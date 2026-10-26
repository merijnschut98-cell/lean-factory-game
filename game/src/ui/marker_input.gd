class_name MarkerInput
extends PanelContainer
## The designer's F8 line (Merijn's playtest tools): one line of text over the HUD.
## Enter hands it over, Esc cancels; the game's own keys do not fire while it has the
## focus (the field takes the key events, and GameUI holds the world still).

signal submitted(text: String)
signal cancelled

const PROMPT := "Noteer dit moment"
const HINT := "Enter bewaart · Esc sluit"
const WIDTH := 640.0
const BOTTOM_MARGIN := 90.0

var field: LineEdit


func _init() -> void:
	visible = false
	add_theme_stylebox_override("panel", UiTheme.panel(14))
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size.x = WIDTH
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -BOTTOM_MARGIN
	var box := VBoxContainer.new()
	add_child(box)
	field = LineEdit.new()
	field.max_length = SessionLog.MARKER_MAX_CHARS
	field.placeholder_text = tr(PROMPT)
	field.text_submitted.connect(_submit)
	field.gui_input.connect(_cancel_on_escape)
	box.add_child(field)
	box.add_child(UiPanel.label(tr(HINT), UiTheme.SMALL, Palette.MUTED))


func open() -> void:
	field.clear()
	show()
	if is_inside_tree():
		field.grab_focus()


func close() -> void:
	if is_inside_tree():
		field.release_focus()
	hide()


## Enter: an empty line writes nothing, it only closes.
func _submit(text: String) -> void:
	close()
	if text.strip_edges().is_empty():
		cancelled.emit()
	else:
		submitted.emit(text)


func _cancel_on_escape(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		field.accept_event()   # not the world's pause
		close()
		cancelled.emit()
