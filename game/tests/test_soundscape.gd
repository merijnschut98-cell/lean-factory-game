extends TestCase
## A thin sound layer (design §1.3, S1-B): the office bed follows the hour and who is in,
## one-shots for steps, doors, the lift, the shutter and the vans; master volume and
## "Geluid uit" in the settings. Every sound is a listed CC0 file.

const SOURCES := "res://assets/audio/SOURCES.md"

var path := scratch("soundscape_settings.cfg")


func _cleanup() -> void:
	DirAccess.remove_absolute(path)


func test_the_bed_is_louder_at_ten_than_at_half_past_six() -> void:
	for occupancy in [0.3, 0.8, 1.0]:
		assert_true(Soundscape.bed_level(10 * 60, occupancy) > Soundscape.bed_level(18 * 60 + 30, occupancy),
			"occupancy %s" % occupancy)
	assert_true(Soundscape.bed_level(18 * 60 + 30, 0.1) < 0.1, "near silent in the evening")
	assert_true(Soundscape.bed_level(10 * 60, 1.0) > 0.8, "full at ten")
	assert_eq(Soundscape.bed_level(3 * 60, 1.0), 0.0, "nobody types at night")


func test_more_people_make_more_sound() -> void:
	assert_true(Soundscape.bed_level(10 * 60, 1.0) > Soundscape.bed_level(10 * 60, 0.2))


func test_the_settings_default_low_and_round_trip() -> void:
	_cleanup()
	assert_eq(Soundscape.master(path), Soundscape.MASTER_DEFAULT)
	assert_true(Soundscape.MASTER_DEFAULT < 1.0, "default low")
	assert_false(Soundscape.muted(path))
	assert_eq(Soundscape.set_master(0.3, path), "")
	assert_eq(Soundscape.set_muted(true, path), "")
	assert_eq(Soundscape.master(path), 0.3)
	assert_true(Soundscape.muted(path))
	Soundscape.set_master(7.0, path)
	assert_eq(Soundscape.master(path), 1.0, "clamped")
	_cleanup()


func test_muted_plays_nothing() -> void:
	_cleanup()
	Soundscape.set_muted(true, path)
	var host := Node.new()
	assert_eq(Soundscape.play_at(host, "door_open", path), null)
	var scape := Soundscape.new()
	scape.settings_path = path
	host.add_child(scape)
	scape.apply_bed(10 * 60, 1.0)
	for layer: AudioStreamPlayer in scape.layers.values():
		assert_false(layer.playing, layer.name)
	assert_eq(scape.step(Vector3.ZERO, "first"), null)
	host.free()
	_cleanup()


func test_unmuted_the_bed_plays_and_a_one_shot_frees_itself() -> void:
	_cleanup()
	var host := Node.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	var scape := Soundscape.new()
	scape.settings_path = path
	host.add_child(scape)
	scape.apply_bed(10 * 60, 1.0)
	assert_true(scape.layers["murmur"].playing)
	var loud: float = scape.layers["murmur"].volume_db
	scape.apply_bed(18 * 60 + 30, 1.0)
	assert_true(scape.layers["murmur"].volume_db < loud, "quieter in the evening")
	var shot := Soundscape.play_at(host, "door_open", path)
	assert_true(shot != null and shot.stream != null)
	assert_true(shot.finished.is_connected(shot.queue_free))
	assert_eq(Soundscape.play_at(host, "no_such_sound", path), null, "an unknown sound plays nothing")
	host.free()
	_cleanup()


func test_steps_sound_by_the_floor_underfoot() -> void:
	assert_eq(Soundscape.surface_at(Vector3(8, 0, -3), "first"), "carpet", "the office wing")
	assert_eq(Soundscape.surface_at(Vector3(-3, 0, -8), "first"), "tile", "the core")
	assert_eq(Soundscape.surface_at(Vector3(8, 0, -3), "yard"), "tile", "outside")


func test_every_referenced_file_exists_and_is_listed_in_sources() -> void:
	var sources := FileAccess.get_file_as_string(SOURCES)
	assert_false(sources.is_empty(), SOURCES)
	var files := 0
	for id: String in Soundscape.SOUNDS:
		for file: String in Soundscape.SOUNDS[id]:
			files += 1
			assert_true(ResourceLoader.exists(Soundscape.DIR + file), file)
			var listed := sources.contains(file) or sources.contains(file.trim_suffix(".ogg").rstrip("0123456789"))
			assert_true(listed, "%s in SOURCES.md" % file)
	assert_true(files >= 10)
	assert_true(sources.contains("Made for Spanning"), "the buzz is the project's own and says so")


func test_every_audio_file_is_used() -> void:
	var used := []
	for id: String in Soundscape.SOUNDS:
		used.append_array(Soundscape.SOUNDS[id])
	for file in DirAccess.get_files_at(Soundscape.DIR):
		if file.ends_with(".ogg"):
			assert_true(file in used, file + " is referenced")


func test_the_settings_controls_write_the_settings() -> void:
	_cleanup()
	var controls := Soundscape.settings_controls(path)
	for c in controls:
		(Engine.get_main_loop() as SceneTree).root.add_child(c)
	var box: CheckBox = controls.filter(func(c: Control) -> bool: return c is CheckBox)[0]
	var slider: HSlider = controls[1].find_children("*", "HSlider", true, false)[0]
	assert_eq(box.text, Soundscape.MUTE_LABEL)
	box.button_pressed = true
	assert_true(Soundscape.muted(path))
	slider.value = 0.2
	assert_eq(Soundscape.master(path), 0.2)
	for c in controls:
		c.free()
	_cleanup()


## Going home (OfficeHome's fade): the door and the street, the bed fades out and stays
## out; the next morning it fades back in.
func test_going_home_hushes_the_bed_until_the_morning() -> void:
	_cleanup()
	var host := Node.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	var scape := Soundscape.new()
	scape.settings_path = path
	host.add_child(scape)
	scape.apply_bed(17 * 60 + 10, 1.0)
	var shots := scape.go_home()
	assert_eq(shots.size(), 2, "the door and the street")
	assert_true(scape.hushed)
	scape.apply_bed(10 * 60, 1.0)
	assert_true(scape.hushed, "the clock does not wake the bed while you are away")
	scape.morning(8 * 60 + 30, 1.0)
	assert_false(scape.hushed)
	assert_true(scape.layers["keys"].playing, "the morning office")
	host.free()
	_cleanup()
