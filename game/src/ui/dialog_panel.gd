class_name DialogPanel
extends UiPanel
## A talk with a named person (dialog spec §11), across the bottom of the
## screen so the office stays in view. At the top the meter: the openness bar
## that FILLS, with ▲/▲▲ or ▼/▼▼ for the last reply and never a number
## (Merijn, 2026-10-15), its band named under it; trust as five pips; the mood
## word and the face; the layer tracker (Standpunt · Belang · Zorg); the trace
## so far. Then what you said, the reply, and the cue "Er zit meer achter…".
## Below, the reply chips by move type, all of them, always: the line you will
## say shows on hover, never an effect or a hint about fit. A chip with ▸
## opens its picks (a clue you found, an experiment, a proposal). When the
## talk ends the chips give way to the summary card.

## The summary card asks to talk the main mission's talk over with the coach.
signal coach_requested

const ROW_NAMES := {"listen": "Luisteren", "steer": "Sturen"}
## Which move rows sit on which chip row (pressure and the rest on Sturen).
const CHIP_ROWS := {"listen": ["listen"], "steer": ["steer", "pressure", "other"]}
const LAYERS := {"position": "Standpunt", "interest": "Belang", "concern": "Zorg"}
const ARROWS := {2: "▲▲", 1: "▲", 0: "", -1: "▼", -2: "▼▼"}
const PICK_MARK := " ▸"
const YOU := "Jij: %s"
const OPENNESS := "Openheid"
const TRUST := "Vertrouwen"
const MOOD := "Stemming: %s"
const TRACE := "Verloop"
const PICK_HEADING := "Kies:"
const NO_PICKS := "Je hebt hier nog niets voor."
const SUMMARY := "Hoe het gesprek ging"
const LEARNED := "Wat je hoorde"
const NEW_CLUE := "Een nieuwe aanwijzing staat in je journaal (J)."
const ROUTES := "Wat zou helpen"
const TALK_IT_OVER := "Bespreek met %s"
const RUINED_AFTER := "morgen weer"
const CLOSE := "Sluiten"
## Space at the screen's edges around the panel.
const MARGIN := 16
## Picks longer than this are cut on their button (the whole text on hover).
const PICK_CHARS := 64

## start_dialog's result while a talk is open ({} when none is).
var talk: Dictionary = {}
## The last move's result (choose_move), {} before the first.
var last: Dictionary = {}
## Layer id → its line once heard (session.dialog_layers, then each reveal).
var heard: Dictionary = {}
## Openness after each move, the start first (what the trace draws).
var trace: Array = []
## The moves made, by chip label, for the summary.
var made: Array[String] = []
## The ▸ move whose picks are open ("" for none).
var picking := ""
var bar: OpennessBar


func _init() -> void:
	super("", Vector2(1480, 0))


## Across the bottom of the screen, at its minimum height.
func _place() -> void:
	if not is_inside_tree():
		return
	var area := get_parent_area_size()
	var min_size := get_combined_minimum_size()
	size = Vector2(area.x - 2 * MARGIN, min_size.y)
	position = Vector2(MARGIN, area.y - min_size.y - MARGIN)


## Open a person's talk: "" or start_dialog's error code.
func start(person_id: String) -> String:
	var opened := session.start_dialog(person_id)
	if opened.has("error"):
		return opened["error"]
	talk = opened
	last = {}
	heard = {}
	for layer in session.dialog_layers():
		if layer["heard"]:
			heard[layer["id"]] = layer["text"]
	trace = opened["meter"]["trace"].duplicate()
	made.clear()
	picking = ""
	refresh()
	return ""


## The talk is open and not yet over.
func talking() -> bool:
	return not talk.is_empty() and not last.get("ended", false)


## Make a move (with a pick for a ▸ chip): choose_move's result.
func choose(move: String, pick: String = "") -> Dictionary:
	var result := session.choose_move(move, pick)
	if result.has("error"):
		return result
	last = result
	picking = ""
	trace.append(result["openness"])
	made.append(chip_label(move))
	if not result["revealed"].is_empty():
		heard[result["revealed"]] = result["reply"]
	if result["ended"]:
		acted.emit()
	refresh()
	return result


## A ▸ chip: show its picks, or hide them again.
func open_picks(move: String) -> void:
	picking = "" if picking == move else move
	refresh()


## End the talk gracefully (Esc mid-talk); {} when no talk runs.
func close_talk() -> Dictionary:
	return choose("close") if talking() else {}


## "▲▲", "▲", "", "▼" or "▼▼" for a reply's arrow: never a number.
static func arrow_text(arrow: int) -> String:
	return ARROWS[clampi(arrow, -2, 2)]


