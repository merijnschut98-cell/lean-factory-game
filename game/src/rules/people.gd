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
	"customer_upset": 25, "expert": 60, "mentor": 55}
const MOOD_START := {"goed": 10, "neutraal": 0, "gespannen": -5, "stil": -5, "moe": -10}
## The least morale anyone the player meets in the training week starts with (a friendly
## first week, PLAN 2.13 D; content/dialogs.yaml people). Bad moods come later, with reasons.
const FRIENDLY_MORALE := 55
const TEAM_TRUST_WEIGHT := 10
const START_MIN := 5
const START_MAX := 80
## The last talk with this person: the most negative and the most positive
## memory count (ESTIMATES).
const MEMORY_NEGATIVE := {"confronted": -15, "ruined": -10, "pressured": -10, "promise_broken": -15}
## A promised date kept (the simulation judged it, Missions): the person's trust
## (dialog spec §6; drie winters §3: trust +5). Broken: memory "promise_broken".
const PROMISE_KEPT_TRUST := 5
const MEMORY_POSITIVE := {"committed": 15, "heard": 10}
## A talk that went wrong this way offers the repair move next time.
const REPAIRABLE := ["ruined", "pressured", "confronted"]
## What an outcome does to trust, morale and reputation (ESTIMATES, §4.1, §5.4).
const TRUST := {"commitment": 10, "partial": 5, "heard": 3, "lifted": 5, "compliance": -5, "ruined": -5}
const MORALE := {"commitment": 10, "partial": 5, "heard": 3, "compliance": -10, "lifted": 15}
## Morale drifts once a day between talks (QA 2.12 (b), phase-2 design §3.5: ignoring
## people is not free). ESTIMATES, tuned with autoplay (never-talks against the talker,
## docs/qa/autoplay-report.md): a team planned above LOAD_NORM of its time wears its
## people by up to LOAD_DRIFT a day at 100 % (twice that at LOAD_NORM + 2 × LOAD_SPAN);
## someone whose fix was won by pressure (their best agreement is compliance) loses
## COMPLIED_DRIFT a day; a check-in prompt left to expire costs IGNORED_MORALE; at a
## load under the norm, morale creeps back towards where the person started by
## RECOVER_DRIFT a day (never above it: good talks lift people higher). Neglect (the
## load, ignored check-ins) wears no one below NEGLECT_FLOOR: tired, not gone. Only
## pressure (a fix they owned won by compliance) takes them further, towards
## LEAVE_MORALE (people leave rarely, Merijn 2026-10-15; coordinator's tuning,
## 2026-10-21: nobody before day 100, nobody for a player who listens).
const LOAD_NORM := 0.85
const NEGLECT_FLOOR := 30
const LOAD_SPAN := 0.15
const LOAD_DRIFT := 0.25
const COMPLIED_DRIFT := 0.05
const IGNORED_MORALE := -3
const RECOVER_DRIFT := 0.1
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
## A check-in prompt nobody answers expires after this many days, at no cost
## (§5.7). The cadence keeps check-ins a kindness, not a chore: at most
## PROMPTS_AT_ONCE open, at most PROMPTS_PER_WEEK opened in any seven days,
## and a person's next prompt PROMPT_REST_DAYS after their last one opened.
const PROMPT_DAYS := 3
const PROMPTS_AT_ONCE := 1
const PROMPTS_PER_WEEK := 2
const PROMPT_REST_DAYS := 14
## People leave rarely (Merijn, 2026-10-15): morale below LEAVE_MORALE for
## LEAVE_DAYS, and LEAVE_IGNORED check-in prompts left unanswered. It closes
## a door (their talks, their ownership of a fix), never the game.
const LEAVE_MORALE := 20
const LEAVE_DAYS := 90
const LEAVE_IGNORED := 2
## Main-mission talks that end this way bring the coach's question about the
## talk on the next ask (spec §5.6); a talk that only listened does not.
const COACHED := ["ruined", "blocked", "compliance", "partial", "commitment"]
## The Mensen tab keeps this many talks per person, the newest (an estimate:
## enough to see how a person opened up over an act).
const TALK_LOG_MAX := 12
## The player's note on a person is kept to this many characters.
const NOTE_MAX := 600
## An expert's answer among what they told you: its key is TOPIC + the topic id.
const TOPIC := "topic:"
## The keys and value types of a saved observed line and a saved talk.
const OBSERVED_KEYS := {"dialog": TYPE_STRING, "key": TYPE_STRING, "text": TYPE_STRING, "place": TYPE_STRING}
const TALK_KEYS := {"dialog": TYPE_STRING, "outcome": TYPE_STRING, "trace": TYPE_ARRAY, "moves": TYPE_ARRAY}

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
## Promises the simulation judged: dialog id → kept (judge_promise).
var judged: Dictionary[String, bool] = {}
## dialog id → how often it was had.
var talks: Dictionary[String, int] = {}
## check-in id → when it can come again (minutes).
var rest_until: Dictionary[String, int] = {}
## heard:<id> facts learned concerns set.
var heard_facts: Dictionary[String, bool] = {}
## check-in id → when its prompt opened (minutes); person id → since when
## morale is below LEAVE_MORALE, and how many prompts expired unanswered.
var prompts: Dictionary[String, int] = {}
## When prompts opened (the last seven days), and each person's last one.
var prompt_log: Array[int] = []
var last_prompt: Dictionary[String, int] = {}
var low_since: Dictionary[String, int] = {}
var ignored: Dictionary[String, int] = {}
## Person ids of colleagues who left (to another grid operator).
var left: Dictionary[String, bool] = {}
## The main-mission talk the coach asks about next: {mission, person (short
## name), outcome}; {} for none. How many such questions he asked.
var coach_after: Dictionary = {}
var coach_asks := 0
## What the player heard each person say, for the Mensen tab (person-needs
## spec §4, §6): person id → [{dialog, key, text, at (minutes; -1 unknown),
## place}], in the order heard, each line once. Never read by the rules.
var observed: Dictionary[String, Array] = {}
## person id → their talks, oldest first: [{dialog, at, outcome, trace, moves,
## summary (talk_note; absent in older saves, TalkSummary.of reads it safely)}].
var talk_log: Dictionary[String, Array] = {}
## person id → the player's own note: never read by the rules, never judged.
var note: Dictionary[String, String] = {}
## The beats_after lines already said: "dialog id/index" → true.
var beat_lines: Dictionary[String, bool] = {}
## The daily drift (_drift): the last day it ran (-1 before the first), and each
## person's part-point not yet taken from or added to morale.
var drift_day := -1
var drift_carry: Dictionary[String, float] = {}


