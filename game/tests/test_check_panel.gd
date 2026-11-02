extends TestCase
## The Check panel labels each number as a leading (Stuurindicator) or a
## lagging (Volgindicator) measure and explains why lagging ones trail.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"
const PROBLEM := "custom_design"


func test_every_row_is_classified_and_the_lagging_ones_are_the_finished_order_measures() -> void:
	for row: String in CheckPanel.ROWS:
		assert_true(CheckPanel.KIND.has(row), row)
	for row in ["lead_time", "first_time_right", "on_time"]:
		assert_eq(CheckPanel.kind(row), CheckPanel.LAGGING, row)
	for row in ["capacity", "throughput", "wip_age"]:
		assert_eq(CheckPanel.kind(row), CheckPanel.LEADING, row)


func test_the_result_shows_a_tag_per_measure_and_the_explanation() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false  # a returning player: straight to the campaign
	office.build()
	var ui := office.ui
	ui.mission_board.accept(MISSION)
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("time_study")
	ui.place_menu.use_tool("documents")
	office.interact(office.interactable(INTAKE))
	ui.place_menu.ask("walk")
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("data")
	office.interact(office.interactable("obeya"))
	var problem: ProblemDef = office.session.region.problems[PROBLEM]
	var evidence := office.session.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id)
	ui.a3_form.submit({"waste": "overprocessing", "cause": office.session.cause_options(PROBLEM).find(problem.root_cause),
		"evidence": evidence, "cm": "standard_designs", "prediction": "throughput"})
	ui.a3_form.wait()
	ui.a3_form.check()
	var texts := ui.check_panel.shown_texts()
	var leading := texts.filter(func(t: String) -> bool: return t == "Stuurindicator").size()
	var lagging := texts.filter(func(t: String) -> bool: return t == "Volgindicator").size()
	assert_eq(leading, 3, "three leading rows are tagged")
	assert_eq(lagging, 3, "three lagging rows are tagged")
	assert_true(texts.has(CheckPanel.KIND_GROUPS[CheckPanel.LAGGING]), "the lagging group says when the effect shows")
	assert_true(texts.has(CheckPanel.LAGGING_NOTE), "the explanatory line shows")
	office.free()
