class_name OfficePerson
extends Node3D
## One of the people in the office, made from a cast.json entry: their model (or a plain
## stand-in while it is not built) in a pose (sit at a desk typing, stand idle, stand
## talking, or walk a route back and forth), a name tag shown on hover, and the
## walk-around energy bar over their head while they need a talk (a quiet line in the
## tag's colour with a "…" beside it, audit U17). Where they are is a spot that
## OfficePeople resolves: their desk, or between 12:00 and 13:00 their lunch spot when
## they have one. The contact centre wears headsets. Faces -Z.
##
## They react (Phase 2 §1.4, §2.2): they turn to you when you come close (face_toward; a
## seated person swivels part of the way) and back to their work after; they say things as
## a short subtitle over their head (say: a greeting, a quick line, coffee chatter); in a
## talk their posture carries the openness band (pose_for_band) and a hesitation is a look
## away (hesitate). Low energy shows in a tired idle. A clip the model lacks falls back to
## the nearest one it has (FALLBACK).

const POSES: Array[String] = ["sit", "idle", "talk", "walk"]
## The talk's openness bands (Dialog.BANDS: Dicht, Op z'n hoede, Luistert, Open, Denkt mee)
## as posture, standing and seated: arms folded (half turned away when Dicht), hands open
## while talking, a nod that settles into talking, leaning in. A seated person keeps typing
## when Dicht and talks with their hands from the chair otherwise.
const BAND_CLIPS: Array[String] = ["arms_folded", "arms_folded", "talk", "nod", "lean"]
const SEATED_BAND_CLIPS: Array[String] = ["sit", "sit_talk", "sit_talk", "sit_talk", "sit_talk"]
## A one-shot clip and the loop it settles into.
const SETTLES := {"nod": "talk"}
## The nearest clip a model built before the reaction clips has.
const FALLBACK := {"arms_folded": "idle", "lean": "talk", "nod": "talk", "look_away": "idle", "tired": "idle",
	"phone": "talk", "carry": "walk", "sit_talk": "sit", "sit_tired": "sit"}
