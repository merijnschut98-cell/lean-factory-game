# Autoplay report

Generated 2026-10-21T12:01:53 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, seeds 11, 12, 13). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 0 critical, 6 high, 4 medium, 8 low. Every persona but careless reaches the end of the campaign without a dead end: no.

## S1-H verdict: QA 2.12 (a) and (b), before and after (written 2026-10-21; the rest of this file is generated)

**Runs.** Talker and never-talks on seeds 11, 12, 13; expert, average and careless on seed 11 only (careless takes about 18 minutes a run, and six agents shared four CPUs). *Before* is `e62ee52`; *after* is the S1-H commits: `talk_to` goals on the Act I missions, check-ins at 25 XP with holding at 100, the daily morale drift, and Anouk's one-day trial.

| | before (e62ee52) | after (S1-H) |
|---|---|---|
| XP, talker 11 / 12 / 13 | 20 376 / 19 992 / 20 442 | 19 733 / 19 767 / 19 753 |
| XP, never-talks 11 / 12 / 13 | 20 490 / 20 840 / 20 322 (**more** than the talker) | 17 511 / 17 767 / 17 493 (about 2 200 **less**) |
| never-talks: mean morale, start → end | 51.9 → 51.9 (flat; nobody leaves) | 51.9 → 42–43; Linda under 20 by about day 90 and gone on day 148–161; Esra and Petra leave later |
| talker: lowest morale, who leaves | 50, nobody | 45–50, nobody |
| expert 11: XP, who leaves | 20 490, nobody | 19 718; Anouk (day 211) and Ahmed (day 324) leave: the expert never answers a check-in |
| average 11: XP | 22 355 | 19 955 |
| careless 11 | not run before | horizon, 11 625 XP, five people leave |

**(a) Decay no longer pays.** Never-talks now ends below the talker on every seed. It still opens more check-ins than the talker (16–19 against 13), but a check-in now pays 25 XP. A yes under pressure pays half the mission (the `talk_to` goals), and that half is most of the gap. No persona holds a fix before it slips, because all of them audit only on a 'slipping' event, so the holding reward (100, once a fix) never shows up here. The unit tests cover it.

**(b) Ignoring people costs.** Morale now drifts every day. A team planned above 85 % of its time loses morale (the load alone stops at 30), a fix won by pressure keeps costing, and an unanswered check-in costs 5. People recover under the norm. The acceptance holds: never-talks has someone under 40 by day 100 (Linda), and the talker keeps everyone. **To tune:** people now leave in every run that ignores check-ins. That is three in never-talks, two for the expert and five for careless. Merijn said people leave rarely. Raising `LEAVE_IGNORED` or `LEAVE_DAYS`, or the load floor, would make that rarer.

