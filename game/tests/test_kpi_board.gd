extends TestCase
## The KPI board and the quarterly review: every department follows two KPIs
## from its menu, chosen each quarter. The reward is a forecast: the coming
## quarter run twice from the review, with the habit and with the chosen
## KPIs (common random numbers, so only the work rules differ), and only the
## measured gain in the streams the departments on the menu work in pays.

const QUESTION := "Welke KPI stuurt het werk van morgen?"
## One stream, "a", that a department on the menu works in.
const A: PackedStringArray = ["a"]
const GOOD := {"intake": ["intake_lead_time", "intake_oldest"], "prep": ["prep_lead_time", "prep_due"]}
## Every rule the same as the habit: push, first come first served, normal care.
const HABIT := {"intake": ["intake_volume", "intake_queue"], "prep": ["prep_output", "prep_queue"]}
const CAREFUL := {"intake": ["intake_volume", "intake_careful"], "prep": ["prep_output", "prep_queue"]}
const HASTY := {"intake": ["intake_volume", "intake_hasty"], "prep": ["prep_output", "prep_queue"]}


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
		# The habit's own rules, and care, which the tests below make strong.
		{"id": "intake_volume", "pool": "intake", "kind": "lagging", "rules": {"start": "push"}},
		{"id": "intake_queue", "pool": "intake", "kind": "leading", "rules": {"order": "first_come"}},
		{"id": "intake_careful", "pool": "intake", "kind": "leading", "rules": {"care": "careful"}},
		{"id": "intake_hasty", "pool": "intake", "kind": "leading", "rules": {"care": "hasty"}},
		{"id": "prep_queue", "pool": "prep", "kind": "leading", "rules": {"order": "first_come"}},
	]:
		d["name"] = d["id"]
		m.menus.get_or_add(d["pool"], []).append(KpiDef.from_dict(d))
	m.pull_limit_days = 2.0
	m.review_question = QUESTION
	# Strong care, so its effect is unmistakable: the same time, far fewer or far more mistakes.
	m.care = {"careful": {"touch_time": 1.0, "ftr": 0.3}, "hasty": {"touch_time": 1.0, "ftr": -0.3}}
	m.pool_steps["intake"] = PackedStringArray(["connections.intake"])
	m.pool_steps["prep"] = PackedStringArray(["connections.design"])
	return m


func _region() -> Region:
	var r := RulesFixture.region()
	r.use_kpis(_menu())
	return r


## A region whose board was just unlocked: the first review is due.
func _due_region() -> Region:
	var r := _region()
	r.advance_days(30)
	r.board.unlock(r.net.time)
	return r


func _reviews(r: Region) -> int:
	return r.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "kpi_review").size()


func test_the_review_opens_only_when_unlocked_and_due() -> void:
	var r := _region()
	assert_false(r.board.review_due(r.net.time))
	assert_eq(r.kpi_review(GOOD)["error"], "locked")
	r.advance_days(10)
	r.board.unlock(r.net.time)
	assert_true(r.board.review_due(r.net.time), "the first review is due at once")
	assert_eq(r.kpi_review(GOOD)["error"], "")
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
	r.board.unlock(r.net.time)
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


func test_a_board_without_a_menu_grants_nothing() -> void:
	var r := RulesFixture.region()  # never given use_kpis
	assert_false(r.board.unlock(r.net.time), "a board without menus stays shut")
	assert_eq(r.kpi_review({})["error"], "locked")


## A choice whose rules are the habit's changes nothing in the paired runs,
## so it pays exactly nothing.
func test_the_habit_pays_nothing() -> void:
	var r := _region()
	r.advance_days(60)
	r.board.unlock(r.net.time)
	var xp := r.profile.xp
	var result := r.kpi_review(HABIT)
	assert_eq(result["error"], "")
	assert_eq(result["habit"], result["chosen"], "the same rules, the same quarter")
	assert_eq([result["improvement"], result["paid"], result["xp"], result["budget"]], [0.0, 0.0, 0, 0])
	assert_eq(r.profile.xp, xp)
	assert_true(result["habit"]["connections"]["completed"] > 0, "measured")


## A choice that beats the habit in the paired runs pays the measured gain,
## and keeps paying while it is kept: good management is a lasting dividend.
func test_a_choice_that_beats_the_habit_pays_every_quarter() -> void:
	var r := _region()
	r.advance_days(60)
	r.board.unlock(r.net.time)
	var xp := r.profile.xp
	var budget := r.profile.budget
	var first := r.kpi_review(CAREFUL)
	assert_eq(first["error"], "")
	assert_true(first["chosen"]["connections"]["first_time_right"] > first["habit"]["connections"]["first_time_right"])
	assert_eq(first["improvement"], KpiBoard.improvement(first["habit"], first["chosen"], r.board.menu.streams()))
	assert_true(first["paid"] > 0.0, "a real gain: %.3f" % first["paid"])
	assert_eq(first["xp"], roundi(first["paid"] * KpiBoard.REVIEW_XP))
	assert_eq(first["budget"], roundi(first["paid"] * KpiBoard.REVIEW_BUDGET))
	assert_eq([r.profile.xp - xp, r.profile.budget - budget], [first["xp"], first["budget"]], "granted")
	assert_eq(first["question"], QUESTION, "the coach asks about leading and lagging")
	r.advance_days(KpiBoard.REVIEW_DAYS)
	assert_true(r.kpi_review(CAREFUL)["paid"] > 0.0, "the same good choice pays again")


