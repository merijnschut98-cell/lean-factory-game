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
	for id in ["scene:mt_room:player", "scene:mt_room:seat0", "scene:mt_room:seat1", "scene:mt_room:screen"]:
		assert_true(markers.has(id), id)
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
