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
const WEEKDAY_NAMES: Array[String] = ["maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag", "zondag"]
static var _PROMISE_DATE := RegEx.create_from_string("\\{promise_date:(\\d+)\\}")
const MONTH_NAMES: Array[String] = ["januari", "februari", "maart", "april", "mei", "juni", "juli", "augustus",
	"september", "oktober", "november", "december"]
## The training week's first day, and its practice problem (fade_forecast's default).
const TRAINING_FIRST := "training_mon"
const TRAINING_PROBLEM := "training_tray"
## A fade forecast looks at most a quarter ahead.
const MAX_FORECAST_DAYS := 91
## A milestone's scene takes half an hour of the day (ESTIMATE: a sit-down with two managers).
const SCENE_MINUTES := 30

var catalog: Catalog
var region: Region
var missions: Missions
## The cast and what they remember (dialogs).
var people: People
## What people say in passing and the talk in progress (SessionTalks).
var talks := SessionTalks.new()
## People's events ({type: left, person}) not yet drained.
var _people_events: Array[Dictionary] = []
## Hidden rewards for deep thinking; it hears what the player does.
var discoveries: Discoveries
## The El Amrani family's dossier, followed through the stream.
var followed := FollowedOrder.new()
## The "Hoe werkt het?" explainers seen (PLAN 2.7c), for the codex.
var explainers := ExplainerLog.new()
## What fits each place, its observations, and the player's toolbox (PLAN 2.12).
var gemba: PlaceActions
## The player as made in the character creator (PLAN 2.7b): first name, look,
## badge photo. Its tokens ({speler}, {hij_zij} …) fill dialog text and briefings.
var player := PlayerProfile.new()
## The first thing wrong with the content; "" when the game is usable.
var error := ""


## A new game on the real content. `seed_value` fixes the simulation's luck.
## `training`: start with the training week (Inwerkweek), its first day handed
## out; without it (a returning player) the week counts as skipped. Either
## way the story's walk counts as done once the week is over.
static func new_game(seed_value: int = 1, data_dir: String = Catalog.DATA_DIR, training: bool = true) -> GameSession:
	var s := GameSession.new()
	s.catalog = Catalog.load_from(data_dir)
	if not s.catalog.error.is_empty():
		s.error = s.catalog.error
		return s
	var net := _warmed_up(data_dir, seed_value, s.catalog.kpis.pull_limit_days)
	s.error = net.error
	if not s.error.is_empty():
		return s
	s.region = Region.new(net, s.catalog.problems, s.catalog.countermeasures, Profile.new())
	s.region.use_kpis(s.catalog.kpis)
	s.missions = Missions.new(s.region, s.catalog.missions, s.catalog.coach)
	s.people = People.new(s.catalog.persons, s.catalog.dialogs, s.catalog.dialog_bank)
	# Bound methods, not lambdas: a lambda capturing `s` would be a reference
	# cycle (s → missions → lambda → s) and no session would ever be freed.
	s.missions.talk_outcome = s.talk_outcome
	s.missions.talked = s.talked
	s.missions.can_talk = s.can_talk
	s.missions.topics_heard = s.topics_heard
	s.missions.play_start = SimCalendar.days(WARMUP_DAYS)
	s.discoveries = Discoveries.new(s.catalog.discoveries)
	s.gemba = PlaceActions.from_doc(s.catalog.places)
	for id in [STORY_MISSION, TRAINING_FIRST]:
		if not s.missions.defs.has(id):
			s.error = "missing mission: " + id
			return s
	s.followed.pick(net)
	if training:
		s.missions.accept(TRAINING_FIRST)
		s._after(0)
	else:
		s.skip_training()
	return s


## The warmed-up networks by content, seed and pull limit (_warmed_up).
static var _warm_networks: Dictionary = {}


