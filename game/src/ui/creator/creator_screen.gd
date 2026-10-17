class_name CreatorScreen
extends Control
## The character creator (PLAN 2.7b; spec 2026-10-16-creator-and-minimap §1,
## first five minutes B1): HR's welcome mail on a phone, then the phone held
## sideways as a camera making the photo for your Voltana badge. One trait at
## a time on a mode strip (the first name, then the traits of
## creator_options.json in its order, labels from the file); the live model is
## the preview. ↑↓/W S the trait, ←→/A D the option, Z/C or a drag turn the
## model, R "Willekeurig" (never the name or the body), Enter "Volgende" (on the
## last trait the photo), Esc leaves the name field or asks before leaving.
## "Foto maken" renders the badge photo (PortraitPhoto) and emits `done` with
## the made player. Also opened from the pause menu as "Uiterlijk" (Mode.EDIT):
## no mail, the current look and name, free and silent.
##
## Works outside the tree too (the tests build it headless): no animation, no
## photo (the placeholder), the same state.

## The player is made: name, look and photo (empty headless).
signal done(profile: PlayerProfile)
## Back without a photo (Esc on the mail, or "Terug" / "Weggooien").
signal cancelled

enum Mode { NEW, EDIT }
enum Stage { MAIL, CAMERA, LEAVING, SENT }

## The strip's first step, before the file's traits.
const NAME_STEP := "name"
## Traits framed from the knees up; the rest head and shoulders (§1.2).
const WIDE: Array[String] = ["lichaam", "kleding"]

const STATUS_TIME := "20:14"
const STATUS_DAY := "zo 11 okt"
const STATUS_NEW := "Pasfoto · Voltana"
const NEW_PHOTO := "Nieuwe pasfoto"
const RANDOM := "Willekeurig"
const NAME_LABEL := "Je voornaam"
const NAME_FIELD := "Je voornaam (op je pas)"
const NAME_LINE := "Zo noemen je collega's je."
const BODY_LINE := "Collega's spreken over je als hij of zij."
const OUTFIT_TITLE := "Wat trek je maandag aan?"
const OUTFIT_LINE := "Buiten draag je er je PBM overheen."
const MORE_HAIR := "Meer kapsels"
const GOOD := "Zo is het goed"
const NEXT := "Volgende"
const SHOOT := "Foto maken"
const SENT := "Verzonden ✓"
const ASK_NAME := "Hoe mogen we je noemen?"
const ONLY_LETTERS := "Alleen letters, met een spatie, streepje of apostrof ertussen."
const TOO_LONG := "Langer past niet op je pas."
const BADGE_COMPANY := "VOLTANA"
const BADGE_ROLE := "CI-lead · Aansluitingen"
const LEAVE_ASK := "Terug naar het titelmenu? Je pasfoto is nog niet gemaakt."
const DISCARD_ASK := "Wijzigingen weggooien?"
const LEAVE := "Terug"
const DISCARD := "Weggooien"
const STAY := "Blijven"
const MAIL_APP := "Mail"
const MAIL_FROM := "Van: HR Voltana Netbeheer"
const MAIL_SUBJECT_LABEL := "Onderwerp:"
const MAIL_SUBJECT := "Welkom! Je eerste dag, maandag 12 oktober"
const MAIL_BODY := "Hoi,\n\nFijn dat je maandag begint als CI-lead bij Aansluitingen, regio Zuidmark. Om half negen word je verwacht bij de ontvangst, Stationsweg 4 in Nova. Ruud Hoekstra haalt je daar op.\n\nWil je vast een pasfoto sturen? Dan ligt je toegangspas maandag klaar.\n\nGroet, HR"
const MAIL_BUTTON := "Pasfoto maken"

