class_name OfficeMilestone
extends Node
## A milestone's scene in the world (phase-2 design §3.1): when a scene milestone is
## active, the people it names wait in its room (the MT-kamer for Honderd dagen), and
## walking in plays it as SceneLines: the lines the facts chose (GameSession.scene_of),
## the one question with its answers, what is said back, the rest. Then the milestone
## completes (GameSession.finish_scene) and the people leave. No score screen.
## A room with scene spots in its model (`scene:<room>:<spot>`, PLAN 2.16) is a stage: the
## one the scene names `stands` presents beside the screen, the others sit round the table
## (seat0, seat1, ...), and walking in you sit down at yours; the camera is on whoever
## speaks, and on the two of you while you answer. They are not at their desks meanwhile.

## How often (s) it looks whether the player walked into a scene's room.
const POLL_SECONDS := 0.5
## The people stand this far (m) apart, across the room's middle from the door side.
const SPACING := 1.4
## They wait this far (m) into the room from its door.
const INSIDE_DOOR := 3.5
## At a table the two-shot sits this share of the screen's height above the middle, so the
## others at the table stay clear of the question and its answers (an estimate, tuned on
## play_mt_room_scene).
const TABLE_LIFT := 0.16

var office: Office
var lines: SceneLines
## The milestone whose scene plays now ("" for none), its scene and the answer chosen.
var playing := ""
var _scene: Dictionary = {}
var _answer := -1
var _asked := false
## The people waiting in the room now, by cast id; the milestone they wait for.
var _people: Dictionary = {}
var _waiting_for := ""
var _since_poll := 0.0
var _holding := false
## Who the camera frames now, and whether as the one asking ("" for none).
var _framed := ""


static func create(of_office: Office) -> OfficeMilestone:
	var m := OfficeMilestone.new()
	m.name = "Milestone"
	m.office = of_office
	m.lines = SceneLines.new()
	m.lines.auto = SceneLines.auto_setting()
	m.lines.lines_done.connect(m._on_lines_done)
	m.lines.chosen.connect(m._on_chosen)
	of_office.ui.hud.add_child(m.lines)
	return m


func _process(delta: float) -> void:
	step(delta)


## One frame (tests call it with their own dt).
func step(dt: float) -> void:
	lines.step(dt)
	_hold()
	_since_poll += dt
	if not playing.is_empty() or _since_poll < POLL_SECONDS:
		return
	_since_poll = 0.0
	var m := waiting()
	_place_people(m)
	var away: Array[String] = []
	away.assign(_people.keys())
	if office.people != null and office.people.away != away:   # also after a floor change made them anew
		office.people.away = away
		office.people.refresh(office.session)
	if m != null and in_room(_room_of(m)):
		start(m.id)


## The active scene milestone whose room is on the loaded floor, or null.
func waiting() -> MissionDef:
	var markers := office.floors.markers()
	for m in office.session.missions.active("milestone"):
		if m.goal_type == "scene" and markers.has("room:" + _room_of(m)):
			return m
	return null


## Whether the player stands in room `room_id` of the loaded floor.
func in_room(room_id: String) -> bool:
	var marker: Node = office.floors.markers().get("room:" + room_id)
	var at := office.player.position
	return marker != null and OfficeFloors.room_rect(marker).has_point(Vector2(at.x, at.z))


## Play milestone `mission_id`'s scene from its first line.
func start(mission_id: String) -> void:
	_scene = office.session.scene_of(mission_id)
	if _scene.is_empty():
		return
	playing = mission_id
	_answer = -1
	_asked = false
	var seat := _spot("player")
	if seat != null:   # "Kom erbij zitten"
		office.player.sit_at(office.in_office(seat))
	lines.say(_said(_scene["before"]))
	if _scene["before"].is_empty():
		_on_lines_done()


func _on_lines_done() -> void:
	if playing.is_empty():
		return
	var choice: Dictionary = _scene["choice"]
	if _answer < 0 and not choice.is_empty():
		if _asked:
			return  # the pick ends the question's line first; `chosen` follows
		_asked = true
		var labels: Array[String] = []
		labels.assign(choice["options"].map(func(o: Dictionary) -> String: return o["label"]))
		lines.ask(choice["name"], choice["text"], labels)
		return
	var refused := office.session.finish_scene(playing, _answer)
	if not refused.is_empty():
		push_warning("milestone %s: %s" % [playing, refused])
	playing = ""
	_scene = {}
	office.player.stand_up()
	_place_people(null)
	office.ui.after_action()


