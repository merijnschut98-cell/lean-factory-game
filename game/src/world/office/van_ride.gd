class_name VanRide
extends Node3D
## The van ride (PLAN 2.15 S2-Y; design 2026-10-21 §1.7, §2.3): a scene, not a driving game.
## You sit beside the monteur in the cab (van_cab.glb) while the edge of town goes by
## outside: a short canned loop of terraced houses with solar panels, a trafohuisje, a bike
## lane, lamp posts, trees, a ditch and fields, wind turbines far off, drifting past at 50
## km/h. The engine hums (Soundscape "van_cab"). When the mission has a talk with them still
## to have, it opens on the way and runs in the cab as a standing talk (TalkView unchanged:
## the cab only frames it, frame_talk); the drive waits while you talk. Then a fade, and you
## stand at the side's field step (a place on the yard until the town exists) with its place
## open; close it and a fade brings you back to the van.
##
## Respect the player's time: DRIVE_SECONDS of real time, no game time passes (walking the
## yard costs none either), and holding Spatie about a second skips to the arrival, as in
## the scenes. The cab stands far off the floor (ORIGIN), so nothing of the yard shows.
## A child of the Office (Office.ride while it lasts); step() runs it (from _process).

const CAB := "res://assets/office/van_cab.glb"
## Where the cab stands while you ride (office space): far from every floor.
const ORIGIN := Vector3(2000, 0, 0)
## The drive in real seconds (the brief: 20–40 s), when the talk opens, and the least drive
## left once a talk is over (the van arrives after the talk, not during its last line).
const DRIVE_SECONDS := 26.0
const TALK_AFTER := 3.0
const AFTER_TALK := 5.0
## Each fade, to black and back (s).
const FADE_SECONDS := 0.6
## Through the edge of town at 50 km/h (m/s).
const SPEED := 13.9
## The scenery loop (m along the road): a thing that passes BEHIND the cab comes round again
## LOOP metres ahead, too far to see it appear.
const LOOP := 300.0
const BEHIND := 40.0
## The cab's camera framings, in the cab's space (it faces -Z; the driver sits left):
## [eye, look at, field of view]. DRIVE: from behind and between the two of you, the
## windscreen and the passenger window with the town going by; TWO_SHOT: from the
## dashboard, the two of you; FACE: the driver's face from the passenger's side.
const DRIVE := "drive"
const TWO_SHOT := "two_shot"
const FACE := "face"
const SHOTS := {
	DRIVE: [Vector3(0.05, 1.34, 0.78), Vector3(0.25, 1.06, -2.0), 70.0],
	TWO_SHOT: [Vector3(0.0, 1.26, -0.86), Vector3(0.0, 1.08, 0.35), 64.0],
	FACE: [Vector3(0.32, 1.24, -0.42), Vector3(-0.45, 1.2, 0.28), 50.0],
}
## The seats when the cab model is missing (the stand-in).
const SEATS := {"driver": Vector3(-0.45, 0, 0.25), "passenger": Vector3(0.45, 0, 0.25)}

enum Stage {DRIVING, LEAVING, THERE, RETURNING, OVER}

var office: Office
## {mission, with, to} (OfficeBuilding.rides).
var ride: Dictionary
var monteur: OfficePerson
var camera: Camera3D
## Real seconds of drive left (it waits while a talk or a panel is open).
var seconds_left := DRIVE_SECONDS
var stage := Stage.DRIVING
var _cab: Node3D
## The scenery that drifts past (VanRideTown), and the turbines' rotors.
var _movers: Array[Node3D] = []
var _blades: Array[Node3D] = []
var _talk_tried := false
var _driven := 0.0
## Seconds Spatie has been held (-1: not held).
var _held := -1.0
var _black: ColorRect
var _hint: Label
var _alpha := 1.0
var _alpha_goal := 0.0
var _engine: AudioStreamPlayer
var _shot := DRIVE


