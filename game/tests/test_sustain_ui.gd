extends TestCase
## Sustain or decay and stagnation drift in the UI: the event texts, the
## leader routines in a team's menu (only where a standardised fix is held),
## a fix's health and the drift as measures (never the remedy), and the
## Friday card that no longer says a standard holds a fix by itself.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "connections.design"
const INTAKE := "connections.intake"

## Panels built outside the tree, freed at the end of each test (_free_all).
var _made: Array[Node] = []


## A returning player's game with "Maatwerk voor standaardwerk" solved
## (standardised or not).
func _solved(standardise: bool) -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.accept(MISSION), "")
	s.use_tool(DESIGN, "time_study")
	s.use_tool(DESIGN, "documents")
	s.ask(INTAKE, "walk")
	s.use_tool(DESIGN, "data")
	var problem: ProblemDef = s.region.problems[PROBLEM]
	assert_eq(s.submit_a3(PROBLEM, {"waste": "overprocessing", "cause": s.cause_options(PROBLEM).find(problem.root_cause),
		"evidence": s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id), "cm": "standard_designs",
		"prediction": "throughput"}), "")
	s.wait_for_check(PROBLEM)
	assert_true(s.check(PROBLEM)["passed"])
	assert_false(s.act(PROBLEM, standardise).has("error"))
	return s


func _menu(s: GameSession, place: String) -> PlaceMenu:
	var menu := PlaceMenu.new()
	_made.append(menu)
	menu.session = s
	menu.open_at(place)
	return menu


func _free_all() -> void:
	for n in _made:
		n.free()
	_made.clear()


## Wear the fix to just above the slipping line: the next hour crosses it.
func _nearly_slipping(s: GameSession) -> void:
	var st: ProblemState = s.region.state[PROBLEM]
	st.neglect = s.region.life_days(PROBLEM) * 0.64
	st.wear = 0.4149


# ── Words ───────────────────────────────────────────────────────────────────

func test_the_slipping_and_check_in_events_are_worded_with_their_names() -> void:
	var slipping := UiText.event({"type": "slipping", "problem": PROBLEM}, {}, {PROBLEM: "Maatwerk"})
	assert_true(slipping.contains("Maatwerk"), slipping)
	var checkin := UiText.event({"type": "checkin", "mission": "terugval_x"}, {"terugval_x": "Terugval: Maatwerk"})
	assert_true(checkin.contains("Terugval: Maatwerk") and checkin.contains("missiebord"), checkin)


func test_every_routine_refusal_is_worded() -> void:
	for code in ["no_team", "planned", "not_planned"]:
		assert_ne(UiText.place_error(code), code, code)


func test_a_fixs_health_reads_as_a_measure_not_a_remedy() -> void:
	var line := UiText.fix_health({"health": 0.82, "standardised": true, "neglect_days": 40.4, "routine": false})
	assert_eq(line, "Werkt voor 82%  ·  gestandaardiseerd  ·  40 dagen niet nagelopen")
	assert_eq(UiText.fix_health({"health": 1.0, "standardised": true, "neglect_days": 0.0, "routine": true}),
		"Werkt voor 100%  ·  gestandaardiseerd  ·  wekelijkse routine")
	assert_eq(UiText.fix_health({"health": 0.9, "standardised": false, "neglect_days": 1.0, "routine": false}),
		"Werkt voor 90%  ·  geen standaard  ·  1 dag niet nagelopen")
	for remedy in ["audit", "plan", "doe "]:
		assert_false(line.to_lower().contains(remedy), "no remedy in the measure: " + remedy)


func test_the_drift_reads_as_days_and_a_level() -> void:
	assert_eq(UiText.drift_line({"level": 0.2, "stagnant_days": 101.2, "started": true}),
		"Laatste afgeronde verbetering: 101 dagen geleden  ·  achteruitgang door stilstand: 20%")
	assert_eq(UiText.drift_line({"level": 0.0, "stagnant_days": 0.0, "started": false}), "", "not before the campaign")


# ── The Friday card ─────────────────────────────────────────────────────────

func test_the_friday_card_says_a_standard_slows_the_slide_and_routines_hold_it() -> void:
	var kept := CheckPanel.forecast_verdict({"standardised": true, "recur_days": 21.7, "fade_days": 10})
	assert_true(kept.contains("22 dagen"), kept)
	assert_false(kept.contains("houdt haar vast"), "a standard alone does not hold it")
	assert_true(kept.contains("audit") and kept.contains("routine"), kept)
	var held := CheckPanel.forecast_verdict({"standardised": true, "recur_days": INF, "fade_days": 10})
	assert_true(held.contains("routine"), held)
	assert_eq(CheckPanel.forecast_verdict({"standardised": false, "recur_days": 10.0, "fade_days": 10}),
		CheckPanel.NOT_KEPT % "10 dagen")


# ── The place menu ──────────────────────────────────────────────────────────

