class_name TalkWalk
## Read talks instead of playing them (Merijn's playtest 2026-10-30;
## docs/qa/dialog-coherence-2026-10-30.md). Walks a talk's branches through the
## real rules (Dialog) and keeps what was said turn by turn, flagged where a line
## cannot be true for what came before it:
##   repeat   the person says the player repeats themselves, and the player did not
##   clarify  the person asks what the player means: no turn lets the player say it
##   empty    the person says nothing
##   question the person asked the player something and the player's sentence is a
##            stock line of the bank (it cannot know the question)
##   farewell the talk ended and the person never said how it landed
##   ruud     Ruud's note after a tutorial talk does not quote a sentence the player said
##   echo     the person says a line they already said in this talk, word for word,
##            to a sentence the player had not said before
##   retold   an echo of a story line said once: a layer, a lead-in, a proposal's reply,
##            their own idea (review 1 of 2026-10-30)
## Two walks: every option a turn could offer under any deal (Dialog._candidates),
## breadth first with states merged, then random talks to the end, for the table of
## every exchange; and a few whole talks as the player sees them (four sentences a
## turn on the route check's deal), chosen by simple players, to read start to end.
## Used by game/tools/talk_transcripts.gd and test_talk_coherence.gd.

## States expanded per talk in the exchange walk (an estimate: the first three
## turns in full, deeper turns sampled breadth first).
const BUDGET := 1500
## Random talks played to the end after it, over every option (an estimate).
const DIVES := 300
## Flags a talk in content may never show (test_talk_coherence.gd); `question`
## is a reading hint, the share of stock replies a measure (score).
const BROKEN := ["repeat", "clarify", "empty", "farewell", "ruud", "retold"]
## Talks read through and rewritten (the reference talks): no echo at all either.
const REVIEWED := ["anouk_seven"]
## How much each flag weighs in the ranking of talks (the worst read first).
const WEIGHT := {"repeat": 3.0, "clarify": 3.0, "empty": 2.0, "farewell": 2.0, "ruud": 2.0, "retold": 2.0,
	"echo": 1.0, "question": 1.0}
## Seeds of the random players.
const RANDOM_PLAYERS := 3


## What the flags read: the patterns of vocabulary.json (tools/build_content.py
## REPEAT_CLAIM, CLARIFY_ASK), every stock text of the bank, the outcome texts.
static func context(c: Catalog) -> Dictionary:
	var vocab := JsonFile.read_dict("res://data/vocabulary.json")
	var coherence := JsonFile.dict_or_empty(JsonFile.dict_or_empty(vocab.get("data")).get("dialog_coherence"))
	var stock := {}
	for move: String in Dialog.MOVES:
		var lines: Variant = JsonFile.dict_or_empty(c.dialog_bank.get("player")).get(move, [])
		for line: Variant in (lines if lines is Array else [lines]):
			stock[str(line)] = true
	return {"repeat": _regex(str(coherence.get("repeat", ""))), "clarify": _regex(str(coherence.get("clarify", ""))),
		"stock": stock, "bank_replies": _bank_replies(c), "people": People.new(c.persons, c.dialogs, c.dialog_bank),
		"catalog": c}


static func _regex(pattern: String) -> RegEx:
	return RegEx.create_from_string("(?i)" + pattern) if not pattern.is_empty() else null


## Every persuasion and check-in in content, at the start People gives it on a
## first meeting (as the route check starts them: its clues found, the facts its
## condition and block need given).
static func talks(c: Catalog, ids: Array = []) -> Array[Dialog]:
	var people := People.new(c.persons, c.dialogs, c.dialog_bank)
	var out: Array[Dialog] = []
	for d: DialogDef in c.dialogs:
		if d.kind == ExpertTalk.KIND or (not ids.is_empty() and not d.id in ids):
			continue
		var first := people.start(d, {"main": Array(d.missions), "active": Array(d.missions), "found": {},
			"facts": {}, "team_trust": 0, "blamed": false, "now": 0})
		out.append(DialogRoutes.start(d, people.persons[d.person], c.dialog_bank, first.openness))
	return out


# ── One turn ────────────────────────────────────────────────────────────────

