class_name DesignerPage
extends VBoxContainer
## The Ontwerper page on the title menu (Phase 3 slice 3.0, Designer): the designer saves that
## jump to a play day (tools/make_saves.gd writes them into DesignerSaves.DIR), one card each
## with its day and how it was made. A save made on old mission content says so. "Spelen" copies
## the save into the autosave and asks the title menu to continue from it.

## The title menu should continue from this slot (always the autosave).
signal play_requested(slot: String)
## "Praat opnieuw" (the replay of a talk, slice 3.0).
signal replay_requested
signal back_requested

const NONE := "Nog geen opslagen. Maak ze met: python tools/make_designer_saves.py"
const DAY := "dag %d"
const PLAY := "Spelen"
const REPLAY := "Praat opnieuw"
const LABELS := {
	"designer_training_done": "Opleiding klaar",
	"designer_day045": "Dag 45",
	"designer_day070": "Dag 70",
	"designer_day095": "Dag 95",
	"designer_act2": "Begin Akte II",
}

## The cards' scrolling height (px), so the buttons below stay on a 900 px screen.
const LIST_HEIGHT := 330.0

## The folder with the designer saves, and the folder whose autosave a pick replaces.
var dir := DesignerSaves.DIR
var autosave_dir := SaveFile.DIR
## What went wrong with the last pick, shown under the cards.
var message := ""


## Build (again) the cards and the buttons.
func build() -> void:
	UiPanel.clear(self)
	add_theme_constant_override("separation", 12)
	add_child(UiPanel.label(tr(TitleMenu.DESIGNER), UiTheme.HEADING, Palette.VOLTANA_BLUE))
	var found := entries()
	if found.is_empty():
		add_child(UiPanel.paragraph(tr(NONE), Palette.MUTED, UiTheme.SMALL))
	var column := UiPanel.add_scroll_list(self, LIST_HEIGHT if not found.is_empty() else 0.0)
	for e in found:
		_card(column, e)
	if not message.is_empty():
		add_child(UiPanel.paragraph(message, Palette.SAFETY_ORANGE, UiTheme.SMALL))
	add_child(UiPanel.button(tr(REPLAY), replay_requested.emit))
	add_child(UiPanel.button(tr(TitleMenu.BACK), back_requested.emit))


## The designer saves in `dir`, earliest play day first: {slot, label, persona, seed, play_day,
## stale}. Files that are not whole designer saves are left out.
func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var current := DesignerSaves.content_hash()
	if not DirAccess.dir_exists_absolute(dir):
		return out  # none made yet
	for file in DirAccess.get_files_at(dir):
		var slot := file.trim_suffix(".save")
		if slot == file or not SaveFile.valid_slot(slot):
			continue
		var loaded := SaveFile.load_slot(slot, dir)
		if loaded["fault"] != SaveFile.Fault.NONE:
			continue
		var meta := JsonFile.dict_or_empty(loaded["data"].get("meta"))
		var made := JsonFile.dict_or_empty(meta.get("designer"))
		if made.is_empty():
			continue
		var time: Variant = meta.get("time")
		out.append({"slot": slot, "label": LABELS.get(slot, slot), "persona": str(made.get("persona", "")),
			"seed": made["seed"] if made.get("seed") is int else 0,
			"play_day": SimCalendar.day_of(time) - GameSession.WARMUP_DAYS if time is int else -1,
			"stale": made.get("content_hash") != current})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["play_day"] < b["play_day"])
	return out


## Continue from designer save `slot`: it is copied into the autosave and the title menu starts
## the office from there. "" or the error, which the page shows.
func pick(slot: String) -> String:
	var error := DesignerSaves.load_into_autosave(slot, dir, autosave_dir)
	if error.is_empty():
		play_requested.emit(GameSave.AUTOSAVE)
		return ""
	message = error
	build()
	return error


func _card(parent: Node, e: Dictionary) -> void:
	var box := UiPanel.add_card(parent)
	var row := HBoxContainer.new()
	box.add_child(row)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	texts.add_child(UiPanel.label(e["label"], UiTheme.FONT_SIZE, Palette.VOLTANA_BLUE))
	texts.add_child(UiPanel.label("%s  ·  seed %d  ·  %s" % [e["persona"], e["seed"], tr(DAY) % e["play_day"]],
		UiTheme.SMALL, Palette.INK))
	var go := UiPanel.button(tr(PLAY), pick.bind(e["slot"]))
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(go)
	if e["stale"]:
		box.add_child(UiPanel.paragraph(tr(TitleMenu.STALE), Palette.SAFETY_ORANGE, UiTheme.SMALL))