func test_audit_and_routine_show_only_where_a_standardised_fix_is_held() -> void:
	var s := _solved(true)
	var design := _menu(s, DESIGN)
	assert_eq(design.sustain_actions(), ["audit", "plan_routine"])
	assert_true(shows(design, "Audit van de standaard (1 uur)"), "the audit with its time")
	assert_true(shows(design, "2 uur per week"), "the routine with the team's cost")
	assert_true(shows(design, "Werkt voor 100%"), "the fix's health, as measured")
	assert_eq(_menu(s, INTAKE).sustain_actions(), [], "no fix held at the intake")
	assert_false(shows(_menu(s, INTAKE), "Audit van de standaard"))
	assert_eq(_menu(_solved(false), DESIGN).sustain_actions(), [], "no standard, nothing to audit or hold")
	assert_eq(_menu(GameSession.new_game(11, Catalog.DATA_DIR, false), DESIGN).sustain_actions(), [], "nothing solved")
	_free_all()


func test_an_audit_in_the_menu_takes_an_hour_and_refreshes_the_fix() -> void:
	var s := _solved(true)
	var st: ProblemState = s.region.state[PROBLEM]
	st.wear = 0.3
	var menu := _menu(s, DESIGN)
	var before := s.region.net.time
	var text := menu.audit()
	assert_eq(s.region.net.time - before, Sustain.AUDIT_MINUTES)
	assert_true(text.contains(s.region.problems[PROBLEM].name), text)
	assert_near(st.wear, 0.0, 1e-4, "back in full use (the hour after it barely counts)")
	assert_true(shows(menu, text), "the result shows in the menu")
	_free_all()


func test_a_routine_is_planned_and_stopped_from_the_menu() -> void:
	var s := _solved(true)
	var menu := _menu(s, DESIGN)
	assert_true(menu.plan_routine().contains("2 uur"), "the cost is named")
	assert_eq(s.routines(), [DESIGN])
	assert_eq(menu.sustain_actions(), ["audit", "stop_routine"])
	assert_true(shows(menu, "wekelijkse routine"), "the fix shows it is held")
	assert_false(menu.stop_routine().is_empty())
	assert_eq(s.routines(), [])
	assert_eq(menu.sustain_actions(), ["audit", "plan_routine"])
	_free_all()


func test_the_place_menu_is_a_narrow_side_panel() -> void:
	var menu := PlaceMenu.new()
	assert_true(menu.docked, "docked at the side, the framed station stays in view")
	assert_true(menu.custom_minimum_size.x <= 560, "narrow: %d" % menu.custom_minimum_size.x)
	menu.free()


## A docked panel's place in one rect, set once (UiPanel._place): shrinking
## it to its minimum and then growing it to full height resized it twice per
## placement, each resize queued two more, and the game crashed when a place
## opened. (Resizes only notify inside a tree, which this runner lacks.)
func test_a_docked_panel_is_placed_in_one_rect() -> void:
	var screen := Vector2(1600, 900)
	var rect := UiPanel.placement(screen, Vector2(PlaceMenu.WIDTH, 43), true)
	assert_eq(rect.end.x, screen.x - UiPanel.DOCK_MARGIN, "at the right edge")
	assert_eq(rect.position.y, float(UiPanel.DOCK_TOP), "below the HUD's bar")
	assert_eq(rect.end.y, screen.y - UiPanel.DOCK_MARGIN, "the full height")
	assert_eq(UiPanel.placement(screen, Vector2(PlaceMenu.WIDTH, 2000), true).size.y, 2000.0, "never below its minimum")
	assert_eq(UiPanel.placement(screen, Vector2(1000, 500), false), Rect2(300, 200, 1000, 500), "others centred")


# ── The journal and the HUD ─────────────────────────────────────────────────

func test_the_journal_lists_each_fix_with_its_health() -> void:
	var s := _solved(true)
	var journal := ClueJournal.new()
	journal.session = s
	journal.refresh()
	assert_true(shows(journal, s.region.problems[PROBLEM].name), "the fix by name")
	assert_true(shows(journal, "Werkt voor 100%"), "its health")
	assert_true(shows(journal, "Laatste afgeronde verbetering"), "the drift's measure")
	assert_false(shows(journal, "audit"), "the measure, not the remedy")
	journal.free()


func test_the_practice_fix_is_not_listed() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(SustainView.fixes(s), [])
	s.region.state["training_tray"].phase = ProblemState.Phase.RESOLVED
	assert_eq(SustainView.fixes(s), [], "the training week's problem is retired")


func test_the_hud_shows_the_drift_once_the_region_slides_back() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var hud := Hud.new()
	hud.session = s
	hud.refresh()
	assert_false(hud.drift_label.visible, "no drift yet")
	s.region.advance_days(Sustain.DRIFT_GRACE_DAYS + 73)
	hud.refresh()
	assert_true(hud.drift_label.visible)
	assert_eq(hud.drift_label.text, "Achteruitgang 20%")
	hud.free()


func test_a_slipping_fix_shows_as_toasts_with_the_check_in() -> void:
	var s := _solved(true)
	var ui := GameUI.new()
	ui.setup(s)
	_nearly_slipping(s)
	s.audit(INTAKE)  # an hour passes elsewhere
	ui.after_action()
	var toasts := ui.hud.toast_texts()
	var name: String = s.region.problems[PROBLEM].name
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("zakt weg") and t.contains(name)), str(toasts))
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("Terugval: " + name)), str(toasts))
	ui.free()
