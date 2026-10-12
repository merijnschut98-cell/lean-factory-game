class_name JsonFile
## Reads a JSON object from a file with a precise error message.


## Returns {"data": Dictionary, "error": String}; `error` is empty on success.
static func read_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {"data": {}, "error": "cannot read %s (%s)" % [path, error_string(FileAccess.get_open_error())]}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {"data": {}, "error": "%s is not a JSON object" % path}
	return {"data": parsed, "error": ""}
