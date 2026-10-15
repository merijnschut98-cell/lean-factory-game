extends TestCase
## The sample characters (tools/blender/build_character.py): each glb stands
## alone (textures embedded), carries only its own looping idle and walk, and
## its skin takes its colour from the vertex colours. Skipped for a model that
## is not there (the samples are a trial, not a dependency).

const MODELS: Array[String] = [
	"res://assets/characters/sample_player.glb",
	"res://assets/characters/sample_coach.glb",
	"res://assets/characters/sample_monteur.glb",
]


func _models() -> Array[Node]:
	var out: Array[Node] = []
	for path in MODELS:
		if ResourceLoader.exists(path):
			out.append((load(path) as PackedScene).instantiate())
	return out


func _surfaces(model: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			out.append({"node": mi.name, "mesh": mi.mesh, "index": i, "material": mi.mesh.surface_get_material(i) as BaseMaterial3D})
	return out


func test_each_character_idles_and_walks_in_a_loop_and_nothing_else() -> void:
	for model in _models():
		var animations: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false).pop_front()
		assert_true(animations != null, "%s has animations" % model.name)
		if animations != null:
			assert_eq(Array(animations.get_animation_list()), ["idle", "walk"], "%s: its own idle and walk only" % model.name)
			for name in ["idle", "walk"]:
				if animations.has_animation(name):
					assert_eq(animations.get_animation(name).loop_mode, Animation.LOOP_LINEAR, "%s %s loops" % [model.name, name])
			if animations.has_animation("walk"):
				assert_between(animations.get_animation("walk").length, 0.95, 1.05, "%s: a one-second stride cycle" % model.name)
		model.free()


func test_skin_is_coloured_by_its_vertex_colours() -> void:
	for model in _models():
		var skins := 0
		for s in _surfaces(model):
			if s.mesh.surface_get_format(s.index) & Mesh.ARRAY_FORMAT_COLOR:
				skins += 1
				assert_true(s.material != null and s.material.vertex_color_use_as_albedo,
					"%s: %s uses its vertex colours as albedo" % [model.name, s.node])
		assert_true(skins > 0, "%s has vertex-coloured skin" % model.name)
		model.free()


func test_every_texture_is_inside_the_model() -> void:
	for model in _models():
		var textures := 0
		for s in _surfaces(model):
			if s.material == null:
				continue
			for texture: Texture2D in [s.material.albedo_texture, s.material.normal_texture]:
				if texture != null:
					textures += 1
					assert_true(texture.get_image() != null, "%s: a texture of %s loads" % [model.name, s.node])
		assert_true(textures > 0, "%s has textures" % model.name)
		model.free()
