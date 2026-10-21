class_name GameUI
extends CanvasLayer
## Everything on screen over the 3D office: the HUD and one panel at a time
## (mission board, a team's place, the A3, the Check, the coach, the talk) or
## the player's phone (Phone: the notes, the map, the codex, the people, the
## messages, the missions, the settings). The world asks it to open a panel or
## raise the phone; they act on the session, and after each action the HUD
## refreshes, events show as toasts and what is new reaches the phone.

signal panel_opened
signal panels_closed
## A talk opened (the world frames the person).
signal talk_opened(person_id: String)
## The pause menu's "Naar het titelmenu" (the game has saved itself).
signal title_requested
## The pause menu came up (true) or went (false): the tree is paused with it.
signal pause_changed(on: bool)

## Why a person has no talk for you now that the world answers with a quick line over their
## head (Office.talk_to; Phase 2 §1.4): nothing to discuss, or not one of the talking cast.
const NO_TALK: Array[String] = ["nothing_to_say", "unknown_person"]

var session: GameSession
var hud: Hud
var mission_board: MissionBoard
var place_menu: PlaceMenu
var a3_form: A3Form
var check_panel: CheckPanel
var coach_panel: CoachPanel
## The player's phone (PLAN 2.14 S1-F); the journal, the map and the codex live
## in its apps (Notities, Kaart, Begrippen) and never open on their own.
var phone: Phone
var journal: ClueJournal
var office_map: OfficeMap
var codex: CodexPanel
var talk_view: TalkView
## The session layer (PLAN 1.4): the terugblik, Intussen, the stop note, the
## discovery toasts and the side offers; the playtest log; autosave.
var session_layer: SessionLayer
var terugblik: TerugblikCard
var intussen: IntussenPanel
var pause_menu: PauseMenu
## Off until the real game starts (begin_play), so tests write no log.
var playtest_log := SessionLog.new(SessionLog.PATH, false)
var settings_path := Settings.PATH:
	set(value):
		settings_path = value
		if phone != null:
			(phone.app(Phone.SETTINGS) as SettingsApp).settings_path = value
## The saves (PLAN 2.7): the game saves itself into the autosave at every
## dagstart and on closing, and the pause menu into the five slots; null
## saves nothing (tests, tools).
var saves: SaveSlots
## When this session started (real time), for the stop note and the log.
var started_ms := Time.get_ticks_msec()
## The in-game day whose dagstart shows the stop note; -1 for none.
var _stop_day := -1
## Experiments running, to open Intussen once when one starts.
var _running: Dictionary[String, bool] = {}
## Missions taken on this session → when (real ms), until their first key clue.
var _accepted_ms: Dictionary[String, int] = {}
var _panels: Array[UiPanel] = []


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
	phone = Phone.new()
	journal = (phone.app(Phone.NOTES) as NotesApp).journal
	office_map = (phone.app(Phone.MAP) as MapApp).map
	codex = (phone.app(Phone.CODEX) as CodexApp).codex
	talk_view = TalkView.new()
	terugblik = TerugblikCard.new()
	intussen = IntussenPanel.new()
	pause_menu = PauseMenu.new()
	_panels = [mission_board, place_menu, a3_form, check_panel, coach_panel, phone, terugblik, intussen,
		talk_view, pause_menu]
	_setup_session_layer(of_layer)
	for p in _panels:
		p.session = session
		p.acted.connect(after_action)
		p.close_requested.connect(resume if p == pause_menu else close_panels)
		root.add_child(p)
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS   # the one thing that runs while paused
	a3_form.checked.connect(func(problem_id: String, result: Dictionary) -> void:
		check_panel.show_result(problem_id, result)
		_open(check_panel))
	check_panel.back_to_a3.connect(open_a3)
	place_menu.talk_requested.connect(open_talk)
	talk_view.coach_requested.connect(open_coach)
	pause_menu.save_requested.connect(save_to)
	pause_menu.title_requested.connect(func() -> void:
		end_session()
		resume()   # the title menu must not start paused
		title_requested.emit())
	root.move_child(hud, -1)
	phone.buzz.connect(hud.buzz)
	phone.badges_changed.connect(func() -> void: hud.phone_status(phone.unread_count()))
	after_action()


## False when the content could not be loaded: no panels exist, and the
## error stays on screen.
func playable() -> bool:
	return session.error.is_empty()


