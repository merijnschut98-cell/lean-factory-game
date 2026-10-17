class_name SceneLines
extends Control
## What is said in a scripted scene (PLAN 2.7d, the first day): one line at a
## time at the bottom of the screen, as a film's subtitle, with who says it;
## a line stays as long as it takes to read and Spatie moves on. Beside it: a
## one-off control hint, a choice between two answers, a paper held up to the
## camera (the badge, the letter) and the phone's notifications. Nothing here
## blocks walking unless a paper or a choice is up.
##
## All time runs through step(dt) (its scene calls it each frame), so tests
## drive it frame by frame.

## Emitted when the lines queued with say() have all been shown.
signal lines_done
## Emitted with the index of the answer chosen in ask().
signal chosen(index: int)
## Emitted when the paper is put away (Verder or Spatie).
signal paper_closed

## A line stays at least this long, plus this per character, at most this long.
const READ_MIN := 2.4
const READ_PER_CHAR := 0.055
const READ_MAX := 7.0
const HINT_SECONDS := 5.0
const PHONE_SECONDS := 4.5
const NEXT := "Verder  (Spatie)"

## The lines still to show: [{who, text}]; the first is on screen.
var queue: Array[Dictionary] = []
var _left := 0.0
var _hint_left := 0.0
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


## Move on to the next line (Spatie).
func next() -> void:
	if queue.is_empty() or not _choices.get_children().is_empty():
		return
	queue.pop_front()
	_show_first()


## Show every queued line at once (tests, a skip).
func finish() -> void:
	while not queue.is_empty() and _choices.get_children().is_empty():
		next()


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
	if not queue.is_empty() and not asking():
		_left -= dt
		if _left <= 0.0:
			next()
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
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_SPACE:
		return
	if paper_up():
		close_paper()
	elif speaking():
		next()
	else:
		return
	get_viewport().set_input_as_handled()


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
