extends TestCase
## The people the player talks with (rules/people.gd): trust, morale and
## memory across talks, who has something to say, what an outcome changes, and
## the buy-in that sustains a fix (spec §3.6, §4, §5.2, §5.4).

## Friday 10:00 of the first week (the simulation week starts on Monday).
const FRIDAY := 4 * SimCalendar.MINUTES_PER_DAY + 600
const MONDAY_0830 := 7 * SimCalendar.MINUTES_PER_DAY + 510
## From a start of 40: listen, earn the concern, propose what meets it, ask.
const LISTENING := ["mood", "reflect", "open_question", "reflect", "silence", "propose:good", "ask_commitment"]
const RUIN := ["show_data:custom_design:0", "propose:good", "pressure"]
const COMPLY := ["open_question", "pressure", "propose:good", "ask_commitment"]


func _talk(people: People, moves: Array, world: Dictionary = DialogFixture.world(), def: DialogDef = null) -> Dictionary:
	var d := people.start(def if def != null else people.dialogs["talk"], world)
	DialogFixture.play(d, moves)
	return people.finish(d, int(world["now"]))


# ── Ruud names a move after an Act 0 talk (tutorial talks spec §3) ─────────

func test_ruud_names_the_day_s_move_when_it_landed() -> void:
	var people := DialogFixture.people([DialogFixture.def({"tutorial": true, "teaches": ["reflect"]})])
	assert_eq(_talk(people, ["mood", "reflect", "open_question"])["ruud_names"], "naam reflect Pim")


func test_else_ruud_names_the_move_that_landed_most() -> void:
	var people := DialogFixture.people([DialogFixture.def({"tutorial": true, "teaches": ["silence"]})])
	assert_eq(_talk(people, ["open_question", "mood"])["ruud_names"], "naam mood Pim", "mood +8 over open question +6")


func test_ruud_asks_instead_when_nothing_landed_and_never_names_after_act_0() -> void:
	var tutorial := DialogFixture.people([DialogFixture.def({"tutorial": true, "teaches": ["mood"]})])
	assert_eq(_talk(tutorial, ["pressure"])["ruud_names"], "niets Pim", "a question, no name")
	assert_eq(_talk(DialogFixture.people(), ["mood"])["ruud_names"], "", "not a tutorial talk")


## A talk may stay open over several missions' days (Rachid, Tuesday to
## Thursday: D9 talks audit §2.9).
func test_a_talk_also_open_during_later_missions() -> void:
	var people := DialogFixture.people([DialogFixture.def({"also_during": ["wed", "thu"]})])
	for day in ["fix_design", "wed", "thu"]:
		assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": [day]})).id, "talk", day)
	assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": ["fri"]})), null)


## A talk on more than one mission (arc S11: `missions:`, the first owns it):
## open during either, and the main mission's talk when either is the main one.
func test_a_talk_on_two_missions_is_open_during_either() -> void:
	var data := DialogFixture.dialog_data({"missions": ["fix_design", "winter"]})
	data.erase("mission")
	var two := DialogDef.from_dict(data)
	assert_eq(two.mission, "fix_design", "the first owns it")
	assert_eq(Array(two.missions), ["fix_design", "winter"])
	assert_eq(Array(DialogFixture.def().missions), ["fix_design"], "a talk on one mission")
	var people := DialogFixture.people([two])
	for on in ["fix_design", "winter"]:
		assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": [on]})).id, "talk", on)
	assert_eq(people.dialog_for("pim", DialogFixture.world({"main": [], "active": ["fri"]})), null)
	var side := DialogFixture.def({"id": "side_talk", "mission": "fri"})
	var both := DialogFixture.people([side, two])
	assert_eq(both.dialog_for("pim", DialogFixture.world({"main": ["winter"], "active": ["fri", "winter"]})).id,
		"talk", "the main mission's talk first, whichever of its missions is main")


# ── Promises the game checks later (D9 talks audit A4; the check is 2.4b) ────

