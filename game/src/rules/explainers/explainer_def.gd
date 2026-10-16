class_name ExplainerDef
extends RefCounted
## One "Hoe werkt het?" explainer from content/explainers.yaml (PLAN 2.7c),
## validated by tools/build_content.py: its Dutch texts, its controls, the
## analogy's layer pairs, the reveal and Ruud's beats.

const FILE := "explainers.json"

var id := ""
var name := ""
var number := 0
## The folder under res://assets/ with manifest.json and the layer SVGs.
var assets := ""
var one_idea := ""
## [{analogy, real, pair: [tuin layer, meterkast layer]}]
var mapping: Array = []
## [{id, tuin?, meterkast?, key}]
var controls: Array = []
## {tuin, meterkast, haspel}
var hint := {}
## {current, u_end, t_cable}
var labels := {}
var tags: Array = []
var caption: Array = []
## {label, lines: [{words, formula?, live?}]}
var reveal := {}
## [{id, phase, lines, ...}] in content order.
var beats: Array = []


static func from_dict(d: Dictionary) -> ExplainerDef:
	var e := ExplainerDef.new()
	e.id = d.get("id", "")
	e.name = d.get("name", "")
	e.number = int(d.get("number", 0))
	e.assets = d.get("assets", "")
	e.one_idea = d.get("one_idea", "")
	var analogy := JsonFile.dict_or_empty(d.get("analogy"))
	e.mapping = analogy.get("mapping", [])
	e.controls = d.get("controls", [])
	e.hint = JsonFile.dict_or_empty(d.get("hint"))
	e.labels = JsonFile.dict_or_empty(d.get("labels"))
	e.tags = d.get("tags", [])
	e.caption = d.get("caption", [])
	e.reveal = JsonFile.dict_or_empty(d.get("reveal"))
	e.beats = d.get("beats", [])
	return e


## {error, explainers: {id: ExplainerDef}}.
static func load_all(data_dir: String = Catalog.DATA_DIR) -> Dictionary:
	var read := JsonFile.read_dict(data_dir.path_join(FILE))
	if not read["error"].is_empty():
		return {"error": read["error"], "explainers": {}}
	var out := {}
	var list: Variant = read["data"].get("explainers")
	if not list is Array:
		return {"error": "%s: 'explainers' must be a list" % FILE, "explainers": {}}
	for item: Variant in list:
		if item is Dictionary:
			var e := ExplainerDef.from_dict(item)
			out[e.id] = e
	return {"error": "", "explainers": out}


## The beat with this id ({} if none).
func beat(beat_id: String) -> Dictionary:
	for b: Dictionary in beats:
		if b["id"] == beat_id:
			return b
	return {}


## Every Dutch string the player can read here except the reveal's formulas
## (tests T7 and T9 walk them).
func plain_texts() -> Array[String]:
	var out: Array[String] = [one_idea]
	for row: Dictionary in mapping:
		out.append_array([row["analogy"], row["real"]])
	out.append_array(hint.values())
	out.append_array(labels.values())
	out.append_array(tags)
	out.append_array(caption)
	for b: Dictionary in beats:
		out.append_array(b["lines"])
	return out
