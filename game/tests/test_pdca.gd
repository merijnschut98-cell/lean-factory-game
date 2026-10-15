extends TestCase
## Countermeasure effectiveness, the five-dimension score, progression.


func _best() -> Dictionary:
	return {
		"key_found": 2, "key_total": 2, "scouted": true, "blamed": false, "cause_correct": true, "key_linked": 2,
		"herrings_linked": 0, "eff": 0.8, "failed_checks": 0, "prediction_right": true, "standardised": true,
		"waste_right": true, "capacity_gain": 0.05, "at_constraint": true, "team_step": true, "lead_time_gain": 0.0,
	}


func test_effectiveness_by_fit_and_maturity() -> void:
	var p: ProblemDef = RulesFixture.problem_defs()[0]
	var cms := RulesFixture.countermeasure_defs()
	assert_eq(Pdca.effectiveness(p, cms[0], 1), {"eff": 0.9, "level": "full", "fit": 1.0})
	assert_eq(Pdca.effectiveness(p, cms[1], 1)["level"], "mismatch")
	var tier3: ProblemDef = RulesFixture.problem_defs()[2]
	assert_eq(Pdca.effectiveness(tier3, cms[3], 2)["level"], "reduced")
	assert_near(Pdca.effectiveness(tier3, cms[3], 2)["eff"], 0.5, 1e-9)
	assert_eq(Pdca.effectiveness(tier3, cms[3], 1)["level"], "minimal")
	assert_eq(Pdca.effectiveness(tier3, cms[3], 0)["level"], "none")


func test_several_countermeasures_can_work_some_better() -> void:
	var p: ProblemDef = RulesFixture.problem_defs()[0]
	var cms := RulesFixture.countermeasure_defs()
	var standard := Pdca.effectiveness(p, cms[0], 1)
	var delegated := Pdca.effectiveness(p, cms[2], 1)
	assert_eq(delegated["level"], "full", "a real improvement, not a mismatch")
	assert_near(delegated["eff"], 0.9 * 0.6, 1e-9)
	assert_true(delegated["eff"] >= Pdca.CHECK_PASS and standard["eff"] > delegated["eff"])


## A countermeasure that does not touch the cause leaves the problem as it
## is: the Check's "with" and "without" are the same future.
func test_a_mismatch_leaves_the_problem_at_full_strength() -> void:
	var p: ProblemDef = RulesFixture.problem_defs()[0]
	var mismatch: CountermeasureDef = RulesFixture.countermeasure_defs()[1]
	var e := Pdca.effectiveness(p, mismatch, 1)
	assert_eq(e["eff"], 0.0)
	assert_eq(Pdca.treated_effects(p, mismatch, e["eff"]), Pdca.treated_effects(p, null, 0.0))


## The Check's gain of a KPI: relative, positive when better (shorter for
## lead time and the age of open work), 0 when there was nothing to compare.
func test_a_kpi_gain_is_relative_and_positive_when_better() -> void:
	assert_near(Pdca.kpi_gain("lead_time", {"lead_time": 50.0}, {"lead_time": 40.0}), 0.2, 1e-9)
	assert_near(Pdca.kpi_gain("wip_age", {"wip_age": 50.0}, {"wip_age": 60.0}), -0.2, 1e-9)
	assert_near(Pdca.kpi_gain("throughput", {"throughput": 10.0}, {"throughput": 12.0}), 0.2, 1e-9)
	assert_eq(Pdca.kpi_gain("on_time", {"on_time": 0.0}, {"on_time": 0.5}), 0.0)


func test_treated_effects() -> void:
	var p: ProblemDef = RulesFixture.problem_defs()[0]
	var cm: CountermeasureDef = RulesFixture.countermeasure_defs()[0]
	var passed := Pdca.treated_effects(p, cm, 0.8)
	assert_eq(passed.keys(), ["problem:custom_design", "cm:custom_design"])
	assert_near(passed["problem:custom_design"][0]["value"], 1.1, 1e-9, "the problem at strength 1 − 0.8")
	assert_near(passed["cm:custom_design"][0]["value"], 0.84, 1e-9, "the countermeasure at strength 0.8")
	assert_eq(Pdca.treated_effects(p, cm, 0.4).keys(), ["problem:custom_design"], "below the Check, no fix")
	assert_eq(Pdca.treated_effects(p, null, 0.0), {"problem:custom_design": p.effects}, "untreated: at full strength")


func test_scores_range_from_6_to_25() -> void:
	var best := Pdca.score(_best())
	assert_eq(best["total"], 25)
	var worst := Pdca.score({
		"key_found": 0, "key_total": 3, "scouted": false, "blamed": true, "cause_correct": false, "key_linked": 0,
		"herrings_linked": 4, "eff": 0.1, "failed_checks": 3, "prediction_right": false, "standardised": false,
		"waste_right": false, "capacity_gain": 0.0, "at_constraint": false, "team_step": true, "lead_time_gain": 0.0,
	})
	assert_true(worst["total"] <= 6, str(worst["total"]))
	for code in ["coverage", "not_scouted", "blamed", "waste_wrong", "cause_wrong", "failed_checks",
			"prediction_wrong", "not_standardised", "impact_not_constraint"]:
		assert_true(code in worst["notes"], code)


func test_flow_impact_explains_itself() -> void:
	var i := _best()
	i["capacity_gain"] = 0.0
	assert_true("impact_constraint_small" in Pdca.score(i)["notes"], "on the constraint, but little gain")
	i["at_constraint"] = false
	assert_true("impact_not_constraint" in Pdca.score(i)["notes"])
	assert_eq(Pdca.score(i)["impact"], 1)
	assert_true("impact_good" in Pdca.score(_best())["notes"])


## A wait (a permit, a delivery, a close-out) has no team and adds no
## capacity: its impact is the shorter lead time, never "not the bottleneck".
func test_a_wait_scores_impact_on_lead_time() -> void:
	var i := _best()
	i.merge({"team_step": false, "at_constraint": false, "capacity_gain": 0.0, "lead_time_gain": 0.12}, true)
	var s := Pdca.score(i)
	assert_eq(s["impact"], 5)
	assert_true("impact_good" in s["notes"])
	i["lead_time_gain"] = 0.0
	s = Pdca.score(i)
	assert_eq(s["impact"], 1)
	assert_true("impact_lead_time_small" in s["notes"])
	assert_false("impact_not_constraint" in s["notes"])


func test_rewards() -> void:
	var best := Pdca.score(_best())
	assert_eq(Pdca.budget_for(best, "high"), 12000)
	assert_eq(Pdca.xp_for(best, 2), 500)


func test_belts() -> void:
	assert_eq(Progression.belt_index(0), 0)
	assert_eq(Progression.belt_index(2000), 1)
	assert_eq(Progression.belt_index(999999), 4)
	assert_near(Progression.belt_progress(1000), 0.5, 1e-9)
	assert_eq(Progression.belt_progress(999999), 1.0)
