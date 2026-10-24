extends TestCase
## The coach reads the numbers (phase-2 design §3.6) on the real content: Ruud's questions
## name the main mission's KPI as it is now, and during an experiment he asks the Kata five
## in order (Rother: target, actual condition, obstacles, next step, when we go and see).
## Main quest only; questions, rarely an answer.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "connections.design"


func _accepted() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	assert_eq(s.accept(MISSION), "")
	return s


## Ruud's words for the KPI now, from content (coach.numbers.kpi_now), with the number in.
func _kpi_now(s: GameSession) -> String:
	var clause: String = s.missions.coach["numbers"]["kpi_now"][s.region.problems[PROBLEM].kpi]
	return clause.get_slice("{value}", 0)


func _questions(s: GameSession, n: int) -> Array:
	var out := []
	while out.size() < n:
		var reply := s.ask_coach()
		if reply["kind"] == "question":
			out.append(reply["text"])
	return out


func test_the_coach_first_asks_about_the_kpi_as_it_is_now() -> void:
	var s := _accepted()
	var first: String = s.ask_coach()["text"]
	assert_true(first.begins_with(_kpi_now(s)), "the number first: %s" % first)
	assert_true(first.ends_with(s.missions.coach["numbers"]["go_see"]))
	assert_true(RegEx.create_from_string("\\d").search(first) != null, "with the number in it")
	assert_false(s.ask_coach()["text"].begins_with(_kpi_now(s)), "once a stage, then his other questions")


func test_during_an_experiment_the_kata_five_come_in_order() -> void:
	var s := _accepted()
	for tool in ["time_study", "documents", "data"]:
		s.use_tool(DESIGN, tool)
	s.ask("connections.intake", "walk")
	assert_true(MissionTalks.win(s, MISSION))
	s.ask_coach()  # after a hard talk of the main mission, his one question about it comes first
	var problem: ProblemDef = s.region.problems[PROBLEM]
	var a3 := {"waste": "overprocessing", "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id), "cm": "standard_designs",
		"prediction": "throughput"}
	assert_eq(s.submit_a3(PROBLEM, a3), "")
	var kata: Array = s.missions.coach["kata"]
	assert_eq(kata.size(), 5)
	var asked := _questions(s, 5)
	assert_true(asked[0].begins_with(_kpi_now(s)) and asked[0].ends_with(kata[0]), "the target, read against the number")
	assert_eq(asked.slice(1), kata.slice(1), "then the actual condition, obstacles, next step, when we go and see")
	assert_false(_questions(s, 1)[0] in kata, "the five once an experiment")


func test_a_mission_without_a_problem_gets_no_number() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var clauses: Dictionary = s.missions.coach["numbers"]["kpi_now"]
	assert_eq(CoachNumbers.kpi_now(s.region, s.missions.defs["walk_connections"], clauses), "", "a walk has no KPI to read")
	assert_ne(CoachNumbers.kpi_now(s.region, s.missions.defs[MISSION], clauses), "")
