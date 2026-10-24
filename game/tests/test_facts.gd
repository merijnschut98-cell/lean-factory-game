extends TestCase
## Path dependence (Merijn, 2026-10-15; catalogue §2.15): facts record what
## the player did and chose; missions and countermeasures need them; a
## missing preparation locks an option, shown as "niet voorbereid" with a
## hint. And the mission schema's story fields (catalogue C1).


func _log(cms: Array = RulesFixture.countermeasures(), extra: Array = []) -> Missions:
	var defs: Array[MissionDef] = []
	for d: Dictionary in RulesFixture.missions() + extra:
		defs.append(MissionDef.from_dict(d))
	var r := RulesFixture.region(50000, 5, RulesFixture.problems(), cms)
	return Missions.new(r, defs, RulesFixture.coach())


func _walk_connections(log: Missions) -> void:
	log.accept("walk_connections")
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()


## A mission in the fixture's shape, with extra fields.
func _mission(id: String, kind: String, goal: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": kind, "tier": 1, "goal": goal, "briefing": "briefing " + id,
		"debrief": "debrief " + id, "rewards": {"xp": 100}}
	d.merge(extra, true)
	return d


func _resolve(log: Missions, problem_id: String, cm: String, standardised: bool = true, cause_correct: bool = true) -> void:
	var st: ProblemState = log.region.state[problem_id]
	st.phase = ProblemState.Phase.RESOLVED
	st.a3 = {"cm": cm}
	st.standardised = standardised
	st.cause_correct = cause_correct
	log.update()


func test_needs_all_any_none_and_measures() -> void:
	var known := {"done:a": true, "flag:b": true}
	var knows := func(atom: String) -> bool: return known.has(atom)
	assert_true(Facts.met({}, knows), "no needs")
	assert_true(Facts.met({"all": ["done:a", "flag:b"]}, knows))
	assert_false(Facts.met({"all": ["done:a", "done:c"]}, knows))
	assert_true(Facts.met({"any": ["done:c", "flag:b"]}, knows))
	assert_false(Facts.met({"any": ["done:c"]}, knows))
	assert_false(Facts.met({"none": ["flag:b"]}, knows))
	assert_eq(Facts.measure("maturity>=3"), ["maturity", 3])
	assert_eq(Facts.measure("done:a"), [])


func test_the_mission_schema_reads_story_fork_gates_and_flags() -> void:
	var m := MissionDef.from_dict(_mission("x", "main", {"type": "walk", "stream": "meters"}, {
		"act": 1, "chapter": "De stapel", "arc": "henk", "fork": {"group": "g", "role": "bottleneck"},
		"debrief_first": "eerst", "reopen": "terug", "sets_flags": ["flag:seen"],
		"requires": {"missions": ["a"], "maturity": 2, "reputation": 40, "trust": {"crew": 1}, "any_of": ["b", "c"],
			"facts": {"all": ["done:a"]}}}))
	assert_eq(m.error, "")
	assert_eq([m.act, m.chapter, m.arc, m.fork_group, m.fork_role, m.debrief_first, m.reopen_text],
		[1, "De stapel", "henk", "g", "bottleneck", "eerst", "terug"])
	assert_eq([m.requires_maturity, m.requires_reputation, m.requires_trust, m.requires_any_of, m.requires_facts],
		[2, 40, {"crew": 1}, PackedStringArray(["b", "c"]), {"all": ["done:a"]}])
	assert_eq(m.sets_flags, PackedStringArray(["flag:seen"]))
	var plain := MissionDef.from_dict(_mission("y", "side", {"type": "walk", "stream": "meters"}))
	assert_eq([plain.act, plain.requires_maturity, plain.fork_group], [-1, 1, ""], "defaults: no act, any maturity")


func test_missions_open_on_maturity_reputation_trust_any_of_and_facts() -> void:
	var walk := {"type": "walk", "stream": "meters"}
	var log := _log(RulesFixture.countermeasures(), [
		_mission("by_reputation", "side", walk, {"requires": {"reputation": 40}}),
		_mission("by_trust", "side", walk, {"requires": {"trust": {"crew": 1}}}),
		_mission("by_any", "side", walk, {"requires": {"any_of": ["fix_design", "fix_revision"]}}),
		_mission("by_maturity", "side", walk, {"requires": {"maturity": 2}}),
		_mission("by_facts", "side", walk, {"requires": {"facts": {"all": ["chose:custom_design:standard_designs"],
			"none": ["poor_fix:custom_design"]}}}),
	])
	var gated := ["by_reputation", "by_trust", "by_any", "by_maturity", "by_facts"]
	for id in gated:
		assert_eq(log.status(id), "locked", id)
	log.region.earn_reputation(10, "test")
	log.region.change_trust("crew", 1)
	_walk_connections(log)
	log.accept("fix_revision")
	_resolve(log, "revision_backlog", "revision_at_source")
	log.accept("fix_design")
	_resolve(log, "custom_design", "standard_designs")
	log.accept("look_at_intake")
	log.region.state["incomplete_application"].phase = ProblemState.Phase.RESOLVED  # 3 of 3 tier-1 problems
	for id in gated:
		assert_eq(log.status(id), "available", id)


