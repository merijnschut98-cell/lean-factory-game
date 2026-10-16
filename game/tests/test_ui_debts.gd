extends TestCase
## The UI debts the rules already needed (PLAN 1.5): every code the rules
## return has Dutch words, the HUD shows savings and the debt floor, the
## Check shows its forecast, the A3 its repairs and missing preparations,
## the board its acts, chapters and forks, the codex its discoveries.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"


func _session() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, false)


# ── Words ───────────────────────────────────────────────────────────────────

func test_every_lesson_score_note_and_refusal_the_rules_give_has_words() -> void:
	for code in ["cause_right", "cause_wrong", "mismatch", "too_early", "not_moved"]:
		assert_ne(UiText.lesson(code), code, code)
	for code in ["impact_lead_time_small", "impact_constraint_small", "impact_not_constraint", "impact_good"]:
		assert_ne(UiText.score_note(code), code, code)
	assert_ne(UiText.a3_error("same_countermeasure"), "same_countermeasure")


func test_the_rules_events_read_in_dutch() -> void:
	var problems := {PROBLEM: "Maatwerk in het ontwerp"}
	var teams := {"werkvoorbereiding": "Werkvoorbereiding"}
	var dividend := UiText.event({"type": "dividend", "problem": PROBLEM, "budget": 2000, "days": 90}, {}, problems)
	assert_true(dividend.contains("Maatwerk in het ontwerp") and dividend.contains("€ 2.000") and dividend.contains("90"), dividend)
	var overload := UiText.event({"type": "overload", "team": "werkvoorbereiding", "problem": PROBLEM, "load": 0.97},
		{}, problems, teams)
	assert_true(overload.contains("Werkvoorbereiding") and overload.contains("97%"), overload)
	var repair := UiText.event({"type": "repair", "mission": "repair_x"}, {"repair_x": "Herstel: Maatwerk"})
	assert_true(repair.contains("Herstel: Maatwerk"), repair)
	var up := UiText.event({"type": "reputation", "change": 3, "reason": "flow", "value": 40}, {})
	var down := UiText.event({"type": "reputation", "change": -1, "reason": "blame", "value": 29}, {})
	assert_true(up.contains("+3") and down.contains("−1"), up + " / " + down)
	assert_ne(up.split("(")[1], down.split("(")[1], "the reason is worded")


func test_the_budget_line_shows_savings_and_the_floor_in_debt() -> void:
	assert_eq(UiText.budget_line(12000, 0.0), "Budget € 12.000")
	assert_true(UiText.budget_line(12000, 250.4).contains("€ 250"), "the weekly savings")
	var debt := UiText.budget_line(-8000, 0.0)
	assert_true(debt.contains(UiText.money(Region.DEBT_FLOOR)), debt)


func test_the_hud_shows_the_savings_of_held_fixes() -> void:
	var s := _session()
	var hud := Hud.new()
	hud.session = s
	hud.refresh()
	assert_eq(hud.budget_label.text, UiText.budget_line(s.budget(), s.region.weekly_savings()))
	hud.free()


# ── Check ───────────────────────────────────────────────────────────────────

func test_the_check_panel_takes_lower_is_better_from_the_rules() -> void:
	assert_false(CheckPanel.new().get_script().get_script_constant_map().has("LOWER_IS_BETTER"))
	assert_true(CheckPanel.improved("lead_time", 40.0, 30.0))
	assert_true(CheckPanel.improved("throughput", 4.0, 5.0))


func _numbers(v: float) -> Dictionary:
	return {"capacity": v, "throughput": v, "wip_age": v, "lead_time": v, "first_time_right": 0.8, "on_time": 0.7}


func _panel(s: GameSession, result: Dictionary) -> CheckPanel:
	s.region.state[PROBLEM].a3 = {"prediction": "throughput"}
	var panel := CheckPanel.new()
	panel.session = s
	panel.show_result(PROBLEM, result)
	return panel


func test_the_check_shows_its_forecast_with_and_without_the_fix() -> void:
	var s := _session()
	var forecast := {"days": 120, "window": 14, "with": _numbers(6.0), "without": _numbers(4.0), "kpi": "throughput"}
	var panel := _panel(s, {"passed": true, "before": _numbers(4.0), "after": _numbers(5.0), "forecast": forecast,
		"lesson": "cause_right", "not_constraint": false})
	assert_true(shows(panel, CheckPanel.WITHOUT), "zonder jouw maatregel")
	assert_true(shows(panel, CheckPanel.WITH), "met jouw maatregel")
	assert_true(shows(panel, "120 dagen"), "over forecast.days")
	panel.free()


func test_the_a3_says_the_check_is_simulating_before_it_runs() -> void:
	var s := _session()
	var a3 := A3Form.new()
	a3.session = s
	s.accept(MISSION)
	s.region.state[PROBLEM].phase = ProblemState.Phase.CHECK_READY
	a3.refresh()
	a3.show_simulating()
	assert_true(shows(a3, A3Form.SIMULATING), "the note shows while the forecast runs")
	a3.free()


