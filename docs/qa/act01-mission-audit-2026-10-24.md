# Act 0 and Act I mission audit (2026-10-24)

Lane M-B, the mission auditor. Scope: the five training days (`training_mon` to `training_fri`), the Act I mains (`walk_connections`, `fix_custom_design`, the fork `fix_incomplete_application` / `fix_installer_not_ready`, `fix_status_callers`, `fix_done_but_not_closed`), the milestones `winter_el_amrani` and `review_100_days`, and the Act I sides (`walk_outages`, `walk_meters`, `fix_wrong_joint`, `fix_not_at_home`, `fix_permits_in_batches`, `look_at_grid_study`, `save_henks_knowledge`, `fix_planning_reshuffle`, `talk_netplanner`, `lsw_gemba_round`, and the way back: `fix_double_visits`, `fix_overtime_planning`). Method and tools as in the Act II audit (`docs/qa/act2-mission-audit-2026-10-24.md`).

Each mission is held against:
- CLAUDE.md's seven mission criteria: real, entertaining, intriguing, challenging, draws in, intuitive, correct;
- the three reward principles: long term, respect for people, always improve;
- `tests/test_mission_shape.py` (face, number, choice).

Talk lines (`dialogs.yaml`) and scene lines were read, not changed: the Act I talk rewrite waits for Merijn's playtest. One gemba question in `places.yaml` changed (a family name, see training_thu).

**Evidence used:**
- the content;
- every Act I countermeasure's effectiveness at maturity 1 and 2 (`Pdca.effectiveness`), and which ones the A3 offers (`Region.available_countermeasures`: at most one tier above the maturity);
- the Check numbers of the last autoplay (`docs/qa/autoplay-report.json`, seed 11 expert/average/talker/never-talks, careless 11 and 12), including the repair quests each persona got;
- the simulation's own numbers in `value_streams.yaml` and the followed El Amrani order (`FollowedOrder`).

**Act I is played at maturity 1.** Maturity 2 needs twelve of the twenty tier-1 problems resolved; the expert has nine when it takes the last Act I main (day 62). So the A3 offers tier 1 and 2 in Act I, never tier 3. Several findings below follow from that.

Scores run from 1 (fails) to 5 (strong). "Before → after" marks what this audit changed.

## Headline

Act I's problems are real and well chosen:
- maatwerk voor standaardwerk;
- a web form that lets you click past the details (poka-yoke);
- a readiness check before the monteur rides;
- failure demand at the KCC (Seddon);
- a monthly batch at close-out;
- the fork that teaches the bottleneck.

The faces come first: Joost, Sanne, Marco, Esra, Petra, Henk. The numbers mostly agree with the stream.

It was weakest on four points, all fixed in content or rules unless marked open:
1. **The best play was punished.** In `fix_wrong_joint` every fix the A3 offers in Act I was a poor fix: the best fit (two-bin kanban) is tier 3 and never offered at maturity 1. Even the expert persona got a repair quest and Ruud's long-term-cost line. `fix_status_callers` was the same for the patient "by hand first" step: the milestone mail was 0.05 under the poor-fix line.
2. **The designed failed Check could not happen.** `fix_done_but_not_closed`'s best-written text (the `too_early` debrief) needs automatic EAN registration, but at tier 3 Act I's A3 never offered it. No autoplay persona ever saw it.
3. **Debriefs described the best fix to a player who chose a passing poor fix.** Five missions had no `poor_fix` debrief: the intake checklist, the reserve job, the status page, the second monthly run, the refill card. The training Friday told a player with two labelled trays that "iedereen pakt het oudste dossier uit één bak".
4. **Stories that disagree with the simulation.**
   - The El Amrani dossier is a real order that sits at Intake until the intake fix holds. Thursday's briefing put it "nine days at Anouk's", and `fix_done_but_not_closed` said her heat pump runs. That could come before the winter milestone fails with "In Nova-Oost staat een warmtepomp nog steeds uit". The clue journal even shows "ligt nu bij Intake".
   - Monday's debrief said "Elf weken" whatever the letter said.
   - The family Bos waited three weeks in a batch that is at most two.
   - The status callers "already waiting three weeks" call only after nine (`status_calls.after_days: 63`).
   - The fork's debriefs claimed a throughput the Check does not always show (see the fork).

