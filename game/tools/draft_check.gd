extends SceneTree
## Measure a content draft on the real network before it goes into content/:
##   godot --headless --path game --script res://tools/draft_check.gd -- <draft.json> [out.json]
## draft.json holds {problems, countermeasures} in the content shape (a draft's
## YAML blocks converted to JSON), and optionally `maturity` (the region's, for
## effectiveness; default 2), `only` (problem ids to measure; default all) and
## `scenarios` (below), and `quick` (true: skip the year runs, for a fast
## re-measure of harm and the Check). Writes JSON (stdout by
## default). Every number is a mean ± sd over SEEDS; runs share random numbers
## per purpose, so differences come from the effects.
##
## Per problem:
##   harm        the test_catalog.gd measures, so a draft can be held to the
##               catalogue tests before it is added: the flow harm (worst
##               team load ratio, or waiting at the step), first-time-right
##               ratio, and the named KPI before and after (seed 11, 150 days);
##               plus the highest planned team load with the problem.
##   countermeasures  per listed countermeasure: eff and level at `maturity`,
##               whether the Check passes, the steady state during the Check
##               (problem at 1 − eff, the countermeasure at eff), its gain over
##               the open problem (KpiBoard.improvement on the problem's
##               stream), and Region.check's not_constraint rule. After the Act
##               the problem is cleared whatever the fit, so the fit shows only
##               here; over time fixes differ by decay, own effects and aftermath:
##   year        the 365 days from the A3, unstandardised and standardised: the
##               Check, then wear as Sustain models it with nothing else done
##               (no audits, no routine), a fix that recurs found again
##               (REFIND_DAYS) and redone with the same countermeasure; the
##               draft's proposed `aftermath` ({after_days, days, effects,
##               cost}) runs from each adoption. Gain over leaving the problem
##               open for the year, and euros (budget, standardising,
##               aftermath, the problem's weekly cost at its strength).
## Scenarios: [{id, window_days, phases: [{days, open: [problem], treated:
## {problem: cm}, resolved: {problem: cm}}]}]: each phase replaces all
## effects; days "warmup" is GameSession.WARMUP_DAYS. Every stream's KPIs over
## the last window_days are reported.

const SEEDS: Array[int] = [11, 12, 13, 14, 15]
const WARMUP := GameSession.WARMUP_DAYS
const WINDOW := 84
const YEAR := 365
## The year is measured in this many windows (the network keeps 120 days).
const YEAR_SAMPLES := 5
## ESTIMATE: a recurred fix's mission reopens and the problem is found again
## within a week; then the A3 and the Check as the first time.
const REFIND_DAYS := 7
## test_catalog.gd's harm run.
const HARM_SEED := 11
const HARM_DAYS := 150
const HARM_KPI_WINDOW := 60

var _config: Dictionary
var _problems: Dictionary[String, ProblemDef] = {}
var _cms: Dictionary[String, CountermeasureDef] = {}
## countermeasure id → its raw `aftermath` (a proposed field the defs drop).
var _aftermath: Dictionary[String, Dictionary] = {}
var _maturity := 2
var _quick := false


func _initialize() -> void:
	quit(_run())


func _run() -> int:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -- <draft.json> [out.json]")
		return 1
	var draft := JsonFile.read_dict(args[0])
	var file := JsonFile.read_dict(Network.DEFAULT_PATH)
	var catalog := Catalog.load_from()
	for error: String in [draft["error"], file["error"], catalog.error]:
		if not error.is_empty():
			printerr(error)
			return 1
	_config = file["data"]
	var error := _load_draft(draft["data"], catalog.kpis)
	if not error.is_empty():
		printerr(error)
		return 1
	var report := {"seeds": SEEDS, "warmup_days": WARMUP, "window_days": WINDOW, "maturity": _maturity,
		"base": _measure_phases([{"days": WARMUP + WINDOW}], WINDOW), "problems": [], "scenarios": []}
	var only: Array = draft["data"].get("only", [])
	for p: ProblemDef in _problems.values():
		if not only.is_empty() and not p.id in only:
			continue
		report["problems"].append(_problem_report(p))
		printerr("measured ", p.id)
	for s: Variant in draft["data"].get("scenarios", []):
		var scenario: Dictionary = JsonFile.dict_or_empty(s)
		var window := int(scenario.get("window_days", WINDOW))
		var phases: Array = scenario.get("phases", []).map(_phase_sources)
		report["scenarios"].append({"id": scenario.get("id", "?"), "window_days": window,
			"result": _measure_phases(phases, window)})
		printerr("scenario ", scenario.get("id", "?"))
	return _write(JSON.stringify(report, " "), args[1] if args.size() > 1 else "")


