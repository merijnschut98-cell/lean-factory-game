extends TestCase
## One conversation (rules/dialog.gd): openness moves after each move by the
## person's state, the hidden concern must be earned, and no reply is right
## by itself (docs/superpowers/specs/2026-10-15-dialog-system-design.md §3–§4).

func _openness(d: Dialog, moves: Array) -> int:
	DialogFixture.play(d, moves)
	return d.openness


# ── Listening: MORE PIES ────────────────────────────────────────────────────

func test_an_open_question_is_the_safe_move() -> void:
	var d := DialogFixture.talk()
	var r := d.say("open_question")
	assert_eq([r["delta"], r["openness"], r["reply"]], [6, 41, "open_question landt"])
	assert_eq(r["line"], "speler open_question", "the player's line from the bank")


func test_asking_the_mood_lands_early_or_on_a_tense_day() -> void:
	assert_eq(DialogFixture.talk().say("mood")["delta"], 8, "the first move")
	assert_eq(DialogFixture.play(DialogFixture.talk(), ["open_question", "paraphrase", "mood"])["delta"], 2, "later, on an ordinary day")
	var tense := DialogFixture.talk(35, {"mood": "gespannen"})
	assert_eq(DialogFixture.play(tense, ["open_question", "paraphrase", "mood"])["delta"], 8, "a tense day: not yet asked")
	assert_eq(DialogFixture.play(tense, ["open_question", "mood"])["delta"], 2, "asked once already")


func test_a_paraphrase_of_a_claim_makes_the_person_feel_heard() -> void:
	var d := DialogFixture.talk()
	assert_eq(d.say("paraphrase")["delta"], 7, "the position is a claim")
	assert_true(d.heard)
	var after_feeling := DialogFixture.talk()
	after_feeling.say("mood")
	assert_eq(after_feeling.say("paraphrase")["delta"], 1, "nothing claimed to summarise")


func test_naming_a_feeling_lands_only_when_there_is_one() -> void:
	var d := DialogFixture.talk()
	d.say("mood")  # "Druk." carries a feeling
	assert_eq(d.say("reflect")["delta"], 10)
	assert_true(d.heard)
	var misread := DialogFixture.talk()
	var r := misread.say("reflect")
	assert_eq([r["delta"], r["reply"]], [-3, "reflect mist"], "a misread the person corrects")
	assert_false(misread.heard)


func test_silence_lands_after_a_hesitation_only() -> void:
	assert_eq(DialogFixture.talk().say("silence")["delta"], -4, "awkward")
	var d := DialogFixture.talk(66, {"revealed": {"interest": true}})
	var r := d.say("paraphrase")
	assert_eq([r["reply"], r["tags"], r["cue"]], ["En…", ["hesitation"], true], "the lead-in carries the cue")
	assert_eq(d.say("silence")["delta"], 12)


func test_sharing_experience_needs_trust_being_heard_and_a_doubt() -> void:
	assert_eq(DialogFixture.talk().say("experience")["delta"], -5, "it is not about you")
	var d := DialogFixture.talk(66, {"revealed": {"interest": true}})
	DialogFixture.play(d, ["paraphrase", "silence"])  # heard, the lead-in, then the concern: an admission
	assert_eq(d.say("experience")["delta"], 8)


func test_the_same_move_again_counts_half_and_a_third_time_costs() -> void:
	var d := DialogFixture.talk()
	assert_eq(d.say("open_question")["delta"], 6)
	assert_eq(d.say("open_question")["delta"], 3, "not a slot machine")
	var third := d.say("open_question")
	assert_eq([third["delta"], third["reply"]], [-3, "herhaling"])


func test_the_archetype_weighs_how_a_move_lands() -> void:
	var quiet := DialogFixture.talk(66, {"revealed": {"interest": true}}, DialogFixture.def(), DialogFixture.person("quiet"))
	quiet.say("paraphrase")
	assert_eq(quiet.say("silence")["delta"], 18, "a quiet person: silence ×1.5")


