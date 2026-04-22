# Handoff: Lean Factory — Walkable Topology (Initial Setup)

## ⚠ Status: Initial Setup, Not Complete UI

**This is an initial setup / reference mock — not the complete UI.** It exists to show Claude Code roughly what the factory world should look and feel like (art direction, tile palette, topology, room layout, interaction metaphor), so Claude Code has something to anchor against when building the real thing. Every screen, panel, and flow shown here will evolve. Do not treat the HTML as a spec; treat it as a visual north star.

Only the topology layout, the walkable player loop, and the interaction prompt have been designed. Scoring, the problem/countermeasure systems, AI integration, persistence, save files, and most UI chrome (menus, settings, save/load, tutorials, dialogs) are explicitly out of scope here and will come in later iterations.

## Overview

Lean Factory is a single-player, 2D top-down factory simulation game where the player runs a fictional hoverboard assembly plant (NovaGlide X1). The player walks around as the plant manager, observes problems, diagnoses them, and applies lean countermeasures. See `Lean_Factory_Business_Case_v0.2` (original doc) for the full product vision — this handoff covers only the first playable slice: **a walkable factory + office world with stations and NPCs that can be inspected.**

## About the Design Files

The files in this bundle are **design references created in HTML** — prototypes showing intended look and behavior, not production code to copy directly. The task is to **recreate these HTML designs in the target codebase's environment** (the business case specifies a local Python desktop application — so Pygame, Pyglet, arcade, or a Python binding to a game engine is expected) using the established patterns of that stack. If no environment has been picked yet, pick the one best suited for a tile-based 2D walkable world with UI overlays.

Do **not** ship the HTML as the game. It exists only to communicate look/layout/behaviour.

## Fidelity

**Medium-fidelity.** Colors, tile palette, topology, zone layout, and overall art direction are intentional and should be recreated closely. Exact pixel dimensions, typography, and the right-side inspector panel are approximate — use the target stack's idiomatic UI patterns and typography. The business case calls for a Python desktop application, so the inspector panel should become a proper in-game panel (Pygame surface, Tk sidebar, or whatever the framework offers), not an HTML sidebar.

## Files in This Bundle

| File | Purpose |
|------|---------|
| `Lean Factory Topology v1.html` | Schematic diagram (abstract boxes + arrows). **Reference only** — use to understand zone relationships. |
| `Lean Factory Topology v2.html` | Top-down "game view" with dimensional machines but no walking. **Reference for machine art direction** (conveyor chevrons, CNC gantry, burn-in rig, flight-test pad, packaging line, loading docks, painted flow lines). |
| `Lean Factory Topology v3.html` | **The main reference.** Full walkable tilemap with player, collision, interaction prompt, inspector panel, minimap, HUD. This is what the initial game setup should look/feel like. |

v3 supersedes v1/v2. v1 and v2 are included only because they show auxiliary views (schematic + close-up machine art) that may help when building the final rendering.

## The World

### World dimensions
- **Tile size:** 24 px
- **Map:** 100 × 60 tiles = 2400 × 1440 world px
- Camera follows the player with a smoothed lerp (factor ≈ 0.18), clamped to world bounds.

### Rooms (the top-level spatial structure)

The world has **3 major regions**:

1. **Exterior Yard** — rows 0–3 across factory width (parked truck, asphalt).
2. **Factory Floor** — rows 4–30, cols 0–69. U-shape lean cell.
3. **Office + Support Wing** — everything south and east of the factory.

Inside these, specific rooms:

| Room | Tile bounds (x1,y1 – x2,y2) | Floor tile | Purpose |
|------|---|---|---|
| Exterior Yard | 0,0 – 69,3 | asphalt `#5c564b` | Inbound truck, dock approach |
| Factory Floor | 0,4 – 69,30 | concrete `#cfc6b2` | 19 production stations, U-flow |
| Main Corridor | 70,4 – 77,59 | carpet-gray `#bdb49e` | Hallway linking office rooms |
| Operations | 78,4 – 99,12 | carpet-blue `#b6c8da` | Plant manager + scheduler |
| Quality | 78,13 – 99,21 | carpet-green `#bfd5bf` | QA lead + metrology bench |
| IT | 78,22 – 99,30 | carpet-purple `#c9bcdc` | Engineer + server rack (MES) |
| Finance | 78,31 – 99,39 | carpet-teal `#bcd6d0` | Controller + records |
| HR | 78,40 – 99,48 | carpet-orange `#e4c8b3` | HR manager + interview area |
| Break Room | 78,49 – 99,59 | carpet-brown `#c9b59a` | Lunch table, vending, info board |
| Maintenance | 0,31 – 29,59 | yellow shop `#d8c37a` | Tool crib, mill/lathe, parts shelves, TPM board |
| Locker Room | 30,48 – 69,59 | white tile `#e3dccb` | Lockers, clock-in terminal |

Walls (`#3a3830`) ring every room. Doors (`#caa24a`, walkable) carve through walls at specific coordinates — see `v3` source for the authoritative list.

