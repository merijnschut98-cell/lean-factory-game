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
	assert_true(shows(panel, "Stemming peilen · Samenvatten · Afronden"), "the moves under the trace")
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