func test_an_agreed_promise_is_kept_with_the_day_it_was_made() -> void:
	var data := DialogFixture.dialog_data()
	data["proposals"][0]["promise"] = {"kind": "callback", "days": 3}
	var people := DialogFixture.people([DialogFixture.def(data)])
	assert_eq(people.promises(), {})
	_talk(people, LISTENING, DialogFixture.world({"now": FRIDAY}))
	assert_eq(people.promises(), {"talk": {"proposal": "good", "kind": "callback", "days": 3, "at": FRIDAY}})
	var bare := DialogFixture.people()
	_talk(bare, LISTENING, DialogFixture.world({"now": FRIDAY}))
	assert_eq(bare.promises(), {}, "an agreement that promises nothing")


## The simulation judged a promised date (Missions: promise_kept / promise_broken):
## kept, the person trusts you more; broken, the next talk opens 15 lower, once, and a
## variant keyed on the fact lets her say so (dialog spec §6; drie winters §3).
func test_a_judged_promise_moves_the_person() -> void:
	var data := DialogFixture.dialog_data()
	data["proposals"][0]["promise"] = {"kind": "delivery_date", "days": 3}
	data["variants"] = [{"needs": {"all": ["promise_broken:talk"]}, "opening": "U zei vrijdag. Het is dinsdag."}]
	for kept in [true, false]:
		var people := DialogFixture.people([DialogFixture.def(data)])
		_talk(people, LISTENING, DialogFixture.world({"now": FRIDAY}))
		var who: String = people.dialogs["talk"].person
		var trust: int = people.trust[who]
		var before := people.start(people.dialogs["talk"], DialogFixture.world()).openness
		people.judge_promise("talk", kept)
		people.judge_promise("talk", kept)  # once
		assert_eq(people.trust[who], trust + (People.PROMISE_KEPT_TRUST if kept else 0), "kept: trust")
		var facts := {} if kept else {"promise_broken:talk": true}
		var d := people.start(people.dialogs["talk"], DialogFixture.world({"facts": facts}))
		assert_eq(d.openness, before + (1 if kept else -15), "kept: +5 trust is +1 open; broken: remembered")
		assert_eq(people.opening(people.dialogs["talk"], d.version) == "U zei vrijdag. Het is dinsdag.", not kept)
		var restored := DialogFixture.people([DialogFixture.def(data)])
		restored.load_dict(people.to_dict())
		assert_eq(restored.judged, people.judged, "saved")


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


func test_a_mentor_starts_open() -> void:
	var ruud := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("mentor")])
	assert_eq(ruud.start(ruud.dialogs["talk"], DialogFixture.world()).openness, 55, "drie winters §4.2: base 55")


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
	_talk(people, ["mood", "reflect", "open_question", "close"])
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
	var later := _talk(people, ["repair", "mood", "reflect", "open_question", "reflect", "silence", "propose:good", "ask_commitment"])
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
	DialogFixture.play(d, ["mood", "reflect", "open_question", "reflect", "silence", "close"])
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
	assert_eq(_days(people, 0, People.LEAVE_DAYS), [], "not before LEAVE_DAYS")
	assert_true(people.ignored["pim"] >= 2, "check-ins that expired unanswered")
	assert_eq(_days(people, People.LEAVE_DAYS, People.LEAVE_DAYS + 10), [{"type": "left", "person": "pim"}])
	assert_true(people.has_left("pim"))
	assert_eq(people.dialog_for("pim", DialogFixture.world()), null, "a door closes")
	assert_eq(people.buy_in("custom_design", people.facts()), "none", "the fix they owned has no owner now")


func test_better_morale_or_answered_checkins_keep_them() -> void:
	var people := _low_pim()
	_days(people, 0, 30)
	people.morale["pim"] = 25
	_days(people, 30, 31)
	people.morale["pim"] = 15
	assert_eq(_days(people, 31, 31 + People.LEAVE_DAYS - 1), [], "the clock starts again")
	var heard := _low_pim()
	for day in People.LEAVE_DAYS + 10:
		var world := DialogFixture.world({"now": SimCalendar.days(day)})
		heard.daily(world)
		var d := heard.start(heard.dialogs["checkin"], world)
		d.say("close")
		heard.finish(d, SimCalendar.days(day))
	assert_false(heard.has_left("pim"), "every prompt answered")


## QA 2.12 (b): ignoring people is not free. Morale drifts daily with the team's load
## above the norm, a fix won by pressure and check-ins left to expire; it creeps back
## when the load is fine, and never in the training week.
func _drift_days(people: People, days: int, extra: Dictionary = {}) -> void:
	for day in days + 1:
		people.daily(DialogFixture.world({"now": SimCalendar.days(day)}).merged(extra, true))


