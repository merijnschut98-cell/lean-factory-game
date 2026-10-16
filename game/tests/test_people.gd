extends TestCase
## The people the player talks with (rules/people.gd): trust, morale and
## memory across talks, who has something to say, what an outcome changes, and
## the buy-in that sustains a fix (spec §3.6, §4, §5.2, §5.4).

## Friday 10:00 of the first week (the simulation week starts on Monday).
const FRIDAY := 4 * SimCalendar.MINUTES_PER_DAY + 600
const MONDAY_0830 := 7 * SimCalendar.MINUTES_PER_DAY + 510
## From a start of 40: listen, earn the concern, propose what meets it, ask.
const LISTENING := ["mood", "reflect", "inquiry", "reflect", "silence", "propose:good", "ask_commitment"]
const RUIN := ["show_data:custom_design:0", "propose:good", "pressure"]
const COMPLY := ["open_question", "pressure", "propose:good", "ask_commitment"]


func _talk(people: People, moves: Array, world: Dictionary = DialogFixture.world(), def: DialogDef = null) -> Dictionary:
	var d := people.start(def if def != null else people.dialogs["talk"], world)
	DialogFixture.play(d, moves)
	return people.finish(d, int(world["now"]))


# ── The start of a talk ─────────────────────────────────────────────────────

func test_the_start_reads_the_person_the_day_and_the_team() -> void:
	var people := DialogFixture.people()
	assert_eq(people.start(people.dialogs["talk"], DialogFixture.world()).openness, 40, "a defender on an ordinary day")
	var tense := DialogFixture.people([DialogFixture.def({"mood": "gespannen"})])
	assert_eq(tense.start(tense.dialogs["talk"], DialogFixture.world()).openness, 35, "the scene's mood, first talk")
	var warm := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 60, 70)])
	assert_eq(warm.start(warm.dialogs["talk"], DialogFixture.world({"team_trust": 1})).openness, 54,
		"40 + 10 × team trust + (60 − 50) / 5 + (70 − 50) / 10")
	var blamed := DialogFixture.people()
	assert_eq(blamed.start(blamed.dialogs["talk"], DialogFixture.world({"blamed": true})).mood, "gespannen",
		"their team was blamed")
	var cold := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("cynic", 0, 0)])
	assert_eq(cold.start(cold.dialogs["talk"], DialogFixture.world({"team_trust": -2})).openness, 5, "never below 5")


func test_a_ruined_talk_costs_a_few_points_and_a_day() -> void:
	var people := DialogFixture.people()
	var summary := _talk(people, RUIN, DialogFixture.world({"now": FRIDAY}))
	assert_eq([summary["outcome"], summary["trust"], summary["reputation"]], ["ruined", 37, -1])
	assert_eq(summary["cooldown_until"], MONDAY_0830, "the next working day at 08:30")
	assert_true(people.cooling_down("pim", MONDAY_0830 - 1))
	assert_false(people.cooling_down("pim", MONDAY_0830))


func test_the_person_remembers_and_a_repair_is_offered() -> void:
	var people := DialogFixture.people()
	_talk(people, RUIN, DialogFixture.world({"now": FRIDAY}))
	var d := people.start(people.dialogs["talk"], DialogFixture.world({"now": MONDAY_0830}))
	assert_eq(d.openness, 27, "40 − 2.6 (trust 37) − 10 (ruined)")
	assert_true(d.moves().any(func(m: Dictionary) -> bool: return m["id"] == "repair"))
	assert_eq(people.opening(people.dialogs["talk"]), "Jij weer.")


func test_revealed_layers_stay_revealed() -> void:
	var people := DialogFixture.people()
	_talk(people, ["mood", "reflect", "inquiry", "close"])
	assert_eq(people.start(people.dialogs["talk"], DialogFixture.world()).revealed, {"interest": true})


# ── Outcomes ────────────────────────────────────────────────────────────────

func test_commitment_builds_trust_morale_and_reputation() -> void:
	var people := DialogFixture.people()
	var summary := _talk(people, LISTENING)
	assert_eq([summary["outcome"], summary["trust"], summary["morale"], summary["reputation"], summary["team_trust"]],
		["commitment", 60, 60, 1, 1])
	assert_eq(summary["clue"], "custom_design:5", "the learned concern")
	assert_eq(summary["facts"], ["heard:talk"])
	var facts := people.facts()
	assert_true(facts.has("committed:talk") and facts.has("heard:talk"))
	assert_eq(people.agreed_kpis("prep", facts), ["prep_output"], "the KPIs the lead committed to")


