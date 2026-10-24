extends TestCase
## The principle line (phase-2 design §3.7): one sentence after a main mission's debrief
## naming which of the three principles paid or cost, chosen from what the play left,
## from the bank in missions.yaml.

const BANK := {"long_term_cost": ["kort"], "respect_blamed": ["schuld"], "respect_complied": ["{wie} volgt"],
	"improve_cost": ["los"], "respect_committed": ["{wie} draagt"], "improve_paid": ["opnieuw"], "long_term_paid": ["lang"]}


func _code(over: Dictionary) -> String:
	var facts := {"poor_fix": false, "fading": false, "blamed": false, "complied": "", "committed": "",
		"standardised": true, "failed_checks": 0}
	facts.merge(over, true)
	return PrincipleLine.code(facts)


func test_the_first_principle_that_the_play_shows_is_named() -> void:
	assert_eq(_code({}), "long_term_paid", "a patient, standardised fix")
	assert_eq(_code({"failed_checks": 1}), "improve_paid", "a failed Check learned from")
	assert_eq(_code({"committed": "Joost", "failed_checks": 1}), "respect_committed", "someone carries it")
	assert_eq(_code({"committed": "Joost", "standardised": false}), "improve_cost", "nobody holds it")
	assert_eq(_code({"complied": "Petra", "standardised": false}), "respect_complied")
	assert_eq(_code({"complied": "Petra", "committed": "Joost"}), "respect_committed", "one committed: it is carried")
	assert_eq(_code({"blamed": true, "complied": "Petra"}), "respect_blamed")
	assert_eq(_code({"poor_fix": true, "blamed": true}), "long_term_cost", "the quick fix first")
	assert_eq(_code({"fading": true}), "long_term_cost", "a fix chosen to fade while a lasting one fit")


func test_a_line_is_picked_per_mission_and_names_the_person() -> void:
	var bank := {"respect_committed": ["{wie} draagt het.", "Het is van {wie}."]}
	var line := PrincipleLine.line(bank, "respect_committed", "fix_a", "Joost")
	assert_true(line in ["Joost draagt het.", "Het is van Joost."], line)
	assert_eq(PrincipleLine.line(bank, "respect_committed", "fix_a", "Joost"), line, "the same each time")
	assert_eq(PrincipleLine.line({}, "long_term_paid", "fix_a", ""), "", "no bank, no line")


## Every real main mission with a problem gets its line after the debrief (the hook).
func test_every_main_debrief_ends_with_a_principle() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var bank := s.catalog.principles
	assert_eq(bank.keys().size(), PrincipleLine.CODES.size(), "the bank has every code")
	var lines := []
	for code: String in bank:
		lines.append_array(bank[code])
	var mains := 0
	for m: MissionDef in s.missions.defs.values():
		if m.kind != "main" or m.goal_problem.is_empty():
			continue
		mains += 1
		var debrief := s.mission_debrief(m.id)
		var line := s.principle_line(m.id)
		assert_ne(line, "", m.id)
		assert_false(line.contains("{"), "%s: %s" % [m.id, line])
		assert_true(debrief.ends_with(line), m.id)
		assert_true(lines.has(line), "%s: from the bank" % m.id)
	assert_true(mains >= 10, "the tier-1 mains")
	assert_eq(s.principle_line("walk_connections"), "", "a walk names no principle")