**The fork works.** A player who takes the monteurs first gets the Check's "dit was niet het knelpunt" line. The stream's capacity does not move (+0.0 %). A player who takes the intake first gets +4.6 % throughput on the expert run. Two cracks, now honest in the text:
- The Check table can still show a small green throughput rise for the non-bottleneck branch (+4.6 % on the average run). Orders that wait less finish earlier inside the Check's window. The debrief now names it ("klanten die eerder aan de beurt waren, geen extra klanten"). The table itself is an open item.
- Done second, the monteurs can be the constraint by then (expert: the constraint was the monteurs at day 47). The second branch's debrief no longer claims "het knelpunt zat al ergens anders".

**Henk's deadline works**, and it closes the right doors (the buddy, TWI, Henk's one-point lessons). One trap after the door closed: a poor fix brought a repair quest that could never be done. The better fix was closed, and a rework must choose another one. Careless seed 12 gave it up after 56 days. The rule is now fixed: a repair measures against the best fix still open.

## Per mission

### training_mon — Rondleiding

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | A letter from a waiting customer on the first morning; the weeks are the real order's age. |
| Entertaining | 4 | The letter and Anouk at seven. |
| Intriguing | 4 | "Hoeveel uur is er al echt aan gewerkt?" sets up lead time against touch time. |
| Challenging | 2 | A walk; fine for day one. |
| Draws in | 5 | Ruud speaks to the player; the letter is addressed to Voltana. |
| Intuitive | 5 | M for the map, two places. |
| Correct | 3 → 5 | The debrief said "Elf weken onderweg" while the briefing reads `{dossier_weken}`. Now "al weken onderweg". |

### training_tue — Kijken zonder oordeel

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Gemba without judgement; two tools that show different things. |
| Entertaining | 3 | Quiet by design. |
| Intriguing | 4 | "Anouk werkt snel. Toch ligt er veel." |
| Challenging | 3 | Pick two different tools. |
| Draws in | 4 | Anouk alone, her colleagues on a course. |
| Intuitive | 5 | |
| Correct | 5 | |

### training_wed — Waar zit de stapel?

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Count work in days, not dossiers: a correct, often-missed TOC point. |
| Entertaining | 3 | |
| Intriguing | 4 | "Schrijf het op voordat je het met je gevoel vergelijkt." |
| Challenging | 3 | The staged setup makes the answer clear. |
| Draws in | 3 | |
| Intuitive | 5 | |
| Correct | 5 | The setup (three of four preparers on a course) is marked as staged. |

**Note:** it teaches `netcongestie` too, which this day does not touch. It is harmless, and the card belongs to `talk_netplanner`. Not changed.

### training_thu — Een klein experiment

| Criterion | Score | Reason |
|---|---|---|
| Real | 4 | Two trays for one kind of work; invented and harmless, as Merijn decided. |
| Entertaining | 4 | |
| Intriguing | 4 | "Anouk pakt altijd het oudste dossier. Toch ligt er een al negen dagen." |
| Challenging | 4 | The first A3 with a prediction, checked the next day. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 1 → 5 | The dossier nine days at Anouk's was the El Amrani one. That order is real and waits at Intake until the intake fix holds (S2-M's loop), so the clue journal said "ligt nu bij Intake" next to a briefing that said Werkvoorbereiding. It is now the family Koster's dossier. The steps and the blame question at Werkvoorbereiding ("Wie heeft het dossier van de familie Koster laten liggen?") follow. |

### training_fri — Borgen of laten wegzakken

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Standardise or watch it fade, with a month's time-lapse. |
| Entertaining | 4 | The time-lapse. |
| Intriguing | 4 | "Weten zij van de ene bak?" |
| Challenging | 3 | A clear choice with a cost. |
| Draws in | 4 | Joost's request for two people is the hook into Act I. |
| Intuitive | 5 | |
| Correct | 3 → 5 | Both debriefs spoke of "één bak", false after the labelled trays (`tray_labels`, which the average persona chose). Now: "werkt iedereen nog zoals jullie het hebben afgesproken" and "wordt er weer gezocht en omgesorteerd". |

