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


## The largest value `measure` takes while stepping the network tick by tick.
func _max_over(net: Network, days: int, measure: Callable) -> int:
	var most := 0
	for i in SimCalendar.days(days) / SimCalendar.TICK:
		net.advance(SimCalendar.TICK)
		most = maxi(most, measure.call())
	return most


func _max_planned_busy(net: Network, days: int) -> int:
	return _max_over(net, days, func() -> int:
		return net.pools["crew"].busy.filter(func(o: WorkOrder) -> bool: return o.stream.id == "planned").size())


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
	assert_eq(planned.step("plan").stats_since(0)["entered"] - (planned.finished.size() + planned.active), interrupted,
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
	var reserve := {"stream": "outages", "people": 2}
	assert_eq(net.set_effects("cm:outage_reserve", [NetFixture.effect("crew", "reserve", reserve)]), "")
	assert_eq(crew.reserve, reserve)
	net.clear_effects("cm:outage_reserve")
	assert_eq(crew.reserve, {})
	for bad: Dictionary in [
		NetFixture.effect("crew", "reserve", {"stream": "ghost", "people": 1}),
		NetFixture.effect("crew", "reserve", {"stream": "outages", "people": 4}),
		NetFixture.effect("crew", "reserve", 2),
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
	net.set_effects("cm:reserve", [NetFixture.effect("crew", "reserve", {"stream": "outages", "people": 1})])
	assert_near(Capacity.analyse(net)["streams"]["planned"]["capacity_per_week"], 40.0 / 6.0, 1e-6)  # (80 − 40 held) / 6


## One overloaded team: 80 hours of second-step work a week for 40 hours of
## people. Dossiers waiting longer than 5 days (a weekend fits within that)
## at `second` go stale and go back to `first`.
func _overloaded(extra: Dictionary = {}) -> Network:
	return NetFixture.net([NetFixture.pool("team", 1)], [NetFixture.stream("s", [
		NetFixture.work("first", "team", 0.5),
		NetFixture.work("second", "team", 8.0, 1.0, {"stale_after_days": 5, "stale_to": "first", "stale_wait_days": 1}),
	], 10.0, 1, extra)])


func test_dossiers_that_wait_too_long_go_stale() -> void:
	var net := _overloaded()
	net.advance_days(42)
	var stale := NetFixture.events(net, "stale")
	assert_true(stale.size() > 0, "long waits make the dossier stale")
	var first := net.stream("s").step("first").stats_since(0)
	assert_eq(first["entered"] - (net.stream("s").active + net.stream("s").finished.size()), stale.size(),
		"every stale dossier went back to the first step once more")


func _max_started(net: Network, days: int) -> int:
	return _max_over(net, days, func() -> int: return net.stream("s").active - net.held("s"))


func test_a_wip_limit_holds_new_orders_before_they_start() -> void:
	var limited := _overloaded({"wip_limit": 3})
	assert_true(_max_started(limited, 42) <= 3)
	assert_true(limited.held("s") > 0, "the rest wait, not yet started")
	assert_eq(NetFixture.events(limited, "stale").size(), 0, "nothing started waits long enough to go stale")


func test_limiting_wip_finishes_more_when_waiting_costs_rework() -> void:
	var pushed := _overloaded()
	var limited := _overloaded({"wip_limit": 3})
	pushed.advance_days(56)
	limited.advance_days(56)
	assert_true(limited.stream("s").finished.size() > pushed.stream("s").finished.size(),
		"%d vs %d" % [limited.stream("s").finished.size(), pushed.stream("s").finished.size()])


func test_wip_limit_is_a_lever() -> void:
	var net := _overloaded()
	assert_eq(net.set_effects("cm:conwip", [NetFixture.effect("s", "wip_limit", 3)]), "")
	net.advance_days(14)
	assert_true(net.held("s") > 0)
	net.clear_effects("cm:conwip")
	assert_eq(net.held("s"), 0, "lifting the limit releases every held order at once")
	assert_ne(net.set_effects("bad", [NetFixture.effect("s", "wip_limit", -1)]), "")
	assert_ne(net.set_effects("bad", [NetFixture.effect("s", "wip_limit", 2.5)]), "")


## Connections that wait too long make customers call the contact centre.
## 10 orders a week at `design_hours` each: at 7 hours one person is
## overloaded (70 of 40 hours) and orders get late.
func _with_status_calls(call_rate: float, design_hours: float) -> Network:
	return NetFixture.net([NetFixture.pool("prep", 1), NetFixture.pool("agents", 1)], [
		NetFixture.stream("connections", [NetFixture.work("design", "prep", design_hours)], 10.0, 2,
			{"status_calls": {"to": "contact", "after_days": 7, "per_week": call_rate}}),
		# Loaded about half, so extra calls show as waiting.
		NetFixture.stream("contact", [NetFixture.work("answer", "agents", 1.0)], 20.0, 1),
	])


func _failure_calls(net: Network) -> int:
	return NetFixture.events(net, "arrived").filter(func(e: Dictionary) -> bool: return e.get("failure_demand", false)).size()


func test_late_orders_cause_status_calls() -> void:
	var fast := _with_status_calls(1.0, 1.0)
	var slow := _with_status_calls(1.0, 7.0)
	fast.advance_days(42)
	slow.advance_days(42)
	assert_eq(_failure_calls(fast), 0, "nobody calls about an order that is on its way")
	# 16–45 calls over seeds 1–10: a late order calls about once a week.
	assert_true(_failure_calls(slow) > 10, "late orders call: %d" % _failure_calls(slow))


func test_failure_demand_loads_the_contact_centre() -> void:
	var quiet := _with_status_calls(0.0, 7.0)
	var calling := _with_status_calls(3.0, 7.0)
	quiet.advance_days(42)
	calling.advance_days(42)
	var answer_quiet := quiet.stream("contact").step("answer").stats_since(0)
	var answer_calling := calling.stream("contact").step("answer").stats_since(0)
	assert_true(answer_calling["entered"] > answer_quiet["entered"] * 1.25, "×1.34–2.4 over seeds 1–10")
	assert_true(answer_calling["queue_hours"] > answer_quiet["queue_hours"], "real questions wait longer")
	var calls: Array = calling.stream("contact").finished.filter(func(f: Dictionary) -> bool: return f["failure_demand"])
	assert_true(calls.size() > 0, "answered calls remember they were failure demand")


func test_status_call_rate_is_a_lever() -> void:
	var net := _with_status_calls(1.0, 7.0)
	assert_eq(net.set_effects("cm:status_updates", [NetFixture.effect("connections", "call_rate", 0.2)]), "")
	assert_near(net.stream("connections").call_rate, 0.2, 1e-9)


## One person serving `streams`, each a single work step on the shared pool.
func _shared_person(streams: Array, rule: String) -> Network:
	var net := NetFixture.net([NetFixture.pool("team", 1)], streams)
	assert_eq(net.set_effects("cm:rule", [NetFixture.effect("team", "order_rule", rule)]), "")
	return net


func _done(net: Network, stream_id: String) -> int:
	return net.stream(stream_id).finished.size()


func test_shortest_first_picks_the_quickest_job() -> void:
	var streams := func() -> Array:
		return [
			NetFixture.stream("long", [NetFixture.work("job", "team", 4.0)], 20.0, 1),
			NetFixture.stream("short", [NetFixture.work("job", "team", 0.5)], 20.0, 1),
		]
	var fifo: Network = _shared_person(streams.call(), "first_come")
	var quickest: Network = _shared_person(streams.call(), "shortest")
	fifo.advance_days(7)
	quickest.advance_days(7)
	assert_true(_done(fifo, "short") <= _done(fifo, "long") + 1, "first come: %d short, %d long" % [_done(fifo, "short"), _done(fifo, "long")])
	assert_true(_done(quickest, "short") > _done(quickest, "long"), "shortest first: %d short, %d long" % [_done(quickest, "short"), _done(quickest, "long")])


## Reworked orders re-enter the back of their queue but were born earlier.
func _rework_and_fresh(rule: String) -> Network:
	var net := NetFixture.net([NetFixture.pool("team", 1)], [
		NetFixture.stream("reworked", [NetFixture.work("check", "team", 1.0, 0.5)], 5.0, 1),
		NetFixture.stream("fresh", [NetFixture.work("job", "team", 1.0)], 25.0, 1),
	])
	assert_eq(net.set_effects("cm:rule", [NetFixture.effect("team", "order_rule", rule)]), "")
	return net


func test_oldest_first_picks_the_earliest_born() -> void:
	var fifo := _rework_and_fresh("first_come")
	var oldest := _rework_and_fresh("oldest")
	fifo.advance_days(56)
	oldest.advance_days(56)
	var fifo_lead: float = fifo.stream("reworked").kpis(fifo.time, 56)["lead_days_p85"]
	var oldest_lead: float = oldest.stream("reworked").kpis(oldest.time, 56)["lead_days_p85"]
	assert_true(oldest_lead < fifo_lead, "the reworked order, born earlier, goes first: %.2f vs %.2f days" % [oldest_lead, fifo_lead])


func test_due_first_picks_the_earliest_due_date() -> void:
	var streams := func() -> Array:
		return [
			NetFixture.stream("urgent", [NetFixture.work("job", "team", 2.0)], 10.0, 1, {"norm_days": 2.0}),
			NetFixture.stream("relaxed", [NetFixture.work("job", "team", 2.0)], 10.0, 1, {"norm_days": 30.0}),
		]
	var fifo: Network = _shared_person(streams.call(), "first_come")
	var due: Network = _shared_person(streams.call(), "due")
	fifo.advance_days(56)
	due.advance_days(56)
	var fifo_on_time: float = fifo.stream("urgent").kpis(fifo.time, 56)["on_time"]
	var due_on_time: float = due.stream("urgent").kpis(due.time, 56)["on_time"]
	assert_true(due_on_time > fifo_on_time, "on time %.2f vs %.2f" % [due_on_time, fifo_on_time])


## `fast` feeds a slower `slow` team.
func _fast_into_slow(start_rule: String) -> Network:
	var net := NetFixture.net([NetFixture.pool("fast", 1), NetFixture.pool("slow", 1)], [
		NetFixture.stream("s", [
			NetFixture.work("a", "fast", 0.5),
			NetFixture.work("b", "slow", 4.0),
		], 20.0, 1),
	])
	assert_eq(net.set_effects("cm:rule", [NetFixture.effect("fast", "start_rule", start_rule)]), "")
	return net


func test_pull_waits_for_room_downstream() -> void:
	var pushed := _fast_into_slow("push")
	var pulled := _fast_into_slow("pull")
	pushed.advance_days(10)
	pulled.advance_days(10)
	var b_step := pulled.stream("s").step("b")
	var limit: float = pulled.pools["fast"].pull_limit_days
	assert_true(pulled.queue_days(b_step) <= limit + 0.5, "pull: %.2f days queued" % pulled.queue_days(b_step))
	assert_true(pushed.queue_days(pushed.stream("s").step("b")) > limit + 0.5, "push: %.2f days queued" % pushed.queue_days(pushed.stream("s").step("b")))


func test_queue_days_is_queued_work_over_the_first_pool_per_day() -> void:
	var net := _fast_into_slow("push")
	var b_step := net.stream("s").step("b")
	assert_eq(net.queue_days(b_step), 0.0)
	for i in 3:
		net.open_order(net.stream("s"))
	net.advance(SimCalendar.days(1) + 600)  # Tuesday 10:00: all three passed `a`, one is in progress at `b`
	assert_true(net.queue_of(b_step).size() >= 1)
	var minutes := 0
	for o in net.queue_of(b_step):
		minutes += o.remaining
	assert_near(net.queue_days(b_step), minutes / (8.0 * 60.0), 1e-9, "one monteur, 8 hours a working day")


func test_pull_never_blocks_a_last_step() -> void:
	var net := NetFixture.net([NetFixture.pool("team", 1)], [
		NetFixture.stream("s", [NetFixture.work("only", "team", 1.0)], 10.0, 1),
	])
	assert_eq(net.set_effects("cm:rule", [NetFixture.effect("team", "start_rule", "pull")]), "")
	net.advance_days(14)
	assert_true(_done(net, "s") > 5, "%d done" % _done(net, "s"))


func test_rule_values_are_checked() -> void:
	var net := _fast_into_slow("push")
	assert_ne(net.set_effects("bad", [NetFixture.effect("fast", "order_rule", "random")]), "")
	assert_ne(net.set_effects("bad", [NetFixture.effect("fast", "start_rule", "first_come")]), "")
	assert_ne(net.set_effects("bad", [NetFixture.effect("fast", "order_rule", 1)]), "")
	assert_eq(net.pools["fast"].order_rule, "first_come", "nothing changed")
	assert_eq(net.pools["fast"].start_rule, "push")
	assert_eq(net.set_effects("ok", [NetFixture.effect("fast", "order_rule", "due")]), "")
	assert_eq(net.pools["fast"].order_rule, "due")
	net.clear_effects("ok")
	assert_eq(net.pools["fast"].order_rule, "first_come", "lifting the rule restores the habit")