func test_compliance_is_remembered_and_can_be_repaired() -> void:
	var people := DialogFixture.people()
	var summary := _talk(people, COMPLY)
	assert_eq([summary["outcome"], summary["trust"], summary["morale"], summary["reputation"]], ["compliance", 37, 40, 0])
	assert_true(people.facts().has("complied:talk"))
	assert_eq(people.buy_in("custom_design", people.facts()), "compliance")
	var later := _talk(people, ["repair", "mood", "reflect", "inquiry", "reflect", "silence", "propose:good", "ask_commitment"])
	assert_eq(later["outcome"], "commitment")
	assert_eq(people.buy_in("custom_design", people.facts()), "commitment", "a later commitment repairs the buy-in")


func test_confronting_someone_lowers_their_morale() -> void:
	var people := DialogFixture.people()
	var summary := _talk(people, ["confront", "close"])
	assert_true(summary["confronted"])
	assert_eq(summary["morale"], 40)


# ── Buy-in ──────────────────────────────────────────────────────────────────

func test_acting_without_asking_the_owner_is_compliance() -> void:
	var people := DialogFixture.people()
	assert_eq(people.buy_in("custom_design", people.facts()), "compliance", "nobody asked the person whose work changes")
	assert_eq(people.buy_in("incomplete_application", people.facts()), "", "a problem nobody owns")


func test_an_agreement_under_condition_upgrades_by_itself() -> void:
	var people := DialogFixture.people([DialogFixture.def({"condition_needs": {"all": ["committed:boss"]}})])
	assert_eq(_talk(people, LISTENING)["outcome"], "partial")
	assert_eq(people.buy_in("custom_design", people.facts()), "none", "pending")
	var met := people.facts({"committed:boss": true})
	assert_true(met.has("committed:talk"))
	assert_eq(people.effective_outcome("talk", met), "commitment")
	assert_eq(people.buy_in("custom_design", met), "commitment")


func test_first_see_then_believe_waits_for_a_passed_check() -> void:
	var people := DialogFixture.people()
	assert_eq(_talk(people, ["paraphrase", "open_question", "inquiry", "propose:bare", "ask_commitment"])["outcome"], "partial")
	assert_eq(people.effective_outcome("talk", people.facts()), "partial")
	assert_eq(people.effective_outcome("talk", people.facts({"checked:custom_design": true})), "commitment")


# ── Who has something to say ────────────────────────────────────────────────

func test_a_persuasion_belongs_to_its_active_mission() -> void:
	var side := DialogFixture.def({"id": "side_talk", "mission": "side_m"})
	var people := DialogFixture.people([DialogFixture.def(), side])
	var both := DialogFixture.world({"active": ["fix_design", "side_m"]})
	assert_eq(people.dialog_for("pim", both).id, "talk", "the main mission first")
	assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": ["side_m"]})).id, "side_talk")
	assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": []})), null)
	var gated := DialogFixture.people([DialogFixture.def({"requires_clue": "custom_design:3"})])
	assert_eq(gated.dialog_for("pim", DialogFixture.world()), null, "the clue that opens it is not found yet")
	assert_ne(gated.dialog_for("pim", DialogFixture.world({"found": {"custom_design:3": true}})), null)
	_talk(people, LISTENING)
	assert_eq(people.dialog_for("pim", DialogFixture.world()), null, "nothing more to win once committed")


func test_a_checkin_opens_on_its_trigger_and_rests_after_it_lifted() -> void:
	var low := DialogFixture.people([DialogFixture.checkin()], [DialogFixture.person("defender", 50, 20)])
	assert_eq(low.dialog_for("pim", DialogFixture.world()).id, "checkin")
	var d := low.start(low.dialogs["checkin"], DialogFixture.world())
	DialogFixture.play(d, ["mood", "reflect", "inquiry", "reflect", "silence", "close"])
	var summary := low.finish(d, 0)
	assert_eq([summary["outcome"], summary["morale"], summary["trust"]], ["lifted", 35, 55])
	assert_eq(low.dialog_for("pim", DialogFixture.world({"now": SimCalendar.days(13)})), null, "14 days of rest")
	assert_eq(low.dialog_for("pim", DialogFixture.world({"now": SimCalendar.days(14)})).id, "checkin")
	var fine := DialogFixture.people([DialogFixture.checkin()], [DialogFixture.person("defender", 50, 60)])
	assert_eq(fine.dialog_for("pim", DialogFixture.world()), null, "morale is fine")


