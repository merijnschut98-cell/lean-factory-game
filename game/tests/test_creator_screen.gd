extends TestCase
## The character creator's screen and flow (PLAN 2.7b; spec
## 2026-10-16-creator-and-minimap §1, tests §4.1 1, 5–9, 12, 13), headless:
## HR's mail, the phone camera with one trait at a time, Willekeurig, the first
## name, "Zo is het goed" and "Foto maken"; "Nieuw spel" goes through it, and
## the pause menu's "Uiterlijk" changes look and name without a trace in the
## game. The badge photo needs a renderer: headless it is the placeholder.

const SCENE := "res://src/world/office/office.tscn"
const SOURCE := "res://src/ui/creator/creator_screen.gd"

var dir := TestCase.scratch("creator_saves")


func _cleanup() -> void:
	SaveSlots.new(dir).wipe()
	DirAccess.remove_absolute(dir)


func _screen(mode := CreatorScreen.Mode.NEW, from: PlayerProfile = null, seed_value := 7) -> CreatorScreen:
	var screen := CreatorScreen.new()
	screen.setup(mode, from, seed_value)
	screen.build()
	return screen


## The camera open (past the mail) on a new player.
func _camera(seed_value := 7) -> CreatorScreen:
	var screen := _screen(CreatorScreen.Mode.NEW, null, seed_value)
	screen.open_camera()
	return screen


func _done(screen: CreatorScreen) -> Array[PlayerProfile]:
	var made: Array[PlayerProfile] = []
	screen.done.connect(func(p: PlayerProfile) -> void: made.append(p))
	return made


static func _valid(look: Dictionary) -> bool:
	return look == CreatorLook.normalized(look)


# ── The strip and the options (§4.1 test 1) ────────────────────────────────

func test_the_strip_is_the_name_then_the_files_traits_in_order() -> void:
	var screen := _camera()
	var ids: Array[String] = [CreatorScreen.NAME_STEP]
	for t in CreatorLook.traits():
		ids.append(t["id"])
	assert_eq(screen.steps, ids)
	assert_true(shows(screen, CreatorScreen.NAME_LABEL), "Je voornaam")
	for t in CreatorLook.traits():
		assert_true(shows(screen, t["label"]), "the file's label %s" % t["label"])
	screen.free()


func test_every_option_the_screen_offers_has_two_to_five_and_resolves() -> void:
	var screen := _camera()
	for body: String in ["man", "vrouw"]:
		screen.choose_in(CreatorLook.BODY, body)
		var b := CreatorLook.body_of(screen.profile.look)
		for t in CreatorLook.traits():
			if t["id"] == CreatorLook.BODY:
				continue  # choosing a body changes the lists; the loop above walks both
			var offered := screen.offered(t["id"])
			var own: int = (t["per_body"][b] as Array).size() if t.get("per_body") is Dictionary else offered.size()
			assert_between(own, 2, 5, "%s on %s" % [t["id"], body])
			for option in offered:
				screen.choose_in(t["id"], option["id"])
				assert_eq(screen.profile.look[t["id"]], option["id"], "%s: %s is chosen" % [t["id"], option["id"]])
				assert_eq(CreatorLook.option(t["id"], option["id"], b)["id"], option["id"], "and resolves")
	screen.free()


func test_kapsel_lists_the_bodys_own_five_first_then_the_others() -> void:
	var screen := _camera()
	screen.choose_in(CreatorLook.BODY, "vrouw")
	var hair := screen.offered("kapsel").map(func(o: Dictionary) -> String: return o["id"])
	assert_eq(hair.size(), 10, "any style on either body")
	assert_eq(hair.slice(0, 5), CreatorLook.options("kapsel", "f").slice(0, 5).map(func(o: Dictionary) -> String: return o["id"]))
	screen.free()


# ── Body, Willekeurig, the opening look (§4.1 tests 5–7) ───────────────────

func test_a_body_change_resets_the_face_and_keeps_the_rest() -> void:
	var look := CreatorLook.normalized({"lichaam": "man", "gezicht": "volle_baard", "kapsel": "curtains",
		"huidskleur": "bruin", "haarkleur": "zwart", "ogen": "groen", "bril": "transparant", "kleding": "blazer"})
	var changed := CreatorScreen.with_body(look, "vrouw")
	assert_eq(changed["lichaam"], "vrouw")
	assert_eq(changed["gezicht"], CreatorLook.options("gezicht", "f")[0]["id"])
	for keep: String in ["huidskleur", "kapsel", "haarkleur", "ogen", "bril", "kleding"]:
		assert_eq(changed[keep], look[keep], keep)
	assert_eq(CreatorScreen.with_body(look, "man"), look, "the same body changes nothing")


