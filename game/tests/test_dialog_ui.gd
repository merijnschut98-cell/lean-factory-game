extends TestCase
## The dialog UI (PLAN 1.2, dialog spec §11) on the real content: the meter
## fills and shows arrows, never a number; four sentences to say, never a
## move's name (PLAN 2.13 B); the layer tracker and the cue; the summary card; the
## Mensen tab; the way in from a team's place; the walk-around energy bar.

const SCENE := "res://src/world/office/office.tscn"
const DESIGN := "connections.design"
const LISTEN_TO_JOOST := ["mood", "paraphrase", "inquiry", "reflect", "silence"]
const DIGITS := "0123456789"


## Act II's main mission open with Joost's own words found (his talk opens).
func _silo() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	return s


func _panel(s: GameSession) -> DialogPanel:
	var panel := DialogPanel.new()
	panel.session = s
	assert_eq(panel.start("joost"), "")
	return panel


func _has_digit(text: String) -> bool:
	for ch in text:
		if ch in DIGITS:
			return true
	return false


func test_arrows_and_pips_are_never_numbers() -> void:
	assert_eq([DialogPanel.arrow_text(2), DialogPanel.arrow_text(1), DialogPanel.arrow_text(0),
		DialogPanel.arrow_text(-1), DialogPanel.arrow_text(-2), DialogPanel.arrow_text(-7)], ["▲▲", "▲", "", "▼", "▼▼", "▼▼"])
	assert_eq(DialogPanel.pips(2), "●●○○○")
	assert_eq(DialogPanel.pips(9), "●●●●●")


func test_the_panel_opens_with_the_person_the_meter_and_four_sentences() -> void:
	var s := _silo()
	var panel := _panel(s)
	assert_eq(panel.title_label.text, "Joost van Dijk  ·  " + panel.talk["role"])
	assert_true(shows(panel, "Ik heb tien minuten."), "the opening")
	assert_true(shows(panel, "Op z'n hoede"), "the band, named")
	assert_true(shows(panel, "Standpunt"), "the layer tracker")
	assert_eq(panel.offers, s.dialog_offers(), "the session's offer")
	assert_eq(panel.offers.size(), Dialog.OFFERED)
	var buttons := _chips_of(panel)
	for o: Dictionary in panel.offers:
		assert_true(buttons.has(o["line"]), "a button says: " + o["line"])
	panel.free()


## Merijn's playtest (2026-10-19): the choice is about what you say. No move's
## label, no row name, no hover text: only sentences, the whole talk long.
func test_no_move_label_is_ever_on_screen_mid_talk() -> void:
	var s := _silo()
	var panel := _panel(s)
	var labels: Array = DialogPanel.labels_of(s).get("chips", {}).values() + ["Luisteren", "Sturen", "Kies:"]
	for turn in 6:
		for n: Node in _nodes(panel.body, func(x: Node) -> bool: return x is Control):
			var texts: Array[String] = [(n as Control).tooltip_text]
			if n is Label or n is Button:
				texts.append(n.text)
			for text in texts:
				assert_false(text in labels, "a move's label on screen: " + text)
		for b: Button in _nodes(panel.body, func(x: Node) -> bool: return x is Button):
			assert_eq(b.tooltip_text, "", "no hover text that names the move")
			assert_false(b.has_theme_stylebox_override("normal"), "no styling that judges: " + b.text)
		panel.choose_option(turn % panel.offers.size())
		if not panel.talking():
			break
	panel.free()


func test_a_sentence_is_what_you_then_say() -> void:
	var s := _silo()
	var panel := _panel(s)
	var said: Dictionary = panel.offers[2]
	var r := panel.choose_option(2)
	assert_eq([r["move"], r["line"]], [said["move"], said["line"]])
	assert_true(shows(panel, DialogPanel.YOU % said["line"]), "what you said, above their reply")
	assert_eq(panel.choose_option(7), {}, "no fifth sentence")
	panel.free()


