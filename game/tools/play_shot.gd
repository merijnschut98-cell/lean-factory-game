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
## toasts of a slipping fix) · intussen (the A3 in: what happens while the
## Check runs, and the named skip) · terugblik (the card a resumed game opens
## with, after a session that finished the mission and left it alone) ·
## people_desks (Werkvoorbereiding and Intake at work, Anouk's name on hover) ·
## people_talk (E beside Joost: the prompt and the talk's placeholder toast) ·
## people_energy (the walk-around energy bars, from a stand-in energy_of) ·
## people_monteurs (Henk and Ahmed at the huddle table for Henk's mission, Marco
## walking in) · people_meetdata (Petra at the stand-in Meetdata desk) ·
## people_gemba (E at Werkvoorbereiding with the people there: do the stacks
## and the in-trays still read?).
## The mission is played through the UI's own handlers, as a player would;
## only the training states start with the training week.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"
## Days the standardised fix is left alone in the sustain state: long enough
## to slip below the check-in line (life ≈ 130 days, slipping from ≈ 84).
const SUSTAIN_DAYS := 100


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <office|overview|inspect|tools|a3|check|act|board|coach|map|codex|training_board|timelapse|sustain|intussen|terugblik|people_desks|people_talk|people_energy|people_monteurs|people_meetdata|people_gemba> <out.png> [frames]")
		quit(2)
		return
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	var state := args[0]
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
		"terugblik":
			_last_session(office)
			_stand_at(office, DESIGN)
			office.ui.close_panels()
			office.ui.open_terugblik(office.ui.session_layer.open_session(office.session))
		"people_desks", "people_talk", "people_energy", "people_monteurs", "people_meetdata", "people_gemba":
			_people(office, state)
		_:
			printerr("unknown state ", state)
			quit(2)
			return
	var frames := int(args[2]) if args.size() > 2 else 20
	for i in frames:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(args[1])
	if err != OK:
		printerr("cannot write ", args[1], ": ", error_string(err))
	quit(0 if err == OK else 1)


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


## The A3 a careful player would write (the cause read from the clues).
func _a3(office: Office) -> Dictionary:
	var s := office.session
	var problem: ProblemDef = s.region.problems["custom_design"]
	var evidence := s.clues_found("custom_design").filter(func(c: Clue) -> bool: return c.key) \
		.map(func(c: Clue) -> String: return c.id)
	return {"waste": "overprocessing", "cause": s.cause_options(problem.id).find(problem.root_cause),
		"evidence": evidence, "cm": "standard_designs", "prediction": "throughput"}
