class_name TitleMenu
extends Control
## The title menu the game opens with (PLAN 2.7): the saves most recently
## used first (the autosave among them), each a card to continue from;
## "Nieuw spel" (a fresh game, the saves untouched; the character creator
## 2.7b comes in front of it later), "Instellingen" (a stub for now) and
## "Alles wissen" behind one confirmation.

## The player chose a save to continue from, or "" for a new game.
signal start_requested(slot: String)

const SCENE := "res://src/ui/title_menu.tscn"
const OFFICE := "res://src/world/office/office.tscn"

const TITLE := "Spanning"
const SAVES := "Opgeslagen spellen"
const NO_SAVES := "Nog geen opgeslagen spel. Begin met \"Nieuw spel\"."
const PLAY := "Verder spelen"
const NEW_GAME := "Nieuw spel"
const SETTINGS := "Instellingen"
const SETTINGS_LATER := "Toetsen, camera en geluid: deze instellingen komen later. Voor nu speel je met WASD, de muis en E."
const WIPE := "Alles wissen"
const WIPE_ASK := "Alle opgeslagen spellen wissen? Ook het automatisch opgeslagen spel. Dit kan niet ongedaan worden gemaakt."
const WIPE_YES := "Ja, alles wissen"
const WIPED := "Alle opgeslagen spellen zijn gewist."
const BACK := "Terug"
const LOADING := "Voltana wordt geladen…"

enum Page { MAIN, SETTINGS, WIPE }

var saves := SaveSlots.new()
var page := Page.MAIN
## The saves' cards.
var list: SaveList
## A line under the menu (the wipe's result, an error).
var message := ""
var _menu: VBoxContainer
var _empty: Label


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
	columns.add_child(_right())
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
	match page:
		Page.MAIN:
			for item: Array in [[NEW_GAME, new_game], [SETTINGS, open_settings], [WIPE, ask_wipe]]:
				_menu.add_child(UiPanel.button(tr(item[0]), item[1]))
		Page.SETTINGS:
			_menu.add_child(UiPanel.label(tr(SETTINGS), UiTheme.HEADING, Palette.VOLTANA_BLUE))
			_menu.add_child(UiPanel.paragraph(tr(SETTINGS_LATER)))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
		Page.WIPE:
			_menu.add_child(UiPanel.paragraph(tr(WIPE_ASK)))
			_menu.add_child(UiPanel.button(tr(WIPE_YES), confirm_wipe))
			_menu.add_child(UiPanel.button(tr(BACK), cancel))
	if not message.is_empty():
		_menu.add_child(UiPanel.paragraph(message, Palette.MUTED, UiTheme.SMALL))


## A fresh game: no save is touched (the first autosave starts its own).
func new_game() -> void:
	start_requested.emit("")


func open_settings() -> void:
	_go(Page.SETTINGS)


func ask_wipe() -> void:
	_go(Page.WIPE)


func confirm_wipe() -> void:
	if page != Page.WIPE:
		return
	var error := saves.wipe()
	page = Page.MAIN
	message = tr(WIPED) if error.is_empty() else error
	refresh()


## Back to the main page.
func cancel() -> void:
	_go(Page.MAIN)


func _go(to: Page) -> void:
	page = to
	message = ""
	refresh()


## Swap this menu for the office, playing from `slot`. The office takes a
## moment to build: the loading line shows first.
func _launch(slot: String) -> void:
	UiPanel.clear(_menu)
	_menu.add_child(UiPanel.label(tr(LOADING), UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	await get_tree().process_frame
	await get_tree().process_frame
	var office: Office = load(OFFICE).instantiate()
	office.saves = saves
	office.play(slot)
	var tree := get_tree()
	tree.root.add_child(office)
	tree.current_scene = office
	queue_free()


static func _gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Palette.VOLTANA_BLUE)
	g.set_color(1, Palette.BLUE_LIGHT)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 1)
	return t
