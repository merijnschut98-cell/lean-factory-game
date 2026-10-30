// "Hoe werkt het? 1": one bench, two skins (spec 2026-10-16-explainer-spanning-stroom-weerstand §3).
// Skin "tuin": a garden tap, a hose reel, a flow meter, a manifold with three valves and three sprinklers.
// Skin "meterkast": a group in a meter panel, a cable reel, a clamp meter, a power strip with three
// switches and three appliances. Every analogy part stands in the slot of its real counterpart, so
// the cross-fade never re-sorts. Each layer is one painter's slot that changes on its own; the list
// order is the z order. Built with the anatomy kit (tools/explainers/kit, MIT).
import * as k from "../kit/iso-kit.mjs";
import * as G from "../kit/lathe.mjs";
import { tubePieces, tubeSvg } from "../kit/tube.mjs";

export const WIDTH = 1200;

// ── The world (units ≈ px of a real bench, z up) ────────────────────────────
const PLATE = { x: -250, y: -88, w: 500, d: 176, r: 10 };
const PLATE_H = 12;
const FOOT_H = 6;
const RULER = { x: -214, y: 64, w: 428, d: 13, r: 1.5 };
const M = 16; // one metre on the ruler
const RULER_FROM = -200; // 0 m

const WALL = { x: -236, y: -84, w: 112, d: 7, r: 1 }; // back plate, standing on two feet
const WALL_Z0 = 7;
const WALL_Z1 = 132;
const FACE_Y = WALL.y + WALL.d; // the plate's front face (normal +y)

const REEL1 = { x: -104, y: -30 };
const REEL2 = { x: -176, y: 22 };
const HUB_Z = 38;
const CORE_R = 13;
const FLANGE_R = 31;
const HALF = 14; // half the drum's width (between flanges)
const FLANGE_T = 2.6;
const WOUND = { rolled: 27, unrolled: 19 };

const ROUTE_Y = 44; // the cable or hose runs along the ruler here
const STRIP = { x: 148, y: 30, w: 58, d: 26, r: 3 }; // power strip / manifold slot
const STRIP_H = 13;
const LOAD_X = { lamp: 132, kettle: 172, heater: 214 };
const LOAD_Y = { lamp: -14, kettle: -30, heater: -22 };
const SOCKET_X = { lamp: 160, kettle: 177, heater: 194 };
const CLAMP_X = -26; // clamp meter / flow meter on the route
const THERMO_X = 66; // thermometer, halfway
const METER = { x: 214, y: 30, w: 30, d: 44, r: 3 }; // multimeter / end gauge slot

export const WIRE = { thin: 2.1, thick: 3.1 }; // cable radii
const HOSE = { thin: 2.9, thick: 4.1 };

// Camera: azimuth 58° shows the bench's long side (anatomy: 35–60° for that); the viewBox takes
// the figure's own shape, so the sheet in the game holds no empty band.
const AZIMUTH = 58;
const EXTREMES = [...k.boxCorners(PLATE, -PLATE_H - FOOT_H, 0), [WALL.x, WALL.y, WALL_Z1 + 4], [WALL.x + WALL.w, WALL.y, WALL_Z1 + 4], [LOAD_X.kettle, LOAD_Y.kettle, 62]];
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
const byDepth = (points) => [...points].sort((a, b) => k.depthOf([a[0], a[1], a[2] ?? 0], P) - k.depthOf([b[0], b[1], b[2] ?? 0], P));
const AY = [0, 1, 0];
const AX = [1, 0, 0];
const AZ = [0, 0, 1];

// A rectangle on a vertical face of normal +y (x along, z up), as a closed path.
const faceRect = (x0, x1, y, z0, z1) => k.pathOf([at([x0, y, z0]), at([x1, y, z0]), at([x1, y, z1]), at([x0, y, z1])], true);
const faceLine = (x0, x1, y, z) => k.segment([x0, y, z], [x1, y, z], P);

// Stroked glyphs for the one engraved label (text as paths: Godot's SVG
// renderer draws no <text>). Each glyph is polylines in a 3 × 5 cell.
const GLYPHS = {
  B: [[[0, 0], [0, 5], [2.2, 5], [3, 4.3], [3, 3.2], [2.2, 2.5], [0, 2.5]], [[2.2, 2.5], [3, 1.8], [3, 0.7], [2.2, 0], [0, 0]]],
  1: [[[0.6, 4], [1.6, 5], [1.6, 0]], [[0.6, 0], [2.6, 0]]],
  6: [[[2.8, 4.6], [2, 5], [1, 5], [0.2, 4.2], [0.2, 0.8], [1, 0], [2, 0], [2.8, 0.8], [2.8, 2], [2, 2.7], [1, 2.7], [0.2, 2]]],
};
function engraved(text, x0, y, z0, height) {
  const scale = height / 5;
  const out = [];
  [...text].forEach((ch, index) => {
    for (const line of GLYPHS[ch]) {
      out.push(k.pathOf(line.map(([u, v]) => at([x0 + (index * 4 + u) * scale, y, z0 + v * scale]))));
    }
  });
  return out.join("");
}

// ── Layers ──────────────────────────────────────────────────────────────────
export const layers = [];
export const extras = { lcds: [], needles: [], wheels: [], leds: [], tags: [], hits: [] };
// skin: shared | tuin | meterkast. group: the mapping group the cross-fade staggers by.
function layer(id, skin, svg, { group = "", pair = "", heat = false } = {}) {
  layers.push({ id, skin, group, pair, heat, svg });
}

// A plane on the floor or a face, as screen vectors per world unit, for the
// Godot overlays (LCD labels, needles, the paddle wheel).
function planeAt(origin, u, v) {
  const o = at(origin);
  const pu = at(G.add3(origin, u));
  const pv = at(G.add3(origin, v));
  return { origin: o, u: [pu[0] - o[0], pu[1] - o[1]], v: [pv[0] - o[0], pv[1] - o[1]] };
}
// An LCD window on a top face: origin is its back-left corner (min x, min y), x along +x, y along +y.
function lcdOnTop(id, skin, plan, z) {
  extras.lcds.push({ id, skin, w: plan.w, h: plan.d, ...planeAt([plan.x, plan.y, z], AX, AY) });
}

