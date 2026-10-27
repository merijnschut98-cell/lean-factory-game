class_name Interactable
extends Node3D
## A spot in the office where the player stands to do something: a team's
## place (a value-stream step), the obeya wall, the coach, the mission
## board, the stairs and the lift, or a shut door. Made from a marker in the
## office geometry; a faint ring on the floor shows where to stand, but only
## near the player or under the cursor, and never while the world waits (UX
## audit #2: the office is a workplace, not a level of quest markers).

const RING_RADIUS := 0.55
## Within this distance (m) of the player a ring fades in (estimate: two steps beyond the
## interaction reach, so it shows where to stand as you walk up, not across the floor).
const RING_SHOW := 3.0
## Seconds a ring takes to fade in or out.
const RING_FADE := 0.25
const RING_ALPHA := 0.75

## The marker's name in the geometry: "place:connections.design", "obeya",
## "coach", "mission_board", "stairs_up", "stairs_down", "lift" or "door:<room>".
var id := ""
## "place" or the role (the id itself).
var kind := ""
## For a place: the step ("connections.design").
var place := ""
## Whether the cursor is over its ring (the ring lights up).
var hovered := false
## Whether it has a ring at all (a shut door has none: only its prompt).
var has_ring := true
var _ring_mesh: MeshInstance3D
## 0 hidden … 1 fully shown (fade_ring).
var _ring_alpha := 0.0


static func create(marker_id: String, at: Transform3D) -> Interactable:
	var i := Interactable.new()
	i.id = marker_id
	i.name = marker_id.validate_node_name()
	if marker_id.begins_with("place:"):
		i.kind = "place"
		i.place = marker_id.trim_prefix("place:")
	else:
		i.kind = marker_id.get_slice(":", 0)   # "door:<room>" is a door
	i.transform = at
	i._ring_mesh = _ring()
	i.add_child(i._ring_mesh)
	i._paint_ring()
	return i


## Whether it has a ring on the floor (a shut door has none: only its prompt).
func show_ring(on: bool) -> void:
	has_ring = on
	_paint_ring()


func set_hovered(on: bool) -> void:
	if on == hovered:
		return
	hovered = on
	_ring_mesh.scale = Vector3(1.18, 0.35, 1.18) if on else Vector3(1, 0.2, 1)
	_paint_ring()


## Fade the ring towards shown when the player is within RING_SHOW (`distance`, m) or the
## cursor is over it, and the world is free; otherwise towards hidden.
func fade_ring(distance: float, world_free: bool, delta: float) -> void:
	var want := has_ring and world_free and (hovered or distance <= RING_SHOW)
	_ring_alpha = move_toward(_ring_alpha, 1.0 if want else 0.0, delta / RING_FADE)
	_paint_ring()


func ring_shown() -> bool:
	return _ring_mesh.visible


func _paint_ring() -> void:
	var alpha := _ring_alpha if has_ring else 0.0
	_ring_mesh.visible = alpha > 0.0
	(_ring_mesh.material_override as StandardMaterial3D).albedo_color = Color(Palette.VOLTANA_GREEN,
		(1.0 if hovered else RING_ALPHA) * alpha)


static func _ring() -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = RING_RADIUS - 0.06
	ring.outer_radius = RING_RADIUS
	ring.rings = 32
	ring.ring_segments = 6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := MeshInstance3D.new()
	mesh.mesh = ring
	mesh.material_override = mat
	mesh.scale = Vector3(1, 0.2, 1)
	mesh.position.y = 0.02
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
