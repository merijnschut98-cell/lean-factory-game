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
## A greeting remembers a talk this many days back (Friday's talk still on Monday).
const GREETING_MEMORY_DAYS := 3
## How full a team's work feels (load_of), from its pool's share of present hours spent
## busy over the last LOAD_DAYS (SimPool.load_since) and its queue in working days
## (Network.queue_days). ESTIMATES for the quick line's tone, read off a fresh game (the
## teams run 0.25-0.98 busy): from 85 % busy, or three days of queue, it feels full; under
## 40 % busy with half a day of queue it feels quiet.
const LOAD_DAYS := 5
const BUSY_SHARE := 0.85
const CALM_SHARE := 0.4
const BUSY_QUEUE_DAYS := 3.0
const CALM_QUEUE_DAYS := 0.5
## Under this morale (0-100) a person's quick line is a tired one (People's own scale: the
## leave clock starts at 20, a friendly week is 55 and up). An ESTIMATE.
const TIRED_MORALE := 40
## The hour bands of a quick line (minutes since midnight): before half eleven is morning,
## from half five it is late.
const MORNING_UNTIL := 11 * 60 + 30
const LATE_FROM := 17 * 60 + 30
## A milestone's scene takes half an hour of the day (ESTIMATE: a sit-down with two managers).
const SCENE_MINUTES := 30
## Promise kinds that name a date (content's PROMISE_KINDS); the others are an action.
const DATE_PROMISES: Array[String] = ["delivery_date"]

