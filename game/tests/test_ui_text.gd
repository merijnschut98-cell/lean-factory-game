extends TestCase
## UiText: the Dutch words for the rules' codes. Every code the rules can
## return has words, and the words give nothing away (no marked answers).


func test_every_tool_question_waste_and_kpi_has_dutch_words() -> void:
	for tool: String in Investigation.TOOLS:
		assert_false(UiText.tool_name(tool).is_empty(), tool)
	for q: String in Investigation.QUESTIONS:
		assert_false(UiText.question(q).is_empty(), q)
	for w: String in Investigation.WASTES:
		assert_false(UiText.waste(w).is_empty(), w)
	for k: String in Investigation.KPIS:
		assert_false(UiText.kpi(k).is_empty(), k)
	for b: Dictionary in Progression.BELTS:
		assert_false(UiText.belt(b["id"]).is_empty(), b["id"])


func test_questions_do_not_say_what_kind_they_are() -> void:
	for q: String in Investigation.QUESTIONS:
		var text := UiText.question(q).to_lower()
		for kind in ["open", "gesloten", "blame", "schuld", "herstel"]:
			assert_false(text.begins_with(kind), "%s: %s" % [q, text])


func test_durations_read_as_dutch() -> void:
	assert_eq(UiText.duration(30), "30 min")
	assert_eq(UiText.duration(60), "1 uur")
	assert_eq(UiText.duration(90), "1,5 uur")
	assert_eq(UiText.duration(240), "4 uur")
	assert_eq(UiText.tool_label("time_study"), "Tijdstudie (2 uur)")


func test_money_uses_dutch_thousands() -> void:
	assert_eq(UiText.money(50000), "€ 50.000")
	assert_eq(UiText.money(3000), "€ 3.000")
	assert_eq(UiText.money(950), "€ 950")
	assert_eq(UiText.money(-1250000), "€ -1.250.000")


func test_a_tool_result_lists_its_clues() -> void:
	var clue := Clue.new()
	clue.text = "Driekwart is standaard."
	var text := UiText.tool_result({"spotted": [], "clues": [clue], "hidden_signal": false})
	assert_true(text.contains("Driekwart is standaard."))
	assert_eq(UiText.tool_result({"spotted": [], "clues": [], "hidden_signal": true}), UiText.HIDDEN_SIGNAL,
		"a hidden problem leaves a feeling that something is off")


func test_a_tool_result_without_a_clue_shows_the_places_observation_and_the_feeling() -> void:
	var text := UiText.tool_result({"spotted": [], "clues": [], "hidden_signal": true, "observation": "De inbox loopt vol."})
	assert_true(text.contains("De inbox loopt vol."))
	assert_true(text.contains(UiText.HIDDEN_SIGNAL), "the hidden signal stays")
	assert_eq(UiText.tool_result({"spotted": [], "clues": [], "hidden_signal": false, "observation": "Rustig."}),
		"Rustig.")


func test_a_place_names_its_tools_its_own_way_with_the_time_they_take() -> void:
	assert_eq(UiText.place_tool("Tel de inbox", "queue_count"), "Tel de inbox (30 min)")
	assert_eq(UiText.place_tool("", "queue_count"), UiText.tool_label("queue_count"))
	for code in ["tool_not_here", "tool_not_known"]:
		assert_ne(UiText.place_error(code), code)


func test_a_person_asked_answers_in_their_own_words() -> void:
	var said := {"kind": "open", "reply": "observation", "trust": 0, "person": "sanne", "line": "\"Kijk.\"",
		"observation": {"kind": "queue", "value": 8}}
	assert_eq(UiText.reply(said, "Sanne"), "Sanne: \"Kijk.\"\n" + UiText.observation(said["observation"]),
		"an open question: their line, then what the team sees")
	assert_eq(UiText.reply({"reply": "closed", "line": "\"Ja.\""}, "Linda"), "Linda: \"Ja.\"")
	assert_eq(UiText.reply({"reply": "guarded"}, "Linda"), "Linda: " + UiText.REPLIES["guarded"])
	assert_eq(UiText.reply({"reply": "guarded"}), UiText.REPLIES["guarded"], "the team, unnamed")


func test_every_reply_and_refusal_has_words() -> void:
	for reply in ["closed", "blame", "guarded", "repair", "welcome", "nobody"]:
		assert_false(UiText.reply({"reply": reply}).is_empty(), reply)
	assert_true(UiText.reply({"reply": "observation", "observation": {"kind": "queue", "value": 42}}).contains("42"))
	for code in ["not_spotted", "waste", "cause", "evidence", "countermeasure", "prediction"]:
		assert_false(UiText.a3_error(code).is_empty(), code)
	for code in ["unknown", "not_available", "locked", "main_active", "side_full", "problem_unavailable"]:
		assert_false(UiText.accept_error(code).is_empty(), code)
	for code in ["unknown_tool", "use_ask", "unknown_place", "unknown_question"]:
		assert_ne(UiText.place_error(code), code, code)
	for kind in ["no_main", "not_main"]:
		assert_false(UiText.coach_reply({"kind": kind}).is_empty(), kind)
	for note in ["coverage", "not_scouted", "blamed", "herrings_linked", "thin_evidence", "cause_wrong", "waste_wrong",
			"failed_checks", "prediction_wrong", "not_standardised", "impact_constraint_small", "impact_not_constraint",
			"impact_good"]:
		assert_false(UiText.score_note(note).is_empty(), note)
	for lesson in ["cause_right", "cause_wrong", "mismatch", "too_early"]:
		assert_false(UiText.lesson(lesson).is_empty(), lesson)


func test_kpi_values_have_units() -> void:
	assert_eq(UiText.kpi_value("throughput", 12.34), "12,3 /week")
	assert_eq(UiText.kpi_value("lead_time", 41.6), "42 dagen")
	assert_eq(UiText.kpi_value("first_time_right", 0.873), "87%")
	assert_eq(UiText.kpi_value("wip_age", 3.0), "3 dagen")
