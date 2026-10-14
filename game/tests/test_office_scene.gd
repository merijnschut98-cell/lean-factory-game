extends TestCase
## The office scene, headless: the interaction points found in the loaded
## geometry, the session wired to the UI, and the mission played through the
## UI's own handlers (the nodes only forward clicks to them).

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"


## Built outside the tree: the runner's tests run before the tree starts.
func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false  # a returning player: straight to the campaign
	office.build()
	return office


func _close(office: Office) -> void:
	office.free()


func _ids(office: Office) -> Array:
	return office.interactables.map(func(i: Interactable) -> String: return i.id)


func test_the_office_loads_with_a_session_a_player_and_every_interaction_point() -> void:
	var office := _office()
	assert_eq(office.session.error, "")
	assert_true(office.player != null, "a player")
	assert_true(office.ui != null, "a UI")
	var ids := _ids(office)
	ids.sort()
	assert_eq(ids, ["coach", "mission_board", "obeya", DESIGN, INTAKE])
	assert_eq(office.session.clock_text(), "ma 12 okt, 08:30")
	assert_eq(office.geometry.name == "OfficePlaceholder", not ResourceLoader.exists(Office.MODEL),
		"the model when it is imported, the stand-in otherwise")
	_close(office)


func test_every_interaction_point_maps_to_a_place_or_a_role() -> void:
	var office := _office()
	for i: Interactable in office.interactables:
		if i.kind == "place":
			assert_true(office.session.region.net.step_at(i.place) != null, "%s is a step of the network" % i.id)
		else:
			assert_true(i.kind in ["obeya", "coach", "mission_board"], "%s has a role" % i.id)
		assert_false(office.prompt_for(i).is_empty(), "%s has a prompt" % i.id)
	assert_eq(office.prompt_for(office.interactable(DESIGN)), "E — Werkvoorbereiding & ontwerp")
	_close(office)


func test_standing_at_a_point_puts_it_in_reach() -> void:
	var office := _office()
	var design := office.interactable(DESIGN)
	assert_eq(office.interactable_near(design.position), design)
	assert_eq(office.interactable_near(design.position + Vector3(0.5, 0, 0.3)), design)
	assert_eq(office.interactable_near(Vector3(500, 0, 500)), null, "nothing in reach far away")
	_close(office)


func test_the_player_starts_at_the_spawn_point() -> void:
	var office := _office()
	var spawn := office.find_marker("spawn")
	assert_true(spawn != null, "a spawn marker")
	assert_true(office.player.position.distance_to(office.in_office(spawn).origin) < 0.01)
	assert_true(office.player.position.distance_to(office.interactable("mission_board").position) < 5.0,
		"the mission board is by the entrance")
	_close(office)


func test_the_mission_board_accepts_the_first_mission() -> void:
	var office := _office()
	office.interact(office.interactable("mission_board"))
	assert_true(office.ui.mission_board.visible, "the board opens")
	assert_true(MISSION in office.ui.mission_board.listed(), "the first mission is on the board")
	assert_eq(office.ui.mission_board.accept(MISSION), "")
	assert_eq(office.session.active_missions().map(func(m: MissionDef) -> String: return m.id), [MISSION])
	assert_true(office.ui.hud.mission_text().contains("De stapel bij Werkvoorbereiding"), "the HUD shows it")
	assert_ne(office.ui.mission_board.accept(MISSION), "", "it cannot be taken twice")
	_close(office)


func test_a_gemba_tool_in_the_place_menu_costs_time_and_fills_the_journal() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	assert_true(office.ui.place_menu.visible, "the team's menu opens")
	assert_eq(office.ui.place_menu.place, "connections.design")
	assert_eq(office.ui.journal_lines(), [], "nothing found yet")
	var before := office.session.region.net.time
	var text := office.ui.place_menu.use_tool("time_study")
	assert_eq(office.session.region.net.time - before, Investigation.TOOLS["time_study"]["minutes"])
	assert_eq(office.ui.hud.clock_label.text, office.session.clock_text(), "the HUD clock follows")
	var found := office.session.clues_found(PROBLEM)
	assert_eq(found.size(), 1)
	assert_true(text.contains(found[0].text), "the result shows the clue")
	assert_true(office.ui.journal_lines().has(found[0].text), "the journal keeps it")
	_close(office)


func test_a_question_in_the_place_menu_costs_a_conversation() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	office.ui.place_menu.use_tool("time_study")
	office.interact(office.interactable(INTAKE))
	var before := office.session.region.net.time
	var text := office.ui.place_menu.ask("walk")
	assert_eq(office.session.region.net.time - before, Investigation.TOOLS["conversation"]["minutes"])
	assert_false(text.is_empty())
	assert_eq(office.ui.journal_lines().size(), 2, "the intake's story is a clue")
	_close(office)


