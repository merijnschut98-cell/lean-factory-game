extends TestCase
## The real value streams from content/value_streams.yaml.
## Fixed seed, so these are exact regression checks on the tuned starting state.

const SEED := 11

## One 120-day run shared by the tests that only read its outcome.
static var _after_120_days: Network


func _net() -> Network:
	return Network.load_file(Network.DEFAULT_PATH, SEED)


func _run_120_days() -> Network:
	if _after_120_days == null:
		_after_120_days = _net()
		_after_120_days.advance_days(120)
	return _after_120_days


func test_content_loads() -> void:
	var net := _net()
	assert_eq(net.error, "")
	for id in ["connections", "outages", "meters", "congestion"]:
		assert_ne(net.stream(id), null, id)


func test_design_is_the_starting_constraint_at_about_full_load() -> void:
	var r := Capacity.analyse(_net())
	var c: Dictionary = r["streams"]["connections"]
	assert_eq(c["constraint_pool"], "work_prep")
	assert_eq(c["constraint_step"], "design")
	assert_between(c["utilisation"], 0.95, 1.15)
	assert_between(r["pools"]["gis"]["utilisation"], 0.85, 1.0, "Revisie & GIS is close behind")
	assert_between(r["pools"]["monteurs"]["utilisation"], 0.6, 0.8, "the obvious suspect is not the constraint")


func test_standard_designs_move_the_constraint_to_gis() -> void:
	var net := _net()
	assert_eq(net.set_effects("cm:standard_designs", [NetFixture.effect("connections.design", "touch_time", 0.7)]), "")
	var c: Dictionary = Capacity.analyse(net)["streams"]["connections"]
	assert_eq(c["constraint_pool"], "gis", "fix the constraint and the next one shows")
	assert_between(c["capacity_per_week"], 30.0, 34.0, "only a little more output: Revisie & GIS is close behind")


func test_queue_builds_at_the_constraint() -> void:
	var net := _run_120_days()
	var s := net.stream("connections")
	var design_queue := 0
	var other_max := 0
	for step in s.steps:
		if step.kind != SimStep.Kind.WORK:
			continue
		if step.id == "design":
			design_queue = net.queue_of(step).size()
		else:
			other_max = maxi(other_max, net.queue_of(step).size())
	assert_true(design_queue > other_max, "design queue %d vs next %d" % [design_queue, other_max])


func test_kpis_are_in_a_realistic_range() -> void:
	var net := _run_120_days()
	var k := net.stream("connections").kpis(net.time, 28)
	assert_between(k["throughput_per_week"], 20.0, 32.0, "demand is 30 a week")
	assert_between(k["lead_days_p50"], 15.0, 80.0)
	assert_true(k["backlog"] > 100, "backlog %d" % k["backlog"])
	assert_between(k["first_time_right"], 0.3, 0.7)


func test_outages_are_restored_within_hours_by_day_and_night() -> void:
	var net := _run_120_days()
	var k := net.stream("outages").kpis(net.time, 28)
	assert_true(k["completed"] > 40, "completed %d" % k["completed"])
	assert_true(k["lead_days_p85"] < 0.25, "p85 %.2f days" % k["lead_days_p85"])
	assert_true(k["on_time"] > 0.8, "within the 4-hour norm: %.2f" % k["on_time"])


func test_outages_interrupt_planned_monteur_work() -> void:
	var net := _run_120_days()
	assert_true(NetFixture.events(net, "preempted").size() > 0)


func test_meters_and_congestion_flow() -> void:
	var net := _run_120_days()
	var meters := net.stream("meters").kpis(net.time, 28)
	var congestion := net.stream("congestion").kpis(net.time, 28)
	assert_between(meters["throughput_per_week"], 30.0, 50.0, "demand is 40 a week")
	assert_between(meters["first_time_right"], 0.6, 0.9, "niet thuis")
	assert_true(congestion["completed"] > 0)
	assert_true(congestion["lead_days_p50"] > meters["lead_days_p50"], "the capacity queue is long")


func test_starting_stock_does_not_run_out() -> void:
	var net := _run_120_days()
	var stockouts := NetFixture.events(net, "stockout")
	assert_eq(stockouts.size(), 0, "stock-outs are a problem to discover later, not the starting state")
	for item: SimStock in net.stock.values():
		assert_true(item.level > 0, item.id)


func test_skipping_idle_time_changes_nothing() -> void:
	var fast := _net()
	var slow := _net()
	slow.skip_idle = false
	fast.advance_days(30)
	slow.advance_days(30)
	for s in fast.streams:
		assert_eq(s.finished, slow.stream(s.id).finished, s.id)
	assert_eq(fast.events, slow.events)