## The phone: near-black bezel, rounded (§1.2).
const BEZEL := Color("#121316")
const BEZEL_PX := 14
const BEZEL_RADIUS := 36
const EDGE := 24.0
## The camera's controls: a column over the right of the viewfinder.
const COLUMN_SHARE := 0.34
const COLUMN_SHADE := Color(0.05, 0.06, 0.08, 0.62)
const MUTED := Color(1, 1, 1, 0.55)
const FOCUS := Color("#ffd34d")
const SWATCH := 40
const SHUTTER := 68
## The face square (yellow, as phone cameras draw it) and the thirds grid.
const FACE_SQUARE := Color("#ffd34d")
const GRID := Color(1, 1, 1, 0.22)
## Turning the phone, the flash (30 % white for 80 ms, photosensitivity), dark.
const ROTATE_S := 0.4
const FLASH_ALPHA := 0.3
const FLASH_S := 0.08
const SENT_S := 0.7
const DARK_S := 0.6

var mode := Mode.NEW
var stage := Stage.MAIL
## The player being made: the look as chosen (normalized); the name is
## name_text until the photo confirms it.
var profile := PlayerProfile.new()
var name_text := ""
## "name", then the file's trait ids.
var steps: Array[String] = []
var step := 0
## "Zo is het goed" moved to the shutter: Enter takes the photo.
var at_shutter := false
## The name field has focus: letters type, the keys do not act.
var typing := false
var booth: CreatorBooth
var shutter: Button
var name_field: LineEdit
var rng := RandomNumberGenerator.new()
## When the screen opened (ms), for the playtest log's beat timing.
var opened_ms := Time.get_ticks_msec()

var _asked_name := false
var _hint := ""
var _mail_phone: Control
var _camera_phone: Control
var _status: Label
var _strip: VBoxContainer
var _options: VBoxContainer
var _name_box: VBoxContainer
var _badge_name: Label
var _option_name: Label
var _hint_label: Label
var _line: Label
var _viewfinder: Viewfinder
var _leave_box: PanelContainer
var _leave_text: Label
var _leave_button: Button
var _flash: ColorRect
var _dark: ColorRect


## Before build: what to make. NEW opens on the mail with a random look (a new
## body drawn 50/50); EDIT on the camera with `from`'s look and name. A
## `seed_value` below 0 draws a seed.
func setup(of_mode: Mode, from: PlayerProfile = null, seed_value := -1) -> void:
	mode = of_mode
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	steps.assign([NAME_STEP])
	for t in CreatorLook.traits():
		steps.append(t["id"])
	if mode == Mode.EDIT and from != null:
		profile = from.copy()
		name_text = from.name
		stage = Stage.CAMERA
	else:
		profile = PlayerProfile.new()
		profile.look = random_look(rng)
		stage = Stage.MAIL


## The creator over `parent` on its own layer (the office's "Uiterlijk").
static func open(parent: Node, of_mode: Mode, from: PlayerProfile) -> CreatorScreen:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var screen := CreatorScreen.new()
	screen.setup(of_mode, from)
	screen.build()
	layer.add_child(screen)
	parent.add_child(layer)
	return screen


# ── Looks (pure) ─────────────────────────────────────────────────────────────

## A random look: the body drawn first, then every other trait.
static func random_look(with_rng: RandomNumberGenerator) -> Dictionary:
	var bodies := CreatorLook.options(CreatorLook.BODY, "")
	var body: Dictionary = bodies[with_rng.randi_range(0, bodies.size() - 1)] if not bodies.is_empty() else {}
	return randomized({CreatorLook.BODY: body.get("id", "")}, with_rng)


## "Willekeurig": every trait but the body drawn evenly from the options open
## to the body (for the hair all ten).
static func randomized(look: Dictionary, with_rng: RandomNumberGenerator) -> Dictionary:
	var body := CreatorLook.body_of(look)
	var out := look.duplicate()
	for t in CreatorLook.traits():
		var options := CreatorLook.options(t["id"], body)
		if t["id"] != CreatorLook.BODY and not options.is_empty():
			out[t["id"]] = options[with_rng.randi_range(0, options.size() - 1)]["id"]
	return CreatorLook.normalized(out)