### Factory Floor — Production Zones

The factory is a **U-shape lean cell**. Material enters at the NW dock, sweeps right along the top, U-turns down the east wall into Final Assembly, runs right-to-left along the south, and exits at the SW dispatch dock.

Each zone is painted as a colored rectangle on the concrete floor (lean "floor tape" zoning), with a subtle dashed inner border and a monospace label painted on the floor.

| Zone | Paint | Stations | Starting Ops |
|------|------|----------|---|
| Z1 Receiving | `#e5cf9a` amber | Dock (R-01), Incoming QA (R-02), Staging (R-03) | 3 |
| Z2 Component Prep | `#c9d6a3` olive | Coil Winding (P-01), PCB Prep (P-02), Deck Cutting (P-03) | 3 |
| Z3 Subassembly | `#a9d4b8` mint | Propulsion Build (S-01), Battery Assembly (S-02), Deck Assembly (S-03) | 3 |
| Z4 Final Assembly | `#a9c3d6` steel blue | Integration 1–5 (FA-01…FA-05), right-to-left conveyor | 7 (FA-03 and FA-04 have 2 ops) |
| Z5 Testing | `#c3b5d6` lavender | Burn-in (T-01), Flight Test (T-02), Final QA (T-03) | 4 (T-03 has 2) |
| Z6 Packaging & Ship | `#d6a9a9` blush | Packaging (PK-01), Dispatch Staging (PK-02) | 2 |

**19 stations, 22–24 starting operators** (chaotic start; deliberately unbalanced).

Every station has a typed *machine art*: dock, bench, rack, machine, cnc, cell, line (conveyor), rig (burn-in), pad (flight-test H-bullseye), packline. See `drawObj()` in v3 for the painter per type.

## Rendering Architecture (recommended)

1. **Static background layer** — prerender the entire tilemap to an offscreen surface once at load. Each tile draws its fill color plus a subtle texture (grout lines on concrete, asphalt grain, brick highlight on walls, carpet stipple, door knob, hazard stripes). Draw big painted-floor zone labels (semi-transparent monospace) over the zone paint. In v3 this lives in `drawWorldBackground()` → `bg` canvas.

