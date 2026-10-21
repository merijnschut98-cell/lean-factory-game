class_name SettingsApp
extends PhoneApp
## Instellingen (the phone): the game's switches, kept in the settings file.
## "Tekst loopt vanzelf door" (SceneLines' own switch, as in the pause menu
## and the title menu), the sound (Soundscape's "Geluid uit" and volume) and the playtest
## log (once on the journal). Each change
## is saved at once; the office follows the text switch (auto_text_changed).

## "Tekst loopt vanzelf door" switched (the scene on screen follows).
signal auto_text_changed(on: bool)
## The playtest log switched on or off (GameUI keeps it in the settings).
signal log_toggled(on: bool)

const TEXT := "Tekst"
const PLAYTEST := "Speellogboek"
const SOUND := "Geluid"
const LOG := "Speellogboek bijhouden (alleen op deze computer, nooit verstuurd)"

## The settings file (GameUI's; tests point it elsewhere).
var settings_path := SessionLog.SETTINGS


func refresh() -> void:
	var list := scroll_list()
	var text := UiPanel.add_card(list, tr(TEXT))
	var auto := SceneLines.auto_toggle(settings_path)
	auto.toggled.connect(auto_text_changed.emit)
	text.add_child(auto)
	var log_card := UiPanel.add_card(list, tr(PLAYTEST))
	var log_switch := CheckBox.new()
	log_switch.text = tr(LOG)
	log_switch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_switch.button_pressed = SessionLog.enabled_in(settings_path)
	log_switch.add_theme_font_size_override("font_size", UiTheme.SMALL)
	log_switch.toggled.connect(log_toggled.emit)
	log_card.add_child(log_switch)
	var sound_card := UiPanel.add_card(list, tr(SOUND))
	for c in Soundscape.settings_controls(settings_path):
		sound_card.add_child(c)
