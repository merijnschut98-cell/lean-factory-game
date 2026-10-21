class_name Company
extends RefCounted
## The company file (res://data/company.json, built from content/company.yaml; phase-2
## design §1.6): who works where, under whom, with what title. One source for titles:
## the name tags read them here. Loaded once; a missing or broken file leaves the
## caller's own text (the build checks the file, so that is a broken build, not play).

const PATH := "res://data/company.json"

static var _titles: Dictionary = {}
static var _loaded := false


## Person `id`'s title ("teamleider Werkvoorbereiding"), or `fallback` when the company
## file does not know them.
static func title(id: String, fallback: String = "") -> String:
	if not _loaded:
		_titles = titles_from(JsonFile.read_dict(PATH))
		_loaded = true
	return str(_titles.get(id, fallback))


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
