extends SceneTree
## Screenshots of the office in a given play state (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/play_shot.gd -- <state> <out.png> [frames]
## States: office (first person at Werkvoorbereiding, HUD and prompt) ·
## tools (the team's menu after some gemba work) · a3 (the A3, filled in) ·
## check (the Check result after the experiment) · act (the score after Act) ·
## board (the mission board) · coach (the coach's question) · map (the
## player map with the mission taken) · codex (the glossary after some
## gemba work and an extra few concepts) · free (the mouse freed with Esc) ·
## training_board (Monday of the training week: the board with the skip) ·
## timelapse (the week played to Friday: the Act and the month ahead, with and
## without the standard).
## The mission is played through the UI's own handlers, as a player would;
## only the training states start with the training week.

const SCENE := "res://src/world/office/office.tscn"
const MISSION := "fix_custom_design"
const DESIGN := "place:connections.design"
const INTAKE := "place:connections.intake"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <office|tools|a3|check|act|board|coach|map|codex|free|training_board|timelapse> <out.png> [frames]")
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
		"check", "act":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.a3_form.check()
			if state == "act":
				office.ui.check_panel.act(true)
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
		"free":
			_stand_at(office, DESIGN)
			office.player.escape_pressed.emit()
		"board", "training_board":
			_stand_at(office, "mission_board")
			office.interact(office.interactable("mission_board"))
		"timelapse":
			_play_week(office)
			office.ui.check_panel.act(false)
			office.ui.check_panel.fade_forecast()
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


## Stand a step behind the marker, looking the way it faces.
func _stand_at(office: Office, id: String) -> void:
	var at := office.interactable(id)
	office.player.position = at.position + at.basis.z * 0.6
	office.player.face(at.basis)
	office.player.camera.rotation.x = deg_to_rad(-12)


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