func _load_draft(d: Dictionary, menu: KpiMenu) -> String:
	_maturity = int(d.get("maturity", 2))
	_quick = bool(d.get("quick", false))
	for raw: Variant in d.get("countermeasures", []):
		var cm := CountermeasureDef.from_dict(JsonFile.dict_or_empty(raw))
		if not cm.error.is_empty():
			return cm.error
		cm.effects = menu.expand(cm.effects)
		_cms[cm.id] = cm
		_aftermath[cm.id] = JsonFile.dict_or_empty(raw.get("aftermath"))
	for raw: Variant in d.get("problems", []):
		var p := ProblemDef.from_dict(JsonFile.dict_or_empty(raw))
		if not p.error.is_empty():
			return p.error
		p.effects = menu.expand(p.effects)
		for cm_id in p.countermeasures:
			if not _cms.has(cm_id):
				return "problem %s: countermeasure %s is not in the draft" % [p.id, cm_id]
		_problems[p.id] = p
	return ""


# ── Per problem ─────────────────────────────────────────────────────────────

func _problem_report(p: ProblemDef) -> Dictionary:
	var open_sources := Pdca.treated_effects(p, null, 0.0)
	var open_runs := _runs(open_sources)
	var row := {"id": p.id, "step": p.step, "kpi": p.kpi, "harm": _harm(p),
		"with_problem": _summary(open_runs, WINDOW), "countermeasures": []}
	if not _quick:
		row["year_open"] = _summary(_open_year_runs(p), YEAR)
	var before := Capacity.analyse(_net(open_sources, SEEDS[0]))
	var stream_before: Dictionary = before["streams"][p.stream_id()]
	var at_constraint: bool = stream_before["constraint_pool"] in _net({}, SEEDS[0]).step_at(p.step).pool_ids
	row["constraint_pool"] = stream_before["constraint_pool"]
	row["at_constraint"] = at_constraint
	for cm_id: String in p.countermeasures:
		var cm := _cms[cm_id]
		var e := Pdca.effectiveness(p, cm, _maturity)
		var sources := Pdca.treated_effects(p, cm, e["eff"])
		var runs := _runs(sources)
		var after: Dictionary = Capacity.analyse(_net(sources, SEEDS[0]))["streams"][p.stream_id()]
		var year := {}
		for standardised: bool in [] if _quick else [false, true]:
			var year_runs := _year_runs(p, cm, standardised)
			year["standardised" if standardised else "loose"] = {
				"summary": _summary(year_runs, YEAR),
				"gain": _gains(_open_year_runs(p), year_runs, p.stream_id()),
				"euros_open": _mean_of(_open_year_runs(p), "euros"),
				"euros": _mean_of(year_runs, "euros"), "adoptions": _mean_of(year_runs, "adoptions"),
			}
		row["countermeasures"].append({
			"id": cm_id, "fit": e["fit"], "tier": cm.tier, "level": e["level"], "eff": e["eff"],
			"passes_check": e["eff"] >= Pdca.CHECK_PASS, "decay_days": cm.decay_days,
			"at_check": _summary(runs, WINDOW), "gain_at_check": _gains(open_runs, runs, p.stream_id()),
			"capacity_before": stream_before["capacity_per_week"], "capacity_after": after["capacity_per_week"],
			"not_constraint": not at_constraint and after["capacity_per_week"] < stream_before["capacity_per_week"] * 1.01,
			"year": year,
		})
	return row


## The open-problem year runs, cached per problem.
var _open_year: Dictionary[String, Array] = {}


func _open_year_runs(p: ProblemDef) -> Array:
	if not _open_year.has(p.id):
		_open_year[p.id] = _year_runs(p, null, false)
	return _open_year[p.id]


