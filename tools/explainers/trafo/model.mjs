// The model of "Hoe werkt het? 2: de transformator" (spec 2026-10-24-explainer-transformator §3.4).
// The twin of game/src/rules/explainers/trafo_thermal.gd: the drawing's needles, tint and readouts
// come from here, and fixtures.json (written by export.mjs) holds the game to it (T2).
// The thermal part is the exponential model of IEC 60076-7 (the loading guide) with its default
// constants for an ONAN distribution transformer, recalled: estimates (content/explainers.yaml).

export const RATED_KVA = 630; // estimate: a common size in a Dutch transformatorhuisje
export const U_PRIMARY = 10000; // V, the most common MS level (Netbeheer Nederland)
export const U_SECONDARY = 400; // V between the phases of the LS net (Netbeheer Nederland)
export const LOSS_RATIO = 5; // R: load losses / no-load losses at rated load (estimate)
export const OIL_RISE_RATED = 55; // K, top-oil rise at rated load (estimate)
export const GRADIENT_RATED = 23; // K, hot spot over top oil at rated load (H·gr, estimate)
export const OIL_EXP = 0.8; // x
export const WINDING_EXP = 1.6; // y
export const TAU_OIL_MIN = 180; // top-oil time constant, minutes
export const HOTSPOT_LIMIT_C = 120; // normal cyclic loading
export const AGEING_REF_C = 98; // relative ageing 1 at this hot spot, doubling every 6 K
export const AGEING_DOUBLING_K = 6;
export const BEFORE_PCT = 50; // the overload note starts from a long day at half load (estimate)
export const LOADS_PCT = [0, 25, 50, 75, 100, 125, 150];
export const AMBIENTS_C = [0, 10, 20, 30];

const SQRT3 = Math.sqrt(3);

export function oilRise(k) {
  return OIL_RISE_RATED * ((1 + LOSS_RATIO * k * k) / (1 + LOSS_RATIO)) ** OIL_EXP;
}

export function gradient(k) {
  return GRADIENT_RATED * k ** WINDING_EXP;
}

// Hours until the hot spot reaches the limit at load k after a long day at BEFORE_PCT;
// Infinity when the steady state stays under it, 0 when it is over at once.
export function hoursToLimit(k, ambient) {
  const target = HOTSPOT_LIMIT_C - ambient - gradient(k);
  const start = oilRise(BEFORE_PCT / 100);
  const end = oilRise(k);
  if (end <= target) return Infinity;
  if (start >= target) return 0;
  return (-TAU_OIL_MIN * Math.log(1 - (target - start) / (end - start))) / 60;
}

export function solve(loadPct, ambient) {
  const k = loadPct / 100;
  const s = RATED_KVA * k;
  const oil = oilRise(k);
  const hot = ambient + oil + gradient(k);
  return {
    load_pct: loadPct,
    ambient_c: ambient,
    i_primary_a: (s * 1000) / (SQRT3 * U_PRIMARY),
    i_secondary_a: (s * 1000) / (SQRT3 * U_SECONDARY),
    oil_c: ambient + oil,
    hotspot_c: hot,
    hours: hoursToLimit(k, ambient),
    ageing: 2 ** ((hot - AGEING_REF_C) / AGEING_DOUBLING_K),
  };
}

// Every load step at every ambient: the cross-check cases for T2 (Infinity as null in JSON).
export function fixtures() {
  const cases = [];
  for (const ambient of AMBIENTS_C) {
    for (const load of LOADS_PCT) {
      const r = solve(load, ambient);
      cases.push({ ...r, hours: Number.isFinite(r.hours) ? r.hours : null });
    }
  }
  return { model: "transformer", cases };
}
