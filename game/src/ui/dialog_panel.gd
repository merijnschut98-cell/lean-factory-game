class_name DialogPanel
extends UiPanel
## A talk with a named person (dialog spec §11), across the bottom of the
## screen at one fixed height (at most two fifths of it), so the person
## stays in view above it, framed over the player's shoulder. At the top, in
## one small row by their face (PLAN 2.13 B), the meter: the openness bar that
## FILLS, with ▲/▲▲ or ▼/▼▼ for the last reply and never a number (Merijn,
## 2026-10-15), its band named beside it; trust as five pips; the mood word;
## the layer tracker (Standpunt · Belang · Zorg). Then what you said, the reply, and the cue "Er zit meer achter…".
## Below, four things you could say (Dialog.offer; Merijn's playtest,
## 2026-10-19): whole sentences, never a move's name, label or row, none
## styled by fit; each carries its key, small and dimmed (1–4), and Esc ends
## the talk ("Afronden"). When the talk ends the sentences give way to the
## summary card. What changes between states (the speech, the sentences, the
## summary) scrolls; the meter stays where the eye left it. When trust moves,
## a ▲ or ▼ flashes beside the pips for a moment (never a number).

## The summary card asks to talk the main mission's talk over with the coach.
signal coach_requested

const LAYERS := {"position": "Standpunt", "interest": "Belang", "concern": "Zorg"}
const ARROWS := {2: "▲▲", 1: "▲", 0: "", -1: "▼", -2: "▼▼"}
const YOU := "Jij: %s"
const OPENNESS := "Openheid"
const TRUST := "Vertrouwen"
const MOOD := "Stemming: %s"
const SUMMARY := "Hoe het gesprek ging"
const LEARNED := "Wat je hoorde"
const NEW_CLUE := "Een nieuwe aanwijzing staat in je journaal (J)."
const ROUTES := "Wat zou helpen"
const TALK_IT_OVER := "Bespreek met %s"
## Under the outcome: what an agreement under condition still waits for.
const STILL_NEEDED := "Wat nog moet: %s"
## When the condition names nothing: first see, then believe.
const STILL_NEEDED_CHECK := "Eerst zien, dan geloven: een geslaagde Check."
## Ruud after an Act 0 talk (tutorial talks spec §3): in person on the first
## day, by phone after that. One move named, never a score.
const RUUD_DROPPED_BY := "Ruud kwam even langs"
const RUUD_MESSAGE := "Bericht van Ruud"
## From this minute of the day Ruud has gone home: he texts.
const RUUD_HOME_AT := 18 * 60
## Under a ruined talk: the retry, and nothing more.
const TRY_AGAIN := "%s wil morgen weer praten."
## The header's button mid-talk: Esc ends the talk as "Afronden" does.
const END_TALK := "Afronden  (Esc)"
## Space at the screen's edges around the panel.
const MARGIN := 16
## The panel's height as a share of the screen's (the person stays in view).
const HEIGHT_SHARE := 0.4
## The space inside the panel's edges (tighter than other panels).
const PADDING := 14
const CHIP_FONT := 15
## The face beside the meter, and the bar's width: a small mood indicator.
const FACE_SIZE := 44.0
const BAR_WIDTH := 260.0
## How tall "Wat je hoorde" is before it scrolls (beside the summary card).
const SUMMARY_HEIGHT := 96.0
## The keys of the offered sentences, in order.
const OPTION_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4]
const KEY_HINT_FONT := 10
const KEY_HINT_AT := Vector2(3, -1)
## How long the trust arrow stays before it fades, and the fade.
const TRUST_FLASH_S := 1.0
const TRUST_FADE_S := 0.6

## start_dialog's result while a talk is open ({} when none is).
var talk: Dictionary = {}
## The last move's result (choose_move), {} before the first.
var last: Dictionary = {}
## Layer id → its line once heard (session.dialog_layers, then each reveal).
var heard: Dictionary = {}
## Openness after each move, the start first (what the trace draws).
var trace: Array = []
## The moves made, by chip label, for the summary (after the talk a move
## may be named, as Ruud does).
var made: Array[String] = []
## The sentences on offer this turn (session.dialog_offers), [] when none.
var offers: Array[Dictionary] = []
var bar: OpennessBar
var face: MoodFace
## The summary card's trace, its moves under its points (null mid-talk).
var summary_trace: TraceLine
## What scrolls under the meter: the speech, then the chips or the summary.
var _flow: VBoxContainer
## "Bespreek met Ruud" beside the close button, after a main mission's talk.
var _talk_over: Button
## The cue's slanted font (built once).
var _italic_font: FontVariation
## How the last move (or the talk's end) moved trust: 1, -1 or 0.
var trust_moved := 0
## The ▲ or ▼ beside the pips, shown while trust_moved is not 0.
var trust_flash: Label
## The trust the pips showed before the last move.
var _trust_seen := 0
## A line under the meter until the first move, once in the game (the first
## talk, PLAN 2.7d B7); "" for none.
var first_hint := ""


