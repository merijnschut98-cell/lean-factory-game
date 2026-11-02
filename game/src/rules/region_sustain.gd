class_name RegionSustain
extends RefCounted
## The sustain rules of one Region: the habits holding a resolved fix, its
## health, the wear of every day, the gemba audit and the leader routine that
## refresh or hold it, and the stagnation drift. Region keeps the state these
## rules read and write (the fixes' wear, the routines, the drift start) and
## forwards its public names here.

## The region is held weakly: it owns this object, and a strong reference back
## would be a RefCounted cycle that leaks.
var _owner: WeakRef

var region: Region:
	get:
		return _owner.get_ref()


func _init(host: Region) -> void:
	_owner = weakref(host)


## The sustaining habits holding a resolved fix: {strength 0..1, mechanisms
## (Sustain.WEIGHTS keys, in that order)}. Standard work from the Act; a held
## fix in the same stream whose countermeasure `sustains` (a board); a team at
## the step that steers by KPIs on the board.
func sustain(problem_id: String) -> Dictionary:
	var r := region
	var st: ProblemState = r.state.get(problem_id)
	var mechanisms: Array[String] = []
	if st == null or st.phase != ProblemState.Phase.RESOLVED:
		return {"strength": 0.0, "mechanisms": mechanisms}
	var p := r.problems[problem_id]
	if st.standardised:
		mechanisms.append("standard_work")
	if _board_holds(p):
		mechanisms.append("visual_management")
	if Array(r._pools_at(p.step)).any(func(pool: String) -> bool: return not r.board.chosen.get(pool, []).is_empty()):
		mechanisms.append("kpis")
	var strength := 0.0
	for m in mechanisms:
		strength += Sustain.WEIGHTS[m]
	return {"strength": strength, "mechanisms": mechanisms}


## Another resolved fix in the problem's stream holds with a board (`sustains`).
func _board_holds(p: ProblemDef) -> bool:
	var r := region
	return r.problem_list().any(func(other: ProblemDef) -> bool:
		var st := r.state[other.id]
		return other.id != p.id and other.stream_id() == p.stream_id() and st.phase == ProblemState.Phase.RESOLVED \
			and r.countermeasures.has(st.a3.get("cm", "")) and r.countermeasures[st.a3["cm"]].sustains)


## A resolved fix's health (1 fresh, 0.5 at recurrence); 1 for anything else.
func health(problem_id: String) -> float:
	var st: ProblemState = region.state.get(problem_id)
	return Sustain.health(st.wear) if st != null and st.phase == ProblemState.Phase.RESOLVED else 1.0


## The days of neglect the fix lasts at today's habits (Sustain.life_days),
## times its owner's buy-in (Sustain.BUY_IN); 0 when there is no fix.
func life_days(problem_id: String) -> float:
	var r := region
	var st: ProblemState = r.state.get(problem_id)
	if st == null or st.phase != ProblemState.Phase.RESOLVED or not r.countermeasures.has(st.a3.get("cm", "")):
		return 0.0
	return Sustain.life_days(Sustain.base_days(r.countermeasures[st.a3["cm"]]), sustain(problem_id)["strength"]) \
		* Sustain.BUY_IN[st.buy_in]


## A planned routine at the step holds a standardised fix (there is a
## standard to hold it to).
func held_by_routine(problem_id: String) -> bool:
	var r := region
	var st: ProblemState = r.state.get(problem_id)
	return st != null and st.phase == ProblemState.Phase.RESOLVED and st.standardised \
		and r.routines.has(r.problems[problem_id].step)


