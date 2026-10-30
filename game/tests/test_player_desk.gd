extends TestCase
## The player's own place (phase-2 design §1.8, PLAN 2.10 diegetic UI): a desk at
## Aansluitingen with your name plate, your badge photo, the El Amrani letter once Ruud
## has handed it over and your A3 on a clipboard (E there: the A3, drawn as paper);
## and the Check at Petra's screen at Meetdata, drawn as her monitor, once it is ready.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"


func _office(player_name := "Noor", photo := PackedByteArray()) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false   # a returning player: straight to the campaign
	var me := PlayerProfile.new()
	me.name = player_name
	me.portrait = photo
	office.new_player = me
	office.build()
	return office


## The mission played up to its experiment running (the A3 written at the desk).
func _to_the_experiment(office: Office) -> void:
	var ui := office.ui
	ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("time_study")
	ui.place_menu.use_tool("documents")
	office.interact(office.interactable(INTAKE))
	ui.place_menu.ask("walk")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("data")
	ui.close_panels()
	office.interact(office.interactable(OfficeDesk.ID))
	var problem: ProblemDef = office.session.region.problems[PROBLEM]
	var evidence := office.session.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	assert_eq(ui.a3_form.submit({"waste": "overprocessing", "cause": office.session.cause_options(PROBLEM).find(problem.root_cause),
		"evidence": evidence, "cm": "standard_designs", "prediction": "throughput"}), "")
	ui.close_panels()


func _photo() -> PackedByteArray:
	var image := Image.create_empty(PlayerProfile.PORTRAIT_SIZE.x, PlayerProfile.PORTRAIT_SIZE.y, false, Image.FORMAT_RGB8)
	image.fill(Color(0.8, 0.6, 0.5))
	return image.save_png_to_buffer()


# ── The desk ────────────────────────────────────────────────────────────────

func test_your_desk_at_aansluitingen_carries_a_name_plate_with_your_name() -> void:
	for c: Dictionary in CharacterModel.cast():
		assert_false(str(c.get("office", {}).get("seat", "")) == OfficeDesk.DESK, "nobody else sits there: " + str(c["id"]))
	var office := _office()
	var desk := office.interactable(OfficeDesk.ID)
	assert_true(desk != null, "your desk on the 1e")
	var room := MinimapTargets.room_of(office.floors.building, "connections.design")
	assert_eq(room.get("id"), "connections", "at Aansluitingen, with Werkvoorbereiding")
	assert_true(desk.position.distance_to(office.people.person("joost").position) < 3.0, "beside Joost's team")
	assert_eq(office.prompt_for(desk), tr(OfficeDesk.PROMPT))
	assert_true(office.desk != null, "its things on the desk")
	assert_eq(office.desk.plate_text(), "Noor", "the name plate shows your first name")
	office.free()


func test_a_new_name_changes_the_plate() -> void:
	var office := _office()
	var me := office.session.player.copy()
	me.name = "Daan"
	office.session.player = me   # "Uiterlijk" in the pause menu
	office.desk.refresh()
	assert_eq(office.desk.plate_text(), "Daan")
	office.free()


func test_your_badge_photo_stands_framed_on_the_desk() -> void:
	var office := _office("Noor", _photo())
	var photo := office.desk.photo_texture()
	assert_true(photo != null, "the creator's badge photo")
	assert_eq(Vector2i(photo.get_size()), PlayerProfile.PORTRAIT_SIZE)
	office.free()
	var without := _office()
	assert_true(without.desk.photo_texture() == null, "no photo taken: the frame shows the badge's placeholder")
	without.free()


func test_the_el_amrani_letter_lies_on_the_desk_once_ruud_has_handed_it_over() -> void:
	var office := _office()
	var layer := office.ui.session_layer
	assert_true(office.desk.letter_shown(), "no opening (a returning player): the letter is there")
	layer.opening_beat = Opening.WALK
	office.desk.refresh()
	assert_false(office.desk.letter_shown(), "before Ruud's letter beat")
	layer.opening_beat = Opening.LETTER
	office.desk.refresh()
	assert_false(office.desk.letter_shown(), "Ruud is reading it to you")
	layer.opening_beat = Opening.EVENING
	office.desk.refresh()
	assert_true(office.desk.letter_shown(), "after the letter beat it lies on your desk")
	office.free()


