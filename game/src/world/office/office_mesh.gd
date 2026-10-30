class_name OfficeMesh
## Small mesh helpers shared by the props built in Godot (the whiteboard, the
## terugbelbord, the KPI wall), not in the office model.


## A box of `size` centred at `at` under `parent`, drawn with `mat`.
static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
