class_name Catalog
extends RefCounted
## The problem and countermeasure catalogue from game/data (built from
## content/problems_tier*.yaml and countermeasures.yaml), as definitions.

const DATA_DIR := "res://data"

var problems: Array[ProblemDef] = []
var countermeasures: Array[CountermeasureDef] = []
## The first thing wrong with the files; "" when the catalogue is usable.
var error := ""


static func load_from(dir: String = DATA_DIR) -> Catalog:
	var c := Catalog.new()
	var cms := JsonFile.read_dict(dir + "/countermeasures.json")
	if not cms["error"].is_empty():
		c.error = cms["error"]
		return c
	for d: Variant in cms["data"].get("countermeasures", []):
		c._add_countermeasure(CountermeasureDef.from_dict(d if d is Dictionary else {}))
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool:
		return f.begins_with("problems_tier") and f.ends_with(".json"))
	files.sort()
	for file: String in files:
		var doc := JsonFile.read_dict(dir + "/" + file)
		if not doc["error"].is_empty():
			c.error = doc["error"]
			return c
		for d: Variant in doc["data"].get("problems", []):
			c._add_problem(ProblemDef.from_dict(d if d is Dictionary else {}))
	return c


func _add_problem(p: ProblemDef) -> void:
	if not p.error.is_empty() and error.is_empty():
		error = p.error
	problems.append(p)


func _add_countermeasure(cm: CountermeasureDef) -> void:
	if not cm.error.is_empty() and error.is_empty():
		error = cm.error
	countermeasures.append(cm)
