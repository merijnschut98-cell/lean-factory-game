extends TestCase
## The real dialogs (content/dialogs.yaml) on the real rules: the worked
## paths of the audited scripts (docs/superpowers/specs/2026-10-15-dialog-
## scripts-act0-2.md §3.3, §3.4, §7), replayed on the engine with E1–E5 and
## person needs (PLAN 1.6c), and different routes reach the same place.

const JOOST_FOUND := {"silo_kpis:0": true, "silo_kpis:2": true, "silo_kpis:4": true}
## Friday 10:00 and the next Monday 08:30 (minutes).
const FRIDAY := 4 * SimCalendar.MINUTES_PER_DAY + 600
const MONDAY := 7 * SimCalendar.MINUTES_PER_DAY + 510


func _people() -> People:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	return People.new(c.persons, c.dialogs, c.dialog_bank)


func _world(extra: Dictionary = {}) -> Dictionary:
	var w := {"main": ["fix_silo_kpis"], "active": ["fix_silo_kpis"], "found": JOOST_FOUND, "facts": {},
		"team_trust": 0, "blamed": false, "now": FRIDAY}
	w.merge(extra, true)
	return w


func _talk(people: People, dialog_id: String, moves: Array, world: Dictionary = _world()) -> Dialog:
	var d := people.start(people.dialogs[dialog_id], world)
	DialogFixture.play(d, moves)
	return d


func test_the_game_knows_the_dialog_vocabulary() -> void:
	var vocab: Dictionary = JsonFile.read_dict("res://data/vocabulary.json")["data"]
	assert_eq(Dialog.MOVES, vocab["dialog_moves"])
	assert_eq(Dialog.LISTEN, vocab["dialog_moves"].slice(0, 8))
	assert_eq(Dialog.TAGS, vocab["dialog_tags"])
	assert_eq(Dialog.ARCHETYPES, vocab["dialog_archetypes"])
	assert_eq(Dialog.NEEDS, vocab["dialog_needs"])
	assert_eq(Dialog.KINDS, vocab["dialog_kinds"])
	assert_eq(Dialog.MOODS, vocab["dialog_moods"])
	assert_eq(Dialog.OUTCOMES, vocab["dialog_outcomes"])


func test_the_catalog_loads_the_cast_and_their_talks() -> void:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	assert_true(c.persons.any(func(p: PersonDef) -> bool: return p.id == "joost" and p.archetype == "defender"))
	assert_true(c.dialogs.any(func(d: DialogDef) -> bool: return d.id == "ahmed_after_henk" and d.kind == "checkin"))
	assert_eq(c.dialog_bank["labels"]["bands"].size(), 5)


