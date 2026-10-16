class_name OfficeFloors
extends Node
## The head office's floors in play (PLAN 2.1): one floor's model is loaded at a time;
## the stairs and the lift are the seams. Walk onto the stairs' ring (or E there) and
## you go a floor up or down; E at the lift opens the building's directory, the map,
## to choose a floor. You arrive at the right spot (the floor's `arrive:<how>` marker),
## the same player with the same game. Rooms open as missions need them
## (OfficeBuilding): a shut room's door stays shut and blocks the way, its places are
## not offered; a shut floor is not reached. A child of the Office, which it drives.

signal floor_changed(floor_id: String)

## The seams and the doors: the interactables this node answers for.
const STAIRS: Array[String] = ["stairs_up", "stairs_down"]
const OWN: Array[String] = ["stairs_up", "stairs_down", "lift", "door"]
## The markers that become interactables (the rest: spawn, arrivals, rooms).
const USABLE: Array[String] = ["place", "obeya", "coach", "mission_board", "stairs_up", "stairs_down", "lift", "door"]
## Seconds between checks of which rooms are open.
const POLL_SECONDS := 0.5
## Walking onto the stairs counts when the player moves this fast (m/s) up their run.
const WALK_IN_SPEED := 0.3
## The key of a cast spot's floor (the start floor when a spot names none).
const FLOOR_KEY := "floor"

const CLOSED_DOOR := "%s is dicht: je toegangspas opent deze deur nog niet."
const CLOSED_FLOOR := "De %s is nog dicht: je toegangspas opent die verdieping nog niet."

var office: Office
var building: OfficeBuilding
## The floor the player is on.
var floor_id := ""
## The open rooms when the doors were last set (to notice a change).
var open: Array[String] = []
## The stairs' ring the player stands in (the walk-in fires once, on stepping in).
var _on_stairs: Interactable
var _since_poll := 0.0
## Map plans of the floors not loaded, by floor id (read once from their models).
var _plans: Dictionary = {}


func setup(of_office: Office) -> void:
	office = of_office
	name = "Floors"
	building = OfficeBuilding.load_from(office.data_dir)
	floor_id = building.start_floor


func model_path() -> String:
	return building.model_path(floor_id)


func floor_name(id: String = floor_id) -> String:
	return str(building.floor_of(id).get("name", ""))


## Whether a cast spot (an entry's office spot, or its lunch spot) is on this floor: it
## names its `floor`; without one it is on the start floor.
func here(spot: Dictionary) -> bool:
	return str(spot.get(FLOOR_KEY, building.start_floor)) == floor_id


## The loaded floor's markers by id (OfficeBuilding.markers).
func markers() -> Dictionary:
	return OfficeBuilding.markers(office.geometry)


## The rooms open now (a game whose content failed has taken no mission: the rooms open
## from the start).
func open_now() -> Array[String]:
	return building.open_rooms(office.session if office.session.error.is_empty() else null)


## The markers to make interactables on this floor, by id: the usable ones, without the
## places inside a shut room and without the doors of open rooms.
func usable_markers(geometry: Node3D) -> Dictionary:
	var all := OfficeBuilding.markers(geometry)
	var shut := shut_rects(all)
	var out := {}
	for id: String in all:
		var kind := id.get_slice(":", 0)
		if not kind in USABLE:
			continue
		if kind == "door" and id.get_slice(":", 1) in open:
			continue
		var at := office.in_office(all[id]).origin
		if kind != "door" and shut.any(func(r: Rect2) -> bool: return r.has_point(Vector2(at.x, at.z))):
			continue
		out[id] = all[id]
	return out


