// "Hoe werkt het? 2": one bench, two skins (spec 2026-10-24-explainer-transformator §3).
// Skin "fiets": a bicycle drivetrain on a fietstrainer: a bottom bracket with a small chainring
// (left), the chain, a big sprocket on the back wheel standing on the trainer's roller, the
// roller's resistance unit, a force gauge at the pedal and one at the wheel.
// Skin "trafo": a 10 kV → 400 V oil transformer with the front of its tank cut away (core,
// windings, oil, cooling fins), its 10 kV cable and bushings, its low-voltage side to a
// laagspanningsrek and four houses, a current meter on each side.
// Shared: the bench, the load knob's control box, the wall thermometer on its backboard.
// Each analogy part stands near the slot of its real counterpart; each layer is one painter's
// slot that changes on its own; the list order is the z order. Built with the anatomy kit
// (tools/explainers/kit, MIT).
import * as k from "../kit/iso-kit.mjs";
import * as G from "../kit/lathe.mjs";
import { tubePieces, tubeSvg } from "../kit/tube.mjs";

export const WIDTH = 1200;

// ── The world (units ≈ px of a real bench, z up; +x right, +y towards the viewer) ──
const PLATE = { x: -250, y: -92, w: 500, d: 184, r: 10 };
const PLATE_H = 12;
const FOOT_H = 6;

// The fiets: the bottom bracket, the back wheel, the chain plane.
const BB = { x: -186, z: 66 };
const HUB = { x: 50, z: 66 };
const CHAIN_Y = 13;
const RING_R = 13; // the small chainring
const SPROCKET_R = 34; // the big sprocket (a light gear: the wheel turns about a third as fast)
const TYRE = { rIn: 47, rOut: 55 };
const ROLLER = { r: 5, z: 6 }; // the trainer's roller under the tyre (55 + 5 + 6 = 66)

// The trafo: the tank with its front cut away, the core's three legs.
const TANK = { x0: -176, x1: 16, y0: -40, y1: 20, z0: 10, z1: 112 };
const WALL = 3;
const LEGS = [-146, -82, -18];
const CORE_Y = -10;
const COIL = { hv: 22, lv: 15, z0: 28, z1: 92 };
const OIL_Z = 104;
const LID = { y0: -44, y1: -8, z: 112, h: 5 };
const HV_X = [-152, -132, -112];
const LV_X = [-62, -46, -30, -14];
const BUSH_Y = -26;
const REK = { x0: 42, x1: 106, y: -22, top: 150 };
const FUSE_X = [50, 64, 78, 92];
const HOUSES = [128, 152, 176, 200];
const HOUSE = { y: 8, w: 18, d: 16, wall: 15, ridge: 25 };

// Shared: the backboard with the wall thermometer, the control box with the knob.
const BOARD = { x: 150, y: -88, w: 88, d: 6, z1: 122 };
const AIR = { x: 205, z: 92, r: 15 };
const BOX = { x: 186, y: 46, w: 50, d: 34, r: 3 };
const BOX_H = 13;
const KNOB = { x: 211, y: 62, r: 8 };

// The meters: the pedal's gauge and the 10 kV meter on the left, the wheel's gauge and the
// laagspanningsrek's meter on the right, in front.
const GAUGE_IN = { x: -214, y: 48 };
const GAUGE_OUT = { x: 104, y: 48 };

const AZIMUTH = 58;
const EXTREMES = [...k.boxCorners(PLATE, -PLATE_H - FOOT_H, 0), [BOARD.x, BOARD.y, BOARD.z1 + 4], [BOARD.x + BOARD.w, BOARD.y, BOARD.z1 + 4],
  [REK.x0, REK.y, REK.top + 12], [-210, -26, 172]];
const PAD = 24;
export const HEIGHT = (() => {
  const unit = { origin: [0, 0], scale: 1, azimuth: AZIMUTH, elevation: 30 };
  const flat = EXTREMES.map((p) => k.iso(p, unit));
  const span = (i) => Math.max(...flat.map((f) => f[i])) - Math.min(...flat.map((f) => f[i]));
  return Math.round((WIDTH - 2 * PAD) * (span(1) / span(0)) + 2 * PAD);
})();
export const P = k.fitProjection(EXTREMES, WIDTH, HEIGHT, { pad: PAD, azimuth: AZIMUTH, elevation: 30 });

const at = (p) => k.iso(p, P);
const S = (paths, style) => k.solidSvg(paths, style);
const L = (d, style) => k.lineSvg(d, style);
const D = (points, style) => k.dotsSvg(points, style);
const byDepth = (items, key = (p) => p) => [...items].sort((a, b) => k.depthOf(key(a), P) - k.depthOf(key(b), P));
const hue = (name, svg) => `<g data-hue="${name}">${svg}</g>`;
const AX = [1, 0, 0];
const AY = [0, 1, 0];
const AZ = [0, 0, 1];
const DOWN = [0, 0, -1];

// A rectangle and a line on a vertical face of normal +y (x along, z up).
const faceRect = (x0, x1, y, z0, z1) => k.pathOf([at([x0, y, z0]), at([x1, y, z0]), at([x1, y, z1]), at([x0, y, z1])], true);
const faceLine = (x0, x1, y, z) => k.segment([x0, y, z], [x1, y, z], P);
const tube = (points, r, tone = "mid") => tubePieces(points, r, P, { maxLength: 400 }).map((piece) => tubeSvg(piece, { tone })).join("");
const box = (x0, x1, y0, y1, z0, z1, tone = "mid", inner = "") => S(k.slabOf({ x: x0, y: y0, w: x1 - x0, d: y1 - y0, r: 0.4 }, z0, z1 - z0, P, 2, 0.3), { tone, inner });

// ── Layers ──────────────────────────────────────────────────────────────────
export const layers = [];
export const extras = { lcds: [], needles: [], wheels: [], leds: [], tags: [], hits: [] };
function layer(id, skin, svg, { group = "", pair = "", heat = false } = {}) {
  layers.push({ id, skin, group, pair, heat, svg });
}

