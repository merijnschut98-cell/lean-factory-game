extends TestCase
## A milestone's scene in the world (phase-2 design §3.1; OfficeMilestone): on day 100
## Ruud and Frank wait in the MT-kamer on the 2e (opened for it), walking in plays the
## scene as subtitles, the player answers Frank's one question, the milestone completes.

const SCENE := "res://src/world/office/office.tscn"


func test_walking_into_the_mt_room_on_day_100_plays_the_review() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.play_start -= SimCalendar.days(100)
	s.pass_time(0)
	assert_eq(s.missions.status("review_100_days"), "active")
	assert_true("mt_room" in office.floors.open_now(), "the MT-kamer opens for its scene")
	assert_true(office.floors.go_to("second", "lift"), "the 2e is open")
	var m := office.milestone
	m.step(1.0)
	assert_eq(m._people.keys(), ["ruud", "frank"], "Ruud and Frank wait in the room")
	assert_eq(m.playing, "", "not before the player walks in")
	var rect := OfficeFloors.room_rect(office.floors.markers()["room:mt_room"])
	office.player.position = Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	m.step(1.0)
	assert_eq(m.playing, "review_100_days")
	assert_true(m.lines.holds(), "the scene holds the player")
	m.lines.finish()
	assert_true(m.lines.asking(), "Frank's question")
	m.lines.pick(2)
	m.lines.finish()
	assert_eq(m.playing, "")
	assert_eq(s.missions.status("review_100_days"), "completed")
	assert_true(s.knows("flag:day100_patience"), "the answer is remembered")
	m.step(1.0)
	assert_true(m._people.is_empty(), "they leave the room")
	office.free()


# ── The MT-kamer as a stage (PLAN 2.16): seats round the table and a spot at the screen,
# from the 2e's model; the camera on whoever speaks.

const SECOND_MODEL := "res://assets/office/office_second.glb"


func test_the_mt_room_has_seats_round_the_table_and_a_spot_at_the_screen() -> void:
	var geometry: Node3D = load(SECOND_MODEL).instantiate()
	var markers := OfficeBuilding.markers(geometry)
	for id in ["scene:mt_room:player", "scene:mt_room:seat0", "scene:mt_room:seat1", "scene:mt_room:screen",
			"kpi_board", "scene:directors_obeya:board"]:
		assert_true(markers.has(id), id)
	assert_true(Office._find_marker(geometry, "obeya2_board2_frame", Office._loose("obeya2_board2_frame")) != null,
		"the obeya wall's board S3-B anchors to keeps its name")
	geometry.free()


func _spot(office: Office, id: String) -> Vector3:
	return office.in_office(office.floors.markers()["scene:mt_room:" + id]).origin * Vector3(1, 0, 1)


func test_the_review_seats_ruud_frank_presents_at_the_screen_and_you_sit_down() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.play_start -= SimCalendar.days(100)
	s.missions.progress["fix_silo_kpis"] = {"status": "active", "asks": {}, "seen": {}}   # Frank's Obeya open
	s.pass_time(0)
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("second", "lift", true)
	var m := office.milestone
	m.step(1.0)
	var ruud: OfficePerson = m._people.get("ruud")
	var frank: OfficePerson = m._people.get("frank")
	assert_true(ruud != null and frank != null)
	if ruud == null or frank == null:
		office.free()
		return
	assert_near(ruud.position.distance_to(_spot(office, "seat0")), 0.0, 0.01, "Ruud at the table")
	assert_eq(ruud.pose, "sit")
	assert_near(frank.position.distance_to(_spot(office, "screen")), 0.0, 0.01, "Frank at the screen with his numbers")
	assert_true(office.people.person("frank") == null or not office.people.person("frank").visible,
		"Frank is not at his desk in the Obeya at the same time")
	var rect := OfficeFloors.room_rect(office.floors.markers()["room:mt_room"])
	office.player.position = Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	m.step(1.0)
	assert_eq(m.playing, "review_100_days")
	assert_true(office.player.seated, "'Kom erbij zitten': you sit down")
	assert_near(office.player.position.distance_to(_spot(office, "player")), 0.0, 0.01, "at your seat")
	m.step(0.0)
	assert_true(office.rig._inspect.get("shot") in [CameraRig.FACE, CameraRig.CONVERSE], "the camera on Ruud as he speaks")
	m.lines.finish()
	m.step(0.0)
	assert_true(m.lines.asking())
	assert_eq(office.rig._inspect.get("shot"), CameraRig.TWO_SHOT, "Frank's question: the two of you")
	m.lines.pick(0)
	m.lines.finish()
	assert_eq(m.playing, "")
	assert_false(office.player.seated, "you get up")
	m.step(1.0)
	office.people.refresh(s)
	assert_true(office.people.person("frank").visible, "Frank back at his desk")
	office.free()


