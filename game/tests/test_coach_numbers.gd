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


## Ruud's words for a KPI now (the problem's own by default), from content
## (coach.numbers.kpi_now), up to the number.
func _kpi_now(s: GameSession, kpi := "") -> String:
	var clause: String = s.missions.coach["numbers"]["kpi_now"][kpi if kpi != "" else s.region.problems[PROBLEM].kpi]
	return clause.get_slice("{value}", 0)


func _questions(s: GameSession, n: int) -> Array:
	var out := []
	while out.size() < n:
		var reply := s.ask_coach()
		if reply["kind"] == "question":
			out.append(reply["text"])
	return out


func test_the_coach_first_asks_about_the_stream_s_number_as_it_is_now() -> void:
	var s := _accepted()
	var first: String = s.ask_coach()["text"]
	var headline := _kpi_now(s, CoachNumbers.headline_kpi(s.region.problems[PROBLEM]))
	assert_true(first.begins_with(headline), "the stream's number first: %s" % first)
	assert_true(first.ends_with(s.missions.coach["numbers"]["go_see"]))
	assert_true(RegEx.create_from_string("\\d").search(first) != null, "with the number in it")
	assert_false(s.ask_coach()["text"].begins_with(headline), "once a stage, then his other questions")


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


## Review S3 #3: before the A3 Ruud never names the problem's own KPI (the prediction is the
## player's to find); he reads the stream's headline number, its end-to-end lead time (or its
## on-time share when the lead time is the problem's KPI). At reflect, after the prediction,
## he reads the problem's own KPI.
func test_before_the_a3_the_coach_reads_the_stream_not_the_problem_s_kpi() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var numbers: Dictionary = s.missions.coach["numbers"]
	var read := 0
	for m: MissionDef in s.missions.defs.values():
		var p: ProblemDef = s.region.problems.get(m.goal_problem)
		if m.kind != "main" or p == null:
			continue
		var own := str(numbers["kpi_now"][p.kpi]).get_slice("{value}", 0)
		var headline := "on_time" if p.kpi == "lead_time" else "lead_time"
		var line := CoachNumbers.question(s.region, m, "go_see", {}, s.missions.coach)
		if line.is_empty():
			continue   # nothing finished on the stream yet
		read += 1
		assert_false(line.contains(own), "%s: go_see names its own KPI: %s" % [m.id, line])
		assert_true(line.begins_with(str(numbers["kpi_now"][headline]).get_slice("{value}", 0)), "%s: %s" % [m.id, line])
		var reflect := CoachNumbers.question(s.region, m, "reflect", {}, s.missions.coach)
		assert_true(reflect.is_empty() or reflect.begins_with(own), "%s: at reflect its own KPI: %s" % [m.id, reflect])
	assert_true(read >= 3, "the stream's number read for %d main missions" % read)
