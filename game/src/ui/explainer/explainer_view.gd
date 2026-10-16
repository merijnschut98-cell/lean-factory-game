class_name ExplainerView
extends CanvasLayer
## "Hoe werkt het?": a sheet clipped to Ruud's whiteboard with the anatomy
## figure on it (PLAN 2.7c; spec 2026-10-16-explainer-spanning-stroom-
## weerstand §4 and §6.3). The garden skin first; Ruud's beats at the bottom;
## the valves and switches are parts of the drawing (click, or 1–3), the reel
## swaps from R8 on (click, or H); the cross-fade turns each garden part into
## its real counterpart where it stands. Readouts are Godot labels on the
## instruments' own LCD faces; the sums wait behind "Laat de rekensom zien"
## (R). Spatie moves on, Esc or [Klaar] closes at once.
##
## Open it with ExplainerView.open(parent, id, options); it emits `closed`
## when done and files the explainer in the ExplainerLog it was given.
## Options: log (ExplainerLog), codex (bool: no Ruud, the skin tab, the reel
## free), reduced_motion (bool), data_dir (String).
##
## All motion runs through step(dt) (called from _process), so tests drive
## it frame by frame; only the open and close fades are Tweens.

signal closed(explainer_id: String)

const SCENE := "res://src/ui/explainer/explainer_view.tscn"
## The cross-fade: one pair group after another (spec §6.3, estimates).
const GROUP_ORDER: Array[String] = ["source", "cable", "switches", "meter_flow", "meter_end", "loads", "reels"]
const XFADE_EACH_S := 0.3
const XFADE_STAGGER_S := 0.25
const TAG_S := 3.0
## A valve or a switch flips in 0.08 s; the reel swap takes 0.6 s.
const FLIP_S := 0.08
const SWAP_S := 0.6
const OPEN_S := 0.4
## The heat tint: a warm orange that deepens as the cable warms to 70 °C.
const WARM := Color("#ff7a1a")
const HEAT_SPAN_C := 50.0
const HEAT_MAX_ALPHA := 0.85
## The end gauge's zoomed band (spec §3.4, estimate) and the paddle wheel's
## turns per second per ampère (estimate: a calm spin at a kettle's 8,5 A).
const END_GAUGE_V := Vector2(210.0, 230.0)
const WHEEL_TURNS_PER_A := 0.12
## Labels on the drawing are laid out this many times larger and scaled
## down, so their glyphs stay sharp on the small faces.
const TEXT_SCALE := 6.0
const CARD_TOP := 64.0
const CARD_BOTTOM := 176.0
const CARD_SIDE := 28.0
const PAPER := Color("#fbfbfa")
const EDGE := Color("#8a8a8f")
const MUTED := Color("#6e6e72")

var def: ExplainerDef
var figure: ExplainerFigure
## Ruud's beats; null in the codex.
var beats: ExplainerBeats
var error := ""
var codex := false
var reduced_motion := false
var reveal_open := false
var klaar: Button
var reveal_corner: Button

var _log: ExplainerLog
var _open := true
var _on := {"lamp": false, "kettle": false, "heater": false}
var _haspel := 1
var _skin_target := 0.0  # 0 the garden, 1 the meterkast
var _mix := {}  # pair group → 0..1
var _xfade_t := INF
var _tag_t := INF
var _shows := {"readout": false, "reveal": false}
var _t_cable := OhmCable.ROOM_C
var _result := {}
var _wheel_turn := 0.0
var _led_t := 0.0
var _beat_seen := ""
var _pulse := {}  # layer id → seconds left
var _vis := {}  # layer id → 0..1, easing toward its state
var _sprites := {}
var _card: Panel
var _stage: Control
var _root: Node2D
var _overlay: Node2D
var _lcd_labels := {}
var _tag_labels: Array[Label] = []
var _hint: Label
var _readout: Label
var _ruud: RichTextLabel
var _keys: Label
var _strip: RichTextLabel
var _tabs: Array[Button] = []


## Make the view (not yet in the tree): check `error`.
static func create(explainer_id: String, options: Dictionary = {}) -> ExplainerView:
	var v: ExplainerView = load(SCENE).instantiate()
	v._setup(explainer_id, options)
	return v


