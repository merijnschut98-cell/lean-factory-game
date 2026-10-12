extends TestCase



func _simple(ftr: float = 1.0, arrivals: float = 20.0, seed_value: int = 7) -> Network:
	return NetFixture.net([NetFixture.pool("team", 2)], [NetFixture.stream("s", [NetFixture.work("do", "team", 1.0, ftr)], arrivals)], [], seed_value)


func test_config_errors_are_reported() -> void:
	var bad := NetFixture.net([NetFixture.pool("team")], [NetFixture.stream("s", [NetFixture.work("do", "nobody", 1.0)])])
	assert_true("unknown pool" in bad.error, bad.error)
	assert_true("cannot read" in Network.load_file("res://data/nope.json").error)
	var no_hours := NetFixture.pool("team")
	no_hours.erase("schedule")
	assert_true("bad schedule" in NetFixture.net([no_hours], [NetFixture.stream("s", [NetFixture.work("do", "team", 1.0)])]).error)


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
	var net := _simple(0.5, 30.0)
	net.advance_days(56)
	var k := net.stream("s").kpis(net.time, 56)
	assert_between(k["first_time_right"], 0.4, 0.6)
	assert_true(net.stream("s").steps[0].stats_since(0)["reworked"] > 0)


func test_rework_can_wait_for_the_customer() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 3)], [NetFixture.stream("s", [
		NetFixture.work("intake", "team", 0.5, 0.5, {"rework_wait_days": 5}),
	], 20.0)])
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
	], 50.0)])
	net.advance_days(56)
	var steps := net.stream("s").steps
	assert_between(steps[0].stats_since(0)["entered"] / float(steps[1].stats_since(0)["entered"]), 0.18, 0.32)


func test_stockout_makes_orders_wait_for_delivery() -> void:
	var kit := NetFixture.stock("kit", 0, 2, 50, 10)
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
		NetFixture.stream("planned", [NetFixture.work("job", "crew", 6.0)], 15.0, 1),
		NetFixture.stream("outage", [NetFixture.work("fix", "crew", 1.0)], 5.0, 5, {"preempts": true}),
	])
	net.advance_days(28)
	var planned := net.stream("planned").kpis(net.time, 28)
	var outage := net.stream("outage").kpis(net.time, 28)
	assert_true(outage["lead_days_p85"] < 1.0, "outages fixed within the day: %s" % outage["lead_days_p85"])
	assert_true(planned["lead_days_p50"] > outage["lead_days_p50"])
	assert_true(NetFixture.events(net, "preempted").size() > 0, "some planned work was interrupted")


func test_priority_alone_does_not_interrupt_work() -> void:
	var net := NetFixture.net([NetFixture.pool("crew", 1)], [
		NetFixture.stream("planned", [NetFixture.work("job", "crew", 6.0)], 15.0, 1),
		NetFixture.stream("urgent", [NetFixture.work("fix", "crew", 1.0)], 5.0, 5),
	])
	net.advance_days(28)
	assert_eq(NetFixture.events(net, "preempted").size(), 0, "only streams with preempts interrupt work in progress")


func test_around_the_clock_pool_works_at_the_weekend() -> void:
	var net := NetFixture.net([NetFixture.pool("on_call", 1, 1.0, [NetFixture.block("mon-sun", "00:00", "24:00")])],
		[NetFixture.stream("outages", [NetFixture.work("fix", "on_call", 1.0)], 0.0, 3, {"arrivals": NetFixture.always(14.0)})])
	net.advance_days(5)
	var before := net.stream("outages").finished.size()
	net.advance_days(2)
	assert_true(net.stream("outages").finished.size() > before, "outages are fixed on Saturday and Sunday")