func test_the_mission_is_played_through_the_ui() -> void:
	var office := _office()
	var ui := office.ui
	ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("time_study")
	ui.place_menu.use_tool("documents")
	office.interact(office.interactable(INTAKE))
	ui.place_menu.ask("walk")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("data")

	office.interact(office.interactable("obeya"))
	assert_true(ui.a3_form.visible, "the obeya wall opens the A3")
	assert_eq(ui.a3_form.problem_id, PROBLEM)
	var problem: ProblemDef = office.session.region.problems[PROBLEM]
	var cause: int = Investigation.cause_options(problem, office.session.region.problem_list())["correct"]
	var evidence := office.session.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	assert_eq(ui.a3_form.submit({"waste": "overprocessing", "cause": cause, "evidence": evidence,
		"cm": "standard_designs", "prediction": "throughput"}), "")
	assert_eq(office.session.phase_of(PROBLEM), "doing")
	assert_eq(ui.a3_form.wait(), "")
	assert_eq(office.session.phase_of(PROBLEM), "check_ready")
	var checked := ui.a3_form.check()
	assert_true(checked.get("passed", false), "the fitting countermeasure passes")
	assert_true(ui.check_panel.visible, "the Check result is shown")
	var score := ui.check_panel.act(true)
	assert_true(score.get("total", 0) > 0)
	assert_eq(office.session.missions.status(MISSION), "completed")
	assert_true(ui.hud.xp_label.text.contains(str(office.session.xp())))
	_close(office)


func test_an_a3_with_a_gap_is_refused_in_dutch() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	office.ui.place_menu.use_tool("time_study")
	office.interact(office.interactable("obeya"))
	assert_eq(office.ui.a3_form.submit({"waste": "overprocessing", "cause": 0, "evidence": []}), "evidence")
	assert_eq(office.ui.a3_form.message, UiText.a3_error("evidence"))
	assert_eq(office.session.phase_of(PROBLEM), "spotted", "nothing started")
	_close(office)


func test_the_a3_form_reads_back_what_was_filled_in() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	office.ui.place_menu.use_tool("time_study")
	office.interact(office.interactable("obeya"))
	var form := office.ui.a3_form
	assert_eq(form.selected_a3(), {"waste": "", "cause": -1, "evidence": [], "cm": "", "prediction": ""},
		"nothing is chosen for the player")
	var clue: String = office.session.clues_found(PROBLEM)[0].id
	var a3 := {"waste": "waiting", "cause": 2, "evidence": [clue], "cm": "standard_designs", "prediction": "lead_time"}
	form.fill(a3)
	assert_eq(form.selected_a3(), a3)
	_close(office)


func test_the_coach_answers_with_a_question_about_the_main_mission() -> void:
	var office := _office()
	office.interact(office.interactable("coach"))
	assert_true(office.ui.coach_panel.visible)
	assert_eq(office.ui.coach_panel.ask(), UiText.coach_reply({"kind": "no_main"}))
	office.ui.mission_board.accept(MISSION)
	assert_eq(office.ui.coach_panel.ask(), office.session.catalog.coach["stages"]["go_see"][0])
	_close(office)


func test_one_panel_at_a_time_and_closing_frees_the_player() -> void:
	var office := _office()
	office.interact(office.interactable("mission_board"))
	assert_true(office.ui.is_busy(), "a panel is open")
	office.interact(office.interactable("coach"))
	assert_false(office.ui.mission_board.visible, "the board closed")
	assert_true(office.ui.coach_panel.visible)
	office.ui.close_panels()
	assert_false(office.ui.is_busy())
	_close(office)


# ── Review fixes ──────────────────────────────────────────────────────────────

func test_over_bad_content_the_keys_do_nothing_and_the_error_stays() -> void:
	var office: Office = load(SCENE).instantiate()
	office.data_dir = "res://does_not_exist"
	office.build()
	assert_ne(office.session.error, "")
	office.player.journal_pressed.emit()
	office.player.interact_pressed.emit()
	office.player.escape_pressed.emit()
	office.ui.open_a3()
	office.ui.open_coach()
	office.ui.open_mission_board()
	office.ui.open_place("connections.design")
	office.ui.toggle_map()
	assert_false(office.ui.is_busy(), "no panel opens")
	assert_true(office.ui.hud.prompt_label.text.begins_with("De inhoud kon niet worden geladen"), "the error stays")
	assert_true(office.ui.hud.prompt_label.visible)
	_close(office)


func _a3_open(office: Office) -> A3Form:
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	office.ui.place_menu.use_tool("time_study")
	office.interact(office.interactable("obeya"))
	return office.ui.a3_form


func test_a_refused_a3_keeps_the_players_draft() -> void:
	var office := _office()
	var form := _a3_open(office)
	var draft := {"waste": "waiting", "cause": 1, "evidence": [], "cm": "standard_designs", "prediction": "lead_time"}
	form.fill(draft)
	assert_eq(form.submit(form.selected_a3()), "evidence")
	assert_eq(form.selected_a3(), draft, "the answers survive the refusal")
	_close(office)


