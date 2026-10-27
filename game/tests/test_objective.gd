extends TestCase
## The objective line (PLAN 2.13 C): the next concrete step of the main mission (or the
## training day), short and in-world, derived from the goal and its progress, with the
## mission's own `steps:` texts where it has them. Never a tool, a problem or a
## countermeasure, never what is wrong. The minimap marker follows the same step.

const SCENE := "res://src/world/office/office.tscn"
const INTAKE := "connections.intake"
const DESIGN := "connections.design"
const TRAY := "training_tray"
const P := ProblemState.Phase


func _training() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, true)


func _campaign() -> GameSession:
	return GameSession.new_game(11, Catalog.DATA_DIR, false)


func _text(s: GameSession) -> String:
	return str(Objective.of(s).get("text", ""))


## Every word that would hand the answer over: the tools (ids, names, card titles), the
## problems' and countermeasures' ids and names.
func _forbidden(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for tool: String in Investigation.TOOLS:
		out.append(tool)
		out.append(UiText.tool_name(tool))
		var card := s.tool_card(tool)
		if not card.is_empty():
			out.append(str(card["title"]))
	for p in s.region.problem_list():
		out.append_array([p.id, p.name])
	for c: CountermeasureDef in s.region.countermeasures.values():
		out.append_array([c.id, c.name])
	return out.filter(func(w: String) -> bool: return w.length() >= 4)


func _assert_clean(s: GameSession, text: String, where: String) -> void:
	assert_false(text.is_empty(), where + ": an objective")
	assert_true(text.length() <= Objective.MAX_CHARS, "%s: short (%d chars): %s" % [where, text.length(), text])
	var words := _words(text)
	for w: String in _forbidden(s):
		assert_false(words.contains(_words(w)), "%s names '%s': %s" % [where, w, text])
	assert_false(text.contains("{"), where + ": every token filled: " + text)


## " kijk bij meetdata " — whole words only ("data" the tool is not in "Meetdata").
func _words(text: String) -> String:
	var out := text.to_lower()
	for c in ":,.;?!()'\"·—_":
		out = out.replace(c, " ")
	return " %s " % " ".join(out.split(" ", false))


func _talk_through(s: GameSession, person: String) -> void:
	s.start_dialog(person)
	s.choose_move("close")
	s.end_dialog()


# ── The training week ───────────────────────────────────────────────────────

func test_monday_points_at_intake_then_werkvoorbereiding_then_anouk() -> void:
	var s := _training()
	var o := Objective.of(s)
	assert_eq(o["mission"], "training_mon")
	assert_eq(o["text"], "Kijk bij Intake hoe een aanvraag binnenkomt", "the mission's own step text")
	assert_eq(o["place"], INTAKE)
	s.ask(INTAKE, "walk")
	o = Objective.of(s)
	assert_eq(o["place"], DESIGN, "the next place once Intake was seen")
	assert_true(o["text"].contains("Werkvoorbereiding"), o["text"])
	s.ask(DESIGN, "walk")
	o = Objective.of(s)
	assert_eq(o["mission"], "training_mon", "Monday ends with Anouk's talk")
	assert_eq(o["text"], "Praat met Anouk (Werkvoorbereiding)")
	assert_eq(o["person"], "anouk")


func test_every_state_of_the_training_week_has_a_clean_objective() -> void:
	var s := _training()
	var seen: Array[String] = []
	var note := func(where: String) -> void:
		var text := _text(s)
		_assert_clean(s, text, where)
		seen.append(text)
	note.call("mon start")
	s.ask(INTAKE, "walk")
	note.call("mon intake seen")
	s.ask(DESIGN, "walk")
	note.call("mon talk")
	_talk_through(s, "anouk")
	assert_eq(Objective.of(s)["mission"], "training_tue")
	note.call("tue start")
	s.use_tool(DESIGN, "shadow")
	note.call("tue one look")
	assert_eq(Objective.of(s)["place"], DESIGN, "a second look at the same place")
	s.use_tool(DESIGN, "documents")
	assert_eq(Objective.of(s)["mission"], "training_wed")
	note.call("wed start")
	s.use_tool(INTAKE, "queue_count")
	note.call("wed intake counted")
	s.use_tool(DESIGN, "queue_count")
	assert_eq(Objective.of(s)["mission"], "training_thu")
	note.call("thu start")
	s.use_tool(DESIGN, "shadow")
	s.use_tool(DESIGN, "time_study")
	s.ask(DESIGN, "walk")
	note.call("thu clues")
	var problem: ProblemDef = s.region.problems[TRAY]
	assert_eq(s.submit_a3(TRAY, {"waste": problem.waste, "cause": s.cause_options(TRAY).find(problem.root_cause),
		"evidence": s.clues_found(TRAY).map(func(c: Clue) -> String: return c.id), "cm": "one_tray_fifo",
		"prediction": problem.kpi}), "")
	note.call("thu experiment")
	assert_eq(s.wait_for_check(TRAY), "")
	note.call("thu check ready")
	assert_true(s.check(TRAY).get("passed", false))
	assert_eq(Objective.of(s)["mission"], "training_fri")
	note.call("fri act")
	assert_eq(Objective.of(s).get("person"), Objective.CHECK_PERSON, "the Act at Petra's screen (PLAN 2.10)")
	assert_eq(seen.size(), 12, "every state checked")


func test_the_objective_changes_when_the_goal_moves_on() -> void:
	var s := _training()
	var before := _text(s)
	s.ask(INTAKE, "walk")
	assert_true(_text(s) != before, "a step done: a new line")


# ── Act I ───────────────────────────────────────────────────────────────────

func _act1_mains(s: GameSession) -> Array[MissionDef]:
	var out: Array[MissionDef] = []
	for m: MissionDef in s.missions.defs.values():
		if m.kind == "main" and m.act == 1:
			out.append(m)
	return out


func test_every_act_one_main_mission_has_a_clean_objective_in_every_phase() -> void:
	var s := _campaign()
	for m in _act1_mains(s):
		for id: String in s.missions.progress.keys():
			if s.missions.progress[id]["status"] == "active":
				s.missions.progress.erase(id)
		s.missions.progress[m.id] = {"status": "active", "asks": {}, "seen": {}}
		for t: Dictionary in m.talk_goals:
			s.people.outcomes[t["dialog"]] = "commitment"  # the talk had (test_mission_talks.gd)
		assert_eq(Objective.of(s).get("mission"), m.id)
		_assert_clean(s, _text(s), m.id + " at the start")
		if m.goal_problem.is_empty():
			continue
		var st: ProblemState = s.region.state[m.goal_problem]
		for phase in [P.ACTIVE, P.SPOTTED, P.DOING, P.CHECK_READY, P.CHECKED]:
			st.phase = phase
			_assert_clean(s, _text(s), "%s in %s" % [m.id, P.keys()[phase]])
		st.phase = P.SPOTTED
		for c in s.region.problems[m.goal_problem].clues:
			if c.key:
				s.region.found[c.id] = true
		_assert_clean(s, _text(s), m.id + " with its key clues")
		assert_true(Objective.of(s).get("desk", false), m.id + ": the A3 is written at your desk (PLAN 2.10)")
		st.phase = P.DORMANT


## Phase-2 design §3.1 (S1-H): every Act I mission, main and side, has an authored
## objective (its own `steps:` text, not a default) in every phase of its goal.
func test_every_act_one_mission_has_its_own_objective_at_every_state() -> void:
	var s := _campaign()
	var checked := 0
	for m: MissionDef in s.missions.defs.values():
		if m.act != 1 or m.goal_type == "story_order":
			continue  # the story's order is judged by the simulation: it has no line (see below)
		s.missions.progress[m.id] = {"status": "active", "asks": {}, "seen": {}}
		var phases: Array = [-1]
		if not m.goal_problem.is_empty():
			phases = [P.ACTIVE, P.SPOTTED, P.DOING, P.CHECK_READY, P.CHECKED] if m.goal_type == "solve" \
				else [P.ACTIVE, P.SPOTTED]
		for phase: int in phases:
			if phase >= 0:
				s.region.state[m.goal_problem].phase = phase
			var o := Objective.step(m, s)
			var where := "%s in %s" % [m.id, "start" if phase < 0 else P.keys()[phase]]
			assert_false(o.is_empty(), where + ": an objective")
			assert_true(m.steps.has(o.get("step", "")), "%s: its own words for '%s'" % [where, o.get("step")])
			_assert_clean(s, str(o.get("text", "")), where)
			checked += 1
		if not m.goal_problem.is_empty():
			s.region.state[m.goal_problem].phase = P.DORMANT
		s.missions.progress.erase(m.id)
	assert_true(checked >= 14, "the Act I missions were checked: %d states" % checked)


func test_without_a_main_mission_the_board_is_the_next_step() -> void:
	var s := _campaign()
	for id: String in s.missions.progress.keys():
		if s.missions.progress[id]["status"] == "active":
			s.missions.progress.erase(id)
	assert_eq(Objective.of(s)["text"], Objective.BOARD_TEXT)


## After closing time (the front door's own rule, OfficeHome.HOME_FROM) the line sends you
## home, by the front door, not to the board in a dark office (UX audit #18).
func test_after_closing_time_the_objective_is_going_home() -> void:
	var s := _campaign()
	s.pass_time(Objective.HOME_FROM - 1 - s.minute_of_day())
	assert_ne(Objective.of(s).get("step"), "home", "16:59: the work's own step")
	var working := _text(s)
	s.pass_time(1)
	assert_eq(Objective.of(s), {"step": "home", "text": Objective.HOME_TEXT})
	assert_true(Objective.HOME_TEXT.begins_with("Tijd om naar huis te gaan") and Objective.HOME_TEXT.contains("voordeur"),
		Objective.HOME_TEXT)
	assert_eq(OfficeHome.HOME_FROM, Objective.HOME_FROM, "the same rule as the front door")
	_assert_clean(s, Objective.HOME_TEXT, "home")
	s.pass_time(SimCalendar.days(1) - 1)   # the next morning, 16:59
	assert_eq(_text(s), working, "the next day the work's step again")


func test_a_side_mission_is_never_the_objective() -> void:
	var s := _campaign()
	for id: String in s.missions.progress.keys():
		if s.missions.progress[id]["status"] == "active":
			s.missions.progress.erase(id)
	s.missions.progress["walk_meters"] = {"status": "active", "asks": {}, "seen": {}}
	assert_true(Objective.of(s).get("mission", "") != "walk_meters", "the coach and the line are for the main quest")


# ── The opening and the HUD ─────────────────────────────────────────────────

func test_the_opening_has_no_objective_except_following_ruud() -> void:
	var s := _training()
	var layer := SessionLayer.new()
	layer.opening_beat = Opening.ARRIVAL
	assert_eq(Objective.of(s, layer), {}, "a scene: no objective")
	layer.opening_beat = Opening.WALK
	assert_eq(Objective.of(s, layer)["text"], "Loop met Ruud mee")
	for beat in [Opening.BOARD, Opening.LETTER, Opening.EVENING]:
		layer.opening_beat = beat
		assert_eq(Objective.of(s, layer), {}, beat)
	layer.opening_beat = Opening.DONE
	assert_false(Objective.of(s, layer).is_empty(), "after the first day the line is back")


func test_the_hud_shows_one_objective_line_and_no_mission_titles() -> void:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = true
	office.build()
	var hud := office.ui.hud
	assert_eq(hud.objective_label.text, "Kijk bij Intake hoe een aanvraag binnenkomt")
	assert_true(hud.objective_label.visible)
	assert_false(hud.objective_label.text.contains("\n"), "one line")
	for l in hud.find_children("*", "Label", true, false):
		assert_false((l as Label).text.begins_with("Missie:"), "no mission title in the bar: " + (l as Label).text)
	office.free()


func test_the_minimap_marker_follows_the_objective() -> void:
	var s := _training()
	var b := OfficeBuilding.load_from(Catalog.DATA_DIR)
	var cast := CharacterModel.cast()
	s.ask(INTAKE, "walk")
	s.ask(DESIGN, "walk")
	var t := MinimapTargets.of(s.missions.defs["training_mon"], s, b, cast)
	assert_eq([t.get("kind"), t.get("person")], ["person", "anouk"], "the talk that ends Monday")


## A milestone's scene waits in its room (phase-2 design §3.1): on its day the line
## leads there, before the main mission, and the minimap marks the room; once the
## scene is played the main mission leads again. A story_order milestone has no line:
## nothing is handed over, the simulation judges it.
func test_a_scene_milestone_leads_to_its_room_on_its_day() -> void:
	var s := _campaign()
	var main_text := _text(s)
	s.missions.play_start -= SimCalendar.days(100)   # day 100 of play
	s.pass_time(0)
	assert_eq(s.missions.status("review_100_days"), "active")
	var step := Objective.of(s)
	assert_eq([step.get("step"), step.get("room"), step.get("text")], ["go", "mt_room", "Ga naar de MT-kamer op de 2e"])
	var t := MinimapTargets.of(s.missions.defs["review_100_days"], s, OfficeBuilding.load_from(Catalog.DATA_DIR),
		CharacterModel.cast())
	assert_eq([t.get("kind"), t.get("room"), t.get("floor")], ["room", "mt_room", "second"])
	assert_eq(Objective.step(s.missions.defs["winter_el_amrani"], s), {}, "the frost is judged, not walked to")
	assert_eq(s.finish_scene("review_100_days", 0), "")
	assert_eq(_text(s), main_text, "the main mission leads again")
