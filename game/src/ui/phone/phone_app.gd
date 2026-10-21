class_name PhoneApp
extends VBoxContainer
## One app on the player's phone (Phone): it fills the phone's screen under
## the app bar. An app either draws its own list (Berichten, Opdrachten, Wie is
## wie, Instellingen) or carries one of the old panels inside it (the journal,
## the map, the codex: `carry`), so their code lives on in one place.

## The player did something that changed the session (GameUI refreshes).
signal acted

var session: GameSession
var layer: SessionLayer
## The phone turns sideways for this app (the map).
var landscape := false
## The old panel this app carries, or null.
var carried: UiPanel


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visible = false
	sort_children.connect(wrap_lines)   # whatever the app (or its carried panel) adds, as it lays out


## Carry `panel` inside the app: no title bar, no frame of its own, sized by
## the phone; its actions reach GameUI through the app.
func carry(panel: UiPanel) -> void:
	carried = panel
	panel.embed()
	panel.acted.connect(acted.emit)
	add_child(panel)


## Rebuild from the session (each time the app opens).
func refresh() -> void:
	if carried != null:
		carried.session = session
		carried.refresh()


## The app was opened: what it showed as new is now seen.
func opened() -> void:
	pass


## The phone went down (or another app opened) while this app showed.
func closed() -> void:
	pass


## The title in the phone's app bar: the carried panel's own, else "".
func title() -> String:
	return carried.title_label.text if carried != null else ""


## The ids of what is new in this app (its badge); none by default.
func unread() -> Array[String]:
	return []


## On the upright phone every line wraps: a line laid out for the old wide
## panels (a heading, a dossier line, a talk's state) would set the width of
## the whole app and run off the screen.
func wrap_lines() -> void:
	if landscape:
		return
	for n: Node in find_children("*", "Label", true, false):
		var l := n as Label
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF and not l.clip_text:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## A column that scrolls, filling the app, cleared first.
func scroll_list() -> VBoxContainer:
	UiPanel.clear(self)
	var column := UiPanel.add_scroll_list(self)
	column.add_theme_constant_override("separation", 10)
	return column
