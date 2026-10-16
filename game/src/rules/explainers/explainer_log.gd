class_name ExplainerLog
extends RefCounted
## Which "Hoe werkt het?" explainers the player has seen (the codex lists
## them) and whether the reveal ("Laat de rekensom zien") was left open.
## Saved with the game; ids are checked against the content on load.

var seen: Array[String] = []
var reveal_open := false


func see(id: String) -> void:
	if not seen.has(id):
		seen.append(id)


func has_seen(id: String) -> bool:
	return seen.has(id)


func to_dict() -> Dictionary:
	return {"seen": seen.duplicate(), "reveal_open": reveal_open}


## Restore from a save: an id the content no longer knows is dropped, a
## broken field loads as its default.
func load_dict(d: Dictionary, known: Array) -> void:
	seen.clear()
	var list: Variant = d.get("seen", [])
	if list is Array:
		for id: Variant in list:
			if id is String and known.has(id):
				see(id)
	var open: Variant = d.get("reveal_open", false)
	reveal_open = open if open is bool else false
