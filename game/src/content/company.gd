class_name Company
extends RefCounted
## The company file (res://data/company.json, built from content/company.yaml; phase-2
## design §1.6): who works where, under whom, with what title. One source for titles
## (the name tags), for where someone sits and who leads them (Wie is wie) and for the
## codex's company page. Loaded once; a missing or broken file leaves the caller's own
## text (the build checks the file, so that is a broken build, not play).

const PATH := "res://data/company.json"
## Under a person's name in Wie is wie: who leads them.
const LEADER := "leidinggevende: %s"

static var _doc: Dictionary = {}
static var _titles: Dictionary = {}
static var _loaded := false


## The whole company file ({} when it cannot be read).
static func doc() -> Dictionary:
	if not _loaded:
		var file := JsonFile.read_dict(PATH)
		if not str(file.get("error", "")).is_empty():
			push_warning("company: " + str(file["error"]))
		else:
			_doc = JsonFile.dict_or_empty(file.get("data"))
		_titles = titles_from(file)
		_loaded = true
	return _doc


## Person `id`'s title ("teamleider Werkvoorbereiding"), or `fallback` when the company
## file does not know them.
static func title(id: String, fallback: String = "") -> String:
	doc()
	return str(_titles.get(id, fallback))


## Person `id`'s entry in the built index: {title, department, team, manager} for
## Voltana's people, {title, organisation} for an external; {} when unknown.
static func person(id: String) -> Dictionary:
	return JsonFile.dict_or_empty(JsonFile.dict_or_empty(doc().get("people")).get(id))


## Where person `id` sits and who leads them, for under their name in Wie is wie:
## "Werkvoorbereiding · Aansluitingen & Netverzwaring · leidinggevende: Joost van Dijk";
## the team is left out when they head the department, when it has the department's
## name or when their title already says it ("teamleider Werkvoorbereiding"); "" for
## an external or someone unknown.
static func place_line(id: String) -> String:
	return place_line_of(person(id))


static func place_line_of(entry: Dictionary) -> String:
	var department := str(entry.get("department", ""))
	if department.is_empty():
		return ""
	var parts: Array[String] = []
	var team := str(entry.get("team", ""))
	if not team.is_empty() and team != department and not str(entry.get("title", "")).containsn(team):
		parts.append(team)
	parts.append(department)
	var manager := str(entry.get("manager", ""))
	if not manager.is_empty():
		parts.append(TranslationServer.translate(LEADER) % manager)
	return " · ".join(parts)


## id → title from a read_dict result ({data, error}); {} on an error.
static func titles_from(file: Dictionary) -> Dictionary:
	var out := {}
	if not str(file.get("error", "")).is_empty():
		return out
	var doc := JsonFile.dict_or_empty(file.get("data"))
	var refs: Array = []
	for d: Variant in doc.get("departments", []) if doc.get("departments") is Array else []:
		var dept := JsonFile.dict_or_empty(d)
		refs.append(dept.get("head"))
		for t: Variant in dept.get("teams", []) if dept.get("teams") is Array else []:
			var team := JsonFile.dict_or_empty(t)
			refs.append(team.get("lead"))
			refs.append_array(team.get("members", []) if team.get("members") is Array else [])
	refs.append_array(doc.get("externals", []) if doc.get("externals") is Array else [])
	for r: Variant in refs:
		var ref := JsonFile.dict_or_empty(r)
		if ref.get("id") is String and ref.get("title") is String:
			out[ref["id"]] = ref["title"]
	return out


## A person ref's name (company.yaml: {id, title} for someone in the cast, {name, title}
## for someone named here); "" for anything else (a team its head leads: "head").
static func name_of(ref: Variant) -> String:
	if not ref is Dictionary:
		return ""
	if ref.get("name") is String:
		return ref["name"]
	var id := str(ref.get("id", ""))
	for entry: Dictionary in CharacterModel.cast():  # the cast has everyone, Ruud too
		if entry.get("id") == id:
			return str(entry.get("name", ""))
	return ""


## Whether a company entry may show: always without `revealed_by`, else once `known`
## (a clue id or a fact → bool) holds for any of its atoms; a malformed gate hides it.
static func revealed(entry: Dictionary, known: Callable) -> bool:
	if not entry.has("revealed_by"):
		return true
	var atoms: Variant = entry["revealed_by"]
	return atoms is Array and atoms.any(func(a: Variant) -> bool: return a is String and known.call(a))


## A Dutch whole number with a dot per thousand: 15498 → "15.498".
static func number_text(value: float) -> String:
	var digits := str(int(round(absf(value))))
	var out := ""
	while digits.length() > 3:
		out = "." + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
