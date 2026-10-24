class_name PaperSheet
extends StyleBox
## A panel drawn as a Voltana object (PLAN 2.10: every panel that stays a panel is drawn
## as a thing from the office, never a game window): a ruled sheet of off-white paper,
## held on a hardboard clipboard with its metal clip at the top. The A3 is this sheet,
## at your desk or taken from anywhere as your clipboard.

## The paper: off-white, as office paper looks under the lamps (not pure white).
var paper := Color("#f6f3e8")
## The clipboard's hardboard around the sheet; `clipboard` false draws the sheet alone.
var board := Color("#8b6a45")
var clipboard := true
## A ruled line every this many pixels (0: none), under a printed header band.
var rule_every := 30
var rule_color := Color(0.42, 0.62, 0.82, 0.32)
## The red margin line of a writing pad.
var margin_color := Color(0.85, 0.35, 0.33, 0.42)

## The board's rim around the sheet, and the clip's room above it (px).
const RIM := 16
const CLIP_ROOM := 34
const CLIP := Vector2(220, 46)
## Where the ruling starts under the sheet's top (the title sits above it).
const HEADER := 64
const MARGIN_LINE := 30


func _init() -> void:
	content_margin_left = RIM + MARGIN_LINE + 18
	content_margin_right = RIM + 28
	content_margin_top = RIM + CLIP_ROOM + 18
	content_margin_bottom = RIM + 24


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var sheet := rect
	if clipboard:
		flat(board, 18, 10).draw(to_canvas_item, rect)
		sheet = rect.grow_individual(-RIM, -RIM - CLIP_ROOM, -RIM, -RIM)
	flat(paper, 3, 4).draw(to_canvas_item, sheet)
	if rule_every > 0:
		var y := sheet.position.y + HEADER
		while y < sheet.end.y - 8:
			RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(sheet.position.x + 6, y),
				Vector2(sheet.end.x - 6, y), rule_color, 1.0)
			y += rule_every
	var x := sheet.position.x + MARGIN_LINE
	RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(x, sheet.position.y + 4), Vector2(x, sheet.end.y - 4),
		margin_color, 1.5)
	if clipboard:
		_clip(to_canvas_item, rect)


## The metal clip over the sheet's top edge: a plate, its rivets and the lever.
func _clip(ci: RID, rect: Rect2) -> void:
	var at := Rect2(Vector2(rect.get_center().x - CLIP.x / 2.0, rect.position.y + 6), CLIP)
	flat(Color("#b9bcc2"), 10, 3).draw(ci, at)
	flat(Color("#d9dbe0"), 8, 0).draw(ci, at.grow_individual(-8, -6, -8, -CLIP.y / 2.0))
	for dx in [-CLIP.x * 0.36, CLIP.x * 0.36]:
		RenderingServer.canvas_item_add_circle(ci, at.get_center() + Vector2(dx, 6), 5.0, Color("#8e9298"))
	flat(Color("#a3a7ad"), 6, 0).draw(ci, Rect2(at.get_center() + Vector2(-46, -at.size.y / 2.0 - 4), Vector2(92, 12)))


static func flat(fill: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.shadow_size = shadow
	b.shadow_color = Color(0, 0, 0, 0.28)
	b.shadow_offset = Vector2(0, shadow / 2.0)
	b.anti_aliasing = true
	return b
