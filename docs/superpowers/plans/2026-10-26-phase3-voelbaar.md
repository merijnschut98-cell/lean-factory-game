# Phase 3 — *Voelbaar* Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make improvement at Voltana felt by a human player: tools so Merijn can play cheaply, people who change with the load, promotions, one real street, and the Act III spine ending in the reversal (Ruud to Den Haag, Frank's interim MT).

**Architecture:** Slice 3.0 is detailed to the step and ships first (designer tools behind a flag, two behaviour-neutral file splits, decision day). Slices 3.1–3.3 are given at task level with their files, interfaces, tests and exits; Opus details each one when its predecessor's playtest is done, because every slice's content depends on what Merijn says after playing the one before. Everything lands one commit at a time through the gate (`scratchpad/gate`, `g.sh`, `land.sh`): import, `tools/run_godot_tests.py`, `build_content.py --check`, pytest.

**Tech Stack:** Godot 4.7 / GDScript (`game/`), Python 3 content pipeline (`tools/build_content.py`, YAML → `game/data/*.json`), Blender `bpy` scripts (`tools/blender/`), pytest (`tests/`), the Spanning Godot test runner (`game/tests/run_tests.gd`, one file per process).

**Spec:** `docs/superpowers/specs/2026-10-26-phase3-design.md` (read §0–§1 first; the slice sections map 1:1 onto the slices below).

## Global Constraints