## The floor areas (x, z) of this floor's shut rooms (a room the building data does not
## know stays shut).
func shut_rects(all: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for id: String in all:
		if id.begins_with("room:") and not id.trim_prefix("room:") in open:
			out.append(room_rect(all[id]))
	return out


static func room_rect(marker: Node) -> Rect2:
	var rect: Variant = marker.get_meta("extras", {}).get("rect", [])
	if rect is Array and rect.size() == 4:
		return Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	return Rect2()


## Doors as the rooms are now: an open room's shut leaf and its blocker go (the walk
## grid is baked again), its open leaf shows; a shut room's open leaf hides.
func apply_rooms() -> void:
	open = open_now()
	for id: String in OfficeBuilding.markers(office.geometry):
		if not id.begins_with("room:"):
			continue
		var room := id.trim_prefix("room:")
		var is_open := room in open
		if is_open:
			for n in _named(office.geometry, ["lockleaf_" + room, "lockcol_" + room]):
				n.get_parent().remove_child(n)
				n.free()
		for n in _named(office.geometry, ["openleaf_" + room]):
			(n as Node3D).visible = is_open


## Nodes under `root` whose names start with one of `prefixes` (compared loosely: the
## importer rewrites names), outermost only.
static func _named(root: Node, prefixes: Array) -> Array[Node]:
	var out: Array[Node] = []
	var loose := prefixes.map(func(p: String) -> String: return Office._loose(p))
	for n in root.find_children("*", "Node3D", true, false):
		var own := Office._loose(n.name)
		if loose.any(func(p: String) -> bool: return own.begins_with(p)) and not out.any(func(o: Node) -> bool: return o.is_ancestor_of(n)):
			out.append(n)
	return out


func _process(delta: float) -> void:
	if office == null or office.session == null or not office.session.error.is_empty() or office.player == null:
		return
	_since_poll += delta
	if _since_poll >= POLL_SECONDS:
		_since_poll = 0.0
		if open_now() != open:
			office.reload_rooms()
	_walk_in()


## Stepping onto the stairs' ring while walking up their run takes them.
func _walk_in() -> void:
	var ring := office.interactable_near(office.player.position, Interactable.RING_RADIUS)
	var stairs := ring if ring != null and ring.kind in STAIRS else null
	if stairs == _on_stairs:
		return
	_on_stairs = stairs
	if stairs != null and not office.ui.is_busy() and walking_into(stairs):
		use(stairs)


## Whether the player is moving up the stairs' run (their marker's forward).
func walking_into(stairs: Interactable) -> bool:
	var ahead := -stairs.basis.z
	var v := office.player.velocity
	return Vector2(v.x, v.z).dot(Vector2(ahead.x, ahead.z).normalized()) >= WALK_IN_SPEED


## Use a seam or a door; false when `target` is not one (the office handles it).
func use(target: Interactable) -> bool:
	if target == null or not target.kind in OWN:
		return false
	match target.kind:
		"stairs_up", "stairs_down":
			var to := building.next_floor(floor_id, 1 if target.kind == "stairs_up" else -1)
			go_to(to, target.kind)
		"lift":
			office.ui.office_map.lift = true
			office.ui.toggle_map()
		"door":
			office.ui.hud.toast(CLOSED_DOOR % room_name(target))
	return true


func room_name(door: Interactable) -> String:
	return str(building.room(door.id.get_slice(":", 1)).get("name", ""))


## The prompt for a seam or a door; "" for anything else.
func prompt(target: Interactable) -> String:
	if target == null or not target.kind in OWN:
		return ""
	match target.kind:
		"stairs_up", "stairs_down":
			var to := building.next_floor(floor_id, 1 if target.kind == "stairs_up" else -1)
			var shut := "" if building.floor_open(to, open) else " (dicht)"
			return "E — Trap naar de %s%s" % [floor_name(to).to_lower(), shut] if not to.is_empty() else ""
		"lift":
			return "E — Lift"
	return "E — %s: dicht" % room_name(target)


## A seam's or door's name on the map; "" for anything else.
func label(target: Interactable) -> String:
	if target == null or not target.kind in OWN:
		return ""
	match target.kind:
		"stairs_up":
			return "Trap omhoog"
		"stairs_down":
			return "Trap omlaag"
		"lift":
			return "Lift"
	return room_name(target) + " (dicht)"


## Go to floor `id`, arriving `how` (lift, stairs_up, stairs_down: the floor's
## `arrive:<how>` marker). A shut floor says so and keeps you here, unless `force`
## (tools). True when the floor changed.
func go_to(id: String, how: String, force := false) -> bool:
	if building.floor_of(id).is_empty() or id == floor_id:
		return false
	if not force and not building.floor_open(id, open_now()):
		office.ui.hud.toast(CLOSED_FLOOR % floor_name(id).to_lower())
		return false
	floor_id = id
	office.load_floor()
	var found := OfficeBuilding.markers(office.geometry)
	var at: Node3D = found.get("arrive:" + how, found.get("spawn"))
	office.player.stop()
	office.player.velocity = Vector3.ZERO
	if at != null:
		var t := office.in_office(at)
		office.player.position = t.origin
		office.player.face(t.basis)
	office.rig.bounds = office.floor_rect()
	office.rig.snap()
	_on_stairs = office.interactable_near(office.player.position, Interactable.RING_RADIUS)
	floor_changed.emit(id)
	return true


# ── The map ─────────────────────────────────────────────────────────────────

## The map's floors: [{id, name, open, here}], lowest first.
func map_floors() -> Array[Dictionary]:
	var now := open_now()
	var out: Array[Dictionary] = []
	for f in building.floors:
		out.append({"id": f["id"], "name": f["name"], "open": f["id"] == floor_id or building.floor_open(f["id"], now),
			"here": f["id"] == floor_id})
	return out


## What the map draws of floor `id`: {rect, places, footprints, rooms}. This floor's
## from the loaded model; another's from its model, read once.
func map_plan(id: String) -> Dictionary:
	if id == floor_id:
		return {"rect": office.floor_rect(), "places": office.map_places(), "footprints": office.map_footprints(),
			"rooms": _map_rooms(OfficeBuilding.markers(office.geometry), open)}
	if not _plans.has(id):
		_plans[id] = _read_plan(id)
	var plan: Dictionary = _plans[id].duplicate()
	plan["rooms"] = plan["rooms"].map(func(r: Dictionary) -> Dictionary:
		var copy := r.duplicate()
		copy["open"] = r["id"] in open_now()
		return copy)
	return plan


## {id, name, rect, open} for the rooms of the floor whose markers are `all`.
func _map_rooms(all: Dictionary, open_ids: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in all:
		if id.begins_with("room:"):
			var room_id := id.trim_prefix("room:")
			out.append({"id": room_id, "name": str(building.room(room_id).get("name", room_id)),
				"rect": room_rect(all[id]), "open": room_id in open_ids})
	return out


## Another floor's plan from its model: the floor, its places (the seams and the teams;
## not reachable from here, so no doors), its furniture and its rooms.
func _read_plan(id: String) -> Dictionary:
	var path := building.model_path(id)
	var plan := {"rect": Rect2(), "places": [] as Array[Dictionary], "footprints": [] as Array[Dictionary], "rooms": []}
	if not ResourceLoader.exists(path):
		return plan
	var geometry: Node3D = (load(path) as PackedScene).instantiate()
	var all := OfficeBuilding.markers(geometry)
	var floor_node := Office._find_marker(geometry, Office.FLOOR, Office._loose(Office.FLOOR))
	if floor_node is MeshInstance3D:
		var b: AABB = office.in_office(floor_node) * (floor_node as MeshInstance3D).get_aabb()
		plan["rect"] = Rect2(b.position.x, b.position.z, b.size.x, b.size.z)
	for marker_id: String in all:
		var kind := marker_id.get_slice(":", 0)
		if kind in USABLE and kind != "door":
			var i := Interactable.create(marker_id, office.in_office(all[marker_id]))
			var text := label(i) if kind in OWN else office.label_for(i)
			plan["places"].append({"id": marker_id, "label": text, "at": Vector2(i.position.x, i.position.z)})
			i.free()
	plan["footprints"] = Office.footprints_of(geometry, plan["rect"], office)
	plan["rooms"] = _map_rooms(all, [])
	geometry.free()
	return plan


## Hand this floor to the player map.
func refresh_map() -> void:
	var map := office.ui.office_map
	if map == null:
		return
	map.show_floors(map_floors(), floor_id, map_plan)
	if not map.floor_chosen.is_connected(_on_floor_chosen):
		map.floor_chosen.connect(_on_floor_chosen)


func _on_floor_chosen(id: String) -> void:
	office.ui.close_panels()
	go_to(id, "lift")
