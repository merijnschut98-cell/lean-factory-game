class_name Dialog
extends RefCounted
## One conversation in progress with a named person (CLAUDE.md §2, "Dialogs
## are give and take"; docs/superpowers/specs/2026-10-15-dialog-system-design.md
## §3–§4). Deterministic, no nodes: People builds it with its start state and
## applies its outcome afterwards.
##
## The person has a state (openness, trust in you, mood, and hidden layers:
## position → interest → concern). The player picks a move each turn from a
## fixed palette: the eight listening moves of MORE PIES, five steering moves,
## pressure and blame. What a move does depends on the state and on what was
## just said (the tags of the last line), so the same move helps at one moment
## and hurts at another: there is no golden path. Openness cannot pass the
## next hidden layer's threshold + CEILING, so the concern must be earned.
##
## Results are ids, numbers and the content's Dutch lines; the meter reports
## feeling after the fact, never which move is right.

const LISTEN := ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry", "experience", "silence"]
const STEER := ["perspective", "show_data", "propose_experiment", "propose", "ask_commitment"]
## The fixed palette, in the order the UI shows it (mirrored in build_content.py).
const MOVES := ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry", "experience", "silence",
	"perspective", "show_data", "propose_experiment", "propose", "ask_commitment",
	"pressure", "confront", "repair", "close"]
## Moves that need a pick: a found clue, an experiment, a proposal.
const PICK_MOVES := ["show_data", "propose_experiment", "propose"]
const TAGS := ["claim", "feeling", "hesitation", "admission", "doubt"]
## What a person needs from a talk before they open up (person-needs spec §1;
## hidden, never shown): it weighs how each move lands.
const NEEDS := ["facts", "safety", "recognition", "time", "fairness"]
const ARCHETYPES := ["defender", "cynic", "craftsman", "overloaded", "rule_bound", "quiet", "customer_upset", "expert", "mentor"]
const KINDS := ["persuade", "checkin", "expert"]
const MOODS := ["goed", "neutraal", "gespannen", "moe", "stil"]
const OUTCOMES := ["commitment", "partial", "heard", "none", "blocked", "compliance", "ruined", "lifted"]

# Every number below is an ESTIMATE (spec §3.3, §3.7, §4.1), chosen so that
# listening first, then steering, reaches commitment in 7–9 moves, and pushing
# first ruins a guarded person in 3.

## Band floors of openness: Dicht · Op z'n hoede · Luistert · Open · Denkt mee.
const BANDS := [10, 20, 40, 60, 80]
## "Er zit meer achter…": the concern's lead-in can come from here on.
const CUE_AT := 65
## Δ openness of a listening move that lands, and one that does not.
const LANDS := {"mood": 8, "open_question": 6, "paraphrase": 7, "reflect": 10, "empathy": 8, "inquiry": 8,
	"experience": 8, "silence": 12}
const MISSES := {"mood": 2, "open_question": 3, "paraphrase": 1, "reflect": -3, "empathy": 2, "inquiry": 2,
	"experience": -5, "silence": -4}
