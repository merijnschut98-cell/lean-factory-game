class_name SceneLines
extends Control
## What is said in a scripted scene (PLAN 2.7d, the first day): one line at a
## time at the bottom of the screen, as a film's subtitle, with who says it.
## A line types itself out and stays until the player moves on (PLAN 2.13 A,
## Merijn 2026-10-19): Spatie, Enter or a click shows the whole line, the next
## press goes on; ← or Backspace re-reads the last lines; holding Spatie about
## a second asks the scene to skip (skip_requested). "Tekst loopt vanzelf
## door" (`auto`, a setting, off by default) brings back the timed advance.
## An aside (a call-out from afar) moves on by itself and holds nothing.
## Beside the lines: a one-off control hint, a choice between two answers, a
## paper held up to the camera (the badge, the letter) and the phone's
## notifications. While a line, a choice or a paper is up the scene holds the
## player (holds()); its scene locks walking and the camera.
##
## All time runs through step(dt) (its scene calls it each frame), so tests
## drive it frame by frame.

## Emitted when the lines queued with say() have all been shown.
signal lines_done
## Emitted with the index of the answer chosen in ask().
signal chosen(index: int)
## Emitted when the paper is put away (Verder or Spatie).
signal paper_closed
## Spatie held for HOLD_SKIP_S: the scene should skip to its end state.
signal skip_requested

## A line stays at least this long, plus this per character, at most this long.
const READ_MIN := 2.4
const READ_PER_CHAR := 0.055
const READ_MAX := 7.0
const HINT_SECONDS := 5.0
const PHONE_SECONDS := 4.5
const NEXT := "Verder  (Spatie)"
const SKIP_HINT := "Houd spatie ingedrukt om over te slaan"
const AUTO_LABEL := "Tekst loopt vanzelf door"
## A line types itself out at this many characters a second (estimate: a
## calm subtitle pace, quicker than reading so it never waits on the text).
const REVEAL_CPS := 45.0
## Holding Spatie this long skips the scene (Merijn: "about a second").
const HOLD_SKIP_S := 1.0
## The lines ← can go back to.
const HISTORY := 10
## The setting (user://settings.cfg, section "text"): lines move on by themselves.
const SECTION := "text"
const AUTO_KEY := "auto_advance"

## "Tekst loopt vanzelf door": lines move on after their reading time.
var auto := false

## The lines still to show: [{who, text}]; the first is on screen.
var queue: Array[Dictionary] = []
var _left := 0.0
var _hint_left := 0.0
## The lines already moved past, oldest first (at most HISTORY).
var _history: Array[Dictionary] = []
var _shown_chars := 0.0
## Seconds Spatie has been held (-1: not held, or this hold already skipped).
var _held := -1.0
var _skip_hint: Label
var _subtitle: PanelContainer
var _who: Label
var _text: Label
var _choices: HBoxContainer
var _hint: Label
var _paper: PanelContainer
var _paper_box: VBoxContainer
var _phone: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.HUD_BAR, 0.82)
	style.set_corner_radius_all(14)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	_subtitle.add_theme_stylebox_override("panel", style)
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_subtitle.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_subtitle.offset_bottom = -22
	_subtitle.custom_minimum_size.x = 900
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_subtitle.add_child(box)
	_who = UiPanel.label("", UiTheme.SMALL, Palette.VOLTANA_GREEN)
	box.add_child(_who)
	_text = UiPanel.paragraph("", Color.WHITE, 22)
	_text.custom_minimum_size.x = 850
	box.add_child(_text)
	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", 16)
	box.add_child(_choices)
	_subtitle.visible = false

	_skip_hint = UiPanel.label("", 15, Color(1, 1, 1, 0.6))
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.visible = false
	box.add_child(_skip_hint)

	_hint = UiPanel.label("", 17, Color(1, 1, 1, 0.85))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_bottom = -250
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hint.visible = false
	add_child(_hint)

	_paper = PanelContainer.new()
	_paper.set_anchors_preset(Control.PRESET_CENTER)
	_paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_paper.grow_vertical = Control.GROW_DIRECTION_BOTH
	_paper.visible = false
	add_child(_paper)
	_paper_box = VBoxContainer.new()
	_paper_box.add_theme_constant_override("separation", 10)
	_paper.add_child(_paper_box)

	_phone = VBoxContainer.new()
	_phone.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_phone.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_phone.offset_top = 70
	_phone.offset_right = -24
	_phone.custom_minimum_size.x = 420
	_phone.add_theme_constant_override("separation", 8)
	_phone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_phone)


