extends SceneTree
## Measure every catalogue problem on the real network, for content reviews:
##   godot --headless --path game --script res://tools/problem_report.gd -- [out.json]
## For each problem: the healthy base, the problem active, and the problem
## treated by each fitting countermeasure at full strength (Pdca.treated_effects,
## as after a passed Check). KPIs are means over SEEDS runs, measured over the
## last WINDOW of DAYS simulated days. Writes JSON (stdout by default).

const DAYS := 90
const WINDOW := 56
const SEEDS := [11, 12, 13, 14, 15]
const CONTACT := "customer_contact"

var _config: Dictionary


func _initialize() -> void:
	quit(_run())


func _run() -> int:
	var file := JsonFile.read_dict(Network.DEFAULT_PATH)
	var catalog := Catalog.load_from()
	var error: String = file["error"] if not file["error"].is_empty() else catalog.error
	if not error.is_empty():
		printerr(error)
		return 1
	_config = file["data"]
	var cms := {}
	for cm in catalog.countermeasures:
		cms[cm.id] = cm
	var report := {"days": DAYS, "window_days": WINDOW, "seeds": SEEDS, "base": _base(), "problems": []}
	for p in catalog.problems:
		var row := {"id": p.id, "with_problem": _measure(p, Pdca.treated_effects(p, null, 0.0)), "countermeasures": []}
		for cm_id: String in p.countermeasures:
			var cm: CountermeasureDef = cms[cm_id]
			var eff: float = Pdca.effectiveness(p, cm, cm.tier)["eff"]
			row["countermeasures"].append({"id": cm_id, "eff": eff, "result": _measure(p, Pdca.treated_effects(p, cm, eff))})
		report["problems"].append(row)
		printerr("measured ", p.id)
	var text := JSON.stringify(report, "  ")
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print(text)
		return 0
	var out := FileAccess.open(args[0], FileAccess.WRITE)
	if out == null:
		printerr("cannot write ", args[0], ": ", error_string(FileAccess.get_open_error()))
		return 1
	out.store_string(text)
	return 0


## Utilisation per team and the KPIs of every stream, without any problem.
func _base() -> Dictionary:
	var net := _net({}, SEEDS[0])
	var cap: Dictionary = Capacity.analyse(net)["pools"]
	var pools := {}
	for pool_id: String in cap:
		pools[pool_id] = {"headcount": net.pools[pool_id].headcount, "utilisation": cap[pool_id]["utilisation"]}
	return {"pools": pools, "streams": _mean_kpis({})}


## The problem's stream, the contact centre (where failure demand lands) and
## the load on the problem's team and the stream's constraint.
func _measure(p: ProblemDef, sources: Dictionary) -> Dictionary:
	var net := _net(sources, SEEDS[0])
	var kpis := _mean_kpis(sources)
	var cap := Capacity.analyse(net)
	var stream_cap: Dictionary = cap["streams"][p.stream_id()]
	var step := net.step_at(p.step)
	var team: String = step.pool_ids[0] if step.kind == SimStep.Kind.WORK else ""
	return {
		"stream": kpis[p.stream_id()],
		"contact": kpis[CONTACT],
		"team": team,
		"team_utilisation": cap["pools"][team]["utilisation"] if team != "" else null,
		"constraint": stream_cap["constraint_pool"],
		"constraint_utilisation": stream_cap["utilisation"],
		"capacity_per_week": stream_cap["capacity_per_week"],
	}


## Every stream's KPIs, averaged over the seeds: {stream_id: kpis}.
func _mean_kpis(sources: Dictionary) -> Dictionary:
	var mean := {}
	for seed_value: int in SEEDS:
		var net := _net(sources, seed_value)
		net.advance_days(DAYS)
		for s in net.streams:
			var kpis := s.kpis(net.time, WINDOW)
			var sum: Dictionary = mean.get_or_add(s.id, {})
			for key: String in kpis:
				sum[key] = sum.get(key, 0.0) + kpis[key] / float(SEEDS.size())
	return mean


func _net(sources: Dictionary, seed_value: int) -> Network:
	var net := Network.create(_config, seed_value)
	for source: String in sources:
		var error := net.set_effects(source, sources[source])
		assert(error.is_empty(), error)
	return net