### walk_connections — Volg het dossier

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Walk one connection before you change anything. |
| Entertaining | 3 | |
| Intriguing | 4 | "Waar zou jij als dossier het liefst niet liggen?" |
| Challenging | 2 | |
| Draws in | 4 | The family's dossier. |
| Intuitive | 5 | |
| Correct | 3 → 5 | "Een paar uur werk" undersold it. The stream's touch hours add up to about fifteen (14.5, plus 4 for the quarter with a grid study), so it now says "zo'n vijftien uur werk, verdeeld over een handvol teams", with the sum in a comment. The Measure directive asks for that number. |

### fix_custom_design — De stapel bij Werkvoorbereiding

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Standard work for standard connections: Enexis's standard stations are the real case (capaciteit_gevonden). |
| Entertaining | 4 | Anouk at seven in the evening; Joost's two vacancies. |
| Intriguing | 4 | "Wat is hier echt aan de hand?" The name is the symptom. |
| Challenging | 4 | Delegated approval (0.55) passes as a poor fix; standard designs (0.9) is the patient one. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 5 | Throughput +8.7 % (expert), the constraint moves to Intake. Titles now come from company.yaml. |

**Discovery added:** `het_volgende_knelpunt`. The player counts the queue at Intake while the stack at Werkvoorbereiding is open. Intake is where the work will wait once design is faster (autoplay: work_prep → intake), and the debrief's own question points there.

### The fork: fix_incomplete_application (bottleneck) and fix_installer_not_ready (non-bottleneck)

| Criterion | Incomplete | Installer | Reason |
|---|---|---|---|
| Real | 5 | 5 | Poka-yoke at the web form; a readiness check 48 hours ahead. Both are textbook and both are in the sector. |
| Entertaining | 4 | 4 | Sanne's "postkantoor", Marco's lost hours. |
| Intriguing | 4 | 4 | Symmetric briefings, a true number each, neither names a queue. The player has to count (`het_knelpunt_eerst`). |
| Challenging | 5 | 4 | A real choice; each has a shortcut that passes as a poor fix. |
| Draws in | 4 | 4 | Two team leads asking for you. |
| Intuitive | 4 | 4 | |
| Correct | 3 → 5 | 2 → 4 | See below. |

**Does the Check show no flow gain for the non-bottleneck?** Yes, as a verdict. Average seed 11, installer first (day 33): `not_constraint`, capacity +0.0 %, and the panel says "de stroom levert niet meer". But the table showed throughput +4.6 % (on another run −1.2 % and +3.4 %). Orders that no longer ride for nothing finish sooner inside the Check's window: a transient, not more capacity.

The installer debriefs said "er gaan niet méér aansluitingen per week door". That is the wrong number to promise. They now speak of what the stream can handle per week (capacity, which did not move), and the first-branch debrief explains a small rise as "klanten die eerder aan de beurt waren, geen extra klanten" (Little's law). Done second, the installer branch can meet the monteurs as the constraint (expert, day 47, throughput +3.1 %), so its debrief no longer says the bottleneck was elsewhere.

**Poor fixes:**
- The intake checklist (0.56) and the reserve job (0.54) pass, and both debriefs described the poka-yoke and the readiness check.
- New `poor_fix` debriefs: "elke fout wordt nog gemaakt, alleen eerder gevonden", and "de klant ... hoort het nog steeds pas als de monteur voor de deur staat".

**Deadline in the fork:** El Amrani's dossier only gets through when the intake fix holds (S2-M's loop). A player who takes the monteurs first loses weeks towards the winter milestone. That is the fork's real stake and a good one; nothing tells the player in words, and the clue journal shows it ("ligt nu bij Intake").

### fix_status_callers — De telefoon staat roodgloeiend

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Failure demand (Seddon). Four extra agents is the reflex. |
| Entertaining | 4 | Mrs El Amrani's fourth call. |
| Intriguing | 4 | "Wie bellen er eigenlijk, en waarom?" |
| Challenging | 3 → 4 | At maturity 1 the patient fixes were either poor (the hand-made mail at 0.75, under the 0.8 line) or barely working (proactive messages, tier 2, at exactly 0.50). The expert persona picked the status page and got a repair quest. |
| Draws in | 4 | Esra is a face. |
| Intuitive | 4 | |
| Correct | 3 → 5 | Changes: (a) the mail by hand is now 0.85 (eff 0.77): Pareto on a week's tally takes most of the calls, and it fades sooner than the built-in messages; (b) a `poor_fix` debrief for the status page ("wie niet kijkt, hoort nog steeds niets"); (c) the data clue said callers wait "meer dan drie weken", but the stream lets them call from nine weeks (`after_days: 63`), so now "meer dan twee maanden". |

