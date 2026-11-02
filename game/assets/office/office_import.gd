@tool
extends EditorScenePostImport
## Post-import step for office.glb (set as import_script in office.glb.import).
## - The room shell's baked lightmap arrives as the glTF occlusion texture on UV2. Godot
##   applies AO to ambient light only, and the Compatibility renderer has no GI, so the
##   lightmap becomes a multiply detail layer on UV2: it darkens corners and spreads the
##   window and ceiling light under every light source.
## - Glass casts no shadows, so the sun reaches the floor through the windows.


func _post_import(scene: Node) -> Object:
	_fix(scene)
	return scene


func _fix(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		if mi.name.begins_with("glass"):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat != null and mat.ao_enabled and mat.ao_texture != null:
				mat.detail_enabled = true
				mat.detail_albedo = mat.ao_texture
				mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
				mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
				mat.ao_enabled = false
				mat.ao_texture = null
	for child in node.get_children():
		_fix(child)
