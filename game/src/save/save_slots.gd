class_name SaveSlots
extends RefCounted
## The player's saves (PLAN 2.7): five manual slots and the autosave, kept
## apart. The player saves into slot 1–5 by hand (the pause menu); the game
## saves itself into the autosave only, so it never eats a manual save. The
## title menu lists them most recently used first (saved, or continued
## from), each with its meta (GameSave.meta) or why it cannot be played: too
## old, from a newer build, or damaged. "Alles wissen" deletes them all.
## Paths come only from the folder (fixed, under user://) and the fixed slot
## names; nothing the player types reaches them.

const COUNT := 5
const AUTOSAVE := GameSave.AUTOSAVE
## An entry's status.
const PLAYABLE := "ok"
const DAMAGED := "damaged"
const TOO_OLD := "too_old"
const TOO_NEW := "too_new"
const _STATUS := {SaveFile.Fault.DAMAGED: DAMAGED, SaveFile.Fault.TOO_OLD: TOO_OLD, SaveFile.Fault.TOO_NEW: TOO_NEW}
## When each slot was last used (saved or continued from): small JSON beside
## the saves. Lost or damaged, the save times stand in.
const INDEX := "last_used.json"

var dir: String
## The real time in unix seconds (tests set their own clock).
var now: Callable = func() -> float: return Time.get_unix_time_from_system()


func _init(saves_dir: String = SaveFile.DIR) -> void:
	dir = saves_dir


## The name of manual slot `n`; "" for a number outside 1–5.
static func manual(n: int) -> String:
	return "slot_%d" % n if n >= 1 and n <= COUNT else ""


## The autosave and the five manual slots, by name.
static func names() -> Array[String]:
	var out: Array[String] = [AUTOSAVE]
	for n in range(1, COUNT + 1):
		out.append(manual(n))
	return out


## The folder is the game's own: under user://, never climbing out.
func valid() -> bool:
	return dir.begins_with("user://") and not ".." in dir and not "\\" in dir


func index_path() -> String:
	return dir.path_join(INDEX)


## Save the game into manual slot `n` (1–5). "" or what went wrong.
func save(n: int, s: GameSession, layer: SessionLayer) -> String:
	var slot := manual(n)
	if slot.is_empty():
		return "no save slot %d (1 to %d)" % [n, COUNT]
	return _write(slot, s, layer)


## Copy the autosave byte for byte into manual slot `n` (1–5), so a new game
## can replace it (the title menu's "Eerst bewaren in een slot"). "" or what
## went wrong; nothing is copied unless the autosave is whole and playable.
func copy_autosave(n: int) -> String:
	var slot := manual(n)
	if slot.is_empty():
		return "no save slot %d (1 to %d)" % [n, COUNT]
	if not valid():
		return "not a saves folder: %s" % dir
	var loaded := SaveFile.load_slot(AUTOSAVE, dir)  # recovers what a crash left first
	if loaded["fault"] != SaveFile.Fault.NONE:
		return loaded["error"]
	var bytes := FileAccess.get_file_as_bytes(SaveFile.path_of(AUTOSAVE, dir))
	if bytes.is_empty():
		return "cannot read the autosave (%s)" % error_string(FileAccess.get_open_error())
	var error := SaveFile.store(slot, bytes, dir)
	if error.is_empty():
		_mark_used(slot)
	return error


## Save the game into the autosave slot. "" or what went wrong.
func autosave(s: GameSession, layer: SessionLayer) -> String:
	return _write(AUTOSAVE, s, layer)


## GameSave.read's result for one of names(); continuing from it uses it.
func resume(slot: String, data_dir: String = Catalog.DATA_DIR) -> Dictionary:
	if not valid() or not slot in names():
		return {"error": "no save slot %s" % slot, "session": null, "layer": null, "dropped": []}
	var loaded := GameSave.read(slot, data_dir, dir)
	if loaded["error"].is_empty():
		_mark_used(slot)
	return loaded


