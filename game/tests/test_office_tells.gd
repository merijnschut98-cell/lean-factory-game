extends TestCase
## The world shows the work (PLAN 2.6, design §1.5): props on the 1e and the 2e read the
## region's numbers and show one of three heights.

const MODEL := "res://assets/office/office.glb"
const SECOND_MODEL := "res://assets/office/office_second.glb"
## The tells of each floor's model.
const FIRST: Array[String] = ["intake_stack", "prep_tray", "planning_board", "revision_cabinet", "close_out_cabinet",
	"meter_board"]
const SECOND: Array[String] = ["obeya_board", "grid_study_tray", "reinforcement_board", "congestion_list"]


func _net() -> Network:
	return NetFixture.net([NetFixture.pool("intake", 2), NetFixture.pool("work_prep", 2)], [
		NetFixture.stream("connections", [
			NetFixture.work("intake", "intake", 1.0),
			NetFixture.work("design", "work_prep", 3.0),
		], 0.0),
	])


func test_bands_follow_the_documented_thresholds() -> void:
	for tell: String in OfficeTells.THRESHOLDS:
		var at: Array = OfficeTells.THRESHOLDS[tell]
		assert_eq(OfficeTells.band(tell, 0), OfficeTells.LOW, tell)
		assert_eq(OfficeTells.band(tell, at[0] - 1), OfficeTells.LOW, tell)
		assert_eq(OfficeTells.band(tell, at[0]), OfficeTells.MID, tell)
		assert_eq(OfficeTells.band(tell, at[1]), OfficeTells.HIGH, tell)


func test_a_long_intake_queue_shows_the_tall_stack_and_a_short_one_the_low() -> void:
	var net := _net()
	assert_eq(OfficeTells.bands(net)["intake_stack"], OfficeTells.LOW, "nothing waits")
	for i in 40:
		net.open_order(net.stream("connections"))
	assert_eq(net.queue_of(net.step_at("connections.intake")).size(), 40)
	assert_eq(OfficeTells.bands(net)["intake_stack"], OfficeTells.HIGH)
	net.advance_days(7)   # the team works the queue away; nothing new arrives
	assert_eq(OfficeTells.bands(net)["intake_stack"], OfficeTells.LOW)


func test_a_network_without_the_steps_reads_low() -> void:
	var net := NetFixture.net([NetFixture.pool("p")], [NetFixture.stream("other", [NetFixture.work("w", "p", 1.0)])])
	var none := {}
	for tell: String in FIRST + SECOND:
		none[tell] = OfficeTells.LOW
	assert_eq(OfficeTells.bands(net), none)
	assert_eq(OfficeTells.bands(net).size(), OfficeTells.THRESHOLDS.size(), "every tell is read")


## Revisie & GIS: the sketches of finished jobs waiting to be drawn into the GIS.
func test_the_revision_cabinet_follows_the_revision_queue() -> void:
	var net := NetFixture.net([NetFixture.pool("gis", 2)], [
		NetFixture.stream("connections", [NetFixture.work("revision", "gis", 1.0)], 0.0)])
	assert_eq(OfficeTells.bands(net)["revision_cabinet"], OfficeTells.LOW, "nothing waits")
	for i in OfficeTells.THRESHOLDS["revision_cabinet"][1]:
		net.open_order(net.stream("connections"))
	assert_eq(OfficeTells.bands(net)["revision_cabinet"], OfficeTells.HIGH)
	net.advance_days(7)
	assert_eq(OfficeTells.bands(net)["revision_cabinet"], OfficeTells.LOW, "drawn in")


## Meetdata: finished connections waiting for the administrative close-out (the wait and
## the queue at the desk both lie on the cabinet).
func test_the_close_out_cabinet_follows_the_finished_connections_waiting() -> void:
	var net := NetFixture.net([NetFixture.pool("meter_office")], [
		NetFixture.stream("connections", [NetFixture.wait("close_out_wait", 30.0),
			NetFixture.work("close_out", "meter_office", 0.25)], 0.0)])
	assert_eq(OfficeTells.bands(net)["close_out_cabinet"], OfficeTells.LOW)
	for i in OfficeTells.THRESHOLDS["close_out_cabinet"][1]:
		net.open_order(net.stream("connections"))
	assert_eq(OfficeTells.readings(net)["close_out_cabinet"], OfficeTells.THRESHOLDS["close_out_cabinet"][1])
	assert_eq(OfficeTells.bands(net)["close_out_cabinet"], OfficeTells.HIGH)


