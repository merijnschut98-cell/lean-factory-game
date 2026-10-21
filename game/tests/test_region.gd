extends TestCase
## The PDCA loop of one region over the live simulation.


func _region(budget: int = 50000) -> Region:
	return RulesFixture.region(budget)


func _clue_ids(clues: Array) -> Array:
	return clues.map(func(c: Clue) -> String: return c.id)


## Investigate custom_design like an expert: every key clue, walking upstream.
func _investigate(r: Region) -> void:
	r.use_tool("connections.design", "time_study")  # spots it; key clue depth 0
	r.use_tool("connections.design", "documents")  # depth 1
	r.ask("connections.intake", "walk")  # depth 1, upstream
	r.use_tool("connections.design", "data")  # depth 2


func _a3(r: Region, cm: String, evidence: Array = ["custom_design:0", "custom_design:2", "custom_design:4"]) -> Dictionary:
	return RulesFixture.a3(r, "custom_design", "overprocessing", cm, evidence, "lead_time")


func test_activating_a_problem_hits_the_simulation() -> void:
	var r := _region()
	assert_true(r.activate("custom_design"))
	assert_eq(r.net.stream("connections").step("design").touch_minutes, 360)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.ACTIVE)
	assert_false(r.activate("custom_design"), "already active")


func test_at_most_four_problems_open() -> void:
	var defs := RulesFixture.problem_defs()
	for i in 3:
		var d: Dictionary = RulesFixture.problems()[1].duplicate(true)
		d["id"] = "extra_%d" % i
		defs.append(ProblemDef.from_dict(d))
	var r := Region.new(RulesFixture.net(), defs, RulesFixture.countermeasure_defs(), Profile.new())
	var activated := 0
	for p in defs:
		activated += 1 if r.activate(p.id) else 0
	assert_eq(activated, Region.MAX_OPEN)


func test_tools_spot_and_reveal_one_why_at_a_time() -> void:
	var r := _region()
	r.activate("custom_design")
	var first := r.use_tool("connections.design", "data")
	assert_eq(first["spotted"], ["custom_design"])
	assert_eq(_clue_ids(first["clues"]), [], "the depth-2 data clue waits for depths 0 and 1")
	var timed := r.use_tool("connections.design", "time_study")
	assert_eq(_clue_ids(timed["clues"]), ["custom_design:0"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "documents")["clues"]), ["custom_design:2"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "data")["clues"]), ["custom_design:4"])
	assert_eq(_clue_ids(r.use_tool("connections.design", "data")["clues"]), [], "found once")


func test_some_clues_are_found_upstream() -> void:
	var r := _region()
	r.activate("custom_design")
	r.use_tool("connections.design", "time_study")
	assert_eq(_clue_ids(r.use_tool("connections.design", "conversation")["clues"]), [], "not at design")
	var reply := r.ask("connections.intake", "walk")
	assert_eq(reply["reply"], "clue")
	assert_eq(reply["clue"].id, "custom_design:3")


func test_quick_looks_miss_hidden_problems() -> void:
	var r := _region()
	r.activate("revision_backlog")
	var look := r.use_tool("connections.revision", "queue_count")
	assert_eq(look["spotted"], [])
	assert_true(look["hidden_signal"], "something here needs a deeper tool")
	assert_eq(r.use_tool("connections.revision", "data")["spotted"], ["revision_backlog"])


func test_blame_costs_a_teams_trust_and_respect_repairs_it() -> void:
	var r := _region()
	r.activate("custom_design")
	r.activate("incomplete_application")
	r.use_tool("connections.design", "time_study")
	assert_eq(r.ask("connections.design", "behind")["reply"], "blame")
	assert_eq(r.trust_of("connections.design"), -1)
	assert_true(r.state["custom_design"].blamed)
	assert_eq(r.ask("connections.design", "walk")["reply"], "guarded", "they stop sharing")
	assert_eq(r.ask("connections.intake", "walk")["reply"], "clue", "another team still talks")
	assert_eq(r.ask("connections.design", "ok")["reply"], "closed")
	r.ask("connections.design", "thanks")
	assert_eq(r.trust_of("connections.design"), 0)
	assert_ne(r.ask("connections.design", "walk")["reply"], "guarded")


