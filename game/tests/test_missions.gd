extends TestCase
## Missions: a progressive campaign with one main mission and at most three
## side missions at a time, unlocked by progress, and a coach who asks
## questions about the main mission only (CLAUDE.md §2).


func _log() -> Missions:
	return RulesFixture.mission_log(RulesFixture.region())


func _ids(defs: Array) -> Array:
	var ids := defs.map(func(m: MissionDef) -> String: return m.id)
	ids.sort()
	return ids


## Walk every work step of the connections stream (the fixture has four).
func _walk_connections(log: Missions) -> void:
	for step in ["intake", "design", "build", "revision"]:
		log.region.use_tool("connections." + step, "shadow")
	log.update()


func test_only_unlocked_missions_are_available() -> void:
	var log := _log()
	assert_eq(_ids(log.available()), ["walk_connections", "walk_meters"], "a fresh start opens only the first steps")
	assert_eq(log.accept("fix_design"), "locked")
	assert_eq(log.accept("walk_connections"), "")
	_walk_connections(log)
	assert_eq(log.status("walk_connections"), "completed")
	assert_eq(_ids(log.available()), ["fix_design", "fix_revision", "henk", "look_at_intake", "walk_meters"])
	assert_eq(log.accept("green_only"), "locked", "needs the green belt")
	log.region.profile.xp = Progression.BELTS[2]["xp"]
	assert_true(log.available().any(func(m: MissionDef) -> bool: return m.id == "green_only"))


func test_one_main_and_at_most_three_side_missions() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.profile.xp = Progression.BELTS[2]["xp"]
	assert_eq(log.accept("fix_design"), "")
	assert_eq(log.accept("henk"), "main_active", "one main mission at a time")
	for id in ["look_at_intake", "fix_revision", "walk_meters"]:
		assert_eq(log.accept(id), "", id)
	assert_eq(log.accept("green_only"), "side_full", "at most three side missions")
	assert_eq(log.active().size(), 4)
	assert_eq(log.accept("fix_design"), "not_available", "already active")


func test_accepting_activates_the_problem_and_solving_completes_it() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	var budget := log.region.profile.budget
	assert_eq(log.accept("fix_revision"), "")
	assert_eq(log.region.state["revision_backlog"].phase, ProblemState.Phase.ACTIVE)
	log.region.state["revision_backlog"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("fix_revision"), "completed")
	assert_eq(log.region.profile.budget, budget + 2000, "the mission's reward")
	var completed := log.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "completed")
	assert_eq(completed.map(func(e: Dictionary) -> String: return e["mission"]), ["walk_connections", "fix_revision"])


func test_investigating_completes_with_enough_key_clues() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("look_at_intake")
	log.update()
	assert_eq(log.status("look_at_intake"), "active")
	log.region.use_tool("connections.intake", "documents")  # its key clue at depth 0
	log.update()
	assert_eq(log.status("look_at_intake"), "completed")


func test_the_coach_only_helps_with_the_main_mission() -> void:
	var log := _log()
	assert_eq(log.ask_coach()["kind"], "no_main")
	log.accept("walk_meters")
	assert_eq(log.ask_coach("walk_meters")["kind"], "not_main", "no coaching on side missions")
	log.accept("walk_connections")
	var first := log.ask_coach()
	assert_eq([first["kind"], first["stage"], first["text"]], ["question", "go_see", "go_see 1"])
	assert_eq(log.ask_coach()["text"], "go_see 2", "questions rotate")
	assert_eq(log.ask_coach("walk_meters")["kind"], "not_main")


func test_the_coach_mostly_asks_and_sometimes_gives_an_insight() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	log.region.use_tool("connections.design", "time_study")  # spotted: understanding the problem
	var kinds := []
	for i in 6:
		kinds.append(log.ask_coach()["kind"])
	assert_eq(kinds, ["question", "question", "insight", "question", "question", "insight"])
	assert_eq(log.ask_coach()["stage"], "understand")


func test_a_missed_deadline_fails_the_mission_for_good() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.accept("henk"), "")
	log.region.advance_days(11)
	log.update()
	assert_eq(log.status("henk"), "failed")
	assert_false(log.available().any(func(m: MissionDef) -> bool: return m.id == "henk"), "Henk has left")
	assert_eq(log.drain_events().back(), {"type": "failed", "mission": "henk"})


func test_abandoning_a_mission_makes_room() -> void:
	var log := _log()
	log.accept("walk_connections")
	assert_true(log.abandon("walk_connections"))
	assert_eq(log.status("walk_connections"), "available")
	assert_false(log.abandon("walk_connections"), "not active")


func test_missions_survive_save_and_load() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	log.ask_coach()
	var restored := _log()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict()))), [])
	assert_eq(restored.to_dict(), log.to_dict())
	assert_eq(restored.status("fix_design"), "active")
	var saved := log.to_dict()
	saved["progress"]["ghost"] = {"status": "active"}
	assert_eq(_log().load_dict(saved), ["ghost"], "missions the content no longer has are dropped")
