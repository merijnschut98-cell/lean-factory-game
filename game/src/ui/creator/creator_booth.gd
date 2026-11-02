class_name CreatorBooth
extends Node3D
## The photo booth behind the creator's viewfinder and the badge photo (PLAN
## 2.7b; spec 2026-10-16-creator-and-minimap §1.2, §1.7): the player's model
## on a turntable in a neutral grey light, and a camera framed by the trait
## (head and shoulders, or from the knees up). Its own world: put it in a
## SubViewport with own_world_3d.

## The booth's grey (the photo's background, §1.7).
const BACKDROP := Color("#9aa0a6")
const FOV := 30.0
## Framing: the height (m) the view spans and how far its top edge sits above
## the Head bone (the base of the skull). Head and shoulders (a passport
## photo), or from the knees up (estimates, judged in the screenshots).
const HEAD_SPAN := 0.6
const HEAD_TOP := 0.27
const BODY_SPAN := 1.32
const BODY_TOP := 0.33
## The badge photo: tighter, the head filling most of the frame.
const PHOTO_SPAN := 0.46
const PHOTO_TOP := 0.24
## The face's middle above the Head bone (m) and its height, for the face square.
const FACE_UP := 0.09
const FACE_SIZE := 0.24
## The camera moves to a new framing in this long (s).
const FRAME_S := 0.3
## Turning with Z/C (rad/s, the game's own camera speed) and a drag (rad/px).
const TURN_SPEED := 1.8
const DRAG_TURN := 0.008
## After a turn the model eases back to the front, this long after (s).
const RETURN_AFTER := 2.0
const RETURN_RATE := 3.0
## The Head bone's height when a model has none (m).
const HEAD_FALLBACK := 1.62

var camera: Camera3D
## Turns the model (yaw 0: facing the camera).
var turntable: Node3D
var model: Node3D
var head_height := HEAD_FALLBACK
## Where the model stands across the view: 0 the middle, -0.34 left of it,
## so the creator's right column never covers it.
var shift := 0.0
## The framing: head and shoulders (true) or from the knees up.
var close_up := false
var _since_turn := INF
var _tween: Tween


func _init() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.84)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	# The light of creator_shot.gd's studio: key front left and high, a fill, a rim.
	for light: Array in [[Vector3(-35, -30, 0), 1.15, Color(1.0, 0.96, 0.9), true],
			[Vector3(-10, 40, 0), 0.55, Color(0.9, 0.95, 1.0), false], [Vector3(-25, 165, 0), 0.8, Color.WHITE, false]]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = light[0]
		sun.light_energy = light[1]
		sun.light_color = light[2]
		sun.shadow_enabled = light[3]
		add_child(sun)
	turntable = Node3D.new()
	add_child(turntable)
	camera = Camera3D.new()
	camera.fov = FOV
	add_child(camera)
	frame(false, true)


## Dress the model in `look` (CreatorLook), keeping the turn.
func wear(look: Dictionary) -> void:
	if model != null:
		turntable.remove_child(model)
		model.queue_free()
	model = CreatorLook.build(look)
	if model == null:
		return
	model.rotation = Vector3.ZERO  # the glb's front is +Z: towards the camera
	turntable.add_child(model)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	var head := skeleton.find_bone("Head") if skeleton != null else -1
	head_height = skeleton.get_bone_global_rest(head).origin.y if head >= 0 else HEAD_FALLBACK
	var animations := CharacterModel.animations(model)
	if animations != null and animations.has_animation("idle"):
		animations.play("idle")
	frame(close_up, true)


## Frame the head and shoulders (`close`) or from the knees up; `now` without
## the move.
func frame(close: bool, now := false) -> void:
	close_up = close
	_frame(HEAD_SPAN if close else BODY_SPAN, HEAD_TOP if close else BODY_TOP, now)


## The badge photo's framing (PortraitPhoto), straight from the front.
func frame_photo() -> void:
	_frame(PHOTO_SPAN, PHOTO_TOP, true)


func _frame(span: float, top: float, now: bool) -> void:
	var middle := head_height + top - span / 2.0
	var distance := span / 2.0 / tan(deg_to_rad(FOV / 2.0))
	var to := Vector3(0, middle, distance)
	var offset := -shift * distance * tan(deg_to_rad(FOV / 2.0)) * _aspect()
	if _tween != null:
		_tween.kill()
	if now or not is_inside_tree():
		camera.position = to
		camera.h_offset = offset
		return
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "position", to, FRAME_S)
	_tween.tween_property(camera, "h_offset", offset, FRAME_S)


## Turn the model by `radians` (Z/C, a drag); it eases back after a while.
func turn(radians: float) -> void:
	turntable.rotation.y = wrapf(turntable.rotation.y + radians, -PI, PI)
	_since_turn = 0.0


## The head's middle in the world, for the viewfinder's face square.
func head_point() -> Vector3:
	var face := Vector3(0, head_height + FACE_UP, 0)
	return turntable.global_transform * face if is_inside_tree() else face


func _process(delta: float) -> void:
	_since_turn += delta
	if _since_turn > RETURN_AFTER:
		turntable.rotation.y = lerp_angle(turntable.rotation.y, 0.0, 1.0 - exp(-RETURN_RATE * delta))


func _aspect() -> float:
	var viewport := get_viewport() if is_inside_tree() else null
	if viewport == null:
		return 16.0 / 9.0
	var size := viewport.get_visible_rect().size
	return size.x / size.y if size.y > 0 else 16.0 / 9.0