var catalog: Catalog
var region: Region
var missions: Missions
## The cast and what they remember (dialogs); the talk in progress, if any.
var people: People
var _talk: Dialog = null
## An expert talk in progress instead (topic by topic, ExpertTalk), if any.
var _expert: ExpertTalk = null
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
## What people said in passing today (Phase 2 §1.4): person id → the day they greeted
## you; "a|b" → the day that pair chatted (saved: passing_to_dict); how many quick lines
## were said (variety).
var _greeted: Dictionary[String, int] = {}
var _chatted: Dictionary[String, int] = {}
var _quick_said := 0


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
	var facts := {"poor_fix": missions.knows("poor_fix:" + m.goal_problem), "fading": missions.fading_fix(m),
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
## connected (delivered:<story>), the proposals agreed (agreed:<dialog>:<proposal>),
## and who left (left:<person>).
func _note_story() -> void:
	if followed.delivered_at >= 0:
		missions.facts.add("delivered:" + FollowedOrder.STORY)
	if people == null:
		return
	for id: String in people.agreed:
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


# ── In passing (Phase 2 §1.4, §2.4): greetings, quick lines, coffee chatter ──

## The morning hello of `person_id` by your name, once a day: their line after what
## yesterday left (greeting_fact), else an ordinary morning. "" when they greeted you
## today already or have no greeting.
func greet(person_id: String) -> String:
	var today := SimCalendar.day_of(region.net.time)
	if _greeted.get(person_id, -1) == today:
		return ""
	var line := catalog.reactions.greeting(person_id, greeting_fact(person_id), hash(person_id) + today)
	if not line.is_empty():
		_greeted[person_id] = today
	return fill_tokens(line)


## What a person remembers this morning (one of Reactions.FACTS, or ""): how the last talk
## went when it was on an earlier day, at most GREETING_MEMORY_DAYS ago (a ruined or
## pressured talk first, then an agreement, then being heard), else a fix at their place
## that was standardised that recently.
func greeting_fact(person_id: String) -> String:
	var now := region.net.time
	var log: Array = people.talk_log.get(person_id, [])
	var at := int(log[-1].get("at", -1)) if not log.is_empty() else -1
	var ago := SimCalendar.day_of(now) - SimCalendar.day_of(at)
	if at >= 0 and ago >= 1 and ago <= GREETING_MEMORY_DAYS:
		var flags: Array = people.memory.get(person_id, {}).get("flags", [])
		for flag: String in ["ruined", "pressured"]:
			if flag in flags:
				return flag
		if log[-1].get("outcome") == "commitment":
			return "committed"
		if "heard" in flags:
			return "heard"
	var p: PersonDef = people.persons.get(person_id)
	for problem: ProblemDef in region.problem_list() if p != null else []:
		var st: ProblemState = region.state[problem.id]
		if problem.step == p.place and st.standardised and st.phase == ProblemState.Phase.RESOLVED \
				and now - st.check_at <= SimCalendar.days(GREETING_MEMORY_DAYS):
			return "standardised"
	return ""


## One line about today when there is nothing to discuss (E on a person; no panel): tired
## when their morale is low, else busy or calm by their team's queue, else the hour.
func quick_line(person_id: String) -> String:
	_quick_said += 1
	var line := catalog.reactions.quick_line(person_id, quick_mood(person_id), hash(person_id) + _quick_said)
	return fill_tokens(line)


## The mood of a quick line now (one of Reactions.MOODS).
func quick_mood(person_id: String) -> String:
	if int(people.morale.get(person_id, 100)) < TIRED_MORALE:
		return "tired"
	var load := load_of(person_id)
	if not load.is_empty():
		return load
	var minute := minute_of_day()
	return "morning" if minute < MORNING_UNTIL else ("late" if minute >= LATE_FROM else "afternoon")


## How full their team's work is: busy, calm, or "" (in between, or no team or queue known).
func load_of(person_id: String) -> String:
	var p: PersonDef = people.persons.get(person_id)
	var step := region.net.step_at(p.place) if p != null else null
	if step == null or step.pool_ids.is_empty():
		return ""
	var busy: float = region.net.pools[step.pool_ids[0]].load_since(SimCalendar.day_of(region.net.time) - LOAD_DAYS)
	var queue := region.net.queue_days(step)
	if busy >= BUSY_SHARE or queue >= BUSY_QUEUE_DAYS:
		return "busy"
	return "calm" if busy < CALM_SHARE and queue < CALM_QUEUE_DAYS else ""


## Two colleagues at the coffee corner: their exchange [first line, second line], once a
## day per pair; [] when they chatted today or nothing fits their teams and load.
func chatter(first: String, second: String) -> Array[String]:
	var today := SimCalendar.day_of(region.net.time)
	var pair := first + "|" + second if first < second else second + "|" + first
	var out: Array[String] = []
	if _chatted.get(pair, -1) == today:
		return out
	var teams := [first, second].map(func(id: String) -> String:
		return people.persons[id].team if people.persons.has(id) else "")
	var loads := [load_of(first), load_of(second)]
	var load := "busy" if "busy" in loads else ("calm" if loads.all(func(l: String) -> bool: return l == "calm") else "")
	out = catalog.reactions.chatter_for(teams, load, hash(pair) + today,
		SimCalendar.weekday(region.net.time - SimCalendar.days(WARMUP_DAYS)))
	if not out.is_empty():
		_chatted[pair] = today
	out.assign(out.map(fill_tokens))
	return out


## Today's greetings and chatter for the save, so "once a day" survives a reload.
func passing_to_dict() -> Dictionary:
	return {"greeted": _greeted.duplicate(), "chatted": _chatted.duplicate()}


## Restore passing_to_dict() output, untrusted: an entry that is not id → day is
## dropped; junk or an old save without it is nobody greeted yet.
func load_passing(d: Variant) -> void:
	var saved := JsonFile.dict_or_empty(d)
	_greeted = _days_by_id(saved.get("greeted"))
	_chatted = _days_by_id(saved.get("chatted"))


static func _days_by_id(v: Variant) -> Dictionary[String, int]:
	var out: Dictionary[String, int] = {}
	var days := JsonFile.dict_or_empty(v)
	for id: Variant in days:
		if id is String and days[id] is int:
			out[id] = days[id]
	return out


## Who could use a talk now, for the dagstart (spec §5.7; at most one by the
## cadence in People): [{person, name, dialog, line}].
func checkin_prompts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in people.prompt_lines():
		p["name"] = people.persons[p["person"]].name
		out.append(p)
	return out


## What the player knows of a person (the journal's Mensen tab): {id, name,
## role, place, trust_pips, morale_band (0 low · 1 middling · 2 high),
## cooldown_until, outcomes (dialog id → its best outcome), observed (what they
## said, newest first: People.observed), talks (newest first: People.talk_log),
## note (the player's own, "" for none), open (_still_open), talk_ready (they
## have a talk for you now)}; {} for an unknown id.
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
		"cooldown_until": int(people.memory.get(person_id, {}).get("cooldown_until", 0)), "outcomes": outcomes,
		"observed": _filled(_newest_first(people.observed.get(person_id, []))),
		"talks": _filled(_newest_first(people.talk_log.get(person_id, []))), "note": people.note.get(person_id, ""),
		"open": _still_open(person_id, facts),
		"talk_ready": not people.cooling_down(person_id, region.net.time) and people.dialog_for(person_id, _world(p)) != null}


