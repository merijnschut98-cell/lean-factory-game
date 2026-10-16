# Tier-4 missions — content-ready drafts (Act V and the tier-4 IT chapter)

> Status: drafts by the mission and dialog design agent (Claude, 2026-10-15), for Merijn to review. **Docs only**, **not** in `content/` yet. Each block is ready to paste into `content/missions.yaml`, `content/problems_tier4.yaml`, `content/problems_it.yaml`, `content/countermeasures.yaml`, `content/dialogs.yaml` and `content/people.yaml` once the catalogue's schema (C1–C20), the tier-3 areas and IT streams (K6, K9) and the dialog engine exist.
>
> Read with:
> - `CLAUDE.md` §2;
> - PLAN.md "Decisions Made": path dependence, the finale as a placeholder, no dialect, customers by phone, "Respect the player's time";
> - the catalogue `2026-10-15-mission-system-and-catalogue-design.md` §2.15, §3.7 and §3.8;
> - the tier-3 draft `2026-10-15-tier3-missions-draft.md`: its format, §2.8 (the two tier-4 IT drafts it hands over) and §3.2 (the facts it leaves for tier 4);
> - the tier-2 dialogs `2026-10-15-tier2-dialogs.md` §6 (Act III facts tier 4 reads);
> - the sustain design `2026-10-15-sustain-and-drift-design.md` (fix health, which the audit reads);
> - the engagement loop `2026-10-15-engagement-loop.md` (cliffhangers; the hidden-reward map, which asks this draft for 4–6 Act V rewards).

## 0. What this covers and how to read it

**Scope.** 20 missions plus the finale's placeholder id:

- **Act V, "Het systeem" (15, as in the catalogue):**
  - one direction (hoshin);
  - risk-based maintenance;
  - the NTA 8120 audit;
  - a fork between seeing faults in the low-voltage grid and finding stolen power;
  - the flex market;
  - the investment plan, which the player's whole history shapes;
  - sides: gas phase-out, the asset manager, the grid of 2035, the sensor pilot, catchball, holding the region, the re-audit;
  - `t4_new_ci_lead` stays a placeholder: an id and an idea, without goals, texts or rewards (Merijn, 2026-10-15).
- **The tier-4 IT chapter, "Het digitale loket" (6):**
  - the catalogue's `fix_team_dependencies`, `fix_tech_debt` and `it_dora_metrics`;
  - the customer portal (`fix_status_page_wrong`) and the meter-data platform (`fix_meter_data_mandates`), handed over by the tier-3 draft §2.8;
  - one new main mission, `it_field_asset_data` ("De mof die nergens staat"), where the two chains meet. The field app the player fixed in tier 3 is what feeds risk-based maintenance in Act V.

**Totals.** 9 new problems (6 grid, 3 IT; the 2 from tier-3 §2.8 come on top), 35 new countermeasures, 10 persuasion dialogs, 1 auditor talk, 2 expert topic sets and 6 hidden rewards (D45–D50).

**Every mission names**, as in tiers 2 and 3:
- the **principle** it tests (`principles`: `long_term`, `respect`, `improve`);
- a **tempting shortcut** that works now and costs later;
- its **dialogs**, in standard Dutch with the voice sheet (§5). Everyone speaks standard Dutch (decided 2026-10-15: no dialect); voices differ in word choice, rhythm, humour and worry.

**Act V's own idea: the system.** Tiers 1–3 taught the player to find a constraint and fix a process. Act V asks what holds the whole together:
- one direction instead of twenty (hoshin);
- maintenance where the risk is, not where the calendar says (NTA 8120);
- an audit that checks whether earlier fixes still hold;
- an investment plan built only from what the player prepared.

Little in this act is new to fix; much is old to keep. That is "Stagnation is regression" and "Improvements must be sustained" as the act's plot.

**The 1 + 3 rule:**
- Act V and the IT chapter are two main chains. The player holds one main at a time and picks which chain to advance (prioritising, not a fork).
- At most three sides. The audit is a milestone and takes no slot.
- The coach coaches only the active main, grid or IT.

**Conventions** as in the tier-3 draft:
- Dutch game text; English ids, keys and comments.
- Every number is sourced, or marked `estimate:` with its reasoning.
- Facts that could not be checked at the source carry **(verify)**.
- Effects use only today's `EFFECT_PROPERTIES`: `touch_time`, `ftr`, `applies`, `wait_time`, `availability`, `headcount`, `lead_time`, `reorder_point`, `demand`, `reserve`, `preempts`, `wip_limit`, `call_rate`, `start_rule`, `order_rule`, `batch_days`, `starts_with`.

### 0.1 Schema this draft assumes

Everything the tier-2 and tier-3 drafts assume:
- `principles`, `temptations`, `aftermath`, `strategy` options with `needs` and `preparation`;
- `needs_discount`, `release_gated`, `cleared_by`, `track`;
- `agreed:<dialog>:<proposal>`, `hold_kpi`.

Plus four new fields:

| Field | On | Meaning | Why |
|---|---|---|---|
| `audit` goal | milestone | `{fixes_holding: n, health_min: f, resolved: [problem], findings: [flag], judged_on: deadline}` | The NTA 8120 audit reads fix health (sustain design §1) on its date. The catalogue's "6 fixes holding ≥ 0.8" in schema form. |
| `findings` | `audit` goal | Facts that, when set on the audit day, are written up as findings: `{fact, text, reputation}` | Tier-3 shortcuts (`flag:queue_jumped`, `flag:hidden_wip`) surface here, where an auditor would find them. A finding never decides pass or fail: the measure does. |
| `maturity` per track | `requires` | `{maturity: {it: 3}}` | Catalogue C17d: IT has its own maturity. The tier-4 IT missions gate on IT maturity, not the grid's. |
| `forecast_check` | `strategy` goal | `{after_days: 182, tolerance: 0.1}`: compares the chosen option's forecast with what happened | D50 rewards a forecast that held, and the investment plan's debrief reads it. Learning to predict is the Check's purpose (CLAUDE.md "Measure"). |

### 0.2 Corrections to the catalogue found while grounding

1. **`ls_grid_blind` needs a wait step.** The catalogue puts its mechanism at `outages.report` ("report wait. Exists"). But `report` is a work step of the control room, and `wait_time` acts only on wait steps.
   - Fix: a new wait step `outages.noticed` before `report`: the time from a low-voltage fault until someone calls.
   - Base: 0.5 h. Estimate: most faults are called in within minutes in the day, later at night.
   - The problem multiplies it.
2. **The Act V fork is honest on outage minutes, not throughput.** Every fault gets repaired, so the outage stream's throughput equals its demand. What a customer in the dark feels, and what the ACM measures, is duration: the yearly outage minutes per customer (*jaarlijkse uitvalduur*).
   - The fork test (C15) compares `outages` lead time.
   - B (`ls_grid_blind`) shortens it.
   - N (`grid_losses_theft`) saves money and barely moves it.
   - This is the audit's L1 rule applied to a demand-driven stream: name the KPI the fork is honest on.
3. **`strategy_silos` needs a mechanism.** "Board rules disagree" is not a simulation effect on its own.
   - Fix: twenty parallel improvement projects drain the people who must run them. Availability falls at the departments that carry most projects: work_prep, planners and grid_analysts, −0.06 each.
   - Estimate: two to three hours a week per person in project meetings and status reports.
   - The best countermeasure gives that time back by stopping projects, not by starting one.
4. **The flex market in 2026 is not empty because nobody knows the platform.** Since the congestion-management code (2022), grid operators must try market-based congestion management before they say no (ACM code decision, *verify the article*). GOPACS exists since 2019.
   - The realistic problem at a regional operator is threefold:
     - bids are asked too late (day-ahead, for planned work known weeks earlier);
     - small and mid-size customers cannot bid on their own;
     - the payment is unclear.
   - The mission keeps its name; its root cause says this.
5. **The audit reads health, not "fixes".** "6 fixes holding ≥ 0.8" maps onto the sustain design's health per resolved fix.
   - By Act V a player who standardised and audits has 10–20 resolved fixes, so 6 at health ≥ 0.8 is reachable on the expert path.
   - A player who never sustained has fewer: the audit fails, and the re-audit is the way back (setbacks, never game over).
   - **Validator check:** ≥ 8 problems from tiers 1–3 can be standardised before `t4_hoshin` opens. They can: every tier-1 mission allows it.
6. **The investment plan is a regulated document.** Dutch grid operators publish an investment plan every two years, with a public consultation, and the ACM checks it (Elektriciteitswet 1998 art. 21, carried into the Energiewet: *verify the article and cycle*). Their income is set by the ACM's yardstick regulation (*maatstafregulering*), so an operator that spends more than its peers for the same output earns less.
   - That is the realistic reason why "alles tegelijk" and "klassiek verzwaren" are not free.
   - It is the finance director's worry (§1.8).

### 0.3 Content the drafts need (for K8 and K9)

All numbers are **estimates**, sized so that no team is above 85 % in the base (the K6 rule). The builder calibrates them with the problem report.

**Pools (new):**

| id | Name (NL) | Headcount | Availability | Notes |
|---|---|---|---|---|
| `asset_mgmt` | Assetmanagement | 3 | 0.85 | Ingrid Bos's team: risk register, maintenance policy, the investment plan's numbers |
| `maintenance` | Onderhoudsploeg | 4 | 0.85 | Theo Janssen's inspectors; today they visit every station on a fixed calendar |
| `gas_monteurs` | Gasmonteurs | 4 | 0.85 | For `gas_phaseout` only, approximated without a gas stream (catalogue) |
| `fraud_desk` | Netverliezen & fraude | 1 | 0.85 | One analyst, today mostly invoices of bought losses |
| `portal_team`, `data_team`, `data_desk` | Team Klantportaal, Team Meetdata, Mandaten & datalevering | 6, 6, 1 | 0.85 | From the tier-3 draft §0.3, marked tier 4 there |

**Streams and steps (new or changed):**

| Stream | Change | Why |
|---|---|---|
| `outages` | New wait step `noticed` before `report` (base 0.5 h) | Correction 1. |
| `maintenance` (new) | plan (`asset_mgmt`) → inspect (`maintenance`) → repair_planned (`monteurs`) | Planned maintenance as work that competes with connections and outages for monteurs. Arrivals: 12 inspections a week (estimate: ~600 MS stations visited every 4 years at a region of Zuidmark's size, plus cables and joints). |
| `it_features` | New wait step `dependency` after `build` (base `applies: 0.0`, 10 d) | The handoff to another team, switched on by `team_dependencies` (§2.1). |

**Places:** `maintenance.inspect` is a middenspanningsruimte (MSR) in Nova-Oost; `outages.noticed` is the street (the player stands where the lights went out); `asset_mgmt` sits on the Directie & Obeya floor (catalogue §2.3: Ingrid).

**New cast** (voice sheet §5):
- **Asset side:**
  - Ingrid Bos (asset manager, expert; catalogue);
  - Theo Janssen (coördinator onderhoud);
  - Harrie Coenen (gasmonteur).
- **Management:** Monique de Ruiter (directeur Financiën).
- **Audit:** Rianne Hoogendoorn (lead auditor of the certifying body; fictional, no real body named).
- **IT:** Tim de Haan (lead, Team Werkorderplatform).
- **Returning, with new stages:**
  - Frank Hulshof, Kees Mulder, Yvonne Kok, Mieke van der Veen;
  - Femke de Wit, Thomas Visser, Mohammed Aziz, Wim Kortekaas;
  - Noor Hendriks, Mark van Leeuwen, Lisette Koster, Carla Wijnands, Bas Kuipers.
- **The finale's Lotte** stays a name in a beat (catalogue).

---

## 1. Act V — Het systeem (tier 4)

Gates: `t3_stop_starting` (done **or** failed), maturity 4, belt black, reputation ≥ 65.

**Chapters:**
- **Eén richting:** hoshin, then catchball as a routine.
- **Het net van binnen:** risk-based maintenance and the audit; then the fork between seeing and finding.
- **Wat het systeem kan dragen:** the flex market, then the investment plan.

The act's cliffhanger in (engagement loop §3, IV and IT → V): three letters on the same morning.
- The Raad van State on a permit.
- The MT's list, "Twintig prioriteiten".
- The NTA 8120 audit date.
- And Esra, for the IT chapter: "Ik vroeg vorig jaar om een datum op het klantportaal. Die staat er nog steeds niet."

The title card (Drie winters, 2026-10-16: Ruud is back and says it): "Het systeem. Ik ben terug, en ik ga weer weg. Op 1 april stop ik. Dat is geen dreigement, dat is de AOW. Twintig prioriteiten is er geen. Wat is de ene?" The return sets `flag:ruud_back`; Frank goes back to his manager's role. Under the regime (`flag:interim_regime` without `flag:regime_eased`) `frank_twenty` starts 5 lower. Hoshin's true north reads the waiting list: "Iedereen een eerlijke datum, en die klopt."

### 1.1 `t4_hoshin` — Eén richting (M)

Principles tested: **long_term** (one direction that holds) and **respect** (catchball: the departments shape the plan, they do not receive it). Temptation: add the twenty projects to one beautiful X-matrix, and stop none.

```yaml
missions:
  - id: t4_hoshin
    name: Eén richting
    kind: main
    tier: 4
    act: 5
    chapter: Eén richting
    requires: {facts: {any: [done:t3_stop_starting, failed:t3_stop_starting]}, belt: 3, maturity: 4, reputation: 65}
    goal: {type: solve, problem: strategy_silos}
    principles: [long_term, respect]
    briefing: "Het MT heeft een lijst gemaakt: twintig prioriteiten voor Zuidmark, elk met een eigenaar en een kleur. Ruud legt hem op tafel. 'Twintig prioriteiten,' zegt hij, 'is er geen. Bij Werkvoorbereiding zitten mensen in vijf projecten tegelijk en maken er geen af. Zoek uit wat er echt toe doet, en zorg dat iedereen dezelfde kant op kijkt. Niet omdat ik het zeg.'"
    debrief: "Zuidmark heeft nu {objectives} doelen in plaats van twintig, en elke afdeling weet welk van haar projecten eraan bijdraagt. {stopped} projecten zijn gestopt. Werkvoorbereiding heeft {hours_back} uur per week terug. Frank: 'Ik heb drie projecten weggestreept. Het voelde als verliezen. Het was winnen.'"
    debrief_variants:
      poor_fix: "Alle twintig projecten staan nu netjes op één A3, met pijlen naar vier doelen. Niets is gestopt. Werkvoorbereiding zit nog steeds in vijf projecten tegelijk. Ruud: 'Mooi plaatje. Wat is er gestopt?'"
    reopen: "Er staan weer zeventien projecten op de lijst. Elk kwartaal kwam er een bij, en er ging er geen af."
    beats:
      - {on: accepted, who: ruud, text: "Hoofdstuk vijf: Het systeem. Een doel dat iedereen kent, is meer waard dan twintig die iemand heeft opgeschreven."}
      - {on: accepted, who: carla, text: "Bij de release train hebben we geleerd om te zeggen wat zeker is en wat misschien. Misschien moet het MT dat ook leren."}   # only if committed:carla_must_haves
      - {on: completed, who: joost, text: "Mijn mensen zaten in vijf projecten. Nu in één. Anouk vroeg of ze ziek was, zo rustig was het."}
    temptations:
      - id: everything_on_the_matrix
        who: frank
        when: accepted
        text: "Zet alle twintig op de X-matrix. Dan ziet de raad van bestuur dat we overal aan werken, en hoeft niemand iets te laten vallen."
        accept: "Je zet alle twintig projecten op de X-matrix."
        decline: "Je vraagt elke afdeling wat ze laat vallen."
        accept_sets_flags: [flag:matrix_of_twenty]
        accept_effects: {reputation: 3}
    teaches: [hoshin_kanri, x_matrix, okr, wip]
    rewards: {xp: 3600, budget: 30000, reputation: 5, unlocks: [strategy, lsw_catchball]}
    insights:
      go_see: "Hoeveel projecten heeft één werkvoorbereider deze week? Heb je het hem zelf gevraagd?"
      understand: "Welke van de twintig dragen bij aan wat Zuidmark het komende jaar moet bereiken? Hoe weet je dat?"
      experiment: "Als je vijf projecten stopt, wat verwacht je dan te zien bij Werkvoorbereiding? Over hoeveel weken?"
      reflect: "Wie heeft er iets laten vallen, en waarom deed hij dat zelf?"

problems:
  - id: strategy_silos
    tier: 4
    name: Twintig prioriteiten
    step: work_prep           # a pool-level problem; its clues live at the Obeya wall (place: obeya)
    waste: overproduction
    severity: high
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Het MT heeft twintig prioriteiten voor dit jaar, elk met een eigen eigenaar.
      - Werkvoorbereiders zitten in gemiddeld vijf verbeterprojecten tegelijk.
    root_cause: Elke afdeling start eigen projecten en stuurt op eigen KPI's. Niemand beslist welke projecten bijdragen aan de doelen van Zuidmark, dus komt er elk kwartaal een bij en gaat er geen af. De mensen die het werk doen, zitten hun weken vol met projectoverleg en statusrapporten.
    plausible_causes:
      - De afdelingen werken niet hard genoeg aan hun projecten.
      - Er is te weinig projectmanagement.
      - De doelen zijn niet goed genoeg uitgelegd.
    mismatch_note: Meer projectmanagement of een betere uitleg voegt nog een laag toe. Het helpt pas als er projecten stoppen, en als de afdelingen zelf mogen zeggen welke.
    countermeasures: {hoshin_catchball: 1.0, x_matrix: 0.8, okr_per_department: 0.7, pmo_dashboard: 0.5}
    teaches: [hoshin_kanri, wip]
    effects:
      # estimate: 2-3 h a week per person in project meetings and status reports (of ~36 h): -0.06 availability
      - {target: work_prep, property: availability, value: -0.06}
      - {target: planners, property: availability, value: -0.06}
      - {target: grid_analysts, property: availability, value: -0.06}
    clues:
      - {tool: documents, key: true, depth: 0, at: obeya, text: "De lijst van het MT: twintig prioriteiten. Bij elf staat 'hoog'. Bij geen enkele staat wat er stopt als hij begint."}
      - {tool: shadow, key: true, depth: 1, at: connections.design, text: "Anouk zit dinsdag in vier projectoverleggen. Tussendoor tekent ze twee aansluitingen. 'Woensdag is mijn tekendag,' zegt ze. 'Als er geen overleg is.'"}
      - {tool: data, key: true, depth: 1, text: "Van de twintig projecten van vorig jaar zijn er drie afgerond. Elf lopen nog, zes zijn stilgevallen zonder dat iemand het besloot."}
      - {tool: conversation, key: false, depth: 0, text: "'We hebben gewoon meer projectleiders nodig.'"}
      - {tool: conversation, key: true, depth: 2, at: obeya, text: "'Als ik een project stop, staat mijn afdeling er in de najaarsronde slechter voor. Dus stop ik niks.'"}

countermeasures:
  - id: hoshin_catchball
    name: Eén richting, samen afgestemd
    tier: 4
    category: standard_work
    description: Het MT kiest drie tot vijf doelen voor Zuidmark. Elke afdeling stelt zelf voor welke projecten daaraan bijdragen en welke ze stopt, en gooit het voorstel terug. Dat gaat heen en weer tot het klopt. Elk kwartaal opnieuw.
    budget: 8000
    team_hours: {work_prep: 10, planners: 10, grid_analysts: 10, intake: 5}
    decay_days: 120
    sustains: true            # catchball is itself a leader routine (lsw_catchball keeps it)
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: work_prep, property: availability, value: 0.06}
      - {target: planners, property: availability, value: 0.06}
      - {target: grid_analysts, property: availability, value: 0.06}
  - id: x_matrix
    name: Eén X-matrix voor Zuidmark
    tier: 4
    category: visual_management
    description: Doelen, jaardoelen, projecten en KPI's op één A3, met wie waaraan bijdraagt. Het MT stelt hem op; de afdelingen krijgen hem te zien.
    budget: 4000
    team_hours: {work_prep: 5, planners: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: work_prep, property: availability, value: 0.04}
      - {target: planners, property: availability, value: 0.04}
      - {target: grid_analysts, property: availability, value: 0.04}
  - id: okr_per_department
    name: OKR's per afdeling
    tier: 3
    category: visual_management
    description: Elke afdeling krijgt eigen OKR's, afgeleid van het doel voor Zuidmark. De projecten blijven bestaan; elk krijgt een OKR erbij.
    budget: 3000
    team_hours: {work_prep: 5, planners: 5, grid_analysts: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: work_prep, property: availability, value: 0.03}
      - {target: grid_analysts, property: availability, value: 0.03}
  - id: pmo_dashboard
    name: Een projectbureau met een dashboard
    tier: 1
    category: visual_management
    description: Een projectbureau houdt alle twintig projecten bij op een dashboard, met een stoplicht per project.
    budget: 25000
    team_hours: {}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialog: `frank_twenty`.** Frank owns seven of the twenty. His worry from the voice sheet becomes the act's opening knot: stopping a project looks like losing budget.

```yaml
dialogs:
  - id: frank_twenty
    person: frank
    kind: persuade
    mission: t4_hoshin
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + memory
    #   with committed:frank_red_numbers (Act III): +15 = 50, Luistert; without: 35, Op z'n hoede
    opening: "Zeven van de twintig zijn van mij. Ik weet wat je komt vragen. Het antwoord is nee, maar ga zitten."
    position: {text: "Mijn projecten staan erop omdat de directie ze heeft goedgekeurd. Daar ga ik niet aan tornen.", tags: [claim]}
    layers:
      - id: interest
        at: 58
        via: [inquiry, paraphrase]
        text: "Elk project is een regel in het jaarplan. In de najaarsronde vraagt de directie per regel wat het opleverde. Een regel die weg is, levert niks op."
        tags: [claim]
      - id: concern
        at: 76
        via: [show_data, paraphrase]   # 2026-10-16 (1.6c, route variety): facts; his twenty lines in the plan, on the table
        lead_in: {text: "En als ik er drie stop… Die regels staan in het jaarplan. Nakijken mag.", tags: [hesitation, claim], tell: facts}
        text: "…dan zeggen ze in de najaarsronde: Frank had minder nodig. Dan gaat het budget voor de verzwaringen naar Noord. En die verzwaringen zijn het enige wat ik echt wil. De rest staat erop om het te beschermen."
        tags: [admission]
        unlocks: {facts: [heard:frank_shield], proposals: [stop_list_with_the_board]}
    reframe: "Vanuit Anouk, met vier overleggen op een dinsdag? Die tekent mijn verzwaringen. Tussen mijn projecten door. Hm. Dan bescherm ik mijn verzwaringen tegen mijn eigen projecten."
    warning: "Dat moet ik kunnen uitleggen. Dit kan ik niet uitleggen."
    data: ["strategy_silos:1", "strategy_silos:2"]
    lines:
      open_question:
        lands: {text: "Twintig projecten. Twintig regels in het jaarplan, elk met een paraaf van de directie.", tags: [claim], tell: facts}
      show_data:
        lands: "Drie van de twintig af. Zes stilgevallen. … Daar staan er twee van mij tussen. Die was ik vergeten."
        misses: "Dat zijn de projecten van anderen."
    proposals:
      - {id: drop_three, addresses: [interest], label: "Drie projecten stoppen", say: "Stop drie van je zeven. Dan heeft Werkvoorbereiding tijd voor je verzwaringen.", reply: "Drie. En dan sta ik er in de najaarsronde slecht op."}
      - {id: stop_list_with_the_board, hidden: true, addresses: [concern], label: "Een stoplijst, samen naar de directie", say: "Wat als je de directie zelf vertelt welke projecten je stopt, en waarom: om de verzwaringen sneller te maken? Dan is stoppen geen verlies, maar jouw keuze. En wij laten in de najaarsronde zien wat het opleverde.", reply: "Mijn keuze. Met de verzwaringen als reden. … Dat kan ik uitleggen. Dat kan ik zelfs goed uitleggen."}
    experiments:
      - {id: pause_a_quarter, addresses: [concern], label: "Een kwartaal op pauze, en meten", say: "Zet drie projecten een kwartaal op pauze, niet weg. Als de verzwaringen niet sneller gaan, zet je ze terug.", reply: "Op pauze. Dan is het niet weg. En als het werkt, heb ik cijfers voor de najaarsronde."}
    co_proposal: {id: stop_list_with_the_board, text: "Ik neem de stoplijst zelf mee naar de directie. Met de doorlooptijd van de verzwaringen erbij. Als jij die cijfers voor me hebt."}
    outcomes:
      commitment: "Drie eraf. Ik zet mijn paraaf eronder, en ik zeg het in het MT als eerste. Dan moeten de anderen ook."
      partial: "Als de directie het zwart op wit krijgt, doe ik mee."
      heard: "Wat ik echt wilde. Dat vraagt niemand een manager."
      compliance: "Ze staan op de matrix. Allemaal. Dat wilde je toch?"
      ruined: "Dit is het jaarplan van iemand anders. Dat moet ík dan uitleggen, niet jij."
    # route (no history, start 35): open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose stop_list_with_the_board +8 89 > ask: commitment (8 moves)
    # route (with committed:frank_red_numbers, start 50): open question +6 56 (interest) > paraphrase +7 63 (heard)
    #        > show_data +15 78 (lead-in, cue) > silence +12 > 81 capped (concern) > propose stop_list_with_the_board +8 89 > ask (6 moves)
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (rule_bound): interest.at 55->58, concern.at 72->76.
    # 2026-10-16 (1.6c, route variety): Frank opens on the record: the data clue, or the claim said back exactly. Silence lets the moment pass. (In tier 2 he opened to a precise question; here only the record does.)
    # 2026-10-16 (1.6c, route variety): open questions land with a claim in Frank's own words, so Samenvatten and Doorvragen have something to answer (a tell of facts).
```

**Path dependence.**
- **`flag:matrix_of_twenty`** pays now: reputation +3, and the board loves the overview. It is a poor fix in disguise: nothing stops.
  - The audit (§1.3) reads it as a finding ("De doelen zijn niet vertaald naar wat wél en niet gebeurt").
  - The investment plan's forecast runs with work_prep at −0.06 until it is cleared.
  - Cleared by `chose:strategy_silos:hoshin_catchball` through the repair quest.
- **Read from tier 3:** `chose:pi_overcommit:capacity_based_pi` with `committed:carla_must_haves`.
  - The IT train already plans by capacity. The X-matrix gets one honest row (a clue at depth 1 reads "De release train plant al op capaciteit; daar staat wat zeker is en wat niet"), and Carla speaks up in catchball (her beat).
- **Read from Act III:** `committed:frank_red_numbers`. Frank starts at 50, not 35.
- **Set:** `committed:frank_twenty` is read by `t4_investment_plan` (Frank backs a non-baseline option in the MT: §1.8).

**Grounding.**
- Hoshin kanri and catchball: Akao, *Hoshin Kanri* (1991).
- The X-matrix: Jackson, *Hoshin Kanri for the Lean Enterprise* (2006).
- Stopping projects to finish others: the WIP lesson of Act IV, one level up (Little's law; the existing `wip` concept).
- The budget fear: the ACM's yardstick regulation sets income by comparing operators' efficiency (§0.2 item 6). Department budgets in an autumn round are fiction.
- Twenty projects, three finished, two to three hours a week: estimates.

**Engrossing.**
- The player has fixed processes for four acts. Now the process that starts work is the problem, and the player's own list of "good ideas" is on it.
- Frank's admission, that six of his seven projects exist to protect the one he cares about, is a real management pattern, said by a person.

### 1.2 `fix_maintenance_calendar` — Onderhoud op de kalender (M)

Principles tested: **improve** (maintenance where the risk is) and **respect** (the inspectors' knowledge is the risk model's best input). Temptation: stretch every interval to save money, without looking at risk.

```yaml
missions:
  - id: fix_maintenance_calendar
    name: Onderhoud op de kalender
    kind: main
    tier: 4
    act: 5
    chapter: Het net van binnen
    requires: {missions: [t4_hoshin]}
    goal: {type: solve, problem: maintenance_calendar}
    principles: [improve, respect]
    briefing: "Theo Janssens ploeg bezoekt elk middenspanningsstation om de vier jaar, of het nu uit 1968 is of uit 2022. Ondertussen vallen in Nova-Oost de oude kabelmoffen uit, steeds in dezelfde straten. Ingrid Bos, assetmanager: 'De audit vraagt of ons onderhoud op risico is gebaseerd. Eerlijk antwoord: op de kalender.' Over drie maanden komt de auditor."
    debrief: "De ploeg gaat nu eerst naar de stations en moffen met het hoogste risico. In Nova-Oost vielen dit kwartaal {outages_delta} minder storingen dan vorig jaar, en de monteurs hebben {hours_back} uur per week terug voor aansluitingen. Theo: 'Ik heb veertig jaar elk station bezocht. Nu weet ik ook waarom ik het ene vaker moet zien dan het andere.'"
    debrief_variants:
      poor_fix: "De intervallen zijn langer, dus de monteurs hebben tijd terug. Maar de oude moffen in Nova-Oost vallen nog net zo vaak uit: niemand keek waar het risico zat. Ingrid: 'We besparen op het onderhoud dat goed ging.'"
    reopen: "De ploeg rijdt weer de kalender af. Het risicoregister is een half jaar niet bijgewerkt."
    beats:
      - {on: accepted, who: ingrid, text: "Kom morgen naar het station in de Lijsterstraat. Theo is er. Neem een zaklamp mee, en tijd."}
      - {on: completed, who: ruben, text: "Die mof in de Merelstraat is vervangen voordat hij eruit ging. Eerste keer in twaalf jaar dat ik daar niet 's nachts heen hoefde."}   # only if heard:ruben_blame or committed:ruben_cause
    temptations:
      - id: stretch_all_intervals
        who: monique
        when: accepted
        text: "Rek alle intervallen op van vier naar zes jaar. Dat scheelt een derde van het onderhoud, en niemand merkt het."
        accept: "Je rekt alle onderhoudsintervallen op naar zes jaar."
        decline: "Je laat eerst uitzoeken waar het risico zit."
        accept_sets_flags: [flag:intervals_stretched]
        accept_effects: {budget: 20000}
    teaches: [risk_based_maintenance, asset_health_index, nta_8120, pareto]
    rewards: {xp: 4000, budget: 35000, reputation: 5}
    insights:
      go_see: "Waar vallen de storingen in Nova-Oost? Heb je met de mensen gesproken die die stations al dertig jaar zien?"
      understand: "Welke stations en moffen hebben het meeste risico? Wat heb je nodig om dat te weten, en wat ontbreekt?"
      experiment: "Als de ploeg eerst naar de hoogste risico's gaat, welk getal moet over een kwartaal anders zijn?"
      reflect: "Wat wist Theo al dat in geen enkel systeem stond?"

problems:
  - id: maintenance_calendar
    tier: 4
    name: Onderhoud op de kalender
    step: maintenance.inspect
    waste: overprocessing
    severity: high
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Elk middenspanningsstation krijgt om de vier jaar onderhoud, ongeacht leeftijd of toestand.
      - In een paar straten in Nova-Oost vallen oude kabelmoffen steeds opnieuw uit.
    root_cause: Het onderhoud volgt een vaste kalender uit de jaren negentig. Jonge, betrouwbare stations krijgen evenveel aandacht als oude moffen in papierloodkabel (GPLK) met een geschiedenis van storingen. Er is geen risicoregister dat leeftijd, storingen en gevolgen samenbrengt, en wat de inspecteurs zien, wordt op papier genoteerd en niet gebruikt.
    plausible_causes:
      - De inspecteurs werken niet grondig genoeg.
      - Er is te weinig geld voor onderhoud.
      - Oude kabels gaan nu eenmaal stuk; daar valt niets aan te doen.
    mismatch_note: Meer of grondiger onderhoud volgens dezelfde kalender besteedt nog meer tijd aan stations die het goed doen. Het helpt pas als het onderhoud volgt waar het risico zit.
    countermeasures: {risk_based_maintenance: 1.0, condition_monitoring_ms: 0.8, fault_pareto: 0.7, longer_intervals: 0.5}
    teaches: [risk_based_maintenance, waste_overprocessing]
    effects:
      # estimate: a fixed 4-year calendar spends ~a third of inspection hours on young, low-risk assets,
      # and the monteurs who repair what inspections find lose that time: availability -0.04;
      # old joints left unwatched fail more: outage demand x1.1 (catalogue)
      - {target: monteurs, property: availability, value: -0.04}
      - {target: outages, property: demand, value: 1.1}
    clues:
      - {tool: documents, key: true, depth: 0, at: maintenance.inspect, text: "Het onderhoudsplan: elk station om de vier jaar. Het station in de Lijsterstraat is uit 1968, dat in de Nieuwe Haven uit 2022. Zelfde interval."}
      - {tool: data, key: true, depth: 1, at: outages.repair, text: "Twee derde van de storingen in het middenspanningsnet van Nova-Oost zit in moffen in oude GPLK-kabels. Vijf straten komen steeds terug."}
      - {tool: shadow, key: true, depth: 1, at: maintenance.inspect, text: "Theo opent het station in de Nieuwe Haven, kijkt, en zegt: 'Die is in orde. Die was vier jaar geleden ook in orde.' Hij vult het formulier toch helemaal in."}
      - {tool: conversation, key: true, depth: 2, at: maintenance.inspect, text: "'Ik schrijf al jaren op welke stations kraken en welke ruiken. Op het formulier is daar een vakje 'opmerkingen'. Ik weet niet of iemand dat leest.'"}
      - {tool: data, key: false, depth: 1, text: "Het onderhoudsbudget is in vijf jaar niet gestegen, het aantal stations wel."}
      - {tool: documents, key: true, depth: 2, text: "De storingsoorzaken van de afgelopen drie jaar: {cause_line}"}   # path: the Act III cause codes (see Path dependence)

countermeasures:
  - id: risk_based_maintenance
    name: Onderhoud op risico, met de ploeg
    tier: 4
    category: standard_work
    description: Elk station, elke kabel en elke mof krijgt een gezondheidsscore uit leeftijd, storingen, wat de inspecteurs zien en wat er gebeurt als hij uitvalt. De ploeg bezoekt eerst de hoogste risico's en vervangt de slechtste moffen voordat ze uitvallen. Theo's ploeg vult de score mee in.
    budget: 30000
    team_hours: {asset_mgmt: 40, maintenance: 30}
    decay_days: 180
    sustains: true            # the risk register reviewed every quarter is itself a routine
    needs_discount: {needs: {any: [chose:cause_unknown:cause_codes_pareto, standardised:cause_unknown, committed:ruben_cause]}, budget: 0.7, team_hours: 0.7}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.04}
      - {target: outages, property: demand, value: 0.88}     # estimate: the worst joints replaced before they fail
  - id: condition_monitoring_ms
    name: Kabels laten zeggen hoe het met ze gaat
    tier: 4
    category: quality
    description: Op de oudste middenspanningskabels komt meetapparatuur die deelontladingen meet, een vroeg teken dat een mof het gaat begeven. Een melding gaat naar de onderhoudsploeg.
    budget: 45000
    team_hours: {asset_mgmt: 20, monteurs: 20}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.92}
  - id: fault_pareto
    name: Een Pareto van de storingen
    tier: 3
    category: quality
    description: Elk kwartaal een Pareto van de storingsoorzaken per straat en per type component. De ploeg gaat eerst naar de top vijf. De kalender blijft voor de rest.
    budget: 3000
    team_hours: {asset_mgmt: 10}
    decay_days: 90
    needs: {any: [chose:cause_unknown:cause_codes_pareto, chose:cause_unknown:stop_and_record, chose:cause_unknown:repeat_fault_analysis, repaired:cause_unknown],
            none: [flag:cause_field_policed, chose:cause_unknown:mandatory_cause_field]}   # tier-2 promise; flag:cause_field_policed {cleared_by: [repaired:cause_unknown]}
    preparation: "De storingsdata moet eerst weer te vertrouwen zijn."
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.95}
  - id: longer_intervals
    name: Langere intervallen voor iedereen
    tier: 1
    category: flow
    description: Alle stations gaan van vier naar zes jaar. Er komt tijd vrij, maar niemand kijkt waar het risico zit.
    budget: 0
    team_hours: {asset_mgmt: 5}
    decay_days: 365
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.04}
    aftermath:
      after_days: 120
      days: 365
      effects:
        - {target: outages, property: demand, value: 1.05}   # estimate: the unwatched old joints fail a little more
