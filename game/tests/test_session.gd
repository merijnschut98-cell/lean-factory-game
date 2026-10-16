extends TestCase
## GameSession: the one facade the 3D world and the UI call. Real content,
## real network; the mission "Maatwerk voor standaardwerk" is played end to end.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "connections.design"
const INTAKE := "connections.intake"


## A returning player's game: the training week skipped, the campaign open.
func _campaign() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, false)


func _accepted() -> GameSession:
	var s := _campaign()
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
	var s := _campaign()
	assert_eq(s.error, "")
	assert_eq(s.clock_text(), "ma 12 okt, 08:30")
	assert_eq(s.budget(), 50000)
	assert_eq(s.xp(), 0)
	assert_eq(s.belt(), "white")
	assert_eq(s.reputation(), Reputation.START)
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
	var s := _campaign()
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
	var s := _campaign()
	assert_eq(s.accept("no_such_mission"), "unknown")
	assert_eq(s.accept("fix_incomplete_application"), "locked", "it opens after the first bottleneck is fixed")
	assert_eq(s.accept(MISSION), "")
	assert_eq(s.accept(MISSION), "not_available", "it is already taken")


## A player can drop a mission; its problem goes back to sleep (every open
## problem belongs to a mission), unless an experiment is running.
func test_a_mission_can_be_abandoned_through_the_facade() -> void:
	var s := _accepted()
	assert_eq(s.abandon("no_such_mission"), "not_active")
	assert_eq(s.abandon(MISSION), "")
	assert_eq(s.phase_of(PROBLEM), "dormant")
	assert_eq(s.abandon(MISSION), "not_active")
	assert_eq(s.accept(MISSION), "", "it can be taken on again")
	_investigate(s)
	assert_eq(s.submit_a3(PROBLEM, _a3(s, "standard_designs")), "")
	assert_eq(s.abandon(MISSION), "experiment_running")


func test_the_a3_errors_pass_through() -> void:
	var s := _campaign()
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
	var s := _campaign()
	assert_eq(s.ask_coach()["kind"], "no_main")
	s.accept(MISSION)
	var first := s.ask_coach()
	assert_eq(first["kind"], "question")
	assert_eq(first["stage"], "go_see")
	assert_true(first["text"] in s.catalog.coach["stages"]["go_see"], first["text"])
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
	assert_true(s.knows("forecast_positive:throughput"), "the Check's forecast for the predicted KPI came out positive")
	assert_false(s.knows("forecast_positive:lead_time"), "only the KPI the A3 predicted")
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
	assert_true(s.knows("chose:custom_design:standard_designs"), "the path is remembered")
	assert_true(s.knows("standardised:custom_design"))
	assert_eq(s.mission_debrief(MISSION), s.missions.defs[MISSION].debrief)
	assert_eq(s.mission_briefing(MISSION), s.missions.defs[MISSION].briefing)
	assert_eq(s.unprepared_countermeasures(), [], "nothing in today's content needs a preparation")
	assert_eq(s.year_cost("standard_designs"), Stewardship.year_cost(s.region.countermeasures["standard_designs"]))
	assert_eq(s.year_cost("ghost"), -1)

	var types := s.drain_events().map(func(e: Dictionary) -> String: return e["type"])
	for expected in ["accepted", "check_ready", "completed"]:
		assert_true(expected in types, "%s in %s" % [expected, types])
	assert_eq(s.drain_events(), [], "events are delivered once")


## The second office mission, as an expert: the intake's form lets incomplete
## applications through; poka-yoke at the source, measured on the intake's
## capacity.
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
	assert_true(checked["passed"], "the fitting countermeasure passes the Check: %s" % [checked["forecast"]["gains"]])
	assert_true(checked["forecast"]["gains"]["capacity"] > 0.1, "less rework frees intake capacity")
	assert_false(s.act(problem_id, true).has("error"))
	assert_eq(s.missions.status(second), "completed")
	assert_true(s.xp() > xp_before)


# ── The training week (Inwerkweek) ──────────────────────────────────────────

const TRAY := "training_tray"


func _training() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	assert_eq(s.error, "")
	return s


func _active_ids(s: GameSession) -> Array:
	return s.active_missions().map(func(m: MissionDef) -> String: return m.id)


