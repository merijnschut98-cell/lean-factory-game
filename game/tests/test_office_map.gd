extends TestCase
## The player map (M): the office floor seen from above, every interaction
## place with its Dutch name, the player and the active mission's places.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const DESIGN := "place:connections.design"


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false  # a returning player: straight to the campaign
	office.build()
	return office


func test_the_floor_fills_the_map_keeping_its_shape() -> void:
	var floor_rect := Rect2(0, -16, 24, 16)
	var area := Rect2(10, 20, 600, 600)
	var top_left := OfficeMap.project(Vector2(0, -16), floor_rect, area)
	var bottom_right := OfficeMap.project(Vector2(24, 0), floor_rect, area)
	assert_eq(top_left, Vector2(10, 120), "the floor is centred, north (-z) up")
	assert_eq(bottom_right, Vector2(610, 520))
	assert_eq(OfficeMap.project(Vector2(12, -8), floor_rect, area), Vector2(310, 320), "the middle in the middle")


func test_the_office_floor_is_the_shell() -> void:
	var office := _office()
	var r := office.floor_rect()
	assert_near(r.size.x, 24.0, 0.5)
	assert_near(r.size.y, 16.0, 0.5)
	for i in office.interactables:
		assert_true(r.has_point(Vector2(i.position.x, i.position.z)), "%s stands on the floor" % i.id)
	office.free()


func test_m_opens_and_closes_the_map() -> void:
	var office := _office()
	office.player.map_pressed.emit()
	assert_true(office.ui.office_map.visible, "M opens the map")
	assert_true(office.ui.is_busy())
	office.player.map_pressed.emit()
	assert_false(office.ui.office_map.visible, "M again closes it")
	assert_false(office.ui.is_busy())
	office.free()


func test_the_map_shows_every_place_inside_its_frame() -> void:
	var office := _office()
	office.ui.toggle_map()
	var map := office.ui.office_map
	assert_eq(map.places.size(), office.interactables.size())
	var area := map.area()
	for i in office.interactables:
		var label := office.label_for(i)
		assert_true(label in map.labels(), "%s is on the map as %s" % [i.id, label])
		assert_true(area.has_point(map.to_view(Vector2(i.position.x, i.position.z))), "%s inside the map" % i.id)
	assert_true("Werkvoorbereiding & ontwerp" in map.labels(), "in Dutch")
	office.free()


func test_the_player_dot_follows_the_player() -> void:
	var office := _office()
	office.ui.toggle_map()
	var map := office.ui.office_map
	var before := map.player_point()
	office.player.position += Vector3(3, 0, -2)
	var after := map.player_point()
	assert_true(after.x > before.x, "east is right")
	assert_true(after.y < before.y, "north (-z) is up")
	assert_eq(after, map.to_view(Vector2(office.player.position.x, office.player.position.z)))
	office.player.rotation.y = 0.0
	assert_true(map.player_facing().y < -0.99, "looking north points up")
	office.free()


func test_the_active_missions_places_are_marked() -> void:
	var office := _office()
	assert_eq(OfficeMap.mission_places(office.session), [], "no mission, nothing marked")
	office.ui.mission_board.accept(MISSION)
	var marked := OfficeMap.mission_places(office.session)
	assert_true(DESIGN in marked, "the place in the briefing")
	assert_true("obeya" in marked, "the A3 wall")
	assert_false("place:connections.intake" in marked)
	office.free()


func test_the_controls_name_the_map() -> void:
	var office := _office()
	assert_true(office.ui.hud.controls_text().contains("M kaart"))
	office.free()


func test_the_map_shows_what_stands_on_the_floor() -> void:
	var office := _office()
	var prints := office.map_footprints()
	assert_true(prints.size() > 5, "desks and cabinets")
	var floor_area := office.floor_rect()
	for f in prints:
		assert_true(floor_area.encloses(f["rect"]), "on the floor")
	office.free()
