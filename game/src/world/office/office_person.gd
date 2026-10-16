class_name OfficePerson
extends Node3D
## One of the people in the office, made from a cast.json entry: their model (or a plain
## stand-in while it is not built) in a pose (sit at a desk typing, stand idle, stand
## talking, or walk a route back and forth), a name tag shown on hover, and the
## walk-around energy bar over their head while they need a talk. Faces -Z.

const POSES: Array[String] = ["sit", "idle", "talk", "walk"]
## Seconds a walker stands at each end of their route.
const PAUSE := 2.5
## How tall the person is in their pose (m): where the tag and the bar float, and the
## height the cursor can pick them at.
const STANDING_HEIGHT := 1.85
const SEATED_HEIGHT := 1.4
## How close (m) to its axis the cursor's ray must pass to point at a person.
const PICK_RADIUS := 0.35
## The bar's size as a share of its distance to the camera: one size on screen at any zoom.
const BAR_SIZE := Vector2(0.065, 0.01)
const BAR_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;
uniform float fill : hint_range(0.0, 1.0) = 0.5;
uniform vec4 low_color : source_color;
uniform vec4 high_color : source_color;
uniform vec4 back_color : source_color;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	VERTEX *= length((VIEW_MATRIX * MODEL_MATRIX[3]).xyz);
}
void fragment() {
	bool edge = UV.x < 0.02 || UV.x > 0.98 || UV.y < 0.14 || UV.y > 0.86;
	vec3 level = mix(low_color.rgb, high_color.rgb, smoothstep(0.25, 0.75, fill));
	ALBEDO = edge ? vec3(0.96) : (UV.x < fill ? level : back_color.rgb);
	ALPHA = edge ? 1.0 : 0.92;
}
"""

var id := ""
var display_name := ""
var role := ""
var pose := "idle"
## Present only while one of these missions is active ([] = always).
var missions: Array[String] = []
## "coach": using them opens the coach, not a talk.
var talk := ""
## A walker's route (office space) and the corner they walk to.
var route := PackedVector3Array()
var _leg := 1
var _wait := 0.0
## Walking speed (m/s): the walk animation's own pace, so the feet stay on the floor.
var pace := CharacterModel.FALLBACK_PACE
var model: Node3D
var tag: Label3D
var bar: MeshInstance3D
var _animations: AnimationPlayer


## A person from a cast entry ({id, name, role, office: {pose, missions, talk}}); where
## they stand is set by OfficePeople.
static func create(entry: Dictionary) -> OfficePerson:
	var p := OfficePerson.new()
	var office: Dictionary = entry.get("office", {})
	p.id = str(entry["id"])
	p.name = p.id.validate_node_name()
	p.display_name = str(entry.get("name", p.id))
	p.role = str(entry.get("role", ""))
	p.pose = str(office.get("pose", "idle")) if str(office.get("pose", "")) in POSES else "idle"
	for m: Variant in office.get("missions", []):
		p.missions.append(str(m))
	p.talk = str(office.get("talk", ""))
	p.visible = p.missions.is_empty()   # until the session says a mission of theirs is on
	p.model = CharacterModel.instantiate(p.id)
	if p.model == null:
		p.model = _stand_in(p.pose == "sit")
	p.add_child(p.model)
	p._animations = CharacterModel.animations(p.model)
	if p._animations != null:
		p.pace = CharacterModel.walk_pace(p.model)
	p.tag = _tag(p.display_name + ("\n" + p.role if not p.role.is_empty() else ""), p.height() + 0.3)
	p.add_child(p.tag)
	p.bar = _bar(p.height() + 0.12)
	p.add_child(p.bar)
	p._play(p.pose)
	return p


## Stand at `at` (office space, on the floor) facing `direction`.
func place(at: Vector3, direction: Vector3) -> void:
	position = at
	direction.y = 0
	if direction.length() > 0.01:
		basis = Basis.looking_at(direction.normalized(), Vector3.UP)


func height() -> float:
	return SEATED_HEIGHT if pose == "sit" else STANDING_HEIGHT


## Whether they are in the office while these missions are active.
func present_for(active_missions: Array) -> bool:
	if missions.is_empty():
		return true
	for m in missions:
		if m in active_missions:
			return true
	return false


func show_tag(on: bool) -> void:
	tag.visible = on


## The energy bar from GameSession.energy_of: {energy (0–1), needs_talk}. Shown only while
## they need a talk; {} (no such accessor, an unknown person) hides it.
func show_energy(state: Dictionary) -> void:
	bar.visible = bool(state.get("needs_talk", false))
	if bar.visible:
		(bar.material_override as ShaderMaterial).set_shader_parameter("fill", clampf(float(state.get("energy", 0.5)), 0.0, 1.0))


## Whether a ray (office space) passes within PICK_RADIUS of their body's axis.
func picked_by(origin: Vector3, direction: Vector3) -> bool:
	var a := position + Vector3.UP * 0.3
	var b := position + Vector3.UP * height()
	var points := Geometry3D.get_closest_points_between_segments(origin, origin + direction * 200.0, a, b)
	return points[0].distance_to(points[1]) <= PICK_RADIUS


func _process(delta: float) -> void:
	if pose == "walk":
		walk(delta)


## One frame of a walker's round: towards the end of the route at their pace, a pause
## there (standing idle), then back.
func walk(delta: float) -> void:
	if route.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_play("walk")
		return
	var to := route[_leg] - position
	to.y = 0
	var step := pace * delta
	if to.length() <= step:
		position = route[_leg]
		_leg = (_leg + 1) % route.size()
		_wait = PAUSE
		_play("idle")
		return
	place(position + to.normalized() * step, to)


func _play(animation: String) -> void:
	if _animations != null and _animations.has_animation(animation):
		_animations.play(animation, 0.25)


## A capsule and a head, seated or standing, while the model is not built.
static func _stand_in(seated: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "StandIn"
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = 0.9 if seated else 1.5
	body.mesh = capsule
	body.position.y = (0.5 + 0.45) if seated else 0.75
	root.add_child(body)
	return root


static func _tag(text: String, at: float) -> Label3D:
	var l := Label3D.new()
	l.name = "NameTag"
	l.text = text
	l.position.y = at
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0006
	l.font_size = 32
	l.outline_size = 10
	l.modulate = Color.WHITE
	l.outline_modulate = Palette.HUD_BAR
	l.visible = false
	return l


static func _bar(at: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = BAR_SIZE
	var shader := Shader.new()
	shader.code = BAR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("low_color", Color(0.93, 0.55, 0.16))
	mat.set_shader_parameter("high_color", Palette.VOLTANA_GREEN)
	mat.set_shader_parameter("back_color", Color(0.12, 0.14, 0.18))
	var bar := MeshInstance3D.new()
	bar.name = "EnergyBar"
	bar.mesh = quad
	bar.material_override = mat
	bar.position.y = at
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.visible = false
	return bar
