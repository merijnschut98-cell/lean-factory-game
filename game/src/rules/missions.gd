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
## Every open problem belongs to an active mission (problems only arrive
## through missions): a finished investigation, an abandoned mission or one
## that ended without its problem solved puts the problem back to sleep; the
## clues found are kept.
##
## Path dependence (catalogue §2.15): the facts of what the player did and
## chose (Facts) gate missions (requires.facts) and countermeasures (needs);
## a countermeasure whose preparation is missing is not offered (Region's
## `unprepared`), and shows with its hint.
##
## Missions drive the Region (accepting one activates its problem) and read
## it to see when a goal is met; the Region does not know about missions.

const MAX_MAIN := 1
const MAX_SIDE := 3
## Every third question at the same stage, the coach shares an insight.
const INSIGHT_EVERY := 3
## The coach does not repeat a line the player heard in the last this many
## asks (audit §3A.1: the same opener came back in 14 missions).
const NO_REPEAT := 6
## A fix chosen to fade within this many days, while a lasting one fits as
## well, gets the coach's long-term question (audit §3A.2, an estimate).
const FADING_DAYS := 45
## The coach's conditional questions (content: coach.conditional).
const CONDITIONS: Array[String] = ["blamed", "fading_fix"]
## A debrief's variants, in the order they win (content: debrief_variants).
const DEBRIEF_VARIANTS: Array[String] = ["blamed", "poor_fix", "not_standardised"]
const P := ProblemState.Phase
## Where the player stands, as the coach sees it (see stage_of).
const STAGES := ["go_see", "understand", "experiment", "reflect"]
## The effects source of a training day's setup.
const SETUP_SOURCE := "setup:"
## Check-in missions are named after their problem.
const CHECKIN_PREFIX := "terugval_"
## ESTIMATE: a small reward, like a side mission's smallest (an hour's work).
const CHECKIN_XP := 100
## Half a solve mission's reward is for finishing it, half for how well the
## problem was solved (its PDCA score), so the thorough, lasting fix pays more
## than the quick one (CLAUDE.md §2, long term over short term; audit R1).
## At the lowest score (5 of 25) a player still earns MIN_REWARD_SHARE.
const REWARD_FOR_FINISHING := 0.5
const MIN_REWARD_SHARE := 0.6
## A fix is poor when its countermeasure fits this much less than the
## problem's best one (ESTIMATE, catalogue §2.15), or the A3 named a wrong
## root cause.
const POOR_FIT_GAP := 0.2
## The outcomes that meet a talk_to goal (dialog spec §5.1). A yes under
## pressure meets it too, but pays COMPLIANCE_SHARE and no reputation: a
## quick win scores lower than the patient one (CLAUDE.md §2).
const TALK_MEETS := {"partial": ["partial", "commitment", "compliance"], "commitment": ["commitment", "compliance"]}
const COMPLIANCE_SHARE := 0.5

