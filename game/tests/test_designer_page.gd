extends TestCase
## The Ontwerper page on the title menu (Phase 3 slice 3.0): with the designer flag on it lists
## the designer saves (tools/make_saves.gd) with their play day, marks one made on old content,
## and starts one by copying it into the autosave. Short runs into a scratch folder of their own.

var designer_dir := TestCase.scratch("designer_saves")
var saves_dir := TestCase.scratch("designer_menu")


func _cleanup() -> void:
	Designer.force(null)
	for folder: String in [designer_dir, saves_dir]:
		if DirAccess.dir_exists_absolute(folder):
			for file: String in DirAccess.get_files_at(folder):
				DirAccess.remove_absolute(folder.path_join(file))
			DirAccess.remove_absolute(folder)


func _menu() -> TitleMenu:
	var menu := TitleMenu.new()
	menu.saves = SaveSlots.new(saves_dir)
	menu.designer_dir = designer_dir
	menu.build()
	return menu


## A designer save for `day` made on the content `hash` ("" the current content).
func _save(slot: String, day: int, hash := "") -> void:
	if hash.is_empty():
		assert_eq(MakeSaves.write({"slot": slot, "stop_day": float(day)}, "expert", 11, designer_dir), "")
		return
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.region.advance_days(day)
	var designer := {"persona": "expert", "seed": 11, "stop_day": float(day), "content_hash": hash}
	assert_eq(GameSave.write(slot, s, SessionLayer.new(), designer_dir, 0.0, {"designer": designer}), "")


func test_designer_page_hidden_when_disabled() -> void:
	Designer.force(false)
	var menu := _menu()
	assert_false(shows(menu, TitleMenu.DESIGNER), "no Ontwerper button without the flag")
	menu.free()
	Designer.force(true)
	menu = _menu()
	assert_true(shows(menu, TitleMenu.DESIGNER), "the flag shows it")
	menu.free()
	_cleanup()


func test_designer_entries_list_saves_with_day() -> void:
	_save("designer_t2", 4)
	_save("designer_t1", 3)
	var page := DesignerPage.new()
	page.dir = designer_dir
	var entries := page.entries()
	assert_eq(entries.map(func(e: Dictionary) -> String: return e["slot"]), ["designer_t1", "designer_t2"], "earliest day first")
	assert_eq(entries.map(func(e: Dictionary) -> int: return e["play_day"]), [3, 4])
	assert_eq(entries[0]["persona"], "expert")
	assert_eq(entries[0]["seed"], 11)
	assert_false(entries[0]["stale"])
	page.free()
	_cleanup()


func test_designer_entry_marks_stale_content() -> void:
	_save("designer_t1", 3)
	_save("designer_t2", 4, "an older content hash")
	Designer.force(true)
	var menu := _menu()
	menu.open_designer()
	var by_slot := {}
	for e: Dictionary in menu.designer.entries():
		by_slot[e["slot"]] = e
	assert_false(by_slot["designer_t1"]["stale"])
	assert_true(by_slot["designer_t2"]["stale"])
	assert_true(shows(menu, TitleMenu.STALE), "the stale row says so")
	assert_eq(texts_in(menu).filter(func(t: String) -> bool: return t == TitleMenu.STALE).size(), 1, "only the stale one")
	menu.free()
	_cleanup()


func test_pick_loads_into_autosave_and_plays() -> void:
	_save("designer_t1", 3)
	Designer.force(true)
	var menu := _menu()
	menu.open_designer()
	var asked: Array[String] = []
	menu.start_requested.connect(func(slot: String) -> void: asked.append(slot))
	assert_eq(menu.designer.pick("designer_t1"), "")
	assert_eq(asked, [GameSave.AUTOSAVE])
	assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of(GameSave.AUTOSAVE, saves_dir)),
		FileAccess.get_file_as_bytes(SaveFile.path_of("designer_t1", designer_dir)), "the save, byte for byte")
	var office := menu.open_game(asked[0])
	assert_eq(office.resume_slot, GameSave.AUTOSAVE)
	office.free()
	menu.free()
	_cleanup()


func test_pick_of_a_missing_save_says_so_and_starts_nothing() -> void:
	Designer.force(true)
	var menu := _menu()
	menu.open_designer()
	var asked: Array[String] = []
	menu.start_requested.connect(func(slot: String) -> void: asked.append(slot))
	var error: String = menu.designer.pick("designer_nope")
	assert_false(error.is_empty())
	assert_true(shows(menu, error), "the error shows on the page")
	assert_eq(asked, [])
	assert_false(SaveFile.exists(GameSave.AUTOSAVE, saves_dir))
	menu.free()
	_cleanup()


