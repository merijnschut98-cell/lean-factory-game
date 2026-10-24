extends TestCase
## The "Hoe werkt het? 2" model (spec 2026-10-24-explainer-transformator
## §3.4): T1 the table's numbers, T2 the fixtures the drawing's own model
## wrote, T3 the physics that must hold at every load and in every weather.

const FIXTURES := "res://assets/explainers/trafo/fixtures.json"


# ── T1 ──────────────────────────────────────────────────────────────────────

## §3.4's table: [ambient, load, I1, I2, oil, hot spot, hours (-1: holds), ageing].
func test_t1_the_table_of_the_spec() -> void:
	var rows := [
		[20, 0, 0.0, 0, 33, 33, -1, 0.0],
		[20, 25, 9.1, 227, 36, 39, -1, 0.0],
		[20, 75, 27.3, 682, 58, 73, -1, 0.05],
		[20, 100, 36.4, 909, 75, 98, -1, 1.0],
		[20, 125, 45.5, 1137, 95, 128, 5.6, 30.8],
		[20, 150, 54.6, 1364, 117, 161, 1.7, 1509],
		[0, 125, 45.5, 1137, 75, 108, -1, 3.1],
		[0, 150, 54.6, 1364, 97, 141, 3.7, 150],
		[30, 100, 36.4, 909, 85, 108, -1, 3.2],
		[30, 125, 45.5, 1137, 105, 138, 3.1, 98],
	]
	for row: Array in rows:
		var r := TrafoThermal.solve(row[1], row[0])
		var at := "%s °C %s %%" % [row[0], row[1]]
		assert_near(r["i_primary_a"], row[2], 0.05, at + " I1")
		assert_near(r["i_secondary_a"], row[3], 0.5, at + " I2")
		assert_near(r["oil_c"], row[4], 0.5, at + " oil")
		assert_near(r["hotspot_c"], row[5], 0.5, at + " hot spot")
		if row[6] < 0:
			assert_true(is_inf(r["hours"]), at + " holds")
		else:
			assert_near(r["hours"], row[6], 0.05, at + " hours")
		assert_near(r["ageing"], row[7], maxf(0.01, row[7] * 0.02), at + " ageing")


# ── T2 ──────────────────────────────────────────────────────────────────────

func test_t2_the_game_and_the_picture_share_one_model() -> void:
	var read := JsonFile.read_dict(FIXTURES)
	assert_eq(read["error"], "", "fixtures.json")
	var cases: Array = read["data"].get("cases", [])
	assert_eq(cases.size(), TrafoThermal.LOADS_PCT.size() * TrafoThermal.AMBIENTS_C.size(), "every load in every weather")
	for c: Dictionary in cases:
		var r := TrafoThermal.solve(c["load_pct"], c["ambient_c"])
		var at := "%s °C %s %%" % [c["ambient_c"], c["load_pct"]]
		for key: String in ["i_primary_a", "i_secondary_a", "oil_c", "hotspot_c", "ageing"]:
			assert_near(r[key], c[key], 0.001 * maxf(1.0, absf(c[key])), at + " " + key)
		if c["hours"] == null:
			assert_true(is_inf(r["hours"]), at + " holds")
		else:
			assert_near(r["hours"], c["hours"], 0.001, at + " hours")


# ── T3 ──────────────────────────────────────────────────────────────────────

func test_t3_the_current_out_is_always_twenty_five_times_the_current_in() -> void:
	for load: int in TrafoThermal.LOADS_PCT:
		var r := TrafoThermal.solve(load, 20)
		assert_near(r["i_secondary_a"], 25.0 * r["i_primary_a"], 0.001, "%d %%" % load)


func test_t3_more_load_never_cools_and_more_heat_never_lengthens_the_hours() -> void:
	for ambient: int in TrafoThermal.AMBIENTS_C:
		var before := TrafoThermal.solve(0, ambient)
		for load: int in TrafoThermal.LOADS_PCT.slice(1):
			var r := TrafoThermal.solve(load, ambient)
			assert_true(r["hotspot_c"] > before["hotspot_c"], "%d °C %d %%" % [ambient, load])
			assert_true(r["oil_c"] > before["oil_c"])
			assert_true(r["hours"] <= before["hours"], "more load, no more hours")
			before = r
	for load: int in TrafoThermal.LOADS_PCT:
		var cooler := TrafoThermal.solve(load, 0)
		for ambient: int in [10, 20, 30]:
			var r := TrafoThermal.solve(load, ambient)
			assert_true(r["hours"] <= cooler["hours"], "%d %%: warmer air, no more hours" % load)
			cooler = r


func test_t3_at_its_nameplate_in_mild_air_it_holds_for_ever() -> void:
	for load: int in [0, 25, 50, 75, 100]:
		assert_true(is_inf(TrafoThermal.solve(load, 20)["hours"]), "%d %%" % load)
	assert_near(TrafoThermal.solve(100, 20)["hotspot_c"], 98.0, 0.01, "the classic 98 °C at rated load")
	assert_near(TrafoThermal.solve(100, 20)["ageing"], 1.0, 0.001)


func test_the_oil_eases_toward_its_steady_rise() -> void:
	var rise := 10.0
	for i in 120:
		rise = TrafoThermal.ease_oil(rise, 50.0, 0.25)
	assert_near(rise, 50.0, 2.0, "after half a minute, close")
	assert_eq(TrafoThermal.ease_oil(10.0, 50.0, 0.25, 0.0), 50.0, "reduced motion jumps")