func _init(person_defs: Array[PersonDef], dialog_defs: Array[DialogDef], lines: Dictionary) -> void:
	bank = lines
	for p in person_defs:
		persons[p.id] = p
	for d in dialog_defs:
		dialogs[d.id] = d
	_reset()


func _reset() -> void:
	for state: Dictionary in [trust, morale, memory, revealed, outcomes, agreed, talks, rest_until, heard_facts, prompts,
			low_since, ignored, left, coach_after, last_prompt, observed, talk_log, note, beat_lines, drift_carry, judged]:
		state.clear()
	prompt_log.clear()
	drift_day = -1
	coach_asks = 0
	for p: PersonDef in persons.values():
		trust[p.id] = p.trust
		morale[p.id] = p.morale


# ── Who has something to say ────────────────────────────────────────────────

## The talk a person has for the player now: a persuasion of the main mission,
## then of another active mission, then a check-in, then an expert talk; null
## when there is none.
func dialog_for(person_id: String, world: Dictionary) -> DialogDef:
	var best: DialogDef = null
	var best_rank := -1
	var known := facts(world.get("facts", {}))
	for d: DialogDef in dialogs.values():
		var rank := _rank(d, world, known) if d.person == person_id and not left.has(person_id) else -1
		if rank > best_rank or (rank == best_rank and rank >= 0 and best.kind == ExpertTalk.KIND):
			best = d
			best_rank = rank
	return best


