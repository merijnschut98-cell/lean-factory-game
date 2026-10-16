@tool
extends EditorScenePostImport
## Post-import step for the sample characters (set as import_script in each
## sample_*.glb.import). The skin has no texture: its tone, lips, stubble and
## baked occlusion are the glTF vertex colours (COLOR_0), which Godot's
## importer stores but does not use as albedo. Turn that on for every surface
## that has them.


func _post_import(scene: Node) -> Object:
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat != null and mi.mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_COLOR:
				mat.vertex_color_use_as_albedo = true
	return scene