// ── Shared: the bench ───────────────────────────────────────────────────────
function bench() {
  const out = [`<path class="iso-halo" d="${k.haloOf(PLATE, -PLATE_H - FOOT_H, PLATE_H, P)}"/>`];
  for (const [x, y] of byDepth(k.corners(PLATE, 24))) {
    out.push(S(k.cylinder(x, y, 8, -PLATE_H - FOOT_H, 1.8, P, 28), { tone: "lo" }));
    out.push(S(k.cylinder(x, y, 6.2, -PLATE_H - FOOT_H + 1.8, FOOT_H - 1.8, P, 28), { tone: "mid" }));
  }
  out.push(S(k.slabOf(PLATE, -PLATE_H, PLATE_H, P, 10, 1.6), { tone: "mid", inner: L(k.sideSeam(PLATE, -PLATE_H + 3.4, P, 10), { tone: "faint" }) }));
  out.push(L(k.planOutline(k.insetPlan(PLATE, 5), 0, P, 10), { tone: "lo" }));
  const screws = k.corners(PLATE, 11);
  out.push(L(screws.map(([x, y]) => k.ring(x, y, 2.4, 0, P, 16)).join(""), { tone: "lo" }));
  out.push(D(screws.map(([x, y]) => at([x, y, 0])), { size: 0.6 }));
  // The ruler strip: 0–25 m, a tick every metre, a long one every five.
  out.push(S(k.slabOf(RULER, 0, 0.8, P, 3), { tone: "lo", crease: "none" }));
  const ticks = k.topTicks(RULER_FROM, RULER_FROM + 25 * M, M, 5, RULER.y + 0.6, 0.8, [3, 6.5], P);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  const halves = k.topTicks(RULER_FROM + M / 2, RULER_FROM + 25 * M - M / 2, M, 1000, RULER.y + 0.6, 0.8, [1.6, 1.6], P);
  out.push(L(halves.minor, { tone: "faint" }));
  out.push(D([at([RULER.x + 3, RULER.y + RULER.d / 2, 0.8]), at([RULER.x + RULER.w - 3, RULER.y + RULER.d / 2, 0.8])], { size: 0.55 }));
  // The label plate, with three rule lines for its printed text.
  const label = { x: 222, y: -78, w: 20, d: 30, r: 1.5 };
  out.push(S(k.slabOf(label, 0, 0.8, P, 3), { tone: "lo", crease: "none" }));
  for (const [i, inset] of [[0, 5], [1, 8], [2, 12]]) {
    out.push(L(k.lineOnTop([label.x + 5 + i * 5, label.y + 4], [label.x + 5 + i * 5, label.y + label.d - inset], 0.8, P), { tone: "lo", free: true }));
  }
  out.push(D([at([label.x + 2.5, label.y + 2.5, 0.8]), at([label.x + label.w - 2.5, label.y + label.d - 2.5, 0.8])], { size: 0.45 }));
  return out.join("");
}

// ── The back plate: a meter panel, or a garden wall ──────────────────────────
function backPlate(brick) {
  const out = [];
  for (const x of [WALL.x + 8, WALL.x + WALL.w - 18]) {
    const foot = { x, y: WALL.y - 2, w: 10, d: WALL.d + 6, r: 1.5 };
    out.push(S(k.slabOf(foot, 0, WALL_Z0, P, 3, 0.5), { tone: "lo" }));
    out.push(D([at([x + 5, WALL.y + WALL.d + 2, WALL_Z0])], { size: 0.5 }));
  }
  let inner = "";
  if (brick) {
    // Mortar courses run edge to edge; the head joints stand between two courses.
    const courses = [];
    const heads = [];
    for (let z = WALL_Z0 + 9, row = 0; z < WALL_Z1 - 2; z += 9, row++) {
      courses.push(faceLine(WALL.x, WALL.x + WALL.w, FACE_Y, z));
      for (let x = WALL.x + (row % 2 ? 9 : 18); x < WALL.x + WALL.w - 4; x += 18) heads.push(k.segment([x, FACE_Y, z], [x, FACE_Y, Math.min(z + 9, WALL_Z1)], P));
    }
    for (let x = WALL.x + 9; x < WALL.x + WALL.w - 4; x += 18) heads.push(k.segment([x, FACE_Y, WALL_Z0], [x, FACE_Y, WALL_Z0 + 9], P));
    inner = L(courses.join(""), { tone: "faint" }) + L(heads.join(""), { tone: "faint" });
  }
  out.push(S(k.slabOf(WALL, WALL_Z0, WALL_Z1 - WALL_Z0, P, 3, 0.6), { tone: "mid", inner }));
  if (brick) {
    // A coping stone along the top.
    out.push(S(k.slabOf({ x: WALL.x - 2, y: WALL.y - 2, w: WALL.w + 4, d: WALL.d + 4, r: 1 }, WALL_Z1, 4, P, 3, 0.5), { tone: "mid" }));
  } else {
    out.push(L(faceRect(WALL.x + 4, WALL.x + WALL.w - 4, FACE_Y, WALL_Z0 + 4, WALL_Z1 - 4), { tone: "faint" }));
    out.push(D([[WALL.x + 7, WALL_Z0 + 7], [WALL.x + WALL.w - 7, WALL_Z0 + 7], [WALL.x + 7, WALL_Z1 - 7], [WALL.x + WALL.w - 7, WALL_Z1 - 7]].map(([x, z]) => at([x, FACE_Y, z])), { size: 0.6 }));
  }
  return out.join("");
}

const PANEL_SOCKET = { x: -222, z: 22 };
function panel() {
  const out = [backPlate(false)];
  const y = FACE_Y;
  // DIN rail with its end clips, and the group on it.
  out.push(S(k.slabOf({ x: WALL.x + 8, y, w: WALL.w - 16, d: 3, r: 0.4 }, 96, 7, P, 2), { tone: "lo", crease: "none" }));
  for (const x of [WALL.x + 9, WALL.x + WALL.w - 13]) out.push(S(k.slabOf({ x, y, w: 4, d: 5, r: 0.6 }, 94, 11, P, 2), { tone: "mid" }));
  // Installatieautomaat B16: body, toggle, the engraved rating.
  const mcb = { x: WALL.x + 18, y, w: 16, d: 13, r: 1.2 };
  out.push(S(k.slabOf(mcb, 84, 30, P, 3, 0.6), { tone: "hi", inner: L(k.sideSeam(mcb, 99, P, 3), { tone: "faint" }) }));
  out.push(S(k.slabOf({ x: mcb.x + 5, y: y + 13, w: 6, d: 4, r: 0.8 }, 101, 7, P, 2), { tone: "hi" }));
  out.push(L(engraved("B16", mcb.x + 2.4, y + 13, 88, 6.5), { tone: "mid", free: true }));
  // Aardlekschakelaar with its test button.
  const rcd = { x: WALL.x + 38, y, w: 28, d: 13, r: 1.2 };
  out.push(S(k.slabOf(rcd, 84, 30, P, 3, 0.6), { tone: "hi", inner: L(k.sideSeam(rcd, 99, P, 3), { tone: "faint" }) }));
  out.push(S(k.slabOf({ x: rcd.x + 4, y: y + 13, w: 6, d: 4, r: 0.8 }, 101, 7, P, 2), { tone: "hi" }));
  out.push(S(k.cylinder(rcd.x + 20, y + 14.5, 2.2, 104, 3, P, 16), { tone: "mid" }));
  // Busbar between them.
  out.push(L(faceLine(mcb.x + 3, rcd.x + rcd.w - 3, y + 13, 86), { tone: "faint" }));
  // The wall socket the reel's lead plugs into.
  const socket = { x: PANEL_SOCKET.x - 8, y, w: 18, d: 5, r: 1.5 };
  out.push(S(k.slabOf(socket, PANEL_SOCKET.z - 9, 18, P, 4, 0.5), { tone: "hi" }));
  out.push(L(k.sideRing([PANEL_SOCKET.x + 1, y + 5, PANEL_SOCKET.z], 5.5, "y", P, 24), { tone: "lo" }));
  // Cable gland at the bottom of the panel.
  out.push(S(k.cylinder(WALL.x + WALL.w - 30, y + 3, 3.4, WALL_Z0, 10, P, 18), { tone: "mid" }));
  out.push(L(k.sideArc(WALL.x + WALL.w - 30, y + 3, 3.4, WALL_Z0 + 6, P, 12), { tone: "faint" }));
  return out.join("");
}

