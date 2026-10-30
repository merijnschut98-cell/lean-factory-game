# Tier-2 missions — content-ready drafts (Acts II–III)

> Status: drafts by the mission-design agent (2026-10-15), for Merijn to review. They are **not** in `content/` yet. Each block can be pasted into `content/missions.yaml`, `content/problems_tier2.yaml`, `content/countermeasures.yaml`, `content/concepts.yaml` and `content/people.yaml` once the schema of the catalogue design (`2026-10-15-mission-system-and-catalogue-design.md`, C1–C20) exists.
>
> Read with: `CLAUDE.md` §2 (the mission system decides the game; the three principles), the catalogue design §2–§3.5, `content/problems_tier1.yaml`, `content/countermeasures.yaml`, `content/value_streams.yaml`.

## 0. What this covers and how to read it

**Scope.**
- All 16 Act III (tier 2) missions of catalogue §3.5.
- The two Act II missions that open tier 2 and the congestion arc: `first_kpi_review` and `sector_congestion_map`.
- **Four additions** the catalogue lacked:
  - `fix_stale_capacity_map` (the capacity map and congestion);
  - `fix_monteur_hours` (the technician shortage);
  - `fix_klic_expired` (permits and KLIC);
  - `repair_escalation_hallway` (a worked repair quest).

That is **22 missions, 11 problems (8 from the catalogue + 3 new) and 36 countermeasures**.

**The three principles** (Merijn, 2026-10-15). Every mission names which ones it tests in `principles` (a proposed metadata field the debrief and score can read):
- `long_term`: long term outweighs short term in 95% of cases;
- `respect`: respect for people comes first;
- `improve`: always improve.

Where it fits, a mission carries a **temptation**: a short-term or people-unfriendly option that works now and costs later, through path dependence. The rare real exception is named where it applies: in `fix_lmra_tickbox`, safety containment comes first.