func test_a_team_planned_above_the_norm_wears_its_people_down() -> void:
	var busy := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 60)])
	_drift_days(busy, 40, {"loads": {"prep": 1.0}})
	assert_eq(busy.morale["pim"], 60 - roundi(40 * People.LOAD_DRIFT), "a quarter point a day at full load")
	var calm := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 60)])
	_drift_days(calm, 40, {"loads": {"prep": People.LOAD_NORM}})
	assert_eq(calm.morale["pim"], 60, "at the norm nothing wears")
	var week := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 60)])
	_drift_days(week, 40, {"loads": {"prep": 1.3}, "training": true})
	assert_eq(week.morale["pim"], 60, "a friendly training week")


func test_the_load_alone_wears_no_one_below_the_floor() -> void:
	var people := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 35)])
	_drift_days(people, 200, {"loads": {"prep": 1.3}})
	assert_eq(people.morale["pim"], People.NEGLECT_FLOOR, "tired, not gone: people leave rarely")


func test_morale_creeps_back_when_the_load_is_fine_but_never_above_the_start() -> void:
	var people := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 60)])
	people.morale["pim"] = 50
	_drift_days(people, 200, {"loads": {"prep": 0.5}})
	assert_eq(people.morale["pim"], 60)


func test_a_fix_won_by_pressure_and_an_ignored_check_in_cost_morale() -> void:
	var people := DialogFixture.people([DialogFixture.def()], [DialogFixture.person("defender", 50, 60)])
	people.outcomes["talk"] = "compliance"
	_drift_days(people, 60)
	assert_eq(people.morale["pim"], 60 - roundi(60 * People.COMPLIED_DRIFT), "a yes under pressure keeps costing")
	var ignored := _low_pim()
	ignored.morale["pim"] = 40
	ignored.daily(DialogFixture.world({"now": 0}))
	ignored.prompts["checkin"] = 0
	ignored.daily(DialogFixture.world({"now": SimCalendar.days(People.PROMPT_DAYS)}))
	assert_eq(ignored.morale["pim"], 40 + People.IGNORED_MORALE, "a check-in left to expire")


func test_leaving_survives_a_save() -> void:
	var people := _low_pim()
	_days(people, 0, People.LEAVE_DAYS + 10)
	var restored := _low_pim()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict()))), [])
	assert_eq(restored.to_dict(), people.to_dict())
	assert_true(restored.has_left("pim"))


# ── The coach after a hard main-mission talk (spec §5.6) ─────────────────────

func _coached(moves: Array, main: bool = true, def: DialogDef = null) -> People:
	var people := DialogFixture.people([DialogFixture.def(), DialogFixture.checkin()])
	var d := people.start(def if def != null else people.dialogs["talk"], DialogFixture.world())
	DialogFixture.play(d, moves)
	people.finish(d, 0, "fix_design" if main else "")
	return people


## A talk on more than one mission (`missions:`, arc S11) whose main mission is not its
## first: the coach still asks about it (S2-L's note: the first was stored, so the question
## was dropped).
func test_the_coach_asks_about_a_talk_on_more_missions_by_its_main_one() -> void:
	var def := DialogFixture.def({"mission": null, "missions": ["walk_side", "fix_design"]})
	var people := DialogFixture.people([def, DialogFixture.checkin()])
	var d := people.start(people.dialogs["talk"], DialogFixture.world())
	DialogFixture.play(d, COMPLY)
	people.finish(d, 0, "fix_design")
	assert_eq(people.coach_question("fix_design")["stage"], "talk", "Ruud asks about the main mission's talk")


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
	people.finish(d, 0, "fix_design")
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


## A friendly first week (PLAN 2.13 D): everyone the player meets in the training week (a
## talk of a training day, or Ruud's introductions on the first walk) starts in a good
## enough mood; bad moods come later, with reasons.
func test_the_training_weeks_people_start_in_a_friendly_mood() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	var met := {"sanne": true, "joost": true, "anouk": true}   # Ruud introduces them, and they talk this week
	for d: DialogDef in s.people.dialogs.values():
		if d.mission.begins_with("training_") or Array(d.also_during).any(func(m: String) -> bool:
				return m.begins_with("training_")):
			met[d.person] = true
	for id: String in met:
		assert_true(s.people.morale[id] >= People.FRIENDLY_MORALE, "%s starts at %d" % [id, s.people.morale[id]])