// A plane on the floor or a face, as screen vectors per world unit, for the Godot overlays.
function planeAt(origin, u, v) {
  const o = at(origin);
  const pu = at(G.add3(origin, u));
  const pv = at(G.add3(origin, v));
  return { origin: o, u: [pu[0] - o[0], pu[1] - o[1]], v: [pv[0] - o[0], pv[1] - o[1]] };
}
function lcdOnTop(id, skin, group, plan, z) {
  extras.lcds.push({ id, skin, group, w: plan.w, h: plan.d, ...planeAt([plan.x, plan.y, z], AX, AY) });
}
function rectOf(points) {
  const corners = k.boxCorners({ x: points[0][0], y: points[0][1], w: points[1][0] - points[0][0], d: points[1][1] - points[0][1] }, points[0][2], points[1][2]).map(at);
  const xs = corners.map((p) => p[0]);
  const ys = corners.map((p) => p[1]);
  return [Math.min(...xs), Math.min(...ys), Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys)];
}

// A dial with its face up: case, bezel, ticks; the needle is Godot's.
function gaugeUp(id, skin, group, cx, cy, z, r, { stem = 0, ticks = 24, every = 4 } = {}) {
  const out = [];
  if (stem) {
    out.push(S(k.cylinder(cx, cy, 5, 0, 2, P, 24, 0.4), { tone: "lo" }));
    out.push(S(k.cylinder(cx, cy, 2.2, 2, z - 2, P, 14), { tone: "mid" }));
  }
  out.push(S(k.cylinder(cx, cy, r, z, 4, P, 48, 0.6), { tone: "hi", crease: "lo" }));
  out.push(L(k.ring(cx, cy, r - 1.6, z + 4, P, 48), { tone: "lo" }));
  const t = k.radialTicks(cx, cy, r - 2.2, ticks, every, z + 4, [1, 2.2], P, -Math.PI * 0.75, Math.PI * 1.5);
  out.push(L(t.minor, { tone: "lo" }), L(t.major, { tone: "mid" }));
  out.push(D([at([cx, cy, z + 4])], { size: 0.8, tone: "hi" }));
  extras.needles.push({ id, skin, group, from: -0.75, to: 0.75, length: r - 3.6, tail: 2, ...planeAt([cx, cy, z + 4.2], AX, AY) });
  return out.join("");
}

// ── Shared: the bench, the backboard, the control box ──────────────────────
function bench() {
  const out = [`<path class="iso-halo" d="${k.haloOf(PLATE, -PLATE_H - FOOT_H, PLATE_H, P)}"/>`];
  for (const [x, y] of byDepth(k.corners(PLATE, 24), ([x, y]) => [x, y, 0])) {
    out.push(S(k.cylinder(x, y, 8, -PLATE_H - FOOT_H, 1.8, P, 28), { tone: "lo" }));
    out.push(S(k.cylinder(x, y, 6.2, -PLATE_H - FOOT_H + 1.8, FOOT_H - 1.8, P, 28), { tone: "mid" }));
  }
  out.push(S(k.slabOf(PLATE, -PLATE_H, PLATE_H, P, 10, 1.6), { tone: "mid", inner: L(k.sideSeam(PLATE, -PLATE_H + 3.4, P, 10), { tone: "faint" }) }));
  out.push(L(k.planOutline(k.insetPlan(PLATE, 5), 0, P, 10), { tone: "lo" }));
  const screws = k.corners(PLATE, 11);
  out.push(L(screws.map(([x, y]) => k.ring(x, y, 2.4, 0, P, 16)).join(""), { tone: "lo" }));
  out.push(D(screws.map(([x, y]) => at([x, y, 0])), { size: 0.6 }));
  // The label plate of the training rig, with three rule lines for its printed text.
  const label = { x: -240, y: 58, w: 30, d: 22, r: 1.5 };
  out.push(S(k.slabOf(label, 0, 0.8, P, 3), { tone: "lo", crease: "none" }));
  for (const [i, inset] of [[0, 4], [1, 9], [2, 14]]) {
    out.push(L(k.lineOnTop([label.x + 4, label.y + 5 + i * 5], [label.x + label.w - inset, label.y + 5 + i * 5], 0.8, P), { tone: "lo", free: true }));
  }
  out.push(D([at([label.x + 2.5, label.y + 2.5, 0.8]), at([label.x + label.w - 2.5, label.y + label.d - 2.5, 0.8])], { size: 0.45 }));
  return out.join("");
}

function backboard() {
  const out = [];
  for (const x of [BOARD.x + 8, BOARD.x + BOARD.w - 18]) {
    out.push(S(k.slabOf({ x, y: BOARD.y - 2, w: 10, d: BOARD.d + 8, r: 1.5 }, 0, 6, P, 3, 0.5), { tone: "lo" }));
    out.push(D([at([x + 5, BOARD.y + BOARD.d + 3, 6])], { size: 0.5 }));
  }
  const face = BOARD.y + BOARD.d;
  const plan = { x: BOARD.x, y: BOARD.y, w: BOARD.w, d: BOARD.d, r: 1 };
  out.push(S(k.slabOf(plan, 6, BOARD.z1 - 6, P, 3, 0.6), { tone: "mid", inner: L(faceRect(BOARD.x + 4, BOARD.x + BOARD.w - 4, face, 10, BOARD.z1 - 4), { tone: "faint" }) }));
  out.push(D([[BOARD.x + 7, 13], [BOARD.x + BOARD.w - 7, 13], [BOARD.x + 7, BOARD.z1 - 7], [BOARD.x + BOARD.w - 7, BOARD.z1 - 7]].map(([x, z]) => at([x, face, z])), { size: 0.6 }));
  // The wall thermometer: a round dial on the board, its ticks from −10 to 40 °C.
  const F = G.frameAlong([AIR.x, face, AIR.z], AY);
  out.push(S(G.disc(0, 3, AIR.r + 2, F, P), { tone: "mid" }));
  out.push(S(G.disc(3, 5, AIR.r, F, P), { tone: "hi", lit: false }));
  out.push(L(G.circleOf(F, 5, AIR.r - 1.6, P), { tone: "lo" }));
  const y = face + 5;
  const ticks = [];
  const major = [];
  for (let i = 0; i <= 10; i++) {
    const a = Math.PI * (-0.75 + 1.5 * (i / 10));
    const dir = [Math.sin(a), Math.cos(a)];
    const r0 = AIR.r - (i % 2 === 0 ? 4.6 : 3.4);
    const seg = k.segment([AIR.x + dir[0] * r0, y, AIR.z + dir[1] * r0], [AIR.x + dir[0] * (AIR.r - 2.2), y, AIR.z + dir[1] * (AIR.r - 2.2)], P);
    (i % 2 === 0 ? major : ticks).push(seg);
  }
  out.push(L(ticks.join(""), { tone: "lo" }), L(major.join(""), { tone: "mid" }));
  // A short red band from 30 °C up (the tropical day) as a heavier arc of ticks.
  out.push(D([at([AIR.x, y, AIR.z])], { size: 0.9, tone: "hi" }));
  extras.needles.push({ id: "air_needle", skin: "shared", group: "", from: -0.75, to: 0.75, length: AIR.r - 4, tail: 2.4, width: 1.4, ...planeAt([AIR.x, y + 0.2, AIR.z], AX, DOWN) });
  extras.hits.push({ id: "air", control: "ambient", skin: "shared", rect: rectOf([[AIR.x - AIR.r - 2, face, AIR.z - AIR.r - 2], [AIR.x + AIR.r + 2, face + 6, AIR.z + AIR.r + 2]]) });
  return out.join("");
}

