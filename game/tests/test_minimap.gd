extends TestCase
## The minimap (PLAN 2.1b; creator-and-minimap spec §4.2): the targets at room level (a
## pure function, no world), where never what, the rim arrow with the route's distance,
## the floors, the fade, the turn, when it shows and the layout.

const SCENE := "res://src/world/office/office.tscn"
const SETTINGS := "user://test_minimap_settings.cfg"


func _session() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, false)


func _building() -> OfficeBuilding:
	return OfficeBuilding.load_from(Catalog.DATA_DIR)


func _office() -> Office:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	office.minimap.settings_path = SETTINGS
	return office


func _take(s: GameSession, id: String) -> void:
	s.missions.progress[id] = {"status": "active", "asks": {}, "seen": {}}


func _talk(dialog: String) -> MissionDef:
	var m := MissionDef.new()
	m.id = "talk_test"
	m.kind = "side"
	m.goal_type = "talk_to"
	m.goal_dialog = dialog
	return m


func _of(s: GameSession, id: String) -> Dictionary:
	return MinimapTargets.of(s.missions.defs[id], s, _building(), CharacterModel.cast())


## The items of a layout of one kind.
func _items(map: Minimap, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in map.layout():
		if i["kind"] == kind:
			out.append(i)
	return out


# ── 1, 2, 5: the targets ────────────────────────────────────────────────────

func test_targets_per_goal_type_are_rooms_or_people() -> void:
	var s := _session()
	var b := _building()
	var t := MinimapTargets.of(_talk("petra_thursday"), s, b, CharacterModel.cast())
	assert_eq([t.get("kind"), t.get("person"), t.get("room"), t.get("floor")], ["person", "petra", "meter_data", "first"],
		"talk_to: the person, wherever they are")
	t = _of(s, "walk_meters")
	assert_eq([t.get("kind"), t.get("room")], ["room", "meter_data"], "walk: the first unseen step's room")
	s.region.observed["meters.registration"] = true
	assert_eq(_of(s, "walk_meters"), {}, "every step with a room seen: no target")
	t = _of(s, "training_tue")
	assert_eq(t.get("room"), "connections", "observe: the first unobserved place's room")
	assert_eq(_of(s, "fix_status_callers").get("room"), "contact_centre", "solve: the room of the problem's step")
	assert_eq(_of(s, "fix_wrong_joint"), {}, "a problem in the field: no target in the office")
	assert_eq(MinimapTargets.of(_talk("el_amrani_fourth_call"), s, b, CharacterModel.cast()), {},
		"a customer on the phone: no target")


func test_a_problems_target_moves_to_the_obeya_when_the_a3_is_ready() -> void:
	var s := _session()
	_take(s, "fix_status_callers")
	var st: ProblemState = s.region.state["status_callers"]
	st.phase = ProblemState.Phase.CHECK_READY
	assert_eq(_of(s, "fix_status_callers").get("room"), MinimapTargets.OBEYA_ROOM)


func test_every_tier1_target_is_a_room_or_a_person_never_a_place() -> void:
	var s := _session()
	var b := _building()
	var rooms := b.rooms.map(func(r: Dictionary) -> String: return r["id"])
	for m: MissionDef in s.missions.defs.values():
		var t := MinimapTargets.of(m, s, b, CharacterModel.cast())
		if t.is_empty():
			continue
		assert_true(t["kind"] in ["room", "person"], "%s: %s" % [m.id, t["kind"]])
		assert_true(t["kind"] == "person" or t["room"] in rooms, "%s points at a room, not %s" % [m.id, t.get("room")])
		assert_false(str(t.get("room", "")).contains("."), "%s: never a place id" % m.id)


func test_only_accepted_missions_have_targets_one_main_and_at_most_three_sides() -> void:
	var s := _session()
	var b := _building()
	for t in MinimapTargets.all(s, b, CharacterModel.cast()):
		assert_true(s.missions.status(t["mission"]) == "active", "%s is accepted" % t["mission"])
	var before := MinimapTargets.all(s, b, CharacterModel.cast()).size()
	assert_true(s.missions.status("fix_status_callers") != "active", "offered, not taken")
	assert_eq(MinimapTargets.all(s, b, CharacterModel.cast()).size(), before, "an offered mission adds nothing")
	for id in ["fix_status_callers", "walk_meters", "fix_not_at_home", "fix_permits_in_batches", "fix_planning_reshuffle"]:
		_take(s, id)
	var all := MinimapTargets.all(s, b, CharacterModel.cast())
	assert_true(all.filter(func(t: Dictionary) -> bool: return t["main"]).size() <= MinimapTargets.MAX_MAIN)
	assert_true(all.filter(func(t: Dictionary) -> bool: return not t["main"]).size() <= MinimapTargets.MAX_SIDE)


# ── 4: where, never what ────────────────────────────────────────────────────

func test_the_map_draws_only_where_never_what() -> void:
	var office := _office()
	office.session.missions.progress["fix_custom_design"] = {"status": "active", "asks": {}, "seen": {}}
	office.minimap.refresh()
	var map := office.minimap.map
	var people := 0
	for item in map.layout():
		assert_true(item["kind"] in Minimap.ITEM_KINDS, "a %s may be drawn" % item["kind"])
		if item["kind"] == "person":
			people += 1
			assert_eq(item.keys().size(), 2, "a person dot carries nothing but where it is")
		if item["kind"] == "room_name":
			assert_true(office.floors.building.rooms.any(func(r: Dictionary) -> bool: return r["name"] == item["text"]),
				"text is only a room's name")
	assert_true(people > 0, "the people around are dots")
	var names := map.targets.map(func(t: Dictionary) -> String: return t["id"])
	assert_eq(names.filter(func(n: String) -> bool: return n.begins_with("fix_custom_design")).size(), 1,
		"the main mission: one target")
	for t in map.targets:
		assert_true(t["kind"] in ["room", "person", "seam"], "never a clue, a tool or a place")
	office.free()


# ── 6, 7: the rim arrow and the floors ──────────────────────────────────────

func test_a_far_target_is_an_arrow_with_the_route_distance_and_a_near_one_a_marker() -> void:
	var office := _office()
	office.session.missions.progress["fix_done_but_not_closed"] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)   # Meetdata opens
	var map := office.minimap.map
	office.player.position = Vector3(20.0, 0, -8.0)   # the east end of Aansluitingen
	office.minimap.refresh()
	var t: Dictionary = map.targets.filter(func(x: Dictionary) -> bool: return x["main"])[0]
	var straight := Vector2(20.0, -8.0).distance_to(t["at"])
	assert_true(straight > Minimap.METRES / 2.0, "Meetdata is out of the circle")
	var arrows := _items(map, "arrow")
	assert_eq(arrows.size(), 1, "an arrow on the rim")
	assert_eq(int(t["distance"]) % 5, 0, "rounded to 5 m")
	assert_true(t["distance"] >= straight - 2.5, "the walking route, not the straight line (%d m vs %.1f)" % [t["distance"], straight])
	assert_eq(arrows[0]["text"], "%d m" % t["distance"])
	assert_eq(_items(map, "target").size(), 0, "no marker while it is out of view")
	office.player.position = Vector3(-8.0, 0, -8.0)   # the corridor by Meetdata
	office.minimap.refresh()
	assert_eq(_items(map, "arrow").size(), 0, "in view: no arrow")
	assert_eq(_items(map, "target").size(), 1, "the marker on the plan")
	assert_eq(Minimap.rounded(1.0), 5, "never below 5 m")
	assert_eq(Minimap.rounded(33.0), 35)
	office.free()


