class_name GameSession
extends RefCounted
## One game in progress: the facade the 3D world and the UI call. It owns the
## Catalog, the Region (with the department KPIs) and the Missions, and has
## one method per player action. Each advances the clock where the rules say
## so (the Region never does) and then lets the missions notice what
## happened. Pure logic: no nodes, so it is tested headless.
##
## Results are the rules' own codes and numbers; the UI words them in Dutch.
## Actions that return a Dictionary answer a refused request with only
## {"error": code}; the rules' own results never have an "error" key.
## Actions that return a String give "" or the error code.
## When `error` is not empty (the content could not be loaded) nothing else
## is built: show the message and do not call anything.

## Whole weeks of simulated work before play starts, so the first day of play
## is a Monday (the simulation's week starts on Monday). Half a year: the
## connections stream settles only after months of external waits (as in
## tools/problem_report.gd); a shorter warm-up starts play on a network that
## is still filling up, and every Check then shows lead time drifting worse.
const WARMUP_DAYS := 182
## Play starts at half past eight.
const START_MINUTE := 8 * 60 + 30
## The story so far: the stream was walked before the game starts.
const STORY_MISSION := "walk_connections"
## Dates in the clock text. The simulation counts minutes from Monday 00:00 of
## week 1 and has no calendar date, so day 0 of play (the Monday after the
## warm-up) is Monday 2026-10-12, the start of the project.
const PLAY_START_DATE := {"year": 2026, "month": 10, "day": 12, "hour": 0, "minute": 0, "second": 0}
const WEEKDAYS: Array[String] = ["ma", "di", "wo", "do", "vr", "za", "zo"]
const MONTHS: Array[String] = ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]
## The training week's first day, and its practice problem (fade_forecast's default).
const TRAINING_FIRST := "training_mon"
const TRAINING_PROBLEM := "training_tray"
## A fade forecast looks at most a quarter ahead.
const MAX_FORECAST_DAYS := 91

var catalog: Catalog
var region: Region
var missions: Missions
## The cast and what they remember (dialogs); the talk in progress, if any.
var people: People
var _talk: Dialog = null
## People's events ({type: left, person}) not yet drained.
var _people_events: Array[Dictionary] = []
## Hidden rewards for deep thinking; it hears what the player does.
var discoveries: Discoveries
## The El Amrani family's dossier, followed through the stream.
var followed := FollowedOrder.new()
## The first thing wrong with the content; "" when the game is usable.
var error := ""


## A new game on the real content. `seed_value` fixes the simulation's luck.
## `training`: start with the training week (Inwerkweek), its first day handed
## out; without it (a returning player) the week counts as skipped. Either
## way the story's walk counts as done once the week is over.
static func new_game(seed_value: int = 1, data_dir: String = Catalog.DATA_DIR, training: bool = true) -> GameSession:
	var s := GameSession.new()
	s.catalog = Catalog.load_from(data_dir)
	var net := Network.load_file(data_dir + "/value_streams.json", seed_value)
	s.error = s.catalog.error if not s.catalog.error.is_empty() else net.error
	if not s.error.is_empty():
		return s
	s.region = Region.new(net, s.catalog.problems, s.catalog.countermeasures, Profile.new())
	s.region.use_kpis(s.catalog.kpis)
	s.missions = Missions.new(s.region, s.catalog.missions, s.catalog.coach)
	s.people = People.new(s.catalog.persons, s.catalog.dialogs, s.catalog.dialog_bank)
	s.missions.talk_outcome = s.talk_outcome
	s.discoveries = Discoveries.new(s.catalog.discoveries)
	for id in [STORY_MISSION, TRAINING_FIRST]:
		if not s.missions.defs.has(id):
			s.error = "missing mission: " + id
			return s
	# No problems are active yet, so the warm-up costs nothing and teaches nothing.
	net.advance(SimCalendar.days(WARMUP_DAYS) + START_MINUTE)
	s.followed.pick(net)
	if training:
		s.missions.accept(TRAINING_FIRST)
	else:
		s.missions.skip_training()
		s._walked_before()
	s._after(0)
	return s


