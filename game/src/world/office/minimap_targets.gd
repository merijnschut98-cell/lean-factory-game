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


## The next "where" of mission `m` (see the class doc); {} for a goal without a place
## in the head office.
static func of(m: MissionDef, s: GameSession, building: OfficeBuilding, cast: Array[Dictionary]) -> Dictionary:
	var out := {}
	match m.goal_type:
		"talk_to":
			var d: DialogDef = s.people.dialogs.get(m.goal_dialog)
			var p: PersonDef = s.people.persons.get(d.person) if d != null else null
			var spot := _spot(cast, p.id) if p != null else {}
			if not spot.is_empty():   # someone with a body in the office (a customer is phoned)
				out = {"kind": "person", "person": p.id, "room": str(room_of(building, p.place).get("id", "")),
					"floor": str(spot.get(OfficeFloors.FLOOR_KEY, building.start_floor))}
		"walk":
			var stream := s.region.net.stream(m.goal_stream)
			for step in stream.steps if stream != null else []:
				var place := m.goal_stream + "." + step.id
				var room := room_of(building, place)
				if step.kind == SimStep.Kind.WORK and not s.region.observed.has(place) and not room.is_empty():
					out = _room_target(room, building)
					break
		"observe":
			var seen: Dictionary = s.missions.progress.get(m.id, {}).get("seen", {})
			for place in m.goal_places:
				if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
					out = _room_target(room_of(building, place), building)
					break
		"check", "solve":
			var st: ProblemState = s.region.state.get(m.goal_problem)
			var p: ProblemDef = s.region.problems.get(m.goal_problem)
			if st != null and st.phase == ProblemState.Phase.CHECK_READY:
				out = _room_target(building.room(OBEYA_ROOM), building)
			elif p != null:
				out = _room_target(room_of(building, p.step), building)
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