var region: Region
var defs: Dictionary[String, MissionDef] = {}
## {name, role, stages: {stage: [questions]}, conditional: {blamed?,
## fading_fix?}}
var coach: Dictionary
## The coach's last NO_REPEAT lines, across missions.
var heard: Array[String] = []
## Missions the player has accepted: id → {status: active | completed, asks:
## {stage: count}, seen: {"place|tool": true} (observe goals: what was used
## while it was active)}. A mission whose fix faded is erased from it, so it
## is available again.
var progress: Dictionary[String, Dictionary] = {}
## Missions completed at least once: rewarded, unlocking what follows, and
## past any deadline, even when a faded fix reopens them.
var done_once: Dictionary[String, bool] = {}
## When each mission with a deadline opened (minutes): its clock starts there.
## Also when each training day started (GameSession keeps it: its weekday
## names the day). Kept after the mission ends (small, and harmless).
var opened_at: Dictionary[String, int] = {}
## Missions whose deadline passed: their door (fail_closes) is closed for
## good, but the mission itself can still be done, without a clock, so its
## problem can still be solved another way (CLAUDE.md §2).
var failed_once: Dictionary[String, bool] = {}
## {type: accepted | completed | failed | reopened | checkin | repair, mission}
## and {type: dividend | overload, ...} (Stewardship) for the UI (a
## new belt is a Region event; tell the player about a faded fix by
## `reopened`, not Region's `recurred`).
var events: Array[Dictionary] = []
## The recorded facts (Facts); done: and failed: and the measures are read
## live (knows).
var facts := Facts.new()
## Problems resolved at the last update, with their countermeasure, so a new
## Act's facts are noted once.
var _resolved: Dictionary[String, String] = {}
## Repair quests for poor fixes (Repairs; built here, like check-ins).
var repairs := Repairs.new()
## Dividends for fixes that hold, trust lost to overload (Stewardship).
var stewardship := Stewardship.new()
## Deadlines met because the fix was in place when the date came (R5).
var deadline_kept: Dictionary[String, bool] = {}
## A dialog's best outcome so far (GameSession.talk_outcome): what a talk_to
## goal reads. Missions knows no people; GameSession hands this in.
var talk_outcome: Callable = func(_dialog_id: String) -> String: return ""


func _init(of_region: Region, mission_defs: Array[MissionDef], coach_def: Dictionary) -> void:
	region = of_region
	coach = coach_def
	for m in mission_defs:
		defs[m.id] = m
		if m.kind == "training" and not m.goal_problem.is_empty():
			region.practice[m.goal_problem] = true
	_lock_unprepared()


## available | active | completed | locked (a missed deadline: see failed)
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
	if m.goal_type == "rework_fix":
		if not region.start_rework(m.goal_problem).is_empty():
			return "problem_unavailable"
	elif _holds_problem(m):
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


## Whether the mission's deadline passed before it was done (its door closed).
func failed(id: String) -> bool:
	return failed_once.has(id)


## Stop an active mission; it becomes available again and its problem goes
## back to sleep (the clues found are kept). "" or not_active |
## experiment_running (an A3's experiment is running or waiting for its Act).
func abandon(id: String) -> String:
	if not defs.has(id) or status(id) != "active":
		return "not_active"
	var m := defs[id]
	if _holds_problem(m) and region.state[m.goal_problem].phase in [P.DOING, P.CHECK_READY, P.CHECKED]:
		return "experiment_running"
	progress.erase(id)
	_clear_setup(m)
	if m.goal_type == "rework_fix":
		region.cancel_rework(m.goal_problem)  # the old fix stays
	_retire_orphans()
	return ""


## Complete the missions whose goal is met, start the clock of missions with
## a deadline that just opened, and fail those past it (taken on or not).
## The game loop calls it after every Region action and time step.
func update() -> void:
	_note_fixes()
	_reopen_faded()
	_sync_checkins()
	_sync_repairs()
	events.append_array(stewardship.update(region))
	for m in active():
		if _goal_met(m):
			_complete(m)
	for m: MissionDef in defs.values():
		if m.deadline_days < 0 or done_once.has(m.id) or failed_once.has(m.id) or deadline_kept.has(m.id) \
				or not status(m.id) in ["available", "active"]:
			continue
		if not opened_at.has(m.id):
			opened_at[m.id] = region.net.time
		elif region.net.time > opened_at[m.id] + SimCalendar.days(m.deadline_days):
			if _fix_in_place(m):
				deadline_kept[m.id] = true  # the A3 is in: the Check still judges it (R5)
			else:
				_fail(m)
	_retire_orphans()
	_lock_unprepared()


## Whether a fact or a measure holds (Facts): done: and failed: from the
## missions, maturity>= and reputation>= from the region, the rest recorded.
func knows(atom: String) -> bool:
	var measure := Facts.measure(atom)
	if not measure.is_empty():
		return (region.maturity() if measure[0] == "maturity" else region.reputation.value) >= measure[1]
	match atom.get_slice(":", 0):
		"done":
			return done_once.has(atom.get_slice(":", 1))
		"failed":
			return failed_once.has(atom.get_slice(":", 1))
		"checked":
			var st: ProblemState = region.state.get(atom.get_slice(":", 1))
			return st != null and st.phase in [P.CHECKED, P.RESOLVED]
	return facts.has(atom)


