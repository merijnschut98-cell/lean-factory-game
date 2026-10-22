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
