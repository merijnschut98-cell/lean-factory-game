extends TestCase
## The real value streams from content/value_streams.yaml: a healthy base,
## and the starting state (the base with the custom_design problem switched
## on, which makes Werkvoorbereiding the constraint).
## Fixed seed, so these are exact regression checks on the tuned content.

const SEED := 11

## One 120-day run shared by the tests that only read its outcome.
static var _after_120_days: Network


func _net() -> Network:
	return Network.load_file(Network.DEFAULT_PATH, SEED)


## The base with the custom_design problem active (as at the start of the game).
func _starting_state() -> Network:
	return RulesFixture.real_network(["custom_design"], SEED)


func _run_120_days() -> Network:
	if _after_120_days == null:
		_after_120_days = _net()
		_after_120_days.advance_days(120)
	return _after_120_days


## Common random numbers: each stream, team and step draws from its own random
## sequence, so a change in one place leaves the others' randomness alone and
## two runs differ only where the change reaches.
func test_a_change_leaves_unrelated_streams_identical() -> void:
	var base := _net()
	var changed := _net()
	# The contact centre serves only its own stream, and nothing flows on from it.
	changed.set_effects("problem:slow_answers", [NetFixture.effect("customer_contact.answer", "touch_time", 1.5)])
	base.advance_days(60)
	changed.advance_days(60)
	assert_ne(changed.stream("customer_contact").finished, base.stream("customer_contact").finished, "the change reaches contact")
	for id: String in ["connections", "outages", "meters", "congestion", "voltage_complaints"]:
		assert_eq(changed.stream(id).finished, base.stream(id).finished, id + " is untouched")


func test_content_loads() -> void:
	var net := _net()
	assert_eq(net.error, "")
	for id in ["connections", "outages", "meters", "congestion", "voltage_complaints"]:
		assert_ne(net.stream(id), null, id)


func test_the_base_is_healthy() -> void:
	var r := Capacity.analyse(_net())
	for pool: String in r["pools"]:
		assert_true(r["pools"][pool]["utilisation"] < 0.9, "%s at %.0f%%" % [pool, 100 * r["pools"][pool]["utilisation"]])
	assert_between(r["pools"]["monteurs"]["utilisation"], 0.6, 0.8, "the obvious suspect is not the constraint")


func test_design_is_the_starting_constraint() -> void:
	var r := Capacity.analyse(_starting_state())
	var c: Dictionary = r["streams"]["connections"]
	assert_eq(c["constraint_pool"], "work_prep")
	assert_eq(c["constraint_step"], "design")
	assert_between(c["utilisation"], 1.0, 1.2, "overloaded: the queue grows")


func test_fixing_the_constraint_shows_the_next_one() -> void:
	var net := _starting_state()
	var before: float = Capacity.analyse(net)["streams"]["connections"]["capacity_per_week"]
	net.clear_effects("problem:custom_design")
	var c: Dictionary = Capacity.analyse(net)["streams"]["connections"]
	assert_eq(c["constraint_pool"], "intake", "fix the constraint and the next one shows")
	assert_between(c["capacity_per_week"] / before, 1.15, 1.4, "more output, until intake sets the pace")


func test_queue_builds_at_the_constraint() -> void:
	var net := _starting_state()
	net.advance_days(60)  # the design queue is clearly the longest by then
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
	# Realistic external waits run to months (permits, grid reinforcement), so
	# connections only settle after half a year; measured over seeds 11–15.
	var net := _net()
	net.advance_days(240)
	var k := net.stream("connections").kpis(net.time, 56)
	assert_between(k["throughput_per_week"], 24.0, 36.0, "demand is 30 a week")
	assert_between(k["lead_days_p50"], 30.0, 70.0, "the customer's approval, permits and reinforcement take months")
	assert_between(k["backlog"], 150, 350, "about seven weeks of work in progress (Little's law)")
	assert_between(k["first_time_right"], 0.3, 0.7)
	# The 18-week norm is met most of the time, not always (streets that need
	# grid reinforcement run late), so problems show in on-time.
	assert_between(k["on_time"], 0.8, 0.97)


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


## Solve one made-up problem at `step` on the real network; returns the score.
func _solve_at(step: String) -> Dictionary:
	var problem := ProblemDef.from_dict({
		"id": "slow", "tier": 1, "name": "Traag", "step": step, "waste": "overprocessing", "severity": "medium",
		"visibility": "obvious", "kpi": "throughput", "root_cause": "Too many approvals",
		"countermeasures": {"fix": 1.0},
		"effects": [NetFixture.effect(step, "touch_time", 1.2)],
		"clues": [RulesFixture.clue("time_study", true, 0)],
	})
	var fix := CountermeasureDef.from_dict({
		"id": "fix", "name": "Fix", "tier": 1, "budget": 1000, "decay_days": null,
		"multipliers": {"full": 0.9, "reduced": 0.5, "minimal": 0.25},
		"effects": [NetFixture.effect(step, "touch_time", 0.7)],
	})
	var defs: Array[ProblemDef] = [problem]
	var cms: Array[CountermeasureDef] = [fix]
	var r := Region.new(_net(), defs, cms, Profile.new())
	r.activate("slow")
	r.use_tool(step, "time_study")
	r.submit_a3("slow", {"waste": "overprocessing", "cause": Investigation.cause_options(problem, defs)["correct"],
		"evidence": ["slow:0"], "cm": "fix", "prediction": "throughput"})
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("slow")["passed"])
	return r.act("slow", true)


func test_only_improving_the_constraint_scores_on_flow() -> void:
	var planning := _solve_at("connections.planning")
	assert_true(planning["impact"] <= 2, "planning is at ~40%%: impact %d" % planning["impact"])
	assert_true("impact_not_constraint" in planning["notes"])
	var design := _solve_at("connections.design")
	assert_true(design["impact"] >= 4, "design is the constraint: impact %d" % design["impact"])
