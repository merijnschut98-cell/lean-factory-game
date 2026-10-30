extends TestCase
## The whole game in one save (GameSave): the region, the missions, the
## discoveries and the session layer's snapshot, so the next session opens
## with a terugblik. Old saves (the region only) still load.

## Per process (see TestCase.scratch): a fixed name raced between runs.
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


## The people come back: trust, what was heard, the talks and the player's note.
func test_a_saved_game_keeps_the_people() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	assert_false(s.start_dialog("joost").has("error"))
	s.end_dialog()
	assert_true(s.set_note("joost", "Zijn cijfers zijn zijn schild."))
	assert_eq(GameSave.write(slot, s, SessionLayer.new()), "")
	var back: GameSession = GameSave.read(slot)["session"]
	assert_eq(back.people.to_dict(), s.people.to_dict())
	assert_eq(back.person("joost")["note"], "Zijn cijfers zijn zijn schild.")
	_cleanup()


## "Once a day" survives a reload: who greeted you and which pair chatted today.
func test_todays_greetings_and_chatter_survive_a_reload() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_ne(s.greet("anouk"), "", "Anouk says good morning")
	assert_eq(s.chatter("sanne", "anouk").size(), 2, "Sanne and Anouk chat")
	assert_eq(GameSave.write(slot, s, SessionLayer.new()), "")
	var back: GameSession = GameSave.read(slot)["session"]
	assert_eq(back.greet("anouk"), "", "not twice the same day, reload or not")
	assert_eq(back.chatter("anouk", "sanne"), [] as Array[String], "nor the same chat")
	back.pass_time(SimCalendar.days(1))
	assert_ne(back.greet("anouk"), "", "the next day she greets again")
	_cleanup()


## Junk where the day's greetings are saved reads as nobody greeted yet.
func test_junk_greetings_read_as_none() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.load_passing({"greeted": {"anouk": "maandag", "3": 4}, "chatted": [1]})
	assert_ne(s.greet("anouk"), "", "a junk day is no greeting")
	s.load_passing("x")
	s.load_passing(null)
	assert_ne(s.greet("anouk"), "", "junk, or an old save without them: nobody greeted yet")


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
		"missions": "x", "discoveries": 5, "people": [], "session": {"start": [1], "queued": "no"}}))
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


## The save list's meta can be told more (a designer save says how it was made); a key given
## there wins over the meta's own.
func test_extra_meta_is_merged_over_the_meta() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(GameSave.write(slot, s, SessionLayer.new(), SaveFile.DIR, 5.0, {"designer": {"seed": 11}, "act": 9}), "")
	var meta: Dictionary = SaveFile.load_slot(slot)["data"]["meta"]
	assert_eq(meta["designer"], {"seed": 11})
	assert_eq(meta["act"], 9, "the extra key wins")
	assert_eq(meta["saved"], 5.0, "the rest is the meta's own")
	_cleanup()