func test_open_questions_without_a_clue_describe_the_work() -> void:
	var r := _region()
	r.activate("custom_design")
	# A rush of applications on top: design at ~180% load, so its queue grows
	# whatever the random draws (37–70 orders after 30 days over seeds 1–10).
	r.net.set_effects("event:rush", [NetFixture.effect("connections", "demand", 1.6)])
	r.net.advance_days(30)
	var reply := r.ask("connections.design", "obstacle")
	assert_eq(reply["reply"], "observation")
	assert_eq(reply["observation"]["kind"], "queue")
	assert_true(reply["observation"]["value"] > 10)


func test_the_a3_refuses_weak_plans() -> void:
	var r := _region(1000)
	r.activate("custom_design")
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "not_spotted")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs", [])), "evidence")
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs", ["custom_design:1"])), "evidence",
		"only facts you found count")
	var no_waste := _a3(r, "standard_designs")
	no_waste["waste"] = "laziness"
	assert_eq(r.submit_a3("custom_design", no_waste), "waste")


func test_an_expert_run_resolves_the_problem() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	var budget := r.profile.budget
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "")
	assert_eq(r.profile.budget, budget - 8000)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.DOING)
	r.advance_days(Region.CHECK_DAYS)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.CHECK_READY)
	var check := r.check("custom_design")
	assert_true(check["passed"])
	assert_true(check["cause_correct"] and check["waste_right"])
	assert_true(check["after"]["capacity"] > check["before"]["capacity"])
	var score := r.act("custom_design", true)
	assert_true(score["total"] >= 22, "score %d %s" % [score["total"], score["notes"]])
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)
	assert_true(r.profile.xp > 0)
	assert_false(r.net.effects().has("problem:custom_design"), "the problem is gone")
	assert_true(r.net.effects().has("cm:custom_design"), "the improvement stays")


func test_a_mismatched_countermeasure_fails_check() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "poka_yoke_form")), "")
	assert_eq(r.net.stream("connections").step("design").touch_minutes, 360, "it does not touch the cause at all")
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check("custom_design")
	assert_false(check["passed"])
	assert_eq(check["lesson"], "mismatch")
	assert_eq(check["forecast"]["with"], check["forecast"]["without"], "with or without it, the same future")
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.SPOTTED, "back to the gemba")
	assert_eq(r.state["custom_design"].failed_checks, 1)
	assert_false(r.net.effects().has("cm:custom_design"))
	assert_eq(r.net.stream("connections").step("design").touch_minutes, 360, "the problem is back at full strength")


# ── The Check measures what the A3 predicts (QA findings 4, 5, 21) ─────────

## custom_design's harm and fix (touch time) moved to another step.
func _region_at(place: String, harm: Dictionary, fix: Dictionary, kpi: String) -> Region:
	var problems := RulesFixture.problems()
	problems[0].merge({"step": place, "kpi": kpi, "effects": [harm], "clues": [RulesFixture.clue("data", true, 0)]}, true)
	var cms := RulesFixture.countermeasures()
	cms[0]["effects"] = [fix]
	var r := RulesFixture.region(50000, 5, problems, cms)
	r.activate("custom_design")
	r.use_tool(place, "data")
	return r


func _check_with(r: Region, prediction: String) -> Dictionary:
	var a3 := RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs", ["custom_design:0"], prediction)
	assert_eq(r.submit_a3("custom_design", a3), "")
	r.advance_days(Region.CHECK_DAYS)
	return r.check("custom_design")


## The Check runs the coming quarter twice on copies of the network, with
## the fix and without it (same random sequences), so a pass means the
## predicted KPI moved because of the fix. The game itself does not move on.
func test_the_check_passes_when_the_predicted_kpi_moved_against_the_no_fix_forecast() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	var a3 := _a3(r, "standard_designs")
	a3["prediction"] = "capacity"
	r.submit_a3("custom_design", a3)
	r.advance_days(Region.CHECK_DAYS)
	var now := r.net.time
	var check := r.check("custom_design")
	assert_eq(r.net.time, now, "the forecast runs on copies")
	var forecast: Dictionary = check["forecast"]
	assert_eq(forecast["kpi"], "capacity")
	assert_true(forecast["with"]["capacity"] > forecast["without"]["capacity"], str(forecast))
	assert_near(forecast["gain"], forecast["gains"]["capacity"], 1e-9)
	assert_true(forecast["gain"] > Pdca.CHECK_NOISE)
	assert_true(check["passed"])


