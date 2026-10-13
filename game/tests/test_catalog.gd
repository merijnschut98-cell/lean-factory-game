extends TestCase
## The real problem catalogue (content/problems_tier*.yaml, countermeasures.yaml):
## it loads, it fits the real network, an expert can solve every problem, and
## every problem visibly hurts what it claims to hurt.

const SEED := 11
## Long enough for connections to settle: realistic waits run to months, and
## late customers only start calling after nine weeks.
const DAYS := 150
## The window, at the end of those runs, over which a problem's named KPI is
## compared with the healthy base.
const KPI_WINDOW_DAYS := 60


func _region(c: Catalog) -> Region:
	return Region.new(Network.load_file(Network.DEFAULT_PATH, SEED), c.problems, c.countermeasures, Profile.new())


func test_the_catalogue_loads() -> void:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	assert_true(c.problems.size() >= 6, "problems: %d" % c.problems.size())
	assert_true(c.countermeasures.size() >= 6)


func test_every_effect_fits_the_real_network() -> void:
	var c := Catalog.load_from()
	var net := Network.load_file(Network.DEFAULT_PATH)
	for p in c.problems:
		assert_eq(net.set_effects("problem:" + p.id, p.effects), "", p.id)
	for cm in c.countermeasures:
		assert_eq(net.set_effects("cm:" + cm.id, cm.effects), "", cm.id)
		for pool in cm.team_hours:
			assert_true(net.pools.has(pool), "%s: team %s" % [cm.id, pool])


## The expert: walks to every key clue's place in depth order, asks open
## questions, names the real cause, the right waste and KPI, and picks the
## best-fitting countermeasure the region can use.
func _solve(c: Catalog, p: ProblemDef) -> Dictionary:
	var r := _region(c)
	assert_true(r.activate(p.id), p.id)
	_experiment(r, p, _investigate(r, p))
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check(p.id)
	assert_true(check.get("passed", false), "%s: check passes" % p.id)
	return r.act(p.id, true)


## Find every key clue like an expert: a deep look first, then by depth.
func _investigate(r: Region, p: ProblemDef) -> Array:
	r.use_tool(p.step, "data")  # a deep look spots even hidden problems
	var keys := p.clues.filter(func(k: Clue) -> bool: return k.key)
	keys.sort_custom(func(a: Clue, b: Clue) -> bool: return a.depth < b.depth)
	for k: Clue in keys:
		if k.tool == "conversation":
			r.ask(k.at, "walk")
		else:
			r.use_tool(k.at, k.tool)
	for k: Clue in keys:
		assert_true(r.found.has(k.id), "%s: key clue %s is reachable" % [p.id, k.id])
	return keys


## Submit an A3 with the real cause, all key evidence and the best fitting
## countermeasure available at the problem's tier.
func _experiment(r: Region, p: ProblemDef, keys: Array) -> void:
	var best := ""
	for cm in r.available_countermeasures():
		if cm.tier <= p.tier and p.countermeasures.get(cm.id, 0.0) > p.countermeasures.get(best, 0.0):
			best = cm.id
	var a3 := RulesFixture.a3(r, p.id, p.waste, best, keys.map(func(k: Clue) -> String: return k.id), p.kpi)
	assert_eq(r.submit_a3(p.id, a3), "", p.id)


## Each listed countermeasure is an improvement (some more than others), so
## each can pass the Check at full strength.
func test_every_listed_countermeasure_can_pass_the_check() -> void:
	var c := Catalog.load_from()
	var cms := {}
	for cm in c.countermeasures:
		cms[cm.id] = cm
	for p in c.problems:
		for cm_id: String in p.countermeasures:
			var cm: CountermeasureDef = cms[cm_id]
			assert_true(Pdca.effectiveness(p, cm, cm.tier)["eff"] >= Pdca.CHECK_PASS, "%s → %s" % [p.id, cm_id])


func test_an_expert_can_solve_every_problem() -> void:
	var c := Catalog.load_from()
	for p in c.problems:
		var score := _solve(c, p)
		assert_true(score.get("root_cause", 0) >= 4 and score.get("plan", 0) >= 4,
			"%s: %s" % [p.id, score.get("notes")])


## The base network after DAYS days, shared by the tests that compare against it.
static var _base_run: Network


static func _base_after_days() -> Network:
	if _base_run == null:
		_base_run = RulesFixture.real_network([], SEED)
		_base_run.advance_days(DAYS)
	return _base_run


## One run per problem, shared by the tests that only read its outcome.
static var _hurt_runs: Dictionary[String, Network] = {}


static func _hurt_after_days(p: ProblemDef) -> Network:
	if not _hurt_runs.has(p.id):
		var net := RulesFixture.real_network([p.id], SEED)
		net.advance_days(DAYS)
		_hurt_runs[p.id] = net
	return _hurt_runs[p.id]


