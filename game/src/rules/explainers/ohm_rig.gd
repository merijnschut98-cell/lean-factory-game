class_name OhmRig
extends ExplainerRig
## The controls of "Hoe werkt het? 1: spanning, stroom, weerstand" (spec
## 2026-10-16-explainer-spanning-stroom-weerstand §3.4, §4): three switches
## (or valves in the garden) and the reel, over OhmCable. What was open in the
## garden is switched on in the meterkast.

const LOADS: Array[String] = ["lamp", "kettle", "heater"]
## The skin of the analogy (the beats' first phase).
const GARDEN := "tuin"
## The heat tint's span: a warm orange that deepens as the cable warms to 70 °C.
const HEAT_SPAN_C := 50.0
## The end gauge's zoomed band (spec §3.4, estimate) and the paddle wheel's
## turns per second per ampère (estimate: a calm spin at a kettle's 8,5 A).
const END_GAUGE_V := Vector2(210.0, 230.0)
const WHEEL_TURNS_PER_A := 0.12

var on := {"lamp": false, "kettle": false, "heater": false}
## The reel in use: 1 (thin) or 2 (thick).
var haspel := 1
## The kettle ran without the heater in the meterkast (R7's variant).
var kettle_alone_seen := false
var result := {}
var t_cable := OhmCable.ROOM_C

var _wheel_turn := 0.0
var _led_t := 0.0


func _init(explainer: ExplainerDef) -> void:
	super(explainer)
	result = OhmCable.solve(on, cross_section())


func cross_section() -> float:
	return 1.5 if haspel == 1 else 2.5


func _apply(control: String, _step: int) -> bool:
	if control == "haspel":
		haspel = 3 - haspel
	elif on.has(control):
		on[control] = not on[control]
	else:
		return false
	result = OhmCable.solve(on, cross_section())
	return true


func snapshot() -> Dictionary:
	return {"on": on.duplicate(), "haspel": haspel}


func note(phase: String) -> void:
	if phase != GARDEN and on["kettle"] and not on["heater"]:
		kettle_alone_seen = true


func _count() -> int:
	return on.values().count(true)


func holds(condition: String) -> bool:
	match condition:
		"only_lamp":
			return on["lamp"] and _count() == 1
		"kettle_on":
			return on["kettle"]
		"heater_on":
			return on["heater"]
		"never_kettle_alone":
			return not kettle_alone_seen
	return false


func met(wait: String) -> bool:
	match wait:
		"any_on":
			return _count() >= 1
		"two_on":
			return _count() >= 2
		"kettle_on":
			return on["kettle"]
		"heater_on":
			return on["heater"]
		"heater_again":
			return kettle_alone_seen and on["heater"]
		"haspel":
			return haspel != at_start.get("haspel", haspel)
	return false


func step(dt: float, reduced_motion: bool) -> void:
	result = OhmCable.solve(on, cross_section())
	t_cable = OhmCable.ease_temperature(t_cable, result["t_cable_c"], dt, 0.0 if reduced_motion else OhmCable.TAU_S)
	if not reduced_motion:
		_wheel_turn = fmod(_wheel_turn + result["current_a"] * WHEEL_TURNS_PER_A * dt, 1.0)
	_led_t += dt


## Whether the switches, valves and reel put this layer on show (its skin aside).
func shows(w: Dictionary) -> bool:
	if w.has("haspel"):
		return (haspel == int(w["haspel"])) == w["active"]
	if w.has("control"):
		return on[w["control"]] == w["on"]
	if w.has("spray"):
		return spray_level(w["spray"]) == int(w["level"])
	return true


## 0 when the outlet is shut, else 1–3 by its own flow (an estimate: below
## 1 A a trickle, below 5 A a spray, above it the full arc).
func spray_level(outlet: String) -> int:
	if not on.get(outlet, false):
		return 0
	var current: float = result.get("u_end_v", OhmCable.U_NOMINAL) * OhmCable.LOADS[outlet] / pow(OhmCable.U_NOMINAL, 2.0)
	return 1 if current < 1.0 else (2 if current < 5.0 else 3)


## The heater's own glow is full whenever it shows; the rest follow the cable.
func heat(layer_id: String) -> float:
	return 1.0 if layer_id == "heater_glow" else heat_level()


func heat_level() -> float:
	return clampf((t_cable - OhmCable.ROOM_C) / HEAT_SPAN_C, 0.0, 1.0)


## The end gauge reads what is left at the far end, on its zoomed band.
func needle(_id: String) -> float:
	return clampf((result.get("u_end_v", 230.0) - END_GAUGE_V.x) / (END_GAUGE_V.y - END_GAUGE_V.x), 0.0, 1.0)


func turn(_id: String) -> float:
	return _wheel_turn


## The kWh-meter's LED blinks faster with more power (estimate: 1 flash a second per kilowatt).
func led(_id: String) -> bool:
	var watts: float = result.get("p_app_w", 0.0)
	return watts > 1.0 and fmod(_led_t * watts / 1000.0, 1.0) < 0.25


func lcd_text(id: String) -> String:
	match id:
		"stroomtang":
			return amps(result.get("current_a", 0.0))
		"multimeter":
			return volts(result.get("u_end_v", 230.0))
		"thermometer":
			return "%d °C" % roundi(t_cable)
	return ""


func readout(labels: Dictionary) -> String:
	return "%s  %s\n%s  %s\n%s  %s" % [labels.get("current", ""), amps(result.get("current_a", 0.0)),
		labels.get("u_end", ""), volts(result.get("u_end_v", 230.0)), labels.get("t_cable", ""), "%d °C" % roundi(t_cable)]


func reveal_values() -> Dictionary:
	var r := result
	return {
		"u_n": nl(OhmCable.U_NOMINAL, 0),
		"r_total": "—" if is_inf(r["r_total_ohm"]) else nl(r["r_total_ohm"], 1),
		"current": nl(r["current_a"], 2 if r["current_a"] < 1.0 else 1),
		"r_cable": nl(r["r_cable_ohm"], 2),
		"p_cable": nl(r["p_cable_w"], 0),
		"du": nl(r["du_v"], 1),
		"u_end": nl(r["u_end_v"], 0),
		"p_app": nl(r["p_app_w"], 0),
	}


static func amps(a: float) -> String:
	return "%s A" % nl(a, 2 if a < 1.0 and a > 0.0 else 1)


static func volts(v: float) -> String:
	return "%s V" % nl(v, 0)
