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
	assert_true(talks.all(func(t: Dictionary) -> bool:
		return t["kind"] == ExpertTalk.KIND or t["moves"].is_empty() or t["moves"][0] in Dialog.LISTEN),
		"opens every talk with a listening move (an expert's talk is questions: its moves are the topics)")
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


## The fork's control (Phase 2 gate): plays as the expert, but where the main quest forks it
## takes the non-bottleneck branch first; the curve samples the connections flow, so the two
## orders can be compared on throughput.
func test_the_non_bottleneck_control_takes_the_other_branch_first_and_the_curve_has_the_flow() -> void:
	var run: Dictionary = Autoplay.Persona.new("non-bottleneck", 11, 3).play()
	assert_eq(run["dead_ends"], [], "no dead end")
	var mains := (run["missions"] as Array).filter(func(m: Dictionary) -> bool: return m["kind"] == "main") \
		.map(func(m: Dictionary) -> String: return m["id"])
	assert_eq(mains, ["walk_connections", "fix_custom_design", "fix_installer_not_ready"], "the non-bottleneck first")
	var point: Dictionary = (run["curve"] as Array).back()
	assert_true(point.has("throughput") and point.has("lead_days"), "the connections flow: %s" % [point])
	assert_eq([point.get("advance"), run.get("advance_max")], [0, 0], "the directie's advance (none above the floor)")
	var rows := Autoplay.PlayReport._story_table([run])
	assert_true(rows[2].begins_with("| non-bottleneck | 11 | installer_not_ready | "),
		"a row per run: the fork branch taken first, the winter, Act II: %s" % rows[2])


## Milestones never dead-end a run (phase-2 design §3.1): a scene is sat through, the
## story's order is judged by the simulation while the player plays on.
func test_milestones_do_not_dead_end_a_run() -> void:
	var persona := Autoplay.Persona.new("expert", 11, 2)
	persona.story_day = 100   # Honderd dagen at once; the first frost long past
	var run: Dictionary = persona.play()
	assert_eq(run["dead_ends"], [], "no dead end")
	assert_eq(run["errors"], [], "no engine error")
	assert_eq(run["end"], "stop_after")
	var review := (run["missions"] as Array).filter(func(m: Dictionary) -> bool: return m["id"] == "review_100_days")
	assert_eq(review.map(func(m: Dictionary) -> String: return m["outcome"]), ["completed"], "the scene was played")


## Het eerste kwartaal ends at the KPI board (PLAN 2.4c): autoplay hangs the persona's
## KPIs there (the expert's play flow first), then the scene completes.
func test_the_first_quarterly_review_is_played_at_the_board() -> void:
	for persona: String in ["expert", "careless", "average"]:
		var p := Autoplay.Persona.new(persona, 11)
		p.s = GameSession.new_game(11, Catalog.DATA_DIR, false)
		p.s.missions.done_once["fix_silo_kpis"] = true
		p.s.pass_time(0)
		assert_eq(p.s.missions.status("first_kpi_review"), "active")
		assert_eq(p.play_scene(p.s.missions.defs["first_kpi_review"]), "", persona)
		assert_eq(p.s.missions.status("first_kpi_review"), "completed", persona)
		var steers := p.s.catalog.kpis.steers(p.s.region.board.chosen)
		if persona != "average":
			assert_eq(Array(steers), ["flow"] if persona == "expert" else ["output"], persona)


## A main done again after it reopened counts once in the story table's Act II column.
func test_the_story_table_counts_each_act_ii_main_once() -> void:
	var missions := Autoplay.ACT2_MAINS.map(func(id: String) -> Dictionary:
		return {"id": id, "outcome": "completed", "completed_day": 150.0})
	missions.append({"id": Autoplay.ACT2_MAINS[0], "outcome": "completed", "completed_day": 200.0})
	var run := {"persona": "average", "seed": 11, "missions": missions, "dead_ends": [], "curve": [],
		"followed_day": 80.0, "winter": "missed"}
	var row: String = Autoplay.PlayReport._story_table([run])[2]
	assert_true(" | 6 of 6 | 150 | " in row, row)


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


## Finding 13 (careless seed 12, day 467): the Check passed on a lead-time gain
## of 2.04 %, just over Pdca.CHECK_NOISE; the report's copy rounds it to 2.0 %,
## and the flag read that copy as "no visible change". The flags judge the
## Check's own unrounded gains, as Region.check does.
func test_the_flags_judge_the_unrounded_gain_not_the_reports_rounded_copy() -> void:
	var raw := {"capacity": 0.0, "first_time_right": 0.062, "lead_time": 0.02036, "on_time": 0.101,
		"throughput": 0.005, "wip_age": -0.001}
	var rows := {"capacity": 25.0, "first_time_right": 0.3, "lead_time": 130.0, "on_time": 0.85,
		"throughput": 20.0, "wip_age": 90.0}
	var entry := {"passed": true, "prediction": "lead_time", "kpi": "lead_time", "cause_correct": true,
		"at_constraint": false, "before": rows, "after": rows, "throughput_direction": 1,
		"not_constraint": false, "wait_step": true, "lesson": "cause_right", "level": "full",
		"gains": Autoplay.Persona._rows(raw)}
	assert_eq(entry["gains"]["lead_time"], 0.02, "the report's copy rounds to the noise edge")
	assert_false("passed_no_visible_change" in Autoplay.Persona._flags(entry, raw),
		"2.04 % is over the noise: the Check saw a change")
	raw["lead_time"] = 0.01
	assert_true("passed_no_visible_change" in Autoplay.Persona._flags(entry, raw),
		"a pass with its gain inside the noise is still flagged")
