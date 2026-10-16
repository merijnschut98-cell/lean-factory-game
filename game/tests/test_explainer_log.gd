extends TestCase
## T8: the explainers the player has seen and the reveal's fold survive a
## save; an unknown id is dropped on load, never a crash.

const ID := "spanning_stroom_weerstand"
const SLOT := "test_explainer_log"


func test_a_seen_explainer_and_the_reveal_round_trip() -> void:
	var book := ExplainerLog.new()
	book.see(ID)
	book.see(ID)
	book.reveal_open = true
	var back := ExplainerLog.new()
	back.load_dict(book.to_dict(), [ID])
	assert_eq(back.seen, [ID] as Array[String], "once, however often it was opened")
	assert_true(back.has_seen(ID))
	assert_true(back.reveal_open)


func test_an_unknown_id_is_dropped_on_load() -> void:
	var back := ExplainerLog.new()
	back.load_dict({"seen": [ID, "gone", 7], "reveal_open": "yes"}, [ID])
	assert_eq(back.seen, [ID] as Array[String])
	assert_false(back.reveal_open, "not a bool: folded")


func test_a_broken_entry_loads_as_nothing_seen() -> void:
	var back := ExplainerLog.new()
	back.load_dict({"seen": "all"}, [ID])
	assert_eq(back.seen, [] as Array[String])


func test_the_game_save_keeps_the_log() -> void:
	var s := GameSession.new_game(1, Catalog.DATA_DIR, false)
	s.explainers.see(ID)
	s.explainers.reveal_open = true
	assert_eq(GameSave.write(SLOT, s, SessionLayer.new()), "")
	var read := GameSave.read(SLOT)
	assert_eq(read["error"], "")
	var loaded: GameSession = read["session"]
	assert_true(loaded.explainers.has_seen(ID))
	assert_true(loaded.explainers.reveal_open)
	DirAccess.remove_absolute(SaveFile.path_of(SLOT))