## What a person's agreements still wait for (the Mensen tab, U16): [{dialog,
## outcome (partial | blocked), wait_for (a heard concern's condition, else
## ""), hints (a block's route hints)}].
func _still_open(person_id: String, facts: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: DialogDef in people.dialogs.values():
		var o := people.effective_outcome(d.id, facts) if d.person == person_id else ""
		if o == "partial":
			out.append({"dialog": d.id, "outcome": o, "wait_for": _heard_wait_for(d), "hints": []})
		elif o == "blocked":
			out.append({"dialog": d.id, "outcome": o, "wait_for": "",
				"hints": d.block.get("routes", []).map(func(r: Dictionary) -> String: return str(r.get("hint", "")))})
	return out


## The concern's `wait_for` of a dialog whose concern the player heard ("" if
## not heard or it names nothing): a condition never shows before its concern.
func _heard_wait_for(d: DialogDef) -> String:
	for key: String in people.revealed:
		if key.get_slice("/", 0) == d.id and people.revealed[key].has("concern"):
			var layers := d.layers_of(int(key.get_slice("/", 1)))
			if layers.size() > 1:
				return str(layers[1].get("wait_for", ""))
	return ""


static func _newest_first(entries: Array) -> Array:
	var out := entries.duplicate(true)
	out.reverse()
	return out


## The player's note on a person (the Mensen tab; People.set_note).
func set_note(person_id: String, text: String) -> bool:
	return people.set_note(person_id, text)


## Open the talk a person has for the player: {dialog, kind, person, name, short,
## role, opening, position ({text, tags}), meter, moves}, or an error:
## in_dialog | unknown_person | cooling_down (after a ruined talk; the UI says
## the bank's special.cooling_down line) | nothing_to_say.
func start_dialog(person_id: String) -> Dictionary:
	if _talk != null or _expert != null:
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
	if d.kind == ExpertTalk.KIND:   # topic by topic: no position, no moves (phase 2 design §2.5)
		_expert = people.start_expert(d, world)
		return _filled({"dialog": d.id, "kind": d.kind, "person": p.id, "name": p.name, "short": p.short,
			"role": p.role, "opening": people.opening(d), "position": {}, "meter": _expert.meter(), "moves": []})
	_talk = people.start(d, world)
	return _filled({"dialog": d.id, "kind": d.kind, "person": p.id, "name": p.name, "short": p.short, "role": p.role,
		"opening": people.opening(d, _talk.version), "position": _talk.position(), "meter": _talk.meter(), "moves": _talk.moves()})


## The moves of the talk in progress (Dialog.moves); [] when there is none.
func dialog_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _talk != null:
		out.assign(_filled(_talk.moves()))
	return out


## This turn's sentences in the talk in progress (Dialog.offer: [{move, pick,
## line}], a shown clue's text in its line); [] when there is none.
func dialog_offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _expert != null:
		out.assign(_filled(_expert.offer()))
	if _talk != null:
		for o: Dictionary in _talk.offer():
			out.append(_filled(_with_clue(o, o["pick"])))
	return out


## `said` (an offer or a move's result) with the text of the clue it shows
## (`clue_id`) in its line, for Dialog.DATA_TOKEN.
func _with_clue(said: Dictionary, clue_id: String) -> Dictionary:
	if said.get("move") != "show_data" or not Dialog.DATA_TOKEN in str(said.get("line", "")):
		return said
	var p: ProblemDef = region.problems.get(clue_id.get_slice(":", 0))
	var clues := p.clues.filter(func(c: Clue) -> bool: return c.id == clue_id) if p != null else []
	var text: String = clues[0].text if not clues.is_empty() else ""
	return said.merged({"line": str(said["line"]).replace(Dialog.DATA_TOKEN, text).strip_edges()}, true)


## The meter of the talk in progress (Dialog.meter); {} when there is none.
func dialog_meter() -> Dictionary:
	if _expert != null:
		return _expert.meter()
	return _talk.meter() if _talk != null else {}


## The layers of the talk in progress, for the layer tracker: [{id
## (position | interest | concern), text ("" until heard), heard}]; the
## position is heard from the start, a layer from an earlier talk stays heard.
## [] when there is no talk.
func dialog_layers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _talk == null:
		return out
	out.append({"id": "position", "text": str(_talk.position().get("text", "")), "heard": true})
	for layer: Dictionary in _talk.layers():
		var heard := _talk.revealed.has(layer["id"])
		out.append({"id": str(layer["id"]), "text": str(layer.get("text", "")) if heard else "", "heard": heard})
	out.assign(_filled(out))
	return out


## Make a move in the talk (a pick for show_data, propose_experiment and
## propose: one the moves offered). Dialog.say's result; when the talk ended,
## with `summary` (People.finish), and its minutes have passed. Errors:
## no_dialog | unknown_move | bad_pick (and nothing changes).
func choose_move(move: String, pick: String = "") -> Dictionary:
	if _expert != null:
		return _ask_expert(move, pick)
	if _talk == null:
		return {"error": "no_dialog"}
	var result := _talk.say(move, pick)
	if result.get("ended", false):
		result["summary"] = _finish_talk()
	return _filled(_with_clue(result, pick))


## A question in the expert talk (ExpertTalk.ASK with the topic id) or its close
## (ExpertTalk.CLOSE, as "Afronden"): ExpertTalk.say's result. A topic's new
## clue is found at once; when the talk ends, with `summary`
## (People.finish_expert) and its minutes passed.
func _ask_expert(move: String, pick: String) -> Dictionary:
	var result := _expert.say(move, pick)
	if result.has("error"):
		return result
	if not str(result["clue"]).is_empty():
		region.found[result["clue"]] = true
	if result["ended"]:
		var t := _expert
		_expert = null
		result["summary"] = people.finish_expert(t, region.net.time)
		_after(t.minutes())
	return _filled(result)


## The tokens talk lines speak through: the player's (PlayerProfile.fill:
## {speler}, {jongen_meid} …) and {aanvraag_datum}, the day the El Amrani
## family applied (D9 talks audit #20). No filled value holds a brace.
func fill_tokens(text: String) -> String:
	if not "{" in text:
		return text
	var born := date_of(followed.born)
	var out := player.fill(text).replace("{aanvraag_datum}", "%d %s" % [born["day"], MONTH_NAMES[born["month"] - 1]])
	for found in _PROMISE_DATE.search_all(out):   # {promise_date:N}: the date N days from now (the promise checked)
		var t := region.net.time + SimCalendar.days(found.get_string(1).to_int())
		var date := date_of(t)
		out = out.replace(found.get_string(), "%s %d %s" % [WEEKDAY_NAMES[SimCalendar.weekday(t - SimCalendar.days(WARMUP_DAYS))],
			date["day"], MONTH_NAMES[date["month"] - 1]])
	return out


## Every text in a talk's result, filled (fill_tokens).
func _filled(v: Variant) -> Variant:
	if v is String:
		return fill_tokens(v)
	if v is Dictionary:
		var d := {}
		for k: Variant in v:
			d[k] = _filled(v[k])
		return d
	if v is Array:
		return (v as Array).map(_filled)
	return v


## End the talk gracefully (the close move); see choose_move.
func end_dialog() -> Dictionary:
	return choose_move("close")


## A dialog's best agreement so far, a met condition counted as commitment
## ("" when never had). What a mission's talk_to {dialog, outcome} goal reads
## (Missions.talk_outcome).
func talk_outcome(dialog_id: String) -> String:
	return people.effective_outcome(dialog_id, people.facts(_facts()))


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
		"now": region.net.time, "beats": missions.beats(), "seed": region.net.run_seed,
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
	var main := d.def.on_any(missions.active("main").map(func(m: MissionDef) -> String: return m.id))
	var morale_before: int = people.morale[d.who.id]
	var summary := people.finish(d, region.net.time, main)
	_keep_promise(d)
	discoveries.note_talk(self, {"person": d.who.id, "team": d.who.team, "kind": d.def.kind, "outcome": d.outcome,
		"listened_first": not d.steered_early and d.revealed.has("concern"), "silence_reveal": d.concern_by == "silence",
		"own_idea": d.own_idea(), "morale_before": morale_before, "pressured": d.pressured, "confronted": d.confronted})
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


## A promise agreed in talk `d` (a proposal with `promise`, PLAN 2.4) becomes a
## fact the simulation checks: promised:<dialog>:<ISO date> for a date promised
## (`days` from today), promised:<dialog>:<kind> for an action (a callback). It
## replaces the dialog's earlier promise only when this talk's agreement is now
## the best one (People.finish keeps that).
func _keep_promise(d: Dialog) -> void:
	if not d.outcome in People.BUY_IN_OF or people.agreed.get(d.def.id) != d.table:
		return
	var promise := JsonFile.dict_or_empty(d.def.item(d.table).get("promise"))
	if promise.is_empty():
		return
	var kind := str(promise.get("kind", ""))
	var value := iso_date(region.net.time + SimCalendar.days(int(promise.get("days", 0)))) \
		if kind in DATE_PROMISES else kind
	missions.facts.remove_prefix("%s%s:" % [Facts.PROMISED, d.def.id])
	missions.facts.add("%s%s:%s" % [Facts.PROMISED, d.def.id, value])


## Customers whose talk is due now (PLAN 2.4): the KCC's headset takes their
## call, and they ring the player's phone (CustomerCalls). [{person, dialog,
## name}], in content order; [] when none.
func customer_calls() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: PersonDef in people.persons.values():
		if not p.customer or people.cooling_down(p.id, region.net.time):
			continue
		var d := people.dialog_for(p.id, _world(p))
		if d != null:
			out.append({"person": p.id, "dialog": d.id, "name": p.name})
	return out


## After every action: check-in prompts and the low-morale clock move on
## (People.daily; a goodbye is an event), the facts talks set join the ones missions and
## countermeasures read (Missions.facts), and every resolved fix with an owner
## carries that owner's buy-in now (a later commitment repairs it, a met
## condition upgrades it; Sustain.BUY_IN).
func _sync_people() -> void:
	if people == null:
		return
	var world_facts := _facts()
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
