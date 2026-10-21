class_name PeopleApp
extends PhoneApp
## Wie is wie (the phone, design 2026-10-21 §1.6/§1.8): the player's notebook on
## people, once the journal's Mensen tab (dialog spec §11, person-needs spec §4).
## Above it the company's org chart when content/company.yaml is built
## (`res://data/company.json`, S1-E); without it, just the people. Per person
## their trust as pips, their morale as a word (never a number), what they
## told you as quotes with the day and the place (newest first, older ones
## folded), your talks with their curve and moves, your own note, and whether
## they want to talk now. Never what the person needs: reading them is the
## player's work.

const MORALE := "Werkplezier: "
const MORALE_BANDS: Array[String] = ["laag", "gewoon", "hoog"]
## The face a morale band shows, as a meter band (a frown, flat, a soft smile);
## low morale also tires the eyes.
const MORALE_FACES: Array[int] = [1, 2, 3]
const TOLD := "Wat %s je vertelde"
const TALKS := "Jullie gesprekken"
const NOTE := "Jouw notitie"
const NOTE_HINT := "Wat weet je over %s?"
const EARLIER := "Eerder"
## Quotes shown before the older ones fold under EARLIER.
const QUOTES_SHOWN := 8
## Over the morale word: it is how someone has been lately, not the talk's mood.
const MORALE_TIP := "Hoe iemand er de laatste weken bij zit."
const NEEDS_TALK := "Kan wel een goed gesprek gebruiken."
## What an agreement under condition, or a block, still waits for (U16).
const OPEN_HEADING := "Wat nog openstaat"
## When the next talk can be (U16): now, tomorrow, from a day, or nothing to say.
const AGAIN := "Weer praten: %s"
const AGAIN_NOW := "kan nu."
const AGAIN_TOMORROW := "morgen."
const AGAIN_FROM := "vanaf %s."
const AGAIN_NOTHING := "nu niets te bespreken."
const NOBODY := "Je hebt nog met niemand gesproken. Mensen vind je op hun plek op de werkvloer."
## The org chart (company.json): its heading and a team's line.
const ORG := "Voltana, regio Zuidmark"
const LEAD := "leiding: %s"
const COMPANY := "res://data/company.json"
## A talk's curve, as wide as the phone's screen allows.
const TRACE_WIDTH := 340

var _list: VBoxContainer
## Person ids whose older quotes are unfolded.
var _unfolded: Dictionary[String, bool] = {}
## The company file, read once ({} without one).
var _company: Variant = null


func refresh() -> void:
	_people()


## The departments and their teams from company.json, if it is there: a short
## chart, each department with its lead and its teams (any field may be missing).
func _org_chart() -> void:
	var departments: Variant = company().get("departments")
	if not departments is Array or departments.is_empty():
		return
	var box := UiPanel.add_card(_list, tr(ORG), Palette.BLUE_PALE)
	for d: Variant in departments:
		if not d is Dictionary:
			continue
		box.add_child(UiPanel.label(str(d.get("name", "")), UiTheme.SMALL, Palette.VOLTANA_BLUE))
		var lead := _head_name(d.get("head"))
		if not lead.is_empty():
			box.add_child(UiPanel.label(tr(LEAD) % lead, 15, Palette.MUTED))
		var teams: Variant = d.get("teams")
		for t: Variant in teams if teams is Array else []:
			if t is Dictionary and t.get("name") is String:
				box.add_child(UiPanel.paragraph("• " + t["name"], Palette.INK, 15))


## A department head's name (company.yaml: {id, title} for someone in the cast, or
## {name, title} for someone not yet in it); "" when there is none.
func _head_name(head: Variant) -> String:
	if not head is Dictionary:
		return ""
	if head.get("name") is String:
		return head["name"]
	var id := str(head.get("id", ""))
	for entry: Dictionary in CharacterModel.cast():  # the cast has everyone, Ruud too
		if entry.get("id") == id:
			return str(entry.get("name", ""))
	return ""


## The company file's data, or {} (it is optional until S1-E builds it).
func company() -> Dictionary:
	if _company == null:
		_company = {}
		if FileAccess.file_exists(COMPANY):
			var read := JsonFile.read_dict(COMPANY)
			if read["error"].is_empty():
				_company = read["data"]
			else:
				push_warning("Wie is wie: " + read["error"])
	return _company


## The people the player knows of: whoever they talked with, or who wants a talk.
func _people() -> void:
	_list = scroll_list()
	_org_chart()
	var shown := 0
	for id: String in session.people.persons:
		if session.people.has_left(id):
			continue
		var talked := session.people.talks.keys().any(func(d: String) -> bool: return session.people.dialogs[d].person == id)
		var wants: bool = session.energy_of(id)["needs_talk"]
		if talked or wants:
			_person_card(id, wants)
			shown += 1
	if shown == 0:
		_list.add_child(UiPanel.paragraph(tr(NOBODY), Palette.MUTED))


