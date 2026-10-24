# Autoplay report

Generated 2026-10-23T22:45:17 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, seeds 11, 12). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 1 critical, 5 high, 4 medium, 8 low. Every persona but careless reaches the end of the campaign without a dead end: yes.

## S2-Q follow-up (2026-10-23): the funding rule, the weekly gemba round, Femke's expert talk

This file's generated part now holds only the follow-up runs, all on the same code:
- expert, average, talker and never-talks on seed 11;
- careless on seeds 11 and 12.

The first S2-Q verdict below compares against slice 1.

**The ruling on (c).** In a bad period the directie pays an experiment only up to what the region has above the floor. A refused A3 gets Ruud's line ("Daar is nu geen geld voor. Wat kun je doen met wat er wel is?"). A small experiment (€ 3 000, an estimate) is always paid, so a player can never be locked out.

| | before the rule | with the rule |
|---|---|---|
| careless 11 | floor first reached day ~150; end € -50 000; 20 % of play at the floor | floor first reached day 212; end € -50 000; 22 % at the floor; 71 A3s refused for money |
| careless 11, best within a year of first reaching the floor | about € -44 000 | € -28 132 |
| careless 12 | end € -48 500; 27 % at the floor | floor first reached day 284; end € -49 592; 23 % at the floor; 87 refused |
| careless 12, best within a year of first reaching the floor | – | € -36 760 |
| expert / average / talker / never-talks 11 | – | never in debt, no A3 refused. Days: expert 177, average 509, talker 164, never-talks 197 (the weekly round takes a side slot again and again) |

**Acceptance, read honestly.**
- Both careless seeds leave the floor within a year of first reaching it. Seed 11 gets € 22 000 above it.
- Neither stays off: careless climbs and falls back.
- The rule stops careless spending money it does not have. It does not stop careless redoing every faded fix (it never standardises) and failing 3 to 8 Checks per problem.
- A lower floor-funding limit was tried (€ 500, test runs not kept): careless got worse. More missions were given up (too many failed Checks), XP fell to 5 600–9 200 and the budget did not climb either.

**The gemba round recurs.**
- `recurring: {every_days: 7}`: XP the first time, after that reputation and trust.
- Seed 11: expert walked it 11 times, average 30, talker 10, never-talks 13.

**`talk_netplanner` is Femke's expert talk** (`femke_expert`, four topics; the goal is two topics heard).

**New finding for the dialog owners.** Careless hits a `talk_never_won` dead end on both seeds: `marco_wasted_trips`, 20 talks, still "heard". It is not caused by content changed here; Marco's talk is unchanged.

## S2-Q verdict: QA 2.12 (c)–(e), the shape test and the slice-2 sides, before and after (2026-10-23; the rest of this file is generated)

**Runs.** Expert, average, talker, never-talks and careless on seed 11; talker and never-talks on 12 and 13; careless on 12 (13 skipped for CPU, about 23 minutes a run). *Before* is the report of `89dc5a4` (slice 1). *After* is this branch merged with S2-M's schema (milestones, `review_100_days`, `winter_el_amrani`): the check-ins that end after their beat, Femke's and Ilse's listening route, the Act II mains' needed talks and the shortcuts (`tests/test_mission_shape.py`), `talk_netplanner`, `lsw_gemba_round`, the way back from the debt floor and the coach's number questions.

