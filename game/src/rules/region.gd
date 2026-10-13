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
## spent on the experiment), board:kpis (the KPIs chosen at the last
## quarterly review, see KpiBoard).

const P := ProblemState.Phase
## At most this many problems are open at once.
const MAX_OPEN := 4
const CHECK_DAYS := 14
const STANDARDISE_BUDGET := 3000
## A region's maturity rises when this share of a tier's problems is resolved.
const MATURITY_STEP := 0.6
## In debt the region is in a bad period, never out of the game (CLAUDE.md
## §2): no money for overtime or temporary staff, more sickness absence, so
## every team has a little less time (an estimate: 3 points of availability).
const BAD_PERIOD_AVAILABILITY := 0.03
const BAD_PERIOD_SOURCE := "region:bad_period"

var net: Network
var profile: Profile
var problems: Dictionary[String, ProblemDef] = {}
var countermeasures: Dictionary[String, CountermeasureDef] = {}
var state: Dictionary[String, ProblemState] = {}
## Places the player has worked at, and clue ids found.
var observed: Dictionary[String, bool] = {}
var found: Dictionary[String, bool] = {}
## Countermeasures closed for good (a missed deadline: Henk has retired).
## Derived from the failed missions (Missions.load_dict restores it).
var closed: Dictionary[String, bool] = {}
## Trust per team (pool id), -2..1: below 0 they stop sharing.
var trust: Dictionary[String, int] = {}
## {type: activated | check_ready | recurred | belt | bad_period | kpi_review, ...} for the world and UI.
var events: Array[Dictionary] = []
## The KPI board; its menu comes from use_kpis.
var board := KpiBoard.new(KpiMenu.new())
## Problem costs not yet taken from the budget (charged in whole euros).
var _cost_owed := 0.0


func _init(network: Network, problem_defs: Array[ProblemDef], cm_defs: Array[CountermeasureDef], player: Profile) -> void:
	net = network
	profile = player
	for p in problem_defs:
		problems[p.id] = p
		state[p.id] = ProblemState.new(p.id)
	for c in cm_defs:
		countermeasures[c.id] = c


## Take the department KPI menus (Catalog.kpis): a fresh board, and the
## kanban limit every team pulls by.
func use_kpis(menu: KpiMenu) -> void:
	board = KpiBoard.new(menu)
	for pool: SimPool in net.pools.values():
		pool.pull_limit_days = menu.pull_limit_days


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
		var done := tier.filter(func(p: ProblemDef) -> bool: return state[p.id].phase == P.RESOLVED)
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
	var day := SimCalendar.day_of(net.time)
	var was_due := board.review_due(net.time)
	net.advance(minutes)
	if not was_due and board.review_due(net.time):
		events.append({"type": "kpi_review"})
	_charge_costs(SimCalendar.day_of(net.time) - day)
	for st: ProblemState in state.values():
		if st.phase == P.DOING and net.time >= st.check_at:
			st.phase = P.CHECK_READY
			events.append({"type": "check_ready", "problem": st.id})
		elif st.phase == P.RESOLVED and st.recur_at >= 0 and net.time >= st.recur_at:
			_recur(st)


## What the open problems cost per week now: each one's cost, weakened by
## a working countermeasure.
func weekly_cost() -> float:
	var total := 0.0
	for st: ProblemState in state.values():
		if st.is_open():
			total += _cost_of(st)
	return total


func _cost_of(st: ProblemState) -> float:
	return problems[st.id].cost_per_week * (1.0 - st.eff)


## Take the weekly cost's share for `days` passed days from the budget.
func _charge_costs(days: int) -> void:
	if days <= 0:
		return
	_cost_owed += weekly_cost() * days / 7.0
	var whole := floori(_cost_owed)
	_cost_owed -= whole
	_add_budget(-whole)


## Debt is allowed; it starts a bad period, and paying it off ends it.
func in_bad_period() -> bool:
	return profile.budget < 0


func _add_budget(amount: int) -> void:
	var was_bad := in_bad_period()
	profile.budget += amount
	if in_bad_period() != was_bad:
		_apply_bad_period()
		events.append({"type": "bad_period", "started": in_bad_period()})


