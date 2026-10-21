class_name Phone
extends UiPanel
## The player's phone, the hub (design 2026-10-21 §1.8, Merijn: "the phone is
## the hub"): what was a panel over the world is an app on it. Tab (the
## remappable action ACTION) raises it in the character's hand, portrait, the
## world blurred and dimmed behind it and its input paused (GameUI counts it as
## an open panel); J, M and K raise it on Notities, Kaart and Begrippen; Esc,
## Tab or a click beside it lowers it. The home screen shows the time, the
## date and the apps that have had their moment (Opening.hud), each with a
## badge for what is new; a new message buzzes it (`buzz`, the sound layer's
## cue) and the HUD's bar shows the count.

## Something new arrived (a message, a concept): the sound layer buzzes, the
## HUD's phone shakes.
signal buzz
## An app was opened and what was new in it is seen (the HUD's count follows).
signal badges_changed

const ACTION := "phone"
const HOME := ""
const MESSAGES := "messages"
const MISSIONS := "missions"
const NOTES := "notes"
const MAP := "map"
const PEOPLE := "people"
const CODEX := "codex"
const SETTINGS := "settings"
## The home screen's order.
const APPS: Array[String] = [MESSAGES, MISSIONS, NOTES, MAP, PEOPLE, CODEX, SETTINGS]
const NAMES := {MESSAGES: "Berichten", MISSIONS: "Opdrachten", NOTES: "Notities", MAP: "Kaart", PEOPLE: "Wie is wie",
	CODEX: "Begrippen", SETTINGS: "Instellingen"}
## The Opening.hud element each app waits for (Instellingen comes with the phone).
const REVEAL := {MESSAGES: "messages", MISSIONS: "missions", NOTES: "notes", MAP: "map", PEOPLE: "people",
	CODEX: "codex", SETTINGS: "phone"}
const BACK := "Terug"
const HOME_TITLE := "Voltana"

## The phone held upright, and sideways (the map), in px at 1600x900.
const PORTRAIT := Vector2(470, 800)
const LANDSCAPE := Vector2(980, 600)
## Its bezel (as the creator's phone, B1).
const BEZEL := Color("#121316")
const BEZEL_PX := 14
const RADIUS := 38
const RAISE_S := 0.16
const BACKDROP := "res://src/ui/phone/phone_backdrop.gdshader"
const SKIN := Color(0.86, 0.67, 0.54)

## The app on screen, HOME for the home screen.
var current := HOME
## Which apps have had their moment (Opening.hud); every app when empty.
var revealed: Dictionary = {}
var back_button: Button
## The player's skin (the creator's look), for the hand holding the phone.
var skin := SKIN

var _apps: Dictionary[String, PhoneApp] = {}
var _icons: Dictionary[String, PhoneIcon] = {}
## What new has been announced with a buzz ("<app>:<id>").
var _announced: Dictionary[String, bool] = {}
var _stage: Control
var _frame: PanelContainer
var _home: Control
## The screen's area under the app bar: the home screen or one app.
var _content: MarginContainer
## The screen's colour: the wallpaper's blue at home, paper in an app.
var _paper: StyleBoxFlat
var _signal: Label
var _app_bar: HBoxContainer
var _title: Label
var _time: Label
var _home_time: Label
var _home_date: Label
var _hand_back: Control
var _thumb: Control


func _init() -> void:
	super(NAMES[MESSAGES])
	ensure_action()
	title_label.get_parent().visible = false
	rule.visible = false
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_stage)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.08, 0.16, 0.6)
	var shader: Shader = load(BACKDROP)
	if shader != null:
		backdrop.material = ShaderMaterial.new()
		backdrop.material.shader = shader
	backdrop.gui_input.connect(func(e: InputEvent) -> void:   # a click beside the phone lowers it
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			close_requested.emit())
	_stage.add_child(backdrop)
	_hand_back = _layer(_draw_fingers)
	_frame = _build_frame()
	_stage.add_child(_frame)
	_thumb = _layer(_draw_thumb)
	_frame.resized.connect(func() -> void:
		_hand_back.queue_redraw()
		_thumb.queue_redraw())
	for id: String in APPS:
		_add_app(id, _make(id))
	visibility_changed.connect(func() -> void:
		if not visible and current != HOME:
			_apps[current].closed())


