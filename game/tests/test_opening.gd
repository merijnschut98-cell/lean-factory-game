extends TestCase
## De eerste vijf minuten (PLAN 2.7d; spec 2026-10-16-first-five-minutes): a
## new game opens as one scene, B2 → B7, and the HUD appears one element at a
## time (spec §3); no mission board before the first talk; a returning player
## and an old save skip it all.

const SCENE := "res://src/world/office/office.tscn"


## A new game through the opening (as "Nieuw spel" starts it).
func _opening_office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.opening = true
	office.build()
	return office


func _shown(office: Office) -> Dictionary:
	return Opening.hud(office.session, office.ui.session_layer)


# ── The beats and the HUD ───────────────────────────────────────────────────

func test_a_new_game_opens_at_the_reception_with_no_hud() -> void:
	var office := _opening_office()
	var layer := office.ui.session_layer
	assert_eq(layer.opening_beat, Opening.ARRIVAL)
	assert_false(layer.has_floor_plan, "the plan comes from Ruud on the walk")
	var hud := office.ui.hud
	for l: Control in [hud.clock_label, hud.budget_label, hud.xp_label, hud.objective_label, hud.help_label]:
		assert_false(l.visible, "nothing on screen before it means something: " + l.name)
	for element: String in Opening.ELEMENTS:
		assert_false(_shown(office)[element], element)
	office.free()


func test_the_beats_run_in_order_and_never_back() -> void:
	var layer := SessionLayer.new()
	layer.opening_beat = Opening.ARRIVAL
	for beat: String in Opening.BEATS.slice(1):
		assert_true(Opening.advance(layer, beat), beat)
		assert_eq(layer.opening_beat, beat)
	assert_false(Opening.advance(layer, Opening.ARRIVAL), "never back")
	assert_eq(layer.opening_beat, Opening.DONE)


func test_the_clock_comes_with_the_evening_and_the_notes_after_the_talk() -> void:
	var office := _opening_office()
	var layer := office.ui.session_layer
	Opening.advance(layer, Opening.ANOUK)
	office.ui.after_action()
	assert_true(_shown(office)["clock"], "the first time time has passed")
	assert_true(office.ui.hud.clock_label.visible)
	assert_true(_shown(office)["phone"], "the phone came with the evening's messages")
	assert_false(_shown(office)["notes"])
	assert_false(_shown(office)["people"])
	Opening.advance(layer, Opening.DONE)
	assert_true(_shown(office)["notes"], "the first thing worth remembering")
	assert_true(_shown(office)["people"], "and the first person to remember")
	assert_false(_shown(office)["mission"], "the mission line waits for Tuesday")
	assert_false(_shown(office)["budget"])
	office.free()


func test_tuesday_brings_the_mission_line_the_board_and_the_map_thursday_the_budget_friday_xp() -> void:
	var office := _opening_office()
	var s := office.session
	Opening.advance(office.ui.session_layer, Opening.DONE)
	s.missions.done_once["training_mon"] = true
	s.missions.done_once["training_tue"] = true
	for element: String in ["mission", "board", "map", "codex", "controls"]:
		assert_true(_shown(office)[element], element)
	assert_false(_shown(office)["budget"])
	s.missions.done_once["training_thu"] = true
	assert_true(_shown(office)["budget"])
	assert_false(_shown(office)["xp"])
	s.missions.done_once["training_fri"] = true
	assert_true(_shown(office)["xp"])
	office.free()


func test_no_mission_board_and_no_j_m_k_before_their_time() -> void:
	var office := _opening_office()
	office.ui.open_mission_board()
	assert_false(office.ui.mission_board.visible, "no board before the first talk")
	for app: String in [Phone.HOME, Phone.NOTES, Phone.MAP, Phone.CODEX]:
		office.ui.toggle_phone(app)
	assert_false(office.ui.is_busy(), "Tab, J, M and K wait for their moment")
	office.free()


## A returning player (no training week) and a game built without the opening
## (an old save, the tests) have the full HUD at once.
func test_returning_players_and_old_saves_skip_it() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.opening = true
	office.build()
	assert_eq(office.ui.session_layer.opening_beat, "", "no week, no opening")
	for element: String in Opening.ELEMENTS:
		assert_true(_shown(office)[element], element)
	office.free()
	var old := SessionLayer.new()
	old.load_dict({"start": {}, "toast_day": -1})
	assert_eq(old.opening_beat, "", "an old save has no opening")


