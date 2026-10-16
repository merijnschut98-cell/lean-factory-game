class_name CodexPanel
extends UiPanel
## The codex (K), two tabs. "Begrippen": the glossary by category. A concept
## the player has learned is readable (name, short, text, example, source);
## the others are only counted ("Nog te ontdekken: N begrippen"). Categories
## fold; those with learned entries start open. "Ontdekkingen": the hidden
## rewards, found ones with their story, the rest as silhouettes with a hint
## once their act is over (Merijn, 2026-10-15), and the titles earned under
## the player's name.

const CATEGORY_ORDER := ["lean", "kata", "measure", "sector"]
const CATEGORY_TITLES := {"lean": "Lean", "kata": "Kata", "measure": "Meten", "sector": "Energiesector"}
const CONCEPTS := "concepts"
const DISCOVERIES := "discoveries"
const TABS := {CONCEPTS: "Begrippen", DISCOVERIES: "Ontdekkingen"}
const SILHOUETTE := "? ? ?"
const NO_HINT := "Nog verborgen."
const PLAYER := "Jij, CI-lead bij Voltana Netbeheer"
const NO_TITLES := "Nog geen titels. Die verdien je met wat je doet, niet met wat je aanklikt."

var tab := CONCEPTS
var _tabs: Dictionary[String, Button] = {}
var _list: VBoxContainer


func _init() -> void:
	super("Begrippen", Vector2(1100, 0))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	body.add_child(bar)
	for id: String in TABS:
		var b := button(TABS[id], show_tab.bind(id))
		b.toggle_mode = true
		_tabs[id] = b
		bar.add_child(b)
	_list = add_scroll_list(body, 640)
	_list.add_theme_constant_override("separation", 10)


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


## Switch the codex to a tab (CONCEPTS or DISCOVERIES).
func show_tab(id: String) -> void:
	tab = id
	refresh()


func refresh() -> void:
	clear(_list)
	title_label.text = TABS[tab]
	for id: String in _tabs:
		_tabs[id].set_pressed_no_signal(id == tab)
	if tab == DISCOVERIES:
		_discoveries()
		return
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
	var box := add_card(_list)
	var open: bool = g["known"] > 0
	var toggle := Button.new()
	toggle.flat = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_font_size_override("font_size", UiTheme.SMALL)
	toggle.add_theme_color_override("font_color", Palette.VOLTANA_BLUE)
	box.add_child(toggle)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.visible = open
	box.add_child(content)
	toggle.text = _toggle_text(g, open)
	toggle.pressed.connect(func() -> void:
		content.visible = not content.visible
		toggle.text = _toggle_text(g, content.visible))
	for e in g["entries"]:
		if e["known"]:
			_add_entry(content, e["def"])
	var unknown: int = g["entries"].size() - g["known"]
	if unknown > 0:
		content.add_child(label(undiscovered_line(unknown), UiTheme.SMALL, Palette.MUTED))


## The titles earned (a found discovery's reward title), in codex order.
static func titles(view: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for d in view:
		var title: String = d.get("reward", {}).get("title", "") if d["found"] else ""
		if not title.is_empty():
			out.append(title)
	return out


func _discoveries() -> void:
	var view := session.discoveries_view()
	var me := add_card(_list, "", Palette.BLUE_PALE)
	me.add_child(label(PLAYER, UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	var earned := titles(view)
	me.add_child(label(" · ".join(earned) if not earned.is_empty() else NO_TITLES, UiTheme.SMALL,
		Palette.GREEN_DARK if not earned.is_empty() else Palette.MUTED))
	var found := view.filter(func(d: Dictionary) -> bool: return d["found"]).size()
	_list.add_child(paragraph("Je vond %d van de %d ontdekkingen. Niemand vertelt je waar ze zitten." % [found, view.size()], Palette.MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_list.add_child(grid)
	for d in view:
		var box := add_card(grid, "", Color.WHITE if d["found"] else Palette.LINE)
		box.get_parent().custom_minimum_size = Vector2(340, 96)
		if d["found"]:
			_add_found(box, d)
		else:
			box.add_child(label(SILHOUETTE, UiTheme.HEADING, Palette.MUTED))
			box.add_child(paragraph(d["hint"] if not d["hint"].is_empty() else NO_HINT, Palette.MUTED, 15))


func _add_found(box: VBoxContainer, d: Dictionary) -> void:
	box.add_child(label(d["name"], UiTheme.FONT_SIZE, Palette.BLUE_LIGHT))
	box.add_child(paragraph(d["line"], Palette.INK, 15))
	var reward: Dictionary = d.get("reward", {})
	if reward.has("title"):
		box.add_child(label("Titel: " + reward["title"], 15, Palette.GREEN_DARK))
	if reward.has("object"):
		box.add_child(label(reward["object"], 15, Palette.GREEN_DARK))
	if reward.has("note"):
		box.add_child(paragraph("'%s'" % reward["note"], Palette.MUTED, 15))


## "Nog te ontdekken: N begrippen" (singular for one).
static func undiscovered_line(count: int) -> String:
	return "Nog te ontdekken: %d %s" % [count, "begrip" if count == 1 else "begrippen"]


func _toggle_text(g: Dictionary, open: bool) -> String:
	return "%s %s  (%d/%d)" % ["▼" if open else "▶", g["title"], g["known"], g["entries"].size()]


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