## Facts the rules derive: done and failed missions, the fix the Act chose
## (replaced by a later one), whether it was standardised, and a poor fix:
## a countermeasure fitting 0.2 or more below the best, or a wrong root cause.
func test_derived_facts_follow_play() -> void:
	var log := _log()
	_walk_connections(log)
	assert_true(log.knows("done:walk_connections"))
	log.region.advance_days(11)
	log.update()
	assert_true(log.knows("failed:henk"))
	log.accept("fix_design")
	_resolve(log, "custom_design", "delegated_approval", false)
	assert_true(log.knows("chose:custom_design:delegated_approval"))
	assert_false(log.knows("standardised:custom_design"))
	assert_true(log.knows("poor_fix:custom_design"), "0.6 against a best fit of 1.0")
	log.region.state["custom_design"] = ProblemState.new("custom_design")  # the fix faded
	log.update()
	assert_true(log.knows("chose:custom_design:delegated_approval"), "kept until replaced")
	log.accept("fix_design")
	_resolve(log, "custom_design", "standard_designs")
	assert_false(log.knows("chose:custom_design:delegated_approval"))
	assert_true(log.knows("chose:custom_design:standard_designs"))
	assert_true(log.knows("standardised:custom_design"))
	assert_false(log.knows("poor_fix:custom_design"))
	log.accept("fix_revision")
	_resolve(log, "revision_backlog", "revision_at_source", true, false)
	assert_true(log.knows("poor_fix:revision_backlog"), "the wrong root cause")
	assert_true(log.knows("reputation>=30"))
	assert_false(log.knows("maturity>=3"))
	assert_eq(Facts.measure("floor_days>=28"), ["floor_days", 28])
	assert_false(log.knows("floor_days>=28"), "QA 2.12 (c): the way back opens at the debt floor")
	log.region.floor_days = 28
	assert_true(log.knows("floor_days>=28"))


func test_flags_and_the_fork_branch_done_first() -> void:
	var walk := {"type": "walk", "stream": "meters"}
	var log := _log(RulesFixture.countermeasures(), [
		_mission("branch_b", "main", walk, {"fork": {"group": "g", "role": "bottleneck"}, "sets_flags": ["flag:met_crew"],
			"debrief_first": "first b"}),
		_mission("branch_n", "main", {"type": "walk", "stream": "connections"},
			{"fork": {"group": "g", "role": "non_bottleneck"}, "debrief_first": "first n"}),
	])
	log.accept("branch_b")
	log.region.use_tool("meters.visit", "shadow")
	log.update()
	assert_true(log.knows("flag:met_crew"))
	assert_true(log.knows("fork_first:g:branch_b"))
	assert_eq(log.debrief_of("branch_b"), "first b", "this branch came first")
	_walk_connections(log)
	log.accept("branch_n")
	log.update()
	assert_false(log.knows("fork_first:g:branch_n"))
	assert_eq(log.debrief_of("branch_n"), "debrief branch_n")


