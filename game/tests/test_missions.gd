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


## Half a solve mission's reward is for finishing, half for how well the
## problem was solved (its PDCA score): the patient, thorough fix pays more
## (audit R1), and what the simulation measured reaches the reward.
func test_a_solve_missions_reward_follows_the_score() -> void:
	var rewards := []
	for total in [Pdca.MAX_SCORE, 10]:
		var log := _log()
		log.accept("walk_connections")
		_walk_connections(log)
		log.accept("fix_revision")
		var budget := log.region.profile.budget
		var xp := log.region.profile.xp
		var st: ProblemState = log.region.state["revision_backlog"]
		st.phase = ProblemState.Phase.RESOLVED
		st.score = {"total": total}
		log.update()
		rewards.append([log.region.profile.xp - xp, log.region.profile.budget - budget])
	assert_eq(rewards, [[300, 2000], [210, 1400]], "a full score pays it all; 10 of 25 pays 0.5 + 0.5 × 0.4")
	assert_eq(Missions.reward_share({"total": 1}), Missions.MIN_REWARD_SHARE, "never below the floor")


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
	assert_eq([first["kind"], first["stage"]], ["question", "go_see"])
	assert_true(first["text"] in log.coach["stages"]["go_see"])
	assert_ne(log.ask_coach()["text"], first["text"], "questions rotate")
	assert_eq(log.ask_coach("walk_meters")["kind"], "not_main")


## An insight every third ask at a stage; a stage's insights are told in turn,
## then the coach goes back to asking (audit §3A, C2).
func test_the_coach_mostly_asks_and_sometimes_gives_an_insight() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	log.region.use_tool("connections.design", "time_study")  # spotted: understanding the problem
	var kinds := []
	for i in 6:
		kinds.append(log.ask_coach()["kind"])
	assert_eq(kinds, ["question", "question", "insight", "question", "question", "question"], "one insight, told once")
	assert_eq(log.ask_coach()["stage"], "understand")


func _coach_log(extra: Array) -> Missions:
	var coach := RulesFixture.coach()
	coach["stages"]["go_see"] = ["g1", "g2", "g3", "g4", "g5", "g6", "g7"]
	coach["conditional"] = {"blamed": "Wat wilde je eigenlijk weten?", "fading_fix": "Hoe lang blijft dit werken?"}
	var defs: Array[MissionDef] = []
	for d: Dictionary in RulesFixture.missions() + extra:
		defs.append(MissionDef.from_dict(d))
	return Missions.new(RulesFixture.region(), defs, coach)


func _main(id: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": "main", "tier": 1, "goal": {"type": "walk", "stream": "meters"},
		"briefing": "b", "debrief": "d"}
	d.merge(extra, true)
	return d


## The coach does not open every mission with the same line (QA #20): the
## mission's own questions come first, then the bank from a place of its own,
## and no line the player heard in the last six asks comes back.
func test_the_coach_does_not_repeat_himself_across_missions() -> void:
	var log := _coach_log([_main("m1", {"questions": {"go_see": ["eigen vraag"]}}), _main("m2"), _main("m3")])
	log.accept("m1")
	assert_eq(log.ask_coach()["text"], "eigen vraag", "the mission's own question first")
	var heard := [log.ask_coach()["text"]]
	log.region.use_tool("meters.visit", "shadow")
	log.update()
	for id in ["m2", "m3"]:
		log.accept(id)
		for i in 2:
			heard.append(log.ask_coach()["text"])
		log.update()
	assert_eq(heard.size(), 5)
	var unique := {}
	for line in heard + ["eigen vraag"]:
		unique[line] = true
	assert_eq(unique.size(), 6, "six asks, six different lines: %s" % [heard])


func test_insights_are_told_in_turn() -> void:
	var log := _coach_log([_main("m1", {"insights": {"go_see": ["inzicht 1", "inzicht 2"]}})])
	log.accept("m1")
	var insights := []
	for i in 9:
		var reply := log.ask_coach()
		if reply["kind"] == "insight":
			insights.append(reply["text"])
	assert_eq(insights, ["inzicht 1", "inzicht 2"])


