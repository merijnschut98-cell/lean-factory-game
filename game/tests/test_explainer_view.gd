extends TestCase
## The explainer on Ruud's whiteboard as the player meets it: T5 (Esc and
## [Klaar] close it into the room, the explainer filed), T6 (no quiz: no
## button but the controls' own), T9 (no formula on screen until asked) and
## T10 (the analogy maps part for part over the cross-fade). Time is stepped
## by hand, so every frame is the same on every run.

const ID := "spanning_stroom_weerstand"
var _closed: Array[String] = []


func _view(options: Dictionary = {}) -> ExplainerView:
	var v := ExplainerView.create(ID, options)
	assert_eq(v.error, "", "opens")
	v.closed.connect(func(id: String) -> void: _closed.append(id))
	return v


## Step until the beat changes (reading beats move on by themselves).
func _past(v: ExplainerView, id: String) -> void:
	var t := 0.0
	while v.beats.beat_id() == id and not v.beats.done and t < 60.0:
		v.step(0.25)
		t += 0.25


func _to(v: ExplainerView, id: String) -> void:
	var guard := 0
	while v.beats.beat_id() != id and not v.beats.done and guard < 40:
		v.press(KEY_SPACE)
		guard += 1
	v.step(0.01)


func _formula() -> RegEx:
	return RegEx.create_from_string("[=÷×²·Ω]|ΔU|\\b[IUPR]\\s*[=/]")


func _formulas_on_screen(v: ExplainerView) -> Array[String]:
	var re := _formula()
	return v.visible_texts().filter(func(t: String) -> bool: return re.search(t) != null)


# ── T5: closing ─────────────────────────────────────────────────────────────

func test_esc_closes_at_once_and_files_the_explainer() -> void:
	for stop in ["a1", "a4", "x", "r6"]:
		_closed.clear()
		var book := ExplainerLog.new()
		var v := _view({"log": book})
		_to(v, stop)
		v.press(KEY_ESCAPE)
		assert_eq(_closed, [ID] as Array[String], stop + ": back in the room")
		assert_true(book.has_seen(ID), stop + ": in the codex")
		assert_false(v.is_open(), stop)
		v.free()


func test_klaar_closes_too() -> void:
	var book := ExplainerLog.new()
	var v := _view({"log": book})
	v.klaar.pressed.emit()
	assert_eq(_closed, [ID] as Array[String])
	assert_true(book.has_seen(ID))
	v.free()


func test_the_last_beat_closes_it() -> void:
	var v := _view()
	_to(v, "r8b")
	_past(v, "r8b")
	assert_eq(_closed, [ID] as Array[String])
	v.free()


# ── T6: no quiz ─────────────────────────────────────────────────────────────

func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button:
			out.append(n)
		stack.append_array(n.get_children())
	return out


func test_the_only_buttons_are_klaar_and_the_reveal_corner() -> void:
	var v := _view()
	_to(v, "r3")
	var buttons := _buttons(v)
	assert_eq(buttons.size(), 2)
	assert_true(buttons.has(v.klaar))
	assert_true(buttons.has(v.reveal_corner))
	v.free()


func test_the_codex_adds_only_the_skin_tab() -> void:
	var v := _view({"codex": true})
	var buttons := _buttons(v)
	assert_eq(buttons.size(), 4, "Klaar, the reveal corner, De tuin, De meterkast")
	v.free()


func test_the_controls_answer_clicks_on_the_drawing_not_buttons() -> void:
	var v := _view()
	var hit: Dictionary = v.figure.hits.filter(func(h: Dictionary) -> bool: return h["control"] == "kettle" and h["skin"] == "tuin")[0]
	var r: Array = hit["rect"]
	v.click_figure(Vector2(r[0] + r[2] / 2.0, r[1] + r[3] / 2.0))
	assert_true(v.beats.on["kettle"], "clicking the big valve opens it")
	assert_eq(v.beats.beat_id(), "a2")
	v.free()


func test_keys_one_to_three_and_h() -> void:
	var v := _view()
	v.press(KEY_2)
	v.press(KEY_3)
	assert_eq(v.beats.on, {"lamp": false, "kettle": true, "heater": true})
	v.press(KEY_H)
	assert_eq(v.beats.haspel, 1, "the reel waits for R8")
	_to(v, "r8a")
	v.press(KEY_H)
	assert_eq(v.beats.haspel, 2)
	v.free()


# ── T9: no formula until asked ──────────────────────────────────────────────

func test_no_formula_on_screen_through_every_beat_and_switch_state() -> void:
	var v := _view()
	var guard := 0
	while not v.beats.done and guard < 40:
		for mask in 8:
			for i in 3:
				var want := bool(mask & (1 << i))
				var id: String = ExplainerBeats.LOADS[i]
				if v.beats.on[id] != want and v.beats.beat().get("wait_for", "") == "":
					v.beats.on[id] = want  # set without answering a wait
			v.step(0.05)
			assert_eq(_formulas_on_screen(v), [] as Array[String], "%s, switches %d" % [v.beats.beat_id(), mask])
		v.press(KEY_SPACE)
		guard += 1
	v.free()


