class_name GameUI
extends CanvasLayer
## Everything on screen over the 3D office: the HUD and one panel at a time
## (mission board, a team's place, the A3, the Check, the coach, the clue
## journal, the map, the codex). The world asks it to open a panel; the panels act on the
## session, and after each action the HUD refreshes and events show as
## toasts.

signal panel_opened
signal panels_closed

var session: GameSession
var hud: Hud
var mission_board: MissionBoard
var place_menu: PlaceMenu
var a3_form: A3Form
var check_panel: CheckPanel
var coach_panel: CoachPanel
var journal: ClueJournal
var office_map: OfficeMap
var codex: CodexPanel
var _panels: Array[UiPanel] = []
## The concepts already known, to toast only new ones.
var _known_concepts := PackedStringArray()
## Training days whose glossary card was shown (once each).
var _carded: Dictionary[String, bool] = {}


func setup(of_session: GameSession) -> void:
	session = of_session
	var root := Control.new()
	root.theme = UiTheme.build()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hud = Hud.new()
	hud.session = session
	root.add_child(hud)
	if not session.error.is_empty():
		show_error(session.error)
		return
	mission_board = MissionBoard.new()
	place_menu = PlaceMenu.new()
	a3_form = A3Form.new()
	check_panel = CheckPanel.new()
	coach_panel = CoachPanel.new()
	journal = ClueJournal.new()
	office_map = OfficeMap.new()
	codex = CodexPanel.new()
	_panels = [mission_board, place_menu, a3_form, check_panel, coach_panel, journal, office_map, codex]
	for p in _panels:
		p.session = session
		p.acted.connect(after_action)
		p.close_requested.connect(close_panels)
		root.add_child(p)
	a3_form.checked.connect(func(problem_id: String, result: Dictionary) -> void:
		check_panel.show_result(problem_id, result)
		_open(check_panel))
	check_panel.back_to_a3.connect(open_a3)
	root.move_child(hud, -1)
	_known_concepts = session.region.profile.concepts.duplicate()
	after_action()


## False when the content could not be loaded: no panels exist, and the
## error stays on screen.
func playable() -> bool:
	return session.error.is_empty()


func open_mission_board() -> void:
	if not playable():
		return
	mission_board.message = ""
	_open(mission_board)


func open_place(place: String) -> void:
	if not playable():
		return
	place_menu.open_at(place)
	_open(place_menu)


func open_a3() -> void:
	if not playable():
		return
	a3_form.message = ""
	_open(a3_form)


func open_coach() -> void:
	if not playable():
		return
	coach_panel.reply = ""
	_open(coach_panel)


func toggle_journal() -> void:
	_toggle(journal)


func toggle_map() -> void:
	_toggle(office_map)


func toggle_codex() -> void:
	_toggle(codex)


func _toggle(panel: UiPanel) -> void:
	if not playable():
		return
	if panel.visible:
		close_panels()
	else:
		_open(panel)


func is_busy() -> bool:
	return _panels.any(func(p: UiPanel) -> bool: return p.visible)


func close_panels() -> void:
	var was_busy := is_busy()
	for p in _panels:
		p.hide()
	hud.show_overlay(true)
	if was_busy:
		panels_closed.emit()


## The clue texts in the journal.
func journal_lines() -> Array[String]:
	var out: Array[String] = []
	for c in ClueJournal.found(session):
		out.append(c.text)
	return out


## After every action: the HUD follows the session and new events show: a
## training day's debrief and glossary card as cards, the rest as toasts.
func after_action() -> void:
	hud.refresh()
	var names := {}
	for m: MissionDef in session.missions.defs.values():
		names[m.id] = UiText.mission_title(m, session)
	for e in session.drain_events():
		if e["type"] == "recurred" and session.is_practice(e.get("problem", "")):
			continue  # the practice problem is retired; the Friday forecast tells the fade
		var text := UiText.event(e, names)
		if not text.is_empty():
			hud.toast(text)
		if e["type"] == "completed":
			_debrief_card(session.missions.defs[e["mission"]], e)
	for m in session.missions.active("training"):
		_glossary_card(m)
	for text in new_concept_toasts():
		hud.toast(text)


## A finished training day: the coach's debrief, with what the player
## measured (the solve day's debrief shows with its score on the Check).
func _debrief_card(m: MissionDef, e: Dictionary) -> void:
	if m.kind != "training" or m.goal_type == "solve":
		return
	var lines: Array[String] = ["'%s'" % m.debrief]
	if e.has("queues"):
		var place_names := {}
		for place: String in e["queues"]:
			place_names[place] = session.region.net.step_at(place).name
		lines.append(UiText.queue_lesson(e["queues"], place_names))
	hud.show_card(str(session.catalog.coach.get("name", "Coach")), lines)


## A training day's concepts on one short card (name and short text), once;
## they stand in for the "new concept" toasts.
func _glossary_card(m: MissionDef) -> void:
	if _carded.has(m.id) or m.teaches.is_empty():
		return
	_carded[m.id] = true
	var lines: Array[String] = []
	for id in m.teaches:
		var def: ConceptDef = session.catalog.concepts.get(id)
		if def != null:
			lines.append("%s — %s" % [def.name, def.short])
			if not id in _known_concepts:
				_known_concepts.append(id)
	hud.show_card("Nieuwe begrippen", lines, UiText.CARD_FOOTER)


## Toasts for the concepts learned since the last call, once each.
func new_concept_toasts() -> Array[String]:
	var out: Array[String] = []
	for id in session.region.profile.concepts:
		if id in _known_concepts:
			continue
		_known_concepts.append(id)
		var def: ConceptDef = session.catalog.concepts.get(id)
		if def != null:
			out.append("Nieuw begrip: %s (K)" % def.name)
	return out


func show_error(text: String) -> void:
	hud.show_prompt("De inhoud kon niet worden geladen: " + text)


func _open(panel: UiPanel) -> void:
	for p in _panels:
		if p != panel:
			p.hide()
	panel.refresh()
	panel.show()
	hud.show_prompt("")
	hud.show_overlay(false)
	panel_opened.emit()
