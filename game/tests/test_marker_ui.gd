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


## A marker must not change the moment it marks: in a van ride (or a scene, a view) the
## line does not open and the ride goes on untouched.
func test_the_line_does_not_open_in_a_ride_or_a_scene() -> void:
	var office := _office()
	Designer.force(true)
	office.session.missions.progress["fix_wrong_joint"] = {"status": "active", "asks": {}, "seen": {}}
	office.floors.go_to("yard", "exit", true)
	office.yard.poll()
	office.interact(office.interactable("ride:fix_wrong_joint"))
	assert_true(office.ride != null, "the ride starts")
	var stage: Variant = office.ride.stage
	assert_false(office.ui.open_marker(), "no line in the cab")
	assert_false(office.ui.marker_open())
	assert_eq(office.ride.stage, stage, "the ride is untouched")
	assert_false(office.player.active)
	office.free()
	var scene := _office()
	scene._scene_holds = true
	assert_false(scene.ui.open_marker(), "no line over a scene")
	_cleanup()
	scene.free()


## Tab lowers the phone (Phone._input); typed in the line it must not.
func test_tab_in_the_line_does_not_close_the_phone() -> void:
	var office := _office()
	Designer.force(true)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(office)
	var ui := office.ui
	ui.phone.show()
	assert_true(ui.open_marker())
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.keycode = KEY_TAB
	tab.pressed = true
	var closed := [false]
	ui.phone.close_requested.connect(func() -> void: closed[0] = true)
	tree.root.push_input(tab)
	assert_false(closed[0], "the phone stays")
	_cleanup()
	office.free()