## A gemba audit of the standard at a place (the caller advances the clock
## by Sustain.AUDIT_MINUTES): standardised fixes there are back in full use;
## unstandardised ones have no standard to audit against.
## Returns {refreshed, no_standard}: problem ids.
func audit(place: String) -> Dictionary:
	var r := region
	var refreshed: Array[String] = []
	var no_standard: Array[String] = []
	for p in r.problem_list():
		var st := r.state[p.id]
		if p.step != place or st.phase != ProblemState.Phase.RESOLVED:
			continue
		if st.standardised:
			st.wear = 0.0
			st.neglect = 0.0
			if r.countermeasures.has(st.a3.get("cm", "")):
				apply_wear(st)
			refreshed.append(p.id)
		else:
			no_standard.append(p.id)
	r.observed[place] = true
	r.profile.learn(["standard_work", "leader_standard_work"])
	return {"refreshed": refreshed, "no_standard": no_standard}


## `minutes` of wear on a resolved fix, at its life now and faster the
## longer it is neglected; worn to 1 it recurs. A routine holds it as it is.
func wear(st: ProblemState, minutes: int) -> void:
	var r := region
	if held_by_routine(st.id):
		st.neglect = 0.0
		return
	var was := Sustain.health(st.wear)
	var days := minutes / float(SimCalendar.MINUTES_PER_DAY)
	st.wear += Sustain.wear_over(st.neglect, days, life_days(st.id))
	st.neglect += days
	if st.wear >= 1.0 - 1e-9:
		r._recur(st)
		return
	if was >= Sustain.SLIPPING_HEALTH and Sustain.health(st.wear) < Sustain.SLIPPING_HEALTH:
		r.events.append({"type": "slipping", "problem": st.id})
	apply_wear(st)


## The fix's and the problem's effects at the fix's health.
func apply_wear(st: ProblemState) -> void:
	var r := region
	var sources := Sustain.eroded_effects(r.problems[st.id], r.countermeasures[st.a3["cm"]], st.eff, Sustain.health(st.wear))
	for source: String in sources:
		r.net.set_effects(source, sources[source])


## Plan a routine at a place (leader standard work, no mission needed): the
## team gives Sustain.ROUTINE_HOURS_PER_WEEK every week, and standardised
## fixes there stop wearing while it runs. "" or why not: unknown_place |
## no_team (a wait step) | planned.
func plan_routine(place: String) -> String:
	var r := region
	var net := r.net
	if net.step_at(place) == null:
		return "unknown_place"
	var pool: SimPool = net.pools.get(r._team(place))
	if pool == null:
		return "no_team"
	if r.routines.has(place):
		return "planned"
	var weekly_hours := pool.headcount * pool.schedule.hours()
	var refused := net.set_effects(Region.ROUTINE_SOURCE + place,
		[{"target": pool.id, "property": "availability", "value": -Sustain.ROUTINE_HOURS_PER_WEEK / weekly_hours}])
	if not refused.is_empty():
		return "no_team"
	r.routines[place] = true
	r.profile.learn(["standard_work", "leader_standard_work"])
	return ""


## Stop a routine: the team's time is back, and neglect counts from now.
## "" or not_planned.
func stop_routine(place: String) -> String:
	var r := region
	if not r.routines.erase(place):
		return "not_planned"
	r.net.clear_effects(Region.ROUTINE_SOURCE + place)
	return ""


# ── Stagnation drift ────────────────────────────────────────────────────────

## Start counting stagnation (the campaign opens). Idempotent.
func start_drift() -> void:
	var r := region
	if r.drift_from < 0:
		r.drift_from = r.net.time


func drift_level() -> float:
	return Sustain.drift_level(region.stagnant_days())


## The drift's effects follow its level. Content validates the
## targets, so a refusal is a bug worth a warning, not a crash.
func apply_drift() -> void:
	var r := region
	var level := drift_level()
	if is_equal_approx(level, r._drift_applied):
		return
	r._drift_applied = level
	if level <= 0.0:
		r.net.clear_effects(Region.DRIFT_SOURCE)
		return
	var refused := r.net.set_effects(Region.DRIFT_SOURCE, Sustain.drift_effects(r.net, level))
	if not refused.is_empty():
		push_warning("drift refused: " + refused)
