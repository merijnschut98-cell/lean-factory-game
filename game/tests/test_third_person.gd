extends TestCase
## The third-person office (Sims-like): a visible player, a raised camera that
## follows, turns and zooms, WASD relative to the camera, and click-to-move
## over a walk grid baked from the office's collision. Headless: the physics
## step is simulated by moving the player by its own velocity.

const SCENE := "res://src/world/office/office.tscn"
const DESIGN := "place:connections.design"
const FRAME := 1.0 / 60.0


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


## Physics frames without a physics server: the player steers, then moves.
func _walk(office: Office, seconds: float) -> void:
	for n in int(seconds / FRAME):
		office.player.step(FRAME)
		office.player.position += office.player.velocity * FRAME


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


# ── The character ─────────────────────────────────────────────────────────────

func test_the_player_is_a_visible_character_without_a_first_person_camera() -> void:
	var office := _office()
	assert_true(office.player.avatar != null, "an avatar")
	assert_eq(office.player.avatar.scene_file_path, Player.AVATAR)
	assert_eq(office.player.find_children("*", "Camera3D", true, false).size(), 0, "no camera on the player")
	assert_true(office.rig.camera.current, "the rig's camera is the view")
	office.free()


func test_the_character_model_walks_and_idles_when_it_is_there() -> void:
	if not ResourceLoader.exists(Player.CHARACTER):
		return
	var office := _office()
	var animations: AnimationPlayer = office.player.avatar.find_children("*", "AnimationPlayer", true, false).pop_front()
	assert_true(animations != null, "the model's animations")
	assert_false(office.player.avatar.has_node("StandIn"), "the model replaces the stand-in")
	assert_eq(animations.current_animation, "idle")
	office.player.step(FRAME, Vector2(0, -1))
	assert_eq(animations.current_animation, "walk")
	office.player.step(FRAME)
	assert_eq(animations.current_animation, "idle")
	office.free()


# ── The camera ────────────────────────────────────────────────────────────────

func test_the_camera_starts_at_a_medium_distance_looking_down_at_the_player() -> void:
	var office := _office()
	var rig := office.rig
	assert_between(rig.distance, 8.0, 12.0, "medium distance")
	var to_focus := rig.focus - rig.camera.position
	assert_true(to_focus.normalized().dot(-rig.camera.basis.z) > 0.999, "it looks at its focus")
	assert_true(_flat(rig.focus).distance_to(_flat(office.player.position)) <= rig.distance * CameraRig.LEAN + 0.01,
		"near the player (leaning into the room by the entrance)")
	assert_between(rad_to_deg(asin(-to_focus.normalized().y)), 44.0, 89.0, "raised")
	var teams := (office.interactable(DESIGN).position + office.interactable("place:connections.intake").position) / 2.0
	assert_true(_off_centre(rig.camera, teams) < rig.camera.fov / 2.0, "the team area in view")
	office.free()


func test_the_camera_follows_the_player_smoothly() -> void:
	var office := _office()
	var rig := office.rig
	var start := rig.focus
	office.player.position += Vector3(3, 0, -4)
	rig.update(FRAME)
	assert_true(rig.focus.distance_to(start) > 0.01, "it starts to follow")
	assert_true(rig.focus.distance_to(start) < 1.0, "smoothly, not in one jump")
	for n in 180:
		rig.update(FRAME)
	assert_true(_flat(rig.focus).distance_to(_flat(office.player.position)) < 0.05, "it catches up")
	office.free()


func test_zoom_stays_between_conversation_and_overview_distance() -> void:
	var office := _office()
	var rig := office.rig
	rig.zoom(-100)
	assert_eq(rig.distance, CameraRig.MIN_DISTANCE)
	assert_between(CameraRig.MIN_DISTANCE, 2.5, 3.0, "a close, conversation distance")
	rig.zoom(100)
	assert_eq(rig.distance, CameraRig.MAX_DISTANCE)
	assert_near(CameraRig.MAX_DISTANCE, 18.0, 0.01)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	rig._unhandled_input(wheel)
	assert_true(rig.distance < CameraRig.MAX_DISTANCE, "the wheel zooms in")
	office.free()


func _key(code: Key, pressed: bool) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.pressed = pressed
	return k


func test_z_and_c_turn_the_camera_while_held() -> void:
	var office := _office()
	var rig := office.rig
	var yaw := rig.yaw
	rig._unhandled_input(_key(CameraRig.TURN_LEFT, true))
	rig.update(0.5)
	assert_true(angle_difference(yaw, rig.yaw) > 0.3, "Z turns one way")
	rig._unhandled_input(_key(CameraRig.TURN_LEFT, false))
	yaw = rig.yaw
	rig.update(0.5)
	assert_near(rig.yaw, yaw, 0.0001, "released, it stops")
	rig._unhandled_input(_key(CameraRig.TURN_RIGHT, true))
	rig.update(0.5)
	assert_true(angle_difference(yaw, rig.yaw) < -0.3, "C turns the other way")
	office.free()


