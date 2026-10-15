class_name OfficeNav
extends RefCounted
## Where the player can walk, for click-to-move. A navigation mesh is baked
## from the office's collision (so desks, walls and the coach's glass room
## keep the character's radius clear), then laid on a fine grid for A*: the
## route comes back at once, without waiting for the navigation server's
## first sync, so it works headless and in the tests too.

## Grid cell, m.
const CELL := 0.2
## The character as the navmesh sees it (the player's capsule).
const AGENT_RADIUS := 0.3
const AGENT_HEIGHT := 1.6
## How far (cells) a click on furniture or a wall looks for a free spot.
const SNAP_CELLS := 12

var _grid := AStarGrid2D.new()
var _area: Rect2


## Bake from collision faces (office space) within the floor `area` (x, z).
static func bake(faces: PackedVector3Array, area: Rect2) -> OfficeNav:
	var source := NavigationMeshSourceGeometryData3D.new()
	source.add_faces(faces, Transform3D.IDENTITY)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = AGENT_RADIUS
	mesh.agent_height = AGENT_HEIGHT
	mesh.agent_max_climb = 0.1
	mesh.cell_size = 0.1
	mesh.cell_height = 0.05
	mesh.filter_baking_aabb = AABB(Vector3(area.position.x, -0.5, area.position.y), Vector3(area.size.x, 2.5, area.size.y))
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var nav := OfficeNav.new()
	nav._fill(mesh, area)
	return nav


## A cell is walkable when its centre lies on a navmesh polygon.
func _fill(mesh: NavigationMesh, area: Rect2) -> void:
	_area = area
	_grid.region = Rect2i(Vector2i.ZERO, Vector2i(ceili(area.size.x / CELL), ceili(area.size.y / CELL)))
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	_grid.fill_solid_region(_grid.region, true)
	var vertices := mesh.get_vertices()
	for i in mesh.get_polygon_count():
		var polygon := PackedVector2Array()
		for index in mesh.get_polygon(i):
			polygon.append(Vector2(vertices[index].x, vertices[index].z))
		var lo := _cell(_bounds(polygon).position)
		var hi := _cell(_bounds(polygon).end)
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				var c := Vector2i(x, y)
				if _grid.is_in_boundsv(c) and Geometry2D.is_point_in_polygon(_centre(c), polygon):
					_grid.set_point_solid(c, false)


static func _bounds(polygon: PackedVector2Array) -> Rect2:
	var r := Rect2(polygon[0], Vector2.ZERO)
	for p in polygon:
		r = r.expand(p)
	return r


func walkable(at: Vector3) -> bool:
	var c := _cell(Vector2(at.x, at.z))
	return _grid.is_in_boundsv(c) and not _grid.is_point_solid(c)


## The walking route from `from` to `to` (office space, on the floor): the
## corners to pass, ending at `to` (or the nearest free spot to it). Empty
## when there is no way there.
func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := _free_near(_cell(Vector2(from.x, from.z)))
	var goal := _free_near(_cell(Vector2(to.x, to.z)))
	var route := PackedVector3Array()
	if start.x < 0 or goal.x < 0:
		return route
	var cells := _grid.get_id_path(start, goal)
	if cells.is_empty():
		return route
	var end := to if walkable(to) else _point(goal)
	# String-pulling: keep only the corners the straight line cannot skip.
	var at := Vector3(from.x, 0, from.z)
	var i := 0
	while i < cells.size() - 1:
		var j := cells.size() - 1
		while j > i + 1 and not _clear(at, _point(cells[j])):
			j -= 1
		if j == cells.size() - 1 and _clear(at, end):
			break
		at = _point(cells[j])
		route.append(at)
		i = j
	route.append(end)
	return route


## Whether the straight line between two points stays on walkable cells.
func _clear(a: Vector3, b: Vector3) -> bool:
	var steps := ceili(Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) / (CELL * 0.5))
	for n in steps + 1:
		if not walkable(a.lerp(b, float(n) / maxf(steps, 1))):
			return false
	return true


## The nearest walkable cell to `c` within SNAP_CELLS, else (-1, -1).
func _free_near(c: Vector2i) -> Vector2i:
	for r in SNAP_CELLS + 1:
		var best := Vector2i(-1, -1)
		var best_d := INF
		for x in range(c.x - r, c.x + r + 1):
			for y in range(c.y - r, c.y + r + 1):
				var n := Vector2i(x, y)
				if maxi(absi(x - c.x), absi(y - c.y)) == r and _grid.is_in_boundsv(n) and not _grid.is_point_solid(n):
					var d := Vector2(n - c).length_squared()
					if d < best_d:
						best = n
						best_d = d
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori((at.x - _area.position.x) / CELL), floori((at.y - _area.position.y) / CELL))


func _centre(c: Vector2i) -> Vector2:
	return _area.position + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func _point(c: Vector2i) -> Vector3:
	var p := _centre(c)
	return Vector3(p.x, 0, p.y)
