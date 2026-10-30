class_name CharacterModel
## The people's models: game/assets/characters/<id>.glb, built from the one cast list
## (cast.json) by tools/blender/build_character.py (the CC0 Quaternius pack re-dressed,
## PLAN 1.3a): the game needs only these file names, a front on +Z, feet at 0, Godot's
## humanoid bone names and the looping animations idle, walk, sit, talk and jog (the run), plus the
## reaction clips (Phase 2 §1.4: arms_folded, phone, lean, tired, carry, sit_talk, sit_tired loop;
## nod and look_away play once; OfficePerson uses them).
## The character creator's parts are glbs in parts/, one per body (<part>_m, <part>_f): hair,
## beards and glasses skinned to the Head bone (they sit on any head of that body), outfits
## skinned to the whole creator body; attach() puts one on, tint() colours it. CreatorLook
## puts a whole look together.

const DIR := "res://assets/characters/"
const CAST := DIR + "cast.json"
const PARTS := DIR + "parts/"
## The walk's pace (m/s) when it cannot be measured (no skeleton, no LeftFoot).
const FALLBACK_PACE := 1.4
## The jog's pace (m/s) when it cannot be measured; the builder times the jog to this.
const JOG_PACE := 4.5
## Samples over one cycle for the pace measurement.
const PACE_SAMPLES := 240
## A foot is on the floor within this of its standing height (m), the ankle or the ball.
const CONTACT := 0.02
const FEET: Array[String] = ["LeftFoot", "LeftToes"]

static var _paces := {}
## The cast list as read, once (cast).
static var _cast: Array[Dictionary] = []
static var _cast_read := false


static func path(id: String) -> String:
	return DIR + id + ".glb"


## The model of `id` turned to face -Z like every node in the office, or null when it
## has not been built.
static func instantiate(id: String) -> Node3D:
	if not ResourceLoader.exists(path(id)):
		return null
	var packed := load(path(id)) as PackedScene
	if packed == null:
		return null
	var model: Node3D = packed.instantiate()
	model.rotation.y = PI
	return model


static func animations(model: Node) -> AnimationPlayer:
	return model.find_children("*", "AnimationPlayer", true, false).pop_front() if model != null else null


## The cast list's characters ([] when the file is missing or broken). The file is read
## once (it ships with the game); the list is the caller's, its entries are shared and
## read-only.
static func cast() -> Array[Dictionary]:
	if not _cast_read:
		_cast = _read_cast()
		_cast_read = true
	return _cast.duplicate()


## "hij" or "zij" for the cast member `id`, by their look's sex ("hij" when unknown).
static func pronoun(id: String) -> String:
	for entry in cast():
		if entry["id"] == id:
			return "zij" if JsonFile.dict_or_empty(entry.get("look")).get("sex") == "f" else "hij"
	return "hij"


## The cast member the coach is: the one whose place opens the coach (office talk: coach).
static func coach_id() -> String:
	for entry in cast():
		if JsonFile.dict_or_empty(entry.get("office")).get("talk") == "coach":
			return entry["id"]
	return ""


static func _read_cast() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(CAST)
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not data is Dictionary or not data.get("characters") is Array:
		push_warning("cast: cannot read " + CAST)
		return out
	for entry: Variant in data["characters"]:
		if entry is Dictionary and entry.get("id") is String:
			out.append(entry)
	return out


## The walk's ground speed (m/s): moving at it with the walk at speed 1 keeps the feet on
## the floor. Measured once per model file.
static func walk_pace(model: Node3D) -> float:
	return stride_pace(model, "walk", FALLBACK_PACE)


## The jog's ground speed (m/s), for the run: play the jog at speed / jog_pace.
static func jog_pace(model: Node3D) -> float:
	return stride_pace(model, "jog", JOG_PACE)


## The ground speed (m/s) of an in-place stride `animation`: how fast the planted foot (the
## ankle or the ball of the foot, whichever is on the floor) travels backwards, the median
## over the cycle. `fallback` when it cannot be measured (no skeleton, no feet, no animation).
static func stride_pace(model: Node3D, animation: String, fallback: float) -> float:
	var key := "%s:%s" % [model.scene_file_path, animation]
	if _paces.has(key):
		return _paces[key]
	var pace := _measure_pace(model, animation, fallback)
	if not model.scene_file_path.is_empty():
		_paces[key] = pace
	return pace


static func _measure_pace(model: Node3D, animation: String, fallback: float) -> float:
	var player := animations(model)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	if player == null or skeleton == null or not player.has_animation(animation):
		return fallback
	var bones: Array[int] = []
	var rest: Array[float] = []
	for name in FEET:
		var b := skeleton.find_bone(name)
		if b < 0:
			return fallback
		bones.append(b)
		rest.append(skeleton.get_bone_global_rest(b).origin.y)
	var was := player.current_animation
	var length := player.get_animation(animation).length
	player.play(animation)
	var feet: Array[Array] = []
	for k in PACE_SAMPLES + 1:
		player.seek(length * k / PACE_SAMPLES, true)
		feet.append(bones.map(func(b: int) -> Vector3: return bone_pose(skeleton, b).origin))
	if not was.is_empty():
		player.play(was)
	else:
		player.stop()
	var dt := length / PACE_SAMPLES
	var speeds: Array[float] = []
	for k in PACE_SAMPLES:
		for j in bones.size():
			if feet[k][j].y < rest[j] + CONTACT and feet[k + 1][j].y < rest[j] + CONTACT:
				speeds.append((feet[k][j].z - feet[k + 1][j].z) / dt)   # backwards is -Z (the front is +Z)
				break
	if speeds.is_empty() or dt <= 0.0:
		return fallback
	speeds.sort()
	var pace := speeds[speeds.size() >> 1]
	return pace if pace > 0.2 else fallback


## A bone's pose in the skeleton's space, composed from the bones' own poses: right after an
## AnimationPlayer.seek (Skeleton3D's global poses refresh later, on its own update).
static func bone_pose(skeleton: Skeleton3D, bone: int) -> Transform3D:
	var pose := Transform3D.IDENTITY
	while bone >= 0:
		pose = skeleton.get_bone_pose(bone) * pose
		bone = skeleton.get_bone_parent(bone)
	return pose


## Put a creator part (parts/<part>.glb: hair, a beard, glasses) on `model`: its meshes move
## onto the model's skeleton and bind to its Head bone by name, so the part sits on any
## person's head and follows every animation. Returns the meshes ([] when the part or the
## skeleton is missing).
static func attach(model: Node3D, part: String) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front() if model != null else null
	var path := PARTS + part + ".glb"
	if skeleton == null or not part.is_valid_identifier() or not ResourceLoader.exists(path):
		push_warning("character: cannot attach %s" % part)
		return out
	var scene: Node = (load(path) as PackedScene).instantiate()
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		mi.get_parent().remove_child(mi)
		mi.owner = null
		mi.name = part
		skeleton.add_child(mi)
		mi.transform = Transform3D.IDENTITY
		mi.skeleton = mi.get_path_to(skeleton)
		out.append(mi)
	scene.free()
	return out


## Colour a part (or a person's one-material mesh, like the hair or the skin): the material's
## albedo colour, which tints the shared greyscale texture under it. Each mesh gets its own
## copy of the material, as its material_override (a skinned mesh's surface overrides trip
## Godot's dummy renderer when freed headless).
static func tint(meshes: Array[MeshInstance3D], color: Color) -> void:
	for mi in meshes:
		var mat := mi.get_active_material(0) as BaseMaterial3D
		if mat != null:
			mat = mat.duplicate()
			mat.albedo_color = color
			mi.material_override = mat
