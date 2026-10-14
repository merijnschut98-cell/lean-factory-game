class_name OfficeMap
extends UiPanel
## The player map (M): the office floor from above, north up, with every
## interaction place by its Dutch name, the player (where and which way) and
## the active missions' places marked. The world hands it the floor, the
## places and the player (show_office); it is drawn in code.

## The map's drawing area at 1600x900 (the floor is 3:2).
const SIZE := Vector2(1050, 660)
const GRID_METRES := 2.0
const DOT := 11.0

## The floor in the office's (x, z) plane.
var floor_rect := Rect2(0, -16, 24, 16)
## [{id, label, at: Vector2 (x, z)}].
var places: Array[Dictionary] = []
var player: Node3D
## What stands on the floor: [{rect (x, z), room}] (Office.map_footprints).
var footprints: Array[Dictionary] = []
var view: Control
var _marked: Array[String] = []


func _init() -> void:
	super("Kaart: kantoor Verbindingen", Vector2(0, 0))
	view = Control.new()
	view.custom_minimum_size = SIZE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_map)
	body.add_child(view)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 28)
	for item: Array in [["●  Plek", Palette.VOLTANA_BLUE], ["●  Je missie", Palette.SAFETY_ORANGE],
			["▲  Jij", Palette.GREEN_DARK]]:
		legend.add_child(label(item[0], UiTheme.SMALL, item[1]))
	legend.add_child(label("M of Esc sluit de kaart", UiTheme.SMALL, Palette.MUTED))
	body.add_child(legend)


func show_office(floor_in_office: Rect2, office_places: Array[Dictionary], office_player: Node3D) -> void:
	floor_rect = floor_in_office
	places = office_places
	player = office_player


func refresh() -> void:
	_marked = mission_places(session)
	view.queue_redraw()


## A point on the floor (x, z) in a map area: the floor fitted to the area
## keeping its shape, centred, north (-z) up.
static func project(at: Vector2, floor_in: Rect2, area_in: Rect2) -> Vector2:
	var scale := minf(area_in.size.x / floor_in.size.x, area_in.size.y / floor_in.size.y)
	var offset := area_in.position + (area_in.size - floor_in.size * scale) / 2.0
	return offset + (at - floor_in.position) * scale


## The marker ids of the active missions' places: a walk marks its stream's
## places; an observe goal its places; a problem marks the place its
## briefing sends you to and, to check or solve it, the obeya wall.
static func mission_places(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for m in s.active_missions():
		var stream := s.region.net.stream(m.goal_stream) if m.goal_type == "walk" else null
		for step in stream.steps if stream != null else []:
			out.append("place:%s.%s" % [stream.id, step.id])
		for place in m.goal_places:
			out.append("place:" + place)
		var p: ProblemDef = s.region.problems.get(m.goal_problem)
		if p != null:
			out.append("place:" + p.step)
			if m.goal_type in ["solve", "check"]:
				out.append("obeya")
	return out


## The drawing area inside the view.
func area() -> Rect2:
	return Rect2(Vector2(24, 24), SIZE - Vector2(48, 48))


func to_view(at: Vector2) -> Vector2:
	return project(at, floor_rect, area())


func labels() -> Array[String]:
	var out: Array[String] = []
	for p in places:
		out.append(p["label"])
	return out


func player_point() -> Vector2:
	return to_view(Vector2(player.position.x, player.position.z))


## The way the player looks, on the map (unit vector; up is north).
func player_facing() -> Vector2:
	var yaw := player.rotation.y
	return Vector2(-sin(yaw), -cos(yaw))


func _draw_map() -> void:
	var font := view.get_theme_default_font()
	var r := Rect2(to_view(floor_rect.position), to_view(floor_rect.end) - to_view(floor_rect.position))
	view.draw_rect(Rect2(Vector2.ZERO, SIZE), Palette.BLUE_PALE)
	view.draw_rect(r, Color.WHITE)
	var step := r.size.x / floor_rect.size.x * GRID_METRES
	var x := r.position.x + step
	while x < r.end.x - 1:
		view.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Palette.LINE, 1.0)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 1:
		view.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Palette.LINE, 1.0)
		y += step
	for f in footprints:
		var a := to_view(f["rect"].position)
		var box := Rect2(a, to_view(f["rect"].end) - a)
		if f["room"]:
			view.draw_rect(box, Color(Palette.BLUE_PALE, 0.6))
			view.draw_rect(box, Palette.BLUE_LIGHT, false, 3.0)
		else:
			view.draw_rect(box, Palette.LINE)
	view.draw_rect(r, Palette.VOLTANA_BLUE, false, 5.0)
	_draw_north(font, Vector2(SIZE.x - 40, 52))
	var scale_label := "%d m" % int(GRID_METRES)
	view.draw_line(Vector2(r.position.x, r.end.y + 12), Vector2(r.position.x + step, r.end.y + 12), Palette.MUTED, 2.0)
	view.draw_string(font, Vector2(r.position.x + step + 8, r.end.y + 18), scale_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.MUTED)
	for p in places:
		_draw_place(font, p, p["id"] in _marked)
	if player != null:
		_draw_player()


func _draw_place(font: Font, p: Dictionary, marked: bool) -> void:
	var at := to_view(p["at"])
	var colour := Palette.SAFETY_ORANGE if marked else Palette.VOLTANA_BLUE
	if marked:
		view.draw_circle(at, DOT * 2.0, Color(Palette.SAFETY_ORANGE, 0.22))
	view.draw_circle(at, DOT + 3.0, Color.WHITE)
	view.draw_circle(at, DOT, colour)
	var text: String = p["label"]
	var font_size := 19
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pill := Rect2(at + Vector2(-text_size.x / 2.0 - 10, DOT + 8), text_size + Vector2(20, 8))
	var bounds := area()
	pill.position.x = clampf(pill.position.x, bounds.position.x, bounds.end.x - pill.size.x)
	if pill.end.y > bounds.end.y:
		pill.position.y = at.y - DOT - 8 - pill.size.y
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = colour
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(pill.size.y / 2.0))
	view.draw_style_box(box, pill)
	view.draw_string(font, pill.position + Vector2(10, 4 + font.get_ascent(font_size)), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.INK)


func _draw_player() -> void:
	var at := player_point()
	var ahead := player_facing()
	var side := Vector2(-ahead.y, ahead.x)
	view.draw_circle(at, 30.0, Color(Palette.VOLTANA_GREEN, 0.18))
	var tip := at + ahead * 22.0
	var points := PackedVector2Array([tip, at - ahead * 10.0 + side * 13.0, at - ahead * 4.0, at - ahead * 10.0 - side * 13.0])
	view.draw_colored_polygon(points, Palette.GREEN_DARK)
	view.draw_polyline(points + PackedVector2Array([tip]), Color.WHITE, 2.0)


func _draw_north(font: Font, at: Vector2) -> void:
	view.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -16), at + Vector2(9, 8), at + Vector2(-9, 8)]), Palette.VOLTANA_BLUE)
	view.draw_string(font, at + Vector2(-7, 32), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.VOLTANA_BLUE)
