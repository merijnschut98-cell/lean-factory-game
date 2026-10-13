class_name OfficePlaceholder
## A plain stand-in for office.glb while the model is missing: floor, walls,
## a few desks and the same named markers, laid out like the model (Godot
## coordinates: the floor is x 0..24, z 0..-16, the entrance in the west
## wall). Office reads its markers exactly as it reads the glb's.

const W := 24.0
const D := 16.0
const H := 2.8
## Marker name → [standing point (x, z), the point it faces].
const MARKERS := {
	"place:connections.intake": [Vector2(3.2, -4.75), Vector2(3.2, -2.4)],
	"place:connections.design": [Vector2(9.0, -5.4), Vector2(9.0, -3.0)],
	"obeya": [Vector2(22.6, -3.4), Vector2(24.0, -3.4)],
	"coach": [Vector2(22.4, -13.0), Vector2(22.4, -14.7)],
	"mission_board": [Vector2(1.3, -9.9), Vector2(0.0, -9.9)],
	"spawn": [Vector2(1.6, -7.95), Vector2(8.0, -7.95)],
}
const WALL := Color("#e9ecef")
const DESK := Color("#c8b291")


static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "OfficePlaceholder"
	_box(root, Vector3(W, 0.1, D), Vector3(W / 2, -0.05, -D / 2), Color("#8a9099")).name = "shell_floor"
	_box(root, Vector3(W, 0.1, D), Vector3(W / 2, H + 0.05, -D / 2), Color("#f4f4f2"))
	_box(root, Vector3(W, H, 0.2), Vector3(W / 2, H / 2, 0.1), WALL)
	_box(root, Vector3(W, H, 0.2), Vector3(W / 2, H / 2, -D - 0.1), WALL)
	_box(root, Vector3(0.2, H, D), Vector3(-0.1, H / 2, -D / 2), WALL)
	_box(root, Vector3(0.2, H, D), Vector3(W + 0.1, H / 2, -D / 2), WALL)
	for x in [2.4, 4.0]:
		_box(root, Vector3(1.4, 0.75, 0.8), Vector3(x, 0.375, -2.0), DESK)
	for x in [7.4, 9.0, 10.6, 12.2]:
		_box(root, Vector3(1.4, 0.75, 0.8), Vector3(x, 0.375, -2.6), DESK)
	_box(root, Vector3(0.05, 1.2, 4.8), Vector3(W - 0.05, 1.55, -3.4), Color.WHITE)
	_box(root, Vector3(0.05, 0.9, 1.8), Vector3(0.05, 1.5, -9.9), Palette.VOLTANA_BLUE)
	for marker_name: String in MARKERS:
		var m := Marker3D.new()
		m.name = marker_name.validate_node_name()
		var at: Vector2 = MARKERS[marker_name][0]
		var to: Vector2 = MARKERS[marker_name][1]
		m.position = Vector3(at.x, 0, at.y)
		m.rotation.y = atan2(-(to.x - at.x), -(to.y - at.y))
		var kind := "place" if marker_name.begins_with("place:") else marker_name
		m.set_meta("extras", {"interaction": kind, "id": marker_name.trim_prefix("place:")})
		root.add_child(m)
	return root


static func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> StaticBody3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	var body := StaticBody3D.new()
	body.position = at
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = mat
	body.add_child(view)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = size
	body.add_child(shape)
	parent.add_child(body)
	return body