- Dutch game text, English code and docs; every UI string through `tr()`; every spoken or on-screen line follows `docs/superpowers/specs/2026-10-19-dutch-style-guide.md` and passes `BANNED_SPOKEN` in `tools/build_content.py`.
- Nothing is handed over: no tell, briefing, codex text or mission name names a problem's cause; the spoiler checks in `build_content.py` (`check_clue_spoilers`, the company check) stay on and are extended to new text.
- Problems arrive only through missions; one main, at most three sides (a routine takes no slot); the coach helps only the main quest.
- Evidence first: every number in content has a `source:` on an approved domain or `estimate:` with its reasoning.
- Network rule (CLAUDE.md §3, verbatim in every agent brief): only the approved domains; agents stop and report instead of fetching anything else.
- Designer features are never in the player's build: gated by `Designer.enabled()` (Task 1) and nothing else; `game/tools/*` and `game/tests/*` stay excluded by `game/export_presets.cfg`.
- Save compatibility: old saves load (`JsonFile.int_or`, `dict_or_empty`, clamps); the splits in Tasks 7–8 change no save key.
- Behaviour-neutral refactors keep every touched test file's pass count identical before and after.
- TDD: a failing test first for every behaviour change; `simplify` on each diff before its final commit; one Godot process at a time (`godot --headless --path game --script res://tests/run_tests.gd -- /test_x.gd`).
- Commits by explicit paths; agents never push; the footer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_018C759XCCMetfCHDHUbymvT`; no model id anywhere else.

## Review Focus

1. **The designer flag in a player build.** A player who launches `Spanning.exe` plainly must never see the Ontwerper page or load a designer save. Pinned by Task 1's `test_designer_disabled_without_flag_or_editor` and Task 2's `test_designer_page_hidden_when_disabled`.
2. **A designer save written on older content.** After `build_content.py` changes missions, a save made yesterday may hold mission ids that no longer exist. The page must say so and offer regeneration, not crash. Pinned by Task 2's `test_designer_entry_marks_stale_content`.
3. **A jump save taken mid-state.** The bot stops at a day boundary with no talk open; a save with a dialog in progress would resume into a half-screen. Pinned by Task 1's `test_saves_are_written_outside_any_talk`.
4. **Markers file growth.** Merijn pressing F8 every minute for an evening must not fill the disk or slow the game. Pinned by Task 4's `test_markers_file_rolls_over_at_max_bytes`.
5. **Save round-trip after the splits.** Moving sustain and the sync passes must not change what `Region.to_dict` / `Missions.to_dict` write or read. Pinned by Tasks 7–8 running `test_game_save.gd` and `test_save.gd` with unchanged counts and by `test_split_keeps_save_keys` in each.

---

# Slice 3.0 — *Spelen* (spec §2)

### Task 1: Designer flag and jump-to-day saves

**Files:**
- Create: `game/src/game/designer.gd` (`class_name Designer`)
- Create: `game/src/save/designer_saves.gd` (`class_name DesignerSaves`)
- Create: `game/tools/make_saves.gd` (SceneTree script)
- Create: `tools/make_designer_saves.py` (runs the Godot script per save)
- Modify: `game/tools/autoplay.gd:241-300` (Persona: `stop_act`, a stop only at a day boundary with no talk open)
- Test: `game/tests/test_designer_saves.gd`

**Interfaces:**
- Produces: `Designer.enabled() -> bool` (true when `OS.has_feature("editor")` or `OS.get_cmdline_user_args()` holds `--designer`); `Designer.force(value: Variant) -> void` (a test hook: `true`/`false` overrides, `null` clears; only `enabled()` reads it).
- Produces: `DesignerSaves.DIR := SaveFile.DIR + "/designer"`; `DesignerSaves.SAVES: Array[Dictionary]` = `[{slot: "designer_training_done", stop_day: 5.0}, {slot: "designer_day045", stop_day: 45.0}, {slot: "designer_day070", stop_day: 70.0}, {slot: "designer_day095", stop_day: 95.0}, {slot: "designer_act2", stop_act: 2}]` (3.3 adds `{slot: "designer_act3", stop_act: 3}`); `DesignerSaves.write(spec: Dictionary, persona: String, seed_value: int) -> String` (runs the persona to the stop, writes the slot with `GameSave.write(slot, s, SessionLayer.new(), DIR)`, meta gains `designer: {persona, seed, stop_day, content_hash}`; returns "" or an error); `DesignerSaves.content_hash() -> String` (SHA-256 of `game/data/missions.json` + `problems_tier1.json`); `DesignerSaves.load_into_autosave(slot: String) -> String` (copies the designer file's bytes into `GameSave.AUTOSAVE` with `SaveFile.store`; returns "" or an error).
- Produces on `Persona`: `var stop_act := -1` (ends the run with `"stop_act"` when `s.missions.current_act() >= stop_act`); both `stop_day` and `stop_act` end only when `s.talks.talk == null and s.talks.expert == null`.
- Consumes: `GameSave.write`, `GameSave.meta`, `SaveFile.store`, `SaveFile.load_slot`, `Persona.stop_day` (exists), `Missions.current_act()`.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_designer_saves.gd`:
  - `test_designer_disabled_without_flag_or_editor`: with no `--designer` arg and the editor feature absent, `Designer.enabled()` is false (run the test under `--headless`, which has no editor feature; assert against `OS.has_feature("editor")` so it also holds in the editor).
  - `test_write_stops_at_day_and_saves_meta`: `DesignerSaves.write({slot: "designer_day045", stop_day: 45.0}, "expert", 11)` returns ""; `SaveFile.load_slot("designer_day045", DesignerSaves.DIR)["meta"]["designer"]["stop_day"] == 45.0` and the region's play day is in `[45, 46)`.
  - `test_saves_are_written_outside_any_talk`: the saved session's `talks.talk` and `talks.expert` are null (read back through `GameSave.read` with `DesignerSaves.DIR`).
  - `test_stop_act_ends_when_act_opens`: a Persona with `stop_act = 2` ends with `record["end"] == "stop_act"` and `s.missions.current_act() == 2`.
  - `test_load_into_autosave_copies_bytes`: after `load_into_autosave("designer_day045")`, `SaveFile.load_slot(GameSave.AUTOSAVE)` decodes to the same `region.time` as the designer file.
  Use a temp saves dir (`OS.get_user_data_dir() + "/test_designer_%d"`) and remove it in teardown.