const KWH = { x: WALL.x + 70, y: FACE_Y, w: 36, d: 11, r: 2 };
function kwhMeter() {
  const out = [];
  const y = FACE_Y + KWH.d;
  out.push(S(k.slabOf(KWH, 26, 50, P, 4, 0.8), { tone: "hi", inner: L(k.sideSeam(KWH, 36, P, 4), { tone: "faint" }) }));
  // The LCD window (it shows no number here; the reveal and the tang do).
  out.push(L(faceRect(KWH.x + 6, KWH.x + KWH.w - 6, y, 56, 68), { tone: "mid" }));
  out.push(L(faceLine(KWH.x + 6, KWH.x + KWH.w - 6, y, 50), { tone: "faint" }));
  out.push(D([at([KWH.x + 5, y, 30]), at([KWH.x + KWH.w - 5, y, 30])], { size: 0.5 }));
  // The pulse LED sits high on the meter, above the reels (Godot draws it over every layer).
  extras.leds.push({ id: "kwh_pulse", skin: "meterkast", at: at([KWH.x + KWH.w - 9, y, 72]) });
  out.push(L(k.sideRing([KWH.x + KWH.w - 9, y, 72], 2, "y", P, 16), { tone: "lo" }));
  return out.join("");
}

const TAP = { x: WALL.x + 30, z: 64 };
function wallTap() {
  const out = [backPlate(true)];
  // The rosette on the wall, the tap body out of it, the spout down to the coupling.
  const F = G.frameAlong([TAP.x, FACE_Y, TAP.z], AY);
  out.push(S(G.disc(0, 2, 8, F, P), { tone: "mid" }));
  out.push(S(G.solidOf([[2, 5], [9, 5], [10, 6.5, 1], [15, 6.5, 1], [16, 5]], F, P), { tone: "hi" }));
  out.push(L(G.arcOf(F, 9.5, 6, P), { tone: "faint" }));
  const spout = G.frameAlong([TAP.x, FACE_Y + 12, TAP.z - 5], [0, 0, -1]);
  out.push(S(G.solidOf([[0, 4], [10, 3.6], [13, 4.2]], spout, P), { tone: "hi" }));
  out.push(S(G.disc(13, 19, 5.2, spout, P), { tone: "mid" }));
  out.push(k.fadedSvg(G.ribsOf(spout, 13.4, 18.6, 5.2, 22, P, { fade: [0.05, 0.4] }), { tone: "lo" }));
  // The handle: a stem and a lever across (closed? the tap is always open).
  out.push(S(k.cylinder(TAP.x, FACE_Y + 9, 2, TAP.z + 6, 5, P, 14), { tone: "mid" }));
  out.push(S(k.slabOf({ x: TAP.x - 2, y: FACE_Y + 9 - 9, w: 4, d: 18, r: 1.5 }, TAP.z + 11, 3, P, 3, 0.4), { tone: "hi" }));
  out.push(D([at([TAP.x, FACE_Y + 9, TAP.z + 14])], { size: 0.6, tone: "hi" }));
  return out.join("");
}

// A dial gauge with its face up: case, bezel, ticks; the needle is Godot's.
function gaugeUp(id, skin, cx, cy, z, r, { stem = 0, needle = {} } = {}) {
  const out = [];
  if (stem) out.push(S(k.cylinder(cx, cy, 2.2, z - stem, stem, P, 14), { tone: "mid" }));
  out.push(S(k.cylinder(cx, cy, r, z, 4, P, 48, 0.6), { tone: "hi", crease: "lo" }));
  out.push(L(k.ring(cx, cy, r - 1.6, z + 4, P, 48), { tone: "lo" }));
  const ticks = k.radialTicks(cx, cy, r - 2.2, 24, 4, z + 4, [1, 2.2], P, -Math.PI * 0.75, Math.PI * 1.5);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  out.push(D([at([cx, cy, z + 4])], { size: 0.8, tone: "hi" }));
  extras.needles.push({ id, skin, length: r - 3.6, tail: 2, ...planeAt([cx, cy, z + 4.2], AX, AY), ...needle });
  return out.join("");
}

function tapGauge() {
  // On a short riser off the wall, beside the tap: it reads the push at the source.
  const out = [];
  const x = TAP.x + 30;
  const F = G.frameAlong([x, FACE_Y, 70], AY);
  out.push(S(G.disc(0, 9, 2, F, P), { tone: "mid" }));
  out.push(S(k.cylinder(x, FACE_Y + 10, 2.4, 63, 9, P, 14), { tone: "mid" }));
  out.push(gaugeUp("tap_gauge_needle", "tuin", x, FACE_Y + 10, 72, 10, { needle: { from: -0.75, to: 0.75, fixed: 0.45 } }));
  return out.join("");
}

// ── The reels: shared frames, wound with hose or cable ──────────────────────
function reelFrame(c, half) {
  // half: "back" (the base, the far post and flange, the core) or "front".
  const out = [];
  const F = G.frameAlong([c.x, c.y - HALF - FLANGE_T, HUB_Z], AY);
  const post = (y) => ({ x: c.x - 3.5, y, w: 7, d: 3.4, r: 0.8 });
  if (half === "back") {
    const base = { x: c.x - 26, y: c.y - HALF - 9, w: 52, d: 2 * HALF + 18, r: 3 };
    out.push(`<path class="iso-halo" d="${k.haloOf(base, 0, 3, P)}"/>`);
    out.push(S(k.slabOf(base, 0, 4, P, 4, 0.6), { tone: "lo" }));
    for (const [dx, dy] of [[-21, -HALF - 5], [21, -HALF - 5], [-21, HALF + 5], [21, HALF + 5]]) out.push(D([at([c.x + dx, c.y + dy, 4])], { size: 0.5 }));
    out.push(S(k.slabOf(post(c.y - HALF - FLANGE_T - 4), 4, HUB_Z - 4, P, 2, 0.4), { tone: "mid" }));
    out.push(S(G.disc(-4, -2, 4.4, F, P), { tone: "mid" }));
    out.push(S(G.disc(0, FLANGE_T, FLANGE_R, F, P, { steps: 96 }), { tone: "mid", inner: L(G.arcOf(F, FLANGE_T, FLANGE_R - 3, P, { inward: true }), { tone: "faint" }) }));
    out.push(S(G.disc(FLANGE_T, FLANGE_T + 2 * HALF, CORE_R, F, P), { tone: "lo" }));
  } else {
    const s0 = FLANGE_T + 2 * HALF;
    out.push(S(G.disc(s0, s0 + FLANGE_T, FLANGE_R, F, P, { steps: 96 }), { tone: "mid" }));
    out.push(L(G.circleOf(F, s0 + FLANGE_T, FLANGE_R - 3.5, P), { tone: "faint" }));
    out.push(L(G.spokesOf(F, s0 + FLANGE_T, 7, FLANGE_R - 3.5, 5, P, { phase: 0.3 }), { tone: "faint" }));
    out.push(S(k.slabOf(post(c.y + HALF + FLANGE_T + 0.6), 4, HUB_Z - 4, P, 2, 0.4), { tone: "mid" }));
    const hub = s0 + FLANGE_T + 4;
    out.push(S(G.disc(s0 + FLANGE_T, hub + 1, 5, F, P), { tone: "mid" }));
    out.push(D([at(G.pointOf(F, hub + 1, 0, 0))], { size: 0.7, tone: "hi" }));
    // The crank: an arm to the rim, a knurled handle sticking out.
    const tip = [c.x + 18, c.y + HALF + FLANGE_T + 4.4, HUB_Z - 14];
    const armF = G.frameAlong([c.x, tip[1] + 1, HUB_Z], G.unit3([18, 0, -14]));
    out.push(S(G.prismOf(armF, [[-1.6, -2.4], [1.6, -2.4], [1.6, 2.4], [-1.6, 2.4]], 0, Math.hypot(18, 14) + 2, P), { tone: "mid" }));
    const handle = G.frameAlong(tip, AY);
    out.push(S(G.disc(1.6, 12, 2.6, handle, P), { tone: "hi" }));
    out.push(k.fadedSvg(G.ribsOf(handle, 2.4, 11.4, 2.6, 18, P, { fade: [0.05, 0.4] }), { tone: "lo" }));
  }
  return out.join("");
}