## 2 for the main mission's talk, 1 for another active mission's, 0 for a
## check-in or an expert talk (dialog_for puts the expert last); -1 when it
## cannot be had now. `known`: every fact (facts()).
func _rank(d: DialogDef, world: Dictionary, known: Dictionary) -> int:
	if d.kind == ExpertTalk.KIND:
		var active: Array = world.get("active", [])
		var on := d.mission.is_empty() or d.on_any(active)
		var problems := JsonFile.dict_or_empty(world.get("problems"))
		return 0 if on and DialogDef.needs_met(d.needs, known) and _has_open_topic(d, known, problems) else -1
	if d.kind == "checkin":
		var below := int(d.trigger.get("morale_below", 101))
		var now := int(world.get("now", 0))
		var ready: bool = morale.get(d.person, 0) < below and int(rest_until.get(d.id, 0)) <= now \
			and _in_beat_window(d.trigger, JsonFile.dict_or_empty(world.get("beats")), now)
		return 0 if ready and DialogDef.needs_met(JsonFile.dict_or_empty(d.trigger.get("needs")), known) else -1
	if not (d.requires_clue.is_empty() or world.get("found", {}).has(d.requires_clue)) \
			or not DialogDef.needs_met(d.needs, known) or effective_outcome(d.id, known) == "commitment":
		return -1
	if d.on_any(world.get("main", [])):
		return 2
	var active: Array = world.get("active", [])
	return 1 if d.on_any(active) else -1


## A trigger without a beat always holds; with one (`beats`: id → minutes;
## Missions.beats), from `after_days` after the beat on, or with `before_days`
## from that many days before the beat until the beat. A beat whose date is
## not known yet has not come near.
static func _in_beat_window(trigger: Dictionary, beats: Dictionary, now: int) -> bool:
	if not trigger.has("beat"):
		return true
	var at: Variant = beats.get(str(trigger["beat"]))
	if not (at is int or at is float):
		return false
	if trigger.has("before_days"):
		return now >= int(at) - SimCalendar.days(int(trigger["before_days"])) and now < int(at)
	return now >= int(at) + SimCalendar.days(int(trigger.get("after_days", 0)))


## Whether a dated beat (`beats`, as above) has come.
static func _beat_passed(beat: String, beats: Dictionary, now: int) -> bool:
	var at: Variant = beats.get(beat)
	return (at is int or at is float) and now >= int(at)


## After a ruined talk, until the next working day at 08:30.
func cooling_down(person_id: String, now: int) -> bool:
	return int(memory.get(person_id, {}).get("cooldown_until", 0)) > now


## The talk's first line: version `v`'s own (a variant keyed on a fact, e.g. a broken
## promise), else the retry opening once it was had, else the opening.
func opening(d: DialogDef, v: int = -1) -> String:
	if v >= 0 and v < d.variants.size() and d.variants[v].get("opening") is String:
		return d.variants[v]["opening"]
	return d.retry_opening if talks.get(d.id, 0) > 0 and not d.retry_opening.is_empty() else d.opening


## The simulation judged the date promised in talk `dialog_id` (once): kept, the
## person's trust rises; broken, they remember it at the next talk.
func judge_promise(dialog_id: String, kept: bool) -> void:
	var d: DialogDef = dialogs.get(dialog_id)
	if d == null or judged.has(dialog_id) or not persons.has(d.person):
		return
	judged[dialog_id] = kept
	if kept:
		trust[d.person] = clampi(trust[d.person] + PROMISE_KEPT_TRUST, 0, 100)
		return
	var remembered: Dictionary = memory.get_or_add(d.person, {"flags": [], "cooldown_until": 0})
	remembered["flags"].append("promise_broken")


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
		# The game's seed, and a new deal of options each time this talk is had again.
		"seed": hash([int(world.get("seed", 0)), talks.get(d.id, 0)]),
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
## agreement under condition still waits for, or "")}. `main`: the main
## mission the talk belongs to ("" for none), so the coach asks about it next.
func finish(d: Dialog, now: int, main := "") -> Dictionary:
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
	if not main.is_empty() and d.def.kind == "persuade" and o in COACHED:
		coach_after = {"mission": main, "person": who.short, "outcome": o}
	var result := {
		"dialog": d.def.id, "person": who.id, "outcome": o, "trust": trust[who.id], "morale": morale[who.id],
		"reputation": REPUTATION.get(o, 0), "team_trust": 1 if o == "commitment" else 0, "confronted": d.confronted,
		"clue": d.unlocked_clue(), "facts": facts, "cooldown_until": cooldown, "wait_for": d.wait_for(),
		"hints": d.def.block.get("routes", []).map(func(r: Dictionary) -> String: return str(r.get("hint", ""))) \
			if o == "blocked" else [],
		"ruud_names": ruud_names(d),
	}
	_keep(d, now, result)
	return result