# ── The scene, beat by beat ─────────────────────────────────────────────────

## Step the scene until `done` holds (or a few minutes of game frames pass).
## The player reads along: each frame a line is up, Spatie (a paper or a
## choice waits for the test).
func _until(office: Office, done: Callable, seconds := 240.0) -> bool:
	var t := 0.0
	while not done.call() and t < seconds:
		office.first_day.step(0.25)
		var l := office.first_day.lines if office.first_day != null else null
		if l != null and l.speaking() and not l.asking() and not l.paper_up() and not done.call():
			l.press()
		t += 0.25
	return done.call()


func _said(office: Office, part: String) -> Callable:
	return func() -> bool: return office.first_day.lines.current().get("text", "").contains(part)


## A new game's opening with a named player.
func _named_opening() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.opening = true
	var me := PlayerProfile.new()
	me.name = "Noor"
	office.new_player = me
	office.build()
	office.first_day.start()
	office.first_day.lines.auto = false   # the default, whatever this machine's settings say
	return office


## B2 → B3's top of the stairs: the ontvangst, the badge, Ruud from the lift.
func _to_upstairs(office: Office) -> OfficeOpening:
	var o := office.first_day
	assert_true(_until(office, func() -> bool: return o.lines.paper_up()), "the badge")
	o.lines.close_paper()
	assert_true(_until(office, func() -> bool: return o.guide != null), "Ruud comes")
	assert_eq(office.ui.session_layer.opening_beat, Opening.WALK)
	assert_true(_until(office, func() -> bool: return o._guide_route.is_empty() and not o.lines.speaking() \
		and o.guide.position.z < -9.0), "Ruud leads to the stairs")
	office.player.position = o.guide.position
	assert_true(_until(office, func() -> bool: return not o.guide.visible), "he goes up")
	office.floors.go_to("first", "stairs_up")
	assert_true(_until(office, func() -> bool: return office.ui.session_layer.has_floor_plan), "the plan on the landing")
	return o


func test_b2_the_ontvangst_yvonne_and_the_badge() -> void:
	var office := _named_opening()
	var o := office.first_day
	assert_eq(office.floors.floor_id, "ground", "the begane grond")
	assert_true(_until(office, _said(office, "Jij bent Noor, toch?")), "Yvonne knows your name from the photo")
	assert_true(_until(office, func() -> bool: return o.lines.paper_up()))
	assert_true(o.lines.texts().has("Noor") and o.lines.texts().has(OfficeOpening.BADGE_ROLE), "the badge: your name, your role")
	office.free()


func test_b3_ruud_leads_introduces_hands_the_plan_and_reaches_his_door() -> void:
	var office := _named_opening()
	var o := _to_upstairs(office)
	assert_true(office.minimap.wanted() or office.busy(), "the minimap comes with the plan")
	for key: String in ["sanne", "marco", "design", "door"]:
		var line: String = OfficeOpening.LINES[key][0][1]
		assert_true(_until(office, func() -> bool:
			if o._guide_route.is_empty():
				office.player.position = o.guide.position   # the player follows him
			return o.lines.current().get("text", "") == o.fill(line)), key)
	assert_true(_until(office, func() -> bool: return o.lines.asking()), "his whiteboard question")
	assert_eq(office.ui.session_layer.opening_beat, Opening.BOARD)
	assert_true(_said(office, "spanning").call())
	office.free()


func test_b3_walking_ahead_to_his_room_overtakes_the_walk() -> void:
	var office := _named_opening()
	var o := _to_upstairs(office)
	office.player.position = o._coach_door()
	assert_true(_until(office, _said(office, "Je vond het zelf")), "he catches up")
	assert_true(_until(office, func() -> bool: return o.lines.asking()))
	office.free()