**Needed talks.** Never-talks presses each needed talk to a yes (hello, a proposal, pressure, the ask): 7 compliances a run. With Marco it ruins the talk 5 times (he is closed, so pressure takes his openness under 10). After that it listens, which is logged as assisted (a low finding). Before a fix in this round, the talker went through 987 'heard' talks with Petra on seed 12, because it closed whenever no proposal was offered. It now listens on, and a needed talk not won in 20 talks is a dead end. Careless also found a mission stuck on a dormant problem (its fix faded while the mission still waited for the talk). That is fixed in `5f75d23`, and the careless run above was played after the fix.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 162 | 40 | 12 | 19718 | green | € 275.697 | 20/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 444 | 59 | 16 | 19955 | green | € 193.807 | 32/47 | 0 | 28 | 0 | 0 |
| careless | 11 | horizon | 1096 | 58 | 14 | 11625 | green | € -50.000 | 56/231 | 1 | 53 | 1 | 30 |
| talker | 11 | campaign_done | 162 | 39 | 12 | 19733 | green | € 278.449 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 12 | campaign_done | 176 | 41 | 12 | 19767 | green | € 285.389 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 13 | campaign_done | 162 | 37 | 12 | 19753 | green | € 282.375 | 20/0 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 176 | 47 | 12 | 17511 | green | € 248.906 | 20/0 | 0 | 0 | 0 | 5 |
| never-talks | 12 | campaign_done | 177 | 49 | 12 | 17767 | green | € 244.421 | 21/0 | 0 | 0 | 0 | 6 |
| never-talks | 13 | campaign_done | 173 | 47 | 12 | 17493 | green | € 248.411 | 20/0 | 0 | 0 | 0 | 2 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 13 (1) | none 1, commitment 6, heard 4, partial 2 | 50.2→54.1 | 51.9→52.9 | anouk 12 | anouk (d211), ahmed (d324) | 18/18 | 1 | 40 | 40 | 7/4/7 | 380 | 11 | € 34.800 | 18/18, 0, 27 |
| average | 11 | 16 (1) | none 1, heard 7, commitment 7, partial 1 | 50.2→54.8 | 51.9→46.8 | ahmed 0 | anouk (d161), ahmed (d344), marco (d570) | 14/18 | 29 | 57 | 36 | 3/4/7 | 226 | 11 | € 31.800 | 3/18, 11, 18 |
| careless | 11 | 49 (0) | compliance 4, ruined 17, heard 24, partial 3, none 1 | 50.2→47.5 | 51.9→28.5 | ahmed 0 | linda (d127), anouk (d239), ahmed (d394), marco (d590), esra (d717) | 2/12 | 54 | 54 | 0 | 0/1/1 | 196 | 3 | € -50.000 | – |
| talker | 11 | 62 (0) | commitment 22, heard 17, partial 9, lifted 13, none 1 | 50.2→67.5 | 51.9→67.8 | femke 45 | – | 18/18 | 1 | 36 | 36 | 11/4/3 | 447 | 11 | € 34.800 | 18/18, 0, 24 |
| talker | 12 | 63 (0) | heard 22, commitment 19, partial 8, none 1, lifted 13 | 50.2→67.0 | 51.9→67.2 | femke 48 | – | 18/18 | 1 | 39 | 39 | 10/4/4 | 416 | 11 | € 34.800 | 18/18, 0, 25 |
| talker | 13 | 66 (0) | commitment 20, heard 25, partial 7, lifted 13, blocked 1 | 50.2→67.8 | 51.9→68.4 | esra 50 | – | 18/18 | 1 | 31 | 31 | 11/5/2 | 424 | 11 | € 34.800 | 18/18, 0, 21 |
| never-talks | 11 | 18 (1) | none 1, compliance 7, ruined 5, heard 4, commitment 1 | 50.2→45.0 | 51.9→42.9 | linda 0 | linda (d161), esra (d246), petra (d281) | 18/18 | 1 | 50 | 50 | 1/5/12 | 284 | 6 | € 34.800 | 18/18, 0, 30 |
| never-talks | 12 | 19 (1) | none 1, compliance 7, ruined 5, heard 5, commitment 1 | 50.2→45.1 | 51.9→43.0 | linda 0 | linda (d148), esra (d240), petra (d282) | 18/18 | 1 | 48 | 48 | 1/5/12 | 306 | 6 | € 34.800 | 18/18, 0, 27 |
| never-talks | 13 | 15 (1) | none 1, compliance 7, ruined 5, heard 1, partial 1 | 50.2→44.3 | 51.9→42.3 | linda 0 | linda (d158), esra (d243), petra (d278) | 18/18 | 1 | 49 | 49 | 1/5/12 | 284 | 6 | € 34.800 | 18/18, 0, 29 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 1 | 40.0 | 0.0 | 162 | € 275.697 | € 34.800 | 54.1 | 47.9 | 2.0 | 18.0/18.0 | 41.0 | 380 | 11.0 | 13.0 |
| average | 1 | 59.0 | 0.0 | 444 | € 193.807 | € 31.800 | 54.8 | 44.9 | 3.0 | 3.0/18.0 | 86.0 | 615 | 11.0 | 16.0 |
| careless | 1 | 58.0 | 1.0 | 1096 | € -50.000 | € -50.000 | 47.5 | 28.5 | 5.0 | 2.0/12.0 | 108.0 | 196 | 3.0 | 49.0 |
| talker | 3 | 39.0 | 0.0 | 167 | € 282.071 | € 34.800 | 67.4 | 61.5 | 0.0 | 18.0/18.0 | 36.3 | 429 | 11.0 | 63.7 |
| never-talks | 3 | 47.7 | 0.0 | 175 | € 247.246 | € 34.800 | 44.8 | 34.6 | 3.0 | 18.0/18.0 | 50.0 | 305 | 6.0 | 17.3 |

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

