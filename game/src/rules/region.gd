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
## quarterly review, see KpiBoard), region:drift (stagnation, see Sustain),
## routine:<place> (the team's time for a planned routine).
##
## A resolved fix wears (Sustain): its effects fade and the problem's creep
## back, slower the stronger the sustaining habits and faster the longer it is
## neglected, until it recurs and its mission brings it back. A planned
## routine holds a standardised fix. While the region stops improving, it
## drifts back.

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
## Debt stops here: the directie carries what the region loses beyond it,
## so the way back stays within reach (recovery is always possible, CLAUDE.md
## §2). ESTIMATE: the size of the starting budget, about four solved problems
## with their missions' rewards, or a few months of held fixes' savings.
const DEBT_FLOOR := -50000
## In a bad period the directie funds an experiment only up to what the region has above
## the floor, and always one this small (QA 2.12 (c), ruling 2026-10-23): the cheap fixes
## and the way back are the way out, never a lock-out. ESTIMATE: a small team experiment, a
## few days of time and material (the way back's own fixes cost EUR 0-3,000).
const DEBT_FUNDED_MINIMUM := 3000
## The most the directie advances for the story's experiments (advance_owed); past it they
## are funded only as any experiment in a bad period is (fundable), so recovery
## stays within reach (gate backlog 1, 2026-10-24: careless play owed EUR 233,000-250,000
## and spent 80-88 % of its days at the floor without it). ESTIMATE: half the floor, two or
## three of the larger experiments (EUR 8,000-12,000); about what a held fix's grants and
## savings repay in a few months. Every tier-1 problem keeps a fix within DEBT_FUNDED_MINIMUM.
const ADVANCE_CEILING := 25000
## Finance books part of what a held fix saves (less overtime, rework, repeat
## visits, status calls) into the improvement budget: every week this share
## of the grant for a perfect result on the problem (Pdca.BUDGET_BASE), at
## the fix's health, while the team that runs it trusts you. Long-term,
## respectful play pays its way. ESTIMATE: the grant once a year (€96–346 a
## week a fix); a self-funding CI programme reinvests a share of its savings.
const SAVINGS_RATE := 1.0 / 52.0
## The Check looks ahead with and without the fix (CheckForecast): one lead
## time of the orders the problem holds up, then MEASURE_DAYS over which the
## KPIs are measured, so that the orders measured started after the fix; at
## least a quarter (as the KPI review), at most three. ESTIMATES (probe
## 2026-10-15, real network, 6 seeds): a 14-day window one lead time ahead
## swings ±13 % on the same fix, eight weeks ±3–5 %; grid reinforcement (7
## months of waiting) shows only after half a year.
const CHECK_HORIZON := 91
const MAX_CHECK_HORIZON := 273
const MEASURE_DAYS := 56
const BAD_PERIOD_SOURCE := "region:bad_period"
const DRIFT_SOURCE := "region:drift"
const ROUTINE_SOURCE := "routine:"
const AFTERMATH_SOURCE := "aftermath:"
const TRUST_MIN := -2
const TRUST_MAX := 1

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
## Countermeasures whose needs (earlier preparations) are not met yet;
## Missions keeps it current from the facts (path dependence).
var unprepared: Dictionary[String, bool] = {}
## Problems only the training week opens (Missions marks them): practice,
## so they say nothing about the region's maturity.
var practice: Dictionary[String, bool] = {}
## Trust per team (pool id), TRUST_MIN..TRUST_MAX: below 0 they stop sharing.
var trust: Dictionary[String, int] = {}
## How the MT sees the CI lead (Reputation), next to trust and the budget.
var reputation := Reputation.new()
## {type: activated | check_ready | slipping | recurred | belt | bad_period | kpi_review | reputation, ...} for the world and UI.
var events: Array[Dictionary] = []
## The KPI board; its menu comes from use_kpis.
var board := KpiBoard.new(KpiMenu.new())
## Problem costs not yet taken from the budget (charged in whole euros).
var _cost_owed := 0.0
## Whole days that ended with the budget at DEBT_FLOOR, in all (it never falls): the way
## back, a cost-saving side chain, opens on it (QA 2.12 (c); the measure floor_days>=n).
var floor_days := 0
## What the directie advanced (EUR): the part of an experiment's cost the floor would have
## swallowed. Any later income repays it first, before the budget rises again, so a fix
## started at the floor is never free (review of 3c40ed8..381d21c #4). At most
## ADVANCE_CEILING for the story's experiments; a failed Check's part is written off.
var advance_owed := 0
## Since when the region has not improved (minutes; the last resolved Act or
## the campaign's start); -1: drift has not started (start_drift).
var drift_from := -1
## The drift level now on the network (set only when it changes).
var _drift_applied := 0.0
## Open problems the main quest holds outside the mission slots (MAX_OPEN): a fork's waiting
## bottleneck branch (Missions keeps it current every update; not saved, derived).
var uncounted: Dictionary[String, bool] = {}
## Places with a planned routine (leader standard work), see plan_routine.
var routines: Dictionary[String, bool] = {}
## Aftermaths of short-term fixes (CountermeasureDef.aftermath): problem →
## {cm, start, end (minutes), started}.
var aftermaths: Dictionary[String, Dictionary] = {}


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


