extends TestCase
## GameSession's dialog facade on the real content: who has something to say,
## a talk from the first move to its summary, and what it changes in the
## world (team trust, clues, the buy-in that sustains a fix).

const DESIGN := "connections.design"
const LISTEN_TO_JOOST := ["mood", "paraphrase", "inquiry", "reflect", "silence", "propose:lead_and_oldest"]


## A returning player's game with Act II's main mission open and Joost's own
## words found (the clue that opens his talk). The campaign up to there is
## not what these tests are about, so its first mission counts as done.
func _silo() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	return s


func _play(s: GameSession, moves: Array) -> Dictionary:
	return DialogFixture.play_with(s.choose_move, moves)


func test_people_at_a_place_say_whether_they_have_something_to_say() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var here := s.people_at(DESIGN)
	assert_eq(here.map(func(p: Dictionary) -> String: return p["id"]), ["joost", "frank"])
	assert_false(here[0]["has_dialog"], "no mission of theirs is active")
	assert_eq(s.start_dialog("joost"), {"error": "nothing_to_say"})
	assert_true(_silo().people_at(DESIGN)[0]["has_dialog"])


func test_a_talk_opens_with_the_person_the_meter_and_the_moves() -> void:
	var s := _silo()
	var r := s.start_dialog("joost")
	assert_eq([r["dialog"], r["name"], r["opening"]], ["joost_output_kpi", "Joost van Dijk", "Ik heb tien minuten. Morgen is het MT."])
	assert_eq(r["meter"]["openness"], 35)
	assert_eq(r["moves"].size(), Dialog.MOVES.size(), "every move, always")
	assert_eq(s.start_dialog("joost"), {"error": "in_dialog"})
	assert_eq(s.dialog_meter()["band_label"], "Op z'n hoede")
	assert_eq(s.dialog_moves().size(), Dialog.MOVES.size())


func test_bad_requests_change_nothing() -> void:
	var s := _silo()
	assert_eq(s.start_dialog("nobody"), {"error": "unknown_person"})
	assert_eq(s.choose_move("mood"), {"error": "no_dialog"})
	assert_eq(s.end_dialog(), {"error": "no_dialog"})
	assert_eq(s.dialog_meter(), {})
	s.start_dialog("joost")
	var before := s.region.net.time
	assert_eq(s.choose_move("shout"), {"error": "unknown_move"})
	assert_eq(s.choose_move("show_data", "silo_kpis:6"), {"error": "bad_pick"}, "a clue not found")
	assert_eq(s.region.net.time, before)


func test_the_clock_moves_once_when_the_talk_ends() -> void:
	var s := _silo()
	var before := s.region.net.time
	s.start_dialog("joost")
	_play(s, ["mood", "paraphrase"])
	assert_eq(s.region.net.time, before, "the world does not tick mid-sentence")
	var r := s.end_dialog()
	assert_eq([r["ended"], r["summary"]["outcome"]], [true, "heard"])
	assert_eq(s.region.net.time, before + 3 * Dialog.MINUTES_PER_MOVE)
	assert_eq(s.dialog_meter(), {}, "the talk is over")


func test_a_ruined_talk_waits_for_the_next_working_day() -> void:
	var s := _silo()
	s.start_dialog("joost")
	var r := _play(s, ["show_data:silo_kpis:4", "propose:lead_and_oldest", "pressure"])
	assert_eq(r["summary"]["outcome"], "ruined")
	assert_eq(s.start_dialog("joost"), {"error": "cooling_down"})
	s.region.advance(r["summary"]["cooldown_until"] - s.region.net.time)
	assert_eq(s.start_dialog("joost")["opening"], "Jij weer.")


func test_blaming_hits_the_team_as_a_blaming_question_does() -> void:
	var s := _silo()
	s.start_dialog("joost")
	_play(s, ["confront"])
	s.end_dialog()
	assert_eq(s.region.trust["work_prep"], -1)
	assert_true(s.region.state["silo_kpis"].blamed)


