extends TestCase
## The session layer on screen: the terugblik card (one button, reopened from
## the journal), the stop note at a dagstart, the Intussen panel with its
## named skip, one discovery toast a day, the side offers with "Nog open",
## and the playtest log switch.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
var settings_path := scratch("test_session_ui_settings.cfg")


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	office.ui.playtest_log = SessionLog.new(SessionLog.PATH, false)  # tests write no log
	office.ui.settings_path = settings_path
	return office


func _visible_buttons(root: Node) -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem and not n.visible:
			continue
		if n is Button:
			out.append(n.text)
		stack.append_array(n.get_children())
	return out


func _complete(s: GameSession, id: String) -> void:
	s.missions.done_once[id] = true
	s.missions.progress[id] = {"status": "completed", "asks": {}, "seen": {}}


func test_the_terugblik_card_has_ruuds_line_up_to_three_lines_and_one_button() -> void:
	var office := _office()
	var ui := office.ui
	ui.session_layer.begin(office.session)
	_complete(office.session, "walk_outages")
	ui.open_terugblik(ui.session_layer.open_session(office.session))
	var card := ui.terugblik
	assert_true(card.visible)
	assert_true(shows(card, office.session.missions.defs["walk_outages"].name), "Ruud names what was done")
	assert_eq(_visible_buttons(card), [TerugblikCard.BUTTON], "one button: %s" % [_visible_buttons(card)])
	for text in texts_in(card):
		assert_false(text.contains(" uur"), "a day, never an hour countdown: " + text)
	card.close_requested.emit()
	assert_false(card.visible)
	office.free()


## Komt eraan is a day name: today, tomorrow, a weekday, or a date.
func test_a_date_reads_as_a_day_name() -> void:
	var office := _office()
	var s := office.session
	var now := s.region.net.time
	assert_eq(TerugblikCard.day_name(s, now + 60), "vandaag")
	assert_eq(TerugblikCard.day_name(s, now + SimCalendar.days(1)), "morgen")
	assert_true(TerugblikCard.day_name(s, now + SimCalendar.days(3)) in TerugblikCard.WEEKDAYS)
	assert_true(TerugblikCard.day_name(s, now + SimCalendar.days(12)).contains(" "), "further ahead: a date")
	office.free()


func test_the_journal_reopens_the_terugblik_and_switches_the_log() -> void:
	var office := _office()
	var ui := office.ui
	ui.toggle_journal()
	assert_false(shows(ui.journal, ClueJournal.TERUGBLIK), "no card in a new game")
	ui.session_layer.begin(office.session)
	ui.session_layer.open_session(office.session)
	ui.journal.refresh()
	assert_true(shows(ui.journal, ClueJournal.TERUGBLIK))
	ui.journal.reopen.emit("terugblik")
	assert_true(ui.terugblik.visible)
	assert_false(ui.journal.visible)
	ui.set_log_enabled(false)
	assert_false(SessionLog.enabled_in(settings_path))
	assert_false(ui.playtest_log.enabled)
	ui.set_log_enabled(true)
	assert_true(SessionLog.enabled_in(settings_path))
	DirAccess.remove_absolute(settings_path)
	office.free()


func test_the_stop_note_shows_at_a_dagstart_after_half_an_hour() -> void:
	var office := _office()
	var ui := office.ui
	office.session.region.advance_days(1)
	ui.after_action()
	assert_false(ui.hud.stop_note.visible, "not in the first half hour")
	ui.started_ms -= 31 * 60 * 1000
	office.session.region.advance_days(1)
	ui.after_action()
	assert_true(ui.hud.stop_note.visible, "a quiet note at the dagstart")
	assert_eq(ui.hud.stop_note.text, Hud.STOP_NOTE)
	office.free()


func test_one_discovery_toast_a_day_the_rest_wait() -> void:
	var office := _office()
	var ui := office.ui
	var ids: Array = office.session.discoveries.defs.keys()
	for id: String in ids.slice(0, 2):
		office.session.discoveries.events.append({"type": "discovery", "id": id})
	ui.after_action()
	var toasts := ui.hud.toast_texts().filter(func(t: String) -> bool: return t.begins_with("Ontdekking"))
	assert_eq(toasts.size(), 1)
	assert_eq(ui.session_layer.queued, [ids[1]])
	office.free()


func test_the_intussen_panel_opens_with_the_experiment_and_skips_to_the_check() -> void:
	var office := _office()
	var ui := office.ui
	var s := office.session
	ui.mission_board.accept(MISSION)
	s.use_tool("connections.design", "time_study")
	s.use_tool("connections.design", "documents")
	s.ask("connections.intake", "walk")
	s.use_tool("connections.design", "data")
	var problem: ProblemDef = s.region.problems[PROBLEM]
	ui.open_a3()
	ui.a3_form.submit({"waste": "overprocessing", "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id), "cm": "standard_designs",
		"prediction": "throughput"})
	assert_true(ui.intussen.visible, "while the Check runs: what happens meanwhile")
	var days: int = ui.session_layer.intussen(s, PROBLEM)["days"]
	assert_true(shows(ui.intussen, IntussenPanel.SKIP % days), "the skip names its days")
	ui.intussen.skip()
	assert_eq(s.phase_of(PROBLEM), "check_ready")
	assert_true(shows(ui.intussen, IntussenPanel.READY))
	office.free()


func test_the_board_shows_two_new_sides_a_week_and_older_ones_under_nog_open() -> void:
	var office := _office()
	var ui := office.ui
	var s := office.session
	for id in ["walk_outages", "walk_meters"]:
		_complete(s, id)
	ui.after_action()
	var sides := s.available_missions().filter(func(m: MissionDef) -> bool: return m.kind == "side")
	ui.open_mission_board()
	var shown := sides.filter(func(m: MissionDef) -> bool: return shows(ui.mission_board, m.name))
	assert_eq(shown, [], "this week's two offers were the walks: the next ones wait")
	s.region.advance_days(7)
	ui.after_action()
	ui.open_mission_board()
	shown = sides.filter(func(m: MissionDef) -> bool: return shows(ui.mission_board, m.name))
	assert_eq(shown.size(), SessionLayer.NEW_SIDES_PER_WEEK, "two of %d" % sides.size())
	assert_false(shows(ui.mission_board, MissionBoard.OLDER), "nothing older yet")
	s.region.advance_days(7)
	ui.after_action()
	ui.open_mission_board()
	assert_true(shows(ui.mission_board, MissionBoard.OLDER), "last week's offers fold away, not lost")
	for m: MissionDef in shown:
		assert_false(shows(ui.mission_board, m.name), m.name + " is folded away")
	ui.mission_board.toggle_older()
	for m: MissionDef in shown:
		assert_true(shows(ui.mission_board, m.name), m.name + " is still open")
	office.free()
