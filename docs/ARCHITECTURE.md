# Spanning — Architecture

How the Godot project is built, and why. Read with `docs/GDD.md` (what we build) and `PLAN.md` (in what order).

## Platform

| Choice | Decision | Why |
| --- | --- | --- |
| Engine | **Godot 4.7.2 stable** (pinned; upgrade deliberately) | open source, strong 3D, desktop + web export, runs headless in CI and in Claude's environment |
| Language | **GDScript** with static typing everywhere (`var x: int`, typed arrays, `-> void`) | web export works (C# does not in Godot 4); fast iteration; types catch errors early |
| Renderer | **Compatibility (OpenGL 3 / WebGL 2)** for the whole project | one look on desktop and web; the stylised low-poly art does not need Forward+; it is the renderer Claude can screenshot headlessly (Xvfb + Mesa), so what is verified is what you play |
| Targets | Windows and Linux desktop first, web build as a bonus, macOS later (needs signing) | desktop first was decided in the GDD review |

## Repository layout

```
game/                      Godot project (res://)
  project.godot
  src/
    sim/                   pure logic: work orders, value streams, pools, stock, time
    rules/                 pure logic: problems, clues, conversations, A3, PDCA score, progression, story
    content/               loads generated JSON into typed objects, validates references
    save/                  save files: versioned, validated, written to user://
    game/                  autoloads: Game (owns sim + rules, time control), Events (signal bus)
    world/                 3D scenes and scripts: campus, town, characters, vans, WIP visuals
    ui/                    Control scenes: HUD, dagstart, gemba toolkit, A3, Check & Act, VSM, notebook, codex
  data/                    generated JSON (never edited by hand)
  assets/                  models, textures, fonts, audio (with licence files)
  tests/                   headless test runner + test_*.gd (helpers such as TestCase in tests/lib/)
  tools/screenshot.gd      renders a scene to PNG under Xvfb for visual checks
  tools/make_default_env.gd  regenerates src/world/default_environment.tres
  tools/problem_report.gd  measures every catalogue problem and countermeasure on the real network (JSON, for content reviews)
  export_presets.cfg       Windows, Linux and web export presets
content/                   authored content, YAML, Dutch game text (problems, countermeasures, missions, story, codex)
tools/
  build_content.py         YAML → validated JSON in game/data/
docs/                      GDD, architecture, research notes
archive/factory-3d/        the Three.js factory prototype (reference only)
(root)                     the legacy Python factory game, unchanged
```

## The one rule that matters most

**`sim/` and `rules/` never touch nodes, scenes, the scene tree or the renderer.**
- They are plain `RefCounted` classes with a seeded random generator, so every behaviour is deterministic and testable headless in milliseconds.
- The world and UI only *read* that state and call a small set of player actions (use a tool, ask a question, submit an A3, check, act). They react to changes through signals on the `Events` bus.
- This is what made the factory prototype's logic testable (57 tests), and it is what lets one simulation drive 3D, UI and tests alike.

```
content (YAML) ──build──▶ game/data/*.json ──load──▶ content/   (typed catalogue)
                                                        │
          player actions ──▶ Game autoload ──▶ sim/ + rules/   (pure, deterministic)
                                   │                  │
                       Events (signals) ◀─────────────┘
                          │          │
                       world/       ui/   (read state, draw it, never own it)
```

## Simulation core (`sim/`)

Generalises the factory prototype's `FlowSim` (`archive/factory-3d/src/sim/flow.ts`) from one linear line to a network of value streams:

| Class | Responsibility |
| --- | --- |
| `SimCalendar` | minutes since Monday 00:00 of week 1, the 10-minute tick, `"HH:MM"` and day-range (`mon-fri`) parsing |
| `WeekSchedule` | which 10-minute slots of the week are on: pool working hours (incl. 24/7 and on-call through midnight) and stream arrival hours; hours per week, next start, overlap |
| `WorkOrder` | id, stream, birth and due time, current step, remaining touch time, rework count (where it is follows from the queue or list holding it) |
| `SimStep` | definition of one step (work / wait / material, `applies`, FTR, what a failed attempt costs (`fail_minutes`: the trip, not the job; drawn when work starts), rework target, the pool or pools that do the work) and its statistics |
| `SimPool` | headcount, daily attendance, weekly schedule, the orders being worked on now, actual load per day (busy over present people-minutes; `Capacity` is the planned load) |
| `DailyCounts` | integer counters per simulated day for time windows (step statistics, pool load); bounded by `HISTORY_DAYS`, saved |
| `SimStock` | level, reorder point, order quantity, lead time, open deliveries, orders waiting for stock |
| `ValueStream` | ordered steps, arrival sources (`per_week` within a `WeekSchedule`, optionally with an `id` so a `demand` effect can target one: `outages.daytime`), norm, priority and `preempts`, backlog and finished-order records, KPIs (throughput, backlog, lead time p50/p85, on time, first-time-right) |
| `Network` | loads `value_streams.json`, advances time, schedules arrivals, moves orders, assigns people (priority, then longest-waiting; only `preempts` streams interrupt work), hands unfinished work over at the end of a shift, keeps the queues, emits events |
| `SimModifiers` | problem, countermeasure and event effects by source on top of the content's base values (see below) |
| `Capacity` | expected visits per step (including `applies` and rework loops), people-hours per week needed vs available per pool (a step served by several pools is split by how much of the stream's arrival time each pool covers), constraint and capacity per stream |
| `Rng` | seeded PRNG; the only source of randomness. The network keeps one per purpose (each arrival source, each team's attendance, each step's outcomes, each stream's status calls), seeded from the run seed and the purpose: common random numbers, so two runs differ only where a change reaches |

**No reference cycles.** Godot frees `RefCounted` objects by reference counting, so a loop (step → pool → busy order → stream → step) leaks every network that is replaced. Steps therefore refer to pools and stock by id, and queues live in the `Network`. The test runner shows leaks at exit, so a new cycle is noticed straight away.

**Failure demand.** A stream with `status_calls` makes customers of orders older than `after_days` call another stream (the contact centre) `per_week` times, at that stream's opening hours. These calls are orders like any other, marked `failure_demand` in the arrival event. The static `Capacity` analysis does not see them; the simulation does, which is itself a lesson.

**Shared people.** The monteurs serve connections, meters and outages. Queue order is stream priority, then longest waiting. Only a stream with `preempts` (outages) interrupts work in progress; the interrupted order goes back to the front of its queue. The same happens at the end of a shift (a *handover* event), so the next shift or another pool serving the step picks it up, e.g. the on-call crew hands a fault over to the monteurs at 07:00.

The network skips idle stretches by jumping to the next moment anything can happen: an arrival, the end of a wait, a delivery, a new day, or a shift starting for a pool with queued work. A test proves the results are identical to stepping every tick. A simulated year of the four streams takes about 1.4 s.

Time runs in fixed simulated steps, independent of the frame rate: `Game` advances `n` steps per frame based on the speed setting (pause, 1×, 4×, 16×) and pauses at the dagstart.

## Rules (`rules/`)

Ports of the prototype's tested logic, adapted to a service organisation (plan: `docs/superpowers/plans/2026-10-12-phase-a-step-5-rules.md`):

| Prototype (TypeScript) | Godot (GDScript) |
| --- | --- |
| content types | `ProblemDef`, `CountermeasureDef`, `Clue`: the shape of the Phase B content |
| `investigation.ts`: tools, clues with depth, questions, cause bank | `Investigation` (ids only; the UI words them) |
| `pdca.ts`: effectiveness by maturity, five-dimension score | `Pdca` (effectiveness = maturity multiplier × the countermeasure's fit for the problem) |
| `game.ts`: problem phases, A3, Check/Act, recurrence | `Region` + `ProblemState` + `Profile` |
| `progression.ts`: belts | `Progression` |
| missions | `MissionDef` + `Missions` (the campaign; see below) |
| story | later (`rules/story.gd`) |

How the rules differ from the factory:
- **Places are value-stream steps** (`connections.design`). Walking another step of the same stream counts as scouting. A clue can sit upstream of where the problem shows.
- **Trust is per team** (pool).
- **Several countermeasures can help one problem**, each with a fit. Each shapes the process differently through its own effects and levers, so there is no single healthy process.
- **An experiment costs** improvement budget (€) and team hours. The hours become an availability effect (`do:<id>`) on that team while it runs: improvement work competes with daily work.
- **Check compares** the stream's end-to-end KPIs and capacity before and after, plus the problem's own step (per-step daily statistics). A fix away from the constraint is flagged and scores low on flow impact.
- **Results are codes and numbers** (reply `guarded`, lesson `mismatch`, note `impact_not_constraint`). The UI words them in Dutch.
- **Problems can cost money** every week they are open (`cost_per_week`: damage repairs, claims), weakened by a working countermeasure; Region charges it to the budget day by day.

**The campaign** (`rules/missions.gd`, content `missions.yaml`; design rules in CLAUDE.md §2):
- Missions unlock by completed missions and the player's belt.
- At most one main mission and three side missions are active (`Region.MAX_OPEN` is 4 to match).
- A goal is `walk` (see every work step of a stream), `investigate` (find N key clues) or `solve` (resolve a problem). Accepting a mission activates its problem.
- A deadline fails a mission for good (Henk retires).
- The coach (a senior manager) only talks about the main mission. Its stage (`go_see`, `understand`, `experiment`, `reflect`) follows from the problem's PDCA phase; it asks the stage's Kata questions in turn, and every third time shares the mission's insight for that stage.
- `Missions` holds the Region; the Region does not know about missions (no reference cycle). Saved with `to_dict`/`load_dict`; missions the content no longer has are dropped and reported.

Problem effects are generic modifiers (`sim/modifiers.gd`):
- An effect is `{target, property, value}`, e.g. `{target: "connections.design", property: "touch_time", value: 1.3}`. The property decides the kind of target and how effects combine: factors for times and demand; additions for FTR, `applies`, availability, headcount and reorder point. Results are clamped to sensible bounds.
- Effects are grouped by source (`problem:…`, `cm:…`, `event:…`), so a problem's effect can be switched off when it is solved, a countermeasure's can be added, and both can be saved and compared. `SimModifiers.scaled` gives partial strength (countermeasure effectiveness).
- Levers change how work flows rather than how fast (SET: the most recent source wins): `reserve` (`{stream, people}`: people held for one stream), `preempts` (frozen planning window), `batch_days` and `starts_with` (a wait in batches, or in parallel from an earlier step), `wip_limit` (CONWIP: new orders wait, not yet started). Waiting has a cost: a work step's `stale_after_days` sends a dossier that waited too long back to an earlier step. Content can also set them; `interrupt_to` (where interrupted work goes back to) is content only.
- Content values stay the base. Every change recomputes the touched fields from base and writes the effective value into the plain sim field, so the tick loop and `Capacity` stay free of lookups. Effects apply to work from then on; attendance follows a headcount change the next day.

## Content pipeline

- **Authoring:** content is written in **YAML** under `content/`. YAML is readable for review, handles long Dutch texts well, and keeps comments. Game text is Dutch; keys and field names are English.
- **Files so far:** `game.yaml`, `value_streams.yaml` (a healthy base), `countermeasures.yaml` and `problems_tier1.yaml` (the problems switched on as effects on top of the base). `rules/catalog.gd` loads the last two.
- **Build:** `tools/build_content.py` validates everything in two passes (each file against its own validator, then `CROSS_CHECKS` over all files for references between them) and writes JSON to `game/data/`. Godot parses JSON natively, so the game needs no YAML parser. Validation covers:
  - required fields;
  - every problem has at least one key clue at depth 0;
  - YAML that would silently lose text is refused at load: duplicate keys, and an unquoted comma inside `{…}` (it splits the text into a key without a value); problems, countermeasures, clues and effects reject unknown keys;
  - every listed countermeasure can pass the Check at full strength (`Pdca.CHECK_PASS`, mirrored in `vocabulary.json`);
  - countermeasure references resolve;
  - every tool and waste is a known value;
  - missions point at real problems.
- **Load:** `src/content/` loads the JSON and checks references again, so a corrupt or outdated data file fails loudly in tests, never silently in play.
- **Drift guard:** a test fails if `game/data/` is out of date with `content/`.

UI strings that are not content (button labels, HUD) go through Godot's translation system with Dutch as the default locale, so an English version stays possible.

## Saves

- **Files:** `user://saves/<slot>.save` with a schema version (`save/save_file.gd`).
  - Godot's binary Variant encoding (`var_to_bytes`) is exact for ints, 64-bit values and floats. Godot's JSON rounds floats to about 15 digits (0.1 + 0.2 becomes 0.3), which breaks exact continuation.
  - Loading never creates objects.
  - Slot names are restricted to `[a-z0-9_]`, so a path never leaves the folder.
  - Writes go to a temporary file that is then renamed, so a crash never leaves half a save.
- **Serializers next to their layers:** `sim/network_state.gd` (`NetworkState`) and `rules/region_state.gd` (`RegionState`, which includes its network) capture and restore everything needed to continue exactly. `WorkOrder` and `ProblemState` own their `to_dict`/`from_dict`. Together they cover:
  - the clock and every random sequence's state;
  - effects;
  - every order wherever it is (queues, busy, waits, stock, held);
  - stock, finished records and daily statistics (the simulation keeps `Network.HISTORY_DAYS` = 120 days, so memory and saves stay bounded);
  - every problem's place in the PDCA loop;
  - trust, clues found and the profile.
  A test proves a restored game continues identically.
- **Loading** restores into a Network and Region freshly built from the current content.
  - Everything is matched by id (`stream.step`), never by index. What the content no longer has is dropped and reported (`dropped`), never guessed at.
  - Structural damage returns an `error` and the caller discards the half-built game.
- **Not saved:** transient events. The world state is rebuilt from the simulation, never saved separately.
- **Later:** autosave at every dagstart (sessions are 15–40 minutes and can end at any morning).

## Testing

- **Logic tests:** a small custom runner (`game/tests/run_tests.gd`, a `SceneTree` script) runs every `test_*.gd` headless: `godot --headless --path game --script res://tests/run_tests.gd` (append `-- rng` to run only matching files). It exits non-zero on failure. No third-party test addon, so nothing to keep compatible.
  - Tests extend `TestCase` (`assert_eq`, `assert_near`, `assert_between`, …).
  - GDScript cannot catch runtime errors, so the runner registers a `Logger` (Godot 4.5+). A test that crashes halfway, for example on a null access, fails instead of silently passing.
  - A file with a syntax error fails the run.
- **What gets tested:** every rule with business meaning:
  - flow and pre-emption;
  - rework and stock-outs;
  - capacity and constraint;
  - clue depth and trust;
  - A3 validation and Check/Act;
  - scoring, saves;
  - content validity.
  This mirrors the prototype's 57 tests.
- **Visual checks:** `game/tools/screenshot.gd` renders a named scene to PNG under Xvfb, so world and UI changes are reviewed as pictures before they are committed: `xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 --script res://tools/screenshot.gd -- res://src/boot/boot.tscn out.png`.
- **Legacy:** the Python factory game keeps its own `pytest` suite.

## CI and builds (GitHub Actions)

- **On every push to master and every PR** (one shared, cached Godot setup in `.github/actions/setup-godot`):
  - build content and check the generated data is current;
  - run the Godot logic tests headless;
  - run the legacy Python tests.
- **On demand and on milestone tags:** export Windows, Linux and web builds and attach them as downloadable artifacts, so you never compile anything yourself.

## Rendering notes (measured, 2026-10-12)

These settings live in one place: the project's default environment (`src/world/default_environment.tres`, set in `project.godot`, regenerated by `tools/make_default_env.gd`). Scenes add only their own sun. Brand colours live in `src/ui/palette.gd`.

- **Linear tone mapping.** Filmic noticeably lifts colours in the Compatibility renderer (authored `#6f9a4c` grass rendered as `#8ab767`); Linear keeps authored colours true, which stylised art depends on.
- **A neutral ambient colour, not the sky.** Sky-sourced ambient light tinted grey asphalt blue and overexposed everything.
- **The colour pipeline itself is exact:** an unlit `#6f9a4c` surface renders as `#6f9a4c` in screenshots.
- **Still to check in Phase C:** directional shadows were not visible in the first boot-scene angle.

## Assets

- Procedural low-poly geometry where it is quick (buildings, furniture, cable trays).
- CC0 asset packs (Kenney, Quaternius) for characters, vehicles and props, with each licence kept beside the asset.
- The character approach is decided in Phase C: rigged CC0 glTF characters, or a port of the prototype's procedural rig (`archive/factory-3d/src/world/character.ts`).

## Conventions

- **Naming:** `snake_case` files, `PascalCase` class names (`class_name`), signals in past tense (`order_completed`).
- **Scripts:** one responsibility per script. A function with "and" in its name gets split.
- **Constants:** numbers that tune the game live in content or in a single constants script, never inline.
- **Process:** each increment is small, tested, committed with `PLAN.md` updated, and pushed.