## Open it over `parent` (the office, the codex): the entry point.
static func open(parent: Node, explainer_id: String, options: Dictionary = {}) -> ExplainerView:
	var v := create(explainer_id, options)
	parent.add_child(v)
	return v


func _setup(explainer_id: String, options: Dictionary) -> void:
	codex = options.get("codex", false)
	reduced_motion = options.get("reduced_motion", false)
	_log = options.get("log")
	var defs := ExplainerDef.load_all(options.get("data_dir", Catalog.DATA_DIR))
	def = defs["explainers"].get(explainer_id)
	if def == null:
		error = defs["error"] if not defs["error"].is_empty() else "unknown explainer " + explainer_id
		return
	figure = ExplainerFigure.load_from("res://assets/" + def.assets)
	if not figure.error.is_empty():
		error = figure.error
		return
	if _log != null:
		reveal_open = _log.reveal_open and codex
	for g in GROUP_ORDER:
		_mix[g] = 0.0
	if codex:
		_skin_target = 1.0
		for g in GROUP_ORDER:
			_mix[g] = 1.0
		_shows = {"readout": true, "reveal": true}
	else:
		beats = ExplainerBeats.new(def)
		beats.start()
	_build()
	_sync_state()
	_result = OhmCable.solve(_on, _cross_section())
	for entry: Dictionary in figure.layers:
		_vis[entry["id"]] = 1.0 if _shown_by_state(entry) else 0.0
	_refresh()


func _ready() -> void:
	if not error.is_empty():
		push_warning("explainer not opened: " + error)
		_finish()
		return
	get_viewport().size_changed.connect(_layout)
	_layout()
	if not reduced_motion:
		_card.modulate.a = 0.0
		create_tween().tween_property(_card, "modulate:a", 1.0, OPEN_S).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	if _open and error.is_empty():
		step(delta)


func is_open() -> bool:
	return _open


# ── Input ───────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if press(event.keycode):
		get_viewport().set_input_as_handled()


## One key: 1–3 the loads, H the reel, R the reveal, Spatie on, Esc closes.
## True when the view used it.
func press(key: Key) -> bool:
	match key:
		KEY_1, KEY_2, KEY_3:
			_toggle(ExplainerBeats.LOADS[key - KEY_1])
		KEY_H:
			_toggle("haspel")
		KEY_R:
			if reveal_corner.visible:
				_set_reveal(not reveal_open)
		KEY_SPACE:
			if beats != null:
				beats.next()
				_after_beats()
		KEY_ESCAPE:
			close()
		_:
			return false
	return true


func _on_stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_figure(_root.transform.affine_inverse() * event.position)


## A click at a point of the figure (viewBox units): the control under it.
## Neighbouring valves' rects overlap on screen; the nearest centre wins.
func click_figure(point: Vector2) -> void:
	var skin := "meterkast" if _skin_target >= 0.5 else "tuin"
	var best := ""
	var nearest := INF
	for hit: Dictionary in figure.hits:
		var r: Array = hit["rect"]
		var rect := Rect2(r[0], r[1], r[2], r[3])
		if hit["skin"] in [skin, "shared"] and rect.has_point(point) and rect.get_center().distance_to(point) < nearest:
			nearest = rect.get_center().distance_to(point)
			best = hit["control"]
	if not best.is_empty():
		_toggle(best)


func _toggle(control: String) -> void:
	if beats != null:
		if beats.toggle(control):
			_after_beats()
	elif control == "haspel":
		_haspel = 3 - _haspel
	elif _on.has(control):
		_on[control] = not _on[control]
	_sync_state()
	_refresh()


func _set_reveal(open_it: bool) -> void:
	reveal_open = open_it
	if _log != null:
		_log.reveal_open = open_it
	_refresh()


func _show_skin(meterkast: bool) -> void:
	_skin_target = 1.0 if meterkast else 0.0
	_xfade_t = 0.0
	_refresh()


