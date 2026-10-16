class_name TerugblikCard
extends UiPanel
## The terugblik (engagement loop §2.1): when the game opens on a saved game,
## a card over the dagstart. Ruud's one line on the most important change
## since the last session, up to three lines (Veranderd · Wacht op je · Komt
## eraan, a date as a day name, never an hour countdown) and one button. It
## names people, numbers and dates; what to do is for the player. The journal
## reopens it. Words SessionLayer.terugblik's codes in Dutch.

const BUTTON := "Naar de dagstart"
const LABELS := {"changed": "Veranderd", "waiting": "Wacht op je", "coming": "Komt eraan"}
const WEEKDAYS: Array[String] = ["maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag", "zondag"]
const RUUD := {
	"completed": "'%s is af. Wat zag je daar dat je eerst niet zag?'",
	"check_ready": "'De Check van %s staat klaar. Wat verwacht je dat de cijfers zeggen, en waarom?'",
	"checkin": "'Bij %s zakt een verbetering weg. Wie merkte dat als eerste?'",
	"changed": "'%s ging van %s naar %s. Weet je al waardoor?'",
	"quiet": "'Fijn dat je er weer bent. Waar ga je vandaag als eerste kijken?'",
}
const WAITING := {
	"check_ready": "%s · de Check van \"%s\" staat klaar",
	"checkin": "%s · de verbetering bij \"%s\" zakt weg",
	"repair": "%s · \"%s\" kan nog beter",
	"main": "Ruud · er ligt een nieuwe hoofdmissie op het bord: %s",
	"talk": "%s · %s",
}
const COMING := {
	"check": "%s · de Check van \"%s\"",
	"deadline": "%s · de deadline van \"%s\"",
	"review": "%s · de kwartaalreview van het KPI-bord",
}
const MEASURES := {
	"lead_days_p50": ["De doorlooptijd bij %s", "dagen"],
	"on_time": ["Op tijd bij %s", "%"],
	"first_time_right": ["Eerste keer goed bij %s", "%"],
	"throughput_per_week": ["Afgerond per week bij %s", ""],
}
const ALSO_FOUND := "Ook ontdekt: %s (K)"

## The card shown (SessionLayer.terugblik).
var card := {}


func _init() -> void:
	super("Terugblik", Vector2(820, 0))
	# One button only: the header's close is hidden (Esc still closes).
	close_button.hide()


func show_card(of_card: Dictionary) -> void:
	card = of_card
	refresh()


func refresh() -> void:
	clear(body)
	if card.is_empty():
		return
	var coach := str(session.catalog.coach.get("name", "Ruud"))
	var head := add_card(body, coach, Palette.BLUE_PALE)
	head.add_child(paragraph(ruud_line(session, card), Palette.VOLTANA_BLUE))
	for line: Dictionary in card["lines"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var tag := label(LABELS[line["kind"]], UiTheme.SMALL, Palette.MUTED)
		tag.custom_minimum_size.x = 150
		row.add_child(tag)
		row.add_child(paragraph(line_text(session, line), _colour(line)))
		body.add_child(row)
	var found: Array = card.get("discoveries", [])
	if not found.is_empty():
		var names := found.map(func(id: String) -> String: return discovery_name(session, id))
		body.add_child(paragraph(ALSO_FOUND % ", ".join(names), Palette.MUTED, UiTheme.SMALL))
	var go := button(BUTTON, close_requested.emit)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(go)


static func _colour(line: Dictionary) -> Color:
	if line["kind"] != "changed":
		return Palette.INK
	return Palette.GREEN_DARK if line["better"] else Palette.SAFETY_ORANGE


# ── Wording ─────────────────────────────────────────────────────────────────

static func ruud_line(s: GameSession, of_card: Dictionary) -> String:
	var ruud: Dictionary = of_card["ruud"]
	match ruud["kind"]:
		"completed":
			return RUUD["completed"] % UiText.mission_title(s.missions.defs[ruud["mission"]], s)
		"check_ready":
			return RUUD["check_ready"] % ("\"%s\"" % s.region.problems[ruud["problem"]].name)
		"checkin":
			return RUUD["checkin"] % _team(s, s.region.problems[ruud["problem"]].step)
		"changed":
			var line: Dictionary = of_card["lines"].filter(func(l: Dictionary) -> bool: return l["kind"] == "changed")[0]
			return RUUD["changed"] % [_measure_name(s, line), _number(line, "before"), _number(line, "after")]
	return RUUD["quiet"]


static func line_text(s: GameSession, line: Dictionary) -> String:
	match line["kind"]:
		"changed":
			var arrow := "▲" if line["after"] > line["before"] else "▼"
			return "%s: %s → %s %s" % [_measure_name(s, line), _number(line, "before"), _number(line, "after"), arrow]
		"waiting":
			if line["what"] == "main":
				return WAITING["main"] % UiText.mission_title(s.missions.defs[line["mission"]], s)
			if line["what"] == "talk":   # a person by name, in their dagstart line (PLAN 1.4b)
				return TranslationServer.translate(WAITING["talk"]) % [line["name"], line["line"]]
			return WAITING[line["what"]] % [_team(s, line["place"]), s.region.problems[line["problem"]].name]
		"coming":
			return COMING[line["what"]] % _coming_args(s, line)
	return ""


static func _coming_args(s: GameSession, line: Dictionary) -> Variant:
	var day := day_name(s, line["t"])
	match line["what"]:
		"check":
			return [day, s.region.problems[line["id"]].name]
		"deadline":
			return [day, UiText.mission_title(s.missions.defs[line["id"]], s)]
	return day


static func _measure_name(s: GameSession, line: Dictionary) -> String:
	var stream := s.region.net.stream(line["stream"])
	return MEASURES[line["measure"]][0] % (stream.name if stream != null else line["stream"])


## A number with its unit: shares as percentages, days whole.
static func _number(line: Dictionary, key: String) -> String:
	var unit: String = MEASURES[line["measure"]][1]
	var value: float = line[key]
	if unit == "%":
		return "%d%%" % roundi(value * 100.0)
	return ("%d %s" % [roundi(value), unit]).strip_edges()


static func _team(s: GameSession, place: String) -> String:
	var step := s.region.net.step_at(place)
	return step.name if step != null else place


static func discovery_name(s: GameSession, id: String) -> String:
	return str(s.discoveries.defs.get(id, {}).get("name", id))


## A date ahead as a day name: vandaag, morgen, a weekday within the week,
## else a short date ("di 27 okt"). Never hours.
static func day_name(s: GameSession, t: int) -> String:
	var ahead := SimCalendar.day_of(t) - SimCalendar.day_of(s.region.net.time)
	if ahead <= 0:
		return "vandaag"
	if ahead == 1:
		return "morgen"
	if ahead < 7:
		return WEEKDAYS[SimCalendar.weekday(t)]
	var date := s.date_of(t)
	return "%s %d %s" % [GameSession.WEEKDAYS[SimCalendar.weekday(t)], date["day"], GameSession.MONTHS[date["month"] - 1]]
