# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed or added.

---

## Current Status: Phase 4 ✅ COMPLETE → Phase 5 started (~15%)

Next: dialogue fork UI (choice panel in inspector) → InvestigationSession wired to factory → codex unlock tracking → rollback action

---

## Learning Pillars (design principles — applies to every phase)

This game is a **learning tool** for lean, six sigma, and factory digitalization. Every feature must serve these three pillars. When a task in any phase conflicts with a pillar, the pillar wins.

1. **Learn by doing — safely.** The player must be able to make mistakes without instant hard punishment. Wrong choices reduce effectiveness, surface a lesson, and allow recovery (rollback, retry, NPC redirect). No dead-ends. No game-over from a single bad call. Recovery is always possible — often it *is* the lesson.
2. **NPC-guided decision forks.** Key moments — investigation, 5 Whys, kaizen, countermeasure selection, digitalization choices — are presented as **multiple-choice branches** offered by NPCs: "what should we check next?", "what should we verify?", "what should we implement?". Every fork must include at least one correct option, one plausible-but-wrong option, and optionally a clearly-wrong option. Wrong options still teach: the NPC explains *why* in lean terms, then lets the player try again.
3. **Teach the concept, not just the button.** When a lean, six sigma, or digitalization concept first appears in play (kanban, SMED, SPC, jidoka, MES, digital twin, etc.), introduce it in-fiction through an NPC — one short, skippable explanation. The button comes after the concept, never before it.

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

## Phase 4 — Countermeasures and Scoring 🔧 ~80% COMPLETE

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
- ✅ Automated tests: 77 tests covering all 6 metrics, catalog loader, mismatch calc, apply/resolve flow, wrap_text, decay

### Done (completed this session)
- ✅ **Save/load for full game state**: `to_dict()`/`from_dict()` now covers problems runtime state, active_countermeasures, inspection_log, maturity engine — 14 new round-trip tests all pass
- ✅ **Per-CM modifier tuning**: flat heuristic replaced with 14-category modifier table in `_CM_CATEGORY_MODIFIERS` (`simulation/factory.py`)

**Deliverable:** First fully playable loop. Walk → find → investigate → apply CM → score → earn credits. ✅ COMPLETE

---

## Phase 5 — Guided Learning, Decision Forks, and Mistake Recovery 🔧 ~15% COMPLETE

Drives the three Learning Pillars into concrete mechanics. NPC forks are **deterministic, YAML-driven dialogue trees** — separate from the AI coach (Phase 8). Forks scaffold the *decision*; the coach reflects on it.

### Guided decision flow (NPC dialogue as learning scaffold)

- ✅ Dialogue choice engine: `problems/dialogue.py` — `DialogueChoice`, `InvestigationFork`, `FiveWhysStep`, `ProblemDialogue`, `InvestigationSession` data model; YAML parse; round-trip serialisation
- ✅ `teaches:` tags on all 25 Tier 1 problems in `data/problems_tier1.yaml`
- ✅ `dialogue:` investigation forks on T1-001 through T1-005 (CORRECT / PLAUSIBLE / WRONG with evidence, hint, teaches)
- ✅ `Problem.from_dict()` parses `teaches` and `dialogue` fields; `Problem` carries both
- ✅ 31 new tests covering: YAML parsing, choice tagging, InvestigationSession (rally, concepts, serialisation)
- ⬜ Interaction indicators: visual `[?]` speech-bubble marker above NPCs that have an active investigation fork for the current problem; pulsing ring around stations that have an unread fork — players must always know where to go next
- ⬜ Dialogue fork UI: choice panel rendered inside inspector when NPC has an active fork for this problem
- ⬜ `InvestigationSession` wired to factory state: created on inspector open, stored on `factory`, persisted in save
- ⬜ Score boost on correct fork: `score_feed` field maps to metric bonus (e.g. RCA +1 on CORRECT)
- ⬜ "What should we check next?" fork: NPC offers 3 investigation targets (e.g. supplier log, shift schedule, SPC chart). Correct choice unlocks evidence that feeds RCA/CMP scoring; wrong choices surface a lean-principle hint and let the player try again
- ⬜ 5 Whys guided flow: for root-cause problems, operators walk the player through each "why" as a multiple-choice branch. A wrong answer is explained as a symptom, not a cause, and the player re-picks
- ⬜ Gemba walk decision tree: player chooses who to talk to, what to time, what to measure — each NPC gives a different partial perspective; full picture requires multiple stops
- ⬜ CM selection fork: when the catalog is opened from a specific NPC, the NPC proposes a shortlist (one correct CM, one off-tier CM, one unrelated CM) with a post-selection explanation
- ⬜ DMAIC workflow scaffold: Define → Measure → Analyze → Improve → Control presented as a multi-stage A3-style form with NPC-suggested options at each step; unlocks gradually as the player progresses

### Mistake tolerance and recovery

- ⬜ Rollback action: "Undo this countermeasure" button costs ~25% of the credits earned, restores previous station modifiers, re-activates the problem. Always available
- ⬜ Soft-punishment ladder: first wrong CM on a problem = tip from floor manager; second = reduced credit refund; third = score penalty. Never a game-over
- ⬜ Recovery coach dialogue: after a failed or mismatched CM, a designated NPC offers "want to talk through what happened?" and explains in lean terms why it didn't land
- ⬜ Daily auto-snapshot: auto-save every in-game day so the player can restart a day without losing a week
- ⬜ No hard fail state for bankruptcy: zero credits triggers a "back-to-basics" week — simpler problems, free coach consults, narrative framing of the setback as a learning reset

### Lean / Six Sigma / digitalization learning content

