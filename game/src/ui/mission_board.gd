class_name MissionBoard
extends UiPanel
## The mission board by the entrance: the active missions with their
## briefing, the ones that can be taken on now, and what is done. During the
## training week a returning player can skip it (after a confirm line).
## A missed deadline closes a door, not the mission: it stays open or active
## without its clock, with a line saying what was lost (Missions.failed).

## Under a mission whose deadline passed: its fail line (Henk has retired),
## or NO_CLOCK when it has none.
const EXPIRED := "Verlopen: %s De missie blijft open, nu zonder klok."
const NO_CLOCK := "de deadline is voorbij."
## Over a fork: two main missions open at once, and the player picks the order.
const FORK_HEADING := "Twee hoofdmissies tegelijk: welke pak je eerst aan?"
const REPAIR_KIND := "herstel"
## The drawer of side offers older than a week (SessionLayer.older_offers).
const OLDER := "Nog open"
## A safety mission's containment (audit §2.4.1): the button names the
## measure, its cost and how long it holds; once taken, until when.
const CONTAIN := "Indammen: %s  (%s, %d dagen)"
const CONTAINED := "Ingedamd tot %s: %s. De oorzaak is nog niet weg."

var message := ""
## Set by GameUI: holds back side offers (at most two new a week); null
## shows every available mission.
var layer: SessionLayer
## The "Nog open" drawer is unfolded.
var show_older := false
## The skip's confirm line is showing.
var confirming_skip := false
var _list: VBoxContainer


func _init() -> void:
	super("Missiebord", Vector2(1000, 0))
	_list = add_scroll_list(body, 700)


## The ids of the missions on the board that can be taken on now.
func listed() -> Array[String]:
	var out: Array[String] = []
	for m in session.available_missions():
		out.append(m.id)
	return out


## Take on a mission: "" or the refusal code (worded on the board).
func accept(mission_id: String) -> String:
	var refused := session.accept(mission_id)
	message = "" if refused.is_empty() else UiText.accept_error(refused)
	acted.emit()
	refresh()
	return refused


## Skipping the training week: first the confirm line.
func ask_skip() -> void:
	confirming_skip = true
	refresh()


func cancel_skip() -> void:
	confirming_skip = false
	refresh()


## Contain an active mission's acute risk: "" or the refusal code.
func contain(mission_id: String) -> String:
	var refused := session.contain(mission_id)
	message = "" if refused.is_empty() else UiText.accept_error(refused)
	acted.emit()
	refresh()
	return refused


static func contain_label(m: MissionDef) -> String:
	return TranslationServer.translate(CONTAIN) % [m.containment.get("name", ""),
		UiText.money(int(m.containment.get("budget", 0))), int(m.containment.get("days", 0))]


## Under an active mission with a containment: the button, or until when it holds.
func _add_containment(parent: Node, m: MissionDef) -> void:
	if m.containment.is_empty():
		return
	if session.missions.contained.has(m.id):
		var until: int = session.missions.contained[m.id]
		parent.add_child(paragraph(tr(CONTAINED) % [session.day_text(until), m.containment.get("name", "")],
			Palette.MUTED, UiTheme.SMALL))
		return
	var b := button(contain_label(m), contain.bind(m.id))
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	parent.add_child(b)


## Skip the week: "" or the refusal code.
func confirm_skip() -> String:
	confirming_skip = false
	var refused := session.skip_training()
	message = ""
	acted.emit()
	refresh()
	return refused


