extends TestCase
## The expert talk (phase 2 design §2.5, PLAN §4.3 "seven dialog shapes"):
## topic by topic, no meters, no win or lose. The player picks a question,
## the expert answers in their own voice; a topic can unlock a clue (once),
## a fact or an explainer, and can wait for a fact or for trust.


static func expert(extra: Dictionary = {}) -> DialogDef:
	var d := {
		"id": "pim_expert", "name": "Pim legt uit", "person": "pim", "kind": "expert",
		"opening": "Vraag maar.", "retry_opening": "Nog meer vragen?", "closing": "Graag gedaan.",
		"topics": [
			{"id": "cable", "ask": "Hoe oud is die kabel?", "answer": "Van 1968."},
			{"id": "joint", "ask": "Welke mof hoort daarbij?", "answer": "Een overgangsmof.",
				"unlocks": {"clue": "custom_design:5", "facts": ["heard:pim_joint"]}},
			{"id": "trench", "ask": "Wat ligt er in je sleuf?", "answer": "Oude kabel.",
				"unlocks": {"explainer": "spanning_stroom_weerstand"}},
			{"id": "secret", "ask": "Wat zou jij anders doen?", "answer": "Voordoen.",
				"needs": {"all": ["heard:talk"]}},
			{"id": "close", "ask": "Wat moet Ahmed leren?", "answer": "Voelen.", "trust": 70},
		],
	}
	d.merge(extra, true)
	return DialogDef.from_dict(d)


func _people(defs: Array = [expert()], trust: int = 50) -> People:
	return DialogFixture.people(defs, [DialogFixture.person("craftsman", trust)])


func _world(extra: Dictionary = {}) -> Dictionary:
	return DialogFixture.world({"found": {}}.merged(extra, true))


func _asks(t: ExpertTalk) -> Array:
	return t.offer().map(func(o: Dictionary) -> String: return o["pick"])


func test_an_expert_talk_needs_topics_not_layers() -> void:
	var d := expert()
	assert_eq(d.error, "")
	assert_eq(d.topics.size(), 5)
	assert_true(DialogDef.from_dict({"id": "x", "person": "pim", "kind": "expert", "topics": []}).error.contains("topic"),
		"an expert talk without topics")
	assert_true(DialogFixture.def().error.is_empty(), "a persuasion is as before")


func test_it_offers_at_most_four_open_topics_as_questions() -> void:
	var t := _people().start_expert(expert(), _world())
	var offers := t.offer()
	assert_eq(offers.size(), 3, "the gated two are hidden")
	assert_eq(offers.map(func(o: Dictionary) -> String: return o["line"]),
		["Hoe oud is die kabel?", "Welke mof hoort daarbij?", "Wat ligt er in je sleuf?"])
	assert_true(offers.all(func(o: Dictionary) -> bool: return o["move"] == ExpertTalk.ASK))
	var all_open := _people([expert()], 80).start_expert(expert(), _world({"facts": {"heard:talk": true}}))
	assert_eq(all_open.offer().size(), ExpertTalk.OFFERED, "never more than four")


func test_a_gated_topic_waits_for_its_fact_and_for_trust() -> void:
	assert_false("secret" in _asks(_people().start_expert(expert(), _world())))
	var heard := _people().start_expert(expert(), _world({"facts": {"heard:talk": true}}))
	assert_true("secret" in _asks(heard), "the fact opens it")
	assert_false("close" in _asks(heard), "trust 50 is below its 70")
	var p := _people([expert({"topics": [expert().topics[4]]})], 70)
	assert_eq(_asks(p.start_expert(p.dialogs["pim_expert"], _world())), ["close"], "trust 70 opens it")


func test_the_expert_answers_with_no_meter_and_no_outcome() -> void:
	var t := _people().start_expert(expert(), _world())
	var r := t.say(ExpertTalk.ASK, "cable")
	assert_eq(r["reply"], "Van 1968.")
	assert_eq(r["line"], "Hoe oud is die kabel?")
	assert_false(r["ended"])
	for key in ["openness", "arrow", "outcome", "band"]:
		assert_false(r.has(key), "no " + key)
	assert_false("cable" in _asks(t), "an answered topic is not offered again")
	var end := t.say(ExpertTalk.CLOSE)
	assert_true(end["ended"])
	assert_eq(end["reply"], "Graag gedaan.")
	assert_eq(t.offer(), [])


