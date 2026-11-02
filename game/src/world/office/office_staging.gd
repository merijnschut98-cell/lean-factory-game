class_name OfficeStaging
extends RefCounted
## Where the office's camera stands for a talk, a scene or a station (phase 2 design §2):
## the face shot while someone speaks, the two-shot of the pair while you choose, the
## pair followed on a walking talk, a station framed beside a docked panel; and the sight
## lines that keep a wall or a pillar from hiding a face. The office owns one (Office.staging);
## it reads the office's player, camera rig, people and walk grid each time.

## A talk is framed this far round (rad) from straight behind the player,
## towards the side the person faces, so their face shows beside the
## player's shoulder.
const TALK_ANGLE := 0.6
## The person's face this share of the screen's width right of the middle
## (the player's shoulder on the left).
const TALK_SHIFT := -0.08
## The person's face sits this far (m) under the top of their head.
const FACE_DROP := 0.2
## A face shot stands this far round (rad) from the line between the person
## and the player, so the player's head stays at the edge of the frame.
const FACE_ANGLE := 0.5
## The face this share of the screen's height above the middle while they
## speak, the pair while you choose (the subtitle and the sentences cover the
## bottom; estimates, tuned on the screenshots).
const FACE_LIFT := 0.06
const PAIR_LIFT := 0.12
## In a walking talk the person keeps this far (m) from the player.
const WALK_BESIDE := 1.3
## A scene's two-shot looks from the side with open floor behind the pair, up
## to this far (m): a wall nearer than that would hide them.
const SCENE_CLEAR := 3.0
## Where a shot looks for a body (m above the floor: waist, head), seated and standing.
const BODY_SEATED: Array[float] = [0.55, 1.15]
const BODY_STANDING: Array[float] = [0.9, 1.55]
## Half a body's width (m), shoulders and arms.
const BODY_HALF_WIDTH := 0.3
## A sight line ends this far (m) short of what it looks at: the chair or desk
## right beside a person does not hide them.
const SIGHT_SHORT := 0.3
## Framing a station: the point looked at lies this far (m) ahead of where
## the player stands, at desk-top height (the in-tray, the screens, the board).
const FRAME_AHEAD := 0.9
const FRAME_HEIGHT := 0.8

var office: Office
## The geometry's collision triangles, for sight lines (in_sight; empty until asked).
var _sight_faces := PackedVector3Array()


func _init(for_office: Office) -> void:
	office = for_office


## The floor changed or a door opened: the sight lines are measured again when next asked.
func forget_walls() -> void:
	_sight_faces = PackedVector3Array()


## Stage a talk (phase 2 design §2): someone in the office is talked with
## where they are (the player turns to them, their body takes the talk's
## band); someone not here makes it a phone call. Then the camera for the
## talk's phase (stage_talk).
func frame_talk(person_id: String) -> void:
	var person := office.people.person(person_id)
	var here := person != null and person.visible
	office.people.hold(person if here else null)
	if here and office.ride == null:   # in the van they sit side by side; the cab frames them (VanRide)
		turn_to(person)
		person.face_toward(office.player.position, true)   # they turn to you, so the face shot sees their face
	office.ui.talk_view.stage(person if here else null)
	stage_talk()


## The camera for the talk's phase: their face while they speak (over the
## player's shoulder where the floor is too tight for it), the two of you
## while you choose and after; walking, always the pair, following; on the
## phone the player where they stand. Only a walking talk lets the player walk.
func stage_talk() -> void:
	var view := office.ui.talk_view
	if not view.visible or view.talk.is_empty():
		return
	office.player.active = view.setting == TalkView.WALKING
	if view.setting == TalkView.HEADSET:
		return   # the camera stays on the desk where the player sits (interact frames it)
	if office.ride != null:
		office.ride.frame_talk(view.phase())
	elif view.person == null:
		office.rig.release()
	elif view.phase() == TalkView.SPEAK and view.setting == TalkView.STANDING:
		frame_face(view.person)
	else:
		_two_shot(view.person, PAIR_LIFT)


