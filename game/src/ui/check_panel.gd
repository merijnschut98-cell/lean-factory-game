class_name CheckPanel
extends UiPanel
## Check and Act: the stream's numbers before and after the experiment,
## what the Check says, then the choice to standardise; after Act, the score
## and the coach's debrief. On the training week's practice problem the
## player can then look a month ahead, with and without the standard (the
## Friday lesson: does the fix hold without one?).

signal back_to_a3

## The stream's numbers in the table, in this order.
const ROWS := ["capacity", "throughput", "wip_age", "lead_time", "first_time_right", "on_time"]
## The stream's flow: what "dit was niet het knelpunt" says did not grow.
const FLOW_ROWS := ["capacity", "throughput"]
## Leading ("Stuurindicator") reacts within the two weeks of the experiment;
## lagging ("Volgindicator") measures finished orders and only moves after
## about one lead time. The one place that classifies the numbers.
const LEADING := "leading"
const LAGGING := "lagging"
const KIND := {
	"capacity": LEADING, "throughput": LEADING, "wip_age": LEADING,
	"lead_time": LAGGING, "first_time_right": LAGGING, "on_time": LAGGING,
}
const KIND_TAGS := {LEADING: "Stuurindicator", LAGGING: "Volgindicator"}
const KIND_GROUPS := {
	LEADING: "Stuurindicatoren: reageren al tijdens het experiment",
	LAGGING: "Volgindicatoren — effect zichtbaar na ±1 doorlooptijd",
}
const LAGGING_NOTE := "Volgindicatoren lopen achter: ze meten werk dat grotendeels vóór je verbetering is gestart."
## The Check's forecast (Region.check's `forecast`): the coming days run
## twice, without and with the player's countermeasure.
const FORECAST_HEADING := "Vooruitblik: de komende %d dagen, twee keer doorgerekend"
const WITHOUT := "Zonder jouw maatregel"
const WITH := "Met jouw maatregel"
const FORECAST_NOTE := "Gemeten over de laatste %d dagen, zodat het werk pas na je verbetering begon. Dezelfde vraag en hetzelfde toeval in beide runs: het verschil is je maatregel."
## A practice problem's fix says nothing about the stream's bottleneck.
const PRACTICE_NOTE := "Dit was een oefenprobleem: wat het voor de hele stroom betekent, telt hier niet."
## The Friday lesson's verdict, by the player's Act (GameSession.fade_forecast):
## a standard slows the slide; only audits and planned routines hold a fix.
const NOT_KEPT := "Jij borgde niet. Zonder standaard valt het team na %s terug in de oude gewoonte: de maand loopt dan zoals \"Zonder borgen\"."
const KEPT := "Jij borgde de verbetering: de standaard remt het wegzakken, ook als het druk wordt. Maar ook een standaard slijt als niemand hem naloopt: zonder audit of vaste routine zakt de verbetering over zo'n %s toch weg. \"Met borgen\" is de maand waarin de standaard gevolgd blijft."
const KEPT_BY_ROUTINE := "Jij borgde de verbetering en een vaste routine loopt de standaard elke week na: zo blijft ze staan. De maand loopt zoals \"Met borgen\"."
const FORECAST_LAGGING := "De doorlooptijd (een volgindicator) laat dit pas na maanden zien: het werk dat deze maand klaar is, ging lang geleden door deze stap."
const SCORE_PARTS := {
	"plan": "Plan: onderzoek op de gemba", "root_cause": "Oorzaak en bewijs", "countermeasure": "Tegenmaatregel",
	"check_act": "Check en Act", "impact": "Impact op de hele stroom",
}

## Shown on her screen while the Check's forecast runs (a few seconds of simulation).
const SIMULATING := "De Check rekent de komende maanden twee keer door, met en zonder jouw maatregel. Even geduld, dat duurt een paar seconden…"

## How far the practice forecast looks ahead.
const FORECAST_DAYS := 30

var problem_id := ""
var result: Dictionary = {}
var score: Dictionary = {}
## GameSession.fade_forecast's result once asked for (empty before).
var forecast: Dictionary = {}


