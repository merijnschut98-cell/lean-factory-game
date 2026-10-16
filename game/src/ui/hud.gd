class_name Hud
extends Control
## The heads-up display: a top bar (day and time, budget with the savings of
## held fixes and, in debt, the floor; XP and belt, the
## region's setback while it stands still, the active mission), the
## interaction prompt, the controls,
## short messages (toasts, bottom right) when something happens, and cards
## (top right: a training day's glossary, the coach's debrief) that stay a
## while longer. It is drawn over the panels; toasts and cards hide while one
## is open, and a card's time only runs while it shows.

const TOAST_SECONDS := 7.0
const MAX_TOASTS := 4
const CARD_SECONDS := 25.0
const MAX_CARDS := 3

var session: GameSession
var clock_label: Label
var budget_label: Label
var xp_label: Label
## The stagnation drift, once the region slides back (hidden before).
var drift_label: Label
var mission_label: Label
var prompt_label: Label
var _toasts: VBoxContainer
var _cards: VBoxContainer


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
	mission_label = _bar_label("")
	mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mission_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for l in [clock_label, budget_label, xp_label, drift_label, mission_label]:
		row.add_child(l)


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
	prompt_label.offset_bottom = -150
	prompt_label.visible = false
	add_child(prompt_label)

	var help := Label.new()
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

	_cards = VBoxContainer.new()
	_cards.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_cards.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_cards.offset_top = 64
	_cards.offset_right = -20
	_cards.custom_minimum_size.x = 460
	_cards.add_theme_constant_override("separation", 10)
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cards)


func refresh() -> void:
	clock_label.text = session.clock_text()
	budget_label.text = UiText.budget_line(session.budget(), session.region.weekly_savings())
	budget_label.add_theme_color_override("font_color", Palette.SAFETY_ORANGE if session.budget() < 0 else Color.WHITE)
	xp_label.text = "%d XP  ·  %s" % [session.xp(), UiText.belt(session.belt())]
	var drift := roundi(session.drift()["level"] * 100.0)
	drift_label.visible = drift > 0
	drift_label.text = "Achteruitgang %d%%" % drift
	mission_label.text = mission_text()


func controls_text() -> String:
	return "WASD/klik lopen   ·   Z/C draaien   ·   wiel zoomen   ·   E gebruiken   ·   J aanwijzingen   ·   M kaart   ·   K begrippen"


## The active missions in the top bar: the main one first.
func mission_text() -> String:
	var active := session.active_missions()
	if active.is_empty():
		return "Geen missie: ga naar het missiebord"
	return "Missie: " + ", ".join(active.map(func(m: MissionDef) -> String:
		return UiText.mission_title(m, session)))


## The toasts and cards; hidden while a panel is open.
func show_overlay(on: bool) -> void:
	_toasts.visible = on
	_cards.visible = on


## A card: a heading, its lines and a muted footer. The oldest goes when
## there are too many.
func show_card(heading: String, lines: Array[String], footer: String = "") -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.card(Color.WHITE))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("left", CARD_SECONDS)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(UiPanel.label(heading, UiTheme.SMALL, Palette.VOLTANA_BLUE))
	for line in lines:
		box.add_child(UiPanel.paragraph(line, Palette.INK, 17))
	if not footer.is_empty():
		box.add_child(UiPanel.label(footer, 15, Palette.MUTED))
	_cards.add_child(card)
	while _cards.get_child_count() > MAX_CARDS:
		var oldest := _cards.get_child(0)
		_cards.remove_child(oldest)
		oldest.queue_free()


## Each card on screen as one text (heading, lines, footer), oldest first.
func card_texts() -> Array[String]:
	var out: Array[String] = []
	for card in _cards.get_children():
		var texts: PackedStringArray = []
		for l: Label in card.get_child(0).get_children():
			texts.append(l.text)
		out.append("\n".join(texts))
	return out


func _process(delta: float) -> void:
	if not _cards.visible:
		return
	for card in _cards.get_children():
		var left: float = card.get_meta("left") - delta
		card.set_meta("left", left)
		if left <= 0.0:
			_cards.remove_child(card)
			card.queue_free()


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


func _bar_label(text: String, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 20)
	return l
