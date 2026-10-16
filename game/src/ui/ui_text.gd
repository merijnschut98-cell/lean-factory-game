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
	"same_countermeasure": "Deze maatregel heb je hier al geprobeerd. Kies voor het herstel een andere.",
}

## Refusals at a team's place (GameSession.use_tool and ask).
const PLACE_ERRORS := {
	"unknown_tool": "Dat instrument ken je niet.",
	"use_ask": "Een gesprek voer je door een vraag te stellen.",
	"unknown_place": "Hier werkt geen team.",
	"unknown_question": "Die vraag kun je hier niet stellen.",
	"no_team": "Hier werkt geen team om een routine mee te houden.",
	"planned": "Hier loopt al een vaste routine.",
	"not_planned": "Hier loopt geen vaste routine.",
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
	"not_moved": "De maatregel doet iets, maar het getal dat je voorspelde beweegt nauwelijks. Klopt je voorspelling, of zit het effect op een ander getal?",
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
	"impact_lead_time_small": "Hier wacht het werk zonder team: de verbetering haalt maar weinig doorlooptijd uit de stroom.",
}

const EVENTS := {
	"accepted": "Missie aangenomen: %s",
	"completed": "Missie voltooid: %s",
	"failed": "Missie verlopen: %s",
	"reopened": "Een probleem is terug: %s staat weer open",
	"check_ready": "Het experiment heeft zijn tijd gehad: tijd voor de Check op de obeya-wand.",
	"recurred": "Een oud probleem is terug: de verbetering is weggezakt.",
	"kpi_review": "De KPI-review van de afdelingen staat open.",
	"slipping": "Een verbetering zakt weg: %s (J)",
	"checkin": "Op het missiebord: %s",
	"repair": "Herstel op het missiebord: %s",
}

## Why the MT's view of the CI lead changed (Reputation's reasons).
const REPUTATION_REASONS := {
	"mission": "missie voltooid",
	"flow": "de hele stroom levert meer",
	"held": "een verbetering houdt een half jaar stand",
	"reopened": "je pakte een teruggekeerd probleem op",
	"discovery": "een ontdekking",
	"blame": "een vraag gaf het team de schuld",
	"deadline": "een deadline gemist",
	"bad_period": "het budget staat rood",
}
const DIVIDEND := "Een verbetering houdt stand na %d dagen: %s. De besparing levert %s op voor het verbeterbudget."
const OVERLOAD := "%s draait op %d%% bezetting door je experiment bij %s, al twee weken te vol. Het team vertrouwt je wat minder."
const REPUTATION := "Reputatie bij het MT %s (%s)"
## The six acts of the campaign (PLAN §2.3), by the act number in the content.
const ACT_TITLES := {
	0: "Inwerkweek", 1: "Akte I · De eerste honderd dagen", 2: "Akte II · Wat onder de grond zit",
	3: "Akte III · Zichtbaar maken", 4: "Akte IV · Flow door de regio", 5: "Akte V · Het systeem",
	6: "Akte VI · Het digitale net",
}

## The Check's waiting time in words (GameSession.check_days).
const PERIODS := {1: "een dag", 2: "twee dagen", 3: "drie dagen", 7: "een week", 14: "twee weken"}
const TRAINING_TITLE := "Inwerkweek — %s: %s"
const SKIP_CONFIRM := "Je mist de oefenweek, het echte werk begint direct."
const CARD_FOOTER := "K voor alle begrippen"

## Leader routines at a team's place (GameSession.audit, plan_routine,
## stop_routine): the buttons with their cost, and what happened.
const AUDIT_BUTTON := "Audit van de standaard (%s)"
const PLAN_BUTTON := "Vaste routine plannen (%s per week van het team)"
const STOP_BUTTON := "Routine stoppen (het team krijgt %s per week terug)"
const AUDIT_HEADING := "Audit van de standaard"
const ROUTINE_HEADING := "Vaste routine"
const AUDITED := "Je loopt met het team de standaard na. Wat wegzakte, wordt weer gedaan zoals afgesproken: %s."
const NO_STANDARD := "Voor %s is nooit een standaard vastgelegd: er is niets om tegen te auditen."
const NOTHING_TO_AUDIT := "Hier is geen verbetering om na te lopen."
const ROUTINE_PLANNED := "Vanaf nu loopt de teamleider elke week de standaard na met het team. Dat kost het team %s per week."
const ROUTINE_STOPPED := "De routine is gestopt: het team heeft de %s per week weer voor ander werk."

const NOTHING_NEW := "Je vindt hier niets nieuws met dit instrument."
const SPOTTED := "Je ziet het met eigen ogen: hier loopt iets niet zoals het zou moeten."
const HIDDEN_SIGNAL := "Er schuurt iets, maar wat? Een diepere blik (tijdstudie, data) laat misschien meer zien."


static func tool_name(tool: String) -> String:
	return TOOLS.get(tool, tool)


## "Tijdstudie (2 uur)": the tool with the time it takes.
static func tool_label(tool: String) -> String:
	if not Investigation.TOOLS.has(tool):
		return tool_name(tool)
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


static func place_error(code: String) -> String:
	return PLACE_ERRORS.get(code, code)


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


## Every problem's name by id (for events and audits that name problems).
static func problem_names(s: GameSession) -> Dictionary:
	var names := {}
	for p in s.region.problem_list():
		names[p.id] = p.name
	return names


## Every team's name by pool id (for events that name a team).
static func team_names(s: GameSession) -> Dictionary:
	var names := {}
	for id: String in s.region.net.pools:
		names[id] = s.region.net.pools[id].name
	return names


