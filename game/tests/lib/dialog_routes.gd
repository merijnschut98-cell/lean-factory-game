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
## A token plays only when the turn offers it (Dialog.offer, PLAN 2.13 B: the
## player chooses among four sentences), with the offered pick a good player
## takes; a route whose token is not on offer does not fit that talk.
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

## A talk's offers this turn, by the talk (instance id): the search tries every
## token on the same talks, so each turn is dealt once (cleared every step).
static var _dealt: Dictionary = {}


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


## Every persuasion talk in content, at the start People gives it on a first
## meeting (no team trust, no memory).
static func content_talks(c: Catalog) -> Array[Dialog]:
	var people := People.new(c.persons, c.dialogs, c.dialog_bank)
	var out: Array[Dialog] = []
	for d: DialogDef in c.dialogs:
		if d.kind == "persuade":
			var first := people.start(d, {"main": [d.mission], "active": [d.mission], "found": {}, "facts": {},
				"team_trust": 0, "blamed": false, "now": 0})
			out.append(start(d, people.persons[d.person], c.dialog_bank, first.openness))
	return out


## Tier 1 as the route test measures it: the Acts 0–II scripts' persuasion
## talks (tests/data/tier1_scripts.json), each from content once it is there.
## The Act 0 week's own tutorial talks are not among them.
static func tier1_talks(c: Catalog) -> Array[Dialog]:
	var scripts: Dictionary = JsonFile.read_dict("res://tests/data/tier1_scripts.json")["data"]
	var ids: Array = scripts["dialogs"].map(func(d: Dictionary) -> String: return d["id"])
	var out := content_talks(c).filter(func(t: Dialog) -> bool: return t.def.id in ids)
	out.append_array(draft_talks(scripts, c.dialog_bank, out.map(func(t: Dialog) -> String: return t.def.id)))
	return out


## The talks of a draft collected by tools/dialog_drafts.py ({people, dialogs},
## each dialog with its `start`), leaving out the ids in `skip`.
static func draft_talks(data: Dictionary, bank: Dictionary, skip: Array = []) -> Array[Dialog]:
	var persons := {}
	for p: Dictionary in data["people"]:
		persons[p["id"]] = PersonDef.from_dict(p.merged({"place": "draft"}))
	var out: Array[Dialog] = []
	for d: Dictionary in data["dialogs"]:
		var def := DialogDef.from_dict(d)
		if not def.error.is_empty():
			push_error(def.error)
		elif not def.id in skip:
			out.append(start(def, persons[def.person], bank, int(d["start"])))
	return out


## The routes of `routes` that differ from every one kept before in two
## positions or more (T7: different ways to win, not one with a detour).
static func distinct(routes: Array) -> Array:
	var kept := []
	for r: Array in routes:
		if kept.all(func(o: Array) -> bool: return _differ(o, r) >= 2):
			kept.append(r)
	return kept


## The best fixed route found over `talks`: {wins, route, won (the ids of the
## talks it wins), winners (every route found that won a talk with its last
## move, at most one per state)}. `without`: tokens no route may use.
## `every_winner` false: stop once a route wins every talk; wins, route and won
## are the same (the best route only changes on more wins), winners is partial.
## `offered` false: every token on the whole palette, offered or not (what
## the content holds, whatever a turn deals; T7 and the Act 0 week's rule).
static func best_route(talks: Array, width: int = WIDTH, without: Array = [], every_winner := true,
		offered := true) -> Dictionary:
	var tokens := TOKENS.filter(func(t: String) -> bool: return not t in without)
	var beam := [{"talks": talks.map(func(t: Dialog) -> Dialog: return t.copy()), "route": [], "won": 0}]
	var best := {"wins": 0, "route": [], "winners": []}
	var depth := 0
	for t: Dialog in talks:
		depth = maxi(depth, t.patience)
	for step in depth:
		_dealt.clear()
		var next := {}
		for node: Dictionary in beam:
			for token: String in tokens:
				var after := _step(node, token, offered)
				if after["won"] > node["won"]:
					best["winners"].append(after["route"])
				if after["won"] > best["wins"]:
					best["wins"] = after["won"]
					best["route"] = after["route"]
					if not every_winner and best["wins"] == talks.size():
						return _with_won(best, talks, offered)
				var key := ",".join(after["talks"].map(_key))
				if not next.has(key):
					next[key] = after
		beam = next.values().filter(func(n: Dictionary) -> bool: return n["talks"].any(winnable))
		for n: Dictionary in beam:  # scored once, not on every comparison of the sort
			n["score"] = _score(n)
		beam.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		beam = beam.slice(0, width)
		if beam.is_empty():
			break
	_dealt.clear()
	return _with_won(best, talks, offered)


static func _with_won(best: Dictionary, talks: Array, offered: bool) -> Dictionary:
	best["won"] = talks.filter(func(t: Dialog) -> bool: return wins(t, best["route"], offered)).map(
		func(t: Dialog) -> String: return t.def.id)
	return best


## Whether `route` wins `talk` (played on a copy, through its offers, or
## with `offered` false on the whole palette).
static func wins(talk: Dialog, route: Array, offered := true) -> bool:
	var t := talk.copy()
	for token: String in route:
		if not t.outcome.is_empty() or not _play(t, token, t.offer() if offered else null):
			break
	return t.outcome == "commitment"


