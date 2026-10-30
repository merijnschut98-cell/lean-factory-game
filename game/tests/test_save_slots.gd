extends TestCase
## Save slots (PLAN 2.7): five manual slots beside the autosave, listed most
## recently used first, a wipe, and saves that are old, new or damaged
## marked, never a crash. Every test works in its own folder under user://
## (TestCase.scratch): parallel runs share user://.

const MISSION := "fix_custom_design"

var dir := TestCase.scratch("saves")
var clock := 1000.0


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
	DirAccess.remove_absolute(dir)


func _write_raw(slot: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(SaveFile.path_of(slot, dir), FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func test_slot_names_come_only_from_the_numbers_one_to_five() -> void:
	assert_eq(SaveSlots.manual(1), "slot_1")
	assert_eq(SaveSlots.manual(5), "slot_5")
	for bad in [0, 6, -1, 99]:
		assert_eq(SaveSlots.manual(bad), "", "slot %d does not exist" % bad)
	var slots := _slots()
	assert_ne(slots.save(0, _session(), SessionLayer.new()), "", "no slot 0")
	assert_ne(slots.save(6, _session(), SessionLayer.new()), "", "no slot 6")
	assert_ne(slots.resume("../autosave")["error"], "", "a path is not a slot")
	assert_ne(slots.resume("test_other")["error"], "", "only the five and the autosave")
	assert_false(SaveSlots.new("res://saves").valid(), "saves live under user:// only")
	assert_false(SaveSlots.new("user://a/../b").valid())
	_cleanup()


func test_all_five_slots_round_trip() -> void:
	var slots := _slots()
	for n in range(1, SaveSlots.COUNT + 1):
		var s := _session(n)
		assert_eq(slots.save(n, s, SessionLayer.new()), "")
		var loaded := slots.resume(SaveSlots.manual(n), Catalog.DATA_DIR)
		assert_eq(loaded["error"], "", "slot %d" % n)
		assert_eq(loaded["session"].region.net.time, s.region.net.time, "slot %d keeps its own game" % n)
	assert_eq(slots.entries().size(), SaveSlots.COUNT)
	_cleanup()


func test_a_slot_keeps_the_missions_and_shows_name_act_and_date() -> void:
	var slots := _slots()
	var s := _session()
	assert_eq(s.accept(MISSION), "")
	assert_eq(slots.save(2, s, SessionLayer.new()), "")
	var e := slots.entry(SaveSlots.manual(2))
	assert_eq(e["status"], SaveSlots.PLAYABLE)
	assert_eq(e["number"], 2)
	assert_eq(e["act"], s.missions.current_act())
	assert_eq(e["time"], s.region.net.time)
	assert_eq(GameSession.clock_at(e["time"]), s.clock_text())
	assert_eq(e["saved"], clock)
	assert_true(e["name"] is String)
	assert_eq(slots.resume(SaveSlots.manual(2))["session"].missions.status(MISSION), "active")
	_cleanup()


func test_saves_are_listed_most_recently_used_first() -> void:
	var slots := _slots()
	var layer := SessionLayer.new()
	for n in [3, 1, 5]:
		clock += 10.0
		assert_eq(slots.save(n, _session(), layer), "")
	clock += 10.0
	assert_eq(slots.autosave(_session(), layer), "")
	assert_eq(_order(slots), ["autosave", "slot_5", "slot_1", "slot_3"])
	clock += 10.0
	assert_eq(slots.resume("slot_1")["error"], "", "continuing from a save uses it")
	assert_eq(_order(slots), ["slot_1", "autosave", "slot_5", "slot_3"])
	clock += 10.0
	assert_eq(slots.save(3, _session(), layer), "")
	assert_eq(_order(slots), ["slot_3", "slot_1", "autosave", "slot_5"])
	_cleanup()


## A damaged index of last use never hides a save: the save time stands in.
func test_a_damaged_use_index_falls_back_to_the_save_time() -> void:
	var slots := _slots()
	assert_eq(slots.save(1, _session(), SessionLayer.new()), "")
	clock += 10.0
	assert_eq(slots.save(2, _session(), SessionLayer.new()), "")
	var file := FileAccess.open(slots.index_path(), FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	assert_eq(_order(slots), ["slot_2", "slot_1"])
	file = FileAccess.open(slots.index_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"slot_1": "x", "../evil": 5, "slot_2": null}))
	file.close()
	assert_eq(_order(slots), ["slot_2", "slot_1"])
	_cleanup()


func test_the_autosave_never_overwrites_a_manual_slot() -> void:
	var slots := _slots()
	var kept := _session(4)
	for n in range(1, SaveSlots.COUNT + 1):
		assert_eq(slots.save(n, kept, SessionLayer.new()), "")
	var before := {}
	for n in range(1, SaveSlots.COUNT + 1):
		before[n] = FileAccess.get_file_as_bytes(SaveFile.path_of(SaveSlots.manual(n), dir))
	var playing := _session(9)
	assert_eq(slots.autosave(playing, SessionLayer.new()), "")
	assert_eq(slots.autosave(playing, SessionLayer.new()), "")
	for n in range(1, SaveSlots.COUNT + 1):
		assert_eq(FileAccess.get_file_as_bytes(SaveFile.path_of(SaveSlots.manual(n), dir)), before[n],
			"slot %d untouched" % n)
	assert_eq(slots.resume(SaveSlots.AUTOSAVE)["session"].region.net.time, playing.region.net.time)
	assert_eq(slots.entries().size(), SaveSlots.COUNT + 1, "the autosave is a sixth entry, not one of the five")
	_cleanup()


func test_the_wipe_deletes_every_save() -> void:
	var slots := _slots()
	assert_eq(slots.save(1, _session(), SessionLayer.new()), "")
	assert_eq(slots.save(4, _session(), SessionLayer.new()), "")
	assert_eq(slots.autosave(_session(), SessionLayer.new()), "")
	_write_raw("slot_2", PackedByteArray([1, 2, 3]))
	assert_eq(slots.wipe(), "")
	assert_eq(slots.entries(), [])
	assert_false(FileAccess.file_exists(slots.index_path()))
	assert_false(GameSave.exists(SaveSlots.AUTOSAVE, dir))
	assert_eq(slots.wipe(), "", "wiping nothing is fine")
	_cleanup()


func test_a_damaged_save_is_marked_and_does_not_load() -> void:
	var slots := _slots()
	assert_eq(slots.save(1, _session(), SessionLayer.new()), "")
	var bytes := FileAccess.get_file_as_bytes(SaveFile.path_of("slot_1", dir))
	_write_raw("slot_2", bytes.slice(0, bytes.size() / 2))  # cut off mid-write
	var flipped := bytes.duplicate()
	flipped[flipped.size() - 3] ^= 0xFF
	_write_raw("slot_3", flipped)
	_write_raw("slot_4", "dit is geen save".to_utf8_buffer())
	_write_raw("slot_5", PackedByteArray())
	for slot in ["slot_2", "slot_3", "slot_4", "slot_5"]:
		assert_eq(slots.entry(slot)["status"], SaveSlots.DAMAGED, slot)
		var loaded := slots.resume(slot)
		assert_ne(loaded["error"], "", slot)
		assert_eq(loaded["session"], null, slot)
	assert_eq(slots.entry("slot_1")["status"], SaveSlots.PLAYABLE, "the good one still is")
	_cleanup()


func test_old_and_new_versions_are_marked_never_crash() -> void:
	var slots := _slots()
	var s := _session(2)
	_write_raw("slot_1", var_to_bytes({"version": SaveFile.OLDEST - 1, "region": {}}))
	_write_raw("slot_2", SaveFile.encode({"version": SaveFile.VERSION + 1, "region": {}}))
	_write_raw("slot_3", var_to_bytes({"version": 1, "region": RegionState.capture(s.region)}))
	assert_eq(slots.entry("slot_1")["status"], SaveSlots.TOO_OLD)
	assert_eq(slots.entry("slot_2")["status"], SaveSlots.TOO_NEW)
	assert_ne(slots.resume("slot_1")["error"], "")
	assert_ne(slots.resume("slot_2")["error"], "")
	var legacy := slots.entry("slot_3")
	assert_eq(legacy["status"], SaveSlots.PLAYABLE, "a version-1 save (no header) still loads")
	assert_eq(legacy["time"], s.region.net.time, "its date read from the region")
	assert_eq(legacy["act"], -1, "its act is unknown")
	assert_eq(_order(slots)[0], "slot_3", "what cannot be played is listed after what can")
	assert_eq(slots.resume("slot_3")["session"].region.net.time, s.region.net.time)
	_cleanup()


func test_a_missing_slot_is_empty() -> void:
	var slots := _slots()
	assert_eq(slots.entry("slot_1"), {})
	assert_eq(slots.entries(), [])
	assert_ne(slots.resume("slot_1")["error"], "")
	_cleanup()


# ── A crash mid-save (review S2): the newest whole file wins ───────────────

## A save of a game `days` in, written through manual slot `n` and then moved
## to `path` (the state a crash leaves). Returns its game time.
func _staged(n: int, days: int, path: String) -> int:
	var s := _session(days)
	assert_eq(_slots().save(n, s, SessionLayer.new()), "")
	assert_eq(DirAccess.rename_absolute(SaveFile.path_of(SaveSlots.manual(n), dir), path), OK)
	return s.region.net.time


func _autosave_path() -> String:
	return SaveFile.path_of(SaveSlots.AUTOSAVE, dir)


## The save files in the folder (the use index left out).
func _files() -> Array:
	var out := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f != SaveSlots.INDEX)
	out.sort()
	return out