function controlBox() {
  const out = [`<path class="iso-halo" d="${k.haloOf(BOX, 0, BOX_H, P)}"/>`];
  out.push(S(k.slabOf(BOX, 0, BOX_H, P, 4, 0.8), { tone: "hi", inner: L(k.sideSeam(BOX, 4, P, 4), { tone: "faint" }) }));
  out.push(D(k.corners(BOX, 3.5).map(([x, y]) => at([x, y, BOX_H])), { size: 0.5 }));
  // The scale: seven steps round the knob, a long tick at the nameplate (the fifth).
  const t = k.radialTicks(KNOB.x, KNOB.y, KNOB.r + 6, 6, 1000, BOX_H, [2.2, 2.2], P, -Math.PI * 0.75, Math.PI * 1.5);
  out.push(L(t.minor, { tone: "mid" }));
  const a = -Math.PI * 0.75 + Math.PI * 1.5 * (4 / 6);
  out.push(L(k.lineOnTop([KNOB.x + Math.sin(a) * (KNOB.r + 3), KNOB.y - Math.cos(a) * (KNOB.r + 3)], [KNOB.x + Math.sin(a) * (KNOB.r + 9), KNOB.y - Math.cos(a) * (KNOB.r + 9)], BOX_H, P), { tone: "hi" }));
  // − and + engraved left and right of the knob.
  const mx = KNOB.x - KNOB.r - 11;
  const px = KNOB.x + KNOB.r + 11;
  out.push(L(k.lineOnTop([mx - 2.5, KNOB.y + 9], [mx + 2.5, KNOB.y + 9], BOX_H, P), { tone: "mid", free: true }));
  out.push(L(k.lineOnTop([px - 2.5, KNOB.y + 9], [px + 2.5, KNOB.y + 9], BOX_H, P) + k.lineOnTop([px, KNOB.y + 6.5], [px, KNOB.y + 11.5], BOX_H, P), { tone: "mid", free: true }));
  // The knob: a skirt, a knurled grip, a cap.
  out.push(S(k.cylinder(KNOB.x, KNOB.y, KNOB.r + 1.6, BOX_H, 1.6, P, 40), { tone: "mid" }));
  out.push(S(k.cylinder(KNOB.x, KNOB.y, KNOB.r, BOX_H + 1.6, 6, P, 40), { tone: "hi" }));
  out.push(L(k.knurl(KNOB.x, KNOB.y, KNOB.r, BOX_H + 1.6, BOX_H + 7.6, 36, P), { tone: "lo" }));
  extras.needles.push({ id: "knob_pointer", skin: "shared", group: "", from: -0.75, to: 0.75, length: KNOB.r - 1.4, tail: 0, width: 1.6, ...planeAt([KNOB.x, KNOB.y, BOX_H + 7.8], AX, AY) });
  // Its cable runs out at the back, under the bench edge's groove, to the rig.
  out.push(tube(G.fillet([[BOX.x + 6, BOX.y + 2, 6], [BOX.x + 6, BOX.y - 8, 1.4], [BOX.x - 30, BOX.y - 8, 1.4]], 6, 6), 1.2, "mid"));
  extras.hits.push({ id: "knob_down", control: "load", step: -1, skin: "shared", rect: rectOf([[KNOB.x - KNOB.r - 14, KNOB.y - KNOB.r - 8, BOX_H], [KNOB.x, KNOB.y + KNOB.r + 14, BOX_H + 8]]) });
  extras.hits.push({ id: "knob_up", control: "load", step: 1, skin: "shared", rect: rectOf([[KNOB.x, KNOB.y - KNOB.r - 8, BOX_H], [KNOB.x + KNOB.r + 14, KNOB.y + KNOB.r + 14, BOX_H + 8]]) });
  return out.join("");
}

// ── The fiets ───────────────────────────────────────────────────────────────
function trainerFrame() {
  const out = [];
  // Two cross bars on the bench, the far A-frame up to the axle, the roller's cradle.
  for (const x of [HUB.x - 44, HUB.x + 44]) {
    out.push(`<path class="iso-halo" d="${k.haloOf({ x: x - 5, y: -30, w: 10, d: 56, r: 2 }, 0, 3, P)}"/>`);
    out.push(S(k.slabOf({ x: x - 4, y: -30, w: 8, d: 56, r: 2 }, 0, 5, P, 3, 0.5), { tone: "lo" }));
    for (const y of [-26, 22]) out.push(S(k.cylinder(x, y, 3, 5, 1.5, P, 16), { tone: "mid" }));
  }
  for (const y of [-22]) {
    const F = (x0) => G.frameAlong([x0, y, 4], G.unit3([HUB.x - x0, 0, HUB.z - 4]));
    for (const x0 of [HUB.x - 40, HUB.x + 40]) {
      const len = Math.hypot(HUB.x - x0, HUB.z - 4);
      out.push(S(G.prismOf(F(x0), [[-2, -2.6], [2, -2.6], [2, 2.6], [-2, 2.6]], 0, len, P), { tone: "mid" }));
    }
    // The axle clamp at the top of the A.
    out.push(S(G.disc(-2, 4, 6, G.frameAlong([HUB.x, y - 2, HUB.z], AY), P), { tone: "mid" }));
  }
  // The roller's cradle: two blocks.
  for (const y of [-18, 16]) out.push(box(HUB.x - 8, HUB.x + 8, y - 2, y + 2, 0, ROLLER.z + 2, "mid"));
  return out.join("");
}