## The talks of `talks` won by always choosing the offer at `position` (the
## last one when fewer are offered): no button may be the right one.
static func position_wins(talks: Array, position: int) -> Array[String]:
	var out: Array[String] = []
	for talk: Dialog in talks:
		var t := talk.copy()
		while t.outcome.is_empty():
			var offers := t.offer()
			var o: Dictionary = offers[mini(position, offers.size() - 1)]
			t.say(o["move"], o["pick"])
		if t.outcome == "commitment":
			out.append(t.def.id)
	return out


## The listening move for a person's last words (the autoplay talker's, QA 2.12 (e)).
const ANSWER := {"feeling": "reflect", "admission": "empathy", "hesitation": "silence", "claim": "paraphrase",
	"doubt": "experience"}
const FALLBACK_LISTEN: Array[String] = ["open_question", "inquiry", "empathy", "paraphrase", "mood"]


## A persuasion played by a listen-first player through the turns' offers, as the
## autoplay talker plays it (game/tools/autoplay.gd, _talker_move): ask the mood, answer
## the person's last words with the move that fits them, show the data once when they
## feel heard, put a proposal that meets the concern on the table only once the concern
## is out and the meter reads commitment (or time runs short), then ask. Never presses.
## Returns the played copy.
static func listen_first(talk: Dialog) -> Dialog:
	var t := talk.copy()
	var tags: Array = t.position().get("tags", [])
	var last := {}
	var uses := {}
	var proposed := false
	var shown_data := false
	while t.outcome.is_empty():
		var want := ["", ""]
		var concern := t.revealed.has("concern")
		if proposed:
			want = ["ask_commitment", ""]
		elif (concern and t.openness >= Dialog.COMMIT_AT) or last.get("patience_low", false):
			want = ["propose", pick(t, "propose")]
		elif last.get("heard", false) and not shown_data and t.openness >= Dialog.SHOW_DATA["at"] \
				and not t.def.data.is_empty():
			want = ["show_data", t.def.data[0]]
		var order := _listen_order(tags, uses, str(last.get("move", "")))
		var choice := _offered(t.offer(), want, order)
		last = t.say(choice[0], choice[1])
		uses[choice[0]] = int(uses.get(choice[0], 0)) + 1
		proposed = choice[0] in ["propose", "propose_experiment"]
		shown_data = shown_data or choice[0] == "show_data"
		tags = last.get("tags", [])
	return t


## The listening moves in the order a listen-first player makes them now.
static func _listen_order(tags: Array, uses: Dictionary, last_move: String) -> Array:
	var order: Array = ["mood"] if uses.is_empty() else []
	for tag: Variant in tags:
		if ANSWER.has(tag):
			order.append(ANSWER[tag])
	order.append_array(FALLBACK_LISTEN)
	order = order.filter(func(m: String) -> bool: return m != last_move and int(uses.get(m, 0)) < Dialog.USE_DECAY.size())
	order.append("silence" if last_move != "silence" else "empathy")
	return order


## Among `offers`: the wanted move (a proposal with any offered pick, the one meeting
## the concern first), else the first offered listening move in `order`, else the
## first offer that is no pressure or blame.
static func _offered(offers: Array, want: Array, order: Array) -> Array:
	for exact: bool in [true, false]:
		for o: Dictionary in offers:
			if o["move"] == want[0] and (o["pick"] == want[1] or (not exact and want[0] == "propose")):
				return [o["move"], o["pick"]]
	for move: String in order:
		for o: Dictionary in offers:
			if o["move"] == move:
				return [move, ""]
	for o: Dictionary in offers:
		if not o["move"] in ["pressure", "confront"]:
			return [o["move"], o["pick"]]
	return ["close", ""]


## Play `token` in `talk`: the option of `offers` (this turn's) that plays
## it, or with `offers` null the move itself; false, and nothing played,
## when it is not on offer or the talk refuses it.
static func _play(talk: Dialog, token: String, offers: Variant) -> bool:
	if offers == null:
		return not talk.say(token, pick(talk, token)).has("error")
	var o := _option(talk, offers, token)
	if o.is_empty():
		return false
	talk.say(o["move"], o["pick"])
	return true


## The option of `offers` (`talk`'s this turn) that plays `token`, with the
## pick a good player takes among the offered ones; {} when it is not on offer.
static func _option(talk: Dialog, offers: Array, token: String) -> Dictionary:
	var best := pick(talk, token)
	var chosen := {}
	for o: Dictionary in offers:
		if o["move"] == token and (chosen.is_empty() or o["pick"] == best):
			chosen = o
	return chosen


## `talk`'s offers this turn, dealt once per step of the search (_dealt).
static func _offers(talk: Dialog) -> Array:
	var id := talk.get_instance_id()
	if not _dealt.has(id):
		_dealt[id] = talk.offer()
	return _dealt[id]


## The pick a good player makes for a steering token ("" for none).
static func pick(talk: Dialog, token: String) -> String:
	match token:
		"show_data":
			return talk.def.data[0] if not talk.def.data.is_empty() else OTHER_CLUE
		"propose", "propose_experiment":
			# The picks moves() offers, without building the whole palette (hot in the search).
			var picks: Array = talk._picks(token)
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


static func _step(node: Dictionary, token: String, offered: bool) -> Dictionary:
	var won: int = node["won"]
	var after := []
	for t: Dialog in node["talks"]:
		if not winnable(t):
			after.append(t)
			continue
		var c := t.copy()
		if not _play(c, token, _offers(t) if offered else null):
			c.outcome = "none"  # not on offer this turn (or no experiment here): the route does not fit
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


static func _differ(a: Array, b: Array) -> int:
	var n := absi(a.size() - b.size())
	for i in mini(a.size(), b.size()):
		n += 1 if a[i] != b[i] else 0
	return n
