class_name Hud
extends Control
## The heads-up display: a top bar (day and time, budget, XP and belt, the
## active mission), the crosshair, the interaction prompt, the controls and
## short messages (toasts, bottom right) when something happens. It is drawn
## over the panels.

const TOAST_SECONDS := 7.0
const MAX_TOASTS := 4

var session: GameSession
var clock_label: Label
var budget_label: Label
var xp_label: Label
var mission_label: Label
var prompt_label: Label
## "Klik om verder te lopen", while Esc has freed the mouse.
var mouse_hint: Label
var _toasts: VBoxContainer
var _crosshair: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_bar()
	_build_centre()


func _build_bar() -> void:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.HUD_BAR
	style.border_color = Palette.VOLTANA_GREEN
	style.border_width_bottom = 3
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 34)
	bar.add_child(row)
	row.add_child(_bar_label("VOLTANA", Palette.VOLTANA_GREEN))
	clock_label = _bar_label("")
	budget_label = _bar_label("")
	xp_label = _bar_label("")
	mission_label = _bar_label("")
	mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mission_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for l in [clock_label, budget_label, xp_label, mission_label]:
		row.add_child(l)


func _build_centre() -> void:
	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.85)
	_crosshair.size = Vector2(6, 6)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = -_crosshair.size / 2.0
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)

	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 26)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Palette.HUD_BAR
	pill.set_corner_radius_all(22)
	pill.border_color = Palette.VOLTANA_GREEN
	pill.set_border_width_all(2)
	pill.content_margin_left = 26
	pill.content_margin_right = 26
	pill.content_margin_top = 8
	pill.content_margin_bottom = 8
	prompt_label.add_theme_stylebox_override("normal", pill)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_label.offset_bottom = -150
	prompt_label.visible = false
	add_child(prompt_label)

	mouse_hint = prompt_label.duplicate()
	mouse_hint.text = "Klik om verder te lopen"
	mouse_hint.add_theme_font_size_override("font_size", 22)
	mouse_hint.set_anchors_preset(Control.PRESET_CENTER)
	mouse_hint.grow_vertical = Control.GROW_DIRECTION_END
	mouse_hint.offset_left = 0
	mouse_hint.offset_right = 0
	mouse_hint.offset_top = 40
	mouse_hint.offset_bottom = 40
	mouse_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mouse_hint)

	var help := Label.new()
	help.text = "WASD lopen   ·   muis kijken   ·   E gebruiken   ·   J aanwijzingen   ·   Esc muis los"
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	help.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.offset_left = 20
	help.offset_bottom = -14
	add_child(help)

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toasts.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toasts.offset_bottom = -14
	_toasts.offset_right = -20
	_toasts.custom_minimum_size.x = 520
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)


func refresh() -> void:
	clock_label.text = session.clock_text()
	budget_label.text = "Budget " + UiText.money(session.budget())
	xp_label.text = "%d XP  ·  %s" % [session.xp(), UiText.belt(session.belt())]
	mission_label.text = mission_text()


## The active missions in the top bar: the main one first.
func mission_text() -> String:
	var active := session.active_missions()
	if active.is_empty():
		return "Geen missie: ga naar het missiebord"
	return "Missie: " + ", ".join(active.map(func(m: MissionDef) -> String: return m.name))


## The crosshair and the toasts; hidden while a panel is open.
func show_overlay(on: bool) -> void:
	_crosshair.visible = on
	_toasts.visible = on


## "" hides the prompt.
func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()


func toast(text: String) -> void:
	var l := UiPanel.paragraph(text, Color.WHITE, 19)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.HUD_BAR
	style.border_color = Palette.VOLTANA_GREEN
	style.border_width_left = 5
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	l.add_theme_stylebox_override("normal", style)
	_toasts.add_child(l)
	while _toasts.get_child_count() > MAX_TOASTS:
		var oldest := _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()
	if is_inside_tree():
		get_tree().create_timer(TOAST_SECONDS).timeout.connect(l.queue_free)


## The toasts on screen, oldest first.
func toast_texts() -> Array[String]:
	var out: Array[String] = []
	for l: Label in _toasts.get_children():
		out.append(l.text)
	return out


func show_mouse_hint(on: bool) -> void:
	mouse_hint.visible = on


func _bar_label(text: String, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 20)
	return l
