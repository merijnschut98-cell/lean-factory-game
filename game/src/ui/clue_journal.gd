class_name ClueJournal
extends UiPanel
## The player's notes (the phone's Notities, J): every clue the player has
## found, grouped by the place where it was found, with what the gemba tools
## showed that was no clue (Waarneming) and any other entry the rules write
## to the journal, by its kind. It does not say which problem a clue belongs
## to, nor which clues matter: that is for the player to work out. Above
## them, the fixes in use with their health and the stagnation drift, as
## measured (SustainView): what holds a fix is for the player to find.
## Ruud's notes moved to Berichten (PhoneMessages), the people to Wie is wie
## (PeopleApp), the playtest log switch to Instellingen (SettingsApp).

## The followed dossier's card (PLAN 1.5): a manila folder among the clues.
const DOSSIER := "Dossier familie El Amrani · warmtepomp, Nova-Oost"
const DOSSIER_UNDERWAY := "Onderweg: %d dagen · %s uur werk eraan · ligt nu bij %s"
const DOSSIER_DONE := "Aangesloten na %d dagen · %s uur werk eraan"
## A briefing that reads the dossier names this token (content/missions.yaml).
const DOSSIER_TOKEN := "{dossier_weken}"
## What a gemba tool showed that was no clue (PLAN 2.12), marked apart.
const SEEN := "Waarneming"
const NOTHING_YET := "Nog niets gevonden. Ga naar de werkvloer en kijk, tel, meet en vraag."
const TITLE := "Aanwijzingen"
const FIXES := "Je verbeteringen"
## A journal entry's kind with its heading; an entry without a kind is a Waarneming.
const KINDS := {"talk": "Gesprekken"}

## The session layer's buttons (GameUI opens what they name).
const TERUGBLIK := "Terugblik"
const INTUSSEN := "Intussen"

## "terugblik" or "intussen": reopen that card or panel.
signal reopen(what: String)

## Set by GameUI: the session layer (the last terugblik, the running Checks).
var layer: SessionLayer
var _list: VBoxContainer


func _init() -> void:
	super(TITLE, Vector2(1000, 0))
	_list = add_scroll_list(body, 620)


## Terugblik (when this session opened with one) and Intussen (while an
## experiment runs).
func _session_row() -> void:
	if layer == null:
		return
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	if not layer.last_card.is_empty():
		row.add_child(button(tr(TERUGBLIK), reopen.emit.bind("terugblik")))
	if not SessionLayer.running(session).is_empty():
		row.add_child(button(tr(INTUSSEN), reopen.emit.bind("intussen")))
	if row.get_child_count() > 0:
		_list.add_child(row)
	else:
		row.free()


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
## clues, seen}]. Entries of another kind are not here (by_kind).
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
		if str(entry.get("kind", "")).is_empty():
			add.call(entry["place"])["seen"].append(entry["text"])
	return groups


## The journal's entries of each other kind (a talk's summary, ...), newest
## first: {kind: [entry]}.
static func by_kind(s: GameSession) -> Dictionary:
	var out := {}
	for entry in s.gemba.journal:
		var kind := str(entry.get("kind", ""))
		if not kind.is_empty():
			if not out.has(kind):
				out[kind] = []
			out[kind].push_front(entry)
	return out


func refresh() -> void:
	clear(_list)
	title_label.text = tr(TITLE)
	_session_row()
	_dossier()
	_sustain()
	var groups := by_place(session)
	var kinds := by_kind(session)
	if groups.is_empty() and kinds.is_empty():
		_list.add_child(paragraph(tr(NOTHING_YET), Palette.MUTED))
	for g in groups:
		var box := add_card(_list, g["place"])
		for c: Clue in g["clues"]:
			box.add_child(paragraph("• " + c.text))
		for line: String in g["seen"]:
			box.add_child(paragraph("%s: %s" % [tr(SEEN), tr(line)], Palette.MUTED, UiTheme.SMALL))
	for kind: String in kinds:
		var box := add_card(_list, tr(KINDS.get(kind, kind)))
		for entry: Dictionary in kinds[kind]:
			box.add_child(paragraph(str(entry.get("text", "")), Palette.INK, UiTheme.SMALL))


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
	var box := add_card(_list, tr(FIXES), Palette.BLUE_PALE)
	for id in fixes:
		SustainView.add_fix(box, session, id, true)
	if not drift.is_empty():
		box.add_child(paragraph(drift, Palette.MUTED, UiTheme.SMALL))
