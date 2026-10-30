class_name MoodFace
extends Control
## The portrait's face in a talk: a drawn head whose mouth and brows follow
## the meter's band (dialog spec §3.7, the second layer of cues): Dicht a
## closed mouth and eyes away, Op z'n hoede a frown, Luistert neutral, Open a
## soft smile, Denkt mee a smile with the brows up. The mood word of the day
## only tires the eyes ("moe"). A stand-in until the characters have faces of
## their own; it never shows anything the band and the mood word do not.

const SKIN := Color("#e8c4a0")
const HAIR := Color("#4a3a2c")
## The mouth per band, from below Dicht (-1) to Denkt mee (4).
const MOUTHS: Array[String] = ["closed", "closed", "frown", "flat", "soft_smile", "smile"]

## The meter's band (Dialog.band_of): -1 below Dicht … 4 Denkt mee.
var band := 1
var mood := "neutraal"


func _init(side: float = 96.0) -> void:
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_state(of_band: int, of_mood: String) -> void:
	band = of_band
	mood = of_mood
	queue_redraw()


## The mouth a band shows: closed · frown · flat · soft_smile · smile.
static func mouth_for(of_band: int) -> String:
	return MOUTHS[clampi(of_band, -1, 4) + 1]


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, s * 0.42)
	var r := s * 0.3
	draw_circle(Vector2(size.x / 2.0, s * 1.05), s * 0.42, Palette.BLUE_LIGHT)
	draw_circle(c, r, SKIN)
	draw_arc(c, r, PI * 1.05, PI * 1.95, 24, HAIR, r * 0.35)
	var mouth := mouth_for(band)
	var eye_y := c.y - r * 0.08
	var eye_dx := r * 0.38
	var look := Vector2(r * 0.08, 0) if mouth == "closed" else Vector2.ZERO  # eyes away
	for side in [-1.0, 1.0]:
		var eye := Vector2(c.x + side * eye_dx, eye_y)
		if mood == "moe":
			draw_line(eye - Vector2(r * 0.12, 0), eye + Vector2(r * 0.12, 0), Palette.INK, 2.0)
		else:
			draw_circle(eye + look, r * 0.07, Palette.INK)
		var brow := eye + Vector2(0, -r * 0.22)
		match mouth:
			"closed", "frown":  # drawn together
				draw_line(brow + Vector2(-side * r * 0.14, -r * 0.06), brow + Vector2(side * r * 0.14, r * 0.04), Palette.INK, 2.0)
			"smile":  # raised
				draw_line(brow + Vector2(-r * 0.12, -r * 0.06), brow + Vector2(r * 0.12, -r * 0.06), Palette.INK, 2.0)
	var at := Vector2(c.x, c.y + r * 0.42)
	var w := r * 0.36
	match mouth:
		"smile":
			draw_arc(at - Vector2(0, r * 0.16), w, PI * 0.15, PI * 0.85, 12, Palette.INK, 2.0)
		"soft_smile":
			draw_arc(at - Vector2(0, r * 0.3), w * 1.2, PI * 0.32, PI * 0.68, 12, Palette.INK, 2.0)
		"frown":
			draw_arc(at + Vector2(0, r * 0.2), w, PI * 1.25, PI * 1.75, 12, Palette.INK, 2.0)
		"closed":
			draw_line(at - Vector2(w * 0.35, 0), at + Vector2(w * 0.35, 0), Palette.INK, 2.0)
		_:
			draw_line(at - Vector2(w * 0.7, 0), at + Vector2(w * 0.7, 0), Palette.INK, 2.0)