func test_the_bar_fills_and_the_meter_never_shows_a_number() -> void:
	var s := _silo()
	var panel := _panel(s)
	for move in LISTEN_TO_JOOST:
		var r := panel.choose(move)
		assert_eq(panel.bar.target, float(r["openness"]), "the bar fills to the openness")
		var header := panel.body.get_child(0)
		for text in texts_in(header):
			assert_false(_has_digit(text), "no number in the meter: " + text)
		assert_true(shows(header, DialogPanel.arrow_text(r["arrow"])) or r["arrow"] == 0, "the arrow")
	panel.free()


func test_the_tracker_lights_a_layer_once_heard_and_the_cue_shows() -> void:
	var s := _silo()
	var panel := _panel(s)
	var cue := false
	var interest := false
	for move in LISTEN_TO_JOOST:
		var r := panel.choose(move)
		cue = cue or (r["cue"] and shows(panel, "Er zit meer achter"))
		interest = interest or r["revealed"] == "interest"
	assert_true(interest, "the interest was heard on this path")
	assert_true(shows(panel, "● Belang"), "lit")
	assert_true(panel.heard.has("interest"))
	assert_true(cue or panel.heard.has("concern"), "the cue showed before the concern")
	panel.free()


func test_the_summary_card_shows_the_outcome_and_the_trace() -> void:
	var s := _silo()
	var panel := _panel(s)
	panel.choose("mood")
	panel.choose("paraphrase")
	var r := panel.close_talk()
	assert_true(r["ended"])
	assert_false(panel.talking())
	assert_true(shows(panel, DialogPanel.SUMMARY))
	assert_true(shows(panel, panel.outcome_label(r["outcome"])))
	assert_eq(panel.trace.size(), 4, "the start and three moves")
	assert_eq(panel.summary_trace.labels, ["Stemming peilen", "Samenvatten", "Afronden"], "each move under its point")
	assert_true(shows(panel, DialogPanel.TALK_IT_OVER % "Ruud Hoekstra"), "a main mission's talk")
	panel.free()


func test_the_session_reports_the_layers_of_the_talk() -> void:
	var s := _silo()
	assert_eq(s.dialog_layers(), [])
	s.start_dialog("joost")
	var layers := s.dialog_layers()
	assert_eq(layers.map(func(l: Dictionary) -> String: return l["id"]), ["position", "interest", "concern"])
	assert_eq(layers.map(func(l: Dictionary) -> bool: return l["heard"]), [true, false, false])
	assert_eq(layers[1]["text"], "", "a layer not yet heard says nothing")


## The chips found in the panel, by their text.
func _chips_of(panel: DialogPanel) -> Dictionary:
	var out := {}
	var stack: Array[Node] = [panel.body]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button:
			out[n.text] = n
		stack.append_array(n.get_children())
	return out


func test_the_face_follows_the_meter_band() -> void:
	assert_eq([MoodFace.mouth_for(-1), MoodFace.mouth_for(0), MoodFace.mouth_for(1), MoodFace.mouth_for(2),
		MoodFace.mouth_for(3), MoodFace.mouth_for(4)], ["closed", "closed", "frown", "flat", "soft_smile", "smile"])
	var s := _silo()
	var panel := _panel(s)
	for move in LISTEN_TO_JOOST:
		panel.choose(move)
		assert_eq(panel.face.band, panel.meter()["band"], "the face is the band's, whatever the mood word")
	panel.free()


func test_a_partial_agreement_says_what_still_has_to_happen() -> void:
	var panel := _panel(_silo())
	for move in ["mood", "paraphrase", "inquiry", "reflect", "silence", "empathy"]:
		panel.choose(move)
	panel.choose("propose", "lead_and_oldest")
	var r := panel.choose("ask_commitment")
	assert_eq(r["outcome"], "partial")
	assert_true(shows(panel, DialogPanel.STILL_NEEDED % "Frank moet het goedvinden."), "the condition, in a line")
	panel.free()


func test_a_ruined_talk_says_when_to_try_again_and_nothing_more() -> void:
	var panel := _panel(_silo())
	panel.choose("show_data", "silo_kpis:4")
	panel.choose("propose", "lead_and_oldest")
	var r := panel.choose("pressure")
	assert_eq(r["outcome"], "ruined")
	assert_true(shows(panel, DialogPanel.TRY_AGAIN % "Joost"))
	assert_false(shows(panel, DialogPanel.STILL_NEEDED.left(10)))
	panel.free()


