class_name UiTheme
## The in-game look: light paper panels with a Voltana-blue header line,
## blue buttons that turn green when pressed, 20 px text. Built in code so
## every colour comes from Palette.

const FONT_SIZE := 20
const SMALL := 17
const HEADING := 26


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_stylebox("panel", "PanelContainer", _box(Palette.PAPER, 12, Palette.VOLTANA_BLUE, 6, 26))
	t.set_stylebox("panel", "Panel", _box(Palette.PAPER, 12, Palette.VOLTANA_BLUE, 6, 26))
	for type in ["Label", "CheckBox", "RichTextLabel"]:
		t.set_color("font_color", type, Palette.INK)
	t.set_color("default_color", "RichTextLabel", Palette.INK)
	t.set_color("font_hover_color", "CheckBox", Palette.VOLTANA_BLUE)
	t.set_color("font_pressed_color", "CheckBox", Palette.INK)

	t.set_stylebox("normal", "Button", _box(Palette.VOLTANA_BLUE, 8))
	t.set_stylebox("hover", "Button", _box(Palette.BLUE_LIGHT, 8))
	t.set_stylebox("pressed", "Button", _box(Palette.GREEN_DARK, 8))
	t.set_stylebox("disabled", "Button", _box(Palette.LINE, 8))
	t.set_stylebox("focus", "Button", _outline(Palette.VOLTANA_GREEN))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Palette.MUTED)

	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
		t.set_stylebox(state, "OptionButton", _box(Color.WHITE if state != "hover" else Palette.BLUE_PALE, 6, Palette.LINE, 2, 12))
	t.set_stylebox("focus", "OptionButton", _outline(Palette.VOLTANA_BLUE))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "OptionButton", Palette.INK)

	t.set_icon("unchecked", "CheckBox", _check_icon(false, false))
	t.set_icon("checked", "CheckBox", _check_icon(true, false))
	t.set_icon("radio_unchecked", "CheckBox", _check_icon(false, true))
	t.set_icon("radio_checked", "CheckBox", _check_icon(true, true))
	t.set_constant("h_separation", "CheckBox", 10)

	t.set_stylebox("panel", "PopupMenu", _box(Color.WHITE, 6, Palette.LINE, 2, 8))
	t.set_stylebox("hover", "PopupMenu", _box(Palette.BLUE_PALE, 4))
	t.set_color("font_color", "PopupMenu", Palette.INK)
	t.set_color("font_hover_color", "PopupMenu", Palette.VOLTANA_BLUE)
	t.set_color("font_separator_color", "PopupMenu", Palette.MUTED)
	t.set_stylebox("separator", "HSeparator", _line(Palette.LINE))
	t.set_constant("separation", "HSeparator", 14)
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 12)
	return t


## A paper card inside a panel (a section of the A3, a mission).
static func card(fill: Color = Color.WHITE) -> StyleBoxFlat:
	return _box(fill, 8, Palette.LINE, 1, 14)


static func _box(fill: Color, radius: int, border: Color = Color.TRANSPARENT, border_top: int = 0,
		margin: int = 10) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.border_color = border
	if border_top > 0 and border != Color.TRANSPARENT:
		# Panels carry a thick blue top edge; inputs and cards a thin frame.
		b.border_width_top = border_top
		if border_top <= 2:
			b.set_border_width_all(border_top)
	b.content_margin_left = margin
	b.content_margin_right = margin
	b.content_margin_top = margin * 0.7
	b.content_margin_bottom = margin * 0.7
	return b


## A 22 px check box (blue with a white tick when checked) or radio button
## (a blue dot when checked) with a 2 px frame.
static func _check_icon(checked: bool, radio: bool) -> ImageTexture:
	const N := 22
	var img := Image.create_empty(N, N, false, Image.FORMAT_RGBA8)
	var c := (N - 1) / 2.0
	for y in N:
		for x in N:
			var p := Vector2(x, y)
			# Distance inside the shape's edge (negative: outside).
			var inside := c - (p - Vector2(c, c)).length() if radio else minf(minf(x, y), minf(N - 1 - x, N - 1 - y)) + 0.5
			var color := Color.TRANSPARENT
			if inside >= 0.0:
				color = Palette.VOLTANA_BLUE if checked else Palette.MUTED
			if inside >= 2.0:
				color = Color.WHITE
				if checked and (not radio or inside >= 5.0):
					color = Palette.VOLTANA_BLUE
				if checked and not radio and _near_tick(p):
					color = Color.WHITE
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


static func _near_tick(p: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, Vector2(5, 11), Vector2(9, 15)).distance_to(p) < 1.4 \
		or Geometry2D.get_closest_point_to_segment(p, Vector2(9, 15), Vector2(16, 6)).distance_to(p) < 1.4


static func _outline(color: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.draw_center = false
	b.set_border_width_all(2)
	b.border_color = color
	b.set_corner_radius_all(8)
	return b


static func _line(color: Color) -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = color
	l.thickness = 2
	return l
