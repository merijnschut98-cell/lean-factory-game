class_name SaveFile
## Save files: one JSON file per slot in user://saves, with a schema
## version. Written to a temporary file first and then renamed, so a crash
## mid-write never leaves a half-written save. Slot names are restricted so
## a path can never leave the saves folder.

const VERSION := 1
const DIR := "user://saves"
const _SLOT := "^[a-z0-9_]{1,40}$"


static func path_of(slot: String) -> String:
	return "%s/%s.json" % [DIR, slot]


static func valid_slot(slot: String) -> bool:
	var re := RegEx.create_from_string(_SLOT)
	return re.search(slot) != null


## Save a region and its network. Returns "" or what went wrong.
static func write(slot: String, region: Region) -> String:
	if not valid_slot(slot):
		return "invalid save slot name %s" % slot
	var dir_error := DirAccess.make_dir_recursive_absolute(DIR)
	if dir_error != OK:
		return "cannot create %s (%s)" % [DIR, error_string(dir_error)]
	var data := {"version": VERSION, "network": NetworkState.capture(region.net), "region": RegionState.capture(region)}
	var path := path_of(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "cannot write %s (%s)" % [temp, error_string(FileAccess.get_open_error())]
	file.store_string(JSON.stringify(data))
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
	var file := JsonFile.read_dict(path_of(slot))
	if not file["error"].is_empty():
		return {"error": file["error"], "dropped": []}
	var data: Dictionary = file["data"]
	if int(data.get("version", 0)) != VERSION:
		return {"error": "save version %s, this game reads version %d" % [data.get("version"), VERSION], "dropped": []}
	if not (data.get("network") is Dictionary and data.get("region") is Dictionary):
		return {"error": "save is missing the network or the region", "dropped": []}
	var net := NetworkState.restore(region.net, data["network"])
	if not net["error"].is_empty():
		return net
	var rules := RegionState.restore(region, data["region"])
	if not rules["error"].is_empty():
		return rules
	return {"error": "", "dropped": net["dropped"] + rules["dropped"]}