## No check-in prompt while the training week runs;
## the low colleague's comes once it is over.
func test_no_checkin_prompt_during_the_training_week() -> void:
	var people := _three_low()
	people.daily(DialogFixture.world({"now": 0, "training": true}))
	assert_eq(_open(people), [], "the training week asks nobody to talk")
	people.daily(DialogFixture.world({"now": SimCalendar.days(1)}))
	assert_eq(_open(people), ["c_pim"], "after it, the lowest first")


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


## An expired prompt costs no trust (it was never a promise), but it costs morale: the
## person asked for a moment and got none (QA 2.12 (b)).
func test_an_expired_prompt_costs_morale_not_trust() -> void:
	var people := _three_low()
	_days(people, 0, 5)
	assert_eq([people.morale["pim"], people.trust["pim"]], [20, 50], "already below the floor: neglect takes no more")
	var pressed := _low_pim()
	pressed.outcomes["talk"] = "compliance"  # Pim's fix was won by pressure
	_days(pressed, 0, 5)
	assert_eq(pressed.morale["pim"], 15 + People.IGNORED_MORALE, "after pressure, an ignored check-in still costs")


## Neglect alone (load, ignored check-ins) makes people tired, never gone: only a
## fix won by pressure takes them below the floor (people leave rarely).
func test_neglect_alone_stops_at_the_floor() -> void:
	var people := DialogFixture.people([DialogFixture.def(), DialogFixture.checkin({"trigger": {"morale_below": 101}})],
		[DialogFixture.person("defender", 50, 40)])
	_drift_days(people, 300, {"loads": {"prep": 1.3}})
	assert_eq(people.morale["pim"], People.NEGLECT_FLOOR)
	assert_false(people.has_left("pim"))


# ── What the player saw and heard (person-needs spec §4, §6): the Mensen tab ─

## Pim's talk with a tell in his position and in his reply to the mood question.
func _telling() -> People:
	return DialogFixture.people([DialogFixture.def({
		"position": {"text": "Positie.", "tags": ["claim"], "tell": "facts"},
		"replies": {"mood": {"lands": {"text": "Hoeveel precies?", "tags": ["feeling"], "tell": "facts"}},
			"experience": {"misses": {"text": "Hm."}}}})])


func _texts(people: People) -> Array:
	return people.observed.get("pim", []).map(func(o: Dictionary) -> String: return o["text"])


func test_what_the_player_heard_is_noted_once_with_the_day_and_the_place() -> void:
	var people := _telling()
	_talk(people, LISTENING, DialogFixture.world({"now": FRIDAY}))
	assert_eq(_texts(people), ["Positie.", "Hoeveel precies?", "Belang.", "Zorg."], "the position, a tell, the layers")
	assert_eq(people.observed["pim"][1], {"dialog": "talk", "key": "replies.mood.lands", "text": "Hoeveel precies?",
		"at": FRIDAY, "place": "connections.design"})
	_talk(people, ["mood", "close"], DialogFixture.world({"now": MONDAY_0830}))
	assert_eq(people.observed["pim"].size(), 4, "a line enters once")


func test_a_line_without_a_tell_is_not_noted() -> void:
	var people := _telling()
	_talk(people, ["experience", "close"])
	assert_eq(_texts(people), ["Positie."])


func test_each_talk_is_kept_with_its_curve_and_its_moves() -> void:
	var people := DialogFixture.people()
	_talk(people, LISTENING, DialogFixture.world({"now": FRIDAY}))
	var past: Dictionary = people.talk_log["pim"][0]
	assert_eq([past["dialog"], past["at"], past["outcome"]], ["talk", FRIDAY, "commitment"])
	assert_eq(past["moves"], ["mood", "reflect", "open_question", "reflect", "silence", "propose", "ask_commitment"])
	assert_eq(past["trace"].size(), LISTENING.size() + 1, "the start, then each move")
	for i in People.TALK_LOG_MAX + 2:
		_talk(people, ["close"])
	assert_eq(people.talk_log["pim"].size(), People.TALK_LOG_MAX, "the oldest go")
	assert_eq(people.talk_log["pim"][-1]["moves"], ["close"], "the newest last")


