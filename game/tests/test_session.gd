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


## The second office mission, as an expert: the intake's form lets incomplete
## applications through; poka-yoke at the source, measured on lead time.
func test_the_second_mission_is_played_end_to_end() -> void:
	var second := "fix_incomplete_application"
	var problem_id := "incomplete_application"
	var s := _accepted()
	_investigate(s)
	assert_eq(s.submit_a3(PROBLEM, _a3(s, "standard_designs")), "")
	assert_eq(s.wait_for_check(PROBLEM), "")
	assert_true(s.check(PROBLEM)["passed"])
	s.act(PROBLEM, true)
	assert_eq(s.missions.status(MISSION), "completed")

	var open := s.available_missions().map(func(m: MissionDef) -> String: return m.id)
	assert_true(second in open, "the first fix opens the second mission: %s" % [open])
	var xp_before := s.xp()
	assert_eq(s.accept(second), "")
	assert_eq(s.phase_of(problem_id), "active")

	# The expert's route, with the deeper "whys" after the shallower ones.
	s.use_tool(INTAKE, "documents")
	s.use_tool(INTAKE, "data")
	s.ask(INTAKE, "walk")
	s.use_tool(INTAKE, "listen_in")
	var problem: ProblemDef = s.region.problems[problem_id]
	var keys := problem.clues.filter(func(c: Clue) -> bool: return c.key)
	assert_eq(s.clues_found(problem_id).size(), keys.size(), "all key clues found at the intake")
	var cause: int = Investigation.cause_options(problem, s.region.problem_list())["correct"]
	var a3 := {"waste": "defects", "cause": cause, "cm": "poka_yoke_application", "prediction": problem.kpi,
		"evidence": s.clues_found(problem_id).map(func(c: Clue) -> String: return c.id)}
	assert_eq(s.submit_a3(problem_id, a3), "")
	assert_eq(s.wait_for_check(problem_id), "")
	var checked := s.check(problem_id)
	print("CHECK ", problem.kpi, " before=", checked["before"], " after=", checked["after"])
	assert_true(checked["passed"], "the fitting countermeasure passes the Check")
	var kpi: String = problem.kpi
	assert_true(checked["after"][kpi] < checked["before"][kpi], "lead time falls: %s -> %s" % [checked["before"][kpi], checked["after"][kpi]])
	assert_true(checked["after"]["throughput"] > checked["before"]["throughput"], "more applications get through")
	assert_true(checked["after"]["capacity"] > checked["before"]["capacity"], "less rework frees intake capacity")
	assert_false(s.act(problem_id, true).has("error"))
	assert_eq(s.missions.status(second), "completed")
	assert_true(s.xp() > xp_before)


# ── The training week (Inwerkweek) ──────────────────────────────────────────

const TRAY := "training_tray"
const PLANNING := "connections.planning"


func _training() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	assert_eq(s.error, "")
	return s


func _active_ids(s: GameSession) -> Array:
	return s.active_missions().map(func(m: MissionDef) -> String: return m.id)


func test_without_training_the_week_counts_as_skipped() -> void:
	var s := GameSession.new_game(11)
	assert_false(s.in_training())
	assert_eq(s.missions.status("training_mon"), "completed")
	assert_eq(s.missions.status("training_fri"), "completed")


func test_a_new_game_with_training_starts_on_monday_of_the_week() -> void:
	var s := _training()
	assert_true(s.in_training())
	assert_eq(_active_ids(s), ["training_mon"], "the coach hands out the first day")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "locked", "the campaign waits for the week")
	assert_eq(s.missions.status(MISSION), "locked")
	assert_eq(s.ask_coach()["kind"], "question", "the coach helps with the training week")
	for id in ["netbeheerder", "aansluiting", "aansluittermijn"]:
		assert_true(id in s.region.profile.concepts, "glossary card " + id)


func test_skipping_training_opens_the_campaign_without_rewards() -> void:
	var s := _training()
	s.use_tool(INTAKE, "shadow")
	assert_eq(s.skip_training(), "")
	assert_false(s.in_training())
	assert_eq(s.xp(), 0, "no rewards for skipped days")
	assert_eq(s.budget(), 50000)
	assert_eq(s.missions.status("training_thu"), "completed")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "available", "a returning player starts the campaign")
	assert_eq(s.active_missions().size(), 0)
	assert_eq(s.skip_training(), "not_in_training")