## The look on another body: a trait listed per body and not open to either
## (the face: beard or make-up) goes to the new body's first option; the rest
## stays.
static func with_body(look: Dictionary, body_id: String) -> Dictionary:
	if look.get(CreatorLook.BODY) == body_id:
		return look.duplicate()
	var out := look.duplicate()
	out[CreatorLook.BODY] = body_id
	var body := CreatorLook.body_of(out)
	for t in CreatorLook.traits():
		if t.get("per_body") is Dictionary and not t.get("any_body", false):
			var options := CreatorLook.options(t["id"], body)
			if not options.is_empty():
				out[t["id"]] = options[0]["id"]
	return CreatorLook.normalized(out)


# ── State ───────────────────────────────────────────────────────────────────

func step_id() -> String:
	return steps[step] if step < steps.size() else NAME_STEP


## The options the screen offers for `trait_id` with the current body.
func offered(trait_id: String) -> Array[Dictionary]:
	return CreatorLook.options(trait_id, CreatorLook.body_of(profile.look))


func go_to(index: int) -> void:
	step = clampi(index, 0, steps.size() - 1)
	at_shutter = false
	_hint = ""
	if step_id() != NAME_STEP:
		_unfocus_name()
	if booth != null:
		booth.frame(not step_id() in WIDE)
	refresh()


## [Volgende]: the next trait; on the last, the photo.
func next() -> void:
	if step >= steps.size() - 1:
		shoot()
	else:
		go_to(step + 1)


## Choose option `option_id` of `trait_id` (a body change resets the face).
func choose_in(trait_id: String, option_id: String) -> void:
	if trait_id == CreatorLook.BODY:
		profile.look = with_body(profile.look, option_id)
	else:
		var look := profile.look.duplicate()
		look[trait_id] = option_id
		profile.look = CreatorLook.normalized(look)
	at_shutter = false
	_dress()


## The next (1) or previous (-1) option of the current trait, round.
func cycle(direction: int) -> void:
	var id := step_id()
	var options := offered(id)
	if id == NAME_STEP or options.is_empty():
		return
	var at := options.map(func(o: Dictionary) -> String: return o["id"]).find(profile.look.get(id))
	choose_in(id, options[posmod(at + direction, options.size())]["id"])


## "Willekeurig".
func randomize_look() -> void:
	profile.look = randomized(profile.look, rng)
	_dress()


## What the name field keeps of `text` (PlayerProfile.typed), with the line
## that says why something was not typed.
func type_name(text: String) -> void:
	var kept := PlayerProfile.typed(text)
	if text.length() > PlayerProfile.MAX_NAME and kept.length() >= PlayerProfile.MAX_NAME:
		_hint = tr(TOO_LONG)
	elif kept != text.replace("’", "'"):
		_hint = tr(ONLY_LETTERS)
	name_text = kept
	if name_field != null and name_field.text != kept:
		var caret := mini(name_field.caret_column, kept.length())
		name_field.text = kept
		name_field.caret_column = caret
	_refresh_name()


func can_shoot() -> bool:
	return not PlayerProfile.clean_name(name_text).is_empty()


## [Zo is het goed]: to the shutter with what is chosen so far; without a name
## to the name step, asking once.
func good_as_is() -> void:
	if not can_shoot():
		_ask_name()
		return
	at_shutter = true
	_unfocus_name()
	refresh()
	if shutter.is_inside_tree():
		shutter.grab_focus()


## [Foto maken]: the photo (rendered when a renderer runs), the flash, "Verzonden
## ✓", dark; then `done`. Without a name it asks for one instead.
func shoot() -> void:
	if stage != Stage.CAMERA:
		return
	if not can_shoot():
		_ask_name()
		return
	stage = Stage.SENT
	var made := profile.copy()
	made.name = PlayerProfile.clean_name(name_text)
	made.portrait = PackedByteArray()
	if PortraitPhoto.can_render() and is_inside_tree():
		made.portrait = await PortraitPhoto.take(self, made.look)
		await _sent()
	done.emit(made)