# ── Actions ─────────────────────────────────────────────────────────────────

## Take on a mission (activating its problem). "" or Missions.accept's code.
func accept(mission_id: String) -> String:
	var refused := missions.accept(mission_id)
	if refused.is_empty():
		discoveries.note_accept(self, mission_id)
	_after(0)
	return refused


## Drop an active mission; its problem goes back to sleep (clues are kept).
## "" or Missions.abandon's code: not_active | experiment_running.
func abandon(mission_id: String) -> String:
	var refused := missions.abandon(mission_id)
	_after(0)
	return refused


## Use a gemba tool at a place ("stream.step"); the tool's minutes pass.
## Returns Region.use_tool's {spotted, clues, hidden_signal}, or an error:
## unknown_tool | use_ask (a conversation is a question) | unknown_place.
func use_tool(place: String, tool: String) -> Dictionary:
	if not Investigation.TOOLS.has(tool):
		return {"error": "unknown_tool"}
	if tool == "conversation":
		return {"error": "use_ask"}
	if not _is_place(place):
		return {"error": "unknown_place"}
	var result := region.use_tool(place, tool)
	missions.note_use(place, tool)
	discoveries.note_use(self, place, tool, "", result["clues"].any(func(c: Clue) -> bool: return c.key))
	_after(Investigation.TOOLS[tool]["minutes"])
	return result


## Ask the team at a place a question; a conversation's minutes pass.
## Returns Region.ask's result, or an error: unknown_question | unknown_place.
func ask(place: String, question_id: String) -> Dictionary:
	if not Investigation.QUESTIONS.has(question_id):
		return {"error": "unknown_question"}
	if not _is_place(place):
		return {"error": "unknown_place"}
	var result := region.ask(place, question_id)
	missions.note_use(place, "conversation")
	discoveries.note_use(self, place, "conversation", result["reply"], result.has("clue") and result["clue"].key)
	_after(Investigation.TOOLS["conversation"]["minutes"])
	return result


## The Check's days for a problem: an active mission's (the training week's
## short practice Check) or Region.CHECK_DAYS.
func check_days(problem_id: String) -> int:
	var days := missions.check_days_for(problem_id)
	return days if days > 0 else Region.CHECK_DAYS


## Submit the A3 {waste, cause (index into cause_options), evidence (clue
## ids), cm, prediction (a KPI)} and start the experiment. "" or why not:
## unknown_problem | not_spotted | waste | cause | evidence | countermeasure |
## prediction. Malformed fields count as missing.
func submit_a3(problem_id: String, a3: Dictionary) -> String:
	if not region.state.has(problem_id):
		return "unknown_problem"
	var refused := region.submit_a3(problem_id, _cleaned(a3), check_days(problem_id))
	if refused.is_empty():
		discoveries.note_a3(self, problem_id)
	_after(0)
	return refused


## Let the experiment run until the Check is due. "" (also when it already is)
## or unknown_problem | not_doing.
func wait_for_check(problem_id: String) -> String:
	var st: ProblemState = region.state.get(problem_id)
	if st == null:
		return "unknown_problem"
	if st.phase == ProblemState.Phase.CHECK_READY:
		return ""
	if st.phase != ProblemState.Phase.DOING:
		return "not_doing"
	region.advance(maxi(0, st.check_at - region.net.time))
	_after(0)
	return ""


## The Check: the fix against no fix over the coming lead time
## (Region.check's result, a few seconds of simulation on copies), or an
## error: unknown_problem | not_check_ready | a forecast copy's error.
func check(problem_id: String) -> Dictionary:
	if not region.state.has(problem_id):
		return {"error": "unknown_problem"}
	var result := region.check(problem_id)
	if not result.is_empty():
		discoveries.note_check(self, problem_id, result)
	_after(0)
	return result if not result.is_empty() else {"error": "not_check_ready"}


