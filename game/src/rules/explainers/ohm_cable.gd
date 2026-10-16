class_name OhmCable
extends RefCounted
## The model of "Hoe werkt het? 1: spanning, stroom, weerstand" (spec
## 2026-10-16-explainer-spanning-stroom-weerstand §3.4): a 230 V group feeds
## a 25 m extension cable on a reel and up to three resistive appliances.
## One pure function drives the readout, the heat tint, the needles and the
## reveal in both skins; tools/explainers/spanning/model.mjs is its twin for
## the drawing (fixtures.json, test T2). Sources and estimates: spec §3.5 and
## content/explainers.yaml.

## Nominal low-voltage, an ideal source at the socket (Netbeheer Nederland).
const U_NOMINAL := 230.0
## Copper at 20 °C, Ω·mm²/m (estimate: the installers' rounded value).
const RHO := 0.0175
## The reel's length in m; the current flows out and back (2·L).
const LENGTH_M := 25.0
## Appliance ratings in W (estimates: common household ratings).
const LOADS := {"lamp": 8.0, "kettle": 2000.0, "heater": 1500.0}
## Current rating I_z per cross-section in mm² (estimate: H05VV-F tables).
const RATING_A := {1.5: 16.0, 2.5: 25.0}
const THIN := 1.5
const ROOM_C := 20.0
## Rated conductor rise at I_z (estimate: PVC 70 °C at a 30 °C reference).
const RISE_MAX_K := 40.0
## The heating time constant in game seconds (estimate: a design choice for
## visibility; a real cord takes minutes).
const TAU_S := 4.0


## {current_a, u_end_v, du_v, p_app_w, p_cable_w, t_cable_c, r_cable_ohm,
## r_total_ohm} for the switches ({load id: bool}) on a cable of this
## cross-section (1,5 or 2,5 mm²; anything else counts as the thin one).
## t_cable_c is the steady state; ease_temperature walks toward it.
static func solve(switches: Dictionary, cross_section_mm2: float) -> Dictionary:
	var area := cross_section_mm2 if RATING_A.has(cross_section_mm2) else THIN
	var r_cable := 2.0 * RHO * LENGTH_M / area
	var conductance := 0.0
	for id: String in LOADS:
		if switches.get(id, false):
			conductance += LOADS[id] / (U_NOMINAL * U_NOMINAL)
	if conductance == 0.0:
		return {"current_a": 0.0, "u_end_v": U_NOMINAL, "du_v": 0.0, "p_app_w": 0.0, "p_cable_w": 0.0,
			"t_cable_c": ROOM_C, "r_cable_ohm": r_cable, "r_total_ohm": INF}
	var r_load := 1.0 / conductance
	var current := U_NOMINAL / (r_cable + r_load)
	var u_end := current * r_load
	return {
		"current_a": current,
		"u_end_v": u_end,
		"du_v": current * r_cable,
		"p_app_w": u_end * current,
		"p_cable_w": current * current * r_cable,
		"t_cable_c": ROOM_C + RISE_MAX_K * pow(current / RATING_A[area], 2.0),
		"r_cable_ohm": r_cable,
		"r_total_ohm": r_cable + r_load,
	}


## One step of the cable's temperature toward `target` (exponential follow;
## tau 0 jumps, for reduced motion).
static func ease_temperature(current: float, target: float, dt: float, tau: float = TAU_S) -> float:
	if tau <= 0.0:
		return target
	return current + (target - current) * (1.0 - exp(-dt / tau))
