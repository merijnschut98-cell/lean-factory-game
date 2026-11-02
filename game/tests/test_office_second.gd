extends TestCase
## The 2e verdieping alive (PLAN 2.16, design §1.1, §1.7): its people keep the clock like
## the 1e (in by the lift or the stairs, coffee at the 2e's coffee corner, lunch in the
## kantine or at the desk, home), Ingrid Bos heads Netstrategie at her own desk, and Ruud
## moves back up to his own office once the first hundred days are behind him.

const SCENE := "res://src/world/office/office.tscn"
## The rooms of the 2e and the missions that open them.
const OPENERS: Array[String] = ["fix_silo_kpis", "look_at_grid_study", "fix_unused_capacity"]


## A session stand-in with a clock (minutes since midnight); nobody stays late.
class Clock:
	extends RefCounted
	var minute := 9 * 60

	func active_missions() -> Array[MissionDef]:
		return []

	func minute_of_day() -> int:
		return minute


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _take(office: Office, mission_id: String) -> void:
	office.session.missions.progress[mission_id] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)


func _done(office: Office, mission_id: String) -> void:
	office.session.missions.progress[mission_id] = {"status": "completed", "asks": {}, "seen": {}}
	office.session.missions.done_once[mission_id] = true
	office.floors._process(OfficeFloors.POLL_SECONDS)


## The 2e with its rooms open, the player by the lift.
func _second() -> Office:
	var office := _office()
	for m in OPENERS:
		_take(office, m)
	office.floors.go_to("second", "lift", true)
	return office


func _chair(office: Office, id: String) -> Vector3:
	return office.in_office(office.find_marker(id)).origin * Vector3(1, 0, 1)


func _run(office: Office, seconds: float, dt := 0.1) -> void:
	var t := 0.0
	while t < seconds:
		office.people._process(dt)
		t += dt


## The distance (m, on the floor) from `at` to the nearest way onto this floor.
func _from_way_in(office: Office, at: Vector3) -> float:
	var best := INF
	var markers := office.floors.markers()
	for id: String in markers:
		if id.begins_with("arrive:"):
			var m: Vector3 = office.in_office(markers[id]).origin
			best = minf(best, Vector2(at.x - m.x, at.z - m.z).length())
	return best


func _at(clock: Clock, office: Office, minute: int) -> void:
	clock.minute = minute
	office.people.refresh(clock)


# ── The day on the 2e ─────────────────────────────────────────────────────────

func test_the_2e_people_come_in_by_the_lift_or_the_stairs_and_sit_at_their_desks() -> void:
	var office := _second()
	var clock := Clock.new()
	_at(clock, office, 7 * 60)
	for id in ["femke", "thomas", "ingrid"]:
		var p := office.people.person(id)
		assert_true(p != null, "%s works on the 2e" % id)
		if p != null:
			assert_false(p.visible, "%s is not in at seven" % id)
	var femke := office.people.person("femke")
	_at(clock, office, office.people.day_of("femke").arrive + 1)
	var t := 0.0
	while not femke.visible and t < 6.0:
		office.people._process(0.1)
		t += 0.1
	assert_true(femke.visible, "Femke has come in")
	assert_true(_from_way_in(office, femke.position) < 1.0, "by the lift or the stairs: %.1f m" % _from_way_in(office, femke.position))
	assert_eq(femke.pose, "walk")
	_at(clock, office, 9 * 60 + 30)
	assert_near(femke.position.distance_to(_chair(office, "grid_a0_chair")), 0.0, 0.01, "at her desk in Netstrategie")
	assert_eq(femke.pose, "sit")
	var ingrid := office.people.person("ingrid")
	assert_true(ingrid.visible, "Ingrid at Netstrategie")
	assert_near(ingrid.position.distance_to(_chair(office, "grid_b1_chair")), 0.0, 0.01, "at her own desk")
	office.free()