func test_bad_questions_change_nothing() -> void:
	var t := _people().start_expert(expert(), _world())
	assert_eq(t.say(ExpertTalk.ASK, "nope"), {"error": "bad_pick"})
	assert_eq(t.say(ExpertTalk.ASK, "secret"), {"error": "bad_pick"}, "a gated topic")
	assert_eq(t.say("pressure"), {"error": "unknown_move"})
	assert_eq(t.asked, [])


func test_a_topic_unlocks_its_clue_once_and_its_fact_and_explainer() -> void:
	var p := _people()
	var t := p.start_expert(expert(), _world())
	var r := t.say(ExpertTalk.ASK, "joint")
	assert_eq(r["clue"], "custom_design:5")
	assert_eq(r["facts"], ["heard:pim_joint"])
	assert_eq(t.say(ExpertTalk.ASK, "trench")["explainer"], "spanning_stroom_weerstand")
	var found := p.start_expert(expert(), _world({"found": {"custom_design:5": true}}))
	assert_eq(found.say(ExpertTalk.ASK, "joint")["clue"], "", "a clue already found is not new")
	p.finish_expert(t, 0)
	assert_true(p.facts().has("heard:pim_joint"), "the topic's fact holds after the talk")


func test_what_was_asked_is_remembered_across_talks() -> void:
	var p := _people()
	var t := p.start_expert(expert(), _world())
	t.say(ExpertTalk.ASK, "cable")
	t.say(ExpertTalk.ASK, "joint")
	t.say(ExpertTalk.CLOSE)
	var result := p.finish_expert(t, 600)
	assert_eq(result["asked"], ["cable", "joint"])
	assert_eq(p.asked_topics("pim_expert"), ["cable", "joint"])
	var again := p.start_expert(expert(), _world())
	assert_eq(_asks(again), ["trench"], "only what is still open")
	assert_eq(p.opening(p.dialogs["pim_expert"]), "Nog meer vragen?")
	var saved := People.new([DialogFixture.person("craftsman")] as Array[PersonDef], [expert()] as Array[DialogDef], DialogFixture.bank())
	saved.load_dict(p.to_dict())
	assert_eq(saved.asked_topics("pim_expert"), ["cable", "joint"], "kept in the save, as what they told you")


func test_the_answers_go_to_what_they_told_you() -> void:
	var p := _people()
	var t := p.start_expert(expert(), _world())
	t.say(ExpertTalk.ASK, "cable")
	p.finish_expert(t, 600)
	var told: Array = p.observed["pim"]
	assert_eq(told.map(func(o: Dictionary) -> String: return o["text"]), ["Van 1968."])


func test_being_asked_about_the_craft_builds_a_little_trust() -> void:
	var p := _people()
	var t := p.start_expert(expert(), _world())
	t.say(ExpertTalk.ASK, "cable")
	assert_eq(t.trust, 50 + ExpertTalk.TRUST_PER_TOPIC)
	t.say(ExpertTalk.ASK, "joint")
	var result := p.finish_expert(t, 0)
	assert_eq(result["trust"], 50 + 2 * ExpertTalk.TRUST_PER_TOPIC)
	assert_eq(p.trust["pim"], result["trust"])
	assert_eq(p.outcomes, {}, "no outcome recorded: nothing won or lost")


func test_the_talk_takes_minutes_per_topic() -> void:
	var t := _people().start_expert(expert(), _world())
	t.say(ExpertTalk.ASK, "cable")
	t.say(ExpertTalk.ASK, "joint")
	assert_eq(t.minutes(), 2 * ExpertTalk.MINUTES_PER_TOPIC)


func test_a_persuasion_or_check_in_comes_before_the_expert_talk() -> void:
	var p := _people([expert(), DialogFixture.def()])
	assert_eq(p.dialog_for("pim", _world()).id, "talk", "the mission's talk first")
	assert_eq(p.dialog_for("pim", _world({"main": [], "active": []})).id, "pim_expert", "then the expert")


func test_an_expert_with_nothing_left_to_ask_has_no_talk() -> void:
	var p := _people([expert({"topics": [expert().topics[0]]})])
	var t := p.start_expert(p.dialogs["pim_expert"], _world())
	t.say(ExpertTalk.ASK, "cable")
	p.finish_expert(t, 0)
	assert_eq(p.dialog_for("pim", _world()), null)


func test_an_expert_talk_bound_to_a_mission_waits_for_it() -> void:
	var p := _people([expert({"mission": "fix_design"})])
	assert_eq(p.dialog_for("pim", _world()).id, "pim_expert")
	assert_eq(p.dialog_for("pim", _world({"main": [], "active": []})), null)