| | before (89dc5a4) | after |
|---|---|---|
| expert 11: days, XP | 162, 19 718 | 165, 20 538 |
| average 11: days, XP | 444, 19 955 | 778, 26 076 (it takes the cheapest fitting fix, now often a shortcut: poor fixes, repair quests) |
| talker 11 / 12 / 13: XP | 19 733 / 19 767 / 19 753 | 20 603 / 20 614 / 20 553 |
| never-talks 11 / 12 / 13: XP | 17 549 / 17 893 / 17 742 | 15 539 / 15 931 / 15 532 (the Act II owners' talks pressed to a yes pay half) |
| talker: `marco_day_100` / `petra_after` had (each seed) | 6 / 6 (the persona's cap; the check-in never ended) | 1 / 1 |
| talker: Femke's talk (`femke_triage`) | won on 1 of 3 seeds, on the third try | commitment at the first try on 3 of 3 |
| talker: Ilse's talk (`ilse_queue`) | won on 2 of 3 | won on 2 of 3 (seed 13: heard three times) |
| careless 11: end budget, share of play at the floor | € -49 777, 17 % | € -50 000, 20 % |
| careless 12 | not run | € -48 500, 27 %; Linda leaves |
| dead ends outside careless | average 11: repairs of `wrong_joint_in_van` (8 failed Checks) | the same, nothing new |

**(d) holds.** The arc check-ins end once their concern is heard.

**(e) holds for Femke, partly for Ilse.** The route check (`test_listening_first_wins_femke_and_ilse`, ten deals): Femke 0 → 5 of 10, Ilse 4 → 5 of 10. The route ratchet stays at ≤ 2 and every talk can still be won through its offers.

**(c) is built but the acceptance fails.** The way back opens at the floor and careless takes it: double visits 3–4 times, overtime planning 3–4 times a run. Careless still does not climb. The chain is not too small; careless spends everything:
- From day 400 to 800 careless bought countermeasures worth € 408 000 at list price. Most were random picks from the whole catalogue, 3 to 8 failed Checks per problem.
- Rewards and grants in the same period were about € 180 000.
- At the floor spending is free (the floor clamps it), so every euro the chain brings goes into the next random A3.

A content chain cannot fix that. It needs a rule, which is Merijn's call. One proposal: in a bad period the directie pays an experiment only up to what the region has above the floor ("geen geld voor dit experiment"). Cheap fixes then become the way back. That is what the chain teaches.

**Face, number, choice.** Every tier-1 main now names a person before the numbers, states a claim with a unit, and offers a tempting shortcut with a later cost.

**The coach** reads the KPI (for example "Er komen nu 27,5 per week klaar. Waar wil je naartoe, en waarom juist dat getal?") and asks the Kata five in order during an experiment.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 177 | 54 | 12 | 20761 | green | € 277.725 | 21/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 509 | 129 | 23 | 22869 | green | € 341.831 | 39/19 | 0 | 25 | 0 | 0 |
| careless | 11 | horizon | 1098 | 95 | 8 | 13236 | green | € -50.000 | 55/207 | 0 | 46 | 2 | 31 |
| careless | 12 | horizon | 1100 | 87 | 13 | 12279 | green | € -49.592 | 60/216 | 0 | 52 | 2 | 25 |
| talker | 11 | campaign_done | 164 | 51 | 12 | 20578 | green | € 281.824 | 20/0 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 197 | 68 | 12 | 15589 | green | € 228.973 | 20/2 | 0 | 0 | 0 | 6 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 26 (1) | none 1, commitment 10,  1, heard 10, partial 4 | 50.2→57.6 | 51.9→57.2 | anouk 33 | – | 18/18 | 1 | 33 | 33 | 11/4/3 | 472 | 11 | € 34.800 | 18/18, 0, 21 |
| average | 11 | 36 (1) | none 2, heard 19, commitment 12,  1, partial 2 | 50.2→59.3 | 51.9→54.1 | anouk 31 | – | 18/18 | 26 | 87 | 69 | 11/4/3 | 245 | 11 | € 45.800 | 8/18, 10, 16 |
| careless | 11 | 60 (0) | compliance 4,  1, ruined 24, heard 28, partial 2, commitment 1 | 50.2→45.5 | 51.9→37.3 | dirk 0 | linda (d170), esra (d367) | 2/13 | 50 | 51 | 0 | 0/2/0 | 365 | 5 | € -50.000 | – |
| careless | 12 | 44 (0) | compliance 3,  1, ruined 16, commitment 2, heard 22 | 50.2→48.1 | 51.9→36.3 | dirk 0 | linda (d186) | 2/11 | 55 | 55 | 0 | 0/1/1 | 196 | 5 | € -50.000 | – |
| talker | 11 | 57 (0) | commitment 23,  3, heard 18, partial 9, lifted 3, blocked 1 | 50.2→67.0 | 51.9→68.0 | kees 50 | – | 18/18 | 1 | 34 | 34 | 12/4/2 | 455 | 11 | € 34.800 | 18/18, 0, 23 |
| never-talks | 11 | 30 (1) | none 1, compliance 12,  1, ruined 10, heard 4, commitment 1, partial 1 | 50.2→41.4 | 51.9→41.9 | linda 0 | linda (d225), esra (d324) | 18/18 | 1 | 57 | 57 | 1/4/13 | 280 | 7 | € 34.800 | 18/18, 0, 32 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 1 | 54.0 | 0.0 | 177 | € 277.725 | € 34.800 | 57.6 | 55.9 | 0.0 | 18.0/18.0 | 34.0 | 472 | 11.0 | 26.0 |
| average | 1 | 129.0 | 0.0 | 509 | € 341.831 | € 45.800 | 59.3 | 53.4 | 0.0 | 8.0/18.0 | 113.0 | 384 | 11.0 | 36.0 |
| careless | 2 | 91.0 | 0.0 | 1099 | € -49.796 | € -50.000 | 46.8 | 36.8 | 1.5 | 2.0/12.0 | 105.5 | 280 | 5.0 | 52.0 |
| talker | 1 | 51.0 | 0.0 | 164 | € 281.824 | € 34.800 | 67.0 | 67.2 | 0.0 | 18.0/18.0 | 35.0 | 455 | 11.0 | 57.0 |
| never-talks | 1 | 68.0 | 0.0 | 197 | € 228.973 | € 34.800 | 41.4 | 35.2 | 2.0 | 18.0/18.0 | 58.0 | 287 | 7.0 | 30.0 |

Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon).

## Monday's closing talk (`ends_with_talk`)

| persona | seed | mission | talk | had on day | goal met, day held open | completed on day | completed after the talk | outcome |
|---|---|---|---|---|---|---|---|---|
| expert | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| talker | 11 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| never-talks | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |

Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.

## Findings (18), ranked by severity

### 1. [critical] Dead end: talk_never_won

- **Category:** stuck · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** marco_wasted_trips: 20 talks, still heard
- **Affects:** fix_installer_not_ready, fix_incomplete_application
- **Reproduce:** persona `careless`, seed 11, mission `fix_installer_not_ready`, day 621
- **Proposed fix:** Investigate the detail; it should not happen.

### 2. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 4 · **seen in:** average/11, careless/11, careless/12, never-talks/11
- **Detail:** average/11: 81 of 124 completed missions were re-runs of a faded fix; the campaign took 509 days (campaign_done) against the expert's 177
- **Affects:** average/11: 81/124, careless/11: 74/95, careless/12: 69/87, never-talks/11: 24/63
- **Reproduce:** persona `average`, seed 11, day 509
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 3. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** careless ends at € -50.000 after 1098 days, still falling about € 148 a month; 2 bad periods
- **Affects:** careless/11, careless/12
- **Reproduce:** persona `careless`, seed 11, day 1098
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 4. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 71 · **seen in:** expert/11, average/11, careless/11, careless/12, talker/11, never-talks/11
- **Detail:** cm standard_designs, predicted throughput +8.7 % (fix), problem KPI throughput +8.7 % (fix), -32.3 % (before/after), capacity +26.2 % (fix), eff 0.90, lesson cause_right
- **Affects:** silent_meter ×9, custom_design ×8, not_at_home ×7, installer_not_ready ×7, planning_reshuffle ×7, double_visits ×7, knowledge_drain ×5, overtime_planning ×5, status_callers ×4, permits_in_batches ×3, transformer_wait ×3, done_but_not_closed ×3, silo_kpis ×2, unused_capacity
- **Reproduce:** persona `expert`, seed 11, mission `fix_custom_design`, day 19
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 5. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 21 · **seen in:** average/11, careless/11, careless/12, never-talks/11
- **Detail:** cm planning_with_fault_windows, predicted first_time_right +10.7 % (fix), problem KPI first_time_right +10.7 % (fix), -5.1 % (before/after), capacity +0.0 % (fix), eff 0.42, lesson too_early
- **Affects:** planning_reshuffle ×10, knowledge_drain ×4, wrong_joint_in_van ×2, overtime_planning ×2, done_but_not_closed, silo_kpis, silent_meter
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 49
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 6. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** 95 missions after 1098 days
- **Affects:** horizon ×2
- **Reproduce:** persona `careless`, seed 11, day 1098
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 7. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 9 · **seen in:** careless/11, careless/12
- **Detail:** 8 failed Checks on inverters_tripping
- **Affects:** fix_inverters_tripping ×2, fix_wrong_joint ×2, fix_permits_in_batches ×2, save_henks_knowledge, fix_status_callers, repair_knowledge_drain
- **Reproduce:** persona `careless`, seed 11, mission `fix_inverters_tripping`, day 241
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 8. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 91 · **seen in:** careless/11, careless/12
- **Detail:** cm delegated_approval, predicted capacity +14.7 % (fix), problem KPI throughput +7.5 % (fix), +0.0 % (before/after), capacity +14.7 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** silent_meter ×17, planning_reshuffle ×15, overtime_planning ×12, custom_design ×10, double_visits ×8, incomplete_application ×6, permits_in_batches ×6, knowledge_drain ×5, wrong_joint_in_van ×4, not_at_home ×3, installer_not_ready ×3, status_callers, done_but_not_closed
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 9. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 21 · **seen in:** expert/11, average/11, careless/11, careless/12, talker/11, never-talks/11
- **Detail:** cm readiness_check, predicted lead_time +8.6 % (fix), problem KPI lead_time +8.6 % (fix), -5.1 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** status_callers ×7, inverters_tripping ×5, planning_reshuffle ×3, installer_not_ready ×2, double_visits ×2, not_at_home, custom_design
- **Reproduce:** persona `expert`, seed 11, mission `fix_installer_not_ready`, day 48
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 10. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 102 distinct lines over 153 expert asks; 6 lines reach 5+ missions, e.g. "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" in 11 missions. Insights: 43 of 153 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 11. [low] careless could not press a needed talk to a yes

- **Category:** people · **occurrences:** 56 · **seen in:** careless/11, careless/12
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk marco_wasted_trips: pushed 5 times ×24, talk sanne_checker: pushed 5 times ×19, talk petra_batch: pushed 5 times ×10, talk henk_camera: pushed 5 times ×3
- **Reproduce:** persona `careless`, seed 11, mission `fix_incomplete_application`, day 86
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 12. [low] Slow missions for careless play (over 30 days and twice the median of 42)

- **Category:** balance · **occurrences:** 7 · **seen in:** careless/11, careless/12
- **Detail:** fix_wrong_joint took 84 days, 6 Checks, 3 gemba actions
- **Affects:** fix_wrong_joint (84 d), fix_done_but_not_closed (168 d), fix_permits_in_batches (85 d), fix_incomplete_application (112 d), fix_planning_reshuffle (84 d), fix_custom_design (100 d), fix_not_at_home (85 d)
- **Reproduce:** persona `careless`, seed 11, mission `fix_wrong_joint`, day 1
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 13. [low] never-talks could not press a needed talk to a yes

- **Category:** people · **occurrences:** 6 · **seen in:** never-talks/11
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_kpi: pushed 5 times ×4, talk marco_wasted_trips: pushed 5 times ×2
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_installer_not_ready`, day 57
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 14. [low] Slow missions for average play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 4 · **seen in:** average/11
- **Detail:** fix_planning_reshuffle took 43 days, 3 Checks, 5 gemba actions
- **Affects:** fix_planning_reshuffle (43 d), fix_inverters_tripping (57 d), fix_incomplete_application (42 d), fix_transformer_wait (33 d)
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 21
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 15. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 3 · **seen in:** average/11, careless/11, careless/12
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 25, careless/11: 46, careless/12: 52
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 16. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** careless spends 54 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11, careless/12
- **Reproduce:** persona `careless`, seed 11, day 198
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 17. [low] Slow missions for never-talks play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 1 · **seen in:** never-talks/11
- **Detail:** fix_silo_kpis took 39 days, 2 Checks, 6 gemba actions
- **Affects:** fix_silo_kpis (39 d)
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_silo_kpis`, day 158
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 18. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 92 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless |
|---|---|---|---|---|
| training_mon | training | 1.0 (1) | 1.0 (1) | – | 1.0 (1) | 1.0 (1) |
| training_tue | training | 1.0 (1) | 1.0 (1) | – | 1.0 (1) | 1.0 (1) |
| training_wed | training | 1.0 (1) | 1.0 (1) | – | 1.0 (1) | 1.0 (1) |
| training_thu | training | 1.3 (1) | 1.4 (1) | – | 1.3 (1) | 1.3 (1) |
| training_fri | training | 0.0 (1) | 0.0 (1) | – | 0.0 (1) | 0.0 (1) |
| walk_connections | main | 0.0 (1) | 0.0 (1) | – | 0.1 (1) | 0.0 (1) |
| fix_custom_design | main | 14.3 (1) | 19.0 (3) | 66.1 (10) | 14.2 (1) | 14.3 (1) |
| fix_incomplete_application | main | 14.2 (1) | 35.2 (2) | 80.0 (3) | 14.3 (1) | 14.2 (1) |
| fix_installer_not_ready | main | 14.3 (1) | 23.6 (3) | 47.2 (6) | 14.3 (1) | 25.2 (1) |
| fix_status_callers | main | 14.2 (1) | 14.3 (1) | 70.2 (1) | 14.3 (1) | 14.3 (1) |
| fix_done_but_not_closed | main | 14.3 (1) | 14.2 (2) | 167.8 (1) | 14.3 (1) | 14.3 (1) |
| winter_el_amrani | milestone | 0.0 (1) | 0.0 (1) | 0.0 (2) | 0.0 (1) | 0.0 (1) |
| review_100_days | milestone | 0.3 (1) | 0.0 (1) | 0.1 (2) | 0.3 (1) | 0.4 (1) |
| fix_digging_damage | main | 14.2 (1) | 28.3 (1) | – | 14.2 (1) | 14.2 (1) |
| fix_revision_backlog | main | 14.3 (1) | 14.2 (2) | – | 14.3 (1) | 14.3 (1) |
| fix_grid_study_queue | main | 14.3 (1) | 14.2 (3) | – | 14.3 (1) | 14.4 (1) |
| fix_transformer_wait | main | 15.4 (1) | 20.6 (3) | – | 16.4 (1) | 14.2 (1) |
| fix_unused_capacity | main | 14.3 (1) | 14.6 (1) | – | 14.3 (1) | 14.3 (1) |
| fix_silo_kpis | main | 14.4 (1) | 16.4 (1) | – | 14.5 (1) | 39.0 (1) |
| walk_outages | side | 0.7 (1) | 0.7 (1) | 1.4 (2) | 0.7 (1) | 0.6 (1) |
| walk_meters | side | 0.9 (1) | 0.7 (1) | 1.4 (2) | 1.0 (1) | 0.9 (1) |
| fix_wrong_joint | side | 14.6 (1) | 14.6 (2) | 63.6 (4) | 14.6 (1) | 14.6 (1) |
| fix_not_at_home | side | 14.9 (1) | 21.8 (2) | 63.5 (6) | 14.9 (1) | 14.9 (1) |
| fix_silent_meter | side | 14.3 (1) | 21.2 (2) | 52.3 (21) | 14.3 (1) | 14.3 (1) |
| fix_permits_in_batches | side | 14.2 (1) | 28.3 (1) | 72.7 (6) | 14.2 (1) | 14.2 (1) |
| look_at_grid_study | side | 0.5 (1) | 0.8 (1) | 0.8 (1) | 0.5 (1) | 0.4 (1) |
| fix_inverters_tripping | side | 14.3 (1) | 36.0 (2) | – | 14.4 (1) | 14.3 (1) |
| save_henks_knowledge | side | 14.3 (1) | 14.3 (1) | 65.7 (3) | 14.3 (1) | 14.3 (1) |
| fix_planning_reshuffle | side | 14.8 (1) | 42.5 (1) | 61.7 (18) | 14.9 (1) | 14.8 (1) |
| talk_netplanner | side | 0.3 (1) | 0.5 (1) | 1.1 (2) | 0.0 (1) | 0.3 (1) |
| lsw_gemba_round | side | 0.3 (11) | 0.3 (30) | 0.2 (63) | 0.3 (10) | 0.2 (13) |
| fix_double_visits | side | – | – | 56.4 (11) | – | – |
| fix_overtime_planning | side | – | – | 39.9 (12) | – | – |

Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.

## Checks

| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted (fix) | KPI | Δ KPI (fix) | Δ KPI before→after | Δ capacity (fix) | flags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | training_tray | 1 | one_tray_fifo | 0.90 | yes | cause_right | capacity | +10.8 % | capacity | +10.8 % | +10.8 % | +10.8 % |  |
| expert | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | +8.7 % | throughput | +8.7 % | -32.3 % | +26.2 % | trend_hides_gain |
| expert | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | +10.5 % | on_time | +10.5 % | -3.4 % | +21.7 % |  |
| expert | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +42.8 % | first_time_right | +42.8 % | +47.5 % | +4.7 % |  |
| expert | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +15.3 % | first_time_right | +15.3 % | -11.1 % | +8.1 % | trend_hides_gain |
| expert | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +18.4 % | capacity | +18.4 % | +18.4 % | +18.4 % |  |
| expert | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +14.3 % | lead_time | +14.3 % | +14.2 % | +0.0 % |  |
| expert | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +26.3 % | on_time | +26.3 % | -7.2 % | +19.2 % | trend_hides_gain |
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +10.2 % | first_time_right | +10.2 % | -0.3 % | +13.7 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +8.6 % | lead_time | +8.6 % | -5.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +18.1 % | first_time_right | +18.1 % | +3.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +5.6 % | on_time | +5.6 % | +7.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.4 % | lead_time | +21.4 % | -0.1 % | +0.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +2.4 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | wrong_joint_in_van | 1 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +19.1 % | on_time | +19.1 % | -0.2 % | +32.3 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.9 % | capacity | +41.9 % | +41.9 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +26.7 % | wip_age | +26.7 % | -0.0 % | +0.0 % |  |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +14.3 % | throughput | +14.3 % | -33.3 % | +0.0 % | trend_hides_gain |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +14.2 % | first_time_right | +14.2 % | -0.9 % | -3.8 % |  |
| expert | status_callers | 1 | proactive_status_updates | 0.90 | yes | cause_right | on_time | +29.0 % | on_time | +29.0 % | -38.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +6.8 % | throughput | +6.8 % | -23.1 % | +14.7 % | trend_hides_gain |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +20.4 % | first_time_right | +20.4 % | -10.5 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | lead_time | +18.2 % | on_time | +10.4 % | -3.4 % | +21.7 % |  |
| average | installer_not_ready | 1 | backup_job_per_day | 0.54 | yes | cause_right | first_time_right | +7.4 % | lead_time | +6.2 % | +11.6 % | +0.0 % |  |
| average | permits_in_batches | 1 | cupboard_photo_at_booking | 0.00 | no | mismatch | capacity | +0.0 % | lead_time | +0.0 % | +11.6 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | no | not_moved | on_time | +1.9 % | first_time_right | +49.7 % | -14.2 % | +0.0 % |  |
| average | incomplete_application | 1 | connections_wip_limit | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +13.3 % | lead_time | +13.3 % | -8.8 % | +0.0 % | trend_hides_gain |
| average | planning_reshuffle | 2 | planning_with_fault_windows | 0.42 | no | too_early | first_time_right | +10.7 % | first_time_right | +10.7 % | -5.1 % | +0.0 % | failed_but_kpi_improved |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | capacity | +10.0 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | lead_time | +8.6 % | first_time_right | +14.8 % | -13.9 % | +12.3 % | trend_hides_gain |
| average | planning_reshuffle | 3 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +44.2 % | first_time_right | +44.2 % | -23.6 % | +0.0 % | trend_hides_gain |
| average | custom_design | 1 | obeya_end_to_end | 0.00 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | +22.2 % | +0.0 % |  |
| average | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | first_time_right | +59.2 % | on_time | +24.6 % | -10.5 % | +18.9 % | trend_hides_gain |
| average | inverters_tripping | 1 | area_teams | 0.00 | no | mismatch | wip_age | +0.0 % | first_time_right | +0.0 % | +33.3 % | +0.0 % |  |
| average | custom_design | 2 | delegated_approval | 0.55 | yes | cause_right | wip_age | +6.9 % | throughput | +1.9 % | -3.6 % | +14.7 % |  |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | +11.8 % | on_time | +11.8 % | +4.5 % | +21.9 % |  |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | no | not_moved | throughput | -54.3 % | first_time_right | +16.0 % | -23.8 % | +12.9 % |  |
| average | installer_not_ready | 1 | poka_yoke_application | 0.00 | no | mismatch | lead_time | +0.0 % | lead_time | +0.0 % | -10.5 % | +0.0 % |  |
| average | silent_meter | 1 | early_transformer_order | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -6.6 % | +0.0 % |  |
| average | inverters_tripping | 3 | smart_meter_voltage_data | 0.40 | no | too_early | first_time_right | -0.7 % | first_time_right | -0.7 % | +8.7 % | +5.7 % |  |
| average | installer_not_ready | 2 | backup_job_per_day | 0.54 | yes | cause_right | lead_time | +2.1 % | lead_time | +2.1 % | +5.6 % | +2.2 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +20.8 % | first_time_right | +20.8 % | -12.9 % | +12.3 % | trend_hides_gain |
| average | inverters_tripping | 4 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +20.6 % | first_time_right | +20.6 % | +12.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +2.8 % | on_time | +2.8 % | +29.1 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | yes | cause_right | lead_time | +13.2 % | lead_time | +13.2 % | +0.5 % | +0.0 % |  |
| average | digging_damage | 1 | work_instruction_videos | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.5 % | +0.0 % |  |
| average | digging_damage | 2 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | +2.8 % | +4.7 % |  |
| average | installer_not_ready | 1 | backup_job_per_day | 0.54 | no | not_moved | capacity | +0.0 % | lead_time | +8.0 % | -16.6 % | +0.0 % |  |
| average | installer_not_ready | 2 | readiness_check | 0.90 | yes | cause_right | throughput | +3.4 % | lead_time | +7.3 % | -5.8 % | +0.0 % | trend_hides_gain |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.1 % | capacity | +21.1 % | +21.1 % | +21.1 % |  |
| average | status_callers | 1 | proactive_status_updates | 0.50 | yes | cause_right | on_time | +42.0 % | on_time | +42.0 % | -17.0 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +38.3 % | capacity | +38.3 % | +38.3 % | +38.3 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | no | not_moved | on_time | -0.9 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | incomplete_application | 2 | poka_yoke_application | 0.90 | no | not_moved | on_time | -0.7 % | capacity | +11.1 % | +11.1 % | +11.1 % |  |
| average | incomplete_application | 3 | poka_yoke_application | 0.90 | yes | cause_right | lead_time | +12.5 % | capacity | +13.4 % | +13.1 % | +13.4 % |  |
| average | transformer_wait | 1 | standard_test_trenches | 0.00 | no | mismatch | first_time_right | +0.0 % | wip_age | +0.0 % | -2.0 % | +0.0 % |  |
| average | transformer_wait | 2 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +29.1 % | wip_age | +29.1 % | -7.6 % | +0.0 % | trend_hides_gain |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +42.0 % | capacity | +42.0 % | +42.0 % | +42.0 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | +25.0 % | throughput | +25.0 % | +0.0 % | +0.0 % |  |
| average | silo_kpis | 1 | connections_wip_limit | 0.72 | yes | cause_right | first_time_right | +9.0 % | first_time_right | +9.0 % | +18.5 % | +0.0 % |  |
| average | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +10.8 % | first_time_right | +10.8 % | +20.8 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | custom_design | 2 | standard_designs | 0.90 | yes | cause_right | throughput | +13.1 % | throughput | +13.1 % | +26.8 % | +21.5 % |  |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | yes | cause_right | throughput | +22.7 % | lead_time | +19.3 % | -16.1 % | +0.0 % | trend_hides_gain |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +13.0 % | wip_age | +13.0 % | +3.3 % | +0.0 % |  |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +52.0 % | capacity | +52.0 % | +15.2 % | +52.0 % |  |
| average | not_at_home | 1 | triage_fast_lane | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -4.2 % | +0.0 % |  |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +18.5 % | first_time_right | +18.5 % | -0.5 % | +7.9 % |  |
| average | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | +12.0 % | throughput | +12.0 % | -13.6 % | +29.0 % | trend_hides_gain |
| average | done_but_not_closed | 1 | daytime_outage_crew | 0.00 | no | mismatch | lead_time | +31.9 % | lead_time | +31.9 % | +11.0 % | +0.0 % | failed_but_kpi_improved |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | throughput | +6.9 % | wip_age | +36.6 % | -7.1 % | +0.0 % | trend_hides_gain |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +25.1 % | lead_time | +25.1 % | +1.9 % | +0.0 % |  |
| average | silo_kpis | 1 | standard_designs | 0.00 | no | mismatch | first_time_right | +14.0 % | first_time_right | +14.0 % | -19.1 % | -4.5 % | failed_but_kpi_improved |
| average | silo_kpis | 2 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +39.0 % | first_time_right | +39.0 % | +1.9 % | -3.9 % |  |
| average | wrong_joint_in_van | 1 | capacity_usage_dashboard | 0.00 | no | mismatch | lead_time | +22.7 % | on_time | +16.5 % | +12.6 % | +31.5 % | failed_but_kpi_improved |
| average | wrong_joint_in_van | 2 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +14.4 % | on_time | +14.4 % | +0.9 % | +32.3 % |  |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 21 of 21 passed; average 39 of 58 passed; careless 115 of 538 passed; talker 20 of 20 passed; never-talks 20 of 22 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| average | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| careless | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| careless | 11 | fix_incomplete_application | fix_installer_not_ready | no | no | -54.5 % |
| careless | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +6.4 % |
| careless | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +38.2 % |
| talker | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| never-talks | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |

The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.

## Coach

| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |
|---|---|---|---|---|
| go_see | 45 | 32 | 15 | "Als je over een jaar terugkijkt, welk getal wil je dan veranderd hebben?" (7) |
| understand | 36 | 18 | 12 | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" (8) |
| experiment | 29 | 19 | 5 | "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" (11) |
| reflect | 35 | 29 | 11 | "Wat is de volgende kleine stap?" (6) |
| talk | 8 | 4 | 0 | "Wiens idee was het uiteindelijk?" (5) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `kpi_review_due()`: `kpi_review(choices)` exists, but nothing says when a review is due and no screen calls it (PLAN 2.4c), so the quarterly review is not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.
- `goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).