func _init() -> void:
	super("", Vector2(1000, 0))
	add_theme_stylebox_override("panel", UiTheme.panel(PADDING))
	title_label.add_theme_font_size_override("font_size", 22)
	close_button.add_theme_font_size_override("font_size", UiTheme.SMALL)
	rule.hide()  # the panel's height goes to the talk
	_talk_over = button("", coach_requested.emit)
	_talk_over.add_theme_font_size_override("font_size", UiTheme.SMALL)
	var header := close_button.get_parent()
	header.add_child(_talk_over)
	header.move_child(_talk_over, close_button.get_index())
	body.add_theme_constant_override("separation", 6)


## Across the bottom of the screen, always the same height.
func _place() -> void:
	if not is_inside_tree():
		return
	var rect := rect_on(get_parent_area_size())
	size = rect.size
	position = rect.position


## Where the panel goes on a screen of `area`: across the bottom, inside the
## margin, HEIGHT_SHARE of the screen tall at most.
static func rect_on(area: Vector2) -> Rect2:
	var height := floorf(area.y * HEIGHT_SHARE)
	return Rect2(MARGIN, area.y - height - MARGIN, area.x - 2 * MARGIN, height)


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
	trust_moved = 0
	_trust_seen = opened["meter"]["trust"]
	refresh()
	return ""


## The talk is open and not yet over.
func talking() -> bool:
	return not talk.is_empty() and not last.get("ended", false)


## Make a move (with its pick): choose_move's result. The buttons make only
## the offered ones (choose_option).
func choose(move: String, pick: String = "") -> Dictionary:
	var result := session.choose_move(move, pick)
	if result.has("error"):
		return result
	last = result
	first_hint = ""
	# At the end the talk's outcome moves trust too (a partial's +5).
	var trust: int = result.get("summary", {}).get("trust", result["trust"])
	trust_moved = signi(trust - _trust_seen)
	_trust_seen = trust
	trace.append(result["openness"])
	made.append(chip_label(move))
	if not result["revealed"].is_empty():
		heard[result["revealed"]] = result["reply"]
	if result["ended"]:
		acted.emit()
	refresh()
	return result


## Say the offered sentence at `index`: choose_move's result ({} for none).
func choose_option(index: int) -> Dictionary:
	if not talking() or index < 0 or index >= offers.size():
		return {}
	return choose(offers[index]["move"], offers[index]["pick"])


## A key pressed mid-talk: 1–4 say the sentence beside it. False when the key
## means nothing here (left for others).
func press_key(key: Key) -> bool:
	var i := OPTION_KEYS.find(key)
	if not talking() or i < 0 or i >= offers.size():
		return false
	choose_option(i)
	return true


func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key != null and key.pressed and not key.echo and press_key(key.physical_keycode):
		get_viewport().set_input_as_handled()


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
	summary_trace = null
	if talk.is_empty():
		return
	title_label.text = "%s  ·  %s" % [talk["name"], talk["role"]]
	close_button.text = tr(END_TALK) if talking() else tr(CLOSE)
	_talk_over.visible = not talking() and is_main_talk()
	_talk_over.text = TALK_IT_OVER % session.catalog.coach.get("name", "Ruud")
	body.add_child(_header())
	_flow = add_scroll_list(body)
	_flow.add_theme_constant_override("separation", 6)
	offers = session.dialog_offers()  # [] once the talk has ended
	_speech()
	if talking():
		_sentences()
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
	row.add_theme_constant_override("separation", 14)
	face = MoodFace.new(FACE_SIZE)
	face.clip_contents = true  # head and shoulders, a portrait in the row
	face.show_state(m["band"], m["mood"])
	row.add_child(face)
	row.add_child(label(OPENNESS, UiTheme.SMALL, Palette.MUTED))
	bar = OpennessBar.new()
	bar.custom_minimum_size.x = BAR_WIDTH
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.set_openness(trace[-2] if trace.size() >= 2 else m["openness"], false)
	bar.set_openness(m["openness"])
	row.add_child(bar)
	var arrow: int = last.get("arrow", 0)
	var arrow_label := label(arrow_text(arrow), UiTheme.HEADING, Palette.GREEN_DARK if arrow > 0 else Palette.SAFETY_ORANGE)
	arrow_label.custom_minimum_size.x = 44
	row.add_child(arrow_label)
	var band := maxi(0, m["band"])  # below Dicht (a ruin) still reads "Dicht"
	var band_label := label(band_name(band), UiTheme.SMALL, OpennessBar.COLORS[band].darkened(0.3))
	band_label.custom_minimum_size.x = 110
	row.add_child(band_label)
	row.add_child(label("%s  %s" % [TRUST, pips(m["trust_pips"])], UiTheme.SMALL))
	row.add_child(_trust_flash())
	row.add_child(label(MOOD % m["mood"], UiTheme.SMALL))
	row.add_child(_layer_tracker())
	for child in row.get_children():
		if child is Label:
			child.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return row


