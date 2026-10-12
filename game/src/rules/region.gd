class_name Region
extends RefCounted
## The game rules of one region: problems become active and hit the
## simulation; the player investigates with gemba tools and questions,
## writes an A3, runs an experiment, Checks it against the end-to-end
## numbers and Acts (standardise, or watch it come back). Owns the Network.
##
## Places are value-stream steps ("connections.design"). Results are codes
## and numbers; the UI words them in Dutch.
##
## Effect sources on the Network: problem:<id> (the problem, weakened by a
## working countermeasure), cm:<id> (the improvement), do:<id> (team hours
## spent on the experiment).

const MAX_OPEN := 3
const CHECK_DAYS := 14
const STANDARDISE_BUDGET := 3000
## A region's maturity rises when this share of a tier's problems is resolved.
const MATURITY_STEP := 0.6

var net: Network
var profile: Profile
var problems: Dictionary[String, ProblemDef] = {}
var countermeasures: Dictionary[String, CountermeasureDef] = {}
var state: Dictionary[String, ProblemState] = {}
## Places the player has worked at, and clue ids found.
var observed: Dictionary[String, bool] = {}
var found: Dictionary[String, bool] = {}
## Trust per team (pool id), -2..1: below 0 they stop sharing.
var trust: Dictionary[String, int] = {}
## {type: activated | check_ready | recurred | belt, ...} for the world and UI.
var events: Array[Dictionary] = []


func _init(network: Network, problem_defs: Array[ProblemDef], cm_defs: Array[CountermeasureDef], player: Profile) -> void:
	net = network
	profile = player
	for p in problem_defs:
		problems[p.id] = p
		state[p.id] = ProblemState.new(p.id)
	for c in cm_defs:
		countermeasures[c.id] = c


func problem_list() -> Array[ProblemDef]:
	return problems.values()


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


## The region's maturity (1–4): a tier counts once most of its problems are resolved.
func maturity() -> int:
	var m := 1
	while m < 4:
		var tier := problem_list().filter(func(p: ProblemDef) -> bool: return p.tier == m)
		var done := tier.filter(func(p: ProblemDef) -> bool: return state[p.id].phase == "resolved")
		if tier.is_empty() or done.size() < tier.size() * MATURITY_STEP:
			break
		m += 1
	return m


func trust_of(place: String) -> int:
	return trust.get(_team(place), 0)


# ── Time ────────────────────────────────────────────────────────────────────

func advance_days(n: float) -> void:
	advance(SimCalendar.days(n))


func advance(minutes: int) -> void:
	net.advance(minutes)
	for st: ProblemState in state.values():
		if st.phase == "doing" and net.time >= st.check_at:
			st.phase = "check_ready"
			events.append({"type": "check_ready", "problem": st.id})
		elif st.phase == "resolved" and st.recur_at >= 0 and net.time >= st.recur_at:
			_recur(st)


# ── Problems ────────────────────────────────────────────────────────────────

## Make a dormant problem active (missions and the story decide which).
## False when it is not dormant or MAX_OPEN problems are already open.
func activate(problem_id: String) -> bool:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != "dormant" or state.values().filter(func(s: ProblemState) -> bool: return s.is_open()).size() >= MAX_OPEN:
		return false
	st.phase = "active"
	_apply_problem(st)
	events.append({"type": "activated", "problem": problem_id})
	return true


## The problem hurts the simulation at the strength a countermeasure leaves.
func _apply_problem(st: ProblemState) -> void:
	net.set_effects("problem:" + st.id, SimModifiers.scaled(problems[st.id].effects, 1.0 - st.eff))


# ── Plan: Go & See ──────────────────────────────────────────────────────────

## Spend time at a place with a gemba tool (the caller advances the clock by
## Investigation.TOOLS[tool].minutes). One use goes one "why" deeper.
## Returns {spotted: problem ids, clues: Array[Clue], hidden_signal}.
func use_tool(place: String, tool: String) -> Dictionary:
	var spotted := _spot(place, Investigation.TOOLS[tool]["deep"])
	var clues := _ready_clues(place, tool)
	for c in clues:
		_reveal(c)
	for p in _known_at(place):
		if not tool in state[p.id].tools_used:
			state[p.id].tools_used.append(tool)
	return {"spotted": spotted, "clues": clues, "hidden_signal": spotted.is_empty() and _hidden_at(place)}


