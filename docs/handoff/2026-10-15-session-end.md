# Handoff — end of session 2026-10-15

For the planning session (Fable) and the next build session. PLAN.md stays the source of truth; this note lists what is in flight and where unfinished work lives.

## State
- Branch `claude/compassionate-heisenberg-ynlqyr`, PR merijnschut98-cell/lean-factory-game#1 (draft). Pushed HEAD is green: full gate (Godot tests, content `--check`, pytest) and CI.
- Built and merged this session:
  - sustain-or-decay and stagnation drift (`rules/sustain.gd`) with its UI (audits, routines, health, drift), a narrower place menu;
  - the Sims-like third-person camera with click-to-move;
  - the QA autoplay bot (`game/tools/autoplay.gd`, `docs/qa/autoplay-report.md`) and the crash fix it found;
  - missions:
    - wave 1 (C0, C1, C9 reputation, C14 belts, C19 path dependence, C20 repair quests, K0 concepts);
    - wave 2 (coach, rewrites, correctness fixes, Act II swap, rewards over time, hidden rewards);
  - sample characters scripted in Blender (`game/assets/characters/`, screenshots `docs/screenshots/characters_*.png`).
- Design docs (all in `docs/superpowers/specs/`, dated 2026-10-15):
  - mission system and catalogue;
  - audit and engagement;
  - tier-2, tier-3 and tier-4 drafts;
  - tier-2 dialogs;
  - dialog system;
  - dialog scripts Acts 0–II;
  - engagement loop;
  - four-tier audit (partial);
  - sustain and drift.

## Unfinished work, saved as patches (the worktrees die with the container)
1. **Dialog engine**: `docs/handoff/dialog-engine-f5319f4.patch` (37 files).
   - Applies with `git am` onto `fae460a`. It passed the full gate there: 472 Godot tests, 484 pytest.
   - Merging it onto today's HEAD conflicts in five files: `tools/build_content.py`, `game/src/game/session.gd`, `game/src/rules/catalog.gd`, `PLAN.md` and `game/data/vocabulary.json`.
   - Do it as a careful merge: apply on a branch from `fae460a`, then merge HEAD into it.
   - Still open after the merge: `talk_to` mission goals (`talk_outcome()` is ready), coach follow-ups after a talk, check-in cadence limits, the rest of the cast, and all dialog UI.
2. **El Amrani followed order + containment**: `docs/handoff/wip-mission-followed-order-containment.patch`, the mission builder's stash. Not gate-clean.
   - Missing: the `Discoveries.note_contain` and followed-order triggers, the containment validator, and the content on `fix_digging_damage`.
3. **Check honesty and debt recovery (QA #4, #5, #6, #21)**: merged (c8a93c6).
   - The Check simulates with and without the fix and passes only if the predicted KPI improves by more than 2%.
   - Wait steps are scored on lead time.
   - Debt floors at −€50k, and held fixes pay weekly savings.
   - Still open: regenerate `docs/qa/autoplay-report.md` (the rerun command is in PLAN.md), and Dutch UI text for `not_moved` and `impact_lead_time_small`.

## Next work, in order of value
1. Merge the dialog engine, then build the dialog UI (the meter bar with arrows, the walk-around energy bar, reply chips by move type).
2. Apply the four-tier audit's open fixes:
   - unset facts;
   - six tier-2 promises missing in tier 4;
   - shortcuts with no later cost;
   - up to 7 sides opening at once;
   - dialog sameness (every concern revealed by silence; the "Afgesproken." openers).
3. Apply `docs/qa/tier2-sim-check.md`:
   - 30 of 137 claims fail;
   - `safety_stock_calendar` is inert;
   - the ACM 85% target can't be failed;
   - all six OKR key results are wrong;
   - three fixes are confirmed, the rest need re-measuring.
   Then bring tier 2 into content (wave 3).
4. The QA Check findings, if not finished (below).
5. The character method: Merijn chooses Blender, an AI generator or asset packs, after seeing the samples. Known issues: the walk animation is paced for 1.2 m/s against a 3 m/s player speed (foot sliding), and the glbs are 3.5–4.2 MB each.

## Merijn's standing rules from this session
These are in CLAUDE.md §2 and PLAN.md Decisions:
- reward deep thinking (long term, respect for people, always improve);
- dialogs are give and take, with a visible bar meter, arrows and no numbers;
- respect the player's time;
- mission and dialog agents run continuously, and Claude tells Merijn if that stops;
- smaller open questions take their recommended option, logged under "Claude's calls, pending Merijn".

## Process lessons
- Agents commit silently: check `git log origin/<branch>..HEAD` every ~30 minutes and push after a clean-worktree gate, or CI goes quiet (it did for 43 minutes).
- The gate is slow while several agents run simulations; run it in the background.
- "Send now" in the app interrupts every running agent, and a stopped agent can't be resumed: relaunch it fresh, pointing it at its worktree.
