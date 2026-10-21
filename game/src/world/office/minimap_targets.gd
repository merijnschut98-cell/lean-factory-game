class_name MinimapTargets
## Where the accepted missions point on the minimap (PLAN 2.1b; creator-and-minimap
## spec §2.4): one target per mission, at ROOM level (or a person), never a place, a
## clue or a tool, and never more specific than the briefing. Pure: it reads the
## session and the building data, no world.
##
## A target: {mission, main (bool), kind: "room" | "person", room (id), person (id,
## for a person), floor (id)}. No target: {}.

## The obeya wall's room: a problem's mission points there once its A3 is ready for the
## Check (build_office.py puts the obeya in the connections office).
const OBEYA_ROOM := "connections"
## At most this many targets of each kind are drawn (the 1 + 3 rule; two mains in a fork).
const MAX_MAIN := 2
const MAX_SIDE := 3


## The targets of the missions the player has accepted (an offered mission has none):
## mains first.
static func all(s: GameSession, building: OfficeBuilding, cast: Array[Dictionary]) -> Array[Dictionary]:
	var mains: Array[Dictionary] = []
	var sides: Array[Dictionary] = []
	for m in s.active_missions():
		var t := of(m, s, building, cast)
		if t.is_empty():
			continue
		if t["main"] and mains.size() < MAX_MAIN:
			mains.append(t)
		elif not t["main"] and sides.size() < MAX_SIDE:
			sides.append(t)
	return mains + sides


## The next "where" of mission `m`: its objective's step (Objective.step, so the marker
## and the HUD's line point at the same place): the person, the room of the place, the
## obeya's room; {} for a step without a place in the head office (a customer on the
## phone, a step in no room). A walk skips the steps in no room.
static func of(m: MissionDef, s: GameSession, building: OfficeBuilding, cast: Array[Dictionary]) -> Dictionary:
	var step := Objective.step(m, s, func(place: String) -> bool: return not room_of(building, place).is_empty())
	var out := {}
	if step.has("person"):
		var p: PersonDef = s.people.persons[step["person"]]
		var spot := _spot(cast, p.id)
		if not spot.is_empty():   # someone with a body in the office (a customer is phoned)
			out = {"kind": "person", "person": p.id, "room": str(room_of(building, p.place).get("id", "")),
				"floor": str(spot.get(OfficeFloors.FLOOR_KEY, building.start_floor))}
	elif step.get("obeya", false):
		out = _room_target(building.room(OBEYA_ROOM), building)
	elif step.has("room"):   # a milestone's scene waits there
		out = _room_target(building.room(step["room"]), building)
	elif step.has("place"):
		out = _room_target(room_of(building, step["place"]), building)
	if out.is_empty():
		return {}
	out.merge({"mission": m.id, "main": m.kind != "side"})
	return out


## The room (building data) whose places hold `place`; {} when none does.
static func room_of(building: OfficeBuilding, place: String) -> Dictionary:
	for r in building.rooms:
		if place in r["places"]:
			return r
	return {}


static func _room_target(room: Dictionary, building: OfficeBuilding) -> Dictionary:
	if room.is_empty():
		return {}
	return {"kind": "room", "room": room["id"], "floor": room["floor"] if room.has("floor") else building.start_floor}


## A cast entry's office spot ({} when the cast does not place them).
static func _spot(cast: Array[Dictionary], id: String) -> Dictionary:
	for e in cast:
		if e.get("id") == id:
			return e.get("office", {})
	return {}
