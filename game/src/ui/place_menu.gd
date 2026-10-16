class_name PlaceMenu
extends UiPanel
## A team's place, as a narrow panel at the right so the station the camera
## frames stays in view: what you saw and heard (newest first), the gemba
## tools with the time each takes, the leader routines where a standardised
## fix is held, and the questions you can ask. Each one spends simulated
## time; the results (clues, replies, a feeling that something is off) show
## at the top.

## Narrow enough to leave the framed station visible at 1600 × 900.
const WIDTH := 540
const PEOPLE_HEADING := "Mensen hier"
const TALK := "Praat met %s"
const NOTHING_TO_SAY := "heeft nu niets met je te bespreken"
const WANTS_A_WORD := "  (kan wel een goed gesprek gebruiken)"

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
	_record(UiText.tool_label(tool), text)
	return text


## Ask the team here a question. Returns the Dutch reply.
func ask(question_id: String) -> String:
	var result := session.ask(place, question_id)
	var text: String = UiText.reply(result) if not result.has("error") else UiText.place_error(result["error"])
	_record("Jij: \"%s\"" % UiText.question(question_id), text)
	return text


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


func _record(heading: String, text: String) -> void:
	log.push_front({"heading": "%s  —  %s" % [session.clock_text(), heading], "text": text})
	acted.emit()
	refresh()


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
	_questions(column)


func _results(parent: Node) -> void:
	var results := add_card(parent, "Wat je ziet en hoort")
	if log.is_empty():
		results.add_child(paragraph("Kies een gemba-instrument of stel een vraag. Alles wat je vindt, komt in je aanwijzingen (J).",
			Palette.MUTED, UiTheme.SMALL))
	for entry in log.slice(0, 3):
		results.add_child(label(entry["heading"], UiTheme.SMALL, Palette.MUTED))
		results.add_child(paragraph(entry["text"], Palette.INK, UiTheme.SMALL))


## The people who work here: a talk with whoever has something to say (a
## mission's, or a check-in), the bank's "Niet nu." after a ruined one.
func _people(parent: Node) -> void:
	var here := session.people_at(place)
	if here.is_empty():
		return
	var card := add_card(parent, PEOPLE_HEADING)
	var special := JsonFile.dict_or_empty(session.catalog.dialog_bank.get("special"))
	for p in here:
		if p["cooling_down"]:
			card.add_child(label("%s: \"%s\"" % [p["name"], special.get("cooling_down", "")], UiTheme.SMALL, Palette.MUTED))
		elif p["has_dialog"]:
			card.add_child(_small_button((TALK % p["name"]) + (WANTS_A_WORD if p["needs_talk"] else ""),
				talk_requested.emit.bind(p["id"])))
		else:
			card.add_child(label("%s %s" % [p["name"], NOTHING_TO_SAY], UiTheme.SMALL, Palette.MUTED))


func _tools(parent: Node) -> void:
	var tools := add_card(parent, "Gemba: kijk zelf  (de tijd loopt door)")
	var grid := GridContainer.new()
	grid.columns = 2
	tools.add_child(grid)
	for tool: String in Investigation.TOOLS:
		if tool != "conversation":
			var b := button(UiText.tool_label(tool), use_tool.bind(tool))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", UiTheme.SMALL)
			grid.add_child(b)


## The fixes held here and the routines that apply (none: no card).
func _sustain(parent: Node) -> void:
	var actions := sustain_actions()
	if actions.is_empty():
		return
	var card := add_card(parent, "Borging op deze plek")
	for id in SustainView.fixes(session, place):
		SustainView.add_fix(card, session, id, false)
	var labels := {
		"audit": UiText.AUDIT_BUTTON % UiText.duration(Sustain.AUDIT_MINUTES),
		"plan_routine": UiText.PLAN_BUTTON % UiText.routine_hours(),
		"stop_routine": UiText.STOP_BUTTON % UiText.routine_hours(),
	}
	for action in actions:
		card.add_child(_small_button(labels[action], Callable(self, action)))


func _questions(parent: Node) -> void:
	var questions := add_card(parent, "Vraag het team  (%s per gesprek)" % UiText.duration(Investigation.TOOLS["conversation"]["minutes"]))
	for q: String in Investigation.QUESTIONS:
		var b := _small_button(UiText.question(q), ask.bind(q))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		questions.add_child(b)


## A left-aligned button in the small type of this narrow panel.
static func _small_button(text: String, on_press: Callable) -> Button:
	var b := button(text, on_press)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	return b