func test_a_learned_concern_becomes_a_clue_in_the_journal() -> void:
	var s := _silo()
	s.start_dialog("joost")
	var r := _play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	assert_eq(r["summary"]["outcome"], "partial", "Frank still has to agree")
	assert_true(s.clues_found("silo_kpis").any(func(c: Clue) -> bool: return c.dialog == "joost_output_kpi"))
	assert_eq(s.talk_outcome("joost_output_kpi"), "partial")


func test_a_commitment_builds_team_trust() -> void:
	var s := _silo()
	s.region.state["silo_kpis"].phase = ProblemState.Phase.CHECKED  # shown on one stream: Frank's route
	s.region.found["silo_kpis:2"] = true  # first time right, 85 → 80 %
	s.start_dialog("frank")
	var r := _play(s, ["open_question", "paraphrase", "inquiry", "show_data:silo_kpis:2", "inquiry", "silence",
		"propose:one_stream_board", "ask_commitment"])
	assert_eq(r["summary"]["outcome"], "commitment")
	assert_eq(s.region.trust["work_prep"], 1)
	assert_eq(s.talk_outcome("frank_kpi_targets"), "commitment")


func test_the_owner_s_buy_in_follows_the_fix() -> void:
	var s := _silo()
	s.start_dialog("joost")
	_play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	var st: ProblemState = s.region.state["silo_kpis"]
	st.phase = ProblemState.Phase.RESOLVED  # as if acted on
	st.a3 = {"cm": "obeya_end_to_end"}
	s.ask_coach()
	assert_eq(st.buy_in, "none", "an agreement under condition, still pending")
	var unowned: ProblemState = s.region.state["custom_design"]
	unowned.phase = ProblemState.Phase.RESOLVED
	unowned.a3 = {"cm": "standard_designs"}
	s.ask_coach()
	assert_eq(unowned.buy_in, "none", "nobody owns that fix in the dialogs")


func test_acting_without_asking_the_owner_shortens_the_fix() -> void:
	var s := _silo()
	var st: ProblemState = s.region.state["silo_kpis"]
	st.phase = ProblemState.Phase.RESOLVED
	st.a3 = {"cm": "obeya_end_to_end"}
	s.ask_coach()
	assert_eq(st.buy_in, "compliance")
	assert_near(s.region.life_days("silo_kpis"), Sustain.life_days(45.0, s.region.sustain("silo_kpis")["strength"]) * 0.6, 1e-6)


func test_the_mt_hears_how_talks_go() -> void:
	var s := _silo()
	var before := s.region.reputation.value
	s.start_dialog("joost")
	_play(s, ["show_data:silo_kpis:4", "propose:lead_and_oldest", "pressure"])
	assert_eq(s.region.reputation.value, before - 1, "a ruined talk")


func test_what_talks_teach_reaches_the_facts_missions_read() -> void:
	var s := _silo()
	assert_false(s.missions.knows("checked:silo_kpis"))
	s.region.state["silo_kpis"].phase = ProblemState.Phase.CHECKED
	assert_true(s.missions.knows("checked:silo_kpis"), "a passed Check is known live")
	s.start_dialog("joost")
	_play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	assert_true(s.missions.knows("heard:joost_kpi"), "a learned concern")
	assert_true(s.missions.knows("partial:joost_output_kpi"))


## Merijn (2026-10-15): people met while walking around show a low-energy
## bar, inviting a talk that lifts their spirit.
func test_walking_around_shows_who_is_low_on_energy() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.energy_of("ahmed"), {"energy": 0.42, "needs_talk": false}, "low, but Henk is still there")
	s.missions.done_once["save_henks_knowledge"] = true
	s.ask_coach()
	assert_eq(s.energy_of("ahmed"), {"energy": 0.42, "needs_talk": true})
	assert_eq(s.people_at("outages.locate")[0]["energy"], 0.42)
	assert_eq(s.energy_of("nobody"), {})
