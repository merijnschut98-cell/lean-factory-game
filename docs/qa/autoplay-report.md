# Autoplay report

Generated 2026-10-23T21:05:27 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, seeds 11, 12, 13). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 0 critical, 5 high, 4 medium, 7 low. Every persona but careless reaches the end of the campaign without a dead end: no.

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
| expert | 11 | campaign_done | 165 | 42 | 12 | 20538 | green | € 280.613 | 20/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 778 | 121 | 28 | 26076 | green | € 321.653 | 55/47 | 0 | 36 | 0 | 0 |
| careless | 11 | horizon | 1098 | 62 | 11 | 15068 | green | € -50.000 | 60/231 | 0 | 48 | 2 | 33 |
| careless | 12 | horizon | 1097 | 68 | 13 | 13050 | green | € -48.500 | 62/241 | 0 | 55 | 1 | 12 |
| talker | 11 | campaign_done | 164 | 43 | 12 | 20603 | green | € 281.719 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 12 | campaign_done | 180 | 44 | 12 | 20614 | green | € 289.584 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 13 | campaign_done | 165 | 40 | 12 | 20553 | green | € 281.494 | 20/0 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 180 | 50 | 12 | 15539 | green | € 225.530 | 20/1 | 0 | 0 | 0 | 4 |
| never-talks | 12 | campaign_done | 197 | 57 | 12 | 15931 | green | € 220.797 | 21/1 | 0 | 0 | 0 | 7 |
| never-talks | 13 | campaign_done | 186 | 53 | 12 | 15532 | green | € 226.657 | 20/0 | 0 | 0 | 0 | 10 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 25 (1) | none 1, commitment 10, heard 10, partial 4 | 50.2→57.4 | 51.9→57.2 | anouk 35 | – | 18/18 | 1 | 34 | 34 | 11/4/3 | 426 | 11 | € 34.800 | 18/18, 0, 23 |
| average | 11 | 38 (1) | none 1, heard 23, commitment 11, partial 3 | 50.2→59.0 | 51.9→52.4 | femke 29 | – | 18/18 | 37 | 111 | 84 | 11/4/3 | 338 | 12 | € 45.800 | 12/18, 6, 23 |
| careless | 11 | 63 (0) | compliance 5, ruined 25, heard 28, partial 4, commitment 1 | 50.2→43.9 | 51.9→30.4 | dirk 0 | linda (d184), esra (d507) | 4/16 | 53 | 55 | 0 | 1/3/0 | 212 | 3 | € -50.000 | – |
| careless | 12 | 27 (0) | compliance 5, ruined 10, heard 10, partial 2 | 50.2→46.6 | 51.9→32.4 | dirk 0 | linda (d170) | 2/12 | 55 | 56 | 0 | 1/1/0 | 411 | 3 | € -50.000 | – |
| talker | 11 | 57 (0) | commitment 23, heard 19, partial 10, lifted 3, blocked 2 | 50.2→67.0 | 51.9→68.3 | kees 50 | – | 18/18 | 1 | 35 | 35 | 12/4/2 | 455 | 11 | € 34.800 | 18/18, 0, 23 |
| talker | 12 | 57 (0) | heard 23, commitment 21, partial 9, none 1, lifted 3 | 50.2→66.4 | 51.9→68.3 | kees 50 | – | 18/18 | 1 | 34 | 34 | 13/4/1 | 456 | 11 | € 34.800 | 18/18, 0, 21 |
| talker | 13 | 61 (0) | commitment 24, heard 26, partial 7, lifted 3, blocked 1 | 50.2→67.8 | 51.9→69.7 | kees 50 | – | 18/18 | 1 | 29 | 29 | 14/4/0 | 459 | 11 | € 34.800 | 18/18, 0, 20 |
| never-talks | 11 | 27 (1) | none 1, compliance 12, ruined 10, heard 2, commitment 1, partial 1 | 50.2→41.0 | 51.9→42.2 | linda 4 | linda (d222), esra (d307) | 18/18 | 1 | 52 | 52 | 1/4/13 | 280 | 7 | € 34.800 | 18/18, 0, 33 |
| never-talks | 12 | 30 (1) | none 1, compliance 12, ruined 11, heard 4, commitment 1, partial 1 | 50.2→41.0 | 51.9→41.8 | linda 0 | linda (d225), esra (d324) | 18/18 | 1 | 54 | 54 | 1/4/13 | 302 | 6 | € 34.800 | 18/18, 0, 29 |
| never-talks | 13 | 33 (1) | none 1, compliance 12, ruined 10, heard 8, partial 2 | 50.2→41.6 | 51.9→42.4 | linda 3 | linda (d221), esra (d313) | 18/18 | 1 | 54 | 54 | 1/4/13 | 280 | 6 | € 34.800 | 18/18, 0, 32 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 1 | 42.0 | 0.0 | 165 | € 280.613 | € 34.800 | 57.4 | 55.9 | 0.0 | 18.0/18.0 | 35.0 | 426 | 11.0 | 25.0 |
| average | 1 | 121.0 | 0.0 | 778 | € 321.653 | € 45.800 | 59.0 | 51.4 | 0.0 | 12.0/18.0 | 148.0 | 468 | 12.0 | 38.0 |
| careless | 2 | 65.0 | 0.0 | 1097 | € -49.250 | € -50.000 | 45.2 | 31.4 | 1.5 | 3.0/14.0 | 109.5 | 311 | 3.0 | 45.0 |
| talker | 3 | 42.3 | 0.0 | 170 | € 284.266 | € 34.800 | 67.0 | 68.0 | 0.0 | 18.0/18.0 | 33.7 | 457 | 11.0 | 58.3 |
| never-talks | 3 | 53.3 | 0.0 | 188 | € 224.328 | € 34.800 | 41.2 | 35.3 | 2.0 | 18.0/18.0 | 54.3 | 299 | 6.3 | 30.0 |

Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon).

