extends TestCase
## People react (Phase 2 design §1.4, S1-C), headless: they turn to you within two metres and
## back after, greet you once a day by your name, give a quick line when there is nothing to
## discuss (no panel), chat in pairs at the coffee corner, remember yesterday's talk in the
## greeting, and carry the talk's openness band in their posture.

const SCENE := "res://src/world/office/office.tscn"
const FRAME := 1.0 / 30.0


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	office.session.player.name = "Noor"
	return office


## A person on their own (no office), standing or seated, facing -Z at the origin.
func _person(id: String, pose: String) -> OfficePerson:
	var p := OfficePerson.create({"id": id, "office": {"pose": pose}})
	p.place(Vector3.ZERO, Vector3.FORWARD)
	return p


func _turn(p: OfficePerson, seconds := 2.0) -> void:
	for i in int(seconds / FRAME):
		p.turn(FRAME)


## The yaw (rad) of a person looking from `from` to `at`.
static func _yaw_to(from: Vector3, at: Vector3) -> float:
	return atan2(-(at.x - from.x), -(at.z - from.z))


func test_within_two_metres_a_standing_person_turns_to_the_player_and_back_after() -> void:
	var p := _person("kim", "idle")
	var rest := p.rotation.y
	var player := Vector3(1.5, 0, 0)
	p.face_toward(player)
	_turn(p)
	assert_near(p.rotation.y, _yaw_to(p.position, player), 0.02, "turned all the way to the player")
	p.face_back()
	_turn(p)
	assert_near(p.rotation.y, rest, 0.02, "back to their work")
	p.free()


func test_a_seated_person_swivels_part_of_the_way_and_the_office_turns_them() -> void:
	var office := _office()
	var sanne := office.people.person("sanne")
	var rest := sanne.rotation.y
	office.player.position = sanne.position + sanne.basis.x * 1.5   # to her right, within reach
	office.reactions.react()
	assert_true(sanne.facing(), "she noticed the player")
	_turn(sanne)
	var turned := absf(angle_difference(rest, sanne.rotation.y))
	assert_near(turned, OfficePerson.SWIVEL, 0.02, "seated: swivels the chair part of the way")
	var toward := _yaw_to(sanne.position, office.player.position)
	assert_true(absf(angle_difference(sanne.rotation.y, toward)) < absf(angle_difference(rest, toward)), "towards the player")
	office.player.position = sanne.position + sanne.basis.x * 6.0
	office.reactions.react()
	assert_false(sanne.facing(), "the player passed")
	_turn(sanne)
	assert_near(sanne.rotation.y, rest, 0.02, "and she turns back to her screen")
	office.free()


func test_one_greeting_per_person_per_day_by_name() -> void:
	var office := _office()
	var session := office.session
	var sanne := office.people.person("sanne")
	office.player.position = sanne.position + sanne.basis.x * 1.2
	office.reactions.react()
	assert_true(sanne.saying(), "she says hello over her head")
	var hello := sanne.subtitle.text
	assert_true("Noor" in hello or hello in session.catalog.reactions.greetings["sanne"]["day"], "by name, in her voice")
	assert_false("{" in hello, "no token left")
	sanne.say("")
	office.reactions.react()
	assert_false(sanne.saying(), "not twice on one day")
	assert_eq(session.greet("sanne"), "", "the session says she greeted you today")
	session.pass_time(SimCalendar.MINUTES_PER_DAY)
	assert_ne(session.greet("sanne"), "", "tomorrow she greets you again")
	office.free()


func test_the_quick_exchange_needs_no_mission_and_opens_no_panel() -> void:
	var office := _office()
	assert_true(office.session.active_missions().is_empty(), "no mission taken on")
	var sanne := office.people.person("sanne")
	office.player.position = sanne.position + sanne.basis.x * 0.7
	office.use(sanne)
	assert_false(office.ui.is_busy(), "no panel opens")
	assert_true(sanne.saying(), "one line over her head instead")
	assert_ne(sanne.subtitle.text, "")
	assert_eq(office.ui.hud.toast_texts(), [] as Array[String], "no toast")
	office.free()


func test_someone_outside_the_talking_cast_gives_a_quick_line_too() -> void:
	var office := _office()
	var line := office.session.quick_line("kim")
	assert_ne(line, "", "the shared lines cover anyone")
	office.free()


