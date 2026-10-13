class_name CoachPanel
extends UiPanel
## The coach, a senior manager, in her glass room. She coaches the main
## mission only and mostly answers with a Kata question.

var reply := ""


func _init() -> void:
	super("Coach", Vector2(900, 0))


## Ask for coaching: her reply in Dutch.
func ask() -> String:
	reply = UiText.coach_reply(session.ask_coach())
	acted.emit()
	refresh()
	return reply


func refresh() -> void:
	var coach: Dictionary = session.catalog.coach
	title_label.text = coach.get("name", "Coach")
	clear(body)
	body.add_child(label(coach.get("role", ""), UiTheme.SMALL, Palette.MUTED))
	var mains := session.missions.active("main")
	body.add_child(paragraph("Hoofdmissie: " + (mains[0].name if not mains.is_empty() else "nog geen")))
	var said := add_card(body, "", Palette.BLUE_PALE)
	said.add_child(paragraph(("'%s'" % reply) if not reply.is_empty()
		else "Ze kijkt op van haar scherm. 'Kom binnen. Waar sta je?'", Palette.VOLTANA_BLUE, 24))
	body.add_child(button("Vraag om coaching", ask))
	body.add_child(paragraph("Ze helpt alleen met je hoofdmissie, en antwoordt meestal met een vraag.", Palette.MUTED, UiTheme.SMALL))