function crank() {
  // The bottom bracket on its post, the axle, the small chainring with its teeth.
  const out = [];
  const foot = { x: BB.x - 16, y: -16, w: 32, d: 32, r: 3 };
  out.push(`<path class="iso-halo" d="${k.haloOf(foot, 0, 3, P)}"/>`);
  out.push(S(k.slabOf(foot, 0, 3, P, 4, 0.6), { tone: "lo" }));
  out.push(D(k.corners(foot, 4).map(([x, y]) => at([x, y, 3])), { size: 0.5 }));
  out.push(S(k.slabOf({ x: BB.x - 5, y: -5, w: 10, d: 10, r: 1.5 }, 3, BB.z - 9, P, 3, 0.4), { tone: "mid" }));
  // The seat tube on up from the bottom bracket, its clamp, the saddle: a bike at once.
  out.push(S(k.cylinder(BB.x - 2, 0, 3.4, BB.z + 6, 52, P, 20), { tone: "mid" }));
  out.push(S(k.cylinder(BB.x - 2, 0, 4.4, BB.z + 50, 5, P, 20), { tone: "mid" }));
  out.push(S(k.cylinder(BB.x - 2, 0, 2.4, BB.z + 55, 14, P, 16), { tone: "hi" }));
  const saddle = { x: BB.x - 24, y: -8, w: 42, d: 16, r: 7 };
  out.push(S(k.slabOf({ x: BB.x - 10, y: -3, w: 16, d: 6, r: 1 }, BB.z + 67, 3, P, 2), { tone: "mid" }));
  out.push(S(k.slabOf(saddle, BB.z + 70, 6, P, 8, 1.4), { tone: "hi", inner: L(k.sideSeam(saddle, BB.z + 72.5, P, 8), { tone: "faint" }) }));
  out.push(L(k.lineOnTop([saddle.x + 8, 0], [saddle.x + saddle.w - 4, 0], BB.z + 76, P), { tone: "faint" }));
  const shell = G.frameAlong([BB.x, -9, BB.z], AY);
  out.push(S(G.disc(0, 18, 6.5, shell, P), { tone: "mid", inner: L(G.arcOf(shell, 9, 6.5, P), { tone: "faint" }) }));
  out.push(S(G.disc(18, CHAIN_Y - 1 + 9, 3.2, shell, P), { tone: "mid" }));
  const ring = G.frameAlong([BB.x, CHAIN_Y - 0.8, BB.z], AY);
  out.push(S(G.disc(0, 1.6, RING_R, ring, P, { steps: 64 }), { tone: "hi", inner: L(G.arcOf(ring, 1.6, RING_R - 3.5, P, { inward: true }), { tone: "faint" }) }));
  out.push(D(G.dotsOf(ring, 1.6, RING_R - 0.6, 22, P, { all: true }), { size: 0.55, tone: "mid" }));
  out.push(S(G.disc(1.6, 3.6, 4.2, ring, P), { tone: "mid" }));
  // The crank arm and the pedal turn: Godot draws them on the chain plane, in front.
  extras.wheels.push({ id: "crank", skin: "fiets", group: "source", r: 19, r0: 0, blades: 1, width: 3.4, tip: 3.2, ...planeAt([BB.x, CHAIN_Y + 3.4, BB.z], AX, DOWN) });
  return out.join("");
}

// The chain: a loop round the chainring and the sprocket, in the plane y = CHAIN_Y.
function chainRoute() {
  const d = HUB.x - BB.x;
  const s = (SPROCKET_R - RING_R) / d;
  const c = Math.sqrt(1 - s * s);
  const pts = [];
  const arc = (cx, r, a0, a1, n) => {
    for (let i = 0; i <= n; i++) {
      const a = a0 + (a1 - a0) * (i / n);
      pts.push([cx + r * Math.cos(a), CHAIN_Y, BB.z + r * Math.sin(a)]);
    }
  };
  // Angles in the x–z plane; the upper tangent touches both at angle a = atan2(c, -s).
  const up = Math.atan2(c, -s);
  const down = Math.atan2(-c, -s);
  arc(HUB.x, SPROCKET_R + 1, up, down + Math.PI * 2 - Math.PI * 2, 36); // over the right, down
  arc(BB.x, RING_R + 1, down, up - Math.PI * 2, 20); // round the left
  return pts;
}
function chain(silhouette = false) {
  const route = chainRoute();
  const pieces = tubePieces(route, 1.8, P, { maxLength: 60, closed: true });
  if (silhouette) return pieces.map((piece) => `<path class="heat" d="${piece.body}"/>`).join("");
  const out = [`<g class="iso-solid" data-lit="">${pieces.map((piece) => tubeSvg(piece, { tone: "hi" })).join("")}</g>`];
  // The links' pins along the loop, the far ones left out where the loop turns away.
  const pins = G.resample(route, 3.2).filter((_, i) => i % 1 === 0);
  out.push(D(pins.map(at), { size: 0.5, tone: "hi" }));
  return out.join("");
}