## After a blaming question the coach asks what the player wanted to know
## (respect for people); a fix chosen to fade soon, while a lasting one fits,
## gets the long-term question (audit §3A.2).
func test_the_coach_asks_about_a_blame_and_a_fading_fix() -> void:
	var log := _coach_log([])
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	log.region.ask("connections.design", "who")
	log.region.use_tool("connections.design", "time_study")
	assert_eq(log.ask_coach()["text"], "Wat wilde je eigenlijk weten?")
	assert_ne(log.ask_coach()["text"], "Wat wilde je eigenlijk weten?", "said once")
	var r := log.region
	r.change_trust("prep", 2)
	r.state["custom_design"].phase = ProblemState.Phase.DOING
	r.countermeasures["standard_designs"].decay_days = -1  # built in: it lasts
	r.state["custom_design"].a3 = {"cm": "delegated_approval"}  # fades in 20 days
	assert_eq(log.ask_coach()["text"], "Hoe lang blijft dit werken?")


func test_what_the_coach_said_survives_a_save() -> void:
	var log := _coach_log([_main("m1")])
	log.accept("m1")
	var first: String = log.ask_coach()["text"]
	var restored := _coach_log([_main("m1")])
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	assert_ne(restored.ask_coach()["text"], first, "the memory came along")


## A missed deadline closes a door, not the problem: Henk has left, but the
## mission comes back without its clock, so the problem can still be solved
## another way (CLAUDE.md §2; QA autoplay #2).
func test_a_missed_deadline_closes_a_door_but_the_mission_can_be_taken_again() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.advance_days(11)
	log.update()
	assert_true(log.failed("henk"))
	assert_eq(log.drain_events().back(), {"type": "failed", "mission": "henk"})
	assert_eq(log.status("henk"), "available", "the problem can still be solved")
	assert_eq(log.accept("henk"), "")
	log.region.advance_days(30)
	log.update()
	assert_eq(log.status("henk"), "active", "no second deadline")
	log.region.state["incomplete_application"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("henk"), "completed")


## A deadline is a real event: the clock runs from the moment the mission
## opens, whether or not the player takes it on. Henk retires anyway. Taken
## on, the work goes on: the mission stays active and keeps its problem.
func test_a_deadline_passing_on_an_active_mission_keeps_its_work() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.accept("henk"), "")
	log.region.use_tool("connections.intake", "documents")
	log.region.advance_days(11)
	log.update()
	assert_true(log.failed("henk"))
	assert_eq(log.status("henk"), "active", "the experiment is not thrown away")
	assert_true(log.region.state["incomplete_application"].is_open(), "still held by its mission")


func test_failed_missions_survive_save_and_load() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.advance_days(11)
	log.update()
	var restored := _log()
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	assert_true(restored.failed("henk"))
	assert_eq(restored.status("henk"), "available")
	var old := log.to_dict()  # a save from before: status "failed", no failed_once
	old.erase("failed_once")
	old["progress"]["henk"] = {"status": "failed"}
	var legacy := _log()
	legacy.load_dict(old)
	assert_true(legacy.failed("henk"))
	assert_eq(legacy.status("henk"), "available")


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
	assert_eq(log.abandon("walk_connections"), "")
	assert_eq(log.status("walk_connections"), "available")
	assert_eq(log.abandon("walk_connections"), "not_active")


# ── Every open problem belongs to a mission (CLAUDE.md §2; QA autoplay #2, #3) ──

## Problems that are open (hurting the simulation) while no active mission
## names them.
func _orphans(log: Missions) -> Array:
	var held := log.active().map(func(m: MissionDef) -> String: return m.goal_problem)
	return log.region.state.keys().filter(func(id: String) -> bool:
		return log.region.state[id].is_open() and not id in held)


