extends SceneTree
## Screenshots of the office in a given play state (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/play_shot.gd -- <state> <out.png> [frames] [--at HH:MM] [--season name]
## `--at` moves the office clock forward to that time of day first (evening light, who is
## still at their desk); `--season` is parsed for Phase 3.3, not built yet.
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
## two found) · codex_company, codex_company_numbers (its Voltana page: sites, 2012; scrolled to the numbers) · simulating (Petra's screen's note while the Check runs) · fork_board
## (the board after the first mission: the fork as a pair) · debt (the HUD in
## debt, with the floor, and its toasts) · dialog_start, dialog_mid,
## dialog_summary, dialog_ruined (a talk with Joost) ·
## talk_face, talk_choose, talk_phone (S1-G: Joost speaks in a face shot, you
## choose in the two-shot; Mevrouw El Amrani on the phone) ·
## dialog_people, phone_notes (the phone's Wie is wie and Notities after it) · dialog_place (the
## team's menu with its people) · dialog_energy (the low-energy bar) ·
## intussen (the A3 in: what happens while the
## Check runs, and the named skip) · terugblik (the card a resumed game opens
## with, after a session that finished the mission and left it alone) ·
## people_desks (Werkvoorbereiding and Intake at work, Anouk's name on hover) ·
## people_talk (E beside Joost: the prompt and the talk's placeholder toast) ·
## people_greet (S1-C: Sanne turns on her chair and says hello by name) ·
## people_quick (E beside Rachid with nothing to discuss: his line about today) ·
## people_chatter (Sanne and Rachid at the coffee corner, the first line of their chatter) ·
## people_energy (the walk-around energy bars, from a stand-in energy_of) ·
## people_monteurs (Henk and Ahmed at the huddle table for Henk's mission, Marco
## walking in) · people_meetdata (Petra at the stand-in Meetdata desk) ·
## people_gemba (E at Werkvoorbereiding with the people there: do the stacks
## and the in-trays still read?) · people_kcc, people_lunch, people_directie,
## people_netstrategie, people_planning, people_revisie (2.1c: Esra and her agents,
## lunch in the kantine, Frank and Femke on the 2e, Linda and Mieke on the 1e) ·
## people_whiteboard, people_explainer (Ruud's whiteboard, and E there) ·
## play_day_0830, play_day_1230, play_day_1830 (PLAN 2.14 S1-A: the office keeps time:
## people coming in by the lift and the stairs in the morning light, lunch in the kantine,
## the 1e after six with the late stayers' desk lamps) · play_day_1830_strain (PLAN 3.1-A: the
## same after the stack at Werkvoorbereiding was left for three weeks: who is still in and
## who is slumped follows GameSession.strain_of) · play_home, play_home_fade (after
## five at the front door: "Naar huis", then the fade with the next morning's date) ·
## phone_home, phone_messages, phone_map, phone_settings (PLAN 2.14 S1-F: the phone raised on its
## home screen on Monday of the training week, on Berichten, on Kaart) ·
## title (the title menu over a few saves) · designer_loaded (the title menu after the
## training-week designer save went into the autosave: its card names the made player) ·
## title_replace, title_keep ("Nieuw spel" over a filled autosave: the
## question, then the slots to keep it in) · designer_page (Phase 3 3.0: the title menu's
## Ontwerper page over three designer saves, the last one made on old content) ·
## designer_replay, designer_replay_talk ("Praat opnieuw": the list of talks; Joost's talk
## replayed with "Gisteren verpest", his retry opening on screen) ·
## pause, pause_slots, pause_confirm (Esc in the office: the pause menu, its
## five slots, the overwrite question) ·
## open_reception … open_after (the opening, beat by beat; PLAN 2.7d) ·
## open_pause (Esc over Yvonne's line: the pause menu over the frozen scene) ·
## open_explainer (Ruud's whiteboard a few beats in: the counter; PLAN 2.13 A) ·
## place_mon_intake, place_mon_design, place_thu_intake, place_thu_design (PLAN
## 2.12: the team's menu on Monday and on Thursday of the training week: the
## people and their questions, then only the known tools that fit) ·
## tell_intake_high, tell_intake_low, tell_prep_high, tell_planning_high (PLAN 2.6:
## the 1e's props read the region; a long intake queue, then none) ·
## play_kcc_headset, play_phone_incoming, play_talk_expert (PLAN 2.4 and 2.15: mevrouw
## El Amrani's call on the KCC's headset, her call ringing on the phone at ten, Henk's
## expert talk on the yard after his first answer).
## play_van_ride, play_van_talk, play_van_choose (PLAN 2.15 S2-Y: riding along with Sandra,
## the edge of town going by; Henk's talk in the cab, his face, then the two of you) · play_opleidingsterrein (Henk shows Ahmed the
## joint at the practice trench) · play_yard_morning (08:45: the monteurs walk to their vans, R-1 #3).
## play_trafohuisje, play_explainer_trafo_fiets, play_explainer_trafo_cross,
## play_explainer_trafo_trafo (PLAN 2.7c S3-X: at the trafohuisje mock-up on the
## opleidingsterrein, its prompt; E there: "Hoe werkt het? 2" with the chain warm on the
## fiets, the cross-fade half-way, the trafo above its nameplate with the hours).
## play_tell_uitgifte_high, play_tell_storingsbord_high, play_tell_rack_high,
## play_tell_returns_high, play_tell_measurement_high, play_tell_yard_low (S3-Y: the yard's tells:
## the uitgiftelijst on the magazijn's counter and the storingsbord looked at closer, the joint
## shelf, the returns pallet, the complaints' tray at their highest; the list at its lowest).
## play_tell_kcc_high, play_tell_kcc_low, play_tell_kcc_look (R-1 #4: the KCC's callback board
## by the team lead's desk, full with the status callers on, nearly empty without; then looked at).
## play_desk, play_a3_clipboard, play_check_screen (PLAN 2.10 S3-D: your desk with your name
## plate, badge photo, the letter and your clipboard; E there, the A3 on the clipboard; the
## Check at Petra's screen, drawn as her monitor) · play_desk_thanks (R-1 #5: the winter promise
## kept, mevrouw El Amrani's thank-you letter lies beside her first one).
## play_2e_day, play_mt_room_scene, play_tell_obeya_high (PLAN 2.16 S3-A: the 2e at ten,
## coffee and chatter at its corner; Honderd dagen in the MT-kamer, you seated, Ruud at the
## table and Frank at the screen asking his question (play_mt_room_ruud: Ruud's first line,
## his face across the table); the directie's KPI board looked at closer) · tell_grid_study_high,
## tell_reinforcement_high, tell_congestion_high (the 2e's other tells at their highest).
## tell_revision_high, tell_meetdata_high, tell_closeout_high (PLAN 2.15: Revisie & GIS's
## sketches, Meetdata's whiteboard, its close-out cabinet) · tell_inspect (E beside the
## sketches: the camera moves in and one line says what you see).
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
	var shot := PlayShotArgs.parse(args)
	if shot["out"] == "":
		printerr("usage: -- <office|overview|inspect|tools|a3|check|act|board|coach|map|codex|training_board|timelapse|sustain|intussen|terugblik|people_desks|people_talk|people_energy|people_monteurs|people_meetdata|people_gemba|title|title_replace|title_keep|pause|pause_slots|pause_confirm> <out.png> [frames] [--at HH:MM] [--season <name>]")
		quit(2)
		return
	var state: String = shot["state"]
	if state in ["title", "title_replace", "title_keep", "designer_loaded", "designer_page", "designer_replay", "designer_replay_talk", "pause", "pause_slots", "pause_confirm"]:
		await _save_menus(state)
		_say_flag_errors(shot)
		if shot["at"] >= 0:
			printerr(PlayShotArgs.MENU_AT_NOTE)
		_capture(shot)
		return
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = state in ["training_board", "timelapse", "act0_note", "act0_ruud", "act0_cards", "phone_home",
			"phone_messages", "phone_map", "phone_settings"] \
		or state.begins_with("place_") or state.begins_with("open_")
	if state.begins_with("open_"):   # De eerste vijf minuten (PLAN 2.7d), as a new game
		office.opening = true
		office.new_player = PlayerProfile.new()
		office.new_player.name = "Noor"
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
		"play_desk", "play_desk_thanks", "play_a3_clipboard", "play_check_screen":
			await _desk(office, state)
		"coach":
			_investigate(office, false)
			office.interact(office.interactable("coach"))
			office.ui.coach_panel.ask()
		"map":
			office.ui.mission_board.accept(MISSION)
			office.ui.close_panels()
			_stand_at(office, INTAKE)
			office.player.rotation.y += deg_to_rad(-60)
			office.ui.toggle_phone(Phone.MAP)
		"codex":
			_investigate(office, true)
			office.session.region.profile.learn(["flow", "bottleneck_focus", "netbeheerder", "netcongestie", "kata_prediction"])
			office.ui.toggle_phone(Phone.CODEX)
		"discoveries":
			_investigate(office, false)
			office.session.discoveries.found["het_knelpunt_eerst"] = office.session.region.net.time
			office.session.discoveries.found["voorspeller"] = office.session.region.net.time
			office.ui.toggle_phone(Phone.CODEX)
			office.ui.codex.show_tab(CodexPanel.DISCOVERIES)
		"codex_company", "codex_company_numbers":   # the codex's Voltana page (PLAN 2.16, design §1.6)
			office.ui.toggle_phone(Phone.CODEX)
			office.ui.codex.show_tab(CodexPanel.COMPANY)
			if state == "codex_company_numbers":   # scrolled to the numbers once laid out
				var scroll: ScrollContainer = office.ui.codex._list.get_parent()
				create_timer(0.3).timeout.connect(func() -> void: scroll.scroll_vertical = 1500)
		"simulating":
			_investigate(office, true)
			office.interact(office.interactable("obeya"))
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.close_panels()
			office.ui.check_panel.show_simulating(office.ui.a3_form.problem_id)   # as open_check shows it
			office.ui.check_panel.show()
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
		"milestone_review", "milestone_question":   # S2-M: Honderd dagen in the MT-kamer, a line, then Frank's question
			_to_milestone_day(office, "review_100_days")
			office.ui.after_action()
			office.floors.go_to("second", "lift")
			var rect := OfficeFloors.room_rect(office.floors.markers()["room:mt_room"])
			office.player.position = Vector3(rect.get_center().x, 0.0, rect.end.y - 1.0)
			office.milestone.step(1.0)
			office.milestone.step(1.0)
			if state == "milestone_question":
				office.milestone.lines.finish()
			else:
				office.milestone.lines.next()
				office.milestone.lines.press()
		"dialog_start", "dialog_mid", "dialog_summary", "dialog_ruined":
			_talk_to_joost(office, state)
		"talk_face", "talk_choose", "talk_phone":
			await _staged_talk(office, state)
		"dialog_people", "phone_notes":   # Wie is wie, or Notities with the talk's note
			_talk_to_joost(office, "dialog_summary")
			office.ui.close_panels()
			office.ui.toggle_phone(Phone.PEOPLE if state == "dialog_people" else Phone.NOTES)
		"open_reception", "open_badge", "open_walk", "open_plan", "open_sanne", "open_marco", "open_design", \
				"open_door", "open_board", "open_letter", "open_phone", "open_evening", "open_anouk", "open_after", \
				"open_pause", "open_explainer":
			_opening(office, state)
		"phone_home", "phone_messages", "phone_map", "phone_settings":   # the phone raised (PLAN 2.14 S1-F)
			_phone(office, state)
		"act0_note":   # Monday morning: Ruud's note with the day's move card (PLAN 1.11a)
			_stand_at(office, DESIGN)
		"act0_ruud":   # Anouk at seven, one move, then Ruud names it on the summary
			var anouk := office.people.person("anouk")
			if anouk != null:
				office.player.position = anouk.position + anouk.basis.x * 1.1 - anouk.basis.z * 0.2
				office.use(anouk)
				office.rig.snap()
			else:
				office.ui.open_talk("anouk")
			for move in ["mood", "empathy", "open_question"]:
				office.ui.talk_view.choose(move)
			office.ui.talk_view.close_talk()
		"act0_cards":   # the codex's Gesprekken at the week's end: every card, the Friday one last
			for id in ["training_mon", "training_tue", "training_wed", "training_thu", "training_fri"]:
				office.session.missions.done_once[id] = true
			office.ui.toggle_phone(Phone.CODEX)
			office.ui.codex.show_tab(CodexPanel.TALKS)
		"explainers":
			office.session.explainers.see("spanning_stroom_weerstand")
			office.ui.toggle_phone(Phone.CODEX)
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
			office.ui.toggle_phone(Phone.NOTES)
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
		"place_mon_intake", "place_mon_design", "place_thu_intake", "place_thu_design":
			if state.begins_with("place_thu"):
				_play_to_thursday(office)
			var at := INTAKE if state.ends_with("intake") else DESIGN
			_stand_at(office, at)
			office.interact(office.interactable(at))
			if state.begins_with("place_thu"):
				office.ui.place_menu.use_tool("documents")
			else:
				office.ui.place_menu.ask("walk")
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
		"people_desks", "people_talk", "people_energy", "people_monteurs", "people_meetdata", "people_gemba", \
				"people_greet", "people_quick", "people_chatter":
			_people(office, state)
		"tell_intake_high", "tell_intake_low", "tell_prep_high", "tell_planning_high", "tell_revision_high", \
				"tell_meetdata_high", "tell_closeout_high":
			_tells(office, state)
		"tell_inspect":
			_tells(office, "tell_revision_high")
			office.player.position = Vector3(-16.6, 0, -12.2)
			office.use(OfficeTells.node(office.geometry, "revision_cabinet"))   # capture with ~25 frames
		"minimap", "minimap_floor", "minimap_near":
			_minimap(office, state)
		"yard", "yard_magazijn", "yard_werkplaats", "yard_vans":
			_yard(office, state)
		"people_kcc", "people_lunch", "people_directie", "people_netstrategie", "people_planning", "people_revisie", \
				"people_whiteboard", "people_explainer", "people_dirk", "people_gert":
			await _rooms(office, state)
		"play_day_0830", "play_day_1230", "play_day_1830", "play_day_1830_strain":
			await _day(office, state)
		"play_home", "play_home_fade":
			_home(office, state)
		"play_kcc_headset", "play_phone_incoming", "play_talk_expert":
			await _calls_and_experts(office, state)
		"play_van_ride", "play_van_talk", "play_van_choose", "play_opleidingsterrein", "play_yard_morning":
			await _yard_life(office, state)
		"play_trafohuisje", "play_explainer_trafo_fiets", "play_explainer_trafo_cross", "play_explainer_trafo_trafo":
			await _trafohuisje(office, state)
		"play_tell_uitgifte_high", "play_tell_storingsbord_high", "play_tell_rack_high", "play_tell_returns_high", \
				"play_tell_measurement_high", "play_tell_yard_low":
			_yard_tells(office, state)
		"play_tell_kcc_high", "play_tell_kcc_low", "play_tell_kcc_look":
			_kcc_tell(office, state)
		"play_2e_day", "play_mt_room_scene", "play_mt_room_ruud", "play_tell_obeya_high", "tell_grid_study_high", \
				"tell_reinforcement_high", "tell_congestion_high":
			await _second(office, state)
		"play_kpi_wall", "play_kpi_board", "play_kpi_board_result":
			await _kpi_board(office, state)
		"play_kpi_review_start", "play_kpi_review_scene":
			await _kpi_review_scene(office, state)
		_:
			printerr("unknown state ", state)
			quit(2)
			return
	_apply_clock(office, shot)
	_capture(shot)


