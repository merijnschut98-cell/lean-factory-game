extends TestCase
## The automated playtester (tools/autoplay.gd): the expert persona plays the
## training week and the first three main missions on the real content
## without a dead end, an engine error or a failed Check.

const Autoplay := preload("res://tools/autoplay.gd")
const MAIN_MISSIONS := 3


func test_the_expert_plays_the_training_week_and_three_main_missions_without_a_dead_end() -> void:
	var run: Dictionary = Autoplay.Persona.new("expert", 11, MAIN_MISSIONS).play()
	assert_eq(run["dead_ends"], [], "no dead end")
	assert_eq(run["errors"], [], "no engine error")
	assert_eq(run["end"], "stop_after", "it got as far as asked")
	var done: Array = (run["missions"] as Array).filter(func(m: Dictionary) -> bool: return m["outcome"] == "completed")
	var ids := done.map(func(m: Dictionary) -> String: return m["id"])
	for day in ["training_mon", "training_tue", "training_wed", "training_thu", "training_fri"]:
		assert_true(day in ids, "%s done: %s" % [day, ids])
	assert_eq(done.filter(func(m: Dictionary) -> bool: return m["kind"] == "main").size(), MAIN_MISSIONS)
	assert_true((run["checks"] as Array).all(func(c: Dictionary) -> bool: return c["passed"]),
		"the expert's best countermeasure passes every Check")
	assert_true((run["coach"] as Array).all(func(c: Dictionary) -> bool:
		return c["kind"] == ("not_main" if c["mission_kind"] == "side" else "question") or c["kind"] == "insight"),
		"the coach coaches the main quest and the training week, not side missions")
	assert_true(run["xp"] > 0 and not (run["curve"] as Array).is_empty())


func test_the_report_ranks_findings_by_severity() -> void:
	var run: Dictionary = Autoplay.Persona.new("expert", 11, 1).play()
	run["dead_ends"] = [{"kind": "belt_gate", "mission": "x", "detail": "d", "day": 1.0}]
	var runs: Array[Dictionary] = [run]
	var findings := Autoplay.PlayReport.findings(runs, Catalog.load_from())
	assert_false(findings.is_empty())
	assert_eq(findings[0]["severity"], "critical", "a dead end comes first")
	assert_eq(findings[0]["repro"]["persona"], "expert")
	var order := findings.map(func(f: Dictionary) -> int: return Autoplay.SEVERITIES.find(f["severity"]))
	var sorted := order.duplicate()
	sorted.sort()
	assert_eq(order, sorted, "ranked by severity")
