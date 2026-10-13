extends TestCase
## The KPI board and the quarterly review: every department follows two KPIs
## from its menu, chosen each quarter; the reward follows only the measured
## end-to-end change since the last review.

const QUESTION := "Welke KPI stuurt het werk van morgen?"
const GOOD := {"intake": ["intake_lead_time", "intake_oldest"], "prep": ["prep_lead_time", "prep_due"]}


## A small menu for the fixture network's intake and prep teams.
static func _menu() -> KpiMenu:
	var m := KpiMenu.new()
	for d: Dictionary in [
		{"id": "intake_output", "pool": "intake", "kind": "lagging", "rules": {"start": "push", "order": "shortest"}},
		{"id": "intake_lead_time", "pool": "intake", "kind": "lagging", "rules": {"start": "pull"}},
		{"id": "intake_oldest", "pool": "intake", "kind": "leading", "rules": {"order": "oldest"}},
		{"id": "prep_output", "pool": "prep", "kind": "lagging", "rules": {"start": "push"}},
		{"id": "prep_lead_time", "pool": "prep", "kind": "lagging", "rules": {"start": "pull"}},
		{"id": "prep_due", "pool": "prep", "kind": "leading", "rules": {"order": "due"}},
	]:
		d["name"] = d["id"]
		m.menus.get_or_add(d["pool"], []).append(KpiDef.from_dict(d))
	m.pull_limit_days = 2.0
	m.review_question = QUESTION
	return m


func _region() -> Region:
	var r := RulesFixture.region()
	r.use_kpis(_menu())
	return r


## A region whose board was unlocked a quarter ago: the first review is due.
func _due_region() -> Region:
	var r := _region()
	r.advance_days(30)
	r.board.unlock(r.net)
	r.advance_days(KpiBoard.REVIEW_DAYS)
	return r


func _reviews(r: Region) -> int:
	return r.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "kpi_review").size()


func test_the_review_opens_only_when_unlocked_and_due() -> void:
	var r := _region()
	assert_false(r.board.review_due(r.net.time))
	assert_eq(r.kpi_review(GOOD)["error"], "locked")
	r.advance_days(10)
	r.board.unlock(r.net)
	assert_eq(r.board.next_review_at, r.net.time + SimCalendar.days(KpiBoard.REVIEW_DAYS))
	assert_eq(r.kpi_review(GOOD)["error"], "not_due")
	r.advance_days(KpiBoard.REVIEW_DAYS - 1)
	assert_eq(_reviews(r), 0, "not yet")
	r.advance_days(1)
	assert_eq(_reviews(r), 1, "the quarter is up")
	r.advance_days(30)
	assert_eq(_reviews(r), 0, "announced once")
	assert_true(r.board.review_due(r.net.time), "it stays due until it is done: no skipping, no penalty")
	var due_at := r.board.next_review_at
	r.board.unlock(r.net)
	assert_eq(r.board.next_review_at, due_at, "unlocking again changes nothing")
	assert_eq(r.kpi_review(GOOD)["error"], "")
	assert_false(r.board.review_due(r.net.time))
	assert_eq(r.board.next_review_at, r.net.time + SimCalendar.days(KpiBoard.REVIEW_DAYS))
	r.advance_days(KpiBoard.REVIEW_DAYS)
	assert_eq(_reviews(r), 1, "next quarter")


func test_the_board_refuses_bad_choices() -> void:
	var r := _due_region()
	var board := r.board.to_dict()
	var effects := r.net.effects()
	var xp := r.profile.xp
	var prep: Array = GOOD["prep"]
	for case: Array in [
		[{"intake": ["intake_oldest"], "prep": prep}, "choose_two"],
		[{"intake": ["intake_oldest", "intake_oldest"], "prep": prep}, "choose_two"],
		[{"intake": ["intake_oldest", "intake_output", "intake_lead_time"], "prep": prep}, "choose_two"],
		[{"intake": ["intake_oldest", "prep_due"], "prep": prep}, "not_on_menu"],
		[{"intake": "intake_oldest", "prep": prep}, "choose_two"],
		[{"prep": prep}, "choose_two"],
		[{"intake": GOOD["intake"], "prep": prep, "gis": ["gis_output", "gis_oldest"]}, "unknown_department"],
	]:
		assert_eq(r.kpi_review(case[0])["error"], case[1], str(case[0]))
	assert_eq(r.board.to_dict(), board, "the board is unchanged")
	assert_eq(r.net.effects(), effects, "the work rules are unchanged")
	assert_eq(r.profile.xp, xp)
	assert_true(r.board.review_due(r.net.time))


