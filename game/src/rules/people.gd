class_name People
extends RefCounted
## The people the player talks with, across talks (spec §3.6, §4, §5.2,
## §5.4): trust in the player and morale per person, what each remembers of
## the last talk (and when they will talk again), the layers already
## revealed, the best agreement per dialog and the facts talks set.
##
## People knows nothing of the Region or the Missions: GameSession passes in
## what it needs to know about the world (a `world` Dictionary: main and
## active mission ids, found clue ids, facts, team trust, whether the team was
## blamed, the time now) and applies to the Region what a talk changes there.

## Openness at the start by archetype (ESTIMATES, spec §3.6).
const START_BASE := {"defender": 40, "cynic": 30, "craftsman": 40, "overloaded": 35, "rule_bound": 35, "quiet": 47,
	"customer_upset": 25, "expert": 60}
const MOOD_START := {"goed": 10, "neutraal": 0, "gespannen": -5, "stil": -5, "moe": -10}
const TEAM_TRUST_WEIGHT := 10
const START_MIN := 5
const START_MAX := 80
## The last talk with this person: the most negative and the most positive
## memory count (ESTIMATES).
const MEMORY_NEGATIVE := {"confronted": -15, "ruined": -10, "pressured": -10}
const MEMORY_POSITIVE := {"committed": 15, "heard": 10}
## A talk that went wrong this way offers the repair move next time.
const REPAIRABLE := ["ruined", "pressured", "confronted"]
## What an outcome does to trust, morale and reputation (ESTIMATES, §4.1, §5.4).
const TRUST := {"commitment": 10, "partial": 5, "heard": 3, "lifted": 5, "compliance": -5, "ruined": -5}
const MORALE := {"commitment": 10, "compliance": -10, "lifted": 15}
## A blame of their team.
const MORALE_CONFRONTED := -10
const REPUTATION := {"commitment": 1, "ruined": -1}
## The best agreement so far wins (a later commitment repairs a compliance).
const RANK := {"commitment": 5, "partial": 4, "compliance": 3, "blocked": 2, "heard": 1, "lifted": 1}
## The fact an outcome sets for `needs` expressions (fact:<dialog id>).
const FACT_OF := {"commitment": "committed", "partial": "partial", "compliance": "complied", "blocked": "blocked"}
## The kinds of fact talks set (Facts.KINDS has them too).
const FACT_KINDS := ["heard", "committed", "partial", "complied", "blocked"]
## Buy-in of the fix the person owns, by their best agreement (§4.2); no
## agreement at all is compliance: the change was imposed (§14 Q3).
const BUY_IN_OF := {"commitment": "commitment", "partial": "none", "compliance": "compliance"}
## After a ruined talk the person talks again on the next working day at 08:30.
const RETRY_MINUTE := 8 * 60 + 30
## A check-in that lifted someone rests this long (§5.7).
const CHECKIN_REST_DAYS := 14
## A check-in prompt nobody answers expires after this many days (§5.7).
const PROMPT_DAYS := 3
## People leave rarely (Merijn, 2026-10-15): morale below LEAVE_MORALE for
## LEAVE_DAYS, and LEAVE_IGNORED check-in prompts left unanswered. It closes
## a door (their talks, their ownership of a fix), never the game.
const LEAVE_MORALE := 20
const LEAVE_DAYS := 60
const LEAVE_IGNORED := 2
## Main-mission talks that end this way bring the coach's question about the
## talk on the next ask (spec §5.6); a talk that only listened does not.
const COACHED := ["ruined", "blocked", "compliance", "partial", "commitment"]