func _init() -> void:
	super("Check", Vector2(1240, 0))
	add_theme_stylebox_override("panel", MonitorScreen.new())


## The problem whose Check waits at Petra's screen: the first accepted mission's problem
## that is ready for its Check or checked and waiting for the Act; "" when none is.
static func due(s: GameSession) -> String:
	for m in s.active_missions():
		if not m.goal_problem.is_empty() and s.phase_of(m.goal_problem) in ["check_ready", "checked"]:
			return m.goal_problem
	return ""


## The note that the Check is simulating, while it runs.
func show_simulating(of_problem: String) -> void:
	problem_id = of_problem
	result = {}
	clear(body)
	title_label.text = "Check"
	title_label.add_theme_color_override("font_color", Palette.VOLTANA_BLUE)
	body.add_child(paragraph(tr(SIMULATING), Palette.VOLTANA_BLUE))


func show_result(of_problem: String, check_result: Dictionary) -> void:
	problem_id = of_problem
	result = check_result
	score = {}
	forecast = {}
	refresh()


## Act: close the problem, standardising or not. Returns the score or
## {"error": code}.
func act(standardise: bool) -> Dictionary:
	score = session.act(problem_id, standardise)
	acted.emit()
	refresh()
	return score


## Look a month ahead on the practice problem, with and without the
## standard (the game itself does not move on). Returns
## GameSession.fade_forecast's result.
func fade_forecast() -> Dictionary:
	forecast = session.fade_forecast(FORECAST_DAYS, problem_id)
	refresh()
	return forecast


## "leading" or "lagging" for a number in the table.
static func kind(row: String) -> String:
	return KIND[row]


## Whether `after` is an improvement on `before` for this number, on a stream
## whose throughput direction is `throughput` (Pdca.direction).
static func improved(row: String, before: float, after: float, throughput := 1) -> bool:
	return Pdca.direction(row, throughput) * (after - before) > 0.0


## Green for better, orange for worse, ink for no change: a change within the Check's noise
## (Pdca.CHECK_NOISE, relative) is no change (gate backlog 3). When the Check found the step
## was `not_constraint`, the flow rows (FLOW_ROWS) read ink whatever they did, so the flow
## never reads green next to "dit was niet het knelpunt" (review 2453246..3c0a190 #4).
static func change_color(row: String, before: float, after: float, throughput := 1, not_constraint := false) -> Color:
	if not_constraint and row in FLOW_ROWS or is_equal_approx(before, after) \
			or before != 0.0 and absf(after - before) / absf(before) < Pdca.CHECK_NOISE:
		return Palette.INK
	return Palette.GREEN_DARK if improved(row, before, after, throughput) else Palette.SAFETY_ORANGE


## The problem's stream: which way its throughput is better, and its name for it.
func _stream() -> ValueStream:
	return session.region.net.stream_of(session.region.problems[problem_id].step)


func refresh() -> void:
	clear(body)
	if result.is_empty() or result.has("error"):
		body.add_child(paragraph("Er is nog geen Check gedaan.", Palette.MUTED))
		return
	var passed: bool = result["passed"]
	title_label.text = "Check geslaagd" if passed else "Check niet geslaagd"
	title_label.add_theme_color_override("font_color", Palette.GREEN_DARK if passed else Palette.SAFETY_ORANGE)

	if not forecast.is_empty():
		_forecast_view()  # the month ahead replaces the Check's table: it was read before
		_score_view()
		return
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	_table(columns)
	var verdict := add_card(columns, "Wat zegt de Check?")
	verdict.get_parent().custom_minimum_size.x = 520
	var own := str(result.get("debrief", ""))   # a designed failed Check speaks in its own words
	for text in own.split("\n\n") if not own.is_empty() else [UiText.lesson(result["lesson"])]:
		verdict.add_child(paragraph(text))
	if result["lesson"] == "mismatch":
		verdict.add_child(paragraph(session.region.problems[problem_id].mismatch_note, Palette.MUTED, UiTheme.SMALL))
	if result["not_constraint"]:
		verdict.add_child(paragraph("Let op: de stap is beter, maar de stroom levert niet meer. Het werk wacht nog op een ander team: dit was niet het knelpunt.", Palette.SAFETY_ORANGE))
	if result.get("forecast") is Dictionary and result["forecast"].has("with"):
		_check_forecast(result["forecast"])

	if not passed:
		body.add_child(button("Terug naar de A3", back_to_a3.emit))
	elif score.is_empty():
		_act_choice()
	else:
		_score_view()