## Ride along with `driver` (on the yard) on `of_ride`: you sit beside them and the drive starts.
static func begin(of_office: Office, of_ride: Dictionary, driver: OfficePerson) -> VanRide:
	var r := VanRide.new()
	r.name = "VanRide"
	r.office = of_office
	r.ride = of_ride
	r.monteur = driver
	r.position = ORIGIN
	of_office.add_child(r)
	r._build()
	r._board()
	return r


## A seat in the cab ("driver", "passenger") in the office's space, facing the windscreen.
func seat(who: String) -> Transform3D:
	var marker := Office._find_marker(_cab, "seat:" + who, Office._loose("seat:" + who)) if _cab != null else null
	if marker != null:
		return office.in_office(marker)
	return Transform3D(Basis.IDENTITY, position + SEATS[who])


func arrived() -> bool:
	return stage >= Stage.THERE


func over() -> bool:
	return stage == Stage.OVER


## The cab's framing now (DRIVE, TWO_SHOT, FACE).
func frame_shot() -> String:
	return _shot


## The scenery drifted `seconds` on: whether it moved.
func scenery_moves(seconds: float) -> bool:
	if _movers.is_empty():
		return false
	var before := _movers[0].position
	_drift(seconds)
	return _movers[0].position != before


## Frame the talk's phase in the cab (Office.stage_talk): their face while they speak, the
## two of you while you choose.
func frame_talk(phase: String) -> void:
	_frame(FACE if phase == TalkView.SPEAK else TWO_SHOT)


## Spatie down (true) or up: held for SceneLines.HOLD_SKIP_S while driving, the drive ends.
func hold_space(on: bool) -> void:
	_held = 0.0 if on and stage == Stage.DRIVING else -1.0


## A panel closed (Office._on_panels_closed): after a talk the drive goes on, after the
## field step's place the ride back.
func panels_closed() -> void:
	match stage:
		Stage.DRIVING:
			_seat_everyone()
		Stage.THERE:
			stage = Stage.RETURNING
			_alpha_goal = 1.0


## One frame of the ride.
func step(delta: float) -> void:
	_drift(delta)
	_fade(delta)
	match stage:
		Stage.DRIVING:
			_drive(delta)
		Stage.LEAVING:
			if _alpha >= 1.0:
				_arrive()
		Stage.RETURNING:
			if _alpha >= 1.0:
				_back()
		Stage.OVER:
			if _alpha <= 0.0:
				_end()