func test_chosen_kpis_change_the_work_rules() -> void:
	var r := _due_region()
	var intake := r.net.pools["intake"]
	assert_eq(intake.pull_limit_days, 2.0, "the menu's kanban limit")
	assert_eq([intake.start_rule, intake.order_rule], ["push", "first_come"], "the habit")
	assert_eq(r.kpi_review(GOOD)["error"], "")
	assert_eq([intake.start_rule, intake.order_rule], ["pull", "oldest"])
	assert_eq(r.net.pools["prep"].order_rule, "due")
	var menu := _menu()
	assert_eq(r.net.effects()[KpiBoard.SOURCE],
		menu.effects_for("intake", PackedStringArray(GOOD["intake"])) + menu.effects_for("prep", PackedStringArray(GOOD["prep"])))
	assert_eq(r.board.chosen["intake"], PackedStringArray(GOOD["intake"]))
	# Next quarter: output against lead time is a mixed signal on start.
	r.advance_days(KpiBoard.REVIEW_DAYS)
	assert_eq(r.kpi_review({"intake": ["intake_output", "intake_lead_time"], "prep": GOOD["prep"]})["error"], "")
	assert_eq([intake.start_rule, intake.order_rule], ["push", "shortest"])


## A quarter measured against the one before it, with the same KPIs chosen;
## `bad_first` puts the bad first-time-right (in both streams: they share the
## crew) in the first quarter, else in the second.
func _quarter(bad_first: bool) -> Dictionary:
	var r := _region()
	var bad := [NetFixture.effect("connections.intake", "ftr", -0.4), NetFixture.effect("meters.visit", "ftr", -0.4)]
	if bad_first:
		r.net.set_effects("test", bad)
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.board.unlock(r.net)
	if bad_first:
		r.net.clear_effects("test")
	else:
		r.net.set_effects("test", bad)
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var xp := r.profile.xp
	var budget := r.profile.budget
	var result := r.kpi_review(GOOD)
	assert_eq(result["error"], "")
	assert_eq(r.profile.xp - xp, result["xp"], "granted")
	assert_eq(r.profile.budget - budget, result["budget"], "granted")
	return result


func test_the_reward_follows_the_measured_change() -> void:
	var worse := _quarter(false)
	assert_true(worse["after"]["connections"]["first_time_right"] < worse["before"]["connections"]["first_time_right"])
	assert_eq(worse["improvement"], 0.0, "a worse quarter earns nothing, and costs nothing")
	assert_eq([worse["xp"], worse["budget"]], [0, 0])
	var better := _quarter(true)
	assert_true(better["after"]["connections"]["first_time_right"] > better["before"]["connections"]["first_time_right"])
	assert_true(better["improvement"] > 0.0, "a better quarter earns a reward")
	assert_eq(better["xp"], roundi(better["improvement"] * KpiBoard.REVIEW_XP))
	assert_eq(better["budget"], roundi(better["improvement"] * KpiBoard.REVIEW_BUDGET))
	assert_eq(better["question"], QUESTION, "the coach asks about leading and lagging")


