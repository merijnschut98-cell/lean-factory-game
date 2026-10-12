class_name Catalog
extends RefCounted
## The problem and countermeasure catalogue from game/data (built from
## content/problems_tier*.yaml and countermeasures.yaml), as definitions.

const DATA_DIR := "res://data"
## One file per tier (the same rule as tools/build_content.py).
const PROBLEM_FILES := "problems_tier"

var problems: Array[ProblemDef] = []
var countermeasures: Array[CountermeasureDef] = []
var missions: Array[MissionDef] = []
## The senior manager who coaches the main mission: {name, role, stages}.
var coach: Dictionary = {}
## The first thing wrong with the files; "" when the catalogue is usable.
var error := ""


static func load_from(dir: String = DATA_DIR) -> Catalog:
	var c := Catalog.new()
	if c._load(dir + "/countermeasures.json", "countermeasures", CountermeasureDef.from_dict, c.countermeasures).is_empty():
		return c
	var campaign := c._load(dir + "/missions.json", "missions", MissionDef.from_dict, c.missions)
	if campaign.is_empty():
		return c
	c.coach = JsonFile.dict_or_empty(campaign.get("coach"))
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool:
		return f.begins_with(PROBLEM_FILES) and f.ends_with(".json"))
	files.sort()
	for file: String in files:
		if c._load(dir + "/" + file, "problems", ProblemDef.from_dict, c.problems).is_empty():
			return c
	return c


## Read definitions under `key` of a JSON file into `into` (each made by
## `from_dict`, keeping the first error). Returns the document; empty (and
## `error` set) when the file cannot be read.
func _load(path: String, key: String, from_dict: Callable, into: Array) -> Dictionary:
	var doc := JsonFile.read_dict(path)
	if not doc["error"].is_empty():
		error = doc["error"]
		return {}
	for d: Variant in doc["data"].get(key, []):
		var def: Variant = from_dict.call(JsonFile.dict_or_empty(d))
		_keep_first(def.error)
		into.append(def)
	return doc["data"]


func _keep_first(definition_error: String) -> void:
	if error.is_empty():
		error = definition_error