## Gate backlog 3 (2026-10-24): the fork is one main quest, so once the player picks a
## branch, the other branch's problem hurts too (the intake does not heal while the monteurs
## are helped); otherwise the non-bottleneck branch's Check could never show that fixing it
## brings no flow. It is held until its own branch is taken and solved.
func test_taking_one_fork_branch_switches_the_others_problem_on() -> void:
	var log := _log(RulesFixture.countermeasures(), [
		_mission("branch_b", "main", {"type": "solve", "problem": "incomplete_application"},
			{"fork": {"group": "g", "role": "bottleneck"}}),
		_mission("branch_n", "main", {"type": "solve", "problem": "custom_design"},
			{"fork": {"group": "g", "role": "non_bottleneck"}}),
	])
	var problem := func(id: String) -> ProblemState.Phase: return log.region.state[id].phase
	log.update()
	assert_eq(problem.call("incomplete_application"), ProblemState.Phase.DORMANT, "nothing until a branch is taken")
	assert_eq(log.accept("branch_n"), "")
	log.update()
	assert_eq(problem.call("custom_design"), ProblemState.Phase.ACTIVE)
	assert_eq(problem.call("incomplete_application"), ProblemState.Phase.ACTIVE, "the other branch's problem is on")
	assert_eq(log.status("branch_b"), "available", "but its mission waits for the player")
	_resolve(log, "custom_design", "standard_designs")
	assert_eq(log.status("branch_n"), "completed")
	assert_eq(problem.call("incomplete_application"), ProblemState.Phase.ACTIVE, "still on while its branch waits")
	assert_eq(log.accept("branch_b"), "")
	_resolve(log, "incomplete_application", "poka_yoke_form")
	assert_eq(problem.call("incomplete_application"), ProblemState.Phase.RESOLVED)


func test_a_reopened_mission_tells_its_reopen_text() -> void:
	var log := _log(RulesFixture.countermeasures(), [
		_mission("fix_again", "side", {"type": "solve", "problem": "revision_backlog"}, {"reopen": "Het is terug."})])
	assert_eq(log.briefing_of("fix_again"), "briefing fix_again")
	log.accept("fix_again")
	_resolve(log, "revision_backlog", "revision_at_source")
	log.region.state["revision_backlog"] = ProblemState.new("revision_backlog")  # the fix faded
	log.update()
	assert_eq(log.status("fix_again"), "available")
	assert_eq(log.briefing_of("fix_again"), "Het is terug.")


## A countermeasure that needs an earlier preparation is not offered until
## the facts hold; the player sees it as "niet voorbereid" with its hint.
func test_an_unprepared_countermeasure_is_locked_with_its_hint() -> void:
	var cms := RulesFixture.countermeasures()
	cms[2].merge({"needs": {"all": ["done:fix_revision"]}, "preparation": "Eerst moet de kaart kloppen."})
	var log := _log(cms)
	log.update()
	var r := log.region
	var delegated: CountermeasureDef = r.countermeasures["delegated_approval"]
	assert_eq(delegated.preparation, "Eerst moet de kaart kloppen.")
	assert_false(delegated in r.available_countermeasures())
	assert_eq(log.unprepared(), [delegated])
	_walk_connections(log)
	log.accept("fix_revision")
	_resolve(log, "revision_backlog", "revision_at_source")
	assert_true(delegated in r.available_countermeasures(), "prepared now")
	assert_eq(log.unprepared(), [])


func test_facts_survive_save_and_load() -> void:
	var log := _log()
	_walk_connections(log)
	log.accept("fix_design")
	_resolve(log, "custom_design", "delegated_approval", false)
	log.facts.add("heard:henk_teach")
	log.facts.add("forecast_positive:kpi_board")
	var restored := _log()
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	for atom in ["chose:custom_design:delegated_approval", "poor_fix:custom_design", "heard:henk_teach",
			"forecast_positive:kpi_board"]:
		assert_true(restored.knows(atom), atom)
	var saved := log.to_dict()
	saved["facts"] = ["nonsense", "flag:ok"]
	var odd := _log()
	odd.load_dict(saved)
	assert_true(odd.knows("flag:ok"))
	assert_false(odd.facts.has("nonsense"))


## A debrief reads the play (audit §5.7): blamed before a poor fix before an
## unstandardised fix before the fork branch done first.
func test_the_debrief_reads_the_play() -> void:
	var variants := {"blamed": "b", "poor_fix": "p", "not_standardised": "n"}
	var log := _log(RulesFixture.countermeasures(), [_mission("fix_it", "side", {"type": "solve", "problem": "revision_backlog"},
		{"debrief_variants": variants})])
	log.accept("fix_it")
	var st: ProblemState = log.region.state["revision_backlog"]
	_resolve(log, "revision_backlog", "revision_at_source", false)
	assert_eq(log.debrief_of("fix_it"), "n")
	st.cause_correct = false
	log.facts.add("poor_fix:revision_backlog")
	assert_eq(log.debrief_of("fix_it"), "p")
	st.blamed = true
	assert_eq(log.debrief_of("fix_it"), "b")
	var plain := MissionDef.from_dict(_mission("x", "side", {"type": "walk", "stream": "meters"}, {"debrief_variants": {"blamed": "b"}}))
	assert_eq(plain.debrief_variants, {"blamed": "b"})
