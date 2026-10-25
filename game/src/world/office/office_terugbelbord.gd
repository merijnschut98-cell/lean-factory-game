class_name OfficeTerugbelbord
## The KCC's callback board (R-1 #4; PLAN 2.6 "every active tier-1 problem" has a tell): a cork
## pinboard on a stand by the team lead's desk, where the agents pin a yellow note for every
## caller they promise to ring back. It is the begane grond's tell (OfficeTells, `terugbelbord`):
## a few notes, two rows, or a board full, by the status calls the KCC answered this week. It
## never says what the calls are about; looking closer does (world.yaml, and the status
## callers' own line from mid up). Built in Godot like Ruud's whiteboard, so the floor's model
## and lightmaps need no rebuild.

## The tell's id (OfficeTells.THRESHOLDS) and its node's name in the geometry.
const TELL := "terugbelbord"
const NODE := "tell_" + TELL
## A marker of the KCC on the loaded floor: the board stands only where it is.
const KCC_MARKER := "kcc_lead_desk"
## Where it stands (office space, the begane grond): the board's middle at the floor, facing
## -X into the KCC, between the team lead's desk (x 21.4) and the agents' back pods (x 16.4);
## the KCC is x 0..24, z -16..0.
const AT := Vector3(19.6, 0, -8.5)
const FACING := Vector3(-1, 0, 0)
## The cork (m): 1.2 wide, 0.9 high, its middle at 1.4 m; the player stands this far in front.
const SIZE := Vector2(1.2, 0.9)
const MIDDLE_HEIGHT := 1.4
const STAND := 0.95
## The notes: 7.5 cm squares on a grid of 10 cm under the heading strip; how many each variant
## pins (a few, two rows, the board full and some pinned over others).
const NOTE := 0.075
const PITCH := 0.1
const COLUMNS := 11
const ROWS := 7
const NOTES := {"low": 3, "mid": 14, "high": 66}
const OVERLAP := 9
const CORK := Color("#b08a5a")
const FRAME := Color(0.72, 0.74, 0.77)
const PAPER := Color("#f3df5a")
const INK := Color("#3a3f4a")
const MARKER_BLUE := Color("#1f4fa8")


## The board, its stand, its notes in three variants (tell_terugbelbord_low, _mid, _high) and
## its collision as one node named for OfficeTells, placed in the geometry's space by
## `to_geometry` (office space → geometry).
static func build(to_geometry: Transform3D) -> Node3D:
	var root := Node3D.new()
	root.name = NODE
	root.transform = to_geometry * Transform3D(Basis.looking_at(-FACING, Vector3.UP), AT)
	var frame := _mat(FRAME, 0.35)
	frame.metallic = 0.6
	OfficeMesh.box(root, Vector3(SIZE.x + 0.05, SIZE.y + 0.05, 0.025), Vector3(0, MIDDLE_HEIGHT, -0.005), frame)
	OfficeMesh.box(root, Vector3(SIZE.x, SIZE.y, 0.012), Vector3(0, MIDDLE_HEIGHT, 0.008), _mat(CORK, 0.9))
	OfficeMesh.box(root, Vector3(SIZE.x * 0.45, 0.07, 0.004), Vector3(0, MIDDLE_HEIGHT + SIZE.y / 2.0 - 0.06, 0.016),
		_mat(Color.WHITE, 0.6))
	var title := Label3D.new()
	title.name = "Title"
	title.text = "Terugbellen"
	title.font_size = 48
	title.pixel_size = 0.0011
	title.modulate = MARKER_BLUE
	title.outline_size = 0
	title.position = Vector3(0, MIDDLE_HEIGHT + SIZE.y / 2.0 - 0.06, 0.019)
	root.add_child(title)
	for side: float in [-1.0, 1.0]:   # the stand: two legs on feet
		OfficeMesh.box(root, Vector3(0.035, MIDDLE_HEIGHT + SIZE.y / 2.0, 0.035),
			Vector3(side * (SIZE.x / 2.0 + 0.04), (MIDDLE_HEIGHT + SIZE.y / 2.0) / 2.0, 0), frame)
		OfficeMesh.box(root, Vector3(0.05, 0.04, 0.55), Vector3(side * (SIZE.x / 2.0 + 0.04), 0.05, 0), frame)
	var paper := _mat(PAPER, 0.8)
	var ink := _mat(INK, 0.9)
	for variant: String in NOTES:
		var notes := Node3D.new()
		notes.name = "%s_%s" % [NODE, variant]
		var n: int = NOTES[variant]
		for k in n:
			_note(notes, _slot(k, n), paper, ink)
		if variant == "high":
			for k in OVERLAP:   # pinned over the others where the board ran out of room
				_note(notes, _slot(k * 7 + 3, n) + Vector3(0.04, -0.035, 0.003), paper, ink)
		root.add_child(notes)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(SIZE.x + 0.2, 1.0, 0.6)
	shape.position = Vector3(0, 0.5, 0)
	body.add_child(shape)
	root.add_child(body)
	return root


## Where the player stands to look at it, on the floor in front of the board (office space).
static func stand() -> Vector3:
	return AT + FACING * STAND


## Note `k` of `n`'s place on the cork (the board's space): a few spread out, many filling it
## row by row from the top, each a little askew of the grid (by its number, so every build is
## the same).
static func _slot(k: int, n: int) -> Vector3:
	var spread := maxi(1, (COLUMNS * ROWS) / maxi(n, 1)) if n < COLUMNS else 1
	var cell := (k * spread) % (COLUMNS * ROWS)
	var col := cell % COLUMNS
	var row := cell / COLUMNS
	var top := MIDDLE_HEIGHT + SIZE.y / 2.0 - 0.15
	var wobble := Vector2(((k * 37) % 7 - 3) * 0.004, ((k * 53) % 5 - 2) * 0.004)
	return Vector3((col - (COLUMNS - 1) / 2.0) * PITCH + wobble.x, top - row * PITCH * 1.05 + wobble.y, 0.017)


## A yellow note at `at` (the board's space) with two lines of ink on it.
static func _note(parent: Node3D, at: Vector3, paper: Material, ink: Material) -> void:
	OfficeMesh.box(parent, Vector3(NOTE, NOTE, 0.002), at, paper)
	for line in 2:
		OfficeMesh.box(parent, Vector3(NOTE * (0.7 - line * 0.25), 0.006, 0.001),
			at + Vector3(-NOTE * line * 0.12, 0.015 - line * 0.02, 0.0015), ink)


static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