**Conventions.**
- Game text is Dutch; keys, ids and comments are English.
- Every number is sourced (title + URL in the grounding list under the block) or carries `estimate:` with its reasoning.
- Sources that could not be opened from this environment carry **(verify)**.
- Source check of 2026-10-15: pages could not be fetched directly from this environment, so the flagged sources were checked against search extracts of the primary site (ACM, KNMI, Kadaster, IEC, TenneT, Netbeheer Nederland, Stedin, LEI, ASQ, re:Work, NEN). Where that confirmed the claim, the flag is gone; corrections are noted inline.
- Effects use **only today's effect properties** (`tools/build_content.py` `EFFECT_PROPERTIES`). Each problem and countermeasure block was run through `validate_problems`, `validate_countermeasures` and `_check_problem` against today's network (see §5).
- Rewards follow the catalogue (§2.13 rescaled belts: green = belt 2).
- `insights` (Ruud's Kata questions) appear on main missions only; the coach never coaches a side mission or a milestone.

### 0.1 Schema this draft assumes (beyond today's)

From the catalogue design (C1, C2, C4–C7, C10, C11, C19, C20):
- mission fields: `act`, `chapter`, `arc`, `beats`, `fork`, `debrief_first`, `reopen`, `opens_on`, `fail_opens`, `fail_effects`, `event`, `recurring`, `sets_flags`;
- `requires`: `maturity`, `trust`, `any_of`, `facts`;
- rewards: `reputation`, `trust`, `unlocks`;
- countermeasures: `needs`;
- goal types: `routine`, `measure`, `okr`, `kpi_review`, `talk_to`, `coach`, `strategy`, `rework_fix`.

**New in this draft:**

| Field | On | Meaning | Why |
|---|---|---|---|
| `principles` | mission | list of `long_term`, `respect`, `improve` | the directive: the debrief names what was tested |
| `temptations` | mission | `[{id, who, when, text, accept, decline, accept_sets_flags, accept_effects}]`: a person offers a shortcut in a beat; accepting applies the effects and sets the flags | short-term or people-unfriendly options whose cost shows later through facts |
| `event.extra_if_open` | mission | effects added during the event window only if the mission is not completed when the event starts | storm and heat: preparation matters without a second problem |
| `trust` | countermeasure | `{pool: n}` applied when the Act chooses it | people-unfriendly fixes cost trust at once |
| `aftermath` | countermeasure | `{after_days, days, effects, cost, trust, reputation}`: delayed consequences while it runs | the cost of a short-term fix shows up later, as Merijn asked |
| `containment` | countermeasure | `true`: may run next to the A3's countermeasure, decays by design, scores as containment, not as the fix | the safety exception: contain now, solve the cause next |
| `npc_experiment` | mission (coach goal) | the coached person's own small countermeasure | catalogue C7 names it; this gives it a shape |
| `key_results_menu` + `pick` | okr goal | the player chooses KRs from a menu | choosing a leading KR is the lesson; an output KR is the temptation |

**Effect properties:** none new are required. Optionally, a `rework_wait_days` effect property would model `escalation_hallway` and `klic_expired` more faithfully. Today they use `ftr` on the step and the step's own rework wait.

### 0.2 Corrections to the catalogue design found while grounding

1. **Time-bound transport right.** GDD/§3.6 say "≥85% availability at about half the tariff". The *tijdsduurgebonden transportrecht* (TDTR) gives transport in at least 85% of the hours a year; in the other 15% TenneT may limit transport, announced at least a day ahead. It exists only for large customers on TenneT's high-voltage grid: ACM code decision of July 2024 (https://www.acm.nl/nl/publicaties/codebesluit-alternatieve-transportrechten), first contract with GIGA Storage in September 2024, offering it compulsory for TenneT from 1 Oct 2025 (TenneT, https://www.tennet.eu/nl/de-elektriciteitsmarkt/aansluiten-op-het-nederlandse-hoogspanningsnet/tijdsduurgebonden-transportrecht-tdtr). Its discount is "up to 65%" on the transport tariff (TenneT), so "about half the tariff" is not far off, but it is not a regional (DSO) product. The ~50% discount on a regional grid belongs to the non-firm ATO (Dirkzwager, §2.16 grounding). The concept texts below use the corrected wording.
2. **OKR scoring.** §2.1 says "at least 0.7 of the key results met". With three binary KRs, that means all three. The OKR convention scores each KR 0.0–1.0 on progress and averages them, with 0.6–0.7 the sweet spot. The `okr` goal below uses a progress score per KR (linear from the quarter's start value to the target) and passes on an average ≥ 0.7.
3. **Shift handover step.** §3.5 puts `shift_handover` at `outages.locate`, the same step as `on_call_far`, the fork's bottleneck. The fork test needs the non-bottleneck's Check to say `not_constraint`, so `shift_handover` moves to `outages.report` (the control room, which has plenty of slack).
4. **The storm.** The Dutch LS and MS grids are almost entirely underground. A storm hits through fallen trees, water in substations and the remaining overhead lines in rural parts, and above all through a **flood of calls**. The storm mission's aha is built on that.
5. **The heatwave.** In the Netherlands the summer overload is mostly **solar feed-in on sunny afternoons (11–15 h)** in solar-heavy streets, made worse because a transformer can carry less when it is hot. Air-conditioning is not the main driver. The heat mission's twist is built on that.
6. **`sustain` goal name clash.** The working tree (another agent) adds `sustain {problem}`: "the fix back in use". The catalogue's `sustain {stream, kpi, op, target, weeks}` holds a KPI. No tier-2 draft uses either, but the two need different names (suggestion: `hold_kpi` for the catalogue's).

---

## 1. Act II bridge — the end of tier 1

### 1.1 `first_kpi_review` — Het eerste kwartaal (M)

Principle tested: **long_term** (a KPI review is for learning, not for looking good). Temptation: the "watermelon" report (green outside, red inside).

```yaml
missions:
  - id: first_kpi_review
    name: Het eerste kwartaal
    kind: main
    tier: 1
    act: 2
    chapter: Wat je meet
    requires: {missions: [fix_silo_kpis]}
    goal: {type: kpi_review, reviews: 1}
    principles: [long_term, improve]
    briefing: "Over twee weken zit het MT bij elkaar voor de eerste echte kwartaalreview op het nieuwe KPI-bord. Ruud wil geen presentatie: hij wil dat jij bij het bord vertelt wat je ziet, ook wat rood is. 'Een rood getal waar we van leren is meer waard dan tien groene die niemand begrijpt.'"
    debrief: "Je liet het MT zien waar het nog niet goed gaat en wat je daarvan leert. Ruud: 'Nu wordt het bord van ons allemaal. Volgend kwartaal wil ik dat de teams hun eigen problemen zien, niet dat jij ze moet vinden.'"
    beats:
      - {on: accepted, who: ruud, text: "Kies zelf welke getallen je laat zien. Maar kies ze omdat ze iets vertellen, niet omdat ze mooi zijn."}
      - {on: completed, who: ruud, text: "Hoofdstuk drie: Zichtbaar maken. Problemen moeten niet door jou gevonden worden; de teams moeten ze zien."}
    temptations:
      - id: watermelon_report
        who: thomas
        when: accepted
        text: "Tip van iemand die al vijftien kwartalen meedraait: laat de doorlooptijd van de netverzwaringen weg. Die is rood en daar kun jij toch niets aan doen. Dan ziet het bord er strak uit."
        accept: "Je laat de netverzwaringen weg."
        decline: "Je laat het rode getal staan en vertelt wat je ervan leert."
        accept_sets_flags: [flag:watermelon_review]
        accept_effects: {reputation: 3}   # the MT is pleased now...
    teaches: [kpi, leading_lagging, okr]
    rewards: {xp: 800, budget: 8000, reputation: 5, unlocks: [okr]}
    insights:
      go_see: "Welke getallen op het bord kijken vooruit, en welke vertellen alleen wat al gebeurd is?"
      understand: "Welk getal is rood, en weet je waarom? Weet het team waarom?"
      experiment: "Wat wil je dat het MT na de review anders doet? Welk getal laat dat volgend kwartaal zien?"
      reflect: "Als je volgend kwartaal alleen groen laat zien, wat leert het MT dan?"
```

**Path dependence.**
- `flag:watermelon_review`: later (C19 `needs`), `acm_visit`'s pass text changes. More importantly, `t2_first_okr` offers its "doorlooptijd netverzwaring" KR only with `none: [flag:watermelon_review]` *or* `done:lsw_kpi_review` (an honest review repairs it).
- The +3 reputation now is less than the honest path's later gains (rep +3 per flow-score ≥ 4 Check that the red number led to).

**Grounding.**
- Watermelon reporting and Goodhart: the existing `kpi_alignment` concept.
- Leading vs lagging: the existing `leading_lagging` concept.
- No sector numbers.

**Engrossing.** The first time the player stands at the board in front of the MT. The temptation comes from a likeable colleague and costs nothing visible. The cost arrives a quarter later, when the KR the MT needs is missing.

### 1.2 `sector_congestion_map` — De congestiekaart (S, sector arc)

Principle tested: **improve** (learn the instruments before you judge the queue).

```yaml
missions:
  - id: sector_congestion_map
    name: De congestiekaart
    kind: side
    tier: 1
    act: 2
    chapter: Het net is vol
    arc: sector
    requires: {missions: [talk_netplanner, fix_grid_study_queue]}
    goal: {type: talk_to, person: thomas, topics: 3}
    principles: [improve]
    briefing: "Thomas Visser van Grootzakelijke klanten heeft vandaag drie ondernemers aan de lijn gehad die op de capaciteitskaart 'rood' zagen en toch willen uitbreiden. Hij legt het je graag uit, als je de tijd neemt om te luisteren. Vraag hem naar de kaart, naar wat een klant kan als het net vol is, en naar capaciteit die niemand gebruikt."
    debrief: "Vol is niet altijd vol. Er bestaan contracten voor als het net niet altijd ruimte heeft, en capaciteit die niemand gebruikt kan terug. Thomas: 'Het lastige is dat de klant de kaart als eerste ziet. Als die niet klopt, beginnen we elk gesprek met een achterstand.'"
    beats:
      - {on: completed, who: femke, text: "Thomas heeft gelijk over die kaart. Wij werken hem met de hand bij, eens per kwartaal. Als we eraan toekomen."}
    teaches: [capaciteitskaart, alternatieve_transportrechten, gotork]
    rewards: {xp: 300, trust: {key_accounts: 1}}
```

People topics: §4.1 (`thomas`). Femke's beat plants `fix_stale_capacity_map` (§2.15).

**Engrossing.** The beat at the end turns a lesson into a lead: the map itself is wrong. The player now *wants* the side quest that opens in Act III.

---

## 2. Act III — Zichtbaar maken (tier 2)

Gates: `first_kpi_review`, maturity 2, belt green (2).

Chapters:
- **Het bord aan de muur:** daily boards and the side quests they surface;
- **Als het licht uitgaat:** cause_unknown, then the fork;
- **Samen bouwen:** contractor, escalation, KLIC;
- **Wie kijkt er mee?** the ACM, then the OKR.

Events through missions: the storm (winter) and the heat (summer).

### 2.1 `t2_daily_boards` — Het bord aan de muur (M)

Principles tested: **respect** (the team owns the board) and **improve**.

```yaml
missions:
  - id: t2_daily_boards
    name: Het bord aan de muur
    kind: main
    tier: 2
    act: 3
    chapter: Het bord aan de muur
    requires: {missions: [first_kpi_review], belt: 2, maturity: 2}
    goal: {type: routine, kind: dagstart, places: [connections.intake, connections.design, connections.planning], every_days: 2, times: 10}
    principles: [respect, improve]
    briefing: "Ruud heeft het MT beloofd dat Intake, Werkvoorbereiding en Planning voor de zomer elke ochtend een dagstart bij hun eigen bord houden. Sanne is enthousiast, Joost sceptisch ('weer een bord'), Linda vraagt wie dat bord dan bijhoudt. Help ze tien keer in drie weken een dagstart te houden die over het werk gaat en niet over jou."
    debrief: "Drie teams kijken elke ochtend naar hun eigen getallen en zeggen hardop wat hen hindert. Ruud: 'Nu zien zij de problemen eerder dan jij. Dat was het doel. Let op wat er gebeurt met de rode kaartjes die ze zelf niet kunnen oplossen.'"
    reopen: "De borden hangen er nog, maar de dagstarts zijn stilletjes gestopt. Sanne: 'Niemand kwam meer kijken, dus wij ook niet.'"
    beats:
      - {on: accepted, who: joost, text: "Weer een bord. Het vorige hangt nog in de gang, met de cijfers van 2023."}
      - {on: completed, who: linda, text: "Er hangen nu vier rode kaartjes die wij zelf niet kunnen oplossen. Wat doen we daarmee?"}
    temptations:
      - id: digital_dashboard
        who: it_manager
        when: accepted
        text: "Waarom papier? Ik zet de getallen automatisch op een scherm in de gang. Dan hoeft niemand iets bij te houden en ben je in een week klaar."
        accept: "Je laat IT een scherm ophangen en de dagstart vervalt."
        decline: "Je houdt het bord met de hand: wat het team zelf schrijft, ziet het ook."
        accept_sets_flags: [flag:dashboard_not_board]
        accept_effects: {complete_goal: true}   # done at once...
    teaches: [daily_management, visual_management, leader_standard_work]
    rewards: {xp: 1600, budget: 12000, reputation: 5}
    insights:
      go_see: "Wie schrijft de getallen op het bord, en wie leest ze? Als dat niet dezelfde mensen zijn, van wie is het bord dan?"
      understand: "Wat gebeurt er met een rood kaartje dat het team zelf niet kan oplossen?"
      experiment: "Wat verwacht je na tien dagstarts te zien: in de getallen, of in wat de teams hardop zeggen?"
      reflect: "Wat gebeurt er met het bord als jij een maand niet komt kijken?"
```

**Path dependence.**
- `flag:dashboard_not_board` completes the mission at once (the quick win). But the three teams then count as having **no** visual-management support (catalogue §2.8) until `lsw_gemba_round` has run three times at those places.
- `escalation_hallway` opens with *no* red cards to read: its depth-0 key clue moves to depth 1. Investigation is harder.

**Grounding.**
- Daily management (team boards, short daily stand-ups, leader routines): D. Mann, *Creating a Lean Culture* (book; no URL). Concept `daily_management` below.
- The counts are estimates: "10 times in 21 days" allows one missed day in each two-day window.

**Engrossing.** The mission ends with the board's first real output: red cards nobody can solve. That is the hook for `fix_escalation_hallway`. The temptation is the most realistic one in the act: a dashboard is what most organisations actually buy.

### 2.2 `fix_cause_unknown` — Oorzaak: onbekend (M, the data puzzle)

Principles tested: **long_term** (record and learn vs repair faster) and **respect** (ask the monteur, don't police him). Temptation: a mandatory field with a target on "% onbekend" (Goodhart).

```yaml
missions:
  - id: fix_cause_unknown
    name: "Oorzaak: onbekend"
    kind: main
    tier: 2
    act: 3
    chapter: Als het licht uitgaat
    requires: {missions: [t2_daily_boards]}
    goal: {type: solve, problem: cause_unknown}
    principles: [long_term, respect]
    briefing: "De directeur van zorgcentrum De Lindehof heeft Ruud een brief gestuurd: drie keer stroomuitval in een halfjaar, de laatste keer twee uur in het donker met bewoners aan de zuurstof. Volgens het storingssysteem was de oorzaak drie keer 'onbekend'. Ruud wil voor de volgende storing weten waarom het steeds dezelfde straten treft."
    debrief: "De storingen hebben weer een oorzaak, en de oorzaken hebben een patroon: een paar zwakke kabeltrajecten en één type mof. Die worden nu opgespoord voordat ze falen. De Lindehof heeft sinds je experiment geen storing meer gehad."
    reopen: "In het storingssysteem staat weer steeds vaker 'onbekend'. Kees: 'De Pareto hangt er nog, maar niemand bespreekt hem meer op maandag.'"
    beats:
      - {on: accepted, who: kees, text: "Wij zien op de videowand dezelfde trajecten steeds terugkomen. Maar ons werk stopt als het licht weer brandt."}
      - {on: completed, who: marco, text: "Mijn mannen vonden het fijn dat iemand eindelijk vroeg wat zij zagen."}
    temptations:
      - id: cause_target
        who: it_manager
        when: accepted
        text: "Simpel: ik maak het oorzaakveld verplicht en we zetten 'percentage onbekend' als KPI op het bord van de monteurs. Over een maand staat het op nul."
        accept: "Je laat het veld verplicht maken en rekent de monteurs af op het percentage onbekend."
        decline: "Je vraagt eerst de monteurs wat zij bij een storing zien en waarom ze 'onbekend' kiezen."
        accept_sets_flags: [flag:cause_field_policed]
        accept_effects: {trust: {monteurs: -1}}
    teaches: [pareto, root_cause, storingsregistratie]
    rewards: {xp: 1800, budget: 15000, reputation: 5}
    insights:
      go_see: "Wat zegt 'onbekend' je over hoe wij van een storing leren?"
      understand: "Als je de storingen niet op oorzaak kunt sorteren, waarop kun je ze dan wel sorteren?"
      experiment: "Welk getal laat over twee weken zien dat je experiment werkt: het aantal storingen, of het aandeel onbekend? Welke van de twee kijkt vooruit?"
      reflect: "Wie kijkt over drie maanden naar de Pareto, en wat doet hij dan met de hoogste staaf?"

problems:
  - id: cause_unknown
    tier: 2
    name: "Oorzaak: onbekend"
    step: outages.repair
    waste: defects
    severity: high
    visibility: hidden
    kpi: on_time
    symptoms:
      - Steeds dezelfde straten zitten zonder stroom, soms drie keer in een halfjaar.
      - In het storingssysteem staat bij bijna de helft van de storingen 'oorzaak onbekend'.
    root_cause: Bij het afmelden is de oorzaak een vrij veld met 'onbekend' als standaard, en niemand bekijkt herhaalstoringen. Zwakke kabeltrajecten en moffen worden telkens opnieuw gerepareerd in plaats van opgespoord en vervangen; er is geen terugkoppeling van storing naar werkwijze.
    plausible_causes:
      - De monteurs repareren slordig.
      - Het net is gewoon oud; alleen vervangen helpt.
      - Er zijn te weinig monteurs in de storingsdienst.
    mismatch_note: Sneller of zorgvuldiger herstellen helpt niet zolang niemand weet welke trajecten steeds opnieuw falen. Zonder oorzaak valt er niets te leren.
    countermeasures: {cause_codes_pareto: 1.0, repeat_fault_analysis: 0.9, stop_and_record: 0.7, mandatory_cause_field: 0.6}
    teaches: [pareto, root_cause, storingsregistratie]
    effects:
      # estimate: repeat faults on known weak sections add about 15% to the
      # outage arrivals (18 a week → ~21); Netbeheer Nederland's LS cause split
      # (2018: digging 27%, ageing 18%, latent faults 18%) leaves room for a
      # repeat-fault share of this size.
      - {target: outages, property: demand, value: 1.15}
      # estimate: one in twenty repairs hits a second weak spot on the same cable.
      - {target: outages.repair, property: ftr, value: -0.05}
    # estimate: ~2.7 extra outages a week x ~EUR 600 (a joint, 3 monteur-hours,
    # van) = ~EUR 1,600; compensation payments come on top for the few > 4 h.
    cost_per_week: 1600
    clues:
      - {tool: data, key: true, depth: 0, text: "Bij 41 procent van de storingen van het afgelopen jaar staat als oorzaak 'onbekend'. In elk overzicht is 'onbekend' de hoogste staaf."}
      - {tool: time_study, key: false, depth: 0, text: "Een kabelverbinding maken kost anderhalf uur, bij iedere monteur ongeveer even lang."}
      - {tool: documents, key: true, depth: 1, text: "Op het afmeldformulier is de oorzaak een vrij tekstveld. Wie niets invult, krijgt 'onbekend'. Nergens staat wie de oorzaken bekijkt."}
      - {tool: conversation, key: true, depth: 1, text: "'Om drie uur 's nachts na vier uur in de kou typ ik geen verhaal. Onbekend is één klik. En niemand heeft ooit gevraagd wat ik zag.'"}
      - {tool: data, key: true, depth: 1, at: outages.locate, text: "Drie op de tien storingen zijn op een kabel waar het afgelopen jaar al een storing was. Twaalf kabeltrajecten zijn samen goed voor bijna de helft van die herhaalstoringen."}
      - {tool: shadow, key: false, depth: 1, text: "De monteur werkt veilig en netjes en herstelt de storing volgens de werkinstructie."}
      - {tool: material_check, key: true, depth: 2, at: outages.joint, text: "In de bak met teruggebrachte oude moffen liggen veel moffen van hetzelfde type uit dezelfde jaren. Bij bijna allemaal is de afdichting gescheurd en zit er vocht in."}
      - {tool: conversation, key: true, depth: 2, at: outages.locate, text: "'Wij sluiten een storing af als het licht weer brandt. Wat er kapot was en of het terugkomt, vraagt niemand ons.'"}

countermeasures:
  - id: cause_codes_pareto
    name: Oorzaakcodes en een wekelijkse Pareto
    tier: 2
    category: visual_management
    description: Bij het afmelden kiest de monteur uit acht oorzaakcodes en maakt hij een foto van het kapotte onderdeel. Elke maandag bekijkt de storingsdienst bij het bord de Pareto per oorzaak en per kabeltraject; de hoogste staaf krijgt een A3.
    budget: 6000
    team_hours: {control_room: 10, monteurs: 20}
    decay_days: 60
    sustains: true   # a weekly board the outage team reads: it helps hold the stream's other fixes
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.97}   # estimate: weak sections from the base also found
  - id: repeat_fault_analysis
    name: Herhaalstoringen opsporen en trajecten vervangen
    tier: 2   # sim check fix 7: at tier 3 it fails the Check at maturity 2 (eff 0.45); at tier 2 eff 0.81
    category: quality
    description: Elke maand een lijst van kabeltrajecten met twee of meer storingen in een jaar. Netstrategie en Werkvoorbereiding plannen de zwakste trajecten voor vervanging voordat ze opnieuw falen.
    budget: 30000   # estimate: a few short LS sections and joints replaced per year
    team_hours: {grid_analysts: 20, work_prep: 20}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.95}   # estimate
  - id: stop_and_record
    name: Vastleggen voor het afmelden
    tier: 1
    category: standard_work
    description: Voordat de monteur een storing afmeldt, fotografeert hij het kapotte onderdeel, neemt het mee in een zakje met het adres en noemt de oorzaak in één zin. Twee minuten per storing.
    budget: 1000
    team_hours: {monteurs: 10}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: mandatory_cause_field
    name: Verplicht oorzaakveld en een doel op 'onbekend'
    tier: 1
    category: standard_work
    description: Het afmelden lukt pas als er een oorzaak is gekozen, en het aandeel 'onbekend' komt als doel op het bord van de monteurs.
    budget: 1500
    team_hours: {control_room: 5}
    decay_days: 90
    trust: {monteurs: -1}   # proposed field: people are policed, not asked
    aftermath:              # proposed field: Goodhart after six weeks
      after_days: 42
      days: 999
      effects:
        - {target: outages.repair, property: ftr, value: -0.02}   # estimate: wrong codes send repairs after the wrong cause
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.**
- `chose:cause_unknown:mandatory_cause_field` or `flag:cause_field_policed`: the Act V countermeasure "Pareto of fault data" (`maintenance_calendar`, fit 0.7) gets `needs: {none: [chose:cause_unknown:mandatory_cause_field], any: [...]}` with `repaired:cause_unknown` as the way back. Hint: "De storingsdata moet eerst weer te vertrouwen zijn."
- The field "works" in the Check: "onbekend" falls to 2% in weeks. The monteurs pick the first code in the list. Its fit is 0.4 below the best, so `poor_fix:cause_unknown` is set and the repair quest follows.

**Grounding.**
- LS fault causes 2018: digging almost 27% (the largest cause), followed by ageing/wear and latent faults at 18% (the report gives one figure for the two categories; read it as "about 18% each" only after checking the table itself). Netbeheer Nederland — *Betrouwbaarheid van elektriciteitsnetten in Nederland, resultaten 2018*, https://www.netbeheernederland.nl/sites/default/files/Betrouwbaarheid_elektriciteitsnetten_in_Nederland_2018_150.pdf; also Netbeheer Nederland — *Graafschade blijft grootste veroorzaker stroomstoring*, https://www.netbeheernederland.nl/artikelen/nieuws/graafschade-blijft-grootste-veroorzaker-stroomstoring. Nestor has registered faults nationally since 1976 (same report).
- National fault registration (Nestor), latent fault ("sluimerende storing") as a category: same series. The 2024 results: https://www.netbeheernederland.nl/sites/default/files/2025-04/03.02._betrouwbaarheid_van_elektriciteitsnetten_in_nederland_-_resultaten_2024.pdf
- "41% onbekend", "three in ten repeat" and "twelve sections": `estimate:` chosen so the Pareto is a puzzle. The content test (catalogue §2.11) must make the briefing's number true on the network.
- Lean check:
  - The Pareto is a diagnostic, used here as a countermeasure only together with a routine (weekly review + A3 on the top bar). That keeps the GDD rule "diagnostic tools are not countermeasures" intact: the countermeasure is the *routine and the codes*.
  - Stop-and-record is jidoka for information.

**Engrossing.**
- The data puzzle has three layers. The first Pareto is useless: "onbekend" is the top bar. You must sort by *location* first. Then the old-joints bin shows *one joint type*.
- The aha: the data was never missing. It was in the van, in the bin, and in Kees's head.
- The care home gives a face and a clock without a hard deadline.

### 2.3 The fork: `fix_on_call_far` (B) and `fix_shift_handover` (N)

Fork group `t2_outage_time`. Both open after `fix_cause_unknown`.
- Bottleneck: the on-call crew starts too far away. On-call people are scarce, two at night, so travel queues outages and the 4-hour norm breaks.
- Non-bottleneck: control-room handovers. A real annoyance at a step with lots of slack.

Principles tested: **long_term** and **respect**. Temptation: extra on-call shifts for the same two people.

```yaml
missions:
  - id: fix_on_call_far
    name: De verste storingsdienst
    kind: main
    tier: 2
    act: 3
    chapter: Als het licht uitgaat
    requires: {missions: [fix_cause_unknown]}
    fork: {group: t2_outage_time, role: bottleneck}
    goal: {type: solve, problem: on_call_far}
    principles: [long_term, respect]
    briefing: "Kees uit de meldkamer houdt een lijstje bij: van de storingen 's nachts en in het weekend duurde vorige maand bijna een op de vier langer dan vier uur, bijna allemaal in de dorpen ten noorden van Nova. Elke klant daar krijgt dan een compensatie. Kees en Esra van het klantcontactcentrum willen allebei dat jij eerst naar hun probleem kijkt."
    debrief: "De consignatie wacht nu waar de storingen vallen, niet waar de monteurs toevallig wonen. De klant in het noorden wacht niet meer langer dan de klant in Nova."
    debrief_first: "De consignatie staat goed, en de nachtelijke storingen halen weer de vier uur. Kees' overdracht in de meldkamer wacht nog; kijk straks of die de stroom echt ophoudt."
    reopen: "De standplaatsen zijn ongemerkt teruggeschoven naar huis. Kees: 'Het noorden wacht weer.'"
    beats:
      - {on: accepted, who: kees, text: "Ik stuur altijd de dichtstbijzijnde. Maar de dichtstbijzijnde is 's nachts drie kwartier rijden."}
    temptations:
      - id: double_on_call
        who: marco
        when: accepted
        text: "Snelste oplossing: Ruben en Ilse draaien er elk twee consignatieweekenden per maand bij. Dan staat er altijd iemand extra. Ze klagen wel, maar ze doen het."
        accept: "Je roostert Ruben en Ilse extra in."
        decline: "Je laat de consignatie zoals hij is en zoekt waarom ze zo ver moeten rijden."
        accept_sets_flags: [flag:on_call_overloaded]
        accept_effects: {trust: {on_call: -1}}
    teaches: [waste_transport, lead_time, compensatieregeling]
    rewards: {xp: 2000, budget: 15000, reputation: 5, trust: {on_call: 1}}
    insights:
      go_see: "Twee teams vragen om je aandacht. Waar wacht een storing het langst: in de meldkamer of onderweg?"
      understand: "Waar wacht de consignatiemonteur als er geen storing is? Wie heeft dat ooit bepaald?"
      experiment: "Hoeveel storingen 's nachts verwacht je over twee weken binnen vier uur, en hoe meet je dat?"
      reflect: "Gaan er nu meer storingen binnen de norm door? Wat zou er gebeurd zijn als je eerst de overdracht had aangepakt?"

  - id: fix_shift_handover
    name: De overdracht die niet overkomt
    kind: main
    tier: 2
    act: 3
    chapter: Als het licht uitgaat
    requires: {missions: [fix_cause_unknown]}
    fork: {group: t2_outage_time, role: non_bottleneck}
    goal: {type: solve, problem: shift_handover}
    principles: [improve]
    briefing: "Kees vraagt je om hulp: bij elke dienstwissel in de meldkamer gaat informatie verloren. Collega's bellen monteurs na om te vragen hoe het ervoor staat, en een melding van vlak voor de wissel bleef vorige week een halfuur liggen. 'Dit is mijn grootste ergernis', zegt hij."
    debrief: "De overdracht gaat nu volgens een vaste standaard aan het bord. Kees is blij. Kijk wel naar de storingen: halen er nu meer de vier uur?"
    debrief_first: "De overdracht loopt, Kees is tevreden. Maar de storingen in het noorden duren nog net zo lang: de meldkamer was het knelpunt niet. Waar wachten ze dan?"
    reopen: "De overdrachtsstandaard is in de drukte verwaterd tot een vluchtig 'alles goed?'."
    teaches: [standard_work, bottleneck_focus]
    rewards: {xp: 1600, budget: 10000, trust: {control_room: 1}}
    insights:
      go_see: "Twee teams vragen om je aandacht. Waar wacht een storing het langst: in de meldkamer of onderweg?"
      reflect: "Kees is blij. Gaan er nu ook meer storingen binnen vier uur door? Waarom wel of niet?"

problems:
  - id: on_call_far
    tier: 2
    name: De verste storingsdienst
    step: outages.locate
    waste: transport
    severity: high
    visibility: subtle
    kpi: on_time
    symptoms:
      - "'s Nachts en in het weekend duren storingen in de dorpen ten noorden van Nova veel langer dan overdag."
      - Klanten in het noorden krijgen vaker een compensatiebrief dan klanten in Nova.
    root_cause: De consignatiemonteurs wachten thuis, allebei vlak bij Campus Nova in het zuiden. De standplaatsen zijn ooit bepaald door waar de monteurs wonen, niet door waar de storingen vallen; niemand heeft dat sindsdien naast de storingskaart gelegd.
    plausible_causes:
      - De consignatiemonteurs rijden te langzaam of vertrekken te laat.
      - De meldkamer stuurt de verkeerde monteur.
      - Er zijn gewoon te weinig consignatiemonteurs.
    mismatch_note: De monteurs zijn niet traag; ze beginnen te ver weg. Waar je wacht, bepaalt hoe lang de klant wacht.
    countermeasures: {standby_by_fault_map: 1.0, smaller_on_call_areas: 0.8, mutual_aid_agreement: 0.7, extra_on_call_shifts: 0.65}
    teaches: [waste_transport, lead_time]
    effects:
      # estimate: four in ten faults are in the north, 45-50 min further away;
      # averaged over all faults ~20 extra minutes on the 1.0 h (travel included)
      # locate step. Approximation: daytime monteurs share the step (they are
      # spread over the region and drive less), so the factor is applied to both.
      - {target: outages.locate, property: touch_time, value: 1.35}
    # estimate: about one extra outage a week passes four hours, ~30 small
    # connections affected x EUR 35 compensation (Liander compensation scheme).
    cost_per_week: 1050
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de storingen 's nachts en in het weekend duurde vorige maand bijna een op de vier langer dan vier uur. Overdag was dat een op de twintig."}
      - {tool: time_study, key: false, depth: 0, text: "Op locatie vinden de consignatiemonteurs de fout even snel als hun collega's overdag."}
      - {tool: shadow, key: true, depth: 1, text: "Om half twee 's nachts komt een melding uit het noorden binnen. De monteur stapt in Nova in de bus en rijdt 48 minuten voordat hij kan beginnen."}
      - {tool: documents, key: true, depth: 1, at: outages.report, text: "Het consignatierooster noemt als standplaats het huisadres van de monteur. Allebei wonen ze binnen tien minuten van de campus."}
      - {tool: data, key: true, depth: 2, at: outages.report, text: "Op de storingskaart van de laatste drie jaar ligt het zwaartepunt van de nachtelijke storingen twintig kilometer noordelijker dan de standplaatsen."}
      - {tool: conversation, key: true, depth: 2, text: "'Mijn standplaats is mijn huis. Zo is het altijd geweest. Als ik bij de oude werkplaats in Noordveld mocht wachten, was ik er in een kwartier.'"}
      - {tool: conversation, key: false, depth: 1, at: outages.report, text: "'Het noorden heeft gewoon oudere kabels. Daar valt meer uit.'"}

  - id: shift_handover
    tier: 2
    name: De overdracht die niet overkomt
    step: outages.report
    waste: overprocessing
    severity: medium
    visibility: obvious
    kpi: lead_time
    symptoms:
      - Bij elke dienstwissel in de meldkamer bellen operators monteurs na om te vragen hoe een storing ervoor staat.
      - Een melding van vlak voor de wissel bleef vorige week een halfuur liggen.
    root_cause: Er is geen vaste overdracht. Elke operator geeft op zijn eigen manier door wat er openstaat; de volgende dienst reconstrueert het uit het logboek en de telefoon.
    plausible_causes:
      - De operators zijn niet zorgvuldig genoeg.
      - Het meldkamersysteem is verouderd.
    mismatch_note: Zorgvuldiger werken lost niet op dat niemand weet wat er bij een overdracht gezegd moet worden. Het ontbreekt aan een standaard, niet aan inzet.
    countermeasures: {handover_standard_at_board: 1.0, open_actions_list: 0.8}
    teaches: [standard_work]
    effects:
      # estimate: reconstructing open faults after a shift change adds ~9 minutes
      # per report on average (0.25 h → 0.4 h). The control room has lots of
      # slack (2 operators around the clock for ~5 h of outage work a week), so
      # this is not the constraint: the fork's lesson.
      - {target: outages.report, property: touch_time, value: 1.6}
    clues:
      - {tool: shadow, key: true, depth: 0, text: "Om drie uur neemt de middagdienst over. De nieuwe operator leest twintig minuten in het logboek en belt twee monteurs na."}
      - {tool: queue_count, key: false, depth: 0, text: "Er staan zelden meer dan twee meldingen tegelijk open in de meldkamer."}
      - {tool: documents, key: true, depth: 1, text: "Er is geen overdrachtsformulier en geen vast moment. Het logboek is vrije tekst per operator."}
      - {tool: conversation, key: true, depth: 1, text: "'Iedereen draagt anders over. Bij de een krijg je een verhaal, bij de ander een knikje.'"}

countermeasures:
  - id: standby_by_fault_map
    name: Standplaatsen volgens de storingskaart
    tier: 1
    category: flow
    description: De consignatiemonteurs wachten op standplaatsen die gekozen zijn op de storingskaart van de laatste drie jaar, met de bus en het materiaal daar. Er komt een vergoeding voor de wachtplek en elk kwartaal wordt de kaart opnieuw bekeken.
    budget: 3000
    team_hours: {control_room: 10, on_call: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages.locate, property: touch_time, value: 0.95}   # estimate: also shortens the base's drives
  - id: smaller_on_call_areas
    name: Twee consignatiegebieden met drie monteurs
    tier: 2
    category: flow
    description: Zuidmark wordt in twee consignatiegebieden verdeeld met elk een eigen monteur, plus een derde als achtervang. Meer mensen in de consignatie, kortere ritten.
    budget: 15000   # estimate: a year's on-call allowance for one extra person
    team_hours: {on_call: 10, control_room: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: on_call, property: headcount, value: 1}
  - id: mutual_aid_agreement
    name: Burenhulp met de buurnetbeheerder
    tier: 2
    category: flow
    description: De storingsdienst van de buurnetbeheerder neemt 's nachts storingen in de grensdorpen over en andersom, met een vaste afspraak over meldkamers, vergoeding en materiaal.
    budget: 5000
    team_hours: {control_room: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: extra_on_call_shifts
    name: Extra consignatiediensten voor dezelfde monteurs
    tier: 1
    category: flow
    description: De twee consignatiemonteurs draaien er elk twee weekenden per maand bij. Er staat altijd iemand extra klaar, zonder iets aan het proces te veranderen.
    budget: 4000
    team_hours: {on_call: 2}
    decay_days: 60
    trust: {on_call: -1}
    aftermath:
      after_days: 42
      days: 56
      effects:
        - {target: on_call, property: availability, value: -0.15}   # estimate: fatigue and sick leave after six weeks
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: on_call, property: headcount, value: 1}
  - id: handover_standard_at_board
    name: Overdracht aan het bord met een vaste standaard
    tier: 1
    category: standard_work
    description: Tien minuten overlap bij elke dienstwissel. De operators lopen samen het bord langs, met een vaste volgorde voor open storingen, wie waar is en wat nog moet.
    budget: 1000
    team_hours: {control_room: 8}
    decay_days: 60
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: open_actions_list
    name: Openstaande acties in het meldkamersysteem
    tier: 2
    category: visual_management
    description: Het meldkamersysteem toont per storing de openstaande acties en wie ze heeft; de nieuwe dienst ziet in één scherm wat er loopt.
    budget: 7000
    team_hours: {control_room: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.**
- `flag:on_call_overloaded` or `chose:on_call_far:extra_on_call_shifts`. The quick fix passes the Check (more people), then the `aftermath` takes availability down. Its fit (0.65) is ≥ 0.2 below the best, so `poor_fix` → `repair_on_call_far`.
- Act IV `t3_crew_strategy`'s option "daytime outage reserve" gets `none: [flag:on_call_overloaded]` unless `repaired:on_call_far`. Hint: "De storingsdienst moet eerst weer op adem komen."
- `prep_storm_week` failing closes `mutual_aid_agreement` (fail text there). Another way stays open: `standby_by_fault_map`.

**Grounding.**
- Compensation (current, unchanged since the 2013 scheme): €35 for 4–8 h on a connection up to 3×25 A, +€20 per extra 4 h; €195 for 4–8 h on 3×35–3×80 A; paid automatically within 6 months; planned work announced in time does not count. ACM ConsuWijzer — *Vergoeding bij stroomstoring*, https://consument.acm.nl/elektriciteit-en-gas/ik-heb-een-probleem/stroomstoring-vergoeding; ACM — *Vergoeding stroomstoring en gasstoring*, https://www.acm.nl/nl/energie/elektriciteit-en-gas/energietarieven/vergoeding-stroomstoring-en-gasstoring. There is no fixed compensation for a late connection: that goes through a dispute at the ACM (see §2.6 grounding).
- Arrival norm and the 4 h restoration context: Netbeheer Nederland — communicatie use cases, https://www.netbeheernederland.nl/sites/default/files/2024-03/20240229_-_communicatie_use_cases.pdf **(verify)**.
- Travel times, the "one in four" figure and the 9-minute handover cost: `estimate:` (reasoning in the comments).
- **C15 must confirm the fork on the network:**
  - on_call_far's best fix lowers outages' p85 lead time ≥ 3× more than shift_handover's;
  - the shift_handover Check says `not_constraint` (the control room is far below 85% load).

**Engrossing.**
- Kees is a likeable ally who asks for the wrong thing first. The player who helps him first learns the fork's lesson with a friend's disappointment.
- The aha for on_call_far: "Wachten waar je woont" is a decision nobody made.
- The temptation is a manager's reflex. Its cost arrives exactly when a storm or heat event needs those two people.

### 2.4 `fix_contractor_rework` — Twee keer graven (M, the people/conflict mission)

Principle tested: **respect** (for people outside your own payroll too) and **long_term**. Temptation: switch contractor.

```yaml
missions:
  - id: fix_contractor_rework
    name: Twee keer graven
    kind: main
    tier: 2
    act: 3
    chapter: Samen bouwen
    requires: {any_of: [fix_on_call_far, fix_shift_handover]}
    goal: {type: solve, problem: contractor_rework}
    principles: [respect, long_term]
    briefing: "Marco wil van de graafaannemer af: 'Ze kunnen niet graven.' Erik Smits, de uitvoerder van Grondwerk Zuid, zegt dat Voltana's monteurs om niets afkeuren en dreigt het contract niet te verlengen. Ze mailen alleen nog met elkaar. Ondertussen rijden monteurs naar sleuven die niet kloppen, en klanten wachten een week extra. Inkoop wil over vijf weken weten of het contract verlengd wordt."
    debrief: "Monteurs en graafploegen werken nu met één standaard, en een afgekeurde sleuf wordt dezelfde dag besproken in plaats van zes weken later op de factuur. Marco en Erik drinken weer koffie. Inkoop verlengt het contract."
    reopen: "De sleuven kloppen weer minder vaak. Bij Grondwerk Zuid werken nieuwe ploegen die de standaardkaart nooit hebben gezien."
    beats:
      - {on: accepted, who: marco, text: "Ik heb het drie keer gezegd. Ze leren het niet."}
      - {on: accepted, who: erik, text: "Mijn jongens graven zoals op de tekening staat. Als dat fout is, hoor ik het pas als de factuur wordt afgekeurd."}
      - {on: completed, who: erik, text: "Voor het eerst weet mijn ploeg wat goed is voordat ze de sleuf dichtgooien."}
    temptations:
      - id: switch_contractor
        who: inkoop
        when: accepted
        text: "Er is een andere aannemer die volgende maand kan beginnen. Een boeteclausule erin en klaar. Dan hoef jij je niet met hun ruzie te bemoeien."
        accept: "Je laat Inkoop overstappen naar een nieuwe aannemer."
        decline: "Je gaat eerst met Marco en Erik samen naar een sleuf kijken."
        accept_sets_flags: [flag:contractor_burned]
        accept_effects: {reputation: -2}
    teaches: [quality_at_the_source, respect_for_people, standard_work]
    rewards: {xp: 2000, budget: 15000, reputation: 5, trust: {monteurs: 1}}
    insights:
      go_see: "Heb je een afgekeurde sleuf zelf gezien, samen met iemand van de aannemer?"
      understand: "Wanneer hoort de graafploeg dat een sleuf niet goed was, en wat kan hij op dat moment nog met die informatie?"
      experiment: "Wat verwacht je over twee weken te zien aan het aandeel klussen dat in één keer lukt?"
      reflect: "Marco en Erik stonden tegenover elkaar. Wat is er veranderd: de mensen, of wat ze van elkaar weten?"

problems:
  - id: contractor_rework
    tier: 2
    name: Twee keer graven
    step: connections.execution
    waste: defects
    severity: medium
    visibility: subtle
    kpi: first_time_right
    symptoms:
      - Monteurs komen bij sleuven die niet kloppen, te ondiep, zonder mantelbuis onder de stoep of op de verkeerde plek, en moeten de klus terugsturen naar Planning.
      - De teamleider monteurs en de uitvoerder van de graafaannemer praten alleen nog via e-mail.
    root_cause: Voltana en de aannemer werken met verschillende versies van de sleufstandaard. De graafploegen, vaak nieuw en wisselend, krijgen wel de tekening maar niet de standaard. Een afgekeurde sleuf komt alleen terug via de maandelijkse factuurcontrole, zes weken later, dus niemand op straat leert ervan.
    plausible_causes:
      - De aannemer zet slechte mensen in.
      - De monteurs keuren te streng af.
      - De tekeningen van Werkvoorbereiding kloppen niet.
    mismatch_note: Een andere aannemer of strenger keuren verandert niets zolang de ploeg op straat de standaard niet kent en pas weken later hoort wat er mis was.
    countermeasures: {shared_trench_standard: 1.0, first_job_inspection: 0.8, contractor_scorecard: 0.7, switch_contractor: 0.6}
    teaches: [quality_at_the_source, respect_for_people]
    effects:
      # estimate: four in twenty trenches rejected; the job goes back to
      # planning (execution's rework_to) with its 5-day wait. Sim check
      # (docs/qa/tier2-sim-check.md fix 1, verified): -0.15 hurt FTR by only
      # 1.8 pt on the test seed; -0.20 gives 41.8 -> 32.2 % over 5 seeds.
      - {target: connections.execution, property: ftr, value: -0.20}
    cost_per_week: 1000   # estimate: ~4 trenches re-dug a week x ~EUR 250, disputed on the invoice
    clues:
      - {tool: shadow, key: true, depth: 0, text: "De sleuf bij een nieuwbouwwoning ligt op veertig centimeter, terwijl de aansluitkabel in de stoep minstens vijftig moet liggen. De monteur maakt een foto en rijdt terug; de klus gaat terug naar Planning."}
      - {tool: documents, key: false, depth: 0, at: connections.design, text: "De tekeningen van Werkvoorbereiding kloppen: maten, tracé en diepte staan erop."}
      - {tool: data, key: true, depth: 1, at: connections.planning, text: "Vier op de twintig klussen met een graafploeg van de aannemer gaan terug naar Planning omdat de sleuf niet klopt. Bij de eigen graafploeg is dat een op de vijftig."}
      - {tool: documents, key: true, depth: 1, text: "Voltana werkt met sleufstandaard versie 4 uit 2024. In het contract met de aannemer staat versie 2; de mantelbuis onder de stoep staat daar niet in."}
      - {tool: conversation, key: true, depth: 2, text: "'Wij horen het pas als de factuur wordt afgekeurd, zes weken later. Dan weet ik niet eens meer welke ploeg dat was.'"}
      - {tool: conversation, key: false, depth: 1, text: "'Die jongens van de aannemer hebben er geen zin in. Dat zie je zo.'"}
      - {tool: conversation, key: true, depth: 2, at: connections.planning, text: "'Elke maand zie ik een paar nieuwe namen in de ploegen van de aannemer. Niemand legt ze uit hoe wij het willen.'"}

countermeasures:
  - id: shared_trench_standard
    name: Eén sleufstandaard en een wekelijkse terugkoppeling
    tier: 2
    category: quality
    description: Monteurs en aannemer maken samen één standaardkaart met foto's van een goede en een foute sleuf. De ploeg stuurt een foto voor het dichtgooien. Elke week bespreken Marco en de uitvoerder een kwartier aan het bord wat er misging.
    budget: 4000
    team_hours: {monteurs: 20, planners: 10}
    decay_days: 90
    sustains: true   # a weekly review at the board with the contractor
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.execution, property: ftr, value: 0.02}   # estimate: also the base's misunderstandings
  - id: first_job_inspection
    name: Eerste-sleufinspectie met de aannemer
    tier: 1
    category: quality
    description: Bij elke nieuwe graafploeg keuren een monteur en de uitvoerder van de aannemer samen de eerste sleuf, ter plekke, met de standaard erbij.
    budget: 1500
    team_hours: {monteurs: 15}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: contractor_scorecard
    name: Kwaliteitsscorekaart in het contract
    tier: 2
    category: standard_work
    description: Het percentage goedgekeurde sleuven komt in het contract, met een bonus of korting per kwartaal. Het werkt, maar meet wat er misgaat en niet waarom.
    budget: 2000
    team_hours: {planners: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: switch_contractor
    name: Overstappen naar een andere aannemer
    tier: 1
    category: people
    description: Inkoop sluit een contract met een andere graafaannemer, met een boeteclausule op afgekeurde sleuven.
    budget: 8000
    team_hours: {planners: 15}
    decay_days: 120
    aftermath:
      after_days: 7
      days: 56
      effects:
        - {target: connections.execution, property: ftr, value: -0.1}   # estimate: new crews learn Nova's streets and standard from scratch
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.**
- `flag:contractor_burned` or `chose:contractor_rework:switch_contractor`: in Act IV, `underground_crowding`'s "one-dig agreements" (contractors, utilities and gemeente share one trench) gets `needs: {none: [flag:contractor_burned], any: [...]}` with `repaired:contractor_rework` as the way back. Hint: "Aannemers moeten Voltana weer willen vertrouwen."
- The contractor market is small, which is part of the technician shortage.
- `done:fix_contractor_rework` opens `fix_monteur_hours` (Marco trusts you now).

**Grounding.**
- Depth: a house-connection cable lies at least 50 cm deep in public ground and 40 cm on private ground, in a PVC sleeve (red, 50 mm for electricity) from just before the façade to the meter cupboard. Stedin — *Richtlijnen huisaansluitingen*, https://www.stedin.net/-/media/project/online/files/zakelijk/branches/stedin-richtlijnen-huisaanluitingen.pdf. Corrected from 60 cm: a trench at 40 cm under the footpath is still too shallow. Other DSOs and municipalities may ask for more (60 cm is a common municipal norm for cables), which is why the clue says "minstens".
- The care for contractor crews (rotating staff): grounded in the technician shortage (Netbeheer Nederland / Solar Magazine, see the `monteurstekort` concept).
- Feedback delay via the monthly invoice: `estimate:`.
- Lean check:
  - quality at the source;
  - a feedback loop measured in hours, not weeks;
  - a scorecard is a lagging control and is Goodhart-prone (hence fit 0.7).
  - Switching suppliers is not a Lean countermeasure, but it is a real management option, hence fit 0.6 with an aftermath.

**Engrossing.**
- A conflict between two people who are both partly right. Each side's red herring is the other side's accusation.
- Blaming questions to Marco *or* Erik cost trust (Erik counts under `monteurs` trust for the contractor relation, or under a new `contractor` trust key).
- The win is visible: the two men at one sleuf. A person, a stake and a clock (Inkoop's five weeks).

### 2.5 `fix_escalation_hallway` — Escalatie via de gang (M)

Principle tested: **improve** and **long_term** (the cheap stand-up vs the full escalation route). Its poor-fix route is the worked repair quest in §2.15.

```yaml
missions:
  - id: fix_escalation_hallway
    name: Escalatie via de gang
    kind: main
    tier: 2
    act: 3
    chapter: Samen bouwen
    requires: {missions: [fix_contractor_rework]}
    goal: {type: solve, problem: escalation_hallway}
    principles: [improve, long_term]
    briefing: "Op het bord van Werkvoorbereiding hangen elf rode kaartjes. Het oudste hangt er negen dagen: een vraag aan de gemeente over een tracé. Joost: 'We zien de problemen nu wel, maar niemand doet er iets mee. Ik loop de gang op en hoop dat ik iemand tref.' Als het bord niets oplevert, haalt hij het eraf."
    debrief: "Een rood kaartje dat het team niet zelf kan oplossen, gaat dezelfde dag een laag hoger en heeft binnen een dag een eigenaar. Joost: 'Het bord is nu geen klaagmuur meer.'"
    reopen: "De rode kaartjes blijven weer hangen. De afdelingsdagstart om negen uur is twee keer niet doorgegaan en daarna niet meer."
    beats:
      - {on: accepted, who: joost, text: "Als er volgende week nog steeds niemand reageert, haal ik dat bord eraf."}
    teaches: [tiered_escalation, andon, daily_management]
    rewards: {xp: 2100, budget: 15000, reputation: 5, trust: {work_prep: 1}}
    insights:
      go_see: "Neem het oudste rode kaartje. Wat heeft het de afgelopen negen dagen meegemaakt?"
      understand: "Wie kan dit kaartje oplossen, en hoe hoort die persoon dat het er hangt?"
      experiment: "Hoe lang hangt een rood kaartje nu gemiddeld? Wat verwacht je over twee weken?"
      reflect: "Een andon zonder iemand die komt, wat leert het team daarvan?"

problems:
  - id: escalation_hallway
    tier: 2
    name: Escalatie via de gang
    step: connections.design
    waste: waiting
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Een werkvoorbereider wacht een week op antwoord op één vraag over een tracé.
      - Op het nieuwe bord bij Werkvoorbereiding hangen rode kaartjes die al dagen niemand oppakt.
    root_cause: Wat een team niet zelf kan oplossen, wacht op het wekelijkse coördinatieoverleg op dinsdag. Er is geen afgesproken route en geen tijd waarbinnen een probleem een laag hoger moet zijn; wie iets wil, loopt de gang op en hoopt iemand te treffen.
    plausible_causes:
      - De werkvoorbereiders stellen te veel vragen.
      - Netstrategie en de gemeente reageren niet.
      - Het bord werkt niet; het moet digitaal.
    mismatch_note: Meer zichtbaarheid helpt niet als niemand op het signaal reageert. Een andon werkt pas als er iemand komt.
    countermeasures: {tiered_escalation_24h: 1.0, andon_standup: 0.7}
    teaches: [tiered_escalation, andon]
    effects:
      # estimate: one in eight dossiers hits a blocker the work preparer cannot
      # solve alone; it goes back on the pile until the weekly meeting (approximated
      # as a failed design that waits its turn again). A rework_wait_days effect
      # property would model the weekly wait more faithfully.
      - {target: connections.design, property: ftr, value: -0.12}
      # estimate: questions from the gemeente are answered at the weekly meeting:
      # about three days on the 30-day permit wait.
      - {target: connections.permit, property: wait_time, value: 1.1}
    clues:
      - {tool: queue_count, key: true, depth: 0, text: "Op het bord hangen elf rode kaartjes. Het oudste hangt er negen dagen; zeven wachten op iemand buiten het team."}
      - {tool: time_study, key: false, depth: 0, text: "Een ontwerp maken kost ruim drie uur, binnen de norm."}
      - {tool: documents, key: true, depth: 1, text: "De agenda van het wekelijkse coördinatieoverleg op dinsdag: 'rondvraag'. Er is geen vaste plek voor blokkades en geen termijn waarbinnen iemand antwoordt."}
      - {tool: conversation, key: true, depth: 1, text: "'Als ik Netstrategie nodig heb, loop ik erheen. Is Femke er niet, dan zet ik het op de lijst voor dinsdag.'"}
      - {tool: data, key: true, depth: 2, text: "Een blokkade die het team zelf oplost, is binnen een dag weg. Een blokkade die een ander team nodig heeft, duurt gemiddeld zes werkdagen."}
      - {tool: conversation, key: true, depth: 2, at: connections.grid_study, text: "'Als ik het had geweten, had het me tien minuten gekost. Ik zie hun bord nooit.'"}

countermeasures:
  - id: tiered_escalation_24h
    name: Gelaagde dagstart met een 24-uursregel
    tier: 2
    category: visual_management
    description: Drie korte dagstarts na elkaar, team om kwart over acht, afdeling om negen uur en regio om half tien. Een rood kaartje dat het team niet zelf oplost, gaat dezelfde ochtend een laag hoger en heeft binnen 24 uur een eigenaar.
    budget: 3000
    team_hours: {work_prep: 10, planners: 10, intake: 5, grid_analysts: 5}
    decay_days: 60
    sustains: true
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.design, property: ftr, value: 0.02}   # estimate: the base's blockers also move faster
  - id: andon_standup
    name: Dagstart met een andonkaart
    tier: 1
    category: visual_management
    description: Elk team houdt een korte dagstart en hangt een rode andonkaart op bij een blokkade. De teamleider haalt de kaarten op; een route naar boven is er niet.
    budget: 500
    team_hours: {work_prep: 5}
    decay_days: 30
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Grounding.**
- Tiered escalation (team → department → site, with a time limit) and the andon principle that a signal needs a response: Lean Enterprise Institute lexicon, *andon*, https://www.lean.org/lexicon-terms/andon/ (the entry: a light goes on when an operator pulls a cord or presses a button, and a team leader responds). Also D. Mann, *Creating a Lean Culture* (tiered daily accountability).
- "Eleven cards", "nine days" and "six working days": `estimate:`.

**Engrossing.**
- A direct sequel to `t2_daily_boards`: your own board produced this problem. If the player took the dashboard temptation there, this mission's depth-0 clue is hidden behind depth 1.
- The aha: *visual management without a response is theatre*.

### 2.6 `acm_visit` — De ACM komt langs (milestone) and `acm_improvement_plan` (recovery)

Principle tested: **long_term**. Temptation: start the clock later ("the dossier only counts once it is complete"). That is gaming the measure, the most realistic and the most dangerous shortcut in regulated industries.

```yaml
missions:
  - id: acm_visit
    name: De ACM komt langs
    kind: milestone
    tier: 2
    act: 3
    chapter: Wie kijkt er mee?
    requires: {missions: [fix_contractor_rework]}
    # Sim check 2026-10-16: on_time >= 0.85 cannot fail (0.884 with every Act III
    # problem left open, 0.889 on the expert path; the 120-day reinforcement wait
    # sets it). The median lead time separates the paths on every seed.
    goal: {type: measure, stream: connections, kpi: lead_time, op: '<=', target: 54, window_days: 56}
    deadline_days: 70
    principles: [long_term]
    briefing: "De ACM heeft een informatieverzoek gestuurd: Woonstichting Nova klaagt dat haar nieuwbouwwoningen veel te lang op een aansluiting wachten. Over tien weken komt een toezichthouder voor een gesprek, met de cijfers van de laatste acht weken. Jeroen Dekker: 'Sinds de rechter het oude besluit vernietigde, is er geen harde termijn meer. De achttien weken halen we meestal; wat de ACM wil zien is hoe lang een gewone aansluiting bij ons duurt. Zorg dat de helft binnen 54 dagen klaar is, en dat we weten waar de rest op wacht.'"
    debrief: "De toezichthouder zag dat de helft van de aansluitingen binnen 54 dagen klaar was, en vooral dat Voltana weet waar de rest op wacht. Jeroen: 'Dit vertrouwen hebben we nodig als we straks iets nieuws willen proberen met contracten.'"
    fail: "De cijfers haalden het niet. De ACM vraagt een verbeterplan met een termijn, en voor nieuwe proeven met flexibele contracten is voorlopig geen ruimte."
    fail_opens: [acm_improvement_plan]
    fail_effects: {reputation: -10}
    beats:
      - {on: accepted, who: jeroen, text: "Tien weken. Begin bij de oudste aanvragen; die vragen ze altijd het eerst op."}
      - {on: day, day: 69, who: jeroen, text: "Morgen om tien uur. Ik neem de koffie mee; jij de cijfers."}
    temptations:
      - id: late_clock
        who: thomas
        when: accepted
        text: "Iedereen doet het: laat de klok pas lopen als een aanvraag compleet is in plaats van bij binnenkomst. Dan haal je die 54 dagen zo."
        accept: "Je laat de klok later starten."
        decline: "Je laat de klok lopen vanaf de dag dat de klant aanvraagt."
        accept_sets_flags: [flag:acm_clock_gamed]
        accept_effects: {measure_bonus: -5}     # the reported median looks 5 days shorter: intake and its 5-day rework wait drop out (estimate)
    teaches: [acm, aansluittermijn, leading_lagging]
    rewards: {xp: 2200, budget: 20000, reputation: 10}

  - id: acm_improvement_plan
    name: Een plan voor de ACM
    kind: side
    tier: 2
    act: 3
    chapter: Wie kijkt er mee?
    requires: {facts: {all: [failed:acm_visit]}}
    goal: {type: measure, stream: connections, kpi: lead_time, op: '<=', target: 54, window_days: 56}
    deadline_days: 112
    principles: [long_term, improve]
    briefing: "De ACM wil binnen zestien weken zien dat het verbeterplan werkt: acht weken achter elkaar de helft van de aansluitingen binnen 54 dagen. Geen nieuwe deur dicht als het mislukt, wel een slechtere naam."
    debrief: "De ACM sluit het dossier. Het verbeterplan was geen papier; de cijfers laten het zien."
    fail: "De ACM noteert dat het verbeterplan niet is waargemaakt."
    fail_effects: {reputation: -5}
    teaches: [acm]
    rewards: {xp: 600}
```

**Path dependence.**
- `failed:acm_visit` closes the Act IV countermeasure `acm_pilot_time_bound` through `needs: {none: [failed:acm_visit]}`, replacing the catalogue's `fail_closes` as §2.15 proposes. `non_firm_unused` stays solvable by the standard flex offer and the group contract.
- `flag:acm_clock_gamed` is the real trap. The milestone passes. At Act V's `nta8120_audit`, the auditor finds that registration and measurement disagree: the audit counts one fix fewer as holding (`audit` reads `flag:acm_clock_gamed` as a data-integrity finding) and reputation −15. The flag clears through `repaired:` of a data-integrity repair quest, or by `done:t2_first_okr` with an honest connections KR.
- Note for C10/C4: `measure_bonus` is a proposed temptation effect. It is reported, not simulated: the KPI the board shows changes, the network does not.

**Grounding.**
- The connection term: the CBb annulled the ACM's term decision in Sept 2024. Rechtspraak, https://www.rechtspraak.nl/organisatie-en-contact/organisatie/college-van-beroep-voor-het-bedrijfsleven/nieuws/2024/09/-acm-besluit-over-aansluittermijnen-kleinverbruikers-op-het-elektriciteitsnet-houdt-geen-stand
- The CBb ruling of 28 April 2026 (WoonFriesland/Liander): ACM — *Uitspraak CBb geschilbesluit WoonFriesland/Liander*, https://www.acm.nl/nl/node/29102. The CBb annulled the ACM's decision of 6 May 2024 for lack of reasoning and ordered a new one within 12 weeks; the ACM took it on 16 July 2026.
- In that case the ACM used about 18–22 weeks (the average connection term in practice) as a reasonable term; the CBb did not follow that reasoning, so the term has no firm legal footing right now. Same ACM page; Solar Magazine, https://solarmagazine.nl/nieuws-zonne-energie/i44905/wachten-op-stroom-mag-jaren-duren-acm-geeft-liander-gelijk-bij-klacht-over-uitgestelde-aansluiting-op-stroomnet.
- `norm_days: 126` in `value_streams.yaml`.
- An "information request" and a supervisory conversation are how the ACM supervises. A literal site visit is rare, hence the wording. `estimate:` of the format.
- Median ≤ 54 days over 56 days: `estimate:` (sim check 2026-10-16, `docs/qa/tier2-sim-check.md`): the healthy base 50.3 (max 53.9), the expert path 48.7 (max 51.8), only the main fixed 57.8 (min 54.8), every Act III problem left open 64.0 (min 57.9). The earlier 85% on time could not fail (left open 0.884). K5's content test must show it is reachable on the expert path and missed with the Act III problems left open.

**Engrossing.** A date everyone in the building knows. A measure you can't game without paying later. And a recovery that can always be earned back.

### 2.7 `t2_first_okr` — Een doel voor Zuidmark (M)

Principles tested: **long_term** and **improve**. Temptation: output KRs (Goodhart). Choosing one weakens a fix already made.

```yaml
missions:
  - id: t2_first_okr
    name: Een doel voor Zuidmark
    kind: main
    tier: 2
    act: 3
    chapter: Wie kijkt er mee?
    requires: {missions: [fix_escalation_hallway]}
    goal:
      type: okr
      objective: "Klanten in Zuidmark weten waar ze aan toe zijn, en we houden wat we beloven."
      quarter_days: 91
      pick: 3
      pass_average: 0.7       # each KR scores 0-1 on progress from its start value; the average must reach 0.7
      key_results_menu:
        # Sim check 2026-10-16 (docs/qa/tier2-sim-check.md, 5 seeds, 91 days):
        # expert = every Act III problem fixed with its best fit; left open =
        # the connections sides (or, for outages and meters, a side on that
        # stream) open. Each target is met on 4-5 of 5 seeds on the expert
        # path and on none left open; the old on_time 0.92, wip_age 45 and
        # meters FTR 0.85 were out of reach on every path.
        - {id: kr_conn_lead_time, stream: connections, kpi: lead_time, op: '<=', target: 50, kind: lagging}       # expert 48.5, left open 58.9
        - {id: kr_conn_ftr, stream: connections, kpi: first_time_right, op: '>=', target: 0.45, kind: leading}   # expert 0.462, healthy 0.421, left open 0.359
        - {id: kr_outage_on_time, stream: outages, kpi: on_time, op: '>=', target: 0.91, kind: lagging}          # expert 0.916, heatwave left open 0.821
        - {id: kr_meters_on_time, stream: meters, kpi: on_time, op: '>=', target: 0.86, kind: lagging}           # expert 0.877, monteur hours left open 0.806-0.823; meters FTR moves with nothing in tier 2 (0.72)
        - {id: kr_conn_throughput, stream: connections, kpi: throughput, op: '>=', target: 28, kind: output}     # the temptation: demand is 30 a week, so it reads demand; met by the healthy base too
        # Not offered until a reinforcement-only measure exists (C-task): the
        # stream's wip_age is ~102 d on every path (101.8-103.5), so no target
        # can be failed or earned in a quarter.
        # - {id: kr_reinforcement_wip, stream: connections, kpi: wip_age, op: '<=', target: ?, kind: lagging, needs: {any: [done:lsw_kpi_review], none: [flag:watermelon_review]}}
    principles: [long_term, improve]
    briefing: "Ruud wil voor het eerst één doel voor de hele regio, met drie meetbare resultaten voor het komende kwartaal. Het MT kiest mee, maar jij stelt voor. 'Kies resultaten die laten zien of de klant er iets van merkt, en minstens één die vooruitkijkt. Als je over drie maanden alles hebt gehaald, was je doel te makkelijk.'"
    debrief: "Zuidmark heeft een doel dat elke afdeling begrijpt en drie getallen die laten zien of het lukt. Ruud: 'Zeventig procent halen van een doel dat ertoe doet, is beter dan honderd procent van een doel dat niemand verandert.'"
    beats:
      - {on: accepted, who: ruud, text: "Een getal dat je zelf in de hand hebt is fijn. Een getal dat de klant voelt is beter."}
      - {on: completed, who: sanne, text: "Voor het eerst weet ik waarom mijn getal op het bord ertoe doet."}
    temptations:
      - id: output_kr
        who: mt_member
        when: accepted
        text: "Neem gewoon 'aansluitingen per week' als resultaat. Dat begrijpt iedereen en het is makkelijk te halen als we even doorpakken."
        accept: "Je kiest het aantal aansluitingen per week als key result."
        decline: "Je kiest resultaten die de klant merkt."
        accept_sets_flags: [flag:okr_output_kr]
    sets_flags: [flag:okr_region]          # four-tier audit 1.1: read by lsw_catchball (Act V)
    teaches: [okr, kpi, leading_lagging, kpi_alignment]
    rewards: {xp: 2400, budget: 20000, reputation: 5, unlocks: [okr]}
    insights:
      go_see: "Wat merkt een klant in Nova als het goed gaat? Welk getal op het bord laat dat zien?"
      understand: "Welke van je key results kijkt vooruit? Hoe weet je halverwege het kwartaal of je op koers ligt?"
      experiment: "Wat ga je deze week doen waarvan je verwacht dat een key result beweegt, en wanneer zie je dat?"
      reflect: "Wat gebeurt er met de teams als je ze op een aantal per week afrekent? Heb je dat eerder gezien?"
```

**Path dependence.**
- `flag:okr_output_kr`: a KR on output is a steering KPI that does *not* match the connections problems' KPIs. For the quarter, `silo_kpis`' fix loses its "steering KPI" support and gets drift 1.5 (catalogue §2.8). The player can watch the old silo behaviour creep back, and `fix_silo_kpis` may reopen through the "Terugval" lane.
- The menu's sixth KR ("doorlooptijd netverzwaring") is only offered to a player who did not hide it in `first_kpi_review`, or who repaired that with an honest `lsw_kpi_review`. It is parked until the simulation has a reinforcement-only measure (sim check 2026-10-16); until then the menu has five KRs.
- `t2_first_okr` sets `flag:okr_region` (read by `lsw_catchball` in Act V).
- **Drie winters (2026-10-16):** completing `t2_first_okr` with `acm_visit` judged ends Act III: the farewell talk `ruud_farewell` and Ruud's secondment follow (`2026-10-16-drie-winters-arc.md` §4). The OKR's KR menu gains nothing new; the waiting list's `date_kept` is named in Jeroen's ACM briefing.

**Grounding.**
- OKR grading 0.0–1.0 per KR, sweet spot 0.6–0.7: Google re:Work — *Set goals with OKRs*, https://rework.withgoogle.com/intl/en/guides/set-goals-with-okrs (KRs graded 0.0–1.0, the objective a rough average, the sweet spot 0.6–0.7, a steady 1.0 means too little ambition); What Matters — *How to end the OKR cycle: grading*, https://www.whatmatters.com/okrs-explained/grading-okrs (aspirational OKRs average about 0.7; committed OKRs are expected to score 1.0).
- KR targets: `estimate:`, to be calibrated by K5 on the expert path (the target sits at the expert path's p50 plus a stretch).

**Engrossing.**
- Picking the KRs is the puzzle, and nothing tells you which are good.
- The temptation's cost is not a number in a debrief. It is an earlier victory quietly coming undone.

### 2.8 `fix_safety_stock_calendar` — Altijd net op (S)

Principle tested: **long_term**. Temptation: double the stock. It works, ties up money, and the stock goes stale: meters with the outgoing GPRS module.

```yaml
missions:
  - id: fix_safety_stock_calendar
    name: Altijd net op
    kind: side
    tier: 2
    act: 3
    chapter: Het bord aan de muur
    requires: {missions: [t2_daily_boards]}
    goal: {type: solve, problem: safety_stock_calendar}
    principles: [long_term]
    briefing: "Linda heeft het op het bord gezet: voor de derde keer dit kwartaal zijn de slimme meters op. Meterwissels schuiven een week op, en de brieven voor de laatste analoge meters zijn al de deur uit. Het magazijn zegt dat de leverancier te laat levert."
    debrief: "Het bestelpunt rekent nu met werkdagen. De meters zijn niet meer op, en er ligt niet meer op voorraad dan nodig."
    reopen: "De meters raken weer op. Iemand heeft het bestelpunt bij de jaarlijkse update teruggezet."
    temptations:
      - id: double_stock
        who: magazijn
        when: accepted
        text: "Weet je wat? We bestellen voortaan het dubbele. Dan raken ze nooit meer op."
        accept: "Je laat het magazijn dubbel bestellen."
        decline: "Je zoekt eerst uit waarom het bestelpunt te laag is."
        accept_sets_flags: [flag:meter_overstock]
    teaches: [safety_stock, waste_inventory, kanban]
    rewards: {xp: 700, budget: 6000}

problems:
  - id: safety_stock_calendar
    tier: 2
    name: Altijd net op
    step: meters.reserve_meter
    waste: waiting
    severity: medium
    visibility: subtle
    # Sim check fix 5 (re-measured 2026-10-16): on time hardly moves (the
    # meters norm has slack); the age of the open work shows the orders that
    # wait for a meter (+9.5 %, every seed above +5 %).
    kpi: wip_age
    symptoms:
      - De slimme meters zijn om de paar weken op, en meterwissels schuiven een week op.
      - Het magazijn wijst naar de leverancier, maar de leverancier levert op tijd.
    root_cause: Het bestelpunt rekent het verbruik per kalenderdag, terwijl meters alleen op werkdagen de deur uit gaan. Over een levertijd van twintig werkdagen wordt het verbruik onderschat, en de veiligheidsvoorraad is met dezelfde fout berekend.
    plausible_causes:
      - De leverancier levert te laat.
      - De monteurs nemen meer meters mee dan ze nodig hebben.
      - Er zijn gewoon meer meterwissels dan gepland.
    mismatch_note: De leverancier is niet het probleem en meer voorraad verbergt de fout alleen. Het bestelpunt rekent verkeerd.
    countermeasures: {reorder_point_working_days: 1.0, warehouse_kanban: 0.9, double_stock: 0.6}
    teaches: [safety_stock, waste_inventory]
    effects:
      # 40 meters a week = 8 a working day, not 5.7 a calendar day. The
      # supplier delivers in 20 working days (four weeks; content/value_streams.yaml):
      # the base's reorder point (190) holds 20 x 8 = 160 plus ~2.5 sigma; the
      # sheet's 20 x 5.7 = 114 plus a smaller sigma gives ~130: 60 lower.
      # Measured (5 seeds, 84 days): stock-outs wait ~13 h per order on
      # average, the open work ages 16.7 -> 18.3 d. With "ten days" the error
      # was too small to run out (sim check: harm x0).
      - {target: smart_meter, property: reorder_point, value: -60}
    clues:
      - {tool: data, key: true, depth: 0, text: "De meters waren dit kwartaal drie keer op, telkens zo'n drie weken nadat er besteld was. De orders die moesten wachten, schoven tot een week op."}
      - {tool: documents, key: false, depth: 0, text: "De leverancier levert al een jaar binnen de afgesproken twintig werkdagen."}
      - {tool: documents, key: true, depth: 1, text: "In de bestelpuntsheet staat: verbruik per dag = verbruik per week gedeeld door zeven. Bestelpunt = levertijd in dagen maal verbruik per dag plus veiligheid."}
      - {tool: conversation, key: true, depth: 1, at: meters.appointment, text: "'In het weekend gaat er geen meter de deur uit. Maandag gaan er tien tegelijk mee.'"}
      - {tool: data, key: true, depth: 2, text: "Op werkdagen gaan er gemiddeld acht meters de deur uit, niet vijf of zes. Met werkdagen gerekend had het bestelpunt zestig hoger moeten liggen."}
      - {tool: material_check, key: true, depth: 2, at: connections.materials, text: "Bij de aansluitsets staat dezelfde sheet, met dezelfde fout. Het gaat daar nog goed omdat die leverancier in kalenderdagen levert, maar de volgende leverancier rekent misschien in werkdagen."}

countermeasures:
  - id: reorder_point_working_days
    name: Bestelpunt op werkdagen
    tier: 1
    category: standard_work
    description: Het bestelpunt rekent met het verbruik per werkdag en de werkdagen in de levertijd, en de veiligheidsvoorraad met de spreiding per werkdag. Eens per kwartaal kijkt het magazijn of het verbruik nog klopt.
    budget: 500
    team_hours: {planners: 5}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: warehouse_kanban
    name: Kanban in het magazijn
    tier: 2
    category: flow
    description: De meters liggen in twee vakken. Is het eerste vak leeg, dan gaat de kanbankaart met een vaste bestelhoeveelheid naar de leverancier. Het signaal komt van het verbruik, niet van een sheet.
    budget: 3000
    team_hours: {planners: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: smart_meter, property: reorder_point, value: 5}   # estimate: the second bin as a small buffer
  - id: double_stock
    name: Dubbele bestelling
    tier: 1
    category: flow
    description: Het magazijn bestelt voortaan het dubbele aantal meters. Ze raken niet meer op, maar er ligt veel geld op de plank.
    budget: 2000
    team_hours: {planners: 2}
    decay_days: null
    aftermath:
      after_days: 120
      cost: 18000   # estimate: ~200 extra meters whose GPRS module is outdated by the 2G/3G sunset; ~EUR 90 rework or write-off each
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: smart_meter, property: reorder_point, value: 100}
```

**Path dependence.**
- `chose:safety_stock_calendar:double_stock` / `flag:meter_overstock`: the aftermath cost lands in the next budget period.
- In Act IV, `t3_kaizen_week` at a warehouse-fed step shows the 5S "inventory" finding as an extra red-herring clue that wastes time.

**Grounding.**
- Base numbers and the "up to 9 working days" reasoning: `content/value_streams.yaml` (stock comments).
- The problem source: PLAN.md problem backlog #2 (found while tuning the simulation, 2026-10-12).
- 2G/3G sunset: about 2.5 million GPRS meters replaced 2024–2029. Gaslicht, https://www.gaslicht.com/energie-informatie/slimme-meter
- €90 per meter: `estimate:` (a module swap or write-off of an obsolete meter).
- Lean check: the reorder point = demand during lead time + safety stock, standard inventory practice; kanban as the consumption signal.

**Engrossing.** A pure arithmetic mystery: the supplier is innocent, the spreadsheet is guilty, and the same bug hides in a second place. The player who finds the kits too feels clever.

### 2.9 `fix_lmra_tickbox` — LMRA als vinkje (S, the safety exception)

Principles tested: **respect** and the **named exception to long_term**. Two near-misses mean containment *now* (a two-person rule at old meter cabinets), then the root-cause fix. Here a quick, temporary measure is right, and the game must score it so.

```yaml
missions:
  - id: fix_lmra_tickbox
    name: LMRA als vinkje
    kind: side
    tier: 2
    act: 3
    chapter: Het bord aan de muur
    requires: {missions: [fix_cause_unknown]}   # staggered (four-tier audit §2, 2026-10-16)
    goal: {type: solve, problem: lmra_tickbox}
    principles: [respect, long_term]
    briefing: "Twee bijna-ongevallen in een maand, allebei bij het openen van een oude meterkast, en allebei met een LMRA op 'akkoord'. Marco is geschrokken: 'Volgende keer is het geen bijna.' Zorg eerst dat niemand vandaag gewond raakt, en zoek dan uit waarom de LMRA niets tegenhoudt."
    debrief: "Bij oude meterkasten werken monteurs tijdelijk met z'n tweeën, tot de nieuwe LMRA-kaarten werken. De LMRA duurt weer een minuut en gaat weer over het werk; stoppen wordt beloond. Marco: 'Dit keer veranderden we de kaart, niet de mensen.'"
    reopen: "De LMRA-kaart is weer aangevuld met vragen. Het duurt weer tien minuten en niemand leest het nog."
    beats:
      - {on: accepted, who: marco, text: "Vandaag nog. Ik wil niet wachten op een A3 terwijl er iemand bij zo'n kast staat."}
    teaches: [lmra, respect_for_people, standard_work]
    rewards: {xp: 700, budget: 6000, trust: {monteurs: 1}}

problems:
  - id: lmra_tickbox
    tier: 2
    name: LMRA als vinkje
    step: connections.execution
    waste: overprocessing
    severity: high
    visibility: subtle
    kpi: first_time_right
    symptoms:
      - Een monteur vinkt op zijn tablet in tien minuten 42 vragen af voordat hij begint.
      - Twee bijna-ongevallen in een maand bij oude meterkasten, beide met een LMRA op 'akkoord'.
    root_cause: De laatste-minuut-risicoanalyse is uitgegroeid tot een lange algemene vragenlijst. Na elk incident kwam er een vraag bij, voor de audit. Hij wordt afgevinkt in plaats van doordacht, de echte risico's van deze klus komen niet aan bod, en er is geen afgesproken moment om te stoppen.
    plausible_causes:
      - De monteurs nemen veiligheid niet serieus.
      - De jonge monteurs zijn onvoldoende opgeleid.
      - De oude meterkasten zijn het probleem; vervang ze allemaal.
    mismatch_note: Meer vragen of strenger controleren maakt het afvinken alleen langer. De LMRA hoort een korte denkstap over deze klus te zijn, met het recht om te stoppen.
    countermeasures: {task_specific_lmra: 1.0, stop_the_work_andon: 0.8, two_person_rule_old_cabinets: 0.6}
    teaches: [lmra, respect_for_people]
    effects:
      # estimate: a quarter of an hour of ticking per job on the 5 h execution step.
      - {target: connections.execution, property: touch_time, value: 1.05}
      # estimate: one job in five is stopped late, after a near-miss or an
      # unsafe discovery, and has to be replanned. Sim check fix 2: -0.05,
      # -0.13 and -0.17 did not drop first time right by 5 points on the test
      # seed (+0.7, -3.7, -4.2); -0.20 does (-5.7, a thin margin; -0.23 gives
      # -7.7 if the base moves).
      - {target: connections.execution, property: ftr, value: -0.20}
    clues:
      - {tool: shadow, key: true, depth: 0, text: "Bij de auto vinkt de monteur 42 vragen af. Dan opent hij de meterkast zonder te kijken; de kast is van voor 1970, met blanke delen achter het deurtje."}
      - {tool: data, key: false, depth: 0, text: "Het aantal ongevallen met verzuim is al drie jaar laag."}
      - {tool: documents, key: true, depth: 1, text: "De LMRA-lijst begon in 2018 met zes vragen. Na elk incident kwam er een vraag bij; nu zijn het er 42, voor elke klus dezelfde."}
      - {tool: conversation, key: true, depth: 1, text: "'Ik vink alles af, anders kan ik de werkbon niet openen. Wat er echt gevaarlijk is aan deze klus, staat er niet in.'"}
      - {tool: conversation, key: true, depth: 2, text: "'Stoppen? Dan moet ik uitleggen waarom ik mijn planning niet haal. Dat doe je één keer.'"}
      - {tool: documents, key: true, depth: 2, at: connections.planning, text: "Een gestopte klus telt in het weekrapport van Planning als 'niet gehaald'. Er is geen code voor 'veilig gestopt'."}

countermeasures:
  - id: task_specific_lmra
    name: Korte LMRA per type klus
    tier: 1
    category: safety
    description: Terug naar wat een LMRA is, één minuut nadenken over deze klus. Per type klus een kaart met vier vragen over de echte risico's, en de afspraak dat 'nee' stoppen betekent.
    budget: 2000
    team_hours: {monteurs: 20}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.execution, property: touch_time, value: 0.99}
  - id: stop_the_work_andon
    name: Stoppen mag, en telt
    tier: 2
    category: people
    description: Elke monteur mag het werk stilleggen en de teamleider bellen. Een gestopte klus krijgt de code 'veilig gestopt' en wordt besproken bij de dagstart, als leermoment en niet als schuldvraag.
    budget: 2500
    team_hours: {monteurs: 10, planners: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: two_person_rule_old_cabinets
    name: Tijdelijk met z'n tweeën bij oude meterkasten
    tier: 1
    category: safety
    description: Tot de oorzaak is opgelost, gaat bij elke meterkast van voor 1970 een tweede monteur mee. Dit beheerst het risico vandaag; het lost het niet op.
    budget: 500
    team_hours: {planners: 5}
    decay_days: 30          # temporary by design
    containment: true       # proposed field: runs next to the A3's countermeasure and scores as containment
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.execution, property: touch_time, value: 1.05}   # estimate: the second monteur's time on the old-cabinet share
```

**Scoring (the exception, for C-tasks).** The Check & Act score gives a **containment bonus** if a `containment: true` countermeasure was started within 3 days of accepting. It gives a **penalty** if the containment is the only countermeasure at the Act ("you contained it, you did not solve it"). Elsewhere in the game, the same quick measure would score lower. Here the debrief says why: *a safety risk is the 5% where now beats later.*

**Grounding.**
- LMRA: a short mental risk check by the person who does the task, about a minute, no paperwork; a "no" means stop and consult. VOLTA — *Informatie LMRA* (2020), https://volta-org.be/media/ieqbrpzq/volta-informatie_lmra_2020.pdf **(verify)**; Westenberg — *Toolbox Laatste Minuut Risico Analyse*, https://westenberg.net/wp-content/uploads/2025/02/Toolbox_Laatste-Minuut-Risico-Analyse.pdf **(verify)**.
- Safety Culture Ladder (formerly Veiligheidsladder, owned and managed by NEN): manual 5.0 (July 2023) on the public site, https://safetycultureladder.com/app/uploads/2023/12/Safety-Culture-Ladder-Manual_5.0_EN_def-.pdf (Dutch: https://safetycultureladder.com/app/uploads/2023/11/Handboek-Safety-Culture-Ladder_5.0_def_NL.pdf); documents page https://safetycultureladder.com/en/documents/.
- 42 questions, ten minutes, two near-misses and "before 1970": `estimate:`.

**Engrossing.**
- The safety officer added a question after every incident. Every addition made it less safe.
- The aha: more checks, less attention.
- The deeper clue makes it a respect problem: stopping is punished by a planning KPI.

### 2.10 `prep_storm_week` — Code oranje (S, deadline, event)

Principles tested: **respect** and **long_term**. Temptation: cancel everyone's leave and put all monteurs on call for 72 hours. It works in the storm and costs the month after.

Goal: a `strategy` choice among preparation plans, forecast over the storm. It replaces the catalogue's `observe`, because visiting is not preparing. The forecast shows the storm's three days; it does **not** show the month after. That is the lesson the debrief and Ruud name.

```yaml
missions:
  - id: prep_storm_week
    name: Code oranje
    kind: side
    tier: 2
    act: 3
    arc: events
    requires: {maturity: 2, missions: [t2_daily_boards]}
    opens_on: {season: winter}
    goal:
      type: strategy
      horizon_days: 24          # the 21 days to the storm plus its 3 days
      options:
        - id: storm_baseline
          name: Zoals altijd
          effects: []
          cost: 0
        - id: storm_plan_field
          name: "Veldplan: storingsbord, vrijwillige reserve en mofvoorraad"
          effects:
            - {target: monteurs, property: reserve, value: {stream: outages, people: 3}}
            - {target: cable_joint, property: reorder_point, value: 25}
          cost: 6000            # estimate: standby allowances for volunteers
        - id: storm_plan_information
          name: "Informatieplan: statusbericht in het keuzemenu en storingskaart online"
          effects:
            - {target: customer_contact, property: demand, value: 0.85}   # applies during the event only
          cost: 4000
        - id: storm_plan_all_hands
          name: "Alle hens: verlof ingetrokken, iedereen 72 uur oproepbaar"
          effects:
            - {target: monteurs, property: reserve, value: {stream: outages, people: 6}}
          cost: 2000
          trust: {monteurs: -1, on_call: -1}
          aftermath:
            after_days: 4
            days: 28
            effects:
              - {target: monteurs, property: availability, value: -0.08}   # estimate: exhaustion and sick leave after the storm
          sets_flags: [flag:storm_all_hands]
    deadline_days: 21
    event:
      at: deadline
      days: 3
      effects:
        - {target: outages, property: demand, value: 2.5}           # estimate
        - {target: customer_contact, property: demand, value: 1.2}  # estimate
      extra_if_open:
        - {target: customer_contact, property: demand, value: 1.25}  # estimate: no status message, everyone calls
        - {target: cable_joint, property: lead_time, value: 2.0}     # estimate: every DSO orders joints at once
    fail: "De storm kwam voordat er een plan lag. Monteurs werden ad hoc opgeroepen en het klantcontactcentrum was onbereikbaar. De buurnetbeheerder had zijn eigen ploegen nodig en wil voorlopig geen burenhulp afspreken."
    fail_closes: [mutual_aid_agreement]
    fail_effects: {reputation: -10}
    principles: [respect, long_term]
    briefing: "Het stormseizoen is begonnen. Vorige winter kwam code oranje op een vrijdagavond en ging het mis: de telefoon was urenlang onbereikbaar en monteurs werden uit hun bed gebeld. Ruud wil dat Zuidmark dit jaar een plan heeft voordat de storm komt. Kijk bij de storingsdienst, de mofvoorraad en het klantcontactcentrum, en kies een plan dat het team ook na de storm nog kan dragen."
    debrief: "De storm is voorbij. Kijk niet alleen naar de storingen van die drie dagen, maar ook naar de telefoon en naar je monteurs in de weken erna."
    beats:
      - {on: day, day: 20, who: kees, text: "Het KNMI heeft code oranje afgegeven voor morgen: windstoten boven de honderd kilometer per uur."}
      - {on: completed, who: esra, text: "Wat ons het meest hielp? Dat klanten bij het bellen meteen hoorden dat we het wisten en wanneer we verwachtten klaar te zijn."}
    teaches: [capacity_planning, failure_demand, compensatieregeling]
    rewards: {xp: 600, budget: 5000}
```

**Drie winters (2026-10-16).** The first `prep_storm_week` waits for Ruud's secondment: `first_requires: {facts: {all: [flag:ruud_seconded]}}` and `opens_on: {season: storm}` (1 October – 31 March, KNMI). It becomes winter 2's climax, *De storm zonder Ruud*, with the group scene `storm_night_board` at the escalation board on the first night, and under the regime the all-hands option is voiced by Frank (`who: frank`). Later winters repeat it as drafted. See `2026-10-16-drie-winters-arc.md` §7.4.

**Path dependence.**
- `flag:storm_all_hands`: the forecast looks best (most monteurs on outages), so a player who reads only the forecast picks it.
  - Its `aftermath` cuts monteur availability for four weeks. That shows in connections on_time right when `acm_visit` is measuring, if it is open.
  - Its trust cost gates `coach_*` missions with those teams.
  - In the next winter, `prep_storm_week` (recurring yearly: `recurring: {every_days: 365}`) offers *no* volunteer reserve option unless trust is back. Hint: "Vrijwilligers melden zich alleen als ze de vorige keer niet zijn uitgeknepen."
- `failed:prep_storm_week` closes `mutual_aid_agreement`; `standby_by_fault_map` remains.

**Grounding.**
- KNMI code oranje for wind: gusts from 100 km/h (from 120 km/h at the coast in the winter half-year; code geel from 75 and 90 km/h). KNMI — *Windstoten en storm*, https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/windstoten. Corrected: since 20 May 2026 code oranje and rood may be issued up to 48 h ahead, not 24 h. KNMI — *Regeling taken meteorologie en seismologie gewijzigd*, https://www.knmi.nl/over-het-knmi/nieuws/rtms-gewijzigd; Staatscourant 2026, 12631, https://zoek.officielebekendmakingen.nl/stcrt-2026-12631.html. The KNMI may now also weigh impact and warn locally instead of per province.
- Storm damage to underground infrastructure through fallen trees and saturated soil: Klimaatadaptatie Nederland — *Ondergrondse infrastructuur*, https://klimaatadaptatienederland.nl/thema-sector/infrastructuur/ondergrondse-infra
- The remaining overhead lines in rural parts: the DSO explanation quoted via Zonneplan, https://www.zonneplan.nl/noodstroomvoorziening/hoe-ontstaat-stroomuitval/ **(verify)**.
- Outage ×2.5 for 3 days, calls ×1.2/×1.5 and joints' lead time ×2: `estimate:`. NL storms cause far fewer outages than abroad because the LS/MS grid is underground, so ×2.5 over 3 days is modest. The call surge is the dominant effect, consistent with the existing failure-demand model.

**Engrossing.**
- A dated threat that will come whatever you do, and the forecast as an honest but incomplete judge.
- The aha: *in a storm, the phone is the bottleneck, not the van*.
- The second aha comes in the debrief: the best three days can cost the next month.

### 2.11 `fix_heatwave_overload` — Hitte in het trafohuisje (S, deadline, event)

Principle tested: **long_term**. Temptations:
- mobile transformers on standby (treat the symptom each summer);
- asking customers to switch their solar off (reputation).

```yaml
missions:
  - id: fix_heatwave_overload
    name: Hitte in het trafohuisje
    kind: side
    tier: 2
    act: 3
    arc: events
    requires: {maturity: 2, missions: [t2_daily_boards]}
    opens_on: {season: summer}
    goal: {type: solve, problem: heatwave_overload}
    deadline_days: 42
    event:
      at: deadline
      days: 7
      effects:
        - {target: outages.daytime, property: demand, value: 1.15}   # estimate: some stations trip in any heatwave
      extra_if_open:
        - {target: outages.daytime, property: demand, value: 1.3}    # estimate: the unknown overloaded stations trip
    fail: "De hittegolf is er. De zwakste trafohuisjes vielen uit op de zonnigste middagen. De reservetrafo's die je had kunnen plaatsen, zijn intussen naar andere netbeheerders gegaan."
    fail_closes: [preventive_transformer_swap]
    fail_effects: {reputation: -5}
    principles: [long_term]
    briefing: "Het KNMI verwacht een warme zomer, en vorige week sloegen op één zonnige middag in Nova drie zekeringen door in drie trafohuisjes. Femke: 'Bij een echte hittegolf gaan er meer. Welke weet niemand; we meten pas als er iets kapot is.' Over zes weken begint de hoogzomer. Zoek uit welke stations het eerst zullen bezwijken."
    debrief: "Je weet nu welke trafohuisjes op een zonnige middag aan hun grens zitten, en die zijn ontlast voordat de hitte kwam. De hittegolf kwam; het licht bleef aan."
    reopen: "De piekbelastingslijst is een jaar niet bijgewerkt. Er liggen honderden nieuwe panelen op de daken."
    beats:
      - {on: accepted, who: femke, text: "Iedereen denkt aan airco's. Maar kijk eens hoe laat die zekeringen doorsloegen."}
    temptations:
      - id: solar_switch_off
        who: thomas
        when: accepted
        text: "We kunnen klanten in de drukste straten vragen hun omvormer op zonnige middagen te begrenzen. Een brief, en klaar."
        accept: "Je stuurt de brief."
        decline: "Je zoekt eerst uit welke stations echt vol zitten."
        accept_sets_flags: [flag:solar_curtail_letter]
        accept_effects: {reputation: -3}
    teaches: [terugleverpiek, transformator, energietransitie]
    rewards: {xp: 800, budget: 8000}

problems:
  - id: heatwave_overload
    tier: 2
    name: Hitte in het trafohuisje
    step: outages.report
    waste: defects
    severity: high
    visibility: hidden
    kpi: on_time
    symptoms:
      - Op zonnige middagen slaan in wijken met veel zonnepanelen zekeringen door in trafohuisjes.
      - Er komen meer spanningsklachten binnen naarmate de zomer vordert.
    root_cause: Niemand weet hoe zwaar de wijktransformatoren belast zijn; er wordt alleen gekeken als er een zekering doorslaat. In straten met veel zonnepanelen draait de trafo op zonnige middagen boven zijn vermogen, en bij hitte kan hij minder hebben. De zwakste stations worden pas bekend als ze uitvallen.
    plausible_causes:
      - Het is de hitte; daar kun je niets aan doen.
      - De transformatoren zijn te oud.
      - Klanten zetten massaal hun airco aan.
    mismatch_note: Het is geen airco-avond maar een zonnige middag, en het zijn niet alle trafo's maar een paar. Wie niet meet welke, kan alleen wachten tot ze uitvallen.
    countermeasures: {peak_load_list_smart_meters: 1.0, preventive_transformer_swap: 0.7, mobile_transformers: 0.6}
    teaches: [terugleverpiek, transformator]
    effects:
      # estimate: on sunny weeks before the heat, a few station fuses already
      # blow (outages during working hours) and overvoltage complaints rise.
      - {target: outages.daytime, property: demand, value: 1.1}
      - {target: voltage_complaints, property: demand, value: 1.3}
      # estimate: a station that tripped under solar load is relieved in
      # sections before the fuse goes back in, so each repair takes longer.
      # Sim check fix 3 (verified): on time 92.6 -> 81.7 % over 5 seeds;
      # without it extra outages do not make outages late.
      - {target: outages.repair, property: touch_time, value: 1.25}
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de doorgeslagen zekeringen in trafohuisjes deze zomer viel bijna alles tussen elf en drie uur, op zonnige dagen. 's Avonds bijna niets."}
      - {tool: conversation, key: false, depth: 0, text: "'Het is de hitte. Bij dertig graden zet iedereen de airco aan.'"}
      - {tool: documents, key: true, depth: 1, at: voltage_complaints.analysis, text: "De drie stations die vorige week uitvielen, voeden straten waar op meer dan de helft van de daken zonnepanelen liggen."}
      - {tool: shadow, key: true, depth: 1, text: "Na het vervangen van de zekering legt de monteur zijn hand op de trafokast. 'Gloeiend. En er is niemand thuis die stroom gebruikt; alles gaat het net op.'"}
      - {tool: data, key: true, depth: 2, at: voltage_complaints.analysis, text: "De slimme meters achter elk station registreren elk kwartier wat er wordt teruggeleverd. Opgeteld per station kun je zien welke trafo's op een zonnige middag boven hun vermogen draaien. Niemand doet dat."}
      - {tool: documents, key: true, depth: 2, text: "Volgens de belastbaarheidsrichtlijn kan een transformator bij een hoge buitentemperatuur minder vermogen aan zonder sneller te verouderen."}

countermeasures:
  - id: peak_load_list_smart_meters
    name: Piekbelastingslijst uit slimme meters
    tier: 2
    category: visual_management
    description: Meetdata telt per trafohuisje de kwartierwaarden van de slimme meters op. Zo staat de vijf procent zwaarst belaste stations voor de zomer op een lijst, en die worden ontlast door de aftakking te verzetten, belasting te verschuiven of de trafo te vervangen.
    budget: 8000
    team_hours: {meter_office: 30, grid_analysts: 10}
    decay_days: 365   # the list must be redone every spring: panels keep coming
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: preventive_transformer_swap
    name: Trafo's vervangen waar het vaker misging
    tier: 1
    category: quality
    description: In de tien trafohuisjes met de meeste doorgeslagen zekeringen van de afgelopen zomers wordt de trafo voor de zomer vervangen door een zwaardere.
    budget: 25000   # estimate: ten distribution transformers at a few thousand euros each, installed
    team_hours: {monteurs: 40, work_prep: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: mobile_transformers
    name: Mobiele trafo's paraat
    tier: 2
    category: flow
    description: Twee mobiele transformatoren staan de hele zomer klaar. Valt een station uit, dan staat er binnen een paar uur een vervanger. Het lost de uitval niet op, maar maakt hem korter.
    budget: 12000   # estimate: rent for one summer; it comes back every summer
    team_hours: {monteurs: 15}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.**
- `chose:heatwave_overload:peak_load_list_smart_meters` is proposed as an extra `any` branch of Act V's investment option "Sensoren in het LS-net". You already know how to read the LS grid from meter data.
- `flag:solar_curtail_letter` makes Act IV's `non_firm_unused` start with `trust: {key_accounts: -1}`: customers have learned that "flex" means being asked to switch off.

**Grounding.**
- Solar feed-in peaks 11–15 h overload transformers in parts of Enexis' grid (2026 call to customers): Solar Magazine, https://solarmagazine.nl/nieuws-zonne-energie/i43218/oproep-enexis-gebruik-stroom-zonnepanelen-tijdens-zonnige-uren-overbelasting-dreigt-op-37-locaties
- Heatwave definition (KNMI: ≥ 5 days ≥ 25 °C in De Bilt, of which ≥ 3 ≥ 30 °C), used for the 7-day event: RIVM — *Achtergrond warm weer in Nederland*, https://rivm.nl/sites/default/files/2023-06/Achtergrond_Warm_weer_in_NL_Richtlijn_Hitte_Gezondheid.pdf
- Transformer loading capacity falls with ambient temperature (the ageing rate rises with hot-spot temperature): IEC 60076-7, *Loading guide for mineral-oil-immersed power transformers*, IEC 60076-7:2018 (ed. 2.0), https://webstore.iec.ch/en/publication/34351 (it replaced the 2005 edition, "oil-immersed").
- Inverters tripping above 253 V, complaints tripled: existing `inverters_tripping` grounding (Solar Magazine).
- Event factors, the fuse counts and the "five percent" list: `estimate:`.

**Engrossing.**
- The red herring (airco) is what everyone believes. The time-of-day clue overturns it, and the monteur's hand on the hot box makes it physical.
- It links back to `fix_inverters_tripping` (tier 1): the same smart-meter data, unused again.

### 2.12 `talk_regulation` — Wie houdt toezicht? (S, sector arc)

Principle tested: **improve** (know the rules you work under).

```yaml
missions:
  - id: talk_regulation
    name: Wie houdt toezicht?
    kind: side
    tier: 2
    act: 3
    arc: sector
    requires: {missions: [fix_contractor_rework]}   # staggered (four-tier audit §2, 2026-10-16)
    goal: {type: talk_to, person: jeroen, topics: 3}
    principles: [improve]
    briefing: "Jeroen Dekker, adviseur regulering, heeft een kwartier. 'Iedereen noemt de ACM als het misgaat, niemand weet wat ze eigenlijk doet.' Vraag hem naar het toezicht, de nieuwe Energiewet en wat een klant krijgt als de stroom lang uitvalt."
    debrief: "Je weet nu wie meekijkt en waarop. Jeroen: 'Onthoud vooral dit: de ACM wil zien dat je weet waar je staat. Een eerlijk getal helpt meer dan een mooi verhaal.'"
    teaches: [acm, energiewet, compensatieregeling]
    rewards: {xp: 400}
```

People topics: §4.2 (`jeroen`). The second topic gives a *sector clue* for `acm_visit` (only usable as evidence while it is open). It warns: "De klok loopt vanaf de aanvraag, niet vanaf compleet." That defuses the `late_clock` temptation for players who listened.

### 2.13 `coach_intake_lead` — Sanne leert verbeteren (S)

Principle tested: **respect** (develop people; don't hand over answers).

```yaml
missions:
  - id: coach_intake_lead
    name: Sanne leert verbeteren
    kind: side
    tier: 2
    act: 3
    arc: people
    requires: {any_of: [fix_on_call_far, fix_shift_handover], trust: {intake: 1}}   # staggered (four-tier audit §2, 2026-10-16)
    goal: {type: coach, person: sanne, sessions: 3}
    npc_experiment:
      name: Sanne belt de klant binnen een dag als er iets ontbreekt
      effects:
        - {target: connections.intake, property: ftr, value: 0.03}   # estimate: a call fixes in a day what a letter fixes in a week
      decay_days: 90
    principles: [respect, improve]
    briefing: "Sanne heeft gevraagd of jij haar wilt helpen verbeteren 'zoals jij dat doet'. Ruud: 'Doe het niet voor haar. Stel haar de vijf vragen, drie keer, en laat haar haar eigen experiment doen. Als jij het antwoord geeft, leert zij alleen dat jij het weet.'"
    debrief: "Sanne draait haar eigen experimenten en vraagt haar team nu zelf: wat is de volgende stap, en wat verwacht je? Ruud: 'Nu heb je een verbeteraar erbij, en die blijft als jij weg bent.'"
    beats:
      - {on: completed, who: sanne, text: "Ik dacht dat jij het antwoord had. Je vroeg alleen maar. Dat was irritant, en het werkte."}
    teaches: [coaching_kata, respect_for_people, improvement_kata]
    rewards: {xp: 700, reputation: 3, trust: {intake: 1}}
```

**Rules (C7).**
- A session counts only if the five Kata questions come in order: target condition, actual condition, obstacles, next experiment, when can we see what we learned.
- Telling the answer, or a closed question in place of one of the five, makes the session teach but not count, and Sanne says so ("Je zegt het nu voor me.").
- A completed coaching gives the intake team's fixes the "coached team" support (§2.8). That is the long-term payoff of respect.

**Grounding.**
- The five coaching-kata questions: Mike Rother, *Toyota Kata* (existing `coaching_kata` concept).
- Sanne's experiment and its effect: `estimate:`.

**Engrossing.** The hardest thing for a good problem solver is to *not* solve it. The game makes the player feel that.

### 2.14 `lsw_kpi_review` — Kwartaalreview (R)

Principle tested: **improve** (stagnation is regression).

```yaml
missions:
  - id: lsw_kpi_review
    name: Kwartaalreview
    kind: side
    tier: 2
    act: 3
    requires: {missions: [first_kpi_review]}
    goal: {type: kpi_review, reviews: 1}
    recurring: {every_days: 91}
    principles: [improve]
    briefing: "Het kwartaal is om. Zet het bord bij, met wat rood is erop, en bespreek met de teamleiders wat ze ervan leren."
    debrief: "Weer een kwartaal waarin het bord iets veranderde. Een bord dat niemand bespreekt, is behang."
    teaches: [kpi, leading_lagging]
    rewards: {xp: 300}
```

**Path dependence.** `done:lsw_kpi_review` repairs `flag:watermelon_review` (§1.1). Each run gives the region's fixes the steering-KPI support (§2.8) and resets the stagnation drift (it is a completed routine).

### 2.15 Repair quest example: `repair_escalation_hallway` — De andonkaart die niemand ophaalt

From the catalogue's `repair_template`, with an authored override on the problem. It opens when:
- `poor_fix:escalation_hallway` is set (the Act chose `andon_standup`, fit 0.7 against the best 1.0);
- 42 days have passed;
- the connections lead time is ≥ 5% worse than the best countermeasure's forecast.

Principles tested: **long_term** and **improve**.

```yaml
problems_override:
  escalation_hallway:
    repair:
      name: De andonkaart die niemand ophaalt
      briefing: "Joost belt je: de dagstarts lopen, de andonkaarten hangen, en toch wachten zijn mensen nog dagen op Netstrategie en de gemeente. 'We trekken aan het koord, maar er komt niemand.' Herzie je tegenmaatregel."
      debrief: "Een andonkaart gaat nu binnen een dag een laag hoger, tot iemand hem oplost. Het koord heeft eindelijk een bel aan het andere eind."

missions:
  - id: repair_escalation_hallway
    name: De andonkaart die niemand ophaalt
    kind: side
    tier: 2
    act: 3
    requires: {facts: {all: [poor_fix:escalation_hallway]}}
    goal: {type: rework_fix, problem: escalation_hallway}
    principles: [long_term, improve]
    briefing: "Joost belt je: de dagstarts lopen, de andonkaarten hangen, en toch wachten zijn mensen nog dagen op Netstrategie en de gemeente. 'We trekken aan het koord, maar er komt niemand.' Herzie je tegenmaatregel."
    debrief: "Een andonkaart gaat nu binnen een dag een laag hoger, tot iemand hem oplost. Het koord heeft eindelijk een bel aan het andere eind."
    teaches: [andon, tiered_escalation]
    rewards: {xp: 400, reputation: 2}
```

**Path dependence (why skipping it matters).**
- `repaired:escalation_hallway` (or the first-time choice `chose:escalation_hallway:tiered_escalation_24h`) is proposed as a `needs` on Act IV's CONWIP countermeasure for connections. A WIP limit makes blockers stop the line, and without a fast escalation route every blocker becomes a standstill: `needs: {any: [chose:escalation_hallway:tiered_escalation_24h, repaired:escalation_hallway, standardised:escalation_hallway]}`. Hint: "Een stop in de stroom moet binnen een dag iemand bereiken."
- A player who skips the repair sees the option locked in Act IV and can still do the repair then.

**Engrossing.** The player meets their own earlier shortcut as a measurable symptom, from a person they helped. The fix is small; the lesson ("a signal needs a responder") is the one that matters for CONWIP later.

### 2.16 Addition: `fix_stale_capacity_map` — De kaart van gisteren (S, congestion)

Principles tested: **long_term** and **respect** (for customers). Temptation: paint the whole map red.

```yaml
missions:
  - id: fix_stale_capacity_map
    name: De kaart van gisteren
    kind: side
    tier: 2
    act: 3
    arc: sector
    requires: {missions: [sector_congestion_map, t2_daily_boards]}
    goal: {type: solve, problem: stale_capacity_map}
    principles: [long_term, respect]
    briefing: "Femke's analisten draaien overuren op congestieonderzoeken, en de netstudies voor gewone aansluitingen liggen weer stil. Thomas: 'Driekwart van die onderzoeken eindigt met nee. Dat hadden ze op de kaart kunnen zien, als die klopte.' Een ondernemer van het bedrijventerrein heeft intussen de krant gebeld: hij kreeg na vier maanden een nee voor een kavel die op de kaart groen was."
    debrief: "De kaart laat nu zien wat Netstrategie weet, binnen een week na elk onderzoek. Een aanvraag in een vol gebied krijgt binnen vijf dagen eerlijk antwoord met de mogelijkheden die er wel zijn. De analisten werken weer aan studies die ertoe doen."
    reopen: "De kaart loopt weer achter. Na de laatste reorganisatie weet niemand meer wie hem bijwerkt."
    temptations:
      - id: paint_it_red
        who: femke
        when: accepted
        text: "Weet je wat het snelst is? We zetten de hele regio op rood. Dan vraagt niemand meer aan en hebben mijn mensen rust."
        accept: "Je laat de hele kaart op rood zetten."
        decline: "Je zorgt dat de kaart laat zien wat Netstrategie echt weet."
        accept_sets_flags: [flag:map_all_red]
        accept_effects: {reputation: -5, trust: {key_accounts: -1}}
    teaches: [capaciteitskaart, failure_demand, triage, netcongestie]
    rewards: {xp: 700, budget: 6000, trust: {grid_analysts: 1}}

problems:
  - id: stale_capacity_map
    tier: 2
    name: De kaart van gisteren
    # Sim check 2026-10-16: the harm lands where the shared grid analysts meet
    # the connections grid studies, so the problem sits there and the Check
    # reads connections. With the problem open the analysts become the
    # connections constraint (capacity 35.0 -> 32.9 a week, demand 30); every
    # fix restores 35.0 (+6.4 %, deterministic, not_constraint false for all
    # four). On congestion.intake no KPI was readable: congestion lead time
    # jumps +-15 d at 4 requests a week, and congestion capacity moves only
    # with the quick scan.
    step: connections.grid_study
    waste: defects
    severity: medium
    visibility: hidden
    kpi: capacity
    symptoms:
      - De netanalisten draaien overuren op congestieonderzoeken, terwijl de netstudies voor nieuwe aansluitingen weer wachten.
      - Ondernemers krijgen na maanden een nee voor een plek die op de capaciteitskaart nog ruimte had.
    root_cause: De capaciteitskaart wordt eens per kwartaal met de hand bijgewerkt, en de uitkomsten van congestieonderzoeken komen er niet op. Ondernemers vragen aan waar het net al vol is en blijven weg waar nog ruimte is. Elke kansloze aanvraag krijgt een volledig onderzoek voordat het nee volgt.
    plausible_causes:
      - Er zijn te weinig netanalisten.
      - Ondernemers kijken niet goed op de kaart.
      - Het net is overal vol; daar helpt geen kaart tegen.
    mismatch_note: Meer analisten maken meer onderzoeken met de uitkomst nee. De aanvragen ontstaan doordat de kaart achterloopt. Dit is faalvraag, ook bij grote klanten.
    countermeasures: {quick_scan_at_intake: 1.0, map_update_from_studies: 0.8, flex_options_on_map: 0.7, map_all_red: 0.6}
    teaches: [capaciteitskaart, failure_demand]
    effects:
      # estimate: about three in ten large-consumer requests would not have come
      # with a current map (4 a week → 5.2). The grid analysts are shared with
      # connections' grid studies, so the load moves there: base ~79% → ~90%.
      - {target: congestion, property: demand, value: 1.3}
      # estimate: requests in full areas lack the details a hopeful applicant
      # skips; more go back for missing data.
      - {target: congestion.intake, property: ftr, value: -0.1}
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de congestieonderzoeken van het afgelopen halfjaar eindigden er bijna drie op de vier met 'geen ruimte, wachtrij'. Een jaar geleden was dat de helft."}
      - {tool: shadow, key: false, depth: 0, at: congestion.congestion_study, text: "De analisten werken geconcentreerd en lang door. Een onderzoek kost een dag en wordt zorgvuldig gedaan."}
      - {tool: documents, key: true, depth: 1, text: "De capaciteitskaart op de website is vier maanden oud. Drie stations die volgens de onderzoeken vol zijn, staan nog op groen."}
      - {tool: listen_in, key: true, depth: 1, at: customer_contact.answer, text: "Een ondernemer: 'Op jullie kaart stond groen. Daarom heb ik die kavel gekocht. En nu zeggen jullie na vier maanden nee?'"}
      - {tool: conversation, key: true, depth: 2, at: congestion.congestion_study, text: "'Wij weten na tien minuten dat het station vol is. Maar de procedure zegt: volledig onderzoek. En de kaart bijwerken is van niemand.'"}
      - {tool: conversation, key: false, depth: 1, text: "'Ondernemers kijken toch niet op die kaart. Ze vragen gewoon overal aan.'"}

countermeasures:
  - id: quick_scan_at_intake
    name: Snelle scan bij de aanvraag
    tier: 2
    category: flow
    description: Bij binnenkomst kijkt Grootzakelijke klanten eerst naar de status van het station. Is het gebied vol, dan krijgt de klant binnen vijf werkdagen zijn plek in de wachtrij en de flexibele mogelijkheden die er wel zijn, zonder volledig onderzoek.
    budget: 4000
    team_hours: {key_accounts: 20, grid_analysts: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.congestion_study, property: applies, value: -0.3}   # estimate: three in ten skip the full study
  - id: map_update_from_studies
    name: Kaart bijwerken na elk onderzoek
    tier: 1
    category: standard_work
    description: Elk afgerond congestieonderzoek werkt binnen een week de capaciteitskaart bij; één analist is eigenaar, en het staat als vaste stap in de procedure.
    budget: 1500
    team_hours: {grid_analysts: 15}
    decay_days: 60
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: flex_options_on_map
    name: Flexmogelijkheden op de kaart
    tier: 2
    category: visual_management
    description: De kaart laat per gebied niet alleen 'vol' zien, maar ook of er non-firm contracten, capaciteitsbeperkingscontracten of een groepscontract mogelijk zijn.
    budget: 5000
    team_hours: {key_accounts: 15, grid_analysts: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: map_all_red
    name: De hele kaart op rood
    tier: 1
    category: flow
    description: De hele regio gaat op de kaart naar 'vol'. Er komen minder aanvragen binnen, ook waar wel ruimte is.
    budget: 0
    team_hours: {grid_analysts: 2}
    decay_days: null
    trust: {key_accounts: -1}
    aftermath:
      after_days: 1
      days: 999
      effects:
        - {target: congestion, property: demand, value: 0.8}   # estimate: also the requests that would have fitted stay away
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.**
- `flag:map_all_red` / `chose:stale_capacity_map:map_all_red`: Act IV `fix_non_firm_unused` and Act V `fix_flex_market_unused` start with fewer interested customers. The flex options' fits drop by 0.1 (a proposed `needs`-modifier) unless `repaired:stale_capacity_map`.
- The investment option "Flex eerst, koper later" gets the extra `none: [flag:map_all_red]` with `repaired:stale_capacity_map` as the way back.
- Hint: "Klanten moeten de kaart weer kunnen geloven."

**Grounding.**
- The capacity map: Netbeheer Nederland — *Capaciteitskaart*, https://capaciteitskaart.netbeheernederland.nl (existing concept source).
- The national queue (over 15,000 requests): `docs/energy-notes.md` (LAN update autumn 2026; Solar Magazine).
- Contract forms (non-firm ATO, CBC, group contracts): Dirkzwager — *Blogreeks juridische oplossingen netcongestie #1*, https://www.dirkzwager.nl/kennis/artikelen/blogreeks-juridische-oplossingen-netcongestie-1-alternatieve-transportrechten (31 May 2024; non-firm ATO since 31 Jan 2024 for large consumers in congestion areas, about 50% discount). The time-bound right (TDTR) is TenneT-only: ACM — *Codebesluit alternatieve transportrechten*, https://www.acm.nl/nl/publicaties/codebesluit-alternatieve-transportrechten; TenneT TDTR page (see §0.2).
- "Three in four end with no", the 4-month map age and the 1.3 demand factor: `estimate:`.
- Lean check: failure demand in B2B; triage before overprocessing; the map as outward-facing visual management.

**Engrossing.**
- The cause sits in congestion, but the pain lands at connections' grid studies (the shared analysts): a linked cause, as in Act II.
- The temptation comes from an ally under pressure, and her people *do* need rest.

### 2.17 Addition: `fix_monteur_hours` — Twee monteurs te weinig (S, technician shortage)

Principles tested: **respect** (people are the most valuable resource) and **long_term**. Temptation: overtime.

```yaml
missions:
  - id: fix_monteur_hours
    name: Twee monteurs te weinig
    kind: side
    tier: 2
    act: 3
    arc: people
    requires: {missions: [fix_contractor_rework]}
    goal: {type: solve, problem: monteur_hours}
    principles: [respect, long_term]
    briefing: "Marco vertrouwt je nu, en hij komt met zijn grootste zorg: hij heeft twee vacatures en al een halfjaar geen enkele sollicitant. 'Heel Nederland zoekt monteurs. Ik vind ze niet.' Hij wil dat het MT overwerk goedkeurt. Kijk eerst wat zijn monteurs met hun dag doen."
    debrief: "Je hebt de twee monteurs gevonden, in de bus. Wat ze aan materiaal halen en papierwerk kwijt waren, besteden ze nu aan het vak. Marco: 'Ze zijn ook gewoon minder moe.'"
    reopen: "De monteurs rijden 's ochtends weer eerst naar de campus. Het klaarzetten van materiaal is in de drukte vergeten."
    temptations:
      - id: overtime
        who: marco
        when: accepted
        text: "Laat het MT gewoon vier uur overwerk per week per monteur goedkeuren. Ze verdienen er goed aan en het gat is dicht."
        accept: "Je steunt het overwerk."
        decline: "Je kijkt eerst waar hun uren nu naartoe gaan."
        accept_sets_flags: [flag:overtime_monteurs]
        accept_effects: {trust: {monteurs: -1}}
    teaches: [monteurstekort, waste_skills, respect_for_people]
    rewards: {xp: 700, budget: 6000, trust: {monteurs: 1}}

problems:
  - id: monteur_hours
    tier: 2
    name: Twee monteurs te weinig
    step: connections.execution
    waste: skills
    severity: high
    visibility: subtle
    kpi: capacity
    symptoms:
      - Twee vacatures voor monteurs staan al een halfjaar open, zonder sollicitanten.
      - Monteurs beginnen hun dag op de campus en zijn pas om half negen bij de eerste klus.
    root_cause: Monteurs halen elke ochtend zelf hun werkbonnen en materiaal op de campus en vullen 's middags papieren werkbonnen in. Zo gaat ruim anderhalf uur per dag op aan werk waarvoor geen monteur nodig is.
    plausible_causes:
      - Er zijn gewoon te weinig monteurs op de markt.
      - De monteurs werken te langzaam.
      - De klussen zijn zwaarder geworden.
    mismatch_note: Er zijn inderdaad te weinig monteurs op de markt, maar dat verklaart niet waar de uren van de monteurs die er wel zijn naartoe gaan. Anderhalf uur per dag aan halen en papier is meer dan de twee monteurs die je zoekt.
    countermeasures: {kitting_night_before: 1.0, digital_work_orders: 0.8, start_from_home: 0.7, monteur_overtime: 0.6}
    teaches: [monteurstekort, waste_skills]
    effects:
      # estimate: about an hour and a half of an eight-hour day goes to
      # fetching work orders and materials and to paper forms: availability
      # 0.85 -> 0.65, 13 monteurs x 1.6/8 = 2.6 FTE. Sim check fix 4
      # (verified): monteur load 71 % -> 94 % and the monteurs become the
      # connections constraint, so the fixes show; at -0.12 nothing moved.
      - {target: monteurs, property: availability, value: -0.20}
    clues:
      - {tool: shadow, key: true, depth: 0, text: "Om zeven uur staat de monteur bij de balie op de campus voor zijn werkbonnen, daarna een halfuur in het magazijn. Om half negen is hij bij de eerste klus."}
      - {tool: data, key: false, depth: 0, text: "Op de vacatures voor monteurs is in een halfjaar niemand afgekomen. In de hele regio staan er tientallen open."}
      - {tool: time_study, key: true, depth: 1, text: "Van een werkdag van acht uur gaat ruim anderhalf uur op aan werkbonnen halen, materiaal zoeken en 's middags formulieren invullen."}
      - {tool: conversation, key: true, depth: 1, text: "'Ik ben monteur geworden om te monteren. Niet om in de rij bij het magazijn te staan.'"}
      - {tool: documents, key: true, depth: 2, at: connections.planning, text: "De planning is de avond ervoor klaar. Het materiaal per klus staat erin, maar niemand zet het klaar."}
      - {tool: material_check, key: true, depth: 2, at: connections.materials, text: "Het magazijn is om half zeven open. Wat een monteur nodig heeft, weet het pas als hij aan de balie staat."}

countermeasures:
  - id: kitting_night_before
    name: Materiaal klaarzetten per klus
    tier: 2
    category: flow
    description: Het magazijn zet 's avonds per monteur het materiaal voor de klussen van morgen klaar, op basis van de planning. De bus wordt geladen door wie 's avonds dienst heeft; de monteur rijdt 's ochtends meteen naar zijn eerste klus.
    budget: 5000
    team_hours: {planners: 20, monteurs: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: digital_work_orders
    name: Digitale werkbon op de tablet
    tier: 2
    category: flow
    description: De werkbon staat op de tablet en wordt ter plekke afgemeld; geen papieren formulieren meer 's middags.
    budget: 9000
    team_hours: {monteurs: 20, planners: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: start_from_home
    name: Starten vanaf huis
    tier: 1
    category: flow
    description: Monteurs nemen de bus mee naar huis en krijgen de werkbonnen digitaal; alleen voor bijzonder materiaal komen ze langs de campus.
    budget: 2000
    team_hours: {planners: 10}
    decay_days: 60
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: monteur_overtime
    name: Vier uur overwerk per week
    tier: 1
    category: people
    description: Elke monteur werkt vier uur per week over. Het gat in de capaciteit is direct dicht.
    budget: 10000   # estimate: overtime premium over a quarter
    team_hours: {planners: 2}
    decay_days: 90
    trust: {monteurs: -1}
    aftermath:
      after_days: 56
      days: 56
      effects:
        - {target: monteurs, property: availability, value: -0.05}   # estimate: fatigue and sick leave
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.1}
```

**Path dependence.**
- `flag:overtime_monteurs` / `chose:monteur_hours:monteur_overtime`: Act IV `training_capacity`'s *train-the-trainer* (experienced monteurs train the new ones) gets `needs: {none: [flag:overtime_monteurs], any: [...]}`, with `repaired:monteur_hours` as the way back. Hint: "De ervaren monteurs moeten ruimte hebben om op te leiden."
- `done:fix_monteur_hours` with kitting or digital work orders adds an `any` branch to Act IV `t3_crew_strategy`'s Havenzij street-works crew option.

**Grounding.**
- Technician shortage: about 28,000 technicians short up to 2029 (Netbeheer Nederland, *Stand van de uitvoering Q1 2025*, https://www.netbeheernederland.nl/sites/default/files/2025-03/stand_van_de_uitvoering_q1_2025_1.pdf). The scale-up plan is +5,000 by 2030, with training capacity as the binding constraint (Solar Magazine, https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan).
- One hour a day of non-monteur work: `estimate:` (no public time-use study found). The content test must check that 0.12 of availability hurts connections' lead time and outages' on-time without making monteurs the constraint of connections.
- Lean check: waste of skills (people's talent on non-value work); kitting is a standard Lean logistics practice; overtime is a capacity fix, not an improvement.

**Engrossing.** The sector's most famous problem, presented by a person you just earned the trust of. The answer ("they were in the van all along") reframes the shortage without denying it.

### 2.18 Addition: `fix_klic_expired` — De verlopen graafmelding (S, permits/KLIC)

Principle tested: **long_term**, with a **non-negotiable safety line**. The temptation (dig on an outdated melding) is illegal and must never pay.

```yaml
missions:
  - id: fix_klic_expired
    name: De verlopen graafmelding
    kind: side
    tier: 2
    act: 3
    chapter: Samen bouwen
    requires: {missions: [fix_escalation_hallway]}
    goal: {type: solve, problem: klic_expired}
    principles: [long_term]
    briefing: "Nu de rode kaartjes een laag hoger gaan, ziet Ruud er één steeds terugkomen: 'KLIC verlopen'. Monteurs staan bij een sleuf en mogen niet graven omdat de graafmelding niet meer klopt. Linda: 'Elke dag een paar klussen die we opnieuw moeten plannen.'"
    debrief: "De graafmelding gaat de deur uit als de klus definitief gepland is, niet maanden eerder bij het ontwerp. Een monteur staat niet meer bij een sleuf zonder geldige kaart."
    reopen: "De graafmeldingen worden weer bij het ontwerp gedaan. Werkvoorbereiding: 'Zo deden we het altijd.'"
    temptations:
      - id: dig_anyway
        who: monteur
        when: accepted
        text: "Die melding is twee weken oud, het is dezelfde straat. Laat ons gewoon graven, dan halen we de planning."
        accept: "Je laat de monteurs graven op de oude melding."
        decline: "Je laat de monteurs niet graven zonder geldige melding."
        accept_sets_flags: [flag:dug_without_klic]
        accept_effects: {cost: 25000, reputation: -10}   # estimate: a hit cable under an invalid melding; liability and the regulator
    teaches: [klic_melding, waste_waiting, standard_work]
    rewards: {xp: 700, budget: 6000}

problems:
  - id: klic_expired
    tier: 2
    name: De verlopen graafmelding
    step: connections.execution
    waste: waiting
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Monteurs staan bij een sleuf en mogen niet graven, omdat de graafmelding verlopen is of niet bij de klus hoort.
      - Op het escalatiebord is 'KLIC verlopen' het vaakst terugkerende rode kaartje.
    root_cause: De graafmelding wordt gedaan door Werkvoorbereiding bij het ontwerp, maanden voor de uitvoering. Een melding mag pas kort voor het graven worden gedaan; zodra een klus later of opnieuw wordt gepland, klopt hij niet meer. Niemand bij Planning kijkt ernaar.
    plausible_causes:
      - Het Kadaster levert de gegevens te laat.
      - De monteurs vergeten de kaarten mee te nemen.
      - De gemeente geeft de vergunning te laat.
    mismatch_note: Het Kadaster levert binnen een paar werkdagen. De melding wordt op het verkeerde moment in de stroom gedaan, door de verkeerde afdeling.
    countermeasures: {klic_at_planning: 1.0, klic_expiry_alert: 0.9, klic_in_readiness_check: 0.8}
    teaches: [klic_melding, waste_waiting]
    effects:
      # estimate: about one job in twelve finds no valid melding on site and goes
      # back to planning with its 5-day rework wait (a new melding takes at least
      # 3 working days).
      - {target: connections.execution, property: ftr, value: -0.08}
    clues:
      - {tool: shadow, key: true, depth: 0, text: "De monteur pakt de KLIC-kaart uit het dossier: de melding is drie maanden oud. Hij belt Planning en rijdt terug."}
      - {tool: documents, key: false, depth: 0, at: connections.permit, text: "De vergunning van de gemeente is nog vier maanden geldig."}
      - {tool: documents, key: true, depth: 1, at: connections.design, text: "De werkinstructie van Werkvoorbereiding: graafmelding doen als het ontwerp klaar is. Dat is gemiddeld drie maanden voor de uitvoering."}
      - {tool: data, key: true, depth: 1, at: connections.planning, text: "Van de klussen die vorige maand opnieuw werden gepland, had één op de vier als reden 'KLIC verlopen of onjuist'."}
      - {tool: conversation, key: true, depth: 2, at: connections.planning, text: "'Wij plannen de klus. Of er een geldige melding is, weten we niet; dat is van Werkvoorbereiding.'"}
      - {tool: conversation, key: true, depth: 2, at: connections.design, text: "'Ik doe de melding als het ontwerp af is, dan ben ik ervan af. Wanneer er gegraven wordt, weet ik niet.'"}

countermeasures:
  - id: klic_at_planning
    name: Graafmelding bij het definitief plannen
    tier: 1
    category: standard_work
    description: Planning doet de graafmelding zodra een klus definitief is ingepland, tussen drie en twintig werkdagen voor het graven, en hangt de KLIC-kaart digitaal aan de werkbon.
    budget: 1000
    team_hours: {planners: 15, work_prep: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: klic_expiry_alert
    name: Waarschuwing bij een verlopen melding
    tier: 2
    category: quality
    description: Het planningssysteem toont bij elke klus de datum van de graafmelding en waarschuwt als de klus erbuiten valt; zonder geldige melding geen vrijgave.
    budget: 6000
    team_hours: {planners: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: klic_in_readiness_check
    name: KLIC in de gereedheidscheck
    tier: 1
    category: standard_work
    description: Bij de check twee dagen voor de uitvoering kijkt Planning ook of de graafmelding geldig is; zo niet, dan gaat er direct een nieuwe uit en schuift de klus een paar dagen.
    budget: 500
    team_hours: {planners: 10}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Path dependence.** `flag:dug_without_klic` is never rewarded:
- it costs at once;
- it adds a fail-safe beat in Act V (`nta8120_audit` finds the incident);
- `fix_digging_damage`'s fix loses one support step (catalogue §2.8: the leader routine is undermined).

**Grounding.**
- KLIC timing: a graafmelding is made at the earliest 20 working days and at the latest 3 working days before the digging starts; the information arrives within 2 working days and must be on site. Kadaster — *Op welk moment moet u een KLIC-melding doen?*, https://www.kadaster.nl/-/op-welk-moment-moet-u-een-klic-melding-doen-; Kadaster — *KLIC-melding zakelijk*, https://www.kadaster.nl/zakelijk/producten/graafwerk/klic-melding; Defensie — *Graafmelding verplicht*, https://www.defensie.nl/onderwerpen/t/taken-in-nederland/defensie-pijpleidingen/graafmelding-verplicht. Nuance from the Kadaster: grid operators deliver within 1 working day and the Kadaster sends the link after at most 2 working days; a late supplement can still follow.
- CROW 500 careful digging process: via CUMELA, https://www.cumela.nl/media/1629/download?delta=0 **(verify)**.
- Municipal permit validity (around 6 months under a local AVOI ordinance): https://lokaleregelgeving.overheid.nl/CVDR3886/1 (one municipality; it varies).
- "One in twelve", "one in four replans" and the €25k incident: `estimate:`.

**Engrossing.**
- The escalation board you built finds this problem for you. The act's theme pays off.
- The aha: the work is right, the *moment* is wrong. A process step owned by the wrong department.

---

### 2.19 Addition (2026-10-16): the act's human thread — `thread_zandbergen` — De boerderij aan de Noorderweg (S)

PLAN §4.2.2 (one human thread per act; arc doc §9.1). **A face:** Daan Zandbergen (16), whose father runs a dairy farm with two milking robots at the end of a rural MS line north of Nova. **A number:** Daan called the contact centre fourteen times during three outages this year; the last outage lasted 3 hours 40 minutes (estimates, in line with `fix_on_call_far`'s "one in four night outages longer than four hours"). **A choice:** put the farm at the top of the restoration list, or tell him honestly what we know and call back. **A payoff:** Daan's card at the end of the act, and his 04:10 call in the storm.

Principles tested: **respect** (a teenager on the phone is a customer too) and **long_term** (a favour now is a queue someone else waits in). It takes a side slot only from the storm's warning to the storm's end, so it never competes with the act's mains for long.

```yaml
missions:
  - id: thread_zandbergen
    name: De boerderij aan de Noorderweg
    kind: side
    tier: 2
    act: 3
    arc: threads
    requires: {any_of: [fix_on_call_far, fix_shift_handover], facts: {all: [flag:ruud_seconded]}}
    opens_on: {beat: storm_warning}          # the KNMI warning beat of prep_storm_week (day 20 of its window)
    deadline_days: 4                        # the storm's three days and the morning after
    goal: {type: talk_to, dialog: daan_storm_call, outcome: partial}
    principles: [respect, long_term]
    briefing: "Code oranje voor morgen. Esra: 'Als het in het noorden uitvalt, belt Daan Zandbergen. Zestien jaar. Dit jaar veertien keer, bij drie storingen. De laatste duurde drie uur en veertig minuten. Zijn vader staat dan met een geleend aggregaat in de stal, met honderdveertig koeien.' Als hij belt, neem jij op."
    debrief: "{daan_line}"
    debrief_variants:
      honest: "Daan belde één keer. Om vijf uur belde jij terug, zoals je zei. De stroom kwam om kwart over vijf. Zijn vader stuurde een foto van de robot die weer melkte. Er stond geen tekst bij. Die was niet nodig."
      favour: "De boerderij kwam als eerste terug. Zorgcentrum De Linde, twee kilometer verderop, kwam veertig minuten later dan gepland. Niemand weet dat, behalve Kees. Kees weet het."
      not_reached: "Daan belde zes keer. De laatste keer zei hij alleen: 'Oké.'"
    beats:
      - {on: accepted, who: esra, text: "Hij vraagt nooit om een manager. Alleen of we het weten."}
      - {on: completed, who: kees, text: "Om vier uur stond die boerderij op mijn wand. Eén stip tussen honderden. Raar, als je weet wie daar woont."}
      - {on: act_end, who: daan, text: "{card}"}    # the card on the kantine wall (arc doc §9.1), with or without the information plan
    temptations:
      - id: farm_first
        who: kees
        when: accepted
        text: "Ik kan die boerderij bovenaan de herstellijst zetten. Dan zit die jongen niet de hele nacht te bellen. Niemand die het merkt."
        accept: "Je laat de boerderij voorgaan op de herstellijst."
        decline: "De herstellijst blijft zoals hij is; jij belt Daan zelf terug."
        accept_sets_flags: [flag:queue_jumped]     # the same flag the tier-4 audit reads as a finding
        accept_effects: {person_trust: {kees: -5}, effects_during_event: [{target: outages, property: wait_time, value: 1.05}]}   # estimate: everyone else waits a little longer
    teaches: [failure_demand, customer_value]
    rewards: {xp: 500, reputation: 2}
```

**Path dependence.**
- `flag:queue_jumped` is the tier-4 audit's finding ("Een aanvraag is buiten het prioriteringskader om voorgetrokken"), here for an outage. It costs reputation −10 at the audit. The favour is invisible on the night and visible two years later.
- `storm_plan_information` (the storm's information plan) makes Daan's call start 10 higher: he heard on the phone menu that Voltana knew.
- `done:fix_on_call_far` gives Daan +15 (he knows the voice) and the payoff line about the standby location ("vijftig minuten").
- `heard:daan_storm` is read in Act IV by `fix_priority_first_come`: the farm appears in its clues as a customer who needs a *time*, not priority (the framework's lesson).

**Dialog:** `daan_storm_call` (arc doc §9.1).

**Grounding.** Milking robots and cooling depend on power; dairy farms keep or borrow generators for outages (sector practice; `estimate:` farm size 140 cows, two robots). Failure demand during outages: the existing contact-centre model.

## 3. Summary tables

### 3.1 Missions (22)

| id | Act | Kind | Goal type | Problem | Deadline → door | Principles | Temptation (later cost) |
|---|---|---|---|---|---|---|---|
| first_kpi_review | II | M | kpi_review | — | — | long_term, improve | watermelon report (a KR is missing in the OKR) |
| sector_congestion_map | II | S | talk_to | — | — | improve | — |
| t2_daily_boards | III | M | routine | — | — | respect, improve | digital dashboard (no visual-management support) |
| fix_cause_unknown | III | M | solve | cause_unknown | — | long_term, respect | policed cause field (Goodhart; Act V Pareto locked) |
| fix_on_call_far | III | M (B) | solve | on_call_far | — | long_term, respect | extra on-call shifts (fatigue; Act IV option locked) |
| fix_shift_handover | III | M (N) | solve | shift_handover | — | improve | — |
| fix_contractor_rework | III | M | solve | contractor_rework | — | respect, long_term | switch contractor (new crews' rework; Act IV one-dig locked) |
| fix_escalation_hallway | III | M | solve | escalation_hallway | — | improve, long_term | cheap andon (repair quest; Act IV CONWIP locked) |
| acm_visit | III | Ms | measure | — | 70 d → `acm_improvement_plan`; pilot closed | long_term | late clock (audit finding in Act V) |
| acm_improvement_plan | III | S (recovery) | measure | — | 112 d → rep −5 | long_term, improve | — |
| t2_first_okr | III | M | okr | — | — | long_term, improve | output KR (silo fix drifts back) |
| fix_safety_stock_calendar | III | S | solve | safety_stock_calendar | — | long_term | double stock (obsolete GPRS meters) |
| fix_lmra_tickbox | III | S | solve | lmra_tickbox | — | respect, long_term (exception) | — (containment is the right short-term move) |
| prep_storm_week | III | S | strategy | — (event) | 21 d → `mutual_aid_agreement` closed | respect, long_term | all hands (sick leave, trust, no volunteers next year) |
| fix_heatwave_overload | III | S | solve | heatwave_overload | 42 d → `preventive_transformer_swap` closed | long_term | curtailment letter (flex distrust in Act IV) |
| talk_regulation | III | S | talk_to | — | — | improve | — (defuses `late_clock`) |
| coach_intake_lead | III | S | coach | — | — | respect, improve | giving the answer (session doesn't count) |
| lsw_kpi_review | III | R | kpi_review | — | — | improve | skipping it (stagnation) |
| repair_escalation_hallway | III | S (repair) | rework_fix | escalation_hallway | — | long_term, improve | — |
| fix_stale_capacity_map | III | S | solve | stale_capacity_map | — | long_term, respect | map all red (flex options weaker later) |
| fix_monteur_hours | III | S | solve | monteur_hours | — | respect, long_term | overtime (train-the-trainer locked) |
| fix_klic_expired | III | S | solve | klic_expired | — | long_term (safety line) | dig anyway (never pays) |

The 1 + 3 rule holds: one main at a time (the fork offers two, the player takes one), and the sides open spread over the act. Milestones take no slot.

### 3.2 Problems (11) and countermeasures (36)

| Problem | Step | Waste | KPI | Countermeasures (fit) |
|---|---|---|---|---|
| cause_unknown | outages.repair | defects | on_time | cause_codes_pareto 1.0 · repeat_fault_analysis 0.9 · stop_and_record 0.7 · mandatory_cause_field 0.6 |
| on_call_far | outages.locate | transport | on_time | standby_by_fault_map 1.0 · smaller_on_call_areas 0.8 · mutual_aid_agreement 0.7 · extra_on_call_shifts 0.65 |
| shift_handover | outages.report | overprocessing | lead_time | handover_standard_at_board 1.0 · open_actions_list 0.8 |
| contractor_rework | connections.execution | defects | first_time_right | shared_trench_standard 1.0 · first_job_inspection 0.8 · contractor_scorecard 0.7 · switch_contractor 0.6 |
| escalation_hallway | connections.design | waiting | lead_time | tiered_escalation_24h 1.0 · andon_standup 0.7 |
| safety_stock_calendar | meters.reserve_meter | waiting | on_time | reorder_point_working_days 1.0 · warehouse_kanban 0.9 · double_stock 0.6 |
| lmra_tickbox | connections.execution | overprocessing | first_time_right | task_specific_lmra 1.0 · stop_the_work_andon 0.8 · two_person_rule_old_cabinets 0.6 (containment) |
| heatwave_overload | outages.report | defects | on_time | peak_load_list_smart_meters 1.0 · preventive_transformer_swap 0.7 · mobile_transformers 0.6 |
| stale_capacity_map | connections.grid_study | defects | capacity | quick_scan_at_intake 1.0 · map_update_from_studies 0.8 · flex_options_on_map 0.7 · map_all_red 0.6 |
| monteur_hours | connections.execution | skills | capacity | kitting_night_before 1.0 · digital_work_orders 0.8 · start_from_home 0.7 · monteur_overtime 0.6 |
| klic_expired | connections.execution | waiting | lead_time | klic_at_planning 1.0 · klic_expiry_alert 0.9 · klic_in_readiness_check 0.8 |

All 8 wastes but motion appear in the act. Motion is covered in tier 1 (`training_tray`).

Four problems sit on `connections.execution`. Their `ftr` effects add up only if several are open at once (at most 1 main + 3 sides). K5's content test should check the worst legal combination still leaves `ftr` ≥ 0.4.

---

## 4. People topics (`content/people.yaml` drafts)

### 4.1 Thomas Visser (`sector_congestion_map`)

```yaml
people:
  - id: thomas
    name: Thomas Visser
    role: accountmanager grootzakelijk
    place: congestion.offer
    topics:
      - id: capaciteitskaart
        ask: "Hoe weet een ondernemer of er nog ruimte is op het net?"
        open: "Op de capaciteitskaart van de netbeheerders zie je per gebied of er ruimte is voor afname en voor teruglevering. Rood is vol, met een wachtrij. Maar die kaart is zo goed als wie hem bijwerkt; bij ons is dat eens per kwartaal, met de hand."
        closed: "Op de kaart."
        teaches: [capaciteitskaart]
        sector_clue: {problem: stale_capacity_map, text: "De capaciteitskaart van Zuidmark wordt eens per kwartaal met de hand bijgewerkt; uitkomsten van congestieonderzoeken komen er niet vanzelf op."}
      - id: alternatieve_transportrechten
        ask: "Wat kan een klant als het net vol is?"
        open: "Soms meer dan hij denkt. Met een non-firm contract krijgt hij transport, behalve op de momenten dat het net vol zit, tegen een lager tarief. Met een capaciteitsbeperkingscontract levert een bedrijf dat al aangesloten is tegen betaling tijdelijk capaciteit in. En op het hoogspanningsnet van TenneT bestaat een tijdsduurgebonden recht: transport in minstens 85 procent van de uren. Het lastige is dat klanten het pas horen als ze maanden hebben gewacht."
        closed: "Dan komt hij op de wachtlijst."
        teaches: [alternatieve_transportrechten, netcongestie]
      - id: gotork
        ask: "Wat gebeurt er met capaciteit die een klant niet gebruikt?"
        open: "Die kan terug. Sinds de ACM-regels over ongebruikte capaciteit mag een netbeheerder vragen of een klant die structureel veel minder gebruikt dan hij gecontracteerd heeft, iets wil teruggeven. Wat vrijkomt gaat naar de wachtrij."
        closed: "Die blijft van hem."
        teaches: [gotork]
```

### 4.2 Jeroen Dekker (`talk_regulation`)

```yaml
people:
  - id: jeroen
    name: Jeroen Dekker
    role: adviseur regulering
    place: connections.intake
    topics:
      - id: acm_toezicht
        ask: "Waar kijkt de ACM bij ons naar?"
        open: "Naar tarieven, naar hoe we aansluiten en transporteren, en of we ons aan de codes houden. Over de aansluittermijn: de rechter heeft het oude ACM-besluit in 2024 vernietigd, dus er is geen harde termijn meer. De ACM kijkt nog wel naar achttien tot tweeëntwintig weken als redelijk. En de klok loopt vanaf de aanvraag, niet vanaf het moment dat wij hem compleet vinden."
        closed: "Naar alles, eigenlijk."
        teaches: [acm, aansluittermijn]
        sector_clue: {mission: acm_visit, text: "De ACM meet de aansluittermijn vanaf de aanvraag van de klant, niet vanaf het moment dat het dossier compleet is."}
      - id: energiewet
        ask: "Wat veranderde er met de nieuwe Energiewet?"
        open: "Sinds 1 januari 2026 vervangt de Energiewet de Elektriciteitswet 1998 en de Gaswet. Formeel heten wij nu distributiesysteembeheerder, al zegt iedereen nog netbeheerder. Voor de klant verandert er weinig; voor ons staan regels die in losse wetten zaten nu in één wet."
        closed: "Andere namen, vooral."
        teaches: [energiewet]
      - id: compensatieregeling
        ask: "Wat krijgt een klant als de stroom lang uitvalt?"
        open: "Bij een storing van meer dan vier uur krijgt een huishouden een vaste vergoeding, en per vier uur extra komt er iets bij. Geen schadevergoeding, een tegemoetkoming. Maar tel het op over een hele straat en een paar nachten, en je ziet waarom vier uur voor ons een harde grens is."
        closed: "Een vergoeding."
        teaches: [compensatieregeling]
```

People to add to the cast (catalogue §2.3):
- `erik` (Erik Smits, uitvoerder of contractor Grondwerk Zuid; place connections.execution; Act III);
- `it_manager`, `inkoop`, `magazijn`, `mt_member`, `monteur` (generic voices for temptations; no topics).

---

## 5. New concepts (`content/concepts.yaml` drafts)

Thirteen new concepts are needed: `daily_management`, `pareto`, `tiered_escalation`, `andon`, `safety_stock`, `lmra`, `storingsregistratie`, `capaciteitskaart`, `alternatieve_transportrechten`, `gotork`, `energiewet`, `compensatieregeling`, `terugleverpiek`.

The catalogue's `non_firm` and `compensatie` are folded into `alternatieve_transportrechten` and `compensatieregeling`.

```yaml
concepts:
  - id: daily_management
    name: Dagelijkse sturing
    category: lean
    short: "Elke dag kort bij het bord: hoe ging het gisteren, wat hindert ons vandaag, wie pakt het op."
    text: >-
      Dagelijkse sturing maakt afwijkingen zichtbaar terwijl ze nog klein zijn. Het
      team schrijft zijn eigen getallen op het bord, bespreekt in een paar minuten
      wat er hindert en spreekt af wie wat oppakt. Leidinggevenden komen kijken en
      helpen met wat het team niet zelf kan oplossen. Zonder die laatste stap wordt
      het bord een klaagmuur.
    example: >-
      Werkvoorbereiding begint elke ochtend om kwart over acht bij het bord: de
      stapel, het oudste dossier en de rode kaartjes van gisteren.
    estimate: "Lean practice (D. Mann, Creating a Lean Culture); no sector numbers."

  - id: pareto
    name: Pareto-analyse
    category: measure
    short: "Sorteer oorzaken van groot naar klein: vaak veroorzaken een paar oorzaken het meeste."
    text: >-
      Een Pareto-diagram zet oorzaken of categorieën op volgorde van hoe vaak ze
      voorkomen. Vaak blijkt een klein deel van de oorzaken het grootste deel van
      de problemen te geven, de 80/20-regel. Het werkt alleen als de oorzaken goed
      zijn vastgelegd: als 'onbekend' de hoogste staaf is, leer je eerst iets over
      je registratie.
    example: >-
      De storingsdienst bekijkt elke maandag de Pareto van de storingen per oorzaak
      en per kabeltraject. De hoogste staaf krijgt een A3.
    source:
      title: ASQ — What is a Pareto chart?
      url: https://asq.org/quality-resources/pareto

  - id: tiered_escalation
    name: Gelaagde escalatie
    category: lean
    short: "Wat een team niet zelf kan oplossen, gaat dezelfde dag een laag hoger, tot iemand het oplost."
    text: >-
      Bij gelaagde escalatie volgen de dagstarts elkaar op: eerst het team, dan de
      afdeling, dan de regio. Een probleem dat een laag niet zelf kan oplossen, gaat
      mee naar de volgende, met een afgesproken tijd waarbinnen het een eigenaar
      heeft. Zo wacht niemand een week op het wekelijkse overleg.
    example: >-
      Een vraag aan de gemeente over een tracé hangt om kwart over acht op het bord
      van Werkvoorbereiding en heeft om half tien een eigenaar bij de regio.
    estimate: "Lean practice (tiered daily accountability, D. Mann); the 24-hour rule is a common choice, not a norm."

  - id: andon
    name: Andon
    category: lean
    short: "Een signaal waarmee iedereen een probleem meldt, waarna er direct iemand komt helpen."
    text: >-
      Bij Toyota trekt een medewerker aan een koord als er iets misgaat; de lijn
      stopt en de teamleider komt. Het signaal is maar de helft: zonder iemand die
      komt, leert een team dat melden geen zin heeft. Op kantoor kan een andon een
      rood kaartje op het bord zijn.
    example: >-
      Een monteur die bij een onveilige meterkast stopt, belt de teamleider. De
      stop telt als 'veilig gestopt', niet als 'niet gehaald'.
    source:
      title: Lean Enterprise Institute — Andon (lexicon)
      url: https://www.lean.org/lexicon-terms/andon/

  - id: safety_stock
    name: Bestelpunt en veiligheidsvoorraad
    category: measure
    short: "Bestel opnieuw als de voorraad net genoeg is voor de levertijd, plus een buffer voor schommelingen."
    text: >-
      Het bestelpunt is het verbruik tijdens de levertijd plus een veiligheidsvoorraad
      voor de schommelingen in verbruik en levertijd. Reken je het verbruik per
      kalenderdag terwijl er alleen op werkdagen iets de deur uit gaat, dan ligt het
      bestelpunt te laag en raakt de voorraad 'onverwacht' op.
    example: >-
      Er gaan 40 slimme meters per week de deur uit, acht per werkdag. Wie door zeven
      deelt, rekent met vijf à zes per dag en bestelt te laat.
    estimate: "Standard inventory practice (reorder point = demand over the lead time + safety stock); Zuidmark's numbers come from content/value_streams.yaml."

  - id: lmra
    name: LMRA (laatste-minuut-risicoanalyse)
    category: sector
    short: "Eén minuut nadenken over de risico's van deze klus, met het recht om te stoppen."
    text: >-
      Vlak voor het werk kijkt de uitvoerder zelf of het veilig kan: wat is er hier
      anders dan verwacht, wat kan er misgaan, en kan ik dat beheersen? Een LMRA
      duurt ongeveer een minuut en hoort geen formulier te zijn. Is een antwoord
      'nee', dan stop je en overleg je. Een lange vragenlijst die je afvinkt, doet
      het tegenovergestelde.
    example: >-
      Bij een meterkast van voor 1970 met blanke delen stopt de monteur en belt zijn
      teamleider, in plaats van 42 vragen af te vinken.
    source:
      title: VOLTA — Informatie LMRA (2020)
      url: https://volta-org.be/media/ieqbrpzq/volta-informatie_lmra_2020.pdf
    verify: true

  - id: storingsregistratie
    name: Storingsregistratie
    category: sector
    short: "Netbeheerders leggen elke storing vast met oorzaak en duur; daar leer je van, als het klopt."
    text: >-
      De Nederlandse netbeheerders registreren hun storingen sinds 1976 landelijk,
      met onder meer de oorzaak. In het laagspanningsnet waren graafwerk,
      veroudering en sluimerende storingen in 2018 de grootste oorzaken. Een oorzaak
      die als 'onbekend' wordt vastgelegd, is een gemiste les.
    example: >-
      Bij Voltana stond bij 41 procent van de storingen 'oorzaak onbekend', tot de
      monteurs zelf de codes mochten kiezen en er elke week naar gekeken werd.
    source:
      title: Netbeheer Nederland — Betrouwbaarheid van elektriciteitsnetten in Nederland, resultaten 2018
      url: https://www.netbeheernederland.nl/sites/default/files/Betrouwbaarheid_elektriciteitsnetten_in_Nederland_2018_150.pdf

  - id: capaciteitskaart
    name: Capaciteitskaart
    category: sector
    short: "De kaart waarop netbeheerders laten zien waar het net nog ruimte heeft."
    text: >-
      Op de capaciteitskaart van Netbeheer Nederland zie je per gebied of er nog
      transportcapaciteit is voor afname en voor teruglevering, of dat er een
      wachtrij is. Ondernemers en gemeenten kiezen er locaties mee. Een kaart die
      achterloopt, stuurt mensen naar plekken die vol zijn en weg van plekken met
      ruimte.
    example: >-
      Een ondernemer kocht een kavel op Nova's bedrijventerrein omdat de kaart groen
      was. Het station was al maanden vol.
    source:
      title: Netbeheer Nederland — Capaciteitskaart elektriciteitsnet
      url: https://capaciteitskaart.netbeheernederland.nl

  - id: alternatieve_transportrechten
    name: Alternatieve transportrechten en flexcontracten
    category: sector
    short: "Contracten waarmee een klant toch stroom kan krijgen als het net niet altijd ruimte heeft."
    text: >-
      Naast vaste capaciteit bestaan er contractvormen voor een vol net. Bij een
      non-firm contract kan de netbeheerder het transport beperken als het net vol
      zit, tegen een lager tarief. Met een capaciteitsbeperkingscontract levert een
      bedrijf tegen betaling tijdelijk capaciteit in. Op het hoogspanningsnet van
      TenneT bestaat sinds 2024 een tijdsduurgebonden transportrecht: transport in
      minstens 85 procent van de uren van het jaar, tegen een lager tarief.
    example: >-
      Een koelhuis op het bedrijventerrein krijgt een non-firm contract en kan
      's nachts uitbreiden, terwijl het wacht op de verzwaring.
    source:
      title: ACM — Codebesluit alternatieve transportrechten
      url: https://www.acm.nl/nl/publicaties/codebesluit-alternatieve-transportrechten

  - id: gotork
    name: GOTORK (use it or lose it)
    category: sector
    short: "Regels waarmee een netbeheerder ongebruikte gecontracteerde capaciteit kan terugvragen."
    text: >-
      Veel bedrijven hebben meer transportcapaciteit gecontracteerd dan ze gebruiken.
      Met de ACM-regels over ongebruikte transportcapaciteit kan een netbeheerder
      die capaciteit terugvragen en aan de wachtrij geven. Daarvoor moet hij wel
      weten wie wat gebruikt.
    example: >-
      Op het drukste kwartier gebruikten de grootzakelijke klanten in Nova samen 62
      procent van wat ze gecontracteerd hadden.
    source:
      title: Solar Magazine — ACM publiceert ontwerp-codebesluit om ongebruikte transportcapaciteit af te pakken
      url: https://solarmagazine.nl/nieuws-zonne-energie/i35667/acm-publiceert-ontwerp-codebesluit-om-ongebruikte-transportcapaciteit-af-te-pakken

  - id: energiewet
    name: Energiewet
    category: sector
    short: "De wet die sinds 1 januari 2026 de Elektriciteitswet 1998 en de Gaswet vervangt."
    text: >-
      De Energiewet bundelt de regels voor elektriciteit en gas in één wet. In de
      wet heten regionale netbeheerders distributiesysteembeheerders en heet TenneT
      transmissiesysteembeheerder; in de praktijk blijft iedereen netbeheerder
      zeggen. Voor klanten verandert er weinig.
    example: >-
      In Voltana's contracten staat sinds januari 2026 'distributiesysteembeheerder';
      aan de balie zegt niemand het.
    source:
      title: Netbeheer Nederland — FAQ Energiewet
      url: https://www.netbeheernederland.nl/sites/default/files/2025-12/faq_energiewet.pdf

  - id: compensatieregeling
    name: Compensatieregeling bij storingen
    category: sector
    short: "Bij een stroomstoring van meer dan vier uur krijgt een klant een vaste vergoeding."
    text: >-
      Duurt een storing langer dan vier uur, dan betaalt de netbeheerder een vaste
      tegemoetkoming. Voor een huishouden is dat 35 euro voor vier tot acht uur en
      20 euro per vier uur extra; grotere aansluitingen krijgen meer. Het is geen
      schadevergoeding. Bij aangekondigd onderhoud of natuurrampen geldt het niet.
    example: >-
      Een storing van vijf uur in een straat met dertig huizen kost Voltana ruim
      duizend euro aan compensatie.
    source:
      title: ACM ConsuWijzer — Vergoeding bij stroomstoring
      url: https://consument.acm.nl/elektriciteit-en-gas/ik-heb-een-probleem/stroomstoring-vergoeding

  - id: terugleverpiek
    name: Terugleverpiek
    category: sector
    short: "Op zonnige middagen leveren zonnepanelen zoveel terug dat trafohuisjes overbelast raken."
    text: >-
      Zonnepanelen leveren het meest rond het middaguur, in voorjaar en zomer, als
      er weinig stroom wordt gebruikt. In straten met veel panelen gaat de stroom
      dan het net op en kan de wijktransformator overbelast raken; bij hitte kan een
      trafo bovendien minder aan. Netbeheerders vragen klanten soms stroom te
      gebruiken tussen 11 en 15 uur.
    example: >-
      In Nova slaan op een zonnige zomermiddag drie zekeringen door in trafohuisjes
      van straten waar de helft van de daken vol panelen ligt.
    source:
      title: Solar Magazine — Oproep Enexis, gebruik stroom zonnepanelen tijdens zonnige uren
      url: https://solarmagazine.nl/nieuws-zonne-energie/i43218/oproep-enexis-gebruik-stroom-zonnepanelen-tijdens-zonnige-uren-overbelasting-dreigt-op-37-locaties
```

---

## 6. What the drafts require from code (for the C tasks)

**Goal types:**
- from the catalogue: `routine` (C6), `measure` (C4), `okr` (C11), `kpi_review` (C4), `talk_to` (C5), `coach` (C7), `strategy` (C11), `rework_fix` (C20);
- existing: `solve`.

**Mission fields:**
- from the catalogue: `act`, `chapter`, `arc`, `beats` (incl. `on: day`), `fork`, `debrief_first`, `reopen`, `opens_on`, `fail_opens`, `fail_effects`, `event`, `recurring`, `sets_flags`, `requires.{maturity, trust, any_of, facts}`, `rewards.{reputation, trust, unlocks}`, `kind: milestone`;
- **new:** `principles`, `temptations`, `event.extra_if_open`, `npc_experiment`, `okr.key_results_menu` / `pick` / `pass_average`, `strategy option: trust / aftermath / sets_flags`.

**Countermeasure fields (new):**
- `trust`, `aftermath`, `containment`, and `needs` (catalogue C19).

**Effect properties:**
- none new; all 36 countermeasures and 11 problems use today's `EFFECT_PROPERTIES`. Optional: `rework_wait_days`.

**Temptation effects (new, reported not simulated):** `reputation`, `trust`, `cost`, `complete_goal`, `measure_bonus`.

**Scoring (Check & Act):**
- a containment bonus (`fix_lmra_tickbox`);
- `poor_fix` should also be set when a countermeasure with `trust < 0` or an `aftermath` is chosen while a better-fitting one was offered. That turns "long term outweighs short term" into a fact the repair quests read.

---

## 7. Open items for Merijn

1. The four additions (§2.16–2.18 and the repair example) raise Act III from 16 to 20 missions. Keep all, or move `fix_klic_expired` to Act IV?
2. Should the storm use the `strategy` goal (draft) or stay an `observe` goal?
3. The `temptations` mechanic: one beat per mission, offered by a person. Is that the right weight, or should temptations live only in the countermeasure list (as `switch_contractor`, `double_stock` and friends already do)?
4. Sources: the list checked on 2026-10-15 (compensation, KNMI, KLIC, IEC 60076-7, lean.org / asq.org, Safety Culture Ladder, transport rights, re:Work, the 2018 Nestor table, trench depth). Corrections: KNMI warns up to 48 h ahead; the time-bound right dates from 2024 and has its own discount; trench depth 50 cm (Stedin), not 60. Still open: the 2018 table's split of the 18% (read the PDF), and the sources not on that list that still carry (verify).