## Queue lines ({who, text}) after any still showing.
func say(lines: Array[Dictionary]) -> void:
	var was_idle := queue.is_empty()
	queue.append_array(lines)
	if was_idle:
		_show_first()


## Whether a line is on screen or waiting.
func speaking() -> bool:
	return not queue.is_empty()


## The line on screen now ({} for none).
func current() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


## Whether the line on screen is shown whole (no line: true).
func revealed() -> bool:
	return queue.is_empty() or _shown_chars >= _text.text.length()


## Whether the scene holds the player: a line (not an aside), a choice or a paper is up.
func holds() -> bool:
	return paper_up() or asking() or (speaking() and not queue[0].get("aside", false))


## Spatie, Enter or a click: put the paper away, show the whole line, or go on.
func press() -> void:
	if paper_up():
		close_paper()
	elif not revealed():
		_reveal(_text.text.length())
	else:
		next()


## Move on to the next line now.
func next() -> void:
	if queue.is_empty() or asking():
		return
	_history.append(queue.pop_front())
	if _history.size() > HISTORY:
		_history.pop_front()
	_show_first()


## ← or Backspace: the line before this one again, shown whole (none while a choice waits).
func back() -> void:
	if _history.is_empty() or asking() or paper_up():
		return
	queue.push_front(_history.pop_back())
	_show_first()
	_reveal(_text.text.length())


## Show every queued line at once (tests, a skip).
func finish() -> void:
	while not queue.is_empty() and not asking():
		next()


## Drop every line, the choice and the paper without a word (a skipped scene).
func clear() -> void:
	queue.clear()
	UiPanel.clear(_choices)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.visible = false
	_paper.visible = false
	_hint.visible = false


## Spatie down (true) or up: held for HOLD_SKIP_S it asks to skip.
func hold_space(on: bool) -> void:
	_held = 0.0 if on else -1.0


## "Houd spatie ingedrukt om over te slaan", small under the line (the first scene).
func skip_hint(on: bool) -> void:
	_skip_hint.text = tr(SKIP_HINT) if on else ""
	_skip_hint.visible = on


## The setting "Tekst loopt vanzelf door" (`path`: user://settings.cfg; tests point it elsewhere).
static func auto_setting(path: String = Settings.PATH) -> bool:
	return Settings.get_bool(SECTION, AUTO_KEY, false, path)


## The settings' switch for it (the title menu's Instellingen, the pause menu).
static func auto_toggle(path: String = Settings.PATH) -> CheckBox:
	var box := CheckBox.new()
	box.text = AUTO_LABEL   # a Button translates its own text
	box.button_pressed = auto_setting(path)
	box.toggled.connect(func(on: bool) -> void:
		var error := set_auto_setting(on, path)
		if not error.is_empty():
			push_warning(error))
	return box


## "" or what went wrong.
static func set_auto_setting(on: bool, path: String = Settings.PATH) -> String:
	return Settings.set_value(SECTION, AUTO_KEY, on, path)


## Two or more answers under the line on screen; the scene waits for one.
func ask(who: String, text: String, options: Array[String]) -> void:
	queue = [{"who": who, "text": text}]
	_show_first()
	UiPanel.clear(_choices)
	for i in options.size():
		var b := UiPanel.button(options[i], pick.bind(i))
		b.add_theme_font_size_override("font_size", 19)
		_choices.add_child(b)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_STOP


func asking() -> bool:
	return not _choices.get_children().is_empty()


## Choose answer `index` of ask().
func pick(index: int) -> void:
	if not asking():
		return
	UiPanel.clear(_choices)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue.clear()
	_show_first()
	chosen.emit(index)