# ── Steering, pressure and blame ────────────────────────────────────────────

func test_pushing_too_early_costs_and_the_person_repeats_the_position() -> void:
	var d := DialogFixture.talk()
	var r := d.say("propose", "good")
	assert_eq([r["delta"], r["reply"], r["tags"]], [-12, "Positie.", ["claim"]], "not heard yet")
	assert_eq(d.table, "good", "the proposal is on the table all the same")
	var heard_but_low := DialogFixture.talk(30)
	heard_but_low.say("paraphrase")  # heard, at 37: still below 40
	assert_eq(heard_but_low.say("show_data", "custom_design:0")["delta"], -12)


func test_data_lands_only_when_the_person_is_curious() -> void:
	var d := DialogFixture.talk(45)
	d.say("paraphrase")  # heard, 52
	var r := d.say("show_data", "custom_design:0")
	assert_eq([r["delta"], r["reply"]], [-8, "show_data mist"], "below 55: 'so it is my people?'")
	var other := d.say("show_data", "custom_design:1")
	assert_eq([other["delta"], other["reply"]], [0, "En?"], "a clue this person does not care about")
	var open := DialogFixture.talk(50)
	open.say("paraphrase")
	assert_eq(open.say("show_data", "custom_design:0")["delta"], 10)


func test_a_proposal_lands_by_what_it_addresses() -> void:
	var d := DialogFixture.talk(50)
	d.say("paraphrase")
	var guess := d.say("propose", "good")
	assert_eq([guess["delta"], guess["reply"]], [4, "Hm. Misschien."], "the concern, before it is known")
	var bare := d.say("propose", "bare")
	assert_eq([bare["delta"], bare["reply"]], [0, "Bezwaar."], "the person names the objection")


func test_pressure_and_blame_cost_openness_and_trust() -> void:
	var d := DialogFixture.talk(50)
	var r := d.say("pressure")
	assert_eq([r["delta"], r["trust"]], [-15, 42])
	assert_true(d.pressured)
	var blamed := DialogFixture.talk(50)
	var b := blamed.say("confront")
	assert_eq([b["delta"], b["trust"]], [-20, 40])
	assert_true(blamed.confronted)


## Every move is always visible (Merijn, 2026-10-15): a repair with nothing
## to repair changes nothing, and lands once on a retry.
func test_a_repair_lands_only_on_a_retry_and_once() -> void:
	var first := DialogFixture.talk().say("repair")
	assert_eq([first["delta"], first["trust"], first["reply"]], [0, 50, "niets te herstellen"])
	var d := DialogFixture.talk(27, {"retry": true})
	var r := d.say("repair")
	assert_eq([r["openness"], r["trust"]], [39, 53])
	d.say("open_question")
	assert_eq(d.say("repair")["delta"], 0, "said once")


# ── Layers, the ceiling and the cue ─────────────────────────────────────────

func test_the_concern_must_be_earned() -> void:
	var d := DialogFixture.talk(50)
	d.say("mood")
	assert_eq(d.say("reflect")["openness"], 64, "the ceiling: the next layer's threshold + 9")
	var interest := d.say("inquiry")
	assert_eq([interest["revealed"], interest["reply"], interest["openness"]], ["interest", "Belang.", 72])
	var lead_in := d.say("reflect")
	assert_eq([lead_in["openness"], lead_in["revealed"], lead_in["cue"]], [79, "", true],
		"the lead-in comes first, at the new ceiling")
	var concern := d.say("silence")
	assert_eq([concern["revealed"], concern["reply"], concern["openness"], concern["cue"]], ["concern", "Zorg.", 91, false])
	assert_eq(concern["unlocked"], {"clue": "custom_design:5", "facts": ["heard:talk"], "proposals": ["secret"]})
	assert_true(_pick_ids(d, "propose").has("secret"), "the concern unlocked a proposal")