func test_willekeurig_never_touches_name_or_body_and_stays_in_the_file() -> void:
	var screen := _camera()
	screen.type_name("Sanne")
	var body: String = screen.profile.look[CreatorLook.BODY]
	var seen := {}
	for i in 1000:
		screen.randomize_look()
		assert_eq(screen.profile.look[CreatorLook.BODY], body)
		assert_eq(screen.name_text, "Sanne")
		if not _valid(screen.profile.look):
			assert_true(false, "draw %d not in the file: %s" % [i, screen.profile.look])
			break
		seen[screen.profile.look["kapsel"]] = true
	assert_eq(seen.size(), 10, "every hairstyle comes up, from both lists")
	screen.free()


func test_the_creator_opens_on_a_random_valid_look() -> void:
	var looks := []
	var bodies := {}
	for seed_value in range(1, 21):
		var screen := _screen(CreatorScreen.Mode.NEW, null, seed_value)
		assert_true(_valid(screen.profile.look))
		looks.append(screen.profile.look)
		bodies[screen.profile.look[CreatorLook.BODY]] = true
		screen.free()
	assert_ne(looks[0], looks[1], "two creators differ")
	assert_eq(bodies.size(), 2, "both bodies come up")


# ── The mail, the name, the shutter (§1.1, §4.1 test 8) ────────────────────

func test_a_new_game_opens_on_hrs_mail_and_esc_there_goes_back() -> void:
	var screen := _screen()
	assert_eq(screen.stage, CreatorScreen.Stage.MAIL)
	assert_true(shows(screen, CreatorScreen.MAIL_SUBJECT))
	assert_true(shows(screen, CreatorScreen.MAIL_BUTTON))
	var cancelled := []
	screen.cancelled.connect(func() -> void: cancelled.append(true))
	screen.press(KEY_ESCAPE)
	assert_eq(cancelled, [true], "nothing was made, nothing asks")
	screen.free()


func test_zo_is_het_goed_without_a_name_asks_once_and_the_shutter_waits() -> void:
	var screen := _camera()
	screen.go_to(3)
	assert_true(screen.shutter.disabled, "no name, no photo")
	screen.good_as_is()
	assert_eq(screen.step_id(), CreatorScreen.NAME_STEP, "back to the name")
	assert_true(shows(screen, CreatorScreen.ASK_NAME))
	screen.go_to(2)
	screen.good_as_is()
	assert_false(shows(screen, CreatorScreen.ASK_NAME), "asked once")
	screen.type_name("bo")
	assert_false(screen.shutter.disabled)
	screen.go_to(2)
	screen.good_as_is()
	assert_true(screen.at_shutter, "jumps to the shutter")
	var made := _done(screen)
	screen.press(KEY_ENTER)
	assert_eq(made.size(), 1, "Enter at the shutter takes the photo")
	assert_eq(made[0].name, "Bo", "the name as confirmed")
	assert_eq(made[0].portrait, PackedByteArray(), "headless: the placeholder")
	screen.free()


func test_the_name_field_keeps_only_name_characters_and_says_why() -> void:
	var screen := _camera()
	screen.type_name("Jan{b}2")
	assert_eq(screen.name_text, "Janb")
	assert_true(shows(screen, CreatorScreen.ONLY_LETTERS))
	screen.type_name("Abcdefghijklmnopqrs")
	assert_eq(screen.name_text.length(), PlayerProfile.MAX_NAME)
	assert_true(shows(screen, CreatorScreen.TOO_LONG))
	screen.free()


func test_the_badge_preview_shows_the_typed_name() -> void:
	var screen := _camera()
	screen.type_name("Zoë")
	assert_true(shows(screen, "Zoë"))
	assert_true(shows(screen, CreatorScreen.BADGE_ROLE))
	screen.free()


func test_the_selected_options_name_is_always_printed() -> void:
	var screen := _camera()
	screen.go_to(screen.steps.find("ogen"))
	screen.choose_in("ogen", "groen")
	assert_true(shows(screen, "Groen"), "a colour-blind player reads the name")
	screen.free()