## Close a checked problem, with or without standardising: the score (see
## Pdca.score), or an error: unknown_problem | not_checked.
func act(problem_id: String, standardise: bool) -> Dictionary:
	if not region.state.has(problem_id):
		return {"error": "unknown_problem"}
	var score := region.act(problem_id, standardise)
	if not score.is_empty():
		discoveries.note_act(self, problem_id)
	_after(0)
	return score.duplicate(true) if not score.is_empty() else {"error": "not_checked"}


## Write the standard for a fix acted on without one (Region.standardise);
## it takes Sustain.AUDIT_MINUTES at the place. "" or unknown_problem |
## Region's code: not_resolved | standardised | no_budget.
func standardise(problem_id: String) -> String:
	if not region.problems.has(problem_id):
		return "unknown_problem"
	var refused := region.standardise(problem_id)
	_after(Sustain.AUDIT_MINUTES if refused.is_empty() else 0)
	return refused


## Contain an acute risk in an active safety mission (Missions.contain): ""
## or not_active | no_containment | contained.
func contain(mission_id: String) -> String:
	var refused := missions.contain(mission_id)
	if refused.is_empty():
		discoveries.note_contain(self, mission_id)
	_after(0)
	return refused


## Let time pass (whole or part days, at most a quarter): the player waits
## for something to happen. "" or bad_days.
func wait_days(days: float) -> String:
	if days <= 0.0 or days > MAX_FORECAST_DAYS * 3:
		return "bad_days"
	_after(roundi(days * SimCalendar.MINUTES_PER_DAY))
	return ""


## A gemba audit of the standard at a place (a leader routine, no mission
## needed); Sustain.AUDIT_MINUTES pass. Standardised fixes there are back in
## full use. Returns Region.audit's {refreshed, no_standard} (problem ids), or
## an error: unknown_place.
func audit(place: String) -> Dictionary:
	if not _is_place(place):
		return {"error": "unknown_place"}
	var result := region.audit(place)
	_after(Sustain.AUDIT_MINUTES)
	return result


## Plan a recurring routine at a place (leader standard work, no mission
## needed): the team gives Sustain.ROUTINE_HOURS_PER_WEEK a week, and
## standardised fixes there stop wearing while it runs. "" or Region's code:
## unknown_place | no_team | planned.
func plan_routine(place: String) -> String:
	var refused := region.plan_routine(place)
	_after(0)
	return refused


## Stop a routine at a place. "" or not_planned.
func stop_routine(place: String) -> String:
	var refused := region.stop_routine(place)
	_after(0)
	return refused


## The coach's reply (Missions.ask_coach): about the main mission only; right
## after a hard talk of the main mission, one question about that talk
## (People.coach_question, stage "talk").
func ask_coach(mission_id: String = "") -> Dictionary:
	var main := missions.active("main")
	var reply := people.coach_question(main[0].id) if not main.is_empty() and mission_id in ["", main[0].id] else {}
	if not reply.is_empty():
		_after(0)
		return reply
	reply = missions.ask_coach(mission_id)
	if reply.has("stage"):
		var coached := missions.active("main")
		coached.append_array(missions.active("training"))
		discoveries.note_coach(coached[0].id, reply["stage"])
	_after(0)
	return reply


## A returning player skips the training week: the campaign opens, without
## the week's rewards. "" or not_in_training.
func skip_training() -> String:
	if not missions.in_training():
		return "not_in_training"
	missions.skip_training()
	_walked_before()
	_after(0)
	return ""