func needs_met(needs: Dictionary) -> bool:
	return Facts.met(needs, knows)


## Countermeasures not offered because an earlier preparation is missing
## ("niet voorbereid": show each one's `preparation` hint), not those closed
## for good.
func unprepared() -> Array[CountermeasureDef]:
	var out: Array[CountermeasureDef] = []
	for c: CountermeasureDef in region.countermeasures.values():
		if region.unprepared.has(c.id) and not region.closed.has(c.id):
			out.append(c)
	return out


## The briefing to show: the reopen text when the mission is back because its
## fix faded.
func briefing_of(id: String) -> String:
	var m := defs[id]
	var back := done_once.has(id) and status(id) != "completed"
	return m.reopen_text if back and not m.reopen_text.is_empty() else m.briefing


## The debrief to show, reading the play (audit §5.7): a blaming question
## while it was open, a poor fix, a fix not standardised, the fork branch done
## first, in that order; the plain debrief otherwise.
func debrief_of(id: String) -> String:
	var m := defs[id]
	var st: ProblemState = region.state.get(m.goal_problem)
	var holds := {
		"blamed": st != null and st.blamed,
		"poor_fix": knows("poor_fix:" + m.goal_problem),
		"not_standardised": st != null and st.phase == P.RESOLVED and not st.standardised,
	}
	for variant: String in DEBRIEF_VARIANTS:
		if holds[variant] and m.debrief_variants.has(variant):
			return m.debrief_variants[variant]
	var first := not m.fork_group.is_empty() and facts.has("fork_first:%s:%s" % [m.fork_group, id])
	return m.debrief_first if first and not m.debrief_first.is_empty() else m.debrief


## Note the facts of every new Act: the countermeasure chosen (replacing an
## earlier choice), whether it was standardised, and whether it was a poor
## fix. Practice problems are not part of the story.
func _note_fixes() -> void:
	for p in region.problem_list():
		var st: ProblemState = region.state[p.id]
		var resolved := st.phase == P.RESOLVED and st.a3.has("cm") and not region.practice.has(p.id)
		if resolved and (_resolved.get(p.id) != st.a3["cm"] or facts.with_prefix("chose:%s:" % p.id).is_empty()):
			_note_fix(p, st)
		if resolved:
			_resolved[p.id] = st.a3["cm"]
		else:
			_resolved.erase(p.id)


func _note_fix(p: ProblemDef, st: ProblemState) -> void:
	var cm: String = st.a3["cm"]
	facts.remove_prefix("chose:%s:" % p.id)
	facts.add("chose:%s:%s" % [p.id, cm])
	stewardship.noted(p.id, region.net.time)
	for kind in ["standardised", "poor_fix"]:
		facts.remove("%s:%s" % [kind, p.id])
	if st.standardised:
		facts.add("standardised:" + p.id)
	var best: float = p.countermeasures.values().max()
	repairs.due.erase(p.id)
	if not st.cause_correct or p.countermeasures.get(cm, 0.0) <= best - POOR_FIT_GAP + 1e-9:
		facts.add("poor_fix:" + p.id)
		repairs.due[p.id] = region.net.time + SimCalendar.days(Repairs.AFTER_DAYS)


## Keep the Region's unprepared countermeasures current with the facts.
func _lock_unprepared() -> void:
	region.unprepared.clear()
	for c: CountermeasureDef in region.countermeasures.values():
		if not c.needs.is_empty() and not needs_met(c.needs):
			region.unprepared[c.id] = true


## Whether an active mission's countermeasure is in place: its A3 submitted
## (or further), so a deadline counts as met (audit R5, QA #19).
func _fix_in_place(m: MissionDef) -> bool:
	return status(m.id) == "active" and _holds_problem(m) \
		and region.state[m.goal_problem].phase in [P.DOING, P.CHECK_READY, P.CHECKED, P.RESOLVED]