## A lagging KPI (lead time, on time, first time right) measures orders that
## started long before the fix: the Check looks one lead time ahead (at least
## a quarter) and measures the orders that finish after it.
func test_the_check_measures_the_orders_finishing_after_one_lead_time() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check("custom_design")
	var lead := ceili(check["after"]["lead_time"])
	assert_between(lead, 1, Region.CHECK_HORIZON - Region.MEASURE_DAYS, "a short stream")
	assert_eq(check["forecast"]["days"], Region.CHECK_HORIZON, "at least a quarter")
	assert_eq(check["forecast"]["window"], Region.CHECK_HORIZON - lead)


## A long wait only some orders take (grid reinforcement: months) is longer
## than the stream's median: the Check looks past it.
func test_the_check_looks_past_a_long_wait() -> void:
	var place := "connections.permit"
	var harm := NetFixture.effect(place, "wait_time", 30.0)  # 150 days
	var r := _region_at(place, harm, harm, "lead_time")
	# A countermeasure that misses the cause leaves the wait as it is.
	var a3 := RulesFixture.a3(r, "custom_design", "overprocessing", "poka_yoke_form", ["custom_design:0"], "lead_time")
	assert_eq(r.submit_a3("custom_design", a3), "")
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check("custom_design")
	assert_true(check["after"]["lead_time"] < 150.0, "the median order does not wait for it")
	assert_eq(check["forecast"]["days"], 150 + Region.MEASURE_DAYS)
	assert_eq(check["forecast"]["window"], Region.MEASURE_DAYS)


## A well-fitting fix whose predicted KPI does not move fails the Check: the
## fit decides how much moves, the numbers decide the Check.
func test_a_fitting_fix_fails_when_its_predicted_kpi_does_not_move() -> void:
	var place := "connections.revision"  # not the constraint
	var r := _region_at(place, NetFixture.effect(place, "touch_time", 1.5), NetFixture.effect(place, "touch_time", 0.8), "capacity")
	var check := _check_with(r, "capacity")
	assert_eq(check["level"], "full", "the fix fits")
	assert_true(check["forecast"]["gain"] <= Pdca.CHECK_NOISE, str(check["forecast"]))
	assert_false(check["passed"])
	assert_eq(check["lesson"], "not_moved")
	assert_true(check["not_constraint"])


## A batch or wait taken out anywhere on the path shortens lead time (Little's
## law), although a wait has no team and adds no capacity: no "not the
## bottleneck" verdict, and the score counts the shorter lead time.
func test_a_shorter_wait_is_a_lead_time_gain_not_a_missed_bottleneck() -> void:
	var place := "connections.permit"
	var r := _region_at(place, NetFixture.effect(place, "wait_time", 2.0), NetFixture.effect(place, "wait_time", 0.5), "lead_time")
	var check := _check_with(r, "lead_time")
	assert_true(check["passed"], str(check["forecast"]))
	assert_false(check["not_constraint"], "a wait is not a capacity question")
	assert_true(check["forecast"]["gains"]["lead_time"] > Pdca.CHECK_NOISE, str(check["forecast"]["gains"]))
	var score := r.act("custom_design", true)
	assert_false("impact_not_constraint" in score["notes"], str(score["notes"]))
	assert_true(score["impact"] >= 4, "impact %d" % score["impact"])


func test_another_countermeasure_also_works_less_well() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "delegated_approval"))
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("custom_design")["passed"], "a different, smaller improvement is still an improvement")
	assert_true(r.act("custom_design", true)["countermeasure"] >= 4)


func test_improvement_work_takes_team_hours_during_the_experiment() -> void:
	var r := _region()
	var prep := r.net.pools["prep"]
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	# 40 hours over two weeks of a team of 2 × 40 hours a week.
	assert_near(prep.availability, 1.0 - 40.0 / (2.0 * 80.0), 1e-9)
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	assert_eq(prep.availability, 1.0, "back to daily work after the experiment")


