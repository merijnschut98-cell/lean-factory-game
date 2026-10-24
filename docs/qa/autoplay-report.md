# Autoplay report

Generated 2026-10-24T11:45:30 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, non-bottleneck, seeds 11, 12). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 1 critical, 6 high, 6 medium, 9 low. Every persona but careless reaches the end of the campaign without a dead end: yes.

## Phase 2 gate, the machine half (PLAN 2.8; S3 lane G-A, 2026-10-24)

**Runs.** The whole tier 1 as it stands on `origin` after the review fix pass (Act 0, Act I with the fork, `winter_el_amrani`, `review_100_days`, Act II, `first_kpi_review`, the funding rule and the directie advance at the debt floor, the way back). Five personas on seeds 11 and 12, plus a control, `non-bottleneck`: it plays as the expert does but takes the fork's other branch first. The control runs only when named. Twelve runs, one Godot process at a time. The S2-Q notes that stood here are in git history (`docs/qa/autoplay-report.md` before this commit).

**The expectations, with the numbers.**

| expectation | verdict | numbers |
|---|---|---|
| Every persona reaches day 100 without a stuck state | **holds** | 0 dead ends by day 100 in all 12 runs; 0 engine errors. Every persona except careless finishes the campaign. Careless gets stuck later: Sanne's talk, after day 240 (backlog 2). |
| Bottleneck first beats the other branch on flow | **marginal: holds on capacity and on the dossier, not in the stream's numbers** | Intake fix: Check capacity +18.4 %. Monteurs fix: +0.2 to +0.7 % (fork table). Connections flow at day 100, expert vs non-bottleneck: 27.0 vs 27.8 per week and 48 vs 49 days (seed 11); 32.8 vs 33.5 per week and 53 vs 52 days (seed 12). The difference is inside the seed noise. Probe over 120 days: intake fixed 26.8–28.9 per week, both problems 25.5–27.5. The gap shows in the followed dossier: El Amrani connected on day 56–60 (bottleneck first) vs 78–81 (other branch first). Backlog 3. |
| Careful and standardising beats careless in the long term | **holds** | Fixes held after the epilogue: expert 18/18, average (standardises half the time) 8.5/18, careless 3/13.5 at the 3-year horizon. Budget at the end: € 297 685 vs € 279 131 vs € −50 000. Slipping + recurred: 36.5 vs 104.5 vs 118. XP: expert 21 757, careless 13 822. |
| The talker beats never-talks on trust and morale | **holds** | Trust at the end: 67.2 vs 41.2. Morale: 67.5 vs 35.5. Never-talks loses Linda (day 215–221) and Esra (day 313–320) on both seeds, with six people under 40 morale by day 100; the talker has none. XP: 21 603 vs 16 571. |
| Winter 1 has stakes | **holds** | Promise kept by expert, talker and never-talks: dossier connected on day 56–63, frost on day 70. Missed by average (day 86–93), non-bottleneck (day 78–81) and careless (day 144–198). |
| No mission is unwinnable at the debt floor | **holds for the Checks; recovery fails since the directie advance** | Probe (`floor_probe`, seeds 11 and 12, the best fix at the region's maturity): every tier-1 problem passes its Check at the floor. One exception: `inverters_tripping` on seed 11, +1.4 % against the 2 % noise. Careless at the floor: 59 of 265 and 49 of 233 Checks passed; mains completed there. **The advance makes recovery practically impossible for careless:** € 233 000 and € 250 000 owed at the horizon; 80–88 % of play at the floor (42 % and 40 % on this code before the advance landed); never above € −38 926 after first reaching it. Backlog 1. |
| Act II mains are reachable and completable | **holds** | All six Act II mains and `first_kpi_review` are done by expert (day 173–177), talker (164–180), never-talks (179–194), non-bottleneck (164–173) and average (403–447). Careless: 1 of 6 on seed 11 and 0 on seed 12, where the main chain stops after `fix_incomplete_application` is given up (backlog 2). |

**The route check** (`game/tools/route_check.gd`):
- Tier 1 (`-- tier1`): one fixed route wins **2 of 20** persuasion talks (`joost_output_kpi`, `joost_vacancies`), exactly at `TIER1_RATCHET` 2.
- Always pressing the same button wins 0 of 20 for every position.
- All 20 talks can be won through their offers, with 28 (`linda_replanning`) to 386 distinct winning routes.
- Content (31 talks): one route wins 3 of 31 (10 %). Always button 2 wins 1 of 31.
- `test_dialog_routes.gd`: 8 of 8 pass.

**`wrong_joint_in_van` now shows** (this lane):
- A quarter of the outages send the monteur back to the magazijn for the right joint, an hour each. That is a counted trip, `Network.material_trips_since`.
- Every repair also takes ×1.15 longer while he searches an unstocked van.
- The storingsbord median moves from 18–19 to 27–28 and the uitgiftelijst from 7–8 to 12.
- Outage on-time drops from 0.86–0.93 to 0.61–0.68 (probe, seeds 11–13).
- Each fix takes the trips away. The experts' Checks on it pass at +31 to +46 % on-time.

## Tuning backlog (from these runs; design and balance calls for Merijn, no code changed for them)

1. **[high] The directie advance has no ceiling, so a careless player never leaves the floor.**
   - Numbers: € 233 000 and € 250 000 owed at the horizon. 80–88 % of play at the floor; it was 40–42 % before the advance.
   - Cause: `game/src/rules/region.gd:525`. Every always-funded experiment past the floor adds to `advance_owed`, and `Missions.always_funded` (`game/src/rules/missions.gd:252`) covers every A3 for the active main. Careless writes many random A3s for the same main.
   - Proposal (pick one):
     - the directie advances one experiment per main at a time, and a failed Check's advance is written off;
     - or cap `advance_owed` at, say, € 25 000, after which only a € 3 000 experiment is paid.
   - Either keeps CLAUDE.md's "recovery is always possible" true.
2. **[high] A player who presses can never win Sanne's talk, and without it the main chain stops.**
   - Careless, seed 12: `sanne_checker` was had 20 times and ended "heard" every time. `fix_incomplete_application` was given up on day 242, and Act II was never reached.
   - Cause: the talk (`content/dialogs.yaml:1567`) needs listening. Careless presses, then listens only by the persona's rule.
   - In the real game the talk can be retried. Whether a cynical presser should ever get through is a dialog call, and dialogs wait on Merijn. Proposal: after N ruined or heard tries, the coach (main quest only) asks one question that points at listening.
3. **[medium] The fork's lesson barely shows in the stream's flow.**
   - With `incomplete_application` active, intake runs at 1.03. Fixing it adds about 1.3 per week (≈ 5 %) after 120 days, inside the seed noise (25.5–30 per week).
   - The debrief still says "er gaan nu méér aansluitingen per week door" (`content/missions.yaml:359`).
   - Cause: `content/problems_tier1.yaml:50` (ftr −0.2) against 30.5 arrivals per week and intake capacity 29.5 → 34.5.
   - After the fix, intake (0.88) and Werkvoorbereiding (0.86) nearly tie, so the constraint flips between runs. The "niet het knelpunt" note shows on 1 of 2 control runs; `game/src/rules/region.gd:623` needs a capacity gain under 1 %.
   - Proposal (pick one):
     - make the intake overload clearer: ftr −0.3, or connection demand growing with the energy transition;
     - or let the debrief speak of capacity and the El Amrani dossier instead of the weekly count.
4. **[medium] The expert's best fix for `installer_not_ready` sometimes fails on noise.**
   - `readiness_check` (fit 1.0, eff 0.9) on lead time: +1.4 % (expert, seed 11) and +0.1 % (never-talks, seed 12) against `Pdca.CHECK_NOISE` 0.02. It passes on the retry at day 61.
   - Cause: lead time moves little while intake is the constraint (`content/problems_tier1.yaml:76`, kpi lead_time).
   - Proposal: predict on `wip_age` or first-time-right for this problem, or measure the Check's lead time on the reworked orders only.
5. **[medium] `inverters_tripping` at the debt floor.**
   - The best fix gains +1.4 % first-time-right on seed 11 (bad period: availability −3 %), against 2 % noise. +7.6 % on seed 12.
   - Careless gave it up on both seeds (8 failed Checks).
   - Cause: a small first-time-right effect (`content/problems_tier1.yaml:445`).
   - Proposal: check the problem's effect size against its source, or let its Check horizon run longer.
6. **[low] The control persona and `average` both miss the winter.** This is intended: the dossier waits in the intake queue. One consequence: never-talks keeps the promise without a single talk (connected on day 60–61), so the winter rewards flow, not the phone call. If the promise should also need the fourth call (`el_amrani_fourth_call`), make that a design change.
7. **[known] Treadmill and Check-panel findings** (findings 2–5 below) are unchanged from S2-Q. They are not new for the gate.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 177 | 58 | 12 | 21720 | green | € 295.451 | 21/1 | 0 | 0 | 0 | 0 |
| expert | 12 | campaign_done | 173 | 56 | 12 | 21793 | green | € 299.918 | 21/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 474 | 127 | 17 | 24936 | green | € 289.116 | 44/21 | 1 | 25 | 0 | 1 |
| average | 12 | campaign_done | 490 | 120 | 16 | 24156 | green | € 269.146 | 40/29 | 1 | 24 | 0 | 1 |
| careless | 11 | horizon | 1098 | 146 | 14 | 15445 | green | € -50.000 | 67/235 | 1 | 61 | 1 | 44 |
| careless | 12 | horizon | 1100 | 136 | 14 | 12199 | green | € -50.000 | 60/231 | 1 | 54 | 2 | 17 |
| talker | 11 | campaign_done | 164 | 55 | 12 | 21428 | green | € 303.687 | 20/0 | 0 | 0 | 0 | 0 |
| talker | 12 | campaign_done | 181 | 58 | 12 | 21778 | green | € 301.874 | 21/0 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 179 | 65 | 12 | 16599 | green | € 253.168 | 21/0 | 0 | 1 | 0 | 4 |
| never-talks | 12 | campaign_done | 194 | 67 | 12 | 16543 | green | € 239.362 | 21/1 | 0 | 0 | 0 | 7 |
| non-bottleneck | 11 | campaign_done | 164 | 54 | 12 | 21150 | green | € 304.574 | 20/0 | 1 | 0 | 0 | 0 |
| non-bottleneck | 12 | campaign_done | 173 | 53 | 12 | 21013 | green | € 295.400 | 20/0 | 1 | 0 | 0 | 0 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## The story per run (Phase 2 gate)

| persona | seed | fork: first | dead ends by day 100 | El Amrani connected (day) | winter | Act II mains done | Act II done on day | throughput/wk, lead (d) at day 100 | directie advance (most owed) |
|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | incomplete_application | 0 | 60 | kept | 6 of 6 | 177 | 27.0, 48 | € 0 |
| expert | 12 | incomplete_application | 0 | 56 | kept | 6 of 6 | 173 | 32.8, 53 | € 0 |
| average | 11 | installer_not_ready | 0 | 93 | missed | 6 of 6 | 403 | 15.5, 50 | € 0 |
| average | 12 | installer_not_ready | 0 | 86 | missed | 6 of 6 | 447 | 34.8, 59 | € 0 |
| careless | 11 | incomplete_application | 0 | 144 | missed | 1 of 6 | – | 20.8, 50 | € 232.981 |
| careless | 12 | incomplete_application | 0 | 198 | missed | 0 of 6 | – | 31.8, 64 | € 250.297 |
| talker | 11 | incomplete_application | 0 | 60 | kept | 6 of 6 | 164 | 27.5, 49 | € 0 |
| talker | 12 | incomplete_application | 0 | 63 | kept | 6 of 6 | 180 | 33.8, 49 | € 0 |
| never-talks | 11 | incomplete_application | 0 | 60 | kept | 6 of 6 | 179 | 28.5, 50 | € 0 |
| never-talks | 12 | incomplete_application | 0 | 61 | kept | 6 of 6 | 194 | 29.5, 53 | € 0 |
| non-bottleneck | 11 | installer_not_ready | 0 | 81 | missed | 6 of 6 | 164 | 27.8, 49 | € 0 |
| non-bottleneck | 12 | installer_not_ready | 0 | 78 | missed | 6 of 6 | 173 | 33.5, 52 | € 0 |

Winter: kept (connected before the first frost, day 70), missed, or open. The fork: `incomplete_application` is the bottleneck branch, `installer_not_ready` the other.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 26 (1) | none 1, commitment 10,  1, heard 10, partial 4 | 50.2→57.6 | 51.9→57.1 | anouk 33 | – | 18/18 | 1 | 36 | 36 | 11/4/3 | 669 | 11 | € 34.800 | 18/18, 0, 22 |
| expert | 12 | 41 (1) | none 2, commitment 8,  1, heard 24, partial 6 | 50.2→59.1 | 51.9→58.6 | anouk 33 | – | 18/18 | 1 | 35 | 35 | 11/4/3 | 669 | 11 | € 34.800 | 18/18, 0, 22 |
| average | 11 | 41 (1) | none 1, heard 25, commitment 11,  1, partial 3 | 50.2→59.8 | 51.9→56.5 | anouk 32 | – | 18/18 | 27 | 79 | 62 | 11/4/3 | 686 | 13 | € 48.800 | 10/18, 8, 16 |
| average | 12 | 57 (1) | none 3, commitment 7,  1, partial 7, heard 39 | 50.2→60.5 | 51.9→56.1 | femke 30 | – | 18/18 | 26 | 77 | 58 | 11/4/3 | 274 | 12 | € 40.200 | 7/18, 11, 19 |
| careless | 11 | 74 (0) | compliance 4,  1, ruined 25, heard 39, commitment 2, partial 3 | 50.2→47.7 | 51.9→36.7 | dirk 0 | linda (d170), esra (d395) | 3/15 | 61 | 63 | 0 | 0/3/0 | 253 | 4 | € -50.000 | – |
| careless | 12 | 36 (0) | compliance 3,  1, ruined 15, heard 15, none 1, partial 1 | 50.2→46.1 | 51.9→35.1 | dirk 0 | linda (d186) | 3/12 | 55 | 57 | 0 | 0/3/0 | 157 | 3 | € -50.000 | – |
| talker | 11 | 60 (0) | commitment 23,  3, heard 19, partial 10, lifted 3, blocked 2 | 50.2→67.4 | 51.9→68.3 | kees 50 | – | 18/18 | 1 | 35 | 35 | 12/4/2 | 618 | 11 | € 34.800 | 18/18, 0, 22 |
| talker | 12 | 61 (0) | heard 24,  4, commitment 21, partial 8, none 1, lifted 3 | 50.2→67.0 | 51.9→68.1 | kees 50 | – | 18/18 | 1 | 34 | 34 | 13/4/1 | 703 | 11 | € 34.800 | 18/18, 0, 20 |
| never-talks | 11 | 28 (1) | none 1, compliance 12,  1, ruined 10, heard 2, commitment 1, partial 1 | 50.2→41.1 | 51.9→42.2 | linda 4 | linda (d221), esra (d313) | 18/18 | 2 | 57 | 57 | 1/4/13 | 360 | 7 | € 34.800 | 18/18, 0, 35 |
| never-talks | 12 | 31 (1) | none 1, compliance 12,  1, ruined 11, heard 4, commitment 1, partial 1 | 50.2→41.2 | 51.9→42.2 | linda 0 | linda (d215), esra (d320) | 18/18 | 1 | 58 | 58 | 1/4/13 | 398 | 6 | € 34.800 | 18/18, 0, 36 |
| non-bottleneck | 11 | 26 (1) | none 1, commitment 10,  1, heard 10, partial 4 | 50.2→57.6 | 51.9→57.3 | anouk 35 | – | 18/18 | 1 | 35 | 35 | 11/4/3 | 589 | 11 | € 34.800 | 18/18, 0, 22 |
| non-bottleneck | 12 | 41 (1) | none 2, commitment 8,  1, heard 24, partial 6 | 50.2→59.1 | 51.9→58.6 | anouk 33 | – | 18/18 | 1 | 34 | 34 | 11/4/3 | 671 | 12 | € 34.800 | 18/18, 0, 22 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks | directie advance: most owed / at end |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 2 | 57.0 | 0.0 | 175 | € 297.685 | € 34.800 | 58.3 | 56.6 | 0.0 | 18.0/18.0 | 36.5 | 669 | 11.0 | 33.5 | € 0 / € 0 |
| average | 2 | 123.5 | 1.0 | 482 | € 279.131 | € 44.500 | 60.1 | 55.6 | 0.0 | 8.5/18.0 | 104.5 | 581 | 12.5 | 49.0 | € 0 / € 0 |
| careless | 2 | 141.0 | 1.0 | 1099 | € -50.000 | € -50.000 | 46.9 | 35.9 | 1.5 | 3.0/13.5 | 118.0 | 205 | 3.5 | 55.0 | € 241.639 / € 240.599 |
| talker | 2 | 56.5 | 0.0 | 172 | € 302.781 | € 34.800 | 67.2 | 67.5 | 0.0 | 18.0/18.0 | 35.5 | 661 | 11.0 | 60.5 | € 0 / € 0 |
| never-talks | 2 | 66.0 | 0.0 | 186 | € 246.265 | € 34.800 | 41.2 | 35.5 | 2.0 | 18.0/18.0 | 59.0 | 405 | 6.5 | 29.5 | € 0 / € 0 |
| non-bottleneck | 2 | 53.5 | 1.0 | 169 | € 299.987 | € 34.800 | 58.3 | 56.6 | 0.0 | 18.0/18.0 | 35.5 | 630 | 11.5 | 33.5 | € 0 / € 0 |

Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon). The directie advance: what an experiment cost past the debt floor, repaid first from income (Region.advance_owed).