## Esc, [Klaar] or the last beat: back into the room, the explainer filed.
func close() -> void:
	if not _open:
		return
	_open = false
	if beats != null:
		beats.close()
	if _log != null:
		_log.see(def.id)
		_log.reveal_open = reveal_open
	closed.emit(def.id)
	if is_inside_tree() and not reduced_motion:
		var t := create_tween()
		t.tween_property(_card, "modulate:a", 0.0, OPEN_S * 0.75)
		t.tween_callback(queue_free)
	elif is_inside_tree():
		queue_free()


func _finish() -> void:
	_open = false
	closed.emit(def.id if def != null else "")
	queue_free()


# ── Time ────────────────────────────────────────────────────────────────────

func step(dt: float) -> void:
	if not _open:
		return
	if beats != null:
		beats.tick(dt)
		_after_beats()
		if not _open:
			return
	_result = OhmCable.solve(_on, _cross_section())
	_t_cable = OhmCable.ease_temperature(_t_cable, _result["t_cable_c"], dt, 0.0 if reduced_motion else OhmCable.TAU_S)
	if not reduced_motion:
		_wheel_turn = fmod(_wheel_turn + _result["current_a"] * WHEEL_TURNS_PER_A * dt, 1.0)
	_led_t += dt
	_xfade_t += dt
	_tag_t += dt
	for g_index in GROUP_ORDER.size():
		var g := GROUP_ORDER[g_index]
		var start := 0.0 if reduced_motion else XFADE_STAGGER_S * g_index
		if _xfade_t >= start:
			_mix[g] = move_toward(_mix[g], _skin_target, dt / XFADE_EACH_S)
	for entry: Dictionary in figure.layers:
		var id: String = entry["id"]
		var target := 1.0 if _shown_by_state(entry) else 0.0
		var span := SWAP_S if entry.get("when", {}).has("haspel") else FLIP_S
		_vis[id] = target if reduced_motion else move_toward(_vis[id], target, dt / span)
	for id: String in _pulse.keys():
		_pulse[id] -= dt
		if _pulse[id] <= 0.0:
			_pulse.erase(id)
	_refresh()


func _after_beats() -> void:
	_sync_state()
	if beats.done:
		close()
		return
	var id := beats.beat_id()
	if id == _beat_seen:
		return
	_beat_seen = id
	var b := beats.beat()
	for what: String in b.get("shows", []):
		_shows[what] = true
	if b.get("phase") == "cross" and _skin_target < 1.0:
		_show_skin(true)
		_tag_t = 0.0
	if b.has("pulse"):
		_pulse[_control_layer(b["pulse"])] = 0.8
	_refresh()


func _sync_state() -> void:
	if beats != null:
		_on = beats.on.duplicate()
		_haspel = beats.haspel


func _cross_section() -> float:
	return 1.5 if _haspel == 1 else 2.5


## The off/closed layer of a control in the skin on show (it pulses).
func _control_layer(control: String) -> String:
	for c: Dictionary in def.controls:
		if c["id"] == control:
			return "%s_%s" % [c["meterkast"], "off"] if _skin_target >= 0.5 else "%s_%s" % [c["tuin"], "closed"]
	return ""


# ── What shows ──────────────────────────────────────────────────────────────

## Whether the switches, valves and reel put this layer on show (its skin aside).
func _shown_by_state(entry: Dictionary) -> bool:
	var w: Dictionary = entry.get("when", {})
	if w.is_empty():
		return true
	if w.has("haspel"):
		return (_haspel == int(w["haspel"])) == w["active"]
	if w.has("control"):
		return _on[w["control"]] == w["on"]
	if w.has("spray"):
		return spray_level(w["spray"]) == int(w["level"])
	return true


## 0 when the outlet is shut, else 1–3 by its own flow (an estimate: below
## 1 A a trickle, below 5 A a spray, above it the full arc).
func spray_level(outlet: String) -> int:
	if not _on.get(outlet, false):
		return 0
	var current: float = _result.get("u_end_v", OhmCable.U_NOMINAL) * OhmCable.LOADS[outlet] / pow(OhmCable.U_NOMINAL, 2.0)
	return 1 if current < 1.0 else (2 if current < 5.0 else 3)


