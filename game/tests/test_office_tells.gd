extends TestCase
## The world shows the work (PLAN 2.6, design §1.5): props on the 1e read the region's
## numbers and show one of three heights.

const MODEL := "res://assets/office/office.glb"


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
	assert_eq(OfficeTells.bands(net), {"intake_stack": 0, "prep_tray": 0, "planning_board": 0})


func test_the_1e_model_has_every_tell_with_three_variants() -> void:
	var geometry: Node3D = load(MODEL).instantiate()
	for tell: String in OfficeTells.THRESHOLDS:
		var root := OfficeTells.node(geometry, tell)
		assert_true(root != null, "tell_%s in office.glb" % tell)
		for v in OfficeTells.VARIANTS:
			assert_true(OfficeTells.node(geometry, "%s_%s" % [tell, v]) != null, "tell_%s_%s" % [tell, v])
	geometry.free()


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