func test_a_quick_line_reads_morale_load_and_the_hour() -> void:
	var office := _office()
	var session := office.session
	session.people.morale["sanne"] = 20
	assert_eq(session.quick_mood("sanne"), "tired")
	session.people.morale["sanne"] = 80
	assert_true(session.quick_mood("sanne") in Reactions.MOODS)
	assert_true(session.quick_line("sanne") in _all_quick(session, "sanne", session.quick_mood("sanne")))
	office.free()


static func _all_quick(session: GameSession, id: String, mood: String) -> Array:
	var own: Array = session.catalog.reactions.quick.get(id, {}).get(mood, [])
	return own if not own.is_empty() else session.catalog.reactions.quick["_all"][mood]


func test_chatter_only_with_two_at_the_corner() -> void:
	var office := _office()
	var corners := office.reactions.corner_points()
	assert_false(corners.is_empty(), "the 1e has a coffee corner")
	var corner := corners[0]
	var sanne := office.people.person("sanne")
	var anouk := office.people.person("anouk")
	office.player.position = corner + Vector3(3.5, 0, 0)   # near enough to hear, too far to be greeted
	sanne.position = corner + Vector3(-0.4, 0, 0.3)
	office.reactions.react()
	assert_false(sanne.saying(), "one person alone at the corner says nothing")
	anouk.position = corner + Vector3(0.4, 0, -0.3)
	office.reactions.react()
	assert_true(sanne.saying() != anouk.saying(), "one of the two starts")
	var first := sanne if sanne.saying() else anouk
	var second := anouk if first == sanne else sanne
	office.reactions._process(OfficePerson.say_time(first.subtitle.text) + 0.1)
	assert_true(second.saying(), "the other answers")
	assert_eq(office.session.chatter("sanne", "anouk"), [] as Array[String], "once a day per pair")
	office.free()


## A chatter with `days` (content/dialogs.yaml) is said only on those days: plans for the
## weekend on Thursday or Friday, never on a Monday.
func test_weekend_plans_are_not_chatted_about_on_a_monday() -> void:
	var r := Reactions.new({"chatter": [
		{"id": "weekend", "days": ["thu", "fri"], "lines": ["Nog plannen voor het weekend?", "Slapen."]},
		{"id": "monday", "lines": ["Goed weekend gehad?", "Te kort."]}]})
	for n in 4:
		assert_eq(r.chatter_for([], "", n, 0)[0], "Goed weekend gehad?", "Monday, variant %d" % n)
	var friday := range(4).map(func(n: int) -> String: return r.chatter_for([], "", n, 4)[0])
	assert_true("Nog plannen voor het weekend?" in friday, "on Friday it can come up")
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var weekend: Dictionary = s.catalog.reactions.chatter.filter(func(c: Dictionary) -> bool: return c["id"] == "weekend")[0]
	assert_false("mon" in weekend.get("days", ["mon"]), "the real weekend chatter waits for the end of the week")


## The corners are found once when the floor loads, not every look round.
func test_the_coffee_corners_are_found_once_per_floor() -> void:
	var office := _office()
	var corners := office.reactions.corner_points()
	var table := office.find_marker("coffee_table")
	table.get_parent().remove_child(table)
	assert_eq(office.reactions.corner_points(), corners, "the floor is not searched again")
	table.free()
	office.free()


func test_no_chatter_when_the_player_is_far_from_the_corner() -> void:
	var office := _office()
	var corner := office.reactions.corner_points()[0]
	var sanne := office.people.person("sanne")
	var anouk := office.people.person("anouk")
	sanne.position = corner + Vector3(-0.4, 0, 0)
	anouk.position = corner + Vector3(0.4, 0, 0)
	office.player.position = corner + Vector3(OfficeReactions.CHATTER_REACH + 3.0, 0, 0)
	office.reactions.react()
	assert_false(sanne.saying() or anouk.saying())
	office.free()


