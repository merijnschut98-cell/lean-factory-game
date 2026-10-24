class_name ExplainerView
extends CanvasLayer
## "Hoe werkt het?": a sheet with the anatomy figure on it (PLAN 2.7c; spec
## 2026-10-16-explainer-spanning-stroom-weerstand §4 and §6.3, generalised by
## 2026-10-24-explainer-transformator §6). The analogy's skin first; the
## speaker's beats at the bottom; the controls are parts of the drawing (a
## click, or their keys from the content), a locked one opens at its beat;
## the cross-fade turns each analogy part into its real counterpart where it
## stands. What the controls do and what the drawing shows for it is the
## explainer's rig's (ExplainerRig). Readouts are Godot labels on the
## instruments' own LCD faces; the sums wait behind "Laat de rekensom zien"
## (R). Ruud's beats wait for the player (PLAN 2.13 A): Spatie, Enter or a
## click on his line moves on, ← or Backspace goes back a beat, a counter
## says where you are ("3/14"); holding Spatie or [Klaar] closes it; Esc asks
## for the pause menu (pause_requested). In the codex Esc closes.
##
## Open it with ExplainerView.open(parent, id, options); it emits `closed`
## when done and files the explainer in the ExplainerLog it was given.
## Options: log (ExplainerLog), codex (bool: no speaker, the skin tab, every
## control free), reduced_motion (bool), data_dir (String), auto (bool: "Tekst loopt
## vanzelf door", beats move on by themselves).
##
## All motion runs through step(dt) (called from _process), so tests drive
## it frame by frame; only the open and close fades are Tweens.

signal closed(explainer_id: String)
## Esc on Ruud's board: the world's pause menu, the sheet stays.
signal pause_requested

const SCENE := "res://src/ui/explainer/explainer_view.tscn"
## The cross-fade: one pair group after another (the content's `groups`; spec §6.3, estimates).
const XFADE_EACH_S := 0.3
const XFADE_STAGGER_S := 0.25
const TAG_S := 3.0
## A valve or a switch flips in 0.08 s; the reel swap takes 0.6 s.
const FLIP_S := 0.08
const SWAP_S := 0.6
const OPEN_S := 0.4
const HOLD_SKIP_S := SceneLines.HOLD_SKIP_S
const KEYS := "Spatie: verder   ←: terug   Spatie vasthouden: overslaan   Esc: pauze"
## The heat tint: a warm orange, as deep as the rig's heat says.
const WARM := Color("#ff7a1a")
const HEAT_MAX_ALPHA := 0.85
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
## The controls and the model (the beats' own rig when there are beats).
var rig: ExplainerRig
## The speaker's beats; null in the codex.
var beats: ExplainerBeats
var error := ""
var codex := false
var reduced_motion := false
var reveal_open := false
var klaar: Button
var reveal_corner: Button

var _log: ExplainerLog
var _open := true
var _skin_target := 0.0  # 0 the analogy, 1 the real thing
var _groups: Array = []  # the pair groups in cross-fade order
var _mix := {}  # pair group → 0..1
var _xfade_t := INF
var _tag_t := INF
var _shows := {"readout": false, "reveal": false}
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
## Seconds Spatie has been held (-1: not held).
var _held := -1.0


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
	_groups = def.groups
	for g: String in _groups:
		_mix[g] = 1.0 if codex else 0.0
	rig = ExplainerRig.create(def)
	if codex:
		_skin_target = 1.0
		_shows = {"readout": true, "reveal": true}
		rig.unlock_all()
	else:
		beats = ExplainerBeats.new(def, rig)
		beats.auto = options.get("auto", false)
		beats.start()
	_build()
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
	var key := event as InputEventKey
	if not _open or key == null or key.echo:
		return
	if key.keycode == KEY_SPACE:
		hold_space(key.pressed)
	if key.pressed and press(key.keycode):
		get_viewport().set_input_as_handled()


## Spatie down (true) or up: held for HOLD_SKIP_S it closes the sheet (a skip).
func hold_space(on: bool) -> void:
	_held = 0.0 if on and beats != null else -1.0


## One key: a control's own (the content's `key`, and `down_key` for a
## stepped one), R the reveal, Spatie or Enter on, ← or Backspace back, Esc
## the pause (in the codex: closes). True when the view used it.
func press(key: Key) -> bool:
	for c: Dictionary in def.controls:
		for which: String in ["key", "down_key"]:
			if c.has(which) and OS.find_keycode_from_string(str(c[which])) == key:
				_toggle(c["id"], -1 if which == "down_key" else 1)
				return true
	match key:
		KEY_R:
			if reveal_corner.visible:
				_set_reveal(not reveal_open)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			next()
		KEY_LEFT, KEY_BACKSPACE:
			if beats != null:
				beats.back()
				_after_beats()
		KEY_ESCAPE:
			if codex:
				close()
			else:
				pause_requested.emit()
		_:
			return false
	return true


