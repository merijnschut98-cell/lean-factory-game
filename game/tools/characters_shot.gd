extends SceneTree
## A screenshot of the sample characters in the office, seen from the game's
## own camera (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/characters_shot.gd -- <out.png> [frames]
## The player (sample_player.glb, loaded by Player itself) stands in the aisle
## by Werkvoorbereiding; the coach talks to her, a monteur walks past behind
## him. Prints each model's animations, so a missing idle or walk shows.

const SCENE := "res://src/world/office/office.tscn"
const DESIGN := "place:connections.design"
const COACH := "res://assets/characters/sample_coach.glb"
const MONTEUR := "res://assets/characters/sample_monteur.glb"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -- <out.png> [frames]")
		quit(2)
		return
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	root.add_child(office)
	# the player a step back from the desk, turned to the aisle
	var desk := office.interactable(DESIGN)
	var player := office.player
	player.position = desk.position + desk.basis.z * 1.1
	player.face(desk.basis.rotated(Vector3.UP, PI))
	var ahead := -player.basis.z
	var right := player.basis.x
	_report("player", player)
	var coach := _person(office, COACH, player.position + ahead * 1.25 + right * 0.15, player.position)
	var crossing := player.position + ahead * 2.2 - right * 1.8
	var monteur := _person(office, MONTEUR, crossing, crossing + right)
	if coach == null or monteur == null:
		quit(1)
		return
	_pose(coach, "idle", 1.3)
	_pose(monteur, "walk", 0.35)
	office.rig.yaw = player.rotation.y + deg_to_rad(35)   # over the player's shoulder
	office.rig.distance = 5.2
	office.rig.snap()
	var frames := int(args[1]) if args.size() > 1 else 20
	for i in frames:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[0])
	if err != OK:
		printerr("cannot write ", args[0], ": ", error_string(err))
	quit(0 if err == OK else 1)


## A character model standing at `at` facing `look_at` (models face +Z).
func _person(office: Office, path: String, at: Vector3, look_at: Vector3) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		printerr("cannot load ", path)
		return null
	var holder := Node3D.new()
	office.add_child(holder)
	holder.position = Vector3(at.x, office.player.position.y, at.z)
	var to := look_at - at
	holder.rotation.y = atan2(to.x, to.z)
	var model := packed.instantiate()
	holder.add_child(model)
	_report(path.get_file(), model)
	return model


## Hold `model` still at `at` seconds into `animation`.
func _pose(model: Node, animation: String, at: float) -> void:
	var player := _animations(model)
	if player != null and player.has_animation(animation):
		player.play(animation)
		player.seek(at, true)
		player.pause()
	else:
		printerr("no ", animation, " animation in ", model.name)


static func _animations(node: Node) -> AnimationPlayer:
	return node.find_children("*", "AnimationPlayer", true, false).pop_front()


func _report(label: String, node: Node) -> void:
	var player := _animations(node)
	if player == null:
		printerr(label, ": no AnimationPlayer")
		return
	var names := []
	for a in player.get_animation_list():
		names.append("%s (%.2f s, loop %d)" % [a, player.get_animation(a).length, player.get_animation(a).loop_mode])
	print(label, ": ", ", ".join(names))
