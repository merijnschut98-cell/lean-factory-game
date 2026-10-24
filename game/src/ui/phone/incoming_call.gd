class_name IncomingCall
extends PanelContainer
## A customer rings the player's phone (PLAN 2.4, CustomerCalls): the phone
## comes up at the right of the screen with who is calling, and two choices:
## answer (1, or a tap) or let it go (2): their voicemail lands in Berichten,
## at no cost. The world goes on while it rings; it never rings out by itself
## (no timer counts against the player).

signal answered(call: Dictionary)
signal declined(call: Dictionary)

const CALLING := "belt je"
const ANSWER := "Opnemen"
const LET_GO := "Niet opnemen"
const ANSWER_KEY := KEY_1
const LET_GO_KEY := KEY_2

## The call ringing ({person, dialog, name}); {} when none.
var call: Dictionary = {}
## Whether its keys 1 and 2 are its own now (GameUI: the world is free; review S3 #2);
## unset: always. Over the KPI board or a scene they are that view's.
var keys_free := Callable()
var _name: Label


func _init() -> void:
	var style := StyleBoxFlat.new()   # the raised phone of a call (TalkView's phone screen)
	style.bg_color = Color(0.08, 0.09, 0.11, 0.95)
	style.border_color = Color(0.25, 0.27, 0.3)
	style.set_border_width_all(6)
	style.set_corner_radius_all(26)
	style.set_content_margin_all(22)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(230, 300)
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BOTH
	offset_right = -120
	offset_top = -240   # above the toasts at the right
	visible = false
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_name = UiPanel.label("", 20, Color.WHITE)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_name)
	var calling := UiPanel.label(tr(CALLING), UiTheme.SMALL, Palette.VOLTANA_GREEN)
	calling.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(calling)
	box.add_child(UiPanel.button("1  " + tr(ANSWER), answer))
	box.add_child(UiPanel.button("2  " + tr(LET_GO), decline))


## Ring with `c` ({person, dialog, name}).
func ring(c: Dictionary) -> void:
	call = c
	_name.text = str(c.get("name", ""))
	show()


func answer() -> void:
	_end(answered)


## Stop ringing without a choice: the call is being taken another way (the
## KCC's headset).
func stop() -> void:
	call = {}
	hide()


func decline() -> void:
	_end(declined)


func _end(outcome: Signal) -> void:
	if not visible:
		return
	var c := call
	call = {}
	hide()
	outcome.emit(c)


func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	if keys_free.is_valid() and not keys_free.call():
		return
	match key.physical_keycode:
		ANSWER_KEY:
			answer()
		LET_GO_KEY:
			decline()
		_:
			return
	get_viewport().set_input_as_handled()