### fix_done_but_not_closed — Klaar maar niet af

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | A monthly batch at close-out; the EAN in the C-AR. |
| Entertaining | 4 | A heat pump off for a missing code. |
| Intriguing | 5 | "Bij Meetdata heeft Petra tijd over. Ergens ligt werk dat niemand ziet." |
| Challenging | 2 → 5 | The designed failed Check could not happen: automatic EAN registration was tier 3 and the A3 never offers tier 3 at maturity 1. Now tier 2: it is offered and works at `reduced` (0.45 < 0.5). The `too_early` debrief ("dat helpt maar half") now fires. A Godot test proves it on the real network, and that the close-out at completion passes on lead time. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 2 → 5 | Two fixes: (a) the family was El Amrani, whose real order decides when her heat pump runs (winter_el_amrani), so "De warmtepomp van de familie El Amrani draait" could precede "staat nog steeds uit". It is now the family Hendriks; Petra's opening ("de EAN van die familie") already fits any family. (b) A `poor_fix` debrief for the second monthly run: "De batch is kleiner, niet weg." |

### winter_el_amrani — Voor de vorst (milestone)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | A frost period, estimated with KNMI reasoning in the file. |
| Entertaining | 5 | Her call and her letter. |
| Intriguing | 4 | The hidden proposal (check the existing connection) rewards the listener. |
| Challenging | 4 | Only the bottleneck branch or listening gets her warm in time. |
| Draws in | 5 | The most personal deadline in the act. |
| Intuitive | 3 | The deadline is a date; the board shows it. Whether the player connects it to the fork depends on reading the dossier card. |
| Correct | 5 | The door closes and opens later doors (flags for Act III and IV). |

Not changed (S2-M's lane).

### review_100_days — Honderd dagen (milestone)

Audited in the Act II audit (same scene). Not changed.

### walk_outages — Een nacht met de storingsdienst

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | The compensation rule is real. ACM: up to 3x25A, € 35 for 4 to 8 hours, € 20 for every 4 hours more, paid unasked. Now cited in the file. |
| Entertaining | 4 | Ahmed, the night, the clock. |
| Intriguing | 4 | "Waar gaat de tijd naartoe?" |
| Challenging | 2 | A walk. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 3 | The debrief says Ahmed drove for a joint. Lane G-A makes that trip a counted event, so it may not happen on the player's walk. **Open** (G-A's lane): make the debrief read the walk, or keep it as told. |

### walk_meters — Acht adressen

| Criterion | Score | Reason |
|---|---|---|
| Real / Correct | 5 | Eight addresses a day matches the stream (40 a week). Three not at home matches visit FTR 0.8 − 0.15. |
| Others | 3–4 | A good question to answer by looking. |

### fix_wrong_joint — De verkeerde mof in de bus

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Van stock without a standard or a signal. |
| Entertaining | 4 | 140 households × € 35 (correct per the ACM). |
| Intriguing | 5 | "Ze hebben allebei gelijk. Hoe kan dat?" |
| Challenging | 1 → 4 | Every fix the A3 offers in Act I was a poor fix. The refill card fit 0.65 and the standard stock 0.8, against the kanban's 1.0, which the A3 offers only from maturity 2. The expert, the talker and the never-talks persona all got `repair_wrong_joint_in_van`. The standard stock is now 0.85: its own description refills at the end of every shift, so it removes most of the cause. The kanban stays the better, built-in fix for later. |
| Draws in | 4 | Dirk is a face. |
| Intuitive | 4 | |
| Correct | 2 → 5 | The debrief said "een lege bak zegt Dirk wat hij moet aanvullen": the kanban, which Act I never offers. It now holds for the standard stock and the kanban. A `poor_fix` debrief for the refill card: a forgotten stripe leaves exactly that slot empty. |

