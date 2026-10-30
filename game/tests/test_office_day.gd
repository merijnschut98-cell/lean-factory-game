extends TestCase
## The office keeps time (PLAN 2.14 S1-A; design 2026-10-21 §1.1–1.2): people come in by
## the lift or the stairs, have coffee and lunch and go home on their own day (cast.json
## `day:`), walking between their places instead of jumping; who stays late follows the
## simulation; the light follows the clock, with desk lamps where people work late.

const SCENE := "res://src/world/office/office.tscn"


## A session stand-in with a clock (minutes since midnight), morale and strain by person.
class Clock:
	extends RefCounted
	var minute := 9 * 60
	var energy := {}
	var strain := {}

	func active_missions() -> Array[MissionDef]:
		return []

	func minute_of_day() -> int:
		return minute

	func energy_of(person_id: String) -> Dictionary:
		return energy.get(person_id, {})

	func strain_of(person_id: String) -> float:
		return strain.get(person_id, 0.0)


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


## The distance (m, on the floor) from `at` to the nearest way onto this floor.
func _from_way_in(office: Office, at: Vector3) -> float:
	var best := INF
	var markers := office.floors.markers()
	for id: String in markers:
		if id.begins_with("arrive:"):
			var m: Vector3 = office.in_office(markers[id]).origin
			best = minf(best, Vector2(at.x - m.x, at.z - m.z).length())
	return best


## Seconds of the world running in steps of `dt`; the positions `p` passed through.
func _run(office: Office, p: OfficePerson, seconds: float, dt := 0.1) -> PackedVector3Array:
	var trail := PackedVector3Array([p.position])
	var t := 0.0
	while t < seconds:
		office.people._process(dt)
		trail.append(p.position)
		t += dt
	return trail


func _longest_step(trail: PackedVector3Array) -> float:
	var out := 0.0
	for i in range(1, trail.size()):
		out = maxf(out, trail[i].distance_to(trail[i - 1]))
	return out


func _moves(trail: PackedVector3Array) -> int:
	var n := 0
	for i in range(1, trail.size()):
		if trail[i].distance_to(trail[i - 1]) > 0.001:
			n += 1
	return n


func _chair(office: Office, id: String) -> Vector3:
	return office.in_office(office.find_marker(id)).origin * Vector3(1, 0, 1)


# ── The day ─────────────────────────────────────────────────────────────────

func test_someone_comes_in_by_the_lift_or_the_stairs_and_is_at_the_desk_by_a_quarter_to_nine() -> void:
	var office := _office()
	var clock := Clock.new()
	var sanne := office.people.person("sanne")
	var day := office.people.day_of("sanne")
	assert_between(day.arrive, 8 * 60, 8 * 60 + 4, "Sanne is in just after eight")
	clock.minute = 7 * 60
	office.people.refresh(clock)
	assert_eq(office.people.place_for(sanne, clock.minute), "out")
	assert_false(sanne.visible, "nobody at Intake at seven")
	clock.minute = 8 * 60 + 5
	office.people.refresh(clock)
	var t := 0.0
	while not sanne.visible and t < 5.0:   # someone may step out before her
		office.people._process(0.1)
		t += 0.1
	assert_true(sanne.visible, "she has come in")
	assert_true(_from_way_in(office, sanne.position) < 1.0, "at the lift or the stairs: %.1f m" % _from_way_in(office, sanne.position))
	assert_eq(sanne.pose, "walk")
	var trail := _run(office, sanne, 1.0)
	assert_true(_moves(trail) > 5, "walking to her desk")
	clock.minute = 8 * 60 + 45
	office.people.refresh(clock)
	assert_near(sanne.position.distance_to(_chair(office, "intake0_chair")), 0.0, 0.01, "at her desk")
	assert_eq(sanne.pose, "sit")
	office.free()


