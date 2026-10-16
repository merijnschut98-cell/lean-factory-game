class_name Office
extends Node3D
## Voltana's connections office, played in third person (Sims-like). Loads
## the office model (or a plain stand-in while it is missing), adds the sun
## and the environment, finds the interaction markers in the geometry by their
## glTF extras or their name, and routes E at a marker, or a click on its
## ring, to the UI. A left click on the floor walks the player there. The people
## at their desks (OfficePeople, from the cast list) show their name on hover;
## E next to one, or a click on them, asks for a talk: `person_selected(id)`,
## and the dialog opens (GameUI.ask_talk). The game itself lives in the GameSession; this
## scene only wires it to the world.

## The player asks to talk with a person (E next to them, or a click on them).
signal person_selected(person_id: String)

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
## A talk is framed this far round (rad) from straight behind the player,
## towards the side the person faces, so their face shows beside the
## player's shoulder.
const TALK_ANGLE := 0.6
## The person's face this share of the screen's width right of the middle
## (the player's shoulder on the left).
const TALK_SHIFT := -0.08
## The person's face sits this far (m) under the top of their head.
const FACE_DROP := 0.2

const RESUME_FAILED := "De bewaarde game kon niet worden geladen (%s). Dit spel wordt niet bewaard, zodat de oude bewaard blijft."
const WHITEBOARD_PROMPT := "E — Whiteboard: hoe werkt het?"
const WHITEBOARD_LABEL := "Whiteboard van Ruud"

## The saves (PLAN 2.7; tests point it at their own folder).
var saves := SaveSlots.new()
## The slot the game continues from ("" for a new game): the title menu's
## pick (play), or the autosave when this office is the main scene.
var resume_slot := ""
## Whether the game saves itself (into the autosave only, never a manual
## slot): the real game does, tests and tools do not.
var autosaves := false
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
var people: OfficePeople
## The head office's floors (PLAN 2.1): which floor is loaded, the stairs and the lift,
## the rooms' doors.
var floors: OfficeFloors
## The walk grid, baked on first use.
var _nav: OfficeNav
## The ring or person clicked last: used when the walk there ends.
var _walk_goal: Node3D
## The person under the cursor (their name tag shows).
var _hovered_person: OfficePerson
## The "Hoe werkt het?" explainer open over the world (Ruud's whiteboard), or null.
var explainer: ExplainerView


func _ready() -> void:
	# Run as the main scene (from the editor) it resumes the autosave; tests
	# and tools that load this scene play a fresh game of their own.
	if get_tree().current_scene == self and not autosaves:
		play(SaveSlots.AUTOSAVE)
	build()


## Play the real game (before build): continue from `slot` (one of
## SaveSlots.names()), or a new game for "" or an empty slot; it saves itself.
func play(slot: String) -> void:
	resume_slot = slot
	autosaves = true


## The game closes: it saves, and the session ends (GameUI.end_session).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and ui != null and ui.playable():
		ui.end_session()


## Build the office and start the game (once): the saved game in `resume_slot`
## when there is one (it opens with the terugblik), else a new one. Works
## outside the scene tree too, so the tests can build it headless: positions
## are the office's own.
func build() -> void:
	if session != null:
		return
	var loaded := _resume()
	session = loaded["session"] if loaded.has("session") else GameSession.new_game(seed_value, data_dir, training)
	floors = OfficeFloors.new()
	floors.setup(self)
	add_child(floors)
	_add_light()
	load_floor()
	for id in INTERACTIONS:
		if interactable(id) == null:
			push_warning("office: no marker for " + id)
	_add_player()
	_add_camera()
	ui = GameUI.new()
	add_child(ui)
	ui.setup(session, loaded.get("layer"))
	ui.panel_opened.connect(_on_panel_opened)
	ui.talk_opened.connect(frame_talk)
	ui.panels_closed.connect(_on_panels_closed)
	if ui.playable():
		show_map()
		floors.floor_changed.connect(func(id: String) -> void: ui.session_layer.floor_id = id)
		enter_saved_floor(ui.session_layer.floor_id)
		ui.title_requested.connect(to_title)
		if autosaves:
			ui.begin_play(saves, loaded.has("session"))
	if loaded.has("error"):
		ui.hud.toast(RESUME_FAILED % loaded["error"])


