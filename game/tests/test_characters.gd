extends TestCase
## The characters (tools/blender/build_character.py: the CC0 Quaternius pack re-dressed for
## Voltana, from assets/characters/cast.json): each glb carries only its own looping idle,
## walk, sit, talk and jog, the reaction loops and the two one-shots (nod, look away; Phase 2
## §1.4) on Godot's humanoid bone names; skin, hair and clothes use the
## shared textures under their material colour (no images inside, so a glb stays small);
## the creator's parts sit on anyone's head and take a colour. The creator (PLAN 2.7b):
## every trait of creator_options.json has 2-5 options per body and each resolves to a glb, a
## mask or a colour; parts sit on both bodies' heads, glasses on the nose, outfits on their
## body's skeleton; a look builds, and a broken one falls back. Skipped for a model that is
## not built.

## (2.0 MB since the reaction clips, S1-C: nine more clips are ~0.6 MB of keys a person.)
const MAX_BYTES := 2_000_000
## A creator part (hair, an outfit) is smaller: the game loads one per trait.
const MAX_PART_BYTES := 1_000_000
## Where character_import.gd finds the shared textures.
const TEXTURES := "res://assets/characters/textures/"
const LOOPS: Array[String] = ["arms_folded", "carry", "idle", "jog", "lean", "phone", "sit", "sit_talk", "sit_tired",
	"talk", "tired", "walk"]
## Played once, then the person settles back (OfficePerson.SETTLES).
const ONCE: Array[String] = ["look_away", "nod"]
## How far (m) a planted foot may slide over one contact when the person moves at the
## stride's measured pace (the heel lands and rolls a little; the eye forgives ~4 cm), and
## how close (m) to its standing height a foot counts as on the floor for this.
const MAX_SLIDE := 0.04
const ON_FLOOR := 0.005
const SLIDE_SAMPLES := 120
const BODIES: Array[String] = ["m", "f"]
## Glasses rest in front of the eyes: their front this far (m) before the eyes' front.
const GLASSES_FRONT := Vector2(0.004, 0.03)


## The cast's models and the creator's bodies (player_m, player_f).
func _models() -> Array[Node]:
	var ids: Array = CharacterModel.cast().map(func(e: Dictionary) -> String: return e["id"])
	for entry in CreatorLook.options(CreatorLook.BODY, ""):
		ids.append(entry["model"])
	var out: Array[Node] = []
	for id: String in ids:
		var model := CharacterModel.instantiate(id)
		if model != null:
			model.name = id
			out.append(model)
	return out


func _body_model(body: String) -> Node3D:
	for entry in CreatorLook.options(CreatorLook.BODY, ""):
		if entry["body"] == body:
			return CharacterModel.instantiate(entry["model"])
	return null


## The head parts (hair, beards, glasses) an option list names that may be worn with `body`.
func _head_parts(body: String) -> PackedStringArray:
	var out := PackedStringArray()
	for trait_id in ["kapsel", "gezicht", "bril"]:
		for entry in CreatorLook.options(trait_id, body):
			var part := str(entry.get("part", ""))
			if not part.is_empty() and not part in out:
				out.append(part)
	return out


func _skeleton(model: Node) -> Skeleton3D:
	return model.find_children("*", "Skeleton3D", true, false).pop_front()


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
			var all := LOOPS + ONCE
			all.sort()
			assert_eq(names, all, "%s: its own clips only" % model.name)
			for name in names:
				var mode := Animation.LOOP_NONE if name in ONCE else Animation.LOOP_LINEAR
				assert_eq(animations.get_animation(name).loop_mode, mode, "%s %s loops (or plays once)" % [model.name, name])
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