func test_a_variant_follows_the_facts() -> void:
	var variant := {"needs": {"all": ["chose:custom_design:standard_designs"]}, "mood": "goed",
		"position": {"text": "Goed.", "tags": ["claim"]}}
	var people := DialogFixture.people([DialogFixture.def({"variants": [variant]})])
	var d := people.start(people.dialogs["talk"], DialogFixture.world({"facts": {"chose:custom_design:standard_designs": true}}))
	assert_eq([d.mood, d.openness, d.position()["text"]], ["goed", 50, "Goed."])


# ── Save ────────────────────────────────────────────────────────────────────

func test_people_survive_a_save() -> void:
	var people := DialogFixture.people()
	_talk(people, RUIN, DialogFixture.world({"now": FRIDAY}))
	var restored := DialogFixture.people()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict()))), [])
	assert_eq(restored.to_dict(), people.to_dict())
	assert_true(restored.cooling_down("pim", FRIDAY + 60))


func test_an_old_save_loads_with_defaults_and_unknown_ids_are_dropped() -> void:
	var people := DialogFixture.people()
	assert_eq(people.load_dict({}), [])
	assert_eq(people.trust["pim"], 50)
	assert_eq(people.load_dict({"trust": {"ghost": 3, "pim": "x"}, "outcomes": {"gone": "commitment"}}), ["ghost", "gone"])
	assert_eq(people.trust["pim"], 50, "a malformed value keeps the default")


# ── Leaving (Merijn, 2026-10-15): rarely, closing a door, never the game ────

func _days(people: People, first: int, last: int) -> Array:
	var events := []
	for day in range(first, last):
		events.append_array(people.daily(DialogFixture.world({"now": SimCalendar.days(day)})))
	return events


func _low_pim() -> People:
	return DialogFixture.people([DialogFixture.def(), DialogFixture.checkin()], [DialogFixture.person("defender", 50, 15)])


func test_a_colleague_left_low_and_unheard_leaves() -> void:
	var people := _low_pim()
	assert_eq(_days(people, 0, 60), [], "not before 60 days")
	assert_true(people.ignored["pim"] >= 2, "check-ins that expired unanswered")
	assert_eq(_days(people, 60, 70), [{"type": "left", "person": "pim"}])
	assert_true(people.has_left("pim"))
	assert_eq(people.dialog_for("pim", DialogFixture.world()), null, "a door closes")
	assert_eq(people.buy_in("custom_design", people.facts()), "none", "the fix they owned has no owner now")


func test_better_morale_or_answered_checkins_keep_them() -> void:
	var people := _low_pim()
	_days(people, 0, 30)
	people.morale["pim"] = 25
	_days(people, 30, 31)
	people.morale["pim"] = 15
	assert_eq(_days(people, 31, 80), [], "the 60 days start again")
	var heard := _low_pim()
	for day in 70:
		var world := DialogFixture.world({"now": SimCalendar.days(day)})
		heard.daily(world)
		var d := heard.start(heard.dialogs["checkin"], world)
		d.say("close")
		heard.finish(d, SimCalendar.days(day))
	assert_false(heard.has_left("pim"), "every prompt answered")


func test_leaving_survives_a_save() -> void:
	var people := _low_pim()
	_days(people, 0, 70)
	var restored := _low_pim()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict()))), [])
	assert_eq(restored.to_dict(), people.to_dict())
	assert_true(restored.has_left("pim"))


# ── The coach after a hard main-mission talk (spec §5.6) ─────────────────────

func _coached(moves: Array, main: bool = true, def: DialogDef = null) -> People:
	var people := DialogFixture.people([DialogFixture.def(), DialogFixture.checkin()])
	var d := people.start(def if def != null else people.dialogs["talk"], DialogFixture.world())
	DialogFixture.play(d, moves)
	people.finish(d, 0, main)
	return people