## A path through a talk so far: the moves and sentences the player said, the
## lines the person said (their position first).
static func path_of(talk: Dialog) -> Dictionary:
	return {"moves": [], "lines": [], "heard": [str(talk.position().get("text", ""))]}


## The path after turn `r`.
static func path_after(path: Dictionary, r: Dictionary) -> Dictionary:
	var more := str(r.get("co_proposal", {}).get("text", ""))
	return {"moves": path["moves"] + [r["move"]], "lines": path["lines"] + [r["line"]],
		"heard": path["heard"] + [str(r["reply"])] + ([more] if not more.is_empty() else [])}


## The turn the player just took in `t` (`r`: its say() result), after the person
## said `before`, on `path` (what was said before it): {before, said, move,
## reply, more (what they said after it: their own idea), arrow, band, flags}.
static func turn(ctx: Dictionary, t: Dialog, before: String, path: Dictionary, r: Dictionary) -> Dictionary:
	var reply := str(r["reply"])
	var flags: Array[String] = []
	var moves: Array = path["moves"]
	# Said before (Dialog._repeats): the same sentence, or a move whose sentences all say the same.
	var again: bool = r["line"] in path["lines"] or (r["move"] in Dialog.SAME_SAYING and r["move"] in moves)
	if _hits(ctx["repeat"], reply) and not again:
		flags.append("repeat")
	if _hits(ctx["clarify"], reply):
		flags.append("clarify")
	if reply.strip_edges().is_empty():
		flags.append("empty")
	if before.strip_edges().ends_with("?") and ctx["stock"].has(r["line"]):
		flags.append("question")
	var more := str(r.get("co_proposal", {}).get("text", ""))
	for line: String in [reply, more]:   # the same answer to the same sentence is no echo
		if not line.strip_edges().is_empty() and line in path["heard"] and not r["line"] in path["lines"]:
			flags.append("retold" if _story(t.def).has(line) else "echo")
	return {"before": before, "said": str(r["line"]), "move": str(r["move"]), "reply": reply, "more": more,
		"farewell": str(r.get("farewell", "")), "arrow": int(r.get("arrow", 0)), "band": int(r.get("band", -1)),
		"openness": int(r.get("openness", 0)), "flags": flags}


## What the person said last after `t`'s turn (`r`): their own idea after their
## reply, else the reply, else what they said before.
static func last_words(before: String, r: Dictionary) -> String:
	var more := str(r.get("co_proposal", {}).get("text", ""))
	if not more.is_empty():
		return more
	return str(r["reply"]) if not str(r["reply"]).strip_edges().is_empty() else before


## How an ended talk `t` closed (`r`: the last say() result): {outcome, reply,
## farewell (their word on how it went after the reply, "" for none), ruud
## (Ruud's note, "" outside Act 0), note (People.talk_note), moves, flags}.
static func ending(ctx: Dictionary, t: Dialog, r: Dictionary) -> Dictionary:
	var flags: Array[String] = []
	var farewell := str(r.get("farewell", ""))
	var closed := farewell.strip_edges() != "" or str(r["reply"]) == str(r["outcome_line"]) \
		or t.outcome in ["partial", "blocked"]
	if not closed:
		flags.append("farewell")
	var people: People = ctx["people"]
	var ruud := people.ruud_names(t)
	var named := people.ruud_named(t)
	if not named.get("move", "none") in ["none", "silence"] and not str(named["said"]) in ruud:
		flags.append("ruud")   # a silence is no sentence: he says the player said nothing
	var result := {"clue": t.unlocked_clue(), "wait_for": t.wait_for(), "ruud_names": ruud,
		"hints": t.def.block.get("routes", []).map(func(x: Dictionary) -> String: return str(x.get("hint", ""))) \
			if t.outcome == "blocked" else []}
	return {"outcome": t.outcome, "reply": str(r["reply"]), "farewell": farewell, "ruud": ruud,
		"note": People.talk_note(t, result), "moves": Array(t.made), "flags": flags}


## The lines a talk tells once (layers, lead-ins, proposal replies, their own idea).
static func _story(d: DialogDef) -> Dictionary:
	var out := {str(d.co_proposal.get("text", "")): true}
	for v in range(-1, d.variants.size()):
		for layer: Dictionary in d.layers_of(v):
			out[str(layer.get("text", ""))] = true
			out[str(JsonFile.dict_or_empty(layer.get("lead_in")).get("text", ""))] = true
	for item: Dictionary in d.proposals + d.experiments:
		out[str(item.get("reply", ""))] = true
	out.erase("")
	return out


