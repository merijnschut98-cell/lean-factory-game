extends TestCase
## Countermeasure effectiveness, the five-dimension score, progression.


func _best() -> Dictionary:
	return {
		"key_found": 2, "key_total": 2, "scouted": true, "blamed": false, "cause_correct": true, "key_linked": 2,
		"herrings_linked": 0, "eff": 0.8, "failed_checks": 0, "prediction_right": true, "standardised": true,
		"waste_right": true, "capacity_gain": 0.05, "at_constraint": true,
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


func test_scores_range_from_6_to_25() -> void:
	var best := Pdca.score(_best())
	assert_eq(best["total"], 25)
	var worst := Pdca.score({
		"key_found": 0, "key_total": 3, "scouted": false, "blamed": true, "cause_correct": false, "key_linked": 0,
		"herrings_linked": 4, "eff": 0.1, "failed_checks": 3, "prediction_right": false, "standardised": false,
		"waste_right": false, "capacity_gain": 0.0, "at_constraint": false,
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


func test_rewards() -> void:
	var best := Pdca.score(_best())
	assert_eq(Pdca.budget_for(best, "high"), 12000)
	assert_eq(Pdca.xp_for(best, 2), 500)


func test_belts() -> void:
	assert_eq(Progression.belt_index(0), 0)
	assert_eq(Progression.belt_index(1200), 1)
	assert_eq(Progression.belt_index(99999), 4)
	assert_near(Progression.belt_progress(600), 0.5, 1e-9)
	assert_eq(Progression.belt_progress(99999), 1.0)