func test_an_unstandardised_fix_comes_back() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", false)
	r.advance_days(29)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)
	r.advance_days(2)
	# Sustain is the hardest S: the gain is gone. The problem comes back
	# through its mission (CLAUDE.md §2), so it waits, dormant, until then.
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.DORMANT)
	assert_false(r.net.effects().has("cm:custom_design"))
	assert_true(r.activate("custom_design"), "the mission can switch it on again")
	assert_true(r.drain_events().any(func(e: Dictionary) -> bool: return e["type"] == "recurred"))


## Standard work keeps the gain well past the countermeasure's own decay (it
## still wears, slowly: test_sustain.gd).
func test_a_standardised_fix_outlasts_its_decay() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", true)
	r.advance_days(60)
	assert_eq(r.state["custom_design"].phase, ProblemState.Phase.RESOLVED)


## A problem can cost money every week it is active (overtime, damage
## repairs, claims), weakened by a working countermeasure and gone once it is
## resolved. The Check shows the cost before and after.
func test_an_active_problem_costs_money_every_week() -> void:
	var r := _region()
	r.activate("custom_design")
	assert_eq(r.weekly_cost(), 700.0)
	r.advance_days(7)
	assert_eq(r.profile.budget, 50000 - 700, "a week of overtime")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "")
	assert_near(r.weekly_cost(), 70.0, 1e-6, "the fix takes away 90%")
	r.advance_days(Region.CHECK_DAYS)
	var result := r.check("custom_design")
	assert_eq(result["before"]["cost_per_week"], 700.0)
	assert_near(result["after"]["cost_per_week"], 70.0, 1e-6)
	r.act("custom_design", true)
	assert_eq(r.weekly_cost(), 0.0, "resolved: no more cost")
	r.advance_days(7)
	# A standardised fix wears slowly (Sustain): a little of the cost creeps back.
	assert_between(r.weekly_cost(), 0.01, 70.0, "a slowly wearing fix")



## The company never goes down (CLAUDE.md §2): an improvement can be paid on
## credit, and debt brings a bad period instead of the end of the game.
func test_an_improvement_can_be_paid_into_debt() -> void:
	var r := _region(1000)
	r.activate("custom_design")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "")
	assert_eq(r.profile.budget, 1000 - 8000)
	assert_true(r.in_bad_period())


## In a bad period there is no money for overtime or temporary staff, and
## sickness absence rises: every team has a little less time. Paying off the
## debt ends it.
func test_debt_brings_a_bad_period_until_it_is_paid_off() -> void:
	var r := _region(1000)
	var before := r.net.pools["prep"].availability
	r.grant(0, -2000)
	assert_true(r.in_bad_period())
	assert_near(r.net.pools["prep"].availability, before - Region.BAD_PERIOD_AVAILABILITY, 1e-9)
	assert_eq(r.drain_events(), [{"type": "bad_period", "started": true},
		{"type": "reputation", "change": Reputation.BAD_PERIOD, "reason": "bad_period", "value": Reputation.START + Reputation.BAD_PERIOD}])
	r.grant(0, 500)
	assert_eq(r.drain_events(), [], "still in debt")
	r.grant(0, 1000)
	assert_false(r.in_bad_period())
	assert_near(r.net.pools["prep"].availability, before, 1e-9)
	assert_eq(r.drain_events(), [{"type": "bad_period", "started": false}])


## Recovery is always possible (CLAUDE.md §2): debt stops at a floor, so a
## few solved problems always bring the region back (QA finding: debt spiral).
func test_debt_stops_at_a_floor_so_recovery_stays_within_reach() -> void:
	var r := _region(Region.DEBT_FLOOR + 1000)
	r.activate("custom_design")
	_investigate(r)
	assert_eq(r.submit_a3("custom_design", _a3(r, "standard_designs")), "", "an experiment can still be started")
	assert_eq(r.profile.budget, Region.DEBT_FLOOR)
	assert_true(r.in_bad_period())
	r.advance_days(7)
	assert_eq(r.profile.budget, Region.DEBT_FLOOR, "the problem's costs stop at the floor")
	r.grant(0, 5000)
	assert_eq(r.profile.budget, Region.DEBT_FLOOR + 5000, "every reward counts towards recovery")