## Empathy right after an admission lands harder.
const EMPATHY_AFTER_ADMISSION := 10
# Route variety (four-tier audit §4.4, E1–E5, estimates): with the moves
# above alone, one fixed listening route won every talk.
## E1: empathy answers something shown (or comes in the first moves).
const EMPATHY_AFTER := ["feeling", "admission"]
## E2: inquiry digs into something said.
const INQUIRY_AFTER := ["claim", "hesitation"]
## E3: a misread of what was just shown costs more: {move: [tag, Δ]}.
const MISREAD := {"silence": ["feeling", -6], "reflect": ["hesitation", -5]}
## E4: a listening move's landing Δ by how often it was used before in this
## talk (not in a row; in a row REPEAT_FACTOR and REPEAT_THIRD apply).
const USE_DECAY := [1.0, 0.7, 0.4]
## Open questions land this often; after that the person has said what is easy to say.
const OPEN_QUESTIONS_THAT_LAND := 3
## Asking the mood lands in the first moves, or once on a hard day.
const EARLY_MOVES := 2
const HARD_DAY_MOODS := ["gespannen", "moe", "stil"]
## Inquiry lands within this much below the next layer's threshold. The
## spec's text says 10; 15 is what its own worked example needs (§7.2 B5′).
const INQUIRY_REACH := 15
## Sharing your own experience needs this much trust.
const EXPERIENCE_TRUST := 50
## A steering move before the person feels heard, or below STEER_FROM.
const TOO_EARLY := -12
const STEER_FROM := 40
## Steering that is not too early: {at: openness it needs, lands, misses}.
const PERSPECTIVE := {"at": 50, "lands": 8, "misses": -4}
const SHOW_DATA := {"at": 55, "lands": 10, "misses": -8}
const EXPERIMENT := {"at": 45, "lands": 6, "misses": 0}
## A proposal that addresses a revealed layer; one that guesses the hidden concern.
const PROPOSAL_ADDRESSES := 8
const LUCKY_GUESS := 4
const PRESSURE := {"openness": -15, "trust": -8}
const CONFRONT := {"openness": -20, "trust": -10}
const REPAIR := {"openness": 12, "trust": 3}
## Asking for agreement too low, without pressure: "Nee. Nog niet."
const REFUSAL := -10
## The same move as the previous one counts half; a third time in a row costs.
const REPEAT_FACTOR := 0.5
const REPEAT_THIRD := -3
## Openness stays below the next hidden layer's threshold + this.
const CEILING := 9
const COMMIT_AT := 70
const PARTIAL_AT := 55
## Below this the talk is ruined.
const RUINED_BELOW := 10
## A graceful close counts as heard from here, or this far above the start.
const HEARD_AT := 60
const HEARD_GAIN := 15
## A check-in lifts someone's spirit once the concern is out, from here.
const LIFTED_AT := 70
## In-game minutes a move takes (the clock advances once, when the talk ends).
const MINUTES_PER_MOVE := 3
## A reply's arrow: ▲▲ / ▼▼ from this change on, ▲ / ▼ below it (Merijn,
## 2026-10-15: the meter shows arrows, never numbers).
const ARROW_BIG := 8
## The first talks (Act 0) are tutorials: openness never falls below
## RUINED_BELOW there, so they cannot be ruined, and there is more time
## (Merijn, 2026-10-15; dialog scripts R-D5, estimate).
const TUTORIAL_PATIENCE := 12
## Moves before the person has to go; busy people and tired days give less.
const PATIENCE := 10
## E5: busy and sceptical people give less time.
const PATIENCE_BY_ARCHETYPE := {"overloaded": -3, "rule_bound": -2, "cynic": -1, "quiet": -1}
const PATIENCE_BY_MOOD := {"moe": -2}
## Never less than this, however busy and tired (an overloaded person on a
## tired day had five moves: no talk could be won; estimate).
const PATIENCE_MIN := 7
## The person looks at the clock with this many moves left.
const PATIENCE_WARNING := 2
const TRUST_PER_PIP := 20
## How an archetype weighs a move that lands (never shown; reading people is
## part of the game).
const WEIGHTS := {
	"cynic": {"show_data": 1.5, "experience": 0.5},
	"craftsman": {"inquiry": 1.5},
	"overloaded": {"mood": 1.5},
	"rule_bound": {"show_data": 1.5, "propose_experiment": 1.5, "reflect": 0.5},
	"quiet": {"silence": 1.5},
	"customer_upset": {"empathy": 1.5, "paraphrase": 1.5},
	# Drie winters §4.2 (S7, estimates): a mentor wants to hear what you learned,
	# and has seen your numbers. Ruud only, in two talks.
	"mentor": {"experience": 1.5, "show_data": 0.5},
}
## Person needs (person-needs spec §1.2, estimates): a landing Δ × this, per
## move and need (moves not listed: ×1). Each need has its own strong opening
## move, so no single first move suits everyone.
const NEED_WEIGHTS := {
	"mood": {"facts": 0.5, "recognition": 0.75, "time": 1.5, "fairness": 0.75},
	"open_question": {"facts": 0.75, "recognition": 1.25, "time": 0.5, "fairness": 1.5},
	"reflect": {"facts": 0.75, "safety": 1.25, "fairness": 1.25},
	"empathy": {"facts": 0.5, "safety": 1.5, "recognition": 0.75, "fairness": 0.5},
	"paraphrase": {"facts": 1.25, "recognition": 1.5, "time": 1.25},
	"inquiry": {"facts": 1.5, "safety": 0.5, "time": 0.75},
	"experience": {"facts": 0.75, "safety": 1.5, "recognition": 0.5, "time": 0.5},
	"silence": {"time": 0.5},
	"perspective": {"safety": 0.75, "recognition": 0.75, "fairness": 1.5},
	"show_data": {"facts": 1.5, "safety": 0.5, "recognition": 0.75},
	"propose_experiment": {"safety": 1.25, "time": 1.5, "fairness": 0.75},
}
## For a safety need, a question before feeling heard sounds like an audit;
## once heard it is curiosity (×1).
const SAFETY_INQUIRY_HEARD := 1.0
## The mood sharpens the need (tense) or softens it (tired, quiet):
## weight today = 1 + (weight − 1) × k.
const NEED_MOOD_K := {"gespannen": 1.5, "goed": 1.0, "neutraal": 1.0, "moe": 0.5, "stil": 0.5}
## The combined archetype × need factor stays within these (no move becomes
## a trap, none a sure thing).
const WEIGHT_MIN := 0.25
const WEIGHT_MAX := 2.0
## Moves that wear out (PLAN 1.6c (b), person-needs spec §3): when a move's
## force falls below REPEAT_FACTOR (a third use in a talk, or a third in a
## row) the person says so once per move, in their archetype's words
## (bank.wear_out.<archetype>.ask for questions, .say for statements); silence
## keeps its own reply.
const WEAR_ASK := ["mood", "open_question", "inquiry"]
## A statement is answered once: a landing move uses up the tags it answers,
## and a shared bank line leaves the rest of the person's last words standing.
const ANSWERS := {"paraphrase": ["claim"], "inquiry": ["claim", "hesitation"], "reflect": ["feeling"],
	"empathy": ["feeling", "admission"], "silence": ["hesitation"], "experience": ["doubt", "admission"]}