func test_without_training_the_week_counts_as_skipped() -> void:
	var s := _campaign()
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


## Follow the dossier: the first main mission is a real action (audit M1):
## count what lies at Intake and Werkvoorbereiding.
func test_after_the_week_the_dossier_is_followed_by_counting_its_queues() -> void:
	var s := _training()
	s.missions.skip_training()  # the week's days done, as the rules see it
	s.accept(GameSession.STORY_MISSION)
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "active", "no longer done for the player")
	s.use_tool(INTAKE, "queue_count")
	s.use_tool(DESIGN, "queue_count")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "completed")
	assert_eq(s.missions.status(MISSION), "available")


func test_skipping_training_opens_the_campaign_without_rewards() -> void:
	var s := _training()
	s.use_tool(INTAKE, "shadow")
	assert_eq(s.skip_training(), "")
	assert_false(s.in_training())
	assert_eq(s.xp(), 0, "no rewards for skipped days")
	assert_eq(s.budget(), 50000)
	assert_eq(s.missions.status("training_thu"), "completed")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "completed", "the story's walk, as without the week")
	assert_eq(s.missions.status(MISSION), "available", "a returning player starts the campaign")
	assert_eq(s.xp(), 0, "the story's walk is not rewarded")
	assert_eq(s.active_missions().size(), 0)
	assert_eq(s.skip_training(), "not_in_training")


## The whole week as a player would play it: walk, look, count, a practice A3
## with a short Check at the bottleneck Wednesday found, and the Act with the
## month-ahead forecast of the fade.
func test_the_training_week_is_played_end_to_end() -> void:
	var s := _training()
	# Monday: visit the two teams.
	s.use_tool(INTAKE, "shadow")
	assert_eq(s.missions.status("training_mon"), "active")
	assert_false(s.ask(DESIGN, "walk").has("error"))
	assert_eq(s.missions.status("training_mon"), "completed")
	assert_eq(_active_ids(s), ["training_tue"])
	assert_eq(s.clock_text(), "di 13 okt, 08:30", "each day of the week starts on its own morning")
	# Tuesday: two tools at Werkvoorbereiding.
	s.use_tool(DESIGN, "time_study")
	s.use_tool(DESIGN, "time_study")
	assert_eq(s.missions.status("training_tue"), "active", "two different tools")
	s.use_tool(DESIGN, "documents")
	assert_eq(_active_ids(s), ["training_wed"])
	# Wednesday: count the queues at two steps (the week's course makes design the bottleneck).
	assert_true(s.clock_text().begins_with("wo 14 okt"))
	s.drain_events()
	var counted := [s.use_tool(INTAKE, "queue_count")["queue"]]
	counted.append(s.use_tool(DESIGN, "queue_count")["queue"])
	assert_eq(_active_ids(s), ["training_thu"])
	var wed: Array = s.drain_events().filter(func(e: Dictionary) -> bool: return e.get("mission") == "training_wed")
	var queues: Dictionary = wed[0]["queues"]
	assert_eq(queues[DESIGN], counted[1], "the lesson reports what was counted")
	assert_true(queues[DESIGN]["days"] > 2.0 * queues[INTAKE]["days"] and queues[DESIGN]["count"] > 0,
		"the training setup makes design clearly the longer wait")
	assert_true(s.clock_text().begins_with("do 15 okt"))
	assert_eq(s.phase_of(TRAY), "active", "the practice problem arrives through Thursday's mission")
	# Thursday: the practice A3 at the bottleneck Wednesday found, and a three-day Check.
	assert_eq(s.region.problems[TRAY].step, DESIGN, "the practice problem sits where the work waits")
	assert_true(s.region.net.pools["work_prep"].availability < 0.5, "the course lasts the whole week")
	s.use_tool(DESIGN, "shadow")
	s.use_tool(DESIGN, "time_study")
	s.ask(DESIGN, "walk")
	var problem: ProblemDef = s.region.problems[TRAY]
	var keys := problem.clues.filter(func(c: Clue) -> bool: return c.key)
	assert_eq(s.clues_found(TRAY).size(), keys.size(), "every key clue found at Werkvoorbereiding")
	assert_eq(s.ask_coach()["stage"], "understand")
	var a3 := {"waste": problem.waste, "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": "one_tray_fifo",
		"prediction": problem.kpi}
	var submitted_at := s.region.net.time
	assert_eq(s.submit_a3(TRAY, a3), "")
	assert_eq(s.region.state[TRAY].check_at - submitted_at, SimCalendar.days(3), "a short Check for practice")
	assert_eq(s.wait_for_check(TRAY), "")
	var checked := s.check(TRAY)
	assert_true(checked["passed"])
	assert_true(checked["before"]["at_constraint"] and not checked["not_constraint"],
		"the Check agrees: Thursday worked on the bottleneck")
	assert_true(checked["after"][problem.kpi] > checked["before"][problem.kpi],
		"the leading indicator predicted shows the fix within three days")
	assert_eq(s.missions.status("training_thu"), "completed")
	assert_eq(_active_ids(s), ["training_fri"])
	# Friday: the three-day Check ended in the weekend; the day starts on the next working morning.
	assert_eq(s.clock_text(), "ma 19 okt, 08:30")
	assert_eq(s.training_weekday("training_fri"), "ma", "the day is named by the day it started")
	assert_eq(s.training_weekday("training_thu"), "do")
	assert_true(s.region.net.pools["work_prep"].availability < 0.5, "the course still runs: the week is not over")
	assert_false(s.act(TRAY, false).has("error"))
	assert_eq(s.missions.status("training_fri"), "completed")
	assert_false(s.in_training())
	assert_eq(s.region.net.pools["work_prep"].availability, _campaign().region.net.pools["work_prep"].availability,
		"the week is over: the course with it")
	assert_eq(s.missions.status(GameSession.STORY_MISSION), "available", "the campaign opens with a real walk")
	assert_eq(s.missions.status(MISSION), "locked", "the first problem waits for it")
	assert_true(s.xp() >= 250, "the five days' rewards and the practice score")
	var time_before := s.region.net.time
	var forecast := s.fade_forecast(30)
	assert_false(forecast.has("error"))
	assert_eq([forecast["problem"], forecast["kpi"], forecast["place"], forecast["standardised"]],
		[TRAY, "capacity", DESIGN, false])
	assert_true(forecast["faded"]["capacity"] < forecast["held"]["capacity"], "without a standard the month is worse")
	assert_true(forecast["held"]["queue"].has("count") and forecast["faded"]["queue"].has("days"))
	assert_eq(s.region.net.time, time_before, "a forecast does not move the game on")
	assert_eq(s.phase_of(TRAY), "resolved")
	assert_eq(s.missions.status("training_fri"), "completed", "the practice problem is retired: Friday does not reopen")
	assert_eq(s.accept("training_fri"), "not_available")
	assert_false(s.drain_events().any(func(e: Dictionary) -> bool: return e["type"] == "reopened"))
	assert_eq(s.region.maturity(), 1, "practice does not raise the region's maturity")