## ▲ or ▼ beside the pips when the last move moved trust; in the tree it
## fades after a moment.
func _trust_flash() -> Label:
	trust_flash = label(arrow_text(trust_moved), UiTheme.SMALL, Palette.GREEN_DARK if trust_moved > 0 else Palette.SAFETY_ORANGE)
	trust_flash.visible = trust_moved != 0
	if trust_flash.visible and is_inside_tree():
		var fade := create_tween()
		fade.tween_interval(TRUST_FLASH_S)
		fade.tween_property(trust_flash, "modulate:a", 0.0, TRUST_FADE_S)
	return trust_flash


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


## What you said and what they said, then the cue (in italics: a feeling,
## not a link) or their own idea.
func _speech() -> void:
	if last.is_empty():
		if not first_hint.is_empty():
			_flow.add_child(paragraph(first_hint, Palette.MUTED, UiTheme.SMALL))
		_flow.add_child(paragraph("\"%s\"  \"%s\"" % [talk["opening"], talk["position"].get("text", "")]))
	else:
		if talking():  # the summary keeps only the person's last words
			_flow.add_child(paragraph(YOU % last["line"], Palette.MUTED, UiTheme.SMALL))
		_flow.add_child(paragraph("\"%s\"" % last["reply"]))
	if last.get("cue", false):
		var cue := paragraph(str(_labels().get("cue", "")), Palette.MUTED, UiTheme.SMALL)
		cue.add_theme_font_override("font", _italic())
		_flow.add_child(cue)
	if not last.get("co_proposal", {}).is_empty():
		_flow.add_child(paragraph("\"%s\"" % last["co_proposal"]["text"], Palette.GREEN_DARK))


## The theme's font, slanted.
func _italic() -> FontVariation:
	if _italic_font == null:
		_italic_font = FontVariation.new()
		_italic_font.base_font = get_theme_default_font()
		_italic_font.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return _italic_font