## Every head part of `body` on `model`: one mesh each, bound to the model's skeleton and its
## Head bone by name, centred on its head, taking a colour.
func _assert_parts_sit_on(model: Node3D, body: String, label: String) -> void:
	var skeleton := _skeleton(model)
	var head_rest := skeleton.get_bone_global_rest(skeleton.find_bone("Head"))
	for part in _head_parts(body):
		var meshes := CharacterModel.attach(model, "%s_%s" % [part, body])
		assert_eq(meshes.size(), 1, "%s on %s" % [part, label])
		for mi in meshes:
			assert_eq(mi.get_node(mi.skeleton), skeleton, "%s binds to %s's skeleton" % [part, label])
			var binds := range(mi.skin.get_bind_count()).map(func(i: int) -> StringName: return mi.skin.get_bind_name(i))
			assert_true(&"Head" in binds, "%s binds to the head by name" % part)
			var bind := mi.skin.get_bind_pose(binds.find(&"Head")) if &"Head" in binds else Transform3D.IDENTITY
			var centre := head_rest * bind * mi.mesh.get_aabb().get_center()
			assert_true(centre.distance_to(head_rest.origin + Vector3(0, 0.09, 0)) < 0.16,
				"%s sits on %s's head (%s vs head %s)" % [part, label, centre, head_rest.origin])
			CharacterModel.tint(meshes, Color(0.8, 0.2, 0.1))
			assert_eq((mi.material_override as BaseMaterial3D).albedo_color, Color(0.8, 0.2, 0.1), "%s takes a colour" % part)


func test_the_creators_parts_sit_on_any_head_and_take_a_colour() -> void:
	var people := _models()
	if people.is_empty():
		return
	for model in [people[0], people[people.size() - 1]]:   # a woman and a man of other heights
		_assert_parts_sit_on(model, "f" if model.name in ["player", "player_f"] else "m", model.name)
	for model in people:
		model.free()


func test_every_creator_trait_has_two_to_five_options_per_body() -> void:
	var traits := CreatorLook.traits()
	assert_eq(traits.map(func(t: Dictionary) -> String: return t["id"]),
		["lichaam", "huidskleur", "kapsel", "haarkleur", "ogen", "gezicht", "bril", "kleding"], "the traits of PLAN 2.7b, in order")
	for entry in traits:
		var lists: Array = entry["per_body"].values() if entry.get("per_body") is Dictionary else [entry.get("options", [])]
		for list: Array in lists:
			assert_between(list.size(), 2, 5, "%s: 2-5 options" % entry["id"])
			var ids := list.map(func(o: Dictionary) -> String: return o["id"])
			for id: String in ids:
				assert_eq(ids.count(id), 1, "%s: %s once" % [entry["id"], id])
			for option: Dictionary in list:
				assert_true(option.get("label") is String and not option["label"].is_empty(), "%s %s has a label" % [entry["id"], option["id"]])


## Merijn's playtest (2026-10-19): the styles that read wrong left the creator (the contact
## sheets docs/screenshots/creator_hair_*_2026-10-19.png): the middle parting's helmet, the
## ponytail's loose cone, the curls' flat cards. Their glbs stay for a rebuild.
const DROPPED_HAIR: Array[String] = ["curtains", "staart", "krullen"]


func test_at_least_three_hairstyles_per_body_and_any_on_either() -> void:
	var kapsel := CreatorLook.trait_def("kapsel")
	var all := 0
	for body in BODIES:
		assert_true(kapsel["per_body"][body].size() >= 3, "at least three hairstyles listed for %s" % body)
		all += kapsel["per_body"][body].size()
	for body in BODIES:
		assert_eq(CreatorLook.options("kapsel", body).size(), all, "every style may be chosen with %s" % body)
		assert_eq(CreatorLook.options("kapsel", body)[0], kapsel["per_body"][body][0], "the body's own list comes first")
	assert_eq(CreatorLook.options("gezicht", "f").size(), 5, "faces stay per body")


func test_the_hairstyles_that_read_wrong_are_not_offered() -> void:
	for body in BODIES:
		for option: Dictionary in CreatorLook.options("kapsel", body):
			assert_false(option["id"] in DROPPED_HAIR, "%s is dropped" % option["id"])


