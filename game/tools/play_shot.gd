extends SceneTree
## Screenshots of the office in a given play state (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/play_shot.gd -- <state> <out.png> [frames]
## States: office (third person at Werkvoorbereiding, HUD and prompt) ·
## overview (the same, zoomed out over the floor) · inspect (E at
## Werkvoorbereiding: the team's menu docked at the right, the camera framing
## the station beside it) ·
## tools (the team's menu after some gemba work) · a3 (the A3, filled in) ·
## check (the Check result after the experiment) · act (the score after Act) ·
## board (the mission board) · coach (the coach's question) · map (the
## player map with the mission taken) · codex (the glossary after some
## gemba work and an extra few concepts) ·
## training_board (Monday of the training week: the board with the skip) ·
## timelapse (the week played to Friday: the Act and the month ahead, with and
## without the standard) · sustain (the fix standardised, then left alone for
## weeks: its health, the audit and the routine in the team's menu, and the
## toasts of a slipping fix) · discoveries (the codex's Ontdekkingen tab with
## two found) · simulating (the A3's note while the Check runs) · fork_board
## (the board after the first mission: the fork as a pair) · debt (the HUD in
## debt, with the floor, and its toasts) · dialog_start, dialog_mid,
## dialog_picks, dialog_summary, dialog_ruined (a talk with Joost) ·
## dialog_people (the journal's Mensen tab after it) · dialog_place (the
## team's menu with its people) · dialog_energy (the low-energy bar) ·
## intussen (the A3 in: what happens while the
## Check runs, and the named skip) · terugblik (the card a resumed game opens
## with, after a session that finished the mission and left it alone) ·
## people_desks (Werkvoorbereiding and Intake at work, Anouk's name on hover) ·
## people_talk (E beside Joost: the prompt and the talk's placeholder toast) ·
## people_energy (the walk-around energy bars, from a stand-in energy_of) ·
## people_monteurs (Henk and Ahmed at the huddle table for Henk's mission, Marco
## walking in) · people_meetdata (Petra at the stand-in Meetdata desk) ·
## people_gemba (E at Werkvoorbereiding with the people there: do the stacks
## and the in-trays still read?) · people_kcc, people_lunch, people_directie,
## people_netstrategie, people_planning, people_revisie (2.1c: Esra and her agents,
## lunch in the kantine, Frank and Femke on the 2e, Linda and Mieke on the 1e) ·
## people_whiteboard, people_explainer (Ruud's whiteboard, and E there) ·
## title (the title menu over a few saves) ·
## title_replace, title_keep ("Nieuw spel" over a filled autosave: the
## question, then the slots to keep it in) ·
## pause, pause_slots, pause_confirm (Esc in the office: the pause menu, its
## five slots, the overwrite question).
## The mission is played through the UI's own handlers, as a player would;
## only the training states start with the training week.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"
## Days the standardised fix is left alone in the sustain state: long enough
## to slip below the check-in line (life ≈ 130 days, slipping from ≈ 84).
const SUSTAIN_DAYS := 100
## The save menus' saves: this tool's own folder.
const SHOT_SAVES := "user://shot_saves"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <office|overview|inspect|tools|a3|check|act|board|coach|map|codex|training_board|timelapse|sustain|intussen|terugblik|people_desks|people_talk|people_energy|people_monteurs|people_meetdata|people_gemba|title|title_replace|title_keep|pause|pause_slots|pause_confirm> <out.png> [frames]")
		quit(2)
		return
	var state := args[0]
	if state in ["title", "title_replace", "title_keep", "pause", "pause_slots", "pause_confirm"]:
		await _save_menus(state)
		_capture(args)
		return
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = state in ["training_board", "timelapse"]
	root.add_child(office)
	match state:
		"office":
			_stand_at(office, DESIGN)
		"tools":
			_investigate(office, false)
		"a3":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.fill(_a3(office))
		"check", "act", "sustain":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.a3_form.check()
			if state != "check":
				office.ui.check_panel.act(true)
			if state == "sustain":
				office.ui.close_panels()
				office.session.region.advance_days(SUSTAIN_DAYS)
				office.ui.after_action()
				_stand_at(office, DESIGN)
				office.interact(office.interactable(DESIGN))
				office.rig.snap()
		"coach":
			_investigate(office, false)
			office.interact(office.interactable("coach"))
			office.ui.coach_panel.ask()
		"map":
			office.ui.mission_board.accept(MISSION)
			office.ui.close_panels()
			_stand_at(office, INTAKE)
			office.player.rotation.y += deg_to_rad(-60)
			office.ui.toggle_map()
		"codex":
			_investigate(office, true)
			office.session.region.profile.learn(["flow", "bottleneck_focus", "netbeheerder", "netcongestie", "kata_prediction"])
			office.ui.toggle_codex()
		"discoveries":
			_investigate(office, false)
			office.session.discoveries.found["het_knelpunt_eerst"] = office.session.region.net.time
			office.session.discoveries.found["voorspeller"] = office.session.region.net.time
			office.ui.toggle_codex()
			office.ui.codex.show_tab(CodexPanel.DISCOVERIES)
		"simulating":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.a3_form.show_simulating()
		"fork_board":
			office.session.missions.done_once[MISSION] = true
			office.session.missions.progress[MISSION] = {"status": "completed", "asks": {}, "seen": {}}
			office.session.region.state["custom_design"].phase = ProblemState.Phase.RESOLVED  # or it reopens
			office.session.missions.update()
			_stand_at(office, "mission_board")
			office.interact(office.interactable("mission_board"))
		"debt":
			office.session.region.grant(0, -70000)
			office.ui.after_action()
			_stand_at(office, DESIGN)
		"dialog_start", "dialog_mid", "dialog_picks", "dialog_summary", "dialog_ruined":
			_talk_to_joost(office, state)
		"dialog_people":
			_talk_to_joost(office, "dialog_summary")
			office.ui.close_panels()
			office.ui.toggle_journal()
			office.ui.journal.show_tab(ClueJournal.PEOPLE)
		"explainers":
			office.session.explainers.see("spanning_stroom_weerstand")
			office.ui.toggle_codex()
			office.ui.codex.show_tab(CodexPanel.EXPLAINERS)
		"contain_board":
			for id in ["fix_done_but_not_closed", "fix_status_callers", "fix_incomplete_application", MISSION]:
				office.session.missions.done_once[id] = true
			office.session.accept("fix_digging_damage")
			_stand_at(office, "mission_board")
			office.interact(office.interactable("mission_board"))
		"standardise":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.a3_form.check()
			office.ui.check_panel.act(false)
			office.ui.close_panels()
			_stand_at(office, DESIGN)
			office.interact(office.interactable(DESIGN))
			office.rig.snap()
		"dossier":
			_investigate(office, false)
			office.ui.toggle_journal()
		"dialog_place":
			_open_silo(office)
			_stand_at(office, DESIGN)
			office.interact(office.interactable(DESIGN))
			office.rig.snap()
		"dialog_energy":
			office.session.people.prompts["joost_output_kpi"] = office.session.region.net.time
			office.session.people.morale["joost"] = 25
			office.people.refresh(office.session)
			var joost := office.people.person("joost")
			office.player.position = joost.position + joost.basis.x * 3.0 - joost.basis.z * 0.5
			office.player.face(Basis.looking_at((joost.position - office.player.position) * Vector3(1, 0, 1)))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(15)
			office.rig.zoom(-4)
			office.rig.snap()
		"inspect":
			_stand_at(office, DESIGN)
			office.interact(office.interactable(DESIGN))
			office.rig.snap()
		"overview":
			_stand_at(office, DESIGN)
			office.rig.zoom(100)
			office.rig.snap()
		"board", "training_board":
			_stand_at(office, "mission_board")
			office.interact(office.interactable("mission_board"))
		"timelapse":
			_play_week(office)
			office.ui.check_panel.act(false)
			office.ui.check_panel.fade_forecast()
		"intussen":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))  # Intussen opens with the experiment
		"intussen_talk":   # the skip stops when someone's check-in comes due (PLAN 1.4b)
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			var people := office.session.people
			people.prompts.clear()
			people.last_prompt.clear()
			for id: String in people.morale:
				people.morale[id] = 20
			office.ui.intussen.skip()
		"terugblik":
			_last_session(office)
			_stand_at(office, DESIGN)
			office.ui.close_panels()
			office.ui.open_terugblik(office.ui.session_layer.open_session(office.session))
		"people_desks", "people_talk", "people_energy", "people_monteurs", "people_meetdata", "people_gemba":
			_people(office, state)
		"people_kcc", "people_lunch", "people_directie", "people_netstrategie", "people_planning", "people_revisie", \
				"people_whiteboard", "people_explainer":
			await _rooms(office, state)
		_:
			printerr("unknown state ", state)
			quit(2)
			return
	_capture(args)


