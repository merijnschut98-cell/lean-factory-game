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


## A session stand-in with a clock (minutes since midnight) and what it knows of people.
class FakeSessionWithClock:
	extends FakeSession
	var minute := 9 * 60
	var known := {}

	func minute_of_day() -> int:
		return minute

	func person(person_id: String) -> Dictionary:
		return known.get(person_id, {})


func _office(training := false) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = training
	office.build()
	return office


## To floor `id` the way a player gets there: an outside area (the yard) by its door.
func _go_to(office: Office, id: String) -> void:
	office.floors.go_to(id, "exit" if office.floors.building.floor_of(id).get("outside_of", "") != "" else "lift", true)


func _take(office: Office, mission_id: String) -> void:
	office.session.missions.progress[mission_id] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)


## The cast entry of `id` ({} when there is none).
func _cast(id: String) -> Dictionary:
	for e in CharacterModel.cast():
		if e["id"] == id:
			return e
	return {}


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


func test_henk_and_ahmed_come_only_with_their_missions() -> void:
	var office := _office()
	_take(office, "fix_installer_not_ready")   # opens the werkplaats on the yard, where they wait
	_go_to(office, "yard")
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


## A friendly first week (PLAN 2.13 D): all Monday long nobody in the office shows the
## energy bar or the check-in mark; the scripted talk (Anouk at seven) comes by mission.
func test_on_monday_nobody_in_the_office_shows_the_energy_bar() -> void:
	var office := _office(true)
	for hour in 10:
		office.session.pass_time(60)
		office.people.refresh(office.session)
		for p: OfficePerson in office.people.people:
			assert_false(p.bar.visible or p.mark.visible, "%s at %s" % [p.id, office.session.clock_text()])
	assert_eq(office.session.checkin_prompts(), [], "no check-in prompt in the training week")
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
	assert_true(office.ui.talk_view.talking(), "the talk with Joost opens")
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


# ── 2.1c: people in every room (PLAN 1.3, 2.1c) ─────────────────────────────

func test_every_speaker_has_a_body_and_is_there_while_their_talk_is_open() -> void:
	var office := _office()
	var talks: Array[DialogDef] = []
	for d: DialogDef in office.session.people.dialogs.values():
		var person: PersonDef = office.session.people.persons.get(d.person)
		if person != null and not person.archetype.begins_with("customer"):   # customers are phoned
			talks.append(d)
	assert_true(talks.size() >= 20, "the talks are read")
	for d in talks:
		assert_false(_cast(d.person).get("office", {}).is_empty(), "%s has a place in the office's cast" % d.person)
		assert_true(ResourceLoader.exists(CharacterModel.path(d.person)), "%s has a body" % d.person)
	for d in talks:   # a talk tied to a mission: its person is there, reachable, while it is on
		if d.mission.is_empty() or _cast(d.person).get("office", {}).is_empty():
			continue
		_take(office, d.mission)
		_go_to(office, str(_cast(d.person)["office"].get("floor", "first")))
		office.people.refresh(office.session)
		var p := office.people.person(d.person)
		assert_true(p != null and p.visible, "%s is there for %s (%s)" % [d.person, d.id, d.mission])
		if p != null and p.visible:
			assert_false(office.nav().path(office.player.position, p.position).is_empty(), "%s can be walked up to" % d.person)
	office.free()


func test_the_yard_has_its_people_dirk_at_his_counter_henk_and_ahmed_in_the_werkplaats() -> void:
	var office := _office()
	_take(office, "fix_wrong_joint")
	_take(office, "save_henks_knowledge")
	office.floors.go_to("yard", "exit", true)
	var m := office.floors.markers()
	var magazijn := OfficeFloors.room_rect(m["room:magazijn"])
	var werkplaats := OfficeFloors.room_rect(m["room:werkplaats"])
	for who: Array in [["dirk", magazijn], ["henk", werkplaats], ["ahmed", werkplaats]]:
		var p := office.people.person(who[0])
		assert_true(p != null and p.visible, "%s is on the yard" % who[0])
		if p != null:
			assert_true((who[1] as Rect2).has_point(Vector2(p.position.x, p.position.z)), "%s in his room" % who[0])
			assert_false(office.nav().path(office.player.position, p.position).is_empty(), "%s can be walked up to" % who[0])
	assert_eq(_cast("dirk")["office"].get("missions", []), [], "the magazijn is Dirk's: he is there whenever it is open")
	office.free()


func test_visitors_come_to_the_ontvangst_for_their_missions() -> void:
	var office := _office()
	office.floors.go_to("ground", "lift", true)
	var reception := OfficeFloors.room_rect(office.floors.markers()["room:reception"])
	for visit: Array in [["gert", "fix_digging_damage"], ["wim", "fix_inverters_tripping"]]:
		var p := office.people.person(visit[0])
		assert_true(p != null and not p.visible, "%s is not here without %s" % visit)
		if p == null:
			continue
		_take(office, visit[1])
		office.people.refresh(office.session)
		assert_true(p.visible and reception.has_point(Vector2(p.position.x, p.position.z)), "%s waits at the ontvangst" % visit[0])
		assert_false(office.nav().path(office.player.position, p.position).is_empty(), "%s can be walked up to" % visit[0])
		assert_true(ResourceLoader.exists(CharacterModel.path(visit[0])), "%s has a body" % visit[0])
	office.free()


