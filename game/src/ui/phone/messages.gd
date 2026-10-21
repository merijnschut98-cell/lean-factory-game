class_name PhoneMessages
extends PhoneApp
## Berichten (the phone, design 2026-10-21 §1.8): the messages that reach the
## player, newest first. Ruud's note on a training morning (the day's gemba
## tools and talk moves, once on the journal's Briefjes tab), his debrief of a
## training day with what was measured, his question when the week is over,
## and the first day's phone messages (B6). Each arrives once into the
## session layer's inbox (saved, with whether it was read); a message not yet
## read badges the app, and its arrival buzzes the phone (GameUI).
##
## Inbox ids: "note:<training day>", "debrief:<training day>", "week_end",
## "opening:<n>" (OfficeOpening.PHONE's n-th). The text is worded when shown,
## so a translation reads the current words.

const NOTE_HEADING := "Briefje van Ruud · %s"
const DEBRIEF_HEADING := "Terugblik op %s"
const WEEK_END_HEADING := "Je eerste week"
const NONE := "Nog geen berichten."
const NOTE := "note:"
const DEBRIEF := "debrief:"
const WEEK_END := "week_end"
const OPENING := "opening:"


func refresh() -> void:
	var list := scroll_list()
	var inbox := layer.inbox if layer != null else []
	if inbox.is_empty():
		list.add_child(UiPanel.paragraph(tr(NONE), Palette.MUTED))
	for i in range(inbox.size() - 1, -1, -1):
		var m := render(session, inbox[i])
		if m.is_empty():
			continue
		var box := UiPanel.add_card(list, "", m["paper"])
		var from := UiPanel.label(m["from"], 15, Palette.MUTED)
		box.add_child(from)
		if not inbox[i]["read"]:
			from.add_theme_color_override("font_color", Palette.GREEN_DARK)
		box.add_child(UiPanel.label(m["heading"], UiTheme.SMALL, Palette.VOLTANA_BLUE, true))
		for line: String in m["lines"]:
			box.add_child(UiPanel.paragraph(line, Palette.INK, UiTheme.SMALL))


## Opening Berichten reads every message in it.
func opened() -> void:
	for entry: Dictionary in layer.inbox:
		entry["read"] = true


func unread() -> Array[String]:
	return unread_in(layer)


static func unread_in(of_layer: SessionLayer) -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in of_layer.inbox:
		if not entry["read"]:
			out.append(entry["id"])
	return out


## Put message `id` in the inbox once (unread), arrived at `at` (game minutes),
## with `extra` for its wording (a debrief's measured queues).
static func push(of_layer: SessionLayer, id: String, at: int, extra: Dictionary = {}) -> void:
	if of_layer.inbox.any(func(e: Dictionary) -> bool: return e["id"] == id):
		return
	var entry := {"id": id, "at": at, "read": false}
	entry.merge(extra)
	of_layer.inbox.append(entry)


## The messages that arrive from the game's state: a training morning's note
## (the days the session layer carded), the first day's phone messages once
## its evening is reached (B6), and Ruud's question when the week is over.
static func sync(s: GameSession, of_layer: SessionLayer) -> void:
	var now := s.region.net.time
	for id: String in of_layer.carded:
		if not note_lines(s, id).is_empty():
			push(of_layer, NOTE + id, now)
	if Opening.running(of_layer) and Opening.reached(of_layer, Opening.EVENING):
		for n in OfficeOpening.PHONE.size():
			push(of_layer, OPENING + str(n), now)
	if week_over(s):
		push(of_layer, WEEK_END, now)


