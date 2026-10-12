extends TestCase
## The real connections value stream from content/value_streams.yaml.
## Fixed seed, so these are exact regression checks on the tuned starting state.

const SEED := 11


func _net() -> Network:
	return Network.load_file(Network.DEFAULT_PATH, SEED)


func test_content_loads() -> void:
	var net := _net()
	assert_eq(net.error, "")
	assert_ne(net.stream("connections"), null)


func test_design_is_the_starting_constraint_at_about_full_load() -> void:
	var r := Capacity.analyse(_net())
	var c: Dictionary = r["streams"]["connections"]
	assert_eq(c["constraint_pool"], "work_prep")
	assert_eq(c["constraint_step"], "design")
	assert_between(c["utilisation"], 0.95, 1.15)
	assert_between(r["pools"]["gis"]["utilisation"], 0.85, 1.0, "Revisie & GIS is close behind")


func test_queue_builds_at_the_constraint() -> void:
	var net := _net()
	net.advance_days(120)
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
	var net := _net()
	net.advance_days(120)
	var k := net.stream("connections").kpis(net.time, 28)
	assert_between(k["throughput_per_week"], 20.0, 32.0, "demand is 30 a week")
	assert_between(k["lead_days_p50"], 15.0, 80.0)
	assert_true(k["backlog"] > 100, "backlog %d" % k["backlog"])
	assert_between(k["first_time_right"], 0.3, 0.7)


func test_starting_stock_does_not_run_out() -> void:
	var net := _net()
	net.advance_days(120)
	var stockouts := net.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "stockout")
	assert_eq(stockouts.size(), 0, "stock-outs are a problem to discover later, not the starting state")