## The talk's note for the journal (phase 2 design §2.2): what the talk screen
## no longer shows while it runs, kept with the talk: the band it ended in, the
## mood, what was heard per layer (position | interest | concern → line), and
## from `result` whether a clue came of it, a block's route hints, what an
## agreement still waits for and Ruud's naming. Never read by the rules.
static func talk_note(d: Dialog, result: Dictionary) -> Dictionary:
	var heard := {"position": str(d.position().get("text", ""))}
	for layer: Dictionary in d.layers():
		if d.revealed.has(layer["id"]):
			heard[str(layer["id"])] = str(layer.get("text", ""))
	return {"band": Dialog.band_of(d.openness), "mood": d.mood, "heard": heard,
		"new_clue": not str(result["clue"]).is_empty(),
		"hints": result["hints"], "wait_for": result["wait_for"], "ruud_names": result["ruud_names"]}


# ── An expert talk (ExpertTalk) ─────────────────────────────────────────────

## Start an expert talk: the person's trust, what was asked before, the facts,
## the clues found (a clue found already is not new) and the problems missions
## raised (ExpertTalk.is_open).
func start_expert(d: DialogDef, world: Dictionary) -> ExpertTalk:
	return ExpertTalk.new(d, persons[d.person], {"trust": trust[d.person], "asked": asked_topics(d.id),
		"facts": facts(world.get("facts", {})), "found": world.get("found", {}), "problems": world.get("problems", {})})


## Apply an ended expert talk: trust, what was asked (kept as what they told
## you: an answer is an observed line under the key "topic:<id>"), the facts
## its topics unlocked. Nothing is won or lost: no outcome, no memory flag.
## Returns {dialog, person, trust, morale, asked (this talk's topic ids), facts}.
func finish_expert(t: ExpertTalk, now: int) -> Dictionary:
	var who := t.who
	trust[who.id] = t.trust
	talks[t.def.id] = talks.get(t.def.id, 0) + 1
	for id in t.asked_now:
		_observe(who.id, {"dialog": t.def.id, "key": TOPIC + id, "text": str(t.def.topic(id)["answer"]), "at": now,
			"place": who.place})
	var unlocked := t.unlocked_facts()
	for f: String in unlocked:
		heard_facts[f] = true
	return {"dialog": t.def.id, "person": who.id, "trust": trust[who.id], "morale": morale[who.id],
		"asked": t.asked_now.duplicate(), "facts": unlocked}


## The topic ids of expert talk `dialog_id` asked so far, in order.
func asked_topics(dialog_id: String) -> Array[String]:
	var out: Array[String] = []
	var d: DialogDef = dialogs.get(dialog_id)
	for line: Dictionary in observed.get(d.person, []) if d != null else []:
		if line["dialog"] == dialog_id and str(line["key"]).begins_with(TOPIC):
			out.append(str(line["key"]).trim_prefix(TOPIC))
	return out


func _has_open_topic(d: DialogDef, known: Dictionary, problems: Dictionary) -> bool:
	var asked := asked_topics(d.id)
	return d.topics.any(func(t: Dictionary) -> bool:
		return not t["id"] in asked and ExpertTalk.is_open(t, known, trust[d.person], problems))


## The promises the player made and the person agreed to (a proposal with a
## `promise`), for the check that keeps them (2.4b): dialog id → {proposal,
## kind, days, at (the day of the talk that agreed it, minutes)}. Read from
## what is saved anyway: the agreement and the talk log.
func promises() -> Dictionary:
	var out := {}
	for id: String in agreed:
		var d: DialogDef = dialogs.get(id)
		var promise := JsonFile.dict_or_empty(d.item(str(agreed[id])).get("promise")) if d != null else {}
		if promise.is_empty():
			continue
		var at := -1
		for entry: Dictionary in talk_log.get(d.person, []):
			if entry.get("dialog") == id and entry.get("outcome") == outcomes.get(id):
				at = int(entry.get("at", -1))
		out[id] = {"proposal": agreed[id], "kind": str(promise.get("kind", "")), "days": int(promise.get("days", 0)),
			"at": at}
	return out