static func _hits(re: RegEx, text: String) -> bool:
	return re != null and re.search(text) != null


# ── Every exchange ──────────────────────────────────────────────────────────

## Every exchange `talk` can hold: breadth first over every option a turn could
## offer, states merged, at most `budget` states expanded (the first turns in
## full), then `dives` random talks to the end over the same options (the late
## turns and the endings): {exchanges (key → {before, said, move, replies: {reply
## → flags}}), endings (key → ending()), states (expanded), complete (the breadth
## first walk ran out of states before the budget)}.
static func walk(ctx: Dictionary, talk: Dialog, budget: int = BUDGET, dives: int = DIVES) -> Dictionary:
	var start := {"talk": talk.copy(), "before": str(talk.position().get("text", "")), "path": path_of(talk)}
	var queue: Array = [start]
	var head := 0
	var seen := {}
	var out := {"exchanges": {}, "endings": {}, "states": 0, "complete": false}
	while head < queue.size() and out["states"] < budget:
		var node: Dictionary = queue[head]
		head += 1
		var key := (node["talk"] as Dialog).state_key() + "|" + str(node["before"])
		if seen.has(key):
			continue
		seen[key] = true
		out["states"] += 1
		for option: Dictionary in _options(node["talk"]):
			var next := _step(ctx, node, option, out)
			if not next.is_empty():
				queue.append(next)
	out["complete"] = head >= queue.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(talk.def.id)
	for i in dives:
		var node := start
		while not node.is_empty():
			var options := _options(node["talk"])
			node = _step(ctx, node, options[rng.randi_range(0, options.size() - 2)], out)  # never the close
	return out


## Every option a turn of `t` could offer under any deal, the close last.
static func _options(t: Dialog) -> Array:
	return t._candidates() + [{"move": "close", "pick": ""}]


## Play `option` on a copy of `node`'s talk and keep the exchange (and the
## ending) in `out`: the next node, {} when the talk ended or refused it.
static func _step(ctx: Dictionary, node: Dictionary, option: Dictionary, out: Dictionary) -> Dictionary:
	var c := (node["talk"] as Dialog).copy()
	var r := c.say(option["move"], option["pick"])
	if r.has("error"):
		return {}
	var x := turn(ctx, c, node["before"], node["path"], r)
	var ex_key: String = x["before"] + "\n" + x["said"]
	var ex: Dictionary = out["exchanges"].get(ex_key, {"before": x["before"], "said": x["said"], "move": x["move"],
		"replies": {}})
	ex["replies"][x["reply"] + ("\n" + x["more"] if not x["more"].is_empty() else "")] = x["flags"]
	out["exchanges"][ex_key] = ex
	if r["ended"]:
		var e := ending(ctx, c, r)
		out["endings"]["%s|%s|%s|%s" % [e["outcome"], e["reply"], e["farewell"], e["ruud"]]] = e
		return {}
	return {"talk": c, "before": last_words(node["before"], r), "path": path_after(node["path"], r)}


# ── Whole talks, as the player sees them ────────────────────────────────────

## A whole talk played by `player` (a Callable (talk, offers, turns) → index into
## offers, -1 to close) through the turns' offers: {turns: [turn() + {offers,
## chosen}], ending}.
static func play(ctx: Dictionary, talk: Dialog, player: Callable) -> Dictionary:
	var t := talk.copy()
	var before := str(t.position().get("text", ""))
	var turns: Array[Dictionary] = []
	var path := path_of(t)
	var r := {}
	while t.outcome.is_empty():
		var offers := t.offer()
		var i: int = player.call(t, offers, turns)
		var option: Dictionary = offers[i] if i >= 0 and i < offers.size() else {"move": "close", "pick": ""}
		r = t.say(option["move"], option["pick"])
		var x := turn(ctx, t, before, path, r)
		x["offers"] = offers.map(func(o: Dictionary) -> String: return str(o["line"]))
		x["chosen"] = i if i >= 0 and i < offers.size() else -1
		turns.append(x)
		path = path_after(path, r)
		before = last_words(before, r)
	return {"turns": turns, "ending": ending(ctx, t, r)}