## The variables that make up a talk in progress (copy()); the first ones up to
## `trace` are what the next move depends on (state_key()).
const COPIED := ["openness", "trust", "mood", "version", "revealed", "heard", "pressured", "confronted", "table",
	"patience", "outcome", "_repaired", "_last_move", "_streak", "_last_tags", "_uses", "_mood_asked",
	"_lead_in_said", "_co_offered", "_warned", "_worn", "moves_made",
	"trace", "made", "told", "steered_early", "concern_by", "start_openness", "_found", "_facts", "_retry"]
const STATE_KEYS := 22  # COPIED up to "trace"; test_dialog_routes.gd checks it

var def: DialogDef
var who: PersonDef
## The shared lines (dialogs.json `bank`).
var bank: Dictionary
var openness: int
var start_openness: int
var trust: int
var mood: String
## The variant of the dialog in use (DialogDef.version), -1 for the dialog as written.
var version := -1
## Layer id → true, kept from earlier talks with this person.
var revealed: Dictionary = {}
## A paraphrase or reflection landed: steering can land from now on.
var heard := false
var pressured := false
var confronted := false
## The proposal or experiment on the table ("" for none).
var table := ""
## Moves left.
var patience: int
## "" while the talk runs (OUTCOMES otherwise).
var outcome := ""
var moves_made := 0
## Openness after each move, starting with the start.
var trace: Array[int] = []
## The moves made, in order (the Mensen tab's record of the talk).
var made: Array[String] = []
## What the person told that the player can note (person-needs spec §4): the
## position, each layer drawn out, and every line that shows their need (a
## `tell`), as [{key, text}] in the order said.
var told: Array[Dictionary] = []
var _found: Dictionary
var _facts: Dictionary
var _retry: bool
var _repaired := false
var _last_move := ""
var _streak := 0
var _last_tags: Array = []
var _uses: Dictionary = {}
var _mood_asked := false
var _lead_in_said := false
var _co_offered := false
var _warned := false
var _worn: Dictionary = {}
## How the talk went, for the discoveries: a steering move came before the
## concern was out; the move that revealed the concern.
var steered_early := false
var concern_by := ""