func _process(delta: float) -> void:
	step(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.physical_keycode == KEY_SPACE and not key.echo:
		hold_space(key.pressed)
		get_viewport().set_input_as_handled()


# ── The drive ───────────────────────────────────────────────────────────────

func _drive(delta: float) -> void:
	_hint.visible = not office.ui.is_busy()
	if office.ui.is_busy():   # a talk (or the phone): the van waits for you
		return
	_driven += delta
	if not _talk_tried and _driven >= TALK_AFTER:
		_talk_tried = true
		if _open_talk():
			seconds_left = maxf(seconds_left, AFTER_TALK)
			return
	seconds_left = maxf(0.0, seconds_left - delta)
	if _held >= 0.0:
		_held += delta
		if _held >= SceneLines.HOLD_SKIP_S:
			seconds_left = 0.0
	if seconds_left <= 0.0:
		stage = Stage.LEAVING
		_alpha_goal = 1.0
		_hint.visible = false


## The mission's talk with the monteur, when it is still to have: it opens in the cab.
func _open_talk() -> bool:
	var s := office.session
	var mission: MissionDef = null
	for m in s.active_missions():
		if m.id == ride["mission"]:
			mission = m
	if mission == null:
		return false
	var dialog := s.missions.pending_talk(mission)
	var d: DialogDef = s.people.dialogs.get(dialog) if not dialog.is_empty() else null
	if d == null or d.person != monteur.id:
		return false
	return office.ui.open_talk(monteur.id, TalkView.STANDING).is_empty()


# ── Getting in and out ──────────────────────────────────────────────────────

func _board() -> void:
	office.ui.close_panels()
	office.hold_for_scene(true)
	office.people.hold(monteur)
	_seat_everyone()
	if office.sound != null:
		office.sound.play("van_start", -6.0)
		_engine = office.sound.loop_under(self, "van_cab", -8.0)
	_alpha = 1.0
	_alpha_goal = 0.0


## You beside the monteur, both seated, the cab's camera on the drive.
func _seat_everyone() -> void:
	office.people.hold(monteur)
	var wheel := seat("driver")
	monteur.settle({"at": wheel.origin, "face": -wheel.basis.z, "pose": "sit"})
	monteur.end_talk()   # after a talk: hands on the wheel again, eyes on the road
	monteur.hold()
	monteur.visible = true
	office.player.sit(seat("passenger"))
	office.hold_for_scene(true)
	office.ui.hud.show_overlay(false)   # no walking keys in the cab
	office.rig.active = false
	camera.current = true
	_frame(DRIVE)


## The field step: you stand at its place on the yard with the place open; the monteur goes
## back to their day; the ride is remembered (the monteur waits no longer).
func _arrive() -> void:
	stage = Stage.THERE
	_alpha_goal = 0.0
	if _engine != null:
		_engine.queue_free()
		_engine = null
	office.session.missions.facts.add(OfficeYard.rode(ride["mission"]))
	_stand_at("place:" + str(ride["to"]))
	office.people.release()
	office.people.refresh(office.session)
	if office.yard != null:
		office.yard.poll()
	office.interact(office.interactable("place:" + str(ride["to"])))


## Back at the van's passenger door; the world is yours again.
func _back() -> void:
	stage = Stage.OVER
	_alpha_goal = 0.0
	if office.ride == self:
		office.ride = null
	_stand_at("ride:van%d" % monteur.van)
	office.hold_for_scene(false)
	office.ui.hud.show_overlay(true)
	office.rig.release()


## The player stands at marker `id` of the yard (as it faces), the world's camera behind them.
func _stand_at(id: String) -> void:
	var markers := office.floors.markers()
	var player := office.player
	player.stand()
	if markers.has(id):
		var t := office.in_office(markers[id])
		player.position = t.origin
		player.face(t.basis)
		office.rig.yaw = player.rotation.y
	office.rig.camera.current = true
	office.rig.snap()


func _end() -> void:
	office.remove_child(self)
	queue_free()


# ── The cab, the town, the camera, the fade ─────────────────────────────────

func _build() -> void:
	_cab = (load(CAB) as PackedScene).instantiate() if ResourceLoader.exists(CAB) else _stand_in_cab()
	add_child(_cab)
	camera = Camera3D.new()
	camera.near = 0.05
	add_child(camera)
	add_child(VanRideTown.build(_movers, _blades))
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_black)
	_hint = UiPanel.label(tr(SceneLines.SKIP_HINT), 15, Color(1, 1, 1, 0.6))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(_hint)


func _frame(shot: String) -> void:
	_shot = shot
	var s: Array = SHOTS[shot]
	camera.fov = s[2]
	camera.transform = Transform3D(Basis.looking_at(s[1] - s[0], Vector3.UP), s[0])


## The town drifts back past the cab, round the loop; the turbines turn.
func _drift(delta: float) -> void:
	for m in _movers:
		m.position.z += SPEED * delta
		if m.position.z > BEHIND:
			m.position.z -= LOOP
	for b in _blades:
		b.rotate_z(delta * 1.4)


func _fade(delta: float) -> void:
	_alpha = move_toward(_alpha, _alpha_goal, delta / FADE_SECONDS)
	_black.modulate.a = _alpha
	_black.visible = _alpha > 0.0


## A box for the cab when its model is not built (a stand-in, never shipped).
static func _stand_in_cab() -> Node3D:
	var root := Node3D.new()
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.9, 0.05, 1.8)
	floor_mesh.mesh = box
	root.add_child(floor_mesh)
	return root