## How much of its skin a layer shows: 1 for shared layers, else by the
## cross-fade of its pair group.
func skin_weight(id: String) -> float:
	var entry := figure.layer(id)
	var mix: float = _mix.get(entry.get("group", ""), _skin_target)
	match entry.get("skin"):
		"tuin":
			return 1.0 - mix
		"meterkast":
			return mix
	return 1.0


func alpha(id: String) -> float:
	return skin_weight(id) * _vis.get(id, 0.0)


func group_mix(group: String) -> float:
	return _mix.get(group, 0.0)


## 0..1: how warm the hose or cable looks (the same value in both skins).
func heat_level() -> float:
	return clampf((_t_cable - OhmCable.ROOM_C) / HEAT_SPAN_C, 0.0, 1.0)


func tags_visible() -> bool:
	return not _tag_labels.is_empty() and _tag_labels[0].visible


## The text of every label and strip a player can see now (test T9).
func visible_texts() -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem and not n.visible:
			continue
		if n is CanvasItem and n.modulate.a <= 0.0:
			continue
		if n is Label or n is Button:
			out.append(n.text)
		elif n is RichTextLabel:
			out.append(n.get_parsed_text())
		stack.append_array(n.get_children())
	return out


# ── Building ────────────────────────────────────────────────────────────────

func _build() -> void:
	layer = 20
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_card = Panel.new()
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = PAPER
	sheet.border_color = EDGE
	sheet.set_border_width_all(1)
	sheet.shadow_color = Color(0, 0, 0, 0.25)
	sheet.shadow_size = 14
	sheet.shadow_offset = Vector2(0, 6)
	_card.add_theme_stylebox_override("panel", sheet)
	add_child(_card)
	# The clip that holds the sheet to the whiteboard.
	var clip := Panel.new()
	var steel := StyleBoxFlat.new()
	steel.bg_color = Color("#9a9aa0")
	steel.set_corner_radius_all(4)
	steel.border_color = Color("#5a5a60")
	steel.set_border_width_all(1)
	clip.add_theme_stylebox_override("panel", steel)
	clip.name = "Clip"
	_card.add_child(clip)

	_stage = Control.new()
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	_card.add_child(_stage)
	_root = Node2D.new()
	_stage.add_child(_root)
	for entry: Dictionary in figure.layers:
		var s := Sprite2D.new()
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var tex := figure.texture(entry["id"])
		var r: Array = entry["rect"]
		s.position = Vector2(r[0], r[1])
		if tex != null:
			s.texture = tex
			s.scale = Vector2(r[2], r[3]) / Vector2(tex.get_size())
		_root.add_child(s)
		_sprites[entry["id"]] = s
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	_root.add_child(_overlay)
	for lcd: Dictionary in figure.lcds:
		_lcd_labels[lcd["id"]] = _face_label(lcd, Color("#1d1d20"))
	for i in mini(figure.tags.size(), def.tags.size()):
		var tag := _figure_label(def.tags[i], Vector2(figure.tags[i]["at"][0], figure.tags[i]["at"][1]), 13.0, Color("#123c7a"))
		tag.visible = false
		_tag_labels.append(tag)

	var fig := _label(tr("Hoe werkt het? %d") % def.number, 15, Color("#3a3a3e"))
	fig.name = "Fig"
	var title := _label(def.name.to_upper(), 15, MUTED)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	klaar = _button(tr("Klaar"))
	klaar.pressed.connect(close)
	_hint = _label("", 15, MUTED)
	_hint.name = "Hint"
	reveal_corner = _button("◣ " + def.reveal.get("label", ""))
	reveal_corner.flat = true
	reveal_corner.add_theme_color_override("font_color", Color("#123c7a"))
	reveal_corner.pressed.connect(func() -> void: _set_reveal(not reveal_open))
	_readout = _label("", 17, Color("#26262a"))
	_readout.name = "Readout"
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ruud = RichTextLabel.new()
	_ruud.bbcode_enabled = true
	_ruud.fit_content = true
	_ruud.scroll_active = false
	_ruud.add_theme_font_size_override("normal_font_size", 19)
	_ruud.add_theme_font_size_override("bold_font_size", 19)
	_ruud.add_theme_color_override("default_color", Color("#1d2b3a"))
	_card.add_child(_ruud)
	_keys = _label(tr("Spatie: verder   Esc: klaar"), 13, MUTED)
	_keys.name = "Keys"
	_strip = RichTextLabel.new()
	_strip.bbcode_enabled = true
	_strip.fit_content = true
	_strip.scroll_active = false
	_strip.add_theme_font_size_override("normal_font_size", 16)
	_strip.add_theme_font_size_override("italics_font_size", 16)
	_strip.add_theme_color_override("default_color", Color("#26262a"))
	var strip_bg := StyleBoxFlat.new()
	strip_bg.bg_color = Color(1, 1, 1, 0.96)
	strip_bg.border_color = Color("#d4d4d6")
	strip_bg.set_border_width_all(1)
	strip_bg.set_content_margin_all(12)
	_strip.add_theme_stylebox_override("normal", strip_bg)
	_card.add_child(_strip)
	if codex:
		for meterkast in [false, true]:
			var tab := _button(tr("De meterkast") if meterkast else tr("De tuin"))
			tab.pressed.connect(_show_skin.bind(meterkast))
			_tabs.append(tab)
	_layout()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_card.add_child(l)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE  # Spatie moves Ruud on, never presses a button
	b.add_theme_font_size_override("font_size", 16)
	_card.add_child(b)
	return b


