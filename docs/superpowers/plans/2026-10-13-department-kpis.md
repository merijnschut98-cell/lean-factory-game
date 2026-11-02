# Department KPIs and Work Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let departments work by rules that follow the KPIs they are measured on, so the player can set 2 of up to 5 KPIs per department at a quarterly review and see the real end-to-end effect.

**Architecture:**
- **The simulation knows only work rules.** Per pool there is a start rule (push or pull) and an order rule. Care is expressed through the existing `touch_time` and `ftr` effects.
- **The rules layer translates KPIs into rule effects:** `KpiMenu.effects_for`.
  - The Catalog expands content `kpis` effects at load time, so the sim and saves never see KPI ids.
  - The `KpiBoard` (owned by Region) holds the player's choices as the effect source `board:kpis`. It runs the quarterly review and rewards the measured improvement.

**Tech Stack:** Godot 4.7 GDScript (headless tests via `res://tests/run_tests.gd`), Python 3 content build (`tools/build_content.py`, pytest).

**Spec:** `docs/superpowers/specs/2026-10-13-department-kpis-design.md`

## Global Constraints

- **Habit when no KPI is set:** start `push`, order `first_come`, care `normal`. The healthy base must stay identical (common random numbers make this exact).
- **Rule vocabulary:**
  - start: `push | pull`;
  - order: `first_come | oldest | shortest | due`;
  - care: `normal | careful | hasty`.
- **Care values (estimates, marked as such in `content/kpis.yaml`):** careful = touch ×1.1, ftr +0.05; hasty = touch ×0.9, ftr −0.05.
- **Pull** starts work only while the next work step's queue holds less than `pull_limit_days` of the next team's work. The default is 3 (an estimate).
- **KPI menus:**
  - At most 5 KPIs per department; the player chooses exactly 2 distinct ones.
  - Kind: `leading | lagging`.
  - Two KPIs that set the same rule to different values fall back to the habit for that rule.
- **Quarterly review** every 13 weeks (91 days), after the board is unlocked. The reward follows only the measured end-to-end improvement over the previous quarter, never the labels.
- **Text:** Dutch game text; English code, comments and docs. Content estimates are marked as estimates with their reasoning (CLAUDE.md §2).
- **Process:**
  - every behaviour change goes test-first (watch it fail);
  - `simplify` after each task;
  - the full gate before each commit: `godot --headless --path game --script res://tests/run_tests.gd`, `python tools/build_content.py --check`, `python -m pytest tests/`;
  - PLAN.md updated inline;
  - commit and push per task.

## Review Focus

1. **A pool that serves several streams (planners, monteurs).**
   - Its rules apply to all its steps.
   - Pull looks at the next work step of each order's own stream.
   - A last step (nothing downstream) is never blocked.
   - Covered in Task 1: `test_pull_never_blocks_a_last_step`.
2. **Choosing one KPI, the same KPI twice, or a KPI from another department's menu** is refused with a code, and nothing changes. Covered in Task 5: `test_the_board_refuses_bad_choices`.
3. **A review over a quarter in which a stream finished nothing** (congestion can be quiet). There's no division by zero, and that stream counts as no change. Covered in Task 5: `test_a_quiet_stream_counts_as_no_change`.
4. **Problem rules versus countermeasure rules.**
   - While `silo_kpis` is treated, the countermeasure's rules must win over the problem's.
   - Rules are SET levers, so the most recent source wins.
   - Covered in Task 4: `test_the_countermeasure_rules_override_the_problem`.
5. **Save and load in the middle of a quarter** keeps the chosen KPIs, the next review time and the last quarter's snapshot. Covered in Task 5: `test_the_board_survives_save_and_load`.

---

### Task 1: Work rules in the simulation (start and order per pool)

**Files:**
- Modify:
  - `game/src/sim/pool.gd`: add fields;
  - `game/src/sim/modifiers.gd`: `PROPERTIES` and `_check_lever`;
  - `game/src/sim/network.gd`: `_assign_work`, `_next_step_for`, `_most_urgent_step`, `_more_urgent`, plus a new helper;
  - `tools/build_content.py`: `EFFECT_PROPERTIES` and vocabulary, mirroring the sim.
