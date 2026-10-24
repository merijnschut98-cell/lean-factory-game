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
