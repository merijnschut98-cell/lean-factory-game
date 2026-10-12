class_name GameInfo
extends RefCounted
## World identity loaded from res://data/game.json (built from content/game.yaml).

const PATH := "res://data/game.json"

var company := ""
var region := ""
var town := ""
var campus := ""
var player_role := ""
var locale := ""
## Empty when the data loaded cleanly; otherwise what was wrong.
## (Not a content field: every other String property above is required in the JSON.
## The schema itself is owned by tools/build_content.py; this is the load-time recheck.)
var error := ""


static func load_from(path: String = PATH) -> GameInfo:
	var info := GameInfo.new()
	var file := JsonFile.read_dict(path)
	info.error = file["error"]
	if not info.error.is_empty():
		return info
	var parsed: Dictionary = file["data"]
	for key in info._content_fields():
		var value: Variant = parsed.get(key)
		if not value is String or (value as String).strip_edges().is_empty():
			info.error = "%s: '%s' must be a non-empty string" % [path, key]
			return info
		info.set(key, value)
	return info


func _content_fields() -> PackedStringArray:
	var out: PackedStringArray = []
	for prop in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and prop["type"] == TYPE_STRING and prop["name"] != "error":
			out.append(prop["name"])
	return out
