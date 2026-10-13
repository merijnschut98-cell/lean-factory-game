class_name MissionBoard
extends UiPanel
## The mission board by the entrance: the active missions with their
## briefing, the ones that can be taken on now, and what is done.

var message := ""


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


func refresh() -> void:
	clear(body)
	if not message.is_empty():
		body.add_child(paragraph(message, Palette.SAFETY_ORANGE))
	var active := session.active_missions()
	var current := add_card(body, "Actief", Palette.BLUE_PALE)
	if active.is_empty():
		current.add_child(paragraph("Nog geen missie. Kies er hieronder een.", Palette.MUTED))
	for m in active:
		current.add_child(label("%s  ·  %s" % [m.name, _kind(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
		current.add_child(paragraph(m.briefing))
	var open := add_card(body, "Beschikbaar")
	if session.available_missions().is_empty():
		open.add_child(paragraph("Er staan nu geen nieuwe missies open.", Palette.MUTED))
	for m in session.available_missions():
		var row := HBoxContainer.new()
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(label("%s  ·  %s" % [m.name, _kind(m)], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
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
			past.add_child(label(("Verlopen: " if failed else "Voltooid: ") + m.name, UiTheme.SMALL, Palette.MUTED))


static func _kind(m: MissionDef) -> String:
	return "hoofdmissie" if m.kind == "main" else "zijmissie"