## The region's maturity (1–4): a tier counts once most of its problems are
## resolved. Practice problems do not count.
func maturity() -> int:
	var m := 1
	while m < 4:
		var tier := problem_list().filter(func(p: ProblemDef) -> bool: return p.tier == m and not practice.has(p.id))
		var done := tier.filter(func(p: ProblemDef) -> bool: return state[p.id].phase == P.RESOLVED)
		if tier.is_empty() or done.size() < tier.size() * MATURITY_STEP:
			break
		m += 1
	return m


func trust_of(place: String) -> int:
	return trust.get(_team(place), 0)


## The team you talk to at a place ("" at a wait step).
func team_at(place: String) -> String:
	return _team(place)


## Change a team's trust (bounded); the new trust.
func change_trust(team: String, delta: int) -> int:
	trust[team] = clampi(trust.get(team, 0) + delta, TRUST_MIN, TRUST_MAX)
	return trust[team]


## Change the reputation (Reputation's deltas); an event when it moved.
func earn_reputation(delta: int, reason: String) -> void:
	var event := reputation.change(delta, reason)
	if not event.is_empty():
		events.append(event)


# ── Time ────────────────────────────────────────────────────────────────────

func advance_days(n: float) -> void:
	advance(SimCalendar.days(n))


## Time passes a day at a time at most, so fixes wear and the region drifts
## as it goes (the simulation runs the same in pieces).
func advance(minutes: int) -> void:
	var end := net.time + minutes
	while net.time < end:
		var next_day := SimCalendar.days(SimCalendar.day_of(net.time) + 1)
		_advance_within_day(mini(end, next_day) - net.time)


func _advance_within_day(minutes: int) -> void:
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
		elif st.phase == P.RESOLVED and st.a3.has("cm"):
			_wear(st, minutes)
	_run_aftermaths()
	_apply_drift()


## Start and end the aftermaths whose time has come.
func _run_aftermaths() -> void:
	for problem_id: String in aftermaths.keys():
		var a := aftermaths[problem_id]
		var cm: CountermeasureDef = countermeasures.get(str(a["cm"]))
		if cm == null:
			aftermaths.erase(problem_id)
			continue
		if not a["started"] and net.time >= int(a["start"]):
			a["started"] = true
			var refused := net.set_effects(AFTERMATH_SOURCE + problem_id, cm.aftermath.get("effects", []))
			if not refused.is_empty():
				push_warning("aftermath of %s refused: %s" % [cm.id, refused])
			_add_budget(-int(cm.aftermath.get("cost", 0)))
			events.append({"type": "aftermath", "problem": problem_id, "cm": cm.id})
		if a["started"] and net.time >= int(a["end"]):
			net.clear_effects(AFTERMATH_SOURCE + problem_id)
			aftermaths.erase(problem_id)


## What the problems cost per week now: each open one's cost, weakened by a
## working countermeasure, and what creeps back as resolved fixes wear.
func weekly_cost() -> float:
	var total := 0.0
	for st: ProblemState in state.values():
		total += _cost_of(st)
	return total


## What held fixes put into the budget per week now (SAVINGS_RATE): practice
## fixes and those of a team that does not trust you bring nothing.
func weekly_savings() -> float:
	var total := 0.0
	for st: ProblemState in state.values():
		var p := problems[st.id]
		if st.phase == P.RESOLVED and not practice.has(st.id) and trust_of(p.step) >= 0:
			total += Pdca.BUDGET_BASE[p.severity] * SAVINGS_RATE * Sustain.health(st.wear)
	return total