func test_the_player_s_note_is_their_own_words() -> void:
	var people := DialogFixture.people()
	assert_true(people.set_note("pim", "  Wil eerst cijfers zien.  "))
	assert_eq(people.note["pim"], "Wil eerst cijfers zien.")
	people.set_note("pim", "x".repeat(People.NOTE_MAX + 50))
	assert_eq(people.note["pim"].length(), People.NOTE_MAX, "kept to a note's length")
	people.set_note("pim", " ")
	assert_false(people.note.has("pim"), "an empty note is no note")
	assert_false(people.set_note("ghost", "Wie?"), "only someone the game knows")


func test_what_was_heard_and_the_note_survive_a_save() -> void:
	var people := _telling()
	_talk(people, LISTENING, DialogFixture.world({"now": FRIDAY}))
	people.set_note("pim", "Wil het zwart op wit.")
	var restored := _telling()
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict()))), [])
	assert_eq(restored.to_dict(), people.to_dict())
	assert_eq(restored.note["pim"], "Wil het zwart op wit.")


func test_a_save_from_before_the_notebook_fills_it_from_what_was_revealed() -> void:
	var people := DialogFixture.people()
	assert_eq(people.load_dict({"revealed": {"talk/-1": {"interest": true}}}), [])
	assert_eq(_texts(people), ["Positie.", "Belang."])
	assert_eq(people.observed["pim"][0]["at"], -1, "heard, but not when")


func test_a_hand_edited_save_falls_back_and_never_crashes() -> void:  # review N1
	var people := DialogFixture.people()
	var dropped := people.load_dict({"memory": {"pim": {"flags": 5, "cooldown_until": {}}},
		"revealed": {"talk/7": {"interest": true}, "talk/x": {"interest": true}, "talk/-1": 3}})
	assert_eq(people.memory["pim"], {"flags": [], "cooldown_until": 0}, "malformed fields keep the defaults")
	assert_eq(dropped, ["talk/7", "talk/x"], "a variant the content does not have is dropped")
	assert_true(people.revealed.is_empty())
	assert_true(people.observed.is_empty())


func test_a_malformed_notebook_keeps_what_is_sound() -> void:
	var people := DialogFixture.people()
	var dropped := people.load_dict({"observed": {"pim": [{"text": 3}, {"dialog": "talk", "key": "position",
		"text": "Positie.", "at": 5, "place": "connections.design"}, "x"], "ghost": []},
		"talk_log": {"pim": [{"dialog": "talk", "at": 1, "outcome": "heard", "trace": [40, 45], "moves": ["mood"]}, 7]},
		"note": {"pim": 12, "ghost": "Wie?"}})
	assert_eq(dropped, ["ghost", "ghost"])
	assert_eq(_texts(people), ["Positie."])
	assert_eq(people.talk_log["pim"].size(), 1)
	assert_false(people.note.has("pim"), "a note is text")



# ── Dated beats and lines after a later fact (drie winters S2; audit C11, C15) ─

## A check-in that waits for a dated beat: Ahmed grieves first (C11).
func test_a_checkin_can_wait_days_after_a_dated_beat() -> void:
	var trigger := {"beat": "farewell", "after_days": 16, "morale_below": 50}
	var low := DialogFixture.people([DialogFixture.checkin({"trigger": trigger})], [DialogFixture.person("defender", 50, 20)])
	var farewell := SimCalendar.days(10)
	assert_eq(low.dialog_for("pim", DialogFixture.world({"now": SimCalendar.days(40)})), null, "no date for the beat yet")
	var beats := {"beats": {"farewell": farewell}}
	assert_eq(low.dialog_for("pim", DialogFixture.world(beats.merged({"now": farewell + SimCalendar.days(16) - 1}))), null,
		"sixteen days after the farewell, not before")
	assert_eq(low.dialog_for("pim", DialogFixture.world(beats.merged({"now": farewell + SimCalendar.days(16)}))).id, "checkin")
	var fine := DialogFixture.people([DialogFixture.checkin({"trigger": trigger})], [DialogFixture.person("defender", 50, 60)])
	assert_eq(fine.dialog_for("pim", DialogFixture.world(beats.merged({"now": SimCalendar.days(40)}))), null,
		"the beat opens the window; morale still decides")