## Wait `frames` (args[2], default 20), then save the screen to args[1].
func _capture(args: PackedStringArray) -> void:
	var frames := int(args[2]) if args.size() > 2 else 20
	for i in frames:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[1])
	if err != OK:
		printerr("cannot write ", args[1], ": ", error_string(err))
	quit(0 if err == OK else 1)


## The title menu over a few saves, or the pause menu (its main page, the
## slot picker, the overwrite question). The saves live in a folder of this
## tool's own, never the player's.
func _save_menus(state: String) -> void:
	var slots := SaveSlots.new(SHOT_SAVES)
	slots.wipe()
	var now := Time.get_unix_time_from_system()
	for save: Array in [[1, 3 * 86400.0, true, 2], [3, 86400.0 + 3600.0, false, 18], [0, 120.0, false, 9]]:
		var s := GameSession.new_game(11, Catalog.DATA_DIR, save[2])
		s.region.advance_days(save[3])
		slots.now = func() -> float: return now - save[1]
		var error := slots.autosave(s, SessionLayer.new()) if save[0] == 0 else slots.save(save[0], s, SessionLayer.new())
		if not error.is_empty():
			printerr(error)
	var old := FileAccess.open(SaveFile.path_of("slot_4", SHOT_SAVES), FileAccess.WRITE)
	old.store_buffer(var_to_bytes({"version": 0, "region": {}}))
	old.close()
	slots.now = func() -> float: return now
	if state.begins_with("title"):
		var menu: TitleMenu = load(TitleMenu.SCENE).instantiate()
		menu.saves = slots
		root.add_child(menu)
		if state != "title":
			menu.new_game()  # the autosave holds a game: it asks first
		if state == "title_keep":
			menu.keep_first()
		return
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.saves = slots
	root.add_child(office)
	office.ui.saves = slots  # the pause menu saves here; no autosave in a tool
	_stand_at(office, DESIGN)
	office.player.escape_pressed.emit()
	if state != "pause":
		office.ui.pause_menu.show_slots()
	if state == "pause_confirm":
		office.ui.pause_menu.pick(3)


