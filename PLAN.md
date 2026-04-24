# Lean Factory — Build Plan

Spec reference: `Lean_Factory_v2.0_Specification.docx`
Update this file every time a task is completed or added.

---

## Current Status: Phase 5 Complete ✅ → Phase 6 Content

Next: Tier 2 problem catalog (15–20 problems with dialogue forks) → Tier 3 → Tier 4

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
- ✅ Shift-to-run: holding Shift moves at 2.5× speed (RUN_MULT = 2.5 in player.py)
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
- ✅ 138 automated tests (scoring, catalog, mismatch, apply/resolve, save/load, missions, rollback)

**Deliverable:** First fully playable loop. Walk → find → investigate → apply CM → score → earn credits. ✅

---

## Phase 5 — Guided Learning, Decision Forks, and Mistake Recovery 🔧 ~75% COMPLETE

NPC forks are **deterministic, YAML-driven dialogue trees** — separate from the AI coach (Phase 8). Forks scaffold the *decision*; the coach reflects on it.

### Done

- ✅ `problems/dialogue.py`: `DialogueChoice`, `InvestigationFork`, `FiveWhysStep`, `ProblemDialogue`, `InvestigationSession` with Learning Rally detection and round-trip serialisation
- ✅ `teaches:` tags on all 25 Tier 1 problems
- ✅ `dialogue:` investigation forks on all 25 Tier 1 problems (CORRECT / PLAUSIBLE / WRONG with evidence, hint, teaches, score_feed)
- ✅ `Problem` carries `teaches` and `dialogue`; loader parses both
- ✅ `factory.investigation_sessions` dict + `get_or_create_session()`; persisted in save
- ✅ Pulsing `[?]` interaction indicator on stations and role-desks with an unread fork
- ✅ Dialogue fork UI in inspector: NPC prompt → `[1][2][3]` choices → reveal evidence/hint → `[Enter]` continue
- ✅ `score_feed` wired: correct fork choice applies +1 bonus (capped at 5) to named scoring metric
- ✅ Learning Rally bonus wired: +10% credits when player solves after an initial wrong attempt
- ✅ `InvestigationSession.choices_made` tracks decision log per problem
- ✅ `factory.discovered_concepts` registry: populated from fork choices and station inspections; persisted
- ✅ Concept codex panel: `[K]` opens `ui/codex_panel.py` — 62 concepts; unlocked with definitions, locked as `???`
- ✅ Rollback action: `[U]` in inspector — costs 25% of base credit, re-activates problem, clears session
- ✅ NPC sprites interactable: all NPCs have `w=1, h=1` + `label`; `detect_facing(OBJECTS + NPCS)` — walking up to any NPC opens inspector
- ✅ Role-name mismatch fixed: all sources now use `"Quality Lead"` consistently
- ✅ Inspector scroll: mouse wheel + arrow keys scroll; 2400px off-screen surface; scroll indicator
- ✅ `ui/fonts.py`: single source for all UI font sizes (mono 13px, body 14px, title 16px)
- ✅ Mission system: `problems/mission.py` — `Mission`, `MissionTrigger` with direction field; YAML loader
- ✅ Tier 1 mission pack: 5 missions in `data/missions_tier1.yaml` (auto/npc/kpi/day/inspect triggers)
- ✅ Progressive problem visibility: problems gated behind active missions; sorted by severity; cap enforced
- ✅ Active problem cap: max 3 active, max 1 critical (enforced in `visibility.py`)
- ✅ Mission flood cap: max 2 active missions at once
- ✅ WIP ceiling circuit breaker: WIP > 100 auto-slows simulation to 1×; events capped at 50
- ✅ OEE floor circuit breaker: OEE < 20% logs a critical event (no station mutation — avoids accumulation)
- ✅ Mission state persisted in `factory.to_dict()`/`from_dict()`
- ✅ `active_mission_count` property on Factory eliminates duplicated sum
- ✅ 30 new tests: mission triggers, completion, NPC activation, rollback, visibility caps (138 total)

### Remaining — guided decision flow