## The Friday lesson in numbers, as a counterfactual (the pattern of
## KpiBoard.forecast): the coming `days` run twice on copies of the network
## from now, "held" (the fix kept: the countermeasure's effects, not the
## problem's) and "faded" (after the countermeasure's decay_days the fix is
## gone and the problem's effects are back). Both copies continue the same
## random sequences, so they differ only in the fix. The game itself does
## not move on. Returns {problem, kpi (the one the problem names), place,
## standardised (the player's Act), fade_days, held, faded (each
## Region.measures at the end)}, or an error: bad_days | unknown_problem |
## not_resolved (no Act yet) | a copy's error. fade_days: the days the fix
## lasts with no sustaining habit (Sustain.base_days, capped at `days`);
## recur_days: when the fix itself recurs at today's habits (days_to_recur).
func fade_forecast(days: int, problem_id: String = TRAINING_PROBLEM) -> Dictionary:
	if days < 1 or days > MAX_FORECAST_DAYS:
		return {"error": "bad_days"}
	var p: ProblemDef = region.problems.get(problem_id)
	if p == null:
		return {"error": "unknown_problem"}
	var st: ProblemState = region.state[problem_id]
	if st.phase != ProblemState.Phase.RESOLVED:
		return {"error": "not_resolved"}
	var cm: CountermeasureDef = region.countermeasures[st.a3["cm"]]
	var fixed := Pdca.treated_effects(p, cm, st.eff)
	var problem_source := "problem:" + problem_id
	var cm_source := "cm:" + problem_id
	var runs := {}
	for run: String in ["held", "faded"]:
		var twin := NetworkState.copy(region.net)
		if not twin.error.is_empty():
			return {"error": twin.error}
		twin.clear_effects(problem_source)
		twin.set_effects(cm_source, fixed.get(cm_source, []))
		runs[run] = twin
	var fade_days := mini(roundi(Sustain.base_days(cm)), days)
	var faded: Network = runs["faded"]
	faded.advance_days(fade_days)
	faded.clear_effects(cm_source)
	faded.set_effects(problem_source, p.effects)
	faded.advance_days(days - fade_days)
	runs["held"].advance_days(days)
	return {
		"problem": problem_id, "kpi": p.kpi, "place": p.step, "standardised": st.standardised,
		"fade_days": fade_days, "recur_days": region.days_to_recur(problem_id),
		"held": Region.measures(runs["held"], p.step), "faded": Region.measures(faded, p.step),
	}


## What happened since the last call, for the world and UI: the Region's
## events, then the missions' (see Region.events and Missions.events).
func drain_events() -> Array[Dictionary]:
	var out := region.drain_events()
	out.append_array(missions.drain_events())
	out.append_array(_people_events)
	_people_events = []
	out.append_array(discoveries.drain_events())
	return out


# ── Views ───────────────────────────────────────────────────────────────────

## Dutch date and time, e.g. "di 13 okt, 09:30".
func clock_text() -> String:
	var played := region.net.time - SimCalendar.days(WARMUP_DAYS)
	var date := Time.get_date_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(PLAY_START_DATE) + SimCalendar.day_of(played) * 86400)
	var minute_of_day := played % SimCalendar.MINUTES_PER_DAY
	return "%s %d %s, %02d:%02d" % [WEEKDAYS[SimCalendar.weekday(played)], date["day"], MONTHS[date["month"] - 1],
		int(minute_of_day / 60.0), minute_of_day % 60]


## The El Amrani dossier: {age_days, touch_hours, step, delivered_days}
## (FollowedOrder.view).
func followed_order() -> Dictionary:
	return followed.view(region.net)


## The month of the game's date (1-12).
func month() -> int:
	var played := region.net.time - SimCalendar.days(WARMUP_DAYS)
	return Time.get_date_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(PLAY_START_DATE) + SimCalendar.day_of(played) * 86400)["month"]


## The codex's Ontdekkingen: found ones {id, found, name, line, reward}, the
## rest {id, found: false, hint} (the hint once their act is over).
func discoveries_view() -> Array[Dictionary]:
	return discoveries.view(self)


