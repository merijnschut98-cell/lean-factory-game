extends SceneTree
## Render a scene to PNG for visual review (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/screenshot.gd -- res://src/boot/boot.tscn /tmp/out.png [frames]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <scene.tscn> <out.png> [frames]")
		quit(2)
		return
	var packed: PackedScene = load(args[0])
	if packed == null:
		printerr("cannot load scene ", args[0])
		quit(1)
		return
	root.add_child(packed.instantiate())
	var frames := int(args[2]) if args.size() > 2 else 10
	for i in frames:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[1])
	if err != OK:
		printerr("cannot write ", args[1], ": ", error_string(err))
	quit(0 if err == OK else 1)
