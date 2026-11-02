extends TestCase
## The session layer (engagement loop §2): the terugblik when the game opens,
## the stop note at a dagstart, the Intussen view and the named time skip
## during a Check, at most one discovery toast a day, and at most two new
## side offers a week. It reads the rules and never changes them.

const MISSION := "fix_custom_design"
const PROBLEM := "custom_design"
const DESIGN := "connections.design"
const INTAKE := "connections.intake"
const HENK := "save_henks_knowledge"


func _campaign() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	return s


## The main mission investigated like an expert and its A3 in: the
## experiment runs.
func _experiment_running() -> GameSession:
	var s := _campaign()
	assert_eq(s.accept(MISSION), "")
	s.use_tool(DESIGN, "time_study")
	s.use_tool(DESIGN, "documents")
	s.ask(INTAKE, "walk")
	s.use_tool(DESIGN, "data")
	var problem: ProblemDef = s.region.problems[PROBLEM]
	var a3 := {"waste": "overprocessing", "cause": Investigation.cause_options(problem, s.region.problem_list())["correct"],
		"evidence": s.clues_found(PROBLEM).map(func(c: Clue) -> String: return c.id), "cm": "standard_designs",
		"prediction": "throughput"}
	assert_eq(s.submit_a3(PROBLEM, a3), "")
	assert_eq(s.phase_of(PROBLEM), "doing")
	return s


func _ids(missions: Array[MissionDef]) -> Array:
	return missions.map(func(m: MissionDef) -> String: return m.id)


# ── Side offers ─────────────────────────────────────────────────────────────

## Three sides open at once: two are offered this week, the third the next;
## a week on, the first two fold into "Nog open", never lost.
func test_at_most_two_new_side_offers_a_week_and_older_ones_stay_open() -> void:
	var s := _campaign()
	for id in ["walk_outages", "walk_meters"]:
		s.missions.done_once[id] = true
		s.missions.progress[id] = {"status": "completed", "asks": {}, "seen": {}}
	s.missions.update()
	var sides := s.available_missions().filter(func(m: MissionDef) -> bool: return m.kind == "side")
	assert_true(sides.size() >= 3, "three sides open at once: %s" % [_ids(sides)])
	var layer := SessionLayer.new()
	layer.update(s)
	var fresh := layer.new_offers(s)
	assert_eq(fresh.filter(func(m: MissionDef) -> bool: return m.kind == "side").size(), SessionLayer.NEW_SIDES_PER_WEEK)
	assert_eq(layer.older_offers(s), [], "nothing older yet")
	assert_true(_ids(fresh).has(MISSION), "the main mission is never held back")
	var waiting: Array = _ids(sides).filter(func(id: String) -> bool: return not _ids(fresh).has(id))
	assert_eq(waiting.size(), sides.size() - 2)
	assert_eq(_ids(s.available_missions()).size(), _ids(sides).size() + 1, "the rules still offer all of them")

	s.region.advance_days(7)
	s.missions.update()
	layer.update(s)
	assert_true(_ids(layer.new_offers(s)).has(waiting[0]), "next week the next one is offered")
	assert_eq(_ids(layer.older_offers(s)).size(), 2, "last week's two fold into Nog open")


## A side with a clock is shown at once (its deadline runs from when it
## opens), and check-ins never wait: they are the player's own fixes.
func test_a_side_with_a_deadline_and_a_check_in_are_never_held_back() -> void:
	var s := _campaign()
	for id in s.missions.defs[HENK].requires_missions:
		s.missions.done_once[id] = true
	for id in ["walk_outages", "walk_meters"]:
		s.missions.done_once[id] = true
		s.missions.progress[id] = {"status": "completed", "asks": {}, "seen": {}}
	s.missions.update()
	assert_eq(s.missions.status(HENK), "available")
	var layer := SessionLayer.new()
	layer.update(s)
	assert_true(_ids(layer.new_offers(s)).has(HENK), "Henk's clock runs: he is shown")
	var checkin := Missions.checkin_def(s.region.problems[PROBLEM])
	assert_false(layer.held_back(checkin), "a check-in is never held back")


