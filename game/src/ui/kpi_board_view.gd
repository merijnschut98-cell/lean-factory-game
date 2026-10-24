class_name KpiBoardView
extends CanvasLayer
## The KPI board at the directie obeya on the 2e (PLAN 2.4c): you step up to the
## magnetic wall board and the camera moves in; this is the board itself, not a panel.
## Each team's column holds its KPI cards (content/kpis.yaml); a click puts a magnet on
## a card, two per team (a third takes the first one's place, a click on a magnet takes
## it off). [Ophangen] hangs the choice: the quarterly review runs
## (GameSession.kpi_review: the analysts reckon the quarter twice) and then only the
## chosen cards stay up, each with its real number from the region (KpiReading).
## Between reviews it shows the choice in force with its numbers. Ruud asks at the
## bottom, never tells. Nothing names a card's kind (leading, lagging, output): the
## player decides, the simulation judges.
##
## KpiBoardView.open(parent, session) shows it; `closed` gives the review's result,
## or {} when it closed without one. Esc or [Klaar] closes it; nothing is lost.

signal closed(result: Dictionary)

## REVIEW: the review is due, choose. RESULT: just hung. READ: between reviews.
enum Mode { REVIEW, RESULT, READ }

const LAYER := 20
## A team's colour of index card, column by column (an obeya board's own habit).
const CARD_COLOURS: Array[Color] = [Color("#fff3a8"), Color("#cfe6ff"), Color("#d6f5d0"), Color("#ffd9e2")]
const ENAMEL := Color("#f8f8f5")
const FRAME := Color("#b9bec5")
const MARKER_BLUE := Color("#1f4fa8")
const MARKER_RED := Color("#c0392b")
const MAGNET := Color("#d63a2f")
const MAGNET_RADIUS := 13.0
## The board leaves this share of the screen around it (x, y), so the room still shows
## and the HUD's bars above and below stay readable.
const MARGIN := Vector2(0.035, 0.065)
const TITLE := "Waar sturen de teams op?"
const THINKING := "De analisten rekenen het kwartaal door…"
const HINT := "Klik per team twee kaarten aan."

var mode := Mode.REVIEW
var session: GameSession
## Pool → the KPI ids with a magnet on them, in the order they were put there.
var picks: Dictionary = {}
var result: Dictionary = {}

var _marker: FontVariation
var _columns: Dictionary = {}  # pool → VBoxContainer of its cards
var _cards: Dictionary = {}  # "pool/kpi" → PanelContainer
var _ruud: RichTextLabel
var _when: Label
var _hint: Label
var _hang: Button
var _open := true


static func open(parent: Node, of_session: GameSession) -> KpiBoardView:
	var v := create(of_session)
	parent.add_child(v)
	return v


## The board (not yet in the tree), in REVIEW mode when the review is due.
static func create(of_session: GameSession) -> KpiBoardView:
	var v := KpiBoardView.new()
	v.layer = LAYER
	v.session = of_session
	var board := of_session.region.board
	v.mode = Mode.REVIEW if board.review_due(of_session.region.net.time) else Mode.READ
	for pool: String in v.pools():
		v.picks[pool] = Array(board.chosen.get(pool, PackedStringArray())) if v.mode == Mode.READ else []
	v._build()
	v._refresh()
	return v


## The teams on the board, in the menu's order.
func pools() -> Array[String]:
	var out: Array[String] = []
	out.assign(session.catalog.kpis.menus.keys())
	return out


## The KPI ids of the cards up in `pool`'s column now.
func cards_in(pool: String) -> Array[String]:
	var out: Array[String] = []
	for card: Control in _columns[pool].get_children():
		if card.visible:
			out.append(str(card.get_meta("kpi")))
	return out


## The number written on a card ("" while none is).
func number_on(pool: String, kpi_id: String) -> String:
	var number: Label = _cards[pool + "/" + kpi_id].get_meta("number")
	return number.text if number.visible else ""


func ruud_line() -> String:
	return _ruud.get_meta("line", "")


## A magnet on (or off) a card of `pool`.
func pick(pool: String, kpi_id: String) -> void:
	if mode != Mode.REVIEW or not picks.has(pool):
		return
	var chosen: Array = picks[pool]
	if chosen.has(kpi_id):
		chosen.erase(kpi_id)
	else:
		chosen.append(kpi_id)
		if chosen.size() > 2:
			chosen.pop_front()
	_refresh()


func can_hang() -> bool:
	return mode == Mode.REVIEW and picks.values().all(func(c: Array) -> bool: return c.size() == 2)


## Hang the choice: the review runs now (it takes the analysts a moment). The result,
## or {error} when it could not run (the board stays as it was).
func hang_now() -> Dictionary:
	if not can_hang():
		return {"error": "choose_two"}
	result = session.kpi_review(picks)
	if result.get("error", "") == "":
		mode = Mode.RESULT
	_refresh()
	return result


## [Klaar], Esc: back into the room with the result, or {} when nothing was hung.
func close() -> void:
	if not _open:
		return
	_open = false
	closed.emit(result if mode == Mode.RESULT else {})
	queue_free()


## A number as it is written on a card: "54 dagen", "87%", "28 per week", "15 min".
static func number_text(measure: String, value: float) -> String:
	match measure:
		"lead_days_p50", "wip_age":
			return "%d dagen" % roundi(value)
		"throughput_per_week", "done_per_week":
			return "%d per week" % roundi(value)
		"touch_minutes":
			return "%d min" % roundi(value)
	return "%d%%" % roundi(value * 100.0)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# ── Drawing ─────────────────────────────────────────────────────────────────

