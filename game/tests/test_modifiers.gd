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
	return net.stream(stream_id).step(step_id)


## The current value of every field `effects` touch, in order.
func _fields(net: Network, effects: Array) -> Array:
	var out := []
	for e: Dictionary in effects:
		for obj: Object in SimModifiers.targets(net, e["property"], e["target"]):
			out.append(obj.get(SimModifiers.PROPERTIES[e["property"]]["field"]))
	return out


func test_touch_time_factor_reaches_capacity() -> void:
	var net := _net()
	var before: float = Capacity.analyse(net)["pools"]["crew"]["load"]
	assert_eq(net.set_effects("problem:custom_design", [NetFixture.effect("connections.build", "touch_time", 1.5)]), "")
	assert_eq(_step(net, "connections", "build").touch_minutes, 360)
	assert_near(Capacity.analyse(net)["pools"]["crew"]["load"], before * 1.5, 1e-6)


func test_clearing_restores_base_exactly() -> void:
	var net := _net()
	var effects: Array = []
	for property: String in SimModifiers.PROPERTIES:
		var spec: Dictionary = SimModifiers.PROPERTIES[property]
		var target: String = {"step": "connections.intake", "pool": "crew", "stock": "kit", "stream": "connections",
			"arrivals": "connections"}[spec["kind"]]
		if spec.get("step_kind") == SimStep.Kind.WAIT:
			target = "connections.permit"
		var value: Variant
		match spec["op"]:
			SimModifiers.Op.MUL:
				value = 1.37
			SimModifiers.Op.ADD:
				value = 2
			SimModifiers.Op.SET:
				value = {"reserve": {"stream": "congestion", "people": 1}, "preempts": true, "starts_with": "intake",
					"wip_limit": 2, "start_rule": "pull", "order_rule": "shortest"}[property]
		effects.append(NetFixture.effect(target, property, value))
	var before := _fields(net, effects)
	assert_eq(net.set_effects("a", effects), "")
	assert_ne(_fields(net, effects), before)
	net.clear_effects("a")
	assert_eq(_fields(net, effects), before, "every property back to its exact base value")
	assert_eq(net.effects(), {})


func test_every_property_names_a_real_field() -> void:
	var net := _net()
	var objects := {"step": _step(net, "connections", "intake"), "pool": net.pools["crew"], "stock": net.stock["kit"],
		"stream": net.stream("connections"), "arrivals": net.stream("connections").arrivals[0]}
	for property: String in SimModifiers.PROPERTIES:
		var spec: Dictionary = SimModifiers.PROPERTIES[property]
		assert_true(spec["field"] in objects[spec["kind"]], "%s → %s" % [property, spec["field"]])


func test_sources_stack() -> void:
	var net := _net()
	net.set_effects("problem:a", [NetFixture.effect("connections.build", "touch_time", 1.5), NetFixture.effect("prep", "headcount", -1)])
	net.set_effects("cm:b", [NetFixture.effect("connections.build", "touch_time", 0.5), NetFixture.effect("prep", "headcount", 2)])
	assert_eq(_step(net, "connections", "build").touch_minutes, 180, "4 h × 1.5 × 0.5")
	assert_eq(net.pools["prep"].headcount, 3, "2 − 1 + 2")


func test_setting_a_source_again_replaces_it() -> void:
	var net := _net()
	net.set_effects("problem:a", [NetFixture.effect("crew", "headcount", -1)])
	net.set_effects("problem:a", [NetFixture.effect("crew", "headcount", -2)])
	assert_eq(net.pools["crew"].headcount, 2)


func test_step_targets_are_scoped_to_their_stream() -> void:
	var net := _net()
	net.set_effects("problem:incomplete", [NetFixture.effect("connections.intake", "ftr", -0.15)])
	assert_near(_step(net, "connections", "intake").ftr, 0.6, 1e-9)
	assert_eq(_step(net, "congestion", "intake").ftr, 0.75)


func test_bounds_clamp() -> void:
	var net := _net()
	net.set_effects("x", [NetFixture.effect("connections.intake", "ftr", -0.9), NetFixture.effect("crew", "headcount", -20),
		NetFixture.effect("crew", "availability", 0.5)])
	assert_eq(_step(net, "connections", "intake").ftr, 0.05)
	assert_eq(net.pools["crew"].headcount, 0)
	assert_eq(net.pools["crew"].availability, 1.0)
	assert_eq(Capacity.analyse(net)["pools"]["crew"]["utilisation"], INF, "nobody left to do the work")