**Not touched** (lane G-A): the problem's effects, the "materiaal halen" trip, the yard tells and the data clue's "een kwart". Once G-A counts the trip, check that "een kwart van de storingslogboeken" matches.

### fix_not_at_home — Niet thuis

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | A full-day window with no reminder. |
| Entertaining | 4 | Meneer De Jong's half day off. |
| Intriguing | 5 | "Wie is hier eigenlijk niet thuis?" |
| Challenging | 3 | The two-hour window (tier 2) fails too early; the reminder passes. No shortcut; fine for a side. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 5 | The numbers match the stream (see walk_meters). |

### fix_permits_in_batches — Vergunningen in batches

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Batching at a wait step: no capacity, all lead time. |
| Entertaining | 3 | |
| Intriguing | 4 | "De gemeente haalt haar termijn bijna altijd. Waar wacht het dossier dan op?" |
| Challenging | 3 | Request daily passes; parallel permits is tier 3, so not offered in Act I. |
| Draws in | 3 | |
| Intuitive | 4 | |
| Correct | 2 → 5 | Two fixes: (a) "al drie weken klaar" did not fit a batch of at most fourteen days (`batch_days: 14`, a week on average as the clue says), so now "bijna twee weken"; (b) the debrief described parallel permits ("zodra het tracé bekend is"), which Act I never offers. It now says "zodra het klaar is", and Bos's application went out the day her dossier was done. |

### look_at_grid_study — Het bord van Femke

| Criterion | Score | Reason |
|---|---|---|
| Real / Correct | 5 | |
| Intriguing | 4 | A side that seeds Act II's main. |
| Others | 3–4 | |

### save_henks_knowledge — Henks kennis

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | The technician shortage and retiring experts; GPLK cable. |
| Entertaining | 5 | The farewell invitation on the board; Henk saying nothing as the compliment. |
| Intriguing | 3 | The briefing says what is at stake ("Zorg dat Henks vakmanschap niet met hem de deur uit gaat"). That is acceptable for a deadline mission: the door must be visible. |
| Challenging | 4 | Four fixes. Videos and one-point lessons are poor, TWI and the buddy are the patient ones; the buddy is tier 2 (0.5 at maturity 1). |
| Draws in | 5 | |
| Intuitive | 4 | Eight weeks in the briefing = `deadline_days: 56`; the clue says "over twee maanden". |
| Correct | 4 → 5 | After the deadline only the videos remain, a poor fix, so the long-term line and the poor_fix debrief are honest ("lasting consequences"). But the poor fix also opened a repair quest asking for "een andere tegenmaatregel" when none was left. Careless 12 gave it up after 56 days. Fixed in `Repairs.kpi_gap`: it measures against the best fix still open, and a closed one never brings a repair (Godot test). |

### fix_planning_reshuffle — De planning die nooit klopt

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Planning at 100 % breaks on the first outage (Kingman). |
| Entertaining | 4 | Linda working harder than ever. |
| Intriguing | 3 → 4 | The briefing ended "Maar zijn storingen eigenlijk een verrassing?", which is nearly the answer (plan for them). Now: "Waar komen al die wijzigingen vandaan?" |
| Challenging | 4 | The daytime crew passes; fault windows (tier 2) is too early in Act I. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 5 | One in three moved fits the execution FTR with the effect. |

### talk_netplanner — Waarom is het net vol? / lsw_gemba_round — De gemba-ronde

Both are sound: a real expert talk, and leader standard work that asks rather than claims. Not changed.

### fix_double_visits / fix_overtime_planning (the way back)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Old cupboards seen at the door, not at planning; zigzag routing. Costs are estimates, marked. |
| Challenging | 4 | |
| Correct | 3 → 5 | Each `poor_fix` debrief describes the shortcut (the customer reports, the overtime cap). But the register check (0.8) and the district teams (0.8) were also poor and got the same text, which describes something they did not do. Both are real fixes of the root cause, built in: now 0.85 each, so the poor-fix text belongs to the shortcut alone. |

**Tell:** the planning board read "de meterwissels van één monteur verspreid over vier wijken". That is the shadow clue (the cause). It now shows the symptom: an overtime hour in red behind the meter fitters' names.

## Act II sides found on the way

