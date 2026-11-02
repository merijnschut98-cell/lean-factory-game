extends TestCase
## The local playtest log (engagement loop §8): a readable text file in the
## save folder, opt-out in the settings, never sent anywhere.

var log_path := scratch("saves/test_playtest_log.txt")
var settings_path := scratch("test_settings.cfg")
var markers_path := scratch("saves/test_playtest_markers.md")


func _cleanup() -> void:
	for path in [log_path, log_path + ".old", settings_path, markers_path, markers_path + ".old"]:
		DirAccess.remove_absolute(path)


func test_the_log_is_on_by_default_and_can_be_switched_off() -> void:
	_cleanup()
	assert_true(SessionLog.enabled_in(settings_path), "on until the player says no")
	assert_eq(SessionLog.set_enabled_in(settings_path, false), "")
	assert_false(SessionLog.enabled_in(settings_path))
	assert_eq(SessionLog.set_enabled_in(settings_path, true), "")
	assert_true(SessionLog.enabled_in(settings_path))
	_cleanup()


func test_lines_are_readable_text_and_nothing_is_written_when_off() -> void:
	_cleanup()
	var log := SessionLog.new(log_path, true)
	assert_eq(log.write("Sessie begint"), "")
	assert_eq(log.write("Missie aangenomen: Maatwerk"), "")
	var text := FileAccess.get_file_as_string(log_path)
	assert_true(text.contains("Sessie begint\n"), text)
	assert_eq(text.split("\n", false).size(), 2)
	var off := SessionLog.new(log_path, false)
	assert_eq(off.write("niet schrijven"), "")
	assert_false(FileAccess.get_file_as_string(log_path).contains("niet schrijven"))
	_cleanup()


## A log that grows past its limit starts a new file; the old one is kept once.
func test_a_long_log_rolls_over() -> void:
	_cleanup()
	var log := SessionLog.new(log_path, true)
	log.max_bytes = 200
	for i in 20:
		log.write("regel %d" % i)
	assert_true(FileAccess.get_file_as_string(log_path).length() <= 200 + 64)
	assert_true(FileAccess.file_exists(log_path + ".old"))
	_cleanup()


## Where a session ended and how many loops it left open.
func test_the_end_of_a_session_is_described() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(SessionLog.ended_at(s, true), "dagstart")
	assert_eq(SessionLog.ended_at(s, false), "elders")
	s.accept("fix_custom_design")
	assert_eq(SessionLog.ended_at(s, false), "onderzoek", "a main problem being investigated")
	assert_eq(SessionLog.open_loops(s), 1, "one active mission")


func _marker_log() -> SessionLog:
	_cleanup()
	var log := SessionLog.new(log_path, true)
	log.markers_path = markers_path
	return log


## F8 (the designer's marker): the day, the hour, the place and the main mission in a
## header, the designer's line, then the last events he saw.
func test_marker_writes_day_place_mission_and_recent() -> void:
	var log := _marker_log()
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.accept("fix_custom_design"), "")
	var layer := SessionLayer.new()
	for event in ["Eerste", "Tweede", "Derde"]:
		layer.note_event(event)
	assert_eq(log.marker("Dit voelt traag", s, layer, "connections.design"), "")
	var text := FileAccess.get_file_as_string(markers_path)
	var day := SimCalendar.day_of(s.region.net.time) - GameSession.WARMUP_DAYS
	var minute := GameSession.minute_at(s.region.net.time)
	var header := "## dag %d · %02d:%02d · connections.design · fix_custom_design" % [day, minute / 60, minute % 60]
	assert_true(text.begins_with(header + "\n"), text)
	assert_true(text.contains("\nDit voelt traag\n"), text)
	assert_true(text.contains("- Eerste\n- Tweede\n- Derde\n"), text)
	_cleanup()


func test_marker_names_no_mission_and_keeps_the_last_five_events() -> void:
	var log := _marker_log()
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var layer := SessionLayer.new()
	for i in 8:
		layer.note_event("gebeurtenis %d" % i)
	assert_eq(log.marker("x", s, layer), "")
	var text := FileAccess.get_file_as_string(markers_path)
	assert_true(text.split("\n")[0].ends_with(" · geen"), text)
	assert_false(text.contains("gebeurtenis 2"), "only the last five")
	assert_true(text.contains("- gebeurtenis 3\n"), text)
	assert_true(text.contains("- gebeurtenis 7\n"), text)
	_cleanup()


## The line is written as typed but cannot start a heading or a second block.
func test_marker_text_cannot_break_the_markdown() -> void:
	var log := _marker_log()
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(log.marker("eerste\r\n## nep kopje\n- lijst", s, SessionLayer.new()), "")
	assert_eq(log.marker("# kop", s, SessionLayer.new()), "")
	var lines := Array(FileAccess.get_file_as_string(markers_path).split("\n"))
	assert_eq(lines.filter(func(l: String) -> bool: return l.begins_with("#")).size(), 2, "two headers, one per marker")
	assert_true(lines.has("eerste ## nep kopje - lijst"), str(lines))
	assert_true(lines.has("\\# kop"), str(lines))
	_cleanup()


## No fence (~~~), no strikethrough and no HTML tag from typed text, in the line or the events.
func test_marker_text_cannot_open_a_fence_or_a_tag() -> void:
	var log := _marker_log()
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var layer := SessionLayer.new()
	layer.note_event("<b>vet</b>")
	assert_eq(log.marker("~~~\n<script>x</script> en ~~weg~~ en \\<", s, layer), "")
	var lines := Array(FileAccess.get_file_as_string(markers_path).split("\n"))
	assert_true(lines.has("\\~\\~\\~ \\<script>x\\</script> en \\~\\~weg\\~\\~ en \\\\\\<"), str(lines))
	assert_true(lines.has("- \\<b>vet\\</b>"), str(lines))
	assert_true(lines.all(func(l: String) -> bool: return not l.begins_with("~") and not l.replace("\\<", "").contains("<")), str(lines))
	_cleanup()


## A marker every minute for an evening must not fill the disk: the file rolls over like the log.
func test_markers_file_rolls_over_at_max_bytes() -> void:
	var log := _marker_log()
	log.max_bytes = 60
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var layer := SessionLayer.new()
	assert_eq(log.marker("eerste markering met genoeg tekst om de grens te halen, en nog wat extra erbij", s, layer), "")
	assert_eq(log.marker("tweede markering", s, layer), "")
	assert_true(FileAccess.file_exists(markers_path + ".old"), "the first block moved to .old")
	var fresh := FileAccess.get_file_as_string(markers_path)
	assert_true(fresh.contains("tweede markering") and not fresh.contains("eerste"), fresh)
	_cleanup()


func test_marker_reports_an_unwritable_path() -> void:
	var log := _marker_log()
	log.markers_path = "/proc/no_such_dir/markers.md"
	expect_error("cannot create /proc/no_such_dir")
	expect_error("Could not create directory")
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_ne(log.marker("x", s, SessionLayer.new()), "")
	_cleanup()


func test_markers_sit_beside_the_log() -> void:
	assert_eq(SessionLog.new("user://saves/playtest_log.txt").markers_path, SessionLog.MARKERS)
