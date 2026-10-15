class_name Investigation
## Investigation by doing: gemba tools reveal clues, questions earn (or lose)
## a team's trust, and the player builds the root cause from evidence.
## Ids only: the UI gives tools, questions and replies their Dutch words.

## Gemba tools for a service and field organisation: simulated minutes it
## takes, and whether it can expose problems a quick look misses.
const TOOLS := {
	"shadow": {"minutes": 240, "deep": false},  # meelopen: half a day with a monteur, planner or agent
	"time_study": {"minutes": 120, "deep": true},  # tijdstudie
	"queue_count": {"minutes": 30, "deep": false},  # wachtrij tellen
	"data": {"minutes": 90, "deep": true},  # data analyseren (SAP, GIS, Nestor)
	"documents": {"minutes": 60, "deep": false},  # dossiers doorlezen
	"listen_in": {"minutes": 120, "deep": true},  # meeluisteren klantcontact
	"material_check": {"minutes": 30, "deep": false},  # materiaal checken
	"conversation": {"minutes": 30, "deep": false},  # gesprek (see QUESTIONS)
}

## question id → kind. Open questions earn stories, closed ones "yeah,
## mostly", blaming ones cost trust, a repair restores it.
const QUESTIONS := {
	"walk": "open", "obstacle": "open", "last": "open",
	"standard": "closed", "ok": "closed",
	"behind": "blame", "who": "blame",
	"thanks": "repair",
}

## The 8 wastes (TIMWOODS).
const WASTES := ["transport", "inventory", "motion", "waiting", "overproduction", "overprocessing", "defects", "skills"]

## What a prediction can name.
const KPIS := ["throughput", "lead_time", "first_time_right", "on_time", "wip_age", "capacity"]
## KPIs where a smaller number is better (days); the rest are better higher.
const LOWER_IS_BETTER := ["lead_time", "wip_age"]


## Whether `clue` can be found now: not yet found, and at depth 0 or with a
## key clue one "why" shallower already found.
static func revealable(clue: Clue, problem: ProblemDef, found: Dictionary) -> bool:
	if found.has(clue.id):
		return false
	if clue.depth == 0:
		return true
	for k in problem.clues:
		if k.key and k.depth == clue.depth - 1 and found.has(k.id):
			return true
	return false


## Candidate root causes for the A3: the real one, up to two plausible ones,
## and real root causes of other problems of the same tier (same stream
## first). Stable order per problem. Returns {options, correct}.
static func cause_options(problem: ProblemDef, all: Array[ProblemDef], n: int = 5) -> Dictionary:
	var others := all.filter(func(o: ProblemDef) -> bool: return o.id != problem.id and o.tier == problem.tier)
	others.sort_custom(func(a: ProblemDef, b: ProblemDef) -> bool:
		var a_same := a.stream_id() == problem.stream_id()
		var b_same := b.stream_id() == problem.stream_id()
		if a_same != b_same:
			return a_same
		return Rng.fnv1a(problem.id + a.id) < Rng.fnv1a(problem.id + b.id))
	var options: Array[String] = [problem.root_cause]
	for cause in Array(problem.plausible_causes).slice(0, 2) + others.map(func(o: ProblemDef) -> String: return o.root_cause):
		if options.size() < n and not cause in options:
			options.append(cause)
	options.sort_custom(func(a: String, b: String) -> bool: return Rng.fnv1a(problem.id + a) < Rng.fnv1a(problem.id + b))
	return {"options": options, "correct": options.find(problem.root_cause)}