## A label lying on a face of the drawing (an LCD window).
func _face_label(lcd: Dictionary, color: Color) -> Label:
	var holder := Node2D.new()
	holder.transform = ExplainerFigure.plane(lcd)
	_root.add_child(holder)
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(lcd["h"] * 0.62 * TEXT_SCALE))
	l.add_theme_color_override("font_color", color)
	l.scale = Vector2.ONE / TEXT_SCALE
	l.size = Vector2(lcd["w"], lcd["h"]) * TEXT_SCALE
	holder.add_child(l)
	return l


## A label standing upright on the figure (a marker tag).
func _figure_label(text: String, at: Vector2, size: float, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(size * TEXT_SCALE))
	l.add_theme_color_override("font_color", color)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("#fff8c4")
	paper.set_content_margin_all(4 * TEXT_SCALE)
	paper.set_corner_radius_all(int(2 * TEXT_SCALE))
	l.add_theme_stylebox_override("normal", paper)
	l.scale = Vector2.ONE / TEXT_SCALE
	l.position = at
	l.rotation = -0.06
	_root.add_child(l)
	return l


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920, 1080)


## The sheet takes as much of the screen as the figure's shape allows.
func _layout() -> void:
	var screen := _screen()
	var vb := figure.viewbox
	var w := minf(screen.x * 0.94, (screen.y * 0.96 - CARD_TOP - CARD_BOTTOM) * vb.x / vb.y + 2 * CARD_SIDE)
	var fig_w := w - 2 * CARD_SIDE
	var s := fig_w / vb.x
	var h := CARD_TOP + vb.y * s + CARD_BOTTOM
	_card.size = Vector2(w, h)
	_card.position = (screen - _card.size) / 2.0
	var clip: Control = _card.get_node("Clip")
	clip.size = Vector2(90, 16)
	clip.position = Vector2(w / 2.0 - 45, -8)
	_stage.position = Vector2(CARD_SIDE, CARD_TOP)
	_stage.size = vb * s
	_root.scale = Vector2(s, s)
	var fig: Label = _card.get_node("Fig")
	fig.position = Vector2(CARD_SIDE, 22)
	var title: Label = _card.get_node("Title")
	title.size = Vector2(w * 0.5, 24)
	klaar.size = Vector2.ZERO
	klaar.position = Vector2(w - CARD_SIDE - klaar.get_combined_minimum_size().x, 14)
	title.position = Vector2(klaar.position.x - 16 - title.size.x, 22)
	var bottom := CARD_TOP + vb.y * s
	_hint.position = Vector2(CARD_SIDE, bottom + 8)
	reveal_corner.position = Vector2(CARD_SIDE - 8, bottom + 32)
	_readout.size = Vector2(w * 0.4, 78)
	_readout.position = Vector2(w - CARD_SIDE - _readout.size.x, bottom + 4)
	_ruud.position = Vector2(CARD_SIDE, bottom + 90)
	_ruud.size = Vector2(w - 2 * CARD_SIDE, 56)
	_keys.position = Vector2(w - CARD_SIDE - 260, h - 26)
	_keys.size = Vector2(260, 20)
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# The sums unfold over the empty sky of the drawing, top right.
	_strip.position = Vector2(CARD_SIDE + fig_w * 0.47, CARD_TOP + 4)
	_strip.size = Vector2(fig_w * 0.53, 0)
	for i in _tabs.size():
		_tabs[i].position = Vector2(CARD_SIDE + 180 + i * 150, 14)


