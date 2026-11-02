extends SceneTree
## Writes res://src/world/default_environment.tres, the project-wide default
## Environment (set in project.godot). Re-run after changing these settings:
##   godot --headless --path game --script res://tools/make_default_env.gd
## Settings measured 2026-10-12 (docs/ARCHITECTURE.md, rendering notes):
## linear tone mapping keeps authored colours true in the Compatibility
## renderer; a neutral ambient avoids the blue cast and overexposure of sky light.

const OUT := "res://src/world/default_environment.tres"


func _initialize() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Palette.SKY_TOP
	sky_mat.sky_horizon_color = Palette.SKY_HORIZON
	sky_mat.ground_horizon_color = Palette.SKY_HORIZON
	sky_mat.ground_bottom_color = Color("#5f7f45")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c9d2dc")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var err := ResourceSaver.save(env, OUT)
	print("wrote ", OUT, ": ", error_string(err))
	quit(0 if err == OK else 1)
