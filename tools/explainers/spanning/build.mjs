// The design proof (anatomy step 10): every layer stacked in one SVG, both skins, the switches
// and the reel live, light theme only. `node build.mjs` writes spanning.html beside this file
// (not shipped; the game gets the per-layer SVGs from export.mjs).
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import * as k from "../kit/iso-kit.mjs";
import { HEIGHT, WIDTH, extras, layers } from "./figure.mjs";
import { whenOf } from "./visibility.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

const body = layers
  .map((l) => `<g data-layer="${l.id}" data-skin="${l.skin}"${l.heat ? ' data-heat=""' : ""}>${l.svg}</g>`)
  .join("");
const svg = k.figureSvg({
  width: WIDTH,
  height: HEIGHT,
  label: "Een werkbank met twee gedaanten: een tuinkraan, een slanghaspel en drie sproeiers, of een meterkastgroep, een kabelhaspel en drie apparaten.",
  body,
});

const PAGE_CSS = `
[data-hue="green"] .iso-fill,[data-hue="green"] .tb-body{fill:#6aa356}
[data-hue="green"] .tb-shine,[data-hue="green"] .iso-top{fill:#9ccc84}
[data-hue="green"] .tb-shade,[data-hue="green"] .iso-shade{fill:#4b7f3c}
[data-hue="green"] .iso-line{stroke:#2f5a25}
.heat{fill:#ff7a1a;stroke:none}
[data-heat]{opacity:0}
.tools{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0;font:13px ui-monospace,monospace}
.tools button{font:inherit;padding:4px 10px}
`;

// The page runs the same model module, inlined.
const MODEL = readFileSync(join(HERE, "model.mjs"), "utf8").replace(/^export /gm, "");
const live = `
${MODEL}
const WHEN = ${JSON.stringify(Object.fromEntries(layers.map((l) => [l.id, whenOf(l.id)])))};
const state = { skin: new URLSearchParams(location.search).get("skin") || "tuin", on: { lamp: false, kettle: false, heater: false }, haspel: 1 };
for (const id of (new URLSearchParams(location.search).get("on") || "").split(",").filter(Boolean)) state.on[id] = true;
if (new URLSearchParams(location.search).get("haspel") === "2") state.haspel = 2;
const level = (id, r) => { if (!state.on[id]) return 0; const i = r.u_end_v * LOADS[id] / (U_NOMINAL * U_NOMINAL); return i < 1 ? 1 : i < 5 ? 2 : 3; };
function visible(id, skin, r) {
  if (skin !== "shared" && skin !== state.skin) return false;
  const w = WHEN[id];
  if (!w) return true;
  if (w.haspel) return (state.haspel === w.haspel) === w.active;
  if (w.control) return state.on[w.control] === w.on;
  if (w.spray) return level(w.spray, r) === w.level;
  return true;
}
function draw() {
  const r = solve(state.on, state.haspel === 1 ? 1.5 : 2.5);
  for (const g of document.querySelectorAll("[data-layer]")) {
    g.style.display = visible(g.dataset.layer, g.dataset.skin, r) ? "" : "none";
    if (g.hasAttribute("data-heat")) g.style.opacity = Math.max(0, Math.min(1, (r.t_cable_c - 20) / 50)) * 0.85;
  }
  document.querySelector("[data-readout]").textContent = state.skin === "meterkast" ? r.current_a.toFixed(1) + " A · " + Math.round(r.u_end_v) + " V · " + Math.round(r.t_cable_c) + " °C" : "";
}
document.querySelector(".tools").addEventListener("click", (e) => {
  const b = e.target.closest("button"); if (!b) return;
  if (b.dataset.skin) state.skin = b.dataset.skin;
  if (b.dataset.load) state.on[b.dataset.load] = !state.on[b.dataset.load];
  if (b.dataset.haspel) state.haspel = 3 - state.haspel;
  draw();
});
draw();
`;

const tools = `<div class="tools"><button data-skin="tuin">De tuin</button><button data-skin="meterkast">De meterkast</button><button data-load="lamp">1</button><button data-load="kettle">2</button><button data-load="heater">3</button><button data-haspel="1">Haspel</button></div>`;
const plate = k.plateHtml({
  fig: "Hoe werkt het? 1",
  title: "Spanning, stroom, weerstand",
  hint: "Zet een apparaat aan",
  readout: "",
  caption: `${layers.length} layers · ${extras.lcds.length} LCDs · ${extras.needles.length} needles`,
  body: `<div class="iso-stage">${svg}</div>`,
});
const html = k.pageHtml({ title: "Spanning, stroom, weerstand", theme: "light", body: tools + plate, script: live, width: 1240 }).replace("</style>", PAGE_CSS + "</style>");
writeFileSync(join(HERE, "spanning.html"), html);
console.log("wrote spanning.html,", layers.length, "layers");
