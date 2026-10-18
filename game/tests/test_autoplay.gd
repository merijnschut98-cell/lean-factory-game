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


func test_the_talker_talks_to_everyone_it_can_and_listens_first() -> void:
	var run: Dictionary = Autoplay.Persona.new("talker", 11, 1).play()
	assert_eq(run["dead_ends"], [], "no dead end")
	assert_eq(run["errors"], [], "no engine error")
	var talks: Array = run["talks"]
	var dialogs := talks.map(func(t: Dictionary) -> String: return t["dialog"])
	for id in ["anouk_seven", "sanne_tuesday", "rachid_counter", "anouk_owns_tray"]:
		assert_true(id in dialogs, "%s had: %s" % [id, dialogs])
	assert_true(talks.all(func(t: Dictionary) -> bool: return not t["forced"]), "the talker opens its talks itself")
	assert_true(talks.all(func(t: Dictionary) -> bool: return not "pressure" in t["moves"] and not "confront" in t["moves"]),
		"never pressures")
	assert_true(talks.all(func(t: Dictionary) -> bool: return t["moves"].is_empty() or t["moves"][0] in Dialog.LISTEN),
		"opens every talk with a listening move")
	assert_true(talks.any(func(t: Dictionary) -> bool: return t["outcome"] in ["commitment", "partial"]),
		"wins at least one agreement: %s" % [talks.map(func(t: Dictionary) -> String: return t["outcome"])])
	assert_true((run["people"] as Dictionary).has("anouk"), "trust and morale per person")


func test_never_talks_has_only_the_talk_a_mission_cannot_end_without() -> void:
	var run: Dictionary = Autoplay.Persona.new("never-talks", 11, 1).play()
	assert_eq(run["dead_ends"], [], "no dead end")
	var talks: Array = run["talks"]
	assert_eq(talks.map(func(t: Dictionary) -> String: return t["dialog"]), ["anouk_seven"], "only Monday's talk")
	assert_true(talks[0]["forced"])
	var monday: Array = (run["ends_with_talk"] as Array).filter(func(e: Dictionary) -> bool: return e["mission"] == "training_mon")
	assert_eq(monday.size(), 1, "Monday waited for Anouk's talk")
	assert_true(monday[0]["held_open"], "the walk was done, the day stayed open until the talk")
	assert_true(monday[0]["completed_after_talk"], "the day ended with the talk")


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
