extends TestCase
## The whole game in one save (GameSave): the region, the missions, the
## discoveries and the session layer's snapshot, so the next session opens
## with a terugblik. Old saves (the region only) still load.

## Per process: every worktree's test run shares user://, so a fixed name
## lets one run delete the save another has just written.
var slot := "test_game_save_%d" % OS.get_process_id()
const MISSION := "fix_custom_design"


func _cleanup() -> void:
	DirAccess.remove_absolute(SaveFile.path_of(slot))


func test_a_saved_game_comes_back_with_its_missions_and_its_snapshot() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.accept(MISSION), "")
	s.use_tool("connections.design", "time_study")
	var layer := SessionLayer.new()
	layer.begin(s)
	layer.queued.append("d_two")
	assert_eq(GameSave.write(slot, s, layer), "")
	assert_true(GameSave.exists(slot))
	var loaded := GameSave.read(slot)
	assert_eq(loaded["error"], "")
	var back: GameSession = loaded["session"]
	assert_eq(back.region.net.time, s.region.net.time)
	assert_eq(back.missions.status(MISSION), "active", "the missions come back")
	assert_eq(back.region.found, s.region.found)
	assert_eq(back.discoveries.to_dict(), s.discoveries.to_dict())
	assert_eq(back.followed_order(), s.followed_order(), "the El Amrani dossier is the same order")
	var back_layer: SessionLayer = loaded["layer"]
	assert_eq(back_layer.to_dict(), layer.to_dict(), "the snapshot comes back")
	assert_false(back_layer.terugblik(back).is_empty(), "so the next session opens with a terugblik")
	_cleanup()


## A save from before the session layer (the region only) loads: the
## missions start as a new game's, and there is no terugblik.
func test_an_old_save_still_loads() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.region.advance_days(3)
	assert_eq(SaveFile.write(slot, s.region), "")
	var loaded := GameSave.read(slot)
	assert_eq(loaded["error"], "")
	assert_eq(loaded["session"].region.net.time, s.region.net.time)
	assert_eq(loaded["layer"].terugblik(loaded["session"]), {})
	_cleanup()


## Junk in the new keys is ignored, not trusted.
func test_junk_in_the_new_keys_is_ignored() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var file := FileAccess.open(SaveFile.path_of(slot), FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"version": SaveFile.VERSION, "region": RegionState.capture(s.region),
		"missions": "x", "discoveries": 5, "session": {"start": [1], "queued": "no"}}))
	file.close()
	var loaded := GameSave.read(slot)
	assert_eq(loaded["error"], "")
	assert_eq(loaded["layer"].start, {})
	assert_eq(loaded["layer"].queued, [])
	_cleanup()


func test_a_bad_slot_or_a_missing_save_is_refused() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_ne(GameSave.write("../escape", s, SessionLayer.new()), "")
	assert_false(GameSave.exists("../escape"))
	assert_ne(GameSave.read("no_such_slot")["error"], "")
	assert_eq(GameSave.read("no_such_slot")["session"], null)
