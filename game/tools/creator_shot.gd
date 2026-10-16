extends SceneTree
## Contact sheets of the characters in a plain studio (no office): grey backdrop, a soft key
## light like the creator's photo booth (first-five-minutes B1), an orthographic camera, a
## label under each person. Needs a display (e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/creator_shot.gd -- <out.png> <sheet> [ids, a,b,c]
## Sheets:
##   cast [ids]: the cast (or `ids`) full length, front and in profile, idle (1.3c bodies).
##   trait:<trait>: every option of a creator trait on both bodies, head and shoulders, front
##     and three-quarter (the closest view the game has: the badge photo).
##   outfits: every outfit on both bodies, full length.
##   poses:<m|f>: every outfit on one body in each animation (idle, walk, jog, sit, talk).
##   poses [ids]: the cast (or `ids`) in each animation.
##   parts:<id> <part,part+part,...>: head close-ups of model `id` wearing each part (or parts
##     joined by +), front, three-quarter, side and back.

const POSES: Array[String] = ["idle", "walk", "jog", "sit", "talk"]
const BACKDROP := Color(0.56, 0.58, 0.61)

var _studio: Node3D
var _camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <out.png> <cast|trait:<trait>|outfits|poses:<m|f>> [ids]")
		quit(2)
		return
	_build_studio()
	var sheet := args[1]
	var ok := true
	if sheet == "cast":
		ok = _cast_sheet(args[2].split(",") if args.size() > 2 else PackedStringArray())
	elif sheet.begins_with("trait:"):
		ok = _trait_sheet(sheet.trim_prefix("trait:"))
	elif sheet == "outfits":
		ok = _outfit_sheet()
	elif sheet.begins_with("poses:"):
		ok = _creator_poses(sheet.trim_prefix("poses:"))
	elif sheet == "poses":
		var ids := args[2].split(",") if args.size() > 2 else PackedStringArray(["player", "joost"])
		var models: Array[Node3D] = []
		for id in ids:
			models.append(CharacterModel.instantiate(id))
		ok = _pose_sheet(models, ids)
	elif sheet.begins_with("parts:"):
		ok = _parts_sheet(sheet.trim_prefix("parts:"), args[2].split(",") if args.size() > 2 else PackedStringArray())
	else:
		printerr("unknown sheet ", sheet)
		ok = false
	if not ok:
		quit(1)
		return
	for i in 12:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[0])
	if err != OK:
		printerr("cannot write ", args[0], ": ", error_string(err))
	quit(0 if err == OK else 1)


func _build_studio() -> void:
	_studio = Node3D.new()
	root.add_child(_studio)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.84)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world := WorldEnvironment.new()
	world.environment = env
	_studio.add_child(world)
	_light(Vector3(-35, -30, 0), 1.15, Color(1.0, 0.96, 0.9), true)    # key, from the front left, high
	_light(Vector3(-10, 40, 0), 0.55, Color(0.9, 0.95, 1.0), false)   # fill, front right
	_light(Vector3(-25, 165, 0), 0.8, Color(1, 1, 1), false)          # rim, from behind
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_studio.add_child(_camera)


func _light(degrees: Vector3, energy: float, color: Color, shadow: bool) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = degrees
	light.light_energy = energy
	light.light_color = color
	light.shadow_enabled = shadow
	_studio.add_child(light)


