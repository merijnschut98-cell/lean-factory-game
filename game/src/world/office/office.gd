class_name Office
extends Node3D
## Voltana's connections office, played in third person (Sims-like). Loads
## the office model (or a plain stand-in while it is missing), adds the light
## by the clock (OfficeDaylight), finds the interaction markers in the geometry by their
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
## How much farther (m) a tell counts than its footprint is, against a place or a person.
const TELL_BIAS := 0.6
## The model's own sky and ambient light (made with it); the project's
## default environment otherwise.
const ENVIRONMENT := "res://assets/office/office_environment.tres"
## The sun through the south windows by day, as in the model's preview (OfficeDaylight).
const SUN_DIRECTION := Vector3(0.36, -0.53, -0.77)
## What the raised camera cuts away (by name in the geometry): the ceiling and
## what hangs from it, and the slabs (the roof).
const CUTAWAY: Array[String] = ["shell_ceiling", "light_panels", "air_diffusers", "building_slabs"]
## The camera's first view from the entrance: south-south-east over both
## teams to the windows, with room behind it to stay at its usual angle.
const START_YAW := -2.64

const RESUME_FAILED := "De bewaarde game kon niet worden geladen (%s). Dit spel wordt niet bewaard, zodat de oude bewaard blijft."
const WHITEBOARD_PROMPT := "E — Whiteboard: hoe werkt het?"
const WHITEBOARD_LABEL := "Whiteboard van Ruud"

## The saves (PLAN 2.7; tests point it at their own folder).
var saves := SaveSlots.new()
## The slot the game continues from ("" for a new game): the title menu's
## pick (play), or the autosave when this office is the main scene.
var resume_slot := ""
## The game in `resume_slot` when the title menu has already loaded it
## (SaveSlots.resume's result); {} to load it here.
var resumed := {}
## Whether the game saves itself (into the autosave only, never a manual
## slot): the real game does, tests and tools do not.
var autosaves := false
## The simulation's luck for a new game.
@export var seed_value := 1
## Where the content is read from (tests point it at bad content).
@export var data_dir := Catalog.DATA_DIR
## The player made in the character creator for a new game (PLAN 2.7b);
## null keeps the default look (tests, tools) or the saved one.
var new_player: PlayerProfile
## Start with the training week (Inwerkweek); a returning player skips it on
## the mission board.
@export var training := true
## A new game opens as one scene, De eerste vijf minuten (PLAN 2.7d; the UI
## agent's OfficeOpening): "Nieuw spel" sets it; tests and tools leave it off.
var opening := false
## The first day's scene while it runs (also a resumed one), else null.
var first_day: OfficeOpening