func _cost_of(st: ProblemState) -> float:
	if st.phase == P.RESOLVED:
		return problems[st.id].cost_per_week * (1.0 - Sustain.health(st.wear))
	return problems[st.id].cost_per_week * (1.0 - st.eff) if st.is_open() else 0.0


## Take the weekly costs, less the savings, for `days` passed days from the
## budget.
func _charge_costs(days: int) -> void:
	if days <= 0:
		return
	_cost_owed += (weekly_cost() - weekly_savings()) * days / 7.0
	var whole := floori(_cost_owed)
	_cost_owed -= whole
	_add_budget(-whole)
	if profile.budget <= DEBT_FLOOR:
		floor_days += days


## Whether the directie pays for `cm` on `problem_id` now: always out of debt (an experiment
## may still run into it); in a bad period only up to what the region has above the floor, a
## small one, or the problem's cheapest fix still open (review 381d21c..0ec040f #8: a missed
## deadline can close the cheap ones, as Henk's farewell does; no problem is locked out).
func fundable(cm: CountermeasureDef, problem_id: String = "") -> bool:
	return not in_bad_period() or cm.budget <= maxi(DEBT_FUNDED_MINIMUM, profile.budget - DEBT_FLOOR) \
		or cm.budget <= _cheapest_fix(problem_id)


## The budget of the problem's cheapest fitting countermeasure still available (0: none).
func _cheapest_fix(problem_id: String) -> int:
	var p: ProblemDef = problems.get(problem_id)
	if p == null:
		return 0
	var cheapest := -1
	for c in available_countermeasures():
		if p.countermeasures.has(c.id) and (cheapest < 0 or c.budget < cheapest):
			cheapest = c.budget
	return maxi(0, cheapest)


## Debt is allowed, down to DEBT_FLOOR; it starts a bad period, and paying it
## off ends it.
func in_bad_period() -> bool:
	return profile.budget < 0


func _add_budget(amount: int) -> void:
	var repaid := clampi(amount, 0, advance_owed)  # income repays the directie's advance first
	advance_owed -= repaid
	amount -= repaid
	var was_bad := in_bad_period()
	profile.budget = maxi(DEBT_FLOOR, profile.budget + amount)
	if in_bad_period() != was_bad:
		_apply_bad_period()
		events.append({"type": "bad_period", "started": in_bad_period()})
		if in_bad_period():
			earn_reputation(Reputation.BAD_PERIOD, "bad_period")


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
## False when it is not dormant or MAX_OPEN problems are already open (an uncounted one needs
## no slot).
func activate(problem_id: String) -> bool:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != P.DORMANT or _open_count() >= MAX_OPEN and not uncounted.has(problem_id):
		return false
	st.phase = P.ACTIVE
	_apply_problem(st)
	events.append({"type": "activated", "problem": problem_id})
	return true


## Put an open problem back to sleep without a fix: its effects, a running
## experiment and its state go (a skipped training week takes its practice
## problem with it).
func deactivate(problem_id: String) -> void:
	if not state.has(problem_id):
		return
	for source in ["problem:", "cm:", "do:"]:
		net.clear_effects(source + problem_id)
	state[problem_id] = ProblemState.new(problem_id)


func _open_count() -> int:
	return state.values().filter(func(s: ProblemState) -> bool: return s.is_open() and not uncounted.has(s.id)).size()


## The problem hurts the simulation at the strength a countermeasure leaves;
## with `cm`, the countermeasure's own effects start too.
func _apply_problem(st: ProblemState, cm: CountermeasureDef = null) -> void:
	var sources := Pdca.treated_effects(problems[st.id], cm, st.eff)
	for source: String in sources:
		net.set_effects(source, sources[source])


# ── Plan: Go & See ──────────────────────────────────────────────────────────

## Spend time at a place with a gemba tool (the caller advances the clock by
## Investigation.TOOLS[tool].minutes). One use goes one "why" deeper.
## Returns {spotted: problem ids, clues: Array[Clue], hidden_signal}, and
## for queue_count the queue counted (queue_at).
func use_tool(place: String, tool: String) -> Dictionary:
	var spotted := _spot(place, Investigation.TOOLS[tool]["deep"])
	var clues := _ready_clues(place, tool)
	for c in clues:
		_reveal(c)
	var result := {"spotted": spotted, "clues": clues, "hidden_signal": spotted.is_empty() and _hidden_at(place)}
	if tool == "queue_count":
		result["queue"] = queue_at(place)
	return result