## Monday's closing talk (`ends_with_talk`)

| persona | seed | mission | talk | had on day | goal met, day held open | completed on day | completed after the talk | outcome |
|---|---|---|---|---|---|---|---|---|
| expert | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| talker | 11 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| talker | 12 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | heard |
| talker | 13 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| never-talks | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |

Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.

## Findings (16), ranked by severity

### 1. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 3 · **seen in:** average/11, careless/11, careless/12
- **Detail:** average/11: 73 of 116 completed missions were re-runs of a faded fix; the campaign took 778 days (campaign_done) against the expert's 165
- **Affects:** average/11: 73/116, careless/11: 37/62, careless/12: 47/68
- **Reproduce:** persona `average`, seed 11, day 778
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 2. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/12
- **Detail:** careless ends at € -48.500 after 1097 days, still falling about € 723 a month; 1 bad periods
- **Affects:** careless/12
- **Reproduce:** persona `careless`, seed 12, day 1097
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 3. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 95 · **seen in:** expert/11, average/11, careless/11, careless/12, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm standard_designs, predicted throughput +8.7 % (fix), problem KPI throughput +8.7 % (fix), -32.3 % (before/after), capacity +26.2 % (fix), eff 0.90, lesson cause_right
- **Affects:** planning_reshuffle ×17, custom_design ×12, done_but_not_closed ×9, silent_meter ×8, not_at_home ×7, installer_not_ready ×7, status_callers ×7, permits_in_batches ×6, wrong_joint_in_van ×6, knowledge_drain ×4, unused_capacity ×4, overtime_planning ×3, silo_kpis ×2, double_visits ×2 …
- **Reproduce:** persona `expert`, seed 11, mission `fix_custom_design`, day 19
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 4. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 33 · **seen in:** average/11, careless/11, careless/12, never-talks/11
- **Detail:** cm planning_with_fault_windows, predicted first_time_right +58.0 % (fix), problem KPI first_time_right +58.0 % (fix), -10.0 % (before/after), capacity +0.0 % (fix), eff 0.42, lesson too_early
- **Affects:** planning_reshuffle ×11, wrong_joint_in_van ×5, silent_meter ×4, inverters_tripping ×4, not_at_home ×3, knowledge_drain ×2, installer_not_ready ×2, done_but_not_closed, double_visits
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 49
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 5. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** 62 missions after 1098 days
- **Affects:** horizon ×2
- **Reproduce:** persona `careless`, seed 11, day 1098
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 6. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 6 · **seen in:** average/11, careless/11, careless/12
- **Detail:** 8 failed Checks on wrong_joint_in_van
- **Affects:** fix_inverters_tripping ×2, repair_wrong_joint_in_van, fix_permits_in_batches, fix_wrong_joint, fix_status_callers
- **Reproduce:** persona `average`, seed 11, mission `repair_wrong_joint_in_van`, day 260
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 7. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 105 · **seen in:** careless/11, careless/12
- **Detail:** cm delegated_approval, predicted capacity +14.7 % (fix), problem KPI throughput +10.1 % (fix), -4.3 % (before/after), capacity +14.7 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** planning_reshuffle ×15, silent_meter ×14, permits_in_batches ×13, wrong_joint_in_van ×11, knowledge_drain ×8, double_visits ×7, custom_design ×6, installer_not_ready ×6, overtime_planning ×6, not_at_home ×5, incomplete_application ×4, inverters_tripping ×4, done_but_not_closed ×2, revision_backlog ×2 …
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 8. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 33 · **seen in:** expert/11, average/11, careless/11, careless/12, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm readiness_check, predicted lead_time +11.9 % (fix), problem KPI lead_time +11.9 % (fix), -5.1 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** status_callers ×13, inverters_tripping ×8, installer_not_ready ×4, planning_reshuffle ×3, not_at_home ×2, double_visits, revision_backlog, incomplete_application
- **Reproduce:** persona `expert`, seed 11, mission `fix_installer_not_ready`, day 48
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 9. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 102 distinct lines over 153 expert asks; 6 lines reach 5+ missions, e.g. "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" in 11 missions. Insights: 43 of 153 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 10. [low] careless could not press a needed talk to a yes