## QA 2.12 (c): the region counts the days its budget spent at the floor (the way back,
## a cost-saving side chain, opens on it); the count is kept across a save and never
## falls, so the chain does not flicker on the board as the budget moves.
func test_the_region_counts_the_days_at_the_debt_floor() -> void:
	var r := _region(Region.DEBT_FLOOR + 100)
	r.advance_days(3)
	assert_eq(r.floor_days, 0, "just above the floor")
	r.grant(0, -100)
	r.advance_days(5)
	assert_eq(r.floor_days, 5)
	r.grant(0, 20000)
	r.advance_days(4)
	assert_eq(r.floor_days, 5, "off the floor the count stands still")
	var copy := _region()
	assert_eq(RegionState.restore(copy, RegionState.capture(r))["error"], "")
	assert_eq(copy.floor_days, 5)


## Long-term, respectful play pays its way: finance books part of what a
## held fix saves into the improvement budget every week, at the fix's health,
## while the team that runs it trusts you (a blamed team stops reporting it).
func test_a_held_fix_pays_savings_while_its_team_trusts_you() -> void:
	var r := _region()
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	assert_eq(r.weekly_savings(), 0.0, "nothing is saved before the Act")
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", true)
	assert_near(r.weekly_savings(), Pdca.BUDGET_BASE["high"] * Region.SAVINGS_RATE, 1e-9, "a fresh fix saves in full")
	var budget := r.profile.budget
	r.advance_days(7)
	assert_between(r.profile.budget - budget, roundi(Pdca.BUDGET_BASE["high"] * Region.SAVINGS_RATE) - 70, roundi(Pdca.BUDGET_BASE["high"] * Region.SAVINGS_RATE),
		"a week of savings, less what creeps back")
	assert_true(r.weekly_savings() < Pdca.BUDGET_BASE["high"] * Region.SAVINGS_RATE, "a wearing fix saves less")
	r.ask("connections.design", "behind")
	assert_eq(r.weekly_savings(), 0.0, "a blamed team stops reporting its savings")
	r.ask("connections.design", "thanks")
	assert_true(r.weekly_savings() > 0.0, "repaired trust brings them back")


## Recovery is within reach from the floor: a few held fixes pay it back.
func test_savings_pay_off_debt() -> void:
	var r := _region(Region.DEBT_FLOOR)
	r.activate("custom_design")
	_investigate(r)
	r.submit_a3("custom_design", _a3(r, "standard_designs"))
	r.advance_days(Region.CHECK_DAYS)
	r.check("custom_design")
	r.act("custom_design", false)
	var budget := r.profile.budget
	r.advance_days(14)
	assert_true(r.profile.budget > budget, "from %d to %d" % [budget, r.profile.budget])


func test_problem_costs_can_push_the_region_into_a_bad_period() -> void:
	var r := _region(1000)
	r.activate("custom_design")  # 700 a week
	r.advance_days(14)
	assert_eq(r.profile.budget, 1000 - 1400)
	assert_true(r.in_bad_period())


## The Check shows the age of the open work too (wip_age), so a long wait is
## visible before its orders finish.
func test_the_snapshot_measures_the_age_of_open_work() -> void:
	var r := _region()
	r.activate("custom_design")
	r.advance_days(30)
	var s := r.snapshot("custom_design")
	assert_near(s["wip_age"], r.net.open_age_days(r.net.stream("connections")), 1e-9)
	assert_true(s["wip_age"] > 0.0)
	assert_true("wip_age" in Investigation.KPIS, "a prediction can name it")


## The real catalogue: silo_kpis investigated like an expert, with Obeya
## with end-to-end KPIs as the experiment.
func _obeya_experiment(c: Catalog) -> Region:
	var r := Region.new(Network.load_file(Network.DEFAULT_PATH, 11), c.problems, c.countermeasures, Profile.new())
	r.use_kpis(c.kpis)
	assert_true(r.activate("silo_kpis"))
	var intake := r.net.pools["intake"]
	assert_eq([intake.start_rule, intake.order_rule], ["push", "shortest"], "the siloed KPIs steer by volume")
	var keys := r.problems["silo_kpis"].clues.filter(func(k: Clue) -> bool: return k.key)
	keys.sort_custom(func(a: Clue, b: Clue) -> bool: return a.depth < b.depth)
	r.use_tool("connections.design", "data")  # a deep look spots it
	for k: Clue in keys:
		if k.tool == "conversation":
			r.ask(k.at, "walk")
		else:
			r.use_tool(k.at, k.tool)
	var a3 := RulesFixture.a3(r, "silo_kpis", "overproduction", "obeya_end_to_end",
		keys.map(func(k: Clue) -> String: return k.id), "first_time_right")
	assert_eq(r.submit_a3("silo_kpis", a3), "")
	assert_eq(r.state["silo_kpis"].phase, ProblemState.Phase.DOING)
	return r


