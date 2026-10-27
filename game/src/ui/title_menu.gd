class_name TitleMenu
extends Control
## The title menu the game opens with (PLAN 2.7): the saves most recently
## used first (the autosave among them), each a card to continue from (a
## save that will not load keeps the menu, with a line that says so);
## "Nieuw spel" (the character creator, PLAN 2.7b, then a fresh game),
## "Inwerkweek overslaan" (the same, past the first day's scene and the training
## week: a returning player, spec rule 6),
## "Instellingen" ("Tekst loopt vanzelf door", the rest later), "Alles wissen" behind one
## confirmation and, for the designer only (Designer), "Ontwerper": the jump-to-day saves.
## A new game's first autosave replaces the autosave, so when that holds a
## game "Nieuw spel" asks once: keep it in a slot first, replace it, or go
## back (PLAN §10, review S3).

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
const SKIP_WEEK := "Inwerkweek overslaan"
const SETTINGS := "Instellingen"
const SETTINGS_LATER := "Toetsen en camera: deze instellingen komen later. Voor nu speel je met WASD, de muis en E."
const DESIGNER := "Ontwerper"
const STALE := "Oude inhoud: maak de opslag opnieuw (tools/make_designer_saves.py)"
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

enum Page { MAIN, SETTINGS, WIPE, REPLACE, KEEP, OVERWRITE, DESIGNER }

var saves := SaveSlots.new()
## The settings file (tests point it elsewhere).
var settings_path := Settings.PATH
## The designer's saves (tests point it elsewhere).
var designer_dir := DesignerSaves.DIR
var page := Page.MAIN
## The saves' cards.
var list: SaveList
## The designer's page (Page.DESIGNER), or null.
var designer: DesignerPage
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
## The designer save waiting for the answer about the autosave (Page.REPLACE, Page.KEEP), or "".
var _designer_slot := ""
## The new game skips the training week ("Inwerkweek overslaan").
var skip_week := false
## The character creator over the menu while a new player is made, or null.
var creator: CreatorScreen
## The designer's talk replay over the menu (TalkReplay), or null.
var replay: TalkReplay


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
	designer = null
	_saves_column.visible = page != Page.KEEP and page != Page.OVERWRITE
	match page:
		Page.MAIN:
			var items: Array[Array] = [[NEW_GAME, new_game], [SKIP_WEEK, new_game_skipping_week], [SETTINGS, open_settings],
				[WIPE, ask_wipe]]
			if Designer.enabled():
				items.append([DESIGNER, open_designer])
			for item in items:
				_menu.add_child(UiPanel.button(tr(item[0]), item[1]))
		Page.SETTINGS:
			_menu.add_child(UiPanel.label(tr(SETTINGS), UiTheme.HEADING, Palette.VOLTANA_BLUE))
			_menu.add_child(SceneLines.auto_toggle(settings_path))
			for c in Soundscape.settings_controls(settings_path):
				_menu.add_child(c)
			_menu.add_child(UiPanel.paragraph(tr(SETTINGS_LATER)))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
		Page.DESIGNER:
			designer = DesignerPage.new()
			designer.dir = designer_dir
			designer.autosave_dir = saves.dir
			designer.play_requested.connect(start_requested.emit)
			designer.back_requested.connect(cancel)
			designer.replace_requested.connect(_ask_replace_for)
			designer.replay_requested.connect(open_replay)
			designer.build()
			_menu.add_child(designer)
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


## "Inwerkweek overslaan": a new game that opens past the training week.
func new_game_skipping_week() -> void:
	skip_week = true
	new_game()


## "Eerst bewaren in een slot": the five slots, the empty ones first.
func keep_first() -> void:
	_go(Page.KEEP)


## "Vervangen": the new game (or the designer save) starts; it replaces the autosave.
func replace_autosave() -> void:
	if page == Page.REPLACE:
		_begin()


## The game starts: the pending designer save, else a new game.
func _begin() -> void:
	if _designer_slot.is_empty():
		start_requested.emit("")
		return
	var slot := _designer_slot
	_go(Page.DESIGNER)  # forgets the pending slot; the page shows an error from start()
	designer.start(slot)


## "Spelen" on designer save `slot` while the autosave holds a game: the same question as a new game.
func _ask_replace_for(slot: String) -> void:
	_designer_slot = slot
	_go(Page.REPLACE)


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
		_begin()
		return
	printerr("title menu: " + error)
	_say(tr(KEEP_FAILED))


func open_settings() -> void:
	_go(Page.SETTINGS)


func open_designer() -> void:
	if Designer.enabled():
		_go(Page.DESIGNER)


func ask_wipe() -> void:
	_go(Page.WIPE)


func confirm_wipe() -> void:
	if page != Page.WIPE:
		return
	var error := saves.wipe()
	_say(tr(WIPED) if error.is_empty() else error)


## Back: to the slots from an overwrite question; from the question about the autosave to the
## designer page when that is where it came from; else to the main page.
func cancel() -> void:
	if page == Page.OVERWRITE:
		_go(Page.KEEP)
		return
	_go(Page.DESIGNER if page == Page.REPLACE and not _designer_slot.is_empty() else Page.MAIN)


## The main page with a line under the menu.
func _say(line: String) -> void:
	_designer_slot = ""
	page = Page.MAIN
	message = line
	refresh()


## Show page `to`. The pending designer save lives only in the question about the autosave and
## the slots (Page.REPLACE, KEEP, OVERWRITE); any other page forgets it.
func _go(to: Page) -> void:
	if not to in [Page.REPLACE, Page.KEEP, Page.OVERWRITE]:
		_designer_slot = ""
		skip_week = false   # back on the menu: the next "Nieuw spel" is the full week
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
		SessionLog.from_settings(Settings.PATH, saves.dir).write("Pasfoto gemaakt na %d s" %
			roundi((Time.get_ticks_msec() - creator.opened_ms) / 1000.0))
		_launch("", player))
	creator.cancelled.connect(close_creator)
	return creator


## "Praat opnieuw" on the designer page: the list of talks over the menu (designer only).
func open_replay() -> void:
	if replay != null or not Designer.enabled():
		return
	replay = TalkReplay.new()
	replay.build()
	add_child(replay)
	replay.back_requested.connect(close_replay)


func close_replay() -> void:
	if replay == null:
		return
	remove_child(replay)
	replay.queue_free()
	replay = null


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
	office.training = not skip_week
	office.opening = slot.is_empty() and not skip_week   # a new game opens as one scene (PLAN 2.7d)
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