func test_a_save_leaves_no_temporary_or_backup_file() -> void:
	var slots := _slots()
	assert_eq(slots.autosave(_session(1), SessionLayer.new()), "")
	assert_eq(slots.autosave(_session(2), SessionLayer.new()), "")
	assert_eq(_files(), ["autosave.save"])
	_cleanup()


func test_a_failed_move_into_place_leaves_no_temporary_file() -> void:
	DirAccess.make_dir_recursive_absolute(_autosave_path())  # a folder where the save belongs: the rename fails
	var error := SaveFile.store(SaveSlots.AUTOSAVE, SaveFile.encode({"version": SaveFile.VERSION}), dir)
	assert_true("cannot move" in error, "the failure is reported: %s" % error)
	assert_false(FileAccess.file_exists(_autosave_path() + SaveFile.TEMP), "the unsaved copy is not left to be 'recovered'")
	DirAccess.remove_absolute(_autosave_path())
	_cleanup()


func test_a_new_save_left_only_as_tmp_is_recovered() -> void:
	var time := _staged(1, 3, _autosave_path() + ".tmp")
	var slots := _slots()
	assert_eq(slots.entries().size(), 1, "the title menu still lists it")
	assert_eq(slots.entry(SaveSlots.AUTOSAVE)["time"], time)
	assert_eq(slots.resume(SaveSlots.AUTOSAVE)["session"].region.net.time, time)
	assert_eq(_files(), ["autosave.save"], "moved into place")
	_cleanup()


