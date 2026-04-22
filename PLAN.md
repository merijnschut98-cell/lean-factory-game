# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed.

---

## Current Status: Phase 1 bugfix needed → then Phase 3

---

## Phase 0 — Design Foundations ✅ COMPLETE
All design artifacts exist: spec doc, problem catalog YAML (730 lines, 25 problems), countermeasures YAML, topology.

---

## Phase 1 — Simulation Core (Headless) ✅ COMPLETE

### Tasks
- ✅ Station model (OEE, cycle time, WIP, quality)
- ✅ Operator model (skill, fatigue, state)
- ✅ Material flow between stations
- ✅ Time engine with speed multipliers
- ✅ Factory aggregator
- ✅ Metrics calculation (live KPIs)
- ✅ SQLite persistence (save/load)
- ✅ Headless mode
- ✅ Fixed `station.py` crash bug (`field()` → `[]`)
- ✅ Fixed stop probability formula (step-size independent: `1 - avail^(dt/CT)`)
- ✅ Calibrated headless tick (30 sim-sec/step) and injection rate
- ✅ **VERIFIED**: Day 1 output=14 ✓, OEE≈39% (problems active), FTR≈83%, WIP≈52

### Deliverable
Headless mode runs cleanly for N days and prints metrics. ✅

---

## Phase 2 — Navigation and Rendering ✅ COMPLETE

### Tasks
- ✅ Tilemap definition from topology
- ✅ Player sprite with four-directional movement
- ✅ Camera following player
- ✅ Collision detection
- ✅ Interaction zones per station
- ✅ Factory rendering (zone colors, station sprites, operator sprites)
- ✅ Basic HUD (clock, speed, KPI strip, minimap)
- ✅ Inspector panel (station OEE/metrics, NPC dialogue)
- ✅ Visual verified via code review (pygame install needed for runtime test)

### Deliverable
Walkable factory. Player navigates floor, sees stations, inspector opens on E. ✅

---

## Phase 3 — Problems and Inspection 🔧 ~60% COMPLETE

### Tasks
- ✅ Problem data model (`problems/problem.py`)
- ✅ YAML catalog loader (`problems/catalog.py`)
- ✅ 25 Tier 1 problems in `data/problems_tier1.yaml`
- ✅ Visibility logic: obvious auto-activate Day 1; subtle needs zone inspection; hidden deferred to Phase 4
- ✅ Problem state machine (states defined)
- ✅ Problems wired into `Factory.__init__`: load catalog, `evaluate_visibility` each day
- ✅ Problem effect modifiers applied to stations on activation (`apply_modifier`)
- ✅ `Factory.active_problems` property + `Factory.log_inspection()` for scoring
- ✅ Visual problem indicators on factory floor (red ! badge on station object)
- ✅ Inspector panel: shows problem name, severity, first symptom when station has active problem
- ✅ Inspection logging wired in inspector (logs entity:station + metric on open)
- ⬜ Gemba walk panel: show cumulative inspection path in inspector
- ⬜ Diagnostic tool UI: "Time Observation" panel (cycle time trend per station)
- ⬜ Maturity engine: `maturity_engine.py` `update()` real zone scores (needed for subtle/hidden problems and Phase 4)
- ⬜ `subtle` problem activation: track which zones have been inspected (inspection_log used — just need evaluation on each open)

### Deliverable
Player walks to a problem station, sees ! indicator, opens inspector, reads symptoms, and can investigate.

---

## Phase 4 — Countermeasures and Scoring ⬜ ~10% COMPLETE

### Tasks
- ✅ Scoring math functions (`scoring/metrics.py`) — DQQ, EI, RCA, CMP, LM, CIM stubs exist
- ✅ Credit formula (`scoring/credits.py` exists)
- ⬜ Load countermeasure catalog from `data/countermeasures_v1.yaml`
- ⬜ Countermeasure browser UI panel (list, filter by tier, apply button)
- ⬜ Maturity-mismatch effectiveness calculation (spec Section 7.1)
- ⬜ Mismatch warning dialog before confirming application (spec Section 7.2)
- ⬜ Countermeasure effect applied to station modifiers when confirmed
- ⬜ Decay logic: tick decay timer per active countermeasure, reduce effect, notify player
- ⬜ Side-effect triggering: harmful application activates linked problem from catalog
- ⬜ Complete RCA scoring (keyword matching per problem)
- ⬜ Score display panel: show all 6 metrics + total + credits earned after resolve
- ⬜ Credits balance shown in HUD (already wired — just needs to update)
- ⬜ "Proceed / Cancel / Ask Coach" dialog for mismatch warnings
- ⬜ PDCA tracking for CIM score: detect if player re-inspects station after applying countermeasure

### Deliverable
First fully playable version. Walk → find problem → investigate → apply countermeasure → receive score → earn credits.

---

## Phase 5 — AI Integration ⬜ ~5% COMPLETE

### Tasks
- ✅ AI module files exist (`ai/agent.py`, `ai/coach.py`, `ai/problem_generator.py`, `ai/prompt.py`)
- ⬜ `ai/prompt.py`: LGM-40 system prompt (use spec Section 10.3 persona)
- ⬜ `ai/coach.py`: Coach consultation during investigation (75 credits/exchange)
- ⬜ `ai/coach.py`: Post-score reflection dialogue (50 credits)
- ⬜ "Ask Coach" button in problem inspector panel
- ⬜ Coach dialogue UI panel (scrollable conversation)
- ⬜ `ai/problem_generator.py`: Generate new problem from factory state (500 credits, catalog-exhausted gate)
- ⬜ Session cost tracking: increment `factory.session_cost_eur` per API call, show in HUD
- ⬜ Anthropic SDK wired with prompt caching (spec: under €0.50/hour target)
- ⬜ Graceful offline fallback: coach unavailable message if API call fails

### Deliverable
Game with AI coaching. Coach available on demand. Session cost visible in HUD.

---

## Phase 6 — Tiers 2, 3, and 4 Content ⬜ NOT STARTED

### Tasks
- ⬜ Tier 2 problem catalog: 15–20 problems (design + YAML)
- ⬜ Tier 3 problem catalog: 15–20 problems (design + YAML)
- ⬜ Tier 4 problem catalog: 10–15 problems (design + YAML)
- ⬜ Tier progression visibility verified across all four tiers
- ⬜ Tier 5 stub in UI (locked, "Coming in v2" label)
- ⬜ Specialist hiring system (credits → hire → zone bonus)
- ⬜ Full save/load coverage for all new state (Tiers 2–4 problems, specialists)

### Deliverable
Complete v1 game. All four tiers playable. 70–80 hand-designed problems.

---

## Project Setup ✅ COMPLETE

- ✅ CLAUDE.md created (auto-loaded by Claude Code at session start)
- ✅ PLAN.md created and linked
- ✅ `data/countermeasures_v1.yaml` — merged two versions into one (79 entries: design content + numeric multipliers + applicable_to + decay_days)
- ✅ Root `countermeasures_v1.yaml` deleted
- ✅ `.env` created (paste new API key there as `ANTHROPIC_API_KEY=...`)
- ✅ `.gitignore` created

---

## Known Issues / Blockers

| ID | Description | Blocking |
|----|-------------|---------|
| B-001 | `station.py:89` — `field(default_factory=list)` crashes headless mode | Phase 1 verify |
| B-002 | `pygame` not installed in current env — needs `pip install pygame pygame_gui` | Phase 2 verify |

---

## Decisions Made

- Tier 2–4 problem design (Phase 6): Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; code reads from env var
