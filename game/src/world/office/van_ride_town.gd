class_name VanRideTown
extends Node3D
## The edge of town the van ride passes (VanRide; design 2026-10-21 §1.7: a canned drive-by
## loop, simple, readable and cheap): a Dutch "rand van de stad" in the cab's space (the cab
## faces -Z, you sit on the right). The road with its dashed middle line and white edges, a
## red bike lane (fietspad) beyond the verge, a pavement, terraced houses (rijtjeshuizen) with
## front hedges and solar panels on some roofs, a trafohuisje on the corner, lamp posts; on
## the left a row of trees, a ditch (sloot), fields and a barn, wind turbines far off. Plain
## boxes and colours, no textures. The ground stays put; what stands on it drifts past
## (`movers`, VanRide._drift) round a loop, and the turbines' rotors turn (`blades`).

## The road across x (m): its left and right edges; the bike lane, the pavement, the ditch.
const ROAD := Vector2(-4.6, 1.6)
const BIKE_LANE := Vector2(3.0, 5.2)
const PAVEMENT := Vector2(5.6, 7.2)
const DITCH := Vector2(-8.5, -7.0)
## How far the ground runs ahead and behind (m).
const AHEAD := 420.0
const BACK := 60.0
## Terraced houses: where their fronts stand (x), a house's width and depth, wall height and
## roof; the blocks' first z and how many houses each has.
const HOUSE_X := 10.5
const HOUSE_W := 5.6
const HOUSE_D := 9.0
const WALL_H := 5.8
const ROOF_H := 3.0
const BLOCKS := [[-30.0, 6], [-90.0, 5], [-170.0, 6], [-235.0, 4]]
const BRICKS := [Color(0.55, 0.27, 0.2), Color(0.62, 0.36, 0.26), Color(0.47, 0.25, 0.2), Color(0.66, 0.5, 0.38)]
const ROOF := Color(0.24, 0.22, 0.22)
const PANEL := Color(0.08, 0.12, 0.24)
const WINDOW := Color(0.12, 0.15, 0.18)
const FRAME := Color(0.92, 0.92, 0.9)
const HEDGE := Color(0.18, 0.36, 0.16)
const GRASS := Color(0.32, 0.5, 0.22)
const FIELD := Color(0.4, 0.55, 0.24)
const ASPHALT := Color(0.24, 0.25, 0.26)
const LINE := Color(0.9, 0.9, 0.86)
const BIKE_RED := Color(0.55, 0.22, 0.17)
const TILES := Color(0.62, 0.61, 0.58)
const WATER := Color(0.2, 0.28, 0.3)
const BARK := Color(0.3, 0.22, 0.16)
const LEAVES := Color(0.22, 0.4, 0.17)
const POLE := Color(0.5, 0.52, 0.54)
const TURBINE := Color(0.93, 0.94, 0.95)
const TRAFO := Color(0.74, 0.72, 0.66)
const TRAFO_DOOR := Color(0.24, 0.3, 0.28)
const WARNING := Color(0.95, 0.78, 0.1)
## One loop of the dashed middle line: a 3 m stripe every 9 m (the Dutch "deelstreep", an
## estimate by eye).
const DASH := 3.0
const DASH_EVERY := 9.0

var _materials := {}


## The town, its drifting things added to `movers` and its rotors to `blades`.
static func build(movers: Array[Node3D], blades: Array[Node3D]) -> VanRideTown:
	var t := VanRideTown.new()
	t.name = "Town"
	t._ground()
	var loop := VanRide.LOOP
	var z := 0.0
	while z > -loop:   # the middle line
		movers.append(t._box(t, Vector3(0.12, 0.01, DASH), Vector3((ROAD.x + ROAD.y) / 2, 0.012, z), LINE))
		z -= DASH_EVERY
	for b: Array in BLOCKS:
		movers.append(t._block(b[0], b[1]))
	z = -8.0
	while z > -loop:   # lamp posts on the right verge, trees on the left
		movers.append(t._lamp(Vector3(2.3, 0, z)))
		movers.append(t._tree(Vector3(-5.6, 0, z - 11.0), 1.0 + fmod(-z, 7.0) / 14.0))
		z -= 30.0
	movers.append(t._trafohuisje(Vector3(8.2, 0, -66.0)))
	movers.append(t._barn(Vector3(-46.0, 0, -140.0)))
	for at: Vector3 in [Vector3(-170, 0, -120), Vector3(-230, 0, -40), Vector3(-200, 0, -230)]:
		movers.append(t._turbine(at, blades))
	return t


func _ground() -> void:
	var length := AHEAD + BACK
	var mid := (BACK - AHEAD) / 2.0
	_strip(Vector2(-260, 260), -0.03, GRASS, length, mid)
	_strip(Vector2(-140, DITCH.x - 1.0), -0.02, FIELD, length, mid)
	_strip(ROAD, 0.0, ASPHALT, length, mid)
	_strip(BIKE_LANE, 0.004, BIKE_RED, length, mid)
	_strip(PAVEMENT, 0.008, TILES, length, mid)
	_strip(DITCH, -0.01, WATER, length, mid)
	for x in [ROAD.x + 0.25, ROAD.y - 0.25]:   # the white edge lines
		_strip(Vector2(x - 0.06, x + 0.06), 0.006, LINE, length, mid)


## A flat strip across x `span` at height `y`, running along z.
func _strip(span: Vector2, y: float, color: Color, length: float, mid: float) -> MeshInstance3D:
	return _box(self, Vector3(span.y - span.x, 0.02, length), Vector3((span.x + span.y) / 2, y - 0.01, mid), color)


