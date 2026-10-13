extends TestCase
## GameSession: the one facade the 3D world and the UI call. Real content,
## real network; the mission "Maatwerk voor standaardwerk" is played end to end.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "connections.design"
const INTAKE := "connections.intake"


func _accepted() -> GameSession:
	var s := GameSession.new_game(11)
	assert_eq(s.error, "")
	assert_eq(s.accept(MISSION), "")
	return s


## Find every key clue like an expert, in the order the "whys" go deeper.
func _investigate(s: GameSession) -> void:
	s.use_tool(DESIGN, "time_study")
	s.use_tool(DESIGN, "documents")
	s.ask(INTAKE, "walk")
	s.use_tool(DESIGN, "data")


func _a3(s: GameSession, cm: String) -> Dictionary:
	var problem: ProblemDef = s.region.problems[PROBLEM]
	var cause: int = Investigation.cause_options(problem, s.region.problem_list())["correct"]
	var evidence := s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	return {"waste": "overprocessing", "cause": cause, "evidence": evidence, "cm": cm, "prediction": "throughput"}


func test_a_new_game_starts_on_a_monday_morning_with_the_story_begun() -> void:
	var s := GameSession.new_game(11)
	assert_eq(s.error, "")
	assert_eq(s.clock_text(), "ma 12 okt, 08:30")
	assert_eq(s.budget(), 50000)
	assert_eq(s.xp(), 0)
	assert_eq(s.belt(), "white")
	assert_eq(s.active_missions().size(), 0, "nothing is active until the player accepts it")
	var mains := s.available_missions().filter(func(m: MissionDef) -> bool: return m.kind == "main")
	assert_eq(mains.map(func(m: MissionDef) -> String: return m.id), [MISSION],
		"the connections stream was walked in the story: the first problem is open")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "completed")
	assert_eq(s.xp(), 0, "the story's walk is not rewarded again")
	assert_true(s.region.net.open_orders(s.region.net.stream("connections")).size() > 0, "the warm-up built queues")


func test_a_session_over_missing_content_reports_the_error() -> void:
	var s := GameSession.new_game(1, "res://does_not_exist")
	assert_ne(s.error, "")


func test_the_clock_is_dutch_and_follows_the_simulation() -> void:
	var s := GameSession.new_game(11)
	s.region.advance(60)
	assert_eq(s.clock_text(), "ma 12 okt, 09:30")
	s.region.advance(SimCalendar.days(2))
	assert_eq(s.clock_text(), "wo 14 okt, 09:30")
	s.region.advance(SimCalendar.days(18))
	assert_eq(s.clock_text(), "zo 1 nov, 09:30", "the month rolls over")


func test_a_tool_costs_its_minutes() -> void:
	var s := _accepted()
	var before := s.region.net.time
	var result := s.use_tool(DESIGN, "shadow")
	assert_false(result.has("error"))
	assert_eq(s.region.net.time - before, Investigation.TOOLS["shadow"]["minutes"])
	assert_eq(s.clock_text(), "ma 12 okt, 12:30")
	assert_eq(s.phase_of(PROBLEM), "spotted", "an obvious problem shows to anyone who looks")


func test_a_question_costs_a_conversation() -> void:
	var s := _accepted()
	var before := s.region.net.time
	var result := s.ask(INTAKE, "walk")
	assert_false(result.has("error"))
	assert_eq(s.region.net.time - before, Investigation.TOOLS["conversation"]["minutes"])


func test_bad_input_is_refused_without_spending_time() -> void:
	var s := _accepted()
	var before := s.region.net.time
	assert_eq(s.use_tool("connections.nowhere", "shadow"), {"error": "unknown_place"})
	assert_eq(s.use_tool("nowhere", "shadow"), {"error": "unknown_place"})
	assert_eq(s.use_tool(DESIGN, "crystal_ball"), {"error": "unknown_tool"})
	assert_eq(s.use_tool(DESIGN, "conversation"), {"error": "use_ask"}, "a conversation is a question, with trust at stake")
	assert_eq(s.ask("nowhere", "walk"), {"error": "unknown_place"})
	assert_eq(s.ask(INTAKE, "tell_me_everything"), {"error": "unknown_question"})
	assert_eq(s.region.net.time, before)
	assert_eq(s.region.found.size(), 0)


func test_missions_cannot_be_accepted_out_of_turn() -> void:
	var s := GameSession.new_game(11)
	assert_eq(s.accept("no_such_mission"), "unknown")
	assert_eq(s.accept("fix_incomplete_application"), "locked", "it opens after the first bottleneck is fixed")
	assert_eq(s.accept(MISSION), "")
	assert_eq(s.accept(MISSION), "not_available", "it is already taken")