func test_replay_button_emits_replay_requested_and_terug_goes_back() -> void:
	Designer.force(true)
	var menu := _menu()
	menu.open_designer()
	var replays := [0]
	menu.designer.replay_requested.connect(func() -> void: replays[0] += 1)
	_press(menu.designer, DesignerPage.REPLAY)
	assert_eq(replays[0], 1)
	_press(menu.designer, TitleMenu.BACK)
	assert_eq(menu.page, TitleMenu.Page.MAIN)
	menu.free()
	_cleanup()


## A menu over a designer save and an autosave holding a game; the autosave's bytes in `autosaved`.
var autosaved: PackedByteArray


func _menu_over_autosave() -> TitleMenu:
	_save("designer_t1", 3)
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.region.advance_days(20)
	assert_eq(SaveSlots.new(saves_dir).autosave(s, SessionLayer.new()), "")
	autosaved = FileAccess.get_file_as_bytes(SaveFile.path_of(GameSave.AUTOSAVE, saves_dir))
	Designer.force(true)
	var menu := _menu()
	menu.open_designer()
	return menu


func _asked(menu: TitleMenu) -> Array[String]:
	var asked: Array[String] = []
	menu.start_requested.connect(func(slot: String) -> void: asked.append(slot))
	return asked


func _autosave_bytes() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(SaveFile.path_of(GameSave.AUTOSAVE, saves_dir))


func test_pick_over_a_playable_autosave_asks_first_and_replaces_after_the_answer() -> void:
	var menu := _menu_over_autosave()
	var asked := _asked(menu)
	assert_eq(menu.designer.pick("designer_t1"), "")
	assert_eq(menu.page, TitleMenu.Page.REPLACE, "asks before it replaces the game in the autosave")
	assert_eq(_autosave_bytes(), autosaved, "nothing is overwritten yet")
	assert_eq(asked, [])
	menu.replace_autosave()
	assert_eq(asked, [GameSave.AUTOSAVE])
	assert_eq(_autosave_bytes(), FileAccess.get_file_as_bytes(SaveFile.path_of("designer_t1", designer_dir)), "now it is the designer save")
	menu.free()
	_cleanup()


func test_pick_over_a_playable_autosave_can_keep_the_game_in_a_slot_first() -> void:
	var menu := _menu_over_autosave()
	var asked := _asked(menu)
	menu.designer.pick("designer_t1")
	menu.keep_first()
	assert_eq(_autosave_bytes(), autosaved)
	menu.keep_in(2)
	assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of("slot_2", saves_dir)), autosaved, "the game is kept in the slot")
	assert_eq(asked, [GameSave.AUTOSAVE])
	assert_eq(_autosave_bytes(), FileAccess.get_file_as_bytes(SaveFile.path_of("designer_t1", designer_dir)))
	menu.free()
	_cleanup()


func test_terug_from_the_question_returns_to_the_designer_page_and_changes_nothing() -> void:
	var menu := _menu_over_autosave()
	var asked := _asked(menu)
	menu.designer.pick("designer_t1")
	menu.cancel()
	assert_eq(menu.page, TitleMenu.Page.DESIGNER)
	assert_eq(_autosave_bytes(), autosaved)
	assert_eq(asked, [])
	menu.replace_autosave()  # no question open: nothing happens
	assert_eq(asked, [])
	menu.free()
	_cleanup()


func test_a_failed_keep_forgets_the_designer_save_so_nieuw_spel_starts_a_new_game() -> void:
	var menu := _menu_over_autosave()
	var asked := _asked(menu)
	expect_error("cannot move")  # the failed keep says so
	var blocked := SaveFile.path_of("slot_2", saves_dir)
	DirAccess.make_dir_recursive_absolute(blocked)  # slot 2 cannot be written
	menu.designer.pick("designer_t1")
	menu.keep_first()
	menu.keep_in(2)
	assert_eq(menu.page, TitleMenu.Page.MAIN, "the keep failed")
	assert_eq(asked, [])
	assert_eq(_autosave_bytes(), autosaved)
	menu.new_game()
	assert_eq(menu.page, TitleMenu.Page.REPLACE)
	menu.replace_autosave()
	assert_eq(asked, [""], "a new game, not the designer save")
	assert_eq(_autosave_bytes(), autosaved)
	DirAccess.remove_absolute(blocked)
	menu.free()
	_cleanup()


func _press(root: Node, text: String) -> void:
	for button: Node in root.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			(button as Button).pressed.emit()