## "●●○○○": filled pips of five.
static func pips(filled: int) -> String:
	var n := clampi(filled, 0, 5)
	return "●".repeat(n) + "○".repeat(5 - n)


func chip_label(move: String) -> String:
	return str(_labels().get("chips", {}).get(move, move))


func outcome_label(outcome: String) -> String:
	return outcome_name(session, outcome)


## An outcome's Dutch name from the content's bank ("Staat erachter").
static func outcome_name(s: GameSession, outcome: String) -> String:
	return str(labels_of(s).get("outcomes", {}).get(outcome, outcome))


func band_name(band: int) -> String:
	var bands: Array = _labels().get("bands", [])
	return str(bands[band]) if band >= 0 and band < bands.size() else ""


## The bank's labels (chips, bands, cue, outcomes): Dutch lives in content.
static func labels_of(s: GameSession) -> Dictionary:
	return JsonFile.dict_or_empty(s.catalog.dialog_bank.get("labels"))


func _labels() -> Dictionary:
	return labels_of(session)


func refresh() -> void:
	clear(body)
	if talk.is_empty():
		return
	title_label.text = "%s  ·  %s" % [talk["name"], talk["role"]]
	body.add_child(_header())
	_speech()
	if talking():
		_chips()
	else:
		_summary()


## The meter as it stands: the session's while the talk runs, else from the
## last move.
func meter() -> Dictionary:
	if talking():
		return session.dialog_meter()
	var openness: int = last.get("openness", 0)
	return {"openness": openness, "band": Dialog.band_of(openness),
		"trust_pips": floori(last.get("trust", 0) / float(Dialog.TRUST_PER_PIP)), "mood": talk["meter"]["mood"]}


func _header() -> HBoxContainer:
	var m := meter()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var face := MoodFace.new(88.0)
	face.set_mood(m["mood"])
	row.add_child(face)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	mid.add_child(top)
	var name := label(OPENNESS, UiTheme.SMALL, Palette.MUTED)
	name.custom_minimum_size.x = 92
	top.add_child(name)
	bar = OpennessBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.set_openness(trace[-2] if trace.size() >= 2 else m["openness"], false)
	bar.set_openness(m["openness"])
	top.add_child(bar)
	var arrow: int = last.get("arrow", 0)
	var arrow_label := label(arrow_text(arrow), UiTheme.HEADING, Palette.GREEN_DARK if arrow > 0 else Palette.SAFETY_ORANGE)
	arrow_label.custom_minimum_size.x = 60
	top.add_child(arrow_label)
	var band_label := label(band_name(m["band"]), UiTheme.FONT_SIZE, OpennessBar.COLORS[maxi(0, m["band"])].darkened(0.3))
	band_label.custom_minimum_size.x = 150
	top.add_child(band_label)
	mid.add_child(_band_names())
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 30)
	mid.add_child(facts)
	facts.add_child(label("%s  %s" % [TRUST, pips(m["trust_pips"])], UiTheme.SMALL))
	facts.add_child(label(MOOD % m["mood"], UiTheme.SMALL))
	facts.add_child(_layer_tracker())
	var right := VBoxContainer.new()
	row.add_child(right)
	right.add_child(label(TRACE, 15, Palette.MUTED))
	var line := TraceLine.new(Vector2(170, 52))
	line.set_trace(trace)
	right.add_child(line)
	return row


## The band names under the bar, each under its own stretch of it.
func _band_names() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var floors: Array[int] = [0]
	floors.append_array(Dialog.BANDS)
	floors.append(100)
	var lead := Control.new()
	lead.custom_minimum_size.x = 92 + 14  # under "Openheid"
	row.add_child(lead)
	for i in floors.size() - 1:
		var name := label(band_name(i - 1), 14, Palette.MUTED)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.size_flags_stretch_ratio = floors[i + 1] - floors[i]
		name.clip_text = true
		row.add_child(name)
	var tail := Control.new()
	tail.custom_minimum_size.x = 14 + 60 + 14 + 150  # under the arrow and the band word
	row.add_child(tail)
	return row


## Standpunt · Belang · Zorg: a layer lights once heard (its line on hover).
func _layer_tracker() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id: String in LAYERS:
		var known := heard.has(id)
		var chip := label(("● " if known else "○ ") + LAYERS[id], UiTheme.SMALL, Palette.VOLTANA_BLUE if known else Palette.MUTED)
		if known:
			chip.tooltip_text = heard[id]
			chip.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(chip)
	return row


