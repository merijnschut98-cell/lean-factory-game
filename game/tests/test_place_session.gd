extends TestCase
## Place actions in play (PLAN 2.12, Merijn's playtest 2026-10-18; spec
## docs/superpowers/specs/2026-10-18-place-actions.md §7): only the tools that
## fit a place, a real observation where a tool finds no clue, questions to
## the people who are there, and a toolbox that grows with the training week.
## Real content (content/places.yaml).

const INTAKE := "connections.intake"
const DESIGN := "connections.design"
const WEEK: Array[String] = ["training_mon", "training_tue", "training_wed", "training_thu", "training_fri"]


func _training() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	assert_eq(s.error, "")
	return s


func _campaign() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, false)


## A training game whose toolbox holds what the week grants up to `last`.
func _known_through(last: String) -> GameSession:
	var s := _training()
	for id in WEEK.slice(0, WEEK.find(last) + 1):
		s.gemba.grant(s.missions.defs[id].grant_tools)
	return s


func test_the_menu_grows_with_the_week_and_shows_only_what_fits() -> void:
	var expected := {
		"training_mon": {INTAKE: [], DESIGN: []},
		"training_tue": {INTAKE: ["documents"], DESIGN: ["shadow", "documents"]},
		"training_wed": {INTAKE: ["documents", "queue_count"], DESIGN: ["shadow", "documents", "queue_count"]},
		"training_thu": {INTAKE: ["listen_in", "documents", "queue_count", "data"],
			DESIGN: ["shadow", "documents", "queue_count", "time_study", "data"]},
	}
	for day: String in expected:
		var s := _known_through(day)
		for place: String in expected[day]:
			assert_eq(s.place_tools(place), Array(expected[day][place], TYPE_STRING, "", null), "%s at %s" % [day, place])
	assert_eq(_training().place_tools(INTAKE), [] as Array[String], "Monday: people and questions only")


func test_monday_at_intake_sanne_answers_in_her_own_words() -> void:
	var s := _training()
	assert_true("sanne" in s.people_to_ask(INTAKE), "someone to talk to at Intake on Monday")
	var result := s.ask(INTAKE, "walk")
	assert_eq(result["person"], "sanne")
	assert_eq(result["line"], s.gemba.question(INTAKE, "walk")["reply"])
	assert_false(UiText.reply(result, "Sanne").is_empty())


func test_every_tool_at_every_place_shows_something_when_no_clue_is_ready() -> void:
	var s := _campaign()
	for place: String in s.gemba.places:
		for tool in s.place_tools(place):
			var result := s.use_tool(place, tool)
			assert_false(result.has("error"), "%s at %s: %s" % [tool, place, result])
			assert_true(result["observation"] is String and not result["observation"].is_empty(), "%s at %s" % [tool, place])
			assert_false(UiText.tool_result(result).is_empty())


func test_an_observation_cycle_shows_every_line_once_and_survives_a_save() -> void:
	var s := _campaign()
	var lines: Array = s.gemba.places[INTAKE]["tools"]["listen_in"]["observations"]
	var seen: Array = []
	for i in lines.size():
		seen.append(s.use_tool(INTAKE, "listen_in")["observation"])
	assert_eq(seen, lines, "no line repeats before all were seen")
	assert_eq(s.gemba.journal.size(), lines.size(), "each use writes one Waarneming")
	assert_true(ClueJournal.by_place(s)[0]["seen"].size() == lines.size())
	var slot := "test_place_session_%d" % OS.get_process_id()
	s.use_tool(INTAKE, "listen_in")
	assert_eq(GameSave.write(slot, s, SessionLayer.new()), "")
	var loaded: GameSession = GameSave.read(slot)["session"]
	DirAccess.remove_absolute(SaveFile.path_of(slot))
	assert_eq(loaded.use_tool(INTAKE, "listen_in")["observation"], lines[1], "the cycle goes on after a load")
	assert_eq(loaded.gemba.journal.size(), lines.size() + 2)


func test_a_tool_that_does_not_fit_or_is_not_known_yet_is_refused_without_cost() -> void:
	var s := _known_through("training_tue")
	var before := s.region.net.time
	assert_eq(s.use_tool(INTAKE, "time_study"), {"error": "tool_not_here"})
	assert_eq(s.use_tool(DESIGN, "data"), {"error": "tool_not_known"}, "Tuesday: data comes on Thursday")
	assert_eq(s.region.net.time, before)


func test_a_clue_wins_over_an_observation_at_its_cost() -> void:
	var s := _campaign()
	assert_eq(s.accept("fix_custom_design"), "")
	var problem: ProblemDef = s.region.problems["custom_design"]
	var first: Clue = null
	for c in problem.clues:
		if first == null and c.depth == 0 and c.dialog.is_empty() and c.tool != "conversation":
			first = c
	var before := s.region.net.time
	var result := s.use_tool(first.at, first.tool)
	assert_false(result["clues"].is_empty())
	assert_false(result.has("observation"))
	assert_eq(s.region.net.time - before, Investigation.TOOLS[first.tool]["minutes"], "the time cost stays")


func test_only_the_places_questions_can_be_asked_and_thanks_after_a_blame() -> void:
	var s := _campaign()
	assert_eq(s.ask(INTAKE, "who"), {"error": "unknown_question"}, "not one of Intake's questions")
	assert_eq(s.ask(INTAKE, "thanks"), {"error": "unknown_question"}, "nothing to make up for yet")
	var blamed := s.ask(INTAKE, "behind")
	assert_eq(blamed["reply"], "blame")
	assert_eq(blamed["line"], s.gemba.question(INTAKE, "behind")["reply"], "she answers in her own words")
	assert_true(s.place_questions(INTAKE).any(func(q: Dictionary) -> bool: return q["id"] == "thanks"),
		"a thanks chip under Sanne")
	assert_eq(s.ask(INTAKE, "thanks")["person"], "sanne")
	assert_false(s.place_questions(INTAKE).any(func(q: Dictionary) -> bool: return q["id"] == "thanks"))


func test_people_met_elsewhere_can_be_asked_there() -> void:
	var s := _campaign()
	assert_true("ahmed" in s.people_to_ask("connections.commissioning"))
	assert_eq(s.ask("connections.commissioning", "walk")["person"], "ahmed")


func test_monday_is_met_by_asking_at_both_places() -> void:
	var s := _training()
	s.ask(INTAKE, "walk")
	s.ask(DESIGN, "walk")
	assert_eq(s.missions.progress["training_mon"]["seen"].size(), 2, "a question counts as looking at both places")


func test_the_toolbox_grows_day_by_day_and_a_skip_or_an_old_save_knows_all() -> void:
	var s := _training()
	assert_eq(s.gemba.known.keys(), ["conversation"], "Monday: questions only")
	assert_eq(s.skip_training(), "")
	assert_eq(s.gemba.known.size(), Investigation.TOOLS.size(), "a skip of the week grants all eight")
	assert_eq(_campaign().gemba.known.size(), Investigation.TOOLS.size(), "a returning player")
	var fresh := _training()
	fresh.gemba.load_dict({})
	assert_eq(fresh.gemba.known.size(), Investigation.TOOLS.size(), "a save from before the toolbox")


func test_a_training_day_names_the_tools_it_hands_out_with_their_cards() -> void:
	var s := _training()
	assert_eq(s.new_tools("training_wed"), PackedStringArray(["queue_count"]))
	assert_eq(s.tool_card("queue_count")["title"], "Wachtrij tellen")
	assert_eq(s.new_tools("nope"), PackedStringArray())
