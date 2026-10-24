extends TestCase
## "Hoe werkt het? 2: de transformator" as the player meets it (spec
## 2026-10-24-explainer-transformator §6): T4 the parts load, T5 Ruud's beats
## in order with their variants, T6 no quiz, T7 never the answer, T8 the codex
## keeps it, T9 no formula until asked, T10 the analogy maps over the
## cross-fade; and the controls move the readout the way the model says.
## Time is stepped by hand, so every frame is the same on every run.

const ID := "transformator"
var _closed: Array[String] = []


func _def() -> ExplainerDef:
	return ExplainerDef.load_all()["explainers"][ID]


func _view(options: Dictionary = {}) -> ExplainerView:
	var v := ExplainerView.create(ID, options)
	assert_eq(v.error, "", "opens")
	v.closed.connect(func(id: String) -> void: _closed.append(id))
	return v


func _to(v: ExplainerView, id: String) -> void:
	var guard := 0
	while v.beats.beat_id() != id and not v.beats.done and guard < 40:
		v.press(KEY_SPACE)
		guard += 1
	v.step(0.01)


func _rig(v: ExplainerView) -> TrafoRig:
	return v.rig as TrafoRig


func _formula() -> RegEx:
	return RegEx.create_from_string("[=÷×²·Ω√]|Δθ|\\b[IUPRS]\\s*[=/]")


func _formulas_on_screen(v: ExplainerView) -> Array[String]:
	var re := _formula()
	return v.visible_texts().filter(func(t: String) -> bool: return re.search(t) != null)


# ── T4: the parts load ──────────────────────────────────────────────────────

func test_t4_every_layer_loads_and_the_controls_have_their_hits() -> void:
	var f := ExplainerFigure.load_from("res://assets/" + _def().assets)
	assert_eq(f.error, "", "manifest")
	assert_true(f.layers.size() >= 20, "both skins (got %d)" % f.layers.size())
	var seen := {}
	for i in f.layers.size():
		var layer: Dictionary = f.layers[i]
		assert_eq(int(layer["z"]), i, "listed back to front")
		assert_false(seen.has(layer["z"]))
		seen[layer["z"]] = true
		var tex := f.texture(layer["id"])
		assert_true(tex is Texture2D, layer["id"])
		if tex != null:
			assert_near(tex.get_width(), layer["rect"][2] * ExplainerFigure.SVG_SCALE, 1.0, layer["id"] + " at the import scale")
	var knob := f.hits.filter(func(h: Dictionary) -> bool: return h["control"] == "load")
	assert_eq(knob.map(func(h: Dictionary) -> int: return int(h["step"])), [-1, 1], "the knob's two halves")
	assert_eq(f.hits.filter(func(h: Dictionary) -> bool: return h["control"] == "ambient").size(), 1, "the wall thermometer")
	assert_eq(f.lcds.map(func(l: Dictionary) -> String: return l["id"]), ["mv_meter", "lv_meter"])
	for n: Dictionary in f.needles:
		assert_eq(n["origin"].size(), 2, n["id"] + " pivot")
	for id in ["gauge_pedal", "gauge_wheel", "oil_needle", "air_needle", "knob_pointer"]:
		assert_true(f.needles.any(func(n: Dictionary) -> bool: return n["id"] == id), id)


# ── The controls move the readout as the model says ─────────────────────────

func test_the_knob_steps_the_load_and_the_meters_follow_the_model() -> void:
	var v := _view({"codex": true})
	var rig := _rig(v)
	assert_eq(rig.load_pct(), 25, "starts at a quarter")
	assert_eq(rig.ambient(), 20, "on a mild day")
	v.press(KEY_UP)
	v.press(KEY_UP)
	v.step(0.1)
	assert_eq(rig.load_pct(), 75)
	var want := TrafoThermal.solve(75, 20)
	assert_eq(rig.lcd_text("mv_meter"), "27,3 A")
	assert_eq(rig.lcd_text("lv_meter"), "682 A")
	assert_near(rig.result["hotspot_c"], want["hotspot_c"], 0.01)
	v.press(KEY_DOWN)
	assert_eq(rig.load_pct(), 50, "↓ turns it back")
	for i in 10:
		v.press(KEY_UP)
	assert_eq(rig.load_pct(), 150, "it stops at its last step")
	v.free()


func test_clicking_the_knobs_halves_turns_it_down_and_up() -> void:
	var v := _view({"codex": true})
	for hit: Dictionary in v.figure.hits:
		if hit["control"] == "load":
			var r: Array = hit["rect"]
			v.click_figure(Vector2(r[0] + r[2] / 2.0, r[1] + r[3] / 2.0))
	assert_eq(_rig(v).load_pct(), 25, "down then up")
	var up: Dictionary = v.figure.hits.filter(func(h: Dictionary) -> bool: return h.get("step", 0) == 1)[0]
	v.click_figure(Vector2(up["rect"][0] + up["rect"][2] / 2.0, up["rect"][1] + up["rect"][3] / 2.0))
	assert_eq(_rig(v).load_pct(), 50)
	v.free()


