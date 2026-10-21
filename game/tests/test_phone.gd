extends TestCase
## The phone as hub (design 2026-10-21 §1.8, PLAN 2.14 S1-F): everything that
## was a panel over the world lives on the player's phone. Tab raises and
## lowers it, J/M/K open it on Notities/Kaart/Begrippen, Esc lowers it; each
## app opens by key and by tap; Ruud's notes arrive in Berichten with a buzz
## and a badge; the old panels never open on their own; the opening shows the
## phone at B6 and not before.

const SCENE := "res://src/world/office/office.tscn"


func _office(training := false) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = training
	office.build()
	return office


func _opening_office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.opening = true
	office.build()
	return office


func test_tab_raises_and_lowers_the_phone_and_pauses_the_world() -> void:
	var office := _office()
	var phone := office.ui.phone
	assert_false(phone.visible, "lowered at the start")
	office.player.phone_pressed.emit("")
	assert_true(phone.visible, "Tab raises it")
	assert_eq(phone.current, Phone.HOME, "on its home screen")
	assert_true(office.busy(), "the world waits")
	assert_false(office.player.active, "the player stands still")
	office.player.phone_pressed.emit("")
	assert_false(phone.visible, "Tab again lowers it")
	assert_true(office.player.active)
	office.free()


func test_the_phone_key_is_a_remappable_action_on_tab() -> void:
	Phone.ensure_action()
	assert_true(InputMap.has_action(Phone.ACTION))
	var keys := InputMap.action_get_events(Phone.ACTION).filter(func(e: InputEvent) -> bool:
		return e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_TAB)
	assert_eq(keys.size(), 1, "Tab by default")


func test_esc_lowers_the_phone() -> void:
	var office := _office()
	office.ui.toggle_phone(Phone.MAP)
	office.player.escape_pressed.emit()
	assert_false(office.ui.phone.visible, "Esc lowers it")
	assert_false(office.ui.paused(), "and does not pause the game")
	office.free()


func test_j_m_k_open_the_phone_on_their_app() -> void:
	var office := _office()
	var phone := office.ui.phone
	for pair: Array in [[Phone.NOTES, KEY_J], [Phone.MAP, KEY_M], [Phone.CODEX, KEY_K]]:
		office.player.phone_pressed.emit(pair[0])
		assert_true(phone.visible, "%s raises it" % pair[0])
		assert_eq(phone.current, pair[0])
		assert_true(phone.app(pair[0]).is_visible_in_tree() or not phone.is_inside_tree(), pair[0])
		assert_eq(Player.app_for_key(pair[1]), pair[0], "the key names its app")
	office.player.phone_pressed.emit(Phone.CODEX)
	assert_false(phone.visible, "the same key again lowers it")
	office.free()


func test_each_app_opens_by_tap_and_back_goes_home() -> void:
	var office := _office()
	var phone := office.ui.phone
	office.ui.toggle_phone()
	for id: String in Phone.APPS:
		phone.icon(id).pressed.emit()
		assert_eq(phone.current, id, "a tap opens " + id)
		assert_true(phone.app(id).visible, id)
		phone.back_button.pressed.emit()
		assert_eq(phone.current, Phone.HOME, "back to the home screen")
	office.free()


func test_the_old_panels_are_apps_now_and_never_open_on_their_own() -> void:
	var office := _office()
	var ui := office.ui
	for panel: UiPanel in [ui.journal, ui.office_map, ui.codex]:
		assert_false(panel in ui.panels(), "%s is no panel over the world" % panel.get_class())
		assert_true(phone_holds(ui.phone, panel), "it lives in the phone")
	for name: String in ["toggle_journal", "toggle_map", "toggle_codex"]:
		assert_false(ui.has_method(name), name + " is gone")
	ui.toggle_phone(Phone.NOTES)
	assert_true(ui.phone.visible and ui.journal.is_visible_in_tree() == ui.phone.is_inside_tree(), "J shows the clues on the phone")
	office.free()


