class_name Missions
extends RefCounted
## The campaign: missions unlock new and harder missions as the player
## progresses. At most one main mission and three side missions are active
## at once; the coach (a senior manager) mostly asks questions, and only
## about the main mission (CLAUDE.md §2).
##
## Before the campaign comes the training week (Inwerkweek, kind "training"):
## one day at a time, each handing out the next when done. Training days take
## no side slot and the coach helps with them; a returning player skips them.
##
## A standardised fix that slips (Sustain.SLIPPING_HEALTH) brings a check-in:
## a small side mission (Terugval) to go and look, built here, never a free
## problem (Merijn, 2026-10-15). An audit at the place or a routine there
## completes it; ignored until the fix wears out, it ends and the problem
## comes back through its own mission.
##
## Missions drive the Region (accepting one activates its problem) and read
## it to see when a goal is met; the Region does not know about missions.

const MAX_MAIN := 1
const MAX_SIDE := 3
## Every third question at the same stage, the coach shares an insight.
const INSIGHT_EVERY := 3
const P := ProblemState.Phase
## Where the player stands, as the coach sees it (see stage_of).
const STAGES := ["go_see", "understand", "experiment", "reflect"]
## The effects source of a training day's setup.
const SETUP_SOURCE := "setup:"
## Check-in missions are named after their problem.
const CHECKIN_PREFIX := "terugval_"
## ESTIMATE: a small reward, like a side mission's smallest (an hour's work).
const CHECKIN_XP := 100

var region: Region
var defs: Dictionary[String, MissionDef] = {}
## {name, role, stages: {stage: [questions]}}
var coach: Dictionary
## Missions the player has accepted, or whose deadline passed: id → {status:
## active | completed | failed, asks: {stage: count}, seen: {"place|tool":
## true} (observe goals: what was used while it was active)}. A mission whose
## fix faded is erased from it, so it is available again.
var progress: Dictionary[String, Dictionary] = {}
## Missions completed at least once: rewarded, unlocking what follows, and
## past any deadline, even when a faded fix reopens them.
var done_once: Dictionary[String, bool] = {}
## When each mission with a deadline opened (minutes): its clock starts there.
## Also when each training day started (GameSession keeps it: its weekday
## names the day). Kept after the mission ends (small, and harmless).
var opened_at: Dictionary[String, int] = {}
## {type: accepted | completed | failed | reopened | checkin, mission} for the UI (a
## new belt is a Region event; tell the player about a faded fix by
## `reopened`, not Region's `recurred`).
var events: Array[Dictionary] = []


func _init(of_region: Region, mission_defs: Array[MissionDef], coach_def: Dictionary) -> void:
	region = of_region
	coach = coach_def
	for m in mission_defs:
		defs[m.id] = m
		if m.kind == "training" and not m.goal_problem.is_empty():
			region.practice[m.goal_problem] = true


## available | active | completed | failed | locked
func status(id: String) -> String:
	if progress.has(id):
		return progress[id]["status"]
	return "available" if _unlocked(defs[id]) else "locked"


func available() -> Array[MissionDef]:
	var out: Array[MissionDef] = []
	for m: MissionDef in defs.values():
		if status(m.id) == "available":
			out.append(m)
	return out


## Active missions, of one kind ("main", "side" or "training") or all.
func active(kind: String = "") -> Array[MissionDef]:
	var out: Array[MissionDef] = []
	for id: String in progress:
		if progress[id]["status"] == "active" and (kind.is_empty() or defs[id].kind == kind):
			out.append(defs[id])
	return out


