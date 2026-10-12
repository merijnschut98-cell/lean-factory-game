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
  tests/                   headless test runner + test_*.gd
  tools/screenshot.gd      renders a scene to PNG under Xvfb for visual checks
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
| `WorkOrder` | id, type, stream, birth time, due date, current step, rework count, history |
| `StepDef` / `Step` | touch hours, FTR, rework target, pool or external wait, queue, in-progress |
| `PeoplePool` | headcount, hours per day, availability, skills, priority rules (outages pre-empt planned work) |
| `StockItem` | level, reorder point, order quantity, supplier lead time |
| `ValueStream` | ordered steps, arrivals model, KPIs (throughput, backlog, lead time p50/p85, on time, FTR) |
| `Network` | advances time in fixed steps (one simulated minute), assigns people, moves orders, records events |
| `Capacity` | end-to-end capacity per stream and the constraint (generalised `lineCapacity`) |
| `Rng` | seeded PRNG; the only source of randomness |

Time runs in fixed simulated steps, independent of the frame rate: `Game` advances `n` steps per frame based on the speed setting (pause, 1×, 4×, 16×) and pauses at the dagstart.

## Rules (`rules/`)

Ports of the prototype's tested logic, adapted to a service organisation:

| Prototype (TypeScript) | Godot (GDScript) |
| --- | --- |
| `investigation.ts`: tools, clues with depth, questions and trust, cause bank, prediction | `rules/investigation.gd`, `rules/conversation.gd` |
| `pdca.ts`: effectiveness by maturity, score with five dimensions incl. flow impact | `rules/pdca.gd` |
| `game.ts`: missions, problem phases, A3, Check/Act, recurrence | `rules/site_game.gd`, `rules/missions.gd`, plus `rules/story.gd` for the narrative arc |
| `progression.ts`: belts, regions | `rules/progression.gd` |

Problem effects become generic modifiers on a target (`step`, `pool`, `stock`, `stream`): touch time, FTR, availability, external delay, demand, headcount.

## Content pipeline

- **Authoring:** content is written in **YAML** under `content/`. YAML is readable for review, handles long Dutch texts well, and keeps comments. Game text is Dutch; keys and field names are English.
- **Build:** `tools/build_content.py` validates everything and writes compact JSON to `game/data/`. Godot parses JSON natively, so the game needs no YAML parser. Validation covers:
  - required fields;
  - every problem has at least one key clue at depth 0;
  - countermeasure references resolve;
  - every tool and waste is a known value;
  - missions point at real problems.
- **Load:** `src/content/` loads the JSON and checks references again, so a corrupt or outdated data file fails loudly in tests, never silently in play.
- **Drift guard:** a test fails if `game/data/` is out of date with `content/`.

UI strings that are not content (button labels, HUD) go through Godot's translation system with Dutch as the default locale, so an English version stays possible.

## Saves

- JSON in `user://saves/`, with a schema version.
- Autosave at every dagstart (sessions are 15–40 minutes and can end at any morning).
- Loading validates every field and ignores ids that no longer exist in the content, the same approach as the prototype's `save.ts`.
- The world state is rebuilt from the simulation, never saved separately.

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

- **On every push:**
  - build content and check the generated data is current;
  - run the Godot logic tests headless;
  - run the legacy Python tests.
- **On demand and on milestone tags:** export Windows, Linux and web builds and attach them as downloadable artifacts, so you never compile anything yourself.

## Rendering notes (measured, 2026-10-12)

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