// The windings on a drum: rolled full, or the few left when it is unrolled.
function windings(c, wound, kind) {
  const F = G.frameAlong([c.x, c.y - HALF - FLANGE_T, HUB_Z], AY);
  const r = WOUND[wound];
  const thick = kind === "thick";
  const out = [S(G.disc(FLANGE_T, FLANGE_T + 2 * HALF, r, F, P), { tone: "hi", lit: true })];
  const pitch = thick ? 4 : 3;
  const rings = [];
  for (let s = FLANGE_T + pitch; s < FLANGE_T + 2 * HALF - 0.5; s += pitch) rings.push(G.arcOf(F, s, r, P));
  out.push(L(rings.join(""), { tone: "lo" }));
  return out.join("");
}

// The routes: from the drum's winding to the power strip along the ruler.
// The route lies on the bench (z = its radius) from the drum to the strip's strain relief.
function routeOf(kind, r) {
  const c = kind === "thin" ? REEL1 : REEL2;
  const bend = kind === "thin" ? 40 : 50;
  return G.fillet([[c.x + 8, c.y, HUB_Z - WOUND.unrolled + 2], [c.x + 26, c.y, r], [c.x + bend, ROUTE_Y, r], [STRIP.x - 7, ROUTE_Y, r]], 16, 9);
}

function routeSvg(kind, radius, { hue = "", silhouette = false } = {}) {
  const pieces = tubePieces(routeOf(kind, radius), radius, P, { maxLength: 400, caps: [false, true] });
  if (silhouette) return pieces.map((piece) => `<path class="heat" d="${piece.body}"/>`).join("");
  const body = pieces.map((piece) => tubeSvg(piece, { tone: "hi" })).join("");
  return hue ? `<g data-hue="${hue}">${body}</g>` : `<g class="iso-solid" data-lit="">${body}</g>`;
}

// The lead from the source to the reel's inlet box (on the reel's base, at the back).
function inletBox(c) {
  return { x: c.x - 24, y: c.y - HALF - 8, w: 9, d: 7, r: 1 };
}
function lead(c, kind, hue) {
  const box = inletBox(c);
  const top = [box.x + 4.5, box.y + 3.5, 10];
  const from = kind === "tuin" ? [TAP.x, FACE_Y + 12, TAP.z - 24] : [PANEL_SOCKET.x + 1, FACE_Y + 12, PANEL_SOCKET.z];
  const r = kind === "tuin" ? 2.2 : 1.6;
  const pts = kind === "tuin"
    ? [from, [from[0], from[1], 14], [from[0] + 2, from[1] + 6, r], [top[0], from[1] + 6, r], [top[0], top[1], r + 1], [top[0], top[1], top[2]]]
    : [from, [from[0], from[1] + 6, from[2] - 4], [from[0], from[1] + 8, r], [top[0], from[1] + 8, r], [top[0], top[1], r + 1], [top[0], top[1], top[2]]];
  const route = G.fillet(pts, 6, 7);
  const pieces = tubePieces(route, r, P, { maxLength: 400 });
  const body = pieces.map((piece) => tubeSvg(piece, { tone: "mid" })).join("");
  const out = [hue ? `<g data-hue="${hue}">${body}</g>` : body];
  if (kind !== "tuin") {
    // The plug in the wall socket.
    out.push(S(G.disc(0, 7, 4.6, G.frameAlong([from[0], FACE_Y + 5, from[2]], AY), P), { tone: "hi" }));
  }
  return out.join("");
}
function inletSvg(c) {
  const box = inletBox(c);
  return S(k.slabOf(box, 4, 6, P, 2, 0.4), { tone: "mid" }) + L(k.ring(box.x + 4.5, box.y + 3.5, 2, 10, P, 12), { tone: "lo" });
}

// ── The power strip or the manifold ─────────────────────────────────────────
function stekkerdoos() {
  const out = [`<path class="iso-halo" d="${k.haloOf(STRIP, 0, STRIP_H, P)}"/>`];
  // Strain relief where the cable enters.
  const relief = G.frameAlong([STRIP.x - 7, ROUTE_Y, WIRE.thick + 1], AX);
  out.push(S(G.solidOf([[0, 2.6], [5, 3.6], [7, 4.4]], relief, P), { tone: "mid" }));
  out.push(S(k.slabOf(STRIP, 0, STRIP_H, P, 4, 0.8), { tone: "hi", inner: L(k.sideSeam(STRIP, 4, P, 4), { tone: "faint" }) }));
  for (const id of ["lamp", "kettle", "heater"]) {
    const x = SOCKET_X[id];
    out.push(L(k.ring(x, STRIP.y + 11, 6.2, STRIP_H, P, 32), { tone: "mid" }));
    out.push(D([at([x - 2.4, STRIP.y + 11, STRIP_H]), at([x + 2.4, STRIP.y + 11, STRIP_H])], { size: 0.7, tone: "hi" }));
  }
  out.push(D([at([STRIP.x + 4, STRIP.y + 4, STRIP_H]), at([STRIP.x + STRIP.w - 4, STRIP.y + STRIP.d - 4, STRIP_H])], { size: 0.5 }));
  return out.join("");
}

