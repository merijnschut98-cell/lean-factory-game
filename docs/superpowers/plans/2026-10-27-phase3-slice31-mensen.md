# Phase 3, slice 3.1 *Mensen*: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make improvement felt in people. Colleagues stay late, slump and fall ill under load, and recover when a fix holds. The player and two colleagues get promoted on results that hold. Ruud comments on what he saw. Frank reads the month's figures at the board. The phone gains two apps: Voltana (the company) and Ik (you). The KPIs a team lead agreed to in a talk hang on the board.

**Architecture:** One new rules reading, `Strain`, built from values `People` already keeps or derives from the simulation (team load, morale, recent pressure). The office, the chatter and the absence effect read it. Promotions live in a new game-layer `Career` (the content is `content/career.yaml`). Reviews and celebrations are milestone scenes on the existing `SceneScript`/`OfficeMilestone` path; milestones may now recur. The company numbers come from one function per tile in a new `CompanyView` and from monthly samples in `CompanyLog`. The monthly scene and the Voltana app read the same functions. Every task lands on its own through the gate.

**Tech Stack:** Godot 4.7 / GDScript (`game/`), Python 3 content pipeline (`tools/build_content.py`, YAML → `game/data/*.json`), pytest (`tests/`), the Spanning Godot runner (`tools/run_godot_tests.py`; one file: `godot --headless --path game --script res://tests/run_tests.gd -- /test_x.gd`).

**Spec:** `docs/superpowers/specs/2026-10-26-phase3-design.md`: §3.1–§3.5 (this plan), §1 (decisions), §6 (the gate). The parent plan is `docs/superpowers/plans/2026-10-26-phase3-voelbaar.md`. Read the decision-day pack too, `docs/qa/decision-day-2026-10.md`: rows F1, T2, T4a–d, R5a–b, R7.

**Out of scope:** 3.1-H, the rewrite of the Act I–II talks. It waits for Merijn's verdicts per talk from the playtest. Its task-level text is kept at the end of this file so that nothing is lost.

## Global Constraints