- Test: `game/tests/test_levers.gd`, `game/tests/test_value_streams.gd`

**Interfaces:**
- Produces:
  - `SimPool.start_rule: String = "push"`
  - `SimPool.order_rule: String = "first_come"`
  - `SimPool.pull_limit_days: float = 3.0`
  - modifier properties `start_rule` and `order_rule`: kind `pool`, op SET, valid values as in Global Constraints;
  - `Network.queue_days(step: SimStep) -> float`: the remaining touch minutes queued at `step`, divided by its first pool's working minutes per day (headcount × availability × schedule hours per working day × 60).

- [ ] **Step 1: Write the failing tests** in `test_levers.gd`, using `NetFixture`. Each test runs a short fixture network, and the assertion names the behaviour:
  - `test_shortest_first_picks_the_quickest_job`:
    - one person serves two single-step streams, `long` (4 h) and `short` (0.5 h), with equal priority;
    - set `order_rule` to `shortest` on that pool;
    - after one day, `short` has more DONE than `long`, while with `first_come` it does not.
  - `test_oldest_first_picks_the_earliest_born`: a pool where an older order re-enters the queue after rework. With `oldest` it starts before newer arrivals; assert its done time is earlier than under `first_come`.
  - `test_due_first_picks_the_earliest_due_date`: two streams with `norm_days` 2 and 30 share one person; with `due`, the 2-day stream's on-time is higher than under `first_come`.
  - `test_pull_waits_for_room_downstream`:
    - stream `a` (team `fast`, 0.5 h) then `b` (team `slow`, 4 h);
    - with `start_rule` `pull` on `fast`, after 10 days `net.queue_days(b_step) <= fast.pull_limit_days + 0.5`;
    - under `push` it is larger.
  - `test_pull_never_blocks_a_last_step`: with `pull` on the pool of a stream's last work step, its work still completes.
  - `test_rule_values_are_checked`: `set_effects` with `order_rule` `"random"` returns an error and changes nothing.
- [ ] **Step 2: Add `test_habit_rules_leave_the_base_identical`** to `test_value_streams.gd`. Run the real network for 60 days with explicit habit effects (`push` and `first_come` on every pool), and assert every stream's `finished` equals the base run's.
- [ ] **Step 3: Run the Godot suite.** Expected: these tests fail (the properties are unknown).
- [ ] **Step 4: Implement the rules.**
  - **Order:** the order rule decides which queued order of a step is the head, and `_more_urgent` compares heads across the pool's steps by stream priority first, then by the rule:
    - `first_come`: `queued_at`;
    - `oldest`: `born`;
    - `shortest`: `remaining`;
    - `due`: `due`.
  - **Taking work:** `_assign_work` removes the chosen head by index instead of `pop_front`.
  - **Pull:** `_most_urgent_step` skips a step when the pool's `start_rule` is `pull`, the step has a next work step in its stream, and `queue_days(next) >= pool.pull_limit_days`.
- [ ] **Step 5: Mirror the properties in Python.**
  - Add `start_rule` and `order_rule` to `EFFECT_PROPERTIES` in `tools/build_content.py` as `("pool", None, "start_rule" / "order_rule")`.
  - Add value checks for both.
  - Add `START_RULES` and `ORDER_RULES` to `vocabulary()`.
  - The Godot vocabulary test then passes.
- [ ] **Step 6: Run the full gate.** Expected: all pass, and the base is identical.
- [ ] **Step 7: Simplify, update PLAN.md, commit:** `Work rules per department: start push/pull and order`.

### Task 2: Probe, and calibrate only where the simulation shows no real effect

**Files:**
- Create: `scratchpad/probe_kpis.gd` (throwaway, not committed)
- Modify, only if needed: `content/value_streams.yaml`
- Modify: `PLAN.md`

**Interfaces:**
- Consumes: Task 1's properties.

