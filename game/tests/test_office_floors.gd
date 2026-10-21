extends TestCase
## The head office as three floors (PLAN 2.1), headless: every floor's model carries the
## markers the building data and the people need; the stairs and the lift take the same
## player to another floor; rooms open as missions need them.

const SCENE := "res://src/world/office/office.tscn"


## A returning player's game (the training week done), or the week's Monday (`training`).
func _office(training := false) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = training
	office.build()
	return office


func _building() -> OfficeBuilding:
	return OfficeBuilding.load_from(Catalog.DATA_DIR)


func _take(office: Office, mission_id: String) -> void:
	office.session.missions.progress[mission_id] = {"status": "active", "asks": {}, "seen": {}}


## The markers of floor `id`'s model, in the floor's own space.
func _markers(building: OfficeBuilding, id: String) -> Dictionary:
	var geometry: Node3D = (load(building.model_path(id)) as PackedScene).instantiate()
	var out := {}
	var all := OfficeBuilding.markers(geometry)
	for m: String in all:
		out[m] = {"at": all[m].global_transform.origin if all[m].is_inside_tree() else _origin(all[m]),
			"rect": OfficeFloors.room_rect(all[m])}
	geometry.free()
	return out


static func _origin(n: Node) -> Vector3:
	var t := Transform3D.IDENTITY
	while n != null:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin


func _at(m: Dictionary) -> Vector2:
	return Vector2(m["at"].x, m["at"].z)


func test_the_building_has_three_floors_each_with_its_own_model() -> void:
	var b := _building()
	assert_eq(b.error, "")
	assert_eq(b.floors.filter(func(f: Dictionary) -> bool: return f["outside_of"].is_empty()).map(
		func(f: Dictionary) -> String: return f["name"]), ["Begane grond", "1e verdieping", "2e verdieping"])
	assert_eq(b.start_floor, "first")
	assert_eq(b.model_path("first"), Office.MODEL, "the 1e is the connections office's model, as before")
	for f in b.floors:
		assert_true(ResourceLoader.exists(b.model_path(f["id"])), "%s has its glb" % f["id"])
	assert_eq(b.next_floor("first", 1), "second")
	assert_eq(b.next_floor("first", -1), "ground")
	assert_eq(b.next_floor("second", 1), "", "no floor above the top")


func test_the_yard_is_outside_the_begane_grond_behind_the_kantines_back_door() -> void:
	var b := _building()
	var yard := b.floor_of("yard")
	assert_eq([yard.get("name"), yard.get("outside_of"), yard.get("level")], ["Werf", "ground", 0])
	assert_true(ResourceLoader.exists(b.model_path("yard")), "the yard has its glb")
	assert_eq(b.next_floor("ground", 1), "first", "the stairs skip the yard")
	assert_eq(b.next_floor("first", -1), "ground")
	var ground := _markers(b, "ground")
	var out := _markers(b, "yard")
	for key in ["exit:yard", "arrive:exit"]:
		assert_true(ground.has(key), "the kantine: %s" % key)
	for key in ["exit:ground", "arrive:exit"]:
		assert_true(out.has(key), "the yard: %s" % key)
	if ground.has("exit:yard") and out.has("exit:ground"):
		assert_true(_at(ground["exit:yard"]).distance_to(_at(out["exit:ground"])) < 2.5, "one door, seen from both sides")
	var kantine: Rect2 = ground["room:canteen"]["rect"]
	assert_true(kantine.has_point(_at(ground["exit:yard"])), "the back door is the kantine's")