## Monday's closing talk (`ends_with_talk`)

| persona | seed | mission | talk | had on day | goal met, day held open | completed on day | completed after the talk | outcome |
|---|---|---|---|---|---|---|---|---|
| expert | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| expert | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| average | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| talker | 11 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| talker | 12 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | heard |
| never-talks | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| non-bottleneck | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| non-bottleneck | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |

Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.

## Findings (22), ranked by severity

### 1. [critical] Dead end: talk_never_won

- **Category:** stuck · **occurrences:** 1 · **seen in:** careless/12
- **Detail:** sanne_checker: 20 talks, still heard
- **Affects:** fix_incomplete_application
- **Reproduce:** persona `careless`, seed 12, mission `fix_incomplete_application`, day 242
- **Proposed fix:** Investigate the detail; it should not happen.

### 2. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 7 · **seen in:** average/11, average/12, careless/11, careless/12, talker/12, never-talks/11, never-talks/12
- **Detail:** average/11: 78 of 122 completed missions were re-runs of a faded fix; the campaign took 474 days (campaign_done) against the expert's 175
- **Affects:** average/11: 78/122, average/12: 72/115, careless/11: 123/146, careless/12: 118/136, talker/12: 16/53, never-talks/11: 22/60, never-talks/12: 23/62
- **Reproduce:** persona `average`, seed 11, day 474
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 3. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 117 · **seen in:** expert/11, expert/12, average/11, average/12, careless/11, careless/12, talker/11, talker/12, never-talks/11, never-talks/12, non-bottleneck/11, non-bottleneck/12
- **Detail:** cm standard_designs, predicted throughput +8.2 % (fix), problem KPI throughput +8.2 % (fix), -32.3 % (before/after), capacity +26.2 % (fix), eff 0.90, lesson cause_right
- **Affects:** silent_meter ×15, custom_design ×14, planning_reshuffle ×14, status_callers ×12, wrong_joint_in_van ×10, installer_not_ready ×8, not_at_home ×7, knowledge_drain ×6, double_visits ×6, unused_capacity ×5, done_but_not_closed ×4, overtime_planning ×3, permits_in_batches ×3, inverters_tripping ×3 …
- **Reproduce:** persona `expert`, seed 11, mission `fix_custom_design`, day 19
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 4. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 30 · **seen in:** average/11, average/12, careless/11, careless/12
- **Detail:** cm appointment_reminder, predicted on_time +25.8 % (fix), problem KPI on_time +25.8 % (fix), -4.1 % (before/after), capacity +21.0 % (fix), eff 0.00, lesson mismatch
- **Affects:** inverters_tripping ×7, installer_not_ready ×7, planning_reshuffle ×6, knowledge_drain ×5, transformer_wait, custom_design, grid_study_queue, silent_meter, not_at_home
- **Reproduce:** persona `average`, seed 11, mission `repair_knowledge_drain`, day 92
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 5. [high] Check passes while the problem's own KPI got worse (prediction named another KPI)

