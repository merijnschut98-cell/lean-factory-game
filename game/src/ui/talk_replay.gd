class_name TalkReplay
extends Control
## "Praat opnieuw" on the designer page (Phase 3 slice 3.0): every talk of the content, started at
## once in the real TalkView over a plain backdrop, with a preset of what the person remembers
## (nothing, a talk ruined yesterday, a kept promise). Each play is on a session of its own,
## thrown away when the talk closes; the summary card shows the route taken (TalkSummary). Esc
## leaves the talk for the list, and the list for the designer page. Dutch for the designer, as
## the page around it.

## Back to the designer page.
signal back_requested

const HEADING := "Praat opnieuw"
const PLAY := "Speel"
const NO_TALK := "Geen gesprek te starten: %s"
const KIND_NAMES := {"persuade": "gesprek", "checkin": "check-in", "expert": "deskundige"}
const NONE := "none"
const RUINED := "ruined_yesterday"
const KEPT := "kept_promise"
## The presets, with their names in the picker.
const PRESETS: Array[String] = [NONE, RUINED, KEPT]
const PRESET_NAMES := {NONE: "Geen voorgeschiedenis", RUINED: "Gisteren verpest", KEPT: "Belofte nagekomen"}
## The list's scrolling height (px), so the buttons below stay on a 900 px screen.
const LIST_HEIGHT := 640.0

## The list of talks, hidden while one runs.
var list: VBoxContainer
## The running talk (null in the list); it holds the session it runs on.
var view: TalkView
## Dialog id → the picker of its row.
var pickers: Dictionary[String, OptionButton] = {}
var _message: Label


## Build (once) the backdrop and the list: one row per persuasion, check-in and expert talk.
func build() -> void:
	if list != null:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Palette.VOLTANA_BLUE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 72 if side in ["left", "right"] else 40)
	add_child(margin)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	margin.add_child(list)
	list.add_child(UiPanel.label(tr(HEADING), 40, Color.WHITE))
	var column := UiPanel.add_scroll_list(list, LIST_HEIGHT)
	for row in rows(Catalog.load_from()):
		_row(column, row)
	_message = UiPanel.paragraph("", Palette.SAFETY_ORANGE, UiTheme.SMALL)
	list.add_child(_message)
	list.add_child(UiPanel.button(tr(TitleMenu.BACK), back_requested.emit))


## Every talk of the content, in the bank's order: [{id, person (id), name, kind}].
static func rows(catalog: Catalog) -> Array[Dictionary]:
	var names := {}
	for p in catalog.persons:
		names[p.id] = p.name
	var out: Array[Dictionary] = []
	for d in catalog.dialogs:
		if d.kind in Dialog.KINDS:
			out.append({"id": d.id, "person": d.person, "name": names.get(d.person, d.person), "kind": d.kind})
	return out


## The presets a talk of `kind` can have: only a persuasion can be ruined or hold a promise.
static func presets_for(kind: String) -> Array[String]:
	return PRESETS if kind == "persuade" else [NONE]


## A new game with talk `dialog_id` ready to open and `preset` applied. Its person is present,
## and everything that would gate the talk in play (its mission, clue, needs, trigger, topics)
## is open on this session's own copy of the content. `error` is set for an unknown talk.
static func session_for(dialog_id: String, preset: String, seed_value: int = 11) -> GameSession:
	var s := GameSession.new_game(seed_value, Catalog.DATA_DIR, false)
	var d: DialogDef = s.people.dialogs.get(dialog_id) if s.error.is_empty() else null
	if d == null:
		if s.error.is_empty():
			s.error = "unknown talk: " + dialog_id
		return s
	_open_up(s, d)
	apply(preset, s, d)
	return s


## Put the session in the state `preset` names for talk `d` (anything else leaves it be):
## RUINED the way play records a ruined talk (People.finish, a day back: memory, log, the
## retry, the morning hello), KEPT as the fact Missions records for a kept promise.
static func apply(preset: String, s: GameSession, d: DialogDef) -> void:
	match preset:
		RUINED:
			var talk := s.people.start(d, SessionTalks.world(s, s.people.persons[d.person]))
			talk.outcome = "ruined"
			s.people.finish(talk, s.region.net.time - SimCalendar.days(1))
			while s.people.cooling_down(d.person, s.region.net.time):   # a weekend between
				s.region.advance_days(1)
		KEPT:
			s.missions.facts.add("promise_kept:" + d.id)


## This talk is the only one its person has, and open: the world is not asked for its mission,
## clue, facts, trigger or expert trust.
static func _open_up(s: GameSession, d: DialogDef) -> void:
	for other: DialogDef in s.people.dialogs.values():
		if other.person == d.person and other != d:
			s.people.dialogs.erase(other.id)
	d.needs = {}
	d.requires_clue = ""
	d.trigger = {}
	s.people.trust[d.person] = 100
	for topic: Dictionary in d.topics:
		topic.erase("needs")
	if s.missions.defs.has(d.mission):
		s.missions.progress[d.mission] = {"status": "active", "asks": {}, "seen": {}}


## Play talk `dialog_id` with `preset`: the real TalkView over the backdrop. The error shows
## under the list when the talk will not open.
func start(dialog_id: String, preset: String) -> void:
	build()
	var s := session_for(dialog_id, preset)
	var d: DialogDef = s.people.dialogs.get(dialog_id)
	var shown := TalkView.new()
	shown.session = s
	var refused := s.error if d == null else shown.start(d.person)
	if not refused.is_empty():
		shown.free()
		_message.text = tr(NO_TALK) % refused
		return
	_message.text = ""
	view = shown
	view.close_requested.connect(close_talk)
	add_child(view)
	view.show()
	list.hide()


## "Speel" on the row of `dialog_id`, with the preset its picker shows.
func play(dialog_id: String) -> void:
	build()
	var picker := pickers[dialog_id]
	start(dialog_id, picker.get_item_metadata(picker.selected))


## Leave the talk for the list; its session goes with it.
func close_talk() -> void:
	if view == null:
		return
	remove_child(view)
	view.queue_free()
	view = null
	list.show()


## A key, as the screen reads it: true when it acted. Esc closes the talk, then the list.
func press(key: Key) -> bool:
	if key != KEY_ESCAPE:
		return false
	if view != null:
		close_talk()
	else:
		back_requested.emit()
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key != null and key.pressed and not key.echo and press(key.physical_keycode):
		get_viewport().set_input_as_handled()


func _row(parent: Node, row: Dictionary) -> void:
	var box := UiPanel.add_card(parent)
	var line := HBoxContainer.new()
	box.add_child(line)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(texts)
	texts.add_child(UiPanel.label(row["id"], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	texts.add_child(UiPanel.label("%s  ·  %s" % [row["name"], tr(KIND_NAMES[row["kind"]])], UiTheme.SMALL, Palette.INK))
	var picker := OptionButton.new()
	for preset in presets_for(row["kind"]):
		picker.add_item(tr(PRESET_NAMES[preset]))
		picker.set_item_metadata(picker.item_count - 1, preset)
	picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(picker)
	pickers[row["id"]] = picker
	var go := UiPanel.button(tr(PLAY), play.bind(row["id"]))
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(go)