- ✅ **`teaches:` tags on all 79 countermeasures**: `_CM_TEACHES_MAP` in `countermeasure.py`; `factory.discover(cm.teaches)` called in `apply_countermeasure`
- ✅ **5 Whys guided flow**: `five_whys:` YAML authored for T1-003/006/008/012 (3 steps each, 3 choices per step); session tracking + inspector rendering; follows investigation fork completion
- ⬜ **Gemba walk decision tree**: player chooses who to talk to, what to time, what to measure — each NPC gives a different partial perspective; full picture requires multiple stops
- ⬜ **CM selection fork**: when catalog opens from a specific NPC, NPC proposes shortlist (correct / off-tier / unrelated) with post-selection explanation
- ⬜ **DMAIC workflow scaffold**: Define → Measure → Analyze → Improve → Control as multi-stage A3 form; unlocks gradually

### Remaining — mission system

- ✅ **Mission HUD indicator**: small active mission title + current hint shown in a corner of the HUD when a mission is active; nothing shown when no mission is active
- ✅ **Mission briefing dialogue**: when a mission activates via NPC interaction, the NPC delivers the narrative briefing as a short dialogue exchange (framed as invitation, never a command)
- ✅ **Mission ordering / availability cap**: `visible_after:` prerequisite field on `Mission` gates each mission behind a predecessor. Chain: M-T1-001 (auto) → M-T1-002 + M-T1-003 (need M-T1-001 done) → M-T1-004 (needs M-T1-002) → M-T1-005 (needs M-T1-003). Only M-T1-001 surfaces on day 1; subsequent missions unlock progressively.
- ✅ **Mission completion notification**: source NPC panel shows "MISSION COMPLETE" + per-mission debrief text when mission is completed (`_MISSION_DEBRIEFS` dict in inspector)
- ⬜ **Lean Coach NPC**: add a Black Belt / Lean Coach character to the office wing; delivers kaizen and DMAIC missions with structured methodical framing; distinct from operational floor NPCs
- ✅ **NPC awareness hints**: `_NPC_AWARENESS` dict in inspector; 12 (role, mission_id) entries; ambient line replaces static NPC quote when a nearby mission is active

### Remaining — safety nets

- ✅ **FTR floor circuit breaker**: FTR < 60% logs `ftr_floor` event and slows simulation to 1× (consistent with WIP ceiling pattern)
- ✅ **Side-effect suppression**: `_active_problem_cap_reached` guard in `apply_countermeasure` — harmful side-effects suppressed when at cap
- ✅ **Daily auto-snapshot**: currently auto-saves every 5 real minutes — change to trigger on in-game day boundary so player can always restart from yesterday's state
- ⬜ **No hard fail state for bankruptcy**: zero credits triggers "back-to-basics" week — simpler problems, free coach consults, narrative framing as learning reset

### Remaining — mistake tolerance

- ✅ Soft-punishment ladder: wrong CM tip shown in inspector; count=2 → 10% penalty; count=3 → 20% penalty (capped at 40%). Never game-over
- ✅ Recovery coach dialogue: source NPC shows "CM REVIEW" section with escalating advice when `wrong_cm_count >= 1` on a mission problem

### Remaining — learning content

- ✅ Micro-lesson intros: first time a concept appears via `discovered_concepts`, NPC offers optional 3–5 sentence in-fiction explanation (skippable, one-time per concept)
- ✅ Knowledge score in HUD: `CONCEPTS X / 62` shown in the KPI strip alongside OUTPUT/OEE/WIP/FTR/CREDITS
- ⬜ Digitalization decision forks: explicit analog-vs-digital choice forks (paper Andon vs digital, clipboard vs MES)
- ⬜ Data-literacy moments: when SPC chart / Pareto / histogram first appears, NPC walks through reading it as a fork

### Remaining — PDCA verification loop

The game currently implements Plan (investigation fork) and Do (apply CM). Check and Act are missing.

