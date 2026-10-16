class_name PersonTag
extends Node3D
## Over a person in the office: their name and, when a talk could lift their
## spirit (a check-in prompt is open), a quiet "…" and a low-energy bar
## (Merijn, 2026-10-15; dialog spec §5.7). The bar shows their energy as a
## length and a colour, never a number. It turns with the camera. Until the
## people stand at their desks themselves (PLAN 1.3), it hangs over their
## place.

const WIDTH := 0.7
const HEIGHT := 0.09
const LOW := Color("#f07b22")
const OK := Color("#3ccf7a")
## Below this the bar is orange.
const LOW_ENERGY := 0.4
## The tag keeps its size on screen: at this camera distance (m) it is 1:1.
const REF_DISTANCE := 6.0

var person_id := ""
## 0..1 (the person's morale).
var energy := 1.0
var needs_talk := false
var _name: Label3D
var _back: MeshInstance3D
var _fill: MeshInstance3D


static func create(id: String, display_name: String) -> PersonTag:
	var t := PersonTag.new()
	t.person_id = id
	t.name = "tag_" + id
	t._name = Label3D.new()
	t._name.text = display_name + "  …"
	t._name.font_size = 40
	t._name.outline_size = 10
	t._name.pixel_size = 0.004
	t._name.position.y = 0.16
	t._name.no_depth_test = true
	t.add_child(t._name)
	t._back = t._quad(Vector2(WIDTH + 0.04, HEIGHT + 0.04), Color(0.07, 0.17, 0.33, 0.85), 0)
	t._fill = t._quad(Vector2(WIDTH, HEIGHT), OK, 1)
	return t


## Show the person's state: the tag shows only while a talk could help.
func show_state(person_energy: float, wants_a_talk: bool) -> void:
	energy = clampf(person_energy, 0.0, 1.0)
	needs_talk = wants_a_talk
	visible = needs_talk
	var mesh: QuadMesh = _fill.mesh
	mesh.size.x = maxf(0.01, WIDTH * energy)
	_fill.position.x = -WIDTH * (1.0 - energy) / 2.0
	(_fill.material_override as StandardMaterial3D).albedo_color = LOW if energy < LOW_ENERGY else OK


## Face the camera (the bar's fill grows from its left end) and keep the
## same size on screen at any zoom.
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d() if visible else null
	if camera != null:
		var d := camera.global_position.distance_to(global_position)
		global_basis = camera.global_basis.scaled(Vector3.ONE * maxf(1.0, d / REF_DISTANCE))


## The low-energy bar is showing.
func showing_bar() -> bool:
	return visible and needs_talk


func _quad(size: Vector2, color: Color, order: int) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = order
	m.material_override = mat
	add_child(m)
	return m
