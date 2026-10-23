class_name OfficeKpiBoard
## The KPI board on the wall of Directie & Obeya on the 2e (PLAN 2.4c): a magnetic
## board with a column per team and the cards they steer by, magnets on them. Once the
## board exists (KpiBoard.unlocked, born at the obeya or in the first quarterly review's
## scene) you step up to it (E, or a click on its ring) and the camera moves in; the
## board itself opens (KpiBoardView). Built in Godot like Ruud's whiteboard, against
## the room's west wall from the room's own marker, so the floor's model needs nothing.

## The interaction point's id (an Interactable kind of its own) and the board's node.
const ID := "kpi_board"
const NODE := "kpi_board_wall"
const ROOM := "directors_obeya"
## The board (m): as the obeya boards beside it, 2.4 wide and 1.2 high, its middle at
## 1.55 m, this far off the wall line; the player stands this far in front.
const SIZE := Vector2(2.4, 1.2)
const MIDDLE_HEIGHT := 1.55
const OFF_WALL := 0.09
const STAND := 1.1
## Facing +X into the room, from its west wall.
const FACING := Vector3(1, 0, 0)
const PROMPT := "E — KPI-bord"
const LABEL := "KPI-bord"
const CARD := Vector2(0.5, 0.16)


## Directie & Obeya's floor area (x, z) on the loaded floor; empty when it is elsewhere.
static func room_of(office: Office) -> Rect2:
	var marker: Node = office.floors.markers().get("room:" + ROOM)
	return OfficeFloors.room_rect(marker) if marker != null else Rect2()


## The board's transform in office space for its room's rect (x, z).
static func placement(room: Rect2) -> Transform3D:
	var at := Vector3(room.position.x + OFF_WALL, 0, room.get_center().y)
	return Transform3D(Basis.looking_at(-FACING, Vector3.UP), at)


## Where the player stands to use it, facing the board.
static func stand(room: Rect2) -> Transform3D:
	var t := placement(room)
	return Transform3D(t.basis, t.origin + FACING * STAND)


static func look_point(room: Rect2) -> Vector3:
	return placement(room).origin + Vector3.UP * MIDDLE_HEIGHT


## The board, placed in the geometry by `to_geometry` (office space → geometry), with
## `columns`: [[team name, [card names]]] as the teams steer now (empty cards: none yet).
static func build(to_geometry: Transform3D, room: Rect2, columns: Array) -> Node3D:
	var root := Node3D.new()
	root.name = NODE
	root.transform = to_geometry * placement(room)
	var frame := _material(Color(0.72, 0.74, 0.77), 0.6, 0.35)
	_box(root, Vector3(SIZE.x + 0.06, SIZE.y + 0.06, 0.03), Vector3(0, MIDDLE_HEIGHT, -0.005), frame)
	_box(root, Vector3(SIZE.x, SIZE.y, 0.01), Vector3(0, MIDDLE_HEIGHT, 0.012), _material(KpiBoardView.ENAMEL, 0.0, 0.25))
	_text(root, "KPI-bord Aansluitingen", 72, KpiBoardView.MARKER_BLUE, Vector3(-SIZE.x / 2 + 0.55, MIDDLE_HEIGHT + 0.49, 0.019), 1200.0)
	var width := SIZE.x / maxf(1.0, columns.size())
	for i in columns.size():
		var x := -SIZE.x / 2 + width * (i + 0.5)
		_box(root, Vector3(width - 0.08, 0.07, 0.004), Vector3(x, MIDDLE_HEIGHT + 0.36, 0.018),
			_material(Palette.VOLTANA_BLUE, 0.0, 0.6))
		_text(root, str(columns[i][0]), 40, Color.WHITE, Vector3(x, MIDDLE_HEIGHT + 0.36, 0.021))
		var cards: Array = columns[i][1]
		for j in cards.size():
			var y := MIDDLE_HEIGHT + 0.2 - j * (CARD.y + 0.06)
			var colour := KpiBoardView.CARD_COLOURS[i % KpiBoardView.CARD_COLOURS.size()]
			_box(root, Vector3(CARD.x, CARD.y, 0.003), Vector3(x, y, 0.019), _material(colour, 0.0, 0.8))
			_text(root, str(cards[j]), 34, Palette.INK, Vector3(x, y - 0.02, 0.022))
			var magnet := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.02
			disc.bottom_radius = 0.02
			disc.height = 0.012
			magnet.mesh = disc
			magnet.material_override = _material(KpiBoardView.MAGNET, 0.1, 0.4)
			magnet.rotation_degrees = Vector3(90, 0, 0)
			magnet.position = Vector3(x, y + CARD.y / 2 - 0.01, 0.026)
			root.add_child(magnet)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(SIZE.x + 0.1, 1.0, 0.12)
	shape.position = Vector3(0, 0.5, 0)
	body.add_child(shape)
	root.add_child(body)
	return root


## The teams on the menu with the names of the cards they steer by now.
static func columns_of(s: GameSession) -> Array:
	var out := []
	var board := s.region.board
	for pool: String in s.catalog.kpis.menus:
		var names: Array = s.catalog.kpis.defs_for(pool, board.chosen.get(pool, PackedStringArray())).map(
			func(k: KpiDef) -> String: return k.name)
		var team: String = s.region.net.pools[pool].name if s.region.net.pools.has(pool) else pool
		out.append([team, names])
	return out


static func _text(parent: Node3D, text: String, size: int, colour: Color, at: Vector3, width := 420.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0011
	l.modulate = colour
	l.outline_size = 0
	l.width = width
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = at
	parent.add_child(l)


static func _material(colour: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.metallic = metallic
	m.roughness = roughness
	return m


static func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
