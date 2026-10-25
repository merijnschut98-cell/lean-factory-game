class_name OfficePeople
extends Node3D
## The people on the loaded floor (PLAN 1.3, 2.1c), placed from the cast list (cast.json):
## at a workstation of the floor's model (<seat>_chair, facing <seat>_desk), on a chair
## (facing the way it faces), at a spot, or walking a route. Who is there follows the
## session: someone tied to missions is present only while one of them is active; someone
## who left (People.left: Henk retired, a colleague gone to another grid operator) is not
## there any more; nobody sits behind a shut door (a room's area, `shut`). The office keeps time (PLAN 2.14
## S1-A): with the session's clock (minute_of_day) each person keeps their own day
## (OfficeDay, cast.json `day:`): in by the lift or the stairs, coffee at the floor's
## coffee corner, lunch at their lunch spot (the kantine; their desk without one), home,
## or home late when the simulation keeps them (OfficeDay.late_ids). A change of place
## the clock has just reached is walked over the floor's walk grid (Office.nav) with the
## walk clip; an older one (the clock jumped) is simply done. Someone tied to missions
## keeps to the story, not the clock. A desk can move with the story (cast `moves`: Ruud
## back up to his own office on the 2e after the first hundred days). On the yard the vans have their say (OfficeYard.where):
## a monteur waits at their van for a ride, is out while their van is out, or stands where a
## mission puts them (the opleidingsterrein). Names and roles come from GameSession.person when
## the session knows the person (cast.json otherwise). The walk-around energy bar follows
## GameSession.energy_of when the session has it.

## Seconds between refreshes of who is present and who needs a talk.
const REFRESH_SECONDS := 0.5
## The coffee corner's table, by floor (the 1e's, the 2e's): people stand round it.
const COFFEE_TABLES: Array[String] = ["coffee_table", "coffee2_table"]
## Standing round the coffee table: this far (m) from its middle, in this many places,
## the first this far round (rad) from +X; the counter's side (-X) is left free.
const COFFEE_RADIUS := 0.95
const COFFEE_PLACES := 5
const COFFEE_FIRST := -2.2
const COFFEE_ARC := TAU * 0.75
## The ways onto a floor: the lift and the stairs; the yard's door where there are none.
const WAYS_IN: Array[String] = ["arrive:lift", "arrive:stairs_down", "arrive:stairs_up"]
const YARD_DOOR := "arrive:exit"
## The front door: people whose desk is on this floor come in and go home through it.
const ENTRANCE := "arrive:entrance"
## A walk to or from a seat starts or ends this far (m) behind the chair, in the aisle.
const AISLE := 0.7
## People coming in by the same way at the same time step out this many seconds apart.
const STAGGER := 1.6
## Where someone without a clock to keep is (a session without one, the story), and
## someone the opening's evening has sent home.
const ALWAYS_AT_DESK := {"place": OfficeDay.DESK, "since": -SimCalendar.MINUTES_PER_DAY}
const ALWAYS_OUT := {"place": OfficeDay.OUT, "since": -SimCalendar.MINUTES_PER_DAY}

var people: Array[OfficePerson] = []
## Who is in a talk with the player (OfficeStaging.frame_talk), or null: they stay for it.
var held: OfficePerson
## Whether holding them stopped them on their way (release walks them on).
var _stopped := false
## The floor areas (x, z) of the floor's shut rooms (OfficeFloors.shut_rects).
var shut: Array[Rect2] = []
## Each person's day by id.
var days: Dictionary[String, OfficeDay] = {}
## Only these are in, whatever the clock (the opening's evening: Anouk); [] for the day.
var stay_in: Array[String] = []
## These are elsewhere in the building, whatever the clock (a milestone's scene: OfficeMilestone).
var away: Array[String] = []
var office: Office
var _since_refresh := 0.0
var _session: Object
## The session the names were last taken from.
var _named_by: Object
## Where each person is by their day (OfficeDay's places), by id.
var _place: Dictionary[String, String] = {}
## Whether each person is on this floor now (at a spot or walking), by id.
var _here: Dictionary[String, bool] = {}
## The walks under way by id: {who, path, leg (the corner walked to), to (the spot, or {}
## to leave the floor), started (the minute), wait (seconds before stepping out)}.
var _trips: Dictionary[String, Dictionary] = {}
## Who stays late today, and the day that was decided for.
var _late := {}
var _late_day := -1
var _late_for: Object
## The coffee tables' middles on this floor (office space, on the floor), found once.
var coffee_corners: Array[Vector3] = []
## The coffee table people go to (the first corner), or null; who stands at which place round it.
var _coffee: Variant = null
var _at_coffee: Dictionary[int, String] = {}
## The ways onto this floor (WAYS_IN found) and the front door (or null).
var _ways: Array[Vector3] = []
var _entrance: Variant = null
## Seconds until the next person may step out of each way onto this floor.
var _queues: Dictionary[Vector3, float] = {}


