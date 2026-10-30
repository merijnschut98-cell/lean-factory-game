class_name CreatorLook
## The player's look from the character creator (PLAN 2.7b): the catalogue of options
## (assets/characters/creator_options.json; its _about explains the fields) and the model put
## together from a look, a dictionary of trait id -> option id as the save stores it. An unknown
## or missing id falls back to the trait's first option for the body, never a crash. The glbs
## and masks the catalogue names are built by tools/blender/creator_build.py.

const CATALOGUE := "res://assets/characters/creator_options.json"
const MASKS := "res://assets/characters/textures/face_%s_%s.png"
## The body trait, which picks the model and the parts' suffix, so it is resolved first.
const BODY := "lichaam"
## The skin texture keeps lips and cheeks around this share of its mean: the skin material's
## colour is the chosen tone divided by it (tools/blender/pack_character.py SKIN_HEADROOM).
const SKIN_HEADROOM := 0.92
## Brows are the hair colour at this share; stubble darker still and drawn towards a cool
## grey (short hairs under skin read darker and greyer than the hair).
const BROW_SHADE := 0.8
const STUBBLE_SHADE := 0.6
const STUBBLE_GREY := Color(0.16, 0.16, 0.18)

static var _catalogue := {}


## The catalogue ({} when the file is missing or broken).
static func catalogue() -> Dictionary:
	if _catalogue.is_empty():
		var text := FileAccess.get_file_as_string(CATALOGUE)
		var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if data is Dictionary and data.get("traits") is Array:
			_catalogue = data
		else:
			push_warning("creator: cannot read " + CATALOGUE)
	return _catalogue


## The traits in the creator's order (each {id, label, options | per_body}).
static func traits() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Variant in catalogue().get("traits", []):
		if entry is Dictionary and entry.get("id") is String:
			out.append(entry)
	return out


static func trait_def(trait_id: String) -> Dictionary:
	for entry in traits():
		if entry["id"] == trait_id:
			return entry
	return {}


## The options of `trait_id` that may be chosen with `body` ("m" or "f"), in order: for a trait
## that differs per body, the body's own list first, then (when any_body) the other body's.
static func options(trait_id: String, body: String) -> Array[Dictionary]:
	var entry := trait_def(trait_id)
	var lists: Array = []
	if entry.get("per_body") is Dictionary:
		var per: Dictionary = entry["per_body"]
		lists.append(per.get(body, []))
		if entry.get("any_body", false):
			for other: String in per:
				if other != body:
					lists.append(per[other])
	else:
		lists.append(entry.get("options", []))
	var out: Array[Dictionary] = []
	for list: Variant in lists:
		if list is Array:
			for option: Variant in list:
				if option is Dictionary and option.get("id") is String:
					out.append(option)
	return out


## The option `id` of `trait_id` for `body`, or the first one when `id` is not among them
## ({} only when the trait has no options at all).
static func option(trait_id: String, id: Variant, body: String) -> Dictionary:
	var list := options(trait_id, body)
	for entry in list:
		if id is String and entry["id"] == id:
			return entry
	return list[0] if not list.is_empty() else {}


## The body ("m" or "f") of a look.
static func body_of(look: Dictionary) -> String:
	return str(option(BODY, look.get(BODY), "").get("body", "m"))


## "hij" or "zij" for a look ({hij_zij} in dialog text).
static func pronoun(look: Dictionary) -> String:
	return str(option(BODY, look.get(BODY), "").get("pronoun", "hij"))


## Every trait mapped to a valid option id for the look's body.
static func normalized(look: Dictionary) -> Dictionary:
	var body := body_of(look)
	var out := {}
	for entry in traits():
		var chosen := option(entry["id"], look.get(entry["id"]), body)
		if not chosen.is_empty():
			out[entry["id"]] = chosen["id"]
	return out