func test_invalid_effects_change_nothing() -> void:
	var net := _net()
	net.set_effects("ok", [NetFixture.effect("crew", "headcount", 1)])
	var bad := [
		[NetFixture.effect("crew", "headcount", 1), NetFixture.effect("nobody", "headcount", 1)],
		[NetFixture.effect("crew", "speed", 2.0)],
		[NetFixture.effect("connections.nope", "ftr", 0.1)],
		[NetFixture.effect("crew", "touch_time", 2.0)],
		[NetFixture.effect("connections.build", "touch_time", 0.0)],
		[{"target": "crew", "property": "headcount"}],
		[NetFixture.effect("connections.permit", "ftr", 0.1)],
	]
	for effects: Array in bad:
		var error := net.set_effects("bad", effects)
		assert_ne(error, "", str(effects))
	assert_eq(net.pools["crew"].headcount, 5, "the valid source still applies, the bad ones never did")
	assert_eq(net.effects().keys(), ["ok"])


func test_demand_scales_arrivals() -> void:
	var normal := _net()
	var busy := _net()
	busy.set_effects("event:new_housing", [NetFixture.effect("connections", "demand", 2.0)])
	assert_near(Capacity.analyse(busy)["pools"]["crew"]["load"], 2.0 * Capacity.analyse(normal)["pools"]["crew"]["load"], 1e-6)
	normal.advance_days(28)
	busy.advance_days(28)
	var ratio := NetFixture.events(busy, "arrived").size() / float(NetFixture.events(normal, "arrived").size())
	assert_between(ratio, 1.5, 2.3)


func test_scaled() -> void:
	var half := SimModifiers.scaled([NetFixture.effect("a.b", "touch_time", 1.4), NetFixture.effect("c", "headcount", -2)], 0.5)
	assert_near(half[0]["value"], 1.2, 1e-9)
	assert_near(half[1]["value"], -1.0, 1e-9)
	assert_eq(half[0]["target"], "a.b")


## An arrival source with an id can be targeted on its own ("stream.source"),
## e.g. digging damage only adds daytime outages.
func test_demand_can_target_one_arrival_source() -> void:
	var day := NetFixture.block("mon-fri", "08:00", "17:00")
	day.merge({"id": "daytime", "per_week": 10.0})
	var night := NetFixture.block("mon-sun", "00:00", "24:00")
	night.merge({"id": "around_the_clock", "per_week": 8.0})
	var net := NetFixture.net([NetFixture.pool("crew", 4)], [
		NetFixture.stream("outages", [NetFixture.work("repair", "crew", 1.0)], 0.0, 3, {"arrivals": [day, night]}),
	])
	assert_eq(net.set_effects("problem:digging", [NetFixture.effect("outages.daytime", "demand", 1.5)]), "")
	assert_near(net.stream("outages").per_week(), 23.0, 1e-9, "15 by day + 8 around the clock")
	assert_ne(net.set_effects("bad", [NetFixture.effect("outages.ghost", "demand", 2.0)]), "")



## A lever takes the value of the latest source. Setting a source again keeps
## its place; moving it last makes it the latest without switching anything off.
func test_moving_a_source_last_makes_its_lever_win() -> void:
	var net := _net()
	var board := [NetFixture.effect("prep", "order_rule", "oldest")]
	net.set_effects("board", board)
	net.set_effects("cm", [NetFixture.effect("prep", "order_rule", "due"), NetFixture.effect("connections", "wip_limit", 3)])
	var prep := net.pools["prep"]
	assert_eq(prep.order_rule, "due", "the latest source wins")
	net.set_effects("board", board)
	assert_eq(prep.order_rule, "due", "setting it again keeps its place")
	net.move_effects_last(["board"])
	assert_eq(prep.order_rule, "oldest")
	assert_eq(net.effects().keys(), ["cm", "board"])
	assert_eq(net.stream("connections").wip_limit, 3, "the other sources stay on")
	net.move_effects_last(["ghost"])
	assert_eq(net.effects().keys(), ["cm", "board"], "an unknown source changes nothing")