- **Category:** contradiction · **occurrences:** 2 · **seen in:** average/12
- **Detail:** cm tap_review_per_neighbourhood, predicted capacity +12.8 % (fix), problem KPI first_time_right -8.0 % (fix), +72.2 % (before/after), capacity +12.8 % (fix), eff 0.90, lesson cause_right
- **Affects:** inverters_tripping, unused_capacity
- **Reproduce:** persona `average`, seed 12, mission `fix_inverters_tripping`, day 148
- **Proposed fix:** Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'.

### 6. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** 146 missions after 1098 days
- **Affects:** horizon ×2
- **Reproduce:** persona `careless`, seed 11, day 1098
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 7. [high] The expert's best countermeasure fails the Check

- **Category:** balance · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** cm readiness_check (tier 1) eff 0.90, level full
- **Affects:** installer_not_ready
- **Reproduce:** persona `expert`, seed 11, mission `fix_installer_not_ready`, day 48
- **Proposed fix:** Give the problem a tier-1 countermeasure whose fit x full multiplier reaches 0.5, or raise the fit.

### 8. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 7 · **seen in:** careless/11, careless/12
- **Detail:** 8 failed Checks on inverters_tripping
- **Affects:** repair_inverters_tripping ×2, fix_inverters_tripping ×2, fix_wrong_joint, repair_knowledge_drain, save_henks_knowledge
- **Reproduce:** persona `careless`, seed 11, mission `repair_inverters_tripping`, day 397
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 9. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 94 · **seen in:** careless/11, careless/12
- **Detail:** cm delegated_approval, predicted capacity +14.7 % (fix), problem KPI throughput +7.4 % (fix), +43.5 % (before/after), capacity +14.7 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** permits_in_batches ×15, silent_meter ×12, planning_reshuffle ×11, overtime_planning ×11, installer_not_ready ×8, wrong_joint_in_van ×7, custom_design ×6, double_visits ×6, not_at_home ×5, knowledge_drain ×5, status_callers ×2, inverters_tripping ×2, done_but_not_closed ×2, digging_damage …
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 10. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 47 · **seen in:** expert/11, expert/12, average/11, average/12, careless/11, careless/12, talker/11, talker/12, never-talks/11, never-talks/12, non-bottleneck/11, non-bottleneck/12
- **Detail:** cm tap_review_per_neighbourhood, predicted first_time_right +8.9 % (fix), problem KPI first_time_right +8.9 % (fix), +3.2 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** status_callers ×20, inverters_tripping ×13, not_at_home ×5, planning_reshuffle ×3, installer_not_ready ×2, double_visits, incomplete_application, custom_design, overtime_planning
- **Reproduce:** persona `expert`, seed 11, mission `fix_inverters_tripping`, day 49
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 11. [medium] average play gets lost searching for clues