## A mission's name as the player sees it: a training day with its weekday
## ("Inwerkweek — ma: Rondleiding", see GameSession.training_weekday).
static func mission_title(m: MissionDef, s: GameSession) -> String:
	var weekday := s.training_weekday(m.id)
	return TRAINING_TITLE % [weekday, m.name] if not weekday.is_empty() else m.name


## "twee weken", "drie dagen".
static func period(days: int) -> String:
	return PERIODS.get(days, "%d dagen" % days)


## A counted queue (Region.queue_at): "8 dossiers (0,4 dagen werk)".
static func queue(q: Dictionary) -> String:
	return "%d %s (%s dagen werk)" % [q["count"], "dossier" if q["count"] == 1 else "dossiers", _decimal(q["days"], 1)]


## The bottleneck lesson from the queues the player counted ({place:
## queue}, place names by place): what was measured, and where the work
## waits longest by the numbers.
static func queue_lesson(queues: Dictionary, place_names: Dictionary) -> String:
	var parts: PackedStringArray = []
	var longest := ""
	for place: String in queues:
		parts.append("%s %s" % [place_names.get(place, place), queue(queues[place])])
		if queues[place]["days"] > 0.0 and (longest.is_empty() or queues[place]["days"] > queues[longest]["days"]):
			longest = place
	var verdict := "Volgens je telling wacht het werk nergens: de wachtrijen zijn leeg." if longest.is_empty() \
		else "Volgens je telling wacht het werk het langst bij %s." % place_names.get(longest, longest)
	return "Je telde: %s. %s" % [", ".join(parts), verdict]


## What a gemba tool showed: the problem spotted, the clues, a counted
## queue, or a feeling.
static func tool_result(result: Dictionary) -> String:
	var lines: PackedStringArray = []
	if not result.get("spotted", []).is_empty():
		lines.append(SPOTTED)
	if result.has("queue"):
		lines.append("Je telt de wachtrij: %s." % queue(result["queue"]))
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


## A session event in a line, or "" when it is not for the player. Its
## name comes from `mission_names` (a mission's event) or `problem_names`.
static func event(e: Dictionary, mission_names: Dictionary, problem_names: Dictionary = {},
		team_names: Dictionary = {}) -> String:
	var type: String = e.get("type", "")
	var problem: String = problem_names.get(e.get("problem", ""), "")
	match type:
		"dividend":
			return DIVIDEND % [e["days"], problem, money(e["budget"])]
		"overload":
			return OVERLOAD % [team_names.get(e["team"], e["team"]), roundi(e["load"] * 100.0), problem]
		"reputation":
			return REPUTATION % [signed(e["change"]), REPUTATION_REASONS.get(e["reason"], e["reason"])]
	if type == "belt":
		return "Nieuwe band: %s!" % belt(Progression.BELTS[e["belt"]]["id"])
	if type == "bad_period":
		return "Het budget staat rood: een slechte periode voor de regio." if e.get("started", false) \
			else "Het budget is weer op orde."
	if not EVENTS.has(type):
		return ""
	var text: String = EVENTS[type]
	if not text.contains("%s"):
		return text
	return text % (mission_names.get(e["mission"], "") if e.has("mission") else problem)


## "+3" or "−1" (a true minus sign).
static func signed(n: int) -> String:
	return ("+%d" if n >= 0 else "−%d") % absi(n)


## The HUD's budget: the weekly savings of held fixes, and in debt the floor
## the directie carries (Region.DEBT_FLOOR), so a setback reads as one.
static func budget_line(budget: int, savings_per_week: float) -> String:
	var out := "Budget " + money(budget)
	if roundi(savings_per_week) > 0:
		out += "  ·  besparing %s /week" % money(roundi(savings_per_week))
	if budget < 0:
		out += "  ·  ondergrens %s" % money(Region.DEBT_FLOOR)
	return out


## "Akte I · De eerste honderd dagen"; "" for a mission outside the acts.
static func act_title(act: int) -> String:
	return ACT_TITLES.get(act, "")


## The weekly team time a routine costs, e.g. "2 uur".
static func routine_hours() -> String:
	return duration(roundi(Sustain.ROUTINE_HOURS_PER_WEEK * 60.0))


## What an audit found (GameSession.audit's {refreshed, no_standard}, problem
## names by id).
static func audit_result(result: Dictionary, problem_names: Dictionary) -> String:
	var lines: PackedStringArray = []
	for key: String in ["refreshed", "no_standard"]:
		if not result[key].is_empty():
			var names := ", ".join(result[key].map(func(id: String) -> String: return problem_names.get(id, id)))
			lines.append((AUDITED if key == "refreshed" else NO_STANDARD) % names)
	return "\n".join(lines) if not lines.is_empty() else NOTHING_TO_AUDIT


## A resolved fix as measured (GameSession.sustain_of): how much of it still
## works, whether it was standardised, and how long nobody checked it. The
## measure only: nothing says what would hold it.
static func fix_health(sustain: Dictionary) -> String:
	var days := roundi(sustain["neglect_days"])
	return "Werkt voor %d%%  ·  %s  ·  %s" % [roundi(sustain["health"] * 100.0),
		"gestandaardiseerd" if sustain["standardised"] else "geen standaard",
		"wekelijkse routine" if sustain["routine"] else "%d %s niet nagelopen" % [days, "dag" if days == 1 else "dagen"]]


## Stagnation drift (GameSession.drift) in a line; "" before the campaign.
static func drift_line(drift: Dictionary) -> String:
	if not drift["started"]:
		return ""
	return "Laatste afgeronde verbetering: %d dagen geleden  ·  achteruitgang door stilstand: %d%%" % [
		roundi(drift["stagnant_days"]), roundi(drift["level"] * 100.0)]


static func _decimal(value: float, places: int) -> String:
	return String.num(value, places).replace(".", ",")
