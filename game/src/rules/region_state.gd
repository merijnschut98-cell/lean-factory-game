class_name RegionState
## Captures and restores a whole Region: its network (NetworkState) and the
## rules state (the player's progress, clues found, trust, every problem's
## place in the PDCA loop). Problems the content no longer has are dropped
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
	for team: Variant in d["trust"]:
		r.trust[str(team)] = int(d["trust"][team])
	for id: String in d["problems"]:
		var saved: Variant = d["problems"][id]
		if not (r.state.has(id) and saved is Dictionary and r.state[id].load_dict(saved)):
			dropped.append(id)
	return {"error": "", "dropped": dropped}