## The countermeasure's work rules replace the ones the problem set (a set
## lever takes the value of the latest source), already while the experiment runs.
func test_the_countermeasure_rules_override_the_problem() -> void:
	var r := _obeya_experiment(Catalog.load_from())
	var intake := r.net.pools["intake"]
	assert_eq([intake.start_rule, intake.order_rule], ["pull", "oldest"], "the countermeasure's KPIs win")
	assert_eq(r.net.pools["work_prep"].start_rule, "pull")


## A passed Check of the Obeya unlocks the board, and the real menus' work
## rules fit the real network.
func test_the_obeya_unlocks_the_kpi_board() -> void:
	var c := Catalog.load_from()
	var r := _obeya_experiment(c)
	assert_eq(r.net.pools["intake"].pull_limit_days, c.kpis.pull_limit_days)
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("silo_kpis")["passed"])
	assert_true(r.board.review_due(r.net.time), "the baseline review is due at once")
	var choices := {}
	for pool: String in c.kpis.menus:
		choices[pool] = c.kpis.menus[pool].slice(0, 2).map(func(k: KpiDef) -> String: return k.id)
	assert_eq(r.kpi_review(choices)["error"], "")
	assert_false(r.net.effects()[KpiBoard.SOURCE].is_empty())


## Counting the queue measures it: how many orders wait and how many days of
## the team's work that is.
func test_counting_a_queue_measures_it() -> void:
	var r := _region()
	r.advance_days(3)
	var step := r.net.step_at("connections.design")
	var counted: Dictionary = r.use_tool("connections.design", "queue_count")["queue"]
	assert_eq(counted, {"count": r.net.queue_of(step).size(), "days": r.net.queue_days(step)})
	assert_eq(counted, r.queue_at("connections.design"))
	assert_false(r.use_tool("connections.design", "shadow").has("queue"), "other tools do not count")


## Every gemba tool works at every kind of step (QA autoplay: queue_count at
## connections.permit crashed). At a wait (a permit) or a material step the
## count is the orders waiting there, holding no days of a team's work; the
## Check's measures show the same queue.
func test_every_tool_works_at_every_kind_of_step() -> void:
	var net := NetFixture.net([NetFixture.pool("prep", 2), NetFixture.pool("crew", 2)], [
		NetFixture.stream("connections", [
			NetFixture.work("design", "prep", 1.0),
			NetFixture.wait("permit", 5.0),
			NetFixture.material("cable", "cable"),
			NetFixture.work("build", "crew", 1.0),
		]),
	], [NetFixture.stock("cable", 0, 0, 1, 30.0)])
	var r := Region.new(net, [] as Array[ProblemDef], [] as Array[CountermeasureDef], Profile.new())
	r.advance_days(10)
	var s := net.stream("connections")
	for step in s.steps:
		var place := "connections." + step.id
		for tool: String in Investigation.TOOLS:
			assert_true(r.use_tool(place, tool).has("spotted"), "%s at %s" % [tool, place])
		for question: String in Investigation.QUESTIONS:
			assert_true(r.ask(place, question).has("reply"), "%s at %s" % [question, place])
		var counted: Dictionary = r.use_tool(place, "queue_count")["queue"]
		assert_eq(counted, Region.measures(net, place)["queue"], place)
		if step.kind == SimStep.Kind.WORK:
			continue
		var here := net.open_orders(s).filter(func(o: WorkOrder) -> bool: return o.current_step() == step)
		assert_true(here.size() > 0, "orders wait at " + place)
		assert_eq(counted, {"count": here.size(), "days": 0.0}, place)