## The network as play starts: the content's, every team pulling by
## `pull_limit_days` (Region.use_kpis), after the warm-up. No problems are
## active yet, so the warm-up costs nothing and teaches nothing. It is ~2 s of
## simulation, the same for every game with this seed: run once, then each
## game gets a copy that continues exactly alike (NetworkState.copy).
static func _warmed_up(data_dir: String, seed_value: int, pull_limit_days: float) -> Network:
	var key := "%s|%d|%s" % [data_dir, seed_value, pull_limit_days]
	if not _warm_networks.has(key):
		var net := Network.load_file(data_dir + "/value_streams.json", seed_value)
		if not net.error.is_empty():
			return net
		for pool: SimPool in net.pools.values():
			pool.pull_limit_days = pull_limit_days
		net.advance(SimCalendar.days(WARMUP_DAYS) + START_MINUTE)
		_warm_networks[key] = net
	return NetworkState.copy(_warm_networks[key])


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
## Returns Region.use_tool's {spotted, clues, hidden_signal}, with the
## place's next observation (PlaceActions) when no clue was found, or an
## error (no time passes): unknown_tool | use_ask (a conversation is a
## question) | unknown_place | tool_not_here (it does not fit the work there)
## | tool_not_known (the training week has not handed it out yet).
func use_tool(place: String, tool: String) -> Dictionary:
	if not Investigation.TOOLS.has(tool):
		return {"error": "unknown_tool"}
	if tool == "conversation":
		return {"error": "use_ask"}
	if not _is_place(place):
		return {"error": "unknown_place"}
	if not gemba.fits(place, tool):
		return {"error": "tool_not_here"}
	if not gemba.known.has(tool):
		return {"error": "tool_not_known"}
	var result := region.use_tool(place, tool)
	if result["clues"].is_empty():
		var seen := gemba.observe(place, tool, SimCalendar.day_of(region.net.time) - WARMUP_DAYS)
		if not seen.is_empty():
			result["observation"] = fill_tokens(seen)
	missions.note_use(place, tool)
	discoveries.note_use(self, place, tool, "", result["clues"].any(func(c: Clue) -> bool: return c.key))
	_after(Investigation.TOOLS[tool]["minutes"])
	return result


## Ask a question at a place; a conversation's minutes pass. Where the place
## has questions (content/places.yaml) only those can be asked, each to its
## person, plus "thanks" to whoever gave a blame or guarded reply there.
## Returns Region.ask's result (its kind keeps its rules: a clue wins over
## an open question's answer, a blame costs trust), with the person asked
## and their own line when no clue came out, or an error: unknown_question |
## unknown_place.
func ask(place: String, question_id: String) -> Dictionary:
	if not Investigation.QUESTIONS.has(question_id):
		return {"error": "unknown_question"}
	if not _is_place(place):
		return {"error": "unknown_place"}
	var q := gemba.question(place, question_id)
	var person: String = gemba.repair_due.get(place, "") if question_id == PlaceActions.THANKS else str(q.get("person", ""))
	if gemba.has_place(place) and person.is_empty():
		return {"error": "unknown_question"}
	var result := region.ask(place, question_id)
	if not person.is_empty():
		result["person"] = person
		if result["reply"] in ["observation", "closed", "blame", "nobody"] and q.has("reply"):
			result["line"] = fill_tokens(q["reply"])
		if result["reply"] in ["blame", "guarded"]:
			gemba.repair_due[place] = person
		elif question_id == PlaceActions.THANKS:
			gemba.repair_due.erase(place)
	missions.note_use(place, "conversation")
	discoveries.note_use(self, place, "conversation", result["reply"], result.has("clue") and result["clue"].key)
	_after(Investigation.TOOLS["conversation"]["minutes"])
	return result


## The questions to the people at a place who are still here: [{id, person,
## text, reply}] (content/places.yaml), and "thanks" to whoever a blame or
## guarded reply there left wanting one.
func place_questions(place: String) -> Array:
	var out := gemba.questions_at(place).filter(func(q: Dictionary) -> bool: return _here(q["person"]))
	if gemba.repair_due.has(place) and _here(gemba.repair_due[place]):
		out.append({"id": PlaceActions.THANKS, "person": gemba.repair_due[place], "text": "", "reply": ""})
	return out


## Whom the player can ask at a place: those who work there and those met
## there too (people_also), while they are still around.
func people_to_ask(place: String) -> Array[String]:
	var out: Array[String] = []
	for q: Dictionary in place_questions(place):
		if not q["person"] in out:
			out.append(q["person"])
	return out


func _here(person: String) -> bool:
	return people.persons.has(person) and not people.has_left(person)


