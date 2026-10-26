class_name DesignerSaves
## Saves that jump to a play day, for the designer's playtests (Designer): the autoplay bot
## plays to the stop and tools/make_saves.gd writes a slot in DIR; the main menu loads one into
## the autosave. A save carries the hash of the content it was made on, so a stale one shows.
## Lives in src (the build needs it); the bot and the writer stay in tools (not exported).

const DIR := SaveFile.DIR + "/designer"
## One save per jump: a play day (`stop_day`) or the opening of an act (`stop_act`).
const SAVES: Array[Dictionary] = [
	{"slot": "designer_training_done", "stop_day": 5.0},
	{"slot": "designer_day045", "stop_day": 45.0},
	{"slot": "designer_day070", "stop_day": 70.0},
	{"slot": "designer_day095", "stop_day": 95.0},
	{"slot": "designer_act2", "stop_act": 2},
]
## What a save's content hash covers: the missions and the problems they play on.
const HASHED: Array[String] = ["missions.json", "problems_tier1.json"]


## SHA-256 (hex) of the mission and problem content; "" when a file is missing.
static func content_hash() -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	for file: String in HASHED:
		var path := "%s/%s" % [Catalog.DATA_DIR, file]
		if not FileAccess.file_exists(path):
			return ""
		hashing.update(FileAccess.get_file_as_bytes(path))
	return hashing.finish().hex_encode()


## Copy a designer save's bytes into the autosave slot, so Doorgaan opens it. "" or what went wrong.
static func load_into_autosave(slot: String, from_dir: String = DIR, to_dir: String = SaveFile.DIR) -> String:
	if not SaveFile.valid_slot(slot) or not FileAccess.file_exists(SaveFile.path_of(slot, from_dir)):
		return "no designer save %s" % slot
	return SaveFile.store(GameSave.AUTOSAVE, FileAccess.get_file_as_bytes(SaveFile.path_of(slot, from_dir)), to_dir)