## test_catalog.gd's harm, on the draft problem (see _harm there).
func _harm(p: ProblemDef) -> Dictionary:
	var sources := Pdca.treated_effects(p, null, 0.0)
	var before := Capacity.analyse(_net({}, HARM_SEED))
	var after := Capacity.analyse(_net(sources, HARM_SEED))
	var worst := 1.0
	var worst_pool := ""
	var max_load := 0.0
	for pool: String in before["pools"]:
		max_load = maxf(max_load, after["pools"][pool]["utilisation"])
		if before["pools"][pool]["load"] > 0.0 and after["pools"][pool]["load"] / before["pools"][pool]["load"] > worst:
			worst = after["pools"][pool]["load"] / before["pools"][pool]["load"]
			worst_pool = pool
	var base_run := _net({}, HARM_SEED)
	base_run.advance_days(HARM_DAYS)
	var hurt_run := _net(sources, HARM_SEED)
	hurt_run.advance_days(HARM_DAYS)
	var flow := worst
	if p.kpi == "throughput":
		flow = before["streams"][p.stream_id()]["capacity_per_week"] / after["streams"][p.stream_id()]["capacity_per_week"]
	elif worst <= 1.0:
		var step := p.step.get_slice(".", 1)
		var h: Dictionary = hurt_run.stream(p.stream_id()).step(step).stats_since(0)
		var b: Dictionary = base_run.stream(p.stream_id()).step(step).stats_since(0)
		flow = (h["wait_hours"] + h["queue_hours"]) / maxf(0.001, b["wait_hours"] + b["queue_hours"])
	var kb := base_run.stream(p.stream_id()).kpis(base_run.time, HARM_KPI_WINDOW)
	var kh := hurt_run.stream(p.stream_id()).kpis(hurt_run.time, HARM_KPI_WINDOW)
	kb["wip_age"] = base_run.open_age_days(base_run.stream(p.stream_id()))
	kh["wip_age"] = hurt_run.open_age_days(hurt_run.stream(p.stream_id()))
	var harm := flow
	if p.kpi == "first_time_right" and kh["first_time_right"] > 0.0:
		harm = maxf(harm, kb["first_time_right"] / kh["first_time_right"])
	var named := ""
	var named_ok := true
	if p.kpi in ["first_time_right", "on_time"]:
		named = "%s %.3f → %.3f" % [p.kpi, kb[p.kpi], kh[p.kpi]]
		named_ok = kh[p.kpi] < kb[p.kpi] - 0.05
	elif p.kpi == "wip_age":
		named = "wip_age %.1f → %.1f" % [kb["wip_age"], kh["wip_age"]]
		named_ok = kh["wip_age"] > kb["wip_age"] * 1.05
	return {"harm": harm, "flow_harm": flow, "worst_pool": worst_pool, "max_planned_load": max_load,
		"passes_harm_test": harm > 1.03, "named_kpi": named, "passes_named_kpi_test": named_ok}


# ── Year: Check, wear, recurrence, re-fix ───────────────────────────────────

## One run per seed of the YEAR days from the A3: the stream measures (the
## mean of YEAR_SAMPLES windows: the network keeps 120 days of history),
## euros and adoptions. `cm` null: the problem stays open all year.
func _year_runs(p: ProblemDef, cm: CountermeasureDef, standardised: bool) -> Array:
	var out := []
	for seed_value in SEEDS:
		var net := _net(Pdca.treated_effects(p, null, 0.0), seed_value)
		net.advance_days(WARMUP)
		var samples := []
		var r := _live_year(net, p, cm, standardised, samples)
		var m := _mean_measures(samples)
		m["euros"] = r["euros"]
		m["adoptions"] = r["adoptions"]
		out.append(m)
	return out



## The mean of several _measured results (equal windows).
static func _mean_measures(samples: Array) -> Dictionary:
	var out := {"streams": {}, "load": {}}
	var k := 1.0 / samples.size()
	for m: Dictionary in samples:
		for stream_id: String in m["streams"]:
			var sum: Dictionary = out["streams"].get_or_add(stream_id, {})
			for key: String in m["streams"][stream_id]:
				sum[key] = sum.get(key, 0.0) + m["streams"][stream_id][key] * k
		for pool: String in m["load"]:
			out["load"][pool] = out["load"].get(pool, 0.0) + m["load"][pool] * k
	return out


