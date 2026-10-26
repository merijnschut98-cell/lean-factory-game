extends TestCase
## The designer's talk replay (Phase 3 slice 3.0): any talk of the bank, started at once on a
## session of its own, with a preset of what the person remembers. The session is thrown away
## when the talk closes. The tests build the screen outside the tree, like the other UI tests.

const JOOST := "joost_output_kpi"


func _cleanup() -> void:
	Designer.force(null)


func _kinds() -> Array[String]:
	return Array(Dialog.KINDS, TYPE_STRING, "", null)


func test_presets_fill_the_dialog_id() -> void:
	var s := TalkReplay.session_for(JOOST, "none")
	assert_false(s.missions.knows("promise_kept:" + JOOST))
	assert_false(s.people.memory.has("joost"), "nothing is remembered")
	s = TalkReplay.session_for(JOOST, "kept_promise")
	assert_true(s.missions.knows("promise_kept:" + JOOST), "the promise was kept")
	assert_false(s.missions.knows("promise_kept:other"))


func test_ruined_yesterday_is_a_ruined_talk_as_play_records_it() -> void:
	var s := TalkReplay.session_for(JOOST, "ruined_yesterday")
	var people := s.people
	assert_true("ruined" in people.memory["joost"]["flags"], "they remember it")
	assert_eq(SessionTalks.greeting_fact(s, "joost"), "ruined", "this morning's hello says so")
	assert_eq(people.talks[JOOST], 1, "the talk was had")
	assert_eq(people.talk_log["joost"][-1]["outcome"], "ruined")
	var ago := SimCalendar.day_of(s.region.net.time) - SimCalendar.day_of(int(people.talk_log["joost"][-1]["at"]))
	assert_between(ago, 1, 3, "a day back (more over a weekend)")
	assert_false(people.cooling_down("joost", s.region.net.time), "the retry is possible again")
	var opened := s.start_dialog("joost")
	assert_eq(opened["opening"], s.fill_tokens(people.dialogs[JOOST].retry_opening), "the retry opening, as in play")


func test_session_for_opens_the_dialog() -> void:
	var opened := TalkReplay.session_for(JOOST, "none").start_dialog("joost")
	assert_false(opened.has("error"), "not a refusal: %s" % opened.get("error", ""))
	assert_eq(opened["dialog"], JOOST)
	assert_false(str(opened["opening"]).is_empty(), "the first line")


func test_a_persuasion_keeps_the_trust_the_person_has() -> void:
	var s := TalkReplay.session_for(JOOST, "none")
	var own: int = s.people.persons["joost"].trust
	assert_true(own < 100, "the check means something")
	assert_eq(s.start_dialog("joost")["meter"]["trust"], own, "the meter's trust is theirs, not the maximum")


func test_an_expert_talk_opens_its_trust_gated_topics() -> void:
	var s := TalkReplay.session_for("henk_expert", "none")
	assert_eq(s.people.trust["henk"], 100, "an expert's topics wait for trust")


func test_every_content_dialog_is_listed_and_opens() -> void:
	var catalog := Catalog.load_from()
	var wanted := catalog.dialogs.filter(func(d: DialogDef) -> bool: return d.kind in _kinds())
	var rows := TalkReplay.rows(catalog)
	assert_eq(rows.size(), wanted.size(), "one row per dialog")
	assert_eq(rows.map(func(r: Dictionary) -> String: return r["id"]), wanted.map(func(d: DialogDef) -> String: return d.id))
	for row: Dictionary in rows:
		assert_false(str(row["name"]).is_empty(), "%s: the person's name" % row["id"])
		var opened := TalkReplay.session_for(row["id"], "none").start_dialog(row["person"])
		assert_eq(opened.get("dialog"), row["id"], "%s opens: %s" % [row["id"], opened.get("error", "")])


func test_the_presets_a_kind_offers() -> void:
	assert_eq(TalkReplay.presets_for("persuade"), ["none", "ruined_yesterday", "kept_promise"])
	for kind in ["expert", "checkin"]:
		assert_eq(TalkReplay.presets_for(kind), ["none"], "a %s has no ruin or promise to remember" % kind)


func test_an_unknown_dialog_is_an_error_on_the_session() -> void:
	assert_false(TalkReplay.session_for("nope", "none").error.is_empty())


func _screen() -> TalkReplay:
	var screen := TalkReplay.new()
	screen.build()
	return screen


func _press(root: Node, text: String) -> void:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			(b as Button).pressed.emit()
			return
	assert_true(false, "no button \"%s\"" % text)


func test_play_opens_the_real_talk_view_and_esc_throws_the_session_away() -> void:
	var screen := _screen()
	screen.start(JOOST, "none")
	assert_true(screen.view != null)
	assert_true(screen.view.visible and screen.view.talking(), "the talk runs")
	assert_eq(screen.view.talk["dialog"], JOOST)
	assert_false(screen.list.visible, "the list gives way to the talk")
	screen.press(KEY_ESCAPE)
	assert_true(screen.view == null, "Esc closes the talk")
	assert_true(screen.list.visible, "back at the list")
	var backs := [0]
	screen.back_requested.connect(func() -> void: backs[0] += 1)
	screen.press(KEY_ESCAPE)
	assert_eq(backs[0], 1, "Esc on the list goes back")
	screen.free()


func test_the_speel_button_uses_the_preset_picked_in_its_row() -> void:
	var screen := _screen()
	var picker: OptionButton = screen.pickers[JOOST]
	picker.select(TalkReplay.presets_for("persuade").find("ruined_yesterday"))
	screen.play(JOOST)
	assert_eq(screen.view.talk["opening"], screen.view.session.fill_tokens(
		screen.view.session.people.dialogs[JOOST].retry_opening), "Joost remembers yesterday")
	screen.free()


func test_a_listed_row_names_dialog_person_and_kind() -> void:
	var screen := _screen()
	assert_true(shows(screen, JOOST), "the dialog id")
	assert_true(shows(screen, "Joost van Dijk"), "the person")
	screen.free()


func test_the_title_menu_opens_the_replay_from_the_designer_page_and_closes_it() -> void:
	Designer.force(true)
	var menu := TitleMenu.new()
	menu.saves = SaveSlots.new(TestCase.scratch("replay_menu"))
	menu.build()
	menu.open_designer()
	_press(menu.designer, DesignerPage.REPLAY)
	assert_true(menu.replay != null, "the replay is open over the menu")
	menu.replay.back_requested.emit()
	assert_true(menu.replay == null, "closed again")
	assert_eq(menu.page, TitleMenu.Page.DESIGNER, "on the designer page")
	menu.free()
	_cleanup()
