extends TestCase
## The mission board and missed deadlines (CLAUDE.md §2): a missed deadline
## closes a door, but the mission comes back without its clock, so the board
## shows it as open (or active) with what was lost, never as a dead entry.

const HENK := "save_henks_knowledge"


## A returning player's game where Henk's deadline has passed.
func _henk_missed() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	for id in s.missions.defs[HENK].requires_missions:
		s.missions.done_once[id] = true
	s.missions.update()  # the clock starts when the mission opens
	s.region.advance_days(s.missions.defs[HENK].deadline_days + 1)
	s.missions.update()
	assert_true(s.missions.failed(HENK))
	return s


func _board(s: GameSession) -> MissionBoard:
	var board := MissionBoard.new()
	board.session = s
	board.refresh()
	return board


func test_a_missed_mission_stays_on_the_board_with_what_was_lost() -> void:
	var s := _henk_missed()
	var board := _board(s)
	assert_true(HENK in board.listed(), "it can still be taken on")
	var fail_text: String = s.missions.defs[HENK].fail_text
	assert_true(shows(board, MissionBoard.EXPIRED % fail_text), "the door it closed, once")
	assert_false(shows(board, "Voltooid: " + s.missions.defs[HENK].name), "not done, nor a dead entry")
	board.free()


func test_a_missed_mission_taken_on_keeps_its_note_and_completes_as_done() -> void:
	var s := _henk_missed()
	var board := _board(s)
	assert_eq(board.accept(HENK), "")
	assert_true(shows(board, s.missions.defs[HENK].fail_text), "the active card says Henk has left")
	s.region.state[s.missions.defs[HENK].goal_problem].phase = ProblemState.Phase.RESOLVED
	s.missions.update()
	board.refresh()
	assert_true(shows(board, "Voltooid: " + s.missions.defs[HENK].name), "solved another way: done")
	board.free()


func test_a_mission_on_time_has_no_expiry_note() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var board := _board(s)
	assert_false(shows(board, MissionBoard.EXPIRED.get_slice("%", 0)), "no deadline missed")
	board.free()


func test_a_missed_mission_without_a_fail_line_still_says_its_clock_stopped() -> void:
	var m := MissionDef.from_dict({"id": "x", "name": "X", "kind": "side", "tier": 1, "briefing": "",
		"debrief": "", "goal": {"type": "walk", "stream": "connections"}, "rewards": {"xp": 0, "budget": 0}})
	assert_eq(MissionBoard.expiry_note(m), MissionBoard.EXPIRED % MissionBoard.NO_CLOCK)