## The practice problem resolved on the given seed, standardised or not.
func _practice_acted(seed_value: int, cm: String, standardise: bool) -> GameSession:
	var s := GameSession.new_game(seed_value, Catalog.DATA_DIR, false)
	# Every open problem belongs to a mission: a plain side mission holds the
	# practice problem here (the training days would shorten its Check).
	s.missions.defs["hold_tray"] = MissionDef.from_dict({"id": "hold_tray", "name": "hold", "kind": "side", "tier": 1,
		"goal": {"type": "solve", "problem": TRAY}, "briefing": "b", "debrief": "d"})
	assert_eq(s.accept("hold_tray"), "")
	s.use_tool(DESIGN, "shadow")
	var problem: ProblemDef = s.region.problems[TRAY]
	var a3 := {"waste": problem.waste, "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": cm, "prediction": problem.kpi}
	assert_eq(s.submit_a3(TRAY, a3), "")
	s.wait_for_check(TRAY)
	assert_true(s.check(TRAY)["passed"], "%s passes the practice Check" % cm)
	assert_false(s.act(TRAY, standardise).has("error"))
	return s


## The Friday lesson in numbers: the month without a standard is measurably
## worse on the practice KPI than the month with one, on every seed, and the
## forecast runs on copies: the region's own network is untouched.
func test_the_fade_forecast_shows_the_fade_in_the_numbers() -> void:
	for seed_value in [11, 12, 13]:
		var s := _practice_acted(seed_value, "one_tray_fifo", false)
		var before := NetworkState.capture(s.region.net)
		var events_before := s.region.events.size()
		var forecast := s.fade_forecast(30)
		assert_false(forecast.has("error"), "seed %d" % seed_value)
		var kpi: String = forecast["kpi"]
		var held: float = forecast["held"][kpi]
		var faded: float = forecast["faded"][kpi]
		assert_true(faded < held * 0.95, "seed %d: without a standard %s falls (%.1f vs %.1f)" % [seed_value, kpi, faded, held])
		assert_true(forecast["faded"]["queue"]["days"] >= forecast["held"]["queue"]["days"],
			"seed %d: the work waits at least as long at Werkvoorbereiding" % seed_value)
		assert_eq(forecast["fade_days"], s.region.countermeasures["one_tray_fifo"].decay_days, "the fix fades after its decay")
		assert_eq(NetworkState.capture(s.region.net), before, "seed %d: the region's network is untouched" % seed_value)
		assert_eq(s.region.events.size(), events_before)
		assert_eq(s.phase_of(TRAY), "resolved")


