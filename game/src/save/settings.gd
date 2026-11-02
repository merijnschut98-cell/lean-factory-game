class_name Settings
extends RefCounted
## The player's settings (user://settings.cfg): the one place that reads and
## writes them. Sections in use: "text" (auto), "minimap" (shown, turns),
## "privacy" (playtest_log), "audio" (master, muted). A missing or damaged file,
## or a value of the wrong type, gives the caller's default: settings never stop
## play. `path` is for tests (they point it at a scratch file).

const PATH := "user://settings.cfg"


static func get_bool(section: String, key: String, default: bool, path: String = PATH) -> bool:
	var v: Variant = _read(section, key, default, path)
	return v if v is bool else default


static func get_float(section: String, key: String, default: float, path: String = PATH) -> float:
	var v: Variant = _read(section, key, default, path)
	return float(v) if v is float or v is int else default


## "" or what went wrong. The other keys in the file stay as they were; a damaged
## file is replaced by one holding what could be kept (nothing) plus this value.
static func set_value(section: String, key: String, value: Variant, path: String = PATH) -> String:
	var config := ConfigFile.new()
	config.load(path)   # missing or damaged: starts empty
	config.set_value(section, key, value)
	var err := config.save(path)
	return "" if err == OK else "instellingen niet bewaard: %s (%s)" % [path, error_string(err)]


static func _read(section: String, key: String, default: Variant, path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return default
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("settings: %s is unreadable, using the defaults" % path)
		return default
	return config.get_value(section, key, default)