var persons: Dictionary[String, PersonDef] = {}
var dialogs: Dictionary[String, DialogDef] = {}
var bank: Dictionary
var trust: Dictionary[String, int] = {}
var morale: Dictionary[String, int] = {}
## person id → {flags: [ruined | pressured | confronted | heard | committed], cooldown_until}
var memory: Dictionary[String, Dictionary] = {}
## "dialog id/version" → {layer id: true}
var revealed: Dictionary[String, Dictionary] = {}
## dialog id → its best outcome so far, and what was on the table then.
var outcomes: Dictionary[String, String] = {}
var agreed: Dictionary[String, String] = {}
## dialog id → how often it was had.
var talks: Dictionary[String, int] = {}
## check-in id → when it can come again (minutes).
var rest_until: Dictionary[String, int] = {}
## heard:<id> facts learned concerns set.
var heard_facts: Dictionary[String, bool] = {}
## check-in id → when its prompt opened (minutes); person id → since when
## morale is below LEAVE_MORALE, and how many prompts expired unanswered.
var prompts: Dictionary[String, int] = {}
var low_since: Dictionary[String, int] = {}
var ignored: Dictionary[String, int] = {}
## Person ids of colleagues who left (to another grid operator).
var left: Dictionary[String, bool] = {}
## The main-mission talk the coach asks about next: {mission, person (short
## name), outcome}; {} for none. How many such questions he asked.
var coach_after: Dictionary = {}
var coach_asks := 0


func _init(person_defs: Array[PersonDef], dialog_defs: Array[DialogDef], lines: Dictionary) -> void:
	bank = lines
	for p in person_defs:
		persons[p.id] = p
	for d in dialog_defs:
		dialogs[d.id] = d
	_reset()


func _reset() -> void:
	for state: Dictionary in [trust, morale, memory, revealed, outcomes, agreed, talks, rest_until, heard_facts, prompts,
			low_since, ignored, left, coach_after]:
		state.clear()
	coach_asks = 0
	for p: PersonDef in persons.values():
		trust[p.id] = p.trust
		morale[p.id] = p.morale


# ── Who has something to say ────────────────────────────────────────────────

## The talk a person has for the player now: a persuasion of the main mission,
## then of another active mission, then a check-in; null when there is none.
func dialog_for(person_id: String, world: Dictionary) -> DialogDef:
	var best: DialogDef = null
	var best_rank := -1
	var known := facts(world.get("facts", {}))
	for d: DialogDef in dialogs.values():
		var rank := _rank(d, world, known) if d.person == person_id and not left.has(person_id) else -1
		if rank > best_rank:
			best = d
			best_rank = rank
	return best


## 2 for the main mission's talk, 1 for another active mission's, 0 for a
## check-in; -1 when it cannot be had now. `known`: every fact (facts()).
func _rank(d: DialogDef, world: Dictionary, known: Dictionary) -> int:
	if d.kind == "checkin":
		var below := int(d.trigger.get("morale_below", 101))
		var ready: bool = morale.get(d.person, 0) < below and int(rest_until.get(d.id, 0)) <= int(world.get("now", 0))
		return 0 if ready and DialogDef.needs_met(JsonFile.dict_or_empty(d.trigger.get("needs")), known) else -1
	if not (d.requires_clue.is_empty() or world.get("found", {}).has(d.requires_clue)) \
			or not DialogDef.needs_met(d.needs, known) or effective_outcome(d.id, known) == "commitment":
		return -1
	if d.mission in world.get("main", []):
		return 2
	return 1 if d.mission in world.get("active", []) else -1


## After a ruined talk, until the next working day at 08:30.
func cooling_down(person_id: String, now: int) -> bool:
	return int(memory.get(person_id, {}).get("cooldown_until", 0)) > now


func opening(d: DialogDef) -> String:
	return d.retry_opening if talks.get(d.id, 0) > 0 and not d.retry_opening.is_empty() else d.opening


# ── A talk ──────────────────────────────────────────────────────────────────

