class_name OfficeBuilding
extends RefCounted
## The head office's floors and rooms (PLAN 2.1), read from world.json (content/world.yaml):
## which glb each floor is, and which rooms are open. The progressive rule decides: a room
## opens once a mission that needs it has been taken on (or from the start), a floor once
## one of its rooms is. Also reads the markers a floor's model carries (by their glTF
## extras). Without a readable world.json the building is the 1e alone, all of it open.

const FILE := "world.json"
const MODEL_DIR := "res://assets/office/"
## Opens a room from the first day.
const START := "start"
## A mission taken on: active, or done.
const TAKEN: Array[String] = ["active", "completed"]
## The building when world.json cannot be read: the connections office alone.
const FALLBACK := {
	"start_floor": "first",
	"floors": [{"id": "first", "level": 1, "name": "1e verdieping", "model": "office.glb"}],
	"rooms": [{"id": "connections", "floor": "first", "name": "Aansluitingen", "places": [], "opens_with": [START]}],
}

## Sorted by level, lowest first: {id, level, name, model, outside_of}. An outside area (the
## yard, PLAN 2.2) has outside_of: the floor whose door leads there, and that floor's level;
## the stairs never lead to it ("" for a floor).
var floors: Array[Dictionary] = []
## {id, floor, name, places, opens_with}.
var rooms: Array[Dictionary] = []
var start_floor := ""
## What each tell looks like (PLAN 2.15, world.yaml `tells:`): id → {place, low, mid, high}.
## An entry without all of them is left out (the tell then has no words).
var tells: Dictionary = {}
## Why world.json was not used ("" when it was).
var error := ""


## The building in `data_dir`. world.json is optional (as in the content pipeline): without
## it the building is the FALLBACK, quietly; a file that is there but unusable says why.
static func load_from(data_dir: String) -> OfficeBuilding:
	var b := OfficeBuilding.new()
	var path := data_dir.path_join(FILE)
	if not FileAccess.file_exists(path):
		b._fill(FALLBACK)
		b.error = "no " + path
		return b
	var read := JsonFile.read_dict(path)
	var problem: String = read["error"] if not read["error"].is_empty() else _shape_error(read["data"])
	b._fill(FALLBACK if not problem.is_empty() else read["data"])
	if problem.is_empty():
		b.tells = _tells(read["data"].get("tells"))
	b.error = problem
	if not problem.is_empty():
		push_warning("office: building: " + problem)
	return b


## Why `d` is not a usable building ("" when it is). The content pipeline validates
## world.yaml; this guards the file the game actually reads, model names included,
## since they become paths.
static func _shape_error(d: Dictionary) -> String:
	var shape := JsonFile.shape_error(d, {"start_floor": TYPE_STRING, "floors": TYPE_ARRAY, "rooms": TYPE_ARRAY})
	if not shape.is_empty():
		return shape
	var ids: Array[String] = []
	var model := RegEx.create_from_string("^[a-z][a-z0-9_]*\\.glb$")
	for f: Variant in d["floors"]:
		if not f is Dictionary or not f.get("id") is String or not f.get("name") is String \
				or not (f.get("level") is float or f.get("level") is int or f.get("outside_of") is String) \
				or not f.get("model") is String or model.search(f["model"]) == null:
			return "a floor needs an id, a name, a level (or outside_of) and a model (a .glb file name)"
		ids.append(f["id"])
	for f: Dictionary in d["floors"]:
		if f.get("outside_of") is String and not f["outside_of"] in ids:
			return "an outside area is outside of an unknown floor"
	if not d["start_floor"] in ids:
		return "start_floor is not a floor"
	for r: Variant in d["rooms"]:
		if not r is Dictionary or not r.get("id") is String or not r.get("name") is String \
				or not r.get("floor") in ids or not r.get("opens_with") is Array or not r.get("places") is Array:
			return "a room needs an id, a name, a known floor, places and opens_with"
	return ""