// A rocker switch on the strip's front face, beside its socket.
function rocker(id, on) {
  const x = SOCKET_X[id];
  const y = STRIP.y + STRIP.d;
  const out = [S(k.slabOf({ x: x - 4, y, w: 8, d: 1.2, r: 0.3 }, 3.5, 7, P, 2), { tone: "mid" })];
  // The rocker leans: its pressed end sits in, the other proud.
  const pressed = on ? [x - 3.2, x] : [x, x + 3.2];
  const proud = on ? [x, x + 3.2] : [x - 3.2, x];
  out.push(S(k.slabOf({ x: pressed[0], y: y + 1.2, w: 3.2, d: 0.8, r: 0.2 }, 4.3, 5.4, P, 2), { tone: "hi" }));
  out.push(S(k.slabOf({ x: proud[0], y: y + 1.2, w: 3.2, d: 2.6, r: 0.3 }, 4.3, 5.4, P, 2), { tone: on ? "hi" : "mid", lit: on }));
  if (on) out.push(L(k.segment([x + 1.6, y + 3.8, 6], [x + 1.6, y + 3.8, 8.2], P), { tone: "lit" }));
  extras.hits.push({ id: `switch_${id}`, control: id, skin: "meterkast", rect: rectOf([[x - 6, y - 4, 0], [x + 6, y + 6, 14]]) });
  return out.join("");
}

const MANIFOLD_Z = 9;
function verdeelstuk() {
  const out = [`<path class="iso-halo" d="${k.haloOf(STRIP, 0, 6, P)}"/>`];
  // Two saddle feet, the brass body along x, the inlet clamp, three outlets.
  for (const x of [STRIP.x + 8, STRIP.x + STRIP.w - 12]) out.push(S(k.slabOf({ x, y: ROUTE_Y - 6, w: 5, d: 12, r: 1 }, 0, MANIFOLD_Z - 3, P, 2, 0.4), { tone: "lo" }));
  const F = G.frameAlong([STRIP.x - 7, ROUTE_Y, MANIFOLD_Z], AX);
  out.push(S(G.solidOf([[0, 3.6], [4, 4.6], [7, 4.6]], F, P), { tone: "mid" }));
  out.push(S(G.disc(1, 4, 5.4, F, P), { tone: "mid" }));
  out.push(S(G.solidOf([[7, 5.4], [8.6, 6.4, 1], [STRIP.w + 2, 6.4, 1], [STRIP.w + 3.6, 5.4]], F, P), { tone: "hi" }));
  out.push(L(G.arcOf(F, 12, 6.4, P) + G.arcOf(F, STRIP.w - 2, 6.4, P), { tone: "faint" }));
  for (const id of ["lamp", "kettle", "heater"]) {
    const x = SOCKET_X[id];
    out.push(S(k.cylinder(x, ROUTE_Y, 3, MANIFOLD_Z + 5, 9, P, 18), { tone: "hi" }));
    out.push(L(k.sideArc(x, ROUTE_Y, 3, MANIFOLD_Z + 9, P, 12), { tone: "faint" }));
  }
  return out.join("");
}

// A garden valve: a lever across the flow is shut, along it is open.
function kraantje(id, open) {
  const x = SOCKET_X[id];
  const z = MANIFOLD_Z + 14;
  const out = [S(k.cylinder(x, ROUTE_Y, 3.8, z, 3, P, 20), { tone: "mid" })];
  out.push(S(k.cylinder(x, ROUTE_Y, 1.4, z + 3, 3, P, 12), { tone: "mid" }));
  const lever = open ? { x: x - 1.6, y: ROUTE_Y - 2, w: 14, d: 4, r: 1.6 } : { x: x - 2, y: ROUTE_Y - 1.6, w: 4, d: 14, r: 1.6 };
  out.push(S(k.slabOf(lever, z + 6, 2.4, P, 3, 0.4), { tone: "hi", lit: open }));
  out.push(D([at([x, ROUTE_Y, z + 8.4])], { size: 0.6, tone: "hi" }));
  extras.hits.push({ id: `tap_${id}`, control: id, skin: "tuin", rect: rectOf([[x - 8, ROUTE_Y - 8, z - 2], [x + 14, ROUTE_Y + 14, z + 10]]) });
  return out.join("");
}

// ── Appliances, or the things that use water ────────────────────────────────
function cordTo(id, from, hue) {
  // A cord or a thin hose from the load to its socket or outlet.
  const x = SOCKET_X[id];
  const mid = [x, STRIP.y - 10, 1.6];
  // A hose leaves its outlet stub at the back; a cord ends on its plug on top of the strip.
  const tail = hue
    ? [[x, STRIP.y - 4, 1.6], [x, ROUTE_Y - 9, MANIFOLD_Z + 9], [x, ROUTE_Y - 3, MANIFOLD_Z + 9]]
    : [[x, STRIP.y - 1, 1.6], [x, STRIP.y + 6, STRIP_H + 8], [x, STRIP.y + 11, STRIP_H + 2]];
  const pts = G.fillet([from, [from[0], from[1] + 8, 1.6], [x, from[1] + 12, 1.6], mid, ...tail], 5, 6);
  const pieces = tubePieces(pts, hue ? 1.5 : 1.1, P, { maxLength: 400 });
  const body = pieces.map((piece) => tubeSvg(piece, { tone: "mid" })).join("");
  const plug = hue ? "" : S(k.cylinder(x, STRIP.y + 11, 4.4, STRIP_H, 3.4, P, 24), { tone: "hi" });
  return plug + (hue ? `<g data-hue="${hue}">${body}</g>` : body);
}

