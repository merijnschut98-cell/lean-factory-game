# Archived: 3D factory prototype (hoverboard plant)

Snapshot of the Three.js + TypeScript prototype built on 2026-10-12, before the
game pivoted to a fictional energy grid operator. Also available in git history
at commit `b3a4c8c`.

What works: content loader, unit-level line simulation (push vs CONWIP),
action-based investigation (gemba tools, clue depth, operator trust), A3 with
waste/evidence/root cause/prediction, PDCA scoring incl. flow impact, and the 3D
world (procedural characters, stations, conveyors, WIP stacks). UI panels were
unfinished, so it is not playable.

The live `web/` folder was removed once the project moved to Godot 4. To run the
prototype again, restore it from history: `git checkout b3a4c8c -- web`, then
`cd web && npm install && npx vitest run` (it reads the factory content in `data/`).
