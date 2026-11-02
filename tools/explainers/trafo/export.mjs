// Export "Hoe werkt het? 2: de transformator" for Godot (spec 2026-10-24-explainer-transformator
// §6): one SVG per layer, a manifest and the model's fixtures, into game/assets/explainers/trafo/.
//   node tools/explainers/trafo/export.mjs
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { exportFigure } from "../export-lib.mjs";
import * as figure from "./figure.mjs";
import { fixtures } from "./model.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

// When a layer shows, as data for the manifest (TrafoRig.shows reads it):
//   {load_at_least: %}  a house's windows light from this load on (one house per quarter)
// A layer without `when` shows whenever its skin does.
export function whenOf(id) {
  const m = id.match(/^house(\d)_lit$/);
  return m ? { load_at_least: Number(m[1]) * 25 } : null;
}

exportFigure(resolve(HERE, "../../../game/assets/explainers/trafo"), figure, fixtures(), whenOf);
