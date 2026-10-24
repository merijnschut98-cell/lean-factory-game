class_name Repairs
extends RefCounted
## Repair side quests (catalogue §2.15, C20): a poor fix (Missions' fact
## `poor_fix:<problem>`) brings, some weeks later, a small side mission to
## swap it for a better countermeasure, but only once the weakness shows in
## the problem's own KPI: the player meets a measurable symptom, never a
## verdict. Doing it records `repaired:<problem>`, which opens the options
## that need the better fix; skipping it is allowed (CLAUDE.md §2: you can
## pivot, and another route back always remains).
##
## Missions owns the quests (built, like check-ins, not content); this keeps
## when each poor fix is looked at and how its weakness is measured.

const PREFIX := "repair_"
## ESTIMATES (catalogue §2.15): a poor fix is looked at six weeks after its
## Act, then weekly; it counts as showing when the problem's KPI is this much
## behind the best countermeasure's, forecast four weeks ahead.
const AFTER_DAYS := 42
const RETRY_DAYS := 7
const KPI_GAP := 0.05
const FORECAST_DAYS := 28
## A small reward, a side mission's (the rework's own Act pays the score).
const XP := 150

## Poor fix → when to look at it next (minutes).
var due: Dictionary[String, int] = {}
## How far the KPI is behind the best fix (relative, > 0 is behind); a seam
## for tests, kpi_gap otherwise.
var gap_of: Callable = kpi_gap


## Whether a poor fix's weakness shows now; when it does not, look again in
## RETRY_DAYS. Call only when `due` says so.
func shows(r: Region, problem_id: String) -> bool:
	if gap_of.call(r, problem_id) >= KPI_GAP:
		due.erase(problem_id)
		return true
	due[problem_id] = r.net.time + SimCalendar.days(RETRY_DAYS)
	return false


## How far the problem's KPI with today's fix is behind the problem's
## best-fitting countermeasure still open (a missed deadline may have closed the
## best for good), FORECAST_DAYS ahead on two copies of the network (the same
## random sequences, as KpiBoard.forecast): relative, > 0 when today's fix is
## behind. 0 when the best open fix is already in place or a copy fails.
static func kpi_gap(r: Region, problem_id: String) -> float:
	var p: ProblemDef = r.problems[problem_id]
	var best_id := ""
	for cm_id: String in p.countermeasures:
		if r.closed.has(cm_id):
			continue
		if best_id.is_empty() or p.countermeasures[cm_id] > p.countermeasures[best_id]:
			best_id = cm_id
	if best_id == r.state[problem_id].a3.get("cm", "") or not r.countermeasures.has(best_id):
		return 0.0
	var now := NetworkState.copy(r.net)
	var better := NetworkState.copy(r.net)
	if not now.error.is_empty() or not better.error.is_empty():
		return 0.0
	var best: CountermeasureDef = r.countermeasures[best_id]
	better.clear_effects("problem:" + problem_id)
	better.set_effects("cm:" + problem_id, SimModifiers.scaled(best.effects, Pdca.effectiveness(p, best, r.maturity())["eff"]))
	now.advance_days(FORECAST_DAYS)
	better.advance_days(FORECAST_DAYS)
	var today: float = Region.measures(now, p.step)[p.kpi]
	var possible: float = Region.measures(better, p.step)[p.kpi]
	if is_zero_approx(possible):
		return 0.0
	return behind(p.kpi, today, possible, r.net.stream_of(p.step).throughput_direction)


## How far `today` is behind `possible` on `kpi` (relative, > 0 when behind), on a
## stream whose throughput direction is `throughput` (more outages than possible is behind).
static func behind(kpi: String, today: float, possible: float, throughput := 1) -> float:
	return Pdca.direction(kpi, throughput) * (possible - today) / absf(possible)


## The repair quest for a poor fix (Dutch game text).
static func def_for(p: ProblemDef) -> MissionDef:
	return MissionDef.from_dict({
		"id": PREFIX + p.id, "name": "Herstel: " + p.name, "kind": "side", "tier": p.tier,
		"briefing": "De maatregel bij \"%s\" werkt, maar de cijfers blijven achter bij wat mogelijk is. Kijk er opnieuw naar: schrijf een korte A3 met een andere tegenmaatregel. De huidige blijft draaien tot de nieuwe zich in de Check bewijst." % p.name,
		"debrief": "De nieuwe maatregel doet wat de oude beloofde. Terugkijken op je eigen oplossing is ook verbeteren.",
		"goal": {"type": "rework_fix", "problem": p.id}, "rewards": {"xp": XP, "budget": 0},
	})


func to_dict() -> Dictionary:
	return due.duplicate()


func load_dict(d: Dictionary) -> void:
	due.clear()
	for id: Variant in d:
		due[str(id)] = int(d[id])
