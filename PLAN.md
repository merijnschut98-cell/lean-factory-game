# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed or added.

---

## Current Status: Phase 5 — Guided Learning (~50% done)

Next: NPC sprite interactability → concept codex panel → rollback action → mission system data model → WIP/OEE circuit breakers

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

## Phase 4 — Countermeasures and Scoring ✅ COMPLETE
- ✅ `CountermeasureCatalog` + `Countermeasure` dataclass — loads all 79 CMs
- ✅ All six scoring metrics: DQQ, EI, RCA, CMP, LM, CIM (`scoring/metrics.py`)
- ✅ `calculate_all()` orchestrator; `credits_earned()` formula
- ✅ Full mismatch effectiveness table; mismatch warning dialog
- ✅ Countermeasure browser UI: scroll, tier color, prereq indicator
- ✅ Score display panel: 6 metrics with dot bars + total + credits
- ✅ `Factory.apply_countermeasure()`: mismatch mult, station modifier, maturity register, side effects
- ✅ `Factory.resolve_problem()`: scores, awards credits, removes modifiers, RESOLVED state
- ✅ Decay logic (`_tick_decay`): per-CM day timer, removes modifier + maturity on expiry
- ✅ Game loop fully orchestrated: inspector → catalog → warning → apply → resolve → score
- ✅ Save/load for full game state: problems runtime state, active_countermeasures, inspection_log, maturity engine
- ✅ Per-CM modifier tuning: 14-category modifier table in `_CM_CATEGORY_MODIFIERS`
- ✅ 91 automated tests (scoring, catalog, mismatch, apply/resolve, save/load round-trips)

**Deliverable:** First fully playable loop. Walk → find → investigate → apply CM → score → earn credits. ✅

---

## Phase 5 — Guided Learning, Decision Forks, and Mistake Recovery 🔧 ~35% COMPLETE

NPC forks are **deterministic, YAML-driven dialogue trees** — separate from the AI coach (Phase 8). Forks scaffold the *decision*; the coach reflects on it.

### Done

- ✅ `problems/dialogue.py`: `DialogueChoice`, `InvestigationFork`, `FiveWhysStep`, `ProblemDialogue`, `InvestigationSession` with Learning Rally detection and round-trip serialisation
- ✅ `teaches:` tags on all 25 Tier 1 problems
- ✅ `dialogue:` investigation forks authored for T1-001 through T1-025 (3 choices each: CORRECT / PLAUSIBLE / WRONG with evidence, hint, teaches, score_feed)
- ✅ `Problem` carries `teaches` and `dialogue`; loader parses both
- ✅ `factory.investigation_sessions` dict + `get_or_create_session()`; persisted in save
- ✅ Pulsing `[?]` interaction indicator on stations and role-desks with an unread fork (`factory_renderer.py`)
- ✅ Dialogue fork UI in inspector: NPC prompt → `[1][2][3]` choices → reveal evidence/hint → `[Enter]` continue
- ✅ `InvestigationSession.choices_made` tracks decision log per problem
- ✅ `ui/fonts.py`: single source for all UI font sizes (mono 13px, body 14px, title 16px)
- ✅ 31 tests covering dialogue engine (108 total)

### Bugs found while coding — fix before continuing

- ✅ **Role-name mismatch**: fixed — `world_data.py` desk now uses `"Quality Lead"` matching NPC sprite, NPC_LINES, and T1-003 dialogue
- ✅ **Inspector panel overflow**: fixed — inspector now renders to a 2400px tall off-screen surface and blits a scrollable window; mouse wheel + arrow keys scroll; scroll indicator shown when content exceeds screen height
- ⬜ **NPC sprites not interactable**: `player.detect_facing(OBJECTS)` detects desks/machines only — walking up to an NPC sprite does nothing. Need to include NPCS in facing detection so players can interact with NPCs directly, not just their desks.

### Guided decision flow — remaining

