class_name Office
extends Node3D
## Voltana's connections office, played in third person (Sims-like). Loads
## the office model (or a plain stand-in while it is missing), adds the sun
## and the environment, finds the interaction markers in the geometry by their
## glTF extras or their name, and routes E at a marker, or a click on its
## ring, to the UI. A left click on the floor walks the player there. The game
## itself lives in the GameSession; this scene only wires it to the world.

const MODEL := "res://assets/office/office.glb"
## The interaction markers to find (the spawn marker is found separately).
const INTERACTIONS: Array[String] = ["place:connections.intake", "place:connections.design", "obeya", "coach", "mission_board"]
const SPAWN := "spawn"
## The floor's mesh in the geometry (the map's outline).
const FLOOR := "shell_floor"
## How close (m, on the floor) the player must stand to a marker to use it.
const REACH := 1.6
## The model's own sky and ambient light (made with it); the project's
## default environment otherwise.
const ENVIRONMENT := "res://assets/office/office_environment.tres"
## The sun through the south windows, as in the model's preview.
const SUN_DIRECTION := Vector3(0.36, -0.53, -0.77)
## What the raised camera cuts away (by name in the geometry): the ceiling and
## what hangs from it, and the slabs (the roof).
const CUTAWAY: Array[String] = ["shell_ceiling", "light_panels", "air_diffusers", "building_slabs"]
## The camera's first view from the entrance: south-south-east over both
## teams to the windows, with room behind it to stay at its usual angle.
const START_YAW := -2.64
## Framing a station: the point looked at lies this far (m) ahead of where
## the player stands, at desk-top height (the in-tray, the screens, the board).
const FRAME_AHEAD := 0.9
const FRAME_HEIGHT := 0.8
## A click this close (m) to a ring's centre is a click on the ring.
const RING_CLICK := Interactable.RING_RADIUS + 0.3

## The simulation's luck for a new game.
@export var seed_value := 1
## Where the content is read from (tests point it at bad content).
@export var data_dir := Catalog.DATA_DIR
## Start with the training week (Inwerkweek); a returning player skips it on
## the mission board.
@export var training := true

var session: GameSession
var geometry: Node3D
var player: Player
var rig: CameraRig
var ui: GameUI
var interactables: Array[Interactable] = []
## The walk grid, baked on first use.
var _nav: OfficeNav
## The ring clicked last: opened when the walk there ends.
var _walk_goal: Interactable


func _ready() -> void:
	build()


## Build the office and start the game (once). Works outside the scene tree
## too, so the tests can build it headless: positions are the office's own.
func build() -> void:
	if session != null:
		return
	session = GameSession.new_game(seed_value, data_dir, training)
	geometry = _load_geometry()
	add_child(geometry)
	_cut_away_ceiling()
	_add_light()
	for id in INTERACTIONS:
		var marker := find_marker(id)
		if marker != null:
			var i := Interactable.create(id, in_office(marker))
			interactables.append(i)
			add_child(i)
		else:
			push_warning("office: no marker for " + id)
	_add_player()
	_add_camera()
	ui = GameUI.new()
	add_child(ui)
	ui.setup(session)
	ui.panel_opened.connect(_on_panel_opened)
	ui.panels_closed.connect(_on_panels_closed)
	if ui.playable():
		ui.office_map.show_office(floor_rect(), map_places(), player)
		ui.office_map.footprints = map_footprints()


func _process(_delta: float) -> void:
	player.view_yaw = rig.yaw
	if session.error.is_empty() and not ui.is_busy():
		ui.hud.show_prompt(prompt_for(interactable_near(player.position)))


## The model when it has been imported, else the stand-in.
static func _load_geometry() -> Node3D:
	if ResourceLoader.exists(MODEL):
		var packed: PackedScene = load(MODEL)
		if packed != null:
			return packed.instantiate()
	return OfficePlaceholder.build()


## A marker in the geometry: by its glTF extras {interaction, id}, or by its
## name (the importer rewrites ':' and '.', so names are compared loosely).
func find_marker(id: String) -> Node3D:
	return _find_marker(geometry, id, _loose(id))


static func _find_marker(node: Node, id: String, loose: String) -> Node3D:
	if node is Node3D and (_extras_id(node) == id or _loose(node.name) == loose):
		return node
	for child in node.get_children():
		var found := _find_marker(child, id, loose)
		if found != null:
			return found
	return null


## "place:connections.design" from extras {interaction: place, id: connections.design}.
static func _extras_id(node: Node) -> String:
	var extras: Variant = node.get_meta("extras", {})
	if not extras is Dictionary or not extras.has("interaction"):
		return ""
	return "place:" + str(extras.get("id", "")) if extras["interaction"] == "place" else str(extras["interaction"])