## What you said and what they said, then the cue or their own idea.
func _speech() -> void:
	var box := add_card(body)
	if last.is_empty():
		box.add_child(paragraph("\"%s\"" % talk["opening"]))
		box.add_child(paragraph("\"%s\"" % talk["position"].get("text", "")))
	else:
		box.add_child(paragraph(YOU % last["line"], Palette.MUTED, UiTheme.SMALL))
		box.add_child(paragraph("\"%s\"" % last["reply"]))
	if last.get("cue", false):
		box.add_child(paragraph(str(_labels().get("cue", "")), Palette.BLUE_LIGHT, UiTheme.SMALL))
	if not last.get("co_proposal", {}).is_empty():
		box.add_child(paragraph("\"%s\"" % last["co_proposal"]["text"], Palette.GREEN_DARK))


## Every chip by row, always; a ▸ chip's picks under them when open.
func _chips() -> void:
	var moves := session.dialog_moves()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for row: String in CHIP_ROWS:
		var name := label(ROW_NAMES[row], UiTheme.SMALL, Palette.MUTED)
		name.custom_minimum_size.x = 92
		grid.add_child(name)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 6)
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(flow)
		for m: Dictionary in moves:
			if m["row"] in CHIP_ROWS[row]:
				flow.add_child(_chip(m))
	if not picking.is_empty():
		_picks(moves)


## A chip: the move type as its label, the line you will say on hover.
func _chip(m: Dictionary) -> Button:
	var has_picks: bool = m.has("picks")
	var b := button(m["label"] + (PICK_MARK if has_picks else ""),
		open_picks.bind(m["id"]) if has_picks else choose.bind(m["id"], ""))
	b.tooltip_text = "\"%s\"" % m["line"]
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	if m["row"] == "pressure":
		b.add_theme_stylebox_override("normal", UiTheme.card(Palette.MUTED))
	elif m["row"] == "other":
		b.add_theme_stylebox_override("normal", UiTheme.card(Palette.BLUE_LIGHT))
	if picking == m["id"]:
		b.add_theme_stylebox_override("normal", UiTheme.card(Palette.GREEN_DARK))
	return b


func _picks(moves: Array[Dictionary]) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	body.add_child(row)
	row.add_child(label(PICK_HEADING, UiTheme.SMALL, Palette.MUTED))
	var picks: Array = []
	for m in moves:
		if m["id"] == picking:
			picks = m.get("picks", [])
	if picks.is_empty():
		row.add_child(label(NO_PICKS, UiTheme.SMALL, Palette.MUTED))
	for p: Dictionary in picks:
		var text := str(p.get("name", p.get("text", p["id"])))
		var b := button(text if text.length() <= PICK_CHARS else text.left(PICK_CHARS) + "…", choose.bind(picking, p["id"]))
		b.tooltip_text = text
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		b.add_theme_stylebox_override("normal", UiTheme.card(Palette.BLUE_LIGHT))
		row.add_child(b)


## The summary card: the outcome, the trace with the moves under it, what you
## heard, a block's route hints, and for a main mission's talk the way to the
## coach.
func _summary() -> void:
	var summary: Dictionary = last.get("summary", {})
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	var card := add_card(columns, SUMMARY, Palette.BLUE_PALE)
	var outcome: String = last.get("outcome", "")
	card.add_child(label(outcome_label(outcome) + ("  —  " + RUINED_AFTER if outcome == "ruined" else ""),
		UiTheme.HEADING, Palette.VOLTANA_BLUE))
	var line := TraceLine.new(Vector2(600, 64))
	line.set_trace(trace)
	card.add_child(line)
	card.add_child(paragraph(" · ".join(PackedStringArray(made)), Palette.MUTED, 15))
	var learned := add_card(columns, LEARNED)
	for id: String in LAYERS:
		if heard.has(id):
			learned.add_child(paragraph("%s: \"%s\"" % [LAYERS[id], heard[id]], Palette.INK, UiTheme.SMALL))
	if not str(summary.get("clue", "")).is_empty():
		learned.add_child(paragraph(NEW_CLUE, Palette.GREEN_DARK, UiTheme.SMALL))
	var hints: Array = summary.get("hints", [])
	if not hints.is_empty():
		learned.add_child(label(ROUTES, UiTheme.SMALL, Palette.VOLTANA_BLUE))
		for h: String in hints:
			learned.add_child(paragraph("• " + h, Palette.INK, UiTheme.SMALL))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	if is_main_talk():
		row.add_child(button(TALK_IT_OVER % session.catalog.coach.get("name", "Ruud"), coach_requested.emit))
	row.add_child(button(CLOSE, close_requested.emit))


## Whether this talk belongs to the main mission (the coach talks it over).
func is_main_talk() -> bool:
	var d: DialogDef = session.people.dialogs.get(talk.get("dialog", ""))
	return d != null and not d.mission.is_empty() \
		and session.missions.active("main").any(func(m: MissionDef) -> bool: return m.id == d.mission)