## The saved game in `resume_slot`: SaveSlots.resume's result; {} when there
## is none. A save that cannot be read is left alone, and this game does not
## save itself ({error} only, autosaves off): an autosave that failed to
## load is never written over.
func _resume() -> Dictionary:
	if resume_slot.is_empty() or saves.entry(resume_slot).is_empty():
		return {}
	var loaded := saves.resume(resume_slot, data_dir)
	if loaded["error"].is_empty():
		return loaded
	push_warning("office: " + loaded["error"])
	autosaves = false
	return {"error": loaded["error"]}


## Build, continuing on floor `floor_id` (as a save that was left there does).
func resume_on(floor_id: String) -> void:
	build()
	enter_saved_floor(floor_id)


## Go to the floor a saved game was left on, by the lift; an unknown or shut floor
## (the content changed) keeps the start floor.
func enter_saved_floor(floor_id: String) -> void:
	if floor_id.is_empty() or floor_id == floors.floor_id or floors.building.floor_of(floor_id).is_empty() \
			or not floors.building.floor_open(floor_id, floors.open_now()):
		return
	floors.go_to(floor_id, "lift")


## Back to the title menu (the pause menu's choice; the game has saved).
func to_title() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(TitleMenu.SCENE)


func _process(_delta: float) -> void:
	player.view_yaw = rig.yaw
	if session.error.is_empty() and not busy():
		ui.hud.show_prompt(prompt_near(player.position))
	var tagged: Array[OfficePerson] = []
	if not busy():
		for p: OfficePerson in [_hovered_person, people.person_near(player.position, REACH)]:
			if p != null:
				tagged.append(p)
	people.show_tags(tagged)


## The model when it has been imported, else the stand-in.
static func _load_geometry(path := MODEL) -> Node3D:
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path)
		if packed != null:
			return packed.instantiate()
	return OfficePlaceholder.build()


## Load the floor OfficeFloors is on in place of the one shown (at the start, and on
## the stairs or in the lift): its model, its doors as the rooms are now, its interaction
## points and its people. The player, the camera, the UI and the game stay as they are.
func load_floor() -> void:
	_clear_interactables()
	for n: Node in [people, geometry]:
		if n != null:
			remove_child(n)
			n.free()
	_nav = null
	_walk_goal = null
	_hovered_person = null
	geometry = _load_geometry(floors.model_path())
	add_child(geometry)
	_cut_away_ceiling()
	if find_marker("coach") != null:   # the coach's room is on this floor: Ruud's whiteboard
		geometry.add_child(OfficeWhiteboard.build(in_office(geometry).affine_inverse()))
	floors.apply_rooms()
	_add_interactables()
	people = OfficePeople.build(self, CharacterModel.cast(), floors.here)
	add_child(people)
	_refresh_people()
	if ui != null and ui.playable():
		show_map()


## A room opened (a mission that needs it was taken on): its door opens, its places
## and its people come within reach and the walk grid is baked again.
func reload_rooms() -> void:
	_clear_interactables()
	floors.apply_rooms()
	_add_interactables()
	_refresh_people()
	_nav = null
	if ui.playable():
		show_map()


## Who is where, with the doors as they are now.
func _refresh_people() -> void:
	people.shut = floors.shut_rects(floors.markers())
	if session.error.is_empty():   # content that failed to load has no missions to read
		people.refresh(session)


func _clear_interactables() -> void:
	for i in interactables:
		remove_child(i)
		i.free()
	interactables.clear()


## An interaction point at each usable marker of the floor (OfficeFloors.usable_markers);
## a shut door shows no ring, only its prompt.
func _add_interactables() -> void:
	var markers := floors.usable_markers(geometry)
	for id: String in markers:
		var i := Interactable.create(id, in_office(markers[id]))
		i.show_ring(i.kind != "door")
		interactables.append(i)
		add_child(i)
	if find_marker(OfficeWhiteboard.NODE) != null:
		var board := Interactable.create(OfficeWhiteboard.ID, OfficeWhiteboard.stand())
		interactables.append(board)
		add_child(board)


