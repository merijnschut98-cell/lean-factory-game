class_name TraceLine
extends Control
## "Verloop": openness over a talk's moves as a small line (dialog spec §3.7),
## its band floors as faint lines. No axis, no numbers: it shows where a talk
## rose and where it fell, so the summary card can ask "waar ging het mis?".
## With labels, each move's name sits under its own point (in two staggered
## rows, so neighbours do not overlap).

const LABEL_SIZE := 13
## The height of one row of labels under the line.
const LABEL_ROW := 16.0
## With labels, the line keeps this far (px) from the sides, so the first and
## last name fit under their points.
const LABEL_INSET := 44.0

var trace: Array = []
## The moves made, one per point after the start ([] for none).
var labels: Array[String] = []


func _init(min_size: Vector2 = Vector2(150, 34)) -> void:
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_trace(values: Array, move_labels: Array[String] = []) -> void:
	trace = values.duplicate()
	labels = move_labels.duplicate()
	queue_redraw()


## The line's own area: the control less the label rows under it.
func plot_size() -> Vector2:
	return Vector2(size.x, size.y - (2 * LABEL_ROW if not labels.is_empty() else 0.0))


## Where move `i` of the trace sits in `area` (x by move, y by openness).
static func point(i: int, count: int, value: float, area: Vector2) -> Vector2:
	var x := 0.0 if count <= 1 else area.x * i / float(count - 1)
	return Vector2(x, area.y * (1.0 - clampf(value, 0.0, 100.0) / 100.0))


func _draw() -> void:
	var area := plot_size()
	for floor_value: int in Dialog.BANDS:
		var y := area.y * (1.0 - floor_value / 100.0)
		draw_line(Vector2(0, y), Vector2(area.x, y), Color(Palette.LINE, 0.6), 1.0)
	if trace.size() < 2:
		return
	var inset := LABEL_INSET if not labels.is_empty() else 0.0
	var points := PackedVector2Array()
	for i in trace.size():
		points.append(point(i, trace.size(), trace[i], area - Vector2(2 * inset, 0)) + Vector2(inset, 0))
	draw_polyline(points, Palette.VOLTANA_BLUE, 2.0, true)
	for i in trace.size():
		draw_circle(points[i], 2.5, OpennessBar.COLORS[maxi(0, Dialog.band_of(roundi(trace[i])))])
	_draw_labels(points, area)


## Each move's name under its point, alternating rows, kept inside the control.
func _draw_labels(points: PackedVector2Array, area: Vector2) -> void:
	var font := get_theme_default_font()
	for i in mini(labels.size(), points.size() - 1):
		var x := points[i + 1].x
		var width := font.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		var left := clampf(x - width / 2.0, 0.0, maxf(0.0, size.x - width))
		var y := area.y + LABEL_ROW * (i % 2 + 1) - 3.0
		draw_line(Vector2(x, points[i + 1].y), Vector2(x, y - LABEL_SIZE + 2), Color(Palette.LINE, 0.8), 1.0)
		draw_string(font, Vector2(left, y), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, Palette.MUTED)
