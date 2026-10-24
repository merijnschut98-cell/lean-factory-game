extends TestCase
## The KPI board at the directie obeya (PLAN 2.4c): a magnetic wall board, not a
## panel. Each team's KPI cards hang in its column; a click puts a magnet on a card,
## two per team, and hanging the choice runs the quarterly review
## (GameSession.kpi_review). Then only the chosen cards stay up, each with its real
## number from the region, and Ruud asks about what the analysts' forecast showed.

const FLOW := {"intake": ["intake_lead_time", "intake_oldest"], "work_prep": ["work_prep_lead_time", "work_prep_oldest"],
	"planners": ["planners_on_time", "planners_oldest"], "contact_centre": ["contact_centre_resolved", "contact_centre_reachable"]}


func _session(due: bool = true) -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.region.advance_days(20)
	if due:
		s.region.board.unlock(s.region.net.time)
	return s


func _open(s: GameSession) -> KpiBoardView:
	return KpiBoardView.create(s)


func test_the_board_offers_every_team_its_menu_and_waits_for_two_magnets_each() -> void:
	var s := _session()
	var v := _open(s)
	assert_eq(v.mode, KpiBoardView.Mode.REVIEW)
	assert_eq(v.pools(), ["intake", "work_prep", "planners", "contact_centre"])
	for pool: String in v.pools():
		assert_eq(v.cards_in(pool).size(), s.catalog.kpis.menus[pool].size(), pool)
	assert_false(v.can_hang(), "no magnets yet")
	assert_eq(v.ruud_line(), s.catalog.kpis.review_question, "Ruud asks the review's question")
	v.pick("intake", "intake_output")
	v.pick("intake", "intake_lead_time")
	v.pick("intake", "intake_oldest")
	assert_eq(v.picks["intake"], ["intake_lead_time", "intake_oldest"], "a third magnet takes the first one's place")
	v.pick("intake", "intake_oldest")
	assert_eq(v.picks["intake"], ["intake_lead_time"], "a click on a magnet takes it off")
	v.free()


func test_hanging_the_choice_runs_the_review_and_shows_the_real_numbers() -> void:
	var s := _session()
	var v := _open(s)
	for pool: String in FLOW:
		for id: String in FLOW[pool]:
			v.pick(pool, id)
	assert_true(v.can_hang())
	var xp := s.xp()
	var result := v.hang_now()
	assert_eq(result.get("error"), "", "the review ran")
	assert_eq(s.region.board.chosen["intake"], PackedStringArray(FLOW["intake"]))
	assert_false(s.region.board.review_due(s.region.net.time), "done for this quarter")
	assert_eq(s.xp(), xp + int(result["xp"]))
	assert_eq(v.mode, KpiBoardView.Mode.RESULT)
	assert_eq(v.cards_in("intake").size(), 2, "only the chosen cards stay up")
	var lead: KpiDef = s.catalog.kpis.defs_for("intake", PackedStringArray(["intake_lead_time"]))[0]
	var days := roundi(KpiReading.value(s.region.net, lead))
	assert_eq(v.number_on("intake", "intake_lead_time"), "%d dagen" % days, "its real number")
	assert_true(v.number_on("contact_centre", "contact_centre_resolved").ends_with("%"))
	var lines := s.catalog.kpis.review_lines
	assert_ne(lines["paid"], "")
	assert_ne(lines["flat"], "")
	assert_eq(v.ruud_line(), lines["paid"] if result["paid"] > 0.0 else lines["flat"])
	v.free()


func test_between_reviews_the_board_shows_the_choice_in_force() -> void:
	var s := _session()
	assert_eq(s.kpi_review(FLOW).get("error", ""), "")
	var v := _open(s)
	assert_eq(v.mode, KpiBoardView.Mode.READ)
	assert_eq(v.cards_in("planners"), ["planners_on_time", "planners_oldest"])
	assert_ne(v.number_on("planners", "planners_on_time"), "")
	assert_eq(v.ruud_line(), s.catalog.kpis.review_lines["read"])
	assert_false(v.can_hang())
	v.free()


func test_closing_without_hanging_changes_nothing() -> void:
	var s := _session()
	var v := _open(s)
	var got := []
	v.closed.connect(func(r: Dictionary) -> void: got.append(r))
	v.pick("intake", "intake_output")
	v.close()
	assert_eq(got, [{}])
	assert_true(s.region.board.review_due(s.region.net.time), "still due: no penalty, no skipping")


func test_numbers_read_as_people_write_them() -> void:
	assert_eq(KpiBoardView.number_text("lead_days_p50", 53.6), "54 dagen")
	assert_eq(KpiBoardView.number_text("on_time", 0.874), "87%")
	assert_eq(KpiBoardView.number_text("done_per_week", 28.04), "28 per week")
	assert_eq(KpiBoardView.number_text("touch_minutes", 15.0), "15 min")


## Review S3 #11: the board writes a number as Ruud says it (one formatter, CoachNumbers.spoken).
func test_the_board_and_ruud_round_alike() -> void:
	assert_eq(KpiBoardView.number_text("done_per_week", 27.5), CoachNumbers.spoken("throughput", 27.5) + " per week")
	assert_eq(KpiBoardView.number_text("on_time", 0.874), CoachNumbers.spoken("on_time", 0.874) + "%")


## Review S3 #11: Esc closes the board by the key's place, whatever the keyboard layout.
func test_esc_closes_the_board_by_its_physical_key() -> void:
	var v := _open(_session())
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	var got := []
	v.closed.connect(func(r: Dictionary) -> void: got.append(r))
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	v._unhandled_key_input(esc)
	assert_eq(got, [{}])


## In the world: the board hangs on Directie & Obeya's wall on the 2e; once it exists,
## E there moves the camera in and opens it, and closing gives the world back with the
## wall showing the choice in force.
func test_the_board_hangs_at_the_directie_obeya_and_opens_there() -> void:
	var office: Office = load("res://src/world/office/office.tscn").instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	var s := office.session
	s.missions.progress["fix_silo_kpis"] = {"status": "completed", "asks": {}, "seen": {}}   # its room opened
	assert_true(office.floors.go_to("second", "lift"))
	assert_ne(office.find_marker(OfficeKpiBoard.NODE), null, "the board hangs on the wall")
	assert_eq(office.interactable(OfficeKpiBoard.ID), null, "no board to use before it exists")
	s.region.board.unlock(s.region.net.time)
	office.reload_rooms()
	var at := office.interactable(OfficeKpiBoard.ID)
	assert_ne(at, null)
	assert_eq(office.prompt_for(at), OfficeKpiBoard.PROMPT)
	office.player.position = at.position
	office.use(at)
	var v := office.kpi_board
	assert_ne(v, null, "the board opened")
	assert_true(office.busy(), "the world waits")
	for pool: String in FLOW:
		for id: String in FLOW[pool]:
			v.pick(pool, id)
	assert_eq(v.hang_now().get("error"), "")
	v.close()
	assert_eq(office.kpi_board, null)
	assert_false(office.busy())
	var wall := office.find_marker(OfficeKpiBoard.NODE)
	var texts := wall.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)
	assert_true(texts.has("Oudste aanvraag in de bak"), "the wall shows the cards hung")
	office.free()