func test_a_crash_between_the_two_renames_keeps_the_newer_save() -> void:
	var newer := _staged(1, 5, _autosave_path() + ".tmp")
	_staged(2, 2, _autosave_path() + ".bak")
	assert_eq(_slots().entry(SaveSlots.AUTOSAVE)["time"], newer, "the new save, not the backup")
	assert_eq(_files(), ["autosave.save"])
	_cleanup()


func test_a_half_written_tmp_falls_back_to_the_backup() -> void:
	var older := _staged(1, 2, _autosave_path() + ".bak")
	_staged(2, 5, _autosave_path() + ".tmp")
	var whole := FileAccess.get_file_as_bytes(_autosave_path() + ".tmp")
	var file := FileAccess.open(_autosave_path() + ".tmp", FileAccess.WRITE)
	file.store_buffer(whole.slice(0, whole.size() / 2))
	file.close()
	assert_eq(_slots().entry(SaveSlots.AUTOSAVE)["time"], older)
	assert_eq(_slots().entry(SaveSlots.AUTOSAVE)["status"], SaveSlots.PLAYABLE)
	assert_eq(_files(), ["autosave.save"])
	_cleanup()


func test_a_damaged_save_is_replaced_by_a_whole_backup() -> void:
	var older := _staged(1, 2, _autosave_path() + ".bak")
	_write_raw(SaveSlots.AUTOSAVE, "kapot".to_utf8_buffer())
	assert_eq(_slots().entry(SaveSlots.AUTOSAVE)["time"], older)
	assert_eq(_slots().resume(SaveSlots.AUTOSAVE)["error"], "")
	_cleanup()


func test_a_whole_save_wins_over_stray_files() -> void:
	var slots := _slots()
	var s := _session(4)
	assert_eq(slots.autosave(s, SessionLayer.new()), "")
	_staged(1, 9, _autosave_path() + ".bak")
	assert_eq(slots.entry(SaveSlots.AUTOSAVE)["time"], s.region.net.time, "the save in place is never replaced")
	slots.wipe()
	assert_eq(_files(), [], "the wipe takes the stray files too")
	_cleanup()


func _order(slots: SaveSlots) -> Array:
	return slots.entries().map(func(e: Dictionary) -> String: return e["slot"])
