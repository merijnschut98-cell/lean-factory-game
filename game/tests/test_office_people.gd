extends TestCase
## The people in the office (PLAN 1.3), headless: placed from the cast list at their
## desks, present with their missions, the energy bar from the session when it can say,
## and E or a click next to someone asking for a talk (Office.person_selected).

const SCENE := "res://src/world/office/office.tscn"
const AT_DESKS: Array[String] = ["joost", "anouk", "sanne", "petra", "ruud"]


## A session stand-in: the active missions, and energy_of when `energy` is given.
class FakeSession:
	extends RefCounted
	var active: Array[MissionDef] = []

	func active_missions() -> Array[MissionDef]:
		return active


class FakeSessionWithEnergy:
	extends FakeSession
	var energy := {}

	func energy_of(person_id: String) -> Dictionary:
		return energy.get(person_id, {})


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _mission(id: String) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	return m


## The player a step beside `p`, on the floor.
func _beside(office: Office, p: OfficePerson) -> void:
	office.player.position = p.position + p.basis.x * 0.7


func test_the_people_sit_at_their_desks_and_marco_walks_the_aisle() -> void:
	var office := _office()
	for id in AT_DESKS:
		var p := office.people.person(id)
		assert_true(p != null, "%s is in the office" % id)
		if p != null:
			assert_eq(p.pose, "sit", "%s sits" % id)
			assert_true(p.visible, "%s is there from the start" % id)
	var joost := office.people.person("joost")
	var chair := office.find_marker("design3_chair")
	if joost != null and chair != null:
		assert_near(Vector2(joost.position.x, joost.position.z).distance_to(
			Vector2(office.in_office(chair).origin.x, office.in_office(chair).origin.z)), 0.0, 0.01, "Joost on his chair")
		var desk := office.in_office(office.find_marker("design3_desk")).origin
		assert_true((-joost.basis.z).dot(desk - joost.position) > 0, "facing his desk")
	var marco := office.people.person("marco")
	assert_true(marco != null and marco.pose == "walk" and marco.route.size() == 2, "Marco walks a route")
	office.free()


func test_petras_desk_is_a_stand_in_with_its_furniture_and_collision() -> void:
	var office := _office()
	if office.find_marker("design0_desk") == null:
		office.free()
		return   # the stand-in office has no workstations to copy
	assert_true(office.find_marker("meetdata_desk") != null, "a desk for Meetdata")
	assert_true(office.find_marker("meetdata_chair") != null, "and a chair")
	var petra := office.people.person("petra")
	assert_true(petra != null and petra.visible, "Petra sits there")
	var desk := office.in_office(office.find_marker("meetdata_desk")).origin
	assert_false(office.nav().walkable(desk), "the walk grid goes round the stand-in desk")
	office.free()


func test_henk_and_ahmed_come_only_with_their_missions() -> void:
	var office := _office()
	var henk := office.people.person("henk")
	var ahmed := office.people.person("ahmed")
	assert_true(henk != null and ahmed != null, "Henk and Ahmed are in the cast")
	if henk == null or ahmed == null:
		office.free()
		return
	assert_false(henk.visible, "no Henk without his mission")
	assert_false(ahmed.visible, "no Ahmed without his missions")
	var session := FakeSession.new()
	session.active = [_mission("walk_outages")]
	office.people.refresh(session)
	assert_false(henk.visible, "Henk is not on the outage walk")
	assert_true(ahmed.visible, "Ahmed comes for the outage walk")
	session.active = [_mission("save_henks_knowledge")]
	office.people.refresh(session)
	assert_true(henk.visible and ahmed.visible, "both for Henk's knowledge")
	assert_eq(office.people.person_near(henk.position, Office.REACH), henk, "and can be talked to")
	office.people.refresh(FakeSession.new())
	assert_eq(office.people.person_near(henk.position, 0.1), null, "absent people are out of reach")
	office.free()


func test_the_energy_bar_shows_only_when_the_session_says_someone_needs_a_talk() -> void:
	var office := _office()
	for p in office.people.people:
		assert_false(p.bar.visible, "%s: no bar while the session has no energy_of" % p.id)
	var session := FakeSessionWithEnergy.new()
	session.energy = {"anouk": {"energy": 0.3, "needs_talk": true}, "joost": {"energy": 0.4, "needs_talk": false}}
	office.people.refresh(session)
	var anouk := office.people.person("anouk")
	assert_true(anouk.bar.visible, "Anouk needs a talk")
	assert_near((anouk.bar.material_override as ShaderMaterial).get_shader_parameter("fill"), 0.3, 0.001, "her energy fills the bar")
	assert_false(office.people.person("joost").bar.visible, "low, but no talk needed")
	assert_false(office.people.person("sanne").bar.visible, "unknown to energy_of")
	office.free()