## U13: when trust moves, a ▲ or ▼ flashes beside the pips, never a number,
## also when no pip turns over; the end of a talk counts (a partial's +5).
func test_a_trust_change_flashes_beside_the_pips() -> void:
	var panel := _panel(_silo())
	assert_eq(panel.trust_moved, 0, "nothing moved at the start")
	assert_false(panel.trust_flash.visible)
	panel.choose("mood")
	assert_eq(panel.trust_moved, 0, "listening leaves trust where it was")
	panel.choose("pressure")
	assert_eq(panel.trust_moved, -1, "pressure costs trust")
	assert_true(panel.trust_flash.visible)
	assert_eq(panel.trust_flash.text, "▼")
	panel.free()
	panel = _panel(_silo())
	for move in ["mood", "paraphrase", "inquiry", "reflect", "silence", "empathy"]:
		panel.choose(move)
	panel.choose("propose", "lead_and_oldest")
	assert_eq(panel.choose("ask_commitment")["outcome"], "partial")
	assert_eq(panel.trust_flash.text, "▲", "the partial's trust shows on the summary")
	panel.free()


## U14: every sentence carries its key, small and dimmed in its corner, 1–4;
## the key says it.
func test_each_sentence_carries_a_key_that_says_it() -> void:
	var s := _silo()
	var panel := _panel(s)
	var buttons := _chips_of(panel)
	for i in panel.offers.size():
		var b: Button = buttons[panel.offers[i]["line"]]
		var hint := b.get_child(0) as Label if b.get_child_count() > 0 else null
		assert_true(hint != null, "a hint in the corner of sentence %d" % (i + 1))
		assert_eq(hint.text, OS.get_keycode_string(DialogPanel.OPTION_KEYS[i]))
	var second: Dictionary = panel.offers[1]
	assert_true(panel.press_key(KEY_2), "2 says the second sentence")
	assert_eq(panel.last["line"], second["line"])
	assert_false(panel.press_key(KEY_5), "no fifth")
	assert_false(panel.press_key(KEY_Q), "a key without a sentence is left for others")
	panel.free()


func test_the_panel_keeps_one_height_of_at_most_two_fifths_of_the_screen() -> void:
	for screen: Vector2 in [Vector2(1600, 900), Vector2(1280, 720), Vector2(1920, 1080)]:
		var rect := DialogPanel.rect_on(screen)
		assert_true(rect.size.y <= screen.y * 0.4 + 0.5, "at most 40 %% of %s" % screen)
		assert_eq(rect.end.y, screen.y - DialogPanel.MARGIN, "at the bottom")
	var panel := _panel(_silo())
	assert_true(panel.find_children("*", "ScrollContainer", true, false).size() > 0, "what changes scrolls, the panel does not grow")
	panel.free()


# ── In the office ───────────────────────────────────────────────────────────

func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func test_a_teams_place_lists_its_people_and_opens_a_talk() -> void:
	var office := _office()
	var s := office.session
	s.missions.done_once["fix_unused_capacity"] = true
	s.accept("fix_silo_kpis")
	s.region.found["silo_kpis:4"] = true
	office.interact(office.interactable("place:" + DESIGN))
	assert_true(shows(office.ui.place_menu, "Joost van Dijk"))
	assert_eq(office.ui.open_talk("joost"), "")
	assert_true(office.ui.dialog_panel.visible)
	office.ui.close_panels()
	assert_false(s.dialog_meter().size() > 0, "Esc mid-talk ends it gracefully")
	assert_true(office.ui.dialog_panel.visible and shows(office.ui.dialog_panel, DialogPanel.SUMMARY), "its summary shows")
	office.ui.close_panels()
	assert_false(office.ui.is_busy(), "the next Esc closes")
	office.free()


