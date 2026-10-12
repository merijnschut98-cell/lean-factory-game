extends TestCase



func test_visits_without_rework_are_one() -> void:
	var net := NetFixture.net([NetFixture.pool("t")], [NetFixture.stream("s", [NetFixture.work("a", "t", 1.0), NetFixture.work("b", "t", 1.0)])])
	var v := Capacity.expected_visits(net.stream("s"))
	assert_near(v[0], 1.0, 1e-6)
	assert_near(v[1], 1.0, 1e-6)


func test_rework_to_same_step_is_one_over_ftr() -> void:
	var net := NetFixture.net([NetFixture.pool("t")], [NetFixture.stream("s", [NetFixture.work("a", "t", 1.0, 0.8)])])
	assert_near(Capacity.expected_visits(net.stream("s"))[0], 1.25, 1e-6)


func test_rework_to_an_earlier_step_loads_the_steps_between() -> void:
	var net := NetFixture.net([NetFixture.pool("t")], [NetFixture.stream("s", [
		NetFixture.work("a", "t", 1.0), NetFixture.work("b", "t", 1.0), NetFixture.work("c", "t", 1.0, 0.5, {"rework_to": "b"}),
	])])
	var v := Capacity.expected_visits(net.stream("s"))
	assert_near(v[0], 1.0, 1e-6)
	assert_near(v[1], 2.0, 1e-6)
	assert_near(v[2], 2.0, 1e-6)


func test_applies_scales_visits() -> void:
	var net := NetFixture.net([NetFixture.pool("t")], [NetFixture.stream("s", [NetFixture.work("a", "t", 1.0, 1.0, {"applies": 0.25})])])
	assert_near(Capacity.expected_visits(net.stream("s"))[0], 0.25, 1e-6)


func test_constraint_is_the_most_loaded_pool_on_the_route() -> void:
	var net := NetFixture.net([NetFixture.pool("fast", 2), NetFixture.pool("slow", 1)], [NetFixture.stream("s", [
		NetFixture.work("a", "fast", 2.0), NetFixture.work("b", "slow", 4.0),
	], 2.0)])
	var r := Capacity.analyse(net)
	assert_near(r["pools"]["slow"]["utilisation"], 1.0, 1e-6)  # 10/week × 4 h vs 1 × 40 h
	assert_near(r["pools"]["fast"]["utilisation"], 0.25, 1e-6)
	assert_eq(r["streams"]["s"]["constraint_pool"], "slow")
	assert_eq(r["streams"]["s"]["constraint_step"], "b")
	assert_near(r["streams"]["s"]["capacity_per_week"], 10.0, 1e-6)


func test_shared_pool_load_counts_for_both_streams() -> void:
	var net := NetFixture.net([NetFixture.pool("crew", 2)], [
		NetFixture.stream("x", [NetFixture.work("a", "crew", 4.0)], 2.0),
		NetFixture.stream("y", [NetFixture.work("b", "crew", 2.0)], 2.0),
	])
	var r := Capacity.analyse(net)
	assert_near(r["pools"]["crew"]["utilisation"], 0.75, 1e-6)  # (40 + 20) / 80 hours a week
	assert_near(r["streams"]["y"]["capacity_per_week"], 20.0, 1e-6)  # (80 − 40) / 2


func test_a_step_served_by_two_pools_splits_its_load_by_the_hours_they_cover() -> void:
	var net := NetFixture.net([
		NetFixture.pool("day", 1, 1.0, [NetFixture.block("mon-fri", "07:00", "15:00")]),
		NetFixture.pool("on_call", 1, 1.0, [
			NetFixture.block("mon-fri", "00:00", "07:00"), NetFixture.block("mon-fri", "15:00", "24:00"),
			NetFixture.block("sat-sun", "00:00", "24:00"),
		]),
	], [NetFixture.stream("outages", [NetFixture.work("fix", ["day", "on_call"], 1.0)], 0.0, 3, {"arrivals": NetFixture.always(168.0)})])
	var r := Capacity.analyse(net)
	assert_near(r["pools"]["day"]["load"], 40.0, 1e-6)  # the 40 of 168 hours the day crew covers
	assert_near(r["pools"]["on_call"]["load"], 128.0, 1e-6)
	assert_near(r["pools"]["on_call"]["utilisation"], 1.0, 1e-6)