func test_arrivals_follow_their_schedule() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 4, 1.0, [NetFixture.block("mon-sun", "00:00", "24:00")])], [
		NetFixture.stream("office", [NetFixture.work("a", "team", 0.1)], 30.0),
		NetFixture.stream("outages", [NetFixture.work("b", "team", 0.1)], 0.0, 1, {"arrivals": NetFixture.always(30.0)}),
	])
	net.advance_days(28)
	var weekend := {"office": 0, "outages": 0}
	var night := {"office": 0, "outages": 0}
	for e in NetFixture.events(net, "arrived"):
		var m: int = e["t"] % SimCalendar.MINUTES_PER_DAY
		weekend[e["stream"]] += 1 if SimCalendar.weekday(e["t"]) >= 5 else 0
		night[e["stream"]] += 1 if m < 480 or m > 1020 else 0
	assert_eq(weekend["office"], 0)
	assert_eq(night["office"], 0)
	assert_true(weekend["outages"] > 10, "outages arrive at the weekend: %d" % weekend["outages"])
	assert_true(night["outages"] > 20, "and at night: %d" % night["outages"])


## Two pools serving one step: the night crew until 07:00, the day crew after.
func _relay() -> Network:
	return NetFixture.net([
		NetFixture.pool("night", 1, 1.0, [NetFixture.block("mon-sun", "00:00", "07:00"), NetFixture.block("mon-sun", "22:00", "24:00")]),
		NetFixture.pool("day", 1, 1.0, [NetFixture.block("mon-fri", "07:00", "15:00")]),
	], [NetFixture.stream("outages", [NetFixture.work("fix", ["night", "day"], 2.0)], 0.0, 3)])


func test_unfinished_work_is_handed_over_at_the_end_of_a_shift() -> void:
	var net := _relay()
	net.advance(360)  # Monday 06:00
	net.open_order(net.stream("outages"))
	net.advance(180)
	assert_eq(NetFixture.events(net, "handover").size(), 1, "the night crew hands over at 07:00")
	var done := net.stream("outages").finished
	assert_eq(done.size(), 1, "the day crew finishes it the same morning")
	assert_between(done[0]["done_at"], 470, 500)


func test_midnight_inside_a_shift_is_no_handover() -> void:
	var net := _relay()
	net.advance(23 * 60 + 30)  # Monday 23:30
	net.open_order(net.stream("outages"))
	net.advance(180)
	assert_eq(NetFixture.events(net, "handover").size(), 0)
	assert_eq(net.stream("outages").finished.size(), 1, "finished around 01:30")


func test_events_can_be_drained() -> void:
	var net := _simple()
	net.advance_days(1)
	assert_true(net.drain_events().size() > 0)
	assert_eq(net.events.size(), 0)


func test_step_statistics_by_window() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 1)], [NetFixture.stream("s", [NetFixture.work("do", "team", 2.0)], 0.0)])
	net.advance(480)  # Monday 08:00
	net.open_order(net.stream("s"))
	net.open_order(net.stream("s"))
	net.advance_days(1)
	var step := net.stream("s").step("do")
	var monday := step.stats_since(0)
	assert_eq([monday["entered"], monday["done"], monday["reworked"]], [2, 2, 0])
	assert_near(monday["queue_hours"], 1.0, 0.2, "the second order waited two hours, the first none")
	net.open_order(net.stream("s"))
	net.advance_days(1)
	var tuesday := step.stats_since(1)
	assert_eq([tuesday["entered"], tuesday["done"]], [1, 1], "only Tuesday's order in Tuesday's window")


func test_step_statistics_count_rework() -> void:
	var net := _simple(0.5, 30.0)
	net.advance_days(28)
	var stats := net.stream("s").step("do").stats_since(0)
	assert_eq(stats["reworked"], NetFixture.events(net, "rework").size())
	assert_between(stats["reworked"] / float(stats["done"] + stats["reworked"]), 0.4, 0.6)


## Actual load: busy people-hours over present people-hours, per day.
## 2 people × 40 h a week; 40 one-hour jobs a week → about half.
func test_actual_load_is_measured() -> void:
	var net := NetFixture.net([NetFixture.pool("crew", 2)], [
		NetFixture.stream("jobs", [NetFixture.work("job", "crew", 1.0)], 40.0),
	])
	net.advance_days(56)
	var crew: SimPool = net.pools["crew"]
	assert_between(crew.load_since(0), 0.45, 0.55)
	assert_between(crew.load_since(28), 0.4, 0.6, "a window of the last four weeks")
	assert_eq(crew.load_since(1000), 0.0, "no days, no load")

