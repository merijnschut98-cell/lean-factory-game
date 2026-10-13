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


## Walk every work step of the connections stream.
func _walk_connections(log: Missions) -> void:
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()


func test_only_unlocked_missions_are_available() -> void:
	var log := _log()
	assert_eq(_ids(log.available()), ["walk_connections", "walk_meters"], "a fresh start opens only the first steps")
	assert_eq(log.accept("fix_design"), "locked")
	assert_eq(log.accept("walk_connections"), "")
	_walk_connections(log)
	assert_eq(log.status("walk_connections"), "completed")
	assert_eq(_ids(log.available()), ["deep_dive", "fix_design", "fix_revision", "henk", "look_at_intake", "walk_meters"])
	assert_eq(log.accept("green_only"), "locked", "needs the green belt")
	log.region.profile.xp = Progression.BELTS[2]["xp"]
	assert_true(log.available().any(func(m: MissionDef) -> bool: return m.id == "green_only"))


func test_one_main_and_at_most_three_side_missions() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.profile.xp = Progression.BELTS[2]["xp"]
	assert_eq(log.accept("fix_design"), "")
	assert_eq(log.accept("deep_dive"), "main_active", "one main mission at a time")
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


## A deadline is a real event: the clock runs from the moment the mission
## opens, whether or not the player takes it on. Henk retires anyway.
func test_a_deadline_runs_from_when_the_mission_opens() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.status("henk"), "available")
	log.region.advance_days(11)
	log.update()
	assert_eq(log.status("henk"), "failed")
	assert_eq(log.accept("henk"), "not_available")


## Missing the deadline closes a door: the countermeasures that needed Henk
## are gone for good. The problem can still be solved another way.
func test_a_missed_deadline_closes_the_countermeasures_it_names() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	var poka_yoke := log.region.countermeasures["poka_yoke_form"]
	assert_true(poka_yoke in log.region.available_countermeasures())
	log.region.advance_days(11)
	log.update()
	assert_false(poka_yoke in log.region.available_countermeasures(), "the knowledge transfer is no longer possible")
	var restored := RulesFixture.mission_log(RulesFixture.region())
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	assert_false(poka_yoke in restored.region.available_countermeasures(), "still closed after a load")


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
	log.region.advance_days(3)
	log.update()  # the deadline clock of an open mission is saved too
	var restored := _log()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict()))), [])
	assert_eq(restored.to_dict(), log.to_dict())
	assert_eq(restored.status("fix_design"), "active")
	var saved := log.to_dict()
	saved["progress"]["ghost"] = {"status": "active"}
	assert_eq(_log().load_dict(saved), ["ghost"], "missions the content no longer has are dropped")


## A fix that fades brings its problem back through its mission, never on
## its own (CLAUDE.md §2). Doing it again earns no second reward.
func test_a_faded_fix_reopens_its_mission() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	var r := log.region
	r.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	r.state["custom_design"].recur_at = r.net.time + SimCalendar.days(5)
	log.update()
	assert_eq(log.status("fix_design"), "completed")
	r.advance_days(6)
	log.update()
	assert_eq(log.status("fix_design"), "available", "the problem is back")
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.DORMANT, "only the mission switches it on")
	assert_eq(log.drain_events().back(), {"type": "reopened", "mission": "fix_design"})
	assert_eq(log.accept("fix_design"), "")
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.ACTIVE)
	var budget := r.profile.budget
	r.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("fix_design"), "completed")
	assert_eq(r.profile.budget, budget, "no second reward")


## A reopened mission has no deadline: Henk passed on his knowledge before the
## fix faded, so nothing closes now.
func test_a_reopened_mission_runs_no_deadline() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.accept("henk"), "")
	var r := log.region
	r.state["incomplete_application"].phase = ProblemState.Phase.RESOLVED
	r.state["incomplete_application"].recur_at = r.net.time + SimCalendar.days(20)
	log.update()
	assert_eq(log.status("henk"), "completed")
	r.advance_days(21)
	log.update()
	assert_eq(log.status("henk"), "available", "reopened after the deadline would have passed")
	assert_true(r.countermeasures["poka_yoke_form"] in r.available_countermeasures(), "no door closes")
