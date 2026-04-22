# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed.

---

## Current Status: Phase 1 bugfix needed → then Phase 3

---

## Phase 0 — Design Foundations ✅ COMPLETE
All design artifacts exist: spec doc, problem catalog YAML (730 lines, 25 problems), countermeasures YAML, topology.

---

## Phase 1 — Simulation Core (Headless) 🔧 90% — BUG TO FIX

### Tasks
- ✅ Station model (OEE, cycle time, WIP, quality)
- ✅ Operator model (skill, fatigue, state)
- ✅ Material flow between stations
- ✅ Time engine with speed multipliers
- ✅ Factory aggregator
- ✅ Metrics calculation (live KPIs)
- ✅ SQLite persistence (save/load)
- ✅ Headless mode skeleton
- ⬜ **FIX BUG**: `station.py` line 89 — `_acc_wip_samples: List[float] = field(default_factory=list)` uses a dataclass `field()` in a regular class. Fix: assign `[]` directly in `__init__`.
- ⬜ **VERIFY**: `python main.py --headless --days 1` runs without error and produces output close to Day 1 spec targets (14 output, 41% OEE, 62 WIP, 91.8% FTR)

### Deliverable
Headless mode runs cleanly for N days and prints metrics.

---

## Phase 2 — Navigation and Rendering ✅ ~85% COMPLETE

### Tasks
- ✅ Tilemap definition from topology
- ✅ Player sprite with four-directional movement
- ✅ Camera following player
- ✅ Collision detection
- ✅ Interaction zones per station
- ✅ Factory rendering (zone colors, station sprites, operator sprites)
- ✅ Basic HUD (clock, speed, KPI strip, minimap)
- ✅ Inspector panel (station OEE/metrics, NPC dialogue)
- ⬜ **VERIFY**: `python main.py` launches, player walks, inspector opens on station interact

### Deliverable
Walkable factory. Player navigates floor, sees stations, inspector opens on E.

---

## Phase 3 — Problems and Inspection ⬜ ~15% COMPLETE

### Tasks
- ✅ Problem data model (`problems/problem.py`)
- ✅ YAML catalog loader (`problems/catalog.py`)
- ✅ 25 Tier 1 problems in `data/problems_tier1.yaml`
- ✅ Visibility logic stub (`problems/visibility.py`) — "obvious" problems auto-activate
- ✅ Problem state machine (`problems/state_machine.py`) — states defined
- ⬜ Wire problems into `Factory.__init__`: load catalog, run `evaluate_visibility` each day
- ⬜ Expose active problems on `Factory` so renderer and inspector can read them
- ⬜ Visual problem indicators on factory floor (red ! icon over affected station)
- ⬜ Problem panel in inspector: when station has active problem, show name + symptoms
- ⬜ Investigation logging: each entity the player inspects gets logged to `factory.inspection_log`
- ⬜ Gemba walk tool: show player's inspection path in inspector panel
- ⬜ Diagnostic tool: "Time Observation" — opens a panel showing station cycle time trend
- ⬜ Full visibility logic: "subtle" problems need N prior inspections; "hidden" need maturity threshold
- ⬜ Maturity engine: `maturity_engine.py` `update()` must compute real zone scores from countermeasures + metric stability

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