## The sentences on offer, two by two (the panel keeps its height), each with
## its key; none styled by fit and none named by its move.
func _sentences() -> void:
	var list := GridContainer.new()
	list.columns = 2
	list.add_theme_constant_override("h_separation", 8)
	list.add_theme_constant_override("v_separation", 6)
	_flow.add_child(list)
	for i in offers.size():
		var b := button(str(offers[i]["line"]), choose_option.bind(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", CHIP_FONT)
		list.add_child(_with_key(b, OPTION_KEYS[i] if i < OPTION_KEYS.size() else KEY_NONE))


## A chip with its key in its top-left corner, small and dimmed, taking no
## width of the row (KEY_NONE: the chip alone).
static func _with_key(chip: Button, key: Key) -> Button:
	if key != KEY_NONE:
		var ink := chip.get_theme_color("font_color") if chip.has_theme_color_override("font_color") else Color.WHITE
		var hint := label(OS.get_keycode_string(key), KEY_HINT_FONT, ink)
		hint.modulate.a = 0.6
		hint.position = KEY_HINT_AT
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(hint)
	return chip


## The summary card: the outcome and what comes next, the trace with each
## move under its point, what you heard, a block's route hints, and for a
## main mission's talk the way to the coach.
func _summary() -> void:
	var summary: Dictionary = last.get("summary", {})
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	_flow.add_child(columns)
	var card := add_card(columns, SUMMARY, Palette.BLUE_PALE)
	card.get_parent().size_flags_stretch_ratio = 1.2
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 20)
	card.add_child(split)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.custom_minimum_size.x = 250
	split.add_child(left)
	var outcome: String = last.get("outcome", "")
	left.add_child(label(outcome_label(outcome), 22, Palette.VOLTANA_BLUE))
	var next := what_next(outcome, summary)
	if not next.is_empty():
		left.add_child(paragraph(next, Palette.INK, UiTheme.SMALL))
	summary_trace = TraceLine.new(Vector2(420, 40 + 2 * TraceLine.LABEL_ROW))
	summary_trace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_trace.set_trace(trace, made)
	split.add_child(summary_trace)
	var heard_card := add_card(columns, LEARNED)
	heard_card.get_parent().size_flags_stretch_ratio = 0.8
	var learned := add_scroll_list(heard_card, SUMMARY_HEIGHT)
	for id: String in LAYERS:
		if heard.has(id):
			learned.add_child(paragraph("%s: \"%s\"" % [LAYERS[id], heard[id]], Palette.INK, CHIP_FONT))
	if not str(summary.get("clue", "")).is_empty():
		learned.add_child(paragraph(NEW_CLUE, Palette.GREEN_DARK, CHIP_FONT))
	var hints: Array = summary.get("hints", [])
	if not hints.is_empty():
		learned.add_child(label(ROUTES, CHIP_FONT, Palette.VOLTANA_BLUE))
		for h: String in hints:
			learned.add_child(paragraph("• " + h, Palette.INK, CHIP_FONT))
	_ruud_names(columns, str(summary.get("ruud_names", "")))


## Ruud's word after an Act 0 talk: the one move he names (or his question),
## and after Friday's last talk his question for the weekend. Nothing outside
## Act 0 (the rules give no line there). A note beside the summary, in view.
func _ruud_names(columns: HBoxContainer, line: String) -> void:
	if line.is_empty():
		return
	# In person on Monday's working day; by text in the evening (he has gone home, 2.7d B7) and after.
	var monday := SimCalendar.weekday(session.region.net.time - SimCalendar.days(GameSession.WARMUP_DAYS)) == 0 \
		and session.minute_of_day() < RUUD_HOME_AT
	var card := add_card(columns, tr(RUUD_DROPPED_BY if monday else RUUD_MESSAGE), Palette.NOTE_PAPER)
	card.get_parent().size_flags_stretch_ratio = 0.9
	var note := add_scroll_list(card, SUMMARY_HEIGHT)
	note.add_child(paragraph("'%s'" % line, Palette.INK, CHIP_FONT))
	var d: DialogDef = session.people.dialogs.get(talk.get("dialog", ""))
	if d != null and week_ends(session, d):
		var week_end := str(JsonFile.dict_or_empty(session.catalog.dialog_bank.get("ruud_names")).get("week_end", ""))
		if not week_end.is_empty():
			note.add_child(paragraph("'%s'" % week_end, Palette.INK, CHIP_FONT))


## Whether talk `d` closes the Act 0 week: a tutorial talk of the last
## training day, with every tutorial talk of that day had.
static func week_ends(s: GameSession, d: DialogDef) -> bool:
	var training := s.missions.defs.values().filter(func(m: MissionDef) -> bool: return m.kind == "training")
	if not d.tutorial or training.is_empty() or d.mission != training[-1].id:
		return false
	return s.people.dialogs.values().all(func(o: DialogDef) -> bool:
		return not (o.tutorial and o.mission == d.mission) or s.people.outcomes.has(o.id))


## The line under the outcome: what an agreement under condition waits for,
## or when to try a ruined talk again; "" otherwise.
func what_next(outcome: String, summary: Dictionary) -> String:
	match outcome:
		"partial":
			var wait := str(summary.get("wait_for", ""))
			return tr(STILL_NEEDED) % wait if not wait.is_empty() else tr(STILL_NEEDED_CHECK)
		"ruined":
			return tr(TRY_AGAIN) % talk.get("short", talk["name"])
	return ""


## Whether this talk belongs to the main mission (the coach talks it over).
func is_main_talk() -> bool:
	var d: DialogDef = session.people.dialogs.get(talk.get("dialog", ""))
	return d != null and not d.mission.is_empty() \
		and session.missions.active("main").any(func(m: MissionDef) -> bool: return m.id == d.mission)