func test_lunch_on_the_2e_is_downstairs_in_the_kantine_or_at_franks_desk() -> void:
	var office := _second()
	var clock := Clock.new()
	_at(clock, office, 11 * 60)
	var femke := office.people.person("femke")
	var lunch := office.people.day_of("femke").lunch
	_at(clock, office, lunch + 1)
	assert_eq(office.people.place_for(femke, clock.minute), "lunch")
	assert_eq(femke.pose, "walk", "she walks to the lift or the stairs, never jumps")
	_run(office, 60.0)
	assert_false(femke.visible, "gone down to the kantine")
	var frank := office.people.person("frank")
	_at(clock, office, office.people.day_of("frank").lunch + OfficeDay.WALK_WINDOW + 1)
	assert_true(frank.visible, "Frank eats at his desk")
	assert_near(frank.position.distance_to(_chair(office, "director0_chair")), 0.0, 0.01)
	_at(clock, office, lunch + OfficeDay.LUNCH_MINUTES + OfficeDay.WALK_WINDOW + 1)
	assert_true(femke.visible, "back from lunch")
	assert_near(femke.position.distance_to(_chair(office, "grid_a0_chair")), 0.0, 0.01)
	office.free()


func test_at_six_the_2e_has_gone_home() -> void:
	var office := _second()
	var clock := Clock.new()
	_at(clock, office, 9 * 60)
	_at(clock, office, 18 * 60 + 10)
	for id in ["frank", "femke", "thomas", "ingrid"]:
		assert_false(office.people.person(id).visible, "%s has gone home" % id)
	office.free()


func test_coffee_at_the_2e_corner_with_chatter() -> void:
	var office := _second()
	var clock := Clock.new()
	var femke := office.people.person("femke")
	var thomas := office.people.person("thomas")
	var both := maxi(office.people.day_of("femke").coffee, office.people.day_of("thomas").coffee)
	assert_true(both < mini(office.people.day_of("femke").coffee, office.people.day_of("thomas").coffee)
		+ OfficeDay.COFFEE_MINUTES, "Femke's and Thomas's coffee overlap")
	_at(clock, office, 9 * 60 + 30)
	_at(clock, office, both + 1)
	_run(office, 60.0)
	var corner: Vector3 = office.people.coffee_corners[0]
	var there := office.reactions.at_corner(corner)
	assert_true(femke in there and thomas in there, "both at the 2e's coffee table")
	var lines := office.session.chatter(there[0].id, there[1].id)
	assert_eq(lines.size(), 2, "they talk")
	office.free()


# ── Ruud goes back upstairs (PLAN 2.1c Q10) ──────────────────────────────────────

func test_ruud_moves_up_to_his_own_office_after_the_first_hundred_days() -> void:
	var office := _office()
	var ruud := office.people.person("ruud")
	assert_true(ruud.visible, "in Acts 0-I Ruud sits with Aansluitingen")
	assert_false("ruud_office" in office.floors.open_now(), "his room upstairs is shut")
	_done(office, "review_100_days")
	assert_true("ruud_office" in office.floors.open_now(), "after day 100 his room opens")
	office.people.refresh(office.session)
	assert_false(ruud.visible, "no longer at the coach's desk on the 1e")
	office.floors.go_to("second", "lift", true)
	var upstairs := office.people.person("ruud")
	assert_true(upstairs != null and upstairs.visible, "Ruud at his desk on the 2e")
	assert_near(upstairs.position.distance_to(_chair(office, "ruud_office_chair")), 0.0, 0.01)
	var heard: Array[String] = []
	office.person_selected.connect(func(id: String) -> void: heard.append(id))
	office.player.position = upstairs.position + upstairs.basis.x * 0.7
	office.use(upstairs)
	assert_eq(heard, [], "no talk")
	assert_true(office.ui.is_busy(), "the coach's panel opens upstairs too")
	office.free()


func test_the_1e_coach_room_has_no_coach_once_ruud_has_moved() -> void:
	var office := _office()
	assert_true(office.interactable("coach") != null)
	_done(office, "review_100_days")
	office.floors.go_to("second", "lift", true)
	office.floors.go_to("first", "lift", true)
	assert_true(office.interactable("coach") == null, "the room is the team's overlegkamer now")
	office.free()