## The bad period's effect on the teams follows the budget. Idempotent:
## RegionState.restore calls it too.
func _apply_bad_period() -> void:
	if not in_bad_period():
		net.clear_effects(BAD_PERIOD_SOURCE)
		return
	var effects := []
	for pool_id: String in net.pools:
		effects.append({"target": pool_id, "property": "availability", "value": -BAD_PERIOD_AVAILABILITY})
	net.set_effects(BAD_PERIOD_SOURCE, effects)


# ── Problems ────────────────────────────────────────────────────────────────

## Make a dormant problem active (missions and the story decide which).
## False when it is not dormant or MAX_OPEN problems are already open.
func activate(problem_id: String) -> bool:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != P.DORMANT or _open_count() >= MAX_OPEN:
		return false
	st.phase = P.ACTIVE
	_apply_problem(st)
	events.append({"type": "activated", "problem": problem_id})
	return true


func _open_count() -> int:
	return state.values().filter(func(s: ProblemState) -> bool: return s.is_open()).size()


## The problem hurts the simulation at the strength a countermeasure leaves;
## with `cm`, the countermeasure's own effects start too.
func _apply_problem(st: ProblemState, cm: CountermeasureDef = null) -> void:
	var sources := Pdca.treated_effects(problems[st.id], cm, st.eff)
	for source: String in sources:
		net.set_effects(source, sources[source])


# ── Plan: Go & See ──────────────────────────────────────────────────────────

## Spend time at a place with a gemba tool (the caller advances the clock by
## Investigation.TOOLS[tool].minutes). One use goes one "why" deeper.
## Returns {spotted: problem ids, clues: Array[Clue], hidden_signal}.
func use_tool(place: String, tool: String) -> Dictionary:
	var spotted := _spot(place, Investigation.TOOLS[tool]["deep"])
	var clues := _ready_clues(place, tool)
	for c in clues:
		_reveal(c)
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
		if st.phase == P.ACTIVE and p.step == place and (deep or p.visibility != "hidden"):
			st.phase = P.SPOTTED
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


func _hidden_at(place: String) -> bool:
	return problem_list().any(func(p: ProblemDef) -> bool:
		return p.step == place and state[p.id].phase == P.ACTIVE and p.visibility == "hidden")


## What the team at a place truthfully sees in their work right now.
func _observation(place: String) -> Dictionary:
	var step := net.step_at(place)
	var queue := net.queue_of(step).size()
	if queue > 10:
		return {"kind": "queue", "value": queue}
	var recent := _recent_stats(step)
	var attempts: int = recent["done"] + recent["reworked"]
	if attempts > 0 and recent["reworked"] / float(attempts) > 0.2:
		return {"kind": "rework", "value": recent["reworked"] / float(attempts)}
	return {"kind": "quiet", "value": queue}


## The step's statistics over the last CHECK_DAYS.
func _recent_stats(step: SimStep) -> Dictionary:
	return step.stats_since(SimCalendar.day_of(net.time) - CHECK_DAYS)


func _pools_at(place: String) -> PackedStringArray:
	var step := net.step_at(place)
	return step.pool_ids if step != null else PackedStringArray()


## The team you talk to at a place: the first pool doing the work there.
func _team(place: String) -> String:
	var pools := _pools_at(place)
	return pools[0] if not pools.is_empty() else ""


# ── Plan → Do: the A3 ───────────────────────────────────────────────────────

## Countermeasures this region can try: up to one tier above its maturity,
## and not closed.
func available_countermeasures() -> Array[CountermeasureDef]:
	var m := maturity()
	var out: Array[CountermeasureDef] = []
	for c: CountermeasureDef in countermeasures.values():
		if c.tier <= m + 1 and not closed.has(c.id):
			out.append(c)
	return out


func close_countermeasures(ids: PackedStringArray) -> void:
	for id in ids:
		closed[id] = true