## The well-formed entries of world.json's `tells` (none when it is missing or not a list).
static func _tells(v: Variant) -> Dictionary:
	var out := {}
	for t: Variant in v if v is Array else []:
		if not t is Dictionary or not t.get("id") is String:
			continue
		var look := {}
		for key in ["place", "low", "mid", "high"]:
			if t.get(key) is String and not t[key].is_empty():
				look[key] = t[key]
		if look.size() == 4:
			out[t["id"]] = look
	return out


func _fill(d: Dictionary) -> void:
	start_floor = d["start_floor"]
	var levels := {}
	for f: Dictionary in d["floors"]:
		if f.has("level"):
			levels[f["id"]] = int(f["level"])
	for f: Dictionary in d["floors"]:
		var outside := str(f.get("outside_of", "")) if not f.has("level") else ""
		floors.append({"id": f["id"], "level": levels.get(outside, 0) if not outside.is_empty() else int(f["level"]),
			"name": f["name"], "model": f["model"], "outside_of": outside})
	floors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["level"] < b["level"] or (a["level"] == b["level"] and a["outside_of"] < b["outside_of"]))
	for r: Dictionary in d["rooms"]:
		rooms.append(r)


func floor_of(id: String) -> Dictionary:
	for f in floors:
		if f["id"] == id:
			return f
	return {}


func model_path(floor_id: String) -> String:
	var f := floor_of(floor_id)
	return MODEL_DIR + str(f["model"]) if not f.is_empty() else ""


## The floor `step` levels above (+1) or below (-1) `floor_id` by the stairs (never an
## outside area); "" for none.
func next_floor(floor_id: String, step: int) -> String:
	var f := floor_of(floor_id)
	for other in floors:
		if not f.is_empty() and other["level"] == f["level"] + step and other["outside_of"].is_empty():
			return other["id"]
	return ""


func room(id: String) -> Dictionary:
	for r in rooms:
		if r["id"] == id:
			return r
	return {}


func rooms_on(floor_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in rooms:
		if r["floor"] == floor_id:
			out.append(r)
	return out


## The missions the player has taken on (active or done) in `session`: the ids of its
## missions' progress. A session without missions (a stand-in) has taken none.
static func taken(session: Object) -> Dictionary:
	var out := {}
	var m: Variant = session.get("missions") if session != null else null
	if m is Missions:
		for id: String in m.progress:
			if m.progress[id].get("status", "") in TAKEN:
				out[id] = true
	return out


## Whether one of `opens_with` is met by the missions taken: "start", a mission id,
## or a prefix of missions made in play ("terugval_*").
static func opens(opens_with: Array, taken_ids: Dictionary) -> bool:
	for opener: Variant in opens_with:
		var o := str(opener)
		if o == START or taken_ids.has(o):
			return true
		if o.ends_with("*") and taken_ids.keys().any(func(id: String) -> bool: return id.begins_with(o.trim_suffix("*"))):
			return true
	return false


## The ids of the rooms open in `session`.
func open_rooms(session: Object) -> Array[String]:
	var t := taken(session)
	var out: Array[String] = []
	for r in rooms:
		if opens(r["opens_with"], t):
			out.append(r["id"])
	return out


## A floor is open when one of its rooms is.
func floor_open(floor_id: String, open: Array[String]) -> bool:
	return rooms_on(floor_id).any(func(r: Dictionary) -> bool: return r["id"] in open)


## The markers in a floor's geometry by id: "place:<step>", "door:<room>",
## "room:<room>", "arrive:<how>", or the role ("obeya", "lift", "spawn", ...), from
## each node's glTF extras {interaction, id}.
static func markers(geometry: Node) -> Dictionary:
	var out := {}
	for n in [geometry] + geometry.find_children("*", "Node3D", true, false):
		var extras: Variant = n.get_meta("extras", {})
		if not extras is Dictionary or not extras.get("interaction") is String:
			continue
		var kind: String = extras["interaction"]
		var id := str(extras.get("id", ""))
		out[kind + ":" + id if kind in ["place", "door", "room", "arrive", "exit"] else kind] = n
	return out
