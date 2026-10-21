class_name TitleMenu
extends Control
## The title menu the game opens with (PLAN 2.7): the saves most recently
## used first (the autosave among them), each a card to continue from (a
## save that will not load keeps the menu, with a line that says so);
## "Nieuw spel" (the character creator, PLAN 2.7b, then a fresh game),
## "Instellingen" ("Tekst loopt vanzelf door", the rest later) and "Alles wissen" behind one
## confirmation. A new game's first autosave replaces the autosave, so when
## that holds a game "Nieuw spel" asks once: keep it in a slot first,
## replace it, or go back (PLAN §10, review S3).

## The player chose a save to continue from, or "" for a new game (the
## creator comes first).
signal start_requested(slot: String)

const SCENE := "res://src/ui/title_menu.tscn"
const OFFICE := "res://src/world/office/office.tscn"

const TITLE := "Spanning"
const SAVES := "Opgeslagen spellen"
const NO_SAVES := "Nog geen opgeslagen spel. Begin met \"Nieuw spel\"."
const PLAY := "Verder spelen"
const NEW_GAME := "Nieuw spel"
const SETTINGS := "Instellingen"
const SETTINGS_LATER := "Toetsen en camera: deze instellingen komen later. Voor nu speel je met WASD, de muis en E."
const WIPE := "Alles wissen"
const WIPE_ASK := "Alle opgeslagen spellen wissen? Ook het automatisch opgeslagen spel. Dit kan niet ongedaan worden gemaakt."
const WIPE_YES := "Ja, alles wissen"
const WIPED := "Alle opgeslagen spellen zijn gewist."
const BACK := "Terug"
const LOADING := "Voltana wordt geladen…"
const LOAD_FAILED := "Deze opslag kon niet geladen worden."
const REPLACE_ASK := "Je huidige spel staat in de automatische opslag en wordt vervangen."
const KEEP_FIRST := "Eerst bewaren in een slot"
const REPLACE := "Vervangen"
const KEEP_PICK := "Kies een slot voor je huidige spel. Daarna begint het nieuwe spel."
const KEEP_FAILED := "Bewaren is niet gelukt. Je huidige spel staat nog in de automatische opslag."

## The five slots' scrolling height (px), so "Terug" stays on a 900 px screen.
const KEEP_HEIGHT := 420.0

enum Page { MAIN, SETTINGS, WIPE, REPLACE, KEEP, OVERWRITE }

var saves := SaveSlots.new()
## The settings file (tests point it elsewhere).
var settings_path := SessionLog.SETTINGS
var page := Page.MAIN
## The saves' cards.
var list: SaveList
## The five slots to keep the autosave's game in (Page.KEEP).
var keep_list: SaveList
## A line under the menu (the wipe's result, an error).
var message := ""
var _menu: VBoxContainer
var _empty: Label
## The saves' column, out of the way while the five slots show (Page.KEEP).
var _saves_column: VBoxContainer
## The slot waiting for the overwrite answer (Page.OVERWRITE).
var _pending := 0
## The character creator over the menu while a new player is made, or null.
var creator: CreatorScreen


func _ready() -> void:
	build()
	start_requested.connect(_launch)


## Build the screen (once; tests build it outside the tree).
func build() -> void:
	if _menu != null:
		return
	theme = UiTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = _gradient()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 72 if side in ["left", "right"] else 56)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 56)
	margin.add_child(columns)
	columns.add_child(_left())
	_saves_column = _right()
	columns.add_child(_saves_column)
	refresh()


func _left() -> VBoxContainer:
	var info := GameInfo.load_from()
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 460
	left.add_theme_constant_override("separation", 6)
	left.add_child(UiPanel.label(tr(TITLE), 88, Color.WHITE))
	var sub := "%s · %s" % [info.company, info.region] if info.error.is_empty() else ""
	left.add_child(UiPanel.label(sub, 26, Palette.BLUE_PALE))
	var gap := Control.new()
	gap.custom_minimum_size.y = 40
	left.add_child(gap)
	var panel := PanelContainer.new()
	left.add_child(panel)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	panel.add_child(_menu)
	return left


func _right() -> VBoxContainer:
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(UiPanel.label(tr(SAVES), UiTheme.HEADING, Palette.VOLTANA_BLUE))
	box.add_child(HSeparator.new())
	_empty = UiPanel.paragraph(tr(NO_SAVES), Palette.MUTED)
	box.add_child(_empty)
	list = SaveList.new()
	list.action = tr(PLAY)
	list.picked.connect(start_requested.emit)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiPanel.add_scroll_list(box)
	column.add_child(list)
	return right