const FLOW := {"intake": ["intake_lead_time", "intake_oldest"], "work_prep": ["work_prep_lead_time", "work_prep_oldest"],
	"planners": ["planners_on_time", "planners_oldest"], "contact_centre": ["contact_centre_resolved", "contact_centre_reachable"]}


## The office on the 2e with Het eerste kwartaal open (fix_silo_kpis done): Ruud and Frank
## wait at Directie & Obeya.
func _quarter_office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.done_once["fix_silo_kpis"] = true
	s.pass_time(0)
	assert_eq(s.missions.status("first_kpi_review"), "active", "it opens after fix_silo_kpis")
	assert_true("directors_obeya" in office.floors.open_now())
	assert_true(office.floors.go_to("second", "lift"))
	office.milestone.step(1.0)
	assert_eq(office.milestone._people.keys(), ["ruud", "frank"])
	return office


func _walk_in(office: Office) -> void:
	var rect := OfficeFloors.room_rect(office.floors.markers()["room:directors_obeya"])
	office.player.position = Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	office.milestone.step(1.0)


## Het eerste kwartaal (PLAN 2.4c, 2.5): the scene reads the silo fix and Frank, ends at
## the KPI board (born here when no fix hung it), and what is said after it reads the
## choice hung and the forecast. It completes only once the board is hung.
func test_the_first_quarterly_review_ends_at_the_kpi_board() -> void:
	var office := _quarter_office()
	var s := office.session
	var m := office.milestone
	assert_false(s.region.board.unlocked, "no fix hung the board")
	_walk_in(office)
	assert_eq(m.playing, "first_kpi_review")
	var before: Array = m._scene["before"].map(func(l: Dictionary) -> String: return l["text"])
	m.lines.finish()
	assert_ne(office.kpi_board, null, "the scene ends at the board")
	assert_true(s.region.board.unlocked, "the board is born in the scene")
	assert_eq(s.finish_scene("first_kpi_review"), "review_first", "not done before the board is hung")
	for pool: String in FLOW:
		for id: String in FLOW[pool]:
			office.kpi_board.pick(pool, id)
	var result := office.kpi_board.hang_now()
	office.kpi_board.close()
	assert_true(m.lines.holds(), "Ruud and Frank go on")
	var said: Array = m._scene["after"].map(func(l: Dictionary) -> String: return l["text"])
	var frank_flow := "Hoe lang iets duurt, en wat er blijft liggen."
	assert_true(said.any(func(t: String) -> bool: return t.contains(frank_flow)), "Frank reads the flow KPIs: %s" % [said])
	var forecast := "De analisten zien met deze getallen een beter kwartaal"
	assert_eq(said.any(func(t: String) -> bool: return t.contains(forecast)), result["paid"] > 0.0, "Ruud reads the forecast")
	assert_false(before.any(func(t: String) -> bool: return t.contains(frank_flow)), "the choice is read after the board")
	m.lines.finish()
	assert_eq(s.missions.status("first_kpi_review"), "completed")
	m.step(1.0)
	assert_true(m._people.is_empty(), "they leave the room")
	office.free()


## Walking away from the board without hanging it pauses the review: nothing is lost,
## and walking back in starts it again.
func test_leaving_the_board_unhung_waits_for_you_to_come_back() -> void:
	var office := _quarter_office()
	var m := office.milestone
	_walk_in(office)
	m.lines.finish()
	office.kpi_board.close()
	assert_eq(m.playing, "", "the review waits")
	assert_eq(office.session.missions.status("first_kpi_review"), "active")
	m.step(1.0)
	assert_eq(m.playing, "", "not again while you are still in the room")
	assert_eq(m._people.keys(), ["ruud", "frank"], "they wait for you")
	office.player.position = Vector3(1000, 0, 1000)
	m.step(1.0)
	_walk_in(office)
	assert_eq(m.playing, "first_kpi_review", "back in, it starts again")
	office.free()


