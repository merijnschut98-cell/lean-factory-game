extends Node3D
## Placeholder start scene for Phase A: proves the project boots, loads
## content and renders. Replaced by the title screen in Phase D.

func _ready() -> void:
	_build_environment()
	_build_placeholder_campus()
	_build_title(GameInfo.load_from())


## Sky, ambient light and tone mapping come from the project's default
## environment (src/world/default_environment.tres); scenes add their own sun.
func _build_environment() -> void:
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
	_box(Vector3(400, 0.2, 400), Vector3(0, -0.1, 0), Palette.GRASS)
	_box(Vector3(16, 0.05, 10), Vector3(0, 0.02, 3), Palette.ASPHALT)
	_box(Vector3(10, 4, 6), Vector3(0, 2, -2), Color("#e9edf2"))
	_box(Vector3(10.2, 0.6, 6.2), Vector3(0, 4.1, -2), Palette.VOLTANA_BLUE)
	_box(Vector3(3, 0.8, 0.1), Vector3(-2.5, 3.0, 1.06), Palette.VOLTANA_GREEN)
	for i in 3:
		_box(Vector3(2.2, 1.6, 1.4), Vector3(-4 + i * 3.2, 0.8, 6), Color("#f2f2f2"))
		_box(Vector3(2.2, 0.3, 1.42), Vector3(-4 + i * 3.2, 0.9, 6), Palette.SAFETY_ORANGE)


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
	title.add_theme_color_override("font_color", Palette.VOLTANA_BLUE)
	box.add_child(title)
	var sub := Label.new()
	sub.text = info.error if not info.error.is_empty() else "%s · %s" % [info.company, info.campus]
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Palette.INK)
	box.add_child(sub)
