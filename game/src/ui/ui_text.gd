class_name UiText
## The Dutch words for the rules' codes: tools, questions, replies, wastes,
## KPIs, refusals, Check lessons and score notes. The rules return ids and
## numbers; only this file words them. Nothing here marks an answer as the
## right one: questions do not say what kind they are, causes and
## countermeasures are worded by the content itself.

const TOOLS := {
	"shadow": "Meelopen",
	"time_study": "Tijdstudie",
	"queue_count": "Wachtrij tellen",
	"data": "Data analyseren",
	"documents": "Dossiers doorlezen",
	"listen_in": "Meeluisteren klantcontact",
	"material_check": "Materiaal checken",
	"conversation": "Gesprek",
}

const QUESTIONS := {
	"walk": "Wil je me stap voor stap laten zien hoe je werkt?",
	"obstacle": "Wat maakt dit werk lastiger dan nodig?",
	"last": "Kun je laten zien wat er de laatste keer misging?",
	"standard": "Volgen jullie de standaard?",
	"ok": "Loopt alles goed vandaag?",
	"behind": "Waarom lopen jullie altijd achter?",
	"who": "Wie heeft de laatste fout gemaakt?",
	"thanks": "Uitleggen dat je het proces wilt verbeteren, niet mensen beoordelen, en ze bedanken.",
}

## TIMWOODS, in the words of a service and field organisation.
const WASTES := {
	"transport": "Transport (dossiers en mensen onderweg)",
	"inventory": "Voorraad (werk dat op de plank ligt)",
	"motion": "Beweging (zoeken, lopen, klikken)",
	"waiting": "Wachten",
	"overproduction": "Overproductie (meer of eerder dan nodig)",
	"overprocessing": "Overbewerking (meer werk dan de klant nodig heeft)",
	"defects": "Fouten en herstelwerk",
	"skills": "Onbenut talent",
}

const KPIS := {
	"throughput": "Doorzet (gereed per week)",
	"lead_time": "Doorlooptijd end-to-end",
	"first_time_right": "Eerste keer goed",
	"on_time": "Op tijd (binnen de norm)",
	"wip_age": "Leeftijd van het onderhanden werk",
	"capacity": "Capaciteit van de stroom",
}

const BELTS := {
	"white": "Witte band", "yellow": "Gele band", "green": "Groene band",
	"black": "Zwarte band", "master_black": "Master Black Belt",
}

const REPLIES := {
	"closed": "'Ja hoor. Meestal wel.' Ze wachten tot je weer gaat.",
	"blame": "'...We doen ons best.' Ze draaien zich terug naar hun scherm en kijken je niet meer aan.",
	"guarded": "'Het gaat prima hoor.' Na die vorige vraag houden ze zich op de vlakte.",
	"repair": "Ze ontspannen een beetje. 'Oké... wat wil je weten?'",
	"welcome": "'Fijn dat je het zo zegt. Vraag maar raak.'",
	"nobody": "Er is hier niemand om mee te praten.",
}

const A3_ERRORS := {
	"not_spotted": "Je hebt het probleem nog niet zelf gezien. Ga eerst naar de gemba.",
	"waste": "Welke verspilling zie je? Kies er een.",
	"cause": "Kies de oorzaak die je denkt te hebben gevonden.",
	"evidence": "Onderbouw je oorzaak met minstens één aanwijzing die je zelf hebt gevonden.",
	"countermeasure": "Kies een tegenmaatregel die de regio nu kan proberen.",
	"prediction": "Op welke KPI verwacht je het effect? Kies er een.",
	"unknown_problem": "Er ligt geen probleem op de obeya-wand.",
	"not_doing": "Er loopt geen experiment.",
	"not_check_ready": "De Check is nog niet klaar.",
	"not_checked": "Doe eerst de Check.",
}

const ACCEPT_ERRORS := {
	"unknown": "Deze missie bestaat niet.",
	"not_available": "Deze missie is niet meer beschikbaar.",
	"locked": "Deze missie gaat later open.",
	"main_active": "Je hebt al een hoofdmissie. Maak die eerst af.",
	"side_full": "Je hebt al drie zijmissies.",
	"problem_unavailable": "Dit probleem kan nu niet worden opgepakt.",
}

const COACH := {
	"no_main": "Waar wil je aan werken? Kijk eerst op het missiebord en neem een hoofdmissie aan. Dan praten we verder.",
	"not_main": "Dat is jouw zijmissie; daar ga ik je niet bij helpen. Hoe staat je hoofdmissie ervoor?",
}

const LESSONS := {
	"cause_right": "Je hebt de oorzaak te pakken: de maatregel raakt de kern.",
	"cause_wrong": "De maatregel werkt, maar je A3 noemt een andere oorzaak. Wat zegt dat over je analyse?",
	"mismatch": "De maatregel raakt de oorzaak niet. Kijk opnieuw naar je aanwijzingen.",
	"too_early": "Het idee past, maar de regio is er nog niet klaar voor; het werkt maar half.",
}

const SCORE_NOTES := {
	"coverage": "Je hebt niet alle belangrijke aanwijzingen gevonden.",
	"not_scouted": "Je bent niet stroomop- of stroomafwaarts gaan kijken.",
	"blamed": "Een vraag gaf het team de schuld; dat kostte vertrouwen.",
	"herrings_linked": "Je A3 noemt een aanwijzing die niets met de oorzaak te maken had.",
	"thin_evidence": "De onderbouwing van je oorzaak was dun.",
	"cause_wrong": "De oorzaak op je A3 was niet de echte oorzaak.",
	"waste_wrong": "Je noemde een andere verspilling dan die er speelde.",
	"failed_checks": "Er was meer dan één experiment nodig.",
	"prediction_wrong": "Je voorspelling noemde niet de KPI die dit probleem het meest raakt.",
	"not_standardised": "Niet gestandaardiseerd: de verbetering kan wegzakken.",
	"impact_constraint_small": "Het knelpunt is aangepakt, maar de stroom levert nauwelijks meer.",
	"impact_not_constraint": "Dit was niet het knelpunt: de stroom levert niet meer.",
	"impact_good": "De hele stroom levert meer: het knelpunt is aangepakt.",
}

