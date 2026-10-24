class_name TrafoThermal
extends RefCounted
## The model of "Hoe werkt het? 2: de transformator" (spec 2026-10-24-
## explainer-transformator §3.4): a 10 kV → 400 V distribution transformer
## at a load (% of its nameplate) in outside air. It keeps its power, so the
## current out is twenty-five times the current in; it warms by the loading
## guide's exponential model (IEC 60076-7, default ONAN constants recalled:
## estimates). tools/explainers/trafo/model.mjs is its twin (fixtures.json,
## test T2). Sources and estimates: the spec §3.5 and content/explainers.yaml.

## Rated power in kVA (estimate: a common size in a Dutch MSR).
const RATED_KVA := 630.0
## The most common MS level and the LS level between phases (Netbeheer Nederland).
const U_PRIMARY := 10000.0
const U_SECONDARY := 400.0
## Load losses over no-load losses at rated load (estimate).
const LOSS_RATIO := 5.0
## Top-oil rise and hot spot over top oil at rated load, K (estimates).
const OIL_RISE_RATED := 55.0
const GRADIENT_RATED := 23.0
const OIL_EXP := 0.8
const WINDING_EXP := 1.6
## The top oil's time constant, minutes.
const TAU_OIL_MIN := 180.0
## The hot-spot limit for normal cyclic loading, °C (estimate).
const HOTSPOT_LIMIT_C := 120.0
## Relative ageing is 1 at this hot spot and doubles every AGEING_DOUBLING_K.
const AGEING_REF_C := 98.0
const AGEING_DOUBLING_K := 6.0
## The overload's hours start after a long day at this load (estimate).
const BEFORE_PCT := 50.0
## The knob's steps and the wall thermometer's.
const LOADS_PCT: Array[int] = [0, 25, 50, 75, 100, 125, 150]
const AMBIENTS_C: Array[int] = [0, 10, 20, 30]
## The oil's time constant in the view, game seconds (estimate: the real
## three hours sped up so the player sees it climb).
const TAU_VIEW_S := 6.0


## The steady top-oil rise over the air at load factor k (1 = the nameplate).
static func oil_rise(k: float) -> float:
	return OIL_RISE_RATED * pow((1.0 + LOSS_RATIO * k * k) / (1.0 + LOSS_RATIO), OIL_EXP)


## The winding's warmest point over the top oil at load factor k.
static func gradient(k: float) -> float:
	return GRADIENT_RATED * pow(k, WINDING_EXP)


## Hours until the hot spot reaches the limit at load factor k after a long
## day at BEFORE_PCT: INF when the steady state stays under it, 0 when over at once.
static func hours_to_limit(k: float, ambient_c: float) -> float:
	var target := HOTSPOT_LIMIT_C - ambient_c - gradient(k)
	var start := oil_rise(BEFORE_PCT / 100.0)
	var end := oil_rise(k)
	if end <= target:
		return INF
	if start >= target:
		return 0.0
	return -TAU_OIL_MIN * log(1.0 - (target - start) / (end - start)) / 60.0


## {load_pct, ambient_c, i_primary_a, i_secondary_a, oil_c, hotspot_c,
## hours, ageing} at this load (% of the nameplate) in this air (°C).
static func solve(load_pct: float, ambient_c: float) -> Dictionary:
	var k := load_pct / 100.0
	var va := RATED_KVA * k * 1000.0
	var hot := ambient_c + oil_rise(k) + gradient(k)
	return {
		"load_pct": load_pct,
		"ambient_c": ambient_c,
		"i_primary_a": va / (sqrt(3.0) * U_PRIMARY),
		"i_secondary_a": va / (sqrt(3.0) * U_SECONDARY),
		"oil_c": ambient_c + oil_rise(k),
		"hotspot_c": hot,
		"hours": hours_to_limit(k, ambient_c),
		"ageing": pow(2.0, (hot - AGEING_REF_C) / AGEING_DOUBLING_K),
	}


## One step of the oil's rise toward `target` (exponential follow; tau 0
## jumps, for reduced motion).
static func ease_oil(current: float, target: float, dt: float, tau: float = TAU_VIEW_S) -> float:
	if tau <= 0.0:
		return target
	return current + (target - current) * (1.0 - exp(-dt / tau))
