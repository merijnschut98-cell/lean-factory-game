# Act II mission audit (2026-10-24)

Lane M-A, the mission auditor. Scope: the six Act II main missions (`fix_digging_damage`, `fix_revision_backlog`, `fix_grid_study_queue`, `fix_transformer_wait`, `fix_unused_capacity`, `fix_silo_kpis`), the milestone `first_kpi_review` and the day-100 milestone `review_100_days`, in `content/missions.yaml`, `problems_tier1.yaml`, `countermeasures.yaml` and `scenes.yaml`.

Each mission is held against:
- CLAUDE.md's seven mission criteria: real, entertaining, intriguing, challenging, draws in, intuitive, correct;
- the three reward principles: long term, respect for people, always improve;
- `tests/test_mission_shape.py`: a face before the numbers, a number with a unit in the briefing, and a tempting shortcut with a later cost.

Talk lines (`dialogs.yaml`) and scene lines were read but not changed: the Act II talk rewrite waits for Merijn's playtest.

**Evidence used:**
- the content itself;
- the effectiveness of every countermeasure at Act II's maturity (2) and at 3 (`Pdca.effectiveness`: the tier multiplier times the fit);
- the Check numbers of the last autoplay run (`docs/qa/autoplay-report.json`: expert, average, talker and never-talks on seed 11, careless on seeds 11 and 12).

Scores run from 1 (fails) to 5 (strong). "Before → after" marks what this audit changed.

## Headline