`fix_silent_meter` and `fix_inverters_tripping` (act 2) have passing poor fixes (the coverage check 0.72; the one-station trial and the smart-meter data) and debriefs that described the best fix. They now have `poor_fix` debriefs. They are outside the Act II audit's scope (mains only).

## New checks

- `tests/test_act_fixes.py` (content, at each act's maturity):
  - the patient fix is reachable in its act;
  - a `too_early` debrief's failed Check can happen;
  - every solve mission (training aside) whose problem has a passing poor fix has a `poor_fix` debrief.

  It failed on 9 missions before these changes.
- `game/tests/test_act1_fixes.gd`: the designed failed Check of Klaar maar niet af on the real network.
- `game/tests/test_repairs.gd`: no repair quest when the better fix is closed.
- `game/tests/test_discoveries.gd`: `het_volgende_knelpunt`.

## Open items for Merijn and other lanes

1. **The Check table's throughput row for a non-bottleneck fix** can show a green rise (+3 to +5 %) next to "dit was niet het knelpunt". The debriefs now explain it. A cleaner fix is a UI/rules change: show the stream's capacity next to throughput in the table, or mark changes within a band as "gelijk". Merijn's call (UI).
2. **The maturity rule versus the designed-failed-Checks spec.** The spec assumed tier 3 works at `minimal` in Act I, but the A3 offers at most one tier above maturity. This audit moved automatic EAN to tier 2 instead of changing the rule. If you prefer the rule "offer up to two tiers above", every tier-3 fix becomes visible (and failing) in Act I. Your call.
3. **`walk_outages`' debrief** asserts the joint trip; G-A is making it a counted trip. Make the debrief read the walk, or keep it as Ruud's summary (G-A).
4. **`fix_status_callers`' plain debrief** says Mrs El Amrani "kreeg een bericht en hoefde niet meer te bellen". It is true unless she was connected before the fix (then she stopped calling for another reason). Harmless, but the El Amrani lines in missions could read the followed order, like `{dossier_weken}`, for example a `{dossier_stap}` token (S2-M / S2-L).
5. **Problem names that name the cause** (seen in the A3 and the journal once spotted): "Maatwerk voor standaardwerk", "De statusbellers", "De laatste kennisdrager". Same question as Act II's item 4.
6. **The fork has no words for its real stake** (El Amrani's winter). A line in Ruud's go_see insight for the fork ("Wie van de twee houdt het dossier van de familie El Amrani tegen?") would make it felt. It is a coach line, so it waits for the talk rewrite.

## Calls made on Merijn's behalf

| Call | Cost if wrong |
|---|---|
| `automatic_ean_registration` is tier 2 (was 3), so the designed failed Check happens in Act I | From maturity 2 the automatic registration works at 0.81 and becomes a strong option. It was at most 0.45 before. If "a system integration is tier 3" matters more than the designed failure, revert one line and the Python test names the failure. |
| `standard_van_stock` fit 0.85 (was 0.8) | The standard stock is no longer a poor fix, so no repair quest nudges a player towards the kanban. The kanban still fits 1.0 and never fades. |
| `milestone_mail_by_hand` fit 0.85 (was 0.75) | The hand-made mail is now the best working fix at maturity 1 (0.77 against proactive's 0.50). That is Lean ("by hand first"); proactive messages win on durability. |
| `register_cupboard_check` and `area_teams` 0.85 (were 0.8) | Way-back fixes that do not fade are no longer poor. A player in debt has two good fixes instead of one. |
| Other families instead of El Amrani in training_thu (Koster) and done_but_not_closed (Hendriks) | The throughline loses two mentions. In exchange it never contradicts her real order or the winter milestone. Her own story now lives in the letter, the dossier card, the calls and the winter. |
| A gemba question in `places.yaml` names the family Koster | Changes a question the player asks (not a talk line), to keep the blame trap consistent with Thursday. |
| Repairs measure against the best fix still open | A repair quest never asks for the impossible. A closed best fix still makes the chosen one a poor fix (the long-term line and the poor_fix debrief stay: the door closed). |
| The training days have no `poor_fix` debrief; their texts hold for every fix | Friday's lesson stays borgen, not the fit. |
| One discovery (`het_volgende_knelpunt`), no reputation | A small, quiet reward for looking where the constraint goes next. |
