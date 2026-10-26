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


func _press(root: Node, text: String) -> void:
	for button: Node in root.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			(button as Button).pressed.emit()