## The saves again, and the menu's page.
func refresh() -> void:
	list.now = saves.now.call()
	list.show_entries(saves.entries())
	_empty.visible = list.get_child_count() == 0
	UiPanel.clear(_menu)
	_saves_column.visible = page != Page.KEEP and page != Page.OVERWRITE
	match page:
		Page.MAIN:
			for item: Array in [[NEW_GAME, new_game], [SETTINGS, open_settings], [WIPE, ask_wipe]]:
				_menu.add_child(UiPanel.button(tr(item[0]), item[1]))
		Page.SETTINGS:
			_menu.add_child(UiPanel.label(tr(SETTINGS), UiTheme.HEADING, Palette.VOLTANA_BLUE))
			_menu.add_child(SceneLines.auto_toggle(settings_path))
			for c in Soundscape.settings_controls(settings_path):
				_menu.add_child(c)
			_menu.add_child(UiPanel.paragraph(tr(SETTINGS_LATER)))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
		Page.WIPE:
			_menu.add_child(UiPanel.paragraph(tr(WIPE_ASK)))
			_menu.add_child(UiPanel.button(tr(WIPE_YES), confirm_wipe))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
		Page.REPLACE:
			_menu.add_child(UiPanel.paragraph(tr(REPLACE_ASK)))
			for item: Array in [[KEEP_FIRST, keep_first], [REPLACE, replace_autosave], [BACK, cancel]]:
				_menu.add_child(UiPanel.button(tr(item[0]), item[1]))
		Page.KEEP:
			_menu.add_child(UiPanel.paragraph(tr(KEEP_PICK), Palette.MUTED, UiTheme.SMALL))
			keep_list = SaveList.new()
			keep_list.now = list.now
			keep_list.action = tr(PauseMenu.SAVE_HERE)
			keep_list.picked.connect(func(slot: String) -> void: keep_in(slot.to_int()))
			keep_list.show_manual(saves, true)
			UiPanel.add_scroll_list(_menu, KEEP_HEIGHT).add_child(keep_list)
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
		Page.OVERWRITE:
			_menu.add_child(UiPanel.paragraph(tr(PauseMenu.OVERWRITE) % _pending))
			_menu.add_child(UiPanel.button(tr(PauseMenu.YES), confirm_keep))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
	if not message.is_empty():
		_menu.add_child(UiPanel.paragraph(message, Palette.MUTED, UiTheme.SMALL))


## A fresh game. Its first autosave replaces the autosave, so when that
## holds a game the menu asks first (Page.REPLACE).
func new_game() -> void:
	if saves.entry(SaveSlots.AUTOSAVE).get("status") == SaveSlots.PLAYABLE:
		_go(Page.REPLACE)
	else:
		start_requested.emit("")


## "Eerst bewaren in een slot": the five slots, the empty ones first.
func keep_first() -> void:
	_go(Page.KEEP)


## "Vervangen": the new game starts; its first autosave replaces the old.
func replace_autosave() -> void:
	if page == Page.REPLACE:
		start_requested.emit("")


## A slot picked to keep the autosave's game in: an empty one at once, a
## filled one asks first.
func keep_in(number: int) -> void:
	if page != Page.KEEP or SaveSlots.manual(number).is_empty():
		return
	if saves.entry(SaveSlots.manual(number)).is_empty():
		_keep(number)
		return
	_pending = number
	_go(Page.OVERWRITE)


func confirm_keep() -> void:
	if page == Page.OVERWRITE:
		_keep(_pending)


## Copy the autosave into slot `number`, then start the new game; a failed
## copy starts nothing.
func _keep(number: int) -> void:
	var error := saves.copy_autosave(number)
	if error.is_empty():
		start_requested.emit("")
		return
	printerr("title menu: " + error)
	_say(tr(KEEP_FAILED))


func open_settings() -> void:
	_go(Page.SETTINGS)


func ask_wipe() -> void:
	_go(Page.WIPE)


func confirm_wipe() -> void:
	if page != Page.WIPE:
		return
	var error := saves.wipe()
	_say(tr(WIPED) if error.is_empty() else error)


## Back: to the slots from an overwrite question, else to the main page.
func cancel() -> void:
	_go(Page.KEEP if page == Page.OVERWRITE else Page.MAIN)


## The main page with a line under the menu.
func _say(line: String) -> void:
	page = Page.MAIN
	message = line
	refresh()


func _go(to: Page) -> void:
	page = to
	message = ""
	refresh()


## The character creator for a new game (PLAN 2.7b): HR's mail, the phone
## camera; its photo starts the game, Esc on the mail comes back here.
func open_creator() -> CreatorScreen:
	if creator != null:
		return creator
	creator = CreatorScreen.new()
	creator.setup(CreatorScreen.Mode.NEW)
	creator.build()
	add_child(creator)
	creator.done.connect(func(player: PlayerProfile) -> void:
		SessionLog.from_settings(SessionLog.SETTINGS, saves.dir).write("Pasfoto gemaakt na %d s" %
			roundi((Time.get_ticks_msec() - creator.opened_ms) / 1000.0))
		_launch("", player))
	creator.cancelled.connect(close_creator)
	return creator


func close_creator() -> void:
	if creator == null:
		return
	remove_child(creator)
	creator.queue_free()
	creator = null
	_go(Page.MAIN)


## Swap this menu for the office, playing from `slot`; a new game ("") is
## made in the creator first, `player` is who it made. The office takes a
## moment to build: the loading line shows first (behind the creator's dark).
func _launch(slot: String, player: PlayerProfile = null) -> void:
	if slot.is_empty() and player == null:
		open_creator()
		return
	UiPanel.clear(_menu)
	_menu.add_child(UiPanel.label(tr(LOADING), UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	await get_tree().process_frame
	await get_tree().process_frame
	var office := open_game(slot, player)
	if office == null:
		close_creator()
		return
	var tree := get_tree()
	tree.root.add_child(office)
	tree.current_scene = office
	queue_free()


## The office, ready to play from `slot` ("" a new game, played by `player`
## from the creator) and handed the loaded game; null when the save does not
## load: the menu stays, saying so, and the save is left alone (never a
## half-started game, review S1).
func open_game(slot: String, player: PlayerProfile = null) -> Office:
	var loaded := {}
	if not slot.is_empty():
		loaded = saves.resume(slot)
		if not loaded["error"].is_empty():
			printerr("title menu: " + loaded["error"])  # a log line, not an engine warning
			_say(tr(LOAD_FAILED))
			return null
	var office: Office = load(OFFICE).instantiate()
	office.saves = saves
	office.new_player = player
	office.opening = slot.is_empty()   # a new game opens as one scene (PLAN 2.7d)
	office.play(slot)
	office.resumed = loaded
	return office


static func _gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Palette.VOLTANA_BLUE)
	g.set_color(1, Palette.BLUE_LIGHT)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 1)
	return t
