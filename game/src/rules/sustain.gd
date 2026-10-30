class_name Sustain
## Improvements must be sustained, or they decay, and stagnation is regression
## (CLAUDE.md §2; docs/superpowers/specs/2026-10-15-sustain-and-drift-design.md).
## Pure numbers: the Region keeps the state and applies the effects.
##
## A resolved fix wears faster the longer nothing is done about it (neglect:
## days since the Act, the last audit or the end of a routine): with a
## constant life L, wear = (neglect / L)², health = 0.5^wear, and at wear 1
## (health one half, after L days of neglect) it recurs. The stronger the
## sustaining habits S, the longer L. A planned routine at the fix's step holds
## a standardised fix: no wear while it runs (Merijn, 2026-10-15).
## Drift sets a region back while it stops improving.

## The sustaining mechanisms and their share of S (they add up to 1).
## ESTIMATE: standard work is the main habit (Merijn, 2026-10-15); a visual
## board on the stream and KPIs the team steers by complete a daily
## management system.
const WEIGHTS := {"standard_work": 0.6, "visual_management": 0.2, "kpis": 0.2}
## How much S stretches a fix's life at most: L = base / (1 − 0.9·S), so even
## a fix held by every habit wears when neglected, ten times slower.
const SLOWDOWN := 0.9
## How the person whose work the fix changes stands behind it (People.buy_in;
## the dialog spec §4.2, approved by Merijn): their commitment keeps it alive
## longer, compliance (pressure, or acting without asking them) shorter.
## ESTIMATES of the direction found by Herscovitch & Meyer (2002) and Kotter &
## Schlesinger (1979), not measured values.
const BUY_IN := {"commitment": 1.25, "none": 1.0, "compliance": 0.6}
## The base of a fix that used to stay for good (decay_days null: built into a
## system or a contract). ESTIMATE: workarounds creep in over about a year (a
## form field gets an "n.v.t." option, a contract clause stops being checked).
const STRUCTURAL_DAYS := 365.0
## Health below which the slide is announced (event `slipping`).
const SLIPPING_HEALTH := 0.75
## A gemba audit of the standard at a place. ESTIMATE: a layered process audit
## takes 10–30 minutes per area; with the walk and the conversation an hour.
const AUDIT_MINUTES := 60
## A planned routine (leader standard work: a weekly layered audit and a
## short check with the team) costs the team this much time a week. ESTIMATE:
## a 30-minute audit by the team lead plus a short stand-up with the team.
const ROUTINE_HOURS_PER_WEEK := 2.0

## Drift: nothing for this many days without a resolved improvement (ESTIMATE:
## a month is a normal pace), then full after DRIFT_RAMP_DAYS more.
const DRIFT_GRACE_DAYS := 28.0
const DRIFT_RAMP_DAYS := 365.0
## At full drift. ESTIMATES (no clean public yearly figure):
## demand: the energy transition keeps adding connection and capacity
## requests (Netbeheer Nederland: ~107,000 small connections realised in 2024
## at a flat pace while the average wait rose, 40 → 44 weeks in H1 2025); 6 %.
## availability: ~10 %/year turnover × ~4 months until a replacement is
## productive ≈ 3 % of capacity (the technician shortage).
## ftr: knowledge leaving and workarounds creeping in; 2 points.
const DRIFT_DEMAND := 0.06
const DRIFT_DEMAND_STREAMS: Array[String] = ["connections", "congestion"]
const DRIFT_AVAILABILITY := 0.03
const DRIFT_FTR := 0.02


## The days a fix lasts with no sustaining habit: its decay_days, or
## STRUCTURAL_DAYS for one that used to stay.
static func base_days(cm: CountermeasureDef) -> float:
	return float(cm.decay_days) if cm.decay_days > 0 else STRUCTURAL_DAYS


## The days of neglect a fix lasts at sustain strength `strength`.
static func life_days(base: float, strength: float) -> float:
	return base / (1.0 - SLOWDOWN * clampf(strength, 0.0, 1.0))


## The wear `days` more of neglect add, after `neglect` days, at `life` days:
## ((neglect + days)² − neglect²) / life², so the longer the neglect, the faster.
static func wear_over(neglect: float, days: float, life: float) -> float:
	return (2.0 * neglect + days) * days / (life * life)


## Days of neglect left before the fix recurs, at `life` days.
static func days_left(wear: float, life: float) -> float:
	return maxf(0.0, life * (1.0 - sqrt(wear)))


static func health(wear: float) -> float:
	return pow(0.5, wear)


## What a resolved fix does at `fix_health`, by effect source: the
## countermeasure at eff × health, and the problem back at 1 − health, its
## levers excepted (a rule is in place or not: it comes back with the problem).
static func eroded_effects(problem: ProblemDef, cm: CountermeasureDef, eff: float, fix_health: float) -> Dictionary[String, Array]:
	var unlevered := problem.effects.filter(func(e: Dictionary) -> bool:
		return SimModifiers.PROPERTIES[e["property"]]["op"] != SimModifiers.Op.SET)
	return {
		"problem:" + problem.id: SimModifiers.scaled(unlevered, 1.0 - fix_health),
		"cm:" + problem.id: SimModifiers.scaled(cm.effects, eff * fix_health),
	}


## The drift level 0..1 after `stagnant_days` without a resolved improvement.
static func drift_level(stagnant_days: float) -> float:
	return clampf((stagnant_days - DRIFT_GRACE_DAYS) / DRIFT_RAMP_DAYS, 0.0, 1.0)


## The drift's effects on `net` at `level`: more demand on the streams the
## energy transition feeds, less available time for every team, a little less
## first-time-right at every work step.
static func drift_effects(net: Network, level: float) -> Array:
	var effects := []
	if level <= 0.0:
		return effects
	for stream_id in DRIFT_DEMAND_STREAMS:
		if net.stream(stream_id) != null:
			effects.append({"target": stream_id, "property": "demand", "value": 1.0 + DRIFT_DEMAND * level})
	for pool_id: String in net.pools:
		effects.append({"target": pool_id, "property": "availability", "value": -DRIFT_AVAILABILITY * level})
	for s: ValueStream in net.streams:
		for step in s.steps:
			if step.kind == SimStep.Kind.WORK:
				effects.append({"target": s.id + "." + step.id, "property": "ftr", "value": -DRIFT_FTR * level})
	return effects