# ── Refresh ─────────────────────────────────────────────────────────────────

func _refresh() -> void:
	if _card == null:
		return
	var heat := heat_level()
	for entry: Dictionary in figure.layers:
		var id: String = entry["id"]
		var s: Sprite2D = _sprites[id]
		var a := alpha(id)
		s.visible = a > 0.001
		var glow := 1.0 + 0.35 * sin(_pulse[id] / 0.8 * PI) if _pulse.has(id) else 1.0
		if entry.get("heat", false):
			var level := heat if id != "heater_glow" else 1.0
			s.modulate = Color(WARM, a * level * HEAT_MAX_ALPHA)
		else:
			s.modulate = Color(glow, glow, glow, a)
	var meter := _skin_target >= 0.5
	var lcd_on := group_mix("meter_flow")
	for id: String in _lcd_labels:
		var l: Label = _lcd_labels[id]
		var w := group_mix("meter_end") if id == "multimeter" else lcd_on
		l.get_parent().visible = w > 0.001
		l.modulate.a = w
		_fit_lcd(l, _lcd_text(id))
	for tag in _tag_labels:
		tag.visible = _tag_t < TAG_S
	var b := beats.beat() if beats != null else {}
	var phase: String = b.get("phase", "meterkast" if meter else "tuin")
	_hint.text = def.hint.get("haspel" if _haspel_free() and meter else ("tuin" if phase == "tuin" else "meterkast"), "")
	_readout.visible = meter and _shows["readout"]
	_readout.text = "%s  %s\n%s  %s\n%s  %s" % [def.labels.get("current", ""), _amps(_result.get("current_a", 0.0)),
		def.labels.get("u_end", ""), _volts(_result.get("u_end_v", 230.0)), def.labels.get("t_cable", ""), "%d °C" % roundi(_t_cable)]
	reveal_corner.visible = _shows["reveal"] and meter
	_strip.visible = reveal_open and reveal_corner.visible
	if _strip.visible:
		_set_text(_strip, _reveal_text())
	_ruud.visible = beats != null
	_keys.visible = beats != null
	if beats != null:
		_set_text(_ruud, "[b]Ruud[/b]   " + "  ".join(_ruud_lines(b)))
	_overlay.queue_redraw()


## A RichTextLabel re-parses its BBCode on every assignment: only when it changed.
static func _set_text(label: RichTextLabel, text: String) -> void:
	if label.text != text:
		label.text = text


func _haspel_free() -> bool:
	return codex or (beats != null and beats.haspel_unlocked)


## Ruud's lines so far: after a silence the rest waits two seconds.
func _ruud_lines(b: Dictionary) -> Array:
	var lines: Array = b.get("lines", [])
	var silences: Array = b.get("silence_after", [])
	if silences.is_empty():
		return lines
	var cut: int = silences[0]
	var chars := 0
	for i in cut + 1:
		chars += String(lines[i]).length()
	var until := ExplainerBeats.READ_BASE_S + chars * ExplainerBeats.READ_PER_CHAR_S + ExplainerBeats.SILENCE_S
	return lines if beats.elapsed() >= until else lines.slice(0, cut + 1)


## An LCD's digits as large as its window allows.
func _fit_lcd(l: Label, text: String) -> void:
	if l.text == text:
		return
	l.text = text
	var window := l.size / TEXT_SCALE
	var by_width := window.x * 1.7 / maxf(text.length(), 1.0)
	l.add_theme_font_size_override("font_size", int(minf(window.y * 0.8, by_width) * TEXT_SCALE))