## The queue at a place now: {count (orders waiting, Network.waiting_at),
## days (of the team's work they hold, Network.queue_days)}.
func queue_at(place: String) -> Dictionary:
	return _queue(net, net.step_at(place))


static func _queue(network: Network, step: SimStep) -> Dictionary:
	return {"count": network.waiting_at(step), "days": network.queue_days(step)}


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
			change_trust(team, -1)
			earn_reputation(Reputation.BLAME, "blame")
			for p in problem_list():
				if state[p.id].is_open() and team in _pools_at(p.step):
					state[p.id].blamed = true
			profile.learn(["respect_for_people"])
			return {"kind": kind, "reply": "blame", "trust": trust[team]}
		"repair":
			change_trust(team, 1)
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
	var queue := net.waiting_at(step)
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


func _has_team(place: String) -> bool:
	return not _pools_at(place).is_empty()


func _pools_at(place: String) -> PackedStringArray:
	var step := net.step_at(place)
	return step.pool_ids if step != null else PackedStringArray()


## The team you talk to at a place: the first pool doing the work there.
func _team(place: String) -> String:
	var pools := _pools_at(place)
	return pools[0] if not pools.is_empty() else ""


# ── Plan → Do: the A3 ───────────────────────────────────────────────────────

## Countermeasures this region can try: up to one tier above its maturity,
## not closed, and prepared for.
func available_countermeasures() -> Array[CountermeasureDef]:
	var m := maturity()
	var out: Array[CountermeasureDef] = []
	for c: CountermeasureDef in countermeasures.values():
		if c.tier <= m + 1 and not closed.has(c.id) and not unprepared.has(c.id):
			out.append(c)
	return out


func close_countermeasures(ids: PackedStringArray) -> void:
	for id in ids:
		closed[id] = true


## Submit the A3 {waste, cause (index into the cause bank), evidence (clue
## ids), cm, prediction (a KPI)} and start the experiment; it may be paid
## into debt, but in a bad period only what the region can carry (fundable), unless it is
## `always_funded` (the active main mission's or a deadline mission's: never locked out);
## what the region cannot carry the directie advances (advance_owed), up to ADVANCE_CEILING:
## past the floor, or the whole of an exempt experiment a bad period would refuse.
## The Check is due after `check_days` (a mission may shorten it for
## practice). Returns "" or why not: not_spotted | waste | cause | evidence |
## countermeasure | prediction | same_countermeasure (a rework must try
## another one) | no_funds.
func submit_a3(problem_id: String, a3: Dictionary, check_days: int = CHECK_DAYS, always_funded := false) -> String:
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
	if st.rework_from.get("cm") == cm.id:
		return "same_countermeasure"
	# What the region cannot carry the directie advances: past the floor, or all of an exempt
	# experiment a bad period would refuse (the region pays none of it, as if refused).
	var carried := fundable(cm, problem_id)
	var advanced := maxi(0, cm.budget - (profile.budget - DEBT_FLOOR)) if carried else cm.budget
	if not carried and not (always_funded and advance_owed + advanced <= ADVANCE_CEILING):
		return "no_funds"

	var p := problems[problem_id]
	advance_owed += advanced
	st.advanced = advanced
	_add_budget(advanced - cm.budget)
	st.baseline = snapshot(problem_id)
	var e := Pdca.effectiveness(p, cm, maturity())
	st.a3 = a3.duplicate()
	st.a3["evidence"] = evidence
	st.cause_correct = options[a3["cause"]] == p.root_cause
	st.waste_right = a3["waste"] == p.waste
	st.eff = e["eff"]
	st.level = e["level"]
	st.phase = P.DOING
	st.check_at = net.time + SimCalendar.days(check_days)
	_apply_problem(st, cm)
	if not st.rework_from.is_empty():
		net.clear_effects("problem:" + problem_id)  # the old fix holds it meanwhile
	net.set_effects("do:" + problem_id, _team_hours(cm, check_days))
	profile.learn(["A3", "kata_prediction"])
	return ""


## The improvement work takes the team's hours from daily work while the
## experiment runs: an availability effect spread over the check period.
func _team_hours(cm: CountermeasureDef, check_days: int) -> Array:
	var effects := []
	for pool_id in cm.team_hours:
		var pool: SimPool = net.pools.get(pool_id)
		if pool != null:
			var hours_in_period := pool.headcount * pool.schedule.hours() * check_days / 7.0
			effects.append({"target": pool_id, "property": "availability", "value": -cm.team_hours[pool_id] / hours_in_period})
	return effects


