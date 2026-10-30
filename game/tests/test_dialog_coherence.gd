extends TestCase
## A talk holds together (Merijn's playtest 2026-10-30; docs/qa/dialog-coherence-2026-10-30.md):
## what a person answers and what Ruud says afterwards follow from what the player
## actually said, never from the kind of move alone.


func _bank_with_again() -> Dictionary:
	var bank := DialogFixture.bank()
	for move: String in ["empathy", "silence", "paraphrase"]:
		bank["replies"][move]["again"] = {"text": move + " nog eens"}
	return bank


func _talk(bank: Dictionary, d: DialogDef = DialogFixture.def(), openness: int = 20) -> Dialog:
	return Dialog.new(d, DialogFixture.person(), bank, {"openness": openness, "trust": 50, "mood": "neutraal",
		"found": {}, "facts": {}})


## "Ja, dat zei je al." only after the player said that kind of sentence before.
func test_a_person_says_you_repeat_yourself_only_when_you_did() -> void:
	var t := _talk(_bank_with_again())
	DialogFixture.play(t, ["mood", "open_question"])  # past the early moves; their last words a claim
	var first := t.say("empathy")
	assert_false(first["lands"], "empathy after a claim, late: a miss")
	assert_eq(first["reply"], "empathy mist", "the first time an ordinary miss, no 'you said that'")
	assert_eq(t.say("paraphrase")["reply"], "paraphrase landt", "a summary of the claim")
	var second := t.say("empathy")
	assert_false(second["lands"])
	assert_eq(second["reply"], "empathy nog eens", "the second time they may say you said it before")


## Without an `again` line the miss stays the ordinary one (a dialog's own, or the bank's).
func test_without_an_again_line_the_miss_is_the_ordinary_one() -> void:
	var t := _talk(DialogFixture.bank())
	DialogFixture.play(t, ["mood", "open_question", "empathy", "paraphrase"])
	assert_eq(t.say("empathy")["reply"], "empathy mist")


## Three times the same in a row: the person answers in the form of what was
## said (a silence is no question), from the move's `again` line.
func test_three_in_a_row_is_answered_in_the_form_of_the_move() -> void:
	var t := _talk(_bank_with_again(), DialogFixture.def(), 50)
	DialogFixture.play(t, ["silence", "silence"])
	var third := t.say("silence")
	assert_eq(third["reply"], "silence nog eens", "not the bank's 'you asked that' after three silences")
	assert_eq(third["delta"], Dialog.REPEAT_THIRD, "the rules are unchanged: a third in a row costs")


## The player's line answers what the person said last: a talk's own line for a
## move may be keyed by the layer the talk is at (position, interest, lead_in,
## concern, `_` for any).
func test_the_player_s_line_answers_what_the_person_said_last() -> void:
	var d := DialogFixture.def({"lines": {"paraphrase": {"position": "Dus de positie.", "interest": "Dus het belang.",
		"_": "Dus iets."}, "mood": {"_": ["Hoe gaat het?", "En verder?"]}}})
	var t := _talk(DialogFixture.bank(), d, 50)
	assert_true(t.offer().all(func(o: Dictionary) -> bool: return o["move"] != "paraphrase" or o["line"] == "Dus de positie."),
		"offered as it will be said")
	var r := t.say("paraphrase")
	assert_eq(r["line"], "Dus de positie.", "a summary of what they said: their position")
	assert_eq(r["revealed"], "interest", "it drew the interest out")
	assert_eq(t.say("paraphrase")["line"], "Dus het belang.", "now a summary of the interest")
	assert_eq(t.say("mood")["line"], "Hoe gaat het?", "`_` stands for any layer; a list still turns")
	assert_eq(t.say("mood")["line"], "En verder?")


## The talk keeps the player's sentences, as said, in order.
func test_the_talk_keeps_what_the_player_said() -> void:
	var t := _talk(DialogFixture.bank())
	DialogFixture.play(t, ["mood", "open_question", "close"])
	assert_eq(t.said, ["speler mood", "speler open_question", "speler close"])
	assert_eq(t.copy().said, t.said, "a copy keeps them")


## However a talk ends, the person says how it landed, in their own words: the
## outcome line after their reply when the talk ran out of time.
func test_every_ending_carries_the_person_s_word_on_how_it_landed() -> void:
	var t := _talk(DialogFixture.bank(), DialogFixture.def({"patience": 3}))
	DialogFixture.play(t, ["mood", "open_question"])
	var r := t.say("empathy")
	assert_true(r["ended"], "out of time")
	assert_eq(r["farewell"], "uitkomst " + r["outcome"], "their word on how it went, after their reply")
	var closed := _talk(DialogFixture.bank())
	var c := closed.say("close")
	assert_eq(c["reply"], "uitkomst " + c["outcome"], "a close is answered with it")
	assert_eq(c["farewell"], "", "and not twice")
	var running := _talk(DialogFixture.bank()).say("mood")
	assert_eq(running["farewell"], "", "nothing while the talk runs")


## Ruud's note after an Act 0 talk quotes the sentence the player said for the
## move he names: never a move described that the player did not say.
func test_ruud_quotes_the_sentence_he_names() -> void:
	var bank := DialogFixture.bank()
	bank["ruud_names"]["mood"] = "Je zei: “{said}” Tegen {person}."
	var people := People.new([DialogFixture.person()], [DialogFixture.def({"tutorial": true, "teaches": ["mood"]})], bank)
	var d := people.start(people.dialogs["talk"], DialogFixture.world())
	DialogFixture.play(d, ["open_question", "mood"])
	assert_eq(people.finish(d, 0)["ruud_names"], "Je zei: “speler mood” Tegen Pim.")
	assert_eq(people.ruud_named(d), {"move": "mood", "said": "speler mood"}, "the move and the sentence he names")