## R-1 #5 (design §3.2: "her call and the letter's reply on your desk"): once the winter
## promise is kept, her thank-you letter lies on your desk beside her first letter, its
## greeting and close readable, as well as in Berichten.
func test_her_thank_you_letter_lies_on_your_desk_once_the_winter_promise_is_kept() -> void:
	var office := _office()
	assert_false(office.desk.thanks_shown(), "no thank-you before the frost")
	office.session.missions.done_once["winter_el_amrani"] = true
	office.desk.refresh()
	assert_true(office.desk.thanks_shown(), "her letter on your desk")
	var text := office.desk.thanks_text()
	assert_true(text.begins_with("Beste Noor,"), "to you, by name: " + text)
	assert_true(text.ends_with("Fatima El Amrani"), "signed by her")
	assert_true(office.desk.letter_shown(), "beside her first letter")
	PhoneMessages.sync(office.session, office.ui.session_layer)
	assert_true(office.ui.session_layer.inbox.any(func(e: Dictionary) -> bool:
		return e["id"] == PhoneMessages.PAYOFF + "winter_el_amrani:1"), "and in Berichten")
	office.free()


func test_e_at_your_desk_opens_your_a3_with_the_camera_on_the_desk() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	office.ui.place_menu.use_tool("time_study")
	office.ui.close_panels()
	office.interact(office.interactable(OfficeDesk.ID))
	assert_true(office.ui.a3_form.visible, "the A3 opens at your desk")
	assert_eq(office.ui.a3_form.problem_id, PROBLEM)
	assert_true(office.rig.inspecting(), "the camera drops to the desk")
	office.free()


func test_the_a3_is_drawn_as_a_sheet_on_a_clipboard() -> void:
	var office := _office()
	var form := office.ui.a3_form
	var style := form.get_theme_stylebox("panel")
	assert_true(style is PaperSheet, "a sheet of paper, not a game window")
	var sheet := style as PaperSheet
	assert_true(sheet.clipboard, "on a clipboard")
	assert_true(sheet.rule_every > 0, "ruled")
	assert_true(sheet.paper.v > 0.9 and sheet.paper.s < 0.12, "off-white paper")
	assert_true(sheet.paper != Color.WHITE, "not pure white")
	assert_false(form.title_label.text.contains("Obeya-wand"), "your clipboard, not the wall")
	office.free()


func test_the_clipboard_opens_from_anywhere_on_the_phone() -> void:
	var office := _office()
	office.ui.mission_board.accept(MISSION)
	office.ui.close_panels()
	var app := office.ui.phone.app(Phone.MISSIONS) as MissionsApp
	office.ui.toggle_phone(Phone.MISSIONS)
	assert_true(shows(app, tr(MissionsApp.CLIPBOARD)), "Opdrachten offers your clipboard")
	app.a3_requested.emit()
	assert_true(office.ui.a3_form.visible, "the A3, drawn the same")
	assert_false(office.ui.phone.visible, "the phone goes down")
	office.free()


# ── The Check at Petra's screen ─────────────────────────────────────────────

## Petra's room is open whenever a Check can come: the training week's first trial is
## read on Friday (Meetdata opens with Thursday), a skipped week counts as done.
func test_meetdata_is_open_whenever_a_check_can_come() -> void:
	var building := OfficeBuilding.load_from(Catalog.DATA_DIR)
	var week := GameSession.new_game(11, Catalog.DATA_DIR, true)
	assert_false("meter_data" in building.open_rooms(week), "Monday: no Check before Thursday's trial")
	week.missions.progress["training_thu"] = {"status": "active", "asks": {}, "seen": {}}
	assert_true("meter_data" in building.open_rooms(week), "Thursday, the day of the first trial")
	assert_true("meter_data" in building.open_rooms(GameSession.new_game(11, Catalog.DATA_DIR, false)), "a skipped week")


