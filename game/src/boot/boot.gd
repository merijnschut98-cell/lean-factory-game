extends Node3D
## Placeholder start scene for Phase A: proves the project boots, loads
## content and renders. Replaced by the title screen in Phase D.

const SKY_TOP := Color("#7fa9d8")
const SKY_HORIZON := Color("#d9e6f2")
const VOLTANA_BLUE := Color("#123c7a")
const VOLTANA_GREEN := Color("#3ccf7a")


func _ready() -> void:
	_build_environment()
	_build_placeholder_campus()
	_build_title(GameInfo.load_from())


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = SKY_TOP
	sky_mat.sky_horizon_color = SKY_HORIZON
	sky_mat.ground_horizon_color = SKY_HORIZON
	sky_mat.ground_bottom_color = Color("#5f7f45")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# A neutral ambient: sky-sourced ambient tints everything blue and overexposes.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c9d2dc")
	env.ambient_light_energy = 0.35
	# Linear keeps authored colours true; Filmic lifts them noticeably in the Compatibility renderer.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(14, 10, 18)
	add_child(cam)
	cam.look_at(Vector3(0, 1.5, 0))


func _build_placeholder_campus() -> void:
	_box(Vector3(400, 0.2, 400), Vector3(0, -0.1, 0), Color("#6f9a4c"))
	_box(Vector3(16, 0.05, 10), Vector3(0, 0.02, 3), Color("#6b6f73"))
	_box(Vector3(10, 4, 6), Vector3(0, 2, -2), Color("#e9edf2"))
	_box(Vector3(10.2, 0.6, 6.2), Vector3(0, 4.1, -2), VOLTANA_BLUE)
	_box(Vector3(3, 0.8, 0.1), Vector3(-2.5, 3.0, 1.06), VOLTANA_GREEN)
	for i in 3:
		_box(Vector3(2.2, 1.6, 1.4), Vector3(-4 + i * 3.2, 0.8, 6), Color("#f2f2f2"))
		_box(Vector3(2.2, 0.3, 1.42), Vector3(-4 + i * 3.2, 0.9, 6), Color("#f07b22"))


func _box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	add_child(inst)


func _build_title(info: GameInfo) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(48, 40)
	layer.add_child(box)
	var title := Label.new()
	title.text = "Spanning"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", VOLTANA_BLUE)
	box.add_child(title)
	var sub := Label.new()
	sub.text = info.error if not info.error.is_empty() else "%s · %s" % [info.company, info.campus]
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color("#1d2b3a"))
	box.add_child(sub)
