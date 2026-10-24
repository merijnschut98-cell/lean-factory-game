class_name A3Form
extends UiPanel
## The A3 of a mission's problem, a sheet on the player's clipboard (PLAN 2.10: at
## their desk at Aansluitingen, or taken from anywhere; drawn as paper, PaperSheet).
## The player writes it (waste, cause, evidence, countermeasure, prediction), starts
## the experiment and waits for the Check, which is read at Petra's screen at Meetdata
## (GameUI.open_check). The choices come from the rules (cause_options,
## countermeasures) and say nothing about which one is right: the simulation judges.

signal checked(problem_id: String, result: Dictionary)

const PICK := "— kies —"
## The stream's numbers on the A3, in this order.
const NUMBERS := ["throughput", "lead_time", "first_time_right", "on_time", "wip_age"]
## A repair's earlier fix (Region.start_rework), and the countermeasures
## not offered because a preparation is missing (each with its hint).
const TRIED := "Eerder geprobeerd: %s. Die draait door tot een nieuwe maatregel zich in de Check bewijst."
const UNPREPARED := "Niet voorbereid"
const TITLE := "Je A3"
const NO_A3 := "Er zit nog geen A3 op je klembord. Neem eerst een missie aan op het missiebord."
## Where the Check and the Act are done now (PLAN 2.10): at Petra's screen.
const CHECK_AT_PETRA := "De cijfers staan op Petra's scherm bij Meetdata & registratie. Daar doe je de Check."
const ACT_AT_PETRA := "De uitslag staat nog op Petra's scherm bij Meetdata & registratie. Daar beslis je."
## The sections on the sheet: no fill, the ruling shows through.
const SECTION := Color(1, 1, 1, 0)

var problem_id := ""
var message := ""
## Whether `message` is good news (green) or a refusal (orange).
var message_ok := false
## Check results per problem, kept until Act (a Check is done once).
var results: Dictionary[String, Dictionary] = {}
## What the player has filled in per problem, kept while the form is rebuilt
## (a refusal, closing and reopening the wall) until the A3 is accepted.
var drafts: Dictionary[String, Dictionary] = {}
## The problem whose form is on the wall now ("" when none is).
var _form_problem := ""

var _waste: OptionButton
var _causes := ButtonGroup.new()
var _evidence: Dictionary[String, CheckBox] = {}
var _cm: OptionButton
var _prediction: OptionButton


func _init() -> void:
	super(TITLE, Vector2(1480, 0))
	add_theme_stylebox_override("panel", PaperSheet.new())


## The mission on the wall: the main one first, then side missions with a
## problem.
func mission() -> MissionDef:
	for m in session.active_missions():
		if not m.goal_problem.is_empty():
			return m
	return null


## Submit the A3 (GameSession.submit_a3's fields). "" or the refusal code;
## `message` words it.
func submit(a3: Dictionary) -> String:
	var refused := session.submit_a3(problem_id, a3)
	message_ok = refused.is_empty()
	message = ("Het experiment loopt. %s doe je de Check." % ("Morgen" if _one_day() else "Over " + _period())) if message_ok else UiText.a3_error(refused)
	if message_ok:
		drafts.erase(problem_id)
		_form_problem = ""
	acted.emit()
	refresh()
	return refused


## Let the experiment run until the Check is due.
func wait() -> String:
	var refused := session.wait_for_check(problem_id)
	message_ok = false
	message = "" if refused.is_empty() else UiText.a3_error(refused)
	acted.emit()
	refresh()
	return refused


## Do the Check (at Petra's screen, GameUI.open_check): the result goes to the Check panel.
func check() -> Dictionary:
	var result := session.check(problem_id)
	message_ok = false
	message = UiText.a3_error(result["error"]) if result.has("error") else ""
	acted.emit()
	if result.has("error"):
		refresh()
		return result
	results[problem_id] = result
	checked.emit(problem_id, result)
	return result


## The A3 as filled in on the form.
func selected_a3() -> Dictionary:
	var pressed: BaseButton = _causes.get_pressed_button()
	var evidence := []
	for id in _evidence:
		if _evidence[id].button_pressed:
			evidence.append(id)
	var cms := session.countermeasures()
	return {
		"waste": Investigation.WASTES[_waste.selected - 1] if _waste.selected > 0 else "",
		"cause": _causes.get_buttons().find(pressed),
		"evidence": evidence,
		"cm": cms[_cm.selected - 1].id if _cm.selected > 0 else "",
		"prediction": Investigation.KPIS[_prediction.selected - 1] if _prediction.selected > 0 else "",
	}


## Set the form's fields from an A3 (the shape selected_a3 returns).
func fill(a3: Dictionary) -> void:
	_waste.select(Investigation.WASTES.find(a3.get("waste", "")) + 1)
	var cause: int = a3.get("cause", -1)
	var causes := _causes.get_buttons()
	if cause >= 0 and cause < causes.size():
		causes[cause].button_pressed = true
	for id in _evidence:
		_evidence[id].button_pressed = id in a3.get("evidence", [])
	var cms := session.countermeasures().map(func(c: CountermeasureDef) -> String: return c.id)
	_cm.select(cms.find(a3.get("cm", "")) + 1)
	_prediction.select(Investigation.KPIS.find(a3.get("prediction", "")) + 1)


