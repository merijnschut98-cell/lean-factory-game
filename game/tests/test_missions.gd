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


## A fix that wears out brings its problem back through its mission, never on
## its own (CLAUDE.md §2). Doing it again earns no second reward.
func test_a_faded_fix_reopens_its_mission() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	var r := log.region
	# A fix with no sustaining habit, neglected for 25 of its 30 days (standard_designs).
	r.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	r.state["custom_design"].a3 = {"cm": "standard_designs"}
	r.state["custom_design"].neglect = 25.0
	r.state["custom_design"].wear = pow(25.0 / 30.0, 2)
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


## A standardised fix that slips gets a "have a look" side mission (Terugval),
## never a free problem (Merijn, 2026-10-15). An audit at the place, or a
## planned routine there, completes it.
func _slipping_fix(log: Missions, standardised: bool = true) -> Region:
	var r := log.region
	var st: ProblemState = r.state["custom_design"]
	st.phase = ProblemState.Phase.RESOLVED
	st.a3 = {"cm": "standard_designs"}
	st.standardised = standardised
	st.wear = 0.5  # health 0.71: below Sustain.SLIPPING_HEALTH
	st.neglect = 40.0
	return r


func test_a_slipping_standardised_fix_opens_a_check_in() -> void:
	var log := _log()
	var r := _slipping_fix(log)
	var id := Missions.CHECKIN_PREFIX + "custom_design"
	log.update()
	assert_eq(log.status(id), "available", "a mission to have a look")
	assert_eq(log.defs[id].kind, "side", "small, and the coach stays out of it")
	assert_eq(log.defs[id].goal_problem, "custom_design")
	assert_eq(log.drain_events(), [{"type": "checkin", "mission": id}])
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED, "no problem switches on")
	assert_eq(log.accept(id), "")
	log.update()
	assert_eq(log.status(id), "active")
	r.audit("connections.design")
	log.update()
	assert_eq(log.status(id), "completed", "the standard is back in use")
	var budget := r.profile.budget
	r.state["custom_design"].wear = 0.5  # it slips again later
	log.update()
	assert_eq(log.status(id), "available", "the check-in comes back when it is needed again")
	assert_eq(log.accept(id), "")
	assert_eq(r.plan_routine("connections.design"), "")
	log.update()
	assert_eq(log.status(id), "completed", "a planned routine holds it too")
	assert_eq(r.profile.budget, budget, "rewarded once")


func test_an_ignored_check_in_ends_with_its_problem_back_through_the_main_mission() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	var r := _slipping_fix(log)
	log.update()
	var id := Missions.CHECKIN_PREFIX + "custom_design"
	assert_eq(log.status("fix_design"), "completed")
	assert_eq(log.accept(id), "")
	r.advance_days(30)  # nobody looks: 40 days of neglect on a 65-day life become 70
	log.update()
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.DORMANT)
	assert_false(log.defs.has(id), "the check-in is over")
	assert_false(log.active("side").any(func(m: MissionDef) -> bool: return m.id == id))
	assert_eq(log.status("fix_design"), "available", "the problem comes back through its own mission")


func test_an_unstandardised_fix_gets_no_check_in() -> void:
	var log := _log()
	_slipping_fix(log, false)
	log.update()
	assert_false(log.defs.has(Missions.CHECKIN_PREFIX + "custom_design"), "nothing to audit: it fades back to its mission")


func test_a_check_in_survives_a_save() -> void:
	var log := _log()
	_slipping_fix(log)
	log.update()
	var id := Missions.CHECKIN_PREFIX + "custom_design"
	log.accept(id)
	var restored := RulesFixture.mission_log(log.region)
	assert_eq(restored.load_dict(log.to_dict()), [])
	assert_eq(restored.status(id), "active")
	assert_eq(restored.defs[id].name, log.defs[id].name)