## Start a talk: openness = base (archetype) + mood + 10 × team trust +
## (trust − 50) / 5 + (morale − 50) / 10 + memory, clamped (spec §3.6).
func start(d: DialogDef, world: Dictionary) -> Dialog:
	var known := facts(world.get("facts", {}))
	var who := persons[d.person]
	var v := d.version(known)
	var mood := _mood(d, v, bool(world.get("blamed", false)))
	var flags: Array = memory.get(who.id, {}).get("flags", [])
	var start: float = START_BASE.get(who.archetype, 40) + MOOD_START.get(mood, 0) \
		+ TEAM_TRUST_WEIGHT * int(world.get("team_trust", 0)) + (trust[who.id] - 50) / 5.0 \
		+ (morale[who.id] - 50) / 10.0 + _memory_term(flags)
	return Dialog.new(d, who, bank, {
		"openness": clampi(roundi(start), START_MIN, START_MAX), "trust": trust[who.id], "mood": mood,
		"found": world.get("found", {}), "facts": known, "version": v, "revealed": revealed.get(_key(d.id, v), {}),
		"retry": flags.any(func(f: String) -> bool: return f in REPAIRABLE),
	})


## The variant's mood, the scene's on the first talk, tense after a blame of
## their team, or an ordinary day. (Overload and life beats: spec §3.6, D3.)
func _mood(d: DialogDef, v: int, blamed: bool) -> String:
	if v >= 0 and not d.mood_of(v).is_empty():
		return d.mood_of(v)
	if not d.mood.is_empty() and talks.get(d.id, 0) == 0:
		return d.mood
	return "gespannen" if blamed else "neutraal"


func _memory_term(flags: Array) -> int:
	var worst := 0
	var best := 0
	for f: String in flags:
		worst = mini(worst, MEMORY_NEGATIVE.get(f, 0))
		best = maxi(best, MEMORY_POSITIVE.get(f, 0))
	return worst + best


## Apply an ended talk (trust, morale, reputation, memory, revealed layers,
## the best agreement, facts, cooldowns). Returns what GameSession applies to
## the world and the UI shows: {dialog, person, outcome, trust, morale,
## reputation (this talk's change), team_trust (+1 for a commitment),
## confronted, clue ("" or the clue the concern unlocked), facts (heard:),
## cooldown_until (0 for none), hints (a block's route hints), wait_for (what an
## agreement under condition still waits for, or "")}. `main`: the
## talk belongs to the main mission, so the coach asks about it next.
func finish(d: Dialog, now: int, main: bool = false) -> Dictionary:
	var who := d.who
	var o := d.outcome
	trust[who.id] = clampi(d.trust + TRUST.get(o, 0), 0, 100)
	morale[who.id] = clampi(morale[who.id] + MORALE.get(o, 0) + (MORALE_CONFRONTED if d.confronted else 0), 0, 100)
	var flags := []
	for flag: String in ["ruined", "pressured", "confronted", "heard", "committed"]:
		if _remembers(flag, d):
			flags.append(flag)
	var cooldown := _next_working_morning(now) if o == "ruined" else 0
	memory[who.id] = {"flags": flags, "cooldown_until": cooldown}
	revealed[_key(d.def.id, d.version)] = d.revealed.duplicate()
	talks[d.def.id] = talks.get(d.def.id, 0) + 1
	if RANK.get(o, 0) > RANK.get(outcomes.get(d.def.id, ""), 0):
		outcomes[d.def.id] = o
		agreed[d.def.id] = d.table
	var facts := d.unlocked_facts()
	for f: String in facts:
		heard_facts[f] = true
	if o == "lifted":
		rest_until[d.def.id] = now + SimCalendar.days(CHECKIN_REST_DAYS)
	prompts.erase(d.def.id)
	if main and d.def.kind == "persuade" and o in COACHED:
		coach_after = {"mission": d.def.mission, "person": who.short, "outcome": o}
	return {
		"dialog": d.def.id, "person": who.id, "outcome": o, "trust": trust[who.id], "morale": morale[who.id],
		"reputation": REPUTATION.get(o, 0), "team_trust": 1 if o == "commitment" else 0, "confronted": d.confronted,
		"clue": d.unlocked_clue(), "facts": facts, "cooldown_until": cooldown, "wait_for": d.wait_for(),
		"hints": d.def.block.get("routes", []).map(func(r: Dictionary) -> String: return str(r.get("hint", ""))) \
			if o == "blocked" else [],
	}


