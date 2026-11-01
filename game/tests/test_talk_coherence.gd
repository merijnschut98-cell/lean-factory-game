extends TestCase
## Every talk in content holds together through the real rules (Merijn's playtest
## 2026-10-30; docs/qa/dialog-coherence-2026-10-30.md): walked over every option a
## turn could offer (TalkWalk, a smaller walk than the transcripts'), no person says
## the player repeats themselves when they did not, asks them to clarify, says
## nothing, or ends a talk without their word on how it went, and Ruud's note after
## an Act 0 talk quotes the player; no story line (a layer, a lead-in, a proposal's
## reply, their own idea) is said twice, and a reviewed talk (TalkWalk.REVIEWED) says
## no line twice at all (review 1, 2026-10-30). The transcripts (game/tools/talk_transcripts.gd)
## show the same flags in context.

## States and random talks walked per talk (enough for every option of the first
## turns and the endings; the transcripts walk more).
const BUDGET := 150
const DIVES := 40


func test_no_talk_says_what_the_player_s_sentences_cannot_have_earned() -> void:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	var ctx := TalkWalk.context(c)
	var talks := TalkWalk.talks(c)
	assert_true(talks.size() > 30, "every persuasion and check-in")
	for talk: Dialog in talks:
		var walked := TalkWalk.walk(ctx, talk, BUDGET, DIVES)
		var broken := []
		var never: Array = TalkWalk.BROKEN + (["echo"] if talk.def.id in TalkWalk.REVIEWED else [])
		for ex: Dictionary in walked["exchanges"].values():
			for reply: String in ex["replies"]:
				for f: String in ex["replies"][reply]:
					if f in never:
						broken.append("%s: \"%s\" → \"%s\"" % [f, ex["said"], reply])
		for e: Dictionary in walked["endings"].values():
			for f: String in e["flags"]:
				if f in TalkWalk.BROKEN:
					broken.append("%s: ends %s on \"%s\"%s" % [f, e["outcome"], e["reply"],
						(" (Ruud: \"%s\")" % e["ruud"]) if f == "ruud" else ""])
		assert_true(broken.is_empty(), "%s: %d broken, e.g. %s" % [TalkWalk.label(talk), broken.size(), broken.slice(0, 3)])


## Review round 2: the walk flags a story line said twice even when the player
## said the same sentence again (a proposal's answer, a lead-in, a layer never
## comes twice), and an echo only to a new sentence.
func test_the_walk_flags_a_retold_story_line_and_an_echo() -> void:
	var ctx := {"repeat": null, "clarify": null, "stock": {}}
	var t := DialogFixture.talk(50)
	var path := {"moves": ["propose"], "lines": ["Voorstel goed."], "heard": ["Positie.", "Dat helpt.", "Gaat wel."]}
	var said_again := {"move": "propose", "line": "Voorstel goed.", "reply": "Dat helpt."}
	assert_true("retold" in TalkWalk.turn(ctx, t, "Gaat wel.", path, said_again)["flags"],
		"the proposal's answer twice, though the player repeated the proposal")
	var new_line := {"move": "mood", "line": "Hoe is het?", "reply": "Gaat wel."}
	assert_true("echo" in TalkWalk.turn(ctx, t, "Dat helpt.", path, new_line)["flags"], "a line again, to a new sentence")
	var same_line := {"move": "mood", "line": "Voorstel goed.", "reply": "Gaat wel."}
	assert_false("echo" in TalkWalk.turn(ctx, t, "Dat helpt.", path, same_line)["flags"],
		"the same answer to the same sentence is no echo")


## Review 7 (2026-11-01): a talk is walked in every version, the dialog as written
## and each variant, so a fault only a variant holds is caught: here the variant's
## position comes back, word for word, as the answer to the mood question.
func test_the_walk_plays_every_version_of_a_talk() -> void:
	var line := "Gaat wel, hoor."
	var d := DialogFixture.def({"replies": {"mood": {"lands": {"text": line}}},
		"variants": [{"needs": {"all": ["standardised:custom_design"]}, "position": {"text": line, "tags": ["claim"]}}]})
	var people := DialogFixture.people([d])
	var ctx := {"repeat": null, "clarify": null, "stock": {}, "people": people}
	var versions := TalkWalk.versions(d, people)
	assert_eq(versions.map(func(t: Dialog) -> int: return t.version), [-1, 0], "as written, then the variant")
	var echoes := versions.map(func(t: Dialog) -> int: return _echoes_of(TalkWalk.walk(ctx, t, 60, 5), line))
	assert_eq(echoes[0], 0, "as written, the mood's answer is new")
	assert_true(echoes[1] > 0, "the variant's position, said again as the mood's answer")
	assert_eq(TalkWalk.label(versions[1]), "dialog_id (variant 1)".replace("dialog_id", d.id))


func _echoes_of(walked: Dictionary, line: String) -> int:
	var n := 0
	for ex: Dictionary in walked["exchanges"].values():
		n += 1 if "echo" in ex["replies"].get(line, []) else 0
	return n


## Review 2 #1 (2026-10-31): a question that misses in a reviewed talk is held back or
## turned aside in the person's own words at every layer, never "I don't know" about
## the work they just explained or do every day.
const DISOWNS := "(?i)weet (ik )?(het )?(eigenlijk )?niet|geen idee|nakijken|zo gaat (dat|het) (hier|nu eenmaal)"