var session: GameSession
var geometry: Node3D
var player: Player
var rig: CameraRig
var ui: GameUI
var interactables: Array[Interactable] = []
var people: OfficePeople
## The sun, the sky and the desk lamps by the clock (PLAN 2.14 S1-A).
var daylight: OfficeDaylight
## Going home after five, and the empty desks of the colleagues who have (OfficeHome).
var home: OfficeHome
## The head office's floors (PLAN 2.1): which floor is loaded, the stairs and the lift,
## the rooms' doors.
var floors: OfficeFloors
## The walk grid, baked on first use.
var _nav: OfficeNav
## The camera for talks, scenes and stations (OfficeStaging).
var staging := OfficeStaging.new(self)
## The mouse: hover and click on people, rings, tells and the floor (OfficePointer).
var pointer := OfficePointer.new(self)
## A scene's line, choice or paper holds the player (hold_for_scene).
var _scene_holds := false
## The "Hoe werkt het?" explainer open over the world (Ruud's whiteboard), or null.
var explainer: ExplainerView
## The KPI board open at the directie obeya (PLAN 2.4c), or null.
var kpi_board: KpiBoardView
## Ruud's paper floor plan in the corner (PLAN 2.1b); null when the game cannot be played.
var minimap: OfficeMinimap
## The yard's clock-keeper (the vans by the hour, PLAN 2.2) while the yard is loaded, or null.
var yard: OfficeYard
## The van ride under way (PLAN 2.15 S2-Y), or null.
var ride: VanRide
## The office's sound (S1-B) while the game can be played, or null.
var sound: Soundscape
## The props that read the region (PLAN 2.6) while a floor with tells is loaded, or null.
var tells: OfficeTells
## The character creator open over the world ("Uiterlijk" in the pause menu), or null.
var look_editor: CreatorScreen
## People turning to you, greeting you, chatting at the coffee corner (Phase 2 §1.4).
var reactions: OfficeReactions
## A milestone's scene in its room (phase-2 design §3.1) while the game can be played, or null.
var milestone: OfficeMilestone
## Your desk's things (name plate, photo, letter, clipboard) while its floor is loaded, or null.
var desk: OfficeDesk


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
	if new_player != null and not loaded.has("session"):
		session.player = new_player
	floors = OfficeFloors.new()
	floors.setup(self)
	add_child(floors)
	daylight = OfficeDaylight.create(self)
	add_child(daylight)
	load_floor()
	for id in INTERACTIONS:
		if interactable(id) == null:
			push_warning("office: no marker for " + id)
	_add_player()
	_add_camera()
	reactions = OfficeReactions.create(self)
	add_child(reactions)
	ui = GameUI.new()
	add_child(ui)
	ui.setup(session, loaded.get("layer", _opening_layer()))
	ui.panel_opened.connect(_on_panel_opened)
	ui.world_free = world_free
	ui.talk_opened.connect(staging.frame_talk)
	if ui.playable():
		ui.talk_view.phase_changed.connect(func(_phase: String) -> void: staging.stage_talk())
		ui.talk_view.explainer_requested.connect(open_talk_explainer)
	ui.panels_closed.connect(_on_panels_closed)
	home = OfficeHome.create(self)
	add_child(home)
	home.poll()
	if ui.playable():
		show_map()
		sound = Soundscape.new()
		sound.office = self
		add_child(sound)
		ui.phone.buzz.connect(sound.play.bind("phone_buzz", -6.0))
		minimap = OfficeMinimap.new()
		add_child(minimap)
		minimap.setup(self)
		ui.hud.keep_clear_below_toasts(Minimap.DIAMETER + Minimap.MARGIN)
		floors.floor_changed.connect(func(id: String) -> void: ui.session_layer.floor_id = id)
		enter_saved_floor(ui.session_layer.floor_id)
		ui.title_requested.connect(to_title)
		ui.pause_menu.look_requested.connect(open_look)
		ui.pause_changed.connect(_on_pause_changed)
		ui.pause_menu.auto_text_changed.connect(_on_auto_text)
		milestone = OfficeMilestone.create(self)
		add_child(milestone)
		if autosaves:
			ui.begin_play(saves, loaded.has("session"))
		if Opening.running(ui.session_layer):
			first_day = OfficeOpening.create(self)
			add_child(first_day)
	if loaded.has("error"):
		ui.hud.toast(RESUME_FAILED % loaded["error"])


## The saved game in `resume_slot`: SaveSlots.resume's result; {} when there
## is none. A save that cannot be read is left alone, and this game does not
## save itself ({error} only, autosaves off): an autosave that failed to
## load is never written over.
func _resume() -> Dictionary:
	if not resumed.is_empty():
		return resumed
	if resume_slot.is_empty() or saves.entry(resume_slot).is_empty():
		return {}
	var loaded := saves.resume(resume_slot, data_dir)
	if loaded["error"].is_empty():
		return loaded
	push_warning("office: " + loaded["error"])
	autosaves = false
	return {"error": loaded["error"]}


## A new game's session layer at the opening's first beat (PLAN 2.7d), or null
## (no opening: a returning player skips the week, tests and tools).
func _opening_layer() -> SessionLayer:
	if not opening or not session.in_training():
		return null
	var layer := SessionLayer.new()
	layer.begin(session)
	layer.opening_beat = Opening.ARRIVAL
	layer.has_floor_plan = false   # Ruud hands it over on the walk (B3)
	return layer


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