- ✅ **Follow-up indicator**: 3 days after CM applied, pulsing green `↻` badge appears above station; clears on resolve. `factory.follow_up_due_stations` property; rendered in `_draw_followup_badges`
- ✅ **Effect verification fork**: 3 days post-CM, `_should_show_verification` gates a generated PDCA-Check fork; `build_verification_fork` generates per-category NPC prompt + 3 choices; CORRECT boosts CIM via score_feed; 37 new tests
- ✅ **Standardize action**: `[S]` after correct verification locks CM decay permanently; `session.standardized` flag; `factory.standardize_cm()`
- ✅ **Adjust action**: `[A]` after wrong/plausible verification resets `verification_complete` + clears `verification_choices` for retry; `factory.adjust_verification()`
- ✅ **PDCA completion bonus**: +15% credits when all four phases done (fork + verification correct + standardized); stacks with rally bonus

### Remaining — kaizen events

- ⬜ Kaizen workshop trigger: NPC proposes multi-day kaizen when 2+ related problems active in a zone
- ⬜ Team composition choice: player chooses who to invite — affects which hints surface
- ⬜ Workshop stages as forks: Gemba → Analyze → Experiment → Standardize
- ⬜ Anti-pattern dialogue: wrong choices surface realistic failure modes without losing the workshop

**Deliverable:** Every problem-solving loop is a guided, mistake-tolerant learning journey. Player leaves each session having *understood* a lean concept.

---

## Phase 6 — Tiers 2–4 Content + Final Packaging ⬜ NOT STARTED

Content design happens *after* Phase 5 so every new problem uses the settled dialogue-fork YAML schema (`teaches:`, `dialogue:`, `five_whys:`) from day one.

### Content
- ✅ Tier 2 problem catalog: 15 problems in `data/problems_tier2.yaml` (session 2026-04-24) — all have `teaches:` + `dialogue:` investigation forks; T2-001/003/005/008/015 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Codex fully covers Tiers 1+3: 164 concepts, all 161 teaches tags mapped (session 2026-04-24)
- ✅ Tier 3 problem catalog: 15 problems in `data/problems_tier3.yaml` (session 2026-04-24) — all have `teaches:` + `dialogue:`; T3-002/007/009 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Tier 4 problem catalog: 12 problems in `data/problems_tier4.yaml` (session 2026-04-24) — SPC/MSA/DMAIC/FMEA/DOE/8D/regression/reliability; T4-002/004/012 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Codex fully covers Tiers 1–4: 197 concepts, all 196 teaches tags mapped (session 2026-04-24)
- ⬜ Tier progression visibility verified across all four tiers
- ⬜ Tier 5 stub in UI ("Coming in v2" — locked)
- ⬜ Specialist hiring system (credits → hire → zone OEE bonus)
- ⬜ Full save/load for all new state (Tiers 2–4 problems, specialists, CM history)

### Packaging
- ⬜ Fix `requirements.txt`: replace `pygame>=2.5.0` with `pygame-ce>=2.5.3` to prevent install conflict (pygame and pygame-ce share the same namespace; plain pygame must not be installed alongside)
- ⬜ Add icon (`assets/icon.ico`)
- ⬜ Populate `assets/sprites/`, `assets/tilesets/`, `assets/sounds/`
- ⬜ Update `lean_factory.spec` for populated assets
- ⬜ Build `lean_factory.exe` with PyInstaller
- ⬜ Test standalone exe on a clean machine (no Python installed)
- ⬜ Create installer or zip distribution

### Architecture debt (tracked from skills audit 2026-04-23)
- ⬜ **`ui/inspector.py` split** (819 lines → ~250 + ~550): extract all `_draw_*` methods + module-level content dicts into `ui/inspector_drawing.py` as `InspectorDrawMixin`; `Inspector` inherits it. No behavior change.
- ⬜ **`simulation/factory.py` split** (686 lines → ~350 core + extracted engines): extract `apply_countermeasure`/`rollback` → `simulation/countermeasure_engine.py`; mission triggers → `simulation/mission_engine.py`. Factory becomes a cleaner orchestrator.

**Deliverable:** Complete v1 game. All four tiers playable. 70–80 hand-designed problems, all with dialogue forks. Standalone exe.

---

## Phase 7 — UI Polish, Progression, and Story ⬜ NOT STARTED