## The phone key lowers the phone before the GUI takes Tab as focus moving
## (a button on the phone may hold the focus).
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(ACTION) and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_requested.emit()


## The phone fills the screen (its backdrop over the world); the frame sits
## in the middle, a little low, as held.
func _place() -> void:
	if not is_inside_tree():
		return
	var area := get_parent_area_size()
	position = Vector2.ZERO
	size = area
	_lay_out(area)


func _lay_out(area: Vector2) -> void:
	var landscape := current != HOME and _apps[current].landscape
	var frame_size := LANDSCAPE if landscape else PORTRAIT
	_frame.custom_minimum_size = frame_size
	_frame.size = frame_size
	var y := area.y - frame_size.y - (area.y - frame_size.y) * (0.45 if landscape else 0.2)
	_frame.position = Vector2(floorf((area.x - frame_size.x) / 2.0), floorf(y))


func _make(id: String) -> PhoneApp:
	match id:
		MESSAGES:
			return PhoneMessages.new()
		MISSIONS:
			return MissionsApp.new()
		NOTES:
			return NotesApp.new()
		MAP:
			return MapApp.new()
		PEOPLE:
			return PeopleApp.new()
		CODEX:
			return CodexApp.new()
	return SettingsApp.new()


## The apps' session and session layer (GameUI's).
func setup(of_session: GameSession, of_layer: SessionLayer) -> void:
	session = of_session
	for a: PhoneApp in _apps.values():
		a.session = of_session
		a.layer = of_layer
		if a.carried != null:
			a.carried.session = of_session


func app(id: String) -> PhoneApp:
	return _apps.get(id)


func icon(id: String) -> PhoneIcon:
	return _icons.get(id)


## Whether `id` (HOME: the phone itself) may open now.
func may_open(id: String) -> bool:
	if not revealed.get("phone", true):
		return false
	return id == HOME or revealed.get(REVEAL[id], true)


## Open app `id` (a tap on its icon, or a key): it fills the screen and what
## was new in it is now seen.
func open_app(id: String) -> void:
	if id == HOME:
		home()
		return
	if not _apps.has(id) or not may_open(id):
		return
	if current != HOME and current != id:
		_apps[current].closed()
	current = id
	var a := _apps[id]
	a.refresh()
	a.opened()
	_show_current()
	badges_changed.emit()


func home() -> void:
	if current != HOME:
		_apps[current].closed()
	current = HOME
	_show_current()


## The badge on app `id`: how many things in it are new.
func badge(id: String) -> int:
	return _apps[id].unread().size() if _apps.has(id) and may_open(id) else 0


## Everything new on the phone, over all apps.
func unread_count() -> int:
	var n := 0
	for id: String in APPS:
		n += badge(id)
	return n


## Mark what is new and not yet announced as announced; true when there was
## any (GameUI buzzes the phone then).
func announce() -> bool:
	var fresh := false
	for id: String in APPS:
		if not may_open(id):
			continue
		for item in _apps[id].unread():
			var key := "%s:%s" % [id, item]
			if not _announced.has(key):
				_announced[key] = true
				fresh = true
	return fresh


func refresh() -> void:
	for id: String in APPS:
		_icons[id].visible = may_open(id)
	if current != HOME and not may_open(current):
		current = HOME
	if current != HOME:
		_apps[current].refresh()
	_show_current()


