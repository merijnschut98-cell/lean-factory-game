@tool
extends EditorScenePostImport
## Post-import step for the characters (set as import_script in each <id>.glb.import,
## which tools/blender/build_character.py writes). Two jobs:
## - The skin has no texture: its tone, lips, stubble and baked occlusion are the glTF
##   vertex colours (COLOR_0), which Godot's importer stores but does not use as albedo.
##   Turn that on for every surface that has them.
## - Clothes and hair: a glb carries no images, only the garment's colour and its texture's
##   name in the material's extras ({"texture": "pique"}). Lay the shared greyscale texture
##   (textures/<name>_albedo.png, and <name>_normal.png when there is one) under that colour,
##   so every person uses the same few textures.

const TEXTURES := "res://assets/characters/textures/"


func _post_import(scene: Node) -> Object:
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat == null:
				continue
			if mi.mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_COLOR:
				mat.vertex_color_use_as_albedo = true
			dress(mat)
	return scene


## Put the shared texture its extras name on `mat`. A name that is not a plain identifier,
## or a texture that is not there, leaves the plain colour (and says so).
static func dress(mat: BaseMaterial3D) -> void:
	var extras: Variant = mat.get_meta("extras", {})
	if not extras is Dictionary or not extras.has("texture"):
		return
	var texture := str(extras["texture"])
	if not texture.is_valid_identifier():
		push_warning("character import: bad texture name %s on %s" % [texture, mat.resource_name])
		return
	var albedo := TEXTURES + texture + "_albedo.png"
	if not ResourceLoader.exists(albedo):
		push_warning("character import: no %s for %s" % [albedo, mat.resource_name])
		return
	mat.albedo_texture = load(albedo)
	var normal := TEXTURES + texture + "_normal.png"
	if ResourceLoader.exists(normal):
		mat.normal_enabled = true
		mat.normal_texture = load(normal)
