extends TestCase
## The title menu and the pause menu (PLAN 2.7), headless: the saves listed
## most recently used first, continue / new game / wipe behind one
## confirmation; Esc opens the pause menu, which saves into a slot and asks
## once before overwriting; the game continued from a slot saves itself into
## the autosave only. Each test has its own saves folder (TestCase.scratch).

const SCENE := "res://src/world/office/office.tscn"

var dir := TestCase.scratch("menu_saves")
var clock := 5000.0


func _slots() -> SaveSlots:
	var slots := SaveSlots.new(dir)
	slots.now = func() -> float: return clock
	return slots


func _session(days := 0) -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	if days > 0:
		s.region.advance_days(days)
	return s


func _cleanup() -> void:
	SaveSlots.new(dir).wipe()
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))  # the playtest log
	DirAccess.remove_absolute(dir)


func _menu() -> TitleMenu:
	var menu := TitleMenu.new()
	menu.saves = _slots()
	menu.build()
	return menu


## The office playing from `slot` (SaveSlots.names(), "" new) in this
## test's folder, built outside the tree.
func _office(slot: String) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.saves = _slots()
	office.play(slot)
	office.build()
	return office


func _listed(menu: TitleMenu) -> Array:
	return menu.list.get_children().map(func(c: Node) -> String: return c.get_meta("slot"))


func test_the_title_menu_lists_saves_most_recently_used_first() -> void:
	var slots := _slots()
	for n in [2, 4]:
		clock += 10.0
		assert_eq(slots.save(n, _session(n), SessionLayer.new()), "")
	clock += 10.0
	assert_eq(slots.autosave(_session(1), SessionLayer.new()), "")
	var menu := _menu()
	assert_eq(_listed(menu), ["autosave", "slot_4", "slot_2"])
	assert_true(shows(menu, "Automatisch opgeslagen"))
	assert_true(shows(menu, "Slot 4"))
	assert_true(shows(menu, "Akte I · De eerste honderd dagen"), "the act")
	assert_true(shows(menu, GameSession.clock_at(_session(4).region.net.time)), "the game's date")
	assert_true(shows(menu, "Opgeslagen "), "the real save time")
	menu.free()
	_cleanup()


func test_picking_a_save_continues_from_it_and_new_game_touches_nothing() -> void:
	var slots := _slots()
	assert_eq(slots.save(3, _session(), SessionLayer.new()), "")
	var before := FileAccess.get_file_as_bytes(SaveFile.path_of("slot_3", dir))
	var menu := _menu()
	var asked: Array[String] = []
	menu.start_requested.connect(func(slot: String) -> void: asked.append(slot))
	menu.list.button_for("slot_3").pressed.emit()
	menu.new_game()
	assert_eq(asked, ["slot_3", ""])
	assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of("slot_3", dir)), before, "a new game leaves the saves alone")
	assert_eq(menu.saves.entries().size(), 1)
	menu.free()
	_cleanup()


func test_a_save_that_cannot_be_played_says_why_and_has_no_button() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(SaveFile.path_of("slot_1", dir), FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"version": 0, "region": {}}))
	file.close()
	file = FileAccess.open(SaveFile.path_of("slot_2", dir), FileAccess.WRITE)
	file.store_buffer("kapot".to_utf8_buffer())
	file.close()
	var menu := _menu()
	assert_true(shows(menu, "Te oud voor deze versie"))
	assert_true(shows(menu, "Beschadigd"))
	assert_eq(menu.list.button_for("slot_1"), null)
	assert_eq(menu.list.button_for("slot_2"), null)
	menu.free()
	_cleanup()


