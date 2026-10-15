extends TestCase
## Hidden rewards (audit §4; Merijn, 2026-10-15): quiet discoveries for deep
## thinking, shown in the codex as silhouettes with a hint once their act is
## over. Real content, a returning player's game.

const DESIGN := "connections.design"


func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	return s


func _found(s: GameSession) -> Array:
	return s.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "discovery").map(
		func(e: Dictionary) -> String: return e["id"])


func _entry(s: GameSession, id: String) -> Dictionary:
	for d in s.discoveries_view():
		if d["id"] == id:
			return d
	return {}


## The gemba runs 24/7: a visit to the outage stream at night.
func test_a_night_at_the_outage_stream_is_a_discovery() -> void:
	var s := _session()
	s.use_tool("outages.locate", "shadow")
	assert_eq(_found(s), [], "by day it is just a visit")
	var minute := s.region.net.time % SimCalendar.MINUTES_PER_DAY
	s.region.advance(23 * 60 - minute)
	s.use_tool("outages.locate", "shadow")
	assert_eq(_found(s), ["nachtdienst"])
	assert_true(_entry(s, "nachtdienst")["found"])
	s.region.advance(SimCalendar.days(1))
	s.use_tool("outages.locate", "shadow")
	assert_eq(_found(s), [], "once")


## Unfound discoveries are silhouettes; their hint shows once their act is over.
func test_silhouettes_get_their_hint_after_their_act() -> void:
	var s := _session()
	var entry := _entry(s, "het_eerste_net")
	assert_eq([entry["found"], entry["hint"]], [false, ""])
	assert_false(entry.has("name"), "a silhouette: no name yet")
	for m: MissionDef in s.missions.defs.values():
		if m.kind == "main" and m.act == 2:
			s.missions.done_once[m.id] = true
	assert_ne(_entry(s, "het_eerste_net")["hint"], "")


## The most important arrow is the one back (audit D6): a failed Check, a new
## key clue at the gemba, then a pass with the right cause.
func test_going_back_to_the_gemba_after_a_failed_check() -> void:
	var s := _session()
	s.accept("fix_custom_design")
	s.use_tool(DESIGN, "time_study")
	var p: ProblemDef = s.region.problems["custom_design"]
	var cause: int = Investigation.cause_options(p, s.region.problem_list())["correct"]
	var a3 := {"waste": "overprocessing", "cause": cause, "evidence": ["custom_design:0"], "cm": "poka_yoke_application",
		"prediction": "throughput"}
	assert_eq(s.submit_a3("custom_design", a3), "")
	s.wait_for_check("custom_design")
	assert_false(s.check("custom_design")["passed"], "a mismatch")
	s.use_tool(DESIGN, "documents")  # one why deeper
	a3["cm"] = "standard_designs"
	a3["evidence"] = s.clues_found("custom_design").map(func(c: Clue) -> String: return c.id)
	assert_eq(s.submit_a3("custom_design", a3), "")
	s.wait_for_check("custom_design")
	s.drain_events()
	assert_true(s.check("custom_design")["passed"])
	assert_true("terug_naar_de_gemba" in _found(s))


func test_discoveries_survive_a_save() -> void:
	var s := _session()
	var minute := s.region.net.time % SimCalendar.MINUTES_PER_DAY
	s.region.advance(23 * 60 - minute)
	s.use_tool("outages.locate", "shadow")
	var restored := Discoveries.new(s.catalog.discoveries)
	restored.load_dict(bytes_to_var(var_to_bytes(s.discoveries.to_dict())))
	assert_true(restored.found.has("nachtdienst"))
	var saved := s.discoveries.to_dict()
	saved["found"]["retired_discovery"] = 1
	restored.load_dict(saved)
	assert_false(restored.found.has("retired_discovery"), "the content no longer has it")