func test_a_right_mouse_drag_turns_the_camera() -> void:
	var office := _office()
	var rig := office.rig
	var yaw := rig.yaw
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	drag.relative = Vector2(100, 0)
	rig._unhandled_input(drag)
	assert_true(absf(angle_difference(yaw, rig.yaw)) > 0.2, "dragging turns")
	yaw = rig.yaw
	drag.button_mask = 0
	rig._unhandled_input(drag)
	assert_eq(rig.yaw, yaw, "a plain mouse move does not")
	office.free()


## The angle (degrees) between where the camera looks and `point`.
func _off_centre(cam: Camera3D, point: Vector3) -> float:
	return rad_to_deg((-cam.basis.z).angle_to(point - cam.position))


func test_the_camera_stays_over_the_floor_with_the_player_in_view() -> void:
	var office := _office()
	var rig := office.rig
	var area := office.floor_rect()
	for zoom in [-100, 0, 100]:
		rig.zoom(zoom)
		for spot: Vector3 in [Vector3(0.6, 0, -8), Vector3(23.4, 0, -0.6), Vector3(12, 0, -15.4), Vector3(9, 0, -8)]:
			office.player.position = spot
			for yaw in [0.0, PI / 2, PI, -PI / 2, 0.8]:
				rig.yaw = yaw
				rig.snap()
				var cam := rig.camera
				var why := "at %s yaw %.1f distance %.0f: %s" % [spot, yaw, rig.distance, cam.position]
				assert_true(area.has_point(_flat(cam.position)), "over the floor " + why)
				assert_true(cam.position.y > 1.9, "above head height (the ceiling is cut away) " + why)
				for part in [0.0, 1.8]:
					assert_true(_off_centre(cam, spot + Vector3.UP * part) < cam.fov / 2.0, "the player in view " + why)
	office.free()


func test_in_open_floor_the_camera_keeps_its_angle() -> void:
	var office := _office()
	var rig := office.rig
	office.player.position = Vector3(9, 0, -8)
	rig.yaw = 0.3
	rig.snap()
	var to_focus := (rig.focus - rig.camera.position).normalized()
	assert_near(asin(-to_focus.y), rig.pitch(), 0.001)
	assert_between(rad_to_deg(rig.pitch()), 45.0, 55.0, "the medium distance looks down ~45-55°")
	office.free()


func test_the_ceiling_is_cut_away_for_the_camera() -> void:
	var office := _office()
	var ceiling := office.find_marker("shell_ceiling") as VisualInstance3D
	assert_true(ceiling != null, "the office has a ceiling")
	assert_eq(ceiling.layers & office.rig.camera.cull_mask, 0, "the camera does not draw it")
	office.free()


# ── Walking ───────────────────────────────────────────────────────────────────

func test_wasd_walks_relative_to_the_camera() -> void:
	assert_true(Player.walk_direction(Vector2(0, -1), 0.0).is_equal_approx(Vector3(0, 0, -1)), "W with the camera looking north")
	assert_true(Player.walk_direction(Vector2(0, -1), PI / 2).is_equal_approx(Vector3(-1, 0, 0)), "W turns with the camera")
	assert_true(Player.walk_direction(Vector2(1, 0), PI).is_equal_approx(Vector3(-1, 0, 0)), "D: to the camera's right")


func test_a_click_on_the_floor_walks_the_player_there() -> void:
	var office := _office()
	var goal := Vector3(6.0, 0, -9.0)
	assert_true(office.click_floor(goal), "a walkable spot")
	assert_true(office.player.walking())
	_walk(office, 10.0)
	assert_false(office.player.walking(), "arrived")
	assert_true(_flat(office.player.position).distance_to(_flat(goal)) < 0.2, "at %s" % office.player.position)
	office.free()


func test_the_player_turns_to_face_where_it_walks() -> void:
	var office := _office()
	office.player.walk(PackedVector3Array([office.player.position + Vector3(0, 0, -3)]))
	_walk(office, 0.6)
	var heading := Vector2(-sin(office.player.rotation.y), -cos(office.player.rotation.y))
	assert_true(heading.dot(Vector2(0, -1)) > 0.95, "facing north: %s" % heading)
	office.free()


func test_the_walk_goes_around_furniture() -> void:
	var office := _office()
	var from := office.player.position
	var to := office.interactable("coach").position
	var route := office.nav().path(from, to)
	assert_true(route.size() >= 2, "a route with turns: %s" % route)
	assert_true(_flat(route[-1]).distance_to(_flat(to)) < 0.3, "it ends at the coach")
	var prev := from
	for p in route:
		for n in 20:
			var at := prev.lerp(p, n / 20.0)
			assert_true(office.nav().walkable(at), "walkable at %s" % at)
		prev = p
	office.free()


func test_wasd_cancels_a_click_walk() -> void:
	var office := _office()
	office.click_floor(Vector3(6.0, 0, -9.0))
	office.player.step(FRAME, Vector2(1, 0))
	assert_false(office.player.walking(), "a key takes over from the click")
	office.free()