func test_a_standardised_practice_fix_still_gets_its_counterfactual() -> void:
	var s := _practice_acted(11, "tray_labels", true)
	var forecast := s.fade_forecast(30)
	assert_true(forecast["standardised"], "the player's Act is reported")
	assert_true(forecast["faded"]["capacity"] < forecast["held"]["capacity"], "what the standard saves is shown too")
	# Standard work slows the wear in the game itself (but even a standard erodes, Sustain).
	assert_true(forecast["recur_days"] > s.region.countermeasures["tray_labels"].decay_days * 2.0)
	assert_eq(s.sustain_of(TRAY)["mechanisms"], ["standard_work"])


func test_a_fade_forecast_refuses_bad_input_without_spending_time() -> void:
	var s := _training()
	var before := s.region.net.time
	assert_eq(s.fade_forecast(0), {"error": "bad_days"})
	assert_eq(s.fade_forecast(GameSession.MAX_FORECAST_DAYS + 1), {"error": "bad_days"})
	assert_eq(s.fade_forecast(5, "no_such_problem"), {"error": "unknown_problem"})
	assert_eq(s.fade_forecast(5), {"error": "not_resolved"}, "only after the Act")
	assert_eq(s.region.net.time, before)


func test_a_new_game_starts_with_the_training_week_by_default() -> void:
	var s := GameSession.new_game(11)
	assert_true(s.in_training())
	assert_eq(_active_ids(s), ["training_mon"])


func test_the_check_takes_the_missions_check_days() -> void:
	var s := _campaign()
	assert_eq(s.check_days(PROBLEM), Region.CHECK_DAYS, "the real Check")
	var t := _training()
	assert_eq(t.check_days(TRAY), Region.CHECK_DAYS, "no training day shortens it yet")
	t.missions.done_once["training_wed"] = true
	t.missions.skip_training()
	t.missions.progress.erase("training_thu")
	t.missions.done_once.erase("training_thu")
	assert_eq(t.accept("training_thu"), "")
	assert_eq(t.check_days(TRAY), 3, "Thursday's short practice Check")


func test_training_days_are_numbered_monday_to_friday() -> void:
	var s := _training()
	var days := ["training_mon", "training_tue", "training_wed", "training_thu", "training_fri"].map(
		func(id: String) -> int: return s.training_day(id))
	assert_eq(days, [0, 1, 2, 3, 4])
	assert_eq(s.training_day(MISSION), -1, "not a training day")
	assert_true(s.is_practice(TRAY))
	assert_false(s.is_practice(PROBLEM))


# ── Sustain and drift (CLAUDE.md §2) ────────────────────────────────────────

## Stagnation counts from the campaign's start, not during the training week.
func test_drift_starts_with_the_campaign() -> void:
	assert_false(_training().drift()["started"], "the training week is practice")
	var s := _campaign()
	assert_eq(s.drift(), {"level": 0.0, "stagnant_days": 0.0, "grace_days": Sustain.DRIFT_GRACE_DAYS, "started": true})
	s.region.advance_days(Sustain.DRIFT_GRACE_DAYS + 73)
	assert_near(s.drift()["level"], 0.2, 0.01, "standing still sets the region back")


