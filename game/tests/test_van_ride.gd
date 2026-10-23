extends TestCase
## The van ride (PLAN 2.15 S2-Y; design 2026-10-21 §1.7, §2.3): a side that sends you out rides
## there. Its monteur waits at their van; E at the passenger door and you sit beside them in
## the cab while the edge of town goes by; the mission's talk with them runs in the cab; you
## arrive at the side's field step (a place on the yard) and ride back after. Holding Spatie
## skips the drive. Also the opleidingsterrein (PLAN 2.3) and the yard's morning (monteurs
## walk to their vans before they drive out).

const SCENE := "res://src/world/office/office.tscn"


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _take(office: Office, mission_id: String) -> void:
	office.session.missions.progress[mission_id] = {"status": "active", "asks": {}, "seen": {}}


## The clock to `minute` of today.
func _at(office: Office, minute: int) -> void:
	office.session.region.net.time += minute - office.session.minute_of_day()


func _on_yard(office: Office, missions: Array[String]) -> void:
	for m in missions:
		_take(office, m)
	office.floors.go_to("yard", "exit", true)
	office.yard.poll()


func _marker(office: Office, id: String) -> Vector3:
	return office.in_office(office.floors.markers()[id]).origin


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Run the ride until it is over or `seconds` have passed (steps of `dt`).
func _drive(ride: VanRide, seconds: float, dt := 0.1) -> void:
	var t := 0.0
	while t < seconds and is_instance_valid(ride) and not ride.over():
		ride.step(dt)
		t += dt


func test_a_ride_waits_at_the_van_only_for_a_side_that_rides() -> void:
	var office := _office()
	_on_yard(office, ["walk_outages"])
	assert_true(office.find_marker("van0") != null, "the yard is loaded")
	assert_eq(office.interactables.filter(func(i: Interactable) -> bool: return i.kind == OfficeYard.RIDE), [],
		"walking the outages stream rides nowhere")
	office.free()
	office = _office()
	_on_yard(office, ["fix_wrong_joint"])
	var door := office.interactable("ride:fix_wrong_joint")
	assert_true(door != null, "the passenger door of the storingsbus")
	if door == null:
		office.free()
		return
	assert_true(_flat(door.position).distance_to(_flat(_marker(office, "ride:van0"))) < 0.05, "at van0's passenger door")
	assert_eq(office.prompt_for(door), "E — Meerijden met Ahmed")
	var ahmed := office.people.person("ahmed")
	assert_true(ahmed.visible, "Ahmed is on the yard")
	assert_true(_flat(ahmed.position).distance_to(_flat(_marker(office, "driver:van0"))) < 0.3,
		"Ahmed waits by the storingsbus")
	_at(office, 11 * 60)
	OfficeYard.park(office.geometry, office.session.minute_of_day(), office.yard.kept_vans())
	assert_true(office.find_marker("van0").visible, "the storingsbus is in")
	office.free()


func test_sandras_van_stays_in_while_she_waits_for_you() -> void:
	var office := _office()
	_on_yard(office, ["fix_not_at_home"])
	_at(office, 11 * 60)
	assert_eq(office.yard.kept_vans(), [5], "Sandra's van stays")
	OfficeYard.park(office.geometry, office.session.minute_of_day(), office.yard.kept_vans())
	assert_true(office.find_marker("van5").visible, "her van is in at eleven")
	assert_false(office.find_marker("van3").visible, "the others are out")
	office.people.refresh(office.session)
	assert_true(office.people.person("sandra").visible, "Sandra waits at her van")
	office.free()


func test_the_ride_seats_you_beside_the_monteur_and_ends_at_the_field_step() -> void:
	var office := _office()
	_on_yard(office, ["fix_wrong_joint"])
	office.interact(office.interactable("ride:fix_wrong_joint"))
	var ride := office.ride
	assert_true(ride != null, "the ride starts")
	if ride == null:
		office.free()
		return
	assert_true(ride.camera.current, "the cab's camera")
	assert_true(office.world_waits(), "no walking in the cab")
	var ahmed := office.people.person("ahmed")
	assert_true(ahmed.position.distance_to(ride.seat("driver").origin) < 0.05, "Ahmed at the wheel")
	assert_eq(ahmed.pose, "sit")
	assert_true(office.player.position.distance_to(ride.seat("passenger").origin) < 0.05, "you beside him")
	assert_true(ride.scenery_moves(0.5), "the edge of town goes by")
	_drive(ride, VanRide.DRIVE_SECONDS - 1.0)
	assert_false(ride.arrived(), "a drive of %d s" % VanRide.DRIVE_SECONDS)
	_drive(ride, 3.0 + VanRide.FADE_SECONDS * 2)
	assert_true(ride.arrived(), "there")
	assert_true(office.ui.place_menu.visible, "the field step's place opens")
	assert_eq(office.ui.place_menu.place, "outages.repair")
	assert_true(_flat(office.player.position).distance_to(_flat(_marker(office, "place:outages.repair"))) < 0.05,
		"you stand at the field step")
	assert_true(office.rig.camera.current, "the world's camera again")
	assert_true(office.session.knows(OfficeYard.rode("fix_wrong_joint")), "the ride is remembered")
	assert_eq(office.interactable("ride:fix_wrong_joint"), null, "and not offered again")
	office.ui.close_panels()
	_drive(ride, VanRide.FADE_SECONDS * 3)
	assert_true(ride.over(), "and back")
	assert_true(office.ride == null, "the world is yours again")
	assert_true(_flat(office.player.position).distance_to(_flat(_marker(office, "ride:van0"))) < 0.05,
		"back at the van")
	assert_false(office.world_waits(), "the world is yours again")
	office.free()