static func _loose(text: String) -> String:
	var out := ""
	for ch in text.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
	return out


func interactable(id: String) -> Interactable:
	for i in interactables:
		if i.id == id:
			return i
	return null


## A node's transform in the office's own space.
func in_office(node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != self:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## The nearest interaction point within `reach` on the floor, or null. `at`
## is in the office's space (the player's position, or a click).
func interactable_near(at: Vector3, reach := REACH) -> Interactable:
	var best: Interactable = null
	var best_distance := reach
	for i in interactables:
		var d := Vector2(at.x - i.position.x, at.z - i.position.z).length()
		if d <= best_distance:
			best = i
			best_distance = d
	return best


## "E — Werkvoorbereiding & ontwerp", or "" for null.
func prompt_for(target: Interactable) -> String:
	if target == null:
		return ""
	match target.kind:
		"obeya":
			return "E — Obeya-wand: A3 en Check"
		"coach":
			return "E — Coach: " + str(session.catalog.coach.get("name", ""))
	return "E — " + label_for(target)


## An interaction point's Dutch name: "Werkvoorbereiding & ontwerp".
func label_for(target: Interactable) -> String:
	match target.kind:
		"place":
			var step := session.region.net.step_at(target.place)
			return step.name if step != null else target.place
		"obeya":
			return "Obeya-wand"
		"coach":
			return "Coach: " + str(session.catalog.coach.get("name", ""))
		"mission_board":
			return "Missiebord"
	return target.id


## The interaction points for the map: [{id, label, at (x, z)}].
func map_places() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in interactables:
		out.append({"id": i.id, "label": label_for(i), "at": Vector2(i.position.x, i.position.z)})
	return out


## What stands on the floor, seen from above, for the map: [{rect (x, z),
## room}]. A room is a tall, wide frame smaller than half the floor (the
## coach's glass room); the rest is furniture. The shell, walls and things off the floor are left out.
func map_footprints() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var floor_area := floor_rect()
	for n in geometry.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = in_office(n) * (n as MeshInstance3D).get_aabb()
		var rect := Rect2(b.position.x, b.position.z, b.size.x, b.size.z)
		if absf(b.position.y) > 0.05 or b.size.y < 0.3 or not floor_area.encloses(rect.grow(-0.01)):
			continue
		var room := b.size.y >= 2.0 and rect.size.x > 2.0 and rect.size.y > 2.0 \
			and rect.size.x < floor_area.size.x / 2.0 and rect.size.y < floor_area.size.y / 2.0
		if room or (b.size.y < 2.0 and rect.get_area() > 0.15 and rect.get_area() < 6.0):
			out.append({"rect": rect, "room": room})
	return out


## The floor in the office's (x, z) plane: the floor mesh's bounds, else
## the markers' with a margin.
func floor_rect() -> Rect2:
	var floor_node := find_marker(FLOOR)
	if floor_node != null:
		var box := AABB()
		for n in [floor_node] + floor_node.find_children("*", "MeshInstance3D"):
			if n is MeshInstance3D:
				var b: AABB = in_office(n) * (n as MeshInstance3D).get_aabb()
				box = b if box.size == Vector3.ZERO else box.merge(b)
		if box.size.x > 0 and box.size.z > 0:
			return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var r := Rect2(Vector2(player.position.x, player.position.z), Vector2.ZERO)
	for i in interactables:
		r = r.expand(Vector2(i.position.x, i.position.z))
	return r.grow(2.0)


## Use an interaction point: open its panel, the camera framing the station.
func interact(target: Interactable) -> void:
	if target == null or not session.error.is_empty():
		return
	match target.kind:
		"place":
			ui.open_place(target.place)
		"obeya":
			ui.open_a3()
		"coach":
			ui.open_coach()
		"mission_board":
			ui.open_mission_board()
	if ui.is_busy():
		frame(target)


func _add_player() -> void:
	player = Player.new()
	add_child(player)
	var spawn := find_marker(SPAWN)
	if spawn != null:
		var at := in_office(spawn)
		player.position = at.origin
		player.face(at.basis)
	player.interact_pressed.connect(func() -> void:
		if not ui.is_busy():
			interact(interactable_near(player.position)))
	player.journal_pressed.connect(func() -> void: ui.toggle_journal())
	player.map_pressed.connect(func() -> void: ui.toggle_map())
	player.codex_pressed.connect(func() -> void: ui.toggle_codex())
	player.escape_pressed.connect(func() -> void:
		if ui.is_busy():
			ui.close_panels()
		else:
			player.stop())
	player.arrived.connect(_on_arrived)


func _add_camera() -> void:
	rig = CameraRig.new()
	rig.target = player
	rig.bounds = floor_rect()
	rig.yaw = START_YAW
	add_child(rig)
	rig.snap()
	rig.hold_inspect.connect(func(on: bool) -> void:
		var near := interactable_near(player.position)
		if on and near != null and not ui.is_busy():
			frame(near)
		elif not on and not ui.is_busy():
			rig.release())


## Frame a station with the camera: its desk, in-tray and board, close by.
func frame(target: Interactable) -> void:
	var ahead := -target.basis.z
	rig.inspect(frame_point(target), atan2(-ahead.x, -ahead.z))


## The point the camera looks at when it frames `target`.
func frame_point(target: Interactable) -> Vector3:
	var ahead := -target.basis.z
	ahead.y = 0
	return target.position + ahead.normalized() * FRAME_AHEAD + Vector3.UP * FRAME_HEIGHT


## The ceiling's meshes go on the layer the camera does not draw (they still
## cast their shadow, so the room keeps its light).
func _cut_away_ceiling() -> void:
	for id in CUTAWAY:
		var node := find_marker(id)
		if node == null:
			continue
		for n in [node] + node.find_children("*", "VisualInstance3D"):
			if n is VisualInstance3D:
				(n as VisualInstance3D).layers = CameraRig.CUTAWAY_LAYER


## A left click on the view (no panel took it): walk to that spot. A mouse
## move lights up the ring under the cursor.
func _unhandled_input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not clicked and not event is InputEventMouseMotion:
		return
	var origin := to_local(rig.camera.project_ray_origin(event.position))
	var ray := (to_local(rig.camera.project_ray_origin(event.position) + rig.camera.project_ray_normal(event.position)) - origin).normalized()
	if ray.y >= -0.01:
		return
	var point := origin + ray * (-origin.y / ray.y)
	if clicked:
		click_floor(point)
	else:
		hover_floor(point)


## Light up the ring at a floor point under the cursor (office space), and
## only that one; the cursor becomes a hand over it.
func hover_floor(point: Vector3) -> void:
	var under := interactable_near(point, RING_CLICK) if not ui.is_busy() else null
	for i in interactables:
		i.set_hovered(i == under)
	if DisplayServer.get_name() != "headless":
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if under != null else Input.CURSOR_ARROW)


