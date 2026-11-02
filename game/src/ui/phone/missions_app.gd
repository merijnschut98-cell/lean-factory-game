class_name MissionsApp
extends PhoneApp
## Opdrachten (the phone): what the player is working on and what waits on
## the board, read-only. The active main with its next step and briefing, the
## sides beside it, then the board's list as the board shows it (MissionBoard's
## own offers and order). Taking one on still happens at the board by the
## entrance: the app says so, and has no button for it. A mission with a problem
## has your clipboard with its A3 at hand (PLAN 2.10: the A3 from anywhere).

## "Je klembord": the A3 asked for (GameUI opens it; the phone goes down).
signal a3_requested

const ACTIVE := "Nu bezig"
const NONE_ACTIVE := "Nog niets aangenomen."
const ON_THE_BOARD := "Op het bord"
const NONE_OPEN := "Er staat nu niets nieuws op het bord."
const AT_THE_BOARD := "Aannemen doe je bij het missiebord bij de ingang."
const NEXT := "Volgende stap: %s"
const CLIPBOARD := "Pak je klembord (A3)"


func refresh() -> void:
	var list := scroll_list()
	var active := UiPanel.add_card(list, tr(ACTIVE), Palette.BLUE_PALE)
	var missions := session.active_missions()
	if missions.is_empty():
		active.add_child(UiPanel.paragraph(tr(NONE_ACTIVE), Palette.MUTED, UiTheme.SMALL))
	var step := str(Objective.of(session, layer).get("text", ""))
	for m in missions:
		_mission(active, m)
		if m.kind != "side" and not step.is_empty():
			active.add_child(UiPanel.paragraph(tr(NEXT) % tr(step), Palette.GREEN_DARK, UiTheme.SMALL))
		active.add_child(UiPanel.paragraph(session.mission_briefing(m.id), Palette.INK, UiTheme.SMALL))
	if missions.any(func(m: MissionDef) -> bool: return not m.goal_problem.is_empty()):
		var clipboard := UiPanel.button(tr(CLIPBOARD), a3_requested.emit)
		clipboard.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		active.add_child(clipboard)
	var board := UiPanel.add_card(list, tr(ON_THE_BOARD))
	var offers := MissionBoard.offers_of(session, layer)   # as the board offers them
	if offers.is_empty():
		board.add_child(UiPanel.paragraph(tr(NONE_OPEN), Palette.MUTED, UiTheme.SMALL))
	for m in offers:
		_mission(board, m)
	board.add_child(UiPanel.paragraph(tr(AT_THE_BOARD), Palette.MUTED, UiTheme.SMALL))


## A mission's title and kind, where it sits in the story, and what a missed
## deadline closed.
func _mission(box: VBoxContainer, m: MissionDef) -> void:
	box.add_child(UiPanel.label("%s  ·  %s" % [UiText.mission_title(m, session), MissionBoard.kind_label(m)],
		UiTheme.SMALL, Palette.VOLTANA_BLUE, true))
	var where := MissionBoard.story(m)
	if not where.is_empty():
		box.add_child(UiPanel.label(where, 15, Palette.MUTED, true))
	if session.missions.failed(m.id):
		box.add_child(UiPanel.paragraph(MissionBoard.expiry_note(m), Palette.SAFETY_ORANGE, 15))