## Talk to the team at a place. How you ask decides what you learn.
## Returns {kind, reply, trust, clue?, observation?}; reply is a code:
## clue | observation | closed | blame | guarded | repair | welcome | nobody.
func ask(place: String, question_id: String) -> Dictionary:
	var team := _team(place)
	var kind: String = Investigation.QUESTIONS[question_id]
	if team.is_empty():
		return {"kind": kind, "reply": "nobody", "trust": 0}
	var before: int = trust.get(team, 0)
	match kind:
		"blame":
			trust[team] = maxi(-2, before - 1)
			for p in problem_list():
				if state[p.id].is_open() and team in _pools_at(p.step):
					state[p.id].blamed = true
			profile.learn(["respect_for_people"])
			return {"kind": kind, "reply": "blame", "trust": trust[team]}
		"repair":
			trust[team] = mini(1, before + 1)
			profile.learn(["respect_for_people"])
			return {"kind": kind, "reply": "repair" if before < 0 else "welcome", "trust": trust[team]}
		"closed":
			profile.learn(["open_questions"])
			return {"kind": kind, "reply": "closed", "trust": before}
	if before < 0:
		return {"kind": kind, "reply": "guarded", "trust": before}
	_spot(place, false)
	profile.learn(["open_questions"])
	var clues := _ready_clues(place, "conversation")
	if clues.is_empty():
		return {"kind": kind, "reply": "observation", "trust": before, "observation": _observation(place)}
	clues.sort_custom(func(a: Clue, b: Clue) -> bool: return a.depth < b.depth)
	_reveal(clues[0])
	return {"kind": kind, "reply": "clue", "trust": before, "clue": clues[0]}


func _spot(place: String, deep: bool) -> Array[String]:
	observed[place] = true
	var spotted: Array[String] = []
	for p in problem_list():
		var st := state[p.id]
		if st.phase == "active" and p.step == place and (deep or p.visibility != "hidden"):
			st.phase = "spotted"
			spotted.append(p.id)
	if not spotted.is_empty():
		profile.learn(["gemba"])
	return spotted


## Clues for `tool` at `place` that can be found now, for problems the player
## knows. Collected before revealing, so one use goes one level deeper.
func _ready_clues(place: String, tool: String) -> Array[Clue]:
	var out: Array[Clue] = []
	for p in problem_list():
		if not state[p.id].is_known():
			continue
		for c in p.clues:
			if c.tool == tool and c.at == place and Investigation.revealable(c, p, found):
				out.append(c)
	return out


func _reveal(c: Clue) -> void:
	found[c.id] = true
	profile.learn(c.teaches)


func _known_at(place: String) -> Array[ProblemDef]:
	return problem_list().filter(func(p: ProblemDef) -> bool: return p.step == place and state[p.id].is_known())


func _hidden_at(place: String) -> bool:
	return problem_list().any(func(p: ProblemDef) -> bool:
		return p.step == place and state[p.id].phase == "active" and p.visibility == "hidden")


## What the team at a place truthfully sees in their work right now.
func _observation(place: String) -> Dictionary:
	var step := _step(place)
	var queue := net.queue_of(step).size()
	if queue > 10:
		return {"kind": "queue", "value": queue}
	var recent := step.stats_since(SimCalendar.day_of(net.time) - CHECK_DAYS)
	var attempts: int = recent["done"] + recent["reworked"]
	if attempts > 0 and recent["reworked"] / float(attempts) > 0.2:
		return {"kind": "rework", "value": recent["reworked"] / float(attempts)}
	return {"kind": "quiet", "value": queue}


func _step(place: String) -> SimStep:
	return net.stream(place.get_slice(".", 0)).step(place.get_slice(".", 1))


func _pools_at(place: String) -> PackedStringArray:
	var step := _step(place)
	return step.pool_ids if step != null else PackedStringArray()


## The team you talk to at a place: the first pool doing the work there.
func _team(place: String) -> String:
	var pools := _pools_at(place)
	return pools[0] if not pools.is_empty() else ""


