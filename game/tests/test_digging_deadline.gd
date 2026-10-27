extends TestCase
## Act II's one deadline (Merijn, 2026-10-27, M1): digging damage must be fixed before the
## winter, and missing it closes the cheap contractor briefing, never the problem. Real content.

const MISSION := "fix_digging_damage"
const PROBLEM := "digging_damage"
const CHEAP := "contractor_briefing"
## Act I's mains: what must be done before Act II opens.
const ACT_ONE := ["walk_connections", "fix_custom_design", "fix_incomplete_application", "fix_installer_not_ready",
	"fix_status_callers", "fix_done_but_not_closed"]


func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	for id in ACT_ONE:
		s.missions.done_once[id] = true
	s.missions.update()
	assert_eq(s.missions.status(MISSION), "available", "Act II is open")
	return s


## Play day `day` of the campaign (day 0: the first Monday) without simulating the days between.
func _on_day(s: GameSession, day: int) -> void:
	s.missions.play_start = s.region.net.time - SimCalendar.days(day)
	s.missions.update()


func test_the_deadline_is_the_second_winters_first_frost_and_names_the_cheap_briefing() -> void:
	var def: MissionDef = _session().missions.defs[MISSION]
	assert_eq(def.deadline_on_day, 435, "21 December 2027, the shortest day a year after winter 1's day 70")
	assert_eq(Array(def.fail_closes), [CHEAP])
	assert_false(def.fail_text.is_empty(), "the failure is told")


func test_until_that_day_the_door_stays_open() -> void:
	var s := _session()
	_on_day(s, 435)
	assert_false(s.missions.failed(MISSION), "the deadline is judged after its day")
	assert_true(s.region.available_countermeasures().any(func(c: CountermeasureDef) -> bool: return c.id == CHEAP))


func test_missing_it_fails_the_mission_and_closes_the_cheap_briefing_only() -> void:
	var s := _session()
	_on_day(s, 436)
	assert_true(s.missions.failed(MISSION))
	assert_eq(s.region.closed.keys(), [CHEAP], "exactly the cheap briefing is closed")
	assert_eq(s.missions.status(MISSION), "available", "a closed door, not the end of the problem")
	assert_true(s.missions.drain_events().has({"type": "failed", "mission": MISSION}))


func test_another_countermeasure_still_solves_the_problem_after_the_deadline() -> void:
	var s := _session()
	_on_day(s, 436)
	var problem: ProblemDef = s.region.problems[PROBLEM]
	var open: Array = s.region.available_countermeasures().filter(
		func(c: CountermeasureDef) -> bool: return problem.countermeasures.has(c.id))
	assert_false(open.is_empty(), "a way is left")
	assert_true(open.any(func(c: CountermeasureDef) -> bool:
		return Pdca.effectiveness(problem, c, s.region.maturity())["eff"] >= Pdca.CHECK_PASS),
		"and one of them can pass the Check")
	assert_eq(s.accept(MISSION), "", "the mission can still be taken on")


func test_a_fix_already_under_way_keeps_the_door_open() -> void:
	var s := _session()
	assert_eq(s.accept(MISSION), "")
	s.region.state[PROBLEM].phase = ProblemState.Phase.DOING   # the A3 is in: the Check still judges it
	_on_day(s, 436)
	assert_false(s.missions.failed(MISSION))
	assert_true(s.region.closed.is_empty())


## The whole way, after the deadline: the cheap briefing is refused, the patient fix is played
## from the gemba to the Act, and the mission completes (the problem is solved another way).
func test_the_mission_is_still_played_to_the_end_with_the_other_countermeasure() -> void:
	var s := _session()
	_on_day(s, 436)
	assert_eq(s.accept(MISSION), "")
	var problem: ProblemDef = s.region.problems[PROBLEM]
	for depth in 3:
		for c: Clue in problem.clues:
			if c.key and c.depth == depth and c.dialog.is_empty():
				if c.tool == "conversation":
					s.ask(c.at, "walk")
				else:
					s.use_tool(c.at, c.tool)
	assert_true(MissionTalks.win(s, MISSION), "Gert is brought along")
	var cause: int = Investigation.cause_options(problem, s.region.problem_list())["correct"]
	var evidence := s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	var a3 := {"waste": problem.waste, "cause": cause, "evidence": evidence, "cm": CHEAP, "prediction": "throughput"}
	assert_ne(s.submit_a3(PROBLEM, a3), "", "the closed briefing is refused")
	a3["cm"] = "standard_test_trenches"
	assert_eq(s.submit_a3(PROBLEM, a3), "")
	assert_eq(s.wait_for_check(PROBLEM), "")
	assert_true(s.check(PROBLEM)["passed"], "the patient fix works")
	s.act(PROBLEM, true)
	assert_eq(s.missions.status(MISSION), "completed")