func test_the_back_door_takes_the_same_player_out_and_back_in() -> void:
	var office := _office()
	_take(office, "fix_wrong_joint")
	office.floors.go_to("ground", "lift", true)
	var player := office.player
	var door := office.interactable("exit:yard")
	assert_true(door != null, "the back door in the kantine")
	assert_eq(office.prompt_for(door), "E — Naar de werf")
	office.interact(door)
	assert_eq(office.floors.floor_id, "yard", "out on the yard")
	assert_true(office.player == player, "the same player")
	var arrive := office.in_office(office.floors.markers()["arrive:exit"]).origin
	assert_true(player.position.distance_to(arrive) < 0.01, "outside the door")
	assert_eq(office.interactable("lift"), null, "no lift on the yard")
	var under := PackedVector2Array()   # the collision's corners below the ground's surface
	for v in office._collision_faces():
		if v.y < -0.15:
			under.append(Vector2(v.x, v.z))
	var ground := Rect2(under[0], Vector2.ZERO) if not under.is_empty() else Rect2()
	for p in under:
		ground = ground.expand(p)
	assert_true(ground.has_point(Vector2(arrive.x, arrive.z)), "ground to stand on under the door (the player does not fall)")
	var back := office.interactable("exit:ground")
	assert_eq(office.prompt_for(back), "E — Naar binnen (begane grond)")
	office.interact(back)
	assert_eq(office.floors.floor_id, "ground", "and back in the kantine")
	assert_false(office.floors.go_to("yard", "lift"), "the lift does not go to the yard")
	assert_true(OfficeFloors.NO_LIFT_OUTSIDE % "werf" in office.ui.hud.toast_texts())
	office.free()


func test_the_vans_go_out_in_the_morning_and_come_back_in_the_afternoon() -> void:
	var office := _office()
	_take(office, "fix_wrong_joint")
	office.floors.go_to("yard", "exit", true)
	var vans := range(6).map(func(k: int) -> Node3D: return office.find_marker("van%d" % k))
	assert_false(vans.has(null), "six vans in the model")
	var parked := func() -> Array:
		return range(6).filter(func(k: int) -> bool: return vans[k].visible)
	for at: Array in [[7 * 60, [0, 1, 2, 3, 4, 5], "07:00: every bay full"],
			[11 * 60, OfficeYard.ON_CALL, "11:00: only the storingsbussen"],
			[17 * 60, [0, 1, 2, 3, 4, 5], "17:00: back"]]:
		OfficeYard.park(office.geometry, at[0])
		assert_eq(parked.call(), at[1], at[2])
	office.free()


func test_the_yard_is_shut_until_a_mission_needs_it() -> void:
	var office := _office(true)   # Monday of the training week
	office.floors.go_to("ground", "lift", true)
	var door := office.interactable("exit:yard")
	assert_true(door != null)
	office.interact(door)
	assert_eq(office.floors.floor_id, "ground", "nothing on the yard is open yet")
	assert_true(OfficeFloors.CLOSED_OUTSIDE % "werf" in office.ui.hud.toast_texts())
	office.free()


func test_every_floor_carries_its_rooms_seams_and_places() -> void:
	var b := _building()
	for f in b.floors:
		var id: String = f["id"]
		var m := _markers(b, id)
		if f.get("outside_of", "") != "":
			for r in b.rooms_on(id):
				_room_markers(id, r, m)
			continue
		for key in ["lift", "arrive:lift"]:
			assert_true(m.has(key), "%s: %s" % [id, key])
		var above := not b.next_floor(id, 1).is_empty()
		var below := not b.next_floor(id, -1).is_empty()
		assert_eq(m.has("stairs_up"), above, "%s: stairs up only with a floor above" % id)
		assert_eq(m.has("arrive:stairs_down"), above, "%s: arriving from above where the stairs go up" % id)
		assert_eq(m.has("stairs_down"), below, "%s: stairs down only with a floor below" % id)
		assert_eq(m.has("arrive:stairs_up"), below, "%s: arriving from below where the stairs come up" % id)
		for r in b.rooms_on(id):
			_room_markers(id, r, m)


## A room's markers on floor `id`: its area, its door while it can be shut, its places inside it.
func _room_markers(id: String, r: Dictionary, m: Dictionary) -> void:
	var room: String = "room:" + r["id"]
	assert_true(m.has(room), "%s: a marker for room %s" % [id, r["id"]])
	if not m.has(room):
		return
	var rect: Rect2 = m[room]["rect"]
	assert_true(rect.get_area() > 4.0, "%s has a floor area" % r["id"])
	if not OfficeBuilding.START in r["opens_with"]:
		assert_true(m.has("door:" + r["id"]), "%s: a door to shut %s" % [id, r["id"]])
		if m.has("door:" + r["id"]):
			assert_false(rect.has_point(_at(m["door:" + r["id"]])), "%s's door marker stands outside it" % r["id"])
	for place: String in r["places"]:
		var key: String = "place:" + place
		assert_true(m.has(key), "%s: a marker for %s" % [id, place])
		if m.has(key):
			assert_true(rect.has_point(_at(m[key])), "%s stands in %s" % [place, r["id"]])