## Meetdata's whiteboard: the new meters that sent no reading in the last days (a
## registration that failed and went back for a new visit).
func test_the_meter_board_counts_the_silent_meters_of_the_last_days() -> void:
	for ftr: float in [0.0, 1.0]:
		var net := NetFixture.net([NetFixture.pool("meter_office", 2)], [
			NetFixture.stream("meters", [NetFixture.work("registration", "meter_office", 0.25, ftr,
				{"rework_wait_days": 30})], 0.0)])
		for i in 20:
			net.open_order(net.stream("meters"))
		net.advance_days(3)
		assert_eq(OfficeTells.bands(net)["meter_board"], OfficeTells.HIGH if ftr == 0.0 else OfficeTells.LOW,
			"first time right %s" % ftr)
		net.advance_days(OfficeTells.METER_DAYS + 1)
		assert_eq(OfficeTells.bands(net)["meter_board"], OfficeTells.LOW, "older ones are wiped off the board")


func test_the_1e_model_has_every_tell_with_three_variants() -> void:
	_has_tells(MODEL, FIRST)


func test_the_2e_model_has_every_tell_with_three_variants() -> void:
	_has_tells(SECOND_MODEL, SECOND)


func _has_tells(model: String, tells: Array[String]) -> void:
	var geometry: Node3D = load(model).instantiate()
	for tell in tells:
		var root := OfficeTells.node(geometry, tell)
		assert_true(root != null, "tell_%s in %s" % [tell, model.get_file()])
		for v in OfficeTells.VARIANTS:
			assert_true(OfficeTells.node(geometry, "%s_%s" % [tell, v]) != null, "tell_%s_%s" % [tell, v])
	geometry.free()


# --- the 2e (PLAN 2.16, design §1.5): the directie's KPI board, Netstrategie's study tray and
# reinforcement board, the congestion desk's printed waiting list.

## `n` orders of stream `id` finished just now, on time or late on its norm.
func _finished(net: Network, id: String, n: int, on_time: bool) -> void:
	for i in n:
		net.stream(id).finished.append({"done_at": net.time, "lead_minutes": 60, "on_time": on_time, "reworks": 0,
			"failure_demand": false})


func test_the_obeya_board_shows_a_red_card_for_each_stream_late_on_its_norm() -> void:
	var ids: Array[String] = ["a", "b", "c", "d", "e", "f"]
	var streams := []
	for id in ids:
		streams.append(NetFixture.stream(id, [NetFixture.work("w", "p", 1.0)], 0.0))
	var net := NetFixture.net([NetFixture.pool("p")], streams)
	net.advance_days(1)
	assert_eq(OfficeTells.readings(net)["obeya_board"], 0, "nothing finished: no colour on any card")
	for k in ids.size():
		_finished(net, ids[k], OfficeTells.KPI_MIN_FINISHED, k == 5)
	assert_eq(OfficeTells.readings(net)["obeya_board"], 5, "five of six late on their norm")
	assert_eq(OfficeTells.bands(net)["obeya_board"], OfficeTells.HIGH)
	_finished(net, "a", OfficeTells.KPI_MIN_FINISHED * 9, true)
	assert_eq(OfficeTells.readings(net)["obeya_board"], 4, "nine in ten on time: green again")
	assert_eq(OfficeTells.bands(net)["obeya_board"], OfficeTells.MID)
	var few := NetFixture.net([NetFixture.pool("p")], [streams[0]])
	_finished(few, "a", OfficeTells.KPI_MIN_FINISHED - 1, false)
	assert_eq(OfficeTells.readings(few)["obeya_board"], 0, "too few finished to colour the card")


func test_the_grid_study_tray_holds_the_studies_waiting() -> void:
	var net := NetFixture.net([NetFixture.pool("grid_analysts", 2)], [
		NetFixture.stream("connections", [NetFixture.work("grid_study", "grid_analysts", 4.0)], 0.0),
		NetFixture.stream("congestion", [NetFixture.work("congestion_study", "grid_analysts", 6.0)], 0.0)])
	assert_eq(OfficeTells.bands(net)["grid_study_tray"], OfficeTells.LOW, "nothing waits")
	var high: int = OfficeTells.THRESHOLDS["grid_study_tray"][1]
	for i in high - 2:
		net.open_order(net.stream("connections"))
	for i in 2:
		net.open_order(net.stream("congestion"))
	assert_eq(OfficeTells.readings(net)["grid_study_tray"], high, "the congestion studies lie in the same tray")
	assert_eq(OfficeTells.bands(net)["grid_study_tray"], OfficeTells.HIGH)
	net.advance_days(28)
	assert_eq(OfficeTells.bands(net)["grid_study_tray"], OfficeTells.LOW, "studied")


func test_the_reinforcement_board_counts_the_streets_waiting_for_their_reinforcement() -> void:
	var net := NetFixture.net([NetFixture.pool("p")], [
		NetFixture.stream("connections", [NetFixture.wait("grid_reinforcement", 120.0)], 0.0)])
	var high: int = OfficeTells.THRESHOLDS["reinforcement_board"][1]
	for i in high:
		net.open_order(net.stream("connections"))
	assert_eq(OfficeTells.bands(net)["reinforcement_board"], OfficeTells.HIGH)
	net.advance_days(121)
	assert_eq(OfficeTells.bands(net)["reinforcement_board"], OfficeTells.LOW, "reinforced")


