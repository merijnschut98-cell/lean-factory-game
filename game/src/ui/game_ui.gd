class_name GameUI
extends CanvasLayer
## Everything on screen over the 3D office: the HUD and one panel at a time
## (mission board, a team's place, the A3, the Check, the coach, the clue
## journal, the map, the codex). The world asks it to open a panel; the panels act on the
## session, and after each action the HUD refreshes and events show as
## toasts.

signal panel_opened
signal panels_closed

## A person asked in the office who has nothing to talk about now.
const NOTHING_TO_SAY := "%s knikt je toe en werkt door."

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
var dialog_panel: DialogPanel
## The session layer (PLAN 1.4): the terugblik, Intussen, the stop note, the
## discovery toasts and the side offers; the playtest log; autosave.
var session_layer: SessionLayer
var terugblik: TerugblikCard
var intussen: IntussenPanel
## Off until the real game starts (begin_play), so tests write no log.
var playtest_log := SessionLog.new(SessionLog.PATH, false)
var settings_path := SessionLog.SETTINGS
## The slot the game saves itself to at every dagstart and on closing; ""
## saves nothing (tests, tools).
var save_slot := ""
## When this session started (real time), for the stop note and the log.
var started_ms := Time.get_ticks_msec()
## The in-game day whose dagstart shows the stop note; -1 for none.
var _stop_day := -1
## Experiments running, to open Intussen once when one starts.
var _running: Dictionary[String, bool] = {}
## Missions taken on this session → when (real ms), until their first key clue.
var _accepted_ms: Dictionary[String, int] = {}
var _panels: Array[UiPanel] = []
## The concepts already known, to toast only new ones.
var _known_concepts := PackedStringArray()
## Training days whose glossary card was shown (once each).
var _carded: Dictionary[String, bool] = {}


## `of_layer`: a saved game's session layer (its snapshot opens the
## terugblik, see begin_play); a new one otherwise.
func setup(of_session: GameSession, of_layer: SessionLayer = null) -> void:
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
	dialog_panel = DialogPanel.new()
	terugblik = TerugblikCard.new()
	intussen = IntussenPanel.new()
	_panels = [mission_board, place_menu, a3_form, check_panel, coach_panel, journal, office_map, codex, terugblik, intussen,
		dialog_panel]
	_setup_session_layer(of_layer)
	for p in _panels:
		p.session = session
		p.acted.connect(after_action)
		p.close_requested.connect(close_panels)
		root.add_child(p)
	a3_form.checked.connect(func(problem_id: String, result: Dictionary) -> void:
		check_panel.show_result(problem_id, result)
		_open(check_panel))
	check_panel.back_to_a3.connect(open_a3)
	place_menu.talk_requested.connect(open_talk)
	dialog_panel.coach_requested.connect(open_coach)
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


## Talk with a person: "" or why not (start_dialog's code; cooling_down
## shows the person's "Niet nu." as the prompt).
func open_talk(person_id: String) -> String:
	if not playable():
		return "unplayable"
	var refused := dialog_panel.start(person_id)
	if refused.is_empty():
		_open(dialog_panel)
	return refused


## A talk asked for in the office (walking up to someone): it opens, or a toast
## says why not in the person's own way ("Niet nu.", a nod).
func ask_talk(person_id: String, display_name: String) -> void:
	match open_talk(person_id):
		"", "unplayable", "in_dialog":
			pass
		"cooling_down":
			var special := JsonFile.dict_or_empty(session.catalog.dialog_bank.get("special"))
			hud.toast("%s: \"%s\"" % [display_name, special.get("cooling_down", "")])
		_:
			hud.toast(tr(NOTHING_TO_SAY) % display_name)


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


## The share of the screen's width an open docked panel covers (the team's
## menu), its margin included; 0 when none is open.
func docked_share() -> float:
	var width: float = get_viewport().get_visible_rect().size.x if is_inside_tree() \
		else ProjectSettings.get_setting("display/window/size/viewport_width")
	for p in _panels:
		if p.visible and p.docked:
			return (p.get_combined_minimum_size().x + UiPanel.DOCK_MARGIN) / width
	return 0.0


func is_busy() -> bool:
	return _panels.any(func(p: UiPanel) -> bool: return p.visible)


func close_panels() -> void:
	var was_busy := is_busy()
	if dialog_panel != null and dialog_panel.talking():
		dialog_panel.close_talk()  # Esc mid-talk: a graceful close, never a ruin
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
	var problem_names := UiText.problem_names(session)
	var team_names := UiText.team_names(session)
	for e in session.drain_events():
		if e["type"] in ["recurred", "slipping"] and session.is_practice(e.get("problem", "")):
			continue  # the practice problem is retired; the Friday forecast tells the fade
		var text := UiText.event(e, names, problem_names, team_names)
		if not text.is_empty():
			hud.toast(text)
		if e["type"] == "completed":
			_debrief_card(session.missions.defs[e["mission"]], e)
		_session_event(e)
	for m in session.missions.active("training"):
		_glossary_card(m)
	for text in new_concept_toasts():
		hud.toast(text)
	_session_beat()