func budget() -> int:
	return region.profile.budget


func xp() -> int:
	return region.profile.xp


## How the MT sees the CI lead, 0..100 (Reputation).
func reputation() -> int:
	return region.reputation.value


## The belt's id (white, yellow, ...).
func belt() -> String:
	return Progression.BELTS[Progression.belt_index(xp())]["id"]


## The missions on the board that can be taken on now.
func available_missions() -> Array[MissionDef]:
	return missions.available()


## A mission's briefing as the board shows it (the reopen text when its fix
## faded) and its debrief (a fork branch done first has its own).
## {dossier_weken} reads the El Amrani dossier's age.
func mission_briefing(mission_id: String) -> String:
	if not missions.defs.has(mission_id):
		return ""
	var age: float = followed_order()["age_days"]
	return missions.briefing_of(mission_id).replace("{dossier_weken}", FollowedOrder.weeks_text(age))


func mission_debrief(mission_id: String) -> String:
	return missions.debrief_of(mission_id) if missions.defs.has(mission_id) else ""


## Countermeasures not offered because an earlier preparation is missing:
## [{id, name, preparation}] for the A3's "niet voorbereid" list. The hint
## points at a place or team, never at the route.
func unprepared_countermeasures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in missions.unprepared():
		out.append({"id": c.id, "name": c.name, "preparation": c.preparation})
	return out


## What a countermeasure costs over a year, redoing it each time it fades
## (Stewardship.year_cost; an estimate, for the A3); -1 for an unknown one.
func year_cost(cm_id: String) -> int:
	var cm: CountermeasureDef = region.countermeasures.get(cm_id)
	return Stewardship.year_cost(cm) if cm != null else -1


## Whether a fact of the player's path holds ("chose:custom_design:
## standard_designs", "maturity>=2"; Missions.knows).
func knows(fact: String) -> bool:
	return missions.knows(fact)


## Still in the training week (a day not yet done or skipped).
func in_training() -> bool:
	return missions.in_training()


## A training day's place in the week: 0 (Monday) to 4 (Friday), in content
## order; -1 for any other mission.
func training_day(mission_id: String) -> int:
	var week := missions.defs.values().filter(func(m: MissionDef) -> bool: return m.kind == "training")
	return week.map(func(m: MissionDef) -> String: return m.id).find(mission_id)


## A training day's weekday as the player saw it ("ma" … "vr"): the day it
## started, or its place in the week before then; "" for any other mission.
func training_weekday(mission_id: String) -> String:
	var day := training_day(mission_id)
	if day < 0:
		return ""
	if not missions.opened_at.has(mission_id):
		return WEEKDAYS[day]
	return WEEKDAYS[SimCalendar.weekday(missions.opened_at[mission_id])]


## A problem only the training week opens (Region.practice).
func is_practice(problem_id: String) -> bool:
	return region.practice.has(problem_id)


## The active missions: the main one first, then the training day, then the
## side missions.
func active_missions() -> Array[MissionDef]:
	var out := missions.active("main")
	out.append_array(missions.active("training"))
	out.append_array(missions.active("side"))
	return out


## Where a problem stands: dormant | active | spotted | doing | check_ready |
## checked | resolved ("" for an unknown problem).
func phase_of(problem_id: String) -> String:
	var st: ProblemState = region.state.get(problem_id)
	return ProblemState.Phase.keys()[st.phase].to_lower() if st != null else ""


## The clues found for a problem, in the order of its content.
func clues_found(problem_id: String) -> Array[Clue]:
	var out: Array[Clue] = []
	var p: ProblemDef = region.problems.get(problem_id)
	for c in p.clues if p != null else []:
		if region.found.has(c.id):
			out.append(c)
	return out


## The candidate root causes for the A3 (the order is stable per problem).
## Which one is right is for the player to work out.
func cause_options(problem_id: String) -> Array[String]:
	var p: ProblemDef = region.problems.get(problem_id)
	if p == null:
		return []
	return Investigation.cause_options(p, region.problem_list())["options"]