func test_the_congestion_list_is_the_waiting_list_for_capacity() -> void:
	var net := NetFixture.net([NetFixture.pool("p")], [
		NetFixture.stream("congestion", [NetFixture.wait("capacity_queue", 90.0)], 0.0)])
	var mid: int = OfficeTells.THRESHOLDS["congestion_list"][0]
	for i in mid:
		net.open_order(net.stream("congestion"))
	assert_eq(OfficeTells.bands(net)["congestion_list"], OfficeTells.MID)
	net.advance_days(91)
	assert_eq(OfficeTells.bands(net)["congestion_list"], OfficeTells.LOW)


func test_the_office_on_the_2e_follows_the_region() -> void:
	var office := _office()
	for m in ["fix_silo_kpis", "look_at_grid_study", "fix_unused_capacity"]:
		office.session.missions.progress[m] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)
	assert_true(office.floors.go_to("second", "lift", true))
	assert_true(office.tells != null, "the 2e has tells")
	if office.tells == null:
		office.free()
		return
	assert_eq(office.tells.roots.keys().size(), SECOND.size(), "the 2e's tells, none of the 1e's")
	var net := office.session.region.net
	for s in net.streams:
		_finished(net, s.id, OfficeTells.KPI_MIN_FINISHED * 10, false)
	office.tells.refresh()
	assert_true(OfficeTells.node(office.geometry, "obeya_board_high").visible, "every card red")
	var said := office.tells.look("obeya_board")
	assert_false(said.is_empty())
	var noted := office.session.gemba.journal.filter(func(e: Dictionary) -> bool: return e["text"] == said)
	assert_eq(noted.size(), 1)
	assert_eq(noted[0]["place"] if not noted.is_empty() else "", "Directie & Obeya",
		"a board with no team's place is noted under its room")
	office.free()


func test_one_variant_shows_per_tell() -> void:
	var geometry: Node3D = load(MODEL).instantiate()
	assert_eq(OfficeTells.show(geometry, {"intake_stack": OfficeTells.HIGH, "prep_tray": OfficeTells.LOW,
		"planning_board": OfficeTells.MID}), 3)
	var shown := func(id: String) -> bool: return OfficeTells.node(geometry, id).visible
	assert_true(shown.call("intake_stack_high"))
	assert_false(shown.call("intake_stack_low"))
	assert_false(shown.call("intake_stack_mid"))
	assert_true(shown.call("prep_tray_low"))
	assert_false(shown.call("prep_tray_high"))
	assert_true(shown.call("planning_board_mid"))
	OfficeTells.show(geometry, {"intake_stack": OfficeTells.LOW})
	assert_true(shown.call("intake_stack_low"))
	assert_false(shown.call("intake_stack_high"))
	geometry.free()


func test_the_office_on_the_1e_follows_the_region() -> void:
	var office: Office = load("res://src/world/office/office.tscn").instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	assert_true(office.tells != null, "the 1e has tells")
	var net := office.session.region.net
	var intake := net.step_at("connections.intake")
	for i in 60:
		net.open_order(net.stream("connections"))
	office.tells.refresh()
	assert_true(OfficeTells.node(office.geometry, "intake_stack_high").visible, "the queue is long")
	net.queue_of(intake).clear()
	net.advance(1)
	office.tells.refresh()
	assert_false(OfficeTells.node(office.geometry, "intake_stack_high").visible, "the queue is gone")
	office.free()


## The content's tells (problems_tier1.yaml `tells:`, checked by tools/build_content.py
## against its TELLS) are the ones this reads.
func test_every_tell_the_content_names_is_read_here() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/problems_tier1.json"))
	var named := 0
	for p: Dictionary in doc["problems"]:
		for t: Dictionary in p.get("tells", []):
			named += 1
			assert_true(OfficeTells.THRESHOLDS.has(t["tell"]), "%s: tell %s" % [p["id"], t["tell"]])
	assert_true(named >= 3, "the 1e's problems list tells")


# --- looking closer (PLAN 2.15): E or a click at a tell, the camera moves in, one line says
# what you see (world.yaml `tells:` by the variant shown, or an open problem's own text).

const LOOKS := {"intake_stack": {"place": "connections.intake", "low": "Weinig.", "mid": "Wat.", "high": "Veel."}}


func _office() -> Office:
	var office: Office = load("res://src/world/office/office.tscn").instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _problem_on(tell: String, text: String) -> ProblemDef:
	var p := ProblemDef.from_dict({"id": "p", "name": "Een probleem", "step": "connections.intake", "waste": "waiting",
		"severity": "low", "visibility": "subtle", "kpi": "lead_time", "root_cause": "x",
		"tells": [{"tell": tell, "text": text}]})
	assert_eq(p.error, "")
	return p


