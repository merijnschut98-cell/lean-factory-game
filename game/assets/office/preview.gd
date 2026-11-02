extends Node3D
## Office preview for screenshots. The view index is the 4th user argument:
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/screenshot.gd -- res://assets/office/preview.tscn out.png 30 <view>

# Camera position and look-at target per view, in Godot coordinates (Blender x, z, -y).
const VIEWS := [
	[Vector3(1.6, 1.65, -7.95), Vector3(12.0, 1.3, -7.0)],    # 0 spawn, looking down the aisle
	[Vector3(20.5, 1.65, -7.6), Vector3(8.0, 0.9, -2.6)],     # 1 werkvoorbereiding and intake
	[Vector3(3.0, 1.65, -11.6), Vector3(20.0, 1.0, -12.6)],   # 2 north side to the coach's room
	[Vector3(9.0, 1.65, -5.4), Vector3(9.0, 0.8, -2.8)],      # 3 at the werkvoorbereiding desks
	[Vector3(21.2, 1.65, -3.4), Vector3(24.0, 1.4, -3.4)],    # 4 obeya wall
	[Vector3(2.6, 1.65, -9.4), Vector3(0.0, 1.4, -10.4)],     # 5 mission board and coffee corner
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var view: int = clampi(int(args[3]), 0, VIEWS.size() - 1) if args.size() > 3 else 0
	var cam := $Camera3D as Camera3D
	cam.position = VIEWS[view][0]
	cam.look_at(VIEWS[view][1])
