class_name Reactions
extends RefCounted
## The small things people say in passing (Phase 2 design §1.4, §2.4; content/dialogs.yaml
## `greetings:`, `quick:`, `chatter:`): the morning hello by your name, one line about today
## when there is nothing to discuss, and two colleagues talking at the coffee corner. No
## panel, no meter, nothing judged: the world remembers out loud. This class only picks the
## lines; GameSession knows the facts and the hour, the office shows them as subtitles.
##
## greetings: {<person id>: {day: [...], <fact>: [...]}, _all: {<fact>: [...]}}: a person's
##   own line for the fact, else the shared one, else an ordinary morning (`day`).
## quick: {<person id>: {<mood>: [...]}, _all: {<mood>: [...]}}, moods as MOODS.
## chatter: [{id, lines: [first, second], teams: [...] (optional), load: busy|calm (optional),
##   days: [mon..sun] (optional: only on those days, SimCalendar.DAY_NAMES)}].

## What yesterday left, strongest first (GameSession.greeting_fact picks one).
const FACTS: Array[String] = ["ruined", "pressured", "committed", "heard", "standardised"]
const ORDINARY := "day"
## A quick line's mood: tired (low morale), busy or calm (their team's queue), else the hour.
const MOODS: Array[String] = ["tired", "busy", "calm", "morning", "afternoon", "late"]
const SHARED := "_all"
const LOADS: Array[String] = ["busy", "calm"]

var greetings: Dictionary = {}
var quick: Dictionary = {}
var chatter: Array = []


func _init(doc: Dictionary = {}) -> void:
	greetings = JsonFile.dict_or_empty(doc.get("greetings"))
	quick = JsonFile.dict_or_empty(doc.get("quick"))
	var pairs: Variant = doc.get("chatter", [])
	chatter = pairs if pairs is Array else []


## The greeting of `person_id` after `fact` ("" or one of FACTS): their own line for it, the
## shared one, else an ordinary morning; variant `n` (wraps). "" when they have no greeting.
func greeting(person_id: String, fact: String, n: int) -> String:
	var own := JsonFile.dict_or_empty(greetings.get(person_id))
	if not fact.is_empty():
		var line := _pick(own.get(fact), n)
		if line.is_empty():
			line = _pick(JsonFile.dict_or_empty(greetings.get(SHARED)).get(fact), n)
		if not line.is_empty():
			return line
	return _pick(own.get(ORDINARY), n)


## A quick line of `person_id` in `mood` (one of MOODS): their own, else the shared one.
func quick_line(person_id: String, mood: String, n: int) -> String:
	var line := _pick(JsonFile.dict_or_empty(quick.get(person_id)).get(mood), n)
	return line if not line.is_empty() else _pick(JsonFile.dict_or_empty(quick.get(SHARED)).get(mood), n)


## A two-line exchange for two colleagues of `teams` (theirs, "" when unknown) at `load`
## (busy | calm | "") on `weekday` (0 Monday; -1 any day), variant `n` among those that fit:
## [first, second], or [] when none fits. A snippet with teams fits when one of the two is in
## one of them; with a load, at that load; with days, on one of them.
func chatter_for(teams: Array, load: String, n: int, weekday := -1) -> Array[String]:
	var fits: Array = chatter.filter(func(c: Variant) -> bool:
		if not c is Dictionary or not (c.get("lines") is Array and c["lines"].size() == 2):
			return false
		var want: Array = c.get("teams", []) if c.get("teams") is Array else []
		var at := str(c.get("load", ""))
		var days: Array = c.get("days", []) if c.get("days") is Array else []
		return (want.is_empty() or teams.any(func(t: Variant) -> bool: return t in want)) \
			and (at.is_empty() or at == load) \
			and (days.is_empty() or weekday < 0 or SimCalendar.DAY_NAMES[weekday] in days))
	var out: Array[String] = []
	if fits.is_empty():
		return out
	for line: Variant in fits[posmod(n, fits.size())]["lines"]:
		out.append(str(line))
	return out


static func _pick(lines: Variant, n: int) -> String:
	if not lines is Array or (lines as Array).is_empty():
		return ""
	return str(lines[posmod(n, lines.size())])
