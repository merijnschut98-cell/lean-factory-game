class_name RulesFixture
## A small network with problems and countermeasures in the shape the Phase B
## content (problems.json, countermeasures.json) will have.


static func net(seed_value: int = 5) -> Network:
	return NetFixture.net([
		NetFixture.pool("intake", 2), NetFixture.pool("prep", 2), NetFixture.pool("crew", 4), NetFixture.pool("gis", 2),
	], [
		NetFixture.stream("connections", [
			NetFixture.work("intake", "intake", 1.0, 0.9),
			NetFixture.work("design", "prep", 4.0),
			NetFixture.wait("permit", 5.0),
			NetFixture.work("build", "crew", 4.0),
			NetFixture.work("revision", "gis", 1.0),
		], 15.0, 2),
		NetFixture.stream("meters", [NetFixture.work("visit", "crew", 1.5)], 20.0, 2),
	], [], seed_value)


static func clue(tool: String, key: bool, depth: int, at: String = "") -> Dictionary:
	var d := {"tool": tool, "text": "%s %s %d" % [tool, "key" if key else "herring", depth], "key": key, "depth": depth}
	if not at.is_empty():
		d["at"] = at
	return d


static func problems() -> Array:
	return [
		{
			"id": "custom_design", "tier": 1, "name": "Maatwerk voor standaardwerk", "step": "connections.design",
			"waste": "overprocessing", "severity": "high", "visibility": "obvious", "kpi": "throughput",
			"root_cause": "Standard jobs get a full custom design",
			"plausible_causes": ["The preparers are too slow", "The design software is old"],
			# Several healthier processes: both help, one more than the other.
			"countermeasures": {"standard_designs": 1.0, "delegated_approval": 0.6}, "teaches": ["standard_work"],
			"cost_per_week": 700,  # overtime
			"effects": [NetFixture.effect("connections.design", "touch_time", 1.5)],
			"clues": [
				clue("time_study", true, 0), clue("queue_count", false, 0),
				clue("documents", true, 1), clue("conversation", true, 1, "connections.intake"),
				clue("data", true, 2),
			],
		},
		{
			"id": "incomplete_application", "tier": 1, "name": "De onvolledige aanvraag", "step": "connections.intake",
			"waste": "defects", "severity": "medium", "visibility": "obvious", "kpi": "first_time_right",
			"root_cause": "The online form accepts incomplete applications",
			"plausible_causes": ["Customers do not read the instructions"],
			"countermeasures": {"poka_yoke_form": 1.0}, "teaches": ["poka_yoke"],
			"effects": [NetFixture.effect("connections.intake", "ftr", -0.3)],
			"clues": [clue("documents", true, 0), clue("conversation", true, 0)],
		},
		{
			"id": "revision_backlog", "tier": 1, "name": "De revisieberg", "step": "connections.revision",
			"waste": "inventory", "severity": "low", "visibility": "hidden", "kpi": "lead_time",
			"root_cause": "As-built changes are typed in weeks later",
			"plausible_causes": [], "countermeasures": {"revision_at_source": 1.0}, "teaches": [],
			"effects": [NetFixture.effect("connections.revision", "touch_time", 1.5)],
			"clues": [clue("data", true, 0)],
		},
	]


static func countermeasures() -> Array:
	return [
		{
			"id": "standard_designs", "tier": 1, "name": "Standaardontwerpen", "category": "standard_work",
			"budget": 8000, "team_hours": {"prep": 40}, "decay_days": 30,
			"multipliers": {"full": 0.9, "reduced": 0.5, "minimal": 0.25},
			"effects": [NetFixture.effect("connections.design", "touch_time", 0.8)],
		},
		{
			"id": "poka_yoke_form", "tier": 1, "name": "Poka-yoke aanvraagformulier", "category": "quality",
			"budget": 5000, "team_hours": {"intake": 20}, "decay_days": null,
			"multipliers": {"full": 0.85, "reduced": 0.45, "minimal": 0.2},
			"effects": [NetFixture.effect("connections.intake", "ftr", 0.05)],
		},
		{
			"id": "delegated_approval", "tier": 1, "name": "Gedelegeerde goedkeuring", "category": "flow",
			"budget": 2000, "team_hours": {"prep": 10}, "decay_days": 20,
			"multipliers": {"full": 0.9, "reduced": 0.5, "minimal": 0.25},
			"effects": [NetFixture.effect("connections.design", "touch_time", 0.9)],
		},
		{
			"id": "revision_at_source", "tier": 3, "name": "Revisie aan de bron", "category": "flow",
			"budget": 15000, "team_hours": {"gis": 40}, "decay_days": null,
			"multipliers": {"full": 0.9, "reduced": 0.5, "minimal": 0.25}, "effects": [],
		},
	]