## How much worse the problem makes its stream, as a ratio above 1, through
## the mechanism it works by. Lead-time KPIs of two runs over a few months
## are too noisy to compare (the random sequences diverge after the first
## different draw), so: throughput problems by capacity; rework and slow work
## by the extra load on the team it hits hardest (deterministic: Capacity);
## the rest by the measured waiting at their step. A first-time-right problem
## is also measured by the drop in first-time-right (base over hurt, over the
## last KPI_WINDOW_DAYS of the same runs as the named-KPI test), since quality can fall
## while load and waiting do not.
static func _harm(p: ProblemDef) -> float:
	var harm := _flow_harm(p)
	if p.kpi == "first_time_right":
		var base_run := _base_after_days()
		var base: float = base_run.stream(p.stream_id()).kpis(base_run.time, KPI_WINDOW_DAYS)["first_time_right"]
		var hurt_run := _hurt_after_days(p)
		var hurt: float = hurt_run.stream(p.stream_id()).kpis(hurt_run.time, KPI_WINDOW_DAYS)["first_time_right"]
		harm = maxf(harm, base / hurt)
	return harm


static func _flow_harm(p: ProblemDef) -> float:
	var before := Capacity.analyse(RulesFixture.real_network([], SEED))
	var after := Capacity.analyse(RulesFixture.real_network([p.id], SEED))
	if p.kpi == "throughput":
		return before["streams"][p.stream_id()]["capacity_per_week"] / after["streams"][p.stream_id()]["capacity_per_week"]
	var worst := 1.0
	for pool: String in before["pools"]:
		if before["pools"][pool]["load"] > 0.0:
			worst = maxf(worst, after["pools"][pool]["load"] / before["pools"][pool]["load"])
	if worst > 1.0:
		return worst
	# Waiting at the problem's own step: an external wait, or the queue in
	# front of a team (e.g. failure demand loading the contact centre, which a
	# static capacity analysis does not see).
	var step := p.step.get_slice(".", 1)
	var hurt: Dictionary = _hurt_after_days(p).stream(p.stream_id()).step(step).stats_since(0)
	var base: Dictionary = _base_after_days().stream(p.stream_id()).step(step).stats_since(0)
	return (hurt["wait_hours"] + hurt["queue_hours"]) / (base["wait_hours"] + base["queue_hours"])


func test_every_problem_hurts_its_stream() -> void:
	for p in Catalog.load_from().problems:
		var harm := _harm(p)
		assert_true(harm > 1.03, "%s should hurt its stream (×%.3f)" % [p.id, harm])


func test_problems_hurt_their_named_kpi_in_the_simulation() -> void:
	# Where the effect is strong enough to show over one run (first-time-right,
	# on-time and the age of open work), check the KPI the problem names as well.
	var base := _base_after_days()
	for p in Catalog.load_from().problems:
		if p.kpi == "wip_age":
			var older := _hurt_after_days(p)
			var age_before := base.open_age_days(base.stream(p.stream_id()))
			var age_after := older.open_age_days(older.stream(p.stream_id()))
			assert_true(age_after > age_before * 1.05, "%s: open work p85 %.0f → %.0f days" % [p.id, age_before, age_after])
			continue
		if not p.kpi in ["first_time_right", "on_time"]:
			continue
		var hurt := _hurt_after_days(p)
		var before: float = base.stream(p.stream_id()).kpis(base.time, KPI_WINDOW_DAYS)[p.kpi]
		var after: float = hurt.stream(p.stream_id()).kpis(hurt.time, KPI_WINDOW_DAYS)[p.kpi]
		assert_true(after < before - 0.05, "%s: %s %.2f → %.2f" % [p.id, p.kpi, before, after])


func test_the_game_knows_the_content_vocabulary() -> void:
	var vocab: Dictionary = JsonFile.read_dict("res://data/vocabulary.json")["data"]
	var tools: Array = Investigation.TOOLS.keys()
	tools.sort()
	assert_eq(tools, vocab["tools"])
	assert_eq(Investigation.WASTES, vocab["wastes"])
	assert_eq(Investigation.KPIS, vocab["kpis"])
	assert_eq(ProblemDef.SEVERITIES, vocab["severities"])
	assert_eq(ProblemDef.VISIBILITIES, vocab["visibilities"])
	assert_eq(Pdca.CHECK_PASS, vocab["check_pass"])
	assert_eq(MissionDef.KINDS, vocab["mission_kinds"])
	var goals := MissionDef.GOALS.duplicate()
	goals.sort()
	assert_eq(goals, vocab["mission_goals"])
	assert_eq(Missions.STAGES, vocab["coach_stages"])
	assert_eq(SimPool.START_RULES, vocab["start_rules"])
	assert_eq(SimPool.ORDER_RULES, vocab["order_rules"])
	assert_eq(CountermeasureDef.UNLOCKS, vocab["countermeasure_unlocks"])
	assert_eq(KpiDef.KINDS, vocab["kpi_kinds"])
	assert_eq(KpiDef.CARE_RULES, vocab["care_rules"])
	assert_eq(Progression.BELTS.map(func(b: Dictionary) -> int: return b["xp"]),
		vocab["belt_xp"].map(func(xp: float) -> int: return int(xp)), "JSON has no integers")
	var properties: Dictionary = vocab["effect_properties"]
	assert_eq(SimModifiers.PROPERTIES.keys().size(), properties.size())
	for property: String in SimModifiers.PROPERTIES:
		var spec: Dictionary = SimModifiers.PROPERTIES[property]
		assert_true(properties.has(property), property)
		var kind: String = spec["kind"]
		var step_kind: String = ["work", "wait", "material"][spec["step_kind"]] if spec.has("step_kind") else ""
		assert_eq({"kind": kind, "step_kind": step_kind}, properties.get(property), property)