func test_lunch_is_walked_to_the_lift_and_in_the_kantine_never_jumped() -> void:
	var office := _office()
	var clock := Clock.new()
	var rachid := office.people.person("rachid")
	var lunch := office.people.day_of("rachid").lunch
	clock.minute = 11 * 60
	office.people.refresh(clock)
	assert_true(rachid.visible and rachid.pose == "sit", "at Intake before lunch")
	clock.minute = lunch + 1
	office.people.refresh(clock)
	assert_eq(office.people.place_for(rachid, clock.minute), "lunch")
	var trail := _run(office, rachid, 15.0)
	assert_true(_moves(trail) > 10, "he walks, over several refreshes: %d moves" % _moves(trail))
	assert_true(_longest_step(trail) <= rachid.pace * 0.1 + 0.05, "never a jump: %.2f m" % _longest_step(trail))
	assert_false(rachid.visible, "down to the kantine")
	assert_true(_from_way_in(office, trail[trail.size() - 1]) < 0.5, "he left by the lift or the stairs")
	office.floors.go_to("ground", "lift", true)
	rachid = office.people.person("rachid")
	clock.minute = 11 * 60
	office.people.refresh(clock)
	assert_false(rachid.visible, "not down yet")
	clock.minute = lunch + 1
	office.people.refresh(clock)
	var closest := INF
	var first_seen := Vector3.INF
	trail = PackedVector3Array()
	for i in 300:   # 30 s; nobody walks through anybody coming out of the lift with them
		office.people._process(0.1)
		if rachid.visible:
			trail.append(rachid.position)
			if first_seen == Vector3.INF:
				first_seen = rachid.position
		var out := office.people.people.filter(func(p: OfficePerson) -> bool: return p.visible and p.pose == "walk")
		for a in out.size():
			for b in range(a + 1, out.size()):
				closest = minf(closest, (out[a] as OfficePerson).position.distance_to((out[b] as OfficePerson).position))
	assert_true(_from_way_in(office, first_seen) < 1.0, "out of the lift or off the stairs")
	assert_true(closest > 0.5, "walkers keep apart: %.2f m" % closest)
	assert_true(_longest_step(trail) <= rachid.pace * 0.1 + 0.05, "never a jump")
	var canteen := OfficeFloors.room_rect(office.floors.markers()["room:canteen"])
	assert_true(canteen.has_point(Vector2(rachid.position.x, rachid.position.z)), "at his table in the kantine")
	assert_eq(rachid.pose, "sit")
	office.free()


## Someone stopped mid-walk for a talk stands and talks; their day waits until the talk
## (its summary too) is over, then they walk on.
func test_someone_talked_with_on_the_way_stays_until_the_talk_is_over() -> void:
	var office := _office()
	var clock := Clock.new()
	var rachid := office.people.person("rachid")
	clock.minute = 11 * 60
	office.people.refresh(clock)
	clock.minute = office.people.day_of("rachid").lunch + 1
	office.people.refresh(clock)
	_run(office, rachid, 1.0)
	assert_eq(rachid.pose, "walk", "on his way to lunch")
	office.people.hold(rachid)
	var stopped := rachid.position
	assert_eq(rachid.pose, "idle", "he stops and stands")
	_run(office, rachid, 2.0)
	clock.minute += 20   # the talk's minutes pass while its summary still shows
	_run(office, rachid, 2.0)
	assert_near(rachid.position.distance_to(stopped), 0.0, 0.001, "he stays where he stopped")
	assert_true(rachid.visible, "and stays on the floor")
	office.people.release()
	assert_true(office.people.held == null)
	var trail := _run(office, rachid, 2.0)
	assert_true(_moves(trail) > 5, "then he walks on")
	assert_true(_longest_step(trail) <= rachid.pace * 0.1 + 0.05, "never a jump: %.2f m" % _longest_step(trail))
	office.free()


func test_a_walker_held_for_a_talk_stops_walking_his_round() -> void:
	var office := _office()
	var marco := office.people.person("marco")
	office.people.hold(marco)
	var stopped := marco.position
	for i in 20:
		marco._process(0.1)
	assert_near(marco.position.distance_to(stopped), 0.0, 0.001, "Marco stands for the talk")
	office.people.release()
	for i in 5:
		marco._process(0.1)
	assert_true(marco.position.distance_to(stopped) > 0.1, "and walks his round again after")
	office.free()


