class_name Pdca
## PDCA rules: how well a countermeasure works, and the five-dimension score.
## Notes are codes the UI words in Dutch.

## A countermeasure must reach this effectiveness to pass Check.
const CHECK_PASS := 0.5
const MISMATCH_EFF := 0.1
const NONE_EFF := 0.05
const MAX_SCORE := 25
const BUDGET_BASE := {"low": 5000, "medium": 8000, "high": 12000, "critical": 18000}


## {eff, level, fit}. A countermeasure that does not touch the cause is a
## mismatch. A fitting one works as well as its fit allows (several
## countermeasures can help one problem, some more than others) and as the
## region's maturity allows: the right idea too early only half-works.
static func effectiveness(problem: ProblemDef, cm: CountermeasureDef, maturity: int) -> Dictionary:
	var fit: float = problem.countermeasures.get(cm.id, 0.0)
	if fit <= 0.0:
		return {"eff": MISMATCH_EFF, "level": "mismatch", "fit": 0.0}
	var gap := cm.tier - maturity
	if gap > 2:
		return {"eff": NONE_EFF, "level": "none", "fit": fit}
	var level: String = ["full", "reduced", "minimal"][maxi(0, gap)]
	return {"eff": cm.multipliers[level] * fit, "level": level, "fit": fit}


## The score of one solved problem. Inputs:
## key_found, key_total, scouted (walked another step of the stream), blamed,
## cause_correct, key_linked, herrings_linked, eff, failed_checks,
## prediction_right, standardised, waste_right, capacity_gain (relative change
## in the stream's capacity), at_constraint (the problem's team was the
## stream's constraint).
## Returns {plan, root_cause, countermeasure, check_act, impact, total, notes}.
static func score(i: Dictionary) -> Dictionary:
	var notes: Array[String] = []
	var coverage: float = i["key_found"] / float(i["key_total"]) if i["key_total"] > 0 else 1.0
	var plan := _clamp15(1 + coverage * 3 + (1 if i["scouted"] else 0) - (1 if i["blamed"] else 0))
	if coverage < 1.0:
		notes.append("coverage")
	if not i["scouted"]:
		notes.append("not_scouted")
	if i["blamed"]:
		notes.append("blamed")

	var root_cause := 1
	if i["cause_correct"]:
		root_cause = _clamp15(2 + mini(2, i["key_linked"]) + (1 if i["waste_right"] else 0) - i["herrings_linked"])
		if i["herrings_linked"] > 0:
			notes.append("herrings_linked")
		elif i["key_linked"] == 0:
			notes.append("thin_evidence")
	else:
		notes.append("cause_wrong")
	if not i["waste_right"]:
		notes.append("waste_wrong")

	var base := 5 if i["eff"] >= 0.7 else (4 if i["eff"] >= CHECK_PASS else 2)
	var countermeasure := _clamp15(base - i["failed_checks"])
	if i["failed_checks"] > 0:
		notes.append("failed_checks")

	var check_act := _clamp15(2 + (1 if i["prediction_right"] else 0) + (2 if i["standardised"] else 0))
	if not i["prediction_right"]:
		notes.append("prediction_wrong")
	if not i["standardised"]:
		notes.append("not_standardised")

	var gain: float = i["capacity_gain"]
	var impact := 5 if gain >= 0.03 else (4 if gain >= 0.01 else (2 if gain > 0.002 else 1))
	if impact <= 2:
		notes.append("impact_constraint_small" if i["at_constraint"] else "impact_not_constraint")
	else:
		notes.append("impact_good")

	return {
		"plan": plan, "root_cause": root_cause, "countermeasure": countermeasure, "check_act": check_act,
		"impact": impact, "total": plan + root_cause + countermeasure + check_act + impact, "notes": notes,
	}


## Improvement budget management grants for a result.
static func budget_for(s: Dictionary, severity: String) -> int:
	return roundi(BUDGET_BASE[severity] * s["total"] / float(MAX_SCORE))


static func xp_for(s: Dictionary, tier: int) -> int:
	return s["total"] * 10 * tier


static func _clamp15(v: float) -> int:
	return clampi(roundi(v), 1, 5)