## Ruud's line after an Act 0 talk (tutorial talks spec §3): he names one
## listening move that landed, the day's move first, else the one that landed
## most; when none did he asks (`none`). "" after any other talk: from Act I he
## asks, he never names. (The spec's second rule, the move that drew out the
## concern, waits: the talk keeps no record of which move that was.)
func ruud_names(d: Dialog) -> String:
	if not d.def.tutorial:
		return ""
	var best := "none"
	var most := 0
	for i in d.made.size():
		var gain := d.trace[i + 1] - d.trace[i] if i + 1 < d.trace.size() else 0
		var move := d.made[i]
		if not move in Dialog.LISTEN or gain <= 0:
			continue
		if move in d.def.teaches:
			best = move
			break
		if gain > most:
			best = move
			most = gain
	var lines := JsonFile.dict_or_empty(bank.get("ruud_names"))
	return str(lines.get(best, "")).replace("{person}", d.who.short)


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


## What the talk adds to the Mensen tab: each new line the person said, and
## the talk itself with its note (talk_note).
func _keep(d: Dialog, now: int, result: Dictionary) -> void:
	var who := d.who.id
	for line: Dictionary in d.told:
		_observe(who, {"dialog": d.def.id, "key": line["key"], "text": line["text"], "at": now, "place": d.who.place})
	var log: Array = talk_log.get(who, [])
	log.append({"dialog": d.def.id, "at": now, "outcome": d.outcome, "trace": Array(d.trace), "moves": Array(d.made),
		"summary": talk_note(d, result)})
	talk_log[who] = log.slice(-TALK_LOG_MAX)


## A line is kept once: an expert's answer by its topic key in its talk (two topics may
## answer alike), any other line by its text.
func _observe(person_id: String, entry: Dictionary) -> void:
	var heard: Array = observed.get(person_id, [])
	var topic := str(entry["key"]).begins_with(TOPIC)
	if not heard.any(func(o: Dictionary) -> bool:
			return o.get("dialog") == entry["dialog"] and o.get("key") == entry["key"] if topic else o.get("text") == entry["text"]):
		heard.append(entry)
	observed[person_id] = heard


## The player's note on a person (trimmed, at most NOTE_MAX characters; empty
## removes it). False for an unknown person.
func set_note(person_id: String, text: String) -> bool:
	if not persons.has(person_id):
		return false
	var clean := text.strip_edges().left(NOTE_MAX)
	if clean.is_empty():
		note.erase(person_id)
	else:
		note[person_id] = clean
	return true


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

## After every action (world as for dialog_for): a prompt left unanswered
## PROMPT_DAYS expires (ignored); a check-in that can be had opens a prompt
## when the cadence allows, for the lowest morale first; the low-morale clock
## runs; a partial agreement whose beats_after line came true speaks up. No
## prompt opens while the training week runs (world `training`: a friendly first
## week, PLAN 2.13 D; its scripted talks come by mission).
## Returns [{type: left, person}] for whoever leaves today and
## [{type: beat_line, person, name, dialog, text}] for each line said.
func daily(world: Dictionary) -> Array[Dictionary]:
	var now := int(world.get("now", 0))
	_retire(JsonFile.dict_or_empty(world.get("beats")), now)
	var events := _beat_lines(world)
	var pressured := _pressured(facts(world.get("facts", {})))
	for id: String in prompts.keys():
		if now - prompts[id] >= SimCalendar.days(PROMPT_DAYS):
			prompts.erase(id)
			var who := dialogs[id].person
			ignored[who] = ignored.get(who, 0) + 1
			var floor_at := 0 if pressured.has(who) else mini(NEGLECT_FLOOR, morale[who])
			morale[who] = maxi(floor_at, morale[who] + IGNORED_MORALE)
	_drift(world, pressured)
	_open_prompt(world)
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


## The people whose fix was won by pressure: their best agreement on a dialog that owns
## a fix is compliance (`known`: every fact, facts()).
func _pressured(known: Dictionary) -> Dictionary:
	var out := {}
	for d: DialogDef in dialogs.values():
		if not d.owns.is_empty() and effective_outcome(d.id, known) == "compliance":
			out[d.person] = true
	return out