## The morning note's card for a tool Ruud hands out ({title, text}; {}).
func tool_card(tool: String) -> Dictionary:
	return gemba.tool_cards.get(tool, {})


## The tool buttons at a place: the fitting tools the player knows.
func place_tools(place: String) -> Array[String]:
	return gemba.tools_at(place)


## The tools a mission hands out when it is taken on (a training day's
## morning note names them).
func new_tools(mission_id: String) -> PackedStringArray:
	return missions.defs[mission_id].grant_tools if missions.defs.has(mission_id) else PackedStringArray()


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
	var refused := region.submit_a3(problem_id, _cleaned(a3), check_days(problem_id),
		missions.backing(problem_id))
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


## Let `minutes` pass with nothing done (the session layer's named time
## skip, a morning at a time); the missions notice what happened.
func pass_time(minutes: int) -> void:
	_after(maxi(0, minutes))


## The Check: the fix against no fix over the coming lead time
## (Region.check's result, a few seconds of simulation on copies; a failed one with
## `debrief`, the mission's own text for its verdict or ""), or an
## error: unknown_problem | not_check_ready | a forecast copy's error.
func check(problem_id: String) -> Dictionary:
	if not region.state.has(problem_id):
		return {"error": "unknown_problem"}
	var result := region.check(problem_id)
	if not result.is_empty():
		discoveries.note_check(self, problem_id, result)
		if result.has("forecast") and result["forecast"]["gain"] > Pdca.CHECK_NOISE:
			missions.facts.add(Facts.FORECAST_POSITIVE + str(result["forecast"]["kpi"]))
		if not result.get("passed", true):  # a designed failed Check has its mission's own words
			result["debrief"] = player.fill(missions.check_debrief(problem_id, str(result["lesson"])))
	_after(0)
	return result if not result.is_empty() else {"error": "not_check_ready"}


## The quarterly review on the KPI board (Region.kpi_review): its result, or
## {error} (KpiBoard.review's codes). A forecast that beats the habit by more
## than the board's noise band (it pays) is remembered as
## forecast_positive:kpi_board, which talks can wait for (Frank's third route).
func kpi_review(choices: Dictionary) -> Dictionary:
	var result := region.kpi_review(choices)
	if not result["error"].is_empty():
		return {"error": result["error"]}
	if result["paid"] > 0.0:
		missions.facts.add(Facts.FORECAST_POSITIVE + KpiBoard.UNLOCK)
	_after(0)
	return result


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
	gemba.know_all()
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
	return clock_at(region.net.time)


## The date and time of a simulation time, as clock_text (a save list shows
## it without loading the game).
static func clock_at(t: int) -> String:
	var minute := minute_at(t)
	return "%s, %02d:%02d" % [day_text(t), int(minute / 60.0), minute % 60]


## The minutes since midnight now (the world reads the hour: lunch in the kantine).
func minute_of_day() -> int:
	return minute_at(region.net.time)


static func minute_at(t: int) -> int:
	return (t - SimCalendar.days(WARMUP_DAYS)) % SimCalendar.MINUTES_PER_DAY


## The greeting for `minute` of the day ({groet}): goedemorgen until noon, goedemiddag until
## six, goedenavond after (and through the night; goedenacht is a goodbye).
static func greeting_at(minute: int) -> String:
	if minute >= 6 * 60 and minute < 12 * 60:
		return "Goedemorgen"
	return "Goedemiddag" if minute >= 12 * 60 and minute < 18 * 60 else "Goedenavond"


## The El Amrani dossier: {age_days, touch_hours, step, delivered_days}
## (FollowedOrder.view).
func followed_order() -> Dictionary:
	return followed.view(region.net)


## The calendar date {year, month, day, ...} of a simulation time.
static func date_of(t: int) -> Dictionary:
	var played := t - SimCalendar.days(WARMUP_DAYS)
	return Time.get_date_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(PLAY_START_DATE) + SimCalendar.day_of(played) * 86400)


## "2026-12-01" for a moment `t` (minutes): the date a promise names (PLAN 2.4).
static func iso_date(t: int) -> String:
	var date := date_of(t)
	return "%04d-%02d-%02d" % [date["year"], date["month"], date["day"]]