## Whether the mission's goal brings and holds a problem (a check-in looks
## at a resolved fix and holds nothing).
static func _holds_problem(m: MissionDef) -> bool:
	return not m.goal_problem.is_empty() and m.goal_type != "sustain"


## Every open problem belongs to an active mission: one nobody works on any
## more (an investigation done, a mission dropped) goes back to sleep, so it
## neither hurts the simulation nor takes one of Region.MAX_OPEN's places.
func _retire_orphans() -> void:
	var held := {}
	for m in active():
		if _holds_problem(m):
			held[m.goal_problem] = true
	for id: String in region.state:
		if region.state[id].is_open() and not held.has(id):
			region.deactivate(id)


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


## Open a repair quest for a poor fix whose weakness shows (Repairs), and
## take back the ones whose fix is gone or no longer poor (not one being
## worked on).
func _sync_repairs() -> void:
	for id: String in defs.keys():
		var problem_id := defs[id].goal_problem if id.begins_with(Repairs.PREFIX) else ""
		if not problem_id.is_empty() and status(id) != "active" and (region.state[problem_id].phase != P.RESOLVED
				or status(id) == "available" and not knows("poor_fix:" + problem_id)):
			defs.erase(id)
			progress.erase(id)
	for problem_id: String in repairs.due.keys():
		var id := Repairs.PREFIX + problem_id
		if region.state[problem_id].phase != P.RESOLVED or not knows("poor_fix:" + problem_id):
			repairs.due.erase(problem_id)
		elif region.net.time >= repairs.due[problem_id] and not defs.has(id) and repairs.shows(region, problem_id):
			defs[id] = Repairs.def_for(region.problems[problem_id])
			events.append({"type": "repair", "mission": id})


## The check-in mission for a slipping fix (Dutch game text).
static func checkin_def(p: ProblemDef) -> MissionDef:
	return MissionDef.from_dict({
		"id": CHECKIN_PREFIX + p.id, "name": "Terugval: " + p.name, "kind": "side", "tier": p.tier,
		"briefing": "De verbetering bij \"%s\" zakt weg. Ga kijken of de standaard nog gevolgd wordt: doe een audit op de plek, of plan er een vaste routine." % p.name,
		"debrief": "De standaard wordt weer gevolgd. Een verbetering die niemand onderhoudt, slijt.",
		"goal": {"type": "sustain", "problem": p.id}, "rewards": {"xp": CHECKIN_XP, "budget": 0},
		"teaches": ["leader_standard_work"],
	})


## The deadline passed: the door closes for good, the mission stays (active
## with its work, or on the board without a clock).
func _fail(m: MissionDef) -> void:
	failed_once[m.id] = true
	region.close_countermeasures(m.fail_closes)
	region.earn_reputation(Reputation.DEADLINE_MISSED, "deadline")
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
	var insights: Array = m.insights.get(stage, [])
	var nth_insight: int = asks[stage] / INSIGHT_EVERY - 1
	if asks[stage] % INSIGHT_EVERY == 0 and nth_insight < insights.size():
		return {"kind": "insight", "text": insights[nth_insight], "stage": stage}
	return {"kind": "question", "text": _question(m, stage, asks[stage]), "stage": stage}


## The next question: a conditional one that applies (once per mission),
## the mission's own, then the general bank starting at a place of the
## mission's own; the first the player did not hear in the last NO_REPEAT
## asks (all heard: in turn).
func _question(m: MissionDef, stage: String, nth: int) -> String:
	var said: Dictionary = progress[m.id].get_or_add("said", {})
	for condition: String in _conditions(m, stage):
		if not said.has(condition) and coach.get("conditional", {}).has(condition):
			said[condition] = true
			return _say(coach["conditional"][condition])
	var candidates: Array = m.questions.get(stage, []).duplicate()
	var bank: Array = coach["stages"].get(stage, [])
	if not bank.is_empty():
		var start := absi(m.id.hash()) % bank.size()
		candidates.append_array(bank.slice(start) + bank.slice(0, start))
	if candidates.is_empty():
		return ""
	for line: String in candidates:
		if not line in heard:
			return _say(line)
	return _say(candidates[(nth - 1) % candidates.size()])