func _signs() -> People:
	return DialogFixture.people([DialogFixture.def({"condition_needs": {"all": ["committed:boss"]},
		"beats_after": [{"when": "committed:boss", "text": "De baas heeft getekend."}]})])


func _beat_lines(people: People, facts: Dictionary, now: int = 0) -> Array:
	return people.daily({"now": now, "facts": facts}).filter(func(e: Dictionary) -> bool: return e["type"] == "beat_line")


## C15: a partial agreement that upgrades when the boss signs is felt: the
## person says so, once, and the notebook keeps it.
func test_a_partial_agreement_speaks_up_when_its_condition_comes_true() -> void:
	var people := _signs()
	assert_eq(_beat_lines(people, {"committed:boss": true}), [], "never talked: nothing to upgrade")
	assert_eq(_talk(people, LISTENING)["outcome"], "partial")
	assert_eq(_beat_lines(people, {}), [], "the boss has not signed")
	var now := SimCalendar.days(3)
	assert_eq(_beat_lines(people, {"committed:boss": true}, now),
		[{"type": "beat_line", "person": "pim", "name": "Pim", "dialog": "talk", "text": "De baas heeft getekend."}])
	assert_eq(_beat_lines(people, {"committed:boss": true}, now), [], "said once")
	var heard: Array = people.observed["pim"].filter(func(o: Dictionary) -> bool: return o["key"] == "beat")
	assert_eq(heard.map(func(o: Dictionary) -> Array: return [o["text"], o["at"]]), [["De baas heeft getekend.", now]])
	var restored := _signs()
	restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict())))
	assert_eq(_beat_lines(restored, {"committed:boss": true}, now), [], "a save remembers it was said")


## Only the upgrade of a partial is a beat: a commitment or a ruined talk has
## nothing to upgrade.
func test_no_beat_line_without_a_partial_agreement() -> void:
	var ruined := _signs()
	_talk(ruined, RUIN)
	assert_eq(_beat_lines(ruined, {"committed:boss": true}), [])



## Henk's last week (scripts §5): a check-in open from five days before a
## beat until the beat itself, never after it.
func test_a_checkin_can_open_in_the_days_before_a_beat() -> void:
	var people := DialogFixture.people([DialogFixture.checkin({"trigger": {"beat": "farewell", "before_days": 5}})])
	var farewell := SimCalendar.days(30)
	var at := func(now: int) -> DialogDef:
		return people.dialog_for("pim", DialogFixture.world({"now": now, "beats": {"farewell": farewell}}))
	assert_eq(at.call(farewell - SimCalendar.days(5) - 1), null, "not yet: more than five days before")
	assert_eq(at.call(farewell - SimCalendar.days(5)).id, "checkin")
	assert_eq(at.call(farewell - 1).id, "checkin", "the last evening")
	assert_eq(at.call(farewell), null, "the day itself: he has gone")


## A person who leaves on a dated beat (Henk retires) is gone once it has
## passed: no talks, no prompts, and the save remembers it.
func test_a_person_who_leaves_on_a_beat_is_gone_after_it() -> void:
	var henk := PersonDef.from_dict({"id": "pim", "name": "Pim", "role": "monteur", "place": "connections.design",
		"team": "prep", "archetype": "craftsman", "leaves_on": "farewell"})
	var people := DialogFixture.people([DialogFixture.checkin({"trigger": {"morale_below": 101}})], [henk])
	var farewell := SimCalendar.days(30)
	var before := {"now": farewell - 1, "facts": {}, "beats": {"farewell": farewell}}
	people.daily(before)
	assert_false(people.has_left("pim"))
	assert_eq(people.prompts.keys(), ["checkin"], "still here: he can be asked")
	people.daily({"now": farewell, "facts": {}, "beats": {"farewell": farewell}})
	assert_true(people.has_left("pim"), "retired on his day")
	assert_eq(people.prompts.keys(), [], "his open prompt goes with him")
	assert_eq(people.dialog_for("pim", DialogFixture.world({"now": farewell, "beats": {"farewell": farewell}})), null)
	var restored := DialogFixture.people([DialogFixture.checkin({"trigger": {"morale_below": 101}})], [henk])
	restored.load_dict(bytes_to_var(var_to_bytes(people.to_dict())))
	assert_true(restored.has_left("pim"))
