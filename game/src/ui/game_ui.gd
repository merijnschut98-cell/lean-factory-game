class_name GameUI
extends CanvasLayer
## Everything on screen over the 3D office: the HUD and one panel at a time
## (mission board, a team's place, the A3, the Check, the coach, the clue
## journal, the map). The world asks it to open a panel; the panels act on the
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
var _panels: Array[UiPanel] = []


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
	_panels = [mission_board, place_menu, a3_form, check_panel, coach_panel, journal, office_map]
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


## After every action: the HUD follows the session and new events show.
func after_action() -> void:
	hud.refresh()
	var names := {}
	for m: MissionDef in session.missions.defs.values():
		names[m.id] = m.name
	for e in session.drain_events():
		var text := UiText.event(e, names)
		if not text.is_empty():
			hud.toast(text)


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
