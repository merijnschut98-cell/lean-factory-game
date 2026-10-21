class_name TalkSummary
extends RefCounted
## A talk's note (People.talk_note, kept with the talk in the talk log; phase 2
## design §2.2): read safely from a save, listed for the journal, and drawn as
## one compact card, the talk's last screen and its entry in the notes. What
## the talk screen leaves out while it runs is here, named afterwards: the
## outcome and what comes next, the curve with the moves under it, the band it
## ended in and the mood, what was heard per layer, a new clue, a block's route
## hints and Ruud's word after an Act 0 talk.

const SUMMARY := "Hoe het gesprek ging"
const HEADING := "Gesprek met %s · %s"
const LAYERS := {"position": "Standpunt", "interest": "Belang", "concern": "Zorg"}
const LEARNED := "Wat je hoorde"
const ENDED := "Openheid aan het eind: %s"
const MOOD := "Stemming: %s"
const NEW_CLUE := "Een nieuwe aanwijzing staat in Notities op je telefoon."
const ROUTES := "Wat zou helpen"
## Under the outcome: what an agreement under condition still waits for.
const STILL_NEEDED := "Wat nog moet: %s"
## When the condition names nothing: first see, then believe.
const STILL_NEEDED_CHECK := "Eerst zien, dan geloven: een geslaagde Check."
## Under a ruined talk: the retry, and nothing more.
const TRY_AGAIN := "%s wil morgen weer praten."
const LINE_FONT := 15
const TRACE_SIZE := Vector2(420, 40 + 2 * TraceLine.LABEL_ROW)


## A talk log entry (GameSession.person's `talks`) of `person_id` with its
## note, every field typed whatever the save held: {person, dialog, at,
## outcome, trace, moves, band (-1 unknown), mood, heard ({layer: line}),
## new_clue, hints, wait_for, ruud_names}. A save from before the note reads
## as a note with nothing heard.
static func of(entry: Dictionary, person_id: String = "") -> Dictionary:
	var note := JsonFile.dict_or_empty(entry.get("summary"))
	var heard := {}
	var saved_heard := JsonFile.dict_or_empty(note.get("heard"))
	for id: String in LAYERS:
		if saved_heard.get(id) is String:
			heard[id] = saved_heard[id]
	var hints: Array[String] = []
	if note.get("hints") is Array:
		for h: Variant in note["hints"]:
			if h is String:
				hints.append(h)
	var band: Variant = note.get("band")
	return {"person": person_id, "dialog": str(entry.get("dialog", "")), "at": int(entry.get("at", -1)),
		"outcome": str(entry.get("outcome", "")), "trace": _array(entry.get("trace")), "moves": _array(entry.get("moves")),
		"band": int(band) if band is int or band is float else -1, "heard": heard, "hints": hints,
		"mood": _text(note.get("mood")), "new_clue": note.get("new_clue") == true,
		"wait_for": _text(note.get("wait_for")), "ruud_names": _text(note.get("ruud_names"))}


static func _text(v: Variant) -> String:
	return v if v is String else ""


static func _array(v: Variant) -> Array:
	return v if v is Array else []


## Every talk's note, newest first (the journal's notes).
static func notes(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in s.people.talk_log:
		for entry: Dictionary in s.person(id).get("talks", []):
			out.append(of(entry, id))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] > b["at"])
	return out


## The line under the outcome: what an agreement under condition waits for,
## or when to try a ruined talk again; "" otherwise.
static func what_next(s: GameSession, note: Dictionary) -> String:
	match note["outcome"]:
		"partial":
			return TranslationServer.translate(STILL_NEEDED) % note["wait_for"] if not note["wait_for"].is_empty() \
				else TranslationServer.translate(STILL_NEEDED_CHECK)
		"ruined":
			var p: PersonDef = s.people.persons.get(note["person"])
			return TranslationServer.translate(TRY_AGAIN) % (p.short if p != null else "")
	return ""


## The note as a card: `heading` over it ("" for SUMMARY), and beside it
## Ruud's word when `ruud` holds one ({heading, lines}).
static func card(s: GameSession, note: Dictionary, heading: String = "", ruud: Dictionary = {}) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var box := UiPanel.add_card(row, heading if not heading.is_empty() else TranslationServer.translate(SUMMARY),
		Palette.BLUE_PALE)
	box.get_parent().size_flags_stretch_ratio = 2.0
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	box.add_child(top)
	top.add_child(UiPanel.label(TalkView.outcome_name(s, note["outcome"]), 20, Palette.VOLTANA_BLUE))
	var state: Array[String] = []
	var band := TalkView.band_name(s, note["band"])
	if not band.is_empty():
		state.append(TranslationServer.translate(ENDED) % band)
	if not note["mood"].is_empty():
		state.append(TranslationServer.translate(MOOD) % note["mood"])
	var state_label := UiPanel.label("  ·  ".join(state), UiTheme.SMALL, Palette.MUTED)
	state_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(state_label)
	var next := what_next(s, note)
	if not next.is_empty():
		box.add_child(UiPanel.paragraph(next, Palette.INK, UiTheme.SMALL))
	var chips: Dictionary = TalkView.labels_of(s).get("chips", {})
	var moves: Array[String] = []
	moves.assign(note["moves"].map(func(m: Variant) -> String: return str(chips.get(m, m))))
	var curve := TraceLine.new(TRACE_SIZE)
	curve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curve.set_trace(note["trace"], moves)
	box.add_child(curve)
	_learned(box, note)
	if not ruud.is_empty():
		var said := UiPanel.add_card(row, ruud["heading"], Palette.NOTE_PAPER)
		for line: String in ruud["lines"]:
			said.add_child(UiPanel.paragraph("'%s'" % line, Palette.INK, LINE_FONT))
	return row


## What you heard, layer by layer, then a new clue and a block's route hints.
static func _learned(box: VBoxContainer, note: Dictionary) -> void:
	var heard: Dictionary = note["heard"]
	if not heard.is_empty() or note["new_clue"] or not note["hints"].is_empty():
		box.add_child(UiPanel.label(TranslationServer.translate(LEARNED), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	for id: String in LAYERS:
		if heard.has(id):
			box.add_child(UiPanel.paragraph("%s: \"%s\"" % [LAYERS[id], heard[id]], Palette.INK, LINE_FONT))
	if note["new_clue"]:
		box.add_child(UiPanel.paragraph(TranslationServer.translate(NEW_CLUE), Palette.GREEN_DARK, LINE_FONT))
	if not note["hints"].is_empty():
		box.add_child(UiPanel.label(TranslationServer.translate(ROUTES), LINE_FONT, Palette.VOLTANA_BLUE))
		for h: String in note["hints"]:
			box.add_child(UiPanel.paragraph("• " + h, Palette.INK, LINE_FONT))