func _say(line: String) -> String:
	heard.erase(line)
	heard.append(line)
	if heard.size() > NO_REPEAT:
		heard.remove_at(0)
	return line


## Conditions the coach asks about now: a blaming question while the problem
## was open (respect for people), and a fix chosen to fade soon while a
## lasting one fits as well (long term over short term).
func _conditions(m: MissionDef, stage: String) -> Array[String]:
	var out: Array[String] = []
	var st: ProblemState = region.state.get(m.goal_problem)
	if st == null:
		return out
	if st.blamed:
		out.append("blamed")
	var cm: CountermeasureDef = region.countermeasures.get(st.a3.get("cm", ""))
	if stage == "experiment" and cm != null and cm.decay_days > 0 and cm.decay_days <= FADING_DAYS:
		var p: ProblemDef = region.problems[m.goal_problem]
		var chosen_fit: float = p.countermeasures.get(cm.id, 0.0)
		if p.countermeasures.keys().any(func(id: String) -> bool:
				var other: CountermeasureDef = region.countermeasures.get(id)
				return other != null and (other.decay_days < 0 or other.decay_days > FADING_DAYS) \
					and p.countermeasures[id] >= chosen_fit):
			out.append("fading_fix")
	return out


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
	return {"progress": progress.duplicate(true), "opened_at": opened_at.duplicate(), "done_once": done_once.keys(),
		"failed_once": failed_once.keys(), "facts": facts.to_list(), "repair_due": repairs.to_dict(),
		"heard": heard.duplicate(), "stewardship": stewardship.to_dict(), "deadline_kept": deadline_kept.keys()}


## Restore to_dict() output. Returns the mission ids the content no longer
## has (dropped).
func load_dict(d: Dictionary) -> Array[String]:
	progress.clear()
	opened_at.clear()
	done_once.clear()
	failed_once.clear()
	# Facts of Acts before the save are kept; old saves note them at the next update.
	facts.load_list(d.get("facts", []))
	repairs.load_dict(JsonFile.dict_or_empty(d.get("repair_due")))
	stewardship.load_dict(JsonFile.dict_or_empty(d.get("stewardship")))
	deadline_kept.clear()
	var kept: Variant = d.get("deadline_kept", [])
	for id: Variant in kept if kept is Array else []:
		if defs.has(str(id)):
			deadline_kept[str(id)] = true
	heard.clear()
	var lines: Variant = d.get("heard", [])
	for line: Variant in lines if lines is Array else []:
		heard.append(str(line))
	_resolved.clear()
	for id: String in region.state:
		if region.state[id].phase == P.RESOLVED and region.state[id].a3.has("cm"):
			_resolved[id] = region.state[id].a3["cm"]
	_rebuild_checkins(d)
	for key: String in ["done_once", "failed_once"]:
		var ids: Variant = d.get(key, [])
		for id: Variant in ids if ids is Array else []:
			if defs.has(str(id)):
				(done_once if key == "done_once" else failed_once)[str(id)] = true
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
		if defs.has(str(id)) and entry is Dictionary and entry.get("status") == "failed":
			failed_once[str(id)] = true  # a save from before failed missions came back
		elif defs.has(str(id)) and entry is Dictionary and entry.get("status") in ["active", "completed"]:
			progress[str(id)] = {"status": entry["status"], "asks": JsonFile.dict_or_empty(entry.get("asks")),
				"seen": JsonFile.dict_or_empty(entry.get("seen"))}
			if entry.has("said"):  # the coach's conditional questions already asked
				progress[str(id)]["said"] = JsonFile.dict_or_empty(entry["said"])
		else:
			dropped.append(str(id))
	# A missed deadline closed its doors for good.
	for id: String in failed_once:
		region.close_countermeasures(defs[id].fail_closes)
	_lock_unprepared()
	return dropped