## The end-to-end numbers of the problem's stream: KPIs over the last
## CHECK_DAYS, capacity and constraint (and whether the problem's team is
## it), and the problem's own step.
func snapshot(problem_id: String) -> Dictionary:
	var p := problems[problem_id]
	var out := measures(net, p.step)
	out["at_constraint"] = out["constraint_pool"] in _pools_at(p.step)
	out["cost_per_week"] = _cost_of(state[problem_id])
	return out


## The end-to-end numbers of the stream through `place` on any network (the
## region's own, or a forecast's copy): KPIs over the last `window_days`,
## capacity and constraint, and the place's step: its statistics and queue
## now (as queue_at).
static func measures(network: Network, place: String, window_days: int = CHECK_DAYS) -> Dictionary:
	var stream := network.stream(place.get_slice(".", 0))
	var step := network.step_at(place)
	var c: Dictionary = Capacity.analyse(network)["streams"][stream.id]
	var k := stream.kpis(network.time, window_days)
	return {
		"capacity": c["capacity_per_week"], "constraint_pool": c["constraint_pool"],
		"throughput": k["throughput_per_week"], "lead_time": k["lead_days_p50"],
		"first_time_right": k["first_time_right"], "on_time": k["on_time"],
		# The age of the open work: long waits show before their orders finish.
		"wip_age": network.open_age_days(stream),
		"step": step.stats_since(SimCalendar.day_of(network.time) - window_days),
		"queue": _queue(network, step),
	}


# ── Check ───────────────────────────────────────────────────────────────────

## Did the fix move the KPI the A3 predicted? The coming lead time with the
## fix against without it (CheckForecast): it passes when the countermeasure
## works (Pdca.CHECK_PASS) and the predicted KPI is better by more than
## Pdca.CHECK_NOISE. Returns {passed, before, after (snapshots), forecast
## (CheckForecast.run, with kpi: the prediction and gain: its gain), level,
## cause_correct, waste_right, lesson, not_constraint}, or {error} when the
## forecast cannot run. lesson is a code: cause_right | cause_wrong (passed) |
## mismatch | too_early | not_moved (failed).
func check(problem_id: String) -> Dictionary:
	var st := state[problem_id]
	if st.phase != P.CHECK_READY:
		return {}
	var p := problems[problem_id]
	net.clear_effects("do:" + problem_id)
	var after := snapshot(problem_id)
	var horizon := check_window(p, _lead_days(p, after))
	var forecast := CheckForecast.run(net, p, horizon.x, horizon.y)
	if not forecast["error"].is_empty():
		return {"error": forecast["error"]}
	forecast["kpi"] = st.a3["prediction"]
	forecast["gain"] = forecast["gains"][forecast["kpi"]]
	st.gains = forecast["gains"]
	st.checked = {"with": ProblemState.kpi_values(forecast["with"]),
		"without": ProblemState.kpi_values(forecast["without"])}
	var works := st.eff >= Pdca.CHECK_PASS
	var result := {
		"passed": works and forecast["gain"] > Pdca.CHECK_NOISE, "before": st.baseline, "after": after,
		"forecast": forecast, "level": st.level, "cause_correct": st.cause_correct, "waste_right": st.waste_right,
		"lesson": "cause_right" if st.cause_correct else "cause_wrong",
		# The step got better, but the stream still waits on another team. A
		# wait or material step has no team and adds no capacity: what it
		# takes out is lead time, wherever it is on the path.
		"not_constraint": _has_team(p.step) and not st.baseline["at_constraint"] and st.gains["capacity"] < 0.01,
	}
	profile.learn(["PDCA", "eight_wastes", "waste_" + p.waste])
	if result["not_constraint"]:
		profile.learn(["bottleneck_focus", "theory_of_constraints"])
	if not result["passed"]:
		advance_owed -= mini(advance_owed, st.advanced)  # the directie took the risk
	st.advanced = 0
	if result["passed"]:
		st.phase = P.CHECKED
		if countermeasures[st.a3["cm"]].unlocks == KpiBoard.UNLOCK and board.unlock(net.time):
			events.append({"type": "kpi_review"})  # the first review is due at once
		return result
	result["lesson"] = "mismatch" if st.level == "mismatch" else ("too_early" if not works else "not_moved")
	st.failed_checks += 1
	st.eff = 0.0
	st.level = ""
	st.phase = P.SPOTTED
	net.clear_effects("cm:" + problem_id)
	if st.rework_from.is_empty():
		_apply_problem(st)
	else:
		_apply_old_fix(st)  # a rework that failed: the old fix is still there
	return result