func test_a_dialog_with_an_unknown_person_or_a_broken_bank_is_refused() -> void:
	var dir := scratch("dialog_catalog_test")
	DirAccess.make_dir_recursive_absolute(dir)
	for file in ["countermeasures", "missions", "value_streams", "kpis", "concepts", "discoveries", "problems_tier1"]:
		assert_eq(DirAccess.copy_absolute("res://data/%s.json" % file, "%s/%s.json" % [dir, file]), OK)
	var talk: Dictionary = JsonFile.read_dict("res://data/dialogs.json")["data"]
	for broken: Dictionary in [{"dialogs": [talk["dialogs"][0].merged({"person": "nobody"}, true)]}, {"bank": {}}]:
		var f := FileAccess.open(dir + "/dialogs.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(talk.merged(broken, true)))
		f.close()
		assert_ne(Catalog.load_from(dir).error, "", str(broken.keys()))
	DirAccess.remove_absolute(dir + "/dialogs.json")
	assert_eq(Catalog.load_from(dir).error, "", "without dialogs.json: no people, no error")


func test_a_concern_clue_is_found_only_by_listening() -> void:
	var c := Catalog.load_from()
	var silo: ProblemDef = c.problems.filter(func(p: ProblemDef) -> bool: return p.id == "silo_kpis")[0]
	var clue: Clue = silo.clues.filter(func(k: Clue) -> bool: return k.dialog == "joost_output_kpi")[0]
	var everything := {}
	for k in silo.clues:
		if k != clue:
			everything[k.id] = true
	assert_false(Investigation.revealable(clue, silo, everything), "no gemba tool or quick question finds it")
	assert_eq([clue.tool, clue.at, clue.key, clue.depth], ["conversation", "connections.design", true, 2])


# ── Sample 1: Joost and the output KPI (spec §7) ────────────────────────────

func test_joost_pushed_early_ends_ruined() -> void:
	var people := _people()
	var d := _talk(people, "joost_output_kpi", ["show_data:silo_kpis:2", "propose:lead_and_oldest", "pressure"])
	assert_eq([d.outcome, d.meter()["trace"]], ["ruined", [35, 23, 11, 0]], "path A")
	assert_eq(people.finish(d, FRIDAY)["trust"], 37)


func test_joost_listened_to_the_next_day_agrees_under_condition() -> void:
	var people := _people()
	people.finish(_talk(people, "joost_output_kpi", ["show_data:silo_kpis:2", "propose:lead_and_oldest", "pressure"]), FRIDAY)
	var d := _talk(people, "joost_output_kpi", ["repair", "mood", "paraphrase", "inquiry", "reflect", "silence",
		"propose:lead_and_oldest"], _world({"now": MONDAY}))
	assert_eq(d.meter()["trace"], [27, 39, 47, 54, 62, 75, 87, 95], "path B: heard first, then the question lands")
	var r := d.say("ask_commitment")
	assert_eq([r["outcome"], r["reply"]], ["partial", "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst."])
	var summary := people.finish(d, MONDAY)
	assert_eq([summary["trust"], summary["clue"], summary["facts"]], [45, "silo_kpis:7", ["heard:joost_kpi"]])


func test_another_route_reaches_joosts_concern() -> void:
	var people := _people()
	people.finish(_talk(people, "joost_output_kpi", ["show_data:silo_kpis:2", "propose:lead_and_oldest", "pressure"]), FRIDAY)
	var d := _talk(people, "joost_output_kpi", ["repair", "mood", "paraphrase", "inquiry", "empathy"], _world({"now": MONDAY}))
	assert_eq(d.meter()["trace"].slice(4), [62, 74], "empathy for his feeling brings the cue")
	var r := d.say("inquiry")
	assert_eq(r["revealed"], "concern", "a question after his hesitation is another way in")
	var first := _talk(_people(), "joost_output_kpi", ["empathy", "open_question", "reflect", "silence",
		"propose:lead_and_oldest", "ask_commitment"])
	assert_eq(first.outcome, "partial", "a third way: being seen first")


func test_joost_under_pressure_complies() -> void:
	var people := _people()
	var d := _talk(people, "joost_output_kpi", ["open_question", "pressure", "propose:lead_and_oldest", "ask_commitment"])
	assert_eq([d.outcome, d.meter()["trace"]], ["compliance", [35, 41, 26, 14, 14]], "path C")
	assert_eq(people.finish(d, FRIDAY)["trust"], 37)
	assert_eq(people.buy_in("silo_kpis", people.facts()), "compliance")


func test_frank_blocks_until_shown_and_his_okay_completes_joosts_agreement() -> void:
	var people := _people()
	var frank_moves := ["paraphrase", "inquiry", "show_data:silo_kpis:2", "inquiry", "silence",
		"propose:obeya_one_stream", "ask_commitment"]
	var blocked := _talk(people, "frank_kpi_targets", frank_moves)
	assert_eq(blocked.outcome, "blocked")
	var summary := people.finish(blocked, FRIDAY)
	assert_eq(summary["hints"], ["Laat het me zien op één stroom.",
		"Als Sanne en Joost het zelf komen uitleggen, sta ik er niet alleen voor."])
	assert_eq(summary["facts"], ["heard:frank_budget"], "the fact the interim MT reads (drie-winters §5.2)")
	var shown := _world({"facts": {"checked:silo_kpis": true}})
	var agreed := _talk(people, "frank_kpi_targets",
		["paraphrase", "inquiry", "show_data:silo_kpis:2", "propose:obeya_one_stream", "ask_commitment"], shown)
	assert_eq(agreed.outcome, "commitment", "a route is met: the person can commit")
	people.finish(agreed, FRIDAY)
	var joost := _talk(people, "joost_output_kpi", ["empathy", "open_question", "reflect", "silence",
		"propose:lead_and_oldest", "ask_commitment"])
	assert_eq(joost.outcome, "commitment", "Frank's okay was Joost's condition")


# ── Sample 2: a check-in with Ahmed (spec §8) ───────────────────────────────

func _ahmed_world(extra: Dictionary = {}) -> Dictionary:
	return _world({"main": [], "active": [], "found": {}, "facts": {"done:save_henks_knowledge": true}}).merged(extra, true)


func test_ahmed_has_a_checkin_once_henk_has_gone() -> void:
	var people := _people()
	assert_eq(people.dialog_for("ahmed", _world({"main": [], "active": []})), null, "Henk is still there")
	assert_eq(people.dialog_for("ahmed", _ahmed_world()).id, "ahmed_after_henk")
	assert_eq(people.start(people.dialogs["ahmed_after_henk"], _ahmed_world()).openness, 43)


func test_fixing_mode_is_not_the_moment() -> void:
	var people := _people()
	var d := _talk(people, "ahmed_after_henk", ["mood", "propose:extra_course", "propose_experiment:ride_along", "close"],
		_ahmed_world())
	assert_eq([d.outcome, d.meter()["trace"]], ["none", [43, 51, 39, 27, 27]])


func test_listening_lifts_ahmed() -> void:
	var people := _people()
	var d := _talk(people, "ahmed_after_henk", ["mood", "open_question", "reflect", "silence", "empathy", "experience", "close"],
		_ahmed_world())
	assert_eq(d.outcome, "lifted")
	var summary := people.finish(d, FRIDAY)
	assert_eq([summary["morale"], summary["trust"], summary["facts"]], [57, 65, ["heard:ahmed_night"]])


func test_when_henk_taught_ahmed_the_checkin_is_about_pride() -> void:
	var people := _people()
	var d := people.start(people.dialogs["ahmed_after_henk"],
		_ahmed_world({"facts": {"done:save_henks_knowledge": true, "chose:knowledge_drain:skills_matrix_buddy": true}}))
	assert_eq([d.mood, d.position()["text"]], ["goed", "Goed, eigenlijk."])
	DialogFixture.play(d, ["mood", "open_question", "reflect", "silence"])
	assert_eq(d.unlocked_facts(), ["heard:ahmed_trainer"])