func test_an_old_save_with_a_dropped_hairstyle_gets_a_kept_one() -> void:
	for body: String in BODIES:
		var kept := CreatorLook.options("kapsel", body).map(func(o: Dictionary) -> String: return o["id"])
		for id in DROPPED_HAIR:
			var look := CreatorLook.normalized({"lichaam": "man" if body == "m" else "vrouw", "kapsel": id})
			assert_true(look["kapsel"] in kept, "%s on %s: %s" % [id, body, look["kapsel"]])
			assert_eq(look["kapsel"], kept[0], "the body's first style")


func test_every_creator_option_resolves_to_a_mesh_or_a_colour() -> void:
	for entry in CreatorLook.options(CreatorLook.BODY, ""):
		assert_true(entry.get("body") in BODIES and entry.get("pronoun") in ["hij", "zij"], "%s: a body and a pronoun" % entry["id"])
		var model := CharacterModel.instantiate(str(entry.get("model", "")))
		assert_true(model != null and _skeleton(model) != null, "%s: the body %s loads" % [entry["id"], entry.get("model")])
		if model != null:
			model.free()
	for body in BODIES:
		for entry in CreatorLook.traits():
			if entry["id"] == CreatorLook.BODY:
				continue
			for option in CreatorLook.options(entry["id"], body):
				var what := "%s %s on %s" % [entry["id"], option["id"], body]
				var resolves := 0
				for field in ["part", "outfit"]:
					var name := str(option.get(field, ""))
					if not name.is_empty():
						var path := CharacterModel.PARTS + ("outfit_" if field == "outfit" else "") + "%s_%s.glb" % [name, body]
						assert_true(ResourceLoader.exists(path) and load(path) is PackedScene, "%s: %s loads" % [what, path])
						assert_true(FileAccess.get_file_as_bytes(path).size() < MAX_PART_BYTES, "%s: %s is small" % [what, path])
						resolves += 1
				if not str(option.get("layer", "")).is_empty():
					var mask := CreatorLook.MASKS % [option["layer"], body]
					assert_true(ResourceLoader.exists(mask) and load(mask) is Texture2D, "%s: the mask %s loads" % [what, mask])
					resolves += 1
				if option.has("color"):
					var c: Variant = option["color"]
					var valid: bool = (c is String and c == "hair") or (c is Array and c.size() in [3, 4] and c.slice(0, 3).all(
						func(v: Variant) -> bool: return (v is float or v is int) and v >= 0 and v <= 255 and v == floorf(v)) \
						and (c.size() == 3 or (c[3] >= 0.0 and c[3] <= 1.0)))
					assert_true(valid, "%s: a colour sRGB 0..255 (or \"hair\")" % what)
					resolves += 1
				var bare: bool = str(option.get("part", "-")).is_empty() or str(option.get("layer", "-")).is_empty()
				assert_true(resolves > 0 or bare, "%s resolves to a mesh, a mask or a colour" % what)


func test_head_parts_sit_on_both_bodies() -> void:
	for body in BODIES:
		var model := _body_model(body)
		if model == null:
			continue
		_assert_parts_sit_on(model, body, "the creator's " + body)
		model.free()