## One slot as the menus show it: {slot, number (0 for the autosave),
## status, name ("" none or invalid), portrait (PNG bytes, empty none or
## invalid), act (-1 unknown), time (the game's, -1 unknown), saved, used
## (unix seconds)}; {} when the slot is empty.
func entry(slot: String) -> Dictionary:
	if not valid() or not slot in names():
		return {}
	var loaded := SaveFile.load_slot(slot, dir)
	if loaded["fault"] == SaveFile.Fault.MISSING:
		return {}
	var data: Dictionary = loaded["data"]
	var meta := JsonFile.dict_or_empty(data.get("meta"))
	var out := {"slot": slot, "number": 0 if slot == AUTOSAVE else slot.to_int(),
		"status": _STATUS.get(loaded["fault"], PLAYABLE), "name": PlayerProfile.stored_name(meta.get("name")),
		"portrait": PlayerProfile.valid_portrait(meta.get("portrait")),
		"act": _typed(meta, "act", TYPE_INT, -1), "time": _typed(meta, "time", TYPE_INT, _region_time(data)),
		"saved": float(_typed(meta, "saved", TYPE_FLOAT, _modified(slot)))}
	out["used"] = float(_read_index().get(slot, out["saved"]))
	return out


## Every save, most recently used first; those that cannot be played after
## the rest (their file time is no use).
func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in names():
		var e := entry(slot)
		if not e.is_empty():
			out.append(e)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_plays: bool = a["status"] == PLAYABLE
		return a_plays if a_plays != (b["status"] == PLAYABLE) else a["used"] > b["used"])
	return out


## Delete every save in the folder (and the index): a clean start for a test
## run. Other files there (the playtest log) stay. "" or what went wrong.
func wipe() -> String:
	if not valid():
		return "not a saves folder: %s" % dir
	if not DirAccess.dir_exists_absolute(dir):
		return ""
	var failed: PackedStringArray = []
	for file in DirAccess.get_files_at(dir):
		if file == INDEX or file.trim_suffix(SaveFile.TEMP).trim_suffix(SaveFile.BACKUP).ends_with(".save"):
			var error := DirAccess.remove_absolute(dir.path_join(file))
			if error != OK:
				failed.append("%s (%s)" % [file, error_string(error)])
	return "" if failed.is_empty() else "cannot delete " + ", ".join(failed)


func _write(slot: String, s: GameSession, layer: SessionLayer) -> String:
	if not valid():
		return "not a saves folder: %s" % dir
	var error := GameSave.write(slot, s, layer, dir, now.call())
	if error.is_empty():
		_mark_used(slot)
	return error


## Record a slot's use. A failure only costs the order, never the save.
func _mark_used(slot: String) -> void:
	var index := _read_index()
	index[slot] = now.call()
	var file := FileAccess.open(index_path(), FileAccess.WRITE)
	if file == null:
		push_warning("save slots: cannot write %s (%s)" % [index_path(), error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(index))
	file.close()


## {slot: unix seconds}, only the known slots with finite numbers.
func _read_index() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(index_path()):
		return out
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(index_path())) != OK or not json.data is Dictionary:
		return out
	for slot: Variant in json.data:
		var t: Variant = json.data[slot]
		if slot is String and slot in names() and (t is float or t is int) and is_finite(t):
			out[slot] = float(t)
	return out


## A version-1 save has no meta: its game time from the region.
static func _region_time(data: Dictionary) -> int:
	var network := JsonFile.dict_or_empty(JsonFile.dict_or_empty(data.get("region")).get("network"))
	return network["time"] if network.get("time") is int else -1


func _modified(slot: String) -> float:
	return float(FileAccess.get_modified_time(SaveFile.path_of(slot, dir)))


static func _typed(d: Dictionary, key: String, type: int, fallback: Variant) -> Variant:
	var v: Variant = d.get(key)
	if type == TYPE_FLOAT and v is int:
		return float(v)
	return v if typeof(v) == type and (type != TYPE_FLOAT or is_finite(v)) else fallback