func open_mission_board() -> void:
	if not playable() or not hud.may_show("board"):   # no board before the first talk (2.7d)
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
## shows the person's "Niet nu." as the prompt). `where`: TalkView.STANDING, or
## WALKING (Ruud's walk, a shadow day); the world makes it a call when they are not here.
func open_talk(person_id: String, where: String = TalkView.STANDING) -> String:
	if not playable():
		return "unplayable"
	var refused := talk_view.start(person_id, where)
	if refused.is_empty():
		_open(talk_view)
		talk_opened.emit(person_id)
	return refused


## A talk asked for in the office (walking up to someone): it opens, or a toast
## says why not in the person's own way ("Niet nu."). Returns open_talk's code: with
## one of NO_TALK the world lets them say a quick line instead (Office.talk_to).
func ask_talk(person_id: String, display_name: String) -> String:
	var refused := open_talk(person_id)
	if refused == "cooling_down":
		var special := JsonFile.dict_or_empty(session.catalog.dialog_bank.get("special"))
		hud.toast("%s: \"%s\"" % [display_name, special.get("cooling_down", "")])
	return refused


## Esc from the world (PLAN 2.13 A: Esc pauses everything): the pause menu
## goes away; a panel closes, but a talk pauses under the menu; with nothing
## open, the pause menu.
func escape() -> void:
	if not playable():
		return
	if paused():
		resume()
	elif is_busy() and not talk_view.talking():
		close_panels()
	else:
		open_pause()


## The pause menu, over whatever is on screen (a scene, a talk), and the tree
## paused under it: scenes, talks, people and the clock stop. Only when the
## game saves.
func open_pause() -> void:
	if not playable() or saves == null or paused():
		return
	pause_menu.saves = saves
	pause_menu.open()
	pause_menu.refresh()
	pause_menu.get_parent().move_child(pause_menu, -1)
	pause_menu.show()
	hud.show_prompt("")
	_set_paused(true)


func paused() -> bool:
	return pause_menu != null and pause_menu.visible


## "Verder spelen" or Esc: the menu goes, everything under it runs on.
func resume() -> void:
	if not paused():
		return
	pause_menu.hide()
	_set_paused(false)


func _set_paused(on: bool) -> void:
	if is_inside_tree():
		get_tree().paused = on
	pause_changed.emit(on)


## Save into manual slot `number` (the pause menu, overwrite confirmed).
func save_to(number: int) -> void:
	var error := saves.save(number, session, session_layer) if saves != null else "the game is not saved"
	if error.is_empty():
		hud.toast(tr(SAVED_IN) % number)
		resume()
	else:
		push_warning(error)
		hud.toast(tr(SAVE_FAILED) % error)


## Tab (`app` HOME), or J, M and K (Notities, Kaart, Begrippen): raise the
## phone on that app, switch to it, or lower the phone when it already shows
## (or for Tab). Each app from its moment on (Opening.hud, 2.7d §3); never
## mid-talk (review B1: hiding the talk let the next press end it unseen).
func toggle_phone(app := Phone.HOME) -> void:
	if not playable() or talk_view.talking() or not phone.may_open(app):
		return
	if phone.visible and (app == Phone.HOME or app == phone.current):
		close_panels()
		return
	var raising := not phone.visible
	if raising:
		phone.current = Phone.HOME
		phone.skin = CreatorLook.skin_of(session.player.look)   # your own hand ("Uiterlijk" may have changed it)
		_open(phone)
	phone.open_app(app)
	if raising:
		phone.slide_in()   # to where the app holds it (the map: sideways)


## The lift: the phone's map as the floor switch that takes you there.
func open_lift() -> void:
	if not playable():
		return
	office_map.lift = true
	if phone.visible and phone.current == Phone.MAP:
		phone.refresh()
		return
	phone.revealed = {}   # the lift's floors need no moment
	phone.current = Phone.HOME
	_open(phone)
	phone.open_app(Phone.MAP)
	phone.revealed = hud.revealed


## The panels over the world (the phone among them).
func panels() -> Array[UiPanel]:
	return _panels


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


## Close what is open (and the pause). Mid-talk it ends the talk as
## "Afronden" does (a graceful close, never a ruin) and its summary shows;
## the next call closes. Esc mid-talk pauses instead (escape()).
func close_panels() -> void:
	resume()
	var was_busy := is_busy()
	if talk_view != null and talk_view.talking():
		talk_view.close_talk()
		_open(talk_view)  # its summary shows, whatever else was open
		return
	for p in _panels:
		p.hide()
	hud.show_overlay(true)
	hud.set_talking(false)
	if was_busy:
		panels_closed.emit()


