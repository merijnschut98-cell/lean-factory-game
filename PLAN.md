# Spanning — Build Plan

*Spanning* (Dutch: voltage, and tension) is a 3D game (Godot 4, desktop + web export) where you practise Lean and continuous improvement at **Voltana Netbeheer**, a fictional Dutch regional grid operator (DSO) in the spirit of Enexis. It is built first for Merijn's own learning: practise Lean on realistic problems from the energy sector, including the less-known ones.

Game text is **Dutch** (with sector terms). Code, comments and this plan stay in English.

---

## Current Status: Phase A — Engine (Godot) ✅ done · Phase B — Content 🔧 next

Pivot agreed 2026-10-12: from a hoverboard factory to a grid operator. The 3D factory prototype is archived in `archive/factory-3d/` (also git commit `b3a4c8c`). Its investigation / A3 / PDCA / bottleneck logic will be carried over and generalised.

This is a multi-month project, built the right way: research → design (reviewed by Merijn) → engine → content → world → UI, in small tested increments. No publishing deadline. Built in **Godot 4 + GDScript** from the start (decided 2026-10-12).

**Next task:** the counterfactual KPI reward, then Phase C's first piece: the 3D connections office with one playable mission. `content/concepts.yaml` comes after. All review questions are answered and built in (review doc: https://claude.ai/code/artifact/120bfc8c-75b6-4a56-86d9-2c5c3148112a).

---

## Vision and Learning Pillars

1. **Learn by doing, safely.** Mistakes cost time, credits and trust, never the game. Recovery is always possible, and often it *is* the lesson.
2. **Problem solving is thinking, not quizzing.** Clues are earned through gemba actions (meelopen, data analyseren, tijdstudie, gesprekken) and good questions. You write the A3 yourself: waste, evidence, root cause, countermeasure, prediction. The simulation judges the result.
3. **Respect for people.** Problems live in the process, not the person. Blaming questions cost trust and information.
4. **Quality first.** Rework loops (incomplete applications, wrong GIS data, failed commissioning, repeat visits) are simulated and visible.
5. **See the 8 wastes (TIMWOODS)** in a service and field organisation: waiting for permits, the backlog itself, travel, searching for materials, approvals nobody needs, rework, unused expertise.
6. **Bottleneck first, end to end.** Each value stream is mapped end to end; improving a non-constraint is shown to be no real gain. The value stream map is built by walking it.
7. **Real sector problems.** Grid congestion is one of many. The catalogue covers the well-known and the less-known struggles of Dutch DSOs.

---

## Setting

- **Company:** Voltana Netbeheer (fictional), region *Zuidmark*.
- **Player:** newly hired continuous improvement lead (CI-lead).
- **World at start:** the operations campus in *Nova* (customer service, intake & planning, engineering/werkvoorbereiding, bedrijfsvoeringscentrum/control room, warehouse, workshop, training yard) plus the town of Nova (homes with solar panels, heat pumps and EV chargers, an industrial estate, MS/LS cables, distribution substations, a primary substation). Vans drive from the campus to jobs in town.
- **Later:** more regions unlock as your CI maturity grows.

## Value streams

| # | Value stream | Units flowing | Typical constraint |
|---|---|---|---|
| 1 | **Nieuwe aansluitingen & netverzwaring** | connection requests | grid studies, monteurs, materials, permits |
| 2 | **Storingen** (outage response) | faults | detection/localisation, on-call travel time, joints in the van |
| 3 | **Veldservice & slimme meters** | meter and service jobs | appointments / niet-thuis, travel |
| 4 | **Congestiemanagement** | capacity requests (grootverbruik) | congestion studies, contracts, unused reserved capacity |
| 5 | **IT-waardestromen** (later phase) | features, incidents | release trains, dependencies, test environments |

Streams share people (monteurs serve outages, connections and meters), so outages preempting planned work is simulated, not scripted.

## Issue catalogue themes (to be authored as problems)

Well-known: netcongestie and the wachtrij; long aansluittermijnen (legal 18 weeks, compensation payments); technician shortage and aging workforce; transformer/cable lead times.

