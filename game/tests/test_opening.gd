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
	for l: Control in [hud.clock_label, hud.budget_label, hud.xp_label, hud.mission_label, hud.help_label]:
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


func test_the_clock_comes_with_the_evening_and_the_journal_after_the_talk() -> void:
	var office := _opening_office()
	var layer := office.ui.session_layer
	Opening.advance(layer, Opening.ANOUK)
	office.ui.after_action()
	assert_true(_shown(office)["clock"], "the first time time has passed")
	assert_true(office.ui.hud.clock_label.visible)
	assert_false(_shown(office)["journal"])
	Opening.advance(layer, Opening.DONE)
	assert_true(_shown(office)["journal"], "the first thing worth remembering")
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
	office.ui.toggle_journal()
	office.ui.toggle_map()
	office.ui.toggle_codex()
	assert_false(office.ui.is_busy(), "J, M and K wait for their moment")
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

## Step the scene until `done` holds (or a minute of game frames passes).
func _until(office: Office, done: Callable, seconds := 240.0) -> bool:
	var t := 0.0
	while not done.call() and t < seconds:
		office.first_day.step(0.25)
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
	assert_true(office.first_day.lines.hint_text().begins_with("J"), "the journal key")
	assert_true(Opening.hud(office.session, office.ui.session_layer)["journal"])
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
	office.first_day.skip_week()
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
