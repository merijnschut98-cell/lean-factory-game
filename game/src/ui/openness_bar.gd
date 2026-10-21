class_name OpennessBar
extends Control
## The dialog meter's main bar (dialog spec §3.7, Merijn 2026-10-15): a
## horizontal bar that FILLS with the person's openness, its five bands named
## under it, so colour is never the only signal. It never shows a number: the
## change of a reply is the arrow beside it (TalkView), the band word says
## where it stands. The fill slides to a new value.

## Band colours, from closed (red) to thinking along (green), always with the
## band's name written under the bar.
const COLORS: Array[Color] = [Color("#d64545"), Color("#f07b22"), Color("#e5b821"), Color("#7fcf6a"), Color("#1f9a57")]
const HEIGHT := 22.0
const SLIDE_SECONDS := 0.45

## Openness 0..100 as drawn now (it slides toward `target`).
var shown := 0.0
var target := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(420, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Set the openness; `animate` slides the fill there.
func set_openness(value: float, animate: bool = true) -> void:
	target = clampf(value, 0.0, 100.0)
	if not animate or not is_inside_tree():
		shown = target
		queue_redraw()
		return
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		shown = v
		queue_redraw(), shown, target, SLIDE_SECONDS)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(size.x, HEIGHT))
	draw_rect(r, Palette.LINE)
	var fill := Rect2(r.position, Vector2(r.size.x * shown / 100.0, r.size.y))
	draw_rect(fill, COLORS[maxi(0, Dialog.band_of(roundi(shown)))])
	for floor_value: int in Dialog.BANDS.slice(1):
		var x: float = r.size.x * floor_value / 100.0
		draw_line(Vector2(x, 0), Vector2(x, HEIGHT), Palette.PAPER, 2.0)
	draw_rect(r, Palette.MUTED, false, 1.0)
