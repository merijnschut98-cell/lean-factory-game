extends TestCase
## Fewer outages a week is better (gate backlog 7): a stream whose orders are faults or
## complaints (content `throughput_direction: lower_is_better`) counts a drop in its
## throughput as a gain wherever that throughput is judged: the Check, the KPI review,
## the repairs, the Check table and the terugblik. The connection stream stays as it is.


## A RulesFixture region whose connections stream counts fewer a week as better
## (`lower`), with a problem at `place` that raises the demand a fix brings down.
func _region(lower: bool) -> Region:
	var place := "connections.intake"
	var problems := RulesFixture.problems()
	problems[0].merge({"step": place, "kpi": "throughput", "effects": [NetFixture.effect("connections", "demand", 1.5)],
		"clues": [RulesFixture.clue("data", true, 0)]}, true)
	var cms := RulesFixture.countermeasures()
	cms[0]["effects"] = [NetFixture.effect("connections", "demand", 0.6)]
	var r := RulesFixture.region(50000, 5, problems, cms)
	r.net.stream("connections").throughput_direction = -1 if lower else 1
	r.activate("custom_design")
	r.use_tool(place, "data")
	return r


func _check(r: Region) -> Dictionary:
	var a3 := RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs", ["custom_design:0"], "throughput")
	assert_eq(r.submit_a3("custom_design", a3), "")
	r.advance_days(Region.CHECK_DAYS)
	return r.check("custom_design")


func test_the_real_outage_streams_count_fewer_as_better() -> void:
	var net := Network.load_file(Network.DEFAULT_PATH, 1)
	assert_eq(net.error, "")
	for id: String in ["outages", "voltage_complaints", "customer_contact"]:
		assert_eq(net.stream(id).throughput_direction, -1, id)
	assert_eq(net.stream("outages").throughput_phrase, "storingen per week")
	for id: String in ["connections", "meters", "congestion"]:
		assert_eq(net.stream(id).throughput_direction, 1, id)
		assert_eq(net.stream(id).throughput_phrase, "", id)


func test_only_the_throughput_follows_its_stream() -> void:
	assert_eq(Pdca.direction("throughput"), 1)
	assert_eq(Pdca.direction("throughput", -1), -1)
	assert_eq(Pdca.direction("throughput_per_week", -1), -1, "the streams' own name for it")
	for kpi: String in ["lead_time", "wip_age", "lead_days_p50"]:
		assert_eq(Pdca.direction(kpi, -1), -1, kpi)
	for kpi: String in ["capacity", "on_time", "first_time_right"]:
		assert_eq(Pdca.direction(kpi, -1), 1, kpi)
	assert_near(Pdca.kpi_gain("throughput", {"throughput": 20.0}, {"throughput": 15.0}, -1), 0.25, 1e-9)
	assert_near(Pdca.kpi_gain("throughput", {"throughput": 20.0}, {"throughput": 15.0}), -0.25, 1e-9)
	assert_near(Pdca.kpi_gain("capacity", {"capacity": 20.0}, {"capacity": 15.0}, -1), -0.25, 1e-9)


## The Check: a fix that brings the faults down passes on a throughput prediction.
func test_a_fix_that_lowers_outages_passes_the_check() -> void:
	var check := _check(_region(true))
	assert_true(check["forecast"]["gains"]["throughput"] > Pdca.CHECK_NOISE, str(check["forecast"]["gains"]))
	assert_true(check["passed"], str(check["forecast"]))


func test_the_connection_stream_stays_as_it_is() -> void:
	var check := _check(_region(false))
	assert_true(check["forecast"]["gains"]["throughput"] < -Pdca.CHECK_NOISE, str(check["forecast"]["gains"]))
	assert_false(check["passed"])


## The KPI review: fewer outages a week is an improvement on that stream.
func test_the_kpi_review_counts_fewer_outages_as_better() -> void:
	var net := RulesFixture.net()
	var before := {"completed": 20, "lead_days_p50": 1.0, "on_time": 0.5, "first_time_right": 0.5,
		"throughput_per_week": 20.0, "wip_age": 1.0}
	var after := before.duplicate()
	after["throughput_per_week"] = 16.0  # −20 %
	var ids := PackedStringArray(["connections"])
	assert_near(KpiBoard.improvement({"connections": before}, {"connections": after}, ids, net), -0.2 / 5, 1e-9)
	net.stream("connections").throughput_direction = -1
	assert_near(KpiBoard.improvement({"connections": before}, {"connections": after}, ids, net), 0.2 / 5, 1e-9)


## Repairs: today's fix leaves more outages than the best one would, so it is behind.
func test_a_repair_sees_more_outages_as_behind() -> void:
	assert_near(Repairs.behind("throughput", 20.0, 15.0, -1), 5.0 / 15.0, 1e-9)
	assert_near(Repairs.behind("throughput", 20.0, 15.0, 1), -5.0 / 15.0, 1e-9)
	assert_near(Repairs.behind("lead_time", 20.0, 15.0, 1), 5.0 / 15.0, 1e-9)


## The Check table: a drop in outages is green, and the row says what it counts.
func test_the_check_table_shows_fewer_outages_as_better() -> void:
	assert_true(CheckPanel.improved("throughput", 20.0, 15.0, -1))
	assert_false(CheckPanel.improved("throughput", 20.0, 15.0))
	assert_eq(CheckPanel.change_color("throughput", 20.0, 15.0, -1), Palette.GREEN_DARK)
	var net := Network.load_file(Network.DEFAULT_PATH, 1)
	assert_eq(UiText.kpi("throughput", net.stream("outages")), "Storingen per week (minder is beter)")
	assert_eq(UiText.kpi("throughput", net.stream("connections")), UiText.kpi("throughput"))
	assert_eq(UiText.kpi("lead_time", net.stream("outages")), UiText.kpi("lead_time"))


## The terugblik: a drop in outages since the last session is the better news.
func test_the_terugblik_reads_fewer_outages_as_better() -> void:
	var net := RulesFixture.net()
	net.stream("connections").throughput_direction = -1
	var then := {"connections": {"completed": 20.0, "lead_days_p50": 1.0, "on_time": 0.5, "first_time_right": 0.5,
		"throughput_per_week": 20.0}}
	var now := {"connections": then["connections"].duplicate()}
	now["connections"]["throughput_per_week"] = 14.0
	var moved := SessionLayer._most_moved(then, now, ["connections"], net)
	assert_eq(moved["measure"], "throughput_per_week")
	assert_true(moved["better"])
