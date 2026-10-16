class_name Minimap
extends Control
## The minimap (PLAN 2.1b; creator-and-minimap spec §2): Ruud's paper floor plan as a
## round cut-out in the bottom-right corner. Walls and rooms (open ones paper white, shut
## ones hatched), room names upright, the stairs and the lift as symbols, people as grey
## dots all alike, the player as an arrowhead in the middle, and where the accepted
## missions are: the main one an orange diamond (a ring round a person) or, out of view,
## an arrow on the rim with the walking distance or the floor to go to; a side mission a
## small hollow ring or a notch. Where, never what: nothing else is drawn (`layout` lists
## every item, so a test can check). It turns with the camera unless the setting says
## north-up. Fed by OfficeMinimap; drawn in code, nothing animates but the 1 s fade of a
## target the player has reached.

## Size and place (px at 1600 × 900) and scale: 28 m of floor across (estimate: one room
## and its neighbours).
const DIAMETER := 220.0
const MARGIN := 20.0
const METRES := 28.0
## A target's marker fades out (and back in) over this long (s).
const FADE_S := 1.0
## A person target fades when the player is this close (m): E's reach is a step away.
const NEAR_PERSON := 3.0
const PAPER := Color("#f4f1ea")
const INK := Color(0.29, 0.30, 0.32)
const HATCH := Color(0.29, 0.30, 0.32, 0.35)
const SIDE := Color(0.42, 0.52, 0.62)
const SEGMENTS := 48
const NAME_SIZE := 9
## The settings (user://settings.cfg, section "minimap"): shown, and turning with the
## camera; both on by default.
const SECTION := "minimap"
const SHOWN := "shown"
const TURNS := "turns"
## The items a layout may hold (spec §2.6: where, never what).
const ITEM_KINDS: Array[String] = ["wall", "room", "room_name", "stairs", "lift", "person", "player", "target",
	"arrow", "notch", "north"]

## The floor's plan: {rect: Rect2, rooms: [{id, name, rect, open}], places: [{id, at}]}
## (x, z in office space).
var plan := {}
## The player on the floor (x, z), their yaw and the camera's.
var at := Vector2.ZERO
var facing := 0.0
var camera_yaw := 0.0
## Turning with the camera (the setting); off: north-up.
var turns := true
## The people present on this floor (x, z).
var people_at: Array[Vector2] = []
## The targets on show: {id, main, kind ("room" | "person" | "seam"), at (x, z),
## room_rect (Rect2, for a room), toward (x, z: where the walking route first heads),
## distance (m, rounded; 0 for none), text ("" or the floor to go to), reached (bool)}.
var targets: Array[Dictionary] = []
## A target's fade (id → alpha 0..1).
var alpha := {}


func _init() -> void:
	name = "Minimap"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * DIAMETER
	size = custom_minimum_size
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -DIAMETER - MARGIN
	offset_top = -DIAMETER - MARGIN
	offset_right = -MARGIN
	offset_bottom = -MARGIN


## The settings (`path`: user://settings.cfg; tests point it elsewhere).
static func setting(key: String, path: String = SessionLog.SETTINGS) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return true
	var v: Variant = config.get_value(SECTION, key, true)
	return v if v is bool else true


static func set_setting(key: String, on: bool, path: String = SessionLog.SETTINGS) -> String:
	var config := ConfigFile.new()
	config.load(path)   # a missing file starts empty
	config.set_value(SECTION, key, on)
	var err := config.save(path)
	return "" if err == OK else "instellingen niet bewaard (%s)" % error_string(err)


## The map's turn on screen: the camera's yaw while it turns with the camera (screen-up is
## where W walks), else 0 (north-up).
func map_rotation() -> float:
	return camera_yaw if turns else 0.0


## Pixels per metre.
static func scale_px() -> float:
	return DIAMETER / METRES


func centre() -> Vector2:
	return Vector2.ONE * DIAMETER / 2.0


## A floor point (x, z) on the map.
func to_map(p: Vector2) -> Vector2:
	return centre() + (p - at).rotated(map_rotation()) * scale_px()


## Whether a floor point is inside the circle.
func shows(p: Vector2) -> bool:
	return p.distance_to(at) <= METRES / 2.0