func test_yesterdays_ruined_talk_changes_todays_greeting() -> void:
	var office := _office()
	var session := office.session
	assert_eq(session.greeting_fact("sanne"), "", "an ordinary day")
	var now := session.region.net.time
	session.people.talk_log["sanne"] = [{"dialog": "sanne_tuesday", "at": now - SimCalendar.MINUTES_PER_DAY,
		"outcome": "ruined", "trace": [], "moves": []}]
	session.people.memory["sanne"] = {"flags": ["ruined"], "cooldown_until": 0}
	assert_eq(session.greeting_fact("sanne"), "ruined")
	var line := session.greet("sanne")
	var ruined: Array = session.catalog.reactions.greetings["sanne"]["ruined"]
	assert_true(line in ruined.map(session.fill_tokens), "her own line after a ruined talk: " + line)
	assert_false(line in (session.catalog.reactions.greetings["sanne"]["day"] as Array).map(session.fill_tokens))
	office.free()


func test_a_kept_agreement_and_a_standardised_fix_come_up_too() -> void:
	var office := _office()
	var session := office.session
	var now := session.region.net.time
	session.people.talk_log["anouk"] = [{"dialog": "anouk_seven", "at": now - SimCalendar.MINUTES_PER_DAY,
		"outcome": "commitment", "trace": [], "moves": []}]
	session.people.memory["anouk"] = {"flags": ["committed"], "cooldown_until": 0}
	assert_eq(session.greeting_fact("anouk"), "committed")
	session.people.talk_log["anouk"][0]["at"] = now - SimCalendar.days(GameSession.GREETING_MEMORY_DAYS + 1)
	assert_eq(session.greeting_fact("anouk"), "", "a talk long ago is not news")
	office.free()


func test_the_talk_band_shows_in_the_posture() -> void:
	var standing := _person("sanne", "idle")
	for band in BandCase.STANDING:
		standing.pose_for_band(band)
		assert_eq(standing.playing(), BandCase.STANDING[band], "standing, band %d" % band)
	var seated := _person("sanne", "sit")
	for band in BandCase.SEATED:
		seated.pose_for_band(band)
		assert_eq(seated.playing(), BandCase.SEATED[band], "seated, band %d" % band)
	standing.free()
	seated.free()


class BandCase:
	const STANDING := {0: "arms_folded", 1: "arms_folded", 2: "talk", 3: "nod", 4: "lean"}
	const SEATED := {0: "sit", 2: "sit_talk", 4: "sit_talk"}


func test_closed_turns_only_half_way() -> void:
	var p := _person("kim", "idle")
	var player := Vector3(2.0, 0, 0)
	p.face_toward(player)
	p.pose_for_band(0)
	_turn(p)
	assert_near(angle_difference(0.0, p.rotation.y), _yaw_to(p.position, player) * OfficePerson.HALF_TURN, 0.02)
	p.pose_for_band(2)
	_turn(p)
	assert_near(p.rotation.y, _yaw_to(p.position, player), 0.02, "listening: facing the player")
	p.free()


func test_a_hesitation_is_a_look_away() -> void:
	var p := _person("sanne", "idle")
	p.pose_for_band(2)
	p.hesitate()
	assert_eq(p.playing(), "look_away")
	p.free()


func test_low_energy_shows_in_a_tired_idle() -> void:
	var p := _person("sanne", "idle")
	p.show_energy({"energy": 0.2, "needs_talk": false})
	assert_eq(p.playing(), "tired")
	p.show_energy({"energy": 0.8, "needs_talk": false})
	assert_eq(p.playing(), "idle")
	p.free()


func test_a_talk_turns_a_seated_person_to_the_player_at_once() -> void:
	var office := _office()
	office.session.missions.done_once["fix_unused_capacity"] = true
	office.session.accept("fix_silo_kpis")   # Joost's talk is about its KPI
	office.session.region.found["silo_kpis:4"] = true
	office.people.refresh(office.session)
	var joost := office.people.person("joost")
	var rest := joost.rotation.y
	office.player.position = joost.position + joost.basis.x * 0.9 + joost.basis.z * 0.6   # beside and behind
	office.use(joost)
	assert_true(office.ui.is_busy(), "the talk opens")
	var turned := absf(angle_difference(rest, joost.rotation.y))
	assert_true(turned > OfficePerson.SWIVEL, "his chair turns out from the desk, no frames needed: %.2f" % turned)
	assert_true(turned <= OfficePerson.TALK_SWIVEL + 0.01, "but not through the desk")
	office.free()