- **Category:** people · **occurrences:** 45 · **seen in:** careless/11, careless/12
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_checker: pushed 5 times ×14, talk petra_batch: pushed 5 times ×10, talk mieke_redraw: pushed 5 times ×10, talk marco_wasted_trips: pushed 5 times ×8, talk gert_klic: pushed 5 times ×3
- **Reproduce:** persona `careless`, seed 11, mission `fix_incomplete_application`, day 86
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 11. [low] never-talks could not press a needed talk to a yes

- **Category:** people · **occurrences:** 21 · **seen in:** never-talks/11, never-talks/12, never-talks/13
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_kpi: pushed 5 times ×15, talk marco_wasted_trips: pushed 5 times ×6
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_installer_not_ready`, day 57
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 12. [low] Slow missions for average play (over 30 days and twice the median of 1)

- **Category:** balance · **occurrences:** 6 · **seen in:** average/11
- **Detail:** fix_planning_reshuffle took 43 days, 3 Checks, 5 gemba actions
- **Affects:** fix_planning_reshuffle (43 d), fix_status_callers (56 d), repair_custom_design (57 d), fix_silo_kpis (66 d), fix_done_but_not_closed (56 d), fix_silo_kpis (70 d)
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 21
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 13. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 3 · **seen in:** average/11, careless/11, careless/12
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 36, careless/11: 48, careless/12: 55
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 14. [low] Slow missions for careless play (over 30 days and twice the median of 56)

- **Category:** balance · **occurrences:** 3 · **seen in:** careless/11
- **Detail:** fix_installer_not_ready took 127 days, 7 Checks, 4 gemba actions
- **Affects:** fix_installer_not_ready (127 d), fix_done_but_not_closed (211 d), fix_revision_backlog (225 d)
- **Reproduce:** persona `careless`, seed 11, mission `fix_installer_not_ready`, day 113
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 15. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** careless spends 64 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11, careless/12
- **Reproduce:** persona `careless`, seed 11, day 198
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 16. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 92 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless |
|---|---|---|---|---|
| training_mon | training | 1.0 (1) | 1.0 (1) | – | 1.0 (3) | 1.0 (3) |
| training_tue | training | 1.0 (1) | 1.0 (1) | – | 1.0 (3) | 1.0 (3) |
| training_wed | training | 1.0 (1) | 1.0 (1) | – | 1.0 (3) | 1.0 (3) |
| training_thu | training | 1.3 (1) | 1.4 (1) | – | 1.3 (3) | 1.3 (3) |
| training_fri | training | 0.0 (1) | 0.0 (1) | – | 0.0 (3) | 0.0 (3) |
| walk_connections | main | 0.0 (1) | 0.0 (1) | – | 0.0 (3) | 0.0 (3) |
| fix_custom_design | main | 14.3 (1) | 19.0 (3) | 59.9 (8) | 14.2 (3) | 14.3 (3) |
| fix_incomplete_application | main | 14.2 (1) | 24.7 (4) | 80.7 (4) | 14.3 (3) | 14.2 (3) |
| fix_installer_not_ready | main | 14.3 (1) | 14.2 (1) | 76.4 (7) | 14.3 (3) | 25.1 (3) |
| fix_status_callers | main | 14.2 (1) | 56.5 (1) | 56.2 (1) | 14.2 (3) | 14.3 (3) |
| fix_done_but_not_closed | main | 14.3 (1) | 28.2 (5) | 140.4 (2) | 14.3 (3) | 14.3 (3) |
| winter_el_amrani | milestone | 0.0 (1) | 0.0 (1) | 0.0 (2) | 0.0 (3) | 0.0 (3) |
| review_100_days | milestone | 0.2 (1) | 0.0 (1) | 0.0 (2) | 0.2 (3) | 0.2 (3) |
| fix_digging_damage | main | 14.2 (1) | 28.3 (2) | 98.5 (1) | 14.2 (3) | 14.3 (3) |
| fix_revision_backlog | main | 14.3 (1) | 18.9 (3) | 225.4 (1) | 14.3 (3) | 14.3 (3) |
| fix_grid_study_queue | main | 14.3 (1) | 14.2 (1) | – | 14.2 (3) | 14.4 (3) |
| fix_transformer_wait | main | 17.3 (1) | 28.6 (2) | – | 15.2 (3) | 14.2 (3) |
| fix_unused_capacity | main | 14.3 (1) | 21.3 (2) | – | 16.0 (3) | 19.0 (3) |
| fix_silo_kpis | main | 14.4 (1) | 50.1 (3) | – | 14.8 (3) | 24.6 (3) |
| walk_outages | side | 0.7 (1) | 0.7 (1) | 1.4 (2) | 0.7 (3) | 0.7 (3) |
| walk_meters | side | 1.0 (1) | 0.8 (1) | 1.4 (2) | 1.0 (3) | 0.9 (3) |
| fix_wrong_joint | side | 14.6 (1) | 19.1 (3) | 71.2 (15) | 14.6 (3) | 14.6 (3) |
| fix_not_at_home | side | 14.9 (1) | 14.8 (2) | 73.3 (5) | 14.9 (3) | 14.9 (3) |
| fix_silent_meter | side | 14.3 (1) | 21.4 (2) | 60.9 (15) | 14.3 (3) | 14.3 (3) |
| fix_permits_in_batches | side | 14.2 (1) | 21.3 (4) | 72.4 (13) | 14.2 (3) | 14.2 (3) |
| look_at_grid_study | side | 0.3 (1) | 0.3 (1) | 0.8 (1) | 0.3 (3) | 0.4 (3) |
| fix_inverters_tripping | side | 14.3 (1) | 28.8 (1) | 80.8 (4) | 14.4 (3) | 14.3 (3) |
| save_henks_knowledge | side | 14.3 (1) | 28.3 (1) | 49.3 (4) | 14.3 (3) | 14.3 (3) |
| fix_planning_reshuffle | side | 14.9 (1) | 21.2 (8) | 67.7 (16) | 14.9 (3) | 14.8 (3) |
| talk_netplanner | side | 0.3 (1) | 0.5 (1) | 1.1 (2) | 0.3 (3) | 0.3 (3) |
| lsw_gemba_round | side | 0.1 (1) | 0.1 (1) | 0.1 (2) | 0.1 (3) | 0.1 (3) |
| fix_double_visits | side | – | – | 47.0 (6) | – | – |
| fix_overtime_planning | side | – | – | 52.2 (7) | – | – |

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
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +10.2 % | first_time_right | +10.2 % | +1.3 % | +13.7 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +11.9 % | lead_time | +11.9 % | -5.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +15.7 % | first_time_right | +15.7 % | +3.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +6.1 % | on_time | +6.1 % | +7.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.9 % | lead_time | +21.9 % | -2.1 % | +0.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +2.4 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | wrong_joint_in_van | 1 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +20.3 % | on_time | +20.3 % | -0.2 % | +32.3 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.9 % | capacity | +41.9 % | +41.9 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +26.7 % | wip_age | +26.7 % | -3.7 % | +0.0 % |  |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +37.5 % | throughput | +37.5 % | +10.0 % | +0.0 % |  |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +12.7 % | first_time_right | +12.7 % | -12.4 % | -3.8 % | trend_hides_gain |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +6.8 % | throughput | +6.8 % | -23.1 % | +14.7 % | trend_hides_gain |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +20.0 % | first_time_right | +20.0 % | -10.5 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | lead_time | +18.2 % | on_time | +10.5 % | -3.4 % | +21.7 % |  |
| average | installer_not_ready | 1 | backup_job_per_day | 0.54 | yes | cause_right | first_time_right | +7.4 % | lead_time | +6.2 % | +11.6 % | +0.0 % |  |
| average | permits_in_batches | 1 | cupboard_photo_at_booking | 0.00 | no | mismatch | capacity | +0.0 % | lead_time | +0.0 % | +11.6 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | no | not_moved | on_time | -0.3 % | first_time_right | +45.9 % | -17.5 % | +8.5 % |  |
| average | incomplete_application | 1 | route_by_area | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +9.0 % | lead_time | +9.0 % | -13.2 % | +0.0 % | trend_hides_gain |
| average | planning_reshuffle | 2 | planning_with_fault_windows | 0.42 | no | too_early | first_time_right | +58.0 % | first_time_right | +58.0 % | -10.0 % | +0.0 % | failed_but_kpi_improved |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | capacity | +10.0 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +13.2 % | first_time_right | +13.2 % | -15.1 % | +12.3 % | trend_hides_gain |
| average | planning_reshuffle | 3 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +76.7 % | first_time_right | +76.7 % | -15.5 % | +0.0 % | trend_hides_gain |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +3.3 % | throughput | +3.3 % | +48.8 % | +14.7 % |  |
| average | knowledge_drain | 1 | close_out_at_completion | 0.00 | no | mismatch | wip_age | +0.0 % | on_time | +0.0 % | -23.7 % | +0.0 % |  |
| average | inverters_tripping | 1 | connections_wip_limit | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +23.1 % | +0.0 % |  |
| average | status_callers | 1 | customer_self_report | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -20.6 % | +0.0 % |  |
| average | knowledge_drain | 2 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +25.0 % | on_time | +25.0 % | +21.5 % | +18.9 % |  |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | on_time | +6.3 % | first_time_right | +7.3 % | -18.7 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | status_callers | 2 | realistic_promise | 0.63 | no | not_moved | wip_age | +0.0 % | on_time | +7.4 % | -6.3 % | +0.0 % |  |
| average | installer_not_ready | 1 | daily_revision_template | 0.00 | no | mismatch | on_time | +0.5 % | lead_time | +5.8 % | -24.8 % | +2.7 % |  |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | +16.1 % | on_time | +16.1 % | -4.3 % | +21.9 % |  |
| average | status_callers | 3 | proactive_status_updates | 0.50 | no | not_moved | throughput | -8.3 % | on_time | +4.3 % | -12.4 % | +0.0 % |  |
| average | installer_not_ready | 2 | readiness_check | 0.90 | yes | cause_right | lead_time | +6.1 % | lead_time | +6.1 % | +11.0 % | +0.0 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +16.0 % | lead_time | +16.0 % | +14.0 % | +0.0 % |  |
| average | status_callers | 4 | realistic_promise | 0.63 | yes | cause_right | wip_age | +5.7 % | on_time | +8.8 % | +28.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | planning_reshuffle | 1 | cupboard_photo_at_booking | 0.00 | no | mismatch | wip_age | +0.0 % | first_time_right | +0.0 % | -5.5 % | +0.0 % |  |
| average | incomplete_application | 1 | two_hour_window | 0.00 | no | mismatch | wip_age | +0.0 % | capacity | +0.0 % | +18.6 % | +0.0 % |  |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +52.1 % | first_time_right | +52.1 % | -6.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | capacity | +10.0 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | wrong_joint_in_van | 1 | customer_self_report | 0.00 | no | mismatch | capacity | +30.6 % | on_time | +14.9 % | -17.0 % | +30.6 % | failed_but_kpi_improved |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | yes | cause_right | lead_time | +13.2 % | lead_time | +13.2 % | -2.2 % | +0.0 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +11.2 % | lead_time | +11.2 % | -2.2 % | +0.0 % |  |
| average | wrong_joint_in_van | 2 | overtime_cap | 0.00 | no | mismatch | on_time | +14.9 % | on_time | +14.9 % | +17.7 % | +30.6 % | failed_but_kpi_improved |
| average | digging_damage | 1 | study_overtime_sprint | 0.00 | no | mismatch | on_time | +0.0 % | capacity | +0.0 % | -4.3 % | +0.0 % |  |
| average | wrong_joint_in_van | 3 | overtime_cap | 0.00 | no | mismatch | on_time | +15.8 % | on_time | +15.8 % | -7.9 % | +30.6 % | failed_but_kpi_improved |
| average | digging_damage | 2 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | +2.3 % | +4.7 % |  |
| average | wrong_joint_in_van | 4 | overtime_cap | 0.00 | no | mismatch | on_time | +15.1 % | on_time | +15.1 % | -9.6 % | +30.6 % | failed_but_kpi_improved |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.1 % | capacity | +21.1 % | +21.1 % | +21.1 % |  |
| average | custom_design | 1 | standard_van_stock | 0.00 | no | mismatch | lead_time | -1.7 % | throughput | -2.7 % | +102.7 % | +5.1 % |  |
| average | wrong_joint_in_van | 5 | overtime_cap | 0.00 | no | mismatch | first_time_right | +0.0 % | on_time | +16.1 % | +18.7 % | +30.5 % |  |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +28.6 % | capacity | +28.6 % | +28.6 % | +28.6 % |  |
| average | custom_design | 2 | standard_designs | 0.90 | no | not_moved | throughput | -1.3 % | throughput | -1.3 % | -46.7 % | +13.2 % |  |
| average | wrong_joint_in_van | 6 | overtime_cap | 0.00 | no | mismatch | wip_age | +0.0 % | on_time | +17.3 % | -0.7 % | +30.5 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | no | not_moved | on_time | -0.1 % | capacity | +8.5 % | +8.5 % | +8.5 % |  |
| average | custom_design | 3 | standard_designs | 0.90 | no | not_moved | lead_time | -2.6 % | throughput | -0.5 % | +7.5 % | +9.3 % |  |
| average | wrong_joint_in_van | 7 | overtime_cap | 0.00 | no | mismatch | first_time_right | +0.0 % | on_time | +18.7 % | -16.6 % | +30.5 % |  |
| average | incomplete_application | 2 | poka_yoke_application | 0.90 | yes | cause_right | throughput | +6.7 % | capacity | +8.5 % | +8.5 % | +8.5 % |  |
| average | custom_design | 4 | standard_designs | 0.90 | yes | cause_right | throughput | +6.6 % | throughput | +6.6 % | +72.1 % | +28.2 % |  |
| average | wrong_joint_in_van | 8 | overtime_cap | 0.00 | no | mismatch | first_time_right | +0.0 % | on_time | +17.6 % | +15.8 % | +30.5 % |  |
| average | digging_damage | 1 | contractor_briefing | 0.56 | no | not_moved | throughput | -13.6 % | capacity | +4.7 % | -13.1 % | +4.7 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | capacity | +34.9 % | first_time_right | +16.2 % | -24.3 % | +34.9 % | trend_hides_gain |
| average | status_callers | 4 | proactive_status_updates | 0.50 | no | not_moved | capacity | +0.0 % | on_time | +79.4 % | +38.6 % | +0.0 % |  |
| average | digging_damage | 2 | standard_test_trenches | 0.72 | yes | cause_right | wip_age | +100.0 % | capacity | +6.4 % | +16.2 % | +6.4 % |  |
| average | status_callers | 5 | proactive_status_updates | 0.50 | yes | cause_right | on_time | +94.8 % | on_time | +94.8 % | -19.6 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | silent_meter | 1 | triage_fast_lane | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -10.8 % | +0.0 % |  |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +34.5 % | wip_age | +34.5 % | +0.1 % | +0.0 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | capacity | +12.4 % | first_time_right | +23.5 % | +4.2 % | +12.4 % |  |
| average | wrong_joint_in_van | 1 | installer_photo_upload | 0.00 | no | mismatch | first_time_right | +0.0 % | on_time | +0.0 % | +4.3 % | +0.0 % |  |
| average | permits_in_batches | 1 | capacity_usage_dashboard | 0.00 | no | mismatch | throughput | +0.0 % | lead_time | +0.0 % | +8.5 % | +0.0 % |  |
| average | wrong_joint_in_van | 2 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +2.4 % | on_time | +2.4 % | -7.5 % | +16.1 % | trend_hides_gain |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | no | not_moved | wip_age | -0.9 % | lead_time | +8.3 % | +8.4 % | +0.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +16.6 % | lead_time | +16.6 % | +8.4 % | +0.0 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +24.5 % | lead_time | +24.5 % | -41.1 % | +0.0 % | trend_hides_gain |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +36.3 % | first_time_right | +36.3 % | -21.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | custom_design | 1 | standard_designs | 0.90 | no | not_moved | wip_age | -21.3 % | throughput | +15.8 % | -22.5 % | +29.0 % |  |
| average | custom_design | 2 | standard_designs | 0.90 | yes | cause_right | throughput | +12.2 % | throughput | +12.2 % | -12.7 % | +28.9 % | trend_hides_gain |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | transformer_wait | 1 | customer_self_report | 0.00 | no | mismatch | throughput | +0.0 % | wip_age | +0.0 % | +7.6 % | +0.0 % |  |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +17.2 % | first_time_right | +17.2 % | -6.9 % | +7.9 % | trend_hides_gain |
| average | transformer_wait | 2 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +32.7 % | wip_age | +32.7 % | -1.4 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | lead_time | +10.2 % | first_time_right | +31.4 % | -17.2 % | +4.9 % | trend_hides_gain |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | +54.5 % | throughput | +54.5 % | +0.0 % | +0.0 % |  |
| average | silo_kpis | 1 | contractor_briefing | 0.00 | no | mismatch | wip_age | +0.0 % | first_time_right | +0.0 % | +0.0 % | +0.0 % |  |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | no | not_moved | first_time_right | +0.0 % | first_time_right | +0.0 % | -6.8 % | -2.7 % |  |
| average | silo_kpis | 3 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +34.4 % | first_time_right | +34.4 % | +1.7 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +42.5 % | first_time_right | +42.5 % | -17.0 % | +11.1 % | trend_hides_gain |
| average | done_but_not_closed | 1 | register_cupboard_check | 0.00 | no | mismatch | capacity | +0.0 % | lead_time | +0.0 % | -28.6 % | +0.0 % |  |
| average | done_but_not_closed | 2 | mid_month_run | 0.54 | yes | cause_right | lead_time | +14.4 % | lead_time | +14.4 % | -3.7 % | +0.0 % |  |
| average | unused_capacity | 1 | request_permits_daily | 0.00 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | +37.5 % | +0.0 % |  |
| average | unused_capacity | 2 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | +43.5 % | throughput | +43.5 % | -54.5 % | +0.0 % | trend_hides_gain |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | no | not_moved | throughput | +0.5 % | capacity | +0.0 % | -8.1 % | +0.0 % |  |
| average | planning_reshuffle | 1 | appointment_reminder | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -13.1 % | +0.0 % |  |
| average | revision_backlog | 2 | revision_at_source | 0.50 | yes | cause_right | capacity | +15.9 % | capacity | +15.9 % | +26.2 % | +15.9 % |  |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | throughput | +13.6 % | first_time_right | +55.9 % | +0.3 % | +14.2 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +26.4 % | lead_time | +26.4 % | -20.6 % | +0.0 % | trend_hides_gain |
| average | silo_kpis | 3 | connections_wip_limit | 0.72 | no | not_moved | wip_age | -1.3 % | first_time_right | +1.9 % | -2.0 % | -4.2 % |  |
| average | silo_kpis | 4 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +12.9 % | first_time_right | +12.9 % | +62.6 % | -4.2 % |  |
| average | done_but_not_closed | 1 | installer_photo_upload | 0.00 | no | mismatch | lead_time | +0.0 % | lead_time | +0.0 % | -1.8 % | +0.0 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | no | not_moved | throughput | -2.0 % | lead_time | +20.8 % | -21.9 % | +0.0 % |  |
| average | done_but_not_closed | 3 | automatic_ean_registration | 0.45 | no | too_early | lead_time | +12.9 % | lead_time | +12.9 % | +22.4 % | +0.0 % | failed_but_kpi_improved |
| average | unused_capacity | 2 | use_it_or_lose_it | 0.90 | yes | cause_right | on_time | +36.4 % | throughput | +34.4 % | +100.0 % | +0.0 % |  |
| average | done_but_not_closed | 4 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +23.5 % | lead_time | +23.5 % | -14.0 % | +0.0 % | trend_hides_gain |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +24.6 % | first_time_right | +24.6 % | -36.7 % | +16.4 % | trend_hides_gain |
| average | silo_kpis | 1 | daily_revision_template | 0.00 | no | mismatch | throughput | +0.0 % | first_time_right | +0.0 % | +38.6 % | +0.0 % |  |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | no | not_moved | first_time_right | -1.2 % | first_time_right | -1.2 % | -16.0 % | -2.4 % |  |
| average | silo_kpis | 3 | obeya_end_to_end | 0.90 | no | not_moved | on_time | -1.8 % | first_time_right | +10.4 % | +51.0 % | -3.2 % |  |
| average | silo_kpis | 4 | obeya_end_to_end | 0.90 | no | not_moved | on_time | -0.9 % | first_time_right | +13.0 % | -44.7 % | -3.2 % |  |
| average | silo_kpis | 5 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +4.3 % | first_time_right | +4.3 % | +25.9 % | -3.6 % |  |
| average | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +19.2 % | lead_time | +19.2 % | +13.1 % | +0.0 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | yes | cause_right | throughput | +20.4 % | capacity | +10.0 % | +9.2 % | +10.0 % |  |
| average | silo_kpis | 1 | connections_wip_limit | 0.72 | yes | cause_right | first_time_right | +5.1 % | first_time_right | +5.1 % | +5.7 % | -2.6 % |  |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 20 of 20 passed; average 55 of 102 passed; careless 122 of 594 passed; talker 60 of 60 passed; never-talks 61 of 63 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| average | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| careless | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +10.0 % |
| careless | 11 | fix_incomplete_application | fix_installer_not_ready | no | yes | -6.2 % |
| careless | 12 | fix_incomplete_application | fix_incomplete_application | no | no | +151.4 % |
| careless | 12 | fix_incomplete_application | fix_installer_not_ready | no | no | -29.8 % |
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
