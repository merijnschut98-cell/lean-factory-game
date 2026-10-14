class_name Player
extends CharacterBody3D
## The first-person CI-lead: WASD to walk, the mouse to look, E to interact,
## J for the clue journal, M for the map, K for the codex, Esc to free (or catch) the mouse. While a panel
## is open the player stands still (`active` is false) and the keys only
## signal the office.

signal interact_pressed
signal journal_pressed
signal map_pressed
signal codex_pressed
signal escape_pressed

const EYE_HEIGHT := 1.65
## Walking pace in the office, m/s (a brisk walk; real is ~1.4).
const SPEED := 3.0
const MOUSE_SENSITIVITY := 0.0022
const MAX_PITCH := deg_to_rad(80.0)

var active := true
var camera: Camera3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _init() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = EYE_HEIGHT
	camera.fov = 72.0
	camera.near = 0.05
	add_child(camera)


## Face the way `basis` looks (its -Z), level.
func face(basis_to_match: Basis) -> void:
	var forward := -basis_to_match.z
	rotation.y = atan2(-forward.x, -forward.z)
	camera.rotation.x = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH)
	elif event is InputEventKey and event.pressed and not event.echo:
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
	var input := _walk_input() if active else Vector2.ZERO
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()


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
