class_name RegionState
## Captures and restores a whole Region: its network (NetworkState) and the
## rules state (the player's progress, clues found, trust, every problem's
## place in the PDCA loop and how worn its fix is, the KPI board, the drift,
## the planned routines and the reputation). Problems the content no longer has are dropped
## and reported.

const SHAPE := {
	"network": TYPE_DICTIONARY, "profile": TYPE_DICTIONARY, "observed": TYPE_ARRAY, "found": TYPE_ARRAY,
	"trust": TYPE_DICTIONARY, "problems": TYPE_DICTIONARY,
}


static func capture(r: Region) -> Dictionary:
	var problems := {}
	for st: ProblemState in r.state.values():
		problems[st.id] = st.to_dict()
	return {
		"network": NetworkState.capture(r.net),
		"profile": {"budget": r.profile.budget, "xp": r.profile.xp, "concepts": r.profile.concepts},
		"observed": r.observed.keys(), "found": r.found.keys(), "trust": r.trust, "problems": problems,
		"cost_owed": r._cost_owed, "kpi_board": r.board.to_dict(), "drift_from": r.drift_from,
		"floor_days": r.floor_days, "advance_owed": r.advance_owed,
		"routines": r.routines.keys(), "reputation": r.reputation.value, "aftermaths": r.aftermaths.duplicate(true),
	}


## Restore into a Region freshly built from content (and its network).
## Returns {error, dropped}; on an error, discard the region.
static func restore(r: Region, d: Dictionary) -> Dictionary:
	var error := JsonFile.shape_error(d, SHAPE)
	if not error.is_empty():
		return {"error": error, "dropped": []}
	var result := NetworkState.restore(r.net, d["network"])
	if not result["error"].is_empty():
		return result
	var dropped: Array[String] = result["dropped"]
	r.profile.budget = int(d["profile"].get("budget", r.profile.budget))
	r.profile.xp = int(d["profile"].get("xp", 0))
	r.profile.concepts = PackedStringArray(d["profile"].get("concepts", []))
	for place: Variant in d["observed"]:
		r.observed[str(place)] = true
	for clue_id: Variant in d["found"]:
		r.found[str(clue_id)] = true
	r._cost_owed = float(d.get("cost_owed", 0.0))
	r.floor_days = maxi(0, JsonFile.int_or(d.get("floor_days"), 0))  # saves from before it: none counted
	r.advance_owed = maxi(0, JsonFile.int_or(d.get("advance_owed"), 0))  # junk or older saves: nothing owed
	# Saves from before reputation start where a new game does.
	r.reputation.value = clampi(int(d.get("reputation", Reputation.START)), 0, Reputation.MAX)
	r._apply_bad_period()
	# Saves from before drift have none: GameSession starts it when the campaign is open.
	r.drift_from = maxi(-1, int(d.get("drift_from", -1)))
	r._drift_applied = r.drift_level()  # its effects come back with the network's
	# A routine's team time comes back with the network's effects too.
	var routines: Variant = d.get("routines", [])
	for place: Variant in routines if routines is Array else []:
		if r.net.step_at(str(place)) != null:
			r.routines[str(place)] = true
	# A running aftermath's effects come back with the network's.
	var aftermaths := JsonFile.dict_or_empty(d.get("aftermaths"))
	for id: Variant in aftermaths:
		var a: Variant = aftermaths[id]
		if a is Dictionary and r.countermeasures.has(str(a.get("cm", ""))):
			r.aftermaths[str(id)] = {"cm": str(a["cm"]), "start": int(a.get("start", 0)), "end": int(a.get("end", 0)),
				"started": bool(a.get("started", false))}
	# Saves from before the board have none; its work rules come back with the network's effects.
	r.board.load_dict(JsonFile.dict_or_empty(d.get("kpi_board")))
	for team: Variant in d["trust"]:
		r.trust[str(team)] = int(d["trust"][team])
	for id: String in d["problems"]:
		var saved: Variant = d["problems"][id]
		if not (r.state.has(id) and saved is Dictionary and r.state[id].load_dict(saved)):
			dropped.append(id)
	return {"error": "", "dropped": dropped}
