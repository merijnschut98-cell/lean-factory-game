extends TestCase
## The dialog UI (PLAN 1.2, dialog spec §11) on the real content: the meter
## fills and shows arrows, never a number; every chip, always, with its line
## on hover; the layer tracker, the cue and the picks; the summary card; the
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


func test_the_panel_opens_with_the_person_the_meter_and_every_chip() -> void:
	var s := _silo()
	var panel := _panel(s)
	assert_eq(panel.title_label.text, "Joost van Dijk  ·  " + panel.talk["role"])
	assert_true(shows(panel, "Ik heb tien minuten."), "the opening")
	assert_true(shows(panel, "Op z'n hoede"), "the band, named")
	assert_true(shows(panel, "Standpunt"), "the layer tracker")
	var chips := 0
	for m in s.dialog_moves():
		assert_true(shows(panel, m["label"]), m["id"])
		chips += 1
	assert_eq(chips, Dialog.MOVES.size(), "every move, always")
	panel.free()


func test_a_chip_shows_its_line_on_hover() -> void:
	var s := _silo()
	var panel := _panel(s)
	var tips := {}
	var stack: Array[Node] = [panel.body]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button:
			tips[n.text] = n.tooltip_text
		stack.append_array(n.get_children())
	for m in s.dialog_moves():
		var chip: String = m["label"] + (DialogPanel.PICK_MARK if m.has("picks") else "")
		assert_eq(tips.get(chip, ""), "\"%s\"" % m["line"], m["id"])
	assert_true(tips.has("Voorstel doen" + DialogPanel.PICK_MARK), "a ▸ chip")
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


func test_a_pick_chip_opens_its_picks_and_a_pick_is_a_move() -> void:
	var s := _silo()
	var panel := _panel(s)
	panel.open_picks("propose")
	assert_true(shows(panel, DialogPanel.PICK_HEADING))
	var picks: Array = s.dialog_moves().filter(func(m: Dictionary) -> bool: return m["id"] == "propose")[0]["picks"]
	assert_true(shows(panel, str(picks[0].get("name", picks[0]["id"])).left(DialogPanel.PICK_CHARS)))
	var r := panel.choose("propose", picks[0]["id"])
	assert_false(r.has("error"))
	assert_eq(panel.picking, "", "the picks close")
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


func test_pressure_and_blame_look_like_every_other_chip() -> void:
	var panel := _panel(_silo())
	var chips := _chips_of(panel)
	for text in ["Druk zetten", "Aanspreken", "Afronden", "Open vraag"]:
		assert_true(chips.has(text), text)
		assert_false((chips[text] as Button).has_theme_stylebox_override("normal"), "no styling that judges: " + text)
	panel.free()


func test_an_open_pick_chip_is_outlined_never_the_meters_green() -> void:
	var panel := _panel(_silo())
	panel.open_picks("propose")
	var chip: Button = _chips_of(panel)["Voorstel doen" + DialogPanel.PICK_MARK]
	var box := chip.get_theme_stylebox("normal") as StyleBoxFlat
	assert_true(box.border_width_bottom > 0, "outlined")
	assert_false(box.bg_color in OpennessBar.COLORS or box.bg_color == Palette.GREEN_DARK, "not a colour that says good")
	panel.free()


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


func test_the_mensen_tab_shows_trust_morale_and_what_you_heard() -> void:
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
	office.ui.toggle_journal()
	office.ui.journal.show_tab(ClueJournal.PEOPLE)
	assert_true(shows(office.ui.journal, "Joost van Dijk"))
	assert_true(shows(office.ui.journal, "Belang:"), "what he told you")
	assert_true(shows(office.ui.journal, DialogPanel.pips(s.person("joost")["trust_pips"])))
	for text in texts_in(office.ui.journal):
		if text.begins_with(ClueJournal.MORALE):
			assert_false(_has_digit(text), "morale is a band, not a number")
	office.free()


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
	for l: Control in [hud.budget_label, hud.xp_label, hud.mission_label, hud.help_label]:
		assert_false(l.visible, "hidden in a talk: " + l.name)
	office.ui.close_panels()
	assert_false(hud.budget_label.visible, "the summary is still the talk")
	office.ui.close_panels()
	assert_true(hud.budget_label.visible and hud.xp_label.visible and hud.mission_label.visible, "back after")
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
