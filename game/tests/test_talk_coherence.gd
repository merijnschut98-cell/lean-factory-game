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
		assert_true(broken.is_empty(), "%s: %d broken, e.g. %s" % [talk.def.id, broken.size(), broken.slice(0, 3)])


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