const EVENTS := {
	"accepted": "Missie aangenomen: %s",
	"completed": "Missie voltooid: %s",
	"failed": "Missie verlopen: %s",
	"reopened": "Een probleem is terug: %s staat weer open",
	"check_ready": "Het experiment heeft zijn twee weken gehad: tijd voor de Check op de obeya-wand.",
	"recurred": "Een oud probleem is terug: de verbetering is weggezakt.",
	"kpi_review": "De KPI-review van de afdelingen staat open.",
}

const NOTHING_NEW := "Je vindt hier niets nieuws met dit instrument."
const SPOTTED := "Je ziet het met eigen ogen: hier loopt iets niet zoals het zou moeten."
const HIDDEN_SIGNAL := "Er schuurt iets, maar wat? Een diepere blik (tijdstudie, data) laat misschien meer zien."


static func tool_name(tool: String) -> String:
	return TOOLS.get(tool, tool)


## "Tijdstudie (2 uur)": the tool with the time it takes.
static func tool_label(tool: String) -> String:
	return "%s (%s)" % [tool_name(tool), duration(Investigation.TOOLS[tool]["minutes"])]


static func question(id: String) -> String:
	return QUESTIONS.get(id, id)


static func waste(id: String) -> String:
	return WASTES.get(id, id)


static func kpi(id: String) -> String:
	return KPIS.get(id, id)


static func belt(id: String) -> String:
	return BELTS.get(id, id)


static func a3_error(code: String) -> String:
	return A3_ERRORS.get(code, code)


static func accept_error(code: String) -> String:
	return ACCEPT_ERRORS.get(code, code)


static func lesson(code: String) -> String:
	return LESSONS.get(code, code)


static func score_note(code: String) -> String:
	return SCORE_NOTES.get(code, code)


## "30 min", "1 uur", "1,5 uur".
static func duration(minutes: int) -> String:
	if minutes < 60:
		return "%d min" % minutes
	var hours := minutes / 60.0
	return ("%d uur" % int(hours)) if is_equal_approx(hours, roundf(hours)) else ("%s uur" % _decimal(hours, 1))


## "€ 50.000": whole euros with Dutch thousands.
static func money(euros: int) -> String:
	var digits := str(absi(euros))
	var out := ""
	while digits.length() > 3:
		out = "." + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return "€ %s%s%s" % ["-" if euros < 0 else "", digits, out]


## A KPI's value with its unit, e.g. "12,3 /week", "42 dagen", "87%".
static func kpi_value(id: String, value: float) -> String:
	match id:
		"throughput", "capacity":
			return "%s /week" % _decimal(value, 1)
		"first_time_right", "on_time":
			return "%d%%" % roundi(value * 100.0)
	return "%d dagen" % roundi(value)


## What a gemba tool showed: the problem spotted, the clues, or a feeling.
static func tool_result(result: Dictionary) -> String:
	var lines: PackedStringArray = []
	if not result.get("spotted", []).is_empty():
		lines.append(SPOTTED)
	for c: Clue in result.get("clues", []):
		lines.append("• " + c.text)
	if lines.is_empty():
		lines.append(HIDDEN_SIGNAL if result.get("hidden_signal", false) else NOTHING_NEW)
	return "\n".join(lines)


## What the team says (Region.ask's result).
static func reply(result: Dictionary) -> String:
	match result.get("reply", ""):
		"clue":
			return "• " + (result["clue"] as Clue).text
		"observation":
			return observation(result["observation"])
	return REPLIES.get(result.get("reply", ""), "")


## What the team truthfully sees in their work right now.
static func observation(o: Dictionary) -> String:
	match o.get("kind", ""):
		"queue":
			return "'Er liggen nu %d dossiers op ons te wachten. Het wordt elke week meer.'" % o["value"]
		"rework":
			return "'Ongeveer %d%% van ons werk komt terug om opnieuw te doen.'" % roundi(o["value"] * 100.0)
	return "'Het loopt hier wel. Er liggen %d dossiers in de bak.'" % o.get("value", 0)


## The coach's reply (Missions.ask_coach): the Kata question or insight
## itself, or why there is nothing to coach.
static func coach_reply(reply_def: Dictionary) -> String:
	var kind: String = reply_def.get("kind", "")
	return reply_def.get("text", "") if kind in ["question", "insight"] else COACH.get(kind, "")


## A session event in a line, or "" when it is not for the player.
static func event(e: Dictionary, mission_names: Dictionary) -> String:
	var type: String = e.get("type", "")
	if type == "belt":
		return "Nieuwe band: %s!" % belt(Progression.BELTS[e["belt"]]["id"])
	if type == "bad_period":
		return "Het budget staat rood: een slechte periode voor de regio." if e.get("started", false) \
			else "Het budget is weer op orde."
	if not EVENTS.has(type):
		return ""
	var text: String = EVENTS[type]
	return text % mission_names.get(e.get("mission", ""), "") if text.contains("%s") else text


static func _decimal(value: float, places: int) -> String:
	return String.num(value, places).replace(".", ",")
