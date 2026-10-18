class_name OfficeMinimap
extends Node
## Feeds the minimap (PLAN 2.1b) from the office: the loaded floor's plan, the player and
## the camera, the people present, and the accepted missions' targets (MinimapTargets) with
## their walking routes: a route's first heading and length for the rim arrow, and on
## another floor the nearer of the stairs and the lift by route, with the floor to go to.
## Shown once Ruud has handed over the plan (SessionLayer.has_floor_plan) and while the
## setting says so; hidden while the world waits (a talk, an explainer, a panel).

## The targets and routes are worked out at most this often (s); the map is redrawn when
## the player moves or turns more than these.
const ROUTE_SECONDS := 0.25
const MOVE_M := 0.1
const TURN_RAD := deg_to_rad(2.0)
## The route's first heading: its first corner at least this far (m) from the player.
const HEADING_M := 2.0

var office: Office
var map: Minimap
## Where the settings are read (tests point it at their own file).
var settings_path := SessionLog.SETTINGS
var _since := INF
var _plan_key := ""
var _drawn := {}


func setup(of_office: Office) -> void:
	office = of_office
	name = "MinimapFeed"
	map = Minimap.new()
	office.ui.add_child(map)
	refresh()


## Whether the minimap is in view: the plan handed over, the setting on, nothing open.
func wanted() -> bool:
	return office.ui.session_layer.has_floor_plan and Minimap.setting(Minimap.SHOWN, settings_path) \
		and office.session.error.is_empty() and not office.busy()


func _process(delta: float) -> void:
	if office == null or office.player == null:
		return
	map.visible = wanted()
	if not map.visible:
		return
	_since += delta
	if _since >= ROUTE_SECONDS:
		refresh()
	elif _moved():
		_follow()
	map.step(delta)


## Everything again: the plan when the floor or its doors changed, the targets and routes.
func refresh() -> void:
	_since = 0.0
	map.turns = Minimap.setting(Minimap.TURNS, settings_path)
	var key := office.floors.floor_id + ":" + ",".join(office.floors.open)
	if key != _plan_key:
		_plan_key = key
		map.plan = plan()
	map.targets = targets()
	_follow()


## The loaded floor: its outline, its rooms (open or shut) and its seams.
func plan() -> Dictionary:
	var rooms: Array[Dictionary] = []
	var all := office.floors.markers()
	for id: String in all:
		if id.begins_with("room:"):
			var room_id := id.trim_prefix("room:")
			rooms.append({"id": room_id, "name": str(office.floors.building.room(room_id).get("name", room_id)),
				"rect": OfficeFloors.room_rect(all[id]), "open": room_id in office.floors.open})
	var places: Array[Dictionary] = []
	for i in office.interactables:
		if i.kind in OfficeFloors.STAIRS or i.kind == "lift":
			places.append({"id": i.kind, "at": Vector2(i.position.x, i.position.z)})
	return {"rect": office.floor_rect(), "rooms": rooms, "places": places}


## The targets on show (Minimap.targets), with their routes from where the player stands.
func targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not office.session.error.is_empty():
		return out
	var here := office.floors.floor_id
	var player := Vector2(office.player.position.x, office.player.position.z)
	for t in MinimapTargets.all(office.session, office.floors.building, CharacterModel.cast()):
		var shown := {"id": "%s:%s" % [t["mission"], t.get("person", t["room"])], "main": t["main"], "kind": t["kind"],
			"room_rect": Rect2(), "distance": 0, "text": "", "reached": false}
		if t["floor"] == here:
			if not _locate(t, shown, player):
				continue
		elif not _seam(t, shown):
			continue
		var route := office.nav().path(office.player.position, Vector3(shown["at"].x, 0, shown["at"].y))
		shown["toward"] = _heading(route, shown["at"])
		if t["main"] and shown["text"].is_empty():
			shown["distance"] = Minimap.rounded(_length(office.player.position, route))
		out.append(shown)
	return out


## A target on this floor: the person's dot (while they are here) or the room's middle;
## reached when the player is in the room or near the person. False when it is not here.
func _locate(t: Dictionary, shown: Dictionary, player: Vector2) -> bool:
	if t["kind"] == "person":
		var p := office.people.person(t["person"])
		if p == null or not p.visible:
			return false
		shown["at"] = Vector2(p.position.x, p.position.z)
		shown["reached"] = player.distance_to(shown["at"]) <= Minimap.NEAR_PERSON
		return true
	for room: Dictionary in map.plan.get("rooms", []):
		if room["id"] == t["room"]:
			shown["at"] = (room["rect"] as Rect2).get_center()
			shown["room_rect"] = room["rect"]
			shown["reached"] = (room["rect"] as Rect2).has_point(player)
			return true
	return false


## A target on another floor: the nearer of the stairs that way and the lift, by route,
## and the floor to go to ("2e verdieping ↑"). False when neither is on this floor.
func _seam(t: Dictionary, shown: Dictionary) -> bool:
	var building := office.floors.building
	var to := building.floor_of(t["floor"])
	var here := building.floor_of(office.floors.floor_id)
	var up: bool = to.get("level", 0) > here.get("level", 0)
	# the yard (an outside area) is reached through its door, on its own level
	var by_door: bool = to["level"] == here["level"] and (to["outside_of"] != "" or here["outside_of"] != "")
	var best: Interactable = null
	var best_length := INF
	for i in office.interactables:
		var way: bool = i.kind == "exit" if by_door or here["outside_of"] != "" \
			else (i.kind == "lift" or i.kind == ("stairs_up" if up else "stairs_down"))
		if way:
			var length := _length(office.player.position, office.nav().path(office.player.position, i.position))
			if length < best_length:
				best = i
				best_length = length
	if best == null:
		return false
	shown["kind"] = "seam"
	shown["at"] = Vector2(best.position.x, best.position.z)
	var arrow := "" if to["level"] == here["level"] else (" ↑" if up else " ↓")
	shown["text"] = tr(office.floors.floor_name(t["floor"])) + arrow
	return true


## Where the route first heads: its first corner HEADING_M or more from the start.
func _heading(route: PackedVector3Array, goal: Vector2) -> Vector2:
	var from := office.player.position
	for p in route:
		if Vector2(p.x - from.x, p.z - from.z).length() >= HEADING_M:
			return Vector2(p.x, p.z)
	return goal


static func _length(from: Vector3, route: PackedVector3Array) -> float:
	var total := 0.0
	var last := from
	for p in route:
		total += Vector2(p.x - last.x, p.z - last.z).length()
		last = p
	return total if not route.is_empty() else INF


func _moved() -> bool:
	var p := office.player
	return _drawn.is_empty() or Vector2(p.position.x, p.position.z).distance_to(_drawn["at"]) > MOVE_M \
		or absf(angle_difference(p.rotation.y, _drawn["facing"])) > TURN_RAD \
		or absf(angle_difference(office.rig.yaw, _drawn["yaw"])) > TURN_RAD


## The player, the camera and the people as they are now; redraw.
func _follow() -> void:
	var p := office.player
	map.at = Vector2(p.position.x, p.position.z)
	map.facing = p.rotation.y
	map.camera_yaw = office.rig.yaw
	map.people_at.clear()
	for person in office.people.people:
		if person.visible:
			map.people_at.append(Vector2(person.position.x, person.position.z))
	_drawn = {"at": map.at, "facing": map.facing, "yaw": map.camera_yaw}
	map.queue_redraw()