func test_b4_to_b7_the_board_the_letter_the_evening_and_anouk() -> void:
	var office := _named_opening()
	var o := _to_upstairs(office)
	office.player.position = o._coach_door()
	assert_true(_until(office, func() -> bool: return o.lines.asking()))
	o.lines.pick(1)   # "Ik ken het, Ruud"
	assert_true(_until(office, func() -> bool: return o.lines.paper_up()), "the letter")
	assert_eq(office.ui.session_layer.opening_beat, Opening.LETTER)
	var letter := "\n".join(o.lines.texts())
	assert_true(letter.contains("F. El Amrani") and not letter.contains("{"), letter)
	assert_true(letter.contains(FollowedOrder.weeks_text(office.session.followed_order()["age_days"])), "the real weeks")
	o.lines.close_paper()
	assert_true(_until(office, func() -> bool: return office.ui.session_layer.opening_beat == Opening.ANOUK), "the day passes")
	assert_eq(office.session.minute_of_day(), OfficeOpening.EVENING_MINUTE, "19:02")
	assert_true(office.ui.hud.clock_label.visible, "the clock appears")
	assert_false(office.ui.hud.budget_label.visible)
	for p in office.people.people:
		assert_eq(p.visible, p.id == "anouk", "only one lamp on: " + p.id)
	var anouk := office.people.person("anouk")
	office.player.position = anouk.position + Vector3(4.0, 0, -2.0)
	assert_true(_until(office, func() -> bool: return office.ui.dialog_panel.visible), "she calls out as you pass")
	assert_true(shows(office.ui.dialog_panel, OfficeOpening.TALK_HINT.left(20)), "the one line under the meter")
	office.ui.dialog_panel.choose("mood")
	assert_false(shows(office.ui.dialog_panel, OfficeOpening.TALK_HINT.left(20)), "gone after the first move")
	office.ui.close_panels()
	office.ui.close_panels()
	assert_true(_until(office, func() -> bool: return office.ui.session_layer.opening_beat == Opening.DONE), "the scene ends")
	assert_true(office.first_day.lines.hint_text().begins_with(Phone.key_text()), "the phone key")
	assert_true(Opening.hud(office.session, office.ui.session_layer)["people"])
	assert_eq(office.session.minute_of_day(), GameSession.START_MINUTE, "the screen goes to Tuesday morning")
	assert_true(Opening.hud(office.session, office.ui.session_layer)["mission"], "Tuesday brings the mission line")
	office.free()


func test_b4_leg_maar_uit_opens_the_whiteboard_and_ruud_closes_it() -> void:
	var office := _named_opening()
	var o := _to_upstairs(office)
	office.player.position = o._coach_door()
	assert_true(_until(office, func() -> bool: return o.lines.asking()))
	o.lines.pick(0)
	assert_true(_until(office, func() -> bool: return office.explainer != null), "the explainer on his board")
	office.explainer.close()
	assert_true(_until(office, _said(office, "ergens zit weerstand")), "his close")
	office.free()


func test_a_returning_player_can_skip_the_week_at_the_door() -> void:
	var office := _named_opening()
	assert_true(_until(office, _said(office, "Jij bent Noor")))
	office.first_day.skip_week()
	office.first_day.step(0.1)
	assert_false(office.first_day.lines.holds(), "no line of the week left to hold you")
	assert_true(office.player.active, "you walk")
	assert_false(office.session.in_training())
	assert_eq(office.ui.session_layer.opening_beat, "")
	for element: String in Opening.ELEMENTS:
		assert_true(_shown(office)[element], element)
	office.free()


func test_the_beat_is_saved() -> void:
	var layer := SessionLayer.new()
	layer.opening_beat = Opening.LETTER
	var back := SessionLayer.new()
	back.load_dict(layer.to_dict())
	assert_eq(back.opening_beat, Opening.LETTER)
	back.load_dict({"opening_beat": "nonsense"})
	assert_eq(back.opening_beat, "", "junk reads as no opening")


## The toolbox grows through the week (place menu rework): on the opening's
## Monday a team's place offers questions only, no gemba tool.
func test_the_opening_offers_no_tools_before_they_are_granted() -> void:
	var office := _named_opening()
	for place: String in ["connections.intake", "connections.design"]:
		assert_eq(office.session.gemba.tools_at(place), [], "Monday is questions only: " + place)
	office.floors.go_to("first", "stairs_up", true)
	office.ui.open_place("connections.intake")
	for tool: String in Investigation.TOOLS:
		if tool != "conversation":
			assert_false(shows(office.ui.place_menu, UiText.tool_label(tool)), "no tool button: " + tool)
	office.free()


# ── Scenes that behave like scenes (PLAN 2.13 A) ────────────────────────────

func test_a_line_waits_for_the_player() -> void:
	var office := _named_opening()
	var o := office.first_day
	assert_true(_until(office, _said(office, "Jij bent Noor, toch?")))
	for i in 240:
		o.step(0.25)
	assert_true(_said(office, "Jij bent Noor, toch?").call(), "a minute later Yvonne's line is still up")
	o.lines.press()
	assert_false(_said(office, "Jij bent Noor, toch?").call(), "the player's key moves on")
	office.free()