func _process(delta: float) -> void:
	player.view_yaw = rig.yaw
	if ui.playable():
		staging.follow_walking_talk(delta)
	if session.error.is_empty() and not busy():
		OfficeCheckScreen.refresh(self)
		ui.hud.show_prompt(prompt_near(player.position))
	var tagged: Array[OfficePerson] = []
	if not busy():
		for p: OfficePerson in [pointer.hovered, people.person_near(player.position, REACH)]:
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
	var stay_in: Array[String] = people.stay_in if people != null else ([] as Array[String])
	for n: Node in [people, geometry, yard, tells, desk]:
		if n != null:
			remove_child(n)
			n.free()
	_nav = null
	staging.forget_walls()
	pointer.forget()
	geometry = _load_geometry(floors.model_path())
	add_child(geometry)
	_cut_away_ceiling()
	desk = OfficeDesk.create(self)   # your desk at Aansluitingen (PLAN 2.10)
	if desk != null:
		add_child(desk)
	if find_marker("coach") != null:   # the coach's room is on this floor: Ruud's whiteboard
		geometry.add_child(OfficeWhiteboard.build(in_office(geometry).affine_inverse()))
	if find_marker(OfficeTerugbelbord.KCC_MARKER) != null:   # the KCC is on this floor: its callback board (a tell)
		geometry.add_child(OfficeTerugbelbord.build(in_office(geometry).affine_inverse()))
	_hang_kpi_wall()
	floors.apply_rooms()
	_add_interactables()
	people = OfficePeople.build(self, CharacterModel.cast(), floors.here)
	people.stay_in = stay_in
	add_child(people)
	_refresh_people()
	daylight.update(session)
	yard = null
	tells = OfficeTells.create(self)
	if tells != null:
		add_child(tells)
		if session.error.is_empty():
			tells.refresh()
	if find_marker("van0") != null:   # the yard (PLAN 2.2): its vans go out and come back by the hour
		yard = OfficeYard.new()
		yard.name = "Yard"
		yard.office = self
		add_child(yard)
		if session.error.is_empty():
			yard.poll()
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
	staging.forget_walls()   # an opened door no longer hides anything
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
	if coach_moved():   # the coach's room on the 1e is the team's overlegkamer now
		markers.erase("coach")
	for id: String in markers:
		var i := Interactable.create(id, in_office(markers[id]))
		i.show_ring(i.kind != "door")
		interactables.append(i)
		add_child(i)
	if find_marker(OfficeWhiteboard.NODE) != null:
		var board := Interactable.create(OfficeWhiteboard.ID, OfficeWhiteboard.stand())
		interactables.append(board)
		add_child(board)
	var kpi_wall: Variant = OfficeKpiBoard.placement_in(self)   # the KPI board, once it exists and its room is open
	if kpi_wall != null and OfficeKpiBoard.ROOM in floors.open and session.error.is_empty() \
			and session.region.board.unlocked:
		var kpi := Interactable.create(OfficeKpiBoard.ID, OfficeKpiBoard.stand(kpi_wall))
		interactables.append(kpi)
		add_child(kpi)
	# the KCC's free desk (begane grond, once its room is open); your desk; Petra's screen (2.10)
	# and on the yard the trafohuisje mock-up once the opleidingsterrein is open (2.7c)
	for at: Interactable in [OfficeHeadset.place(self), OfficeDesk.place(self), OfficeCheckScreen.place(self),
			OfficeTrafohuisje.place(self)]:
		if at != null:
			interactables.append(at)
			add_child(at)


## Whether the coach has moved out of the coach's room (cast `moves`: Ruud back up to his
## own office on the 2e after the first hundred days).
func coach_moved() -> bool:
	var done: Dictionary = session.missions.done_once if session.error.is_empty() else {}
	return CharacterModel.cast().any(func(e: Dictionary) -> bool:
		var at: Dictionary = e.get("office", {})
		return at.get("talk", "") == "coach" and OfficePerson.moves_of(at).any(func(m: String) -> bool: return done.has(m)))


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
## is in the office's space (the player's position, or a click). A hidden one (Petra's
## screen while no Check waits) is not there.
func interactable_near(at: Vector3, reach := REACH) -> Interactable:
	var best: Interactable = null
	var best_distance := reach
	for i in interactables:
		if not i.visible:
			continue
		var d := Vector2(at.x - i.position.x, at.z - i.position.z).length()
		if d <= best_distance:
			best = i
			best_distance = d
	return best


