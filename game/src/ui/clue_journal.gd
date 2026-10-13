class_name ClueJournal
extends UiPanel
## The clue journal (J): every clue the player has found, grouped by the
## place where it was found. It does not say which problem a clue belongs
## to, nor which clues matter: that is for the player to work out.


func _init() -> void:
	super("Aanwijzingen", Vector2(1000, 0))


## Every clue found so far, in the content's order.
static func found(s: GameSession) -> Array[Clue]:
	var out: Array[Clue] = []
	for p in s.region.problem_list():
		out.append_array(s.clues_found(p.id))
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
	clear(body)
	var groups := by_place(session)
	if groups.is_empty():
		body.add_child(paragraph("Nog niets gevonden. Ga naar de werkvloer en kijk, tel, meet en vraag.", Palette.MUTED))
	for g in groups:
		var box := add_card(body, g["place"])
		for c: Clue in g["clues"]:
			box.add_child(paragraph("• " + c.text))
