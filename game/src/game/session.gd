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

## Whole weeks of simulated work before play starts, so queues exist and the
## first day of play is a Monday (the simulation's week starts on Monday).
const WARMUP_DAYS := 63
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

var catalog: Catalog
var region: Region
var missions: Missions
## The first thing wrong with the content; "" when the game is usable.
var error := ""


## A new game on the real content. `seed_value` fixes the simulation's luck.
static func new_game(seed_value: int = 1, data_dir: String = Catalog.DATA_DIR) -> GameSession:
	var s := GameSession.new()
	s.catalog = Catalog.load_from(data_dir)
	var net := Network.load_file(data_dir + "/value_streams.json", seed_value)
	s.error = s.catalog.error if not s.catalog.error.is_empty() else net.error
	if not s.error.is_empty():
		return s
	s.region = Region.new(net, s.catalog.problems, s.catalog.countermeasures, Profile.new())
	s.region.use_kpis(s.catalog.kpis)
	s.missions = Missions.new(s.region, s.catalog.missions, s.catalog.coach)
	if not s.missions.defs.has(STORY_MISSION):
		s.error = "missing mission: " + STORY_MISSION
		return s
	# No problems are active yet, so the warm-up costs nothing and teaches nothing.
	net.advance(SimCalendar.days(WARMUP_DAYS) + START_MINUTE)
	# Done without a reward: it happened before the game starts.
	s.missions.progress[STORY_MISSION] = {"status": "completed", "asks": {}}
	s.missions.done_once[STORY_MISSION] = true
	return s


# ── Actions ─────────────────────────────────────────────────────────────────

## Take on a mission (activating its problem). "" or Missions.accept's code.
func accept(mission_id: String) -> String:
	var refused := missions.accept(mission_id)
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
	_after(Investigation.TOOLS["conversation"]["minutes"])
	return result


## Submit the A3 {waste, cause (index into cause_options), evidence (clue
## ids), cm, prediction (a KPI)} and start the experiment. "" or why not:
## unknown_problem | not_spotted | waste | cause | evidence | countermeasure |
## prediction. Malformed fields count as missing.
func submit_a3(problem_id: String, a3: Dictionary) -> String:
	if not region.state.has(problem_id):
		return "unknown_problem"
	var refused := region.submit_a3(problem_id, _cleaned(a3))
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


## Compare before and after: Region.check's result, or an error:
## unknown_problem | not_check_ready.
func check(problem_id: String) -> Dictionary:
	if not region.state.has(problem_id):
		return {"error": "unknown_problem"}
	var result := region.check(problem_id)
	_after(0)
	return result if not result.is_empty() else {"error": "not_check_ready"}


## Close a checked problem, with or without standardising: the score (see
## Pdca.score), or an error: unknown_problem | not_checked.
func act(problem_id: String, standardise: bool) -> Dictionary:
	if not region.state.has(problem_id):
		return {"error": "unknown_problem"}
	var score := region.act(problem_id, standardise)
	_after(0)
	return score.duplicate(true) if not score.is_empty() else {"error": "not_checked"}


## The coach's reply (Missions.ask_coach): about the main mission only.
func ask_coach(mission_id: String = "") -> Dictionary:
	var reply := missions.ask_coach(mission_id)
	_after(0)
	return reply


## What happened since the last call, for the world and UI: the Region's
## events, then the missions' (see Region.events and Missions.events).
func drain_events() -> Array[Dictionary]:
	var out := region.drain_events()
	out.append_array(missions.drain_events())
	return out


# ── Views ───────────────────────────────────────────────────────────────────

## Dutch date and time, e.g. "di 13 okt, 09:30".
func clock_text() -> String:
	var played := region.net.time - SimCalendar.days(WARMUP_DAYS)
	var date := Time.get_date_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(PLAY_START_DATE) + SimCalendar.day_of(played) * 86400)
	var minute_of_day := played % SimCalendar.MINUTES_PER_DAY
	return "%s %d %s, %02d:%02d" % [WEEKDAYS[SimCalendar.weekday(played)], date["day"], MONTHS[date["month"] - 1],
		minute_of_day / 60, minute_of_day % 60]


func budget() -> int:
	return region.profile.budget


func xp() -> int:
	return region.profile.xp


## The belt's id (white, yellow, ...).
func belt() -> String:
	return Progression.BELTS[Progression.belt_index(xp())]["id"]


## The missions on the board that can be taken on now.
func available_missions() -> Array[MissionDef]:
	return missions.available()


## The active missions: the main one first.
func active_missions() -> Array[MissionDef]:
	var out := missions.active("main")
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


# ── Internals ───────────────────────────────────────────────────────────────

func _is_place(place: String) -> bool:
	return region.net.step_at(place) != null


## Time passes, then the missions notice what happened.
func _after(minutes: int) -> void:
	if minutes > 0:
		region.advance(minutes)
	missions.update()


## The A3 as the rules read it: evidence a list of clue ids, cm an id.
## Anything else reads as missing, so the rules name the first thing wrong
## in their own order.
static func _cleaned(a3: Dictionary) -> Dictionary:
	var clean := a3.duplicate()
	var evidence: Variant = a3.get("evidence", [])
	clean["evidence"] = evidence.filter(func(id: Variant) -> bool: return id is String) if evidence is Array else []
	clean["cm"] = a3["cm"] if a3.get("cm") is String else ""
	return clean