function appliances() {
  const out = [];
  // LED lamp: a round foot, a stem, a shade, the bulb.
  const l = [LOAD_X.lamp, LOAD_Y.lamp];
  out.push(S(k.cylinder(l[0], l[1], 9, 0, 3, P, 32, 0.5), { tone: "mid" }));
  out.push(S(k.cylinder(l[0], l[1], 1.4, 3, 26, P, 12), { tone: "mid" }));
  const shade = G.frameAlong([l[0], l[1], 26], AZ);
  out.push(S(G.solidOf([[0, 10], [9, 5.4]], shade, P, { rims: "first" }), { tone: "hi" }));
  out.push(S(G.disc(9, 10.5, 2, shade, P), { tone: "mid" }));
  // Waterkoker: base plate, body, lid, handle, water window, its switch.
  const w = [LOAD_X.kettle, LOAD_Y.kettle];
  out.push(S(k.cylinder(w[0], w[1], 12, 0, 3, P, 40, 0.5), { tone: "mid" }));
  const kettle = G.frameAlong([w[0], w[1], 3], AZ);
  out.push(S(G.solidOf([[0, 10.5], [24, 9, 1], [28, 7.6]], kettle, P), { tone: "hi", inner: L(G.arcOf(kettle, 4, 10.3, P), { tone: "faint" }) }));
  out.push(S(G.disc(28, 30, 6.6, kettle, P), { tone: "mid" }));
  out.push(S(k.cylinder(w[0], w[1], 1.8, 33, 2, P, 12), { tone: "mid" }));
  out.push(S(k.slabOf({ x: w[0] - 15, y: w[1] - 2, w: 5, d: 4, r: 1.5 }, 6, 22, P, 3, 0.4), { tone: "mid" }));
  out.push(S(k.slabOf({ x: w[0] - 13, y: w[1] - 2, w: 4, d: 4, r: 1 }, 24, 4, P, 2), { tone: "mid" }));
  out.push(L(k.segment([w[0] + 7.4, w[1] + 7.4, 8], [w[0] + 7.4, w[1] + 7.4, 22], P), { tone: "lo" }));
  out.push(L(k.segment([w[0] + 6.3, w[1] + 8.4, 8], [w[0] + 6.3, w[1] + 8.4, 22], P), { tone: "lo" }));
  // Elektrische kachel: housing on two feet, grille bars on its front, a knob.
  const h = { x: LOAD_X.heater - 16, y: LOAD_Y.heater - 7, w: 32, d: 14, r: 2.5 };
  for (const x of [h.x + 3, h.x + h.w - 9]) out.push(S(k.slabOf({ x, y: h.y - 4, w: 6, d: h.d + 8, r: 2 }, 0, 3, P, 3, 0.4), { tone: "lo" }));
  const bars = [];
  for (let x = h.x + 5; x <= h.x + h.w - 9; x += 3) bars.push(k.segment([x, h.y + h.d, 9], [x, h.y + h.d, 28], P));
  out.push(S(k.slabOf(h, 3, 30, P, 4, 0.8), { tone: "hi", inner: L(faceRect(h.x + 3.5, h.x + h.w - 7, h.y + h.d, 7, 30), { tone: "lo" }) + L(bars.join(""), { tone: "lo" }) }));
  out.push(S(G.disc(0, 2, 2.6, G.frameAlong([h.x + h.w - 3.6, h.y + h.d, 26], AY), P), { tone: "mid" }));
  out.push(cordTo("lamp", [l[0] + 6, l[1] + 4, 1.6]));
  out.push(cordTo("kettle", [w[0] + 6, w[1] + 9, 1.6]));
  out.push(cordTo("heater", [h.x + 10, h.y + h.d + 1, 1.6]));
  return out.join("");
}

function outlets() {
  const out = [];
  const GREEN = "green";
  // Druppelaar on a stick.
  const d = [LOAD_X.lamp, LOAD_Y.lamp];
  out.push(S(k.cylinder(d[0], d[1], 1.4, 0, 22, P, 12), { tone: "mid" }));
  out.push(S(G.solidOf([[0, 3.4], [5, 2.4], [7, 1.2]], G.frameAlong([d[0], d[1], 22], AZ), P), { tone: "hi" }));
  // Grote sproeier on a spike.
  const b = [LOAD_X.kettle, LOAD_Y.kettle];
  out.push(S(k.cylinder(b[0], b[1], 1.8, 0, 20, P, 12), { tone: "mid" }));
  const head = G.frameAlong([b[0], b[1], 20], AZ);
  out.push(S(G.solidOf([[0, 4], [3, 8.6, 1], [6, 8.6, 1], [7.4, 6]], head, P), { tone: "hi" }));
  out.push(D(G.dotsOf(head, 7.4, 4.4, 14, P, { all: true }), { size: 0.55, tone: "hi" }));
  // Tuinsproeier: a base sled, a riser, a rotating arm with two nozzles.
  const s = [LOAD_X.heater, LOAD_Y.heater];
  out.push(S(k.slabOf({ x: s[0] - 12, y: s[1] - 6, w: 24, d: 12, r: 5 }, 0, 4, P, 6, 0.5), { tone: "mid" }));
  out.push(S(k.cylinder(s[0], s[1], 2.6, 4, 16, P, 16), { tone: "mid" }));
  out.push(S(k.slabOf({ x: s[0] - 13, y: s[1] - 1.8, w: 26, d: 3.6, r: 1.6 }, 20, 3, P, 3, 0.4), { tone: "hi" }));
  for (const x of [s[0] - 12, s[0] + 9]) out.push(S(k.cylinder(x + 1.5, s[1], 1.6, 23, 3, P, 12), { tone: "hi" }));
  out.push(cordTo("lamp", [d[0] + 2, d[1] + 2, 1.6], GREEN));
  out.push(cordTo("kettle", [b[0] + 2, b[1] + 2, 1.6], GREEN));
  out.push(cordTo("heater", [s[0] + 2, s[1] + 6, 1.6], GREEN));
  return out.join("");
}

// Spray: arcs of drops above each outlet, in three densities by flow.
function spray(id, level) {
  const [x, y] = [LOAD_X[id], LOAD_Y[id]];
  const top = { lamp: 29, kettle: 27.4, heater: 26 }[id];
  const reach = { lamp: [0.7, 1.2, 1.6], kettle: [9, 15, 22], heater: [10, 16, 22] }[id][level - 1];
  const count = { lamp: [2, 3, 4], kettle: [10, 16, 22], heater: [8, 12, 16] }[id][level - 1];
  const drops = [];
  for (let i = 0; i < count; i++) {
    const angle = (i / count) * Math.PI * 2 + 0.3;
    for (let t = 0.2; t <= 1.0001; t += 0.2) {
      const rr = reach * t;
      const z = top + (id === "lamp" ? -6 * t : 10 * t * (1.2 - t) * (reach / 12)) ;
      drops.push([x + Math.cos(angle) * rr, y + Math.sin(angle) * rr, Math.max(1, z), 1 - t * 0.6]);
    }
  }
  return D(byDepth(drops).map((p) => [...at(p), p[3]]), { size: 1.1, tone: "hi" });
}

// ── Instruments ─────────────────────────────────────────────────────────────
function rectOf(points) {
  const box = k.boxCorners({ x: points[0][0], y: points[0][1], w: points[1][0] - points[0][0], d: points[1][1] - points[0][1] }, points[0][2], points[1][2]).map(at);
  const xs = box.map((p) => p[0]);
  const ys = box.map((p) => p[1]);
  return [Math.min(...xs), Math.min(...ys), Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys)];
}

// A clamp around the route at CLAMP_X: a ring in the y–z plane, split into its far and near halves.
function clampRing(r, half, tone) {
  const F = G.frameOf([CLAMP_X, ROUTE_Y, r], AX, AY, AZ);
  // The jaws stand on the bench: the ring is cut where it would go through it.
  const pts = G.arcPoints(F, 0, r + 5, 0, Math.PI * 2, 72);
  const V = G.viewOf(P);
  const facing = (p) => G.dot3(G.sub3(p, [CLAMP_X, ROUTE_Y, r]), V);
  const flags = pts.map((p) => p[2] >= 2.6 && (half === "back" ? facing(p) <= 0.5 : facing(p) >= -0.5));
  // Rotate the kept arc so it is one run.
  const start = flags.findIndex((f, i) => f && !flags[(i + pts.length - 1) % pts.length]);
  const run = [];
  for (let i = 0; i < pts.length; i++) {
    const p = pts[(start + i) % pts.length];
    if (!flags[(start + i) % pts.length]) break;
    run.push(p);
  }
  const pieces = tubePieces(run, 2.4, P, { maxLength: 400 });
  return pieces.map((piece) => tubeSvg(piece, { tone })).join("");
}