## Review B1: Tab, J, M or K mid-talk never hide or end the talk, pressed once
## or twice; the talk stays on screen and runs on.
func test_the_phone_keys_leave_a_talk_alone() -> void:
	var office := _office()
	_open_joost(office)
	var ui := office.ui
	for app: String in [Phone.HOME, Phone.NOTES, Phone.MAP, Phone.CODEX]:
		ui.toggle_phone(app)
		assert_true(ui.dialog_panel.visible, "the talk stays on screen")
		ui.toggle_phone(app)
		assert_true(ui.dialog_panel.talking(), "the talk runs on")
		assert_false(ui.phone.visible, "the phone stayed down")
	assert_false(office.session.dialog_meter().is_empty(), "never ended unseen")
	office.free()


## The office with one talk with Joost had, and the phone on Wie is wie.
func _mensen_after_joost() -> Office:
	var office := _office()
	var s := office.session
	s.missions.done_once["fix_unused_capacity"] = true
	s.accept("fix_silo_kpis")
	s.region.found["silo_kpis:4"] = true
	office.ui.open_talk("joost")
	for move in LISTEN_TO_JOOST:
		office.ui.dialog_panel.choose(move)
	office.ui.dialog_panel.close_talk()
	office.ui.close_panels()
	office.ui.toggle_phone(Phone.PEOPLE)
	return office


func test_the_mensen_tab_shows_trust_morale_and_what_you_heard() -> void:
	var office := _mensen_after_joost()
	var s := office.session
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), "Joost van Dijk"))
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), DialogPanel.pips(s.person("joost")["trust_pips"])))
	for text in texts_in(office.ui.phone.app(Phone.PEOPLE)):
		if text.begins_with(PeopleApp.MORALE):
			assert_false(_has_digit(text), "morale is a band, not a number")
	office.free()


## Person-needs spec §4: what he told you as quotes with the day and the place,
## your talks with their curve and moves, and your own note.
func test_the_mensen_tab_is_the_player_s_notebook() -> void:
	var office := _mensen_after_joost()
	var s := office.session
	var joost := s.person("joost")
	assert_true(joost["observed"].size() >= 2, "his position and what he let out")
	for o: Dictionary in joost["observed"]:
		assert_true(shows(office.ui.phone.app(Phone.PEOPLE), "\"%s\"" % o["text"]), o["text"])
	var heard_at: Dictionary = joost["observed"][0]
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), "%s · %s" % [s.day_text(heard_at["at"]), "Werkvoorbereiding & ontwerp"]),
		"the day and the place")
	var talk: Dictionary = joost["talks"][0]
	var curves := _nodes(office.ui.phone.app(Phone.PEOPLE), func(n: Node) -> bool: return n is TraceLine)
	assert_eq(curves.size(), 1, "one talk, one curve")
	assert_eq(curves[0].trace, talk["trace"])
	assert_eq(curves[0].labels.size(), talk["moves"].size(), "the moves under the points")
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), DialogPanel.outcome_name(s, talk["outcome"])))
	# Joost's card (Linda may want a talk too: her evenings check-in).
	var joosts := func(n: Node) -> bool: return n is TextEdit and n.placeholder_text == "Wat weet je over Joost?"
	var notes := _nodes(office.ui.phone.app(Phone.PEOPLE), joosts)
	assert_eq(notes.size(), 1, "one note field on his card")
	notes[0].text = "Hij wil eerst gehoord worden."
	notes[0].text_changed.emit()
	assert_eq(s.person("joost")["note"], "Hij wil eerst gehoord worden.", "the note is kept")
	office.ui.phone.app(Phone.PEOPLE).refresh()
	notes = _nodes(office.ui.phone.app(Phone.PEOPLE), joosts)
	assert_eq(notes[0].text, "Hij wil eerst gehoord worden.", "and shown again")
	office.free()


## More than QUOTES_SHOWN quotes: the newest show, the older fold under "Eerder".
func test_older_quotes_fold_away() -> void:
	var office := _mensen_after_joost()
	var s := office.session
	for i in PeopleApp.QUOTES_SHOWN + 2:
		s.people.observed["joost"].append({"dialog": "joost_output_kpi", "key": "k%d" % i, "text": "Regel %d." % i,
			"at": s.region.net.time, "place": "connections.design"})
	office.ui.phone.app(Phone.PEOPLE).refresh()
	assert_false(shows(office.ui.phone.app(Phone.PEOPLE), "\"Regel 0.\""), "the oldest folded")
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), "\"Regel %d.\"" % (PeopleApp.QUOTES_SHOWN + 1)), "the newest shown")
	var fold: Button = _nodes(office.ui.phone.app(Phone.PEOPLE), func(n: Node) -> bool:
		return n is Button and n.text.begins_with(PeopleApp.EARLIER))[0]
	fold.pressed.emit()
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), "\"Regel 0.\""), "unfolded")
	office.free()