func test_a_layer_opens_only_through_one_of_its_ways_in() -> void:
	var d := DialogFixture.talk(50)
	d.say("mood")
	var r := d.say("reflect")  # 60 → 64: high enough, but reflect is no way into the interest
	assert_eq(r["revealed"], "")
	assert_eq(d.say("paraphrase")["revealed"], "", "after a feeling, nothing claimed: it does not land")
	assert_eq(d.say("inquiry")["revealed"], "interest")


func test_the_person_offers_an_idea_of_their_own_when_thinking_along() -> void:
	var d := _concern_known()
	var r := d.say("empathy")
	assert_eq(r["openness"], 100)
	assert_eq(r["co_proposal"], {"id": "secret", "text": "Ons eigen idee."})
	assert_eq(d.say("open_question")["co_proposal"], {}, "once")


# ── Outcomes ────────────────────────────────────────────────────────────────

## Openness 91 with the concern revealed (see test_the_concern_must_be_earned).
func _concern_known(d: DialogDef = DialogFixture.def(), facts: Dictionary = {}) -> Dialog:
	var talk := DialogFixture.talk(50, {"facts": facts}, d)
	DialogFixture.play(talk, ["mood", "reflect", "inquiry", "reflect", "silence"])
	return talk


func test_commitment_when_the_proposal_meets_the_concern() -> void:
	var d := _concern_known()
	DialogFixture.play(d, ["propose:good"])
	var r := d.say("ask_commitment")
	assert_eq([r["outcome"], r["ended"], r["reply"]], ["commitment", true, "uitkomst commitment"])
	assert_eq(d.say("open_question"), {"error": "ended"})


func test_an_unmet_condition_gives_an_agreement_under_condition() -> void:
	var def := DialogFixture.def({"condition_needs": {"all": ["committed:boss"]}})
	var d := _concern_known(def)
	var r := DialogFixture.play(d, ["propose:good", "ask_commitment"])
	assert_eq([r["outcome"], r["reply"]], ["partial", "Als de baas het goedvindt."], "the concern turned into a demand")
	assert_eq(DialogFixture.play(_concern_known(def, {"committed:boss": true}), ["propose:good", "ask_commitment"])["outcome"],
		"commitment")


func test_a_partial_agreement_without_the_concern_and_a_refusal_below() -> void:
	var d := DialogFixture.talk(50)
	var r := DialogFixture.play(d, ["paraphrase", "propose:bare", "ask_commitment"])
	assert_eq([r["outcome"], r["reply"]], ["partial", "uitkomst partial"], "57: 'first see, then believe'")
	var low := DialogFixture.talk()
	var refused := DialogFixture.play(low, ["paraphrase", "propose:bare", "ask_commitment"])
	assert_eq([refused["delta"], refused["reply"], refused["ended"]], [-10, "weigering", false])
	assert_eq(DialogFixture.talk(60).say("ask_commitment")["reply"], "geen voorstel", "nothing on the table")


func test_pressure_wins_compliance() -> void:
	var d := DialogFixture.talk()
	var r := DialogFixture.play(d, ["open_question", "pressure", "propose:good", "ask_commitment"])
	assert_eq([r["outcome"], r["openness"], r["trust"]], ["compliance", 14, 42])


func test_pushing_a_guarded_person_ruins_the_talk() -> void:
	var d := DialogFixture.talk()
	var r := DialogFixture.play(d, ["show_data:custom_design:0", "propose:good", "pressure"])
	assert_eq([r["outcome"], r["openness"], r["reply"], r["ended"]], ["ruined", 0, "Klaar.", true])
	assert_eq(d.meter()["trace"], [35, 23, 11, 0])


