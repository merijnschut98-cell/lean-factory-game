class_name CodexPanel
extends UiPanel
## The codex (K), "Begrippen": the glossary by category. A concept the player
## has learned is readable (name, short, text, example, source); the others
## show "???", so the codex is a map of what is still to discover.

const CATEGORY_ORDER := ["lean", "kata", "measure", "sector"]
const CATEGORY_TITLES := {"lean": "Lean", "kata": "Kata", "measure": "Meten", "sector": "Energiesector"}
const UNKNOWN := "???"
const COLUMNS := 8

var _scroll: ScrollContainer
var _list: VBoxContainer


func _init() -> void:
	super("Begrippen", Vector2(1100, 0))
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 640)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)


## The concepts by category in codex order: [{title, known (count), entries}],
## each entry {def, known}; entries keep the glossary's own order.
static func groups(concepts: Dictionary, learned: PackedStringArray) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for category: String in CATEGORY_ORDER:
		var entries: Array[Dictionary] = []
		var known := 0
		for def: ConceptDef in concepts.values():
			if def.category == category:
				var is_known := def.id in learned
				known += int(is_known)
				entries.append({"def": def, "known": is_known})
		out.append({"title": CATEGORY_TITLES[category], "known": known, "entries": entries})
	return out


## "Bron: <title>" or "Schatting: <reasoning>", "" when the entry has neither.
static func source_line(def: ConceptDef) -> String:
	if not def.source_title.is_empty():
		return "Bron: " + def.source_title
	if not def.estimate.is_empty():
		return "Schatting: " + def.estimate
	return ""


func refresh() -> void:
	clear(_list)
	var all := groups(session.catalog.concepts, session.region.profile.concepts)
	var known := 0
	var total := 0
	for g in all:
		known += g["known"]
		total += g["entries"].size()
	_list.add_child(paragraph("Je kent %d van de %d begrippen. Wat je ontdekt op de werkvloer komt hier te staan." % [known, total], Palette.MUTED))
	for g in all:
		_add_group(g)


func _add_group(g: Dictionary) -> void:
	var box := add_card(_list, "%s  (%d/%d)" % [g["title"], g["known"], g["entries"].size()])
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 24)
	box.add_child(grid)
	for e in g["entries"]:
		if not e["known"]:
			grid.add_child(label(UNKNOWN, UiTheme.FONT_SIZE, Palette.MUTED))
	grid.visible = grid.get_child_count() > 0
	for e in g["entries"]:
		if e["known"]:
			_add_entry(box, e["def"])


func _add_entry(box: VBoxContainer, def: ConceptDef) -> void:
	box.add_child(label(def.name, UiTheme.FONT_SIZE, Palette.BLUE_LIGHT))
	box.add_child(paragraph(def.short))
	if not def.text.is_empty():
		box.add_child(paragraph(def.text, Palette.INK, UiTheme.SMALL))
	if not def.example.is_empty():
		box.add_child(paragraph("Voorbeeld: " + def.example, Palette.MUTED, UiTheme.SMALL))
	var source := source_line(def)
	if not source.is_empty():
		box.add_child(paragraph(source, Palette.MUTED, UiTheme.SMALL))
	box.add_child(HSeparator.new())


## Every text on the panel's list, for tests.
func shown_texts() -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [_list]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label:
			out.append(n.text)
		stack.append_array(n.get_children())
	return out
