extends TestCase
## Act II's one deadline (Merijn, 2026-10-27, M1): digging damage must be fixed within nine weeks
## of opening, and missing it closes the cheap contractor briefing, never the problem. Real content.

const MISSION := "fix_digging_damage"
const PROBLEM := "digging_damage"
const CHEAP := "contractor_briefing"
const WEEKS_9 := 63
## Act I's mains: what must be done before Act II opens.
const ACT_ONE := ["walk_connections", "fix_custom_design", "fix_incomplete_application", "fix_installer_not_ready",
	"fix_status_callers", "fix_done_but_not_closed"]


## A session with Act I done and Act II just opened (its clock starts now).
func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	for id in ACT_ONE:
		s.missions.done_once[id] = true
	s.missions.update()
	assert_eq(s.missions.status(MISSION), "available", "Act II is open")
	assert_true(s.missions.opened_at.has(MISSION), "its clock runs from the opening, taken on or not")
	return s


## Let `days` of the mission's clock pass without simulating them (the opening moves back).
func _age(s: GameSession, days: int) -> void:
	s.missions.opened_at[MISSION] -= SimCalendar.days(days)
	s.missions.update()


func test_the_deadline_is_nine_weeks_from_opening_and_names_the_cheap_briefing() -> void:
	var def: MissionDef = _session().missions.defs[MISSION]
	assert_eq(def.deadline_days, WEEKS_9)
	assert_eq(def.deadline_on_day, -1, "a clock from the opening, not a fixed day")
	assert_eq(Array(def.fail_closes), [CHEAP])
	assert_false(def.fail_text.is_empty(), "the failure is told")


func test_until_the_ninth_week_is_over_the_door_stays_open() -> void:
	var s := _session()
	_age(s, WEEKS_9)
	assert_false(s.missions.failed(MISSION), "the deadline is judged after its last day")
	assert_true(s.region.available_countermeasures().any(func(c: CountermeasureDef) -> bool: return c.id == CHEAP))


func test_a_day_past_it_fails_the_mission_and_closes_the_cheap_briefing_only() -> void:
	var s := _session()
	_age(s, WEEKS_9 + 1)
	assert_true(s.missions.failed(MISSION))
	assert_eq(s.region.closed.keys(), [CHEAP], "exactly the cheap briefing is closed")
	assert_eq(s.missions.status(MISSION), "available", "a closed door, not the end of the problem")
	assert_true(s.missions.drain_events().has({"type": "failed", "mission": MISSION}))


func test_the_clock_runs_in_simulated_time_too() -> void:
	var s := _session()
	s.region.advance_days(WEEKS_9 - 1)
	s.missions.update()
	assert_false(s.missions.failed(MISSION), "week nine is not over")
	s.region.advance_days(2)
	s.missions.update()
	assert_true(s.missions.failed(MISSION))
	assert_eq(s.region.closed.keys(), [CHEAP])


func test_another_countermeasure_still_solves_the_problem_after_the_deadline() -> void:
	var s := _session()
	_age(s, WEEKS_9 + 1)
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
	_age(s, WEEKS_9 + 1)
	assert_false(s.missions.failed(MISSION))
	assert_true(s.region.closed.is_empty())


## Solving it in time completes the mission with the door still open.
func test_solved_before_the_deadline_the_mission_completes_and_nothing_closes() -> void:
	var s := _session()
	assert_eq(s.accept(MISSION), "")
	_solve(s, "standard_test_trenches")
	assert_eq(s.missions.status(MISSION), "completed")
	assert_false(s.missions.failed(MISSION))
	_age(s, WEEKS_9 + 1)
	assert_false(s.missions.failed(MISSION), "done missions are never failed afterwards")
	assert_true(s.region.closed.is_empty())


## The whole way, after the deadline: the cheap briefing is refused, the patient fix is played
## from the gemba to the Act, and the mission completes (the problem is solved another way).
func test_the_mission_is_still_played_to_the_end_with_the_other_countermeasure() -> void:
	var s := _session()
	_age(s, WEEKS_9 + 1)
	assert_eq(s.accept(MISSION), "")
	_solve(s, "standard_test_trenches", true)
	assert_eq(s.missions.status(MISSION), "completed")


## Gemba, Gert's talk, the A3, the Check and the Act. With `closed_first` the cheap briefing is
## tried first and refused.
func _solve(s: GameSession, cm: String, closed_first := false) -> void:
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
	if closed_first:
		assert_ne(s.submit_a3(PROBLEM, a3), "", "the closed briefing is refused")
	a3["cm"] = cm
	assert_eq(s.submit_a3(PROBLEM, a3), "")
	assert_eq(s.wait_for_check(PROBLEM), "")
	assert_true(s.check(PROBLEM)["passed"], "the patient fix works")
	s.act(PROBLEM, true)
