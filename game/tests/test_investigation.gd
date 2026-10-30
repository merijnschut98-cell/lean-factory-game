extends TestCase
## Gemba tools, clues with depth, conversations, the cause bank.


func _custom_design() -> ProblemDef:
	return RulesFixture.problem_defs()[0]


func test_definitions_load() -> void:
	for p in RulesFixture.problem_defs():
		assert_eq(p.error, "", p.id)
	for c in RulesFixture.countermeasure_defs():
		assert_eq(c.error, "", c.id)
	var p := _custom_design()
	assert_eq(p.step, "connections.design")
	assert_eq(p.stream_id(), "connections")
	assert_eq(p.clues.size(), 5)
	assert_eq(p.clues[0].id, "custom_design:0")
	assert_eq(p.clues[3].at, "connections.intake", "a clue can sit upstream")
	assert_eq(p.clues[0].at, "connections.design", "by default where the problem shows")


func test_bad_definitions_are_reported() -> void:
	var d: Dictionary = RulesFixture.problems()[0]
	d.erase("root_cause")
	assert_true("root_cause" in ProblemDef.from_dict(d).error)
	d = RulesFixture.problems()[0]
	d["waste"] = "laziness"
	assert_true("waste" in ProblemDef.from_dict(d).error)
	d = RulesFixture.problems()[0]
	d["clues"][0]["tool"] = "crystal_ball"
	assert_true("tool" in ProblemDef.from_dict(d).error)
	var c: Dictionary = RulesFixture.countermeasures()[0]
	c.erase("multipliers")
	assert_true("multipliers" in CountermeasureDef.from_dict(c).error)
	c = RulesFixture.countermeasures()[0]
	c["unlocks"] = "secret_door"
	assert_true("'unlocks' must be one of" in CountermeasureDef.from_dict(c).error)
	c["unlocks"] = "kpi_board"
	assert_eq(CountermeasureDef.from_dict(c).error, "")


func test_deeper_clues_need_the_shallower_key_clue() -> void:
	var p := _custom_design()
	var found := {}
	assert_true(Investigation.revealable(p.clues[0], p, found), "depth 0 is always open")
	assert_false(Investigation.revealable(p.clues[2], p, found), "depth 1 waits for a depth-0 key clue")
	found[p.clues[1].id] = true
	assert_false(Investigation.revealable(p.clues[2], p, found), "a red herring opens nothing")
	found[p.clues[0].id] = true
	assert_true(Investigation.revealable(p.clues[2], p, found))
	assert_false(Investigation.revealable(p.clues[4], p, found), "depth 2 waits for depth 1")
	assert_false(Investigation.revealable(p.clues[0], p, found), "already found")


func test_cause_options_are_stable_and_contain_the_real_cause_once() -> void:
	var all := RulesFixture.problem_defs()
	var p := all[0]
	var a := Investigation.cause_options(p, all)
	assert_eq(a["options"].size(), 5)
	assert_eq(a["options"].count(p.root_cause), 1)
	assert_eq(a["options"][a["correct"]], p.root_cause)
	assert_eq(Investigation.cause_options(p, all), a, "same problem, same order")
	assert_true("The preparers are too slow" in a["options"], "plausible causes are in the bank")
	assert_true(all[1].root_cause in a["options"], "and other problems' real causes")


func test_tools_and_questions() -> void:
	for tool: String in Investigation.TOOLS:
		assert_true(Investigation.TOOLS[tool]["minutes"] > 0, tool)
	assert_true(Investigation.TOOLS["data"]["deep"])
	assert_false(Investigation.TOOLS["queue_count"]["deep"])
	var kinds := {}
	for q: String in Investigation.QUESTIONS:
		kinds[Investigation.QUESTIONS[q]] = true
	assert_eq(kinds.keys().size(), 4, "open, closed, blame, repair")
	assert_eq(Investigation.WASTES.size(), 8, "TIMWOODS")