# ── Discovery toasts ────────────────────────────────────────────────────────

func test_at_most_one_discovery_toast_a_day_the_rest_wait_for_the_terugblik() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	assert_true(layer.discovery_toast(s, "d_one"), "the first of the day shows")
	assert_false(layer.discovery_toast(s, "d_two"), "the second waits")
	assert_eq(layer.queued, ["d_two"])
	s.region.advance_days(1)
	assert_true(layer.discovery_toast(s, "d_three"), "a new day, a new toast")
	var card := layer.terugblik(s)
	assert_eq(card["discoveries"], ["d_two"], "the queued one comes with the next terugblik")


# ── The terugblik ───────────────────────────────────────────────────────────

func test_a_new_game_has_no_terugblik() -> void:
	var s := _campaign()
	assert_eq(SessionLayer.new().terugblik(s), {})


## What happened in the last session: a mission done is Ruud's line; a
## Check waiting is the person waiting; the Check's date is what comes.
func test_the_terugblik_names_the_change_who_waits_and_what_comes() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	s.missions.done_once["walk_outages"] = true
	s.missions.progress["walk_outages"] = {"status": "completed", "asks": {}, "seen": {}}
	var card := layer.terugblik(s)
	assert_eq(card["ruud"]["kind"], "completed")
	assert_eq(card["ruud"]["mission"], "walk_outages")
	assert_true(card["lines"].size() <= SessionLayer.MAX_LINES)

	var running := _experiment_running()
	var later := SessionLayer.new()
	later.begin(running)
	var coming := later.terugblik(running)
	var kinds: Array = coming["lines"].map(func(l: Dictionary) -> String: return l["kind"])
	assert_true("coming" in kinds, "the Check's date comes: %s" % [kinds])
	var line: Dictionary = coming["lines"][kinds.find("coming")]
	assert_eq(line["what"], "check")
	assert_eq(line["t"], running.region.state[PROBLEM].check_at)
	assert_true(running.wait_for_check(PROBLEM).is_empty())
	var ready := later.terugblik(running)
	var waiting: Array = ready["lines"].filter(func(l: Dictionary) -> bool: return l["kind"] == "waiting")
	assert_eq(waiting.size(), 1)
	assert_eq(waiting[0]["what"], "check_ready")
	assert_eq(ready["ruud"]["kind"], "check_ready")


## A number that moved since the start of the last session.
func test_the_terugblik_names_a_number_that_moved() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	var connections: Dictionary = layer.start["measures"]["connections"]
	connections["lead_days_p50"] = connections["lead_days_p50"] * 2.0  # it was twice as long
	var card := layer.terugblik(s)
	var changed: Array = card["lines"].filter(func(l: Dictionary) -> bool: return l["kind"] == "changed")
	assert_eq(changed.size(), 1)
	assert_eq(changed[0]["stream"], "connections")
	assert_eq(changed[0]["measure"], "lead_days_p50")
	assert_true(changed[0]["after"] < changed[0]["before"])
	assert_eq(card["ruud"]["kind"], "changed")


## Opening a session shows the card once, clears the queue and starts a new
## snapshot; the card can be read again (the journal).
func test_opening_a_session_starts_a_new_snapshot_and_keeps_the_card() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	layer.queued.append("d_two")
	var card := layer.open_session(s)
	assert_eq(card["discoveries"], ["d_two"])
	assert_eq(layer.queued, [])
	assert_eq(layer.last_card, card)
	assert_eq(layer.start["t"], s.region.net.time)


# ── Stop note ───────────────────────────────────────────────────────────────

func test_the_stop_note_comes_at_a_dagstart_after_half_an_hour() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	assert_false(layer.update(s), "no new day yet")
	s.region.advance_days(1)
	assert_true(layer.update(s), "a new day: the dagstart")
	assert_false(layer.update(s), "once per day")
	assert_false(SessionLayer.stop_note_due(12.0))
	assert_true(SessionLayer.stop_note_due(31.0))


# ── Intussen and the named time skip ────────────────────────────────────────