func test_a_line_holds_the_player_and_frames_the_speaker() -> void:
	var office := _named_opening()
	var o := office.first_day
	assert_true(_until(office, _said(office, "Jij bent Noor, toch?")))
	o.step(0.1)
	assert_false(office.player.active, "no walking while Yvonne speaks")
	assert_false(office.rig.active, "no free camera")
	assert_true(office.rig.inspecting(), "the camera frames you and her")
	assert_false(office.click_floor(office.player.position + Vector3(2, 0, 0)), "no click-to-move")
	assert_true(_until(office, func() -> bool: return o.lines.paper_up()), "the badge")
	assert_true(o.lines.holds(), "a paper holds you too")
	o.lines.close_paper()
	assert_true(_until(office, func() -> bool: return o.guide != null and not o.lines.holds()), "Ruud's walk, between his lines")
	o.step(0.1)
	assert_true(office.player.active, "between lines you walk")
	assert_true(office.rig.active)
	office.free()


func test_the_first_scene_shows_how_to_skip() -> void:
	var office := _named_opening()
	var o := office.first_day
	assert_true(o.lines.texts().has(SceneLines.SKIP_HINT), "at the ontvangst")
	o.skip()
	assert_false(o.lines.texts().has(SceneLines.SKIP_HINT), "once is enough")
	office.free()


## Holding Spatie skips to the end of the beat on screen: the next place
## where the player acts (a choice, a walk, Anouk's talk).
func test_holding_space_skips_each_beat_to_its_end() -> void:
	var office := _named_opening()
	var o := office.first_day
	var layer := office.ui.session_layer
	o.lines.hold_space(true)
	o.step(SceneLines.HOLD_SKIP_S + 0.1)
	o.lines.hold_space(false)
	assert_eq(layer.opening_beat, Opening.WALK, "the ontvangst skipped: Ruud is here")
	assert_true(o.guide != null and not o.lines.paper_up())
	o.skip()
	assert_eq(layer.opening_beat, Opening.BOARD, "the walk skipped: at his door")
	assert_eq(office.floors.floor_id, "first")
	assert_true(layer.has_floor_plan, "the plan handed over")
	assert_true(o.lines.asking(), "his question waits: a choice is the player's")
	o.skip()
	assert_true(o.lines.asking(), "a choice is never skipped")
	o.lines.pick(1)
	o.skip()
	assert_eq(layer.opening_beat, Opening.LETTER, "his answer skipped: the letter")
	o.skip()
	assert_eq(layer.opening_beat, Opening.EVENING, "the letter skipped: the rest of the day")
	o.skip()
	assert_eq(layer.opening_beat, Opening.ANOUK, "the day skipped: the evening")
	assert_eq(office.session.minute_of_day(), OfficeOpening.EVENING_MINUTE)
	assert_false(o.lines.holds(), "you walk to the exit yourself")
	office.free()


func test_esc_during_a_line_pauses() -> void:
	var office := _named_opening()
	office.saves = SaveSlots.new(TestCase.scratch("opening_saves"))
	office.ui.saves = office.saves
	assert_true(_until(office, _said(office, "Jij bent Noor, toch?")))
	office.player.escape_pressed.emit()
	assert_true(office.ui.pause_menu.visible, "Esc pauses the scene")
	assert_true(_said(office, "Jij bent Noor, toch?").call(), "the line waits under it")
	office.player.escape_pressed.emit()
	office.free()


## Esc pauses the tree: the scene, its lines, the people and the walk stop;
## only the pause menu runs.
func test_the_pause_freezes_the_scene() -> void:
	var office := _named_opening()
	office.saves = SaveSlots.new(TestCase.scratch("opening_saves"))
	office.ui.saves = office.saves
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(office)
	office.ui.open_pause()
	assert_true(tree.paused, "the tree is paused")
	for n: Node in [office.first_day, office.first_day.lines, office.player, office.people, office.rig]:
		assert_false(n.can_process(), "frozen: " + n.name)
	assert_true(office.ui.pause_menu.can_process(), "the pause menu works")
	office.ui.pause_menu.close_requested.emit()
	assert_false(tree.paused, "Verder spelen")
	assert_true(office.first_day.can_process())
	tree.root.remove_child(office)
	tree.paused = false
	office.free()