func test_the_check_opens_at_petras_screen_when_it_is_ready_and_not_before() -> void:
	var office := _office()
	_to_the_experiment(office)
	office.reload_rooms()
	var screen := office.interactable(OfficeCheckScreen.ID)
	assert_true(screen == null or not screen.visible, "no Check waits: nothing at her screen")
	assert_false(office.ui.open_check(), "and nothing opens")
	assert_eq(office.ui.a3_form.wait(), "")
	office.ui.close_panels()
	office.reload_rooms()   # the floor's poll: Meetdata opens
	OfficeCheckScreen.refresh(office)   # each frame in the office
	screen = office.interactable(OfficeCheckScreen.ID)
	assert_true(screen != null and screen.visible, "the Check waits at Petra's screen")
	assert_eq(office.prompt_for(screen), tr(OfficeCheckScreen.PROMPT))
	var petra := office.people.person("petra")
	assert_true(petra != null and screen.position.distance_to(petra.position) < 1.6, "beside Petra")
	assert_eq(office.interactable_near(screen.position), screen, "standing there, E uses her screen")
	office.interact(screen)
	assert_true(office.ui.check_panel.visible, "the Check opens on her screen")
	assert_eq(office.ui.check_panel.problem_id, PROBLEM)
	assert_true(office.ui.check_panel.result.has("passed"), "the Check ran")
	assert_eq(office.session.phase_of(PROBLEM), "checked")
	assert_true(office.rig.inspecting(), "the camera on her screen")
	office.ui.close_panels()
	office.interact(screen)
	assert_true(office.ui.check_panel.visible and office.ui.check_panel.result.has("passed"), "back for the Act: the same result")
	office.free()


func test_the_a3_points_to_petras_screen_when_the_check_is_due() -> void:
	var office := _office()
	_to_the_experiment(office)
	office.ui.a3_form.wait()
	office.ui.open_a3()
	assert_true(shows(office.ui.a3_form, tr(A3Form.CHECK_AT_PETRA)), "the A3 says where the numbers are")
	office.free()


func test_the_check_is_drawn_as_her_monitor() -> void:
	var office := _office()
	var style := office.ui.check_panel.get_theme_stylebox("panel")
	assert_true(style is MonitorScreen, "a screen in its bezel")
	assert_true((style as MonitorScreen).grid > 0, "her spreadsheet's grid")
	office.free()


func test_the_objective_and_the_minimap_point_to_petra_for_the_check_and_to_your_desk_for_the_a3() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.progress[MISSION] = {"status": "active", "asks": {}, "seen": {}}
	var st: ProblemState = s.region.state[PROBLEM]
	st.phase = ProblemState.Phase.SPOTTED
	for c in s.region.problems[PROBLEM].clues:
		if c.key:
			s.region.found[c.id] = true
	for t: Dictionary in s.missions.defs[MISSION].talk_goals:
		s.people.outcomes[t["dialog"]] = "commitment"
	var a3 := Objective.of(s)
	assert_eq(a3.get("step"), "a3")
	assert_true(a3.get("desk", false), "the A3 is written at your desk")
	assert_true(str(a3["text"]).contains("bureau"), a3["text"])
	for phase in [ProblemState.Phase.CHECK_READY, ProblemState.Phase.CHECKED]:
		st.phase = phase
		var step := Objective.of(s)
		assert_eq(step.get("person"), Objective.CHECK_PERSON, "the Check and the Act at Petra's screen")
		assert_true(str(step["text"]).contains("Petra"), step["text"])
	st.phase = ProblemState.Phase.CHECK_READY
	var building := OfficeBuilding.load_from(Catalog.DATA_DIR)
	var target := MinimapTargets.of(s.missions.defs[MISSION], s, building, CharacterModel.cast())
	assert_eq(target.get("kind"), "person")
	assert_eq(target.get("person"), "petra")
	assert_eq(target.get("room"), "meter_data")
	assert_true(OfficeCheckScreen.ID in OfficeMap.mission_places(s), "the map marks her screen")
	assert_false("obeya" in OfficeMap.mission_places(s), "not the wall")