func test_clicking_a_ring_walks_there_and_opens_the_place_on_arrival() -> void:
	var office := _office()
	var design := office.interactable(DESIGN)
	assert_true(office.click_floor(design.position + Vector3(0.3, 0, 0.2)), "the ring is clicked")
	assert_false(office.ui.is_busy(), "nothing opens before arrival")
	_walk(office, 15.0)
	assert_true(office.ui.place_menu.visible, "the team's menu opens on arrival")
	assert_eq(office.ui.place_menu.place, "connections.design")
	assert_false(office.player.active, "and the player stands still")
	office.free()


func test_a_click_with_a_panel_open_is_for_the_panel() -> void:
	var office := _office()
	office.interact(office.interactable("coach"))
	assert_false(office.click_floor(Vector3(6.0, 0, -9.0)))
	assert_false(office.player.walking())
	office.free()


func test_a_click_on_the_floor_after_a_ring_click_forgets_the_ring() -> void:
	var office := _office()
	office.click_floor(office.interactable(DESIGN).position)
	office.click_floor(Vector3(6.0, 0, -9.0))
	_walk(office, 10.0)
	assert_false(office.ui.is_busy(), "no panel opens at a plain spot")
	office.free()


# ── Seeing the gemba: close zoom, inspect, hover ──────────────────────────────

func _shown_distance(rig: CameraRig) -> float:
	return rig.camera.position.distance_to(rig.focus)


func test_the_close_zoom_looks_lower_to_read_the_desks() -> void:
	var office := _office()
	var rig := office.rig
	var medium := rig.pitch()
	rig.zoom(-100)
	assert_true(rad_to_deg(rig.pitch()) <= 35.0, "close by, the camera looks across the desks: %.0f°" % rad_to_deg(rig.pitch()))
	assert_true(rig.pitch() < medium - deg_to_rad(10.0))
	office.player.position = Vector3(9, 0, -8)
	rig.snap()
	assert_true(rig.camera.position.y > 1.9, "still above head height")
	office.free()


func test_using_a_place_frames_its_workstation_and_closing_returns() -> void:
	var office := _office()
	var rig := office.rig
	var design := office.interactable(DESIGN)
	office.player.position = design.position
	rig.snap()
	office.interact(design)
	assert_true(rig.inspecting(), "the camera frames the station")
	for n in 120:
		rig.update(FRAME)
	var look := office.frame_point(design)
	assert_true(rig.focus.distance_to(look) < 0.05, "it looks at the desk")
	assert_between(_shown_distance(rig), 2.0, 3.5, "at close range")
	var ahead := -design.basis.z
	assert_true((-rig.camera.basis.z).dot(ahead) > 0.5, "looking the way the place faces")
	office.ui.close_panels()
	assert_false(rig.inspecting(), "closing the panel lets go")
	for n in 180:
		rig.update(FRAME)
	assert_near(_shown_distance(rig), rig.distance, 0.1, "back at the player's zoom")
	office.free()


func _right(pressed: bool) -> InputEventMouseButton:
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_RIGHT
	b.pressed = pressed
	return b


func test_holding_right_click_at_a_place_frames_it_until_released() -> void:
	var office := _office()
	var rig := office.rig
	office.player.position = office.interactable(DESIGN).position
	rig._unhandled_input(_right(true))
	rig.update(0.1)
	assert_false(rig.inspecting(), "not on a quick click")
	rig.update(0.4)
	assert_true(rig.inspecting(), "held still: the station is framed")
	assert_false(office.ui.is_busy(), "without opening a panel")
	rig._unhandled_input(_right(false))
	assert_false(rig.inspecting(), "released: back to the player")
	office.free()


func test_a_right_drag_turns_instead_of_inspecting() -> void:
	var office := _office()
	var rig := office.rig
	office.player.position = office.interactable(DESIGN).position
	rig._unhandled_input(_right(true))
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	drag.relative = Vector2(40, 0)
	rig._unhandled_input(drag)
	rig.update(0.5)
	assert_false(rig.inspecting())
	office.free()


func test_holding_right_click_away_from_a_place_frames_nothing() -> void:
	var office := _office()
	office.player.position = Vector3(12, 0, -9)
	office.rig._unhandled_input(_right(true))
	office.rig.update(0.5)
	assert_false(office.rig.inspecting())
	office.free()


func test_the_ring_under_the_cursor_lights_up() -> void:
	var office := _office()
	var design := office.interactable(DESIGN)
	office.hover_floor(design.position + Vector3(0.2, 0, 0))
	assert_true(design.hovered, "the ring under the cursor")
	assert_eq(office.interactables.filter(func(i: Interactable) -> bool: return i.hovered).size(), 1, "only that one")
	office.hover_floor(Vector3(12, 0, -9))
	assert_false(design.hovered, "off again when the cursor leaves")
	office.free()
