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


## A new sentence of the same kind is no repeat: "dat zei je al" needs the same
## sentence (or a move whose sentences all say the same: how are you, nothing).
func test_a_new_sentence_of_the_same_kind_is_no_repeat() -> void:
	var d := DialogFixture.def({"lines": {"empathy": ["Dat is veel.", "Dat lijkt me zwaar."]}})
	var t := _talk(_bank_with_again(), d)
	DialogFixture.play(t, ["mood", "open_question", "empathy", "paraphrase"])
	var second := t.say("empathy")
	assert_false(second["lands"])
	assert_true(t.said.count(second["line"]) == 1, "a sentence not said before")
	assert_eq(second["reply"], "empathy mist", "so no 'you said that'")
	var four := _talk(_bank_with_again(), d, 50)
	DialogFixture.play(four, ["empathy", "empathy"])
	assert_eq(four.say("empathy")["reply"], "defender zegt", "the third in a row: the pattern, in their words")
	var fourth := four.say("empathy")
	assert_true(fourth["line"] in four.said.slice(0, 3), "the fourth: a sentence said before")
	assert_eq(fourth["reply"], "empathy nog eens", "now they may say you said it")


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


## A third proposal in a row that is a new one is answered as a proposal, not
## called a repeat (the rules still count the streak).
func test_a_new_proposal_after_two_others_is_no_repeat() -> void:
	var t := _talk(_bank_with_again(), DialogFixture.def(), 50)
	DialogFixture.play(t, ["paraphrase", "reflect", "propose:good", "propose:good"])
	var third := t.say("propose", "bare")
	assert_eq(third["reply"], "Bezwaar.", "their answer to the new proposal")
	assert_eq(third["delta"], Dialog.REPEAT_THIRD, "the third in a row still costs")
	var same := _talk(_bank_with_again(), DialogFixture.def(), 50)
	DialogFixture.play(same, ["paraphrase", "reflect", "propose:good", "propose:bare"])
	assert_eq(same.say("propose", "good")["reply"], "herhaling", "the same proposal again: a repeat")


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


## A talk's own reply may answer the layer the player spoke to (keyed by TOPICS),
## and a list gives the next line each time the move is made (the last one stays).
func test_a_reply_answers_the_layer_the_player_spoke_to() -> void:
	var replies := {"open_question": {"lands": {"position": {"text": "Over de positie.", "tags": ["claim"]},
		"_": {"text": "Over iets anders."}}}, "empathy": {"lands": [{"text": "Eerste."}, {"text": "Tweede."}]}}
	var d := DialogFixture.def({"replies": replies})
	var r := _talk(DialogFixture.bank(), d).say("open_question")
	assert_eq([r["reply"], r["tags"]], ["Over de positie.", ["claim"]], "an answer to the position")
	var t := _talk(DialogFixture.bank(), d, 50)
	assert_eq(t.say("paraphrase")["revealed"], "interest")
	assert_eq(t.say("open_question")["reply"], "Over iets anders.", "past the position: `_`")
	var listed := _talk(DialogFixture.bank(), d)
	assert_eq(listed.say("empathy")["reply"], "Eerste.", "a list: the first line the first time")
	assert_eq(listed.say("empathy")["reply"], "Tweede.", "the next one the next time")


## Review 1 #1: they do not offer as their own idea what the player just proposed.
func test_their_own_idea_is_not_offered_after_the_player_proposed_it() -> void:
	var t := _talk(DialogFixture.bank(), DialogFixture.def(), 85)
	t.revealed = {"interest": true, "concern": true}
	t.say("paraphrase")   # heard
	t._co_offered = false
	var r := t.say("propose", "secret")
	assert_eq(r["co_proposal"], {}, "the player's proposal is on the table: no 'weet je wat?'")


## Review 1 #1: once they offered their idea, taking it up is on offer, in words
## that take it up (the co-proposal's `take`).
func test_taking_up_their_idea_is_offered_in_words_that_take_it_up() -> void:
	var d := DialogFixture.def({"co_proposal": {"id": "secret", "text": "Ons eigen idee.", "take": "Graag, samen dan."}})
	var t := _talk(DialogFixture.bank(), d, 85)
	t.revealed = {"interest": true, "concern": true}
	assert_false(t.say("paraphrase")["co_proposal"].is_empty(), "their own idea")
	var take := t.offer().filter(func(o: Dictionary) -> bool: return o["move"] == "propose" and o["pick"] == "secret")
	assert_eq(take.size(), 1, "taking it up is one of the sentences")
	assert_eq(take[0]["line"], "Graag, samen dan.")