func test_intussen_names_the_check_date_and_the_skip() -> void:
	var s := _experiment_running()
	var view := SessionLayer.new().intussen(s, PROBLEM)
	var st: ProblemState = s.region.state[PROBLEM]
	assert_eq(view["check_at"], st.check_at)
	assert_eq(view["days"], ceili((st.check_at - s.region.net.time) / float(SimCalendar.MINUTES_PER_DAY)))
	assert_true(view.has("beats") and view.has("people") and view.has("sides"))
	assert_eq(SessionLayer.new().intussen(s, "ghost"), {"error": "unknown_problem"})


## With nobody waiting the skip runs to the Check.
func test_the_skip_runs_to_the_check() -> void:
	var s := _experiment_running()
	var result := SessionLayer.new().skip_to_check(s, PROBLEM)
	assert_eq(result["stopped"], "")
	assert_eq(s.phase_of(PROBLEM), "check_ready")
	assert_eq(s.region.net.time, s.region.state[PROBLEM].check_at)
	assert_true(result["days"] > 0)


## A deadline with a person is a beat the skip stops at, the day before.
func test_the_skip_stops_at_a_deadline() -> void:
	var s := _experiment_running()
	for id in s.missions.defs[HENK].requires_missions:
		s.missions.done_once[id] = true
	s.missions.update()
	var deadline: int = s.missions.opened_at[HENK] + SimCalendar.days(s.missions.defs[HENK].deadline_days)
	s.region.state[PROBLEM].check_at = deadline + SimCalendar.days(3)  # the Check falls after Henk's date
	var layer := SessionLayer.new()
	var beats: Array = layer.intussen(s, PROBLEM)["beats"]
	assert_true(beats.any(func(b: Dictionary) -> bool: return b["what"] == "deadline" and b["id"] == HENK),
		"Henk's date is a beat before the Check")
	var result := layer.skip_to_check(s, PROBLEM)
	assert_eq(result["stopped"], "deadline")
	assert_eq(result["id"], HENK)
	assert_eq(s.phase_of(PROBLEM), "doing", "the Check still waits")
	assert_true(deadline - s.region.net.time <= SimCalendar.days(1) and deadline > s.region.net.time,
		"stopped the day before, in time")
	assert_false(s.missions.failed(HENK))
	var on := layer.skip_to_check(s, PROBLEM)
	if on["stopped"] == "talk":   # Henk gone, Ahmed's check-in may come due on the way (1.4b)
		on = layer.skip_to_check(s, PROBLEM)
	assert_eq(on["stopped"], "", "skipping again goes on to the Check")
	assert_eq(s.phase_of(PROBLEM), "check_ready")


func test_the_skip_refuses_without_a_running_experiment() -> void:
	var s := _campaign()
	assert_eq(SessionLayer.new().skip_to_check(s, PROBLEM), {"error": "not_doing"})
	assert_eq(SessionLayer.new().skip_to_check(s, "ghost"), {"error": "unknown_problem"})


# ── Saved state ─────────────────────────────────────────────────────────────

func test_the_layer_round_trips_and_ignores_junk() -> void:
	var s := _campaign()
	var layer := SessionLayer.new()
	layer.begin(s)
	layer.update(s)
	layer.queued.append("d_two")
	layer.toast_day = 4
	var copy := SessionLayer.new()
	copy.load_dict(bytes_to_var(var_to_bytes(layer.to_dict())))
	assert_eq(copy.to_dict(), layer.to_dict())
	var junk := SessionLayer.new()
	junk.load_dict({"start": "x", "offered": [1], "queued": [3, "ok"], "toast_day": "no"})
	assert_eq(junk.start, {})
	assert_eq(junk.offered, {})
	assert_eq(junk.queued, ["ok"])
	assert_eq(junk.toast_day, -1)
	var bad_snapshot := SessionLayer.new()
	bad_snapshot.load_dict({"start": {"t": 5, "measures": {"connections": "x"}, "completed": [1, "a"]}})
	assert_eq(bad_snapshot.start["measures"], {})
	assert_eq(bad_snapshot.start["completed"], ["a"])
	assert_eq(bad_snapshot.terugblik(s)["ruud"]["kind"] in ["completed", "quiet", "changed", "check_ready", "checkin"], true)