Act II is the strongest act on **real problems with real fixes**:
- KLIC maps that lag the ground;
- a revision backlog drawn twice;
- exploiting the grid-study constraint before elevating it (Goldratt's order);
- trafo lead times you cannot change but order timing you can;
- unused contracted capacity under the ACM's GOTORK rule;
- department KPIs that fight the flow (Goodhart).

Every Lean method named is the right one, and every main passes the shape test.

It was weakest on four points:
1. **Intrigue.** Two briefings and two mission names handed over the cause, and one tell did too:
   - "Gereserveerd maar ongebruikt" and "KPI's die elkaar bevechten" as names;
   - "de hal is leeg" in Ilse's briefing;
   - Femke's "vijf minuten werk", which is her own key clue;
   - the congestion list's "hal staat leeg".
2. **Correctness of the debriefs.** Every plain debrief described the best fix. A player who chose a passing poor fix (overtime, a dashboard, a stock, a WIP limit) was told the opposite of what they did. For example, "Je hebt het knelpunt eerst beter benut" was said after six weeks of overtime.
3. **One dead shortcut.** The trafo stock, the only tempting shortcut of `transformer_wait`, failed every Act II Check at tier 3 (0.40). The choice the shape test counts on was never real in play.
4. **Two missing levers.** There is no fork in Act II (Act I has one) and no deadline (Act I has the winter). Both are design calls for Merijn.

Points 1–3 are fixed in content (commits below). Point 4 is an open item with a concrete proposal.

## Per mission

### fix_digging_damage — Graafschade

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | KLIC-melding, outdated maps, skipped proefsleuven: the real Dutch pattern. The damage counts fit Wibon's national count (now noted in the content). |
| Entertaining | 4 | It opens hard: 10.12 on a Tuesday, De Linde on the generator, Gert holding his KLIC printout. |
| Intriguing | 4 | "Volgens deze kaart lag hier niks" points at the map without saying why it is wrong. |
| Challenging | 5 | The designed failed Check. Revision at the source is right but too early (0.30 at maturity 2), and the too_early debrief sends the player back. |
| Draws in | 4 | Gert is a face, and the containment ("stop en bel") lets the player act on day one. |
| Intuitive | 4 | Clear steps. The KPI is the monteurs' capacity, not "graafschades per week", which is what the player thinks in. |
| Correct | 3 → 4 | It said "de vijfde graafschade deze maand", but the simulation adds five a week (a third of 15 daytime outages) and charges 5 × € 850 a week. Now "deze week", with the reasoning in a comment (Wibon 46,799 a year, a region at about 2 %). The 7 % of digs that hit a cable is marked as an estimate. |

**Principles:**
- Long term: trenches (60 days) outlast the briefing (30 days).
- Respect: the blamed variant shows Gert closing up.
- Always improve: the reflect question asks who keeps the map, which leads into the next mission.
- Shape: Gert's talk comes before the dig, "Driehonderd huizen" is the number, and the contractor briefing is the shortcut that fades sooner.

**Open:**
- The Check's KPI is capacity, while the outage stream's throughput falls by 15 % with the fix. Fewer outages is good news, but wherever the stream's throughput is shown as a KPI (the Check's other numbers, the KPI board; the coach's phrase for it is "Er komen nu X per week klaar") it reads as a loss. Not checked on screen in this audit. Proposal: let the coach phrase the outage stream's throughput as "storingen per week", or give the problem a "demand" KPI. That is a rules change, Merijn's call.
- `standard_test_trenches` takes its team hours from `key_accounts` (the large-customer desk). It is probably meant to be the storingsdienst or Werkvoorbereiding, who brief contractors. This changes the simulation, so it is not changed here.

### fix_revision_backlog — De revisieberg

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Paper as-built sketches drawn again in GIS weeks later is double work at every netbeheerder that has not digitised the field. |
| Entertaining | 4 | The sketch on a boterhamzakje. |
| Intriguing | 4 | It follows Gert's cable upstream. The briefing asks "hoe oud, en waarom?" instead of answering. |
| Challenging | 4 | The right fix (revision at the source, tier 3) just passes at maturity 2 (0.50). The shortcut template passes better now (0.63) but stays a poor fix. That is the long-term trade-off in its purest form. |
| Draws in | 4 | Mieke is a face; the box is a place. |
| Intuitive | 4 | Clear steps. |
| Correct | 3 → 5 | Three fixes: (a) the comment said the KPI was wip_age, but it is capacity; (b) "De oudste is van augustus" clashed with the clue's "vier maanden oud" for most start dates (Act II starts around day 90–300), so it is now "onderop liggen er van maanden terug"; (c) the numbers now carry a Little's law check (30 in a week, 240 open, the oldest four months: GIS draws about 15 a week and the box grew by about 15 a week). |

**Principles:**
- Long term: the patient fix scores no lower (both reach countermeasure score 5 when durable), avoids the poor-fix repair and never fades.
- Debrief: it read "de doos wordt kleiner" whatever was chosen. A **poor_fix** debrief now says the double work is still there, only faster.

### fix_grid_study_queue — De netstudie-wachtrij

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Every request above 3x25A gets a full study and there is no triage; it hits the technician and analyst shortage (Netbeheer Nederland). |
| Entertaining | 4 | Femke's long days and the school waiting nine weeks. |
| Intriguing | 3 → 4 | The briefing quoted Femke saying the study is "waarschijnlijk vijf minuten werk": her own conversation clue, given away up front. It now gives her struggle instead ("Er komen er elke week meer bij dan we af krijgen"), and the five minutes is for the player to hear. |
| Challenging | 5 | Exploit before elevate. Overtime and templates pass but are poor fixes. The overtime has an aftermath: the analysts' availability −10 %. |
| Draws in | 4 | |
| Intuitive | 4 | |
| Correct | 3 → 5 | The plain debrief ("Je hebt het knelpunt eerst beter benut") was said after the overtime sprint too. Now a **poor_fix** debrief: still every study, faster or longer, not fewer. The autoplay confirms grid_analysts is the stream's constraint throughout Act II, and triage adds about 42 % capacity. Throughput moves only 3–13 %, because demand limits it. The debrief names capacity, so that is honest. |

**Principles:**
- Respect: the overtime's aftermath is real.
- `capaciteit_gevonden` and the new `het_net_was_niet_vol` reward the patient fix.

### fix_transformer_wait — Wachten op de trafo

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Trafo lead times are the sector's daily news. Ordering after design approval puts the lead time in series with the design. |
| Entertaining | 4 | Hermans Bouw, 48 homes, five months. |
| Intriguing | 4 | "Dat klopt. Wat kunnen wíj dan nog doen?" invites the reframe. |
| Challenging | 2 → 4 | The only shortcut (the strategic stock, € 40,000) was tier 3 and worked at 0.40 at maturity 2: it failed every Act II Check. Now tier 1 (buying stock asks no maturity, which is why it tempts). It passes at 0.72 and stays a poor fix with a repair later, at a high price. |
| Draws in | 3 → 4 | The talk the mission needs is with Rob (`rob_order_rule`), but the briefing named only "het projectteam". Now Rob Verhagen, inkoper, says the line. |
| Intuitive | 4 | |
| Correct | 3 → 5 | The plain debrief said "we bestellen zodra de netstudie zegt…", which is false after a framework contract. It now holds for every fix: "wij hebben veranderd wanneer en hoe we bestellen". A **poor_fix** debrief for the stock covers what it hides: the late order, inventory, and three projects at once. |

**Note:** De Boomgaard is five months out and the lead time is six. Even ordering today is late, so "eerder stroom" (not "op tijd") is the honest claim, and it is the one the debrief makes.

### fix_unused_capacity — Twee jaar op de wachtlijst (was: Gereserveerd maar ongebruikt)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | GOTORK (ACM, 2024) is the real rule, with its thresholds (at most half used for twelve months, or 1 MW or more unused), now in the countermeasure's text. Non-firm and time-bound contracts are the real second route. |
| Entertaining | 4 | Ilse's bakery and the threat of the ACM. |
| Intriguing | 2 → 4 | Before, the name said the cause, and the briefing said "naast haar staat een distributiehal met twee megawatt gecontracteerd vermogen; de hal is leeg". That is the listen-in clue, given away, so "Is het dat ook?" had no tension. Now: the symptom as the name, Ilse's "de helft van de hallen staat 's avonds donker" as a hint, and the hall for the player to hear. |
| Challenging | 4 | The dashboard (shortcut) and flexible contracts (tier 3, fails at maturity 2) are both poor fixes, so only the gesprek is a full fix. |
| Draws in | 4 | Ilse and Thomas both have talks. |
| Intuitive | 4 | |
| Correct | 3 → 5 | The plain debrief claimed capacity "komt terug in de wachtrij". That is false after a dashboard. Now a **poor_fix** debrief: the old contracts are untouched and Ilse still waits next door. |

**Tell:** the congestion list's "in potlood: 'hal staat leeg'" named the cause. It is now a pencilled question mark: someone wondered.

### fix_silo_kpis — Twee recordmaanden (was: KPI's die elkaar bevechten)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | Local output and utilisation KPIs push defects downstream; the effects are modelled as KPI menus (Goodhart). |
| Entertaining | 5 | Marco's "Mooi. En wie bouwt jullie fouten na?" in the MT. |
| Intriguing | 2 → 4 | The name was the cause, and the briefing ended "Kijk wat hun cijfers van hen vragen": the answer. Now the symptom as the name, and a question: "Hoe kunnen twee teams allebei een record halen, terwijl de klant niets merkt?" |
| Challenging | 4 | Three passing fixes. Two are poor (WIP limit 0.8, shared goals 0.7), so the end-to-end obeya is the one to find. |
| Draws in | 4 | Sanne, Joost and Marco are named with their titles. |
| Intuitive | 4 | |
| Correct | 4 → 5 | A **poor_fix** debrief: each team still sees its own part. |

**Open:**
- The KPI is first time right, and it lags. One autoplay run (expert, seed 11) failed the obeya's first Check with "not_moved" (−0.7 %) and passed the second. That is noise in a lagging KPI; Act I's `incomplete_application` has the same note. If it shows up in playtests, give the Check a longer window for FTR (a rules change).
- `shared_team_goals` is tagged as the tempting shortcut, but shared goals are a respectable Lean step. The *really* tempting wrong move here is "tell them to slow down" or "more overleg", which are already plausible causes. Fine as is; noted.

### first_kpi_review — Het eerste kwartaal (milestone)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | A quarterly MT review of steering KPIs, with Frank's year plan as the real constraint. |
| Entertaining | 4 | Frank has a quarter of an hour. |
| Intriguing | 3 | The briefing says what happens; the intrigue is in which lines the play unlocks. |
| Challenging | 4 | The board choice (output, flow, customer) is answered by Ruud's El Amrani question, with no right answer marked. |
| Draws in | 5 | It reads the silo fix and Frank's talk outcome. |
| Intuitive | 4 | One step: go to Directie & Obeya. |
| Correct | 4 | Leading and lagging KPIs. The analysts' forecast is a real number. |

**Changed:** the briefing names Frank Hulshof with his title.

**Open:** the debrief and the last line promise "over een kwartaal kijken we of de getallen deden wat we dachten". Lane S3-B is building the `kpi_review` screen. If no second review comes, the promise breaks the always-improve principle. Keep the next review in S3-B's scope.

### review_100_days — Honderd dagen (milestone)

| Criterion | Score | Reason |
|---|---|---|
| Real | 5 | The 100-day talk with the manager. |
| Entertaining | 4 | Every line reads the play: who left, who committed, Henk's tang, El Amrani's call. |
| Intriguing | 4 | Ruud's "Hoe komt dat, denk je?" when a fix slid back. |
| Challenging | 3 | One choice (what to tell the directie). Its stakes are not visible yet. |
| Draws in | 5 | It is the most personal scene of the act. |
| Intuitive | 5 | |
| Correct | 4 | Frank "has the numbers" but never says one. The Measure directive asks for a number here (for example the stream's throughput then and now). That is a scene line, so it waits for the talk rewrite. |

**Changed:** the briefing names Frank Hulshof with his title.

## Hidden rewards added (discoveries.yaml)

| id | Trigger | Why it is deep thinking |
|---|---|---|
| `stroomopwaarts` | data at Revisie & GIS while the digging damage is open | Looking for the cause a floor up and a stream upstream (fix end to end). |
| `het_drukste_kwartier` | data at the congestion desk between 17.00 and 20.00 while Ilse waits | Whether a net is full shows at its peak, not on paper. The evening-peak hours are an estimate, noted in the file. |
| `het_net_was_niet_vol` | the three "Het net is vol" mains each scored 20 of 25 or more | Exploiting what is there before building more; reputation +2. |

All three use existing trigger types and stay within the rules: no XP, reputation at most +3, never a reward for the short-term choice. A Godot test covers the two place-and-hour ones on the real content.

## The title token

Briefings now name people as "Naam ({functie:<id>})". The build (`fill_titles`) fills in the title from `company.yaml`, so a briefing can never disagree with the name tags or Wie is wie. The build refuses:
- an unknown person;
- a token in any field other than briefing, debrief(s), reopen, fail or missed;
- a token in a content set without `company.yaml`.

Tests are in `tests/test_company_content.py`.

## Open items for Merijn

1. **A fork in Act II.** The rule says forks "now and then", and Act II has none. The only pairing the current simulation supports with a Check that says "not the constraint" is `fix_grid_study_queue` (bottleneck: grid_analysts is the constraint all through Act II) with `fix_silo_kpis` (design is not the constraint; the obeya's capacity gain is −4 %). That would pull the KPI chapter forward and change the act's order, which `tests/test_act2_content.py` pins. `fix_transformer_wait` cannot be the non-bottleneck branch: its step has no team, so the Check never says "not the constraint". Recommendation: no fork in Act II, and plan one in Act III where two team steps compete. Your call.
2. **A deadline in Act II.** Digging damage is a safety problem with a containment, and the act has no clock. A fitting door would be: "De Linde's aggregaat staat in de winter niet nog eens stil". Missed, it closes the cheap contractor briefing (the road to the patient fix stays open). This is a design call; the rule allows failed missions to close doors.
3. **Outage-stream wording.** Fewer outages show as lower throughput wherever that KPI is shown for the outage stream. Proposal: a KPI phrase per stream, such as "storingen per week" (rules).
4. **Problem names still name causes** in the A3 and the journal ("Gereserveerd maar ongebruikt", "KPI's die elkaar bevechten"). Mission names are fixed; problem names show once the problem is spotted, which may be acceptable. Say if you want them renamed too.
5. **`standard_test_trenches` team hours** sit on `key_accounts` (see digging damage). The likely owner is the storingsdienst or Werkvoorbereiding; it changes the simulation.

## Calls made on Merijn's behalf

| Call | Cost if wrong |
|---|---|
| The trafo stock is tier 1 (was 3), so the shortcut passes an Act II Check | An expensive shortcut becomes playable in Act II. If you meant "money cannot buy maturity" as the lesson, revert one line; the shape test still passes. |
| Two mission names changed to their symptom | The board shows new names; the problem names are unchanged. |
| Femke's "vijf minuten" and Ilse's empty hall moved out of the briefings | A player who skims gets less of a push. The listen-in and conversation clues still hold them. |
| Debrief variants only for `poor_fix`; blamed and not-standardised left to the principle line | No double message after the debrief, but a blamed player hears the blame once (the principle line), not twice. |
| `{functie:}` is resolved at build time, not at runtime | A title changed in `company.yaml` needs a rebuild (always the case for content). |