# ── The content: Wim and Henk ───────────────────────────────────────────────

func test_henk_and_wim_have_expert_talks_with_four_or_five_topics() -> void:
	var c := Catalog.load_from(Catalog.DATA_DIR)
	for id in ["henk_expert", "wim_expert"]:
		var d: DialogDef = c.dialogs.filter(func(x: DialogDef) -> bool: return x.id == id)[0]
		assert_eq([d.kind, d.error], [ExpertTalk.KIND, ""], id)
		assert_true(d.topics.size() >= 4 and d.topics.size() <= 5, id + ": four or five topics")
		assert_false(d.closing.is_empty(), id + " says goodbye")


func test_henk_talks_about_the_craft_and_about_ahmed_once_he_said_what_he_fears() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var world: Dictionary = s.call("_world", s.people.persons["henk"])
	var t := s.people.start_expert(s.people.dialogs["henk_expert"], world)
	var asks := _asks(t)
	assert_eq(asks, ["joints", "old_cable", "digging", "trench"], "Ahmed waits for what Henk fears")
	s.people.heard_facts["heard:henk_teach"] = true
	var heard := s.people.start_expert(s.people.dialogs["henk_expert"], world)
	assert_eq(heard.open_topics().size(), 5, "Ahmed's topic opens")
	assert_eq(_asks(heard).size(), ExpertTalk.OFFERED, "and waits for a free place among the four questions")
	var r := t.say(ExpertTalk.ASK, "joints")
	assert_true(str(r["clue"]).begins_with("wrong_joint_in_van:"), "the joint topic gives a clue (no cable explainer yet)")


func test_wim_explains_only_after_he_felt_heard() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var world: Dictionary = s.call("_world", s.people.persons["wim"])
	assert_eq(s.people.dialog_for("wim", world), null, "the persuasion is not on, and he was not heard yet")
	s.people.heard_facts["heard:wim_spreadsheet"] = true
	assert_eq(s.people.dialog_for("wim", world).id, "wim_expert")


# ── Through the session ─────────────────────────────────────────────────────

## A returning player's game where Petra (nothing to discuss) knows about meters.
func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	var d := expert({"id": "petra_expert", "person": "petra",
		"topics": [{"id": "molen", "ask": "Wat is de Molen?", "answer": "Het register.",
			"unlocks": {"clue": "silent_meter:0", "facts": ["heard:petra_molen"]}},
			{"id": "map", "ask": "Wat staat er in je map?", "answer": "Alles."}]})
	s.people.dialogs[d.id] = d
	return s


func test_the_session_opens_an_expert_talk_with_questions_and_no_moves() -> void:
	var s := _session()
	var r := s.start_dialog("petra")
	assert_eq([r["dialog"], r["kind"], r["opening"]], ["petra_expert", "expert", "Vraag maar."])
	assert_eq(r["moves"], [], "no palette of moves")
	assert_eq(s.dialog_offers().map(func(o: Dictionary) -> String: return o["line"]),
		["Wat is de Molen?", "Wat staat er in je map?"])
	assert_eq(s.dialog_meter()["trust_pips"], floori(s.people.trust["petra"] / float(Dialog.TRUST_PER_PIP)))
	assert_eq(s.start_dialog("petra"), {"error": "in_dialog"})


func test_a_topic_s_clue_lands_in_the_journal_when_it_is_answered() -> void:
	var s := _session()
	s.start_dialog("petra")
	assert_false(s.region.found.has("silent_meter:0"))
	var r := s.choose_move(ExpertTalk.ASK, "molen")
	assert_eq(r["clue"], "silent_meter:0")
	assert_true(s.region.found.has("silent_meter:0"), "found at once")
	assert_eq(s.choose_move("mood"), {"error": "unknown_move"})


func test_rounding_off_ends_it_and_the_clock_moves_by_the_answers() -> void:
	var s := _session()
	var before := s.region.net.time
	s.start_dialog("petra")
	s.choose_move(ExpertTalk.ASK, "molen")
	var r := s.end_dialog()
	assert_true(r["ended"])
	assert_eq(r["summary"]["asked"], ["molen"])
	assert_eq(s.region.net.time - before, ExpertTalk.MINUTES_PER_TOPIC)
	assert_true(s.people.facts().has("heard:petra_molen"))
	assert_eq(s.dialog_offers(), [])
	assert_eq(s.start_dialog("petra")["dialog"], "petra_expert", "one topic is still open")
	assert_eq(s.dialog_offers().size(), 1)