## `--at` and `--season` of the shot: the office clock to that time of day; a bad flag is
## said and ignored; the season waits for 3.3.
func _apply_clock(office: Office, shot: Dictionary) -> void:
	_say_flag_errors(shot)
	if shot["at"] >= 0:
		office.set_minute_of_day(shot["at"])
	if shot["season"] != "":
		printerr("season not built yet: ", shot["season"])


func _say_flag_errors(shot: Dictionary) -> void:
	if shot["error"] != "":
		printerr(shot["error"])


## Wait `frames`, then save the screen to the shot's out file.
func _capture(shot: Dictionary) -> void:
	for i: int in shot["frames"]:
		await process_frame
	var err := root.get_viewport().get_texture().get_image().save_png(shot["out"])
	if err != OK:
		printerr("cannot write ", shot["out"], ": ", error_string(err))
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
	if state == "designer_loaded":   # MakeSaves gives the bot's save a made player (UX audit #1)
		var dir := SHOT_SAVES + "/designer"
		var spec: Dictionary = DesignerSaves.SAVES[0]
		var error := MakeSaves.write(spec, "expert", 11, dir)
		if error.is_empty():
			error = DesignerSaves.load_into_autosave(spec["slot"], dir, SHOT_SAVES)
		if not error.is_empty():
			printerr(error)
		state = "title"
	if state.begins_with("designer_"):
		var menu := _designer_page(slots)
		if state != "designer_page":
			menu.open_replay()
		if state == "designer_replay_talk":
			menu.replay.start("joost_output_kpi", TalkReplay.RUINED)
		return
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