## A control hint, small, for a few seconds (once: the caller decides).
func hint(text: String, seconds := HINT_SECONDS) -> void:
	_hint.text = text
	_hint.visible = true
	_hint_left = seconds


func hint_text() -> String:
	return _hint.text if _hint.visible else ""


## Put the hint away (the player did what it says).
func clear_hint() -> void:
	_hint.visible = false


## A paper held up to the camera (the badge, the letter): `content` is filled
## by the caller; Verder puts it away.
func paper(fill: Color, content: Array[Control]) -> void:
	_paper.add_theme_stylebox_override("panel", UiTheme.card(fill))
	UiPanel.clear(_paper_box)
	for c in content:
		_paper_box.add_child(c)
	var next_button := UiPanel.button(tr(NEXT), close_paper)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_paper_box.add_child(next_button)
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.visible = true


func paper_up() -> bool:
	return _paper.visible


func close_paper() -> void:
	if not _paper.visible:
		return
	_paper.visible = false
	paper_closed.emit()


## A notification on the phone (from, at, text); it fades by itself.
func phone(from: String, at: String, text: String) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.13, 0.92)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("left", PHONE_SECONDS)
	var box := VBoxContainer.new()
	card.add_child(box)
	box.add_child(UiPanel.label("%s  ·  %s" % [from, at], 15, Color(1, 1, 1, 0.6)))
	box.add_child(UiPanel.paragraph(text, Color.WHITE, 18))
	_phone.add_child(card)


## The phone's notifications on screen, as text.
func phone_texts() -> Array[String]:
	var out: Array[String] = []
	for card in _phone.get_children():
		var parts: PackedStringArray = []
		for l: Label in card.get_child(0).get_children():
			parts.append(l.text)
		out.append("\n".join(parts))
	return out


## Every text on screen (tests).
func texts() -> Array[String]:
	var out: Array[String] = []
	for n in find_children("*", "Label", true, false):
		if (n as Label).is_visible_in_tree() or not is_inside_tree():
			out.append((n as Label).text)
	return out


func step(dt: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if holds() and not asking() else Control.MOUSE_FILTER_IGNORE
	if not queue.is_empty():
		_reveal(_shown_chars + REVEAL_CPS * dt)
		if not asking() and revealed() and (auto or queue[0].get("aside", false)):
			_left -= dt
			if _left <= 0.0:
				next()
	if _held >= 0.0:
		_held += dt
		if _held >= HOLD_SKIP_S:
			_held = -1.0
			skip_requested.emit()
	if _hint.visible:
		_hint_left -= dt
		if _hint_left <= 0.0:
			_hint.visible = false
	for card in _phone.get_children():
		var left: float = card.get_meta("left") - dt
		card.set_meta("left", left)
		if left <= 0.0:
			_phone.remove_child(card)
			card.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	if key.physical_keycode == KEY_SPACE:
		hold_space(key.pressed)
	if not key.pressed:
		return
	match key.physical_keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if not holds():
				return
			press()
		KEY_LEFT, KEY_BACKSPACE:   # also between lines: the last ones again
			if _history.is_empty() or asking() or paper_up():
				return
			back()
		_:
			return
	get_viewport().set_input_as_handled()


## A left click while the scene holds: as Spatie (the choice's and the paper's own buttons come first).
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and holds() and not asking():
		press()
		accept_event()


static func read_seconds(text: String) -> float:
	return clampf(READ_MIN + READ_PER_CHAR * text.length(), READ_MIN, READ_MAX)


func _show_first() -> void:
	if queue.is_empty():
		_subtitle.visible = false
		lines_done.emit()
		return
	var line := queue[0]
	_who.text = str(line.get("who", ""))
	_who.visible = not _who.text.is_empty()
	_text.text = str(line["text"])
	_subtitle.visible = true
	_left = read_seconds(_text.text)
	_reveal(0.0)


func _reveal(chars: float) -> void:
	_shown_chars = minf(chars, _text.text.length())
	_text.visible_characters = int(_shown_chars) if _shown_chars < _text.text.length() else -1