func _remembers(flag: String, d: Dialog) -> bool:
	match flag:
		"ruined":
			return d.outcome == "ruined"
		"pressured":
			return d.pressured
		"confronted":
			return d.confronted
		"heard":
			return d.heard or d.outcome in ["heard", "partial", "lifted"]
	return d.outcome == "commitment"


# ── The coach after a hard talk ─────────────────────────────────────────────

## The coach's one question about the last hard main-mission talk (Kata; he
## never names the right move): {kind: question, stage: talk, text}, then
## back to the mission's stage ({} when there is no such talk, or it was for
## another mission than `main_id`, the main mission now). A line for
## what happened (pressure, a ruin, a block, a commitment) comes first, else
## the bank's questions in turn. A yes under pressure is the bank's
## `after.pressure`.
func coach_question(main_id: String) -> Dictionary:
	if coach_after.get("mission") != main_id:
		coach_after = {}
		return {}
	var lines := JsonFile.dict_or_empty(bank.get("coach"))
	var after := JsonFile.dict_or_empty(lines.get("after"))
	var questions: Array = lines.get("questions", []) if lines.get("questions") is Array else []
	var o := str(coach_after.get("outcome", ""))
	var text := str(after.get("pressure" if o == "compliance" else o, ""))
	if text.is_empty() and not questions.is_empty():
		text = str(questions[coach_asks % questions.size()])
		coach_asks += 1
	var who := str(coach_after.get("person", ""))
	coach_after = {}
	return {"kind": "question", "stage": "talk", "text": text.replace("{person}", who)} if not text.is_empty() else {}


# ── Each day: check-in prompts, and the rare goodbye ─────────────────────────

## Once a day (world as for dialog_for): a check-in that can be had opens a
## prompt; one left unanswered PROMPT_DAYS expires (ignored); the low-morale
## clock runs. Returns [{type: left, person}] for whoever leaves today.
func daily(world: Dictionary) -> Array[Dictionary]:
	var now := int(world.get("now", 0))
	var known := facts(world.get("facts", {}))
	var events: Array[Dictionary] = []
	for d: DialogDef in dialogs.values():
		if d.kind != "checkin" or left.has(d.person):
			continue
		if prompts.has(d.id) and now - prompts[d.id] >= SimCalendar.days(PROMPT_DAYS):
			prompts.erase(d.id)
			ignored[d.person] = ignored.get(d.person, 0) + 1
		elif not prompts.has(d.id) and _rank(d, world, known) == 0:
			prompts[d.id] = now
	for id: String in persons:
		if left.has(id):
			continue
		if morale[id] >= LEAVE_MORALE:
			low_since.erase(id)
			continue
		low_since[id] = low_since.get(id, now)
		if now - low_since[id] >= SimCalendar.days(LEAVE_DAYS) and ignored.get(id, 0) >= LEAVE_IGNORED:
			left[id] = true
			events.append({"type": "left", "person": id})
	return events


func has_left(person_id: String) -> bool:
	return left.has(person_id)


## A check-in prompt is open for the person (the "…" over their head).
func needs_talk(person_id: String) -> bool:
	return dialogs.values().any(func(d: DialogDef) -> bool: return d.person == person_id and prompts.has(d.id))


static func _next_working_morning(now: int) -> int:
	var day := SimCalendar.day_of(now) + 1
	while SimCalendar.weekday(SimCalendar.days(day)) >= 5:
		day += 1
	return SimCalendar.days(day) + RETRY_MINUTE