func open_camera() -> void:
	if stage != Stage.MAIL:
		return
	stage = Stage.CAMERA
	go_to(0)
	if is_inside_tree():
		_turn_phone()
	else:
		_show_stage()


## Esc outside the name field: ask before leaving (Stage.LEAVING).
func ask_leave() -> void:
	stage = Stage.LEAVING
	_show_stage()


## "Blijven".
func stay() -> void:
	if stage == Stage.LEAVING:
		stage = Stage.CAMERA
		_show_stage()


## "Terug" / "Weggooien": nothing was made.
func leave() -> void:
	if stage == Stage.LEAVING or stage == Stage.MAIL:
		cancelled.emit()


func focus_name() -> void:
	typing = true
	if name_field != null and name_field.is_inside_tree():
		name_field.grab_focus()


## Turn the model by `radians` (Z/C, a drag).
func turn_by(radians: float) -> void:
	booth.turn(radians)


## A key, as the screen reads it: true when it acted (§1.3). While the name
## field has focus only Enter, ↑/↓ and Esc act; letters type.
func press(key: Key) -> bool:
	match stage:
		Stage.MAIL:
			if key == KEY_ESCAPE:
				leave()
			elif key in [KEY_ENTER, KEY_KP_ENTER]:
				open_camera()
			else:
				return false
			return true
		Stage.LEAVING:
			if key == KEY_ESCAPE:
				stay()
				return true
			return false
		Stage.SENT:
			return true
	if typing and not key in [KEY_ENTER, KEY_KP_ENTER, KEY_UP, KEY_DOWN, KEY_ESCAPE]:
		return false
	match key:
		KEY_UP, KEY_W:
			go_to(step - 1)
		KEY_DOWN, KEY_S:
			go_to(step + 1)
		KEY_LEFT, KEY_A:
			cycle(-1)
		KEY_RIGHT, KEY_D:
			cycle(1)
		KEY_R:
			randomize_look()
		KEY_ENTER, KEY_KP_ENTER:
			if at_shutter:
				shoot()
			else:
				next()
		KEY_ESCAPE:
			if typing:
				_unfocus_name()
			else:
				ask_leave()
		_:
			return false
	return true


func _ask_name() -> void:
	go_to(steps.find(NAME_STEP))
	if not _asked_name:
		_asked_name = true
		_hint = tr(ASK_NAME)
	refresh()
	focus_name()


func _unfocus_name() -> void:
	typing = false
	if name_field != null and name_field.has_focus():
		name_field.release_focus()


## The model in the chosen look, and the column.
func _dress() -> void:
	if booth != null:
		booth.wear(profile.look)
	refresh()


# ── Building ────────────────────────────────────────────────────────────────

## Build the screen (once; tests build it outside the tree).
func build() -> void:
	if booth != null:
		return
	if steps.is_empty():
		setup(mode)
	theme = _theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color("#08090b")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_camera_phone = _build_camera()
	add_child(_camera_phone)
	_mail_phone = _build_mail()
	add_child(_mail_phone)
	_leave_box = _build_leave()
	add_child(_leave_box)
	_flash = _cover(Color(1, 1, 1, 0))
	_dark = _cover(Color(0, 0, 0, 0))
	booth.wear(profile.look)
	booth.frame(not step_id() in WIDE, true)
	_show_stage()
	refresh()


func _ready() -> void:
	if stage == Stage.CAMERA:
		focus_name.call_deferred()


