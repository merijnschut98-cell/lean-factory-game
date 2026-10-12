class_name Missions
extends RefCounted
## The campaign: missions unlock new and harder missions as the player
## progresses. At most one main mission and three side missions are active
## at once; the coach (a senior manager) mostly asks questions, and only
## about the main mission (CLAUDE.md §2).
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

var region: Region
var defs: Dictionary[String, MissionDef] = {}
## {name, role, stages: {stage: [questions]}}
var coach: Dictionary
## Missions the player has accepted, or whose deadline passed: id → {status:
## active | completed | failed, asks: {stage: count}}.
var progress: Dictionary[String, Dictionary] = {}
## When each mission with a deadline opened (minutes): its clock starts there.
var opened_at: Dictionary[String, int] = {}
## {type: accepted | completed | failed, mission} for the UI (a new belt is a
## Region event).
var events: Array[Dictionary] = []


func _init(of_region: Region, mission_defs: Array[MissionDef], coach_def: Dictionary) -> void:
	region = of_region
	coach = coach_def
	for m in mission_defs:
		defs[m.id] = m


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


## Active missions, of one kind ("main" or "side") or all.
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
	if not m.goal_problem.is_empty():
		var st: ProblemState = region.state.get(m.goal_problem)
		if st == null or st.phase == P.RESOLVED or (st.phase == P.DORMANT and not region.activate(m.goal_problem)):
			return "problem_unavailable"
	progress[id] = {"status": "active", "asks": {}}
	events.append({"type": "accepted", "mission": id})
	return ""


## Stop an active mission; it becomes available again. Its problem stays.
func abandon(id: String) -> bool:
	if status(id) != "active":
		return false
	progress.erase(id)
	return true


## Complete the missions whose goal is met, start the clock of missions with
## a deadline that just opened, and fail those past it (taken on or not).
## The game loop calls it after every Region action and time step.
func update() -> void:
	for m in active():
		if _goal_met(m):
			_complete(m)
	for m: MissionDef in defs.values():
		if m.deadline_days < 0 or not status(m.id) in ["available", "active"]:
			continue
		if not opened_at.has(m.id):
			opened_at[m.id] = region.net.time
		elif region.net.time > opened_at[m.id] + SimCalendar.days(m.deadline_days):
			_fail(m)


func _fail(m: MissionDef) -> void:
	progress[m.id] = {"status": "failed", "asks": progress.get(m.id, {}).get("asks", {})}
	region.close_countermeasures(m.fail_closes)
	events.append({"type": "failed", "mission": m.id})


## Ask the coach. With no mission named, about the main mission. Returns
## {kind: question | insight | no_main | not_main, text?, stage?}.
func ask_coach(mission_id: String = "") -> Dictionary:
	if not mission_id.is_empty() and defs.has(mission_id) and defs[mission_id].kind != "main":
		return {"kind": "not_main"}
	var mains := active("main")
	if mains.is_empty():
		return {"kind": "no_main"}
	var m := mains[0]
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
	return {"progress": progress.duplicate(true), "opened_at": opened_at.duplicate()}


## Restore to_dict() output. Returns the mission ids the content no longer
## has (dropped).
func load_dict(d: Dictionary) -> Array[String]:
	progress.clear()
	opened_at.clear()
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
			progress[str(id)] = {"status": entry["status"], "asks": JsonFile.dict_or_empty(entry.get("asks"))}
		else:
			dropped.append(str(id))
	return dropped


func _unlocked(m: MissionDef) -> bool:
	if Progression.belt_index(region.profile.xp) < m.requires_belt:
		return false
	for id in m.requires_missions:
		if status(id) != "completed":
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
	return false


func _complete(m: MissionDef) -> void:
	progress[m.id]["status"] = "completed"
	region.grant(m.reward_xp, m.reward_budget)
	events.append({"type": "completed", "mission": m.id})
