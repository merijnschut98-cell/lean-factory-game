# Phase 1 gate: code review (PLAN 1.10, `requesting-code-review`)

Reviewer agent, 2026-10-16. Scope: `git diff 80836af..origin/claude/compassionate-heisenberg-ynlqyr -- game/src tools content` (HEAD `da81c77`), in this order: save and load, dialog engine and People, session layer / floors / office, content pipeline, architecture.

**Counts: 1 blocker · 5 should-fix · 6 nits.** Every finding below was traced from a real caller. Most were reproduced with a failing headless test or a Python script. The repro tests were run as `game/tests/test_zz_review_repro.gd`. That file is **not committed**; each test is expected to fail until fixed. Its code is in §Repros so a fix wave can paste it and watch each test turn green.

---

## Blocker

### B1. J / M / K mid-talk hides the talk, and the next press ends it unseen
`game/src/ui/game_ui.gd:199-205` (`_toggle`) with `game_ui.gd:225-229` (`close_panels`), reached from `office.gd:506-508` (the player's key signals are not gated on `ui.is_busy()`).

**Scenario.** The player is talking to Joost and wants to check a clue before using "Data laten zien". They press **J**, a natural move here. `_toggle(journal)` → `_open(journal)` hides every other panel, the dialog panel included, while `session._talk` keeps running. Then:
- If they press **J** again or click the journal's close button, `close_panels()` sees `dialog_panel.talking()` and calls `close_talk()`. That plays the `close` move: the talk ends as *heard* or *none* and People applies it. It then `return`s, so **the journal stays open and the summary card never shows**.
- If they press **M**, the map replaces the journal, and so on. The talk only reappears by chance.

Repro: `test_r1_journal_key_mid_talk` fails on both assertions (R1a: the dialog panel is hidden; R1b: the talk ended while the journal stayed open). This is very likely to happen in Merijn's playtest, and it silently spends a mission talk.

**Smallest fix.** In `_toggle`, do nothing while `dialog_panel.talking()`. Better, if the journal should be usable mid-talk: in `close_panels`, after `close_talk()`, call `_open(dialog_panel)` so the summary shows. Add a test that presses J twice mid-talk.

---

## Should-fix

### S1. A resume that fails drops the player into an unsaved game with no way back to the title menu
`game/src/world/office/office.gd:148-156` (`_resume` sets `autosaves = false`), `office.gd:138-139` (`begin_play` is skipped, so `ui.saves` stays null), `game/src/ui/game_ui.gd:168-170` (`open_pause` returns when `saves == null`).

**Scenario.** The title menu lists a save as playable because `SaveSlots.entry` only decodes it and checks the hash and version. `GameSave.read` then fails on `RegionState.restore` (a shape error) or on a content load. The office shows the RESUME_FAILED toast and starts a fresh game that never saves, which is intended. But **Esc does nothing** (no pause menu), so the only way out is closing the window. Repro: `test_r2_failed_resume_has_no_way_back` (a hash-valid save with `region.network = 1`; the save list shows it as playable, then the pause menu does not open).

**Smallest fix.** Keep the pause menu without saving. Pass `saves` to the UI with an `autosave_off` flag, or let `open_pause` work with `saves == null` and show only "Verder spelen · Naar het titelmenu". Better still, make `SaveSlots.entry` mark a save `DAMAGED` when `GameSave.read` would fail. That costs one restore per card, so a cheaper option is `RegionState`'s shape check in `entry`.

### S2. The save write is not atomic on Windows, and a leftover `.tmp` is never recovered
`game/src/save/save_file.gd:95-101` and `save_file.gd:107-112`.

**Scenario.** On Windows, which is the playtest platform (`Spanning-windows-playtest`), Godot's `DirAccessWindows::rename` **removes an existing destination first, then calls `MoveFileW`** (godotengine/godot `drivers/windows/dir_access_windows.cpp`). The comment "a crash mid-write never leaves a half-written save" is true, but a crash, power cut or kill between the remove and the move leaves only `autosave.save.tmp`. `load_slot` never looks at the `.tmp`, so the title menu shows no autosave, and `wipe()` deletes it. There is also no flush or fsync before the rename. On Linux the rename is atomic, but the window is real on Windows. Repro (simulating the state after the crash): `test_r3_tmp_left_after_crash_is_not_recovered`.

**Smallest fix.** In `load_slot`, when `<slot>.save` is missing and `<slot>.save.tmp` decodes cleanly (the SHA-256 already proves it whole), rename it into place and load it. Add `file.flush()` before `close()`. A test: write, rename to `.tmp`, and `entries()` still lists it.

### S3. "Nieuw spel" (and continuing a manual slot) silently replaces the previous game's autosave
`game/src/ui/title_menu.gd:137-141` ("a fresh game: no save is touched"), `office.gd:97-99`, `game_ui.gd:352-353` / `425-431`.

**Scenario.** A player has 30 in-game days in the autosave and never saved by hand. They click "Nieuw spel" to look at Act 0 again and close the window. `end_session()` autosaves the new game over the old one, and the old game is gone. Repro: `test_r5_new_game_replaces_the_autosave` (the autosave's game time goes from day 30 to day 0). This is the accepted call in PLAN §10 ("one shared autosave that a new game replaces"), but nothing in the UI says so, and the title menu's own doc comment claims the opposite. It goes against "no loss for stopping" and "respect the player's time".

**Smallest fix (no change to the call).** When the autosave is filled, "Nieuw spel" asks once: "Je automatisch opgeslagen spel wordt vervangen zodra dit spel zichzelf opslaat. Eerst opslaan in een slot?" Fix the comment at `title_menu.gd:137`. **Merijn's call** whether the autosave should instead belong to the game being played (one autosave per game).

### S4. Content pipeline: a variant's layers may unlock a proposal that does not exist
`tools/build_content.py:1341-1344`. Only `d["layers"]` is checked against the hidden proposals. `variants[*].layers[*].unlocks.proposals` is never checked.

**Scenario.** A typo in `ahmed_after_henk`'s variant concern, such as `unlocks: {proposals: [no_such_proposal]}`, builds cleanly. In play, `Dialog._picks("propose")` never shows the hidden proposal, so the variant can lose its only concern-addressing proposal and the "two ways in" rule is quietly broken. Repro: the S4 Python script in §Repros. The variant typo is ACCEPTED; the same typo in the base layers is rejected.

**Smallest fix.** Loop over `_all_layers(d)` (it already exists) instead of `d["layers"]`.

### S5. Content pipeline: a typo in a floor's model loads the stand-in office without a word
`tools/build_content.py:1016` (a regex only), `game/src/world/office/office.gd:193-198` (`_load_geometry` falls back to `OfficePlaceholder` silently).

**Scenario.** `model: office_secnd.glb` in `world.yaml` passes `--check`. Taking the stairs to the 2e verdieping then loads the *connections office* placeholder as that floor, with no warning. Repro: the S5 Python script in §Repros, where the typo'd model is ACCEPTED.

**Smallest fix.** In `check_world`, require `game/assets/office/<model>` to exist. In `_load_geometry`, `push_warning` when a named model is missing.

---

## Nits

- **N1. Malformed values in a hash-valid save raise a script error mid-load.** `game/src/rules/people.gd:504`: `Array(v.get("flags", []))` on a non-list fails with "Nonexistent 'Array' constructor" (repro `test_r4_memory_flags_not_a_list`). The same class of error appears at `discoveries.gd:453` (`int(<Dictionary>)`) and `people.gd:561-563` (`_observe_revealed` indexes `variants[v]` for a saved key `"<dialog>/<v>"` whose variant the content has since removed; only saves from before the notebook). The SHA-256 keeps out random damage, so this needs a hand-edited save or a save from a buggy build. Fix: type-check before converting (`v.get("flags") is Array`) and bounds-check `v < d.variants.size()`.
- **N2. The training glossary card shows again after every resume.** `game_ui.gd:55` `_carded` is not saved, so `_glossary_card` fires again for an active training day on the first `after_action`. Fix: derive it from the profile's known concepts, or save it in the session layer.
- **N3. The title menu decodes every save in full to show its card.** `save_slots.gd:84` (`entry` → `load_slot` → `bytes_to_var` of the whole game, six times, and again on every refresh). Cheap today (under 1 MB). If saves grow, put `meta` in the header.
- **N4. More than 4 parameters** (CLAUDE.md §3 architecture): `GameSave.write(slot, s, layer, dir, saved)` at `game_save.gd:19`, and `Dialog.weight(archetype, need, today, move, was_heard)` at `dialog.gd:614`. Pass the session pair as one object, and a `{need, mood, heard}` context.
- **N5. `Office` mixes the save flow with the 3D world.** `office.gd:53-60, 95-178` (`saves`, `play`, `_resume`, `to_title`, `_notification`, `RESUME_FAILED`) sit in the scene that builds geometry, input and camera. Move the resume and title flow into a small `GameLauncher` / `SaveSlots` helper that hands the office a session and layer. This would also make S1 easy to fix.
- **N6. People holds both the rules state and the Mensen notebook.** `people.gd:103-110, 267-295` (`observed`, `talk_log`, `note`, documented as "never read by the rules"). A `PeopleNotebook` beside People would keep the rules module about rules. Low priority.

---

## Checked and clean (no finding)

- **Path construction (security):** slot names pass `^[a-z0-9_]{1,40}$` (`save_file.gd:22`), and `SaveSlots` takes only the six fixed names and a folder under `user://` with no `..` or `\` (`save_slots.gd:46-48`). The playtest log path is fixed. The 64 MB guard is read before the buffer. `bytes_to_var` never decodes objects.
- **Version handling:** v1 bare files are accepted only when the first byte is `TYPE_DICTIONARY`. Too old, too new and damaged are told apart and listed last without a button. A failed resume never writes over the save.
- **People, explainers and floor in the save:** every People field is in `to_dict`/`load_dict`. `ExplainerLog` and `SessionLayer.floor_id` round-trip. A talk in progress is deliberately not saved.
- **Floors:** there are no signal leaks on floor switches. Every connection is made once, `refresh_map` guards `floor_chosen`, and people, geometry and interactables are freed and rebuilt. A resumed game on a shut or unknown floor stays on the start floor (`office.gd:167-171`) and keeps the saved id.
- **Dialog rules against CLAUDE.md §2:** the meter shows arrows, a band and pips, never a number (tested). A ruin costs trust −5, reputation −1 and a cooldown to the next working morning, never a door. Every move is always offered. The pipeline demands two concern-addressing proposals per persuasion and a robust route for every block. People leaving after 60 low days plus 2 ignored prompts is Merijn's decision (2026-10-15).

## Repros

`game/tests/test_zz_review_repro.gd` (not committed; each test asserts the correct behaviour and fails today). Run it with `godot --headless --path game --script res://tests/run_tests.gd -- zz_review`. The result on `da81c77`: 0 passed, 7 failed (R1a, R1b, R2 plus its warning, R3, R4, R5).

```gdscript
extends TestCase
const SCENE := "res://src/world/office/office.tscn"
var dir := TestCase.scratch("review_saves")

func _cleanup() -> void:
	SaveSlots.new(dir).wipe()
	if DirAccess.dir_exists_absolute(dir):
		for file in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file))
		DirAccess.remove_absolute(dir)

func _office(slot := "", with_saves := false) -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	if with_saves:
		office.saves = SaveSlots.new(dir)
		office.play(slot)
	office.build()
	return office

func test_r1_journal_key_mid_talk() -> void:  # B1
	var office := _office()
	var s := office.session
	s.missions.done_once["fix_unused_capacity"] = true
	s.accept("fix_silo_kpis")
	s.region.found["silo_kpis:4"] = true
	assert_eq(office.ui.open_talk("joost"), "")
	office.ui.toggle_journal()
	assert_true(office.ui.dialog_panel.visible, "R1a")
	office.ui.toggle_journal()
	assert_false(office.ui.journal.visible and s.dialog_meter().is_empty(), "R1b")
	office.free()

func test_r2_failed_resume_has_no_way_back() -> void:  # S1
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(SaveFile.path_of("slot_1", dir), FileAccess.WRITE)
	file.store_buffer(SaveFile.encode({"version": 2, "region": {"network": 1}}))
	file.close()
	var office := _office("slot_1", true)
	office.ui.open_pause()
	assert_true(office.ui.pause_menu.visible, "R2")
	office.free()
	_cleanup()

func test_r3_tmp_left_after_crash_is_not_recovered() -> void:  # S2
	var slots := SaveSlots.new(dir)
	slots.autosave(GameSession.new_game(11, Catalog.DATA_DIR, false), SessionLayer.new())
	var path := SaveFile.path_of(SaveSlots.AUTOSAVE, dir)
	DirAccess.rename_absolute(path, path + ".tmp")
	assert_false(slots.entries().is_empty(), "R3")
	_cleanup()

func test_r4_memory_flags_not_a_list() -> void:  # N1
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.people.load_dict({"memory": {"joost": {"flags": 5}}, "talks": {}})
	assert_true(s.people.memory.get("joost", {}).is_empty(), "R4")

func test_r5_new_game_replaces_the_autosave() -> void:  # S3
	var slots := SaveSlots.new(dir)
	var old := GameSession.new_game(11, Catalog.DATA_DIR, false)
	old.region.advance_days(30)
	slots.autosave(old, SessionLayer.new())
	var before: Variant = slots.entry(SaveSlots.AUTOSAVE)["time"]
	var office := _office("", true)
	office.ui.end_session()
	assert_eq(slots.entry(SaveSlots.AUTOSAVE)["time"], before, "R5")
	office.free()
	_cleanup()
```

Python repros (run from the repo root with `python -I`): S4 sets `variants[i].layers[1].unlocks.proposals = ["no_such_proposal"]` on `ahmed_after_henk` and calls `validate_dialogs`; S5 sets `floors[2].model = "office_secnd.glb"` and runs `validate_world` plus `check_world`.