## Review 1 #2: a proposal made again is answered with a short acknowledgement
## (the talk's own `replies.propose.again`, else the bank's special.proposal_again),
## never its first answer word for word; the rules read it as before.
func test_a_proposal_made_again_is_acknowledged_not_answered_twice() -> void:
	var t := _talk(DialogFixture.bank(), DialogFixture.def(), 50)
	DialogFixture.play(t, ["paraphrase", "propose:good"])
	var first_words := t.copy()
	var again := t.say("propose", "good")
	assert_eq(again["reply"], DialogFixture.bank()["special"]["proposal_again"], "not 'Dat helpt.' again")
	first_words.said.clear()   # the same talk, the proposal as if new: the same numbers
	var as_new := first_words.say("propose", "good")
	assert_eq([again["delta"], again["tags"]], [as_new["delta"], as_new["tags"]], "the rules read it as before")
	var own := _talk(DialogFixture.bank(), DialogFixture.def({"replies": {"propose": {"again": {"text": "Ja, ja."}}}}), 50)
	DialogFixture.play(own, ["paraphrase", "propose:good"])
	assert_eq(own.say("propose", "good")["reply"], "Ja, ja.", "the talk's own")


## Review 1 #3: the lead-in is said once; when the moment passed and comes back,
## the person says its short form (the layer's `again`, else the bank's), with the
## same cue.
func test_the_lead_in_is_said_once_then_its_short_form() -> void:
	var t := _talk(DialogFixture.bank(), DialogFixture.def(), 66)
	t.revealed = {"interest": true}
	assert_eq(t.say("mood")["reply"], "En…", "the lead-in")
	t.say("open_question")   # not a way in: the moment passes
	var again := t.say("open_question")
	assert_eq(again["reply"], DialogFixture.bank()["special"]["lead_in_again"], "its short form, not the same words")
	assert_true("hesitation" in again["tags"], "the same cue")
	var own := _talk(DialogFixture.bank(), DialogFixture.def({"layers": DialogFixture.dialog_data()["layers"].map(
		func(l: Dictionary) -> Dictionary: return l.merged({"lead_in": {"text": "En…", "tags": ["hesitation"],
			"again": "Dat van net…"}}, true) if l["id"] == "concern" else l)}), 66)
	own.revealed = {"interest": true}
	DialogFixture.play(own, ["mood", "open_question"])
	assert_eq(own.say("open_question")["reply"], "Dat van net…", "the layer's own short form")


## Review 1 #3/#4: a lead-in's short forms as a list, each said once while another
## is left; a talk may give its own refusal ("Nee. Nog niet.") as a list too.
func test_short_forms_and_refusals_turn_through_their_lists() -> void:
	var layers: Array = DialogFixture.dialog_data()["layers"].map(func(l: Dictionary) -> Dictionary:
		return l.merged({"lead_in": {"text": "En…", "tags": ["hesitation"], "again": ["Eén…", "Twee…"]}}, true) \
			if l["id"] == "concern" else l)
	var t := _talk(DialogFixture.bank(), DialogFixture.def({"layers": layers}), 66)
	t.revealed = {"interest": true}
	var said := []
	for move: String in ["mood", "paraphrase", "open_question", "paraphrase", "open_question"]:
		said.append(t.say(move)["reply"])
	assert_eq(said.filter(func(r: String) -> bool: return r in ["En…", "Eén…", "Twee…"]), ["En…", "Eén…", "Twee…"],
		"each lead-in in other words")
	var no := _talk(DialogFixture.bank(), DialogFixture.def({"replies": {"ask_commitment": {"misses":
		[{"text": "Nee, nog niet."}, {"text": "Echt nog niet."}]}}}), 50)
	DialogFixture.play(no, ["mood", "propose:good"])
	assert_eq([no.say("ask_commitment")["reply"], no.say("ask_commitment")["reply"]], ["Nee, nog niet.", "Echt nog niet."])


## Review 1 #2/#6: a reply given as a list gives the next line they have not said yet.
func test_a_list_reply_never_says_the_same_line_twice_while_another_is_left() -> void:
	var d := DialogFixture.def({"replies": {"mood": {"again": [{"text": "Nog steeds moe."}, {"text": "Echt, het gaat."}]}}})
	var t := _talk(DialogFixture.bank(), d, 50)
	DialogFixture.play(t, ["mood", "paraphrase"])
	var first := t.say("mood")
	var second := t.say("mood")
	assert_eq([first["reply"], second["reply"]], ["Nog steeds moe.", "Echt, het gaat."])


## Review round 2: a talk's own keyed lines are said in the order written, on any
## deal, so a follow-up question never comes before the question it follows.
func test_keyed_lines_come_in_the_order_written_on_any_deal() -> void:
	var d := DialogFixture.def({"lines": {"open_question": {"_": ["Eerst dit?", "En dan dat?", "En verder?"]}}})
	for seed in 6:
		var t := _talk(DialogFixture.bank(), d)
		t._seed = seed
		var asked := []
		for i in 3:
			asked.append(t.say("open_question")["line"])
		assert_eq(asked, ["Eerst dit?", "En dan dat?", "En verder?"], "seed %d" % seed)


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