## A reopened mission has no deadline: Henk passed on his knowledge before the
## fix faded, so nothing closes now.
func test_a_reopened_mission_runs_no_deadline() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.accept("henk"), "")
	var r := log.region
	# poka_yoke_form is built in: it lasts about a year of neglect; this one has 20 days left.
	r.state["incomplete_application"].phase = ProblemState.Phase.RESOLVED
	r.state["incomplete_application"].a3 = {"cm": "poka_yoke_form"}
	r.state["incomplete_application"].neglect = Sustain.STRUCTURAL_DAYS - 20.0
	r.state["incomplete_application"].wear = pow((Sustain.STRUCTURAL_DAYS - 20.0) / Sustain.STRUCTURAL_DAYS, 2)
	log.update()
	assert_eq(log.status("henk"), "completed")
	r.advance_days(21)
	log.update()
	assert_eq(log.status("henk"), "available", "reopened after the deadline would have passed")
	assert_true(r.countermeasures["poka_yoke_form"] in r.available_countermeasures(), "no door closes")


# ── The training week (Inwerkweek) ──────────────────────────────────────────

## The fixture campaign with a three-day training week before it.
func _training_log() -> Missions:
	var data := RulesFixture.missions()
	var day := func(id: String, goal: Dictionary, requires: Array, extra: Dictionary = {}) -> Dictionary:
		var d := {"id": id, "name": id, "kind": "training", "tier": 1, "goal": goal, "requires": {"missions": requires},
			"briefing": "briefing " + id, "debrief": "debrief " + id, "rewards": {"xp": 50}}
		d.merge(extra, true)
		return d
	data.append_array([
		day.call("t_look", {"type": "observe", "places": ["connections.intake", "connections.design"]}, [],
			{"teaches": ["gemba"], "insights": {"go_see": "insight t_look"},
			"setup": [{"target": "prep", "property": "availability", "value": -0.75}]}),
		day.call("t_tools", {"type": "observe", "places": ["connections.design"], "uses": 2}, ["t_look"]),
		day.call("t_count", {"type": "observe", "places": ["connections.intake", "connections.design"], "tool": "queue_count"},
			["t_tools"]),
		day.call("t_check", {"type": "check", "problem": "custom_design"}, ["t_count"], {"check_days": 3}),
		day.call("t_fix", {"type": "solve", "problem": "custom_design"}, ["t_check"], {"check_days": 3}),
	])
	var defs: Array[MissionDef] = []
	for d: Dictionary in data:
		defs.append(MissionDef.from_dict(d))
	return Missions.new(RulesFixture.region(), defs, RulesFixture.coach())


func test_training_missions_read_their_new_fields() -> void:
	var log := _training_log()
	assert_eq(log.defs["t_look"].error, "")
	assert_eq(log.defs["t_look"].teaches, PackedStringArray(["gemba"]))
	assert_eq(log.defs["t_count"].goal_places, PackedStringArray(["connections.intake", "connections.design"]))
	assert_eq(log.defs["t_count"].goal_tool, "queue_count")
	assert_eq(log.defs["t_tools"].goal_uses, 2)
	assert_eq(log.defs["t_look"].goal_uses, 1, "by default one use in all")
	assert_eq(log.defs["t_check"].check_days, 3)
	assert_eq(log.defs["fix_design"].check_days, -1, "the real Check unless a mission shortens it")
	assert_ne(MissionDef.from_dict({"id": "x", "name": "x", "kind": "training", "goal": {"type": "observe"}}).error, "",
		"an observe goal needs places")


func test_training_missions_take_no_side_slot() -> void:
	var log := _training_log()
	log.accept("walk_connections")
	_walk_connections(log)
	for id in ["look_at_intake", "fix_revision", "walk_meters"]:
		assert_eq(log.accept(id), "", id)
	assert_eq(log.accept("t_look"), "", "the training week does not count against the three side missions")
	assert_eq(log.active("side").size(), 3)
	assert_eq(_ids(log.active("training")), ["t_look"])


func test_an_observe_goal_needs_every_place_while_the_mission_is_active() -> void:
	var log := _training_log()
	log.note_use("connections.intake", "shadow")  # before it was taken on: does not count
	assert_eq(log.accept("t_look"), "")
	log.note_use("connections.intake", "shadow")
	log.update()
	assert_eq(log.status("t_look"), "active", "one of two places")
	log.note_use("connections.design", "documents")
	log.update()
	assert_eq(log.status("t_look"), "completed")