## Frame the box from `lo` to `hi` (x, y in the studio's front view) with the camera on +Z.
func _frame(lo: Vector2, hi: Vector2) -> void:
	var size := root.get_visible_rect().size
	var aspect := size.x / size.y
	var w := hi.x - lo.x
	var h := hi.y - lo.y
	_camera.size = maxf(h, w / aspect) * 1.04
	_camera.position = Vector3((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, 10)
	for label: Label3D in _studio.find_children("*", "Label3D", false, false):
		label.pixel_size = _camera.size / 1600.0


## A person at `at` turned `yaw` degrees from facing the camera, held at `seconds` into
## `animation`, with `label` under their feet (or under the chin for a head sheet).
func _place(model: Node3D, at: Vector3, yaw: float, animation: String, seconds: float, label: String, label_y: float) -> void:
	var holder := Node3D.new()
	_studio.add_child(holder)
	holder.position = at
	holder.rotation_degrees.y = yaw
	model.rotation = Vector3.ZERO   # the glb's front is +Z: towards the camera
	holder.add_child(model)
	var player := CharacterModel.animations(model)
	if player != null and player.has_animation(animation):
		player.play(animation)
		player.seek(seconds, true)
		player.pause()
	if not label.is_empty():
		var text := Label3D.new()
		text.text = label
		text.modulate = Color(0.08, 0.08, 0.1)
		text.outline_size = 0
		text.position = Vector3(at.x, label_y, at.z + 0.5)
		_studio.add_child(text)


func _cast_sheet(ids: PackedStringArray) -> bool:
	var list: Array = Array(ids) if not ids.is_empty() else CharacterModel.cast().map(func(e: Dictionary) -> String: return e["id"])
	var gap := 0.75
	for i in list.size():
		for row in 2:
			var model := CharacterModel.instantiate(list[i])
			if model == null:
				printerr("not built: ", list[i])
				return false
			var x := (i - (list.size() - 1) / 2.0) * gap
			var y := -row * ROW
			_place(model, Vector3(x, y, -row * 2.0), 0.0 if row == 0 else 90.0, "idle", 0.5,
				list[i] if row == 0 else "", y - 0.1)
	_frame(Vector2(-(list.size() / 2.0) * gap, -ROW - 0.1), Vector2((list.size() / 2.0) * gap, 1.95))
	return true


## Rows of full-length people: one above the other in the orthographic front view.
const ROW := 2.15


## Head close-ups of the model `id` wearing each part in `parts` (one row each), from the
## front, three-quarter, the side and the back: for judging a part's fit.
func _parts_sheet(id: String, parts: PackedStringArray) -> bool:
	var gap := 0.42
	var head := 0.0
	for row in parts.size():
		for col in 4:
			var model := CharacterModel.instantiate(id)
			if model == null:
				return false
			head = _head_height(model)
			for part in parts[row].split("+"):
				if not part.is_empty():
					CharacterModel.attach(model, part)
			_place(model, Vector3(col * gap, -row * gap, row * 2.0 - col * 0.5), [0.0, 35.0, 90.0, 180.0][col], "idle", 0.5,
				parts[row] if col == 0 else "", head - row * gap - 0.2)
	_frame(Vector2(-gap / 2, head - 0.24 - (parts.size() - 1) * gap), Vector2(3.5 * gap, head + 0.22))
	return true


## The Head bone's rest height in `model` (m above its feet).
func _head_height(model: Node3D) -> float:
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	return skeleton.get_bone_global_rest(skeleton.find_bone("Head")).origin.y if skeleton != null else 1.6


## The look the sheets start from on `body`: the first options, a mid skin tone, brown hair.
func _base_look(body: String) -> Dictionary:
	var look := CreatorLook.normalized({"lichaam": "man" if body == "m" else "vrouw"})
	look["huidskleur"] = "lichtgetint"
	look["haarkleur"] = "bruin"
	return look


## Every option of `trait_id` on both bodies, head and shoulders: per body a row from the
## front and a row in three-quarter view.
func _trait_sheet(trait_id: String) -> bool:
	if CreatorLook.trait_def(trait_id).is_empty():
		printerr("no trait ", trait_id)
		return false
	var gap := 0.46
	var row := 0
	var cols := 0
	var head := 0.0
	for body in ["m", "f"]:
		var list := CreatorLook.options(trait_id, body)
		cols = maxi(cols, list.size())
		for view in 2:
			for col in list.size():
				var look := _base_look(body)
				look[trait_id] = list[col]["id"]
				var model := CreatorLook.build(look)
				if model == null:
					printerr("cannot build ", look)
					return false
				head = maxf(head, _head_height(model))
				_place(model, Vector3(col * gap, -row * gap, row * 2.0), [0.0, 35.0][view], "idle", 0.5,
					list[col]["label"] if view == 0 else "", head - row * gap - 0.19)
			row += 1
	_frame(Vector2(-gap / 2, head - 0.23 - (row - 1) * gap), Vector2((cols - 0.5) * gap, head + 0.2))
	return true


## Every outfit on both bodies, full length, front and back.
func _outfit_sheet() -> bool:
	var gap := 0.7
	var list := CreatorLook.options("kleding", "m")
	var row := 0
	for body in ["m", "f"]:
		for col in list.size():
			for view in 2:
				var look := _base_look(body)
				look["kleding"] = list[col]["id"]
				var model := CreatorLook.build(look)
				if model == null:
					return false
				var x := (col * 2 + view) * gap
				_place(model, Vector3(x, -row * ROW, row * 2.0), [0.0, 180.0][view], "idle", 0.5,
					list[col]["label"] if view == 0 else "", -row * ROW - 0.1)
		row += 1
	_frame(Vector2(-gap / 2, -ROW - 0.2), Vector2((list.size() * 2 - 0.5) * gap, 1.95))
	return true


## Every outfit on one body in each animation.
func _creator_poses(body: String) -> bool:
	var models: Array[Node3D] = []
	var labels: PackedStringArray = []
	for entry in CreatorLook.options("kleding", body):
		var look := _base_look(body)
		look["kleding"] = entry["id"]
		models.append(CreatorLook.build(look))
		labels.append(entry["label"])
	return _pose_sheet(models, labels)


## Each model in a row, in every animation (three-quarter view, a moment mid-stride).
func _pose_sheet(models: Array[Node3D], labels: PackedStringArray) -> bool:
	var gap := 0.9
	for row in models.size():
		for col in POSES.size():
			var model := models[row] if col == 0 else models[row].duplicate() as Node3D
			if model == null:
				return false
			var y := -row * ROW
			_place(model, Vector3(col * gap, y, -row - col * 0.1), -40.0, POSES[col], 0.37,
				labels[row] if col == 0 else POSES[col], y - 0.1)
	_frame(Vector2(-gap / 2, -(models.size() - 1) * ROW - 0.2), Vector2((POSES.size() - 0.5) * gap, 1.95))
	return true