## Start a mission. Returns "" or an error code: unknown, not_available,
## locked, main_active, side_full, problem_unavailable.
func accept(id: String) -> String:
	var m: MissionDef = defs.get(id)
	if m == null:
		return "unknown"
	if progress.has(id):
		return "not_available"
	if not _unlocked(m):
		return "locked"
	if m.kind == "main" and active("main").size() >= MAX_MAIN:
		return "main_active"
	if m.kind == "side" and active("side").size() >= MAX_SIDE:
		return "side_full"
	if not m.goal_problem.is_empty() and m.goal_type != "sustain":  # a check-in looks at a resolved fix
		var st: ProblemState = region.state.get(m.goal_problem)
		if st == null or st.phase == P.RESOLVED or (st.phase == P.DORMANT and not region.activate(m.goal_problem)):
			return "problem_unavailable"
	progress[id] = {"status": "active", "asks": {}, "seen": {}}
	_set_up(m)
	region.profile.learn(m.teaches)
	events.append({"type": "accepted", "mission": id})
	return ""


## A gemba tool (or "conversation" for a question) was used at a place: active
## observe goals note it.
func note_use(place: String, tool: String) -> void:
	for m in active():
		if m.goal_type == "observe" and place in m.goal_places and (m.goal_tool.is_empty() or m.goal_tool == tool):
			progress[m.id]["seen"][place + "|" + tool] = true


## The Check days an active mission sets for its problem (the training
## week's short Check); -1: the real Check (Region.CHECK_DAYS).
func check_days_for(problem_id: String) -> int:
	for m in active():
		if m.goal_problem == problem_id and m.check_days > 0:
			return m.check_days
	return -1


## Still in the training week: a training day not yet done.
func in_training() -> bool:
	return defs.values().any(func(m: MissionDef) -> bool: return m.kind == "training" and not done_once.has(m.id))


## A returning player skips the training week: every day counts as done,
## without rewards, and a practice problem it opened goes back to sleep.
func skip_training() -> void:
	for m: MissionDef in defs.values():
		if m.kind != "training" or status(m.id) == "completed":
			continue
		if status(m.id) == "active" and not m.goal_problem.is_empty():
			region.deactivate(m.goal_problem)
		progress[m.id] = {"status": "completed", "asks": {}, "seen": {}}
		done_once[m.id] = true
	_clear_week_setup()


## Stop an active mission; it becomes available again. Its problem stays.
func abandon(id: String) -> bool:
	if status(id) != "active":
		return false
	progress.erase(id)
	_clear_setup(defs[id])
	return true


## Complete the missions whose goal is met, start the clock of missions with
## a deadline that just opened, and fail those past it (taken on or not).
## The game loop calls it after every Region action and time step.
func update() -> void:
	_reopen_faded()
	_sync_checkins()
	for m in active():
		if _goal_met(m):
			_complete(m)
	for m: MissionDef in defs.values():
		if m.deadline_days < 0 or done_once.has(m.id) or not status(m.id) in ["available", "active"]:
			continue
		if not opened_at.has(m.id):
			opened_at[m.id] = region.net.time
		elif region.net.time > opened_at[m.id] + SimCalendar.days(m.deadline_days):
			_fail(m)


## A completed solve mission whose problem is dormant again (the fix faded)
## opens again: the problem comes back through it. Not a training day: its
## practice problem is retired once the day is done (the Friday lesson's
## fade shows in its forecast, GameSession.fade_forecast).
func _reopen_faded() -> void:
	for id: String in progress.keys():
		var m := defs[id]
		if progress[id]["status"] == "completed" and m.goal_type == "solve" and m.kind != "training" \
				and region.state[m.goal_problem].phase == P.DORMANT:
			progress.erase(id)
			events.append({"type": "reopened", "mission": id})


## Open a check-in for every standardised fix that slipped (no routine
## holding it; again once an earlier one is done), and end those whose fix
## wore out: its own mission reopens instead.
func _sync_checkins() -> void:
	for id: String in defs.keys():
		if id.begins_with(CHECKIN_PREFIX) and region.state[defs[id].goal_problem].phase != P.RESOLVED:
			defs.erase(id)
			progress.erase(id)
	for p: ProblemDef in region.problem_list():
		var st: ProblemState = region.state[p.id]
		var id := CHECKIN_PREFIX + p.id
		if st.phase != P.RESOLVED or not st.standardised or region.practice.has(p.id) \
				or region.held_by_routine(p.id) or region.health(p.id) >= Sustain.SLIPPING_HEALTH \
				or (defs.has(id) and status(id) != "completed"):
			continue
		defs[id] = checkin_def(p)
		progress.erase(id)
		events.append({"type": "checkin", "mission": id})