## One frame of the fades: a reached target fades out over FADE_S, others back in.
## Nothing loops: a steady state never changes.
func step(dt: float) -> void:
	var changed := false
	for t in targets:
		var a: float = alpha.get(t["id"], 1.0)
		var want := 0.0 if t["reached"] else 1.0
		var next := move_toward(a, want, dt / FADE_S)
		changed = changed or next != a
		alpha[t["id"]] = next
	if changed:
		queue_redraw()


## Everything the map draws, in drawing order: [{kind (ITEM_KINDS), ...}] in map pixels.
func layout() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var circle := _circle(DIAMETER / 2.0 - 1.0)
	var floor_rect: Rect2 = plan.get("rect", Rect2())
	for poly in Geometry2D.intersect_polygons(_rect_poly(floor_rect), circle):
		out.append({"kind": "wall", "points": poly})
	for room: Dictionary in plan.get("rooms", []):
		for poly in Geometry2D.intersect_polygons(_rect_poly(room["rect"]), circle):
			out.append({"kind": "room", "points": poly, "open": room["open"]})
		var mid: Vector2 = (room["rect"] as Rect2).get_center()
		if shows(mid):
			var box := Rect2(to_map(room["rect"].position), Vector2.ZERO)
			for corner in _rect_poly(room["rect"]):
				box = box.expand(corner)
			out.append({"kind": "room_name", "at": to_map(mid), "text": str(room["name"]), "width": box.size.x})
	for p: Dictionary in plan.get("places", []):
		var kind := "stairs" if str(p["id"]).begins_with("stairs") else ("lift" if p["id"] == "lift" else "")
		if not kind.is_empty() and shows(p["at"]):
			out.append({"kind": kind, "at": to_map(p["at"]), "up": p["id"] == "stairs_up"})
	for p in people_at:
		if shows(p):
			out.append({"kind": "person", "at": to_map(p)})
	for t in targets:
		var a: float = alpha.get(t["id"], 1.0)
		if shows(t["at"]):
			out.append({"kind": "target", "at": to_map(t["at"]), "main": t["main"], "person": t["kind"] == "person",
				"alpha": a, "text": str(t["text"]) if t["main"] else ""})
			continue
		var dir: Vector2 = (t["toward"] - at).rotated(map_rotation()).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		out.append({"kind": "arrow" if t["main"] else "notch", "at": centre() + dir * (DIAMETER / 2.0 - 12.0),
			"dir": dir, "main": t["main"], "alpha": a, "text": _arrow_text(t) if t["main"] else ""})
	out.append({"kind": "player", "at": centre(), "dir": Vector2(-sin(facing), -cos(facing)).rotated(map_rotation())})
	out.append({"kind": "north", "at": centre() + Vector2.UP.rotated(map_rotation()) * (DIAMETER / 2.0 - 9.0)})
	return out


static func _arrow_text(t: Dictionary) -> String:
	if not str(t["text"]).is_empty():
		return t["text"]
	return "%d m" % int(t["distance"]) if int(t["distance"]) > 0 else ""


## A route's length rounded to 5 m, never below 5 m.
static func rounded(metres: float) -> int:
	return maxi(5, int(roundf(metres / 5.0)) * 5)


func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([to_map(r.position), to_map(Vector2(r.end.x, r.position.y)), to_map(r.end),
		to_map(Vector2(r.position.x, r.end.y))])