func test_coffee_at_ten_at_the_coffee_corner() -> void:
	var office := _office()
	var clock := Clock.new()
	var joost := office.people.person("joost")
	var coffee := office.people.day_of("joost").coffee
	assert_between(coffee, 9 * 60 + 45, 10 * 60 + 20, "coffee around ten")
	clock.minute = coffee - 30
	office.people.refresh(clock)
	clock.minute = coffee + 5   # the walk there is over once the clock has moved on
	office.people.refresh(clock)
	_run(office, joost, 30.0)
	var table := _chair(office, "coffee_table")
	assert_true(joost.visible and joost.position.distance_to(table) < 1.5, "at the coffee table: %.1f m" % joost.position.distance_to(table))
	assert_true((-joost.basis.z).dot(table - joost.position) > 0, "facing it")
	clock.minute = coffee + OfficeDay.COFFEE_MINUTES + OfficeDay.WALK_WINDOW + 1
	office.people.refresh(clock)
	assert_near(joost.position.distance_to(_chair(office, "design3_chair")), 0.0, 0.01, "back at his desk")
	office.free()


func test_people_do_not_move_in_lockstep() -> void:
	var arrivals := {}
	var lunches := {}
	for entry in CharacterModel.cast():
		var problems: Array[String] = []
		var day := OfficeDay.from_entry(entry, problems)
		assert_eq(problems, [] as Array[String], "%s's day reads" % entry["id"])
		arrivals[day.arrive] = true
		lunches[day.lunch] = true
		assert_between(day.arrive, 7 * 60, 8 * 60 + 45, "%s in by 08:45" % entry["id"])
		assert_between(day.lunch, 12 * 60, 12 * 60 + 30, "%s lunches between twelve and one" % entry["id"])
		assert_between(day.leave, 16 * 60, 17 * 60 + 30, "%s out by 17:30" % entry["id"])
	assert_true(arrivals.size() >= 8, "arrivals spread: %d" % arrivals.size())
	assert_true(lunches.size() >= 5, "lunches spread: %d" % lunches.size())


# ── Staying late ────────────────────────────────────────────────────────────

func test_at_half_past_six_only_those_who_stay_late_are_still_in() -> void:
	var office := _office()
	var clock := Clock.new()
	clock.strain = {"linda": 0.6}
	clock.minute = 9 * 60
	office.people.refresh(clock)
	clock.minute = 18 * 60 + 30
	office.people.refresh(clock)
	assert_true(office.people.person("linda").visible, "Linda, worn down, is still at it")
	for p in office.people.people:
		if p.id != "linda":
			assert_false(p.visible, "%s has gone home" % p.id)
	clock.minute = OfficeDay.LATE_UNTIL + OfficeDay.WALK_WINDOW
	office.people.refresh(clock)
	assert_false(office.people.person("linda").visible, "and home by a quarter to seven")
	office.free()


func test_who_stays_late_is_the_strain() -> void:
	assert_true(OfficeDay.stays_late(Strain.LATE_AT), "from the late threshold on")
	assert_false(OfficeDay.stays_late(Strain.LATE_AT - 0.01), "an ordinary day")
	var clock := Clock.new()
	clock.strain = {"joost": 0.9, "anouk": 0.1}
	var late := OfficeDay.late_ids(clock, ["joost", "anouk", "sanne"])
	assert_true(late.has("joost") and not late.has("anouk"), str(late))
	var office := _office()
	var ids := office.session.people.persons.keys()
	var real := OfficeDay.late_ids(office.session, ids)
	for id: String in real:
		assert_true(id in ids, "a person the session knows: " + id)
	office.free()


# ── Validation ──────────────────────────────────────────────────────────────

func test_a_bad_day_falls_back_to_the_defaults_never_a_crash() -> void:
	var fallback := OfficeDay.from_entry({"id": "x"})
	var problems: Array[String] = []
	var bad := OfficeDay.from_entry({"id": "x", "day": {"arrive": "25:10", "coffee": 10, "lunch": "12:15", "nap": "14:00"}}, problems)
	assert_eq(problems.size(), 3, "each one named: " + str(problems))
	assert_eq(bad.arrive, fallback.arrive, "a time that is no time")
	assert_eq(bad.coffee, fallback.coffee, "not a string")
	assert_eq(bad.lunch, 12 * 60 + 15, "the good field stays")
	problems.clear()
	var upside := OfficeDay.from_entry({"id": "x", "day": {"arrive": "18:00", "leave": "08:00"}}, problems)
	assert_eq(problems.size(), 1, "out of order")
	assert_eq(upside.arrive, fallback.arrive, "out of order: the defaults")
	assert_eq(upside.leave, fallback.leave)
	var not_a_day := OfficeDay.from_entry({"id": "x", "day": ["08:00"]}, problems)
	assert_eq(not_a_day.arrive, fallback.arrive)
	assert_eq(OfficeDay.parse_time("08:05"), 8 * 60 + 5)
	assert_eq(OfficeDay.parse_time("8:5"), -1)
	assert_eq(OfficeDay.parse_time(null), -1)