func test_a_finished_investigation_puts_its_problem_back_to_sleep() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("look_at_intake")
	log.region.use_tool("connections.intake", "documents")
	log.update()
	assert_eq(log.status("look_at_intake"), "completed")
	assert_eq(_orphans(log), [], "no problem stays open without a mission")
	assert_eq(log.region.state["incomplete_application"].phase, ProblemState.Phase.DORMANT)
	assert_eq(log.region.key_clues_found("incomplete_application"), 1, "what was found is kept")


func test_abandoning_a_mission_puts_its_problem_back_to_sleep() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_revision")
	assert_eq(log.abandon("fix_revision"), "")
	assert_eq(_orphans(log), [])
	assert_eq(log.accept("fix_revision"), "", "it can be taken on again")


func test_a_running_experiment_cannot_be_abandoned() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_revision")
	log.region.state["revision_backlog"].phase = ProblemState.Phase.DOING
	assert_eq(log.abandon("fix_revision"), "experiment_running")
	assert_eq(log.status("fix_revision"), "active")


## The open-problem limit (Region.MAX_OPEN) is never filled by problems
## nobody works on: after two finished investigations, a full board of one
## main and three side missions can still be taken on (QA autoplay #3).
func test_a_full_board_can_be_taken_on_after_finished_investigations() -> void:
	var problems := []
	for i in range(1, 6):
		var p: Dictionary = RulesFixture.problems()[2].duplicate(true)  # revision_backlog's shape
		p["id"] = "p%d" % i
		problems.append(p)
	var r := RulesFixture.region(50000, 5, problems)
	var m := func(id: String, kind: String, goal: Dictionary) -> MissionDef:
		return MissionDef.from_dict({"id": id, "name": id, "kind": kind, "tier": 1, "goal": goal,
			"briefing": "b", "debrief": "d"})
	var defs: Array[MissionDef] = [
		m.call("look_1", "side", {"type": "investigate", "problem": "p1", "clues": 1}),
		m.call("look_2", "side", {"type": "investigate", "problem": "p2", "clues": 1}),
		m.call("fix_3", "main", {"type": "solve", "problem": "p3"}),
		m.call("fix_4", "side", {"type": "solve", "problem": "p4"}),
		m.call("fix_5", "side", {"type": "solve", "problem": "p5"}),
	]
	var log := Missions.new(r, defs, RulesFixture.coach())
	log.accept("look_1")
	log.accept("look_2")
	r.use_tool("connections.revision", "data")
	log.update()
	assert_eq([log.status("look_1"), log.status("look_2")], ["completed", "completed"])
	for id in ["fix_3", "fix_4", "fix_5"]:
		assert_eq(log.accept(id), "", id)
	assert_eq(_orphans(log), [])


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


## QA 2.12 (a): decay must not pay. A check-in for your own slipped fix pays a little;
## holding the fix before it slips (an audit, a routine) pays the full reward, once a fix.
func test_a_check_in_pays_little_and_holding_the_fix_pays_the_reward() -> void:
	var log := _log()
	var r := _slipping_fix(log)
	log.update()
	var id := Missions.CHECKIN_PREFIX + "custom_design"
	log.accept(id)
	var xp := r.profile.xp
	r.audit("connections.design")
	log.update()
	assert_eq(log.status(id), "completed")
	assert_eq(r.profile.xp - xp, Missions.CHECKIN_XP, "it slipped on your watch")
	assert_true(Missions.CHECKIN_XP < Missions.HOLD_XP)
	var worn := _log()
	var held := _slipping_fix(worn)
	held.state["custom_design"].wear = 0.3  # health 0.81: worn, not yet slipping
	worn.update()
	assert_false(worn.defs.has(id), "no check-in: it has not slipped")
	xp = held.profile.xp
	held.audit("connections.design")
	worn.update()
	assert_eq(held.profile.xp - xp, Missions.HOLD_XP, "a look before it slipped holds the fix")
	assert_true(worn.drain_events().has({"type": "held", "problem": "custom_design"}))
	held.state["custom_design"].wear = 0.3
	worn.update()
	held.audit("connections.design")
	worn.update()
	assert_eq(held.profile.xp - xp, Missions.HOLD_XP, "once a fix: the routine is its own reward after that")