- ✅ **Wire `score_feed` into scoring**: correct fork choice with `score_feed: "RCA"` now applies +1 bonus (capped at 5) to that metric in `resolve_problem()`
- ✅ **Wire Learning Rally bonus into scoring**: `InvestigationSession.earned_rally_bonus` now applies +10% to `credits_earned` in `resolve_problem()`
- ✅ **Dialogue forks for all 25 Tier 1 problems**: all problems have authored investigation forks (3 choices each: CORRECT / PLAUSIBLE / WRONG)
- ⬜ **`teaches:` tags on all 79 countermeasures**: problems have tags; CMs need them too so codex unlocks fire when a CM is applied, not just when a fork is triggered
- ⬜ 5 Whys guided flow: author `five_whys:` sections in YAML for root-cause problems (data model already supports it); render as follow-up fork after investigation fork is complete
- ⬜ Gemba walk decision tree: player chooses who to talk to, what to time, what to measure — each NPC gives a different partial perspective; full picture requires multiple stops
- ⬜ CM selection fork: when catalog opens from a specific NPC, NPC proposes shortlist (correct / off-tier / unrelated) with post-selection explanation
- ⬜ DMAIC workflow scaffold: Define → Measure → Analyze → Improve → Control as multi-stage A3 form; unlocks gradually

### Safety net, pacing governor, and stop-gaps

The game has no lose state and no timers. Urgency is created by KPI degradation and NPC ambient comments, not countdown clocks. The following safeguards ensure the game stays doable regardless of how the player plays.

**Problem / mission throttle**
- ⬜ **Active problem cap**: no more than 3 active problems visible at once; new problems queue and activate only when the player resolves one (mission system controls this)
- ⬜ **Severity cap**: no more than 1 CRITICAL problem active at any time. If a second critical would trigger, it is held at HIGH severity until the first is resolved
- ⬜ **Side-effect suppression**: if the player is already at the active problem cap, harmful side-effects from mismatched CMs are downgraded to warnings rather than spawning new problems
- ⬜ **Mission flood cap**: no more than 2 missions offered simultaneously. New missions queue behind active ones. Player is never overwhelmed with simultaneous urgency

**Simulation overflow circuit breakers**
- ⬜ **WIP ceiling**: if total live WIP exceeds 100 units (well above normal ~50), the simulation automatically steps down to 0.5× speed and a team leader NPC appears with a one-line ambient comment: "Lines are backing up — something's not flowing." The slow-down prevents a runaway WIP spiral
- ⬜ **OEE floor**: if plant OEE drops below 20% (severe degradation), a "crisis stabilizer" event fires — a helper NPC (Lean Coach or Maintenance Lead) temporarily takes ownership of the worst station, applying a small free corrective modifier for 3 in-game days, giving the player time to react
- ⬜ **FTR floor**: if plant FTR drops below 60%, Final QA line halts temporarily with a narrative framing: "We've had to pause final test — too many failures coming through." This is not a penalty; it is a pause that creates urgency without crashing the game
- ⬜ **Credit floor**: credits never go below zero. Negative-credit events (wrong CM penalties, etc.) are capped at zero. The player can always take action.

**No timers rule**
- ⬜ **No mission timers**: missions have no deadlines, countdowns, or expiry. Urgency comes only from KPI degradation (the simulation naturally worsening) and NPC ambient comments — never from a visible clock
- ⬜ **No session time pressure**: the game can be paused at any point; closing the game saves state and the player resumes exactly where they left off
- ⬜ **Pace indicators only**: the HUD may show "days since problem first appeared" for context, but this is informational — it never triggers a penalty or a timer-based event

### Mission system

Problems do not all surface at once. The player discovers them through **missions** — thematic clusters of 2–5 related problems unlocked by talking to NPCs, observing dashboards, or noticing floor conditions. The mission system provides hints (not answers) that guide the player toward the next observation without removing the discovery experience.

