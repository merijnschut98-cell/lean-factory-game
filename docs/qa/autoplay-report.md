# Autoplay report

Generated 2026-10-18T19:40:44 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, seeds 11, 12, 13). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without (Monday's `anouk_seven`) is had, hello and goodbye, logged as forced. Every other persona also only says hello there. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 0 critical, 6 high, 11 medium, 4 low. Every persona but careless reaches the end of the campaign without a dead end: yes.

## QA verdict (written by the QA agent on 2026-10-18; the rest of this file is generated)

**Builds.** The twelve expert, average, talker and never-talks runs played `ad4b39e` (bot `bd438a4` plus the talk-stage filter). The three careless runs (~25 min each) played the same bot on the rules of `c1c4313`, before the warm-up cache (`2df2809`) set the pull limit before the warm-up instead of after. Their numbers may differ slightly from a run on `ad4b39e`. All 15 persona-seeds ran (careless 12 and 13 for the first time); nothing is missing. Act 0–II is the whole campaign today (27 missions).

**The design's promises, seed by seed (11, 12, 13):**

| promise | holds? | numbers |
|---|---|---|
| The talker ends with more trust than never-talks | **yes**, every seed | mean trust 68.7 vs 50.5 (morale 67.6 vs 50.5) |
| The talker's fixes last longer | **yes**, every seed | life of held fixes 441–443 d vs 293–316 d; slipping + recurred 31–32 vs 47–51; audits needed 31–32 vs 47–51; buy-in 11 commitment / 6 none / 1 compliance vs 0 / 6 / 12 |
| Never-talks completes missions, with more decay | **yes** | campaign done on day 164 every seed, 12 main missions (as the expert: never-talks plays exactly as the expert, whose only talk is Monday's hello); 17 check-in missions for slipping fixes vs 8–9 |
| Careless hits setbacks, never a game over | **yes, but no recovery** | 1–2 bad periods each, the €-50.000 debt floor reached on every seed and held for 65 % of the run; no crash, no state it cannot leave; but the campaign is not finished in three years (52–60 missions, 34–47 of them re-runs of faded fixes), and seed 12 still falls at the horizon |

**Contradictions (each a finding below):**
1. *Decay pays* (medium; never-talks 11/12/13, day 164): never-talks ends with 32–532 XP **more** than the talker (20 526 vs 20 276; 20 858 vs 20 326; 20 358 vs 20 326). The extra comes from twice as many check-in missions (`terugval_`, 100 XP each), which the faster-slipping compliance fixes open. This goes against principle 1, long term over short term.
2. *Neglecting people costs nothing* (medium; never-talks 11/12/13, day 348): trust and morale stay at 50.5 for 348 days and nobody leaves. Morale moves only in talks, and a goodbye needs morale below 20, so a player who never talks loses only fix life, never a person. This goes against principle 2, respect for people.
3. *Careless never recovers* (high, existing findings *treadmill*, *debt spiral*, *debt floor*): setbacks yes, game over no, but no careless run climbs back off the floor.

**Monday (`ends_with_talk`).** Yes, Monday ends with Anouk's talk on every run that plays the training week (12 of 12). The walk meets the goal on day 0.4, the day stays open, and it completes on day 1.4 only after `anouk_seven`. No persona gets stuck there: the talk is always open (a tutorial talk cannot be ruined), and even a bare hello closes the day. One spell-breaker: the talk is had on Monday morning (day 0.4), not at 19:00. The scene clock is not built (PLAN 1.6b, A2).

**Talks (talker).** 52–53 talks per run: 22 commitments, 11–12 partials, 14 lifted check-ins, 5 none. A simple listen-first policy wins every tutorial talk and most persuasions:
- mood first;
- then the listening move that answers the person's last words;
- a proposal that answers the concern once it is out and openness ≥ 70.

It never reaches Femke (`femke_triage`, none ×2) or Ilse (`ilse_queue`, none ×3), so `grid_study_queue` stays compliance even for the talker. Two check-ins with no morale condition (`marco_day_100`, `petra_after`) come back every 14 days after "lifted" for as long as the condition holds (the talker stopped at its cap of 6 each). A prompt cadence with no end may read as nagging.

**Bot fixes in this round:** repair quests (`rework_fix`) are now played (the old bot gave them up as an unknown goal on every run). A repair's A3 takes a different countermeasure once the A3 refuses the old one (`same_countermeasure`). The coach's `talk` stage is no longer reported as a missing mission insight.

**Heads-up:** a builder is changing the place menu (only fitting tools per place, a growing toolbox). The bot calls `use_tool` with any tool at any place, so it may get refusals once that lands. Not chased here.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 164 | 45 | 12 | 20526 | green | € 271.888 | 20/0 | 0 | 0 | 0 | 0 |
| expert | 12 | campaign_done | 164 | 46 | 12 | 20858 | green | € 265.681 | 21/0 | 0 | 0 | 0 | 0 |
| expert | 13 | campaign_done | 164 | 45 | 12 | 20358 | green | € 272.519 | 20/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 438 | 82 | 21 | 21235 | green | € 249.488 | 34/21 | 0 | 28 | 0 | 0 |
| average | 12 | campaign_done | 395 | 80 | 17 | 20185 | green | € 256.342 | 27/16 | 0 | 22 | 0 | 0 |
| average | 13 | campaign_done | 326 | 72 | 15 | 20948 | green | € 225.232 | 28/13 | 0 | 21 | 0 | 1 |
| careless | 11 | horizon | 1096 | 52 | 13 | 10566 | green | € -50.000 | 50/224 | 0 | 46 | 2 | 0 |
| careless | 12 | horizon | 1096 | 60 | 15 | 10848 | green | € -48.500 | 58/236 | 0 | 52 | 1 | 0 |
| careless | 13 | horizon | 1099 | 51 | 15 | 12210 | green | € -50.000 | 48/204 | 0 | 45 | 1 | 0 |
| talker | 11 | campaign_done | 165 | 36 | 12 | 20276 | green | € 277.126 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 12 | campaign_done | 165 | 37 | 12 | 20326 | green | € 273.703 | 20/1 | 0 | 0 | 0 | 0 |
| talker | 13 | campaign_done | 165 | 37 | 12 | 20326 | green | € 278.150 | 20/0 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 164 | 45 | 12 | 20526 | green | € 271.888 | 20/0 | 0 | 0 | 0 | 0 |
| never-talks | 12 | campaign_done | 164 | 46 | 12 | 20858 | green | € 265.681 | 21/0 | 0 | 0 | 0 | 0 |
| never-talks | 13 | campaign_done | 164 | 45 | 12 | 20358 | green | € 272.519 | 20/0 | 0 | 0 | 0 | 0 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 51 | 51 | 0/6/12 | 294 | 7 | € 34.800 | 18/18, 0, 33 |
| expert | 12 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 47 | 47 | 0/6/12 | 316 | 6 | € 34.800 | 18/18, 0, 29 |
| expert | 13 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 51 | 51 | 0/6/12 | 293 | 7 | € 34.800 | 18/18, 0, 33 |
| average | 11 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 13/18 | 29 | 74 | 51 | 0/5/8 | 192 | 7 | € 28.800 | 2/18, 12, 15 |
| average | 12 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 13/18 | 23 | 76 | 59 | 0/6/7 | 185 | 7 | € 46.200 | 2/18, 11, 14 |
| average | 13 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 17/18 | 22 | 64 | 46 | 0/6/11 | 211 | 5 | € 42.738 | 3/18, 14, 14 |
| careless | 11 | 0 (0) | – | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 3/10 | 46 | 46 | 0 | 0/3/0 | 258 | 2 | € -50.000 | – |
| careless | 12 | 0 (0) | – | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 5/10 | 52 | 55 | 0 | 0/2/3 | 202 | 4 | € -50.000 | – |
| careless | 13 | 0 (0) | – | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 1/13 | 45 | 45 | 0 | 0/1/0 | 365 | 4 | € -50.000 | – |
| talker | 11 | 52 (0) | commitment 22, lifted 14, partial 11, none 5 | 50.5→68.7 | 50.5→67.6 | femke 50 | – | 18/18 | 1 | 31 | 31 | 11/6/1 | 443 | 12 | € 34.800 | 18/18, 0, 22 |
| talker | 12 | 53 (0) | commitment 22, lifted 14, partial 12, none 5 | 50.5→68.7 | 50.5→67.6 | femke 50 | – | 18/18 | 1 | 32 | 32 | 11/6/1 | 441 | 11 | € 34.800 | 18/18, 0, 22 |
| talker | 13 | 52 (0) | commitment 22, lifted 14, partial 11, none 5 | 50.5→68.7 | 50.5→67.6 | femke 50 | – | 18/18 | 1 | 32 | 32 | 11/6/1 | 441 | 11 | € 34.800 | 18/18, 0, 22 |
| never-talks | 11 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 51 | 51 | 0/6/12 | 294 | 7 | € 34.800 | 18/18, 0, 33 |
| never-talks | 12 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 47 | 47 | 0/6/12 | 316 | 6 | € 34.800 | 18/18, 0, 29 |
| never-talks | 13 | 1 (1) | none 1 | 50.5→50.5 | 50.5→50.5 | ahmed 42 | – | 18/18 | 1 | 51 | 51 | 0/6/12 | 293 | 7 | € 34.800 | 18/18, 0, 33 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 3 | 45.3 | 0.0 | 164 | € 270.029 | € 34.800 | 50.5 | 50.5 | 0.0 | 18.0/18.0 | 50.7 | 301 | 6.7 | 1.0 |
| average | 3 | 78.0 | 0.0 | 387 | € 243.687 | € 39.246 | 50.5 | 50.5 | 0.0 | 2.3/18.0 | 96.0 | 564 | 6.3 | 1.0 |
| careless | 3 | 54.3 | 0.0 | 1097 | € -49.500 | € -50.000 | 50.5 | 50.5 | 0.0 | 3.0/11.0 | 96.3 | 275 | 3.3 | 0.0 |
| talker | 3 | 36.7 | 0.0 | 165 | € 276.326 | € 34.800 | 68.7 | 67.6 | 0.0 | 18.0/18.0 | 32.7 | 442 | 11.3 | 52.3 |
| never-talks | 3 | 45.3 | 0.0 | 164 | € 270.029 | € 34.800 | 50.5 | 50.5 | 0.0 | 18.0/18.0 | 50.7 | 301 | 6.7 | 1.0 |

Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon).

## Monday's closing talk (`ends_with_talk`)

| persona | seed | mission | talk | had on day | goal met, day held open | completed on day | completed after the talk | outcome |
|---|---|---|---|---|---|---|---|---|
| expert | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| expert | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| expert | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| talker | 11 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| talker | 12 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| talker | 13 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| never-talks | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |

Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.

## Findings (21), ranked by severity

### 1. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 6 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** average/11: 42 of 77 completed missions were re-runs of a faded fix; the campaign took 438 days (campaign_done) against the expert's 164
- **Affects:** average/11: 42/77, average/12: 40/75, average/13: 30/67, careless/11: 39/52, careless/12: 47/60, careless/13: 34/51
- **Reproduce:** persona `average`, seed 11, day 438
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 2. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/12
- **Detail:** careless ends at € -48.500 after 1096 days, still falling about € 294 a month; 1 bad periods
- **Affects:** careless/12
- **Reproduce:** persona `careless`, seed 12, day 1096
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 3. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 130 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm standard_van_stock, predicted on_time +10.8 % (fix), problem KPI on_time +10.8 % (fix), -6.8 % (before/after), capacity +21.7 % (fix), eff 0.72, lesson cause_right
- **Affects:** planning_reshuffle ×17, installer_not_ready ×16, wrong_joint_in_van ×14, custom_design ×14, status_callers ×13, silent_meter ×12, done_but_not_closed ×8, not_at_home ×7, permits_in_batches ×7, inverters_tripping ×6, knowledge_drain ×6, unused_capacity ×5, silo_kpis ×4, digging_damage
- **Reproduce:** persona `expert`, seed 11, mission `fix_wrong_joint`, day 23
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 4. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 48 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm installer_photo_upload, predicted lead_time +5.6 % (fix), problem KPI lead_time +5.6 % (fix), -6.5 % (before/after), capacity +0.0 % (fix), eff 0.45, lesson too_early
- **Affects:** silent_meter ×15, planning_reshuffle ×13, installer_not_ready ×6, wrong_joint_in_van ×6, not_at_home ×4, status_callers, incomplete_application, inverters_tripping, knowledge_drain
- **Reproduce:** persona `average`, seed 11, mission `fix_installer_not_ready`, day 151
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 5. [high] Check passes while the problem's own KPI got worse (prediction named another KPI)

- **Category:** contradiction · **occurrences:** 5 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** cm tap_review_per_neighbourhood, predicted wip_age +41.7 % (fix), problem KPI first_time_right -9.4 % (fix), +100.0 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** planning_reshuffle ×3, inverters_tripping, custom_design
- **Reproduce:** persona `careless`, seed 11, mission `fix_inverters_tripping`, day 214
- **Proposed fix:** Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'.

### 6. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** 52 missions after 1096 days
- **Affects:** horizon ×3
- **Reproduce:** persona `careless`, seed 11, day 1096
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 7. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 7 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** 8 failed Checks on status_callers
- **Affects:** fix_status_callers ×2, fix_wrong_joint ×2, fix_permits_in_batches, fix_planning_reshuffle, fix_digging_damage
- **Reproduce:** persona `careless`, seed 11, mission `fix_status_callers`, day 296
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 8. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 120 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** cm delegated_approval, predicted throughput +2.1 % (fix), problem KPI throughput +2.1 % (fix), -34.9 % (before/after), capacity +6.4 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** silent_meter ×21, planning_reshuffle ×17, wrong_joint_in_van ×15, permits_in_batches ×14, custom_design ×13, installer_not_ready ×11, knowledge_drain ×10, incomplete_application ×8, not_at_home ×5, inverters_tripping ×3, status_callers ×2, done_but_not_closed
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 9. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 52 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm tap_review_per_neighbourhood, predicted first_time_right +10.9 % (fix), problem KPI first_time_right +10.9 % (fix), -15.6 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** status_callers ×23, inverters_tripping ×15, not_at_home ×3, planning_reshuffle ×3, incomplete_application ×3, installer_not_ready ×3, custom_design ×2
- **Reproduce:** persona `expert`, seed 11, mission `fix_inverters_tripping`, day 52
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 10. [medium] Never talking to people costs their morale nothing

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/13
- **Detail:** seed 13, day 348: never-talks' mean morale 50.5 at the start, 50.5 at the end; nobody left; trust 50.5 → 50.5
- **Reproduce:** persona `never-talks`, seed 13, day 348
- **Proposed fix:** Respect for people (principle 2): morale moves only in talks (People.MORALE) and a goodbye needs morale below 20 for 60 days. Let ignored check-in prompts and fixes pushed through without the owner (compliance) cost morale, so neglect shows before anyone leaves.

### 11. [medium] Never-talks earns more XP than the talker: the slips pay

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/13
- **Detail:** seed 13, day 164: XP never-talks 20358, talker 20326; check-in missions (terugval_) done never-talks 17, talker 9
- **Reproduce:** persona `never-talks`, seed 13, day 164
- **Proposed fix:** Principle 1 (long term over short term): a check-in for a slipping fix pays Missions.CHECKIN_XP, so faster decay earns more. Pay the check-in nothing, or pay the fix that held (e.g. a bonus per quarter a fix stayed above SLIPPING_HEALTH).

### 12. [medium] Never talking to people costs their morale nothing

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/12
- **Detail:** seed 12, day 348: never-talks' mean morale 50.5 at the start, 50.5 at the end; nobody left; trust 50.5 → 50.5
- **Reproduce:** persona `never-talks`, seed 12, day 348
- **Proposed fix:** Respect for people (principle 2): morale moves only in talks (People.MORALE) and a goodbye needs morale below 20 for 60 days. Let ignored check-in prompts and fixes pushed through without the owner (compliance) cost morale, so neglect shows before anyone leaves.

### 13. [medium] Never-talks earns more XP than the talker: the slips pay

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/12
- **Detail:** seed 12, day 164: XP never-talks 20858, talker 20326; check-in missions (terugval_) done never-talks 17, talker 9
- **Reproduce:** persona `never-talks`, seed 12, day 164
- **Proposed fix:** Principle 1 (long term over short term): a check-in for a slipping fix pays Missions.CHECKIN_XP, so faster decay earns more. Pay the check-in nothing, or pay the fix that held (e.g. a bonus per quarter a fix stayed above SLIPPING_HEALTH).

### 14. [medium] Never talking to people costs their morale nothing

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/11
- **Detail:** seed 11, day 348: never-talks' mean morale 50.5 at the start, 50.5 at the end; nobody left; trust 50.5 → 50.5
- **Reproduce:** persona `never-talks`, seed 11, day 348
- **Proposed fix:** Respect for people (principle 2): morale moves only in talks (People.MORALE) and a goodbye needs morale below 20 for 60 days. Let ignored check-in prompts and fixes pushed through without the owner (compliance) cost morale, so neglect shows before anyone leaves.

### 15. [medium] Never-talks earns more XP than the talker: the slips pay

- **Category:** promise · **occurrences:** 1 · **seen in:** never-talks/11
- **Detail:** seed 11, day 164: XP never-talks 20526, talker 20276; check-in missions (terugval_) done never-talks 17, talker 8
- **Reproduce:** persona `never-talks`, seed 11, day 164
- **Proposed fix:** Principle 1 (long term over short term): a check-in for a slipping fix pays Missions.CHECKIN_XP, so faster decay earns more. Pay the check-in nothing, or pay the fix that held (e.g. a bonus per quarter a fix stayed above SLIPPING_HEALTH).

### 16. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 76 distinct lines over 459 expert asks; 8 lines reach 5+ missions, e.g. "Wat zie je hier dat de mensen zelf al lang niet meer zien?" in 9 missions. Insights: 153 of 459 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 17. [medium] average play gets lost searching for clues

- **Category:** balance · **occurrences:** 1 · **seen in:** average/13
- **Detail:** after the persona's own search (every tool at the step, four at its two neighbours) the problem was still unspotted or without evidence
- **Affects:** grid_study_queue (16 actions, spotted, 2 clues)
- **Reproduce:** persona `average`, seed 13, mission `look_at_grid_study`, day 110
- **Proposed fix:** Key clues sit at another step or stream than the problem (status_callers: intake/design; grid_study_queue: depth chain). Add a hidden_signal hint or a coach insight that names the place of the first key clue.

### 18. [low] Slow missions for average play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 6 · **seen in:** average/11, average/12
- **Detail:** fix_installer_not_ready took 57 days, 4 Checks, 5 gemba actions
- **Affects:** fix_installer_not_ready (57 d), repair_wrong_joint_in_van (72 d), fix_custom_design (42 d), fix_digging_damage (42 d), repair_wrong_joint_in_van (42 d), fix_silo_kpis (57 d)
- **Reproduce:** persona `average`, seed 11, mission `fix_installer_not_ready`, day 108
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 19. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 6 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 28, average/12: 22, average/13: 21, careless/11: 46, careless/12: 52, careless/13: 45
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 20. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** careless spends 65 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11, careless/12, careless/13
- **Reproduce:** persona `careless`, seed 11, day 127
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 21. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 82 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless |
|---|---|---|---|---|
| training_mon | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_tue | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_wed | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_thu | training | 4.0 (3) | 4.0 (3) | – | 4.0 (3) | 4.0 (3) |
| training_fri | training | 0.0 (3) | 0.0 (3) | – | 0.0 (3) | 0.0 (3) |
| walk_connections | main | 0.1 (3) | 0.1 (3) | – | 0.0 (3) | 0.1 (3) |
| fix_custom_design | main | 14.2 (3) | 23.9 (9) | 60.0 (15) | 14.2 (3) | 14.2 (3) |
| fix_incomplete_application | main | 14.2 (3) | 21.3 (4) | 66.1 (10) | 14.3 (3) | 14.2 (3) |
| fix_installer_not_ready | main | 14.3 (3) | 28.4 (3) | 69.2 (13) | 14.3 (3) | 14.3 (3) |
| fix_status_callers | main | 14.3 (3) | 25.0 (4) | 77.1 (2) | 14.3 (3) | 14.3 (3) |
| fix_done_but_not_closed | main | 14.2 (3) | 19.7 (6) | 70.3 (2) | 14.3 (3) | 14.2 (3) |
| fix_digging_damage | main | 14.3 (3) | 23.6 (6) | 84.3 (1) | 14.2 (3) | 14.3 (3) |
| fix_revision_backlog | main | 14.3 (3) | 21.5 (4) | – | 14.4 (3) | 14.3 (3) |
| fix_grid_study_queue | main | 14.2 (3) | 17.7 (4) | – | 14.2 (3) | 14.2 (3) |
| fix_transformer_wait | main | 14.3 (3) | 18.6 (4) | – | 14.3 (3) | 14.3 (3) |
| fix_unused_capacity | main | 14.3 (3) | 19.8 (3) | – | 14.3 (3) | 14.3 (3) |
| fix_silo_kpis | main | 14.4 (3) | 33.9 (3) | – | 14.4 (3) | 14.4 (3) |
| walk_outages | side | 0.7 (3) | 2.1 (3) | 1.5 (3) | 0.7 (3) | 0.7 (3) |
| walk_meters | side | 1.2 (3) | 1.6 (3) | 1.3 (3) | 1.2 (3) | 1.2 (3) |
| fix_wrong_joint | side | 14.8 (3) | 17.2 (5) | 68.4 (21) | 14.8 (3) | 14.8 (3) |
| fix_not_at_home | side | 14.9 (3) | 22.5 (4) | 72.2 (9) | 14.9 (3) | 14.9 (3) |
| fix_silent_meter | side | 14.3 (3) | 24.0 (3) | 66.3 (24) | 14.3 (3) | 14.3 (3) |
| fix_permits_in_batches | side | 14.2 (3) | 21.9 (4) | 71.1 (18) | 14.2 (3) | 14.2 (3) |
| look_at_grid_study | side | 0.3 (3) | 0.6 (3) | 1.8 (1) | 0.3 (3) | 0.3 (3) |
| fix_inverters_tripping | side | 14.3 (3) | 19.7 (3) | 79.8 (6) | 19.0 (3) | 14.3 (3) |
| save_henks_knowledge | side | 14.3 (3) | 14.5 (3) | 60.4 (7) | 14.3 (3) | 14.3 (3) |
| fix_planning_reshuffle | side | 15.1 (3) | 19.5 (6) | 68.2 (24) | 15.1 (3) | 15.1 (3) |

Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.

## Checks

| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted (fix) | KPI | Δ KPI (fix) | Δ KPI before→after | Δ capacity (fix) | flags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | training_tray | 1 | one_tray_fifo | 0.90 | yes | cause_right | capacity | +10.8 % | capacity | +10.8 % | +10.8 % | +10.8 % |  |
| expert | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | +6.9 % | throughput | +6.9 % | -3.7 % | +26.2 % |  |
| expert | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | +10.8 % | on_time | +10.8 % | -6.8 % | +21.7 % | trend_hides_gain |
| expert | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +33.8 % | first_time_right | +33.8 % | +45.7 % | +4.7 % |  |
| expert | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +16.2 % | first_time_right | +16.2 % | -22.8 % | +8.1 % | trend_hides_gain |
| expert | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +18.4 % | capacity | +18.4 % | +18.4 % | +18.4 % |  |
| expert | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +10.5 % | lead_time | +10.5 % | +4.7 % | +0.0 % |  |
| expert | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +25.0 % | on_time | +25.0 % | +2.4 % | +19.0 % |  |
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +12.8 % | first_time_right | +12.8 % | +8.9 % | +13.1 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +6.1 % | lead_time | +6.1 % | -12.0 % | +1.2 % | trend_hides_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +10.9 % | first_time_right | +10.9 % | -15.6 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| expert | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +6.7 % | on_time | +6.7 % | +5.3 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.4 % | lead_time | +21.4 % | -7.6 % | +0.0 % | trend_hides_gain |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +3.1 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.6 % | capacity | +41.6 % | +41.6 % | +41.6 % |  |
| expert | wrong_joint_in_van | 1 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +23.0 % | on_time | +23.0 % | +6.2 % | +32.3 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +29.0 % | wip_age | +29.0 % | +3.0 % | +0.0 % |  |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +22.2 % | throughput | +22.2 % | +10.0 % | +0.0 % |  |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +14.3 % | first_time_right | +14.3 % | +24.7 % | -3.7 % |  |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | shared_team_goals | 0.00 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | +0.0 % | +0.0 % |  |
| average | not_at_home | 1 | framework_contracts | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -15.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 1 | standard_test_trenches | 0.00 | no | mismatch | capacity | +0.0 % | on_time | +0.0 % | -15.9 % | +0.0 % |  |
| average | custom_design | 2 | delegated_approval | 0.55 | yes | cause_right | throughput | +8.4 % | throughput | +8.4 % | +3.6 % | +14.7 % |  |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +22.0 % | first_time_right | +22.0 % | +0.6 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | wrong_joint_in_van | 2 | standard_van_stock | 0.72 | yes | cause_right | on_time | +11.0 % | on_time | +11.0 % | +7.0 % | +21.7 % |  |
| average | incomplete_application | 1 | shared_team_goals | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | no | not_moved | throughput | +0.4 % | lead_time | +12.5 % | +2.4 % | +0.0 % |  |
| average | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +25.3 % | on_time | +25.3 % | +14.3 % | +19.0 % |  |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | capacity | +10.0 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +14.2 % | lead_time | +14.2 % | -37.3 % | +0.0 % | trend_hides_gain |
| average | silent_meter | 1 | two_hour_window | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -5.5 % | +0.0 % |  |
| average | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | lead_time | +33.3 % | on_time | +5.1 % | -5.5 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | planning_reshuffle | 1 | framework_contracts | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -21.2 % | +0.0 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | throughput | +3.1 % | first_time_right | +12.1 % | +4.3 % | +12.3 % |  |
| average | done_but_not_closed | 1 | obeya_end_to_end | 0.00 | no | mismatch | lead_time | +0.0 % | lead_time | +0.0 % | +100.0 % | +0.0 % |  |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | throughput | +3.4 % | first_time_right | +32.1 % | -100.0 % | +2.8 % | trend_hides_gain |
| average | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +11.4 % | first_time_right | +11.4 % | +0.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.5 % | lead_time | +21.5 % | -6397.2 % | +0.0 % | trend_hides_gain |
| average | installer_not_ready | 1 | use_it_or_lose_it | 0.00 | no | mismatch | throughput | +0.0 % | lead_time | +0.0 % | +14.4 % | +0.0 % |  |
| average | installer_not_ready | 2 | readiness_check | 0.90 | no | not_moved | on_time | -1.2 % | lead_time | +2.8 % | +3.9 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | capacity | +65.6 % | first_time_right | +45.2 % | -60.4 % | +65.6 % | trend_hides_gain |
| average | installer_not_ready | 3 | installer_photo_upload | 0.45 | no | too_early | lead_time | +5.6 % | lead_time | +5.6 % | -6.5 % | +0.0 % | failed_but_kpi_improved |
| average | installer_not_ready | 4 | readiness_check | 0.90 | yes | cause_right | first_time_right | +16.2 % | lead_time | +17.5 % | +14.5 % | +64.3 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +11.7 % | throughput | +11.7 % | -30.8 % | +14.7 % | trend_hides_gain |
| average | wrong_joint_in_van | 2 | tray_labels | 0.00 | no | mismatch | lead_time | +22.7 % | on_time | +12.0 % | +15.3 % | +30.5 % | failed_but_kpi_improved |
| average | planning_reshuffle | 1 | standard_designs | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +7.4 % | +0.0 % |  |
| average | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +23.5 % | lead_time | +23.5 % | -31.9 % | +0.0 % | trend_hides_gain |
| average | wrong_joint_in_van | 3 | tray_labels | 0.00 | no | mismatch | throughput | +0.4 % | on_time | +12.8 % | -10.7 % | +30.5 % |  |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +33.7 % | first_time_right | +33.7 % | -30.2 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | incomplete_application | 1 | intake_checklist | 0.56 | yes | cause_right | capacity | +10.0 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | wrong_joint_in_van | 4 | tray_labels | 0.00 | no | mismatch | lead_time | +22.7 % | on_time | +12.0 % | +0.1 % | +30.5 % | failed_but_kpi_improved |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | wip_age | +4.7 % | throughput | -0.4 % | -7.7 % | +14.7 % |  |
| average | wrong_joint_in_van | 5 | tray_labels | 0.00 | no | mismatch | capacity | +30.5 % | on_time | +14.8 % | +10.4 % | +30.5 % | failed_but_kpi_improved |
| average | digging_damage | 1 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | -7.7 % | +4.7 % | trend_hides_gain |
| average | wrong_joint_in_van | 6 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +16.9 % | on_time | +16.9 % | -0.3 % | +32.2 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | lead_time | +8.7 % | capacity | +19.7 % | +19.7 % | +19.7 % |  |
| average | status_callers | 1 | standard_van_stock | 0.00 | no | mismatch | on_time | +83.0 % | on_time | +83.0 % | +26.7 % | +0.0 % | failed_but_kpi_improved |
| average | custom_design | 1 | delegated_approval | 0.55 | no | not_moved | first_time_right | -16.7 % | throughput | +5.8 % | +58.0 % | +14.7 % |  |
| average | status_callers | 2 | proactive_status_updates | 0.90 | yes | cause_right | wip_age | +13.0 % | on_time | +91.7 % | -23.2 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | custom_design | 2 | standard_designs | 0.90 | no | not_moved | on_time | +0.4 % | throughput | +9.5 % | -32.9 % | +24.9 % |  |
| average | custom_design | 3 | standard_designs | 0.90 | yes | cause_right | throughput | +9.9 % | throughput | +9.9 % | +52.8 % | +21.4 % |  |
| average | digging_damage | 1 | intake_checklist | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | -1.4 % | +0.0 % |  |
| average | digging_damage | 2 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | -1.8 % | +4.7 % |  |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +21.1 % | capacity | +21.1 % | +21.1 % | +21.1 % |  |
| average | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +19.4 % | capacity | +19.4 % | +22.9 % | +19.4 % |  |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +35.5 % | wip_age | +35.5 % | +0.3 % | +0.0 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | +48.3 % | throughput | +48.3 % | +150.0 % | +0.0 % |  |
| average | digging_damage | 1 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | -0.0 % | +4.7 % |  |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +23.3 % | wip_age | +23.3 % | -4.7 % | +0.0 % |  |
| average | silo_kpis | 1 | connections_wip_limit | 0.72 | no | not_moved | first_time_right | -0.4 % | first_time_right | -0.4 % | -4.5 % | -2.7 % |  |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +23.5 % | first_time_right | +23.5 % | +27.7 % | +7.8 % |  |
| average | silo_kpis | 2 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +15.6 % | first_time_right | +15.6 % | -24.7 % | -4.8 % | trend_hides_gain |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 61 of 61 passed; average 89 of 139 passed; careless 156 of 820 passed; talker 60 of 61 passed; never-talks 61 of 61 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| expert | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| expert | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| average | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +10.0 % |
| average | 11 | fix_incomplete_application | fix_installer_not_ready | no | no | -7.1 % |
| average | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | -7.0 % |
| average | 13 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 13 | fix_installer_not_ready | fix_installer_not_ready | no | no | +66.3 % |
| careless | 11 | fix_installer_not_ready | fix_incomplete_application | no | no | +466.5 % |
| careless | 11 | fix_installer_not_ready | fix_installer_not_ready | yes | no | -27.4 % |
| careless | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | -100.0 % |
| careless | 12 | fix_installer_not_ready | fix_installer_not_ready | no | no | -24.3 % |
| careless | 13 | fix_installer_not_ready | fix_incomplete_application | no | no | +21.2 % |
| careless | 13 | fix_installer_not_ready | fix_installer_not_ready | no | no | +83.8 % |
| talker | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| talker | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| talker | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| never-talks | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| never-talks | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| never-talks | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |

The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.

## Coach

| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |
|---|---|---|---|---|
| go_see | 135 | 21 | 45 | "Wat zie je hier dat de mensen zelf al lang niet meer zien?" (9) |
| understand | 108 | 18 | 36 | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" (8) |
| experiment | 108 | 19 | 36 | "Wat doe je als het tegenvalt?" (8) |
| reflect | 108 | 18 | 36 | "Wat zou je anders doen als je opnieuw begon?" (8) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `kpi_review_due()`: `kpi_review(choices)` exists, but nothing says when a review is due and no screen calls it (PLAN 2.4c), so the quarterly review is not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.
- `goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).