function stroomtang() {
  const out = [clampRing(WIRE.thick, "front", "hi")];
  // The body lies on the bench behind the cable, its jaws up round it.
  const body = { x: CLAMP_X - 11, y: 4, w: 22, d: 30, r: 3 };
  out.push(`<path class="iso-halo" d="${k.haloOf(body, 0, 5, P)}"/>`);
  out.push(S(k.slabOf(body, 0, 7, P, 4, 0.8), { tone: "hi", inner: L(k.sideSeam(body, 3, P, 4), { tone: "faint" }) }));
  const lcd = { x: body.x + 3, y: body.y + 3, w: 16, d: 11, r: 0.6 };
  out.push(S(k.slabOf(lcd, 7, 0.3, P, 2), { tone: "lo", crease: "none" }));
  lcdOnTop("stroomtang", "meterkast", lcd, 7.3);
  out.push(S(k.cylinder(body.x + 11, body.y + 21, 4.2, 7, 2.4, P, 28), { tone: "mid" }));
  out.push(L(k.knurl(body.x + 11, body.y + 21, 4.2, 7, 9.4, 24, P), { tone: "lo" }));
  out.push(L(k.lineOnTop([body.x + 11, body.y + 21], [body.x + 14.4, body.y + 19], 9.4, P), { tone: "hi" }));
  // The jaw arm from the body up to the ring.
  out.push(S(k.slabOf({ x: CLAMP_X - 3, y: body.y + body.d - 1, w: 6, d: ROUTE_Y - 8 - body.y - body.d + 1, r: 1 }, 0, 5, P, 2, 0.4), { tone: "hi" }));
  return out.join("");
}

function flowmeter() {
  const out = [clampRing(HOSE.thick, "front", "mid")];
  // A housing behind the hose, a glass window on top with the paddle wheel under it.
  const body = { x: CLAMP_X - 11, y: 6, w: 22, d: 28, r: 4 };
  out.push(`<path class="iso-halo" d="${k.haloOf(body, 0, 5, P)}"/>`);
  out.push(S(k.slabOf(body, 0, 9, P, 5, 0.8), { tone: "hi", inner: L(k.sideSeam(body, 4, P, 5), { tone: "faint" }) }));
  const c = [CLAMP_X, body.y + 13];
  out.push(S(k.cylinder(c[0], c[1], 8, 9, 1.6, P, 40, 0.4), { tone: "mid" }));
  out.push(L(k.ring(c[0], c[1], 6.6, 10.6, P, 40), { tone: "lo" }));
  extras.wheels.push({ id: "flowmeter_wheel", skin: "tuin", r: 5.8, blades: 6, ...planeAt([c[0], c[1], 10.7], AX, AY) });
  out.push(D([[body.x + 3, body.y + 3], [body.x + body.w - 3, body.y + 3], [body.x + 3, body.y + body.d - 3], [body.x + body.w - 3, body.y + body.d - 3]].map(([x, y]) => at([x, y, 9])), { size: 0.5 }));
  out.push(S(k.slabOf({ x: CLAMP_X - 3.5, y: body.y + body.d - 1, w: 7, d: ROUTE_Y - 10 - body.y - body.d + 1, r: 1 }, 0, 6, P, 2, 0.4), { tone: "mid" }));
  return out.join("");
}

function thermometer() {
  // Taped to the cable: a band over it, a probe, a small box with its LCD.
  const out = [];
  const F = G.frameAlong([THERMO_X - 3, ROUTE_Y, WIRE.thick], AX);
  out.push(S(G.ringBand(0, 6, WIRE.thick, WIRE.thick + 1.2, F, P), { tone: "mid" }));
  const box = { x: THERMO_X - 9, y: ROUTE_Y - 28, w: 18, d: 16, r: 2.5 };
  out.push(`<path class="iso-halo" d="${k.haloOf(box, 0, 4, P)}"/>`);
  out.push(S(k.slabOf(box, 0, 6, P, 4, 0.6), { tone: "hi" }));
  const lcd = { x: box.x + 2.5, y: box.y + 2.5, w: 13, d: 8, r: 0.5 };
  out.push(S(k.slabOf(lcd, 6, 0.3, P, 2), { tone: "lo", crease: "none" }));
  lcdOnTop("thermometer", "meterkast", lcd, 6.3);
  const lead = G.fillet([[THERMO_X, box.y + box.d, 2], [THERMO_X, ROUTE_Y - 8, 1.2], [THERMO_X, ROUTE_Y - WIRE.thick - 1, WIRE.thick]], 3, 5);
  out.push(tubePieces(lead, 0.7, P, { maxLength: 400 }).map((piece) => tubeSvg(piece, { tone: "mid" })).join(""));
  return out.join("");
}

function multimeter() {
  const out = [];
  const m = METER;
  out.push(`<path class="iso-halo" d="${k.haloOf(m, 0, 6, P)}"/>`);
  out.push(S(k.slabOf(k.insetPlan(m, -1.4), 0, 9, P, 5, 0.6), { tone: "lo" }));
  out.push(S(k.slabOf(m, 0.5, 10, P, 4, 0.8), { tone: "hi" }));
  const lcd = { x: m.x + 4, y: m.y + 4, w: 22, d: 12, r: 0.8 };
  out.push(S(k.slabOf(lcd, 10.5, 0.3, P, 2), { tone: "lo", crease: "none" }));
  lcdOnTop("multimeter", "meterkast", lcd, 10.8);
  const knob = [m.x + 15, m.y + 27];
  out.push(L(k.ring(knob[0], knob[1], 8, 10.5, P, 40), { tone: "faint" }));
  out.push(S(k.cylinder(knob[0], knob[1], 6, 10.5, 3, P, 32), { tone: "mid" }));
  out.push(L(k.knurl(knob[0], knob[1], 6, 10.5, 13.5, 30, P), { tone: "lo" }));
  out.push(L(k.lineOnTop([knob[0], knob[1]], [knob[0] - 4.2, knob[1] - 4.2], 13.5, P), { tone: "hi" }));
  for (const [i, x] of [[0, m.x + 7], [1, m.x + 23]]) {
    out.push(L(k.ring(x, m.y + 39, 1.8, 10.5, P, 16), { tone: "mid" }));
    // Probe leads from the jacks to the strip's last socket.
    const to = [SOCKET_X.heater + (i ? 2.4 : -2.4), STRIP.y + 11, STRIP_H + 0.4];
    const pts = G.fillet([[x, m.y + 39, 10.6], [x, m.y + 39, 18 + i * 3], [to[0] + 6 + i * 3, to[1] + 4, STRIP_H + 12 + i * 3], to], 5, 6);
    out.push(tubePieces(pts, 0.8, P, { maxLength: 400 }).map((piece) => tubeSvg(piece, { tone: i ? "hi" : "mid" })).join(""));
  }
  return out.join("");
}