## The clue texts in the journal.
func journal_lines() -> Array[String]:
	var out: Array[String] = []
	for c in ClueJournal.found(session):
		out.append(c.text)
	return out


## After every action: the HUD follows the session and new events show as
## toasts; what reaches the phone (a training day's note and debrief, new
## concepts) badges its app and buzzes it once, never during the first day's
## scene (it buzzes when the scene is over).
func after_action() -> void:
	var shown := Opening.hud(session, session_layer)
	hud.reveal(shown)
	phone.revealed = shown
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
		if not text.is_empty() and not Opening.running(session_layer):   # the first day is one scene (2.7d)
			hud.toast(text)
		if e["type"] == "completed":
			_debrief_message(session.missions.defs[e["mission"]], e)
		_session_event(e)
	for m in session.missions.active("training"):
		if not m.id in session_layer.carded:   # a training day's morning, once a game
			session_layer.carded.append(m.id)
	_phone_beat()
	_session_beat()


## A finished training day: the coach's debrief in Berichten, with what the
## player measured (the solve day's debrief shows with its score on the Check).
func _debrief_message(m: MissionDef, e: Dictionary) -> void:
	if m.kind != "training" or m.goal_type == "solve" or Opening.running(session_layer):
		return   # the first day's debrief is Ruud's Tuesday line (2.7d §4)
	PhoneMessages.push(session_layer, PhoneMessages.DEBRIEF + m.id, session.region.net.time,
		{"queues": e["queues"]} if e.has("queues") else {})


## What reached the phone: the messages that arrive from the game's state; the
## badges; one buzz for anything new, once the first day's scene is over.
func _phone_beat() -> void:
	PhoneMessages.sync(session, session_layer)
	if not Opening.running(session_layer) and phone.announce():
		phone.buzz.emit()
	phone.refresh()
	hud.phone_status(phone.unread_count())


## A save from before the phone: what it holds counts as read and seen, so
## a resumed game does not open on a pile of badges.
func _read_old_save() -> void:
	if session_layer.phone_saved:
		return
	PhoneMessages.sync(session, session_layer)
	for entry: Dictionary in session_layer.inbox:
		entry["read"] = true
	session_layer.concepts_seen.assign(session.region.profile.concepts)
	session_layer.phone_saved = true


# ── The session layer ───────────────────────────────────────────────────────

const DISCOVERY_TOAST := "Ontdekking: %s (K)"
const SAVE_FAILED := "Opslaan lukte niet: %s"
const SAVED_IN := "Opgeslagen in slot %d."


func _setup_session_layer(of_layer: SessionLayer) -> void:
	session_layer = of_layer if of_layer != null else SessionLayer.new()
	hud.layer = session_layer
	if of_layer == null:
		session_layer.begin(session)
	mission_board.layer = session_layer
	journal.layer = session_layer
	phone.setup(session, session_layer)
	_read_old_save()
	var settings := phone.app(Phone.SETTINGS) as SettingsApp
	settings.settings_path = settings_path
	settings.log_toggled.connect(set_log_enabled)
	settings.auto_text_changed.connect(pause_menu.auto_text_changed.emit)   # the office follows it as from the pause menu
	journal.reopen.connect(func(what: String) -> void:
		if what == "terugblik":
			open_terugblik(session_layer.last_card)
		else:
			open_intussen(_running.keys().front() if not _running.is_empty() else ""))
	intussen.layer = session_layer
	for id in SessionLayer.running(session):
		_running[id] = true


## The real game: it saves itself into `of_saves`' autosave, keeps the
## playtest log (in the saves folder) as the settings say, and a resumed game
## opens with the terugblik.
func begin_play(of_saves: SaveSlots, resumed: bool) -> void:
	saves = of_saves
	playtest_log = SessionLog.from_settings(settings_path, saves.dir)
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


## The playtest log on or off (Instellingen's switch), kept in the settings.
func set_log_enabled(on: bool) -> void:
	var error := SessionLog.set_enabled_in(settings_path, on)
	if not error.is_empty():
		push_warning(error)
	playtest_log.enabled = on


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
	if saves == null:
		return
	var error := saves.autosave(session, session_layer)
	if not error.is_empty():
		push_warning(error)
		hud.toast(tr(SAVE_FAILED) % error)


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
	hud.set_talking(panel == talk_view)
	panel_opened.emit()