## Findings (18), ranked by severity

### 1. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 2 · **seen in:** average/11, careless/11
- **Detail:** average/11: 24 of 54 completed missions were re-runs of a faded fix; the campaign took 444 days (campaign_done) against the expert's 162
- **Affects:** average/11: 24/54, careless/11: 43/58
- **Reproduce:** persona `average`, seed 11, day 444
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 2. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** careless ends at € -50.000 after 1096 days, still falling about € 1.093 a month; 1 bad periods
- **Affects:** careless/11
- **Reproduce:** persona `careless`, seed 11, day 1096
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 3. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 73 · **seen in:** expert/11, average/11, careless/11, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm standard_designs, predicted throughput +8.7 % (fix), problem KPI throughput +8.7 % (fix), -32.3 % (before/after), capacity +26.2 % (fix), eff 0.90, lesson cause_right
- **Affects:** custom_design ×11, not_at_home ×7, wrong_joint_in_van ×7, silent_meter ×7, planning_reshuffle ×7, status_callers ×7, installer_not_ready ×6, permits_in_batches ×5, knowledge_drain ×4, done_but_not_closed ×4, unused_capacity ×4, silo_kpis ×3, inverters_tripping
- **Reproduce:** persona `expert`, seed 11, mission `fix_custom_design`, day 19
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 4. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 25 · **seen in:** average/11, careless/11
- **Detail:** cm planning_with_fault_windows, predicted first_time_right +37.7 % (fix), problem KPI first_time_right +37.7 % (fix), -14.8 % (before/after), capacity +0.0 % (fix), eff 0.42, lesson too_early
- **Affects:** planning_reshuffle ×6, wrong_joint_in_van ×5, silent_meter ×5, knowledge_drain ×4, not_at_home ×2, inverters_tripping ×2, installer_not_ready
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 63
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 5. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** 58 missions after 1096 days
- **Affects:** horizon
- **Reproduce:** persona `careless`, seed 11, day 1096
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 6. [high] Check passes while the problem's own KPI got worse (prediction named another KPI)

- **Category:** contradiction · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** cm daytime_outage_crew, predicted wip_age +32.4 % (fix), problem KPI first_time_right -14.2 % (fix), -16.8 % (before/after), capacity +109.3 % (fix), eff 0.90, lesson cause_wrong
- **Affects:** planning_reshuffle
- **Reproduce:** persona `careless`, seed 11, mission `fix_planning_reshuffle`, day 59
- **Proposed fix:** Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'.

### 7. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 5 · **seen in:** average/11, careless/11
- **Detail:** 8 failed Checks on wrong_joint_in_van
- **Affects:** repair_wrong_joint_in_van, fix_wrong_joint, repair_knowledge_drain, save_henks_knowledge, fix_permits_in_batches
- **Reproduce:** persona `average`, seed 11, mission `repair_wrong_joint_in_van`, day 175
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 8. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 45 · **seen in:** careless/11
- **Detail:** cm delegated_approval, predicted lead_time +9.2 % (fix), problem KPI throughput +2.1 % (fix), +16.7 % (before/after), capacity +14.7 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** wrong_joint_in_van ×10, silent_meter ×9, custom_design ×6, planning_reshuffle ×6, permits_in_batches ×5, not_at_home ×3, installer_not_ready ×2, inverters_tripping ×2, incomplete_application, done_but_not_closed
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 57
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 9. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 28 · **seen in:** expert/11, average/11, careless/11, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** cm readiness_check, predicted lead_time +11.6 % (fix), problem KPI lead_time +11.6 % (fix), -5.1 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** status_callers ×12, inverters_tripping ×9, installer_not_ready ×5, not_at_home, planning_reshuffle
- **Reproduce:** persona `expert`, seed 11, mission `fix_installer_not_ready`, day 48
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 10. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 74 distinct lines over 153 expert asks; 8 lines reach 5+ missions, e.g. "Wat zie je hier dat de mensen zelf al lang niet meer zien?" in 9 missions. Insights: 46 of 153 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 11. [low] careless could not press a needed talk to a yes