func _build() -> void:
	_marker = FontVariation.new()
	_marker.base_font = ThemeDB.fallback_font
	_marker.variation_embolden = 0.45   # a marker's line (no handwriting font in the project yet)
	var root := ColorRect.new()   # the room, a little dimmed behind the board you stand at
	root.name = "Board"
	root.color = Color(0.03, 0.06, 0.1, 0.3)
	root.theme = UiTheme.build()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var board := PanelContainer.new()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.anchor_left = MARGIN.x
	board.anchor_right = 1.0 - MARGIN.x
	board.anchor_top = MARGIN.y
	board.anchor_bottom = 1.0 - MARGIN.y
	board.add_theme_stylebox_override("panel", _enamel())
	root.add_child(board)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	board.add_child(page)
	var head := HBoxContainer.new()
	page.add_child(head)
	head.add_child(_written(TITLE, 34, MARKER_BLUE))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	_when = _written("", 22, MARKER_BLUE)
	head.add_child(_when)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	page.add_child(columns)
	var menus := session.catalog.kpis.menus
	for i in pools().size():
		var pool := pools()[i]
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 12)
		columns.add_child(column)
		column.add_child(_strip(session.region.net.pools[pool].name if session.region.net.pools.has(pool) else pool))
		var cards := VBoxContainer.new()
		cards.add_theme_constant_override("separation", 14)
		column.add_child(cards)
		_columns[pool] = cards
		for k: KpiDef in menus[pool]:
			var card := _card(pool, k, CARD_COLOURS[i % CARD_COLOURS.size()])
			cards.add_child(card)
			_cards[pool + "/" + k.id] = card
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 18)
	page.add_child(foot)
	_ruud = RichTextLabel.new()
	_ruud.bbcode_enabled = true
	_ruud.fit_content = true
	_ruud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ruud.add_theme_color_override("default_color", Palette.INK)
	_ruud.add_theme_font_size_override("normal_font_size", 21)
	_ruud.add_theme_font_size_override("bold_font_size", 23)
	foot.add_child(_ruud)
	var buttons := VBoxContainer.new()
	foot.add_child(buttons)
	_hint = _written(HINT, 17, Palette.MUTED)
	buttons.add_child(_hint)
	_hang = Button.new()
	_hang.text = "Ophangen"
	_hang.pressed.connect(_on_hang_pressed)
	buttons.add_child(_hang)
	var done := Button.new()
	done.text = "Klaar  (Esc)"
	done.pressed.connect(close)
	buttons.add_child(done)


func _refresh() -> void:
	var now := session.region.net.time
	_when.text = "Kwartaalreview, " + GameSession.day_text(now) if mode == Mode.REVIEW \
		else "Volgende review: " + TerugblikCard.day_name(session, session.region.board.next_review_at)
	for key: String in _cards:
		var card: PanelContainer = _cards[key]
		var pool := key.get_slice("/", 0)
		var picked: bool = (picks.get(pool, []) as Array).has(card.get_meta("kpi"))
		card.visible = mode == Mode.REVIEW or picked
		card.set_meta("picked", picked)
		card.queue_redraw()
		var number: Label = card.get_meta("number")
		number.visible = mode != Mode.REVIEW
		if number.visible:
			var k: KpiDef = card.get_meta("def")
			number.text = number_text(k.measure, KpiReading.value(session.region.net, k))
	_hint.visible = mode == Mode.REVIEW
	_hang.visible = mode == Mode.REVIEW
	_hang.disabled = not can_hang()
	var lines: Dictionary = session.catalog.kpis.review_lines
	match mode:
		Mode.REVIEW:
			_say(session.catalog.kpis.review_question)
		Mode.RESULT:
			_say(lines.get("paid" if result.get("paid", 0.0) > 0.0 else "flat", ""))
		Mode.READ:
			_say(lines.get("read", ""))


func _say(line: String) -> void:
	_ruud.set_meta("line", line)
	_ruud.text = "[b]%s[/b]   %s" % [session.speaker_name("ruud"), line]


func _on_hang_pressed() -> void:
	if not can_hang():
		return
	_hang.disabled = true
	_ruud.text = "[i]%s[/i]" % THINKING   # the review reckons the quarter twice: a moment
	await get_tree().process_frame
	await get_tree().process_frame
	hang_now()


func _card(pool: String, k: KpiDef, colour: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = k.id
	card.set_meta("kpi", k.id)
	card.set_meta("def", k)
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_content_margin_all(12)
	style.content_margin_top = 18
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(0, 74)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pick(pool, k.id))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(body)
	var name_label := _written(k.name, 21, Palette.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(name_label)
	var number := _written("", 30, MARKER_RED)
	body.add_child(number)
	card.set_meta("number", number)
	card.draw.connect(func() -> void:   # the magnet, when it holds the card
		if card.get_meta("picked", false):
			card.draw_circle(Vector2(card.size.x / 2.0 + 1.5, 6.5), MAGNET_RADIUS, Color(0, 0, 0, 0.3))
			card.draw_circle(Vector2(card.size.x / 2.0, 5.0), MAGNET_RADIUS, MAGNET)
			card.draw_circle(Vector2(card.size.x / 2.0 - 4.0, 1.0), MAGNET_RADIUS * 0.3, Color(1, 1, 1, 0.45)))
	return card


## A label in marker on the board.
func _written(text: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _marker)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A team's printed magnetic strip at the top of its column.
func _strip(text: String) -> PanelContainer:
	var strip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.VOLTANA_BLUE
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	strip.add_theme_stylebox_override("panel", style)
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_font_size_override("font_size", 19)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	strip.add_child(l)
	return strip


func _enamel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = ENAMEL
	s.border_color = FRAME
	s.set_border_width_all(16)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(40)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 18
	return s