## N6 (person-needs spec §5): the need is never on screen, for any need, in the
## talk, its summary or the Mensen tab.
func test_the_need_is_never_shown() -> void:
	var words := Dialog.NEEDS + ["feiten", "veiligheid", "erkenning", "tijd", "eerlijkheid"]
	for need: String in Dialog.NEEDS:
		var office := _office()
		var s := office.session
		s.people.persons["joost"].need = need
		s.missions.done_once["fix_unused_capacity"] = true
		s.accept("fix_silo_kpis")
		s.region.found["silo_kpis:4"] = true
		office.ui.open_talk("joost")
		var seen := _all_text(office.ui.dialog_panel)
		for move in LISTEN_TO_JOOST:
			office.ui.dialog_panel.choose(move)
			seen.append_array(_all_text(office.ui.dialog_panel))
		office.ui.dialog_panel.close_talk()
		seen.append_array(_all_text(office.ui.dialog_panel))
		office.ui.close_panels()
		office.ui.toggle_phone(Phone.PEOPLE)
		seen.append_array(_all_text(office.ui.phone.app(Phone.PEOPLE)))
		var spoken: Array = s.people.observed.get("joost", []).map(func(o: Dictionary) -> String: return o["text"])
		for text in seen:
			if text.begins_with("\"") or spoken.any(func(line: String) -> bool: return text.contains(line)):
				continue  # a quote, his or the player's, may say anything
			for word: String in words:
				var hit := RegEx.create_from_string("(?i)\\b%s\\b" % word).search(text)
				assert_true(hit == null, "%s: the need shows in \"%s\"" % [need, text])
		office.free()


## Every text a player can read under `root`: labels, buttons, tooltips,
## placeholders and the moves under a curve.
func _all_text(root: Node) -> Array[String]:
	var out: Array[String] = []
	for n: Node in _nodes(root, func(_n: Node) -> bool: return true):
		if n is Label or n is Button or n is TextEdit or n is LineEdit:
			out.append(n.text)
		if n is TextEdit or n is LineEdit:
			out.append(n.placeholder_text)
		if n is Control:
			out.append(n.tooltip_text)
		if n is TraceLine:
			out.append_array(n.labels)
	return out


func _nodes(root: Node, keep: Callable) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if keep.call(n):
			out.append(n)
		stack.append_array(n.get_children())
	return out


func test_someone_who_needs_a_talk_shows_an_energy_bar() -> void:
	var office := _office()
	var s := office.session
	s.people.prompts["joost_output_kpi"] = s.region.net.time  # as if a check-in had opened
	s.people.morale["joost"] = 25
	office.people.refresh(s)
	assert_true(office.people.person("joost").bar.visible, "the low-energy bar over Joost")
	var fill: float = (office.people.person("joost").bar.material_override as ShaderMaterial).get_shader_parameter("fill")
	assert_near(fill, 0.25, 0.001)
	assert_false(office.people.person("anouk").bar.visible, "nobody else's")
	office.free()


func test_during_a_talk_the_hud_shows_only_the_date_and_time() -> void:
	var office := _office()
	var hud := office.ui.hud
	_open_joost(office)
	assert_true(office.ui.dialog_panel.visible)
	assert_true(hud.clock_label.visible, "the date and time")
	for l: Control in [hud.budget_label, hud.xp_label, hud.objective_label, hud.help_label]:
		assert_false(l.visible, "hidden in a talk: " + l.name)
	office.ui.close_panels()
	assert_false(hud.budget_label.visible, "the summary is still the talk")
	office.ui.close_panels()
	assert_true(hud.budget_label.visible and hud.xp_label.visible and hud.objective_label.visible, "back after")
	office.free()