- **Category:** people · **occurrences:** 30 · **seen in:** careless/11
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk petra_batch: pushed 5 times ×14, talk marco_wasted_trips: pushed 5 times ×9, talk sanne_checker: pushed 5 times ×7
- **Reproduce:** persona `careless`, seed 11, mission `fix_installer_not_ready`, day 73
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 12. [low] never-talks could not press a needed talk to a yes

- **Category:** people · **occurrences:** 13 · **seen in:** never-talks/11, never-talks/12, never-talks/13
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk marco_wasted_trips: pushed 5 times ×13
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_installer_not_ready`, day 57
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 13. [low] Slow missions for average play (over 30 days and twice the median of 14)

- **Category:** balance · **occurrences:** 5 · **seen in:** average/11
- **Detail:** fix_planning_reshuffle took 42 days, 3 Checks, 5 gemba actions
- **Affects:** fix_planning_reshuffle (42 d), fix_revision_backlog (70 d), fix_permits_in_batches (98 d), fix_digging_damage (42 d), fix_silo_kpis (43 d)
- **Reproduce:** persona `average`, seed 11, mission `fix_planning_reshuffle`, day 35
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 14. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 2 · **seen in:** average/11, careless/11
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 28, careless/11: 53
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 15. [low] Slow missions for careless play (over 30 days and twice the median of 70)

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** fix_done_but_not_closed took 141 days, 8 Checks, 6 gemba actions
- **Affects:** fix_done_but_not_closed (141 d)
- **Reproduce:** persona `careless`, seed 11, mission `fix_done_but_not_closed`, day 647
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 16. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** careless spends 67 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11
- **Reproduce:** persona `careless`, seed 11, day 169
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 17. [low] Deadline missed: save_henks_knowledge

- **Category:** deadline · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** failed on day 171 (taken on: false), closes ["skills_matrix_buddy", "twi_job_instruction"]
- **Affects:** careless
- **Reproduce:** persona `careless`, seed 11, mission `save_henks_knowledge`, day 171
- **Proposed fix:** Working as designed (a missed deadline closes a door); see the orphan finding for what happens to its problem.

### 18. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 84 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
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
| fix_custom_design | main | 14.3 (1) | 28.4 (1) | 66.3 (7) | 14.2 (3) | 14.3 (3) |
| fix_incomplete_application | main | 14.2 (1) | 28.1 (2) | 70.5 (1) | 14.3 (3) | 14.2 (3) |
| fix_installer_not_ready | main | 14.3 (1) | 14.2 (1) | 70.2 (4) | 14.3 (3) | 27.5 (3) |
| fix_status_callers | main | 14.2 (1) | 28.3 (1) | 56.2 (1) | 14.3 (3) | 14.3 (3) |
| fix_done_but_not_closed | main | 14.3 (1) | 28.4 (1) | 140.6 (1) | 14.3 (3) | 14.3 (3) |
| fix_digging_damage | main | 14.2 (1) | 35.4 (2) | – | 14.3 (3) | 14.3 (3) |
| fix_revision_backlog | main | 14.2 (1) | 32.8 (3) | – | 14.3 (3) | 14.3 (3) |
| fix_grid_study_queue | main | 14.2 (1) | 28.2 (1) | – | 14.3 (3) | 14.4 (3) |
| fix_transformer_wait | main | 14.2 (1) | 28.6 (1) | – | 14.2 (3) | 14.2 (3) |
| fix_unused_capacity | main | 14.3 (1) | 14.5 (1) | – | 14.3 (3) | 14.3 (3) |
| fix_silo_kpis | main | 14.5 (1) | 43.1 (1) | – | 14.5 (3) | 14.4 (3) |
| walk_outages | side | 0.6 (1) | 1.1 (1) | 1.0 (1) | 0.7 (3) | 0.6 (3) |
| walk_meters | side | 0.9 (1) | 0.7 (1) | 0.6 (1) | 0.9 (3) | 0.9 (3) |
| fix_wrong_joint | side | 14.6 (1) | 28.8 (1) | 71.7 (10) | 14.6 (3) | 14.6 (3) |
| fix_not_at_home | side | 14.9 (1) | 28.9 (1) | 61.1 (3) | 14.9 (3) | 14.9 (3) |
| fix_silent_meter | side | 14.3 (1) | 19.0 (6) | 57.8 (9) | 14.3 (3) | 14.3 (3) |
| fix_permits_in_batches | side | 14.2 (1) | 63.3 (2) | 66.2 (7) | 14.2 (3) | 14.2 (3) |
| look_at_grid_study | side | 0.3 (1) | 0.3 (1) | 0.5 (1) | 0.3 (3) | 0.3 (3) |
| fix_inverters_tripping | side | 14.3 (1) | 21.4 (2) | 84.5 (3) | 14.4 (3) | 14.3 (3) |
| save_henks_knowledge | side | 14.3 (1) | 28.3 (1) | 56.2 (1) | 14.3 (3) | 14.3 (3) |
| fix_planning_reshuffle | side | 14.9 (1) | 28.2 (3) | 63.3 (8) | 14.9 (3) | 14.8 (3) |

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
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +11.6 % | lead_time | +11.6 % | -5.1 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +19.0 % | first_time_right | +19.0 % | +3.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +5.6 % | on_time | +5.6 % | +7.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.3 % | lead_time | +21.3 % | -0.1 % | +0.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +2.4 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | wrong_joint_in_van | 1 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +19.1 % | on_time | +19.1 % | -0.2 % | +32.3 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.9 % | capacity | +41.9 % | +41.9 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +23.7 % | wip_age | +23.7 % | -0.1 % | +0.0 % |  |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +37.5 % | throughput | +37.5 % | +14.3 % | +0.0 % |  |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +20.3 % | first_time_right | +20.3 % | +7.4 % | -3.8 % |  |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | shared_team_goals | 0.00 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | -23.1 % | +0.0 % |  |
| average | not_at_home | 1 | standard_designs | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -12.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | no | not_moved | wip_age | +0.0 % | on_time | +10.5 % | -3.4 % | +21.7 % |  |
| average | custom_design | 2 | delegated_approval | 0.55 | yes | cause_right | throughput | +11.0 % | throughput | +11.0 % | -6.0 % | +14.7 % | trend_hides_gain |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | on_time | +6.6 % | first_time_right | +26.7 % | -6.8 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 2 | standard_van_stock | 0.72 | yes | cause_right | on_time | +11.6 % | on_time | +11.6 % | -7.9 % | +21.7 % | trend_hides_gain |
| average | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +5.8 % | lead_time | +5.8 % | +13.4 % | +0.0 % |  |
| average | permits_in_batches | 1 | one_tray_fifo | 0.00 | no | mismatch | capacity | +0.0 % | lead_time | +0.0 % | +13.4 % | +0.0 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | no | not_moved | on_time | +1.7 % | first_time_right | +55.1 % | +22.6 % | +0.0 % |  |
| average | incomplete_application | 1 | use_it_or_lose_it | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +7.1 % | lead_time | +7.1 % | -41.7 % | +0.0 % | trend_hides_gain |
| average | planning_reshuffle | 2 | planning_with_fault_windows | 0.42 | no | too_early | first_time_right | +37.7 % | first_time_right | +37.7 % | -14.8 % | +0.0 % | failed_but_kpi_improved |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | first_time_right | +16.6 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | throughput | +3.9 % | first_time_right | +15.6 % | +9.9 % | +12.3 % |  |
| average | planning_reshuffle | 3 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +50.1 % | first_time_right | +50.1 % | +0.0 % | +0.0 % |  |
| average | status_callers | 1 | early_transformer_order | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -33.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 2 | tray_labels | 0.00 | no | mismatch | wip_age | +0.0 % | on_time | +51.8 % | -28.1 % | +25.0 % |  |
| average | knowledge_drain | 1 | daytime_outage_crew | 0.00 | no | mismatch | lead_time | +0.0 % | on_time | +0.0 % | -28.1 % | +0.0 % |  |
| average | status_callers | 2 | realistic_promise | 0.63 | yes | cause_right | on_time | +6.4 % | on_time | +6.4 % | +10.5 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | wrong_joint_in_van | 3 | tray_labels | 0.00 | no | mismatch | on_time | +26.9 % | on_time | +26.9 % | +32.1 % | +29.8 % | failed_but_kpi_improved |
| average | knowledge_drain | 2 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +26.1 % | on_time | +26.1 % | +32.4 % | +19.1 % |  |
| average | done_but_not_closed | 1 | obeya_end_to_end | 0.00 | no | mismatch | wip_age | +0.0 % | lead_time | +0.0 % | +38.0 % | +0.0 % |  |
| average | wrong_joint_in_van | 4 | tray_labels | 0.00 | no | mismatch | throughput | +0.0 % | on_time | +19.2 % | -0.9 % | +30.6 % |  |
| average | inverters_tripping | 1 | realistic_promise | 0.00 | no | mismatch | on_time | +0.0 % | first_time_right | +0.0 % | -11.8 % | +0.0 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.9 % | lead_time | +21.9 % | -96.5 % | +0.0 % | trend_hides_gain |
| average | wrong_joint_in_van | 5 | tray_labels | 0.00 | no | mismatch | on_time | +16.7 % | on_time | +16.7 % | +0.2 % | +30.6 % | failed_but_kpi_improved |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +11.0 % | first_time_right | +11.0 % | -2.8 % | +0.0 % |  |
| average | digging_damage | 1 | contractor_briefing | 0.56 | no | not_moved | lead_time | +0.0 % | capacity | +4.7 % | +6.3 % | +4.7 % |  |
| average | wrong_joint_in_van | 6 | tray_labels | 0.00 | no | mismatch | on_time | +21.9 % | on_time | +21.9 % | +5.5 % | +30.6 % | failed_but_kpi_improved |
| average | planning_reshuffle | 1 | intake_checklist | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -8.9 % | +0.0 % |  |
| average | digging_damage | 2 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +22.0 % | +6.4 % |  |
| average | wrong_joint_in_van | 7 | tray_labels | 0.00 | no | mismatch | on_time | +20.1 % | on_time | +20.1 % | -3.8 % | +30.5 % | failed_but_kpi_improved |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +19.9 % | first_time_right | +19.9 % | +15.2 % | +6.5 % |  |
| average | revision_backlog | 1 | proactive_status_updates | 0.00 | no | mismatch | wip_age | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | wrong_joint_in_van | 8 | tray_labels | 0.00 | no | mismatch | on_time | +15.6 % | on_time | +15.6 % | +4.8 % | +30.5 % | failed_but_kpi_improved |
| average | silent_meter | 1 | skills_matrix_buddy | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +1.4 % | +0.0 % |  |
| average | revision_backlog | 2 | daily_revision_template | 0.63 | no | not_moved | throughput | +1.7 % | capacity | +0.0 % | -28.4 % | +0.0 % |  |
| average | permits_in_batches | 1 | smart_meter_voltage_data | 0.00 | no | mismatch | wip_age | +0.0 % | lead_time | +0.0 % | -30.7 % | +0.0 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | lead_time | +9.3 % | first_time_right | +15.2 % | -1.0 % | +12.3 % |  |
| average | revision_backlog | 3 | daily_revision_template | 0.63 | no | not_moved | wip_age | -1.7 % | capacity | +16.7 % | +62.9 % | +16.7 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | no | not_moved | wip_age | +1.8 % | lead_time | +9.5 % | +7.0 % | +0.0 % |  |
| average | wrong_joint_in_van | 1 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -3.0 % | +0.0 % |  |
| average | revision_backlog | 4 | daily_revision_template | 0.63 | no | not_moved | on_time | -0.3 % | capacity | +13.3 % | +13.3 % | +13.3 % |  |
| average | permits_in_batches | 3 | request_permits_daily | 0.90 | no | not_moved | on_time | +0.5 % | lead_time | +9.4 % | -0.4 % | +0.0 % |  |
| average | wrong_joint_in_van | 2 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | +25.2 % | +0.0 % |  |
| average | revision_backlog | 5 | daily_revision_template | 0.63 | yes | cause_right | capacity | +9.6 % | capacity | +9.6 % | +9.4 % | +9.6 % |  |
| average | permits_in_batches | 4 | request_permits_daily | 0.90 | no | not_moved | on_time | +1.3 % | lead_time | +10.3 % | +3.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 3 | tray_labels | 0.00 | no | mismatch | wip_age | +0.0 % | on_time | +0.0 % | -6.9 % | +0.0 % |  |
| average | grid_study_queue | 1 | contractor_briefing | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +0.0 % | +0.0 % |  |
| average | permits_in_batches | 5 | request_permits_daily | 0.90 | no | not_moved | wip_age | -7.0 % | lead_time | +11.2 % | -15.3 % | +0.0 % |  |
| average | wrong_joint_in_van | 4 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -7.5 % | +0.0 % |  |
| average | grid_study_queue | 2 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +38.3 % | capacity | +38.3 % | +38.3 % | +38.3 % |  |
| average | permits_in_batches | 6 | request_permits_daily | 0.90 | no | not_moved | on_time | -1.5 % | lead_time | +10.0 % | +9.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 5 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | +10.2 % | +0.0 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | lead_time | +2.2 % | capacity | +21.1 % | +21.1 % | +21.1 % |  |
| average | permits_in_batches | 7 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +9.4 % | lead_time | +9.4 % | -8.6 % | +0.0 % | trend_hides_gain |
| average | wrong_joint_in_van | 6 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -13.1 % | +0.0 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | no | not_moved | on_time | +0.4 % | capacity | +10.0 % | +10.0 % | +10.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | wip_age | +37.1 % | first_time_right | +16.8 % | -19.4 % | +16.9 % | trend_hides_gain |
| average | wrong_joint_in_van | 7 | tray_labels | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -17.7 % | +0.0 % |  |
| average | incomplete_application | 2 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +14.9 % | capacity | +14.9 % | +14.9 % | +14.9 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +54.1 % | first_time_right | +54.1 % | -16.8 % | +5.3 % | trend_hides_gain |
| average | wrong_joint_in_van | 8 | tray_labels | 0.00 | no | mismatch | first_time_right | +0.0 % | on_time | +0.0 % | +11.4 % | +0.0 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | transformer_wait | 1 | calculation_templates | 0.00 | no | mismatch | wip_age | +0.0 % | wip_age | +0.0 % | -5.4 % | +0.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +18.6 % | first_time_right | +18.6 % | +4.8 % | +15.6 % |  |
| average | transformer_wait | 2 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +24.3 % | wip_age | +24.3 % | +7.6 % | +0.0 % |  |
| average | digging_damage | 1 | two_bin_van_kanban | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | -20.8 % | +0.0 % |  |
| average | digging_damage | 2 | contractor_briefing | 0.56 | no | not_moved | wip_age | +0.0 % | capacity | +4.7 % | +12.4 % | +4.7 % |  |
| average | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +11.9 % | first_time_right | +11.9 % | +9.8 % | +4.9 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +15.0 % | first_time_right | +15.0 % | -14.7 % | +12.4 % | trend_hides_gain |
| average | digging_damage | 3 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +38.0 % | +6.4 % |  |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | on_time | +35.9 % | throughput | +10.3 % | +800.0 % | +0.0 % |  |
| average | silo_kpis | 1 | flexible_contracts | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +42.1 % | +0.0 % |  |
| average | silent_meter | 1 | two_hour_window | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +8.7 % | +0.0 % |  |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | no | not_moved | throughput | -0.8 % | first_time_right | +7.7 % | -15.4 % | -3.0 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | wip_age | +4.7 % | first_time_right | +18.2 % | -9.2 % | +12.3 % | trend_hides_gain |
| average | silo_kpis | 3 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +4.5 % | first_time_right | +4.5 % | -10.0 % | -0.5 % | trend_hides_gain |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 20 of 20 passed; average 32 of 79 passed; careless 56 of 287 passed; talker 60 of 60 passed; never-talks 61 of 61 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| average | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| careless | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +12.4 % |
| careless | 11 | fix_installer_not_ready | fix_installer_not_ready | yes | no | -0.0 % |
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
| go_see | 45 | 21 | 15 | "Wat zie je hier dat de mensen zelf al lang niet meer zien?" (9) |
| understand | 36 | 18 | 12 | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" (8) |
| experiment | 32 | 15 | 8 | "Wat doe je als het tegenvalt?" (8) |
| reflect | 35 | 17 | 11 | "Wat zou je anders doen als je opnieuw begon?" (8) |
| talk | 5 | 3 | 0 | "Wiens idee was het uiteindelijk?" (3) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `kpi_review_due()`: `kpi_review(choices)` exists, but nothing says when a review is due and no screen calls it (PLAN 2.4c), so the quarterly review is not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.
- `goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).
