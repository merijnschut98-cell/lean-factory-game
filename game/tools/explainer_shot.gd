extends SceneTree
## Screenshots of "Hoe werkt het? 1" (PLAN 2.7c), one per beat, for visual
## review (needs a display, e.g. Xvfb):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://tools/explainer_shot.gd -- <mode> <out_prefix>
## Modes: beats (a player who follows Ruud, a shot at every beat; the reveal
## opened at R5) · contact (ten frames through the cross-fade X) · codex
## (the codex revisit, meterkast and tuin) · small (A1 and R5 at whatever
## --resolution is given, e.g. 1280x720).
## Each shot is <out_prefix>_<name>.png. The view's clock is stepped by hand,
## so the shots are the same on every run.

const ID := "spanning_stroom_weerstand"
## Seconds to let each beat play before its shot (enough for the needles,
## the spray and the warming cable to settle into what the beat shows).
const SETTLE := {"a1": 1.0, "a2": 2.0, "a3": 5.0, "a4": 6.0, "x": 0.8}

var _prefix := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <beats|contact|codex|small> <out_prefix>")
		quit(2)
		return
	_prefix = args[1]
	var bg := ColorRect.new()
	bg.color = Color("#dfe3e6")  # the whiteboard behind the sheet
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	match args[0]:
		"beats":
			await _beats()
		"contact":
			await _contact()
		"codex":
			await _codex()
		"small":
			await _small()
		_:
			printerr("unknown mode ", args[0])
			quit(2)
			return
	quit(0)


func _open(options: Dictionary = {}) -> ExplainerView:
	var v := ExplainerView.open(root, ID, options)
	v.set_process(false)
	v.set_process_input(false)
	return v


func _play(v: ExplainerView, seconds: float) -> void:
	var t := 0.0
	while t < seconds and v.is_open():
		v.step(1.0 / 30.0)
		t += 1.0 / 30.0


func _shot(name: String) -> void:
	for i in 4:
		await process_frame
	var path := "%s_%s.png" % [_prefix, name]
	var err := root.get_viewport().get_texture().get_image().save_png(path)
	print("saved " if err == OK else "cannot write ", path)


## A player who follows the prompts: the big valve, a second one, the
## heater off and on again in the meterkast, the thick reel at R8.
func _beats() -> void:
	var v := _open()
	_play(v, 0.5)
	await _shot("a1")
	v.press(KEY_2)
	_play(v, SETTLE["a2"])
	await _shot("a2")
	v.press(KEY_3)
	_play(v, SETTLE["a3"])
	await _shot("a3")
	_skip_to(v, "a4")
	_play(v, SETTLE["a4"])
	await _shot("a4")
	_skip_to(v, "x")
	_play(v, SETTLE["x"])
	await _shot("x")
	for id in ["r1", "r2", "r3"]:
		_skip_to(v, id)
		_play(v, 3.0)
		await _shot(id)
	v.press(KEY_3)  # the kettle alone for a while
	_skip_to(v, "r4_already_on")
	_play(v, 3.0)
	await _shot("r4")
	_skip_to(v, "r5")
	_play(v, 6.0)
	await _shot("r5")
	v.press(KEY_R)
	_play(v, 0.3)
	await _shot("reveal")
	v.press(KEY_R)
	_skip_to(v, "r6")
	_play(v, 1.0)
	await _shot("r6")
	v.press(KEY_3)
	_play(v, 8.0)
	await _shot("r7")
	_skip_to(v, "r8a")
	_play(v, 1.0)
	await _shot("r8a")
	v.press(KEY_H)
	_play(v, 0.3)
	await _shot("r8_swap")
	_play(v, 8.0)
	await _shot("r8b")


func _skip_to(v: ExplainerView, id: String) -> void:
	var guard := 0
	while v.is_open() and v.beats.beat_id() != id and guard < 30:
		v.press(KEY_SPACE)
		guard += 1
	if v.beats.beat_id() != id:
		printerr("did not reach ", id, " (at ", v.beats.beat_id(), ")")


## Ten frames through the cross-fade (V2: no pop; one pair at a time).
func _contact() -> void:
	var v := _open()
	v.press(KEY_2)
	v.press(KEY_3)
	_skip_to(v, "x")
	for i in 10:
		await _shot("x_%02d" % i)
		_play(v, 0.2)


func _codex() -> void:
	var book := ExplainerLog.new()
	var v := _open({"codex": true, "log": book})
	v.press(KEY_2)
	_play(v, 6.0)
	await _shot("codex_meterkast")
	v.press(KEY_R)
	_play(v, 0.2)
	await _shot("codex_reveal")
	v.press(KEY_R)
	(v._tabs[0] as Button).pressed.emit()
	_play(v, 3.0)
	await _shot("codex_tuin")


func _small() -> void:
	var v := _open()
	_play(v, 0.5)
	await _shot("a1")
	v.press(KEY_2)
	_skip_to(v, "r5")
	_play(v, 6.0)
	await _shot("r5")