## "di 13 okt" for a moment `t` (minutes); "" for an unknown one (t < 0).
static func day_text(t: int) -> String:
	if t < 0:
		return ""
	var date := date_of(t)
	return "%s %d %s" % [WEEKDAYS[SimCalendar.weekday(t - SimCalendar.days(WARMUP_DAYS))], date["day"],
		MONTHS[date["month"] - 1]]


## The month of the game's date (1-12).
func month() -> int:
	return date_of(region.net.time)["month"]


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
	return player.fill(missions.briefing_of(mission_id).replace("{dossier_weken}", FollowedOrder.weeks_text(age)))


## The debrief to show, with a main mission's principle line after it.
func mission_debrief(mission_id: String) -> String:
	if not missions.defs.has(mission_id):
		return ""
	var principle := principle_line(mission_id)
	return player.fill(missions.debrief_of(mission_id)) + ("\n\n" + principle if not principle.is_empty() else "")


## The principle line of main mission `mission_id` with a problem (design §3.7,
## PrincipleLine): which principle the play paid or cost, from its facts; "" otherwise.
func principle_line(mission_id: String) -> String:
	var m: MissionDef = missions.defs.get(mission_id)
	if m == null or m.kind != "main" or m.goal_problem.is_empty():
		return ""
	var st: ProblemState = region.state.get(m.goal_problem)
	var short_term := missions.knows("poor_fix:" + m.goal_problem) or missions.knows("wrong_cause:" + m.goal_problem)
	var facts := {"poor_fix": short_term, "fading": missions.fading_fix(m),
		"blamed": st != null and st.blamed, "complied": "", "committed": "",
		"standardised": st != null and st.standardised, "failed_checks": st.failed_checks if st != null else 0}
	for d: DialogDef in (people.dialogs.values() if people != null else []):
		for kind: String in ["committed", "complied"]:
			if d.missions.has(mission_id) and facts[kind] == "" and missions.knows("%s:%s" % [kind, d.id]):
				facts[kind] = speaker_name(d.person)
	var code := PrincipleLine.code(facts)
	var who: String = facts["complied"] if code == "respect_complied" else facts["committed"]
	return player.fill(PrincipleLine.line(catalog.principles, code, mission_id, who))


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
## side missions, then the milestones (no slot: the story's moments), then the
## routines (no slot either: the weekly round).
func active_missions() -> Array[MissionDef]:
	var out := missions.active("main")
	out.append_array(missions.active("training"))
	var sides := missions.active("side")
	out.append_array(sides.filter(func(m: MissionDef) -> bool: return not m.is_routine()))
	out.append_array(missions.active("milestone"))
	out.append_array(sides.filter(func(m: MissionDef) -> bool: return m.is_routine()))
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
	followed.update(region.net, missions.knows("holds:" + FollowedOrder.DEFECT_PROBLEM))
	_note_story()
	missions.update()
	_start_training_day()
	for id in missions.progress:
		gemba.grant(new_tools(id))
	if not missions.in_training():
		region.start_drift()
	if people != null:
		_note_promises()
	_sync_people()
	discoveries.update(self)


## The story's facts the missions read (phase-2 design §3.2): the followed order
## connected (delivered:<story>, and delivered:<story>:<ISO date> of its real done_at, which
## the promise and the deadline are judged by), the proposals agreed (agreed:<dialog>:<proposal>),
## and who left (left:<person>).
func _note_story() -> void:
	if followed.delivered_at >= 0:
		missions.facts.add("delivered:" + FollowedOrder.STORY)
		missions.facts.add("delivered:%s:%s" % [FollowedOrder.STORY, iso_date(followed.delivered_at)])
	if people == null:
		return
	for id: String in people.agreed:   # the newest agreement in a talk replaces the older one
		missions.facts.remove_prefix("agreed:%s:" % id)
		missions.facts.add("agreed:%s:%s" % [id, people.agreed[id]])
	for id: String in people.left:
		missions.facts.add("left:" + id)


## A promised date the simulation judged (Missions: promise_kept / promise_broken)
## reaches the person it was promised to (People.judge_promise, once).
func _note_promises() -> void:
	for id: String in people.agreed:
		for kept in [true, false]:
			if missions.knows(("promise_kept:" if kept else "promise_broken:") + id):
				people.judge_promise(id, kept)


