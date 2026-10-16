class_name OfficePeople
extends Node3D
## The people in the office (PLAN 1.3), placed from the cast list (cast.json): at a
## workstation of the office model (<seat>_chair, facing <seat>_desk), at a spot, or
## walking a route. Who is there follows the session: someone tied to missions is
## present only while one of them is active. The walk-around energy bar follows
## GameSession.energy_of when the session has it (the dialog engine adds it).

## Seconds between refreshes of who is present and who needs a talk.
const REFRESH_SECONDS := 0.5

var people: Array[OfficePerson] = []
var _since_refresh := 0.0
var _session: Object


## The cast's office people placed in `office` (its geometry must be loaded). Entries
## whose place cannot be found are left out, with a warning.
static func build(office: Office, cast: Array[Dictionary]) -> OfficePeople:
	var out := OfficePeople.new()
	out.name = "People"
	for entry in cast:
		var spot: Dictionary = entry.get("office", {})
		if spot.is_empty():
			continue
		if spot.has("stand_in_desk"):
			_stand_in_desk(office, str(spot.get("seat", "")), spot["stand_in_desk"])
		var p := OfficePerson.create(entry)
		if not _put(office, p, spot):
			push_warning("office: no place for %s" % p.id)
			p.free()
			continue
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


## Who is present and who needs a talk, from the session: its active missions, and
## energy_of(person) when it has that accessor (otherwise no bars).
func refresh(session: Object) -> void:
	_session = session
	var active: Array = []
	if session.has_method("active_missions"):
		active = session.call("active_missions").map(func(m: MissionDef) -> String: return m.id)
	var energy := session.has_method("energy_of")
	for p in people:
		p.visible = p.present_for(active)
		var state: Variant = session.call("energy_of", p.id) if energy and p.visible else {}
		p.show_energy(state if state is Dictionary else {})


func _process(delta: float) -> void:
	_since_refresh += delta
	if _session != null and _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh(_session)


static func _put(office: Office, p: OfficePerson, spot: Dictionary) -> bool:
	if spot.has("seat"):
		var chair := office.find_marker(str(spot["seat"]) + "_chair")
		var desk := office.find_marker(str(spot["seat"]) + "_desk")
		if chair == null or desk == null:
			return false
		# a desk's user faces its -Z (the desk kit's +Y in Blender)
		p.place(office.in_office(chair).origin * Vector3(1, 0, 1), -office.in_office(desk).basis.z)
		return true
	if spot.has("route"):
		for corner: Variant in spot["route"]:
			p.route.append(_floor(corner))
		if p.route.size() < 2:
			return false
		p.place(p.route[0], p.route[1] - p.route[0])
		return true
	if spot.has("at"):
		var at := _floor(spot["at"])
		p.place(at, _floor(spot.get("face", [at.x, at.z - 1.0])) - at)
		return true
	return false


## [x, z] in the office's space as a floor point.
static func _floor(xz: Variant) -> Vector3:
	if xz is Array and xz.size() == 2:
		return Vector3(float(xz[0]), 0, float(xz[1]))
	return Vector3.ZERO


## A workstation where the office model has none yet (marked a stand-in in the cast):
## the furniture of `spec.copy` (desk, chair, screen, keyboard) copied to `spec.at`, the
## user facing `spec.face`, with its collision (so the walk grid goes round it) and a sign.
static func _stand_in_desk(office: Office, seat: String, spec: Dictionary) -> void:
	var source := str(spec.get("copy", ""))
	var src_desk := office.find_marker(source + "_desk")
	if seat.is_empty() or src_desk == null or office.find_marker(seat + "_desk") != null:
		return
	var at := _floor(spec.get("at"))
	var desk_at := Transform3D(Basis.looking_at(_floor(spec.get("face")) - at, Vector3.UP), at)
	var move := desk_at * office.in_office(src_desk).affine_inverse()
	var to_geometry := office.in_office(office.geometry).affine_inverse()
	var root := Node3D.new()
	root.name = seat + "_stand_in"
	for part in ["desk", "chair", "monitor0", "screen0", "keyboard"]:
		var src := office.find_marker(source + "_" + part)
		if src == null:
			continue
		var copy: Node3D = src.duplicate()
		copy.name = seat + "_" + part
		copy.transform = to_geometry * move * office.in_office(src)
		root.add_child(copy)
	var body := StaticBody3D.new()
	for box: Array in [[Vector3(1.6, 0.76, 0.8), Vector3(0, 0.38, 0)], [Vector3(0.55, 0.9, 0.55), Vector3(0.05, 0.45, 0.62)]]:
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = box[0]
		shape.transform = to_geometry * desk_at * Transform3D(Basis.IDENTITY, box[1])
		body.add_child(shape)
	root.add_child(body)
	var sign := Label3D.new()
	sign.text = str(spec.get("sign", ""))
	sign.font_size = 40
	sign.pixel_size = 0.004
	sign.outline_size = 8
	sign.transform = to_geometry * desk_at * Transform3D(Basis.IDENTITY, Vector3(0, 1.55, -0.6))  # on the wall, read from the desk
	root.add_child(sign)
	office.geometry.add_child(root)