## A walking talk, each frame: the person keeps beside the player at their
## pace and the two-shot follows the pair.
func follow_walking_talk(delta: float) -> void:
	var view := office.ui.talk_view
	if not view.visible or view.setting != TalkView.WALKING or view.person == null:
		return
	var person := view.person
	var to_player := (office.player.position - person.position) * Vector3(1, 0, 1)
	var gap := to_player.length() - WALK_BESIDE
	if gap > 0.05:
		person.place(person.position + to_player.normalized() * minf(gap, person.pace * delta), to_player)
	_two_shot(person, PAIR_LIFT, true)


## Their face and shoulders while they speak, from a little to one side of
## the player: the side that sees more of their face, where the camera stands
## over open floor with nothing between it and the face (in_sight); a side over
## open floor when neither is clear; over the player's shoulder when neither has room.
func frame_face(person: OfficePerson) -> void:
	var rig := office.rig
	var face := talk_point(person)
	var to_player := (office.player.position - person.position) * Vector3(1, 0, 1)
	var toward := atan2(to_player.x, to_player.z)
	var faces := -person.basis.z
	var sides: Array[float] = [toward + FACE_ANGLE, toward - FACE_ANGLE]
	sides.sort_custom(func(a: float, b: float) -> bool: return Vector3(sin(a), 0, cos(a)).dot(faces) > Vector3(sin(b), 0, cos(b)).dot(faces))
	var reach := CameraRig.FACE_DISTANCE * cos(CameraRig.FACE_PITCH)
	sides = sides.filter(func(yaw: float) -> bool:
		return office.nav().walkable(face * Vector3(1, 0, 1) + Vector3(sin(yaw), 0, cos(yaw)) * reach))
	if sides.is_empty():
		rig.converse(face, talk_yaw(person, office.player.position), TALK_SHIFT, FACE_LIFT)
		return
	for yaw in sides:
		if in_sight(rig.view_from(face, yaw, CameraRig.FACE_DISTANCE, CameraRig.FACE_PITCH, FACE_LIFT), face):
			rig.face_shot(face, yaw, FACE_LIFT)
			return
	rig.face_shot(face, sides[0], FACE_LIFT)


## A scene's speaker and the player in one view (PLAN 2.13 A): the player
## turns to them and the camera looks down at the point between the two
## (_two_shot); `lift` of the screen's height above the middle.
func frame_scene(person: OfficePerson, lift: float) -> void:
	if not office.player.seated:   # seated at a table you face the table
		turn_to(person)
	_two_shot(person, lift)


## The camera looks down at the point between the player and `person`, from
## behind the player a little to the side when the floor is open there, else
## from the side with the most open floor (a wall close behind would hide them).
## Unless `anywhere` (a walking talk, reframed every step), it takes the first of
## those sides, then square to the pair, from which both are seen whole (a pillar
## or a wall between would hide one); none clear, the one with the most open floor.
func _two_shot(person: OfficePerson, lift: float, anywhere := false) -> void:
	var player := office.player
	var between := (player.position + person.position) / 2.0 * Vector3(1, 0, 1)
	var behind_player := atan2(player.position.x - person.position.x, player.position.z - person.position.z)
	var sides: Array = [talk_yaw(person, player.position), behind_player - TALK_ANGLE, behind_player + TALK_ANGLE,
		behind_player + PI - TALK_ANGLE, behind_player + PI + TALK_ANGLE]
	var room := sides.map(func(yaw: float) -> float: return _open_floor(between, yaw))
	var order := range(sides.size())
	order.sort_custom(func(a: int, b: int) -> bool: return room[a] > room[b] or (room[a] == room[b] and a < b))
	var yaws: Array = order.map(func(i: int) -> float: return sides[i])
	var at := between + Vector3.UP * CameraRig.FOCUS_HEIGHT
	if not anywhere:
		for yaw: float in yaws + [behind_player - PI / 2.0, behind_player + PI / 2.0]:
			var eye := office.rig.view_from(at, yaw, CameraRig.SCENE_DISTANCE, CameraRig.SCENE_PITCH, lift)
			if sees(eye, null) and sees(eye, person):
				office.rig.two_shot(at, yaw, lift)
				return
	office.rig.two_shot(at, yaws[0], lift)