## The title menu's Ontwerper page over three designer saves (the first played by the bot, the
## others written at once); the last carries an old content hash.
func _designer_page(slots: SaveSlots) -> TitleMenu:
	Designer.force(true)
	var dir := SHOT_SAVES + "/designer"
	for slot: String in DesignerSaves.SAVES.map(func(spec: Dictionary) -> String: return spec["slot"]):
		DirAccess.remove_absolute(SaveFile.path_of(slot, dir))
	var error := MakeSaves.write(DesignerSaves.SAVES[0], "expert", 11, dir)
	for spec: Array in [[DesignerSaves.SAVES[1], 45, DesignerSaves.content_hash()], [DesignerSaves.SAVES[2], 70, "old"]]:
		var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
		s.region.advance_days(spec[1])
		var made := {"persona": "expert", "seed": 11, "stop_day": float(spec[1]), "content_hash": spec[2]}
		error += GameSave.write(spec[0]["slot"], s, SessionLayer.new(), dir, 0.0, {"designer": made})
	if not error.is_empty():
		printerr(error)
	var menu: TitleMenu = load(TitleMenu.SCENE).instantiate()
	menu.saves = slots
	menu.designer_dir = dir
	root.add_child(menu)
	menu.open_designer()
	return menu


## Monday of the training week at Werkvoorbereiding, Ruud's note in: the phone
## raised on its home screen, on Berichten or on Kaart.
func _phone(office: Office, state: String) -> void:
	var ui := office.ui
	_stand_at(office, DESIGN)
	ui.toggle_phone({"phone_messages": Phone.MESSAGES, "phone_map": Phone.MAP, "phone_settings": Phone.SETTINGS}.get(
		state, Phone.HOME))


## The tells (PLAN 2.6) driven through the simulation: orders piled up at a step, or
## the intake queue emptied; the planning board shows its band directly.
func _tells(office: Office, state: String) -> void:
	var net := office.session.region.net
	match state:
		"tell_intake_high":
			for i in 60:
				net.open_order(net.stream("connections"))
		"tell_intake_low":
			net.queue_of(net.step_at("connections.intake")).clear()
		"tell_prep_high":
			_pile_up(net, "connections.design", 20)
		"tell_revision_high":
			_pile_up(net, "connections.revision", 16)
		"tell_meetdata_high", "tell_closeout_high":
			_pile_up(net, "connections.close_out", 40)
	office.tells.refresh()
	if state == "tell_planning_high":
		OfficeTells.show(office.geometry, {"planning_board": OfficeTells.HIGH})
	if state == "tell_meetdata_high":   # silent meters are counted from past registrations: shown directly
		OfficeTells.show(office.geometry, {"meter_board": OfficeTells.HIGH})
	print("tells: ", OfficeTells.readings(net), " -> ", OfficeTells.bands(net))
	_stand_at(office, DESIGN if state == "tell_prep_high" else INTAKE)
	var looks := {"tell_planning_high": [Vector3(15.6, 0, -6.2), Vector3(17.7, 0, -3.9)],
		"tell_revision_high": [Vector3(-15.6, 0, -11.2), Vector3(-17.7, 0, -12.6)],
		"tell_meetdata_high": [Vector3(-12.6, 0, -4.6), Vector3(-15.2, 0, -6.9)],
		"tell_closeout_high": [Vector3(-9.0, 0, -5.4), Vector3(-6.5, 0, -3.6)]}
	if looks.has(state):
		office.player.position = looks[state][0]
		office.player.face(Basis.looking_at(looks[state][1] - office.player.position))
	office.player.position -= office.player.basis.x * 0.8
	office.rig.yaw = office.player.rotation.y + deg_to_rad(25)
	office.rig.zoom(-4)
	office.rig.snap()