## The player map shows the floor the player is on, with the floor switch.
func show_map() -> void:
	ui.office_map.show_office(floor_rect(), map_places(), player)
	ui.office_map.footprints = map_footprints()
	floors.refresh_map()


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


## What E uses from `at`: the nearer of the interaction point and the person
## within REACH, or null.
func target_near(at: Vector3) -> Node3D:
	var place := interactable_near(at)
	var person := people.person_near(at, REACH)
	if person == null or place == null:
		return person if person != null else place
	var to_person := Vector2(at.x - person.position.x, at.z - person.position.z).length()
	var to_place := Vector2(at.x - place.position.x, at.z - place.position.z).length()
	return person if to_person < to_place else place


## The prompt for what E uses from `at` ("" for nothing).
func prompt_near(at: Vector3) -> String:
	var target := target_near(at)
	if target is OfficePerson:
		var p := target as OfficePerson
		return "E — Coach: " + p.display_name if p.talk == "coach" else "E — Praat met " + p.display_name
	return prompt_for(target as Interactable)


## "E — Werkvoorbereiding & ontwerp", or "" for null.
func prompt_for(target: Interactable) -> String:
	if target == null:
		return ""
	var seam := floors.prompt(target)
	if not seam.is_empty():
		return seam
	match target.kind:
		"obeya":
			return "E — Obeya-wand: A3 en Check"
		"coach":
			return "E — Coach: " + str(session.catalog.coach.get("name", ""))
		OfficeWhiteboard.ID:
			return tr(WHITEBOARD_PROMPT)
	return "E — " + label_for(target)


## An interaction point's Dutch name: "Werkvoorbereiding & ontwerp".
func label_for(target: Interactable) -> String:
	var seam := floors.label(target)
	if not seam.is_empty():
		return seam
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
		OfficeWhiteboard.ID:
			return tr(WHITEBOARD_LABEL)
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
	return footprints_of(geometry, floor_rect(), self)


## map_footprints for any floor's geometry (`office` places it; it need not be loaded).
static func footprints_of(of_geometry: Node3D, floor_area: Rect2, office: Office) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in of_geometry.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = office.in_office(n) * (n as MeshInstance3D).get_aabb()
		var rect := Rect2(b.position.x, b.position.z, b.size.x, b.size.z)
		if absf(b.position.y) > 0.05 or b.size.y < 0.3 or minf(rect.size.x, rect.size.y) < 0.05 \
				or not floor_area.encloses(rect.grow(-0.01)):
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
	if target == null or not session.error.is_empty() or floors.use(target):
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
		OfficeWhiteboard.ID:
			open_whiteboard()
	if ui.is_busy():
		frame(target)


## Whether the world waits: a panel or the explainer is open.
func busy() -> bool:
	return ui.is_busy() or explainer != null


## Ruud's whiteboard (PLAN 2.7c): the camera moves in to the board and the explainer
## "Hoe werkt het?" opens over it; closing it gives the world back. Never forced.
func open_whiteboard() -> void:
	if busy():
		return
	_on_panel_opened()
	_world_input(false)
	var ahead := -OfficeWhiteboard.FACING
	rig.converse(OfficeWhiteboard.look_point(), atan2(-ahead.x, -ahead.z), 0.0, 0.0)
	explainer = ExplainerView.open(self, OfficeWhiteboard.EXPLAINER, {"log": session.explainers})
	explainer.closed.connect(_on_explainer_closed)


func _on_explainer_closed(_id: String) -> void:
	explainer = null
	_world_input(true)
	_on_panels_closed()


## The world's own keys and clicks (E, J, M, K, Esc, a click on the floor) on or off,
## while something over it takes them.
func _world_input(on: bool) -> void:
	set_process_unhandled_input(on)
	player.set_process_unhandled_input(on)


## Use what is in reach: a person (a talk) or an interaction point.
func use(target: Node3D) -> void:
	if target is OfficePerson:
		talk_to(target)
	elif target is Interactable:
		interact(target)


