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
## SHA-256 (hex) of all the content a save was made on: every *.json in `data_dir`, name and
## bytes, in sorted order (a dialog changed makes a save as stale as a mission changed);
## "" when there is none.
static func content_hash(data_dir: String = Catalog.DATA_DIR) -> String:
	var files := Array(DirAccess.get_files_at(data_dir)).filter(func(f: String) -> bool: return f.get_extension() == "json")
	if files.is_empty():
		return ""
	files.sort()
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	for file: String in files:
		hashing.update(file.to_utf8_buffer())
		hashing.update(FileAccess.get_file_as_bytes(data_dir.path_join(file)))
	return hashing.finish().hex_encode()


## Copy a designer save's bytes into the autosave slot, so Doorgaan opens it. "" or what went wrong.
static func load_into_autosave(slot: String, from_dir: String = DIR, to_dir: String = SaveFile.DIR) -> String:
	if not SaveFile.valid_slot(slot) or not FileAccess.file_exists(SaveFile.path_of(slot, from_dir)):
		return "no designer save %s" % slot
	return SaveFile.store(GameSave.AUTOSAVE, FileAccess.get_file_as_bytes(SaveFile.path_of(slot, from_dir)), to_dir)