## Whether a camera at `eye` sees `point` (office space): no wall, pillar or shut door of
## the geometry's collision crosses the line between them, up to SIGHT_SHORT before it.
func in_sight(eye: Vector3, point: Vector3) -> bool:
	if _sight_faces.is_empty():
		_sight_faces = office.collision_faces()
	var to := point + (eye - point).normalized() * SIGHT_SHORT
	for i in range(0, _sight_faces.size() - 2, 3):
		if Geometry3D.segment_intersects_triangle(eye, to, _sight_faces[i], _sight_faces[i + 1], _sight_faces[i + 2]) != null:
			return false
	return true


## Whether a camera at `eye` sees `person` (the player for null) whole: waist and head
## (lower when seated), each with its left and right edge.
func sees(eye: Vector3, person: OfficePerson) -> bool:
	var at := person.position if person != null else office.player.position
	var sits := person.pose == "sit" if person != null else office.player.seated
	var across := (at - eye).cross(Vector3.UP) * Vector3(1, 0, 1)
	across = across.normalized() * BODY_HALF_WIDTH if across.length() > 0.01 else Vector3.ZERO
	for h: float in BODY_SEATED if sits else BODY_STANDING:
		for side in [-1.0, 0.0, 1.0]:
			if not in_sight(eye, at + Vector3.UP * h + across * side):
				return false
	return true


## How far (m, up to SCENE_CLEAR) the floor runs open from `at` towards a
## camera at `yaw`: a wall close behind the pair would hide them.
func _open_floor(at: Vector3, yaw: float) -> float:
	var back := Vector3(sin(yaw), 0, cos(yaw))
	var free := 0.0
	while free < SCENE_CLEAR and office.nav().walkable(at + back * (free + 0.5)):
		free += 0.5
	return free


## The player turns to face `person`.
func turn_to(person: OfficePerson) -> void:
	var to_person := (person.position - office.player.position) * Vector3(1, 0, 1)
	if to_person.length() > 0.01:
		office.player.face(Basis.looking_at(to_person.normalized()))


## The camera's yaw for a talk: from behind the player standing `at`, turned
## TALK_ANGLE to whichever side sees more of the person's face.
func talk_yaw(person: OfficePerson, at: Vector3) -> float:
	var back := (at - person.position) * Vector3(1, 0, 1)
	var straight := atan2(back.x, back.z)
	var faces := -person.basis.z
	var left := straight + TALK_ANGLE
	var right := straight - TALK_ANGLE
	# the side whose camera stands more in front of the person
	return left if Vector3(sin(left), 0, cos(left)).dot(faces) >= Vector3(sin(right), 0, cos(right)).dot(faces) else right


## The point a talk looks at: the person's face.
func talk_point(person: OfficePerson) -> Vector3:
	return person.position + Vector3.UP * (person.height() - FACE_DROP)


## Frame a station with the camera: its desk, in-tray and board, close by,
## in the middle of the room a docked panel leaves.
func frame(target: Interactable) -> void:
	var ahead := -target.basis.z
	office.rig.inspect(frame_point(target), atan2(-ahead.x, -ahead.z), office.ui.docked_share() / 2.0)


## The point the camera looks at when it frames `target`.
func frame_point(target: Interactable) -> Vector3:
	var ahead := -target.basis.z
	ahead.y = 0
	return target.position + ahead.normalized() * FRAME_AHEAD + Vector3.UP * FRAME_HEIGHT