## The Check's forecast (days ahead, the measured window at their end): one lead time of
## the orders the problem holds up, then the problem's measure_days (MEASURE_DAYS unless it
## names more, for a stream with few orders), within CHECK_HORIZON..MAX_CHECK_HORIZON.
static func check_window(p: ProblemDef, lead: int) -> Vector2i:
	var days := clampi(lead + maxi(MEASURE_DAYS, p.measure_days), CHECK_HORIZON, MAX_CHECK_HORIZON)
	return Vector2i(days, clampi(days - lead, MEASURE_DAYS, days))


## One lead time of the orders the problem holds up, in whole days: the
## stream's median now, or the problem's step's own wait when that is longer
## (a long wait only some orders take, such as grid reinforcement).
func _lead_days(p: ProblemDef, now: Dictionary) -> int:
	var step := net.step_at(p.step)
	var wait := (step.wait_minutes + step.batch_minutes) / float(SimCalendar.MINUTES_PER_DAY)
	return ceili(maxf(now["lead_time"], wait))


# ── Act ─────────────────────────────────────────────────────────────────────

## Close a checked problem: standardise (costs budget; the main sustaining
## habit, so the gain wears far slower) or not (it lasts about the
## countermeasure's decay_days, see Sustain). A resolved improvement ends the
## region's stagnation. Returns the score.
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
	st.standardised = standardise
	st.rework_from = {}
	st.wear = 0.0
	net.clear_effects("problem:" + problem_id)
	_reassert_board()
	if drift_from >= 0:
		drift_from = net.time
		_apply_drift()
	profile.learn(p.teaches + (PackedStringArray(["standard_work"]) if standardise else PackedStringArray()))
	_after_act(problem_id, countermeasures[st.a3["cm"]])
	grant(Pdca.xp_for(st.score, p.tier), Pdca.budget_for(st.score, p.severity))
	return st.score


## A short-term fix's later costs: trust at once, its aftermath in time.
func _after_act(problem_id: String, cm: CountermeasureDef) -> void:
	for team: String in cm.trust:
		change_trust(team, int(cm.trust[team]))
	if not cm.aftermath.is_empty():
		var start := net.time + SimCalendar.days(int(cm.aftermath.get("after_days", 0)))
		aftermaths[problem_id] = {"cm": cm.id, "start": start, "started": false,
			"end": start + SimCalendar.days(int(cm.aftermath.get("days", 0)))}


## Standardise a fix after its Act (same cost as at the Act): standard work
## holds it from now on; what already wore away stays worn, and the score
## stays the Act's. "" or not_resolved | standardised | no_budget.
func standardise(problem_id: String) -> String:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != P.RESOLVED:
		return "not_resolved"
	if st.standardised:
		return "standardised"
	if profile.budget < STANDARDISE_BUDGET:
		return "no_budget"
	_add_budget(-STANDARDISE_BUDGET)
	st.standardised = true
	profile.learn(["standard_work"])
	return ""


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
		if st != null and st.is_open():
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


## The quarterly review on the KPI board (see KpiBoard.review); the forecast
## gain of the chosen KPIs over the habit is rewarded.
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
		"capacity_gain": st.gains.get("capacity", 0.0),
		"at_constraint": st.baseline["at_constraint"],
		"team_step": _has_team(p.step),
		"lead_time_gain": st.gains.get("lead_time", 0.0),
		"durable": standardise or countermeasures[st.a3["cm"]].decay_days < 0,
	}


## A worn-out fix: the improvement goes, and the problem waits, dormant,
## until its mission brings it back (problems only arrive through missions,
## CLAUDE.md §2).
func _recur(st: ProblemState) -> void:
	net.clear_effects("cm:" + st.id)
	net.clear_effects("problem:" + st.id)
	state[st.id] = ProblemState.new(st.id)
	events.append({"type": "recurred", "problem": st.id})


# ── Rework: a repair quest swaps a poor fix for a better one ───────────────