func test_a_target_on_another_floor_points_to_the_nearer_seam_with_the_floor() -> void:
	var office := _office()
	office.session.missions.progress["fix_grid_study_queue"] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.minimap.refresh()
	var map := office.minimap.map
	var t: Dictionary = map.targets.filter(func(x: Dictionary) -> bool: return x["main"])[0]
	assert_eq([t["kind"], t["text"]], ["seam", "2e verdieping ↑"])
	var seams := office.interactables.filter(func(i: Interactable) -> bool: return i.kind in ["stairs_up", "lift"])
	var lengths := seams.map(func(i: Interactable) -> float:
		return OfficeMinimap._length(office.player.position, office.nav().path(office.player.position, i.position)))
	var nearest: Interactable = seams[lengths.find(lengths.min())]
	assert_true(t["at"].distance_to(Vector2(nearest.position.x, nearest.position.z)) < 0.01, "the nearer of stairs and lift by route")
	office.session.missions.progress["fix_status_callers"] = {"status": "active", "asks": {}, "seen": {}}
	office.session.missions.progress["fix_grid_study_queue"] = {"status": "completed", "asks": {}, "seen": {}}
	office.floors.go_to("second", "lift", true)
	office.minimap.refresh()
	t = map.targets.filter(func(x: Dictionary) -> bool: return x["main"])[0]
	assert_eq(t["text"], "Begane grond ↓", "from the 2e down to the begane grond")
	office.free()


