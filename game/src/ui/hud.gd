class_name Hud
extends Control
## The heads-up display: a top bar (day and time, budget with the savings of
## held fixes and, in debt, the floor; XP and belt, the
## region's setback while it stands still; at its right the phone, its key and
## what is new on it), under it top left the one objective line (Objective:
## the next step, never a mission title), the interaction prompt, the controls,
## and short messages (toasts, bottom right) when something happens. Whatever
## stays a while (Ruud's notes, a debrief, new concepts) is on the phone
## (Phone), never a card over the world. It is drawn over the panels; the
## toasts hide while one is open.

const TOAST_SECONDS := 7.0
const MAX_TOASTS := 4
const STOP_NOTE := "Nieuwe dag · goed moment om te stoppen (opgeslagen)"
## The bar's phone: its name, its key, and how much is new on it.
const PHONE := "Telefoon"
const PHONE_NEW := "%d nieuw"
## The phone wiggles this far (degrees) when it buzzes.
const SHAKE_DEGREES := 4.0

var session: GameSession
var clock_label: Label
var budget_label: Label
var xp_label: Label
## The stagnation drift, once the region slides back (hidden before).
var drift_label: Label
## The dagstart's quiet "good moment to stop" note (SessionLayer), beside the
## clock; hidden otherwise.
var stop_note: Label
## The objective line, top left under the bar (PLAN 2.13 C): one short line; none
## during a talk or while a scene's lines run.
var objective_label: Label
## The session layer (GameUI): the first day's beat, for the objective.
var layer: SessionLayer
var _objective := {}
var _objective_beat := ""
## The phone in the bar (Phone), from its moment on (Opening.hud "phone").
var phone_label: Label
var prompt_label: Label
## The controls line, bottom left (hidden while a panel is open).
var help_label: Label
var _toasts: VBoxContainer
## In a talk the bar shows only the date and time: no budget, XP or mission.
var _talking := false
## A panel is open over the world (show_overlay): the objective line steps aside, so it
## never covers the panel's title (a tall one reaches the top bar; PLAN 2.10 S3-D).
var _panel_open := false
## Which element may show (Opening.hud: the first day reveals them one at a
## time); everything when not set.
var revealed: Dictionary = {}


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
	drift_label = _bar_label("", Palette.SAFETY_ORANGE)
	drift_label.visible = false
	stop_note = _bar_label(STOP_NOTE, Palette.VOLTANA_GREEN)
	stop_note.add_theme_font_size_override("font_size", 16)
	stop_note.visible = false
	for l in [clock_label, stop_note, budget_label, xp_label, drift_label]:
		row.add_child(l)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	phone_label = _bar_label("")
	phone_label.add_theme_font_size_override("font_size", 17)
	row.add_child(phone_label)
	phone_status(0)
	objective_label = _bar_label("")
	var line := StyleBoxFlat.new()
	line.bg_color = Color(Palette.HUD_BAR, 0.75)
	line.border_color = Palette.VOLTANA_GREEN
	line.border_width_left = 4
	line.set_corner_radius_all(6)
	line.content_margin_left = 14
	line.content_margin_right = 14
	line.content_margin_top = 5
	line.content_margin_bottom = 5
	objective_label.add_theme_stylebox_override("normal", line)
	objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_label.offset_left = 20
	objective_label.offset_top = 62
	objective_label.visible = false
	add_child(objective_label)


func _build_centre() -> void:
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
	prompt_label.offset_bottom = -170
	prompt_label.visible = false
	add_child(prompt_label)

	var help := Label.new()
	help_label = help
	help.text = controls_text()
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	help.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(Palette.HUD_BAR, 0.7)
	backdrop.set_corner_radius_all(14)
	backdrop.content_margin_left = 14
	backdrop.content_margin_right = 14
	backdrop.content_margin_top = 4
	backdrop.content_margin_bottom = 4
	help.add_theme_stylebox_override("normal", backdrop)
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
	budget_label.text = UiText.budget_line(session.budget(), session.region.weekly_savings())
	budget_label.add_theme_color_override("font_color", Palette.SAFETY_ORANGE if session.budget() < 0 else Color.WHITE)
	xp_label.text = "%d XP  ·  %s" % [session.xp(), UiText.belt(session.belt())]
	var drift := roundi(session.drift()["level"] * 100.0)
	drift_label.visible = drift > 0 and not _talking
	drift_label.text = "Achteruitgang %d%%" % drift
	_objective = Objective.of(session, layer)
	_objective_beat = layer.opening_beat if layer != null else ""
	objective_label.text = tr(str(_objective.get("text", "")))
	_apply_reveal()


