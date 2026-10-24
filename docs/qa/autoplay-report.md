# Autoplay report

Generated 2026-10-24T17:28:49 by `game/tools/autoplay.gd` (personas expert, average, careless, talker, never-talks, non-bottleneck, seeds 11, 12, 13). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step ("assisted"). A run that ends with the campaign done plays an epilogue of 182 days with no new work (the persona's audits only), to see which fixes hold.

**Summary:** 1 critical, 6 high, 5 medium, 9 low. Every persona but careless reaches the end of the campaign without a dead end: yes.

## Phase 2 gate, the machine half (PLAN 2.8; S3 lane G-A, retuned by lane T-1, 2026-10-24)

**Runs.** The whole tier 1 on `origin` at 0ec040f plus lane T-1's tuning (Act 0, Act I with the fork, `winter_el_amrani`, `review_100_days`, Act II, `first_kpi_review`, the funding rule, the directie advance and the way back). Five personas plus the `non-bottleneck` control on seeds 11, 12 and 13: eighteen runs, one Godot process at a time. G-A's twelve-run numbers are in git history (this file before T-1).

**What T-1 changed** (the tuning backlog below says which item each one answers):
- The directie advance has a ceiling, `Region.ADVANCE_CEILING` € 25 000 (an estimate). In a bad period it advances the whole of an exempt experiment the region cannot carry, so the region pays none of it. A failed Check's advance is written off: the directie took the risk. In debt the directie also funds a problem's cheapest fix still open (Henk's farewell closes the cheap fixes for the knowledge drain).
- `incomplete_application`: each return also costs the chase (×1.3 intake touch time, an estimate). At the fork the intake runs at 1.16: about 26 (25.9) a week against 30 arriving, 35 once fixed (`Capacity.analyse`, the same on seeds 11–13).
- The fork is one main quest: once a branch is taken, the bottleneck branch's problem is on while it waits, outside the mission slots (`Missions._waiting_fork_branches`, `Region.uncounted`). Before, the control fixed the monteurs against a healthy intake.
- `installer_not_ready` predicts first time right. `inverters_tripping` measures the Check's longest window (`measure_days`, `Region.check_window`).
- `standard_test_trenches` draws on Werkvoorbereiding.
- The Check table shows a change within the Check's noise (2 %) as unchanged.

**The expectations, with the numbers.**

| expectation | verdict | numbers |
|---|---|---|
| Every persona reaches day 100 without a stuck state | **holds** | 0 dead ends by day 100 and 0 engine errors in all 18 runs. Every persona except careless finishes the campaign. Careless gets stuck later, on talks it presses (`linda_replanning` on seed 13; backlog 2). |
| Bottleneck first beats the other branch on flow | **holds, in the Checks and the dossier** | The intake's fix: Check capacity **+35.4 %** on every seed, throughput +7.6 to +21.4 % (expert, talker, never-talks). The monteurs' fix taken first (control): capacity **+0.0 %** on 3 of 3 seeds, throughput −4.4 to +2.9 %, and "niet het knelpunt" shown on **3 of 3** control runs (G-A: 1 of 2), on 3 of 3 for `average` too. The El Amrani dossier: connected on day 60–66 (bottleneck first) against 73–93 (other branch first). At day 100 the stream's weekly count is alike in both orders (27.8 vs 27.8, 33.5 vs 32.3, 28.5 vs 30.0 per week), because by day 47 both branches are fixed in both orders: the gap lives in the 14 days between the two Checks, which the Checks measure. |
| Careful and standardising beats careless in the long term | **holds** | Fixes held after the epilogue: expert 18/18, average 8.3/18, careless 3.7/13 at the 3-year horizon. Budget at the end: € 301 591 vs € 283 476 vs € −48 526. Slipping + recurred: 35 vs 103 vs 100. |
| The talker beats never-talks on trust and morale | **holds** | Trust at the end: 67.3 vs 41.5. Morale: 67.5 vs 35.3. Never-talks loses Linda (day 220–226) and Esra (day 309–324) on all three seeds; the talker loses no one. |
| Winter 1 has stakes | **holds** | Kept by expert, talker and never-talks on 9 of 9 runs (connected on day 60–66, frost on day 70). Missed by the control (day 73–93), average (101–130) and careless (147–623). |
| No mission is unwinnable at the debt floor; recovery is possible | **holds** | Every tier-1 best fix passes its Check at the floor on seeds 11–13 (`floor_probe`); `inverters_tripping` now gains +4.3 to +21 % over 12 probe runs (was +0.8 and +1.4 % on two). Careless at the floor **48, 58 and 65 %** of its samples (G-A: 80–88 %, and 40–42 % before the advance); it leaves the floor 25, 31 and 16 times (G-A: never); most owed € 17 621, € 19 076 and € 25 380 (G-A: € 233 000–250 000), at the horizon € 0–3 500. What still holds careless near the floor is its stuck main chain (talks it presses, backlog 2): Act II is never reached on two seeds, so the open problems keep costing. Experts never touch the advance. |
| Act II mains are reachable and completable | **holds** | All six Act II mains and `first_kpi_review` are done by expert (day 164–173), talker (164–179), never-talks (182–197), non-bottleneck (164–171) and average (380–569). Careless: 1 of 6 on seed 11, 0 on seeds 12 and 13 (backlog 2). |

**The route check** (`game/tools/route_check.gd`, G-A's run; T-1 changed no talk):
- Tier 1 (`-- tier1`): one fixed route wins **2 of 20** persuasion talks (`joost_output_kpi`, `joost_vacancies`), exactly at `TIER1_RATCHET` 2.
- Always pressing the same button wins 0 of 20 for every position.
- All 20 talks can be won through their offers, with 28 (`linda_replanning`) to 386 distinct winning routes.
- Content (31 talks): one route wins 3 of 31 (10 %). Always button 2 wins 1 of 31.

## Tuning backlog (G-A's list, with what T-1 did)

1. **[high, done] The directie advance had no ceiling.** See the advance above: careless now leaves the floor and owes at most about the ceiling. Tests: `test_region.gd` (the ceiling, the whole advance in a bad period, the write-off, the cheapest fix left), `test_gate_tuning.gd` (Henk's case on the real content).
2. **[high, open: dialogs wait on Merijn] A player who presses can never win some talks**, and without them the main chain stops: `linda_replanning` (careless seed 13, 20 tries, blocking `fix_planning_reshuffle` and `fix_installer_not_ready`), `sanne_checker` in G-A's runs. With the advance capped, this is a large part of what keeps careless near the floor. Proposal unchanged: after N ruined or heard tries, the coach (main quest only) asks one question that points at listening.
3. **[medium, done] The fork's lesson in the stream's numbers.** The intake overload is clear (1.20), the control branch meets the intake's problem, the note shows on every control run and the debrief's "méér aansluitingen per week" is what the intake's Check shows (+7.6 to +21 %). After the fix the intake (0.88) and Werkvoorbereiding (0.86) still nearly tie, so the constraint after the fork can read either (no lesson rests on it). Test: `test_gate_tuning.gd`, `test_facts.gd`.
4. **[medium, done] `readiness_check` passes reliably.** It predicts first time right: +11.5 to +89 % on every expert, talker and never-talks run (+22 to +72 % in the probe, both fork orders, seeds 11–15).
5. **[medium, done] `inverters_tripping` at the floor.** Five seasonal complaints a week were too few for an eight-week window; the Check now measures about nine months (+4.3 to +21 %, 12 probe runs). Careless still gives it up (random countermeasures and predictions), as it does other problems.
6. **[low, done] `standard_test_trenches`** draws 10 hours from Werkvoorbereiding (the work orders say where a test trench is needed), not from the account managers.
7. **[open] Fewer outages read as lower throughput.** A per-stream direction ("storingen per week: minder is beter") touches the Check's gain (`Pdca.kpi_gain`), the KPI review (`KpiBoard.improvement`), the Check table and the A3's prediction labels, the repair quests (`Repairs`) and the content schema. That is more than a small change, so it is left for a lane of its own. Where it shows today: the outage and voltage-complaint streams' throughput row in the Check table and at the KPI review.
8. **[low, unchanged] The control persona and `average` miss the winter**, as intended; never-talks keeps the promise without the fourth call.
9. **[known] Treadmill and Check-panel findings** (below) are unchanged from S2-Q.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 164 | 54 | 12 | 20970 | green | € 299.931 | 19/0 | 0 | 0 | 0 | 0 |
| expert | 12 | campaign_done | 173 | 54 | 12 | 21050 | green | € 304.429 | 19/0 | 0 | 0 | 0 | 0 |
| expert | 13 | campaign_done | 164 | 54 | 12 | 20988 | green | € 300.412 | 19/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 506 | 123 | 17 | 24829 | green | € 323.198 | 43/34 | 1 | 28 | 0 | 0 |
| average | 12 | campaign_done | 584 | 148 | 23 | 23997 | green | € 337.753 | 40/30 | 1 | 25 | 0 | 0 |
| average | 13 | campaign_done | 380 | 102 | 16 | 22901 | green | € 189.476 | 35/22 | 1 | 20 | 0 | 0 |
| careless | 11 | horizon | 1097 | 145 | 16 | 15444 | green | € -50.000 | 66/235 | 1 | 59 | 1 | 24 |
| careless | 12 | horizon | 1098 | 138 | 13 | 13657 | green | € -45.579 | 64/235 | 1 | 54 | 1 | 12 |
| careless | 13 | horizon | 1098 | 109 | 3 | 8238 | green | € -50.000 | 35/149 | 1 | 29 | 1 | 30 |
| talker | 11 | campaign_done | 164 | 54 | 12 | 21010 | green | € 301.065 | 19/0 | 0 | 0 | 0 | 0 |
| talker | 12 | campaign_done | 168 | 54 | 12 | 21028 | green | € 302.288 | 19/0 | 0 | 0 | 0 | 0 |
| talker | 13 | campaign_done | 179 | 54 | 12 | 21071 | green | € 303.548 | 19/1 | 0 | 0 | 0 | 0 |
| never-talks | 11 | campaign_done | 197 | 73 | 12 | 15999 | green | € 248.966 | 19/1 | 0 | 0 | 0 | 6 |
| never-talks | 12 | campaign_done | 182 | 66 | 12 | 15931 | green | € 246.146 | 19/0 | 0 | 0 | 0 | 7 |
| never-talks | 13 | campaign_done | 185 | 67 | 12 | 15884 | green | € 245.101 | 19/0 | 0 | 0 | 0 | 10 |
| non-bottleneck | 11 | campaign_done | 166 | 53 | 12 | 20670 | green | € 302.199 | 19/0 | 1 | 0 | 0 | 0 |
| non-bottleneck | 12 | campaign_done | 171 | 53 | 12 | 20670 | green | € 301.677 | 19/0 | 1 | 0 | 0 | 0 |
| non-bottleneck | 13 | campaign_done | 164 | 53 | 12 | 20646 | green | € 297.121 | 19/0 | 1 | 0 | 0 | 0 |

Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.

## The story per run (Phase 2 gate)

| persona | seed | fork: first | dead ends by day 100 | El Amrani connected (day) | winter | Act II mains done | Act II done on day | throughput/wk, lead (d) at day 100 | directie advance (most owed) |
|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | incomplete_application | 0 | 66 | kept | 6 of 6 | 164 | 27.8, 49 | € 0 |
| expert | 12 | incomplete_application | 0 | 63 | kept | 6 of 6 | 173 | 33.5, 55 | € 0 |
| expert | 13 | incomplete_application | 0 | 63 | kept | 6 of 6 | 164 | 28.5, 62 | € 0 |
| average | 11 | installer_not_ready | 0 | 102 | missed | 6 of 6 | 407 | 24.8, 56 | € 0 |
| average | 12 | installer_not_ready | 0 | 101 | missed | 6 of 6 | 569 | 21.8, 58 | € 0 |
| average | 13 | installer_not_ready | 0 | 130 | missed | 6 of 6 | 380 | 23.8, 63 | € 0 |
| careless | 11 | incomplete_application | 0 | 147 | missed | 1 of 6 | – | 22.8, 46 | € 17.621 |
| careless | 12 | installer_not_ready | 0 | 623 | missed | 0 of 6 | – | 29.5, 67 | € 19.076 |
| careless | 13 | incomplete_application | 0 | 191 | missed | 0 of 6 | – | 27.8, 64 | € 25.380 |
| talker | 11 | incomplete_application | 0 | 66 | kept | 6 of 6 | 164 | 27.5, 50 | € 0 |
| talker | 12 | incomplete_application | 0 | 63 | kept | 6 of 6 | 167 | 33.5, 49 | € 0 |
| talker | 13 | incomplete_application | 0 | 63 | kept | 6 of 6 | 179 | 26.3, 57 | € 0 |
| never-talks | 11 | incomplete_application | 0 | 64 | kept | 6 of 6 | 197 | 28.8, 49 | € 0 |
| never-talks | 12 | incomplete_application | 0 | 60 | kept | 6 of 6 | 182 | 25.0, 56 | € 0 |
| never-talks | 13 | incomplete_application | 0 | 63 | kept | 6 of 6 | 185 | 27.3, 56 | € 0 |
| non-bottleneck | 11 | installer_not_ready | 0 | 73 | missed | 6 of 6 | 166 | 27.8, 49 | € 0 |
| non-bottleneck | 12 | installer_not_ready | 0 | 86 | missed | 6 of 6 | 171 | 32.3, 56 | € 0 |
| non-bottleneck | 13 | installer_not_ready | 0 | 93 | missed | 6 of 6 | 164 | 30.0, 56 | € 0 |

Winter: kept (connected before the first frost, day 70), missed, or open. The fork: `incomplete_application` is the bottleneck branch, `installer_not_ready` the other.

## People, talks and fixes

| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | 26 (1) | none 1, commitment 10,  1, heard 10, partial 4 | 50.2→57.6 | 51.9→57.2 | anouk 35 | – | 18/18 | 1 | 33 | 33 | 11/4/3 | 592 | 13 | € 34.800 | 18/18, 0, 20 |
| expert | 12 | 41 (1) | none 2, commitment 8,  1, heard 24, partial 6 | 50.2→59.1 | 51.9→58.6 | anouk 33 | – | 18/18 | 1 | 36 | 36 | 11/4/3 | 592 | 13 | € 34.800 | 18/18, 0, 23 |
| expert | 13 | 23 (1) | none 1, commitment 10,  1, heard 7, partial 4 | 50.2→57.1 | 51.9→56.8 | anouk 35 | – | 18/18 | 1 | 33 | 33 | 11/4/3 | 592 | 13 | € 34.800 | 18/18, 0, 20 |
| average | 11 | 36 (1) | none 2, heard 19, commitment 11,  1, partial 3 | 50.2→59.1 | 51.9→52.9 | anouk 30 | – | 18/18 | 29 | 74 | 52 | 11/4/3 | 533 | 14 | € 48.800 | 7/18, 11, 20 |
| average | 12 | 46 (1) | none 2, commitment 8,  1, partial 6, heard 29 | 50.2→59.6 | 51.9→54.7 | femke 30 | – | 18/18 | 26 | 91 | 73 | 11/4/3 | 350 | 13 | € 37.200 | 8/18, 10, 17 |
| average | 13 | 32 (1) | none 1, partial 6,  1, heard 16, commitment 8 | 50.2→58.0 | 51.9→52.8 | anouk 32 | – | 18/18 | 21 | 68 | 55 | 11/4/3 | 356 | 11 | € 20.148 | 10/18, 8, 23 |
| careless | 11 | 51 (0) | compliance 6,  1, ruined 20, heard 20, partial 3, commitment 1 | 50.2→43.9 | 51.9→34.0 | dirk 0 | linda (d183), marco (d338), esra (d858) | 4/15 | 59 | 61 | 0 | 1/3/0 | 312 | 3 | € -50.000 | – |
| careless | 12 | 32 (0) | compliance 4,  1, ruined 15, heard 10, partial 2 | 50.2→46.6 | 51.9→33.1 | dirk 0 | linda (d186) | 6/12 | 56 | 58 | 0 | 1/5/0 | 220 | 3 | € -50.000 | – |
| careless | 13 | 49 (0) | compliance 3,  1, ruined 15, heard 26, none 4 | 50.2→47.5 | 51.9→34.0 | dirk 0 | – | 1/12 | 32 | 33 | 0 | 0/1/0 | 365 | 2 | € -50.000 | – |
| talker | 11 | 60 (0) | commitment 23,  3, heard 19, partial 10, lifted 3, blocked 2 | 50.2→67.4 | 51.9→68.2 | kees 50 | – | 18/18 | 1 | 33 | 33 | 12/4/2 | 620 | 13 | € 34.800 | 18/18, 0, 20 |
| talker | 12 | 62 (0) | heard 24,  4, commitment 21, partial 9, none 1, lifted 3 | 50.2→67.2 | 51.9→68.3 | kees 50 | – | 18/18 | 1 | 33 | 33 | 13/4/1 | 626 | 13 | € 34.800 | 18/18, 0, 20 |
| talker | 13 | 58 (0) | commitment 23,  4, heard 22, partial 6, lifted 3 | 50.2→67.1 | 51.9→68.1 | kees 50 | – | 18/18 | 1 | 31 | 31 | 14/4/0 | 630 | 13 | € 34.800 | 18/18, 0, 19 |
| never-talks | 11 | 30 (1) | none 1, compliance 12,  1, ruined 10, heard 4, commitment 1, partial 1 | 50.2→41.4 | 51.9→41.7 | linda 0 | linda (d226), esra (d324) | 18/18 | 1 | 62 | 62 | 1/4/13 | 361 | 9 | € 34.800 | 18/18, 0, 33 |
| never-talks | 12 | 31 (1) | none 1, compliance 12,  1, ruined 11, heard 4, commitment 1, partial 1 | 50.2→41.2 | 51.9→42.3 | linda 3 | linda (d224), esra (d309) | 18/18 | 1 | 57 | 57 | 1/4/13 | 361 | 8 | € 34.800 | 18/18, 0, 34 |
| never-talks | 13 | 34 (1) | none 1, compliance 12,  1, ruined 10, heard 8, partial 2 | 50.2→41.8 | 51.9→42.5 | linda 3 | linda (d220), esra (d312) | 18/18 | 1 | 57 | 57 | 1/4/13 | 361 | 8 | € 34.800 | 18/18, 0, 33 |
| non-bottleneck | 11 | 30 (1) | none 1, commitment 10,  1, heard 14, partial 4 | 50.2→58.1 | 51.9→57.2 | anouk 35 | – | 18/18 | 1 | 34 | 34 | 11/4/3 | 592 | 14 | € 34.800 | 18/18, 0, 21 |
| non-bottleneck | 12 | 37 (1) | none 2, commitment 8,  1, heard 20, partial 6 | 50.2→58.5 | 51.9→57.5 | anouk 35 | – | 18/18 | 1 | 35 | 35 | 11/4/3 | 592 | 14 | € 34.800 | 18/18, 0, 22 |
| non-bottleneck | 13 | 23 (1) | none 1, commitment 9,  1, heard 7, partial 5 | 50.2→56.9 | 51.9→56.2 | anouk 35 | – | 18/18 | 1 | 33 | 33 | 11/4/3 | 592 | 13 | € 34.800 | 18/18, 0, 20 |

At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).

## Per persona (mean over seeds)

| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks | directie advance: most owed / at end |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 3 | 54.0 | 0.0 | 167 | € 301.591 | € 34.800 | 57.9 | 56.1 | 0.0 | 18.0/18.0 | 35.0 | 592 | 13.0 | 30.0 | € 0 / € 0 |
| average | 3 | 124.3 | 1.0 | 490 | € 283.476 | € 35.383 | 58.9 | 51.0 | 0.0 | 8.3/18.0 | 103.0 | 602 | 12.7 | 38.0 | € 0 / € 0 |
| careless | 3 | 130.7 | 1.0 | 1098 | € -48.526 | € -50.000 | 46.0 | 33.7 | 1.3 | 3.7/13.0 | 99.7 | 299 | 2.7 | 44.0 | € 20.692 / € 1.833 |
| talker | 3 | 54.0 | 0.0 | 170 | € 302.300 | € 34.800 | 67.3 | 67.5 | 0.0 | 18.0/18.0 | 33.3 | 625 | 13.0 | 60.0 | € 0 / € 0 |
| never-talks | 3 | 68.7 | 0.0 | 188 | € 246.738 | € 34.800 | 41.5 | 35.3 | 2.0 | 18.0/18.0 | 59.7 | 374 | 8.3 | 31.7 | € 0 / € 0 |
| non-bottleneck | 3 | 53.0 | 1.0 | 167 | € 300.332 | € 34.800 | 57.9 | 55.9 | 0.0 | 18.0/18.0 | 35.0 | 592 | 13.7 | 30.0 | € 0 / € 0 |

Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon). The directie advance: what an experiment cost past the debt floor, repaid first from income (Region.advance_owed).

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
| talker | 12 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | heard |
| talker | 13 | training_mon | anouk_seven | before the goal (talk round) | no | 1.4 | yes | commitment |
| never-talks | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| never-talks | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| non-bottleneck | 11 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| non-bottleneck | 12 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |
| non-bottleneck | 13 | training_mon | anouk_seven | 0.4 | yes | 1.4 | yes | none |

Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.

## Findings (21), ranked by severity

### 1. [critical] Dead end: talk_never_won

- **Category:** stuck · **occurrences:** 2 · **seen in:** careless/13
- **Detail:** linda_replanning: 20 talks, still heard
- **Affects:** fix_planning_reshuffle, fix_installer_not_ready
- **Reproduce:** persona `careless`, seed 13, mission `fix_planning_reshuffle`, day 128
- **Proposed fix:** Investigate the detail; it should not happen.

### 2. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 9 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13, never-talks/11, never-talks/12, never-talks/13
- **Detail:** average/11: 73 of 118 completed missions were re-runs of a faded fix; the campaign took 506 days (campaign_done) against the expert's 167
- **Affects:** average/11: 73/118, average/12: 99/143, average/13: 58/97, careless/11: 122/145, careless/12: 119/138, careless/13: 92/109, never-talks/11: 29/68, never-talks/12: 24/61, never-talks/13: 24/62
- **Reproduce:** persona `average`, seed 11, day 506
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 3. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 1 · **seen in:** careless/11
- **Detail:** careless ends at € -50.000 after 1097 days, still falling about € 416 a month; 1 bad periods
- **Affects:** careless/11
- **Reproduce:** persona `careless`, seed 11, day 1097
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 4. [high] The Check panel's before/after table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 146 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13, non-bottleneck/11, non-bottleneck/12, non-bottleneck/13
- **Detail:** cm standard_designs, predicted throughput +8.2 % (fix), problem KPI throughput +8.2 % (fix), -32.3 % (before/after), capacity +26.2 % (fix), eff 0.90, lesson cause_right
- **Affects:** custom_design ×19, planning_reshuffle ×17, installer_not_ready ×14, not_at_home ×12, knowledge_drain ×10, wrong_joint_in_van ×9, status_callers ×9, done_but_not_closed ×9, silent_meter ×9, inverters_tripping ×8, permits_in_batches ×7, silo_kpis ×6, double_visits ×6, unused_capacity ×5 …
- **Reproduce:** persona `expert`, seed 11, mission `fix_custom_design`, day 19
- **Proposed fix:** The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days).

### 5. [high] Check fails while the fix moved the predicted KPI

- **Category:** contradiction · **occurrences:** 34 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm delegated_approval, predicted first_time_right +54.0 % (fix), problem KPI on_time +24.4 % (fix), -4.2 % (before/after), capacity +21.2 % (fix), eff 0.00, lesson mismatch
- **Affects:** inverters_tripping ×13, planning_reshuffle ×9, installer_not_ready ×4, knowledge_drain ×2, wrong_joint_in_van ×2, custom_design ×2, incomplete_application, silent_meter
- **Reproduce:** persona `average`, seed 11, mission `repair_knowledge_drain`, day 92
- **Proposed fix:** A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half').

### 6. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** 145 missions after 1097 days
- **Affects:** horizon ×3
- **Reproduce:** persona `careless`, seed 11, day 1097
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 7. [high] Check passes while the problem's own KPI got worse (prediction named another KPI)

- **Category:** contradiction · **occurrences:** 2 · **seen in:** careless/13
- **Detail:** cm request_permits_daily, predicted throughput +5.5 % (fix), problem KPI lead_time -7.8 % (fix), -7.7 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_wrong
- **Affects:** permits_in_batches, double_visits
- **Reproduce:** persona `careless`, seed 13, mission `fix_permits_in_batches`, day 339
- **Proposed fix:** Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'.

### 8. [medium] A player can fail the Check 8 times in a row without a way out

- **Category:** balance · **occurrences:** 8 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** 8 failed Checks on inverters_tripping
- **Affects:** repair_inverters_tripping ×3, fix_inverters_tripping ×2, fix_permits_in_batches ×2, fix_status_callers
- **Reproduce:** persona `careless`, seed 11, mission `repair_inverters_tripping`, day 381
- **Proposed fix:** After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note.

### 9. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 129 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** cm delegated_approval, predicted capacity +14.7 % (fix), problem KPI throughput +5.8 % (fix), +25.5 % (before/after), capacity +14.7 % (fix), eff 0.55, lesson cause_wrong
- **Affects:** silent_meter ×16, wrong_joint_in_van ×16, double_visits ×14, planning_reshuffle ×12, knowledge_drain ×12, overtime_planning ×12, custom_design ×10, installer_not_ready ×10, permits_in_batches ×9, not_at_home ×7, incomplete_application ×6, inverters_tripping ×4, status_callers
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 10. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 52 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13, talker/11, talker/12, talker/13, never-talks/11, never-talks/12, never-talks/13, non-bottleneck/11, non-bottleneck/12, non-bottleneck/13
- **Detail:** cm readiness_check, predicted first_time_right +42.7 % (fix), problem KPI first_time_right +42.7 % (fix), +9.3 % (before/after), capacity +0.0 % (fix), eff 0.90, lesson cause_right
- **Affects:** inverters_tripping ×19, status_callers ×16, installer_not_ready ×5, overtime_planning ×4, not_at_home ×2, planning_reshuffle ×2, double_visits ×2, incomplete_application ×2
- **Reproduce:** persona `expert`, seed 11, mission `fix_installer_not_ready`, day 48
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 11. [medium] Budget piles up: rewards far exceed what there is to spend

- **Category:** balance · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** expert ends with €299931 after spending €59700 on countermeasures
- **Reproduce:** persona `expert`, seed 11, day 164
- **Proposed fix:** Pdca.budget_for (up to €18.000 per problem) plus mission budgets outrun countermeasure costs; lower BUDGET_BASE or make budget buy something (extra staff, training) so it matters.

### 12. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 144 distinct lines over 459 expert asks; 6 lines reach 5+ missions, e.g. "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" in 10 missions. Insights: 128 of 459 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 13. [low] Slow missions for careless play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 144 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** fix_custom_design took 56 days, 4 Checks, 3 gemba actions
- **Affects:** fix_silent_meter (56 d) ×12, fix_double_visits (56 d) ×9, fix_custom_design (56 d) ×8, fix_wrong_joint (56 d) ×8, save_henks_knowledge (56 d) ×8, fix_installer_not_ready (56 d) ×6, fix_overtime_planning (56 d) ×5, fix_wrong_joint (84 d) ×5, fix_incomplete_application (56 d) ×5, fix_wrong_joint (70 d) ×4, fix_not_at_home (56 d) ×4, fix_silent_meter (70 d) ×4, fix_planning_reshuffle (70 d) ×4, fix_permits_in_batches (56 d) ×4 …
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 0
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 14. [low] careless could not press a needed talk to a yes

- **Category:** people · **occurrences:** 66 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk marco_wasted_trips: pushed 5 times ×22, talk linda_replanning: pushed 5 times ×15, talk gert_klic: pushed 5 times ×11, talk sanne_checker: pushed 5 times ×9, talk petra_batch: pushed 5 times ×7, talk henk_camera: pushed 5 times ×2
- **Reproduce:** persona `careless`, seed 11, mission `fix_incomplete_application`, day 85
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 15. [low] never-talks could not press a needed talk to a yes

- **Category:** people · **occurrences:** 23 · **seen in:** never-talks/11, never-talks/12, never-talks/13
- **Detail:** after Persona.PUSH_TRIES pushes it listened instead
- **Affects:** talk sanne_kpi: pushed 5 times ×17, talk marco_wasted_trips: pushed 5 times ×6
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_installer_not_ready`, day 57
- **Proposed fix:** Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.

### 16. [low] Slow missions for average play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 20 · **seen in:** average/11, average/12, average/13
- **Detail:** fix_digging_damage took 56 days, 4 Checks, 4 gemba actions
- **Affects:** fix_silo_kpis (43 d), fix_transformer_wait (34 d), fix_permits_in_batches (57 d), fix_done_but_not_closed (42 d), fix_silo_kpis (39 d), fix_grid_study_queue (42 d), fix_unused_capacity (58 d), repair_incomplete_application (42 d), fix_installer_not_ready (42 d), fix_permits_in_batches (42 d), fix_planning_reshuffle (42 d), fix_wrong_joint (43 d), repair_silo_kpis (42 d), repair_custom_design (42 d) …
- **Reproduce:** persona `average`, seed 11, mission `fix_digging_damage`, day 119
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 17. [low] Deadline missed: winter_el_amrani

- **Category:** deadline · **occurrences:** 9 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13, non-bottleneck/11, non-bottleneck/12, non-bottleneck/13
- **Detail:** failed on day 76 (taken on: true), closes []
- **Affects:** average ×3, careless ×3, non-bottleneck ×3
- **Reproduce:** persona `average`, seed 11, mission `winter_el_amrani`, day 76
- **Proposed fix:** Working as designed (a missed deadline closes a door); see the orphan finding for what happens to its problem.

### 18. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 6 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 28, average/12: 25, average/13: 20, careless/11: 59, careless/12: 54, careless/13: 29
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 19. [low] Play reaches the debt floor

- **Category:** balance · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** careless spends 75 % of the run within €5.000 of the floor (€ -50.000) and ends at € -50.000
- **Affects:** careless/11, careless/12, careless/13
- **Reproduce:** persona `careless`, seed 11, day 183
- **Proposed fix:** Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.

### 20. [low] Slow missions for never-talks play (over 30 days and twice the median of 0)

- **Category:** balance · **occurrences:** 1 · **seen in:** never-talks/11
- **Detail:** fix_silo_kpis took 39 days, 2 Checks, 6 gemba actions
- **Affects:** fix_silo_kpis (39 d)
- **Reproduce:** persona `never-talks`, seed 11, mission `fix_silo_kpis`, day 158
- **Proposed fix:** Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.

### 21. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 92 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, incomplete_application:5, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, installer_not_ready:5, wrong_joint_in_van:0, wrong_joint_in_van:2
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless | talker | never-talks |
|---|---|---|---|---|---|---|
| training_mon | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_tue | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_wed | training | 1.0 (3) | 1.0 (3) | – | 1.0 (3) | 1.0 (3) |
| training_thu | training | 1.3 (3) | 1.4 (3) | – | 1.3 (3) | 1.3 (3) |
| training_fri | training | 0.0 (3) | 0.0 (3) | – | 0.0 (3) | 0.0 (3) |
| walk_connections | main | 0.0 (3) | 0.0 (3) | – | 0.1 (3) | 0.0 (3) |
| fix_custom_design | main | 14.3 (3) | 23.1 (8) | 63.3 (12) | 14.6 (3) | 14.3 (3) |
| fix_incomplete_application | main | 14.2 (3) | 16.9 (5) | 68.3 (7) | 14.3 (3) | 14.2 (3) |
| fix_installer_not_ready | main | 14.3 (3) | 22.6 (5) | 63.4 (10) | 14.3 (3) | 25.2 (3) |
| fix_status_callers | main | 14.2 (3) | 19.0 (3) | 98.2 (1) | 14.2 (3) | 14.3 (3) |
| fix_done_but_not_closed | main | 14.3 (3) | 30.6 (6) | 70.8 (1) | 14.3 (3) | 14.3 (3) |
| winter_el_amrani | milestone | 26.8 (3) | – | – | 18.1 (3) | 23.5 (3) |
| review_100_days | milestone | 0.2 (3) | 0.1 (3) | 0.0 (3) | 0.2 (3) | 0.2 (3) |
| fix_digging_damage | main | 14.2 (3) | 28.4 (4) | 140.8 (1) | 14.2 (3) | 14.3 (3) |
| fix_revision_backlog | main | 14.3 (3) | 26.0 (6) | – | 14.3 (3) | 14.3 (3) |
| fix_grid_study_queue | main | 14.7 (3) | 22.6 (5) | – | 14.3 (3) | 14.3 (3) |
| fix_transformer_wait | main | 15.0 (3) | 24.9 (5) | – | 15.6 (3) | 14.2 (3) |
| fix_unused_capacity | main | 17.1 (3) | 38.4 (3) | – | 16.2 (3) | 14.4 (3) |
| fix_silo_kpis | main | 15.8 (3) | 37.1 (3) | – | 19.2 (3) | 29.9 (3) |
| first_kpi_review | milestone | 0.0 (3) | 0.2 (3) | – | 0.0 (3) | 0.0 (3) |
| walk_outages | side | 0.7 (3) | 0.7 (3) | 1.2 (3) | 0.7 (3) | 0.6 (3) |
| walk_meters | side | 0.9 (3) | 0.7 (3) | 1.1 (3) | 1.0 (3) | 0.9 (3) |
| fix_wrong_joint | side | 14.6 (3) | 21.4 (10) | 72.8 (22) | 14.7 (3) | 14.6 (3) |
| fix_not_at_home | side | 14.9 (3) | 21.7 (4) | 56.5 (7) | 14.9 (3) | 14.9 (3) |
| fix_silent_meter | side | 14.3 (3) | 30.2 (7) | 60.7 (22) | 14.4 (3) | 14.3 (3) |
| fix_permits_in_batches | side | 14.2 (3) | 34.5 (7) | 72.8 (11) | 14.3 (3) | 14.2 (3) |
| look_at_grid_study | side | 0.3 (3) | 0.3 (3) | 0.3 (1) | 0.3 (3) | 0.3 (3) |
| fix_inverters_tripping | side | 14.3 (3) | 14.5 (5) | 67.1 (4) | 14.4 (3) | 14.3 (3) |
| save_henks_knowledge | side | 14.3 (3) | 22.7 (5) | 60.9 (12) | 14.4 (3) | 14.3 (3) |
| fix_planning_reshuffle | side | 19.5 (3) | 24.4 (7) | 61.8 (15) | 14.9 (3) | 14.8 (3) |
| talk_netplanner | side | 0.3 (3) | 0.5 (3) | 0.9 (3) | 0.0 (3) | 0.3 (3) |
| lsw_gemba_round | side | 0.3 (33) | 0.3 (100) | 0.2 (219) | 0.3 (34) | 0.3 (40) |
| fix_double_visits | side | – | – | 53.8 (17) | – | – |
| fix_overtime_planning | side | – | – | 56.3 (11) | – | – |

Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.

## Checks

| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted (fix) | KPI | Δ KPI (fix) | Δ KPI before→after | Δ capacity (fix) | flags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | training_tray | 1 | one_tray_fifo | 0.90 | yes | cause_right | capacity | +10.8 % | capacity | +10.8 % | +10.8 % | +10.8 % |  |
| expert | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | +8.2 % | throughput | +8.2 % | -32.3 % | +26.2 % | trend_hides_gain |
| expert | wrong_joint_in_van | 1 | standard_van_stock | 0.77 | yes | cause_right | on_time | +32.9 % | on_time | +32.9 % | -0.3 % | +15.3 % |  |
| expert | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +45.7 % | first_time_right | +45.7 % | +47.5 % | +3.1 % |  |
| expert | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +15.5 % | first_time_right | +15.5 % | -11.1 % | +8.1 % | trend_hides_gain |
| expert | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +35.4 % | capacity | +35.4 % | +35.4 % | +35.4 % |  |
| expert | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +7.5 % | lead_time | +7.5 % | +16.4 % | +0.0 % |  |
| expert | knowledge_drain | 1 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +20.8 % | on_time | +20.8 % | -3.6 % | +19.2 % |  |
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +11.6 % | first_time_right | +11.6 % | -0.3 % | +13.7 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | first_time_right | +42.7 % | first_time_right | +42.7 % | +9.3 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +7.3 % | first_time_right | +7.3 % | +3.2 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | status_callers | 1 | milestone_mail_by_hand | 0.77 | yes | cause_right | on_time | +7.5 % | on_time | +7.5 % | +7.1 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +21.3 % | lead_time | +21.3 % | +2.4 % | +0.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +3.1 % | +6.4 % |  |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +41.9 % | capacity | +41.9 % | +41.9 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +28.1 % | wip_age | +28.1 % | -5.0 % | +0.0 % | trend_hides_gain |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +40.0 % | throughput | +40.0 % | +10.0 % | +0.0 % |  |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +20.7 % | first_time_right | +20.7 % | +19.0 % | -4.5 % |  |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | +7.0 % | +7.0 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +5.5 % | throughput | +5.5 % | -21.5 % | +14.7 % | trend_hides_gain |
| average | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +19.1 % | first_time_right | +19.1 % | -10.5 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | lead_time | +5.3 % | on_time | +23.3 % | +2.5 % | +9.3 % |  |
| average | installer_not_ready | 1 | backup_job_per_day | 0.54 | yes | cause_right | first_time_right | +47.9 % | first_time_right | +47.9 % | -1.6 % | +0.0 % |  |
| average | silent_meter | 1 | route_by_area | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +4.7 % | +0.0 % |  |
| average | knowledge_drain | 1 | henks_one_point_lessons | 0.54 | yes | cause_right | on_time | +21.4 % | on_time | +21.4 % | -3.7 % | +12.4 % |  |
| average | incomplete_application | 1 | intake_checklist | 0.56 | yes | cause_right | lead_time | +2.3 % | capacity | +19.8 % | +19.8 % | +19.8 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +12.5 % | first_time_right | +12.5 % | -15.7 % | +12.3 % | trend_hides_gain |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +47.1 % | first_time_right | +47.1 % | -8.0 % | +0.0 % | trend_hides_gain |
| average | status_callers | 1 | milestone_mail_by_hand | 0.77 | yes | cause_right | on_time | +7.3 % | on_time | +7.3 % | +6.7 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | inverters_tripping | 1 | tap_trial_one_station | 0.54 | yes | cause_right | first_time_right | +16.1 % | first_time_right | +16.1 % | -1.0 % | +0.0 % | constraint_fixed_no_capacity_gain |
| average | permits_in_batches | 1 | tray_labels | 0.00 | no | mismatch | lead_time | +0.0 % | lead_time | +0.0 % | -2.1 % | +0.0 % |  |
| average | custom_design | 1 | poka_yoke_application | 0.00 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | -9.4 % | +0.0 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +15.6 % | lead_time | +15.6 % | -11.3 % | +0.0 % | trend_hides_gain |
| average | wrong_joint_in_van | 1 | van_refill_card | 0.58 | yes | cause_right | on_time | +36.2 % | on_time | +36.2 % | -0.6 % | +9.3 % |  |
| average | custom_design | 2 | delegated_approval | 0.55 | yes | cause_right | throughput | +9.3 % | throughput | +9.3 % | +6.2 % | +14.7 % |  |
| average | silent_meter | 1 | study_overtime_sprint | 0.00 | no | mismatch | throughput | +0.0 % | first_time_right | +0.0 % | -14.1 % | +0.0 % |  |
| average | knowledge_drain | 1 | delegated_approval | 0.00 | no | mismatch | first_time_right | +54.0 % | on_time | +24.4 % | -4.2 % | +21.2 % | failed_but_kpi_improved |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | no | not_moved | capacity | +0.0 % | lead_time | +6.4 % | -19.8 % | +0.0 % |  |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | wip_age | +14.4 % | first_time_right | +20.8 % | -1.7 % | +16.9 % |  |
| average | knowledge_drain | 2 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +33.3 % | on_time | +33.3 % | +3.7 % | +21.9 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +14.9 % | lead_time | +14.9 % | +20.0 % | +0.0 % |  |
| average | planning_reshuffle | 1 | proactive_status_updates | 0.00 | no | mismatch | wip_age | +0.0 % | first_time_right | +0.0 % | +10.1 % | +0.0 % |  |
| average | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | capacity | +39.0 % | capacity | +39.0 % | +23.2 % | +39.0 % |  |
| average | digging_damage | 1 | realistic_promise | 0.00 | no | mismatch | capacity | +0.0 % | capacity | +0.0 % | +8.4 % | +0.0 % |  |
| average | planning_reshuffle | 2 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +40.2 % | first_time_right | +40.2 % | -5.5 % | +2.4 % | trend_hides_gain |
| average | installer_not_ready | 1 | tap_review_per_neighbourhood | 0.00 | no | mismatch | first_time_right | +58.5 % | first_time_right | +58.5 % | -5.5 % | +0.0 % | failed_but_kpi_improved |
| average | digging_damage | 2 | contractor_briefing | 0.56 | no | not_moved | throughput | -14.1 % | capacity | +4.7 % | +21.9 % | +4.7 % |  |
| average | installer_not_ready | 2 | readiness_check | 0.90 | yes | cause_right | first_time_right | +28.8 % | first_time_right | +28.8 % | +12.6 % | +0.0 % |  |
| average | wrong_joint_in_van | 1 | milestone_mail_by_hand | 0.00 | no | mismatch | on_time | +43.0 % | on_time | +43.0 % | -5.9 % | +17.9 % | failed_but_kpi_improved |
| average | digging_damage | 3 | standard_test_trenches | 0.72 | no | not_moved | wip_age | +0.0 % | capacity | +6.4 % | -7.2 % | +6.4 % |  |
| average | wrong_joint_in_van | 2 | standard_van_stock | 0.77 | no | not_moved | first_time_right | +0.5 % | on_time | +40.8 % | +8.8 % | +20.2 % |  |
| average | permits_in_batches | 1 | route_by_area | 0.00 | no | mismatch | lead_time | +0.0 % | lead_time | +0.0 % | +16.5 % | +0.0 % |  |
| average | digging_damage | 4 | standard_test_trenches | 0.72 | yes | cause_right | capacity | +6.4 % | capacity | +6.4 % | +4.3 % | +6.4 % |  |
| average | wrong_joint_in_van | 3 | standard_van_stock | 0.77 | no | not_moved | wip_age | +0.0 % | on_time | +47.1 % | -11.6 % | +20.2 % |  |
| average | permits_in_batches | 2 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +7.0 % | lead_time | +7.0 % | -21.2 % | +0.0 % | trend_hides_gain |
| average | done_but_not_closed | 1 | tap_trial_one_station | 0.00 | no | mismatch | wip_age | +0.0 % | lead_time | +0.0 % | +24.8 % | +0.0 % |  |
| average | wrong_joint_in_van | 4 | standard_van_stock | 0.77 | yes | cause_right | on_time | +38.3 % | on_time | +38.3 % | -4.5 % | +20.1 % |  |
| average | silent_meter | 1 | mid_month_run | 0.00 | no | mismatch | on_time | +0.0 % | first_time_right | +0.0 % | -0.4 % | +0.0 % |  |
| average | done_but_not_closed | 2 | mid_month_run | 0.54 | yes | cause_right | lead_time | +15.9 % | lead_time | +15.9 % | -15.8 % | +0.0 % | trend_hides_gain |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | no | not_moved | throughput | -2.0 % | first_time_right | +12.8 % | -10.0 % | +12.4 % |  |
| average | custom_design | 1 | delegated_approval | 0.55 | no | not_moved | on_time | +0.3 % | throughput | +2.1 % | +909.1 % | +14.7 % |  |
| average | silent_meter | 3 | coverage_check_in_planning | 0.40 | no | too_early | lead_time | +2.0 % | first_time_right | +7.3 % | +16.5 % | +5.0 % |  |
| average | custom_design | 2 | standard_designs | 0.90 | no | not_moved | on_time | -2.0 % | throughput | +0.0 % | -43.2 % | +29.4 % |  |
| average | silent_meter | 4 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +14.2 % | first_time_right | +14.2 % | -2.7 % | +13.2 % |  |
| average | custom_design | 3 | standard_designs | 0.90 | yes | cause_right | throughput | +9.1 % | throughput | +9.1 % | +3.2 % | +29.4 % |  |
| average | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | capacity | +21.8 % | capacity | +21.8 % | +21.8 % | +21.8 % |  |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.77 | yes | cause_right | on_time | +39.5 % | on_time | +39.5 % | -1.5 % | +15.0 % |  |
| average | done_but_not_closed | 1 | mid_month_run | 0.54 | no | not_moved | first_time_right | +0.2 % | lead_time | +10.5 % | -26.5 % | +0.0 % |  |
| average | inverters_tripping | 1 | appointment_reminder | 0.00 | no | mismatch | first_time_right | +8.9 % | first_time_right | +8.9 % | -22.8 % | +0.0 % | failed_but_kpi_improved |
| average | silent_meter | 1 | tap_review_per_neighbourhood | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | -15.1 % | +0.0 % |  |
| average | done_but_not_closed | 2 | close_out_at_completion | 0.90 | yes | cause_right | throughput | +2.9 % | lead_time | +20.2 % | +8.5 % | +0.0 % |  |
| average | inverters_tripping | 2 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | on_time | +5.0 % | first_time_right | +15.6 % | -100.0 % | +1.2 % | trend_hides_gain |
| average | silent_meter | 2 | on_site_comm_test | 0.90 | yes | cause_right | wip_age | +31.1 % | first_time_right | +18.3 % | +1.0 % | +12.4 % |  |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | capacity | +40.1 % | capacity | +40.1 % | +59.3 % | +40.1 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | no | not_moved | capacity | +0.0 % | lead_time | +9.8 % | +1.8 % | +0.0 % |  |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +33.6 % | wip_age | +33.6 % | -3.5 % | +0.0 % |  |
| average | permits_in_batches | 2 | parallel_permits | 0.50 | no | not_moved | first_time_right | -2.4 % | lead_time | +8.2 % | +4.9 % | +0.0 % |  |
| average | permits_in_batches | 3 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +9.6 % | lead_time | +9.6 % | +11.2 % | +0.0 % |  |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | no | not_moved | wip_age | +0.0 % | throughput | +57.9 % | +0.0 % | +0.0 % |  |
| average | unused_capacity | 2 | use_it_or_lose_it | 0.90 | yes | cause_right | throughput | +58.3 % | throughput | +58.3 % | -28.6 % | +0.0 % | trend_hides_gain |
| average | custom_design | 1 | delegated_approval | 0.55 | yes | cause_right | throughput | +10.1 % | throughput | +10.1 % | +5.7 % | +14.7 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +10.2 % | lead_time | +10.2 % | -9.2 % | +0.0 % | trend_hides_gain |
| average | silo_kpis | 1 | connections_wip_limit | 0.72 | no | not_moved | lead_time | +1.7 % | first_time_right | +4.2 % | +11.8 % | -1.9 % |  |
| average | silo_kpis | 2 | shared_team_goals | 0.63 | yes | cause_right | first_time_right | +31.6 % | first_time_right | +31.6 % | -7.1 % | -4.8 % | trend_hides_gain |
| average | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | +12.0 % | first_time_right | +12.0 % | -17.2 % | +0.0 % | constraint_fixed_no_capacity_gain, trend_hides_gain |
| average | not_at_home | 1 | intake_checklist | 0.00 | no | mismatch | first_time_right | +0.0 % | first_time_right | +0.0 % | +1.1 % | +0.0 % |  |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | +13.7 % | first_time_right | +13.7 % | +23.7 % | +7.9 % |  |
| average | custom_design | 1 | planning_with_fault_windows | 0.00 | no | mismatch | capacity | +20.4 % | throughput | +7.5 % | -38.8 % | +20.4 % | failed_but_kpi_improved |
| average | custom_design | 2 | standard_designs | 0.90 | no | not_moved | wip_age | -10.0 % | throughput | +13.3 % | +80.5 % | +23.1 % |  |
| average | knowledge_drain | 1 | request_permits_daily | 0.00 | no | mismatch | on_time | +0.0 % | on_time | +0.0 % | -14.7 % | +0.0 % |  |
| average | custom_design | 3 | standard_designs | 0.90 | yes | cause_right | capacity | +20.9 % | throughput | +1.8 % | -12.2 % | +20.9 % |  |
| average | knowledge_drain | 2 | twi_job_instruction | 0.81 | yes | cause_right | on_time | +19.2 % | on_time | +19.2 % | +36.8 % | +19.2 % |  |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | no | not_moved | throughput | -0.4 % | first_time_right | +6.0 % | +9.4 % | -2.3 % |  |
| average | silo_kpis | 3 | obeya_end_to_end | 0.90 | no | not_moved | wip_age | -1.1 % | first_time_right | +8.6 % | -7.4 % | -4.3 % |  |
| average | silo_kpis | 4 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +5.4 % | first_time_right | +5.4 % | -35.3 % | -4.3 % | trend_hides_gain |

Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (expert 57 of 57 passed; average 118 of 204 passed; careless 165 of 784 passed; talker 57 of 58 passed; never-talks 57 of 58 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| expert | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| expert | 12 | fix_incomplete_application | fix_installer_not_ready | no | no | -0.2 % |
| expert | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| expert | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| average | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +19.8 % |
| average | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| average | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +19.8 % |
| average | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| average | 13 | fix_installer_not_ready | fix_incomplete_application | yes | no | +8.1 % |
| average | 13 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| careless | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +59.6 % |
| careless | 11 | fix_incomplete_application | fix_installer_not_ready | no | no | +3.4 % |
| careless | 12 | fix_installer_not_ready | fix_incomplete_application | no | no | +24.1 % |
| careless | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | -5.3 % |
| careless | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +19.5 % |
| careless | 13 | fix_incomplete_application | fix_installer_not_ready | no | no | +52.6 % |
| talker | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| talker | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| talker | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| talker | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| talker | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| talker | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +6.6 % |
| never-talks | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| never-talks | 11 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| never-talks | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| never-talks | 12 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| never-talks | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +35.4 % |
| never-talks | 13 | fix_incomplete_application | fix_installer_not_ready | yes | no | +7.0 % |
| non-bottleneck | 11 | fix_installer_not_ready | fix_incomplete_application | yes | no | +35.4 % |
| non-bottleneck | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| non-bottleneck | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +35.4 % |
| non-bottleneck | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |
| non-bottleneck | 13 | fix_installer_not_ready | fix_incomplete_application | yes | no | +35.4 % |
| non-bottleneck | 13 | fix_installer_not_ready | fix_installer_not_ready | no | yes | +0.0 % |

The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.

## Coach

| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |
|---|---|---|---|---|
| go_see | 135 | 40 | 45 | "Als je over een jaar terugkijkt, welk getal wil je dan veranderd hebben?" (7) |
| understand | 108 | 18 | 36 | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" (8) |
| experiment | 88 | 37 | 16 | "En hoe is het nu echt, op de werkvloer? Wat zie je daar?" (10) |
| reflect | 103 | 42 | 31 | "Wat is de volgende kleine stap?" (6) |
| talk | 25 | 7 | 0 | "Wiens idee was het uiteindelijk?" (8) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `kpi_review_due()`: the first quarterly review is played in its scene (first_kpi_review, at the KPI board); the playtester reads Region.board.review_due for it, and the later quarters (tier 2's lsw_kpi_review) are not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.
- `goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).