# ── The light ───────────────────────────────────────────────────────────────

func test_the_light_follows_the_clock() -> void:
	assert_eq(OfficeDaylight.band_at(6 * 60), "night")
	assert_eq(OfficeDaylight.band_at(7 * 60 + 30), "morning")
	assert_eq(OfficeDaylight.band_at(12 * 60), "day")
	assert_eq(OfficeDaylight.band_at(16 * 60 + 30), "evening")
	assert_eq(OfficeDaylight.band_at(18 * 60 + 30), "night")
	var office := _office()
	var light := office.daylight
	light.apply(12 * 60)
	var noon := light.sun.light_energy
	var noon_ambient := light.environment.environment.ambient_light_energy if light.environment != null else 0.0
	var noon_colour := light.sun.light_color
	light.apply(8 * 60)
	assert_true(light.sun.light_color.b < noon_colour.b, "the morning is warm")
	assert_true(light.sun.light_energy < noon, "and low")
	light.apply(19 * 60 + 30)
	assert_true(light.sun.light_energy < noon * 0.2, "after six it is dark")
	if light.environment != null:
		assert_true(light.environment.environment.ambient_light_energy < noon_ambient, "the room too")
	assert_eq(light.band, "night")
	office.free()


func test_desk_lamps_burn_where_people_work_late() -> void:
	var office := _office()
	var clock := Clock.new()
	clock.strain = {"linda": 0.6}
	clock.minute = 15 * 60
	office.people.refresh(clock)
	office.daylight.update(clock)
	assert_eq(office.daylight.lit_desks(), 0, "no lamps in the afternoon")
	clock.minute = 18 * 60 + 30
	office.people.refresh(clock)
	office.daylight.update(clock)
	assert_eq(office.daylight.lit_desks(), 1, "one lamp: Linda's")
	var lamp := office.daylight.lamps[0]
	var desk := _chair(office, "planning1_desk")
	assert_true(Vector2(lamp.position.x - desk.x, lamp.position.z - desk.z).length() < 0.5, "at her desk")
	office.free()


func test_the_openings_evening_has_one_lamp_at_anouks_desk() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.opening = true
	var me := PlayerProfile.new()
	me.name = "Noor"
	office.new_player = me
	office.build()
	var o := office.first_day
	o.start()
	o.lines.auto = false
	for i in 8:
		if office.ui.session_layer.opening_beat == Opening.ANOUK:
			break
		if o.lines.asking():
			o.lines.pick(1)
		o.skip()
	assert_eq(office.ui.session_layer.opening_beat, Opening.ANOUK, "the evening")
	office.people._process(OfficePeople.REFRESH_SECONDS)
	office.daylight._process(OfficeDaylight.REFRESH_SECONDS)
	for p in office.people.people:
		assert_eq(p.visible, p.id == "anouk", "only Anouk is still in: " + p.id)
	assert_eq(office.daylight.lit_desks(), 1, "one lamp on")
	var lamp := office.daylight.lamps[0]
	var desk := _chair(office, "design2_desk")
	assert_true(Vector2(lamp.position.x - desk.x, lamp.position.z - desk.z).length() < 0.5, "at Werkvoorbereiding, at hers")
	assert_eq(office.daylight.band, "night")
	office.free()


func test_the_clock_can_be_set_forward_for_a_shot_never_back() -> void:
	var office := _office()
	var start := office.session.minute_of_day()
	assert_true(office.set_minute_of_day(18 * 60 + 30), "half past six is ahead")
	assert_eq(office.session.minute_of_day(), 18 * 60 + 30)
	assert_eq(office.daylight.band, "night", "the light follows")
	assert_true(start < 18 * 60 + 30)
	assert_false(office.set_minute_of_day(9 * 60), "back in time is refused")
	assert_eq(office.session.minute_of_day(), 18 * 60 + 30, "and the clock stays")
	office.free()
