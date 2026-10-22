class_name ExpertTalk
extends RefCounted
## An expert talk in progress (phase 2 design §2.5; PLAN §4.3 "seven dialog
## shapes"): Wim on his meter data, Henk on cables and joints. Topic by
## topic, with no meters and nothing won or lost: the player picks a question
## (at most OFFERED, in the content's order), the expert answers in their own
## voice. A topic can unlock a clue (the first time only: one already found is
## not new), a fact, or a "Hoe werkt het?" explainer, and can wait for a fact
## (`needs`) or for trust (`trust`). Being asked about your craft is a little
## recognition: each answered topic adds TRUST_PER_TOPIC. Deterministic, no
## nodes: People builds it and keeps what it asked afterwards.

const KIND := "expert"
## The player's moves: a question (pick: the topic id), or rounding off.
const ASK := "ask"
const CLOSE := "close"
## Questions offered at once (as a persuasion's sentences, Dialog.OFFERED).
const OFFERED := 4
## Trust per answered topic (an ESTIMATE: a small, steady gain, under a
## heard persuasion's +3, so it never replaces listening in a hard talk).
const TRUST_PER_TOPIC := 1
## In-game minutes an answer takes (an ESTIMATE: an expert explaining takes
## longer than a move in a persuasion, Dialog.MINUTES_PER_MOVE).
const MINUTES_PER_TOPIC := 5
## The body of an expert who is glad to explain (Dialog.BANDS: "Open").
const BAND := 3

var def: DialogDef
var who: PersonDef
var trust: int
## Topic ids asked, in order: earlier talks' first, then this one's.
var asked: Array[String] = []
## Topic ids asked in this talk.
var asked_now: Array[String] = []
var ended := false
var _facts: Dictionary
var _found: Dictionary


## `start`: {trust, asked (earlier talks' topics), facts, found}.
func _init(dialog: DialogDef, person: PersonDef, start: Dictionary) -> void:
	def = dialog
	who = person
	trust = clampi(int(start.get("trust", person.trust)), 0, 100)
	asked.assign(start.get("asked", []))
	_facts = JsonFile.dict_or_empty(start.get("facts"))
	_found = JsonFile.dict_or_empty(start.get("found"))


## The topics the player can ask now: not asked yet, their fact and trust met.
func open_topics() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in def.topics:
		if not t["id"] in asked and is_open(t, _facts, trust):
			out.append(t)
	return out


## Whether a topic's gate holds for `facts` (atom → true) and `trust_now`.
static func is_open(t: Dictionary, facts: Dictionary, trust_now: int) -> bool:
	return trust_now >= int(t.get("trust", 0)) and DialogDef.needs_met(JsonFile.dict_or_empty(t.get("needs")), facts)


## This turn's questions, as a persuasion's offers ([{move, pick, line}]); []
## once the talk has ended.
func offer() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if ended:
		return out
	for t in open_topics().slice(0, OFFERED):
		out.append({"move": ASK, "pick": t["id"], "line": t["ask"]})
	return out


## Ask a topic, or round off: {move, pick, line (the player's), reply (the
## expert's), clue ("" or a clue not found before), explainer ("" or its id),
## facts, trust, ended}. Errors: unknown_move | bad_pick (nothing changes).
func say(move: String, pick: String = "") -> Dictionary:
	if ended or not move in [ASK, CLOSE]:
		return {"error": "unknown_move"}
	if move == CLOSE:
		ended = true
		return _result(move, "", "", def.closing, {})
	var topic := def.topic(pick)
	if topic.is_empty() or not topic in open_topics():
		return {"error": "bad_pick"}
	asked.append(pick)
	asked_now.append(pick)
	trust = mini(100, trust + TRUST_PER_TOPIC)
	return _result(move, pick, topic["ask"], topic["answer"], JsonFile.dict_or_empty(topic.get("unlocks")))


func _result(move: String, pick: String, line: String, reply: String, unlocks: Dictionary) -> Dictionary:
	var clue := str(unlocks.get("clue", ""))
	return {"move": move, "pick": pick, "line": line, "reply": reply,
		"clue": clue if not _found.has(clue) else "", "explainer": str(unlocks.get("explainer", "")),
		"facts": Array(unlocks.get("facts", [])), "trust": trust, "ended": ended}


## The facts this talk's topics unlocked, in order.
func unlocked_facts() -> Array:
	var out := []
	for id in asked_now:
		out.append_array(JsonFile.dict_or_empty(def.topic(id).get("unlocks")).get("facts", []))
	return out


## The meter TalkView shows: trust only (the pips), the body open.
func meter() -> Dictionary:
	return {"trust": trust, "trust_pips": floori(trust / float(Dialog.TRUST_PER_PIP)), "band": BAND, "mood": "neutraal",
		"trace": []}


func minutes() -> int:
	return asked_now.size() * MINUTES_PER_TOPIC
