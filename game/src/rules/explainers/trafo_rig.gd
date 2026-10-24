class_name TrafoRig
extends ExplainerRig
## The controls of "Hoe werkt het? 2: de transformator" (spec 2026-10-24-
## explainer-transformator §3.4, §4): the load knob (seven steps, ↑/↓ or its
## halves) and the wall thermometer (the weather, round: 20 → 30 → 0 → 10 °C),
## over TrafoThermal. The oil follows its steady rise with a sped-up time
## constant; the winding's warmest point rides on the oil.

const MODEL := "transformer"
## Where the knob and the weather start (25 %, 20 °C).
const LOAD_START := 1
const AMBIENT_START := 2
## The analogy's turns per second: the pedals fast, the wheel a third of it
## (estimate: a light bicycle gear); the same at any load, as the voltage is.
const CRANK_TURNS_S := 0.9
const GEAR_RATIO := 3.0
## The heat tint: from a winding at 60 °C (nothing) to 130 °C (full).
const HEAT_FROM_C := 60.0
const HEAT_SPAN_C := 70.0
## The dials' spans: the oil thermometer 0–120 °C, the wall thermometer −10–40 °C.
const OIL_DIAL_C := Vector2(0.0, 120.0)
const AIR_DIAL_C := Vector2(-10.0, 40.0)

var load_step := LOAD_START
var ambient_step := AMBIENT_START
var result := {}
## The top oil's rise over the air as it eases (K).
var oil_rise := 0.0

var _crank := 0.0
var _wheel := 0.0


func _init(explainer: ExplainerDef) -> void:
	super(explainer)
	result = _solve()
	oil_rise = result["oil_c"] - ambient()


func load_pct() -> int:
	return TrafoThermal.LOADS_PCT[load_step]


func ambient() -> int:
	return TrafoThermal.AMBIENTS_C[ambient_step]


func _solve() -> Dictionary:
	return TrafoThermal.solve(load_pct(), ambient())


func _apply(control: String, step: int) -> bool:
	match control:
		"load":
			var to := load_step + signi(step)
			if to < 0 or to >= TrafoThermal.LOADS_PCT.size():
				return false
			load_step = to
		"ambient":
			ambient_step = posmod(ambient_step + signi(step), TrafoThermal.AMBIENTS_C.size())
		_:
			return false
	result = _solve()
	return true


func snapshot() -> Dictionary:
	return {"load": load_pct(), "ambient": ambient()}


func holds(condition: String) -> bool:
	match condition:
		"load_half":
			return load_pct() >= 50
		"load_full":
			return load_pct() >= 100
	return false


func met(wait: String) -> bool:
	match wait:
		"load_up":
			return load_pct() > int(at_start.get("load", load_pct()))
		"load_full":
			return load_pct() >= 100
		"over_rated":
			return load_pct() > 100
		"ambient":
			return ambient() != int(at_start.get("ambient", ambient()))
	return false


func step(dt: float, reduced_motion: bool) -> void:
	result = _solve()
	var target: float = result["oil_c"] - ambient()
	oil_rise = TrafoThermal.ease_oil(oil_rise, target, dt, 0.0 if reduced_motion else TrafoThermal.TAU_VIEW_S)
	if not reduced_motion:
		_crank = fmod(_crank + CRANK_TURNS_S * dt, 1.0)
		_wheel = fmod(_wheel + CRANK_TURNS_S / GEAR_RATIO * dt, 1.0)


## The oil and the winding's warmest point as they are now (°C).
func oil_c() -> float:
	return ambient() + oil_rise


func hotspot_c() -> float:
	return oil_c() + TrafoThermal.gradient(load_pct() / 100.0)


## A house's windows light from their load step on ({load_at_least: %}).
func shows(w: Dictionary) -> bool:
	if w.has("load_at_least"):
		return load_pct() >= int(w["load_at_least"])
	return true


func heat_level() -> float:
	return clampf((hotspot_c() - HEAT_FROM_C) / HEAT_SPAN_C, 0.0, 1.0)


## The wheel's force gauge spans the full load; the pedal's moves a third of
## it (the analogy's gear); the dials read the oil and the air; the knob its step.
func needle(id: String) -> float:
	var top: float = TrafoThermal.LOADS_PCT[-1]
	match id:
		"gauge_wheel":
			return load_pct() / top
		"gauge_pedal":
			return load_pct() / top / GEAR_RATIO
		"oil_needle":
			return clampf((oil_c() - OIL_DIAL_C.x) / (OIL_DIAL_C.y - OIL_DIAL_C.x), 0.0, 1.0)
		"air_needle":
			return clampf((ambient() - AIR_DIAL_C.x) / (AIR_DIAL_C.y - AIR_DIAL_C.x), 0.0, 1.0)
		"knob_pointer":
			return float(load_step) / (TrafoThermal.LOADS_PCT.size() - 1)
	return 0.0


func turn(id: String) -> float:
	return _crank if id == "crank" else _wheel


func lcd_text(id: String) -> String:
	match id:
		"mv_meter":
			return "%s A" % nl(result["i_primary_a"], 1)
		"lv_meter":
			return "%s A" % nl(result["i_secondary_a"], 0)
	return ""


func readout(labels: Dictionary) -> String:
	return "%s  %s A\n%s  %s A\n%s  %d °C    %s  %d °C\n%s" % [
		labels.get("current_in", ""), nl(result["i_primary_a"], 1),
		labels.get("current_out", ""), nl(result["i_secondary_a"], 0),
		labels.get("hotspot", ""), roundi(hotspot_c()), labels.get("outside", ""), ambient(),
		holds_text(labels)]


## How long the trafo holds this load, in the card's words.
func holds_text(labels: Dictionary) -> String:
	var hours: float = result["hours"]
	if is_inf(hours):
		return labels.get("holds", "")
	if hours < 1.0:
		return labels.get("under_an_hour", "")
	var halves := roundf(hours * 2.0) / 2.0
	return String(labels.get("hours", "")).format({"hours": nl(halves, 0 if is_equal_approx(halves, roundf(halves)) else 1)})


func reveal_values() -> Dictionary:
	var kva := TrafoThermal.RATED_KVA * load_pct() / 100.0
	return {
		"rated": nl(TrafoThermal.RATED_KVA, 0),
		"load": str(load_pct()),
		"s": nl(kva, 0),
		"i1": nl(result["i_primary_a"], 1),
		"i2": nl(result["i_secondary_a"], 0),
		"oil": nl(oil_c(), 0),
		"hot": nl(hotspot_c(), 0),
		"ambient": str(ambient()),
		"ageing": nl(pow(2.0, (hotspot_c() - TrafoThermal.AGEING_REF_C) / TrafoThermal.AGEING_DOUBLING_K), 2),
	}