## Submit the A3 {waste, cause (index into the cause bank), evidence (clue
## ids), cm, prediction (a KPI)} and start the experiment; it may be paid
## into debt. Returns "" or why not: not_spotted | waste | cause | evidence |
## countermeasure | prediction.
func submit_a3(problem_id: String, a3: Dictionary) -> String:
	var st := state[problem_id]
	if st.phase != P.SPOTTED:
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

	var p := problems[problem_id]
	_add_budget(-cm.budget)
	st.baseline = snapshot(problem_id)
	var e := Pdca.effectiveness(p, cm, maturity())
	st.a3 = a3.duplicate()
	st.a3["evidence"] = evidence
	st.cause_correct = options[a3["cause"]] == p.root_cause
	st.waste_right = a3["waste"] == p.waste
	st.eff = e["eff"]
	st.level = e["level"]
	st.phase = P.DOING
	st.check_at = net.time + SimCalendar.days(CHECK_DAYS)
	_apply_problem(st, cm)
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
## CHECK_DAYS, capacity and constraint (and whether the problem's team is
## it), and the problem's own step.
func snapshot(problem_id: String) -> Dictionary:
	var p := problems[problem_id]
	var stream := net.stream(p.stream_id())
	var c: Dictionary = Capacity.analyse(net)["streams"][stream.id]
	var k := stream.kpis(net.time, CHECK_DAYS)
	return {
		"capacity": c["capacity_per_week"], "constraint_pool": c["constraint_pool"],
		"at_constraint": c["constraint_pool"] in _pools_at(p.step),
		"throughput": k["throughput_per_week"], "lead_time": k["lead_days_p50"],
		"cost_per_week": _cost_of(state[problem_id]),
		"first_time_right": k["first_time_right"], "on_time": k["on_time"],
		# The age of the open work: long waits show before their orders finish.
		"wip_age": net.open_age_days(stream),
		"step": _recent_stats(net.step_at(p.step)),
	}


# ── Check ───────────────────────────────────────────────────────────────────

## Compare before and after. Returns {passed, before, after, level,
## cause_correct, waste_right, lesson, not_constraint}; lesson is a code:
## cause_right | cause_wrong | mismatch | too_early.
func check(problem_id: String) -> Dictionary:
	var st := state[problem_id]
	if st.phase != P.CHECK_READY:
		return {}
	var p := problems[problem_id]
	net.clear_effects("do:" + problem_id)
	var after := snapshot(problem_id)
	var result := {
		"passed": st.eff >= Pdca.CHECK_PASS, "before": st.baseline, "after": after, "level": st.level,
		"cause_correct": st.cause_correct, "waste_right": st.waste_right,
		"lesson": "cause_right" if st.cause_correct else "cause_wrong",
		# The step got better, but the stream still waits on another team.
		"not_constraint": not st.baseline["at_constraint"] and after["capacity"] < st.baseline["capacity"] * 1.01,
	}
	profile.learn(["PDCA", "eight_wastes", "waste_" + p.waste])
	if result["not_constraint"]:
		profile.learn(["bottleneck_focus", "theory_of_constraints"])
	if result["passed"]:
		st.phase = P.CHECKED
		# A board without department menus has nothing to review: it stays shut.
		if countermeasures[st.a3["cm"]].unlocks == "kpi_board" and not board.unlocked and not board.menu.menus.is_empty():
			board.unlock(net.time)
			events.append({"type": "kpi_review"})  # the first review, the baseline, is due at once
		return result
	result["lesson"] = "mismatch" if st.level == "mismatch" else "too_early"
	st.failed_checks += 1
	st.eff = 0.0
	st.level = ""
	st.phase = P.SPOTTED
	net.clear_effects("cm:" + problem_id)
	_apply_problem(st)
	return result


# ── Act ─────────────────────────────────────────────────────────────────────