func _table(parent: Node) -> void:
	var box := add_card(parent, "De stroom: voor en na het experiment")
	box.get_parent().custom_minimum_size.x = 620
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var prediction: String = session.region.state[problem_id].a3.get("prediction", "")
	var shown_kind := ""
	for row: String in ROWS:
		if kind(row) != shown_kind:
			shown_kind = kind(row)
			grid.add_child(label(KIND_GROUPS[shown_kind], UiTheme.SMALL, Palette.MUTED))
			for heading in ["Voor", "Na", ""] if shown_kind == LEADING else ["", "", ""]:
				grid.add_child(label(heading, UiTheme.SMALL, Palette.MUTED))
		var before: float = result["before"][row]
		var after: float = result["after"][row]
		var name := UiText.kpi(row, _stream()) + ("   (jouw voorspelling)" if row == prediction else "")
		grid.add_child(label(name, UiTheme.SMALL, Palette.VOLTANA_BLUE if row == prediction else Palette.INK))
		_add_before_after(grid, row, before, after)
	box.add_child(paragraph(LAGGING_NOTE, Palette.MUTED, UiTheme.SMALL))


## The Check's two runs, one row each, over the stream's numbers: the
## predicted KPI first.
func _check_forecast(f: Dictionary) -> void:
	var card := add_card(body, FORECAST_HEADING % f["days"])
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	card.add_child(grid)
	var predicted: String = f.get("kpi", "")
	var rows: Array = ROWS.filter(func(r: String) -> bool: return r != predicted)
	if f["with"].has(predicted):
		rows.push_front(predicted)
	grid.columns = rows.size() + 1
	grid.add_child(label(""))
	for row: String in rows:
		var name := label(UiText.kpi(row, _stream()), 15, Palette.VOLTANA_BLUE if row == predicted else Palette.MUTED, true)
		name.custom_minimum_size.x = 150
		name.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		grid.add_child(name)
	var throughput := _stream().throughput_direction
	for run: String in ["without", "with"]:
		grid.add_child(label(WITHOUT if run == "without" else WITH, UiTheme.SMALL))
		for row: String in rows:
			var without: float = f["without"][row]
			var value: float = f[run][row]
			grid.add_child(label(UiText.kpi_value(row, value), UiTheme.SMALL,
				change_color(row, without, value, throughput, result["not_constraint"])))
	card.add_child(paragraph(FORECAST_NOTE % f.get("window", f["days"]), Palette.MUTED, 15))


## A row's before, after (green better, orange worse) and its tag.
func _add_before_after(grid: GridContainer, row: String, before: float, after: float) -> void:
	grid.add_child(label(UiText.kpi_value(row, before)))
	var colour := change_color(row, before, after, _stream().throughput_direction, result["not_constraint"])
	grid.add_child(label(UiText.kpi_value(row, after), UiTheme.FONT_SIZE, colour))
	grid.add_child(label(KIND_TAGS[kind(row)], UiTheme.SMALL, Palette.MUTED))


func _act_choice() -> void:
	var act_card := add_card(body, "Act: wat doe je met de verbetering?")
	act_card.add_child(paragraph("Standaardiseren kost %s: werkinstructie, training en borging in het dagstart-bord. Zonder standaard kan de verbetering na verloop van tijd wegzakken." % UiText.money(Region.STANDARDISE_BUDGET)))
	var row := HBoxContainer.new()
	row.add_child(button("Standaardiseren", act.bind(true)))
	row.add_child(button("Niet standaardiseren", act.bind(false)))
	act_card.add_child(row)


