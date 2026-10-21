class_name OfficeDay
extends RefCounted
## One person's working day in the office (PLAN 2.14 S1-A; design 2026-10-21 §1.1), from
## their cast.json `day:` {arrive, coffee, lunch, leave[, late_until]} as "HH:MM": in, a
## coffee at the coffee corner, lunch, home, or home late. A field that is missing or bad
## falls back to the person's default (with a warning for a bad one); a day out of order
## falls back whole. Defaults vary by person, so the office never moves in lockstep.
## Who stays late follows the simulation, in one rule (stays_late).

const KEYS: Array[String] = ["arrive", "coffee", "lunch", "leave", "late_until"]
## Where someone is: not in the building, at their desk, at the coffee corner, at lunch.
const OUT := "out"
const DESK := "desk"
const COFFEE := "coffee"
const LUNCH := "lunch"
## A coffee break (min): an estimate, a short break by the machine.
const COFFEE_MINUTES := 10
## Lunch (min): the Arbeidstijdenwet's break after 5.5 hours' work (art. 5:4) is 30 min,
## the common office lunch; the starts spread over 12:00–12:30, so the kantine is busy
## from twelve to one.
const LUNCH_MINUTES := 30
## When someone who stays late goes home (design §1.1).
const LATE_UNTIL := 18 * 60 + 30
## A change of place this recent (game minutes) is walked; an older one has happened
## while the clock jumped (a talk, a skip): they are simply there. An estimate: a walk
## across a floor and down the stairs takes a few minutes, with slack for a chat.
const WALK_WINDOW := 20
## The default day's spreads (min) from 08:00, 09:50, 12:00 and 17:00 (design §1.1: in
## 08:00–08:45, coffee about ten, lunch 12:00–13:00, out 17:00–17:30).
const SPREAD := {"arrive": [8 * 60, 45], "coffee": [9 * 60 + 50, 25], "lunch": [12 * 60, 30], "leave": [17 * 60, 30]}
## Staying late (estimates). A team planned above 85 % of its hours: queueing theory
## (Kingman) has waits climbing steeply past about 80–85 % utilisation, and such a team
## catches up after hours. Morale under 0.35 (People's 0–100 as 0–1; FRIENDLY_MORALE is
## 55, someone leaves under 20): a worn-down person stays to keep up.
const LOAD_NORM := 0.85
const LOW_MORALE := 0.35

var arrive := 0
var coffee := 0
var lunch := 0
var leave := 0
## Home at this minute instead of `leave` (authored); -1: by the simulation's rule.
var late_until := -1


## The day of a cast entry ({id, day: {...}}), validated (data-validation: unknown keys
## and bad times fall back, each named in `problems` for the caller to warn about; never
## a crash).
static func from_entry(entry: Dictionary, problems: Array[String] = []) -> OfficeDay:
	var id := str(entry.get("id", ""))
	var day := defaults(id)
	var raw: Variant = entry.get("day", {})
	if not raw is Dictionary:
		problems.append("cast %s: day is not a table, the defaults instead" % id)
		return day
	var given := day.duplicate_day()
	for key: Variant in raw:
		if not key in KEYS:
			problems.append("cast %s: day has an unknown key '%s'" % [id, key])
			continue
		var minute := parse_time(raw[key])
		if minute < 0:
			problems.append("cast %s: day.%s '%s' is not a time (HH:MM), the default instead" % [id, key, raw[key]])
			continue
		given.set(key, minute)
	if not given._in_order():
		problems.append("cast %s: day out of order (in, coffee, lunch, out, late), the defaults instead" % id)
		return day
	return given


## The default day of `id`: a spread per person (by a hash of the id), never lockstep.
static func defaults(id: String) -> OfficeDay:
	var day := OfficeDay.new()
	for key: String in SPREAD:
		day.set(key, SPREAD[key][0] + absi((id + key).hash()) % (SPREAD[key][1] + 1))
	return day


func duplicate_day() -> OfficeDay:
	var d := OfficeDay.new()
	for key in KEYS:
		d.set(key, get(key))
	return d


func _in_order() -> bool:
	return arrive < coffee and coffee + COFFEE_MINUTES <= lunch and lunch + LUNCH_MINUTES <= leave \
		and (late_until < 0 or late_until >= leave)


## "HH:MM" as minutes since midnight; -1 for anything else.
static func parse_time(text: Variant) -> int:
	if not text is String or (text as String).length() != 5 or (text as String)[2] != ":":
		return -1
	var hh := (text as String).substr(0, 2)
	var mm := (text as String).substr(3, 2)
	if not hh.is_valid_int() or not mm.is_valid_int():
		return -1
	var h := hh.to_int()
	var m := mm.to_int()
	return h * 60 + m if h >= 0 and h < 24 and m >= 0 and m < 60 else -1


## When they go home: late_until when they stay late (authored, else LATE_UNTIL), else leave.
func home_at(late: bool) -> int:
	if late_until >= 0:
		return late_until
	return LATE_UNTIL if late else leave


## Where they are at `minute` and since when: {place (OUT, DESK, COFFEE, LUNCH), since
## (the minute that place began; before midnight as a negative minute)}.
func place_at(minute: int, late: bool) -> Dictionary:
	var home := home_at(late)
	if minute < arrive:
		return {"place": OUT, "since": home - SimCalendar.MINUTES_PER_DAY}
	if minute >= home:
		return {"place": OUT, "since": home}
	if minute >= coffee and minute < coffee + COFFEE_MINUTES:
		return {"place": COFFEE, "since": coffee}
	if minute >= lunch and minute < lunch + LUNCH_MINUTES:
		return {"place": LUNCH, "since": lunch}
	var since := arrive
	for back: int in [coffee + COFFEE_MINUTES, lunch + LUNCH_MINUTES]:
		if minute >= back:
			since = back
	return {"place": DESK, "since": since}


## The one rule of who stays late (design §1.1, estimates above): their team's planned
## load above the norm, or their morale low.
static func stays_late(morale: float, utilisation: float) -> bool:
	return utilisation > LOAD_NORM or morale < LOW_MORALE


## Who of `ids` stays late today, by the session: {person id: true}. Morale from
## energy_of; the team's load from the region's capacity (its pools' utilisation) when
## the session has a region and knows the person; without either, their day as authored.
static func late_ids(session: Object, ids: Array) -> Dictionary:
	var out := {}
	if session == null or not session.has_method("energy_of"):
		return out
	var region: Variant = session.get("region")
	var people: Variant = session.get("people")
	var pools: Dictionary = Capacity.analyse((region as Region).net)["pools"] if region is Region else {}
	for id: Variant in ids:
		var energy: Variant = session.call("energy_of", str(id))
		var morale := float((energy as Dictionary).get("energy", 1.0)) if energy is Dictionary else 1.0
		var load := 0.0
		if not pools.is_empty() and people is People and (people as People).persons.has(id):
			var team := (region as Region).team_at((people as People).persons[id].place)
			load = float(pools.get(team, {}).get("utilisation", 0.0))
		if stays_late(morale, load if is_finite(load) else 0.0):
			out[str(id)] = true
	return out