function wheel() {
  const out = [];
  const F = G.frameAlong([HUB.x, -4, HUB.z], AY);
  // The tyre on its rim, the hub, the sprocket in front of it.
  out.push(S(G.ringBand(0, 8, TYRE.rIn, TYRE.rOut, F, P, { steps: 120 }), { tone: "hi" }));
  out.push(L(G.circleOf(F, 8, TYRE.rOut - 2.5, P, 120), { tone: "lo" }));
  out.push(S(G.ringBand(1.5, 6.5, TYRE.rIn - 4, TYRE.rIn, F, P, { steps: 120 }), { tone: "mid" }));
  out.push(L(G.circleOf(F, 6.5, TYRE.rIn - 2, P, 120), { tone: "faint" }));
  // Thirty-two spokes from the hub's two flanges to the rim, crossing.
  const spokes = [];
  for (let i = 0; i < 32; i++) {
    const a0 = (i / 32) * Math.PI * 2;
    spokes.push(k.pathOf([at(G.pointOf(F, i % 2 ? 6 : 1, 6, a0)), at(G.pointOf(F, 4, TYRE.rIn - 4, a0 + (i % 2 ? 0.45 : -0.45)))]));
  }
  out.push(L(spokes.join(""), { tone: "lo" }));
  out.push(S(G.disc(-6, 12, 5, F, P), { tone: "mid" }));
  out.push(L(G.arcOf(F, -2, 5, P) + G.arcOf(F, 10, 5, P), { tone: "faint" }));
  // The axle nuts.
  out.push(S(G.disc(12, 18, 3, F, P), { tone: "mid" }));
  const sp = G.frameAlong([HUB.x, CHAIN_Y - 0.8, HUB.z], AY);
  out.push(S(G.disc(0, 1.6, SPROCKET_R, sp, P, { steps: 120 }), { tone: "hi", inner: L(G.arcOf(sp, 1.6, SPROCKET_R - 4, P, { inward: true }), { tone: "faint" }) }));
  out.push(D(G.dotsOf(sp, 1.6, SPROCKET_R - 0.6, 56, P, { all: true }), { size: 0.55, tone: "mid" }));
  out.push(L(G.spokesOf(sp, 1.6, 8, SPROCKET_R - 6, 5, P, { phase: 0.2 }), { tone: "lo" }));
  out.push(S(G.disc(1.6, 4, 6, sp, P), { tone: "mid" }));
  // The valve on the rim turns, slowly: the wheel goes round a third as fast as the pedals.
  extras.wheels.push({ id: "valve", skin: "fiets", group: "out", r: TYRE.rIn - 1, r0: TYRE.rIn - 7, blades: 1, width: 2.6, ...planeAt([HUB.x, 4.5, HUB.z], AX, DOWN) });
  return out.join("");
}

function resistance() {
  // The roller under the tyre and the resistance unit on its near end: a finned drum.
  const out = [];
  const F = G.frameAlong([HUB.x, -16, ROLLER.z], AY);
  out.push(S(G.disc(0, 30, ROLLER.r, F, P), { tone: "mid", inner: L(G.arcOf(F, 15, ROLLER.r, P), { tone: "faint" }) }));
  const U = G.frameAlong([HUB.x, 16, 11], AY);
  out.push(S(G.disc(0, 4, 3, U, P), { tone: "mid" }));
  out.push(S(G.disc(4, 22, 11, U, P, { steps: 64 }), { tone: "hi" }));
  out.push(L([8, 11, 14, 17, 20].map((s) => G.arcOf(U, s, 11, P)).join(""), { tone: "lo" }));
  out.push(S(G.disc(22, 24, 6, U, P), { tone: "mid" }));
  out.push(box(HUB.x - 8, HUB.x + 8, 24, 38, 0, 2, "lo"));
  // The Bowden cable from the unit to the knob's box.
  out.push(tube(G.fillet([[HUB.x + 6, 38, 6], [HUB.x + 30, 44, 1.4], [BOX.x - 30, BOX.y - 8, 1.4]], 8, 6), 1.2, "mid"));
  return out.join("");
}

// ── The trafo ───────────────────────────────────────────────────────────────
function fins(side) {
  // Corrugated cooling fins on the side walls: x0 the wall's outside, out along ±x.
  const out = [];
  const x0 = side > 0 ? TANK.x1 : TANK.x0;
  const list = [];
  for (let y = TANK.y0 + 4; y <= TANK.y1 - 4; y += 6) list.push(y);
  for (const y of byDepth(list, (y) => [x0 + side * 7, y, 60])) {
    const xa = side > 0 ? x0 : x0 - 14;
    out.push(box(xa, xa + 14, y - 0.8, y + 0.8, TANK.z0 + 10, OIL_Z - 2, "mid"));
  }
  // The fin header along the top and the bottom.
  const xa = side > 0 ? x0 : x0 - 14;
  out.push(box(xa, xa + 14, TANK.y0 + 2, TANK.y1 - 2, OIL_Z - 2, OIL_Z + 1, "mid"));
  return out.join("");
}

function tankBack() {
  const out = [];
  const skid = { x: TANK.x0 - 6, y: TANK.y0 - 2, w: TANK.x1 - TANK.x0 + 12, d: TANK.y1 - TANK.y0 + 4, r: 2 };
  out.push(`<path class="iso-halo" d="${k.haloOf(skid, 0, 4, P)}"/>`);
  for (const y of [TANK.y0 + 4, TANK.y1 - 10]) out.push(box(TANK.x0 - 6, TANK.x1 + 6, y, y + 6, 0, TANK.z0, "lo"));
  out.push(fins(-1));
  const t = "mid";
  out.push(box(TANK.x0, TANK.x1, TANK.y0, TANK.y0 + WALL, TANK.z0, TANK.z1, t)); // the back wall
  out.push(box(TANK.x0, TANK.x0 + WALL, TANK.y0 + WALL, TANK.y1, TANK.z0, TANK.z1, t)); // the left wall
  out.push(box(TANK.x0 + WALL, TANK.x1, TANK.y0 + WALL, TANK.y1, TANK.z0, TANK.z0 + WALL, "lo")); // the floor
  return out.join("");
}