```

**Dialog: `theo_calendar`.** Theo is the calendar's guardian, and its best critic. His worry is a station he skipped.

```yaml
dialogs:
  - id: theo_calendar
    person: theo
    kind: persuade
    mission: fix_maintenance_calendar
    owns: maintenance_calendar
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Pas op je hoofd. Die deur is van 1968 en hij weet het."
    position: {text: "Elk station om de vier jaar. Zo hebben we in veertig jaar nooit een brand gehad.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Ik ken ze allemaal. Dit station kraakt als het warm is. Dat in de Merelstraat ruikt naar was. Dat staat nergens, maar ik weet het.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [reflect, empathy]   # 2026-10-16 (1.6c, route variety): a feeling cue
        lead_in: {text: "Ik lig er wakker van, als je het wilt weten. Als ik er een oversla…", tags: [feeling]}
        text: "…en hij brandt af, met een woonwijk erachter. Dan sta ik voor de rechter met een rapport dat zegt: risico laag. Met de kalender heb ik niets fout gedaan. Met risico heb ik gekozen. En ik heb het verkeerd gekozen."
        tags: [admission]
        unlocks: {facts: [heard:theo_choice], proposals: [theo_scores_with_ingrid]}
    reframe: "Vanuit de monteur die om drie uur 's nachts weer naar de Merelstraat moet? Die denkt: wanneer kijkt iemand nou eens naar die mof. Ja. Die heeft gelijk."
    warning: "Als je komt vertellen dat ik veertig jaar voor niets heb gereden, kun je gaan."
    data: ["maintenance_calendar:1", "maintenance_calendar:2"]
    lines:
      experience:
        say: "Ik heb ooit iets overgeslagen om tijd te winnen, en het ging mis. Niet zo erg als een brand. Maar ik weet hoe dat voelt."
    proposals:
      - {id: score_the_stations, addresses: [interest], label: "Elk station een risicoscore", say: "Elk station krijgt een risicoscore, en jullie gaan eerst naar de hoogste.", reply: "Een score. Wie maakt die score? Iemand die er nooit is geweest?"}
      - {id: theo_scores_with_ingrid, hidden: true, addresses: [concern], label: "Theo maakt de score mee, en tekent niet alleen", say: "Wat als jij en Ingrid de score samen maken, met wat jij al veertig jaar opschrijft? En de keuze wie eerst gaat, wordt een besluit van het team en Ingrid, vastgelegd, niet van jou alleen.", reply: "Mijn opmerkingen in de score. En de keuze op papier, van ons samen. … Dan sta ik niet alleen. Dan wil ik het."}
    experiments:
      - {id: one_district_first, addresses: [concern], label: "Eerst alleen Nova-Oost, een half jaar", say: "Een half jaar alleen in Nova-Oost op risico, de rest op de kalender. Daarna kijken we samen.", reply: "Alleen Nova-Oost. Daar weet ik het beste waar het zit. Goed."}
    co_proposal: {id: theo_scores_with_ingrid, text: "En dat vakje 'opmerkingen' wordt een vakje dat iets doet. Als ik 'ruikt naar was' schrijf, gaat de score omhoog."}
    outcomes:
      commitment: "Dan gaat de Merelstraat bovenaan. Daar heb ik al tien jaar een opmerking bij staan."
      partial: "Zet het besluit op papier. Niet in mijn hoofd. Dan doe ik mee."
      heard: "Niemand heeft ooit gevraagd wat ik ruik in zo'n station. Dank je."
      compliance: "Dan rijden we het schema van iemand anders."
      ruined: "Kalender eraf, risico erop. En als het brandt, is het mijn schuld. Mooi plan."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry x1.5 +12 (craftsman, within 10 of 55) > 64 capped (interest)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern) > experience +8 (heard, trust >= 50, admission) 89
    #        > propose theo_scores_with_ingrid +8 97 > ask: commitment (8 moves)
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (craftsman): concern.at 72->70.
    # 2026-10-16 (1.6c, route variety): a feeling cue: reflect or empathy draws it out; inquiry no longer does.
```

**Path dependence.**
- **Read from Act III** (tier-2 dialogs §6): `committed:ruben_cause` or the cause-code countermeasures of `fix_cause_unknown`.
  - Those make the fault history trustworthy: `risk_based_maintenance` costs 30 % less (`needs_discount`), and `fault_pareto` is available at all (`needs`).
  - The depth-2 clue's `{cause_line}` reads either "drie jaar oorzaken, per straat en per component" (cause codes kept) or "een op de drie: onbekend" (not kept, or the fix faded).
  - The player who sustained Act III's fix sees the asset side clearly; the player who did not, sees why it mattered.
- **Read from the IT chapter** (§2.3): `done:it_field_asset_data`. The asset register knows which joints were already replaced, so `risk_based_maintenance` targets better.
  - Its outage effect goes from ×0.88 to ×0.85 (an authored `effects_if`: the one exception in this draft, listed in §7).
  - Either chain can come first. The beat after whichever comes second names the link ("De moffen die de monteurs fotograferen, staan nu in het register. Ingrid: 'Nu klopt de score.'").
- **`flag:intervals_stretched`** (the temptation): +€20,000 now, and the `longer_intervals` aftermath.
  - The audit reads it as a major finding unless `risk_based_maintenance` replaced it before the audit day. An auditor asks why the interval changed, and "to save money" is not a risk argument.
- **Set:** `chose:maintenance_calendar:risk_based_maintenance` is read by the audit (§1.3, the required resolved problem) and by `t4_sensor_pilot`.

**Grounding.**
- **NTA 8120:** the Dutch agreement on asset management for grid operators. Certification is required by the ministerial regulation on quality aspects of grid management (*verify the regulation's current article and the NTA version*).
- **Risk-based asset management and the health index:** ISO 55001; Ofgem's DNO Common Network Asset Indices Methodology (2017, *verify*); NN-CAM 5.0 (GDD).
- **Joints in old oil-paper (GPLK) cables** are a known main cause of medium-voltage outages in the Netherlands, alongside digging damage (Netbeheer Nederland, *Betrouwbaarheid van elektriciteitsnetten in Nederland*, yearly; *verify the year and share*).
- **Partial-discharge monitoring** of MS cables is in use at Dutch grid operators (*verify*; no product named).
- Two thirds, five streets, 1968, the 4-year interval and the €20,000: estimates and fiction.

**Engrossing.**
- A man who knows every station by smell, and whose notes nobody reads.
- The twist: the risk model's best data was in the "opmerkingen" box.
- The respect turn: the concern is not about the method but about standing alone behind a choice. The answer is to make the choice a team decision, written down.

### 1.3 `nta8120_audit` — De audit (Ms)

Principles tested: **long_term** (what you sustained is what the auditor sees) and **improve** (findings are information, not shame). There is no single temptation here: every shortcut the player took in Acts III–V can surface as a finding. That is the act's reckoning.

```yaml
missions:
  - id: nta8120_audit
    name: De audit
    kind: milestone
    tier: 4
    act: 5
    chapter: Het net van binnen
    requires: {missions: [t4_hoshin]}
    deadline_days: 90                     # the audit date, by post in the act's cliffhanger
    goal:
      type: audit
      judged_on: deadline
      fixes_holding: 6                    # resolved fixes with health >= health_min on the day (sustain design §1)
      health_min: 0.8
      resolved: [maintenance_calendar]    # "is maintenance risk-based?" is the audit's core question
      findings:
        - {fact: flag:queue_jumped, text: "Een aanvraag is buiten het prioriteringskader om voorgetrokken. Niet vastgelegd waarom.", reputation: -10}
        - {fact: flag:hidden_wip, text: "Aanvragen in een map 'concept' tellen niet mee in de doorlooptijd. De gemeten termijn is te kort.", reputation: -10}
        - {fact: flag:matrix_of_twenty, text: "De doelen zijn niet vertaald naar wat wel en niet gebeurt. Twintig projecten, geen keuzes.", reputation: -5}
        - {fact: flag:acm_clock_gamed, unless: picked:t2_first_okr:kr_conn_on_time, text: "De aansluittermijn wordt gemeten vanaf 'compleet' in plaats van vanaf de aanvraag. Registratie en meting spreken elkaar tegen.", reputation: -15, holding_correction: -1}   # tier-2 promise: a data-integrity finding; one fix fewer counted as holding (a correction of the measure, not a verdict)
        - {fact: flag:dug_without_klic, text: "In 2027 is gegraven zonder geldige KLIC-melding. Het incident is niet als leerpunt vastgelegd.", reputation: -5}   # tier-2 promise: the fail-safe beat
        - {fact: flag:intervals_stretched, unless: chose:maintenance_calendar:risk_based_maintenance, text: "Onderhoudsintervallen verlengd zonder risicoanalyse.", reputation: -10, major: true}
        - {missing: standardised:revision_backlog, text: "De revisie loopt achter op de aanleg. Het register klopt niet met wat er in de grond ligt.", reputation: -5}
      observations:                       # positive, read aloud by the auditor; no effect on the verdict
        - {fact: committed:nicole_lmra, text: "Monteurs stoppen een klus als het niet veilig is, en dat wordt gezien als goed werk."}
        - {fact: standardised:revision_backlog, text: "De revisie wordt bij de bron ingetekend en gecontroleerd. Mevrouw Van der Veen liet het zien."}
        - {fact: done:lsw_layered_audit, text: "Leidinggevenden controleren zelf of de standaarden worden gevolgd, op vaste momenten."}
    fail_closes_missions: [t4_sensor_pilot]
    fail_opens: nta8120_reaudit
    fail_effects: {reputation: -10}
    principles: [long_term, improve]
    briefing: "Over negentig dagen komt de certificerende instelling voor de NTA 8120-audit. Ze kijken of Voltana's assetmanagement op risico is gebaseerd, en of wat er verbeterd is, ook blijft staan. Ingrid: 'Ze lopen niet door onze presentaties. Ze lopen door het gebouw. Ze trekken een willekeurige standaard uit de kast en vragen een monteur of hij hem kent.'"
    debrief: "De audit is gehaald. {holding} verbeteringen staan nog zoals bedoeld. {findings_line} Rianne Hoogendoorn, de auditor: 'Ik heb hier mensen gezien die hun eigen standaard uitleggen. Dat zie ik niet overal.'"
    debrief_variants:
      failed: "De audit is niet gehaald. {holding} verbeteringen staan nog zoals bedoeld; er waren er zes nodig. {findings_line} Over vier maanden komt de auditor terug. Ingrid: 'Het is geen ramp. Het is een lijst. Lijsten kunnen we.'"
    beats:
      - {on: accepted, who: ingrid, text: "Negentig dagen. Ik maak geen map voor de auditor. Ik wil dat wat ze zien, waar is."}
      - {on: day_before, who: mieke, text: "Morgen laat ik de auditor zien hoe we intekenen. Ik heb niks voorbereid. Dat hoeft ook niet meer."}   # only if standardised:revision_backlog
      - {on: day_before, who: ruud, text: "Wat de auditor morgen ziet, heb je de afgelopen twee jaar gebouwd. Of niet. Morgen kun je niets meer doen. Slaap goed."}
    teaches: [nta_8120, sustain, leading_lagging]
    rewards: {xp: 4200, budget: 40000, reputation: 10}
```

**How the audit plays.**
- **The measure decides.** On the deadline the game counts resolved fixes with health ≥ 0.8 (sustain design §1) and checks that `maintenance_calendar` is resolved. Six or more, and resolved: passed. Fewer: failed.
- **Findings never decide the verdict.** Each one costs reputation and is read in the debrief's `{findings_line}`. A major finding (`major: true`) also turns a pass into "gehaald, met een grote bevinding": the reputation reward halves, and `nta8120_reaudit` opens as a side for that finding alone.
- **Observations are the respectful half.** The auditor names what the player built and who showed it.
- **Respect the player's time** (CLAUDE.md): the 90 days are in-game days. The countdown sits in the HUD only while the audit is the active milestone (audit doc §5.6). Nothing happens on a real-world clock.

**Dialog: `rianne_audit`.** The auditor, at the opening meeting. As with the ACM inspector in Act III, the talk does not change the measure. It changes how the report is written and the re-audit's tone.

```yaml
dialogs:
  - id: rianne_audit
    person: rianne
    kind: persuade
    mission: nta8120_audit
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    #   with committed:acm_inspector (Act III): +5 (a regulator's report she has read; proposed memory value) = 40
    opening: "Goedemorgen. Rianne Hoogendoorn. Ik heb vandaag een steekproef van twaalf standaarden en drie stations. U hoeft niets te presenteren. Ik vraag liever."
    position: {text: "Ik wil zien dat uw onderhoud op risico is gebaseerd, en dat uw verbeteringen er over een jaar nog staan. Niet in een map. In het werk.", tags: [claim]}
    layers:
      - {id: interest, at: 58, via: [inquiry, paraphrase], text: "Een certificaat zegt niet dat alles goed is. Het zegt dat een organisatie weet waar haar risico's zitten en ze zelf bijhoudt.", tags: [claim]}
      - id: concern
        at: 76
        via: [inquiry, paraphrase]   # 2026-10-16 (1.6c, route variety): facts; an auditor opens to a precise question
        lead_in: {text: "Wat ik vaak zie… en dat staat in mijn rapporten, die zijn openbaar…", tags: [hesitation, claim], tell: facts}
        text: "…is een organisatie die drie maanden voor de audit alles op orde brengt, en drie maanden erna weer loslaat. Dan heb ik een certificaat getekend voor iets wat er niet meer is. Ik teken liever een eerlijke bevinding dan een mooie momentopname."
        tags: [admission]
        unlocks: {facts: [heard:rianne_snapshot], proposals: [show_the_decay_data]}
    reframe: "Vanuit de monteur aan wie ik straks een standaard vraag? Die heeft geen map. Die heeft zijn handen en zijn gewoonte. Ja. Daar kijk ik naar."
    warning: "Als u mij een map gaat geven, leg hem maar op de stapel."
    data: ["maintenance_calendar:1"]
    lines:
      open_question:
        lands: {text: "Ik heb dit jaar elf netbeheerders bezocht. Bij negen zag ik hetzelfde patroon. Dat staat in mijn rapporten.", tags: [claim], tell: facts}
    proposals:
      - {id: the_audit_folder, addresses: [], label: "De auditmap", say: "We hebben alles voor u gebundeld in een map.", reply: "Dank u. Hij gaat op de stapel."}
      - {id: walk_the_standards, addresses: [concern], label: "Kies zelf welke standaarden u wilt zien", say: "Kies zelf welke standaarden en stations u wilt zien. Wij lopen mee, en de mensen leggen het uit.", reply: "Ik kies zelf. Goed. Dan begin ik bij de oudste standaard die u heeft."}
      - {id: show_the_decay_data, hidden: true, addresses: [concern], label: "Laten zien welke verbeteringen afglijden, en wat we doen", say: "Wat als we u laten zien welke verbeteringen afglijden, hoe we dat meten, en wat we eraan doen? Ook de slechte.", reply: "U meet zelf wat afglijdt. … Dat is precies wat een certificaat hoort te betekenen. Dat schrijf ik op."}
    outcomes:
      commitment: "Dank u. Ik schrijf in mijn rapport dat Voltana zelf bijhoudt wat afglijdt. Dat is het beste wat ik kan schrijven."
      partial: "Ik zie wat ik zie. Dat komt in het rapport, het goede en het andere."
      heard: "Dank u voor uw openheid."
      ruined: "Ik zal mijn bevindingen schriftelijk vastleggen."
    # route (start 35): open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > empathy +6 62
    #        > inquiry +8 (within 10 of 72) 70 > perspective +8 78 (lead-in, cue) > silence +12 > 81 capped (concern)
    #        > propose show_the_decay_data +8 89 > ask (9 moves). Her interest line carries no feeling, so reflect does not land.
    # Facts: committed:rianne_audit softens nta8120_reaudit's briefing and debrief if the audit fails ("Ze weet dat we het zelf meten").
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (rule_bound): interest.at 52->58, concern.at 72->76.
    # 2026-10-16 (1.6c, route variety): the lead-in is a claim; a precise question or Rianne's words said back draw the concern out. Silence lets the moment pass.
    # 2026-10-16 (1.6c, route variety): open questions land with a claim in Rianne's own words, so Samenvatten and Doorvragen have something to answer (a tell of facts).
