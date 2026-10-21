extends TestCase
## Going home (PLAN 2.14 S1-A follow-up): after five the front door offers "Naar huis",
## which ends the day on the next working morning with the dagstart; a needed colleague
## who has gone home says so at their empty desk, and is there again the next morning;
## late in the evening one line suggests going home, never forcing it.

const SCENE := "res://src/world/office/office.tscn"
const INTAKE := "place:connections.intake"
const DESIGN := "place:connections.design"
const TRAY := "training_tray"


func _office(training := false) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = training
	office.build()
	return office


## The game's clock moved on to `minute` today (a later minute) as the world sees it.
func _clock_to(office: Office, minute: int) -> void:
	office.session.pass_time(minute - office.session.minute_of_day())
	office.ui.after_action()
	office.people.refresh(office.session)
	office.home.poll()


func _entrance(office: Office) -> Vector3:
	return office.in_office(office.floors.markers()["arrive:entrance"]).origin


func _weekday(office: Office) -> int:
	return SimCalendar.weekday(office.session.region.net.time - SimCalendar.days(GameSession.WARMUP_DAYS))


func _go_home(office: Office) -> void:
	office.player.position = _entrance(office) if office.floors.floor_id == "ground" else office.player.position
	if office.floors.floor_id != "ground":
		office.floors.go_to("ground", "lift", true)
		office.home.poll()
		office.player.position = _entrance(office)
	office.use(office.target_near(office.player.position))


func test_naar_huis_is_at_the_front_door_after_five_only() -> void:
	var office := _office()
	office.floors.go_to("ground", "lift", true)
	office.home.poll()
	office.player.position = _entrance(office)
	assert_ne(office.prompt_near(office.player.position), OfficeHome.PROMPT, "half past eight: no going home")
	_clock_to(office, 16 * 60 + 50)
	assert_ne(office.prompt_near(office.player.position), OfficeHome.PROMPT, "not before five")
	_clock_to(office, 17 * 60 + 5)
	assert_eq(office.prompt_near(office.player.position), OfficeHome.PROMPT, "after five, at the front door")
	office.player.position = _entrance(office) + Vector3(6, 0, -6)
	assert_ne(office.prompt_near(office.player.position), OfficeHome.PROMPT, "only at the door")
	office.free()


func test_going_home_ends_the_day_on_the_next_working_morning_with_the_dagstart() -> void:
	var office := _office()
	var s := office.session
	var monday := SimCalendar.day_of(s.region.net.time)
	assert_eq(_weekday(office), 0, "the game starts on a Monday")
	_clock_to(office, 18 * 60)
	_go_home(office)
	assert_eq(SimCalendar.day_of(s.region.net.time), monday + 1, "Tuesday")
	assert_eq(s.minute_of_day(), GameSession.START_MINUTE, "half past eight")
	assert_false(office.ui.session_layer.update(s), "the dagstart has run")
	assert_true(office.ui.hud.clock_label.text.begins_with("di "), office.ui.hud.clock_label.text)
	assert_eq(office.floors.floor_id, "ground", "in through the front door")
	assert_true(office.player.position.distance_to(_entrance(office)) < 0.5)
	assert_true(office.home.fading(), "a short fade with the date")
	assert_true(office.home.fade_text().begins_with("di "), office.home.fade_text())
	for i in 3:   # to Friday evening
		_clock_to(office, 17 * 60 + 30)
		_go_home(office)
	assert_eq(_weekday(office), 4, "Friday")
	_clock_to(office, 17 * 60 + 30)
	_go_home(office)
	assert_eq(_weekday(office), 0, "the weekend skipped: Monday")
	assert_eq(s.minute_of_day(), GameSession.START_MINUTE)
	office.free()


func test_staying_late_is_never_forced_and_one_line_suggests_home() -> void:
	var office := _office()
	_clock_to(office, 18 * 60 + 50)
	assert_false(office.ui.hud.toast_texts().has(OfficeHome.LATE_NOTE), "not yet")
	_clock_to(office, 19 * 60 + 20)
	assert_true(office.ui.hud.toast_texts().has(OfficeHome.LATE_NOTE), "past seven: a suggestion")
	assert_eq(office.ui.hud.toast_texts().count(OfficeHome.LATE_NOTE), 1)
	_clock_to(office, 21 * 60)
	assert_eq(office.ui.hud.toast_texts().count(OfficeHome.LATE_NOTE), 1, "once an evening")
	assert_eq(office.session.minute_of_day(), 21 * 60, "and the evening goes on")
	office.free()


