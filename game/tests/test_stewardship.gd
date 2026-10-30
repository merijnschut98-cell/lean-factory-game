extends TestCase
## Rewards and costs over time that follow the three principles (Merijn,
## 2026-10-15; audit §2.4.1): a fix that holds pays back (the
## borgingsdividend, R2, R6), overloading a team with an experiment costs its
## trust (R3), and Henk's deadline is met once the respectful fix is in place
## (R5).


func _log(cms: Array = RulesFixture.countermeasures()) -> Missions:
	var defs: Array[MissionDef] = []
	for d: Dictionary in RulesFixture.missions():
		defs.append(MissionDef.from_dict(d))
	var log := Missions.new(RulesFixture.region(50000, 5, RulesFixture.problems(), cms), defs, RulesFixture.coach())
	log.accept("walk_connections")
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()
	return log


func _solve(log: Missions, cm: String = "standard_designs") -> void:
	var r := log.region
	log.accept("fix_design")
	r.use_tool("connections.design", "time_study")
	# Capacity: a planned number, so the Check passes however busy the test makes the team.
	assert_eq(r.submit_a3("custom_design", RulesFixture.a3(r, "custom_design", "overprocessing", cm, ["custom_design:0"], "capacity")), "")
	r.advance_days(Region.CHECK_DAYS)
	log.update()
	assert_true(r.check("custom_design")["passed"])
	r.act("custom_design", true)
	log.update()


func _events(log: Missions, type: String) -> Array:
	return log.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == type)


func test_a_fix_that_holds_pays_back_at_90_and_180_days() -> void:
	var log := _log()
	_solve(log)
	var r := log.region
	r.plan_routine("connections.design")  # held as it is
	log.drain_events()
	var budget := r.profile.budget
	r.advance_days(Stewardship.DIVIDEND_DAYS[0])
	log.update()
	var paid := _events(log, "dividend")
	assert_eq(paid.size(), 1)
	assert_eq(paid[0]["problem"], "custom_design")
	# The routine's team time costs no euros; the held fix's weekly savings come on top.
	var savings := r.weekly_savings() * Stewardship.DIVIDEND_DAYS[0] / 7.0
	assert_near(r.profile.budget, budget + Stewardship.DIVIDEND + savings, 2.0)
	var reputation := r.reputation.value
	r.advance_days(Stewardship.DIVIDEND_DAYS[1] - Stewardship.DIVIDEND_DAYS[0])
	log.update()
	assert_eq(_events(log, "dividend").size(), 1)
	assert_eq(r.reputation.value, reputation + Reputation.HELD_FIX, "held half a year: the MT notices")
	r.advance_days(200)
	log.update()
	assert_eq(_events(log, "dividend"), [], "once per stage")


func test_a_fix_that_faded_pays_nothing() -> void:
	var log := _log()
	_solve(log)
	var r := log.region
	r.state["custom_design"].wear = 0.6  # health 0.66: slipping
	r.state["custom_design"].neglect = 0.0
	var budget := r.profile.budget
	r.advance_days(Stewardship.DIVIDEND_DAYS[0])
	log.update()
	assert_eq(_events(log, "dividend"), [])
	assert_true(r.profile.budget <= budget)


## Burning people out costs trust: an experiment that keeps its team above
## 95 % busy for its fortnight costs that team's trust; a light one does not.
func test_overloading_a_team_with_an_experiment_costs_its_trust() -> void:
	var cms := RulesFixture.countermeasures()
	cms[0]["team_hours"] = {"prep": 120}  # most of two people's fortnight
	var log := _log(cms)
	log.region.net.set_effects("test:busy", [NetFixture.effect("connections", "demand", 4.0)])  # a full week
	log.region.advance_days(30)  # the work reaches Werkvoorbereiding
	log.region.change_trust("prep", 1)
	_solve(log)
	assert_eq(log.region.trust["prep"], 0, "one point")
	var light := _log()
	light.region.change_trust("prep", 1)
	_solve(light)
	assert_eq(light.region.trust["prep"], 1)


func test_overload_is_reported() -> void:
	var cms := RulesFixture.countermeasures()
	cms[0]["team_hours"] = {"prep": 120}
	var log := _log(cms)
	var r := log.region
	r.net.set_effects("test:busy", [NetFixture.effect("connections", "demand", 4.0)])
	r.advance_days(30)  # the work reaches Werkvoorbereiding
	log.accept("fix_design")
	r.use_tool("connections.design", "time_study")
	r.submit_a3("custom_design", RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs", ["custom_design:0"], "lead_time"))
	r.advance_days(Region.CHECK_DAYS)
	log.update()
	var overload := _events(log, "overload")
	assert_eq(overload.size(), 1)
	assert_eq([overload[0]["team"], overload[0]["problem"]], ["prep", "custom_design"])
	assert_true(overload[0]["load"] > Stewardship.OVERLOAD)


## R5 (QA #19): Henk's deadline is met once the A3 is in: the respectful fix
## takes longer to land, and the Check still judges it.
func test_a_deadline_is_met_once_the_fix_is_in_place() -> void:
	var log := _log()
	var r := log.region
	log.accept("henk")
	r.use_tool("connections.intake", "documents")
	assert_eq(r.submit_a3("incomplete_application",
		RulesFixture.a3(r, "incomplete_application", "defects", "poka_yoke_form", ["incomplete_application:0"], "first_time_right")), "")
	r.advance_days(11)
	log.update()
	assert_false(log.failed("henk"), "the transfer has started")
	assert_true(r.countermeasures["poka_yoke_form"] in r.available_countermeasures(), "the door stays open")
	var restored := _log()
	restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict())))
	restored.region.advance_days(30)
	restored.update()
	assert_false(restored.failed("henk"), "kept after a load")


## The A3 can show what a countermeasure costs over a year: one that fades
## must be done again (audit R1, an estimate labelled as one).
func test_the_lifecycle_cost_counts_the_redos() -> void:
	var r := RulesFixture.region()
	assert_eq(Stewardship.year_cost(r.countermeasures["poka_yoke_form"]), 5000, "built in: paid once")
	assert_eq(Stewardship.year_cost(r.countermeasures["delegated_approval"]), 2000 + 2000 * 365 / 20)