## Close a checked problem: standardise (costs budget, keeps the gain) or
## not (the fix fades after the countermeasure's decay). Returns the score.
func act(problem_id: String, standardise: bool) -> Dictionary:
	var st := state[problem_id]
	if st.phase != P.CHECKED:
		return {}
	var p := problems[problem_id]
	standardise = standardise and profile.budget >= STANDARDISE_BUDGET
	if standardise:
		_add_budget(-STANDARDISE_BUDGET)
	st.score = Pdca.score(_score_inputs(st, p, standardise))
	st.phase = P.RESOLVED
	var decay := countermeasures[st.a3["cm"]].decay_days
	st.recur_at = net.time + SimCalendar.days(decay) if not standardise and decay >= 0 else -1
	net.clear_effects("problem:" + problem_id)
	_reassert_board()
	profile.learn(p.teaches + (PackedStringArray(["standard_work"]) if standardise else PackedStringArray()))
	grant(Pdca.xp_for(st.score, p.tier), Pdca.budget_for(st.score, p.severity))
	return st.score


## A later lever wins (SimModifiers: sources apply in the order they were
## first set; setting one again keeps its place), so a fix set after the last
## review would silently override the KPIs chosen there. Move the board's
## source last, then the sources of the problems still open (in their own
## order) after it: problem > board > countermeasure. Moving switches nothing
## off on the way (clearing an open experiment's WIP limit would release its
## held orders).
func _reassert_board() -> void:
	var sources := net.effects()
	if board.chosen.is_empty() or not sources.has(KpiBoard.SOURCE):
		return
	var later: Array[String] = [KpiBoard.SOURCE]
	for source: String in sources:
		var st: ProblemState = state.get(source.get_slice(":", 1))
		if source.get_slice(":", 0) in ["problem", "cm", "do"] and st != null and st.is_open():
			later.append(source)
	net.move_effects_last(later)


## Reward the player (a resolved problem, a completed mission); a new belt
## is an event.
func grant(xp: int, budget: int) -> void:
	var belt := Progression.belt_index(profile.xp)
	profile.xp += xp
	_add_budget(budget)
	if Progression.belt_index(profile.xp) > belt:
		events.append({"type": "belt", "belt": Progression.belt_index(profile.xp)})


## The quarterly review on the KPI board (see KpiBoard.review); the measured
## improvement is rewarded.
func kpi_review(choices: Dictionary) -> Dictionary:
	var result := board.review(net, choices)
	if result["error"].is_empty():
		grant(result["xp"], result["budget"])
	return result


## Key clues of a problem the player has found.
func key_clues_found(problem_id: String) -> int:
	return problems[problem_id].clues.filter(func(c: Clue) -> bool: return c.key and found.has(c.id)).size()


func _score_inputs(st: ProblemState, p: ProblemDef, standardise: bool) -> Dictionary:
	var keys := p.clues.filter(func(c: Clue) -> bool: return c.key).map(func(c: Clue) -> String: return c.id)
	var evidence: Array = st.a3["evidence"]
	var before: float = st.baseline["capacity"]
	var capacity: float = snapshot(p.id)["capacity"]
	return {
		"key_found": key_clues_found(p.id),
		"key_total": keys.size(),
		# Walked another step of the same value stream.
		"scouted": observed.keys().any(func(place: String) -> bool:
			return place != p.step and place.get_slice(".", 0) == p.stream_id()),
		"blamed": st.blamed,
		"cause_correct": st.cause_correct,
		"key_linked": evidence.filter(func(id: String) -> bool: return id in keys).size(),
		"herrings_linked": evidence.filter(func(id: String) -> bool: return not id in keys).size(),
		"eff": st.eff,
		"failed_checks": st.failed_checks,
		"prediction_right": st.a3["prediction"] == p.kpi,
		"standardised": standardise,
		"waste_right": st.waste_right,
		"capacity_gain": (capacity - before) / before if before > 0.0 else 0.0,
		"at_constraint": st.baseline["at_constraint"],
	}


## An unstandardised fix fades: the improvement goes, and the problem waits,
## dormant, until its mission brings it back (problems only arrive through
## missions, CLAUDE.md §2).
func _recur(st: ProblemState) -> void:
	net.clear_effects("cm:" + st.id)
	state[st.id] = ProblemState.new(st.id)
	events.append({"type": "recurred", "problem": st.id})
