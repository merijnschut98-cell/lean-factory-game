class_name ExplainerFigure
extends RefCounted
## An explainer's drawing as exported by tools/explainers/<name>/export.mjs:
## the layers back to front (each an SVG cropped to `rect` in the figure's
## viewBox), and the overlays Godot draws itself (LCD windows, needles, the
## paddle wheel, the pulse LED, the marker tags, the hit rects of controls).
## Planes are given as a screen origin plus the screen vectors of one world
## unit along x (u) and y (v), so overlays lie on the drawing's own faces.

const MANIFEST := "manifest.json"
## The import scale of the layer SVGs (export.mjs seeds it in each .import).
const SVG_SCALE := 2.0

var dir := ""
var error := ""
var viewbox := Vector2.ZERO
## [{id, file, z, skin, group, rect: [x, y, w, h], pair?, heat?, when?}]
var layers: Array = []
var lcds: Array = []
var needles: Array = []
var wheels: Array = []
var leds: Array = []
var tags: Array = []
var hits: Array = []
var _by_id := {}


static func load_from(folder: String) -> ExplainerFigure:
	var f := ExplainerFigure.new()
	f.dir = folder
	var read := JsonFile.read_dict(folder.path_join(MANIFEST))
	if not read["error"].is_empty():
		f.error = read["error"]
		return f
	var d: Dictionary = read["data"]
	var shape := JsonFile.shape_error(d, {"viewbox": TYPE_ARRAY, "layers": TYPE_ARRAY})
	if not shape.is_empty():
		f.error = "%s: %s" % [MANIFEST, shape]
		return f
	f.viewbox = Vector2(d["viewbox"][0], d["viewbox"][1])
	for layer: Variant in d["layers"]:
		if not (layer is Dictionary and layer.get("id") is String and layer.get("rect") is Array and layer["rect"].size() == 4):
			f.error = "%s: a layer without an id or a rect" % MANIFEST
			f.layers = []
			return f
		f.layers.append(layer)
		f._by_id[layer["id"]] = layer
	for key in ["lcds", "needles", "wheels", "leds", "tags", "hits"]:
		var list: Variant = d.get(key, [])
		f.set(key, list if list is Array else [])
	return f


func has_layer(id: String) -> bool:
	return _by_id.has(id)


func layer(id: String) -> Dictionary:
	return _by_id.get(id, {})


## The imported texture of a layer, or null.
func texture(id: String) -> Texture2D:
	if not _by_id.has(id):
		return null
	var path := dir.path_join(_by_id[id]["file"])
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## A plane entry's transform: world units on that face → figure (viewBox) px.
static func plane(entry: Dictionary) -> Transform2D:
	var o: Array = entry["origin"]
	var u: Array = entry["u"]
	var v: Array = entry["v"]
	return Transform2D(Vector2(u[0], u[1]), Vector2(v[0], v[1]), Vector2(o[0], o[1]))