func _circle(radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in SEGMENTS:
		out.append(centre() + Vector2.from_angle(TAU * k / SEGMENTS) * radius)
	return out


func _draw() -> void:
	var font := get_theme_default_font()
	var r := DIAMETER / 2.0
	draw_colored_polygon(_circle(r), PAPER)
	draw_line(centre() + Vector2(-r, r * 0.18), centre() + Vector2(r, -r * 0.18), Color(INK, 0.07), 1.0)   # the fold
	for item in layout():
		match item["kind"]:
			"wall":
				_outline(item["points"], INK, 1.5)
			"room":
				if not item["open"]:
					_hatch(item["points"])
				_outline(item["points"], INK, 1.5)
			"room_name":
				_room_name(font, item)
			"stairs":
				var a: Vector2 = item["at"]
				for k in 4:
					draw_line(a + Vector2(-6, -6 + k * 4), a + Vector2(6, -6 + k * 4), INK, 1.0)
				draw_rect(Rect2(a - Vector2(6, 8), Vector2(12, 16)), INK, false, 1.0)
			"lift":
				var box := Rect2(item["at"] - Vector2(6, 6), Vector2(12, 12))
				draw_rect(box, INK, false, 1.0)
				draw_line(box.position, box.end, INK, 1.0)
				draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), INK, 1.0)
			"person":
				draw_circle(item["at"], 2.5, INK)
			"target":
				_target(font, item)
			"arrow", "notch":
				_rim(font, item)
			"player":
				var d: Vector2 = item["dir"]
				var c: Vector2 = item["at"]
				draw_colored_polygon(PackedVector2Array([c + d * 9, c + d.orthogonal() * 6 - d * 5, c - d * 2,
					c - d.orthogonal() * 6 - d * 5]), Palette.GREEN_DARK)
			"north":
				draw_string(font, item["at"] + Vector2(-4, 5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.VOLTANA_BLUE)
	draw_arc(centre(), r - 1.0, 0, TAU, SEGMENTS * 2, Palette.VOLTANA_BLUE, 2.0, true)


## A room's name, upright, in one line or two as the room is wide on screen; left out
## when it does not fit (the M map names every room).
func _room_name(font: Font, item: Dictionary) -> void:
	var text := tr(str(item["text"])).to_upper()
	var room_w: float = item["width"] - 6.0
	var lines: Array[String] = [text]
	if _text_w(font, text) > room_w and text.contains(" "):
		var words := text.split(" ")
		var half := words.size() / 2
		lines = [" ".join(words.slice(0, half)), " ".join(words.slice(half))]
	if lines.any(func(l: String) -> bool: return _text_w(font, l) > room_w):
		return
	for k in lines.size():
		var at: Vector2 = item["at"] + Vector2(-_text_w(font, lines[k]) / 2.0, 4 + (k - (lines.size() - 1) / 2.0) * 11)
		draw_string(font, at, lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, Color(INK, 0.8))


static func _text_w(font: Font, text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x


func _outline(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _hatch(points: PackedVector2Array) -> void:
	var d := DIAMETER
	var x := -d
	while x < d:
		for seg in Geometry2D.clip_polyline_with_polygon(PackedVector2Array([Vector2(x, d), Vector2(x + d, 0)]), points):
			draw_polyline(seg, HATCH, 1.0)
		x += 7.0


func _target(font: Font, item: Dictionary) -> void:
	var color := Color(Palette.SAFETY_ORANGE if item["main"] else SIDE, item["alpha"])
	var c: Vector2 = item["at"]
	if not str(item["text"]).is_empty():
		_label(font, c, item["text"], c.y > centre().y, item["alpha"])
	if item["person"] or not item["main"]:
		draw_arc(c, 6.0 if item["main"] else 3.5, 0, TAU, 24, color, 2.0, true)
	else:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]), color)


func _rim(font: Font, item: Dictionary) -> void:
	var d: Vector2 = item["dir"]
	var c: Vector2 = item["at"]
	if item["kind"] == "notch":
		draw_line(c - d * 3, c + d * 5, Color(SIDE, item["alpha"]), 3.0)
		return
	var color := Color(Palette.SAFETY_ORANGE, item["alpha"])
	draw_colored_polygon(PackedVector2Array([c + d * 9, c + d.orthogonal() * 7 - d * 4, c - d.orthogonal() * 7 - d * 4]), color)
	var text: String = item["text"]
	if text.is_empty():
		return
	_label(font, c - d * 14.0, text, d.y > 0.0, item["alpha"])


## A short text by a marker or an arrow (the distance, the floor to go to), kept inside
## the circle: under the point, or over it when `above`.
func _label(font: Font, at: Vector2, text: String, above: bool, a: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var p := Vector2(clampf(at.x - w / 2.0, 14.0, DIAMETER - 14.0 - w), at.y + (-8.0 if above else 18.0))
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, PAPER)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(INK, a))
