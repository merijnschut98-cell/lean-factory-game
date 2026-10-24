class_name CoachNumbers
extends RefCounted
## The coach reads the numbers (phase-2 design §3.6): Ruud names the main mission's KPI as
## it is now on its stream ("De doorlooptijd is nu 54 dagen") before a question, once at
## go_see and once at reflect, and during an experiment he asks the Kata five in order
## (Rother: target, actual condition, obstacles, next step, when we go and see), once an
## experiment, the first after the number. Questions, never the answer. The lines are
## content (missions.yaml coach.numbers and coach.kata); Missions asks here first.

## The stages the number is read at (coach.numbers has a question for each).
const NUMBER_STAGES: Array[String] = ["go_see", "reflect"]


## The question to ask now, or "" (then the coach's other questions). `said` is the
## mission's memory of what the coach asked (Missions progress "said"; saved with it).
static func question(region: Region, m: MissionDef, stage: String, said: Dictionary, coach: Dictionary) -> String:
	var numbers := JsonFile.dict_or_empty(coach.get("numbers"))
	var clauses := JsonFile.dict_or_empty(numbers.get("kpi_now"))
	if stage == "experiment":
		return _kata(region, m, said, coach["kata"] if coach.get("kata") is Array else [], clauses)
	var key := "numbers:" + stage
	if not stage in NUMBER_STAGES or said.has(key) or not numbers.get(stage) is String:
		return ""
	var now := kpi_now(region, m, clauses)
	if now.is_empty():
		return ""
	said[key] = true
	return _after(now, numbers[stage])


## The next of the Kata five for this experiment (its Check time tells one experiment from
## the next), the first after the KPI now; "" once all five were asked.
static func _kata(region: Region, m: MissionDef, said: Dictionary, kata: Array, clauses: Dictionary) -> String:
	var st: ProblemState = region.state.get(m.goal_problem)
	var experiment := st.check_at if st != null else -1
	if int(said.get("kata_at", -2)) != experiment:
		said["kata_at"] = experiment
		said["kata"] = 0
	var n := int(said["kata"])
	if n >= kata.size():
		return ""
	said["kata"] = n + 1
	return _after(kpi_now(region, m, clauses) if n == 0 else "", str(kata[n]))


## The mission's KPI as it is now on its problem's stream, in Ruud's words (`clauses`: KPI
## → a line with {value}), or "" when the mission has no problem or the stream has no
## number to read yet (nothing finished in the window).
static func kpi_now(region: Region, m: MissionDef, clauses: Dictionary) -> String:
	var p: ProblemDef = region.problems.get(m.goal_problem)
	if p == null or not clauses.get(p.kpi) is String:
		return ""
	var now := Region.measures(region.net, p.step)
	var value := float(now.get(p.kpi, 0.0))
	if value <= 0.0 or (p.kpi != "capacity" and float(now["throughput"]) <= 0.0):
		return ""
	return str(clauses[p.kpi]).replace("{value}", spoken(p.kpi, value))


## A KPI's value as Ruud says it: whole days and percents, per week with a decimal comma
## (the coach's questions, the debriefs' numbers).
static func spoken(kpi: String, value: float) -> String:
	match kpi:
		"first_time_right", "on_time":
			return str(roundi(value * 100.0))
		"throughput", "capacity":
			return str(roundi(value)) if absf(value - roundf(value)) < 0.05 else String.num(value, 1).replace(".", ",")
	return str(roundi(value))


static func _after(now: String, line: String) -> String:
	return line if now.is_empty() else "%s. %s" % [now, line]
