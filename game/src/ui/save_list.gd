class_name SaveList
extends VBoxContainer
## A list of saves as cards (PLAN 2.7): the player's portrait, their name,
## the act, the game's date and when it was saved, and one button. The title
## menu lists the saves most recently used first (continue from one); the
## pause menu lists the five manual slots in order (save into one). A save
## that cannot be played says why and has no button.

## The player picked a slot (SaveSlots.names()).
signal picked(slot: String)

const NAMELESS := "Nieuwe CI-lead"
const AUTOSAVE := "Automatisch opgeslagen"
const SLOT := "Slot %d"
const EMPTY := "Leeg"
const SAVED := "Opgeslagen %s"
const TODAY := "vandaag %s"
const YESTERDAY := "gisteren %s"
const STATUS := {
	SaveSlots.TOO_OLD: "Te oud voor deze versie",
	SaveSlots.TOO_NEW: "Van een nieuwere versie van het spel",
	SaveSlots.DAMAGED: "Beschadigd: kan niet worden geladen",
}
const PORTRAIT := 72

## The button on each card that can be played ("Spelen", "Opslaan").
var action := ""
## The real time now (unix seconds), for "vandaag" and "gisteren".
var now: float = Time.get_unix_time_from_system()


## The saves in `entries` (SaveSlots.entry), in their order.
func show_entries(entries: Array[Dictionary]) -> void:
	UiPanel.clear(self)
	for e in entries:
		add_child(_card(e, e["slot"]))


## The five manual slots in order, an empty one as "Leeg" (the pause menu's
## picker: every slot can be saved into, also a damaged one). `empty_first`:
## the empty slots before the filled ones (the title menu keeping a game).
func show_manual(slots: SaveSlots, empty_first := false) -> void:
	UiPanel.clear(self)
	var filled: Array[PanelContainer] = []
	for n in range(1, SaveSlots.COUNT + 1):
		var slot := SaveSlots.manual(n)
		var e := slots.entry(slot)
		var card := _card(e, slot, true)
		if empty_first and not e.is_empty():
			filled.append(card)  # after the empty ones, in their order
		else:
			add_child(card)
	for card in filled:
		add_child(card)


## The card's button (null when there is none), for tests and screenshots.
func button_for(slot: String) -> Button:
	for card in get_children():
		if card.get_meta("slot", "") == slot:
			return card.find_child("Action", true, false) as Button
	return null


## A card: the portrait, the texts, the button. `always`: the button also
## on an empty or unplayable slot (saving over it).
func _card(e: Dictionary, slot: String, always := false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card(Color.WHITE))
	panel.set_meta("slot", slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	row.add_child(Portrait.new(e.is_empty() or e["status"] != SaveSlots.PLAYABLE))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var head := HBoxContainer.new()
	texts.add_child(head)
	var where := tr(AUTOSAVE) if slot == SaveSlots.AUTOSAVE else tr(SLOT) % slot.to_int()
	if e.is_empty():
		head.add_child(UiPanel.label(where, UiTheme.FONT_SIZE, Palette.MUTED))
		texts.add_child(UiPanel.label(tr(EMPTY), UiTheme.SMALL, Palette.MUTED))
	else:
		var name: String = e["name"] if not e["name"].is_empty() else tr(NAMELESS)
		head.add_child(UiPanel.label(name, UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
		head.add_child(UiPanel.label("·  " + where, UiTheme.SMALL, Palette.MUTED))
		for line in _lines(e):
			texts.add_child(UiPanel.label(line, UiTheme.SMALL, Palette.INK))
		if e["status"] != SaveSlots.PLAYABLE:
			texts.add_child(UiPanel.label(tr(STATUS[e["status"]]), UiTheme.SMALL, Palette.SAFETY_ORANGE))
	if always or (not e.is_empty() and e["status"] == SaveSlots.PLAYABLE):
		var go := UiPanel.button(action, picked.emit.bind(slot))
		go.name = "Action"
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(go)
	return panel


## The act and the game's date; when it was saved.
func _lines(e: Dictionary) -> Array[String]:
	var game: Array[String] = []
	var act := UiText.act_title(e["act"])
	if not act.is_empty():
		game.append(act)
	if e["time"] >= 0:
		game.append(GameSession.clock_at(e["time"]))
	var out: Array[String] = []
	if not game.is_empty():
		out.append("  ·  ".join(game))
	out.append(tr(SAVED) % when(e["saved"]))
	return out


## A real time in the player's own clock: "vandaag 14:32", "gisteren 09:05",
## else "12 okt 2026, 14:32".
func when(unix: float) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var at := Time.get_datetime_dict_from_unix_time(int(unix) + bias)
	var clock := "%02d:%02d" % [at["hour"], at["minute"]]
	var days := floori((int(now) + bias) / 86400.0) - floori((int(unix) + bias) / 86400.0)
	if days == 0:
		return tr(TODAY) % clock
	if days == 1:
		return tr(YESTERDAY) % clock
	return "%d %s %d, %s" % [at["day"], GameSession.MONTHS[at["month"] - 1], at["year"], clock]


## Where the player's portrait goes once the character creator (PLAN 2.7b)
## exists: a head and shoulders in Voltana's colours.
class Portrait extends Control:
	var faded := false

	func _init(is_faded: bool) -> void:
		faded = is_faded
		custom_minimum_size = Vector2(SaveList.PORTRAIT, SaveList.PORTRAIT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true  # the shoulders end at the frame

	func _draw() -> void:
		var s := size.x
		var ink := Palette.LINE if faded else Palette.BLUE_LIGHT
		draw_rect(Rect2(Vector2.ZERO, size), Palette.BLUE_PALE)
		draw_circle(Vector2(s / 2.0, s * 0.92), s * 0.36, ink)
		draw_circle(Vector2(s / 2.0, s * 0.4), s * 0.19, ink)
