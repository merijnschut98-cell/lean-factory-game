class_name PlaceActions
extends RefCounted
## What a player can do at a place (content/places.yaml, PLAN 2.12; spec
## docs/superpowers/specs/2026-10-18-place-actions.md): the gemba tools that
## fit the work there, each with the place's own Dutch label and its
## observations (how the work really runs, shown when a tool finds no clue),
## the questions to the people who work there, and who else can be met there.
## And the player's side of it, saved: the toolbox (the tools known, which
## grows with the training week: a mission's grant_tools), how far each
## place's observations have cycled, the journal's "Waarneming" lines, and
## where a "thanks" is due after a blame or a guarded reply. A place without
## an entry keeps every tool and the team's questions (a content set without
## places.json).

## Investigation.QUESTIONS' repair: never a chip of its own.
const THANKS := "thanks"

## place → {tools: {tool: {label, observations}}, order: [tool] (as listed), questions:
## [{id, person, text, reply}], people_also: [person id]}.
var places: Dictionary = {}
## tool → {title, text}: the cards Ruud's morning note shows (a day's new tools).
var tool_cards: Dictionary = {}
## The tools the player knows (GameSession grants them).
var known: Dictionary[String, bool] = {}
## "place|tool" → how many of its observations were shown (they cycle).
var shown: Dictionary[String, int] = {}
## Every observation shown, oldest first: [{day, place, tool, text}].
var journal: Array[Dictionary] = []
## place → the person whose blame or guarded reply a "thanks" can answer.
var repair_due: Dictionary[String, String] = {}


static func from_doc(doc: Dictionary) -> PlaceActions:
	var p := PlaceActions.new()
	var entries := JsonFile.dict_or_empty(doc.get("places"))
	for place: Variant in entries:
		var entry := JsonFile.dict_or_empty(entries[place])
		var tools := {}
		var order: Array[String] = []
		for item: Variant in entry.get("tools", []) if entry.get("tools") is Array else []:
			var t := JsonFile.dict_or_empty(item)
			var tool: Variant = t.get("tool")
			if tool is String and Investigation.TOOLS.has(tool) and tool != "conversation" and not tools.has(tool):
				order.append(tool)
				tools[tool] = {"label": str(t.get("label", "")), "observations": _texts(t.get("observations"))}
		var questions := Array(entry.get("questions", []) if entry.get("questions") is Array else []).filter(_is_question)
		p.places[str(place)] = {"tools": tools, "order": order, "questions": questions,
			"people_also": _texts(entry.get("people_also"))}
	for c: Variant in doc.get("tool_cards", []) if doc.get("tool_cards") is Array else []:
		var card := JsonFile.dict_or_empty(c)
		if card.get("tool") is String:
			p.tool_cards[card["tool"]] = {"title": str(card.get("title", "")), "text": str(card.get("text", ""))}
	return p


static func _is_question(q: Variant) -> bool:
	if not q is Dictionary or not Investigation.QUESTIONS.has(q.get("id")) or q["id"] == THANKS:
		return false
	return q.get("person") is String and q.get("text") is String and q.get("reply") is String


static func _texts(v: Variant) -> Array:
	return Array(v).filter(func(x: Variant) -> bool: return x is String) if v is Array else []


func has_place(place: String) -> bool:
	return places.has(place)


## Whether `tool` fits the work at `place` (every tool where no entry says).
func fits(place: String, tool: String) -> bool:
	return not places.has(place) or places[place]["tools"].has(tool)


## The tool buttons at a place: the fitting tools the player knows, in the
## content's order (a conversation is a question, never a button).
func tools_at(place: String) -> Array[String]:
	var order: Array[String] = []
	if places.has(place):
		order = places[place]["order"]
	else:
		order.assign(Investigation.TOOLS.keys().filter(func(t: String) -> bool: return t != "conversation"))
	return order.filter(func(t: String) -> bool: return known.has(t))


## The place's own label for a tool; "" for none.
func label(place: String, tool: String) -> String:
	return places[place]["tools"][tool]["label"] if places.has(place) and places[place]["tools"].has(tool) else ""


## The questions to the people at a place: [{id, person, text, reply}].
func questions_at(place: String) -> Array:
	return places[place]["questions"] if places.has(place) else []


## The question `id` at a place ({} when it is not one of its questions).
func question(place: String, id: String) -> Dictionary:
	for q: Dictionary in questions_at(place):
		if q["id"] == id:
			return q
	return {}


## Who can be met here besides those who work here.
func people_also(place: String) -> Array:
	return places[place]["people_also"] if places.has(place) else []


## The next observation of `tool` at `place`, cycling so none repeats until
## all were shown, logged for the journal on `day`; "" where there is none.
func observe(place: String, tool: String, day: int = 0) -> String:
	var lines: Array = places[place]["tools"][tool]["observations"] \
		if places.has(place) and places[place]["tools"].has(tool) else []
	if lines.is_empty():
		return ""
	var key := place + "|" + tool
	var n: int = shown.get(key, 0)
	shown[key] = n + 1
	var text: String = lines[n % lines.size()]
	journal.append({"day": day, "place": place, "tool": tool, "text": text})
	return text


func grant(tools: PackedStringArray) -> void:
	for t in tools:
		known[t] = true


## A returning player, a skipped week, or an old save: every tool.
func know_all() -> void:
	grant(PackedStringArray(Investigation.TOOLS.keys()))


func to_dict() -> Dictionary:
	return {"tools_known": known.keys(), "observation_seen": shown.duplicate(), "journal": journal.duplicate(true),
		"repair_due": repair_due.duplicate()}


## A save without a valid toolbox is an old one: every tool is known.
func load_dict(d: Dictionary) -> void:
	known.clear()
	shown.clear()
	journal.clear()
	repair_due.clear()
	if d.get("tools_known") is Array:
		grant(PackedStringArray(_texts(d["tools_known"])))
	else:
		know_all()
	var counts := JsonFile.dict_or_empty(d.get("observation_seen"))
	for key: Variant in counts:
		if key is String and (counts[key] is int or counts[key] is float):
			shown[key] = maxi(0, int(counts[key]))
	for e: Variant in d.get("journal", []) if d.get("journal") is Array else []:
		if e is Dictionary and e.get("place") is String and e.get("tool") is String and e.get("text") is String:
			journal.append({"day": int(e.get("day", 0)) if e.get("day") is float or e.get("day") is int else 0,
				"place": e["place"], "tool": e["tool"], "text": e["text"]})
	var due := JsonFile.dict_or_empty(d.get("repair_due"))
	for place: Variant in due:
		if place is String and due[place] is String:
			repair_due[place] = due[place]