## Morale's drift for every day since the last (the constants above): world `loads`
## (team → utilisation, Capacity) and the facts. Not in the training week (a friendly
## first week, PLAN 2.13 D), and not before the first day it runs.
func _drift(world: Dictionary, pressured: Dictionary) -> void:
	var today := SimCalendar.day_of(int(world.get("now", 0)))
	var days := today - drift_day if drift_day >= 0 else 0
	drift_day = today
	if days <= 0 or world.get("training", false):
		return
	var loads := JsonFile.dict_or_empty(world.get("loads"))
	for p: PersonDef in persons.values():
		if left.has(p.id):
			continue
		var over := clampf((float(loads.get(p.team, 0.0)) - LOAD_NORM) / LOAD_SPAN, 0.0, 2.0)
		var per_day := -(COMPLIED_DRIFT if pressured.has(p.id) else 0.0)
		if over > 0.0 and morale[p.id] > NEGLECT_FLOOR:
			per_day -= LOAD_DRIFT * over  # work alone makes people tired, not gone: neglect does the rest
		elif over == 0.0 and per_day == 0.0 and morale[p.id] < p.morale:
			per_day = RECOVER_DRIFT
		var change: float = drift_carry.get(p.id, 0.0) + per_day * days
		var whole := int(snappedf(change, 1e-6))  # towards zero: the part-point waits for tomorrow
		drift_carry[p.id] = change - whole
		if whole != 0:
			morale[p.id] = maxi(0, morale[p.id] + whole) if per_day < 0.0 else mini(morale[p.id] + whole, p.morale)


## Whoever leaves on a dated beat that has come is gone (PersonDef.leaves_on),
## and their open prompts go with them.
func _retire(beats: Dictionary, now: int) -> void:
	for p: PersonDef in persons.values():
		if not p.leaves_on.is_empty() and not left.has(p.id) and _beat_passed(p.leaves_on, beats, now):
			left[p.id] = true
			for id: String in prompts.keys():
				if dialogs[id].person == p.id:
					prompts.erase(id)