## Stand a step behind the marker, looking the way it faces; the camera
## behind the player.
func _stand_at(office: Office, id: String) -> void:
	var at := office.interactable(id)
	office.player.position = at.position + at.basis.z * 0.6
	office.player.face(at.basis)
	office.rig.yaw = office.player.rotation.y
	office.rig.snap()


## A session stand-in for the people states: the real one's missions, plus the
## mission and the energy_of the dialog engine will add.
class PeopleSession:
	extends RefCounted
	var session: GameSession
	var extra: Array[MissionDef] = []
	var energy := {}
	## The hour the people see (minutes since midnight); -1: the session's.
	var minute := -1

	func minute_of_day() -> int:
		return minute if minute >= 0 else session.minute_of_day()

	func person(person_id: String) -> Dictionary:
		return session.person(person_id)

	func active_missions() -> Array[MissionDef]:
		var out := session.active_missions()
		out.append_array(extra)
		return out

	func energy_of(person_id: String) -> Dictionary:
		return energy.get(person_id, {})


func _people(office: Office, state: String) -> void:
	var people := office.people
	var stand_in := PeopleSession.new()
	stand_in.session = office.session
	match state:
		"people_desks":
			_stand_at(office, DESIGN)
			office.player.position += office.player.basis.x * 1.2
			office.rig.yaw = office.player.rotation.y + deg_to_rad(-25)
			office.rig.zoom(3)
			office.rig.snap()
			office.hover_person(people.person("anouk"))
		"people_talk":
			var joost := people.person("joost")
			office.player.position = joost.position + joost.basis.x * 0.8 + joost.basis.z * 0.3
			office.player.face(Basis.looking_at(joost.position - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(30)
			office.rig.snap()
			office.use(office.target_near(office.player.position))
		"people_energy":
			stand_in.energy = {"anouk": {"energy": 0.28, "needs_talk": true}, "sanne": {"energy": 0.55, "needs_talk": true}}
			people.refresh(stand_in)
			_stand_at(office, DESIGN)
			office.rig.yaw = office.player.rotation.y + deg_to_rad(-40)
			office.rig.zoom(2)
			office.rig.snap()
		"people_monteurs":
			var mission := MissionDef.new()
			mission.id = "save_henks_knowledge"
			stand_in.extra = [mission]
			people.refresh(stand_in)
			var marco := people.person("marco")
			marco.walk(1.6)
			office.player.position = Vector3(8.6, 0, -5.4)
			office.player.face(Basis.looking_at(people.person("henk").position - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(20)
			office.rig.snap()
			office.hover_person(people.person("henk"))
		"people_meetdata":
			var petra := people.person("petra")
			office.player.position = petra.position + Vector3(-1.4, 0, 0.6)
			office.player.face(Basis.looking_at(petra.position - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(-20)
			office.rig.snap()
			office.hover_person(petra)
		"people_gemba":
			_stand_at(office, DESIGN)
			office.interact(office.interactable(DESIGN))
			office.rig.snap()


## The rooms peopled in 2.1c: the floor's room opened by its mission, the player a few
## steps from the person, the camera over the shoulder; the explainer from Ruud's board.
func _rooms(office: Office, state: String) -> void:
	var at := {"people_kcc": ["ground", "fix_status_callers", "kim", Vector3(0.6, 0, 2.2), 25.0],
		"people_lunch": ["ground", "", "kim", Vector3(1.2, 0, 2.4), 15.0],
		"people_directie": ["second", "fix_silo_kpis", "frank", Vector3(-1.8, 0, -1.4), -25.0],
		"people_netstrategie": ["second", "look_at_grid_study", "femke", Vector3(1.0, 0, 2.2), 25.0],
		"people_planning": ["first", "", "linda", Vector3(0.6, 0, -2.2), 20.0],
		"people_revisie": ["first", "", "mieke", Vector3(0.4, 0, 2.6), -20.0]}
	if state in ["people_whiteboard", "people_explainer"]:
		var board := office.interactable(OfficeWhiteboard.ID)
		office.player.position = board.position + Vector3(1.2, 0, 0.9)
		office.player.face(Basis.looking_at(board.position - office.player.position))
		office.rig.yaw = office.player.rotation.y + deg_to_rad(15)
		office.rig.snap()
		if state == "people_explainer":
			office.player.position = board.position
			office.use(board)
			for i in 30:
				await process_frame
		return
	var spec: Array = at[state]
	if not str(spec[1]).is_empty():
		office.session.missions.progress[spec[1]] = {"status": "active", "asks": {}, "seen": {}}
		office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to(spec[0], "lift", true)
	if state == "people_lunch":
		var clock := PeopleSession.new()
		clock.session = office.session
		clock.minute = 12 * 60 + 20
		office.people.refresh(clock)
		office.people.set_process(false)   # keep the lunch hour for the shot
	var p := office.people.person(spec[2])
	office.player.position = p.position + spec[3]
	office.player.face(Basis.looking_at((p.position - office.player.position) * Vector3(1, 0, 1)))
	office.rig.yaw = office.player.rotation.y + deg_to_rad(spec[4])
	if state == "people_kcc":
		office.rig.zoom(-3)   # close enough to see the headsets
	office.rig.snap()
	office.hover_person(p)


## Take the mission and do the gemba work; `all` finds every key clue.
func _investigate(office: Office, all: bool) -> void:
	var ui := office.ui
	ui.mission_board.accept(MISSION)
	_stand_at(office, DESIGN)
	office.interact(office.interactable(DESIGN))
	ui.place_menu.use_tool("queue_count")
	ui.place_menu.use_tool("time_study")
	ui.place_menu.use_tool("documents")
	if all:
		office.interact(office.interactable(INTAKE))
		ui.place_menu.ask("walk")
		office.interact(office.interactable(DESIGN))
		ui.place_menu.use_tool("data")
		ui.close_panels()


## A last session to look back on: the mission played to its Act and then
## left alone, so its fix slips (a check-in waits) and the numbers move; a
## side with a clock is open.
func _last_session(office: Office) -> void:
	var ui := office.ui
	var s := office.session
	_investigate(office, true)
	office.interact(office.interactable("obeya"))
	ui.a3_form.submit(_a3(office))
	ui.intussen.skip()
	ui.a3_form.check()
	ui.check_panel.act(true)
	for id in s.missions.defs["save_henks_knowledge"].requires_missions:
		s.missions.done_once[id] = true
	s.pass_time(SimCalendar.days(SUSTAIN_DAYS))
	ui.after_action()


## Monday to Friday's Check of the training week, through the UI.
func _play_week(office: Office) -> void:
	var ui := office.ui
	var s := office.session
	for step: Array in [[INTAKE, "shadow"], [DESIGN, "walk"], [DESIGN, "time_study"], [DESIGN, "documents"],
			[INTAKE, "queue_count"], [DESIGN, "queue_count"], [DESIGN, "shadow"], [DESIGN, "time_study"], [DESIGN, "walk"]]:
		office.interact(office.interactable(step[0]))
		if step[1] == "walk":
			ui.place_menu.ask("walk")
		else:
			ui.place_menu.use_tool(step[1])
	office.interact(office.interactable("obeya"))
	var problem: ProblemDef = s.region.problems["training_tray"]
	ui.a3_form.submit({"waste": problem.waste, "cause": s.cause_options(problem.id).find(problem.root_cause),
		"evidence": s.clues_found(problem.id).map(func(c: Clue) -> String: return c.id), "cm": "one_tray_fifo",
		"prediction": problem.kpi})
	ui.a3_form.wait()
	ui.a3_form.check()


## Act II's main mission open, Joost's own words found: his talk opens.
func _open_silo(office: Office) -> void:
	office.session.missions.done_once["fix_unused_capacity"] = true
	office.session.accept("fix_silo_kpis")
	office.session.region.found["silo_kpis:4"] = true
	office.ui.after_action()


## A talk with Joost at Werkvoorbereiding, played to the state's moment:
## the opening, a few listening moves (the cue), the proposal's picks, the
## summary of an agreement, or a ruined talk (pushing early).
func _talk_to_joost(office: Office, state: String) -> void:
	_open_silo(office)
	office.people.refresh(office.session)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2  # beside his desk
	office.use(joost)
	office.rig.snap()
	var panel := office.ui.dialog_panel
	var moves: Array = []
	match state:
		"dialog_mid", "dialog_picks":
			moves = ["mood", "paraphrase", "inquiry", "reflect"]
		"dialog_summary":
			moves = ["mood", "paraphrase", "inquiry", "reflect", "silence", "empathy", "propose:lead_and_oldest", "ask_commitment"]
		"dialog_ruined":
			moves = ["show_data:silo_kpis:4", "propose:lead_and_oldest", "pressure"]
	for m: String in moves:
		var colon := m.find(":")
		panel.choose(m.left(colon) if colon >= 0 else m, m.substr(colon + 1) if colon >= 0 else "")
	if state == "dialog_picks":
		panel.open_picks("propose")


## The A3 a careful player would write (the cause read from the clues).
func _a3(office: Office) -> Dictionary:
	var s := office.session
	var problem: ProblemDef = s.region.problems["custom_design"]
	var evidence := s.clues_found("custom_design").filter(func(c: Clue) -> bool: return c.key) \
		.map(func(c: Clue) -> String: return c.id)
	return {"waste": "overprocessing", "cause": s.cause_options(problem.id).find(problem.root_cause),
		"evidence": evidence, "cm": "standard_designs", "prediction": "throughput"}