func test_e_beside_a_person_opens_the_talk() -> void:
	var office := _office()
	office.session.missions.done_once["fix_unused_capacity"] = true
	office.session.accept("fix_silo_kpis")   # Joost's talk is about its KPI
	office.session.region.found["silo_kpis:4"] = true
	office.people.refresh(office.session)
	var joost := office.people.person("joost")
	_beside(office, joost)
	assert_eq(office.target_near(office.player.position), joost)
	assert_eq(office.prompt_near(office.player.position), "E — Praat met Joost van Dijk")
	var heard: Array[String] = []
	office.person_selected.connect(func(id: String) -> void: heard.append(id))
	office.use(office.target_near(office.player.position))
	assert_eq(heard, ["joost"], "who was asked")
	assert_true(office.ui.dialog_panel.talking(), "the talk with Joost opens")
	assert_true(office.ui.is_busy())
	office.free()


func test_someone_with_nothing_to_say_nods_and_works_on() -> void:
	var office := _office()
	var sanne := office.people.person("sanne")
	_beside(office, sanne)
	office.use(sanne)
	assert_false(office.ui.is_busy(), "no talk opens")
	assert_true(GameUI.NOTHING_TO_SAY % sanne.display_name in office.ui.hud.toast_texts(), "a toast says so, by name")
	office.free()


func test_a_station_still_wins_when_the_player_stands_at_its_ring() -> void:
	var office := _office()
	var design := office.interactable("place:connections.design")
	assert_eq(office.target_near(design.position), design)
	office.free()


func test_ruud_opens_the_coach_not_a_talk() -> void:
	var office := _office()
	var ruud := office.people.person("ruud")
	_beside(office, ruud)
	var heard: Array[String] = []
	office.person_selected.connect(func(id: String) -> void: heard.append(id))
	office.use(ruud)
	assert_eq(heard, [], "no talk")
	assert_true(office.ui.is_busy(), "the coach's panel opens")
	assert_true(office.prompt_near(office.player.position).begins_with("E — Coach: "), "the prompt says coach")
	office.free()


func test_the_cursor_picks_a_person_and_a_click_walks_up_to_talk() -> void:
	var office := _office()
	var joost := office.people.person("joost")
	var eye := joost.position + Vector3(0, 6, 4)
	var at_chest := joost.position + Vector3.UP * 1.1
	assert_eq(office.people.person_under(eye, (at_chest - eye).normalized()), joost)
	assert_eq(office.people.person_under(eye, (at_chest + Vector3(2, 0, 0) - eye).normalized()), null, "beside him: nobody")
	var heard: Array[String] = []
	office.person_selected.connect(func(id: String) -> void: heard.append(id))
	assert_true(office.click_person(joost), "a way to him")
	for i in 600:
		if not office.player.walking():
			break
		office.player.step(1.0 / 30.0)
		office.player.position += office.player.velocity / 30.0
	assert_eq(heard, ["joost"], "arriving asks for the talk")
	office.free()


func test_the_walker_walks_at_the_walk_pace_and_pauses_at_the_ends() -> void:
	var office := _office()
	var marco := office.people.person("marco")
	var start := marco.position
	marco.walk(0.5)
	assert_near(marco.position.distance_to(start), marco.pace * 0.5, 0.001, "at the pace of his walk")
	var length := marco.route[0].distance_to(marco.route[1])
	for i in ceili(length / (marco.pace * 0.1)) + 1:
		marco.walk(0.1)
	assert_near(marco.position.distance_to(marco.route[1]), 0.0, 0.001, "at the far end")
	marco.walk(OfficePerson.PAUSE * 0.5)
	assert_near(marco.position.distance_to(marco.route[1]), 0.0, 0.001, "pausing there")
	marco.walk(OfficePerson.PAUSE)
	marco.walk(0.5)
	assert_true(marco.position.distance_to(marco.route[0]) < length, "and back again")
	office.free()
