extends TestCase
## PlaceActions (PLAN 2.12): the tools that fit a place, with its own labels
## and observations, the questions to the people there, and the toolbox that
## grows with the training week.

const INTAKE := "connections.intake"
const ELSEWHERE := "connections.planning"


## As tools/build_content.py writes it: a place's tools as a list, in order.
func _doc() -> Dictionary:
	return {"places": {INTAKE: {
		"people_also": ["ahmed"],
		"tools": [
			{"tool": "listen_in", "label": "Luister mee", "observations": ["Een.", "Twee."]},
			{"tool": "queue_count", "label": "Tel de inbox", "observations": ["Drie.", "Vier."]},
		],
		"questions": [{"id": "walk", "person": "sanne", "text": "Hoe gaat het?", "reply": "Druk."},
			{"id": "thanks", "person": "sanne", "text": "x", "reply": "y"}]}},
		"tool_cards": [{"tool": "shadow", "title": "Meelopen", "text": "Een halve dag."}]}


func test_only_the_listed_tools_fit_a_place_with_an_entry() -> void:
	var p := PlaceActions.from_doc(_doc())
	assert_true(p.fits(INTAKE, "listen_in"))
	assert_false(p.fits(INTAKE, "time_study"), "no stopwatch at the intake desk")
	assert_true(p.fits(ELSEWHERE, "time_study"), "a place without an entry keeps every tool")


func test_the_menu_shows_the_known_fitting_tools_in_content_order() -> void:
	var p := PlaceActions.from_doc(_doc())
	assert_eq(p.tools_at(INTAKE), [] as Array[String], "a new player knows no tool yet")
	p.grant(PackedStringArray(["queue_count", "time_study"]))
	assert_eq(p.tools_at(INTAKE), ["queue_count"] as Array[String])
	p.know_all()
	assert_eq(p.tools_at(INTAKE), ["listen_in", "queue_count"] as Array[String])
	assert_eq(p.label(INTAKE, "queue_count"), "Tel de inbox")
	assert_eq(p.label(ELSEWHERE, "queue_count"), "", "no place label: the UI uses the tool's own")
	assert_false("conversation" in p.tools_at(ELSEWHERE), "a conversation is a question, not a tool button")


func test_observations_cycle_without_repeats_and_each_goes_to_the_journal() -> void:
	var p := PlaceActions.from_doc(_doc())
	assert_eq(p.observe(INTAKE, "listen_in", 3), "Een.")
	assert_eq(p.observe(INTAKE, "listen_in", 3), "Twee.")
	assert_eq(p.observe(INTAKE, "listen_in", 4), "Een.", "all seen: round again")
	assert_eq(p.observe(ELSEWHERE, "data"), "", "no entry, no observation")
	assert_eq(p.journal.size(), 3)
	assert_eq(p.journal[2], {"day": 4, "place": INTAKE, "tool": "listen_in", "text": "Een."})


func test_questions_people_and_tool_cards() -> void:
	var p := PlaceActions.from_doc(_doc())
	assert_eq(p.questions_at(INTAKE).size(), 1, "thanks is never a chip of its own")
	assert_eq(p.question(INTAKE, "walk")["person"], "sanne")
	assert_eq(p.question(INTAKE, "who"), {})
	assert_eq(p.questions_at(ELSEWHERE), [])
	assert_eq(p.people_also(INTAKE), ["ahmed"])
	assert_eq(p.tool_cards["shadow"]["title"], "Meelopen")


func test_the_toolbox_and_the_observations_seen_are_saved() -> void:
	var p := PlaceActions.from_doc(_doc())
	p.grant(PackedStringArray(["listen_in"]))
	p.observe(INTAKE, "listen_in", 1)
	p.repair_due[INTAKE] = "sanne"
	var q := PlaceActions.from_doc(_doc())
	q.load_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(q.tools_at(INTAKE), ["listen_in"] as Array[String])
	assert_eq(q.journal, p.journal)
	assert_eq(q.repair_due, p.repair_due)
	assert_eq(q.observe(INTAKE, "listen_in"), "Twee.", "the cycle survives a save")


func test_an_old_save_without_a_toolbox_knows_every_tool() -> void:
	var p := PlaceActions.from_doc(_doc())
	p.load_dict({})
	assert_eq(p.known.size(), Investigation.TOOLS.size())
	p.load_dict({"tools_known": "rubbish", "observation_seen": [], "journal": [3]})
	assert_eq(p.known.size(), Investigation.TOOLS.size(), "a bad entry reads as an old save")
	assert_eq(p.journal, [] as Array[Dictionary])


func test_a_malformed_document_has_no_entries() -> void:
	var p := PlaceActions.from_doc({"places": "nope"})
	assert_true(p.fits(INTAKE, "time_study"))
	p = PlaceActions.from_doc({"places": {INTAKE: {"tools": [{"tool": "nope"}, {"tool": "conversation"}, 3]}}})
	assert_false(p.fits(INTAKE, "nope"), "an unknown tool is never offered")
	assert_false(p.fits(INTAKE, "conversation"))
