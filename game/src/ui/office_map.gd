class_name OfficeMap
extends UiPanel
## The player map (M): a floor of the head office from above, north up, with
## its rooms, every interaction place by its Dutch name, the player (where and
## which way) and the active missions' places marked. A floor switch on top
## shows the other floors (a dot marks a floor with a mission place); at the
## lift the same switch takes you there (`lift`). The world hands it the floor
## the player is on (show_office) and the building (show_floors); it is drawn
## in code.

## A floor was chosen at the lift.
signal floor_chosen(floor_id: String)

## The map's drawing area at 1600x900.
const SIZE := Vector2(1050, 600)
const GRID_METRES := 2.0
const DOT := 11.0
const TITLE := "Kaart: %s"
const LIFT_TITLE := "Lift: kies een verdieping"
## The places' names (px).
const LABEL_SIZE := 17

## The floor in the office's (x, z) plane.
var floor_rect := Rect2(0, -16, 24, 16)
## [{id, label, at: Vector2 (x, z)}].
var places: Array[Dictionary] = []
var player: Node3D
## What stands on the floor: [{rect (x, z), room}] (Office.map_footprints).
var footprints: Array[Dictionary] = []
## The floor's rooms: [{id, name, rect (x, z), open}].
var rooms: Array[Dictionary] = []
## The building's floors: [{id, name, open, here}], lowest first.
var floors: Array[Dictionary] = []
## The floor the player is on, and the one shown.
var floor_here := ""
var floor_shown := ""
## Opened at the lift: the floor switch takes the player there.
var lift := false
var view: Control
var floor_bar: HBoxContainer
var _marked: Array[String] = []
## The places whose room is marked (room_targets).
var _room_targets: Array[String] = []
## floor id -> {rect, places, footprints, rooms} (OfficeFloors.map_plan).
var _plan_of := Callable()


func _init() -> void:
	super(TITLE % "kantoor", Vector2(0, 0))
	floor_bar = HBoxContainer.new()
	floor_bar.add_theme_constant_override("separation", 10)
	body.add_child(floor_bar)
	view = Control.new()
	view.custom_minimum_size = SIZE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_map)
	body.add_child(view)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 28)
	for item: Array in [["●  Plek", Palette.VOLTANA_BLUE], ["●  Je missie", Palette.SAFETY_ORANGE],
			["▲  Jij", Palette.GREEN_DARK], ["▦  Dicht", Palette.MUTED]]:
		legend.add_child(label(item[0], UiTheme.SMALL, item[1]))
	legend.add_child(label("M of Esc sluit de kaart", UiTheme.SMALL, Palette.MUTED))
	body.add_child(legend)
	visibility_changed.connect(func() -> void:
		if not visible:
			lift = false)


## The drawing's size (the phone's sideways screen; SIZE otherwise).
func set_view_size(px: Vector2) -> void:
	view.custom_minimum_size = px
	view.queue_redraw()


func show_office(floor_in_office: Rect2, office_places: Array[Dictionary], office_player: Node3D) -> void:
	floor_rect = floor_in_office
	places = office_places
	player = office_player


## The building: its floors, the one the player is on, and how to read any floor's plan.
func show_floors(building_floors: Array[Dictionary], here: String, plan_of: Callable) -> void:
	floors = building_floors
	floor_here = here
	floor_shown = here
	_plan_of = plan_of
	var plan: Dictionary = plan_of.call(here)
	rooms.assign(plan.get("rooms", []))


func refresh() -> void:
	_marked = mission_places(session)
	_room_targets = room_targets(session)
	if lift or floor_shown.is_empty():
		floor_shown = floor_here
	_show_plan(floor_shown)
	_fill_floor_bar()
	title_label.text = LIFT_TITLE if lift else TITLE % _floor_name(floor_shown)
	view.queue_redraw()


## Show floor `id` (the floor switch); at the lift, go there instead.
func choose_floor(id: String) -> void:
	if lift:
		if id != floor_here:
			floor_chosen.emit(id)
		return
	floor_shown = id
	refresh()


func _show_plan(id: String) -> void:
	if not _plan_of.is_valid():
		return
	var plan: Dictionary = _plan_of.call(id)
	if plan.is_empty():
		return
	if plan["rect"].size != Vector2.ZERO:
		floor_rect = plan["rect"]
	places.assign(plan["places"])
	footprints.assign(plan["footprints"])
	rooms.assign(plan["rooms"])


func _floor_name(id: String) -> String:
	for f in floors:
		if f["id"] == id:
			return f["name"]
	return "kantoor"