func phone_holds(phone: Phone, node: Node) -> bool:
	return phone.is_ancestor_of(node)


func test_the_phone_waits_during_a_talk() -> void:
	var office := _office(true)
	assert_eq(office.ui.open_talk("anouk"), "", "Monday's talk")
	office.ui.toggle_phone(Phone.NOTES)
	assert_false(office.ui.phone.visible, "not mid-talk")
	office.free()


## Monday of the training week: Ruud's note lands in Berichten with a buzz and a
## badge; opening Berichten reads it.
func test_a_new_note_buzzes_and_badges_berichten() -> void:
	var office := _office(true)
	var ui := office.ui
	var phone := ui.phone
	assert_eq(phone.badge(Phone.MESSAGES), 1, "Ruud's Monday note waits")
	assert_true(ui.hud.phone_label.text.contains(Hud.PHONE_NEW % phone.unread_count()), "the bar shows what is new")
	var buzzes := {"n": 0}
	phone.buzz.connect(func() -> void: buzzes["n"] += 1)
	office.session.missions.done_once["training_mon"] = true
	ui.after_action()
	assert_eq(buzzes["n"], 0, "nothing new: no buzz")
	ui.toggle_phone(Phone.MESSAGES)
	var note: Dictionary = PhoneMessages.notes(office.session, ui.session_layer)[0]
	assert_true(shows(phone.app(Phone.MESSAGES), note["lines"][0]), "the note in Berichten")
	assert_eq(phone.badge(Phone.MESSAGES), 0, "read")
	assert_false(ui.hud.toast_texts().any(func(t: String) -> bool: return t.contains("briefje")), "no toast any more")
	office.free()


func test_the_next_note_buzzes_once() -> void:
	var office := _office(true)
	var ui := office.ui
	var buzzes := {"n": 0}
	ui.phone.buzz.connect(func() -> void: buzzes["n"] += 1)
	ui.session_layer.carded.append("training_tue")
	ui.after_action()
	assert_eq(buzzes["n"], 1, "Tuesday's note buzzes")
	ui.after_action()
	assert_eq(buzzes["n"], 1, "once")
	office.free()


## What buzzed before a save does not buzz again after the reload.
func test_a_buzz_is_not_repeated_after_a_reload() -> void:
	var office := _office(true)
	office.ui.session_layer.carded.append("training_tue")
	office.ui.after_action()
	var d := office.ui.session_layer.to_dict()
	var back := SessionLayer.new()
	back.load_dict(d)
	var phone := Phone.new()
	phone.setup(office.session, back)
	assert_false(phone.announce(), "already announced before the save")
	d.erase("announced")
	var old := SessionLayer.new()
	old.load_dict(d)
	var old_phone := Phone.new()
	old_phone.setup(office.session, old)
	assert_true(old_phone.announce(), "an old save buzzes once for what is unread")
	d["announced"] = [3, "x"]
	old.load_dict(d)
	assert_eq(old.announced, ["x"] as Array[String], "only names are kept")
	phone.free()
	old_phone.free()
	office.free()


## The opening's Monday (2.13 follow-up): the note waits through the scene and
## the phone buzzes when the scene is over.
func test_the_opening_monday_buzzes_after_the_scene() -> void:
	var office := _opening_office()
	var ui := office.ui
	var buzzes := {"n": 0}
	ui.phone.buzz.connect(func() -> void: buzzes["n"] += 1)
	ui.after_action()
	assert_eq(buzzes["n"], 0, "not during the scene")
	Opening.advance(ui.session_layer, Opening.DONE)
	ui.after_action()
	assert_eq(buzzes["n"], 1, "after it")
	assert_true(ui.phone.badge(Phone.MESSAGES) >= 1, "Ruud's note badges Berichten")
	office.free()