## Spatie, Enter or a click on Ruud's line: the rest of the beat, or the next one.
func next() -> void:
	if beats != null:
		beats.next()
		_after_beats()


func _on_ruud_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next()


func _on_stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_figure(_root.transform.affine_inverse() * event.position)


## A click at a point of the figure (viewBox units): the control under it
## (a hit's `step` turns a stepped control down or up). Neighbouring hits'
## rects overlap on screen; the nearest centre wins.
func click_figure(point: Vector2) -> void:
	var skin := _skin()
	var best := {}
	var nearest := INF
	for hit: Dictionary in figure.hits:
		var r: Array = hit["rect"]
		var rect := Rect2(r[0], r[1], r[2], r[3])
		if hit["skin"] in [skin, "shared"] and rect.has_point(point) and rect.get_center().distance_to(point) < nearest:
			nearest = rect.get_center().distance_to(point)
			best = hit
	if not best.is_empty():
		_toggle(best["control"], int(best.get("step", 1)))


func _toggle(control: String, step: int = 1) -> void:
	if beats != null:
		if beats.toggle(control, step):
			_after_beats()
	else:
		rig.toggle(control, step)
	_refresh()


## The skin on show: the analogy's or the real one's id.
func _skin() -> String:
	return def.real_skin() if _skin_target >= 0.5 else def.analogy_skin()


func _set_reveal(open_it: bool) -> void:
	reveal_open = open_it
	if _log != null:
		_log.reveal_open = open_it
	_refresh()


func _show_skin(meterkast: bool) -> void:
	_skin_target = 1.0 if meterkast else 0.0
	_xfade_t = 0.0
	_refresh()


## [Klaar], a held Spatie, the last beat (or Esc in the codex): back into the room, the explainer filed.
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
		if _held >= 0.0:
			_held += dt
			if _held >= HOLD_SKIP_S:
				close()
		if not _open:
			return
	rig.step(dt, reduced_motion)
	_xfade_t += dt
	_tag_t += dt
	for g_index in _groups.size():
		var g: String = _groups[g_index]
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


## The layer of a control that pulses: its off (closed) layer in the skin on
## show, or its own shared `layer`.
func _control_layer(control: String) -> String:
	var skin := _skin()
	for c: Dictionary in def.controls:
		if c["id"] == control:
			if c.has(skin):
				return "%s_%s" % [c[skin], "closed" if skin == "tuin" else "off"]
			return c.get("layer", "")
	return ""


# ── What shows ──────────────────────────────────────────────────────────────

## Whether the controls put this layer on show (its skin aside).
func _shown_by_state(entry: Dictionary) -> bool:
	var w: Dictionary = entry.get("when", {})
	return w.is_empty() or rig.shows(w)


## How much of its skin a layer shows: 1 for shared layers, else by the
## cross-fade of its pair group.
func skin_weight(id: String) -> float:
	return _weight(figure.layer(id))


## The same for any manifest entry with a skin and a group (layers, LCDs, needles).
func _weight(entry: Dictionary) -> float:
	var mix: float = _mix.get(entry.get("group", ""), _skin_target)
	var skin: String = entry.get("skin", "shared")
	if skin == def.analogy_skin():
		return 1.0 - mix
	if skin == def.real_skin():
		return mix
	return 1.0


func alpha(id: String) -> float:
	return skin_weight(id) * _vis.get(id, 0.0)


func group_mix(group: String) -> float:
	return _mix.get(group, 0.0)


