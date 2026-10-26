extends TestCase
## The designer's F8 marker on screen: a line over the HUD in a designer build only, the
## world held still while it is open, Enter writes the block, Esc cancels, and every
## event text the player is shown lands in the layer's `recent`.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
var markers_path := scratch("saves/test_ui_markers.md")


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	office.ui.playtest_log = SessionLog.new(scratch("saves/test_ui_log.txt"), false)
	office.ui.playtest_log.markers_path = markers_path
	return office


func _cleanup() -> void:
	Designer.force(null)
	DirAccess.remove_absolute(markers_path)


func test_the_line_opens_only_in_a_designer_build() -> void:
	var office := _office()
	Designer.force(false)
	assert_false(office.ui.open_marker())
	assert_false(office.ui.marker_open(), "the player's build has no marker")
	Designer.force(true)
	assert_true(office.ui.open_marker())
	assert_true(office.ui.marker_open())
	assert_false(office.ui.open_marker(), "not twice")
	_cleanup()
	office.free()


func test_enter_writes_the_marker_with_place_and_recent_and_gives_the_world_back() -> void:
	var office := _office()
	Designer.force(true)
	var ui := office.ui
	assert_eq(office.session.accept(MISSION), "")
	ui.after_action()
	assert_false(ui.session_layer.recent.is_empty(), "the mission's event text was noted")
	ui.open_marker()
	assert_false(office.player.active, "the player stands still while typing")
	ui._marker_input.field.text_submitted.emit("De wachttijd voelt hier lang")
	assert_false(ui.marker_open())
	assert_true(office.player.active, "the world is back")
	var text := FileAccess.get_file_as_string(markers_path)
	assert_true(text.contains(" · %s\n" % MISSION), text)
	assert_true(text.contains("\nDe wachttijd voelt hier lang\n"), text)
	assert_true(text.contains("- " + ui.session_layer.recent[-1]), text)
	assert_true(text.contains(office.floors.floor_id), "the floor is named: " + text)
	_cleanup()
	office.free()


func test_escape_and_an_empty_line_write_nothing() -> void:
	var office := _office()
	Designer.force(true)
	var ui := office.ui
	ui.open_marker()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	ui._marker_input.field.gui_input.emit(escape)
	assert_false(ui.marker_open())
	assert_true(office.player.active)
	ui.open_marker()
	ui._marker_input.field.text_submitted.emit("   ")
	assert_false(ui.marker_open())
	assert_false(FileAccess.file_exists(markers_path))
	_cleanup()
	office.free()


## Over an open panel the player is already still: closing the line leaves the panel's world alone.
func test_the_line_over_a_panel_does_not_release_the_world() -> void:
	var office := _office()
	Designer.force(true)
	var ui := office.ui
	ui.open_a3()
	assert_false(office.player.active)
	ui.open_marker()
	ui._marker_input.field.text_submitted.emit("")
	assert_false(office.player.active, "the A3 still holds the world")
	_cleanup()
	office.free()
