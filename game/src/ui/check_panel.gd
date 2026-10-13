class_name CheckPanel
extends UiPanel
## Check and Act: the stream's numbers before and after the experiment,
## what the Check says, then the choice to standardise; after Act, the score
## and the coach's debrief.

signal back_to_a3

## The stream's numbers in the table, in this order.
const ROWS := ["capacity", "throughput", "lead_time", "first_time_right", "on_time", "wip_age"]
## Numbers where lower is better.
const LOWER_IS_BETTER := ["lead_time", "wip_age"]
const SCORE_PARTS := {
	"plan": "Plan: onderzoek op de gemba", "root_cause": "Oorzaak en bewijs", "countermeasure": "Tegenmaatregel",
	"check_act": "Check en Act", "impact": "Impact op de hele stroom",
}

var problem_id := ""
var result: Dictionary = {}
var score: Dictionary = {}


func _init() -> void:
	super("Check", Vector2(1240, 0))


func show_result(of_problem: String, check_result: Dictionary) -> void:
	problem_id = of_problem
	result = check_result
	score = {}
	refresh()


## Act: close the problem, standardising or not. Returns the score or
## {"error": code}.
func act(standardise: bool) -> Dictionary:
	score = session.act(problem_id, standardise)
	acted.emit()
	refresh()
	return score


## Whether `after` is an improvement on `before` for this number.
static func improved(row: String, before: float, after: float) -> bool:
	return after < before if row in LOWER_IS_BETTER else after > before


func refresh() -> void:
	clear(body)
	if result.is_empty() or result.has("error"):
		body.add_child(paragraph("Er is nog geen Check gedaan.", Palette.MUTED))
		return
	var passed: bool = result["passed"]
	title_label.text = "Check geslaagd" if passed else "Check niet geslaagd"
	title_label.add_theme_color_override("font_color", Palette.GREEN_DARK if passed else Palette.SAFETY_ORANGE)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	_table(columns)
	var verdict := add_card(columns, "Wat zegt de Check?")
	verdict.get_parent().custom_minimum_size.x = 520
	verdict.add_child(paragraph(UiText.lesson(result["lesson"])))
	if result["lesson"] == "mismatch":
		verdict.add_child(paragraph(session.region.problems[problem_id].mismatch_note, Palette.MUTED, UiTheme.SMALL))
	if result["not_constraint"]:
		verdict.add_child(paragraph("Let op: de stap is beter, maar de stroom levert niet meer. Het werk wacht nog op een ander team: dit was niet het knelpunt.", Palette.SAFETY_ORANGE))

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
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for heading in ["", "Voor", "Na"]:
		grid.add_child(label(heading, UiTheme.SMALL, Palette.MUTED))
	var prediction: String = session.region.state[problem_id].a3.get("prediction", "")
	for row: String in ROWS:
		var before: float = result["before"][row]
		var after: float = result["after"][row]
		var name := UiText.kpi(row) + ("   (jouw voorspelling)" if row == prediction else "")
		grid.add_child(label(name, UiTheme.SMALL, Palette.VOLTANA_BLUE if row == prediction else Palette.INK))
		grid.add_child(label(UiText.kpi_value(row, before)))
		var same := is_equal_approx(before, after)
		grid.add_child(label(UiText.kpi_value(row, after), UiTheme.FONT_SIZE,
			Palette.INK if same else (Palette.GREEN_DARK if improved(row, before, after) else Palette.SAFETY_ORANGE)))


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
	for note: String in score["notes"]:
		notes.add_child(paragraph("• " + UiText.score_note(note), Palette.INK, UiTheme.SMALL))
	for m: MissionDef in session.missions.defs.values():
		if m.goal_problem == problem_id and session.missions.status(m.id) == "completed":
			var debrief := add_card(body, session.catalog.coach.get("name", "Coach"), Palette.BLUE_PALE)
			debrief.add_child(paragraph("'%s'" % m.debrief))
