extends TestCase
## The characters (tools/blender/build_character.py: the CC0 Quaternius pack re-dressed for
## Voltana, from assets/characters/cast.json): each glb carries only its own looping idle,
## walk, sit, talk and jog on Godot's humanoid bone names; skin, hair and clothes use the
## shared textures under their material colour (no images inside, so a glb stays small);
## the creator's parts sit on anyone's head and take a colour. Skipped for a model that is
## not built.

const MAX_BYTES := 1_500_000
## Where character_import.gd finds the shared textures.
const TEXTURES := "res://assets/characters/textures/"
const LOOPS: Array[String] = ["idle", "jog", "sit", "talk", "walk"]
## How far (m) a planted foot may slide over one contact when the person moves at the
## stride's measured pace (the heel lands and rolls a little; the eye forgives ~4 cm), and
## how close (m) to its standing height a foot counts as on the floor for this.
const MAX_SLIDE := 0.04
const ON_FLOOR := 0.005
const SLIDE_SAMPLES := 120
## The creator's parts (PLAN 2.7b): at least three hairstyles, two beards, two glasses.
const PARTS: Array[String] = ["hair_bob", "hair_parted", "hair_buzzed", "hair_pixie", "hair_buns", "hair_ponytail",
	"beard_full", "beard_short", "glasses_round", "glasses_rect"]


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


func test_each_character_has_its_own_loops_and_nothing_else() -> void:
	for model in _models():
		var animations := CharacterModel.animations(model)
		assert_true(animations != null, "%s has animations" % model.name)
		if animations != null:
			var names := Array(animations.get_animation_list())
			names.sort()
			assert_eq(names, LOOPS, "%s: its own loops only" % model.name)
			for name in names:
				assert_eq(animations.get_animation(name).loop_mode, Animation.LOOP_LINEAR, "%s %s loops" % [model.name, name])
		model.free()


func test_the_walk_has_a_pace_a_person_can_walk_at() -> void:
	for model in _models():
		assert_between(CharacterModel.stride_pace(model, "walk", 0.0), 1.3, 2.2, "%s: a brisk stride, measured from the walk" % model.name)
		model.free()


func test_the_jog_is_timed_for_the_run() -> void:
	for model in _models():
		assert_between(CharacterModel.stride_pace(model, "jog", 0.0), CharacterModel.JOG_PACE * 0.9, CharacterModel.JOG_PACE * 1.1,
			"%s: the jog runs at about %.1f m/s at speed 1" % [model.name, CharacterModel.JOG_PACE])
		model.free()


func test_the_planted_foot_does_not_slide() -> void:
	for model in _models():
		for animation in ["walk", "jog"]:
			var pace := CharacterModel.stride_pace(model, animation, 0.0)
			var slide := _slide(model, animation, pace)
			assert_true(slide < MAX_SLIDE, "%s %s: the planted foot slides %.3f m at %.2f m/s" % [model.name, animation, slide, pace])
		model.free()


## Moving `model` forward at `pace` while `animation` plays at speed 1: how far (m) the foot's
## contact (the ankle while the foot is flat, then the ball as it rolls off; whichever is
## nearer its standing height) travels over the floor during one stretch on the floor.
func _slide(model: Node3D, animation: String, pace: float) -> float:
	var player := CharacterModel.animations(model)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	var length := player.get_animation(animation).length
	var bones: Array[int] = []
	var rest: Array[float] = []
	for name in CharacterModel.FEET:
		bones.append(skeleton.find_bone(name))
		rest.append(skeleton.get_bone_global_rest(bones[-1]).origin.y)
	player.play(animation)
	var worst := 0.0
	var run: Array[float] = []
	var on := -1
	for k in SLIDE_SAMPLES + 1:
		var t := length * k / SLIDE_SAMPLES
		player.seek(t, true)
		var low := -1
		var lift := ON_FLOOR
		var at := 0.0
		for j in bones.size():
			var foot := CharacterModel.bone_pose(skeleton, bones[j]).origin
			if foot.y - rest[j] < lift:
				lift = foot.y - rest[j]
				low = j
				at = foot.z + pace * t   # where it is on the floor
		if low != on and not run.is_empty():
			worst = maxf(worst, run.max() - run.min())
			run.clear()
		on = low
		if low >= 0:
			run.append(at)
	if not run.is_empty():
		worst = maxf(worst, run.max() - run.min())
	player.stop()
	return worst


func test_the_rig_uses_godots_humanoid_bone_names() -> void:
	var profile := SkeletonProfileHumanoid.new()
	for model in _models():
		var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
		assert_true(skeleton != null, "%s has a skeleton" % model.name)
		if skeleton != null:
			for i in profile.bone_size:
				var bone := profile.get_bone_name(i)
				if not bone in ["LeftEye", "RightEye", "Jaw"]:   # the pack's faces have no such bones
					assert_true(skeleton.find_bone(bone) >= 0, "%s has %s" % [model.name, bone])
		model.free()


func test_skin_is_the_shared_skin_texture_under_the_skin_colour() -> void:
	for model in _models():
		var skins := 0
		for s in _surfaces(model):
			if s.material != null and s.material.albedo_texture != null \
					and s.material.albedo_texture.resource_path.get_file().begins_with("skin_"):
				skins += 1
				assert_true(s.material.albedo_color != Color.WHITE, "%s: the skin has its own colour" % model.name)
		assert_eq(skins, 1, "%s has one skin" % model.name)
		model.free()


func test_the_creators_parts_sit_on_any_head_and_take_a_colour() -> void:
	var people := _models()
	if people.is_empty():
		return
	for part in PARTS:
		assert_true(ResourceLoader.exists(CharacterModel.PARTS + part + ".glb"), "the part %s is built" % part)
	for model in [people[0], people[people.size() - 1]]:   # a woman and a man of other heights
		var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
		var head := skeleton.get_bone_global_rest(skeleton.find_bone("Head")).origin
		for part in PARTS:
			var meshes := CharacterModel.attach(model, part)
			assert_eq(meshes.size(), 1, "%s on %s" % [part, model.name])
			for mi in meshes:
				assert_eq(mi.get_node(mi.skeleton), skeleton, "%s binds to %s's skeleton" % [part, model.name])
				var binds := range(mi.skin.get_bind_count()).map(func(i: int) -> StringName: return mi.skin.get_bind_name(i))
				assert_true(&"Head" in binds, "%s binds to the head by name" % part)
				var bind := mi.skin.get_bind_pose(binds.find(&"Head")) if &"Head" in binds else Transform3D.IDENTITY
				var centre := skeleton.get_bone_global_rest(skeleton.find_bone("Head")) * bind * mi.mesh.get_aabb().get_center()
				assert_true(centre.distance_to(head + Vector3(0, 0.09, 0)) < 0.16,
					"%s sits on %s's head (%s vs head %s)" % [part, model.name, centre, head])
				CharacterModel.tint(meshes, Color(0.8, 0.2, 0.1))
				assert_eq((mi.material_override as BaseMaterial3D).albedo_color, Color(0.8, 0.2, 0.1), "%s takes a colour" % part)
	for model in people:
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