## `start`: {openness, trust, mood, found (clue id → true), facts (fact → true),
## retry (the last talk went wrong: repair is offered), version, revealed}.
func _init(dialog: DialogDef, person: PersonDef, lines: Dictionary, start: Dictionary) -> void:
	def = dialog
	who = person
	bank = lines
	openness = clampi(int(start.get("openness", 50)), 0, 100)
	start_openness = openness
	trust = clampi(int(start.get("trust", person.trust)), 0, 100)
	mood = str(start.get("mood", "neutraal"))
	version = int(start.get("version", -1))
	revealed = JsonFile.dict_or_empty(start.get("revealed")).duplicate()
	_found = JsonFile.dict_or_empty(start.get("found"))
	_facts = JsonFile.dict_or_empty(start.get("facts"))
	_retry = bool(start.get("retry", false))
	_last_tags = position().get("tags", [])
	if def.tutorial:
		patience = def.patience if def.patience > 0 else TUTORIAL_PATIENCE
	else:
		# E5: the archetype and the day cap the time; a dialog may author less (a full diary).
		patience = maxi(PATIENCE_MIN, PATIENCE + int(PATIENCE_BY_ARCHETYPE.get(who.archetype, 0))
			+ int(PATIENCE_BY_MOOD.get(mood, 0)))
		if def.patience > 0:
			patience = mini(patience, def.patience)
	trace.append(openness)
	_note(_told(position(), "position"), true)


func position() -> Dictionary:
	return def.position_of(version)


func layers() -> Array:
	return def.layers_of(version)


## The fixed palette: [{id, row (listen | steer | pressure | other), label,
## line (what you will say), picks? ([{id, name?, text?}])}]. Every move,
## always (Merijn, 2026-10-15): nothing is filtered by fit.
func moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in MOVES:
		var chips := JsonFile.dict_or_empty(bank["labels"].get("chips"))
		var m := {"id": id, "row": _row(id), "label": str(chips.get(id, id)), "line": _player_line(id)}
		if id in PICK_MOVES:
			m["picks"] = _picks(id)
		out.append(m)
	return out