## Day by day: Do (CHECK_DAYS at 1 − eff, team hours taken), Act, wear until
## it recurs, REFIND_DAYS open, and again. A Check that fails leaves the
## problem open; `cm` null leaves it open. Appends a _measured sample to
## `samples` every YEAR / YEAR_SAMPLES days. Returns {euros, adoptions}.
func _live_year(net: Network, p: ProblemDef, cm: CountermeasureDef, standardised: bool, samples: Array) -> Dictionary:
	var sample_days := YEAR / YEAR_SAMPLES
	if cm == null:
		for i in YEAR_SAMPLES:
			net.advance_days(sample_days)
			samples.append(_measured(net, sample_days))
		return {"euros": p.cost_per_week * YEAR / 7.0, "adoptions": 0}
	var eff: float = Pdca.effectiveness(p, cm, _maturity)["eff"]
	var life := Sustain.life_days(Sustain.base_days(cm), Sustain.WEIGHTS["standard_work"] if standardised else 0.0)
	var aftermath := _aftermath[cm.id]
	var euros := 0.0
	var adoptions := 0
	var adopted_at := -1
	var stage := "do"  # do | resolved | refind
	var since := 0  # days in this stage
	for day in YEAR:
		if stage == "refind" and since >= REFIND_DAYS:
			stage = "do"
			since = 0
		if stage == "do" and since == 0:
			adoptions += 1
			adopted_at = day
			euros += cm.budget
			_set_sources(net, p, Pdca.treated_effects(p, cm, eff if eff >= Pdca.CHECK_PASS else 0.0))
			net.set_effects("do:" + p.id, _team_hours(net, cm))
		if stage == "do" and since == Region.CHECK_DAYS:
			net.clear_effects("do:" + p.id)
			if eff >= Pdca.CHECK_PASS:
				stage = "resolved"
				since = 0
				euros += Region.STANDARDISE_BUDGET if standardised else 0
		var strength := 1.0  # of the problem today
		if stage == "resolved":
			var wear := pow(since / life, 2.0)
			if wear >= 1.0:
				stage = "refind"
				since = 0
				_set_sources(net, p, Pdca.treated_effects(p, null, 0.0))
			else:
				var h := Sustain.health(wear)
				strength = 1.0 - h
				_set_sources(net, p, Sustain.eroded_effects(p, cm, eff, h))
		elif stage == "do":
			strength = 1.0 - eff if eff >= Pdca.CHECK_PASS else 1.0
		euros += p.cost_per_week * strength / 7.0
		if not aftermath.is_empty() and adopted_at >= 0:
			var after := day - adopted_at
			if after == int(aftermath.get("after_days", 0)):
				euros += float(aftermath.get("cost", 0))
				net.set_effects("aftermath:" + p.id, aftermath.get("effects", []))
			if after == int(aftermath.get("after_days", 0)) + int(aftermath.get("days", 0)):
				net.clear_effects("aftermath:" + p.id)
		net.advance_days(1)
		since += 1
		if (day + 1) % sample_days == 0:
			samples.append(_measured(net, sample_days))
	return {"euros": euros, "adoptions": adoptions}


func _set_sources(net: Network, p: ProblemDef, sources: Dictionary) -> void:
	net.clear_effects("problem:" + p.id)
	net.clear_effects("cm:" + p.id)
	for source: String in sources:
		var error := net.set_effects(source, sources[source])
		assert(error.is_empty(), error)


## Region._team_hours: the improvement work spread over the Check.
func _team_hours(net: Network, cm: CountermeasureDef) -> Array:
	var effects := []
	for pool_id in cm.team_hours:
		var pool: SimPool = net.pools.get(pool_id)
		if pool != null:
			var hours := pool.headcount * pool.schedule.hours() * Region.CHECK_DAYS / 7.0
			effects.append({"target": pool_id, "property": "availability", "value": -cm.team_hours[pool_id] / hours})
	return effects


# ── Scenarios and measuring ─────────────────────────────────────────────────

## A scenario phase as {days, sources}.
func _phase_sources(raw: Variant) -> Dictionary:
	var phase: Dictionary = JsonFile.dict_or_empty(raw)
	var sources: Dictionary[String, Array] = {}
	for pid: String in phase.get("open", []):
		sources.merge(Pdca.treated_effects(_problems[pid], null, 0.0), true)
	var treated: Dictionary = phase.get("treated", {})
	for pid: String in treated:
		var p := _problems[pid]
		var cm := _cms[treated[pid]]
		sources.merge(Pdca.treated_effects(p, cm, Pdca.effectiveness(p, cm, _maturity)["eff"]), true)
	var resolved: Dictionary = phase.get("resolved", {})
	for pid: String in resolved:
		var p := _problems[pid]
		var cm := _cms[resolved[pid]]
		sources.merge(Sustain.eroded_effects(p, cm, Pdca.effectiveness(p, cm, _maturity)["eff"], 1.0), true)
	var days: Variant = phase.get("days", WARMUP)
	return {"days": WARMUP if str(days) == "warmup" else float(days), "sources": sources}


