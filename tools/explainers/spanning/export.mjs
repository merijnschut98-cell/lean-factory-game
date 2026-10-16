// Export "Hoe werkt het? 1" for Godot (spec §6.1): one SVG per layer, a manifest and the model's
// fixtures, into game/assets/explainers/spanning/.
//   node tools/explainers/spanning/export.mjs
// Godot rasterises SVG at import with ThorVG, which ignores CSS classes, variables, filters and
// <text>. So every kit class is resolved to plain fill/stroke attributes here (light theme), the
// blurred halo becomes a faint offset fill, and the one engraved label is already stroked paths.
// Each layer is cropped to its own bounds (its `rect` in the figure's viewBox), so the textures
// stay small: a full-size canvas per layer would cost ~60 × 2400×1360 px.
import { existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { HEIGHT, P, WIDTH, extras, layers } from "./figure.mjs";
import { fixtures } from "./model.mjs";
import { whenOf } from "./visibility.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = resolve(HERE, "../../../game/assets/explainers/spanning");
const PAD = 3;
const SVG_SCALE = 2.0;
const LINE = 0.9; // stroke width in viewBox units (the kit's 0.6 px is for a 650 px page)

// The light theme of ISO_CSS, as values.
const C = {
  paper: "#fbfbfa", face: "#ffffff", top: "#ffffff", litTop: "#ffffff", litShade: "#eeeeeb",
  shade: ["#dcdcd9", "#e5e5e2", "#ededea", "#f4f4f1"],
  hi: "#26262a", mid: "#8a8a8f", lo: "#b4b4b8", faint: "#d4d4d6", lit: "#000000",
  halo: "#8a8a80", dot: "#3a3a3e",
};
const GREEN = { body: "#6aa356", top: "#9ccc84", shade: "#4b7f3c", line: "#2f5a25" };
const DOT_OPACITY = { hi: 0.85, mid: 0.45, lo: 0.22, faint: 0.12 };

function attrsOf(text) {
  const out = {};
  for (const m of text.matchAll(/([\w:-]+)="([^"]*)"/g)) out[m[1]] = m[2];
  return out;
}
const has = (a, cls) => (a.class || "").split(/\s+/).includes(cls);

// Resolve one element's style from its own attributes and its ancestors'.
function styleOf(tag, a, stack) {
  const lit = stack.some((s) => has(s, "iso-solid") && "data-lit" in s);
  const seamless = stack.some((s) => has(s, "iso-solid") && "data-seamless" in s);
  const green = stack.some((s) => s["data-hue"] === "green");
  const dotTone = [...stack].reverse().find((s) => has(s, "iso-dots"))?.["data-tone"];
  const wireTone = [...stack].reverse().find((s) => has(s, "iso-wire"))?.["data-tone"];
  if (tag === "circle" && dotTone !== undefined) {
    const alpha = (DOT_OPACITY[dotTone] ?? 0.32) * Number(a["fill-opacity"] ?? 1);
    return { fill: C.dot, "fill-opacity": alpha.toFixed(3), stroke: "none" };
  }
  if (has(a, "iso-wire-end")) return { fill: C.paper, stroke: C[wireTone] ?? C.lo, "stroke-width": LINE };
  if (has(a, "heat")) return { fill: "#ffffff", stroke: "none" };
  if (has(a, "iso-halo")) return { fill: C.halo, "fill-opacity": "0.16", stroke: "none", transform: "translate(0 3)" };
  if (has(a, "iso-fill")) return { fill: green ? GREEN.body : lit ? C.face : C.paper, stroke: "none" };
  if (has(a, "tb-body")) return { fill: green ? GREEN.body : C.shade[2], stroke: "none" };
  if (has(a, "tb-shine")) return { fill: green ? GREEN.top : C.top, stroke: "none" };
  if (has(a, "tb-shade")) return { fill: green ? GREEN.shade : C.shade[0], stroke: "none" };
  if (has(a, "tb-ring")) return { fill: "none", stroke: green ? GREEN.line : C[a["data-tone"]] ?? C.lo, "stroke-width": 0.45 };
  const tinted = (fill) => (seamless ? { fill, stroke: fill, "stroke-width": 0.4, "stroke-linejoin": "round" } : { fill, stroke: "none" });
  if (has(a, "iso-shade")) {
    const n = Number(a["data-shade"]);
    return tinted(green ? [GREEN.shade, GREEN.shade, GREEN.body, GREEN.body][n] : lit ? C.litShade : C.shade[n]);
  }
  if (has(a, "iso-top")) return tinted(green ? GREEN.top : lit ? C.litTop : C.top);
  if (has(a, "iso-line")) {
    const tone = a["data-tone"] ?? "lo";
    let stroke = green ? GREEN.line : C[tone] ?? C.lo;
    if (lit && has(a, "iso-edge") && !green) stroke = C.lit;
    const s = { fill: "none", stroke, "stroke-width": LINE, "stroke-linecap": "round", "stroke-linejoin": "round" };
    if ("data-dotted" in a) Object.assign(s, { "stroke-dasharray": "0.01 3.5", "stroke-width": 1.2 });
    if ("data-dashed" in a) s["stroke-dasharray"] = "3 3";
    return s;
  }
  return {};
}

// Rewrite kit markup to attributes only: no classes, no data-*, no style.
export function inline(svg) {
  const stack = [];
  return svg.replace(/<(\/?)([a-zA-Z]+)([^>]*?)(\/?)>/g, (_, close, tag, rest, self) => {
    if (close) {
      stack.pop();
      return `</${tag}>`;
    }
    const a = attrsOf(rest);
    const style = styleOf(tag, a, stack);
    const keep = Object.entries(a).filter(([key]) => !key.startsWith("data-") && key !== "class" && key !== "style" && key !== "fill-opacity");
    const all = [...keep, ...Object.entries(style)];
    const text = `<${tag}${all.map(([key, value]) => ` ${key}="${value}"`).join("")}${self ? "/" : ""}>`;
    if (!self) stack.push(a);
    return text;
  });
}

// The bounds of every coordinate in the markup (the kit writes M/L paths and circles only).
function boundsOf(svg) {
  let [x0, y0, x1, y1] = [Infinity, Infinity, -Infinity, -Infinity];
  const grow = (x, y, r = 0) => {
    x0 = Math.min(x0, x - r); y0 = Math.min(y0, y - r); x1 = Math.max(x1, x + r); y1 = Math.max(y1, y + r);
  };
  for (const m of svg.matchAll(/\sd="([^"]*)"/g)) {
    if (/[^MLZ0-9.\s-]/.test(m[1])) throw new Error(`unexpected path command in ${m[1].slice(0, 40)}`);
    const nums = m[1].match(/-?\d+(?:\.\d+)?/g) ?? [];
    for (let i = 0; i + 1 < nums.length; i += 2) grow(Number(nums[i]), Number(nums[i + 1]));
  }
  for (const m of svg.matchAll(/<circle[^>]*>/g)) {
    const a = attrsOf(m[0]);
    grow(Number(a.cx), Number(a.cy), Number(a.r));
  }
  return [x0, y0, x1, y1];
}