## A row of `count` terraced houses from z `first` backwards, their fronts to the road.
func _block(first: float, count: int) -> Node3D:
	var row := Node3D.new()
	row.position = Vector3(HOUSE_X, 0, first)
	add_child(row)
	for k in count:
		var z := -k * HOUSE_W - HOUSE_W / 2
		var brick: Color = BRICKS[(k + int(-first)) % BRICKS.size()]
		_box(row, Vector3(HOUSE_D, WALL_H, HOUSE_W - 0.04), Vector3(HOUSE_D / 2, WALL_H / 2, z), brick)
		var roof := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(HOUSE_D + 0.6, ROOF_H, HOUSE_W)
		roof.mesh = prism
		roof.material_override = _material(ROOF)
		roof.position = Vector3(HOUSE_D / 2, WALL_H + ROOF_H / 2, z)
		row.add_child(roof)
		if k % 2 == 0:   # solar panels on the slope towards the road
			var panels := _box(row, Vector3(0.06, 2.2, HOUSE_W - 1.4), Vector3(2.4, WALL_H + 1.35, z), PANEL)
			panels.rotation.z = atan2(HOUSE_D / 2 + 0.3, ROOF_H)
		for floor_y in [1.5, 4.3]:   # the street front's windows, and the door
			_box(row, Vector3(0.1, 1.3, 2.0), Vector3(-0.02, floor_y, z - 0.9), FRAME)
			_box(row, Vector3(0.12, 1.15, 1.85), Vector3(-0.04, floor_y, z - 0.9), WINDOW)
		_box(row, Vector3(0.12, 2.1, 1.0), Vector3(-0.04, 1.05, z + 1.6), WINDOW)
		_box(row, Vector3(0.7, 0.9, HOUSE_W - 1.6), Vector3(-2.2, 0.45, z - 0.5), HEDGE)
	return row


func _lamp(at: Vector3) -> Node3D:
	var lamp := Node3D.new()
	lamp.position = at
	add_child(lamp)
	_box(lamp, Vector3(0.12, 6.0, 0.12), Vector3(0, 3.0, 0), POLE)
	_box(lamp, Vector3(1.4, 0.1, 0.12), Vector3(-0.65, 6.0, 0), POLE)
	_box(lamp, Vector3(0.5, 0.12, 0.25), Vector3(-1.3, 5.92, 0), FRAME)
	return lamp


func _tree(at: Vector3, size: float) -> Node3D:
	var tree := Node3D.new()
	tree.position = at
	add_child(tree)
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16 * size
	cyl.bottom_radius = 0.22 * size
	cyl.height = 3.2 * size
	trunk.mesh = cyl
	trunk.material_override = _material(BARK)
	trunk.position.y = 1.6 * size
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 2.2 * size
	ball.height = 3.8 * size
	crown.mesh = ball
	crown.material_override = _material(LEAVES)
	crown.position.y = 4.6 * size
	tree.add_child(crown)
	return tree


## The trafohuisje on the corner: a small concrete box with two green doors and the yellow
## lightning sign.
func _trafohuisje(at: Vector3) -> Node3D:
	var house := Node3D.new()
	house.position = at
	add_child(house)
	_box(house, Vector3(2.0, 2.3, 2.6), Vector3(1.0, 1.15, 0), TRAFO)
	_box(house, Vector3(2.2, 0.15, 2.8), Vector3(1.0, 2.37, 0), TRAFO_DOOR)
	for dz in [-0.6, 0.6]:
		_box(house, Vector3(0.06, 1.9, 1.0), Vector3(-0.02, 0.95, dz), TRAFO_DOOR)
	_box(house, Vector3(0.04, 0.3, 0.3), Vector3(-0.06, 1.95, 0), WARNING)
	return house


func _barn(at: Vector3) -> Node3D:
	var barn := Node3D.new()
	barn.position = at
	add_child(barn)
	_box(barn, Vector3(14.0, 5.0, 24.0), Vector3(0, 2.5, 0), Color(0.36, 0.18, 0.14))
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(15.0, 4.0, 24.5)
	roof.mesh = prism
	roof.material_override = _material(Color(0.2, 0.22, 0.2))
	roof.position.y = 7.0
	barn.add_child(roof)
	return barn


## A wind turbine far off: an 80 m tower, a nacelle, three blades on a turning hub.
func _turbine(at: Vector3, blades: Array[Node3D]) -> Node3D:
	var turbine := Node3D.new()
	turbine.position = at
	add_child(turbine)
	var tower := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 2.2
	cyl.height = 80.0
	tower.mesh = cyl
	tower.material_override = _material(TURBINE)
	tower.position.y = 40.0
	turbine.add_child(tower)
	_box(turbine, Vector3(3.0, 3.0, 8.0), Vector3(0, 81.0, 1.0), TURBINE)
	var hub := Node3D.new()
	hub.position = Vector3(0, 81.0, -3.2)
	turbine.add_child(hub)
	for k in 3:
		var blade := _box(hub, Vector3(1.6, 38.0, 0.5), Vector3(0, 19.0, 0), TURBINE)
		blade.position = Vector3(0, 19.0, 0).rotated(Vector3.FORWARD, k * TAU / 3)
		blade.rotation.z = -k * TAU / 3
	hub.rotation.z = fmod(at.x, TAU)
	blades.append(hub)
	return turbine


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	m.material_override = _material(color)
	m.position = at
	parent.add_child(m)
	return m


## One material per colour, shared.
func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.85
		_materials[color] = mat
	return _materials[color]
