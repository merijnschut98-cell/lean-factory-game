class_name Pdca
## PDCA rules: how well a countermeasure works, and the five-dimension score.
## Notes are codes the UI words in Dutch.

## A countermeasure must reach this effectiveness to work (its own effects
## start); the Check then asks the numbers whether it moved the predicted KPI.
const CHECK_PASS := 0.5
## A countermeasure that does not touch the cause leaves the problem as it is.
const MISMATCH_EFF := 0.0
const NONE_EFF := 0.05
## The Check passes when the predicted KPI is better with the fix than
## without it by more than this (relative). ESTIMATE, from a probe
## (2026-10-15, real network, 6 seeds, the CheckForecast window): the two runs
## share their random sequences, but once the fix changes who works on what
## they drift apart. Every best fix moved its problem's KPI by more than this
## on every seed; on KPIs a fix does not touch the drift is mostly smaller for
## capacity, on time and lead time, but up to ±10 % for first time right and
## the age of open work, so a lucky guess there can pass (the score's
## prediction_wrong note still counts it).
const CHECK_NOISE := 0.02
## KPIs where lower is better (the rest: higher), by the Check's names
## (Investigation.KPIS) and the streams' own (ValueStream.kpis).
const LOWER_IS_BETTER: Array[String] = ["lead_time", "wip_age", "lead_days_p50"]
## The throughput's names: which way it is better is its stream's.
const THROUGHPUT: Array[String] = ["throughput", "throughput_per_week"]
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


## What a treated problem does to the simulation, by effect source: the
## problem at the strength the countermeasure leaves (1 − eff), and the
## countermeasure's own effects at eff once that passes the Check. `cm` null
## means untreated.
static func treated_effects(problem: ProblemDef, cm: CountermeasureDef, eff: float) -> Dictionary[String, Array]:
	var out: Dictionary[String, Array] = {"problem:" + problem.id: SimModifiers.scaled(problem.effects, 1.0 - eff)}
	if cm != null and eff >= CHECK_PASS:
		out["cm:" + problem.id] = SimModifiers.scaled(cm.effects, eff)
	return out


## 1 when a higher `kpi` is better, −1 when a lower one is: days lower, shares and
## capacity higher, and the throughput as its stream says (`throughput`:
## ValueStream.throughput_direction; −1 for outages, fewer a week is better). The one
## place that says which way a number is better.
static func direction(kpi: String, throughput := 1) -> int:
	if kpi in THROUGHPUT:
		return throughput
	return -1 if kpi in LOWER_IS_BETTER else 1


## The relative gain of `kpi` from `without` to `with_fix` (Region.measures
## or snapshots) on a stream whose throughput direction is `throughput`:
## positive when better; 0 when there was nothing to compare.
static func kpi_gain(kpi: String, without: Dictionary, with_fix: Dictionary, throughput := 1) -> float:
	var base: float = without[kpi]
	if base == 0.0:
		return 0.0
	return direction(kpi, throughput) * (with_fix[kpi] - base) / base


## The score of one solved problem. Inputs:
## key_found, key_total, scouted (walked another step of the stream), blamed,
## cause_correct, key_linked, herrings_linked, eff, failed_checks,
## prediction_right, standardised, waste_right, capacity_gain (relative change
## in the stream's capacity), at_constraint (the problem's team was the
## stream's constraint), team_step (a team works at the problem's step; a
## wait or a material step has none), lead_time_gain (relative, shorter is
## positive), durable (the fix is built in or standardised).
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

	# Audit R1(c): a fix that lasts (built in, or standardised) scores a point
	# more, so the patient fix outscores the quick one that fades.
	var base := 5 if i["eff"] >= 0.7 else (4 if i["eff"] >= CHECK_PASS else 2)
	var countermeasure := _clamp15(base - i["failed_checks"] + (1 if i["durable"] else 0))
	if i["failed_checks"] > 0:
		notes.append("failed_checks")

	var check_act := _clamp15(2 + (1 if i["prediction_right"] else 0) + (2 if i["standardised"] else 0))
	if not i["prediction_right"]:
		notes.append("prediction_wrong")
	if not i["standardised"]:
		notes.append("not_standardised")

	var impact := _impact(i)
	if impact > 2:
		notes.append("impact_good")
	elif not i["team_step"]:
		notes.append("impact_lead_time_small")
	else:
		notes.append("impact_constraint_small" if i["at_constraint"] else "impact_not_constraint")

	return {
		"plan": plan, "root_cause": root_cause, "countermeasure": countermeasure, "check_act": check_act,
		"impact": impact, "total": plan + root_cause + countermeasure + check_act + impact, "notes": notes,
	}


## Flow impact, 1..5. At a team's step: the stream's capacity (a step that
## is not the bottleneck adds none). At a wait or a material step, which has no
## team and adds no capacity: the lead time it takes out (Little's law).
## ESTIMATE: lead time is noisier than planned capacity, so its bands start
## at the Check's noise.
static func _impact(i: Dictionary) -> int:
	if not i["team_step"]:
		var shorter: float = i["lead_time_gain"]
		return 5 if shorter >= 0.1 else (4 if shorter >= 0.05 else (2 if shorter > CHECK_NOISE else 1))
	var gain: float = i["capacity_gain"]
	return 5 if gain >= 0.03 else (4 if gain >= 0.01 else (2 if gain > 0.002 else 1))


## Improvement budget management grants for a result.
static func budget_for(s: Dictionary, severity: String) -> int:
	return roundi(BUDGET_BASE[severity] * s["total"] / float(MAX_SCORE))


static func xp_for(s: Dictionary, tier: int) -> int:
	return s["total"] * 10 * tier


static func _clamp15(v: float) -> int:
	return clampi(roundi(v), 1, 5)