## A milestone's scene as it plays now (SceneScript.play, the facts choosing the
## lines), each line's `name` the speaker's, its texts filled; {} when `mission_id` is
## no active scene milestone.
func scene_of(mission_id: String) -> Dictionary:
	var m: MissionDef = missions.defs.get(mission_id)
	if m == null or m.goal_type != "scene" or missions.status(mission_id) != "active" \
			or not catalog.scenes.has(m.scene):
		return {}
	var out := SceneScript.play(catalog.scenes[m.scene], missions.knows)
	for line: Dictionary in out["before"] + out["after"] + ([out["choice"]] if not out["choice"].is_empty() else []):
		line["name"] = speaker_name(line["who"])
		line["text"] = fill_tokens(line["text"])
		for o: Dictionary in line.get("options", []):
			o["label"] = fill_tokens(o["label"])
			o["reply"] = fill_tokens(o["reply"])
	return out


## Who says a scene's line, as the line box names them: the cast's short name, the coach's.
func speaker_name(person_id: String) -> String:
	var p: PersonDef = people.persons.get(person_id) if people != null else null
	if p != null:
		return p.short
	var coach := str(catalog.coach.get("name", ""))
	return coach.get_slice(" ", 0) if person_id == "ruud" and not coach.is_empty() else person_id.capitalize()


## The KPI board's birth (PLAN 2.5): a scene that ends at the board (SceneScript
## `board`) hangs it when no fix did (KpiBoard.unlock: its first review is due at once).
## Whether the board is up.
func hang_kpi_board() -> bool:
	region.board.unlock(region.net.time)
	return region.board.unlocked


## The scene of milestone `mission_id` was played and answered with option `answer`
## (-1: it asked nothing); its minutes pass and the milestone completes. "" or
## Missions.finish_scene's code, bad_answer, or review_first (a scene that ends at the
## KPI board, before the board's review is done).
func finish_scene(mission_id: String, answer: int = -1) -> String:
	var scene := scene_of(mission_id)
	var options: Array = scene.get("choice", {}).get("options", [])
	if not options.is_empty() and (answer < 0 or answer >= options.size()):
		return "bad_answer"
	if scene.get("board", false) and (not region.board.unlocked or region.board.review_due(region.net.time)):
		return "review_first"   # a scene that ends at the KPI board ends once it is hung
	var refused := missions.finish_scene(mission_id, options[answer]["fact"] if not options.is_empty() else "")
	if refused.is_empty():
		_after(SCENE_MINUTES)
	return refused


## A training day handed out starts on its own morning (Monday to Friday of
## the first week of play) when that is still ahead, or on the next working
## day's morning when the clock stands in a weekend (a Check that ends on a
## weekend). When it started is kept (Missions.opened_at): its
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
		var d := people.dialog_for(p.id, SessionTalks.world(self, p))
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


# ── In passing and talks: forwards to SessionTalks (see there) ──────────────

func greet(person_id: String) -> String:
	return talks.greet(self, person_id)


func greeting_fact(person_id: String) -> String:
	return SessionTalks.greeting_fact(self, person_id)


func quick_line(person_id: String) -> String:
	return talks.quick_line(self, person_id)


func quick_mood(person_id: String) -> String:
	return SessionTalks.quick_mood(self, person_id)


func chatter(first: String, second: String) -> Array[String]:
	return talks.chatter(self, first, second)


func passing_to_dict() -> Dictionary:
	return talks.passing_to_dict()


func load_passing(d: Variant) -> void:
	talks.load_passing(d)


func checkin_prompts() -> Array[Dictionary]:
	return SessionTalks.checkin_prompts(self)


func person(person_id: String) -> Dictionary:
	return SessionTalks.person(self, person_id)


func start_dialog(person_id: String) -> Dictionary:
	return talks.start_dialog(self, person_id)


func dialog_moves() -> Array[Dictionary]:
	return talks.dialog_moves(self)


func dialog_offers() -> Array[Dictionary]:
	return talks.dialog_offers(self)


func dialog_meter() -> Dictionary:
	return talks.dialog_meter()


func dialog_layers() -> Array[Dictionary]:
	return talks.dialog_layers(self)