## 0..1: how warm the subject looks (the same value in both skins).
func heat_level() -> float:
	return rig.heat_level()


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
	_ruud.mouse_filter = Control.MOUSE_FILTER_STOP
	_ruud.gui_input.connect(_on_ruud_input)
	_card.add_child(_ruud)
	_keys = _label(tr(KEYS), 13, MUTED)
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
		for real in [false, true]:
			var tab := _button(def.tab(def.real_skin() if real else def.analogy_skin()))
			tab.pressed.connect(_show_skin.bind(real))
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
	_keys.position = Vector2(CARD_SIDE, h - 26)
	_keys.size = Vector2(w - 2 * CARD_SIDE, 20)
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
	for entry: Dictionary in figure.layers:
		var id: String = entry["id"]
		var s: Sprite2D = _sprites[id]
		var a := alpha(id)
		s.visible = a > 0.001
		var glow := 1.0 + 0.35 * sin(_pulse[id] / 0.8 * PI) if _pulse.has(id) else 1.0
		if entry.get("heat", false):
			s.modulate = Color(WARM, a * rig.heat(id) * HEAT_MAX_ALPHA)
		else:
			s.modulate = Color(glow, glow, glow, a)
	var meter := _skin_target >= 0.5
	for lcd: Dictionary in figure.lcds:
		var l: Label = _lcd_labels[lcd["id"]]
		var w := _weight(lcd)
		l.get_parent().visible = w > 0.001
		l.modulate.a = w
		_fit_lcd(l, rig.lcd_text(lcd["id"]))
	for tag in _tag_labels:
		tag.visible = _tag_t < TAG_S
	var b := beats.beat() if beats != null else {}
	var phase: String = b.get("phase", _skin())
	_hint.text = def.hint.get(_freed_control() if meter else "", def.hint.get(def.analogy_skin() if phase == def.analogy_skin() else def.real_skin(), ""))
	_readout.visible = meter and _shows["readout"]
	_readout.text = rig.readout(def.labels)
	reveal_corner.visible = _shows["reveal"] and meter
	_strip.visible = reveal_open and reveal_corner.visible
	if _strip.visible:
		_set_text(_strip, _reveal_text())
	_ruud.visible = beats != null
	_keys.visible = beats != null
	if beats != null:
		_set_text(_ruud, "[b]%s[/b]   %s" % [def.speaker, "  ".join(beats.lines_shown())])
		_keys.text = "%s      %d/%d" % [tr(KEYS), beats.number(), beats.count()]
	_overlay.queue_redraw()


## A RichTextLabel re-parses its BBCode on every assignment: only when it changed.
static func _set_text(label: RichTextLabel, text: String) -> void:
	if label.text != text:
		label.text = text


## The control a beat opened (or the codex frees) with its own hint, or "".
func _freed_control() -> String:
	for c: Dictionary in def.controls:
		var id: String = c["id"]
		if def.hint.has(id) and _opened_by_a_beat(id) and not rig.is_locked(id):
			return id
	return ""


func _opened_by_a_beat(control: String) -> bool:
	return def.beats.any(func(b: Dictionary) -> bool: return control in b.get("unlocks", []))


## An LCD's digits as large as its window allows.
func _fit_lcd(l: Label, text: String) -> void:
	if l.text == text:
		return
	l.text = text
	var window := l.size / TEXT_SCALE
	var by_width := window.x * 1.7 / maxf(text.length(), 1.0)
	l.add_theme_font_size_override("font_size", int(minf(window.y * 0.8, by_width) * TEXT_SCALE))


func _reveal_text() -> String:
	var values := rig.reveal_values()
	var out: Array[String] = []
	for line: Dictionary in def.reveal.get("lines", []):
		var text := "[i]%s[/i]" % line["words"]
		if line.has("formula"):
			text += "   %s" % line["formula"]
		if line.has("live"):
			text += "  →  %s" % String(line["live"]).format(values)
		out.append(text)
	return "\n".join(out)


# ── The overlays: needles, the paddle wheel, the pulse LED ──────────────────

func _draw_overlay() -> void:
	for n: Dictionary in figure.needles:
		var w := _weight(n)
		if w <= 0.001:
			continue
		var value: float = n.get("fixed", rig.needle(n["id"]))
		var theta := PI * (float(n["from"]) + (float(n["to"]) - float(n["from"])) * value)
		var t := ExplainerFigure.plane(n)
		var dir := Vector2(sin(theta), -cos(theta))
		_overlay.draw_line(t * (-dir * float(n["tail"])), t * (dir * float(n["length"])), Color(0, 0, 0, w), float(n.get("width", 1.3)), true)
		_overlay.draw_circle(t * Vector2.ZERO, 1.4, Color(0.15, 0.15, 0.16, w))
	for wheel: Dictionary in figure.wheels:
		var w := _weight(wheel)
		if w <= 0.001:
			continue
		var t := ExplainerFigure.plane(wheel)
		var blades: int = wheel["blades"]
		var turn := rig.turn(wheel["id"])
		for k in blades:
			var a := TAU * (turn + float(k) / blades)
			var tip := t * (Vector2(cos(a), sin(a)) * float(wheel["r"]))
			_overlay.draw_line(t * Vector2.ZERO, tip, Color(0.2, 0.2, 0.22, w), float(wheel.get("width", 1.1)), true)
			if wheel.has("tip"):  # a crank's pedal at the end of its arm
				_overlay.draw_circle(tip, float(wheel["tip"]), Color(0.15, 0.15, 0.16, w))
	for led: Dictionary in figure.leds:
		var w := _weight(led)
		if w > 0.001 and rig.led(led["id"]):
			_overlay.draw_circle(Vector2(led["at"][0], led["at"][1]), 2.0, Color(0.9, 0.15, 0.1, w))
