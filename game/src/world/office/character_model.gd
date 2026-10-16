class_name CharacterModel
## The people's models: game/assets/characters/<id>.glb, built from the one cast list
## (cast.json) by tools/blender/build_character.py, or later by whatever method replaces
## it (PLAN §7 Q1): the game needs only these file names, a front on +Z, feet at 0 and the
## looping animations idle, walk, sit and talk.

const DIR := "res://assets/characters/"
const CAST := DIR + "cast.json"
## The share of a stride a foot is on the floor (human walking ≈ 0.6; the builder's DUTY).
const DUTY := 0.6
## The walk's pace (m/s) when it cannot be measured (no skeleton, no LeftFoot).
const FALLBACK_PACE := 1.4
## Samples over one walk cycle for the measurement.
const PACE_SAMPLES := 24

static var _paces := {}


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


## The cast list's characters ([] when the file is missing or broken).
static func cast() -> Array[Dictionary]:
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


## The walk's ground speed (m/s): how far the left ankle travels front to back in one
## cycle, over the time a foot is down. Moving at this speed with the walk at speed 1
## keeps the feet on the floor. Measured once per model file.
static func walk_pace(model: Node3D) -> float:
	var key := model.scene_file_path
	if _paces.has(key):
		return _paces[key]
	var pace := _measure_pace(model)
	if not key.is_empty():
		_paces[key] = pace
	return pace


static func _measure_pace(model: Node3D) -> float:
	var player := animations(model)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	if player == null or skeleton == null or not player.has_animation("walk"):
		return FALLBACK_PACE
	var foot := skeleton.find_bone("LeftFoot")
	if foot < 0:
		return FALLBACK_PACE
	var was := player.current_animation
	var length := player.get_animation("walk").length
	var lo := INF
	var hi := -INF
	player.play("walk")
	for k in PACE_SAMPLES:
		player.seek(length * k / PACE_SAMPLES, true)
		var z := skeleton.get_bone_global_pose(foot).origin.z
		lo = minf(lo, z)
		hi = maxf(hi, z)
	if not was.is_empty():
		player.play(was)
	else:
		player.stop()
	var pace := (hi - lo) / (DUTY * length) if length > 0 else 0.0
	return pace if pace > 0.2 else FALLBACK_PACE
