class_name PlaceMenu
extends UiPanel
## A team's place, as a narrow panel at the right so the station the camera
## frames stays in view: what you saw and heard (newest first), the people
## who work here (a talk, and the questions you can ask them), the gemba
## tools that fit the work here and that you know, by the place's own words
## (PLAN 2.12: what does not fit is not shown), and the leader routines where
## a standardised fix is held. Each one spends simulated time; the results
## (clues, answers, what you see, a feeling that something is off) show at
## the top. A place without a block in content/places.yaml keeps every tool
## and the team's short questions.

## Narrow enough to leave the framed station visible at 1600 × 900.
const WIDTH := 540
const PEOPLE_HEADING := "Mensen hier"
const TALK := "Praat met %s"
const NOTHING_TO_SAY := "heeft nu niets met je te bespreken"
const WANTS_A_WORD := "  (kan wel een goed gesprek gebruiken)"
## The team's questions, named apart from a talk with a person (U18).
const QUESTIONS := "Korte vragen aan het team  (%s per vraag)"
## A question to a person here (content/places.yaml), under their name.
const ASK_PERSON := "\"%s\""
const TOOLS_HEADING := "Kijk zelf  (de tijd loopt door)"

## A person here was asked for a talk (GameUI opens the dialog).
signal talk_requested(person_id: String)

var place := ""
## This visit's results, newest first: [{heading, text}].
var log: Array[Dictionary] = []


func _init() -> void:
	super("", Vector2(WIDTH, 0))
	docked = true


func open_at(at_place: String) -> void:
	if at_place != place:
		log.clear()
	place = at_place
	refresh()


## Use a gemba tool here. Returns the Dutch result text.
func use_tool(tool: String) -> String:
	var result := session.use_tool(place, tool)
	var text: String = UiText.tool_result(result) if not result.has("error") else UiText.place_error(result["error"])
	return _record(UiText.place_tool(session.gemba.label(place, tool), tool), text)


## Ask a question here: to its person where the place has questions, else
## to the team. Returns the Dutch reply.
func ask(question_id: String) -> String:
	var said := _said(question_id)
	var result := session.ask(place, question_id)
	if result.has("error"):
		return _record("Jij: \"%s\"" % said, UiText.place_error(result["error"]))
	var person: PersonDef = session.people.persons.get(result.get("person", ""))
	return _record("Jij: \"%s\"" % said, UiText.reply(result, person.short if person != null else ""))


## What the player says: the place's own words for the question, or the team question's.
func _said(question_id: String) -> String:
	var q := session.gemba.question(place, question_id)
	return session.fill_tokens(tr(q["text"])) if not q.is_empty() else UiText.question(question_id)


## The leader routines that apply here: an audit and a routine where a
## standardised fix is held, stopping the routine where one runs.
func sustain_actions() -> Array[String]:
	var out: Array[String] = []
	var running := place in session.routines()
	if SustainView.fixes(session, place).any(func(id: String) -> bool: return session.sustain_of(id)["standardised"]):
		out.append("audit")
		if not running:
			out.append("plan_routine")
	if running:
		out.append("stop_routine")
	return out


## Audit the standard here (an hour). Returns the Dutch result.
func audit() -> String:
	var result := session.audit(place)
	var text: String = UiText.place_error(result["error"]) if result.has("error") \
		else UiText.audit_result(result, UiText.problem_names(session))
	_record(UiText.AUDIT_HEADING, text)
	return text


## Write the standard for a fix held here (an hour, Region.STANDARDISE_BUDGET):
## "" or the refusal code; the result shows at the top.
func standardise(problem_id: String) -> String:
	var refused := session.standardise(problem_id)
	_record(session.region.problems[problem_id].name if session.region.problems.has(problem_id) else problem_id,
		UiText.place_error(refused) if not refused.is_empty() else tr(UiText.STANDARDISED))
	return refused


## Plan a weekly routine here. Returns the Dutch result.
func plan_routine() -> String:
	var refused := session.plan_routine(place)
	return _record_routine(refused, UiText.ROUTINE_PLANNED)


## Stop the routine here. Returns the Dutch result.
func stop_routine() -> String:
	var refused := session.stop_routine(place)
	return _record_routine(refused, UiText.ROUTINE_STOPPED)


func _record_routine(refused: String, done: String) -> String:
	var text := UiText.place_error(refused) if not refused.is_empty() else done % UiText.routine_hours()
	_record(UiText.ROUTINE_HEADING, text)
	return text


func _record(heading: String, text: String) -> String:
	log.push_front({"heading": "%s  —  %s" % [session.clock_text(), heading], "text": text})
	acted.emit()
	refresh()
	return text


