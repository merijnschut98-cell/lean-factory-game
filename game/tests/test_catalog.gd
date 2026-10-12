extends TestCase
## The real problem catalogue (content/problems_tier*.yaml, countermeasures.yaml):
## it loads, it fits the real network, an expert can solve every problem, and
## every problem visibly hurts what it claims to hurt.

const SEED := 11
const DAYS := 90


func _catalog() -> Catalog:
	return Catalog.load_from()


func _region(c: Catalog) -> Region:
	return Region.new(Network.load_file(Network.DEFAULT_PATH, SEED), c.problems, c.countermeasures, Profile.new())


func test_the_catalogue_loads() -> void:
	var c := _catalog()
	assert_eq(c.error, "")
	assert_true(c.problems.size() >= 6, "problems: %d" % c.problems.size())
	assert_true(c.countermeasures.size() >= 6)


func test_every_effect_fits_the_real_network() -> void:
	var c := _catalog()
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


func test_an_expert_can_solve_every_problem() -> void:
	var c := _catalog()
	for p in c.problems:
		var score := _solve(c, p)
		assert_true(score.get("root_cause", 0) >= 4 and score.get("plan", 0) >= 4,
			"%s: %s" % [p.id, score.get("notes")])


## How hard the problem's stream is hit, through the mechanism it works by.
## Lead-time KPIs of two separate runs over a few months are too noisy to
## compare (the random sequences diverge after the first different draw), so:
## throughput problems by capacity; rework and slow work by the extra load on
## a team (deterministic: Capacity); waiting problems by the measured wait at
## their step.
static func _harm(p: ProblemDef) -> Dictionary:
	var base := Network.load_file(Network.DEFAULT_PATH, SEED)
	var hurt := Network.load_file(Network.DEFAULT_PATH, SEED)
	hurt.set_effects("problem:" + p.id, p.effects)
	var before := Capacity.analyse(base)
	var after := Capacity.analyse(hurt)
	if p.kpi == "throughput":
		var stream := p.stream_id()
		return {"before": before["streams"][stream]["capacity_per_week"], "after": after["streams"][stream]["capacity_per_week"], "more_is_worse": false}
	# The team whose load grows the most, relatively.
	var most := {"before": 1.0, "after": 1.0, "more_is_worse": true}
	for pool: String in before["pools"]:
		var was: float = before["pools"][pool]["load"]
		var now: float = after["pools"][pool]["load"]
		if was > 0.0 and now / was > most["after"] / most["before"]:
			most = {"before": was, "after": now, "more_is_worse": true}
	if most["after"] > most["before"]:
		return most
	base.advance_days(DAYS)
	hurt.advance_days(DAYS)
	var step := p.step.get_slice(".", 1)
	return {"before": base.stream(p.stream_id()).step(step).stats_since(0)["wait_hours"],
		"after": hurt.stream(p.stream_id()).step(step).stats_since(0)["wait_hours"], "more_is_worse": true}


func test_every_problem_hurts_its_stream() -> void:
	for p in _catalog().problems:
		var h := _harm(p)
		var worse: bool = h["after"] > h["before"] * 1.03 if h["more_is_worse"] else h["after"] < h["before"] * 0.97
		assert_true(worse, "%s should hurt its stream: %.2f → %.2f" % [p.id, h["before"], h["after"]])


func test_problems_hurt_their_named_kpi_in_the_simulation() -> void:
	# Where the effect is strong enough to show over one run (first-time-right
	# and on-time problems), check the KPI the problem names as well.
	for p in _catalog().problems:
		if not p.kpi in ["first_time_right", "on_time"]:
			continue
		var base := Network.load_file(Network.DEFAULT_PATH, SEED)
		var hurt := Network.load_file(Network.DEFAULT_PATH, SEED)
		hurt.set_effects("problem:" + p.id, p.effects)
		base.advance_days(DAYS)
		hurt.advance_days(DAYS)
		var before: float = base.stream(p.stream_id()).kpis(base.time, DAYS - 30)[p.kpi]
		var after: float = hurt.stream(p.stream_id()).kpis(hurt.time, DAYS - 30)[p.kpi]
		assert_true(after < before - 0.05, "%s: %s %.2f → %.2f" % [p.id, p.kpi, before, after])
