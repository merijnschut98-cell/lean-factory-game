extends TestCase
## Problem and countermeasure effects on top of the content's base values.


func _net() -> Network:
	return NetFixture.net([NetFixture.pool("prep", 2), NetFixture.pool("crew", 4)], [
		NetFixture.stream("connections", [
			NetFixture.work("intake", "prep", 1.0, 0.75),
			NetFixture.wait("permit", 10.0),
			NetFixture.work("build", "crew", 4.0),
		], 20.0),
		NetFixture.stream("congestion", [NetFixture.work("intake", "prep", 1.0, 0.75)], 5.0),
	], [NetFixture.stock("kit", 50, 20, 50, 10)])


func _step(net: Network, stream_id: String, step_id: String) -> SimStep:
	for step in net.stream(stream_id).steps:
		if step.id == step_id:
			return step
	return null


func _effect(target: String, property: String, value: float) -> Dictionary:
	return {"target": target, "property": property, "value": value}


func test_touch_time_factor_reaches_capacity() -> void:
	var net := _net()
	var before: float = Capacity.analyse(net)["pools"]["crew"]["load"]
	assert_eq(net.set_effects("problem:custom_design", [_effect("connections.build", "touch_time", 1.5)]), "")
	assert_eq(_step(net, "connections", "build").touch_minutes, 360)
	assert_near(Capacity.analyse(net)["pools"]["crew"]["load"], before * 1.5, 1e-6)


func test_clearing_restores_base_exactly() -> void:
	var net := _net()
	var step := _step(net, "connections", "intake")
	var pool := net.pools["crew"]
	var kit := net.stock["kit"]
	net.set_effects("a", [
		_effect("connections.intake", "ftr", -0.1), _effect("connections.intake", "touch_time", 1.37),
		_effect("connections.permit", "wait_time", 0.5), _effect("crew", "headcount", 3),
		_effect("crew", "availability", -0.2), _effect("kit", "lead_time", 2.0), _effect("kit", "reorder_point", 10),
		_effect("connections", "demand", 1.3), _effect("connections.intake", "applies", -0.4),
	])
	assert_ne(step.ftr, 0.75)
	net.clear_effects("a")
	assert_eq(step.ftr, 0.75)
	assert_eq(step.touch_minutes, 60)
	assert_eq(step.applies, 1.0)
	assert_eq(_step(net, "connections", "permit").wait_minutes, SimCalendar.days(10))
	assert_eq(pool.headcount, 4)
	assert_eq(pool.availability, 1.0)
	assert_eq(kit.lead_minutes, SimCalendar.days(10))
	assert_eq(kit.reorder_point, 20)
	assert_eq(net.stream("connections").demand, 1.0)
	assert_eq(net.modifiers.sources(), {})


func test_sources_stack() -> void:
	var net := _net()
	net.set_effects("problem:a", [_effect("connections.build", "touch_time", 1.5), _effect("prep", "headcount", -1)])
	net.set_effects("cm:b", [_effect("connections.build", "touch_time", 0.5), _effect("prep", "headcount", 2)])
	assert_eq(_step(net, "connections", "build").touch_minutes, 180, "4 h × 1.5 × 0.5")
	assert_eq(net.pools["prep"].headcount, 3, "2 − 1 + 2")


func test_setting_a_source_again_replaces_it() -> void:
	var net := _net()
	net.set_effects("problem:a", [_effect("crew", "headcount", -1)])
	net.set_effects("problem:a", [_effect("crew", "headcount", -2)])
	assert_eq(net.pools["crew"].headcount, 2)


func test_step_targets_are_scoped_to_their_stream() -> void:
	var net := _net()
	net.set_effects("problem:incomplete", [_effect("connections.intake", "ftr", -0.15)])
	assert_near(_step(net, "connections", "intake").ftr, 0.6, 1e-9)
	assert_eq(_step(net, "congestion", "intake").ftr, 0.75)


func test_bounds_clamp() -> void:
	var net := _net()
	net.set_effects("x", [_effect("connections.intake", "ftr", -0.9), _effect("crew", "headcount", -20),
		_effect("crew", "availability", 0.5)])
	assert_eq(_step(net, "connections", "intake").ftr, 0.05)
	assert_eq(net.pools["crew"].headcount, 0)
	assert_eq(net.pools["crew"].availability, 1.0)
	assert_eq(Capacity.analyse(net)["pools"]["crew"]["utilisation"], INF, "nobody left to do the work")


func test_invalid_effects_change_nothing() -> void:
	var net := _net()
	net.set_effects("ok", [_effect("crew", "headcount", 1)])
	var bad := [
		[_effect("crew", "headcount", 1), _effect("nobody", "headcount", 1)],
		[_effect("crew", "speed", 2.0)],
		[_effect("connections.nope", "ftr", 0.1)],
		[_effect("crew", "touch_time", 2.0)],
		[_effect("connections.build", "touch_time", 0.0)],
		[{"target": "crew", "property": "headcount"}],
		[_effect("connections.permit", "ftr", 0.1)],
	]
	for effects: Array in bad:
		var error := net.set_effects("bad", effects)
		assert_ne(error, "", str(effects))
	assert_eq(net.pools["crew"].headcount, 5, "the valid source still applies, the bad ones never did")
	assert_eq(net.modifiers.sources().keys(), ["ok"])


func test_demand_scales_arrivals() -> void:
	var normal := _net()
	var busy := _net()
	busy.set_effects("event:new_housing", [_effect("connections", "demand", 2.0)])
	assert_near(Capacity.analyse(busy)["pools"]["crew"]["load"], 2.0 * Capacity.analyse(normal)["pools"]["crew"]["load"], 1e-6)
	normal.advance_days(28)
	busy.advance_days(28)
	var ratio := NetFixture.events(busy, "arrived").size() / float(NetFixture.events(normal, "arrived").size())
	assert_between(ratio, 1.5, 2.3)


func test_scaled() -> void:
	var half := SimModifiers.scaled([_effect("a.b", "touch_time", 1.4), _effect("c", "headcount", -2)], 0.5)
	assert_near(half[0]["value"], 1.2, 1e-9)
	assert_near(half[1]["value"], -1.0, 1e-9)
	assert_eq(half[0]["target"], "a.b")