2. **Dynamic object layer** — every frame, draw objects whose footprint intersects the visible viewport, **sorted by `ty + h`** for correct overlap (painter's algorithm). Objects include machines, desks, boards, NPCs, the player. See `OBJECTS` array + `drawObj()`.

3. **Player** — single character, drawn last (after same-row objects). Has 4 facing directions (`up/down/left/right`); eyes only render when facing the camera.

4. **Camera** — lerp toward `player.pos - viewportCenter`, clamped to `[0, WORLD_W - viewW]`, `[0, WORLD_H - viewH]`.

5. **Interaction highlight** — dashed golden outline (2px, dash-array `[5,3]`, animated offset) around the currently-facing interactable's footprint.

## Collision & Interaction

### Collision grid
A parallel `Uint8Array` per row: `solid[y][x] = 0` walkable, `1` solid. Populated from:
- `tile === 'wall' || 'void' || 'grass'` → solid
- Every object's footprint tiles → solid (machines, desks, NPCs, etc.)
- Doors explicitly cleared → walkable

Player footprint is a small circle at the feet; test 4 sample points around the feet against the grid. Resolve axis-by-axis so the player slides along walls instead of getting stuck.

### Facing + Interactable detection
After each frame:
1. Compute the tile 1 step ahead of the player in their facing direction.
2. Check that tile plus its 4 neighbours for any object whose footprint contains it.
3. If found → show the floating "**[E] {label}**" prompt above the player and draw the dashed outline around the target.

### Interaction
Press **E** or **Space**: open the inspector panel with that object's payload.

## Controls

| Input | Action |
|---|---|
| W/A/S/D or Arrows | Walk (4-directional, diagonal allowed at 0.707×) |
| Shift | Run (2× speed) |
| E or Space | Interact with the highlighted target |
| Esc | Close inspector / return to overview |

Base walking speed: 2 px/frame (≈ 120 px/s at 60fps).

## UI Panels

### Top bar (full-width, 44px, dark)
`NovaGlide Plant 01 · TOPOLOGY v3 · WALKABLE` on the left, inline control hint in the middle, rooms/stations/NPC counts on the right. Dark background `#100f0c`, mono font for counts.

### HUD (top-left, over the world)
Current room name (gold `#ffd683`) + a dynamic sub-line ("Step up to a machine, press E" → "Press E to inspect · {label}" when near something). Semi-transparent dark rounded card.

### Minimap (top-right, over the world)
220 × 140 canvas showing the full tilemap at scale, with an orange player blip and a white viewport rectangle.

### Interaction prompt (bottom-center, over the world)
Floating tooltip: `[E] {label}`. Fades in/out on `.on` class toggle.

### Inspector panel (right sidebar, 340px wide, dark)
Content depends on what was interacted with:

- **Station** (has `ct` field): 2×2 KPI grid (Status w/ colored dot, Cycle Time w/ target, Operators count, WIP), Details section (Station ID, Zone, Shift), and — if status is `wait` or `block` — an Observed Issue note.
- **NPC / role**: Character section (Name, Role, Location), Talk section with a context-specific line (see `npcLine()` for the lines mapped by role), Actions section with placeholder rows for later functionality.
- **Generic object** (boards, desks, servers, etc.): ID/Location/Kind + "Placeholder object — detailed inspector UI arrives in a later iteration."
- **Empty state** (no selection): "Walk around the plant…" hint card + Rooms list + Controls list.

## NPCs (initial roster, static positions)

10 NPCs placed at specific tiles. Each has a `bodyColor` and a facing `dir`. Static for v3 — no pathing. Pathing/schedules is a future iteration.

| Name | Role | Room | Body color |
|---|---|---|---|
| TL · Receiving | Team Leader | Factory (near Z1 desk) | `#4a90d8` |
| TL · Prep | Team Leader | Factory (near Z2 desk) | `#4a90d8` |
| TL · Subassy | Team Leader | Factory (near Z3 desk) | `#4a90d8` |
| TL · Final | Team Leader | Factory (near Z4 desk) | `#4a90d8` |
| Maya · Scheduler | Scheduler | Operations | `#d8a14a` |
| Sven · QA Lead | Quality Lead | Quality | `#6ab26a` |
| Priya · IT | IT Engineer | IT | `#9a6adb` |
| Jon · Finance | Controller | Finance | `#4ab3a6` |
| Lin · HR | HR Manager | HR | `#c86a4a` |
| Rico · Maint. | Maintenance Lead | Maintenance | `#9a8a4a` |

## Design Tokens

### Core palette
- Concrete floor `#cfc6b2`, grout `#b8ae96`
- Wall `#3a3830`
- Ink `#1c1b17` / `#3a3830` / `#6b6858`
- Accent gold (door, UI) `#caa24a` / `#ffd683`
- Hi-vis orange (operator markers, player collar) `#ff8a1f`

### Zone paints
Amber `#e5cf9a`, olive `#c9d6a3`, mint `#a9d4b8`, steel `#a9c3d6`, lavender `#c3b5d6`, blush `#d6a9a9`.

### Office carpets
Blue `#b6c8da`, green `#bfd5bf`, purple `#c9bcdc`, teal `#bcd6d0`, orange `#e4c8b3`, brown `#c9b59a`. Corridor gray `#bdb49e`. Locker white-tile `#e3dccb`. Maintenance yellow-shop `#d8c37a`.

### Status colors
Running `#6fd36f` · Waiting `#ffb84d` · Blocked `#e8604a`.

### Typography
- UI body: `Inter` 12–13px
- Mono / IDs / HUD: `JetBrains Mono` 10–12px, tracked 0.04–0.18em when caps
- Floor-painted zone labels: bold mono 12px, `globalAlpha ≈ 0.55`, color = zone ink

### Spacing
Mostly multiples of the 24px tile. UI padding 8/12/14/18. Radius 3–6px.

## Out of Scope for This Handoff (For Later)

- Walking animation (sprite cycle) — currently single-frame
- NPC pathing / schedules / shift changes
- Problem spawning + countermeasure application
- Math scoring + improvement credits
- AI reflection (Claude integration)
- Save/load (SQLite persistence per business case)
- Menus, settings, tutorial, cutscenes
- Sound / music / SFX
- Day/night or shift cycle
- Camera zoom
- Mobile / touch controls

Build these after the walkable world + inspector skeleton is working.

## Recreation Checklist

When you recreate this in Python (or whichever stack), you are done with this slice when:

- [ ] A 100×60 tile world renders with the zone paints, walls, doors, and painted zone labels shown in v3.
- [ ] All 6 factory zones are present with the 19 stations placed at the tile coordinates given in v3's `OBJECTS` array.
- [ ] The 6 office rooms + maintenance + locker + yard are present and walled off, with the exact doors listed.
- [ ] A controllable player sprite walks with WASD/arrows, collides with walls and objects, and runs at 2× with Shift.
- [ ] Facing a machine, desk, NPC, or board surfaces a "[E] {label}" prompt and a dashed outline on the target.
- [ ] Pressing E opens an inspector panel showing station KPIs (for stations), character dialog (for NPCs), or placeholder card (for everything else).
- [ ] A minimap shows the world + player blip + viewport rect.
- [ ] A HUD shows the current room name.

Once that runs, the rest of the game (problems, countermeasures, scoring, persistence) can be layered on top.

## Source of Truth

When in doubt, **read `Lean Factory Topology v3.html`** in this bundle. The `OBJECTS` array, `ROOMS` array, tile-building code (`fillRect` / `strokeRect` calls), door carves, collision logic, and inspector payload are all authoritative. Everything in this README is an explanation of what's in that file.