## A gemba audit is a leader routine: no mission needed, an hour at the place.
func test_an_audit_takes_an_hour_at_a_place() -> void:
	var s := _campaign()
	var before := s.region.net.time
	assert_eq(s.audit(DESIGN), {"refreshed": [], "no_standard": []}, "nothing resolved there yet")
	assert_eq(s.region.net.time - before, Sustain.AUDIT_MINUTES)
	assert_eq(s.audit("nowhere.step"), {"error": "unknown_place"})
	assert_eq(s.sustain_of(PROBLEM), {}, "only a resolved fix is held")


func test_a_held_fix_reports_how_it_is_sustained() -> void:
	var s := _practice_acted(11, "one_tray_fifo", false)
	var held := s.sustain_of(TRAY)
	assert_eq([held["strength"], held["mechanisms"], held["standardised"], held["health"]], [0.0, [], false, 1.0])
	assert_near(held["days_to_recur"], s.region.countermeasures["one_tray_fifo"].decay_days, 0.01,
		"no habits: it lasts its decay_days, the Friday lesson's number")
	assert_eq(s.fade_forecast(30)["recur_days"], held["days_to_recur"])


## A routine is planned at a place once and holds the standardised fixes there.
func test_a_routine_is_planned_and_stopped_at_a_place() -> void:
	var s := _practice_acted(11, "tray_labels", true)
	assert_eq(s.plan_routine(DESIGN), "")
	assert_eq(s.plan_routine(DESIGN), "planned")
	assert_eq(s.routines(), [DESIGN])
	var held := s.sustain_of(TRAY)
	assert_true(held["routine"])
	assert_eq(held["days_to_recur"], INF, "it does not wear while the routine runs")
	assert_eq(s.stop_routine(DESIGN), "")
	assert_eq(s.stop_routine(DESIGN), "not_planned")
	assert_eq(s.plan_routine("nowhere.step"), "unknown_place")


## Standardising after the Act: the story remembers it (a check-in can now
## come, the debrief no longer reads "not standardised").
func test_a_fix_is_standardised_after_the_act() -> void:
	var s := _accepted()
	_investigate(s)
	assert_eq(s.submit_a3(PROBLEM, _a3(s, "standard_designs")), "")
	assert_eq(s.wait_for_check(PROBLEM), "")
	assert_true(s.check(PROBLEM)["passed"])
	assert_false(s.act(PROBLEM, false).has("error"))
	assert_false(s.knows("standardised:custom_design"))
	var minutes := s.region.net.time
	assert_eq(s.standardise(PROBLEM), "")
	assert_true(s.knows("standardised:custom_design"))
	assert_eq(s.region.net.time - minutes, Sustain.AUDIT_MINUTES, "writing the standard takes an hour at the place")
	assert_eq(s.standardise(PROBLEM), "standardised")
	assert_eq(s.standardise("ghost"), "unknown_problem")


## Frank's third route (drie winters S13, tier-1 content audit C5): a
## quarterly review whose forecast beats the habit records
## forecast_positive:kpi_board; the habit itself forecasts nothing.
func test_a_positive_kpi_review_forecast_is_a_fact() -> void:
	var s := _campaign()
	assert_eq(s.kpi_review({}), {"error": "locked"})
	s.region.board.unlock(s.region.net.time)
	var habit := {"intake": ["intake_utilisation", "intake_output"], "work_prep": ["work_prep_utilisation", "work_prep_output"],
		"planners": ["planners_hours", "planners_on_time"], "contact_centre": ["contact_centre_handle_time", "contact_centre_reachable"]}
	assert_eq(s.kpi_review(habit)["paid"], 0.0)
	assert_false(s.knows("forecast_positive:kpi_board"))
	s.region.advance_days(KpiBoard.REVIEW_DAYS)
	var flow := habit.merged({"intake": ["intake_lead_time", "intake_complete"],
		"work_prep": ["work_prep_lead_time", "work_prep_ftr"]}, true)
	var result := s.kpi_review(flow)
	assert_eq(result["error"], "")
	assert_true(result["paid"] > 0.0, "lead time and a complete handover beat the habit: %.4f" % result["improvement"])
	assert_true(s.knows("forecast_positive:kpi_board"))