func test_a_practice_fix_does_not_claim_a_bottleneck() -> void:
	var notes := CheckPanel.shown_notes(["coverage", "impact_constraint_small"], true)
	assert_false(notes.has("impact_constraint_small"))
	assert_true(notes.has("coverage"))
	assert_true(CheckPanel.shown_notes(["impact_good"], false).has("impact_good"))


# ── A3 ──────────────────────────────────────────────────────────────────────

func _a3_on_form(s: GameSession) -> A3Form:
	s.accept(MISSION)
	s.region.state[PROBLEM].phase = ProblemState.Phase.SPOTTED
	var a3 := A3Form.new()
	a3.session = s
	a3.refresh()
	return a3


func test_the_a3_lists_the_unprepared_countermeasures_with_their_hint() -> void:
	var s := _session()
	var cm: CountermeasureDef = s.region.countermeasures.values()[0]
	cm.preparation = "Vraag eerst bij Intake hoe de checklist nu gebruikt wordt."
	var a3 := _a3_on_form(s)
	s.region.unprepared[cm.id] = true  # after accept: the missions set it on each update
	a3.refresh()
	assert_true(shows(a3, A3Form.UNPREPARED), "the heading")
	assert_true(shows(a3, cm.preparation), "the hint")
	a3.free()


func test_the_a3_shows_the_year_cost_of_each_countermeasure() -> void:
	var s := _session()
	var a3 := _a3_on_form(s)
	var cm: CountermeasureDef = s.countermeasures()[0]
	var year := UiText.money(roundi(s.year_cost(cm.id) / 1000.0) * 1000) + " /jaar"
	assert_true(A3Form.option_text(cm, s).contains(year), A3Form.option_text(cm, s))
	a3.free()


func test_a_rework_shows_what_was_tried_before() -> void:
	var s := _session()
	var cm: CountermeasureDef = s.countermeasures()[0]
	s.region.state[PROBLEM].rework_from = {"cm": cm.id}
	var a3 := _a3_on_form(s)
	assert_true(shows(a3, A3Form.TRIED % cm.name), "eerder geprobeerd")
	a3.free()


# ── Board ───────────────────────────────────────────────────────────────────

func test_the_board_shows_acts_chapters_and_the_reopen_briefing() -> void:
	var s := _session()
	var m: MissionDef = s.missions.defs[MISSION]
	m.reopen_text = "Het maatwerk is terug."
	s.missions.done_once[MISSION] = true
	var board := MissionBoard.new()
	board.session = s
	board.refresh()
	assert_true(shows(board, UiText.act_title(m.act)), "the act")
	assert_true(shows(board, m.chapter), "the chapter")
	assert_true(shows(board, m.reopen_text), "the board uses mission_briefing")
	board.free()


func test_a_fork_is_shown_as_a_pair() -> void:
	var s := _session()
	var fork := s.missions.defs.values().filter(func(m: MissionDef) -> bool: return not m.fork_group.is_empty())
	assert_eq(fork.size(), 2)
	var other: MissionDef = s.missions.defs[MISSION]
	var rows := MissionBoard.rows([fork[0], other, fork[1]])
	assert_eq(rows.size(), 2, "the fork's two missions share a row")
	assert_eq(rows[0], [fork[0], fork[1]])
	assert_eq(rows[1], [other])


func test_a_repair_quest_is_named_as_one() -> void:
	var s := _session()
	var p: ProblemDef = s.region.problems[PROBLEM]
	assert_eq(MissionBoard.kind_label(Repairs.def_for(p)), MissionBoard.REPAIR_KIND)


func test_the_debrief_card_reads_the_play() -> void:
	var s := _session()
	var m: MissionDef = s.missions.defs[MISSION]
	m.debrief_variants["not_standardised"] = "Zonder standaard zakt dit weg."
	s.region.state[PROBLEM].phase = ProblemState.Phase.RESOLVED
	assert_eq(s.mission_debrief(MISSION), "Zonder standaard zakt dit weg.")


# ── Codex ───────────────────────────────────────────────────────────────────

func test_the_codex_shows_discoveries_as_silhouettes_and_titles() -> void:
	var s := _session()
	var codex := CodexPanel.new()
	codex.session = s
	codex.show_tab(CodexPanel.DISCOVERIES)
	assert_true(shows(codex, CodexPanel.SILHOUETTE), "unfound ones are silhouettes")
	var view: Array[Dictionary] = [{"id": "a", "found": true, "name": "A", "line": "", "reward": {"title": "Knelpuntjager"}},
		{"id": "b", "found": false, "hint": ""}]
	assert_eq(CodexPanel.titles(view), ["Knelpuntjager"])
	codex.free()
