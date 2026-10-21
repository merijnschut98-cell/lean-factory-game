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
	if office.geometry.name != "OfficePlaceholder":   # the building's 1e: both wings and the core (PLAN 2.1)
		assert_near(r.size.x, 42.0, 0.5)
		assert_true(r.encloses(Rect2(0, -16, 24, 16)), "the connections office lies on it")
	assert_near(r.size.y, 16.0, 0.5)
	for i in office.interactables:
		assert_true(r.has_point(Vector2(i.position.x, i.position.z)), "%s stands on the floor" % i.id)
	office.free()


func test_m_opens_and_closes_the_map() -> void:
	var office := _office()
	office.player.phone_pressed.emit(Phone.MAP)
	assert_true(office.ui.phone.visible and office.ui.phone.current == Phone.MAP, "M opens the map on the phone")
	assert_true(office.ui.is_busy())
	office.player.phone_pressed.emit(Phone.MAP)
	assert_false(office.ui.phone.visible, "M again lowers it")
	assert_false(office.ui.is_busy())
	office.free()


func test_the_map_shows_every_place_inside_its_frame() -> void:
	var office := _office()
	office.ui.toggle_phone(Phone.MAP)
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
	office.ui.toggle_phone(Phone.MAP)
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


## A problem's mission marks the room its briefing sends you to, never the
## work step (more than the briefing says; creator-and-minimap spec §2), and
## the obeya once the A3 is ready for its Check.
func test_a_problem_mission_marks_its_room_never_the_step() -> void:
	var office := _office()
	var s := office.session
	assert_eq(OfficeMap.mission_places(s), [], "no mission, nothing marked")
	office.ui.mission_board.accept(MISSION)
	var marked := OfficeMap.mission_places(s)
	assert_false(DESIGN in marked, "never the step")
	assert_false("obeya" in marked, "not before the A3 is ready for a Check")
	office.ui.close_panels()
	office.ui.toggle_phone(Phone.MAP)
	var map := office.ui.office_map
	var rooms := map.marked_rooms()
	assert_eq(rooms.size(), 1, "the room the briefing sends you to")
	var design: Dictionary = map.places.filter(func(p: Dictionary) -> bool: return p["id"] == DESIGN)[0]
	var room: Dictionary = map.rooms.filter(func(r: Dictionary) -> bool: return r["id"] == rooms[0])[0]
	assert_true(room["rect"].has_point(design["at"]), "the room around the step")
	s.region.state["custom_design"].phase = ProblemState.Phase.CHECK_READY
	assert_true("obeya" in OfficeMap.mission_places(s), "then the obeya")
	office.free()


func test_the_controls_name_the_map() -> void:
	var office := _office()
	assert_true(office.ui.hud.controls_text().contains("Tab telefoon"))
	office.free()


func test_the_map_shows_what_stands_on_the_floor() -> void:
	var office := _office()
	var prints := office.map_footprints()
	assert_true(prints.size() > 5, "desks and cabinets")
	var floor_area := office.floor_rect()
	for f in prints:
		assert_true(floor_area.encloses(f["rect"]), "on the floor")
	office.free()