## Make a move (with a pick for show_data, propose_experiment and propose).
## Returns {move, line, reply, tags, arrow (2 ▲▲, 1 ▲, 0, -1 ▼, -2 ▼▼: what
## the player sees), delta (for the rules and tests; never shown), openness,
## trust, band, heard, cue,
## revealed (a layer id or ""), unlocked ({clue?, facts?, proposals?}),
## co_proposal ({} or {id, text}), patience_low, ended, outcome, outcome_line},
## or {error: ended | unknown_move | bad_pick}, and then nothing changes.
func say(move: String, pick: String = "") -> Dictionary:
	if not outcome.is_empty():
		return {"error": "ended"}
	if not move in MOVES:
		return {"error": "unknown_move"}
	if (move in PICK_MOVES and not _picks(move).any(func(p: Dictionary) -> bool: return p["id"] == pick)) \
			or (not move in PICK_MOVES and not pick.is_empty()):
		return {"error": "bad_pick"}
	var before := openness
	var at_lead_in := _lead_in_said and not revealed.has("concern")
	var effect := _effect(move, pick)
	var delta: int = effect["delta"]
	var reply: Dictionary = effect["reply"]
	var lands: bool = effect["lands"]
	_streak = _streak + 1 if move == _last_move and move != "ask_commitment" else 1
	var worn := false
	if _streak == 2 and delta > 0:
		delta = roundi(delta * REPEAT_FACTOR)
	elif _streak >= 3:
		delta = REPEAT_THIRD
		reply = _shared(bank["special"]["repeat"])
		lands = false
		worn = true
	elif lands and move in LISTEN:
		var factor: float = USE_DECAY[mini(int(_uses.get(move, 0)), USE_DECAY.size() - 1)]
		delta = maxi(1, roundi(delta * factor))
		worn = factor < REPEAT_FACTOR
	if worn and move in LISTEN and move != "silence" and not _worn.has(move):
		_worn[move] = true
		reply = _wear_line(move)
	_uses[move] = int(_uses.get(move, 0)) + 1
	steered_early = steered_early or (move in STEER and not revealed.has("concern"))
	openness = clampi(openness + delta, RUINED_BELOW if def.tutorial else 0, 100)
	outcome = effect["outcome"]
	var shown := ""
	var unlocked := {}
	var lead_in_now := false
	if outcome.is_empty():
		var layer := _next_layer()
		if lands and not layer.is_empty() and openness >= int(layer["at"]) and move in layer["via"] \
				and (not layer.has("lead_in") or _lead_in_said):
			revealed[layer["id"]] = true
			shown = layer["id"]
			concern_by = move if shown == "concern" else concern_by
			unlocked = JsonFile.dict_or_empty(layer.get("unlocks")).duplicate(true)
			reply = _told(layer, shown)
		elif at_lead_in:
			_lead_in_said = false  # only a fitting move draws the concern out; the moment passes
		elif lands and move in LISTEN and layer.has("lead_in") and openness >= CUE_AT:
			_lead_in_said = true
			lead_in_now = true
			reply = _told(layer["lead_in"], layer["id"] + ".lead_in")
		var next := _next_layer()
		if not next.is_empty():
			openness = mini(openness, maxi(int(next["at"]) + CEILING, before))
		if openness < RUINED_BELOW:
			outcome = "ruined"
		elif band_of(openness) == 0 and band_of(before) > 0 and not _warned and not def.warning.is_empty():
			_warned = true
			reply = _line(def.warning)
	if outcome.is_empty():
		patience -= 1
		if patience <= 0:
			outcome = _close_outcome()
	if outcome in ["ruined", "commitment", "compliance"] or move == "close":
		reply = _line(_outcome_text(outcome))
	var co := {}
	if outcome.is_empty() and not _co_offered and not def.co_proposal.is_empty() and revealed.has("concern") \
			and shown != "concern" and openness >= BANDS[4]:
		_co_offered = true
		co = {"id": def.co_proposal["id"], "text": def.co_proposal.get("text", "")}
	_last_move = move
	if not reply.get("shared", false):
		_last_tags = reply["tags"]
	elif lands:
		_last_tags = _last_tags.filter(func(tag: String) -> bool: return not tag in ANSWERS.get(move, []))
	moves_made += 1
	made.append(move)
	_note(reply, not shown.is_empty())
	trace.append(openness)
	return {
		"move": move, "line": _player_line(move, pick), "reply": reply["text"], "tags": reply["tags"],
		"delta": openness - before, "arrow": arrow_of(openness - before), "openness": openness, "trust": trust, "band": band_of(openness), "heard": heard,
		"cue": outcome.is_empty() and openness >= CUE_AT and not revealed.has("concern")
			and (lead_in_now or "hesitation" in reply["tags"]),
		"revealed": shown, "unlocked": unlocked, "co_proposal": co,
		"patience_low": outcome.is_empty() and patience == PATIENCE_WARNING,
		"ended": not outcome.is_empty(), "outcome": outcome,
		"outcome_line": _outcome_text(outcome) if not outcome.is_empty() else "",
	}


## The talk as it stands, as a separate talk (the route check plays ahead on
## copies; test_dialog_routes.gd checks that every variable is copied).
func copy() -> Dialog:
	var c := Dialog.new(def, who, bank, {})
	for key: String in COPIED:
		var v: Variant = get(key)
		c.set(key, v.duplicate() if v is Dictionary or v is Array else v)
	return c


## Two talks of the same dialog with the same key play on alike from here.
func state_key() -> String:
	var parts := []
	for i in STATE_KEYS:
		var v: Variant = get(COPIED[i])
		if v is Dictionary:
			var keys: Array = v.keys()
			keys.sort()
			v = keys.map(func(k: Variant) -> String: return "%s=%s" % [k, v[k]])
		parts.append(v)
	return str(parts)


## {openness, band (0–4, -1 below the first), band_label, trust, trust_pips, mood, trace}
func meter() -> Dictionary:
	var band := band_of(openness)
	return {"openness": openness, "band": band, "band_label": str(bank["labels"]["bands"][band]) if band >= 0 else "",
		"trust": trust, "trust_pips": floori(trust / float(TRUST_PER_PIP)), "mood": mood, "trace": trace.duplicate()}


## Why a bank of lines (dialogs.json `bank`) would break a talk; "" when it is
## whole. tools/build_content.py checks every line; this checks what the
## rules index without a fallback.
static func bank_error(lines: Dictionary) -> String:
	var labels := JsonFile.dict_or_empty(lines.get("labels"))
	if not (labels.get("bands") is Array and labels["bands"].size() == BANDS.size()):
		return "dialog bank: labels.bands names the %d openness bands" % BANDS.size()
	for section: Array in [["player", MOVES], ["outcomes", OUTCOMES],
			["special", ["repeat", "refusal", "no_proposal", "other_data", "lucky_guess", "no_repair"]]]:
		var lines_of := JsonFile.dict_or_empty(lines.get(section[0]))
		for key: String in section[1]:
			if not lines_of.get(key) is String:
				return "dialog bank: %s.%s is missing" % [section[0], key]
	return ""