## `n` stand-in orders in the queue of the work step at `place`.
func _pile_up(net: Network, place: String, n: int) -> void:
	var step := net.step_at(place)
	for i in n:
		net.queue_of(step).append(WorkOrder.new(-1 - i, net.stream(place.get_slice(".", 0)), net.time))


## Your desk at Aansluitingen (PLAN 2.10, S3-D): Noor's desk with her name plate, her badge
## photo, the El Amrani letter and her clipboard (play_desk); E there, the A3 on the
## clipboard (play_a3_clipboard); the experiment run, the Check at Petra's screen
## (play_check_screen).
func _desk(office: Office, state: String) -> void:
	var me := office.session.player.copy()
	me.name = "Noor"
	me.portrait = await PortraitPhoto.take(root, me.look)
	office.session.player = me
	_investigate(office, true)
	office.ui.close_panels()
	_stand_at(office, OfficeDesk.ID)
	var desk := office.interactable(OfficeDesk.ID)
	match state:
		"play_desk":
			office.staging.frame(desk)
			office.rig.snap()
		"play_desk_thanks":
			office.session.missions.done_once["winter_el_amrani"] = true
			office.desk.refresh()
			office.staging.frame(desk)
			office.rig.snap()
		"play_a3_clipboard":
			office.interact(desk)
			office.ui.a3_form.fill(_a3(office))
			office.rig.snap()
		"play_check_screen":
			office.interact(desk)
			office.ui.a3_form.submit(_a3(office))
			office.ui.a3_form.wait()
			office.ui.close_panels()
			OfficeCheckScreen.refresh(office)   # each frame in the office
			_stand_at(office, OfficeCheckScreen.ID)
			office.interact(office.interactable(OfficeCheckScreen.ID))
			office.rig.snap()