# ── Plan → Do: the A3 ───────────────────────────────────────────────────────

## Countermeasures this region can try: up to one tier above its maturity.
func available_countermeasures() -> Array[CountermeasureDef]:
	var m := maturity()
	var out: Array[CountermeasureDef] = []
	for c: CountermeasureDef in countermeasures.values():
		if c.tier <= m + 1:
			out.append(c)
	return out


## Submit the A3 {waste, cause (index into the cause bank), evidence (clue
## ids), cm, prediction (a KPI)} and start the experiment. Returns "" or why
## not: not_spotted | waste | cause | evidence | countermeasure | prediction | budget.
func submit_a3(problem_id: String, a3: Dictionary) -> String:
	var st := state[problem_id]
	if st.phase != "spotted":
		return "not_spotted"
	if not a3.get("waste") in Investigation.WASTES:
		return "waste"
	var options: Array = Investigation.cause_options(problems[problem_id], problem_list())["options"]
	if not (a3.get("cause") is int and a3["cause"] >= 0 and a3["cause"] < options.size()):
		return "cause"
	var evidence: Array = a3.get("evidence", []).filter(func(id: String) -> bool: return found.has(id))
	if evidence.is_empty():
		return "evidence"
	var cm: CountermeasureDef = countermeasures.get(a3.get("cm", ""))
	if cm == null or not cm in available_countermeasures():
		return "countermeasure"
	if not a3.get("prediction") in Investigation.KPIS:
		return "prediction"
	if profile.budget < cm.budget:
		return "budget"

	profile.budget -= cm.budget
	st.baseline = snapshot(problem_id)
	var e := Pdca.effectiveness(problems[problem_id], cm, maturity())
	st.a3 = a3.duplicate()
	st.a3["evidence"] = evidence
	st.eff = e["eff"]
	st.level = e["level"]
	st.phase = "doing"
	st.check_at = net.time + SimCalendar.days(CHECK_DAYS)
	_apply_problem(st)
	if st.eff >= Pdca.CHECK_PASS:
		net.set_effects("cm:" + problem_id, SimModifiers.scaled(cm.effects, st.eff))
	net.set_effects("do:" + problem_id, _team_hours(cm))
	profile.learn(["A3", "kata_prediction"])
	return ""


## The improvement work takes the team's hours from daily work while the
## experiment runs: an availability effect spread over the check period.
func _team_hours(cm: CountermeasureDef) -> Array:
	var effects := []
	for pool_id in cm.team_hours:
		var pool: SimPool = net.pools.get(pool_id)
		if pool != null:
			var hours_in_period := pool.headcount * pool.schedule.hours() * CHECK_DAYS / 7.0
			effects.append({"target": pool_id, "property": "availability", "value": -cm.team_hours[pool_id] / hours_in_period})
	return effects


## The end-to-end numbers of the problem's stream: KPIs over the last
## CHECK_DAYS, capacity and constraint, and the problem's own step.
func snapshot(problem_id: String) -> Dictionary:
	var p := problems[problem_id]
	var stream := net.stream(p.stream_id())
	var c: Dictionary = Capacity.analyse(net)["streams"][stream.id]
	var k := stream.kpis(net.time, CHECK_DAYS)
	return {
		"capacity": c["capacity_per_week"], "constraint_pool": c["constraint_pool"],
		"throughput": k["throughput_per_week"], "lead_time": k["lead_days_p50"],
		"first_time_right": k["first_time_right"], "on_time": k["on_time"],
		"step": _step(p.step).stats_since(SimCalendar.day_of(net.time) - CHECK_DAYS),
	}


# ── Check ───────────────────────────────────────────────────────────────────