func test_a_routine_that_holds_a_fix_pays_the_reward_once() -> void:
	var log := _log()
	var r := _slipping_fix(log)
	r.state["custom_design"].wear = 0.0
	log.update()
	var xp := r.profile.xp
	assert_eq(r.plan_routine("connections.design"), "")
	log.update()
	log.update()
	assert_eq(r.profile.xp - xp, Missions.HOLD_XP)
	assert_eq(RulesFixture.mission_log(r).load_dict(log.to_dict()), [])
	var restored := RulesFixture.mission_log(r)
	restored.load_dict(log.to_dict())
	restored.update()
	assert_eq(r.profile.xp - xp, Missions.HOLD_XP, "a save remembers it was paid")


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
	assert_eq(log.abandon("t_fix"), "experiment_running", "the checked experiment still waits for its Act")
	st.phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("t_fix"), "completed")
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


# ── talk_to {dialog, outcome}: a persuasion as a goal (dialog spec §5.1) ─────

func _talk_log(outcome: String) -> Array:
	var said := {"o": ""}
	var defs: Array[MissionDef] = [MissionDef.from_dict({"id": "talk_m", "name": "talk_m", "kind": "side", "tier": 1,
		"goal": {"type": "talk_to", "dialog": "d1", "outcome": outcome}, "briefing": "b", "debrief": "d",
		"rewards": {"xp": 400, "budget": 2000, "reputation": 2}})]
	var log := Missions.new(RulesFixture.region(), defs, RulesFixture.coach())
	log.talk_outcome = func(id: String) -> String: return said["o"] if id == "d1" else ""
	assert_eq(log.accept("talk_m"), "")
	return [log, said]


func test_a_talk_goal_is_met_by_the_outcome_it_names_or_better() -> void:
	var made: Array = _talk_log("partial")
	var log: Missions = made[0]
	for o in ["", "heard", "ruined", "blocked"]:
		made[1]["o"] = o
		log.update()
		assert_eq(log.status("talk_m"), "active", "not met by " + o)
	made[1]["o"] = "commitment"
	log.update()
	assert_eq(log.status("talk_m"), "completed")
	assert_eq([log.region.profile.xp, log.region.reputation.value - Reputation.START], [400, 2])
	made = _talk_log("commitment")
	made[1]["o"] = "partial"
	made[0].update()
	assert_eq(made[0].status("talk_m"), "active", "a partial is not a commitment")


func test_compliance_meets_a_talk_goal_at_half_pay_and_no_reputation() -> void:
	var made: Array = _talk_log("commitment")
	var log: Missions = made[0]
	var budget := log.region.profile.budget
	made[1]["o"] = "compliance"
	log.update()
	assert_eq(log.status("talk_m"), "completed", "pressure works, short term")
	assert_eq([log.region.profile.xp, log.region.profile.budget - budget], [200, 1000])
	assert_eq(log.region.reputation.value, Reputation.START, "no reputation for a forced yes")


## A mission's talk_to goals besides its own (phase-2 design §3.1, S1-H): the talks it
## needs. It completes once its goal and every talk are met; a person who left waives theirs.
func _solve_with_talk_log() -> Array:
	var said := {"o": "", "gone": false}
	var defs: Array[MissionDef] = [MissionDef.from_dict({"id": "fix_m", "name": "fix_m", "kind": "main", "tier": 1,
		"goal": {"type": "solve", "problem": "revision_backlog"}, "briefing": "b", "debrief": "d",
		"talk_to": [{"dialog": "d1", "outcome": "partial"}], "rewards": {"xp": 400, "budget": 2000}})]
	var log := Missions.new(RulesFixture.region(), defs, RulesFixture.coach())
	log.talk_outcome = func(id: String) -> String: return said["o"] if id == "d1" else ""
	log.can_talk = func(_id: String) -> bool: return not said["gone"]
	assert_eq(log.accept("fix_m"), "")
	log.region.state["revision_backlog"].phase = ProblemState.Phase.RESOLVED
	return [log, said]