## Under this energy (morale 0–1) the idle and the typing are the tired ones (slower, the
## back rounded, the head down). An ESTIMATE: People's leave clock starts at 0.2.
const TIRED_ENERGY := 0.35
## How far (m, on the floor) a person notices you and turns to you; how fast they turn
## (rad/s); how far a seated person swivels on their chair (rad); the share of the turn a
## closed person (band 0, Dicht) gives you.
const NOTICE := 2.0
const TURN_SPEED := 3.0
const SWIVEL := 0.6
## In a talk a seated person turns their chair out from the desk this far (rad), so the face
## shot (CameraRig.face_shot) sees their face; further, their knees would go through the desk.
const TALK_SWIVEL := 1.2
const HALF_TURN := 0.5
## A hesitation: the look away's length (s), and how far a seated person turns aside (rad).
const HESITATE_SECONDS := 1.6
const HESITATE_TURN := 0.45
## A subtitle stays at least this long (s), longer for a long line (s a character).
const SAY_SECONDS := 3.0
const SAY_PER_CHAR := 0.05
## How far (px) the subtitle floats over the tag's place: clear of the name tag when it shows
## (two lines and a gap), just over the head when it does not.
const SUBTITLE_LIFT := 70.0
const SUBTITLE_LIFT_ALONE := 10.0
## Seconds a walker stands at each end of their route.
const PAUSE := 2.5
## How tall the person is in their pose (m): where the tag and the bar float, and the
## height the cursor can pick them at.
const STANDING_HEIGHT := 1.85
const SEATED_HEIGHT := 1.4
## How close (m) to its axis the cursor's ray must pass to point at a person.
const PICK_RADIUS := 0.35
## The bar's size as a share of its distance to the camera: one size on screen at any
## zoom. A thin line: the walk-around bar must not look like a game's health bar (U17).
const BAR_SIZE := Vector2(0.06, 0.0036)
## The line in the name tag's colour, over a faint track in the tag's outline colour.
const BAR_LINE := Color(0.93, 0.94, 0.96)
const BAR_TRACK := Color(0.07, 0.17, 0.33)
## The check-in mark's place (px) right of the bar's middle.
const MARK_OFFSET := Vector2(66, 4)
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
	bool on = UV.x < fill;
	ALBEDO = on ? mix(low_color.rgb, high_color.rgb, smoothstep(0.25, 0.75, fill)) : back_color.rgb;
	ALPHA = on ? 0.9 : 0.45;
}
"""
## The contact centre's headset, in the skeleton's rest space from the Head bone's origin
## (m, estimates by eye on the pack's heads): the band's centre and radius.
const HEADSET_CENTRE := Vector3(0, 0.1, 0)
const HEADSET_RADIUS := 0.098
const HEADSET_COLOR := Color(0.12, 0.12, 0.14)

var id := ""
var display_name := ""
var role := ""
var pose := "idle"
## Where they work on this floor: {at, face, pose[, route]}; {} when their desk is on
## another floor.
var desk := {}
## Where they lunch: null when they lunch at their desk; {} on another floor; else a spot.
var lunch: Variant = null
## Whether it is lunchtime and they lunch away from their desk.
var at_lunch := false
## Present only while one of these missions is active ([] = always).
var missions: Array[String] = []
## Away until one of these missions is done ([] = never away): Saskia is at home with
## stress until the callers are fixed (esra_agents).
var after: Array[String] = []
## "coach": using them opens the coach, not a talk.
var talk := ""
## The yard's van they drive (OfficeYard), or -1.
var van := -1
## Where they are instead while a mission is active: {mission: spot} (cast `during`), and
## the other spots of their story by place (OfficePeople: at their van, during:<mission>).
var during: Dictionary = {}
var spots: Dictionary = {}
## A walker's route (office space) and the corner they walk to.
var route := PackedVector3Array()
var _leg := 1
var _wait := 0.0
## Walking speed (m/s): the walk animation's own pace, so the feet stay on the floor.
var pace := CharacterModel.FALLBACK_PACE
var model: Node3D
var tag: Label3D
var bar: MeshInstance3D
## The check-in mark beside the bar.
var mark: Label3D
var _animations: AnimationPlayer
## The spot they were last settled at.
var _settled := {}
## The subtitle over their head (say) and how long it still shows (s).
var subtitle: Label3D
var _say_left := 0.0
## Where they look (office space) while someone is close, or null; their own yaw at their spot.
var _look_at: Variant = null
var _rest_yaw := 0.0
## The share of the turn towards _look_at they give (1, or HALF_TURN when closed).
var _turn_share := 1.0
## In a talk (face_toward's `talk`): turned at once, seated further.
var _talking := false
## Held for a talk (OfficePeople.hold): a walker stands instead of walking their round.
var held := false
## Seconds left of a hesitation's turn aside.
var _hesitating := 0.0
## Low energy: the idle and the typing are the tired clips.
var tired := false
## The clip asked for last (before FALLBACK), e.g. "arms_folded".
var clip := ""


## A person from a cast entry ({id, name, role, office: {pose, missions, talk, headset}});
## where they are is set by OfficePeople (settle).
static func create(entry: Dictionary) -> OfficePerson:
	var p := OfficePerson.new()
	var office: Dictionary = entry.get("office", {})
	p.id = str(entry["id"])
	p.name = p.id.validate_node_name()
	p.pose = str(office.get("pose", "idle")) if str(office.get("pose", "")) in POSES else "idle"
	for m: Variant in office.get("missions", []):
		p.missions.append(str(m))
	for m: Variant in office.get("after", []):
		p.after.append(str(m))
	p.talk = str(office.get("talk", ""))
	var drives: Variant = office.get("van", -1)
	p.van = int(drives) if (drives is int or drives is float) and drives >= 0 else -1
	var instead: Variant = office.get("during", {})
	if instead is Dictionary:
		for m: Variant in instead:
			if instead[m] is Dictionary:
				p.during[str(m)] = instead[m]
	p.visible = p.missions.is_empty() and p.after.is_empty()   # until the session says otherwise
	p.model = CharacterModel.instantiate(p.id)
	if p.model == null:
		p.model = _stand_in(p.pose == "sit")
	p.add_child(p.model)
	p._animations = CharacterModel.animations(p.model)
	if p._animations != null:
		p.pace = CharacterModel.walk_pace(p.model)
	if office.get("headset", false):
		_headset(p.model)
	p.tag = _tag("", 32)
	p.add_child(p.tag)
	p.bar = _bar()
	p.add_child(p.bar)
	p.mark = _tag("…", 40)
	p.mark.name = "CheckInMark"
	p.mark.offset = MARK_OFFSET
	p.add_child(p.mark)
	p.subtitle = _subtitle()
	p.add_child(p.subtitle)
	p.name_as(str(entry.get("name", p.id)), str(entry.get("role", "")))
	p._float_overhead()
	p._play(p.pose)
	return p


## Their name and role on the tag: the title in the company file (Company), else
## `person_role` (GameSession.person's when the session knows them).
func name_as(person_name: String, person_role: String) -> void:
	display_name = person_name
	role = Company.title(id, person_role)
	tag.text = display_name + ("\n" + role if not role.is_empty() else "")


## Go to `spot` ({at, face, pose[, route]}; {} or the spot they are at leaves them as
## they are): stand or sit there in its pose; a route is walked from its start.
func settle(spot: Dictionary) -> void:
	if spot.is_empty() or spot == _settled:
		return
	_settled = spot
	route = spot.get("route", PackedVector3Array())
	_leg = 1
	_wait = 0.0
	place(spot["at"], spot["face"])
	if spot["pose"] != pose:
		pose = spot["pose"]
		_float_overhead()
		_play(pose)


## Stand at `at` (office space, on the floor) facing `direction`.
func place(at: Vector3, direction: Vector3) -> void:
	position = at
	direction.y = 0
	if direction.length() > 0.01:
		basis = Basis.looking_at(direction.normalized(), Vector3.UP)
	_rest_yaw = rotation.y


func height() -> float:
	return SEATED_HEIGHT if pose == "sit" else STANDING_HEIGHT


## Whether they are in the office while these missions are active and those done.
func present_for(active_missions: Array, done: Dictionary = {}) -> bool:
	if not after.is_empty() and not after.any(func(m: String) -> bool: return done.has(m)):
		return false
	return missions.is_empty() or missions.any(func(m: String) -> bool: return m in active_missions)


func show_tag(on: bool) -> void:
	tag.visible = on


## The energy bar from GameSession.energy_of: {energy (0–1), needs_talk}. Shown, with the
## check-in mark, only while they need a talk; {} (no such accessor, an unknown person)
## hides it.
func show_energy(state: Dictionary) -> void:
	bar.visible = bool(state.get("needs_talk", false))
	mark.visible = bar.visible
	var was := tired
	tired = state.has("energy") and float(state["energy"]) < TIRED_ENERGY
	if tired != was and pose in ["idle", "sit"] and clip in ["idle", "sit", "tired", "sit_tired"]:
		_play(pose)
	if bar.visible:
		(bar.material_override as ShaderMaterial).set_shader_parameter("fill", clampf(float(state.get("energy", 0.5)), 0.0, 1.0))


## Whether a ray (office space) passes within PICK_RADIUS of their body's axis.
func picked_by(origin: Vector3, direction: Vector3) -> bool:
	var a := position + Vector3.UP * 0.3
	var b := position + Vector3.UP * height()
	var points := Geometry3D.get_closest_points_between_segments(origin, origin + direction * 200.0, a, b)
	return points[0].distance_to(points[1]) <= PICK_RADIUS


func _process(delta: float) -> void:
	if pose == "walk" and not held:
		walk(delta)
	else:
		turn(delta)
	if _say_left > 0.0:
		_say_left -= delta
		subtitle.visible = _say_left > 0.0
		subtitle.offset.y = SUBTITLE_LIFT if tag.visible else SUBTITLE_LIFT_ALONE


# ── Reacting ────────────────────────────────────────────────────────────────

## Turn to `at` (office space, e.g. the player): standing all the way, seated part of the
## way (SWIVEL); the turn itself happens over the next frames (turn). A walker walks on.
## `talk`: a talk starts (the camera cuts to them): at once, and seated as far as TALK_SWIVEL.
func face_toward(at: Vector3, talk := false) -> void:
	_look_at = at
	_talking = talk
	if talk:
		rotation.y = _goal_yaw()


## Back to their work: the turn eases back to their own yaw.
func face_back() -> void:
	_look_at = null
	_talking = false
	_turn_share = 1.0


## A talk holds them (OfficePeople.hold): a walker stops and stands.
func hold() -> void:
	held = true
	if pose == "walk":
		_play("idle")


## The talk is over: their own pose again (not the band's; a walker pausing at a route's
## end stands on), and back to their work.
func end_talk() -> void:
	held = false
	_play("idle" if pose == "walk" and _wait > 0.0 else pose)
	face_back()


## Whether they are turned to someone.
func facing() -> bool:
	return _look_at != null


## One frame of turning towards where they look (or back to their spot), at TURN_SPEED.
func turn(delta: float) -> void:
	var goal := _goal_yaw()
	if _hesitating > 0.0:
		_hesitating -= delta
		goal += HESITATE_TURN
	rotation.y = rotate_toward(rotation.y, goal, TURN_SPEED * delta)


## The yaw they turn to: towards _look_at (by _turn_share; seated within the swivel), else
## their own at their spot.
func _goal_yaw() -> float:
	if _look_at == null:
		return _rest_yaw
	var to: Vector3 = (_look_at as Vector3) - position
	if Vector2(to.x, to.z).length() <= 0.05:
		return _rest_yaw
	var off := angle_difference(_rest_yaw, atan2(-to.x, -to.z)) * _turn_share   # -Z is the front
	var swivel := TALK_SWIVEL if _talking else SWIVEL
	return _rest_yaw + (clampf(off, -swivel, swivel) if pose == "sit" else off)


## Their posture for a talk's openness band (0 Dicht … 4 Denkt mee, Dialog.band_of), with
## a short blend: see BAND_CLIPS. Dicht also turns them half away from whom they face.
func pose_for_band(band: int) -> void:
	band = clampi(band, 0, BAND_CLIPS.size() - 1)
	_turn_share = HALF_TURN if band == 0 else 1.0
	_play((SEATED_BAND_CLIPS if pose == "sit" else BAND_CLIPS)[band])


## A hesitation ("Er zit meer achter…"): a look away and back. Standing, the look-away clip
## plays once and they return to what they were doing; seated, they turn aside a moment.
func hesitate() -> void:
	_hesitating = HESITATE_SECONDS
	if pose != "sit" and _animations != null and _animations.has_animation("look_away"):
		var back := _animations.current_animation
		_animations.play("look_away", 0.2)
		if not back.is_empty() and back != "look_away":
			_animations.queue(back)


## Say `text` as a subtitle over their head for a few seconds (longer for a long line).
func say(text: String) -> void:
	subtitle.text = text
	_say_left = say_time(text)
	subtitle.visible = not text.is_empty()


## How long (s) a subtitle of `text` stays.
static func say_time(text: String) -> float:
	return maxf(SAY_SECONDS, text.length() * SAY_PER_CHAR)


## Whether a subtitle shows now.
func saying() -> bool:
	return subtitle.visible


## The clip the model plays now ("" for a stand-in without animations).
func playing() -> String:
	return _animations.current_animation if _animations != null else ""


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


## The tag, the bar and the mark over their head, at the height of their pose.
func _float_overhead() -> void:
	tag.position.y = height() + 0.3
	subtitle.position.y = tag.position.y   # over the tag by SUBTITLE_LIFT px, at any zoom
	bar.position.y = height() + 0.12
	mark.position.y = bar.position.y


## Play `animation` (a pose or a reaction clip) with a short blend: the tired version of the
## idle and the typing when tired, the nearest clip the model has when it lacks this one, and
## after a one-shot (the nod) the loop it settles into.
func _play(animation: String) -> void:
	if tired and animation in ["idle", "sit"]:
		animation = "tired" if animation == "idle" else "sit_tired"
	clip = animation
	if _animations == null:
		return
	if not _animations.has_animation(animation):
		animation = FALLBACK.get(animation, animation)
	if _animations.has_animation(animation):
		_animations.play(animation, 0.25)
		var then: String = SETTLES.get(animation, "")
		if not then.is_empty() and _animations.has_animation(then):
			_animations.queue(then)


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


static func _tag(text: String, font_size: int) -> Label3D:
	var l := Label3D.new()
	l.name = "NameTag"
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0006
	l.font_size = font_size
	l.outline_size = 10
	l.modulate = Color.WHITE
	l.outline_modulate = Palette.HUD_BAR
	l.visible = false
	return l


## The subtitle: the line in white on a dark outline, a little over the name tag, wrapped.
static func _subtitle() -> Label3D:
	var l := _tag("", 30)
	l.name = "Subtitle"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = 900
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM   # wrapped lines grow upwards, clear of the tag
	l.offset = Vector2(0, SUBTITLE_LIFT)
	l.outline_size = 12
	l.outline_modulate = Color(0.05, 0.06, 0.08)
	return l


static func _bar() -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = BAR_SIZE
	var shader := Shader.new()
	shader.code = BAR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("low_color", BAR_LINE)
	mat.set_shader_parameter("high_color", BAR_LINE)
	mat.set_shader_parameter("back_color", BAR_TRACK)
	var bar := MeshInstance3D.new()
	bar.name = "EnergyBar"
	bar.mesh = quad
	bar.material_override = mat
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.visible = false
	return bar


## A headset on `model`'s head that follows its Head bone: a band over the crown, an ear
## cup each side and a boom to the mouth (plain meshes; nothing without a Head bone).
static func _headset(model: Node3D) -> void:
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false).pop_front()
	var head := skeleton.find_bone("Head") if skeleton != null else -1
	if head < 0:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = HEADSET_COLOR
	mat.roughness = 0.5
	var c := HEADSET_CENTRE
	var r := HEADSET_RADIUS
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := Vector3(0, 0, 0.011)
	for k in 12:   # the band: a flat strip from ear to ear
		var p0 := c + Vector3(cos(PI * k / 12.0), sin(PI * k / 12.0), 0) * r
		var p1 := c + Vector3(cos(PI * (k + 1) / 12.0), sin(PI * (k + 1) / 12.0), 0) * r
		for v: Vector3 in [p0 - w, p1 - w, p1 + w, p0 - w, p1 + w, p0 + w]:
			st.add_vertex(v)
	st.generate_normals()
	var parts: Array[MeshInstance3D] = [_part(st.commit(), mat, Transform3D.IDENTITY)]
	var cup := CylinderMesh.new()
	cup.top_radius = 0.032
	cup.bottom_radius = 0.032
	cup.height = 0.022
	for side: float in [-1.0, 1.0]:
		parts.append(_part(cup, mat, Transform3D(Basis(Vector3.BACK, PI / 2), c + Vector3(side * r, 0, 0))))
	var stick := CapsuleMesh.new()
	stick.radius = 0.005
	stick.height = 0.12
	var from := c + Vector3(r, -0.01, 0.01)
	var to := c + Vector3(0.035, -0.085, 0.085)
	parts.append(_part(stick, mat, Transform3D(Basis.looking_at(to - from) * Basis(Vector3.RIGHT, PI / 2), (from + to) / 2)))
	var attach := BoneAttachment3D.new()
	attach.name = "Headset"
	attach.bone_name = "Head"
	skeleton.add_child(attach)
	var upright := Node3D.new()   # undo the bone's own turn: the parts are placed head-up
	upright.transform = Transform3D(skeleton.get_bone_global_rest(head).basis.inverse(), Vector3.ZERO)
	attach.add_child(upright)
	for part in parts:
		upright.add_child(part)


static func _part(mesh: Mesh, mat: Material, at: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