## The whole week as a player would play it: walk, look, count, a practice A3
## with a short Check, and the Act with the time-lapse.
func test_the_training_week_is_played_end_to_end() -> void:
	var s := _training()
	# Monday: visit the three teams.
	s.use_tool(INTAKE, "shadow")
	s.use_tool(DESIGN, "shadow")
	assert_eq(s.missions.status("training_mon"), "active")
	assert_false(s.ask(PLANNING, "walk").has("error"))
	assert_eq(s.missions.status("training_mon"), "completed")
	assert_eq(_active_ids(s), ["training_tue"])
	# Tuesday: two tools at Werkvoorbereiding.
	s.use_tool(DESIGN, "time_study")
	s.use_tool(DESIGN, "time_study")
	assert_eq(s.missions.status("training_tue"), "active", "two different tools")
	s.use_tool(DESIGN, "documents")
	assert_eq(_active_ids(s), ["training_wed"])
	# Wednesday: count the queues at two steps.
	s.use_tool(INTAKE, "queue_count")
	s.use_tool(DESIGN, "queue_count")
	assert_eq(_active_ids(s), ["training_thu"])
	assert_eq(s.phase_of(TRAY), "active", "the practice problem arrives through Thursday's mission")
	# Thursday: the practice A3 and a three-day Check.
	s.use_tool(INTAKE, "shadow")
	s.use_tool(INTAKE, "time_study")
	s.ask(INTAKE, "walk")
	var problem: ProblemDef = s.region.problems[TRAY]
	var keys := problem.clues.filter(func(c: Clue) -> bool: return c.key)
	assert_eq(s.clues_found(TRAY).size(), keys.size(), "every key clue found at the intake")
	assert_eq(s.ask_coach()["stage"], "understand")
	var a3 := {"waste": problem.waste, "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": "one_tray_fifo",
		"prediction": problem.kpi}
	var submitted_at := s.region.net.time
	assert_eq(s.submit_a3(TRAY, a3), "")
	assert_eq(s.region.state[TRAY].check_at - submitted_at, SimCalendar.days(3), "a short Check for practice")
	assert_eq(s.wait_for_check(TRAY), "")
	assert_true(s.check(TRAY)["passed"])
	assert_eq(s.missions.status("training_thu"), "completed")
	assert_eq(_active_ids(s), ["training_fri"])
	# Friday: Act without standardising, then watch it fade.
	assert_false(s.act(TRAY, false).has("error"))
	assert_eq(s.missions.status("training_fri"), "completed")
	assert_false(s.in_training())
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "available", "the campaign opens")
	assert_true(s.xp() >= 250, "the five days' rewards and the practice score")
	var lapse := s.time_lapse(30)
	assert_false(lapse.has("error"))
	assert_eq([lapse["problem"], lapse["kpi"], lapse["phase_before"], lapse["phase_after"], lapse["faded"]],
		[TRAY, "lead_time", "resolved", "dormant", true], "not standardised: the fix fades")
	assert_true(lapse["before"].has("lead_time") and lapse["after"].has("lead_time"))
	assert_true(lapse["after"]["step"]["queue_hours"] >= 0.0)


func test_a_standardised_practice_fix_holds_through_the_time_lapse() -> void:
	var s := _training()
	s.skip_training()
	# Straight to Friday's choice on a checked practice problem.
	var st: ProblemState = s.region.state[TRAY]
	s.region.activate(TRAY)
	s.use_tool(INTAKE, "shadow")
	var problem: ProblemDef = s.region.problems[TRAY]
	var a3 := {"waste": problem.waste, "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": "tray_labels",
		"prediction": problem.kpi}
	assert_eq(s.submit_a3(TRAY, a3), "")
	s.wait_for_check(TRAY)
	assert_true(s.check(TRAY)["passed"], "the second countermeasure passes the Check too")
	s.act(TRAY, true)
	var lapse := s.time_lapse(30)
	assert_eq([lapse["phase_after"], lapse["faded"]], ["resolved", false], "standard work keeps the gain")
	assert_eq(st, s.region.state[TRAY])


func test_a_time_lapse_refuses_bad_input_without_spending_time() -> void:
	var s := _training()
	var before := s.region.net.time
	assert_eq(s.time_lapse(0), {"error": "bad_days"})
	assert_eq(s.time_lapse(GameSession.MAX_TIME_LAPSE_DAYS + 1), {"error": "bad_days"})
	assert_eq(s.time_lapse(5, "no_such_problem"), {"error": "unknown_problem"})
	assert_eq(s.region.net.time, before)
