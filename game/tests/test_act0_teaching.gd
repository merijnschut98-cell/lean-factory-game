extends TestCase
## The Act 0 teaching UI (PLAN 1.11a; tutorial talks spec §2, §3): Ruud's
## morning note with the day's move cards, kept in the codex under
## Gesprekken; Ruud naming one move that landed after each tutorial talk, in
## Act 0 only and never as a score; his week-end question after Friday's last
## talk; the Friday card "Wie zit er tegenover je?".

const SCENE := "res://src/world/office/office.tscn"
const DIGITS := "0123456789"


func _training_office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.build()
	return office


func _cards_of(s: GameSession, day: String) -> Array:
	return s.catalog.move_cards.filter(func(c: Dictionary) -> bool: return c["day"] == day)


func test_the_content_holds_a_card_for_every_listening_move_and_the_friday_card() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	var moves: Array = s.catalog.move_cards.map(func(c: Dictionary) -> Variant: return c["move"])
	for move: String in Dialog.LISTEN:
		assert_true(move in moves, move)
	assert_true(null in moves, "the Friday card names a skill, not a move")


## Monday morning: Ruud's note with Monday's card(s), not Tuesday's, in the journal (J),
## announced by one quiet toast; nothing of it on screen (PLAN 2.13 C).
func test_the_morning_brings_ruuds_note_with_the_days_moves_into_the_journal() -> void:
	var office := _training_office()
	var s := office.session
	var ui := office.ui
	var toasts := func() -> Array: return ui.hud.toast_texts().filter(func(t: String) -> bool: return t == ui.tr(GameUI.NOTE_TOAST))
	assert_eq(toasts.call().size(), 1, "one quiet toast")
	assert_false(ui.hud.card_texts().any(func(t: String) -> bool: return t.begins_with(ClueJournal.NOTE_HEADING.left(8))),
		"no note over the world")
	var notes := ClueJournal.notes(s, ui.session_layer)
	assert_eq(notes.size(), 1, "one note from Ruud")
	var note := "\n".join(notes[0]["lines"])
	for card: Dictionary in _cards_of(s, "training_mon"):
		assert_true(note.contains(card["title"]) and note.contains(card["why"]), card["title"])
	for card: Dictionary in _cards_of(s, "training_tue"):
		assert_false(note.contains(card["title"]), "not Tuesday's: " + card["title"])
	assert_true(note.contains(s.tool_card("conversation")["title"]), "the day's new tool (PLAN 2.12)")
	assert_false(note.contains(s.tool_card("shadow")["title"]), "not Tuesday's tools")
	ui.after_action()
	assert_eq(toasts.call().size(), 1, "once a day")
	ui.toggle_journal()
	assert_eq(ui.journal.tab, ClueJournal.NOTES, "J opens on the new note")
	assert_true(shows(ui.journal, notes[0]["lines"][0]), "the note in the journal")
	office.free()


## The codex keeps the cards of the days reached; the rest are silhouettes.
func test_the_codex_keeps_the_cards_of_the_days_reached() -> void:
	var office := _training_office()
	var s := office.session
	office.ui.toggle_codex()
	office.ui.codex.show_tab(CodexPanel.TALKS)
	for card: Dictionary in _cards_of(s, "training_mon"):
		assert_true(shows(office.ui.codex, card["title"]))
		assert_true(shows(office.ui.codex, card["text"]))
	for card: Dictionary in _cards_of(s, "training_fri"):
		assert_false(shows(office.ui.codex, card["title"]), "Friday not reached")
	assert_true(shows(office.ui.codex, CodexPanel.SILHOUETTE))
	office.free()


## After a tutorial talk Ruud names one move that landed, by its chip name,
## in words only (no number, no score).
func test_ruud_names_a_move_after_a_tutorial_talk() -> void:
	var office := _training_office()
	var panel := office.ui.talk_view
	assert_eq(office.ui.open_talk("anouk"), "")
	assert_true(panel.talk.get("dialog", "") == "anouk_seven", "Monday's talk")
	panel.choose("mood")
	var r := panel.close_talk()
	var line: String = r["summary"]["ruud_names"]
	assert_false(line.is_empty(), "he names or asks")
	assert_true(shows(panel, line), "on the summary card")
	assert_true(shows(panel, TalkView.RUUD_DROPPED_BY), "Monday: Ruud came by")
	for text in texts_in(panel):
		if text == line:
			for ch in text:
				assert_false(ch in DIGITS, "never a score: " + text)
	office.free()


## Outside Act 0 Ruud never names a move.
func test_ruud_never_names_after_act_0() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	var panel := TalkView.new()
	panel.session = s
	assert_eq(panel.start("joost"), "")
	panel.choose("mood")
	panel.close_talk()
	assert_false(shows(panel, TalkView.RUUD_DROPPED_BY))
	assert_false(shows(panel, TalkView.RUUD_MESSAGE))
	panel.free()


## Friday's last tutorial talk ends the naming: Ruud's week-end question.
func test_the_week_ends_after_fridays_last_talk() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	var friday: Array = s.people.dialogs.values().filter(func(d: DialogDef) -> bool:
		return d.tutorial and d.mission == "training_fri")
	assert_true(friday.size() >= 2, "Friday has talks")
	var last: DialogDef = friday[-1]
	assert_false(TalkView.week_ends(s, last), "not before the others were had")
	for d: DialogDef in friday:
		s.people.outcomes[d.id] = "commitment"
	assert_true(TalkView.week_ends(s, last), "after Friday's last talk")
	var thursday: DialogDef = s.people.dialogs.values().filter(func(d: DialogDef) -> bool:
		return d.tutorial and d.mission == "training_thu")[0]
	assert_false(TalkView.week_ends(s, thursday), "Thursday is not the week's end")
