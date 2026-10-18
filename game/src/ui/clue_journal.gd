class_name ClueJournal
extends UiPanel
## The clue journal (J): every clue the player has found, grouped by the
## place where it was found. It does not say which problem a clue belongs
## to, nor which clues matter: that is for the player to work out. Above
## them, the fixes in use with their health and the stagnation drift, as
## measured (SustainView): what holds a fix is for the player to find.
## The "Mensen" tab, the player's notebook on people (dialog spec §11,
## person-needs spec §4): per person their trust as pips, their morale as a
## word (never a number), what they told you as quotes with the day and the
## place (newest first, older ones folded), your talks with their curve and
## moves, your own note, and whether they want to talk now. Never what the
## person needs: reading them is the player's work.

const CLUES := "clues"
const PEOPLE := "people"
const TABS := {CLUES: "Aanwijzingen", PEOPLE: "Mensen"}
const MORALE := "Werkplezier: "
const MORALE_BANDS: Array[String] = ["laag", "gewoon", "hoog"]
## The face a morale band shows in the journal, as a meter band (a frown, flat,
## a soft smile); low morale also tires the eyes.
const MORALE_FACES: Array[int] = [1, 2, 3]
const TOLD := "Wat %s je vertelde"
const TALKS := "Jullie gesprekken"
const NOTE := "Jouw notitie"
const NOTE_HINT := "Wat weet je over %s?"
const EARLIER := "Eerder"
## Quotes shown before the older ones fold under EARLIER.
const QUOTES_SHOWN := 8
## The followed dossier's card (PLAN 1.5): a manila folder among the clues.
const DOSSIER := "Dossier familie El Amrani · warmtepomp, Nova-Oost"
const DOSSIER_UNDERWAY := "Onderweg: %d dagen · %s uur werk eraan · ligt nu bij %s"
const DOSSIER_DONE := "Aangesloten na %d dagen · %s uur werk eraan"
## A briefing that reads the dossier names this token (content/missions.yaml).
const DOSSIER_TOKEN := "{dossier_weken}"
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
## What a gemba tool showed that was no clue (PLAN 2.12), marked apart.
const SEEN := "Waarneming"
const NOBODY := "Je hebt nog met niemand gesproken. Mensen vind je op hun plek op de werkvloer."

var tab := CLUES
var _tabs: Dictionary[String, Button] = {}
var _list: VBoxContainer
## Person ids whose older quotes are unfolded.
var _unfolded: Dictionary[String, bool] = {}


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
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	body.add_child(bar)
	for id: String in TABS:
		var b := button(TABS[id], show_tab.bind(id))
		b.toggle_mode = true
		_tabs[id] = b
		bar.add_child(b)
	_list = add_scroll_list(body, 620)


## Switch the journal to a tab (CLUES or PEOPLE).
func show_tab(id: String) -> void:
	tab = id
	refresh()


## Terugblik (when this session opened with one), Intussen (while an
## experiment runs) and the playtest log switch.
func _session_row() -> void:
	if layer == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_list.add_child(row)
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


## The found clues by place, with what the player saw there that was no clue
## (PlaceActions' observations, PLAN 2.12): [{place (the step's Dutch name),
## clues, seen}].
static func by_place(s: GameSession) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var index := {}
	var add := func(at: String) -> Dictionary:
		if not index.has(at):
			index[at] = groups.size()
			var step := s.region.net.step_at(at)
			groups.append({"place": step.name if step != null else at, "clues": [], "seen": []})
		return groups[index[at]]
	for c in found(s):
		add.call(c.at)["clues"].append(c)
	for entry in s.gemba.journal:
		add.call(entry["place"])["seen"].append(entry["text"])
	return groups


func refresh() -> void:
	clear(_list)
	title_label.text = TABS[tab]
	for id: String in _tabs:
		_tabs[id].set_pressed_no_signal(id == tab)
	if tab == PEOPLE:
		_people()
		return
	_session_row()
	_dossier()
	_sustain()
	var groups := by_place(session)
	if groups.is_empty():
		_list.add_child(paragraph("Nog niets gevonden. Ga naar de werkvloer en kijk, tel, meet en vraag.", Palette.MUTED))
	for g in groups:
		var box := add_card(_list, g["place"])
		for c: Clue in g["clues"]:
			box.add_child(paragraph("• " + c.text))
		for line: String in g["seen"]:
			box.add_child(paragraph("%s: %s" % [tr(SEEN), tr(line)], Palette.MUTED, UiTheme.SMALL))


## The El Amrani dossier you follow (PLAN 1.8), clipped in once a mission
## that reads it was taken on: how old it is, the hours of work it has had
## and where it lies now (or when it was delivered).
func _dossier() -> void:
	var follows := session.missions.defs.values().any(func(m: MissionDef) -> bool:
		return m.briefing.contains(DOSSIER_TOKEN) and session.missions.knows("accepted:" + m.id))
	if session.followed.order_id < 0 or not follows:
		return
	var view := session.followed_order()
	var box := add_card(_list, tr(DOSSIER), Palette.MANILA)
	box.add_child(paragraph(dossier_line(session, view), Palette.INK, UiTheme.SMALL))


