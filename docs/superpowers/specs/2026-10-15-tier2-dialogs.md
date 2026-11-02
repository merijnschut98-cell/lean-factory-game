# Tier-2 missions reviewed with dialogs (the end of Act II and Act III)

> Status: by the mission and dialog design agent (Claude, 2026-10-15), for Merijn to review. **Docs only.** This reviews `2026-10-15-tier2-missions-draft.md` against the dialog design, and adds the dialogs its missions need. It does not edit the draft: where the draft should change, a finding says so, and the builder applies it when the draft goes into `content/`.
>
> Read with:
> - the tier-2 draft;
> - the dialog spec (`2026-10-15-dialog-system-design.md`, the engine and schema);
> - the Acts 0–II dialog scripts (`2026-10-15-dialog-scripts-act0-2.md`): the voice sheet (§2), the schema additions (§1.1) and the engine clarifications R-D1–R-D5, which this doc uses unchanged;
> - the audit's cast (§5.3).

## 0. Summary

- **Review (§1).** The tier-2 draft is strong on mechanics, grounding and temptations. As a story it has **ten gaps**, four of them cast collisions:
  - "De Lindehof" duplicates the audit's care home De Linde;
  - "Erik Smits of Grondwerk Zuid" replaces Gert Peeters, the contractor the player already met in Act II;
  - an on-call monteur called Ilse collides with Ilse the baker;
  - Kees pushes *both* branches of the outage fork, so the fork's choice is not between two people.

  Six more:
  - temptations voiced by faceless roles ("it_manager", "magazijn", "monteur");
  - no dialog where a mission's resistance is a person;
  - the coaching script for Sanne is not written;
  - the ACM visit has no face from the ACM;
  - the experts lack openings in their voice;
  - no facts from Act III's people reach tier 3.

  Each finding has a fix.
- **Dialogs (§3–§5)** in the dialog spec's schema, in standard Dutch, with the voice sheet: 17 talks (15 persuasion talks, a customer call with mevrouw Brouwer, the ACM inspector at the milestone), 3 short walk-around check-ins (§3.9: Wendy, Koen, Ruben), Sanne's coaching script, and openings and closings for the two expert talks (Thomas, Jeroen).
- **Path dependence through people.** Ten dialogs start higher when the player earned that person's commitment in Acts I–II: Frank, Joost, Gert, Marco, Dirk, Petra, Femke, Linda, Sanne, Ruben. Several set facts tier 3 reads, e.g. Marco's "betaald uur om op te leiden" makes `train_the_trainer` cheaper in Act IV (§6).
- **Every mission is accounted for (§1.2):** which dialog it needs, or why it needs none (the OKR, the KPI review routine, the recovery mission).
- **7 design calls (§8), decided** by Merijn's standing rule (the recommended option), logged for him to overrule.

---

## 1. Review of the tier-2 draft against the dialog design

### 1.1 Findings

