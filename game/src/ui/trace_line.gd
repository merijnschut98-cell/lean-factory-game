class_name TraceLine
extends Control
## "Verloop": openness over a talk's moves as a small line (dialog spec §3.7),
## its band floors as faint lines. No axis, no numbers: it shows where a talk
## rose and where it fell, so the summary card can ask "waar ging het mis?".

var trace: Array = []


func _init(min_size: Vector2 = Vector2(150, 34)) -> void:
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_trace(values: Array) -> void:
	trace = values.duplicate()
	queue_redraw()


## Where move `i` of the trace sits in `area` (x by move, y by openness).
static func point(i: int, count: int, value: float, area: Vector2) -> Vector2:
	var x := 0.0 if count <= 1 else area.x * i / float(count - 1)
	return Vector2(x, area.y * (1.0 - clampf(value, 0.0, 100.0) / 100.0))


func _draw() -> void:
	for floor_value: int in Dialog.BANDS:
		var y := size.y * (1.0 - floor_value / 100.0)
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(Palette.LINE, 0.6), 1.0)
	if trace.size() < 2:
		return
	var points := PackedVector2Array()
	for i in trace.size():
		points.append(point(i, trace.size(), trace[i], size))
	draw_polyline(points, Palette.VOLTANA_BLUE, 2.0, true)
	for i in trace.size():
		draw_circle(points[i], 2.5, OpennessBar.COLORS[maxi(0, Dialog.band_of(roundi(trace[i])))])