## "Onderweg: 43 dagen · 3,5 uur werk eraan · ligt nu bij Werkvoorbereiding",
## or once delivered, after how long.
static func dossier_line(s: GameSession, view: Dictionary) -> String:
	var hours := String.num(view["touch_hours"], 1).replace(".", ",")
	if view["delivered_days"] >= 0.0:
		return TranslationServer.translate(DOSSIER_DONE) % [roundi(view["delivered_days"]), hours]
	var step := s.region.net.step_at(FollowedOrder.STREAM + "." + str(view["step"]))
	return TranslationServer.translate(DOSSIER_UNDERWAY) % [roundi(view["age_days"]), hours,
		step.name if step != null else str(view["step"])]


## The fixes in use and the drift; nothing before the first fix or the
## campaign.
func _sustain() -> void:
	var fixes := SustainView.fixes(session)
	var drift := UiText.drift_line(session.drift())
	if fixes.is_empty() and drift.is_empty():
		return
	var box := add_card(_list, "Je verbeteringen", Palette.BLUE_PALE)
	for id in fixes:
		SustainView.add_fix(box, session, id, true)
	if not drift.is_empty():
		box.add_child(paragraph(drift, Palette.MUTED, UiTheme.SMALL))


## The people the player knows of: whoever they talked with, or who wants a talk.
func _people() -> void:
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
		_list.add_child(paragraph(NOBODY, Palette.MUTED))


func _person_card(id: String, wants: bool) -> void:
	var p := session.person(id)
	var card := add_card(_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var face := MoodFace.new(64.0)
	face.show_state(MORALE_FACES[p["morale_band"]], "moe" if p["morale_band"] == 0 else "")
	row.add_child(face)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(label("%s  ·  %s" % [p["name"], p["role"]], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	var standing := HBoxContainer.new()
	standing.add_theme_constant_override("separation", 30)
	text.add_child(standing)
	standing.add_child(label("%s  %s" % [DialogPanel.TRUST, DialogPanel.pips(p["trust_pips"])], UiTheme.SMALL))
	var morale := label(MORALE + MORALE_BANDS[p["morale_band"]], UiTheme.SMALL)
	morale.tooltip_text = tr(MORALE_TIP)
	morale.mouse_filter = Control.MOUSE_FILTER_PASS
	standing.add_child(morale)
	var cooling := session.people.cooling_down(id, session.region.net.time)
	text.add_child(label(again_text(session, p["cooldown_until"] if cooling else -1, p["talk_ready"]), UiTheme.SMALL,
		Palette.SAFETY_ORANGE if cooling else Palette.MUTED))
	if wants and not cooling:
		text.add_child(label(NEEDS_TALK, UiTheme.SMALL, Palette.GREEN_DARK))
	var short: String = session.people.persons[id].short
	_still_open(card, p["open"])
	_quotes(card, id, short, p["observed"])
	_talks(card, p["talks"])
	card.add_child(label(tr(NOTE), UiTheme.SMALL, Palette.VOLTANA_BLUE))
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
	card.add_child(label(tr(OPEN_HEADING), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	for o: Dictionary in open:
		var lines: Array = o["hints"] if o["outcome"] == "blocked" else \
			[o["wait_for"] if not o["wait_for"].is_empty() else tr(DialogPanel.STILL_NEEDED_CHECK)]
		for line: String in lines:
			card.add_child(paragraph("• " + line, Palette.INK, UiTheme.SMALL))


## What the person said, newest first, each with the day and the place; the
## older ones fold under EARLIER. Not grouped or marked: a notebook.
func _quotes(card: VBoxContainer, id: String, short: String, observed: Array) -> void:
	if observed.is_empty():
		return
	card.add_child(label(tr(TOLD) % short, UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var shown: int = observed.size() if _unfolded.has(id) else mini(observed.size(), QUOTES_SHOWN)
	for o: Dictionary in observed.slice(0, shown):
		card.add_child(paragraph("\"%s\"" % o["text"], Palette.INK, UiTheme.SMALL))
		var step := session.region.net.step_at(o["place"])
		var where := " · ".join([session.day_text(o["at"]), step.name if step != null else ""].filter(
			func(part: String) -> bool: return not part.is_empty()))
		if not where.is_empty():
			card.add_child(label(where, UiTheme.SMALL, Palette.MUTED))
	if shown < observed.size():
		card.add_child(button("%s (%d)" % [tr(EARLIER), observed.size() - shown], func() -> void:
			_unfolded[id] = true
			refresh()))


## Each talk, newest first: its day and outcome, the curve with the moves under it.
func _talks(card: VBoxContainer, talks: Array) -> void:
	if talks.is_empty():
		return
	card.add_child(label(tr(TALKS), UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var chips: Dictionary = DialogPanel.labels_of(session).get("chips", {})
	for t: Dictionary in talks:
		card.add_child(label("%s · %s" % [session.day_text(t["at"]), DialogPanel.outcome_name(session, t["outcome"])],
			UiTheme.SMALL, Palette.MUTED))
		var moves: Array[String] = []
		moves.assign(t["moves"].map(func(m: String) -> String: return str(chips.get(m, m))))
		var curve := TraceLine.new(Vector2(420, 40 + 2 * TraceLine.LABEL_ROW))
		curve.set_trace(t["trace"], moves)
		card.add_child(curve)
