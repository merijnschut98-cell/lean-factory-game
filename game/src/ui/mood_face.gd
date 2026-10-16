class_name MoodFace
extends Control
## The portrait's face in a talk: a drawn head whose mouth, eyes and brows
## follow the person's mood (goed · neutraal · gespannen · moe · stil), next
## to the mood word (dialog spec §3.1). A stand-in until the characters have
## faces of their own; it never shows anything the mood word does not.

const SKIN := Color("#e8c4a0")
const HAIR := Color("#4a3a2c")

var mood := "neutraal"


func _init(side: float = 96.0) -> void:
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mood(value: String) -> void:
	mood = value
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, s * 0.42)
	var r := s * 0.3
	draw_circle(Vector2(size.x / 2.0, s * 1.05), s * 0.42, Palette.BLUE_LIGHT)
	draw_circle(c, r, SKIN)
	draw_arc(c, r, PI * 1.05, PI * 1.95, 24, HAIR, r * 0.35)
	var eye_y := c.y - r * 0.08
	var eye_dx := r * 0.38
	for side in [-1.0, 1.0]:
		var eye := Vector2(c.x + side * eye_dx, eye_y)
		if mood == "moe":
			draw_line(eye - Vector2(r * 0.12, 0), eye + Vector2(r * 0.12, 0), Palette.INK, 2.0)
		else:
			draw_circle(eye, r * 0.07, Palette.INK)
		if mood == "gespannen":
			var brow := eye + Vector2(0, -r * 0.2)
			draw_line(brow + Vector2(-side * r * 0.14, -r * 0.06), brow + Vector2(side * r * 0.14, r * 0.04), Palette.INK, 2.0)
	var mouth := Vector2(c.x, c.y + r * 0.42)
	var w := r * 0.36
	match mood:
		"goed":
			draw_arc(mouth - Vector2(0, r * 0.14), w, PI * 0.2, PI * 0.8, 12, Palette.INK, 2.0)
		"gespannen", "moe":
			draw_arc(mouth + Vector2(0, r * 0.2), w, PI * 1.25, PI * 1.75, 12, Palette.INK, 2.0)
		"stil":
			draw_line(mouth - Vector2(w * 0.35, 0), mouth + Vector2(w * 0.35, 0), Palette.INK, 2.0)
		_:
			draw_line(mouth - Vector2(w * 0.7, 0), mouth + Vector2(w * 0.7, 0), Palette.INK, 2.0)