## Show each element of the bar only once its moment has come (Opening.hud).
func reveal(shown: Dictionary) -> void:
	revealed = shown
	_apply_reveal()


func may_show(element: String) -> bool:
	return revealed.get(element, true)


func _apply_reveal() -> void:
	clock_label.visible = may_show("clock")
	budget_label.visible = may_show("budget") and not _talking
	xp_label.visible = may_show("xp") and not _talking
	objective_label.visible = _objective_shown()
	phone_label.visible = may_show("phone") and not _talking
	if not may_show("controls"):
		help_label.visible = false


func controls_text() -> String:
	return tr("WASD/klik lopen   ·   Shift rennen   ·   Z/C draaien   ·   wiel zoomen   ·   E gebruiken   ·   %s telefoon") \
		% Phone.key_text()


## The objective line shows from its moment (Opening.hud "mission"; the first day's
## walk behind Ruud before it), never in a talk, over a panel or while a scene speaks.
func _objective_shown() -> bool:
	return not objective_label.text.is_empty() and not _talking and not _panel_open and not _scene_running() \
		and (may_show("mission") or _objective.get("step") == "follow")


## A scene's lines, question or paper are up (SceneLines, a child of the HUD).
func _scene_running() -> bool:
	for child in get_children():
		if child is SceneLines and (child.speaking() or child.asking() or child.paper_up()):
			return true
	return false


## A talk is open (or over): only the date and time stay in the bar; the
## person, not the score, has the player's attention (dialog spec §11).
func set_talking(on: bool) -> void:
	_talking = on
	_apply_reveal()
	if on:
		drift_label.visible = false
		stop_note.visible = false
	elif session != null:
		refresh()


## The toasts, the controls line and the objective line; hidden while a panel is open.
func show_overlay(on: bool) -> void:
	_panel_open = not on
	help_label.visible = on and may_show("controls")
	_toasts.visible = on
	objective_label.visible = _objective_shown()


## The bar's phone: "Telefoon · Tab", and how much is new on it.
func phone_status(unread: int) -> void:
	var parts: PackedStringArray = [tr(PHONE), Phone.key_text()]
	if unread > 0:
		parts.append(tr(PHONE_NEW) % unread)
	phone_label.text = "  ·  ".join(parts)
	phone_label.add_theme_color_override("font_color", Palette.VOLTANA_GREEN if unread > 0 else Color(1, 1, 1, 0.8))


## Something new reached the phone: it wiggles in the bar (a turn about its
## middle, which the bar's layout leaves alone).
func buzz() -> void:
	if not is_inside_tree():
		return
	phone_label.pivot_offset = phone_label.size / 2.0
	var t := create_tween()
	for degrees: float in [SHAKE_DEGREES, -SHAKE_DEGREES, SHAKE_DEGREES * 0.5, 0.0]:
		t.tween_property(phone_label, "rotation_degrees", degrees, 0.06)


func _process(_delta: float) -> void:
	if session != null and layer != null and layer.opening_beat != _objective_beat:
		refresh()   # the first day moved on without an action (Opening)
	objective_label.visible = _objective_shown()


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


## Keep `px` free under the toasts (the minimap in the bottom-right corner): they stack above it.
func keep_clear_below_toasts(px: float) -> void:
	_toasts.offset_bottom = -14 - px


## The toasts on screen, oldest first.
func toast_texts() -> Array[String]:
	var out: Array[String] = []
	for l: Label in _toasts.get_children():
		out.append(l.text)
	return out


func _bar_label(text: String, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 20)
	return l
