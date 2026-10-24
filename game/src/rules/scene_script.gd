class_name SceneScript
## A milestone's scene (content/scenes.yaml; phase-2 design §3.1) as it plays now: the
## beats whose `needs` hold (the facts choose the lines: which fixes hold, who
## committed, who left), split at the one question the player answers: a choice, or
## the KPI board (`board: true`, PLAN 2.4c: its line is said, then the board opens). Pure:
## the facts come in as `knows` (Missions.knows), names and tokens are the caller's.


## {room, present, before: [{who, text}], choice: {who, text, options: [{label, fact,
## reply}]} ({} when it asks nothing), board (whether the KPI board opens after
## `before`), after: [{who, text}]}; who is a cast id. A board scene's `after` reads the
## facts as they are when it is played, so the caller plays it again once the board closes.
static func play(scene: Dictionary, knows: Callable) -> Dictionary:
	var out := {"room": str(scene.get("room", "")), "present": scene.get("present", []), "before": [], "choice": {},
		"board": false, "after": []}
	for beat: Variant in scene.get("beats", []):
		if not beat is Dictionary or not Facts.met(JsonFile.dict_or_empty(beat.get("needs")), knows):
			continue
		var line := {"who": str(beat.get("speaker", "")), "text": str(beat.get("line", ""))}
		var asked: bool = not out["choice"].is_empty() or out["board"]
		if beat.get("choice") is Array and not asked:
			line["options"] = (beat["choice"] as Array).map(func(o: Variant) -> Dictionary:
				var d := JsonFile.dict_or_empty(o)
				return {"label": str(d.get("label", "")), "fact": str(d.get("fact", "")), "reply": str(d.get("reply", ""))})
			out["choice"] = line
		elif beat.get("board") == true and not asked:
			out["before"].append(line)
			out["board"] = true
		else:
			out["after" if asked else "before"].append(line)
	return out
