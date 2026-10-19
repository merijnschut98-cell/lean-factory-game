class_name CameraRig
extends Node3D
## The Sims-like camera: raised over the player, following smoothly. Z/C or a
## right-mouse drag turn it round the player, the wheel zooms from a close
## "conversation" view to an overview of the floor. The ceiling is cut away
## (its meshes sit on a layer the camera does not draw) and the camera stays
## over the office floor, so no wall ever stands between it and the player.
## Near a wall the view leans into the room (the player stays in view, off
## centre) and, where the wanted spot would still lie outside, the camera
## climbs steeper instead of moving through the wall.
##
## Close by it looks lower, across the desks, so the gemba reads: stacks of
## dossiers, boards, screens. To look closer still it frames a workstation
## (`inspect`): while a place's panel is open, or while the right button is
## held still at a place; it glides back to the player when let go.

signal hold_inspect(on: bool)


const MIN_DISTANCE := 2.5
const MAX_DISTANCE := 18.0
const DEFAULT_DISTANCE := 10.0
## Each wheel notch zooms by this factor.
const ZOOM_STEP := 1.15
## The look-down angle close by (across the desks) and far out; between them
## it rises quickly, so the medium distance looks down at ~48°.
const CLOSE_PITCH := deg_to_rad(30.0)
const FAR_PITCH := deg_to_rad(56.0)
const MAX_PITCH := deg_to_rad(89.0)
## Framing a workstation: how far from the point looked at, and how steep.
const INSPECT_DISTANCE := 3.2
const INSPECT_PITCH := deg_to_rad(40.0)
## Framing a talk: over the player's shoulder, close and nearly level, on
## the other person's face.
const TALK_DISTANCE := 2.6
const TALK_PITCH := deg_to_rad(14.0)
## A scene's two-shot stands this far (m) from the point between the two,
## looking down this steeply, so a wall a couple of metres behind the player
## stays under the line of sight (estimates, tuned on the screenshots).
const SCENE_DISTANCE := 7.5
const SCENE_PITCH := deg_to_rad(62.0)
## Holding the right button this long (s) without dragging more than
## HOLD_SLOP pixels frames the place the player stands at.
const HOLD_SECONDS := 0.3
const HOLD_SLOP := 8.0
## Turning speed with Z/C (rad/s) and with a drag (rad per pixel).
const TURN_SPEED := 1.8
const DRAG_TURN := 0.006
const TURN_LEFT := KEY_Z
const TURN_RIGHT := KEY_C
## How fast the view catches up (1/s): with the player, a zoom, a framing.
const FOLLOW_RATE := 6.0
## The point looked at: the player's chest.
const FOCUS_HEIGHT := 1.0
## The camera keeps this far (m) inside the floor.
const MARGIN := 0.4
## Near a wall the point looked at stays this share of the distance inside
## the floor (well within the half-view, so the player stays on screen).
const LEAN := 0.3
## The render layer of what the camera cuts away (the ceiling).
const CUTAWAY_LAYER := 1 << 19

var target: Node3D
## The office floor (x, z) the camera stays over.
var bounds := Rect2()
## The player's view: facing as a node's rotation.y (0 looks north, -Z) and
## zoom. A framing overrides them for a while; they stay for the way back.
var yaw := 0.0
var distance := DEFAULT_DISTANCE
## The point looked at now (it glides towards the wanted one).
var focus := Vector3.ZERO
## False while a panel is open.
var active := true
var camera: Camera3D
var _turn := 0.0
## The framing: {at, yaw, shift} while inspecting, else empty.
var _inspect: Dictionary = {}
## What the camera shows now, gliding towards the wanted view.
var _shown_yaw := 0.0
var _shown_distance := DEFAULT_DISTANCE
var _shown_pitch := 0.0
var _shown_shift := 0.0
var _shown_lift := 0.0
## The right button: held, how far dragged (px), how long (s), framing yet.
var _right_held := false
var _right_drag := 0.0
var _right_time := 0.0
var _hold_framing := false


func _init() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.near = 0.1
	camera.far = 200.0
	camera.cull_mask = ~CUTAWAY_LAYER & 0xFFFFF
	camera.current = true
	add_child(camera)


func zoom(steps: float) -> void:
	distance = clampf(distance * pow(ZOOM_STEP, steps), MIN_DISTANCE, MAX_DISTANCE)


## The look-down angle for the player's zoom.
func pitch() -> float:
	return lerpf(CLOSE_PITCH, FAR_PITCH, sqrt(inverse_lerp(MIN_DISTANCE, MAX_DISTANCE, distance)))


## Frame a workstation: look at `at` (office space) facing `look_yaw`, the
## station `shift` of the screen's width left of the middle (a panel docked
## at the right covers the rest).
func inspect(at: Vector3, look_yaw: float, shift := 0.0) -> void:
	_inspect = {"at": at, "yaw": look_yaw, "shift": shift}


## Frame a talk: look at `at` (the person's face) facing `look_yaw` from over
## the player's shoulder, the face `shift` of the screen's width off the
## middle and `lift` of its height above it (a panel across the bottom
## covers the rest).
func converse(at: Vector3, look_yaw: float, shift: float, lift: float) -> void:
	_inspect = {"at": at, "yaw": look_yaw, "shift": shift, "lift": lift,
		"distance": TALK_DISTANCE, "pitch": TALK_PITCH}