# ── 8, 9: the fade and the turn ─────────────────────────────────────────────

func test_the_marker_fades_in_the_target_room_and_comes_back_on_leaving() -> void:
	var office := _office()
	office.session.missions.progress["fix_custom_design"] = {"status": "active", "asks": {}, "seen": {}}
	var map := office.minimap.map
	office.player.position = Vector3(9.0, 0, -6.0)   # in Aansluitingen
	office.minimap.refresh()
	var t: Dictionary = map.targets.filter(func(x: Dictionary) -> bool: return x["main"])[0]
	assert_true(t["reached"], "in the target room")
	for i in 11:
		map.step(0.1)
	assert_eq(map.alpha[t["id"]], 0.0, "faded out within 1.1 s")
	map.step(5.0)
	assert_eq(map.alpha[t["id"]], 0.0, "and stays gone")
	office.player.position = Vector3(-5.0, 0, -8.0)   # out in the hall
	office.minimap.refresh()
	assert_false(map.targets[0]["reached"])
	map.step(1.1)
	assert_eq(map.alpha[t["id"]], 1.0, "back on leaving")
	var steady: Dictionary = map.alpha.duplicate()
	map.step(3.0)
	assert_eq(map.alpha, steady, "nothing loops: a steady map stays as it is (no blinking)")
	office.free()


func test_the_map_turns_with_the_camera_unless_set_north_up_and_names_stay_upright() -> void:
	var office := _office()
	var map := office.minimap.map
	office.rig.yaw = 0.7
	office.minimap.refresh()
	assert_near(map.map_rotation(), 0.7, 0.0001, "turning: the camera's yaw")
	Minimap.set_setting(Minimap.TURNS, false, SETTINGS)
	office.minimap.refresh()
	assert_eq(map.map_rotation(), 0.0, "north-up")
	assert_true(_items(map, "north")[0]["at"].y < map.centre().y, "N at the top")
	assert_eq(_items(map, "room_name").filter(func(i: Dictionary) -> bool: return i.has("rotation")).size(), 0,
		"room names are written upright")
	office.free()


# ── 10, 11, 12: when it shows, and where ────────────────────────────────────

func test_it_shows_once_ruud_handed_over_the_plan_and_is_kept_in_the_save() -> void:
	var office := _office()
	var layer := office.ui.session_layer
	assert_true(layer.has_floor_plan, "a new game has it until the first walk (2.7d) hands it over")
	assert_true(office.minimap.wanted())
	layer.has_floor_plan = false
	assert_false(office.minimap.wanted(), "before Ruud hands it over: hidden")
	var copy := SessionLayer.new()
	copy.load_dict(layer.to_dict())
	assert_false(copy.has_floor_plan, "saved and restored")
	copy.load_dict({})
	assert_true(copy.has_floor_plan, "an old save has it")
	office.free()


func test_it_hides_while_the_world_waits_and_when_the_setting_says_so() -> void:
	var office := _office()
	office.ui.open_mission_board()
	assert_false(office.minimap.wanted(), "a panel is open")
	office.ui.close_panels()
	assert_true(office.minimap.wanted())
	office.player.position = office.interactable(OfficeWhiteboard.ID).position
	office.open_whiteboard()
	assert_false(office.minimap.wanted(), "the explainer is open")
	office.explainer.close()
	Minimap.set_setting(Minimap.SHOWN, false, SETTINGS)
	assert_false(office.minimap.wanted(), "the setting off: nothing in its place")
	office.free()


func test_it_sits_bottom_right_clear_of_the_toasts_the_help_line_and_the_prompt() -> void:
	var map := Minimap.new()
	var screen := Rect2(0, 0, 1600, 900)
	var rect := Rect2(screen.end - Vector2.ONE * (Minimap.DIAMETER + Minimap.MARGIN), Vector2.ONE * Minimap.DIAMETER)
	assert_eq([map.offset_left, map.offset_top], [-Minimap.DIAMETER - Minimap.MARGIN, -Minimap.DIAMETER - Minimap.MARGIN])
	assert_true(rect.position.x > 1600 - 260 and rect.end.y == 880.0, "220 px, 20 px from the corner")
	assert_true(rect.position.x > 800 + 300, "right of the place prompt (bottom centre)")
	map.free()
	var office := _office()
	assert_eq(office.ui.hud._toasts.offset_bottom, -14 - Minimap.DIAMETER - Minimap.MARGIN, "the toasts stack above it")
	office.free()