| # | Finding | Where | Fix |
|---|---|---|---|
| T1 | **Two care homes with nearly the same name.** The audit's Zorgcentrum De Linde (manager mevrouw Brouwer) runs on its generator after the Act II cable strike. The tier-2 draft's `fix_cause_unknown` invents "De Lindehof" with three outages. | `fix_cause_unknown` briefing | **Use De Linde.** The third outage in a year *at the same care home* is a callback the player feels ("Weer De Linde?"), and mevrouw Brouwer gets a voice (§3.3). |
| T2 | **The contractor is a stranger.** The audit planned Gert Peeters' callback in `fix_contractor_rework` ("a partner, not a culprit"). The draft introduces Erik Smits of Grondwerk Zuid instead; Dirk *Smits* already exists. | `fix_contractor_rework`, cast | **Use Gert Peeters of Grondwerk Peeters.** His Act II outcome (`gert_klic`) becomes his start here: a player who won his trust in the cable strike meets a partner, one who blamed him meets a wall (§3.6). |
| T3 | **A name collision.** "Ruben en Ilse" (the on-call monteurs) against Ilse de Graaf, the baker of Act II. | `fix_on_call_far` temptation | Rename the monteur to **Inge**. Ruben stays. |
| T4 | **The fork is one person's.** The B briefing has Kees *and* Esra asking; the N briefing is Kees's "grootste ergernis". The audit's fork rule is two people, each with a true number, neither naming the queue. | `fix_on_call_far`, `fix_shift_handover` | B is **Esra's**: her number is the night complaints and compensations ("Elke maandag tien boze klanten uit de dorpen ten noorden van Nova"). N stays **Kees's**. Proposed B briefing in §1.3. |
| T5 | **Temptations from faceless roles.** "it_manager", "magazijn", "monteur", "inkoop", "mt_member" offer the shortcuts. A shortcut from a face is more tempting and more honest: people offer shortcuts for reasons. | five missions | Where a named person fits, use them: *magazijn* → Dirk; *monteur* (dig anyway) → Ruben; *mt_member* (output KR) → Frank. The IT manager and Inkoop stay roles (they are the organisation's voice, not a colleague you coach). |
| T6 | **No dialog where the resistance is a person.** Nine missions name a person who resists (Joost's board, the monteur's "onbekend", Inge's standplaats, the operators' handover, Marco and Gert, Netstrategie's 24 hours, Dirk's double stock, the LMRA owner, the planner's KLIC), and none has a dialog. | nine missions | §3: one dialog each. |
| T7 | **Sanne's coaching has no script.** `coach_intake_lead` is a `coach` goal (catalogue C7) with five questions in order. The draft has its briefing but not Sanne's answers. | `coach_intake_lead` | §4: three sessions, Sanne's answers growing, in the format of the tier-3 Joost script. |
| T8 | **The ACM visit has no face from the ACM.** It is judged by a number (a milestone), but the visit itself is a conversation the player has prepared for ten weeks. | `acm_visit` | §3.7: `acm_inspector`, a persuasion talk with a regulator. It does not change the milestone's measure; it changes how the verdict is written and what the recovery mission asks. |
| T9 | **Experts without a voice.** Thomas's and Jeroen's topics (draft §4) are good, but they are only topics. | `sector_congestion_map`, `talk_regulation` | §5: an opening and a closing line in their voice. The topics stay as written. |
| T10 | **Act III's people leave no trace in tier 3.** Tier 3 reads many Act I–II facts, but none from Act III's people. | the facts | §6: Act III's dialogs set facts that tier 3 and tier 4 read (Marco's training hour, Ruben's rest rule, Gert's trust for one-dig agreements, Petra's station query for the household rush). |

### 1.2 Every tier-2 mission: the dialog it needs

| Mission | Dialog | Why (or why none) |
|---|---|---|
| `first_kpi_review` (M) | `frank_red_numbers` | Frank, now committed to new KPIs, fears the red reinforcement number before the directie. The watermelon temptation gets a person on the other side. |
| `sector_congestion_map` (S) | `thomas_congestion_map` (expert) | Voice only (§5). |
| `t2_daily_boards` (M) | `joost_board` | Joost's "weer een bord" hides a story: the abandoned 2023 board was his. |
| `fix_cause_unknown` (M) | `ruben_cause`, `brouwer_third_outage` (customer) | The monteur behind "onbekend"; the care home's manager. |
| `fix_on_call_far` (M, B) | `inge_standby` | The standplaats is her home, and her children. |
| `fix_shift_handover` (M, N) | `wendy_handover` | A senior operator who fears that a form turns the control room into a counter. |
| `fix_contractor_rework` (M) | `gert_contractor`, `marco_contractor` | Two people who are both right; one dialog each. |
| `fix_escalation_hallway` (M) | `koen_24h` | The 24-hour rule lands on a junior analyst who is afraid to answer wrong. |
| `acm_visit` (Ms) | `acm_inspector` | T8. No coach (a milestone). |
| `acm_improvement_plan` (S, recovery) | none; the inspector's variant | The same inspector, a variant line set (§3.7). |
| `t2_first_okr` (M) | none | The OKR is the player's choice from a menu, with Ruud's beats. A persuasion would duplicate `frank_red_numbers`; Frank's commitment there carries over (his beat). |
| `fix_safety_stock_calendar` (S) | `dirk_reorder` | The double-stock temptation is Dirk's, and so is the sheet he does not understand. |
| `fix_lmra_tickbox` (S, safety) | `nicole_lmra` | The safety advisor who added the 42 questions, one per incident. |
| `prep_storm_week` (S, strategy) | `ruben_storm` | The all-hands option has a face: the monteur who nearly drove into a ditch. |
| `fix_heatwave_overload` (S) | `petra_station_data` | The station data sits with Petra, who is careful with personal data and tired of being the only one. |
| `talk_regulation` (S) | `jeroen_regulation` (expert) | Voice only (§5). |
| `coach_intake_lead` (S, coach) | the coaching script | T7 (§4). |
| `lsw_kpi_review` (R) | none | A routine; its people are the team leads at the board, through beats. |
| `repair_escalation_hallway` (S) | `joost_board` variant | Joost with the repair memory: "We trekken aan het koord, maar er komt niemand." |
| `fix_stale_capacity_map` (S) | `femke_map` | The "zet alles op rood" temptation is Femke's own, for a reason. |
| `fix_monteur_hours` (S) | `marco_overtime` | Marco's overtime temptation is his monteurs' mortgage. |
| `fix_klic_expired` (S) | `linda_klic` | A new task for Planning, with legal weight. |

### 1.3 Proposed text changes for the draft (T1–T5)

- **`fix_cause_unknown` briefing (T1):** "Mevrouw Brouwer van zorgcentrum De Linde heeft Ruud een brief gestuurd: drie keer stroomuitval in een halfjaar, de laatste keer twee uur in het donker met bewoners aan de zuurstof. Het is hetzelfde zorgcentrum dat vorig jaar op het noodaggregaat draaide na de graafschade. Volgens het storingssysteem was de oorzaak drie keer 'onbekend'. Ruud wil voor de volgende storing weten waarom het steeds dezelfde straten treft."
- **`fix_contractor_rework` (T2):** replace "Erik Smits, de uitvoerder van Grondwerk Zuid" with "Gert Peeters van Grondwerk Peeters", and the beats' `who: erik` with `who: gert`. The draft's people list drops `erik`.
- **`fix_on_call_far` temptation (T3):** "Ruben en Inge draaien er elk twee consignatieweekenden per maand bij."
- **`fix_on_call_far` briefing (T4):** "Esra Yilmaz heeft elke maandag dezelfde gesprekken: klanten uit de dorpen ten noorden van Nova die 's nachts urenlang zonder stroom zaten. Vorige maand duurde bijna een op de vier nachtelijke storingen langer dan vier uur, en elke getroffen klant krijgt dan een vergoeding. 'Mijn mensen leggen elke week uit waarom het in het noorden zo lang duurt. Ik weet het zelf niet.'"
- **Temptation voices (T5):**
  - `fix_safety_stock_calendar`: `who: magazijn` → `who: dirk`;
  - `fix_klic_expired`: `who: monteur` → `who: ruben`;
  - `t2_first_okr`: `who: mt_member` → `who: frank`.

---

## 2. Voice sheet additions

The Acts 0–II voice sheet (§2 there, revised to standard Dutch on 2026-10-15) holds for Frank, Joost, Sanne, Marco, Esra, Petra, Femke, Linda, Dirk, Gert, Thomas. Everyone speaks standard Dutch (decided: no dialect); voices differ in word choice, rhythm, humour and worry. New for Act III:

| id | Who (age) | Voice | Humour | Worry (hidden) | Recurring line |
|---|---|---|---|---|---|
| `kees` | Kees Mulder (49), operator Bedrijfsvoeringscentrum | Calm night voice, few words, control-room terms: "videowand", "schakelen", "melding". | "'s Nachts is de wand het enige wat licht geeft." | That the control room only ever sees the light come back, never why it went. | "Ons werk stopt als het licht weer brandt." |
| `ruben` | Ruben Smulders (31), consignatiemonteur | Quick, a young father, half-sentences: "even", "toch?", "snap je". | Jokes about sleep: "Ik slaap in blokjes van drie uur, net als de baby." | Being blamed for a cause he wrote down in good faith; driving tired. | "Onbekend is één klik." |
| `inge` | Inge van Gils (39), consignatiemonteur | Direct, practical, says what she means in one sentence. | Dry: "Mijn standplaats heeft een wasmachine." | Her two children at night if she must wait elsewhere. | "Mijn standplaats is mijn huis." |
| `wendy` | Wendy de Bruijn (55), senior operator | Experienced, story-teller, warm but firm: "onderbuik", "zo doen we dat". | "Achtentwintig jaar wisseldiensten. Mijn lichaam weet niet meer welke dag het is." | That a form says the operators couldn't do it, and turns young operators into box-tickers. | "Een overdracht is een verhaal." |
| `koen` | Koen Dijkstra (28), netanalist Netstrategie | Precise, nervous, careful: "zeker weten", "eigenlijk". | Self-mocking: "Femke weet het. Ik reken het na." | Answering fast and wrong, two years into the job. | "Ik wil het eerst zeker weten." |
| `nicole` | Nicole Verbruggen (50), veiligheidskundige | Rule-bound with a heart: "veiligheidsladder", "incident", "borgen". | — | The monteur she visited in hospital in 2019; deleting the one question that would have mattered. | "Elke vraag staat er om een reden." |
| `brouwer` | mevrouw Annet Brouwer (58), manager zorgcentrum De Linde | Polite, tired, factual about care: "bewoners", "zuurstof", "kamer twaalf". | — | Mevrouw Jansen in room 12, on oxygen; the next windy night. | "Weer De Linde." |
| `van_dalen` | mevrouw Lydia van Dalen (45), toezichthouder ACM | Formal "u", calm, legal precision: "vanaf de aanvraag", "narekenen", "besluit". | — | A decision built on numbers that turn out false, again. | "Ik wil uw eigen cijfers zien." |

---
## 3. The dialogs, in mission order

The schema is the dialog spec's §9.1 with the Acts 0–II additions (`label`/`say`, `reframe`, `warning`, `lines.<move>.lands`, `beats_after`). The short form is as in the tier-3 draft.

Each dialog's **start** comment gives the default and, where it matters, the start after the player's earlier history with that person. The **route** comment gives one listening route with openness after each move (R-D1 order: Δ, cap, reveal; the lead-in turn). Other routes and the trap are noted where they teach something.

### 3.1 `first_kpi_review` — Frank and the red number

```yaml
dialogs:
  - id: frank_red_numbers
    person: frank
    kind: persuade
    mission: first_kpi_review
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    #   after committed:frank_kpi_targets (Act II): 35 + 2 (trust 60) + 15 (memory) = 52, Luistert
    opening: "Over twee weken het MT. Ik heb het bord bekeken. Daar moeten we het even over hebben, voordat jij daar gaat staan."
    position: {text: "Wat rood is, bespreken we eerst intern. Op het bord voor het MT staat wat we verbeterd hebben.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, paraphrase], text: "De directie leest dat bord als een rapport. Een rood getal is een vraag die ik moet beantwoorden, en ik heb het antwoord nog niet.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, paraphrase]   # 2026-10-16 (1.6c, route variety): facts; he opens to a precise question or his own words back, not to a pause
        lead_in: {text: "En dat ene getal… Dat is gewoon een getal. Dat ga ik niet wegpraten.", tags: [hesitation, claim], tell: facts}
        text: "De doorlooptijd van de netverzwaringen. Die gaat niet over Werkvoorbereiding of de Intake. Die gaat over mij. Als die rood op het bord staat, zegt de directie: Hulshof heeft zijn verzwaringen niet op orde. Vlak voor de budgetronde."
        tags: [admission]
        unlocks: {facts: [heard:frank_red], proposals: [frank_explains_first]}
    reframe: "Vanuit de directie? Die ziet liever een rood getal met een plan dan een groen getal dat volgend kwartaal omvalt. … Dat zei mijn eerste baas ook altijd."
    warning: "Ik heb hier niet de hele middag voor."
    proposals:
      - {id: leave_it_out, addresses: [interest], label: "De netverzwaringen weglaten", say: "We laten de netverzwaringen dit kwartaal weg.", reply: "Dat zou het makkelijkst zijn. Ja."}
      - {id: red_with_plan, addresses: [concern], label: "Rood laten zien, met een plan ernaast", say: "We laten het rood zien, met ernaast wat we ervan leren en wat we volgend kwartaal proberen. Dan is het geen rapport, maar een plan.", reply: "Een plan naast het rood. Dat is iets anders dan een gat in het rapport."}
      - {id: frank_explains_first, hidden: true, addresses: [concern], label: "Frank licht het rood zelf toe", say: "Wat als jij het rode getal zelf toelicht, voordat iemand ernaar vraagt?", reply: "Zelf. Eerst. Dan is het mijn verhaal en niet hun vraag."}
    co_proposal: {id: frank_explains_first, text: "Als ik het zelf aankaart, met de oorzaak erbij, dan sta ik sterker dan als ze het me vragen."}
    outcomes:
      commitment: "Goed. Het rood blijft staan. Ik licht het zelf toe. En jij zorgt dat dat plan ernaast klopt."
      partial: "Als het plan er echt naast staat, wil ik het wel."
      heard: "Hm. Ik ga erover nadenken. Dat zeg ik niet vaak."
      compliance: "Laat het staan. Op jouw verantwoording."
      ruined: "Ik bepaal wat er op mijn bord staat. Niet de nieuwe CI-lead."
    # route (start 35): open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > empathy +6 62 > inquiry +8 70
    #        > perspective +8 78 (reframe; lead-in, cue) > inquiry ("Welk getal?") > 81 capped (concern) > propose red_with_plan +8 89 > ask (9 moves)
    # route (start 52, after Act II's commitment): open question +6 58 (interest) > reflect +5 (rule_bound x0.5) 63 > inquiry +8 71
    #        > empathy +6 77 (lead-in, cue) > paraphrase > 81 capped (concern) > propose frank_explains_first +8 89 > ask (7 moves)
    # 2026-10-16 (1.6c, route variety): his lead-in is a claim ("Dat is gewoon een getal"); silence lets the moment pass.
    # Path: leave_it_out is the watermelon temptation from the other side. Agreeing to it with Frank sets flag:watermelon_review as well.
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).
```

### 3.2 `t2_daily_boards` — Joost and the board in the corridor

```yaml
dialogs:
  - id: joost_board
    person: joost
    kind: persuade
    mission: t2_daily_boards
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    #   after Act II's commitment: 40 + 10 (team work_prep +1) + 3 (trust 65) + 15 = 68, Open
    opening: "Weer een bord. Het vorige hangt nog in de gang, met de cijfers van 2023. Heb je dat gezien?"
    position: {text: "Een bord verandert niets. We hebben er al een.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Een bord is werk. Iemand moet het elke ochtend bijhouden, en dat ben ik dan. Naast al het andere.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [experience, empathy]   # 2026-10-16 (1.6c, route variety): safety; he only says it to someone who also had a board die on them
        lead_in: {text: "Dat vorige bord… Ik weet niet of je dat wilt horen, eigenlijk.", tags: [hesitation, doubt], tell: safety}
        text: "…was van mij. Mijn eerste maand. Twee weken kwam iedereen kijken, daarna niemand meer. Ik heb het laten hangen, want weghalen was toegeven. Als dit ook doodbloedt, hangen er straks twee borden van Joost in de gang."
        tags: [admission]
        unlocks: {facts: [heard:joost_old_board], proposals: [take_old_board_down]}
    reframe: "Vanuit Anouk? Die ziet nu om negen uur pas wat er gisteren is blijven liggen. Met een bord zou ze het om half acht zien. Ja."
    warning: "Ik moet om negen uur bij Frank zijn."
    proposals:
      - {id: team_keeps_board, addresses: [concern], label: "Het team houdt het bord bij", say: "Wat als niet jij het bijhoudt, maar het team? Wie een rood kaartje ophangt, haalt het ook weg. Jij stelt elke ochtend één vraag.", reply: "Eén vraag. Dan is het hun bord. Niet het mijne."}
      - {id: take_old_board_down, hidden: true, addresses: [concern], label: "Het oude bord samen weghalen", say: "Wat als we het oude bord samen weghalen, met het team erbij, en zeggen waarom? Een nieuw begin, geen tweede bord.", reply: "Samen weghalen. … Dan is het geen nederlaag. Dan is het een afsluiting."}
    experiments:
      - {id: ten_mornings, addresses: [concern], label: "Tien ochtenden, dan beslist het team", say: "Tien ochtenden. Daarna beslist het team zelf of het blijft.", reply: "Het team beslist. Niet ik, niet jij. Goed."}
    lines:
      experience:
        say: "Ik heb ook eens een bord opgehangen waar na twee weken niemand meer naar keek. Het hing er nog een jaar."
        lands: {text: "Jij ook? … Dan weet je hoe dat is. Je loopt er elke dag langs.", tags: [admission]}
    co_proposal: {id: take_old_board_down, text: "En dat oude bord… laten we dat er eerst afhalen. Samen. Met een taart."}
    outcomes:
      commitment: "Afgesproken. Maandag om half acht. En die taart betaal ik."
      partial: "Ik doe mee. Als het niet mijn bord wordt."
      heard: "Niemand heeft ooit gevraagd waarom dat bord er nog hangt."
      compliance: "Prima. Nog een bord. Ik hang het naast het andere."
      ruined: "Dus ik moet het weer bijhouden. Fijn."
    variants:
      - needs: {all: [poor_fix:escalation_hallway]}       # the repair quest (repair_escalation_hallway)
        opening: "We trekken aan het koord, maar er komt niemand. Ik heb het bord al half van de muur."
        position: {text: "De kaartjes hangen. Niemand haalt ze op. Dan kan ik ze net zo goed niet ophangen.", tags: [claim, feeling]}
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > reflect +10 71 > empathy +6 77 (lead-in, cue)
    #        > experience (the player's own dead board; safety x1.5) > 81 capped (concern) > propose take_old_board_down +8 89 > ask (8 moves)
    # 2026-10-16 (1.6c, route variety): at the lead-in Joost doubts whether you want to hear it; silence lets the moment pass,
    #   a story of your own draws it out (Ervaring delen needs that he felt heard first, and trust).
    # Lean: a board belongs to the people who write on it (visual management); a leader's routine is one question, not the bookkeeping.
```

### 3.3 `fix_cause_unknown` — the monteur behind "onbekend", and De Linde

```yaml
dialogs:
  - id: ruben_cause
    person: ruben
    kind: persuade
    mission: fix_cause_unknown
    owns: cause_unknown
    mood: moe                              # he came off a night shift
    patience: 9
    # start: craftsman 40 - 10 + 0 + 0 + 0 = 30, Op z'n hoede
    opening: "Ik kom net van een nachtdienst. Als het kort kan, graag."
    position: {text: "Onbekend is onbekend. Om drie uur 's nachts weet ik ook niet waarom die mof het begaf.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [inquiry, open_question], text: "Na vier uur in de kou wil ik naar huis. Het formulier vraagt een verhaal. Onbekend is één klik.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy]   # 2026-10-16 (1.6c, route variety): tired, he needs room, not one more question
        lead_in: {text: "En weet je…", tags: [hesitation]}
        text: "Als ik iets invul en het blijkt anders, heb ik het fout gedaan. Vorig jaar schreef een collega 'graafschade'. De aannemer kreeg een rekening. Bleek het een oude mof te zijn. Wie stond er voor schut? Hij. Dus schrijf ik onbekend."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Een oorzaak invullen is een risico. Als je ernaast zit, sta je voor schut. Onbekend is veilig.'"}
          facts: [heard:ruben_blame]
          proposals: [ruben_at_the_pareto]
    reframe: "Vanuit De Linde? … Die zitten voor de derde keer in het donker, en ik schrijf drie keer onbekend. Hm. Dan leren we er ook drie keer niks van."
    warning: "Ik ben echt moe, hoor."
    data: ["cause_unknown:0", "cause_unknown:4"]
    lines:
      show_data:
        lands: "Drie op de tien op een kabel die al eens kapot was? Dat… dat voel je wel, maar je ziet het nooit zo."
        misses: "Dus wij vullen het slecht in. Leuk."
    proposals:
      - {id: cause_codes, addresses: [interest], label: "Acht oorzaken, met 'weet ik niet zeker'", say: "Acht vaste oorzaken om uit te kiezen, met een vakje 'weet ik niet zeker'.", reply: "Met 'weet ik niet zeker'. Dat is eerlijker dan onbekend."}
      - {id: photo_and_bag, addresses: [concern], label: "Foto en zakje, geen conclusie", say: "Je hoeft niets te concluderen. Een foto, de mof in een zakje met het adres. De conclusie trekken we samen, maandag, bij het bord.", reply: "Geen conclusie. Alleen wat ik zag. Dat kan ik altijd."}
      - {id: ruben_at_the_pareto, hidden: true, addresses: [concern], label: "Ruben vertelt bij de Pareto wat hij zag", say: "Wat als jij maandag bij de Pareto staat en vertelt wat je zag? Niet als verhoor. Als de man die het weet.", reply: "Als de man die het weet. … Ja. Dat heeft nog nooit iemand gevraagd."}
    co_proposal: {id: ruben_at_the_pareto, text: "Laat ons de moffen meenemen. Dan leggen we ze maandag op tafel. Dan zie je het zelf."}
    outcomes:
      commitment: "Doe ik. Maandag neem ik een tas vol moffen mee. Ruikt niet lekker, zeg ik er maar bij."
      partial: "Ik doe mee. Als niemand er een rekening van maakt."
      heard: "Hm. Fijn dat je het vroeg. Echt."
      compliance: "Prima. Ik vul wel iets in."
      ruined: "Zie je. Onbekend was veiliger."
    # route: mood +8 38 > open question +6 44 > paraphrase +7 51 (heard, interest) > reflect +10 61 > inquiry +12 (craftsman) 73 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose ruben_at_the_pareto +8 87 > ask (8 moves)
    # Note: inquiry right after the interest misses (+3): it lands only within 10 of the next layer's threshold (spec §3.3).
    # Trap: the IT manager's mandatory field (the temptation) is the answer to his fear made worse: it forces a guess and polices it.
    # 2026-10-16 (four-tier audit §4): interest via [open_question, inquiry, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).

  - id: brouwer_third_outage
    person: brouwer
    kind: persuade
    mission: fix_cause_unknown
    place: customer_contact.answer         # she calls; the player takes the call
    mood: gespannen
    patience: 10
    # start: customer_upset 25 - 5 + 0 + 0 + 0 = 20, Op z'n hoede
    opening: "Goedemiddag. Annet Brouwer, zorgcentrum De Linde. U kent ons misschien nog. Van de graafschade."
    position: {text: "Drie keer in een halfjaar. De laatste keer twee uur, met bewoners aan de zuurstof.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [paraphrase, empathy], text: "Ik wil geen excuusbrief. Ik wil weten waarom het steeds bij ons is.", tags: [claim, feeling]}
      - id: concern
        at: 66
        via: [reflect, empathy]
        lead_in: {text: "Ik word nog steeds misselijk als ik eraan denk. Weet u wat het is…", tags: [feeling]}
        text: "Mevrouw Jansen, kamer twaalf. Zuurstof. De accu van haar apparaat hield het anderhalf uur. Het laatste halfuur hebben we met z'n drieën naast haar bed gezeten. Ik slaap niet meer goed als het waait."
        tags: [admission]
        unlocks: {facts: [heard:brouwer_room12], proposals: [check_the_generator]}
    warning: "Als u een folder gaat voorlezen, hang ik op."
    lines:
      reflect: {lands: {text: "Ja. Bang. En boos dat ik bang moet zijn, in een zorgcentrum.", tags: [claim, feeling]}}
    proposals:
      - {id: never_again, addresses: [], label: "Beloven dat het niet meer gebeurt", say: "Ik beloof u dat het niet meer gebeurt.", reply: "Dat zei uw collega na de graafschade ook."}
      - {id: honest_cause_in_a_month, addresses: [interest, concern], label: "Binnen een maand de oorzaak, eerlijk", say: "Ik beloof u niet dat het nooit meer gebeurt. Wel dat we uitzoeken waarom het steeds dezelfde kabel is, en dat ik u binnen een maand bel met wat we vonden.", reply: "Binnen een maand. U. Goed."}
      - {id: check_the_generator, hidden: true, addresses: [concern], label: "Samen het noodaggregaat testen", say: "En tot die tijd: mag een monteur van ons met uw technische dienst testen of het noodaggregaat ook kamer twaalf voedt, en hoe snel?", reply: "Kamer twaalf. Daar heb ik nooit aan gedacht. Het aggregaat doet de gangen en de keuken. Ja. Graag."}
    outcomes:
      commitment: "Dank u. En als u belt over de oorzaak, wil ik het ook horen als het slecht nieuws is."
      partial: "Ik wacht af. Een maand."
      heard: "U luisterde. Dat is meer dan ik verwachtte."
      ruined: "Dan schrijf ik de wethouder. En de krant."
    # route: empathy +9 29 > paraphrase +10 39 (heard) > open question +6 45 (interest) > reflect +10 55 > paraphrase +10 65
    #        > empathy +9 74 (lead-in, cue) > silence +12 > 75 capped (concern) > propose check_the_generator +8 83 > ask (9 moves)
    # Promise: honest_cause_in_a_month carries `promise: {kind: callback, days: 30}` (dialog scripts Q11). Kept, it lifts reputation +1;
    #   broken, her next call starts at memory -15. The mission's debrief reads it ("Mevrouw Brouwer kreeg haar telefoontje.").
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [paraphrase, open_question, inquiry] -> [paraphrase, empathy] (customer_upset). Route re-checked by the simulator (audit §4.4).
```

### 3.4 The fork: `fix_on_call_far` (B) and `fix_shift_handover` (N)

```yaml
dialogs:
  - id: inge_standby
    person: inge
    kind: persuade
    mission: fix_on_call_far
    owns: on_call_far
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Ik heb deze week consignatie, dus ik heb mijn telefoon bij me. Als hij gaat, ben ik weg."
    position: {text: "Mijn standplaats is mijn huis. Zo staat het in mijn contract.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Consignatie is thuis wachten. Je slaapt in je eigen bed, met je telefoon naast je. Dat maakt het vol te houden: een week op, een week af.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [reflect, empathy, inquiry]
        lead_in: {text: "Ik word daar boos van, eerlijk gezegd. En dan…", tags: [feeling]}
        text: "Ik heb twee kinderen. Als ik 's nachts in een werkplaats in Noordveld moet wachten, wie is er dan thuis? Mijn ex woont in Tilburg. Dan stop ik met consignatie. En dan heeft Kees er 's nachts nog één."
        tags: [admission]
        unlocks: {facts: [heard:inge_kids], proposals: [north_volunteer]}
    reframe: "Vanuit de mensen in Noordveld? Die wachten drie kwartier op mij, in het donker. Ja. Dat weet ik ook wel."
    warning: "Mijn telefoon kan elk moment gaan."
    data: ["on_call_far:0", "on_call_far:4"]
    proposals:
      - {id: wait_in_noordveld, addresses: [interest], label: "Wachten in de werkplaats in Noordveld", say: "Wacht 's nachts in de oude werkplaats in Noordveld.", reply: "Daar staat een bank en een koffieautomaat. Voor een hele nacht?"}
      - {id: standby_by_map_for_who_can, addresses: [concern], label: "Een standplaats op de kaart, voor wie kan", say: "De standplaats volgt de storingskaart, maar alleen voor wie dat kan of wil. Wie kinderen thuis heeft, wacht thuis en neemt de storingen in het zuiden.", reply: "Voor wie kan. Dan hoef ik niet te kiezen tussen mijn kinderen en mijn werk."}
      - {id: north_volunteer, hidden: true, addresses: [concern], label: "Een consignatiemonteur die in het noorden woont", say: "Wat als er een monteur in de consignatie komt die in het noorden woont? Die wacht al waar de storingen zijn.", reply: "Rick woont in Noordveld. Die vraagt al twee jaar om consignatie, voor het geld. Niemand heeft het hem ooit gevraagd."}
    co_proposal: {id: north_volunteer, text: "Vraag het Rick. Die woont naast de oude werkplaats. Die is er in vijf minuten."}
    outcomes:
      commitment: "Dan bel ik Rick zelf. En ik blijf gewoon thuis wachten. Dank je."
      partial: "Ik wil het wel. Als niemand gedwongen wordt."
      heard: "Je bent de eerste die naar mijn kinderen vraagt in plaats van naar mijn aanrijtijd."
      compliance: "Ik ga in Noordveld zitten. Tot het niet meer gaat."
      ruined: "Dan zoek je maar iemand anders voor de consignatie."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > reflect +10 71 > empathy +6 77 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose north_volunteer +8 89 > ask (8 moves)
    # The temptation (extra on-call weekends for Ruben and Inge) is answered here as compliance: "Prima. Ik doe ze. Tot het niet meer gaat."
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses). Route re-checked by the simulator (audit §4.4).

  - id: wendy_handover
    person: wendy
    kind: persuade
    mission: fix_shift_handover
    owns: shift_handover
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Kees heeft je gestuurd, hè. Over de overdracht. Ga zitten, de wand is rustig."
    position: {text: "Ik draag al achtentwintig jaar over. Daar heb ik geen formulier voor nodig.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Een goede overdracht is een verhaal. Wat speelt er, wie heb je gebeld, waar zit je onderbuik. Dat past niet in vakjes.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [paraphrase, empathy]   # 2026-10-16 (1.6c, route variety): recognition; she opens when her way of working is said back in her words
        lead_in: {text: "Achtentwintig jaar heb ik het zo gedaan, en het ging goed. Wat ik niet wil…", tags: [hesitation, claim], tell: recognition}
        text: "Als er een formulier komt, denkt de directie dat wij het niet konden. En de jonge operators gaan vakjes invullen in plaats van nadenken. Dan wordt de meldkamer een loket."
        tags: [admission]
        unlocks: {facts: [heard:wendy_story], proposals: [wendy_sets_the_questions]}
    reframe: "Vanuit de jongen die om drie uur van mij overneemt? Die moet in twintig minuten weten wat ik in acht uur heb opgebouwd. Hm. Dat is veel gevraagd."
    warning: "Als de wand rood wordt, ben ik weg."
    data: ["shift_handover:0", "shift_handover:2"]
    proposals:
      - {id: open_actions_list, addresses: [interest], label: "Een lijst met open acties", say: "Een lijst met open acties in het systeem, die je bij de wissel doorloopt.", reply: "Een lijst. Ja. Die helpt. Maar een lijst vertelt niet wat je voelt."}
      - {id: board_three_questions, addresses: [concern], label: "Bij het bord: drie vaste vragen, dan het verhaal", say: "Een overdracht bij het bord: drie vaste vragen, en daarna jouw verhaal.", reply: "Drie vragen en mijn verhaal. Dat is eigenlijk hoe ik het zelf doe."}
      - {id: wendy_sets_the_questions, hidden: true, addresses: [concern], label: "Wendy bepaalt de vragen", say: "Wat als jij de drie vragen bepaalt? Jij weet wat er altijd vergeten wordt.", reply: "Ik. Dan staan er de goede vragen op. Niet die van een adviesbureau."}
    co_proposal: {id: wendy_sets_the_questions, text: "Laat mij die drie vragen opschrijven. En laat de jongens het een maand naast mij doen."}
    outcomes:
      commitment: "Zo doen we dat dan. Drie vragen, mijn verhaal, en de jongens ernaast. Dat is geen loket. Dat is een vak."
      partial: "Ik doe mee. Als het verhaal blijft."
      heard: "Achtentwintig jaar, en je bent de eerste die vraagt hoe ík het doe."
      compliance: "Prima. Ik vul het formulier in. En daarna vertel ik het toch."
      ruined: "Een formulier. Zie je wel. Een loket."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman) 65 > capped 64 (interest) > reflect +10 74 (lead-in, cue)
    #        > paraphrase ("achtentwintig jaar, en het ging goed") > 79 capped (concern) > propose wendy_sets_the_questions +8 87 > ask (7 moves)
    # 2026-10-16 (1.6c, route variety): silence at the lead-in lets the moment pass; she needs to hear her years named.
    # Lean: standard work written by the experienced worker, which is not a form imposed on her.
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
```

### 3.5 `fix_contractor_rework` — Gert and Marco, both right

```yaml
dialogs:
  - id: gert_contractor
    person: gert
    kind: persuade
    mission: fix_contractor_rework
    owns: contractor_rework
    mood: gespannen                        # the contract renewal is in five weeks
    patience: 10
    # start: defender 40 - 5 + 0 + 0 + 0 = 35, Op z'n hoede
    #   after committed:gert_klic (Act II): 35 + 2 (trust 60) + 15 = 52, Luistert
    #   after a confront in gert_klic: 35 - 2 (trust 40) - 15 = 18, Dicht
    opening: "Jij weer. Van de graafschade. Gaat het nu over mijn sleuven?"
    position: {text: "Mijn jongens graven zoals het op de tekening staat. Als het fout is, hoor ik het zes weken later op de factuur.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Ik heb elke maand nieuwe jongens. Uit Polen, uit het dorp, van een uitzendbureau. Ze krijgen de tekening. Wat Voltana eigenlijk wil, staat nergens.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [experience, empathy]   # 2026-10-16 (1.6c, route variety): safety; he says it to someone who has seen a team stand still
        lead_in: {text: "En als dat contract… Ach. Wat maakt het jou uit.", tags: [hesitation, doubt], tell: safety}
        text: "Als het contract niet verlengd wordt, gaan er acht man naar huis. Mijn vader heeft dit bedrijf opgebouwd. En dan zegt Marco in de kantine dat Peeters niet kan graven."
        tags: [admission]
        unlocks: {facts: [heard:gert_crews], proposals: [photo_before_backfill]}
    reframe: "Vanuit de monteur die naar mijn sleuf rijdt? Die staat erbij, ziet veertig centimeter, en rijdt terug. Ja. Daar zou ik ook chagrijnig van worden."
    warning: "Ik heb mijn advocaat al gebeld over dat contract."
    data: ["contractor_rework:2", "contractor_rework:3"]
    lines:
      show_data:
        lands: "Versie 2? Wij werken met versie 2. Niemand heeft ons ooit versie 4 gestuurd. Dat meen je niet."
        misses: "Dus het ligt aan mijn jongens."
      experience:
        say: "Ik heb eens meegemaakt dat een opdracht wegviel en een heel team thuis zat. Dat vergeet je niet."
        lands: {text: "Nee. Dat vergeet je niet. Dan zit je aan de keukentafel en zegt niemand wat.", tags: [admission]}
    proposals:
      - {id: same_standard, addresses: [interest], label: "Eén sleufstandaard, dezelfde versie", say: "Eén sleufstandaard, dezelfde versie voor jullie en voor ons.", reply: "Welke versie? Wij hebben versie 2."}
      - {id: photo_before_backfill, hidden: true, addresses: [concern], label: "Een foto voordat de sleuf dicht gaat", say: "Wat als je ploeg een foto stuurt voordat de sleuf dichtgaat, en een monteur zegt binnen een uur of het goed is? Dan hoor je het vandaag, niet op de factuur.", reply: "Vandaag. Dan kan ik mijn jongen nog vertellen wat er mis was. Dan leert hij het."}
    experiments:
      - {id: friday_with_marco, addresses: [concern], label: "Elke vrijdag een kwartier met Marco", say: "Elke vrijdag een kwartier met Marco aan het bord: wat ging er deze week mis.", reply: "Met Marco. … Als hij komt, kom ik."}
    co_proposal: {id: photo_before_backfill, text: "Geef mijn ploegleiders een nummer waar ze een foto naartoe kunnen sturen. Dan weten ze het voordat de grond erop ligt."}
    outcomes:
      commitment: "Afgesproken. En als jullie tekening fout is, wil ik dat ook horen. Binnen een uur."
      partial: "Ik doe mee. Als het contract wordt verlengd."
      heard: "Je vroeg naar mijn jongens. Dat deed je bij die kabel ook."
      compliance: "Als het moet voor het contract. Ik zeg het tegen mijn ploegen."
      ruined: "Prima. Neem een andere aannemer. Succes met de nieuwe jongens."
    # route (start 35): mood +8 43 > open question +6 49 > paraphrase +7 56 (heard, interest) > show_data +10 66 > empathy +6 72 (lead-in, cue)
    #        > experience (safety x1.5) > 79 capped (concern) > propose photo_before_backfill +8 87 > ask (8 moves)
    # 2026-10-16 (1.6c, route variety): "Wat maakt het jou uit" is a doubt; only your own story answers it. Silence lets it pass.
    # Path: the Act II talk decides where this starts (52, 35 or 18). Respect for an outside partner in Act II pays in Act III.

  - id: marco_contractor
    person: marco
    kind: persuade
    mission: fix_contractor_rework
    patience: 10
    # start: cynic 30 + 0 + 0 + 0 + 0 = 30, Op z'n hoede
    #   with Act I's commitment and the day-100 check-in lifted: 30 + 10 + 2 + 15 = 57
    opening: "Ik heb het drie keer gezegd. Ze leren het niet. Andere aannemer, klaar."
    position: {text: "Peeters kan niet graven. Inkoop heeft een andere die volgende maand kan beginnen.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [paraphrase, inquiry], text: "Mijn mannen rijden naar een sleuf, staan erbij, rijden terug. De klant belt mij, niet Peeters.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [show_data, paraphrase]   # 2026-10-16 (1.6c, route variety): fairness; he opens when the record shows he said it, or when you say it back
        lead_in: {text: "Drie meldingen, met datum. Staat allemaal in het systeem. En eerlijk is eerlijk…", tags: [hesitation, claim], tell: fairness}
        text: "Drie keer. Als ik nu niet hard ben, denken mijn mannen dat ik niks voor ze regel. Dan is het weer 2012: praten, en er verandert niks."
        tags: [admission]
        unlocks: {facts: [heard:marco_hard], proposals: [look_at_one_trench]}
    reframe: "Vanuit de jongen van Peeters? Die graaft volgens een tekening die hij snapt, en hoort zes weken later dat het fout was. Hm. Van wie dan?"
    warning: "Jij gaat me niet vertellen dat het aan ons ligt."
    data: ["contractor_rework:2"]
    lines:
      open_question:
        lands: {text: "Wat er speelt? Mijn mannen rijden voor niks. En Peeters krijgt gewoon betaald. Leg dat maar eens uit in de kantine.", tags: [claim], tell: fairness}
    proposals:
      - {id: switch_now, addresses: [interest], label: "Overstappen naar een andere aannemer", say: "We stappen over naar een andere aannemer.", reply: "Eindelijk. … Al hebben die ook nieuwe jongens, natuurlijk."}
      - {id: look_at_one_trench, hidden: true, addresses: [concern], label: "Samen met Gert naar één sleuf kijken", say: "Wat als jij en Gert samen naar één afgekeurde sleuf gaan kijken? Niet om te praten. Om te kijken.", reply: "Kijken. Samen. Dan zie ik of hij het snapt. En hij ziet of ik gelijk heb."}
    experiments:
      - {id: one_month_then_inkoop, addresses: [concern], label: "Een maand, daarna mag Marco naar Inkoop", say: "Eén maand een vaste terugkoppeling met Gert. Is het dan niet beter, dan stap jij zelf naar Inkoop.", reply: "Een maand. En dan mag ik. Goed. Dan heb ik het ze tenminste gezegd."}
    co_proposal: {id: look_at_one_trench, text: "Laat mij die sleuf aanwijzen. De Klaverstraat. Daar zie je het meteen."}
    outcomes:
      commitment: "Klaar. Klaverstraat, dinsdag om zeven uur. En hij neemt de koffie mee."
      partial: "Ik doe mee. Een maand. Daarna niet meer."
      heard: "Hm. Je hebt gelijk dat ik het al drie keer zei. Ik zei het alleen nooit tegen hem."
      compliance: "Ik praat met hem. Het verandert toch niks."
      ruined: "Zie je. Praten. Wie bouwt dat na?"
    # route (start 30): mood +8 38 > open question +6 44 > paraphrase +7 51 (heard) > inquiry +8 59 (interest) > empathy +6 65
    #        > open question (lead-in, cue) > show_data +15 (cynic: his three reports in the rework data) > 79 capped (concern)
    #        > propose look_at_one_trench +8 87 > ask (9 moves)
    # 2026-10-16 (1.6c, route variety): the concern comes out on the record (data) or his words said back, never on silence: this Marco
    #   wants it acknowledged that he reported it, three times. In marco_overtime the same Marco opens differently.
    # Both dialogs have a co-proposal that names the other person: the fix is the two of them at one trench.
    # 2026-10-16 (four-tier audit §4): interest via [open_question, inquiry, paraphrase] -> [paraphrase, inquiry] (cynic). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (1.6c, route variety): open questions land with a claim (his men pay for another's error), so Samenvatten and Doorvragen have something to answer.
```

### 3.6 `fix_escalation_hallway` — the 24-hour rule and a junior analyst

```yaml
dialogs:
  - id: koen_24h
    person: koen
    kind: persuade
    mission: fix_escalation_hallway
    owns: escalation_hallway
    patience: 9
    # start: overloaded 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede; with done:fix_grid_study_queue (triage): mood goed, 45
    opening: "Gaat het over die rode kaartjes? Ik weet het. Er hangen er vier voor ons."
    position: {text: "Binnen 24 uur reageren op elk rood kaartje? Wij zitten al vol.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [empathy, mood, open_question], text: "Elke dag lopen er drie mensen langs met 'even een vraagje'. Elk vraagje is een halfuur. Ik kom niet aan mijn eigen werk toe.", tags: [claim, feeling]}
      - id: concern
        at: 68
        via: [reflect, empathy]
        lead_in: {text: "Ik word daar heel onrustig van. Het is ook…", tags: [feeling]}
        text: "Als ik binnen een dag moet antwoorden en ik weet het niet zeker, zeg ik iets wat later fout blijkt. Femke kan dat hebben. Ik ben er twee jaar. Liever zeg ik niks dan iets fouts."
        tags: [admission]
        unlocks: {facts: [heard:koen_sure], proposals: [answer_or_date]}
    reframe: "Vanuit Joosts tekenaar? Die zit negen dagen te wachten op een antwoord dat ik misschien in tien minuten had. Hm. Dat wist ik niet."
    warning: "Ik moet echt verder rekenen."
    data: ["escalation_hallway:0", "escalation_hallway:4"]
    proposals:
      - {id: one_slot_a_day, addresses: [interest], label: "Eén vast halfuur per dag", say: "Eén vast halfuur per dag waarin Netstrategie de rode kaartjes van anderen beantwoordt.", reply: "Eén halfuur. Dan lopen ze niet de hele dag langs."}
      - {id: answer_or_date, hidden: true, addresses: [concern], label: "Een antwoord, of een datum", say: "De 24-uursregel vraagt geen antwoord. Binnen een dag zeg je óf het antwoord, óf wanneer je het hebt. 'Weet ik nog niet, donderdag' telt ook.", reply: "Een datum is ook een antwoord. Dat kan ik altijd."}
    experiments:
      - {id: with_femke_first_month, addresses: [concern], label: "De eerste maand samen met Femke", say: "De eerste maand beantwoord je ze samen met Femke.", reply: "Met Femke. Dan leer ik hoe zij het zo snel weet."}
    co_proposal: {id: answer_or_date, text: "Als 'donderdag' ook mag… dan kan ik elke ochtend om negen uur alle kaartjes langs. Met een datum op elk."}
    outcomes:
      commitment: "Afgesproken. Om negen uur. Elk kaartje een antwoord of een datum."
      partial: "Ik wil het wel. Als Femke het ook goed vindt."
      heard: "Fijn dat je vroeg waarom ik niks zeg. Ik dacht dat niemand dat zag."
      compliance: "Prima. 24 uur. Ik zie wel wat ik zeg."
      ruined: "Dus ik ben te traag. Ook goed."
    # route (start 35): mood +12 (overloaded x1.5) 47 > open question +6 53 (interest) > reflect +10 63 (heard) > empathy +6 69 (lead-in, cue)
    #        > silence +12 > 77 capped (concern) > propose answer_or_date +8 85 > ask (7 moves)
    # Lean: tiered escalation needs psychological safety. A 24-hour rule that demands answers makes people hide; one that allows a date works.
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [open_question, inquiry, paraphrase] -> [empathy, mood, open_question] (overloaded). Route re-checked by the simulator (audit §4.4).
```

### 3.7 `acm_visit` — the inspector

The milestone is judged by its measure. This talk does not change the verdict. It changes how the verdict is written, the recovery mission's tone if it fails, and a fact tier 3 reads (`acm_pilot_time_bound` is offered more readily to a DSO the ACM trusts).

```yaml
dialogs:
  - id: acm_inspector
    person: van_dalen
    kind: persuade
    mission: acm_visit
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede; with flag:acm_clock_gamed (the tier-2 temptation): memory -15 = 20, and the variant
    opening: "Goedemorgen. Lydia van Dalen, ACM. Ik heb een uur. Mag ik meteen met de cijfers beginnen?"
    position: {text: "Woonstichting Nova zegt dat haar nieuwbouw veel langer op een aansluiting wacht dan redelijk is. Ik wil uw cijfers zien, vanaf de aanvraag.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, paraphrase], text: "Ik hoef geen perfecte cijfers. Ik wil zien dat u uw eigen proces kent: waar het wacht, en waarom.", tags: [claim]}
      - id: concern
        at: 72
        via: [inquiry, paraphrase]   # 2026-10-16 (1.6c, route variety): facts; a regulator opens to precise questions, not to a pause
        lead_in: {text: "Ik zal eerlijk zijn. Ik heb dit vaker gezien. Dezelfde cijfers, hetzelfde verhaal.", tags: [hesitation, claim], tell: facts}
        text: "Ik heb in vijf jaar drie netbeheerders gezien met prachtige cijfers die niet klopten. Dan sta ik voor de rechter met een besluit op drijfzand. Ik vertrouw liever een eerlijk rood dan een groen dat ik niet kan narekenen."
        tags: [admission]
        unlocks: {facts: [heard:acm_trust], proposals: [same_measure_in_three_months]}
    reframe: "Vanuit de huurders van de woonstichting? Die hebben een sleutel en geen stroom. Ja. Daarom zit ik hier."
    warning: "Als u mij een presentatie gaat geven, kunt u die beter mailen."
    proposals:
      - {id: promise_eighteen_weeks, addresses: [], label: "Beloven: voortaan binnen achttien weken", say: "Wij beloven dat alles voortaan binnen achttien weken is.", reply: "Beloften heb ik genoeg gehoord."}
      - {id: full_data_with_waits, addresses: [concern], label: "Alle cijfers, vanaf de aanvraag, met waar het wacht", say: "Hier zijn de cijfers vanaf de datum van aanvraag, ook de rode, en per stap waar het wacht en wat we eraan doen.", reply: "Vanaf de aanvraag. En u weet waar het wacht. Dat zie ik niet vaak."}
      - {id: same_measure_in_three_months, hidden: true, addresses: [concern], label: "Over drie maanden terugkomen, met dezelfde meting", say: "Wat als u over drie maanden terugkomt, en wij laten met dezelfde meting zien wat we in de tussentijd veranderden?", reply: "Dezelfde meting, over drie maanden. Dat schrijf ik in mijn verslag. Dat is precies wat ik wil zien."}
    outcomes:
      commitment: "Dank u. Ik schrijf in mijn verslag dat Voltana zijn eigen proces kent. Dat is in mijn vak een compliment."
      partial: "Ik wacht uw cijfers over drie maanden af."
      heard: "Dank u voor uw openheid."
      ruined: "Ik zal mijn bevindingen schriftelijk vastleggen. U hoort van ons."
    variants:
      - needs: {all: [flag:acm_clock_gamed]}
        position: {text: "Uw cijfers beginnen bij 'compleet'. De klant begint bij zijn aanvraag. Kunt u mij uitleggen waarom?", tags: [claim]}
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > empathy +6 62 > perspective +8 70
    #        > inquiry +8 78 (lead-in, cue) > inquiry ("Wat zag u dan?") or paraphrase > 81 capped (concern) > propose same_measure_in_three_months +8 89 > ask (9 moves)
    # 2026-10-16 (1.6c, route variety): silence at the lead-in lets the moment pass; she has an hour and wants precision.
    # With flag:acm_clock_gamed the route starts at 20 and needs repair-like honesty: the only proposal that addresses her concern is the full data.
    # Facts: committed:acm_inspector softens acm_improvement_plan's text if the milestone fails, and is read by tier 3's acm_pilot_time_bound.
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).
```

### 3.8 Act III sides

```yaml
dialogs:
  - id: dirk_reorder
    person: dirk
    kind: persuade
    mission: fix_safety_stock_calendar
    owns: safety_stock_calendar
    mood: gespannen                        # the meters ran out for the third time; people blame the warehouse
    patience: 10
    # start: defender 40 - 5 + 0 + 0 + 0 = 35; after committed:dirk_shelf (Act I): 35 + 2 + 15 = 52
    opening: "Als het over de meters gaat: de leverancier levert op tijd. Ik heb de bonnen hier."
    position: {text: "Weet je wat? We bestellen voortaan het dubbele. Dan raken ze nooit meer op.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Als de meters op zijn, staat Linda aan mijn balie. Dan Marco. En dan Ruud.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "Kijk, ik ben geen…", tags: [hesitation]}
        text: "…rekenaar. Die bestelsheet heb ik in 2015 van mijn voorganger gekregen. Als ik zeg dat ik niet snap hoe hij werkt… Zestig jaar, en je snapt je eigen sheet niet."
        tags: [admission]
        unlocks: {facts: [heard:dirk_sheet], proposals: [sheet_together]}
    reframe: "Vanuit de klant die zijn analoge meter kwijt moet? Die krijgt een brief, en dan komt er een week niemand. Omdat mijn stelling leeg is. Hm."
    warning: "Ik heb een vrachtwagen te lossen."
    data: ["safety_stock_calendar:0", "safety_stock_calendar:4"]
    lines:
      show_data:
        lands: "Acht per werkdag, niet vijf. Ja. Op maandag gaan er tien de deur uit. Dat zie ik toch."
        misses: "Ik heb ze besteld. Op tijd. Elke keer."
    proposals:
      - {id: order_double, addresses: [interest], label: "Het dubbele bestellen", say: "Het dubbele bestellen.", reply: "Ja. Al staat de stelling dan vol met GPRS-meters die over een jaar niemand meer wil."}
      - {id: sheet_together, hidden: true, addresses: [concern], label: "De sheet samen nalopen", say: "Wat als we de sheet samen nalopen, regel voor regel? Jij weet wat er de deur uitgaat, ik weet hoe je rekent. Dan is het jouw sheet, en klopt hij.", reply: "Samen. Regel voor regel. Dan hoef ik niet te doen alsof."}
    experiments:
      - {id: two_bins_of_meters, addresses: [concern], label: "Twee bakken meters", say: "Twee bakken meters, zoals de moffen in de bussen. Is de eerste leeg, dan bestel je.", reply: "Twee bakken. Dat snap ik. Dat heb ik zelf bedacht, toch?"}
    co_proposal: {id: sheet_together, text: "Kom morgen om zeven. Dan lopen we hem door. Ik zet koffie, jij neemt een rekenmachine mee."}
    outcomes:
      commitment: "Doe ik. En als hij klopt, hang ik hem op. Met mijn naam erop."
      partial: "Als niemand zegt dat ik het al jaren fout deed. Dan doe ik mee."
      heard: "Hm. Fijn dat je het vroeg."
      compliance: "Jullie sheet. Ik bestel wat erop staat."
      ruined: "Ik heb ze gewoon besteld. Zoek het verder zelf maar uit."
    # route (start 35): mood +8 43 > open question +6 49 > paraphrase +7 56 (heard, interest) > show_data +10 66 > empathy +6 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose sheet_together +8 87 > ask (8 moves)
    # two_bins_of_meters reads well only after Act I's dirk_fills_bins; its reply is a joke that needs that history.

  - id: nicole_lmra
    person: nicole
    kind: persuade
    mission: fix_lmra_tickbox              # safety: true. Pressure used to contain today carries no buy-in penalty (spec §4.2)
    owns: lmra_tickbox
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Ik heb de twee meldingen gelezen. Allebei een LMRA op akkoord. Ik weet wat je gaat zeggen."
    position: {text: "Die lijst is er niet voor niets. Elke vraag staat er omdat er ooit iets gebeurd is.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, paraphrase], text: "De auditor van de veiligheidsladder kijkt of elke LMRA is ingevuld. Honderd procent ingevuld is groen.", tags: [claim]}
      - id: concern
        at: 72
        via: [experience, empathy]   # 2026-10-16 (1.6c, route variety): safety; she tells it to someone who also carries a moment like that
        lead_in: {text: "In 2019… Nee. Ik weet niet of dat hier hoort.", tags: [hesitation, doubt], tell: safety}
        text: "…heb ik een monteur in het ziekenhuis bezocht. Brandwonden aan zijn handen. Als ik er één vraag uithaal en precies dát gaat mis, dan heb ik die vraag geschrapt. Dus komt er na elk incident een bij. Ik weet ook wel dat niemand ze nog leest."
        tags: [admission]
        unlocks: {facts: [heard:nicole_2019], proposals: [safely_stopped_code]}
    reframe: "Vanuit de monteur bij die kast? Die moet 42 vragen afvinken voordat hij de werkbon mag openen. Dan kijkt hij niet meer naar de kast. Nee. Dat is niet wat ik wilde."
    warning: "Ik ga niet tornen aan veiligheid."
    data: ["lmra_tickbox:2", "lmra_tickbox:5"]
    lines:
      pressure:
        say: "Tot we het weten: niemand opent een kast van voor 1970 alleen. Vanaf vandaag."
        any: "Vanaf vandaag. Ja. Dat steun ik. Dat had ik zelf moeten zeggen."
      experience:
        say: "Ik heb ook iets wat ik niet kwijtraak. Een klus waar het bijna misging. Ik had hem zelf goedgekeurd."
        lands: {text: "Dan weet je het. Je denkt: welke vraag had dit tegengehouden.", tags: [admission]}
    proposals:
      - {id: task_cards, addresses: [concern], label: "Een kaart per soort klus", say: "Per soort klus een kaart met de drie echte risico's van díe klus, gemaakt met de monteurs. Kort genoeg om te lezen.", reply: "Drie risico's die ertoe doen, in plaats van 42 die niemand leest. Ja."}
      - {id: safely_stopped_code, hidden: true, addresses: [concern], label: "'Veilig gestopt' telt als goed werk", say: "Wat als er een code komt voor 'veilig gestopt', die telt als goed werk en niet als 'niet gehaald'? Dan kan een monteur stoppen zonder uit te leggen waarom hij zijn planning mist.", reply: "Veilig gestopt als goed werk. Dat had er al jaren moeten zijn."}
    co_proposal: {id: safely_stopped_code, text: "En laat de eerste 'veilig gestopt' van elke maand op het bord komen. Met een bedankje. Niet met een vraag waarom."}
    outcomes:
      commitment: "Afgesproken. Ik schrijf de kaarten met de monteurs. En de auditor krijgt van mij uitgelegd waarom 42 vragen onveiliger was dan drie."
      partial: "Ik wil het wel. Als de auditor het accepteert."
      heard: "Je vroeg naar 2019. Dat doet niemand."
      compliance: "Kortere lijst. Ik teken niet mee."
      ruined: "Ik laat niet met veiligheid sjoemelen. Ook niet door jou."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > experience (a moment of your own you still carry; safety x1.5) > 81 capped (concern)
    #        > propose safely_stopped_code +8 89 > ask (8 moves)
    # 2026-10-16 (1.6c, route variety): Nicole doubts whether 2019 belongs here; silence lets it pass, a story of your own draws it out.
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).

  - id: ruben_storm
    person: ruben
    kind: persuade
    mission: prep_storm_week
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40; after committed:ruben_cause: + 2 + 15 = 57
    opening: "Code oranje volgende week? Ik weet het al. Mijn vrouw heeft de baby al bij haar moeder ondergebracht."
    position: {text: "Als die storm komt, word ik toch wel gebeld. Net als vorig jaar.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Vorig jaar ben ik drie nachten achter elkaar uit mijn bed gebeld. Op de vierde dag reed ik bijna een sloot in.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [reflect, empathy]   # 2026-10-16 (1.6c, route variety): the cue is a feeling now (tier 2 had six of seventeen)
        lead_in: {text: "Het punt is… ik schrik nog steeds wakker van die sloot. Echt.", tags: [feeling]}
        text: "Niemand zegt nee als het stormt. Ik ook niet. Dat is het probleem. Als iedereen 72 uur oproepbaar is, is na een dag niemand meer veilig. Op de weg niet, en bij een kabel niet."
        tags: [admission]
        unlocks: {facts: [heard:ruben_rest], proposals: [rested_reserve]}
    reframe: "Vanuit Esra's mensen? Die krijgen de hele nacht boze bellers die niet weten of er iemand komt. Ja. Als die konden zeggen wanneer we er zijn, hoefde ik ook niet zo te jakkeren."
    warning: "Ik moet de bus nog inruimen."
    proposals:
      - {id: all_hands, addresses: [interest], label: "Alle hens: iedereen oproepbaar", say: "Alle hens: verlof ingetrokken, iedereen 72 uur oproepbaar.", reply: "Iedereen. Ook ik. Weer."}
      - {id: rested_reserve, hidden: true, addresses: [concern], label: "Een vrijwillige reserve, met gegarandeerde rust", say: "Een vrijwillige reserve, in ploegen, met gegarandeerde rust ertussen. Wie gewerkt heeft, mag niet gebeld worden.", reply: "Mag niet gebeld worden. Dat heb ik nog nooit gehoord. Dan meld ik me."}
    experiments:
      - {id: rest_rule_next_wind, addresses: [concern], label: "De rustregel al bij de volgende harde wind", say: "Probeer het al bij de volgende harde wind: wie 's nachts werkte, is de volgende dag vrij. Gegarandeerd.", reply: "Gegarandeerd. Op papier? Dan geloof ik het."}
    co_proposal: {id: rested_reserve, text: "Laat ons zelf het rooster maken. Wij weten wie een baby heeft en wie niet."}
    sets_flags_on_outcome: {commitment: [flag:rest_rule]}   # four-tier audit 1.1: the flag is set here (and by storm_night_board's commitment, drie-winters 7.4)
    outcomes:
      commitment: "Afgesproken. Ik maak het rooster met de anderen. En niemand belt mij als ik vrij ben. Niemand."
      partial: "Als die rust echt op papier staat, ben ik erbij."
      heard: "Je vroeg naar die sloot. Dat heb ik nog aan niemand verteld."
      compliance: "Ik ben oproepbaar. Zoals altijd."
      ruined: "Dus ik moet gewoon harder. Fijn. Tot ik in die sloot lig."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman) 65 > capped 64 (interest) > reflect +10 74 (lead-in, cue)
    #        > reflect (lead-in "ik schrik nog steeds wakker") > 79 capped (concern) > propose rested_reserve +8 87 > ask (7 moves)
    # 2026-10-16 (1.6c, route variety): the cue is a feeling; silence after it misses (-6).
    # Facts: committed:ruben_storm sets flag:rest_rule, read by tier 3's crew strategy (the overtime option's aftermath is milder for a team
    #   with a rest rule) and by D27 Niemand opgebrand.
    # 2026-10-16 (four-tier audit §4): interest via [open_question, inquiry, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).

  - id: petra_station_data
    person: petra
    kind: persuade
    mission: fix_heatwave_overload
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40; after committed:petra_batch (Rachid as backup): 40 + 2 + 15 = 57
    opening: "Kwartierdata per trafo? Die heb ik. In de Molen. Maar daar mag ik niet zomaar aan."
    position: {text: "Terugleverdata gaat niet zomaar het huis uit. Ook niet naar Netstrategie.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Teruglevering per adres is persoonsgegevens. Wie welk dak heeft, wanneer hij thuis is. Ik ben voorzichtig, en dat hoor ik ook te zijn.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [reflect, show_data]   # 2026-10-16 (1.6c, route variety): facts; the feeling named, or her own summer numbers, open it; comfort does not
        lead_in: {text: "Het irriteert me, als ik eerlijk ben. En als ik het doe…", tags: [feeling]}
        text: "…ben ik er weer alleen voor. Elke zomer dezelfde vraag, en dan trekt Petra de lijsten. Tot ik ziek ben. Dan heeft niemand ze."
        tags: [admission]
        unlocks: {facts: [heard:petra_privacy], proposals: [standing_query_rachid_too]}
    reframe: "Vanuit de mensen achter dat trafohuisje? Die zitten zonder stroom op de warmste dag van het jaar. Omdat ik mijn lijst niet wilde delen. Nee. Zo bedoel ik het niet."
    warning: "Als het over privacy gaat: daar doe ik niet aan mee."
    data: ["heatwave_overload:0", "heatwave_overload:4"]
    proposals:
      - {id: per_station_only, addresses: [interest], label: "Alleen opgeteld per station", say: "Alleen opgeteld per station, nooit per adres.", reply: "Per station. Dat mag. Dat is netbeheer, geen nieuwsgierigheid."}
      - {id: standing_query_rachid_too, hidden: true, addresses: [concern], label: "Eén vaste query, die Rachid ook kan draaien", say: "Wat als we er één vaste query van maken, per station, die Rachid ook kan draaien, en die elke week vanzelf de tien zwaarste stations laat zien?", reply: "Vanzelf. En Rachid kan het ook. Dan is het geen Petra-klus meer."}
    experiments:
      - {id: one_summer_list, addresses: [concern], label: "Eén lijst voor deze zomer, samen", say: "Eén lijst voor deze zomer, samen gemaakt. Daarna beslis jij of het een vaste query wordt.", reply: "Samen, en ik beslis. Goed."}
    co_proposal: {id: standing_query_rachid_too, text: "Als de privacy-officer ernaar kijkt, maak ik hem vandaag nog. En ik leer Rachid hem draaien."}
    outcomes:
      commitment: "Klopt. Per station, elke maandag. En als iemand per adres wil, zeg ik nee. Met jouw handtekening erbij."
      partial: "Ik wil het wel. Als het per station blijft."
      heard: "Je vroeg wat ik bedoelde met voorzichtig. Fijn."
      compliance: "Prima. Je krijgt je lijst. Eén keer."
      ruined: "Dan vraag je het maar aan de Molen zelf."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 > empathy +6 77 (lead-in, cue)
    #        > reflect, or show_data (her own summer lists) > 81 capped (concern) > propose standing_query_rachid_too +8 89 > ask (8 moves)
    # 2026-10-16 (1.6c, route variety): comfort (empathy) no longer opens it: Petra wants the irritation named or the numbers on the table.
    # Path: needs heard:petra_alone or the Rachid backup from Act I to read naturally; without it, Rachid's name is replaced by "een collega".
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses). Route re-checked by the simulator (audit §4.4).

  - id: femke_map
    person: femke
    kind: persuade
    mission: fix_stale_capacity_map
    owns: stale_capacity_map
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40; after committed:femke_triage: 40 + 3 + 15 = 58
    opening: "Je komt voor de kaart. Ik weet het. Die ondernemer heeft de krant gebeld."
    position: {text: "Zet de hele regio op rood. Dan vraagt niemand meer aan en hebben mijn mensen rust.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Elk kansloos onderzoek kost een analist een dag. Driekwart eindigt met nee. Koen werkt al weken tot zeven.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [reflect, empathy, inquiry]
        lead_in: {text: "Eerlijk gezegd vind ik het eng. Kijk…", tags: [feeling]}
        text: "Als ik groen zet en het blijkt vol, staat het in de krant. Met mijn naam, want ik teken de kaart. Rood is nooit fout. Rood is alleen… niet waar."
        tags: [admission]
        unlocks: {facts: [heard:femke_red], proposals: [map_with_a_date]}
    reframe: "Vanuit de wethouder? Die wil dat er bedrijven komen. Als alles rood is, komt er niemand meer. Ook niet waar het wel kan. Hm."
    warning: "Ik heb drie onderzoeken openstaan."
    data: ["stale_capacity_map:0", "stale_capacity_map:2"]
    proposals:
      - {id: all_red, addresses: [interest], label: "De hele regio op rood", say: "Goed: de hele regio op rood.", reply: "Rust. Ja. … Tot de wethouder belt dat er geen bedrijf meer wil komen."}
      - {id: quick_scan_first, addresses: [interest], label: "Eerst een snelle check van tien minuten", say: "Een snelle check van tien minuten bij de aanvraag, voordat het volle onderzoek begint.", reply: "Tien minuten. Die doen we eigenlijk al, in ons hoofd."}
      - {id: map_with_a_date, hidden: true, addresses: [concern], label: "Een kaart met een datum", say: "Wat als de kaart na elk onderzoek vanzelf wordt bijgewerkt, met de datum erbij: 'stand van 3 oktober'? Dan is hij niet fout. Hij is van een dag.", reply: "Met een datum. Dan teken ik niet voor de toekomst, alleen voor vandaag. Dat kan ik."}
    experiments:
      - {id: one_area_weekly, addresses: [concern], label: "Eén gebied, drie maanden, elke week bij", say: "Eén gebied, drie maanden: de kaart elke week bijgewerkt, met de datum erbij.", reply: "Eén gebied. Het bedrijventerrein. Daar bellen ze het meest."}
    co_proposal: {id: map_with_a_date, text: "En zet erbij wat iemand kan als het rood is. Flex, wachten, delen. Dan is rood geen deur dicht."}
    outcomes:
      commitment: "Dat past. Elke vrijdag de kaart, met een datum. En Koen gaat om vijf uur naar huis."
      partial: "Ik wil het wel. Als ik niet teken voor wat er over een jaar is."
      heard: "Fijn dat je vroeg waarom rood zo verleidelijk is."
      compliance: "Ik werk hem bij. Als ik eraan toekom."
      ruined: "Dan zet ik hem op rood. Dan klopt hij tenminste nooit verkeerd."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman) 65 > capped 64 (interest) > reflect +10 74 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose map_with_a_date +8 89 > ask (7 moves)
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).

  - id: marco_overtime
    person: marco
    kind: persuade
    mission: fix_monteur_hours
    owns: monteur_hours
    patience: 10
    # start: cynic 30 + 0 + 0 + 0 + 0 = 30; with Act I's commitment and the day-100 check-in lifted: 57
    opening: "Twee vacatures, een halfjaar, nul sollicitanten. Heel Nederland zoekt monteurs. Ik vind ze niet."
    position: {text: "Laat het MT vier uur overwerk per week goedkeuren. Ze verdienen er goed aan en het gat is dicht.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [paraphrase, inquiry], text: "Het werk moet gebeuren. Ik kan geen mannen bijmaken. Overwerk is het enige wat ik heb.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [perspective, empathy]   # 2026-10-16 (1.6c, route variety): fairness x1.5 on perspective; he opens when someone looks from his men's kitchen table
        lead_in: {text: "En eerlijk is eerlijk… jij zit niet aan hun keukentafel.", tags: [hesitation], tell: fairness}
        text: "Mijn mannen rekenen erop. Sem heeft net een huis gekocht. Ricardo's vrouw werkt parttime. Dat overwerk is hun hypotheek. Als ik zeg 'we gaan efficiënter werken', horen zij: minder geld."
        tags: [admission]
        unlocks: {facts: [heard:marco_mortgages], proposals: [paid_hour_for_training]}
    reframe: "Vanuit de jongen die om zeven uur in de rij bij het magazijn staat? Die is monteur geworden om te monteren. Niet om te wachten. Ja."
    warning: "Jij gaat me niet vertellen dat mijn mannen langzaam zijn."
    data: ["monteur_hours:2", "monteur_hours:4"]
    lines:
      open_question:
        lands: {text: "Kijk. Kantoor krijgt een vaste werkweek. Mijn mannen krijgen 'flexibiliteit'. Zo heet dat dan.", tags: [claim], tell: fairness}
    proposals:
      - {id: approve_overtime, addresses: [interest], label: "Vier uur overwerk per week", say: "Vier uur overwerk per week, voor iedereen.", reply: "Dank je. Voor nu."}
      - {id: kitting_overnight, addresses: [interest], label: "Het materiaal 's avonds klaargezet", say: "Het magazijn zet het materiaal de avond ervoor klaar, per klus.", reply: "Dan sta ik niet meer in de rij. Mooi. En dan?"}
      - {id: paid_hour_for_training, hidden: true, addresses: [concern], label: "Het vrije uur: betaald opleiden", say: "Wat als het uur dat vrijkomt geen minder uur wordt, maar een betaald uur om de nieuwe jongens op te leiden? Dan blijft het loon, en heb je over een jaar meer mannen.", reply: "Betaald opleiden. Dan hoeft niemand naar huis met minder. En over een jaar heb ik er misschien twee bij. Ja."}
    experiments:
      - {id: keep_overtime_a_quarter, addresses: [concern], label: "Het overwerk blijft een kwartaal, en we meten", say: "Een kwartaal blijft het overwerk zoals het is, en wat er vrijkomt meten we samen. Daarna beslist de ploeg.", reply: "De ploeg beslist. Dan kan niemand zeggen dat het hem is afgepakt."}
    co_proposal: {id: paid_hour_for_training, text: "Als het uur betaald blijft, wil ik dat Ahmed de nieuwe jongens meeneemt. Die kan het. Henk heeft het hem geleerd."}
    outcomes:
      commitment: "Kijk. Dat zeg ik zelf bij de koffie. Niet in een mail."
      partial: "Als niemand er een euro op achteruitgaat. Anders niet."
      heard: "Je vroeg naar hun hypotheek. Dat had ik niet verwacht van iemand van kantoor."
      compliance: "Geen overwerk. Leg jij het hun hypotheek maar uit."
      ruined: "Zie je. Efficiënter. Wie betaalt dat na?"
    # route (start 30): mood +8 38 > open question +6 44 > paraphrase +7 51 (heard) > inquiry +8 59 (interest) > empathy +6 65
    #        > show_data +15 (cynic) 80 > capped 81 > open question (lead-in, cue) > perspective ("Vanuit Sem, met zijn nieuwe huis?") > 81 (concern)
    #        > propose paid_hour_for_training +8 89 > ask (9 moves)
    # 2026-10-16 (1.6c, route variety): "jij zit niet aan hun keukentafel": only looking from his men's side (Ander perspectief) draws it out.
    # Path: agreed:marco_overtime:paid_hour_for_training is read by tier 3's train_the_trainer (needs_discount, one more `any` branch).
    #   The co-proposal names Ahmed only when chose:knowledge_drain:twi_job_instruction or skills_matrix_buddy is set; else "de beste van mijn ploeg".
    # 2026-10-16 (four-tier audit §4): interest via [open_question, inquiry, paraphrase] -> [paraphrase, inquiry] (cynic). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (1.6c, route variety): open questions land with a claim about who carries the gap, so Samenvatten and Doorvragen have something to answer.

  - id: linda_klic
    person: linda
    kind: persuade
    mission: fix_klic_expired
    owns: klic_expired
    mood: moe
    patience: 9                            # overloaded 10 - 3 - 2 = 5; +4 authored, as in Act I
    # start: overloaded 35 - 10 + 0 + 0 + 0 = 25; after committed:linda_replanning (Act I): 25 + 2 + 15 = 42
    opening: "Weer een klus terug. KLIC verlopen. Dat is de derde deze week."
    position: {text: "De graafmelding is van Werkvoorbereiding. Planning heeft al genoeg.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [empathy, mood, open_question], text: "Als ik er de graafmeldingen ook nog bij krijg, plan ik 's avonds niet alleen om, maar ook nog na.", tags: [claim, feeling]}
      - id: concern
        at: 66
        via: [reflect, empathy]
        lead_in: {text: "Sorry, daar word ik echt zenuwachtig van. En een graafmelding…", tags: [feeling]}
        text: "…is geen planning. Als ik er één vergeet en er wordt een kabel geraakt, is dat geen gemiste afspraak. Dan ligt er iemand. Dat wil ik niet op mijn bord. Niet nog iets wat ik 's nachts moet onthouden."
        tags: [admission]
        unlocks: {facts: [heard:linda_klic], proposals: [klic_automatic_at_planning]}
    reframe: "Vanuit de monteur die bij de sleuf staat met een melding van drie maanden oud? Die rijdt terug. Of hij graaft toch. Nee. Dat wil ik ook niet."
    warning: "Sorry. Het kaartenhuis."
    data: ["klic_expired:3", "klic_expired:2"]
    lines:
      confront: {say: "Jullie plannen gewoon klussen zonder te kijken of er een melding is."}
    proposals:
      - {id: planning_does_klic, addresses: [interest], label: "Planning doet de melding vlak voor de klus", say: "Planning doet de graafmelding vlak voor de klus.", reply: "Nog een taak. Op mijn bord."}
      - {id: klic_automatic_at_planning, hidden: true, addresses: [concern], label: "De melding gaat vanzelf als de klus vastligt", say: "Wat als de melding vanzelf wordt aangevraagd zodra de klus vastligt, en de monteur 's ochtends ziet of hij geldig is? Dan hoeft niemand het te onthouden.", reply: "Vanzelf. Met een rood lampje als hij verlopen is. Dan is het niet mijn geheugen."}
    experiments:
      - {id: expiry_signal_both, addresses: [concern], label: "Een signaal voor allebei, twee dagen vooraf", say: "Een signaal twee dagen voordat een melding verloopt, voor Werkvoorbereiding én Planning.", reply: "Voor allebei. Dan zijn we met z'n tweeën."}
    co_proposal: {id: klic_automatic_at_planning, text: "En laat het systeem de klus blokkeren als de melding niet geldig is. Dan kan niemand per ongeluk gaan graven."}
    outcomes:
      commitment: "Afgesproken. En ik ga vanavond om vijf uur naar huis."
      partial: "Ik doe mee. Als het niet mijn geheugen wordt."
      heard: "Dank je. Je vroeg waarom, niet wie."
      compliance: "Prima. Nog een regel in het kaartenhuis."
      ruined: "Dus Planning vergeet het. Fijn. Zet het maar op mijn bord."
    # route (start 25): mood +12 (overloaded x1.5) 37 > open question +6 43 > paraphrase +7 50 (heard, interest) > reflect +10 60
    #        > empathy +6 66 (lead-in, cue) > silence +12 > 75 capped (concern) > propose klic_automatic_at_planning +8 83 > ask (8 moves)
    # Safety line: the temptation 'dig anyway' (now Ruben's voice, T5) never pays. Her concern is the reason why.
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [open_question, paraphrase, inquiry] -> [empathy, mood, open_question] (overloaded). Route re-checked by the simulator (audit §4.4).
```

### 3.9 Act III walk-around check-ins (Merijn's decision on the meter)

The same shape as the Acts 0–II scripts §8.1: the trigger is passing someone whose morale is below 45, the low energy bar shows above them, patience is 7, the outcome is *opgebeurd*, and the reward is small (morale +10, trust +3, sometimes an observation). Walking past costs nothing (CLAUDE.md, "Respect the player's time"). Each of the three has a worry from Act III's pressure, not from a mission's problem: night shifts, a new analyst checking everything three times, a young father on call.

```yaml
dialogs:
  - id: wendy_night
    person: wendy
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, time_of_day: night, after_mission_open: first_kpi_review}
    patience: 7
    # start: craftsman 40 + 0 + 0 + 0 - 1 = 39, Op z'n hoede
    opening: "Drie uur 's nachts en jij loopt hier rond. Dan ben je óf nieuw, óf je slaapt slecht. Thee?"
    position: {text: "Rustig. De wand is groen. Ik zit hier al achtentwintig jaar; dit is mijn huiskamer.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [open_question, inquiry], text: "Vroeger deed ik de nacht op de automatische piloot. Nu tel ik de uren tot zeven.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [silence, reflect, empathy]
        lead_in: {text: "De bedrijfsarts…", tags: [hesitation]}
        text: "…zegt dat ik moet stoppen met nachten. Mijn lichaam weet niet meer welke dag het is. Maar als ik stop, wie leert de jonge operators dan wat de wand 's nachts doet? Dat staat nergens. Dat zit hier."
        tags: [admission]
    outcomes:
      lifted: "Weet je wat. Volgende maand neem ik een van de jongens mee in mijn nachten. Eén maand. Dan zit het niet alleen meer in mijn hoofd, en dan kan ik stoppen zonder dat het weg is."
      heard: "Dank je voor de thee. Ook al was het mijn thee."
      none: "Rustig. De wand is groen."
    observation: {text: "Wendy moet van de bedrijfsarts stoppen met nachten. Wat zij 's nachts weet, staat nergens.", plants: fix_shift_handover, needs: {none: ["done:fix_shift_handover"]}}
    # route: open question +6 45 (interest) > reflect +10 55 > inquiry x1.5 +12 (craftsman) 67 (lead-in, cue) > silence +12 > 74 capped (concern)
    #        > empathy +10 (after an admission) 84 > close: opgebeurd (6 moves)
    # Evidence: night-shift health advice from an occupational physician is common practice (Arbeidstijdenwet: extra rules for night work);
    #   no number is claimed. Same knowledge-drain theme as Henk, without a deadline: it is a check-in, not a mission.

  - id: koen_late
    person: koen
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, time_of_day: evening, after_mission_open: fix_escalation_hallway}
    patience: 7
    # start: overloaded 35 + 0 + 0 + 0 - 1 = 34, Op z'n hoede
    opening: "O. Ik dacht dat iedereen weg was. Ik reken deze nog even na."
    position: {text: "Gaat goed. Druk, maar goed.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [empathy, mood, open_question], text: "Vandaag zes vragen beantwoord en nul studies afgemaakt. Morgen weer.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, empathy]
        lead_in: {text: "Ik ben eigenlijk best bang, denk ik. Femke zei…", tags: [feeling]}
        text: "…dat ik het goed doe. Maar ik reken alles drie keer na. Als ik er één keer naast zit, gaat er een wijk op slot die niet op slot hoefde. Of andersom. Dat denk ik dan. Hier. Om half acht."
        tags: [admission]
    outcomes:
      lifted: "Misschien vraag ik Femke morgen om een kwartier. Eén studie samen. Dan weet ik of drie keer nodig is, of dat twee ook zeker genoeg is. En nu ga ik naar huis."
      heard: "Eigenlijk fijn dat iemand het vraagt."
      none: "Gaat goed. Echt."
    observation: {text: "Koen rekent alles drie keer na. Niemand heeft hem verteld wat goed genoeg is.", plants: fix_escalation_hallway, needs: {none: ["done:fix_escalation_hallway"]}}
    # route: mood +12 (overloaded x1.5) 46 (interest) > reflect +10 56 > empathy +6 62 > inquiry +8 (within 10 of 65) 70 (lead-in, cue)
    #        > silence +12 > 74 capped (concern) > close: opgebeurd (6 moves)
    # The lifted line ends with him going home: the talk lifts him, it does not keep him at work.
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [mood, open_question, paraphrase] -> [empathy, mood, open_question] (overloaded). Route re-checked by the simulator (audit §4.4).

  - id: ruben_tired
    person: ruben
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, after_mission_open: fix_cause_unknown}
    mood: moe
    patience: 7
    # start: craftsman 40 - 10 + 0 + 0 - 1 = 29, Op z'n hoede
    opening: "Even koffie. Toch? Twaalf uur wakker, snap je."
    position: {text: "Gaat wel. Drukke nacht gehad.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [inquiry, open_question], text: "Drie meldingen, tussen twee en vijf. De baby sliep. Ik niet.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, empathy]
        lead_in: {text: "Ik ben gewoon op, snap je. Mijn vriendin zei gisteren…", tags: [feeling]}
        text: "…'je bent er wel, maar je bent er niet.' Thuis ben ik moe. Hier ben ik moe. En als ik zeg dat ik moe ben, denken ze dat ik het niet aankan. Dus zeg ik het niet."
        tags: [admission]
    outcomes:
      lifted: "Weet je wat. Ik vraag Inge of we volgende week ruilen. Dat mag gewoon, eigenlijk. Ik had het nooit gevraagd."
      heard: "Thanks. Even gezeten. Dat scheelt."
      none: "Gaat wel. Even koffie."
    observation: {text: "Ruben slaapt in blokjes van drie uur, thuis en in de consignatieweek. Hij zegt het niet hardop.", plants: prep_storm_week, needs: {none: ["done:prep_storm_week"]}}
    # route: mood +8 (tired) 37 > open question +6 43 > paraphrase +7 50 (interest; the position is a claim) > reflect +10 60
    #        > inquiry x1.5 +12 (craftsman, within 10 of 65) 72 (lead-in, cue) > silence +12 > 74 capped (concern) > close (7 moves = patience)
    # A shorter route: mood > mood (tired: +8 both) 45 (interest) > reflect 55 > inquiry 67 (lead-in) > silence 74 (concern) > close (6 moves).
    # No spoiler: ruben_storm (prep_storm_week) keeps its own admission (the drive home). This one is about home, not the road.
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [mood, paraphrase, open_question] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
```

---

## 4. The coaching script: `coach_intake_lead` (Sanne)

Rother's five questions, three sessions (catalogue C7). The moves are `inquiry` and `open_question` with fixed lines, as in tier 3's Joost script. Asking out of order or answering for her "teaches but does not count" (tier-2 draft §2.13). Sanne's answers grow; the player sees her learn in her words.

**Sanne's own experiment** (`npc_experiment`, as drafted in tier 2): she chooses it in session 1 and runs it.

| Question (player) | Session 1: Sanne | Session 2 | Session 3 |
|---|---|---|---|
| 1. "Wat is je doelsituatie?" | "Dat we niet meer het postkantoor zijn." | "Negen op de tien aanvragen in één keer compleet. Voor de zomer." | "Negen op de tien compleet. En dat mijn team het zelf ziet als het zakt, zonder dat ik het zeg." |
| 2. "Hoe is het nu?" | "Beter dan vorig jaar. Denk ik." *(silence)* "… Ik weet het eigenlijk niet precies." | "Zeven op de tien. Ik heb het geteld, op het bord." | "Acht op de tien. Vorige week negen, deze week zeven: de installateurs uit Havenzij vullen het vermogen nog steeds verkeerd in." |
| 3. "Welke obstakels houden je tegen? Welke pak je nu aan?" | "De klanten." *(the player waits)* "… Nee. Wat de klant niet weet, vraagt het formulier niet." | "Dat installateurs het formulier anders invullen dan klanten. Die pak ik aan." | "Dat ik nog steeds degene ben die het bord bijhoudt." |
| 4. "Wat is je volgende stap, en wat verwacht je?" | "Een voorbeeld bij het vermogensveld. Ik verwacht… minder terugsturen?" "Hoeveel minder?" "Vijf per week." | "Een apart invulscherm voor installateurs. Ik verwacht dat het vermogen dan bijna altijd klopt." | "Kim houdt het bord een maand bij. Ik verwacht dat het blijft werken als ik er niet ben." |
| 5. "Wanneer kunnen we zien wat je ervan leerde?" | "Volgende week dinsdag." | "Over twee weken." | "Over een maand. Als ik terug ben van vakantie. Ik ga voor het eerst in drie jaar twee weken weg." |

**The temptation in a session:** Sanne, in session 2: "Zeg nou gewoon wat jij zou doen." Answering voids the session. The decline line: "Wat denk jij dat de volgende stap is, en wat verwacht je dat er gebeurt?" Her beat after the third session (from the draft): "Ik dacht dat jij het antwoord had. Je vroeg alleen maar. Dat was irritant, en het werkte."

**Path.** A player who earned Sanne's commitment in Act I (`sanne_checker`) and Act II (`sanne_kpi`) meets her at team trust +1; the trust gate is met already. Without that history the mission waits for intake trust ≥ 1 (catalogue gate), which the board and a repair can earn. D23 *Zelf coach* can be earned here, and D43 *De cirkel* (engagement loop) when Sanne later coaches Kim.

---

## 5. Expert talks: openings and closings

The topics stay as drafted (tier-2 draft §4.1 and §4.2). Only the voice around them is new.

```yaml
dialogs:
  - id: thomas_congestion_map
    person: thomas
    kind: expert
    mission: sector_congestion_map
    opening: "Drie ondernemers vandaag. Alle drie zagen rood op de kaart en willen toch uitbreiden. Ga zitten; dit kost een koffie."
    topics_ref: "tier2-missions-draft §4.1"     # capaciteitskaart, alternatieve_transportrechten, gotork
    closing: "Het lastige is dat de klant de kaart als eerste ziet. Als die niet klopt, beginnen we elk gesprek met een achterstand. Zeg dat maar tegen Femke. Vriendelijk."

  - id: jeroen_regulation
    person: jeroen
    kind: expert
    mission: talk_regulation
    opening: "Een kwartier. Iedereen noemt de ACM als het misgaat, niemand weet wat ze eigenlijk doet. Vraag maar."
    topics_ref: "tier2-missions-draft §4.2"     # acm_toezicht, energiewet, compensatieregeling
    closing: "Onthoud één ding: de klok loopt vanaf de aanvraag. Niet vanaf het moment dat wij hem compleet vinden. Wie dat vergeet, legt het later uit aan de ACM."
```

Jeroen's closing plants the `acm_visit` temptation's counter-argument (the late clock), which the draft's §4.2 already marks as defusing it.

---

## 6. Facts these dialogs set, and who reads them

| Fact | Set by | Read by |
|---|---|---|
| `committed:frank_red_numbers` | Frank shows the red number himself | `t2_first_okr`: the reinforcement KR is offered even if the watermelon temptation was once accepted (a person repaired it); Frank's OKR beat. |
| `committed:joost_board`, `heard:joost_old_board` | Joost takes the old board down | `repair_escalation_hallway` variant; tier 3's `joost_wip` start (+15 memory). |
| `heard:ruben_blame`, `committed:ruben_cause` | Ruben at the Pareto | `ruben_storm` start; D3-style trust; tier 4's maintenance Pareto (`maintenance_calendar`) trusts the cause data. |
| `committed:inge_standby` (north volunteer) | Rick joins on-call | Tier 3's crew strategy: the outage option needs fewer people (a forecast detail). |
| `committed:gert_contractor` | Gert's photo before backfill | Tier 3's `one_dig_agreements` (alongside `done:fix_contractor_rework`): a trusted contractor. |
| `committed:acm_inspector` | The ACM's trust | Tier 3's `acm_pilot_time_bound` (an extra `any` branch, so a failed visit plus an honest talk can still reopen it: Q6). |
| `flag:rest_rule` (`committed:ruben_storm`) | A rest rule for on-call | Tier 3's `overtime_push` aftermath halved; D27. |
| `committed:petra_station_data` | A standing station query | Tier 3's `fix_household_rush` (the station load is known; `heat_pump_check` gets a better forecast), tier 4's sensor option. |
| `agreed:marco_overtime:paid_hour_for_training` | Marco's paid training hour | Tier 3's `train_the_trainer` (`needs_discount`). |
| `committed:nicole_lmra` | "Veilig gestopt" as good work | D28 *Eerst veilig, dan beter*; tier 4's NTA 8120 audit (a safety culture finding). |
| `committed:femke_map` | A map with a date | Tier 3's `fix_non_firm_unused` (flex options shown on the map). |
| `committed:koen_24h` | Answers or dates in 24 h | The escalation fix's sustain (a committed owner ×1.25). |
| `committed:brouwer_third_outage` | The care home's trust | Tier 3's `fix_priority_first_come` (De Linde's manager starts higher). |

---

## 7. Self-check

As in the Acts 0–II scripts §9: layers in range, a lead-in, ≥ 2 `via` moves, ≥ 2 options that address the concern, and the listening route within patience.

| Dialog | interest.at | concern.at | Concern options | Route / patience |
|---|---|---|---|---|
| frank_red_numbers | 52 | 72 | 2 | 9 / 10 |
| joost_board | 55 | 72 | 3 | 8 / 10 |
| ruben_cause | 50 | 70 | 2 | 8 / 9 |
| brouwer_third_outage | 45 | 66 | 2 | 9 / 10 |
| inge_standby | 55 | 72 | 2 | 8 / 10 |
| wendy_handover | 55 | 70 | 2 | 7 / 10 |
| gert_contractor | 55 | 70 | 2 | 8 / 10 |
| marco_contractor | 55 | 70 | 2 | 9 / 10 |
| koen_24h | 50 | 68 | 2 | 7 / 9 |
| acm_inspector | 52 | 72 | 2 | 9 / 10 |
| dirk_reorder | 55 | 70 | 2 | 8 / 10 |
| nicole_lmra | 52 | 72 | 2 | 8 / 10 |
| ruben_storm | 55 | 70 | 2 | 7 / 10 |
| petra_station_data | 55 | 72 | 2 | 8 / 10 |
| femke_map | 55 | 72 | 2 | 7 / 10 |
| marco_overtime | 55 | 72 | 2 | 9 / 10 |
| linda_klic | 45 | 66 | 2 | 8 / 9 |
| wendy_night (check-in) | 45 | 65 | n/a (lifted) | 6 / 7 |
| koen_late (check-in) | 45 | 65 | n/a (lifted) | 6 / 7 |
| ruben_tired (check-in) | 45 | 65 | n/a (lifted) | 6 / 7 |

The same caveat applies as in the Acts 0–II scripts: the builder runs the spec's §9.3 breadth-first search ("no golden path": ≥ 3 distinct successful sequences) on these blocks first.

---

## 8. Decisions (by the standing rule, 2026-10-15)

Merijn's standing rule (PLAN.md Decisions, 19860ac): every open question in these docs takes the recommended option. The seven below are decided that way and logged here so Merijn can overrule any of them.

1. **The care home. Decided (a):** one care home, De Linde, hit by the cable strike in Act II and by repeat faults in Act III. *A coincidence becomes a callback, and mevrouw Brouwer gets a voice.* (Rejected: (b) keep De Lindehof as a second care home.)
2. **The contractor. Decided (a):** Gert Peeters of Grondwerk Peeters, the Act II contractor, starting from his Act II outcome. *Respect in Act II pays in Act III.* (Rejected: (b) Erik Smits of Grondwerk Zuid as a new contractor.)
3. **The outage fork's faces. Decided (a):** B is Esra's (night complaints from the north), N is Kees's (the handover). *A fork is two people asking for your time.* (Rejected: (b) Kees in both.)
4. **Temptations from named people where they fit. Decided (a):** Dirk, Ruben, Frank; the IT manager and Inkoop stay roles. *A shortcut from a colleague has a reason, and the dialog surfaces it.* (Rejected: (b) all roles.)
5. **A talk with the ACM inspector at the milestone. Decided (a):** it changes the verdict's wording, the recovery mission's tone and a later fact, never the measure. (Rejected: (b) the milestone stays a number.)
6. **An honest ACM talk reopening the pilot. Decided (a):** `committed:acm_inspector` adds an `any` branch to `acm_pilot_time_bound`, so a failed visit plus an honest talk can still reopen it; the reputation loss stays. (Rejected: (b) the door stays closed, as the catalogue has it.)
7. **Sanne's coaching script ends with her first holiday in three years. Decided (a):** the sign that the improvement no longer depends on her is a person resting. (Rejected: (b) a neutral ending.)

Applied from Merijn's binding answers (2026-10-15): no dialect anywhere (the voice sheet §2 and every line here are standard Dutch); colleagues leave rarely (no dialog here ends in a departure); customers by phone in this tier (`brouwer_third_outage` is a call); the meter shows arrows, never numbers (the route comments' numbers are for the builder only); Act III walk-around check-ins added (§3.9).

---

## Sources

Method sources as in the dialog spec §12 (MORE PIES, Kotter & Schlesinger, Senge, Herscovitch & Meyer, Miller & Rollnick, Schein, Rother) and the Acts 0–II scripts. Sector facts as in the tier-2 draft's grounding (Nestor fault registration, contractor trench depth, KLIC, LMRA and the Safety Culture Ladder, ACM supervision and the connection term, the heatwave and solar feed-in, the capacity map).

Two facts used here and not in the tier-2 draft:
- **Aggregated smart-meter data for grid management.** A grid operator may use meter data for its legal tasks; consent is required for passing data to market parties (Kamerstuk 29023-202). *Verify* that weekly per-station aggregation of feed-in for load monitoring falls under the legal tasks before release; Netbeheer Nederland's use cases mention voltage monitoring through meter events.
- **On-call standby at home.** Standby rules at a grid operator follow its CAO and the Arbeidstijdenwet; the rest guarantee in `ruben_storm` is a proposal of the dialog, not a claim about current rules.