func test_the_line_follows_the_variant_shown() -> void:
	for band in OfficeTells.VARIANTS.size():
		assert_eq(OfficeTells.text("intake_stack", band, LOOKS, []), LOOKS["intake_stack"][OfficeTells.VARIANTS[band]])
	assert_eq(OfficeTells.text("prep_tray", OfficeTells.HIGH, LOOKS, []), "", "no words for it: nothing")


func test_an_open_problem_on_the_tell_speaks_from_mid_up() -> void:
	var open: Array[ProblemDef] = [_problem_on("intake_stack", "Hoger dan het werk van een dag.")]
	assert_eq(OfficeTells.text("intake_stack", OfficeTells.HIGH, LOOKS, open), "Hoger dan het werk van een dag.")
	assert_eq(OfficeTells.text("intake_stack", OfficeTells.MID, LOOKS, open), "Hoger dan het werk van een dag.")
	assert_eq(OfficeTells.text("intake_stack", OfficeTells.LOW, LOOKS, open), "Weinig.", "a low pile shows nothing odd")
	var other: Array[ProblemDef] = [_problem_on("prep_tray", "Vol.")]
	assert_eq(OfficeTells.text("intake_stack", OfficeTells.HIGH, LOOKS, other), "Veel.")


func test_every_tell_has_words_for_each_variant_and_none_names_a_problem() -> void:
	var looks := OfficeBuilding.load_from(Catalog.DATA_DIR).tells
	var problems: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/problems_tier1.json"))
	for tell: String in OfficeTells.THRESHOLDS:
		assert_true(looks.has(tell), "world.yaml tells: " + tell)
		for v in OfficeTells.VARIANTS:
			var line: String = looks.get(tell, {}).get(v, "")
			assert_false(line.is_empty(), "%s %s" % [tell, v])
			for p: Dictionary in problems["problems"]:
				assert_false(line.to_lower().contains(str(p["name"]).to_lower()), "%s %s names %s" % [tell, v, p["id"]])


func test_looking_at_a_tell_frames_it_says_what_you_see_and_notes_it_once() -> void:
	var office := _office()
	var looks := OfficeBuilding.load_from(Catalog.DATA_DIR).tells
	var band: int = OfficeTells.bands(office.session.region.net)["revision_cabinet"]
	var said := office.tells.look("revision_cabinet")
	assert_eq(said, looks["revision_cabinet"][OfficeTells.VARIANTS[band]])
	assert_true(office.rig.inspecting(), "the camera moves to it")
	assert_eq(office.tells.line.text, said, "the line shows in the world")
	assert_true(office.tells.line.visible)
	var noted := func() -> Array: return office.session.gemba.journal.filter(
		func(e: Dictionary) -> bool: return e["text"] == said)
	assert_eq(noted.call().size(), 1, "Notities holds it as a Waarneming")
	assert_eq(noted.call()[0]["place"], "connections.revision")
	office.tells.look("revision_cabinet")
	assert_eq(noted.call().size(), 1, "once")
	office.free()


func test_the_line_goes_and_the_camera_comes_back_when_you_walk_on() -> void:
	var office := _office()
	office.player.position = Vector3(-16.4, 0, -12.6)
	office.tells.look("revision_cabinet")
	office.player.position += Vector3(1.0, 0, 0)
	office.tells._process(0.1)
	assert_false(office.tells.line.visible)
	assert_false(office.rig.inspecting())
	office.tells.look("revision_cabinet")
	office.tells._process(60.0)
	assert_true(office.tells.line.visible, "one long frame (a hitch) does not end it")
	for i in ceili(OfficePerson.say_time(office.tells.line.text) / OfficeTells.MAX_STEP):
		office.tells._process(OfficeTells.MAX_STEP)
	assert_false(office.tells.line.visible, "it fades after its time")
	assert_false(office.rig.inspecting())
	office.free()


func test_e_beside_a_tell_looks_at_it_and_a_place_ring_still_wins_on_its_ring() -> void:
	var office := _office()
	var cabinet := OfficeTells.node(office.geometry, "revision_cabinet")
	var beside := Vector3(-16.9, 0, -12.6)   # east of the cabinet by the west wall
	assert_eq(office.target_near(beside), cabinet)
	assert_eq(office.prompt_near(beside), office.tr(OfficeTells.PROMPT))
	var ring := office.interactable("place:connections.intake")
	assert_eq(office.target_near(ring.position), ring, "on the intake ring, Intake")
	office.use(cabinet)
	assert_true(office.tells.line.visible)
	assert_eq(office.prompt_near(beside), "", "no prompt while you look")
	office.free()
