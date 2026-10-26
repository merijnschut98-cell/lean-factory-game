class_name MissionSync
extends RefCounted
## The passes that keep the mission log in step with the Region (Missions.update runs them,
## in its own order): problems nobody works on go to sleep, a fork's waiting branch stays on,
## recurring and faded missions come back, slipping fixes and poor fixes get their check-in
## and repair quest. Moved out of Missions (TD-3); they read and write the log's public state.

const P := ProblemState.Phase


## Every open problem belongs to an active mission: one nobody works on any
## more (an investigation done, a mission dropped) goes back to sleep, so it
## neither hurts the simulation nor takes one of Region.MAX_OPEN's places.
static func retire_orphans(m: Missions) -> void:
	var held := {}
	for active in m.active():
		if Missions.holds_problem(active):
			held[active.goal_problem] = true
	for branch in waiting_fork_branches(m):
		held[branch.goal_problem] = true
	for id: String in m.region.state:
		if m.region.state[id].is_open() and not held.has(id):
			m.region.deactivate(id)


## The fork is one main quest (gate backlog 3, 2026-10-24): once a branch is taken, the
## bottleneck branch still waiting for the player hurts too, so the intake does not heal
## while the monteurs are helped, and the non-bottleneck branch's Check can show it brought
## no flow. Only the bottleneck's: the exception to "problems arrive through their mission"
## stays as small as the lesson needs. A branch once done is not waiting: a fix that faded
## comes back through its mission.
static func waiting_fork_branches(m: Missions) -> Array[MissionDef]:
	var taken := {}
	for id: String in m.progress:
		if not m.defs[id].fork_group.is_empty():
			taken[m.defs[id].fork_group] = true
	return m.available().filter(func(branch: MissionDef) -> bool:
		return taken.has(branch.fork_group) and branch.fork_role == "bottleneck" and not m.done_once.has(branch.id) \
			and Missions.holds_problem(branch) and branch.goal_type == "solve")


## Switch on the problem of a fork's bottleneck branch still waiting (waiting_fork_branches).
static func switch_on_forks(m: Missions) -> void:
	sync_uncounted(m)
	for id: String in m.region.uncounted:
		if m.region.state[id].phase == P.DORMANT:
			m.region.activate(id)


## The waiting fork problems take none of the mission slots (Region.uncounted): they must
## never keep a mission's own problem from coming back. Derived, not saved: kept current on
## load, before every update and before a mission is taken on (review 2453246..3c0a190 #1).
static func sync_uncounted(m: Missions) -> void:
	var waiting: Dictionary[String, bool] = {}
	for branch in waiting_fork_branches(m):
		if m.region.state.has(branch.goal_problem):
			waiting[branch.goal_problem] = true
	m.region.uncounted = waiting


## A recurring mission (leader standard work) is offered again its days after it was last done.
static func reoffer_recurring(m: Missions) -> void:
	for id: String in m.progress.keys():
		var def := m.defs[id]
		if def.recurring_days > 0 and m.progress[id]["status"] == "completed" \
				and m.region.net.time >= int(m.progress[id].get("done_at", 0)) + SimCalendar.days(def.recurring_days):
			m.progress.erase(id)
			m.events.append({"type": "recurring", "mission": id})


## A completed solve mission whose problem is dormant again (the fix faded)
## opens again: the problem comes back through it. Not a training day: its
## practice problem is retired once the day is done (the Friday lesson's
## fade shows in its forecast, GameSession.fade_forecast).
static func reopen_faded(m: Missions) -> void:
	for id: String in m.progress.keys():
		var def := m.defs[id]
		if m.progress[id]["status"] == "completed" and def.goal_type == "solve" and def.kind != "training" \
				and m.region.state[def.goal_problem].phase == P.DORMANT:
			m.progress.erase(id)
			m.events.append({"type": "reopened", "mission": id})


## Open a check-in for every standardised fix that slipped (no routine
## holding it; again once an earlier one is done), and end those whose fix
## wore out: its own mission reopens instead.
static func sync_checkins(m: Missions) -> void:
	var region := m.region
	for id: String in m.defs.keys():
		if id.begins_with(Missions.CHECKIN_PREFIX) and region.state[m.defs[id].goal_problem].phase != P.RESOLVED:
			m.defs.erase(id)
			m.progress.erase(id)
	for p: ProblemDef in region.problem_list():
		var st: ProblemState = region.state[p.id]
		var id := Missions.CHECKIN_PREFIX + p.id
		if st.phase != P.RESOLVED or not st.standardised or region.practice.has(p.id) \
				or region.held_by_routine(p.id) or region.health(p.id) >= Sustain.SLIPPING_HEALTH \
				or (m.defs.has(id) and m.status(id) != "completed"):
			continue
		m.defs[id] = Missions.checkin_def(p)
		m.progress.erase(id)
		m.events.append({"type": "checkin", "mission": id})


## Open a repair quest for a poor fix whose weakness shows (Repairs), and
## take back the ones whose fix is gone or no longer poor (not one being
## worked on).
static func sync_repairs(m: Missions) -> void:
	var region := m.region
	for id: String in m.defs.keys():
		var problem_id := m.defs[id].goal_problem if id.begins_with(Repairs.PREFIX) else ""
		if not problem_id.is_empty() and m.status(id) != "active" and (region.state[problem_id].phase != P.RESOLVED
				or m.status(id) == "available" and not m.knows("poor_fix:" + problem_id)):
			m.defs.erase(id)
			m.progress.erase(id)
	for problem_id: String in m.repairs.due.keys():
		var id := Repairs.PREFIX + problem_id
		if region.state[problem_id].phase != P.RESOLVED or not m.knows("poor_fix:" + problem_id):
			m.repairs.due.erase(problem_id)
		elif region.net.time >= m.repairs.due[problem_id] and not m.defs.has(id) and m.repairs.shows(region, problem_id):
			m.defs[id] = Repairs.def_for(region.problems[problem_id])
			m.events.append({"type": "repair", "mission": id})