## The suggestion waits while a panel or a scene holds the world (a talk, the phone).
func test_the_late_line_waits_until_the_world_is_free() -> void:
	var office := _office()
	office.hold_for_scene(true)
	_clock_to(office, 19 * 60 + 20)
	assert_false(office.ui.hud.toast_texts().has(OfficeHome.LATE_NOTE), "not over a scene")
	office.hold_for_scene(false)
	office.home.poll()
	assert_true(office.ui.hud.toast_texts().has(OfficeHome.LATE_NOTE), "once it is over")
	office.free()


func test_a_needed_colleague_who_went_home_says_so_and_is_back_in_the_morning() -> void:
	var office := _office(true)
	var ui := office.ui
	office.interact(office.interactable(INTAKE))
	ui.place_menu.ask("walk")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.ask("walk")
	ui.close_panels()
	assert_eq(Objective.of(office.session).get("person", ""), "anouk", "Monday ends with Anouk's talk")
	_clock_to(office, 19 * 60 + 10)   # she stays late in the training week (Werkvoorbereiding runs hot)
	var anouk := office.people.person("anouk")
	assert_false(anouk.visible, "Anouk has gone home")
	var desk: Vector3 = anouk.desk["at"]
	office.player.position = desk + Vector3(0, 0, 1.0)
	assert_eq(office.prompt_near(office.player.position), OfficeHome.DESK_PROMPT % "Anouk")
	office.use(office.target_near(office.player.position))
	assert_true(ui.hud.toast_texts().has(OfficeHome.GONE_HOME % "Anouk"), str(ui.hud.toast_texts()))
	var marked := office.minimap.targets().filter(func(t: Dictionary) -> bool: return str(t["id"]).ends_with(":anouk"))
	assert_eq(marked.size(), 1, "the minimap still points at her desk")
	if not marked.is_empty():
		assert_true((marked[0]["at"] as Vector2).distance_to(Vector2(desk.x, desk.z)) < 0.5)
	_go_home(office)
	office.floors.go_to("first", "lift", true)
	office.people.refresh(office.session)
	assert_true(office.people.person("anouk").visible, "in the morning she is in")
	ui.open_talk("anouk")
	assert_eq(ui.talk_view.talk.get("dialog", ""), "anouk_seven", "Monday's talk is still there")
	office.free()


## The whole training week, going home every evening.
func test_the_training_week_completes_when_you_go_home_every_evening() -> void:
	var office := _office(true)
	var ui := office.ui
	var s := office.session
	office.interact(office.interactable(INTAKE))
	ui.place_menu.ask("walk")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.ask("walk")
	ui.close_panels()
	_clock_to(office, 17 * 60 + 30)
	_go_home(office)
	office.floors.go_to("first", "lift", true)
	ui.open_talk("anouk")
	ui.talk_view.choose("close")
	ui.talk_view.close_talk()
	ui.close_panels()
	assert_eq(Objective.of(s)["mission"], "training_tue")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("shadow")
	ui.place_menu.use_tool("documents")
	ui.close_panels()
	assert_eq(Objective.of(s)["mission"], "training_wed")
	_clock_to(office, 17 * 60 + 30)
	_go_home(office)
	office.floors.go_to("first", "lift", true)
	office.interact(office.interactable(INTAKE))
	ui.place_menu.use_tool("queue_count")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("queue_count")
	ui.close_panels()
	_clock_to(office, 17 * 60 + 30)
	_go_home(office)
	office.floors.go_to("first", "lift", true)
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("shadow")
	ui.place_menu.use_tool("time_study")
	ui.place_menu.ask("walk")
	office.interact(office.interactable("obeya"))
	var problem: ProblemDef = s.region.problems[TRAY]
	assert_eq(ui.a3_form.submit({"waste": problem.waste, "cause": s.cause_options(TRAY).find(problem.root_cause),
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": "one_tray_fifo",
		"prediction": problem.kpi}), "")
	ui.a3_form.wait()
	assert_true(ui.a3_form.check().get("passed", false))
	ui.check_panel.act(false)
	assert_false(s.in_training(), "the week is done")
	office.free()


## The sound of going home (S1-B): the office fades out behind the front door, and the
## next morning's office comes back.
func test_going_home_hushes_the_office_sound_until_the_morning() -> void:
	var office := _office()
	_clock_to(office, 18 * 60)
	_go_home(office)
	assert_true(office.sound.hushed, "the office fades out behind you")
	office.sound.morning(office.session.minute_of_day(), office.sound.occupancy())
	assert_false(office.sound.hushed, "the morning office")
	office.free()
