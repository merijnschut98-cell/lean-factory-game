# Phase A Step 5 — Rules: Investigation, A3, PDCA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the factory prototype's tested problem-solving rules (`archive/factory-3d/src/sim/{investigation,pdca,game,progression}.ts`) to GDScript, adapted to a grid operator.

The loop is:
1. A problem becomes active and its effects hit the simulation.
2. The player spots it at the gemba and collects clues with tools and questions.
3. The player writes an A3 (waste, root cause, evidence, countermeasure, prediction).
4. The experiment runs and costs euros plus team hours.
5. Check compares end-to-end numbers before and after.
6. Act: standardise, or watch the problem come back.
7. The player gets a 5-dimension score, XP and a belt.

**Architecture:** pure `RefCounted` rules in `game/src/rules/` drive the `Network` only through `set_effects`/`clear_effects` and read it through KPIs, `Capacity` and the new per-step statistics. They return structured results (codes and numbers). The UI words them in Dutch later, so the rules carry no player-facing text except content.

**Spec:**
- `docs/GDD.md`: Problem solving, Check and Act, Score, Countermeasures, Progression.
- `PLAN.md` step 5: "Check compares stream KPIs and capacity before/after"; design point: "time-windowed per-step statistics".

## Adaptations from the prototype (decided here)

| Prototype | Spanning |
| --- | --- |
| station / zone | **place** = a value-stream step (`connections.design`); the problem's `step` is where it shows. "Scouting" means observing another step of the same stream, i.e. walking the value stream. |
| clues derived from 5-Whys choices | clues authored directly: `{tool, text, key, depth, at?}`. `at` lets a clue sit upstream of the problem, e.g. the cause of design rework is found at intake. |
| trust per station | trust per team (pool), since "that person, and soon their team" stop sharing |
| operator view text | an **observation code** from the sim (`queue`, `rework`, `material`, `quiet`) plus a number; the UI words it |
| credits | **budget (€) and team hours**. The hours become an availability effect on that team for the experiment period: improvement work competes with daily work. |
| line capacity | the problem's **stream** capacity per week and its constraint pool; lead time and throughput are in the Check result |
| metrics for the prediction | `throughput`, `lead_time`, `first_time_right`, `on_time` (authored per problem as `kpi`) |

## Global Constraints
- Effect sources:
  - `problem:<id>`: the problem's effects at strength (1 − eff);
  - `cm:<id>`: the countermeasure's effects at strength eff, once eff ≥ 0.5;
  - `do:<id>`: team hours during the experiment.
- Constants:
  - CHECK_PASS 0.5, MISMATCH 0.1, NONE 0.05;
  - MAX_OPEN 3 problems open at once;
  - CHECK_DAYS 14;
  - score per dimension 1–5, total 25.
- Belts (XP): white 0, yellow 1200, green 3500, black 7000, master black 12000.

## Review Focus
1. **The depth gate:** a depth-2 clue must not be revealed before the depth-1 key clue, even with the right tool. Test.
2. **Blame:** a blaming question to one team must not hurt trust with another team. Test.
3. **Failed Check:** the problem's effect must come back at full strength, and the countermeasure's effect must be gone. Test.
4. **Non-constraint fix:** a fix away from the constraint must score low on flow impact even when the step improved. Test on real content (GIS vs work prep).
5. **Recurrence:** an unstandardised fix must recur after its decay, and a standardised one must not. Test.

### Task 1: Per-step statistics in `sim/`
- `SimStep.stats_since(day: int) -> Dictionary` returns `{entered, done, reworked, queue_hours}`. `queue_hours` is the mean wait before the first start.
- Recorded in daily buckets. Tests in `test_network.gd`.

### Task 2: Content classes + pure rules
- `rules/problem_def.gd` (`ProblemDef`) and `rules/countermeasure_def.gd` (`CountermeasureDef`), each with `from_dict(d) -> obj` (null + error on bad data).
- `rules/investigation.gd` (`Investigation`):
  - `TOOLS`, `QUESTIONS`, `WASTES`;
  - `revealable(clue, found)`;
  - `cause_options(problem, all) -> {options, correct}`.
- `rules/pdca.gd` (`Pdca`): `effectiveness(problem, cm, maturity) -> {eff, level}` and `score(inputs) -> {plan, root_cause, countermeasure, check_act, impact, total, notes: Array[String] (codes)}`.
- `rules/progression.gd` (`Progression`): `BELTS`, `belt_index(xp)`, `belt_progress(xp)`.
- Tests: `test_investigation.gd`, `test_pdca.gd` (port of the prototype's cases).

### Task 3: `rules/region.gd` (`Region`)
**Interfaces:**
- `Region.new(net, problems, countermeasures, profile)`
- `activate(problem_id)`
- `use_tool(place, tool) -> {spotted, clues, hidden_signal}`
- `ask(place, question_id) -> {kind, reply: code, clue, trust, observation}`
- `submit_a3(problem_id, a3) -> String` (error code or "")
- `advance_days(n)` moves to check_ready
- `check(problem_id) -> Dictionary`
- `act(problem_id, standardise) -> score`
- recurrence

Tests:
- `test_region.gd` with a fixture network and two fixture problems:
  - the full loop;
  - a failed check;
  - blame and repair;
  - the depth gate;
  - an upstream clue;
  - team hours lowering availability during Do;
  - recurrence.
- On real content, `test_value_streams.gd`: fixing GIS (non-constraint) scores impact ≤ 2; fixing design scores ≥ 4.

### Task 4: Docs, PLAN.md, simplify, push.