# ── Keyboard only (§1.3, §4.1 test 9) ──────────────────────────────────────

func test_keyboard_only_reaches_the_photo_with_the_chosen_look() -> void:
	var screen := _camera(3)
	var made := _done(screen)
	assert_eq(screen.step_id(), CreatorScreen.NAME_STEP, "the camera opens on the name")
	screen.focus_name()
	for key: Key in [KEY_S, KEY_D, KEY_W, KEY_R, KEY_Z]:
		assert_false(screen.press(key), "letters type in the name field")
	assert_eq(screen.step_id(), CreatorScreen.NAME_STEP)
	screen.type_name("Sanne")
	screen.press(KEY_ENTER)  # Volgende: leaves the field
	assert_eq(screen.step_id(), CreatorLook.BODY)
	assert_false(screen.typing)
	screen.choose_in(CreatorLook.BODY, "man")
	screen.press(KEY_RIGHT)
	assert_eq(screen.profile.look[CreatorLook.BODY], "vrouw", "→ the next option")
	screen.press(KEY_S)
	assert_eq(screen.step_id(), "huidskleur", "S the next trait")
	screen.press(KEY_UP)
	assert_eq(screen.step_id(), CreatorLook.BODY, "↑ the previous trait")
	screen.press(KEY_DOWN)
	var skin: String = screen.profile.look["huidskleur"]
	screen.press(KEY_A)
	assert_ne(screen.profile.look["huidskleur"], skin, "A the previous option")
	var chosen := screen.profile.look.duplicate()
	while screen.step < screen.steps.size() - 1:
		screen.press(KEY_ENTER)
	assert_eq(screen.step_id(), "kleding")
	assert_true(made.is_empty())
	screen.press(KEY_ENTER)  # on the last trait: Foto maken
	assert_eq(made.size(), 1)
	assert_eq(made[0].look, chosen)
	assert_eq(made[0].name, "Sanne")
	screen.free()


func test_r_draws_a_random_look_and_esc_asks_once_before_leaving() -> void:
	var screen := _camera()
	screen.go_to(1)
	var before := screen.profile.look.duplicate()
	screen.press(KEY_R)
	assert_ne(screen.profile.look, before)
	var cancelled := []
	screen.cancelled.connect(func() -> void: cancelled.append(true))
	screen.press(KEY_ESCAPE)
	assert_eq(screen.stage, CreatorScreen.Stage.LEAVING)
	assert_true(shows(screen, CreatorScreen.LEAVE_ASK))
	screen.press(KEY_ESCAPE)
	assert_eq(screen.stage, CreatorScreen.Stage.CAMERA, "Esc again: stay")
	screen.press(KEY_ESCAPE)
	screen.leave()
	assert_eq(cancelled, [true])
	screen.free()


func test_z_and_c_turn_the_model() -> void:
	var screen := _camera()
	screen.turn_by(0.5)
	assert_near(screen.booth.turntable.rotation.y, 0.5, 0.001)
	screen.free()


func test_the_framing_follows_the_trait() -> void:
	var screen := _camera()
	screen.go_to(screen.steps.find("ogen"))
	assert_true(screen.booth.close_up, "eyes: head and shoulders")
	screen.go_to(screen.steps.find("kleding"))
	assert_false(screen.booth.close_up, "clothes: from the knees up")
	screen.free()


# ── "Nieuw spel" and "Uiterlijk" (§1.8–§1.9, §4.1 test 12) ─────────────────

func _office(player: PlayerProfile = null) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.saves = SaveSlots.new(dir)
	office.new_player = player
	office.build()
	return office


func _profile() -> PlayerProfile:
	var p := PlayerProfile.new()
	p.name = "Sanne"
	p.look = CreatorLook.normalized({"lichaam": "vrouw", "bril": "groot_rond", "kapsel": "lob"})
	return p


func test_a_new_game_starts_with_the_made_player_wearing_the_look() -> void:
	var menu := TitleMenu.new()
	menu.saves = SaveSlots.new(dir)
	menu.build()
	var office := menu.open_game("", _profile())
	office.build()
	assert_eq(office.session.player.name, "Sanne")
	assert_true(office.player.avatar.find_child("glasses_large_f", true, false) != null, "the made look, not player.glb")
	office.free()
	menu.free()


