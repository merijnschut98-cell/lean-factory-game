extends SceneTree
## Screenshots of the character creator (PLAN 2.7b) and where its player shows
## up (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/creator_screen_shot.gd -- <state> <out.png>
## States: mail (HR's mail on the upright phone) · name (the camera on the
## first name, typed, with the badge preview) · haar (the hairstyles, the
## body's own and "Meer kapsels") · ogen (the eye colours as swatches, head and
## shoulders) · kleding (the outfits, from the knees up) · leave (Esc: the
## question) · sent (the photo taken: "Verzonden ✓") · portrait (the badge
## photo itself, 252 × 324) · title (the title menu with the made player's
## card) · office (the player in the office in the made look) · pause (the
## pause menu with "Uiterlijk") · edit (Uiterlijk open over the office).
## The saves live in this tool's own folder, never the player's.

const SCENE := "res://src/world/office/office.tscn"
const SHOT_SAVES := "user://shot_creator_saves"
const DESIGN := "place:connections.design"
const SEED := 4
const LOOK := {"lichaam": "vrouw", "huidskleur": "getint", "kapsel": "krullen", "haarkleur": "zwart",
	"ogen": "bruin", "gezicht": "mascara", "bril": "groot_rond", "kleding": "overshirt"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <mail|name|haar|ogen|kleding|leave|sent|portrait|title|office|pause|edit> <out.png>")
		quit(2)
		return
	var state := args[0]
	var out := args[1]
	match state:
		"portrait":
			var bytes := await PortraitPhoto.take(root, LOOK)
			var file := FileAccess.open(out, FileAccess.WRITE)
			if bytes.is_empty() or file == null:
				printerr("no photo")
				quit(1)
				return
			file.store_buffer(bytes)
			file.close()
			quit(0)
			return
		"title":
			await _title()
		"office", "pause", "edit":
			await _office(state)
		_:
			if await _creator(state):
				_save(out)
				return
	for i in 30:
		await process_frame
	_save(out)


func _save(out: String) -> void:
	var err := root.get_viewport().get_texture().get_image().save_png(out)
	if err != OK:
		printerr("cannot write ", out, ": ", error_string(err))
	quit(0 if err == OK else 1)


## True when the screenshot is due at once (the moment after the photo).
func _creator(state: String) -> bool:
	var screen := CreatorScreen.new()
	screen.setup(CreatorScreen.Mode.NEW, null, SEED)
	screen.build()
	root.add_child(screen)
	if state == "mail":
		return false
	screen.stage = CreatorScreen.Stage.MAIL
	screen.open_camera()
	screen.profile.look = CreatorLook.normalized(LOOK)
	screen.type_name("Samira")
	screen.booth.wear(screen.profile.look)
	match state:
		"name":
			screen.go_to(0)
		"haar":
			screen.go_to(screen.steps.find("kapsel"))
		"ogen":
			screen.go_to(screen.steps.find("ogen"))
		"kleding":
			screen.go_to(screen.steps.find("kleding"))
		"leave":
			screen.go_to(screen.steps.find("bril"))
			screen.ask_leave()
		"sent":
			screen.go_to(screen.steps.find("kleding"))
			for i in 30:
				await process_frame
			screen.shoot()
			while not screen._status.text.contains(CreatorScreen.SENT):
				await process_frame  # the photo is rendered, then "Verzonden ✓" shows
			for i in 8:
				await process_frame
			return true
	return false


func _player() -> PlayerProfile:
	var p := PlayerProfile.new()
	p.name = "Samira"
	p.look = CreatorLook.normalized(LOOK)
	p.portrait = await PortraitPhoto.take(root, p.look)
	return p


func _title() -> void:
	var slots := SaveSlots.new(SHOT_SAVES)
	slots.wipe()
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.player = await _player()
	s.region.advance_days(3)
	slots.save(1, s, SessionLayer.new())
	var old := GameSession.new_game(11, Catalog.DATA_DIR, false)
	slots.now = func() -> float: return Time.get_unix_time_from_system() - 86400.0
	slots.save(2, old, SessionLayer.new())  # a save from before the creator: the placeholder
	slots.now = func() -> float: return Time.get_unix_time_from_system()
	var menu: TitleMenu = load(TitleMenu.SCENE).instantiate()
	menu.saves = slots
	root.add_child(menu)


func _office(state: String) -> void:
	var slots := SaveSlots.new(SHOT_SAVES)
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.saves = slots
	office.new_player = await _player()
	root.add_child(office)
	office.ui.saves = slots
	var at := office.interactable(DESIGN)
	office.player.position = at.position + at.basis.z * 1.4
	office.player.face(at.basis.rotated(Vector3.UP, PI))  # facing the camera
	office.rig.yaw = office.player.rotation.y + PI
	office.rig.zoom(-6.0)
	office.rig.snap()
	if state == "office":
		return
	office.player.escape_pressed.emit()
	if state == "edit":
		office.ui.pause_menu.ask_look()
