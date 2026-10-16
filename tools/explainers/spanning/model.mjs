// The model of "Hoe werkt het? 1" (spec 2026-10-16-explainer-spanning-stroom-weerstand §3.4).
// The twin of game/src/rules/explainers/ohm_cable.gd: the drawing's needles, tint and
// readouts come from here, and fixtures.json (written by export.mjs) holds the game to it (T2).

export const U_NOMINAL = 230;
export const RHO = 0.0175; // Ω·mm²/m, copper at 20 °C (estimate: the installers' rounded value)
export const LENGTH_M = 25;
export const LOADS = { lamp: 8, kettle: 2000, heater: 1500 }; // W (estimates)
export const RATING_A = { 1.5: 16, 2.5: 25 }; // I_z, A (estimate: H05VV-F tables)
export const ROOM_C = 20;
export const RISE_MAX_K = 40;

export function solve(switches, crossSection) {
  const area = RATING_A[crossSection] ? crossSection : 1.5;
  const rCable = (2 * RHO * LENGTH_M) / area;
  let conductance = 0;
  for (const [id, watts] of Object.entries(LOADS)) if (switches[id]) conductance += watts / (U_NOMINAL * U_NOMINAL);
  if (conductance === 0) {
    return { current_a: 0, u_end_v: U_NOMINAL, du_v: 0, p_app_w: 0, p_cable_w: 0, t_cable_c: ROOM_C, r_cable_ohm: rCable };
  }
  const rLoad = 1 / conductance;
  const current = U_NOMINAL / (rCable + rLoad);
  const uEnd = current * rLoad;
  return {
    current_a: current,
    u_end_v: uEnd,
    du_v: current * rCable,
    p_app_w: uEnd * current,
    p_cable_w: current * current * rCable,
    t_cable_c: ROOM_C + RISE_MAX_K * (current / RATING_A[area]) ** 2,
    r_cable_ohm: rCable,
  };
}

// Every switch state on both cables: the cross-check cases for T2.
export function fixtures() {
  const ids = Object.keys(LOADS);
  const cases = [];
  for (const crossSection of [1.5, 2.5]) {
    for (let mask = 0; mask < 1 << ids.length; mask++) {
      const on = ids.filter((_, index) => mask & (1 << index));
      const switches = Object.fromEntries(ids.map((id) => [id, on.includes(id)]));
      const r = solve(switches, crossSection);
      cases.push({
        cross_section_mm2: crossSection,
        on,
        current_a: r.current_a,
        u_end_v: r.u_end_v,
        du_v: r.du_v,
        p_app_w: r.p_app_w,
        p_cable_w: r.p_cable_w,
        t_cable_c: r.t_cable_c,
      });
    }
  }
  return { model: "ohm_cable", cases };
}
