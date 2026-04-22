# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed or added.

---

## Current Status: Phase 4 — Countermeasures and Scoring (~70% done)

Next: automated-testing skill run → per-CM modifier tuning → save/load for CMs → Phase 5 AI

---

## Phase 0 — Design Foundations ✅ COMPLETE
All design artifacts: spec doc, 25-problem Tier 1 catalog YAML, 79-countermeasure YAML (merged), topology files.

---

## Phase 1 — Simulation Core (Headless) ✅ COMPLETE
- ✅ Station model (OEE, cycle time, WIP, quality)
- ✅ Operator model (skill, fatigue, state)
- ✅ Material flow, time engine with speed multipliers, factory aggregator
- ✅ Metrics calculation (live KPIs), SQLite persistence (save/load), headless mode
- ✅ Bug fixes: `field()` crash, stop probability formula, tick calibration, injection rate
- ✅ Verified: Day 1 output = 14 hoverboards (exact spec target), OEE ≈ 39%, FTR ≈ 83%

**Deliverable:** Headless mode runs cleanly for N days and prints metrics. ✅

---

## Phase 2 — Navigation and Rendering ✅ COMPLETE
- ✅ Tilemap, player sprite, camera, collision detection, interaction zones
- ✅ Factory rendering (zone colors, station sprites, operator sprites)
- ✅ HUD (clock, speed, KPI strip, minimap), inspector panel (station metrics, NPC dialogue)
- ✅ Code-reviewed; runtime visual test pending first play session

**Deliverable:** Walkable factory. Player navigates floor, sees stations, inspector opens on E. ✅

---

## Phase 3 — Problems and Inspection ✅ COMPLETE
- ✅ Problem data model, YAML catalog loader, 25 Tier 1 problems in YAML
- ✅ Visibility logic: obvious → active Day 1; subtle → activates on first zone inspection; hidden → deferred to Phase 4
- ✅ Problem state machine, effect modifiers applied to stations on activation
- ✅ `Factory.active_problems`, `log_inspection()`, `recent_inspections()` on Factory
- ✅ `MaturityEngine` wired into factory (register_cm/remove_cm API ready for Phase 4)
- ✅ Red ! badge on stations with active problems (renderer)
- ✅ Inspector panel: KPI grid, problem name/severity/symptom, Time Observation bar chart, Gemba Log
- ✅ Inspection logged once on open (not per frame); subtle problems re-evaluated on each inspection
- ✅ `ct_history` rolling window (last 20) on Station for Time Observation

**Deliverable:** Player walks to a problem station, sees ! indicator, opens inspector, reads symptoms, sees cycle time history and inspection log. ✅

---

## Phase 4 — Countermeasures and Scoring 🔧 ~70% COMPLETE

### Done
- ✅ `CountermeasureCatalog` + `Countermeasure` dataclass in `problems/countermeasure.py` (loads all 79 CMs)
- ✅ All six scoring metrics complete: DQQ, EI, RCA, CMP, LM, CIM (`scoring/metrics.py`)
- ✅ `calculate_all()` orchestrator; `credits_earned()` formula
- ✅ Full mismatch effectiveness table (`maturity/mismatch.py`): full/reduced/minimal/no_effect tiers
- ✅ Mismatch warning dialog UI (`ui/warning_dialog.py`): Proceed / Cancel
- ✅ Countermeasure browser UI (`ui/catalog_panel.py`): scroll, tier color, prereq indicator
- ✅ Score display panel (`ui/score_panel.py`): 6 metrics with dot bars + total + credits
- ✅ `Factory.apply_countermeasure()`: mismatch mult, station modifier, maturity register, side effects
- ✅ `Factory.resolve_problem()`: scores, awards credits, removes modifiers, RESOLVED state
- ✅ Decay logic (`_tick_decay`): per-CM day timer, removes modifier + maturity on expiry
- ✅ Problem card in inspector: state badge (ACTIVE/CM APPLIED), [C] and [R] action hints
- ✅ Game loop fully orchestrated: inspector → catalog → warning → apply → resolve → score
- ✅ `ui/text_utils.py`: shared `wrap_text()` used across all panels

### Remaining
- ⬜ **Per-CM modifier tuning**: current heuristic (avail+0.05, perf+0.05, qual+0.03 × eff_mult) is a baseline; tune per CM category in Phase 4 polish
- ⬜ **Save/load for active CMs**: `active_countermeasures` dict not yet persisted to SQLite
- ✅ **Automated tests**: 77 tests covering scoring (all 6 metrics), catalog loader, mismatch calc, apply/resolve flow, wrap_text, decay
- ⬜ Save/load for active CMs not yet persisted to SQLite

**Deliverable:** First fully playable loop. Walk → find → investigate → apply CM → score → earn credits. ✅ (functionally complete, polish remaining)

---

## Phase 5 — AI Integration ⬜ ~5% COMPLETE

### Done
- ✅ AI module stubs exist (`ai/agent.py`, `ai/coach.py`, `ai/problem_generator.py`, `ai/prompt.py`)

