extends TestCase
## The "Hoe werkt het? 1" model (spec 2026-10-16-explainer-spanning-stroom-
## weerstand §3.4): T1 the table's numbers, T2 the fixtures the drawing's own
## model wrote, T3 the physics that must hold in every state.

const FIXTURES := "res://assets/explainers/spanning/fixtures.json"
const LOADS: Array[String] = ["lamp", "kettle", "heater"]


func _on(ids: Array) -> Dictionary:
	var out := {}
	for id: String in LOADS:
		out[id] = ids.has(id)
	return out


## Every combination of the three switches.
func _states() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mask in 8:
		var ids := []
		for i in LOADS.size():
			if mask & (1 << i):
				ids.append(LOADS[i])
		out.append(_on(ids))
	return out


func _count(switches: Dictionary) -> int:
	return switches.values().count(true)


# ── T1 ──────────────────────────────────────────────────────────────────────

## §3.4's table. U_eind is printed in whole volts there, so it is held to
## 0,5 V; ΔU (one decimal) to 0,1 V.
func test_t1_the_table_of_the_spec() -> void:
	var rows := [
		[1.5, ["lamp"], 0.03, 230, 0.0, 8, 0, 20],
		[1.5, ["kettle"], 8.51, 225, 5.0, 1915, 42, 31],
		[1.5, ["kettle", "heater"], 14.65, 221, 8.5, 3245, 125, 54],
		[1.5, ["lamp", "kettle", "heater"], 14.68, 221, 8.6, 3252, 126, 54],
		[2.5, ["kettle"], 8.58, 227, 3.0, 1948, 26, 25],
		[2.5, ["kettle", "heater"], 14.87, 225, 5.2, 3343, 77, 34],
	]
	for row: Array in rows:
		var r := OhmCable.solve(_on(row[1]), row[0])
		var at := "%s mm² %s" % [row[0], row[1]]
		assert_near(r["current_a"], row[2], 0.01, at + " I")
		assert_near(r["u_end_v"], row[3], 0.5, at + " U_eind")
		assert_near(r["du_v"], row[4], 0.1, at + " ΔU")
		assert_near(r["p_app_w"], row[5], 1.0, at + " P_app")
		assert_near(r["p_cable_w"], row[6], 1.0, at + " P_kabel")
		assert_near(r["t_cable_c"], row[7], 0.5, at + " T_kabel")


func test_t1_the_cable_resistance_counts_out_and_back() -> void:
	assert_near(OhmCable.solve(_on([]), 1.5)["r_cable_ohm"], 0.583, 0.001)
	assert_near(OhmCable.solve(_on([]), 2.5)["r_cable_ohm"], 0.350, 0.001)


# ── T2 ──────────────────────────────────────────────────────────────────────

func test_t2_the_game_and_the_picture_share_one_model() -> void:
	var read := JsonFile.read_dict(FIXTURES)
	assert_eq(read["error"], "", "fixtures.json")
	var cases: Array = read["data"].get("cases", [])
	assert_eq(cases.size(), 16, "every state on both cables")
	for c: Dictionary in cases:
		var r := OhmCable.solve(_on(c["on"]), c["cross_section_mm2"])
		for key: String in ["current_a", "u_end_v", "du_v", "p_app_w", "p_cable_w", "t_cable_c"]:
			assert_near(r[key], c[key], 0.001, "%s %s %s" % [c["cross_section_mm2"], c["on"], key])


# ── T3 ──────────────────────────────────────────────────────────────────────

func test_t3_more_switches_never_lower_the_current_or_raise_the_end_voltage() -> void:
	for a in _states():
		for b in _states():
			var superset := LOADS.all(func(id: String) -> bool: return not a[id] or b[id])
			if not superset or a == b:
				continue
			var ra := OhmCable.solve(a, 1.5)
			var rb := OhmCable.solve(b, 1.5)
			assert_true(rb["current_a"] >= ra["current_a"], "%s → %s: I" % [a, b])
			assert_true(rb["u_end_v"] <= ra["u_end_v"] + 1e-9, "%s → %s: U" % [a, b])


func test_t3_the_thick_cable_loses_less_and_stays_cooler() -> void:
	for s in _states():
		if _count(s) == 0:
			continue
		var thin := OhmCable.solve(s, 1.5)
		var thick := OhmCable.solve(s, 2.5)
		assert_true(thick["du_v"] < thin["du_v"], "%s ΔU" % s)
		assert_true(thick["t_cable_c"] < thin["t_cable_c"] or thin["t_cable_c"] - 20.0 < 0.01, "%s T" % s)


func test_t3_cable_heat_grows_with_the_square_of_the_current() -> void:
	for cable in [1.5, 2.5]:
		var lit := _states().filter(func(s: Dictionary) -> bool: return _count(s) > 0)
		for a: Dictionary in lit:
			for b: Dictionary in lit:
				var ra := OhmCable.solve(a, cable)
				var rb := OhmCable.solve(b, cable)
				var expected := pow(ra["current_a"] / rb["current_a"], 2.0)
				assert_near(ra["p_cable_w"] / rb["p_cable_w"], expected, expected * 0.001, "%s / %s" % [a, b])


func test_t3_energy_is_conserved() -> void:
	for cable in [1.5, 2.5]:
		for s in _states():
			var r := OhmCable.solve(s, cable)
			assert_near(r["p_app_w"] + r["p_cable_w"], OhmCable.U_NOMINAL * r["current_a"], 1.0, "%s" % s)


func test_t3_nothing_on_is_all_zeros_and_the_full_voltage() -> void:
	var r := OhmCable.solve(_on([]), 1.5)
	for key: String in ["current_a", "du_v", "p_app_w", "p_cable_w"]:
		assert_eq(r[key], 0.0, key)
	assert_eq(r["u_end_v"], 230.0)
	assert_eq(r["t_cable_c"], 20.0)


func test_an_unknown_cross_section_falls_back_to_the_thin_cable() -> void:
	assert_eq(OhmCable.solve(_on(["kettle"]), 4.0), OhmCable.solve(_on(["kettle"]), 1.5))


# ── The temperature eases ───────────────────────────────────────────────────

func test_the_cable_warms_toward_its_steady_temperature() -> void:
	var t := OhmCable.ease_temperature(20.0, 54.0, OhmCable.TAU_S)
	assert_near(t, 20.0 + 34.0 * (1.0 - exp(-1.0)), 0.01, "one time constant")
	assert_eq(OhmCable.ease_temperature(20.0, 54.0, 1.0, 0.0), 54.0, "reduced motion: τ → 0")