## The arrow a change shows: ±2 from ARROW_BIG, ±1 below, 0 for none.
static func arrow_of(change: int) -> int:
	return signi(change) * (2 if absi(change) >= ARROW_BIG else 1)


static func band_of(value: int) -> int:
	for i in range(BANDS.size() - 1, -1, -1):
		if value >= BANDS[i]:
			return i
	return -1


## Their own idea won: the co-proposal they offered was on the table.
func own_idea() -> bool:
	return _co_offered and table == str(def.co_proposal.get("id", ""))


## The facts the revealed layers unlocked (heard:<id>).
func unlocked_facts() -> Array:
	return _unlocked("facts")


## What the revealed layers unlocked under `key` (facts or proposals), in order.
func _unlocked(key: String) -> Array:
	var out := []
	for layer: Dictionary in layers():
		if revealed.has(layer["id"]):
			out.append_array(JsonFile.dict_or_empty(layer.get("unlocks")).get(key, []))
	return out


## The clue the revealed concern unlocked ("" for none).
func unlocked_clue() -> String:
	var concern: Dictionary = layers()[1]
	return str(JsonFile.dict_or_empty(concern.get("unlocks")).get("clue", "")) if revealed.has("concern") else ""


## After an agreement under condition: what still has to happen, as the
## content says it (the concern's `wait_for`); "" when it names nothing.
func wait_for() -> String:
	if outcome != "partial" or not revealed.has("concern"):
		return ""
	return str(layers()[1].get("wait_for", ""))


## The minutes the talk took.
func minutes() -> int:
	return moves_made * MINUTES_PER_MOVE


# ── Moves ───────────────────────────────────────────────────────────────────

## {delta, reply {text, tags}, lands, outcome ("" while it runs)}
func _effect(move: String, pick: String) -> Dictionary:
	match move:
		"close":
			return _result(0, {}, false, _close_outcome())
		"pressure":
			pressured = true
			return _pressure(move, PRESSURE)
		"confront":
			confronted = true
			return _pressure(move, CONFRONT)
		"repair":
			if not _retry or _repaired:
				return _result(0, _shared(bank["special"]["no_repair"]), false)
			_repaired = true
			return _pressure(move, REPAIR)
		"ask_commitment":
			return _ask()
	if move in LISTEN:
		return _listen(move)
	return _steer(move, pick)


func _pressure(move: String, change: Dictionary) -> Dictionary:
	trust = clampi(trust + change["trust"], 0, 100)
	return _result(change["openness"], _reply(move, "lands"), change["openness"] > 0)


func _listen(move: String) -> Dictionary:
	var lands := false
	match move:
		"mood":
			lands = moves_made < EARLY_MOVES or (mood in HARD_DAY_MOODS and not _mood_asked)
			_mood_asked = true
		"open_question":
			lands = int(_uses.get(move, 0)) < OPEN_QUESTIONS_THAT_LAND
		"paraphrase":
			lands = "claim" in _last_tags
		"reflect":
			lands = "feeling" in _last_tags
		"empathy":
			lands = moves_made < EARLY_MOVES or _follows(EMPATHY_AFTER)
		"inquiry":
			var layer := _next_layer()
			lands = not layer.is_empty() and openness >= int(layer["at"]) - INQUIRY_REACH \
				and _follows(INQUIRY_AFTER)
		"experience":
			lands = heard and trust >= EXPERIENCE_TRUST and _follows(["doubt", "admission"])
		"silence":
			lands = "hesitation" in _last_tags
	if not lands:
		var misread: Array = MISREAD.get(move, ["", 0])
		return _result(misread[1] if misread[0] in _last_tags else MISSES[move], _reply(move, "misses"), false)
	if move in ["paraphrase", "reflect"]:
		heard = true
	var delta: int = EMPATHY_AFTER_ADMISSION if move == "empathy" and "admission" in _last_tags else LANDS[move]
	return _result(_weighted(move, delta), _reply(move, "lands"), true)


