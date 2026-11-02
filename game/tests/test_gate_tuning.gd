extends TestCase
## The Phase 2 gate's tuning backlog (docs/qa/autoplay-report.md, 2026-10-24) on the real
## content. The fork's lesson in the stream's own numbers: with both fork problems on, the
## intake is clearly the connections stream's constraint, so fixing it gives flow and fixing
## the monteurs' problem gives none (CLAUDE.md: improving a step that is not the bottleneck
## brings no gain, and the simulation must show it). And the best fix passes its Check
## reliably, not on the luck of a seed.

const DEMAND_SHORTFALL := 0.1   # the intake fails demand by at least this much
const NO_GAIN := 0.01           # Region.check's "not the constraint" threshold


## The connections stream's analysis with the fork's problems on, after the first bottleneck
## (custom_design) is fixed, as the fork opens.
func _analyse(active: Array[String]) -> Dictionary:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	for id in active:
		s.region.activate(id)
	return Capacity.analyse(s.region.net)["streams"]["connections"]


func test_the_intake_is_clearly_the_bottleneck_at_the_fork() -> void:
	var both := _analyse(["incomplete_application", "installer_not_ready"])
	var demand := GameSession.new_game(11, Catalog.DATA_DIR, false).region.net.stream("connections").per_week()
	assert_eq(both["constraint_pool"], "intake")
	assert_true(both["capacity_per_week"] < demand * (1.0 - DEMAND_SHORTFALL),
		"the intake fails demand clearly: %.1f a week against %.1f" % [both["capacity_per_week"], demand])
	var monteurs_fixed := _analyse(["incomplete_application"])
	assert_eq(monteurs_fixed["constraint_pool"], "intake", "fixing the monteurs moves nothing")
	assert_true(monteurs_fixed["capacity_per_week"] / both["capacity_per_week"] - 1.0 < NO_GAIN,
		"no capacity gain: %.2f -> %.2f" % [both["capacity_per_week"], monteurs_fixed["capacity_per_week"]])
	var intake_fixed := _analyse(["installer_not_ready"])
	assert_true(intake_fixed["capacity_per_week"] > demand,
		"the intake's fix lets demand through: %.1f a week" % intake_fixed["capacity_per_week"])


## The gain of `problem_id`'s KPI with its best-fitting fix in place, as Region.check
## measures it (CheckForecast over the Check's horizon), on `seed_value`; `also` stays on.
func _best_fix_gain(problem_id: String, seed_value: int, also: Array[String] = [], at_floor := false) -> float:
	var r := GameSession.new_game(seed_value, Catalog.DATA_DIR, false).region
	if at_floor:
		r.profile.budget = Region.DEBT_FLOOR
		r._apply_bad_period()
	for id in also + [problem_id]:
		r.activate(id)
	r.advance_days(28)
	var p := r.problems[problem_id]
	var best: CountermeasureDef = null
	var eff := 0.0
	for id: String in p.countermeasures:
		var e: float = Pdca.effectiveness(p, r.countermeasures[id], r.maturity())["eff"]
		if e > eff:
			eff = e
			best = r.countermeasures[id]
	var sources := Pdca.treated_effects(p, best, eff)
	for source: String in sources:
		r.net.set_effects(source, sources[source])
	r.advance_days(Region.CHECK_DAYS)
	var horizon := Region.check_window(p, r._lead_days(p, r.snapshot(problem_id)))
	var forecast := CheckForecast.run(r.net, p, horizon.x, horizon.y)
	return forecast["gains"][p.kpi]


## Gate backlog 4 (readiness_check failed on +0.1 and +1.4 % lead time): the best fix for a meterkast that is not ready passes its Check on the
## problem's KPI on every seed, whichever branch of the fork came first.
func test_the_readiness_check_passes_its_check_on_every_seed() -> void:
	for seed_value in [11, 12, 13]:
		for also: Array[String] in [[] as Array[String], ["incomplete_application"] as Array[String]]:
			var gain := _best_fix_gain("installer_not_ready", seed_value, also)
			assert_true(gain > 2.0 * Pdca.CHECK_NOISE, "seed %d %s: %+.1f %%" % [seed_value, also, 100.0 * gain])


## Gate backlog 5: the voltage complaints' best fix passes at the debt floor too, where it
## gained +1.4 % on seed 11 over eight weeks.
func test_the_tap_review_passes_at_the_floor() -> void:
	for seed_value in [11, 13]:
		var gain := _best_fix_gain("inverters_tripping", seed_value, [], true)
		assert_true(gain > Pdca.CHECK_NOISE, "seed %d: %+.1f %%" % [seed_value, 100.0 * gain])


## Review 381d21c..0ec040f #8: once Henk's farewell has closed the cheap fixes for the
## knowledge drain, the one left (work instruction videos, EUR 5,000) is still funded at the
## debt floor, so the failed side mission never holds its slot for good.
func test_after_henks_farewell_the_knowledge_drain_stays_fundable_at_the_floor() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var r := s.region
	r.profile.budget = Region.DEBT_FLOOR
	r._apply_bad_period()
	var henk: MissionDef = s.missions.defs["save_henks_knowledge"]
	r.close_countermeasures(henk.fail_closes)
	var left: Array = r.available_countermeasures().filter(
		func(c: CountermeasureDef) -> bool: return r.problems["knowledge_drain"].countermeasures.has(c.id))
	assert_false(left.is_empty(), "a fix is left")
	for c: CountermeasureDef in left:
		if c.budget == left.map(func(x: CountermeasureDef) -> int: return x.budget).min():
			assert_true(r.fundable(c, "knowledge_drain"), "%s (EUR %d) is funded at the floor" % [c.id, c.budget])
