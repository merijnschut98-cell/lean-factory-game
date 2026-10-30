class_name IntussenPanel
extends UiPanel
## Intussen (engagement loop §2.4): while an experiment runs, what happens
## meanwhile. The Check's day, the beats before it, who has something to say,
## the side missions that fit in the gap, and a named time skip that stops at
## beats with people. Information, never a nag: skipping is always allowed.
## Words SessionLayer.intussen and skip_to_check in Dutch.

const SKIP := "Spoel door tot de Check: %d dagen"
const CHECK_ON := "De Check van \"%s\" is %s, over %d %s."
const STOPS := "De skip stopt vanzelf bij mensen die op je wachten: %s."
const NO_STOPS := "Niemand wacht op een vaste datum: de skip loopt door tot de Check, of tot iemand je wil spreken."
const NOTHING := "Niets op de agenda voor de Check."
const FITS := "Past in de %d %s tot de Check"
const READY := "De Check staat klaar. Ga naar de Obeya en kijk wat de cijfers zeggen."
const STOPPED := {
	"deadline": "Gestopt op %s: \"%s\" verloopt %s.",
	"review": "Gestopt op %s: de kwartaalreview van het KPI-bord is %s.",
	"checkin": "Gestopt op %s: %s",
}

var layer: SessionLayer
var problem_id := ""
## What the last skip did, worded; "" before one.
var message := ""


func _init() -> void:
	super("Intussen", Vector2(860, 0))


func open_for(of_problem: String) -> void:
	problem_id = of_problem
	message = ""


## Skip towards the Check (SessionLayer.skip_to_check); the result is worded
## in `message`. Returns the layer's result.
func skip() -> Dictionary:
	var result := layer.skip_to_check(session, problem_id)
	message = stopped_text(session, result) if not result.has("error") else ""
	acted.emit()
	refresh()
	return result


func refresh() -> void:
	clear(body)
	if not message.is_empty():
		body.add_child(paragraph(message, Palette.VOLTANA_BLUE))
	var view := layer.intussen(session, problem_id)
	if view.has("error"):
		return
	var name := session.region.problems[problem_id].name
	body.add_child(paragraph(CHECK_ON % [name, TerugblikCard.day_name(session, view["check_at"]), view["days"],
		_days_word(view["days"])]))
	var agenda := add_card(body, "Voor de Check")
	if view["beats"].is_empty():
		agenda.add_child(paragraph(NOTHING, Palette.MUTED, UiTheme.SMALL))
	for beat: Dictionary in view["beats"]:
		agenda.add_child(paragraph(_coming(session, beat)))
	if not view["people"].is_empty():
		var people := add_card(body, "Wie wil je spreken")
		for line: Dictionary in view["people"]:
			people.add_child(paragraph(TerugblikCard.line_text(session, line)))
	if not view["sides"].is_empty():
		var sides := add_card(body, FITS % [view["days"], _days_word(view["days"])])
		for m: MissionDef in view["sides"]:
			sides.add_child(paragraph(UiText.mission_title(m, session)))
	var stops: Array = view["beats"].filter(func(b: Dictionary) -> bool: return b["person"])
	var names := stops.map(func(b: Dictionary) -> String: return _coming(session, b))
	body.add_child(paragraph(STOPS % "; ".join(names) if not stops.is_empty() else NO_STOPS, Palette.MUTED, UiTheme.SMALL))
	var go := button(SKIP % view["days"], skip)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(go)


## A skip's result in a line: where it stopped, or that the Check is ready.
static func stopped_text(s: GameSession, result: Dictionary) -> String:
	var stop: String = result["stopped"]
	if stop.is_empty():
		return READY
	var day := s.clock_text()
	match stop:
		"deadline":
			var t: int = s.missions.opened_at[result["id"]] + SimCalendar.days(s.missions.defs[result["id"]].deadline_days)
			return STOPPED["deadline"] % [day, UiText.mission_title(s.missions.defs[result["id"]], s), TerugblikCard.day_name(s, t)]
		"review":
			return STOPPED["review"] % [day, TerugblikCard.day_name(s, s.region.board.next_review_at)]
		"talk":   # the person whose check-in came due, in their dagstart line
			for p in s.checkin_prompts():
				if p["person"] == result["id"]:
					return STOPPED["checkin"] % [day, TerugblikCard.line_text(s, {"kind": "waiting", "what": "talk",
						"name": p["name"], "line": p["line"]})]
			var who: PersonDef = s.people.persons.get(result["id"])
			return STOPPED["checkin"] % [day, who.name if who != null else result["id"]]
	var m: MissionDef = s.missions.defs[result["id"]]
	return STOPPED["checkin"] % [day, TerugblikCard.line_text(s, {"kind": "waiting",
		"what": "checkin" if m.id.begins_with(Missions.CHECKIN_PREFIX) else "repair",
		"place": s.region.problems[m.goal_problem].step, "problem": m.goal_problem})]


## A beat ({what, t, id}) as a "Komt eraan" line.
static func _coming(s: GameSession, beat: Dictionary) -> String:
	var line := beat.duplicate()
	line["kind"] = "coming"
	return TerugblikCard.line_text(s, line)


static func _days_word(n: int) -> String:
	return "dag" if n == 1 else "dagen"