func _steer(move: String, pick: String) -> Dictionary:
	if move in ["propose", "propose_experiment"]:
		table = pick
	if _too_early():
		return _result(TOO_EARLY, _reply(move, "too_early"), false)
	match move:
		"perspective":
			return _graded(move, PERSPECTIVE, _reply(move, "lands"))
		"show_data":
			if not pick in def.data:
				return _result(0, _shared(bank["special"]["other_data"]), false)
			return _graded(move, SHOW_DATA, _reply(move, "lands"))
		"propose_experiment":
			var reply: String = def.item(pick).get("reply", "")
			return _graded(move, EXPERIMENT, _line(reply) if not reply.is_empty() else _reply(move, "lands"))
	var proposal := def.item(pick)
	var addresses: Array = proposal.get("addresses", [])
	if addresses.any(func(layer: String) -> bool: return revealed.has(layer)):
		return _result(PROPOSAL_ADDRESSES, _line(proposal.get("reply", "")), true)
	if "concern" in addresses:
		return _result(LUCKY_GUESS, _shared(bank["special"]["lucky_guess"]), true)
	return _result(0, _line(proposal.get("reply", "")), false)


## A steering move that lands from `rule.at` on, weighted by the archetype.
func _graded(move: String, rule: Dictionary, landed_reply: Dictionary) -> Dictionary:
	if openness >= int(rule["at"]):
		return _result(_weighted(move, rule["lands"]), landed_reply, true)
	return _result(rule["misses"], _reply(move, "misses"), false)


## Asking for agreement decides the outcome (spec §4.1).
func _ask() -> Dictionary:
	var concern := revealed.has("concern")
	if def.kind == "checkin":
		if not concern:
			return _result(TOO_EARLY, _reply("ask_commitment", "too_early"), false)
		return _result(0, _shared(bank["special"]["no_proposal"]), false)
	if not def.block.is_empty() and concern and not _route_met():
		return _result(0, _line(def.block.get("text", "")), false, "blocked")
	if table.is_empty():
		return _result(0, _shared(bank["special"]["no_proposal"]), false)
	if pressured and openness >= RUINED_BELOW:
		return _result(0, {}, false, "compliance")
	var condition: String = layers()[1].get("condition", "") if concern else ""
	var partial := _line(condition if not condition.is_empty() else _outcome_text("partial"))
	if openness >= COMMIT_AT and concern and "concern" in def.item(table).get("addresses", []):
		if DialogDef.needs_met(def.condition_needs, _facts):
			return _result(0, {}, false, "commitment")
		return _result(0, partial, false, "partial")
	if openness >= PARTIAL_AT:
		return _result(0, partial, false, "partial")
	return _result(REFUSAL, _shared(bank["special"]["refusal"]), false)


func _route_met() -> bool:
	return def.block.get("routes", []).any(func(r: Dictionary) -> bool:
		return DialogDef.needs_met(JsonFile.dict_or_empty(r.get("needs")), _facts))


func _too_early() -> bool:
	var needs_concern := def.kind == "checkin" or who.archetype == "customer_upset"
	return not heard or openness < STEER_FROM or (needs_concern and not revealed.has("concern"))


func _close_outcome() -> String:
	if def.kind == "checkin" and revealed.has("concern") and openness >= LIFTED_AT:
		return "lifted"
	return "heard" if openness >= HEARD_AT or openness - start_openness >= HEARD_GAIN else "none"


## Whether the person's last words carry any of `tags`.
func _follows(tags: Array) -> bool:
	return tags.any(func(tag: String) -> bool: return tag in _last_tags)


func _weighted(move: String, delta: int) -> int:
	return roundi(delta * weight(who.archetype, need(), mood, move, heard))


## How hard a landing move lands for this archetype, need and mood (archetype ×
## need, clamped to WEIGHT_MIN–WEIGHT_MAX).
static func weight(archetype: String, person_need: String, today: String, move: String, was_heard: bool) -> float:
	var by_need: float = NEED_WEIGHTS.get(move, {}).get(person_need, 1.0)
	if person_need == "safety" and move == "inquiry" and was_heard:
		by_need = SAFETY_INQUIRY_HEARD
	by_need = 1.0 + (by_need - 1.0) * float(NEED_MOOD_K.get(today, 1.0))
	return clampf(float(WEIGHTS.get(archetype, {}).get(move, 1.0)) * by_need, WEIGHT_MIN, WEIGHT_MAX)