func _score_view() -> void:
	if score.has("error"):
		body.add_child(paragraph(UiText.a3_error(score["error"]), Palette.SAFETY_ORANGE))
		return
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	var parts := add_card(columns, "Je score: %d van de %d" % [score["total"], Pdca.MAX_SCORE])
	for key: String in SCORE_PARTS:
		parts.add_child(label("%s:  %d / 5" % [SCORE_PARTS[key], score[key]], UiTheme.SMALL))
	var notes := add_card(columns, "Om van te leren")
	var practice := session.is_practice(problem_id)
	for note: String in shown_notes(score["notes"], practice):
		notes.add_child(paragraph("• " + UiText.score_note(note), Palette.INK, UiTheme.SMALL))
	if practice:
		notes.add_child(paragraph("• " + PRACTICE_NOTE, Palette.MUTED, UiTheme.SMALL))
	for m: MissionDef in session.missions.defs.values():
		if m.goal_problem == problem_id and m.goal_type == "solve" and session.missions.status(m.id) == "completed":
			var debrief := add_card(body, session.catalog.coach.get("name", "Coach"), Palette.BLUE_PALE)
			debrief.add_child(paragraph("'%s'" % session.mission_debrief(m.id)))
	if practice and forecast.is_empty():
		_forecast_view()


## The score's notes to show: a practice problem's impact notes go (after
## the training's staged course its step can read as the bottleneck, which
## says nothing about the real stream).
static func shown_notes(notes: Array, practice: bool) -> Array:
	return notes.filter(func(n: String) -> bool: return not (practice and n.begins_with("impact_")))


## The Friday lesson: a button to look ahead, then the month with and
## without the standard side by side: the KPI the problem names and the
## queue at its step, both leading indicators.
func _forecast_view() -> void:
	if forecast.is_empty():
		var row := HBoxContainer.new()
		row.add_child(button("Kijk %d dagen vooruit" % FORECAST_DAYS, fade_forecast))
		row.add_child(label("  Wat doet je verbetering in een maand, met en zonder borgen?", UiTheme.SMALL, Palette.MUTED))
		body.add_child(row)
		return
	if forecast.has("error"):
		body.add_child(paragraph(UiText.a3_error(forecast["error"]), Palette.SAFETY_ORANGE))
		return
	var card := add_card(body, "Over %d dagen: met en zonder borgen" % FORECAST_DAYS)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	card.add_child(grid)
	for heading in ["", "Met borgen", "Zonder borgen", ""]:
		grid.add_child(label(heading, UiTheme.SMALL, Palette.MUTED))
	var kpi: String = forecast["kpi"]
	grid.add_child(label(UiText.kpi(kpi, _stream()) + "   (jouw voorspelling)", UiTheme.SMALL, Palette.VOLTANA_BLUE))
	_add_before_after(grid, kpi, forecast["held"][kpi], forecast["faded"][kpi])
	var held_queue: Dictionary = forecast["held"]["queue"]
	var faded_queue: Dictionary = forecast["faded"]["queue"]
	grid.add_child(label("Wachtrij bij " + session.region.net.step_at(forecast["place"]).name, UiTheme.SMALL))
	grid.add_child(label(UiText.queue(held_queue)))
	grid.add_child(label(UiText.queue(faded_queue), UiTheme.FONT_SIZE,
		Palette.SAFETY_ORANGE if faded_queue["days"] > held_queue["days"] else Palette.INK))
	grid.add_child(label(KIND_TAGS[LEADING], UiTheme.SMALL, Palette.MUTED))
	card.add_child(paragraph(forecast_verdict(forecast),
		Palette.GREEN_DARK if forecast["standardised"] else Palette.SAFETY_ORANGE))
	card.add_child(paragraph(FORECAST_LAGGING, Palette.MUTED, UiTheme.SMALL))


## The Friday verdict for a fade_forecast: without a standard the fix fades
## after fade_days; with one it slows down and fades after recur_days, unless
## a routine holds it (recur_days INF).
static func forecast_verdict(f: Dictionary) -> String:
	if not f["standardised"]:
		return NOT_KEPT % UiText.period(f["fade_days"])
	var recur: float = f["recur_days"]
	return KEPT_BY_ROUTINE if is_inf(recur) else KEPT % UiText.period(roundi(recur))


## Every text on the panel, for tests.
func shown_texts() -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [body]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label:
			out.append(n.text)
		stack.append_array(n.get_children())
	return out