func test_a_mission_waits_for_the_talks_it_needs() -> void:
	var made: Array = _solve_with_talk_log()
	var log: Missions = made[0]
	assert_eq(log.defs["fix_m"].talk_goals, [{"dialog": "d1", "outcome": "partial"}])
	log.update()
	assert_eq(log.status("fix_m"), "active", "solved, but Joost was never asked")
	assert_eq(log.pending_talk(log.defs["fix_m"]), "d1")
	made[1]["o"] = "heard"
	log.update()
	assert_eq(log.status("fix_m"), "active", "heard is not yet an agreement")
	made[1]["o"] = "partial"
	log.update()
	assert_eq(log.status("fix_m"), "completed")
	assert_eq(log.pending_talk(log.defs["fix_m"]), "")
	assert_eq(log.region.profile.xp, 400)


## Found by autoplay (careless/11): a fix that fades while its mission still waits for
## its talk comes back through that same mission, never a mission stuck on a sleeping problem.
func test_a_fix_that_fades_while_the_talk_waits_comes_back_through_the_mission() -> void:
	var made: Array = _solve_with_talk_log()
	var log: Missions = made[0]
	log.update()
	log.region.state["revision_backlog"].phase = ProblemState.Phase.DORMANT  # worn out and recurred
	log.update()
	assert_eq(log.status("fix_m"), "active")
	assert_eq(log.region.state["revision_backlog"].phase, ProblemState.Phase.ACTIVE, "back to work")


func test_a_needed_talk_won_by_pressure_pays_half() -> void:
	var made: Array = _solve_with_talk_log()
	made[1]["o"] = "compliance"
	made[0].update()
	assert_eq(made[0].status("fix_m"), "completed")
	assert_eq(made[0].region.profile.xp, 200, "a forced yes: half the reward")


func test_a_needed_talk_with_someone_who_left_is_waived() -> void:
	var made: Array = _solve_with_talk_log()
	made[1]["gone"] = true
	made[0].update()
	assert_eq(made[0].status("fix_m"), "completed", "a closed door, never a dead end")


func test_a_talk_goal_entry_needs_a_dialog_and_an_outcome() -> void:
	var base := {"id": "x", "name": "x", "kind": "main", "goal": {"type": "solve", "problem": "p"}}
	assert_ne(MissionDef.from_dict(base.merged({"talk_to": [{"outcome": "partial"}]})).error, "")
	assert_ne(MissionDef.from_dict(base.merged({"talk_to": [{"dialog": "d", "outcome": "maybe"}]})).error, "")
	assert_eq(MissionDef.from_dict(base.merged({"talk_to": [{"dialog": "d"}]})).talk_goals,
		[{"dialog": "d", "outcome": "commitment"}])


func test_a_talk_goal_names_a_dialog() -> void:
	var bad := MissionDef.from_dict({"id": "x", "name": "x", "kind": "side", "goal": {"type": "talk_to"}})
	assert_ne(bad.error, "")
	var good := MissionDef.from_dict({"id": "x", "name": "x", "kind": "side", "goal": {"type": "talk_to", "dialog": "d1"}})
	assert_eq([good.error, good.goal_dialog, good.goal_outcome], ["", "d1", "commitment"])