func test_a_hard_block_until_a_route_is_met() -> void:
	var block := {"text": "Kan niet.", "routes": [{"needs": {"all": ["checked:custom_design"]}, "hint": "Laat zien."}]}
	var d := _concern_known(DialogFixture.def({"block": block}))
	var r := DialogFixture.play(d, ["propose:good", "ask_commitment"])
	assert_eq([r["outcome"], r["reply"], r["delta"]], ["blocked", "Kan niet.", 0])
	var met := _concern_known(DialogFixture.def({"block": block}), {"checked:custom_design": true})
	assert_eq(DialogFixture.play(met, ["propose:good", "ask_commitment"])["outcome"], "commitment")


func test_closing_is_graceful() -> void:
	var none := DialogFixture.talk().say("close")
	assert_eq([none["outcome"], none["reply"], none["ended"]], ["none", "uitkomst none", true])
	var heard := DialogFixture.play(DialogFixture.talk(40), ["open_question", "paraphrase", "inquiry", "close"])
	assert_eq(heard["outcome"], "heard", "61: the person felt listened to")


func test_patience_runs_out_without_ruining_the_talk() -> void:
	var d := DialogFixture.talk(35, {}, DialogFixture.def({"patience": 3}))
	assert_true(d.say("open_question")["patience_low"], "two moves left: the clock")
	d.say("paraphrase")
	var r := d.say("mood")
	assert_eq([r["ended"], r["outcome"]], [true, "heard"], "15 above the start")
	assert_eq(DialogFixture.talk(35, {}, DialogFixture.def(), DialogFixture.person("overloaded")).patience, 7, "a busy person gives less time")


func test_a_checkin_has_no_proposal_to_win() -> void:
	var data := DialogFixture.dialog_data({"kind": "checkin"})
	for key in ["mission", "owns", "condition_needs", "co_proposal"]:
		data.erase(key)
	var fixing := DialogFixture.talk(50, {}, DialogDef.from_dict(data))
	fixing.say("paraphrase")
	assert_eq(fixing.say("propose", "bare")["delta"], -12, "fixing mode: steering before the concern")
	var listening := DialogFixture.talk(50, {}, DialogDef.from_dict(data))
	var r := DialogFixture.play(listening, ["mood", "reflect", "inquiry", "reflect", "silence", "close"])
	assert_eq(r["outcome"], "lifted")


# ── Input, palette and meter ────────────────────────────────────────────────

func test_bad_moves_and_picks_change_nothing() -> void:
	var d := DialogFixture.talk()
	assert_eq(d.say("shout"), {"error": "unknown_move"})
	assert_eq(d.say("propose", "nope"), {"error": "bad_pick"})
	assert_eq(d.say("propose", "secret"), {"error": "bad_pick"}, "hidden until the concern unlocks it")
	assert_eq(d.say("show_data", "custom_design:4"), {"error": "bad_pick"}, "a clue the player has not found")
	assert_eq(d.say("mood", "x"), {"error": "bad_pick"})
	assert_eq(d.say("propose"), {"error": "bad_pick"}, "a proposal needs a pick")
	assert_eq(d.meter()["trace"], [35], "nothing happened")


func test_the_palette_is_fixed_and_says_nothing_about_fit() -> void:
	var ids := DialogFixture.talk().moves().map(func(m: Dictionary) -> String: return m["id"])
	assert_eq(ids, Dialog.MOVES, "all moves, always (Merijn, 2026-10-15)")
	var first: Dictionary = DialogFixture.talk().moves()[0]
	assert_eq(first, {"id": "mood", "row": "listen", "label": "chip mood", "line": "speler mood"})
	assert_eq(_pick_ids(DialogFixture.talk(), "propose"), ["good", "bare"])
	assert_eq(_pick_ids(DialogFixture.talk(), "show_data"), ["custom_design:0", "custom_design:1"])
	assert_eq(_pick_ids(DialogFixture.talk(), "propose_experiment"), ["trial"])