func _show_current() -> void:
	var at_home := current == HOME
	_home.visible = at_home
	_paper.bg_color = Palette.VOLTANA_BLUE if at_home else Palette.PAPER
	for l: Label in [_time, _signal]:
		l.add_theme_color_override("font_color", Color.WHITE if at_home else Palette.INK)
	_app_bar.visible = current != HOME
	for id: String in _apps:
		_apps[id].visible = id == current
	var own := _apps[current].title() if not at_home else ""   # a carried panel's own (the lift's)
	_title.text = own if not own.is_empty() else tr(NAMES.get(current, HOME_TITLE))
	if session != null:
		var minute := session.minute_of_day()
		_time.text = "%02d:%02d" % [minute / 60, minute % 60]
		_home_time.text = _time.text
		_home_date.text = session.day_text(session.region.net.time)
	for id: String in APPS:
		_icons[id].badge = badge(id)
	if is_inside_tree():
		_lay_out(get_parent_area_size())
		_hand_back.queue_redraw()
		_thumb.queue_redraw()


## Raised: it slides up from the hand, quickly.
func slide_in() -> void:
	if not is_inside_tree():
		return
	_lay_out(get_parent_area_size())
	var to := _frame.position
	_frame.position.y += 120
	modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(_frame, "position", to, RAISE_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, RAISE_S)


## The remappable phone key: Tab, unless the project or the player mapped it.
static func ensure_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION)
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	InputMap.action_add_event(ACTION, tab)


## The phone key's name for the HUD ("Tab").
static func key_text() -> String:
	ensure_action()
	for e in InputMap.action_get_events(ACTION):
		if e is InputEventKey:
			return OS.get_keycode_string((e as InputEventKey).physical_keycode)
	return ""


# ── Building ────────────────────────────────────────────────────────────────

func _build_frame() -> PanelContainer:
	var frame := PanelContainer.new()
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = BEZEL
	bezel.set_corner_radius_all(RADIUS)
	bezel.set_content_margin_all(BEZEL_PX)
	bezel.shadow_color = Color(0, 0, 0, 0.45)
	bezel.shadow_size = 24
	frame.add_theme_stylebox_override("panel", bezel)
	var screen := PanelContainer.new()
	_paper = StyleBoxFlat.new()
	_paper.bg_color = Palette.PAPER
	_paper.set_corner_radius_all(RADIUS - BEZEL_PX)
	_paper.content_margin_bottom = 12
	screen.add_theme_stylebox_override("panel", _paper)
	screen.clip_contents = true
	frame.add_child(screen)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	screen.add_child(column)
	column.add_child(_status_bar())
	_app_bar = HBoxContainer.new()
	_app_bar.add_theme_constant_override("separation", 6)
	var bar_box := MarginContainer.new()
	for side in ["left", "right"]:
		bar_box.add_theme_constant_override("margin_" + side, 12)
	bar_box.add_theme_constant_override("margin_bottom", 8)
	bar_box.add_child(_app_bar)
	column.add_child(bar_box)
	_app_bar.visibility_changed.connect(func() -> void: bar_box.visible = _app_bar.visible)
	back_button = UiPanel.button("‹  " + tr(BACK), home)
	back_button.flat = true
	back_button.focus_mode = Control.FOCUS_NONE
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		back_button.add_theme_color_override(state, Palette.VOLTANA_BLUE)
	back_button.add_theme_font_size_override("font_size", UiTheme.SMALL)
	_app_bar.add_child(back_button)
	_title = UiPanel.label("", UiTheme.FONT_SIZE, Palette.INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_title.clip_text = true
	_app_bar.add_child(_title)
	_content = MarginContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		_content.add_theme_constant_override("margin_" + side, 14)
	column.add_child(_content)
	_home = _build_home()   # on the screen's own colour: the wallpaper
	_content.add_child(_home)
	return frame


func _status_bar() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	margin.add_child(row)
	_time = UiPanel.label("", 15, Palette.INK)
	_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_time)
	_signal = UiPanel.label("4G   86%", 14, Palette.MUTED)
	row.add_child(_signal)
	return margin