## accepted:<mission>: the player took it on (it may be done since).
func test_a_mission_taken_on_is_a_fact() -> void:
	var log := _log()
	assert_false(log.knows("accepted:walk_connections"))
	log.accept("walk_connections")
	assert_true(log.knows("accepted:walk_connections"))
	_walk_connections(log)
	assert_eq(log.status("walk_connections"), "completed")
	assert_true(log.knows("accepted:walk_connections"), "still, once done")


## A dated beat (drie winters S2; tier-1 content audit C11): Henk's farewell
## is the day his mission's clock runs out, done or not, known from the day
## the mission opens, so a talk can count days from it.
func test_a_deadline_marks_a_dated_beat() -> void:
	var log := _log()
	assert_eq(log.beats(), {}, "not open yet: no date")
	log.accept("walk_connections")
	_walk_connections(log)
	var farewell: int = log.opened_at["henk"] + SimCalendar.days(10)
	assert_eq(log.beats(), {"henk_farewell": farewell})
	log.accept("henk")
	log.region.state["incomplete_application"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(log.status("henk"), "completed")
	assert_eq(log.beats(), {"henk_farewell": farewell}, "done early, he still retires on his day")
	var restored := _log()
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	assert_eq(restored.beats(), {"henk_farewell": farewell}, "saved with the mission's clock")


# ── Milestones, dates and the story's order (phase-2 design §3.1–3.2) ─────────

## The fixture's missions plus `extra` (each merged over a milestone's defaults).
func _with(extra: Array) -> Missions:
	var defs: Array[MissionDef] = []
	for d: Dictionary in RulesFixture.missions():
		defs.append(MissionDef.from_dict(d))
	for e: Dictionary in extra:
		var d := {"id": "review", "name": "review", "kind": "milestone", "tier": 1, "goal": {"type": "scene"},
			"scene": "review", "requires": {"missions": ["walk_connections"]}, "briefing": "b", "debrief": "d",
			"rewards": {"xp": 200}}
		d.merge(e, true)
		if not d["goal"].get("type") == "scene":
			d.erase("scene")
		var m := MissionDef.from_dict(d)
		assert_eq(m.error, "", "fixture milestone %s" % d["id"])
		defs.append(m)
	return Missions.new(RulesFixture.region(), defs, RulesFixture.coach())


func _winter(extra: Dictionary = {}) -> Dictionary:
	var d := {"id": "winter", "goal": {"type": "story_order", "story": "el_amrani", "by": "deadline",
		"met_if": {"any": ["delivered:el_amrani", "agreed:call:existing"]}, "promise": "call"},
		"deadline_on_day": 10, "fail": "koud", "sets_flags_on_fail": ["flag:el_amrani_complaint"], "missed": "Koud."}
	d.merge(extra, true)
	return d


func test_milestone_schema_is_parsed_and_checked() -> void:
	var m := MissionDef.from_dict({"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "scene"},
		"scene": "review_100_days", "opens_on": {"day": 100}, "deadline_on_day": 120, "fail": "f",
		"sets_flags_on_fail": ["flag:late"]})
	assert_eq(m.error, "")
	assert_eq([m.scene, m.opens_on_day, m.deadline_on_day, Array(m.sets_flags_on_fail)],
		["review_100_days", 100, 120, ["flag:late"]])
	var by_date := MissionDef.from_dict({"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "scene"},
		"scene": "s", "opens_on": {"date": "2026-12-21"}})
	assert_eq(by_date.opens_on_day, 70, "21 December is day 70 of play (day 0: Monday 12 October 2026)")
	var story := MissionDef.from_dict(_winter().merged({"name": "w", "kind": "milestone"}))
	assert_eq(story.error, "")
	assert_eq([story.goal_story, story.goal_by, story.goal_promise], ["el_amrani", "deadline", "call"])
	assert_eq(story.goal_met_if, {"any": ["delivered:el_amrani", "agreed:call:existing"]})
	for bad: Dictionary in [
		{"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "scene"}},
		{"id": "x", "name": "x", "kind": "side", "goal": {"type": "scene"}, "scene": "s"},
		{"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "scene"}, "scene": "s", "opens_on": {"date": "21-12-2026"}},
		{"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "scene"}, "scene": "s", "opens_on": {"week": 3}},
		{"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "story_order", "story": "el_amrani"}},
		{"id": "x", "name": "x", "kind": "milestone", "goal": {"type": "walk", "stream": "connections"}},
	]:
		assert_ne(MissionDef.from_dict(bad).error, "", "refused: %s" % bad)


## A milestone opens itself on its day: nobody picks it from the board, and it
## takes neither the main mission's place nor a side slot (CLAUDE.md §2).
func test_a_milestone_opens_on_its_day_and_takes_no_slot() -> void:
	var log := _with([{"opens_on": {"day": 5}}])
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.status("review"), "locked", "not before its day")
	assert_eq(log.accept("review"), "locked")
	log.region.advance_days(5)
	log.update()
	assert_eq(log.status("review"), "active", "it opened by itself on day 5")
	assert_true(log.drain_events().has({"type": "milestone", "mission": "review"}))
	log.region.profile.xp = Progression.BELTS[2]["xp"]
	assert_eq(log.accept("fix_design"), "", "the main mission still has its place")
	for id in ["look_at_intake", "fix_revision", "walk_meters"]:
		assert_eq(log.accept(id), "", "three side missions besides it: %s" % id)


func test_opens_on_counts_from_the_first_day_of_play() -> void:
	var log := _with([{"opens_on": {"day": 3}}])
	log.play_start = SimCalendar.days(2)  # a warm-up before play
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.advance_days(4)
	log.update()
	assert_eq(log.play_day(), 2)
	assert_eq(log.status("review"), "locked", "day 2 of play, not 4")
	log.region.advance_days(1)
	log.update()
	assert_eq(log.status("review"), "active")


## A scene milestone is done once its scene has been played; the answer given in
## it is a fact for later.
func test_a_scene_milestone_completes_when_its_scene_is_played() -> void:
	var log := _with([{}])
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.status("review"), "active")
	assert_eq(log.ask_coach("review")["kind"], "not_main", "the coach helps with the main quest only")
	var xp := log.region.profile.xp
	assert_eq(log.finish_scene("walk_meters", "flag:x"), "not_a_scene")
	assert_eq(log.finish_scene("review", "flag:people_first"), "")
	log.update()
	assert_eq(log.status("review"), "completed")
	assert_true(log.knows("flag:people_first"), "the answer is remembered")
	assert_eq(log.region.profile.xp, xp + 200)
	assert_eq(log.finish_scene("review", "flag:again"), "not_active", "played once")


## Winter 1 (arc S12): the story's order is judged against its absolute day.
## Missed: a door closes (the flags), and the moment passes; the problem itself
## stays solvable through its own mission.
func test_a_story_order_missed_by_its_day_fails_and_sets_its_flags() -> void:
	var log := _with([_winter()])
	log.accept("walk_connections")
	_walk_connections(log)
	assert_eq(log.status("winter"), "active", "no opens_on: open once unlocked")
	log.region.advance_days(10)
	log.update()
	assert_eq(log.status("winter"), "active", "day 10 is still in time")
	var reputation := log.region.reputation.value
	log.region.advance_days(1)
	log.update()
	assert_true(log.failed("winter"))
	assert_eq(log.status("winter"), "locked", "the frost has come: the moment is over")
	assert_true(log.knows("flag:el_amrani_complaint"), "a door closes for Act III")
	assert_true(log.region.reputation.value < reputation)
	assert_true(log.drain_events().has({"type": "failed", "mission": "winter", "milestone": true, "text": "Koud."}),
		"its own gentle line, not 'Missie verlopen'")
	assert_eq(UiText.event({"type": "failed", "mission": "winter", "milestone": true, "text": "Koud."}, {}), "Koud.")
	assert_eq(UiText.event({"type": "failed", "mission": "winter", "milestone": true, "text": ""}, {"winter": "Voor de vorst"}),
		"Voor de vorst: het moment is voorbij")
	var restored := _with([_winter()])
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	assert_eq(restored.status("winter"), "locked", "saved")


func test_a_story_order_is_met_by_delivery_or_by_the_agreement() -> void:
	for fact in ["delivered:el_amrani", "agreed:call:existing"]:
		var log := _with([_winter()])
		log.accept("walk_connections")
		_walk_connections(log)
		log.region.advance_days(4)
		log.facts.add(fact)
		log.update()
		assert_eq(log.status("winter"), "completed", fact)
		assert_false(log.failed("winter"))


## The date the player promised (People.promises: a delivery_date proposal agreed
## in the story's call) is checked by the simulation on that date.
func test_a_promised_date_is_checked_on_its_day() -> void:
	for delivered in [false, true]:
		var log := _with([_winter({"deadline_on_day": 60})])
		log.facts.add("promised:call:2026-10-18")   # day 6 of play (GameSession records it at the talk)
		log.accept("walk_connections")
		_walk_connections(log)
		log.region.advance_days(6)
		log.update()
		assert_false(log.knows("promise_broken:call") or log.knows("promise_kept:call"), "not yet day 7")
		if delivered:
			log.facts.add("delivered:el_amrani")
		var reputation := log.region.reputation.value
		log.region.advance_days(1.1)
		log.update()
		assert_eq(log.knows("promise_kept:call"), delivered)
		assert_eq(log.knows("promise_broken:call"), not delivered)
		if not delivered:
			assert_eq(log.region.reputation.value, reputation + Missions.PROMISE_BROKEN)
			assert_true(log.drain_events().has({"type": "promise", "dialog": "call", "kept": false}))


## The designed failed Check (designed-failed-checks spec): a too_early verdict
## on the active mission's problem reads its own debrief.
func test_a_too_early_check_reads_the_missions_own_debrief() -> void:
	var log := _with([])
	log.defs["fix_design"].debrief_variants["too_early"] = "Te vroeg."
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	assert_eq(log.check_debrief("custom_design", "too_early"), "Te vroeg.")
	assert_eq(log.check_debrief("custom_design", "not_moved"), "", "no text of its own")
	assert_eq(log.check_debrief("revision_backlog", "too_early"), "", "no active mission holds it")
	assert_true("too_early" in Missions.DEBRIEF_VARIANTS)
	log.region.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_ne(log.debrief_of("fix_design"), "Te vroeg.", "said at the failed Check, never at the end")


## Debriefs read the player's numbers (catalogue C16): {kpi_before} and {kpi_after} are
## the problem's KPI in the Check's runs without and with the fix, as people say them;
## a sentence whose number is not there (no Check yet) is left out.
func test_a_debrief_reads_the_checks_numbers() -> void:
	var log := _with([])
	var m: MissionDef = log.defs["fix_design"]
	m.debrief = "Klaar. De doorlooptijd ging van {kpi_before} naar {kpi_after} dagen. Wat nu?"
	var st: ProblemState = log.region.state["custom_design"]
	st.phase = ProblemState.Phase.RESOLVED
	st.standardised = true
	assert_eq(log.debrief_of("fix_design"), "Klaar. Wat nu?", "no Check, no numbers: the sentence goes")
	var kpi: String = log.region.problems["custom_design"].kpi
	st.checked = {"without": {kpi: 54.4}, "with": {kpi: 40.6}}
	assert_eq(log.debrief_of("fix_design"), "Klaar. De doorlooptijd ging van 54 naar 41 dagen. Wat nu?")
	assert_eq(Missions.spoken_number("first_time_right", 0.826), "83")
	assert_eq(Missions.spoken_number("throughput", 31.0), "31")
	assert_eq(Missions.spoken_number("capacity", 37.94), "37,9")
	assert_eq(Missions.spoken_number("lead_time", 54.4), "54")
