class_name OfficePeople
extends Node3D
## The people on the loaded floor (PLAN 1.3, 2.1c), placed from the cast list (cast.json):
## at a workstation of the floor's model (<seat>_chair, facing <seat>_desk), on a chair
## (facing the way it faces), at a spot, or walking a route. Who is there follows the
## session: someone tied to missions is present only while one of them is active; nobody
## sits behind a shut door (a room's area, `shut`); between 12:00 and 13:00 those who
## lunch in the kantine sit there instead of at their desk. Names and roles come from
## GameSession.person when the session knows the person (cast.json otherwise). The
## walk-around energy bar follows GameSession.energy_of when the session has it.

## Seconds between refreshes of who is present and who needs a talk.
const REFRESH_SECONDS := 0.5
## Lunch in the kantine (minutes since midnight): from 12:00 to 13:00.
const LUNCH := Vector2i(12 * 60, 13 * 60)

var people: Array[OfficePerson] = []
## The floor areas (x, z) of the floor's shut rooms (OfficeFloors.shut_rects).
var shut: Array[Rect2] = []
var _since_refresh := 0.0
var _session: Object
## The session the names were last taken from.
var _named_by: Object


## The cast's people with a spot on this floor (`here` tells whether a spot's floor is
## the loaded one), placed in `office` (its geometry must be loaded). Someone whose desk
## cannot be found is left out, with a warning.
static func build(office: Office, cast: Array[Dictionary], here: Callable) -> OfficePeople:
	var out := OfficePeople.new()
	out.name = "People"
	for entry in cast:
		var at_desk: Dictionary = entry.get("office", {})
		var at_lunch: Variant = at_desk.get("lunch")
		var lunch_here: bool = at_lunch is Dictionary and here.call(at_lunch)
		var desk_here: bool = not at_desk.is_empty() and here.call(at_desk)
		if not (desk_here or lunch_here):
			continue
		var p := OfficePerson.create(entry)
		if desk_here:
			p.desk = _spot(office, at_desk, p.pose)
			if p.desk.is_empty():
				push_warning("office: no place for %s" % p.id)
				p.free()
				continue
		if at_lunch is Dictionary:
			p.lunch = _spot(office, at_lunch, p.pose) if lunch_here else {}
		p.settle(p.desk)
		p.visible = p.visible and not p.desk.is_empty()
		out.people.append(p)
		out.add_child(p)
	return out


func person(id: String) -> OfficePerson:
	for p in people:
		if p.id == id:
			return p
	return null


## The nearest present person within `reach` on the floor of `at`, or null.
func person_near(at: Vector3, reach: float) -> OfficePerson:
	var best: OfficePerson = null
	var best_distance := reach
	for p in people:
		var d := Vector2(at.x - p.position.x, at.z - p.position.z).length()
		if p.visible and d <= best_distance:
			best = p
			best_distance = d
	return best


## The present person a ray (office space) points at, the nearest along it, or null.
func person_under(origin: Vector3, direction: Vector3) -> OfficePerson:
	var best: OfficePerson = null
	var best_distance := INF
	for p in people:
		var d := origin.distance_to(p.position)
		if p.visible and d < best_distance and p.picked_by(origin, direction):
			best = p
			best_distance = d
	return best


## Name tags on for these people only.
func show_tags(on: Array[OfficePerson]) -> void:
	for p in people:
		p.show_tag(p in on)


## Who is where and who needs a talk, from the session: its active missions, the hour
## (minute_of_day, when it has it: lunch), the names it knows (person) and energy_of
## (otherwise no bars).
func refresh(session: Object) -> void:
	_session = session
	if session != _named_by:
		_named_by = session
		_name_from(session)
	var active: Array = []
	if session.has_method("active_missions"):
		active = session.call("active_missions").map(func(m: MissionDef) -> String: return m.id)
	var missions: Variant = session.get("missions")
	var done: Dictionary = missions.done_once if missions is Missions else {}
	var lunchtime := false
	if session.has_method("minute_of_day"):
		var minute: int = session.call("minute_of_day")
		lunchtime = minute >= LUNCH.x and minute < LUNCH.y
	var energy := session.has_method("energy_of")
	for p in people:
		var spot := p.spot_at(lunchtime)
		p.at_lunch = lunchtime and p.lunch is Dictionary
		p.settle(spot)
		p.visible = p.present_for(active, done) and not spot.is_empty() and not _behind_shut_door(spot["at"])
		var state: Variant = session.call("energy_of", p.id) if energy and p.visible else {}
		p.show_energy(state if state is Dictionary else {})


## Names and roles from the session for the people it knows (one source, PLAN 1.3).
func _name_from(session: Object) -> void:
	if not session.has_method("person"):
		return
	for p in people:
		var known: Variant = session.call("person", p.id)
		if known is Dictionary and not str(known.get("name", "")).is_empty():
			p.name_as(str(known["name"]), str(known.get("role", p.role)))


func _behind_shut_door(at: Vector3) -> bool:
	return shut.any(func(r: Rect2) -> bool: return r.has_point(Vector2(at.x, at.z)))


func _process(delta: float) -> void:
	_since_refresh += delta
	if _session != null and _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh(_session)


## Where a cast spot is in the office: {at, face, pose[, route]}, or {} when its markers
## are not on the loaded floor. `pose` when the spot names none.
static func _spot(office: Office, spot: Dictionary, pose: String) -> Dictionary:
	var out := {"pose": str(spot.get("pose", pose))}
	if spot.has("seat") or spot.has("chair"):
		# at a workstation the user faces the desk, else the way the chair faces: both
		# along their -Z (the kits' +Y in Blender)
		var seat := str(spot.get("seat", ""))
		var chair := office.find_marker(seat + "_chair" if not seat.is_empty() else str(spot["chair"]))
		var facing := office.find_marker(seat + "_desk") if not seat.is_empty() else chair
		if chair == null or facing == null:
			return {}
		out.merge({"at": office.in_office(chair).origin * Vector3(1, 0, 1), "face": -office.in_office(facing).basis.z})
	elif spot.has("route"):
		var route := PackedVector3Array()
		for corner: Variant in spot["route"]:
			route.append(_floor(corner))
		if route.size() < 2:
			return {}
		out.merge({"at": route[0], "face": route[1] - route[0], "route": route})
	elif spot.has("at"):
		var at := _floor(spot["at"])
		out.merge({"at": at, "face": _floor(spot.get("face", [at.x, at.z - 1.0])) - at})
	else:
		return {}
	return out


## [x, z] in the office's space as a floor point.
static func _floor(xz: Variant) -> Vector3:
	if xz is Array and xz.size() == 2:
		return Vector3(float(xz[0]), 0, float(xz[1]))
	return Vector3.ZERO