## The real campaign: it opens with the first main mission only, the coach
## speaks Dutch about it, and walking the connections stream completes it.
func test_the_campaign_opens_with_the_first_main_mission() -> void:
	var c := Catalog.load_from()
	var log := Missions.new(_region(c), c.missions, c.coach)
	assert_eq(log.available().map(func(m: MissionDef) -> String: return m.id), ["walk_connections"])
	assert_eq(log.accept("walk_connections"), "")
	assert_eq(log.ask_coach()["text"], c.coach["stages"]["go_see"][0])
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()
	assert_eq(log.status("walk_connections"), "completed")
	assert_true(log.available().size() >= 3, "new missions unlock: the main story and side missions")
	assert_eq(log.active("main").size(), 0)


## The main quest forks after the first bottleneck: the next bottleneck
## (intake) or a problem that is not one (the monteurs). The player has to
## prioritise (CLAUDE.md §2).
func test_the_main_quest_forks_after_the_first_bottleneck() -> void:
	var c := Catalog.load_from()
	var log := Missions.new(_region(c), c.missions, c.coach)
	for id in ["walk_connections", "fix_custom_design"]:
		log.progress[id] = {"status": "completed", "asks": {}}
		log.done_once[id] = true
	var mains := log.available().filter(func(m: MissionDef) -> bool: return m.kind == "main").map(
		func(m: MissionDef) -> String: return m.id)
	mains.sort()
	assert_eq(mains, ["fix_incomplete_application", "fix_installer_not_ready"])


## Play the opening of the real campaign like an expert: the coach follows
## the PDCA loop of the main mission, and each solved problem unlocks the
## next part of the story.
func test_an_expert_plays_the_opening_of_the_campaign() -> void:
	var c := Catalog.load_from()
	var log := Missions.new(_region(c), c.missions, c.coach)
	var r := log.region
	log.accept("walk_connections")
	for step in r.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			r.use_tool("connections." + step.id, "shadow")
	log.update()
	for id in ["fix_custom_design", "fix_incomplete_application", "fix_status_callers"]:
		assert_eq(log.accept(id), "", id)
		var p: ProblemDef = r.problems[log.defs[id].goal_problem]
		var stages := [log.ask_coach()["stage"]]
		var keys := _investigate(r, p)
		stages.append(log.ask_coach()["stage"])
		_experiment(r, p, keys)
		stages.append(log.ask_coach()["stage"])
		r.advance_days(Region.CHECK_DAYS)
		assert_true(r.check(p.id).get("passed", false), id)
		stages.append(log.ask_coach()["stage"])
		assert_eq(stages, ["go_see", "understand", "experiment", "reflect"], id)
		r.act(p.id, true)
		log.update()
		assert_eq(log.status(id), "completed", id)
	assert_true(Progression.belt_index(r.profile.xp) >= 1, "yellow belt after the opening")
	assert_eq(log.status("fix_done_but_not_closed"), "available", "the story goes on")



## The glossary (content/concepts.yaml): everything the game teaches has an
## entry the codex can show.
func test_every_taught_concept_is_in_the_glossary() -> void:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	var taught := PackedStringArray(["PDCA", "A3", "gemba", "eight_wastes", "bottleneck_focus", "theory_of_constraints",
		"standard_work", "respect_for_people", "open_questions", "kata_prediction"])  # Region's profile.learn calls
	for w: String in Investigation.WASTES:
		taught.append("waste_" + w)
	for p in c.problems:
		taught.append_array(p.teaches)
		for clue in p.clues:
			taught.append_array(clue.teaches)
	for id in taught:
		assert_true(c.concepts.has(id), "concept %s" % id)
	var flow: ConceptDef = c.concepts["flow"]
	assert_eq(flow.category, "lean")
	assert_false(flow.name.is_empty() or flow.short.is_empty() or flow.text.is_empty() or flow.example.is_empty())
