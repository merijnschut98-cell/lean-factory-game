# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed or added.

---

## Current Status: Phase 4 — Countermeasures and Scoring (starting)

Phase 3 complete. Next: countermeasure catalog loader → browser UI → mismatch calc → apply + score flow

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

## Phase 4 — Countermeasures and Scoring ⬜ ~10% COMPLETE

### Done
- ✅ Scoring math stubs: DQQ, EI, RCA, CMP, LM, CIM (`scoring/metrics.py`)
- ✅ Credit formula (`scoring/credits.py`)

### Remaining
- ⬜ Load countermeasure catalog from `data/countermeasures_v1.yaml` into a `CountermeasureCatalog` class
- ⬜ Countermeasure browser UI panel: list by tier, filter, show prerequisites, Apply button
- ⬜ Mismatch effectiveness calculation (spec §7.1): zone_maturity vs cm_tier → multiplier
- ⬜ Mismatch warning dialog before apply: "Proceed / Cancel / Ask Coach" (spec §7.2)
- ⬜ Countermeasure effect applied to station on confirm: `apply_modifier` + record active CM
- ⬜ Decay logic: per-CM tick timer; reduce effect over `decay.days` without sustain; notify player
- ⬜ Side-effect triggering: harmful application activates linked problem from `side_effect_ref`
- ⬜ Complete RCA scoring: keyword matching per problem's `root_cause` field
- ⬜ Score display panel: 6 metrics + total + credits earned (shown after resolve)
- ⬜ Credits balance live in HUD (factory.credits already wired — just needs countermeasure spending)
- ⬜ PDCA tracking for CIM score: flag if player re-inspects station after applying CM
- ⬜ Problem resolution flow: state → RESOLVED, modifiers removed, credits awarded, score shown

**Deliverable:** First fully playable loop. Walk → find → investigate → apply CM → score → earn credits.

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

## Decisions Made
- Tier 2–4 problem design: Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; all AI code reads from env var
- Exe build deferred to Phase 6 (asset folders empty now; bat/vbs launchers used during development)
- pygame-ce used as pygame drop-in (installed via pygame_gui dependency)
