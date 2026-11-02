class_name Stewardship
extends RefCounted
## Rewards and costs over time that follow the three deep-thinking principles
## (CLAUDE.md §2; Merijn's answers, 2026-10-15; audit §2.4.1):
## - long term over short term: a fix that still holds pays back after 90 and
##   180 days (the borgingsdividend, R2), and the MT notices at 180 (R6), so
##   standardising pays for itself over time, not only in the text;
## - respect for people: an experiment that plans its team above 95 % of its
##   time for the fortnight costs that team's trust (R3: burning people out
##   costs);
## - and the A3 can show a countermeasure's cost over a year (R1).
## Missions owns it (it reads the Region and pays through it). All numbers are
## ESTIMATES (audit §2.4.1).

const DIVIDEND := 1500
const DIVIDEND_DAYS := [90, 180]
const HELD_HEALTH := Reputation.HELD_HEALTH
const OVERLOAD := 0.95

## Problem → when its fix's Act was noted (minutes), and how many dividends it
## had a look at (0..2).
var act_at: Dictionary[String, int] = {}
var looked: Dictionary[String, int] = {}
## Experiments already weighed for overload: problem → its check_at.
var weighed: Dictionary[String, int] = {}


## A new Act: the fix's dividend clock starts.
func noted(problem_id: String, time: int) -> void:
	act_at[problem_id] = time
	looked[problem_id] = 0


## Pay the dividends that are due and weigh finished experiments for overload.
## Returns the events.
func update(r: Region) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for problem_id: String in act_at.keys():
		if r.state[problem_id].phase != ProblemState.Phase.RESOLVED:
			act_at.erase(problem_id)
			looked.erase(problem_id)
			continue
		var age := (r.net.time - act_at[problem_id]) / float(SimCalendar.MINUTES_PER_DAY)
		while looked[problem_id] < DIVIDEND_DAYS.size() and age >= DIVIDEND_DAYS[looked[problem_id]]:
			looked[problem_id] += 1
			if r.health(problem_id) < HELD_HEALTH:
				continue
			r.grant(0, DIVIDEND)
			events.append({"type": "dividend", "problem": problem_id, "budget": DIVIDEND, "days": DIVIDEND_DAYS[looked[problem_id] - 1]})
			if looked[problem_id] == DIVIDEND_DAYS.size():
				r.earn_reputation(Reputation.HELD_FIX, "held")
	for st: ProblemState in r.state.values():
		if st.phase == ProblemState.Phase.CHECK_READY and weighed.get(st.id, -1) != st.check_at and not r.practice.has(st.id):
			weighed[st.id] = st.check_at
			events.append_array(_weigh(r, st))
	return events


## The teams an experiment drew on lose a point of trust when their work,
## with the experiment's hours taken from it, was planned above OVERLOAD of
## their time (Capacity, while the experiment's `do:` effects still hold:
## Missions weighs it as soon as the Check is due).
func _weigh(r: Region, st: ProblemState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cm: CountermeasureDef = r.countermeasures.get(st.a3.get("cm", ""))
	if cm == null:
		return out
	var pools: Dictionary = Capacity.analyse(r.net)["pools"]
	for team in cm.team_hours:
		var load: float = pools.get(team, {}).get("utilisation", 0.0)
		if load > OVERLOAD:
			r.change_trust(team, -1)
			out.append({"type": "overload", "team": team, "problem": st.id, "load": load})
	return out


## What a countermeasure costs over a year: one that fades has to be done
## again every decay_days (audit R1; an estimate, shown as one).
static func year_cost(cm: CountermeasureDef) -> int:
	return cm.budget if cm.decay_days <= 0 else cm.budget + cm.budget * 365 / cm.decay_days


func to_dict() -> Dictionary:
	return {"act_at": act_at.duplicate(), "looked": looked.duplicate(), "weighed": weighed.duplicate()}


func load_dict(d: Dictionary) -> void:
	for key in ["act_at", "looked", "weighed"]:
		var into: Dictionary = get(key)
		into.clear()
		var saved := JsonFile.dict_or_empty(d.get(key))
		for id: Variant in saved:
			into[str(id)] = int(saved[id])
