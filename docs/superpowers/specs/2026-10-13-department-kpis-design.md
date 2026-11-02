# Design: Department KPIs and work rules ("KPI's die elkaar bevechten")

> Status: approved by Merijn in brainstorming sections 1–3 (2026-10-13); spec approved, built in tasks 1–6 (see PLAN.md).

## Context
- **The last catalogue problem,** *KPI's die elkaar bevechten*: each department is judged on its own output instead of end-to-end lead time, which leads to overproduction.
- **Merijn's choices (2026-10-13), from brainstorming:**
  - Build a real release decision.
  - The player sets the KPIs themselves.
  - Each department offers at most 5 relevant KPIs, each with its own consequence; the player picks 2.
  - A leading KPI drives day-to-day behaviour and decisions. A lagging KPI is the measured effect that confirms the goal and steers long-term strategy.
  - A leading + lagging pair is usually better and rewards more, but only when the simulation shows it really is better.
  - KPIs change at a quarterly review (an OKR cycle).
  - KPIs set work rules; nothing about the outcome is scripted.
- **Ties to CLAUDE.md §2:** "Measure" (KPIs and OKRs come up often) and "fix processes end to end".

## Design (approved in sections 1–3)

### 1. Work rules per department (sim)
- **Rules.** Each pool (department) has three work rules; with no KPI set, each rule keeps the habit, so the healthy base is unchanged.
  - **start:** `push` (the habit: start whenever work waits) or `pull` (start only while the next work step's queue holds less than a kanban limit of 3 days of that team's work: an estimate, set in `content/kpis.yaml` as `pull_limit_days`).
  - **order:** `first_come` (the habit, today's FIFO by queue time), `oldest` (oldest dossier by birth), `shortest` (shortest touch time first: cherry-picking), or `due` (earliest due date first).
  - **care:** `normal` (the habit), `careful` (touch ×1.1, ftr +0.05) or `hasty` (touch ×0.9, ftr −0.05). These values are estimates and are marked as such in the content.
- **Where the rules live in the code.**
  - Order changes how `_most_urgent_step` and the queue head are picked inside one pool's steps.
  - Start=pull gates starting work in `_next_step_for`.
  - Care is applied as step effects.
- **KPIs map to rules.**
  - A lagging KPI sets the direction (usually *start*). A leading KPI sets the daily choices (*order* and/or *care*).
  - Two KPIs that set the same rule give mixed signals, so that rule falls back to the habit.
  - Which choice is better is measured in the simulation, never awarded as a bonus.

### 2. Gameplay loop
- **KPI board.** The board is unlocked by a countermeasure in the mission "KPI's die elkaar bevechten" (Obeya with end-to-end KPIs).
  - It shows per department its menu (at most 5 KPIs) and the 2 it currently has.
  - KPIs are stored as a network effect source (`board:kpis`), so they are saved and switchable like other effects.
- **Quarterly review (every 13 weeks).** The player picks 2 KPIs per department.
  - The review compares this quarter's end-to-end results with the last quarter's: lead time p50, on time, first-time-right, throughput, and `wip_age` per stream.
  - The XP and budget reward follows the measured improvement only.
  - The coach asks a Kata question about leading versus lagging, e.g. "Welke van deze KPI's stuurt het werk van morgen, en welke laat zien of je strategie klopt?"
- **Mission rules.** The mission and the problem follow the mission rules: one main mission, problems only through missions.

### 3. Content
- **New file `content/kpis.yaml`.** Per department, at most 5 KPIs, each with:
  - `id` and a Dutch `name`;
  - `kind`: leading or lagging;
  - `rules`: start, order and/or care;
  - a `note` with the source or "estimate".
- **Menus:**

| Department | KPIs |
|---|---|
| Intake | aanvragen per week (lagging: push, shortest) · doorlooptijd end-to-end (lagging: pull) · oudste aanvraag in de bak (leading: oldest) · compleet doorgezet (leading: careful) · bezettingsgraad (leading: push) |
| Work prep | ontwerpen per week (lagging: push, shortest) · doorlooptijd end-to-end (lagging: pull) · eerste keer goed bij uitvoering (lagging: careful) · oudste dossier (leading: oldest) · bezettingsgraad (leading: push) |
| Planners | ingeplande monteursuren (leading: push) · afspraak nagekomen (lagging: careful) · klussen op tijd (lagging: due) · oudste klus (leading: oldest) |
| Contact centre | gemiddelde afhandeltijd (leading: hasty) · in één keer opgelost (lagging: careful) · bereikbaar binnen 2 uur (lagging: due) |

- **Problem `silo_kpis`.**
  - Effects set intake and work prep to aanvragen/ontwerpen per week + bezettingsgraad, using a new effect property `kpis` on pools.
  - Countermeasures:
    - Obeya met end-to-end KPI's (fit 1.0): sets doorlooptijd + oudste and unlocks the board;
    - WIP-limiet (the existing `wip_limit` lever, fit 0.8);
    - Gedeelde teamdoelen / OKR (fit 0.7).
  - Dutch clues; a main mission in the chain.
- **Validator** (`build_content.py`):
  - at most 5 KPIs per department, each department a known pool;
  - kinds and rule values from a shared vocabulary (mirrored in `vocabulary.json`);
  - the `kpis` effect lists only ids from that department's menu.

## Build order (each step: TDD, simplify, full gate, PLAN.md, commit and push)

The detailed implementation plan follows from this spec (superpowers:writing-plans).
1. **Work rules in the sim:** start, order and care per pool, with the habit as default. Unit tests on fixture networks for push/pull, each order and each care setting. The real base must stay identical; CRN makes that testable.
2. **Probe** on the real network: output+utilisation versus lead time+oldest versus two laggings, for intake and work prep.
   - If pull/oldest is not measurably better, add realistic harm from waiting where it is grounded (e.g. a quote expires after 30 days, a design goes stale), marked as an estimate.
   - Never a bonus.
3. **KPI content, validator and `kpis` effect property:** KPIs → rules, with conflicts falling back to the habit. Tests: combination rules, content checks, save round-trip.
4. **Problem `silo_kpis`, countermeasures and main mission.** Content tests cover them automatically: harm, named KPI, expert solves it, every countermeasure can pass.
5. **Quarterly review:** the board, the 2-of-5 choice, the reward from measured improvement, the coach question. Tests:
   - the reward follows the measured change;
   - choices outside a department's menu are refused;
   - only at the review moment;
   - saved.
6. **Report, docs and PLAN.md:** `problem_report.gd` measures silo_kpis; ARCHITECTURE.md; GDD catalogue status; the review doc gets section 18.

## Critical files
- **Sim:** `game/src/sim/network.gd` (`_next_step_for`, `_most_urgent_step`, `_more_urgent`), `pool.gd` (rules), `modifiers.gd` (`kpis` property).
- **Rules:** `game/src/rules/region.gd` (board, review), a new `kpi_def.gd`, `catalog.gd` (load `kpis.json`), `missions.gd` (unchanged unless a review goal is needed).
- **Content:** `content/kpis.yaml` (new), `problems_tier1.yaml`, `countermeasures.yaml`, `missions.yaml`, and `tools/build_content.py`.
- **Tests:** `game/tests/test_network.gd`, `test_levers.gd`, `test_region.gd`, `test_catalog.gd`, a new `test_kpis.gd`; `tests/test_build_content.py`.

## Verification
- Full gate after every step: Godot tests, `build_content --check`, pytest.
- CI green on PR #1.
- The probe numbers are recorded in PLAN.md.
- The healthy base stays identical when no KPIs are set; a test compares stream KPIs with and without the feature.