## The players a transcript shows: [{name, play (Callable)}].
static func players() -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"name": "Luistert eerst", "play": listener}]
	for i in Dialog.OFFERED:
		out.append({"name": "Kiest altijd zin %d" % (i + 1), "play": func(_t: Dialog, offers: Array, _turns: Array) -> int:
			return mini(i, offers.size() - 1)})
	out.append({"name": "Stuurt meteen", "play": steerer})
	for s in RANDOM_PLAYERS:
		var rng := RandomNumberGenerator.new()
		rng.seed = s + 1
		out.append({"name": "Kiest willekeurig (%d)" % (s + 1), "play": func(_t: Dialog, offers: Array, _turns: Array) -> int:
			return rng.randi_range(0, offers.size() - 1)})
	return out


## Listens first: answers the person's last words with the move that fits them,
## puts a proposal on the table once the concern is out, then asks; never presses.
static func listener(t: Dialog, offers: Array, turns: Array) -> int:
	var want: Array = []
	if not t.table.is_empty():
		want = ["ask_commitment"]
	elif t.revealed.has("concern") and (t.openness >= Dialog.COMMIT_AT or t.patience <= 2):
		want = ["propose", "propose_experiment"]
	if t.def.kind == "checkin" and t.revealed.has("concern"):
		want = ["close"]
	for tag: String in t._last_tags:
		if DialogRoutes.ANSWER.has(tag):
			want.append(DialogRoutes.ANSWER[tag])
	want.append_array(["open_question", "mood", "empathy", "inquiry", "paraphrase", "silence"])
	var last := str(turns[-1]["move"]) if not turns.is_empty() else ""
	for move: String in want:
		for i in offers.size():
			if offers[i]["move"] == move and move != last:
				return i
	for i in offers.size():
		if not offers[i]["move"] in ["pressure", "confront"]:
			return i
	return 0


## Steers as soon as a turn offers it (a proposal, the ask, data), else presses.
static func steerer(_t: Dialog, offers: Array, _turns: Array) -> int:
	for wanted: Array in [["ask_commitment"], ["propose", "propose_experiment", "show_data", "perspective"],
			["pressure", "confront"]]:
		for i in offers.size():
			if offers[i]["move"] in wanted:
				return i
	return 0


# ── Reading ─────────────────────────────────────────────────────────────────

## How broken a walk reads: {score, counts (flag → distinct exchanges or endings
## with it), generic (the share of replies that are stock lines), exchanges}.
static func score(ctx: Dictionary, walked: Dictionary) -> Dictionary:
	var counts := {}
	var replies := 0
	var stock := 0
	var bank_texts: Dictionary = ctx["bank_replies"]
	for ex: Dictionary in walked["exchanges"].values():
		for reply: String in ex["replies"]:
			replies += 1
			stock += 1 if bank_texts.has(reply) else 0
			for f: String in ex["replies"][reply]:
				counts[f] = int(counts.get(f, 0)) + 1
	for e: Dictionary in walked["endings"].values():
		for f: String in e["flags"]:
			counts[f] = int(counts.get(f, 0)) + 1
	var generic := stock / float(maxi(replies, 1))
	var total := 10.0 * generic
	for f: String in counts:
		total += float(WEIGHT.get(f, 0.0)) * sqrt(float(counts[f]))
	return {"score": total, "counts": counts, "generic": generic, "exchanges": walked["exchanges"].size()}


## Every text the bank's replies, special lines and wear-out lines hold.
static func _bank_replies(c: Catalog) -> Dictionary:
	var out := {}
	var bank := c.dialog_bank
	for move: Variant in JsonFile.dict_or_empty(bank.get("replies")):
		for situation: Variant in bank["replies"][move]:
			out[str(bank["replies"][move][situation].get("text", ""))] = true
	for key: String in ["special", "outcomes"]:
		for k: Variant in JsonFile.dict_or_empty(bank.get(key)):
			out[str(bank[key][k])] = true
	for archetype: Variant in JsonFile.dict_or_empty(bank.get("wear_out")):
		for k: Variant in bank["wear_out"][archetype]:
			out[str(bank["wear_out"][archetype][k])] = true
	return out
