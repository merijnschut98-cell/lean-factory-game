extends TestCase
## T4: the figure's parts load. Every manifest layer's SVG imports as a
## texture (ThorVG: inline styles, text as paths), z is unique, every
## control has its hit rect and its two states in both skins, every LCD has a
## rect and every needle a pivot.

const ID := "spanning_stroom_weerstand"


func _def() -> ExplainerDef:
	return ExplainerDef.load_all()["explainers"][ID]


func _figure() -> ExplainerFigure:
	var f := ExplainerFigure.load_from("res://assets/" + _def().assets)
	assert_eq(f.error, "", "manifest")
	return f


func test_every_layer_loads_as_a_texture() -> void:
	var f := _figure()
	assert_true(f.layers.size() >= 40, "both skins, about sixty layers (got %d)" % f.layers.size())
	for layer: Dictionary in f.layers:
		var tex := f.texture(layer["id"])
		assert_true(tex is Texture2D, layer["id"])
		if tex != null:
			var rect: Array = layer["rect"]
			assert_near(tex.get_width(), rect[2] * ExplainerFigure.SVG_SCALE, 1.0, layer["id"] + " rasterised at the import scale")


func test_z_is_unique_and_follows_the_painters_order() -> void:
	var f := _figure()
	var seen := {}
	for i in f.layers.size():
		var z: int = f.layers[i]["z"]
		assert_false(seen.has(z), "z %d twice" % z)
		seen[z] = true
		assert_eq(z, i, "listed back to front")


func test_every_control_has_its_hit_rect_and_both_states_in_both_skins() -> void:
	var f := _figure()
	for c: Dictionary in _def().controls:
		var hits := f.hits.filter(func(h: Dictionary) -> bool: return h["control"] == c["id"])
		assert_false(hits.is_empty(), c["id"] + " has a hit rect")
		for skin: String in ["tuin", "meterkast"]:
			if not c.has(skin):
				continue
			var states := ["closed", "open"] if skin == "tuin" else ["off", "on"]
			for state: String in states:
				assert_true(f.has_layer("%s_%s" % [c[skin], state]), "%s %s %s" % [c["id"], skin, state])


func test_every_lcd_has_a_rect_and_every_needle_a_pivot() -> void:
	var f := _figure()
	assert_eq(f.lcds.map(func(l: Dictionary) -> String: return l["id"]), ["stroomtang", "thermometer", "multimeter"])
	for lcd: Dictionary in f.lcds:
		assert_true(lcd["w"] > 0 and lcd["h"] > 0, lcd["id"])
		assert_eq(lcd["origin"].size(), 2, lcd["id"])
	assert_eq(f.needles.size(), 2)
	for n: Dictionary in f.needles:
		assert_eq(n["origin"].size(), 2, n["id"] + " pivot")
		assert_true(n["length"] > 0, n["id"])


func test_a_missing_manifest_is_an_error_not_a_crash() -> void:
	var f := ExplainerFigure.load_from("res://assets/explainers/nowhere")
	assert_ne(f.error, "")
	assert_eq(f.layers, [])
