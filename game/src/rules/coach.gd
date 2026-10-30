class_name Coach
extends RefCounted
## The senior manager who coaches the main mission (CLAUDE.md §2): he mostly answers with a
## question (Toyota Kata), shares an insight now and then, and never coaches a side mission.
## Moved out of Missions (TD-3); Missions keeps what is saved (`heard`, each mission's asks
## and said) and the coach content (`coach`), and this reads and writes them through `missions`.

## Every third question at the same stage, the coach shares an insight.
const INSIGHT_EVERY := 3
## The coach does not repeat a line the player heard in the last this many
## asks (audit §3A.1: the same opener came back in 14 missions).
const NO_REPEAT := 6
## A fix chosen to fade within this many days, while a lasting one fits as
## well, gets the coach's long-term question (audit §3A.2, an estimate).
const FADING_DAYS := 45
const P := ProblemState.Phase

## Weak: Missions owns its Coach, and a strong reference back would be a cycle nothing frees.
var missions: Missions:
	get:
		return _missions.get_ref()
var _missions: WeakRef


func _init(of_missions: Missions) -> void:
	_missions = weakref(of_missions)


## Ask the coach. With no mission named, about the main mission (or, before
## the campaign, the training day). Returns {kind: question | insight |
## no_main | not_main, text?, stage?}.
func ask(mission_id: String = "") -> Dictionary:
	if not mission_id.is_empty() and missions.defs.has(mission_id) and missions.defs[mission_id].kind in ["side", "milestone"]:
		return {"kind": "not_main"}
	var coached := missions.active("main")
	coached.append_array(missions.active("training"))
	if coached.is_empty():
		return {"kind": "no_main"}
	var m := coached[0]
	var stage := stage_of(m)
	var asks: Dictionary = missions.progress[m.id]["asks"]
	asks[stage] = int(asks.get(stage, 0)) + 1
	var insights: Array = m.insights.get(stage, [])
	var nth_insight: int = asks[stage] / INSIGHT_EVERY - 1
	if asks[stage] % INSIGHT_EVERY == 0 and nth_insight < insights.size():
		return {"kind": "insight", "text": insights[nth_insight], "stage": stage}
	return {"kind": "question", "text": question(m, stage, asks[stage]), "stage": stage}


## The next question: a conditional one that applies (once per mission),
## the mission's own, then the general bank starting at a place of the
## mission's own; the first the player did not hear in the last NO_REPEAT
## asks (all heard: in turn).
func question(m: MissionDef, stage: String, nth: int) -> String:
	var said: Dictionary = missions.progress[m.id].get_or_add("said", {})
	var content := missions.coach
	for condition: String in conditions(m, stage):
		if not said.has(condition) and content.get("conditional", {}).has(condition):
			said[condition] = true
			return _say(content["conditional"][condition])
	var read := CoachNumbers.question(missions.region, m, stage, said, content)
	if not read.is_empty():
		return _say(read)
	var candidates: Array = m.questions.get(stage, []).duplicate()
	var bank: Array = content["stages"].get(stage, [])
	if not bank.is_empty():
		var start := absi(m.id.hash()) % bank.size()
		candidates.append_array(bank.slice(start) + bank.slice(0, start))
	if candidates.is_empty():
		return ""
	for line: String in candidates:
		if not line in missions.heard:
			return _say(line)
	return _say(candidates[(nth - 1) % candidates.size()])


func _say(line: String) -> String:
	var heard := missions.heard
	heard.erase(line)
	heard.append(line)
	if heard.size() > NO_REPEAT:
		heard.remove_at(0)
	return line


## Conditions the coach asks about now: a blaming question while the problem
## was open (respect for people), and a fix chosen to fade soon while a
## lasting one fits as well (long term over short term).
func conditions(m: MissionDef, stage: String) -> Array[String]:
	var out: Array[String] = []
	var st: ProblemState = missions.region.state.get(m.goal_problem)
	if st == null:
		return out
	if st.blamed:
		out.append("blamed")
	if stage == "experiment" and fading_fix(m):
		out.append("fading_fix")
	return out


## Whether `m`'s fix was chosen to fade within FADING_DAYS while a lasting one fit as
## well (the short term over the long term).
func fading_fix(m: MissionDef) -> bool:
	var region := missions.region
	var st: ProblemState = region.state.get(m.goal_problem)
	var cm: CountermeasureDef = region.countermeasures.get(st.a3.get("cm", "")) if st != null else null
	if cm == null or cm.decay_days <= 0 or cm.decay_days > FADING_DAYS:
		return false
	var p: ProblemDef = region.problems[m.goal_problem]
	var chosen_fit: float = p.countermeasures.get(cm.id, 0.0)
	return p.countermeasures.keys().any(func(id: String) -> bool:
		var other: CountermeasureDef = region.countermeasures.get(id)
		return other != null and (other.decay_days < 0 or other.decay_days > FADING_DAYS) \
			and p.countermeasures[id] >= chosen_fit)


## Where the player stands, as the coach sees it: go_see (find the problem
## at the gemba), understand (grasp the actual condition and the cause),
## experiment (an A3 running), reflect (checked or done).
func stage_of(m: MissionDef) -> String:
	if m.goal_problem.is_empty():
		return "go_see"
	match missions.region.state[m.goal_problem].phase:
		P.SPOTTED:
			return "understand"
		P.DOING, P.CHECK_READY:
			return "experiment"
		P.CHECKED, P.RESOLVED:
			return "reflect"
	return "understand" if missions.region.key_clues_found(m.goal_problem) > 0 else "go_see"
