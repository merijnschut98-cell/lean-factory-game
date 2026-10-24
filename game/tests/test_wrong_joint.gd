extends TestCase
## De verkeerde mof in de bus (wrong_joint_in_van): the waste is the drive back to the
## magazijn for the right joint ("materiaal halen"), a counted trip on outages.repair
## (Network.material_trips_since) that the storingsbord, the uitgiftelijst (each trip signs a
## second joint out) and the outage KPIs can see, and that the fixes take away.

const PROBLEM := "wrong_joint_in_van"
const SEEDS: Array[int] = [11, 12]
const DAYS := 60
## Readings before this day are the problem still settling in (yard_tell_probe.gd).
const SETTLE_DAYS := 9


## {trips, lead_hours (all outage hours per week), the yard's readings (median daily)}
## summed over SEEDS; `cm` names the fix, "" leaves the problem untreated
## and "none" runs the healthy base.
func _run(cm: String) -> Dictionary:
	var out := {"trips": 0, "lead_hours": 0.0, "storingsbord": 0, "uitgiftelijst": 0}
	for seed_value in SEEDS:
		var s := GameSession.new_game(seed_value, Catalog.DATA_DIR, false)
		var r := s.region
		if cm != "none":
			var p: ProblemDef = r.problems[PROBLEM]
			var fix: CountermeasureDef = r.countermeasures.get(cm)
			var eff := 0.0 if fix == null else float(Pdca.effectiveness(p, fix, fix.tier)["eff"])
			var sources := Pdca.treated_effects(p, fix, eff)
			for source: String in sources:
				r.net.set_effects(source, sources[source])
		var read := {"storingsbord": [], "uitgiftelijst": []}
		for d in DAYS:
			r.advance_days(1)
			if d >= SETTLE_DAYS:
				var now := OfficeTells.readings(r.net)
				for tell: String in read:
					read[tell].append(now[tell])
		for tell: String in read:
			read[tell].sort()
			out[tell] += read[tell][read[tell].size() / 2]
		out["trips"] += r.net.material_trips_since(0)
		out["lead_hours"] += r.net.stream("outages").kpis(r.net.time, DAYS - SETTLE_DAYS)["lead_hours_per_week"]
	return out


func test_the_wrong_joint_sends_monteurs_back_for_material_and_the_yard_shows_it() -> void:
	var base := _run("none")
	var hurt := _run("")
	assert_eq(base["trips"], 0, "a healthy van has the joint")
	# A quarter of the outages over 2 × 60 days at ~18 a week: about 75 trips.
	assert_between(hurt["trips"], 40, 120, "trips")
	for tell in ["storingsbord", "uitgiftelijst"]:
		assert_true(hurt[tell] >= base[tell] + 3 * SEEDS.size(), "%s: %d vs %d" % [tell, hurt[tell], base[tell]])
	assert_true(hurt["lead_hours"] > base["lead_hours"] * 1.1, "outage hours %.0f vs %.0f" % [hurt["lead_hours"], base["lead_hours"]])


func test_each_fix_takes_most_of_the_trips_away() -> void:
	var hurt := _run("")
	for cm in ["van_refill_card", "standard_van_stock", "two_bin_van_kanban"]:
		var fixed := _run(cm)
		assert_true(fixed["trips"] < hurt["trips"] * 0.5, "%s: %d trips vs %d" % [cm, fixed["trips"], hurt["trips"]])
		assert_true(fixed["lead_hours"] < hurt["lead_hours"], cm)