- ⬜ **Mission data model**: `Mission` class with id, title, description, trigger conditions, problem_ids (the cluster), hint sequence, and completion condition. Stored in `data/missions_tier1.yaml`
- ⬜ **Mission trigger types**: (a) NPC conversation trigger — talking to a specific NPC unlocks a mission; (b) floor observation trigger — player inspects a specific station/zone; (c) KPI threshold trigger — OEE / FTR drops below a threshold; (d) day trigger — mission becomes available after N in-game days
- ⬜ **Progressive problem visibility**: replace the current "all obvious problems active on Day 1" model — obvious problems only activate when their parent mission is active. The player starts with 2–3 problems visible; new missions unlock as earlier ones progress
- ⬜ **Hint system**: active mission emits context-appropriate hints shown as NPC ambient dialogue or a subtle HUD nudge (not a tooltip or instruction popup). Example: "The Team Leader in Z2 looked worried this morning" or "Scheduler mentioned the dock numbers don't add up" — hints that point toward the right zone/person without naming the problem
- ⬜ **Mission sources** — missions can originate from multiple NPCs depending on the theme:
  - **Plant Manager** (the player's own desk) — strategic missions: "We're losing ground on quality. I need you to find out why."
  - **Lean Coach (Black Belt)** — a new NPC not yet in world_data; gives structured kaizen / six sigma missions with a more methodical framing: "Let's run a DMAIC on the testing zone."
  - **Floor NPCs** (team leaders, quality lead, scheduler, IT engineer, maintenance lead) — operational missions triggered by specific pain points they observe
- ⬜ **Lean Coach NPC**: add a Black Belt / Lean Coach NPC to the world (office wing, near the Plant Manager desk); this NPC is the game's lean expert character — more formal than floor NPCs, more structured in their guidance, initiates kaizen workshops and multi-problem missions
- ⬜ **Mission briefing dialogue**: missions start with an NPC inviting the player to investigate: "There's something off in Component Prep — the numbers look fine but the floor feels wrong. Can you take a look?" — always framed as an invitation, never a command
- ⬜ **No mission timers**: missions have no deadlines or expiry dates. A mission stays open until the player resolves it. The only "pressure" is the factory getting slightly worse over time as problems compound — this is natural simulation consequence, not a countdown
- ⬜ **Mission completion**: resolved when the key problem(s) in the cluster are resolved. Triggers a short debriefing conversation with the NPC who started it
- ⬜ **Tier 1 mission pack** (5 missions, covers all 25 Tier 1 problems):
  - "The Invisible Waste" — 5S and workplace problems (T1-001, T1-002, T1-013, T1-018)
  - "The Quality Gap" — quality and measurement (T1-003, T1-008, T1-010, T1-014, T1-022)
  - "The Flow Problem" — flow and scheduling (T1-006, T1-009, T1-011, T1-016, T1-017)
  - "The Knowledge Risk" — people and skills (T1-005, T1-007, T1-012, T1-019, T1-021)
  - "The Hidden Information" — data and process transparency (T1-004, T1-015, T1-020, T1-023, T1-024, T1-025)
- ⬜ **Mission HUD indicator**: small mission title and hint shown in HUD corner when a mission is active; does not show when no mission is active (no overwhelming quest tracker)
- ⬜ **Mission persistence**: active mission state and progress saved in `factory.to_dict()`

### Follow-up and verification loop (PDCA)

The game models the full Plan → Do → Check → Act cycle. Currently only Plan (investigation fork) and Do (apply CM) are implemented. Check and Act are missing — and they are the most important learning moments.

- ⬜ **Follow-up indicator**: N in-game days after a CM is applied, a pulsing clock badge (`↻`) appears on the station prompting the player to return and observe the effect. Stays until the player re-inspects.
- ⬜ **Effect verification fork**: when player re-inspects a station post-CM, the NPC offers a "Check" fork: "What do you observe now?" — CORRECT identifies the specific measurable improvement; PLAUSIBLE acknowledges something changed but misses the mechanism; WRONG declares the problem solved without checking residual issues. This directly boosts the CIM (Continuous Improvement Mindset) score.
- ⬜ **Standardize action**: if the follow-up fork is resolved CORRECT, NPC offers "Standardize this practice?" — accepting locks the CM benefit permanently (overrides decay) and unlocks the next-tier CM category for that zone
- ⬜ **Adjust action**: if follow-up reveals the CM had less effect than expected, NPC offers to re-open the root-cause investigation — player picks a different fork path without losing all credits (partial score preserved, Learning Rally bonus still possible)
- ⬜ **Daily management board follow-up**: decisions made at the Ops Board or during a Kaizen event generate a "verify on floor" indicator on the relevant station — player must close the loop by walking to the station and observing
- ⬜ **PDCA completion bonus**: completing all four phases (Plan/investigate → Do/apply → Check/observe → Act/standardize-or-adjust) on a single problem awards a bonus multiplier on credits and registers the full cycle in the knowledge score

### Mistake tolerance and recovery

- ⬜ Rollback action: "Undo this countermeasure" — costs ~25% of credits earned, restores station modifiers, re-activates problem. Show as `[U]` hint in inspector when CM is applied
- ⬜ Soft-punishment ladder: first wrong CM = floor manager tip (no credit loss); second = 10% refund penalty; third = score penalty. Never a game-over
- ⬜ Recovery coach dialogue: after failed/mismatched CM, designated NPC offers "want to talk through what happened?" and explains in lean terms
- ⬜ Daily auto-snapshot: currently auto-saves every 5 real minutes — change to trigger on every in-game day boundary so player can always restart from yesterday
- ⬜ No hard fail state for bankruptcy: zero credits triggers "back-to-basics" week — simpler problems, free coach consults, narrative framing as learning reset

### Lean / Six Sigma / digitalization learning content

- ✅ `factory.discovered_concepts` registry: set on factory; populated from fork choices (main.py) and station inspections (log_inspection); persisted in save/load
- ⬜ Concept codex panel: accessible via `[K]` key; lists all discovered concepts with short definition, unlocked per `discovered_concepts`; locked entries shown as `???`
- ⬜ Micro-lesson intros: first time a concept appears (via `discovered_concepts` check), NPC offers optional 3–5 sentence in-fiction explanation (skippable, one-time per concept)
- ⬜ Digitalization decision forks: explicit analog-vs-digital choice forks (paper Andon vs digital, clipboard vs MES); pros/cons surfaced via NPC
- ⬜ Data-literacy moments: when SPC chart / Pareto / histogram first appears, NPC walks through reading it as a fork

### Kaizen event structure

- ⬜ Kaizen workshop trigger: NPC proposes multi-day kaizen when 2+ related problems active in a zone
- ⬜ Team composition choice: player chooses who to invite (operator / supervisor / engineer / quality) — composition affects which hints surface
- ⬜ Workshop stages as forks: Gemba → Analyze → Experiment → Standardize — each with NPC-led branches
- ⬜ Anti-pattern dialogue: wrong choices surface realistic failure modes (blame culture, data-faking, over-engineering) without losing the workshop

### Scoring that rewards learning

- ✅ Decision log: `InvestigationSession.choices_made` tracks every fork choice per problem
- ⬜ Learning Rally bonus applied: wire `earned_rally_bonus` → +10% credits in `resolve_problem()` (tracked, not yet wired)
- ⬜ Knowledge score in HUD: `len(factory.discovered_concepts)` shown as a learning-progress counter distinct from economic credits
- ⬜ Score boost from correct fork: `score_feed` field on `DialogueChoice` maps to +1 on named metric in `resolve_problem()`

**Deliverable:** Every problem-solving loop is a guided, mistake-tolerant learning journey. Player leaves each session having *understood* a lean concept.

---

## Phase 6 — Tiers 2–4 Content + Final Packaging ⬜ NOT STARTED

Content design happens *after* Phase 5 so every new problem and NPC can immediately use the settled dialogue-fork YAML schema (including `teaches:`, `dialogue:`, and `five_whys:` from day one).

### Content
- ⬜ Tier 2 problem catalog: 15–20 problems (Claude designs, Merijn reviews) — `teaches:` + `dialogue:` forks included from the start
- ⬜ Tier 3 problem catalog: 15–20 problems
- ⬜ Tier 4 problem catalog: 10–15 problems
- ⬜ Tier progression visibility verified across all four tiers
- ⬜ Tier 5 stub in UI ("Coming in v2" — locked)
- ⬜ Specialist hiring system (credits → hire → zone OEE bonus)
- ⬜ Full save/load for all new state (Tiers 2–4 problems, specialists, CM history)

### Packaging
- ⬜ Add icon (`assets/icon.ico`)
- ⬜ Populate `assets/sprites/`, `assets/tilesets/`, `assets/sounds/`
- ⬜ Update `lean_factory.spec` for populated assets
- ⬜ Build `lean_factory.exe` with PyInstaller
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

- ⬜ Scrollable inspector panel: panels that exceed screen height scroll with mouse wheel / arrow keys (urgent: dialogue fork section already pushes panel beyond 720px on some stations)
- ⬜ Non-blocking toast notifications: CM decay warning, new problem visible, credits earned — timed banner, never freeze gameplay
- ⬜ Keyboard shortcut reference: `[?]` or `[F1]` shows overlay listing all controls
- ⬜ Problem count HUD badge: active problem count visible at all times (e.g. "⚠ 12 active")
- ⬜ Maturity/phase progress bar in HUD: zone scores visualised at a glance

### NPC Interactions

- ⬜ Multi-line NPC dialogue: NPCs have 3–5 rotating lines that change as factory matures or problems are solved
- ⬜ NPC awareness: operators comment on nearby active problems when inspected ("that shelf's been a mess for weeks")
- ⬜ Character portraits: small illustrated avatar per NPC role shown in the inspector panel
- ⬜ "Walk-up" animation: brief highlight / icon appears above NPC head when player is in range

### General UX

- ⬜ No action should block gameplay for more than 1 second: all dialogs dismissible with Esc or Enter immediately
- ✅ UI text sizes: all panels bumped to minimum 14px body / 13px mono via `ui/fonts.py`
- ⬜ Tooltip system: hovering over HUD metrics shows a one-line explanation (OEE = Availability × Performance × Quality)
- ⬜ Minimap problem dots: active problem zones shown as coloured dots on the minimap
- ⬜ Settings screen: simulation speed default, display options
- ⬜ Sound cues: basic event sounds (problem discovered, CM applied, score panel open, day end)
- ⬜ Colour-blind friendly palette option: toggle accessible colours for problem badges and OEE indicators

**Deliverable:** A game that feels polished enough to show to someone unfamiliar with the project — no raw rectangles, no frozen screen on dialog, no dead-end interactions.

---

## Phase 8 — AI Integration ⬜ ~5% COMPLETE

AI is introduced last so the generator has maximum reference material: all four tiers of hand-designed problems and dialogue fork YAML exist before it runs.

### Done
- ✅ AI module stubs (`ai/agent.py`, `ai/coach.py`, `ai/problem_generator.py`, `ai/prompt.py`)

### Remaining
- ⬜ LGM-40 system prompt in `ai/prompt.py` (spec §10.3 persona)
- ⬜ `ai/coach.py`: Socratic coach consultation during investigation (75 credits/exchange)
- ⬜ `ai/coach.py`: post-score reflection dialogue (50 credits, does not modify score)
- ⬜ "Ask Coach" button in inspector → coach dialogue UI (scrollable conversation panel + send field)
- ⬜ `ai/problem_generator.py`: generate problem from factory state (500 credits, gated on catalog exhausted); uses Tiers 1–4 YAML as style/quality reference
- ⬜ Session cost tracking: `factory.session_cost_eur` incremented per API call, shown in HUD
- ⬜ Anthropic SDK with prompt caching (target: <€0.50/hour at average play intensity)
- ⬜ Graceful offline fallback: "Coach unavailable" if API call fails

**Deliverable:** Game with full AI coaching. Coach on demand. New problems generated from factory state when hand-designed catalog is exhausted. Session cost visible in HUD.

---

## Decisions Made
- **Learning-first design**: game is a teaching tool for lean / six sigma / digitalization. Mistakes must be survivable and recoverable; NPC decision forks are the primary learning scaffold; concepts are introduced in-fiction before mechanics (see Learning Pillars)
- **Phase ordering rationale**: learning mechanics (Phase 5) before content expansion (Phase 6) so the dialogue-fork YAML schema is settled before Tier 2–4 problems are written. AI (Phase 8) last so it generates against a complete reference corpus
- **NPC interaction model**: players interact with NPCs via their associated role-desks (objects with `role` field), not by clicking NPC sprites directly. NPC sprites are visual only in Phase 2–5; sprite interactability is a Phase 7 task
- **PDCA as the core game loop**: every problem-solving sequence follows Plan (investigation fork) → Do (apply CM) → Check (follow-up verification fork) → Act (standardize or adjust). The game is only teaching lean if all four phases are playable — not just Plan + Do.
- **Mission system as the discovery layer**: problems are not listed on a quest tracker — they are discovered through missions triggered by NPC conversations, floor observation, and KPI signals. The mission system hints, never instructs. The player must still figure out what is wrong and why.
- **No timers, no game-over**: the game has no countdown timers, no deadline pressure, and no lose state. Urgency comes from the simulation naturally degrading when problems go unresolved. Active problem cap (max 3, max 1 critical) and simulation circuit breakers (WIP ceiling, OEE floor, FTR floor) ensure the game stays playable regardless of player pace.
- **Doable pace by design**: the player is never overwhelmed. New problems queue behind active ones. Overflow safeguards slow the simulation and provide NPC assistance before situations become unmanageable.
- Tier 2–4 problem design: Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; all AI code reads from env var
- Exe build deferred to Phase 6 (asset folders empty now; bat/vbs launchers used during development)
- pygame-ce used as pygame drop-in (installed via pygame_gui dependency)