## The cast's people with a spot on this floor (`here` tells whether a spot's floor is
## the loaded one), placed in `office` (its geometry must be loaded). Someone whose desk
## cannot be found is left out, with a warning.
static func build(office: Office, cast: Array[Dictionary], here: Callable) -> OfficePeople:
	var out := OfficePeople.new()
	out.name = "People"
	out.office = office
	out._find_places(office)
	for entry in cast:
		var at_desk: Dictionary = entry.get("office", {})
		var at_lunch: Variant = at_desk.get("lunch")
		var lunch_here: bool = at_lunch is Dictionary and here.call(at_lunch)
		var desk_here: bool = not at_desk.is_empty() and here.call(at_desk)
		var moves: Variant = at_desk.get("moves")
		var moved_here: bool = moves is Dictionary and here.call(moves)
		if not (desk_here or lunch_here or moved_here):
			continue
		var p := OfficePerson.create(entry)
		if desk_here:
			p.desk = _spot(office, at_desk, p.pose)
			p.spots = OfficeYard.spots_of(p, func(spot: Dictionary) -> Dictionary: return _spot(office, spot, p.pose))
		if moved_here:
			p.moved_desk = _spot(office, moves, p.pose)
		if (desk_here and p.desk.is_empty()) or (moved_here and p.moved_desk.is_empty()):
			push_warning("office: no place for %s" % p.id)
			p.free()
			continue
		p.home_desk = p.desk
		if at_lunch is Dictionary:
			p.lunch = _spot(office, at_lunch, p.pose) if lunch_here else {}
		p.settle(p.desk)
		p.visible = p.visible and not p.desk.is_empty()
		out._here[p.id] = not p.desk.is_empty()
		var problems: Array[String] = []
		out.days[p.id] = OfficeDay.from_entry(entry, problems)
		for problem in problems:
			push_warning(problem)
		out.people.append(p)
		out.add_child(p)
	return out


func person(id: String) -> OfficePerson:
	for p in people:
		if p.id == id:
			return p
	return null


## The nearest present person within `reach` on the floor of `at`, or null.
func person_near(at: Vector3, reach: float) -> OfficePerson:
	var best: OfficePerson = null
	var best_distance := reach
	for p in people:
		var d := Vector2(at.x - p.position.x, at.z - p.position.z).length()
		if p.visible and d <= best_distance:
			best = p
			best_distance = d
	return best


## The present person a ray (office space) points at, the nearest along it, or null.
func person_under(origin: Vector3, direction: Vector3) -> OfficePerson:
	var best: OfficePerson = null
	var best_distance := INF
	for p in people:
		var d := origin.distance_to(p.position)
		if p.visible and d < best_distance and p.picked_by(origin, direction):
			best = p
			best_distance = d
	return best


## `p` is in a talk with the player (null: nobody here, a call); whoever was before lets
## go. Their day waits while the talk lasts: someone on their way stops where they are and
## stands, a walker stops their round.
func hold(p: OfficePerson) -> void:
	if p == held:
		return
	release()
	held = p
	if p == null:
		return
	p.hold()
	if _trips.has(p.id):
		_trips.erase(p.id)
		_stopped = true
		p.settle({"at": p.position, "face": -p.basis.z, "pose": "idle"})


## The talk is over: who was held drops the talk's posture and goes back to their day,
## walking on from where they stopped.
func release() -> void:
	var p := held
	var stopped := _stopped
	held = null
	_stopped = false
	if p == null or not is_instance_valid(p):
		return
	p.end_talk()
	if stopped and _session != null:
		var minute := _minute_of(_session)
		_go(p, _where(p, minute) if minute >= 0 else ALWAYS_AT_DESK, minute, true)


## Name tags on for these people only.
func show_tags(on: Array[OfficePerson]) -> void:
	for p in people:
		p.show_tag(p in on)


