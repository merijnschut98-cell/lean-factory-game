extends TestCase
## A scene's lines advance on the player's key (PLAN 2.13 A, Merijn's playtest
## 2026-10-19): a line stays until Spatie, Enter or a click; the first press
## shows the whole line, the second goes on; ← or Backspace re-reads; holding
## Spatie about a second asks to skip the scene; "Tekst loopt vanzelf door"
## (off by default) brings back the timed advance.

var settings := TestCase.scratch("scene_settings.cfg")


func _lines(texts: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: String in texts:
		out.append({"who": "Ruud", "text": t})
	return out


func _scene(texts: Array) -> SceneLines:
	var l := SceneLines.new()
	l.say(_lines(texts))
	return l


func test_no_line_moves_on_without_a_key_by_default() -> void:
	var l := _scene(["Eerste regel.", "Tweede regel."])
	assert_false(l.auto, "the timed advance is off by default")
	for i in 120:
		l.step(0.5)
	assert_eq(l.current().get("text"), "Eerste regel.", "a minute later the line is still there")
	assert_true(l.revealed(), "and shown in full")
	assert_true(l.holds(), "the scene waits for the player")
	l.free()


func test_the_first_press_completes_the_line_the_second_moves_on() -> void:
	var l := _scene(["Een regel die lang genoeg is om even te duren voor hij er staat.", "Tweede."])
	l.step(0.1)
	assert_false(l.revealed(), "the line is still appearing")
	l.press()
	assert_true(l.revealed(), "the first press shows all of it")
	assert_eq(l.current().get("text"), "Een regel die lang genoeg is om even te duren voor hij er staat.")
	l.press()
	assert_eq(l.current().get("text"), "Tweede.", "the second goes on")
	l.press()
	l.press()
	assert_false(l.speaking(), "past the last line the scene goes on")
	l.free()


func test_back_shows_the_previous_line_again() -> void:
	var l := _scene(["Een.", "Twee.", "Drie."])
	l.press()
	l.press()
	assert_eq(l.current().get("text"), "Twee.")
	l.back()
	assert_eq(l.current().get("text"), "Een.", "← re-reads")
	assert_true(l.revealed(), "a re-read line is shown whole")
	l.back()
	assert_eq(l.current().get("text"), "Een.", "nothing before the first")
	l.press()
	assert_eq(l.current().get("text"), "Twee.", "on again from there")
	l.free()


func test_back_remembers_about_ten_lines() -> void:
	var texts: Array = []
	for i in 15:
		texts.append("Regel %d." % i)
	var l := _scene(texts)
	for i in 14:
		l.press()
		l.press()
	assert_eq(l.current().get("text"), "Regel 14.")
	for i in 12:
		l.back()
	assert_eq(l.current().get("text"), "Regel %d." % (14 - SceneLines.HISTORY), "the history keeps %d lines" % SceneLines.HISTORY)
	l.free()


func test_back_works_across_two_runs_of_lines() -> void:
	var l := _scene(["Bij de lift."])
	l.press()
	l.press()
	assert_false(l.speaking())
	l.say(_lines(["Bij de trap."]))
	l.back()
	assert_eq(l.current().get("text"), "Bij de lift.", "the previous stop's line")
	l.free()


func test_holding_space_a_second_asks_to_skip() -> void:
	var l := _scene(["Een.", "Twee."])
	var asked := [0]
	l.skip_requested.connect(func() -> void: asked[0] += 1)
	l.hold_space(true)
	l.step(0.5)
	assert_eq(asked[0], 0, "half a second is a press, not a skip")
	l.hold_space(false)
	l.hold_space(true)
	l.step(0.6)
	assert_eq(asked[0], 0, "a release starts the count again")
	l.step(0.5)
	assert_eq(asked[0], 1, "a second held: skip")
	l.step(2.0)
	assert_eq(asked[0], 1, "once per hold")
	l.free()


func test_the_auto_setting_brings_back_the_timed_advance() -> void:
	var l := _scene(["Een.", "Twee."])
	l.auto = true
	var t := 0.0
	while l.current().get("text") == "Een." and t < 30.0:
		l.step(0.25)
		t += 0.25
	assert_eq(l.current().get("text"), "Twee.", "on by itself")
	assert_between(t, SceneLines.READ_MIN, SceneLines.READ_MAX + 1.0, "after its reading time")
	l.free()


func test_an_aside_moves_on_by_itself_and_holds_nothing() -> void:
	var l := SceneLines.new()
	l.say([{"who": "Ruud", "text": "Neem je tijd.", "aside": true}] as Array[Dictionary])
	assert_false(l.holds(), "a call-out from afar does not stop you")
	for i in int((SceneLines.READ_MAX + 2.0) / 0.25):
		l.step(0.25)
	assert_false(l.speaking())
	l.free()


func test_clear_drops_every_line_and_the_paper() -> void:
	var l := _scene(["Een.", "Twee."])
	l.paper(Color.WHITE, [] as Array[Control])
	l.clear()
	assert_false(l.speaking() or l.paper_up() or l.holds())
	l.free()


func test_the_setting_is_kept_and_off_when_missing() -> void:
	DirAccess.remove_absolute(settings)
	assert_false(SceneLines.auto_setting(settings), "off by default")
	assert_eq(SceneLines.set_auto_setting(true, settings), "")
	assert_true(SceneLines.auto_setting(settings))
	assert_eq(SceneLines.set_auto_setting(false, settings), "")
	assert_false(SceneLines.auto_setting(settings))
	DirAccess.remove_absolute(settings)


func test_the_skip_hint_shows_when_asked() -> void:
	var l := _scene(["Een."])
	assert_false(l.texts().has(SceneLines.SKIP_HINT))
	l.skip_hint(true)
	assert_true(l.texts().has(SceneLines.SKIP_HINT))
	l.skip_hint(false)
	assert_false(l.texts().has(SceneLines.SKIP_HINT))
	l.free()