func _lcd_text(id: String) -> String:
	match id:
		"stroomtang":
			return _amps(_result.get("current_a", 0.0))
		"multimeter":
			return _volts(_result.get("u_end_v", 230.0))
		"thermometer":
			return "%d °C" % roundi(_t_cable)
	return ""


func _reveal_text() -> String:
	var r := _result
	var values := {
		"u_n": _nl(OhmCable.U_NOMINAL, 0),
		"r_total": "—" if is_inf(r["r_total_ohm"]) else _nl(r["r_total_ohm"], 1),
		"current": _nl(r["current_a"], 2 if r["current_a"] < 1.0 else 1),
		"r_cable": _nl(r["r_cable_ohm"], 2),
		"p_cable": _nl(r["p_cable_w"], 0),
		"du": _nl(r["du_v"], 1),
		"u_end": _nl(r["u_end_v"], 0),
		"p_app": _nl(r["p_app_w"], 0),
	}
	var out: Array[String] = []
	for line: Dictionary in def.reveal.get("lines", []):
		var text := "[i]%s[/i]" % line["words"]
		if line.has("formula"):
			text += "   %s" % line["formula"]
		if line.has("live"):
			text += "  →  %s" % String(line["live"]).format(values)
		out.append(text)
	return "\n".join(out)


func _amps(a: float) -> String:
	return "%s A" % _nl(a, 2 if a < 1.0 and a > 0.0 else 1)


func _volts(v: float) -> String:
	return "%s V" % _nl(v, 0)


## Dutch number: a decimal comma, a thousands dot.
static func _nl(x: float, decimals: int) -> String:
	var text := ("%." + str(decimals) + "f") % x if decimals > 0 else str(roundi(x))
	var parts := text.split(".")
	var whole := parts[0]
	var grouped := ""
	while whole.lstrip("-").length() > 3:
		grouped = "." + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	return whole + grouped + ("," + parts[1] if parts.size() > 1 else "")


# ── The overlays: needles, the paddle wheel, the pulse LED ──────────────────

func _draw_overlay() -> void:
	for n: Dictionary in figure.needles:
		var w := 1.0 - group_mix("source") if n["id"] == "tap_gauge_needle" else 1.0 - group_mix("meter_end")
		if w <= 0.001:
			continue
		var value: float = n.get("fixed", clampf((_result.get("u_end_v", 230.0) - END_GAUGE_V.x) / (END_GAUGE_V.y - END_GAUGE_V.x), 0.0, 1.0))
		var theta := PI * (float(n["from"]) + (float(n["to"]) - float(n["from"])) * value)
		var t := ExplainerFigure.plane(n)
		var dir := Vector2(sin(theta), -cos(theta))
		_overlay.draw_line(t * (-dir * float(n["tail"])), t * (dir * float(n["length"])), Color(0, 0, 0, w), 1.3, true)
		_overlay.draw_circle(t * Vector2.ZERO, 1.4, Color(0.15, 0.15, 0.16, w))
	for wheel: Dictionary in figure.wheels:
		var w := 1.0 - group_mix("meter_flow")
		if w <= 0.001:
			continue
		var t := ExplainerFigure.plane(wheel)
		var blades: int = wheel["blades"]
		for k in blades:
			var a := TAU * (_wheel_turn + float(k) / blades)
			_overlay.draw_line(t * Vector2.ZERO, t * (Vector2(cos(a), sin(a)) * float(wheel["r"])), Color(0.2, 0.2, 0.22, w), 1.1, true)
	for led: Dictionary in figure.leds:
		var w := group_mix("source")
		var watts: float = _result.get("p_app_w", 0.0)
		# Blinks faster with more power (estimate: 1 flash a second per kilowatt).
		var lit := watts > 1.0 and fmod(_led_t * watts / 1000.0, 1.0) < 0.25
		if w > 0.001 and lit:
			_overlay.draw_circle(Vector2(led["at"][0], led["at"][1]), 2.0, Color(0.9, 0.15, 0.1, w))