## Merijn (2026-10-15): an arrow per reply, ▲ or ▲▲ (8 and over), ▼ or ▼▼;
## never a number.
func test_each_reply_shows_an_arrow_not_a_number() -> void:
	var d := DialogFixture.talk()
	assert_eq(d.say("open_question")["arrow"], 1)
	assert_eq(d.say("paraphrase")["arrow"], 1, "+7: one arrow")
	assert_eq(d.say("reflect")["arrow"], -1, "a misread")
	assert_eq(DialogFixture.talk().say("mood")["arrow"], 2, "+8: two arrows")
	assert_eq(DialogFixture.talk().say("propose", "good")["arrow"], -2)
	assert_eq(DialogFixture.talk(60).say("ask_commitment")["arrow"], 0, "nothing moved")


## Merijn (2026-10-15): the first two talks (Act 0) cannot be ruined.
func test_a_tutorial_talk_cannot_be_ruined() -> void:
	var d := DialogFixture.talk(35, {}, DialogFixture.def({"tutorial": true}))
	var r := DialogFixture.play(d, ["show_data:custom_design:0", "propose:good", "pressure", "confront"])
	assert_eq([r["ended"], r["openness"]], [false, Dialog.RUINED_BELOW])
	assert_eq(d.patience, Dialog.TUTORIAL_PATIENCE - 4, "more time to learn")


func test_the_meter_shows_feeling_after_the_fact() -> void:
	var m := DialogFixture.talk().meter()
	assert_eq(m, {"openness": 35, "band": 1, "band_label": "Op z'n hoede", "trust": 50, "trust_pips": 2,
		"mood": "neutraal", "trace": [35]})
	assert_eq(Dialog.band_of(9), -1, "below 10 the talk is over")
	assert_eq(Dialog.band_of(80), 4)


## What would break a talk halfway is refused when the content loads.
func test_broken_content_is_refused_before_a_talk() -> void:
	var no_threshold := DialogFixture.dialog_data()
	no_threshold["layers"][0].erase("at")
	assert_ne(DialogDef.from_dict(no_threshold).error, "", "a layer without a threshold")
	var no_ways_in := DialogFixture.dialog_data()
	no_ways_in["layers"][1]["via"] = "silence"
	assert_ne(DialogDef.from_dict(no_ways_in).error, "", "via is a list of moves")
	var nameless := DialogFixture.dialog_data()
	nameless["proposals"][0].erase("id")
	assert_ne(DialogDef.from_dict(nameless).error, "", "a proposal without an id")
	assert_eq(Dialog.bank_error(DialogFixture.bank()), "")
	var bank := DialogFixture.bank()
	bank["special"].erase("repeat")
	assert_ne(Dialog.bank_error(bank), "", "every special line")
	bank = DialogFixture.bank()
	bank["player"].erase("silence")
	assert_ne(Dialog.bank_error(bank), "", "a line for every move")
	bank = DialogFixture.bank()
	bank["labels"]["bands"] = ["Dicht"]
	assert_ne(Dialog.bank_error(bank), "", "five bands")


func _pick_ids(d: Dialog, move: String) -> Array:
	for m: Dictionary in d.moves():
		if m["id"] == move:
			return m["picks"].map(func(p: Dictionary) -> String: return p["id"])
	return []


## R-D3 (dialog scripts §1.2): the first time a talk falls into "Dicht" the
## person says how they feel: a last chance, never a hint about the move.
func test_the_first_fall_into_dicht_brings_the_warning_line() -> void:
	var d := DialogFixture.talk(22, {}, DialogFixture.def({"warning": "Ik ga dit niet nog een keer uitleggen."}))
	var r := d.say("show_data", "custom_design:0")
	assert_eq([r["band"], r["reply"], r["ended"]], [0, "Ik ga dit niet nog een keer uitleggen.", false])
	r = d.say("mood")
	assert_eq(r["band"], 0)
	assert_ne(r["reply"], "Ik ga dit niet nog een keer uitleggen.", "once a talk")
	var plain := DialogFixture.talk(25)
	assert_ne(plain.say("show_data", "custom_design:0")["reply"], "", "no warning written: the usual reply")
