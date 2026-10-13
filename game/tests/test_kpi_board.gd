extends TestCase
## The KPI board and the quarterly review: every department follows two KPIs
## from its menu, chosen each quarter; the reward follows only the measured
## end-to-end change against the best level reached so far, in the streams
## the departments on the menu work in, beyond the quarter-to-quarter noise.

const QUESTION := "Welke KPI stuurt het werk van morgen?"
## One stream, "a", that a department on the menu works in.
const A: PackedStringArray = ["a"]
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
	m.pool_steps["intake"] = PackedStringArray(["connections.intake"])
	m.pool_steps["prep"] = PackedStringArray(["connections.design"])
	return m


func _region() -> Region:
	var r := RulesFixture.region()
	r.use_kpis(_menu())
	return r


## A region whose board was just unlocked: the first review (the baseline) is due.
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
	r.board.unlock(r.net.time)
	assert_eq(r.kpi_review({})["error"], "choose_two")


## The first review chooses the KPIs and measures the baseline; the Check
## already rewarded the fix that unlocked the board, so it pays nothing.
func test_the_first_review_sets_the_baseline() -> void:
	var r := _region()
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.board.unlock(r.net.time)
	var xp := r.profile.xp
	var budget := r.profile.budget
	var first := r.kpi_review(GOOD)
	assert_eq(first["error"], "")
	assert_true(first["baseline"])
	assert_eq([first["improvement"], first["xp"], first["budget"]], [0.0, 0, 0])
	assert_eq([r.profile.xp, r.profile.budget], [xp, budget])
	var baseline: Dictionary = first["after"].duplicate(true)
	assert_true(baseline["connections"]["completed"] > 0, "measured")
	first["after"]["connections"]["completed"] = -1
	assert_eq(r.board.snapshot, baseline, "the caller cannot change the baseline")
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var second := r.kpi_review(GOOD)
	assert_eq(second["error"], "")
	assert_false(second["baseline"])
	assert_eq(second["before"], baseline, "the quarter before")
	assert_eq(second["best"], baseline, "the first best levels are the baseline")
	assert_eq(second["improvement"], KpiBoard.improvement(baseline, second["after"], r.board.menu.streams()))
	assert_eq(second["paid"], KpiBoard.paid(second["improvement"]))
	assert_eq(r.profile.xp - xp, second["xp"])


## A quarter measured against the one before it (the baseline review), with
## the same KPIs chosen;
## `bad_first` puts the bad first-time-right (in both streams: they share the
## crew) in the first quarter, else in the second.
func _quarter(bad_first: bool) -> Dictionary:
	var r := _region()
	var bad := [NetFixture.effect("connections.intake", "ftr", -0.4), NetFixture.effect("meters.visit", "ftr", -0.4)]
	if bad_first:
		r.net.set_effects("test", bad)
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.board.unlock(r.net.time)
	assert_true(r.kpi_review(GOOD)["baseline"])
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
	assert_true(worse["improvement"] < 0.0, "measured: worse")
	assert_eq([worse["paid"], worse["xp"], worse["budget"]], [0.0, 0, 0], "a worse quarter earns nothing, and costs nothing")
	var better := _quarter(true)
	assert_true(better["after"]["connections"]["first_time_right"] > better["before"]["connections"]["first_time_right"])
	assert_true(better["improvement"] > KpiBoard.DEAD_BAND, "a real gain, beyond the noise: %.3f" % better["improvement"])
	assert_near(better["paid"], better["improvement"] - KpiBoard.DEAD_BAND, 1e-9, "only the part beyond the noise pays")
	assert_eq(better["xp"], roundi(better["paid"] * KpiBoard.REVIEW_XP))
	assert_eq(better["budget"], roundi(better["paid"] * KpiBoard.REVIEW_BUDGET))
	assert_eq(better["question"], QUESTION, "the coach asks about leading and lagging")


## A bad quarter costs nothing, so climbing back out of it must not pay
## either: the review compares with the best level reached so far.
func test_a_recovery_after_a_bad_quarter_pays_nothing() -> void:
	var r := _region()
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.board.unlock(r.net.time)
	assert_true(r.kpi_review(GOOD)["baseline"])
	r.net.set_effects("test", [NetFixture.effect("connections.intake", "ftr", -0.4)])
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var bad := r.kpi_review(GOOD)
	assert_eq(bad["xp"], 0, "the bad quarter")
	r.net.clear_effects("test")
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var xp := r.profile.xp
	var budget := r.profile.budget
	var recovered := r.kpi_review(GOOD)
	assert_eq(recovered["error"], "")
	assert_true(recovered["after"]["connections"]["first_time_right"] > bad["after"]["connections"]["first_time_right"] + 0.1,
		"it did recover")
	assert_eq([recovered["xp"], recovered["budget"]], [0, 0], "back to the old level is no gain: %.3f" % recovered["improvement"])
	assert_eq(recovered["paid"], 0.0)
	assert_eq([r.profile.xp, r.profile.budget], [xp, budget])


## Quarter-to-quarter noise is not a gain: only the part beyond the dead band pays.
func test_a_gain_inside_the_dead_band_pays_nothing() -> void:
	assert_eq(KpiBoard.paid(KpiBoard.DEAD_BAND * 0.9), 0.0, "inside the noise")
	assert_eq(KpiBoard.paid(KpiBoard.DEAD_BAND), 0.0)
	assert_eq(KpiBoard.paid(-0.2), 0.0, "worse costs nothing")
	assert_near(KpiBoard.paid(KpiBoard.DEAD_BAND + 0.03), 0.03, 1e-9)
	assert_true(KpiBoard.DEAD_BAND > 0.0)