## Take a resolved fix back to the A3 (a repair quest): the player writes a
## new A3 from what was found, while the old fix keeps running and the
## problem does not come back. "" or why not: not_resolved | full (MAX_OPEN).
func start_rework(problem_id: String) -> String:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != P.RESOLVED or not countermeasures.has(st.a3.get("cm", "")):
		return "not_resolved"
	if _open_count() >= MAX_OPEN:
		return "full"
	st.rework_from = {"cm": st.a3["cm"], "eff": st.eff, "level": st.level, "standardised": st.standardised,
		"wear": st.wear, "neglect": st.neglect, "score": st.score}
	st.phase = P.SPOTTED
	return ""


## Drop a rework that has no experiment running: the old fix stays as it was.
func cancel_rework(problem_id: String) -> void:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.rework_from.is_empty() or not st.phase in [P.SPOTTED, P.ACTIVE]:
		return
	var old := st.rework_from
	st.a3 = st.a3.duplicate()
	st.a3["cm"] = old["cm"]
	for key in ["eff", "level", "standardised", "wear", "neglect", "score"]:
		st.set(key, old[key])
	st.rework_from = {}
	st.phase = P.RESOLVED
	_apply_old_fix(st)


## The fix a rework would replace, on the network as it was (its health).
func _apply_old_fix(st: ProblemState) -> void:
	var old := st.rework_from if not st.rework_from.is_empty() else {"cm": st.a3["cm"], "eff": st.eff, "wear": st.wear}
	var sources := Sustain.eroded_effects(problems[st.id], countermeasures[old["cm"]], old["eff"], Sustain.health(old["wear"]))
	for source: String in sources:
		net.set_effects(source, sources[source])


# ── Sustain: fixes wear, audits refresh them ────────────────────────────────

## The sustaining habits holding a resolved fix: {strength 0..1, mechanisms
## (Sustain.WEIGHTS keys, in that order)}. Standard work from the Act; a held
## fix in the same stream whose countermeasure `sustains` (a board); a team at
## the step that steers by KPIs on the board.
func sustain(problem_id: String) -> Dictionary:
	var st: ProblemState = state.get(problem_id)
	var mechanisms: Array[String] = []
	if st == null or st.phase != P.RESOLVED:
		return {"strength": 0.0, "mechanisms": mechanisms}
	var p := problems[problem_id]
	if st.standardised:
		mechanisms.append("standard_work")
	if _board_holds(p):
		mechanisms.append("visual_management")
	if Array(_pools_at(p.step)).any(func(pool: String) -> bool: return not board.chosen.get(pool, []).is_empty()):
		mechanisms.append("kpis")
	var strength := 0.0
	for m in mechanisms:
		strength += Sustain.WEIGHTS[m]
	return {"strength": strength, "mechanisms": mechanisms}


## Another resolved fix in the problem's stream holds with a board (`sustains`).
func _board_holds(p: ProblemDef) -> bool:
	return problem_list().any(func(other: ProblemDef) -> bool:
		var st := state[other.id]
		return other.id != p.id and other.stream_id() == p.stream_id() and st.phase == P.RESOLVED \
			and countermeasures.has(st.a3.get("cm", "")) and countermeasures[st.a3["cm"]].sustains)


## A resolved fix's health (1 fresh, 0.5 at recurrence); 1 for anything else.
func health(problem_id: String) -> float:
	var st: ProblemState = state.get(problem_id)
	return Sustain.health(st.wear) if st != null and st.phase == P.RESOLVED else 1.0


## The days of neglect the fix lasts at today's habits (Sustain.life_days),
## times its owner's buy-in (Sustain.BUY_IN); 0 when there is no fix.
func life_days(problem_id: String) -> float:
	var st: ProblemState = state.get(problem_id)
	if st == null or st.phase != P.RESOLVED or not countermeasures.has(st.a3.get("cm", "")):
		return 0.0
	return Sustain.life_days(Sustain.base_days(countermeasures[st.a3["cm"]]), sustain(problem_id)["strength"]) \
		* Sustain.BUY_IN[st.buy_in]


## Days until a resolved fix recurs if nothing changes: INF while a routine
## holds it, -1 when there is no fix.
func days_to_recur(problem_id: String) -> float:
	var life := life_days(problem_id)
	if life <= 0.0:
		return -1.0
	return INF if held_by_routine(problem_id) else Sustain.days_left(state[problem_id].wear, life)