## Who is where and who needs a talk, from the session: its active missions, the hour
## (minute_of_day, when it has it: each person's day), the names it knows (person) and
## energy_of (otherwise no bars).
func refresh(session: Object) -> void:
	_session = session
	if session != _named_by:
		_named_by = session
		_name_from(session)
	var active: Array = []
	if session.has_method("active_missions"):
		active = session.call("active_missions").map(func(m: MissionDef) -> String: return m.id)
	var missions: Variant = session.get("missions")
	var done: Dictionary = missions.done_once if missions is Missions else {}
	var people_of: Variant = session.get("people")
	var gone: Dictionary = (people_of as People).left if people_of is People else {}
	var minute := _minute_of(session)
	if minute >= 0:
		_decide_late(session)
	var energy := session.has_method("energy_of")
	for p in people:
		_move_desk(p, done)
		var where := _where(p, minute) if minute >= 0 else ALWAYS_AT_DESK
		if p != held:
			_go(p, where, minute)
		p.at_lunch = where["place"] == OfficeDay.LUNCH and p.lunch is Dictionary
		var shut_out := not _trips.has(p.id) and _behind_shut_door(p.position)
		p.visible = _here.get(p.id, false) and p.present_for(active, done) and not gone.has(p.id) and not shut_out
		var state: Variant = session.call("energy_of", p.id) if energy and p.visible else {}
		p.show_energy(state if state is Dictionary else {})


## `p`'s desk before or after it moves (cast `moves`), by the missions done; on a new desk
## they are simply there (or off this floor), never walked over from the old one.
func _move_desk(p: OfficePerson, done: Dictionary) -> void:
	if p.moves_after.is_empty():
		return
	var desk := p.moved_desk if p.has_moved(done) else p.home_desk
	if desk == p.desk:
		return
	p.desk = desk
	_place.erase(p.id)
	_trips.erase(p.id)


## The session's minute of the day; -1 when it keeps no clock.
static func _minute_of(session: Object) -> int:
	return session.call("minute_of_day") if session.has_method("minute_of_day") else -1


## Where `person` is by their day at `minute` (OfficeDay's places: out, desk, coffee, lunch).
func place_for(person: OfficePerson, minute: int) -> String:
	return _where(person, minute)["place"]


func day_of(id: String) -> OfficeDay:
	return days[id] if days.has(id) else OfficeDay.defaults(id)


## {place, since}: the opening's evening (stay_in), the story for someone tied to
## missions, else their day (late or not).
func _where(p: OfficePerson, minute: int) -> Dictionary:
	if not stay_in.is_empty():
		return ALWAYS_AT_DESK if p.id in stay_in else ALWAYS_OUT
	if p.id in away:
		return ALWAYS_OUT
	var yard := OfficeYard.where(p, _session, office.floors.building.rides if office != null and office.floors != null else [],
		minute)
	if not yard.is_empty():
		return yard
	if not p.missions.is_empty():
		return ALWAYS_AT_DESK
	return day_of(p.id).place_at(minute, _late.has(p.id))


## Who stays late, decided once a day (the region's day when the session has one).
func _decide_late(session: Object) -> void:
	var region: Variant = session.get("region")
	var day := floori((region as Region).net.time / float(SimCalendar.MINUTES_PER_DAY)) if region is Region else 0
	if day == _late_day and session == _late_for:
		return
	_late_day = day
	_late_for = session
	_late = OfficeDay.late_ids(session, days.keys())


## To the place `where` names: walked when the clock has just reached it, else simply
## there (the first refresh, a jump of the clock). `walk_on`: walked from where they stand
## whatever the clock did (someone a talk stopped on their way).
func _go(p: OfficePerson, where: Dictionary, minute: int, walk_on := false) -> void:
	var place: String = where["place"]
	if place == _place.get(p.id, "") and not walk_on:
		var trip: Variant = _trips.get(p.id)
		if trip != null and (minute - int(trip["started"]) >= OfficeDay.WALK_WINDOW or minute < int(trip["started"])):
			_finish(p)
		return
	var first := not _place.has(p.id)
	var by_door := OfficeDay.OUT in [place, _place.get(p.id, "")]
	_place[p.id] = place
	var stood: Variant = _at_coffee.find_key(p.id)
	if stood != null:
		_at_coffee.erase(stood)
	var to := _spot_for(p, place)
	var age := minute - int(where["since"])
	if office == null or (not walk_on and (first or age < 0 or age >= OfficeDay.WALK_WINDOW)):
		_arrive(p, to)
	else:
		_walk(p, to, minute, by_door)