function coreInside() {
  // The core: three legs between two yokes; on each leg the low-voltage winding (inside) and the
  // high-voltage winding (outside, many fine turns); spacers on top; the oil over it all.
  const out = [];
  const plan = (x0, x1, y0, y1) => ({ x: x0, y: y0, w: x1 - x0, d: y1 - y0, r: 0.5 });
  out.push(S(k.slabOf(plan(LEGS[0] - 8, LEGS[2] + 8, CORE_Y - 7, CORE_Y + 7), TANK.z0 + WALL, 13, P, 2, 0.4), { tone: "mid", inner: L(k.sideSeam(plan(LEGS[0] - 8, LEGS[2] + 8, CORE_Y - 7, CORE_Y + 7), TANK.z0 + WALL + 6.5, P, 2), { tone: "faint" }) }));
  for (const x of byDepth(LEGS, (x) => [x, CORE_Y, 60])) {
    out.push(S(k.slabOf(plan(x - 7, x + 7, CORE_Y - 7, CORE_Y + 7), TANK.z0 + WALL + 13, 70, P, 2, 0.3), { tone: "mid" }));
    const lv = k.cylinder(x, CORE_Y, COIL.lv, COIL.z0, COIL.z1 - COIL.z0 + 3, P, 48);
    out.push(hue("copper", S(lv, { tone: "hi" })));
    out.push(hue("copper", L([COIL.z1 + 1, COIL.z1 + 2].map((z) => k.sideArc(x, CORE_Y, COIL.lv, z, P, 32)).join(""), { tone: "lo" })));
    const hv = k.cylinder(x, CORE_Y, COIL.hv, COIL.z0, COIL.z1 - COIL.z0, P, 64, 0.6);
    const turns = [];
    for (let z = COIL.z0 + 2.5; z < COIL.z1 - 1; z += 2.4) turns.push(k.sideArc(x, CORE_Y, COIL.hv, z, P, 40));
    out.push(hue("copper", `<g class="iso-solid" data-lit="">${S(hv, { tone: "hi", inner: L(turns.join(""), { tone: "lo" }) })}</g>`));
    out.push(hue("copper", L(k.ring(x, CORE_Y, (COIL.hv + COIL.lv) / 2 + 0.6, COIL.z1, P, 48), { tone: "lo" })));
    // Spacer blocks between the windings and the top yoke.
    for (const a of [0.3, 1.9, 3.5, 5.1]) {
      const sx = x + Math.cos(a) * 18.5;
      const sy = CORE_Y + Math.sin(a) * 18.5;
      out.push(box(sx - 1.6, sx + 1.6, sy - 1.6, sy + 1.6, COIL.z1, COIL.z1 + 4, "lo"));
    }
  }
  const yoke = plan(LEGS[0] - 8, LEGS[2] + 8, CORE_Y - 7, CORE_Y + 7);
  out.push(S(k.slabOf(yoke, COIL.z1 + 4, 10, P, 2, 0.4), { tone: "mid", inner: L(k.sideSeam(yoke, COIL.z1 + 9, P, 2), { tone: "faint" }) }));
  for (const x of [LEGS[0] - 4, LEGS[2] + 4]) out.push(D([at([x, CORE_Y + 7, COIL.z1 + 9])], { size: 0.6 }));
  // The leads up to the bushings: three from the outer windings, four from the inner.
  HV_X.forEach((bx, i) => out.push(tube(G.fillet([[LEGS[i] - 12, CORE_Y - 12, COIL.z1 + 1], [LEGS[i] - 12, CORE_Y - 12, COIL.z1 + 8], [bx, BUSH_Y, TANK.z1 - 2]], 4, 5), 0.9, "lo")));
  LV_X.forEach((bx, i) => {
    const leg = LEGS[Math.min(i, 2)];
    out.push(tube(G.fillet([[leg + 6, CORE_Y - 10, COIL.z1 + 3], [leg + 6, CORE_Y - 14, COIL.z1 + 16], [bx, BUSH_Y, TANK.z1 - 2]], 4, 5), 1.1, "lo"));
  });
  // The oil: its surface and the cut through it, an amber wash over the core.
  const xa = TANK.x0 + WALL;
  const xb = TANK.x1 - WALL;
  out.push(`<path class="oil" d="${k.pathOf([at([xa, TANK.y0 + WALL, OIL_Z]), at([xb, TANK.y0 + WALL, OIL_Z]), at([xb, TANK.y1, OIL_Z]), at([xa, TANK.y1, OIL_Z])], true)}"/>`);
  out.push(`<path class="oil" d="${k.pathOf([at([xa, TANK.y1, TANK.z0 + WALL]), at([xb, TANK.y1, TANK.z0 + WALL]), at([xb, TANK.y1, OIL_Z]), at([xa, TANK.y1, OIL_Z])], true)}"/>`);
  return out.join("");
}

function coilsSilhouette() {
  return LEGS.map((x) => `<path class="heat" d="${k.cylinder(x, CORE_Y, COIL.hv, COIL.z0, COIL.z1 - COIL.z0, P, 64).fill ?? ""}"/>`).join("");
}

function tankFront() {
  const out = [];
  out.push(box(TANK.x1 - WALL, TANK.x1, TANK.y0 + WALL, TANK.y1, TANK.z0, TANK.z1, "mid")); // the right wall
  out.push(fins(1));
  // The lid over the back half (the front half is cut away with the tank's front), its screws.
  const lid = { x: TANK.x0 - 3, y: LID.y0, w: TANK.x1 - TANK.x0 + 6, d: LID.y1 - LID.y0, r: 1 };
  out.push(S(k.slabOf(lid, LID.z, LID.h, P, 3, 0.6), { tone: "hi", inner: L(k.sideSeam(lid, LID.z + 2, P, 3), { tone: "faint" }) }));
  const screws = [];
  for (let x = lid.x + 6; x < lid.x + lid.w - 3; x += 12) screws.push([x, lid.y + 3], [x, lid.y + lid.d - 3]);
  out.push(D(screws.map(([x, y]) => at([x, y, LID.z + LID.h])), { size: 0.45 }));
  // The cut: a faint line where the front half of the lid and the front wall were.
  out.push(L(k.segment([TANK.x0, TANK.y1, TANK.z1], [TANK.x1, TANK.y1, TANK.z1], P), { tone: "faint", dashed: true }));
  // Lifting eyes at the lid's corners.
  for (const x of [TANK.x0 + 6, TANK.x1 - 8]) {
    out.push(box(x - 2, x + 2, LID.y0 + 2, LID.y0 + 6, LID.z + LID.h, LID.z + LID.h + 4, "mid"));
    out.push(L(k.sideRing([x, LID.y0 + 4, LID.z + LID.h + 7], 3.4, "x", P, 20), { tone: "mid" }));
  }
  // The nameplate, its printed text as rule lines.
  const plate = { x: -100, y: LID.y0 + 4, w: 26, d: 18, r: 1 };
  out.push(S(k.slabOf(plate, LID.z + LID.h, 0.6, P, 2), { tone: "lo", crease: "none" }));
  for (const [i, inset] of [[0, 4], [1, 8], [2, 12]]) out.push(L(k.lineOnTop([plate.x + 3, plate.y + 4 + i * 4.5], [plate.x + plate.w - inset, plate.y + 4 + i * 4.5], LID.z + LID.h + 0.6, P), { tone: "lo", free: true }));
  out.push(D([at([plate.x + 1.8, plate.y + 1.8, LID.z + LID.h + 0.6]), at([plate.x + plate.w - 1.8, plate.y + plate.d - 1.8, LID.z + LID.h + 0.6])], { size: 0.4 }));
  // The oil thermometer on the lid.
  out.push(gaugeUp("oil_needle", "trafo", "tank", 2, LID.y0 + 14, LID.z + LID.h, 9, { ticks: 24, every: 4 }));
  return out.join("");
}