## A planned routine at the step holds a standardised fix (there is a
## standard to hold it to).
func held_by_routine(problem_id: String) -> bool:
	var st: ProblemState = state.get(problem_id)
	return st != null and st.phase == P.RESOLVED and st.standardised and routines.has(problems[problem_id].step)


## A gemba audit of the standard at a place (the caller advances the clock
## by Sustain.AUDIT_MINUTES): standardised fixes there are back in full use;
## unstandardised ones have no standard to audit against.
## Returns {refreshed, no_standard}: problem ids.
func audit(place: String) -> Dictionary:
	var refreshed: Array[String] = []
	var no_standard: Array[String] = []
	for p in problem_list():
		var st := state[p.id]
		if p.step != place or st.phase != P.RESOLVED:
			continue
		if st.standardised:
			st.wear = 0.0
			st.neglect = 0.0
			if countermeasures.has(st.a3.get("cm", "")):
				_apply_wear(st)
			refreshed.append(p.id)
		else:
			no_standard.append(p.id)
	observed[place] = true
	profile.learn(["standard_work", "leader_standard_work"])
	return {"refreshed": refreshed, "no_standard": no_standard}


## `minutes` of wear on a resolved fix, at its life now and faster the
## longer it is neglected; worn to 1 it recurs. A routine holds it as it is.
func _wear(st: ProblemState, minutes: int) -> void:
	if held_by_routine(st.id):
		st.neglect = 0.0
		return
	var was := Sustain.health(st.wear)
	var days := minutes / float(SimCalendar.MINUTES_PER_DAY)
	st.wear += Sustain.wear_over(st.neglect, days, life_days(st.id))
	st.neglect += days
	if st.wear >= 1.0 - 1e-9:
		_recur(st)
		return
	if was >= Sustain.SLIPPING_HEALTH and Sustain.health(st.wear) < Sustain.SLIPPING_HEALTH:
		events.append({"type": "slipping", "problem": st.id})
	_apply_wear(st)


## The fix's and the problem's effects at the fix's health.
func _apply_wear(st: ProblemState) -> void:
	var sources := Sustain.eroded_effects(problems[st.id], countermeasures[st.a3["cm"]], st.eff, Sustain.health(st.wear))
	for source: String in sources:
		net.set_effects(source, sources[source])


## Plan a routine at a place (leader standard work, no mission needed): the
## team gives Sustain.ROUTINE_HOURS_PER_WEEK every week, and standardised
## fixes there stop wearing while it runs. "" or why not: unknown_place |
## no_team (a wait step) | planned.
func plan_routine(place: String) -> String:
	if net.step_at(place) == null:
		return "unknown_place"
	var pool: SimPool = net.pools.get(_team(place))
	if pool == null:
		return "no_team"
	if routines.has(place):
		return "planned"
	var weekly_hours := pool.headcount * pool.schedule.hours()
	var refused := net.set_effects(ROUTINE_SOURCE + place,
		[{"target": pool.id, "property": "availability", "value": -Sustain.ROUTINE_HOURS_PER_WEEK / weekly_hours}])
	if not refused.is_empty():
		return "no_team"
	routines[place] = true
	profile.learn(["standard_work", "leader_standard_work"])
	return ""


## Stop a routine: the team's time is back, and neglect counts from now.
## "" or not_planned.
func stop_routine(place: String) -> String:
	if not routines.erase(place):
		return "not_planned"
	net.clear_effects(ROUTINE_SOURCE + place)
	return ""


# ── Stagnation drift ────────────────────────────────────────────────────────

## Start counting stagnation (the campaign opens). Idempotent.
func start_drift() -> void:
	if drift_from < 0:
		drift_from = net.time


## Days since the last resolved improvement (0 before drift starts).
func stagnant_days() -> float:
	return (net.time - drift_from) / float(SimCalendar.MINUTES_PER_DAY) if drift_from >= 0 else 0.0


func drift_level() -> float:
	return Sustain.drift_level(stagnant_days())


## The drift's effects follow its level. Content validates the
## targets, so a refusal is a bug worth a warning, not a crash.
func _apply_drift() -> void:
	var level := drift_level()
	if is_equal_approx(level, _drift_applied):
		return
	_drift_applied = level
	if level <= 0.0:
		net.clear_effects(DRIFT_SOURCE)
		return
	var refused := net.set_effects(DRIFT_SOURCE, Sustain.drift_effects(net, level))
	if not refused.is_empty():
		push_warning("drift refused: " + refused)