## Check-ins and repair quests are built, not content: a save's ids (in
## progress or done_once) are built again for problems the content still has.
func _rebuild_checkins(d: Dictionary) -> void:
	var ids: Array = JsonFile.dict_or_empty(d.get("progress")).keys()
	var once: Variant = d.get("done_once", [])
	ids.append_array(once if once is Array else [])
	for id: Variant in ids:
		for prefix: String in [CHECKIN_PREFIX, Repairs.PREFIX]:
			var problem_id := str(id).trim_prefix(prefix)
			if str(id).begins_with(prefix) and region.problems.has(problem_id):
				var p := region.problems[problem_id]
				defs[str(id)] = checkin_def(p) if prefix == CHECKIN_PREFIX else Repairs.def_for(p)


func _unlocked(m: MissionDef) -> bool:
	if Progression.belt_index(region.profile.xp) < m.requires_belt or region.reputation.value < m.requires_reputation:
		return false
	for id in m.requires_missions:
		if not done_once.has(id):
			return false
	if not m.requires_any_of.is_empty() and not Array(m.requires_any_of).any(func(id: String) -> bool: return done_once.has(id)):
		return false
	for team in m.requires_trust:
		if region.trust.get(team, 0) < m.requires_trust[team]:
			return false
	if m.requires_maturity > 1 and region.maturity() < m.requires_maturity:
		return false
	return needs_met(m.requires_facts)


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
		"rework_fix":
			# Accepting took the fix back to the A3; resolved again means the new one passed.
			return region.state[m.goal_problem].phase == P.RESOLVED
		"observe":
			var seen: Dictionary = progress[m.id]["seen"]
			for place in m.goal_places:
				if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
					return false
			return seen.size() >= m.goal_uses
		"talk_to":
			return talk_outcome.call(m.goal_dialog) in TALK_MEETS[m.goal_outcome]
	return false


## A completed day reports what it measured: an observe goal with
## queue_count gives the queues at its places now (Region.queue_at), so the
## lesson names what the numbers say.
func _complete(m: MissionDef) -> void:
	progress[m.id]["status"] = "completed"
	var score: Dictionary = region.state[m.goal_problem].score if m.goal_type == "solve" else {}
	if not done_once.has(m.id):
		done_once[m.id] = true
		var forced: bool = m.goal_type == "talk_to" and talk_outcome.call(m.goal_dialog) == "compliance"
		var share := reward_share(score) * (COMPLIANCE_SHARE if forced else 1.0)
		region.grant(roundi(m.reward_xp * share), roundi(m.reward_budget * share))
		region.earn_reputation(0 if forced else m.reward_reputation, "mission")
		for team in m.reward_trust:
			region.change_trust(team, m.reward_trust[team])
	else:
		region.earn_reputation(Reputation.REOPENED, "reopened")  # owning a regression
	if int(score.get("impact", 0)) >= Reputation.FLOW_IMPACT:
		region.earn_reputation(Reputation.FLOW_GAIN, "flow")
	for flag in m.sets_flags:
		facts.add(flag)
	if m.goal_type == "rework_fix":
		facts.add("repaired:" + m.goal_problem)
		facts.remove("poor_fix:" + m.goal_problem)
		repairs.due.erase(m.goal_problem)
	if not m.fork_group.is_empty() and facts.with_prefix("fork_first:%s:" % m.fork_group).is_empty():
		facts.add("fork_first:%s:%s" % [m.fork_group, m.id])
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


## The share of a solve mission's reward a PDCA score earns (a whole reward
## without a score: a problem resolved outside the PDCA loop).
static func reward_share(score: Dictionary) -> float:
	if not score.has("total"):
		return 1.0
	var quality := clampf(float(score["total"]) / Pdca.MAX_SCORE, 0.0, 1.0)
	return maxf(MIN_REWARD_SHARE, REWARD_FOR_FINISHING + (1.0 - REWARD_FOR_FINISHING) * quality)


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
