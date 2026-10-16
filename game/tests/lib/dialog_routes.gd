class_name DialogRoutes
## The route check (four-tier audit §4.4 and §7, T6): does one *fixed*
## sequence of moves win many persuasion talks? A player who learns one route
## that wins every talk plays by rote, the biggest quit risk. Played on the
## real rules (Dialog), never on a copy of them.
##
## A route is a sequence of tokens: the eight listening moves, perspective,
## and the steering moves resolved per talk the way a good player would:
## show_data shows a clue this person cares about, propose_experiment and
## propose put forward one that meets the concern, ask_commitment asks.
## Pressure, blame, repair and close never win a commitment and are left out.
## A talk is won when it ends in commitment; the facts outside the talk (a
## block's route, the condition) are given, so only the moves decide.
##
## The search: a talk can take 13^10 routes, too many to try one by one (one
## talk alone reaches over 200,000 different states by its sixth move). So it
## is a beam search over all talks at once: each step tries every token after
## each of the `width` most promising routes so far (most talks won, then most
## progress: layers out, the lead-in heard, a fitting proposal on the table,
## openness), merging routes that leave every talk in the same state. It finds
## the strong routes a player would learn; it cannot prove that no better one
## exists, so its numbers are "the best route found".

const TOKENS := ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry", "experience", "silence",
	"perspective", "show_data", "propose_experiment", "propose", "ask_commitment"]
## A clue nobody cares about, so show_data can always be played.
const OTHER_CLUE := "route_check:0"
## Routes kept after each step (an estimate; PLAN 1.6c records the widths tried).
const WIDTH := 300
## The most a single move can raise openness (the largest landing Δ, 12, at the
## largest weight, 2.0): a bound used to drop talks that can no longer be won.
const MAX_GAIN := 24


## A talk ready to play: `openness` at the start (People's rule for content,
## the script's own number for a draft); facts meet its condition and one route
## of its block.
static func start(d: DialogDef, who: PersonDef, bank: Dictionary, openness: int) -> Dialog:
	var found := {OTHER_CLUE: true}
	for clue in d.data:
		found[clue] = true
	var facts := {}
	var exprs := [d.condition_needs]
	if not d.block.is_empty():
		exprs.append(JsonFile.dict_or_empty(d.block["routes"][0].get("needs")))
	for expr: Dictionary in exprs:
		for atom in expr.get("all", []) + expr.get("any", []).slice(0, 1):
			facts[atom] = true
	return Dialog.new(d, who, bank, {"openness": openness, "trust": who.trust,
		"mood": d.mood if not d.mood.is_empty() else "neutraal", "found": found, "facts": facts})


## The best fixed route found over `talks`: {wins, route, won (the ids of the
## talks it wins), winners (every route found that won a talk with its last
## move, at most one per state)}.
static func best_route(talks: Array, width: int = WIDTH) -> Dictionary:
	var beam := [{"talks": talks.map(func(t: Dialog) -> Dialog: return t.copy()), "route": [], "won": 0}]
	var best := {"wins": 0, "route": [], "winners": []}
	var depth := 0
	for t: Dialog in talks:
		depth = maxi(depth, t.patience)
	for step in depth:
		var next := {}
		for node: Dictionary in beam:
			for token: String in TOKENS:
				var after := _step(node, token)
				if after["won"] > node["won"]:
					best["winners"].append(after["route"])
				if after["won"] > best["wins"]:
					best["wins"] = after["won"]
					best["route"] = after["route"]
				var key := ",".join(after["talks"].map(_key))
				if not next.has(key):
					next[key] = after
		beam = next.values().filter(func(n: Dictionary) -> bool: return n["talks"].any(winnable))
		beam.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _score(a) > _score(b))
		beam = beam.slice(0, width)
		if beam.is_empty():
			break
	best["won"] = talks.filter(func(t: Dialog) -> bool: return wins(t, best["route"])).map(
		func(t: Dialog) -> String: return t.def.id)
	return best


## Whether `route` wins `talk` (played on a copy).
static func wins(talk: Dialog, route: Array) -> bool:
	var t := talk.copy()
	for token: String in route:
		if not t.outcome.is_empty():
			break
		t.say(token, pick(t, token))
	return t.outcome == "commitment"


## The pick a good player makes for a steering token ("" for none).
static func pick(talk: Dialog, token: String) -> String:
	match token:
		"show_data":
			return talk.def.data[0] if not talk.def.data.is_empty() else OTHER_CLUE
		"propose", "propose_experiment":
			var picks: Array = []
			for m: Dictionary in talk.moves():
				if m["id"] == token:
					picks = m["picks"]
			for p: Dictionary in picks:
				if "concern" in talk.def.item(p["id"]).get("addresses", []):
					return p["id"]
			return picks[0]["id"] if not picks.is_empty() else ""
	return ""


## False when the talk certainly cannot reach commitment in the moves left:
## every layer still hidden, the lead-in, a proposal that meets the concern
## and the ask each take a move, and openness rises at most MAX_GAIN a move.
static func winnable(talk: Dialog) -> bool:
	if not talk.outcome.is_empty():
		return false
	var needed := 1
	if not talk.revealed.has("interest"):
		needed += 1
	if not talk.revealed.has("concern"):
		needed += 2 if not talk._lead_in_said else 1
	if not "concern" in talk.def.item(talk.table).get("addresses", []):
		needed += 1
	var rise := ceili(maxi(Dialog.COMMIT_AT - talk.openness, 0) / float(MAX_GAIN)) + 1
	return maxi(needed, rise) <= talk.patience


static func _step(node: Dictionary, token: String) -> Dictionary:
	var won: int = node["won"]
	var after := []
	for t: Dialog in node["talks"]:
		if not winnable(t):
			after.append(t)
			continue
		var c := t.copy()
		if c.say(token, pick(c, token)).has("error"):
			c.outcome = "none"  # a move this talk does not offer (no experiment): the route does not fit
		elif c.outcome == "commitment":
			won += 1
		after.append(c)
	return {"talks": after, "route": node["route"] + [token], "won": won}


static func _key(t: Dialog) -> String:
	return t.state_key() if winnable(t) else t.outcome


static func _score(node: Dictionary) -> float:
	var s: float = node["won"] * 100.0
	for t: Dialog in node["talks"]:
		if winnable(t):
			s += (1.0 if t.revealed.has("interest") else 0.0) + (1.0 if t._lead_in_said else 0.0) \
				+ (2.0 if t.revealed.has("concern") else 0.0) + t.openness / 50.0 \
				+ (1.0 if "concern" in t.def.item(t.table).get("addresses", []) else 0.0)
	return s