func test_the_oil_climbs_slowly_and_the_card_says_how_long_it_holds() -> void:
	var v := _view({"codex": true})
	var rig := _rig(v)
	for i in 5:
		v.press(KEY_UP)
	assert_eq(rig.load_pct(), 150)
	var start := rig.oil_c()
	v.step(1.0)
	assert_true(rig.oil_c() > start and rig.oil_c() < TrafoThermal.solve(150, 20)["oil_c"] - 5.0, "the oil climbs, but not at once")
	assert_true(_shows(v, "Houdt dit zo'n 1,5 uur vol"), "150 % on a mild day: an hour and a half")
	v.press(KEY_DOWN)
	v.press(KEY_DOWN)
	v.step(0.1)
	assert_true(_shows(v, "Kan dit blijven dragen"), "at its nameplate it holds")
	v.press(KEY_T)
	v.press(KEY_T)
	v.press(KEY_T)
	assert_eq(rig.ambient(), 10, "the weather goes round: 20, 30, 0, 10")
	v.free()


func test_the_houses_light_with_the_load() -> void:
	var v := _view({"codex": true})
	v.step(1.0)
	assert_eq(v.alpha("house1_lit"), 1.0, "a quarter: one house")
	assert_eq(v.alpha("house2_lit"), 0.0)
	v.press(KEY_UP)
	v.press(KEY_UP)
	v.press(KEY_UP)
	v.step(1.0)
	assert_eq(v.alpha("house4_lit"), 1.0, "the nameplate: the whole street")
	v.free()


func _shows(v: ExplainerView, text: String) -> bool:
	return v.visible_texts().any(func(t: String) -> bool: return t.contains(text))


# ── T5: the beats ───────────────────────────────────────────────────────────

func test_t5_a_player_who_follows_ruud_walks_every_main_beat() -> void:
	var v := _view()
	var seen: Array[String] = [v.beats.beat_id()]
	var note := func() -> void:
		if seen[-1] != v.beats.beat_id():
			seen.append(v.beats.beat_id())
	v.press(KEY_SPACE)   # f1
	note.call()
	v.press(KEY_UP)      # f2: heavier (50 %)
	note.call()
	v.press(KEY_UP)      # f3: all the way (100 %)
	v.press(KEY_UP)
	note.call()
	for i in 4:          # f4, x, t1, t2
		v.press(KEY_SPACE)
		note.call()
	v.press(KEY_SPACE)   # t3: the street already asks a lot
	note.call()
	assert_false(v.beats.toggle("ambient"), "the thermometer waits for its beat")
	v.press(KEY_UP)      # t4: above the nameplate
	note.call()
	v.press(KEY_T)       # t5: a hot day
	note.call()
	assert_eq(seen, ["f1", "f2", "f3", "f4", "x", "t1", "t2", "t3_already", "t4", "t5", "t6"] as Array[String])
	assert_eq(_rig(v).ambient(), 30, "a hot day")
	v.press(KEY_SPACE)
	assert_eq(_closed, [ID] as Array[String], "the last beat closes it")
	v.free()


func test_t5_the_already_variants_follow_the_knob() -> void:
	var v := _view()
	v.press(KEY_UP)
	v.press(KEY_UP)
	_to(v, "f2_already")
	assert_eq(v.beats.beat_id(), "f2_already", "heavier before Ruud asked")
	v.press(KEY_UP)
	v.press(KEY_UP)
	_to(v, "f3_full")
	assert_eq(v.beats.beat_id(), "f3_full")
	v.press(KEY_UP)
	_to(v, "t4_over")
	assert_eq(v.beats.beat_id(), "t4_over", "already above the nameplate")
	v.free()


func test_t5_the_counter_counts_eleven_main_beats_and_esc_pauses() -> void:
	var v := _view()
	assert_eq(v.beats.count(), 11)
	var paused := [0]
	v.pause_requested.connect(func() -> void: paused[0] += 1)
	_to(v, "t2")
	v.press(KEY_ESCAPE)
	assert_eq(paused[0], 1)
	assert_true(v.is_open())
	var book := ExplainerLog.new()
	v.free()
	var w := _view({"log": book})
	w.klaar.pressed.emit()
	assert_true(book.has_seen(ID), "[Klaar] files it in the codex")
	w.free()


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


func test_t6_the_only_buttons_are_klaar_the_reveal_and_in_the_codex_the_tabs() -> void:
	var v := _view()
	_to(v, "t3")
	assert_eq(_buttons(v).size(), 2)
	v.free()
	var c := _view({"codex": true})
	var names := _buttons(c).map(func(b: Button) -> String: return b.text)
	assert_eq(names.size(), 4)
	assert_true(names.has("De fiets") and names.has("De trafo"), str(names))
	c.free()