func test_an_observe_goal_can_ask_for_one_tool_or_for_different_tools() -> void:
	var log := _training_log()
	log.accept("t_look")
	log.note_use("connections.intake", "shadow")
	log.note_use("connections.design", "shadow")
	log.update()
	assert_eq(log.status("t_tools"), "active", "the next day was handed out")
	log.note_use("connections.design", "time_study")
	log.note_use("connections.design", "time_study")
	log.update()
	assert_eq(log.status("t_tools"), "active", "the same tool twice is one use")
	log.note_use("connections.design", "documents")
	log.update()
	assert_eq(log.status("t_tools"), "completed")
	log.note_use("connections.intake", "shadow")
	log.note_use("connections.design", "queue_count")
	log.update()
	assert_eq(log.status("t_count"), "active", "the queue at the intake is not counted yet")
	log.note_use("connections.intake", "queue_count")
	log.update()
	assert_eq(log.status("t_count"), "completed")


func test_finishing_a_training_day_hands_out_the_next() -> void:
	var log := _training_log()
	log.accept("t_look")
	log.drain_events()
	log.note_use("connections.intake", "shadow")
	log.note_use("connections.design", "shadow")
	log.update()
	assert_eq(log.drain_events(), [{"type": "completed", "mission": "t_look"}, {"type": "accepted", "mission": "t_tools"}])
	assert_eq(log.region.profile.xp, 50, "a small reward per day")


func test_a_check_goal_completes_once_the_check_passed() -> void:
	var log := _training_log()
	log.done_once["t_count"] = true
	assert_eq(log.accept("t_check"), "")
	var st: ProblemState = log.region.state["custom_design"]
	assert_eq(st.phase, ProblemState.Phase.ACTIVE, "accepting brings the problem")
	st.phase = ProblemState.Phase.CHECK_READY
	log.update()
	assert_eq(log.status("t_check"), "active")
	st.phase = ProblemState.Phase.CHECKED
	log.update()
	assert_eq(log.status("t_check"), "completed")
	assert_eq(log.status("t_fix"), "active", "the next day was handed out")
	log.abandon("t_fix")
	assert_eq(log.check_days_for("custom_design"), -1, "no active mission shortens its Check any more")


func test_an_active_mission_can_shorten_its_problems_check() -> void:
	var log := _training_log()
	log.done_once["t_count"] = true
	log.accept("t_check")
	assert_eq(log.check_days_for("custom_design"), 3)
	assert_eq(log.check_days_for("incomplete_application"), -1)


func test_a_training_mission_brings_its_glossary_cards() -> void:
	var log := _training_log()
	assert_false("gemba" in log.region.profile.concepts)
	log.accept("t_look")
	assert_true("gemba" in log.region.profile.concepts)


## The training week is with the coach (the spec's Starter Kata); side
## missions still get no coaching.
func test_the_coach_helps_with_the_training_week() -> void:
	var log := _training_log()
	log.accept("t_look")
	assert_eq(log.ask_coach()["kind"], "question", "no main mission yet: the coach asks about the training day")
	assert_eq(log.ask_coach("t_look")["kind"], "question")
	assert_eq(log.ask_coach()["kind"], "insight")
	assert_eq(log.ask_coach("walk_meters")["kind"], "not_main")


func test_skipping_the_training_week_opens_the_campaign_without_rewards() -> void:
	var log := _training_log()
	log.done_once["t_count"] = true
	log.accept("t_check")
	log.skip_training()
	for id in ["t_look", "t_tools", "t_count", "t_check"]:
		assert_eq(log.status(id), "completed", id)
	assert_eq(log.region.profile.xp, 0, "no rewards for skipped days")
	assert_eq(log.region.state["custom_design"].phase, ProblemState.Phase.DORMANT, "the practice problem goes back to sleep")
	assert_false(log.in_training())


