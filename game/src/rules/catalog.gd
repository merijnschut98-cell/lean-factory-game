class_name Catalog
extends RefCounted
## The problem and countermeasure catalogue from game/data (built from
## content/problems_tier*.yaml and countermeasures.yaml), as definitions.

const DATA_DIR := "res://data"
## One file per tier (the same rule as tools/build_content.py).
const PROBLEM_FILES := "problems_tier"

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
		var cm := CountermeasureDef.from_dict(_dict(d))
		c._keep_first(cm.error)
		c.countermeasures.append(cm)
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool:
		return f.begins_with(PROBLEM_FILES) and f.ends_with(".json"))
	files.sort()
	for file: String in files:
		var doc := JsonFile.read_dict(dir + "/" + file)
		if not doc["error"].is_empty():
			c.error = doc["error"]
			return c
		for d: Variant in doc["data"].get("problems", []):
			var p := ProblemDef.from_dict(_dict(d))
			c._keep_first(p.error)
			c.problems.append(p)
	return c


func _keep_first(definition_error: String) -> void:
	if error.is_empty():
		error = definition_error


static func _dict(d: Variant) -> Dictionary:
	return d if d is Dictionary else {}
