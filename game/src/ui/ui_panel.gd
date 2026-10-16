class_name UiPanel
extends PanelContainer
## An in-game panel, centred or docked at the right: a title, a close button
## and a body the subclass fills. Subclasses keep their logic in small
## methods that tests call directly (use_tool, accept, submit, ...); the
## buttons only forward.

## The player did something that changed the session (the HUD refreshes,
## events are shown).
signal acted
signal close_requested

## Room left for the HUD's top bar, and the margin around a docked panel.
const DOCK_TOP := 64
const DOCK_MARGIN := 16

var session: GameSession
## Docked at the right edge over the full height (the world stays in view
## beside it) instead of centred.
var docked := false
var title_label: Label
## The header's close button (Esc closes too).
var close_button: Button
var body: VBoxContainer


func _init(title: String, size: Vector2 = Vector2(1100, 0)) -> void:
	custom_minimum_size = size
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var outer := VBoxContainer.new()
	add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	title_label = label(title, UiTheme.HEADING, Palette.VOLTANA_BLUE)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	close_button = button("Sluiten  (Esc)", close_requested.emit)
	header.add_child(close_button)
	outer.add_child(HSeparator.new())
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)


## Centre the panel at its current minimum size, or dock it at the right.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_place.call_deferred()


## Set the size once: each resize queues another placement, so a size set
## twice (shrunk, then grown) never settles.
func _place() -> void:
	if not is_inside_tree():
		return
	var rect := placement(get_parent_area_size(), get_combined_minimum_size(), docked)
	size = rect.size
	position = rect.position


## Where a panel of `min_size` goes on `parent_size`: centred, or docked at
## the right edge below the HUD's bar over the full height.
static func placement(parent_size: Vector2, min_size: Vector2, at_side: bool) -> Rect2:
	if not at_side:
		return Rect2(((parent_size - min_size) / 2.0).floor(), min_size)
	var tall := Vector2(min_size.x, maxf(min_size.y, parent_size.y - DOCK_TOP - DOCK_MARGIN))
	return Rect2(Vector2(parent_size.x - tall.x - DOCK_MARGIN, DOCK_TOP), tall)


## Rebuild the body from the session (subclasses).
func refresh() -> void:
	pass


# ── Widget helpers ───────────────────────────────────────────────────────────

static func label(text: String, font_size: int = UiTheme.FONT_SIZE, color: Color = Palette.INK,
		wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func paragraph(text: String, color: Color = Palette.INK, font_size: int = UiTheme.FONT_SIZE) -> Label:
	return label(text, font_size, color, true)


static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	return b


## Add a white card with a small blue heading to `parent`; returns the box to
## fill.
static func add_card(parent: Node, heading: String = "", fill: Color = Color.WHITE) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card(fill))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	if not heading.is_empty():
		box.add_child(label(heading, UiTheme.SMALL, Palette.VOLTANA_BLUE))
	parent.add_child(panel)
	return box


static func clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