## A finished training day: the coach's debrief, with what the player
## measured (the solve day's debrief shows with its score on the Check).
func _debrief_card(m: MissionDef, e: Dictionary) -> void:
	if m.kind != "training" or m.goal_type == "solve":
		return
	var lines: Array[String] = ["'%s'" % session.mission_debrief(m.id)]
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


# ── The session layer ───────────────────────────────────────────────────────

const DISCOVERY_TOAST := "Ontdekking: %s (K)"
const SAVE_FAILED := "Opslaan lukte niet: %s"


func _setup_session_layer(of_layer: SessionLayer) -> void:
	session_layer = of_layer if of_layer != null else SessionLayer.new()
	if of_layer == null:
		session_layer.begin(session)
	mission_board.layer = session_layer
	journal.layer = session_layer
	journal.log_on = SessionLog.enabled_in(settings_path)
	journal.reopen.connect(func(what: String) -> void:
		if what == "terugblik":
			open_terugblik(session_layer.last_card)
		else:
			open_intussen(_running.keys().front() if not _running.is_empty() else ""))
	journal.log_toggled.connect(set_log_enabled)
	intussen.layer = session_layer
	for id in SessionLayer.running(session):
		_running[id] = true


## The real game (the office as the main scene): it saves itself to `slot`,
## keeps the playtest log as the settings say, and a resumed game opens with
## the terugblik.
func begin_play(slot: String, resumed: bool) -> void:
	save_slot = slot
	playtest_log = SessionLog.from_settings(settings_path)
	playtest_log.write("Sessie begint (%s) · speltijd %s" % ["hervat" if resumed else "nieuw spel", session.clock_text()])
	if resumed:
		open_terugblik(session_layer.open_session(session))


## The game closes: save, and the session's end in the log (engagement loop
## §8: its length, where it ended, the loops left open).
func end_session() -> void:
	_autosave()
	playtest_log.write("Sessie eindigt na %d min · gestopt: %s · open lussen: %d · speltijd %s" % [roundi(real_minutes()),
		SessionLog.ended_at(session, _stop_day == SimCalendar.day_of(session.region.net.time)),
		SessionLog.open_loops(session), session.clock_text()])


func real_minutes() -> float:
	return (Time.get_ticks_msec() - started_ms) / 60000.0


func open_terugblik(card: Dictionary) -> void:
	if not playable() or card.is_empty():
		return
	terugblik.show_card(card)
	_open(terugblik)


func open_intussen(problem_id: String) -> void:
	if not playable() or problem_id.is_empty():
		return
	intussen.open_for(problem_id)
	_open(intussen)


## The playtest log on or off (the journal's switch), kept in the settings.
func set_log_enabled(on: bool) -> void:
	var error := SessionLog.set_enabled_in(settings_path, on)
	if not error.is_empty():
		push_warning(error)
	playtest_log.enabled = on
	journal.log_on = on


## One event as the session layer sees it: a discovery's toast (one a day,
## the rest for the next terugblik) and the log's moments.
func _session_event(e: Dictionary) -> void:
	match e["type"]:
		"discovery":
			var name := TerugblikCard.discovery_name(session, e["id"])
			if session_layer.discovery_toast(session, e["id"]):
				hud.toast(DISCOVERY_TOAST % name)
			playtest_log.write("Ontdekking: %s na %d min" % [name, roundi(real_minutes())])
		"accepted":
			_accepted_ms[e["mission"]] = Time.get_ticks_msec()
			playtest_log.write("Missie aangenomen: " + UiText.mission_title(session.missions.defs[e["mission"]], session))


## After every action: side offers, the dagstart (autosave, the stop note
## after half an hour), the first key clue in the log, and Intussen when an
## experiment has just started.
func _session_beat() -> void:
	var today := SimCalendar.day_of(session.region.net.time)
	if session_layer.update(session):
		_autosave()
		if SessionLayer.stop_note_due(real_minutes()):
			_stop_day = today
	hud.stop_note.visible = _stop_day == today
	for id: String in _accepted_ms.keys():
		var m: MissionDef = session.missions.defs.get(id)
		if m != null and session.clues_found(m.goal_problem).any(func(c: Clue) -> bool: return c.key):
			playtest_log.write("Eerste sleutelaanwijzing voor %s na %d min" % [UiText.mission_title(m, session),
				roundi((Time.get_ticks_msec() - _accepted_ms[id]) / 60000.0)])
			_accepted_ms.erase(id)
	var now_running := SessionLayer.running(session)
	for id in now_running:
		if not _running.has(id):
			open_intussen(id)
	_running.clear()
	for id in now_running:
		_running[id] = true


func _autosave() -> void:
	if save_slot.is_empty():
		return
	var error := GameSave.write(save_slot, session, session_layer)
	if not error.is_empty():
		push_warning(error)
		hud.toast(SAVE_FAILED % error)


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