func test_the_a3_errors_pass_through() -> void:
	var s := GameSession.new_game(11)
	assert_eq(s.submit_a3("no_such_problem", {}), "unknown_problem")
	assert_eq(s.submit_a3(PROBLEM, {}), "not_spotted", "problems only arrive through missions")
	s.accept(MISSION)
	s.use_tool(DESIGN, "time_study")
	assert_eq(s.submit_a3(PROBLEM, {"waste": "magic"}), "waste")
	assert_eq(s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": "the form"}), "cause")
	assert_eq(s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": 0, "evidence": "all of it"}), "evidence")
	assert_eq(s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": 0, "evidence": [42]}), "evidence")
	assert_eq(s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": 0, "evidence": []}), "evidence")
	var a3 := _a3(s, "standard_designs")
	a3["cm"] = 7
	assert_eq(s.submit_a3(PROBLEM, a3), "countermeasure")
	a3["cm"] = "no_such_cm"
	assert_eq(s.submit_a3(PROBLEM, a3), "countermeasure")
	a3 = _a3(s, "standard_designs")
	a3["prediction"] = "happiness"
	assert_eq(s.submit_a3(PROBLEM, a3), "prediction")
	assert_eq(s.phase_of(PROBLEM), "spotted", "nothing started, nothing paid")
	assert_eq(s.budget(), 50000)


func test_check_act_and_waiting_need_a_running_experiment() -> void:
	var s := _accepted()
	assert_eq(s.wait_for_check(PROBLEM), "not_doing")
	assert_eq(s.check(PROBLEM), {"error": "not_check_ready"})
	assert_eq(s.act(PROBLEM, true), {"error": "not_checked"})
	assert_eq(s.wait_for_check("no_such_problem"), "unknown_problem")
	assert_eq(s.check("no_such_problem"), {"error": "unknown_problem"})
	assert_eq(s.act("no_such_problem", true), {"error": "unknown_problem"})


func test_the_coach_asks_about_the_main_mission_only() -> void:
	var s := GameSession.new_game(11)
	assert_eq(s.ask_coach()["kind"], "no_main")
	s.accept(MISSION)
	var first := s.ask_coach()
	assert_eq(first["kind"], "question")
	assert_eq(first["stage"], "go_see")
	assert_eq(first["text"], s.catalog.coach["stages"]["go_see"][0])
	var side := s.available_missions().filter(func(m: MissionDef) -> bool: return m.kind == "side")
	assert_true(side.is_empty() or s.ask_coach(side[0].id)["kind"] == "not_main", "no coaching on side missions")
	assert_eq(s.ask_coach("walk_meters"), {"kind": "not_main"}, "the coach helps only with the main quest")


func test_the_choices_are_the_same_for_every_problem() -> void:
	var s := _accepted()
	var ids := s.countermeasures().map(func(c: CountermeasureDef) -> String: return c.id)
	assert_true("standard_designs" in ids and "delegated_approval" in ids)
	assert_true(ids.size() > s.region.problems[PROBLEM].countermeasures.size(), "wrong ideas are on the list too")
	var causes := s.cause_options(PROBLEM)
	assert_true(causes.size() >= 3)
	assert_true(s.region.problems[PROBLEM].root_cause in causes)
	assert_eq(s.cause_options("no_such_problem"), [])


## The whole mission on the real content: gemba, A3, wait, Check, Act.
func test_the_mission_is_played_end_to_end() -> void:
	var s := _accepted()
	var start_time := s.region.net.time
	var xp_before := s.xp()
	assert_eq(s.active_missions().map(func(m: MissionDef) -> String: return m.id), [MISSION])
	assert_eq(s.phase_of(PROBLEM), "active")

	_investigate(s)
	var keys := s.region.problems[PROBLEM].clues.filter(func(c: Clue) -> bool: return c.key)
	assert_eq(s.clues_found(PROBLEM).size(), keys.size(), "the four key clues, no red herring")
	assert_eq(s.phase_of(PROBLEM), "spotted")
	assert_eq(s.ask_coach()["stage"], "understand")

	var budget_before := s.budget()
	assert_eq(s.submit_a3(PROBLEM, _a3(s, "standard_designs")), "")
	assert_eq(s.phase_of(PROBLEM), "doing")
	assert_true(s.budget() < budget_before, "the experiment is paid for")

	assert_eq(s.wait_for_check(PROBLEM), "")
	assert_eq(s.phase_of(PROBLEM), "check_ready")
	assert_eq(s.region.net.time, s.region.state[PROBLEM].check_at, "waited exactly until the Check")
	assert_eq(s.wait_for_check(PROBLEM), "", "waiting again changes nothing")
	assert_eq(s.region.net.time, s.region.state[PROBLEM].check_at)

	var checked := s.check(PROBLEM)
	assert_false(checked.has("error"))
	assert_true(checked["passed"], "the fitting countermeasure works")
	assert_eq(s.phase_of(PROBLEM), "checked")
	assert_eq(s.missions.status(MISSION), "active", "not done before Act")

	var score := s.act(PROBLEM, true)
	assert_false(score.has("error"))
	assert_true(score["total"] > 0)
	assert_eq(s.phase_of(PROBLEM), "resolved")
	assert_eq(s.missions.status(MISSION), "completed")
	assert_true(s.xp() > xp_before + 600, "the problem's XP and the mission reward")
	assert_true(s.region.net.time - start_time > SimCalendar.days(Region.CHECK_DAYS), "the experiment took its two weeks")
	assert_eq(s.active_missions().size(), 0)

	var types := s.drain_events().map(func(e: Dictionary) -> String: return e["type"])
	for expected in ["accepted", "check_ready", "completed"]:
		assert_true(expected in types, "%s in %s" % [expected, types])
	assert_eq(s.drain_events(), [], "events are delivered once")
