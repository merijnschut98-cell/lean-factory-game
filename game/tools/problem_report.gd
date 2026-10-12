extends SceneTree
## Measure every catalogue problem on the real network, for content reviews:
##   godot --headless --path game --script res://tools/problem_report.gd -- [out.json]
## For each problem: the healthy base, the problem active, and the problem
## treated by each fitting countermeasure at full strength (Pdca.treated_effects,
## as after a passed Check). Every stream's KPIs and every team's actual load
## are means over SEEDS runs, measured over the last WINDOW of DAYS simulated
## days; planned load is Capacity's. Runs share random numbers per purpose, so
## differences come from the effects. Writes JSON (stdout by default).

const DAYS := 90
const WINDOW := 56
const SEEDS := [11, 12, 13, 14, 15]

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


## The healthy base: headcount per team, and what _measure gives.
func _base() -> Dictionary:
	var net := _net({}, SEEDS[0])
	var headcount := {}
	for pool in net.pools.values():
		headcount[pool.id] = pool.headcount
	var out := _measure_sources({})
	out["headcount"] = headcount
	return out


## A problem scenario: everything _measure_sources gives, plus the problem's
## team (where it shows; none at a wait) and its stream's constraint.
func _measure(p: ProblemDef, sources: Dictionary) -> Dictionary:
	var out := _measure_sources(sources)
	var stream_cap: Dictionary = Capacity.analyse(_net(sources, SEEDS[0]))["streams"][p.stream_id()]
	var step := _net({}, SEEDS[0]).step_at(p.step)
	out["team"] = step.pool_ids[0] if step.kind == SimStep.Kind.WORK else ""
	out["constraint"] = stream_cap["constraint_pool"]
	out["capacity_per_week"] = stream_cap["capacity_per_week"]
	return out


## {streams: {id: KPIs}, actual_load: {pool: share}} averaged over the seeds,
## and planned_load: {pool: share} from Capacity.
func _measure_sources(sources: Dictionary) -> Dictionary:
	var streams := {}
	var actual := {}
	var k := 1.0 / SEEDS.size()
	for seed_value: int in SEEDS:
		var net := _net(sources, seed_value)
		net.advance_days(DAYS)
		var from_day := DAYS - WINDOW
		for s in net.streams:
			var kpis := s.kpis(net.time, WINDOW)
			var sum: Dictionary = streams.get_or_add(s.id, {})
			for key: String in kpis:
				sum[key] = sum.get(key, 0.0) + kpis[key] * k
		for pool in net.pools.values():
			actual[pool.id] = actual.get(pool.id, 0.0) + pool.load_since(from_day) * k
	var planned := {}
	var cap: Dictionary = Capacity.analyse(_net(sources, SEEDS[0]))["pools"]
	for pool_id: String in cap:
		planned[pool_id] = cap[pool_id]["utilisation"]
	return {"streams": streams, "actual_load": actual, "planned_load": planned}


func _net(sources: Dictionary, seed_value: int) -> Network:
	var net := Network.create(_config, seed_value)
	for source: String in sources:
		var error := net.set_effects(source, sources[source])
		assert(error.is_empty(), error)
	return net
