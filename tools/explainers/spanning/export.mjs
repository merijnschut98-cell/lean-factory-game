// Export "Hoe werkt het? 1" for Godot (spec §6.1): one SVG per layer, a manifest and the model's
// fixtures, into game/assets/explainers/spanning/.
//   node tools/explainers/spanning/export.mjs
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { exportFigure } from "../export-lib.mjs";
import * as figure from "./figure.mjs";
import { fixtures } from "./model.mjs";
import { whenOf } from "./visibility.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
exportFigure(resolve(HERE, "../../../game/assets/explainers/spanning"), figure, fixtures(), whenOf);
