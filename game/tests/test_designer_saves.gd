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
	# The tests run under the editor binary (feature "editor"), so this assert sees it on; the
	# real disabled case is the exported player build, which has neither the editor nor the flag.
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
	assert_false(designer.has("stop_act"), "a day stop names no act")
	var back: GameSession = GameSave.read(SLOT, Catalog.DATA_DIR, dir)["session"]
	assert_between(back.missions.play_day(), 10, 10, "the save is on the stop day")
	_assert_working_morning(back)
	assert_eq(back.player.name, MakeSaves.made_player(SLOT).name, "the bot never runs the creator: the save carries a made player")
	assert_eq(back.player.look, MakeSaves.made_player(SLOT).look)
	_cleanup()


## A designer save's player (UX audit #1): a valid Dutch first name and a look from the
## creator's options, the same for a slot every time the saves are made.
func test_every_designer_slot_has_its_own_fixed_made_player() -> void:
	var names := {}
	for spec: Dictionary in DesignerSaves.SAVES:
		var p := MakeSaves.made_player(spec["slot"])
		assert_false(p.name.is_empty(), spec["slot"])
		assert_eq(PlayerProfile.clean_name(p.name), p.name, "a valid name: %s" % p.name)
		assert_eq(p.look, CreatorLook.normalized(p.look), "every trait a creator option")
		assert_eq(MakeSaves.made_player(spec["slot"]).name, p.name, "reproducible")
		names[p.name] = true
	assert_true(names.size() > 1, "not one name for every slot")


## A save resumes the way a day starts in play: 08:30 on a working day (the office open,
## the front door there by evening), never in the night or on a weekend.
func _assert_working_morning(s: GameSession) -> void:
	assert_eq(s.minute_of_day(), GameSession.START_MINUTE, "08:30")
	var weekday := SimCalendar.weekday(s.region.net.time - SimCalendar.days(GameSession.WARMUP_DAYS))
	assert_true(weekday < 5, "a working day, not day %d of the week" % weekday)


## The play day a run stopped on `play_day` at `minute` resumes on (MakeSaves.working_morning).
func _resumes(play_day: int, minute: int) -> int:
	var t := SimCalendar.days(GameSession.WARMUP_DAYS + play_day) + minute
	return SimCalendar.day_of(MakeSaves.working_morning(t)) - GameSession.WARMUP_DAYS


func test_a_stop_resumes_on_the_first_working_morning_at_or_after_it() -> void:
	assert_eq(_resumes(4, 1), 4, "Friday in the night: that Friday's morning")
	assert_eq(_resumes(5, 1), 7, "Saturday: the Monday after")
	assert_eq(_resumes(6, 600), 7, "Sunday: the Monday after")
	assert_eq(_resumes(10, GameSession.START_MINUTE), 10, "08:30 itself stays")
	assert_eq(_resumes(10, 9 * 60), 11, "past 08:30: the next morning")
	assert_eq(_resumes(11, 23 * 60), 14, "Friday evening: the Monday after")
	var t := SimCalendar.days(GameSession.WARMUP_DAYS + 5) + 1
	assert_eq(MakeSaves.working_morning(t) % SimCalendar.MINUTES_PER_DAY, GameSession.START_MINUTE, "at 08:30")


## designer_training_done stops after day 5 (the Saturday after the training week): it
## resumes on the Monday, day 7, at 08:30.
func test_the_training_week_save_resumes_on_monday() -> void:
	assert_eq(MakeSaves.write({"slot": SLOT, "stop_day": 5.0}, "expert", 11, dir), "")
	var back: GameSession = GameSave.read(SLOT, Catalog.DATA_DIR, dir)["session"]
	assert_eq(back.missions.play_day(), 7, "Monday after the training week")
	_assert_working_morning(back)
	_cleanup()


func test_write_at_an_act_stop_saves_its_stop_on_a_morning() -> void:
	assert_eq(MakeSaves.write({"slot": SLOT, "stop_act": 1}, "expert", 11, dir), "")
	var designer: Dictionary = SaveFile.load_slot(SLOT, dir)["data"]["meta"]["designer"]
	assert_eq(designer["stop_act"], 1)
	assert_false(designer.has("stop_day"), "an act stop names no day")
	assert_eq(designer["content_hash"], DesignerSaves.content_hash())
	var back: GameSession = GameSave.read(SLOT, Catalog.DATA_DIR, dir)["session"]
	assert_true(back.missions.active("main").any(func(m: MissionDef) -> bool: return m.act >= 1), "the act is in play")
	assert_true(back.talks.talk == null and back.talks.expert == null, "no talk open")
	_assert_working_morning(back)
	_cleanup()


## The hash covers all the content (every *.json in the data folder, in sorted order), so a
## save made before a dialog changed shows as stale too.
func test_content_hash_covers_every_content_file() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for file: String in DirAccess.get_files_at(Catalog.DATA_DIR):
		if file.get_extension() == "json":
			DirAccess.copy_absolute(Catalog.DATA_DIR.path_join(file), dir.path_join(file))
	assert_eq(DesignerSaves.content_hash(dir), DesignerSaves.content_hash(), "the same files, the same hash")
	var dialogs := FileAccess.open(dir.path_join("dialogs.json"), FileAccess.READ_WRITE)
	dialogs.seek_end()
	dialogs.store_string("\n")
	dialogs.close()
	assert_ne(DesignerSaves.content_hash(dir), DesignerSaves.content_hash(), "a dialog change changes it")
	_cleanup()


func test_write_says_what_went_wrong() -> void:
	assert_true(MakeSaves.write({"slot": SLOT}, "expert", 11, dir).contains("no stop"), "a spec without a stop, refused before a run")
	assert_false(SaveFile.exists(SLOT, dir), "nothing written")
	assert_ne(MakeSaves.write({"slot": "../escape", "stop_day": 1.0}, "expert", 11, dir), "", "a bad slot")
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


## One step of a persona at the stop check: its session a new game with `progress` as given and
## the action cap spent, so a step that does not stop for the act ends on "action_cap".
func _step_at_the_act_stop(progress: Dictionary, done: Array[String]) -> Dictionary:
	var persona := Autoplay.Persona.new("expert", 11)
	persona.stop_act = 2
	persona.s = GameSession.new_game(11, Catalog.DATA_DIR, false)
	persona.s.missions.progress.clear()
	persona.s.missions.progress.merge(progress)
	for id in done:
		persona.s.missions.done_once[id] = true
	persona.record = {"end": "", "curve": []}
	persona._actions = Autoplay.Persona.MAX_ACTIONS
	persona._step()
	return {"end": persona.record["end"], "current_act": persona.s.missions.current_act()}


## A done Act II side in a gap between mains makes Missions.current_act() say 2 (it counts every
## completed mission); the step must not stop for it, only for an Act II main in play.
func test_a_done_side_of_a_later_act_is_not_the_act_stop() -> void:
	var gap := _step_at_the_act_stop({}, ["fix_silent_meter"])
	assert_eq(gap["current_act"], 2, "the false Act II this guards against")
	assert_eq(gap["end"], "action_cap", "the step goes past the act stop")
	var in_play := _step_at_the_act_stop({"fix_unused_capacity": {"status": "active", "asks": {}, "seen": {}}}, [])
	assert_eq(in_play["end"], "stop_act", "an Act II main in play is the stop")