func test_holding_space_skips_the_drive() -> void:
	var office := _office()
	_on_yard(office, ["fix_not_at_home"])
	office.interact(office.interactable("ride:fix_not_at_home"))
	var ride := office.ride
	if ride == null:
		assert_true(false, "no ride")
		office.free()
		return
	_drive(ride, 2.0)
	ride.hold_space(true)
	_drive(ride, SceneLines.HOLD_SKIP_S + VanRide.FADE_SECONDS + 0.3)
	assert_true(ride.arrived(), "skipped to the arrival")
	assert_eq(office.ui.place_menu.place, "meters.visit", "Sandra's addresses")
	office.free()


func test_henks_talk_runs_in_the_cab_and_the_drive_waits_for_it() -> void:
	var office := _office()
	_on_yard(office, ["save_henks_knowledge"])
	var henk := office.people.person("henk")
	assert_true(_flat(henk.position).distance_to(_flat(_marker(office, "driver:van0"))) < 0.3, "Henk waits at the bus")
	office.interact(office.interactable("ride:save_henks_knowledge"))
	var ride := office.ride
	if ride == null:
		assert_true(false, "no ride")
		office.free()
		return
	_drive(ride, VanRide.TALK_AFTER + 0.2)
	assert_true(office.ui.talk_view.visible, "the talk opens on the way")
	assert_eq(str(office.ui.talk_view.talk.get("dialog", "")), "henk_camera")
	assert_true(office.ui.talk_view.person == henk, "with Henk beside you")
	var left := ride.seconds_left
	_drive(ride, 30.0)
	assert_eq(ride.seconds_left, left, "the drive waits while you talk")
	assert_true(ride.frame_shot() in [VanRide.FACE, VanRide.TWO_SHOT], "the cab frames the talk")
	office.ui.close_panels()   # Afronden: the summary
	office.ui.close_panels()
	assert_false(office.ui.talk_view.visible)
	assert_true(henk.position.distance_to(ride.seat("driver").origin) < 0.05, "Henk drives on")
	_drive(ride, VanRide.DRIVE_SECONDS + VanRide.FADE_SECONDS * 2)
	assert_eq(office.ui.place_menu.place, "outages.locate", "an old cable in Nova-Oud")
	office.free()


func test_the_opleidingsterrein_opens_with_henks_knowledge_and_holds_henk_and_ahmed() -> void:
	var office := _office()
	_on_yard(office, ["fix_wrong_joint"])
	assert_false("opleidingsterrein" in office.floors.open, "shut before")
	assert_true(office.interactable("door:opleidingsterrein") != null, "its gate is shut")
	office.free()
	office = _office()
	_on_yard(office, ["save_henks_knowledge"])
	assert_true("opleidingsterrein" in office.floors.open, "open with Henk's knowledge")
	var ground := OfficeFloors.room_rect(office.floors.markers()["room:opleidingsterrein"])
	var ahmed := office.people.person("ahmed")
	assert_true(ahmed.visible and ground.has_point(_flat(ahmed.position)), "Ahmed practises at the trench")
	office.session.missions.facts.add(OfficeYard.rode("save_henks_knowledge"))
	office.people.refresh(office.session)
	var henk := office.people.person("henk")
	assert_true(henk.visible and ground.has_point(_flat(henk.position)), "Henk shows him how, after the ride")
	assert_true(henk.position.distance_to(ahmed.position) < 2.0, "side by side")
	office.free()


func test_the_monteurs_are_at_their_vans_before_they_drive_out() -> void:
	var office := _office()
	_on_yard(office, ["fix_wrong_joint"])
	var crew: Array[OfficePerson] = [office.people.person("ricardo"), office.people.person("joyce")]
	assert_false(crew.has(null), "Ricardo and Joyce on the yard")
	if crew.has(null):
		office.free()
		return
	var vans := ["van2", "van3"]
	for minute: int in [7 * 60 + 40, 7 * 60 + 44]:
		_at(office, minute)
		office.people.refresh(office.session)
		office.people._process(60.0)   # whoever was still walking from the door is there
		for k in crew.size():
			assert_true(crew[k].visible, "%s in at %d" % [crew[k].id, minute])
			assert_true(_flat(crew[k].position).distance_to(_flat(_marker(office, "driver:" + vans[k]))) < 0.3,
				"%s at the van at %d" % [crew[k].id, minute])
	_at(office, 7 * 60 + 45)
	office.people.refresh(office.session)
	assert_true(crew.all(func(p: OfficePerson) -> bool: return not p.visible), "07:45: they drove out")
	_at(office, 16 * 60 + 20)
	office.people.refresh(office.session)
	assert_true(crew.all(func(p: OfficePerson) -> bool: return p.visible), "back in the afternoon")
	_at(office, 17 * 60 + 30)
	office.people.refresh(office.session)
	office.people._process(120.0)
	assert_true(crew.all(func(p: OfficePerson) -> bool: return not p.visible), "and home")
	office.free()


func test_a_monteur_walks_in_from_the_back_door_in_the_morning() -> void:
	var office := _office()
	_on_yard(office, ["fix_wrong_joint"])
	_at(office, 7 * 60)
	office.people.refresh(office.session)
	var ricardo := office.people.person("ricardo")
	assert_false(ricardo.visible, "not in yet at seven")
	_at(office, 7 * 60 + 19)
	office.people.refresh(office.session)
	for i in 20:   # Dirk came in by the same door just before him: he steps out after
		office.people._process(0.1)
	assert_true(ricardo.visible and ricardo.playing() in ["walk", ""], "walking to his van")
	assert_true(_flat(ricardo.position).distance_to(_flat(_marker(office, "arrive:exit"))) < 3.0, "from the back door")
	office.free()
