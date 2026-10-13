class_name PlaceMenu
extends UiPanel
## A team's place: the gemba tools with the time each takes, and the
## questions you can ask. Each one spends simulated time; the results
## (clues, replies, a feeling that something is off) show on the right.

var place := ""
## This visit's results, newest first: [{heading, text}].
var log: Array[Dictionary] = []


func _init() -> void:
	super("", Vector2(1380, 0))


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


func _record(heading: String, text: String) -> void:
	log.push_front({"heading": "%s  —  %s" % [session.clock_text(), heading], "text": text})
	acted.emit()
	refresh()


func refresh() -> void:
	var step := session.region.net.step_at(place)
	title_label.text = step.name if step != null else place
	clear(body)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	body.add_child(columns)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 560
	columns.add_child(actions)
	var tools := add_card(actions, "Gemba: kijk zelf  (de tijd loopt door)")
	var grid := GridContainer.new()
	grid.columns = 2
	tools.add_child(grid)
	for tool: String in Investigation.TOOLS:
		if tool != "conversation":
			var b := button(UiText.tool_label(tool), use_tool.bind(tool))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(b)
	var questions := add_card(actions, "Vraag het team  (%s per gesprek)" % UiText.duration(Investigation.TOOLS["conversation"]["minutes"]))
	for q: String in Investigation.QUESTIONS:
		var b := button(UiText.question(q), ask.bind(q))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		questions.add_child(b)

	var results := add_card(columns, "Wat je ziet en hoort")
	results.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	results.get_parent().custom_minimum_size.x = 680
	if log.is_empty():
		results.add_child(paragraph("Kies een gemba-instrument of stel een vraag. Alles wat je vindt, komt in je aanwijzingen (J).", Palette.MUTED))
	for entry in log.slice(0, 4):
		results.add_child(label(entry["heading"], UiTheme.SMALL, Palette.MUTED))
		results.add_child(paragraph(entry["text"]))
