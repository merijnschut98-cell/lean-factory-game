extends TestCase



func _simple(ftr: float = 1.0, arrivals: float = 4.0, seed_value: int = 7) -> Network:
	return NetFixture.net([NetFixture.pool("team", 2)], [NetFixture.stream("s", [NetFixture.work("do", "team", 1.0, ftr)], arrivals)], [], seed_value)


func test_config_errors_are_reported() -> void:
	var bad := NetFixture.net([NetFixture.pool("team")], [NetFixture.stream("s", [NetFixture.work("do", "nobody", 1.0)])])
	assert_true("unknown pool" in bad.error, bad.error)
	assert_true("cannot read" in Network.load_file("res://data/nope.json").error)


func test_orders_flow_through_and_finish() -> void:
	var net := _simple()
	net.advance_days(14)
	var s := net.stream("s")
	assert_true(s.finished.size() > 20, "finished %d" % s.finished.size())
	var k := s.kpis(net.time, 14)
	assert_eq(k["first_time_right"], 1.0)
	assert_true(k["lead_days_p50"] < 1.0, "a 1-hour job with spare capacity finishes the same day")


func test_same_seed_replays_exactly() -> void:
	var a := _simple(0.8)
	var b := _simple(0.8)
	a.advance_days(20)
	b.advance_days(20)
	assert_eq(a.stream("s").finished, b.stream("s").finished)


func test_nothing_happens_at_the_weekend() -> void:
	var net := _simple()
	net.advance_days(5)  # to Saturday 00:00
	var done := net.stream("s").finished.size()
	var arrived := net.stream("s").active + done
	net.advance_days(2)  # the weekend
	assert_eq(net.stream("s").finished.size(), done)
	assert_eq(net.stream("s").active + net.stream("s").finished.size(), arrived)


func test_rework_lowers_first_time_right() -> void:
	var net := _simple(0.5, 6.0)
	net.advance_days(56)
	var k := net.stream("s").kpis(net.time, 56)
	assert_between(k["first_time_right"], 0.4, 0.6)
	assert_true(net.stream("s").steps[0].reworked > 0)


func test_rework_can_wait_for_the_customer() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 3)], [NetFixture.stream("s", [
		NetFixture.work("intake", "team", 0.5, 0.5, {"rework_wait_days": 5}),
	], 4.0)])
	net.advance_days(56)
	var k := net.stream("s").kpis(net.time, 56)
	assert_true(k["lead_days_p85"] >= 5.0, "reworked orders wait ~5 days: p85 %s" % k["lead_days_p85"])


func test_external_wait_takes_its_time() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 2)], [NetFixture.stream("s", [NetFixture.wait("permit", 10.0, 0.2), NetFixture.work("do", "team", 0.5)])])
	net.advance_days(60)
	var k := net.stream("s").kpis(net.time, 30)
	assert_between(k["lead_days_p50"], 8.0, 13.0)


func test_applies_skips_a_share_of_orders() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 4)], [NetFixture.stream("s", [
		NetFixture.work("study", "team", 0.5, 1.0, {"applies": 0.25}), NetFixture.work("do", "team", 0.5),
	], 10.0)])
	net.advance_days(56)
	var steps := net.stream("s").steps
	assert_between(steps[0].entered / float(steps[1].entered), 0.18, 0.32)


func test_stockout_makes_orders_wait_for_delivery() -> void:
	var kit := {"id": "kit", "name": "kit", "level": 0, "reorder_point": 2, "order_quantity": 50, "lead_days": 10}
	var net := NetFixture.net([NetFixture.pool("team", 2)], [NetFixture.stream("s", [NetFixture.material("take", "kit"), NetFixture.work("do", "team", 0.5)])], [kit])
	net.advance_days(4)
	assert_eq(net.stream("s").finished.size(), 0, "nothing finishes before the delivery")
	assert_true(net.stock["kit"].waiting.size() > 0)
	assert_eq(net.stock["kit"].on_order(), 50, "one purchase order, not one per stock-out")
	net.advance_days(6.6)  # the delivery lands on day 10
	assert_true(net.stream("s").finished.size() > 0)
	assert_eq(net.stock["kit"].waiting.size(), 0, "the delivery released every waiting order")


func test_urgent_stream_preempts_planned_work() -> void:
	var net := NetFixture.net([NetFixture.pool("crew", 1)], [
		NetFixture.stream("planned", [NetFixture.work("job", "crew", 6.0)], 3.0, 1),
		NetFixture.stream("outage", [NetFixture.work("fix", "crew", 1.0)], 1.0, 5),
	])
	net.advance_days(28)
	var planned := net.stream("planned").kpis(net.time, 28)
	var outage := net.stream("outage").kpis(net.time, 28)
	assert_true(outage["lead_days_p85"] < 1.0, "outages fixed within the day: %s" % outage["lead_days_p85"])
	assert_true(planned["lead_days_p50"] > outage["lead_days_p50"])
	var preempted := net.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "preempted")
	assert_true(preempted.size() > 0, "some planned work was interrupted")


func test_events_can_be_drained() -> void:
	var net := _simple()
	net.advance_days(1)
	assert_true(net.drain_events().size() > 0)
	assert_eq(net.events.size(), 0)
