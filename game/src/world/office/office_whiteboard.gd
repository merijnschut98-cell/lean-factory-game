class_name OfficeWhiteboard
## Ruud's whiteboard in the coach's room (PLAN 2.7c, the explainer's world hook): a mobile
## board on its stand by the glass wall, a sketch of the garden tap and hose on it, under
## "spanning · stroom · weerstand". Standing at it (E, or a click on its ring) opens the
## explainer "Hoe werkt het?" (Office.open_whiteboard). Built in Godot, not in the office
## model, so the floor's lightmaps need no rebake.

## The interaction point's id (an Interactable kind of its own).
const ID := "whiteboard"
## The board's node in the geometry.
const NODE := "ruud_whiteboard"
## The explainer it opens.
const EXPLAINER := "spanning_stroom_weerstand"
## Where it stands (office space, on the 1e): the board's middle at the floor, facing +X
## into the room; the coach's room is x 19.2..24, z -10.8..-16 (build_office.py COACH).
const AT := Vector3(19.78, 0, -14.5)
const FACING := Vector3(1, 0, 0)
## The board (m): 1.5 wide, 1.0 high, its middle at 1.45 m; the player stands this far
## in front of it.
const SIZE := Vector2(1.5, 1.0)
const MIDDLE_HEIGHT := 1.45
const STAND := 0.95
## Ruud's sketch: the explainer's own drawings, [layer, x, y (m from the board's middle),
## width (m)].
const SKETCHES: Array[Array] = [
	["wall_tap.svg", -0.5, -0.05, 0.3],
	["hose_thin.svg", 0.05, -0.12, 0.62],
]
const SKETCH_DIR := "res://assets/explainers/spanning/"
const MARKER_BLUE := Color("#1f4fa8")


## The board, its stand and its collision as one node (named so the office finds it),
## placed in the office's geometry space by `to_geometry` (office space → geometry).
static func build(to_geometry: Transform3D) -> Node3D:
	var root := Node3D.new()
	root.name = NODE
	root.transform = to_geometry * placement()
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color(0.72, 0.74, 0.77)
	frame.metallic = 0.6
	frame.roughness = 0.35
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.97, 0.97, 0.96)
	white.roughness = 0.2
	_box(root, Vector3(SIZE.x + 0.06, SIZE.y + 0.06, 0.03), Vector3(0, MIDDLE_HEIGHT, -0.005), frame)
	_box(root, Vector3(SIZE.x, SIZE.y, 0.01), Vector3(0, MIDDLE_HEIGHT, 0.012), white)
	for side: float in [-1.0, 1.0]:   # the stand: two legs on feet with castors
		_box(root, Vector3(0.035, MIDDLE_HEIGHT + SIZE.y / 2.0, 0.035),
			Vector3(side * (SIZE.x / 2.0 + 0.05), (MIDDLE_HEIGHT + SIZE.y / 2.0) / 2.0, 0), frame)
		_box(root, Vector3(0.05, 0.04, 0.6), Vector3(side * (SIZE.x / 2.0 + 0.05), 0.06, 0), frame)
	_box(root, Vector3(SIZE.x * 0.5, 0.025, 0.07), Vector3(0, MIDDLE_HEIGHT - SIZE.y / 2.0 - 0.02, 0.04), frame)   # the pen tray
	var title := Label3D.new()
	title.name = "Title"
	title.text = "spanning · stroom · weerstand"
	title.font_size = 64
	title.pixel_size = 0.0012
	title.modulate = MARKER_BLUE
	title.outline_size = 0
	title.position = Vector3(0, MIDDLE_HEIGHT + 0.32, 0.019)
	root.add_child(title)
	for s in SKETCHES:
		var path: String = SKETCH_DIR + str(s[0])
		if not ResourceLoader.exists(path):
			continue
		var sprite := Sprite3D.new()
		sprite.texture = load(path)
		sprite.pixel_size = float(s[3]) / maxf(1.0, sprite.texture.get_width())
		sprite.position = Vector3(float(s[1]), MIDDLE_HEIGHT + float(s[2]), 0.019)
		sprite.shaded = false
		root.add_child(sprite)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(SIZE.x + 0.2, 1.0, 0.6)
	shape.position = Vector3(0, 0.5, 0)
	body.add_child(shape)
	root.add_child(body)
	return root


## The board's transform in office space: at AT, its front (+Z of the node) along FACING.
static func placement() -> Transform3D:
	return Transform3D(Basis.looking_at(-FACING, Vector3.UP), AT)


## Where the player stands to use it, facing the board (an Interactable's transform).
static func stand() -> Transform3D:
	return Transform3D(Basis.looking_at(-FACING, Vector3.UP), AT + FACING * STAND)


## The point the camera looks at: the board's middle.
static func look_point() -> Vector3:
	return AT + Vector3.UP * MIDDLE_HEIGHT


static func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
