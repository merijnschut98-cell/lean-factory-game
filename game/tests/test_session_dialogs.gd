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
	assert_eq(here.map(func(p: Dictionary) -> String: return p["id"]), ["joost", "frank", "anouk", "rob"])
	assert_false(here[0]["has_dialog"], "no mission of theirs is active")
	assert_eq(s.start_dialog("joost"), {"error": "nothing_to_say"})
	assert_true(_silo().people_at(DESIGN)[0]["has_dialog"])


func test_a_talk_opens_with_the_person_the_meter_and_the_moves() -> void:
	var s := _silo()
	var r := s.start_dialog("joost")
	assert_eq([r["dialog"], r["name"], r["opening"]], ["joost_output_kpi", "Joost van Dijk", "Ik heb tien minuten. Morgen is het MT."])
	assert_eq(r["meter"]["openness"], 36, "his morale 56 (a friendly first week) adds one")
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
	var r := _play(s, ["paraphrase", "inquiry", "show_data:silo_kpis:2", "inquiry", "silence",
		"propose:obeya_one_stream", "ask_commitment"])
	assert_eq(r["summary"]["outcome"], "commitment")
	assert_eq(s.region.trust["work_prep"], 1)
	assert_eq(s.talk_outcome("frank_kpi_targets"), "commitment")
	assert_eq(s.discoveries.to_dict()["last_talk"], {"frank": "commitment"}, "the discoveries hear of the talk")


func test_the_owner_s_buy_in_follows_the_fix() -> void:
	var s := _silo()
	s.start_dialog("joost")
	_play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	var st: ProblemState = s.region.state["silo_kpis"]
	st.phase = ProblemState.Phase.RESOLVED  # as if acted on
	st.a3 = {"cm": "obeya_end_to_end"}
	s.ask_coach()
	assert_eq(st.buy_in, "none", "an agreement under condition, still pending")
	var unowned: ProblemState = s.region.state["permits_in_batches"]
	unowned.phase = ProblemState.Phase.RESOLVED
	unowned.a3 = {"cm": "request_permits_daily"}
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
	s.missions.opened_at["save_henks_knowledge"] = s.region.net.time - SimCalendar.days(56 + 16)  # the farewell was 16 days ago
	s.ask_coach()
	assert_eq(s.energy_of("ahmed"), {"energy": 0.42, "needs_talk": true})
	assert_eq(s.people_at("outages.locate")[0]["energy"], 0.42)
	assert_eq(s.energy_of("nobody"), {})


## A mission's talk_to goal reads the session's talks (dialog spec §5.1).
func test_missions_read_how_talks_went() -> void:
	var s := _silo()
	assert_eq(s.missions.talk_outcome.call("joost_output_kpi"), "")
	s.start_dialog("joost")
	_play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	assert_eq(s.missions.talk_outcome.call("joost_output_kpi"), "partial")


## After a hard main-mission talk, Ruud's next question is about the talk;
## then he is back at the mission (dialog spec §5.6).
func test_ruud_asks_about_a_hard_talk_once() -> void:
	var s := _silo()
	var before := s.ask_coach()
	assert_ne(before["stage"], "talk")
	s.start_dialog("joost")
	_play(s, LISTEN_TO_JOOST + ["ask_commitment"])
	var about := s.ask_coach()
	assert_eq(about["stage"], "talk")
	assert_true("Joost" in about["text"], about["text"])
	assert_eq(s.ask_coach()["stage"], before["stage"], "one ask, then the mission again")
	assert_eq(s.ask_coach("fix_wrong_joint"), {"kind": "not_main"}, "never about a side mission")