func test_a_quiet_stream_counts_as_no_change() -> void:
	var r := _region()
	r.board.unlock(r.net)  # day 0: nothing has finished yet
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var result := r.kpi_review(GOOD)
	assert_eq(result["error"], "")
	assert_eq(result["improvement"], 0.0)
	var busy := {"completed": 10, "lead_days_p50": 10.0, "on_time": 0.0, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var quiet := {"completed": 0, "lead_days_p50": 0.0, "on_time": 0.0, "first_time_right": 0.0,
		"throughput_per_week": 0.0, "wip_age": 0.0}
	var better := busy.duplicate()
	better["on_time"] = 0.5  # was 0: no measurable change
	better["first_time_right"] = 0.6  # +20 %
	assert_near(KpiBoard.improvement({"a": quiet, "b": busy}, {"a": busy, "b": better}), 0.2 / 5, 1e-9)
	assert_eq(KpiBoard.improvement({"a": busy}, {"a": quiet}), 0.0)
	assert_eq(KpiBoard.improvement({}, {"a": busy}), 0.0)


## A low-volume stream: on time from 5 % to 50 % is +900 %, but one KPI's
## change counts for at most MAX_CHANGE.
func test_a_huge_swing_counts_for_at_most_the_cap() -> void:
	var before := {"completed": 20, "lead_days_p50": 10.0, "on_time": 0.05, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var after := before.duplicate()
	after["on_time"] = 0.5
	assert_near(KpiBoard.improvement({"a": before}, {"a": after}), KpiBoard.MAX_CHANGE / 5, 1e-9)
	after["on_time"] = 0.0  # and down: −100 % counts as −MAX_CHANGE
	after["first_time_right"] = 1.0  # +100 %
	assert_eq(KpiBoard.improvement({"a": before}, {"a": after}), 0.0, "the capped swings cancel out")


func test_a_thin_sample_counts_as_no_change() -> void:
	var before := {"completed": KpiBoard.MIN_COMPLETED - 1, "lead_days_p50": 10.0, "on_time": 0.5,
		"first_time_right": 0.5, "throughput_per_week": 2.0, "wip_age": 5.0}
	var after := before.duplicate()
	after["completed"] = KpiBoard.MIN_COMPLETED
	after["first_time_right"] = 0.6
	assert_eq(KpiBoard.improvement({"a": before}, {"a": after}), 0.0, "too few finished before")
	assert_eq(KpiBoard.improvement({"a": after}, {"a": before}), 0.0, "too few finished after")
	var enough := before.duplicate()
	enough["completed"] = KpiBoard.MIN_COMPLETED
	assert_true(KpiBoard.improvement({"a": enough}, {"a": after}) > 0.0, "the minimum sample counts")


func test_a_passed_check_unlocks_the_board() -> void:
	var cms := RulesFixture.countermeasures()
	cms[0]["unlocks"] = "kpi_board"  # standard_designs
	var defs: Array[CountermeasureDef] = []
	for d: Dictionary in cms:
		defs.append(CountermeasureDef.from_dict(d))
	var profile := Profile.new()
	profile.budget = 50000
	var r := Region.new(RulesFixture.net(), RulesFixture.problem_defs(), defs, profile)
	r.use_kpis(_menu())
	r.activate("custom_design")
	r.use_tool("connections.design", "time_study")
	r.use_tool("connections.design", "documents")
	r.ask("connections.intake", "walk")
	r.use_tool("connections.design", "data")
	assert_eq(r.submit_a3("custom_design", RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs",
		["custom_design:0", "custom_design:2", "custom_design:4"], "throughput")), "")
	r.advance_days(Region.CHECK_DAYS)
	assert_false(r.board.unlocked, "not before the Check")
	assert_true(r.check("custom_design")["passed"])
	assert_true(r.board.unlocked)
	assert_eq(r.board.next_review_at, r.net.time + SimCalendar.days(KpiBoard.REVIEW_DAYS))


func test_the_board_survives_save_and_load() -> void:
	var original := _due_region()
	assert_eq(original.kpi_review(GOOD)["error"], "")
	original.advance_days(30)  # mid-quarter
	original.drain_events()
	var saved: Dictionary = bytes_to_var(var_to_bytes(RegionState.capture(original)))
	var restored := RulesFixture.region(0, 123)
	restored.use_kpis(_menu())
	assert_eq(RegionState.restore(restored, saved)["error"], "")
	assert_eq(restored.board.to_dict(), original.board.to_dict())
	assert_eq(restored.net.pools["intake"].start_rule, "pull", "the chosen work rules are back")
	for r: Region in [original, restored]:
		r.advance_days(KpiBoard.REVIEW_DAYS)
	assert_eq(restored.drain_events(), original.drain_events())
	assert_eq(restored.kpi_review(GOOD), original.kpi_review(GOOD), "the same quarter, measured the same")


func test_old_or_damaged_board_saves_load_safely() -> void:
	var saved := RegionState.capture(_due_region())
	saved.erase("kpi_board")  # a save from before the board
	var r := _region()
	assert_eq(RegionState.restore(r, saved)["error"], "")
	assert_false(r.board.unlocked)
	saved["kpi_board"] = "garbage"
	r = _region()
	assert_eq(RegionState.restore(r, saved)["error"], "")
	assert_false(r.board.unlocked)
	saved["kpi_board"] = {
		"unlocked": true, "next_review_at": "soon",
		"chosen": {"nobody": ["x"], "intake": ["intake_oldest", "prep_due", 7], "prep": "prep_due"},
		"snapshot": {"connections": {"completed": "many", "on_time": 0.5}, "ghost": 3},
	}
	r = _region()
	assert_eq(RegionState.restore(r, saved)["error"], "")
	assert_true(r.board.unlocked)
	assert_eq(r.board.next_review_at, 0)
	assert_eq(r.board.chosen, {"intake": PackedStringArray(["intake_oldest"])} as Dictionary[String, PackedStringArray])
	var result := r.kpi_review(GOOD)
	assert_eq(result["error"], "", "a damaged board still reviews")
	assert_eq(result["improvement"], 0.0, "nothing usable to compare with")
