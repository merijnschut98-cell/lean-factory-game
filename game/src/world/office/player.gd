class_name Player
extends CharacterBody3D
## The CI-lead, seen from above (third person): WASD walks relative to the
## camera, a route from a click is walked corner by corner, E interacts, J
## opens the clue journal, M the map, K the codex, Esc closes a panel. While
## a panel is open the player stands still (`active` is false) and the keys
## only signal the office. The body turns to face where it walks; the avatar
## (a stand-in until a character model replaces it) turns with it.

signal interact_pressed
signal journal_pressed
signal map_pressed
signal codex_pressed
signal escape_pressed
## The end of a route was reached.
signal arrived

## The avatar: a soft shadow and a stand-in body (capsule and head).
const AVATAR := "res://src/world/office/player_avatar.tscn"
## The character model that replaces the stand-in when it is there: a glTF
## facing +Z, feet at 0, with "idle" and "walk" animations.
const CHARACTER := "res://assets/characters/sample_player.glb"
## Walking pace in the office, m/s (a brisk walk; real is ~1.4).
const SPEED := 3.0
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
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _init() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	avatar = (load(AVATAR) as PackedScene).instantiate()
	add_child(avatar)
	var model: Node3D = (load(CHARACTER) as PackedScene).instantiate() if ResourceLoader.exists(CHARACTER) else null
	if model != null:
		avatar.get_node("StandIn").free()
		model.rotation.y = PI
		avatar.add_child(model)
		_animations = model.find_children("*", "AnimationPlayer", true, false).pop_front()
	_animate(false)


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


## The floor direction of WASD `input` (x right, y back) seen from `yaw`.
static func walk_direction(input: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)).normalized()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				interact_pressed.emit()
			KEY_J:
				journal_pressed.emit()
			KEY_M:
				map_pressed.emit()
			KEY_K:
				codex_pressed.emit()
			KEY_ESCAPE:
				escape_pressed.emit()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	step(delta, _walk_input() if active else Vector2.ZERO)
	move_and_slide()


## One frame's steering: WASD (cancels a route), else the next corner of the
## route. Sets the horizontal velocity and turns the body; the physics step
## (or a test) moves it.
func step(delta: float, input := Vector2.ZERO) -> void:
	var direction := Vector3.ZERO
	if not active:
		route.clear()
	elif input != Vector2.ZERO:
		route.clear()
		direction = walk_direction(input, view_yaw)
	elif not route.is_empty():
		direction = _towards_route(delta)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if direction != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-TURN_RATE * delta))
	_animate(direction != Vector3.ZERO)


## The direction to the next corner, dropping corners reached; on the last,
## a stop exactly there and `arrived`.
func _towards_route(delta: float) -> Vector3:
	var to := route[0] - position
	to.y = 0
	while to.length() <= maxf(ARRIVE, SPEED * delta):
		route.remove_at(0)
		if route.is_empty():
			position.x += to.x
			position.z += to.z
			arrived.emit()
			return Vector3.ZERO
		to = route[0] - position
		to.y = 0
	return to.normalized()


func _animate(moving: bool) -> void:
	if _animations == null:
		return
	var wanted := "walk" if moving else "idle"
	if _animations.has_animation(wanted) and _animations.current_animation != wanted:
		_animations.play(wanted, 0.2)


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
