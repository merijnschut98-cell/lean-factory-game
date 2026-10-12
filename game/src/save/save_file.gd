class_name SaveFile
## Save files: one file per slot in user://saves, with a schema version.
## Godot's binary Variant encoding (var_to_bytes) keeps every value exact:
## ints, 64-bit random state, int keys and floats to the last bit (Godot's
## JSON rounds floats to a few digits). Loading never creates objects.
## Written to a temporary file first and then renamed, so a crash mid-write
## never leaves a half-written save. Slot names are restricted so a path
## never leaves the saves folder.

const VERSION := 1
const DIR := "user://saves"
const _SLOT := "^[a-z0-9_]{1,40}$"


static func path_of(slot: String) -> String:
	return "%s/%s.save" % [DIR, slot]


static func valid_slot(slot: String) -> bool:
	return RegEx.create_from_string(_SLOT).search(slot) != null


## Save a region (with its network). Returns "" or what went wrong.
static func write(slot: String, region: Region) -> String:
	if not valid_slot(slot):
		return "invalid save slot name %s" % slot
	var dir_error := DirAccess.make_dir_recursive_absolute(DIR)
	if dir_error != OK:
		return "cannot create %s (%s)" % [DIR, error_string(dir_error)]
	var path := path_of(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "cannot write %s (%s)" % [temp, error_string(FileAccess.get_open_error())]
	file.store_buffer(var_to_bytes({"version": VERSION, "region": RegionState.capture(region)}))
	file.close()
	var rename_error := DirAccess.rename_absolute(temp, path)
	if rename_error != OK and FileAccess.file_exists(path):
		# Some platforms do not rename over an existing file.
		DirAccess.remove_absolute(path)
		rename_error = DirAccess.rename_absolute(temp, path)
	if rename_error != OK:
		return "cannot move %s into place (%s)" % [temp, error_string(rename_error)]
	return ""


## Load a slot into `region`, built fresh from the current content (and its
## network). Returns {error, dropped}; on an error, discard the region.
static func read(slot: String, region: Region) -> Dictionary:
	if not valid_slot(slot):
		return {"error": "invalid save slot name %s" % slot, "dropped": []}
	var bytes := FileAccess.get_file_as_bytes(path_of(slot))
	if bytes.is_empty():
		return {"error": "cannot read %s (%s)" % [path_of(slot), error_string(FileAccess.get_open_error())], "dropped": []}
	var data: Variant = bytes_to_var(bytes)  # never creates objects
	if not data is Dictionary or data.get("version") != VERSION:
		return {"error": "save version %s, this game reads version %d" % [
			data.get("version") if data is Dictionary else "?", VERSION], "dropped": []}
	var shape := JsonFile.shape_error(data, {"region": TYPE_DICTIONARY})
	if not shape.is_empty():
		return {"error": shape, "dropped": []}
	return RegionState.restore(region, data["region"])
