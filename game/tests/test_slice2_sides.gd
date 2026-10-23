extends TestCase
## Slice 2's side missions on the real content and rules (phase-2 design §3.2, §3.5):
## the Act I sides from the catalogue (talk_netplanner, lsw_gemba_round) and the way
## back from the debt floor (QA 2.12 (c): fix_double_visits, then fix_overtime_planning).
## One main mission and at most three sides still hold.


## A returning player's game: the training week skipped, the campaign open.
func _campaign() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	return s


func _done(s: GameSession, ids: Array) -> void:
	for id: String in ids:
		s.missions.progress[id] = {"status": "completed", "asks": {}, "seen": {}}
		s.missions.done_once[id] = true
	s.missions.update()


func test_femke_explains_why_the_grid_is_full() -> void:
	var s := _campaign()
	assert_eq(s.missions.status("talk_netplanner"), "available", "after the training week")
	var trust_before: int = s.region.trust.get("grid_analysts", 0)
	assert_eq(s.accept("talk_netplanner"), "")
	s.ask("connections.grid_study", "walk")
	assert_eq(s.missions.status("talk_netplanner"), "active", "one of her two places")
	s.ask("congestion.congestion_study", "walk")
	assert_eq(s.missions.status("talk_netplanner"), "completed")
	assert_eq(s.region.trust.get("grid_analysts", 0), trust_before + 1)
	assert_true(s.region.profile.concepts.has("middenspanningsruimte"), "the card comes with the mission")


func test_the_gemba_round_opens_after_the_first_fix_and_walks_three_places() -> void:
	var s := _campaign()
	assert_eq(s.missions.status("lsw_gemba_round"), "locked")
	_done(s, ["walk_connections", "fix_custom_design"])
	assert_eq(s.accept("lsw_gemba_round"), "")
	s.use_tool("connections.intake", "documents")
	s.use_tool("connections.design", "shadow")
	assert_eq(s.missions.status("lsw_gemba_round"), "active")
	s.ask("connections.planning", "walk")
	assert_eq(s.missions.status("lsw_gemba_round"), "completed")
	assert_true(s.region.profile.concepts.has("leader_standard_work"))


func test_the_way_back_opens_at_the_debt_floor_and_leads_on() -> void:
	var s := _campaign()
	_done(s, ["walk_connections"])
	assert_eq(s.missions.status("fix_double_visits"), "locked", "not while the budget is fine")
	s.region.floor_days = 28
	assert_eq(s.missions.status("fix_double_visits"), "available", "four weeks at the floor")
	assert_eq(s.accept("fix_double_visits"), "")
	assert_eq(s.phase_of("double_visits"), "active", "its problem comes only through its mission")
	assert_true(s.region.weekly_cost() > 0.0, "the double visits cost money every week")
	assert_eq(s.missions.status("fix_overtime_planning"), "locked")
	_done(s, ["fix_double_visits"])
	assert_eq(s.missions.status("fix_overtime_planning"), "available", "the chain leads on")


func test_still_one_main_and_at_most_three_sides() -> void:
	var s := _campaign()
	_done(s, ["walk_connections", "fix_custom_design"])
	s.region.floor_days = 28
	for id in ["talk_netplanner", "lsw_gemba_round", "fix_double_visits"]:
		assert_eq(s.accept(id), "", id)
	assert_eq(s.accept("walk_outages"), "side_full")
	assert_eq(s.accept("fix_incomplete_application"), "")
	assert_eq(s.accept("fix_installer_not_ready"), "main_active")


## Leader standard work recurs (catalogue §2.9): the round comes back a week after it was
## walked; XP the first time, after that reputation and the team's trust, and it survives
## a save.
func test_the_gemba_round_comes_back_every_week_without_xp() -> void:
	var s := _campaign()
	_done(s, ["walk_connections", "fix_custom_design"])
	var m: MissionDef = s.missions.defs["lsw_gemba_round"]
	assert_eq(m.recurring_days, 7)
	assert_eq(s.accept("lsw_gemba_round"), "")
	s.use_tool("connections.intake", "documents")
	s.use_tool("connections.design", "shadow")
	s.ask("connections.planning", "walk")
	assert_eq(s.missions.status("lsw_gemba_round"), "completed")
	s.wait_days(3.0)
	assert_eq(s.missions.status("lsw_gemba_round"), "completed", "not before the week is out")
	s.wait_days(5.0)
	assert_eq(s.missions.status("lsw_gemba_round"), "available", "next week's round")
	var xp := s.xp()
	var reputation := s.region.reputation.value
	assert_eq(s.accept("lsw_gemba_round"), "")
	s.use_tool("connections.intake", "documents")
	s.use_tool("connections.design", "shadow")
	s.ask("connections.planning", "walk")
	assert_eq(s.missions.status("lsw_gemba_round"), "completed")
	assert_true(s.xp() - xp < m.reward_xp, "no mission XP for a repeat")
	assert_eq(s.region.reputation.value, reputation + Reputation.SIDE_MISSION, "the routine is seen")
	var copy := _campaign()
	copy.missions.load_dict(bytes_to_var(var_to_bytes(s.missions.to_dict())))
	assert_eq(copy.missions.progress["lsw_gemba_round"].get("done_at"), s.missions.progress["lsw_gemba_round"]["done_at"])