func test_observations_survive_save_and_load() -> void:
	var log := _training_log()
	log.accept("t_look")
	log.note_use("connections.intake", "shadow")
	var restored := _training_log()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict()))), [])
	restored.note_use("connections.design", "shadow")
	restored.update()
	assert_eq(restored.status("t_look"), "completed", "the intake visit was kept")


## A training day's goal problem is practice: resolving it says nothing about
## the region's maturity.
func test_a_practice_problem_does_not_count_toward_maturity() -> void:
	var log := _training_log()
	assert_true(log.region.practice.has("custom_design"), "the training week's problem is practice")
	assert_false(log.region.practice.has("incomplete_application"))
	for id in ["custom_design", "incomplete_application"]:
		log.region.state[id].phase = ProblemState.Phase.RESOLVED
	assert_eq(log.region.maturity(), 1, "one real problem of two is not yet most of the tier")
	log.region.state["revision_backlog"].phase = ProblemState.Phase.RESOLVED
	assert_eq(log.region.maturity(), 2, "two of the two real ones are")


## After the week the practice problem is retired: a faded practice fix
## brings neither its day nor its problem back.
func test_a_faded_practice_fix_does_not_reopen_its_training_day() -> void:
	var log := _training_log()
	log.done_once["t_check"] = true
	assert_eq(log.accept("t_fix"), "")
	log.region.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("t_fix"), "completed")
	log.drain_events()
	log.region.state["custom_design"] = ProblemState.new("custom_design")  # the fix faded (Region._recur)
	log.update()
	assert_eq(log.status("t_fix"), "completed", "the training day stays done")
	assert_eq(log.drain_events(), [], "nothing reopens")
	assert_eq(log.accept("t_fix"), "not_available")
	assert_eq(log.region.state["custom_design"].phase, ProblemState.Phase.DORMANT, "the practice problem stays asleep")


## A training setup (a staged situation for the week's lessons) holds from
## its day to the end of the week, and goes when the week is done or skipped.
func test_a_training_setup_holds_for_the_whole_week() -> void:
	var log := _training_log()
	var prep: SimPool = log.region.net.pools["prep"]
	assert_eq(prep.availability, 1.0)
	assert_eq(log.accept("t_look"), "")
	assert_near(prep.availability, 0.25, 0.001, "three of four on a course")
	log.note_use("connections.intake", "walk")
	log.note_use("connections.design", "walk")
	log.update()
	assert_eq(log.status("t_look"), "completed")
	assert_eq(log.status("t_tools"), "active", "the next day is handed out")
	assert_near(prep.availability, 0.25, 0.001, "the course lasts the whole week")
	for id in ["t_tools", "t_count", "t_check"]:
		log.progress[id] = {"status": "completed", "asks": {}, "seen": {}}
		log.done_once[id] = true
	log.progress["t_fix"] = {"status": "active", "asks": {}, "seen": {}}
	log.region.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("t_fix"), "completed", "Friday's goal met")
	assert_false(log.in_training())
	assert_eq(prep.availability, 1.0, "back once the week is over")
	var skipped := _training_log()
	skipped.accept("t_look")
	skipped.skip_training()
	assert_eq(skipped.region.net.pools["prep"].availability, 1.0, "and when the week is skipped")


## The bottleneck lesson is the measurement's, not the script's: the day's
## completion reports the queues measured at its places.
func test_a_queue_count_day_reports_the_measured_queues() -> void:
	var log := _training_log()
	log.done_once["t_tools"] = true
	log.accept("t_count")
	log.region.advance_days(2)
	log.drain_events()
	var expected := {}
	for place in ["connections.intake", "connections.design"]:
		log.note_use(place, "queue_count")
		expected[place] = log.region.queue_at(place)
	log.update()
	var done := log.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "completed")
	assert_eq(done.size(), 1)
	assert_eq(done[0]["queues"], expected)
	assert_true(expected["connections.design"]["days"] > expected["connections.intake"]["days"],
		"with most of the designers away the work waits at design")