func _fill_floor_bar() -> void:
	clear(floor_bar)
	floor_bar.visible = floors.size() > 1
	if lift:
		floor_bar.add_child(label("Naar:", UiTheme.SMALL, Palette.MUTED))
	for i in range(floors.size() - 1, -1, -1):   # the top floor first, as on a lift's panel
		var f: Dictionary = floors[i]
		var text: String = f["name"]
		if f["id"] == floor_here:
			text += "  (hier)"
		elif not f["open"]:
			text += "  (dicht)"
		if _floor_marked(f["id"]):
			text = "● " + text
		var b := button(text, choose_floor.bind(f["id"]))
		b.disabled = not f["open"] or (lift and f["id"] == floor_here) or (not lift and f["id"] == floor_shown)
		floor_bar.add_child(b)


## Whether floor `id` holds one of the active missions' places.
func _floor_marked(id: String) -> bool:
	if (_marked.is_empty() and _room_targets.is_empty()) or not _plan_of.is_valid():
		return false
	var plan: Dictionary = _plan_of.call(id)
	return plan.get("places", []).any(func(p: Dictionary) -> bool: return p["id"] in _marked or p["id"] in _room_targets)


## The labels of floor `id`'s places.
func floor_labels(id: String) -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in (_plan_of.call(id).get("places", []) if _plan_of.is_valid() else []):
		out.append(p["label"])
	return out


## A point on the floor (x, z) in a map area: the floor fitted to the area
## keeping its shape, centred, north (-z) up.
static func project(at: Vector2, floor_in: Rect2, area_in: Rect2) -> Vector2:
	var scale := minf(area_in.size.x / floor_in.size.x, area_in.size.y / floor_in.size.y)
	var offset := area_in.position + (area_in.size - floor_in.size * scale) / 2.0
	return offset + (at - floor_in.position) * scale