## Walk to a clicked floor point (office space); a click on a place's ring
## walks there and opens it on arrival. False when the click is not for the
## world (a panel is open, the content failed) or nothing can be reached.
func click_floor(point: Vector3) -> bool:
	if ui.is_busy() or not session.error.is_empty():
		return false
	_walk_goal = interactable_near(point, RING_CLICK)
	var route := nav().path(player.position, _walk_goal.position if _walk_goal != null else point)
	player.walk(route)
	return not route.is_empty()


func _on_arrived() -> void:
	var goal := _walk_goal
	_walk_goal = null
	if goal != null and not ui.is_busy() and interactable_near(player.position) == goal:
		interact(goal)


## The walk grid, baked from the office's collision on first use.
func nav() -> OfficeNav:
	if _nav == null:
		_nav = OfficeNav.bake(_collision_faces(), floor_rect())
	return _nav


## Every collision triangle of the geometry, in the office's space.
func _collision_faces() -> PackedVector3Array:
	var faces := PackedVector3Array()
	for n in geometry.find_children("*", "CollisionShape3D", true, false):
		var shape := (n as CollisionShape3D).shape
		var local := PackedVector3Array()
		if shape is ConcavePolygonShape3D:
			local = shape.get_faces()
		elif shape is BoxShape3D:
			var box := BoxMesh.new()
			box.size = shape.size
			local = box.get_faces()
		var to_office := in_office(n)
		for v in local:
			faces.append(to_office * v)
	return faces


## The sun through the windows and the sky's ambient light.
func _add_light() -> void:
	if ResourceLoader.exists(ENVIRONMENT):
		var env := WorldEnvironment.new()
		env.environment = load(ENVIRONMENT)
		add_child(env)
	var sun := DirectionalLight3D.new()
	sun.basis = Basis.looking_at(SUN_DIRECTION)
	sun.light_color = Color(1, 0.95, 0.86)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)


func _on_panel_opened() -> void:
	player.active = false
	player.stop()
	rig.active = false


func _on_panels_closed() -> void:
	player.active = true
	rig.active = true
	rig.release()
