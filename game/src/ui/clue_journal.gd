class_name ClueJournal
extends UiPanel
## The clue journal (J): every clue the player has found, grouped by the
## place where it was found. It does not say which problem a clue belongs
## to, nor which clues matter: that is for the player to work out. Above
## them, the fixes in use with their health and the stagnation drift, as
## measured (SustainView): what holds a fix is for the player to find.


## The session layer's buttons (GameUI opens what they name).
const TERUGBLIK := "Terugblik"
const INTUSSEN := "Intussen"
const LOG := "Speellogboek bijhouden (alleen op deze computer, nooit verstuurd)"

## "terugblik" or "intussen": reopen that card or panel.
signal reopen(what: String)
signal log_toggled(on: bool)

## Set by GameUI: the session layer (the last terugblik, the running
## Checks) and whether the playtest log is on.
var layer: SessionLayer
var log_on := true


func _init() -> void:
	super("Aanwijzingen", Vector2(1000, 0))


## Terugblik (when this session opened with one), Intussen (while an
## experiment runs) and the playtest log switch.
func _session_row() -> void:
	if layer == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	if not layer.last_card.is_empty():
		row.add_child(button(TERUGBLIK, reopen.emit.bind("terugblik")))
	if not SessionLayer.running(session).is_empty():
		row.add_child(button(INTUSSEN, reopen.emit.bind("intussen")))
	var log_switch := CheckBox.new()
	log_switch.text = LOG
	log_switch.button_pressed = log_on
	log_switch.add_theme_font_size_override("font_size", UiTheme.SMALL)
	log_switch.toggled.connect(log_toggled.emit)
	row.add_child(log_switch)


## Every clue found so far: by place (the first place a clue was found there
## first), then in the order found. Not per problem: the order must not say
## which clues belong together.
static func found(s: GameSession) -> Array[Clue]:
	var clues := {}
	for p in s.region.problem_list():
		for c in p.clues:
			clues[c.id] = c
	var places := {}
	for id in s.region.found:
		var c: Clue = clues.get(id)
		if c != null:
			if not places.has(c.at):
				places[c.at] = []
			places[c.at].append(c)
	var out: Array[Clue] = []
	for at in places:
		out.append_array(places[at])
	return out


## The found clues by place: [{place (the step's Dutch name), clues}].
static func by_place(s: GameSession) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var index := {}
	for c in found(s):
		if not index.has(c.at):
			index[c.at] = groups.size()
			var step := s.region.net.step_at(c.at)
			groups.append({"place": step.name if step != null else c.at, "clues": []})
		groups[index[c.at]]["clues"].append(c)
	return groups


func refresh() -> void:
	clear(body)
	_session_row()
	_sustain()
	var groups := by_place(session)
	if groups.is_empty():
		body.add_child(paragraph("Nog niets gevonden. Ga naar de werkvloer en kijk, tel, meet en vraag.", Palette.MUTED))
	for g in groups:
		var box := add_card(body, g["place"])
		for c: Clue in g["clues"]:
			box.add_child(paragraph("• " + c.text))


## The fixes in use and the drift; nothing before the first fix or the
## campaign.
func _sustain() -> void:
	var fixes := SustainView.fixes(session)
	var drift := UiText.drift_line(session.drift())
	if fixes.is_empty() and drift.is_empty():
		return
	var box := add_card(body, "Je verbeteringen", Palette.BLUE_PALE)
	for id in fixes:
		SustainView.add_fix(box, session, id, true)
	if not drift.is_empty():
		box.add_child(paragraph(drift, Palette.MUTED, UiTheme.SMALL))
