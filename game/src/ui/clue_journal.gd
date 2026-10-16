class_name ClueJournal
extends UiPanel
## The clue journal (J): every clue the player has found, grouped by the
## place where it was found. It does not say which problem a clue belongs
## to, nor which clues matter: that is for the player to work out. Above
## them, the fixes in use with their health and the stagnation drift, as
## measured (SustainView): what holds a fix is for the player to find.
## The "Mensen" tab: per person their trust as pips, their morale as a word
## (never a number), what they told you (standpunt, belang, zorg once heard),
## how the last talk went, and whether they want to talk now (dialog spec §11).

const CLUES := "clues"
const PEOPLE := "people"
const TABS := {CLUES: "Aanwijzingen", PEOPLE: "Mensen"}
const MORALE := "Werkplezier: "
const MORALE_BANDS: Array[String] = ["laag", "gewoon", "hoog"]
## The face a morale band shows in the journal (the talk's own mood is the day's).
const MORALE_FACES: Array[String] = ["moe", "neutraal", "goed"]
const LAST_TALK := "Laatste gesprek: %s"
const NOT_NOW := "Wil nu even niet praten: morgen weer."
const NEEDS_TALK := "Kan wel een goed gesprek gebruiken."
const NOBODY := "Je hebt nog met niemand gesproken. Mensen vind je op hun plek op de werkvloer."

var tab := CLUES
var _tabs: Dictionary[String, Button] = {}
var _list: VBoxContainer


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
	clear(_list)
	title_label.text = TABS[tab]
	for id: String in _tabs:
		_tabs[id].set_pressed_no_signal(id == tab)
	if tab == PEOPLE:
		_people()
		return
	_sustain()
	var groups := by_place(session)
	if groups.is_empty():
		_list.add_child(paragraph("Nog niets gevonden. Ga naar de werkvloer en kijk, tel, meet en vraag.", Palette.MUTED))
	for g in groups:
		var box := add_card(_list, g["place"])
		for c: Clue in g["clues"]:
			box.add_child(paragraph("• " + c.text))


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


## What the player heard from a person, over all their talks: [{layer
## (position | interest | concern), text}], in that order, the layers once
## heard and the position once talked.
static func heard_from(s: GameSession, person_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: DialogDef in s.people.dialogs.values():
		if d.person != person_id:
			continue
		for key: String in s.people.revealed:
			if key.get_slice("/", 0) != d.id:
				continue
			var v := int(key.get_slice("/", 1))
			out.append({"layer": "position", "text": str(d.position_of(v).get("text", ""))})
			for layer: Dictionary in d.layers_of(v):
				if s.people.revealed[key].has(layer["id"]):
					out.append({"layer": str(layer["id"]), "text": str(layer.get("text", ""))})
	return out


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
	face.set_mood(MORALE_FACES[p["morale_band"]])
	row.add_child(face)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(label("%s  ·  %s" % [p["name"], p["role"]], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	var standing := HBoxContainer.new()
	standing.add_theme_constant_override("separation", 30)
	text.add_child(standing)
	standing.add_child(label("%s  %s" % [DialogPanel.TRUST, DialogPanel.pips(p["trust_pips"])], UiTheme.SMALL))
	standing.add_child(label(MORALE + MORALE_BANDS[p["morale_band"]], UiTheme.SMALL))
	for h in heard_from(session, id):
		text.add_child(paragraph("%s: \"%s\"" % [DialogPanel.LAYERS[h["layer"]], h["text"]], Palette.INK, UiTheme.SMALL))
	for dialog_id: String in p["outcomes"]:
		text.add_child(label(LAST_TALK % DialogPanel.outcome_name(session, p["outcomes"][dialog_id]), UiTheme.SMALL, Palette.MUTED))
	if session.people.cooling_down(id, session.region.net.time):
		text.add_child(label(NOT_NOW, UiTheme.SMALL, Palette.SAFETY_ORANGE))
	elif wants:
		text.add_child(label(NEEDS_TALK, UiTheme.SMALL, Palette.GREEN_DARK))