## The home screen: the time large, the date, then the apps three to a row on
## a Voltana-blue wallpaper.
func _build_home() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_home_time = UiPanel.label("", 64, Color.WHITE)
	_home_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_home_time)
	_home_date = UiPanel.label("", UiTheme.SMALL, Color(1, 1, 1, 0.75))
	_home_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_home_date)
	var gap := Control.new()
	gap.custom_minimum_size.y = 28
	column.add_child(gap)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	for id: String in APPS:
		var i := PhoneIcon.new(id, tr(NAMES[id]))
		i.pressed.connect(open_app.bind(id))
		_icons[id] = i
		grid.add_child(i)
	var brand := UiPanel.label(tr(HOME_TITLE), 15, Palette.VOLTANA_GREEN)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	brand.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(brand)
	return column


func _add_app(id: String, a: PhoneApp) -> void:
	_apps[id] = a
	a.acted.connect(acted.emit)
	_content.add_child(a)


func _layer(draw: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(draw.bind(c))
	_stage.add_child(c)
	return c


# ── The hand ────────────────────────────────────────────────────────────────

## Behind the phone: the palm under it and the fingers round its left edge
## (sideways: the palms under both ends).
func _draw_fingers(c: Control) -> void:
	var r := _frame.get_rect()
	var shade := skin.darkened(0.22)
	if r.size.x > r.size.y:   # both hands grip the ends from behind
		for x: float in [r.position.x + 20, r.end.x - 20]:
			_blob(c, Vector2(x, r.get_center().y + r.size.y * 0.22), Vector2(70, r.size.y * 0.32), skin, shade)
		return
	_blob(c, Vector2(r.end.x - r.size.x * 0.12, r.end.y + r.size.y * 0.03), Vector2(r.size.x * 0.42, r.size.y * 0.1),
		skin, shade)
	for i in 3:
		var y := r.end.y - r.size.y * (0.36 - i * 0.085)
		_capsule(c, Vector2(r.position.x + 18, y), Vector2(r.position.x - 16, y + 6), 30.0, skin, shade)


## Over the phone: the thumb along its right edge (sideways: both thumbs).
func _draw_thumb(c: Control) -> void:
	var r := _frame.get_rect()
	var shade := skin.darkened(0.22)
	if r.size.x > r.size.y:   # a thumb on each end of the screen
		_capsule(c, Vector2(r.position.x - 40, r.end.y - 30), Vector2(r.position.x + 6, r.end.y - 120), 34.0, skin, shade)
		_capsule(c, Vector2(r.end.x + 40, r.end.y - 30), Vector2(r.end.x - 6, r.end.y - 120), 34.0, skin, shade)
		return
	_capsule(c, Vector2(r.end.x + 22, r.end.y - r.size.y * 0.02), Vector2(r.end.x - 8, r.end.y - r.size.y * 0.24), 36.0,
		skin, shade)


static func _capsule(c: Control, a: Vector2, b: Vector2, width: float, fill: Color, edge: Color) -> void:
	for pass_color: Array in [[edge, width + 3.0], [fill, width]]:
		c.draw_line(a, b, pass_color[0], pass_color[1])
		c.draw_circle(a, pass_color[1] / 2.0, pass_color[0])
		c.draw_circle(b, pass_color[1] / 2.0, pass_color[0])


static func _blob(c: Control, centre: Vector2, radii: Vector2, fill: Color, edge: Color) -> void:
	for pass_color: Array in [[edge, 3.0], [fill, 0.0]]:
		var pts := PackedVector2Array()
		for i in 32:
			var a := i * TAU / 32.0
			pts.append(centre + Vector2(cos(a) * (radii.x + pass_color[1]), sin(a) * (radii.y + pass_color[1])))
		c.draw_colored_polygon(pts, pass_color[0])
