# Office vertical slice — implementation plan

Spec: `docs/superpowers/specs/2026-10-13-office-vertical-slice-design.md`. Execution: subagent per task, then a task review. Tasks 1 and 2 run in parallel (separate files); task 3 needs both.

## Task 1: Art pipeline and the office model
- **Create:**
  - `tools/blender/textures.py`: numpy and PIL texture generators for wood, carpet tiles, plaster, concrete, painted metal, glass and whiteboard, each with a normal map, written to `game/assets/office/textures/` at 1024² or smaller.
  - `tools/blender/build_office.py`: builds the scene with `bpy` and exports `game/assets/office/office.glb`.
  - `tools/blender/README.md`: how to set up `bpy` (a venv with `pip install bpy`) and run the build.
- **The model** (spec, "The office"):
  - **Shell:** floor, walls, windows with frames and glass, a suspended ceiling with light panels.
  - **Areas:** the intake corner (2 desks), Werkvoorbereiding (4 desks with dual monitors, dossier stacks, a plotter), the obeya wall (a whiteboard with a KPI grid and sticky notes), the glass-walled coach's room, the mission board by the entrance, and a coffee corner.
  - **Props:** chairs, monitors, keyboards, paper trays, dossier stacks, plants, Voltana-blue signage.
  - **Scale:** real-world, in metres. The floor is about 24 × 16 m and the ceiling 2.8 m.
  - **Size:** a sensible polygon budget, under 150k triangles in total.
- **Lighting:** bake ambient occlusion (and indirect light if Cycles CPU allows, within ~10 min) into a lightmap on the shell, using a second UV set or a baked texture multiplied into the base colour.
- **Empties** (glTF nodes): `place:connections.intake`, `place:connections.design`, `obeya`, `coach`, `mission_board`, `spawn`. Each sits where the player stands to interact, facing the object.
- **Verify:**
  - the glb imports in Godot headless (`godot --headless --path game --import`);
  - a preview scene renders through `game/tools/screenshot.gd` with xvfb, producing PNGs from 2–3 angles under `docs/screenshots/`;
  - look at the PNGs and iterate until it reads as a believable semi-realistic office.

## Task 2: GameSession (pure logic)
- **Create** `game/src/game/session.gd` (`GameSession`, RefCounted) and `game/tests/test_session.gd`.
  - `GameSession.new_game(seed)` loads the `Catalog`, builds the `Network`, `Region` (`use_kpis`) and `Missions`, warms the network up (e.g. 60 days) so queues exist, and marks `walk_connections` done.
  - Player actions:
    - `use_tool(place, tool)`, `ask(place, q)`;
    - `accept(id)`;
    - `cause_options(problem_id)`, `countermeasures(problem_id)`, `submit_a3(problem_id, a3)`;
    - `wait_for_check(problem_id)`, which advances to `check_at`;
    - `check(problem_id)`, `act(problem_id, standardise)`;
    - `ask_coach()`, `drain_events()`.
  - Each advances the clock where the rules say so and calls `Missions.update()`.
  - Read-only views for the UI: `clock_text()` in Dutch (e.g. "di 14 okt, 09:30"), the budget, XP, belt, active missions, and the found clues per problem.
- **Test:** the full mission path on the real content.
  - Accept `fix_custom_design`, then find its key clues with the right tools at the right places (read `content/problems_tier1.yaml`), then submit an A3 with the correct cause and a fitting countermeasure, wait, Check passed, Act with standardise.
  - The mission is completed and XP has increased.
  - Also test that the errors pass through (an unknown place, the wrong mission).

## Task 3: The office scene, player and UI
- **Create:**
  - `game/src/world/office/office.tscn` and `office.gd`: instance the glb, add a sun (DirectionalLight3D through the windows, with shadows) and a WorldEnvironment, and build interaction Area3Ds from the empties.
  - `player.gd`: CharacterBody3D first person, WASD and the mouse, E to interact, Esc frees the mouse.
  - `game/src/ui/*.gd`: HUD, prompt, tool and question menu, clue journal, A3 form, coach panel, Check/Act result panels, mission board. All in Dutch, and Control trees built in code.
- **Change:** `project.godot` main scene → the office. Keep boot as the title or remove it if unused.
- **Test:** `game/tests/test_office_scene.gd` instantiates the scene headless; every interaction maps to a valid place, the mission board opens, and the session is wired.
- **Verify:** screenshots of the office, the tool menu, the A3 form and the Check panel (xvfb). Then the full gate and CI.

## Gate (every task)
- `godot --headless --path game --script res://tests/run_tests.gd`
- `python tools/build_content.py --check`
- `python -m pytest tests/ -q`