func test_the_coach_asks_once_about_a_main_mission_talk() -> void:
	var people := _coached(LISTENING.slice(0, 5) + ["propose:bare", "ask_commitment"])
	assert_eq(people.outcomes["talk"], "partial")
	assert_eq(people.coach_question("fix_design"), {"kind": "question", "stage": "talk", "text": "Wat wilde je dat Pim dacht?"})
	assert_eq(people.coach_question("fix_design"), {}, "one ask, then back to the mission")
	var again := _coached(LISTENING)
	assert_eq(again.coach_question("fix_design")["text"], "Wiens idee was het?", "after a commitment")
	assert_eq(_coached(LISTENING).coach_question("next_main"), {}, "a talk of an earlier main mission is past")


func test_the_coach_reads_how_the_talk_went() -> void:
	assert_eq(_coached(COMPLY).coach_question("fix_design")["text"], "Pim zei ja. En het gezicht?")
	assert_eq(_coached(RUIN).coach_question("fix_design")["text"], "Wie praatte er?")
	assert_eq(_coached(["mood", "close"]).coach_question("fix_design"), {}, "a talk that only listened is not a hard one")


func test_the_coach_never_asks_about_a_side_talk_or_a_checkin() -> void:
	assert_eq(_coached(COMPLY, false).coach_question("fix_design"), {}, "a side mission's talk")
	var people := DialogFixture.people([DialogFixture.checkin()], [DialogFixture.person("defender", 50, 30)])
	var d := people.start(people.dialogs["checkin"], DialogFixture.world())
	DialogFixture.play(d, ["confront", "confront"])
	assert_eq(d.outcome, "ruined")
	people.finish(d, 0, true)
	assert_eq(people.coach_question("fix_design"), {})


func test_the_coach_s_question_survives_a_save() -> void:
	var people := _coached(COMPLY)
	var copy := DialogFixture.people([DialogFixture.def(), DialogFixture.checkin()])
	copy.load_dict(people.to_dict())
	assert_eq(copy.coach_question("fix_design")["stage"], "talk")


# ── Check-in cadence (spec §5.7): ≤ 1 prompt visible, ≤ 2 a week, 14 days per person

## Three low colleagues, each with a check-in.
func _three_low() -> People:
	var who := []
	var talks := []
	for id in ["pim", "ria", "bas"]:
		who.append(PersonDef.from_dict({"id": id, "name": id.capitalize(), "role": "r", "place": "connections.design",
			"team": "prep", "archetype": "defender", "trust": 50, "morale": {"pim": 20, "ria": 30, "bas": 40}[id]}))
		talks.append(DialogFixture.checkin({"id": "c_" + id, "person": id, "prompt": id.capitalize() + " is stil."}))
	return DialogFixture.people(talks, who)


func _open(people: People) -> Array:
	var ids := people.prompts.keys()
	ids.sort()
	return ids


func test_one_checkin_prompt_at_a_time_the_lowest_first() -> void:
	var people := _three_low()
	_days(people, 0, 1)
	assert_eq(_open(people), ["c_pim"], "one at a time, whoever is lowest")
	assert_eq(people.prompt_lines(), [{"person": "pim", "dialog": "c_pim", "line": "Pim is stil."}], "the dagstart line")


func test_at_most_two_prompts_a_week() -> void:
	var people := _three_low()
	_days(people, 0, 4)  # pim's prompt expires on day 3, ria's opens
	assert_eq(_open(people), ["c_ria"])
	var d := people.start(people.dialogs["c_ria"], DialogFixture.world({"now": SimCalendar.days(4)}))
	d.say("close")
	people.finish(d, SimCalendar.days(4))
	_days(people, 4, 7)
	assert_eq(_open(people), [], "two prompts this week already")
	_days(people, 7, 8)
	assert_eq(_open(people), ["c_bas"])


func test_a_person_gets_a_prompt_at_most_every_fourteen_days() -> void:
	var people := DialogFixture.people([DialogFixture.checkin()], [DialogFixture.person("defender", 50, 20)])
	_days(people, 0, 14)
	assert_eq(people.ignored["pim"], 1, "the prompt of day 0 expired, and no new one before day 14")
	_days(people, 14, 15)
	assert_eq(_open(people), ["checkin"])


func test_an_expired_prompt_costs_nothing() -> void:
	var people := _three_low()
	_days(people, 0, 5)
	assert_eq([people.morale["pim"], people.trust["pim"]], [20, 50])