- [ ] **Step 1: Write a probe.** It runs the real network for 180 days, seeds 11–13, measuring the last 84 days, for intake and work_prep, under:
  - (a) `push` + `shortest`, plus hasty care (touch 0.9, ftr −0.05) on their steps: today's silo KPIs;
  - (b) `pull` + `oldest`: a lead-time + oldest-dossier pair;
  - (c) `pull` + `first_come`: two laggings, so order falls back to the habit;
  - (d) the habit.
- [ ] **Step 2: Print the results.** Per variant: connections lead p50/p85, on-time, FTR, throughput, `wip_age`, and the stale count at design.
- [ ] **Step 3: Decision gate.**
  - **If (b) beats (a) on lead time and on wip_age:** record the numbers in PLAN.md and go on.
  - **If not:**
    - add the realistic harm from waiting that the simulation lacks: `stale_after_days: 30` at `connections.intake` with `stale_to: intake` and `stale_wait_days: 5` (an application older than a month needs the customer's check again; an estimate, marked as such);
    - re-run the probe and record both runs;
    - never add a bonus.
- [ ] **Step 4: Full gate, then commit** (content change and PLAN.md, if any): `Probe: what department KPIs do on the real network`.

### Task 3: KPI menus in content, the validator, and the KPI-to-rules translation

**Files:**
- Create:
  - `content/kpis.yaml`;
  - `game/src/rules/kpi_def.gd` (`KpiDef`);
  - `game/src/rules/kpi_menu.gd` (`KpiMenu`);
  - `game/tests/test_kpis.gd`.
- Modify:
  - `game/src/rules/catalog.gd`: load `kpis.json`, expand `kpis` effects;
  - `tools/build_content.py`: `validate_kpis` and the `kpis` effect check;
  - `tests/test_build_content.py`. The Godot runner discovers `test_*.gd` files itself.

**Interfaces:**
- Consumes: modifier properties `start_rule`, `order_rule`, `touch_time`, `ftr` (Task 1).
- Produces:
  - `KpiDef` with `id`, `name`, `pool`, `kind` (`"leading" | "lagging"`), `rules: Dictionary` (keys `start`, `order`, `care`, each optional), and `from_dict(d) -> KpiDef` with `error`.
  - `KpiMenu`:
    - `menus: Dictionary[String, Array]` (pool id to `KpiDef` list);
    - `pool_steps: Dictionary[String, PackedStringArray]` (pool id to its work-step places, `"stream.step"`), read by the Catalog from `value_streams.json`, so no network is needed;
    - `pull_limit_days: float`;
    - `review_question: String`;
    - `func effects_for(pool_id: String, kpi_ids: PackedStringArray) -> Array`: the rule effects for those KPIs (`start_rule` and `order_rule` on the pool; care as `touch_time` and `ftr` on each of `pool_steps[pool_id]`); conflicting rule values give the habit.
  - `Catalog.kpis: KpiMenu`. Problems' and countermeasures' effects with `property: kpis` are replaced by `KpiMenu.effects_for` output at load.
  - Content shape of a KPI effect: `{target: <pool>, property: kpis, value: [<kpi id>, <kpi id>]}`.

- [ ] **Step 1: Write `content/kpis.yaml`** with the spec's menus.
  - Fields: `pull_limit_days: 3`, `care` values, and a Dutch `review_question` ("Welke van deze KPI's stuurt het werk van morgen, en welke laat zien of je strategie klopt?").
  - Ids are prefixed by department (e.g. `intake_output`, `intake_lead_time`, `intake_oldest`, `intake_complete`, `intake_utilisation`).
  - Each KPI has a Dutch name, a kind, rules, and a `note` (source or "estimate").
- [ ] **Step 2: Write the failing pytest cases** in `test_mission_errors_are_caught` style, plus a valid fixture:
  - 6 KPIs on one pool → "at most 5";
  - an unknown pool → "unknown pool";
  - `kind: medium` → "'kind' must be one of";
  - `rules: {order: random}` → "order must be one of";
  - a `kpis` effect naming another pool's KPI → "not on the menu of";
  - a `kpis` effect with three ids → "one or two KPIs".
- [ ] **Step 3: Write the failing Godot tests** in `test_kpis.gd`:
  - `test_a_lagging_and_a_leading_kpi_set_all_their_rules`: `intake_lead_time` + `intake_oldest` → start `pull`, order `oldest`.
  - `test_conflicting_kpis_fall_back_to_the_habit`: `intake_output` (push, shortest) + `intake_lead_time` (pull) → no start effect, order `shortest`.
  - `test_careful_care_slows_and_improves_every_step_of_the_team`: touch ×1.1 and ftr +0.05 on every work step whose pool is the department.
  - `test_the_catalog_expands_kpi_effects`: a problem's `kpis` effect becomes rule effects, and the real network's `set_effects` accepts them.
- [ ] **Step 4: Run both suites.** Expected: the new tests fail.
- [ ] **Step 5: Implement.**
  - `validate_kpis` and the `kpis` effect check: `kpis` is accepted outside `EFFECT_PROPERTIES`, because the game expands it, so the vocabulary mirror stays sim-only.
  - Write `kpis.json` and the vocabulary keys `kpi_kinds`, `care_rules`.
  - `KpiDef`, `KpiMenu`, and Catalog loading and expansion, using the existing `_load` helper.
- [ ] **Step 6: Run the full gate, simplify, update PLAN.md, commit:** `KPI menus per department, translated into work rules`.

### Task 4: The problem `silo_kpis`, its countermeasures, and the main mission

**Files:**
- Modify:
  - `content/problems_tier1.yaml`, `content/countermeasures.yaml`, `content/missions.yaml`;
  - `game/src/rules/countermeasure_def.gd`: add `unlocks`;
  - `tools/build_content.py`: `unlocks` in `COUNTERMEASURE_KEYS`, value in `["kpi_board"]`;
  - `tests/test_build_content.py`, `game/tests/test_region.gd`.

**Interfaces:**
- Consumes: the `kpis` effects (Task 3).
- Produces: `CountermeasureDef.unlocks: String` (`""` or `"kpi_board"`).

- [ ] **Step 1: Write the content.**
  - **Problem** `silo_kpis` "KPI's die elkaar bevechten":
    - step `connections.design`, waste `overproduction`, kpi `wip_age`;
    - effects: intake `[intake_output, intake_utilisation]` and work_prep `[work_prep_output, work_prep_utilisation]`;
    - quoted Dutch clues with the depth chain, and plausible causes.
  - **Countermeasures:**
    - `obeya_end_to_end` (tier 1, fit 1.0): kpis `[intake_lead_time, intake_oldest]` and `[work_prep_lead_time, work_prep_oldest]`, `unlocks: kpi_board`;
    - `connections_wip_limit` (tier 2, fit 0.8): `connections` `wip_limit` 300, an estimate (about the base backlog);
    - `shared_team_goals` (tier 2, fit 0.7): kpis lead time + complete handover.
  - **Main mission** `fix_silo_kpis`, requiring `[fix_unused_capacity]`, with briefing, debrief and insights in Dutch.
- [ ] **Step 2: Write the failing tests.**
  - pytest: `unlocks: board` → "'unlocks' must be one of".
  - Godot: `test_the_countermeasure_rules_override_the_problem` in `test_region.gd`. With the real catalog, activate `silo_kpis`, submit an A3 with `obeya_end_to_end`, and assert intake's pool `start_rule == "pull"` while the experiment runs.
- [ ] **Step 3: Run the gates.** Expected: they fail.
- [ ] **Step 4: Implement `unlocks`** in the validator and in `CountermeasureDef.from_dict`. The content tests (harm, named KPI, expert solves, every countermeasure passes) now cover `silo_kpis`.
  - If `test_every_problem_hurts_its_stream` fails, the problem's mechanism is too weak. Revisit Task 2's numbers; don't loosen the test.
- [ ] **Step 5: Run the full gate, simplify, update PLAN.md, commit:** `KPI's die elkaar bevechten: problem, countermeasures, mission`.

### Task 5: The KPI board and the quarterly review

**Files:**
- Create: `game/src/rules/kpi_board.gd` (`KpiBoard`), `game/tests/test_kpi_board.gd`
- Modify:
  - `game/src/rules/region.gd`: own the board, unlock it on a passed Check of a countermeasure with `unlocks == "kpi_board"`, emit `{type: kpi_review}` when it is due;
  - `game/src/rules/region_state.gd`: save the board;
  - `docs/ARCHITECTURE.md`.

**Interfaces:**
- Consumes: `KpiMenu`, `Network.open_age_days`, `ValueStream.kpis`, `Region.grant`.
- Produces:
  - `KpiBoard.new(menu: KpiMenu)` with:
    - `unlocked: bool`
    - `chosen: Dictionary[String, PackedStringArray]`
    - `next_review_at: int` (minutes)
    - `const REVIEW_DAYS := 91`, `const REVIEW_XP := 1000`, `const REVIEW_BUDGET := 10000`
    - `func unlock(now: int) -> void`
    - `func review_due(now: int) -> bool`
    - `func review(net: Network, choices: Dictionary) -> Dictionary`. On success it returns `{error: "", improvement: float, xp: int, budget: int, question: String, before: Dictionary, after: Dictionary}`. Error codes: `locked`, `not_due`, `unknown_department`, `choose_two`, `not_on_menu`.
    - `func to_dict() -> Dictionary`
    - `func load_dict(d: Dictionary) -> void`
  - `Region.kpi_review(choices: Dictionary) -> Dictionary` calls `board.review`, then `grant(xp, budget)`.
- **Improvement** (written in `review`): per stream with finished work in both quarters, the mean of the relative changes in lead p50 (lower is better), on-time, FTR, throughput, and `wip_age` (lower is better). Average over those streams, and clamp to 0 or more. Reward = round(improvement × REVIEW_XP) XP and round(improvement × REVIEW_BUDGET) budget.

- [ ] **Step 1: Write the failing tests** in `test_kpi_board.gd`, using the fixture network and a small menu:
  - `test_the_review_opens_only_when_unlocked_and_due`;
  - `test_the_board_refuses_bad_choices`: one KPI, the same KPI twice, another pool's KPI, an unknown department; each returns its code and changes nothing;
  - `test_chosen_kpis_change_the_work_rules`: after a valid review, the pool's `start_rule` follows the choice, and the source is `board:kpis`;
  - `test_the_reward_follows_the_measured_change`: a quarter with a worse ftr gives 0, a better one more than 0, with the same labels;
  - `test_a_quiet_stream_counts_as_no_change`: a stream with zero completions in a quarter gives no error and no NaN;
  - `test_the_board_survives_save_and_load`: through `RegionState` capture and restore mid-quarter.
- [ ] **Step 2: Run them.** Expected: they fail.
- [ ] **Step 3: Implement `KpiBoard` and the Region hooks.** The quarter's snapshot holds the per-stream KPIs over the last 91 days at the previous review (or at unlock).
- [ ] **Step 4: Run the full gate, then the `requesting-code-review` skill** (end of the feature). Simplify, update PLAN.md and ARCHITECTURE.md (a board and review section), commit: `KPI board and quarterly review`.

### Task 6: Report, review doc, and catalogue status

**Files:**
- Modify:
  - `game/tools/problem_report.gd`: nothing to change if it already iterates every problem; verify `silo_kpis` appears;
  - `PLAN.md`: 18 of 18 catalogue problems, next task `content/concepts.yaml`;
  - `docs/GDD.md`: catalogue status line, if present.
- Review doc: add section 18 through `scratchpad/review_md.py` with notes for `silo_kpis`.

- [ ] **Step 1: Run the report** (background, about 20 min). Render `p18.md`, insert it after section 17, and add a line to Update 3.
- [ ] **Step 2: Full gate, then commit and push:** `Report and review doc: KPI's die elkaar bevechten`.