func _cover(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


static func _bezel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BEZEL
	box.set_corner_radius_all(BEZEL_RADIUS)
	box.set_content_margin_all(BEZEL_PX)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 18
	return box


## The phone held upright with HR's mail (B1).
func _build_mail() -> Control:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var phone := PanelContainer.new()
	phone.name = "MailPhone"
	phone.custom_minimum_size = Vector2(430, 800)
	phone.add_theme_stylebox_override("panel", _bezel())
	center.add_child(phone)
	var screen := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Palette.PAPER
	paper.set_corner_radius_all(BEZEL_RADIUS - BEZEL_PX)
	paper.set_content_margin_all(26)
	screen.add_theme_stylebox_override("panel", paper)
	phone.add_child(screen)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	screen.add_child(box)
	var bar := HBoxContainer.new()
	bar.add_child(UiPanel.label(tr(STATUS_TIME), UiTheme.SMALL, Palette.INK))
	var app := UiPanel.label(tr(MAIL_APP), UiTheme.SMALL, Palette.MUTED)
	app.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(app)
	box.add_child(bar)
	box.add_child(UiPanel.label(tr(MAIL_FROM), UiTheme.SMALL, Palette.MUTED))
	box.add_child(UiPanel.label(tr(MAIL_SUBJECT_LABEL), UiTheme.SMALL, Palette.MUTED))
	box.add_child(UiPanel.paragraph(tr(MAIL_SUBJECT), Palette.VOLTANA_BLUE, UiTheme.HEADING))
	box.add_child(HSeparator.new())
	var body := UiPanel.paragraph(tr(MAIL_BODY), Palette.INK, UiTheme.SMALL + 1)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var go := UiPanel.button(tr(MAIL_BUTTON), open_camera)
	go.name = "MailButton"
	go.add_theme_stylebox_override("normal", _round_box(Palette.VOLTANA_BLUE, 12))
	go.add_theme_stylebox_override("hover", _round_box(Palette.BLUE_LIGHT, 12))
	go.add_theme_color_override("font_color", Color.WHITE)
	go.add_theme_color_override("font_hover_color", Color.WHITE)
	box.add_child(go)
	return center


## The phone held sideways as a camera: the viewfinder, the status line, the
## column with the strip, the options and the shutter.
func _build_camera() -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(EDGE))
	var phone := PanelContainer.new()
	phone.add_theme_stylebox_override("panel", _bezel())
	margin.add_child(phone)
	var screen := Control.new()
	screen.clip_contents = true
	phone.add_child(screen)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(view)
	var sub := SubViewport.new()
	sub.own_world_3d = true
	sub.msaa_3d = Viewport.MSAA_4X
	view.add_child(sub)
	booth = CreatorBooth.new()
	booth.shift = -COLUMN_SHARE
	sub.add_child(booth)
	sub.size_changed.connect(func() -> void: booth.frame(booth.close_up, true))  # the shift follows the width
	_viewfinder = Viewfinder.new()
	_viewfinder.screen = self
	_viewfinder.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(_viewfinder)
	screen.add_child(_status_bar())
	_line = UiPanel.label("", UiTheme.FONT_SIZE, Color.WHITE)
	_line.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_line.add_theme_constant_override("shadow_offset_y", 2)
	_line.anchor_top = 1.0
	_line.anchor_bottom = 1.0
	_line.offset_left = 36
	_line.offset_top = -64
	screen.add_child(_line)
	screen.add_child(_build_column())
	return margin


func _status_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 24
	bar.offset_right = -24
	bar.offset_top = 10
	bar.add_child(UiPanel.label(tr(STATUS_TIME), UiTheme.SMALL, Color.WHITE))
	_status = UiPanel.label("", UiTheme.SMALL, Color.WHITE)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_status)
	var random := UiPanel.button(tr(RANDOM), randomize_look)
	random.name = "Random"
	random.add_theme_stylebox_override("normal", _round_box(Color(1, 1, 1, 0.16), 14))
	bar.add_child(random)
	return bar