function bushingStack(x, y, z, sheds, rShed, rCore) {
  // A porcelain bushing: a flange, the core with its sheds, the terminal stud.
  const F = G.frameAlong([x, y, z], AZ);
  const out = [S(G.disc(0, 2, rCore + 3, F, P), { tone: "mid" })];
  let s = 2;
  for (let i = 0; i < sheds; i++) {
    out.push(S(G.disc(s, s + 2.4, rCore, F, P), { tone: "hi" }));
    out.push(S(G.disc(s + 2.4, s + 3.4, rShed, F, P, { steps: 40 }), { tone: "hi" }));
    s += 3.4;
  }
  out.push(S(G.disc(s, s + 3, rCore, F, P), { tone: "hi" }));
  out.push(S(G.disc(s + 3, s + 7, 1.6, F, P), { tone: "mid" }));
  return { svg: out.join(""), top: z + s + 7 };
}

function hvSide() {
  const out = [];
  // The 10 kV cable up from the floor through a gland, its breakout and three tails.
  const gx = TANK.x0 - 26;
  out.push(S(k.cylinder(gx, BUSH_Y, 7, 0, 4, P, 24, 0.5), { tone: "lo" }));
  out.push(S(k.cylinder(gx, BUSH_Y, 5, 4, 6, P, 24), { tone: "mid" }));
  out.push(tube(G.fillet([[gx, BUSH_Y, 10], [gx, BUSH_Y, 150]], 6, 6), 4, "hi"));
  const breakout = G.frameAlong([gx, BUSH_Y, 150], AZ);
  out.push(S(G.solidOf([[0, 4.6], [6, 5.6], [10, 4.6]], breakout, P), { tone: "mid" }));
  const stacks = HV_X.map((x) => bushingStack(x, BUSH_Y, LID.z + LID.h, 5, 6, 3.4));
  for (const st of stacks) out.push(st.svg);
  HV_X.forEach((x, i) => {
    const top = stacks[i].top;
    const route = G.fillet([[gx + (i - 1) * 2.4, BUSH_Y, 160], [gx + (i - 1) * 2.4, BUSH_Y, 166 + i * 2], [x, BUSH_Y, 166 + i * 2], [x, BUSH_Y, top + 4]], 6, 6);
    out.push(tube(route, 1.8, "hi"));
    out.push(S(k.cylinder(x, BUSH_Y, 2.6, top - 1, 5, P, 18), { tone: "mid" }));
  });
  return out.join("");
}

function lvSide() {
  const out = [];
  const stacks = LV_X.map((x) => bushingStack(x, BUSH_Y, LID.z + LID.h, 2, 5, 3));
  for (const st of stacks) out.push(st.svg);
  // Insulated cables from the bushings over to the rek's busbar.
  LV_X.forEach((x, i) => {
    const top = stacks[i].top;
    const rx = FUSE_X[i];
    const route = G.fillet([[x, BUSH_Y, top - 1], [x, BUSH_Y, 152 + i * 3], [rx, BUSH_Y, 152 + i * 3], [rx, REK.y + 6, 140], [rx, REK.y + 6, 132]], 6, 6);
    out.push(tube(route, 2, "hi"));
    out.push(S(k.cylinder(x, BUSH_Y, 3, top - 2, 3, P, 18), { tone: "mid" }));
  });
  // The rek: a back panel on two posts, the busbar, four fuse bases with their fuses.
  for (const x of [REK.x0, REK.x1 - 5]) out.push(box(x, x + 5, REK.y - 4, REK.y + 2, 0, REK.top, "mid"));
  out.push(box(REK.x0 + 5, REK.x1 - 5, REK.y - 3, REK.y, 6, REK.top - 4, "lo", L(faceRect(REK.x0 + 9, REK.x1 - 9, REK.y, 12, REK.top - 10), { tone: "faint" })));
  out.push(box(REK.x0 + 6, REK.x1 - 6, REK.y, REK.y + 4, 126, 132, "hi"));
  for (const x of FUSE_X) {
    out.push(box(x - 5, x + 5, REK.y, REK.y + 4, 70, 118, "mid"));
    const F = G.frameAlong([x, REK.y + 8, 78], AZ);
    out.push(S(G.disc(0, 30, 4, F, P), { tone: "hi", inner: L(G.arcOf(F, 6, 4, P) + G.arcOf(F, 24, 4, P), { tone: "faint" }) }));
    out.push(box(x - 1.2, x + 1.2, REK.y + 2, REK.y + 8, 108, 122, "mid"));
    out.push(D([at([x, REK.y + 4, 124]), at([x, REK.y + 4, 72])], { size: 0.5, tone: "hi" }));
  }
  return out.join("");
}