> **Design note (from session 2026-04-23):** Current UI is functional but not inviting — raw rectangles, low contrast, no visual hierarchy between panels and world. Phase 7 should feel like a different product. The deliverable is a game someone unfamiliar with the project can sit down with and find visually clear, progression they can feel, and a story that makes them care. Defer all visual work until Phase 6 content is done.

> **Graphics priority (added 2026-04-24):** The current visuals — solid-colour rectangles for player and stations, flat HUD panels, no sprite art — need a full overhaul before the game can be shown to anyone outside the project. Phase 7 must replace all raw rectangles with illustrated sprites, give each zone a distinct visual identity, and bring inspector panels and HUD up to a modern game standard. This is non-negotiable for the Phase 7 deliverable.

### Narrative and Story

The player is a newly hired **Continuous Improvement Specialist** at NovaGlide. Day 1 they walk into a plant that produces hoverboards but struggles with quality, flow, and hidden waste. Over the course of Tiers 1–4 they transform it into a benchmark operation. The story provides motivation: people to care about, a plant worth saving, and a sense of pride when it works.

- ⬜ **Opening narrative**: Day 1 cutscene / text scroll — player character arrives, Plant Manager (you) greets them, gives first mission. Sets tone: this is a learning journey, not a battle
- ⬜ **NPC character arcs**: each source NPC (Team Leader, Quality Lead, Scheduler, HR Manager, IT Engineer) has a 3-stage story arc — skeptic → engaged → champion — revealed as their mission cluster completes
- ⬜ **Day summary narrative line**: end-of-day card includes a one-sentence flavour from an NPC reflecting on the day ("The rework pile shrank today. First time in weeks." — Quality Lead)
- ⬜ **Milestone events**: at key progression points (first problem resolved, first mission complete, first Tier 2 CM, all Tier 1 done), a short congratulatory line from Plant Manager

### Progression and Leveling

- ⬜ **CI Level system**: player earns XP from: resolving problems (base), correct fork choices (+bonus), completing 5 Whys (+bonus), mission completions (big bonus), codex concepts unlocked. Level displayed in HUD (e.g. "Lvl 4 — Lean Practitioner"). Level names: Observer → Practitioner → Analyst → Expert → Black Belt → Sensei
- ⬜ **Mission progress tracker**: a persistent panel or screen (hotkey `[M]`) listing all missions — status (locked / available / active / complete), problems solved count, source NPC icon
- ⬜ **KPI dashboard screen**: `[Tab]` or `[F2]` opens a full-screen dashboard — OEE/FTR/WIP/OUTPUT trend charts (last 30 days), mission completion bars, concept coverage pie, CI Level XP bar
- ⬜ **Tier progression bar**: visual indicator in HUD or dashboard showing progress toward Tier 2 unlock (X/10 Tier 1 problems resolved), Tier 3, Tier 4
- ⬜ **Achievement system**: hidden milestones that pop up as toast notifications: "First Gemba", "5S Complete", "Learning Rally", "Root Cause Found". No rewards — just recognition
- ⬜ **Problem history log**: `[H]` opens a log of all resolved problems with day, CM applied, score — the player's personal improvement record

### Navigation and Floor

- ⬜ Animated player sprite: 4-directional walk cycle (replace solid rectangle)
- ⬜ Station sprites with more visual detail: machine bodies, screens, conveyor belts per zone type
- ⬜ Animated flow lines between stations: moving dots showing material in transit
- ⬜ WIP pile visual: small stacked-unit icons near a station when `wip_in` is high
- ⬜ Andon light on station sprite when the Andon countermeasure is active (blinking amber/red)
- ⬜ Problem indicator animation: pulsing ! badge instead of static (draws the eye)
- ⬜ Problem discovery notification: non-blocking toast in top-left when a new problem surfaces

### Screens

- ✅ **Start screen** *(2026-04-23)*: `ui/menu.py` — `start_screen()` with [N] New Game / [C] Continue (greyed if no save) / [Q] Quit. Blocks game loop entry.
- ✅ **Save/load/reset via pause menu** *(2026-04-23)*: `[Esc]` → `pause_menu()` overlay with Resume / Save / Load / New Game (with confirmation prompt) / Quit. New Game deletes save file after confirmation.
- ⬜ Day summary popup: non-blocking end-of-day card showing output, OEE, WIP, FTR delta vs yesterday
- ⬜ Pause screen overlay: `[Esc]` opens overlay with Resume / Save / Load / Quit options; visual darkening + "PAUSED" indicator