func test_the_opening_reveals_the_phone_at_b6_and_not_before() -> void:
	var office := _opening_office()
	var ui := office.ui
	var layer := ui.session_layer
	for beat: String in [Opening.ARRIVAL, Opening.WALK, Opening.BOARD, Opening.LETTER]:
		Opening.advance(layer, beat)
		assert_false(Opening.hud(office.session, layer)["phone"], "no phone at " + beat)
		ui.toggle_phone()
		assert_false(ui.phone.visible, "Tab does nothing at " + beat)
	Opening.advance(layer, Opening.EVENING)
	ui.after_action()
	assert_true(Opening.hud(office.session, layer)["phone"], "the phone at B6")
	ui.toggle_phone()
	assert_true(ui.phone.visible, "Tab raises it from B6")
	assert_true(ui.phone.icon(Phone.MESSAGES).visible, "Berichten from B6: the day's messages")
	assert_false(ui.phone.icon(Phone.MAP).visible, "the map comes on Tuesday")
	assert_false(ui.phone.icon(Phone.MISSIONS).visible, "Opdrachten with the board, on Tuesday")
	ui.close_panels()
	ui.toggle_phone(Phone.MAP)
	assert_false(ui.phone.visible and ui.phone.current == Phone.MAP, "M waits for the map's day")
	office.free()


func test_the_evening_messages_land_in_berichten() -> void:
	var office := _opening_office()
	var ui := office.ui
	Opening.advance(ui.session_layer, Opening.EVENING)
	ui.after_action()
	ui.toggle_phone(Phone.MESSAGES)
	assert_true(shows(ui.phone.app(Phone.MESSAGES), OfficeOpening.PHONE[0][2]), "the IT Servicedesk's message")
	office.free()


## The training day's concepts no longer show as a card over the world: the
## Begrippen app badges them.
func test_new_concepts_badge_begrippen_instead_of_a_card() -> void:
	var office := _office(true)
	var ui := office.ui
	assert_false("card_texts" in ui.hud, "no cards over the world")
	assert_true(ui.phone.badge(Phone.CODEX) > 0, "Monday's concepts wait in Begrippen")
	ui.toggle_phone(Phone.CODEX)
	assert_eq(ui.phone.badge(Phone.CODEX), 0, "seen")
	office.free()


func test_opdrachten_lists_the_active_and_the_board_read_only() -> void:
	var office := _office()
	var s := office.session
	var ui := office.ui
	ui.toggle_phone(Phone.MISSIONS)
	var app := ui.phone.app(Phone.MISSIONS)
	for m: MissionDef in s.available_missions():
		assert_true(shows(app, UiText.mission_title(m, s)), "on the board: " + m.id)
	assert_false(_buttons(app).any(func(t: String) -> bool: return t == "Aannemen"), "accepting is at the board")
	assert_true(shows(app, MissionsApp.AT_THE_BOARD), "says where to take one on")
	assert_eq(s.accept("fix_custom_design"), "")
	app.refresh()
	assert_true(shows(app, UiText.mission_title(s.missions.defs["fix_custom_design"], s)), "the active main")
	office.free()


func test_wie_is_wie_holds_the_people_you_know() -> void:
	var office := _office()
	var ui := office.ui
	ui.toggle_phone(Phone.PEOPLE)
	assert_true(shows(ui.phone.app(Phone.PEOPLE), PeopleApp.NOBODY), "no one yet")
	office.free()


func test_instellingen_holds_the_text_and_log_switches() -> void:
	var office := _office()
	var ui := office.ui
	ui.settings_path = scratch("test_phone_settings.cfg")
	ui.toggle_phone(Phone.SETTINGS)
	var app := ui.phone.app(Phone.SETTINGS)
	app.refresh()
	assert_true(_buttons(app).has(SceneLines.AUTO_LABEL), "Tekst loopt vanzelf door")
	assert_true(_buttons(app).has(SettingsApp.LOG), "the playtest log")
	assert_true(_buttons(app).has(Soundscape.MUTE_LABEL), "Geluid uit")
	assert_eq(app.find_children("*", "HSlider", true, false).size(), 1, "the volume")
	office.free()