func test_every_station_in_an_open_room_can_be_walked_to() -> void:
	var office := _office()
	for i: Interactable in office.interactables:
		if i.kind == "place":
			assert_false(office.nav().path(office.player.position, i.position).is_empty(), "%s can be reached" % i.id)
			assert_true(office.nav().walkable(i.position), "%s's ring stands on free floor" % i.id)
	office.free()


func test_the_1e_keeps_its_markers_where_they_were() -> void:
	var m := _markers(_building(), "first")
	var expected := {   # Godot (x, z): build_office.py INTERACTIONS, unchanged by the floors
		"place:connections.intake": Vector2(3.2, -4.75), "place:connections.design": Vector2(9.0, -5.4),
		"obeya": Vector2(22.6, -3.4), "coach": Vector2(22.4, -13.0), "mission_board": Vector2(1.3, -9.9),
		"spawn": Vector2(1.6, -7.95)}
	for key: String in expected:
		assert_true(m.has(key) and _at(m[key]).distance_to(expected[key]) < 0.01, "%s stays put" % key)


func test_the_peoples_desks_and_lunch_chairs_resolve_on_their_floor() -> void:
	var office := _office()
	for f in office.floors.building.floors:
		office.floors.go_to(f["id"], "lift", true)
		for entry in CharacterModel.cast():
			var spot: Dictionary = entry.get("office", {})
			var lunch: Dictionary = spot.get("lunch", {})
			if spot.has("seat") and office.floors.here(spot):
				assert_true(office.find_marker(str(spot["seat"]) + "_desk") != null, "%s's desk" % entry["id"])
				assert_true(office.find_marker(str(spot["seat"]) + "_chair") != null, "%s's chair" % entry["id"])
				assert_true(office.people.person(entry["id"]) != null, "%s is placed" % entry["id"])
			if lunch.has("chair") and office.floors.here(lunch):
				assert_true(office.find_marker(str(lunch["chair"])) != null, "%s's lunch chair" % entry["id"])
	office.free()


func test_only_the_rooms_a_mission_needs_are_open() -> void:
	var office := _office(true)   # Monday of the training week
	assert_eq(office.floors.floor_id, "first")
	assert_true("connections" in office.floors.open and "reception" in office.floors.open, "open from the start")
	assert_false("revision_gis" in office.floors.open, "no mission needs Revisie & GIS yet")
	assert_true(office.interactable("door:revision_gis") != null, "its door is there, shut")
	assert_eq(office.interactable("place:connections.revision"), null, "its team is not offered")
	assert_true(office.find_marker("lockcol_revision_gis") != null, "the door blocks the way")
	var inside := Vector3(-11.0, 0, -10.2)   # open floor in Revisie & GIS
	assert_true(office.nav().path(office.player.position, inside).is_empty(), "no way in")
	assert_false(office.floors.building.floor_open("second", office.floors.open), "the 2e has nothing open")
	_take(office, "fix_revision_backlog")
	office.floors._process(OfficeFloors.POLL_SECONDS)
	assert_true("revision_gis" in office.floors.open, "taking the mission on opens the room")
	assert_eq(office.interactable("door:revision_gis"), null, "the door is open")
	assert_true(office.interactable("place:connections.revision") != null, "the team is there to visit")
	assert_eq(office.find_marker("lockcol_revision_gis"), null, "nothing blocks the doorway")
	assert_false(office.nav().path(office.player.position, inside).is_empty(), "a way in")
	office.free()


func test_a_shut_door_says_so() -> void:
	var office := _office(true)
	var door := office.interactable("door:meter_data")
	assert_eq(office.prompt_for(door), "E — Meetdata & registratie: dicht")
	office.interact(door)
	assert_true(OfficeFloors.CLOSED_DOOR % "Meetdata & registratie" in office.ui.hud.toast_texts())
	assert_false(office.ui.is_busy(), "no panel opens")
	office.free()