func refresh() -> void:
	var step := session.region.net.step_at(place)
	title_label.text = step.name if step != null else place
	clear(body)
	# One column that scrolls: the panel keeps the full height at the side.
	var column := add_scroll_list(body)
	_results(column)
	_people(column)
	_tools(column)
	_sustain(column)
	if not session.gemba.has_place(place):
		_questions(column)


func _results(parent: Node) -> void:
	var results := add_card(parent, "Wat je ziet en hoort")
	if log.is_empty():
		results.add_child(paragraph("Kies een gemba-instrument of stel een vraag. Alles wat je vindt, komt in je aanwijzingen (J).",
			Palette.MUTED, UiTheme.SMALL))
	for entry in log.slice(0, 3):
		var heading := label(entry["heading"], UiTheme.SMALL, Palette.MUTED)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # a question's words can be long: keep the panel narrow
		results.add_child(heading)
		results.add_child(paragraph(entry["text"], Palette.INK, UiTheme.SMALL))


## The people here, first: whoever works here or can be met here, each with
## a talk when one is open (a mission's, or a check-in), the bank's "Niet
## nu." after a ruined one, and the questions they answer (a conversation's
## time each; "thanks" after a blame or a guarded reply).
func _people(parent: Node) -> void:
	var here := session.people_at(place)
	for id in session.people_to_ask(place):
		if not here.any(func(p: Dictionary) -> bool: return p["id"] == id):
			here.append({"id": id, "name": session.people.persons[id].name, "cooling_down": false, "has_dialog": false,
				"needs_talk": false})
	if here.is_empty():
		return
	var card := add_card(parent, PEOPLE_HEADING)
	var special := JsonFile.dict_or_empty(session.catalog.dialog_bank.get("special"))
	var questions := session.place_questions(place)
	for p in here:
		var asks := questions.filter(func(q: Dictionary) -> bool: return q["person"] == p["id"])
		if p["cooling_down"]:
			card.add_child(label("%s: \"%s\"" % [p["name"], special.get("cooling_down", "")], UiTheme.SMALL, Palette.MUTED))
			continue
		card.add_child(label(p["name"], UiTheme.SMALL, Palette.VOLTANA_BLUE if not asks.is_empty() or p["has_dialog"]
			else Palette.MUTED))
		for q: Dictionary in asks:
			card.add_child(_small_button(tr(ASK_PERSON) % _said(q["id"]), ask.bind(q["id"])))
		if p["has_dialog"]:
			card.add_child(_small_button((tr(TALK) % p["name"]) + (tr(WANTS_A_WORD) if p["needs_talk"] else ""),
				talk_requested.emit.bind(p["id"])))
		elif asks.is_empty():
			card.add_child(label(tr(NOTHING_TO_SAY), UiTheme.SMALL, Palette.MUTED))


## The tools that fit the work here and that the player knows, by the
## place's own words; none known yet: no card.
func _tools(parent: Node) -> void:
	var known := session.place_tools(place)
	if known.is_empty():
		return
	var tools := add_card(parent, tr(TOOLS_HEADING))
	for tool in known:
		tools.add_child(_small_button(UiText.place_tool(session.gemba.label(place, tool), tool), use_tool.bind(tool)))


## The fixes held here and the routines that apply (none: no card).
func _sustain(parent: Node) -> void:
	var actions := sustain_actions()
	var fixes := SustainView.fixes(session, place)
	if actions.is_empty() and fixes.is_empty():
		return
	var card := add_card(parent, "Borging op deze plek")
	for id in fixes:
		SustainView.add_fix(card, session, id, false)
		if not session.sustain_of(id)["standardised"]:
			card.add_child(_small_button(tr(UiText.STANDARDISE_BUTTON) % UiText.money(Region.STANDARDISE_BUDGET),
				standardise.bind(id)))
	var labels := {
		"audit": UiText.AUDIT_BUTTON % UiText.duration(Sustain.AUDIT_MINUTES),
		"plan_routine": UiText.PLAN_BUTTON % UiText.routine_hours(),
		"stop_routine": UiText.STOP_BUTTON % UiText.routine_hours(),
	}
	for action in actions:
		card.add_child(_small_button(labels[action], Callable(self, action)))


func _questions(parent: Node) -> void:
	var questions := add_card(parent, tr(QUESTIONS) % UiText.duration(Investigation.TOOLS["conversation"]["minutes"]))
	for q: String in Investigation.QUESTIONS:
		questions.add_child(_small_button(UiText.question(q), ask.bind(q)))


## A left-aligned button in the small type of this narrow panel, wrapping
## long words rather than widening it.
static func _small_button(text: String, on_press: Callable) -> Button:
	var b := button(text, on_press)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	return b
