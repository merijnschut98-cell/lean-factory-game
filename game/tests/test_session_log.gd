extends TestCase
## The local playtest log (engagement loop §8): a readable text file in the
## save folder, opt-out in the settings, never sent anywhere.

const LOG := "user://saves/test_playtest_log.txt"
const SETTINGS := "user://test_settings.cfg"


func _cleanup() -> void:
	for path in [LOG, LOG + ".old", SETTINGS]:
		DirAccess.remove_absolute(path)


func test_the_log_is_on_by_default_and_can_be_switched_off() -> void:
	_cleanup()
	assert_true(SessionLog.enabled_in(SETTINGS), "on until the player says no")
	assert_eq(SessionLog.set_enabled_in(SETTINGS, false), "")
	assert_false(SessionLog.enabled_in(SETTINGS))
	assert_eq(SessionLog.set_enabled_in(SETTINGS, true), "")
	assert_true(SessionLog.enabled_in(SETTINGS))
	_cleanup()


func test_lines_are_readable_text_and_nothing_is_written_when_off() -> void:
	_cleanup()
	var log := SessionLog.new(LOG, true)
	assert_eq(log.write("Sessie begint"), "")
	assert_eq(log.write("Missie aangenomen: Maatwerk"), "")
	var text := FileAccess.get_file_as_string(LOG)
	assert_true(text.contains("Sessie begint\n"), text)
	assert_eq(text.split("\n", false).size(), 2)
	var off := SessionLog.new(LOG, false)
	assert_eq(off.write("niet schrijven"), "")
	assert_false(FileAccess.get_file_as_string(LOG).contains("niet schrijven"))
	_cleanup()


## A log that grows past its limit starts a new file; the old one is kept once.
func test_a_long_log_rolls_over() -> void:
	_cleanup()
	var log := SessionLog.new(LOG, true)
	log.max_bytes = 200
	for i in 20:
		log.write("regel %d" % i)
	assert_true(FileAccess.get_file_as_string(LOG).length() <= 200 + 64)
	assert_true(FileAccess.file_exists(LOG + ".old"))
	_cleanup()


## Where a session ended and how many loops it left open.
func test_the_end_of_a_session_is_described() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(SessionLog.ended_at(s, true), "dagstart")
	assert_eq(SessionLog.ended_at(s, false), "elders")
	s.accept("fix_custom_design")
	assert_eq(SessionLog.ended_at(s, false), "onderzoek", "a main problem being investigated")
	assert_eq(SessionLog.open_loops(s), 1, "one active mission")
