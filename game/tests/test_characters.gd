extends TestCase
## The characters (tools/blender/build_character.py, from assets/characters/cast.json):
## each glb carries only its own looping idle, walk, sit and talk; its skin takes its
## colour from the vertex colours; its clothes use the shared textures (no images inside,
## so a glb stays small). Skipped for a model that is not built (the method is a trial).

const MAX_BYTES := 1_500_000
## Where character_import.gd finds the shared textures.
const TEXTURES := "res://assets/characters/textures/"


func _models() -> Array[Node]:
	var out: Array[Node] = []
	for entry in CharacterModel.cast():
		var model := CharacterModel.instantiate(entry["id"])
		if model != null:
			model.name = entry["id"]
			out.append(model)
	return out


func _surfaces(model: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			out.append({"node": mi.name, "mesh": mi.mesh, "index": i, "material": mi.mesh.surface_get_material(i) as BaseMaterial3D})
	return out


func test_the_cast_lists_everyone_once_with_a_look() -> void:
	var ids := CharacterModel.cast().map(func(e: Dictionary) -> String: return e["id"])
	for id in ["player", "joost", "anouk", "sanne", "petra", "ruud", "marco", "henk", "ahmed"]:
		assert_eq(ids.count(id), 1, "%s in the cast once" % id)
	for entry in CharacterModel.cast():
		assert_true(entry.get("look") is Dictionary, "%s has a look for the builder" % entry["id"])


func test_each_character_has_its_own_four_loops_and_nothing_else() -> void:
	for model in _models():
		var animations := CharacterModel.animations(model)
		assert_true(animations != null, "%s has animations" % model.name)
		if animations != null:
			var names := Array(animations.get_animation_list())
			names.sort()
			assert_eq(names, ["idle", "sit", "talk", "walk"], "%s: its own loops only" % model.name)
			for name in names:
				assert_eq(animations.get_animation(name).loop_mode, Animation.LOOP_LINEAR, "%s %s loops" % [model.name, name])
		model.free()


func test_the_walk_has_a_pace_a_person_can_walk_at() -> void:
	for model in _models():
		assert_between(CharacterModel.walk_pace(model), 1.3, 2.2, "%s: a brisk stride, measured from the walk" % model.name)
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


func test_clothes_use_the_shared_textures_and_the_files_stay_small() -> void:
	for model in _models():
		var textures := 0
		for s in _surfaces(model):
			if s.material != null and s.material.albedo_texture != null:
				textures += 1
				assert_true(s.material.albedo_texture.resource_path.begins_with(TEXTURES),
					"%s: %s uses a shared texture" % [model.name, s.node])
		assert_true(textures > 0, "%s has textured clothes" % model.name)
		var bytes := FileAccess.get_file_as_bytes(CharacterModel.path(model.name)).size()
		assert_true(bytes < MAX_BYTES, "%s.glb is %d bytes" % [model.name, bytes])
		model.free()