## A message as shown: {from, heading, lines, paper}; {} for an unknown one.
static func render(s: GameSession, entry: Dictionary) -> Dictionary:
	var id: String = entry["id"]
	var ruud := str(s.catalog.coach.get("name", "Ruud"))
	var when := s.day_text(entry["at"])
	if id.begins_with(NOTE):
		var m: MissionDef = s.missions.defs.get(id.trim_prefix(NOTE))
		if m == null:
			return {}
		return {"from": "%s · %s" % [ruud, when], "heading": _tr(NOTE_HEADING) % UiText.mission_title(m, s),
			"lines": note_lines(s, m.id), "paper": Palette.NOTE_PAPER}
	if id.begins_with(DEBRIEF):
		var m: MissionDef = s.missions.defs.get(id.trim_prefix(DEBRIEF))
		if m == null:
			return {}
		var lines: Array[String] = ["'%s'" % s.mission_debrief(m.id)]
		var queues := JsonFile.dict_or_empty(entry.get("queues"))
		if not queues.is_empty():
			var place_names := {}
			for place: String in queues:
				var step := s.region.net.step_at(place)
				place_names[place] = step.name if step != null else place
			lines.append(UiText.queue_lesson(queues, place_names))
		return {"from": "%s · %s" % [ruud, when], "heading": _tr(DEBRIEF_HEADING) % UiText.mission_title(m, s),
			"lines": lines, "paper": Color.WHITE}
	if id == WEEK_END:
		var line := str(JsonFile.dict_or_empty(s.catalog.dialog_bank.get("ruud_names")).get("week_end", ""))
		return {"from": "%s · %s" % [ruud, when], "heading": _tr(WEEK_END_HEADING),
			"lines": ["'%s'" % line] as Array[String], "paper": Palette.NOTE_PAPER} if not line.is_empty() else {}
	if id.begins_with(OPENING):
		var n := id.trim_prefix(OPENING).to_int()
		if n < 0 or n >= OfficeOpening.PHONE.size():
			return {}
		var p: Array = OfficeOpening.PHONE[n]
		return {"from": "%s · %s" % [_tr(p[0]), p[1]], "heading": _tr(p[0]), "lines": [_tr(p[2])] as Array[String],
			"paper": Color.WHITE}
	return {}


## Ruud's note of every training morning so far (the days the session layer carded),
## newest first: [{mission, heading, lines}].
static func notes(s: GameSession, of_layer: SessionLayer) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in of_layer.carded if of_layer != null else []:
		var m: MissionDef = s.missions.defs.get(id)
		var lines := note_lines(s, id)
		if m != null and not lines.is_empty():
			out.push_front({"mission": id, "heading": _tr(NOTE_HEADING) % UiText.mission_title(m, s), "lines": lines})
	return out


## A training morning's note: the gemba tools the day hands out (places.yaml
## tool_cards), then the day's move cards, each its name, what it is and why
## (tutorial talks spec §2); never when to use it. Empty for a day without either.
static func note_lines(s: GameSession, mission_id: String) -> Array[String]:
	var lines: Array[String] = []
	if not s.missions.defs.has(mission_id):
		return lines
	for tool in s.new_tools(mission_id):
		var tool_card := s.tool_card(tool)
		if not tool_card.is_empty():
			lines.append("%s. %s" % [_tr(tool_card["title"]), _tr(tool_card["text"])])
	for card: Dictionary in s.catalog.move_cards:
		if card["day"] == mission_id:
			lines.append("%s. %s" % [card["title"], card["text"]])
			lines.append("'%s'" % card["why"])
	return lines


## Whether the training week is over: every tutorial talk of its last day had.
static func week_over(s: GameSession) -> bool:
	var training := s.missions.defs.values().filter(func(m: MissionDef) -> bool: return m.kind == "training")
	if training.is_empty():
		return false
	var last: String = training[-1].id
	var talks := s.people.dialogs.values().filter(func(d: DialogDef) -> bool: return d.tutorial and d.mission == last)
	return not talks.is_empty() and talks.all(func(d: DialogDef) -> bool: return s.people.outcomes.has(d.id))


static func _tr(text: String) -> String:
	return TranslationServer.translate(text)