## A beat's `stand_at` (scenes.yaml): Ruud and Frank walk up to the KPI board for the
## board's line, not left between the door and the room's middle.
func test_ruud_and_frank_stand_at_the_kpi_board_for_its_line() -> void:
	var office := _quarter_office()
	var m := office.milestone
	var spot := office.in_office(office.floors.markers()["scene:directors_obeya:board"]).origin * Vector3(1, 0, 1)
	var far := func() -> float:
		return maxf(m._people["ruud"].position.distance_to(spot), m._people["frank"].position.distance_to(spot))
	assert_true(far.call() > 2.0, "not at the board while they wait")
	_walk_in(office)
	while m.lines.speaking() and not m.lines.current().has("stand_at"):
		m.lines.next()
	assert_true(m.lines.current().has("stand_at"), "the board's line stages them")
	m.step(0.0)
	assert_true(far.call() < 1.5, "both at the board while Ruud hands it over: %.2f m" % far.call())
	assert_true(m._people["ruud"].position.distance_to(m._people["frank"].position) > 0.8, "side by side, not in one spot")
	assert_true(office.player.position.distance_to(spot) < 2.0, "'Kom erbij staan': you stand at the board with them")
	office.free()


## Skipping the lines still leaves them at the board when it opens.
func test_skipping_to_the_board_still_stages_them() -> void:
	var office := _quarter_office()
	var m := office.milestone
	var spot := office.in_office(office.floors.markers()["scene:directors_obeya:board"]).origin * Vector3(1, 0, 1)
	_walk_in(office)
	m.lines.finish()
	assert_ne(office.kpi_board, null)
	assert_true(m._people["frank"].position.distance_to(spot) < 1.5, "Frank at the board")
	office.free()


## Where the rig's camera sees from for its framing now.
func _eye(office: Office) -> Vector3:
	var f := office.rig._inspect
	return office.rig.view_from(f["at"], f["yaw"], f["distance"], f["pitch"], f["lift"], f["shift"])


## The MT-kamer's pillar stands by the table's door end: whichever seat you take (and a
## little off it), the scene camera picks a side from which you and the speaker are both
## in sight (docs/screenshots/play_mt_room_scene.png had the pillar over the seated player).
func test_the_scene_camera_keeps_the_pillar_out_of_the_way() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.play_start -= SimCalendar.days(100)
	s.pass_time(0)
	office.floors.go_to("second", "lift", true)
	var m := office.milestone
	m.step(1.0)
	for spot in ["player", "seat0", "seat1", "seat2", "seat3"]:
		for nudge: Vector3 in [Vector3.ZERO, Vector3(0, 0, 0.45)]:   # as a body settles in its chair
			office.player.sit_at(office.in_office(office.floors.markers()["scene:mt_room:" + spot]))
			office.player.position += nudge
			var at := "you at %s%s" % [spot, " (nudged)" if nudge != Vector3.ZERO else ""]
			for who: String in m._people:
				var speaker: OfficePerson = m._people[who]
				office.frame_scene(speaker, OfficeMilestone.TABLE_LIFT)
				var eye := _eye(office)
				assert_true(office.sees(eye, speaker), "%s: %s whole in the two-shot" % [at, who])
				assert_true(office.sees(eye, null), "%s: you whole in the two-shot on %s" % [at, who])
				office.frame_face(speaker)
				if office.rig.shot == CameraRig.FACE:
					assert_true(office.in_sight(_eye(office), office.talk_point(speaker)), "%s: %s's face" % [at, who])
	office.free()


## Seated at a scene's table the player stays in the chair: the physics does not push the
## body off it (it slid half a metre in play_mt_room_scene).
func test_sitting_down_at_the_table_stops_the_body_sliding() -> void:
	var player := Player.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(player)
	assert_true(player.is_physics_processing(), "a standing body walks")
	player.sit_at(Transform3D(Basis(), Vector3(1, 0, 2)))
	assert_false(player.is_physics_processing(), "no physics step while seated")
	player.stand_up()
	assert_true(player.is_physics_processing(), "walking again once up")
	player.free()


## Review S3 #2: a scene starting lets a ringing call go to voicemail (no penalty).
func test_a_scene_lets_a_ringing_call_go_to_voicemail() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.play_start -= SimCalendar.days(100)
	for id in ["fix_unused_capacity", "fix_incomplete_application"]:
		s.missions.done_once[id] = true
	assert_eq(s.accept("fix_status_callers"), "")
	s.region.net.time += 10 * 60 - s.minute_of_day()
	s.pass_time(0)
	assert_true(office.floors.go_to("second", "lift", true))
	office.ui.after_action()
	assert_true(office.ui.incoming.visible, "El Amrani rings")
	var unread := office.ui.phone.unread_count()
	var m := office.milestone
	m.step(1.0)
	var rect := OfficeFloors.room_rect(office.floors.markers()["room:mt_room"])
	office.player.position = Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	m.step(1.0)
	assert_eq(m.playing, "review_100_days")
	assert_false(office.world_free(), "a scene plays")
	assert_false(office.ui.incoming.visible, "the call goes to voicemail")
	assert_eq(office.ui.phone.unread_count(), unread + 1, "her voicemail in Berichten")
	office.free()