func _on_chosen(index: int) -> void:
	_answer = index
	var said: Array[Dictionary] = []
	var reply: String = _scene["choice"]["options"][index]["reply"]
	if not reply.is_empty():
		said.append({"who": _scene["choice"]["name"], "text": reply})
	said.append_array(_said(_scene["after"]))
	if said.is_empty():
		_on_lines_done()
	else:
		lines.say(said)


static func _said(scene_lines: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for l: Dictionary in scene_lines:
		out.append({"who": l["name"], "text": l["text"]})
	return out


func _room_of(m: MissionDef) -> String:
	return str(office.session.catalog.scenes.get(m.scene, {}).get("room", ""))


## The scene spot `spot` of the room whose scene waits or plays (null without one).
func _spot(spot: String) -> Node3D:
	var m: MissionDef = office.session.missions.defs.get(_waiting_for)
	return office.floors.markers().get("scene:%s:%s" % [_room_of(m), spot]) if m != null else null


## The people of `m`'s scene stand in its room while it waits; none for null.
func _place_people(m: MissionDef) -> void:
	var id := m.id if m != null else ""
	if id == _waiting_for:
		return
	for p: OfficePerson in _people.values():
		p.queue_free()
	_people.clear()
	_waiting_for = id
	if m == null:
		return
	var markers := office.floors.markers()
	var centre := OfficeFloors.room_rect(markers.get("room:" + _room_of(m))).get_center()
	var inside := Vector3(centre.x, 0.0, centre.y)
	var door: Node3D = markers.get("door:" + _room_of(m))
	if door != null:   # between the door and the table, facing whoever comes in
		var at_door := office.in_office(door).origin * Vector3(1, 0, 1)
		inside = at_door + (inside - at_door).normalized() * minf(INSIDE_DOOR, at_door.distance_to(inside))
	var across := (inside - Vector3(centre.x, 0.0, centre.y)).cross(Vector3.UP).normalized()
	var scene: Dictionary = office.session.catalog.scenes[m.scene]
	var present: Array = scene.get("present", [])
	var seated := 0
	for i in present.size():
		var who := str(present[i])
		var p := OfficePerson.create({"id": who, "name": office.session.speaker_name(who), "role": "",
			"office": {"pose": "idle"}})
		p.name = "Scene" + who.capitalize()
		p.tag.visible = false
		p.bar.visible = false
		p.mark.visible = false
		office.add_child(p)
		_people[who] = p
		var stands := who == str(scene.get("stands", ""))
		var spot := _spot("screen" if stands else "seat%d" % seated)
		if spot != null:   # the room is a stage
			var t := office.in_office(spot)
			p.settle({"at": t.origin * Vector3(1, 0, 1), "face": -t.basis.z, "pose": "talk" if stands else "sit"})
			if not stands:
				seated += 1
				p.pose_for_band(2)   # seated, turned to the table, talking
			continue
		var at := inside + across * (i - (present.size() - 1) / 2.0) * SPACING
		var facing := (at - Vector3(centre.x, 0.0, centre.y)) if door == null else (office.in_office(door).origin - at)
		p.place(at, facing * Vector3(1, 0, 1))


## While a line or the question is up the player stands (or sits) still, the camera on
## whoever speaks (their face), and on the two of you while you answer them.
func _hold() -> void:
	var holds := lines.holds()
	if holds != _holding:
		_holding = holds
		_framed = ""
		office.hold_for_scene(holds)
	var who := str(lines.current().get("who", "")) if holds else ""
	var framing := who + ("?" if lines.asking() else "")
	if framing == _framed:
		return
	_framed = framing
	for id: String in _people:
		if office.session.speaker_name(id) != who:
			continue
		if lines.asking() or not office.player.seated:
			office.frame_scene(_people[id], TABLE_LIFT if office.player.seated else OfficeOpening.FRAME_LIFT)
		else:
			office.frame_face(_people[id])