func refresh() -> void:
	clear(_list)
	if not message.is_empty():
		_list.add_child(paragraph(message, Palette.SAFETY_ORANGE))
	var active := session.active_missions()
	var current := add_card(_list, "Actief", Palette.BLUE_PALE)
	if active.is_empty():
		current.add_child(paragraph("Nog geen missie. Kies er hieronder een.", Palette.MUTED))
	for m in active:
		current.add_child(label("%s  ·  %s" % [_title(m), kind_label(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
		var where := story(m)
		if not where.is_empty():
			current.add_child(label(where, 15, Palette.MUTED))
		current.add_child(paragraph(session.mission_briefing(m.id)))
		_add_containment(current, m)
		_add_expiry(current, m)
	if session.in_training():
		_skip_row()
	var open := add_card(_list, "Beschikbaar")
	var offered := offers()
	if offered.is_empty():
		open.add_child(paragraph("Er staan nu geen nieuwe missies open.", Palette.MUTED))
	var shown_story := ""
	for row: Array in rows(offered):
		if story(row[0]) != shown_story:
			shown_story = story(row[0])
			open.add_child(label(shown_story, UiTheme.SMALL, Palette.MUTED))
		if row.size() == 1:
			_offer_row(open, row[0])
			continue
		var fork := add_card(open, FORK_HEADING, Palette.BLUE_PALE)
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 16)
		fork.add_child(pair)
		for m: MissionDef in row:
			_offer_row(pair, m)
	_older_drawer()
	var done := session.missions.defs.values().filter(
		func(m: MissionDef) -> bool: return session.missions.status(m.id) == "completed")
	if not done.is_empty():
		var past := add_card(_list, "Afgerond")
		for m: MissionDef in done:
			past.add_child(label("Voltooid: " + _title(m), UiTheme.SMALL, Palette.MUTED))


## The board's rows: one mission each, except a fork's missions, which
## share the row of the first one (shown as a pair).
static func rows(missions: Array[MissionDef]) -> Array:
	var out: Array = []
	var forks := {}
	for m in missions:
		if m.fork_group.is_empty():
			out.append([m])
		elif forks.has(m.fork_group):
			forks[m.fork_group].append(m)
		else:
			forks[m.fork_group] = [m]
			out.append(forks[m.fork_group])
	return out


## The missions offered as new: all available ones, or with the session
## layer at most two new sides a week (SessionLayer.new_offers).
func offers() -> Array[MissionDef]:
	return offers_of(session, layer)


static func offers_of(s: GameSession, of_layer: SessionLayer) -> Array[MissionDef]:
	return of_layer.new_offers(s) if of_layer != null else s.available_missions()


func toggle_older() -> void:
	show_older = not show_older
	refresh()


## Sides offered more than a week ago, folded under "Nog open": never lost.
func _older_drawer() -> void:
	if layer == null:
		return
	var older := layer.older_offers(session)
	if older.is_empty():
		return
	var drawer := add_card(_list)
	drawer.add_child(button("%s (%d)  %s" % [OLDER, older.size(), "▴" if show_older else "▾"], toggle_older))
	for m in older if show_older else []:
		_offer_row(drawer, m)


## A mission that can be taken on: its title, briefing and "Aannemen" (the
## act and chapter head its group).
func _offer_row(parent: Node, m: MissionDef) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(label("%s  ·  %s" % [_title(m), kind_label(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	text.add_child(paragraph(session.mission_briefing(m.id), Palette.INK, UiTheme.SMALL))
	_add_expiry(text, m)
	row.add_child(text)
	var take := button("Aannemen", accept.bind(m.id))
	take.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(take)
	parent.add_child(row)


## Where a mission sits in the story: "Akte I · … — De stapel"; "" for a
## training day (its title says it) or a mission outside the acts.
static func story(m: MissionDef) -> String:
	if m.kind == "training":
		return ""
	var parts := [UiText.act_title(m.act), m.chapter].filter(func(p: String) -> bool: return not p.is_empty())
	return " — ".join(PackedStringArray(parts))


## "Inwerkweek overslaan", or its confirm line with yes and no.
func _skip_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_list.add_child(row)
	if not confirming_skip:
		row.add_child(button("Inwerkweek overslaan", ask_skip))
		row.add_child(label("Voor wie het spel al kent.", UiTheme.SMALL, Palette.MUTED))
		return
	var confirm := paragraph(UiText.SKIP_CONFIRM, Palette.SAFETY_ORANGE, UiTheme.SMALL)
	row.add_child(confirm)
	row.add_child(button("Ja, overslaan", confirm_skip))
	row.add_child(button("Nee, oefenen", cancel_skip))


## What a missed deadline closed, under a mission still open or active.
func _add_expiry(parent: Node, m: MissionDef) -> void:
	if session.missions.failed(m.id):
		parent.add_child(paragraph(expiry_note(m), Palette.SAFETY_ORANGE, UiTheme.SMALL))


static func expiry_note(m: MissionDef) -> String:
	return EXPIRED % (m.fail_text if not m.fail_text.is_empty() else NO_CLOCK)


func _title(m: MissionDef) -> String:
	return UiText.mission_title(m, session)


static func kind_label(m: MissionDef) -> String:
	if m.goal_type == "rework_fix":
		return REPAIR_KIND
	match m.kind:
		"main":
			return "hoofdmissie"
		"training":
			return "oefendag"
	return "zijmissie"
