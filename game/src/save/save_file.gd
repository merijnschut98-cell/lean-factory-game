class_name SaveFile
## Save files: one file per slot in a saves folder (user://saves), with a
## schema version. Godot's binary Variant encoding (var_to_bytes) keeps every
## value exact: ints, 64-bit random state, int keys and floats to the last
## bit (Godot's JSON rounds floats to a few digits). Loading never creates
## objects. Written to a temporary file first and then renamed, so a crash
## mid-write never leaves a half-written save. Slot names are restricted so
## a path never leaves the saves folder.
##
## Since version 2 a file starts with MAGIC and the SHA-256 of what follows,
## so a damaged file is recognised before it is decoded. Version 1 files are
## the bare encoding and still load.

const VERSION := 2
## The oldest version this game still reads; older saves are marked "te oud".
const OLDEST := 1
const DIR := "user://saves"
const MAGIC := "SPN2"
const _HASH_BYTES := 32
## Bigger than any real save (a game is well under 1 MB): refused unread.
const MAX_BYTES := 64 * 1024 * 1024
const _SLOT := "^[a-z0-9_]{1,40}$"
## The rest of a game beside the region (GameSave): each key optional, a
## Dictionary. "meta" is what a save list shows without loading the game.
const EXTRA: Array[String] = ["missions", "discoveries", "followed", "explainers", "people", "session", "meta"]

## Why a file cannot be read, for the save list (SaveSlots).
enum Fault { NONE, MISSING, DAMAGED, TOO_OLD, TOO_NEW }


static func path_of(slot: String, dir: String = DIR) -> String:
	return "%s/%s.save" % [dir, slot]


static func valid_slot(slot: String) -> bool:
	return RegEx.create_from_string(_SLOT).search(slot) != null


## A save's bytes: MAGIC, the hash of the encoding, the encoding.
static func encode(data: Dictionary) -> PackedByteArray:
	var payload := var_to_bytes(data)
	var out := MAGIC.to_ascii_buffer()
	out.append_array(_sha256(payload))
	out.append_array(payload)
	return out


## {fault, data, error}: a file's bytes back to its Dictionary, its version
## checked. A version-1 file (the bare encoding) is decoded only when it
## starts as an encoded Dictionary, so junk never reaches the decoder.
static func decode(bytes: PackedByteArray) -> Dictionary:
	var payload := bytes
	if bytes.size() >= MAGIC.length() and bytes.slice(0, MAGIC.length()).get_string_from_ascii() == MAGIC:
		var start := MAGIC.length() + _HASH_BYTES
		payload = bytes.slice(start)
		if payload.is_empty() or _sha256(payload) != bytes.slice(MAGIC.length(), start):
			return _fault(Fault.DAMAGED, "the save is damaged (its checksum does not match)")
	elif bytes.size() < 8 or bytes.decode_u8(0) != TYPE_DICTIONARY:
		return _fault(Fault.DAMAGED, "the save is damaged (not a save file)")
	var data: Variant = bytes_to_var(payload)  # never creates objects
	if not data is Dictionary:
		return _fault(Fault.DAMAGED, "the save is damaged (no game in it)")
	var version: Variant = data.get("version")
	if not version is int:
		return _fault(Fault.DAMAGED, "the save has no version")
	if version < OLDEST:
		return _fault(Fault.TOO_OLD, "save version %d, this game reads versions %d to %d" % [version, OLDEST, VERSION])
	if version > VERSION:
		return _fault(Fault.TOO_NEW, "save version %d, this game reads versions %d to %d" % [version, OLDEST, VERSION])
	return {"fault": Fault.NONE, "data": data, "error": ""}


## Save a region (with its network), and the rest of a game in `extra`
## (EXTRA's keys only). Returns "" or what went wrong.
static func write(slot: String, region: Region, extra: Dictionary = {}, dir: String = DIR) -> String:
	if not valid_slot(slot):
		return "invalid save slot name %s" % slot
	var dir_error := DirAccess.make_dir_recursive_absolute(dir)
	if dir_error != OK:
		return "cannot create %s (%s)" % [dir, error_string(dir_error)]
	var path := path_of(slot, dir)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "cannot write %s (%s)" % [temp, error_string(FileAccess.get_open_error())]
	var data := {"version": VERSION, "region": RegionState.capture(region)}
	for key: String in EXTRA:
		if extra.get(key) is Dictionary:
			data[key] = extra[key]
	var stored := file.store_buffer(encode(data))
	file.close()
	if not stored:
		DirAccess.remove_absolute(temp)
		return "cannot write %s (disk full?)" % temp
	var rename_error := DirAccess.rename_absolute(temp, path)
	if rename_error != OK and FileAccess.file_exists(path):
		# Some platforms do not rename over an existing file.
		DirAccess.remove_absolute(path)
		rename_error = DirAccess.rename_absolute(temp, path)
	if rename_error != OK:
		return "cannot move %s into place (%s)" % [temp, error_string(rename_error)]
	return ""


## {fault, data, error}: a slot's file decoded (decode), unread when it is
## missing or too big.
static func load_slot(slot: String, dir: String = DIR) -> Dictionary:
	if not valid_slot(slot):
		return _fault(Fault.MISSING, "invalid save slot name %s" % slot)
	var path := path_of(slot, dir)
	if not FileAccess.file_exists(path):
		return _fault(Fault.MISSING, "no save in slot %s" % slot)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fault(Fault.DAMAGED, "cannot read %s (%s)" % [path, error_string(FileAccess.get_open_error())])
	if file.get_length() > MAX_BYTES:
		return _fault(Fault.DAMAGED, "%s is too big to be a save" % path)
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return decode(bytes)


## Load a slot into `region`, built fresh from the current content (and its
## network). Returns {error, dropped, extra (EXTRA's keys that hold a
## Dictionary, untrusted inside)}; on an error, discard the region.
static func read(slot: String, region: Region, dir: String = DIR) -> Dictionary:
	var loaded := load_slot(slot, dir)
	if loaded["fault"] != Fault.NONE:
		return {"error": loaded["error"], "dropped": [], "extra": {}}
	var data: Dictionary = loaded["data"]
	var shape := JsonFile.shape_error(data, {"region": TYPE_DICTIONARY})
	if not shape.is_empty():
		return {"error": shape, "dropped": [], "extra": {}}
	var result := RegionState.restore(region, data["region"])
	result["extra"] = {}
	for key: String in EXTRA:
		if data.get(key) is Dictionary:
			result["extra"][key] = data[key]
	return result


static func _fault(fault: Fault, error: String) -> Dictionary:
	return {"fault": fault, "data": {}, "error": error}


static func _sha256(bytes: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish()