## The real network with some real catalogue problems switched on.
static func real_network(problem_ids: Array = [], seed_value: int = 11) -> Network:
	var net := Network.load_file(Network.DEFAULT_PATH, seed_value)
	for p in Catalog.load_from().problems:
		if p.id in problem_ids:
			net.set_effects("problem:" + p.id, p.effects)
	return net


static func region(budget: int = 50000, seed_value: int = 5) -> Region:
	var profile := Profile.new()
	profile.budget = budget
	return Region.new(net(seed_value), problem_defs(), countermeasure_defs(), profile)


## An A3 for `problem_id` naming its real root cause.
static func a3(r: Region, problem_id: String, waste: String, cm: String, evidence: Array, prediction: String) -> Dictionary:
	var options: Dictionary = Investigation.cause_options(r.problems[problem_id], r.problem_list())
	return {"waste": waste, "cause": options["correct"], "evidence": evidence, "cm": cm, "prediction": prediction}


static func problem_defs() -> Array[ProblemDef]:
	var out: Array[ProblemDef] = []
	for d: Dictionary in problems():
		out.append(ProblemDef.from_dict(d))
	return out


static func countermeasure_defs() -> Array[CountermeasureDef]:
	var out: Array[CountermeasureDef] = []
	for d: Dictionary in countermeasures():
		out.append(CountermeasureDef.from_dict(d))
	return out


## The coach and missions in the shape of content/missions.yaml.
static func coach() -> Dictionary:
	return {
		"name": "Marleen", "role": "manager",
		"stages": {
			"go_see": ["go_see 1", "go_see 2"], "understand": ["understand 1", "understand 2"],
			"experiment": ["experiment 1"], "reflect": ["reflect 1"],
		},
	}


static func missions() -> Array:
	var m := func(id: String, kind: String, goal: Dictionary, requires: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
		var d := {"id": id, "name": id, "kind": kind, "tier": 1, "requires": requires, "goal": goal,
			"briefing": "briefing " + id, "debrief": "debrief " + id, "rewards": {"xp": 300, "budget": 2000}}
		d.merge(extra, true)
		return d
	return [
		m.call("walk_connections", "main", {"type": "walk", "stream": "connections"}),
		m.call("fix_design", "main", {"type": "solve", "problem": "custom_design"}, {"missions": ["walk_connections"]},
			{"insights": {"understand": "insight understand"}}),
		m.call("look_at_intake", "side", {"type": "investigate", "problem": "incomplete_application", "clues": 1},
			{"missions": ["walk_connections"]}),
		m.call("fix_revision", "side", {"type": "solve", "problem": "revision_backlog"}, {"missions": ["walk_connections"]}),
		m.call("walk_meters", "side", {"type": "walk", "stream": "meters"}),
		m.call("deep_dive", "main", {"type": "investigate", "problem": "custom_design", "clues": 1},
			{"missions": ["walk_connections"]}),
		m.call("henk", "side", {"type": "solve", "problem": "incomplete_application"}, {"missions": ["walk_connections"]},
			{"deadline_days": 10, "fail": "fail henk", "fail_closes": ["poka_yoke_form"]}),
		m.call("green_only", "side", {"type": "walk", "stream": "meters"}, {"belt": 2}),
	]


static func mission_log(r: Region) -> Missions:
	var defs: Array[MissionDef] = []
	for d: Dictionary in missions():
		defs.append(MissionDef.from_dict(d))
	return Missions.new(r, defs, coach())