## Talk with `person` (person_selected says who): the dialog opens, or a toast
## says why not. The coach opens the coach's panel.
func talk_to(person: OfficePerson) -> void:
	if person == null or not session.error.is_empty():
		return
	if person.talk == "coach":
		interact(interactable("coach"))
		return
	person_selected.emit(person.id)
	ui.ask_talk(person.id, person.display_name)


## Frame a talk with a person in the office: the player turns to them and the
## camera looks at their face over the player's shoulder, above the panel.
## Someone not here (a phone call) leaves the view as it is.
func frame_talk(person_id: String) -> void:
	var person := people.person(person_id)
	if person == null or not person.visible:
		return
	var to_person := (person.position - player.position) * Vector3(1, 0, 1)
	if to_person.length() > 0.01:
		player.face(Basis.looking_at(to_person.normalized()))
	rig.converse(talk_point(person), talk_yaw(person, player.position), TALK_SHIFT, DialogPanel.HEIGHT_SHARE / 2.0)


## The camera's yaw for a talk: from behind the player standing `at`, turned
## TALK_ANGLE to whichever side sees more of the person's face.
func talk_yaw(person: OfficePerson, at: Vector3) -> float:
	var back := (at - person.position) * Vector3(1, 0, 1)
	var straight := atan2(back.x, back.z)
	var faces := -person.basis.z
	var left := straight + TALK_ANGLE
	var right := straight - TALK_ANGLE
	# the side whose camera stands more in front of the person
	return left if Vector3(sin(left), 0, cos(left)).dot(faces) >= Vector3(sin(right), 0, cos(right)).dot(faces) else right


## The point a talk looks at: the person's face.
func talk_point(person: OfficePerson) -> Vector3:
	return person.position + Vector3.UP * (person.height() - FACE_DROP)


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
			use(target_near(player.position)))
	player.journal_pressed.connect(func() -> void: ui.toggle_journal())
	player.map_pressed.connect(func() -> void: ui.toggle_map())
	player.codex_pressed.connect(func() -> void: ui.toggle_codex())
	player.escape_pressed.connect(func() -> void:
		if ui.is_busy():
			ui.close_panels()
		else:
			player.stop()
			ui.open_pause())
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


## Frame a station with the camera: its desk, in-tray and board, close by,
## in the middle of the room a docked panel leaves.
func frame(target: Interactable) -> void:
	var ahead := -target.basis.z
	rig.inspect(frame_point(target), atan2(-ahead.x, -ahead.z), ui.docked_share() / 2.0)


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


## A left click on the view (no panel took it): on a person, walk up and ask
## for a talk; else walk to that spot. A mouse move shows the name of the
## person under the cursor, or lights up the ring under it.
func _unhandled_input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not clicked and not event is InputEventMouseMotion:
		return
	var origin := to_local(rig.camera.project_ray_origin(event.position))
	var ray := (to_local(rig.camera.project_ray_origin(event.position) + rig.camera.project_ray_normal(event.position)) - origin).normalized()
	var person := people.person_under(origin, ray) if not ui.is_busy() else null
	if clicked and person != null:
		click_person(person)
		return
	if not clicked:
		hover_person(person)
	if ray.y >= -0.01:
		return
	var point := origin + ray * (-origin.y / ray.y)
	if clicked:
		click_floor(point)
	elif person == null:
		hover_floor(point)


## The person under the cursor (null for none): their name tag shows, the rings
## go dark, the cursor becomes a hand.
func hover_person(person: OfficePerson) -> void:
	_hovered_person = person
	if person == null:
		return
	for i in interactables:
		i.set_hovered(false)
	if DisplayServer.get_name() != "headless":
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


## Walk up to a clicked person and ask for a talk on arrival. False when the
## click is not for the world or there is no way there.
func click_person(person: OfficePerson) -> bool:
	if ui.is_busy() or not session.error.is_empty():
		return false
	_walk_goal = person
	var route := nav().path(player.position, person.position)
	player.walk(route)
	return not route.is_empty()


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
	if goal == null or ui.is_busy():
		return
	if goal == interactable_near(player.position) or goal == people.person_near(player.position, REACH):
		use(goal)


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
	people.refresh(session)
	player.active = true
	rig.active = true
	rig.release()
