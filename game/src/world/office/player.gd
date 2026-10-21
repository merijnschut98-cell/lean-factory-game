class_name Player
extends CharacterBody3D
## The CI-lead, seen from above (third person): WASD walks relative to the
## camera, a route from a click is walked corner by corner, E interacts, Tab
## (the remappable action Phone.ACTION) raises the phone, J, M and K raise it on
## Notities, Kaart and Begrippen, Esc closes a panel. While
## a panel is open the player stands still (`active` is false) and the keys
## only signal the office. Shift jogs (keys or a clicked route). The body turns to face where it walks; the avatar
## (a stand-in until a character model replaces it) turns with it.

signal interact_pressed
## The phone key (`app` Phone.HOME) or J, M, K (`app` the app they open).
signal phone_pressed(app: String)
signal escape_pressed
## The end of a route was reached.
signal arrived

## The avatar: a soft shadow and a stand-in body (capsule and head).
const AVATAR := "res://src/world/office/player_avatar.tscn"
## Walking pace in the office, m/s: a brisk walk (real is ~1.4). The pack's
## walk measures 1.55 m/s for the player (CharacterModel.walk_pace), so it
## plays at ×1.3 here, as the first models did: brisk, not hurried. The
## animation always plays at speed / pace, so the feet do not slide.
const SPEED := 2.0
## Jogging pace with Shift, m/s (Merijn, 2026-10-16): the jog plays at
## RUN_SPEED / CharacterModel.jog_pace (≈ ×0.95).
const RUN_SPEED := 4.5
## How close (m) to a route's corner counts as there.
const ARRIVE := 0.12
## How fast the body turns to its walking direction (1/s).
const TURN_RATE := 12.0

var active := true
## The camera's yaw, so W walks away from the camera.
var view_yaw := 0.0
var avatar: Node3D
## The corners still to walk to (office space).
var route := PackedVector3Array()
var _animations: AnimationPlayer
## The model, for its measured paces (null for the stand-in).
var _model: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


## `look`: the player's look from the character creator (PLAN 2.7b; trait id
## -> option id, CreatorLook); {} is the default look.
func _init(look: Dictionary = {}) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	avatar = (load(AVATAR) as PackedScene).instantiate()
	add_child(avatar)
	wear(look)


## Put on `look` (CreatorLook): the made model replaces the stand-in, or the
## one worn before (the pause menu's "Uiterlijk"). Without built models the
## stand-in stays.
func wear(look: Dictionary) -> void:
	var model := CreatorLook.build(look)
	if model == null:
		return
	for old: Node in [avatar.get_node_or_null("StandIn"), _model]:
		if old != null:
			avatar.remove_child(old)
			old.free()
	avatar.add_child(model)
	_animations = CharacterModel.animations(model)
	_model = model
	_animate("idle")


## Face the way `basis` looks (its -Z), level.
func face(basis_to_match: Basis) -> void:
	var forward := -basis_to_match.z
	rotation.y = atan2(-forward.x, -forward.z)


func walk(corners: PackedVector3Array) -> void:
	route = corners


func stop() -> void:
	route.clear()


func walking() -> bool:
	return not route.is_empty()


## Seated at `at` (office space; the van ride's passenger seat): no gravity, no walking,
## the sit clip, until stand().
func sit(at: Transform3D) -> void:
	stop()
	set_physics_process(false)
	velocity = Vector3.ZERO
	position = at.origin
	face(at.basis)
	if _animations != null and _animations.has_animation("sit"):
		_animations.play("sit", 0.2)
		_animations.speed_scale = 1.0


## Up again (stood where the caller puts them): gravity and walking back.
func stand() -> void:
	set_physics_process(true)
	velocity = Vector3.ZERO
	_animate("idle")


func seated() -> bool:
	return not is_physics_processing()


## The floor direction of WASD `input` (x right, y back) seen from `yaw`.
static func walk_direction(input: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)).normalized()


## The phone app a key opens (J Notities, M Kaart, K Begrippen); "" for none.
static func app_for_key(key: Key) -> String:
	match key:
		KEY_J:
			return Phone.NOTES
		KEY_M:
			return Phone.MAP
		KEY_K:
			return Phone.CODEX
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action(Phone.ACTION):
		phone_pressed.emit(Phone.HOME)
		return
	var app := app_for_key(event.physical_keycode)
	if not app.is_empty():
		phone_pressed.emit(app)
		return
	match event.physical_keycode:
		KEY_E:
			interact_pressed.emit()
		KEY_ESCAPE:
			escape_pressed.emit()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	step(delta, _walk_input() if active else Vector2.ZERO, Input.is_physical_key_pressed(KEY_SHIFT))
	move_and_slide()


## One frame's steering: WASD (cancels a route), else the next corner of the
## route, at a jog while `running`. Sets the horizontal velocity and turns the
## body; the physics step (or a test) moves it.
func step(delta: float, input := Vector2.ZERO, running := false) -> void:
	var speed := RUN_SPEED if running else SPEED
	var direction := Vector3.ZERO
	if not active:
		route.clear()
	elif input != Vector2.ZERO:
		route.clear()
		direction = walk_direction(input, view_yaw)
	elif not route.is_empty():
		direction = _towards_route(speed * delta)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-TURN_RATE * delta))
	_animate(("jog" if running else "walk") if direction != Vector3.ZERO else "idle")


## The direction to the next corner, dropping corners reached; on the last,
## a stop exactly there and `arrived`.
func _towards_route(stride: float) -> Vector3:
	var to := route[0] - position
	to.y = 0
	while to.length() <= maxf(ARRIVE, stride):
		route.remove_at(0)
		if route.is_empty():
			position.x += to.x
			position.z += to.z
			arrived.emit()
			return Vector3.ZERO
		to = route[0] - position
		to.y = 0
	return to.normalized()


## Play idle, walk or jog; a stride plays at the speed that matches its own
## measured pace, so the feet stay on the floor.
func _animate(gait: String) -> void:
	if _animations == null or not _animations.has_animation(gait):
		return
	if _animations.current_animation != gait:
		_animations.play(gait, 0.2)
	match gait:
		"walk":
			_animations.speed_scale = SPEED / CharacterModel.walk_pace(_model)
		"jog":
			_animations.speed_scale = RUN_SPEED / CharacterModel.jog_pace(_model)
		_:
			_animations.speed_scale = 1.0


static func _walk_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1
	return v