func test_a_buzz_plays_the_phone_sound() -> void:
	var office := _office()
	var before := office.sound.get_child_count()
	office.ui.phone.buzz.emit()
	assert_eq(office.sound.get_child_count(), before + (0 if Soundscape.muted() else 1), "the buzz under the soundscape")
	office.free()


func test_the_lift_opens_the_map_as_its_floor_switch() -> void:
	var office := _office()
	office.ui.open_lift()
	assert_true(office.ui.phone.visible and office.ui.phone.current == Phone.MAP)
	assert_true(office.ui.office_map.lift)
	office.free()


## Every string on the phone's own screens goes through tr().
func test_every_phone_string_is_translated() -> void:
	var t := Translation.new()
	t.locale = "en"
	var mine: Array[String] = []
	for id: String in Phone.APPS:
		mine.append(Phone.NAMES[id])
	mine.append_array([Phone.BACK, Phone.HOME_TITLE, MissionsApp.AT_THE_BOARD, MissionsApp.ACTIVE, MissionsApp.ON_THE_BOARD,
		PhoneMessages.NONE, SettingsApp.LOG, Hud.PHONE])
	for msg in mine:
		t.add_message(msg, "«%s»" % msg)
	TranslationServer.add_translation(t)
	TranslationServer.set_locale("en")
	var office := _office()
	var ui := office.ui
	ui.toggle_phone()
	for id: String in Phone.APPS:
		assert_true(shows(ui.phone.icon(id), "«%s»" % Phone.NAMES[id]), id)
	ui.phone.open_app(Phone.MISSIONS)
	assert_true(shows(ui.phone, "«%s»" % Phone.NAMES[Phone.MISSIONS]), "the app's title")
	assert_true(shows(ui.phone, "«%s»" % MissionsApp.AT_THE_BOARD))
	assert_true(ui.hud.phone_label.text.contains("«%s»" % Hud.PHONE), "the bar's phone")
	TranslationServer.remove_translation(t)
	TranslationServer.set_locale("nl")
	office.free()


## The inbox is saved with the session layer and read back untrusted.
func test_the_inbox_survives_a_save_and_junk_is_dropped() -> void:
	var layer := SessionLayer.new()
	PhoneMessages.push(layer, "debrief:training_wed", 100, {"queues": {"connections.intake": 12}})
	layer.inbox[0]["read"] = true
	var back := SessionLayer.new()
	back.load_dict(layer.to_dict())
	assert_eq(back.inbox, layer.inbox, "as saved")
	var d := layer.to_dict()
	d["inbox"] = [{"id": 3}, "x", {"id": "week_end", "at": 5, "read": false, "queues": {"a": "b"}}]
	back.load_dict(d)
	assert_eq(back.inbox, [{"id": "week_end", "at": 5, "read": false}] as Array[Dictionary], "only whole messages")
	assert_true(back.phone_saved)


## A save from before the phone opens without a pile of badges.
func test_an_old_save_opens_with_its_notes_read() -> void:
	var office := _office(true)
	var d := office.ui.session_layer.to_dict()
	d.erase("inbox")
	d.erase("concepts_seen")
	var layer := SessionLayer.new()
	layer.load_dict(d)
	assert_false(layer.phone_saved)
	var resumed := GameUI.new()
	resumed.setup(office.session, layer)
	assert_eq(resumed.phone.unread_count(), 0, "all read")
	assert_eq(layer.inbox.size(), 1, "Monday's note is there")
	resumed.free()
	office.free()


func _buttons(root: Node) -> Array[String]:
	var out: Array[String] = []
	for n in root.find_children("*", "Button", true, false):
		out.append((n as Button).text)
	return out