```

**Path dependence.** The audit is the act's widest reader of earlier play:

| Read | From | Effect on the day |
|---|---|---|
| fix health of every resolved problem | tiers 1–4 (sustain design) | The verdict. Standardised fixes kept by routines and audits are the expert path. |
| `flag:queue_jumped`, `flag:hidden_wip` | Act IV temptations (tier-3 draft §3.2) | Findings, reputation −10 each. |
| `flag:matrix_of_twenty`, `flag:intervals_stretched` | Act V (§1.1, §1.2) | Findings; the second is major unless risk-based maintenance replaced it. |
| `standardised:revision_backlog` | Act II (audit §5.3: Mieke as witness) | An observation and Mieke's beat, or a minor finding. |
| `committed:nicole_lmra` | Act III | An observation. |
| `committed:acm_inspector` | Act III | Rianne starts at 40. |
| D38 *De lege map* | Act IV (engagement loop §4.2) | Checked here: the application-date check finds nothing hidden. |

- **The validator's rule holds.** A failed audit closes `t4_sensor_pilot`, but its investment option keeps another branch (`chose:ls_grid_blind:meter_power_failure_log`), and the re-audit opens.

**Grounding.**
- **NTA 8120 certification** by an accredited certifying body; audits sample standards and sites; findings are graded (minor and major non-conformities are standard audit practice).
- **The "snapshot" worry:** Rother, *Toyota Kata* (2009), on sustaining. The sustain design's decay is what the auditor samples.
- Twelve standards and three stations: an estimate of one audit day's sample.

**Engrossing.**
- The first mission where nothing can be done on the day. Two years of choices are read aloud, by a stranger, in the order she picks.
- Mieke's "Ik heb niks voorbereid. Dat hoeft ook niet meer" is the reward for a player who sustained the Act II fix: a person who is proud.

### 1.4 The fork `t4_detect`: `fix_ls_grid_blind` (B) and `fix_grid_losses_theft` (N)

**The fork card:** "Twee teams vragen om je aandacht."
- **Kees, control room:** "In het laagspanningsnet zijn we blind. We weten pas dat er een straat zonder stroom zit als iemand belt. 's Nachts duurt dat soms een uur."
- **Monique, Financiën:** "We kopen elk jaar voor miljoenen aan netverliezen in. Een deel daarvan is gestolen stroom. Dat is geld dat we nergens anders aan kunnen uitgeven."

Both numbers are true. The fork is honest on **outage minutes** (correction 2): B shortens them, N saves money and barely moves them. The N debrief says both.

#### `fix_ls_grid_blind` — Blind in het laagspanningsnet (M, B)

Principles tested: **improve** (see the fault before the customer does) and **respect** (an alarm that wakes the night shift must be worth waking for). Temptation: switch on every meter alarm at once.

```yaml
missions:
  - id: fix_ls_grid_blind
    name: Blind in het laagspanningsnet
    kind: main
    tier: 4
    act: 5
    chapter: Het net van binnen
    requires: {missions: [fix_maintenance_calendar]}
    fork: {group: t4_detect, role: bottleneck}
    goal: {type: solve, problem: ls_grid_blind}
    principles: [improve, respect]
    briefing: "Een storing in het middenspanningsnet ziet de meldkamer meteen op de wand. Een storing in het laagspanningsnet, een straat of een paar huizen, ziet niemand, tot er iemand belt. Kees Mulder: 'Overdag belt er binnen tien minuten iemand. 's Nachts slaapt de straat. Dan belt de eerste om zeven uur, als de koelkast lekt.'"
    debrief: "De meldkamer ziet een storing in het laagspanningsnet nu gemiddeld {noticed_after} minuten na het begin, was {noticed_before}. Een storing duurt voor de klant {outage_delta} minuten korter. Kees: 'Vannacht stond de monteur er voordat de eerste klant belde. Die klant vroeg of we gedachten kunnen lezen.'"
    debrief_first: "Je koos de blinde vlek in het net. De gestolen stroom wacht nog: dat kost geld, maar geen storingsminuten. Monique heeft het genoteerd."
    reopen: "De meldingen van de meters worden weer weggeklikt. Er kwamen te veel, en niemand paste de regel aan."
    beats:
      - {on: accepted, who: kees, text: "Kom een nacht bij ons zitten. Dan zie je hoe stil het is als er niets op de wand staat. En hoe het dan toch mis kan zijn."}
    temptations:
      - id: every_meter_alarm
        who: it_manager
        when: accepted
        text: "Zet gewoon van alle slimme meters de stroomuitvalmelding aan. Dan zie je alles, meteen."
        accept: "Je laat alle meldingen van alle meters naar de meldkamer sturen."
        decline: "Je laat de meldkamer zelf bepalen welke meldingen tellen."
        accept_sets_flags: [flag:alarm_flood]
        accept_effects: {measure_bonus: {kpi: lead_time, value: -0.05}, trust: {control_room: -1}}
    teaches: [jidoka, lead_time, slimme_meter]
    rewards: {xp: 4400, budget: 40000, reputation: 5, trust: {control_room: 1}}
    insights:
      go_see: "Hoe hoort de meldkamer nu van een storing in een straat? Heb je een nacht meegekeken?"
      understand: "Waar zit de tijd tussen het moment dat de stroom uitvalt en het moment dat de monteur vertrekt?"
      experiment: "Als de meters zelf melden, hoeveel minuten verwacht je te winnen? En hoeveel valse meldingen krijgt Kees erbij?"
      reflect: "Wat had de meldkamer nodig om een melding te vertrouwen?"

problems:
  - id: ls_grid_blind
    tier: 4
    name: Blind in het laagspanningsnet
    step: outages.noticed               # new wait step (correction 1)
    waste: waiting
    severity: high
    visibility: hidden
    kpi: lead_time
    symptoms:
      - Storingen in het laagspanningsnet worden pas opgemerkt als een klant belt.
      - Nachtelijke storingen in een straat duren gemiddeld veel langer dan overdag.
    root_cause: In het laagspanningsnet zitten geen metingen die de meldkamer ziet. De slimme meters registreren wel wanneer de stroom uitvalt, maar die gegevens worden alleen maandelijks uitgelezen voor de administratie, niet gebruikt om storingen te zien.
    plausible_causes:
      - Klanten bellen te laat.
      - De meldkamer let 's nachts niet goed op.
      - Er zijn te weinig monteurs met consignatiedienst.
    mismatch_note: Meer monteurs of een alertere meldkamer helpen niet als niemand weet dat er iets mis is. De tijd zit vóór de melding, niet erna.
    countermeasures: {meter_power_failure_log: 1.0, lv_sensors_msr: 0.9, outage_map_for_customers: 0.6, alarm_every_meter: 0.5}
    teaches: [jidoka, lead_time]
    effects:
      # estimate: a base of 0.5 h until the first call (day and night mixed); for LV faults at night the first call
      # comes much later. Averaged over LV faults (~half of all outages, at night ~a third of those): x2.5
      - {target: outages.noticed, property: wait_time, value: 2.5}
    clues:
      - {tool: data, key: true, depth: 0, at: outages.report, text: "Bij storingen in het laagspanningsnet zit er 's nachts gemiddeld 70 minuten tussen het begin van de storing en het eerste telefoontje. Overdag 12."}
      - {tool: shadow, key: true, depth: 1, at: outages.report, text: "Om 03.40 uur is de wand groen. Om 07.05 uur belt een klant uit de Spechtstraat: geen stroom sinds de nacht. Kees zoekt het op. De meters in die straat registreerden de uitval om 03.52."}
      - {tool: documents, key: true, depth: 1, text: "De slimme meters houden een logboek bij van stroomuitval. Voltana leest het eens per maand uit, voor de administratie."}
      - {tool: conversation, key: true, depth: 2, at: outages.report, text: "'In 2021 hebben ze een proef gedaan met meldingen van meters. Eerste nacht driehonderd meldingen. Een meter die even hapert, een huis waar de hoofdschakelaar om gaat. We hebben hem uitgezet.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Mensen bellen gewoon te laat. Vroeger belden ze meteen.'"}

countermeasures:
  - id: meter_power_failure_log
    name: Meldingen van meters, slim gefilterd
    tier: 4
    category: quality
    description: De stroomuitval die slimme meters registreren, gaat binnen enkele minuten naar de meldkamer, maar alleen als meerdere meters op dezelfde kabel tegelijk uitvallen. Eén huis met een omgevallen schakelaar geeft geen melding. De meldkamer bepaalt zelf de drempel.
    budget: 25000
    team_hours: {control_room: 15, meter_office: 10, ops: 20}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages.noticed, property: wait_time, value: 0.45}
  - id: lv_sensors_msr
    name: Sensoren in de middenspanningsruimte
    tier: 4
    category: visual_management
    description: In de stations komen sensoren op de uitgaande laagspanningskabels. Valt een kabel uit, dan ziet de meldkamer het meteen, met de straat erbij.
    budget: 60000
    team_hours: {monteurs: 30, control_room: 10}
    decay_days: null
    needs: {all: [done:t4_sensor_pilot]}
    preparation: "Daarvoor moet je eerst weten wat sensoren in het net laten zien."
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages.noticed, property: wait_time, value: 0.5}
  - id: outage_map_for_customers
    name: Een storingskaart voor klanten
    tier: 2
    category: visual_management
    description: Op de website staat een kaart met bekende storingen, en klanten kunnen een storing met één klik melden.
    budget: 6000
    team_hours: {portal_team: 15}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages.noticed, property: wait_time, value: 0.85}
  - id: alarm_every_meter
    name: Elke meter meldt
    tier: 2
    category: quality
    description: Elke stroomuitval van elke slimme meter gaat naar de meldkamer. Niets wordt gemist; ook niet wat geen storing is.
    budget: 10000
    team_hours: {ops: 10}
    decay_days: 60
    trust: {control_room: -1}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages.noticed, property: wait_time, value: 0.6}
      - {target: outages.report, property: touch_time, value: 1.3}   # estimate: the control room clicks through false alarms
```

**Dialog: `kees_meter_alarms`.** Kees, from the Act 0–II check-in and Act III's handover, now as the person who must trust the meters.

```yaml
dialogs:
  - id: kees_meter_alarms
    person: kees
    kind: persuade
    mission: fix_ls_grid_blind
    owns: ls_grid_blind
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + memory
    #   with kees_night lifted (Acts 0-II check-in): +5 (a lifted check-in; proposed memory value) = 45
    #   with committed:wendy_handover (Act III, the control room's handover): team trust control_room +1 = +10
    opening: "Je komt voor de meters. Ik weet het. We hebben het in 2021 geprobeerd. Koffie?"
    position: {text: "Meldingen van meters hebben we geprobeerd. Driehonderd in één nacht. Dat doen we niet nog een keer.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Ik wil best eerder weten dat een straat donker is. Ik zit hier 's nachts. Ik zie een groene wand en ik weet dat het niet waar hoeft te zijn.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [inquiry, paraphrase]   # 2026-10-16 (1.6c, route variety): facts; three hundred in one night, it is in the log
        lead_in: {text: "Maar als het weer… Driehonderd in één nacht. Dat staat gewoon in het logboek.", tags: [hesitation, claim], tell: facts}
        text: "…driehonderd meldingen worden, klik ik ze weg. Iedereen klikt ze weg. En dan zit er één echte tussen, een straat met een oude dame aan de zuurstof, en die klik ik ook weg. Dan is het niet de meter die het mist. Dan ben ik het."
        tags: [admission]
        unlocks: {facts: [heard:kees_alarm_fatigue], proposals: [kees_sets_the_threshold]}
    reframe: "Vanuit de straat? Die slaapt. Die weet niet eens dat hij geen stroom heeft. Tot de koelkast lekt. Ja. Die heeft niemand die voor hem wakker is. Behalve ons."
    warning: "Als je komt zeggen dat het deze keer anders is, wil ik weten waarom."
    data: ["ls_grid_blind:0", "ls_grid_blind:1"]
    proposals:
      - {id: switch_on_the_log, addresses: [interest], label: "De meldingen van de meters aanzetten", say: "Laat de meters hun stroomuitval meteen melden.", reply: "Meteen. Allemaal? Dan zitten we weer op driehonderd."}
      - {id: kees_sets_the_threshold, hidden: true, addresses: [concern], label: "Kees bepaalt wanneer een melding telt", say: "Wat als alleen een groep meters op dezelfde kabel samen een melding geeft, en jij bepaalt hoeveel? Jij past de drempel aan, elke week, tot je hem vertrouwt.", reply: "Ik bepaal de drempel. Drie meters op één kabel, binnen vijf minuten. Dat is geen hapering. Dat is een straat. … Dat wil ik proberen."}
    experiments:
      - {id: shadow_month, addresses: [concern], label: "Een maand meelopen, zonder alarm", say: "Een maand komen de meldingen in een apart scherm, zonder alarm. Jij kijkt na hoeveel er echt waren.", reply: "Een maand kijken zonder dat het piept. Dan weet ik wat ik krijg. Goed."}
    co_proposal: {id: kees_sets_the_threshold, text: "En geef me een knop 'vals'. Als ik er een wegklik, wil ik dat het systeem leert waarom."}
    outcomes:
      commitment: "Afgesproken. En ik vertel Wendy zelf hoe het werkt. In de overdracht."
      partial: "Die drempel bepaal ik. Dan doe ik mee."
      heard: "Je vroeg naar 2021. De anderen deden alsof het nooit gebeurd was."
      compliance: "Zet het maar aan. Ik zie wel."
      ruined: "Zie je. Driehonderd, deel twee."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry x1.5 +12 (craftsman) > 64 capped (interest)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern) > propose kees_sets_the_threshold +8 89 > ask: commitment (7 moves)
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (craftsman): concern.at 72->70.
    # 2026-10-16 (1.6c, route variety): the lead-in is a claim; a precise question or Kees's words said back draw the concern out. Silence lets the moment pass.
```

**Path dependence.**
- **`flag:alarm_flood`** (the temptation): a small measure bonus now. The control room's trust falls, and `outages.report` touch time rises (the `alarm_every_meter` effect, as the temptation's aftermath, from day 14).
  - Cleared when `meter_power_failure_log` replaces it.
  - D48-style guard: no reward reads a flooded control room as success.
- **`committed:petra_station_data`** (Act III): station load is already queried weekly. `meter_power_failure_log` costs 30 % less (`needs_discount`); the data path exists.
- **`done:t4_sensor_pilot`** unlocks `lv_sensors_msr`. A player who failed the audit can still pick the meter log: the validator branch.
- **Set:** `chose:ls_grid_blind:meter_power_failure_log` is one `any` branch of the investment plan's "Sensoren in het LS-net".

**Grounding.**
- **Smart meters (DSMR) record power failures**, including a log of long failures (DSMR P1 companion standard: "number of power failures", "power failure event log"). *Verify that the grid operator can read the event log remotely at the needed frequency* (catalogue's own "verify the feature").
- **LV faults are known only when customers call** (GDD outage stream).
- **Alarm fatigue** is a known control-room risk (human factors in control rooms; EEMUA 191 on alarm management, *verify edition*).
- 70 and 12 minutes, 2021's 300 alarms: estimates and fiction.

**Engrossing.**
- The night the player sits with Kees: a green wall and a dark street.
- The twist is that the obvious fix failed before, for a human reason. The good countermeasure is the same data with a filter that the person on duty owns.

#### `fix_grid_losses_theft` — Stroom die verdwijnt (M, N)

Principles tested: **respect** (nobody knocks on a dangerous door alone) and **long_term**. Temptation: send the meter technicians to check suspicious addresses during their normal visits.

```yaml
missions:
  - id: fix_grid_losses_theft
    name: Stroom die verdwijnt
    kind: main
    tier: 4
    act: 5
    chapter: Het net van binnen
    requires: {missions: [fix_maintenance_calendar]}
    fork: {group: t4_detect, role: non_bottleneck}
    goal: {type: solve, problem: grid_losses_theft}
    principles: [respect, long_term]
    briefing: "Voltana koopt elk jaar stroom in om de verliezen in het net aan te vullen. Een deel is natuurkunde: kabels worden warm. Een deel is diefstal, vaak voor hennepkwekerijen. Monique de Ruiter van Financiën: 'Ik betaal elke week voor stroom die iemand anders gebruikt. En soms vliegt er een meterkast in brand.'"
    debrief: "De verliezen in Zuidmark zijn met {losses_delta} euro per week gedaald. Drie illegale aftakkingen zijn samen met de politie gevonden, zonder dat een meterwisselaar alleen naar binnen ging. De storingen duurden voor klanten even lang als voor deze missie: gestolen stroom kost geld, geen storingsminuten. Yvonne: 'Ik hoef niet meer te raden achter welke deur iets zit.'"
    debrief_first: "Je koos de gestolen stroom. Het geld is terug. De straten die 's nachts donker worden, worden nog steeds pas gezien als iemand belt. Kees heeft het genoteerd."
    reopen: "De verliezen lopen weer op. De balansanalyse wordt niet meer elke maand gedraaid."
    beats:
      - {on: accepted, who: yvonne, text: "Je komt over de diefstal? Ik weet welke adressen. Ik ga er alleen niet meer alleen heen."}
    temptations:
      - id: solo_checks
        who: monique
        when: accepted
        text: "Laat de meterwisselaars bij verdachte adressen even binnenkijken als ze toch in de straat zijn. Dat kost niks extra."
        accept: "Je laat de meterwisselaars verdachte adressen controleren tijdens hun gewone ronde."
        decline: "Je laat verdachte adressen alleen samen met de politie bezoeken."
        accept_sets_flags: [flag:solo_checks]
        accept_effects: {trust: {meters: -1}, budget: 5000}
    teaches: [systems_thinking, customer_value, respect_for_people]
    rewards: {xp: 3800, budget: 45000, reputation: 3}
    insights:
      go_see: "Waar zit het verschil tussen wat een station levert en wat de meters erachter tellen? Heb je de cijfers per station gezien?"
      understand: "Welk deel van de verliezen is natuurkunde en welk deel is diefstal? Hoe weet je het verschil?"
      experiment: "Als je de grootste verschillen samen met de politie bezoekt, wat verwacht je dan aan verliezen terug te zien? En aan storingen?"
      reflect: "Wat heeft deze oplossing de klant in het donker opgeleverd? Wat wel, en wat niet?"

problems:
  - id: grid_losses_theft
    tier: 4
    name: Stroom die verdwijnt
    step: outages.repair                 # where the faults from illegal connections show; the cost is on the region
    waste: defects
    severity: medium
    visibility: hidden
    kpi: lead_time
    symptoms:
      - Voltana koopt elk jaar meer stroom in voor netverliezen dan de natuurkunde verklaart.
      - Een paar keer per jaar brandt een meterkast of een aftakking af bij een woning.
    root_cause: Niemand vergelijkt per station wat erin gaat met wat de meters erachter tellen. Diefstal verdwijnt in één groot getal 'netverliezen', dat jaarlijks wordt ingekocht. Wie een vermoeden heeft, weet niet bij wie hij het moet melden, en meterwisselaars gaan er soms alleen op af.
    plausible_causes:
      - De kabels in Zuidmark zijn gewoon oud; dat geeft meer verlies.
      - De meters meten niet nauwkeurig.
    mismatch_note: Oude kabels en meters verklaren een deel, maar niet waarom het verlies achter een paar stations veel groter is dan achter de rest.
    countermeasures: {balance_analytics: 1.0, joint_checks_police: 0.7, field_reports_never_alone: 0.6, solo_meter_checks: 0.4}
    teaches: [systems_thinking]
    # estimate: ~1 billion kWh a year stolen nationwide (DutchNews 2019, in GDD); Zuidmark ~200,000 connections of ~8.5 million
    # (~2.4%) -> ~24 GWh; at ~EUR 0.08/kWh ~EUR 37k a week. The game models the part a regional fraud desk can find and
    # recover within a year (~15%, estimate): EUR 5,500 a week.
    cost_per_week: 5500
    effects:
      - {target: outages, property: demand, value: 1.03}   # estimate: faults and fires from tampered connections
    clues:
      - {tool: data, key: true, depth: 0, text: "Het ingekochte netverlies is in drie jaar met een kwart gestegen. Het aantal klanten met een tiende."}
      - {tool: data, key: true, depth: 1, at: maintenance.inspect, text: "Achter het station in de Kanaalstraat telt de som van de meters 40 procent minder dan het station levert. Achter de stations ernaast vijf procent."}
      - {tool: conversation, key: true, depth: 1, at: meters.visit, text: "'In de Kanaalstraat zit bij nummer 14 een meterkast met verse schroeven en een slot erop. Vorig jaar stond daar een man met een honkbalknuppel in de gang. Ik ben weggegaan.'"}
      - {tool: documents, key: true, depth: 2, text: "Er is een afspraak met de politie over gezamenlijke controles. Hij is van 2017. Niemand bij Voltana weet wie de contactpersoon is."}
      - {tool: conversation, key: false, depth: 0, text: "'Die kabels zijn van voor de oorlog. Natuurlijk lekt er stroom weg.'"}