func test_the_new_rooms_have_their_people_on_their_floors() -> void:
	var expected := {"esra": "ground", "kim": "ground", "saskia": "ground", "femke": "second", "frank": "second",
		"rachid": "first", "linda": "first", "mieke": "first", "petra": "first", "rob": "first", "thomas": "second"}
	for id: String in expected:
		var spot: Dictionary = _cast(id).get("office", {})
		assert_eq(str(spot.get("floor", "first")), expected[id], "%s's floor" % id)
		assert_true(ResourceLoader.exists(CharacterModel.path(id)), "%s is built" % id)
	for id in ["esra", "kim", "saskia"]:
		assert_true(_cast(id)["office"].get("headset", false), "%s wears a headset" % id)


func test_petra_is_reachable_at_her_own_desk() -> void:
	var office := _office()
	assert_false(_cast("petra")["office"].has("stand_in_desk"), "the model has her desk now")
	var petra := office.people.person("petra")
	assert_true(petra != null and petra.visible, "Petra is at Meetdata")
	var chair := office.find_marker("meetdata_chair")
	assert_true(chair != null and Vector2(petra.position.x, petra.position.z).distance_to(
		Vector2(office.in_office(chair).origin.x, office.in_office(chair).origin.z)) < 0.01, "on her chair")
	assert_false(office.nav().path(office.player.position, petra.position + petra.basis.x * 0.8).is_empty(),
		"the way to her is open")
	office.free()


func test_people_behind_a_shut_door_are_not_there() -> void:
	var office := _office(true)   # Monday of the training week: only the tour is on
	var petra := office.people.person("petra")
	var mieke := office.people.person("mieke")
	assert_true(petra != null and mieke != null, "Petra and Mieke have desks on the 1e")
	assert_false(petra.visible, "Meetdata is shut on Monday")
	assert_false(mieke.visible, "Revisie & GIS is shut on Monday")
	assert_eq(office.people.person_near(mieke.position, Office.REACH), null, "and out of reach")
	assert_true(office.people.person("anouk").visible, "Aansluitingen is open")
	assert_true(office.people.person("linda").visible, "Linda at the planners' bench in Aansluitingen")
	assert_true(office.interactable("place:connections.planning") != null, "her team's place for Wednesday's talk")
	_take(office, "training_wed")
	assert_true(mieke.visible, "Wednesday's talk opens Revisie & GIS: Mieke is there")
	_take(office, "training_thu")
	assert_true(petra.visible, "Thursday's talk opens Meetdata: Petra is there")
	office.free()


func test_the_kcc_and_the_2e_are_peopled_once_their_rooms_open() -> void:
	var office := _office()
	_take(office, "fix_status_callers")
	office.floors.go_to("ground", "lift", true)
	for id in ["esra", "kim"]:
		var p := office.people.person(id)
		assert_true(p != null and p.visible, "%s at the Klantcontactcentrum" % id)
	assert_true(office.people.person("esra").find_child("Headset", true, false) != null, "Esra's headset")
	var saskia := office.people.person("saskia")
	assert_true(saskia != null and not saskia.visible, "Saskia is at home with stress (esra_agents) while the mission runs")
	office.session.missions.progress["fix_status_callers"]["status"] = "completed"
	office.session.missions.done_once["fix_status_callers"] = true
	office.people.refresh(office.session)
	assert_true(saskia.visible, "back once the callers are fixed (esra_after: halve dagen)")
	office.floors.go_to("second", "lift", true)
	var frank := office.people.person("frank")
	var femke := office.people.person("femke")
	assert_true(frank != null and femke != null, "Frank and Femke on the 2e")
	if frank == null or femke == null:
		office.free()
		return
	assert_false(frank.visible or femke.visible, "their rooms are shut")
	_take(office, "fix_silo_kpis")
	assert_true(frank.visible, "Directie & Obeya open: Frank at his desk")
	assert_false(femke.visible, "Netstrategie still shut")
	_take(office, "look_at_grid_study")
	assert_true(femke.visible, "Netstrategie open: Femke")
	var thomas := office.people.person("thomas")
	assert_true(thomas != null and not thomas.visible, "Thomas's Congestiedesk still shut")
	_take(office, "fix_unused_capacity")
	assert_true(thomas.visible, "the Congestiedesk open: Thomas at congestion.intake")
	office.free()