function street() {
  const out = [];
  // The outgoing cables: from each fuse down the rek, along the bench to its house.
  FUSE_X.forEach((x, i) => {
    const hx = HOUSES[i] - HOUSE.w / 2 + 3;
    const route = G.fillet([[x, REK.y + 8, 70], [x, REK.y + 10, 1.6], [x, 30 + i * 4, 1.6], [hx, 30 + i * 4, 1.6], [hx, HOUSE.y + HOUSE.d + 0.5, 1.6]], 5, 6);
    out.push(tube(route, 1.4, "mid"));
  });
  for (const cx of HOUSES) {
    const h = { x: cx - HOUSE.w / 2, y: HOUSE.y, w: HOUSE.w, d: HOUSE.d, r: 0.5 };
    out.push(`<path class="iso-halo" d="${k.haloOf(h, 0, 3, P)}"/>`);
    const y = h.y + h.d;
    const inner = L(faceRect(cx - 6, cx - 1.5, y, 4, 10) + faceRect(cx + 1.5, cx + 6, y, 4, 10), { tone: "mid" });
    out.push(S(k.slabOf(h, 0, HOUSE.wall, P, 2, 0.3), { tone: "hi", inner }));
    // The gable roof, its ridge along y.
    const F = G.frameAlong([cx, h.y - 1.5, HOUSE.wall], AY);
    out.push(S(G.prismOf(F, [[-h.w / 2 - 1.5, 0], [h.w / 2 + 1.5, 0], [0, HOUSE.ridge - HOUSE.wall]].map(([u, v]) => [u, v]), 0, h.d + 3, P), { tone: "mid" }));
    out.push(box(cx + 3, cx + 6, h.y + 3, h.y + 6, HOUSE.wall + 4, HOUSE.ridge + 2, "mid")); // the chimney
  }
  return out.join("");
}

function windowsLit(cx) {
  const y = HOUSE.y + HOUSE.d + 0.2;
  return hue("lamp", `<g class="iso-solid">${[[cx - 6, cx - 1.5], [cx + 1.5, cx + 6]].map(([a, b]) => `<path class="iso-fill" d="${faceRect(a, b, y, 4, 10)}"/>`).join("")}</g>`);
}

// ── The meters ──────────────────────────────────────────────────────────────
function meterBox(id, plan, z, lead) {
  const out = [`<path class="iso-halo" d="${k.haloOf(plan, 0, 4, P)}"/>`];
  out.push(S(k.cylinder(plan.x + plan.w / 2, plan.y + plan.d / 2, 5, 0, 2, P, 24, 0.4), { tone: "lo" }));
  out.push(S(k.slabOf({ x: plan.x + plan.w / 2 - 2, y: plan.y + plan.d / 2 - 2, w: 4, d: 4, r: 1 }, 2, z - 2, P, 2), { tone: "mid" }));
  out.push(S(k.slabOf(plan, z, 9, P, 4, 0.8), { tone: "hi", inner: L(k.sideSeam(plan, z + 3, P, 4), { tone: "faint" }) }));
  const lcd = { x: plan.x + 3, y: plan.y + 3, w: plan.w - 6, d: plan.d - 9, r: 0.6 };
  out.push(S(k.slabOf(lcd, z + 9, 0.3, P, 2), { tone: "lo", crease: "none" }));
  lcdOnTop(id, "trafo", id === "mv_meter" ? "meter_in" : "meter_out", lcd, z + 9.3);
  out.push(D([at([plan.x + 4, plan.y + plan.d - 4, z + 9]), at([plan.x + plan.w - 4, plan.y + plan.d - 4, z + 9])], { size: 0.6, tone: "mid" }));
  out.push(tube(lead, 0.8, "mid"));
  return out.join("");
}

// ── Assemble every layer in painter's order ─────────────────────────────────
layer("base", "shared", bench());
layer("backboard", "shared", backboard());

layer("trainer_frame", "fiets", trainerFrame(), { group: "tank", pair: "tank_front" });
layer("tank_back", "trafo", tankBack(), { group: "tank" });
layer("core_inside", "trafo", coreInside(), { group: "core", pair: "chain" });
layer("heat_coils", "trafo", coilsSilhouette(), { group: "core", pair: "heat_chain", heat: true });
layer("tank_front", "trafo", tankFront(), { group: "tank", pair: "trainer_frame" });

layer("crank", "fiets", crank(), { group: "source", pair: "hv_side" });
layer("hv_side", "trafo", hvSide(), { group: "source", pair: "crank" });

layer("wheel", "fiets", wheel(), { group: "out", pair: "lv_side" });
layer("lv_side", "trafo", lvSide(), { group: "out", pair: "wheel" });

layer("resistance", "fiets", resistance(), { group: "street", pair: "street" });
layer("street", "trafo", street(), { group: "street", pair: "resistance" });
HOUSES.forEach((cx, i) => layer(`house${i + 1}_lit`, "trafo", windowsLit(cx), { group: "street" }));

layer("chain", "fiets", chain(), { group: "core", pair: "core_inside" });
layer("heat_chain", "fiets", chain(true), { group: "core", pair: "heat_coils", heat: true });

layer("gauge_pedal", "fiets", gaugeUp("gauge_pedal", "fiets", "meter_in", GAUGE_IN.x, GAUGE_IN.y, 28, 15, { stem: 1 }), { group: "meter_in", pair: "mv_meter" });
layer("mv_meter", "trafo", meterBox("mv_meter", { x: GAUGE_IN.x - 18, y: GAUGE_IN.y - 12, w: 36, d: 24, r: 3 }, 20,
  G.fillet([[GAUGE_IN.x, GAUGE_IN.y - 9, 24], [GAUGE_IN.x, BUSH_Y + 12, 24], [TANK.x0 - 26, BUSH_Y + 7, 30]], 5, 6)), { group: "meter_in", pair: "gauge_pedal" });
layer("gauge_wheel", "fiets", gaugeUp("gauge_wheel", "fiets", "meter_out", GAUGE_OUT.x, GAUGE_OUT.y, 28, 15, { stem: 1 }), { group: "meter_out", pair: "lv_meter" });
layer("lv_meter", "trafo", meterBox("lv_meter", { x: GAUGE_OUT.x - 18, y: GAUGE_OUT.y - 12, w: 36, d: 24, r: 3 }, 20,
  G.fillet([[GAUGE_OUT.x, GAUGE_OUT.y - 9, 24], [GAUGE_OUT.x, REK.y + 14, 24], [REK.x1 - 8, REK.y + 6, 60]], 5, 6)), { group: "meter_out", pair: "gauge_wheel" });

layer("control_box", "shared", controlBox());

// The marker tags Ruud holds up during the cross-fade (placed in Godot).
extras.tags.push({ id: "snel_licht", at: at([BB.x - 10, CHAIN_Y, BB.z + 40]) });
extras.tags.push({ id: "ketting", at: at([-70, CHAIN_Y, BB.z + 38]) });
extras.tags.push({ id: "langzaam_sterk", at: at([HUB.x + 30, CHAIN_Y, HUB.z + 70]) });