## Every seed runs the phases (each replaces all effects); measured over the
## last `window` days.
func _measure_phases(phases: Array, window: int) -> Dictionary:
	var runs := []
	for seed_value in SEEDS:
		var net := _net({}, seed_value)
		for phase: Dictionary in phases:
			for source: String in net.effects():
				net.clear_effects(source)
			for source: String in phase.get("sources", {}):
				var error := net.set_effects(source, phase["sources"][source])
				assert(error.is_empty(), error)
			net.advance_days(phase["days"])
		runs.append(_measured(net, window))
	return _summary(runs, window)


## One run per seed with `sources` on from day 0, WARMUP + WINDOW days.
func _runs(sources: Dictionary) -> Array:
	var out := []
	for seed_value in SEEDS:
		var net := _net(sources, seed_value)
		net.advance_days(WARMUP + WINDOW)
		out.append(_measured(net, WINDOW))
	return out


## {streams: {id: KPIs over the last `window` days + wip_age}, load: {pool: actual share}}.
func _measured(net: Network, window: int) -> Dictionary:
	var streams := {}
	for s in net.streams:
		var k := s.kpis(net.time, window)
		k["wip_age"] = net.open_age_days(s)
		k["lead_hours_p85"] = k["lead_days_p85"] * 24.0
		streams[s.id] = k
	var load := {}
	var from_day := SimCalendar.day_of(net.time) - window
	for pool in net.pools.values():
		load[pool.id] = pool.load_since(from_day)
	return {"streams": streams, "load": load}


## Mean and sd over the runs of every stream KPI and team load.
func _summary(runs: Array, window: int) -> Dictionary:
	var out := {"window_days": window, "streams": {}, "load": {}}
	for stream_id: String in runs[0]["streams"]:
		var kpis := {}
		for key: String in runs[0]["streams"][stream_id]:
			kpis[key] = _stats(runs.map(func(r: Dictionary) -> float: return r["streams"][stream_id][key]))
		out["streams"][stream_id] = kpis
	for pool: String in runs[0]["load"]:
		out["load"][pool] = _stats(runs.map(func(r: Dictionary) -> float: return r["load"][pool]))
	return out


## KpiBoard.improvement of `after` over `before` on `stream`, per seed pair.
func _gains(before: Array, after: Array, stream_id: String) -> Dictionary:
	var gains := []
	var net := _net({}, SEEDS[0])  # which way the stream's throughput is better
	for i in before.size():
		gains.append(KpiBoard.improvement(before[i]["streams"], after[i]["streams"], PackedStringArray([stream_id]), net))
	return _stats(gains)


func _mean_of(runs: Array, key: String) -> float:
	return runs.reduce(func(sum: float, r: Dictionary) -> float: return sum + float(r[key]), 0.0) / runs.size()


## Per seed (`values`, in SEEDS order) as well, so two results can be compared
## pair by pair: they share their random numbers.
static func _stats(values: Array) -> Dictionary:
	var n := values.size()
	var mean: float = values.reduce(func(s: float, v: float) -> float: return s + v, 0.0) / n
	var variance: float = values.reduce(func(s: float, v: float) -> float: return s + (v - mean) * (v - mean), 0.0) / maxi(1, n - 1)
	return {"mean": mean, "sd": sqrt(variance), "min": values.min(), "max": values.max(), "values": values}


func _net(sources: Dictionary, seed_value: int) -> Network:
	var net := Network.create(_config, seed_value)
	for source: String in sources:
		var error := net.set_effects(source, sources[source])
		assert(error.is_empty(), error)
	return net


func _write(text: String, path: String) -> int:
	if path.is_empty():
		print(text)
		return 0
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out == null:
		printerr("cannot write ", path, ": ", error_string(FileAccess.get_open_error()))
		return 1
	out.store_string(text)
	return 0
