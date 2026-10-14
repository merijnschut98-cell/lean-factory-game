class_name MissionBoard
extends UiPanel
## The mission board by the entrance: the active missions with their
## briefing, the ones that can be taken on now, and what is done. During the
## training week a returning player can skip it (after a confirm line).

var message := ""
## The skip's confirm line is showing.
var confirming_skip := false


func _init() -> void:
	super("Missiebord", Vector2(1000, 0))


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


## Skip the week: "" or the refusal code.
func confirm_skip() -> String:
	confirming_skip = false
	var refused := session.skip_training()
	message = ""
	acted.emit()
	refresh()
	return refused


func refresh() -> void:
	clear(body)
	if not message.is_empty():
		body.add_child(paragraph(message, Palette.SAFETY_ORANGE))
	var active := session.active_missions()
	var current := add_card(body, "Actief", Palette.BLUE_PALE)
	if active.is_empty():
		current.add_child(paragraph("Nog geen missie. Kies er hieronder een.", Palette.MUTED))
	for m in active:
		current.add_child(label("%s  ·  %s" % [_title(m), _kind(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
		current.add_child(paragraph(m.briefing))
	if session.in_training():
		_skip_row()
	var open := add_card(body, "Beschikbaar")
	if session.available_missions().is_empty():
		open.add_child(paragraph("Er staan nu geen nieuwe missies open.", Palette.MUTED))
	for m in session.available_missions():
		var row := HBoxContainer.new()
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(label("%s  ·  %s" % [_title(m), _kind(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
		text.add_child(paragraph(m.briefing, Palette.INK, UiTheme.SMALL))
		row.add_child(text)
		var take := button("Aannemen", accept.bind(m.id))
		take.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(take)
		open.add_child(row)
	var done := session.missions.defs.values().filter(
		func(m: MissionDef) -> bool: return session.missions.status(m.id) in ["completed", "failed"])
	if not done.is_empty():
		var past := add_card(body, "Afgerond")
		for m: MissionDef in done:
			var failed := session.missions.status(m.id) == "failed"
			past.add_child(label(("Verlopen: " if failed else "Voltooid: ") + _title(m), UiTheme.SMALL, Palette.MUTED))


## "Inwerkweek overslaan", or its confirm line with yes and no.
func _skip_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	if not confirming_skip:
		row.add_child(button("Inwerkweek overslaan", ask_skip))
		row.add_child(label("Voor wie het spel al kent.", UiTheme.SMALL, Palette.MUTED))
		return
	var confirm := paragraph(UiText.SKIP_CONFIRM, Palette.SAFETY_ORANGE, UiTheme.SMALL)
	row.add_child(confirm)
	row.add_child(button("Ja, overslaan", confirm_skip))
	row.add_child(button("Nee, oefenen", cancel_skip))


func _title(m: MissionDef) -> String:
	return UiText.mission_title(m, session)


static func _kind(m: MissionDef) -> String:
	match m.kind:
		"main":
			return "hoofdmissie"
		"training":
			return "oefendag"
	return "zijmissie"