- [ ] **Step 2: Run to verify they fail**: `godot --headless --path game --script res://tests/run_tests.gd -- /test_designer_saves.gd` → FAIL (classes not found).
- [ ] **Step 3: Implement `Designer.enabled()`** in `game/src/game/designer.gd` (static, two conditions, nothing else).
- [ ] **Step 4: Add `stop_act` to `Persona`** in `game/tools/autoplay.gd` beside `stop_day` (line ~243) and the two end checks in `_step()` (line ~295), each guarded by the no-talk condition.
- [ ] **Step 5: Implement `DesignerSaves`** in `game/src/save/designer_saves.gd`: `write` builds a `Persona` (`persona` and `style` as `autoplay.gd` does for `"expert"`), sets `stop_day`/`stop_act` from the spec, calls `play()`, then `GameSave.write` into `DIR` with the extra meta; `content_hash` reads the two JSON files; `load_into_autosave` reads bytes with `FileAccess.get_file_as_bytes(SaveFile.path_of(slot, DIR))` and stores them.
- [ ] **Step 6: Implement `game/tools/make_saves.gd`**: `godot --headless --path game --script res://tools/make_saves.gd -- [slot|all] [persona] [seed]`; default `all expert 11`; prints each slot and its play day; exits non-zero on any error.
- [ ] **Step 7: Implement `tools/make_designer_saves.py`**: runs the Godot script once per save in `DesignerSaves.SAVES` (one process at a time), fails loudly if Godot is missing; documented in its docstring; never run by CI.
- [ ] **Step 8: Run the test file** → PASS (5 tests). Run `godot --headless --path game --script res://tools/make_saves.gd -- all expert 11` → five slots in `user://saves/designer/`.
- [ ] **Step 9: Commit** `game/src/game/designer.gd game/src/save/designer_saves.gd game/tools/make_saves.gd game/tools/autoplay.gd tools/make_designer_saves.py game/tests/test_designer_saves.gd` with `3.0: designer flag and jump-to-day saves from the autoplay bot`.

### Task 2: The Ontwerper page on the title menu

**Files:**
- Modify: `game/src/ui/title_menu.gd` (`enum Page` gains `DESIGNER`; a button; the page)
- Create: `game/src/ui/designer_page.gd` (`class_name DesignerPage`, a `VBoxContainer`)
- Modify: `game/tools/play_shot.gd` (state `designer_page`)
- Modify: `docs/qa/playtest-checklist-act1-2.md` ("How to get there fast" → the designer saves; add the per-talk question and a verdict table)
- Test: `game/tests/test_designer_page.gd`