## The person's need in this talk: the dialog's own for one scene, else theirs.
func need() -> String:
	return def.need if not def.need.is_empty() else who.need


## The person's line when a move wears out: the dialog's own, else the archetype's.
func _wear_line(move: String) -> Dictionary:
	var own := JsonFile.dict_or_empty(JsonFile.dict_or_empty(def.replies.get(move)).get("worn"))
	if not own.is_empty():
		return _told(own, "replies.%s.worn" % move)
	var lines := JsonFile.dict_or_empty(JsonFile.dict_or_empty(bank.get("wear_out")).get(who.archetype))
	var text := str(lines.get("ask" if move in WEAR_ASK else "say", ""))
	return _shared(text if not text.is_empty() else bank["special"]["repeat"])


# ── Lines ───────────────────────────────────────────────────────────────────

func _result(delta: int, reply: Dictionary, lands: bool, ended: String = "") -> Dictionary:
	return {"delta": delta, "reply": reply if not reply.is_empty() else _shared(""), "lands": lands, "outcome": ended}


## An untagged line from the shared bank: the person's own last words still
## stand (E2: moves answer the last authored line; the bank carries no claim
## or feeling, tier-1 content audit C8).
func _shared(text: String) -> Dictionary:
	return {"text": text, "tags": [], "shared": true}


func _line(text: String, tags: Array = []) -> Dictionary:
	return {"text": text, "tags": tags.duplicate()}


## A line of this dialog's own content ({text, tags?, tell?}), with where it
## stands (`key`: position, a layer id, <layer>.lead_in, replies.<move>.<case>).
func _told(line: Dictionary, key: String) -> Dictionary:
	var out := _line(str(line.get("text", "")), line.get("tags", []))
	out["key"] = key
	out["tell"] = str(line.get("tell", ""))
	return out


## Keep what the person said for the Mensen tab: always (`always`: the
## position, a layer), else when it shows their need.
func _note(reply: Dictionary, always: bool = false) -> void:
	if reply.has("key") and (always or not str(reply.get("tell", "")).is_empty()) \
			and not str(reply["text"]).is_empty():
		told.append({"key": reply["key"], "text": reply["text"]})


## The person's reply to a move: the dialog's own, the bank's, or (too early)
## the position, repeated defensively.
func _reply(move: String, situation: String) -> Dictionary:
	for source: Dictionary in [def.replies, bank.get("replies", {})]:
		var line: Dictionary = JsonFile.dict_or_empty(JsonFile.dict_or_empty(source.get(move)).get(situation))
		if not line.is_empty():
			var tags: Array = line.get("tags", [])
			if source == def.replies:
				return _told(line, "replies.%s.%s" % [move, situation])
			return _line(str(line.get("text", "")), tags) if not tags.is_empty() \
				else _shared(str(line.get("text", "")))
	return _told(position(), "position") if situation == "too_early" else _shared("")


func _player_line(move: String, pick: String = "") -> String:
	if move in ["propose", "propose_experiment"] and not pick.is_empty():
		return str(def.item(pick).get("text", ""))
	return str(def.lines.get(move, bank["player"].get(move, "")))


func _outcome_text(o: String) -> String:
	return str(def.outcomes.get(o, bank["outcomes"].get(o, "")))


func _row(move: String) -> String:
	if move in LISTEN:
		return "listen"
	if move in STEER:
		return "steer"
	return "pressure" if move in ["pressure", "confront"] else "other"


func _picks(move: String) -> Array:
	match move:
		"show_data":
			var ids := _found.keys()
			ids.sort()
			return ids.map(func(id: String) -> Dictionary: return {"id": id})
		"propose_experiment":
			return def.experiments.map(_pick)
	var unlocked := _unlocked("proposals")
	return def.proposals.filter(func(p: Dictionary) -> bool: return not p.get("hidden", false) or p["id"] in unlocked).map(_pick)


func _pick(item: Dictionary) -> Dictionary:
	return {"id": item["id"], "name": item.get("name", ""), "text": item.get("text", "")}


func _next_layer() -> Dictionary:
	for layer: Dictionary in layers():
		if not revealed.has(layer["id"]):
			return layer
	return {}