func _build_column() -> PanelContainer:
	var column := PanelContainer.new()
	var shade := _round_box(COLUMN_SHADE, 18)
	shade.set_content_margin_all(20)
	column.add_theme_stylebox_override("panel", shade)
	column.anchor_left = 1.0 - COLUMN_SHARE
	column.anchor_right = 1.0
	column.anchor_bottom = 1.0
	column.offset_top = 56
	column.offset_right = -16
	column.offset_bottom = -16
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	column.add_child(box)
	_strip = VBoxContainer.new()
	_strip.add_theme_constant_override("separation", 0)
	box.add_child(_strip)
	box.add_child(HSeparator.new())
	_options = VBoxContainer.new()
	box.add_child(_options)
	_name_box = _build_name()
	box.add_child(_name_box)
	_option_name = UiPanel.label("", UiTheme.FONT_SIZE, Color.WHITE)
	box.add_child(_option_name)
	_hint_label = UiPanel.paragraph("", MUTED, UiTheme.SMALL)
	box.add_child(_hint_label)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(UiPanel.button(tr(GOOD), good_as_is))
	buttons.add_child(UiPanel.button(tr(NEXT), next))
	box.add_child(buttons)
	var shoot_row := HBoxContainer.new()
	shoot_row.alignment = BoxContainer.ALIGNMENT_END
	shoot_row.add_child(UiPanel.label(tr(SHOOT), UiTheme.FONT_SIZE, Color.WHITE))
	shutter = Button.new()
	shutter.name = "Shutter"
	shutter.tooltip_text = tr(SHOOT)
	shutter.custom_minimum_size = Vector2(SHUTTER, SHUTTER)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var ring := _round_box(Color.WHITE if state != "disabled" else Color(1, 1, 1, 0.25), SHUTTER / 2)
		ring.border_color = Color(1, 1, 1, 0.5) if state != "focus" else FOCUS
		ring.set_border_width_all(5)
		if state == "hover" or state == "pressed":
			ring.bg_color = Color("#e8e8e8")
		shutter.add_theme_stylebox_override(state, ring)
	shutter.pressed.connect(shoot)
	shoot_row.add_child(shutter)
	box.add_child(shoot_row)
	return column