### Inspector and Panels

- ✅ Scrollable inspector panel: mouse wheel + arrow keys scroll; 2400px off-screen surface with scroll indicator
- ⬜ Non-blocking toast notifications: CM decay warning, new problem visible, credits earned — timed banner, never freeze gameplay
- ⬜ Keyboard shortcut reference: `[?]` or `[F1]` shows overlay listing all controls (currently undocumented: E=inspect, C=apply CM, R=resolve, U=rollback, K=codex, Tab=speed, P=pause, Shift=run)
- ⬜ Problem count HUD badge: active problem count visible at all times (e.g. "⚠ 3 active")
- ⬜ Maturity/phase progress bar in HUD: zone scores visualised at a glance

### NPC Interactions

- ⬜ Multi-line NPC dialogue: NPCs have 3–5 rotating lines that change as factory matures or problems are solved
- ⬜ NPC awareness: operators comment on nearby active problems when inspected ("that shelf's been a mess for weeks")
- ⬜ Character portraits: small illustrated avatar per NPC role shown in the inspector panel
- ⬜ "Walk-up" animation: brief highlight / icon appears above NPC head when player is in range

### General UX

- ⬜ No action should block gameplay for more than 1 second: all dialogs dismissible with Esc or Enter immediately
- ✅ UI text sizes: all panels bumped to minimum 14px body / 13px mono via `ui/fonts.py`
- ✅ Shift-to-run: player holds Shift for 2.5× movement speed
- ⬜ Tooltip system: hovering over HUD metrics shows a one-line explanation (OEE = Availability × Performance × Quality)
- ⬜ Minimap problem dots: active problem zones shown as coloured dots on the minimap
- ⬜ Settings screen: simulation speed default, display options
- ⬜ Sound cues: basic event sounds (problem discovered, CM applied, score panel open, day end)
- ⬜ Colour-blind friendly palette option: toggle accessible colours for problem badges and OEE indicators
- ⬜ Circuit breaker notifications: when WIP ceiling or OEE floor circuit breaker fires, show a non-blocking toast explaining what happened and why the simulation slowed

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
- **NPC interaction model**: players can interact with both NPC sprites directly (implemented Phase 5) AND their associated role-desks. Both open the inspector with the same NPC role panel
- **PDCA as the core game loop**: every problem-solving sequence follows Plan (investigation fork) → Do (apply CM) → Check (follow-up verification fork) → Act (standardize or adjust). The game is only teaching lean if all four phases are playable — not just Plan + Do
- **Mission system as the discovery layer**: problems are not listed on a quest tracker — they are discovered through missions triggered by NPC conversations, floor observation, and KPI signals. The mission system hints, never instructs. The player must still figure out what is wrong and why
- **No timers, no game-over**: the game has no countdown timers, no deadline pressure, and no lose state. Urgency comes from the simulation naturally degrading when problems go unresolved. Active problem cap (max 3, max 1 critical) and simulation circuit breakers (WIP ceiling, OEE floor) ensure the game stays playable regardless of player pace
- **Doable pace by design**: the player is never overwhelmed. New problems queue behind active ones. Problems are sorted by severity before cap check so critical/high surface first
- **Circuit breaker design**: circuit breakers record events and slow simulation only — no permanent station modifier mutations, which would accumulate silently across days
- **Mission trigger direction**: KPI triggers encode comparison direction as `direction: lte/gte` on the `MissionTrigger` dataclass, not hard-coded by metric name
- **pygame-ce over pygame**: pygame-ce used as pygame drop-in (installed via pygame_gui dependency); `requirements.txt` lists `pygame>=2.5.0` which is stale — will be fixed in Phase 6 packaging
- Tier 2–4 problem design: Claude designs, Merijn reviews and may revise
- Anthropic API key: stored in `.env` as `ANTHROPIC_API_KEY`; all AI code reads from env var
- Exe build deferred to Phase 6 (asset folders empty now; bat/vbs launchers used during development)