- ⬜ Concept codex: unlockable glossary of lean/SS/digitalization concepts (JIT, Heijunka, Jidoka, Poka-Yoke, SMED, TPM, VSM, SPC, Cp/Cpk, DMAIC, MES, digital Andon, digital twin, etc.). Entry unlocks the first time the concept appears in play
- ⬜ Micro-lesson intros: first time a major concept is relevant, NPC offers an optional 3–5 sentence in-fiction explanation (skippable, one-time per concept)
- ⬜ Digitalization decision forks: explicit choices between analog and digital (paper Andon vs digital, clipboard vs MES, manual vs SCADA data), pros/cons surfaced via NPC before the choice is made
- ⬜ Data-literacy moments: when an SPC chart / Pareto / histogram first appears, NPC walks the player through reading it as a fork ("which bar represents the biggest loss?")
- ✅ Lean principle tags on every Tier 1 problem: all 25 problems in `data/problems_tier1.yaml` have `teaches: [...]` tags — drives future codex unlock and micro-lesson triggers

### Kaizen event structure

- ⬜ Kaizen workshop trigger: an NPC proposes a multi-day kaizen event when 2+ related problems are active in a zone
- ⬜ Team composition choice: player chooses who to invite (operator / supervisor / engineer / quality). Composition affects which hints surface during the workshop
- ⬜ Workshop stages as decision forks: Gemba → Analyze → Experiment → Standardize — each stage has NPC-led option branches with learning consequences
- ⬜ Anti-pattern dialogue: deliberately-wrong options surface realistic failure modes (blame culture, data-faking, over-engineering) so the player sees what *not* to do and why, without losing the workshop

### Scoring that rewards learning (not just luck)

- ⬜ Decision log per problem: track each fork choice (CORRECT/PLAUSIBLE/WRONG) during investigation
- ⬜ Learning Rally bonus: +10% credits on problems solved correctly *after* an initial wrong attempt — rewards recovery + reflection over first-try guesses
- ⬜ Knowledge score: separate from credits. Tracks concepts encountered, codex entries read, correct forks taken. Shown in HUD as a learning-progress indicator distinct from economic progress

**Deliverable:** Every problem-solving loop is a guided, mistake-tolerant learning journey. The player leaves each session having *understood* a lean, six sigma, or digitalization concept, not just clicked through it.

---

## Phase 6 — Tiers 2–4 Content + Final Packaging ⬜ NOT STARTED

Content design happens *after* Phase 5 so every new problem and NPC can immediately use the dialogue-fork YAML schema.

### Content
- ⬜ Tier 2 problem catalog: 15–20 problems (Claude designs, Merijn reviews) — include `teaches:` tags and dialogue fork YAML from the start
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

**Deliverable:** Complete v1 game. All four tiers playable. 70–80 hand-designed problems, all with dialogue forks. Standalone exe.

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
- ✅ UI text sizes: all panels audited and bumped to minimum 14px body / 13px mono (inspector, HUD, catalog, score panel, warning dialog were 10–12px — unreadable at 1280×720)
- ⬜ Tooltip system: hovering over HUD metrics shows a one-line explanation (OEE = Availability × Performance × Quality)
- ⬜ Minimap problem dots: active problem zones shown as coloured dots on the minimap
- ⬜ Settings screen: simulation speed default, display options
- ⬜ Sound cues: basic event sounds for problem discovered, countermeasure applied, score panel open, day end (using pygame mixer; keep subtle)
- ⬜ Colour-blind friendly palette option: toggle accessible colours for problem badges and OEE indicators

**Deliverable:** A game that feels polished enough to show to someone unfamiliar with the project — no raw rectangles, no frozen screen on dialog, no dead-end interactions.

---

## Phase 8 — AI Integration ⬜ ~5% COMPLETE

AI is introduced last so the generator has maximum reference material: all four tiers of hand-designed problems and dialogue fork YAML exist before it runs.

### Done
- ✅ AI module stubs exist (`ai/agent.py`, `ai/coach.py`, `ai/problem_generator.py`, `ai/prompt.py`)

### Remaining
- ⬜ LGM-40 system prompt in `ai/prompt.py` (spec §10.3 persona)
- ⬜ `ai/coach.py`: coach consultation during investigation (75 credits/exchange, Socratic only)
- ⬜ `ai/coach.py`: post-score reflection dialogue (50 credits, does not modify score)
- ⬜ "Ask Coach" button in problem inspector panel → opens coach dialogue UI
- ⬜ Coach dialogue UI: scrollable conversation panel with send field
- ⬜ `ai/problem_generator.py`: generate problem from factory state (500 credits, gated on catalog exhausted); uses existing Tiers 1–4 as reference material for style/quality
- ⬜ Session cost tracking: `factory.session_cost_eur` incremented per API call, shown in HUD
- ⬜ Anthropic SDK with prompt caching (target: <€0.50/hour at average play intensity)
- ⬜ Graceful offline fallback: show "Coach unavailable" if API call fails

**Deliverable:** Game with full AI coaching. Coach on demand. New problems generated from factory state when hand-designed catalog is exhausted. Session cost visible in HUD.

---

## Decisions Made
- **Learning-first design**: game is a teaching tool for lean / six sigma / digitalization. Mistakes must be survivable and recoverable; NPC decision forks are the primary learning scaffold; concepts are introduced in-fiction before mechanics (see Learning Pillars)
- **Phase ordering rationale**: learning mechanics (Phase 5) before content expansion (Phase 6) so the dialogue-fork YAML schema is settled before Tier 2–4 problems are written. AI (Phase 8) last so it generates against a complete reference corpus
- Tier 2–4 problem design: Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; all AI code reads from env var
- Exe build deferred to Phase 6 (asset folders empty now; bat/vbs launchers used during development)
- pygame-ce used as pygame drop-in (installed via pygame_gui dependency)
