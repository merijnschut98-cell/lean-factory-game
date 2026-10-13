class_name Office
extends Node3D
## Voltana's connections office, played in first person. Loads the office
## model (or a plain stand-in while it is missing), adds the sun and the
## environment, finds the interaction markers in the geometry by their glTF
## extras or their name, and routes E at a marker to the UI. The game
## itself lives in the GameSession; this scene only wires it to the world.

const MODEL := "res://assets/office/office.glb"
## The interaction markers to find (the spawn marker is found separately).
const INTERACTIONS: Array[String] = ["place:connections.intake", "place:connections.design", "obeya", "coach", "mission_board"]
const SPAWN := "spawn"
## How close (m, on the floor) the player must stand to a marker to use it.
const REACH := 1.6
## The model's own sky and ambient light (made with it); the project's
## default environment otherwise.
const ENVIRONMENT := "res://assets/office/office_environment.tres"
## The sun through the south windows, as in the model's preview.
const SUN_DIRECTION := Vector3(0.36, -0.53, -0.77)

## The simulation's luck for a new game.
@export var seed_value := 1
## Where the content is read from (tests point it at bad content).
@export var data_dir := Catalog.DATA_DIR

## Whether the mouse steers the view (else it is free: Esc, or a panel).
var mouse_captured := false

var session: GameSession
var geometry: Node3D
var player: Player
var ui: GameUI
var interactables: Array[Interactable] = []


func _ready() -> void:
	build()


## Build the office and start the game (once). Works outside the scene tree
## too, so the tests can build it headless: positions are the office's own.
func build() -> void:
	if session != null:
		return
	session = GameSession.new_game(seed_value, data_dir)
	geometry = _load_geometry()
	add_child(geometry)
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
	ui = GameUI.new()
	add_child(ui)
	ui.setup(session)
	ui.panel_opened.connect(_on_panel_opened)
	ui.panels_closed.connect(_on_panels_closed)
	_capture_mouse(true)


func _process(_delta: float) -> void:
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


## The nearest interaction point within REACH on the floor, or null. `at`
## is in the office's space (the player's position).
func interactable_near(at: Vector3) -> Interactable:
	var best: Interactable = null
	var best_distance := REACH
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
		"place":
			var step := session.region.net.step_at(target.place)
			return "E — " + (step.name if step != null else target.place)
		"obeya":
			return "E — Obeya-wand: A3 en Check"
		"coach":
			return "E — Coach: " + str(session.catalog.coach.get("name", ""))
		"mission_board":
			return "E — Missiebord"
	return ""


## Use an interaction point: open its panel.
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
	player.escape_pressed.connect(func() -> void:
		if ui.is_busy():
			ui.close_panels()
		else:
			_capture_mouse(not mouse_captured))


## A left click on the view (no panel took it) catches a mouse Esc freed.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and not mouse_captured and not ui.is_busy():
		_capture_mouse(true)


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
	_capture_mouse(false)


func _on_panels_closed() -> void:
	player.active = true
	_capture_mouse(true)


func _capture_mouse(capture: bool) -> void:
	mouse_captured = capture
	ui.hud.show_mouse_hint(not capture and not ui.is_busy())
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