## The best levels: per stream and per measure, the lowest lead time and age
## of open work and the highest on time, first-time-right and throughput.
func test_the_best_levels_rise_only() -> void:
	var r := _region()
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.board.unlock(r.net.time)
	var first := r.kpi_review(GOOD)
	assert_eq(r.board.best, first["after"], "the baseline is the first mark")
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var second := r.kpi_review(GOOD)
	for id: String in ["connections", "meters"]:
		var b: Dictionary = first["after"][id]
		var a: Dictionary = second["after"][id]
		for m: String in KpiBoard.MEASURES:
			var want: float = minf(b[m], a[m]) if KpiBoard.MEASURES[m] < 0 else maxf(b[m], a[m])
			assert_eq(r.board.best[id][m], want, "%s %s" % [id, m])
	var mark := {"completed": 20, "lead_days_p50": 10.0, "on_time": 0.5, "first_time_right": 0.5,
		"throughput_per_week": 2.0, "wip_age": 5.0}
	var worse := mark.duplicate()
	worse["first_time_right"] = 0.4
	var back := mark.duplicate()
	assert_true(KpiBoard.improvement({"a": mark}, {"a": worse}, PackedStringArray(["a"])) < 0.0)
	assert_eq(KpiBoard.improvement({"a": mark}, {"a": back}, PackedStringArray(["a"])), 0.0, "the old level again")


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


func test_a_quiet_stream_counts_as_no_change() -> void:
	var r := _region()
	r.board.unlock(r.net.time)
	assert_true(r.kpi_review(GOOD)["baseline"], "day 0: nothing has finished yet")
	r.advance_days(KpiBoard.REVIEW_DAYS)
	var result := r.kpi_review(GOOD)
	assert_eq(result["error"], "")
	assert_false(result["baseline"])
	assert_eq([result["improvement"], result["xp"]], [0.0, 0])
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
	cms[0]["unlocks"] = "kpi_board"  # standard_designs
	var defs: Array[CountermeasureDef] = []
	for d: Dictionary in cms:
		defs.append(CountermeasureDef.from_dict(d))
	var profile := Profile.new()
	profile.budget = 50000
	var r := Region.new(RulesFixture.net(), RulesFixture.problem_defs(), defs, profile)
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
	var problem_defs: Array[ProblemDef] = []
	for d: Dictionary in problems:
		problem_defs.append(ProblemDef.from_dict(d))
	var cm_defs: Array[CountermeasureDef] = []
	for d: Dictionary in cms:
		cm_defs.append(CountermeasureDef.from_dict(d))
	var profile := Profile.new()
	profile.budget = 50000
	var r := Region.new(RulesFixture.net(), problem_defs, cm_defs, profile)
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
		"unlocked": true, "next_review_at": "soon", "has_baseline": "yes",
		"chosen": {"nobody": ["x"], "intake": ["intake_oldest", "prep_due", 7, "intake_output"], "prep": ["prep_due"],
			"intake_twice": ["intake_oldest", "intake_oldest"]},
		"snapshot": {"connections": {"completed": "many", "on_time": 0.5}, "ghost": 3},
	}
	r = _region()
	assert_eq(RegionState.restore(r, saved)["error"], "")
	assert_true(r.board.unlocked)
	assert_eq(r.board.next_review_at, 0)
	assert_false(r.board.has_baseline)
	assert_eq(r.board.chosen, {"intake": PackedStringArray(["intake_oldest", "intake_output"])} as Dictionary[String, PackedStringArray],
		"unknown ids dropped; a department left with fewer than two is dropped")
	var result := r.kpi_review(GOOD)
	assert_eq(result["error"], "", "a damaged board still reviews")
	assert_true(result["baseline"], "and measures again before it rewards")


## The best levels are saved: a reload must not lower the mark and pay a recovery.
func test_the_best_levels_survive_save_and_load() -> void:
	var r := _due_region()
	r.kpi_review(GOOD)
	r.advance_days(KpiBoard.REVIEW_DAYS)
	r.kpi_review(GOOD)
	r.board.best["connections"]["first_time_right"] = 0.99  # a mark the last quarter did not reach
	assert_ne(r.board.best, r.board.snapshot)
	var fresh := _region()
	fresh.board.load_dict(bytes_to_var(var_to_bytes(r.board.to_dict())))  # as SaveFile stores it
	assert_eq(fresh.board.best, r.board.best)
	var restored := RulesFixture.region(0, 123)
	restored.use_kpis(_menu())
	assert_eq(RegionState.restore(restored, RegionState.capture(r))["error"], "")
	assert_eq(restored.board.best, r.board.best)
	# An old save has no best levels: the last snapshot is the mark.
	var old := r.board.to_dict()
	old.erase("best")
	fresh = _region()
	fresh.board.load_dict(old)
	assert_eq(fresh.board.best, r.board.snapshot)
	# Damaged best levels count as missing; damaged numbers as 0.
	old["best"] = {"connections": "garbage", "meters": {"completed": 30, "on_time": "high", "wip_age": 2}}
	fresh = _region()
	fresh.board.load_dict(old)
	assert_eq(fresh.board.best["connections"], r.board.snapshot["connections"])
	assert_eq(fresh.board.best["meters"], {"completed": 30, "lead_days_p50": 0.0, "on_time": 0.0,
		"first_time_right": 0.0, "throughput_per_week": 0.0, "wip_age": 2.0})


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
	assert_true(fresh.board.has_baseline)
	assert_eq(fresh.board.chosen, r.board.chosen)