static func _key(dialog_id: String, v: int) -> String:
	return "%s/%d" % [dialog_id, v]


# ── Facts, agreements and buy-in ────────────────────────────────────────────

## Every atom the dialogs' needs name, with the generic conditions'
## checked:<problem>: what GameSession asks the world about.
func atoms() -> Array[String]:
	var out: Array[String] = []
	for d: DialogDef in dialogs.values():
		var exprs: Array = [d.needs, d.condition_needs, JsonFile.dict_or_empty(d.trigger.get("needs"))]
		exprs.append_array(d.block.get("routes", []).map(func(r: Dictionary) -> Variant: return r.get("needs", {})))
		exprs.append_array(d.variants.map(func(v: Dictionary) -> Variant: return v.get("needs", {})))
		if d.condition_needs.is_empty() and not d.owns.is_empty():
			exprs.append({"all": ["checked:" + d.owns]})
		for expr: Variant in exprs:
			for atoms_of: Variant in JsonFile.dict_or_empty(expr).values():
				for atom: Variant in atoms_of if atoms_of is Array else []:
					if not str(atom) in out:
						out.append(str(atom))
	return out


## The facts talks set (heard:, committed:, partial:, complied:, blocked:),
## merged into `external` (the world's facts). An agreement under condition
## counts as committed once its condition holds: the dialog's
## condition_needs, or a passed Check of the problem the person owns ("first
## see, then believe").
func facts(external: Dictionary = {}) -> Dictionary:
	var out := external.duplicate()
	out.merge(heard_facts)
	for id: String in outcomes:
		if FACT_OF.has(outcomes[id]):
			out["%s:%s" % [FACT_OF[outcomes[id]], id]] = true
	var changed := true
	while changed:
		changed = false
		for id: String in outcomes:
			if outcomes[id] == "partial" and not out.has("committed:" + id) and _condition_met(dialogs[id], out):
				out["committed:" + id] = true
				changed = true
	return out


func _condition_met(d: DialogDef, facts_now: Dictionary) -> bool:
	var expr := d.condition_needs if not d.condition_needs.is_empty() else \
		({"all": ["checked:" + d.owns]} if not d.owns.is_empty() else {})
	return not expr.is_empty() and DialogDef.needs_met(expr, facts_now)


## The best agreement with a dialog so far, with a met condition counted as
## commitment; "" when it was never had.
func effective_outcome(dialog_id: String, facts_now: Dictionary) -> String:
	var o: String = outcomes.get(dialog_id, "")
	return "commitment" if o == "partial" and facts_now.has("committed:" + dialog_id) else o


## How the owner of a problem's fix stands behind it (Sustain.BUY_IN):
## commitment | none | compliance; "" when no dialog names the problem.
func buy_in(problem_id: String, facts_now: Dictionary) -> String:
	var best := ""
	var owners := dialogs.values().filter(func(d: DialogDef) -> bool: return d.owns == problem_id)
	if owners.is_empty():
		return ""
	var present := owners.filter(func(d: DialogDef) -> bool: return not left.has(d.person))
	if present.is_empty():
		return "none"  # the owner left: the fix has nobody to stand behind it, or against it
	for d: DialogDef in present:
		var o := effective_outcome(d.id, facts_now)
		if RANK.get(o, 0) > RANK.get(best, 0):
			best = o
	return BUY_IN_OF.get(best, "compliance")


## The KPIs a team lead committed to (a KPI dialog's agreed proposal).
func agreed_kpis(team: String, facts_now: Dictionary) -> Array:
	var out := []
	for id: String in agreed:
		var d: DialogDef = dialogs[id]
		if d.kpi_team == team and effective_outcome(id, facts_now) == "commitment":
			out.append_array(d.item(agreed[id]).get("kpis", []))
	return out