## What E uses from `at`: the nearest of the interaction point, the person and the tell
## (by its footprint, PLAN 2.15) within REACH, or null. A tie goes to the place; a tell
## counts TELL_BIAS farther than it is, so the person at a desk comes before their in-tray.
func target_near(at: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for n: Node3D in [interactable_near(at), people.person_near(at, REACH)]:
		var d := Vector2(at.x - n.position.x, at.z - n.position.z).length() if n != null else INF
		if d < best_distance:
			best = n
			best_distance = d
	var tell := tells.nearest(at, REACH) if tells != null else ""
	if not tell.is_empty() and tells.distance(tell, at) + TELL_BIAS < best_distance:
		best = tells.roots[tell]
	return best


## The prompt for what E uses from `at` ("" for nothing).
func prompt_near(at: Vector3) -> String:
	var target := target_near(at)
	if target is OfficePerson:
		var p := target as OfficePerson
		return "E — Coach: " + p.display_name if p.talk == "coach" else "E — Praat met " + p.display_name
	if tells != null and not tells.id_of(target).is_empty():
		return tr(OfficeTells.PROMPT) if tells.looking() != tells.id_of(target) else ""
	return prompt_for(target as Interactable)


## "E — Werkvoorbereiding & ontwerp", or "" for null.
func prompt_for(target: Interactable) -> String:
	if target == null:
		return ""
	var seam := floors.prompt(target) + home.prompt(target) + (yard.prompt(target) if yard != null else "")
	if not seam.is_empty():
		return seam
	match target.kind:
		"obeya":
			return "E — Obeya-wand: je A3"
		"coach":
			return "E — Coach: " + str(session.catalog.coach.get("name", ""))
		OfficeWhiteboard.ID:
			return tr(WHITEBOARD_PROMPT)
		OfficeHeadset.ID:
			return tr(OfficeHeadset.PROMPT)
		OfficeKpiBoard.ID:
			return tr(OfficeKpiBoard.PROMPT)
		OfficeDesk.ID:
			return tr(OfficeDesk.PROMPT)
		OfficeCheckScreen.ID:
			return tr(OfficeCheckScreen.PROMPT)
		OfficeTrafohuisje.ID:
			return tr(OfficeTrafohuisje.PROMPT)
	return "E — " + label_for(target)


## An interaction point's Dutch name: "Werkvoorbereiding & ontwerp".
func label_for(target: Interactable) -> String:
	var seam := floors.label(target) + home.label(target) + (yard.label(target) if yard != null else "")
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
		OfficeHeadset.ID:
			return tr(OfficeHeadset.LABEL)
		OfficeKpiBoard.ID:
			return tr(OfficeKpiBoard.LABEL)
		OfficeDesk.ID:
			return tr(OfficeDesk.LABEL)
		OfficeCheckScreen.ID:
			return tr(OfficeCheckScreen.LABEL)
		OfficeTrafohuisje.ID:
			return tr(OfficeTrafohuisje.LABEL)
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
	if target == null or not session.error.is_empty() or floors.use(target) or home.use(target) \
			or (yard != null and yard.use(target)):
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
		OfficeHeadset.ID:
			OfficeHeadset.take_call(self)
		OfficeKpiBoard.ID:
			open_kpi_board()
		OfficeDesk.ID:
			ui.open_a3()
		OfficeCheckScreen.ID:
			ui.open_check()
		OfficeTrafohuisje.ID:
			open_trafohuisje()
	if ui.is_busy():
		staging.frame(target)


## Whether the world waits: a panel, the explainer or the creator is open, or a van ride is on.
func busy() -> bool:
	return ui.is_busy() or explainer != null or look_editor != null or ride != null or kpi_board != null


## Whether the world is the player's (review S3 #2): no panel, talk or phone, no view over
## it (the KPI board, the explainer, the creator), no ride, no scene holding them or playing.
## Only then does a call ring, and only then are its keys 1 and 2 its own.
func world_free() -> bool:
	return not busy() and not _scene_holds and (milestone == null or milestone.playing.is_empty())


## "Uiterlijk" (PLAN 2.7b): the creator over the world on the current look and
## name; its photo changes them, free and silent (no time, money or trust).
func open_look() -> CreatorScreen:
	ui.close_panels()
	_on_panel_opened()
	_world_input(false)
	look_editor = CreatorScreen.open(self, CreatorScreen.Mode.EDIT, session.player)
	look_editor.done.connect(apply_look)
	look_editor.cancelled.connect(_close_look)
	look_editor.get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_world(true)   # the scene under it stays where the pause menu left it
	return look_editor


func apply_look(made: PlayerProfile) -> void:
	session.player = made
	player.wear(made.look)
	_close_look()


func _close_look() -> void:
	var layer := look_editor.get_parent()
	remove_child(layer)
	layer.queue_free()
	look_editor = null
	_pause_world(false)
	_world_input(true)
	_on_panels_closed()


## Ruud's whiteboard (PLAN 2.7c): the camera moves in to the board and the explainer
## "Hoe werkt het?" opens over it; closing it gives the world back. Never forced.
func open_whiteboard() -> void:
	_open_explainer_at(OfficeWhiteboard.EXPLAINER, OfficeWhiteboard.look_point(), -OfficeWhiteboard.FACING)


## The trafohuisje on the opleidingsterrein (2.7c): the same, for "Hoe werkt het? 2".
func open_trafohuisje() -> void:
	var at := OfficeTrafohuisje.stand(self)
	_open_explainer_at(OfficeTrafohuisje.EXPLAINER, OfficeTrafohuisje.look_point(self), -at.basis.z)


## The camera moves in to `look` (seen along `ahead`) and the explainer opens with its
## speaker's beats; the world's keys are off until it closes.
func _open_explainer_at(explainer_id: String, look: Vector3, ahead: Vector3) -> void:
	if busy():
		return
	_on_panel_opened()
	_world_input(false)
	rig.converse(look, atan2(-ahead.x, -ahead.z), 0.0, 0.0)
	explainer = ExplainerView.open(self, explainer_id,
		{"log": session.explainers, "auto": SceneLines.auto_setting()})
	explainer.closed.connect(_on_explainer_closed)
	explainer.pause_requested.connect(ui.open_pause)


## The KPI board at the directie obeya (PLAN 2.4c): the camera moves in to the wall and
## the board opens (KpiBoardView); closing it gives the world back and the wall shows
## the choice in force. Null when the world is busy or the board does not exist yet.
func open_kpi_board() -> KpiBoardView:
	var wall: Variant = OfficeKpiBoard.placement_in(self)
	if busy() or wall == null or not session.region.board.unlocked:
		return null
	_on_panel_opened()
	_world_input(false)
	var ahead: Vector3 = -(wall as Transform3D).basis.z
	rig.converse(OfficeKpiBoard.look_point(wall), atan2(-ahead.x, -ahead.z), 0.0, 0.0)
	kpi_board = KpiBoardView.open(self, session)
	kpi_board.closed.connect(_on_kpi_board_closed)
	return kpi_board


func _on_kpi_board_closed(_result: Dictionary) -> void:
	kpi_board = null
	_hang_kpi_wall()
	_world_input(true)
	_on_panels_closed()
	ui.after_action()


## The KPI board on Directie & Obeya's wall (on the 2e), as the teams steer now.
func _hang_kpi_wall() -> void:
	var old := find_marker(OfficeKpiBoard.NODE)
	if old != null:
		old.get_parent().remove_child(old)
		old.free()
	var wall: Variant = OfficeKpiBoard.placement_in(self)
	if wall != null and session.error.is_empty():
		geometry.add_child(OfficeKpiBoard.build(in_office(geometry).affine_inverse(), wall, OfficeKpiBoard.columns_of(session)))


## An expert's topic opens a "Hoe werkt het?" explainer over the talk (phase 2
## design §2.5): the drawing free to play with (the codex's way, no Ruud: the
## expert's answer is the explanation); closing it goes back to the talk.
func open_talk_explainer(explainer_id: String) -> void:
	if explainer != null:
		return
	explainer = ExplainerView.open(self, explainer_id, {"codex": true, "log": session.explainers})
	if not explainer.error.is_empty():
		push_warning("talk explainer: " + explainer.error)
		explainer.queue_free()
		explainer = null
		return
	ui.talk_view.process_mode = Node.PROCESS_MODE_DISABLED   # its keys 1–4 are the drawing's now
	explainer.closed.connect(func(_id: String) -> void:
		explainer = null
		ui.talk_view.process_mode = Node.PROCESS_MODE_INHERIT)


## The pause menu over Ruud's board (Esc in the explainer, as anywhere in a scene).
func _on_pause_changed(on: bool) -> void:
	if explainer != null:
		explainer.visible = not on   # the sheet is over the menu's layer: it waits out of sight


## "Tekst loopt vanzelf door" switched in the pause menu: the scene on screen follows.
func _on_auto_text(on: bool) -> void:
	if first_day != null:
		first_day.lines.auto = on
	if explainer != null and explainer.beats != null:
		explainer.beats.auto = on


func _pause_world(on: bool) -> void:
	if is_inside_tree():
		get_tree().paused = on


func _on_explainer_closed(_id: String) -> void:
	explainer = null
	_world_input(true)
	_on_panels_closed()


## The world's own keys and clicks (E, J, M, K, Esc, a click on the floor) on or off,
## while something over it takes them.
func _world_input(on: bool) -> void:
	set_process_unhandled_input(on)
	player.set_process_unhandled_input(on)


## Use what is in reach: a person (a talk), an interaction point, or a tell (look closer).
func use(target: Node3D) -> void:
	if target is OfficePerson:
		talk_to(target)
	elif target is Interactable:
		interact(target)
	elif tells != null and not tells.id_of(target).is_empty() and session.error.is_empty():
		tells.look(tells.id_of(target))


## Talk with `person` (person_selected says who): the dialog opens, or a toast
## says why not; with nothing to discuss they say one line about today over their head
## (the quick exchange: no panel). The coach opens the coach's panel.
func talk_to(person: OfficePerson) -> void:
	if person == null or not session.error.is_empty():
		return
	if person.talk == "coach":
		var coach := interactable("coach")
		if coach != null:
			interact(coach)
		else:   # in his own office on the 2e
			staging.turn_to(person)
			ui.open_coach()
		return
	person_selected.emit(person.id)
	if ui.ask_talk(person.id, person.display_name) in GameUI.NO_TALK:
		staging.turn_to(person)
		person.face_toward(player.position)
		person.say(session.quick_line(person.id))


## A scene's line, choice or paper is up (true; PLAN 2.13 A): no walking, no
## click-to-move, no free camera, until it goes (false).
func hold_for_scene(on: bool) -> void:
	_scene_holds = on
	if on:
		_on_panel_opened()
	elif not busy():
		player.active = true
		rig.active = true
		rig.release()


## Whether the world takes no clicks or E now: a panel is open, or a scene holds the player.
func world_waits() -> bool:
	return ui.is_busy() or _scene_holds


func _add_player() -> void:
	player = Player.new(session.player.look)
	add_child(player)
	var spawn := find_marker(SPAWN)
	if spawn != null:
		var at := in_office(spawn)
		player.position = at.origin
		player.face(at.basis)
	player.interact_pressed.connect(func() -> void:
		if not world_waits():
			use(target_near(player.position)))
	player.phone_pressed.connect(func(app: String) -> void: ui.toggle_phone(app))
	player.escape_pressed.connect(func() -> void:
		player.stop()
		ui.escape())
	player.arrived.connect(pointer.on_arrived)


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
			staging.frame(near)
		elif not on and not ui.is_busy():
			rig.release())


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
## person under the cursor, or lights up the ring under it (OfficePointer).
func _unhandled_input(event: InputEvent) -> void:
	pointer.handle(event)


## The walk grid, baked from the office's collision on first use.
func nav() -> OfficeNav:
	if _nav == null:
		_nav = OfficeNav.bake(collision_faces(), floor_rect())
	return _nav


## Every collision triangle of the geometry, in the office's space.
func collision_faces() -> PackedVector3Array:
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


func _on_panel_opened() -> void:
	ui.let_ringing_go()   # taken up with something else: the call goes to voicemail
	player.active = false
	player.stop()
	rig.active = false


func _on_panels_closed() -> void:
	if ride != null:   # a talk in the cab, or the field step's place: the ride goes on
		ride.panels_closed()
		return
	people.release()
	people.refresh(session)
	if player.seated:   # after a call at the KCC's headset
		OfficeHeadset.wear(self, false)
	player.stand_up()
	player.active = true
	rig.active = true
	rig.release()