func test_a_reviewed_talk_never_disowns_its_own_work_when_a_question_misses() -> void:
	var c := Catalog.load_from()
	var re := RegEx.create_from_string(DISOWNS)
	var bad := []
	for talk: Dialog in TalkWalk.talks(c, TalkWalk.REVIEWED):
		var misses: Variant = JsonFile.dict_or_empty(talk.def.replies.get("inquiry")).get("misses")
		for layer: String in ["interest", "concern"]:
			if not (misses is Dictionary and (misses as Dictionary).has(layer)):
				bad.append("%s: no own inquiry.misses.%s" % [talk.def.id, layer])
		for move: String in ["inquiry", "open_question"]:
			for case: String in ["misses", "again"]:
				for text: String in _texts(JsonFile.dict_or_empty(talk.def.replies.get(move)).get(case)):
					if re.search(text) != null:
						bad.append("%s: %s.%s \"%s\"" % [talk.def.id, move, case, text])
	assert_true(bad.is_empty(), "%d: %s" % [bad.size(), bad.slice(0, 6)])


static func _texts(entry: Variant) -> Array[String]:
	var out: Array[String] = []
	if entry is Dictionary and (entry as Dictionary).has("text"):
		out.append(str(entry["text"]))
	elif entry is Dictionary or entry is Array:
		for e: Variant in (entry.values() if entry is Dictionary else entry):
			out.append_array(_texts(e))
	return out


## Review 2, R1: a long sentence of the player (a story, a promise) said a second time
## in one route is flagged `told`; a short one, or a proposal made again, is not.
func test_the_walk_flags_a_long_sentence_told_twice() -> void:
	var ctx := {"repeat": null, "clarify": null, "stock": {}}
	var t := DialogFixture.talk(50)
	var story := "Maandagavond kon ik de uitgang niet vinden, en niemand hier wist wat ik kwam doen."
	var path := {"moves": ["experience"], "lines": [story, "Gaat het?"], "heard": ["Positie."]}
	assert_true("told" in TalkWalk.turn(ctx, t, "Hm.", path, {"move": "experience", "line": story, "reply": "Mm."})["flags"])
	assert_false("told" in TalkWalk.turn(ctx, t, "Hm.", path, {"move": "mood", "line": "Gaat het?", "reply": "Ja."})["flags"],
		"a short line again")
	var long_proposal := "Wat als we samen een week lang elke ochtend tellen wat er binnenkomt en wat blijft liggen?"
	path["lines"].append(long_proposal)
	assert_false("told" in TalkWalk.turn(ctx, t, "Hm.", path, {"move": "propose", "line": long_proposal, "reply": "Ja."})["flags"],
		"a proposal made again is acknowledged, not told")


## Review 3 #2 (2026-11-01): a commitment follows any proposal or experiment that meets
## the concern, so in a reviewed talk it may not name what only some of them bring: a
## word (four letters or more) of the commitment that one of the talk's proposals or
## replies uses, but not every one that can lead to the commitment, unless the person
## said it before any proposal (the opening, the position, the interest). Spoken
## small words (STOP) say nothing about a route; ROUTE_WORDS_READ are words read by
## hand that fit every route (an invitation, a time of day). A limit: a word the person
## said first can still lean on one route (Sanne's "formulier"); the transcripts show that.
const STOP := ["goed", "maar", "toch", "even", "zelf", "zijn", "laat", "zien", "iets", "nodig", "werkt", "zonder",
	"samen", "kijken", "eens", "wel", "niet", "want", "omdat"]
const ROUTE_WORDS_READ := {
	"anouk_first_look": ["koffie"],    # "Ik zet koffie": she receives whoever comes
	"sanne_tuesday": ["drieën"],       # "na drieën": when it is quiet, for any visit
	"mieke_wednesday": ["eentje"],     # "pak ik er eentje voor je uit": any look at a sketch
	"anouk_thursday": ["vrijdag"],     # Friday is the week's review day for every route
	"petra_batch": ["ziek", "laptop"], # being ill without the laptop: true after either route
}


func test_a_reviewed_talk_s_commitment_fits_every_route_to_it() -> void:
	var c := Catalog.load_from()
	var bad := []
	for talk: Dialog in TalkWalk.talks(c, TalkWalk.REVIEWED):
		var d := talk.def
		var said_first := _words(d.opening + " " + str(d.position.get("text", "")) + " " + str(d.layers[0].get("text", "")))
		var items: Array = d.proposals + d.experiments
		var routes := items.filter(func(i: Dictionary) -> bool: return "concern" in i.get("addresses", []))
		for w: String in _words(str(d.outcomes.get("commitment", ""))):
			if w.length() < 4 or said_first.has(w) or w in STOP or w in ROUTE_WORDS_READ.get(d.id, []):
				continue
			var brought := items.any(func(i: Dictionary) -> bool: return _words(_item_text(i)).has(w))
			var everywhere := routes.all(func(i: Dictionary) -> bool: return _words(_item_text(i)).has(w))
			if brought and not everywhere:
				bad.append("%s: \"%s\" comes from only some routes to the commitment" % [d.id, w])
	assert_true(bad.is_empty(), "%d: %s" % [bad.size(), bad])


static func _item_text(item: Dictionary) -> String:
	return str(item.get("text", "")) + " " + str(item.get("reply", ""))


static func _words(text: String) -> Dictionary:
	var out := {}
	for m: RegExMatch in RegEx.create_from_string("[\\p{L}']+").search_all(text.to_lower()):
		out[m.get_string()] = true
	return out