## The marker ids of the active missions' places: a walk marks its stream's
## places; an observe goal its places (the briefing names them); a problem's
## mission Petra's screen once its A3 is ready for the Check (PLAN 2.10). A problem's own
## step is never marked (room_targets: its room only).
static func mission_places(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for m in s.active_missions():
		var stream := s.region.net.stream(m.goal_stream) if m.goal_type == "walk" else null
		for step in stream.steps if stream != null else []:
			out.append("place:%s.%s" % [stream.id, step.id])
		for place in m.goal_places:
			out.append("place:" + place)
		var st: ProblemState = s.region.state.get(m.goal_problem)
		if st != null and m.goal_type in ["solve", "check"] and st.phase == ProblemState.Phase.CHECK_READY:
			out.append(OfficeCheckScreen.ID)
	return out


## The places whose ROOM a mission marks: its problem's step, never more
## specific than the briefing (creator-and-minimap spec §2: room, never the place).
static func room_targets(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for m in s.active_missions():
		var p: ProblemDef = s.region.problems.get(m.goal_problem)
		if p != null:
			out.append("place:" + p.step)
	return out


## The ids of the rooms of `plan_rooms` around any of `targets` among `plan_places`.
static func rooms_around(targets: Array[String], plan_places: Array, plan_rooms: Array) -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in plan_places:
		if not p["id"] in targets:
			continue
		for room: Dictionary in plan_rooms:
			if room["rect"].has_point(p["at"]) and not room["id"] in out:
				out.append(room["id"])
	return out


## The rooms marked on the floor shown.
func marked_rooms() -> Array[String]:
	return rooms_around(_room_targets, places, rooms)


## The drawing area inside the view.
func area() -> Rect2:
	return Rect2(Vector2(24, 24), view.custom_minimum_size - Vector2(48, 48))


func to_view(at: Vector2) -> Vector2:
	return project(at, floor_rect, area())


func labels() -> Array[String]:
	var out: Array[String] = []
	for p in places:
		out.append(p["label"])
	return out


## Whether the player is on the floor shown (their arrow is drawn).
func player_shown() -> bool:
	return player != null and (floor_shown.is_empty() or floor_shown == floor_here)


func player_point() -> Vector2:
	return to_view(Vector2(player.position.x, player.position.z))


## The way the player looks, on the map (unit vector; up is north).
func player_facing() -> Vector2:
	var yaw := player.rotation.y
	return Vector2(-sin(yaw), -cos(yaw))


func _draw_map() -> void:
	var font := view.get_theme_default_font()
	var r := Rect2(to_view(floor_rect.position), to_view(floor_rect.end) - to_view(floor_rect.position))
	view.draw_rect(Rect2(Vector2.ZERO, view.custom_minimum_size), Palette.BLUE_PALE)
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
	for room in rooms:
		_draw_room(room)
	for f in footprints:
		var a := to_view(f["rect"].position)
		var box := Rect2(a, to_view(f["rect"].end) - a)
		if f["room"]:
			view.draw_rect(box, Color(Palette.BLUE_PALE, 0.6))
			view.draw_rect(box, Palette.BLUE_LIGHT, false, 3.0)
		else:
			view.draw_rect(box, Palette.LINE)
	var target_rooms := marked_rooms()
	for room in rooms:   # over the furniture
		var target: bool = room["id"] in target_rooms
		var a := to_view(room["rect"].position)
		if target:   # the mission's room: its walls in the mission's colour, nothing inside it
			view.draw_rect(Rect2(a, to_view(room["rect"].end) - a).grow(-6), Palette.SAFETY_ORANGE, false, 3.0)
		if room["open"]:
			var corner := to_view(Vector2(room["rect"].position.x, room["rect"].end.y))
			view.draw_string(font, corner + Vector2(8, -10), room["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
				Palette.SAFETY_ORANGE if target else Palette.VOLTANA_BLUE)
	view.draw_rect(r, Palette.VOLTANA_BLUE, false, 5.0)
	_draw_north(font, Vector2(view.custom_minimum_size.x - 40, 52))
	var scale_label := "%d m" % int(GRID_METRES)
	view.draw_line(Vector2(r.position.x, r.end.y + 12), Vector2(r.position.x + step, r.end.y + 12), Palette.MUTED, 2.0)
	view.draw_string(font, Vector2(r.position.x + step + 8, r.end.y + 18), scale_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.MUTED)
	var pills := label_rects(font)
	for k in places.size():
		_draw_place(font, places[k], places[k]["id"] in _marked, pills[k])
	if player_shown():
		_draw_player()


## A room: its walls; a shut room greyed and hatched; an open one named in its south-west
## corner (a shut one is named at its door).
func _draw_room(room: Dictionary) -> void:
	var rect: Rect2 = room["rect"]
	var a := to_view(rect.position)
	var box := Rect2(a, to_view(rect.end) - a)
	if room["open"]:
		view.draw_rect(box, Palette.BLUE_LIGHT, false, 2.0)
		return
	view.draw_rect(box, Color(Palette.MUTED, 0.16))
	var x := box.position.x - box.size.y
	while x < box.end.x:   # hatching, clipped to the box
		var from := Vector2(maxf(x, box.position.x), box.end.y - maxf(0.0, box.position.x - x))
		var to := Vector2(minf(x + box.size.y, box.end.x), box.position.y + maxf(0.0, x + box.size.y - box.end.x))
		view.draw_line(from, to, Color(Palette.MUTED, 0.35), 1.0)
		x += 14.0
	view.draw_rect(box, Palette.MUTED, false, 2.0)


## Where each place's name goes: below its dot, else above, else to the right or the
## left, the first spot that keeps clear of the dots and of the names placed before it.
func label_rects(font: Font) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var bounds := area()
	var dots: Array[Rect2] = []
	for p in places:
		dots.append(Rect2(to_view(p["at"]) - Vector2.ONE * DOT, Vector2.ONE * DOT * 2.0))
	for p in places:
		var at := to_view(p["at"])
		var size := font.get_string_size(p["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE) + Vector2(20, 8)
		var spots: Array[Rect2] = [
			Rect2(at + Vector2(-size.x / 2.0, DOT + 6), size), Rect2(at + Vector2(-size.x / 2.0, -DOT - 6 - size.y), size),
			Rect2(at + Vector2(DOT + 6, -size.y / 2.0), size), Rect2(at + Vector2(-DOT - 6 - size.x, -size.y / 2.0), size)]
		var chosen := Rect2()
		var least := INF
		for spot in spots:   # the first clear spot, else the least covered
			spot.position = spot.position.clamp(bounds.position, bounds.end - spot.size)
			var covered := 0.0
			for r in out + dots:
				covered += r.intersection(spot).get_area()
			if covered < least:
				chosen = spot
				least = covered
			if covered == 0.0:
				break
		out.append(chosen)
	return out


func _draw_place(font: Font, p: Dictionary, marked: bool, pill: Rect2) -> void:
	var at := to_view(p["at"])
	var colour := Palette.SAFETY_ORANGE if marked else Palette.VOLTANA_BLUE
	if marked:
		view.draw_circle(at, DOT * 2.0, Color(Palette.SAFETY_ORANGE, 0.22))
	view.draw_circle(at, DOT + 3.0, Color.WHITE)
	view.draw_circle(at, DOT, colour)
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = colour
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(pill.size.y / 2.0))
	view.draw_style_box(box, pill)
	view.draw_string(font, pill.position + Vector2(10, 4 + font.get_ascent(LABEL_SIZE)), p["label"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, Palette.INK)


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