## Stand a step behind the marker, looking the way it faces; the camera
## behind the player.
## The clock runs on to milestone `id`'s day (its opens_on), so the HUD's date is the
## scene's: 20 January for Honderd dagen, not the first Monday.
func _to_milestone_day(office: Office, id: String) -> void:
	var s := office.session
	var days := maxi(0, s.missions.defs[id].opens_on_day - s.missions.play_day())
	s.pass_time(SimCalendar.days(days))


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
			office.pointer.hover_person(people.person("anouk"))
		"people_talk":
			var joost := people.person("joost")
			office.player.position = joost.position + joost.basis.x * 0.8 + joost.basis.z * 0.3
			office.player.face(Basis.looking_at(joost.position - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(30)
			office.rig.snap()
			office.use(office.target_near(office.player.position))
		"people_greet", "people_quick":
			office.session.player.name = "Noor"   # a greeting by name
			var who := people.person("sanne" if state == "people_greet" else "rachid")
			office.player.position = who.position + who.basis.x * 1.3 + who.basis.z * 0.4
			office.player.face(Basis.looking_at((who.position - office.player.position) * Vector3(1, 0, 1)))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(35)
			office.rig.zoom(-5)
			office.rig.snap()
			if state == "people_quick":
				office.session.greet(who.id)   # greeted earlier today: E gives the quick line
				office.use(who)
			else:
				office.reactions.react()
		"people_chatter":
			var corner := office.reactions.corner_points()[0]
			people.set_process(false)   # no schedules yet (S1-A): keep them at the corner, not back at their desks
			people.person("sanne").settle({"at": corner + Vector3(-0.45, 0, 0.35), "face": Vector3(1, 0, -0.6), "pose": "idle"})
			people.person("rachid").settle({"at": corner + Vector3(0.45, 0, -0.2), "face": Vector3(-1, 0, 0.6), "pose": "talk"})
			office.player.position = corner + Vector3(2.6, 0, 1.2)
			office.player.face(Basis.looking_at(corner - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(-50)
			office.rig.zoom(-1)
			office.rig.snap()
			office.reactions.react()
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
			office.pointer.hover_person(people.person("henk"))
		"people_meetdata":
			var petra := people.person("petra")
			office.player.position = petra.position + Vector3(-1.4, 0, 0.6)
			office.player.face(Basis.looking_at(petra.position - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(-20)
			office.rig.snap()
			office.pointer.hover_person(petra)
		"people_gemba":
			_stand_at(office, DESIGN)
			office.interact(office.interactable(DESIGN))
			office.rig.snap()


## The minimap (2.1b): a main mission in Meetdata seen from Aansluitingen (the rim arrow
## and its distance), one on the 2e (the floor to go to), and Meetdata in view.
func _minimap(office: Office, state: String) -> void:
	var mission: String = {"minimap": "fix_done_but_not_closed", "minimap_floor": "fix_grid_study_queue",
		"minimap_near": "fix_done_but_not_closed"}[state]
	office.session.missions.progress[mission] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)
	if state == "minimap_near":
		office.player.position = Vector3(-6.5, 0, -8.0)
		office.player.face(Basis.looking_at(Vector3(-1, 0, 0)))
		office.rig.yaw = office.player.rotation.y
		office.rig.snap()
	else:
		_stand_at(office, DESIGN)
	office.minimap.refresh()


## The yard (2.2), its rooms open: out through the kantine's back door (yard), then at the
## magazijn's counter, the werkplaats's on-call table and the van with its doors open.
func _yard(office: Office, state: String) -> void:
	for m in ["fix_wrong_joint", "walk_outages", "fix_not_at_home", "save_henks_knowledge"]:
		office.session.missions.progress[m] = {"status": "active", "asks": {}, "seen": {}}
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("ground", "lift", true)
	office.floors.use(office.interactable("exit:yard"))
	var at := {"yard_magazijn": "place:outages.joint", "yard_werkplaats": "place:outages.locate",
		"yard_vans": "place:outages.repair"}
	if at.has(state):
		_stand_at(office, at[state])
		office.rig.zoom(1)
	else:
		office.rig.zoom(4)
	office.rig.snap()


## The customer call and the expert talk (S2-K): El Amrani's mission on (it opens the
## KCC), then at the headset or ten o'clock with the phone ringing; or Henk, his camera
## talk agreed, asked about joints.
func _calls_and_experts(office: Office, state: String) -> void:
	var s := office.session
	var view := office.ui.talk_view
	if state == "play_talk_expert":
		_yard(office, "yard")
		s.people.outcomes["henk_camera"] = "commitment"
		s.people.heard_facts["heard:henk_teach"] = true
		var henk := office.people.person("henk")
		office.player.position = henk.position + (office.player.position - henk.position).normalized() * 1.3
		office.use(henk)
		view.lines.finish()
		view.press_key(KEY_1)
		view.lines.finish()
		office.rig.snap()
		return
	for id in ["fix_unused_capacity", "fix_incomplete_application"]:
		s.missions.done_once[id] = true
	s.accept("fix_status_callers")
	s.pass_time(10 * 60 - s.minute_of_day())
	if state == "play_phone_incoming":
		_stand_at(office, DESIGN)
		office.ui.after_action()
		return
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("ground", "lift", true)
	_stand_at(office, OfficeHeadset.ID)
	office.interact(office.interactable(OfficeHeadset.ID))
	office.ui.hud.refresh()
	view.lines.finish()
	office.rig.snap()
	for i in 30:
		await process_frame


## The rooms peopled in 2.1c: the floor's room opened by its mission, the player a few
## steps from the person, the camera over the shoulder; the explainer from Ruud's board.
func _rooms(office: Office, state: String) -> void:
	var at := {"people_kcc": ["ground", "fix_status_callers", "kim", Vector3(0.6, 0, 2.2), 25.0],
		"people_lunch": ["ground", "", "kim", Vector3(1.2, 0, 2.4), 15.0],
		"people_directie": ["second", "fix_silo_kpis", "frank", Vector3(-1.8, 0, -1.4), -25.0],
		"people_netstrategie": ["second", "look_at_grid_study", "femke", Vector3(1.0, 0, 2.2), 25.0],
		"people_planning": ["first", "", "linda", Vector3(0.6, 0, -2.2), 20.0],
		"people_revisie": ["first", "", "mieke", Vector3(0.4, 0, 2.6), -20.0],
		"people_dirk": ["first", "fix_wrong_joint", "dirk", Vector3(1.6, 0, 1.2), 20.0],
		"people_gert": ["ground", "fix_digging_damage", "gert", Vector3(1.8, 0, 0.6), 25.0]}
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
		office.session.pass_time(12 * 60 + 20 - office.session.minute_of_day())   # the game's own lunch hour (S1-A)
		office.ui.after_action()
		office.people.refresh(office.session)
		office.daylight.update(office.session)
	var p := office.people.person(spec[2])
	office.player.position = p.position + spec[3]
	office.player.face(Basis.looking_at((p.position - office.player.position) * Vector3(1, 0, 1)))
	office.rig.yaw = office.player.rotation.y + deg_to_rad(spec[4])
	if state == "people_kcc":
		office.rig.zoom(-3)   # close enough to see the headsets
	office.rig.snap()
	office.pointer.hover_person(p)


## The office keeps time (S1-A): the game's clock moved on to the state's hour, the
## people seen a quarter of an hour before it (so those whose place changed since walk),
## a few seconds of the world, the camera over the floor.
func _day(office: Office, state: String) -> void:
	var spec: Array = {"play_day_0830": [8 * 60 + 30, "first", Vector3(7.0, 0, -6.6), 1.35, 2.0],
		"play_day_1230": [12 * 60 + 30, "ground", Vector3(-11.8, 0, -7.6), 1.9, 3.0],
		"play_day_1830": [18 * 60 + 30, "first", Vector3(5.8, 0, -6.0), -2.7, 3.0],
		"play_day_1830_strain": [18 * 60 + 30, "first", Vector3(5.8, 0, -6.0), -2.7, 3.0]}[state]
	if state == "play_day_1830_strain":   # the stack at Werkvoorbereiding, left for three weeks
		office.session.accept(MISSION)
		office.session.wait_days(21)
	var minute: int = spec[0]
	office.session.pass_time(minute - office.session.minute_of_day())
	office.ui.after_action()
	if office.floors.floor_id != spec[1]:
		office.floors.go_to(spec[1], "lift", true)
	var before := PeopleSession.new()
	before.session = office.session
	before.minute = minute - 15
	office.people.refresh(before)
	office.people.refresh(office.session)
	office.daylight.update(office.session)
	office.player.position = spec[2]
	office.player.face(Basis(Vector3.UP, spec[3]))
	office.rig.yaw = spec[3]
	office.rig.zoom(spec[4])
	office.rig.snap()
	for i in 90:   # people walk
		await process_frame


## The KPI board at the directie obeya (S3-B, PLAN 2.4c): the wall from the room
## (play_kpi_wall), E there with five magnets placed (play_kpi_board), and the choice
## hung: the chosen cards with their numbers and Ruud's question (play_kpi_board_result).
func _kpi_board(office: Office, state: String) -> void:
	var s := office.session
	s.region.advance_days(40)
	s.missions.progress["fix_silo_kpis"] = {"status": "completed", "asks": {}, "seen": {}}   # its room opened
	s.region.board.unlock(s.region.net.time)
	office.ui.after_action()
	office.floors.go_to("second", "lift")
	_stand_at(office, OfficeKpiBoard.ID)
	if state == "play_kpi_wall":
		office.player.position += office.interactable(OfficeKpiBoard.ID).basis.z * 2.0
		office.rig.snap()
		return
	office.use(office.interactable(OfficeKpiBoard.ID))
	var picks := [["intake", "intake_lead_time"], ["intake", "intake_complete"], ["work_prep", "work_prep_output"],
		["planners", "planners_on_time"], ["contact_centre", "contact_centre_resolved"]]
	if state == "play_kpi_board_result":
		picks += [["work_prep", "work_prep_oldest"], ["planners", "planners_oldest"], ["contact_centre", "contact_centre_reachable"]]
	for p: Array in picks:
		office.kpi_board.pick(p[0], p[1])
	if state == "play_kpi_board_result":
		office.kpi_board.hang_now()
	for i in 30:
		await process_frame


## Het eerste kwartaal (S3-B): Ruud and Frank at Directie & Obeya, Frank's second line
## (play_kpi_review_start); the board hung with flow KPIs, Frank reading them out
## (play_kpi_review_scene).
func _kpi_review_scene(office: Office, state: String) -> void:
	var s := office.session
	s.region.advance_days(40)
	s.missions.done_once["fix_silo_kpis"] = true
	s.pass_time(0)
	office.ui.after_action()
	office.floors.go_to("second", "lift")
	var rect := OfficeFloors.room_rect(office.floors.markers()["room:directors_obeya"])
	var door := office.in_office(office.floors.markers()["door:directors_obeya"]).origin * Vector3(1, 0, 1)
	var centre := Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	office.player.position = door + (centre - door).normalized() * 2.4   # just in through the door
	office.player.face(Basis.looking_at(centre - door))
	var m := office.milestone
	m.step(1.0)
	m.step(1.0)
	if state == "play_kpi_review_start":
		m.lines.next()
		m.lines.press()
	else:
		m.lines.finish()
		var picks := {"intake": ["intake_lead_time", "intake_complete"], "work_prep": ["work_prep_lead_time", "work_prep_ftr"],
			"planners": ["planners_on_time", "planners_oldest"], "contact_centre": ["contact_centre_resolved", "contact_centre_reachable"]}
		for pool: String in picks:
			for id: String in picks[pool]:
				office.kpi_board.pick(pool, id)
		office.kpi_board.hang_now()
		office.kpi_board.close()
	for i in 40:
		await process_frame


## The yard lives (S2-Y): the van ride with Sandra (the drive) or Henk (his talk in the
## cab, his face while he speaks); the opleidingsterrein after the ride with Henk; the yard at
## 08:45 with the monteurs on their way to their vans, seen at 08:30 (your day's start) first so they walk.
func _yard_life(office: Office, state: String) -> void:
	var mission: String = {"play_van_ride": "fix_not_at_home", "play_yard_morning": "fix_wrong_joint"}.get(
		state, "save_henks_knowledge")
	office.session.missions.progress[mission] = {"status": "active", "asks": {}, "seen": {}}
	var minute := 8 * 60 + 45 if state == "play_yard_morning" else 10 * 60 + 20
	office.session.pass_time(posmod(minute - office.session.minute_of_day(), SimCalendar.MINUTES_PER_DAY))
	office.ui.after_action()
	if state == "play_opleidingsterrein":
		office.session.missions.facts.add(OfficeYard.rode(mission))
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("yard", "exit", true)
	office.daylight.update(office.session)
	match state:
		"play_van_ride", "play_van_talk", "play_van_choose":
			office.interact(office.interactable("ride:" + mission))
			for i in (60 if state == "play_van_ride" else 260):
				await process_frame
			if state == "play_van_choose":
				office.ui.talk_view.lines.finish()
				for i in 30:
					await process_frame
		"play_opleidingsterrein":
			office.people.refresh(office.session)
			var henk := office.people.person("henk")
			office.player.position = henk.position + Vector3(2.4, 0, -1.6)
			office.player.face(Basis.looking_at((henk.position - office.player.position) * Vector3(1, 0, 1)))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(25)
			office.rig.zoom(-1)
			office.rig.snap()
		"play_yard_morning":
			var before := PeopleSession.new()
			before.session = office.session
			before.minute = minute - 15
			office.people.refresh(before)
			office.people.refresh(office.session)
			office.player.position = Vector3(-39.5, 0, -2.5)   # east of the bays, looking down the gaps
			office.player.face(Basis(Vector3.UP, 1.25))
			office.rig.yaw = 1.25
			office.rig.zoom(1)
			office.rig.snap()
			for i in 120:
				await process_frame


## The yard's tells (S3-Y) at their highest, at twenty past ten with the vans out: the
## uitgiftelijst on the magazijn's counter, seen from the monteurs' side and looked at closer;
## the storingsbord driven by a week of late outages and looked at closer (its line over it);
## the joint shelf, the returns pallet, the complaints' tray; play_tell_yard_low the list at
## its lowest.
func _yard_tells(office: Office, state: String) -> void:
	for m in ["fix_wrong_joint", "walk_outages", "walk_meters", "fix_inverters_tripping"]:
		office.session.missions.progress[m] = {"status": "active", "asks": {}, "seen": {}}
	office.session.pass_time(posmod(10 * 60 + 20 - office.session.minute_of_day(), SimCalendar.MINUTES_PER_DAY))
	office.ui.after_action()
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("yard", "exit", true)
	office.daylight.update(office.session)
	var net := office.session.region.net
	if state == "play_tell_storingsbord_high":
		for i in OfficeTells.THRESHOLDS["storingsbord"][1]:
			net.stream("outages").finished.append({"done_at": net.time, "lead_minutes": 400, "on_time": false,
				"reworks": 0, "failure_demand": false})
	office.tells.refresh()
	var shown := {"play_tell_uitgifte_high": "uitgiftelijst", "play_tell_rack_high": "magazijn_rack",
		"play_tell_returns_high": "van_returns", "play_tell_measurement_high": "measurement_tray"}
	if shown.has(state):   # read from past days' counts and the stock: shown directly
		OfficeTells.show(office.geometry, {shown[state]: OfficeTells.HIGH})
	if state == "play_tell_yard_low":
		OfficeTells.show(office.geometry, {"uitgiftelijst": OfficeTells.LOW})
	print("tells: ", OfficeTells.readings(net), " -> ", OfficeTells.bands(net))
	# Godot space: Blender (x, y) is (x, -y); [where you stand, what you look at, zoom]
	var spec: Array = {"play_tell_uitgifte_high": [Vector3(-32.7, 0, -12.9), Vector3(-32.85, 0, -13.92), -4.0],
		"play_tell_yard_low": [Vector3(-32.7, 0, -12.9), Vector3(-32.85, 0, -13.92), -3.0],
		"play_tell_storingsbord_high": [Vector3(-32.4, 0, 1.6), Vector3(-33.9, 0, 0.6), -4.0],
		"play_tell_rack_high": [Vector3(-28.8, 0, -19.6), Vector3(-28.8, 0, -21.5), -2.0],
		"play_tell_returns_high": [Vector3(-38.4, 0, -18.4), Vector3(-37.2, 0, -20.4), -3.0],
		"play_tell_measurement_high": [Vector3(-32.6, 0, 2.2), Vector3(-33.66, 0, 2.6), -4.0]}[state]
	office.player.position = spec[0]
	office.player.face(Basis.looking_at((spec[1] - office.player.position) * Vector3(1, 0, 1)))
	office.rig.yaw = office.player.rotation.y + deg_to_rad(25)
	office.rig.zoom(spec[2])
	office.rig.snap()
	var looked := {"play_tell_storingsbord_high": "storingsbord", "play_tell_uitgifte_high": "uitgiftelijst",
		"play_tell_yard_low": "uitgiftelijst"}   # behind the shed's wall: seen only up close
	if looked.has(state):   # capture within ~25 frames, before the line's time is up
		office.use(OfficeTells.node(office.geometry, looked[state]))


## The KCC's callback board (R-1 #4) at twenty past ten: full after weeks of the status callers
## (play_tell_kcc_high, and looked at closer: play_tell_kcc_look), a few notes in the base region
## (play_tell_kcc_low).
func _kcc_tell(office: Office, state: String) -> void:
	office.session.missions.progress["fix_status_callers"] = {"status": "active", "asks": {}, "seen": {}}
	if state != "play_tell_kcc_low":
		office.session.region.activate("status_callers")
		office.session.region.advance_days(14)
	office.session.pass_time(posmod(10 * 60 + 20 - office.session.minute_of_day(), SimCalendar.MINUTES_PER_DAY))
	office.ui.after_action()
	office.ui.let_ringing_go()   # mevrouw El Amrani's call, not this shot's subject
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("ground", "lift", true)
	office.daylight.update(office.session)
	office.tells.refresh()
	if state == "play_tell_kcc_low":
		OfficeTells.show(office.geometry, {"terugbelbord": OfficeTells.LOW})
	print("terugbelbord: ", OfficeTells.readings(office.session.region.net)["terugbelbord"])
	office.player.position = OfficeTerugbelbord.stand() + Vector3(-0.4, 0, 0.6)
	office.player.face(Basis.looking_at((OfficeTerugbelbord.AT - office.player.position) * Vector3(1, 0, 1)))
	office.rig.yaw = office.player.rotation.y + deg_to_rad(20)
	office.rig.zoom(-5.0)
	office.rig.snap()
	if state == "play_tell_kcc_look":
		office.use(OfficeTells.node(office.geometry, OfficeTerugbelbord.TELL))


## Going home (S1-A): the begane grond's front door at half past five, its prompt; then
## used, the fade with the next morning's date over the ontvangst.
func _home(office: Office, state: String) -> void:
	office.session.pass_time(17 * 60 + 30 - office.session.minute_of_day())
	office.ui.after_action()
	office.floors.go_to("ground", "lift", true)
	office.people.refresh(office.session)
	office.daylight.update(office.session)
	office.home.poll()
	var door := office.in_office(office.floors.markers()["arrive:entrance"])
	office.player.position = door.origin
	office.player.face(door.basis.rotated(Vector3.UP, PI))
	office.rig.yaw = office.player.rotation.y
	office.rig.snap()
	if state == "play_home_fade":
		office.use(office.target_near(office.player.position))


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


## Monday to Wednesday of the training week through the UI, with only what
## each day's menu offers (PLAN 2.12): questions, then shadow and documents,
## then the counts.
func _play_to_thursday(office: Office) -> void:
	var ui := office.ui
	_steps(office, [[INTAKE, "walk"], [DESIGN, "walk"]])
	ui.open_talk("anouk")   # Monday ends with Anouk at seven
	ui.talk_view.choose("close")
	ui.talk_view.close_talk()
	ui.close_panels()
	_steps(office, [[DESIGN, "shadow"], [DESIGN, "documents"], [INTAKE, "queue_count"], [DESIGN, "queue_count"]])
	ui.close_panels()


func _steps(office: Office, steps: Array) -> void:
	for step: Array in steps:
		office.interact(office.interactable(step[0]))
		if step[1] == "walk":
			office.ui.place_menu.ask("walk")
		else:
			office.ui.place_menu.use_tool(step[1])


## Monday to Friday's Check of the training week, through the UI.
func _play_week(office: Office) -> void:
	var ui := office.ui
	var s := office.session
	_play_to_thursday(office)
	_steps(office, [[DESIGN, "shadow"], [DESIGN, "time_study"], [DESIGN, "walk"]])
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


## The staged talk (phase 2 design §2): Joost's answer to a listening move in
## his face shot, typed out; then the choice in the two-shot; or the fourth
## call of Mevrouw El Amrani, on the phone.
func _staged_talk(office: Office, state: String) -> void:
	var view := office.ui.talk_view
	if state == "talk_phone":
		for id in ["fix_unused_capacity", "fix_incomplete_application"]:
			office.session.missions.done_once[id] = true
		office.session.accept("fix_status_callers")
		office.ui.after_action()
		_stand_at(office, "place:customer_contact.answer" if office.interactable("place:customer_contact.answer") != null
			else DESIGN)
		office.ui.open_talk("el_amrani")
	else:
		_open_silo(office)
		office.people.refresh(office.session)
		var joost := office.people.person("joost")
		office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2  # beside his desk
		office.use(joost)
		view.lines.finish()
		view.press_key(KEY_1)
	if state == "talk_choose":
		view.lines.finish()
	office.rig.snap()
	for i in 90:   # the line types itself out
		await process_frame


## A talk with Joost at Werkvoorbereiding, played to the state's moment:
## the opening, a few listening moves (the cue), the proposal's picks, the
## summary of an agreement, or a ruined talk (pushing early).
## De eerste vijf minuten (PLAN 2.7d), played to the state's moment with the
## scene's own steps; the player follows Ruud as a player would.
func _opening(office: Office, state: String) -> void:
	var o := office.first_day
	var run := func(done: Callable) -> void:
		var t := 0.0
		while not done.call() and t < 400.0:
			if o.guide != null and o._guide_route.is_empty() and office.floors.floor_id == "first" \
					and o.guide.visible and state != "open_plan":
				office.player.position = o.guide.position + (office.player.position - o.guide.position).normalized() * 1.6
			o.step(0.25)
			if o.lines.speaking() and not o.lines.asking() and not o.lines.paper_up() and not done.call():
				o.lines.press()   # the player reads along (lines wait for the key, PLAN 2.13 A)
			t += 0.25
		if not o.lines.revealed():
			o.lines.press()   # the line on screen whole
	var said := func(part: String) -> Callable:
		return func() -> bool: return str(o.lines.current().get("text", "")).contains(part)
	run.call(said.call("Ik herkende je"))
	if state == "open_reception":
		return
	if state == "open_pause":
		office.rig.snap()   # the paused tree runs no frame: the camera and the map as play left them
		office.minimap.map.visible = office.minimap.wanted()
		office.ui.saves = SaveSlots.new(SHOT_SAVES)
		office.ui.open_pause()
		return
	run.call(func() -> bool: return o.lines.paper_up())
	if state == "open_badge":
		return
	o.lines.close_paper()
	run.call(said.call("Welkom"))
	if state == "open_walk":
		office.rig.yaw = office.player.rotation.y + PI * 0.15
		office.rig.snap()
		return
	run.call(func() -> bool: return o._guide_route.is_empty() and not o.lines.speaking() and o.guide.position.z < -9.0)
	office.player.position = o.guide.position
	run.call(func() -> bool: return not o.guide.visible)
	office.floors.go_to("first", "stairs_up")
	run.call(said.call("plattegrond"))
	if state == "open_plan":
		return
	for pair: Array in [["open_sanne", "Sanne Bakker"], ["open_marco", "Ploegleider"], ["open_design", "Joost van Dijk"],
			["open_door", "Mijn kamer"]]:
		run.call(said.call(pair[1]))
		if state == pair[0]:
			office.rig.snap()
			return
	run.call(func() -> bool: return o.lines.asking())
	if state == "open_board":
		office.rig.snap()
		return
	if state == "open_explainer":
		o.lines.pick(0)
		run.call(func() -> bool: return office.explainer != null)
		office.explainer.press(KEY_SPACE)
		office.explainer.press(KEY_SPACE)
		return
	o.lines.pick(1)
	run.call(func() -> bool: return o.lines.paper_up())
	if state == "open_letter":
		return
	o.lines.close_paper()
	run.call(func() -> bool: return o.lines.phone_texts().size() >= 2)
	if state == "open_phone":
		return
	run.call(func() -> bool: return office.ui.session_layer.opening_beat == Opening.ANOUK)
	if state == "open_evening":
		return
	var anouk := office.people.person("anouk")
	office.player.position = anouk.position + Vector3(3.5, 0, -2.5)
	run.call(func() -> bool: return office.ui.talk_view.visible)
	office.rig.snap()
	if state == "open_anouk":
		return
	for move in ["mood", "empathy", "open_question", "reflect"]:
		office.ui.talk_view.choose(move)
	office.ui.talk_view.close_talk()


func _talk_to_joost(office: Office, state: String) -> void:
	_open_silo(office)
	office.people.refresh(office.session)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2  # beside his desk
	office.use(joost)
	office.rig.snap()
	var panel := office.ui.talk_view
	var moves: Array = []
	match state:
		"dialog_mid":
			moves = ["mood", "paraphrase", "inquiry", "reflect"]
		"dialog_summary":
			moves = ["mood", "paraphrase", "inquiry", "reflect", "silence", "empathy", "propose:lead_and_oldest", "ask_commitment"]
		"dialog_ruined":
			moves = ["show_data:silo_kpis:4", "propose:lead_and_oldest", "pressure"]
	for m: String in moves:
		var colon := m.find(":")
		panel.choose(m.left(colon) if colon >= 0 else m, m.substr(colon + 1) if colon >= 0 else "")
	panel.lines.finish()   # their words heard: the choice, or the note


## The A3 a careful player would write (the cause read from the clues).
func _a3(office: Office) -> Dictionary:
	var s := office.session
	var problem: ProblemDef = s.region.problems["custom_design"]
	var evidence := s.clues_found("custom_design").filter(func(c: Clue) -> bool: return c.key) \
		.map(func(c: Clue) -> String: return c.id)
	return {"waste": "overprocessing", "cause": s.cause_options(problem.id).find(problem.root_cause),
		"evidence": evidence, "cm": "standard_designs", "prediction": "throughput"}


## The 2e alive (PLAN 2.16 S3-A), its rooms opened by their missions: the coffee corner at
## ten (seen a quarter of an hour earlier first, so they walk there and talk); Honderd dagen
## in the MT-kamer; a tell at its highest, the KPI board looked at closer.
func _second(office: Office, state: String) -> void:
	# (the congestion desk's mission rings Ilse's call at ten: left shut for the day's view)
	for m in ["fix_silo_kpis", "look_at_grid_study"] + ([] if state == "play_2e_day" else ["fix_unused_capacity"]):
		office.session.missions.progress[m] = {"status": "active", "asks": {}, "seen": {}}
	if state.begins_with("play_mt_room"):
		_to_milestone_day(office, "review_100_days")
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.ui.after_action()
	office.floors.go_to("second", "lift", true)
	match state:
		"play_2e_day":
			var minute := 10 * 60 + 6
			office.session.pass_time(minute - office.session.minute_of_day())
			office.ui.after_action()
			var before := PeopleSession.new()
			before.session = office.session
			before.minute = minute - 15
			office.people.refresh(before)
			office.people.refresh(office.session)
			office.daylight.update(office.session)
			for i in 600:   # a minute of the world: they walk to the coffee corner
				office.people._process(0.1)
			office.player.position = Vector3(-11.6, 0, -3.0)
			office.player.face(Basis.looking_at(Vector3(-14.0, 0, -3.6) - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(30)
			office.rig.zoom(-1.0)
			office.rig.snap()
			office.reactions.chatter(office.player.position)   # capture soon (~10 frames), while the line shows
		"play_mt_room_scene", "play_mt_room_ruud":
			var rect := OfficeFloors.room_rect(office.floors.markers()["room:mt_room"])
			office.player.position = Vector3(rect.get_center().x, 0.0, rect.end.y - 1.0)
			office.milestone.step(1.0)
			office.milestone.step(1.0)
			if state == "play_mt_room_scene":
				office.milestone.lines.finish()   # Frank's question: the two of you, Ruud at the table
			for i in 90:   # the camera moves in
				await process_frame
		_:
			var net := office.session.region.net
			match state:
				"play_tell_obeya_high":
					for s in net.streams:
						for i in 40:
							s.finished.append({"done_at": net.time, "lead_minutes": 60, "on_time": false, "reworks": 0,
								"failure_demand": false})
				"tell_grid_study_high":
					_pile_up(net, "connections.grid_study", 20)
			office.tells.refresh()
			if state == "tell_reinforcement_high":   # a wait of months: shown directly
				OfficeTells.show(office.geometry, {"reinforcement_board": OfficeTells.HIGH})
			if state == "tell_congestion_high":
				OfficeTells.show(office.geometry, {"congestion_list": OfficeTells.HIGH})
			print("tells: ", OfficeTells.readings(net), " -> ", OfficeTells.bands(net))
			var spec: Array = {"play_tell_obeya_high": [Vector3(4.9, 0, -3.2), Vector3(4.06, 0, -3.5)],
				"tell_grid_study_high": [Vector3(5.2, 0, -10.2), Vector3(4.0, 0, -11.25)],
				"tell_reinforcement_high": [Vector3(1.8, 0, -11.6), Vector3(0.0, 0, -12.6)],
				"tell_congestion_high": [Vector3(20.4, 0, -10.4), Vector3(19.4, 0, -11.6)]}[state]
			office.player.position = spec[0]
			office.player.face(Basis.looking_at(spec[1] - office.player.position))
			office.rig.yaw = office.player.rotation.y + deg_to_rad(25)
			office.rig.zoom(-4)
			office.rig.snap()
			if state == "play_tell_obeya_high":   # capture with ~25 frames, before the line's time is up
				office.use(OfficeTells.node(office.geometry, "obeya_board"))


## The trafohuisje on the opleidingsterrein (S3-X): the ground open with Henk's knowledge,
## you at the mock-up's doors; E there opens "Hoe werkt het? 2", driven by hand to a beat.
func _trafohuisje(office: Office, state: String) -> void:
	office.session.missions.progress["save_henks_knowledge"] = {"status": "active", "asks": {}, "seen": {}}
	office.session.pass_time(posmod(10 * 60 + 20 - office.session.minute_of_day(), SimCalendar.MINUTES_PER_DAY))
	office.ui.after_action()
	office.floors._process(OfficeFloors.POLL_SECONDS)
	office.floors.go_to("yard", "exit", true)
	office.daylight.update(office.session)
	var at := office.interactable(OfficeTrafohuisje.ID)
	if at == null:
		printerr("no trafohuisje on the yard")
		return
	var stand := OfficeTrafohuisje.stand(office)
	office.player.position = stand.origin + stand.basis.z * 0.3
	office.player.face(Basis.looking_at(stand.origin - stand.basis.z * 2.0 - office.player.position))
	office.rig.yaw = office.player.rotation.y + deg_to_rad(20)
	office.rig.snap()
	if state == "play_trafohuisje":
		for i in 20:
			await process_frame
		return
	office.player.position = stand.origin
	office.interact(at)
	var v := office.explainer
	v.set_process(false)
	var play := func(seconds: float) -> void:
		var t := 0.0
		while t < seconds:
			v.step(1.0 / 30.0)
			t += 1.0 / 30.0
	var skip_to := func(id: String) -> void:
		var guard := 0
		while v.beats.beat_id() != id and guard < 30:
			v.press(KEY_SPACE)
			guard += 1
	skip_to.call("f2")
	for i in 3:
		v.press(KEY_UP)
	play.call(8.0)
	if state == "play_explainer_trafo_cross":
		skip_to.call("x")
		play.call(0.7)
	elif state == "play_explainer_trafo_trafo":
		skip_to.call("t4")
		v.press(KEY_UP)
		play.call(8.0)
	for i in 30:
		await process_frame