## The check-in mission for a slipping fix (Dutch game text).
static func checkin_def(p: ProblemDef) -> MissionDef:
	return MissionDef.from_dict({
		"id": CHECKIN_PREFIX + p.id, "name": "Terugval: " + p.name, "kind": "side", "tier": p.tier,
		"briefing": "De verbetering bij \"%s\" zakt weg. Ga kijken of de standaard nog gevolgd wordt: doe een audit op de plek, of plan er een vaste routine." % p.name,
		"debrief": "De standaard wordt weer gevolgd. Een verbetering die niemand onderhoudt, slijt.",
		"goal": {"type": "sustain", "problem": p.id}, "rewards": {"xp": CHECKIN_XP, "budget": 0},
		"teaches": ["leader_standard_work"],
	})


func _fail(m: MissionDef) -> void:
	progress[m.id] = {"status": "failed", "asks": {}, "seen": {}}
	region.close_countermeasures(m.fail_closes)
	events.append({"type": "failed", "mission": m.id})


## Ask the coach. With no mission named, about the main mission (or, before
## the campaign, the training day). Returns {kind: question | insight |
## no_main | not_main, text?, stage?}.
func ask_coach(mission_id: String = "") -> Dictionary:
	if not mission_id.is_empty() and defs.has(mission_id) and defs[mission_id].kind == "side":
		return {"kind": "not_main"}
	var coached := active("main")
	coached.append_array(active("training"))
	if coached.is_empty():
		return {"kind": "no_main"}
	var m := coached[0]
	var stage := stage_of(m)
	var asks: Dictionary = progress[m.id]["asks"]
	asks[stage] = int(asks.get(stage, 0)) + 1
	if asks[stage] % INSIGHT_EVERY == 0 and m.insights.has(stage):
		return {"kind": "insight", "text": m.insights[stage], "stage": stage}
	var questions: Array = coach["stages"].get(stage, [])
	var text: String = questions[(asks[stage] - 1) % questions.size()] if not questions.is_empty() else ""
	return {"kind": "question", "text": text, "stage": stage}


## Where the player stands, as the coach sees it: go_see (find the problem
## at the gemba), understand (grasp the actual condition and the cause),
## experiment (an A3 running), reflect (checked or done).
func stage_of(m: MissionDef) -> String:
	if m.goal_problem.is_empty():
		return "go_see"
	match region.state[m.goal_problem].phase:
		P.SPOTTED:
			return "understand"
		P.DOING, P.CHECK_READY:
			return "experiment"
		P.CHECKED, P.RESOLVED:
			return "reflect"
	return "understand" if region.key_clues_found(m.goal_problem) > 0 else "go_see"


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func to_dict() -> Dictionary:
	return {"progress": progress.duplicate(true), "opened_at": opened_at.duplicate(), "done_once": done_once.keys()}


## Restore to_dict() output. Returns the mission ids the content no longer
## has (dropped).
func load_dict(d: Dictionary) -> Array[String]:
	progress.clear()
	opened_at.clear()
	done_once.clear()
	_rebuild_checkins(d)
	var once: Variant = d.get("done_once", [])
	for id: Variant in once if once is Array else []:
		if defs.has(str(id)):
			done_once[str(id)] = true
	var opened := JsonFile.dict_or_empty(d.get("opened_at"))
	for id: Variant in opened:
		if defs.has(str(id)):
			opened_at[str(id)] = int(opened[id])
	var dropped: Array[String] = []
	var saved: Variant = d.get("progress", {})
	if not saved is Dictionary:
		return dropped
	for id: Variant in saved:
		var entry: Variant = saved[id]
		if defs.has(str(id)) and entry is Dictionary and entry.get("status") in ["active", "completed", "failed"]:
			progress[str(id)] = {"status": entry["status"], "asks": JsonFile.dict_or_empty(entry.get("asks")),
				"seen": JsonFile.dict_or_empty(entry.get("seen"))}
		else:
			dropped.append(str(id))
	# A missed deadline closed its doors for good.
	for id: String in progress:
		if progress[id]["status"] == "failed":
			region.close_countermeasures(defs[id].fail_closes)
	return dropped