# ── T7: never the answer ────────────────────────────────────────────────────

func test_t7_no_string_names_a_missions_answer() -> void:
	var def := _def()
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
	for token in ["3x25", "zonnepaneel", "omvormer", "253", "aftakking", "warmtepomp", "el amrani", "netstudie",
			"wachtlijst", "verzwar", "bestel", "levertijd", "fabrikant", "voorraad", "contract", "reserver",
			"ongebruikt", "boomgaard", "hermans", "net is vol"]:
		names.append(token)
	for text: String in all:
		for name in names:
			assert_false(text.to_lower().contains(name.to_lower()), "%s names %s" % [text, name])


# ── T8: the codex keeps it ──────────────────────────────────────────────────

func test_t8_the_codex_lists_it_once_seen_and_opens_it_again() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var codex := CodexPanel.new()
	codex.session = s
	codex.show_tab(CodexPanel.EXPLAINERS)
	var def := _def()
	assert_false(shows(codex, def.name), "not met: a silhouette")
	s.explainers.see(def.id)
	codex.refresh()
	assert_true(shows(codex, def.name))
	assert_true(shows(codex, def.one_idea), "its one idea")
	var view := codex.open_explainer(def.id)
	assert_true(view != null and view.codex and view.error.is_empty(), "opened the codex's way")
	assert_false(_rig(view).is_locked("ambient"), "both controls free")
	view.free()
	codex.free()


func test_t8_the_log_keeps_it_and_drops_nothing_it_knows() -> void:
	var book := ExplainerLog.new()
	book.see(ID)
	var back := ExplainerLog.new()
	back.load_dict(book.to_dict(), ExplainerDef.load_all()["explainers"].keys())
	assert_true(back.has_seen(ID))


# ── T9: no formula until asked ──────────────────────────────────────────────

func test_t9_no_formula_or_digit_outside_the_readout_until_the_reveal() -> void:
	var digit := RegEx.create_from_string("\\d")
	for text in _def().plain_texts():
		assert_eq(_formula().search(text), null, text)
		assert_eq(digit.search(text), null, text)
	var v := _view()
	var guard := 0
	while not v.beats.done and guard < 30:
		v.step(0.1)
		assert_eq(_formulas_on_screen(v), [] as Array[String], v.beats.beat_id())
		v.press(KEY_UP if guard % 3 == 0 else KEY_SPACE)
		guard += 1
	v.free()


func test_t9_the_reveal_shows_the_sums_with_the_live_numbers() -> void:
	var v := _view()
	_to(v, "t1")
	assert_false(v.reveal_corner.visible, "no reveal before T2")
	_to(v, "t2")
	assert_true(v.reveal_corner.visible)
	v.press(KEY_R)
	assert_false(_formulas_on_screen(v).is_empty(), "the strip shows the sums")
	assert_true(_shows(v, "10.000 V"), "with the voltages")
	assert_true(_shows(v, "kVA"))
	v.press(KEY_R)
	assert_eq(_formulas_on_screen(v), [] as Array[String], "folded: gone")
	v.free()


# ── T10: the analogy maps ───────────────────────────────────────────────────

func test_t10_every_pair_joins_a_fiets_and_a_trafo_layer() -> void:
	var v := _view()
	for row: Dictionary in v.def.mapping:
		var pair: Array = row["pair"]
		assert_eq(v.figure.layer(pair[0]).get("skin"), "fiets", str(pair))
		assert_eq(v.figure.layer(pair[1]).get("skin"), "trafo", str(pair))
		assert_eq(v.figure.layer(pair[0]).get("pair"), pair[1], "the manifest pairs them back")
	v.free()


func test_t10_after_the_cross_fade_the_fiets_is_gone_and_the_load_carries_over() -> void:
	var v := _view()
	v.press(KEY_UP)
	v.press(KEY_UP)
	_to(v, "f4")
	v.step(8.0)
	for layer: Dictionary in v.figure.layers:
		if layer["skin"] == "trafo":
			assert_eq(v.alpha(layer["id"]), 0.0, layer["id"] + " before X")
	var heat := v.heat_level()
	assert_true(heat > 0.0, "the chain is warm")
	_to(v, "x")
	assert_true(v.tags_visible(), "Ruud holds up his tags")
	v.step(4.0)
	for layer: Dictionary in v.figure.layers:
		if layer["skin"] == "fiets":
			assert_eq(v.alpha(layer["id"]), 0.0, layer["id"] + " after X")
	for row: Dictionary in v.def.mapping:
		assert_eq(v.skin_weight(row["pair"][1]), 1.0, row["pair"][1] + " after X")
	assert_eq(_rig(v).load_pct(), 75, "the knob stays where it was")
	assert_near(v.heat_level(), heat, 0.05, "the windings are as warm as the chain was")
	v.free()