## Talks speak of the player and the El Amrani dossier through tokens
## (creator spec §1.6; D9 talks audit #20, #28–#30), filled in one pass.
func test_talk_lines_fill_the_player_s_and_the_dossier_s_tokens() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.player.look["lichaam"] = "vrouw"
	var born := GameSession.date_of(s.followed.born)
	assert_eq(s.fill_tokens("Op {aanvraag_datum}."), "Op %d %s." % [born["day"], GameSession.MONTH_NAMES[born["month"] - 1]])
	assert_eq(s.fill_tokens("Dag, {jongen_meid}."), "Dag, meid.", "by the body made in the creator")
	s.player.look["lichaam"] = "man"
	assert_eq(s.fill_tokens("Dag, {jongen_meid}."), "Dag, jongen.")
	s.player.look["lichaam"] = "vrouw"
	s.missions.done_once["fix_wrong_joint"] = true
	assert_eq(s.accept("save_henks_knowledge"), "")
	var opened := s.start_dialog("henk")
	assert_eq(opened["dialog"], "henk_camera")
	assert_false("{" in str(opened["opening"]), opened["opening"])
	assert_true("meid" in str(opened["opening"]), "Henk's word for a young colleague, by the player's body")


## The dagstart names who could use a talk (spec §5.7), never more than one.
func test_the_dagstart_names_an_open_checkin() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.checkin_prompts(), [])
	s.missions.done_once["save_henks_knowledge"] = true
	s.ask_coach()
	assert_eq(s.checkin_prompts(), [], "Henk's farewell has not come yet (audit C11)")
	s.missions.opened_at["save_henks_knowledge"] = s.region.net.time - SimCalendar.days(56 + 16)
	s.ask_coach()
	var lines := s.checkin_prompts()
	assert_eq(lines.size(), 1)
	assert_eq([lines[0]["person"], lines[0]["name"]], ["ahmed", "Ahmed Bouzid"])
	assert_false(str(lines[0]["line"]).is_empty())



## A check-in counts days from a dated beat (drie winters S2, audit C11): the
## session hands People the beats Missions knows.
func test_a_checkin_counts_days_from_a_dated_beat() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var henk: MissionDef = s.missions.defs["save_henks_knowledge"]
	s.missions.done_once[henk.id] = true
	var ahmed := func() -> bool:
		return s.people_at(s.people.persons["ahmed"].place).filter(
			func(p: Dictionary) -> bool: return p["id"] == "ahmed")[0]["has_dialog"]
	assert_false(ahmed.call(), "Henk's mission never opened: no farewell yet")
	s.missions.opened_at[henk.id] = s.region.net.time - SimCalendar.days(henk.deadline_days + 15)
	assert_false(ahmed.call(), "fifteen days after the farewell")
	s.missions.opened_at[henk.id] -= SimCalendar.days(1)
	assert_true(ahmed.call(), "sixteen days after")


## A partial agreement speaks up when its condition comes true (audit C15),
## as an event the HUD toasts.
func test_a_beat_line_reaches_the_events() -> void:
	var s := _silo()
	s.people.outcomes["joost_output_kpi"] = "partial"
	s.people.outcomes["sanne_kpi"] = "partial"
	s.pass_time(1)
	s.drain_events()
	s.people.outcomes["frank_kpi_targets"] = "commitment"
	s.pass_time(1)
	var lines := s.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "beat_line")
	assert_eq(lines.map(func(e: Dictionary) -> String: return e["person"]), ["joost", "sanne"], "audit C15")
	assert_eq(UiText.event(lines[0], {}), "Joost van Dijk: “Frank heeft getekend. Nu sta ik er ook echt achter.”")



## Henk's last week, then his farewell (scripts §5, audit C11): his talk is
## open in the five days before it, he is gone after it, and only then does
## Ahmed's grief come up, sixteen days on.
func test_henk_s_last_week_then_ahmed_s_grief() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["save_henks_knowledge"] = true
	s.missions.progress["save_henks_knowledge"] = {"status": "completed", "asks": {}, "seen": {}}
	var farewell := func(days_ago: int) -> void:
		s.missions.opened_at["save_henks_knowledge"] = s.region.net.time - SimCalendar.days(56 + days_ago)
		s.pass_time(1)
	farewell.call(-3)
	assert_eq(s.people.dialog_for("henk", SessionTalks.world(s, s.people.persons["henk"])).id, "henk_last_week", "three days left")
	farewell.call(0)
	assert_true(s.people.has_left("henk"), "retired on his day")
	assert_true(s.checkin_prompts().all(func(p: Dictionary) -> bool: return p["person"] != "henk"))
	assert_false(s.people_at("outages.locate").any(func(p: Dictionary) -> bool: return p["id"] == "henk"))