func refresh() -> void:
	if not _form_problem.is_empty():
		drafts[_form_problem] = selected_a3()
		_form_problem = ""
	clear(body)
	var m := mission()
	problem_id = m.goal_problem if m != null else ""
	if m == null:
		body.add_child(paragraph(tr(NO_A3), Palette.MUTED))
		return
	title_label.text = tr(TITLE) + "  ·  " + UiText.mission_title(m, session)
	if not message.is_empty():
		body.add_child(paragraph(message, Palette.GREEN_DARK if message_ok else Palette.SAFETY_ORANGE))
	match session.phase_of(problem_id):
		"spotted":
			_build_form(m)
			_form_problem = problem_id
			fill(drafts.get(problem_id, {}))
		"active":
			body.add_child(paragraph(UiText.a3_error("not_spotted"), Palette.INK))
		"doing":
			body.add_child(paragraph("Het experiment loopt %s. Het team werkt met de nieuwe aanpak; de stroom laat zien of het helpt." % _period()))
			body.add_child(button("Wacht tot de Check (%s)" % ("morgen" if _one_day() else _period()), wait))
		"check_ready":
			body.add_child(paragraph("Het experiment heeft zijn %s gehad. Vergelijk voor en na: wat zeggen de cijfers?" % (
				"dag" if _one_day() else _period())))
			body.add_child(paragraph(tr(CHECK_AT_PETRA), Palette.VOLTANA_BLUE))
		"checked":
			body.add_child(paragraph("De Check is gedaan. Wat doe je nu: standaardiseren of niet?"))
			body.add_child(paragraph(tr(ACT_AT_PETRA), Palette.VOLTANA_BLUE))
		_:
			body.add_child(paragraph("Dit probleem is afgesloten.", Palette.MUTED))


## How long this problem's experiment runs before the Check, in words.
func _period() -> String:
	return UiText.period(session.check_days(problem_id))


## The training week's one-day practice Check (Thursday's trial, read on Friday).
func _one_day() -> bool:
	return session.check_days(problem_id) == 1

func _build_form(m: MissionDef) -> void:
	var sheet := HBoxContainer.new()
	sheet.add_theme_constant_override("separation", 16)
	body.add_child(sheet)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 740
	sheet.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 640
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_child(right)

	var now := add_card(left, "Achtergrond en huidige situatie (laatste twee weken)", SECTION)
	now.add_child(paragraph(m.briefing, Palette.INK, UiTheme.SMALL))
	now.add_child(_numbers_row(session.region.snapshot(problem_id)))

	var waste := add_card(left, "1. Welke verspilling zie je?", SECTION)
	_waste = _options(Investigation.WASTES.map(func(w: String) -> String: return UiText.waste(w)))
	waste.add_child(_waste)

	var cause := add_card(left, "2. Wat is de oorzaak?", SECTION)
	for text in session.cause_options(problem_id):
		var c := CheckBox.new()
		c.text = text
		c.button_group = _causes
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.add_theme_font_size_override("font_size", UiTheme.SMALL)
		cause.add_child(c)

	var proof := add_card(right, "3. Welke aanwijzingen onderbouwen dat?", SECTION)
	_evidence.clear()
	for c in ClueJournal.found(session):
		var box := CheckBox.new()
		box.text = c.text
		box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_theme_font_size_override("font_size", UiTheme.SMALL)
		_evidence[c.id] = box
		proof.add_child(box)

	var plan := add_card(right, "4. Tegenmaatregel en 5. voorspelling", SECTION)
	var tried: String = session.region.state[problem_id].rework_from.get("cm", "")
	if session.region.countermeasures.has(tried):
		plan.add_child(paragraph(TRIED % session.region.countermeasures[tried].name, Palette.SAFETY_ORANGE, UiTheme.SMALL))
	_cm = _options(session.countermeasures().map(func(c: CountermeasureDef) -> String: return option_text(c, session)))
	plan.add_child(_cm)
	_add_unprepared(plan)
	plan.add_child(label("Op welke KPI verwacht je het effect?", UiTheme.SMALL, Palette.MUTED))
	var stream := session.region.net.stream_of(session.region.problems[problem_id].step)
	_prediction = _options(Investigation.KPIS.map(func(k: String) -> String: return UiText.kpi(k, stream)))
	plan.add_child(_prediction)
	var start := button("Start experiment", func() -> void: submit(selected_a3()))
	start.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(start)


## A countermeasure in the list: its cost now and over a year, redoing it
## each time it fades (an estimate, so rounded to a thousand).
static func option_text(c: CountermeasureDef, s: GameSession) -> String:
	var year := roundi(s.year_cost(c.id) / 1000.0) * 1000
	return "%s  (%s; ±%s /jaar)" % [c.name, UiText.money(c.budget), UiText.money(year)]


## "Niet voorbereid": what is not on offer yet, and where to prepare it.
func _add_unprepared(parent: Node) -> void:
	var missing := session.unprepared_countermeasures()
	if missing.is_empty():
		return
	parent.add_child(label(UNPREPARED, UiTheme.SMALL, Palette.MUTED))
	for c in missing:
		parent.add_child(paragraph("• %s: %s" % [c["name"], c["preparation"]], Palette.MUTED, 15))


func _numbers_row(snapshot: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = NUMBERS.size()
	grid.add_theme_constant_override("h_separation", 18)
	var stream := session.region.net.stream_of(session.region.problems[problem_id].step)
	for k: String in NUMBERS:
		var name := label(UiText.kpi(k, stream), 15, Palette.MUTED, true)
		name.custom_minimum_size.x = 118
		name.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		grid.add_child(name)
	for k: String in NUMBERS:
		grid.add_child(label(UiText.kpi_value(k, snapshot[k]), UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	return grid


static func _options(items: Array) -> OptionButton:
	var o := OptionButton.new()
	o.add_item(PICK)
	for text: String in items:
		o.add_item(text)
	o.fit_to_longest_item = false
	o.clip_text = true
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return o