## A worse choice than the habit costs nothing, and pays nothing.
func test_a_worse_choice_pays_nothing() -> void:
	var r := _region()
	r.advance_days(60)
	r.board.unlock(r.net.time)
	var xp := r.profile.xp
	var result := r.kpi_review(HASTY)
	assert_true(result["improvement"] < 0.0, "measured: worse")
	assert_eq([result["paid"], result["xp"], result["budget"]], [0.0, 0, 0])
	assert_eq(r.profile.xp, xp)


## The forecast runs on copies: the region's own network goes on untouched,
## with the chosen rules in force.
func test_the_forecast_leaves_the_region_alone() -> void:
	var r := _region()
	r.advance_days(60)
	r.board.unlock(r.net.time)
	var time := r.net.time
	var finished: Array = r.net.stream("connections").finished.duplicate(true)
	assert_eq(r.kpi_review(CAREFUL)["error"], "")
	assert_eq(r.net.time, time, "no time passes")
	assert_eq(r.net.stream("connections").finished, finished)
	assert_true(r.net.effects().has(KpiBoard.SOURCE))


func test_a_quiet_stream_counts_as_no_change() -> void:
	var r := _region()
	r.board.unlock(r.net.time)
	assert_eq(r.kpi_review(GOOD)["error"], "", "day 0: nothing has finished yet, the forecast still runs")
	var busy := {"completed": 10, "lead_days_p50": 10.0, "on_time": 0.0, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var quiet := {"completed": 0, "lead_days_p50": 0.0, "on_time": 0.0, "first_time_right": 0.0,
		"throughput_per_week": 0.0, "wip_age": 0.0}
	var better := busy.duplicate()
	better["on_time"] = 0.5  # was 0: no measurable change
	better["first_time_right"] = 0.6  # +20 %
	var ab := PackedStringArray(["a", "b"])
	assert_near(KpiBoard.improvement({"a": quiet, "b": busy}, {"a": busy, "b": better}, ab), 0.2 / 5, 1e-9)
	assert_eq(KpiBoard.improvement({"a": busy}, {"a": quiet}, ab), 0.0)
	assert_eq(KpiBoard.improvement({}, {"a": busy}, ab), 0.0)


## Only the streams a department on the menu works in count; the rest
## changes for reasons the KPIs do not steer.
func test_an_untouched_stream_is_ignored() -> void:
	assert_eq(_menu().streams(), PackedStringArray(["connections"]), "the meters crew is on no menu")
	var busy := {"completed": 20, "lead_days_p50": 10.0, "on_time": 0.5, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var better := busy.duplicate()
	better["first_time_right"] = 0.6
	var both := {"a": busy, "b": busy}
	assert_eq(KpiBoard.improvement(both, {"a": busy, "b": better}, PackedStringArray(["a"])), 0.0, "b is not touched")
	assert_near(KpiBoard.improvement(both, {"a": busy, "b": better}, PackedStringArray(["a", "b"])), 0.2 / 5 / 2, 1e-9)
	assert_near(KpiBoard.improvement(both, {"a": better, "b": busy}, PackedStringArray(["a"])), 0.2 / 5, 1e-9)


## A low-volume stream: on time from 5 % to 50 % is +900 %, but one KPI's
## change counts for at most MAX_CHANGE.
func test_a_huge_swing_counts_for_at_most_the_cap() -> void:
	var before := {"completed": 20, "lead_days_p50": 10.0, "on_time": 0.05, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var after := before.duplicate()
	after["on_time"] = 0.5
	assert_near(KpiBoard.improvement({"a": before}, {"a": after}, A), KpiBoard.MAX_CHANGE / 5, 1e-9)
	after["on_time"] = 0.0  # and down: −100 % counts as −MAX_CHANGE
	after["first_time_right"] = 1.0  # +100 %
	assert_eq(KpiBoard.improvement({"a": before}, {"a": after}, A), 0.0, "the capped swings cancel out")


func test_a_thin_sample_counts_as_no_change() -> void:
	var before := {"completed": KpiBoard.MIN_COMPLETED - 1, "lead_days_p50": 10.0, "on_time": 0.5,
		"first_time_right": 0.5, "throughput_per_week": 2.0, "wip_age": 5.0}
	var after := before.duplicate()
	after["completed"] = KpiBoard.MIN_COMPLETED
	after["first_time_right"] = 0.6
	assert_eq(KpiBoard.improvement({"a": before}, {"a": after}, A), 0.0, "too few finished before")
	assert_eq(KpiBoard.improvement({"a": after}, {"a": before}, A), 0.0, "too few finished after")
	var enough := before.duplicate()
	enough["completed"] = KpiBoard.MIN_COMPLETED
	assert_true(KpiBoard.improvement({"a": enough}, {"a": after}, A) > 0.0, "the minimum sample counts")


## A region whose custom_design experiment, with a countermeasure that
## unlocks the board, is ready for its Check.
func _unlocking_experiment(menu: KpiMenu) -> Region:
	var cms := RulesFixture.countermeasures()
	cms[0]["unlocks"] = KpiBoard.UNLOCK  # standard_designs
	var r := RulesFixture.region(50000, 5, RulesFixture.problems(), cms)
	r.use_kpis(menu)
	r.activate("custom_design")
	r.use_tool("connections.design", "time_study")
	r.use_tool("connections.design", "documents")
	r.ask("connections.intake", "walk")
	r.use_tool("connections.design", "data")
	assert_eq(r.submit_a3("custom_design", RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs",
		["custom_design:0", "custom_design:2", "custom_design:4"], "throughput")), "")
	r.advance_days(Region.CHECK_DAYS)
	r.drain_events()
	return r


func test_a_passed_check_unlocks_the_board() -> void:
	var r := _unlocking_experiment(_menu())
	assert_false(r.board.unlocked, "not before the Check")
	assert_true(r.check("custom_design")["passed"])
	assert_true(r.board.unlocked)
	assert_true(r.board.review_due(r.net.time), "the first review is due at once")
	assert_eq(_reviews(r), 1, "the unlock is announced as the first review")


## Without department menus there is nothing to review: the board stays shut.
func test_an_empty_menu_keeps_the_board_locked() -> void:
	var r := _unlocking_experiment(KpiMenu.new())
	assert_true(r.check("custom_design")["passed"])
	assert_false(r.board.unlocked)
	assert_eq(_reviews(r), 0, "no review is announced")


## Effect sources apply in order and a later lever wins (SimModifiers). A
## fix resolved after a review must not override the KPIs chosen there, and
## a problem still open keeps its hold over them: problem > board > countermeasure.
func test_the_board_rules_win_over_a_resolved_fix() -> void:
	var problems := RulesFixture.problems()
	problems[2]["effects"].append(NetFixture.effect("intake", "order_rule", "due"))  # revision_backlog
	var cms := RulesFixture.countermeasures()
	cms[1]["effects"].append(NetFixture.effect("intake", "start_rule", "push"))  # poka_yoke_form
	var r := RulesFixture.region(50000, 5, problems, cms)
	r.use_kpis(_menu())
	r.board.unlock(r.net.time)
	assert_eq(r.kpi_review(GOOD)["error"], "")
	var intake := r.net.pools["intake"]
	assert_eq([intake.start_rule, intake.order_rule], ["pull", "oldest"], "the board's rules")
	assert_true(r.activate("revision_backlog"))
	assert_eq(intake.order_rule, "due", "an open problem overrides the board")
	assert_true(r.activate("incomplete_application"))
	r.use_tool("connections.intake", "documents")
	r.ask("connections.intake", "walk")
	assert_eq(r.submit_a3("incomplete_application", RulesFixture.a3(r, "incomplete_application", "defects",
		"poka_yoke_form", ["incomplete_application:0", "incomplete_application:1"], "first_time_right")), "")
	assert_eq(intake.start_rule, "push", "the experiment runs with its own rule")
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("incomplete_application")["passed"])
	assert_false(r.act("incomplete_application", true).is_empty())
	assert_eq(intake.start_rule, "pull", "the board's rule is back in force")
	assert_eq(intake.order_rule, "due", "the open problem still overrides the board")


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
		"chosen": {"nobody": ["x"], "intake": ["intake_oldest", "prep_due", 7, "intake_output"], "prep": ["prep_due"],
			"intake_twice": ["intake_oldest", "intake_oldest"]},
		"snapshot": {"connections": {"completed": "many", "on_time": 0.5}, "ghost": 3},
	}
	r = _region()
	assert_eq(RegionState.restore(r, saved)["error"], "")
	assert_true(r.board.unlocked)
	assert_eq(r.board.next_review_at, 0)
	assert_eq(r.board.chosen, {"intake": PackedStringArray(["intake_oldest", "intake_output"])} as Dictionary[String, PackedStringArray],
		"unknown ids dropped; a department left with fewer than two is dropped")
	assert_eq(r.kpi_review(GOOD)["error"], "", "a damaged board still reviews")


## A JSON round trip turns ints into floats; the review must not come early.
func test_a_json_round_trip_keeps_the_review_date() -> void:
	var r := _due_region()
	r.kpi_review(GOOD)
	r.advance_days(30)
	var fresh := _region()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(r.board.to_dict()))
	fresh.board.load_dict(saved)
	assert_eq(fresh.board.next_review_at, r.board.next_review_at)
	assert_false(fresh.board.review_due(r.net.time))
	assert_eq(fresh.board.chosen, r.board.chosen)