func choose_move(move: String, pick: String = "") -> Dictionary:
	return talks.choose_move(self, move, pick)


func talk_main(def: DialogDef) -> String:
	return SessionTalks.talk_main(missions, def)


func customer_calls() -> Array[Dictionary]:
	return SessionTalks.customer_calls(self)


func expert_serves_active(dialog_id: String) -> bool:
	return SessionTalks.expert_serves_active(self, dialog_id)


## The player's note on a person (the Mensen tab; People.set_note).
func set_note(person_id: String, text: String) -> bool:
	return people.set_note(person_id, text)


## The tokens talk lines speak through: the player's (PlayerProfile.fill:
## {speler}, {jongen_meid} …), {aanvraag_datum}, the day the El Amrani
## family applied (D9 talks audit #20), and {groet}, the greeting for the hour
## (greeting_at). No filled value holds a brace.
func fill_tokens(text: String) -> String:
	if not "{" in text:
		return text
	var born := date_of(followed.born)
	var out := player.fill(text).replace("{aanvraag_datum}", "%d %s" % [born["day"], MONTH_NAMES[born["month"] - 1]]) \
		.replace("{groet}", greeting_at(minute_of_day()))
	for found in _PROMISE_DATE.search_all(out):   # {promise_date:N}: the date N days from now (the promise checked)
		var t := region.net.time + SimCalendar.days(found.get_string(1).to_int())
		var date := date_of(t)
		out = out.replace(found.get_string(), "%s %d %s" % [WEEKDAY_NAMES[SimCalendar.weekday(t - SimCalendar.days(WARMUP_DAYS))],
			date["day"], MONTH_NAMES[date["month"] - 1]])
	return out


## End the talk gracefully (the close move); see choose_move.
func end_dialog() -> Dictionary:
	return choose_move("close")


## A dialog's best agreement so far, a met condition counted as commitment
## ("" when never had). What a mission's talk_to {dialog, outcome} goal reads
## (Missions.talk_outcome).
func talk_outcome(dialog_id: String) -> String:
	return people.effective_outcome(dialog_id, people.facts(SessionTalks.facts(self)))


## How many topics of an expert talk were heard (Missions.topics_heard).
func topics_heard(dialog_id: String) -> int:
	return people.asked_topics(dialog_id).size()


## Whether a dialog was had (Missions.talked); a talk the content does not
## hold waits for nothing.
func talked(dialog_id: String) -> bool:
	return people.talks.has(dialog_id) or not people.dialogs.has(dialog_id)


## Each team's planned load now: pool id → utilisation (Capacity; 1.0 is all its hours).
func _team_loads() -> Dictionary:
	var out := {}
	var pools: Dictionary = Capacity.analyse(region.net)["pools"]
	for id: String in pools:
		out[id] = float(pools[id].get("utilisation", 0.0))
	return out


## Whether a dialog's person is still here (Missions.can_talk): someone who left takes
## their talks with them.
func can_talk(dialog_id: String) -> bool:
	var d: DialogDef = people.dialogs.get(dialog_id)
	return d != null and not people.has_left(d.person)


## After every action: check-in prompts and the low-morale clock move on
## (People.daily; a goodbye is an event), the facts talks set join the ones missions and
## countermeasures read (Missions.facts), and every resolved fix with an owner
## carries that owner's buy-in now (a later commitment repairs it, a met
## condition upgrades it; Sustain.BUY_IN).
func _sync_people() -> void:
	if people == null:
		return
	var world_facts := SessionTalks.facts(self)
	var world := {"now": region.net.time, "facts": world_facts, "beats": missions.beats(), "training": missions.in_training()}
	if SimCalendar.day_of(region.net.time) != people.drift_day:
		world["loads"] = _team_loads()  # morale's daily drift (People._drift)
	_people_events.append_array(people.daily(world))
	var facts := people.facts(world_facts)
	for fact: String in facts:
		if fact.get_slice(":", 0) in People.FACT_KINDS:
			missions.facts.add(fact)
	for id: String in region.state:
		var st: ProblemState = region.state[id]
		var owner := people.buy_in(id, facts) if st.phase == ProblemState.Phase.RESOLVED else ""
		if not owner.is_empty():
			st.buy_in = owner
