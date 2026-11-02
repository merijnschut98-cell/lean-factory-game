# Drie winters: the story arc in the catalogue, and its new beats

> Status: by the mission and dialog design agent (Claude, 2026-10-16), for Merijn to review. **Docs only.** It carries out PLAN.md §4.0 items 1–7 (Fable's arc *Drie winters*, 2026-10-16) and PLAN 1.0. The catalogue's §3.1 and act tables are reworked to match (`2026-10-15-mission-system-and-catalogue-design.md`); the tier drafts carry a short "Drie winters" note where a beat moved.
>
> Read with: `CLAUDE.md` §2; PLAN.md §4.0–§4.4; the dialog spec `2026-10-15-dialog-system-design.md` (engine, schema §9.1); the Acts 0–II scripts `2026-10-15-dialog-scripts-act0-2.md` (schema additions §1.1, R-D1 to R-D5, the voice sheet §2); the tier-2 dialogs; the tier-2, tier-3 and tier-4 drafts; the engagement loop.
>
> Conventions as in the other drafts: Dutch game text, English ids, keys and comments; every number sourced or marked `estimate:` with its reasoning; **(verify)** where only a search extract was available.

## 0. Summary

- **Three years, three winters, one number.** The six acts keep their missions; they are grouped into three years, each ending in a winter that tests what the player built (§1):
  - **Winter 1, *Voor de vorst*:** a new milestone `winter_el_amrani` (no slot). On the first frost period (day 70, 21 December 2026, an estimate) the game checks whether mevrouw El Amrani's mother is warm: the followed order delivered, or the heat pump running on the existing connection after the player listened. The date the player once promised is checked too (§3).
  - **Winter 2, *De storm zonder Ruud*:** at the end of Act III Ruud is seconded to Den Haag. A farewell talk, then the interim director's first MT as a **group talk** whose opening reads the Frank facts. Act IV opens as *sponsor* or *regime*. The storm (`prep_storm_week`) waits for Ruud's departure and becomes the Act III–IV climax with a night scene at the control room's escalation board (§4–§7).
  - **Winter 3, *De opvolger*:** Ruud returns when Act V opens and names his retirement date (1 April of year 3; the AOW age is 67 years and 3 months for 2029–2030). The finale `de_opvolger` replaces the placeholder `t4_new_ci_lead`. Who sits across the table depends on whom the player developed: Anouk, Ahmed, Sanne, or Lotte Smit from outside. It ends on the player's first Kata question (§8).
- **The north star `waiting_list`** (*De wachtlijst van Zuidmark*): open connection and congestion requests, plus the average wait in weeks and the share of given dates kept. It is on the HUD from Act II, named at the ACM visit and in hoshin, and simulated, never scripted (§2).
- **Ruud's monthly call** in winter 2: `ask_coach` gets a 28-day cooldown and becomes one full Kata cycle by phone, main quest only (§6).
- **New dialogs in full Dutch, in the dialog schema:**
  - `ruud_farewell` (a farewell talk that cannot be ruined);
  - `interim_mt` (the first group talk, with sponsor and regime variants);
  - `ruud_call` (the monthly Kata call);
  - `frank_interim` (bringing a regime Frank along);
  - `storm_night_board` (a short group scene in the storm);
  - the succession: `successor_choice`, four `successor_*` talks and `first_question`.
- **A new dialog shape, the group talk:** several people and one room meter. Listening to the quiet one changes the room. Its rules for the builder are in §5.
- **Schema needs for the builder** are listed in §10; **open questions**, decided by Merijn's standing rule, in §11.

---

## 1. The calendar: three years

Play starts on Monday 12 October 2026 (`content/game.yaml`). Acts are paced by the player, so act lengths are the engagement loop's estimates (§5.1 there). The winters are fixed points; everything else moves.

| Year | In-game time (estimate) | Acts | The winter, its test | What it checks |
|---|---|---|---|---|
| **1 · Het eerste jaar** | Oct 2026 – Sep 2027 | 0 Inwerkweek · I De eerste honderd dagen · II Wat onder de grond zit | **Winter 1, *Voor de vorst*** (`winter_el_amrani`, milestone, judged on day 70) | Does a first fix and one honest conversation keep one family warm? |
| **2 · Het jaar zonder Ruud** | Oct 2027 – Sep 2028 | III Zichtbaar maken (end) · IV Flow door de regio · VI Het digitale net (from `t3_map_region`) | **Winter 2, *De storm zonder Ruud*** (`prep_storm_week` + `storm_night_board`) | Do the boards, the escalation and the people hold without the sponsor? |
| **3 · Het jaar van de opvolger** | Oct 2028 – 1 Apr 2029 | V Het systeem · VI (tier 4) · the finale | **Winter 3, *De opvolger*** (`de_opvolger`, finale, before Ruud's last day) | Can the work go on without *you*? |

**Fixed points:**

| Beat | When | Source / reasoning |
|---|---|---|
| The El Amrani letter | day 0 (training Monday) | exists |
| Day 100 (`review_100_days`) | day 100, 20 January 2027 | exists |
| **The first frost period** (`first_frost`) | **day 70, Monday 21 December 2026** | `estimate:` the first *official* frost night comes earlier (national average 21 October in 1991–2020; De Bilt about 2–3 November, older figures), but a single frost night does not leave a family cold. A run of frost nights, when a house without heating gets cold, is a December–January event. Day 70 is also the shortest day, which the beat uses. |
| Ruud's secondment (`ruud_farewell`) | when `t2_first_okr` is done **and** `acm_visit` judged (end of Act III; expected late 2027) | story; a year away is the national programme's natural cycle (estimate) |
| The storm (`prep_storm_week`, first occurrence) | the first **storm season** (1 October – 31 March) that starts or is running after `flag:ruud_seconded` | KNMI: storms can come all year, but a strong, lasting storm is most likely from October through March |
| Ruud's return (`ruud_returns`) | when Act V opens (`t4_hoshin` available) | story; "about a year" in the fiction, whatever the player's pace |
| **Ruud's last day** (`ruud_retirement`) | 1 April after Act V opens, at least 240 days after it (year 3 at the expected pace: 1 April 2029) | Ruud is born in December 1961 (fiction); the AOW age for 2029 and 2030 is 67 years and 3 months, so he reaches it in March 2029. 240 days (`estimate:`) fits Act V's hoshin, the 90-day audit, the fork, the flex market and the plan. |

**Seasons for `opens_on`** (catalogue §2.4): `winter` = 1 December – 28/29 February; `storm` (new) = 1 October – 31 March; `summer` = June–August (heatwave). A mission with `opens_on: {season: s}` opens on the first day of the first such season after its other requires are met, or at once if that season is running.

**Why the storm waits for Ruud.** If Act III ran into a winter before Ruud left, the storm would come *with* him and the arc's test would be lost. So the first `prep_storm_week` also requires `flag:ruud_seconded`. A player who ends Act III in summer meets the storm a few months into Act IV; one who ends it in winter meets it at once. Either way the storm comes without Ruud. Later winters repeat the storm (`recurring: {every_days: 365}`, tier-2 draft), with Ruud back.

---

## 2. The north star: `waiting_list`

**What it is.** One region number, on the HUD from Act II's first main (`fix_revision_backlog`) on, next to the season:

> **Wachtlijst Zuidmark** · 412 aanvragen · gemiddeld 31 weken · 68 % kreeg de datum die we noemden

Three parts, all computed from the simulation:
1. **`open`:** the count of open orders in `connections` (and `lv_connections`, `hz_connections` from tier 3) plus the open requests in `congestion.capacity_queue` (and `lv_feedin`);
2. **`avg_wait_weeks`:** the mean age of those open orders, in weeks;
3. **`date_kept`:** of the orders delivered in the last 13 weeks that were *given a date*, the share delivered on or before it. An order gets a date when the dialog proposal with `promise: {kind: delivery_date}` is taken (the El Amrani pattern) or when a countermeasure that gives dates is running (`forecast_from_planning`, tier-4 IT; `publicly_visible_queue`, tier 3). Before any dates are given, the third part reads "nog geen data gegeven".

**The finale is not zero.** The sector cannot clear the list in three years and neither can Zuidmark. Ruud's last line asks for the third number: "Iedereen een eerlijke datum. En die klopt." The game never sets a target for `open`. The ACM visit (Act III) and hoshin (Act V) name it.

**Schema** (`content/kpis.yaml`, a new top-level block next to `kpis:`; not a department KPI, so not on any team's menu):

```yaml
north_star:
  id: waiting_list
  name: Wachtlijst Zuidmark
  shows_from: {missions: [fix_revision_backlog]}       # on the HUD from Act II's first main
  parts:
    - {id: open, name: aanvragen, measure: open_count,
       streams: [connections, lv_connections, hz_connections], steps: ["congestion.capacity_queue", "lv_feedin.capacity_queue"]}
    - {id: avg_wait_weeks, name: gemiddeld, unit: weken, measure: mean_wip_age_weeks, of: open}
    - {id: date_kept, name: kreeg de datum die we noemden, measure: share_delivered_by_promised_date, window_days: 91}
  note: "De landelijke wachtlijst voor afname bij de regionale netbeheerders telde medio 2026 ruim 15.000 aanvragen (Landelijk Actieprogramma Netcongestie, voortgang najaar 2026). Sinds 1 juli 2026 staan huishoudens in congestiegebieden op dezelfde lijst. De aantallen van Zuidmark zijn een schatting: ze volgen uit de simulatie."
```

Streams that do not exist yet are skipped (the tier-3 areas). **Grounding:** the national queue at regional operators was a little over 15,000 offtake requests in mid-2026, growing more slowly than before (LAN progress update, autumn 2026, via omgevingsweb.nl); households joined from 1 July 2026 (KHN; tier-3 draft §0.2). Zuidmark's own numbers are `estimate:` and come from the simulation.

**Where it is read:**
- the HUD (Act II on) and the terugblik's "Veranderd" line;
- `acm_visit` (Act III): Jeroen's briefing names the list next to the 18 weeks; the inspector (`acm_inspector`) asks for `date_kept`;
- Ruud's monthly call (§6): his personal line compares it with the national list;
- `interim_mt` (§5): the regime Frank wants `open` as a weekly output target per department; the sponsor Frank wants `date_kept`;
- `t4_hoshin` (Act V): the true north on the X-matrix reads "Iedereen een eerlijke datum, en die klopt" (`date_kept`), with `open` as context;
- `de_opvolger` (§8): the last card shows the three numbers on the day Ruud leaves, against the day the player arrived.

**Goodhart guard.** A rule that only lowers `open` by refusing or hiding requests (`flag:hidden_wip`, tier 3; the concept folder) leaves `avg_wait_weeks` and `date_kept` honest, and the NTA 8120 audit's application-date check finds it (tier 4). The number cannot be gamed without paying later.

---

## 3. Winter 1: *Voor de vorst* (Act I)

PLAN §4.0 item 7: winter 1's climax is the El Amrani date before the first frost.

**The story.** Mevrouw El Amrani's installer told them to remove the gas boiler. The heat pump hangs on the wall, waiting for a heavier connection. Her mother (81) lives with them. On the first run of frost nights, the game looks at that house.

**Two ways to make it in time, both real:**
1. **The followed order is connected** (`WorkOrder.story: el_amrani`, audit §3.0; the WIP patch D14): execution done before day 70. Possible for a player whose Act I fixes made the stream faster.
2. **The heat pump runs on the existing connection, on a lower setting,** after a monteur checked it. This is the hidden proposal `check_existing_connection` in `el_amrani_fourth_call`, which only appears once her concern is heard. Grid operators advise that many heat pumps work on the existing connection (Acts 0–II scripts §1.3). The patient listener finds the fast, honest fix; the hurried one names a date.

**The fairness fix.** The El Amrani call belongs to `fix_status_callers`, which a slower player may not reach before day 70. So the milestone opens the same call on day 49 if that mission is not active yet: the call is available from the mission *or* the milestone, whichever comes first (schema need `missions:` as a list, §10). The call is a customer's own phone call, so it takes no slot and opens no problem. Its clue waits in the journal until `status_callers` is active (a clue never activates a problem).

**Date fixes in `el_amrani_fourth_call`** (the scripts were written before the calendar was fixed; found while placing this beat):
- interest line: "Op 3 juni … Op 17 juni … Op 1 juli" predates her request, which is eleven weeks old on 12 October (born about 27 July). New: "Op 7 september zei iemand 'binnenkort'. Op 21 september 'we zijn ermee bezig'. Op 5 oktober wist niemand het. Ik wil gewoon weten waar ik aan toe ben."
- concern line: "Het is bijna november." becomes "Het wordt elke nacht kouder." It then fits any day from late October to December.
- `name_a_date`'s "14 november" becomes `{promise_date}`, the planning estimate the game shows (and checks).

```yaml
missions:
  - id: winter_el_amrani
    name: Voor de vorst
    kind: milestone
    tier: 1
    act: 1
    chapter: De telefoon
    arc: winters
    requires: {missions: [walk_connections]}
    opens_on: {day: 49}
    deadline_on_day: 70                    # the first frost period (estimate, §1)
    goal: {type: story_order, story: el_amrani, by: deadline,
           met_if: {any: [delivered:el_amrani, agreed:el_amrani_fourth_call:check_existing_connection]}}
    principles: [respect, long_term]
    briefing: "Het KNMI verwacht voor de week van 21 december de eerste echte vorst: een paar nachten achter elkaar onder nul. In Nova-Oost hangt een warmtepomp zonder stroom aan de muur, en de cv-ketel is al weg. Mevrouw El Amrani belt deze week weer."
    debrief: "Op de eerste vorstnacht draaide de warmtepomp van de familie El Amrani. Haar moeder zat warm. {how_line}"
    debrief_variants:
      existing_connection: "Op de eerste vorstnacht draaide de warmtepomp van de familie El Amrani, op een lagere stand, op de oude aansluiting. Een monteur keek een kwartier en zette één instelling om. Niemand had het gevraagd, tot iemand luisterde."
      delivered: "Op de eerste vorstnacht lag de nieuwe aansluiting erin. {age_weeks} weken na de aanvraag. Snel genoeg voor deze familie. En voor de volgende?"
    fail: "De eerste vorstnachten logeert de moeder van mevrouw El Amrani bij haar andere dochter in Havenzij. 'Het is maar voor even,' zegt mevrouw El Amrani. Ze schrijft het op."
    fail_effects: {reputation: -2}         # estimate: small; this is one family, and the region does not know it yet
    sets_flags_on_fail: [flag:el_amrani_cold_winter]   # read by the Act IV thread (the bakery in Havenzij, §9)
    beats:
      - {on: day, day: 49, who: esra, text: "Mevrouw El Amrani aan de lijn. Ze vraagt naar jou. Ze heeft je naam opgeschreven, zegt ze."}
      - {on: day, day: 70, who: ruud, text: "De kortste dag van het jaar. Vannacht vriest het. Weet jij hoe het in Nova-Oost is?"}
      - {on: completed, who: el_amrani, text: "Mijn moeder vraagt wie u bent. Ik heb gezegd: iemand die terugbelde."}
    teaches: [lead_time, customer_value, warmtepomp_aansluiting]
    rewards: {xp: 300, reputation: 3}
```

**The promise is checked separately.** If the player took `name_a_date`, the date is a `promise` (the scripts' Q11). On that date the game checks the followed order. Kept: trust +5 and the terugblik line "Mevrouw El Amrani · de datum klopte". Broken: memory −15 and reputation −1 (the dialog spec §6), and on the next call she reads her notebook aloud. That is the third part of the north star (§2) in one family.

**What it pays forward.** `flag:el_amrani_cold_winter` (or its absence) colours Act IV's human thread: the El Amrani daughter's bakery in Havenzij (PLAN §4.2.2; proposed in §9). D14 is unchanged: it still rewards delivery within 126 days.

**Concept card** `warmtepomp_aansluiting` (new, sector): "Een warmtepomp vraagt niet altijd een zwaardere aansluiting. Veel warmtepompen kunnen op een gewone 3x25A-aansluiting draaien, soms op een lagere stand of met een slimme regeling. Netbeheerders raden aan dat eerst te laten nagaan." Source: grid operators' advice as cited in the Acts 0–II scripts §1.3 (NOS; Kassa). **(verify the exact wording at a grid operator's own page.)**

---

## 4. The end of Act III: Ruud gaat naar Den Haag

### 4.1 The beat sequence

When `t2_first_okr` is done and `acm_visit` judged (passed, or failed with its recovery opened):

1. **The ACM letter** (engagement loop §3, III → IV, unchanged).
2. **Ruud calls the player in.** The talk `ruud_farewell` opens in Ruud's room the next working day (§4.2). It is the act's last debrief scene. It cannot be ruined (`tutorial: true`): a farewell is not a test of skill, it is a gift for one who listens.
3. **The talk ends, whatever its outcome:** `flag:ruud_seconded` is set; the monthly call unlocks (§6); `act` advances to IV; the board shows "Zonder Ruud" as the next chapter.
4. **Two weeks later, the first MT under Frank:** `t3_interim_mt` (a short main, §5.3) holds the group talk `interim_mt`.
5. **Joke's call that evening** (the engagement loop's III → IV cliffhanger) moves to after the MT, so the act's question becomes two: *what will Frank do?* and *is Lindeveld the same stream as Nova?*

**Ruud's title card for Act IV** (replaces the engagement loop's): "Flow door de regio. Ik ben er een jaar niet. Eén keer per maand bel ik je. Wat je dan vertelt, moet van jou zijn, en van hen."

### 4.2 `ruud_farewell`: the farewell talk

**The programme is real; the secondment is fiction** (Fable's note, 2026-10-16). The *Landelijk Actieprogramma Netcongestie* (LAN) was set on 21 December 2022 and sent to the Tweede Kamer by the minister for Klimaat en Energie the day before (Kamerstuk 29 023, nr. 385). It is not an office with staff of its own: it was drawn up, and is carried, **jointly by the grid operators, the ACM, the Rijk, the provinces and municipalities (*medeoverheden*) and market parties**, who each committed to its actions; a special coordinator led it at the start. Its work runs in lines; the 2026 progress letters name them *Beter benutten*, *Sneller bouwen* and *Slimmer inzicht*. The game says only that: Ruud is lent to the programme by Voltana, a fictional operator, for a year, to work on the waiting list from the regions' side. **No real person is named or voiced**: not the minister, the coordinator or any official; Ruud's colleagues there stay offstage, and the lines never claim what the programme decided. The ministry is named as the Rijk did at the time ("het ministerie"), never by a minister's name. Source lines go into `content/dialogs.yaml` as comments above the dialog (below), so the source verifier can find them.

Ruud was never a dialog target (Acts 0–II scripts, audit change to spec §7.4). He becomes one here, and only here and in §8, because in a farewell the coach is the one who has something to say. The talk is a check-in: no proposal to win. Steering is fixing mode, as in every check-in. Its concern, Ruud's 2012 programme, is the audit's planned reveal (audit §5.3: "reveals his own failed 2012 verbeterprogramma … a lesson on sustaining"). Here it is told at the moment it matters most.

New archetype `mentor` (§10): base 55; `experience` ×1.5 (a mentor wants to hear what *you* learned); `show_data` ×0.5 (he has seen your numbers).

```yaml
dialogs:
  - id: ruud_farewell
    person: ruud
    kind: checkin
    trigger: {beat: act3_end}
    tutorial: true                          # a farewell cannot be ruined (R-D5)
    patience: 12
    place: directie.ruud_office
    # source: Landelijk Actieprogramma Netcongestie (LAN), set 21 December 2022; Kamerbrief of the minister for
    #   Klimaat en Energie, 20 December 2022, Kamerstuk 29 023 nr. 385: "gezamenlijk opgesteld door netbeheerders,
    #   ACM, medeoverheden, het Rijk en marktpartijen". Lines Beter benutten / Sneller bouwen / Slimmer inzicht
    #   (progress letters 2026). Waiting list "ruim 15.000 aanvragen voor afnamecapaciteit", mid-2026: LAN
    #   voortgang najaar 2026 (see Sources). Ruud's secondment and everyone he meets there are fiction. (verify)
    # start: mentor 55 + 0 (neutraal) + 0 + 0 (trust 50) + 0 = 55, Luistert
    #   + 5 for each of: committed:anouk_owns_tray, done:coach_intake_lead, D23 earned (he saw you develop people): up to 70
    opening: "Kom binnen. Doe de deur maar dicht. Dat doe ik nooit, dus je weet dat het iets is."
    position: {text: "Den Haag heeft gebeld. Het Landelijk Actieprogramma Netcongestie, je weet wel: het ministerie, de netbeheerders, de ACM, provincies en gemeenten, sinds 2022 samen aan één tafel. Ze willen een jaar lang iemand uit een regio erbij, voor de wachtlijst. Voltana leent mij uit. Ik heb ja gezegd. Maandag over twee weken begin ik.", tags: [claim]}
    layers:
      - id: interest
        at: 60
        via: [open_question, inquiry, paraphrase]
        text: "Vorig jaar stonden er al ruim vijftienduizend aanvragen op de lijst, landelijk, en sinds die zomer staan er ook huishoudens op. Daar zit mevrouw El Amrani tussen, en de bakker, en De Linde. Ik wil weten of wat wij hier leren ook daar werkt. En eerlijk: aan die tafel zitten directies en beleidsmensen. Netbeheerders ook, maar niemand die weet hoe een dossier bij Anouk op de stapel ligt."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [reflect, empathy, experience]   # a feeling cue: reflect is the natural key; silence misses
        lead_in: {text: "Ik zeg je eerlijk: ik vind het geen prettig moment om te gaan.", tags: [feeling]}
        text: "In 2012 heb ik ook een verbeterprogramma getrokken. Met een bureau, met dashboards, met alles. Het liep. En toen ging ik naar een andere functie, en binnen een jaar was het weg. Niet omdat het slecht was. Omdat het van mij was, en niet van hen. … Ik ga nu weer weg. Dit keer wil ik weten of het van hen is."
        tags: [admission, doubt]
        unlocks: {facts: [heard:ruud_2012]}
    reframe: "Vanuit Marco gezien? Die heeft dit al een keer meegemaakt. Met mij. … Ja. Dat is precies waar ik bang voor ben."
    warning: "Ik heb nog een uur. Daarna wil ik bij Kees langs."
    lines:
      mood: {say: "Hoe voelt het, nu het besloten is?"}
      experience:
        say: "Wat ik van jou heb geleerd: je vroeg nooit wat ik moest doen. Je vroeg wat ik zag. Dat ga ik doen als je weg bent."
        lands: {text: "Dat is het mooiste wat je had kunnen zeggen. En het is een vraag die je nu zelf moet stellen. Aan Sanne, aan Joost. Ook als ik niet meeluister.", tags: [feeling]}
      show_data:
        misses: "Ik ken je cijfers. Ik wil horen wat jij denkt."
      close: {say: "Dank je, Ruud. Voor dit jaar."}
    proposals: []                          # a check-in has none; steering is fixing mode (spec §5.7)
    outcomes:
      lifted: "Weet je wat ik ga doen? Ik ga je niet bellen om te vragen hoe het gaat. Ik ga je bellen om te vragen wat je doel is. Eén keer per maand. De rest is van jou."
      heard: "Goed. Dank je. Over een maand bel ik."
      none: "Nou. Over een maand bel ik. Doe de deur maar open als je gaat."
    sets_flags_on_end: [flag:ruud_seconded]   # whatever the outcome
    # route (start 55): open question +6 61 (interest, tagged feeling) > paraphrase +7 68 (heard) > reflect +10 78 (lands on the feeling;
    #        first move at >= 72: the lead-in, a feeling) > empathy +6 > 81 capped (concern) > experience x1.5 +12 93
    #        > close: opgebeurd (6 moves). Silence at the lead-in misses (-4): he said a feeling, not a hesitation.
    # other routes: inquiry for the interest; empathy at the lead-in ("Dat je er eerlijk over bent, zegt genoeg."); silence before reflect.
    # trap (fixing mode): propose / perspective before the concern: -12 ("Ik vraag je geen advies. Nog niet.").
```

**What `heard:ruud_2012` changes later** (path dependence through the coach):
- **Act IV, regime:** when the consultancy offer comes (§7.2), Ruud's next call opens with "Je weet wat ik in 2012 deed. Ik ga je niet vertellen wat je moet doen." (one line; it names nothing).
- **Act IV, the team-led kaizen week** (§7.3): the debrief adds "Ruud stuurde een foto van het bord terug, zonder tekst."
- **The finale (§8):** Ruud's last line before the first Kata question reads it: "Dit keer is het van hen."

---

## 5. The group talk, and the interim director's first MT

### 5.1 The group-talk shape (rules for the builder)

PLAN §4.3.2 names the group talk as the seventh dialog shape: a dagstart or an MT meeting with several people and one *room* meter, where listening to the quiet one changes the room. Catchball (tier 4) and the daily boards (Phase 3, 3.3) use it too. The engine is the persuasion engine (dialog spec §3) with these changes:

1. **Who.** `kind: group`, a `chair` (the person who answers `ask_commitment` for the room), `members` (2–4 people), and exactly one `quiet` member. Each member keeps their own trust and mood; nobody's archetype is shown.
2. **One meter: the room.** One openness bar, labelled *De kamer*, with the same five bands. Start = the mean of each person's start openness (spec §3.6), clamped 5–80. Each person shows only a face (mood) and a small dot that fills once they have spoken. No per-person bars: the player reads a room, not five gauges.
3. **Address.** Every move has a target: `room` (default) or one person (a pick, like `show_data`'s picker). A listening move lands by the usual rules, read against the **last line of the person addressed** (or of the room's last speaker, for `room`). Its Δ goes to the room.
4. **Interjections.** Members speak unasked. Each member has 1–3 authored `interjections`, keyed on `{band}` or `{after_move}`, that fire once. An interjection becomes the room's last line, with its tags, so the next move can answer it (paraphrase a `claim`, reflect a `feeling`). This is what makes a room feel alive, and it gives each route a different middle.
5. **The quiet one.** The `quiet` member never interjects. Their layer (`id: quiet`) is revealed only by a listening move *addressed to them*: one of `via` (2–3 moves), at room openness ≥ its `at`. When it is revealed, the room gains +12 ("de kamer verandert"; an estimate, the same size as a landed silence) and the chair's **concern ceiling lifts**: before that, the room cannot rise above the concern's `at` − 1, so neither the lead-in nor the concern can come. So:
   - **commitment** needs the quiet one heard (the act's lesson, and the only fixed requirement; when and by which move is free);
   - **partial** is reachable without the quiet one (≥ 55, as in the spec), so a player who misses them still leaves with something.
6. **One person, too long.** Three moves in a row to the same person: the others disengage, room −4, and one member says so (an authored `disengage` line, e.g. Monique checks her phone).
7. **Public pressure costs more.** In front of others, `pressure` costs the room −20 (spec: −15) and `confront` −25 (spec: −20); the confronted person's trust −15. Loss of face in public is worse than in private (estimates).
8. **Steering** goes to the room; `propose` and `ask_commitment` always address the chair. Pushing too early (before the room is `heard`, or below 40) costs −12, as in the spec.
9. **Patience** is the agenda: 12 moves by default. Two moves before the end the chair says the authored `clock` line.
10. **Outcomes** as in the spec, as facts on the dialog id (`committed:interim_mt`, …). On commitment each member gains trust +5; the quiet one +10 if their layer was revealed. A ruined group talk is retried at the next meeting (`retry_after_days`, 14 for an MT), with memory −10 for the chair.
11. **Content tests** (spec §9.3) run unchanged on the room, with targets as part of the move. "No golden path" counts sequences that differ in a move *or a target*. One more test: every group talk can reach `partial` without addressing the quiet one, and no sequence reaches `commitment` without them.

### 5.2 Which Frank: the opening state

The talk's variant is chosen at its start from facts the player made in Acts II–III (the dialogs `frank_kpi_targets`, `frank_red_numbers`):

| Variant | Needs | Who the player meets |
|---|---|---|
| **sponsor** | `any: [committed:frank_kpi_targets, committed:frank_red_numbers]` | A Frank who was brought along. Nervous, formal, and loyal to what he signed. |
| **regime** | otherwise: Frank blocked (`blocked:frank_kpi_targets` and no later commitment), complied (`complied:frank_*`), was ruined, or was never asked (the Obeya was acted without him) | A Frank who was bypassed or pushed. He trusts what he can count. |

Within each variant, `heard:frank_budget` and `heard:frank_red` (the player listened, even without an agreement) add +10 to Frank's start: listening that won nothing still pays.

The variant is path dependence, so **one talk cannot flip a regime into a sponsor**. The talk decides how the year starts within the variant (§5.4). The way from regime back to the Obeya runs through Act IV's team-led kaizen week (§7.3).

### 5.3 The mission: `t3_interim_mt`

```yaml
missions:
  - id: t3_interim_mt
    name: De interim-directeur
    kind: main
    tier: 3
    act: 4
    chapter: Zonder Ruud
    arc: winters
    requires: {missions: [t2_first_okr], facts: {all: [flag:ruud_seconded]}}
    goal: {type: talk_to, dialog: interim_mt, outcome: heard}     # any listening outcome completes it; the outcome decides the year's start
    principles: [respect, long_term]
    briefing: "Ruud is weg. Frank Hulshof is een jaar lang interim-directeur van Zuidmark. Dinsdag om negen uur is zijn eerste MT, en jij staat op de agenda: 'Verbeteren zonder Ruud'. Monique de Ruiter van Financiën is er, Ingrid Bos van Assetmanagement, en Esra Yilmaz schuift aan voor het punt over de wachtlijst."
    briefing_variants:
      regime: "Ruud is weg. Frank Hulshof is een jaar lang interim-directeur van Zuidmark. Op de agenda van zijn eerste MT staat 'Sturen op resultaat' en, daaronder, jouw naam. Op zijn bureau ligt een offerte van een adviesbureau. Monique de Ruiter, Ingrid Bos en Esra Yilmaz zijn er ook."
    debrief: "{outcome_line} Het jaar zonder Ruud is begonnen. Wat moet er staan als hij terugkomt, en wie moet het dan dragen?"
    beats:
      - {on: accepted, who: frank, text: "Dinsdag negen uur. Ik heb een kwartier voor jouw punt. Ruud gaf je een uur, ik weet het. Ik ben Ruud niet."}
      - {on: completed, who: joke, text: "Bij ons rijden ze een uur per klus. En er gaan er drie met pensioen. Komt er iemand kijken, of komt er een dashboard?"}
    teaches: [respect_for_people, kpi_alignment, catchball]
    rewards: {xp: 1200, budget: 0, reputation: 3}
    # no insights: Ruud is on the phone; his monthly call covers this main like any other (§6)
```

It is a short main (one talk, at most two days with a retry), so the board shows it as a scene, not a quest. It is the Act IV opener; `t3_map_region` now requires it.

### 5.4 `interim_mt`: the dialog

**Who:**
- **Frank** (chair, `rule_bound`);
- **Monique de Ruiter** (Financiën, `rule_bound`; her tier-4 voice, earlier);
- **Esra Yilmaz** (`defender`; invited for the waiting-list item);
- **Ingrid Bos** (the quiet one, `quiet`). She was in the MT in 2012.

```yaml
dialogs:
  - id: interim_mt
    kind: group
    chair: frank
    members: [monique, esra, ingrid]
    quiet: ingrid
    mission: t3_interim_mt
    place: directie.mt_room
    patience: 12
    retry_after_days: 14                   # the next MT
    # start (sponsor): mean of frank 35+2+15 (trust 60, memory committed) = 52, monique 35, esra 40+10 (team trust) = 50, ingrid 47 -> 46, Luistert
    # start (regime):  mean of frank 35-2 (trust 40) = 33, monique 35, esra 50, ingrid 47 -> 41, Luistert;  +2.5 with heard:frank_budget (10 / 4 people)
    clock: "We hebben nog vijf minuten voor dit punt. Daarna de begroting."
    warning: "Ik stel voor dat we dit punt verdagen."
    variants:
      - id: sponsor
        needs: {any: [committed:frank_kpi_targets, committed:frank_red_numbers]}
        opening: "Goedemorgen. Eerste punt. Ik zal eerlijk zijn: ik had dit niet verwacht, en Ruud ook niet. Het Obeya-bord blijft. Dat heb ik getekend, en wat ik teken, houd ik."
        position: {text: "Ik wil dat jij het verbeteren trekt, zoals met Ruud. Maar ik moet het elke maand kunnen uitleggen. Aan het hoofdkantoor, en aan Den Haag, want daar zit Ruud nu en hij kijkt mee.", tags: [claim]}
        layers:
          - id: interest
            at: 52
            via: [paraphrase, inquiry, open_question]
            text: "Het hoofdkantoor kijkt naar de wachtlijst. Eén getal, elke maand. Als dat getal onder mij groeit, is de vraag niet wat we geleerd hebben. Dan is de vraag waarom de interim het liet lopen."
            tags: [claim, feeling]
          - id: quiet
            person: ingrid
            at: 55
            via: [open_question, silence, inquiry]
            text: "Mag ik iets zeggen? In 2012 zat ik hier ook. Toen werd het verbeteren een rapport voor het hoofdkantoor, elke maand. Na een halfjaar deden we wat er in het rapport stond, en niet wat er op de vloer nodig was. Wat niet op het dashboard stond, deden we niet meer. Onderhoud stond er niet op."
            tags: [admission, claim]
            unlocks: {facts: [heard:ingrid_2012]}
          - id: concern
            at: 72
            via: [reflect, empathy, silence]
            lead_in: {text: "Ingrid heeft gelijk. En ik…", tags: [hesitation]}
            text: "Ik ben geen Ruud. Hij kon in het MT zeggen: 'Dit getal wordt eerst slechter, en dat is goed.' Als ik dat zeg, klinkt het als een excuus. Ik weet niet of ik het zo kan uitleggen dat ze het geloven."
            tags: [admission, doubt]
            unlocks: {facts: [heard:frank_interim], proposals: [teams_present_monthly]}
        proposals:
          - {id: monthly_report, addresses: [interest], label: "Een maandrapport voor het hoofdkantoor",
             say: "Ik maak elke maand een rapport voor het hoofdkantoor, met de wachtlijst en wat we doen.",
             reply: "Een rapport. Dat kan ik doorsturen. Ja."}
          - {id: date_kept_first, addresses: [interest, concern], label: "De wachtlijst, met 'datum gehaald' bovenaan",
             say: "Zet de wachtlijst op het bord, maar met bovenaan het deel dat wij in de hand hebben: hoeveel klanten de datum kregen die we noemden. Dat getal kan deze maand al bewegen.",
             reply: "Een getal dat ik kan uitleggen voordat het grote getal beweegt. Dat ken ik nog van Joost."}
          - {id: teams_present_monthly, hidden: true, addresses: [concern], label: "De teamleiders vertellen het zelf",
             say: "Wat als niet jij het uitlegt, maar Sanne, Joost en Marco, elke maand tien minuten, aan het bord? Jij zit erbij. Het hoofdkantoor mag komen luisteren.",
             reply: "Zij vertellen het. Dan hoef ik geen Ruud te zijn. Dan ben ik de directeur die ze laat praten."}
        co_proposal: {id: teams_present_monthly, text: "Laat ze het zelf vertellen. Ik zit erbij en ik leg uit wat ik moet uitleggen. De rest is van hen."}
        outcomes:
          commitment: "Goed. Het bord blijft, de teamleiders vertellen het elke maand zelf, en ik zit erbij. Ingrid, wil jij volgende maand het onderhoud erbij zetten? Volgende punt."
          partial: "Het bord blijft. Hoe ik het uitleg, zien we volgende maand. Volgende punt."
          heard: "Ik heb het gehoord. Ik denk erover na. Volgende punt."
          compliance: "Prima. Dan doen we het zo. Op jouw voorstel, staat in het verslag."
          ruined: "Ik stel voor dat we dit punt verdagen. Ik heb er vandaag geen goed gevoel bij."
        sets_flags_on_outcome:
          commitment: [flag:interim_sponsor, flag:strategy_early]
          partial: [flag:interim_sponsor]
          heard: [flag:interim_sponsor]
          none: [flag:interim_sponsor]
          compliance: [flag:interim_sponsor]
          ruined: []                       # retried at the next MT; the variant stays
      - id: regime
        needs: {none: [committed:frank_kpi_targets, committed:frank_red_numbers]}
        opening: "Goedemorgen. Eerste punt: sturen op resultaat. Ik ben een jaar interim. In dat jaar wil ik elke maandag zien wat we leveren."
        position: {text: "Het Obeya-bord gaat eruit. Er komt een dashboard: aansluitingen per week, per afdeling, groen of rood. En ik heb een bureau gevraagd een voorstel te doen voor een Lean-programma. Iets wat het hoofdkantoor herkent.", tags: [claim]}
        layers:
          - id: interest
            at: 52
            via: [paraphrase, inquiry, open_question]
            text: "Ruud kon zich een jaar van vragen stellen permitteren. Ik heb een jaar om te laten zien dat de wachtlijst niet groeit. Dat getal gaat naar het hoofdkantoor. Een bord met post-its kan ik niet doorsturen."
            tags: [claim]
          - id: quiet
            person: ingrid
            at: 55
            via: [open_question, silence, inquiry]
            text: "Mag ik iets zeggen? In 2012 hadden we ook een dashboard, en een bureau. Het eerste halfjaar was alles groen. Wat niet op het dashboard stond, deden we niet meer. Onderhoud stond er niet op. De kabelstoringen van 2014 komen daar vandaan. Ik heb ze allemaal in mijn register."
            tags: [admission, claim]
            unlocks: {facts: [heard:ingrid_2012]}
          - id: concern
            at: 72
            via: [inquiry, empathy, silence]
            lead_in: {text: "Dat was niet mijn programma. Maar…", tags: [hesitation]}
            text: "Ik ben interim. Als de wachtlijst onder mij groeit, ben ik de man die het liet lopen. Ruud kan zich in Den Haag achter een programma verschuilen. Ik zit hier. Ik heb iets nodig wat ik elke maandag kan laten zien, anders ben ik in november mijn geloofwaardigheid kwijt."
            tags: [admission]
            unlocks: {facts: [heard:frank_interim], proposals: [one_stream_board_with_dashboard]}
        proposals:
          - {id: dashboard_as_asked, addresses: [interest], label: "Het dashboard, zoals voorgesteld",
             say: "Goed. Een dashboard met aansluitingen per week, per afdeling.",
             reply: "Dat bedoel ik. Iets wat ik kan doorsturen."}
          - {id: date_kept_first, addresses: [interest], label: "De wachtlijst, met 'datum gehaald' bovenaan",
             say: "Zet de wachtlijst op het dashboard, maar met bovenaan hoeveel klanten de datum kregen die we noemden. Dat getal hebben wij in de hand, en het beweegt binnen een maand.",
             reply: "Datum gehaald. Hm. Dat begrijpt het hoofdkantoor ook. Maar het is geen aantal."}
          - {id: one_stream_board_with_dashboard, hidden: true, addresses: [concern], label: "Eén stroom houdt het bord, de rest krijgt het dashboard",
             say: "Laat het bord op één stroom staan, de aansluitingen, als proef. Jij krijgt je dashboard voor de rest, en elke maandag een getal van die proef dat je kunt laten zien. Over een kwartaal vergelijk je ze.",
             reply: "Een proef met een getal. Dat kan ik verdedigen. En als de proef het verliest, is het jouw proef, niet de mijne."}
        experiments:
          - {id: quarter_side_by_side, addresses: [concern], label: "Een kwartaal naast elkaar",
             say: "Een kwartaal het bord en het dashboard naast elkaar, op dezelfde stroom. Ingrid zet er het onderhoud bij. Daarna beslis jij.",
             reply: "Naast elkaar. En ik beslis. Goed."}
        co_proposal: {id: one_stream_board_with_dashboard, text: "Eén stroom houdt het bord. Ik wil elke maandag één getal van die stroom. Als dat goed gaat, mag Ingrid volgend kwartaal het onderhoud erbij zetten."}
        outcomes:
          commitment: "Goed. De aansluitingen houden het bord, als proef. Ik wil elke maandag één getal. De rest krijgt het dashboard. Het voorstel van het bureau leg ik nog even neer. Volgende punt."
          partial: "Ik houd het dashboard. Als jij met één stroom iets beters laat zien, praten we verder. Volgende punt."
          heard: "Interessant verhaal, Ingrid. Ik houd het dashboard. Volgende punt."
          compliance: "Dan zijn we het eens. Het dashboard komt er. Op jouw voorstel, staat in het verslag."
          ruined: "Ik stel voor dat we dit punt verdagen. Kom maar met iets wat ik kan laten zien."
        sets_flags_on_outcome:
          commitment: [flag:interim_regime, flag:regime_one_stream]
          partial: [flag:interim_regime]
          heard: [flag:interim_regime]
          none: [flag:interim_regime]
          compliance: [flag:interim_regime, flag:dashboard_agreed]
          ruined: []
    members_lines:                         # shared by both variants
      monique:
        interjections:
          - {band: Luistert, text: "Mag ik even iets over geld zeggen? Elk programma van de afgelopen tien jaar kostte meer dan begroot. Ik wil weten wat dit kost, en wat het oplevert. In euro's.", tags: [claim]}
          - {after_move: show_data, text: "Die cijfers ken ik niet. Waar komen ze vandaan?", tags: [doubt]}
        disengage: "(Monique kijkt op haar telefoon.)"
      esra:
        interjections:
          - {band: Op z'n hoede, text: "Ik zeg het maar even: mijn mensen krijgen elke dag de wachtlijst aan de telefoon. Een getal op een dashboard verandert daar niks aan. Een datum die klopt wel.", tags: [claim, feeling]}
          - {after_move: perspective, text: "Precies. Vraag het een klant. Die wil geen groen. Die wil een datum.", tags: [claim]}
        disengage: "(Esra schuift haar stoel iets naar achteren.)"
      ingrid:
        interjections: []                  # the quiet one never interjects
        disengage: "(Ingrid schrijft iets op en zegt niets.)"
    lines:
      silence:
        say: "(je wacht, en kijkt naar Ingrid)"
      open_question:
        say: "Ingrid, jij zat hier in 2012. Hoe kijk jij hiernaar?"        # the line when addressed to the quiet one
      confront:
        say: "Frank, dit is precies wat in 2012 misging."
        any: "Ik was in 2012 manager Aansluitingen. Niet de baas van het programma. Nog iets?"
    # routes (sponsor, start 46):
    #   A: paraphrase>frank +7 53 (heard, interest) > open question>ingrid +6 59 (quiet: +12 -> 71) > empathy>frank +6 77 (lead-in, cue)
    #      > silence>frank +12 > 81 capped (concern) > propose teams_present_monthly +8 89 > ask: commitment (6 moves)
    #   B: mood>room +8 54 (Monique interjects at Luistert: claim) > paraphrase>monique +7 61 (heard) > inquiry>frank +8 69 (interest)
    #      > silence>ingrid +12 81 (quiet, room +12 capped at 81 until the concern) > reflect>frank (lead-in) > silence>frank (concern)
    #      > propose date_kept_first +8 > ask: commitment (8 moves)
    #   C (no quiet one): paraphrase>frank 53 > inquiry>frank 61 > empathy>frank 67 > ... capped at concern.at - 1 = 71, no lead-in, no concern
    #      > propose date_kept_first (addresses the interest) > ask at >= 55: partial (6 moves)
    # routes (regime, start 41): the same shapes; route A needs one more listening move (start 5 lower); the commitment is the proposal
    #   one_stream_board_with_dashboard or the experiment. Compliance in 4: pressure ("Ruud zou dit niet willen") > propose dashboard_as_asked > ask.
    # trap: talking only to Frank (three in a row: Monique disengages, -4); showing data before the room is heard (-12, Monique: "Die cijfers ken ik niet").
```

**What the flags do in Act IV** (§7): `flag:interim_sponsor` keeps the Obeya; `flag:strategy_early` opens the strategy screen at `t3_map_region` instead of at `t3_crew_strategy`; `flag:interim_regime` replaces the Obeya with a dashboard; `flag:regime_one_stream` keeps the board on the connections stream; `flag:dashboard_agreed` means the player put their name under the dashboard (−5 trust with Sanne, Joost and Marco when they hear; Marco says "Dit is 2012" if `heard:marco_2012`).

`heard:ingrid_2012` is read in Act V: Ingrid starts `talk_asset_manager` at +10 openness and adds a line about 2014 to the NTA 8120 audit's maintenance finding.

---

## 6. Ruud's monthly call

**The rule** (PLAN §4.0 item 4):
- While `flag:ruud_seconded` is set and `flag:ruud_back` is not, `ask_coach` becomes **Ruud bellen**: one full Kata cycle by phone, then a **28-day cooldown**.
- The HUD's coach button shows the next possible day as a date ("Ruud · weer vanaf dinsdag 14 maart"), never a real-time countdown (respect the player's time).
- **Main quest only**, as always. Asked while no main is active, or about a side mission, Ruud does not coach, and the call does not count against the cooldown.
- Milestones and the finale get no coaching. `t3_interim_mt` is a main, so it can be called about.
- The coaching-kata missions (`coach_intake_lead` if still open, `coach_work_prep_lead`, the Act IV kaizen week) carry the rest. The player coaches others in the year they are coached least.

**Why 28 days and one cycle.** A Kata coaching cycle is a short daily conversation about the next experiment (Rother, *Toyota Kata*, 2009). A monthly call cannot be that, so the game makes it one *full* cycle, the five questions in order with the reflection block. Between calls the player is on their own, and the A3, the Check and their own coaching sessions are the daily cycle. 28 days (`estimate:`) is a calendar month, and about two Checks of a typical main (14–21 days each), so each call has something to reflect on.

**The call** (`kind: coach_call`, a new shape, §10). It is not a persuasion: there is no meter and nothing can be ruined. Ruud asks; the player answers by *picking from their own state*, so the call is a mirror and never a quiz. The rules judge nothing. Ruud's next line depends only on what kind of answer was picked.

```yaml
coach_calls:
  - id: ruud_call
    person: ruud
    available: {all: [flag:ruud_seconded], none: [flag:ruud_back]}
    cooldown_days: 28
    main_only: true
    opening:
      - {needs: null, text: "Met Ruud. Ik sta op het perron in Den Haag, dus als het wegvalt, bel ik terug. Hoe heet je hoofdzaak op dit moment?"}
      - {needs: {all: [heard:ruud_2012, flag:lean_programme_2]}, text: "Met Ruud. Je weet wat ik in 2012 deed. Ik ga je niet vertellen wat je moet doen. Hoe heet je hoofdzaak?"}
      - {needs: {all: [failed:prep_storm_week]}, text: "Met Ruud. Ik heb over de storm gelezen. Daar hebben we het straks over, als jij wilt. Eerst: wat is je hoofdzaak?"}
    questions:                             # asked in this order; each reads the active main's state
      - id: target
        ask: "Wat wil je bereiken? Waar moet het over een paar weken staan?"
        picks:
          - {kind: a3_target, label: "{kpi_name}: van {start} naar {target}", reply: "Waarom dat getal, en niet een ander?"}
          - {kind: none, label: "Dat weet ik nog niet precies", reply: "Wie merkt het als het beter gaat? Begin daar."}
      - id: actual
        ask: "Waar sta je nu? Wat heb je zelf gezien, en wat heb je gemeten?"
        picks:
          - {kind: measured, label: "{kpi_name} is nu {value} (gemeten op {day})", reply: "Gemeten waar? Op het bord, of aan de bak?"}
          - {kind: clue, label: "Gezien: {clue_short}", reply: "Wat zei dat over de stroom, en wat alleen over die ene dag?"}
          - {kind: none, label: "Ik ben er nog niet geweest", reply: "Wanneer ga je kijken?"}
      - id: reflect                        # only when the previous call named a next step
        when: {previous_call: next_step}
        ask: "Vorige keer zei je: {previous_step}. Wat verwachtte je, en wat gebeurde er?"
        picks:
          - {kind: check_result, label: "De Check: {check_line}", reply: "Wat heb je daarvan geleerd wat je vooraf niet wist?"}
          - {kind: not_done, label: "Ik ben er niet aan toegekomen", reply: "Wat kwam ertussen? Is dat iets wat vaker gebeurt?"}
      - id: obstacle
        ask: "Wat houdt je tegen? En welke van die dingen pak je nu aan?"
        picks:
          - {kind: clue, label: "{clue_short}", reply: "Hoe weet je dat dít het is, en niet iets wat erop lijkt?"}
          - {kind: person, label: "{person_name}: {known_layer}", reply: "Wat heeft {person_name} nodig om mee te doen?"}
          - {kind: none, label: "Ik weet het niet", reply: "Wie zou het wel weten? Ga het vragen."}
      - id: next_step
        ask: "Wat is je volgende stap, en wat verwacht je dat er gebeurt?"
        picks:
          - {kind: a3_countermeasure, label: "{countermeasure}: {prediction}", reply: "Hoe klein kun je die stap maken?"}
          - {kind: talk, label: "Eerst praten met {person_name}", reply: "Wat wil je dat {person_name} na dat gesprek denkt?"}
          - {kind: gemba, label: "Eerst kijken bij {place_name}", reply: "Wat verwacht je te zien? Schrijf het op voordat je gaat."}
      - id: learn
        ask: "Wanneer kunnen we zien wat je ervan geleerd hebt?"
        picks:
          - {kind: check_date, label: "Op {check_day}", reply: "Dan bel ik daarna."}
          - {kind: date, label: "Over twee weken", reply: "Goed. Schrijf op wat je verwacht. Dan weet je het straks zeker."}
    closing:                               # one insight a cycle: the main mission's own insight for its stage (as before)
      - {text: "{stage_insight}"}
      - {text: "Een maand. Bel me niet eerder, tenzij er iemand in gevaar is. Dan bel je meteen."}
    personal:                              # one line per call, after the closing; first match wins, each once
      - {needs: {all: [delivered:el_amrani]}, text: "In Den Haag praten we over vijftienduizend aanvragen. Ik denk elke keer aan één warmtepomp in Nova-Oost."}
      - {needs: {all: [flag:interim_regime]}, text: "Frank belde me. Hij vroeg niks, hij wilde vooral vertellen dat het goed ging. Dat is ook een vorm van vragen."}
      - {needs: {all: [flag:interim_sponsor]}, text: "Frank stuurde een foto van het bord. Sanne stond ervoor, niet hij. Dat had hij twee jaar geleden niet gedaan."}
      - {needs: null, text: "Hier rekenen ze met gemiddelden over het hele land. Ik zeg steeds: ga kijken in Lindeveld. Ze kijken me aan alsof ik een vreemde taal spreek."}
      - {needs: {all: [done:t3_kaizen_week], none: [flag:kaizen_by_consultants]}, text: "Ik zag de foto van de kaizenweek. Wie stond er vooraan?"}
    side_reply: "Daar ga ik je niet mee helpen. Dat is van jou. Wat is je hoofdzaak?"
    no_main_reply: "Je hebt nu geen hoofdzaak. Dan heb je tijd om te kijken. Bel me als je weet waar."
```

**Why it is fair to the rule "the coach mostly asks".** Each reply is a question, except the closing's one insight (the mission's own, as before) and the personal line. Ruud never says which pick was good. A player who picks "Dat weet ik nog niet precies" four times hears four good questions and no verdict.

**After the secondment.** When Ruud returns (`flag:ruud_back`), `ask_coach` goes back to the old rule (no cooldown). In Act V his questions turn around more and more ("Wat zou jij nu vragen, als jij mij was?"), a new `act5` line per stage in the coach bank. He is preparing the player for §8.

---

## 7. Act IV: two openings, one storm

### 7.1 The openings

| | **Sponsor** (`flag:interim_sponsor`) | **Regime** (`flag:interim_regime`) |
|---|---|---|
| The Obeya | stands | replaced by a dashboard (output per department), except on the connections stream with `flag:regime_one_stream` |
| In the simulation | the board's KPIs keep supporting `silo_kpis`' fix (sustain §2.8, "a steering KPI") | `silo_kpis`' fix loses its steering-KPI support while the regime runs; drift can make it reopen in the "Terugval" lane (problems only through missions: it comes back through its own mission) |
| The strategy screen | opens at `t3_map_region` with `flag:strategy_early` (the player sees open and locked options a whole act sooner) | opens at `t3_crew_strategy`, as drafted |
| The big shortcut | `bought_vsm` (as drafted: a competent bureau, a bought map) | **`t3_consultants`, "Lean-programma 2.0"**, Frank's offer, replacing `bought_vsm` (§7.2) |
| Frank in the act | beats: he comes to the gemba, asks Joke a question, stands at the storm board with coffee | the persuasion `frank_interim` (§7.3) as the way to bring him along; his beats ask for numbers |
| The storm (`prep_storm_week`) | Frank: "Wat heeft het team nodig?" | the all-hands plan is voiced by Frank (`who: frank`), not by a role |
| The way back | — | the team-led kaizen week (§7.3) |

Both openings are playable to the end of the act. The regime is a setback, never a loss: every Act IV mission can be solved under it. What changes is how long the fixes last, which shortcuts are offered, and who the player must bring along.

**`t3_map_region` changes** (tier-3 draft §1.1):
- `requires` adds `t3_interim_mt`;
- `briefing_variants.regime`: "Frank wil binnen twee weken een dashboard van heel Zuidmark. Ruud zou je hebben laten lopen. Joke van Beek belde al: 'Bij ons rijden ze een uur per klus.' Loop de aansluitstroom in Nova, Lindeveld en Havenzij, of laat het bureau het doen. Wat in Nova klopt, klopt misschien niet in Lindeveld.";
- the temptation `bought_vsm` gets `needs: {none: [flag:interim_regime]}`; `t3_consultants` gets `needs: {all: [flag:interim_regime]}`;
- `rewards.unlocks` adds `strategy` when `flag:strategy_early`.

### 7.2 The consultancy temptation `t3_consultants`

The act's big shortcut under the regime. It is a *respectable* shortcut: the bureau is competent, Frank needs it, and the MT applauds. Its cost is ownership.

```yaml
    temptations:                           # on t3_map_region, regime only
      - id: t3_consultants
        who: frank
        when: accepted
        needs: {all: [flag:interim_regime]}
        text: "Ik heb een voorstel van een bureau: Lean-programma 2.0. In twee weken een waardestroomkaart van heel Zuidmark, daarna vier kaizenweken met hun facilitators, en een dashboard voor het MT. Het hoofdkantoor betaalt. Den Haag ziet dat we iets doen. Jij hoeft alleen te tekenen dat je het begeleidt."
        accept: "Je tekent: het bureau doet het programma, jij begeleidt."
        decline: "Je zegt nee: de teams brengen hun eigen werk in kaart, met jou erbij."
        accept_sets_flags: [flag:lean_programme_2, flag:vsm_bought]
        accept_effects: {complete_goal: true, reputation: 5, trust: {lv_monteurs: -1, hz_work_prep: -1, monteurs: -1}}
        decline_effects: {reputation: -3, person_trust: {frank: -5}}
        decline_line: {who: frank, text: "Dan moet jij het laten zien. Zonder bureau. Ik zet het in het verslag."}
```

**Its later cost** (long term over short term; each a fact the rules already read):
- `flag:vsm_bought`: as drafted (averages hide Lindeveld and Havenzij; a key clue one level deeper; Joke and Yusuf −10 openness).
- **Ownership.** While `flag:lean_programme_2` is set, every Act IV fix gets the compliance buy-in (×0.6 life, dialog spec §4.2): the bureau's changes, not the team's. The sustain view shows it as thinner bars with the bureau's logo, not a face (PLAN §4.3.6).
- `t3_kaizen_week`'s consultant blitz is the programme's default: the temptation is pre-accepted, and declining it needs Frank (§7.3).
- If `heard:marco_2012`: Marco's beat "Dit is 2012." and his trust −1 at the first kaizen week.
- The NTA 8120 audit (Act V) records an observation (not a finding): "Verbeteringen uit 2028 zijn niet belegd bij een eigenaar in de lijn." It costs reputation −3 if those fixes no longer hold.

**Its short-term pay is real:** `t3_map_region` completes at once, reputation +5 now, and the MT is happy. It is the 5 % case done wrong: there is no safety reason here, only a director's comfort.

**The way back** is the team-led kaizen week (§7.3). It clears `flag:lean_programme_2` (`cleared_by: [team_led:t3_kaizen_week]`, §10), and fixes acted after it get their normal buy-in again. The earlier ones keep their wear, as in the dialog spec's repair rule.

**Declining** costs reputation −3 and Frank's trust now. It pays later through the teams' commitment, without a special reward (the engagement loop dropped "Zonder consultant" for rewarding an absence; D34 already covers the pattern).

### 7.3 The team-led way back, and `frank_interim`

**`t3_kaizen_week` under the regime.**
- With `flag:lean_programme_2`, the consultant blitz is the default.
- To hold a team-led week instead, the player needs Frank's agreement: `frank_interim` at `partial` or better. The proposal that addresses his concern puts the *team's presentation to the MT* on the table.
- When the week is team-led (`flag:kaizen_by_consultants` not set) and the team presents to the MT:
  - `flag:lean_programme_2` and `flag:interim_regime`'s dashboard rule clear (`flag:regime_eased`): Frank brings the Obeya back next to the dashboard. The debrief line: "Frank vroeg Yusufs team of ze dit bord ook voor Havenzij willen. Hij vroeg het. Hij zei het niet."
  - Fixes acted after this get their own buy-in again.
- Without the regime, the kaizen week is as drafted.

```yaml
dialogs:
  - id: frank_interim
    person: frank
    kind: persuade
    mission: t3_kaizen_week
    needs: {all: [flag:interim_regime], none: [flag:regime_eased]}
    patience: 10
    # start: rule_bound 35 + 0 + 0 + (trust 45 -> -1) + 0 = 34; +10 with heard:frank_interim (the MT); +5 with flag:regime_one_stream (his own proof is running)
    opening: "Je hebt vijf minuten. Het bureau staat klaar voor maandag. Waarom zou ik dat afzeggen?"
    position: {text: "Het programma loopt. Het hoofdkantoor heeft het gezien. Ik ga het niet halverwege stoppen omdat jij het anders wilt.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [paraphrase, inquiry, open_question]
        text: "Het bureau levert een presentatie, een foto en een getal. Dat kan ik doorsturen. Wat levert jouw team mij op, in een week?"
        tags: [claim]
      - id: concern
        at: 72
        via: [empathy, reflect, inquiry]
        lead_in: {text: "Kijk, ik zeg je wat ik niet in het MT zeg.", tags: [feeling]}
        text: "Als het team het doet en het mislukt, dan heb ík het bureau afgezegd. Dan sta ik er alleen voor, in mijn interimjaar. Met het bureau mislukt het in elk geval netjes."
        tags: [admission]
        unlocks: {facts: [heard:frank_alone], proposals: [team_presents_frank_opens]}
    reframe: "Vanuit Yusufs tekenaars? Die krijgen een week lang mensen in pak die hun werk uitleggen. … Ja. Dat zou ik ook niet willen."
    warning: "Ik heb hier eigenlijk geen tijd voor."
    data: ["long_drives:0", "underground_crowding:1"]
    lines:
      show_data:
        lands: "Die cijfers komen van het team zelf? Niet van het bureau? Hm."
        misses: "Mijn dashboard zegt iets anders."
    proposals:
      - {id: cheaper_than_bureau, addresses: [interest], label: "Het scheelt geld",
         say: "Een week met het eigen team kost een fractie van het bureau.",
         reply: "Geld is niet mijn probleem. Monique misschien wel."}
      - {id: two_day_pilot_frank, addresses: [concern], label: "Eerst twee dagen, met een stopmoment",
         say: "Twee dagen met het team. Woensdagochtend kijk jij. Als je het niet ziet zitten, komt het bureau alsnog.",
         reply: "Een stopmoment. Met mij erbij. Dan sta ik er niet alleen voor."}
      - {id: team_presents_frank_opens, hidden: true, addresses: [concern], label: "Het team presenteert, jij opent",
         say: "Het team presenteert vrijdag zelf aan het MT, en jij opent de presentatie. Niet als degene die het bureau afzegde. Als de directeur die zijn eigen mensen liet werken.",
         reply: "Ik open. Zij presenteren. Als het werkt, is het van hen en van mij. Als het niet werkt… dan heb ik in elk geval mijn mensen gevraagd."}
    co_proposal: {id: team_presents_frank_opens, text: "Ik open die presentatie. En ik nodig het hoofdkantoor uit. Als ze iets willen zien, laten we ze dit zien."}
    outcomes:
      commitment: "Goed. Ik zeg het bureau af. Maandag om acht uur. Vrijdag open ik de presentatie, en ik zorg dat het hoofdkantoor erbij is."
      partial: "Twee dagen. Woensdag kijk ik. Dan beslis ik."
      heard: "Je hebt een punt. Het bureau komt maandag toch."
      compliance: "Prima. Op jouw verantwoording. Als het misgaat, weet iedereen wiens idee het was."
      ruined: "Het bureau komt maandag. Dit gesprek is klaar."
    # route (start 34): open question +6 40 > paraphrase +7 47 (heard) > inquiry +8 55 (interest) > show_data +15 (x1.5, rule_bound) 70
    #        > empathy +6 76 (lead-in: a feeling) > reflect +5 (x0.5) > 81 capped (concern) > propose team_presents_frank_opens +8 89 > ask (8 moves)
    # other routes: start 44 with heard:frank_interim (one move fewer); the experiment two_day_pilot_frank instead of the hidden proposal (partial, upgraded
    #   to commitment by the week's own Check: condition_needs {all: [checked:kaizen_week]}); inquiry at the lead-in instead of reflect.
    # trap: pressure ("Ruud zou dit nooit hebben goedgevonden") -> compliance: the week is team-led, but Frank's buy-in is compliance and flag:regime_eased is NOT set.
    condition_needs: {all: ["checked:kaizen_week"]}
```

### 7.4 Winter 2: the storm without Ruud

`prep_storm_week` (tier-2 draft §2.10) keeps its goal, options, event and costs. Changes:
- `requires` adds `facts: {all: [flag:ruud_seconded]}` for its first occurrence; `opens_on: {season: storm}` (§1). It stays a side mission with a deadline (21 days) and an event.
- **Its voice depends on the opening:**
  - under the regime the all-hands option is offered by Frank (`who: frank`: "Iedereen oproepbaar, verlof ingetrokken. Dan kan niemand zeggen dat we het niet geprobeerd hebben.");
  - under the sponsor, Frank asks Kees what the team needs (a beat).
- **The climax scene `storm_night_board`.** On the event's first night, the game stops the time skip at 05:30 for a short group talk at the escalation board in the control room (Phase 3 item 3.2). Ruud is not there; his absence is the scene. Its outcome changes nothing in the storm's numbers (the plan chosen earlier decides those). It decides whether the night ends with people heard, and it can set `heard:kees_storm`, which Act V's `kees_meter_alarms` reads (+5).

```yaml
dialogs:
  - id: storm_night_board
    kind: group
    chair: kees
    members: [wendy, esra, frank]
    quiet: wendy
    trigger: {event: prep_storm_week, at: start, hour: "05:30"}
    place: control_room.escalation_board
    patience: 8
    retry_after_days: null                 # a scene: once
    # start: mean of kees (defender 40, mood moe -10) 30, wendy (quiet 47, moe -10) 37, esra 50, frank 33 (regime) or 52 (sponsor)
    #   -> about 38 (regime) or 42 (sponsor): Op z'n hoede to Luistert. A night shift starts low; a sponsor who came helps.
    opening: "Kees: 'Vierhonderdtwintig meldingen sinds middernacht. Zes ploegen buiten. De telefoon staat in de wacht tot halfnegen.'"
    position: {text: "Kees: 'We redden het. We redden het altijd. Zeg maar wat je van ons nodig hebt, dan kan ik weer naar de wand.'", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [paraphrase, open_question, mood], text: "Kees: 'Het bord hangt vol rood. Dat is goed, dan zie je het. Maar niemand haalt de kaarten eraf. Er is niemand van Werkvoorbereiding wakker.'", tags: [claim, feeling]}
      - {id: quiet, person: wendy, at: 55, via: [silence, open_question, empathy],
         text: "Wendy: 'Ruben is om drie uur naar huis gestuurd. Hij reed bijna een sloot in. Ik heb hem naar huis gestuurd, niet de planning. Dat staat nergens.'",
         tags: [admission, feeling], unlocks: {facts: [heard:wendy_storm]}}
      - {id: concern, at: 68, via: [reflect, empathy, silence], lead_in: {text: "Kees: 'En als dit straks…'", tags: [hesitation]},
         text: "Kees: 'Vorig jaar stond Ruud hier om vijf uur met koffie. Niemand zei het, maar iedereen zag het. Vannacht dacht ik: als het misgaat, wie staat er dan naast ons?'",
         tags: [admission], unlocks: {facts: [heard:kees_storm]}}
    proposals:
      - {id: rest_rule_now, addresses: [quiet, concern], label: "Een rustregel, nu, op het bord",
         say: "We zetten op het bord: niemand rijdt na twaalf uur dienst. Wendy beslist, niet de planning.",
         reply: "Kees: 'Op het bord. Dan hoeft niemand zich te schamen als hij stopt.'"}
      - {id: wake_work_prep, addresses: [interest], label: "Werkvoorbereiding om zeven uur aan het bord",
         say: "Ik bel Joost. Om zeven uur staat er iemand van Werkvoorbereiding aan dit bord.",
         reply: "Kees: 'Dat scheelt. Dan haal ik de kaarten er niet alleen af.'"}
    outcomes:
      commitment: "Kees: 'Goed. Rustregel op het bord, Joost om zeven uur. En jij… blijf je nog even?'"
      partial: "Kees: 'We gaan door. Bedankt dat je er bent.'"
      heard: "Kees: 'Fijn dat iemand het vroeg.'"
      none: "Kees: 'Ik moet terug naar de wand.'"
    members_lines:
      esra: {interjections: [{band: Luistert, text: "Esra: 'Het statusbericht staat sinds tien uur in het keuzemenu. De helft hangt meteen op. Dat scheelt ons de nacht.'", tags: [claim]}]}
      frank:
        interjections:
          - {band: Op z'n hoede, needs: {all: [flag:interim_regime]}, text: "Frank: 'Ik wil om acht uur een overzicht voor het hoofdkantoor. Aantallen.'", tags: [claim]}
          - {band: Luistert, needs: {all: [flag:interim_sponsor]}, text: "Frank: 'Ik heb koffie meegenomen. Ik weet niet of dat helpt.'", tags: [feeling]}
      wendy: {interjections: []}
    # route: mood>room +8 > paraphrase>kees (heard, interest) > silence>wendy (quiet, +12) > reflect>kees (lead-in) > silence>kees (concern)
    #        > propose rest_rule_now > ask: commitment (7 moves). Without Wendy: partial at best.
    # tie-in: rest_rule_now sets flag:rest_rule (the tier-2 dialogs' rest rule, §1.1 of the four-tier audit) when committed.
```

**The debrief** of `prep_storm_week` adds, when Ruud is away: "Ruud belde om negen uur. Hij vroeg niet hoe het ging. Hij vroeg wie er vannacht naast Kees stond."

---

## 8. Winter 3: Ruud's return and *De opvolger*

### 8.1 Ruud's return and his last date

- **`ruud_returns`** (a beat on `t4_hoshin`'s availability; Act V's title card is his):
  - It sets `flag:ruud_back` and ends the call rule.
  - "Het systeem. Ik ben terug, en ik ga weer weg. Op 1 april stop ik. Dat is geen dreigement, dat is de AOW. Twintig prioriteiten is er geen. Wat is de ene?"
  - Frank goes back to his manager's role. As sponsor, he is Ruud's hoshin partner (`frank_twenty` starts as drafted). Under the regime he is relieved and defensive: `frank_twenty` starts 5 lower, unless `flag:regime_eased` is set.
- **`ruud_retirement`** (a dated beat, not a mission): `deadline_on_day` = the first 1 April at least 240 days after Act V opens (§1). It is the campaign's last deadline, the bookend of Henk's in Act I. Like Henk's, missing it closes a door and never the game: if the finale is not done by then, Ruud's farewell drinks happen anyway, and the finale's last scene is played without him at the table (§8.4).

### 8.2 `de_opvolger`: the finale (replaces `t4_new_ci_lead`)

```yaml
missions:
  - id: de_opvolger
    name: De opvolger
    kind: finale                           # no slot (like a milestone), cannot fail, cannot be abandoned
    tier: 4
    act: 5
    chapter: De opvolger
    arc: winters
    requires: {any_of: [t4_investment_plan]}
    opens_on: {day_before: ruud_retirement, days: 42}   # whichever comes first: the plan done, or six weeks before Ruud's last day
    goal:
      type: sequence
      steps:
        - {type: talk_to, dialog: successor_choice, outcome: heard}        # with Ruud: who?
        - {type: talk_to, dialog: "successor_{chosen}", outcome: partial}  # the candidate's own doubt
        - {type: talk_to, dialog: first_question, outcome: any}            # the last scene
    principles: [respect, long_term, improve]
    briefing: "Ruud stopt op {retirement_date}. Het MT heeft besloten: jij volgt hem op als directeur Netbeheer Zuidmark. Ruud zegt: 'Dan heb je iemand nodig die doet wat jij deed. Wie?'"
    debrief: "{final_card}"
    beats:
      - {on: accepted, who: ruud, text: "Ik heb drie jaar vragen gesteld. Nu ben jij aan de beurt. Niet aan mij, aan hen."}
    teaches: [coaching_kata, respect_for_people, leader_standard_work]
    rewards: {title: "Coach", vitrine: ruud_kata_card, reputation: 5}
```

The MT appointing the player director is the story's gift, not a mechanic. It changes no slot or rule. After the finale, play continues as free play (§11 Q6): the successor's missions are the old ones, sustain and drift go on, and Ruud sends a postcard now and then, as Henk did.

**The final card** (`final_card`, read from the simulation, never scripted):

> Op je eerste dag stonden er {open_start} aanvragen op de wachtlijst van Zuidmark, gemiddeld {wait_start} weken. Vandaag zijn het er {open_now}, gemiddeld {wait_now} weken. Van wie een datum kreeg, kreeg {date_kept}% die datum ook. {fixes_holding} van je verbeteringen staan nog. {people_line}

`people_line` names the people the player developed (`committed` and `coach` facts), never the ones who left; for a player who developed nobody: "Je hebt veel opgelost. Volgende keer: laat ze het zelf oplossen."

### 8.3 Who sits across the table

**The candidates.** A candidate is offered when their needs are met (C19 grammar). The player chooses among those offered; Lotte from outside is always offered. That is a real choice: a player who developed Sanne may still hire from outside.

| Candidate | Needs | Why this person |
|---|---|---|
| **Anouk de Vries** | `{all: [standardised:custom_design], any: [committed:anouk_owns_tray, done:coach_work_prep_lead, lifted:anouk_late], none: [flag:anouk_left]}` | Act 0's drowning werkvoorbereider owns the standard designs, and was coached by Joost (D43) or lifted by you. |
| **Ahmed Bouzid** | `{all: [heard:ahmed_trainer], any: [chose:knowledge_drain:twi_job_instruction, chose:knowledge_drain:skills_matrix_buddy, chose:training_capacity:train_the_trainer]}` | The night-shift monteur who called a retiree became the one who trains apprentices (Act IV). |
| **Sanne Bakker** | `{all: [done:coach_intake_lead], none: [complied:sanne_kpi]}` | The team lead of "het postkantoor" learned to improve by being asked, not told. |
| **Lotte Smit** (external) | — (always) | The game says so kindly when she is the only one: "Er is niemand van binnen die dit kan overnemen. Dat zegt iets over drie jaar, niet over jou als mens." |

**`successor_choice`** (with Ruud; a check-in shape in his room; cannot be ruined):

```yaml
dialogs:
  - id: successor_choice
    person: ruud
    kind: checkin
    tutorial: true
    patience: 8
    place: directie.ruud_office
    opening: "Koffie? De laatste keer dat ik die van de automaat haal. Daar zal ik niet om huilen."
    position: {text: "Wie volgt jou op als CI-lead? Ik vraag het niet om het voor je te beslissen. Ik vraag het omdat ik wil weten of je het weet.", tags: [claim]}
    layers:
      - {id: interest, at: 60, via: [open_question, inquiry, paraphrase],
         text: "Toen ik jou aannam, wist ik niet of je het kon. Ik wist wel dat je vragen stelde. Dat was genoeg.", tags: [feeling]}
      - {id: concern, at: 72, via: [reflect, experience, empathy],
         lead_in: {text: "Weet je wat ik het moeilijkst vind?", tags: [feeling]},
         text: "Niet het stoppen. Dat ik niet zal zien of het blijft. In 2012 zag ik het verdwijnen. Nu ga ik naar huis en moet ik het geloven.",
         tags: [admission], unlocks: {facts: [heard:ruud_last]}}
    choice:                                # after the interest is revealed, Ruud asks: "Wie?" The player picks one offered candidate.
      ask: "Wie?"
      candidates: [anouk, ahmed, sanne, lotte]   # each shown only when its needs are met (§8.3); lotte always
      replies:
        anouk: "Anouk. Die had drie jaar geleden een bergje met een vlag op een post-it. Ze tekent nu de standaard voor de hele regio. Ja."
        ahmed: "Ahmed. Die belde 's nachts een gepensioneerde monteur uit zijn bed. Nu bellen ze hem. Ja."
        sanne: "Sanne. Die vond dat jij irritant was, omdat je alleen maar vroeg. Ja. Juist daarom."
        lotte: "Lotte Smit, van buiten. Goed. Dan begint zij waar jij begon. Bij de brief op mijn bureau."
        lotte_passed_over: "Lotte Smit, van buiten. … Goed. Het is jouw keuze, en ik vraag er niet naar. Eén ding wel: weet {insider_short} het al? Vertel het {hem_haar} zelf. Niet via de mail."   # §8.6: an insider qualified
        lotte_only: "Er is niemand van binnen die dit kan overnemen. Dat zegt iets over drie jaar, niet over jou als mens. Lotte Smit begint maandag. Zij begint waar jij begon."
    outcomes:
      lifted: "Dan ga ik naar huis met iets wat ik in 2012 niet had. Een naam."
      heard: "Goed. Ga het haar vragen. Of hem. Niet vertellen. Vragen."
    sets_flags_on_choice: [successor:{chosen}]
    # §8.6: choosing lotte while an insider was offered also sets passed_over:{insider}
```

### 8.4 The successor's talk: four variants

Each is a short persuasion with a candidate who doubts. Commitment is not required: `partial` completes the step. The **trap is the same in all four**, and it is the campaign's lesson: telling them how. The steering moves before the concern are fixing mode (−12), as in a check-in, because they *are*. The proposals that address the concern hand over the question, not the answer.

```yaml
dialogs:
  - id: successor_anouk
    person: anouk
    kind: persuade
    mission: de_opvolger
    patience: 10
    # start: overloaded 35 + 10 (goed) + 10 (team trust work_prep +1) + 4 (trust 70) + 2 (morale 70) + 15 (memory: committed) = 76 capped 80 -> Open
    opening: "Joost zei dat je me zocht. Als het over de standaard van Havenzij gaat: die is af. Nou ja. Bijna."
    position: {text: "CI-lead? Ik? Ik ben werkvoorbereider. Ik teken aansluitingen. Ik weet niet of ik dat kan.", tags: [claim, doubt]}
    layers:
      - {id: interest, at: 62, via: [open_question, inquiry, paraphrase],
         text: "Weet je wat ik het leukst vond, de afgelopen jaren? Niet de standaard. Dat Joost vroeg hoe ik het zou doen, en dat hij dan wachtte. Dat wil ik ook kunnen. Wachten.", tags: [feeling]}
      - id: concern
        at: 74
        via: [reflect, empathy, silence]
        lead_in: {text: "Het is alleen…", tags: [hesitation]}
        text: "Ik werkte vroeger tot zeven uur zodat niemand zag hoe langzaam ik was. Als ik dit doe, kijkt iedereen. De hele regio. En jij zit er niet meer naast."
        tags: [admission, doubt]
        unlocks: {facts: [heard:anouk_successor], proposals: [first_month_together]}
    reframe: "Vanuit de nieuwe werkvoorbereider die volgend jaar begint? Die zit daar zoals ik toen. Met twee bakken. … Die wil ik niet alleen laten."
    warning: "Sorry. Ik word een beetje zenuwachtig."
    proposals:
      - {id: training_course, addresses: [], label: "Een leiderschapscursus",
         say: "Er is een goede leiderschapscursus. Die regel ik voor je.",
         reply: "Een cursus. Ja. Dat is fijn. Dan weet ik het vast beter."}
      - {id: start_with_one_team, addresses: [concern], label: "Begin bij één team",
         say: "Begin bij één team. Werkvoorbereiding Havenzij, waar ze je al kennen. De rest komt later.",
         reply: "Eén team. Waar ik de tekeningen ken. Dat… kan ik me voorstellen."}
      - {id: first_month_together, hidden: true, addresses: [concern], label: "Een maand samen, jij stelt de vragen",
         say: "De eerste maand ben ik erbij. Ik zeg niets. Jij stelt de vragen. Na een maand ga ik weg, en dan merk je dat je het al deed.",
         reply: "Jij zegt niets. Ik vraag. … Zoals Joost bij mij. Oké."}
    co_proposal: {id: first_month_together, text: "Mag ik het eerst een maand proberen, met jou erbij? Niet om te helpen. Gewoon erbij. Zoals toen met het A4."}
    outcomes:
      commitment: "Goed. Maandag om acht uur. Ik zet koffie. Betere koffie dan toen."
      partial: "Ik doe het. Als ik na een maand mag zeggen dat het niet gaat."
      heard: "Ik moet erover nadenken. Maar dank je dat je het vroeg in plaats van zei."
      compliance: "Als jij het zegt. Ik doe mijn best."
      ruined: "Je weet het al voor me. Dat is precies wat ik niet wil worden."
    # route (start 76): open question (interest) > reflect (lands on the feeling; the lead-in) > silence (concern, capped at 83)
    #        > propose first_month_together > ask: commitment (5 moves). A player with less history starts near 50 and needs 3-4 more listening moves.
    # trap: training_course before the concern (fixing mode, -12): "Een cursus. Ja." and her face closes.

  - id: successor_ahmed
    person: ahmed
    kind: persuade
    mission: de_opvolger
    patience: 9
    # start: quiet 47 + 10 (goed) + 0 + 4 (trust 70) + 2 + 15 (memory: lifted / committed) = 78 -> Open
    opening: "Hé. Ik kom net van het opleidingsterrein. Ze hebben vandaag zelf een mof gemaakt. Twee. Allebei goed."
    position: {text: "Ik ben monteur, man. Ik leid jongens op. Dat is iets anders dan vragen stellen aan teamleiders.", tags: [claim, doubt]}
    layers:
      - {id: interest, at: 60, via: [inquiry, open_question, silence],
         text: "Weet je hoe ik ze opleid? Ik doe het voor, dan doen zij het, dan vraag ik: waarom deed je dat zo? Henk deed dat ook. Ik dacht dat het een monteursding was.", tags: [claim, feeling]}
      - id: concern
        at: 74
        via: [reflect, empathy, silence]
        lead_in: {text: "Maar…", tags: [hesitation]}
        text: "Op het hoofdkantoor praten ze anders. Doorlooptijd. Hoshin. Als ik daar zit, ben ik weer die jongen die Henk om twee uur 's nachts belde. Die het niet wist."
        tags: [admission, doubt]
        unlocks: {facts: [heard:ahmed_successor], proposals: [the_same_question]}
    reframe: "Vanuit de nieuwe jongens gezien? Die bellen mij nu 's nachts. … Ik vind dat eigenlijk fijn. Zoals Henk."
    warning: "Ik moet zo weer naar het terrein, hoor."
    proposals:
      - {id: learn_the_words, addresses: [], label: "Leer de woorden van het hoofdkantoor",
         say: "Ik geef je de presentaties van hoshin en de KPI's. Dan ken je de woorden.",
         reply: "Presentaties. Ja. Goed."}
      - {id: start_at_the_yard, addresses: [concern], label: "Begin op het terrein",
         say: "Begin waar je bent. Eén ochtend per week op het hoofdkantoor, de rest op het terrein en in de bus.",
         reply: "Eén ochtend. De rest buiten. Dat kan ik."}
      - {id: the_same_question, hidden: true, addresses: [concern], label: "Het is dezelfde vraag",
         say: "Je vraagt de jongens: waarom deed je dat zo? Dat is precies wat ik op het hoofdkantoor vroeg. Alleen de mof is anders.",
         reply: "Dezelfde vraag. … Henk zou lachen. Hij zei altijd: het vak is overal hetzelfde, alleen de kabel verschilt."}
    co_proposal: {id: the_same_question, text: "Als ik het mag doen zoals op het terrein. Eerst kijken, dan vragen. Geen presentaties."}
    outcomes:
      commitment: "Doe ik. Maar ik blijf op dinsdag op het terrein. Daar ga ik niet over onderhandelen."
      partial: "Ik probeer het. Een kwartaal. Daarna zeg ik eerlijk of het werkt."
      heard: "Ik moet het Henk vragen. Hij stuurt toch altijd kaartjes."
      compliance: "Oké. Als het moet."
      ruined: "Zie je. Ik ben gewoon monteur."
    # route: inquiry +8 (interest) > reflect +10 (lead-in) > silence x1.5 (concern) > propose the_same_question > ask (5 moves)

  - id: successor_sanne
    person: sanne
    kind: persuade
    mission: de_opvolger
    patience: 10
    # start: overloaded 35 + 10 (goed) + 10 (team trust intake +1) + 4 + 2 + 15 = 76 -> Open
    opening: "Nou. Ik hoorde het al. Iedereen hoort alles hier, dat weet je."
    position: {text: "Ik ben teamleider Intake. Het postkantoor. Daar word je geen CI-lead van, dat weet iedereen.", tags: [claim]}
    layers:
      - {id: interest, at: 60, via: [paraphrase, open_question, inquiry],
         text: "Mijn team stelt elkaar nu dezelfde vragen die jij mij stelde. Wat is je doel, waar sta je. Rachid deed het gisteren bij een nieuwe collega. Ik stond erbij en zei niks. Dat kon ik drie jaar geleden niet.", tags: [feeling]}
      - id: concern
        at: 74
        via: [reflect, empathy]
        lead_in: {text: "Alleen, eerlijk… ik word er zenuwachtig van.", tags: [feeling]}
        text: "Ik ben vijfenveertig, nee, achtenveertig nu. Ik heb nooit gestudeerd. Als ik daar zit, tussen Femke en Monique, ben ik weer het postkantoor. En als het misgaat, zeggen ze: zie je wel."
        tags: [admission]
        unlocks: {facts: [heard:sanne_successor], proposals: [intake_as_the_proof]}
    reframe: "Vanuit de klant gezien? Die komt eerst bij ons binnen. Wij zien alles als eerste. … Hè. Zo had ik het nooit bekeken."
    warning: "Joh. Ik heb nog dertig aanvragen."
    proposals:
      - {id: tell_her_she_can, addresses: [], label: "Zeggen dat ze het kan",
         say: "Je kunt dit echt. Geloof me nou maar.",
         reply: "Ja. Dat zeg jij."}
      - {id: two_teams_first, addresses: [concern], label: "Eerst Intake en Werkvoorbereiding",
         say: "Begin met Intake en Werkvoorbereiding samen, met Joost. Daar weet iedereen dat het werkt.",
         reply: "Met Joost. Eén stroom. Ja, dat ken ik."}
      - {id: intake_as_the_proof, hidden: true, addresses: [concern], label: "Het postkantoor is het bewijs",
         say: "Het postkantoor is de plek waar het het eerst werkte. Dat is geen nadeel. Dat is je bewijs. Neem Rachid mee naar het MT.",
         reply: "Rachid mee. Hè. Dan zien ze het zelf. Dan hoef ik niks te bewijzen."}
    co_proposal: {id: intake_as_the_proof, text: "Als ik het mag doen vanaf de Intake. Niet weg van mijn team. Mijn team als het voorbeeld."}
    outcomes:
      commitment: "Afgesproken. En als iemand in het MT 'postkantoor' zegt, mag Rachid antwoorden."
      partial: "Goed. Een halfjaar. Als het niet gaat, ga ik terug naar mijn bak. Zonder gedoe."
      heard: "Zo. Dat had ik nog nooit hardop gezegd. Weer niet."
      compliance: "Prima. Weer iets erbij."
      ruined: "Zie je wel. Je weet het al voor me."
    # route: paraphrase +7 (heard; interest) > empathy +6 (lead-in: a feeling) > reflect +10 (concern) > propose intake_as_the_proof > ask (5 moves)

  - id: successor_lotte
    person: lotte
    kind: persuade
    mission: de_opvolger
    patience: 10
    # start: expert-like newcomer: defender 40 + 10 (goed) + 0 + 0 + 0 = 50 -> Luistert (no history: everything is earned in this one talk)
    opening: "Lotte Smit. Ik heb een map van vier centimeter gekregen. Ik heb hem gelezen. Twee keer."
    position: {text: "Waar moet ik beginnen?", tags: [claim, doubt]}   # the player's own first question to Ruud (§8.5)
    layers:
      - {id: interest, at: 56, via: [open_question, inquiry, paraphrase],
         text: "Bij mijn vorige werkgever was ik projectleider. Daar wist je wat je moest doen: een plan, een planning, een stuurgroep. Hier vraagt iedereen me wat ik zie. Ik zie nog niks. Ik ben hier drie dagen.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [silence, empathy, reflect]
        lead_in: {text: "En dan…", tags: [hesitation]}
        text: "Iedereen hier noemt jouw naam. Marco, Esra, die monteur met de vis op zijn kaartje. Ik ben de nieuwe die het niet weet. Die van buiten. Ze wachten op wanneer ik de eerste fout maak."
        tags: [admission, doubt]
        unlocks: {facts: [heard:lotte_successor], proposals: [walk_with_a_dossier]}
    reframe: "Vanuit mevrouw El Amrani gezien? Die belde vandaag. Ze vroeg naar jou. Ik zei: die is directeur. Ze zei: dan wil ik u spreken. … Ze kent mij niet eens."
    warning: "Sorry. Ik maak aantekeningen. Dat doe ik als ik zenuwachtig ben."
    proposals:
      - {id: hand_over_the_folder, addresses: [], label: "Een overdrachtsmap met alles",
         say: "Ik maak een overdrachtsmap met alle A3's en de stand van zaken.",
         reply: "Nog een map. Ja. Fijn."}
      - {id: meet_the_team_leads, addresses: [interest], label: "Kennismaken met de teamleiders",
         say: "Ik stel je deze week voor aan Sanne, Joost en Marco.",
         reply: "Kennismaken. Goed. Dan heb ik gezichten bij de namen."}
      - {id: walk_with_a_dossier, hidden: true, addresses: [concern], label: "Volg één dossier, zoals ik deed",
         say: "Volg één dossier, van de brief tot de meter. Zoals ik deed in mijn eerste week. Je hoeft niets te weten. Je moet alleen gaan kijken.",
         reply: "Eén dossier. Van brief tot meter. Dan weet ik over een maand iets wat zij niet weten. … Dat is slim. En een beetje eng."}
    co_proposal: {id: walk_with_a_dossier, text: "Mag ik beginnen bij die mevrouw die belde? Haar dossier volgen?"}
    outcomes:
      commitment: "Goed. Maandag begin ik bij de brief op je bureau. Ik bedoel: mijn bureau."
      partial: "Ik ga kijken. En ik kom terug met wat ik zag."
      heard: "Dank je. Ik dacht dat je me een planning zou geven."
      compliance: "Prima. Ik maak er een plan van."
      ruined: "Oké. Dan doe ik het zoals bij mijn vorige werkgever."
```

`lotte` joins `people.yaml` as the external hire (role "CI-lead regio Zuidmark, nieuw"; archetype `defender`; trust 50; `place: connections.intake` in her first week). The catalogue's earlier Lotte (the CI lead of Lindeveld, a far-future placeholder) is dropped with the placeholder (PLAN §4.0 item 6).

### 8.5 The last scene: `first_question`

The successor sits across the table, with their own first A3 (the successor's `npc_experiment`, a small one, drawn from their variant: Anouk the Havenzij standard; Ahmed the apprentices' first-time-right; Sanne the intake form at Lindeveld; Lotte the El Amrani daughter's bakery dossier, §9). Ruud sits at the end of the table, if he is still there (§8.1). The palette is the dialog's fixed one, and the **five Kata questions** are added to the listening row as chips (the `coach` goal's moves, catalogue C7).

The player makes **one move**. The scene ends on that move, and nothing is judged:

```yaml
dialogs:
  - id: first_question
    person: "{successor}"
    kind: scene
    mission: de_opvolger
    moves: one                             # the scene ends after the first move
    opening: "{successor_name} legt een A3 op tafel. Half ingevuld. 'Ik weet niet of dit goed is.'"
    ruud_present: {none: [past:ruud_retirement]}
    endings:                               # keyed on the move the player makes; none is marked right
      kata_target:
        player: "Wat wil je bereiken?"
        npc: "{successor_first_target}"
        ruud: "Zo begon ik ook. Dit keer is het van hen."     # with heard:ruud_2012; else "Zo begon ik ook."
      kata_actual:
        player: "Waar sta je nu?"
        npc: "{successor_first_actual}"
        ruud: "Eerst kijken. Goed."
      open_question:
        player: "Vertel eens. Hoe kwam je hierop?"
        npc: "{successor_story_line}"
        ruud: "Je vraagt. Dat is het hele vak."
      silence:
        player: "(je zegt niets en wacht)"
        npc: "… Oké. Ik begin gewoon. Het doel is…"
        ruud: "Soms is wachten de beste vraag."
      steering:                            # any steering move: perspective, show_data, propose, propose_experiment, ask_commitment
        player: "{steer_line}"
        npc: "Oké. Ik schrijf het op."
        ruud: "Dat was een antwoord. Het mag. Morgen stel je de vraag."
      pressure_or_confront:
        player: "{pressure_line}"
        npc: "… Goed."
        ruud: "Iedereen begint ergens. Morgen begin je opnieuw."
    final_card: true                       # then the final card (§8.2) and the credits; free play continues after
```

**When Lotte was chosen over an insider, the scene changes** (§8.6): the insider sits at the table too, and the player's first question lands on them.

No ending is a failure. Whichever question comes first is "the first Kata question, asked by the player" (PLAN §4.0). The epilogue only *shows* what a coach's first move does: the successor writes, or thinks. Ruud's line is the last thing the coach says, and the most he ever tells.

### 8.6 Lotte chosen while an insider qualified: the table reads it

Fable's note (PLAN §10, 2026-10-16): the successor choice has a **visible consequence, never a score**. Respect for people says developing talent pays; a player who developed Anouk, Ahmed or Sanne and then hired from outside should *see* what they passed over, without being told off. Choosing Lotte when nobody qualified stays as designed: told kindly, no change at the table.

**The rule.**
- When the player picks `lotte` and at least one insider was offered, `successor_choice` sets `passed_over:<insider>` for the **one** insider who sits at the table: the offered insider with the highest trust (ties: Anouk, Ahmed, Sanne, in that order). The others are not named; one face is enough.
- `successor_lotte` (§8.4) is unchanged. Lotte does not know, and the talk is hers.
- `first_question` takes the variant `passed_over` (below): the insider is at the table, with Lotte and (if he is still there) Ruud. Lotte's first dossier runs through the insider's work, so she has asked them to come. **The scene's person is the insider, not Lotte:** whatever the player's one move is, the insider answers it first. That is the consequence: the player's first Kata question as a director goes to the person they did not choose, and that person answers it well.
- Nothing is scored: no reputation, no trust change, no discovery lost. The final card's `people_line` names the insider among the people the player developed, as it would anyway, and adds one sentence (`final_card_extra`). Free play continues; the insider stays, with one later beat.
- Variant needs: `{all: [successor:lotte], any: [passed_over:anouk, passed_over:ahmed, passed_over:sanne]}`.

```yaml
dialogs:
  - id: first_question
    variants:
      - id: passed_over
        needs: {all: [successor:lotte], any: [passed_over:anouk, passed_over:ahmed, passed_over:sanne]}
        person: "{insider}"                  # the move goes to the insider; Lotte is present and has lines
        opening_by_insider:
          anouk: "Lotte legt een A3 op tafel. Het dossier van de bakkerij in Havenzij. 'Ik heb Anouk gevraagd erbij te komen. Het ontwerp ligt bij haar.' Anouk knikt naar jou. 'Hoi. Ze vroeg het aardig.' Ze schuift het A3 een stukje naar zich toe en begint al te lezen."
          ahmed: "Lotte legt een A3 op tafel. Het dossier van de bakkerij in Havenzij. 'Ik heb Ahmed gevraagd erbij te komen. Ik snap niet waarom de monteur twee keer moest komen.' Ahmed steekt een hand op naar jou. 'Ik kom net van het terrein. Laat eens zien.'"
          sanne: "Lotte legt een A3 op tafel. Het dossier van de bakkerij in Havenzij. 'Ik heb Sanne gevraagd erbij te komen. Het begint bij Intake, zei iedereen.' Sanne kijkt even naar jou, dan naar het A3. 'Nou. Ik hoorde het al. Iedereen hoort alles hier.'"
        endings:                            # keyed on the move, as in the main scene; the insider answers, Lotte watches
          kata_target:
            player: "Wat wil je bereiken?"
            npc_by_insider:
              anouk: "Anouk wacht even. Dan, tegen Lotte: 'Dat ze binnen zes weken een datum hebben die klopt. Toch?'"
              ahmed: "Ahmed tikt op het A3. 'Eén keer komen. Niet twee.' Dan, tegen Lotte: 'Zo begin je. Met wat je wilt zien.'"
              sanne: "Sanne leunt naar voren. 'Dat de aanvraag de eerste keer compleet is. Dan scheelt het jou drie weken.'"
            lotte: "'Dat had ik dus aan jou moeten vragen,' zegt Lotte tegen {insider_short}. Het klinkt niet bitter. Het klinkt als iemand die het opschrijft."
          kata_actual:
            player: "Waar sta je nu?"
            npc_by_insider:
              anouk: "'Het ontwerp is af, op één tekening na.' Anouk draait het A3 naar Lotte. 'Kijk, hier. Daar wacht het. Niet bij mij, bij de netstudie.'"
              ahmed: "'De eerste keer stond de meterkast vol dozen. De tweede keer was de klant er niet.' Ahmed haalt zijn schouders op. 'Dat staat niet op dat A3. Dat zie je alleen als je erheen gaat.'"
              sanne: "'Het lag drie weken in de middelste bak. Er miste een foto.' Sanne kijkt naar Lotte. 'Rachid weet precies welke foto. Vraag het hem.'"
            lotte: "Lotte kijkt van het A3 naar {insider_short}. 'Hoe weet je dat allemaal?' — '{insider_answer}'"
          open_question:
            player: "Vertel eens. Hoe zie jij het?"
            npc_by_insider:
              anouk: "Anouk lacht kort. 'Drie jaar geleden had ik hier een bergje met een vlag op een post-it.' Ze wijst. 'Nu weet ik waar het ligt. Dat is het hele verschil.'"
              ahmed: "'Weet je wat Henk zou zeggen?' Ahmed grijnst. 'Het vak is overal hetzelfde, alleen de kabel verschilt.' Hij schuift het A3 terug naar Lotte. 'Ga kijken. Ik ga mee, als je wilt.'"
              sanne: "'Eerlijk? Het postkantoor ziet alles als eerste.' Sanne zegt het rustig, alsof ze het al vaker heeft gezegd. 'Daar moet ze beginnen.'"
            lotte: "Lotte, tegen {insider_short}: 'Mag ik je volgende week vaker bellen?' {insider_short} knikt."
          silence:
            player: "(je zegt niets en wacht)"
            npc: "Het blijft even stil. Dan begint {insider_short} te praten. Niet tegen jou: tegen Lotte. Rustig, punt voor punt, zoals jij het drie jaar lang vroeg."
            lotte: "Lotte schrijft. Na een minuut kijkt ze op, naar jou. '{Zij_Hij} doet dit vaker, hè.'"
          steering:
            player: "{steer_line}"
            npc: "{insider_short} wacht tot je klaar bent. Dan, tegen Lotte: 'Dat is één manier. Mag ik je laten zien hoe het op de vloer gaat?'"
            lotte: "Lotte kijkt van jou naar {insider_short}, en knikt naar {insider_short}."
          pressure_or_confront:
            player: "{pressure_line}"
            npc: "… {insider_short} legt een hand op het A3. 'Laten we gewoon gaan kijken. Met z'n tweeën.'"
            lotte: "Lotte staat al op."
        ruud: "Ruud zegt niets. Hij kijkt naar {insider_short}, en dan naar jou."   # every ending; dropped when past:ruud_retirement
        insider_answer:
          anouk: "Ik heb het drie jaar lang gevraagd gekregen. Op een gegeven moment ga je het jezelf vragen."
          ahmed: "Iemand vroeg me altijd: waarom deed je dat zo? Op een dag vroeg ik het mezelf."
          sanne: "Iemand stelde me steeds dezelfde vijf vragen. Irritant. Nu stel ik ze zelf."
        final_card_extra: "{insider_name} zat ook aan tafel. Je eerste vraag als directeur ging naar {hem_haar}, en {hij_zij} wist het antwoord."
```

**Ruud is silent in every ending.** In the main scene Ruud says one line per ending, the most he ever tells. Here he says nothing, whatever the move: the only time in the game the coach is silent when he could speak. He looks at the insider, then at the player. The player draws the conclusion, or does not; the game never says it (nothing handed over, no score). Without Ruud (`past:ruud_retirement`) the scene ends on Lotte's line.

**Later, in free play** (a one-line beat, no talk, 14 days after the finale, from the insider; never a reproach):
- Anouk: "Lotte belt me elke dinsdag. Over de tekeningen, zegt ze. Het gaat nooit over de tekeningen."
- Ahmed: "Lotte ging mee in de bus. Ze vroeg waarom ik de mof zo legde. Ik zei: goeie vraag."
- Sanne: "Lotte zit op dinsdag een uur bij ons aan de bak. Rachid legt het haar uit. Hij vindt het geweldig."

The insider coaches the newcomer anyway: the talent the player developed does the job without the title. That is the consequence, and it is kind.

**Schema needs** (adds to §10): the fact `passed_over:<id>` (S13); a scene variant whose `person` is a token, with `opening_by_insider`, `npc_by_insider`, a second speaker's line (`lotte`) per ending and one shared third speaker's line (`ruud`) (extends S10); `final_card_extra`; the one-line beat after the finale (S18). Tokens `{insider}`, `{insider_short}`, `{insider_name}`, `{hij_zij}`, `{hem_haar}`, `{Zij_Hij}` follow the insider's pronoun (Anouk, Sanne: zij/haar; Ahmed: hij/hem).

**The bookend in Act 0.** Lotte's position line, "Waar moet ik beginnen?", is the player's own first line to Ruud. A one-line beat is added to `training_mon` (the player speaks once, as a choice-free line): `{on: accepted, who: player, text: "Waar moet ik beginnen?"}` and Ruud: "Bij de klant. En dan loop je terug." A player who meets Lotte hears their own first question come back.

---

## 9. One human thread per act (Acts III–VI)

PLAN §4.2.2. Each act has a person or a customer whose life the act's KPI touches: met at the start, paid off at the end, and the act's cliffhanger device. Tier 1 has the El Amrani dossier. Below, each thread has its beats (who, when, and the line) and one short talk, in the dialog schema's short form (as in the tier-3 draft). Beats take no slot and open no problem; the talks are a customer call or a check-in, never a mission of their own.

| Act | Thread | Met | Paid off | KPI it touches | Reads |
|---|---|---|---|---|---|
| III | **The Zandbergen dairy farm.** At the end of a rural MS line north of Nova (some of it still overhead): a milking robot, 140 cows, and Daan (16), who phones the contact centre every hour when the power is out because his father is in the barn with a borrowed generator. | `fix_on_call_far`'s briefing (Esra's Monday calls) | the storm night (§7.4): Daan's call at 04:10 | outage duration; failure demand | `chose:on_call_far:*`, `storm_plan_information` |
| IV | **Samira El Amrani's bakery in Havenzij.** The El Amrani daughter opens an all-electric bakery in the old harbour and lands on the waiting list. Ilse de Graaf (Act II) sold her a dough mixer. | `fix_household_rush` or `fix_priority_first_come` | her honest date, and whether it holds | `waiting_list` (`date_kept`) | `winter_el_amrani`, `classify_at_intake`, `publicly_visible_queue` |
| V | **Ahmed's apprentice.** Sem (18), from Ahmed's first cohort (tier 3), does Theo's inspections. | `fix_maintenance_calendar` (Theo: "wie gaat dit doen als ik weg ben?") | the finale: Ahmed at the table, or Sem's postcard | first time right; fix health | `heard:ahmed_trainer`, `chose:training_capacity:*` |
| VI | **Ricardo's notebook.** Ricardo keeps a paper notebook because the app has no signal in the cellars of Nova-Oud. | `fix_field_app_bypassed` (the WhatsApp group) | `it_field_asset_data`: the joint captured at the source, or the notebook photographed into GIS | first time right at close-out; joint data | `committed:ricardo_whatsapp`, `release_gated` fixes |

### 9.1 Act III: the Zandbergen farm

**Grounding.** Dairy farms with milking robots depend on power; an outage of hours means cows that cannot be milked and milk that cannot be cooled, which is why many farms keep or borrow a generator (`estimate:` of the farm's size: 140 cows, a common size for a Dutch farm with two robots). The rural remnants of overhead lines are the tier-2 draft's storm grounding (**verify**).

**Beats:**
- `fix_on_call_far` accepted, Esra: "Elke storing in het noorden belt dezelfde jongen. Daan Zandbergen. Zestien. Hij belt elk uur, heel beleefd, en hij vraagt nooit om iemand anders dan ons."
- `fix_on_call_far` completed: Esra: "Daan belde vorige week niet. De storing duurde vijftig minuten. Hij stuurde een mail: 'Bedankt. De koeien ook.'" (only when the standby fix brought the northern outages under two hours; else: "Daan belde zes keer. De laatste keer zei hij alleen: 'Oké.'")
- The storm night (§7.4), 04:10, at the escalation board: the call is in the scene as an interjection by Esra (`needs: {all: [done:fix_on_call_far]}`): "Daan Zandbergen aan de lijn. Hij vraagt niet wanneer. Hij vraagt of we het weten."
- The act's end, a card from the farm in the kantine: with `storm_plan_information` chosen: "Jullie bericht zei 'vóór zes uur'. Het was kwart over vijf. Mijn vader heeft gehuild. Niet om de stroom. Daan." Otherwise: "We hebben het gered. Daan."

```yaml
dialogs:
  - id: daan_storm_call
    person: daan_zandbergen          # new, a customer (customer_upset), age 16
    kind: persuade
    mission: thread_zandbergen       # the thread's side mission (tier-2 draft §2.19), during the storm
    place: customer_contact.answer
    patience: 8
    # start: customer_upset 25 + 0 + 0 + 0 + 0 = 25; +15 with done:fix_on_call_far (he knows the voice)
    opening: "Goedenacht. Met Daan Zandbergen, van de boerderij aan de Noorderweg. Sorry dat ik weer bel."
    position: {text: "Ik wil alleen weten wanneer de stroom terugkomt. Mijn vader zegt dat ik niet moet bellen.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [paraphrase, empathy], text: "Het aggregaat is van de buurman. Die heeft hem morgenochtend zelf nodig. De robot kan niet melken zonder stroom. Honderdveertig koeien.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, empathy]
        lead_in: {text: "Ik vind het eng, eigenlijk.", tags: [feeling]}
        text: "Mijn vader staat sinds twee uur in de stal. Hij zegt niks. Als hij niks zegt, is het erg. Ik bel omdat ik niet weet wat ik anders moet doen."
        tags: [admission]
        unlocks: {facts: [heard:daan_storm]}
    proposals:
      - {id: a_time, addresses: [interest], label: "Een tijd noemen", say: "Voor zes uur is de stroom terug.", reply: "Zes uur. Ik zeg het tegen mijn vader.",
         promise: {kind: restore_time, source: storm_board_estimate}}
      - {id: what_we_know, addresses: [interest, concern], label: "Zeggen wat we weten, en wanneer we terugbellen", say: "Ik zeg je wat we weten: de ploeg is onderweg naar jullie kabel. Om vijf uur bel ik je terug, ook als ik nog niks nieuws heb. Jij hoeft niet meer te bellen.",
         reply: "Ook als er niks nieuws is? … Oké. Dan ga ik mijn vader koffie brengen."}
    outcomes:
      commitment: "Om vijf uur. Ik zet mijn wekker. Niet dat ik slaap."
      partial: "Oké. Ik bel over een uur weer. Sorry."
      heard: "Fijn dat u het vroeg. Van mijn vader."
      compliance: "Oké. Ik zal niet meer bellen."
      ruined: "Laat maar. Ik bel wel als het licht weer aan is."
    # route: empathy +9 (x1.5) 34 > paraphrase +10 44 (heard) > empathy (x0.5) 49 (interest) > reflect +10 59 > ... (+15 start with history)
    # the temptation is a_time: it calms him now and is checked against the event's real restore time (the promise).
```

### 9.2 Act IV: Samira's bakery

**Grounding.** Since 1 July 2026 small businesses and households in congestion areas queue together for a heavier connection, with a transition period until 1 January 2027 (tier-3 draft §0.2). An all-electric bakery needs more than a household connection (`estimate:` three electric deck ovens at roughly 15–20 kW each, so above 3x80A).

**Beats:**
- `fix_household_rush` (or `fix_priority_first_come`) accepted, Sanne: "Er staat een El Amrani op de lijst. Samira. Een bakkerij in de Oude Haven. Familie van?" With `flag:el_amrani_cold_winter`: Esra adds "Haar moeder belde. Ze zei: dit jaar wil ik niet weer bij mijn dochter logeren. Ik wil in de bakkerij staan."
- Ilse de Graaf (Act II), at the `sector_energy_hub` talk or a beat: "Ik heb haar mijn oude deegmachine verkocht. Elektrisch. Die van mij was gas."
- The act's end: if Samira was given a date and it held, a box of bread at the contact centre, with a card for Esra's agents; if it broke, Samira's line on the terugblik: "U zei maart. Het werd juni. Ik heb drie maanden huur betaald voor een bakkerij zonder oven." Both read `date_kept` for her order (a second followed order, `story: samira`).

```yaml
dialogs:
  - id: samira_waiting_list
    person: samira_el_amrani          # new, a customer (customer_upset), the El Amrani daughter, 27
    kind: persuade
    mission: thread_samira           # the thread's side mission (tier-3 draft §1.13)
    place: customer_contact.answer
    patience: 10
    # start: customer_upset 25 + memory of the family: +10 with delivered:el_amrani or agreed:el_amrani_fourth_call:check_existing_connection; -10 with a broken promise
    opening: "Goedemiddag, Samira El Amrani. U kent mijn moeder, denk ik. Zij heeft alles opgeschreven. Ik heb een spreadsheet."
    position: {text: "Ik sta op de wachtlijst voor een zwaardere aansluiting. De huur loopt al. Ik wil weten waar ik sta. Plek en datum.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [paraphrase, empathy], text: "Ik heb de bakkerij gekocht omdat hij elektrisch kon. Geen gas, nooit meer. Dat heb ik van mijn moeder geleerd, die winter.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [empathy, reflect, silence]
        lead_in: {text: "En weet u…", tags: [hesitation]}
        text: "Iedereen in de straat zegt: zet er toch een gasoven in, dan kun je morgen open. Ik heb een lening voor elektrische ovens. Als ik nu toch gas neem, heb ik twintig jaar gas. En dan heb ik mijn moeder niks geleerd."
        tags: [admission]
        unlocks: {facts: [heard:samira_gas], proposals: [phased_opening]}
    proposals:
      - {id: a_date, addresses: [interest], label: "Een datum noemen", say: "Ik zie hier {promise_date}.", reply: "Ik zet het in mijn spreadsheet.",
         promise: {kind: delivery_date, source: planning_estimate}}
      - {id: place_and_honest_window, addresses: [interest], label: "Haar plek en een eerlijk venster", say: "Uw plek is {queue_place}. Ik geef u een venster, geen datum, en ik bel u zodra het venster kleiner wordt.", reply: "Een venster. Dat is eerlijker dan mijn moeder kreeg."}
      - {id: phased_opening, hidden: true, addresses: [concern], label: "Eerst open met wat er nu kan", say: "Wat als u eerst opent met één oven op de aansluiting die er is, en de rest aansluit zodra de verzwaring er is? Dan bent u open zonder gas.", reply: "Eén oven. Croissants en brood, geen taarten. … Dat kan. Dan ben ik open, en elektrisch."}
    outcomes:
      commitment: "Eén oven, geen gas, en een venster. Ik zet het in mijn spreadsheet. Mijn moeder zet het in haar schrift."
      partial: "Ik wacht af. Maar als het venster niet kleiner wordt, hoort u van mij."
      heard: "Dank u. U luisterde net als die keer bij mijn moeder."
      compliance: "Goed. Ik wacht. Wat moet ik anders."
      ruined: "Dan neem ik toch een gasoven. Dan bent u mij twintig jaar kwijt."
    # path: the ruined line is the lock-in lesson of Ilse (Act II) repeated by the next generation; a_date is checked (date_kept).
```

### 9.3 Act V: Ahmed's apprentice

**Beats** (only with `heard:ahmed_trainer`, or a saved Henk, and `chose:training_capacity:train_the_trainer` or `apprentice_cohort_september`):
- `fix_maintenance_calendar` accepted, Theo: "Wie gaat dit doen als ik weg ben? Die jongens van Bouzid? Die weten niet eens hoe een station ruikt."
- A week into the risk-based inspections, Theo: "Die Sem van Ahmed. Stond vanochtend in de Merelstraat en zei: 'Ruikt naar was.' Ik heb niks gezegd. Hij had gelijk."
- D47 *De mof van 1978* names Sem in its card when the replaced joint was on his inspection list.
- The finale: if Ahmed is the successor, Sem is the one who knocks during the last scene ("Ahmed, de bus staat klaar."); otherwise Sem's postcard arrives on Ruud's last day: a photo of a joint, "Van Henk geleerd, via Ahmed."

```yaml
dialogs:
  - id: sem_first_station
    person: sem                       # new, aankomend monteur (quiet), 18
    kind: checkin
    trigger: {beat: theo_sem_wax, after_days: 7}
    patience: 8
    # start: quiet 47 + 10 (goed) + 0 + 0 + 0 = 57
    opening: "O. Hoi. Ik ben Sem. Van Ahmed."
    position: {text: "Het gaat goed. Theo is streng. Maar goed.", tags: [claim]}
    layers:
      - {id: interest, at: 60, via: [open_question, mood, silence], text: "Ahmed zegt: eerst ruiken, dan meten, dan pas denken. Ik dacht dat hij een grapje maakte.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "Alleen…", tags: [hesitation]}
        text: "Theo zegt dat hij over twee jaar stopt. Dan ben ik twintig. En dan sta ik daar. Met de Merelstraat."
        tags: [admission, doubt]
        unlocks: {facts: [heard:sem_future]}
    outcomes:
      lifted: "Ahmed was ook twintig, toen Henk stopte. Dat zei hij. Ik had het nooit uitgerekend."
      heard: "Oké. Dank je."
      none: "Ik moet naar Theo."
```

### 9.4 Act VI: Ricardo's notebook

**Beats:**
- `fix_field_app_bypassed` accepted: Ricardo shows a paper notebook with a rubber band: "Dit is de echte database. Kelders in Nova-Oud: geen bereik. Ik schrijf het op en tik het 's avonds over. Soms."
- `fix_field_app_bypassed` completed with `committed:ricardo_whatsapp`: "Het boekje blijft in de bus. Voor de kelders. Maar de app werkt nu ook zonder bereik. Dat had niemand gevraagd, behalve wij."
- `it_field_asset_data` accepted, Mieke: "In Ricardo's boekje staan zeventig moffen die nergens anders staan. Ik heb het gezien. Hij laat het niet uit zijn handen."
- The payoff, at `it_field_asset_data`'s debrief: with `joint_capture_in_app` live (the release came): "Ricardo heeft het boekje aan Mieke gegeven. 'Voor het archief,' zei hij. Het staat nu in GIS. Alles." With `photo_to_gis_check` only: "Mieke fotografeert elke maandag de nieuwe pagina's van Ricardo's boekje. Het werkt. Het is niet hoe het hoort."

```yaml
dialogs:
  - id: ricardo_notebook
    person: ricardo
    kind: checkin
    trigger: {beat: it_field_asset_data_accepted, after_days: 3}
    patience: 8
    # start: cynic 30 + 0 + 10 (team trust monteurs +1 after the field-app fix) + ... ; +15 with committed:ricardo_whatsapp
    opening: "Als je voor het boekje komt: dat gaat niet weg."
    position: {text: "Het boekje is van mij. Daar staan dingen in die nergens staan.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [paraphrase, inquiry], text: "Elke mof die ik in een kelder vond die niet op de tekening stond. Zeven jaar. Met de datum en wat ik deed.", tags: [claim]}
      - id: concern
        at: 68
        via: [reflect, empathy]
        lead_in: {text: "Ik word er een beetje raar van, eerlijk gezegd.", tags: [feeling]}
        text: "Als het in GIS staat, is het van iedereen. Dan is het boekje niks meer. Dan ben ik gewoon weer een monteur die het formulier invult."
        tags: [admission]
        unlocks: {facts: [heard:ricardo_notebook]}
    outcomes:
      lifted: "Weet je wat. Ik geef het aan Mieke. Niet aan IT. Aan Mieke. Zij weet wat het is."
      heard: "Je vroeg wat erin stond. Niet hoe je het eruit krijgt. Dat is wat."
      none: "Ik moet de kelder in."
    sets_flags_on_lifted: [flag:notebook_to_mieke]   # it_field_asset_data's debrief and D39's card read it
```

New people for `people.yaml`: `daan_zandbergen` (customer_upset, 16), `samira_el_amrani` (customer_upset, 27), `sem` (quiet, 18). Names checked against every earlier doc: no collisions.

**As missions (2026-10-16):** each thread is a small side mission in its tier draft, with a face, a number, a choice (a temptation with a later cost) and a payoff at the act's end: `thread_zandbergen` (tier-2 draft §2.19), `thread_samira` (tier-3 draft §1.13), `thread_sem` with the talk `theo_sem_pairing` (tier-4 draft §1.11), `thread_notebook` (tier-4 draft §2.6). Schema needs beyond §10: `opens_on: {beat}`, `requires_accepted` (a side that opens when a main is accepted), `followed_order` on a mission (a second followed order), `talk_to` with `outcome: lifted` for a check-in, beats `on: act_end`, `effects_during_event` and `person_trust` in a temptation's effects.

---

## 10. Schema needs for the builder

| # | Need | Where | Why |
|---|---|---|---|
| S1 | `opens_on: {season: winter \| storm \| summer}` with the seasons of §1; `{day_before: <beat>, days: n}` | missions | the winters; the storm season (KNMI: October–March); the finale six weeks before Ruud's date |
| S2 | `deadline_on_day` read from a dated **beat** (`ruud_retirement`), and dated beats with a rule (`first 1 April ≥ 240 days after act 5 opens`) | missions, beats | Ruud's last date |
| S3 | Coach cooldown: `ask_coach` returns `on_call_cooldown {next_day}` while `flag:ruud_seconded` and not `flag:ruud_back`; one call = one Kata cycle (`coach_calls` in content, §6); side and no-main asks do not count | `Missions.ask_coach`, `content/coach_calls.yaml` (new) | PLAN §4.0 item 4 |
| S4 | `north_star` block in `kpis.yaml` (§2): `open_count`, `mean_wip_age_weeks`, `share_delivered_by_promised_date`; promises recorded per order | `kpis.yaml`, `Region`, HUD | the waiting list |
| S5 | **Group talk** (`kind: group`): `chair`, `members`, `quiet`, the room meter, `target` on every move, `interjections` (`band` / `after_move` / `needs`), `disengage`, `clock`, `retry_after_days`, `sets_flags_on_outcome`; the quiet-layer ceiling (§5.1) | dialog engine, `dialogs.yaml`, UI (one bar labelled *De kamer*, faces, a spoken dot) | PLAN §4.3.2; the interim MT, the storm board, catchball, dagstart |
| S6 | `variants` on a dialog with their own `opening`/`position`/`layers`/`proposals`/`outcomes` and `needs` (extends spec §9.1's `variants`) | `dialogs.yaml` | sponsor / regime |
| S7 | Archetype `mentor` (base 55; `experience` ×1.5; `show_data` ×0.5) | `dialog_archetypes` | Ruud as a dialog target (two talks only) |
| S8 | `sets_flags_on_end` (check-ins), `sets_flags_on_choice`, `sets_flags_on_fail` (missions) | dialogs, missions | the secondment, the successor, the cold winter |
| S9 | Kind `finale`: no slot, cannot fail or be abandoned; goal `sequence` of steps; `talk_to` with a templated dialog id (`successor_{chosen}`) | missions | `de_opvolger` |
| S10 | Kind `coach_call` (§6) and kind `scene` with `moves: one` and `endings` keyed on move (§8.5); the five Kata questions as chips in the scene | dialog engine | the call; the last scene |
| S11 | A dialog available from several missions: `missions: [fix_status_callers, winter_el_amrani]` (the first active one counts) | `dialogs.yaml`, validator rule 4 | the El Amrani call before the frost |
| S12 | Goal `story_order {story, by, met_if}` reading `delivered:<story>` and `agreed:<dialog>:<proposal>` | missions, the followed order (WIP patch) | winter 1 |
| S13 | Facts: `lifted:<dialog>` (a check-in's opgebeurd), `team_led:t3_kaizen_week` (the kaizen week completed without `flag:kaizen_by_consultants`), `successor:<id>`, `past:<beat>`, `delivered:<story>` | C19 fact set | §8.3, §7.3 |
| S14 | `buy_in_override: compliance` while a flag is set (`flag:lean_programme_2`), applied at the Act | `GameSession.act`, sustain | the consultancy's ownership cost |
| S15 | Temptations with `needs`, `decline_effects`, `decline_line`, `person_trust`; a temptation pre-accepted by a flag (the blitz under the programme) | missions | `t3_consultants`; the kaizen week |
| S16 | `briefing_variants` keyed on flags (not only debrief variants) | missions | Act IV openings |
| S17 | `requires.facts` on a recurring mission's *first* occurrence only (`first_requires`) | missions | the storm waits for Ruud once |
| S18 | A one-line player beat (`who: player`) | beats | "Waar moet ik beginnen?" |

The validator rules that follow:
- a group talk has exactly one `quiet` member, who has no interjections;
- every group talk reaches `partial` without the quiet one, and no sequence reaches `commitment` without them (content test);
- a `finale` has no `deadline_days`, `fail` or `fail_*`;
- every successor variant's `needs` keeps one branch that no failure can close (Lotte has none, so a successor always exists);
- `ruud_call` questions name only state the rules can fill.

---

## 11. Open questions, decided by the standing rule

Merijn's standing rule (PLAN §6.2): each takes its recommended option, **bold**; logged in PLAN §10 so he can overrule.

1. **The first frost date.** **(a) Day 70, 21 December 2026, as "the first frost period", marked as an estimate (§1).** (b) The national average first frost (21 October), which falls before the El Amrani call can happen. (c) No date; judged at the end of Act I. *(a) keeps a real winter test and a fair window; (b) is correct for a single frost night, but no family is cold after one night.*
2. **How the El Amrani call reaches a slow player.** **(a) The milestone opens the call on day 49 if `fix_status_callers` is not active yet.** (b) Only through the mission. *(a) keeps the milestone fair; the call is the customer's own initiative.*
3. **Who picks the successor.** **(a) The player chooses among the candidates the play qualified, and Lotte is always offered.** (b) The game picks the best-qualified. (c) Always one fixed order of preference. *(a) is a real choice about people, which is the finale's subject.*
4. **The regime's way back.** **(a) A team-led kaizen week with Frank's agreement (`frank_interim`), which clears the programme and eases the regime.** (b) The regime lasts until Ruud returns, whatever the player does. *(a) honours "recovery is always possible"; (b) makes the year feel like a sentence.*
5. **The storm without Ruud.** **(a) The first storm waits for the secondment (`first_requires`), in the storm season October–March.** (b) The storm opens in winter as drafted, with or without Ruud. *(a) is the arc; (b) loses the test for fast or slow players.*
6. **After the finale.** **(a) Free play continues: sustain, drift, repairs and seasons go on; Ruud sends postcards.** (b) The game ends with credits. *(a) respects a player who wants to keep their region; nothing is lost by stopping.*
7. **Ruud as a dialog target.** **(a) Only in the farewell and the successor choice, both unruinable; never a persuasion.** (b) Never; the farewell as a cutscene. *(a) lets the player give back what the coach gave: listening.*
8. **The secondment's place.** **(a) Den Haag, the Landelijk Actieprogramma Netcongestie (a real public programme of the Rijk, the grid operators, the ACM, the provinces and municipalities and market parties, since December 2022; described as such in `ruud_farewell`, §4.2), with Ruud and everyone he meets there fictional.** (b) A fictional national programme. *(a) grounds the waiting list in the real sector; no real person or organisation is impersonated.*
9. **`t3_interim_mt` as a short main.** **(a) Yes: one talk, the Act IV opener, no insights.** (b) A beat without a mission. *(a) makes the variant the player's work, not a cutscene.*

---

## Sources

- KNMI on storm seasons: "Storm kan in ons land het hele jaar door voorkomen, maar de kans op een flinke storm … is het grootst in de periode oktober tot en met maart" — KNMI, *Herfststormen*, https://www.knmi.nl/over-het-knmi/nieuws/herfststormen (search extract; **verify**).
- First frost: national average 21 October (1991–2020) versus 15 October (1961–1990); De Bilt about 2–3 November (older figures) — Hart van Nederland, *Eerste vorst van het jaar*, https://www.hartvannederland.nl/weer/weerbericht/artikelen/eerste-vorst-van-het-jaar-en-warme-dagen-op-komst; Weerplaza, https://www.weerplaza.nl/weerinhetnieuws/eerste-vorst-van-het-seizoen-in-de-bilt/6703/ (search extracts; **verify** against the KNMI climate tables).
- Waiting list: "ruim 15.000 aanvragen voor afnamecapaciteit" at regional operators, mid-2026 — *Actualisatie van de voortgang LAN najaar 2026* (Kamerbrief annex), https://omgevingsweb.nl/wp-content/uploads/2026/10/108251533-Bijlage-Actualisatie-van-de-voortgang-LAN-najaar-2026.pdf; Solar Magazine on the feed-in queue (8,558 requests, end of June 2026), https://solarmagazine.nl/nieuws-zonne-energie/i44990/wachtlijst-teruglevering-bij-regionale-netbeheerders-krimpt-licht-maar-gevraagd-vermogen-stijgt-13-procent (search extracts; **verify**).
- Landelijk Actieprogramma Netcongestie: set on 21 December 2022; Kamerbrief *Landelijk Actieprogramma Netcongestie*, minister voor Klimaat en Energie, 20 December 2022, Kamerstuk 29 023 nr. 385, https://zoek.officielebekendmakingen.nl/kst-29023-385.pdf ("gezamenlijk opgesteld door netbeheerders, ACM, medeoverheden, het Rijk en marktpartijen"; the ministry's decision note of 5 December 2022 in the same words); the programme text, https://www.energie-nederland.nl/wp-content/uploads/2023/06/Landelijk-Actieprogramma-Netcongestie.pdf; the lines *Beter benutten*, *Sneller bouwen*, *Slimmer inzicht* as named in the 2026 progress letters (search extracts; **verify** the line names against the latest letter).
- Households on the waiting list from 1 July 2026: KHN, https://khn.nl/nieuws/netcongestie-vanaf-1-juli-2026-ook-kleinverbruikers-op-de-wachtlijst (as cited in the Acts 0–II scripts).
- AOW age 67 years and 3 months for 2029 and 2030 — Kamerbrief *Vaststelling AOW-leeftijd 2030* (8 November 2024), https://awvn.nl/app/uploads/2024/11/Kamerbrief-vaststelling-AOW-leeftijd-2030-en-pensioenrichtleeftijd-2026.pdf; Rijksoverheid, https://www.rijksoverheid.nl/onderwerpen/algemene-ouderdomswet-aow/aow-leeftijd.
- Kata coaching: Rother, M. (2009), *Toyota Kata* (the five questions and the reflection block).
- Consultant-led change and ownership: Kotter & Schlesinger (1979); Senge (1990); the dialog spec §12.