# ── People instead of teams (PLAN 1.4b) ─────────────────────────────────────

## No check-in open and none resting, everyone low: the next sync may open one
## (which one is the content's: tests read it from checkin_prompts()).
func _nobody_asked_yet(s: GameSession) -> void:
	s.people.prompts.clear()
	s.people.prompt_log.clear()
	s.people.last_prompt.clear()
	for id: String in s.people.morale:
		s.people.morale[id] = 20


## A due check-in names its person in "Wacht op je" and Intussen: one check-in
## opened by hand, whichever the content has.
func test_a_due_check_in_names_its_person() -> void:
	var s := _experiment_running()
	var layer := SessionLayer.new()
	layer.begin(s)
	_nobody_asked_yet(s)
	var checkin: DialogDef = s.people.dialogs.values().filter(func(d: DialogDef) -> bool: return d.kind == "checkin")[0]
	s.people.prompts[checkin.id] = s.region.net.time
	var who: PersonDef = s.people.persons[checkin.person]
	var waiting: Array = layer.terugblik(s)["lines"].filter(func(l: Dictionary) -> bool: return l["kind"] == "waiting")
	assert_eq(waiting.size(), 1)
	assert_eq(waiting[0]["what"], "talk")
	assert_eq(waiting[0]["person"], who.id)
	var text := TerugblikCard.line_text(s, waiting[0])
	assert_true(text.contains(who.name), text)
	assert_true(text.contains(checkin.prompt), "their dagstart line")
	var people: Array = layer.intussen(s, PROBLEM)["people"]
	assert_true(people.any(func(l: Dictionary) -> bool: return l.get("person", "") == who.id), "Intussen too")


## A check-in without a dagstart line still reads as a person who wants a word.
func test_a_check_in_without_a_line_still_names_its_person() -> void:
	var s := _campaign()
	var text := TerugblikCard.line_text(s, {"kind": "waiting", "what": "talk", "person": "anouk", "name": "Anouk de Vries", "line": ""})
	assert_true(text.contains("Anouk de Vries"), text)
	assert_false(text.strip_edges().ends_with("·"), "no dangling separator: " + text)


## The named skip stops when a check-in comes due on the way, and names whose.
func test_the_skip_stops_at_a_due_check_in() -> void:
	var s := _experiment_running()
	_nobody_asked_yet(s)
	var result := SessionLayer.new().skip_to_check(s, PROBLEM)
	assert_eq(result.get("stopped", ""), "talk", "a check-in came due before the Check")
	var due := s.checkin_prompts()
	assert_eq(due.size(), 1)
	assert_eq(result.get("id", ""), due[0]["person"], "the one who came due")
	assert_eq(s.phase_of(PROBLEM), "doing", "the Check still waits")
	var text := IntussenPanel.stopped_text(s, result)
	assert_true(text.contains(due[0]["name"]), text)
	var on := SessionLayer.new().skip_to_check(s, PROBLEM)
	assert_false(on.has("error"), "the experiment still ran")
	assert_false(on.get("stopped", "") == "talk" and on.get("id", "") == due[0]["person"],
		"an open check-in does not stop the next skip")


## The marker's context: the last texts the player saw as events, a ring of live context
## (not saved; an old save loads with an empty one).
func test_recent_keeps_the_last_twenty() -> void:
	var layer := SessionLayer.new()
	for i in 21:
		layer.note_event("gebeurtenis %d" % i)
	assert_eq(layer.recent.size(), SessionLayer.RECENT_MAX)
	assert_eq(layer.recent[0], "gebeurtenis 1", "the oldest is gone")
	assert_eq(layer.recent[-1], "gebeurtenis 20")


func test_recent_is_not_saved() -> void:
	var layer := SessionLayer.new()
	layer.note_event("iets")
	assert_false(layer.to_dict().has("recent"))
	var loaded := SessionLayer.new()
	loaded.load_dict(layer.to_dict())
	assert_true(loaded.recent.is_empty())
