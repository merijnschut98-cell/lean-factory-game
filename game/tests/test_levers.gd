extends TestCase
## Structural levers: reserved capacity, frozen planning window, the cost of
## interruption, batching and waits in parallel.

const MONDAY_8 := 480


func _crew(reserve: int = 0) -> Dictionary:
	var crew := NetFixture.pool("crew", 3)
	if reserve > 0:
		crew["reserve"] = {"stream": "outages", "people": reserve}
	return crew


## Planned work that keeps a crew of 3 overloaded, plus outages that pre-empt it.
func _busy_crew(reserve: int = 0, interrupt: Dictionary = {}) -> Network:
	return NetFixture.net([_crew(reserve), NetFixture.pool("planners", 1)], [
		NetFixture.stream("planned", [
			NetFixture.work("plan", "planners", 0.25),
			NetFixture.work("job", "crew", 6.0, 1.0, interrupt),
		], 25.0, 1),
		NetFixture.stream("outages", [NetFixture.work("fix", "crew", 1.0)], 10.0, 3, {"preempts": true}),
	])


func _max_planned_busy(net: Network, days: int) -> int:
	var most := 0
	for i in days * 144:
		net.advance(SimCalendar.TICK)
		var planned := net.pools["crew"].busy.filter(func(o: WorkOrder) -> bool: return o.stream.id == "planned")
		most = maxi(most, planned.size())
	return most


func test_reserve_keeps_people_free_for_outages() -> void:
	var without := _busy_crew()
	var with_reserve := _busy_crew(1)
	assert_eq(_max_planned_busy(without, 14), 3, "without a reserve planned work fills the crew")
	assert_eq(_max_planned_busy(with_reserve, 14), 2, "one monteur is held for outages")
	# The trade-off: far fewer interrupted jobs, but less planned work done.
	assert_true(NetFixture.events(with_reserve, "preempted").size() * 2 < NetFixture.events(without, "preempted").size())
	assert_true(with_reserve.stream("planned").finished.size() < without.stream("planned").finished.size())


func test_frozen_window_stops_preemption() -> void:
	var net := _busy_crew()
	assert_eq(net.set_effects("cm:frozen_window", [NetFixture.effect("outages", "preempts", false)]), "")
	net.advance_days(28)
	assert_eq(NetFixture.events(net, "preempted").size(), 0)
	assert_true(net.stream("outages").kpis(net.time, 28)["lead_days_p85"] > 0.1, "outages now wait for a free monteur")


func test_interrupted_work_is_replanned() -> void:
	var net := _busy_crew(0, {"interrupt_to": "plan", "interrupt_wait_days": 2})
	net.advance_days(28)
	var planned := net.stream("planned")
	var interrupted := NetFixture.events(net, "preempted").size()
	assert_true(interrupted > 0)
	assert_eq(planned.step("plan").entered - (planned.finished.size() + planned.active), interrupted,
		"every interrupted job went back to planning once more")


func _one_order(steps: Array) -> Network:
	return NetFixture.net([NetFixture.pool("team", 1)], [NetFixture.stream("s", steps, 0.0)])


func test_batched_wait_starts_on_the_batch_day() -> void:
	var net := _one_order([NetFixture.wait("permit", 3.0, 0.0, {"batch_days": 7}), NetFixture.work("do", "team", 0.5)])
	net.advance(SimCalendar.days(1) + 600)  # Tuesday 10:00
	net.open_order(net.stream("s"))
	net.advance_days(12)
	var done: Array[Dictionary] = net.stream("s").finished
	assert_eq(done.size(), 1)
	# Requested with next Monday's batch (day 7), granted 3 days later, done that morning.
	assert_between(done[0]["done_at"], SimCalendar.days(10), SimCalendar.days(10.5))


func test_parallel_wait_overlaps_the_earlier_step() -> void:
	var steps := [
		NetFixture.work("design", "team", 16.0),
		NetFixture.wait("permit", 3.0, 0.0, {"starts_with": "design"}),
		NetFixture.work("build", "team", 1.0),
	]
	var net := _one_order(steps)
	net.advance(MONDAY_8)
	net.open_order(net.stream("s"))
	net.advance_days(7)
	# Design Monday–Tuesday; the permit runs alongside and is ready Thursday 08:00.
	assert_between(net.stream("s").finished[0]["done_at"], SimCalendar.days(3) + 480, SimCalendar.days(3) + 600)


func test_rework_does_not_restart_a_parallel_wait() -> void:
	var net := _one_order([
		NetFixture.work("intake", "team", 1.0),
		NetFixture.wait("permit", 5.0, 0.0, {"starts_with": "intake"}),
		NetFixture.work("review", "team", 1.0, 0.0, {"rework_to": "intake"}),
	])
	net.advance(MONDAY_8)
	var order := net.open_order(net.stream("s"))
	var ready: int = order.early[1]
	net.advance_days(10)
	assert_true(order.reworks > 0)
	assert_eq(order.early[1], ready, "the permit was requested once")


func test_levers_switch_by_effect() -> void:
	var net := _busy_crew()
	var crew := net.pools["crew"]
	assert_eq(net.set_effects("cm:outage_reserve", [
		NetFixture.effect("crew", "reserve_for", "outages"), NetFixture.effect("crew", "reserve", 2),
	]), "")
	assert_eq([crew.reserve_for, crew.reserve], ["outages", 2])
	net.clear_effects("cm:outage_reserve")
	assert_eq([crew.reserve_for, crew.reserve], ["", 0])
	for bad: Dictionary in [
		NetFixture.effect("crew", "reserve_for", "ghost"),
		NetFixture.effect("outages", "preempts", "yes"),
		NetFixture.effect("planned.plan", "batch_days", 7),
	]:
		assert_ne(net.set_effects("bad", [bad]), "", str(bad))


func test_parallel_lever_needs_a_wait_and_an_earlier_step() -> void:
	var net := _one_order([
		NetFixture.work("design", "team", 8.0),
		NetFixture.wait("permit", 3.0),
		NetFixture.work("build", "team", 1.0),
	])
	assert_eq(net.set_effects("ok", [NetFixture.effect("s.permit", "starts_with", "design")]), "")
	assert_eq(net.stream("s").step("permit").starts_with, "design")
	assert_ne(net.set_effects("bad", [NetFixture.effect("s.permit", "starts_with", "build")]), "", "later step")
	assert_ne(net.set_effects("bad", [NetFixture.effect("s.design", "starts_with", "build")]), "", "not a wait")
	assert_eq(net.set_effects("ok", [NetFixture.effect("s.permit", "batch_days", 7)]), "")
	assert_eq(net.stream("s").step("permit").batch_minutes, SimCalendar.days(7))


func test_reserve_lowers_capacity_for_other_streams() -> void:
	var net := NetFixture.net([NetFixture.pool("crew", 2)], [
		NetFixture.stream("planned", [NetFixture.work("job", "crew", 6.0)], 5.0, 1),
		NetFixture.stream("outages", [NetFixture.work("fix", "crew", 1.0)], 10.0, 3, {"preempts": true}),
	])
	assert_near(Capacity.analyse(net)["streams"]["planned"]["capacity_per_week"], 70.0 / 6.0, 1e-6)  # (80 − 10) / 6
	net.set_effects("cm:reserve", [NetFixture.effect("crew", "reserve_for", "outages"), NetFixture.effect("crew", "reserve", 1)])
	assert_near(Capacity.analyse(net)["streams"]["planned"]["capacity_per_week"], 40.0 / 6.0, 1e-6)  # (80 − 40 held) / 6