func _person_card(id: String, wants: bool) -> void:
	var p := session.person(id)
	var card := UiPanel.add_card(_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var face := MoodFace.new(64.0)
	face.show_state(MORALE_FACES[p["morale_band"]], "moe" if p["morale_band"] == 0 else "")
	row.add_child(face)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiPanel.label("%s  ·  %s" % [p["name"], p["role"]], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE, true))
	var standing := HBoxContainer.new()
	standing.add_theme_constant_override("separation", 30)
	text.add_child(standing)
	standing.add_child(UiPanel.label("%s  %s" % [TalkView.TRUST, TalkView.pips(p["trust_pips"])], UiTheme.SMALL))
	var morale := UiPanel.label(tr(MORALE) + tr(MORALE_BANDS[p["morale_band"]]), UiTheme.SMALL)
	morale.tooltip_text = tr(MORALE_TIP)
	morale.mouse_filter = Control.MOUSE_FILTER_PASS
	standing.add_child(morale)
	var cooling := session.people.cooling_down(id, session.region.net.time)
	text.add_child(UiPanel.label(again_text(session, p["cooldown_until"] if cooling else -1, p["talk_ready"]), UiTheme.SMALL,
		Palette.SAFETY_ORANGE if cooling else Palette.MUTED))
	if wants and not cooling:
		text.add_child(UiPanel.label(tr(NEEDS_TALK), UiTheme.SMALL, Palette.GREEN_DARK))
	var short: String = session.people.persons[id].short
	_still_open(card, p["open"])
	_quotes(card, id, short, p["observed"])
	_talks(card, p["talks"])
	card.add_child(UiPanel.label(tr(NOTE), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var note := TextEdit.new()
	note.text = p["note"]
	note.placeholder_text = tr(NOTE_HINT) % short
	note.custom_minimum_size = Vector2(0, 64)
	note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	note.text_changed.connect(func() -> void: session.set_note(id, note.text))
	card.add_child(note)


## "Weer praten: …": from the day a ruin's cooldown ends (`until`, -1 for
## none), else now or nothing to say.
static func again_text(s: GameSession, until: int, ready: bool) -> String:
	var when := AGAIN_NOW if ready else AGAIN_NOTHING
	if until >= 0:
		var tomorrow := SimCalendar.day_of(until) == SimCalendar.day_of(s.region.net.time) + 1
		when = AGAIN_TOMORROW if tomorrow else TranslationServer.translate(AGAIN_FROM) % s.day_text(until)
	return TranslationServer.translate(AGAIN) % TranslationServer.translate(when)


## Under "Wat nog openstaat": what each agreement under condition waits for
## (or "first see, then believe"), and a block's route hints.
func _still_open(card: VBoxContainer, open: Array) -> void:
	if open.is_empty():
		return
	card.add_child(UiPanel.label(tr(OPEN_HEADING), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	for o: Dictionary in open:
		var lines: Array = o["hints"] if o["outcome"] == "blocked" else \
			[o["wait_for"] if not o["wait_for"].is_empty() else tr(TalkSummary.STILL_NEEDED_CHECK)]
		for line: String in lines:
			card.add_child(UiPanel.paragraph("• " + line, Palette.INK, UiTheme.SMALL))


## What the person said, newest first, each with the day and the place; the
## older ones fold under EARLIER. Not grouped or marked: a notebook.
func _quotes(card: VBoxContainer, id: String, short: String, observed: Array) -> void:
	if observed.is_empty():
		return
	card.add_child(UiPanel.label(tr(TOLD) % short, UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var shown: int = observed.size() if _unfolded.has(id) else mini(observed.size(), QUOTES_SHOWN)
	for o: Dictionary in observed.slice(0, shown):
		card.add_child(UiPanel.paragraph("\"%s\"" % o["text"], Palette.INK, UiTheme.SMALL))
		var step := session.region.net.step_at(o["place"])
		var where := " · ".join([session.day_text(o["at"]), step.name if step != null else ""].filter(
			func(part: String) -> bool: return not part.is_empty()))
		if not where.is_empty():
			card.add_child(UiPanel.label(where, UiTheme.SMALL, Palette.MUTED))
	if shown < observed.size():
		card.add_child(UiPanel.button("%s (%d)" % [tr(EARLIER), observed.size() - shown], func() -> void:
			_unfolded[id] = true
			refresh()))


## Each talk, newest first: its day and outcome, the curve with the moves under it.
func _talks(card: VBoxContainer, talks: Array) -> void:
	if talks.is_empty():
		return
	card.add_child(UiPanel.label(tr(TALKS), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var chips: Dictionary = TalkView.labels_of(session).get("chips", {})
	for t: Dictionary in talks:
		card.add_child(UiPanel.label("%s · %s" % [session.day_text(t["at"]), TalkView.outcome_name(session, t["outcome"])],
			UiTheme.SMALL, Palette.MUTED))
		var moves: Array[String] = []
		moves.assign(t["moves"].map(func(m: Variant) -> String: return str(chips.get(m, m))))
		var curve := TraceLine.new(Vector2(TRACE_WIDTH, 40 + 2 * TraceLine.LABEL_ROW))
		curve.set_trace(t["trace"], moves)
		card.add_child(curve)