func test_alles_wissen_asks_once_then_deletes_every_save() -> void:
	var slots := _slots()
	assert_eq(slots.save(1, _session(), SessionLayer.new()), "")
	assert_eq(slots.autosave(_session(), SessionLayer.new()), "")
	var menu := _menu()
	menu.ask_wipe()
	assert_eq(slots.entries().size(), 2, "asking deletes nothing")
	assert_true(shows(menu, "Alle opgeslagen spellen wissen?"))
	menu.cancel()
	assert_eq(slots.entries().size(), 2, "cancelled")
	menu.ask_wipe()
	menu.confirm_wipe()
	assert_eq(slots.entries(), [])
	assert_eq(menu.list.get_child_count(), 0)
	assert_true(shows(menu, "Nog geen opgeslagen spel"))
	menu.free()
	_cleanup()


func test_instellingen_is_a_stub_for_now() -> void:
	var menu := _menu()
	menu.open_settings()
	assert_true(shows(menu, "Instellingen"))
	assert_true(shows(menu, "komen later"))
	menu.cancel()
	assert_true(shows(menu, "Nieuw spel"))
	menu.free()
	_cleanup()


func test_esc_with_nothing_open_opens_the_pause_menu() -> void:
	var office := _office("")
	office.player.escape_pressed.emit()
	assert_true(office.ui.pause_menu.visible, "Esc pauses")
	assert_true(shows(office.ui.pause_menu, "Opslaan"))
	office.player.escape_pressed.emit()
	assert_false(office.ui.is_busy(), "the next Esc closes it")
	office.ui.open_mission_board()
	office.player.escape_pressed.emit()
	assert_false(office.ui.pause_menu.visible, "Esc on a panel closes the panel, no pause")
	office.free()
	_cleanup()


func test_the_pause_menu_saves_into_a_slot_and_asks_once_before_overwriting() -> void:
	var office := _office("")
	var pause := office.ui.pause_menu
	office.ui.open_pause()
	pause.show_slots()
	assert_eq(pause.list.get_child_count(), SaveSlots.COUNT, "five slots, no autosave among them")
	assert_true(shows(pause, "Leeg"))
	pause.list.button_for("slot_2").pressed.emit()
	assert_false(office.saves.entry("slot_2").is_empty(), "an empty slot saves at once")
	assert_true(office.ui.hud.toast_texts().any(func(t: String) -> bool: return t.contains("slot 2")))
	var first := FileAccess.get_file_as_bytes(SaveFile.path_of("slot_2", dir))
	office.session.region.advance_days(2)
	office.ui.open_pause()
	pause.show_slots()
	pause.pick(2)
	assert_eq(pause.page, PauseMenu.Page.CONFIRM, "a filled slot asks")
	assert_true(shows(pause, "Overschrijven?"))
	assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of("slot_2", dir)), first, "not yet overwritten")
	pause.back()
	assert_eq(pause.page, PauseMenu.Page.SLOTS)
	pause.pick(2)
	pause.confirm()
	assert_eq(office.saves.resume("slot_2")["session"].region.net.time, office.session.region.net.time, "overwritten")
	assert_false(office.ui.is_busy(), "saved, the menu closes")
	office.free()
	_cleanup()


func test_a_game_continued_from_a_slot_autosaves_apart_from_it() -> void:
	var slots := _slots()
	var saved := _session(5)
	assert_eq(slots.save(2, saved, SessionLayer.new()), "")
	var before := FileAccess.get_file_as_bytes(SaveFile.path_of("slot_2", dir))
	var office := _office("slot_2")
	assert_eq(office.session.region.net.time, saved.region.net.time, "continued from slot 2")
	office.session.region.advance_days(1)
	office.ui.end_session()
	assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of("slot_2", dir)), before, "slot 2 untouched")
	assert_eq(slots.resume("autosave")["session"].region.net.time, office.session.region.net.time,
		"the autosave holds the game")
	office.free()
	_cleanup()


func test_tests_and_tools_never_pause_into_saving() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	office.player.escape_pressed.emit()
	assert_false(office.ui.pause_menu.visible, "a game that does not save has no pause menu")
	office.free()