**Interfaces:**
- Consumes: `Designer.enabled()`, `DesignerSaves.DIR`, `DesignerSaves.SAVES`, `DesignerSaves.content_hash()`, `DesignerSaves.load_into_autosave(slot)`, `SaveSlots.new(DesignerSaves.DIR).entries()`, `Office.play(slot)`.
- Produces: `DesignerPage.entries() -> Array[Dictionary]` (`{slot, label, persona, seed, play_day, stale: bool}`; `stale` when the save's `designer.content_hash != DesignerSaves.content_hash()`); `DesignerPage.pick(slot: String) -> String` (loads into the autosave and starts the office; returns "" or the error shown); a `replay_requested` signal for Task 3; `TitleMenu.DESIGNER := "Ontwerper"`, `TitleMenu.STALE := "Oude inhoud: maak de opslag opnieuw (tools/make_designer_saves.py)"`.

- [ ] **Step 1: Write the failing tests**: `test_designer_page_hidden_when_disabled` (with `Designer.enabled()` false the main page has no "Ontwerper" button; stub the flag through a `Designer.force(value)` test hook that only `enabled()` reads); `test_designer_entries_list_saves_with_day` (two files written by Task 1's `write` in a temp dir appear with their `play_day`); `test_designer_entry_marks_stale_content` (an entry whose meta hash differs is `stale == true` and the row shows `STALE`); `test_pick_loads_into_autosave_and_plays` (`pick` returns "" and `Office.resume_slot == GameSave.AUTOSAVE`, with `Office.play` stubbed as other title-menu tests do).
- [ ] **Step 2: Run** `-- /test_designer_page.gd` → FAIL.
- [ ] **Step 3: Implement `DesignerPage`**: a list of rows (label, persona/seed, "dag N", STALE in the warning colour), a "Praat opnieuw" button that emits `replay_requested`, "Terug". Reuses `SaveList`'s row style.
- [ ] **Step 4: Wire the title menu**: `Page.DESIGNER`; the "Ontwerper" button appended to `_left()` only when `Designer.enabled()`; `refresh()` shows the page like `Page.SETTINGS`.
- [ ] **Step 5: `play_shot.gd` state `designer_page`** (launch with `--designer`); take and look at the screenshot.
- [ ] **Step 6: Update the checklist**: replace "How to get there fast" with the five saves and the command; add under every talk in the checklist the question "Kon je voorspellen waarom dit antwoord werkte?" and a verdict column (houden / herschrijven / anders in beeld) feeding 3.0c.
- [ ] **Step 7: Run** `-- /test_designer_page.gd` and `-- /test_save_menus.gd` → PASS, the latter with its count unchanged.
- [ ] **Step 8: Commit** with `3.0: the Ontwerper page lists the designer saves and starts one`.

### Task 3: Replay a talk

**Files:**
- Create: `game/src/ui/talk_replay.gd` (`class_name TalkReplay`)
- Modify: `game/src/ui/designer_page.gd` (opens it on `replay_requested`)
- Test: `game/tests/test_talk_replay.gd`

**Interfaces:**
- Produces: `TalkReplay.PRESETS: Dictionary` = `{"none": [], "ruined_yesterday": ["ruined:<dialog>"], "kept_promise": ["promise_kept:<dialog>"]}` (the `<dialog>` placeholder is filled with the chosen dialog's id; fact kinds as in `game/src/rules/facts.gd` `KINDS`); `TalkReplay.session_for(dialog_id: String, preset: String, seed_value: int = 11) -> GameSession` (a `GameSession.new_game(seed_value, Catalog.DATA_DIR, false)` with the preset's facts added and the dialog's person present); `TalkReplay.start(dialog_id: String, preset: String) -> void` (opens the real `TalkView` on that session with `s.start_dialog(person)`; the summary card shows the route taken, which `TalkSummary` already does).
- Consumes: `Catalog.load_from().dialog_bank` (dialog ids and each def's person), `GameSession.start_dialog`, `TalkView`.

- [ ] **Step 1: Write the failing tests**: `test_presets_fill_the_dialog_id` (the `ruined_yesterday` preset for `joost_output_kpi` yields the fact `ruined:joost_output_kpi` on the session); `test_session_for_opens_the_dialog` (`session_for("joost_output_kpi","none").start_dialog("joost")` returns the dialog's first line, not a refusal); `test_every_content_dialog_is_listed` (the list has one row per persuasion/checkin/expert dialog in the bank).
- [ ] **Step 2: Run** `-- /test_talk_replay.gd` → FAIL.
- [ ] **Step 3: Implement `TalkReplay`**: a two-column list (dialog id with person and kind; preset option button), "Speel" opens the TalkView over a plain backdrop (no office), Esc returns to the designer page. The session is thrown away on close.
- [ ] **Step 4: Run the test file and `-- /test_talk_view.gd`** → PASS, the latter unchanged (20).
- [ ] **Step 5: Commit** with `3.0: replay any talk from the designer page with a facts preset`.

### Task 4: Playtest markers you hand back

**Files:**
- Modify: `game/src/save/session_log.gd` (markers file beside the log)
- Modify: `game/src/game/session_layer.gd` (`recent: Array[String]`, a ring of the last 20 event texts)
- Modify: `game/src/ui/game_ui.gd` (F8 → a one-line input → `SessionLog.marker`)
- Test: `game/tests/test_session_log.gd` (extend), `game/tests/test_session_layer.gd` (extend)

**Interfaces:**
- Produces: `SessionLog.MARKERS := "user://saves/playtest_markers.md"`; `SessionLog.marker(text: String, s: GameSession, layer: SessionLayer) -> String` (appends a Markdown block: `## dag N · HH:MM · <place> · <active main mission id>`, the player's line, then the last five of `layer.recent`; rolls over at `MAX_BYTES` like the log; returns "" or an error); `SessionLayer.recent: Array[String]` fed by `SessionLayer.note_event(text)` wherever `GameUI` toasts a region or mission event; `GameUI.MARKER_PROMPT := "Noteer dit moment"`.
- Consumes: `SessionLog._append`, `GameSession.clock_at`, `Office.current_place_id()` (exists in the office for tells; if not, the player's room from `OfficeBuilding`).

- [ ] **Step 1: Write the failing tests**: `test_marker_writes_day_place_mission_and_recent` (a marker after three noted events holds the header and those three lines); `test_markers_file_rolls_over_at_max_bytes` (with `max_bytes` set small, two markers leave a `.old` and a fresh file); `test_recent_keeps_the_last_twenty` (21 events → 20 kept, the oldest gone).
- [ ] **Step 2: Run** `-- /test_session_log.gd` and `-- /test_session_layer.gd` → FAIL on the new tests.
- [ ] **Step 3: Implement** `SessionLayer.note_event` and `recent`; call it from the one place `GameUI` consumes region events (grep `region.events`); implement `SessionLog.marker`; F8 in `GameUI._unhandled_input` opens a `LineEdit` over the HUD (Enter writes, Esc cancels), only when `Designer.enabled()`.
- [ ] **Step 4: Run both files** → PASS; also `-- /test_session_ui.gd` unchanged.
- [ ] **Step 5: Commit** with `3.0: F8 playtest markers written to playtest_markers.md with the last events`.

### Task 5: Time of day for screenshots

**Files:**
- Modify: `game/tools/play_shot.gd` (named arguments after the positional ones)
- Modify: `game/src/world/office/office_day.gd` or `office.gd` only if no setter exists
- Test: `game/tests/test_play_shot_args.gd` (new, tests the parser only)

**Interfaces:**
- Produces: `PlayShotArgs.parse(args: PackedStringArray) -> Dictionary` (`{state, out, frames, at: int (minute of day, -1 when absent), season: String ("" when absent)}`); `--at HH:MM` sets the office clock before the shot (`Office.set_minute_of_day(minute)`: if the office has no such setter, add one that sets `session.minute_of_day` and refreshes `OfficeDaylight` and `OfficePeople`); `--season` is parsed and stored but applied only when 3.3 adds seasons (a `printerr` "season not built yet" until then).

- [ ] **Step 1: Write the failing tests**: `test_parse_positional_only`, `test_parse_at_and_season`, `test_bad_at_is_minus_one` (`--at 25:99` → -1).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** the parser as a small class at the top of `play_shot.gd` (or `game/tools/play_shot_args.gd`) and the setter. **Step 4: Run** → PASS; take `people_desks` at `--at 18:30` and look at it (the evening light, the late people). **Step 5: Commit** with `3.0: play_shot --at HH:MM (and --season parsed for 3.3)`.

### Task 6: The decision-day pack

**Files:**
- Create: `docs/qa/decision-day-2026-10.md`
- Modify: `PLAN.md` (§7, §9, §10 after Merijn answers; §1 status)

**Interfaces:** none (docs).

- [ ] **Step 1: Write the pack**: one table row per open item in PLAN §7 and every "Claude's calls, pending Merijn" block in §10 as of 2026-10-26: *item · where it lives (file:line or content id) · the default as built · the cost of changing it · Merijn's answer (blank)*. Group: rules, missions, talks, world, money. Add the three questions from spec §8.
- [ ] **Step 2: Merijn answers** (one sitting; this is his step, not an agent's).
- [ ] **Step 3: Record**: answers into PLAN §9 ("Merijn's decisions, decision day 2026-10-xx"); every §10 block that is now decided is collapsed to one line pointing at §9; §7 emptied of what was answered; per-talk verdicts from the checklist into `docs/qa/talk-verdicts-2026-10.md` (dialog id · verdict · Merijn's note).
- [ ] **Step 4: Commit** (docs only; no gate run needed) with `3.0: decision day: Merijn's answers in PLAN §9; §7/§10 cleared`.

### Task 7: Split `missions.gd`: `Coach` and `MissionSync`

**Files:**
- Create: `game/src/rules/coach.gd` (`class_name Coach`), `game/src/rules/mission_sync.gd` (`class_name MissionSync`)
- Modify: `game/src/rules/missions.gd:639-870`
- Test: existing `test_missions.gd` (64), `test_session.gd` (41), `test_coach_numbers.gd` (4), `test_facts.gd` (12), `test_gate_tuning.gd` (4), `test_game_save.gd` (7); add `test_split_keeps_save_keys` to `test_missions.gd`

**Interfaces:**
- Produces: `Coach` (RefCounted, holds `missions: Missions`): `ask(mission_id: String = "") -> Dictionary`, `question(m: MissionDef, stage: String, nth: int) -> String`, `conditions(m: MissionDef, stage: String) -> Array[String]`, `fading_fix(m: MissionDef) -> bool`, `stage_of(m: MissionDef) -> String`; `Missions.coach: Coach`; `Missions.ask_coach(mission_id)` stays as a one-line forward (callers: `session.gd`, `autoplay.gd`, tests).
- Produces: `MissionSync` (static functions taking `m: Missions`): `retire_orphans(m)`, `switch_on_forks(m)`, `sync_uncounted(m)`, `reoffer_recurring(m)`, `reopen_faded(m)`, `sync_checkins(m)`, `sync_repairs(m)`, called from `Missions.update()` in exactly today's order; `Missions._sync_uncounted()` stays as a forward for `load_dict` and `accept`.

- [ ] **Step 1: Record the baseline**: run the six test files one at a time; write the per-file counts to the commit message draft.
- [ ] **Step 2: Add the failing test** `test_split_keeps_save_keys`: a session played to the fork, `missions.to_dict().keys()` sorted equals the list recorded today (write the list into the test from a run on the unsplit code first).
- [ ] **Step 3: Move the coach** (`ask_coach`, `_question`, `_say`, `_conditions`, `fading_fix`, `stage_of`) into `Coach`, keeping `_say`'s question-bank memory on `Missions` where it is saved; forward `ask_coach`.
- [ ] **Step 4: Run the six files** → identical counts.
- [ ] **Step 5: Move the sync passes** into `MissionSync`; `update()` calls them in the same order.
- [ ] **Step 6: Run the six files** → identical counts; `test_split_keeps_save_keys` PASS.
- [ ] **Step 7: Commit** with `TD-3: Coach and MissionSync out of Missions (behaviour-neutral)` listing the before/after counts.

### Task 8: Split `region.gd`: `RegionSustain`

**Files:**
- Create: `game/src/rules/region_sustain.gd` (`class_name RegionSustain`)
- Modify: `game/src/rules/region.gd:904-1077`
- Test: existing `test_region.gd` (45), `test_sustain.gd`, `test_sustain_ui.gd` (14), `test_catalog.gd` (13), `test_save.gd`, `test_game_save.gd` (7); add `test_split_keeps_save_keys` to `test_region.gd`

**Interfaces:**
- Produces: `RegionSustain` (RefCounted, holds `region: Region`): `sustain(problem_id) -> Dictionary`, `health(problem_id) -> float`, `life_days(problem_id) -> float`, `held_by_routine(problem_id) -> bool`, `audit(place) -> Dictionary`, `wear(st: ProblemState, minutes: int)`, `apply_wear(st)`, `plan_routine(place) -> String`, `stop_routine(place) -> String`, `start_drift()`, `drift_level() -> float`, `apply_drift()`; `Region.sustain_rules: RegionSustain`; every public name above stays on `Region` as a one-line forward (callers: `session.gd`, the sustain view, autoplay, tests).

- [ ] **Step 1: Baseline counts** for the six files. **Step 2: Failing test** `test_split_keeps_save_keys` on `region.to_dict()`. **Step 3: Move** the twelve functions; forwards on `Region`; the tick loop calls `sustain_rules.wear` where it called `_wear`. **Step 4: Run the six files** → identical counts, new test PASS. **Step 5: Commit** with `TD-4: RegionSustain out of Region (behaviour-neutral)`.

### Slice 3.0 exit
- `docs/qa/playtest-checklist-act1-2.md` played by Merijn from the designer saves; per-talk verdicts recorded (Task 6 step 3); decision day done; PLAN §1 says "3.0 done, 3.1 next".
- Code review of the slice (the reviewer agent; findings fixed before 3.1 starts).

---

# Slice 3.1 — *Mensen* (spec §3)

Detailed in `docs/superpowers/plans/2026-10-27-phase3-slice31-mensen.md` (tasks 3.1-A–G and I to the step; 3.1-H stays task-level there until Merijn's per-talk verdicts).

---

# Slice 3.2 — *De straat* (spec §4)

**Task 3.2-A The street script** · Files: `content/town.yaml` (segments, lots, props for one 120 m street in Nova-Oost; validated), `tools/blender/build_street.py` (from the graph: road, pavements, twelve house shells with doors and meterkast panels, the bakery corner, the trafohuisje, the trench with cones and a KLIC board, vans, hedges, the canal edge; CC0 textures from the approved sources only; day lightmap; `--night` for a second bake or a runtime dim decided by a spike), `game/assets/town/street.glb`. Tests: `tests/test_town_content.py` (every lot a house, bakery or trafohuisje; the El Amrani lot named), a glb node-name test. Exit: `play_shot` states `street_day`, `street_evening`, `street_night` looked at.

**Task 3.2-B Getting there** · Files: `content/world.yaml` (`rides:` gains `street`), `van_ride.gd` (ends at the kerb; the return ride), `map_app.gd` (a *Nova* page), `minimap.gd` (street mode), `office.gd`/`office_building.gd` (the street as a floor-like area: nav, people, tells). Tests: `test_street_travel.gd` (ride → player on the street; back → the yard). Exit: a screenshot of the arrival.

**Task 3.2-C Missions onto the street** · Files: `missions.yaml` (`fix_not_at_home`: the bell and the note; `fix_digging_damage`: Gert at the trench, containment there), `scenes.yaml` (the El Amrani payoff at the door, kept and missed variants), `world.yaml` (street tells: the flickering lamp, the dug-up pavement, the "wanneer?" note), `office_tells.gd` (street readings), `build_content.py` (`check_tells` for the street), the trafohuisje place moved from the mock-up (the mock-up stays for Henk). Tests: `test_street_missions.gd`, the spoiler check on the new texts. Exit: Merijn's slice question.

**Task 3.2-D People on the street** · Files: `cast.json` (three residents, Gert; `day:` schedules), `office_people.gd` (the street's spots). Tests: `test_office_people.gd` extended.

**Slice 3.2 exit:** Merijn drives there from `designer_day045`, meets Gert, rings the bell; "voelde de buitenwereld als onderdeel van het bedrijf?"; frame time ≥ 30 fps on the reference machine; code review.

---

# Slice 3.3 — *Zichtbaar maken* (spec §5)

**Task 3.3-A Goal types** · `mission_def.gd`/`missions.gd`: `coach` (a named person's experiment reaches its Check), `routine` (N visits to a board over M weeks), `measure` (a KPI sampled K times); objective lines; validator. Tests: `test_mission_goals.gd`.

**Task 3.3-B Seasons and events** · `calendar.gd` (`SimCalendar.season(t) -> String`), `missions.gd` (`opens_on {season}`), `network.gd` (`storm` and `heatwave` events: arrival multipliers, a temperature for `TrafoThermal`), the HUD's date line, `office_daylight.gd` (shorter winter days, the first night). Tests: `test_seasons.gd`, `test_storm_event.gd` (outage minutes ×≥1.5 unprepared vs prepared).

**Task 3.3-C The group talk** · `dialog.gd` (shape `group`: participants with their own layers, one room meter, a move aimed at one person weighted into the room, the quiet one's route), `talk_view.gd` (the table shot, the chooser names whom you address), `build_content.py` (validation), `route_check.gd` (group talks counted). Tests: `test_group_talk.gd` (listening to the quiet one wins; pressing the loud one loses the room), `test_dialog_routes.gd` extended. Built with exactly two talks: `first_daily_board` and `interim_mt`.

**Task 3.3-D The control room** · `tools/blender/build_control_room.py` (a small building across the yard), `world.yaml`, two shift workers in `cast.json`, the escalation board as a tell with three states, the storm-night scene. Tests: `test_control_room.gd`, `check_tells`.

**Task 3.3-E Tier-2 problems through the harness** · `content/problems_tier2.yaml` (the five the spine uses), `countermeasures.yaml`; each run through `game/tools/draft_check.gd` on today's network **before** entering content; the tier-1 validators (shape test, spoiler check, `POOR_FIX_TEXT_READ_FOR`, `PLAIN_TEXT_READ_FOR`, the title token). Tests: `tests/test_mission_shape.py` extended to Act III; `test_catalog.gd`.

**Task 3.3-F The eight missions** · `missions.yaml`: `first_daily_board`, `coach_sanne` (Sanne's five answers with variants in `dialogs.yaml`; her experiment via `Region` on her problem), `fix_cause_unknown`, `prep_storm_week`, `heatwave_trafo`, `acm_visit` (scene; `waiting_list` into `kpis.yaml` and the HUD), `zandbergen_farm`, `lsw_board_round`. Tests per mission as in the audits; autoplay personas extended to play `coach` and `routine` goals.

**Task 3.3-G The reversal** · `ruud_farewell` (talk + the monthly call: `ask_coach` cooldown 28 days, one Kata cycle), `interim_mt` (the group talk reading `committed:frank_*`, `blocked:frank`, `heard:frank`: sponsor vs regime opening), the Act III end scene. Tests: `test_reversal.gd` (both Franks reachable from facts; the cooldown).

**Task 3.3-H Designer save `designer_act3`** · `DesignerSaves.SAVES` gains `{slot: "designer_act3", stop_act: 3}`.

**Slice 3.3 exit and the Phase 3 gate (spec §6):** Merijn and one cold player finish Act III; autoplay Acts 0–III, six personas, three seeds; the route check incl. the group talks; the storm hurts the unprepared; code review; the technical-debt trigger before Phase 4.