## Check-ins are built, not content: a save's check-in ids (in progress or
## done_once) are built again for problems the content still has.
func _rebuild_checkins(d: Dictionary) -> void:
	var ids: Array = JsonFile.dict_or_empty(d.get("progress")).keys()
	var once: Variant = d.get("done_once", [])
	ids.append_array(once if once is Array else [])
	for id: Variant in ids:
		var problem_id := str(id).trim_prefix(CHECKIN_PREFIX)
		if str(id).begins_with(CHECKIN_PREFIX) and region.problems.has(problem_id):
			defs[str(id)] = checkin_def(region.problems[problem_id])


func _unlocked(m: MissionDef) -> bool:
	if Progression.belt_index(region.profile.xp) < m.requires_belt:
		return false
	for id in m.requires_missions:
		if not done_once.has(id):
			return false
	return true


func _goal_met(m: MissionDef) -> bool:
	match m.goal_type:
		"walk":
			for step in region.net.stream(m.goal_stream).steps:
				if step.kind == SimStep.Kind.WORK and not region.observed.has(m.goal_stream + "." + step.id):
					return false
			return true
		"investigate":
			return region.key_clues_found(m.goal_problem) >= m.goal_clues
		"solve":
			return region.state[m.goal_problem].phase == P.RESOLVED
		"check":
			return region.state[m.goal_problem].phase in [P.CHECKED, P.RESOLVED]
		"sustain":
			return region.held_by_routine(m.goal_problem) or region.health(m.goal_problem) >= Sustain.SLIPPING_HEALTH
		"observe":
			var seen: Dictionary = progress[m.id]["seen"]
			for place in m.goal_places:
				if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
					return false
			return seen.size() >= m.goal_uses
	return false


## A completed day reports what it measured: an observe goal with
## queue_count gives the queues at its places now (Region.queue_at), so the
## lesson names what the numbers say.
func _complete(m: MissionDef) -> void:
	progress[m.id]["status"] = "completed"
	if not done_once.has(m.id):
		done_once[m.id] = true
		region.grant(m.reward_xp, m.reward_budget)
	var event := {"type": "completed", "mission": m.id}
	if m.goal_type == "observe" and m.goal_tool == "queue_count":
		var queues := {}
		for place in m.goal_places:
			queues[place] = region.queue_at(place)
		event["queues"] = queues
	events.append(event)
	if m.kind == "training":
		_hand_out_next_day(m)
	if not in_training():
		_clear_week_setup()


## A training day's staged situation goes onto the simulation when it is
## accepted and holds until the week ends (Wednesday counts the bottleneck
## Monday's setup makes, Thursday works on it). Content validates it; a
## refusal would only lose the staging.
func _set_up(m: MissionDef) -> void:
	if m.setup.is_empty():
		return
	var refused := region.net.set_effects(SETUP_SOURCE + m.id, m.setup)
	if not refused.is_empty():
		push_warning("mission %s: setup refused: %s" % [m.id, refused])


func _clear_setup(m: MissionDef) -> void:
	if not m.setup.is_empty():
		region.net.clear_effects(SETUP_SOURCE + m.id)


## The week is over or skipped: every training day's staging goes.
func _clear_week_setup() -> void:
	for m: MissionDef in defs.values():
		if m.kind == "training":
			_clear_setup(m)


## The coach hands out the next training day as soon as one is done, so the
## practice problem is never without its mission.
func _hand_out_next_day(done: MissionDef) -> void:
	for next: MissionDef in defs.values():
		if next.kind == "training" and done.id in next.requires_missions and status(next.id) == "available":
			accept(next.id)
