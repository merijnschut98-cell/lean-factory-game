extends TestCase
## The settings file (user://settings.cfg): one helper reads and writes it. A
## missing or damaged file gives the defaults, never a crash.

var path := scratch("settings_helper.cfg")


func _cleanup() -> void:
	DirAccess.remove_absolute(path)


func test_a_missing_file_gives_the_defaults() -> void:
	_cleanup()
	assert_true(Settings.get_bool("minimap", "shown", true, path))
	assert_false(Settings.get_bool("text", "auto", false, path))
	assert_eq(Settings.get_float("audio", "master", 0.6, path), 0.6)


func test_values_round_trip_and_keep_the_other_keys() -> void:
	_cleanup()
	assert_eq(Settings.set_value("minimap", "turns", false, path), "")
	assert_eq(Settings.set_value("audio", "master", 0.25, path), "")
	assert_false(Settings.get_bool("minimap", "turns", true, path))
	assert_eq(Settings.get_float("audio", "master", 0.6, path), 0.25)
	_cleanup()


func test_a_value_of_the_wrong_type_gives_the_default() -> void:
	_cleanup()
	Settings.set_value("minimap", "shown", "ja", path)
	Settings.set_value("audio", "master", "luid", path)
	assert_true(Settings.get_bool("minimap", "shown", true, path))
	assert_eq(Settings.get_float("audio", "master", 0.6, path), 0.6)
	_cleanup()


func test_an_int_reads_as_a_float() -> void:
	_cleanup()
	Settings.set_value("audio", "master", 1, path)
	assert_eq(Settings.get_float("audio", "master", 0.6, path), 1.0)
	_cleanup()


func test_a_damaged_file_gives_the_defaults_and_can_be_written_again() -> void:
	_cleanup()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[audio\nmaster = = ( kapot")
	file.close()
	expect_error("ConfigFile parse error")
	expect_error("is unreadable, using the defaults")
	assert_true(Settings.get_bool("minimap", "shown", true, path))
	assert_eq(Settings.get_float("audio", "master", 0.6, path), 0.6)
	assert_eq(Settings.set_value("audio", "muted", true, path), "")
	assert_true(Settings.get_bool("audio", "muted", false, path))
	_cleanup()


func test_an_unwritable_path_says_what_went_wrong() -> void:
	var error := Settings.set_value("audio", "muted", true, "user://geen_map_%d/x/settings.cfg" % OS.get_process_id())
	assert_true(error.begins_with("instellingen niet bewaard"), error)
