class_name PauseMenu
extends UiPanel
## The pause menu (PLAN 2.7): Esc when nothing else is open. "Opslaan" opens
## the five manual slots; picking a slot that holds a save asks once before
## it is overwritten. The autosave is not among them: the game keeps that
## one itself. "Uiterlijk" opens the character creator to change the look and
## the name (PLAN 2.7b: free, silent). "Naar het titelmenu" saves
## automatically and leaves. "Tekst loopt vanzelf door" switches the timed
## advance of a scene's lines (PLAN 2.13 A). "Toetsen tonen" brings the
## controls line back (Hud.show_controls, as F1). During the training week
## "Inwerkweek overslaan" skips it after one question (spec rule 6; UX audit #22:
## never a link in the scene). While it is up the game is paused
## (GameUI.open_pause); it runs on its own (PROCESS_MODE_ALWAYS).

## The player chose to save into manual slot `number` (1–5), confirmed.
signal save_requested(number: int)
signal title_requested
## "Uiterlijk": the player wants to change their look or name.
signal look_requested
## "Toetsen tonen": the controls line back on the HUD.
signal controls_requested
## "Inwerkweek overslaan", confirmed: the training week skipped.
signal skip_week_requested
## "Tekst loopt vanzelf door" switched (kept in the settings; the scene on screen follows).
signal auto_text_changed(on: bool)

const TITLE := "Pauze"
const RESUME := "Verder spelen"
const SAVE := "Opslaan"
const LOOK := "Uiterlijk"
const CONTROLS := "Toetsen tonen (F1)"
const SKIP_WEEK := "Inwerkweek overslaan"
const SKIP_YES := "Ja, overslaan"
const TO_TITLE := "Naar het titelmenu"
const PICK := "Kies een plek om op te slaan. Automatisch opslaan gebeurt apart, elke dagstart."
const SAVE_HERE := "Hier opslaan"
const OVERWRITE := "Slot %d bevat al een opgeslagen spel. Overschrijven?"
const YES := "Overschrijven"
const BACK := "Terug"

enum Page { MAIN, SLOTS, CONFIRM, SKIP }

## The saves (the game's own folder; tests point it elsewhere).
var saves: SaveSlots
## The settings file (tests point it elsewhere).
var settings_path := Settings.PATH
var page := Page.MAIN
## The slot waiting for the overwrite answer.
var pending := 0
var list: SaveList


func _init() -> void:
	super(TITLE, Vector2(760, 0))
	title_label.text = tr(TITLE)
	close_button.text = tr(CLOSE)


## Open on the main page.
func open() -> void:
	page = Page.MAIN
	pending = 0


func show_slots() -> void:
	page = Page.SLOTS
	refresh()


## A slot picked: an empty one saves at once, a filled one asks first.
func pick(number: int) -> void:
	if SaveSlots.manual(number).is_empty():
		return
	if saves.entry(SaveSlots.manual(number)).is_empty():
		save_requested.emit(number)
		return
	pending = number
	page = Page.CONFIRM
	refresh()


func ask_skip_week() -> void:
	page = Page.SKIP
	refresh()


func ask_look() -> void:
	look_requested.emit()


func confirm() -> void:
	if page == Page.CONFIRM:
		save_requested.emit(pending)


func back() -> void:
	page = Page.SLOTS if page == Page.CONFIRM else Page.MAIN
	refresh()


## Esc while paused (the world's keys are paused with it): back a page, or play on.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo or key.physical_keycode != KEY_ESCAPE:
		return
	if page == Page.MAIN:
		close_requested.emit()
	else:
		back()
	get_viewport().set_input_as_handled()


func refresh() -> void:
	clear(body)
	match page:
		Page.MAIN:
			# Opslaan, Uiterlijk and the title stay together, last
			var items: Array[Array] = [[RESUME, close_requested.emit], [CONTROLS, controls_requested.emit]]
			if session != null and session.in_training():
				items.append([SKIP_WEEK, ask_skip_week])
			items.append_array([[SAVE, show_slots], [LOOK, ask_look], [TO_TITLE, title_requested.emit]])
			for item: Array in items:
				var b := button(tr(item[0]), item[1])
				b.custom_minimum_size.x = 360
				b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				body.add_child(b)
			var auto := SceneLines.auto_toggle(settings_path)
			auto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			auto.toggled.connect(auto_text_changed.emit)
			body.add_child(auto)
			for c in Soundscape.settings_controls(settings_path):
				c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				body.add_child(c)
		Page.SLOTS:
			body.add_child(paragraph(tr(PICK), Palette.MUTED, UiTheme.SMALL))
			list = SaveList.new()
			list.action = tr(SAVE_HERE)
			list.picked.connect(func(slot: String) -> void: pick(slot.to_int()))
			list.show_manual(saves)
			body.add_child(list)
			body.add_child(_row([button(tr(BACK), back)]))
		Page.CONFIRM:
			body.add_child(paragraph(tr(OVERWRITE) % pending))
			body.add_child(_row([button(tr(BACK), back), button(tr(YES), confirm)]))
		Page.SKIP:
			body.add_child(paragraph(tr(UiText.SKIP_CONFIRM)))
			body.add_child(_row([button(tr(BACK), back), button(tr(SKIP_YES), skip_week_requested.emit)]))


static func _row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	for b: Button in buttons:
		row.add_child(b)
	return row