## The countermeasures the region can try, for any problem: the list does not
## say which ones fit.
func countermeasures() -> Array[CountermeasureDef]:
	return region.available_countermeasures()


## How a resolved fix is held (for the Check, the HUD, a place's panel):
## {strength 0..1, mechanisms (standard_work | visual_management | kpis),
## standardised, health (1 fresh, 0.5 at recurrence), neglect_days (since
## the Act, the last audit or routine), life_days (of neglect it lasts at
## today's habits), routine (a planned routine holds it), days_to_recur (INF
## while a routine holds it)}; {} when the problem is not resolved.
func sustain_of(problem_id: String) -> Dictionary:
	var st: ProblemState = region.state.get(problem_id)
	if st == null or st.phase != ProblemState.Phase.RESOLVED:
		return {}
	var out := region.sustain(problem_id)
	out.merge({"standardised": st.standardised, "health": region.health(problem_id), "neglect_days": st.neglect,
		"life_days": region.life_days(problem_id), "routine": region.held_by_routine(problem_id),
		"days_to_recur": region.days_to_recur(problem_id)})
	return out


## The places with a planned routine.
func routines() -> Array[String]:
	var out: Array[String] = []
	out.assign(region.routines.keys())
	return out


## Stagnation drift (for the HUD): {level 0..1, stagnant_days (since the last
## resolved improvement), grace_days (no drift before), started (the campaign
## is open)}.
func drift() -> Dictionary:
	return {"level": region.drift_level(), "stagnant_days": region.stagnant_days(),
		"grace_days": Sustain.DRIFT_GRACE_DAYS, "started": region.drift_from >= 0}


# ── Internals ───────────────────────────────────────────────────────────────

func _is_place(place: String) -> bool:
	return region.net.step_at(place) != null


## A returning player, who skips the training week, has followed a dossier
## before: the story's first mission counts as done, without a reward. After
## the week a new player does it for real (audit M1).
func _walked_before() -> void:
	if not missions.done_once.has(STORY_MISSION):
		missions.progress[STORY_MISSION] = {"status": "completed", "asks": {}, "seen": {}}
		missions.done_once[STORY_MISSION] = true


## Time passes, then the missions notice what happened. A training day just
## handed out starts on its own morning; once the week is over stagnation
## starts to count (also for an old save).
func _after(minutes: int) -> void:
	if minutes > 0:
		region.advance(minutes)
	missions.update()
	_start_training_day()
	if not missions.in_training():
		region.start_drift()
	followed.update(region.net)
	_sync_people()
	discoveries.update(self)


## A training day handed out starts on its own morning (Monday to Friday of
## the first week of play) when that is still ahead, or on the next working
## day's morning when the clock stands in a weekend (Thursday's three-day
## Check ends on a Sunday). When it started is kept (Missions.opened_at): its
## weekday names the day (training_weekday).
func _start_training_day() -> void:
	for m in missions.active("training"):
		if missions.opened_at.has(m.id):
			continue
		var morning := SimCalendar.days(WARMUP_DAYS + training_day(m.id)) + START_MINUTE
		if region.net.time > morning and SimCalendar.weekday(region.net.time) >= 5:
			morning = SimCalendar.days(SimCalendar.day_of(region.net.time) + 7 - SimCalendar.weekday(region.net.time)) + START_MINUTE
		if region.net.time < morning:
			region.advance(morning - region.net.time)
			missions.update()
		missions.opened_at[m.id] = region.net.time


## The A3 as the rules read it: evidence a list of clue ids, cm an id.
## Anything else reads as missing, so the rules name the first thing wrong
## in their own order.
static func _cleaned(a3: Dictionary) -> Dictionary:
	var clean := a3.duplicate()
	var evidence: Variant = a3.get("evidence", [])
	clean["evidence"] = evidence.filter(func(id: Variant) -> bool: return id is String) if evidence is Array else []
	clean["cm"] = a3["cm"] if a3.get("cm") is String else ""
	return clean