## Frame a scene's speaker and the player together (PLAN 2.13 A: you always
## see yourself): look at `at` (between the two) facing `look_yaw`, from
## high enough that the walls stay below the camera; `lift` of the screen's
## height above the middle.
func two_shot(at: Vector3, look_yaw: float, lift: float) -> void:
	_inspect = {"at": at, "yaw": look_yaw, "shift": 0.0, "lift": lift,
		"distance": SCENE_DISTANCE, "pitch": SCENE_PITCH}


## Back to the player.
func release() -> void:
	_inspect = {}


func inspecting() -> bool:
	return not _inspect.is_empty()


## Jump to the wanted view (at the start, or after a teleport).
func snap() -> void:
	focus = _goal()
	_shown_yaw = _wanted_yaw()
	_shown_distance = _wanted_distance()
	_shown_pitch = _wanted_pitch()
	_shown_shift = _wanted_shift()
	_shown_lift = _wanted_lift()
	_place()


func update(delta: float) -> void:
	yaw = wrapf(yaw + _turn * TURN_SPEED * delta, -PI, PI)
	if _right_held and not _hold_framing and _right_drag <= HOLD_SLOP:
		_right_time += delta
		if _right_time >= HOLD_SECONDS:
			_hold_framing = true
			hold_inspect.emit(true)
	var glide := 1.0 - exp(-FOLLOW_RATE * delta)
	focus = focus.lerp(_goal(), glide)
	_shown_yaw = lerp_angle(_shown_yaw, _wanted_yaw(), glide)
	_shown_distance = lerpf(_shown_distance, _wanted_distance(), glide)
	_shown_pitch = lerpf(_shown_pitch, _wanted_pitch(), glide)
	_shown_shift = lerpf(_shown_shift, _wanted_shift(), glide)
	_shown_lift = lerpf(_shown_lift, _wanted_lift(), glide)
	_place()


func _process(delta: float) -> void:
	update(delta)


func _wanted_yaw() -> float:
	return _inspect["yaw"] if inspecting() else yaw


func _wanted_distance() -> float:
	return _inspect.get("distance", INSPECT_DISTANCE) if inspecting() else distance


func _wanted_shift() -> float:
	return _inspect["shift"] if inspecting() else 0.0


func _wanted_pitch() -> float:
	return _inspect.get("pitch", INSPECT_PITCH) if inspecting() else pitch()


func _wanted_lift() -> float:
	return _inspect.get("lift", 0.0)


## The point to look at: the framed station, else the player's chest,
## leaning into the room near a wall.
func _goal() -> Vector3:
	if inspecting():
		return _inspect["at"]
	var at := target.position if target != null else Vector3.ZERO
	if bounds.has_area():
		var inner := bounds.grow(-minf(distance * LEAN, minf(bounds.size.x, bounds.size.y) / 2.0 - 0.01))
		at.x = clampf(at.x, inner.position.x, inner.end.x)
		at.z = clampf(at.z, inner.position.y, inner.end.y)
	return at + Vector3.UP * FOCUS_HEIGHT


func _place() -> void:
	var back := Vector2(sin(_shown_yaw), cos(_shown_yaw))
	var d := _shown_distance
	var p := _shown_pitch
	var room := _room_behind(Vector2(focus.x, focus.z), back)
	if d * cos(p) > room:
		p = minf(acos(room / d), MAX_PITCH)
	var ground := Vector2(focus.x, focus.z) + back * d * cos(p)
	var at := Vector3(ground.x, focus.y + d * sin(p), ground.y)
	camera.transform = Transform3D(Basis.looking_at(focus - at), at)
	# Sideways and down, not turned: the focus moves off the middle.
	var half_height := d * tan(deg_to_rad(camera.fov) / 2.0)
	camera.h_offset = _shown_shift * 2.0 * half_height * _aspect()
	# Down, so the focus rises on screen by the lift.
	camera.v_offset = -_shown_lift * 2.0 * half_height


## The screen's width over its height (16:9, the project's, outside a window).
func _aspect() -> float:
	if not is_inside_tree():
		return 16.0 / 9.0
	var screen := get_viewport().get_visible_rect().size
	return screen.x / screen.y


## How far (m) the camera may go from `from` along `back` and stay over the floor.
func _room_behind(from: Vector2, back: Vector2) -> float:
	if not bounds.has_area():
		return INF
	var inner := bounds.grow(-MARGIN)
	var room := INF
	for axis in 2:
		if back[axis] > 0.0001:
			room = minf(room, (inner.end[axis] - from[axis]) / back[axis])
		elif back[axis] < -0.0001:
			room = minf(room, (inner.position[axis] - from[axis]) / back[axis])
	return maxf(room, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_end_hold()
	if not active:
		_turn = 0.0
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom(1)
			MOUSE_BUTTON_RIGHT:
				_right_held = true
				_right_drag = 0.0
				_right_time = 0.0
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw = wrapf(yaw - event.relative.x * DRAG_TURN, -PI, PI)
		_right_drag += event.relative.length()
		if _right_drag > HOLD_SLOP and _hold_framing:
			_end_hold()
	elif event is InputEventKey and not event.echo and event.physical_keycode in [TURN_LEFT, TURN_RIGHT]:
		var sign := 1.0 if event.physical_keycode == TURN_LEFT else -1.0
		if event.pressed:
			_turn = sign
		elif _turn == sign:
			_turn = 0.0


func _end_hold() -> void:
	_right_held = false
	if _hold_framing:
		_hold_framing = false
		hold_inspect.emit(false)