func test_most_of_the_cast_lunch_in_the_kantine_between_twelve_and_one() -> void:
	var office := _office()
	var clock := FakeSessionWithClock.new()
	var rachid := office.people.person("rachid")
	assert_true(rachid != null and rachid.visible, "Rachid at Intake in the morning")
	if rachid == null:
		office.free()
		return
	var desk := rachid.position
	var day := office.people.day_of("rachid")
	clock.minute = day.lunch + OfficeDay.WALK_WINDOW
	office.people.refresh(clock)
	assert_false(rachid.visible, "at lunch his desk is empty")
	clock.minute = 13 * 60 + OfficeDay.WALK_WINDOW
	office.people.refresh(clock)
	assert_true(rachid.visible and rachid.position.distance_to(desk) < 0.01, "back after one")
	office.floors.go_to("ground", "lift", true)
	assert_true("canteen" in office.floors.open, "the kantine opened with the tour")
	var lunchers: Array[OfficePerson] = []
	clock.minute = 11 * 60 + 59
	office.people.refresh(clock)
	for p in office.people.people:
		if p.lunch is Dictionary and not (p.lunch as Dictionary).is_empty():
			lunchers.append(p)
			assert_false(p.visible and p.at_lunch, "%s not at lunch yet" % p.id)
	assert_true(lunchers.size() >= 8, "most of the office lunches here: %d" % lunchers.size())
	var canteen := OfficeFloors.room_rect(office.floors.markers()["room:canteen"])
	for p in lunchers:
		clock.minute = office.people.day_of(p.id).lunch + OfficeDay.LUNCH_MINUTES - 1
		office.people.refresh(clock)
		assert_true(p.visible and p.at_lunch, "%s at lunch" % p.id)
		assert_true(canteen.has_point(Vector2(p.position.x, p.position.z)), "%s in the kantine" % p.id)
		assert_eq(p.pose, "sit")
	office.free()


func test_the_session_tells_the_time_of_day() -> void:
	var office := _office()
	assert_eq(office.session.minute_of_day(), GameSession.START_MINUTE, "the game starts at half past eight")
	assert_true(office.session.clock_text().ends_with("08:30"))
	office.free()


func test_names_come_from_the_session_when_it_knows_the_person() -> void:
	var office := _office()
	var clock := FakeSessionWithClock.new()
	clock.known = {"joost": {"name": "Joost van Dijk-Smit", "role": "teamleider"}}
	office.people.refresh(clock)
	var joost := office.people.person("joost")
	assert_eq(joost.display_name, "Joost van Dijk-Smit", "the session's name")
	assert_true(joost.tag.text.begins_with("Joost van Dijk-Smit"), "on the name tag")
	assert_eq(office.people.person("anouk").display_name, "Anouk de Vries", "cast.json as the fallback")
	office.people.refresh(office.session)
	assert_eq(joost.display_name, office.session.person("joost")["name"], "the real session names him")
	office.free()


func test_the_energy_bar_is_a_quiet_line_with_a_check_in_mark() -> void:
	var office := _office()
	var session := FakeSessionWithEnergy.new()
	session.energy = {"anouk": {"energy": 0.3, "needs_talk": true}}
	office.people.refresh(session)
	var anouk := office.people.person("anouk")
	var mat := anouk.bar.material_override as ShaderMaterial
	assert_eq(mat.get_shader_parameter("low_color"), mat.get_shader_parameter("high_color"), "one colour, no orange")
	var line: Color = mat.get_shader_parameter("high_color")
	assert_true(line.s < 0.15, "a muted colour, the name tag's")
	var size := (anouk.bar.mesh as QuadMesh).size
	assert_true(size.y / size.x <= 0.08, "a thin line")
	assert_true(anouk.mark.visible and anouk.mark.text == "…", "the check-in mark beside it")
	assert_false(office.people.person("joost").mark.visible, "no mark without a check-in")
	office.free()


func test_ruuds_whiteboard_opens_the_explainer_and_closes_back_into_the_world() -> void:
	var office := _office()
	var board := office.interactable(OfficeWhiteboard.ID)
	assert_true(board != null, "the whiteboard in the coach's room")
	if board == null:
		office.free()
		return
	office.player.position = board.position
	assert_eq(office.target_near(office.player.position), board)
	assert_eq(office.prompt_near(office.player.position), Office.WHITEBOARD_PROMPT)
	office.use(board)
	var view := office.explainer
	assert_true(view != null and view.def != null and view.def.id == OfficeWhiteboard.EXPLAINER, "the explainer opens")
	assert_true(office.rig.inspecting(), "the camera goes to the board")
	assert_false(office.player.active, "the player stands still")
	assert_true(office.busy(), "the world waits")
	view.close()
	assert_eq(office.explainer, null, "closed")
	assert_true(office.player.active and not office.rig.inspecting(), "back into the world")
	assert_false(office.busy())
	assert_true(office.session.explainers.has_seen(OfficeWhiteboard.EXPLAINER), "kept for the codex")
	office.free()


func test_the_whiteboard_stands_on_the_coachs_floor_only() -> void:
	var office := _office()
	assert_true(office.find_marker(OfficeWhiteboard.NODE) != null, "the board itself, with its collision")
	office.floors.go_to("ground", "lift", true)
	assert_eq(office.interactable(OfficeWhiteboard.ID), null)
	office.free()