## The spot of a place on this floor ({} when it is on another floor, or out).
func _spot_for(p: OfficePerson, place: String) -> Dictionary:
	match place:
		OfficeDay.OUT:
			return {}
		OfficeDay.LUNCH:
			return p.lunch if p.lunch is Dictionary else p.desk
		OfficeDay.COFFEE:
			return _coffee_spot(p) if _coffee != null and not p.desk.is_empty() else p.desk
	return p.spots.get(place, p.desk)


## A free place round the coffee table, facing it, talking.
func _coffee_spot(p: OfficePerson) -> Dictionary:
	var k := 0
	while _at_coffee.has(k):
		k += 1
	if k >= COFFEE_PLACES:
		k = absi(p.id.hash()) % COFFEE_PLACES
	_at_coffee[k] = p.id
	var table: Vector3 = _coffee
	var angle := COFFEE_FIRST + k * COFFEE_ARC / (COFFEE_PLACES - 1)
	var at := table + Vector3(cos(angle), 0, sin(angle)) * COFFEE_RADIUS
	return {"at": at, "face": table - at, "pose": "talk"}


## There at once: settled at `to`, or off this floor ({}).
func _arrive(p: OfficePerson, to: Dictionary) -> void:
	_trips.erase(p.id)
	_here[p.id] = not to.is_empty()
	if to.is_empty():
		p.visible = false
	else:
		p.settle(to)


## Walk to `to` over the walk grid: from where they stand, or in by a way onto this floor
## when they were not on it; to a way off it when `to` is elsewhere ({}). `by_door`: they
## come in from home or go home.
func _walk(p: OfficePerson, to: Dictionary, minute: int, by_door: bool) -> void:
	var here: bool = _here.get(p.id, false)
	var way: Variant = _way_for(p, by_door)
	if way == null or (not here and to.is_empty()):
		_arrive(p, to)
		return
	var from: Vector3 = p.position if here else way
	var goal: Vector3 = way if to.is_empty() else to["at"]
	# Seats sit between desks and tables: the walk grid is joined behind the chair.
	var start := from + p.basis.z * AISLE if here and p.pose == "sit" else from
	var end := goal - (to["face"] as Vector3).normalized() * AISLE if to.get("pose") == "sit" else goal
	var path := office.nav().path(start, end) if start.distance_to(end) > 0.05 else PackedVector3Array()
	if path.is_empty():
		_arrive(p, to)
		return
	if start != from:
		path.insert(0, start)
	for corner: Vector3 in [end, goal]:
		if path[path.size() - 1].distance_to(corner) > 0.01:
			path.append(corner)
	# Those coming in by the same way at once step out one after the other, not as one body.
	var wait: float = 0.0 if here else _queues.get(from, 0.0)
	if not here:
		_queues[from] = wait + STAGGER
	_here[p.id] = wait <= 0.0
	p.settle({"at": from, "face": path[0] - from, "pose": "walk"})
	_trips[p.id] = {"who": p, "path": path, "leg": 0, "to": to, "started": minute, "wait": wait}


## The way onto or off this floor for `p`: the front door for someone whose desk is on
## this floor coming in from home or going home, else the lift or the stairs (theirs, by
## id); null when the floor has neither.
func _way_for(p: OfficePerson, by_door: bool) -> Variant:
	if _entrance != null and not p.desk.is_empty() and by_door:
		return _entrance
	return _ways[absi(p.id.hash()) % _ways.size()] if not _ways.is_empty() else _entrance


## One frame of a walk: along the path at their walking pace; at its end they settle at
## the spot, or leave the floor.
func _step(p: OfficePerson, trip: Dictionary, delta: float) -> void:
	if trip["wait"] > 0.0:   # still in the lift or on the stairs, behind someone
		trip["wait"] -= delta
		_here[p.id] = trip["wait"] <= 0.0
		return
	var path: PackedVector3Array = trip["path"]
	var left := p.pace * delta
	while left > 0.0 and int(trip["leg"]) < path.size():
		var to := path[trip["leg"]] - p.position
		to.y = 0
		var d := to.length()
		if d <= left:
			p.place(path[trip["leg"]], to)
			left -= d
			trip["leg"] = int(trip["leg"]) + 1
		else:
			p.place(p.position + to / d * left, to)
			left = 0.0
	if int(trip["leg"]) >= path.size():
		_finish(p)