## The name step: the field and the badge preview (§1.2).
func _build_name() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_child(UiPanel.label(tr(NAME_FIELD), UiTheme.SMALL, MUTED))
	name_field = LineEdit.new()
	name_field.max_length = PlayerProfile.MAX_NAME
	name_field.placeholder_text = tr(NAME_LABEL)
	name_field.text = name_text
	name_field.text_changed.connect(type_name)
	name_field.text_change_rejected.connect(func(_rejected: String) -> void:
		_hint = tr(TOO_LONG)
		_refresh_name())
	name_field.text_submitted.connect(func(_text: String) -> void: next())
	name_field.focus_entered.connect(func() -> void: typing = true)
	name_field.focus_exited.connect(func() -> void: typing = false)
	box.add_child(name_field)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiTheme.card(Color.WHITE))
	box.add_child(badge)
	var row := HBoxContainer.new()
	badge.add_child(row)
	row.add_child(SaveList.Portrait.new(false, profile.portrait))  # the pass you have, in "Uiterlijk"
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	texts.add_child(UiPanel.label(tr(BADGE_COMPANY), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	_badge_name = UiPanel.label("", UiTheme.HEADING, Palette.INK)
	texts.add_child(_badge_name)
	texts.add_child(UiPanel.label(tr(BADGE_ROLE), UiTheme.SMALL, Palette.MUTED))
	return box


func _build_leave() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = UiTheme.build()  # the game's own question, on paper
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	panel.add_child(box)
	_leave_text = UiPanel.paragraph("")
	box.add_child(_leave_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	_leave_button = UiPanel.button("", leave)
	row.add_child(_leave_button)
	row.add_child(UiPanel.button(tr(STAY), stay))
	box.add_child(row)
	return panel


# ── Showing ─────────────────────────────────────────────────────────────────

## The column again for the current step and look.
func refresh() -> void:
	if _strip == null:
		return
	_status.text = "  " + (tr(NEW_PHOTO) if mode == Mode.EDIT else "%s  ·  %s" % [tr(STATUS_DAY), tr(STATUS_NEW)])
	UiPanel.clear(_strip)
	for i in steps.size():
		var id := steps[i]
		var label := tr(NAME_LABEL) if id == NAME_STEP else tr(str(CreatorLook.trait_def(id).get("label", id)))
		var b := UiPanel.button(label.to_upper() if i == step else label, go_to.bind(i))
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		for state in ["normal", "hover", "pressed", "focus"]:
			var box := _round_box(Color(1, 1, 1, 0.1) if state == "hover" else Color.TRANSPARENT, 8)
			box.content_margin_top = 2
			box.content_margin_bottom = 2
			if state == "focus":
				box.border_color = FOCUS
				box.set_border_width_all(2)
			b.add_theme_stylebox_override(state, box)
		b.add_theme_color_override("font_color", Color.WHITE if i == step else MUTED)
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		_strip.add_child(b)
	var id := step_id()
	_name_box.visible = id == NAME_STEP
	UiPanel.clear(_options)
	_option_name.text = ""
	if id != NAME_STEP:
		_show_options(id)
	_line.text = _line_for(id)
	_refresh_name()


## What typing changes: the badge, the hint, the shutter (the strip and the
## options stay as they are).
func _refresh_name() -> void:
	if _strip == null:
		return
	_badge_name.text = name_text
	_hint_label.text = _hint
	shutter.disabled = not can_shoot()


func _show_options(id: String) -> void:
	if id == "kleding":
		_options.add_child(UiPanel.label(tr(OUTFIT_TITLE), UiTheme.SMALL, MUTED))
	var options := offered(id)
	var own := options.size()
	var per: Variant = CreatorLook.trait_def(id).get("per_body")
	if per is Dictionary:
		own = (per.get(CreatorLook.body_of(profile.look), []) as Array).size()
	var flow := HFlowContainer.new()
	_options.add_child(flow)
	var swatches := _is_colour(options)
	for i in options.size():
		if i == own:
			_options.add_child(UiPanel.label(tr(MORE_HAIR), UiTheme.SMALL, MUTED))
			flow = HFlowContainer.new()
			_options.add_child(flow)
		var option := options[i]
		var chosen: bool = profile.look.get(id) == option["id"]
		flow.add_child(_swatch(id, option, chosen) if swatches else _chip(id, option, chosen))
		if chosen:
			_option_name.text = tr(str(option.get("label", option["id"])))


## A colour trait (skin, hair colour, eyes) shows swatches; the rest chips.
static func _is_colour(options: Array[Dictionary]) -> bool:
	return not options.is_empty() and options.all(func(o: Dictionary) -> bool:
		return o.get("color") is Array and not (o.has("part") or o.has("outfit") or o.has("model") or o.has("layer")))


func _chip(id: String, option: Dictionary, chosen: bool) -> Button:
	var b := UiPanel.button(tr(str(option.get("label", option["id"]))), choose_in.bind(id, option["id"]))
	b.toggle_mode = true
	b.set_pressed_no_signal(chosen)
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	return b


func _swatch(id: String, option: Dictionary, chosen: bool) -> Button:
	var b := UiPanel.button("", choose_in.bind(id, option["id"]))
	b.tooltip_text = tr(str(option.get("label", option["id"])))
	b.custom_minimum_size = Vector2(SWATCH, SWATCH)
	var rgb: Array = option["color"]
	var fill := Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
	for state in ["normal", "hover", "pressed", "focus"]:
		var dot := _round_box(fill, SWATCH / 2)
		dot.border_color = Color.WHITE if chosen else (FOCUS if state == "focus" else Color(1, 1, 1, 0.3))
		dot.set_border_width_all(4 if chosen or state == "focus" else 2)
		b.add_theme_stylebox_override(state, dot)
	return b


## The line under the trait, in the viewfinder (B1); "" for the rest.
func _line_for(id: String) -> String:
	match id:
		NAME_STEP:
			return tr(NAME_LINE)
		CreatorLook.BODY:
			return tr(BODY_LINE)
		"kleding":
			return tr(OUTFIT_LINE)
	return ""


func _show_stage() -> void:
	if _mail_phone == null:
		return
	_mail_phone.visible = stage == Stage.MAIL
	_camera_phone.visible = stage != Stage.MAIL
	_leave_box.visible = stage == Stage.LEAVING
	_leave_text.text = tr(DISCARD_ASK) if mode == Mode.EDIT else tr(LEAVE_ASK)
	_leave_button.text = tr(DISCARD) if mode == Mode.EDIT else tr(LEAVE)


## The phone turns to landscape (0.4 s) and the camera opens.
func _turn_phone() -> void:
	var phone: Control = _mail_phone.get_child(0)
	phone.pivot_offset = phone.size / 2.0
	var tween := create_tween()
	tween.tween_property(phone, "rotation", -PI / 2.0, ROTATE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_mail_phone, "modulate:a", 0.0, ROTATE_S).set_ease(Tween.EASE_IN)
	_camera_phone.modulate.a = 0.0
	_camera_phone.visible = true
	tween.tween_property(_camera_phone, "modulate:a", 1.0, 0.25)
	await tween.finished
	_show_stage()
	focus_name()


## The photo is taken: the flash, the frozen frame with "Verzonden ✓", dark.
func _sent() -> void:
	booth.set_process(false)
	var animations := CharacterModel.animations(booth.model)
	if animations != null:
		animations.pause()
	_flash.color.a = FLASH_ALPHA
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, FLASH_S).set_delay(FLASH_S)
	_status.text = "  " + tr(SENT)
	tween.tween_interval(SENT_S)
	tween.tween_property(_dark, "color:a", 1.0, DARK_S)
	await tween.finished


func _process(delta: float) -> void:
	if booth == null or stage != Stage.CAMERA or typing:
		return
	var turn := 0.0
	if Input.is_physical_key_pressed(CameraRig.TURN_LEFT):
		turn -= 1.0
	if Input.is_physical_key_pressed(CameraRig.TURN_RIGHT):
		turn += 1.0
	if turn != 0.0:
		booth.turn(turn * CreatorBooth.TURN_SPEED * delta)
	_viewfinder.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and is_visible_in_tree():
		if press(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode):
			get_viewport().set_input_as_handled()


static func _round_box(fill: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


## White text on the dark camera; chips as soft pills, the chosen one white.
static func _theme() -> Theme:
	var t := UiTheme.build()
	t.set_color("font_color", "Label", Color.WHITE)
	var states := {"normal": Color(1, 1, 1, 0.14), "hover": Color(1, 1, 1, 0.26), "pressed": Color.WHITE,
		"hover_pressed": Color.WHITE, "disabled": Color(1, 1, 1, 0.06), "focus": Color.TRANSPARENT}
	for state: String in states:
		var box := _round_box(states[state], 16)
		if state == "focus":
			box.border_color = FOCUS
			box.set_border_width_all(2)
		t.set_stylebox(state, "Button", box)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(state, "Button", Color.WHITE)
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", MUTED)
	return t


## The viewfinder's drawing over the 3D view: the thirds grid and the face
## square that follows the head; a drag on it turns the model.
class Viewfinder extends Control:
	var screen: CreatorScreen

	func _draw() -> void:
		for i in [1, 2]:
			draw_line(Vector2(size.x * i / 3.0, 0), Vector2(size.x * i / 3.0, size.y), CreatorScreen.GRID, 1.0)
			draw_line(Vector2(0, size.y * i / 3.0), Vector2(size.x, size.y * i / 3.0), CreatorScreen.GRID, 1.0)
		var booth := screen.booth
		if booth == null or not booth.is_inside_tree() or booth.model == null:
			return
		var head := booth.head_point()
		var center := booth.camera.unproject_position(head)
		var side := absf(booth.camera.unproject_position(head + Vector3.UP * CreatorBooth.FACE_SIZE / 2.0).y - center.y) * 2.0
		var corner := center - Vector2(side, side) / 2.0
		draw_rect(Rect2(corner, Vector2(side, side)), CreatorScreen.FACE_SQUARE, false, 2.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			screen.turn_by(event.relative.x * CreatorBooth.DRAG_TURN)
			accept_event()
