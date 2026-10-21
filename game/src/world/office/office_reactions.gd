class_name OfficeReactions
extends Node
## People notice you (Phase 2 design §1.4): whoever is within OfficePerson.NOTICE of the
## player turns to them, and back to their work once they have passed; the first time a
## day the nearest of them says good morning by your name (GameSession.greet, a subtitle);
## and two colleagues at a coffee corner talk between themselves when you come within
## CHATTER_REACH (GameSession.chatter: two lines, one over each of them, one after the
## other). Nothing here while a panel or a scene holds the world, or during the first
## day's scene. The office owns one; it reads the floor's people each time, so it outlives
## the floor changes.

## Seconds between looks at who is near.
const TICK := 0.25
## The coffee corners: their table markers in the floor models (build_office.py), and how
## far (m) from one a person still stands at it.
const CORNERS: Array[String] = ["coffee_table", "coffee2_table"]
const CORNER_RADIUS := 2.0
## How close (m) the player must be to a corner to hear the chatter.
const CHATTER_REACH := 4.0

var office: Office
var _since := 0.0
## The second line of a chatter waiting for the first to finish: {person, text, in (s)}.
var _reply := {}


static func create(for_office: Office) -> OfficeReactions:
	var r := OfficeReactions.new()
	r.name = "Reactions"
	r.office = for_office
	return r


func _process(delta: float) -> void:
	if not _reply.is_empty():
		_reply["in"] -= delta
		if _reply["in"] <= 0.0:
			if is_instance_valid(_reply["person"]):
				(_reply["person"] as OfficePerson).say(_reply["text"])
			_reply = {}
	_since += delta
	if _since >= TICK:
		_since = 0.0
		react()


## One look round: turn, greet, chatter.
func react() -> void:
	if office.people == null or office.session == null or not office.session.error.is_empty() \
			or office.world_waits() or office.first_day != null:
		return
	var at := office.player.position
	var nearest: OfficePerson = null
	for p: OfficePerson in office.people.people:
		var near := p.visible and _floor_distance(p.position, at) <= OfficePerson.NOTICE
		if near:
			p.face_toward(at)
			if nearest == null or _floor_distance(p.position, at) < _floor_distance(nearest.position, at):
				nearest = p
		elif p.facing():
			p.face_back()
	if nearest != null and not nearest.saying():
		var hello := office.session.greet(nearest.id)
		if not hello.is_empty():
			nearest.say(hello)
	chatter(at)


## Two people at a corner the player is near say their exchange (once a day per pair).
func chatter(at: Vector3) -> void:
	if not _reply.is_empty():
		return
	for corner in corner_points():
		if _floor_distance(corner, at) > CHATTER_REACH:
			continue
		var there := at_corner(corner)
		if there.size() < 2 or there.any(func(p: OfficePerson) -> bool: return p.saying()):
			continue
		var lines := office.session.chatter(there[0].id, there[1].id)
		if lines.size() == 2:
			there[0].say(lines[0])
			_reply = {"person": there[1], "text": lines[1], "in": OfficePerson.say_time(lines[0])}
			return


## The present people within CORNER_RADIUS of `corner`, nearest first.
func at_corner(corner: Vector3) -> Array[OfficePerson]:
	var out: Array[OfficePerson] = []
	for p: OfficePerson in office.people.people:
		if p.visible and _floor_distance(p.position, corner) <= CORNER_RADIUS:
			out.append(p)
	out.sort_custom(func(a: OfficePerson, b: OfficePerson) -> bool:
		return _floor_distance(a.position, corner) < _floor_distance(b.position, corner))
	return out


## The coffee corners on the loaded floor (office space, on the floor).
func corner_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for marker in CORNERS:
		var node := office.find_marker(marker)
		if node != null:
			out.append(office.in_office(node).origin * Vector3(1, 0, 1))
	return out


static func _floor_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