- **Category:** balance · **occurrences:** 2 · **seen in:** average/11, average/12
- **Detail:** after the persona's own search (every tool at the step, four at its two neighbours) the problem was still unspotted or without evidence
- **Affects:** silo_kpis (14 actions, active, 3 clues), unused_capacity (10 actions, active, 3 clues)
- **Reproduce:** persona `average`, seed 11, mission `fix_silo_kpis`, day 347
- **Proposed fix:** Key clues sit at another step or stream than the problem (status_callers: intake/design; grid_study_queue: depth chain). Add a hidden_signal hint or a coach insight that names the place of the first key clue.

### 12. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 129 distinct lines over 306 expert asks; 6 lines reach 5+ missions, e.g. "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" in 10 missions. Insights: 87 of 306 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 13. [medium] Budget piles up: rewards far exceed what there is to spend

- **Category:** balance · **occurrences:** 1 · **seen in:** expert/12
- **Detail:** expert ends with €299918 after spending €72700 on countermeasures
- **Reproduce:** persona `expert`, seed 12, day 173
- **Proposed fix:** Pdca.budget_for (up to €18.000 per problem) plus mission budgets outrun countermeasure costs; lower BUDGET_BASE or make budget buy something (extra staff, training) so it matters.

### 14. [low] Slow missions for careless play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 117 · **seen in:** careless/11, careless/12
- **Detail:** fix_custom_design took 56 days, 4 Checks, 3 gemba actions
- **Affects:** fix_silent_meter (56 d) ×12, fix_custom_design (56 d) ×8, fix_permits_in_batches (56 d) ×8, fix_wrong_joint (56 d) ×8, fix_overtime_planning (56 d) ×7, fix_double_visits (56 d) ×7, fix_planning_reshuffle (56 d) ×6, fix_planning_reshuffle (70 d) ×6, save_henks_knowledge (56 d) ×5, fix_installer_not_ready (70 d) ×4, fix_permits_in_batches (70 d) ×4, fix_not_at_home (56 d) ×3, fix_installer_not_ready (84 d) ×3, fix_double_visits (42 d) ×2 …
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 0
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 15. [low] careless could not press a needed talk to a yes