Carried over verbatim from the parent plan (the task numbers in these lines are the parent plan's slice 3.0 tasks):

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

Added for this slice:

- **The gate before every commit:** `python tools/run_godot_tests.py`, `python tools/build_content.py --check` and `python -m pytest tests/ -v`, all green. Any change to content is followed by `python tools/build_content.py`, and the regenerated `game/data/*.json` go in the same commit.
- **Network rule, verbatim (CLAUDE.md §3), to be repeated in every brief:** "The environment has full network access, but **never access a domain Merijn has not approved**. Approved: assets `quaternius.com`, `opengameart.org`, `itch.io` incl. `quaternius.itch.io` and its file-storage host `itchio-mirror.cb031a832f44726753d6267436f3b414.r2.cloudflarestorage.com` for downloads; sources `rijksoverheid.nl`, `officielebekendmakingen.nl`, `wetten.overheid.nl`, `acm.nl`, `netbeheernederland.nl` (incl. subdomains), `cbs.nl`, `knmi.nl`, `nen.nl`, `tennet.eu`; tooling `docs.godotengine.org`, `github.com`, and the package managers the project already uses. Web search is allowed; opening a result is only allowed on this list. Any other domain (a mirror, a CDN a download redirects to, a source page): ask Merijn first, naming the domain and why. Agents stop and report instead of fetching. Every brief to an agent repeats this rule."
- **No invented readings.** Each thing a person shows (staying late, posture, chatter, absence, a comment Ruud makes) traces to a value the simulation or `People` already keeps. Thresholds live only in `Strain` (Task 1) and in `content/career.yaml`.
- **Salary is shown (Merijn, 2026-10-27):** estimated euro amounts per step: Frank names the new monthly amount at a promotion ("± € … bruto per maand") and the Ik app shows it, each marked as an estimate in `career.yaml`.
- **Respect for people and the long term in the rewards:** a promotion needs fixes that hold, people who trust you and nobody pressed, and a customer who waits less. XP alone never promotes. Salary feeds nothing.
- **No compulsion:** missing a review, a celebration or the monthly figures costs nothing. A refused review always names when the next one is, and that review comes.
- **PLAN.md in the same commit:** each task ticks its sub-item under Phase 3 → 3.1 and adds any task it discovers (CLAUDE.md §1). New calls of Claude's go to §10 under "Claude's calls, pending Merijn (2026-10-27, slice 3.1)".
- **Save keys:** every new save key is listed in the task that adds it. A task that adds a key to `Missions.to_dict` updates the expected list in `test_missions.gd::test_split_keeps_save_keys` in the same commit and says so in its commit message.
- **The "Imago & vertrouwen" tile: Merijn decided F1 on 2026-10-27: the directie's trust plus customer satisfaction.** Its inputs are one function, `CompanyView.reputation_tile(s)`. Headline: the directie's reputation; a second row: customer satisfaction, **derived** (no new state) from kept vs missed customer appointments (`FollowedOrder`, `story_order` met/missed facts) and the outcome of customer calls (`customer_calls.gd`, promise kept/broken facts), as a share with its formula and weights documented as an estimate in the function's doc comment. ACM standing is not built (it would be new state; a later decision).

## Review Focus

1. **An old save from before 3.1.** It loads with every new state at its default: no smoothed loads, no career, an empty company log. Nobody is late or absent on the first refreshed day, until a daily sync has run. A save must not show the whole office late because a missing load reads as 0 or as INF. Pinned by Task 1 `test_old_save_without_strain_state_loads_calm`, Task 3 `test_old_save_starts_the_log_at_load` and Task 4 `test_career_round_trips_and_an_old_save_is_a_ci_lead`.
2. **A long time skip.** `wait_days(14)`, a 91-day Check forecast and a quarter skip each advance in one step. Smoothing must compound over the whole span, and the monthly log must not back-fill months it never measured. The monthly milestone must not open twice in one month, and must open again the next month after a missed first working day. Pinned by Task 1 `test_smoothing_over_a_span_equals_day_by_day`, Task 3 `test_a_skip_over_three_months_adds_one_sample` and Task 8 `test_a_skipped_first_workday_opens_next_month`.
3. **Someone who has left or retired** (Henk on his beat, a colleague who went to another grid operator). Such a person has no strain, no absence and no chatter. Henk's retirement is not counted as "nobody left" in a review, but a colleague who left because of you is. Pinned by Task 1 `test_someone_who_left_has_no_strain` and Task 4 `test_a_retirement_is_not_a_departure`.
4. **A review the player never walks into, or a refused one.** The milestone waits without a deadline. A refusal names the first unmet condition and a real date, and the review opens again `every_days` later. After a promotion it never opens again. Pinned by Task 5 `test_refused_review_names_the_condition_and_comes_back_in_91_days` and `test_promoted_review_stays_shut`.
5. **Empty or thin numbers.** A stream with fewer than `SessionLayer.MIN_COMPLETED` finished orders in the window, a log with one sample, or a reputation that has not moved. The tile shows "—" or "gelijk", never 0, NaN or an arrow pointing the wrong way. Pinned by Task 3 `test_a_thin_stream_reads_as_unknown_not_zero`.

---

## Order and dependencies

| # | Task | Spec | Depends on |
|---|---|---|---|
| 1 | 3.1-A Strain | §3.1 | none |
| 2 | 3.1-I Wire `agreed_kpis` | §1 (Claude's calls) | none |
| 3 | 3.1-G part 1: `CompanyView` and `CompanyLog` | §3.5, §3.4 | 1 (the Mensen tile reads strain) |
| 4 | 3.1-B Career content and `Career` | §3.2 | 3 (the customer condition's baseline) |
| 5 | 3.1-C The review talk | §3.2 | 4 |
| 6 | 3.1-D Colleagues step up | §3.2 | 4, 5 (recurring milestones, `promoted:`) |
| 7 | 3.1-E Ruud comments | §3.3 | 1 (`{wie}` must be home on time) |
| 8 | 3.1-F The monthly figures | §3.4 | 3, 5 (milestone recurrence), 7 (Ruud's line) |
| 9 | 3.1-G part 2: the Voltana and Ik apps | §3.5 | 3, 4, 5, 6 |

## Rulings where the spec and today's code disagree

These are Claude's calls. Each goes to PLAN §10 when its task lands.

1. **`PersonState.strain(team)` (spec §3.1)**: there is no `PersonState`. Morale and pressure belong to a person, not a team, so strain is per person: `People.strain(person_id, now)` over a pure `Strain.reading(load, morale, pressed)`.
2. **"Capacity already drops with a missing person (`People.left` path)" (§3.1)**: it does not. `People.left` never touches the `Network`. A sick day is a `headcount` effect, source `absent:<team>`, set for the next day, because attendance follows the next morning in `SimModifiers`.
3. **"No `pressured:` fact in the last quarter" (§3.2)**: no such fact kind exists. Pressure is read from what is already saved: a `pressure` or `confront` move in `People.talk_log` within the window, or a fix won by compliance.
4. **"A new dialog kind `review`" (§3.2)**: a review has no meter and no moves. It is a recurring milestone scene on the existing `SceneScript`/`OfficeMilestone` path, whose beats read live `career:<step>:<condition>` atoms. No new dialog engine shape.
5. **"Anouk → team lead Werkvoorbereiding (`skills_matrix_buddy` or TWI held)" (§3.2)**: Joost is that team lead, and those two countermeasures fix `knowledge_drain` (Henk → Ahmed). So Anouk becomes senior werkvoorbereider on her own team's fix (`custom_design`), and Ahmed becomes praktijkopleider on Henk's transfer. Sanne waits for `coach_sanne` (3.3).
6. **"A new title in `company.yaml`" (§3.2)**: `company.yaml` is static, built content. A promotion is saved state, so titles go through `GameSession.title_of(id)`. Desk moves wait for the next office bake (no Blender here).
7. **"From the KPI board's birth (day 100)" (§3.4)**: the board is born at `first_kpi_review` (end of Act II), and day 100 is `review_100_days`. The figures start on day 100, as the spec dates them, at the board wall in `directors_obeya`.
8. **"The year-end review, after winter 1" (§3.2)**: it opens on 2027-03-01, the first working day after meteorological winter, as an estimate, and recurs quarterly until passed.
9. **`SessionLayer.monthly` (parent plan's task list)**: the samples live in a rules-side `CompanyLog` on `GameSession`, saved under `"company"`, because Career's customer condition needs the baseline and autoplay has no session layer.
10. **The hand-to-neck clip (§3.1)**: Blender is not in this environment. The code falls back to the tired clip, and the clip is a tracked PLAN sub-task.

---

### Task 1: 3.1-A Strain

**Files:**
- Create: `game/src/rules/strain.gd` (`class_name Strain`, static only)
- Modify: `game/src/rules/people.gd` (smoothed loads, strain, absence, counters, save)
- Modify: `game/src/game/session.gd` (`strain_of`, `absent_today`, the absence effect in `_sync_people`)
- Modify: `game/src/world/office/office_day.gd` (`stays_late(strain)`, `late_ids` through `strain_of`; drop `LOAD_NORM`, `LOW_MORALE`)
- Modify: `game/src/world/office/office_people.gd` (`_where`: absent → `ALWAYS_OUT`; pass strain to `show_energy`)
- Modify: `game/src/world/office/office_person.gd` (posture from strain; drop `TIRED_ENERGY`)
- Modify: `game/src/rules/reactions.gd`, `game/src/game/session_talks.gd` (chatter by strain band)
- Modify: `content/dialogs.yaml` (`chatter:` gains `strain:` snippets), `tools/build_content.py` (`_validate_passing`: `CHATTER_STRAINS`)
- Test: `game/tests/test_strain.gd` (new), `game/tests/test_office_day.gd` (the stays-late test rewritten; the `Clock` stand-in gains `strain_of`), `game/tests/test_people.gd` (save round trip), `tests/test_passing_lines.py`

**Interfaces:**
- Produces, `Strain` (estimates, documented in the file):
  - Weights: `LOAD_W := 0.6`, `MORALE_W := 0.25`, `PRESSURE_W := 0.15`.
  - Morale: `STRAIN_MORALE := 50` (below this, morale adds strain, reaching full strain at `People.LEAVE_MORALE`).
  - Windows: `SMOOTH_DAYS := 7` and `PRESSED_DAYS := 30`.
  - Bands: `EASY_BELOW := 0.15`, `LATE_AT := 0.35`, `SLUMP_AT := 0.5`, `NECK_AT := 0.7`, `ABSENT_AT := 0.8`, `ABSENT_AFTER_DAYS := 21`.
  - `static reading(load: float, morale: int, pressed: bool) -> float` returns `clampf(LOAD_W·L + MORALE_W·M + PRESSURE_W·P, 0, 1)`, where `L = clampf((load − People.LOAD_NORM) / People.LOAD_SPAN, 0, 1)`, `M = clampf((STRAIN_MORALE − morale) / float(STRAIN_MORALE − People.LEAVE_MORALE), 0, 1)` and `P = 1.0 if pressed else 0.0`.
  - `static smoothed(seen: float, load: float, days: int) -> float` returns `load + (seen − load) · pow(1 − 1.0/SMOOTH_DAYS, days)`.
  - `static band(strain: float) -> String` returns `"low"` below `EASY_BELOW`, `"high"` from `LATE_AT` up, `"mid"` between.
  - `static sick_weekday(person_id: String, week: int) -> int` returns `posmod(hash([person_id, week]), 5)`.
- Produces, `People`:
  - State: `var load_seen: Dictionary[String, float]` (team → smoothed load), `var strained_since: Dictionary[String, int]` (person → the day their strain first reached `ABSENT_AT`; erased below it), `var late_log: Array[int]` (per working day, how many people stood at `LATE_AT` or above; the last 20 working days kept) and `var sick_days := 0` (cumulative).
  - `strain(person_id: String, now: int) -> float`: 0 for an unknown person or one who left.
  - `pressed(person_id: String, now: int) -> bool`: a `pressure` or `confront` in their `talk_log` moves within `PRESSED_DAYS`, or their best agreement on a dialog that owns a fix is `compliance` (raw `outcomes`, so no facts are needed).
  - `off_on(person_id: String, day: int) -> bool`: true when `strained_since` is at least `ABSENT_AFTER_DAYS` before `day`, `day` is a working day, and its weekday equals `Strain.sick_weekday(id, day / 7)`.
  - `absent_on(day: int) -> Dictionary`: team → how many are off.
  - New save keys in `to_dict`: `load_seen`, `strained_since`, `late_log`, `sick_days`.
- Produces, `GameSession`: `strain_of(person_id: String) -> float`, `absent_today(person_id: String) -> bool` and `const ABSENT_SOURCE := "absent:"`. Its effect is `{target: <pool id>, property: "headcount", value: −n}`, set at each day change for tomorrow (attendance follows the next day, `SimModifiers`) and cleared for a team with nobody off.
- Produces, `OfficeDay`: `static stays_late(strain: float) -> bool` (`strain >= Strain.LATE_AT`). `late_ids(session, ids)` calls `session.strain_of(id)` when the session has it, and is otherwise empty.
- Produces, `Reactions.chatter_for(teams: Array, load: String, n: int, weekday := -1, strain := "")`: a snippet with `strain:` fits only that band, and the pair's band is that of their higher strain.
- Consumes: `People.LOAD_NORM`, `LOAD_SPAN`, `LEAVE_MORALE`, `NEGLECT_FLOOR`; `GameSession._team_loads()`; `Region.net.set_effects` / `clear_effects`.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_strain.gd`:
  - `test_reading_is_zero_on_an_ordinary_day`: `Strain.reading(People.LOAD_NORM, 60, false) == 0.0`.
  - `test_reading_weights_each_part`: `reading(People.LOAD_NORM + People.LOAD_SPAN, Strain.STRAIN_MORALE, false) == Strain.LOAD_W`; `reading(0.5, People.LEAVE_MORALE, false) == Strain.MORALE_W`; `reading(0.5, 60, true) == Strain.PRESSURE_W`; `reading(2.0, 0, true) == 1.0`.
  - `test_neglect_without_load_never_keeps_someone_late`: `reading(People.LOAD_NORM, People.NEGLECT_FLOOR, false) < Strain.LATE_AT`.
  - `test_smoothing_over_a_span_equals_day_by_day`: `Strain.smoothed(1.08, 0.70, 14)` is within 1e-9 of applying `smoothed(x, 0.70, 1)` fourteen times.
  - `test_a_holding_fix_sends_anouk_home_within_14_days`. Set up: `s := GameSession.new_game(11, Catalog.DATA_DIR, false)`, `s.region.activate("custom_design")`, `s.wait_days(21)`. Assert `OfficeDay.late_ids(s, ["anouk"]).has("anouk")`. Then put the fix in place the way `Region.act` leaves it: `s.region.deactivate("custom_design")`, set phase `RESOLVED`, `s.region.net.set_effects("cm:custom_design", <the standard_designs effects from s.region.countermeasures>)`. Run `s.wait_days(14)` and assert she is not late. The probe on 2026-10-27 measured work_prep's load at 1.08 with the problem, 0.83 at the base and 0.71 with the fix.
  - `test_the_problem_back_brings_her_desk_lamp_back_within_14_days`: from the fixed state, `s.region.net.clear_effects("cm:custom_design")`, `s.region.activate("custom_design")`, `s.wait_days(14)`, and she is late again.
  - `test_absence_needs_load_wear_and_pressure`. Use a `DialogFixture` person with a talk log that holds `"pressure"` today, morale 25 and loads `{team: 1.2}` fed through `daily` for 21 days. `off_on` is true on exactly one working day in each later week. The same without the pressure gives no day off.
  - `test_someone_who_left_has_no_strain`: `left[id] = true` gives `strain(id, now) == 0.0` and no `off_on`.
  - `test_old_save_without_strain_state_loads_calm`: `load_dict(old)` with none of the four keys gives `strain == 0.0` for everyone until the first `daily`.
  - `test_no_threshold_outside_strain`: `OfficeDay` and `OfficePerson` scripts have no constant named `LOAD_NORM`, `LOW_MORALE` or `TIRED_ENERGY` (via `get_script_constant_map()`).
- [ ] **Step 2: Run** `godot --headless --path game --script res://tests/run_tests.gd -- /test_strain.gd`. Expected: FAIL (`Strain` not found).
- [ ] **Step 3: Implement `Strain`** with the constants and the four statics above.
- [ ] **Step 4: Implement the `People` part.** In `_drift`, smooth `load_seen` before the training return. A team seen for the first time takes today's load unsmoothed. After the morale drift, update `strained_since` and `late_log`, and add `sick_days` for every working day in the span on which `off_on` holds. A span of n days counts today's reading for each of its working days: no invented intermediate days. Add the four save keys, loaded with the same validators as `drift_carry` (unknown ids dropped, values clamped).
- [ ] **Step 5: Implement the `GameSession` part.** `strain_of` and `absent_today`. In `_sync_people`, on a day change, set or clear `ABSENT_SOURCE + team` for tomorrow from `people.absent_on(day + 1)`.
- [ ] **Step 6: Implement the office readers.** `OfficeDay.stays_late(strain)` and `late_ids`. In `OfficePeople._where`: `absent_today` → `ALWAYS_OUT`, so the greeting is missed because the person is not there. In `OfficePerson.show_energy(state)`, read `state["strain"]`: `tired` at `SLUMP_AT` or above, and the clip `"neck"` (seated `"sit_neck"`) at `NECK_AT` or above. `FALLBACK` gains `"neck": "tired"` and `"sit_neck": "sit_tired"`. `OfficePeople.refresh` merges `{"strain": session.strain_of(id)}` into the state it passes. Rewrite `test_office_day.gd::test_who_stays_late_is_the_load_or_the_morale_in_one_rule` as `test_who_stays_late_is_the_strain`, with the `Clock` stand-in's `strain_of` reading a dict. Keep `test_at_half_past_six_only_those_who_stay_late_are_still_in` passing with Linda given strain 0.6 instead of energy 0.2.
- [ ] **Step 7: Add chatter by strain.** `Reactions.chatter_for` gains the `strain` parameter. `SessionTalks.chatter` passes `Strain.band(maxf(strain of the two))`. In `content/dialogs.yaml`, add two `strain: high` snippets (a complaint about the load, no cause named), two `strain: mid` (shop talk) and two `strain: low` (a joke). Each follows the style guide §2 and §7 and needs no team. In `build_content.py`: `CHATTER_STRAINS = ["low", "mid", "high"]`, and `_validate_passing` accepts the key and checks its value. Add `tests/test_passing_lines.py::test_chatter_strain_is_a_known_band` (the `mutate` pattern of `test_passing_line_errors_are_caught`).
- [ ] **Step 8: Run** `test_strain.gd`, `test_office_day.gd`, `test_people.gd`, `test_office_people.gd` and `test_session.gd`. Expected: PASS, with `test_people.gd`'s count up only by the new round-trip assertions. Then run the full gate.
- [ ] **Step 9: Look at it.** Take `play_shot people_desks --at 18:30` twice: once on a new game, and once with `custom_design` active (the designer save `designer_day045` after `fix_custom_design` is taken). Look at both (Read the PNGs). Who is in at 18:30 and who is slumped must match `strain_of`. The neck clip has no model yet: add PLAN 3.1 sub-task "3.1-A2 build `neck_loop`/`sit_neck_loop` in `tools/blender/pack_character.py` (an edit of the idle like `tired_loop`) on the next character rebuild; Blender is not in this environment". Until then the fallback shows the tired clip.
- [ ] **Step 10: Commit** the files above and `game/data/dialogs.json` with `3.1-A: strain from load, morale and pressure drives late evenings, posture, chatter and absence`.

### Task 2: 3.1-I Wire `agreed_kpis` into the KPI board

**Files:**
- Modify: `game/src/game/session.gd` (`agreed_kpis(pool)`)
- Modify: `game/src/ui/kpi_board_view.gd` (REVIEW mode starts with the agreed magnets and a strip)
- Test: `game/tests/test_kpi_board_view.gd` (extend)

**Interfaces:**
- Produces: `GameSession.agreed_kpis(pool: String) -> Dictionary` returns `{kpis: Array[String], by: String}`. `kpis` holds exactly two distinct ids on `pool`'s menu (`People.agreed_kpis(pool, facts)` filtered through `catalog.kpis`), else `[]`. `by` is the committing person's `short`.
- Produces: `KpiBoardView.AGREED := "Afgesproken met %s"`, shown as a strip on each pre-placed card.
- Consumes: `People.agreed_kpis(team, facts_now)` (exists), `KpiBoardView.create`, `_strip`.

- [ ] **Step 1: Write the failing tests**:
  - `test_review_starts_with_the_kpis_the_team_lead_agreed`. Give `s.people` the outcome `joost_output_kpi = "commitment"` and `agreed["joost_output_kpi"] = "lead_and_oldest"`, then unlock the board with the review due. `KpiBoardView.create(s).picks["work_prep"] == ["work_prep_lead_time", "work_prep_oldest"]`, and the card strip reads `"Afgesproken met Joost"`.
  - `test_a_yes_under_pressure_is_not_preplaced`: the outcome is `compliance`, and picks are `[]`.
  - `test_the_player_can_still_move_the_agreed_magnets`: `pick("work_prep", "work_prep_ftr")` replaces the first.
  - `test_read_mode_shows_what_hangs_not_the_agreement`: between reviews, `picks` equal `board.chosen`.
- [ ] **Step 2: Run** `-- /test_kpi_board_view.gd`. Expected: FAIL on the four new tests.
- [ ] **Step 3: Implement** `GameSession.agreed_kpis`, and in `KpiBoardView.create` (REVIEW mode only) seed `picks[pool]` from it, with the strip on those cards in `_card`.
- [ ] **Step 4: Run** the file and `-- /test_kpi_board.gd`. Expected: PASS, with `test_kpi_board.gd` unchanged. Then the gate.
- [ ] **Step 5: Commit** with `3.1-I: the KPIs a team lead agreed to hang ready on the board at the next review`.

### Task 3: 3.1-G part 1, `CompanyView` and `CompanyLog`

**Files:**
- Create: `game/src/game/company_view.gd` (`class_name CompanyView`, static)
- Create: `game/src/game/company_log.gd` (`class_name CompanyLog`, RefCounted)
- Modify: `game/src/game/session.gd` (`var company_log := CompanyLog.new()`, updated in `_after` after `_sync_people`)
- Modify: `game/src/save/game_save.gd` (save key `"company"`)
- Test: `game/tests/test_company_view.gd` (new)

**Interfaces:**
- Produces, `CompanyView`:
  - `TILES := ["customer", "money", "image", "people"]`, `NAMES := {customer: "Klant & wachtlijst", money: "Geld", image: "Imago & vertrouwen", people: "Mensen"}` and `UNKNOWN := "—"`.
  - `static tiles(s: GameSession) -> Array[Dictionary]`: the four tiles in `TILES` order. Each is `{id, name, headline: {label: String, value: float, text: String}, rows: Array[{label, text}], trend: "better" | "worse" | "flat", spark: Array[float] (≤ 12, oldest first), moved: String}`.
  - `static customer_tile(s) -> Dictionary`. Headline: the median lead time of a new connection in weeks (`connections` `lead_days_p50 / 7`, one decimal; lower is better). Rows: households waiting (the `connections` backlog), firms waiting (the `congestion` backlog), on time against the 18-week norm (`on_time` %), and calls a week (the throughput of `connections.calls_to`'s stream, `customer_contact`). All are measured over `SessionLayer.WINDOW_DAYS`. Below `SessionLayer.MIN_COMPLETED` finished orders, the lead time and on-time rows read `UNKNOWN`.
  - `static money_tile(s) -> Dictionary`. Headline: `region.profile.budget` (higher is better). Rows: savings a week (`region.weekly_savings()`) and owed to the directie (`region.advance_owed`).
  - `static reputation_tile(s) -> Dictionary`. Headline: `region.reputation.value` with the label "bij de directie". One row: "klanttevredenheid", a 0–100 share derived from kept/missed customer appointments and customer-call outcomes since the start (weights are an estimate, documented). Tests: `test_customer_satisfaction_rises_with_kept_appointments`, `test_customer_satisfaction_falls_with_a_broken_promise`, `test_customer_satisfaction_has_no_saved_state` (to_dict/capture keys unchanged). ACM standing is not built (F1).
  - `static people_tile(s) -> Dictionary`. Headline: late evenings last week (the sum of the last five working-day entries of `People.late_log`; lower is better). Rows: the average morale as `PeopleApp.MORALE_BANDS`' word, sick days this month (`sick_days` minus the month's first sample), and left (`People.left` minus everyone whose `leaves_on` beat has passed).
  - `static sample(s) -> Dictionary` returns `{t, month: "YYYY-MM", <tile id>: headline value, raw: {connections: {lead_days_p50, backlog}, congestion: {lead_days_p50, backlog}}, sick_days, late_evenings}`. `raw` is what Task 4's customer condition compares against. A thin stream's `lead_days_p50` is stored as `-1.0` and reads as unknown.
  - The `moved` line: for the customer tile, the resolved problem that holds whose last Check took most lead time out (`st.checked["with"]["lead_time"] − st.checked["without"]["lead_time"]`). Its text is `MOVED_LEAD := "wachttijd %s weken sinds %s"` with a signed whole number and the countermeasure's name. For money, the held fix with the largest weekly saving (`MOVED_SAVING := "%s per week bespaard door %s"`). For image and people, `""` until Tasks 6 and 8 add theirs.
- Produces, `CompanyLog`: `var start: Dictionary` and `var months: Array[Dictionary]` (the last 12 samples). `update(s: GameSession) -> bool` takes the first sample once `not s.missions.in_training()`, and after that one sample per calendar month crossed, from today's numbers only. `first() -> Dictionary`, `to_dict() -> Dictionary`, `load_dict(d: Variant) -> void`. A sample of the wrong shape is dropped. An old save without the key starts the log at its first update.
- Trend rule: compare the headline against `start` with `Pdca.direction`-style better/worse per tile. A change below `SessionLayer.CHANGE_MIN`, or no `start`, reads `"flat"`.

- [ ] **Step 1: Write the failing tests** in `test_company_view.gd`:
  - `test_every_tile_number_equals_the_simulation_s`. On `GameSession.new_game(11, …, false)` after `wait_days(28)`, the customer headline equals `connections.kpis(now, 28)["lead_days_p50"] / 7` (rounded to 0.1), money equals `region.profile.budget`, image equals `region.reputation.value`, and people equals the sum of `people.late_log.slice(-5)`.
  - `test_the_log_samples_once_a_month`. `wait_days(31)` twice gives `months.size() == 2`, and no sample during the training week (`new_game(…, true)` before `training_fri` is done gives `start.is_empty()`).
  - `test_a_skip_over_three_months_adds_one_sample`: `wait_days(91)` adds exactly one sample, with today's numbers.
  - `test_a_thin_stream_reads_as_unknown_not_zero`: a network copy with fewer than `MIN_COMPLETED` finished connections makes the headline text `CompanyView.UNKNOWN`, with trend `"flat"`.
  - `test_trend_is_better_when_lead_time_falls`: a hand-made `start` with a longer lead time gives trend `"better"`.
  - `test_old_save_starts_the_log_at_load`: `GameSave.read` of a save without `"company"` gives `start.is_empty()`, and after one `wait_days(1)` it is filled.
  - `test_reputation_tile_is_the_only_reader_of_reputation`: `image` in `tiles(s)` equals `reputation_tile(s)` (a guard for F1).
- [ ] **Step 2: Run** `-- /test_company_view.gd`. Expected: FAIL (classes not found).
- [ ] **Step 3: Implement** `CompanyView` (the four tile functions, `tiles`, `sample`, the trend rule) and `CompanyLog`. Wire `company_log.update(self)` at the end of `GameSession._after`, and save it under `"company"` in `GameSave.write`/`read`.
- [ ] **Step 4: Run** the file, `-- /test_game_save.gd` and `-- /test_session.gd`. Expected: PASS. Then the gate.
- [ ] **Step 5: Commit** with `3.1-G1: CompanyView reads the four company tiles; CompanyLog samples them monthly`.

### Task 4: 3.1-B Career content and `Career`

**Files:**
- Create: `content/career.yaml`
- Create: `game/src/game/career.gd` (`class_name Career`, RefCounted)
- Modify: `game/src/rules/catalog.gd` (`var career: Dictionary` from `career.json`, optional like `scenes`)
- Modify: `game/src/rules/facts.gd` (`KINDS` gains `"promoted"` and `"career"`; doc comment)
- Modify: `game/src/rules/missions.gd` (`knows`: `"career"` through a callable)
- Modify: `game/src/game/session.gd` (`var career: Career`, wired; `title_of(id)`)
- Modify: `game/src/save/game_save.gd` (save key `"career"`)
- Modify: `tools/build_content.py` (`validate_career`, `check_career`; `FACT_KINDS` gains `"promoted": 1` and `"career": 2`; `VALIDATORS`, `OPTIONAL`)
- Test: `tests/test_career_content.py` (new), `game/tests/test_career.gd` (new)

**Content shape (`content/career.yaml`):**
```yaml
steps:            # the player's ladder, in order; the first is where everyone starts
  - id: ci_lead
    title: CI-lead                # == company.yaml's player title (validated)
    salary: {value: <EUR/month>, estimate: "..."}
  - id: senior_ci_lead
    title: Senior CI-lead
    review: review_senior          # a milestone in missions.yaml
    salary: {...}
    conditions:
      held_fixes: {count: 3, days: 56, estimate: "..."}
      people: {trust: 55, no_pressure_days: 91, estimate: "..."}
      customer: {stream: connections, measure: lead_days_p50, by: 0.10, estimate: "..."}
  - id: manager_cv
    title: Manager Continu Verbeteren
    review: review_manager
    salary: {...}
    reports: [{name: ..., title: ...}, {name: ..., title: ...}]
    conditions: {held_fixes: {count: 6, days: 91}, people: {trust: 60, no_pressure_days: 91}, customer: {..., by: 0.20}}
condition_texts:   # plain Dutch, said in the review and shown in Ik; one per condition id, met and unmet
  held_fixes: {met: "...", unmet: "..."}
  people: {met: "...", unmet: "..."}
  customer: {met: "...", unmet: "..."}
said_about_you: [six lines, index = trust pips 0..5, with {naam}]   # Ik's "wat ze over je zeggen" (Task 9)
colleagues: []     # Task 6
```
The salary values are estimates. The CAO Netbedrijven scales are not on an approved domain, so the reasoning names the level: a regional grid operator's improvement lead, senior specialist and team manager. They sit about EUR 600–800 a month apart, gross, before holiday pay. The `customer` measure is either `lead_days_p50` (lower is better) or `backlog` (lower is better). The two `reports` are new named people, not cast members. That is Claude's call for PLAN §10, and Wie is wie shows them under the player once `promoted:manager_cv` holds (Task 9).

**Interfaces:**
- Produces, `Career`:
  - Constants: `STEPS_KEY := "steps"`, `CONDITIONS := ["held_fixes", "people", "customer"]` and `PROMOTED := "promoted:"`.
  - `var promoted_at: Dictionary[String, int]` (a step id or person id → minutes).
  - `func _init(doc: Dictionary)`.
  - `func step() -> Dictionary` returns the highest step promoted to, else the first.
  - `func next_step() -> Dictionary` returns `{}` at the top.
  - `func conditions(s: GameSession, step_id: String) -> Array[Dictionary]` returns `[{id, met: bool, text: String, have: float, need: float}]` in `CONDITIONS` order. `text` is the `condition_texts` line.
  - `func met(s: GameSession, step_id: String, condition: String) -> bool`.
  - `func promote(id: String, now: int) -> void` records `promoted_at` (idempotent).
  - `func to_dict() -> Dictionary` and `func load_dict(d: Variant) -> Array[String]` (unknown ids dropped and returned).
  - The condition rules:
    - `held_fixes`: the problems that are `RESOLVED`, `holds:` true and `now − st.check_at ≥ days`, counted against `count`.
    - `people`: the persons the player talked with (`talk_log` not empty). Their average `People.trust` must be at least `trust`. Nobody among them, or in their teams, has left except by a `leaves_on` beat. No `talk_log` entry within `no_pressure_days` holds `"pressure"` or `"confront"`.
    - `customer`: `measure` (`lead_days_p50` or `backlog`) of `stream` now (`CompanyView.sample(s)["raw"]`) against `s.company_log.first()["raw"]` has fallen by at least `by`. With no first sample, or `-1.0` on either side, it is not met.
- Produces, `GameSession`: `var career: Career`. `title_of(person_id: String) -> String` returns `career.step()["title"]` for `"player"`, else `Company.title(id, role)`; Task 6 puts a promoted colleague's title in front of the latter. `missions.career_met` is set to `func(step: String, cond: String) -> bool: return career.met(self, step, cond)`.
- Produces, `Missions`: `var career_met: Callable` (default false). `knows("career:<step>:<condition>")` calls it.
- Produces, `build_content.py`:
  - `validate_career(doc, source)`: the shape above; at least two steps; ids match `_ID`; every condition named in `CONDITIONS`; every number with `source` or `estimate`; `condition_texts` has `met` and `unmet` for each condition; six `said_about_you` lines, each containing `{naam}`.
  - `check_career(docs)`: every `review` is a milestone in missions; the first step's title equals company.yaml's `player` title; `customer.stream` is a stream in value_streams.yaml; every `career:<step>:<cond>` atom anywhere names a real step and condition. `_fact_reachable` treats `promoted:<step>` as reachable when its review milestone is reachable.
  - Spoken: the condition texts and `said_about_you` join `spoken_texts`, so `BANNED_SPOKEN` and the developer-word check apply.

- [ ] **Step 1: Write the failing pytest** `tests/test_career_content.py`:
  - `test_the_real_career_builds`
  - `test_first_step_title_is_the_player_s_company_title`
  - `test_every_number_has_a_source_or_estimate` (mutate: drop `estimate` from `held_fixes`, which must give a ContentError)
  - `test_unknown_condition_is_an_error`
  - `test_a_career_atom_must_name_a_real_step`
  - `test_a_banned_word_in_a_condition_text_fails`
- [ ] **Step 2: Run** `python -m pytest tests/test_career_content.py -v`. Expected: FAIL.
- [ ] **Step 3: Write `content/career.yaml`** with three steps, the texts in plain Dutch, and estimates with their reasoning. Implement the validators. Run `python tools/build_content.py`, then the pytest, which must PASS.
- [ ] **Step 4: Write the failing Godot tests** in `game/tests/test_career.gd`:
  - `test_a_new_game_is_a_ci_lead_with_senior_next`
  - `test_held_fixes_count_only_fixes_that_held_long_enough`: two resolved problems that hold with `check_at` 60 days ago, plus one 10 days ago, gives `have == 2.0` and not met for `count: 3`.
  - `test_people_condition_fails_on_a_press_in_the_quarter`: a talk log entry 30 days ago with `"pressure"` gives not met. The same entry 100 days ago gives met.
  - `test_a_retirement_is_not_a_departure`: Henk's beat passed means `people` stays met. A colleague `left` with `ignored` set means not met.
  - `test_customer_condition_reads_the_first_sample`: the first sample's `lead_days_p50` is 70 and now it is 60 (−14 %), which is met for `by: 0.10` and not met for `by: 0.20`.
  - `test_career_atoms_reach_the_facts_grammar`: `s.missions.knows("career:senior_ci_lead:held_fixes") == s.career.met(s, "senior_ci_lead", "held_fixes")`.
  - `test_career_round_trips_and_an_old_save_is_a_ci_lead`
- [ ] **Step 5: Run** `-- /test_career.gd`. Expected: FAIL.
- [ ] **Step 6: Implement** `Career`, the catalog load, `Facts.KINDS`, `Missions.career_met`/`knows`, the `GameSession` wiring and `title_of`, and the `"career"` save key.
- [ ] **Step 7: Run** the file plus `-- /test_facts.gd`, `-- /test_missions.gd` and `-- /test_game_save.gd`. Expected: PASS. Then the gate.
- [ ] **Step 8: Commit** `content/career.yaml`, `game/data/career.json` and the code and tests with `3.1-B: career.yaml (the ladder, three conditions, salary as estimate) and Career reading them from the simulation`.

### Task 5: 3.1-C The review talk

**Files:**
- Modify: `game/src/rules/mission_def.gd` (`recurring` allowed on a milestone)
- Modify: `game/src/rules/missions.gd` (`_open_milestones` reopens a recurring milestone)
- Modify: `game/src/rules/mission_sync.gd` (`reoffer_recurring` covers milestones)
- Modify: `game/src/game/session.gd` (`finish_scene` → `career` review; `scene_of` fills `{volgende_review}`)
- Modify: `content/missions.yaml` (`review_senior`, `review_manager`), `content/scenes.yaml` (the two scenes)
- Modify: `tools/build_content.py` (`_validate_recurring`: a milestone may recur; `SCENE_TOKENS` gains `{volgende_review}`)
- Modify: `game/src/ui/ui_text.gd` (the `promoted` event's toast)
- Test: `game/tests/test_review_talk.gd` (new), `tests/test_milestones_content.py` (extend)

**Interfaces:**
- Consumes: `Career.conditions`, `Career.met`, `Career.promote`, the `career:` atoms (Task 4), `SceneScript.play`, and `OfficeMilestone` (unchanged: it already plays any active scene milestone in its room).
- Produces: `MissionDef.recurring_days` on a milestone. `Missions._open_milestones` opens a milestone with `recurring_days > 0` again once `MissionSync.reoffer_recurring` has erased its progress, whatever `done_once` says. `GameSession.finish_scene(mission_id, answer)` calls `career.after_review(self, mission_id)` after a successful `missions.finish_scene` and before `_after`. `Career.after_review(s: GameSession, mission_id: String) -> String` returns the step promoted to or `""`; it adds the fact `promoted:<step>` and the event `{type: "promoted", step}`.
- Content: `review_senior` is a milestone in act 1 with `requires: {missions: [walk_connections], facts: {none: ["promoted:senior_ci_lead"]}}`, `opens_on: {date: "2027-03-01"}`, `recurring: {every_days: 91}`, `goal: {type: scene}`, `scene: review_senior`, `rewards: {xp: 0}`, a briefing that says what it is (a review, nothing to prepare) and `steps: {go: "Ga naar de MT-kamer op de 2e"}`. `review_manager` is the same with `requires: {missions: [first_kpi_review], facts: {all: ["promoted:senior_ci_lead"], none: ["promoted:manager_cv"]}}` and no `opens_on`. Each scene is in `mt_room`, `present: [ruud, frank]`, `stands: frank`, with these beats:
  - an opening by Ruud;
  - for each condition, one beat when `career:<step>:<cond>` holds and one when it does not (Frank says what he sees, never a number);
  - a closing by Frank with `needs: {all: [the three atoms]}` ("vanaf maandag ben je …");
  - a closing by Ruud when any condition is unmet, built as three beats so exactly one is said: (1) `none: [held_fixes]`; (2) `all: [held_fixes], none: [people]`; (3) `all: [held_fixes, people], none: [customer]`. Each names the next review with `{volgende_review}` (a weekday and date, `MONTH_NAMES`: today plus the milestone's `recurring_days`).

- [ ] **Step 1: Write the failing tests** in `test_review_talk.gd`:
  - `test_review_opens_on_its_date_and_waits_without_a_deadline`
  - `test_all_met_promotes_and_the_title_changes`: force the three conditions through `career_met` and play `finish_scene("review_senior")`. Then `s.missions.knows("promoted:senior_ci_lead")`, `s.career.step()["id"] == "senior_ci_lead"` and `s.title_of("player") == "Senior CI-lead"`.
  - `test_refused_review_names_the_condition_and_comes_back_in_91_days`: with `held_fixes` unmet, `scene_of`'s lines contain the `held_fixes` unmet beat and a date 91 days on, and no closing beat by Frank. After `finish_scene` and `wait_days(91)`, `status("review_senior") == "active"` again.
  - `test_promoted_review_stays_shut`: after a promotion and `wait_days(200)`, `review_senior` is not active.
  - `test_manager_review_needs_the_senior_step_and_act_ii`
  - `test_a_review_pays_no_xp`
- [ ] **Step 2: Run** `-- /test_review_talk.gd`. Expected: FAIL.
- [ ] **Step 3: Implement milestone recurrence** (`MissionDef`, `_open_milestones`, `reoffer_recurring`, `_validate_recurring`). Re-run `-- /test_missions.gd`; its count must be unchanged.
- [ ] **Step 4: Write the content.** Two milestones and two scenes. Every line follows the style guide (je/jij, Frank's and Ruud's voice sheets in §7) and passes `BANNED_SPOKEN`. Run `python tools/build_content.py`. Add to `tests/test_milestones_content.py` `test_a_review_scene_says_every_unmet_condition` (each condition has a met and an unmet beat) and `test_only_milestones_and_sides_recur`.
- [ ] **Step 5: Implement** `Career.after_review`, the `finish_scene` hook, `{volgende_review}` in `scene_of`, and the toast text for `promoted`.
- [ ] **Step 6: Run** the file, `-- /test_milestone_scene.gd`, `-- /test_scene_lines.gd` and the content pytest. Expected: PASS. Then the gate. Take `play_shot` of the MT room in a review (`designer_day095` with `--at 09:00`, after a temporary `opens_on`; do not commit that) and look at it.
- [ ] **Step 7: Commit** with `3.1-C: the review in the MT room reads the three conditions; promotion or a named next date`.

### Task 6: 3.1-D Colleagues step up

**Files:**
- Modify: `content/career.yaml` (`colleagues:`), `content/missions.yaml` (`promotion_anouk`, `promotion_ahmed`), `content/scenes.yaml` (two coffee-corner scenes), `content/dialogs.yaml` (`greetings: anouk/ahmed: promoted:` lines, `_all: promoted:`)
- Modify: `game/src/game/career.gd` (`colleague_promotions`, titles)
- Modify: `game/src/game/session.gd` (run at the dagstart sync; `title_of`; `promoted:<id>` fact)
- Modify: `game/src/game/session_talks.gd` (`greeting_fact` → `"promoted"` for `GREETING_MEMORY_DAYS`; `person()`'s `role` from `title_of`)
- Modify: `game/src/rules/reactions.gd` (`FACTS` gains `"promoted"` first)
- Modify: `game/src/world/office/office_people.gd` (`_name_from` again when the number of promotions changed; names through `title_of`)
- Modify: `game/src/game/company_view.gd` (`people_tile` gains the row "promoted" and the `moved` line "%s is nu %s")
- Modify: `tools/build_content.py` (`validate_career` colleagues, `GREETING_FACTS` gains `promoted`)
- Modify: `game/tools/autoplay.gd` (`record["promoted"]`: the session's `promoted:` facts at the end of a run; one report column)
- Test: `game/tests/test_colleague_promotion.gd` (new), `tests/test_career_content.py` (extend)

**Ruling (spec conflict, see the report):** Joost is the teamleider of Werkvoorbereiding (`company.yaml`), and `skills_matrix_buddy` and `twi_job_instruction` fix `knowledge_drain` (Henk and Ahmed's monteurs), not Anouk's work. So:
- Anouk becomes **senior werkvoorbereider**, once `holds:custom_design` and `standardised:custom_design` both hold and her trust is at least 60.
- Ahmed becomes **monteur en praktijkopleider**, once `holds:knowledge_drain` holds, his trust is at least 60, and any of `chose:knowledge_drain:twi_job_instruction` or `chose:knowledge_drain:skills_matrix_buddy` holds.
- Sanne's path (quality, coached in Act III) is added with `coach_sanne` in 3.3. A trigger now would name a mission that does not exist yet, so the validator would refuse it.
- No desk moves. A new spot needs the office model rebuilt and rebaked (Blender), which is a PLAN sub-task "3.1-D2 the promoted colleague's desk on the next office bake".

**Content shape:** `colleagues: [{id, title, needs: {facts grammar}, trust_at_least: int, estimate: "...", scene: <scene id>}]`. The scenes are `promotion_anouk` in room `connections` (the 1e's coffee corner) and `promotion_ahmed` in `canteen`, each with `present: [ruud, <id>]`. Ruud has two lines and the colleague has one. Cake is in Ruud's first line ("Er staat taart bij de koffie."). Each milestone has `requires: {facts: {all: ["promoted:<id>"]}}`, `goal: scene`, `rewards: {xp: 0}`, and no deadline. Missing the celebration costs nothing; the title has already changed.

**Interfaces:**
- Produces: `Career.colleague_promotions(s: GameSession) -> Array[String]`. It returns the ids promoted now (each once), records `promoted_at[id]`, and GameSession adds `promoted:<id>` plus the event `{type: "promoted", person}`. It is called from `_sync_people` on a day change outside the training week. `Career.title_of(id: String) -> String` returns `""` when the person is not promoted. `GameSession.title_of` checks it first.
- Consumes: `Missions.knows` (needs), `People.trust`, `People.left` (a colleague who left is never promoted).

- [ ] **Step 1: Write the failing tests** in `test_colleague_promotion.gd`:
  - `test_anouk_is_promoted_when_her_fix_holds_and_she_trusts_you`. Set facts and her trust 65, then `wait_days(1)`. `knows("promoted:anouk")`, `title_of("anouk") == "senior werkvoorbereider"`, and the `person("anouk")["role"]` row matches.
  - `test_not_promoted_without_her_trust` (trust 55)
  - `test_not_promoted_while_the_fix_slips`
  - `test_greeting_after_promotion_is_the_promoted_line_for_three_days`
  - `test_the_celebration_waits_at_the_coffee_corner_and_costs_nothing_missed`: the milestone is active. After `wait_days(60)` it is still waiting, and budget and XP are unchanged.
  - `test_the_talker_promotes_anouk_and_never_talks_does_not`. Run `var p := Autoplay.Persona.new("talker", 11)` with `p.stop_day = 150.0` and `p.play()`, and the same for `"never-talks"`. Then `p.s.missions.knows("promoted:anouk")` is true for the talker and false for never-talks, and both records have `dead_ends == []`. This is slow; keep it the file's last test. If never-talks crosses `trust_at_least`, raise the estimate to the talker-only band and record why in its `estimate:`.
- [ ] **Step 2: Run** `-- /test_colleague_promotion.gd`. Expected: FAIL.
- [ ] **Step 3: Write the content** (colleagues, two milestones, two scenes, the greetings). Extend the validators, run `python tools/build_content.py`, and extend `test_career_content.py` with `test_a_colleague_needs_names_known_facts`.
- [ ] **Step 4: Implement** the `Career` and `GameSession` parts, the greeting fact, the name tags following, and the tile row.
- [ ] **Step 5: Run** the file, `-- /test_session_dialogs.gd`, `-- /test_office_people.gd`, `-- /test_company_view.gd` and the content pytest. Expected: PASS. Then the gate. Take `play_shot` at the coffee corner during `promotion_anouk` and look at it.
- [ ] **Step 6: Commit** with `3.1-D: Anouk and Ahmed step up when your fixes developed them; cake at the coffee corner`.

### Task 7: 3.1-E Ruud comments

**Files:**
- Modify: `game/src/rules/coach.gd` (`comment_due`, `comment_said`)
- Modify: `game/src/rules/missions.gd` (saved `comments: {said: {}, due: {}}`; this changes the Missions save keys)
- Modify: `game/src/rules/reactions.gd` (`coach_comment(kind, n)`), `game/src/game/session_talks.gd` (`greet` for `Coach.PERSON`)
- Modify: `game/src/ui/phone/messages.gd` (`COMMENT := "comment:"`; `sync` pushes after `Coach.NOTE_AFTER_DAYS`; `render`)
- Modify: `content/dialogs.yaml` (`coach_comments: {holds: [3], slips: [3], monthly: [3]}`), `tools/build_content.py` (validate: three or more each; only the tokens `{plek}` and `{wie}`; no digit in any line, because Ruud never says the number)
- Test: `game/tests/test_coach_comments.gd` (new), `game/tests/test_missions.gd` (the `test_split_keeps_save_keys` list gains `"comments"`), `tests/test_passing_lines.py`

**Interfaces:**
- Produces, `Coach`:
  - Constants: `PERSON := "ruud"`, `HOLDS_AFTER_DAYS := 7`, `HOLDS_UNTIL_DAYS := 28` and `NOTE_AFTER_DAYS := 3` (estimates: a week to be seen, a month before it is old news, three days unmet).
  - `comment_due(now: int) -> Dictionary` returns `{key, kind: "holds" | "slips", problem, since}` or `{}`. Only the goal problems of main missions in `done_once` count.
    - `holds`: the problem is `RESOLVED`, `holds:` is true, and `now` lies in `[check_at + 7 d, check_at + 28 d]`. The key is `"holds:<problem>:<check_at>"` and `since = check_at + 7 d`.
    - `slips`: the problem is `RESOLVED` and its `health < Sustain.SLIPPING_HEALTH`. The key is `"slips:<problem>:<check_at>"`, and `since` is the first time it was seen due (kept in `comments.due`).
    - The oldest unsaid comment comes first.
  - `comment_said(key: String, now: int) -> void`.
- Produces, `Reactions.coach_comment(kind: String, n: int) -> String`.
- Produces, `SessionTalks.greet(s, person_id)`: for `Coach.PERSON`, a due comment replaces the greeting. The tokens are `{plek}`, the name of the problem step's first pool (`SimPool.name`), and `{wie}`, the `short` name of a person placed at that step whose `strain_of < Strain.LATE_AT`. When a `holds` line needs `{wie}` and nobody there is home on time, the comment waits unsaid: Ruud only says what he could have seen. Once said, `comment_said` is called.
- Produces, `PhoneMessages`: a comment due for `NOTE_AFTER_DAYS` and unsaid is pushed as `"comment:<key>"` with `extra: {text}` (filled when pushed), shown under `NOTE_HEADING`, and marked said.
- Monthly lines are only stored here; Task 8 reads `Reactions.coach_comment("monthly", n)`.
- New Missions save key: `comments`.

- [ ] **Step 1: Write the failing tests** in `test_coach_comments.gd`:
  - `test_a_week_after_a_holding_check_ruud_says_what_he_saw`: a resolved main problem with `check_at` 8 days ago and someone there not late, so `s.greet("ruud")` is a `holds` line with that person's name and no digit.
  - `test_the_comment_waits_while_everyone_there_still_works_late`
  - `test_a_slipping_fix_brings_a_question`: the line ends in `?`.
  - `test_side_mission_fixes_get_no_comment`
  - `test_said_once_and_not_again_after_a_reload` (round trip through `Missions.to_dict`)
  - `test_unmet_for_three_days_it_arrives_as_a_note_from_ruud`: `PhoneMessages.sync` after `wait_days(3)` gives an inbox entry `comment:holds:…` from Ruud, and greeting him afterwards is an ordinary greeting.
- [ ] **Step 2: Run** `-- /test_coach_comments.gd`. Expected: FAIL.
- [ ] **Step 3: Write `coach_comments:`** with three lines per trigger in Ruud's voice (style guide §7: a mentor, few words, a question more than a claim). The two examples in the spec are the tone: "Ik liep langs Werkvoorbereiding. Anouk ging om vijf uur naar huis." becomes "Ik liep langs {plek}. {wie} ging om vijf uur naar huis.", and "Zag je het bord bij {plek} vanmorgen?". Validate them, and add `test_coach_comments_never_hold_a_number` to `tests/test_passing_lines.py`.
- [ ] **Step 4: Implement** `Coach`, the Missions state and save key (update the `test_split_keeps_save_keys` list), `Reactions.coach_comment`, the `greet` branch and the Berichten note.
- [ ] **Step 5: Run** the file, `-- /test_missions.gd`, `-- /test_coach_numbers.gd`, `-- /test_phone.gd` and the content pytest. Expected: PASS. Then the gate.
- [ ] **Step 6: Commit** with `3.1-E: Ruud comments on what he saw a week after a fix holds, asks when one slips` (the commit message names the Missions save key `comments`).

### Task 8: 3.1-F The monthly figures

**Files:**
- Modify: `game/src/rules/mission_def.gd` (`var monthly := false` from `recurring: {monthly: true}`; `static is_first_workday(play_day: int) -> bool` from `PLAY_START`)
- Modify: `game/src/rules/missions.gd` (`_open_milestones`: a monthly milestone opens only on the first working day of the month from 09:00), `game/src/rules/mission_sync.gd` (`lapse_monthly(m)` and the monthly re-offer)
- Modify: `game/src/game/company_view.gd` (`say(s, tile_id) -> String`), `game/src/game/session.gd` (`scene_of` fills `{tegel:<id>}` and `{ruud_maand}`)
- Modify: `content/missions.yaml` (`monthly_figures`), `content/scenes.yaml` (the `monthly_figures` scene, plus a top-level `tile_lines: {customer, money, image, people}`: Frank's spoken template per tile, with the tokens `{waarde}` and `{rij1}` … filled from the tile)
- Modify: `tools/build_content.py` (`_validate_recurring`: `monthly` only on a scene milestone; `SCENE_TOKENS` gains `{tegel:customer|money|image|people}` and `{ruud_maand}`)
- Test: `game/tests/test_monthly_figures.gd` (new)

**Ruling (spec conflict, see the report):** the spec dates this to "the KPI board's birth (day 100)". In the build the KPI board is unlocked by the Obeya countermeasure and first hung at `first_kpi_review`, at the end of Act II, and day 100 is `review_100_days` in the MT room. The figures start with **`done:review_100_days`**, the spec's day, in `directors_obeya` at the board wall (`stand_at: scene:directors_obeya:board`). Frank reads the four company tiles, which are not the teams' KPI cards. So the ritual begins in Act I, as the spec intends.

**Interfaces:**
- Produces: the monthly gate is `MissionDef.is_first_workday(play_day())` and the minute of the day `(region.net.time − play_start) % SimCalendar.MINUTES_PER_DAY >= 9 * 60`. Missions never calls up into `GameSession`.
- Produces: `monthly_figures` is a milestone in act 1 with `requires: {missions: [review_100_days]}`, `recurring: {monthly: true}`, `goal: {type: scene}`, `scene: monthly_figures`, `rewards: {xp: 0}` and `steps: {go: "Loop even langs het bord op de 2e"}`. `MissionSync.lapse_monthly(m: Missions)` closes an active monthly milestone whose opening day has passed, as `{status: "completed", done_at, lapsed: true}`, without `_complete`: no reward, no event, no toast. `reoffer_recurring` erases a monthly milestone's progress once the calendar month of `now` differs from that of `done_at`.
- Produces: `CompanyView.say(s: GameSession, tile_id: String) -> String` is the tile's template from `scenes.yaml` filled with the same numbers `tiles(s)` shows (`CoachNumbers.spoken` style: digits and a decimal comma, read off the board). `{ruud_maand}` is `Reactions.coach_comment("monthly", month index)`.
- Scene: `present: [frank, ruud]` and `stands: frank`. Beats: Frank says four lines, one per tile (`{tegel:…}`); Ruud says one (`{ruud_maand}`); then back to work. It is skippable by holding space (`SceneLines`, unchanged).

- [ ] **Step 1: Write the failing tests** in `test_monthly_figures.gd`:
  - `test_opens_on_the_first_working_day_of_the_month_at_nine`: with `review_100_days` done, on Monday 1 February 2027 at 08:59 it is not active and at 09:00 it is.
  - `test_fires_once_a_month`: playing it, then `wait_days(5)`, leaves it not active, and on 1 March it is active.
  - `test_missing_it_costs_nothing`: let the day pass, and it lapses with XP, budget, reputation and the inbox unchanged and no event.
  - `test_a_skipped_first_workday_opens_next_month`: `wait_days(40)` straight over 1 February lapses February and opens 1 March.
  - `test_frank_says_the_same_numbers_the_app_shows`: for each tile, `scene_of("monthly_figures")`'s Frank line contains the `headline.text` that `CompanyView.tiles(s)` shows.
  - `test_ruud_s_line_has_no_number`
  - `test_not_before_day_100`
- [ ] **Step 2: Run** `-- /test_monthly_figures.gd`. Expected: FAIL.
- [ ] **Step 3: Write the content** (milestone, scene, the four templates), validate it, and run `python tools/build_content.py`.
- [ ] **Step 4: Implement** `is_first_workday`, the monthly gate, `lapse_monthly`, the re-offer, `CompanyView.say` and the scene tokens.
- [ ] **Step 5: Run** the file, `-- /test_missions.gd` (count unchanged except new tests), `-- /test_milestone_scene.gd` and the content pytest. Expected: PASS. Then the gate. Take `play_shot` at the board with `--at 09:00` and look at it.
- [ ] **Step 6: Commit** with `3.1-F: the monthly figures, Frank at the board on the first working day; missing it costs nothing`.

### Task 9: 3.1-G part 2, the Voltana and Ik apps

**Files:**
- Create: `game/src/ui/phone/company_app.gd` (`class_name CompanyApp`, extends `PhoneApp`)
- Create: `game/src/ui/phone/ik_app.gd` (`class_name IkApp`, extends `PhoneApp`)
- Modify: `game/src/ui/phone/phone.gd` (`VOLTANA := "voltana"`, `IK := "ik"` in `APPS` before `CODEX`; `NAMES`; `REVEAL` both `"missions"`; `_make`)
- Modify: `game/src/ui/phone/phone_icon.gd` (two glyphs and colours)
- Modify: `game/src/ui/phone/people_app.gd` (once `promoted:manager_cv` holds, the two `reports` appear under the player's entry)
- Modify: `game/tools/play_shot.gd` (states `phone_voltana` and `phone_ik`)
- Test: `game/tests/test_company_app.gd` (new), `game/tests/test_ik_app.gd` (new), `game/tests/test_phone.gd` (extend)

**Interfaces:**
- Consumes: `CompanyView.tiles(s)`, `s.company_log` (spark), `s.career` (`step`, `next_step`, `conditions`, the salary), `Progression.belt_index` and `belt_progress`, `SessionTalks.person(s, id)["trust_pips"]`, `career.yaml said_about_you`, and `Region.sustain(problem_id)` / `health` / `Sustain.SLIPPING_HEALTH`.
- Produces:
  - `CompanyApp`: four cards. Each shows the headline (`text`), a `▲`/`▼`/`=` mark by `trend` (with colour: better green, worse red; tr'd words in the tooltip), a 12-point sparkline drawn in a `Control._draw`, the rows, and `moved` in muted ink. The title is `"Voltana"`.
  - `IkApp`. The title is `"Ik"`. Its sections:
    1. Job and salary (`step().title`, "± EUR %s bruto per maand", from `salary.value`).
    2. Belt and XP.
    3. "Wat ze over je zeggen": the three people with the most talks, each with their `said_about_you[pips]` line filled with `{naam}`.
    4. "Je verbeteringen": every resolved problem by name, with "houdt" or "zakt weg" by health.
    5. "Naar <next title>": the three conditions with ✓/✗ and their `text`. It reads "Je hebt de hoogste stap bereikt." at the top.
- No HUD change. The old Mensen tab stays in Wie is wie.

- [ ] **Step 1: Write the failing tests**:
  - `test_company_app_shows_the_four_tiles_with_the_view_s_numbers`: each card's headline label text equals `CompanyView.tiles(s)[i].headline.text`.
  - `test_company_app_trend_mark_follows_the_view`
  - `test_ik_shows_the_next_step_s_three_conditions_with_marks`
  - `test_ik_said_about_you_uses_the_pip_band`
  - `test_ik_lists_a_slipping_fix_as_zakt_weg`
  - `test_both_apps_open_from_home_after_tuesday` (in `test_phone.gd`: `may_open(VOLTANA)` follows `"missions"`)
  - `test_manager_reports_appear_in_wie_is_wie_only_after_the_promotion`
- [ ] **Step 2: Run** `-- /test_company_app.gd`, `-- /test_ik_app.gd` and `-- /test_phone.gd`. Expected: FAIL.
- [ ] **Step 3: Implement** both apps (reusing `PhoneApp.scroll_list`, `UiPanel.add_card`, `Palette`, and every string through `tr()`), the phone wiring, the icons, and the Wie is wie rows.
- [ ] **Step 4: Run** the three files and `-- /test_people_app.gd`. Expected: PASS. Then the gate.
- [ ] **Step 5: Look at it.** `play_shot phone_voltana` and `phone_ik` on `designer_day095`; read both screenshots for wrapping on the upright phone (`PhoneApp.wrap_lines`) and for anything that names a cause (spoiler rule).
- [ ] **Step 6: Commit** with `3.1-G2: the Voltana and Ik apps on the phone`.

### Slice 3.1 exit (spec §3)
- Merijn plays `designer_day045` → day 110 and answers "zag ik iemand veranderen door wat ik deed?". 3.1-H waits for his per-talk verdicts.
- Autoplay Acts 0–II with the five personas (`godot --headless --path game --script res://tools/autoplay.gd -- <out dir>`; the report lands in `docs/qa/autoplay-report.md` as before): the talker's colleagues are promoted and never-talks' are not, which Task 6's last test also pins. The report gains a `promoted` row per persona, with each persona's `promoted:` facts at its end, added in Task 6. This is a machine half of the §6 gate.
- `make_designer_saves.py` is regenerated (the content hash changed).
- A code review of the slice; findings are fixed before 3.2 starts.

---

## Deferred: 3.1-H The Acts I–II talk rewrite (task level, waits for Merijn's verdicts)

**Task 3.1-H The Acts I–II talk rewrite** · Files: `docs/superpowers/specs/2026-10-xx-voice-sheets.md` (one sheet per recurring person, written first), `content/dialogs.yaml` (lines only; routes unchanged unless a verdict says "anders in beeld"), the coach's listening question after N ruined tries for `sanne_checker`, `linda_replanning`, `marco_wasted_trips` (`Coach.listening_hint(dialog_id)`, main quest only), `tests/test_dialog_content.py` (the §2.6 limits enforced). Tests: route check ratchet unchanged or tighter; `test_dialog_routes.gd`. Exit: Merijn's verdict table all "houden".