func _finish(p: OfficePerson) -> void:
	_arrive(p, _trips[p.id]["to"])


## Where the desk lamps go (office space, on the floor): the desk of everyone sitting at
## their own workstation now (OfficeDaylight lights them in the evening).
func lamp_spots() -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in people:
		if p.visible and not _trips.has(p.id) and _place.get(p.id, OfficeDay.DESK) == OfficeDay.DESK and p.desk.has("lamp"):
			out.append(p.desk["lamp"])
	return out


## The coffee table and the ways onto this floor, from its markers.
func _find_places(at: Office) -> void:
	for id in COFFEE_TABLES:
		var table := at.find_marker(id)
		if table != null:
			coffee_corners.append(at.in_office(table).origin * Vector3(1, 0, 1))
	if not coffee_corners.is_empty():
		_coffee = coffee_corners[0]
	var markers := at.floors.markers() if at.floors != null else {}
	var on_floor := func(id: String) -> Vector3: return at.in_office(markers[id]).origin * Vector3(1, 0, 1)
	for id in WAYS_IN:
		if markers.has(id):
			_ways.append(on_floor.call(id))
	if _ways.is_empty() and markers.has(YARD_DOOR):
		_ways.append(on_floor.call(YARD_DOOR))
	if markers.has(ENTRANCE):
		_entrance = on_floor.call(ENTRANCE)


## Names and roles from the session for the people it knows (one source, PLAN 1.3).
func _name_from(session: Object) -> void:
	if not session.has_method("person"):
		return
	for p in people:
		var known: Variant = session.call("person", p.id)
		if known is Dictionary and not str(known.get("name", "")).is_empty():
			p.name_as(str(known["name"]), str(known.get("role", p.role)))


func _behind_shut_door(at: Vector3) -> bool:
	return shut.any(func(r: Rect2) -> bool: return r.has_point(Vector2(at.x, at.z)))


func _process(delta: float) -> void:
	for way: Vector3 in _queues.keys():
		_queues[way] = maxf(0.0, _queues[way] - delta)
	for trip: Dictionary in _trips.values():
		_step(trip["who"], trip, delta)
	_since_refresh += delta
	if _session != null and _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh(_session)


## Where a cast spot is in the office: {at, face, pose[, route]}, or {} when its markers
## are not on the loaded floor. `pose` when the spot names none.
static func _spot(office: Office, spot: Dictionary, pose: String) -> Dictionary:
	var out := {"pose": str(spot.get("pose", pose))}
	if spot.has("seat") or spot.has("chair"):
		# at a workstation the user faces the desk, else the way the chair faces: both
		# along their -Z (the kits' +Y in Blender)
		var seat := str(spot.get("seat", ""))
		var chair := office.find_marker(seat + "_chair" if not seat.is_empty() else str(spot["chair"]))
		var facing := office.find_marker(seat + "_desk") if not seat.is_empty() else chair
		if chair == null or facing == null:
			return {}
		out.merge({"at": office.in_office(chair).origin * Vector3(1, 0, 1), "face": -office.in_office(facing).basis.z})
		if not seat.is_empty():   # their own workstation: a desk lamp in the evening
			out["lamp"] = office.in_office(facing).origin * Vector3(1, 0, 1)
	elif spot.has("route"):
		var route := PackedVector3Array()
		for corner: Variant in spot["route"]:
			route.append(_floor(corner))
		if route.size() < 2:
			return {}
		out.merge({"at": route[0], "face": route[1] - route[0], "route": route})
	elif spot.has("at"):
		var at := _floor(spot["at"])
		out.merge({"at": at, "face": _floor(spot.get("face", [at.x, at.z - 1.0])) - at})
	elif spot.get("van") is float or spot.get("van") is int:   # by their van (the yard's driver:van<k>)
		var door := office.find_marker("driver:van%d" % int(spot["van"]))
		if door == null:
			return {}
		var t := office.in_office(door)
		out.merge({"at": t.origin * Vector3(1, 0, 1), "face": -t.basis.z})
	else:
		return {}
	return out


## [x, z] in the office's space as a floor point.
static func _floor(xz: Variant) -> Vector3:
	if xz is Array and xz.size() == 2:
		return Vector3(float(xz[0]), 0, float(xz[1]))
	return Vector3.ZERO
