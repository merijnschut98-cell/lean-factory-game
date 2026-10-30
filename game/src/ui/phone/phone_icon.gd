class_name PhoneIcon
extends Button
## An app's icon on the phone's home screen: a rounded tile with the app's
## glyph drawn in code, its name under it (the button's own text), and a
## badge with the count of what is new. A tap opens the app.

const TILE := 76.0
const RADIUS := 18.0
const SIZE := Vector2(104, 118)
## Each app's tile colour (Voltana's palette).
const COLORS := {"messages": Palette.VOLTANA_GREEN, "missions": Palette.SAFETY_ORANGE, "notes": Color("#f2c94c"),
	"map": Palette.BLUE_LIGHT, "people": Color("#7b61c9"), "codex": Palette.GREEN_DARK, "settings": Palette.MUTED}
const BADGE := Color("#e5484d")

var app_id := ""
var badge := 0:
	set(value):
		badge = value
		queue_redraw()


func _init(id: String, name_text: String) -> void:
	app_id = id
	text = name_text
	flat = true
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_NONE
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_font_size_override("font_size", 15)
	var below := StyleBoxEmpty.new()
	below.content_margin_top = TILE + 8   # the name sits under the tile
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		add_theme_stylebox_override(state, below)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Color.WHITE)


func _draw() -> void:
	var tile := Rect2(Vector2((size.x - TILE) / 2.0, 2), Vector2(TILE, TILE))
	var box := StyleBoxFlat.new()
	box.bg_color = COLORS.get(app_id, Palette.VOLTANA_BLUE)
	if is_hovered() or button_pressed:
		box.bg_color = box.bg_color.lightened(0.15)
	box.set_corner_radius_all(int(RADIUS))
	draw_style_box(box, tile)
	_glyph(tile.grow(-18), Color.WHITE)
	if badge > 0:
		var at := tile.position + Vector2(TILE - 4, 4)
		draw_circle(at, 13.0, BADGE)
		var font := get_theme_default_font()
		var count := str(badge) if badge < 10 else "9+"
		var w := font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, at + Vector2(-w / 2.0, 5), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


## The app's glyph in white, inside `r`: simple shapes, read at a glance.
func _glyph(r: Rect2, c: Color) -> void:
	var w := 3.5
	match app_id:
		"messages":   # a speech bubble
			var bubble := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.72))
			_rounded(bubble, c, 9)
			draw_colored_polygon(PackedVector2Array([bubble.position + Vector2(8, bubble.size.y - 1),
				bubble.position + Vector2(22, bubble.size.y - 1), bubble.position + Vector2(6, r.size.y)]), c)
		"missions":   # a clipboard with ticks
			_rounded(r, c, 5)
			for i in 3:
				var y := r.position.y + 10 + i * 12
				draw_line(Vector2(r.position.x + 7, y), Vector2(r.position.x + 11, y + 4), COLORS["missions"], w)
				draw_line(Vector2(r.position.x + 11, y + 4), Vector2(r.position.x + 17, y - 3), COLORS["missions"], w)
				draw_line(Vector2(r.position.x + 22, y + 1), Vector2(r.end.x - 6, y + 1), COLORS["missions"], 3)
		"notes":   # a notepad with lines
			_rounded(r, c, 4)
			for i in 4:
				var y := r.position.y + 9 + i * 9
				draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y), COLORS["notes"].darkened(0.3), 2.5)
		"map":   # a folded map with a pin
			var third := r.size.x / 3.0
			var pts := PackedVector2Array([r.position + Vector2(0, 5), r.position + Vector2(third, 0),
				r.position + Vector2(2 * third, 5), r.position + Vector2(r.size.x, 0), r.end, r.end - Vector2(third, 5),
				r.end - Vector2(2 * third, 0), r.position + Vector2(0, r.size.y - 5)])
			draw_colored_polygon(pts, c)
			draw_circle(r.get_center() - Vector2(0, 4), 7.0, COLORS["map"])
			draw_circle(r.get_center() - Vector2(0, 4), 3.0, c)
		"people":   # two people
			for k: Array in [[Vector2(-8, 0), 0.8], [Vector2(8, 2), 1.0]]:
				var at: Vector2 = r.get_center() + k[0]
				draw_circle(at - Vector2(0, 9), 7.0 * k[1], c)
				draw_circle(at + Vector2(0, 14), 12.0 * k[1], c)
		"codex":   # an open book
			var mid := r.position.x + r.size.x / 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.position.y + 4), Vector2(mid - 2, r.position.y + 8),
				Vector2(mid - 2, r.end.y), Vector2(r.position.x, r.end.y - 4)]), c)
			draw_colored_polygon(PackedVector2Array([Vector2(mid + 2, r.position.y + 8), Vector2(r.end.x, r.position.y + 4),
				Vector2(r.end.x, r.end.y - 4), Vector2(mid + 2, r.end.y)]), c)
		"settings":   # a gear
			var centre := r.get_center()
			for i in 8:
				var a := i * TAU / 8.0
				draw_line(centre, centre + Vector2(cos(a), sin(a)) * r.size.x * 0.5, c, 7)
			draw_circle(centre, r.size.x * 0.36, c)
			draw_circle(centre, r.size.x * 0.14, COLORS["settings"])


func _rounded(r: Rect2, c: Color, radius: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	box.set_corner_radius_all(radius)
	draw_style_box(box, r)
