class_name GameSave
## A whole game in one save slot (SaveFile): the region with its network,
## the missions, the discoveries, the El Amrani dossier, the session layer
## (the snapshot the next terugblik compares with) and the meta a save list
## shows (SaveSlots). The game saves itself at every dagstart and when it
## closes, so stopping never loses anything. A save from before the missions
## were saved has the region only: it loads as a returning player's game on
## that region, with no terugblik.

## The slot the game saves itself to (SaveSlots keeps it apart from the five).
const AUTOSAVE := "autosave"


static func exists(slot: String = AUTOSAVE, dir: String = SaveFile.DIR) -> bool:
	return SaveFile.valid_slot(slot) and FileAccess.file_exists(SaveFile.path_of(slot, dir))


## "" or what went wrong. `saved`: the real time (unix seconds) it is saved at.
static func write(slot: String, s: GameSession, layer: SessionLayer, dir: String = SaveFile.DIR,
		saved: float = Time.get_unix_time_from_system()) -> String:
	return SaveFile.write(slot, s.region, {"missions": s.missions.to_dict(), "discoveries": s.discoveries.to_dict(),
		"followed": s.followed.to_dict(), "session": layer.to_dict(), "meta": meta(s, saved)}, dir)


## What a save list shows: the player's name ("" until the character creator,
## PLAN 2.7b), the act, the game's time and the real time it was saved.
static func meta(s: GameSession, saved: float) -> Dictionary:
	return {"name": "", "act": s.missions.current_act(), "time": s.region.net.time, "saved": saved}


## {error, session, layer, dropped}: a session built from the current content
## and restored from the slot. On an error session and layer are null.
static func read(slot: String = AUTOSAVE, data_dir: String = Catalog.DATA_DIR, dir: String = SaveFile.DIR) -> Dictionary:
	var failed := {"session": null, "layer": null, "dropped": []}
	if not exists(slot, dir):
		failed["error"] = "no save in slot %s" % slot
		return failed
	var s := GameSession.new_game(1, data_dir, false)
	if not s.error.is_empty():
		failed["error"] = s.error
		return failed
	var result := SaveFile.read(slot, s.region, dir)
	if not result["error"].is_empty():
		failed["error"] = result["error"]
		return failed
	var extra: Dictionary = result["extra"]
	var dropped: Array = result["dropped"]
	if extra.has("missions"):
		dropped.append_array(s.missions.load_dict(extra["missions"]))
	if extra.has("discoveries"):
		s.discoveries.load_dict(extra["discoveries"])
	if extra.get("followed") is Dictionary:
		s.followed.load_dict(extra["followed"])  # else the new game's pick stands
	var layer := SessionLayer.new()
	layer.load_dict(extra.get("session", {}))
	s.drain_events()  # the throwaway new game's, not the player's
	return {"error": "", "session": s, "layer": layer, "dropped": dropped}
