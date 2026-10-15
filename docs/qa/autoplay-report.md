# Autoplay report

Generated 2026-10-15T15:09:23 by `game/tools/autoplay.gd` (personas expert, average, careless, seeds 11, 12, 13). Reproduce one run with
`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.
Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.
The rules are played as they stand in the working tree; the gemba audit (leader routine) is used on every 'slipping' event by the expert, on half of them by the average player.

Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. A lost persona gets the expert's next step ("assisted").

**Summary:** 1 critical, 10 high, 9 medium, 5 low. Expert and average reach the end of the campaign without a dead end: yes.

## Runs

| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 11 | campaign_done | 165 | 37 | 11 | 20000 | master_black | € 231.770 | 19/0 | 0 | 0 | 0 | 0 |
| expert | 12 | campaign_done | 165 | 37 | 11 | 20000 | master_black | € 231.770 | 19/0 | 0 | 0 | 0 | 0 |
| expert | 13 | campaign_done | 165 | 37 | 11 | 20000 | master_black | € 231.770 | 19/0 | 0 | 0 | 0 | 0 |
| average | 11 | campaign_done | 252 | 51 | 11 | 19450 | master_black | € 211.268 | 19/7 | 0 | 1 | 0 | 0 |
| average | 12 | campaign_done | 310 | 61 | 18 | 21900 | master_black | € 247.376 | 32/8 | 0 | 15 | 0 | 0 |
| average | 13 | campaign_done | 253 | 54 | 13 | 20670 | master_black | € 150.060 | 25/9 | 0 | 6 | 0 | 0 |
| careless | 11 | horizon | 1097 | 46 | 15 | 12420 | master_black | € -462.613 | 43/139 | 1 | 41 | 4 | 0 |
| careless | 12 | horizon | 1099 | 45 | 16 | 13210 | master_black | € -504.249 | 42/145 | 1 | 39 | 1 | 0 |
| careless | 13 | horizon | 1101 | 61 | 19 | 14870 | master_black | € -681.303 | 58/179 | 0 | 55 | 4 | 0 |

## Findings (25), ranked by severity

### 1. [critical] Engine error: Invalid access to property or key '<RefCounted>' on a base object of type 'Dictionary[SimStep, Array]'. (network.gd:203 in Network.queue_of)

- **Category:** stuck · **occurrences:** 26 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** raised by queue_count at connections.permit (mission fix_permits_in_batches)
- **Affects:** queue_count at connections.permit ×6, queue_count at connections.close_out_wait ×6, queue_count at connections.grid_reinforcement ×5, queue_count at congestion.capacity_queue ×3, queue_count at outages.joint ×2, queue_count at meters.customer_window, queue_count at connections.materials, queue_count at voltage_complaints.measurement_week, queue_count at meters.reserve_meter
- **Reproduce:** persona `average`, seed 11, day 40
- **Proposed fix:** Region.queue_at (and use_tool's queue_count) read Network.queue_of for any step, but a wait or material step has no queue: guard it as Region.measures does (count 0), and add a test that counts the queue at connections.permit.

### 2. [high] Problems stay open (and hurting) with no mission to solve them

- **Category:** stuck · **occurrences:** 4 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** open problems no active mission covers at the end of the run; they hold one of Region.MAX_OPEN (4) slots, so missions get refused with problem_unavailable
- **Affects:** knowledge_drain (check_ready; save_henks_knowledge failed) ×2, grid_study_queue (spotted; fix_grid_study_queue locked, look_at_grid_study completed) ×2
- **Reproduce:** persona `careless`, seed 11, day 1097
- **Proposed fix:** When a mission fails or completes without solving its problem (deadline missed, an investigate goal), put the problem back to sleep (Region.deactivate) or keep a mission open for it. A failed save_henks_knowledge can never be accepted again (status failed), so its problem stays open for good, against 'the problem can still be solved another way'.

### 3. [high] Missions on the board cannot be accepted (problem_unavailable)

- **Category:** stuck · **occurrences:** 40 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** Region.MAX_OPEN problems are open, mostly problems without a mission (see the orphan finding)
- **Affects:** fix_permits_in_batches ×3, fix_planning_reshuffle ×3, fix_inverters_tripping ×3, fix_custom_design ×3, fix_incomplete_application ×3, fix_silent_meter ×3, fix_wrong_joint ×3, fix_not_at_home ×3, fix_revision_backlog ×3, fix_installer_not_ready ×3, fix_done_but_not_closed ×3, look_at_grid_study ×2, fix_status_callers ×2, fix_digging_damage ×2 …
- **Reproduce:** persona `careless`, seed 11, mission `fix_permits_in_batches`, day 115
- **Proposed fix:** Count only problems with an active mission towards MAX_OPEN, or hide such missions from the board with the reason.

### 4. [high] The Check's 14 days cannot show the fix in the problem's own KPI

- **Category:** contradiction · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** Against a no-fix twin (same network, same random sequence), the expert's best fix moves the problem's own KPI by under 1 % for 5 of 19 problems and makes it worse for 8 (the team hours the experiment takes), mean over seeds. The before/after columns meanwhile move 18 % on average from the stream's own trend. Flat: incomplete_application/lead_time, installer_not_ready/lead_time, revision_backlog/throughput, digging_damage/lead_time, grid_study_queue/throughput. Worse: custom_design/throughput -7 %, not_at_home/first_time_right -5 %, inverters_tripping/first_time_right -1 %, status_callers/on_time -4 %, done_but_not_closed/lead_time -5 %, transformer_wait/wip_age -5 %, unused_capacity/lead_time -1 %, silo_kpis/first_time_right -3 %.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** Lagging KPIs (lead time, first time right, on time) measure orders that started long before the fix, and the Check passes on fit alone, so the table carries no lesson. Show the after-window against a no-fix twin (as fade_forecast does), ask for a leading-indicator prediction in the A3, or measure lagging KPIs only on orders that entered after the fix.

### 5. [high] Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes

- **Category:** balance · **occurrences:** 6 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** average/11: 15 of 46 completed missions were re-runs of a faded fix; the campaign took 252 days (campaign_done) against the expert's 165
- **Affects:** average/11: 15/46, average/12: 25/56, average/13: 19/49, careless/11: 31/46, careless/12: 29/45, careless/13: 45/61
- **Reproduce:** persona `average`, seed 11, day 252
- **Proposed fix:** A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.

### 6. [high] Debt spiral: the budget keeps falling and the bad period never ends

- **Category:** balance · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** careless ends at € -462.613 after 1097 days, still falling about € 13.840 a month; 4 bad periods
- **Affects:** careless/11, careless/12, careless/13
- **Reproduce:** persona `careless`, seed 11, day 1097
- **Proposed fix:** CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.

### 7. [high] The Check table shows the problem's KPI worse although the fix helped

- **Category:** contradiction · **occurrences:** 5 · **seen in:** expert/11, expert/12, expert/13
- **Detail:** cm standard_van_stock, predicted on_time -7.1 %, problem KPI on_time -7.1 %, capacity +49.9 %, eff 0.72, lesson cause_right; against the no-fix twin on_time +3.5 %
- **Affects:** wrong_joint_in_van ×2, installer_not_ready, planning_reshuffle, status_callers
- **Reproduce:** persona `expert`, seed 11, mission `fix_wrong_joint`, day 23
- **Proposed fix:** Before/after compares two different 14-day windows, so the stream's own trend (and noise) lands on the player's fix. The expert's counterfactual (same network, same random sequence, no fix) shows the fix improved the KPI. Compare the after-window with a no-fix twin, as GameSession.fade_forecast already does, and show 'zonder jouw maatregel' as the reference column.

### 8. [high] Check fails while a KPI improved more than 5 %

- **Category:** contradiction · **occurrences:** 238 · **seen in:** average/11, average/12, careless/11, careless/12, careless/13
- **Detail:** cm request_permits_daily, predicted lead_time +13.2 %, problem KPI lead_time +13.2 %, capacity -3.9 %, eff 0.10, lesson mismatch
- **Affects:** planning_reshuffle ×38, silent_meter ×36, permits_in_batches ×29, wrong_joint_in_van ×23, done_but_not_closed ×19, incomplete_application ×17, custom_design ×16, installer_not_ready ×15, not_at_home ×14, revision_backlog ×11, inverters_tripping ×10, knowledge_drain ×4, status_callers ×2, digging_damage ×2 …
- **Reproduce:** persona `average`, seed 11, mission `fix_installer_not_ready`, day 79
- **Proposed fix:** The mismatch/too-early verdict contradicts the table (trend or noise). Show the no-fix reference, or word it 'de cijfers bewegen, maar niet door jouw maatregel'.

### 9. [high] Check passes while the problem's own KPI got worse (prediction named another KPI)

- **Category:** contradiction · **occurrences:** 49 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm standard_van_stock, predicted wip_age +100.0 %, problem KPI on_time -12.8 %, capacity +26.0 %, eff 0.72, lesson cause_right
- **Affects:** permits_in_batches ×8, silent_meter ×7, planning_reshuffle ×5, custom_design ×4, wrong_joint_in_van ×3, knowledge_drain ×3, incomplete_application ×3, installer_not_ready ×3, not_at_home ×2, unused_capacity ×2, transformer_wait ×2, revision_backlog ×2, done_but_not_closed ×2, status_callers …
- **Reproduce:** persona `average`, seed 11, mission `fix_wrong_joint`, day 25
- **Proposed fix:** Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'.

### 10. [high] Check passes while the predicted leading KPI got worse

- **Category:** contradiction · **occurrences:** 23 · **seen in:** expert/12, average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm standard_designs, predicted throughput -29.2 %, problem KPI throughput -29.2 %, capacity +26.2 %, eff 0.90, lesson cause_right; against the no-fix twin throughput -9.8 %
- **Affects:** permits_in_batches ×5, custom_design ×4, transformer_wait ×2, wrong_joint_in_van ×2, installer_not_ready ×2, planning_reshuffle ×2, revision_backlog, unused_capacity, inverters_tripping, silent_meter, status_callers, incomplete_application
- **Reproduce:** persona `expert`, seed 12, mission `fix_custom_design`, day 22
- **Proposed fix:** The pass rule is the countermeasure's fit (eff >= 0.5), not the numbers; a leading indicator (capacity, throughput, WIP age) is supposed to move inside the Check. Judge the pass on the measured change against a no-fix twin, or have the panel say 'geslaagd, maar je voorspelde KPI is nog niet bewogen'.

### 11. [high] Campaign not finished within the horizon

- **Category:** stuck · **occurrences:** 3 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** 46 missions after 1097 days
- **Affects:** horizon ×3
- **Reproduce:** persona `careless`, seed 11, day 1097
- **Proposed fix:** See the slowest missions; shorten Checks or let the player run missions in parallel.

### 12. [medium] The simulation never changes an outcome: the expert's result is identical on every seed

- **Category:** balance · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 3 seeds: 20000 XP, budget € 231.770, 165 days each, although the Check numbers differ per seed
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** Pass, score and rewards come from fit, maturity and planned capacity (Capacity.analyse), never from the measured flow. Let the impact dimension (and a bonus) use the measured change against a no-fix twin so that what the player sees in the numbers is what they are rewarded for.

### 13. [medium] A wrong root cause still passes the Check

- **Category:** contradiction · **occurrences:** 116 · **seen in:** careless/11, careless/12, careless/13
- **Detail:** cm delegated_approval, predicted throughput +86.5 %, problem KPI throughput +86.5 %, capacity +86.7 %, eff 0.55, lesson cause_wrong
- **Affects:** wrong_joint_in_van ×18, silent_meter ×16, planning_reshuffle ×15, permits_in_batches ×14, custom_design ×9, installer_not_ready ×8, incomplete_application ×7, done_but_not_closed ×7, status_callers ×6, not_at_home ×6, inverters_tripping ×4, revision_backlog ×3, knowledge_drain ×3
- **Reproduce:** persona `careless`, seed 11, mission `fix_custom_design`, day 56
- **Proposed fix:** By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more.

### 14. [medium] Check passes while the predicted lagging KPI got worse

- **Category:** contradiction · **occurrences:** 59 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm standard_van_stock, predicted on_time -7.1 %, problem KPI on_time -7.1 %, capacity +49.9 %, eff 0.72, lesson cause_right; against the no-fix twin on_time +3.5 %
- **Affects:** done_but_not_closed ×9, permits_in_batches ×7, status_callers ×6, planning_reshuffle ×5, custom_design ×4, not_at_home ×4, silent_meter ×3, incomplete_application ×3, silo_kpis ×3, unused_capacity ×3, installer_not_ready ×3, inverters_tripping ×2, revision_backlog ×2, wrong_joint_in_van ×2 …
- **Reproduce:** persona `expert`, seed 11, mission `fix_wrong_joint`, day 23
- **Proposed fix:** The panel's LAGGING_NOTE explains lag in general, but not when the predicted KPI moved the wrong way. Name it in the verdict ('je voorspelde KPI is een volgindicator: kijk naar de stuurindicatoren') or let the A3 ask for a leading indicator as the prediction.

### 15. [medium] A fix at the constraint passes but stream capacity does not rise

- **Category:** contradiction · **occurrences:** 34 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm daytime_outage_crew, predicted first_time_right +51.3 %, problem KPI first_time_right +51.3 %, capacity -2.4 %, eff 0.90, lesson cause_right; against the no-fix twin first_time_right +10.4 %
- **Affects:** status_callers ×11, inverters_tripping ×8, planning_reshuffle ×5, not_at_home ×3, knowledge_drain ×2, custom_design ×2, wrong_joint_in_van ×2, silent_meter
- **Reproduce:** persona `expert`, seed 11, mission `fix_planning_reshuffle`, day 23
- **Proposed fix:** Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false.

### 16. [medium] Check passes with no visible change in the predicted or the problem KPI

- **Category:** contradiction · **occurrences:** 10 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/12, careless/13
- **Detail:** cm early_transformer_order, predicted wip_age -0.2 %, problem KPI wip_age -0.2 %, capacity -0.0 %, eff 0.90, lesson cause_right; against the no-fix twin wip_age -10.3 %
- **Affects:** transformer_wait ×4, installer_not_ready, knowledge_drain, inverters_tripping, permits_in_batches, digging_damage, status_callers
- **Reproduce:** persona `expert`, seed 11, mission `fix_transformer_wait`, day 136
- **Proposed fix:** Make the countermeasure's effect large enough to move its KPI inside 14 days, or let the panel name the indicator that did move.

### 17. [medium] Fixing a wait step can never score on impact

- **Category:** balance · **occurrences:** 9 · **seen in:** expert/11, expert/12, expert/13
- **Detail:** the impact dimension rewards stream capacity only; a wait (permit, delivery, close-out) has no team, so the expert's right fix scores impact 1-2 and gets the 'not the bottleneck' note
- **Affects:** done_but_not_closed ×3, transformer_wait ×3, unused_capacity ×3
- **Reproduce:** persona `expert`, seed 11, mission `fix_done_but_not_closed`, day 64
- **Proposed fix:** Score impact on the problem's KPI against the no-fix twin (lead time for a wait), not on capacity alone.

### 18. [medium] Belts run out early: the top belt comes long before the campaign ends

- **Category:** balance · **occurrences:** 3 · **seen in:** expert/11, expert/12, expert/13
- **Detail:** master black on day 107 of a 165-day campaign; belts on days yellow 22, green 24, black 50, master_black 107
- **Reproduce:** persona `expert`, seed 11, day 107
- **Proposed fix:** Total campaign XP (~20000 for the expert) is far above Progression's master black (12000). Raise the belt thresholds, scale XP down, or tie the later belts to maturity and the KPI review instead of XP.

### 19. [medium] A deadline runs out while the player's experiment is already running

- **Category:** deadline · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** save_henks_knowledge failed on day 115 with its problem check_ready; the problem stays open with no mission
- **Affects:** careless/11, careless/12
- **Reproduce:** persona `careless`, seed 11, mission `save_henks_knowledge`, day 115
- **Proposed fix:** Count the deadline as met once the A3 is submitted (the countermeasure is in place), or warn when the Check would end after the deadline.

### 20. [medium] The coach repeats the same questions across missions

- **Category:** coach · **occurrences:** 1 · **seen in:** expert/11
- **Detail:** 40 distinct lines over 450 expert asks; 11 lines reach 5+ missions, e.g. "Wat wil je bereiken? Hoe ziet het eruit als het hier goed loopt?" in 14 missions. Insights: 84 of 450 asks.
- **Reproduce:** persona `expert`, seed 11, day 0
- **Proposed fix:** The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.

### 21. [low] 'Not the bottleneck' warning on a problem at a wait step

- **Category:** contradiction · **occurrences:** 102 · **seen in:** expert/11, expert/12, expert/13, average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** cm close_out_at_completion, predicted lead_time +8.7 %, problem KPI lead_time +8.7 %, capacity +0.0 %, eff 0.90, lesson cause_right; against the no-fix twin lead_time -4.9 %
- **Affects:** permits_in_batches ×47, done_but_not_closed ×43, transformer_wait ×6, unused_capacity ×6
- **Reproduce:** persona `expert`, seed 11, mission `fix_done_but_not_closed`, day 79
- **Proposed fix:** A wait step has no team, so at_constraint is always false and the panel says 'het werk wacht nog op een ander team'. Skip the warning (or word it for waits) when the problem's step is a wait.

### 22. [low] Fixes fade and missions reopen

- **Category:** fade · **occurrences:** 6 · **seen in:** average/11, average/12, average/13, careless/11, careless/12, careless/13
- **Detail:** reopenings per run (the expert standardises every fix and audits on every 'slipping' event)
- **Affects:** average/11: 1, average/12: 15, average/13: 6, careless/11: 41, careless/12: 39, careless/13: 55
- **Reproduce:** persona `average`, seed 11, day 0
- **Proposed fix:** Working as designed for players who do not standardise; check the reopened mission tells why it is back.

### 23. [low] Deadline missed: save_henks_knowledge

- **Category:** deadline · **occurrences:** 2 · **seen in:** careless/11, careless/12
- **Detail:** failed on day 115 (taken on: true), closes ["skills_matrix_buddy"]
- **Affects:** careless ×2
- **Reproduce:** persona `careless`, seed 11, mission `save_henks_knowledge`, day 115
- **Proposed fix:** Working as designed (a missed deadline closes a door); see the orphan finding for what happens to its problem.

### 24. [low] No coach insight for stages players reach

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 22 mission/stage pairs fall back to the generic questions only: training_thu/go_see, fix_custom_design/go_see, fix_incomplete_application/go_see, fix_incomplete_application/experiment, fix_installer_not_ready/understand, fix_installer_not_ready/experiment, fix_status_callers/experiment, fix_status_callers/reflect, fix_done_but_not_closed/go_see, fix_done_but_not_closed/experiment, fix_done_but_not_closed/reflect, fix_revision_backlog/go_see, fix_revision_backlog/experiment, fix_revision_backlog/reflect, fix_digging_damage/go_see, fix_digging_damage/experiment, fix_grid_study_queue/experiment, fix_grid_study_queue/reflect, fix_transformer_wait/go_see, fix_transformer_wait/experiment, fix_unused_capacity/experiment, fix_unused_capacity/reflect
- **Proposed fix:** Add an `insights` line per reached stage (at least understand and reflect) in content/missions.yaml.

### 25. [low] Key clues without a coach note for the debrief

- **Category:** text · **occurrences:** 1 · **seen in:** content
- **Detail:** 76 key clues: incomplete_application:0, incomplete_application:2, incomplete_application:3, incomplete_application:4, installer_not_ready:0, installer_not_ready:2, installer_not_ready:3, installer_not_ready:4, wrong_joint_in_van:0, wrong_joint_in_van:2, wrong_joint_in_van:3, wrong_joint_in_van:4
- **Proposed fix:** Add `note:` to each key clue (the coach's reflection in the debrief).

## Days per mission (mean over seeds, completed runs)

| mission | kind | expert | average | careless |
|---|---|---|---|---|
| training_mon | training | 1.0 (3) | 1.0 (3) | – |
| training_tue | training | 1.0 (3) | 1.0 (3) | – |
| training_wed | training | 1.0 (3) | 1.0 (3) | – |
| training_thu | training | 4.0 (3) | 4.0 (3) | – |
| training_fri | training | 0.0 (3) | 0.0 (3) | – |
| walk_connections | main | – | – | – |
| fix_custom_design | main | 14.2 (3) | 19.3 (6) | 49.3 (10) |
| fix_incomplete_application | main | 14.2 (3) | 19.0 (3) | 56.3 (9) |
| fix_installer_not_ready | main | 14.3 (3) | 23.7 (3) | 59.2 (10) |
| fix_status_callers | main | 14.2 (3) | 23.8 (3) | 52.2 (7) |
| fix_done_but_not_closed | main | 14.2 (3) | 19.4 (6) | 56.4 (9) |
| fix_revision_backlog | main | 14.4 (3) | 17.2 (5) | 56.8 (4) |
| fix_digging_damage | main | 14.3 (3) | 19.0 (3) | 56.6 (1) |
| fix_grid_study_queue | main | 14.2 (3) | 14.0 (3) | – |
| fix_transformer_wait | main | 14.2 (3) | 18.5 (4) | – |
| fix_unused_capacity | main | 14.3 (3) | 14.8 (3) | – |
| fix_silo_kpis | main | 14.5 (3) | 19.1 (3) | – |
| walk_outages | side | 0.7 (3) | 2.1 (3) | 1.5 (3) |
| walk_meters | side | 1.2 (3) | 1.6 (3) | 1.3 (3) |
| fix_wrong_joint | side | 14.8 (3) | 18.0 (4) | 54.4 (21) |
| fix_not_at_home | side | 14.9 (3) | 24.8 (3) | 62.0 (8) |
| fix_silent_meter | side | 14.3 (3) | 20.6 (7) | 63.0 (19) |
| fix_permits_in_batches | side | 14.2 (3) | 21.7 (6) | 50.5 (19) |
| look_at_grid_study | side | 0.3 (3) | 1.0 (3) | 1.0 (3) |
| fix_inverters_tripping | side | 14.3 (3) | 24.3 (3) | 61.1 (6) |
| save_henks_knowledge | side | 14.3 (3) | 14.5 (3) | 47.0 (3) |
| fix_planning_reshuffle | side | 15.1 (3) | 15.1 (5) | 67.3 (17) |

Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.

## Checks

| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted | KPI | Δ KPI | Δ KPI vs no-fix twin | Δ capacity | flags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | training_tray | 1 | one_tray_fifo | 0.90 | yes | cause_right | capacity | +10.8 % | capacity | +10.8 % | +10.8 % | +10.8 % |  |
| expert | custom_design | 1 | standard_designs | 0.90 | yes | cause_right | throughput | -3.7 % | throughput | -3.7 % | -7.1 % | +26.2 % |  |
| expert | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | on_time | -7.1 % | on_time | -7.1 % | +3.5 % | +49.9 % | passed_lagging_kpi_worse, trend_hides_gain |
| expert | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +51.3 % | first_time_right | +51.3 % | +10.4 % | -2.4 % | constraint_fixed_no_capacity_gain |
| expert | not_at_home | 1 | appointment_reminder | 0.90 | yes | cause_right | first_time_right | -19.6 % | first_time_right | -19.6 % | -2.3 % | +13.6 % | passed_lagging_kpi_worse |
| expert | incomplete_application | 1 | poka_yoke_application | 0.90 | yes | cause_right | lead_time | +15.9 % | lead_time | +15.9 % | +0.1 % | +18.4 % |  |
| expert | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | lead_time | +7.2 % | lead_time | +7.2 % | -0.0 % | +18.6 % |  |
| expert | knowledge_drain | 1 | work_instruction_videos | 0.72 | yes | cause_right | on_time | +2.4 % | on_time | +2.4 % | +12.5 % | +7.0 % |  |
| expert | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | +11.6 % | first_time_right | +11.6 % | +16.7 % | +40.6 % |  |
| expert | installer_not_ready | 1 | readiness_check | 0.90 | yes | cause_right | lead_time | -14.5 % | lead_time | -14.5 % | +13.2 % | +3.6 % | passed_lagging_kpi_worse, trend_hides_gain |
| expert | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | first_time_right | -6.3 % | first_time_right | -6.3 % | -3.6 % | -0.3 % | passed_lagging_kpi_worse, constraint_fixed_no_capacity_gain |
| expert | status_callers | 1 | realistic_promise | 0.63 | yes | cause_right | on_time | +5.1 % | on_time | +5.1 % | -1.9 % | +0.0 % | constraint_fixed_no_capacity_gain |
| expert | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | +8.7 % | lead_time | +8.7 % | -4.9 % | +0.0 % | not_constraint_on_wait_step |
| expert | revision_backlog | 1 | daily_revision_template | 0.63 | yes | cause_right | throughput | +60.0 % | throughput | +60.0 % | +2.9 % | +0.0 % |  |
| expert | digging_damage | 1 | standard_test_trenches | 0.72 | yes | cause_right | lead_time | +5.6 % | lead_time | +5.6 % | -0.0 % | +7.3 % |  |
| expert | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | throughput | +4.0 % | throughput | +4.0 % | +2.0 % | +41.9 % |  |
| expert | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | -0.2 % | wip_age | -0.2 % | -10.3 % | -0.0 % | passed_no_visible_change, not_constraint_on_wait_step |
| expert | unused_capacity | 1 | use_it_or_lose_it | 0.90 | yes | cause_right | lead_time | +3.8 % | lead_time | +3.8 % | -4.0 % | -2.1 % | not_constraint_on_wait_step |
| expert | silo_kpis | 1 | obeya_end_to_end | 0.90 | yes | cause_right | first_time_right | +79.1 % | first_time_right | +79.1 % | +1.6 % | -3.0 % |  |
| average | training_tray | 1 | tray_labels | 0.63 | yes | cause_right | capacity | +7.0 % | capacity | +7.0 % | – | +7.0 % |  |
| average | custom_design | 1 | use_it_or_lose_it | 0.10 | no | mismatch | throughput | +0.0 % | throughput | +0.0 % | – | +0.6 % |  |
| average | not_at_home | 1 | request_permits_daily | 0.10 | no | mismatch | first_time_right | -12.3 % | first_time_right | -12.3 % | – | +0.0 % |  |
| average | wrong_joint_in_van | 1 | standard_van_stock | 0.72 | yes | cause_right | wip_age | +100.0 % | on_time | -12.8 % | – | +26.0 % | passed_problem_kpi_worse |
| average | custom_design | 2 | delegated_approval | 0.55 | yes | cause_right | throughput | +7.3 % | throughput | +7.3 % | – | +16.8 % |  |
| average | not_at_home | 2 | appointment_reminder | 0.90 | yes | cause_right | on_time | -8.4 % | first_time_right | -10.3 % | – | -11.3 % | passed_lagging_kpi_worse, passed_problem_kpi_worse, constraint_fixed_no_capacity_gain |
| average | knowledge_drain | 1 | work_instruction_videos | 0.72 | yes | cause_right | lead_time | +5.6 % | on_time | -6.2 % | – | -33.9 % | passed_problem_kpi_worse, constraint_fixed_no_capacity_gain |
| average | incomplete_application | 1 | skills_matrix_buddy | 0.10 | no | mismatch | lead_time | +2.2 % | lead_time | +2.2 % | – | +1.9 % |  |
| average | planning_reshuffle | 1 | daytime_outage_crew | 0.90 | yes | cause_right | first_time_right | +5.3 % | first_time_right | +5.3 % | – | +2.6 % |  |
| average | permits_in_batches | 1 | request_permits_daily | 0.90 | yes | cause_right | throughput | -5.1 % | lead_time | -6.7 % | – | +2.6 % | passed_leading_kpi_worse, passed_problem_kpi_worse |
| average | incomplete_application | 2 | intake_checklist | 0.56 | yes | cause_right | lead_time | -29.4 % | lead_time | -29.4 % | – | +10.0 % | passed_lagging_kpi_worse |
| average | silent_meter | 1 | on_site_comm_test | 0.90 | yes | cause_right | first_time_right | -18.0 % | first_time_right | -18.0 % | – | +13.7 % | passed_lagging_kpi_worse |
| average | installer_not_ready | 1 | request_permits_daily | 0.10 | no | mismatch | lead_time | +13.2 % | lead_time | +13.2 % | – | -3.9 % | failed_but_kpi_improved |
| average | inverters_tripping | 1 | tap_review_per_neighbourhood | 0.90 | yes | cause_right | on_time | +0.0 % | first_time_right | +0.0 % | – | +7.5 % | passed_no_visible_change |
| average | installer_not_ready | 2 | readiness_check | 0.90 | yes | cause_right | throughput | +53.5 % | lead_time | +0.9 % | – | +2.9 % |  |
| average | status_callers | 1 | connections_wip_limit | 0.10 | no | mismatch | on_time | -22.2 % | on_time | -22.2 % | – | +0.0 % |  |
| average | status_callers | 2 | realistic_promise | 0.63 | yes | cause_right | on_time | -26.6 % | on_time | -26.6 % | – | -0.0 % | passed_lagging_kpi_worse, constraint_fixed_no_capacity_gain |
| average | done_but_not_closed | 1 | close_out_at_completion | 0.90 | yes | cause_right | lead_time | -6.5 % | lead_time | -6.5 % | – | +0.0 % | passed_lagging_kpi_worse, not_constraint_on_wait_step |
| average | revision_backlog | 1 | on_site_comm_test | 0.10 | no | mismatch | lead_time | +20.0 % | throughput | +82.5 % | – | +0.0 % | failed_but_kpi_improved |
| average | revision_backlog | 2 | daily_revision_template | 0.63 | yes | cause_right | throughput | -32.9 % | throughput | -32.9 % | – | -0.0 % | passed_leading_kpi_worse |
| average | digging_damage | 1 | contractor_briefing | 0.56 | yes | cause_right | lead_time | +10.6 % | lead_time | +10.6 % | – | +16.4 % |  |
| average | grid_study_queue | 1 | triage_fast_lane | 0.90 | yes | cause_right | on_time | -8.0 % | throughput | +14.3 % | – | +33.9 % | passed_lagging_kpi_worse |
| average | transformer_wait | 1 | early_transformer_order | 0.90 | yes | cause_right | wip_age | +0.0 % | wip_age | +0.0 % | – | +0.5 % | passed_no_visible_change, not_constraint_on_wait_step |
| average | unused_capacity | 1 | capacity_usage_dashboard | 0.63 | yes | cause_right | throughput | -25.0 % | lead_time | -12.7 % | – | -2.2 % | passed_leading_kpi_worse, passed_problem_kpi_worse, not_constraint_on_wait_step |
| average | silo_kpis | 1 | triage_fast_lane | 0.10 | no | mismatch | first_time_right | +29.4 % | first_time_right | +29.4 % | – | +0.3 % | failed_but_kpi_improved |
| average | silo_kpis | 2 | connections_wip_limit | 0.72 | yes | cause_right | first_time_right | -38.1 % | first_time_right | -38.1 % | – | -2.1 % | passed_lagging_kpi_worse |

Expert and average, first seed; Δ is the relative change, positive = better; the no-fix twin is the expert's counterfactual. All Checks (expert 57 of 57 passed; average 76 of 100 passed; careless 143 of 606 passed) are in the JSON.

## The fork (two main missions open at once)

| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |
|---|---|---|---|---|---|---|
| expert | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 11 | fix_incomplete_application | fix_installer_not_ready | no | no | +3.6 % |
| expert | 12 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 12 | fix_incomplete_application | fix_installer_not_ready | no | no | +3.6 % |
| expert | 13 | fix_incomplete_application | fix_incomplete_application | yes | no | +18.4 % |
| expert | 13 | fix_incomplete_application | fix_installer_not_ready | no | no | +3.6 % |
| average | 11 | fix_incomplete_application | fix_incomplete_application | yes | no | +10.0 % |
| average | 11 | fix_incomplete_application | fix_installer_not_ready | no | no | +2.9 % |
| average | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +3.5 % |
| average | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | -6.6 % |
| average | 13 | fix_installer_not_ready | fix_incomplete_application | yes | no | +10.0 % |
| average | 13 | fix_installer_not_ready | fix_installer_not_ready | no | no | +10.6 % |
| careless | 11 | fix_installer_not_ready | fix_incomplete_application | no | no | +43.3 % |
| careless | 11 | fix_installer_not_ready | fix_installer_not_ready | no | yes | -15.1 % |
| careless | 12 | fix_installer_not_ready | fix_incomplete_application | yes | no | +14.6 % |
| careless | 12 | fix_installer_not_ready | fix_installer_not_ready | no | yes | -40.2 % |
| careless | 13 | fix_incomplete_application | fix_incomplete_application | no | no | +74.1 % |
| careless | 13 | fix_incomplete_application | fix_installer_not_ready | no | no | +14.3 % |

The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.

## Coach

| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |
|---|---|---|---|---|
| go_see | 126 | 10 | 21 | "Wat wil je bereiken? Hoe ziet het eruit als het hier goed loopt?" (14) |
| understand | 108 | 14 | 33 | "Hoe is de situatie nu, in cijfers?" (12) |
| experiment | 108 | 6 | 9 | "Wat is je volgende stap, en wat verwacht je dat er gebeurt?" (12) |
| reflect | 108 | 10 | 21 | "Wat had je verwacht, en wat gebeurde er echt?" (12) |

## Accessors GameSession lacks (the playtester reads Region/Missions instead)

- `abandon(mission_id)`: Missions.abandon exists but the facade has no action; a stuck player cannot drop a mission.
- `kpi_review(choices)` and `kpi_review_due()`: Region.kpi_review is not reachable through GameSession, so the quarterly review (and its large reward, KpiBoard.REVIEW_XP/REVIEW_BUDGET) is not played here.
- `mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.
- `stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.
- `problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.
- `wait(minutes)` / `next_day()`: time only passes through tools and Checks; with every mission waiting on a fade or nothing active the player cannot let time pass.
- `act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently).