Less-known: incomplete applications and installers not ready (meterkast niet gereed); failure demand at the call centre (customers chasing status); as-built/GIS revision backlog causing design errors and graafschade; permits requested in batches; administrative close-out backlog (EAN not registered, customer can't get a contract); planned work wrecked by storingen; van stock unknown, trips back to the depot; standard jobs over-prepared; 2G/3G network sunset forcing smart-meter module swaps; LS overvoltage tripping solar inverters; reserved-but-unused capacity; power theft (hennepteelt) and grid losses; ondergrondse drukte (no space in the street); stikstof permits delaying substations; LMRA as a tick-box; contractor quality and rework; departmental KPIs that fight each other; knowledge leaving with retiring monteurs; heatwave transformer overload; gas-grid maintenance during the heat transition.

---

## Phase 0 — Research and Game Design Document ✅
- ✅ Domain research round 1: value streams, well-known and less-known problems, norms and numbers, sources (findings also in `docs/energy-notes.md`)
- ⬜ Verify key figures against the source pages themselves (this environment's network policy blocks the news sites; only search extracts were available)
- ✅ GDD drafted as a shared Claude Doc: vision, core loop, world, value streams, simulation model, problem solving, catalogue v1 (18 problems), countermeasures, progression, UI, art, roadmap, open questions
- ✅ Merijn reviewed the GDD and answered all open questions → decisions recorded below
- ✅ Reviewed GDD synced to `docs/GDD.md` (shared Claude Doc remains the place for comments)
- ✅ `docs/ARCHITECTURE.md`: Godot 4.7.2 + typed GDScript, Compatibility renderer, pure `sim/` + `rules/` separated from `world/` + `ui/`, YAML → validated JSON content pipeline, custom headless test runner, JSON saves, CI with export builds
- ✅ Weekly energy-sector digest for Merijn: notes in `docs/energy-notes.md`, routine every Friday 15:47 (Amsterdam)

## Phase A — Engine for work-order flow (Godot, GDScript) 🔧
- ✅ Step 1: Godot 4.7.2 project skeleton (`game/`, Compatibility renderer), boot scene that loads content and renders
- ✅ Headless test runner with `TestCase` asserts; catches failed asserts, syntax errors and runtime errors (via `Logger`); 10 tests (`Rng`, `GameInfo`)
- ✅ `tools/build_content.py`: YAML → validated JSON with a drift check; 9 pytest tests; first content file `content/game.yaml`
- ✅ `game/tools/screenshot.gd` for visual checks under Xvfb; rendering tuned (linear tone mapping, neutral ambient)
- ✅ CI (`.github/workflows/ci.yml`): content check, Godot tests, legacy Python tests on every push; Windows/Linux/web export on demand. All three exports verified locally
- ✅ CLAUDE.md testing rule lists the Godot, content and Python commands (approved by Merijn)
- ✅ Simplify pass: shared cached Godot setup + export matrix in CI, project-wide default environment and `Palette`, `TestCase` moved to `tests/lib/`, two-pass content validation (`CROSS_CHECKS`), schema fields derived in `GameInfo`
- ⬜ Tech debt (tracked; vocabularies now guarded by a test, `game/data/vocabulary.json`): content rules live twice, in Python (validation, the authority) and in GDScript (loading): the `game.yaml` field list vs `GameInfo`, and since step 3 the day-range, "HH:MM"/"24:00" and `pool`-as-string-or-list rules. Option: let `build_content.py` emit canonical JSON (schedules as minute intervals, `pool` always a list, one `norm_minutes`) so the game parses nothing; decide when the problem/countermeasure schemas arrive (step 4–5)
- ✅ Step 2: work-order simulation core in `game/src/sim/` (calendar, work orders, pools with attendance and pre-emption, external waits, stock with reorder point, rework loops with customer waits, arrivals, KPIs) and `Capacity` (expected visits incl. rework, pool load, constraint per stream); connections stream in `content/value_streams.yaml` with validator; 35 Godot tests; a simulated year runs in ~3 s
- ✅ Simplify pass on step 2: one event path, sorted waits and deliveries, idle-time skipping (proven identical by a test; a simulated year 3.2 s → 0.7 s), random helpers in `Rng`, shared `JsonFile` loader, dead state removed, cached test run (suite 2.9 s → 0.7 s)
- ✅ Step 3 (plan: `docs/superpowers/plans/2026-10-12-phase-a-step-3-shared-streams.md`): outage, meter and congestion streams next to connections.
  - `WeekSchedule` (weekly 10-minute slots) replaces the daily shift: pools have schedules incl. 24/7 and on-call through midnight; streams have arrival sources `{per_week, days, from, to}`.
  - A work step can be served by several pools (monteurs by day, storingsdienst at night); unfinished work is handed over at the end of a shift.
  - `preempts` (outages only) separates interrupting work from queue priority.
  - `Capacity` per week; multi-pool load split by schedule overlap.
  - Validator: schedules, arrivals, norm in days or hours, rework loops that would take material twice.
  - Results: Werkvoorbereiding still the constraint (104%), monteurs 69%, outages p85 ≈ 3.8 h, no stock-outs in 30 seeds × 120 days. 50 Godot tests; a simulated year 1.3 s (four streams).
- ✅ Simplify pass on step 3: day 0 starts in `create()` (no first-tick special case), O(1) `WeekSchedule.next_start`, busy check before schedule lookups, pool list instead of per-tick `values()`, handover folded into the work loop, `SimCalendar.hours()`, shared test helpers in `NetFixture`, dead calendar helpers removed (year 1.7 s → 1.3 s). Kept by choice: the Capacity split of multi-pool steps by arrival hours (an estimate, documented), and the validator rule against rework loops through a material step (an explicit authoring rule instead of per-order material state)
  - Weekly demand patterns (e.g. Monday peaks) and demand multipliers are deferred to step 4 (demand is a problem effect).
- ✅ Step 4 (plan: `docs/superpowers/plans/2026-10-12-phase-a-step-4-problem-effects.md`): problem effects as removable modifiers.
  - `SimModifiers`: effects `{target, property, value}` grouped by source (`problem:…`, `cm:…`, `event:…`); content values stay the base; every change recomputes `clamp(base × factors + additions)` into the plain sim fields, so the simulation and `Capacity` need no lookups.
  - Properties: `touch_time`, `ftr`, `applies`, `wait_time` (steps, as `stream.step`); `availability`, `headcount` (pools); `lead_time`, `reorder_point` (stock); `demand` (streams).
  - `Network.set_effects` / `clear_effects` (atomic: an invalid list changes nothing); `SimModifiers.scaled` for partial effectiveness (step 5); `sources()` for saves (step 6).
  - Lesson test on real content: 30% faster design moves the connections constraint from Werkvoorbereiding to Revisie & GIS, for only ~2 more connections a week. 60 Godot tests.
- ✅ Simplify pass on step 4: `demand` fans out to each arrival source's `per_week` (no separate demand factor for readers to remember), `ValueStream.step()` lookup, one accumulator per property in `_apply`, `Network.effects()` as the single read path, a snapshot-based restore test over every property and a test that every property names a real field
- ✅ Step 4b (plan: `docs/superpowers/plans/2026-10-12-phase-a-step-4b-structural-levers.md`): structural levers, switchable by countermeasures through effects (new SET operation: the most recent source wins).
  - Reserved capacity: pool `reserve: {stream, people}`; idle reserved people take no other work; `Capacity` subtracts the idle reserve from other streams' spare hours.
  - Frozen planning window: `preempts` as a lever.
  - Cost of interruption: `interrupt_to` + `interrupt_wait_days` (connections execution → back to planning, 2 days for a new appointment).
  - Batching (`batch_days`) and waits in parallel (`starts_with`) for problem 8.
  - Validator covers all of it, incl. interruption loops through material. 70 Godot tests; with the levers off, results are unchanged.
- ✅ Simplify pass on step 4b: the reserve is one lever `{stream, people}` (same shape as the content, so a half-set reserve cannot exist), one `_send_back` for rework and re-planning, the parallel-wait sentinel removed, Capacity computes the idle reserve once per pool, shared `_earlier` check in the validator
- ✅ Step 4c: what waiting costs, and WIP limits (Merijn, 2026-10-12: implement).
  - Stale dossiers: a work step's `stale_after_days` + `stale_to`. A dossier that waited longer is out of date when work would start and goes back (connections design: after 60 days back to the quote; the customer signs again). Nothing goes stale in today's process; a problem that slows design starts the spiral (32 stale dossiers a year with design 25% slower).
  - WIP limit (CONWIP): stream `wip_limit` (content or a lever); new orders beyond it wait, not yet started.
  - Measured on real content with design 25% slower: a limit of ~100 removes the stale rework (+4% connections a year); a limit of 60 starves the constraint (throughput 24 → 15 a week), which is Little's Law. That is the lesson: a WIP limit must be sized as throughput × flow time and does not replace fixing the constraint. 102 Godot tests.
- ✅ Simplify pass on step 4c: held orders are released on arrival, finish or a lever change (no per-tick loops, ~7% faster), one `_days()` parser for every day field, shared test helper
- ⬜ Heijunka (levelling the release of planned work), after the content shows where it is needed
- ✅ Decided (Merijn, 2026-10-12): `value_streams.yaml` holds a healthy process *to an extent*; the starting problems are active effects on top. There is no single healthy process: several countermeasures can help one problem (each with a fit 0–1), each shapes the process differently through its own effects and levers, and some improve more than others. Players must not be pushed down one dedicated path
- ✅ Step 5 (plan: `docs/superpowers/plans/2026-10-12-phase-a-step-5-rules.md`): the problem-solving rules in `game/src/rules/`.
  - `Region` runs the loop over the live simulation: activate (max 3 open), gemba tools at value-stream steps, questions with trust per team, A3 (waste, cause bank, evidence, countermeasure, Kata prediction), experiment, Check, Act, recurrence.
  - Several countermeasures per problem, each with a fit (Merijn's "many healthier processes").
  - Improvement budget plus team hours (an availability effect while the experiment runs).
  - Check on end-to-end KPIs and capacity plus per-step daily statistics; five-dimension score, budget and XP, belts.
  - Lesson test on real content: fixing Planning (≈40% load) scores flow impact ≤ 2 with "not the constraint"; fixing Werkvoorbereiding scores ≥ 4. 98 Godot tests.
  - Missions and the story arc follow with the Phase B content
- ✅ Simplify pass on step 5:
  - a `started` flag (not a guess from remaining time) for queue statistics;
  - phases as an enum;
  - A3 verdicts fixed at submit;
  - one `Network.step_at(place)`;
  - dead state removed (incl. the duplicate step counters; daily statistics are the one source);
  - bounded `stats_since`;
  - `_score_inputs` split out of `act`.
- ✅ Step 6: save/load.
  - `NetworkState` and `RegionState` capture everything needed to continue exactly; `SaveFile` writes a versioned file per slot (restricted slot names, atomic write).
  - Loading restores by id into fresh content and reports what the content no longer has.
  - Tests: a restored network continues 30 days identically (orders, events, effects, statistics); a restored region finishes its experiment with the same Check and score; corrupt data, unknown ids, a wrong version and path escape are refused. 109 Godot tests.
- ✅ Simplify pass on step 6:
  - binary saves (`var_to_bytes`), because Godot's JSON rounds floats; checked in the engine;
  - `WorkOrder` and `ProblemState` own their `to_dict`/`from_dict`;
  - `RegionState` includes its network, so callers save one thing;
  - the simulation keeps 120 days of history (a two-year save would otherwise be about 1 MB and growing);
  - one shape check (`JsonFile.shape_error`), `ValueStream.step_index`, shared rules fixtures.
- ✅ Gate (2026-10-12): four value streams run headless with realistic KPIs; tests cover flow, pre-emption, rework, stock-outs, capacity, the PDCA loop and save/load. 107 Godot tests (about 1.5 s), 270 Python tests, content check clean.
  - Automated-testing review: every sim and rules class has tests for the happy path, invalid input and boundaries:
    - bounds and clamps;
    - corrupt saves, unknown ids, path escape;
    - weekends and midnight;
    - the WIP-limit sizing trap.
    Missions, story and UI are untested because they do not exist yet.
  - Technical-debt review:
    - Dead code: `Rng.exp_mean`, `pick`, `next` (factory leftovers) removed. Everything else unused in `src/` is the Region's public player API, waiting for the UI.
    - Annotations: no TODO/FIXME/HACK.
    - Docs: every script has a header comment; ARCHITECTURE.md is current.
    - Duplication: content rules live in both Python and GDScript (tracked above; decide with the Phase B schemas).
    - Dependencies: dev dependencies (`pytest>=`) are unpinned while the legacy runtime dependencies are pinned. Low risk; pin when CI shows drift.

## Phase B — Content (Dutch) ⬜
- ✅ Problem pipeline (plan: `docs/superpowers/plans/2026-10-12-phase-b-1-problem-pipeline.md`):
  - `content/problems_tier1.yaml` + `content/countermeasures.yaml`;
  - validator with cross-checks (steps, places, teams, tools, effects, the clue depth chain, a solvable countermeasure per problem);
  - the `Catalog` loader.
  - Godot content tests: everything loads and fits the real network; an expert can solve every problem (all key clues reachable, the Check passes); every problem hurts its stream through its mechanism (capacity, team load or wait) and, where strong enough, its named KPI.
- ✅ First six tier-1 problems (Dutch), 12 countermeasures, several per problem with different fits and shapes:
  - De onvolledige aanvraag
  - Meterkast niet gereed
  - De verkeerde mof in de bus
  - Maatwerk voor standaardwerk
  - Niet thuis
  - Vergunningen in batches: request daily, or in parallel with the design (`starts_with`), two healthier processes of a different shape
- ✅ Healthy base (Merijn's decision applied, 2026-10-12):
  - `value_streams.yaml` now has no team above ~85% (design 3.2 h, revision 1.6 h), so the flow is stable.
  - The starting constraint comes from the custom_design problem (Werkvoorbereiding ~110%).
  - Fixing it shows the next constraint: Intake at 86%.
  - Regression tests check the base and the starting state separately.
- ✅ Simplify pass on the pipeline:
  - `vocabulary.json` generated from the validator, with a Godot test that fails if the two languages' vocabularies differ;
  - one `problems_tier*` file rule (validator, cross-check, Catalog);
  - validator helpers per job, reusing `_number` and `_earlier`;
  - a shared real-network fixture and a shared base run (suite ~5.8 s).
- ✅ Three more tier-1 problems: de revisieberg (hidden; makes Revisie & GIS the constraint), graafschade (its root cause links to the revisieberg: outdated KLIC maps, so revision at the source also helps here) and de laatste kennisdrager. 9 problems, 18 countermeasures
- ✅ Failure demand (GDD simulation model):
  - a stream's `status_calls: {to, after_days, per_week}` makes customers of late orders call the contact stream; `call_rate` is a lever;
  - content: a klantcontactcentrum (4 agents since the tick fix below; 5 before) and a stream Klantvragen (380 questions a week, answered within 2 hours);
  - connections customers call weekly after three weeks; about 9% of calls in the healthy base.
- ✅ De statusbellers (problem 10): late orders call three times as often. Failure demand rises to 25–30% of calls; on time falls from ~0.9 to ~0.5, and with some seeds the centre tips into a spiral. Countermeasures: realistic promise date (tier 1) or proactive status updates (tier 2, halves even the base failure demand: a healthier shape than before the problem)
- ✅ Simplify pass on failure demand: one arrival-scheduling helper for value and failure demand; lateness counted without temporary arrays; the failure flag lives on the order (saved, and in finished records, so KPIs can separate failure from value demand)
- ⬜ Performance note: the contact stream adds ~20k call orders a year, so a simulated year now takes ~2.8 s (was ~1.7 s). Fine for play (a game year takes hours); revisit if the tests or fast-forward feel slow (e.g. calls as small batches)
- ✅ Klaar maar niet af (problem 11):
  - connections got an administrative close-out (a short wait, then EAN registration by Meetdata & registratie);
  - the problem makes it a monthly batch.
  - Systemic effect, emergent rather than scripted: connections lead p50 29 → 49 days, status calls 37 → 118 a week, contact centre on time 0.84 → 0.19. The contact centre's crisis comes from an admin batch two departments upstream.
  - Countermeasures: close-out at completion (tier 1) or automatic EAN registration (tier 3).
- ✅ Content review prepared: `game/tools/problem_report.gd` measures every problem on the real network (base, problem, each countermeasure at full strength; 5 seeds × 90 days); the shared doc shows texts, clues, effects, countermeasures and the measured impact per problem, with review questions
  - Found by the report: *Checklist bij de intake* could never pass the Check (0.8 × fit 0.6 = 0.48). Every listed countermeasure must now be able to pass at full strength (validator + Godot test on the real formula); fit raised to 0.7.
  - Region and the report share one rule for what a treated problem does to the sim (`Pdca.treated_effects`)
  - Found while writing the review: 12 clue texts were cut off in the game. An unquoted comma inside `{…}` split the text and YAML turned the rest into an extra key. The content loader now refuses that pattern and duplicate keys (`_StrictLoader`). Problems, countermeasures, clues and effects also reject unknown keys (typos). The clue texts are quoted.
- ✅ Review findings fixed with Claude's judgement while Merijn is away (his instruction, 2026-10-12): see "Claude's calls, pending Merijn" under Decisions Made
- ✅ Merijn answered the review's main questions (see Decisions Made); the review doc shows the recalibrated numbers (report over 5 seeds × 180 days, measured over the last 84) and the answers built in
- ✅ Review doc questions answered (2026-10-13, see Decisions Made)
- ✅ A fading fix brings its problem back through its mission (2026-10-13): the problem goes dormant, the solve mission reopens (no second reward), accepting it switches the problem on within the 1 + 3 limit
- ✅ First fork in the main quest (2026-10-13): after De stapel bij Werkvoorbereiding, Het knelpunt verschuift (intake: the bottleneck) and Meterkast niet gereed (monteurs: not the bottleneck, now a main mission with coach insights) open together
- ✅ Catalogue problems that need a new mechanism first:
  - ✅ KPI's die elkaar bevechten: overproduction, departments pushing work in. Design approved by Merijn (2026-10-13): departments get KPIs that set work rules (start push/pull, order, care); the player picks 2 of up to 5 per department at a quarterly review; the reward follows the measured improvement. Spec: `docs/superpowers/specs/2026-10-13-department-kpis-design.md`, plan: `docs/superpowers/plans/2026-10-13-department-kpis.md` (tasks 1–6 below)
  - ✅ Department KPIs, task 1: work rules in the simulation (2026-10-13). A pool gets `start_rule` (push / pull: hold a job while the next work step downstream has `pull_limit_days` = 3 or more queued, see `Network.queue_days`) and `order_rule` (first_come / oldest / shortest / due) as SET levers; push and first_come leave the base bit-identical. Mirrored in `build_content.py` (`start_rule`, `order_rule`, vocabulary). Next: the KPI definitions and effects on top (plan: `docs/superpowers/plans/2026-10-13-department-kpis.md`).
  - ✅ Department KPIs, task 2: probe of the work rules on the real network (2026-10-13). Intake + work_prep, 3 seeds (11-13) x 180 days, last 84 days, connections stream, means over seeds. (a) push + shortest + hasty care (touch 0.9, ftr -0.05 on intake/quote/design); (b) pull + oldest; (c) pull + first_come; (d) the habit. Run 1 is the content as it was, run 2 adds `stale_after_days: 30` at connections.intake (see below).

    | Run 1 (no stale rule) | lead p50 | lead p85 | on time | FTR | per week | wip_age | stale at design |
    |---|---|---|---|---|---|---|---|
    | (a) push + shortest + hasty | 46.5 | 68.6 | 97.4% | 34.6% | 26.47 | 90.9 | 0.0 |
    | (b) pull + oldest | 45.6 | 66.9 | 97.6% | 41.9% | 26.39 | 95.5 | 0.0 |
    | (c) pull + first_come | 45.6 | 66.2 | 97.8% | 42.3% | 26.39 | 96.2 | 0.0 |
    | (d) habit | 45.9 | 66.2 | 97.8% | 41.9% | 26.39 | 96.2 | 0.0 |

    Gate: (b) beats (a) on lead time but NOT on wip_age (95.5 vs 90.9: the hasty care of (a) also shortens the open age), so the stale rule was added: an application older than 30 days at intake goes back to intake and waits 5 days for the customer (estimate, marked in the YAML; never a bonus). `build_content.py` now allows `stale_to` to name the step itself (the first step has no earlier one); the validator test follows.

    | Run 2 (stale rule) | lead p50 | lead p85 | on time | FTR | per week | wip_age | stale at intake |
    |---|---|---|---|---|---|---|---|
    | (a) | 46.5 | 68.6 | 97.4% | 34.6% | 26.47 | 90.9 | 0.0 |
    | (b) | 45.6 | 66.9 | 97.6% | 41.9% | 26.39 | 95.5 | 0.0 |
    | (c) | 45.6 | 66.2 | 97.8% | 42.3% | 26.39 | 96.2 | 0.0 |
    | (d) | 45.9 | 66.2 | 97.8% | 41.9% | 26.39 | 96.2 | 0.0 |

    Findings: run 2 is identical to run 1 - intake queues only ~1 day (12-27 h), so no application waits 30 days and the stale rule never fires at base load. Pull and the order rules barely move the base: p50 45.6-46.5 days, throughput 26.4-26.5 a week. The open age (84-115 days) is mostly external waits (customer 14 d, permit 30 d, reinforcement 120 d), which no department rule touches. The real department effect is therefore care: hasty care (a) cuts first-time right from 42% to 35%. The department KPI mechanism has to rest on care and on the measured KPI, not on pull or order alone; the Check should name the KPI it expects to move.
  - ✅ Department KPIs, task 3: KPI menus in `content/kpis.yaml` (2026-10-13). Intake 5, work prep 5, planners 4, contact centre 3 KPIs (each pool has a leading and a lagging one), each with a Dutch name, kind, rules (start / order / care) and a note; `pull_limit_days` 3, care (careful touch x1.1 / ftr +0.05, hasty x0.9 / -0.05) and the review question are estimates, marked as such. `validate_kpis` (at most 5 per pool, known pool, kinds and rules from the vocabulary, mirrored as `kpi_kinds` / `care_rules` in vocabulary.json) and a `kpis` effect check (`{target: pool, property: kpis, value: [one or two ids from that menu]}`, accepted outside EFFECT_PROPERTIES). `KpiDef`, `KpiMenu.effects_for` (start / order on the pool, care as touch_time and ftr on each of the team's work steps; KPIs that disagree on a rule leave the habit) and `Catalog.kpis`, which expands `kpis` effects at load. Next: the problem `silo_kpis` (task 4, done below).
  - ✅ Department KPIs, task 4: KPI's die elkaar bevechten (2026-10-13). Problem `silo_kpis` (step connections.design, overproduction, kpi first_time_right): intake and work prep follow output + utilisation KPIs (push, shortest first, hasty care). `intake_output` and `work_prep_output` now also set `care: hasty` (rushing to hit a weekly number causes errors downstream, Goodhart's law; estimate), because the Task 2 probe showed care is where KPIs act. Countermeasures: `obeya_end_to_end` (tier 1, fit 1.0, pull + oldest first, `unlocks: kpi_board`), `connections_wip_limit` (tier 2, 0.8, limit 300 against a base of 230-270 started orders), `shared_team_goals` (tier 2, 0.7, pull + careful). Main mission `fix_silo_kpis` after the unused-capacity mission. New: `CountermeasureDef.unlocks` (validator + vocabulary), test that the countermeasure's work rules override the problem's. The harm test is now quality-aware for first-time-right problems (silo_kpis: ftr 0.42 to 0.36, about x1.17).
  - ✅ Department KPIs, task 5: the KPI board and the quarterly review (2026-10-13). `KpiBoard` (`rules/kpi_board.gd`), owned by the Region (`Region.use_kpis(menu)` builds it and sets every team's `pull_limit_days`). A passed Check of a countermeasure with `unlocks: kpi_board` (Obeya) unlocks it; the first review is due at the unlock (`kpi_review` event) and only sets the KPIs and the baseline, without reward (the Check already rewarded the Obeya); after that one every 91 days (`kpi_review` event once, stays due until done, no penalty). An empty menu gives `choose_two`. `Region.kpi_review(choices)`: every department on the menu, exactly 2 distinct KPIs from its own menu (errors `locked`, `not_due`, `unknown_department`, `choose_two`, `not_on_menu`; nothing changes on an error). The choice becomes effect source `board:kpis` (saved with the network). The first review sets the baseline and pays nothing. From the second on, reward = the mean relative change of lead p50, on time, FTR, throughput and wip_age against the best level reached so far, over the streams the departments touch, paid only above a 5 % dead band, × 1000 XP / €10,000 (estimates). Each KPI's change is capped at ±50 % and a stream needs 10+ completions in both quarters (estimates: small denominators make relative changes explode); see "Claude's calls, pending Merijn (2026-10-13, department KPIs)"; the coach's leading/lagging question comes back with it. Saved by `RegionState` under `kpi_board` (old saves load with a locked board; unknown departments and KPI ids are dropped). Next: task 6 (report, docs, review doc).
  - ✅ Department KPIs, task 6: report and review doc (2026-10-13). The problem report measures silo_kpis: connections first-time-right 42% → 35% with the problem, lead time and throughput flat (design is not the bottleneck); Obeya 43%, shared goals 44% (lead p50 +3 days), WIP limit 39%. Review doc section 18 and an Update 3 line added.
- ✅ Mission system (Merijn's design, CLAUDE.md §2): `MissionDef` + `Missions`.
  - At most one main and three side missions; unlocks by mission and belt.
  - Goals: walk / investigate / solve. Deadlines (Henk).
  - A coach (Marleen Verhoef, Directeur Netbeheer regio Zuidmark) who asks Kata questions per stage and shares an insight every third ask, about the main mission only.
  - Saves. The validator checks references, one mission per solved problem, a way in, and that every mission can unlock.
  - Tier-1 campaign: 11 main missions (walk the stream → the bottleneck chain with a fork after the first bottleneck → the grid-study queue at green belt → waiting for transformers → unused capacity) and 10 side missions, among them Henk's knowledge (a 56-day real event) and De planning die nooit klopt.
- ⬜ Mission UI: briefing and debrief dialogues, the coach conversation, a quest log with 1 + 3 slots (Phase D)
- ⬜ Missions beyond tier 1; story events (storm week, ACM visit, NTA 8120 audit) as missions
- ✅ Never game over (Merijn, 2026-10-12): an experiment can be paid into debt; in debt the region is in a bad period (every team −3 points availability, an estimate; no money to standardise) until the debt is paid off. Tests: paying into debt, costs causing a bad period, the period ending.
- ✅ Problems can cost money (Merijn: "claims should count"): `cost_per_week` is charged to the budget every day while the problem is open, weakened by a working countermeasure; the Check shows cost before and after; saved. Graafschade €4,250 a week (~5 extra damages × ~€850 direct repair; Wibon evaluation: €38.8M over 46,799 damages in 2022). De revisieberg: daytime outages ×1.05 (estimate from Bouwend Nederland's ~60% "not known what lies where"; marked as an estimate in the content), €425 a week.
- ✅ Evidence-based connection times (Merijn: "the industry norm"): norm back to 18 weeks (the former legal term, removed Feb 2025; the ACM still uses 18–22 weeks as reference). Real waits were ~40–44 weeks (Netbeheer Nederland 2024–2025), mostly from grid capacity, so the healthy base gets realistic external waits: customer approval 14 d, municipal consent 30 d, grid reinforcement 120 d for 15% of streets. Base: p50 ~7 weeks, ~92% within the norm. Customers call after nine weeks without news, every two weeks (32 calls a week in the base). Content tests and the report measure over 150–180 days so connections can settle.
- ✅ Graafschade and the norm (review findings): outage arrival sources have ids, and a `demand` effect can target one (`outages.daytime`). Graafschade adds half again to daytime outages (a third of them), so the harm is monteurs pulled off planned work. De revisieberg also adds daytime outages (outdated KLIC maps; now ×1.05, see costs below), so fixing GIS reduces digging damage. Delegated approval fit 0.6 → 0.65. (The interim six-week norm was replaced by the 18-week industry norm below.)
- ✅ Graafschade's harm made visible: steps count interruptions (`interrupted`), and stream KPIs include `lead_hours_per_week` (for outages: the hours customers are without power, count × duration, what the regulator measures). Monteurs 14 → 13 (~67% busy, back where the base was before cheaper failed trips; the technician shortage leaves little slack). Planned connection work absorbs interruptions (a two-day re-plan against a 40-day lead time), so Graafschade shows as outage hours and interrupted jobs, not as connection lead time.
- ✅ Short jobs use the whole tick (found by measuring actual load): a person who finishes mid-tick starts the next job in the minutes left. Before, a 15-minute call held an agent for 20 minutes, so short-task teams lost a quarter of their capacity (contact centre: actual 81% vs planned 55%). The contact centre is recalibrated to 4 agents (77% actually busy, 0.86 answered within 2 h); De statusbellers now takes it to 0.57 and Klaar maar niet af to 0.67 (was 0.40, which Merijn's review asked about).
- ✅ A failed attempt costs its own time (`fail_hours`; review question on Meterkast niet gereed): a wasted trip to a meterkast that is not ready costs 1.5 h, not the 5 h job; niet thuis costs 0.5 h. The outcome is drawn when work starts; `Capacity` counts it too.
- ✅ Actual load per team (`SimPool.load_since`): busy over present people-minutes per day, next to the planned load from `Capacity`. The status-callers review showed why: planned 55% while the queue explodes. Step statistics and pool load share `DailyCounts`.
- ✅ Common random numbers: one random sequence per purpose (`Rng.for_purpose`, registered by the network for saves), so a change in one place leaves every other stream's draws alone (test: a slower contact centre leaves connections, outages, meters and congestion identical). Three tests that leaned on the old shared sequence got honest margins (measured over seeds 1–10).
- ✅ De netstudie-wachtrij (catalogue #9): four in ten connections get a full grid study instead of a quarter. The grid analysts (shared with congestion) run 97% busy; connections keep their priority, so congestion throughput drops 43%: large consumers pay for the queue. Countermeasures: triage with a fast lane (tier 1), standard calculation templates (tier 2, also speeds up congestion studies).
- ✅ De zwijgende meter (catalogue #12): nobody tests the meter's connection before leaving; three in ten new meters stay silent and need a return visit (base: a failed registration now goes back to the appointment). Meters on time 0.88 → 0.75. Countermeasures: communication test before leaving (jidoka, tier 1, better than the base), coverage check in planning (tier 2).
- ✅ Three more catalogue problems, each with a mission:
  - Omvormers die afschakelen (#13): a new small stream Spanningsklachten (2 a week: analysis by Meetdata, a measuring week at the address, sometimes a tap change by the monteurs); the problem triples the complaints (Solar Magazine). Countermeasures: review the transformer taps per neighbourhood (tier 1), voltage data from smart meters (tier 2), targeted reinforcement (tier 3). Side mission after De zwijgende meter.
  - Wachten op de trafo (#15): transformers ordered only after the reinforcement design is approved, so the reinforcement wait goes from four to seven months (an estimate) and the congestion queue slows. Countermeasures: order at the grid study (tier 1), a framework contract (tier 2), strategic stock (tier 3). Main mission after De netstudie-wachtrij.
  - Gereserveerd maar ongebruikt (#14): contracted capacity is never compared with use, so the congestion queue moves slower and more requests must wait. Countermeasures: a usage dashboard (tier 1), use-it-or-lose-it conversations (tier 2, the ACM allows it), flexible contracts (tier 3). Main mission after Wachten op de trafo.
  - The validator now requires a mission for every problem, so the campaign reaches the whole catalogue.
- ✅ Storing gooit de planning om (2026-10-13, Merijn chose to approximate it): every monteur planned at 100%, so outages move appointments that do not hold (connections execution ftr −0.25, meter visits −0.1, re-planning doubles the planners' work; estimates). Countermeasures: a daytime outage crew (the existing `reserve` lever, tier 1), planning with fault windows (tier 2), heijunka (tier 3). Side mission after the outage walk. A real day-planning mechanic (an outage cancels the rest of a monteur's day) is left for later.
- ✅ `content/problems_tier1.yaml`: 18 of 18 catalogue problems done
- 🔧 `content/countermeasures.yaml`: 41 countermeasures; grows with each problem
- ✅ `content/missions.yaml`: the tier-1 campaign, with Henk's retirement as a 56-day deadline mission (De laatste kennisdrager)
- ✅ Henk is a real event (Merijn, 2026-10-12): a side mission that opens after De verkeerde mof in de bus; Henk retires 56 days later, taken on or not. Missing it closes the buddy system (`fail_closes`) for good; work instructions with video still solve the problem. Deadlines count from when a mission opens; the validator requires another way to solve the problem.
- ⬜ `content/concepts.yaml` (Lean + sector glossary, Dutch)
- ✅ KPI `wip_age` (`Network.open_age_days`, in `Region.snapshot`): the age of open work. Lead time counts finished orders only, so long waits hide the oldest work (survivorship).
- ⬜ Next session (found by report7, 5 seeds × 180 days):
  - ✅ `wip_age` named in Wachten op de trafo and in the report (2026-10-13). Why: its harm is invisible in finished-order lead time (43.5 vs 46.9 days) and shows only as throughput 26.9 → 25.5;
  - ✅ Omvormers (2026-10-13): a tap set for one address does not hold for the street (tap_change ftr −0.3, an estimate; a failed change goes back to measuring); KPI first_time_right, checked by the content test;
  - ✅ simplify findings (2026-10-13): `early_transformer_order` runs the reinforcement wait from the design (`starts_with`); the congestion ×1.2 is a marked estimate (station reinforcements wait for the same transformers); one stream list in the tests;
  - ✅ review doc (2026-10-13): sections 6 and 12 re-measured, sections 14–17 added, answered questions closed, Update 3 at the top

## Problem ideas backlog (keep growing)

Standing instruction from Merijn (2026-10-12): the v1 mix of 18 problems is fine, but the game needs more as it grows. Whenever a new problem idea fits the game or a difficulty tier, add it here, then promote it into the catalogue for the tier being built.

| Tier | Idea | Stream · waste | Grounding / note |
| --- | --- | --- | --- |
| 1 | LMRA as a tick-box: the last-minute risk analysis is a long generic form signed without looking | field work · over-processing | safety culture; stop-the-work |
| 1 | Contractor rework: jobs by contractors fail inspection and need a second visit | connections · defects | contractor model |
| 2 | Cause recorded as "onbekend": most outage causes are never classified, so repeat faults stay invisible | outages · defects | Nestor outage registration |
| 2 | Control-room shift handover loses open actions | outages · waiting | — |
| 2 | Heatwave transformer overload: no load monitoring on distribution transformers | congestion · defects | summer events |
| 3 | No space under the street (ondergrondse drukte): coordination with gemeente and other utilities | connections · waiting | — |
| 3 | Nitrogen permits delay a substation project | reinforcement · waiting | construction exemption scrapped; >300 Liander projects late |
| 4 | Power theft and grid losses: cannabis farms hidden in the data | grid · defects | ~1 billion kWh a year |
| 4 | NTA 8120 / ISO 55001 audit finding: maintenance not risk-based (oil-paper cables, old joints) | assets · over-processing | NN-CAM 5.0 |
| 4 | Gas-grid maintenance while the grid is being phased out (heat transition) | gas (later) · over-processing | — |
| 2 | Safety stock sized on calendar days while demand only comes on working days: a 10-day lead time holds 8–9 working days, so the reorder point is too low and meters or kits run out "unexpectedly" | meters, connections · waiting | found while tuning the simulation (2026-10-12) |
| 2 | Work in progress handed over at the end of a shift without notes: the next crew starts the fault-finding again | outages · over-processing | handover is now simulated |
| IT | Field app releases twice a year; every fix waits for the release train | IT · waiting | Phase G |
| IT | Test environments scarce; teams queue for them | IT · waiting | Phase G |

## Phase C — World: campus + town ⬜
- ⬜ Campus buildings and rooms with visible WIP (in-trays, planning boards, warehouse racks)
- ⬜ Town: streets, homes with solar/heat pumps/EV chargers, substations, industrial estate
- ⬜ Vans driving to jobs; crews working at sites; outages darken streets
- ⬜ NPCs per department; pathfinding across campus and town

## Phase D — UI (Dutch) ⬜
- ⬜ HUD (week/day clock, KPIs per stream), gemba toolkit, conversations, A3, Check/Act, value stream map per stream (built by walking it), notebook, codex, NPC dialogue, onboarding by the Lean coach

## Phase E — First playable and playtest ⬜
- ⬜ First playable vertical slice (one value stream end to end), shared privately with Merijn once it is worth playing
- ⬜ Playtest round with Merijn → tuning backlog

## Phase F — Depth and regions ⬜
- ⬜ Tier 2–4 problem catalogues; more regions unlock with maturity; strategic layer (prioritisation framework, capacity investments, contract types)

## Phase G — IT value streams: SAFe / Agile / DevOps ⬜
- ⬜ IT department on campus; value streams for field-app features and incident handling
- ⬜ Problems: long release cycles, dependencies between teams, PI planning theatre, manual testing, environment scarcity, ops/dev handoffs, technical debt
- ⬜ Countermeasures: ART alignment, WIP limits, CI/CD, DORA metrics, value stream identification

## Phase H — AI coach and free-text conversations ⬜
- ⬜ Optional Claude-powered conversations with NPCs, grounded in each problem's hidden facts, so "asking the right question" can be fully free text

---

## Decisions Made

- **Prototype and KPI reward (Merijn, 2026-10-13, multiple choice).**
  - **The 3D world comes first** for the prototype (est. 1.5–2 months to first play). The first piece is **one building with one mission**: the connections office (Intake, Werkvoorbereiding), walkable, with its gemba tools and one mission playable end to end.
  - **3D style: semi-realistic.** Models are built by script in Blender (`bpy` from PyPI) and exported to Godot as glTF. CC0 textures (Poly Haven, ambientCG) are used once the environment allows their domains.
  - **KPI board reward: counterfactual, paid at the review.** From the same moment, the coming quarter is simulated twice with common random numbers, once with the old KPIs and once with the new ones, and the review pays the difference. The coach words it as a forecast.
  - **Autonomy: design, then build.** Claude writes the designs and builds; calls Merijn hasn't made are listed under "Claude's calls, pending Merijn".

- **Problems only through missions; occasional forks (Merijn, 2026-10-13).** Never more than one main and three side problems at a time, and no free menu of problems. Sometimes the main quest forks into a bottleneck and a non-bottleneck problem, so the player has to prioritise. Recorded in CLAUDE.md §2.
- **Review answers, round 2 (Merijn, 2026-10-13, multiple choice).**
  - **Kept as built:** the close-out spiral (mild); Henk; the bad period (−3 points); trafo ×1.75; 3 in 10 tap changes that don't hold; 62% use of contracted capacity; use-it-or-lose-it at tier 2; 9 in 20 incomplete applications; the wrong joint ×1.5; three signatures; design +30%; a two-day re-plan for pulled monteurs; 4 in 10 grid studies; 3 in 10 silent meters; 1 in 10 failed registrations in the base; a measuring week, with 4 in 10 ending in a tap change. The earlier "kept as they are" values were also confirmed.
  - **Changed:** voltage complaints 2 → 5 a week in the base (15 with the problem); permits batched per project (about every two weeks, an estimate) instead of a weekly run; the grid analysts serve congestion requests before connections, so connections now pay for De netstudie-wachtrij.
- **Core directives (Merijn, 2026-10-12).** A learning game about continuous improvement (Lean, later IT/Agile/DevOps/SAFe) in the energy sector; people are the most valuable resource; an RPG where the player searches and thinks; fix processes end to end (a non-bottleneck fix brings nothing); a strong focus on measuring (KPIs, OKRs); the 8 wastes and sector issues come up often. Recorded in CLAUDE.md §2.
- **Never game over (Merijn, 2026-10-12).** Claims cost money and the region can go into debt and a bad period, but the company never goes down.
- **Henk is a side mission with a deadline (Merijn, 2026-10-12).** Missing it means doing without the knowledge transfer: the countermeasures that need Henk are gone; the problem can still be solved another way.
- **Superpowers is a core skill (Merijn, 2026-10-12)**, in CLAUDE.md §3.
- **Mission system (Merijn, 2026-10-12).** The game is a progressive RPG: missions unlock new and harder missions as the player progresses. At most one main mission and three side missions are active at once. A senior manager coaches, mostly by asking questions, and only on the main mission. Recorded as a standing rule in CLAUDE.md §2.
- **Review answers (Merijn, 2026-10-12):**
  - connections norm: the industry norm (the 18-week term the ACM still uses as reference);
  - digging-damage claims count as money;
  - failed trips 1.5 h / 0.5 h: fine;
  - the revision backlog's effect on digging damage is based on evidence where it exists;
  - the intake checklist is a real but weak improvement;
  - Henk: explained (the retiring expert in De laatste kennisdrager's clues), proposed as a deadline mission.

### Claude's calls, pending Merijn (2026-10-12)
Merijn asked me to fix the content review's findings with my own judgement while he is away. Each call is easy to reverse, and the same questions sit in the review doc.
- ~~Connections norm: six weeks~~ → answered: the 18-week industry norm.
- **Graafschade hurts through pulled monteurs**: daytime outages ×1.5, and planned connection work is interrupted and re-planned. Answered: claims count too (€4,250 a week).
- **A failed trip costs the trip** (1.5 h at a meterkast that is not ready, 0.5 h when nobody is home), not the full job.
- **De revisieberg feeds Graafschade in the simulation**, not only in the clues. Answered: base it on evidence; now +5% daytime outages and €425 a week, marked as an estimate.
- **Kept as they are, plausible and grounded:** the contact-centre spiral of Klaar maar niet af, the monthly EAN batch, three times as many calls from late customers, 40 minutes to the warehouse, two of five meterkasten not ready, three of eight not at home, 240 open revisions.
- **Henk becomes a story hook** for the missions (built: a deadline mission); the buddy system's team hours stay as they are.
- ~~Still open: the contact-centre spiral~~ → answered 2026-10-13: keep it mild.

### Claude's calls, pending Merijn (2026-10-13, department KPIs)
Rulings I made while building the KPI board without you; each is easy to reverse.
- **Output KPIs also make a team hurry.** `intake_output` and `work_prep_output` set `care: hasty` besides push + shortest first (the spec table had push + shortest only). The probe showed care is where KPIs act in the simulation; rushing for a weekly number is Goodhart's law. Revert: two lines in `content/kpis.yaml`.
- **KPI's die elkaar bevechten names first-time-right** as its KPI instead of the age of open work: the harm shows as rework (FTR 42% → 35%), not as waiting, because design is not the bottleneck.
- **The first review only sets the baseline** (no reward): the Check already paid for the Obeya fix that unlocks the board.
- **The reward only pays for real, lasting gains**: each measure is compared with the best level reached so far, only on streams the departments touch, and only the part above a 5% dead band pays; each KPI's change is capped at ±50% and a stream needs 10+ completions in both quarters (all estimates). The final review measured that without this the board paid for noise and for recovering from a bad quarter.
- ~~**Open question for you:**~~ → answered 2026-10-13: (b), the counterfactual reward, paid at the review (it replaces the best-level guard above). The question was: in the simulation a department's KPI choice moves the end-to-end numbers less than quarter-to-quarter noise, so with the guard above the board almost never pays (measured: 1 payout of 0.002 in 24 quarterly reviews with nothing changed; each measure's best level is set by a lucky quarter). Options: (a) keep it: the lesson is that targets matter less than fixing the process; (b) a counterfactual reward: at the review, simulate the quarter with the old and the new KPIs and pay the difference; (c) stronger KPI effects (care, pull) so the choice shows in the numbers. The board also cannot tell a KPI gain from another mission's fix in the same quarter.
- **Precedence:** an open problem's rules beat the board; the board beats a solved problem's countermeasure (reordered with `Network.move_effects_last`, so a running WIP limit is never released); a running experiment still overrides the board.

- **Many healthier processes, not one (2026-10-12).** Problems list several countermeasures with a fit (0–1); each countermeasure brings its own effects and levers, so different players end up with different, all improved, processes. Content values are a reasonable base; the starting problems are active effects on top.
- **What WIP costs (2026-10-12).** Dossiers go stale when they wait too long (quotes, permits, designs need work again); this is what makes WIP limits pay off in the simulation.
- **GDD answers from Merijn (2026-10-12)**: company name Voltana Netbeheer stays; the town is called Nova; a narrative arc with side quests and some open-world freedom; improvements cost both euros and team hours; model ACM regulation and ISO / NTA 8120 asset management; no own energy-sector cases, so content is research-based; sessions of 15–40 minutes; desktop first
- **Problem catalogue keeps growing (2026-10-12)**: the v1 mix is approved; new problems are added continuously via the backlog above, per difficulty tier
- **Pace (2026-10-12)**: multi-month project; design first, reviewed increments, no publishing deadline
- **Grid operator setting (2026-10-12)**: fictional DSO "Voltana Netbeheer", campus + one town; player is CI-lead; game text Dutch
- **Engine: Godot 4 + GDScript from the start (2026-10-12)**, at Merijn's suggestion. The goal is a desktop game, and porting a TypeScript simulation later would mean rewriting all logic. GDScript (not C#) keeps a web export possible. Godot runs headless here, so logic tests run and scenes can be screenshotted (Xvfb + OpenGL compatibility renderer, verified with 4.4.1). The Three.js prototype in `web/` is superseded (kept in `archive/factory-3d/`)
- **Problem solving is action-based, not multiple choice (2026-10-12)**: clues are earned through tools and questions; the player writes the A3; the simulation judges the countermeasure
- **Bottleneck first (2026-10-12)**: Check always shows end-to-end capacity per value stream; improving a non-constraint is called out
- **Shared resources (2026-10-12)**: monteurs are one pool across streams with priorities, so outage-driven disruption of planned work emerges from the simulation
- **Factory work archived (2026-10-12)**: `archive/factory-3d/` + commit `b3a4c8c`; the Python factory game stays runnable as the legacy build

---

# Legacy build plan — Python factory game (frozen)

Spec reference: `Lean_Factory_v2.0_Specification.docx`. Kept for history; no further work planned.

### Learning Pillars (design principles — applies to every phase)

This game is a **learning tool** for lean, six sigma, and factory digitalization. Every feature must serve these three pillars. When a task in any phase conflicts with a pillar, the pillar wins.

1. **Learn by doing — safely.** The player must be able to make mistakes without instant hard punishment. Wrong choices reduce effectiveness, surface a lesson, and allow recovery (rollback, retry, NPC redirect). No dead-ends. No game-over from a single bad call. Recovery is always possible — often it *is* the lesson.
2. **NPC-guided decision forks.** Key moments — investigation, 5 Whys, kaizen, countermeasure selection, digitalization choices — are presented as **multiple-choice branches** offered by NPCs: "what should we check next?", "what should we verify?", "what should we implement?". Every fork must include at least one correct option, one plausible-but-wrong option, and optionally a clearly-wrong option. Wrong options still teach: the NPC explains *why* in lean terms, then lets the player try again.
3. **Teach the concept, not just the button.** When a lean, six sigma, or digitalization concept first appears in play (kanban, SMED, SPC, jidoka, MES, digital twin, etc.), introduce it in-fiction through an NPC — one short, skippable explanation. The button comes after the concept, never before it.

---

### Phase 0 — Design Foundations ✅ COMPLETE
All design artifacts: spec doc, 25-problem Tier 1 catalog YAML, 79-countermeasure YAML (merged), topology files.

---

### Phase 1 — Simulation Core (Headless) ✅ COMPLETE
- ✅ Station model (OEE, cycle time, WIP, quality)
- ✅ Operator model (skill, fatigue, state)
- ✅ Material flow, time engine with speed multipliers, factory aggregator
- ✅ Metrics calculation (live KPIs), SQLite persistence (save/load), headless mode
- ✅ Bug fixes: `field()` crash, stop probability formula, tick calibration, injection rate
- ✅ Verified: Day 1 output = 14 hoverboards (exact spec target), OEE ≈ 39%, FTR ≈ 83%

**Deliverable:** Headless mode runs cleanly for N days and prints metrics. ✅

---

### Phase 2 — Navigation and Rendering ✅ COMPLETE
- ✅ Tilemap, player sprite, camera, collision detection, interaction zones
- ✅ Factory rendering (zone colors, station sprites, operator sprites)
- ✅ HUD (clock, speed, KPI strip, minimap), inspector panel (station metrics, NPC dialogue)
- ✅ Shift-to-run: holding Shift moves at 2.5× speed (RUN_MULT = 2.5 in player.py)
- ✅ Code-reviewed; runtime visual test pending first play session

**Deliverable:** Walkable factory. Player navigates floor, sees stations, inspector opens on E. ✅

---

### Phase 3 — Problems and Inspection ✅ COMPLETE
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

### Phase 4 — Countermeasures and Scoring ✅ COMPLETE
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

### Phase 5 — Guided Learning, Decision Forks, and Mistake Recovery 🔧 ~75% COMPLETE

NPC forks are **deterministic, YAML-driven dialogue trees** — separate from the AI coach (Phase 8). Forks scaffold the *decision*; the coach reflects on it.

#### Done

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
- ✅ **CM selection fork** (session 2026-04-24): when the catalog opens, the source NPC (from the problem's investigation fork) proposes a 3-CM shortlist at the top of the panel — correct + same-category distractor + different-category distractor. Selectable via `[1][2][3]` or the usual arrow-scroll. `_build_shortlist` in `main.py`; rendered via `CatalogPanel._draw_shortlist`.
- ⬜ **DMAIC workflow scaffold**: Define → Measure → Analyze → Improve → Control as multi-stage A3 form; unlocks gradually

### Remaining — mission system

- ✅ **Mission HUD indicator**: small active mission title + current hint shown in a corner of the HUD when a mission is active; nothing shown when no mission is active
- ✅ **Mission briefing dialogue**: when a mission activates via NPC interaction, the NPC delivers the narrative briefing as a short dialogue exchange (framed as invitation, never a command)
- ✅ **Mission ordering / availability cap**: `visible_after:` prerequisite field on `Mission` gates each mission behind a predecessor. Chain: M-T1-001 (auto) → M-T1-002 + M-T1-003 (need M-T1-001 done) → M-T1-004 (needs M-T1-002) → M-T1-005 (needs M-T1-003). Only M-T1-001 surfaces on day 1; subsequent missions unlock progressively.
- ✅ **Mission completion notification**: source NPC panel shows "MISSION COMPLETE" + per-mission debrief text when mission is completed (`_MISSION_DEBRIEFS` dict in inspector)
- 🔧 **Lean Coach NPC** (session 2026-04-24, character added): Alex the Lean Coach now stands at tile (95, 8) in the Operations room with their own desk (OPS-COACH). Signature flavor line: "Show me the problem. Not the report — the problem." Sprite + role-look mapping done. **Still to author**: dedicated kaizen/DMAIC missions with Lean Coach as source NPC (Phase 6 content authoring).
- ✅ **NPC awareness hints**: `_NPC_AWARENESS` dict in inspector; 12 (role, mission_id) entries; ambient line replaces static NPC quote when a nearby mission is active
- ✅ **[BUG] Progression stalls after the first 3 problems solved** (fixed 2026-04-24): root cause was a "good play soft-lock" — M-T1-002 triggers on `ftr <= 0.88`, M-T1-003 on `wip >= 65`; a player who applied good CMs pushed FTR above 0.88 and WIP below 65, so the KPI triggers never fired after M-T1-001 completed. Fix (option a from the previous plan): added `trigger_ever_met: bool` sticky flag to `Mission` (`problems/mission.py`) plus save/restore, reworked `_check_mission_triggers` in `simulation/mission_engine.py` to always call `_mission_trigger_met` (even before the `visible_after` prereq completes) so the sticky flag tracks KPI crossings across the full session. Also wired `_check_mission_triggers()` + `evaluate_visibility()` into `resolve_problem` so downstream missions activate immediately on resolve instead of only at day-end. Verified with a scripted scenario: good-KPI factory state + resolve first problem → M-T1-002 and M-T1-003 both activate, new problem T1-003 surfaces.

### Remaining — safety nets

- ✅ **FTR floor circuit breaker**: FTR < 60% logs `ftr_floor` event and slows simulation to 1× (consistent with WIP ceiling pattern)
- ✅ **Side-effect suppression**: `_active_problem_cap_reached` guard in `apply_countermeasure` — harmful side-effects suppressed when at cap
- ✅ **Daily auto-snapshot**: currently auto-saves every 5 real minutes — change to trigger on in-game day boundary so player can always restart from yesterday's state
- ✅ **No hard fail state for bankruptcy** (session 2026-04-24): `Factory.recovery_mode` flag flips True when credits hit zero; exits when credits climb back past 150 OR 7 in-game days elapse. During recovery, rollbacks are free (no 25% penalty) so the player can re-experiment freely. HUD shows a warning-styled "RECOVERY WEEK" banner under the top bar. Entry/exit logged as circuit-breaker events for narrative framing. Save/load persists the state. 5 regression tests in `tests/test_factory_cm_flow.py`.

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

### Phase 6 — Tiers 2–4 Content + Final Packaging ⬜ NOT STARTED

Content design happens *after* Phase 5 so every new problem uses the settled dialogue-fork YAML schema (`teaches:`, `dialogue:`, `five_whys:`) from day one.

### Content
- ✅ Tier 2 problem catalog: 15 problems in `data/problems_tier2.yaml` (session 2026-04-24) — all have `teaches:` + `dialogue:` investigation forks; T2-001/003/005/008/015 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Codex fully covers Tiers 1+3: 164 concepts, all 161 teaches tags mapped (session 2026-04-24)
- ✅ Tier 3 problem catalog: 15 problems in `data/problems_tier3.yaml` (session 2026-04-24) — all have `teaches:` + `dialogue:`; T3-002/007/009 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Tier 4 problem catalog: 12 problems in `data/problems_tier4.yaml` (session 2026-04-24) — SPC/MSA/DMAIC/FMEA/DOE/8D/regression/reliability; T4-002/004/012 have `five_whys:` (2 steps each); pending Merijn review
- ✅ Codex fully covers Tiers 1–4: 197 concepts, all 196 teaches tags mapped (session 2026-04-24)
- ✅ Tier progression visibility verified (session 2026-04-24): 18 missions across 4 tiers; multi-tier loader; hidden problems activate after peer resolved; 23 new tests; 198 total passing
- ✅ Tier 5 stub in UI: locked "Coming in v2" row at bottom of catalog panel (session 2026-04-24)
- ✅ Specialist hiring system (session 2026-04-24): `simulation/specialist.py`; 6 zone types; `factory.hire_specialist()`; [H] key in inspector; save/load; 500 credits each
- ✅ Full save/load verified (session 2026-04-24): T2–T4 problem runtime state, specialists, missions all persist correctly via existing by-ID mechanism

### Packaging

> **When to switch to .exe:** Build the first exe at the end of Phase 6 — once all game content is stable and 198 tests pass — so Phase 7 UI work can be tested as a real build rather than via Python scripts. The exe gate is: all four tiers playable, no open bugs, assets folder populated. Don't build earlier; assets are empty until Phase 7 graphics work begins.

- ✅ `requirements.txt`: already uses `pygame-ce==2.5.7` (pinned, correct)
- ⬜ Add icon (`assets/icon.ico`)
- ⬜ Populate `assets/sprites/`, `assets/tilesets/`, `assets/sounds/`
- ⬜ Update `lean_factory.spec` for populated assets
- ⬜ Build `lean_factory.exe` with PyInstaller — **trigger: Phase 6 complete, assets populated**
- ⬜ Test standalone exe on a clean machine (no Python installed)
- ⬜ Create installer or zip distribution

### Architecture debt (tracked from skills audit 2026-04-23)
- ✅ **`ui/inspector.py` split** (994 → 218 lines): all `_draw_*` methods + content dicts in `ui/inspector_drawing.py` as `InspectorDrawMixin`; `Inspector(InspectorDrawMixin)`. No behaviour change. (session 2026-04-24)
- ✅ **`simulation/factory.py` split** (712 → 351 lines): `apply_countermeasure`/`rollback`/`resolve`/`decay` → `simulation/countermeasure_engine.py` (245 lines); mission triggers → `simulation/mission_engine.py` (70 lines). Factory is a clean orchestrator. (session 2026-04-24)

**Deliverable:** Complete v1 game. All four tiers playable. 70–80 hand-designed problems, all with dialogue forks. Standalone exe.

---

### Phase 7 — UI Polish, Progression, and Story ⬜ NOT STARTED

> **Design note (from session 2026-04-23):** Current UI is functional but not inviting — raw rectangles, low contrast, no visual hierarchy between panels and world. Phase 7 should feel like a different product. The deliverable is a game someone unfamiliar with the project can sit down with and find visually clear, progression they can feel, and a story that makes them care. Defer all visual work until Phase 6 content is done.

> **Graphics priority (added 2026-04-24):** The current visuals — solid-colour rectangles for player and stations, flat HUD panels, no sprite art — need a full overhaul before the game can be shown to anyone outside the project. Phase 7 must replace all raw rectangles with illustrated sprites, give each zone a distinct visual identity, and bring inspector panels and HUD up to a modern game standard. This is non-negotiable for the Phase 7 deliverable.

> **Aesthetic target (added 2026-04-24):** The reference is Pokémon DS — top-down, small characters with visible arms and legs, tilemap that reads as a real place. For Lean Factory specifically that means: player and NPC sprites look human (head, body, arms, legs, hi-vis vest for operators), production lines animate hoverboard parts actually moving along them (deck → coils → board → battery → test → box), and the HUD/inspector panels feel like a game not a spreadsheet. Implementation approach: programmatic sprites drawn from pygame primitives (layered shapes, hand-chosen palette) since no pixel-art pipeline exists. Upgrade path later: swap primitives for sprite sheets if Merijn commissions or sources art.

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

- ✅ **[BUG] Bottom-left of layout is unreachable** (fixed 2026-04-24): both south-wall doors from the factory floor to the south wing were placed at cols 14 and 48, which sit directly underneath the Burn-in rig (cols 13–17 rows 28–29) and the Packaging line (cols 45–54 rows 28–29). Player could never approach either door — no path existed. Fix in `navigation/tilemap.py`: moved maintenance door to col 11 and locker door to col 40, both in clear channels between testing stations. BFS reachability check from spawn now reaches all five maintenance objects (Tool Crib, Maintenance Lead Desk, Repair Bay, Spare Parts Shelves, TPM Board) and all locker tiles.
- ✅ **Kenney CC0 sprite packs integrated** (session 2026-04-24): four packs unzipped to `assets/kenney/` — RPG Urban (characters + urban tiles), Tiny Town (village tiles), 1-Bit (monochrome misc), Industrial Expansion (conveyors, chains, pipes, hazard signs). `rendering/sprites.py` loader extracts tiles from each pack's packed tilemap PNG and caches scaled surfaces at TILE_SIZE (24).
- ✅ **Animated player sprite** (session 2026-04-24): 2-frame walk cycle driven by `Player.step_phase`; sprite sourced from RPG Urban character row 4. Side-view sprite is mirrored for left-facing. Falls back to a single frame when the player is idle. The earlier programmatic `rendering/chibi.py` kept as a fallback.
- ✅ **Animated NPC sprites** (session 2026-04-24): each role is mapped to a distinct RPG Urban character row via `_ROLE_CHAR_ROW` — Team Leaders, Scheduler, Quality Lead, IT Engineer, HR Manager, Maintenance Lead, Controller, Plant Manager. Rendered facing the direction specified on the NPC object.
- 🔧 **Station sprites with more visual detail** (partial 2026-04-24): each station now shows a centered industrial-expansion tile (conveyor belts for packaging + integration lines, gears for machining, control boxes for assembly cells, chains for dock/shelves, alarm for burn-in, warning sign for flight test). The underlying station body is still a solid rounded rectangle — a full zone-specific station sprite overhaul is future work.
- ⬜ **Animated hoverboard-parts on production lines**: render material flow along Final Assembly and Packaging lines — small deck/coil/battery/board icons that move stage-to-stage at the live simulation rate. Needs a flow-engine hook to know which station is producing.
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
- ✅ **Arrow key conflict fix** (session 2026-04-24): movement guard in `main.py` now includes `inspector.is_open`; arrow keys scroll the panel cleanly, no simultaneous player movement.
- ✅ **Enforce investigation-before-countermeasure sequence** (session 2026-04-24): `_investigation_required()` helper in `ui/inspector_drawing.py` gates `[C]` — the hint reads "Investigate first — pick [1][2][3] below" until the fork is complete. Same gate in `handle_action_key` prevents pressing [C] early. Problems without a dialogue fork bypass the gate.
- ✅ **Score explanation on resolve** (session 2026-04-24): `scoring.metrics.explain_scores()` returns one short reason per metric (DQQ/EI/RCA/CMP/LM/CIM) matching the achieved tier. `resolve_problem()` returns `explanations` in the result dict; `ScorePanel.show()` renders the reason under each score bar.
- ✅ **One question at a time per station** (session 2026-04-24): when a station has multiple active problems, the inspector used to render every problem's dialogue fork stacked vertically — ambiguous which `[1][2][3]` a keypress answered. `InspectorDrawMixin._problem_has_pending_question()` now identifies the single problem owning the active question (investigation fork, 5 Whys, verification, or revealed-choice reveal), and only that one renders its fork. Other problems with pending questions show "Queued — finish the current question first" instead. Input routing already picked first-match via `break`, so the draw now matches the input behaviour.
- ✅ **[BUG] `score_rca` / `score_cmp` ID-vs-name mismatch** (session 2026-04-24): both functions compared the CM id against `problem.effective_countermeasures` (a list of CM *names*), so RCA and CMP almost always scored 1 even when the correct CM was applied. Fixed in `scoring/metrics.py` (parameter renamed `applied_cm_name`) and `simulation/countermeasure_engine.py` (`resolve_problem` now resolves `cm.name` via the catalog and passes it through). Regression test added in `tests/test_factory_cm_flow.py` — applying 5S System (CM-T1-001) to a problem whose `effective_countermeasures` contains "5S System" now scores RCA=5 and CMP=5. 212 tests passing.
- ✅ **[BUG] Every fork / quiz answer always in position 1** (session 2026-04-24): when the user reported "the answer is always 1" persisting, root cause turned out to be entirely separate from the scoring bug — every one of 67 investigation forks, 34 5-Whys steps, and 40 implementation-quiz questions authored CORRECT as choice 1. Players learned "press 1" within minutes. Fix: `random.shuffle` added at parse time in `problems/dialogue.py` (`_parse_investigation`, `_parse_five_whys_step`, `build_verification_fork`) and `problems/countermeasure.py` (`_parse_quiz`). Choice recording is by content (`outcome`/`text`/`teaches`), not index, so shuffling is safe across save/load. Existing positional tests in `tests/test_dialogue.py` and `tests/test_phase5_pdca.py` updated to assert by outcome instead of position.
- ⬜ **[Known] DQQ=5 unreachable in Phase 6 gameplay**: `score_dqq` requires at least one `diagnostic_*` metric in the inspection log, but no runtime code logs one. Deliberate: reserved for Phase 7b "Unlockable diagnostic tools" (Spaghetti Diagram, SPC chart). Until then, DQQ tops out at 3. Tracked here so it is not mistaken for a bug.
- ⬜ **[Known] EI=5 only reachable for flow/people CMs**: `score_ei` metric_match requires "quality" observed for quality/maintenance CMs, but the inspection log only ever records `metric="oee"`. Flow CMs pass because "oee" satisfies the flow branch. Consider later: log multiple metrics per inspection (oee + quality + wip) or relax metric_match to treat "oee" as universal evidence.
- ✅ **Station inspection gives contextual hint** (done 2026-04-24, option a): inspector now shows a "FLOOR NOTE" section on stations without an active problem, pointing to the zone where the nearest active-mission problem lives. `_floor_hint_for_mission` helper in `ui/inspector_drawing.py` walks active missions' `problem_ids`, skips resolved/dormant problems and the current station, and produces a one-line hint using friendly zone names (`_ZONE_FRIENDLY_NAMES`). Exploration now provides learning feedback instead of silence.
- ⬜ Non-blocking toast notifications: CM decay warning, new problem visible, credits earned — timed banner, never freeze gameplay
- ✅ **Keyboard shortcut reference** (session 2026-04-24): `[F1]` toggles a non-blocking overlay listing every control grouped by context — Movement, Time, Panels, Inspector, Catalog, Dialogs. `ui/help_panel.py`; wired at the top of the event loop in `main.py` so F1 is available globally and the overlay absorbs all non-F1/Esc keys while open. Movement and other panels are gated on `not help_panel.is_open`.
- ⬜ Problem count HUD badge: active problem count visible at all times (e.g. "⚠ 3 active")
- ⬜ Maturity/phase progress bar in HUD: zone scores visualised at a glance

### Countermeasure Learning Flow

> **Design note (added 2026-04-24):** Applying a CM should be a learning moment, not just a button press. The player should understand *how* to implement the chosen countermeasure, not just *that* they applied it. This closes the gap between "I clicked 5S" and "I understand what 5S implementation involves."

- ✅ **CM implementation quiz infrastructure** (session 2026-04-24): `QuizStep` + `QuizChoice` dataclasses in `problems/countermeasure.py`; loader parses `implementation_quiz:` YAML; `ui/quiz_panel.py` renders 2-question fork with CORRECT/PLAUSIBLE/WRONG choices and feedback. Wired catalog → quiz → warning → apply in `main.py`. Correct answers boost CIM at resolve time (capped at 5) and unlock teaches tags via `factory.discover()`; `session.quiz_correct_count` persists across save/load. 13 new tests.
- ✅ **CM implementation quiz content — Tier 1 complete** (session 2026-04-24): all 10 Tier 1 CMs now have 2-question quizzes. New this session: CM-T1-003 Safety Routines (HR Manager), CM-T1-005 Workplace Organization (Team Leader), CM-T1-008 Cleanliness Standards (Team Leader), CM-T1-009 Basic Documentation Control (IT Engineer), CM-T1-010 Skill Matrix (HR Manager). Tier 2/3/4 CM quizzes still to author as prioritised by playtesting.
- ⬜ **Quiz skip penalty**: currently [Esc] skips the remaining questions with no CIM bonus (correct behaviour). Consider adding a small credit cost on skip to discourage power-skipping once playtesting shows it's actually abused.

### NPC Interactions

- ⬜ Multi-line NPC dialogue: NPCs have 3–5 rotating lines that change as factory matures or problems are solved
- ⬜ NPC awareness: operators comment on nearby active problems when inspected ("that shelf's been a mess for weeks")
- ⬜ Character portraits: small illustrated avatar per NPC role shown in the inspector panel
- ⬜ "Walk-up" animation: brief highlight / icon appears above NPC head when player is in range

### General UX

- ✅ **[BUG] Arrow key conflict when inspector is open** (session 2026-04-24): fixed — see Inspector and Panels section above.
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

### Phase 7b — Player Experience Enhancements ⬜ NOT STARTED

> **Scope:** follows Phase 7 polish. Phase 7 takes the game from "raw rectangles" to "looks like a game"; Phase 7b takes it from "looks like a game" to "actually teaches someone who picks it up cold." Where Phase 7 is about surface (sprites, HUD, story), Phase 7b is about depth (onboarding, reflection, progression feedback, emotional investment). Items listed in approximate order of expected impact on first-time-player experience.

### Onboarding and guidance

- ⬜ **Day 1 tutorial / onboarding flow**: a new player is currently dropped in with no explanation of the control scheme, the mission system, or what the goal is. A short guided Day 1 (Plant Manager greets → walk to first NPC → try your first investigation → resolve your first problem) dramatically reduces friction for anyone new. Implement as a skippable intro gated on save-file-is-empty.
- ⬜ **Context-sensitive help `[F1]`**: overlay listing the keys relevant to the current state. Inspector open → E/C/R/U/1/2/3/S/A/H; catalog open → ↑/↓/E/Esc; free roaming → W/A/S/D/Shift/Esc/K/Tab. Removes the memorisation tax. Replaces the generic "keyboard shortcut reference" item in Phase 7 Inspector section.
- ⬜ **Active mission marker on map/floor**: subtle indicator above the NPC or station relevant to the current mission's active hint — reduces "where do I go next?" dead time.

### Rewards and progression depth

- ⬜ **Mission log screen `[M]`**: a full-screen overview of every mission (locked / available / active / complete) with source NPC, hints so far, problems-solved count, and completion date. Lets the player see their whole journey at once without interrogating each NPC for state. (This is the detailed spec; the one-line Phase 7 "mission progress tracker" is superseded by this.)
- ⬜ **Unlockable diagnostic tools**: currently the player has one investigation approach (walk + inspect). Unlocking new tools as tiers progress — "Spaghetti Diagram tool" at Tier 3, "SPC chart tool" at Tier 4 — gives a sense of growing capability separate from credits. Tools appear in the inspector as extra actions.
- ⬜ **NPC reputation / relationship tracking**: per-source-NPC relationship score that rises with well-handled missions and affects subsequent dialogue warmth/openness. Gives weight to player decisions over time and makes NPC interactions feel more than transactional. Pairs with the Phase 7 "NPC character arcs" item.
- ⬜ **Credit uses beyond specialists**: expand the credit sink — training programs (permanent operator skill bump), equipment upgrades (permanent station perf/availability bump), or rapid Lean Coach consultation (hint on current problem). Gives credits more meaning than just passing a gate.

### Reflection and takeaways

- ⬜ **A3 report export on resolve**: after a problem is resolved, offer to export a one-page A3 in the game's UI or as a PDF — problem statement, investigation choices made, root cause (from 5 Whys), countermeasure applied, verification result, final score. Mirrors real lean practice and gives the player a concrete takeaway per problem. High leverage for the game's learning-tool framing.
- ⬜ **Replay-solved-problems sandbox**: optional mode accessed from the pause menu — pick any resolved problem and re-run the investigation with different choices to see how the score changes. Learning reinforcement without affecting the main save file.
- ⬜ **End-of-week Plant Manager review**: every 5 in-game days, a short dialogue from the Plant Manager summarises what changed (KPI deltas, missions completed, concepts learned) and sets a light narrative tone for the next week. Periodic structured reflection.

### Humanising the plant

- ⬜ **Named operators with small bios**: give each of the 24 floor operators a name and one-line bio. When an NPC mentions a problem, they can reference specific operators ("Maria at Integration 3 has been flagging this for weeks"). Tiny change, large boost to emotional investment.
- ⬜ **Plant backstory via in-world artifacts**: occasional emails, memos, or old reports that appear in the inspector to give the plant a history ("Project NovaGlide Q3 2024 retrospective — 9 chronic issues identified, 3 resolved"). Small narrative hooks that reward exploration.

### Quality of life

- ⬜ **Circuit-breaker explanation toast**: when WIP ceiling / OEE floor / FTR floor fires, a non-blocking toast explains *why* the sim slowed and what the player can do. A slowed sim with no explanation is a major UX friction point for new players. Supersedes the terser Phase 7 item.
- ⬜ **Auto-pause when idle**: if no key pressed for 5+ minutes, pause automatically and show a gentle "paused — welcome back" banner. Respects the player's time and prevents unwanted progression in the background.

### Content depth

- ⬜ **Seasonal / themed in-game events**: "Quality Week", "Safety Month" — themed arcs that surface a specific category of problems with bonus credits for solving them in the theme. Reuses the existing problem catalog with different framing, no new content authoring required.
- ⬜ **Customer feedback loop**: occasional customer returns / complaints that trigger 8D-style problems with their own framing. Connects the factory to a downstream customer reality — reinforces that quality problems have consequences outside the plant.

**Deliverable:** A game that a lean-curious stranger can sit down with cold, understand within 5 minutes, and want to spend an evening on. The feature bar is no longer "does it work?" but "does the player keep playing, and do they leave having learned something they can articulate?"

---

### Phase 8 — AI Integration ⬜ ~5% COMPLETE

AI is introduced last so the generator has maximum reference material: all four tiers of hand-designed problems and dialogue fork YAML exist before it runs.

#### Done
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

### Phase 9 — World Expansion (future, parked 2026-04-24)

> **User goal:** a bigger map and a more realistic factory layout. The current 100×60 tile map reads as a diagram — zones are colour blocks with a handful of stations each. A more believable plant would have: intermediate buffer areas between zones, a proper office wing with more rooms, a real loading bay with multiple trucks, a cafeteria, a training room, maybe a quality lab wing, and corridors that feel walked rather than rectangular. Scope this after Phases 7/7b ship because it touches the tilemap, camera, NPC routing, and every renderer — a big change that should land on a stable content/UI base.

- ⬜ **Enlarge map** (target ~200×120 tiles): keep current zones but add intermediate buffer/flow areas, a larger outdoor yard with 2–3 truck bays, an extended office wing, a quality lab, a training room, a cafeteria. Revisit `MAP_W`/`MAP_H` in `navigation/tilemap.py` and `config/world_data.py`.
- ⬜ **Realistic factory detail**: populate each zone with operator walk paths, material carts between stations, wall-mounted visual boards, break-room furniture, safety signage, fire-extinguisher points. Use Kenney Industrial + Urban tiles already in `assets/kenney/`.
- ⬜ **Routing/pathfinding upgrade**: operators (24 total) could roam between stations on realistic paths rather than staying pinned — requires A* and station-to-station routes.
- ⬜ **Zone-specific floor textures**: instead of the current flat colour blocks, tile each zone with appropriate Kenney floor tiles (concrete for prep, epoxy for assembly, metal grid for testing).

**Deliverable:** a plant that looks lived-in from the first screen.

---

### Phase 10 — 3D Web Edition (factory prototype) ⏸ BACKED UP

Built 2026-10-12 as `web/` (git commit `b3a4c8c`), now archived in `archive/factory-3d/`. Kept as a reference; the game is rebuilt in Godot 4.

- ✅ Content loader for the shared YAML with validation (`archive/factory-3d/src/content/`)
- ✅ Unit-level flow simulation: push vs CONWIP release, breakdowns, scrap, WIP piles, line capacity and constraint (`archive/factory-3d/src/sim/flow.ts`)
- ✅ Investigation-by-doing: gemba tools reveal clues (`tool:` tags in problem YAML), deeper 5-Whys clues unlock progressively, operator questions (open, closed, blaming) with a trust mechanic
- ✅ A3: name the waste (TIMWOODS, `waste:` tag on every problem), link evidence, choose the root cause, countermeasure and prediction; Check compares before/after, including whole-line capacity
- ✅ PDCA score with five dimensions, including flow impact (fixing a non-bottleneck scores low)
- ✅ 3D world: procedural characters, 10 station models, conveyors, WIP stacks, andon lights, office wing, yard, A* click-to-move
- ⬜ UI panels (A3, value stream map, NPC dialogue, HUD) — unfinished at backup time
- Data fixes that also help the Python build: "Visual Labels & Signs" → "Visual Labels and Signs"; removed nonexistent "Operator Rebalancing"; codex moved to `data/concepts.yaml`

---

### Decisions Made
- **3D web edition (2026-10-12)**: Three.js + TypeScript prototype, superseded the same day by the decision to build in Godot 4 (see the Spanning plan above); archived in `archive/factory-3d/`
- **Problem solving is action-based, not multiple choice (2026-10-12)**: clues are earned through gemba tools and good questions; the player writes the A3; the simulation judges the countermeasure
- **Bottleneck first (2026-10-12)**: Check always shows end-to-end capacity; improving a non-constraint is called out as no real gain
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