# ── Dialogs: talks with named people (rules/dialog.gd, rules/people.gd) ─────
# docs/superpowers/specs/2026-10-15-dialog-system-design.md §10. A talk runs
# move by move with no time passing; when it ends, its minutes pass once and
# what it changed reaches the world (team trust, a blame, a learned clue).

## The people at a place (those who left are gone): [{id, name, role,
## has_dialog (a talk they have for the player now), checkin (that talk is a
## check-in), cooling_down, energy, needs_talk (see energy_of)}].
func people_at(place: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: PersonDef in people.persons.values():
		if p.place != place or people.has_left(p.id):
			continue
		var d := people.dialog_for(p.id, _world(p))
		var entry := {"id": p.id, "name": p.name, "role": p.role, "has_dialog": d != null,
			"checkin": d != null and d.kind == "checkin", "cooling_down": people.cooling_down(p.id, region.net.time)}
		entry.merge(energy_of(p.id))
		out.append(entry)
	return out


## The bar over a person met while walking around (Merijn, 2026-10-15):
## {energy (their morale, 0–1; the UI draws a bar, never a number),
## needs_talk (a check-in prompt is open: a talk could lift their spirit)};
## {} for an unknown person.
func energy_of(person_id: String) -> Dictionary:
	if not people.persons.has(person_id):
		return {}
	return {"energy": people.morale[person_id] / 100.0, "needs_talk": people.needs_talk(person_id)}


## What the player knows of a person (the journal's Mensen tab): {id, name,
## role, place, trust_pips, morale_band (0 low · 1 middling · 2 high),
## cooldown_until, outcomes (dialog id → its best outcome)}; {} for an unknown id.
func person(person_id: String) -> Dictionary:
	var p: PersonDef = people.persons.get(person_id)
	if p == null:
		return {}
	var facts := people.facts(_facts())
	var outcomes := {}
	for d: DialogDef in people.dialogs.values():
		if d.person == person_id and people.outcomes.has(d.id):
			outcomes[d.id] = people.effective_outcome(d.id, facts)
	var morale: int = people.morale[person_id]
	return {"id": p.id, "name": p.name, "role": p.role, "place": p.place,
		"trust_pips": floori(people.trust[person_id] / float(Dialog.TRUST_PER_PIP)),
		"morale_band": 0 if morale < 30 else (1 if morale < 70 else 2),
		"cooldown_until": int(people.memory.get(person_id, {}).get("cooldown_until", 0)), "outcomes": outcomes}


## Open the talk a person has for the player: {dialog, kind, person, name,
## role, opening, position ({text, tags}), meter, moves}, or an error:
## in_dialog | unknown_person | cooling_down (after a ruined talk; the UI says
## the bank's special.cooling_down line) | nothing_to_say.
func start_dialog(person_id: String) -> Dictionary:
	if _talk != null:
		return {"error": "in_dialog"}
	var p: PersonDef = people.persons.get(person_id)
	if p == null:
		return {"error": "unknown_person"}
	if people.cooling_down(person_id, region.net.time):
		return {"error": "cooling_down"}
	var world := _world(p)
	var d := people.dialog_for(person_id, world)
	if d == null:
		return {"error": "nothing_to_say"}
	_talk = people.start(d, world)
	return {"dialog": d.id, "kind": d.kind, "person": p.id, "name": p.name, "role": p.role,
		"opening": people.opening(d), "position": _talk.position(), "meter": _talk.meter(), "moves": _talk.moves()}


## The moves of the talk in progress (Dialog.moves); [] when there is none.
func dialog_moves() -> Array[Dictionary]:
	var none: Array[Dictionary] = []
	return _talk.moves() if _talk != null else none


## The meter of the talk in progress (Dialog.meter); {} when there is none.
func dialog_meter() -> Dictionary:
	return _talk.meter() if _talk != null else {}


## Make a move in the talk (a pick for show_data, propose_experiment and
## propose: one the moves offered). Dialog.say's result; when the talk ended,
## with `summary` (People.finish), and its minutes have passed. Errors:
## no_dialog | unknown_move | bad_pick (and nothing changes).
func choose_move(move: String, pick: String = "") -> Dictionary:
	if _talk == null:
		return {"error": "no_dialog"}
	var result := _talk.say(move, pick)
	if result.get("ended", false):
		result["summary"] = _finish_talk()
	return result


## End the talk gracefully (the close move); see choose_move.
func end_dialog() -> Dictionary:
	return choose_move("close")


## A dialog's best agreement so far, a met condition counted as commitment
## ("" when never had). What a mission's talk_to {dialog, outcome} goal reads
## (Missions.talk_outcome).
func talk_outcome(dialog_id: String) -> String:
	return people.effective_outcome(dialog_id, people.facts(_facts()))


## What a talk needs to know about the world, for person `p`.
func _world(p: PersonDef) -> Dictionary:
	var blamed := region.problem_list().any(func(problem: ProblemDef) -> bool:
		var step := region.net.step_at(problem.step)
		return region.state[problem.id].blamed and region.state[problem.id].is_open() \
			and step != null and p.team in step.pool_ids)
	return {
		"main": missions.active("main").map(func(m: MissionDef) -> String: return m.id),
		"active": missions.active().map(func(m: MissionDef) -> String: return m.id),
		"found": region.found, "facts": _facts(), "team_trust": region.trust.get(p.team, 0), "blamed": blamed,
		"now": region.net.time,
	}


## The world's facts a talk can need, as Missions.knows answers them (the
## catalogue's C19: done:, failed:, chose:, checked:, flags and measures such
## as reputation>=40), for every atom the dialogs name.
func _facts() -> Dictionary:
	var out := {}
	for atom: String in people.atoms():
		if missions.knows(atom):
			out[atom] = true
	return out


## The talk ended: People applies it, the world takes what it changed (a blame
## by the gemba's own rule, a commitment's team trust, a learned clue), then
## its minutes pass.
func _finish_talk() -> Dictionary:
	var d := _talk
	_talk = null
	var main := missions.active("main").any(func(m: MissionDef) -> bool: return m.id == d.def.mission)
	var summary := people.finish(d, region.net.time, main)
	if summary["confronted"]:
		region.ask(d.who.place, "behind")
	if summary["team_trust"] > 0:
		region.trust[d.who.team] = mini(1, region.trust.get(d.who.team, 0) + summary["team_trust"])
	if not summary["clue"].is_empty():
		region.found[summary["clue"]] = true
	if summary["reputation"] != 0:
		region.earn_reputation(summary["reputation"], "dialog_" + summary["outcome"])
	_after(d.minutes())
	return summary


## After every action: check-in prompts and the low-morale clock move on
## (People.daily; a goodbye is an event), the facts talks set join the ones missions and
## countermeasures read (Missions.facts), and every resolved fix with an owner
## carries that owner's buy-in now (a later commitment repairs it, a met
## condition upgrades it; Sustain.BUY_IN).
func _sync_people() -> void:
	if people == null:
		return
	var world_facts := _facts()
	_people_events.append_array(people.daily({"now": region.net.time, "facts": world_facts}))
	var facts := people.facts(world_facts)
	for fact: String in facts:
		if fact.get_slice(":", 0) in People.FACT_KINDS:
			missions.facts.add(fact)
	for id: String in region.state:
		var st: ProblemState = region.state[id]
		var owner := people.buy_in(id, facts) if st.phase == ProblemState.Phase.RESOLVED else ""
		if not owner.is_empty():
			st.buy_in = owner