func test_the_lift_takes_the_same_player_to_another_floor() -> void:
	var office := _office()
	var player := office.player
	var session := office.session
	office.ui.mission_board.accept("fix_custom_design")
	var clock := session.clock_text()
	office.interact(office.interactable("lift"))
	var map := office.ui.office_map
	assert_true(office.ui.phone.visible and office.ui.phone.current == Phone.MAP and map.lift,
		"the lift opens the building's directory on the phone's map")
	assert_eq(map.title_label.text, OfficeMap.LIFT_TITLE)
	map.choose_floor("ground")
	assert_false(office.ui.phone.visible, "the lift goes")
	assert_eq(office.floors.floor_id, "ground")
	assert_true(office.player == player and office.session == session, "the same player, the same game")
	assert_eq(session.clock_text(), clock, "no time passes")
	assert_eq(session.active_missions().map(func(m: MissionDef) -> String: return m.id), ["fix_custom_design"])
	var arrive := office.in_office(office.floors.markers()["arrive:lift"]).origin
	assert_true(player.position.distance_to(arrive) < 0.01, "you step out of the lift")
	assert_true(player.active, "and walk on")
	assert_true(office.interactable("door:contact_centre") != null, "the begane grond's points")
	assert_eq(office.interactable("obeya"), null, "not the 1e's")
	assert_true(office.people.person("joost") == null or not office.people.person("joost").visible,
		"nobody of the 1e's desks is down here (Joost comes down only for lunch)")
	assert_false(office.people.people.any(func(p: OfficePerson) -> bool: return p.visible),
		"the Klantcontactcentrum is shut and it is not lunchtime: nobody about")
	assert_true(office.rig.bounds.has_point(Vector2(player.position.x, player.position.z)), "the camera follows")
	office.free()


func test_a_shut_floor_is_not_reached() -> void:
	var office := _office()
	assert_false(office.floors.go_to("second", "lift"), "nothing open on the 2e")
	assert_eq(office.floors.floor_id, "first")
	assert_true(OfficeFloors.CLOSED_FLOOR % "2e verdieping" in office.ui.hud.toast_texts())
	assert_eq(office.prompt_for(office.interactable("stairs_up")), "E — Trap naar de 2e verdieping (dicht)")
	office.interact(office.interactable("lift"))
	office.ui.office_map.refresh()
	var buttons := office.ui.office_map.floor_bar.get_children().filter(func(n: Node) -> bool: return n is Button)
	var second: Button = buttons.filter(func(b: Button) -> bool: return b.text.contains("2e verdieping"))[0]
	assert_true(second.disabled, "the lift's button for the 2e does nothing")
	_take(office, "fix_silo_kpis")
	assert_true(office.floors.go_to("second", "lift"), "a mission there opens the floor")
	office.free()


func test_walking_onto_the_stairs_takes_them_and_walking_past_does_not() -> void:
	var office := _office()
	var down := office.interactable("stairs_down")
	var run := -down.basis.z
	office.player.position = down.position - run * 1.2
	office.floors._walk_in()
	office.player.velocity = Vector3(1.4, 0, 0)   # across the hall, past the stairs
	office.player.position = down.position
	office.floors._walk_in()
	assert_eq(office.floors.floor_id, "first", "walking past is not walking down")
	office.player.position = down.position - run * 1.2
	office.floors._walk_in()
	office.player.velocity = run * 1.4
	office.player.position = down.position
	office.floors._walk_in()
	assert_eq(office.floors.floor_id, "ground", "down the stairs")
	var arrive := office.in_office(office.floors.markers()["arrive:stairs_down"]).origin
	assert_true(office.player.position.distance_to(arrive) < 0.01, "at the foot of the stairs")
	office.floors._walk_in()
	assert_eq(office.floors.floor_id, "ground", "arriving does not take the stairs back")
	office.interact(office.interactable("stairs_up"))
	assert_eq(office.floors.floor_id, "first", "E on the stairs goes up")
	var up_arrival := office.in_office(office.floors.markers()["arrive:stairs_up"]).origin
	assert_true(office.player.position.distance_to(up_arrival) < 0.01, "at the head of the stairs")
	office.free()


