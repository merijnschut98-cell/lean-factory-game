extends SceneTree
## Screenshots of the head office's floors (PLAN 2.1; needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/floor_shot.gd -- <view> <out.png> [frames]
## Views: model:<floor> (the floor's glb from above, ceiling cut away, every room in view) ·
## play:<floor> (the game on that floor: the player arrived by the lift, the HUD, zoomed out
## over the core) · map:<floor> (the player map on that floor, the floor switch on top) ·
## lift (the lift's floor choice, from the 1e) · door (a shut door's prompt on the begane
## grond).

const SCENE := "res://src/world/office/office.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <model:<floor>|play:<floor>|map:<floor>|lift|door> <out.png> [frames]")
		quit(2)
		return
	var view := args[0]
	var frames := int(args[2]) if args.size() > 2 else 30
	if view.begins_with("model:"):
		if not _model(view.trim_prefix("model:")):
			quit(1)
			return
	else:
		_play(view)
	for i in frames:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[1])
	if err != OK:
		printerr("cannot write ", args[1], ": ", error_string(err))
	quit(0 if err == OK else 1)


## The floor's model alone, lit like the game, seen from the south-east above.
func _model(floor_id: String) -> bool:
	var building := OfficeBuilding.load_from(Catalog.DATA_DIR)
	var path := building.model_path(floor_id)
	if not ResourceLoader.exists(path):
		printerr("no model for floor ", floor_id, ": ", path)
		return false
	var world := Node3D.new()
	root.add_child(world)
	var geometry: Node3D = (load(path) as PackedScene).instantiate()
	world.add_child(geometry)
	for id in Office.CUTAWAY:
		for n in geometry.find_children("*", "VisualInstance3D", true, false):
			if Office._loose(n.name).begins_with(Office._loose(id)):
				n.visible = false
	var env := WorldEnvironment.new()
	env.environment = load(Office.ENVIRONMENT)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.basis = Basis.looking_at(Office.SUN_DIRECTION)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 50
	world.add_child(cam)
	cam.position = Vector3(3.0, 30.0, 14.0)
	cam.look_at(Vector3(3.0, 0.0, -8.0))
	return true


## The game on a floor, in a given state.
func _play(view: String) -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	root.add_child(office)
	var parts := view.split(":")
	match parts[0]:
		"play", "map":
			office.floors.go_to(parts[1], "lift", true)
			office.rig.distance = CameraRig.MAX_DISTANCE
			office.rig.snap()
			if parts[0] == "map":
				office.ui.toggle_map()
		"lift":
			office.player.position = office.interactable("lift").position
			office.rig.snap()
			office.use(office.interactable("lift"))
		"door":
			office.floors.go_to("ground", "lift", true)
			var door: Interactable = office.interactable("door:contact_centre")
			office.player.position = door.position
			office.rig.snap()