function endGauge() {
  // The end drukmeter on a riser off the manifold's far end.
  const out = [];
  const x = STRIP.x + STRIP.w + 1;
  const F = G.frameAlong([x, ROUTE_Y, MANIFOLD_Z], AX);
  out.push(S(G.disc(0, 4, 3, F, P), { tone: "mid" }));
  out.push(S(G.disc(4, 7, 4.2, F, P), { tone: "mid" }));
  out.push(gaugeUp("end_gauge_needle", "tuin", x + 8, ROUTE_Y, MANIFOLD_Z + 10, 11, { stem: 10, needle: { from: -0.75, to: 0.75 } }));
  out.push(S(k.slabOf({ x: x + 3, y: ROUTE_Y - 2.2, w: 6, d: 4.4, r: 1 }, MANIFOLD_Z - 2.2, 4.4, P, 2), { tone: "mid" }));
  return out.join("");
}

// ── Assemble every layer in painter's order ─────────────────────────────────
layer("base", "shared", bench());
layer("wall_tap", "tuin", wallTap(), { group: "source", pair: "panel" });
layer("panel", "meterkast", panel(), { group: "source", pair: "wall_tap" });
layer("tap_gauge", "tuin", tapGauge(), { group: "source", pair: "kwh_meter" });
layer("kwh_meter", "meterkast", kwhMeter(), { group: "source", pair: "tap_gauge" });

// The far halves of the clamps, under whichever route runs through them.
layer("flowmeter_back", "tuin", clampRing(HOSE.thick, "back", "mid"), { group: "meter_flow", pair: "stroomtang_back" });
layer("stroomtang_back", "meterkast", clampRing(WIRE.thick, "back", "hi"), { group: "meter_flow", pair: "flowmeter_back" });

// Reel 1 (thin) and the route that leaves it, then reel 2 (thick) and its route.
for (const [n, c, kind] of [[1, REEL1, "thin"], [2, REEL2, "thick"]]) {
  layer(`hoselead${n}`, "tuin", lead(c, "tuin", "green"), { group: "reels", pair: `cordlead${n}` });
  layer(`cordlead${n}`, "meterkast", lead(c, "meterkast", ""), { group: "reels", pair: `hoselead${n}` });
  layer(`haspel${n}_frame_back`, "shared", reelFrame(c, "back") + inletSvg(c));
  for (const wound of ["rolled", "unrolled"]) {
    layer(`hosereel${n}_${wound}`, "tuin", `<g data-hue="green">${windings(c, wound, kind)}</g>`, { group: "reels", pair: `haspel${n}_${wound}` });
    layer(`haspel${n}_${wound}`, "meterkast", windings(c, wound, kind), { group: "reels", pair: `hosereel${n}_${wound}` });
  }
  const hose = `hose_${kind}`;
  const cable = `cable_${kind}`;
  layer(hose, "tuin", routeSvg(kind, HOSE[kind], { hue: "green" }), { group: "cable", pair: cable });
  layer(cable, "meterkast", routeSvg(kind, WIRE[kind]), { group: "cable", pair: hose });
  layer(`heat_tint_hose_${kind}`, "tuin", routeSvg(kind, HOSE[kind], { silhouette: true }), { group: "cable", pair: `heat_tint_cable_${kind}`, heat: true });
  layer(`heat_tint_cable_${kind}`, "meterkast", routeSvg(kind, WIRE[kind], { silhouette: true }), { group: "cable", pair: `heat_tint_hose_${kind}`, heat: true });
  layer(`haspel${n}_frame_front`, "shared", reelFrame(c, "front"));
}
extras.hits.push({ id: "haspel1", control: "haspel", skin: "shared", rect: rectOf([[REEL1.x - 30, REEL1.y - HALF - 8, 0], [REEL1.x + 30, REEL1.y + HALF + 12, HUB_Z + FLANGE_R]]) });
extras.hits.push({ id: "haspel2", control: "haspel", skin: "shared", rect: rectOf([[REEL2.x - 30, REEL2.y - HALF - 8, 0], [REEL2.x + 30, REEL2.y + HALF + 12, HUB_Z + FLANGE_R]]) });

layer("flowmeter", "tuin", flowmeter(), { group: "meter_flow", pair: "stroomtang" });
layer("stroomtang", "meterkast", stroomtang(), { group: "meter_flow", pair: "flowmeter" });
layer("thermometer", "meterkast", thermometer(), { group: "meter_flow" });

layer("outlets", "tuin", outlets(), { group: "loads", pair: "appliances" });
layer("appliances", "meterkast", appliances(), { group: "loads", pair: "outlets" });
// Glow layers over the appliances: the kettle's switch lamp, the heater's bars.
layer("kettle_lamp_on", "meterkast", D([at([LOAD_X.kettle - 12.5, LOAD_Y.kettle + 2, 27.5])], { size: 1.4, tone: "hi" }), { group: "loads" });
layer("heater_glow", "meterkast", `<path class="heat" d="${k.pathOf([at([LOAD_X.heater - 12.5, LOAD_Y.heater + 7, 7]), at([LOAD_X.heater + 9, LOAD_Y.heater + 7, 7]), at([LOAD_X.heater + 9, LOAD_Y.heater + 7, 30]), at([LOAD_X.heater - 12.5, LOAD_Y.heater + 7, 30])], true)}"/>`, { group: "loads", heat: true });
for (const id of ["lamp", "kettle", "heater"]) {
  for (const level of [1, 2, 3]) layer(`spray_${id}_${level}`, "tuin", spray(id, level), { group: "loads" });
}

layer("verdeelstuk", "tuin", verdeelstuk(), { group: "switches", pair: "stekkerdoos" });
layer("stekkerdoos", "meterkast", stekkerdoos(), { group: "switches", pair: "verdeelstuk" });
for (const id of ["lamp", "kettle", "heater"]) {
  const t = { lamp: "dripper", kettle: "big", heater: "small" }[id];
  for (const [open, on] of [["closed", "off"], ["open", "on"]]) {
    layer(`tap_${t}_${open}`, "tuin", kraantje(id, open === "open"), { group: "switches", pair: `switch_${id}_${on}` });
    layer(`switch_${id}_${on}`, "meterkast", rocker(id, on === "on"), { group: "switches", pair: `tap_${t}_${open}` });
  }
}
layer("end_gauge", "tuin", endGauge(), { group: "meter_end", pair: "multimeter" });
layer("multimeter", "meterkast", multimeter(), { group: "meter_end", pair: "end_gauge" });

// The marker tags Ruud holds up during the cross-fade (placed in Godot).
extras.tags.push({ id: "druk", at: at([TAP.x + 40, FACE_Y + 12, TAP.z + 30]) });
extras.tags.push({ id: "stroom", at: at([CLAMP_X, 20, 40]) });
extras.tags.push({ id: "tegenhouden", at: at([THERMO_X + 20, ROUTE_Y, 30]) });

// The cross-fade group each overlay fades with (the view weighs it like a layer of that group).
const OVERLAY_GROUP = { stroomtang: "meter_flow", thermometer: "meter_flow", multimeter: "meter_end", kwh_pulse: "source", tap_gauge_needle: "source", end_gauge_needle: "meter_end", flowmeter_wheel: "meter_flow" };
for (const list of [extras.lcds, extras.needles, extras.wheels, extras.leds]) for (const o of list) o.group = OVERLAY_GROUP[o.id];