func test_closing_and_reopening_the_a3_keeps_the_draft() -> void:
	var office := _office()
	var form := _a3_open(office)
	var clue: String = office.session.clues_found(PROBLEM)[0].id
	var draft := {"waste": "overprocessing", "cause": 2, "evidence": [clue], "cm": "", "prediction": "throughput"}
	form.fill(draft)
	office.ui.close_panels()
	office.interact(office.interactable("obeya"))
	assert_eq(form.selected_a3(), draft)
	_close(office)


func test_the_a3_message_is_set_before_the_ui_hears_of_the_action() -> void:
	var office := _office()
	var form := _a3_open(office)
	var heard := []
	form.acted.connect(func() -> void: heard.append(form.message))
	form.check()
	assert_eq(heard, [UiText.a3_error("not_check_ready")])
	_close(office)


func test_a_refused_tool_or_question_is_worded_in_dutch() -> void:
	var office := _office()
	office.interact(office.interactable(DESIGN))
	assert_eq(office.ui.place_menu.use_tool("crystal_ball"), UiText.place_error("unknown_tool"))
	assert_eq(office.ui.place_menu.use_tool("conversation"), UiText.place_error("use_ask"))
	assert_eq(office.ui.place_menu.ask("what_is_wrong"), UiText.place_error("unknown_question"))
	_close(office)


func test_the_journal_lists_clues_by_place_then_as_found_not_per_problem() -> void:
	var office := _office()
	var s := office.session
	# Two clues of different problems at one place, and one elsewhere.
	var first: Clue = null
	var second: Clue = null
	var elsewhere: Clue = null
	for p in s.region.problem_list():
		for c in p.clues:
			if first == null:
				first = c
			elif second == null and c.at == first.at and p.clues.find(first) < 0:
				second = c
	for p in s.region.problem_list():
		for c in p.clues:
			if elsewhere == null and c.at != first.at:
				elsewhere = c
	assert_true(second != null and elsewhere != null, "the content has such clues")
	for c in [second, elsewhere, first]:
		s.region.found[c.id] = true
	var ids := ClueJournal.found(s).map(func(c: Clue) -> String: return c.id)
	assert_eq(ids, [second.id, first.id, elsewhere.id], "the later problem's clue, found first, comes first")
	_close(office)


func test_toasts_keep_only_the_latest_few() -> void:
	var office := _office()
	for n in Hud.MAX_TOASTS + 3:
		office.ui.hud.toast("bericht %d" % n)
	var texts := office.ui.hud.toast_texts()
	assert_eq(texts.size(), Hud.MAX_TOASTS)
	assert_eq(texts[-1], "bericht %d" % (Hud.MAX_TOASTS + 2), "the newest is kept")
	_close(office)


func test_after_esc_a_click_on_the_view_catches_the_mouse_again() -> void:
	var office := _office()
	assert_true(office.mouse_captured)
	assert_false(office.ui.hud.mouse_hint.visible)
	office.player.escape_pressed.emit()
	assert_false(office.mouse_captured, "Esc frees the mouse")
	assert_true(office.ui.hud.mouse_hint.visible, "a hint says how to get it back")
	assert_eq(office.ui.hud.mouse_hint.text, "Klik om verder te lopen")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	office._unhandled_input(click)
	assert_true(office.mouse_captured, "a click catches it")
	assert_false(office.ui.hud.mouse_hint.visible)
	office.interact(office.interactable("coach"))
	assert_false(office.mouse_captured, "a panel frees the mouse")
	assert_false(office.ui.hud.mouse_hint.visible, "but needs no hint")
	office._unhandled_input(click)
	assert_false(office.mouse_captured, "a click with a panel open is for the panel")
	_close(office)


func test_the_board_offers_the_second_mission_once_the_first_is_done() -> void:
	var office := _office()
	var board := office.ui.mission_board
	assert_false("fix_incomplete_application" in board.listed(), "locked at the start")
	board.accept(MISSION)
	var s := office.session
	s.use_tool("connections.design", "time_study")
	s.use_tool("connections.design", "documents")
	s.ask("connections.intake", "walk")
	s.use_tool("connections.design", "data")
	var problem: ProblemDef = s.region.problems[PROBLEM]
	var cause: int = Investigation.cause_options(problem, s.region.problem_list())["correct"]
	var evidence := s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": cause, "evidence": evidence,
		"cm": "standard_designs", "prediction": "throughput"})
	s.wait_for_check(PROBLEM)
	s.check(PROBLEM)
	s.act(PROBLEM, true)
	assert_true("fix_incomplete_application" in board.listed(), "the first fix opens the second mission")
	assert_eq(board.accept("fix_incomplete_application"), "")
	assert_eq(s.active_missions().map(func(m: MissionDef) -> String: return m.id), ["fix_incomplete_application"])
	_close(office)