## The beats_after lines due now: a dialog that ended in a partial agreement
## (its best outcome so far), whose `when` holds, each line once. A person
## who left says nothing. The notebook keeps what was said.
func _beat_lines(world: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var known := facts(world.get("facts", {}))
	for d: DialogDef in dialogs.values():
		if outcomes.get(d.id) != "partial" or left.has(d.person):
			continue
		for i in d.beats_after.size():
			var line: Dictionary = d.beats_after[i]
			var key := _key(d.id, i)
			if beat_lines.has(key) or not known.has(str(line.get("when", ""))):
				continue
			beat_lines[key] = true
			var text := str(line.get("text", ""))
			_observe(d.person, {"dialog": d.id, "key": "beat", "text": text, "at": int(world.get("now", 0)),
				"place": persons[d.person].place})
			out.append({"type": "beat_line", "person": d.person, "name": persons[d.person].name, "dialog": d.id,
				"text": text})
	return out


func _open_prompt(world: Dictionary) -> void:
	var now := int(world.get("now", 0))
	prompt_log.assign(prompt_log.filter(func(t: int) -> bool: return now - t < SimCalendar.days(7)))
	if world.get("training", false) or prompts.size() >= PROMPTS_AT_ONCE or prompt_log.size() >= PROMPTS_PER_WEEK:
		return
	var known := facts(world.get("facts", {}))
	var due := dialogs.values().filter(func(d: DialogDef) -> bool:
		return d.kind == "checkin" and not left.has(d.person) and _rank(d, world, known) == 0 \
			and (not last_prompt.has(d.person) or now - last_prompt[d.person] >= SimCalendar.days(PROMPT_REST_DAYS)))
	if due.is_empty():
		return
	due.sort_custom(func(a: DialogDef, b: DialogDef) -> bool:
		return [morale[a.person], a.id] < [morale[b.person], b.id])
	var d: DialogDef = due[0]
	prompts[d.id] = now
	prompt_log.append(now)
	last_prompt[d.person] = now


## The open prompts' dagstart lines: [{person, dialog, line}] (spec §5.7).
func prompt_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in prompts:
		out.append({"person": dialogs[id].person, "dialog": id, "line": dialogs[id].prompt})
	return out


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
		exprs.append_array(d.topics.map(func(t: Dictionary) -> Variant: return t.get("needs", {})))
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
		"prompt_log": prompt_log.duplicate(), "last_prompt": last_prompt.duplicate(),
		"observed": observed.duplicate(true), "talk_log": talk_log.duplicate(true), "note": note.duplicate(),
		"beat_lines": beat_lines.keys(), "drift_day": drift_day, "drift_carry": drift_carry.duplicate(),
		"judged": judged.duplicate(),
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
		var flags: Variant = v.get("flags")
		var until: Variant = whole.call(v.get("cooldown_until"))
		return {"flags": flags.filter(func(f: Variant) -> bool: return f is String) if flags is Array else [],
			"cooldown_until": until if until != null else 0}
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
	dropped.append_array(_load_map(d.get("last_prompt"), persons, last_prompt, whole))
	var saved_log: Variant = d.get("prompt_log", [])
	for t: Variant in saved_log if saved_log is Array else []:
		if t is int or t is float:
			prompt_log.append(int(t))
	var saved_left: Variant = d.get("left", [])
	for id: Variant in saved_left if saved_left is Array else []:
		if persons.has(str(id)):
			left[str(id)] = true
	var saved_revealed := JsonFile.dict_or_empty(d.get("revealed"))
	for key: Variant in saved_revealed:
		if not saved_revealed[key] is Dictionary:
			continue
		if _known_version(str(key)):
			revealed[str(key)] = saved_revealed[key].duplicate()
		else:
			dropped.append(str(key))
	var saved_coach := JsonFile.dict_or_empty(d.get("coach_after"))
	if str(saved_coach.get("outcome", "")) in COACHED:
		coach_after = {"mission": str(saved_coach.get("mission", "")), "person": str(saved_coach.get("person", "")),
			"outcome": str(saved_coach["outcome"])}
	var asks: Variant = whole.call(d.get("coach_asks"))
	coach_asks = maxi(0, asks) if asks != null else 0
	var saved_lines: Variant = d.get("beat_lines", [])
	for key: Variant in saved_lines if saved_lines is Array else []:
		if key is String and dialogs.has(key.get_slice("/", 0)):
			beat_lines[key] = true
	dropped.append_array(_load_map(d.get("judged"), dialogs, judged, func(v: Variant) -> Variant: return v if v is bool else null))
	var day: Variant = whole.call(d.get("drift_day"))
	drift_day = day if day != null else -1
	dropped.append_array(_load_map(d.get("drift_carry"), persons, drift_carry,
		func(v: Variant) -> Variant: return clampf(float(v), -1.0, 1.0) if v is int or v is float else null))
	var saved_facts: Variant = d.get("facts", [])
	for f: Variant in saved_facts if saved_facts is Array else []:
		heard_facts[str(f)] = true
	dropped.append_array(_load_map(d.get("observed"), persons, observed, _entries.bind(OBSERVED_KEYS)))
	dropped.append_array(_load_map(d.get("talk_log"), persons, talk_log, _entries.bind(TALK_KEYS)))
	dropped.append_array(_load_map(d.get("note"), persons, note,
		func(v: Variant) -> Variant: return str(v).left(NOTE_MAX) if v is String and not v.is_empty() else null))
	if not d.has("observed"):
		_observe_revealed()
	return dropped


## The sound entries of a saved list (each a Dictionary with `keys` of their
## types and a whole `at`); null when it is not a list.
static func _entries(v: Variant, keys: Dictionary) -> Variant:
	if not v is Array:
		return null
	return v.filter(func(e: Variant) -> bool:
		return e is Dictionary and (e.get("at") is int or e.get("at") is float) \
			and keys.keys().all(func(k: String) -> bool: return typeof(e.get(k)) == keys[k])
	).map(func(e: Dictionary) -> Dictionary: return e.merged({"at": int(e["at"])}, true))


## Whether a saved "<dialog>/<v>" key (_key) names a dialog and a version
## (-1 the base, else a variant) the content still has.
func _known_version(key: String) -> bool:
	var v := key.get_slice("/", 1)
	var d: DialogDef = dialogs.get(key.get_slice("/", 0))
	return d != null and v.is_valid_int() and int(v) >= -1 and int(v) < d.variants.size()


## A save from before the notebook: what was revealed, heard at an unknown time.
func _observe_revealed() -> void:
	for key: String in revealed:
		var d: DialogDef = dialogs[key.get_slice("/", 0)]
		var v := int(key.get_slice("/", 1))
		var lines := [{"key": "position", "text": d.position_of(v).get("text", "")}]
		for layer: Dictionary in d.layers_of(v):
			if revealed[key].has(layer["id"]):
				lines.append({"key": layer["id"], "text": layer.get("text", "")})
		for line: Dictionary in lines:
			_observe(d.person, {"dialog": d.id, "key": line["key"], "text": str(line["text"]), "at": -1,
				"place": persons[d.person].place})


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
