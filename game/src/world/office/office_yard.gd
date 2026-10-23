class_name OfficeYard
extends Node
## The yard by the hour (PLAN 2.2; spec 2026-10-17-the-yard.md §5): the monteurs take their
## vans out in the morning and bring them back in the afternoon. Before 07:45 and from 16:15
## every bay holds a van; in between only the storingsbussen on call stay, and a van whose
## monteur waits to take you along (a ride). A child of the Office while the yard is loaded;
## it reads the session's clock.
##
## The van ride (PLAN 2.15 S2-Y; design 2026-10-21 §1.7): a side with a ride (world.yaml
## `rides`) has its monteur wait at their van (cast.json `office.van`) until you have ridden
## with them once in it; E at the van's passenger door ("ride:<mission>") starts the ride
## (VanRide). The monteurs' places by the vans are decided here (where): waiting at their van,
## out while their van is out, or where a mission puts them (cast `during`: Henk and Ahmed at
## the opleidingsterrein). OfficePeople asks; the Office routes the ride doors here (use,
## prompt, label), as it does the floors' seams.

## The storingsbussen (van0, van1): on call, they stay in the yard all day.
const ON_CALL: Array[int] = [0, 1]
const VANS := 6
## Out from (minutes since midnight) and back at.
const OUT := 7 * 60 + 45
const BACK := 16 * 60 + 15
## Seconds between looks at the clock.
const POLL_SECONDS := 1.0
## The ride's door: an interaction point "ride:<mission>" at its van's passenger door.
const RIDE := "ride"
## A monteur's places on the yard (OfficePeople spots): at their van, and where a mission
## puts them ("during:<mission>").
const AT_VAN := "at_van"
const DURING := "during:"
## A place taken at once, not walked to (OfficePeople: older than its walk window): a van
## drives off with its monteur, and the ride's end moves people while you are away.
const AT_ONCE := -SimCalendar.MINUTES_PER_DAY
const PROMPT := "E — Meerijden met %s"
const LABEL := "Meerijden met %s"

var office: Office
var _since := INF


## Park the vans in `geometry` (the yard's model) as they stand at `minute`; the vans in
## `kept` stay in (a monteur waits there for you).
static func park(geometry: Node, minute: int, kept: Array[int] = []) -> void:
	var out := out_at(minute)
	for k in VANS:
		var van := Office._find_marker(geometry, "van%d" % k, Office._loose("van%d" % k))
		if van != null:
			van.visible = not out or k in ON_CALL or k in kept


## Whether the vans are out at `minute`.
static func out_at(minute: int) -> bool:
	return minute >= OUT and minute < BACK


## The fact that the player rode along in mission `mission_id` (Facts, saved with the missions).
static func rode(mission_id: String) -> String:
	return "flag:rode_" + mission_id


## The rides (OfficeBuilding.rides) waiting in `session` now: those of its active missions
## not ridden yet; with `person_id`, only theirs.
static func waiting(session: Object, rides: Array, person_id := "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if session == null or not session.has_method("knows"):
		return out
	var active := _active_ids(session)
	for r: Dictionary in rides:
		if r["mission"] in active and (person_id.is_empty() or r["with"] == person_id) \
				and not session.call("knows", rode(r["mission"])):
			out.append(r)
	return out


## The ids of `session`'s active missions ([] for a stand-in without them).
static func _active_ids(session: Object) -> Array:
	if not session.has_method("active_missions"):
		return []
	return session.call("active_missions").map(func(m: MissionDef) -> String: return m.id)


## The yard's other places for `p` (OfficePeople.spots): by their van (driver:van<k>), and
## each `during` spot; `resolve` turns a cast spot into a floor spot ({} when not here).
static func spots_of(p: OfficePerson, resolve: Callable) -> Dictionary:
	var out := {}
	if p.van >= 0:
		var at_van: Dictionary = resolve.call({"van": p.van, "pose": "idle"})
		if not at_van.is_empty():
			out[AT_VAN] = at_van
	for m: String in p.during:
		var spot: Dictionary = resolve.call(p.during[m])
		if not spot.is_empty():
			out[DURING + m] = spot
	return out


## Where the yard puts `p` at `minute` ({place, since} as OfficePeople._where), or {} when it
## has no say: waiting at their van for a ride, where an active mission puts them, out with
## their van while it is out (not the storingsbussen).
static func where(p: OfficePerson, session: Object, rides: Array, minute: int) -> Dictionary:
	if (p.van < 0 and p.during.is_empty()) or session == null:
		return {}
	if p.spots.has(AT_VAN) and not waiting(session, rides, p.id).is_empty():
		return {"place": AT_VAN, "since": AT_ONCE}
	var active := _active_ids(session)
	for m: String in p.during:
		if m in active and p.spots.has(DURING + m):
			return {"place": DURING + m, "since": AT_ONCE}
	if p.van >= 0 and not p.van in ON_CALL and minute >= 0 and out_at(minute):
		return {"place": OfficeDay.OUT, "since": AT_ONCE}
	return {}


## The vans a monteur waits at for a ride now.
func kept_vans() -> Array[int]:
	var out: Array[int] = []
	for r in waiting(office.session, office.floors.building.rides):
		var p := office.people.person(r["with"])
		if p != null and p.van >= 0 and not p.van in out:
			out.append(p.van)
	return out


## The vans as the clock has them, and a ride's door at each van a monteur waits at.
func poll() -> void:
	if office == null or not office.session.error.is_empty():
		return
	park(office.geometry, office.session.minute_of_day(), kept_vans())
	var want := {}
	var markers := office.floors.markers()
	for r in waiting(office.session, office.floors.building.rides):
		var p := office.people.person(r["with"])
		var door: Node3D = markers.get("ride:van%d" % p.van) if p != null and p.visible and p.van >= 0 else null
		if door != null:
			want["%s:%s" % [RIDE, r["mission"]]] = office.in_office(door)
	_keep(want)


## This node's ride doors exactly `want` (id → transform in the office).
func _keep(want: Dictionary) -> void:
	for i in office.interactables.duplicate():
		if i.kind == RIDE and not want.has(i.id):
			office.interactables.erase(i)
			office.remove_child(i)
			i.free()
	for id: String in want:
		if office.interactable(id) == null:
			var i := Interactable.create(id, want[id])
			office.interactables.append(i)
			office.add_child(i)


## Use a ride's door: the ride starts. False for anything else (the office handles it).
func use(target: Interactable) -> bool:
	if target == null or target.kind != RIDE:
		return false
	var ride := office.floors.building.ride_of(target.id.get_slice(":", 1))
	var monteur := office.people.person(str(ride.get("with", "")))
	if monteur != null and office.ride == null:
		office.ride = VanRide.begin(office, ride, monteur)
	return true


func prompt(target: Interactable) -> String:
	return tr(PROMPT) % _first_name(target) if target != null and target.kind == RIDE else ""


func label(target: Interactable) -> String:
	return tr(LABEL) % _first_name(target) if target != null and target.kind == RIDE else ""


func _first_name(target: Interactable) -> String:
	var who := str(office.floors.building.ride_of(target.id.get_slice(":", 1)).get("with", ""))
	var p := office.people.person(who)
	return p.display_name.get_slice(" ", 0) if p != null else who


func _process(delta: float) -> void:
	_since += delta
	if office == null or _since < POLL_SECONDS or office.ride != null:
		return
	_since = 0.0
	poll()
