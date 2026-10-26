class_name SessionLog
extends RefCounted
## The local playtest log (engagement loop §8, Q8): a readable text file in
## the save folder for Merijn's own play. One line per moment, with the real
## date and time: a session's start and end (its real minutes, where it
## ended, the loops it left open), missions taken on, the first key clue,
## discoveries. It holds game events only, nothing about the player, and is
## never sent anywhere. The player can switch it off (the journal); the
## choice lives in the settings file.

const PATH := "user://saves/playtest_log.txt"
## The designer's F8 markers (Markdown, handed back after a playtest), beside the log.
const MARKERS := "user://saves/playtest_markers.md"
## A marker's own line is cut here, the events under it are the last RECENT of the layer.
const MARKER_MAX_CHARS := 500
const MARKER_RECENT := 5
const _SECTION := "privacy"
const _KEY := "playtest_log"
## A log past this size starts a new file; the previous one is kept once
## (".old").
const MAX_BYTES := 512 * 1024

var path: String
var markers_path: String
var enabled: bool
var max_bytes := MAX_BYTES


func _init(log_path: String = PATH, on: bool = true) -> void:
	path = log_path
	markers_path = log_path.get_base_dir().path_join(MARKERS.get_file())
	enabled = on


## The log in a saves folder, as the settings say (on unless switched off).
static func from_settings(settings: String = Settings.PATH, saves_dir: String = SaveFile.DIR) -> SessionLog:
	return SessionLog.new(saves_dir.path_join(PATH.get_file()), enabled_in(settings))


static func enabled_in(settings: String = Settings.PATH) -> bool:
	return Settings.get_bool(_SECTION, _KEY, true, settings)


## "" or what went wrong.
static func set_enabled_in(settings: String, on: bool) -> String:
	return Settings.set_value(_SECTION, _KEY, on, settings)


## Append one line with the real date and time. "" (also when switched
## off) or what went wrong, also as a warning: a log that cannot be written
## never stops play.
func write(line: String) -> String:
	if not enabled:
		return ""
	var error := _append("[%s] %s\n" % [Time.get_datetime_string_from_system(false, true), line])
	if not error.is_empty():
		push_warning("playtest log: " + error)
	return error


## One designer marker (F8) as a Markdown block: day, time, place and the active main
## mission in a header, the designer's line, the last events he saw. Written whether or
## not the log is on (he asked for it). "" or what went wrong, also as a warning.
func marker(text: String, s: GameSession, layer: SessionLayer, place := "") -> String:
	var t := s.region.net.time
	var minute := GameSession.minute_at(t)
	var main := s.missions.active("main")
	var block := "## dag %d · %02d:%02d · %s · %s\n\n%s\n\n" % [SimCalendar.day_of(t) - GameSession.WARMUP_DAYS,
		minute / 60, minute % 60, _one_line(place, "-"), main[0].id if not main.is_empty() else "geen",
		_one_line(text.left(MARKER_MAX_CHARS), "-")]
	for event in layer.recent.slice(-MARKER_RECENT):
		block += "- %s\n" % _one_line(event, "-")
	var error := _append(block + "\n", markers_path)
	if not error.is_empty():
		push_warning("playtest markers: " + error)
	return error


## Player text on one line that starts no Markdown block (heading, quote, list, code, table).
static func _one_line(text: String, empty: String) -> String:
	var line := " ".join(text.replace("\r", "\n").split("\n", false)).replace("\t", " ").strip_edges()
	if line.is_empty():
		return empty
	return "\\" + line if line[0] in "#>-*+`|" else line


func _append(text: String, to := path) -> String:
	var dir_error := DirAccess.make_dir_recursive_absolute(to.get_base_dir())
	if dir_error != OK:
		return "cannot create %s (%s)" % [to.get_base_dir(), error_string(dir_error)]
	var file := FileAccess.open(to, FileAccess.READ_WRITE if FileAccess.file_exists(to) else FileAccess.WRITE)
	if file != null and file.get_length() > max_bytes:
		file.close()
		DirAccess.remove_absolute(to + ".old")
		DirAccess.rename_absolute(to, to + ".old")
		file = FileAccess.open(to, FileAccess.WRITE)
	if file == null:
		return "cannot write %s (%s)" % [to, error_string(FileAccess.get_open_error())]
	file.seek_end()
	file.store_string(text)
	file.close()
	return ""


## Where a session ended: dagstart (the natural stop) | check (an
## experiment running) | onderzoek (a mission's problem being investigated)
## | elders.
static func ended_at(s: GameSession, at_dagstart: bool) -> String:
	if at_dagstart:
		return "dagstart"
	var phases := s.active_missions().map(func(m: MissionDef) -> String: return s.phase_of(m.goal_problem))
	if not SessionLayer.running(s).is_empty():
		return "check"
	if phases.any(func(p: String) -> bool: return p in ["active", "spotted"]):
		return "onderzoek"
	return "elders"


## The loops a session leaves open: active missions and the check-ins and
## repairs waiting on the board.
static func open_loops(s: GameSession) -> int:
	return s.active_missions().size() + s.available_missions().filter(func(m: MissionDef) -> bool:
		return SessionLayer.is_built(m)).size()