func test_the_map_switches_floors_and_shows_the_rooms() -> void:
	var office := _office(true)   # Monday: two rooms on the 1e still shut
	office.ui.toggle_phone(Phone.MAP)
	var map := office.ui.office_map
	assert_eq(map.floor_here, "first")
	assert_eq(map.title_label.text, OfficeMap.TITLE % "1e verdieping")
	assert_true(map.player_shown(), "you are on the floor shown")
	var shut := map.rooms.filter(func(r: Dictionary) -> bool: return not r["open"]).map(func(r: Dictionary) -> String: return r["id"])
	shut.sort()
	assert_eq(shut, ["meter_data", "revision_gis"], "the shut rooms are greyed")
	assert_true("Lift" in map.labels() and "Trap omhoog" in map.labels())
	map.choose_floor("ground")
	assert_eq(map.floor_shown, "ground")
	assert_eq(map.title_label.text, OfficeMap.TITLE % "Begane grond")
	assert_eq(office.floors.floor_id, "first", "looking is not going")
	assert_false(map.player_shown(), "you are not down there")
	assert_true("Lift" in map.labels(), "the begane grond's places")
	assert_false("Werkvoorbereiding & ontwerp" in map.labels())
	assert_true(map.floor_rect.size.x > 40.0, "the whole building's width")
	office.free()


func test_a_mission_on_another_floor_marks_that_floor() -> void:
	var office := _office()
	_take(office, "fix_status_callers")
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.ui.toggle_phone(Phone.MAP)
	var texts := office.ui.office_map.floor_bar.get_children().filter(func(n: Node) -> bool: return n is Button) \
		.map(func(b: Button) -> String: return b.text)
	assert_true(texts.any(func(t: String) -> bool: return t.begins_with("● Begane grond")), "the floor with the mission's place: %s" % [texts])
	office.free()


func test_room_openers_read_missions_taken_and_kinds_made_in_play() -> void:
	assert_true(OfficeBuilding.opens(["start"], {}))
	assert_false(OfficeBuilding.opens([], {"fix_x": true}), "an empty list keeps the door shut")
	assert_true(OfficeBuilding.opens(["fix_x"], {"fix_x": true}))
	assert_false(OfficeBuilding.opens(["fix_x"], {"fix_y": true}))
	assert_true(OfficeBuilding.opens(["terugval_*"], {"terugval_custom_design": true}), "a check-in opens the kantine")


func test_the_floor_is_kept_in_the_save_and_a_resumed_game_starts_there() -> void:
	var office := _office()
	office.floors.go_to("ground", "lift")
	assert_eq(office.ui.session_layer.floor_id, "ground", "the session layer (saved with the game) keeps the floor")
	var layer := SessionLayer.new()
	layer.load_dict(office.ui.session_layer.to_dict())
	assert_eq(layer.floor_id, "ground", "through the save")
	layer.load_dict({"floor_id": 7})
	assert_eq(layer.floor_id, "", "junk reads as no floor")
	office.free()
	var resumed: Office = load(SCENE).instantiate()
	resumed.training = false
	resumed.resume_on("ground")
	assert_eq(resumed.floors.floor_id, "ground", "a resumed game opens on the floor it was left on")
	var arrive := resumed.in_office(resumed.floors.markers()["arrive:lift"]).origin
	assert_true(resumed.player.position.distance_to(arrive) < 0.01, "by the lift")
	resumed.free()
	var unknown: Office = load(SCENE).instantiate()
	unknown.training = false
	unknown.resume_on("attic")
	assert_eq(unknown.floors.floor_id, "first", "an unknown floor: the start floor")
	unknown.free()


func test_without_world_data_the_building_is_the_1e_alone() -> void:
	var b := OfficeBuilding.load_from("res://does_not_exist")
	assert_ne(b.error, "")
	assert_eq(b.floors.size(), 1)
	assert_eq(b.model_path(b.start_floor), Office.MODEL)
