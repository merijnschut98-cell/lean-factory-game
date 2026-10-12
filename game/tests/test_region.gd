extends TestCase
## The PDCA loop of one region over the live simulation.


func _region(budget: int = 50000) -> Region:
	return RulesFixture.region(budget)


func _clue_ids(clues: Array) -> Array:
	return clues.map(func(c: Clue) -> String: return c.id)


## Investigate custom_design like an expert: every key clue, walking upstream.
func _investigate(r: Region) -> void:
	r.use_tool("connections.design", "time_study")  # spots it; key clue depth 0
	r.use_tool("connections.design", "documents")  # depth 1
	r.ask("connections.intake", "walk")  # depth 1, upstream
	r.use_tool("connections.design", "data")  # depth 2


func _a3(r: Region, cm: String, evidence: Array = ["custom_design:0", "custom_design:2", "custom_design:4"]) -> Dictionary:
	return RulesFixture.a3(r, "custom_design", "overprocessing", cm, evidence, "throughput")


func test_activating_a_problem_hits_the_simulation() -> void:
	var r := _region()
	assert_true(r.activate("custom_design"))
	assert_eq(r.net.stream("connections").step("design").touch_minutes, 360)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.ACTIVE)
	assert_false(r.activate("custom_design"), "already active")


func test_at_most_three_problems_open() -> void:
	var defs := RulesFixture.problem_defs()
	for i in 3:
		var d: Dictionary = RulesFixture.problems()[1].duplicate(true)
		d["id"] = "extra_%d" % i
		defs.append(ProblemDef.from_dict(d))
	var r := Region.new(RulesFixture.net(), defs, RulesFixture.countermeasure_defs(), Profile.new())
	var activated := 0
	for p in defs:
		activated += 1 if r.activate(p.id) else 0
	assert_eq(activated, Region.MAX_OPEN)


func test_tools_spot_and_reveal_one_why_at_a_time() -> void:
	var r := _region()
	r.activate("custom_design")
	var first := r.use_tool("connections.design", "data")
	assert_eq(first["spotted"], ["custom_design"])
	assert_eq(_clue_ids(first["clues"]), [], "the depth-2 data clue waits for depths 0 and 1")
	var timed := r.use_tool("connections.design", "time_study")
	assert_eq(_clue_ids(timed["clues"]), ["custom_design:0"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "documents")["clues"]), ["custom_design:2"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "data")["clues"]), ["custom_design:4"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "data")["clues"]), [], "found once")


func test_some_clues_are_found_upstream() -> void:
	var r := _region()
	r.activate("custom_design")
	r.use_tool("connections.design", "time_study")
	assert_eq(_clue_ids(r.use_tool("connections.design", "conversation")["clues"]), [], "not at design")
	var reply := r.ask("connections.intake", "walk")
	assert_eq(reply["reply"], "clue")
	assert_eq(reply["clue"].id, "custom_design:3")


func test_quick_looks_miss_hidden_problems() -> void:
	var r := _region()
	r.activate("revision_backlog")
	var look := r.use_tool("connections.revision", "queue_count")
	assert_eq(look["spotted"], [])
	assert_true(look["hidden_signal"], "something here needs a deeper tool")
	assert_eq(r.use_tool("connections.revision", "data")["spotted"], ["revision_backlog"])


func test_blame_costs_a_teams_trust_and_respect_repairs_it() -> void:
	var r := _region()
	r.activate("custom_design")
	r.activate("incomplete_application")
	r.use_tool("connections.design", "time_study")
	assert_eq(r.ask("connections.design", "behind")["reply"], "blame")
	assert_eq(r.trust_of("connections.design"), -1)
	assert_true(r.state["custom_design"].blamed)
	assert_eq(r.ask("connections.design", "walk")["reply"], "guarded", "they stop sharing")
	assert_eq(r.ask("connections.intake", "walk")["reply"], "clue", "another team still talks")
	assert_eq(r.ask("connections.design", "ok")["reply"], "closed")
	r.ask("connections.design", "thanks")
	assert_eq(r.trust_of("connections.design"), 0)
	assert_ne(r.ask("connections.design", "walk")["reply"], "guarded")


func test_open_questions_without_a_clue_describe_the_work() -> void:
	var r := _region()
	r.activate("custom_design")
	# A rush of applications on top: design at ~180% load, so its queue grows
	# whatever the random draws (37–70 orders after 30 days over seeds 1–10).
	r.net.set_effects("event:rush", [NetFixture.effect("connections", "demand", 1.6)])
	r.net.advance_days(30)
	var reply := r.ask("connections.design", "obstacle")
	assert_eq(reply["reply"], "observation")
	assert_eq(reply["observation"]["kind"], "queue")
	assert_true(reply["observation"]["value"] > 10)


func test_the_a3_refuses_weak_plans() -> void:
	var r := _region(1000)
	r.activate("custom_design")
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "not_spotted")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs", [])), "evidence")
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs", ["custom_design:1"])), "evidence",
		"only facts you found count")
	var no_waste := _a3(r, "standard_designs")
	no_waste["waste"] = "laziness"
	assert_eq(r.submit_a3("custom_design", no_waste), "waste")
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "budget")


func test_an_expert_run_resolves_the_problem() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	var budget := r.profile.budget
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "")
	assert_eq(r.profile.budget, budget - 8000)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.DOING)
	r.advance_days(Region.CHECK_DAYS)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.CHECK_READY)
	var check := r.check("custom_design")
	assert_true(check["passed"])
	assert_true(check["cause_correct"] and check["waste_right"])
	assert_true(check["after"]["capacity"] > check["before"]["capacity"])
	var score := r.act("custom_design", true)
	assert_true(score["total"] >= 22, "score %d %s" % [score["total"], score["notes"]])
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)
	assert_true(r.profile.xp > 0)
	assert_false(r.net.effects().has("problem:custom_design"), "the problem is gone")
	assert_true(r.net.effects().has("cm:custom_design"), "the improvement stays")


func test_a_mismatched_countermeasure_fails_check() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "poka_yoke_form")), "")
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check("custom_design")
	assert_false(check["passed"])
	assert_eq(check["lesson"], "mismatch")
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.SPOTTED, "back to the gemba")
	assert_eq(r.state["custom_design"].failed_checks, 1)
	assert_false(r.net.effects().has("cm:custom_design"))
	assert_eq(r.net.stream("connections").step("design").touch_minutes, 360, "the problem is back at full strength")


func test_another_countermeasure_also_works_less_well() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "delegated_approval"))
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("custom_design")["passed"], "a different, smaller improvement is still an improvement")
	assert_true(r.act("custom_design", true)["countermeasure"] >= 4)


func test_improvement_work_takes_team_hours_during_the_experiment() -> void:
	var r := _region()
	var prep := r.net.pools["prep"]
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	# 40 hours over two weeks of a team of 2 × 40 hours a week.
	assert_near(prep.availability, 1.0 - 40.0 / (2.0 * 80.0), 1e-9)
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	assert_eq(prep.availability, 1.0, "back to daily work after the experiment")


func test_an_unstandardised_fix_comes_back() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", false)
	r.advance_days(29)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)
	r.advance_days(2)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.ACTIVE, "Sustain is the hardest S")
	assert_true(r.net.effects().has("problem:custom_design"))
	assert_false(r.net.effects().has("cm:custom_design"))
	assert_true(r.drain_events().any(func(e: Dictionary) -> bool: return e["type"] == "recurred"))


func test_a_standardised_fix_stays() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", true)
	r.advance_days(60)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)