func test_glasses_rest_before_the_eyes_not_in_the_air() -> void:
	for body in BODIES:
		var model := _body_model(body)
		if model == null:
			continue
		var eyes: AABB = CreatorLook.meshes(model, "_eyes")[0].mesh.get_aabb()
		for entry in CreatorLook.options("bril", body):
			if str(entry["part"]).is_empty():
				continue
			var scene: Node = load(CharacterModel.PARTS + "%s_%s.glb" % [entry["part"], body]).instantiate()
			var frame: AABB = (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.get_aabb()
			var ahead := frame.end.z - eyes.end.z
			assert_between(ahead, GLASSES_FRONT.x, GLASSES_FRONT.y, "%s on %s: %.3f m before the eyes" % [entry["id"], body, ahead])
			assert_true(frame.position.y < eyes.get_center().y and frame.end.y > eyes.get_center().y,
				"%s on %s: at eye height" % [entry["id"], body])
			scene.free()
		model.free()


func test_outfits_are_cut_for_their_body_and_move_with_it() -> void:
	for body in BODIES:
		var model := _body_model(body)
		if model == null:
			continue
		var skeleton := _skeleton(model)
		var skin: Skin = CreatorLook.meshes(model, "_body")[0].skin
		var rest := {}
		for i in skin.get_bind_count():
			rest[skin.get_bind_name(i)] = skin.get_bind_pose(i)
		for entry in CreatorLook.options("kleding", body):
			var meshes := CharacterModel.attach(model, "outfit_%s_%s" % [entry["outfit"], body])
			assert_true(meshes.size() >= 3, "%s on %s: a top, trousers and shoes" % [entry["id"], body])
			var bones := {}
			for mi in meshes:
				assert_eq(mi.get_node(mi.skeleton), skeleton, "%s binds to the body's skeleton" % mi.name)
				for i in mi.skin.get_bind_count():
					var bone := mi.skin.get_bind_name(i)
					bones[bone] = true
					if rest.has(bone):
						assert_true(mi.skin.get_bind_pose(i).origin.distance_to(rest[bone].origin) < 0.001,
							"%s %s: cut for this body (bind pose of %s)" % [entry["id"], body, bone])
			for bone in ["Hips", "LeftUpperLeg", "RightLowerLeg", "LeftFoot", "Chest", "RightUpperArm"]:
				assert_true(bones.has(StringName(bone)), "%s on %s follows %s" % [entry["id"], body, bone])
		model.free()


func test_a_look_builds_with_its_parts_and_colours() -> void:
	var look := {"lichaam": "vrouw", "huidskleur": "bruin", "kapsel": "fade", "haarkleur": "koperrood", "ogen": "groen",
		"gezicht": "lippenstift", "bril": "transparant", "kleding": "quarterzip"}
	var model := CreatorLook.build(look)
	if model == null:
		return
	assert_eq(CreatorLook.pronoun(look), "zij", "the pronoun follows the body")
	var names := model.find_children("*", "MeshInstance3D", true, false).map(func(mi: Node) -> String: return mi.name)
	for part in ["hair_fade_f", "glasses_clear_f"]:
		assert_true(part in names, "%s is on (a man's style on a woman: any_body)" % part)
	var skin := CreatorLook.meshes(model, "_body")[0].material_override as BaseMaterial3D
	assert_true(skin.albedo_color.is_equal_approx(Color(Color8(132, 86, 56).r / CreatorLook.SKIN_HEADROOM,
		Color8(132, 86, 56).g / CreatorLook.SKIN_HEADROOM, Color8(132, 86, 56).b / CreatorLook.SKIN_HEADROOM)), "the skin tone")
	assert_true(skin.detail_enabled and skin.detail_mask != null, "the lipstick is painted over the skin")
	assert_eq((CreatorLook.meshes(model, "_iris")[0].material_override as BaseMaterial3D).albedo_color, Color8(90, 132, 86), "green eyes")
	var hair := CreatorLook.meshes(model, "hair_fade_f")[0].material_override as BaseMaterial3D
	assert_eq(hair.albedo_color, Color8(166, 76, 40), "copper hair")
	var frame := CreatorLook.meshes(model, "glasses_clear_f")[0].material_override as BaseMaterial3D
	assert_eq(frame.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "a see-through frame")
	model.free()


func test_a_broken_look_falls_back_to_the_first_options() -> void:
	var look := {"lichaam": "alien", "kapsel": 42, "haarkleur": null, "kleding": "pyjama", "bril": ["x"]}
	var normal := CreatorLook.normalized(look)
	for entry in CreatorLook.traits():
		assert_eq(normal.get(entry["id"]), CreatorLook.options(entry["id"], "m")[0]["id"], "%s falls back" % entry["id"])
	var model := CreatorLook.build(look)
	if model != null:
		assert_true(CreatorLook.meshes(model, "_body").size() == 1, "a broken look still builds a body")
		model.free()
	assert_eq(CreatorLook.normalized({}).size(), CreatorLook.traits().size(), "an empty look gets every trait")


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