func test_a_talk_frames_the_person_over_the_players_shoulder() -> void:
	var office := _office()
	_open_silo_in(office)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.z * 1.3 + joost.basis.x * 0.3
	office.use(joost)
	assert_true(office.ui.dialog_panel.talking())
	assert_true(office.rig.inspecting(), "the camera frames the talk")
	var at := office.talk_point(joost)
	assert_near(Vector2(at.x, at.z).distance_to(Vector2(joost.position.x, joost.position.z)), 0.0, 0.01, "looking at Joost")
	var facing := -office.player.basis.z
	var to_joost := (joost.position - office.player.position) * Vector3(1, 0, 1)
	assert_true(facing.dot(to_joost.normalized()) > 0.95, "the player turns to him")
	office.free()


func _open_silo_in(office: Office) -> void:
	var s := office.session
	s.missions.done_once["fix_unused_capacity"] = true
	s.accept("fix_silo_kpis")
	s.region.found["silo_kpis:4"] = true
	office.people.refresh(s)


func _open_joost(office: Office) -> void:
	_open_silo_in(office)
	assert_eq(office.ui.open_talk("joost"), "")


## U16: the Mensen tab says what an agreement still waits for ("Wat nog
## openstaat") and when you can talk again; "Werkplezier" explains itself.
func test_the_mensen_tab_says_what_is_open_and_when_to_talk_again() -> void:
	var office := _office()
	var s := office.session
	_open_silo_in(office)
	office.ui.open_talk("joost")
	for move in ["mood", "paraphrase", "inquiry", "reflect", "silence", "empathy"]:
		office.ui.dialog_panel.choose(move)
	office.ui.dialog_panel.choose("propose", "lead_and_oldest")
	assert_eq(office.ui.dialog_panel.choose("ask_commitment")["outcome"], "partial")
	office.ui.close_panels()
	office.ui.toggle_phone(Phone.PEOPLE)
	var journal := office.ui.phone.app(Phone.PEOPLE)
	assert_true(shows(journal, PeopleApp.OPEN_HEADING), "Wat nog openstaat")
	assert_true(shows(journal, "Frank moet het goedvinden."), "the condition")
	var again := texts_in(journal).filter(func(t: String) -> bool: return t.begins_with(PeopleApp.AGAIN.left(12)))
	assert_eq(again.size(), 1, "one line on when to talk again")
	var morale: Array[Node] = _nodes(journal, func(n: Node) -> bool:
		return n is Label and n.text.begins_with(PeopleApp.MORALE))
	assert_false(morale.is_empty())
	assert_eq(morale[0].tooltip_text, tr(PeopleApp.MORALE_TIP))
	office.free()


func test_after_a_ruin_the_mensen_tab_says_when_to_talk_again() -> void:
	var office := _office()
	_open_silo_in(office)
	office.ui.open_talk("joost")
	office.ui.dialog_panel.choose("show_data", "silo_kpis:4")
	office.ui.dialog_panel.choose("propose", "lead_and_oldest")
	assert_eq(office.ui.dialog_panel.choose("pressure")["outcome"], "ruined")
	office.ui.close_panels()
	office.ui.toggle_phone(Phone.PEOPLE)
	var until: int = office.session.person("joost")["cooldown_until"]
	assert_true(shows(office.ui.phone.app(Phone.PEOPLE), PeopleApp.again_text(office.session, until, false)))
	assert_false(shows(office.ui.phone.app(Phone.PEOPLE), tr(PeopleApp.AGAIN_NOW)), "not now")
	office.free()


## U18, PLAN 2.12: a question goes to a person who is there, under their
## name, apart from a talk; no list of questions to an empty room.
func test_questions_go_to_the_people_here_not_to_the_room() -> void:
	var office := _office()
	office.interact(office.interactable("place:" + DESIGN))
	var walk: Dictionary = office.session.gemba.question(DESIGN, "walk")
	assert_true(shows(office.ui.place_menu, walk["text"]))
	assert_false(shows(office.ui.place_menu, "Korte vragen aan het team"))
	office.free()
