extends TestCase
## The real problem catalogue (content/problems_tier*.yaml, countermeasures.yaml):
## it loads, it fits the real network, an expert can solve every problem, and
## every problem visibly hurts what it claims to hurt.

const SEED := 11
## Long enough for connections to settle: realistic waits run to months, and
## late customers only start calling after nine weeks.
const DAYS := 150


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
	var best := ""
	for cm in r.available_countermeasures():
		if cm.tier <= p.tier and p.countermeasures.get(cm.id, 0.0) > p.countermeasures.get(best, 0.0):
			best = cm.id
	var a3 := RulesFixture.a3(r, p.id, p.waste, best, keys.map(func(k: Clue) -> String: return k.id), p.kpi)
	assert_eq(r.submit_a3(p.id, a3), "", p.id)
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check(p.id)
	assert_true(check.get("passed", false), "%s: check passes with %s" % [p.id, best])
	return r.act(p.id, true)


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


static func _hurt_after_days(p: ProblemDef) -> Network:
	var net := RulesFixture.real_network([p.id], SEED)
	net.advance_days(DAYS)
	return net


## How much worse the problem makes its stream, as a ratio above 1, through
## the mechanism it works by. Lead-time KPIs of two runs over a few months
## are too noisy to compare (the random sequences diverge after the first
## different draw), so: throughput problems by capacity; rework and slow work
## by the extra load on the team it hits hardest (deterministic: Capacity);
## the rest by the measured waiting at their step.
static func _harm(p: ProblemDef) -> float:
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
	# Where the effect is strong enough to show over one run (first-time-right
	# and on-time problems), check the KPI the problem names as well.
	var base := _base_after_days()
	for p in Catalog.load_from().problems:
		if not p.kpi in ["first_time_right", "on_time"]:
			continue
		var hurt := _hurt_after_days(p)
		var before: float = base.stream(p.stream_id()).kpis(base.time, 60)[p.kpi]
		var after: float = hurt.stream(p.stream_id()).kpis(hurt.time, 60)[p.kpi]
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

