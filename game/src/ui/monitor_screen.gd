class_name MonitorScreen
extends StyleBox
## A panel drawn as Petra's monitor at Meetdata (PLAN 2.10): a dark bezel with its chin
## and power light around a screen with her spreadsheet open: the column letters, the row
## numbers and the grid, the sheet's green edge. The Check is read there, on her screen.

var bezel := Color("#1d1f24")
var screen := Color("#fbfbf8")
## The spreadsheet's row height (px; 0: no grid).
var grid := 28
var grid_color := Color(0.80, 0.82, 0.84, 0.55)
var header := Color("#eceef1")
var header_ink := Color("#6b7079")
## The sheet's tab colour (the green of the spreadsheet she uses).
var accent := Color("#2f7d4f")

const BEZEL := 12
const CHIN := 20
## The column letters above the cells, the row numbers beside them.
const COLUMNS := 18
const GUTTER := 30
const COLUMN_WIDTH := 120
const LETTER_SIZE := 13


func _init() -> void:
	content_margin_left = BEZEL + GUTTER + 10
	content_margin_right = BEZEL + 12
	content_margin_top = BEZEL + COLUMNS + 6
	content_margin_bottom = CHIN + 4


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	PaperSheet.flat(bezel, 14, 12).draw(to_canvas_item, rect)
	var glass := rect.grow_individual(-BEZEL, -BEZEL, -BEZEL, -CHIN)
	RenderingServer.canvas_item_add_rect(to_canvas_item, glass, screen)
	RenderingServer.canvas_item_add_circle(to_canvas_item, Vector2(rect.end.x - BEZEL - 10, rect.end.y - CHIN / 2.0),
		3.0, Color("#47d16c"))
	if grid <= 0:
		return
	var font := ThemeDB.fallback_font
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(glass.position, Vector2(glass.size.x, COLUMNS)), header)
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(glass.position, Vector2(GUTTER, glass.size.y)), header)
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(glass.position, Vector2(GUTTER, COLUMNS)), accent)
	var k := 0
	var x := glass.position.x + GUTTER
	while x < glass.end.x:
		RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(x, glass.position.y), Vector2(x, glass.end.y), grid_color)
		font.draw_string(to_canvas_item, Vector2(x + COLUMN_WIDTH / 2.0 - 4, glass.position.y + COLUMNS - 6),
			char(65 + k % 26), HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, header_ink)
		x += COLUMN_WIDTH
		k += 1
	var row := 1
	var y := glass.position.y + COLUMNS
	while y < glass.end.y:
		RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(glass.position.x, y), Vector2(glass.end.x, y), grid_color)
		if y + grid <= glass.end.y:
			font.draw_string(to_canvas_item, Vector2(glass.position.x + 6, y + grid - 9), str(row),
				HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, header_ink)
		y += grid
		row += 1
