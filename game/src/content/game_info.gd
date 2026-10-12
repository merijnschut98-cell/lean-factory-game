class_name GameInfo
extends RefCounted
## World identity loaded from res://data/game.json (built from content/game.yaml).

const PATH := "res://data/game.json"
const REQUIRED := ["company", "region", "town", "campus", "player_role", "locale"]

var company := ""
var region := ""
var town := ""
var campus := ""
var player_role := ""
var locale := ""
## Empty when the data loaded cleanly; otherwise what was wrong.
var error := ""


static func load_from(path: String = PATH) -> GameInfo:
	var info := GameInfo.new()
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		info.error = "cannot read %s (%s)" % [path, error_string(FileAccess.get_open_error())]
		return info
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		info.error = "%s is not a JSON object" % path
		return info
	for key in REQUIRED:
		var value: Variant = parsed.get(key)
		if not value is String or (value as String).strip_edges().is_empty():
			info.error = "%s: '%s' must be a non-empty string" % [path, key]
			return info
		info.set(key, value)
	return info