### Remaining
- ⬜ LGM-40 system prompt in `ai/prompt.py` (spec §10.3 persona)
- ⬜ `ai/coach.py`: coach consultation during investigation (75 credits/exchange, Socratic only)
- ⬜ `ai/coach.py`: post-score reflection dialogue (50 credits, does not modify score)
- ⬜ "Ask Coach" button in problem inspector panel → opens coach dialogue UI
- ⬜ Coach dialogue UI: scrollable conversation panel with send field
- ⬜ `ai/problem_generator.py`: generate problem from factory state (500 credits, gated on catalog exhausted)
- ⬜ Session cost tracking: `factory.session_cost_eur` incremented per API call, shown in HUD
- ⬜ Anthropic SDK with prompt caching (target: <€0.50/hour at average play intensity)
- ⬜ Graceful offline fallback: show "Coach unavailable" if API call fails

**Deliverable:** Game with full AI coaching. Coach on demand. Session cost visible in HUD.

---

## Phase 6 — Tiers 2–4 Content + Final Packaging ⬜ NOT STARTED

### Content
- ⬜ Tier 2 problem catalog: 15–20 problems (Claude designs, Merijn reviews)
- ⬜ Tier 3 problem catalog: 15–20 problems
- ⬜ Tier 4 problem catalog: 10–15 problems
- ⬜ Tier progression visibility verified across all four tiers
- ⬜ Tier 5 stub in UI ("Coming in v2" — locked)
- ⬜ Specialist hiring system (credits → hire → zone OEE bonus)
- ⬜ Full save/load for all new state (Tiers 2–4 problems, specialists, CM history)

### Packaging
- ⬜ Add icon (`assets/icon.ico`) — design or source one
- ⬜ Populate `assets/sprites/`, `assets/tilesets/`, `assets/sounds/` with game assets
- ⬜ Update `lean_factory.spec` to handle populated assets correctly
- ⬜ Build `lean_factory.exe` with PyInstaller: `pyinstaller lean_factory.spec`
- ⬜ Test standalone exe on a clean machine (no Python installed)
- ⬜ Create installer or zip distribution

**Deliverable:** Complete v1 game. All four tiers playable. 70–80 hand-designed problems. Standalone exe.

---

## Phase 7 — UI Polish and UX ⬜ NOT STARTED

### Navigation and Floor

- ⬜ Animated player sprite: 4-directional walk cycle (replace solid rectangle)
- ⬜ Station sprites with more visual detail: machine bodies, screens, conveyor belts per zone type
- ⬜ Animated flow lines between stations: moving dots showing material in transit
- ⬜ WIP pile visual: small stacked-unit icons near a station when `wip_in` is high
- ⬜ Andon light on station sprite when the Andon countermeasure is active (blinking amber/red)
- ⬜ Problem indicator animation: pulsing ! badge instead of static (draws the eye)
- ⬜ Problem discovery notification: non-blocking toast in top-left when a new problem surfaces

### Screens

- ⬜ Start screen: game title, "New Game / Continue / Quit", version number
- ⬜ Save/load screen: list of save slots with date and day number; manual save + load from menu
- ⬜ Day summary popup: non-blocking end-of-day card showing output, OEE, WIP, FTR delta vs yesterday
- ⬜ Pause screen overlay: visual darkening + "PAUSED" indicator + resume hint

### Inspector and Panels

- ⬜ Scrollable inspector panel: panels that exceed screen height should scroll (mouse wheel / arrow keys)
- ⬜ Non-blocking toast notifications: CM decay warning, new problem visible, credits earned — shown as a timed banner, never freeze gameplay
- ⬜ Keyboard shortcut reference: press [?] or [F1] to show overlay listing all controls
- ⬜ Problem count HUD badge: active problem count visible at all times (e.g. "⚠ 12 active")
- ⬜ Maturity/phase progress bar in HUD: zone scores visualised at a glance

### NPC Interactions

- ⬜ Multi-line NPC dialogue: NPCs have 3–5 rotating lines that change as factory matures or problems are solved
- ⬜ NPC awareness: operators comment on nearby active problems when inspected ("that shelf's been a mess for weeks")
- ⬜ Character portraits: small illustrated avatar per NPC role shown in the inspector panel
- ⬜ "Walk-up" animation: brief highlight / icon appears above NPC head when player is in range

### General UX

- ⬜ No action should block gameplay for more than 1 second: all dialogs dismissible with Esc or Enter immediately
- ⬜ Tooltip system: hovering over HUD metrics shows a one-line explanation (OEE = Availability × Performance × Quality)
- ⬜ Minimap problem dots: active problem zones shown as coloured dots on the minimap
- ⬜ Settings screen: simulation speed default, display options
- ⬜ Sound cues: basic event sounds for problem discovered, countermeasure applied, score panel open, day end (using pygame mixer; keep subtle)
- ⬜ Colour-blind friendly palette option: toggle accessible colours for problem badges and OEE indicators

**Deliverable:** A game that feels polished enough to show to someone unfamiliar with the project — no raw rectangles, no frozen screen on dialog, no dead-end interactions.

---

## Decisions Made
- Tier 2–4 problem design: Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; all AI code reads from env var
- Exe build deferred to Phase 6 (asset folders empty now; bat/vbs launchers used during development)
- pygame-ce used as pygame drop-in (installed via pygame_gui dependency)