## The player's model for `look`, facing -Z like CharacterModel.instantiate: the body, its
## outfit, hair, face and glasses attached, and every colour applied. Null when the body's glb
## is not built.
static func build(look: Dictionary) -> Node3D:
	var body := body_of(look)
	var pick := func(trait_id: String) -> Dictionary: return option(trait_id, look.get(trait_id), body)
	var model := CharacterModel.instantiate(str(pick.call(BODY).get("model", "")))
	if model == null:
		return null
	var hair := _color(pick.call("haarkleur").get("color"), Color(0.4, 0.27, 0.17))
	CharacterModel.attach(model, "outfit_%s_%s" % [pick.call("kleding").get("outfit", ""), body])
	_part(model, pick.call("kapsel"), body, hair)
	var face: Dictionary = pick.call("gezicht")
	_part(model, face, body, hair)
	var glasses: Dictionary = pick.call("bril")
	_part(model, glasses, body, _color(glasses.get("color"), Color.BLACK))
	var skin := skin_of(look)
	CharacterModel.tint(meshes(model, "_body"), Color(minf(skin.r / SKIN_HEADROOM, 1.0), minf(skin.g / SKIN_HEADROOM, 1.0),
		minf(skin.b / SKIN_HEADROOM, 1.0)))
	CharacterModel.tint(meshes(model, "_brows"), hair.darkened(1.0 - BROW_SHADE))
	CharacterModel.tint(meshes(model, "_iris"), _color(pick.call("ogen").get("color"), Color(0.3, 0.2, 0.1)))
	var layer := str(face.get("layer", ""))
	if not layer.is_empty():
		var named: Variant = face.get("color")
		var color: Color = hair.darkened(1.0 - STUBBLE_SHADE).lerp(STUBBLE_GREY, 0.4) if named is String and named == "hair" \
			else _color(named, Color.BLACK)
		for mi in meshes(model, "_body"):
			paint(mi, load(MASKS % [layer, body]) as Texture2D, color)
	return model


## The model's meshes whose node name ends with `suffix` (the body glb names them
## <model>_body, _eyes, _iris, _brows).
static func meshes(model: Node, suffix: String) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.name.ends_with(suffix):
			out.append(mi)
	return out


## Lay `color` over the mesh's material where `mask` is white (the face layers: stubble,
## make-up), through BaseMaterial3D's detail layer, so the skin's own tint stays under it.
static func paint(mi: MeshInstance3D, mask: Texture2D, color: Color) -> void:
	var base := mi.material_override if mi.material_override != null else mi.get_active_material(0)
	if mask == null or not base is BaseMaterial3D:
		push_warning("creator: cannot paint %s" % mi.name)
		return
	var mat := base.duplicate() as BaseMaterial3D
	var swatch := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	swatch.fill(Color(color, 1.0))
	mat.detail_enabled = true
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.detail_mask = mask
	mat.detail_albedo = ImageTexture.create_from_image(swatch)
	mi.material_override = mat


## Attach an option's part ("" is none) for `body` and give it `color` (a colour with alpha
## below 1 makes the part see-through: a clear glasses frame).
static func _part(model: Node3D, entry: Dictionary, body: String, color: Color) -> void:
	var part := str(entry.get("part", ""))
	if part.is_empty():
		return
	var attached := CharacterModel.attach(model, "%s_%s" % [part, body])
	CharacterModel.tint(attached, color)
	if color.a < 1.0:
		for mi in attached:
			(mi.material_override as BaseMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## The skin colour of `look` (the hand that holds the phone wears it too).
static func skin_of(look: Dictionary) -> Color:
	return _color(option("huidskleur", look.get("huidskleur"), body_of(look)).get("color"), Color(0.86, 0.67, 0.54))


## A catalogue colour ([r, g, b] sRGB 0..255, or with a fourth alpha 0..1) or `fallback`.
static func _color(value: Variant, fallback: Color) -> Color:
	if not value is Array or not (value.size() == 3 or value.size() == 4):
		return fallback
	for c: Variant in value:
		if not (c is float or c is int):
			return fallback
	var out := Color8(int(value[0]), int(value[1]), int(value[2]))
	if value.size() == 4:
		out.a = clampf(float(value[3]), 0.0, 1.0)
	return out