func test_nieuw_spel_opens_the_creator_first() -> void:
	var menu := TitleMenu.new()
	menu.saves = SaveSlots.new(dir)
	menu.build()
	var creator := menu.open_creator()
	assert_true(creator != null and creator.get_parent() == menu)
	assert_eq(creator.stage, CreatorScreen.Stage.MAIL)
	creator.cancelled.emit()
	assert_true(menu.creator == null, "Esc on the mail: back to the menu")
	menu.free()


func test_uiterlijk_is_in_the_pause_menu_between_opslaan_and_the_title() -> void:
	var menu := PauseMenu.new()
	menu.open()
	menu.refresh()
	var labels := menu.body.get_children().map(func(b: Node) -> String: return b.text if b is Button else "")
	assert_eq(labels.find(PauseMenu.LOOK), labels.find(PauseMenu.SAVE) + 1)
	assert_eq(labels.find(PauseMenu.TO_TITLE), labels.find(PauseMenu.LOOK) + 1)
	var asked := []
	menu.look_requested.connect(func() -> void: asked.append(true))
	menu.ask_look()
	assert_eq(asked, [true])
	menu.free()


static func _game_state(s: GameSession) -> PackedByteArray:
	return var_to_bytes({"region": RegionState.capture(s.region), "missions": s.missions.to_dict(),
		"people": s.people.to_dict(), "discoveries": s.discoveries.to_dict(), "time": s.region.net.time})


func test_uiterlijk_changes_look_and_name_and_nothing_else() -> void:
	var office := _office(_profile())
	var before := _game_state(office.session)
	var screen := office.open_look()
	assert_true(office.busy(), "the world waits")
	assert_eq(screen.mode, CreatorScreen.Mode.EDIT)
	assert_eq(screen.stage, CreatorScreen.Stage.CAMERA, "no mail")
	assert_eq(screen.profile.look, office.session.player.look, "opens on the current look")
	assert_eq(screen.name_text, "Sanne", "the name is editable")
	assert_true(shows(screen, CreatorScreen.NEW_PHOTO))
	screen.choose_in(CreatorLook.BODY, "man")
	screen.choose_in("bril", "geen")
	screen.type_name("Sem")
	screen.shoot()
	assert_eq(office.session.player.name, "Sem")
	assert_eq(office.session.player.look[CreatorLook.BODY], "man")
	assert_eq(office.session.player.fill("{hij_zij}"), "hij", "every later line follows the body")
	assert_true(office.player.avatar.find_child("glasses_large_f", true, false) == null, "the old look is gone")
	assert_eq(_game_state(office.session), before, "no time, money, trust or mission moved")
	assert_false(office.busy(), "the world back")
	var slots := SaveSlots.new(dir)
	assert_eq(slots.save(1, office.session, office.ui.session_layer), "")
	assert_eq(slots.entry("slot_1")["name"], "Sem", "the save card follows")
	office.free()
	_cleanup()


func test_uiterlijk_esc_asks_to_throw_the_changes_away() -> void:
	var office := _office(_profile())
	var screen := office.open_look()
	screen.type_name("Sem")
	screen.press(KEY_ESCAPE)
	assert_true(shows(screen, CreatorScreen.DISCARD_ASK))
	screen.leave()
	assert_eq(office.session.player.name, "Sanne", "nothing changed")
	assert_false(office.busy())
	office.free()


# ── Text (§1.10, §4.1 test 13) ─────────────────────────────────────────────

func test_every_dutch_string_on_the_screen_is_a_constant_shown_through_tr() -> void:
	var source := FileAccess.get_file_as_string(SOURCE)
	assert_false(source.is_empty())
	var literal := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var word := RegEx.create_from_string("\\p{L}{3}")
	for line in source.split("\n"):
		var code := line.strip_edges()
		if code.begins_with("#") or code.begins_with("const ") or code.begins_with("##"):
			continue
		for m in literal.search_all(code):
			var text := m.get_string(1)
			if (text.contains(" ") or text.contains("…")) and word.search(text) != null:
				assert_true(false, "a UI string outside a constant: %s" % code)
	var consts := RegEx.create_from_string("(?m)^const ([A-Z_]+) := \"\\p{Lu}")  # the UI's sentences
	for m in consts.search_all(source):
		var name := m.get_string(1)
		assert_true(source.contains("tr(%s)" % name), "%s goes through tr()" % name)
