extends TestCase
## The designer's tools (Phase 3 slice 3.0): the --designer flag and the saves that
## jump to a play day (tools/make_saves.gd runs the autoplay bot to the stop and writes
## a slot; the main menu loads it). Runs stop early (day 10, act 1): the 45/70/95/Act II
## saves are made by the tool, not by a test.

const Autoplay := preload("res://tools/autoplay.gd")
const SLOT := "designer_test"
## Per process (see TestCase.scratch): a fixed name raced between runs.
var dir := "user://test_designer_%d" % OS.get_process_id()


func _cleanup() -> void:
	Designer.force(null)
	if DirAccess.dir_exists_absolute(dir):
		for file: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute("%s/%s" % [dir, file])
		DirAccess.remove_absolute(dir)


func test_designer_disabled_without_flag_or_editor() -> void:
	Designer.force(null)
	var flagged := OS.get_cmdline_user_args().has("--designer")
	assert_eq(Designer.enabled(), OS.has_feature("editor") or flagged, "only the editor or the flag turns it on")
	Designer.force(true)
	assert_true(Designer.enabled(), "the test hook forces it on")
	Designer.force(false)
	assert_false(Designer.enabled(), "and off")
	_cleanup()


func test_write_stops_at_day_and_saves_meta() -> void:
	assert_eq(MakeSaves.write({"slot": SLOT, "stop_day": 10.0}, "expert", 11, dir), "")
	var meta: Dictionary = SaveFile.load_slot(SLOT, dir)["data"]["meta"]
	var designer: Dictionary = meta["designer"]
	assert_eq(designer["stop_day"], 10.0)
	assert_eq(designer["persona"], "expert")
	assert_eq(designer["seed"], 11)
	assert_eq(designer["content_hash"], DesignerSaves.content_hash())
	assert_false((designer["content_hash"] as String).is_empty())
	var back: GameSession = GameSave.read(SLOT, Catalog.DATA_DIR, dir)["session"]
	assert_between(back.missions.play_day(), 10, 10, "the save is on the stop day")
	_cleanup()


func test_saves_are_written_outside_any_talk() -> void:
	assert_eq(MakeSaves.write({"slot": SLOT, "stop_day": 10.0}, "expert", 11, dir), "")
	var back: GameSession = GameSave.read(SLOT, Catalog.DATA_DIR, dir)["session"]
	assert_true(back.talks.talk == null, "no talk open")
	assert_true(back.talks.expert == null, "no expert talk open")
	_cleanup()


func test_stop_act_ends_when_act_opens() -> void:
	var persona := Autoplay.Persona.new("expert", 11)
	persona.stop_act = 1
	var run := persona.play()
	assert_eq(run["end"], "stop_act")
	assert_true(persona.s.missions.current_act() >= 1)
	assert_true(persona.s.talks.talk == null and persona.s.talks.expert == null, "stopped outside a talk")
	_cleanup()


func test_load_into_autosave_copies_bytes() -> void:
	assert_eq(MakeSaves.write({"slot": SLOT, "stop_day": 10.0}, "expert", 11, dir), "")
	assert_eq(DesignerSaves.load_into_autosave(SLOT, dir, dir), "")
	var designer_time: float = SaveFile.load_slot(SLOT, dir)["data"]["meta"]["time"]
	var autosave: Dictionary = SaveFile.load_slot(GameSave.AUTOSAVE, dir)
	assert_eq(autosave["data"]["meta"]["time"], designer_time)
	assert_ne(DesignerSaves.load_into_autosave("designer_nothing", dir, dir), "", "a missing slot is an error")
	_cleanup()