- **Category:** people · **occurrences:** 61 · **seen in:** careless/11, careless/12
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_checker: pushed 5 times ×26, talk petra_batch: pushed 5 times ×15, talk gert_klic: pushed 5 times ×10, talk marco_wasted_trips: pushed 5 times ×8, talk henk_camera: pushed 5 times ×2
- **Reproduce:** persona `careless`, seed 11, mission `fix_incomplete_application`, day 85
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 16. [low] Slow missions for average play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 16 · **seen in:** average/11, average/12
- **Detail:** repair_status_callers took 43 days, 3 Checks, 0 gemba actions
- **Affects:** repair_status_callers (43 d), fix_transformer_wait (57 d), repair_inverters_tripping (42 d), fix_silo_kpis (114 d), fix_wrong_joint (42 d), repair_custom_design (42 d), fix_wrong_joint (43 d), fix_planning_reshuffle (42 d), fix_incomplete_application (44 d), fix_inverters_tripping (72 d), fix_installer_not_ready (84 d), fix_permits_in_batches (56 d), fix_grid_study_queue (70 d), fix_transformer_wait (33 d) …
- **Reproduce:** persona `average`, seed 11, mission `repair_status_callers`, day 204
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 17. [low] never-talks could not press a needed talk to a yes

- **Category:** people · **occurrences:** 11 · **seen in:** never-talks/11, never-talks/12
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_kpi: pushed 5 times ×7, talk marco_wasted_trips: pushed 5 times ×4
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_installer_not_ready`, day 57
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 18. [low] Deadline missed: winter_el_amrani

- **Category:** deadline · **occurrences:** 6 · **seen in:** average/11, average/12, careless/11, careless/12, non-bottleneck/11, non-bottleneck/12
- **Detail:** failed on day 76 (taken on: true), closes []
- **Affects:** average ×2, careless ×2, non-bottleneck ×2
- **Reproduce:** persona `average`, seed 11, mission `winter_el_amrani`, day 76
- **Proposed fix:** Working as designed (a missed deadline closes a door); see the orphan finding for what happens to its problem.

### 19. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 5 · **seen in:** average/11, average/12, careless/11, careless/12, never-talks/11
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 25, average/12: 24, careless/11: 61, careless/12: 54, never-talks/11: 1
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 20. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** careless spends 88 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11, careless/12
- **Reproduce:** persona `careless`, seed 11, day 128
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 21. [low] Slow missions for never-talks play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 1 · **seen in:** never-talks/12
- **Detail:** fix_installer_not_ready took 34 days, 2 Checks, 4 gemba actions
- **Affects:** fix_installer_not_ready (34 d)
- **Reproduce:** persona `never-talks`, seed 12, mission `fix_installer_not_ready`, day 33
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 22. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 92 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless | talker | never-talks |
|---|---|---|---|---|---|---|
| training_mon | training | 1.0 (2) | 1.0 (2) | – | 1.0 (2) | 1.0 (2) |
| training_tue | training | 1.0 (2) | 1.0 (2) | – | 1.0 (2) | 1.0 (2) |
| training_wed | training | 1.0 (2) | 1.0 (2) | – | 1.0 (2) | 1.0 (2) |
| training_thu | training | 1.3 (2) | 1.4 (2) | – | 1.3 (2) | 1.3 (2) |
| training_fri | training | 0.0 (2) | 0.0 (2) | – | 0.0 (2) | 0.0 (2) |
| walk_connections | main | 0.0 (2) | 0.0 (2) | – | 0.1 (2) | 0.0 (2) |
| fix_custom_design | main | 14.3 (2) | 17.9 (4) | 57.6 (11) | 14.2 (2) | 14.3 (2) |
| fix_incomplete_application | main | 14.2 (2) | 36.0 (2) | 71.2 (2) | 14.3 (2) | 14.2 (2) |
| fix_installer_not_ready | main | 21.3 (2) | 35.3 (4) | 68.8 (9) | 14.3 (2) | 29.4 (2) |
| fix_status_callers | main | 14.2 (2) | 14.2 (3) | 70.2 (2) | 14.2 (2) | 14.3 (2) |
| fix_done_but_not_closed | main | 14.2 (2) | 21.4 (2) | 76.5 (2) | 14.3 (2) | 14.2 (2) |
| winter_el_amrani | milestone | 12.4 (2) | – | – | 6.3 (2) | 17.9 (2) |
| review_100_days | milestone | 0.2 (2) | 0.4 (2) | 0.0 (2) | 0.2 (2) | 0.2 (2) |
| fix_digging_damage | main | 14.2 (2) | 14.3 (3) | 106.7 (2) | 14.2 (2) | 14.3 (2) |
| fix_revision_backlog | main | 14.3 (2) | 14.3 (4) | – | 14.3 (2) | 14.3 (2) |
| fix_grid_study_queue | main | 14.8 (2) | 32.9 (3) | – | 14.3 (2) | 14.3 (2) |
| fix_transformer_wait | main | 14.8 (2) | 44.8 (2) | – | 22.9 (2) | 14.2 (2) |
| fix_unused_capacity | main | 17.4 (2) | 37.4 (2) | – | 16.0 (2) | 14.4 (2) |
| fix_silo_kpis | main | 16.5 (2) | 75.1 (2) | – | 14.5 (2) | 23.7 (2) |
| first_kpi_review | milestone | 0.0 (2) | 0.1 (2) | – | 0.0 (2) | 0.0 (2) |
| walk_outages | side | 0.7 (2) | 0.8 (2) | 1.4 (2) | 0.7 (2) | 0.6 (2) |
| walk_meters | side | 0.9 (2) | 0.7 (2) | 1.4 (2) | 0.9 (2) | 0.9 (2) |
| fix_wrong_joint | side | 14.6 (2) | 23.7 (9) | 58.9 (11) | 14.6 (2) | 14.5 (3) |
| fix_not_at_home | side | 14.9 (2) | 24.0 (3) | 54.2 (6) | 14.9 (2) | 14.9 (2) |
| fix_silent_meter | side | 14.3 (2) | 17.8 (8) | 58.0 (16) | 14.3 (2) | 14.3 (2) |
| fix_permits_in_batches | side | 14.2 (2) | 28.3 (5) | 63.3 (16) | 14.2 (2) | 14.2 (2) |
| look_at_grid_study | side | 0.3 (2) | 0.3 (2) | 0.8 (1) | 0.3 (2) | 0.3 (2) |
| fix_inverters_tripping | side | 14.3 (2) | 35.8 (4) | 70.6 (2) | 14.4 (2) | 14.3 (2) |
| save_henks_knowledge | side | 14.3 (2) | 14.3 (2) | 62.3 (7) | 14.3 (2) | 14.3 (2) |
| fix_planning_reshuffle | side | 21.8 (2) | 24.8 (4) | 63.7 (15) | 14.9 (2) | 14.8 (2) |
| talk_netplanner | side | 0.3 (2) | 0.5 (2) | 1.1 (2) | 0.0 (2) | 0.3 (2) |
| lsw_gemba_round | side | 0.3 (23) | 0.3 (66) | 0.2 (147) | 0.3 (23) | 0.3 (25) |
| fix_double_visits | side | – | – | 50.0 (11) | – | – |
| fix_overtime_planning | side | – | – | 50.7 (10) | – | – |

Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.

## Checks

| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted (fix) | KPI | Δ KPI (fix) | Δ KPI before→after | Δ capacity (fix) | flags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | training_tray | 1 | one_tray_fifo | 0.90 | yes | cause_right | capacity | +10.8 % | capacity | +10.8 % | +10.8 % | +10.8 % |  |
| expert | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | +8.2 % | throughput | +8.2 % | -32.3 % | +26.2 % | trend_hides_gain |
| expert | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | +33.8 % | on_time | +33.8 % | -0.3 % | +14.8 % |  |
| expert | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +34.1 % | first_time_right | +34.1 % | +47.5 % | +4.7 % |  |
| expert | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +19.4 % | first_time_right | +19.4 % | -11.1 % | +8.1 % | trend_hides_gain |
| expert | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +18.4 % | capacity | +18.4 % | +18.4 % | +18.4 % |  |
| expert | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +7.9 % | lead_time | +7.9 % | +16.4 % | +0.0 % |  |
| expert | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +20.8 % | on_time | +20.8 % | -3.6 % | +19.2 % |  |
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +11.9 % | first_time_right | +11.9 % | -0.3 % | +13.7 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | no | not_moved | lead_time | +1.4 % | lead_time | +1.4 % | +16.3 % | +0.0 % |  |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +8.9 % | first_time_right | +8.9 % | +3.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | installer_not_ready | 2 | readiness_check | 0.90 | yes | cause_right | lead_time | +10.1 % | lead_time | +10.1 % | -63.7 % | +0.0 % | trend_hides_gain |
| expert | status_callers | 1 | milestone_mail_by_hand | 0.68 | yes | cause_right | on_time | +6.5 % | on_time | +6.5 % | -8.2 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.8 % | lead_time | +21.8 % | +19.5 % | +0.0 % |  |
| expert | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +40.7 % | on_time | +40.7 % | -2.7 % | +18.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +9.0 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.9 % | capacity | +41.9 % | +41.9 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +43.8 % | wip_age | +43.8 % | +4.8 % | +0.0 % |  |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +13.3 % | throughput | +13.3 % | +0.0 % | +0.0 % |  |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +5.5 % | first_time_right | +5.5 % | +5.1 % | -3.8 % |  |
| expert | status_callers | 1 | proactive_status_updates | 0.90 | yes | cause_right | on_time | +14.5 % | on_time | +14.5 % | -40.7 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +5.5 % | throughput | +5.5 % | -21.5 % | +14.7 % | trend_hides_gain |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +18.3 % | first_time_right | +18.3 % | -10.5 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | lead_time | +5.3 % | on_time | +22.5 % | +2.5 % | +9.3 % |  |
| average | installer_not_ready | 1 | backup_job_per_day | 0.54 | yes | cause_right | lead_time | +4.0 % | lead_time | +4.0 % | +8.6 % | +0.0 % |  |
| average | silent_meter | 1 | appointment_reminder | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +4.7 % | +0.0 % |  |
| average | knowledge_drain | 1 | henks_one_point_lessons | 0.54 | yes | cause_right | on_time | +20.9 % | on_time | +20.9 % | -3.7 % | +12.4 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | no | not_moved | lead_time | +1.6 % | capacity | +9.5 % | +9.5 % | +9.5 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +11.6 % | first_time_right | +11.6 % | -19.0 % | +12.3 % | trend_hides_gain |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +65.0 % | first_time_right | +65.0 % | +4.8 % | +0.0 % |  |
| average | incomplete_application | 2 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +18.1 % | capacity | +18.1 % | +18.1 % | +18.1 % |  |
| average | inverters_tripping | 1 | tap_trial_one_station | 0.54 | yes | cause_right | first_time_right | +4.1 % | first_time_right | +4.1 % | -1.5 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | no | not_moved | first_time_right | -3.4 % | lead_time | +16.1 % | -4.0 % | +0.0 % |  |
| average | status_callers | 1 | milestone_mail_by_hand | 0.68 | yes | cause_right | on_time | +7.0 % | on_time | +7.0 % | -9.2 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +33.1 % | on_time | +33.1 % | -1.5 % | +9.3 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +11.0 % | lead_time | +11.0 % | +9.2 % | +0.0 % |  |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | no | not_moved | throughput | -4.5 % | lead_time | +9.7 % | -46.3 % | +0.0 % |  |
| average | knowledge_drain | 1 | appointment_reminder | 0.00 | no | mismatch | on_time | +25.8 % | on_time | +25.8 % | -4.1 % | +21.0 % | failed_but_kpi_improved |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +11.2 % | lead_time | +11.2 % | +27.6 % | +0.0 % |  |
| average | knowledge_drain | 2 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +36.9 % | on_time | +36.9 % | -3.1 % | +21.0 % |  |
| average | digging_damage | 1 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | +42.4 % | +4.7 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | wip_age | +5.4 % | first_time_right | +57.4 % | -5.0 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +8.7 % | lead_time | +8.7 % | +3.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +25.3 % | on_time | +25.3 % | -3.8 % | +9.4 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +14.7 % | throughput | +14.7 % | -1.9 % | +14.7 % |  |
| average | status_callers | 1 | milestone_mail_by_hand | 0.68 | yes | cause_right | on_time | +13.2 % | on_time | +13.2 % | -0.4 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | digging_damage | 1 | contractor_briefing | 0.56 | yes | cause_right | capacity | +4.7 % | capacity | +4.7 % | -11.7 % | +4.7 % | trend_hides_gain |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.8 % | capacity | +41.8 % | +41.8 % | +41.8 % |  |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +25.3 % | on_time | +25.3 % | -10.6 % | +9.4 % | trend_hides_gain |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | no | not_moved | wip_age | +0.0 % | first_time_right | +31.3 % | +34.0 % | +0.0 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +2.1 % | throughput | +2.1 % | +30.9 % | +14.7 % |  |
| average | planning_reshuffle | 2 | planning_with_fault_windows | 0.77 | yes | cause_right | first_time_right | +25.9 % | first_time_right | +25.9 % | -20.1 % | +3.5 % | trend_hides_gain |
| average | status_callers | 1 | realistic_promise | 0.63 | no | not_moved | throughput | -11.9 % | on_time | +45.2 % | +3.4 % | +0.0 % |  |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | no | not_moved | on_time | -4.3 % | wip_age | +27.9 % | +4.4 % | +0.0 % |  |
| average | status_callers | 2 | proactive_status_updates | 0.90 | no | not_moved | first_time_right | -0.3 % | on_time | +61.1 % | -49.0 % | +0.0 % |  |
| average | inverters_tripping | 1 | poka_yoke_application | 0.00 | no | mismatch | lead_time | +13.9 % | first_time_right | +10.2 % | -8.3 % | +0.0 % | failed_but_kpi_improved |
| average | transformer_wait | 2 | framework_contracts | 0.81 | no | not_moved | on_time | -2.6 % | wip_age | +22.2 % | -12.7 % | +0.0 % |  |
| average | status_callers | 3 | proactive_status_updates | 0.90 | yes | cause_right | on_time | +102.1 % | on_time | +102.1 % | +96.1 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | no | not_moved | on_time | -0.6 % | first_time_right | +8.5 % | +9.1 % | +0.0 % |  |
| average | transformer_wait | 3 | strategic_transformer_stock | 0.40 | no | too_early | wip_age | +4.0 % | wip_age | +4.0 % | -6.4 % | +0.0 % | failed_but_kpi_improved |
| average | inverters_tripping | 3 | smart_meter_voltage_data | 0.72 | yes | cause_right | first_time_right | +5.0 % | first_time_right | +5.0 % | +0.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +39.6 % | on_time | +39.6 % | -12.7 % | +9.4 % | trend_hides_gain |
| average | transformer_wait | 4 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +37.2 % | wip_age | +37.2 % | +5.8 % | +0.0 % |  |
| average | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | +6.1 % | lead_time | +6.1 % | +17.7 % | +0.0 % |  |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | +8.7 % | throughput | +8.7 % | -20.0 % | +0.0 % | trend_hides_gain |
| average | silo_kpis | 1 | daytime_outage_crew | 0.00 | no | mismatch | capacity | +0.0 % | first_time_right | +0.0 % | -25.3 % | +0.0 % |  |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | yes | cause_right | first_time_right | +3.7 % | first_time_right | +3.7 % | +55.3 % | -3.5 % |  |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | no | not_moved | throughput | +0.0 % | on_time | +34.4 % | +9.1 % | +9.4 % |  |
| average | wrong_joint_in_van | 2 | standard_van_stock | 0.72 | no | not_moved | throughput | +0.0 % | on_time | +51.1 % | -14.1 % | +14.9 % |  |
| average | wrong_joint_in_van | 3 | two_bin_van_kanban | 0.50 | yes | cause_right | on_time | +42.7 % | on_time | +42.7 % | -5.4 % | +11.2 % | trend_hides_gain |
| average | silo_kpis | 1 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +25.0 % | first_time_right | +25.0 % | +54.9 % | -5.0 % |  |
| average | custom_design | 1 | revision_at_source | 0.00 | no | mismatch | lead_time | +11.3 % | throughput | +6.4 % | -7.1 % | +28.7 % | failed_but_kpi_improved |
| average | custom_design | 2 | standard_designs | 0.90 | no | not_moved | first_time_right | -12.9 % | throughput | +19.0 % | +46.2 % | +28.6 % |  |
| average | inverters_tripping | 1 | study_overtime_sprint | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -0.5 % | +0.0 % |  |
| average | custom_design | 3 | standard_designs | 0.90 | yes | cause_right | capacity | +25.7 % | throughput | +17.5 % | -40.8 % | +25.7 % | trend_hides_gain |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +15.4 % | first_time_right | +15.4 % | -8.6 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | revision_backlog | 1 | revision_at_source | 0.50 | yes | cause_right | capacity | +26.0 % | capacity | +26.0 % | +6.5 % | +26.0 % |  |
| average | not_at_home | 1 | proactive_status_updates | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +3.3 % | +0.0 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +13.6 % | first_time_right | +13.6 % | -14.4 % | +16.9 % | trend_hides_gain |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +16.9 % | first_time_right | +16.9 % | -18.6 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | silo_kpis | 1 | connections_wip_limit | 0.72 | no | not_moved | wip_age | +0.9 % | first_time_right | +26.8 % | +2.2 % | -3.6 % |  |
| average | silo_kpis | 2 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +27.8 % | first_time_right | +27.8 % | +7.9 % | -3.6 % |  |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +16.1 % | first_time_right | +16.1 % | +10.1 % | +16.9 % |  |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 42 of 43 passed; average 84 of 134 passed; careless 127 of 593 passed; talker 41 of 41 passed; never-talks 42 of 43 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | no | yes | +0.2 % |
| expert | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 12 | fix_incomplete_application | fix_installer_not_ready | no | no | -0.2 % |
| average | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +18.1 % |
| average | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| average | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| careless | 11 | fix_incomplete_application | fix_incomplete_application | no | no | +70.0 % |
| careless | 11 | fix_incomplete_application | fix_installer_not_ready | no | yes | +1.7 % |
| careless | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | -35.5 % |
| careless | 12 | fix_incomplete_application | fix_installer_not_ready | no | no | +36.9 % |
| talker | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| talker | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| talker | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| never-talks | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| never-talks | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| never-talks | 12 | fix_incomplete_application | fix_installer_not_ready | no | yes | +1.5 % |
| non-bottleneck | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +18.4 % |
| non-bottleneck | 11 | fix_installer_not_ready | fix_installer_not_ready | no | no | +0.7 % |
| non-bottleneck | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +18.4 % |
| non-bottleneck | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.7 % |

The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.

## Coach

| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |
|---|---|---|---|---|
| go_see | 90 | 38 | 30 | "Als je over een jaar terugkijkt, welk getal wil je dan veranderd hebben?" (7) |
| understand | 72 | 18 | 24 | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" (8) |
| experiment | 60 | 29 | 12 | "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" (10) |
| reflect | 69 | 37 | 21 | "Wat is de volgende kleine stap?" (6) |
| talk | 15 | 7 | 0 | "Wiens idee was het uiteindelijk?" (6) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `kpi_review_due()`: the first quarterly review is played in its scene (first_kpi_review, at the KPI board); the playtester reads Region.board.review_due for it, and the later quarters (tier 2's lsw_kpi_review) are not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.
- `goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).