countermeasures:
  - id: balance_analytics
    name: Wat erin gaat en wat eruit komt, per station
    tier: 4
    category: quality
    description: Elke maand vergelijkt de fraude-analist per station de levering met de som van de meters erachter. Een groot verschil gaat naar een gezamenlijke controle met de politie.
    budget: 20000
    team_hours: {fraud_desk: 30, meter_office: 10}
    decay_days: 120
    needs_discount: {needs: {any: [committed:petra_station_data]}, budget: 0.6, team_hours: 0.7}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.98}
  - id: joint_checks_police
    name: Samen met de politie en de gemeente
    tier: 3
    category: safety
    description: De afspraak met de politie wordt vernieuwd, met een vaste contactpersoon. Verdachte adressen worden alleen samen bezocht, met de gemeente erbij.
    budget: 5000
    team_hours: {fraud_desk: 15, meters: 5}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: field_reports_never_alone
    name: Melden wat je ziet, nooit alleen naar binnen
    tier: 2
    category: safety
    description: Meterwisselaars en monteurs melden in de app wat hun opvalt bij een adres. Ze gaan nooit alleen een verdacht pand in; de melding gaat naar de fraude-analist.
    budget: 2000
    team_hours: {fraud_desk: 5, monteurs: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: solo_meter_checks
    name: Meterwisselaars kijken even binnen
    tier: 1
    category: people
    description: Meterwisselaars controleren verdachte adressen tijdens hun gewone ronde. Er is geen afspraak met de politie.
    budget: 0
    team_hours: {}
    decay_days: 60
    trust: {meters: -2}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

`cost_per_week` here is the problem's own (as in tier 1). The countermeasures' recovered share is their effectiveness on that cost: `balance_analytics` at full recovers most of it, `joint_checks_police` part, and the solo checks a little (an estimate, calibrated in K8).

**Dialog: `yvonne_theft`.** Yvonne, the meter technician from Act I's stack of cards, knows the addresses and is afraid of one door. Her concern is safety, and the mission's best countermeasure must answer it.

```yaml
dialogs:
  - id: yvonne_theft
    person: yvonne
    kind: persuade
    mission: fix_grid_losses_theft
    owns: grid_losses_theft
    patience: 9
    # start: quiet 47 + 0 + 0 + 0 + memory
    #   with yvonne_cards lifted (Acts 0-II check-in): +5 = 52
    opening: "Kanaalstraat? Ja. Ik weet welke nummers. Ik weet ook welke deur ik niet meer opendoe."
    position: {text: "Ik wissel meters. Ik ben geen politie.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, mood, silence], text: "Je ziet het aan de kast. Verse schroeven, een slot erop, een raar zoemend geluid. Ik schrijf het op een kaartje. Ik weet niet wat er met die kaartjes gebeurt.", tags: [claim, feeling]}
      - id: concern
        at: 66
        via: [experience, empathy]   # 2026-10-16 (1.6c, route variety): safety; she never reported it, and tells it only to someone who also froze once
        lead_in: {text: "Vorig jaar… Nee. Laat maar. Het is gek.", tags: [hesitation, doubt], tell: safety}
        text: "…stond er bij nummer 14 een man in de gang met een honkbalknuppel. Hij zei niks. Hij stond daar alleen. Ik ben weggegaan en heb in de bus zitten trillen. Ik heb het niet gemeld. Ik dacht: dan sturen ze me volgende keer weer."
        tags: [admission]
        unlocks: {facts: [heard:yvonne_door], proposals: [never_alone_rule]}
    reframe: "Vanuit de buren van nummer 14? Die hebben een brandende meterkast naast hun kinderkamer. Ja. Die moeten ook beschermd worden. Alleen niet door mij alleen."
    warning: "Als je me vraagt om even te kijken, zeg ik nee."
    data: ["grid_losses_theft:1", "grid_losses_theft:2"]
    lines:
      experience:
        say: "Ik heb ook eens ergens gestaan waar ik me niet veilig voelde. Ik heb het ook aan niemand verteld."
        lands: {text: "… Nee. Je vertelt het niet. Dan lijkt het alsof je je aanstelt.", tags: [admission]}
    proposals:
      - {id: report_what_you_see, addresses: [interest], label: "Melden wat je ziet, in de app", say: "Meld wat je ziet in de app, en de fraude-analist doet de rest.", reply: "In de app. Dan weet ik tenminste dat iemand het leest."}
      - {id: never_alone_rule, hidden: true, addresses: [concern], label: "Een regel: nooit alleen, en wie meldt, wordt niet gestuurd", say: "Wat als het een regel wordt: niemand van Voltana gaat alleen een verdacht adres in, en wie iets meldt, wordt er nooit zelf heen gestuurd? De controle doet de politie, met iemand van ons erbij die het wil.", reply: "Wie meldt, wordt niet gestuurd. … Dan meld ik nummer 14. En de twee andere die ik weet."}
    experiments:
      - {id: one_street_with_police, addresses: [concern], label: "Eén straat, samen met de politie", say: "Eén controle in de Kanaalstraat, samen met de politie. Jij hoeft er niet bij, tenzij je wilt.", reply: "Tenzij ik wil. Misschien wil ik wel. Als ik achter de agent sta."}
    co_proposal: {id: never_alone_rule, text: "En zeg het tegen alle meterwisselaars. Niet alleen tegen mij. Ik ben niet de enige die in de bus heeft gezeten."}
    outcomes:
      commitment: "Goed. Ik schrijf de drie adressen op. Vandaag nog. En ik ga er niet alleen heen."
      partial: "Ik meld het. Als ik er niet heen hoef."
      heard: "Dank je dat je vroeg. Ik had het nog niemand verteld."
      compliance: "Goed. Ik kijk wel even. Als het moet."
      ruined: "Toch even binnenkijken. Dan doe je dat zelf maar."
    # route (start 47): open question +6 53 > paraphrase +7 60 (heard, interest) > reflect +10 70
    #        > empathy +6 76 (lead-in, cue) > silence +18 (quiet x1.5) > 81 capped (concern) > propose never_alone_rule +8 89 > ask (7 moves)
    # Safety (spec §4.2): pressure on Yvonne to "even kijken" ends the talk as compliance and sets flag:solo_checks' trust cost.
    # 2026-10-16 (four-tier audit §4): interest via [open_question, silence, paraphrase] -> [open_question, mood, silence] (quiet). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (quiet): interest.at 55->50, concern.at 72->66.
    # 2026-10-16 (1.6c, route variety): at the lead-in Yvonne doubts whether to say it; only the player's own story (Ervaring delen, once heard and trusted) draws the concern out. Silence or a question lets the moment pass.
```

**Path dependence.**
- **`flag:solo_checks`** (the temptation): +€5,000 now, and the goal does not complete by it. Within 60 days an event: a meter technician is threatened at a door.
  - The event costs reputation −5 and trust meters −2. Yvonne's next check-in opens at a low bar.
  - Cleared only by `joint_checks_police` or `field_reports_never_alone`.
  - D48 *Niemand alleen naar binnen* (§4) can never fire once it was set.
- **`committed:petra_station_data`** (Act III): the station query exists, so balance analytics is cheaper.
- **`yvonne_cards` lifted** (Acts 0–II check-in): she starts at 52.
- **The fork's honesty:** the debrief names the euros and says the outage minutes did not change. The N-first `debrief_first` line names Kees.

**Grounding.**
- About 1 billion kWh a year stolen in the Netherlands, much of it for cannabis cultivation (DutchNews 2019, in GDD).
- Grid operators buy their grid losses on the market (*verify the procurement practice for regional operators*).
- Joint checks of grid operators with police and municipalities on illegal connections are common practice (*verify a public source*, e.g. a regional covenant).
- Threats against field staff: a known safety risk for meter technicians (*verify a public source*); the story here is fiction.
- 40 %, a quarter in three years, and the 2017 agreement: estimates and fiction.

**Engrossing.**
- A money problem that turns into a safety problem the moment the player meets the person who would carry the shortcut.
- The respectful fix finds more theft, because people report once reporting is safe.

### 1.5 `t4_sensor_pilot` — Sensoren in het net (S)

```yaml
missions:
  - id: t4_sensor_pilot
    name: Sensoren in het net
    kind: side
    tier: 4
    act: 5
    requires: {facts: {all: [done:nta8120_audit]}}   # a failed audit closes it (the catalogue's door; fail_closes_missions)
    goal: {type: observe, places: [msr.lijsterstraat, msr.kanaalstraat, msr.nieuwe_haven], tool: data, then: {talk_to: ingrid, topics: [sensoren]}}
    principles: [improve]
    briefing: "Ingrid wil drie stations met sensoren uitrusten: een oude, een drukke en een nieuwe. 'Niet om alles te meten. Om te leren wat we moeten meten.' Ga kijken wat ze laten zien."
    debrief: "Drie stations, drie verhalen. Het oude station in de Lijsterstraat wordt 's avonds warm, het drukke in de Kanaalstraat heeft een kabel die zwaarder belast wordt dan iemand dacht. Ingrid: 'Nu weten we waar de volgende sensor moet. Niet overal. Daar.'"
    teaches: [asset_health_index, leading_lagging]
    rewards: {xp: 1500, unlocks: [lv_sensors_msr]}
```

- **Small and memorable** (audit §5.4): one person (Ingrid), one place (three stations), one twist (the new station is the boring one), one object (a sensor clamp on a cable).
- **Path:** `flag:deep_cables` (Act IV, Havenzij's deep bypass) adds a fourth line to the debrief: "In de Nieuwe Haven ligt de kabel dieper dan de tekening zegt. De sensor ziet hem warm worden." The forecast of "Sensoren in het LS-net" counts it.

### 1.6 `fix_flex_market_unused` — Een markt zonder bieders (M)

Principles tested: **long_term** (a market people trust outlasts one that is cheap today) and **respect** (a customer who offers flex is a partner, not a switch). Temptation: buy all the flex from the one party that offers it, at any price.

```yaml
missions:
  - id: fix_flex_market_unused
    name: Een markt zonder bieders
    kind: main
    tier: 4
    act: 5
    chapter: Wat het systeem kan dragen
    requires: {facts: {any: [done:fix_ls_grid_blind, done:fix_grid_losses_theft]}}
    goal: {type: solve, problem: flex_market_unused}
    principles: [long_term, respect]
    briefing: "Op de Kanaalzone staan bedrijven in de wachtrij voor transportcapaciteit, terwijl anderen op drukke uren best minder zouden willen afnemen, tegen betaling. Voltana vraagt die flexibiliteit via het landelijke platform GOPACS, maar er komen bijna geen biedingen. Thomas Visser: 'Mijn klanten weten niet eens dat het bestaat. En als ze het weten, vertrouwen ze het niet.'"
    debrief: "Er komen nu elke week biedingen binnen voor de Kanaalzone, van {bidders} partijen. De wachtrij voor capaciteit is {queue_delta} dagen korter. Thomas: 'Ik verkoop geen beperking meer. Ik verkoop een afspraak. Dat is een ander gesprek.' {wim_line}"
    debrief_variants:
      poor_fix: "Kanaalzone Waterstof levert alle flexibiliteit, tegen drie keer de prijs. De wachtrij is korter, maar elke week stuurt Monique een mail met het bedrag."
    reopen: "De biedingen lopen terug. De klanten zien niet meer hoe vaak ze worden afgeroepen, en ze stoppen met bieden."
    beats:
      - {on: accepted, who: thomas, text: "Ik neem je mee naar de ondernemersvereniging. Zeg daar niet 'flexibiliteit'. Zeg 'geld verdienen met wat u toch al doet'."}
      - {on: completed, who: wim, text: "Ik heb een thuisbatterij en een aggregator. Ze zeggen dat ik nu meedoe aan uw markt. Ik heb er een spreadsheet voor gemaakt. Natuurlijk."}   # only if chose:flex_market_unused:aggregator_for_small
    temptations:
      - id: one_big_seller
        who: kzw
        when: accepted
        text: "Kanaalzone Waterstof kan al uw flexibiliteit leveren. Alles, elke dag, één contract. Tegen onze prijs."
        accept: "Je koopt alle flexibiliteit bij Kanaalzone Waterstof."
        decline: "Je zorgt dat meer bedrijven kunnen bieden."
        accept_sets_flags: [flag:flex_single_seller]
        accept_effects: {complete_goal: true, cost_per_week: 4000}
    teaches: [gopacs, netcongestie, customer_value]
    rewards: {xp: 4600, budget: 40000, reputation: 5, trust: {key_accounts: 1}}
    insights:
      go_see: "Heb je met een bedrijf gesproken dat zou kunnen bieden en het niet doet? Wat zei het?"
      understand: "Wanneer vraagt Voltana om flexibiliteit, en wanneer weet Voltana al dat het nodig is? Hoeveel tijd zit daartussen?"
      experiment: "Als meer bedrijven kunnen bieden, wat verwacht je dan van de wachtrij? En van de prijs?"
      reflect: "Wat heeft een klant nodig om een netbeheerder te vertrouwen met zijn stroom?"

problems:
  - id: flex_market_unused
    tier: 4
    name: Een markt zonder bieders
    step: congestion.capacity_queue
    waste: inventory
    severity: high
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Er komen bijna geen biedingen binnen als Voltana om flexibiliteit vraagt.
      - Bedrijven op de Kanaalzone wachten op capaciteit die op de meeste uren gewoon vrij is.
    root_cause: Voltana vraagt flexibiliteit pas de dag van tevoren, ook voor werk dat weken eerder gepland is. Middelgrote en kleine klanten kunnen niet zelf bieden, en niemand legt uit wat het oplevert. Wie ooit heeft geboden, hoort nooit hoe vaak en waarom hij is afgeroepen.
    plausible_causes:
      - Bedrijven willen gewoon niet meewerken.
      - De vergoeding is te laag.
      - Het platform is te ingewikkeld.
    mismatch_note: Een hogere vergoeding of een simpeler platform helpt weinig als de vraag te laat komt, kleine partijen niet mee kunnen doen en niemand hoort wat er met zijn bod gebeurde.
    countermeasures: {gopacs_participation: 1.0, flex_in_contracts: 0.8, aggregator_for_small: 0.7, single_seller_contract: 0.5}
    fit_modifiers:                         # tier-2 promise (S-new): customers who saw an all-red map believe flex less
      - {needs: {all: [flag:map_all_red], none: [repaired:stale_capacity_map]}, countermeasures: [gopacs_participation, flex_in_contracts, aggregator_for_small], delta: -0.1}
    teaches: [gopacs, netcongestie]
    effects:
      # estimate: congestion relief that is not bought keeps requests in the capacity queue ~20% longer
      - {target: congestion.capacity_queue, property: wait_time, value: 1.2}
    clues:
      - {tool: data, key: true, depth: 0, at: congestion.capacity_queue, text: "Voltana vroeg vorig jaar veertig keer om flexibiliteit op de Kanaalzone. Er kwamen negen biedingen, van twee partijen."}
      - {tool: documents, key: true, depth: 1, at: congestion.offer, text: "Alle verzoeken gingen de dag van tevoren uit. Bij dertig ervan was het werk aan het net al drie weken gepland."}
      - {tool: conversation, key: true, depth: 1, at: congestion.offer, text: "'Ik heb een keer geboden. Ik ben vier keer afgeroepen. Waarom, wanneer, hoeveel het opleverde: niemand heeft het me verteld. Dus bied ik niet meer.'"}
      - {tool: data, key: true, depth: 2, text: "Op de Kanaalzone staan veertig bedrijven met koelcellen, laadpleinen of batterijen. Drie daarvan zijn groot genoeg om zelf op het platform te bieden."}
      - {tool: conversation, key: false, depth: 0, text: "'Bedrijven willen gewoon niet. Die denken alleen aan zichzelf.'"}

countermeasures:
  - id: gopacs_participation
    name: Vroeg vragen, open terugmelden
    tier: 4
    category: flow
    description: Voltana zet de vraag naar flexibiliteit op het platform zodra het werk gepland is, weken vooraf in plaats van een dag. Elke bieder krijgt na afloop te zien wanneer hij is afgeroepen, waarom, en wat het opleverde.
    budget: 12000
    team_hours: {key_accounts: 20, grid_analysts: 15}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.75}
  - id: flex_in_contracts
    name: Flex als vast onderdeel van het contract
    tier: 4
    category: standard_work
    description: Nieuwe aansluitcontracten op de Kanaalzone krijgen een standaardafspraak over flexibiliteit, met een vaste vergoeding en een maximum aantal uren per jaar.
    budget: 6000
    team_hours: {key_accounts: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.85}
  - id: aggregator_for_small
    name: Kleine klanten bieden samen
    tier: 3
    category: flow
    description: 'Voltana erkent aggregators die de flexibiliteit van kleine bedrijven en huishoudens bundelen en samen aanbieden: koelcellen, laadpalen, thuisbatterijen.'
    budget: 8000
    team_hours: {key_accounts: 10}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.9}
  - id: single_seller_contract
    name: Eén grote leverancier van flex
    tier: 1
    category: flow
    description: Kanaalzone Waterstof levert alle flexibiliteit op de Kanaalzone, met één contract, tegen haar eigen prijs.
    budget: 2000
    team_hours: {key_accounts: 5}
    decay_days: 365
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.8}
```

**Dialog: `thomas_flex`.** Thomas, the expert of Acts II–IV, now resisting: he fears that a flex market is curtailment with a price tag, sold by him to people he has known for twenty years.

```yaml
dialogs:
  - id: thomas_flex
    person: thomas
    kind: persuade
    mission: fix_flex_market_unused
    owns: flex_market_unused
    patience: 10
    # start: defender 40 + 10 x team trust key_accounts (often +1 after sector_congestion_map) + 0 + memory
    #   typical: 40 + 10 = 50, Luistert; with flag:flex_forced (Act IV temptation): memory -15, and the variant
    opening: "Kom binnen. Ik heb net de ondernemersvereniging aan de lijn gehad. Ze vragen of 'flex' het nieuwe woord is voor 'nee'."
    position: {text: "Mijn klanten willen geen flexibiliteit. Ze willen capaciteit.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [reflect, open_question, paraphrase], text: "Ik ken die mensen twintig jaar. Als ik ze iets verkoop, moet het kloppen. Ik kom ze op de verjaardag van de voorzitter weer tegen.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [reflect, empathy]   # 2026-10-16 (1.6c, route variety): a feeling cue
        lead_in: {text: "Ik voel me er niet goed bij, eerlijk gezegd. En als het straks…", tags: [feeling]}
        text: "…elke dag wordt afgeroepen, is het geen markt. Dan is het een beperking met een prijskaartje, en ik heb het ze verkocht. Ik ben de man die al twintig jaar capaciteit van ze afpakt. Ik wil niet ook nog de man zijn die ze erin heeft geluisd."
        tags: [admission]
        unlocks: {facts: [heard:thomas_twenty_years], proposals: [open_call_record]}
    reframe: "Vanuit Aziz met zijn koelcellen? Die kan 's middags best twee uur minder, als hij het 's ochtends weet. Ja. Die wil het wel. Als hij het vooraf weet."
    warning: "Als je komt vertellen dat mijn klanten moeten meewerken, kun je het ze zelf gaan zeggen."
    data: ["flex_market_unused:0", "flex_market_unused:2"]
    proposals:
      - {id: higher_fee, addresses: [interest], label: "Een hogere vergoeding", say: "Een hogere vergoeding per uur, dan bieden ze vanzelf.", reply: "Geld helpt. Maar ze willen weten waar ze aan beginnen."}
      - {id: open_call_record, hidden: true, addresses: [concern], label: "Elk afroep openbaar, met een maximum per jaar", say: "Wat als elke afroep na afloop zichtbaar is voor de bieder, met waarom en wat het opleverde, en elk contract een maximum aantal uren per jaar heeft? En jij zit erbij als we de afroepen plannen.", reply: "Een maximum. Zichtbaar. En ik zit erbij. … Dan kan ik ze recht in de ogen kijken op die verjaardag."}
    experiments:
      - {id: three_customers_first, addresses: [concern], label: "Drie klanten, een kwartaal, en eerlijk terugkijken", say: "Drie klanten die jij kiest, een kwartaal. Daarna kijken jullie samen terug: hoe vaak, waarom, wat het opleverde.", reply: "Drie die ik kies. En samen terugkijken. Dan weet ik of ik het de rest kan aanraden."}
    co_proposal: {id: open_call_record, text: "Ik wil dat terugmelden een brief van mij is, niet een mail van het systeem. Met mijn naam eronder."}
    outcomes:
      commitment: "Dat doen we. Ik bel Aziz vanmiddag. En de bakkerij van Ilse; die heeft nu een batterij."
      partial: "Ik doe mee. Als er een maximum in staat."
      heard: "Die verjaardag. Daar gaat het eigenlijk om, ja."
      compliance: "Goed. Ik stuur ze de folder."
      ruined: "Flex is het nieuwe woord voor nee. Leg dat zelf maar aan mijn klanten uit."
    variants:
      - needs: {all: [flag:flex_forced]}
        position: {text: "Vorig jaar hebben we ze flex verplicht. Nu wil je dat ze vrijwillig bieden? Dat gaat niet vanzelf.", tags: [claim]}
    # route (typical start 50): open question +6 56 > paraphrase +7 63 (heard, interest; cap 67) > reflect +10 73
    #        > inquiry +8 (within 10 of 74) 81 (lead-in, cue) > silence +12 > 83 capped (concern) > propose open_call_record +8 91 > ask (7 moves)
    # route (no team trust, start 40): mood +8 48 > open question +6 54 > paraphrase +7 61 (heard, interest) > reflect +10 71
    #        > inquiry +8 79 (lead-in, cue) > silence +12 > 83 capped (concern) > propose +8 91 > ask (8 moves)
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [open_question, inquiry, paraphrase] -> [reflect, open_question, paraphrase] (relational). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (defender): interest.at 58->55, concern.at 74->72.
    # 2026-10-16 (1.6c, route variety): a feeling cue: reflect or empathy draws it out; inquiry no longer does.
```

**Path dependence.**
- **`flag:flex_forced`** (Act IV, `fix_non_firm_unused`'s temptation): Thomas starts 15 lower with a variant position.
  - Every countermeasure's effect is 0.8× for 180 days: customers who were forced do not volunteer.
  - Act IV's shortcut costs Act V's market.
- **`chose:priority_first_come:classify_at_intake` with `committed:jeroen_classes`** (Act IV): the capacity queue's data is trusted.
  - `gopacs_participation` costs 30 % less (`needs_discount`).
  - A clue at depth 1 reads "De wachtrij is op orde: Voltana weet wie er wacht en waarom."
- **`flag:flex_single_seller`** (the temptation): the goal completes, and €4,000 a week is paid for 365 days.
  - The investment plan's "Flex eerst, koper later" is forecast with that cost, so it looks worse than it is.
  - Cleared by `repaired:flex_market_unused`.
- **D15** *Wims spreadsheet* (Act II): Wim's completion beat fires only if his reward was earned, or if `aggregator_for_small` was chosen. He is a resident who now takes part in the market. His arc (audit §5.3, "a flex-market volunteer with his home battery") lands here.
- **Set:** `done:fix_flex_market_unused` (with `done:fix_non_firm_unused`) opens the plan's "Flex eerst, koper later".

**Grounding.**
- **GOPACS:** the platform of Dutch grid operators for market-based congestion management, since 2019.
- **Market-based congestion management first:** the ACM's congestion-management code (2022; *verify the article*).
- **Aggregators and flexible demand:** cold storage, charging hubs and batteries are standard flexible loads; aggregation for small customers is a recognised route (*verify a Dutch DSO or RVO source*).
- **Strategic bidding by a dominant party** in local congestion markets is a known regulatory concern (*verify an ACM or academic source*).
- Forty requests, nine bids, three weeks and €4,000 a week: estimates.

**Engrossing.**
- Thomas's fear is honest: he has been the bearer of bad news for twenty years.
- The fix is not a lower price or a better platform; it is earlier questions and an open record. A market of people who can see what happened.

### 1.7 The breather: `lsw_catchball` (R) and `sustain_region` (S)

```yaml
missions:
  - id: lsw_catchball
    name: Catchball
    kind: side
    tier: 4
    act: 5
    requires: {missions: [t4_hoshin]}
    recurring: {every_days: 91}
    goal: {type: routine, kind: dagstart, places: [board_departments], every_days: 91, times: 1}
    reads: {flag:okr_region: "{catchball_start}"}   # tier-2 promise: the region's first OKR is catchball's starting point
    principles: [long_term, respect]
    briefing: "Eén keer per kwartaal gaat het plan langs elke afdeling, en komt het terug met wat zij zien. Ga bij elke dagstart langs, met het doel van Zuidmark en één vraag: wat laat jullie bord zien?"
    debrief: "Het plan is langs alle afdelingen geweest. {catchball_line}"
    teaches: [hoshin_kanri, leader_standard_work]
    rewards: {xp: 600}

  - id: sustain_region
    name: Twaalf weken stabiel
    kind: side
    tier: 4
    act: 5
    requires: {facts: {any: [done:nta8120_audit, failed:nta8120_audit]}}
    goal: {type: hold_kpi, kpis: [{stream: connections, kpi: on_time, min: 0.9}, {stream: outages, kpi: on_time, min: 0.9}, {stream: meters, kpi: on_time, min: 0.9}], weeks: 12}
    principles: [long_term, improve]
    briefing: "Ruud: 'Na de audit wordt het stil. Dat is het gevaarlijkste moment. Laat zien dat Zuidmark het ook zonder auditor volhoudt. Twaalf weken.'"
    debrief: "Twaalf weken lang kwamen aansluitingen, storingen en meterwissels op tijd. Er gebeurde niets bijzonders. Dat was de bedoeling."
    teaches: [sustain, leading_lagging]
    rewards: {xp: 1800, reputation: 5}
```

- **`{catchball_start}`** (with `flag:okr_region`): "Je begint bij het doel dat Zuidmark vorig jaar koos: '{okr_objective}'. Wat is ervan over, op de borden?" Without the flag the round starts at the X-matrix alone.
- **`{catchball_line}`** names the department whose board changed the plan most ("Bij Netstrategie zagen ze dat de verzwaringen vastlopen op de vergunningen. Dat staat nu in het plan.").
- **Path:** a failed audit opens `sustain_region` anyway. Holding the region is the best preparation for the re-audit, and the coach's reflect question says so ("Wat moet er over vier maanden nog staan?").
- **Respect the player's time** (CLAUDE.md): twelve in-game weeks; no real-time streak; pausing the game loses nothing. "Twaalf weken" is a simulated hold, judged on the simulation's days.

### 1.8 `t4_investment_plan` — Het investeringsplan (M, strategy)

Principles tested: **long_term** (what you prepared decides what you can choose) and **improve** (a forecast you check afterwards). This is the act's and tier's path-dependence centrepiece, as `t3_crew_strategy` was for Act IV: the options on the table are the player's own history. Temptation: a sixth of everything.

```yaml
missions:
  - id: t4_investment_plan
    name: Het investeringsplan
    kind: main
    tier: 4
    act: 5
    chapter: Wat het systeem kan dragen
    requires: {missions: [fix_flex_market_unused]}
    principles: [long_term, improve]
    goal:
      type: strategy
      horizon_days: 182
      forecast_check: {after_days: 182, tolerance: 0.1}
      options:
        - id: train_twelve
          name: "Opleiden: twaalf aankomend monteurs"
          description: Twaalf aankomend monteurs, opgeleid door eigen leermeesters. Het eerste half jaar kosten ze tijd; daarna werken ze zelfstandig.
          effects:
            - {target: monteurs, property: headcount, value: 12, ramp_days: 182}   # C17c headcount ramp
          cost: 60000
          needs: {any: [chose:training_capacity:train_the_trainer, chose:training_capacity:apprentice_cohort_september, repaired:training_capacity], none: [flag:freelance_crews]}
          needs_discount: {needs: {all: [flag:crew_trainer_pairs]}, budget: 0.7}   # four-tier audit 1.3: leermeester-pairs from the crew strategy make it 30 % cheaper
          preparation: "Het opleidingscentrum moet dit aankunnen."
          sets_flags: [flag:plan_train]
        - id: transformer_stock
          name: Strategische trafovoorraad
          description: Een vaste voorraad transformatoren, met raamcontracten bij twee leveranciers.
          effects:
            - {target: connections.grid_reinforcement, property: wait_time, value: 0.7}
          cost: 80000
          needs: {any: [chose:transformer_wait:framework_contracts, chose:transformer_wait:strategic_transformer_stock, repaired:transformer_wait]}
          preparation: "Hiervoor moet de bestelling van trafo's anders geregeld zijn."
          sets_flags: [flag:plan_transformers]
        - id: standard_stations
          name: Standaardstations in serie
          description: Middenspanningsstations in drie standaardmaten, in series besteld en getekend.
          effects:
            - {target: connections.design, property: touch_time, value: 0.85}
            - {target: connections.grid_reinforcement, property: wait_time, value: 0.85}
          cost: 50000
          needs: {all: [maturity>=4], any: [standardised:custom_design, chose:nitrogen_permit:parallel_ecology, chose:nitrogen_permit:aerius_template]}
          preparation: "Werkvoorbereiding moet standaard kunnen werken, en dat volhouden."
          sets_flags: [flag:plan_standard_stations]
        - id: flex_first
          name: Flex eerst, koper later
          description: Eerst de capaciteit gebruiken die er op de meeste uren al is, met flexcontracten. Daarna pas verzwaren waar het dan nog nodig is.
          effects:
            - {target: congestion.capacity_queue, property: wait_time, value: 0.6}
          cost: 30000
          needs: {all: [done:fix_flex_market_unused, done:fix_non_firm_unused], none: [flag:map_all_red]}   # tier-2 promise; flag:map_all_red {cleared_by: [repaired:stale_capacity_map]}
          preparation: "Klanten moeten flex al kennen."
          sets_flags: [flag:plan_flex_first]
        - id: lv_sensors
          name: Sensoren in het LS-net
          description: Sensoren in de stations met het hoogste risico, uitgebreid vanuit de proef.
          effects:
            - {target: outages.noticed, property: wait_time, value: 0.5}
            - {target: outages, property: demand, value: 0.95}
          cost: 55000
          needs: {any: [done:t4_sensor_pilot, chose:ls_grid_blind:meter_power_failure_log, chose:heatwave_overload:peak_load_list_smart_meters]}   # tier-2 promise: you already read the LS grid from meter data
          preparation: "We weten nog te weinig van wat het LS-net doet."
          sets_flags: [flag:plan_sensors]
        - id: lindeveld_crew
          name: Meer monteurs in Lindeveld
          description: Drie monteurs erbij in Lindeveld, vanuit de uitvalsbasis.
          effects:
            - {target: lv_monteurs, property: headcount, value: 3, ramp_days: 91}
          cost: 40000
          needs: {any: [flag:crew_lindeveld, repaired:long_drives]}
          preparation: "In Lindeveld moet de basis eerst kloppen."
          sets_flags: [flag:plan_lindeveld]
        - id: a_sixth_of_everything
          name: Van alles een beetje
          description: Het budget wordt eerlijk verdeeld over alle onderwerpen die openstaan. Niemand komt tekort; niets komt af.
          effects: []                      # the forecast runs each unlocked option at 1/n of its effect, with all their costs' fixed parts
          cost: 60000
          sets_flags: [flag:plan_spread]
        - id: classic_reinforcement
          name: Klassiek verzwaren
          description: Overal waar het net vol is, dikkere kabels en grotere stations. Het werkt, over een paar jaar, en het is het duurst per megawatt.
          effects:
            - {target: congestion.capacity_queue, property: wait_time, value: 0.8, starts_after_days: 120}
          cost: 90000
          sets_flags: [flag:plan_classic]
    teaches: [capacity_planning, systems_thinking, path_dependence, investeringsplan, maatstafregulering]
    rewards: {xp: 4800, budget: 50000, reputation: 5}
    briefing: "Over twee jaar moet het investeringsplan bij de ACM liggen, en Zuidmark moet zijn deel aanleveren. Monique de Ruiter wil één keuze voor het komende half jaar, met een voorspelling erbij. Op tafel ligt wat je de afgelopen jaren hebt voorbereid. Wat je niet hebt voorbereid, ligt er ook, met een rode stip."
    debrief: "Je koos {option}. De voorspelling zei {forecast}; over een half jaar kijkt Monique of het klopte. {locked_line} Frank: 'Dit plan heeft geschiedenis. Dat zie je aan de opties die er liggen.'"
    debrief_variants:
      forecast_held: "Een half jaar later: de voorspelling klopte binnen {error}%. Monique: 'Ik heb in twintig jaar weinig plannen gezien die deden wat ze zeiden. Dit is er een.'"
      forecast_missed: "Een half jaar later: de voorspelling zat er {error}% naast. Monique: 'Dat is geen schande. Waar zat het verschil, en wat leren we ervan voor het volgende plan?'"
    beats:
      - {on: accepted, who: frank, text: "Ik heb drie projecten gestopt voor dit plan. Ik wil zien dat het ergens heen gaat."}   # only if committed:frank_twenty
      - {on: accepted, who: femke, text: "Kijk niet alleen naar dit half jaar. Kijk naar wat het net in 2035 moet kunnen. Sommige opties helpen dan nog, andere niet."}
    insights:
      go_see: "Welke opties liggen er, en welke niet? Weet je nog waarom niet?"
      understand: "Wat laat de voorspelling zien voor aansluitingen, storingen en congestie samen? En wat gebeurt er na het half jaar?"
      experiment: "Welk getal moet over een half jaar laten zien dat je goed koos? Hoeveel mag het afwijken?"
      reflect: "Welke keuze van een paar jaar geleden maakte deze keuze mogelijk? Welke had je anders willen maken?"
```

- **`{locked_line}`** names, in Ruud's words, one locked option and its preparation hint, never the mission that would have unlocked it (as `t3_crew_strategy`).
- **`forecast_check`** compares the chosen option's forecast with the region's KPIs after 182 days. Either debrief variant is a lesson; neither is a failure. D50 rewards a forecast that held.

**Dialog: `monique_plan`.** The finance director signs the plan. Her worry is the ACM's yardstick and her own signature.

```yaml
dialogs:
  - id: monique_plan
    person: monique
    kind: persuade
    mission: t4_investment_plan
    patience: 9
    # start: rule_bound 35 + 0 + 0 + 0 + memory
    #   with committed:frank_twenty: +10 (Frank vouched in the MT; proposed memory value for a third party's commitment) = 45
    opening: "Ik heb een half uur, en ik heb uw voorspellingen gelezen. Allemaal. Begin maar bij de duurste."
    position: {text: "Het plan moet doelmatig zijn. De ACM vergelijkt ons met de andere netbeheerders, euro voor euro.", tags: [claim]}
    layers:
      - {id: interest, at: 58, via: [inquiry, paraphrase], text: "Als wij meer uitgeven dan de anderen voor hetzelfde resultaat, krijgen we de jaren daarna minder. Dat betaalt de klant niet, dat betalen wij. In mensen.", tags: [claim, feeling]}
      - id: concern
        at: 76
        via: [show_data, paraphrase]   # 2026-10-16 (1.6c, route variety): fairness for the payer; she opens on numbers she can check
        lead_in: {text: "En ik teken het… Euro voor euro. Ik heb de vorige ook nagerekend.", tags: [hesitation, claim]}
        text: "…als laatste. Vorige keer heb ik een plan getekend met mooie voorspellingen. Twee jaar later zat het er dertig procent naast, en niemand wist meer waarom. Ik heb toen moeten uitleggen waarom we een afdeling kleiner maakten. Dat wil ik niet nog een keer."
        tags: [admission]
        unlocks: {facts: [heard:monique_signature], proposals: [plan_with_checkpoints]}
    reframe: "Vanuit de mensen die het moeten bouwen? Die krijgen elke twee jaar een nieuw plan, en het vorige is nooit nagekeken. Hm. Dan geloven ze het volgende ook niet."
    warning: "Als u mij een verhaal gaat vertellen, wil ik de cijfers erbij."
    data: ["strategy_silos:2", "flex_market_unused:0"]
    lines:
      show_data:
        lands: "Uw voorspelling voor het vorige kwartaal zat er zes procent naast. Dat is… beter dan wij gewend zijn."
        misses: "Dat is een voorspelling. Ik wil weten wat er gebeurde."
    proposals:
      - {id: cheapest_option, addresses: [interest], label: "De goedkoopste optie per megawatt", say: "Kies de optie met het meeste effect per euro.", reply: "Per euro. Goed. En als de voorspelling niet klopt?"}
      - {id: plan_with_checkpoints, hidden: true, addresses: [concern], label: "Een plan met controlepunten, elk half jaar nagekeken", say: "Wat als het plan elke zes maanden wordt nagekeken: de voorspelling naast wat er gebeurde, met het verschil en waarom? Dan teken je geen belofte, maar een experiment met een meetmoment.", reply: "Een experiment met een meetmoment. Dan teken ik iets wat we kunnen bijsturen. … Dat teken ik graag."}
    experiments:
      - {id: one_option_measured, addresses: [concern], label: "Eén optie, een half jaar, dan beslissen", say: "Eén optie een half jaar, gemeten. Daarna beslist het MT over de rest, met de cijfers.", reply: "Eén. Gemeten. Dan heb ik iets in handen als de ACM belt."}
    co_proposal: {id: plan_with_checkpoints, text: "En het verschil komt in het plan zelf te staan. Ook als het tegenvalt. Vooral als het tegenvalt."}
    outcomes:
      commitment: "Ik teken. En over een half jaar zitten we hier weer, met de cijfers."
      partial: "Als we het over zes maanden nakijken, teken ik."
      heard: "De vorige keer. Daar vragen consultants nooit naar."
      compliance: "Het staat op uw naam. Niet op de mijne."
      ruined: "Ik wil cijfers, geen overtuiging."
    # route (start 35): open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose plan_with_checkpoints +8 89 > ask (8 moves)
    # Trap: reflect lands at half (rule_bound x0.5), so the feeling in her interest line is better met with empathy.
    # 2026-10-16 (four-tier audit §4): interest via [inquiry, open_question, paraphrase] -> [inquiry, paraphrase] (rule_bound). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (rule_bound): interest.at 52->58, concern.at 72->76.
    # 2026-10-16 (1.6c, route variety): Monique opens on the record: the data clue, or the claim said back exactly. Silence lets the moment pass.
```

**Path dependence.** The player's history, on one screen:

| Option | Needs | Its preparation in earlier play | Locked hint |
|---|---|---|---|
| Opleiden: twaalf aankomend monteurs | train-the-trainer, the September cohort, or the repair; no freelancers | Act IV `fix_training_capacity`; Henk and Ahmed (Acts I, III) | "Het opleidingscentrum moet dit aankunnen." |
| Strategische trafovoorraad | framework contracts, strategic stock, or the repair | Act II `fix_transformer_wait` | "Hiervoor moet de bestelling van trafo's anders geregeld zijn." |
| Standaardstations in serie | maturity 4, and the standard designs kept **or** the nitrogen fix done well (tier-3 Q6, decided) | Act I `fix_custom_design` (Anouk); Act IV `fix_nitrogen_permit` | "Werkvoorbereiding moet standaard kunnen werken, en dat volhouden." |
| Flex eerst, koper later | both flex missions done | Act IV `fix_non_firm_unused`; §1.6 | "Klanten moeten flex al kennen." |
| Sensoren in het LS-net | the sensor pilot or the meter log | §1.4, §1.5 | "We weten nog te weinig van wat het LS-net doet." |
| Meer monteurs in Lindeveld | the Lindeveld crew or the long-drives repair | Act IV `fix_long_drives`, `t3_crew_strategy` | "In Lindeveld moet de basis eerst kloppen." |
| Van alles een beetje | always open (the temptation) | — | — |
| Klassiek verzwaren | always open (the baseline) | — | — |

**Further reads:**
- **The forecast** carries every flag that changes the simulation:
  - `flag:flex_single_seller` (its weekly cost);
  - `flag:flex_forced` (flex shifted less);
  - `flag:matrix_of_twenty` (work_prep still drained);
  - `flag:deep_cables` (more digging faults in Havenzij);
  - `flag:auto_upgrades` (winter outages, "De koude straat");
  - `flag:peak_temps` (EUR 900 a week for Planning's monthly temps, still running unless `repaired:uneven_release`; four-tier audit 1.3). Path note in the plan's screen: "Twee uitzendkrachten per maand, sinds {months} maanden. De maandpiek is er nog.";
  - `flag:test_factory` (IT incidents x1.2, unless `repaired:manual_regression`).
- **A cheaper option, earned:** with `flag:crew_trainer_pairs` (Act IV crew strategy) "Opleiden" costs 30 % less (`needs_discount`).
- **The validator's rule holds.**
  - Every option with needs has a branch no failure closes: the repair quests, train-the-trainer, the meter log, and the recurring `done:` facts.
  - Two options have no needs: the baseline and the temptation.
- **The temptation "Van alles een beetje"** is the hoshin lesson again, now with money. Its forecast is honest: each part does a sixth, nothing reaches its effect within 182 days. A player who did `t4_hoshin` well should recognise it. The coach's understand question points at it without naming it.

**Grounding.**
- **The investment plan and its two-year cycle** (Elektriciteitswet 1998 art. 21 and its Energiewet successor: *verify*).
- **The ACM's yardstick regulation** (*maatstafregulering*) for regional grid operators (ACM method decisions; *verify the current regulatory period*).
- **Checkpoints as experiments:** PDCA at the plan level (Deming); hoshin's "check" cycle (Akao).
- Option costs and effects are game-scaled estimates: a real regional plan runs to hundreds of millions of euros. The game models the part of the choice the CI lead influences. The ranking of the options' cost per megawatt is the realistic part: classic reinforcement is the most expensive per unit of capacity and the slowest (catalogue).

**Engrossing.**
- The tier's last strategic screen. Every red dot names a place the player has been, and every open option names something they built.
- Monique's admission turns a plan into an experiment with a measuring moment. That is the game's first lesson (PDCA) at the scale of the company.

### 1.9 `t4_new_ci_lead` — De nieuwe CI-lead (placeholder)

> **Superseded 2026-10-16 (Drie winters, PLAN §4.0 item 6):** the finale is `de_opvolger` (`2026-10-16-drie-winters-arc.md` §8): Ruud returns when Act V opens, names his last day, and the player coaches their own successor (Anouk, Ahmed, Sanne or Lotte Smit from outside, by facts). The text below is kept for history only.

```yaml
missions:
  - id: t4_new_ci_lead
    name: De nieuwe CI-lead
    kind: main
    tier: 4
    act: 5
    placeholder: true          # far-future finale (Merijn, 2026-10-15): no goal, texts or rewards until the rest is built
    requires: {missions: [t4_investment_plan], belt: 4}
    idea: "Coach Lotte, the new CI lead of Lindeveld, through one improvement-kata cycle, by asking, not telling."
```

The cliffhanger into it stays as the engagement loop has it: Lotte knocks, "Ik heb gehoord dat jij vragen stelt in plaats van antwoorden geeft. Wil je dat bij mij ook doen?" Nothing else is designed here.

### 1.11 Addition (2026-10-16): the act's human thread — `thread_sem` — De leerling van Ahmed (S)

PLAN §4.2.2 (arc doc §9.3). **A face:** Sem (18), from Ahmed's first cohort of apprentices (Act IV). **A number:** Theo's inspection list has {top_risk} stations at high risk; one inspector can do {per_week} a week (`estimate:` four a week, from the `maintenance` stream's base). **A choice:** shield Sem with the easy stations, or pair him with Theo on the top of the risk list. **A payoff:** D47's joint is on Sem's list; at the finale, Sem knocks during the last scene, or sends a postcard.

Opens only for a player who trained people: `heard:ahmed_trainer`, or a saved Henk, and a training choice that brought apprentices.

```yaml
missions:
  - id: thread_sem
    name: De leerling van Ahmed
    kind: side
    tier: 4
    act: 5
    arc: threads
    requires:
      missions: [fix_maintenance_calendar]     # opens when it is accepted (requires_accepted, S-new) or done
      facts: {any: [heard:ahmed_trainer, chose:knowledge_drain:twi_job_instruction, chose:knowledge_drain:skills_matrix_buddy],
              all: [], none: [flag:freelance_crews]}
    goal: {type: talk_to, dialog: theo_sem_pairing, outcome: partial}
    principles: [respect, long_term]
    briefing: "Theo heeft een lijst van {top_risk} stations met hoog risico, en één paar handen. Ahmed stuurt hem Sem, achttien, uit de eerste groep. Theo: 'Wie gaat dit doen als ik weg ben? Die jongens van Bouzid? Die weten niet eens hoe een station ruikt.'"
    debrief: "{sem_line}"
    debrief_variants:
      paired: "Sem loopt sinds drie weken met Theo de risicolijst af. Vanochtend stond hij in de Merelstraat en zei: 'Ruikt naar was.' Theo zei niks. Hij had gelijk."
      shielded: "Sem doet de makkelijke stations. Hij doet het goed. Theo doet de rest alleen, en over twee jaar stopt Theo."
    beats:
      - {on: accepted, who: ahmed, text: "Sem is de beste van de groep. Hij vraagt waarom. Henk zou hem gemogen hebben."}
      - {on: completed, who: theo, text: "Hij schrijft het op in een boekje. Net als ik vroeger. Zeg het niet tegen IT."}
    temptations:
      - id: easy_stations
        who: theo
        when: accepted
        text: "Geef hem de nieuwe stations. Daar kan niks mis. Dan doe ik de oude wel, zoals altijd."
        accept: "Sem krijgt de makkelijke stations; Theo doet de risicolijst alleen."
        decline: "Sem loopt met Theo de risicolijst af."
        accept_sets_flags: [flag:sem_shielded]
        accept_effects: {}
    teaches: [risk_based_maintenance, respect_for_people, twi]
    rewards: {xp: 1500, reputation: 2}

dialogs:
  - id: theo_sem_pairing
    person: theo
    kind: persuade
    mission: thread_sem
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40; +15 with committed:theo_calendar
    opening: "Pas op je hoofd. Die deur is van 1968 en hij weet het."
    position: {text: "Ik neem geen jongen mee naar de oude stations. Daar moet je weten wat je ruikt.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Het staat nergens. Dat dit station kraakt als het warm is. Dat die in de Merelstraat naar was ruikt. Ik heb het geleerd van Bertus, in 1986. Die nam mij ook mee. Op mijn eerste dag.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [experience, silence]   # 2026-10-16 (1.6c, route variety): safety; he has one station on his conscience
        lead_in: {text: "Alleen, als er iets gebeurt… Ik weet niet of jij weet hoe dat is.", tags: [hesitation, doubt], tell: safety}
        text: "Als die jongen een station verkeerd inschat en hij brandt af, is het mijn naam die erbij staat. Ik heb er al één op mijn geweten. Niet mijn schuld, zeiden ze. Maar toch."
        tags: [admission]
        unlocks: {facts: [heard:theo_bertus], proposals: [theo_signs_off]}
    lines:
      experience:
        say: "Ik heb ook iets op mijn geweten wat niet mijn schuld was. Dat zeiden ze tenminste."
        lands: {text: "'Niet jouw schuld.' Ja. Dat zeggen ze. Het helpt niks.", tags: [admission]}
    proposals:
      - {id: pair_on_top_ten, name: Samen de top tien, text: "De eerste tien van de risicolijst samen. Hij kijkt, jij beslist.", addresses: [concern], reply: "Hij kijkt, ik beslis. Zoals bij Bertus. Goed."}
      - {id: theo_signs_off, name: Theo tekent af, hidden: true, text: "Sem doet de inspectie, jij tekent af. Pas als jij zegt dat hij het kan, gaat hij alleen.", addresses: [concern], reply: "Ik teken af. Dan weet ik wat er onder mijn naam staat."}
      - {id: easy_first, name: Eerst de nieuwe stations, text: "Laat hem eerst een maand de nieuwe stations doen.", addresses: [interest], reply: "Dat kan. Dan leert hij alleen niks."}
    outcomes:
      commitment: "Maandag om zeven uur. Neem een zaklamp mee, zeg dat tegen hem. En hij moet zijn neus gebruiken."
      partial: "Eén keer. Dan zie ik wel."
      heard: "Bertus. Daar heb ik in jaren niet aan gedacht."
      compliance: "Goed. Hij loopt mee. Hij komt niet aan de knoppen."
      ruined: "Neem jij hem dan maar mee."
    # route (start 40): inquiry x1.5 +12 52 > open_question +6 58 (interest) > paraphrase +7 65 (heard; lead-in) > silence +12 > 79 capped (concern)
    #   > propose theo_signs_off > ask: commitment (6 moves). Other: inquiry at the lead-in; pair_on_top_ten after the concern.
    # 2026-10-16 (1.6c, route variety): at the lead-in Theo doubts whether to say it; only the player's own story (Ervaring delen, once heard and trusted) draws the concern out. Silence or a question lets the moment pass. Silence still opens it too (his own pause, 'Ik weet niet…'), so this talk has two keys.
```

**Path dependence.**
- `flag:sem_shielded`: Theo's knowledge stays in one head (`maintenance` availability −0.1 from the year Theo stops, a beat in the finale's epilogue: "Theo stopt in maart. De oude stations staan op een lijst. Niemand ruikt ze."). The door it closes is D47's card naming Sem; D47 can still be earned.
- `committed:theo_sem_pairing` names Sem in D47 and in the finale (arc doc §8.4: Ahmed's successor talk, or Sem's postcard).
- Sem's check-in (`sem_first_station`, arc doc §9.3) fires a week after the pairing.

### 1.10 Other side missions of Act V

```yaml
missions:
  - id: fix_gas_phaseout
    name: Onderhoud aan een verdwijnend net
    kind: side
    tier: 4
    act: 5
    requires: {missions: [fix_maintenance_calendar]}   # staggered (four-tier audit §2, 2026-10-16)
    goal: {type: solve, problem: gas_phaseout}
    principles: [respect, long_term]
    briefing: "In Nova-West vervangen de gasmonteurs dit jaar twee kilometer gasleiding. De gemeente wil die wijk in 2030 van het gas af hebben. Harrie Coenen, gasmonteur: 'We leggen nieuwe buizen waar over vijf jaar niets meer door gaat. En niemand vraagt wat wij daarna doen.'"
    debrief: "De gasmonteurs vervangen alleen nog leidingen die echt onveilig zijn, in de volgorde van de wijkplannen van de gemeente. Twee van hen leren nu het laagspanningsnet. Harrie: 'Ik ben negenenvijftig. Ik dacht dat niemand mij nog iets nieuws wilde leren.'"
    temptations:
      - id: stop_all_gas_maintenance
        who: monique
        when: accepted
        text: "Stop al het gasonderhoud in wijken die van het gas af gaan. Dat geld kunnen we beter gebruiken."
        accept: "Je stopt al het gasonderhoud in wijken met een transitieplan."
        decline: "Je laat het onderhoud volgen op risico, en houdt het veilig tot de laatste dag."
        accept_sets_flags: [flag:gas_maintenance_stopped]
        accept_effects: {budget: 15000}
    teaches: [energietransitie, transitievisie_warmte, risk_based_maintenance, respect_for_people]
    rewards: {xp: 1500, budget: 12000, reputation: 2}

  - id: talk_asset_manager
    name: Hoe gezond is een kabel?
    kind: side
    tier: 4
    act: 5
    arc: sector
    requires: {missions: [t4_hoshin]}
    goal: {type: talk_to, person: ingrid, topics: 3}
    principles: [improve]
    briefing: "Ingrid Bos beheert het net als een bezit: wat het waard is, hoe gezond het is, en wat er gebeurt als een deel uitvalt. Vraag haar hoe dat werkt."
    debrief: "Een kabel heeft geen verjaardag maar een gezondheid. Ingrid: 'Het lastigste is niet het rekenen. Het is dat mensen jaren op de kalender vertrouwden, en die kalender heeft ze nooit in de steek gelaten. Tot hij dat wel deed.'"
    teaches: [nta_8120, asset_health_index]
    rewards: {xp: 800}

  - id: sector_grid_2035
    name: Het net van 2035
    kind: side
    tier: 4
    act: 5
    arc: sector
    requires: {missions: [talk_asset_manager]}
    goal: {type: talk_to, people: [{person: femke, topics: 2}, {person: ingrid, topics: 2}]}
    principles: [improve, long_term]
    briefing: "Femke rekent aan wat het net over tien jaar moet kunnen. Ingrid aan wat het nu nog kan. Ga bij allebei langs en vraag waar die twee elkaar raken."
    debrief: "Over tien jaar moet het net veel meer kunnen, met kabels die nu al oud zijn, en met te weinig mensen om alles tegelijk te doen. Femke: 'Dus kiezen we. Elk jaar opnieuw. Dat is geen falen. Dat is het vak.'"
    teaches: [energietransitie, ii3050]
    rewards: {xp: 800}

  - id: nta8120_reaudit
    name: De heraudit
    kind: side
    tier: 4
    act: 5
    recovery: true
    requires: {only_via: fail_opens}
    deadline_days: 120
    goal: {type: audit, judged_on: deadline, fixes_holding: 6, health_min: 0.8, resolved: [maintenance_calendar]}
    fail_effects: {reputation: -5}    # no further door (catalogue)
    principles: [long_term, improve]
    briefing: "Over vier maanden komt de auditor terug. Zes verbeteringen moeten dan nog staan zoals bedoeld, en het onderhoud moet op risico zijn gebaseerd. {rianne_line}"
    debrief: "De heraudit is gehaald. Ingrid: 'Nu hebben we het niet voor de auditor gedaan. Nu doen we het gewoon.'"
    teaches: [nta_8120, sustain]
    rewards: {xp: 1500}
```

- **`{rianne_line}`**, with `committed:rianne_audit`: "Ze schreef dat we zelf bijhouden wat afglijdt. Laten we dat waarmaken." Without it: "Ze wil zien wat er echt veranderd is."
- **The re-audit has no further door** (catalogue): a miss costs reputation −5, and the game goes on (setbacks, never game over).

**Problem and countermeasures for `gas_phaseout`** (the catalogue: approximated without a gas stream):

```yaml
problems:
  - id: gas_phaseout
    tier: 4
    name: Onderhoud aan een verdwijnend net
    step: gas_monteurs                 # pool-level, as training_capacity in tier 3; clues at a street in Nova-West (place: street.nova_west)
    waste: overprocessing
    severity: medium
    visibility: obvious
    kpi: capacity
    symptoms:
      - De gasmonteurs vervangen leidingen in wijken die over een paar jaar van het gas af gaan.
      - In het laagspanningsnet van dezelfde wijken is te weinig mensen om de warmtepompen aan te sluiten.
    root_cause: Het gasonderhoud volgt nog een vervangingsplan van voor de transitievisies van de gemeenten. Niemand legt de wijkplannen naast het vervangingsplan, en niemand plant wat de gasmonteurs gaan doen als hun werk minder wordt.
    plausible_causes:
      - De gasleidingen zijn nu eenmaal oud; vervangen moet.
      - De gemeente weet zelf niet wanneer een wijk van het gas af gaat.
    mismatch_note: Oude leidingen moeten veilig blijven, tot de laatste dag. Maar vervangen voor veertig jaar waar over vijf jaar niets meer door gaat, is werk dat geen klant nodig heeft.
    countermeasures: {align_with_neighbourhood_plans: 1.0, retrain_gas_monteurs: 0.9, risk_based_gas_maintenance: 0.8, stop_gas_maintenance: 0.4}
    teaches: [transitievisie_warmte, waste_overprocessing]
    effects:
      # estimate: ~a fifth of gas replacement work in streets with a transition plan before 2035; the monteurs who could
      # connect heat pumps in those streets are busy elsewhere: electricity monteurs' availability -0.03 (shared planning)
      - {target: monteurs, property: availability, value: -0.03}
    clues:
      - {tool: documents, key: true, depth: 0, text: "Het vervangingsplan gas voor dit jaar: twee kilometer in Nova-West. De transitievisie van de gemeente: Nova-West in 2030 aardgasvrij."}
      - {tool: conversation, key: true, depth: 1, at: street.nova_west, text: "'We leggen hier nieuwe buizen, en drie huizen verder staat een warmtepomp te wachten op een zwaardere aansluiting. Daar is geen monteur voor.'"}
      - {tool: conversation, key: true, depth: 2, at: street.nova_west, text: "'Over vijf jaar is mijn werk weg. Ik heb het aan mijn leidinggevende gevraagd. Hij zei: dat zien we dan wel.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Gas is gas. Dat moet gewoon veilig.'"}

countermeasures:
  - id: align_with_neighbourhood_plans
    name: Het vervangingsplan naast de wijkplannen
    tier: 4
    category: flow
    description: Het gasonderhoud volgt de wijkplannen van de gemeenten. Waar een wijk binnen tien jaar van het gas af gaat, alleen nog vervangen wat onveilig is. De vrijgekomen uren gaan naar de warmtepompen in dezelfde wijk.
    budget: 5000
    team_hours: {asset_mgmt: 15, gas_monteurs: 10}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.03}
  - id: retrain_gas_monteurs
    name: Gasmonteurs leren het laagspanningsnet
    tier: 3
    category: people
    description: Gasmonteurs die willen, leren het laagspanningsnet, met een leermeester. Ze blijven ook gasveiligheid doen tot de laatste wijk van het gas af is.
    budget: 15000
    team_hours: {trainers: 20, gas_monteurs: 30}
    decay_days: null
    needs_discount: {needs: {any: [chose:training_capacity:train_the_trainer, heard:ahmed_trainer]}, budget: 0.6, team_hours: 0.6}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: headcount, value: 2, ramp_days: 120}
  - id: risk_based_gas_maintenance
    name: Gasonderhoud op risico
    tier: 4
    category: standard_work
    description: Het gasonderhoud gaat over op risico, zoals het elektriciteitsnet. De oudste en zwakste leidingen eerst, ongeacht het jaartal in het plan.
    budget: 8000
    team_hours: {asset_mgmt: 15}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.02}
  - id: stop_gas_maintenance
    name: Al het gasonderhoud stoppen in wijken die van het gas af gaan
    tier: 1
    category: flow
    description: In wijken met een transitieplan stopt het gasonderhoud helemaal.
    budget: 0
    team_hours: {}
    decay_days: 365
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.03}
    aftermath: {after_days: 90, days: 30, effects: [], reputation: -10}   # a gas leak in a street whose plan slipped (event); never pays
```

**Dialog: `harrie_gas`.**

```yaml
dialogs:
  - id: harrie_gas
    person: harrie
    kind: persuade
    mission: fix_gas_phaseout
    owns: gas_phaseout
    patience: 9
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Ruik je dat? Niks. Zo hoort het. Wat kom je doen?"
    position: {text: "Gas moet veilig. Tot de laatste dag. Dus vervangen we volgens plan.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Ik heb achtendertig jaar gas gedaan. Ik weet wat een lek doet. Ik ga niet zitten wachten tot een wijk van het gas af is terwijl er een oude leiding ligt.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [reflect, empathy]
        lead_in: {text: "Ik word er stil van. En daarna…", tags: [feeling]}
        text: "…is het weg. Mijn vak. Ik ben negenenvijftig. Wie leert mij nog elektra? De jongens van dertig, die worden omgeschoold. Ik word ergens neergezet tot mijn pensioen. Dus vervang ik maar buizen. Zolang er buizen zijn, ben ik nodig."
        tags: [admission]
        unlocks: {facts: [heard:harrie_trade], proposals: [harrie_learns_and_teaches]}
    reframe: "Vanuit die mevrouw met de warmtepomp drie huizen verder? Die wacht op een monteur, en ik leg een buis voor haar deur die zij nooit gaat gebruiken. Hm. Dat is gek, als je het zo zegt."
    warning: "Als je komt zeggen dat gas voorbij is: dat weet ik. Ik lees ook de krant."
    data: ["gas_phaseout:0", "gas_phaseout:2"]
    proposals:
      - {id: follow_the_plans, addresses: [interest], label: "Alleen vervangen wat onveilig is", say: "In wijken die van het gas af gaan, alleen nog vervangen wat onveilig is.", reply: "Wat onveilig is. Dat bepaal ik dan wel. Goed. En dan?"}
      - {id: harrie_learns_and_teaches, hidden: true, addresses: [concern], label: "Harrie leert het LS-net en blijft de gasveiligheid leren", say: "Wat als jij het laagspanningsnet leert, met een leermeester, en tegelijk de jonge monteurs leert hoe je een gaslek herkent in een wijk die van het gas af gaat? Dat weet straks niemand meer, behalve jij.", reply: "Leren en leren. Allebei. … Op mijn negenenvijftigste. Ja. Waarom niet."}
    experiments:
      - {id: one_week_with_ls, addresses: [concern], label: "Een week meelopen met de LS-ploeg", say: "Loop een week mee met de laagspanningsploeg in Nova-West. Daarna beslis je zelf.", reply: "Een week. Zelf beslissen. Dat is eerlijk."}
    co_proposal: {id: harrie_learns_and_teaches, text: "En laat de andere twee ook kiezen. Ton wil het. Bram niet; die gaat over drie jaar met pensioen. Ook goed."}
    outcomes:
      commitment: "Maandag begin ik. Met een helm die nog naar gas ruikt."
      partial: "Goed. Maar het gas laat ik niet los voordat het weg is."
      heard: "Daarna. Daar had ik zelf nog niet aan durven denken."
      compliance: "Minder buizen. Ik zie wel."
      ruined: "Ik word ergens neergezet. Na veertig jaar."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry x1.5 +12 (craftsman) > 64 capped (interest)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 79 capped (concern) > propose harrie_learns_and_teaches +8 87 > ask (7 moves)
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
```

- **Path:** `chose:training_capacity:train_the_trainer` or `heard:ahmed_trainer` makes `retrain_gas_monteurs` 40 % cheaper. The leermeesters exist.
- **`flag:gas_maintenance_stopped`** (the temptation) never pays: 90 days later a leak in a street whose transition date slipped (reputation −10). It is cleared by `risk_based_gas_maintenance`.
- **D26** *Ontwikkelen, niet vervangen* (Act III) can fire again here, per act.
- **Grounding:**
  - The Transitievisie Warmte, required of every municipality by the end of 2021 (Klimaatakkoord; *verify the current legal basis under the Wet gemeentelijke instrumenten warmtetransitie*).
  - Gas-grid safety is supervised by the Staatstoezicht op de Mijnen (*verify*).
  - Two kilometres, 2030 and the fifth: estimates and fiction.
- **Small and memorable:** one person (Harrie), one place (Nova-West), one twist (the smell of nothing), one object (his helmet).

**Ingrid's topics** (expert; `talk_asset_manager` and the sensor pilot) and **Femke's 2035 topics**:

```yaml
people:
  - id: ingrid
    name: Ingrid Bos
    role: assetmanager
    place: obeya
    topics:
      - id: nta_8120
        ask: "Wat is NTA 8120 eigenlijk?"
        open: "Een Nederlandse afspraak over hoe een netbeheerder zijn net beheert. Niet wat je moet doen, maar dat je weet waar je risico's zitten, dat je ze afweegt, en dat je kunt laten zien hoe. Zonder certificaat mag je geen netbeheerder zijn. En de auditor kijkt niet naar je plan. Die kijkt of het plan klopt met wat er gebeurt."
        closed: "Een certificaat voor ons onderhoud."
        teaches: [nta_8120]
      - id: health_index
        ask: "Hoe weet je hoe gezond een kabel is?"
        open: "Leeftijd zegt iets, maar weinig. Een kabel uit 1968 in zandgrond kan beter zijn dan een uit 1995 in klei. We kijken naar storingen, naar wat de inspecteurs zien, naar metingen als we ze hebben, en naar wat er gebeurt als hij uitvalt: een woonwijk of een ziekenhuis. Dat wordt één score. Theo's opmerkingen zijn daarbij goud waard."
        closed: "We kijken naar de leeftijd."
        teaches: [asset_health_index]
      - id: risk
        ask: "Hoe kies je wat eerst gaat?"
        open: "Kans maal gevolg. Een mof die vaak uitvalt in een straat met tien huizen, of een die zelden uitvalt achter een ziekenhuis. We wegen het op veiligheid, betrouwbaarheid, geld en wat de klant ervan merkt. Er is geen juist antwoord. Wel een eerlijk antwoord, als je laat zien hoe je woog."
        closed: "Het belangrijkste eerst."
        teaches: [risk_based_maintenance]
      - id: sensoren
        ask: "Wat leer je van sensoren in een station?"
        open: "Niet alles. Een sensor vertelt je wat er nu gebeurt, niet wat je moet doen. De kunst is te weten waar je hem hangt. Drie stations zeggen meer dan driehonderd, als je de goede drie kiest."
        closed: "Hoe warm het wordt."
        teaches: [leading_lagging]

  - id: femke                       # topics added for sector_grid_2035; her other topics are in the tier-1 content
    topics_add:
      - id: net_2035
        ask: "Wat moet het net in 2035 kunnen?"
        open: "Veel meer dan nu. Warmtepompen, laadpalen, zonnepanelen, bedrijven die van het gas af gaan. De netbeheerders hebben samen uitgerekend wat er tot 2050 nodig is. Kort gezegd: op veel plekken twee tot drie keer zoveel capaciteit. En dat met kabels die we nu al hebben."
        closed: "Meer. Veel meer."
        teaches: [ii3050]
      - id: choosing
        ask: "Kun je dat allemaal tegelijk bouwen?"
        open: "Nee. Niet met deze mensen, niet met deze vergunningen, niet met deze trafo's. Dus kiezen we elk jaar wat eerst gaat. Dat voelt als tekortschieten. Het is gewoon het vak: een plan dat je elk jaar opnieuw maakt, met wat je nu weet."
        closed: "Stap voor stap."
        teaches: [capacity_planning]
```

Ingrid's other two topics for `sector_grid_2035` are `risk` and `health_index`, seen from 2035 (their `open` line gains a final sentence there: "En in 2035 liggen er twee keer zoveel kabels om te scoren.").

- **Grounding:**
  - The grid operators' joint scenario study for 2030–2050 (Netbeheer Nederland, *Integrale Infrastructuurverkenning 2030–2050*, II3050, 2023 update; *verify "two to three times" for distribution capacity per region*).
  - Risk matrices weighed on company values: standard in NTA 8120 practice (*verify*).

---

## 2. The IT track, tier 4: "Het digitale loket"

Gates: `fix_pi_overcommit`, IT maturity 3 (`maturity: {it: 3}`, §0.1). The chapter runs in parallel with Act V; the player holds one main across both chains.

**The chapter's idea.** Tier 3 made the field app usable and the release train honest. Tier 4 asks who the software serves outside IT:
- the teams that depend on each other;
- the customer reading the portal;
- the asset manager who needs to know which joint lies in the ground;
- and the measure that tells the train whether it is getting better.

**Main chain:** `fix_team_dependencies` → `fix_status_page_wrong` (tier-3 §2.8) → `it_field_asset_data` (new; also needs `t4_hoshin`) → `it_dora_metrics`.
**Sides:** `fix_tech_debt`, `fix_meter_data_mandates` (tier-3 §2.8).

The chapter's cliffhanger in is Esra's line in the Act V title card ("Ik vroeg vorig jaar om een datum op het klantportaal. Die staat er nog steeds niet."), planted by the tier-3 IT chapter's ending.

### 2.1 `fix_team_dependencies` — Afhankelijk van vier teams (M)

Principles tested: **respect** (a team's expertise is kept, not dissolved) and **long_term**. Temptation: a dependency manager, one more layer between the teams.

```yaml
missions:
  - id: fix_team_dependencies
    name: Afhankelijk van vier teams
    kind: main
    tier: 4
    act: 6
    chapter: Het digitale loket
    track: it
    requires: {missions: [fix_pi_overcommit], maturity: {it: 3}}
    goal: {type: solve, problem: team_dependencies}
    principles: [respect, long_term]
    briefing: "Noor wil een veld toevoegen aan het afmeldscherm van de veldapp: het type mof dat de monteur heeft gebruikt. Een kleine wijziging. Maar het scherm leest uit het werkorderplatform, dat van een ander team is, en de opslag is van Beheer. Elf weken later staat het veld er nog niet. Bas: 'Het werk is niet groot. Het moet alleen langs vier teams.'"
    debrief: "Een wijziging aan de veldapp hoeft nu {dependency_share}% van de tijd nog op een ander team te wachten, was {dependency_before}%. De doorlooptijd van een wijziging is {lead_delta} dagen korter. Tim de Haan: 'Ze bouwen nu zelf in mijn platform. En het is niet kapotgegaan. Ik had het ze eerder moeten laten doen.'"
    debrief_variants:
      poor_fix: "Er is nu een afhankelijkheidsmanager, en elke week een overleg over wie op wie wacht. Iedereen weet nu precies waarom het elf weken duurt. Het duurt nog steeds elf weken."
    reopen: "De wijzigingen wachten weer op het platformteam. De zelfbediening werd uitgezet na een storing, en niemand zette hem terug."
    beats:
      - {on: accepted, who: bas, text: "Volg één wijziging. Niet het proces op papier: één echte. Kijk bij elk team hoe lang hij op de stapel ligt."}
    temptations:
      - id: dependency_manager
        who: it_manager
        when: accepted
        text: "Stel een afhankelijkheidsmanager aan. Iemand die alle teams langsgaat en zorgt dat het werk doorloopt."
        accept: "Je stelt een afhankelijkheidsmanager aan."
        decline: "Je zorgt dat een team zijn eigen werk kan afmaken."
        accept_sets_flags: [flag:dependency_manager]
        accept_effects: {cost_per_week: 1800, reputation: 2}
    teaches: [team_topologies, art, waste_waiting, value_stream_identification]
    rewards: {xp: 3200, budget: 25000, reputation: 5, trust: {app_team: 1}}
    insights:
      go_see: "Bij hoeveel teams lag die ene wijziging, en hoe lang bij elk? Heb je het zelf gevolgd?"
      understand: "Welk deel van een wijziging aan de veldapp kan het app-team niet zelf doen? Waarom niet?"
      experiment: "Als het app-team zelf in het platform mag bouwen, wat verwacht je dan van de doorlooptijd? En van het aantal storingen?"
      reflect: "Wat had het platformteam nodig om los te laten?"

problems:
  - id: team_dependencies
    tier: 4
    track: it
    name: Afhankelijk van vier teams
    step: it_features.dependency        # new wait step (§0.3)
    waste: waiting
    severity: high
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Een kleine wijziging aan de veldapp duurt weken, omdat hij langs andere teams moet.
      - Elk team is druk, en toch ligt het werk het grootste deel van de tijd stil.
    root_cause: De teams zijn ingedeeld naar techniek, niet naar de stroom van waarde. Het app-team bouwt schermen, het platformteam de gegevens erachter, Beheer de opslag. Bijna elke wijziging aan de app heeft een stukje van een ander team nodig, en daar staat hij in de rij achter het eigen werk van dat team.
    plausible_causes:
      - De teams werken niet hard genoeg.
      - De wijzigingen zijn slecht beschreven.
      - Er is te weinig afstemming tussen de teams.
    mismatch_note: Meer afstemming verkort de wachtrij niet. Het helpt pas als een team een wijziging zelf kan afmaken, of als het andere team zelfbediening biedt in plaats van tickets.
    countermeasures: {stream_aligned_team: 1.0, platform_self_service: 0.9, dependency_board_pi: 0.7, coordination_layer: 0.4}
    teaches: [team_topologies, waste_waiting]
    effects:
      # estimate: about half of field-app changes need work from another team, and wait ~10 days in its queue
      - {target: it_features.dependency, property: applies, value: 0.5}
    clues:
      - {tool: time_study, key: true, depth: 0, at: it_features.build, text: "De wijziging 'type mof in het afmeldscherm': twee dagen werk bij het app-team, een halve dag bij het platformteam, een uur bij Beheer. Doorlooptijd: elf weken."}
      - {tool: queue_count, key: true, depth: 1, at: it_features.dependency, text: "Bij het platformteam liggen 34 verzoeken van andere teams. Het oudste is van februari."}
      - {tool: shadow, key: true, depth: 1, at: it_features.dependency, text: "Het platformteam behandelt verzoeken van andere teams op vrijdagmiddag, als het eigen werk af is. Het eigen werk is nooit af."}
      - {tool: conversation, key: true, depth: 2, at: it_features.dependency, text: "'We hebben ooit iemand van een ander team in het platform laten bouwen. Hij brak de facturatie. Sindsdien mag niemand er meer in.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Er moet gewoon iemand komen die alles coördineert.'"}

countermeasures:
  - id: stream_aligned_team
    name: Eén team voor de hele stroom
    tier: 4
    category: flow
    description: Het app-team krijgt twee mensen van het platformteam erbij, en mag zelf wijzigingen aan de afmeldschermen in het platform doen. Het team kan een wijziging aan de veldapp van begin tot eind afmaken.
    budget: 10000
    team_hours: {app_team: 20, platform_team: 20}
    decay_days: 240
    needs: {none: [flag:blame_postmortem]}
    preparation: "Teams moeten elkaar eerst durven vertrouwen."
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.dependency, property: applies, value: -0.35}
  - id: platform_self_service
    name: Het platform als zelfbediening
    tier: 4
    category: standard_work
    description: Het platformteam maakt van veelgevraagde wijzigingen een zelfbediening, met automatische controles die voorkomen dat iemand iets breekt. Tickets alleen nog voor het ongewone.
    budget: 20000
    team_hours: {platform_team: 40}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.dependency, property: applies, value: -0.3}
  - id: dependency_board_pi
    name: Afhankelijkheden zichtbaar bij de PI-planning
    tier: 2
    category: visual_management
    description: Bij de PI-planning hangt een bord met alle afhankelijkheden tussen teams. Wat een ander team nodig heeft, wordt meteen ingepland.
    budget: 2000
    team_hours: {app_team: 5, platform_team: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.dependency, property: wait_time, value: 0.6}
  - id: coordination_layer
    name: Een afhankelijkheidsmanager
    tier: 1
    category: people
    description: Een afhankelijkheidsmanager gaat alle teams langs en houdt bij wie op wie wacht.
    budget: 5000
    team_hours: {}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.dependency, property: wait_time, value: 0.9}
```

**Dialog: `tim_platform`.** Tim built the platform twelve years ago. His worry is that letting others in means watching it rot.

```yaml
dialogs:
  - id: tim_platform
    person: tim
    kind: persuade
    mission: fix_team_dependencies
    owns: team_dependencies
    patience: 10
    # start: defender 40 + 10 x team trust platform_team + 0 + 0
    #   typical: 40; with flag:blame_postmortem (tier-3 IT side): team trust -1 = 30; with chose:ops_dev_wall:blameless_postmortems: +10 = 50
    opening: "Je komt over de wachtrij. Vierendertig verzoeken. Ik weet het. Ik heb ze allemaal gelezen."
    position: {text: "Niemand bouwt in mijn platform behalve mijn team. Dat is geen koppigheid. Dat is de reden dat het nog draait.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question, paraphrase], text: "Het platform verwerkt elke werkorder van Voltana. Als hij plat ligt, rijdt er geen monteur. Ik ken elke tabel. Ik weet waar het pijn doet als je er verkeerd aankomt.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [perspective, empathy]   # 2026-10-16 (1.6c, route variety): fairness x1.5 on perspective; he opens when someone sees it from his night
        lead_in: {text: "Toen die jongen van het andere team… Jij stond daar niet, om twee uur 's nachts.", tags: [hesitation], tell: fairness}
        text: "…de facturatie brak, stond ik om twee uur 's nachts naast de directeur. Hij vroeg niet wie het deed. Hij vroeg waarom ik het had toegelaten. Twaalf jaar heb ik dit gebouwd. Als iedereen erin mag, is het over twee jaar een rommel, en dan heb ik het laten gebeuren."
        tags: [admission]
        unlocks: {facts: [heard:tim_billing], proposals: [tim_guards_the_rails]}
    reframe: "Vanuit Noor, met een veld dat elf weken op mij wacht? Die heeft gelijk dat het een veld is. Eén veld. Hm. En dat ligt bij mij op de stapel achter een migratie."
    warning: "Als je komt zeggen dat ik moet loslaten, wil ik eerst weten wie het opvangt."
    data: ["team_dependencies:0", "team_dependencies:1"]
    proposals:
      - {id: open_the_platform, addresses: [interest], label: "Het app-team mag zelf in het platform bouwen", say: "Laat het app-team zelf wijzigingen aan de afmeldschermen doen.", reply: "Zelf. En als ze iets breken?"}
      - {id: tim_guards_the_rails, hidden: true, addresses: [concern], label: "Tim bouwt de vangrails, niet elke wijziging", say: "Wat als jouw team niet elke wijziging doet, maar de vangrails bouwt: automatische controles die een wijziging tegenhouden voordat hij de facturatie raakt? Jij bepaalt de regels. De anderen bouwen erbinnen.", reply: "Ik bouw de vangrails. Dan bewaak ik het platform beter dan nu, en hoef ik niet elke wijziging zelf te doen. … Dat is eigenlijk mijn vak. Ja."}
    experiments:
      - {id: one_screen_first, addresses: [concern], label: "Eén scherm eerst, met Tim als reviewer", say: "Eén scherm, een maand: het app-team bouwt, jij kijkt elke wijziging na. Daarna beslis jij of het verder gaat.", reply: "Eén scherm. Ik kijk na. Dan weet ik of ik het kan loslaten."}
    co_proposal: {id: tim_guards_the_rails, text: "En als er toch iets misgaat, bespreken we het zonder te zoeken wie. Zoals Bart dat bij Beheer doet."}
    outcomes:
      commitment: "Afgesproken. Ik schrijf de eerste vangrail deze week. Die voor de facturatie."
      partial: "Ik doe mee. Als mijn team de regels maakt."
      heard: "Je vroeg naar die nacht. De meeste mensen vragen naar de wachtrij."
      compliance: "Goed. Ze mogen erin. Bel me maar als het kapot is."
      ruined: "Zie je. Loslaten, en ik mag het opruimen."
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > reflect +10 71
    #        > inquiry +8 79 (lead-in, cue) > silence +12 > 81 capped (concern) > propose tim_guards_the_rails +8 89 > ask: commitment (8 moves)
    # route (with flag:blame_postmortem, start 30): mood +8 38 > open question +6 44 > paraphrase +7 51 (heard) > inquiry +8 59 (interest)
    #        > reflect +10 69 > inquiry +8 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose +8 89 > ask (9 moves)
    # 2026-10-16 (1.6c, route variety): only looking from his side of that night (Ander perspectief) draws the concern out; silence lets it pass.
```

**Path dependence.**
- **`flag:blame_postmortem`** (tier-3 `fix_ops_dev_wall`): the platform team's trust is −1, and Tim starts at 30.
  - `stream_aligned_team` is closed (`needs: {none: [flag:blame_postmortem]}`) until a blameless postmortem has been held (`chose:ops_dev_wall:blameless_postmortems` clears the flag, tier-3 §2.7).
  - Tier 3's blame costs tier 4's best countermeasure.
- **`flag:pi_stretch`** (tier-3 `fix_pi_overcommit`): the app team's trust is −1 at the chapter's start (tier-3 §3.2). Noor's beat reads "We zijn moe. Laat het alsjeblieft geen nieuw toneelstuk worden."
- **`flag:dependency_manager`** (the temptation): €1,800 a week, and the debrief's poor-fix variant.
- **Set:** `chose:team_dependencies:stream_aligned_team` or `platform_self_service` makes `it_field_asset_data`'s app change cheaper (one team builds it: `needs_discount`).

**Grounding.**
- Stream-aligned and platform teams, "thinnest viable platform", self-service with guardrails: Skelton & Pais, *Team Topologies* (2019).
- Dependency boards at PI planning (the "program board"): Scaled Agile Framework (*verify against SAFe 6.0*).
- Waiting in handoffs as the main part of lead time: Reinertsen (2009).
- Eleven weeks, 34 requests and "February": estimates and fiction.

**Engrossing.**
- A tiny change (one field) that takes eleven weeks: the same lesson as tier 1's custom design, now in software.
- Tim's turn, from gatekeeper to the builder of the guardrails, is a respectful role change, not a reorganisation done to him.

### 2.2 `fix_status_page_wrong` — De statuspagina liegt (M)

Drafted in full in the tier-3 draft §2.8 (mission, problem, four countermeasures, `noor_status`). Changes when it enters this chain:

```yaml
missions:
  - id: fix_status_page_wrong
    requires: {missions: [fix_team_dependencies]}   # was [fix_pi_overcommit]; one main at a time in the chain
    # everything else as in the tier-3 draft §2.8
```

- **The release twist reads tier 3.** `forecast_from_planning` stays `release_gated`.
  - It ships within weeks if `fix_release_twice_a_year` was fixed well (`ci_cd_pipeline` or `monthly_release_train`).
  - It waits for "maart" after a poor fix there.
  - The tier-3 player's release cadence decides how long the tier-4 player waits.
- **Team dependencies read too.** With `stream_aligned_team` or `platform_self_service` chosen in §2.1, the portal team can change its own status texts: `plain_language_status`'s team hours halve.
- **D45 *Gewone taal*** (moved here from the engagement loop, §4) can fire in this mission.

### 2.3 `it_field_asset_data` — De mof die nergens staat (M, new)

Principles tested: **respect** (the monteur's knowledge, captured once, at the source) and **improve**. This is where the chains meet: the field app the player made usable in tier 3 feeds the risk model of Act V. Temptation: a one-off clean-up of the register by an outside firm.

```yaml
missions:
  - id: it_field_asset_data
    name: De mof die nergens staat
    kind: main
    tier: 4
    act: 6
    chapter: Het digitale loket
    track: it
    requires: {missions: [fix_status_page_wrong, t4_hoshin]}
    goal: {type: solve, problem: joint_data_lost}
    principles: [respect, improve]
    briefing: "Ingrid's risicoscore zegt dat de mof in de Merelstraat uit 1978 is en hoog risico heeft. Ruben vervangt hem, en vindt een mof uit 2019. Iemand heeft hem vijf jaar geleden al vervangen, na een storing. In het register staat dat nergens. Mieke: 'Wat een monteur na een storing doet, komt bij mij binnen als een foto in een groepsapp. Als het binnenkomt.'"
    debrief: "Een vervangen mof staat nu binnen een dag in het register: type, datum, foto, plek. De risicoscore klopt weer met wat er in de grond ligt. Mieke: 'Ik teken niet meer over wat een ander al getekend heeft. Ik controleer wat de monteur vastlegde. Dat is een ander vak. Een beter vak.' {link_line}"
    debrief_variants:
      poor_fix: "Het bureau heeft het register opgeschoond. Het klopt nu. Maar na elke storing komt er weer een mof bij die nergens staat, en over een jaar is het weer zo ver."
    reopen: "Er staan weer moffen in het register die er niet meer liggen. Het afmeldscherm vraagt het type niet meer sinds de laatste release."
    beats:
      - {on: accepted, who: ingrid, text: "Mijn score is zo goed als wat erin gaat. En wat erin gaat, is een kaart van vijf jaar oud."}
      - {on: accepted, who: ricardo, text: "We fotograferen elke mof al. Al jaren. In de groep. Niemand vroeg er ooit om."}   # only if committed:ricardo_whatsapp
    temptations:
      - id: register_cleanup
        who: it_manager
        when: accepted
        text: "Laat een bureau het hele register in één keer opschonen. Drie maanden, en het klopt weer."
        accept: "Je laat een bureau het register opschonen."
        decline: "Je laat het register kloppen bij de bron, bij elke klus."
        accept_sets_flags: [flag:register_cleanup]
        accept_effects: {cost: 35000}
    teaches: [quality_at_the_source, asset_health_index, value_stream_identification]
    rewards: {xp: 3200, budget: 25000, reputation: 5, trust: {gis: 1}}
    insights:
      go_see: "Waar komt een vervangen mof terecht nadat de monteur hem heeft gelegd? Heb je het pad gevolgd?"
      understand: "Waarom staat de mof uit 2019 nergens? Wie wist het, en waar bleef het?"
      experiment: "Als het afmeldscherm het type mof vraagt, wat verwacht je dan over een kwartaal in het register te zien?"
      reflect: "Wat verandert er aan Mieke's werk als de monteur het zelf vastlegt?"

problems:
  - id: joint_data_lost
    tier: 4
    track: it
    name: De mof die nergens staat
    step: outages.repair
    waste: defects
    severity: medium
    visibility: hidden
    kpi: first_time_right
    symptoms:
      - De risicoscore wijst moffen aan die al vervangen zijn.
      - Na een storing komt wat de monteur deed, niet of laat in het register.
    root_cause: Na een storingsreparatie vraagt het afmeldscherm niet welk onderdeel er nu in de grond ligt. Monteurs sturen een foto in de groepsapp, of niets. Revisie & GIS krijgt het niet of maanden later, en het register blijft tonen wat er vroeger lag. Onderhoud en vervanging worden gepland op een kaart die niet klopt.
    plausible_causes:
      - De monteurs zijn slordig met hun administratie.
      - Het register is gewoon verouderd en moet opnieuw.
    mismatch_note: Een opgeschoond register raakt na elke storing weer achter. Het helpt pas als vastleggen een deel van de klus is, op de plek waar het gebeurt.
    countermeasures: {joint_capture_in_app: 1.0, photo_to_gis_check: 0.8, quarterly_reconciliation: 0.6, one_off_cleanup: 0.5}
    teaches: [quality_at_the_source]
    effects:
      # estimate: replacements and inspections planned on stale joint data miss some at-risk joints and visit some
      # replaced ones: outage demand x1.05; GIS retypes and searches: revision touch time x1.1
      - {target: outages, property: demand, value: 1.05}
      - {target: connections.revision, property: touch_time, value: 1.1}
    clues:
      - {tool: documents, key: true, depth: 0, at: outages.repair, text: "Het afmeldscherm na een storing vraagt: oorzaak, duur, handtekening. Niet: wat ligt er nu in de grond."}
      - {tool: data, key: true, depth: 1, text: "Van de moffen die vorig jaar na een storing zijn vervangen, staat een op de drie nog met het oude type in het register."}
      - {tool: shadow, key: true, depth: 1, at: outages.repair, text: "Ruben legt een nieuwe mof, maakt een foto, en stuurt hem in de groepsapp met 'Merelstraat, gedaan'. Dan rijdt hij naar de volgende storing."}
      - {tool: conversation, key: true, depth: 2, at: connections.revision, text: "'Die foto's komen binnen tussen de verjaardagstaarten. Soms zoek ik er een uur naar. Soms vind ik hem niet.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Monteurs zijn nu eenmaal geen administrateurs.'"}

countermeasures:
  - id: joint_capture_in_app
    name: Het afmeldscherm vraagt wat er nu ligt
    tier: 4
    category: quality
    description: Na een storingsreparatie vraagt het afmeldscherm van de veldapp het type en de plek van het nieuwe onderdeel, met een foto. Het gaat direct naar het register, waar Revisie & GIS het controleert. Het vraagt een wijziging in de app.
    budget: 15000
    team_hours: {app_team: 30, gis: 10}
    decay_days: null
    release_gated: true
    needs: {any: [chose:field_app_bypassed:close_out_redesign_with_monteurs, chose:field_app_bypassed:offline_mode, repaired:field_app_bypassed]}
    preparation: "De monteurs moeten de app eerst echt gebruiken."
    needs_discount: {needs: {any: [chose:team_dependencies:stream_aligned_team, chose:team_dependencies:platform_self_service]}, budget: 0.7, team_hours: 0.6}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.955}
      - {target: connections.revision, property: touch_time, value: 0.9}
  - id: photo_to_gis_check
    name: De foto gaat naar Revisie & GIS, niet naar de groep
    tier: 2
    category: standard_work
    description: Monteurs sturen de foto van een vervangen onderdeel naar een vast adres van Revisie & GIS, met de straat erbij. Mieke's team zet het binnen een week in het register.
    budget: 2000
    team_hours: {gis: 15, monteurs: 5}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.97}
  - id: quarterly_reconciliation
    name: Elk kwartaal het register naast de storingen
    tier: 2
    category: quality
    description: Elk kwartaal legt Revisie & GIS de storingsmeldingen naast het register en zoekt uit wat er vervangen is.
    budget: 3000
    team_hours: {gis: 20}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.98}
  - id: one_off_cleanup
    name: Het register in één keer opschonen
    tier: 1
    category: quality
    description: Een bureau loopt drie maanden alle storingen van vijf jaar na en werkt het register bij. Daarna gaat het zoals het ging.
    budget: 35000
    team_hours: {gis: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: outages, property: demand, value: 0.955}
```

**Dialog: `mieke_register`.** Mieke, from the Act II revision backlog and the Acts 0–II check-in ("Ik teken over wat een ander al getekend heeft"). Her fear from the voice sheet, that capture at the source makes her team obsolete, comes back here at full size.

```yaml
dialogs:
  - id: mieke_register
    person: mieke
    kind: persuade
    mission: it_field_asset_data
    owns: joint_data_lost
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + memory
    #   with standardised:revision_backlog (Act II, revision at the source kept): +15 = 55; with mieke_archive lifted: +5
    opening: "Kijk. Een foto van een mof, tussen een taart en een duim. Dit is mijn bron."
    position: {text: "Het register klopt zo goed als wat wij binnenkrijgen. Wij tekenen zo snel als we kunnen.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question], text: "Ik wil dat het klopt. Sinds die graafschade bij De Linde kijkt iedereen naar GIS. Als het register niet klopt, ligt er iemand in een sleuf met een kaart die liegt.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [reflect, empathy]   # 2026-10-16 (1.6c, route variety): a feeling cue
        lead_in: {text: "Ik vind het eng, als ik eerlijk ben. Maar als de app het straks…", tags: [feeling]}
        text: "…allemaal zelf doet, wat doen wij dan nog? Toen we bij de bron gingen intekenen, ging het al van tekenen naar controleren. Nu controleert de app. Ik ben negenenveertig. Mijn dochter vroeg wat ik doe. Straks weet ik het zelf niet meer."
        tags: [admission]
        unlocks: {facts: [heard:mieke_role], proposals: [mieke_owns_the_quality]}
    reframe: "Vanuit Ruben in de Merelstraat? Die vervangt een mof die al vervangen was. Een nacht voor niks. Hm. Omdat wij het niet wisten."
    warning: "Als je komt vertellen dat de app het beter kan dan wij, mag je hem ook laten tekenen."
    data: ["joint_data_lost:1", "joint_data_lost:2"]
    proposals:
      - {id: app_asks_the_type, addresses: [interest], label: "De app vraagt het type mof", say: "Laat het afmeldscherm het type en de plek van het nieuwe onderdeel vragen.", reply: "Dan komt het tenminste binnen. Niet tussen de taarten."}
      - {id: mieke_owns_the_quality, hidden: true, addresses: [concern], label: "Mieke's team bepaalt wat de app vraagt, en bewaakt het register", say: "Wat als jouw team bepaalt wat de app moet vragen, en elke week bekijkt wat er binnenkwam? Niet overtekenen, maar het register bewaken. Jullie zijn de enigen die weten wanneer een foto niet klopt met de kaart.", reply: "Wij bepalen wat de monteur vastlegt. En wij zien wat niet klopt. … Dat kan ik mijn dochter uitleggen. Ik zorg dat de kaart niet liegt."}
    experiments:
      - {id: one_month_side_by_side, addresses: [concern], label: "Een maand naast elkaar: app en foto's", say: "Een maand lang komt het via de app én via de foto's binnen. Jouw team vergelijkt welke beter klopt.", reply: "Naast elkaar. Dan zie ik het zelf. Goed."}
    co_proposal: {id: mieke_owns_the_quality, text: "En de monteurs krijgen terug wat wij vonden. Als een foto niet klopt, wil Ruben dat weten. Niet als verwijt. Als hulp."}
    outcomes:
      commitment: "Dat moet kloppen, dus ik schrijf het lijstje zelf. Wat de app moet vragen. Vandaag. Ik weet het uit mijn hoofd."
      partial: "Als mijn team de controle houdt. Dat moet kloppen."
      heard: "Fijn. Ik dacht dat iedereen alleen nog naar de app keek."
      compliance: "Prima. Dan kijkt de app wel."
      ruined: "Mijn team kan weg. Dat bedoel je toch?"
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry x1.5 +12 (craftsman) > 64 capped (interest)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern) > propose mieke_owns_the_quality +8 89 > ask: commitment (7 moves)
    # route (with standardised:revision_backlog, start 55): open question +6 61 (interest) > reflect +10 71 > inquiry +8 79 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose +8 89 > ask (6 moves)
    # 2026-10-16 (four-tier audit §4): concern cue is a feeling (reflect or empathy draws it out; silence misses); interest via [inquiry, open_question, paraphrase] -> [inquiry, open_question] (craftsman). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (craftsman): concern.at 72->70.
    # 2026-10-16 (1.6c, route variety): a feeling cue: reflect or empathy draws it out; inquiry no longer does.
```

**Path dependence: where the chains meet.**
- **Read from tier 3:** `chose:field_app_bypassed:close_out_redesign_with_monteurs` (or `offline_mode`, or the repair) makes the best countermeasure available at all. A player who left the app bypassed in tier 3 can only reach the second-best options here, until the repair quest ships the redesign.
- **Read from tier 3:** `committed:ricardo_whatsapp`. Ricardo's beat: the photos have existed for years. The group was the workaround, and it is the requirement (D39 *De echte app*'s lesson, paying off).
- **Read from Act II:** `standardised:revision_backlog`. Mieke starts at 55; her team already checks rather than redraws.
- **Read and set across chains:** `done:it_field_asset_data` raises `risk_based_maintenance`'s effect in Act V (§1.2: ×0.88 → ×0.85). Whichever comes second carries `{link_line}`: "De moffen die de monteurs vastleggen, staan nu in het register. Ingrid: 'Nu klopt mijn score.'"
- **`flag:register_cleanup`** (the temptation): €35,000 and a good register for 120 days, then the decay. It is a poor fix, so the repair quest opens after 42 days, once the gap shows.
- **Respect:** with `field_reports_never_alone` from §1.4, the app's close-out screen also carries the theft report. One screen, two uses.

**Grounding.**
- Quality at the source and capture at the point of work: Shingo; the tier-1 `quality_at_the_source` concept.
- Asset registers that drift from the field are a known data-quality issue in asset management; data quality is an NTA 8120 / ISO 55001 requirement (*verify the clause*).
- One in three, 1978 and 2019: estimates and fiction.

**Engrossing.**
- A night shift spent replacing a joint that was already new.
- The person who feared capture at the source in Act II becomes the guardian of the register's truth. The game's people principle, played across three acts.

### 2.4 `it_dora_metrics` — Meten zoals DevOps (M, sustain)

Principles tested: **long_term** and **improve** (a metric that helps the team, not one that grades it). Temptation: count every configuration change as a release.

```yaml
missions:
  - id: it_dora_metrics
    name: Meten zoals DevOps
    kind: main
    tier: 4
    act: 6
    chapter: Het digitale loket
    track: it
    requires: {missions: [it_field_asset_data]}
    goal:
      type: hold_kpi
      kpis: [{stream: it_features, kpi: lead_time, max: base_x0.7}]
      weeks: 8
      board: [deployment_frequency, change_failure_rate, time_to_restore]   # shown with the measured KPI; not judged
    principles: [long_term, improve]
    briefing: "De release train is sneller geworden. Hoeveel sneller, en is hij ook stabieler? Bas wil vier getallen op het bord: hoe vaak er iets live gaat, hoe lang een wijziging erover doet, hoe vaak een release iets kapotmaakt, en hoe snel het weer werkt. 'Niet om teams te vergelijken,' zegt hij. 'Om te zien of we beter worden.'"
    debrief: "Acht weken lang deed een wijziging gemiddeld {lead_time} dagen van idee tot gebruik, was {lead_time_before}. Er ging {deploys} keer per week iets live, en {failure_rate}% daarvan gaf een storing. Bas: 'Snel en stabiel. Ze zeggen dat dat niet samengaat. Het gaat juist samen.'"
    debrief_variants:
      gamed: "De releasefrequentie op het bord is verdubbeld. Hanneke kijkt ernaar en zegt niets. Dan: 'Twee daarvan waren een spelfout in een tekst. Tellen die?'"
    beats:
      - {on: accepted, who: erwin, text: "Vier getallen. Ik had er vroeger één: het aantal releases dat misging. Dat was nul, want we deden er twee per jaar."}
      - {on: completed, who: noor, text: "Ik ging deze week met Ricardo mee. Hij liet me een scherm zien dat we vorige maand bouwden. 'Dit werkt,' zei hij. Dat getal staat niet op het bord. Het is wel het beste."}
    temptations:
      - id: count_every_change
        who: it_manager
        when: accepted
        text: "Tel elke configuratiewijziging ook als release. Dan staan we op het bord meteen bij de besten."
        accept: "Je laat elke configuratiewijziging meetellen als release."
        decline: "Je laat alleen echte wijzigingen voor gebruikers meetellen."
        accept_sets_flags: [flag:dora_gamed]
        accept_effects: {reputation: 2}
    teaches: [dora_metrics, leading_lagging, goodhart]
    rewards: {xp: 3400, budget: 30000, reputation: 5}
    insights:
      go_see: "Wat telt er als een release? Heb je bij een release gekeken wat er live ging?"
      understand: "Welk van de vier getallen zegt het meest over wat een monteur merkt?"
      experiment: "Als de doorlooptijd korter wordt, wat verwacht je dan van het aantal storingen na een release?"
      reflect: "Wie gebruikt deze getallen, en waarvoor? Wat zou er gebeuren als ze teams ermee gingen vergelijken?"
```

- **Dialogs: none, by design.** A measure mission, as `t2_first_okr` in tier 2. Bas, Erwin and Noor speak in beats. The persuasion work of this chapter is done in §2.1 and §2.3.
- **`flag:dora_gamed`** (the temptation) never decides the goal, which reads `lead_time`.
  - It is the Goodhart lesson in IT: the debrief's `gamed` variant, and Hanneke's line.
  - It blocks D40 *Klein en vaak* from firing afterwards.
  - The engagement loop's dropped "Snelle trein" reward stays dropped: no reward reads the DORA numbers alone.
- **`base_x0.7`:** the target is relative to the chapter's own start (the tier-2 draft's `hold_kpi` with a relative target).
  - A tier-3 player with a good release cadence starts with a short lead time, and must still improve by a third.
  - Estimate: one more constraint broken in the chapter.
- **Grounding:**
  - DORA's four keys, and speed and stability going together: Forsgren, Humble & Kim, *Accelerate* (2018); the DORA reports.
  - Goodhart's law (Goodhart 1975; Strathern 1997's formulation).

### 2.5 Side missions of the IT chapter

**`fix_meter_data_mandates`:** drafted in full in the tier-3 draft §2.8 (mission, problem, two countermeasures, `lisette_privacy`). Changes:

```yaml
missions:
  - id: fix_meter_data_mandates
    requires: {missions: [fix_pi_overcommit], maturity: {it: 3}}   # adds the IT maturity gate
    # everything else as in the tier-3 draft §2.8
```

- **Path:** `flag:whatsapp_official` (tier-3 `fix_field_app_bypassed`'s temptation, with its privacy aftermath) makes Lisette start 10 lower. She handled that aftermath.

**`fix_tech_debt`:**

```yaml
missions:
  - id: fix_tech_debt
    name: De schuld in de code
    kind: side
    tier: 4
    act: 6
    track: it
    requires: {missions: [fix_team_dependencies]}
    goal: {type: solve, problem: tech_debt}
    principles: [long_term, respect]
    briefing: "Elke wijziging aan het werkorderplatform kost meer tijd dan de vorige. Mark van Leeuwen: 'Het is alsof je een huis verbouwt waar niemand ooit een tekening van heeft gemaakt. Elke muur die je weghaalt, draagt iets.'"
    debrief: "Een wijziging aan het platform kost weer {build_delta}% minder tijd. Het team ruimt op waar het werk vastloopt, niet overal. Mark: 'Ik doe het nu overdag. Op het bord. Dat scheelt meer dan je denkt.'"
    temptations:
      - id: rewrite_everything
        who: noor
        when: accepted
        text: "Laten we het platform opnieuw bouwen. Schoon, modern. Over anderhalf jaar zijn we van alle schuld af."
        accept: "Je laat het platform opnieuw bouwen."
        decline: "Je laat opruimen waar het werk vastloopt, stap voor stap."
        accept_sets_flags: [flag:big_rewrite]
        accept_effects: {cost: 60000}
    teaches: [technical_debt, bottleneck_focus]
    rewards: {xp: 1200, budget: 10000, reputation: 2}

problems:
  - id: tech_debt
    tier: 4
    track: it
    name: De schuld in de code
    step: it_features.build
    waste: overprocessing
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Wijzigingen aan het werkorderplatform kosten elk kwartaal meer tijd.
      - Na een release komen er vaker storingen aan het platform binnen.
    root_cause: Twaalf jaar lang is er aangebouwd zonder op te ruimen. Er is nooit tijd voor ingepland; wie opruimt, doet het 's avonds of niet. De meeste schuld zit in een paar onderdelen die bij bijna elke wijziging geraakt worden.
    plausible_causes:
      - De ontwikkelaars zijn niet goed genoeg.
      - Het platform is te oud; het moet opnieuw.
    mismatch_note: Opnieuw bouwen kost anderhalf jaar waarin het oude platform blijft draaien en de schuld blijft groeien. Het helpt om op te ruimen waar het werk het vaakst langskomt, overdag, als gewoon werk.
    countermeasures: {refactor_at_the_constraint: 1.0, debt_capacity_share: 0.8, rewrite_platform: 0.5}
    teaches: [technical_debt]
    effects:
      # estimate: build touch time x1.2 (in reality it grows each quarter; a timed ramp is a code item, §7) and
      # incidents after releases x1.15
      - {target: it_features.build, property: touch_time, value: 1.2}
      - {target: it_incidents, property: demand, value: 1.15}
    clues:
      - {tool: data, key: true, depth: 0, at: it_features.build, text: "Een gemiddelde wijziging aan het platform kostte drie jaar geleden vier dagen. Nu zes."}
      - {tool: data, key: true, depth: 1, at: it_features.build, text: "Drie onderdelen van het platform worden bij acht van de tien wijzigingen geraakt. Daar zitten ook de meeste storingen."}
      - {tool: shadow, key: true, depth: 2, at: it_features.build, text: "Om half tien 's avonds staat er een wijziging van Mark in de pijplijn: 'opruimen planningmodule'. Op het bord van het team staat hij niet."}
      - {tool: conversation, key: false, depth: 0, text: "'Dit platform is gewoon te oud. Opnieuw bouwen, dat is de enige oplossing.'"}

countermeasures:
  - id: refactor_at_the_constraint
    name: Opruimen waar het werk vastloopt
    tier: 3
    category: flow
    description: Het team ruimt eerst de drie onderdelen op die bij bijna elke wijziging geraakt worden. Opruimen staat op het bord, overdag, als gewoon werk.
    budget: 8000
    team_hours: {platform_team: 40}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.build, property: touch_time, value: 0.85}
      - {target: it_incidents, property: demand, value: 0.9}
  - id: debt_capacity_share
    name: Een vast deel van de tijd voor opruimen
    tier: 2
    category: standard_work
    description: Een vijfde van de capaciteit van het team gaat elke sprint naar opruimen, waar het team zelf kiest.
    budget: 3000
    team_hours: {platform_team: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.build, property: touch_time, value: 0.9}
  - id: rewrite_platform
    name: Het platform opnieuw bouwen
    tier: 1
    category: flow
    description: Een nieuw platform, in anderhalf jaar. Het oude blijft tot die tijd draaien en moet ook onderhouden worden.
    budget: 60000
    team_hours: {platform_team: 60}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
    aftermath: {after_days: 0, days: 270, effects: [{target: it_features.build, property: touch_time, value: 1.2}]}   # estimate: two platforms to maintain while the new one is built

dialogs:
  - id: mark_debt
    person: mark
    kind: persuade
    mission: fix_tech_debt
    owns: tech_debt
    patience: 9
    # start: quiet 47 + 0 + 0 + 0 + 0 = 47, Luistert; with committed:mark_pairing (tier 3): +15 = 62
    opening: "Hm? Sorry. Koptelefoon. Ik zat in de planningmodule."
    position: {text: "Het gaat wel. Het is gewoon een oud platform.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, mood, silence], text: "Elke keer als ik iets wijzig, breek ik iets anders. Dus kijk ik eerst twee uur rond voordat ik iets durf.", tags: [claim, feeling]}
      - id: concern
        at: 66
        via: [silence, reflect, empathy]
        lead_in: {text: "'s Avonds…", tags: [hesitation]}
        text: "…ruim ik op. Thuis. Niemand vraagt het, niemand ziet het. Bij mijn vorige werkgever deed ik dat ook. Toen zat ik drie maanden thuis. Ik voel het weer aankomen, en ik weet niet hoe ik moet stoppen zonder dat het platform omvalt."
        tags: [admission]
        unlocks: {facts: [heard:mark_evenings], proposals: [debt_in_daylight]}
    reframe: "Vanuit Noor, die wacht op een wijziging die zes dagen kost in plaats van vier? Die ziet een langzaam team. Niet de avonden. Nee. Die ziet ze niet."
    warning: "Als het over sneller werken gaat: ik kan niet sneller."
    data: ["tech_debt:0", "tech_debt:1"]
    proposals:
      - {id: fifth_for_debt, addresses: [interest], label: "Een vijfde van de tijd voor opruimen", say: "Een vijfde van de tijd van het team gaat naar opruimen.", reply: "Een vijfde. Dat helpt. Als niemand het in de PI-planning weer wegstreept."}
      - {id: debt_in_daylight, hidden: true, addresses: [concern], label: "Opruimen overdag, op het bord, waar het het meest kost", say: "Wat als opruimen gewoon werk wordt? Overdag, op het bord, te beginnen bij de drie onderdelen waar het het meest kost. En niemand ruimt nog 's avonds op. Ook jij niet.", reply: "Overdag. Op het bord. En 's avonds niet. … Ik denk dat ik dat moet horen van iemand anders dan mezelf."}
    experiments:
      - {id: one_module_a_month, addresses: [concern], label: "Eén module, een maand, overdag", say: "Eén maand ruimt het team overdag de planningmodule op, en we meten wat het oplevert.", reply: "De planningmodule. Overdag. Dan zien ze het ook eens."}
    co_proposal: {id: debt_in_daylight, text: "En als ik toch 's avonds commit, mag Bas het zeggen. Hardop. Ik meen het."}
    outcomes:
      commitment: "Oké. Morgen staat hij op het bord. De planningmodule. Met mijn naam erbij."
      partial: "Alleen als het in de PI-planning blijft staan. Anders is het weer avondwerk."
      heard: "De avonden. Dat had ik nog tegen niemand gezegd."
      compliance: "Ik doe mijn best. Zoals altijd."
      ruined: "Sneller. Ik kan niet sneller. Dat zei ik bij mijn vorige baan ook."
    # route (start 47): open question +6 53 > paraphrase +7 60 (heard, interest) > reflect +10 70 > empathy +6 76 (lead-in, cue)
    #        > silence +18 (quiet x1.5) > 81 capped (concern) > propose debt_in_daylight +8 89 > ask: commitment (7 moves)
    # 2026-10-16 (four-tier audit §4): interest via [open_question, silence, paraphrase] -> [open_question, mood, silence] (quiet). Route re-checked by the simulator (audit §4.4).
    # 2026-10-16 (four-tier audit §4.4): thresholds by archetype (quiet): interest.at 55->50, concern.at 72->66.
```

- **Path:** `committed:mark_pairing` (tier 3, the code-review fork branch) starts Mark at 62. He trusts the player who once protected him from pairing all day.
- **`flag:big_rewrite`** (the temptation): €60,000, two platforms for nine months (the aftermath), and nothing better until the rewrite would ship, which is beyond the act. It is a poor fix; the repair quest swaps it for `refactor_at_the_constraint`.
- **Respect:** Mark's concern is burnout. The best countermeasure takes the work into daylight; it does not ask more. D27 *Niemand opgebrand* can fire here.
- **Grounding:**
  - Technical debt: Cunningham (1992).
  - Refactor where change happens most (hotspots): Tornhill, *Your Code as a Crime Scene* (2015).
  - The rewrite trap: Spolsky, "Things You Should Never Do, Part I" (2000).
  - Four and six days, three modules: estimates.

---

### 2.6 Addition (2026-10-16): the chapter's human thread — `thread_notebook` — Het boekje van Ricardo (S)

PLAN §4.2.2 (arc doc §9.4). **A face:** Ricardo (34), monteur and admin of the WhatsApp group (tier 3). **A number:** seventy joints that are in Ricardo's paper notebook and nowhere else (Mieke's count). **A choice:** have the notebook scanned and keyed in by an outside bureau, or ask Ricardo to give it to Mieke, in his own time. **A payoff:** `it_field_asset_data`'s debrief and D39's card.

```yaml
missions:
  - id: thread_notebook
    name: Het boekje van Ricardo
    kind: side
    tier: 4
    act: 6
    track: it
    arc: threads
    requires: {missions: [it_field_asset_data]}        # opens when it is accepted (requires_accepted)
    goal: {type: talk_to, dialog: ricardo_notebook, outcome: lifted}    # a check-in as a goal (S-new: talk_to accepts lifted for a check-in)
    principles: [respect, long_term]
    briefing: "Mieke: 'In Ricardo's boekje staan zeventig moffen die nergens anders staan. Zeven jaar kelders in Nova-Oud. Ik heb het gezien. Hij laat het niet uit zijn handen.'"
    debrief: "{notebook_line}"
    debrief_variants:
      given: "Ricardo heeft het boekje aan Mieke gegeven. 'Voor het archief,' zei hij. Zeventig moffen staan nu in GIS, met zijn naam bij de bron."
      scanned: "Het bureau heeft het boekje ingescand. Zeventig moffen staan in GIS. Bij drie twijfelde de typist aan een cijfer. Ricardo heeft zijn boekje terug, en een nieuw boekje gekocht."
    beats:
      - {on: accepted, who: ricardo, text: "Dit is de echte database. Kelders zonder bereik. Ik schrijf het op en tik het 's avonds over. Soms."}
    temptations:
      - id: scan_bureau
        who: it_manager
        when: accepted
        text: "Laat dat boekje inscannen door een bureau. Twee dagen werk, en het staat erin. Dan hoeft niemand met Ricardo te praten."
        accept: "Een bureau scant het boekje in."
        decline: "Je vraagt Ricardo zelf."
        accept_sets_flags: [flag:notebook_scanned]
        accept_effects: {cost: 2500, complete_goal: true, person_trust: {ricardo: -10}}   # pays half by rule A9 (four-tier audit §5.2)
    teaches: [data_at_the_source, respect_for_people]
    rewards: {xp: 1200, reputation: 2}
```

**Path dependence.**
- `flag:notebook_to_mieke` (Ricardo lifted) makes `joint_capture_in_app` start with Ricardo's seventy joints as test cases: the release's first Check reads first-time-right on joints whose truth is known. D39's card adds "en het boekje".
- `flag:notebook_scanned`: three of the seventy are keyed in wrong (`estimate:`), so the risk score is wrong at three streets; one of them is the Act V fork's first low-voltage fault. Ricardo keeps a new notebook: the workaround survives because the people were bypassed.

**Dialog:** `ricardo_notebook` (arc doc §9.4).

## 3. Path dependence: what tier 4 reads

Tier 4 is the campaign's widest reader. The table lists every earlier fact these drafts read. The tier-3 draft §3.2 promised each one, and it is honoured here.

| Fact (set in) | Read by | What it changes |
|---|---|---|
| `committed:frank_red_numbers` (Act III) | `frank_twenty` | Frank starts at 50, not 35. |
| `committed:ruben_cause`, the cause-code countermeasures, `standardised:cause_unknown` (Act III) | `fix_maintenance_calendar` | `risk_based_maintenance` 30 % cheaper; `fault_pareto` available; the depth-2 clue reads a clean history or "een op de drie: onbekend". |
| `committed:nicole_lmra` (Act III) | `nta8120_audit` | An observation on safety culture. |
| `committed:acm_inspector` (Act III) | `rianne_audit` | Rianne starts at 40. |
| `committed:petra_station_data` (Act III) | `fix_ls_grid_blind`, `fix_grid_losses_theft` | The meter log and the balance analytics are cheaper. |
| `committed:wendy_handover` (Act III) | `kees_meter_alarms` | Control-room team trust +1. |
| `kees_night`, `yvonne_cards`, `mieke_archive` lifted (Acts 0–II check-ins) | `kees_meter_alarms`, `yvonne_theft`, `mieke_register` | +5 each: a walk-around talk remembered two acts later. |
| `standardised:revision_backlog` (Act II) | `nta8120_audit`, `mieke_register` | Mieke's observation and beat, or a minor finding; she starts at 55. |
| D15 *Wims spreadsheet* (Act II) | `fix_flex_market_unused` | Wim's beat; D49. |
| `standardised:custom_design` (Act I) | `t4_investment_plan` | One branch of "Standaardstations in serie". |
| `chose:training_capacity:*`, `flag:freelance_crews`, `heard:ahmed_trainer` (Acts III–IV) | `t4_investment_plan`, `retrain_gas_monteurs` | "Opleiden" open or locked; gas monteurs retrained 40 % cheaper. |
| `chose:transformer_wait:*`, `repaired:transformer_wait` (Act II) | `t4_investment_plan` | "Strategische trafovoorraad". |
| `chose:nitrogen_permit:parallel_ecology` / `aerius_template` (Act IV) | `t4_investment_plan` | The second branch of "Standaardstations in serie" (tier-3 Q6, decided). |
| `flag:crew_lindeveld`, `repaired:long_drives` (Act IV) | `t4_investment_plan` | "Meer monteurs in Lindeveld". |
| `flag:queue_jumped`, `flag:hidden_wip` (Act IV) | `nta8120_audit` | Findings, reputation −10 each; D38 checked. |
| `flag:deep_cables` (Act IV) | `t4_sensor_pilot`, the plan's forecast | A fourth debrief line; more Havenzij faults in the forecast. |
| `flag:auto_upgrades` (Act IV) | the plan's forecast | Winter outages ("De koude straat"). |
| `flag:flex_forced` (Act IV) | `thomas_flex`, `fix_flex_market_unused`, the plan | Thomas −15 with a variant; flex effects ×0.8 for 180 days; "Flex eerst" forecast lower. |
| `chose:priority_first_come:classify_at_intake` with `committed:jeroen_classes` (Act IV) | `fix_flex_market_unused` | A trusted queue; GOPACS participation 30 % cheaper. |
| `chose:pi_overcommit:capacity_based_pi` with `committed:carla_must_haves`; `flag:pi_stretch` (IT tier 3) | `t4_hoshin`; the IT chapter's start | An honest IT row and Carla's beat; or app-team trust −1 and Noor's tired beat. |
| `flag:blame_postmortem` (IT tier 3) | `fix_team_dependencies` | Tim at 30; `stream_aligned_team` closed until a blameless postmortem. |
| `committed:mark_pairing` (IT tier 3) | `mark_debt` | Mark at 62. |
| `chose:field_app_bypassed:*`, `repaired:field_app_bypassed`, `committed:ricardo_whatsapp` (IT tier 3) | `it_field_asset_data` | The best countermeasure available or not; Ricardo's beat. |
| `chose:release_twice_a_year:*` (IT tier 3) | `fix_status_page_wrong`, `it_field_asset_data` | How long a `release_gated` fix waits. |
| `flag:whatsapp_official` (IT tier 3) | `lisette_privacy` | Lisette −10. |

**Facts tier 4 sets** (for the finale placeholder and later content):
- `committed:frank_twenty`, `committed:theo_calendar`, `committed:monique_plan`;
- `flag:plan_*`, `flag:matrix_of_twenty`, `flag:intervals_stretched`, `flag:solo_checks`, `flag:flex_single_seller`, `flag:dora_gamed`, `flag:big_rewrite`;
- `done:it_field_asset_data`.

The finale's idea (coach Lotte) can read who the player developed: Anouk, Sanne, Joost, Mieke, Theo, Harrie.

**Validator check (catalogue §2.15), by hand.** Every `needs` in this draft keeps one branch that no failure or skip can close:
- The investment plan's options:
  - "Opleiden": train-the-trainer is possible after a missed deadline, and the repair exists;
  - "Strategische trafovoorraad": `repaired:transformer_wait`;
  - "Standaardstations": the nitrogen branch, or standardising custom design again through its reopened mission;
  - "Flex eerst": both flex missions are mains or sides that cannot be closed;
  - "Sensoren": `chose:ls_grid_blind:meter_power_failure_log`, which is open even after a failed audit;
  - "Lindeveld": `repaired:long_drives`.
- `fault_pareto`: `repaired:cause_unknown`.
- `lv_sensors_msr`: closed for good by a failed audit (the catalogue's own door). The meter log remains for the same problem.
- `joint_capture_in_app`: `repaired:field_app_bypassed`.
- `stream_aligned_team`: clearing `flag:blame_postmortem` through `blameless_postmortems`.

**Repair quests in tier 4.** Poor fixes by the tier-2 rule (fit ≥ 0.2 below the best, or `trust < 0`, or an `aftermath`, while a better one was offered) set `poor_fix:<problem>`. The template covers:
- Act V: `pmo_dashboard`, `longer_intervals`, `alarm_every_meter`, `solo_meter_checks`, `single_seller_contract`, `stop_gas_maintenance`;
- IT: `coordination_layer`, `one_off_cleanup`, `rewrite_platform`.

Authored overrides are not needed in tier 4; the template's text plus each mission's `poor_fix` debrief variant carry them.

---

## 4. Hidden rewards for Act V and the tier-4 IT chapter (D45–D50)

The engagement loop (§4.3) asks this draft for 4–6. Same rules as audit §4.1:
- unannounced;
- they reward learning, never a shortcut;
- small in power, big in meaning;
- detectable, and once each;
- every one also requires quality;
- every fork branch can earn something;
- deep thinking first.

Shown as silhouettes with a hint (Merijn, 2026-10-15).

| # | Name (NL) | Trigger (detectable) | Reward | Principle | Anti-shortcut guard |
|---|---|---|---|---|---|
| D45 | **Gewone taal** (moved from the engagement loop) | `committed:noor_status` with `listen_with_esra`, status calls down ≥ 30 % (Check), and `forecast_from_planning` live | V: Esra's headset in the vitrine, with Noor's name on a sticker | RP, AI | Needs the shipped forecast, so it includes the release lesson. |
| D46 | **Drie eraf** | `committed:frank_twenty` with `stop_list_with_the_board`, `flag:matrix_of_twenty` never set, and 91 days later `strategy_silos` holds ≥ 0.9 with `lsw_catchball` done once | T "Eén richting"; Frank's crossed-out project list, framed | LT | Needs a quarter of hold and the routine, not only the talk. |
| D47 | **De mof van 1978** | A sim event: with `risk_based_maintenance` and `committed:theo_calendar`, a joint at the top of the risk list is replaced, and its street has no outage for 365 days | V: Theo's torch; R ("Wat je ruikt, is ook data.") | LT, AI | Needs a year, and the people-first choice (Theo's notes in the score). |
| D48 | **Niemand alleen naar binnen** | `fix_grid_losses_theft` solved with `joint_checks_police` or `field_reports_never_alone`, `flag:solo_checks` never set, and `committed:yvonne_theft` | V: a "nooit alleen" sticker on Yvonne's van; Tr +1 meters | RP | The flag guard: one shortcut, and it never fires. Earnable on the fork's N branch (every branch can earn something). |
| D49 | **Wims batterij** | D15 earned (Act II), `aggregator_for_small` chosen, and the Kanaalzone capacity queue's lead time down ≥ 15 % (Check) | V: a new tab in Wim's spreadsheet, "Flexmarkt", shown in his Christmas card | RP, LT | Needs a measured queue gain and the player's own Act II reward. A callback across three acts. |
| D50 | **Een plan dat klopte** | `t4_investment_plan` with ≥ 4 options unlocked, a choice that is neither the baseline nor "Van alles een beetje", and `forecast_check` held within 10 % after 182 days | T "Planmaker"; R from Ruud ("Een plan is een experiment met een datum. Jij hebt de datum gehaald.") | LT, AI | Needs forecast accuracy measured half a year later, not the choice. |

**After the principle check, dropped:**
- **"Audit zonder bevindingen"** (pass the audit with zero findings). It could be earned by a player who never took a temptation, but also by one who never played the missions that carry them. It rewards an absence; D38 and D48 reward refusals that were offered.
- **"Vier getallen groen"** (all DORA keys at elite). It is the dropped "Snelle trein" again: it rewards a dashboard.

**Distribution check** (engagement loop §4.3's row V, now filled):

| Act | Discoverable rewards with a first chance in the act | LT | RP | AI | One for the careful player |
|---|---|---|---|---|---|
| V + IT tier 4 | 6 (D45–D50) + any-act (D2, D7, D26, D27) | ✓ | ✓ | ✓ | D47 (the smell of a station, a year later) |

**Cliffhangers** (engagement loop §3) for the new transitions:
- **The IT chapter's ending, into the finale:** Noor rides along with Ricardo and sends the player a photo of the close-out screen: "Dit werkt. Zegt Ricardo. Dat getal staat niet op het bord." No open question, a quiet close; the IT chain ends before the finale.
- **Act V's ending** stays the engagement loop's: Lotte knocks.

---

## 5. Summary tables and the voice sheet

### 5.1 Missions (20, plus the finale placeholder)

| id | Track · act | Kind | Goal | Problem | Deadline → door | Principles | Temptation (later cost) | Dialogs |
|---|---|---|---|---|---|---|---|---|
| t4_hoshin | grid · V | M | solve | strategy_silos | — | long_term, respect | all twenty on the matrix (an audit finding; work_prep still drained) | frank_twenty |
| fix_maintenance_calendar | grid · V | M | solve | maintenance_calendar | — | improve, respect | stretch all intervals (a major audit finding; outage aftermath) | theo_calendar |
| nta8120_audit | grid · V | Ms | audit | — | 90 d → sensor pilot closed; re-audit opens | long_term, improve | (every earlier shortcut, as findings) | rianne_audit |
| fix_ls_grid_blind | grid · V | M (B) | solve | ls_grid_blind | — | improve, respect | every meter alarm (control-room trust; alarm fatigue) | kees_meter_alarms |
| fix_grid_losses_theft | grid · V | M (N) | solve | grid_losses_theft | — | respect, long_term | solo checks (a threat incident; D48 closed) | yvonne_theft |
| fix_flex_market_unused | grid · V | M | solve | flex_market_unused | — | long_term, respect | one big seller (€4k a week for a year) | thomas_flex |
| t4_investment_plan | grid · V | M | strategy (182 d, forecast check) | — | — | long_term, improve | a sixth of everything (nothing finishes) | monique_plan |
| t4_new_ci_lead | grid · V | M (placeholder) | — | — | — | — | — | — |
| t4_sensor_pilot | grid · V | S | observe + talk_to | — | (the audit's door) | improve | — | Ingrid (topic) |
| fix_gas_phaseout | grid · V | S | solve | gas_phaseout | — | respect, long_term | stop all gas maintenance (a leak) | harrie_gas |
| talk_asset_manager | grid · V | S | talk_to | — | — | improve | — | Ingrid (topics) |
| sector_grid_2035 | grid · V | S | talk_to ×2 | — | — | improve, long_term | — | Femke, Ingrid (topics) |
| nta8120_reaudit | grid · V | S (recovery) | audit | — | 120 d → rep −5, no door | long_term, improve | — | — |
| lsw_catchball | grid · V | R | routine | — | — | long_term, respect | skipping it (decay of hoshin) | — |
| sustain_region | grid · V | S | hold_kpi ×3 | — | — | long_term, improve | — | — |
| fix_team_dependencies | IT · VI | M | solve | team_dependencies | — | respect, long_term | a dependency manager (€1.8k a week; nothing faster) | tim_platform |
| fix_status_page_wrong | IT · VI | M | solve | status_page_wrong | — | respect, long_term | a FAQ (tier-3 §2.8) | noor_status |
| it_field_asset_data | IT · VI | M | solve | joint_data_lost | — | respect, improve | a one-off clean-up (decays in 120 days) | mieke_register |
| it_dora_metrics | IT · VI | M | hold_kpi | — | — | long_term, improve | count every change (Goodhart; D40 closed) | — (beats) |
| fix_tech_debt | IT · VI | S | solve | tech_debt | — | long_term, respect | rewrite everything (two platforms for nine months) | mark_debt |
| fix_meter_data_mandates | IT · VI | S | solve | meter_data_mandates | — | long_term, respect | skip big suppliers (tier-3 §2.8) | lisette_privacy |

**The 1 + 3 rule:**
- One main at a time across both chains; the fork offers two and the player takes one.
- The audit is a milestone and takes no slot.
- The heaviest moment is after `t4_hoshin`: `lsw_catchball`, `fix_gas_phaseout` and `talk_asset_manager` open at once. With the IT sides (`fix_tech_debt` after `fix_team_dependencies`, `fix_meter_data_mandates`), up to five sides can be available. The player holds three; the act's routine (catchball) competes with side problems for a slot, as in Act IV.

**Mission shapes** (audit §5.2), main chain:
- Act V: people/strategy (hoshin) → investigation (maintenance) → fork (data puzzle) → people/conflict (flex) → strategic choice (plan). No two consecutive mains share a shape.
- The act has every required shape: investigation, people/conflict, data puzzle and crisis (the audit's deadline).
- IT: investigation (dependencies) → people with a release twist (status page) → data at the source (asset data) → sustain (DORA).

**Forks:** one (`t4_detect`), honest on outage minutes (correction 2). **Hard deadlines:** one (the audit); the re-audit opens only after it.

### 5.2 Problems (9 new, plus 2 from tier-3 §2.8) and countermeasures (35 new)

| Problem | Step | Waste | KPI | Countermeasures (fit) |
|---|---|---|---|---|
| strategy_silos | work_prep, planners, grid_analysts (pools) | overproduction | lead_time | hoshin_catchball 1.0 · x_matrix 0.8 · okr_per_department 0.7 · pmo_dashboard 0.5 |
| maintenance_calendar | maintenance.inspect | overprocessing | lead_time | risk_based_maintenance 1.0 · condition_monitoring_ms 0.8 · fault_pareto 0.7 · longer_intervals 0.5 |
| ls_grid_blind | outages.noticed | waiting | lead_time | meter_power_failure_log 1.0 · lv_sensors_msr 0.9 · outage_map_for_customers 0.6 · alarm_every_meter 0.5 |
| grid_losses_theft | outages.repair (cost on the region) | defects | lead_time | balance_analytics 1.0 · joint_checks_police 0.7 · field_reports_never_alone 0.6 · solo_meter_checks 0.4 |
| flex_market_unused | congestion.capacity_queue | inventory | lead_time | gopacs_participation 1.0 · flex_in_contracts 0.8 · aggregator_for_small 0.7 · single_seller_contract 0.5 |
| gas_phaseout | gas_monteurs (pool) | overprocessing | capacity | align_with_neighbourhood_plans 1.0 · retrain_gas_monteurs 0.9 · risk_based_gas_maintenance 0.8 · stop_gas_maintenance 0.4 |
| team_dependencies | it_features.dependency | waiting | lead_time | stream_aligned_team 1.0 · platform_self_service 0.9 · dependency_board_pi 0.7 · coordination_layer 0.4 |
| joint_data_lost | outages.repair | defects | first_time_right | joint_capture_in_app 1.0 (release-gated) · photo_to_gis_check 0.8 · quarterly_reconciliation 0.6 · one_off_cleanup 0.5 |
| tech_debt | it_features.build | overprocessing | lead_time | refactor_at_the_constraint 1.0 · debt_capacity_share 0.8 · rewrite_platform 0.5 |
| *(tier-3 §2.8)* status_page_wrong · meter_data_mandates | it_features.in_use · meter_data.mandate_check | defects · overprocessing | on_time · lead_time | as drafted there |

**Wastes:** five of the eight: overproduction, overprocessing, waiting, defects and inventory. Transport, motion and skills are carried by tiers 1–3; skills returns here as a people theme (Harrie's retraining, Mieke's new role) rather than as a problem's waste.

**People-developing options** are present in every people-shaped problem:
- `hoshin_catchball` (departments shape the plan);
- `risk_based_maintenance` (Theo's notes in the score);
- `field_reports_never_alone`;
- `retrain_gas_monteurs`;
- `platform_self_service` (Tim builds the guardrails);
- `refactor_at_the_constraint` (debt work in daylight).

D26 *Ontwikkelen, niet vervangen* can be earned again here.

### 5.3 Voice sheet: the tier-4 cast

As in the Acts 0–II scripts §2. Everyone speaks standard Dutch (decided 2026-10-15: no dialect). Voices differ in word choice, rhythm, humour and worry.

| id | Who (age) | Voice | Humour | Worry (hidden) |
|---|---|---|---|---|
| `ingrid` | Ingrid Bos (52), assetmanager (expert) | Calm, weighs everything: "kans maal gevolg", "eerlijk antwoord". | "De kalender heeft ze nooit in de steek gelaten. Tot hij dat wel deed." | — (expert) |
| `theo` | Theo Janssen (60), coördinator onderhoud | Old-school craftsman, senses: "kraakt", "ruikt naar was", "pas op je hoofd". | "Die deur is van 1968 en hij weet het." | Standing alone in court behind a skipped station. |
| `rianne` | Rianne Hoogendoorn (47), lead auditor (certifying body; fictional) | Precise, polite, asks rather than presents: "steekproef", "bevinding". | Rare: "Leg hem maar op de stapel." | Signing a certificate for a snapshot that is gone three months later. |
| `monique` | Monique de Ruiter (55), directeur Financiën | Numbers and regulation: "doelmatig", "maatstaf", "euro voor euro". | Dry: "Begin maar bij de duurste." | Signing another plan that misses by thirty percent, and shrinking a department again. |
| `harrie` | Harrie Coenen (59), gasmonteur | Few words, safety first: "ruik je dat?", "tot de laatste dag". | "Een helm die nog naar gas ruikt." | That his trade disappears and nobody teaches him the next one. |
| `tim` | Tim de Haan (44), lead Team Werkorderplatform | Protective, technical: "mijn platform", "elke tabel", "vangrails". | — | The night the billing broke and the director asked why he allowed it. |
| `frank` (returning) | Frank Hulshof, manager Aansluitingen & Netverzwaring | As in the Acts 0–II voice sheet. | | Act V stage: six projects that shield the one he cares about. |
| `kees` (returning) | Kees Mulder, operator | As in the tier-2 voice sheet. | | Act V stage: the alarm he clicks away. |
| `yvonne` (returning) | Yvonne Kok, meterwisselaar | As in the Acts 0–II audit cast. | | Act V stage: the man with the baseball bat she never reported. |
| `thomas` (returning) | Thomas Visser, accountmanager | As in the Acts 0–II voice sheet. | | Act V stage: selling a restriction with a price tag. |
| `mieke` (returning) | Mieke van der Veen, Revisie & GIS | As in the Acts 0–II voice sheet. | | Act V stage: what is left of her trade when the app captures it. |
| `mark` (returning) | Mark van Leeuwen, developer | As in the tier-3 voice sheet. | | Tier-4 stage: cleaning up at night, again. |

**Names checked** against the cast of every earlier doc: no collisions. Harrie's colleagues Ton and Bram are named in a line only.

### 5.4 Dialog self-check

As in the Acts 0–II scripts §9: layers in range, a lead-in, ≥ 2 `via` moves, ≥ 2 options that address the concern, and the listening route within patience. Checked by a script on the YAML blocks (all 11 pass the structural checks); the routes are worked by hand in each block's comment. The builder runs the spec's breadth-first search ("no golden path": ≥ 3 distinct successful sequences) first.

| Dialog | interest.at | concern.at | Concern options | Route / patience |
|---|---|---|---|---|
| frank_twenty | 55 | 72 | 2 | 8 / 10 (6 with history) |
| theo_calendar | 55 | 72 | 2 | 8 / 10 |
| rianne_audit | 52 | 72 | 2 | 9 / 10 |
| kees_meter_alarms | 55 | 72 | 2 | 7 / 10 |
| yvonne_theft | 55 | 72 | 2 | 7 / 9 |
| thomas_flex | 58 | 74 | 2 | 7 / 10 (8 without team trust) |
| monique_plan | 52 | 72 | 2 | 8 / 9 |
| harrie_gas | 55 | 70 | 2 | 7 / 9 |
| tim_platform | 55 | 72 | 2 | 8 / 10 (9 with the blame flag) |
| mieke_register | 55 | 72 | 2 | 7 / 10 (6 with history) |
| mark_debt | 55 | 72 | 2 | 7 / 9 |

---

## 6. New concepts (for `content/concepts.yaml`)

Most of tier 4's concepts already exist in `content/concepts.yaml`:
- `hoshin_kanri`, `x_matrix`, `nta_8120`, `gopacs`, `ii3050`;
- `transitievisie_warmte`, `team_topologies`, `technical_debt`, `dora_metrics`;
- `pareto`, `sustain`, `path_dependence`.

New ones, each with a Dutch `short` and `text` and a `source`, or `estimate:`:

| id | Category | Name (NL) | Source |
|---|---|---|---|
| `risk_based_maintenance` | lean | Onderhoud op risico | ISO 55001; NTA 8120 *(verify the version)* |
| `asset_health_index` | sector | De gezondheid van een kabel | Ofgem DNO Common Network Asset Indices Methodology (2017, *verify*); NN-CAM 5.0 (GDD) |
| `investeringsplan` | sector | Het investeringsplan van een netbeheerder | Elektriciteitswet 1998 art. 21 / Energiewet *(verify)* |
| `maatstafregulering` | sector | Hoe de ACM netbeheerders vergelijkt | ACM method decisions for regional grid operators *(verify the current period)* |
| `slimme_meter` | sector | Wat een slimme meter registreert | DSMR P1 companion standard (power-failure log) *(verify remote read-out)* |
| `goodhart` | measure | Als een maat een doel wordt | Goodhart (1975); Strathern (1997) |

---

## 7. What these drafts require from code

Beyond the catalogue (C1–C20), the tier-2 and tier-3 drafts (§6 and §7 there) and the dialog spec:
1. **Steps and pools (K8, K9):**
   - the new wait steps `outages.noticed` and `it_features.dependency`;
   - the `maintenance` stream;
   - the pools of §0.3;
   - places `msr.*`, `street.nova_west`, `obeya` (exists).
2. **The `audit` goal:**
   - it reads fix health (sustain design §1) on the deadline;
   - `findings` with `fact`, `missing` and `unless`, each with a reputation cost and an optional `major`;
   - `observations`.
3. **Per-track maturity in `requires`:** `{maturity: {it: 3}}` (catalogue C17d).
4. **Strategy goals:**
   - `forecast_check` (a stored forecast compared after N days, with two debrief variants);
   - `ramp_days` on a headcount effect (C17c);
   - `starts_after_days` on an effect;
   - the temptation option "Van alles een beetje", forecast as every unlocked option at 1/n.
5. **One `effects_if`:** `risk_based_maintenance` gets a stronger outage effect when `done:it_field_asset_data`. This is the only conditional effect in the draft. If the builder prefers no new field, the alternative is a small countermeasure `asset_register_feed` that `it_field_asset_data` unlocks, with the extra ×0.97.
6. **Countermeasures:** `needs_discount`, `release_gated` and `cost_per_week` (tier-3 §7), used again; `aftermath` with only `reputation` (an event, no effect).
7. **Dialog memory for lifted check-ins:** +5 (proposed here; the spec's memory table has +15 for a commitment). Also +10 for a third party's commitment (`monique_plan` reads `committed:frank_twenty`).
8. **Content tests:**
   - the fork honesty test (C15) for `t4_detect`, on `outages` lead time (correction 2);
   - the investment plan offers ≥ 4 options on the expert path and the baseline plus the temptation on the worst path;
   - the audit passes on the expert path and fails on a never-sustained path; its findings never change the verdict;
   - `it_field_asset_data` can be completed without waiting for a release (through `photo_to_gis_check`);
   - every dialog's listening route stays within patience (the Acts 0–II scripts §9 method).

---

## 8. Questions for Merijn: decided

**Decided 2026-10-15 by Merijn's standing rule** (PLAN.md Decisions, 19860ac): each question below takes its recommended option, (a) in **bold**. They are logged here so Merijn can overrule any of them.

1. **Where the chains meet.**
   - **(a) A new IT main, `it_field_asset_data`, where the field app feeds Act V's risk model (§2.3).**
   - (b) Keep the IT chapter separate from Act V, as in the catalogue.
   - *(a) makes the tier-3 field-app fix pay off in asset management, and teaches that data quality starts at the source.*
2. **The Act V fork's measure.**
   - **(a) Honest on outage minutes (lead time), since every fault is repaired and throughput equals demand (correction 2).**
   - (b) Rework it into a throughput fork on the monteurs pool.
   - *(a) is the KPI the ACM and the customer care about; (b) would need an artificial capacity limit.*
3. **The audit's findings.**
   - **(a) Earlier shortcuts surface as findings that cost reputation, never the verdict; the measure (fix health) decides.**
   - (b) Findings can fail the audit.
   - *(a) keeps "the simulation judges" and makes the temptations' cost visible without a hidden fail state.*
4. **The investment plan's temptation "Van alles een beetje".**
   - **(a) Always open, forecast honestly at 1/n.**
   - (b) Leave it out; the baseline is enough.
   - *(a) replays the hoshin lesson with money; a player who learned it recognises it.*
5. **A forecast check on the plan, half a year later.**
   - **(a) Yes: two debrief variants, neither a failure; D50 rewards a forecast that held.**
   - (b) No check.
   - *(a) makes "Measure" and PDCA reach the company's biggest decision.*
6. **Gas.** Voltana as a combined operator (as most Dutch regional operators are), with gas approximated without a stream.
   - **(a) Keep the catalogue's `gas_phaseout` side, with a `gas_monteurs` pool and Harrie's retraining.**
   - (b) Drop gas; Voltana stays electricity only.
   - *(a) brings the heat transition and a respect story (a 59-year-old who learns a new trade); (b) is simpler.*
7. **Safety in the theft mission.**
   - **(a) The temptation sends meter technicians alone; it never pays (a threat event, D48 closed), and the best countermeasures are joint checks and a "never alone" rule.**
   - (b) Leave field safety out of the theft mission.
   - *Theft is a money problem until you meet the person who would knock on the door.*
8. **Memory for lifted walk-around check-ins.**
   - **(a) +5 to that person's later dialogs.**
   - (b) No memory.
   - *(a) makes a two-minute walk-around talk matter two acts later, without making it a duty (no loss for skipping).*
9. **The new cast** (Theo, Rianne, Monique, Harrie, Tim).
   - **(a) Keep.**
   - (b) Reuse existing people for these roles.
   - *Each fills a role no one in the cast holds, and each worry is the mission's real obstacle.*

---

## Sources

- Netbeheer Nederland — *Integrale Infrastructuurverkenning 2030–2050* (II3050), 2023 update: https://www.netbeheernederland.nl/ (*verify the exact page*)
- Netbeheer Nederland — *Betrouwbaarheid van elektriciteitsnetten in Nederland* (yearly; outage minutes and causes) (*verify the year*)
- NTA 8120 and the ministerial regulation on quality aspects of grid management (*verify the current version and article*)
- ISO 55001:2014, *Asset management — Management systems — Requirements*
- Ofgem — *DNO Common Network Asset Indices Methodology* (2017) (*verify*)
- ACM — congestion-management code decision (2022) and yardstick regulation method decisions (*verify*)
- GOPACS: https://www.gopacs.eu/
- Elektriciteitswet 1998 art. 21 (investment plan) and the Energiewet (*verify the successor article*)
- DutchNews (2019) on electricity theft (~1 billion kWh a year), in the GDD
- DSMR P1 companion standard (power-failure counters and log) (*verify remote read-out by the grid operator*)
- Klimaatakkoord / Wet gemeentelijke instrumenten warmtetransitie (Transitievisie Warmte) (*verify*)
- Books and papers:
  - Akao, *Hoshin Kanri* (1991);
  - Jackson, *Hoshin Kanri for the Lean Enterprise* (2006);
  - Rother, *Toyota Kata* (2009);
  - Skelton & Pais, *Team Topologies* (2019);
  - Reinertsen, *The Principles of Product Development Flow* (2009);
  - Forsgren, Humble & Kim, *Accelerate* (2018);
  - Cunningham, "The WyCash Portfolio Management System" (OOPSLA 1992);
  - Tornhill, *Your Code as a Crime Scene* (2015);
  - Spolsky, "Things You Should Never Do, Part I" (2000);
  - Goodhart (1975);
  - Strathern, "Improving ratings" (1997);
  - EEMUA 191, alarm management (*verify edition*).