# ── Save ────────────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"trust": trust.duplicate(), "morale": morale.duplicate(), "memory": memory.duplicate(true),
		"revealed": revealed.duplicate(true), "outcomes": outcomes.duplicate(), "agreed": agreed.duplicate(),
		"talks": talks.duplicate(), "rest_until": rest_until.duplicate(), "facts": heard_facts.keys(),
		"prompts": prompts.duplicate(), "low_since": low_since.duplicate(), "ignored": ignored.duplicate(),
		"left": left.keys(), "coach_after": coach_after.duplicate(), "coach_asks": coach_asks,
	}


## Restore to_dict() output (a talk in progress is never saved). A save from
## before dialogs loads with the defaults. Returns the person and dialog ids
## the content no longer has (dropped); malformed values keep the default.
func load_dict(d: Dictionary) -> Array[String]:
	_reset()
	var dropped: Array[String] = []
	var percent := func(v: Variant) -> Variant: return clampi(int(v), 0, 100) if v is int or v is float else null
	var whole := func(v: Variant) -> Variant: return int(v) if v is int or v is float else null
	var remembered := func(v: Variant) -> Variant:
		if not v is Dictionary:
			return null
		return {"flags": Array(v.get("flags", [])).filter(func(f: Variant) -> bool: return f is String),
			"cooldown_until": int(v.get("cooldown_until", 0))}
	dropped.append_array(_load_map(d.get("trust"), persons, trust, percent))
	dropped.append_array(_load_map(d.get("morale"), persons, morale, percent))
	dropped.append_array(_load_map(d.get("memory"), persons, memory, remembered))
	dropped.append_array(_load_map(d.get("outcomes"), dialogs, outcomes, func(v: Variant) -> Variant: return v if v in Dialog.OUTCOMES else null))
	dropped.append_array(_load_map(d.get("agreed"), dialogs, agreed, func(v: Variant) -> Variant: return str(v)))
	dropped.append_array(_load_map(d.get("talks"), dialogs, talks, whole))
	dropped.append_array(_load_map(d.get("rest_until"), dialogs, rest_until, whole))
	dropped.append_array(_load_map(d.get("prompts"), dialogs, prompts, whole))
	dropped.append_array(_load_map(d.get("low_since"), persons, low_since, whole))
	dropped.append_array(_load_map(d.get("ignored"), persons, ignored, whole))
	var saved_left: Variant = d.get("left", [])
	for id: Variant in saved_left if saved_left is Array else []:
		if persons.has(str(id)):
			left[str(id)] = true
	var saved_revealed := JsonFile.dict_or_empty(d.get("revealed"))
	for key: Variant in saved_revealed:
		if dialogs.has(str(key).get_slice("/", 0)) and saved_revealed[key] is Dictionary:
			revealed[str(key)] = saved_revealed[key].duplicate()
	var saved_coach := JsonFile.dict_or_empty(d.get("coach_after"))
	if str(saved_coach.get("outcome", "")) in COACHED:
		coach_after = {"mission": str(saved_coach.get("mission", "")), "person": str(saved_coach.get("person", "")),
			"outcome": str(saved_coach["outcome"])}
	var asks: Variant = whole.call(d.get("coach_asks"))
	coach_asks = maxi(0, asks) if asks != null else 0
	var saved_facts: Variant = d.get("facts", [])
	for f: Variant in saved_facts if saved_facts is Array else []:
		heard_facts[str(f)] = true
	return dropped


## Copy a saved id → value map into `into` for ids `known` has: `parse` gives
## the value, or null for a malformed one (the default stays). Returns the
## unknown ids (dropped).
static func _load_map(saved: Variant, known: Dictionary, into: Dictionary, parse: Callable) -> Array[String]:
	var dropped: Array[String] = []
	var entries := JsonFile.dict_or_empty(saved)
	for id: Variant in entries:
		if not known.has(str(id)):
			dropped.append(str(id))
			continue
		var value: Variant = parse.call(entries[id])
		if value != null:
			into[str(id)] = value
	return dropped