function main() {
  mkdirSync(OUT, { recursive: true });
  for (const file of readdirSync(OUT)) if (file.endsWith(".svg") || file.endsWith(".json")) rmSync(join(OUT, file));
  const manifest = { viewbox: [WIDTH, HEIGHT], projection: P, layers: [], ...extras };
  layers.forEach((l, z) => {
    const body = inline(l.svg);
    const [bx0, by0, bx1, by1] = boundsOf(body);
    // Room for strokes, the halo's 3-unit drop, and whole-unit edges.
    const x = Math.floor(bx0 - PAD);
    const y = Math.floor(by0 - PAD);
    const w = Math.ceil(bx1 + PAD + 3) - x;
    const h = Math.ceil(by1 + PAD + 3) - y;
    const file = `${l.id}.svg`;
    writeFileSync(join(OUT, file), `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="${x} ${y} ${w} ${h}">${body}</svg>\n`);
    // Seed the import settings once (Godot keeps them and adds its uid): rasterised at 2× with
    // mipmaps, since the card shows the figure at about half that size.
    const settings = join(OUT, `${file}.import`);
    if (!existsSync(settings)) writeFileSync(settings, `[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\nmipmaps/generate=true\nsvg/scale=${SVG_SCALE}\n`);
    const entry = { id: l.id, file, z, skin: l.skin, group: l.group, rect: [x, y, w, h] };
    if (l.pair) entry.pair = l.pair;
    if (l.heat) entry.heat = true;
    const when = whenOf(l.id);
    if (when) entry.when = when;
    manifest.layers.push(entry);
  });
  writeFileSync(join(OUT, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
  writeFileSync(join(OUT, "fixtures.json"), JSON.stringify(fixtures(), null, 1) + "\n");
  console.log(`exported ${layers.length} layers to ${OUT}`);
}

main();