## Compare before and after. Returns {passed, before, after, level,
## cause_correct, waste_right, lesson, not_constraint}; lesson is a code:
## cause_right | cause_wrong | mismatch | too_early.
func check(problem_id: String) -> Dictionary:
	var st := state[problem_id]
	if st.phase != "check_ready":
		return {}
	var p := problems[problem_id]
	net.clear_effects("do:" + problem_id)
	var after := snapshot(problem_id)
	var cause_correct: bool = Investigation.cause_options(p, problem_list())["correct"] == st.a3["cause"]
	var result := {
		"passed": st.eff >= Pdca.CHECK_PASS, "before": st.baseline, "after": after, "level": st.level,
		"cause_correct": cause_correct, "waste_right": st.a3["waste"] == p.waste,
		"lesson": "cause_right" if cause_correct else "cause_wrong",
		# The step got better, but the stream still waits on another team.
		"not_constraint": not st.baseline["constraint_pool"] in _pools_at(p.step)
			and after["capacity"] < st.baseline["capacity"] * 1.01,
	}
	profile.learn(["PDCA", "eight_wastes", "waste_" + p.waste])
	if result["not_constraint"]:
		profile.learn(["bottleneck_focus", "theory_of_constraints"])
	if result["passed"]:
		st.phase = "checked"
		return result
	result["lesson"] = "mismatch" if st.level == "mismatch" else "too_early"
	st.failed_checks += 1
	st.tried.append(st.a3["cm"])
	st.eff = 0.0
	st.level = ""
	st.phase = "spotted"
	net.clear_effects("cm:" + problem_id)
	_apply_problem(st)
	return result


# ── Act ─────────────────────────────────────────────────────────────────────

## Close a checked problem: standardise (costs budget, keeps the gain) or
## not (the fix fades after the countermeasure's decay). Returns the score.
func act(problem_id: String, standardise: bool) -> Dictionary:
	var st := state[problem_id]
	if st.phase != "checked":
		return {}
	var p := problems[problem_id]
	var cm := countermeasures[st.a3["cm"]]
	standardise = standardise and profile.budget >= STANDARDISE_BUDGET
	if standardise:
		profile.budget -= STANDARDISE_BUDGET
	var keys := p.clues.filter(func(c: Clue) -> bool: return c.key).map(func(c: Clue) -> String: return c.id)
	var evidence: Array = st.a3["evidence"]
	var capacity: float = snapshot(problem_id)["capacity"]
	var before: float = st.baseline["capacity"]
	st.score = Pdca.score({
		"key_found": keys.filter(func(id: String) -> bool: return found.has(id)).size(),
		"key_total": keys.size(),
		"scouted": observed.keys().any(func(place: String) -> bool: return place != p.step and place.get_slice(".", 0) == p.stream_id()),
		"blamed": st.blamed,
		"cause_correct": Investigation.cause_options(p, problem_list())["correct"] == st.a3["cause"],
		"key_linked": evidence.filter(func(id: String) -> bool: return id in keys).size(),
		"herrings_linked": evidence.filter(func(id: String) -> bool: return not id in keys).size(),
		"eff": st.eff,
		"failed_checks": st.failed_checks,
		"prediction_right": st.a3["prediction"] == p.kpi,
		"standardised": standardise,
		"waste_right": st.a3["waste"] == p.waste,
		"capacity_gain": (capacity - before) / before if before > 0.0 else 0.0,
		"at_constraint": st.baseline["constraint_pool"] in _pools_at(p.step),
	})
	st.standardised = standardise
	st.phase = "resolved"
	st.recur_at = net.time + SimCalendar.days(cm.decay_days) if not standardise and cm.decay_days >= 0 else -1
	net.clear_effects("problem:" + problem_id)
	profile.learn(p.teaches + (PackedStringArray(["standard_work"]) if standardise else PackedStringArray()))
	var belt := Progression.belt_index(profile.xp)
	profile.budget += Pdca.budget_for(st.score, p.severity)
	profile.xp += Pdca.xp_for(st.score, p.tier)
	profile.resolved += 1
	if Progression.belt_index(profile.xp) > belt:
		events.append({"type": "belt", "belt": Progression.belt_index(profile.xp)})
	return st.score


## An unstandardised fix fades: the improvement goes, the problem returns.
func _recur(st: ProblemState) -> void:
	net.clear_effects("cm:" + st.id)
	var fresh := ProblemState.new(st.id)
	fresh.phase = "active"
	state[st.id] = fresh
	_apply_problem(fresh)
	events.append({"type": "recurred", "problem": st.id})