func test_the_reveal_shows_the_sums_and_folds_them_away() -> void:
	var v := _view()
	_to(v, "r1")
	assert_false(v.reveal_corner.visible, "no reveal before R2")
	_to(v, "r2")
	assert_true(v.reveal_corner.visible, "from R2 on")
	v.press(KEY_2)
	v.step(0.1)
	v.press(KEY_R)
	assert_false(_formulas_on_screen(v).is_empty(), "the strip shows the sums")
	assert_true(v.visible_texts().any(func(t: String) -> bool: return t.contains("230 V")), "with the live numbers")
	v.press(KEY_R)
	assert_eq(_formulas_on_screen(v), [] as Array[String], "folded: gone")
	v.free()


func test_the_content_strings_are_plain() -> void:
	var def: ExplainerDef = ExplainerDef.load_all()["explainers"][ID]
	var digit := RegEx.create_from_string("\\d")
	for text in def.plain_texts():
		assert_eq(_formula().search(text), null, text)
		assert_eq(digit.search(text), null, text)


# ── T7: never the answer ────────────────────────────────────────────────────

func test_no_string_names_a_missions_answer() -> void:
	var def: ExplainerDef = ExplainerDef.load_all()["explainers"][ID]
	var all := def.plain_texts()
	all.append(def.name)
	for line: Dictionary in def.reveal["lines"]:
		all.append_array(line.values())
	var names: Array[String] = []
	for kpi: Dictionary in JsonFile.read_dict("res://data/kpis.json")["data"]["kpis"]:
		names.append(kpi["name"])
	for stream: Dictionary in JsonFile.read_dict("res://data/value_streams.json")["data"]["streams"]:
		for step: Dictionary in stream["steps"]:
			names.append(step["name"])
	assert_true(names.size() > 20, "the steps and KPIs are read")
	for token in ["3x25", "3×25", "zonnepaneel", "omvormer", "253", "trafo", "transformator", "aftakking",
			"warmtepomp", "el amrani", "netstudie", "wachtlijst", "verzwar"]:
		names.append(token)
	for text: String in all:
		for name in names:
			assert_false(text.to_lower().contains(name.to_lower()), "%s names %s" % [text, name])


# ── T10: the analogy maps ───────────────────────────────────────────────────

func test_every_mapping_row_names_a_tuin_and_a_meterkast_layer() -> void:
	var v := _view()
	for row: Dictionary in v.def.mapping:
		var pair: Array = row["pair"]
		assert_eq(v.figure.layer(pair[0]).get("skin"), "tuin", str(pair))
		assert_eq(v.figure.layer(pair[1]).get("skin"), "meterkast", str(pair))
		assert_eq(v.figure.layer(pair[0]).get("pair"), pair[1], "the manifest pairs them back")
	v.free()


func test_after_the_cross_fade_the_garden_is_gone_and_the_real_parts_are_there() -> void:
	var v := _view()
	v.press(KEY_2)
	v.press(KEY_3)
	_to(v, "a4")
	for layer: Dictionary in v.figure.layers:
		if layer["skin"] == "tuin":
			assert_eq(v.skin_weight(layer["id"]), 1.0, layer["id"] + " before X")
		elif layer["skin"] == "meterkast":
			assert_eq(v.skin_weight(layer["id"]), 0.0, layer["id"] + " before X")
	var heat_before := v.heat_level()
	_to(v, "x")
	assert_near(v.heat_level(), heat_before, 0.02, "the cable keeps the warmth the hose had")
	v.step(4.0)
	for layer: Dictionary in v.figure.layers:
		if layer["skin"] == "tuin":
			assert_eq(v.alpha(layer["id"]), 0.0, layer["id"] + " after X")
	for row: Dictionary in v.def.mapping:
		assert_eq(v.skin_weight(row["pair"][1]), 1.0, row["pair"][1] + " after X")
	for id in ["switch_kettle_on", "switch_heater_on", "switch_lamp_off", "cable_thin", "appliances", "stroomtang"]:
		assert_eq(v.alpha(id), 1.0, id + " shown")
	for id in ["switch_kettle_off", "cable_thick", "cordlead2"]:
		assert_eq(v.alpha(id), 0.0, id + " hidden")
	assert_eq(v.beats.on, {"lamp": false, "kettle": true, "heater": true}, "what was open is on")
	v.free()


func test_the_cross_fade_goes_part_by_part() -> void:
	var v := _view()
	_to(v, "x")
	v.step(0.2)
	var first := v.group_mix("source")
	var last := v.group_mix("reels")
	assert_true(first > last, "the tap turns into the group before the reels turn (%s, %s)" % [first, last])
	assert_true(v.tags_visible(), "Ruud holds up his marker tags")
	v.step(4.0)
	assert_false(v.tags_visible(), "for three seconds")
	v.free()
