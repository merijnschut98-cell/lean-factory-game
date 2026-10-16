# Tier-3 missions — content-ready drafts (Act IV and the parallel IT track)

> Status: drafts by the mission and dialog design agent (Claude, 2026-10-15), for Merijn to review. **Not** in `content/` yet. Each block is ready to paste into `content/missions.yaml`, `content/problems_tier3.yaml`, `content/problems_it.yaml`, `content/countermeasures.yaml`, `content/dialogs.yaml` and `content/people.yaml` once the catalogue's schema (C1–C20), the area and IT streams (K6, K9) and the dialog engine (dialog spec D1–D5) exist.
>
> Read with: `CLAUDE.md` §2; PLAN.md "Decisions Made" (tier-3 areas sit inside Zuidmark; IT runs in parallel from tier 3; path dependence); the catalogue `2026-10-15-mission-system-and-catalogue-design.md` §2.14–2.15, §3.6, §3.8; the audit `2026-10-15-mission-audit-and-engagement.md`; the tier-2 draft `2026-10-15-tier2-missions-draft.md` (its format, `principles` and `temptations` fields, and the facts it sets); the dialog spec and `2026-10-15-dialog-scripts-act0-2.md` (the schema and the voices).

## 0. What this covers and how to read it

**Scope.** 28 tier-3 missions, plus two drafts kept ready for tier 4:
- **Act IV, "Flow door de regio" (18):** the catalogue's 16 tier-3 missions, two of them re-scoped (§0.2), plus two additions:
  - `fix_household_rush`: households on the waiting list since 1 July 2026;
  - `repair_long_drives`: a worked repair quest.
- **The IT track's tier-3 chapter, "De app die niemand gebruikt" (10):** the catalogue's Act VI opening, as decided (field app first), running in parallel with Act IV from `t3_map_region` on:
  - the field app the monteurs bypass;
  - the release train;
  - test environments, regression and PI planning.
- **Two drafts for the tier-4 IT chapter (§2.8):** the customer portal and the meter-data platform, Merijn's other examples. They follow later.

Tier 3 brings **16 new problems**, **57 countermeasures**, **20 persuasion dialogs**, two expert topic sets and one coaching script; the tier-4 drafts add 2 problems, 6 countermeasures and 2 dialogs.

**Every mission names:**
- the **principle** it tests (`principles`: `long_term`, `respect`, `improve`, as in the tier-2 draft);
- a **tempting shortcut** that works now and costs later (`temptations`, or a countermeasure with an `aftermath`), with the later cost named in "Path dependence";
- the **dialogs** it needs. They use the schema of the Acts 0–II scripts, in a shorter form: the voice, the layers, the proposals and one route. The builder adds the bank lines.

**The 1 + 3 rule** holds throughout:
- Act IV and the IT chapter are two main chains. The player holds **one** main at a time and picks which chain to advance: prioritising, not a fork.
- At most three sides. Milestones take no slot.
- The coach coaches only the active main, IT or grid.

**Conventions** as in the tier-2 draft:
- Dutch game text; English ids, keys and comments.
- Every number is sourced, or marked `estimate:` with its reasoning.
- Facts that could not be checked at the source carry **(verify)**.
- Effects use only today's `EFFECT_PROPERTIES` (`touch_time`, `ftr`, `applies`, `wait_time`, `availability`, `headcount`, `demand`, `batch_days`, `starts_with`, `call_rate`, `wip_limit`, …).
- Effects target the new area and IT streams of §0.3, so they can only be run through `validate_problems` and `_check_problem` once K6 and K9 exist.

### 0.1 Schema this draft assumes

Everything the tier-2 draft assumes (§0.1 there: `principles`, `temptations`, `aftermath`, `trust` on countermeasures, `containment`, `npc_experiment`, `strategy` options with `needs` and `preparation`), plus:

| Field | On | Meaning | Why |
|---|---|---|---|
| `areas` | `map_stream` goal | The areas whose steps must be measured (`nova`, `lindeveld`, `havenzij`) | One map for a region with three areas (catalogue §2.14). |
| `cleared_by` | a flag, in `content/flags.yaml` (new, small) | `flag:lindeveld_overtime: {cleared_by: [repaired:long_drives]}`: a repair clears the flags its problem's temptation set | "Repair side quests reopen options" needs the flag to go, not only `poor_fix`. C19's `needs` grammar has no "A unless B"; this keeps it flat. |
| `needs_discount` | countermeasure | `{needs, budget: f, team_hours: f}`: cheaper when a fact is set | Rewards an earlier respectful choice without making a second countermeasure (`train_the_trainer` with Ahmed). |
| `track` | problem, mission | `grid` (default) or `it` | Catalogue C17d: IT has its own maturity. |
| `release_gated` | countermeasure (IT) | `true`: its effect starts at the stream's next release, not at the Act | A fix in code reaches the customer only when it ships. This is the IT chapter's central twist (§2.2). |

### 0.2 Corrections to the catalogue found while grounding

1. **Prioritisation is no longer "first come, first served".** The catalogue's `priority_first_come` assumes the queue is still in date order. In reality:
   - the ACM's prioritisation framework was annulled by the CBb on 11 March 2025 (ECLI:NL:CBB:2025:145) but kept in force until 1 January 2026;
   - a renewed framework applies since 1 January 2026;
   - since 1 July 2026 households in congestion areas join the same list.

   The realistic 2026 problem is the framework applied **by hand and on request**: eligible applicants (care, schools) do not know they must ask, and one account manager classifies in his spare time. The mission is renamed **"Wie gaat er voor?"**; its id is kept.
2. **Households on the waiting list (new).** From 1 July 2026, small consumers up to 3x80A in congestion areas join the queue, with a transition period for heavier connections until 1 January 2027. Grid operators received about five times as many connection requests as a year earlier, and they stress that many heat pumps and chargers work on the existing connection. This is a real, current sector problem at Voltana's front door: `fix_household_rush` (side).
3. **Nitrogen.** After the Porthos ruling (Raad van State, 2 November 2022) the construction exemption is gone; every grid-expansion project needs its own nitrogen assessment, which Netbeheer Nederland estimated could add about two years to permitting. The catalogue's +90 days of wait is a conservative estimate for one substation and is kept.
4. **Cable pooling** is allowed only for wind and solar parks near each other, behind a connection above 2 MVA, applying together (art. 1(7) Elektriciteitswet 1998, carried into the Energiewet: *verify the article*). Storage and consumers are not yet allowed. The solar-field mission keeps to this.
5. **Energy hubs** run on a *groepstransportovereenkomst* (GTO). In 2025 it was an ACM draft code decision with pilots (Liander, Deventer A1); *verify its final status*. The energy-hub side quest calls it a pilot.
6. **The technician shortage's bottleneck is training.** Grid operators and contractors plan 5,000 extra technicians in five years (Climate Fund subsidy €25M); the biggest constraint named is training and supervision capacity, organised in 6–7 regions with ROCs. This grounds `training_capacity` as a constraint on *teaching*, not on applicants.
7. **The IT track's order (decided 2026-10-15): the field app first, as in the catalogue.** I had proposed starting at the customer (the portal and the meter-data platform); Merijn chose the catalogue's order.
   - Tier 3 holds: `it_map_feature_stream` (re-anchored on the field app), `fix_field_app_bypassed`, `fix_release_twice_a_year`, the fork `fix_test_env_queue` (B) / `fix_code_review_wait` (N), `fix_manual_regression`, `fix_pi_overcommit`, `fix_ops_dev_wall`, `talk_rte`, `lsw_system_demo`.
   - The customer portal (`fix_status_page_wrong`) and the meter-data platform (`fix_meter_data_mandates`) are kept as ready drafts for the tier-4 IT chapter (§2.8). The catalogue's `fix_team_dependencies`, `fix_tech_debt` and `it_dora_metrics` stay in tier 4 too.
8. **The Havenzij fork must be a throughput fork.** In the catalogue, `underground_crowding` (B) is mostly a permit *wait*, and a wait adds lead time, not a capacity limit (audit L1). Here its harm sits at Havenzij's design step, the area's constraint: route puzzles and redesigns. `uneven_release` (N) is a batch at a wait step. So the fork honesty test (C15) compares throughput, and the non-bottleneck debrief names its lead-time gain.

### 0.3 Area and IT content the drafts need (for K6 and K9)

All numbers are **estimates**, sized so that no team is above 85 % in the base (the K6 rule). The builder calibrates them with the problem report.

**Pools (new):**

| id | Name (NL) | Headcount | Availability | Notes |
|---|---|---|---|---|
| `lv_monteurs` | Monteurs Lindeveld | 5 | 0.85 | Joke van Beek's team; today they start in Nova |
| `hz_monteurs` | Monteurs Havenzij | 6 | 0.85 | |
| `hz_work_prep` | Werkvoorbereiding Havenzij | 3 | 0.85 | Yusuf Demir's team; the area's constraint |
| `trainers` | Opleidingscentrum | 4 | 0.9 | Patrick Smeets's instructors; feeds the C17c headcount ramp |
| `app_team` | Team Veldapp | 6 | 0.85 | One of the ART's teams, with PO Noor Hendriks |
| `platform_team` | Team Werkorderplatform | 6 | 0.85 | The work-order system behind the field app |
| `portal_team`, `data_team` | Team Klantportaal, Team Meetdata | 6 each | 0.85 | Tier 4 (§2.8); in the ART from the start, but not the player's focus in tier 3 |
| `testers` | Testers | 3 | 0.85 | |
| `test_envs` | Testomgevingen | 2 | 1.0 | Environments modelled as a pool: two shared by the ART's teams |
| `ops` | Beheer (IT operations) | 4 | 0.9 | |
| `data_desk` | Mandaten & datalevering | 1 | 0.85 | Tier 4 (§2.8): one person checks mandates by hand |

**Streams (new):**

| id | Units | Steps (pool or wait) | Arrivals (estimate) |
|---|---|---|---|
| `lv_connections` | connection requests in Lindeveld | intake (`intake`) → design (`work_prep`) → planning (`planners`) → execution (`lv_monteurs`) → commissioning (`lv_monteurs`) → close_out (`meter_office`) | 6 a week: a rural area of about a fifth of Nova's connections, with farms and solar |
| `lv_feedin` | feed-in requests (solar fields) | request (`key_accounts`) → study (`grid_analysts`) → capacity_queue (wait) → offer (`key_accounts`) → connect (`lv_monteurs`) | 1 a month |
| `hz_connections` | connection requests in Havenzij | release (wait: developers' batches) → intake (`intake`) → design (`hz_work_prep`) → permit (wait, 14 d) → planning (`planners`) → execution (`hz_monteurs`) → close_out (`meter_office`) | 8 a week |
| `hz_reinforcement` | grid reinforcements (Havenzij substation and MS ring) | study (`grid_analysts`) → design (`work_prep`) → nature_permit (wait, 60 d) → build (wait: contractor, 40 d) | 1 every 2 months |
| `it_features` | changes to the field app and the work-order platform (from tier 4 also the portal and the meter-data platform) | idea (wait) → refine (`app_team`) → build (`app_team`) → review (`app_team`) → test (`test_envs` + `testers`) → release (wait, `batch_days`) → in_use (wait) | 5 a week |
| `it_incidents` | IT incidents | report (`ops`) → triage (`ops`) → fix (`platform_team`) → deploy (`ops`) | 4 a week |
| `meter_data` (tier 4) | requests for meter data under a customer mandate (P4) | request (wait) → mandate_check (`data_desk`) → deliver (wait: nightly) | 60 a week |

**Places** for the gemba tools follow the steps (`lv_connections.execution` is the depot yard in Oosthoek; `it_features.test` is the test room). The IT campus is one floor of the existing office building (the catalogue's `it_campus` unlock).

**New cast for tier 3** (voice sheet in §5; dialogs with each mission):
- Lindeveld: Joke van Beek (TL monteurs).
- The training centre: Patrick Smeets (head of the Opleidingscentrum).
- Havenzij:
  - Yusuf Demir (TL Werkvoorbereiding);
  - Marloes Kramer (coördinator ondergrondse infrastructuur, gemeente Havenzij);
  - Dennis Wouters (vergunningenadviseur).
- Outside parties:
  - Sjaak van Rooij (installer);
  - Mohammed Aziz (facility manager, ColdChain Havenzij);
  - the Verhoeven family (Zonnepark De Hoge Akker);
  - Kanaalzone Waterstof (KZW).
- IT and the business:
  - Priya Ramdin (infra engineer, Beheer);
  - Mark van Leeuwen (developer);
  - Erwin de Groot (release manager, CAB chair);
  - Hanneke Willems (senior tester);
  - Carla Wijnands (directeur Klant & Markt, the ART's business owner);
  - Bart Jacobs (ops engineer);
  - Lisette Koster (functionaris gegevensbescherming; tier 4, §2.8).
- From the catalogue and earlier tiers: Noor Hendriks (PO veldapp, as in the catalogue), Bas Kuipers (RTE), and Ricardo (monteur, Marco's team; admin of the WhatsApp group).

---

## 1. Act IV — Flow door de regio (tier 3)

Gates: `t2_first_okr`, maturity 3, belt black (3), reputation ≥ 50.

**Chapters:**
- **Eén regio:** map the region, the long drives, the training centre, the crew strategy.
- **Havenzij:** the fork, then the kaizen week.
- **Wie gaat er voor?:** prioritisation, the household rush, nitrogen.
- **Stoppen met starten:** CONWIP and holding it.

The act's cliffhanger in (from Act III): Joke's call, "Bij ons rijden ze een uur per klus. En er gaan er drie met pensioen."

### 1.1 `t3_map_region` — Eén regio, drie gebieden (M)

Principles tested: **improve** (see before you act) and **respect** (walk with the people whose work it is). Temptation: a bought value stream map.

```yaml
missions:
  - id: t3_map_region
    name: Eén regio, drie gebieden
    kind: main
    tier: 3
    act: 4
    chapter: Eén regio
    requires: {missions: [t2_first_okr], belt: 3, maturity: 3, reputation: 50}
    goal: {type: map_stream, stream: connections, measure: queue_count, areas: [nova, lindeveld, havenzij]}
    principles: [improve, respect]
    briefing: "Ruud vraagt je de verbetering voor heel Zuidmark te trekken: Nova, het platteland van Lindeveld en de havenstad Havenzij. Joke van Beek, teamleider monteurs in Lindeveld, belde al: 'Bij ons rijden ze een uur per klus.' In Havenzij zegt Yusuf Demir dat zijn tekenaars 'meer puzzelen dan tekenen'. Loop de aansluitstroom in alle drie de gebieden en tel bij elke stap wat er ligt. Wat in Nova klopt, klopt misschien niet in Lindeveld."
    debrief: "Drie gebieden, drie verschillende knelpunten. In Nova ligt het werk {nova_days} dagen bij {nova_constraint}. In Lindeveld zit het niet in een bak, maar in de bus. In Havenzij ligt het bij Yusufs tekenaars. Het MT kijkt naar één getal voor heel Zuidmark. Wat verbergt dat getal?"
    beats:
      - {on: accepted, who: ruud, text: "Hoofdstuk vier: Flow door de regio. Wat in Nova werkte, is geen recept. Het is een vraag die je in Lindeveld opnieuw stelt."}
      - {on: completed, who: joke, text: "Je bent de eerste van het hoofdkantoor die bij ons in de bus heeft gezeten. Dat vergeten ze hier niet."}
    temptations:
      - id: bought_vsm
        who: consultant
        when: accepted
        text: "Wij hebben de waardestroom bij drie netbeheerders in kaart gebracht. Over twee weken heeft u een complete VSM van Zuidmark, met gemiddelden per stap. U hoeft er de deur niet voor uit."
        accept: "Je laat het bureau de waardestroom in kaart brengen."
        decline: "Je loopt zelf mee, gebied voor gebied."
        accept_sets_flags: [flag:vsm_bought]
        accept_effects: {complete_goal: true, cost: 18000, trust: {lv_monteurs: -1, hz_work_prep: -1}}
    teaches: [value_stream_mapping, gemba, bottleneck_focus]
    rewards: {xp: 2600, budget: 20000, reputation: 5, unlocks: [vsm_view, region_lindeveld, region_havenzij, it_campus]}
    insights:
      go_see: "Wat zie je in Lindeveld dat je in Nova nooit had gezien?"
      understand: "Is Zuidmark één stroom, of drie? Wat betekent dat voor waar je begint?"
      experiment: "Welk getal wil je per gebied volgen? Waarom niet één gemiddelde?"
      reflect: "Wie in Lindeveld of Havenzij liet je iets zien wat in geen rapport staat?"
```

**Drie winters (2026-10-16).** `t3_map_region` now requires `t3_interim_mt` (Frank's first MT as interim director). Under `flag:interim_regime` it gets a briefing variant and its temptation is `t3_consultants` (Lean-programma 2.0, offered by Frank) instead of `bought_vsm`; under `flag:strategy_early` (sponsor, committed) it also unlocks the strategy screen. Ruud coaches by phone (one Kata cycle per 28 days). See `2026-10-16-drie-winters-arc.md` §5 and §7.

**Path dependence.**
- `flag:vsm_bought` is the quick win. The goal completes at once, but:
  - the VSM view shows regional *averages*, so Lindeveld's travel and Havenzij's design puzzle disappear into one number;
  - `fix_long_drives`'s depth-0 key clue moves to depth 1;
  - Joke and Yusuf start every dialog in this act at team trust −1 (−10 openness).
- The way back: `lsw_gemba_round` done twice in each area clears the flag's effects (`cleared_by`). The player still walks, only later.

**Grounding.** Value stream mapping by walking: Rother & Shook, *Learning to See* (1999). Averages hiding the constraint: the existing `bottleneck_focus` concept. The €18,000 is an estimate: two consultants for two weeks.

**Engrossing.**
- The first time the player sees the region, and the first time the shortcut is a respectable one: the consultant is competent.
- The cost is invisible on the day you pay it. You feel it when Joke opens her first talk with "Hebben jullie dat rapport nog?".

### 1.2 `fix_long_drives` — Een uur rijden per klus (M)

Principles tested: **respect** (freed time is not a reason to fill every minute) and **long_term**. Temptation: a travel allowance, which pays people *for* the waste.

```yaml
missions:
  - id: fix_long_drives
    name: Een uur rijden per klus
    kind: main
    tier: 3
    act: 4
    chapter: Eén regio
    requires: {missions: [t3_map_region]}
    goal: {type: solve, problem: long_drives}
    principles: [respect, long_term]
    briefing: "In Lindeveld kost een aansluiting een monteur ruim zes uur, in Nova vijf. Joke van Beeks monteurs beginnen elke ochtend in het depot in Nova en rijden naar boerderijen, zonneweides en dorpen tot veertig kilometer verderop. 'We zijn een uur per klus kwijt,' zegt Joke, 'en dan heb ik het nog niet over de keren dat er iets in Nova ligt.'"
    debrief: "Een klus in Lindeveld kost nu {touch_after} uur in plaats van {touch_before}. De bus rijdt minder en de monteur werkt meer. Joke: 'Ik dacht dat jullie ons wilden wegbezuinigen. Jullie wilden ons dichterbij.' Wat doen haar mensen met het uur dat vrijkwam?"
    debrief_variants:
      poor_fix: "Er ligt nu meer in de bussen, dus er wordt minder naar Nova gereden voor materiaal. Maar elke ochtend beginnen ze nog veertig kilometer van het werk. Joke: 'Het is beter. Het is nog niet goed.'"
    reopen: "In Lindeveld wordt weer meer gereden. Het depot staat er nog, maar de planning stuurt de klussen weer op volgorde van binnenkomst."
    beats:
      - {on: accepted, who: joke, text: "Kom morgen om zes uur naar het depot. Dan rijden we samen. Neem koffie mee, het is ver."}
      - {on: completed, who: marco, text: "Lindeveld heeft een depot. Mooi. Dan wil ik ook weten waarom mijn mannen in Nova nog door de stad crossen."}
    temptations:
      - id: travel_allowance
        who: joke
        when: accepted
        text: "Weet je wat ook helpt? Geef mijn mannen een reistijdvergoeding. Een uur per dag. Dan klagen ze niet meer, en jij bent er vanaf."
        accept: "Je regelt een reistijdvergoeding voor de monteurs in Lindeveld."
        decline: "Je zegt Joke dat je liever het rijden zelf aanpakt dan het betaalt."
        accept_sets_flags: [flag:lindeveld_allowance]
        accept_effects: {trust: {lv_monteurs: 1}, cost_per_week: 1100}
    teaches: [waste_transport, capacity_planning]
    rewards: {xp: 2800, budget: 25000, reputation: 5, trust: {lv_monteurs: 1}}
    insights:
      go_see: "Hoeveel van een werkdag in Lindeveld zit een monteur in de bus? Heb je dat zelf gemeten?"
      understand: "Waarom begint elke klus in Nova? Wie heeft dat ooit besloten, en wanneer?"
      experiment: "Als een monteur een uur minder rijdt, wat doet hij dan met dat uur? Wat wil jij, en wat wil hij zelf?"
      reflect: "Wat is in Lindeveld anders dan in Nova, en wat neem je daarvan mee naar Havenzij?"

problems:
  - id: long_drives
    tier: 3
    name: Een uur rijden per klus
    step: lv_connections.execution
    waste: transport
    severity: high
    visibility: subtle
    kpi: throughput
    symptoms:
      - Een aansluiting in Lindeveld kost een monteur ruim zes uur; in Nova vijf.
      - De monteurs in Lindeveld rijden meer kilometers dan de rest van Voltana bij elkaar.
    root_cause: Alle klussen in Lindeveld worden vanuit het depot in Nova gepland, op volgorde van binnenkomst en zonder te kijken waar ze liggen. Monteurs rijden kriskras door het gebied en terug naar Nova voor materiaal. Sinds de uitvalsbasis in Oosthoek in 2011 dichtging, heeft het gebied geen startplek en geen voorraad.
    plausible_causes:
      - De monteurs in Lindeveld werken langzamer.
      - Het platteland is nu eenmaal groot; daar valt niets aan te doen.
      - De wegen in Lindeveld zijn slecht.
    mismatch_note: Sneller werken of rijden helpt niet zolang elke dag in Nova begint en de klussen niet per gebied worden gebundeld.
    countermeasures: {satellite_depot: 1.0, area_day_routing: 0.8, mobile_van_stock: 0.6, outsource_area: 0.6}
    teaches: [waste_transport, capacity_planning]
    effects:
      # estimate: a 5-hour job plus ~75 minutes of extra driving (two legs of ~35 km at rural speeds,
      # one material run in three jobs) = x1.25 touch time at execution.
      - {target: lv_connections.execution, property: touch_time, value: 1.25}
    # estimate: 6 jobs a week x 1.25 h x EUR 75/h (audit §2.3) + ~500 extra km x EUR 0.50 = ~EUR 810
    cost_per_week: 800
    clues:
      - {tool: time_study, key: true, depth: 0, text: "Een aansluiting in Lindeveld kost een monteur ruim zes uur van vertrek tot terugkomst. Het werk aan de meterkast zelf duurt even lang als in Nova."}
      - {tool: queue_count, key: false, depth: 0, at: lv_connections.planning, text: "Op het planbord van Lindeveld liggen weinig klussen te wachten. Het werk gaat snel de deur uit."}
      - {tool: shadow, key: true, depth: 1, text: "Om 7.10 uur vertrekt de bus uit Nova. De eerste klus ligt 38 kilometer noordelijk, de tweede 31 kilometer terug naar het zuiden, de derde weer in het noorden. Om één uur rijdt de monteur naar Nova voor een kabelmof."}
      - {tool: data, key: true, depth: 1, at: lv_connections.planning, text: "Lindeveldse klussen worden ingepland op volgorde van binnenkomst. Klussen in hetzelfde dorp liggen gemiddeld negen dagen uit elkaar."}
      - {tool: conversation, key: false, depth: 1, text: "'Die wegen hier zijn een ramp. Achter een tractor kom je nergens.'"}
      - {tool: material_check, key: true, depth: 2, text: "In de bussen van Lindeveld ligt dezelfde voorraad als in Nova: veel huisaansluitmateriaal, weinig grondkabel voor erven. Wat ontbreekt, ligt in Nova."}
      - {tool: conversation, key: true, depth: 2, at: lv_connections.execution, text: "'Vroeger hadden we een schuur in Oosthoek, met een stelling erin. In 2011 ging hij dicht. Bezuiniging. Sindsdien beginnen we in Nova.'"}

countermeasures:
  - id: satellite_depot
    name: Een uitvalsbasis in Lindeveld
    tier: 3
    category: flow
    description: Een kleine uitvalsbasis in Oosthoek, met een stelling materiaal voor het platteland en een plek voor de bussen. De monteurs beginnen en eindigen in het gebied, en de planning bundelt de klussen per dorp.
    budget: 60000   # estimate: a year's rent of a small hall, racking and a starting stock
    team_hours: {lv_monteurs: 40, planners: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: lv_connections.execution, property: touch_time, value: 0.95}   # estimate: also the base's own detours
  - id: area_day_routing
    name: Vaste dagen per deelgebied
    tier: 2
    category: flow
    description: Lindeveld wordt in vier deelgebieden verdeeld, elk met vaste dagen. Klussen in hetzelfde dorp gaan samen. Een klant wacht soms een paar dagen langer op 'zijn' dag.
    budget: 3000
    team_hours: {planners: 20}
    decay_days: 60
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: lv_connections.planning, property: wait_time, value: 1.1}   # estimate: the honest price, a few days' wait for the area's day
  - id: mobile_van_stock
    name: Meer voorraad in de bus
    tier: 2
    category: workplace_organization
    description: Elke bus in Lindeveld krijgt een grotere voorraad, zodat er minder naar Nova wordt gereden voor materiaal. De rit 's ochtends blijft.
    budget: 8000
    team_hours: {lv_monteurs: 10}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: outsource_area
    name: Het aansluitwerk in Lindeveld uitbesteden
    tier: 1
    category: people
    description: Een aannemer uit de streek neemt het aansluitwerk in Lindeveld over. Voltana's monteurs daar gaan andere klussen doen.
    budget: 5000
    team_hours: {planners: 15}
    decay_days: 180
    trust: {lv_monteurs: -2}
    aftermath:
      after_days: 7
      days: 84
      effects:
        - {target: lv_connections.execution, property: ftr, value: -0.1}   # estimate: a new contractor learns Voltana's standard
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialog: `joke_depot`.** Joke wants the depot, but she resists what "efficiënter" will mean for her people.

```yaml
dialogs:
  - id: joke_depot
    person: joke
    kind: persuade
    mission: fix_long_drives
    owns: long_drives
    patience: 10
    # start: defender 40 + 0 + 0 (team lv_monteurs; -10 if flag:vsm_bought) + 0 + 0 = 40, Luistert
    opening: "Zes uur 's ochtends en je bent er. Dat had ik niet gedacht. Koffie zit in de thermos."
    position: {text: "Geef ons een plek in Lindeveld. Dan zijn we dat uur kwijt.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Mijn mannen zitten twee uur per dag in de bus. Vier op vrijdag, als er iets in Nova ligt. Ze zien hun eigen dorp alleen 's avonds."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [silence, empathy, reflect, inquiry]
        lead_in: {text: "Alleen, kijk…", tags: [hesitation]}
        text: "Dat uur in de bus is ook hun pauze. Hun telefoon naar huis. Hun rust na een put in de regen. Als ze straks om de hoek beginnen, zitten ze acht uur onder de grond. Ik wil niet dat 'efficiënter' betekent dat ze kapotgaan."
        tags: [admission]
        unlocks: {facts: [heard:joke_hour], proposals: [half_hour_for_training]}
    reframe: "Vanuit de boer die zijn melkrobot niet aan de praat krijgt? Die ziet om tien uur een bus wegrijden naar het noorden en om twaalf weer langskomen. Ja. Dat is raar."
    warning: "Als je komt vertellen hoe het moet, kun je terugrijden."
    data: ["long_drives:0", "long_drives:3"]
    proposals:
      - {id: depot_in_oosthoek, addresses: [interest], label: "Een uitvalsbasis in Oosthoek", say: "Een uitvalsbasis in Oosthoek, met materiaal voor het platteland.", reply: "Oosthoek. Daar stond de oude schuur. Ja."}
      - {id: half_hour_for_training, hidden: true, addresses: [concern], label: "Het vrije uur: half werk, half opleiden", say: "Wat als het uur dat vrijkomt niet helemaal naar klussen gaat? De helft naar klussen, de helft naar het meenemen van de nieuwe jongens.", reply: "De nieuwe jongens. Daar hebben we nu nooit tijd voor. Ja. Dat is iets anders dan acht uur onder de grond."}
    experiments:
      - {id: team_sets_the_day, addresses: [concern], label: "Het team bepaalt de dag", say: "Probeer het een maand, en laat jouw mannen zelf de dagindeling maken, met pauze en al.", reply: "Zelf. Dan weet ik dat er een pauze in zit."}
    co_proposal: {id: half_hour_for_training, text: "En als we het uur nou deels gebruiken om de nieuwe jongens mee te nemen? Daar hebben we nu nooit tijd voor."}
    outcomes:
      commitment: "Afgesproken. En ik wil die schuur zelf uitkiezen."
      partial: "Ik wil het wel. Als het uur niet meteen weer vol wordt gepland."
      heard: "Fijn dat je meereed. Echt."
      compliance: "Komt er een schuur. Goed. Wij rijden er wel heen."
      ruined: "Kom maar terug als je weet hoe ver Lindeveld is."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose half_hour_for_training +8 87 > ask: commitment (7 moves)
    # Path dependence: heard:joke_hour + this commitment makes fix_training_capacity's hybrid_crews cheaper in Lindeveld (needs_discount).
```

**Path dependence.**
- `chose:long_drives:satellite_depot` (or `repaired:long_drives`) unlocks the crew strategy's *Lindeveld satellite crew* (§1.4) and, in Act V, `t4_investment_plan`'s "Meer monteurs in Lindeveld".
- `chose:long_drives:mobile_van_stock` is a poor fix (fit 0.4 below the best). It sets `poor_fix:long_drives`, and `repair_long_drives` opens 42 days later, once the gap shows in Lindeveld's throughput (§1.13).
- `chose:long_drives:outsource_area` locks the Lindeveld crew option. It is also a poor fix: the repair quest is the way back ("De mannen terughalen").
- The `travel_allowance` temptation (`flag:lindeveld_allowance`) costs €1,100 a week and becomes an entitlement. When a later depot removes the drive, the allowance goes, and `lv_monteurs` trust falls by 2. It is cleared by `repaired:long_drives`, where Joke and her team trade it for the depot themselves.

**Grounding.**
- Travel as transport waste in field service: audit L11.
- The €75/h monteur cost: audit §2.3 (estimate).
- The x1.25 and the 2011 closure are estimates and fiction, with their reasoning in the YAML comments.
- The area-day trade-off (a few days' wait for "your day") is a real routing dilemma between efficiency and first-in-first-out, labelled honestly in the countermeasure.

**Engrossing.**
- A 6 a.m. ride with a person.
- The herring "de wegen zijn slecht" is true and irrelevant.
- The twist is that removing waste raises a respect question: freed time is not a reason to fill every minute (Joke's concern).

### 1.3 `fix_training_capacity` — Het opleidingscentrum zit vol (M, deadline)

Principles tested: **respect** (develop people rather than buy them in) and **long_term**. Temptation: hire freelance monteurs at a premium.

```yaml
missions:
  - id: fix_training_capacity
    name: Het opleidingscentrum zit vol
    kind: main
    tier: 3
    act: 4
    chapter: Eén regio
    requires: {missions: [fix_long_drives]}
    goal: {type: solve, problem: training_capacity}
    deadline_days: 63
    fail: "De septembergroep is begonnen zonder extra plekken. Twaalf aankomend monteurs dit jaar, net als vorig jaar. De extra groep kan pas volgend jaar. Wat er nu met de mensen gebeurt die er al zijn, bepaal je nog wel."
    fail_closes: [apprentice_cohort_september]
    fail_effects: {reputation: -10}
    principles: [respect, long_term]
    briefing: "Er staan zeven vacatures voor monteurs open, sommige al sinds de winter. Aanmeldingen voor de opleiding zijn er genoeg: het opleidingscentrum neemt er twaalf per jaar aan en wijst de rest af. In september begint de nieuwe groep. Patrick Smeets, hoofd van het opleidingscentrum, zegt dat er niet meer bij kunnen. Je hebt negen weken."
    debrief: "In september begonnen er {cohort_size} aankomend monteurs in plaats van twaalf. {trainer_line} Over een jaar staan ze zelfstandig op straat. Dat is geen snelle winst; het is de enige die blijft."
    debrief_variants:
      poor_fix: "De zzp'ers rijden. Het werk gaat door. Maar over een jaar zijn ze weg, en de jongens die ze hadden kunnen opleiden ook."
    reopen: "De leermeesters hebben het weer te druk met hun eigen klussen. De nieuwe jongens kijken toe in plaats van te doen."
    beats:
      - {on: accepted, who: patrick, text: "Vier instructeurs, zes cursisten per instructeur op het oefenterrein. Meer is niet veilig. Reken het maar na."}
      - {on: day, day: 42, who: ruud, text: "Over drie weken begint de septembergroep. Wat ligt er dan klaar?"}
      - {on: completed, who: ahmed, text: "Ik heb er vandaag twee mee. Ze stellen dezelfde vragen als ik vroeger. Grappig."}
    temptations:
      - id: hire_freelancers
        who: inkoop
        when: accepted
        text: "Een bureau heeft acht ervaren zzp-monteurs beschikbaar. Volgende week op straat. Iets duurder, maar dan is je probleem weg."
        accept: "Je huurt acht zzp-monteurs in."
        decline: "Je investeert in het opleiden van eigen mensen."
        accept_sets_flags: [flag:freelance_crews]
        accept_effects: {cost_per_week: 4800, trust: {monteurs: -1}}
    teaches: [monteurstekort, respect_for_people, twi_job_instruction]
    rewards: {xp: 3000, budget: 25000, reputation: 5, trust: {monteurs: 1}}
    insights:
      go_see: "Waar zit de grens precies: bij de aanmeldingen, bij de instructeurs, of bij de leermeesters op straat?"
      understand: "Hoe lang duurt het voordat een nieuwe monteur zelfstandig werkt? Waar zit dat verschil tussen de snelste en de langzaamste?"
      experiment: "Als je dit experiment doet, hoeveel extra monteurs verwacht je over een jaar? Hoe zie je dat nu al?"
      reflect: "Wie heeft jou ooit iets geleerd waar je nog steeds op leunt? Hoe deed hij dat?"

problems:
  - id: training_capacity
    tier: 3
    name: Het opleidingscentrum zit vol
    step: monteurs                      # a pool-level problem (catalogue: needs the C17c headcount ramp)
    waste: skills
    severity: high
    visibility: subtle
    kpi: capacity
    symptoms:
      - Zeven vacatures voor monteurs staan maandenlang open.
      - Het opleidingscentrum neemt twaalf aankomend monteurs per jaar aan en wijst er meer af dan het aanneemt.
    root_cause: De opleiding is een knelpunt, maar niet bij de aanmeldingen. Het oefenterrein heeft vier instructeurs en het leren op straat hangt aan ervaren monteurs die nooit geleerd hebben hoe je iemand iets leert. Ze doen het zelf, want de klus moet af. Daardoor duurt het veertien maanden voordat een nieuwe monteur zelfstandig werkt, en er kunnen er niet meer tegelijk leren.
    plausible_causes:
      - Jongeren willen niet meer met hun handen werken.
      - Voltana betaalt te weinig; de aannemers betalen meer.
      - Er zijn gewoon te weinig instructeurs; meer budget voor het opleidingscentrum lost het op.
    mismatch_note: Meer aanmeldingen of hogere salarissen helpen niet zolang er niet meer mensen tegelijk kunnen leren. Het knelpunt zit in het leren op straat, niet in de poort.
    countermeasures: {train_the_trainer: 1.0, apprentice_cohort_september: 0.9, hybrid_crews: 0.8, freelance_monteurs: 0.6}
    teaches: [monteurstekort, twi_job_instruction]
    effects:
      # estimate: ~3 seniors spend about a third of their time beside an apprentice who watches instead of
      # doing: ~1 of 13 FTE lost (0.85 -> 0.80); the C17c ramp itself (12 a year) is the base growth.
      - {target: monteurs, property: availability, value: -0.05}
      - {target: lv_monteurs, property: availability, value: -0.03}
    clues:
      - {tool: data, key: true, depth: 0, text: "Er staan zeven vacatures voor monteurs open, gemiddeld zeven maanden. Voor de opleiding meldden zich vorig jaar 41 mensen aan; er werden er twaalf aangenomen."}
      - {tool: documents, key: false, depth: 0, text: "Het salaris van een monteur bij Voltana volgt de cao. De aannemers in de regio betalen ongeveer hetzelfde."}
      - {tool: conversation, key: true, depth: 1, text: "'Ik heb vier instructeurs. Per instructeur kan ik zes cursisten veilig begeleiden op het oefenterrein. Meer niet.'"}
      - {tool: shadow, key: true, depth: 1, at: connections.execution, text: "Een ervaren monteur werkt met een aankomend monteur naast zich. Hij legt weinig uit en doet het meeste zelf: de klus moet vandaag af."}
      - {tool: conversation, key: false, depth: 1, text: "'Jongeren willen gewoon niet meer met hun handen werken.'"}
      - {tool: data, key: true, depth: 2, text: "Aankomend monteurs werken gemiddeld na veertien maanden zelfstandig. De twee die een vaste leermeester hadden, deden dat na negen maanden."}
      - {tool: conversation, key: true, depth: 2, at: connections.execution, text: "'Niemand heeft mij ooit geleerd hoe je iemand iets leert. Ik doe het voor, en dan zeg ik: zo dus.'"}

countermeasures:
  - id: train_the_trainer
    name: Leermeesters leren leren
    tier: 2
    category: people
    description: Twaalf ervaren monteurs leren in drie dagen hoe je iemand een handeling leert in vier stappen (voorbereiden, voordoen, laten doen, nazorg). Elk krijgt een vaste leerling; de leermeester mag een klus langer doen. Het opleidingscentrum keurt het af wanneer een leerling zelfstandig mag.
    budget: 15000
    team_hours: {monteurs: 60, trainers: 20}
    decay_days: 120
    sustains: true    # a teaching standard the field keeps using
    needs_discount: {needs: {any: [heard:ahmed_trainer, chose:knowledge_drain:twi_job_instruction, chose:knowledge_drain:skills_matrix_buddy]}, budget: 0.6, team_hours: 0.6}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.02}   # estimate: apprentices do real work sooner
  - id: apprentice_cohort_september
    name: Een extra groep in september
    tier: 3
    category: people
    description: Een tweede groep van twaalf aankomend monteurs start in september, met twee extra instructeurs van het ROC in de regio en het oefenterrein ook op zaterdag.
    budget: 45000
    team_hours: {trainers: 60}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: headcount, value: 2}   # estimate: the first net gain after a year, scaled to the model's pool
  - id: hybrid_crews
    name: Gemengde ploegen
    tier: 3
    category: people
    description: Een aankomend monteur doet vanaf maand drie zelfstandig een vaste lijst eenvoudige klussen (meterwissels, huisaansluitingen zonder graafwerk), met een ervaren monteur op afstand. De lijst is opgesteld en ondertekend door het opleidingscentrum.
    budget: 8000
    team_hours: {trainers: 20, planners: 10}
    decay_days: 180
    needs_discount: {needs: {all: [committed:joke_depot]}, team_hours: 0.7}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: freelance_monteurs
    name: Zzp-monteurs inhuren
    tier: 1
    category: people
    description: Acht ervaren zzp-monteurs via een bureau, voor een jaar. Ze werken meteen. Ze leiden niemand op, en ze verdienen meer dan de vaste monteurs naast hen.
    budget: 2000
    team_hours: {planners: 10}
    decay_days: 365
    trust: {monteurs: -1}
    cost_per_week: 4800   # estimate: 8 x 40 h x a EUR 15/h premium over a fully loaded employee
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: monteurs, property: availability, value: 0.04}
```

**Dialog: `patrick_trainers`.** Patrick is rule-bound for a good reason: safety.

```yaml
dialogs:
  - id: patrick_trainers
    person: patrick
    kind: persuade
    mission: fix_training_capacity
    owns: training_capacity
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Kom binnen. Pas op de kabelhaspel. Die ligt daar voor de cursisten, niet voor jou."
    position: {text: "Vier instructeurs, zes cursisten per instructeur. Twaalf per jaar, twee groepen. Meer is niet veilig.", tags: [claim]}
    layers:
      - id: interest
        at: 52
        via: [inquiry, open_question, paraphrase]
        text: "Op het oefenterrein kan ik zien wat ze doen. Op straat niet. Daar staan ze naast een monteur die geen tijd heeft om uit te leggen."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En als er iets gebeurt…", tags: [hesitation]}
        text: "Als jullie straks halve monteurs de straat op sturen en er raakt er één een kabel die nog onder spanning staat, dan is het mijn opleiding die gefaald heeft. Ik teken voor elke jongen die hier de poort uit gaat. Ik ga niet tekenen voor iemand die ik niet heb gezien."
        tags: [admission]
        unlocks: {facts: [heard:patrick_signs], proposals: [patrick_certifies_masters]}
    reframe: "Vanuit de jongen die we vorig jaar afwezen? Die werkt nu bij een installateur. Die heeft niemand die voor hem tekent. Hm."
    warning: "Ik heb om twee uur een groep op het terrein."
    data: ["training_capacity:0", "training_capacity:5"]
    proposals:
      - {id: more_instructors, addresses: [interest], label: "Meer instructeurs", say: "Twee instructeurs erbij, van het ROC.", reply: "Dat helpt. Op het terrein. Op straat verandert er niets."}
      - {id: patrick_certifies_masters, hidden: true, addresses: [concern], label: "Patrick keurt de leermeesters", say: "Wat als jij de leermeesters op straat opleidt en keurt? Dan staat er naast elke jongen iemand die jij hebt gezien.", reply: "Ik keur de leermeesters. Dan teken ik niet voor iemand die ik niet ken. Dan teken ik voor de man die naast hem staat."}
      - {id: signed_task_list, addresses: [concern], label: "Een lijst die Patrick tekent", say: "Een vaste lijst klussen die een leerling alleen mag doen, door jou opgesteld en getekend.", reply: "Een lijst. Met mijn handtekening. Meterwissels ja, middenspanning nooit."}
    co_proposal: {id: patrick_certifies_masters, text: "Geef mij de leermeesters drie dagen. Dan leer ik ze hoe je iemand iets leert. Dat heeft niemand ze ooit geleerd."}
    outcomes:
      commitment: "Afgesproken. En de eerste groep leermeesters kies ik zelf."
      partial: "Ik wil het. Maar niemand gaat alleen de straat op zonder mijn handtekening."
      heard: "Je bent de eerste die vraagt waar ik voor teken."
      compliance: "Als de directie het wil. Het staat wel in mijn verslag dat ik ertegen was."
      ruined: "Ik ga niet tekenen voor een spreadsheet."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose patrick_certifies_masters +8 89 > ask: commitment (8 moves)
```

A short second dialog appears when `heard:ahmed_trainer` is set (dialog scripts §3.4, variant): `ahmed_first_apprentices`. It is a check-in, a week after the first cohort starts. Ahmed's concern, "Ze kijken naar mij alsof ik Henk ben", is lifted by *Gevoel benoemen* and *Ervaring delen*. Fixing mode ("Zal ik een cursus voor je regelen?") is the trap. Content as in the dialog scripts §8; not repeated here.

**Path dependence.**
- `heard:ahmed_trainer` or a saved Henk (`twi_job_instruction`, `skills_matrix_buddy`) makes `train_the_trainer` 40 % cheaper (`needs_discount`), and the debrief's `{trainer_line}` names Ahmed. This is the audit's Q5 payoff with a face.
- `committed:joke_depot` makes `hybrid_crews` cheaper in Lindeveld: the freed hour already went to training.
- `flag:freelance_crews`:
  - the crew strategy's *Havenzij street crew* option counts only own monteurs, so it stays thin;
  - `t4_investment_plan`'s "Opleiden: 12 aankomend monteurs" option needs `none: [flag:freelance_crews]` or `done:fix_training_capacity` with `train_the_trainer`;
  - the freelancers leave after a year (`decay_days: 365`), and if nothing was trained the gap returns at once.
- A miss (deadline) closes the September cohort; `train_the_trainer` and `hybrid_crews` remain, so the problem is still solvable another way.

**Grounding.**
- 5,000 extra technicians planned by grid operators and contractors over five years, with training and supervision capacity as the main constraint, in 6–7 regions with ROCs (Solar Magazine, November 2025).
- The 28,000 shortage up to 2029 and "about 30,000 needed up to 2030" (Netbeheer Nederland; Solar Magazine).
- TWI Job Instruction's four steps (audit §2.3).
- Twelve a year, four instructors, six trainees each, 14 versus 9 months, 41 applicants: estimates sized to the model.

**Engrossing.**
- A clock with a reason (the September intake).
- A person who blocks for safety, not for comfort.
- The aha: the limit is not in the gate but in the field, where nobody was ever taught how to teach.
- The callback: Ahmed with two apprentices.

### 1.4 `t3_crew_strategy` — Waar zetten we de monteurs in? (M, strategy)

Principles tested: **long_term** (what you prepared decides what you can choose) and **respect** (people are not pins on a map). This is the act's path-dependence centrepiece: the options on the table are the player's own history.

```yaml
missions:
  - id: t3_crew_strategy
    name: Waar zetten we de monteurs in?
    kind: main
    tier: 3
    act: 4
    chapter: Eén regio
    requires: {facts: {any: [done:fix_training_capacity, failed:fix_training_capacity]}}
    principles: [long_term, respect]
    goal:
      type: strategy
      horizon_days: 91                   # each unlocked option is forecast on a network copy (KpiBoard.forecast pattern)
      options:
        - id: lindeveld_crew
          name: Een vaste ploeg in Lindeveld
          description: Twee monteurs uit Nova gaan vast naar Lindeveld en werken vanuit de uitvalsbasis.
          effects:
            - {target: lv_monteurs, property: headcount, value: 2}
            - {target: monteurs, property: headcount, value: -2}
          cost: 4000
          needs: {any: [chose:long_drives:satellite_depot, repaired:long_drives], none: [chose:long_drives:outsource_area]}
          preparation: "In Lindeveld moet de basis eerst kloppen."
          sets_flags: [flag:crew_lindeveld]
        - id: daytime_outage_reserve
          name: Een vaste storingsploeg overdag
          description: Elke dag staan twee monteurs klaar voor storingen; de geplande klussen blijven staan.
          effects:
            - {target: monteurs, property: reserve, value: {stream: outages, people: 2}}
          cost: 2000
          needs: {any: [chose:planning_reshuffle:daytime_outage_crew, standardised:planning_reshuffle]}
          preparation: "De planning moet storingen al kunnen opvangen."
          sets_flags: [flag:crew_daytime_reserve]
        - id: havenzij_street_crew
          name: Een straatploeg voor Havenzij
          description: Een ploeg van drie, met de nieuwe monteurs, voor de krappe straten van Havenzij.
          effects:
            - {target: hz_monteurs, property: headcount, value: 3}
            - {target: monteurs, property: headcount, value: -2}   # one is the first trained apprentice
          cost: 6000
          needs: {all: [done:fix_training_capacity], none: [flag:freelance_crews]}
          preparation: "Er moeten eerst genoeg eigen monteurs bij komen."
          sets_flags: [flag:crew_havenzij]
        - id: freed_hours_bank
          name: De uren van de lege ritten
          description: De monteursuren die vrijkwamen toen er niet meer voor niets werd gereden, gaan vast naar Lindeveld.
          effects:
            - {target: lv_monteurs, property: availability, value: 0.08}
          cost: 0
          needs: {any: [chose:installer_not_ready:readiness_check, chose:installer_not_ready:installer_photo_upload]}
          preparation: "Monteurs rijden nog te vaak voor niets."
          sets_flags: [flag:crew_freed_hours]
        - id: trainer_pairs
          name: Leermeester en leerling
          description: Elke nieuwe monteur rijdt een half jaar vast met een leermeester mee; de leermeester krijgt daar tijd voor.
          effects:
            - {target: monteurs, property: availability, value: 0.03}
          cost: 3000
          needs: {any: [heard:ahmed_trainer, chose:knowledge_drain:twi_job_instruction, chose:knowledge_drain:skills_matrix_buddy, chose:training_capacity:train_the_trainer]}
          preparation: "Er moet iemand zijn die het vak kan doorgeven."
          sets_flags: [flag:crew_trainer_pairs]
        - id: overtime_push
          name: Iedereen een uur langer
          description: Alle monteurs werken een kwartaal een uur per dag over. Het werkt meteen.
          effects:
            - {target: monteurs, property: availability, value: 0.1}
          cost: 0
          cost_per_week: 3500             # estimate: 13 x 5 h x EUR 54/h overtime rate
          aftermath: {after_days: 42, days: 56, effects: [{target: monteurs, property: availability, value: -0.12}], trust: {monteurs: -1}}
          sets_flags: [flag:crew_overtime]
        - id: spread_evenly
          name: Iedereen blijft waar hij is
          description: De ploegen blijven zoals ze zijn. Nieuwe monteurs gaan waar het het drukst is.
          effects: []
          cost: 0
    teaches: [path_dependence, capacity_planning, respect_for_people]
    rewards: {xp: 2800, budget: 20000, reputation: 5}
    briefing: "Er komen monteurs bij, en het werk is niet eerlijk verdeeld: Lindeveld rijdt, Havenzij puzzelt, Nova wordt elke ochtend door storingen overhoop gegooid. Het MT wil voor het volgende kwartaal één besluit over de inzet van de monteurs. Op tafel ligt wat je hebt voorbereid. Wat je niet hebt voorbereid, ligt er ook, met een rode stip."
    debrief: "Je koos {option}. Over een kwartaal laat het bord zien wat het deed met de doorlooptijd in alle drie de gebieden. {locked_line} Marco: 'Je hebt het ons gevraagd. Dat had de vorige nooit gedaan.'"
    beats:
      - {on: accepted, who: marco, text: "Als jij mijn mannen over de kaart gaat schuiven, wil ik erbij zijn."}
    insights:
      go_see: "Welke opties liggen op tafel, en welke niet? Waarom niet?"
      understand: "Wat laat de voorspelling zien over Lindeveld, Havenzij en Nova samen, en niet alleen over het gebied waar je het eerst aan dacht?"
      experiment: "Wat verwacht je over een kwartaal te zien? Welk getal vertelt je dat je je vergiste?"
      reflect: "Welke keuze van vorig jaar maakte deze keuze mogelijk? En welke had je anders willen maken?"
```

`{locked_line}` lists, in Ruud's words, one locked option and its preparation hint ("Een vaste ploeg in Lindeveld lag niet op tafel: daar moest de basis eerst kloppen."). It never names the mission that would have unlocked it.

**Dialog: `marco_crew`.** Marco fights for his hours: the arc's last stage from the audit's cast.

```yaml
dialogs:
  - id: marco_crew
    person: marco
    kind: persuade
    mission: t3_crew_strategy
    patience: 10
    # start: cynic 30 + 0 + 10 x team trust monteurs (often +1 by now) + (trust - 50)/5 + memory
    #   with Act I's commitment and the day-100 check-in lifted: 30 + 10 + 4 (trust 70) + 0 + 15 = 59, Luistert
    #   with no history: 30, Op z'n hoede
    opening: "Ik heb de kaart gezien. Met de rode stippen. Ik zeg het maar meteen: ik geef geen man af aan Havenzij."
    position: {text: "Mijn mannen blijven in Nova. Ze kennen de wijken, ze kennen de klanten.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Een monteur die de wijk kent, ziet een rare kast van tien meter afstand. Een monteur die er nieuw is, staat er een uur naar te kijken."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [silence, empathy, inquiry]
        lead_in: {text: "En dan is er nog iets…", tags: [hesitation]}
        text: "Op die kaart zijn het stippen. Ik zie Ricardo, wiens vrouw net bevallen is. Ik zie Sem, die mantelzorger is voor z'n vader in Nova-Oud. Als ik die een uur verder wegstuur, zijn ze over een halfjaar weg. Naar een aannemer. Dan heb ik er twee minder, niet twee meer."
        tags: [admission]
        unlocks: {facts: [heard:marco_people], proposals: [volunteers_first]}
    reframe: "Vanuit Joke? Die heeft vijf man voor een gebied zo groot als Nova en Havenzij samen. Ja. Die zou ik ook een man willen geven. Als hij wil."
    warning: "Jij gaat me niet vertellen hoe ik mijn ploeg indeel."
    proposals:
      - {id: move_two, addresses: [interest], label: "Twee monteurs naar Lindeveld", say: "Twee monteurs uit Nova gaan naar Lindeveld.", reply: "Twee. Welke twee? Dat is de vraag."}
      - {id: volunteers_first, hidden: true, addresses: [concern], label: "Eerst vrijwilligers, met de ploeg erbij", say: "Wat als we het de ploeg zelf vragen? Wie wil, gaat. Wie niet kan, blijft. En wat er overblijft, verdelen we samen.", reply: "Vragen. Aan de mannen zelf. Ja. Dan weet ik wie het vraagt en wie het moet."}
    experiments:
      - {id: rotation_quarter, addresses: [concern], label: "Een kwartaal rouleren", say: "Een kwartaal rouleren: iedereen een week Lindeveld, en daarna kijken wie wil blijven.", reply: "Een week. Dan zien ze het zelf. Sommigen gaan het nog leuk vinden ook."}
    co_proposal: {id: volunteers_first, text: "Laat mij het ze vragen. Bij de koffie, maandag. Niet in een mail."}
    outcomes:
      commitment: "Afgesproken. En wie er gaat, krijgt van mij een goede bus. Niet de oude."
      partial: "Ik doe mee. Als er niemand gestuurd wordt die niet wil."
      heard: "Hm. Je hebt het gevraagd. Dat is al wat."
      compliance: "Zet ze maar op de kaart. Stippen zijn makkelijk."
      ruined: "Zie je. Een nieuw plan, dezelfde stippen. Wie bouwt dat na?"
    # route (no history, start 30): mood +8 38 > open question +6 44 > paraphrase +7 51 (heard) > inquiry +8 59 (interest)
    #        > empathy +6 65 > inquiry +8 73 (lead-in, cue) > silence +12 > 81 capped (concern) > propose volunteers_first +8 89 > ask (10 moves: all his patience)
    # route (with history, start 59): open question > 64 capped (interest) > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern)
    #        > propose volunteers_first +8 89 > ask: commitment (5 moves)
    # This is the act's clearest path-dependence moment in a talk: respect shown in Act I makes Marco reachable in Act IV.
    # A player with no history can still win him (the route is long but within patience with a retry and the repair chip).
```

**Path dependence.** This is where the player *sees* their history:

| Option | Needs (any of) | Its preparation in earlier play | Locked hint |
|---|---|---|---|
| Een vaste ploeg in Lindeveld | the depot chosen, or the long-drives repair; *not* outsourced | `fix_long_drives` (§1.2) | "In Lindeveld moet de basis eerst kloppen." |
| Een vaste storingsploeg overdag | the daytime crew chosen or standardised in `fix_planning_reshuffle` (Act I side) | Linda's side mission | "De planning moet storingen al kunnen opvangen." |
| Een straatploeg voor Havenzij | `fix_training_capacity` done; no freelancers | §1.3 | "Er moeten eerst genoeg eigen monteurs bij komen." |
| De uren van de lege ritten | the readiness check or photo upload in Act I's non-bottleneck fork branch | `fix_installer_not_ready` (audit Q3) | "Monteurs rijden nog te vaak voor niets." |
| Leermeester en leerling | Henk saved by teaching, Ahmed heard as a trainer, or train-the-trainer | Henk, Ahmed (Acts I, III), §1.3 | "Er moet iemand zijn die het vak kan doorgeven." |
| Iedereen een uur langer | always open (the temptation) | — | — |
| Iedereen blijft waar hij is | always open (the baseline) | — | — |

- **The validator's rule holds.** Every option with needs has a branch that no failure closes:
  - the repair quest (`repaired:long_drives`);
  - a recurring or always-open mission (`fix_planning_reshuffle` reopens if it faded);
  - `chose:training_capacity:train_the_trainer` (still possible after a missed deadline).

  The baseline has no needs.
- **The temptation** `overtime_push` forecasts *well* over the first six weeks: the forecast shows it. The aftermath (sick leave, trust −1) lands in weeks 7–14 of the 91-day horizon, so the full forecast shows the cost too, if the player looks past week 6. That is the lesson.
- **`flag:crew_*`** is read by `t4_investment_plan` (catalogue §3.7: "Meer monteurs in Lindeveld" needs `flag:crew_lindeveld` or `repaired:long_drives`). `flag:crew_overtime` is read by D27 *Niemand opgebrand* (it cannot be earned in this act).

**Grounding.** Capacity planning and path dependence: catalogue §2.15. The forecast pattern: PLAN.md decision 2026-10-13 (the counterfactual board). The overtime rate (€54/h) is an estimate: a CAO wage of ~€30/h at a 150 % overtime supplement, plus employer costs. Overtime fatigue reducing availability afterwards is an estimate of the direction only: Kingman's slack argument (audit L15).

**Engrossing.** The first time the player's whole history is on one screen as possibilities. The red dots are not a punishment; each one names a place to go back to. And Marco names the people behind the dots.

### 1.5 The fork `t3_havenzij`: `fix_underground_crowding` (B) and `fix_uneven_release` (N)

Both open after the crew strategy, on one card: "Twee teams vragen om je aandacht."
- **Bottleneck:** Havenzij's design team of three spends its days finding a route through crowded streets, and redesigns when the route turns out occupied. Design is Havenzij's constraint.
- **Non-bottleneck:** a developer releases homes in monthly batches; planning is flooded once a month. It adds lead time and stress, not a capacity limit (correction 8).

```yaml
missions:
  - id: fix_underground_crowding
    name: Geen plek onder de stoep
    kind: main
    tier: 3
    act: 4
    chapter: Havenzij
    requires: {missions: [t3_crew_strategy]}
    fork: {group: t3_havenzij, role: bottleneck}
    goal: {type: solve, problem: underground_crowding}
    principles: [respect, long_term]
    briefing: "Yusuf Demir, teamleider Werkvoorbereiding in Havenzij, heeft drie tekenaars en een achterstand van zeven weken. 'In Nova teken je een kabel van A naar B. Hier moet je eerst uitzoeken waar nog plek is, tussen gas, water, glasvezel, het warmtenet en drie generaties kabels.' Vorige week werd een tracé voor de derde keer overgetekend. Yusuf vraagt een vierde tekenaar."
    debrief: "In Havenzij gaan er nu {throughput_after} aansluitingen per week door, was {throughput_before}. Yusufs tekenaars tekenen weer in plaats van te puzzelen: de straat wordt één keer gepland, met de gemeente en de andere leidingbeheerders aan één tafel. Marloes Kramer van de gemeente: 'De Havenstraat gaat volgend jaar één keer open. Niet drie keer.'"
    debrief_first: "Nu zie je het verschil met de maandpiek: dit keer gaan er wél meer aansluitingen per week door. Waarom hier wel en daar niet?"
    reopen: "In Havenzij wordt weer drie keer overgetekend. Het gezamenlijke straatoverleg is na de zomer niet meer bij elkaar geweest."
    beats:
      - {on: accepted, who: yusuf, text: "Kom kijken. Ik laat je de kaart van de Havenstraat zien. Neem een vergrootglas mee."}
      - {on: completed, who: marloes, text: "Iedereen wilde altijd dat ik andere partijen dwong. Jij vroeg of we samen één agenda wilden. Dat is een verschil."}
    temptations:
      - id: deep_bypass
        who: yusuf
        when: accepted
        text: "Weet je wat sneller is? Ik leg de kabel op een meter twintig, onder alles door. Dan hoef ik met niemand te overleggen."
        accept: "Je laat Werkvoorbereiding de kabels dieper leggen, onder de rest door."
        decline: "Je gaat eerst met de gemeente en de andere beheerders om tafel."
        accept_sets_flags: [flag:deep_cables]
        accept_effects: {complete_goal: false, reputation: 1}
    teaches: [theory_of_constraints, ondergrondse_ordening, respect_for_people]
    rewards: {xp: 3000, budget: 25000, reputation: 5, trust: {hz_work_prep: 1}}
    insights:
      go_see: "Twee teams vragen om je aandacht. Waar ligt in Havenzij het meeste werk te wachten, in dagen werk? Heb je dat zelf geteld?"
      understand: "Hoeveel van de tijd van een tekenaar gaat naar tekenen, en hoeveel naar uitzoeken waar het kan?"
      experiment: "Welk getal in Havenzij verandert als dit werkt: bij de tekenaars, en aan het eind van de stroom?"
      reflect: "Wie zat er voor het eerst samen aan tafel? Wat had ieder daarvoor nodig?"

  - id: fix_uneven_release
    name: De maandpiek
    kind: main
    tier: 3
    act: 4
    chapter: Havenzij
    requires: {missions: [t3_crew_strategy]}
    fork: {group: t3_havenzij, role: non_bottleneck}
    goal: {type: solve, problem: uneven_release}
    principles: [improve, respect]
    briefing: "Hermans Bouw, die je kent van De Boomgaard, bouwt in Havenzij vierhonderd woningen in de oude haven. Eén keer per maand komen er tientallen aanvragen tegelijk binnen. Linda: 'De eerste week van de maand plan ik dag en nacht, de derde week zit ik naar een leeg bord te kijken.' Hermans wil dat zijn kopers op tijd stroom hebben, en hij heeft gelijk."
    debrief: "Hermans geeft zijn woningen nu elke week vrij in plaats van elke maand. Linda plant elke dag ongeveer evenveel. De kopers in de oude haven zijn gemiddeld {lead_delta} dagen eerder aangesloten. Maar kijk naar Havenzij als geheel: er gaan niet méér aansluitingen per week door. Het werk wacht nog steeds bij {constraint_place}."
    debrief_first: "Goed dat dit ook rustiger is: minder stress bij Linda, en kopers die eerder stroom hebben. Het knelpunt van Havenzij zat al ergens anders."
    reopen: "De maandpiek is terug. Hermans' nieuwe projectleider geeft weer alles tegelijk vrij."
    beats:
      - {on: accepted, who: hermans, text: "Ik geef vrij wanneer de bank betaalt. Daar kan ik niks aan doen. Toch?"}
    temptations:
      - id: peak_temps
        who: linda
        when: accepted
        text: "Geef mij twee uitzendkrachten in de eerste week van elke maand. Dan red ik het."
        accept: "Je huurt elke maand twee uitzendkrachten voor Planning in."
        decline: "Je gaat met Hermans praten over waarom het tegelijk komt."
        accept_sets_flags: [flag:peak_temps]
        accept_effects: {cost_per_week: 900}
    teaches: [heijunka, waste_waiting, lead_time]
    rewards: {xp: 2600, budget: 20000, reputation: 5}
    insights:
      go_see: "Twee teams vragen om je aandacht. Waar staat het werk in Havenzij het langst te wachten?"
      understand: "Waarom komt het werk in één keer? Wie heeft er belang bij dat het zo komt?"
      experiment: "Welk getal verwacht je dat verandert: de doorlooptijd van Hermans' kopers, het aantal aansluitingen per week, of allebei?"
      reflect: "Gaan er nu meer aansluitingen per week door in Havenzij? Wat is er wél beter geworden, en voor wie?"

problems:
  - id: underground_crowding
    tier: 3
    name: Geen plek onder de stoep
    step: hz_connections.design
    waste: overprocessing
    severity: high
    visibility: subtle
    kpi: throughput
    symptoms:
      - De tekenaars in Havenzij hebben zeven weken achterstand.
      - Tracés worden twee of drie keer overgetekend voordat de vergunning eruit kan.
    root_cause: In de oude havenstraten liggen gas, water, glasvezel, het warmtenet en drie generaties kabels door elkaar. Elke netbeheerder plant zijn eigen tracé en hoort pas bij de vergunning dat de plek bezet is. Er is geen gezamenlijke planning van de ondergrond met de gemeente; elke partij puzzelt apart, en dezelfde straat gaat meerdere keren open.
    plausible_causes:
      - De tekenaars in Havenzij zijn te onervaren.
      - De gemeente is te streng met vergunningen.
      - Er zijn gewoon te weinig tekenaars; een vierde lost het op.
    mismatch_note: Meer of betere tekenaars puzzelen sneller, maar ze puzzelen nog steeds alleen, en het tracé blijft botsen met wat de anderen tegelijk plannen.
    countermeasures: {joint_street_planning: 1.0, one_dig_agreements: 0.8, standard_duct_designs: 0.7, deep_bypass: 0.6}
    teaches: [theory_of_constraints, ondergrondse_ordening]
    effects:
      # estimate: route searching adds ~30% to a design in the old harbour (KLIC requests, calls to other utilities)
      - {target: hz_connections.design, property: touch_time, value: 1.3}
      # estimate: one in eight routes comes back from the permit check as occupied and is redrawn
      - {target: hz_connections.design, property: ftr, value: -0.12}
    cost_per_week: 500   # estimate: redesigns and extra KLIC requests
    clues:
      - {tool: queue_count, key: true, depth: 0, text: "Bij Werkvoorbereiding Havenzij liggen 46 dossiers: ruim zeven weken werk voor drie tekenaars. Bij Planning liggen er elf."}
      - {tool: time_study, key: true, depth: 0, text: "Een tracé in de oude haven kost ruim vier uur, waarvan anderhalf uur uitzoeken waar nog plek is. In Nova kost een vergelijkbaar tracé tweeënhalf uur."}
      - {tool: conversation, key: false, depth: 0, text: "'De gemeente keurt alles af. Die willen gewoon niet dat we graven.'"}
      - {tool: documents, key: true, depth: 1, at: hz_connections.permit, text: "Van de afgewezen vergunningen van dit jaar is de reden bijna altijd: 'tracé conflicteert met geplande werkzaamheden van een andere leidingbeheerder'."}
      - {tool: data, key: true, depth: 1, text: "De Havenstraat ging vorig jaar drie keer open: voor glasvezel in maart, voor het warmtenet in juni en voor een Voltana-kabel in oktober."}
      - {tool: conversation, key: true, depth: 2, at: hz_connections.permit, text: "'Iedereen meldt zijn eigen werk bij de gemeente. Niemand vraagt wat de buren de komende twee jaar van plan zijn.'"}
      - {tool: shadow, key: false, depth: 1, text: "De tekenaars werken zorgvuldig; ze controleren elk tracé twee keer op de KLIC-kaart."}

  - id: uneven_release
    tier: 3
    name: De maandpiek
    step: hz_connections.release
    waste: waiting
    severity: medium
    visibility: obvious
    kpi: lead_time
    symptoms:
      - In de eerste week van de maand komen tientallen aanvragen tegelijk binnen; in de derde week bijna niets.
      - Planning maakt in de piekweek overuren en zit later in de maand stil.
    root_cause: De projectontwikkelaar geeft zijn woningen eens per maand vrij, als de bank een fase financiert. Voltana neemt de aanvragen aan zoals ze komen, dus de maandpiek gaat de hele stroom door. Niemand heeft met de ontwikkelaar afgesproken hoe vrijgeven anders kan.
    plausible_causes:
      - Planning heeft te weinig mensen.
      - Kopers van nieuwbouw willen altijd alles tegelijk.
    mismatch_note: Meer planners in de piekweek verwerken de piek, maar de klanten uit de piek wachten nog steeds op elkaar. Het werk komt ongelijk binnen, en daar ligt de oorzaak.
    countermeasures: {level_release_with_developer: 1.0, frozen_planning_window: 0.8, peak_temps: 0.6}
    teaches: [heijunka, waste_waiting]
    effects:
      # estimate: monthly release = a batch at the wait step before intake; average extra wait ~2 weeks
      - {target: hz_connections.release, property: batch_days, value: 28}
      # estimate: the peak week is re-planned twice
      - {target: hz_connections.planning, property: touch_time, value: 1.1}
    clues:
      - {tool: data, key: true, depth: 0, at: hz_connections.intake, text: "Zestig procent van de aanvragen van Hermans Bouw komt binnen in de eerste vijf werkdagen van de maand."}
      - {tool: shadow, key: false, depth: 0, at: hz_connections.planning, text: "In de piekweek plant Linda tot zeven uur 's avonds. In de derde week ruimt ze haar bureau op."}
      - {tool: documents, key: true, depth: 1, text: "In het contract met Hermans Bouw staat niets over wanneer of hoe woningen worden vrijgegeven."}
      - {tool: conversation, key: true, depth: 2, text: "'Ik geef vrij als de bank de volgende fase financiert. Eén keer per maand. Daar kan ik niks aan doen.' En na een stilte: 'Of ik zou het moeten vragen.'"}

countermeasures:
  - id: joint_street_planning
    name: Eén ondergrondse agenda met de gemeente
    tier: 3
    category: flow
    description: Elk kwartaal plannen Voltana, de gemeente en de andere leidingbeheerders samen de straten van de komende twee jaar. Wie een straat opengaat, weet wie er nog meer in wil. Tracés worden op de gezamenlijke kaart getekend voordat de vergunning wordt aangevraagd.
    budget: 12000
    team_hours: {hz_work_prep: 30, gis: 10}
    decay_days: 120
    sustains: true    # a quarterly table with the gemeente: a leader routine outside the company
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_connections.permit, property: wait_time, value: 0.8}   # estimate: fewer rejected permits
  - id: one_dig_agreements
    name: Eén keer graven
    tier: 3
    category: flow
    description: In straten die toch opengaan, leggen alle partijen samen in één sleuf, met één aannemer en één planning. Dat vraagt vertrouwen tussen netbeheerder, aannemers en gemeente.
    budget: 20000
    team_hours: {hz_work_prep: 20, planners: 10}
    decay_days: null
    needs: {any: [done:fix_contractor_rework, repaired:contractor_rework], none: [flag:contractor_burned]}   # the tier-2 draft's link
    preparation: "Aannemers moeten Voltana weer willen vertrouwen."
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: standard_duct_designs
    name: Standaardkokers voor de oude haven
    tier: 2
    category: standard_work
    description: Voor de vijf meest voorkomende straatprofielen in de oude haven een standaardtracé met mantelbuis, door de gemeente vooraf goedgekeurd.
    budget: 6000
    team_hours: {hz_work_prep: 25}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: deep_bypass
    name: Dieper leggen, onder de rest door
    tier: 1
    category: flow
    description: Kabels in de oude haven komen op een meter twintig, onder de andere leidingen door. Sneller getekend, duurder gegraven, en wie later graaft, verwacht ze daar niet.
    budget: 9000
    team_hours: {hz_work_prep: 5}
    decay_days: 180
    aftermath:
      after_days: 120
      days: 999
      effects:
        - {target: outages, property: demand, value: 1.02}   # estimate: digging damage on cables at an unexpected depth; KLIC gives position, not reliable depth
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: level_release_with_developer
    name: Elke week vrijgeven, met een vaste datum per blok
    tier: 3
    category: flow
    description: Hermans Bouw geeft elke week een vast aantal woningen vrij. Voltana geeft voor elk blok vooraf een aansluitdatum, zodat de bank zekerheid heeft.
    budget: 3000
    team_hours: {planners: 15, key_accounts: 5}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_connections.release, property: batch_days, value: 7}
  - id: frozen_planning_window
    name: Een bevroren planning van twee weken
    tier: 3
    category: flow
    description: Wat binnen twee weken gepland staat, schuift niet meer. Nieuwe aanvragen uit een piek gaan in de eerstvolgende open week.
    budget: 2000
    team_hours: {planners: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_connections.planning, property: touch_time, value: 0.92}
  - id: peak_temps
    name: Uitzendkrachten in de piekweek
    tier: 1
    category: people
    description: Elke maand twee uitzendkrachten bij Planning in de eerste week. De piek wordt weggewerkt; hij komt elke maand terug.
    budget: 1000
    team_hours: {planners: 5}
    decay_days: 60
    cost_per_week: 900   # estimate: 2 x 40 h x EUR 45/h agency rate, one week in four
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialogs.**

```yaml
dialogs:
  - id: marloes_one_agenda
    person: marloes
    kind: persuade
    mission: fix_underground_crowding
    owns: underground_crowding
    patience: 9
    # start: rule_bound 35 + 0 + 0 (an outside partner) + 0 + 0 = 35, Op z'n hoede
    opening: "Als u komt klagen over de vergunningen: ik heb er vorige maand vierenveertig afgegeven. En vijftien afgewezen. Met reden."
    position: {text: "De gemeente geeft vergunningen af. Afstemmen tussen leidingbeheerders is uw zaak, niet de mijne.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "Ik heb geen mandaat om KPN of het waterbedrijf te dwingen te wachten. Ik kan alleen nee zeggen als het botst. En dan ben ik de boeman.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "Vorig jaar…", tags: [hesitation]}
        text: "Vorig jaar lag de Havenstraat drie keer open. De bewoners kennen mijn naam, de ondernemers ook. Ik word niet opnieuw de vrouw van het zoveelste overleg dat niets oplevert. Daar heb ik er al vier van."
        tags: [admission]
        unlocks: {facts: [heard:marloes_street], proposals: [pilot_one_street]}
    reframe: "Vanuit de bakker in de Havenstraat? Die heeft drie keer een hek voor zijn deur gehad. Ja. Die zou ook liever één keer een slechte maand hebben."
    warning: "Ik heb om vier uur de wethouder."
    data: ["underground_crowding:3", "underground_crowding:4"]
    proposals:
      - {id: quarterly_table, addresses: [interest], label: "Een kwartaaloverleg", say: "Elk kwartaal alle leidingbeheerders aan één tafel, met de straten van de komende twee jaar.", reply: "Nog een overleg. Ik weet hoe dat gaat."}
      - {id: pilot_one_street, hidden: true, addresses: [concern], label: "Eén straat, één keer open", say: "Wat als we het niet voor de hele stad proberen? Eén straat. De Havenstraat. Eén keer open, met iedereen erin. U zit voor.", reply: "Eén straat. Die ken ik van binnen en van buiten. Als het daar lukt, hoeft niemand mij meer te geloven. Dan zien ze het."}
    experiments:
      - {id: shared_map_trial, addresses: [concern], label: "Een gezamenlijke kaart, drie maanden", say: "Drie maanden: iedere beheerder zet zijn plannen op één gezamenlijke kaart, en u ziet ze als eerste.", reply: "Als eerste. Dan ben ik niet de boeman achteraf. Dan ben ik de planner vooraf."}
    co_proposal: {id: pilot_one_street, text: "Begin bij de Havenstraat. Daar wonen de mensen die het meest hebben gemopperd. Als het daar lukt, lukt het overal."}
    outcomes:
      commitment: "Afgesproken. En ik nodig de bewoners uit voor de eerste vergadering. Dan zien ze ons samen."
      partial: "Ik doe mee. Als de anderen ook komen."
      heard: "U bent de eerste netbeheerder die vraagt hoe het voor mij is."
      compliance: "Zet het maar op de agenda. Ik zit wel voor."
      ruined: "Dus de gemeente is het probleem. Dat hoor ik vaker."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose pilot_one_street +8 89 > ask: commitment (8 moves)

  - id: hermans_release
    person: hermans
    kind: persuade
    mission: fix_uneven_release
    owns: uneven_release
    patience: 10
    # start: defender 40 + 0 + 0 + 2 (trust 60 after De Boomgaard, if fix_transformer_wait went well) + 0 = 42, Luistert
    opening: "De trafo voor De Boomgaard kwam op tijd. Dat heb ik onthouden. Wat kan ik voor u doen?"
    position: {text: "Ik geef vrij als de bank betaalt. Eens per maand. Daar kan ik niks aan doen.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Elke fase die de bank financiert, wil ik zo snel mogelijk verkopen. Mijn kopers willen weten wanneer ze erin kunnen.", tags: [claim]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "Kijk, als ik eerlijk ben…", tags: [hesitation]}
        text: "Als ik spreid en een koper hoort dat hij twee weken later stroom heeft dan zijn buurman, krijg ik een advocaat aan de lijn. Ik verkoop zekerheid. Eén datum. Ook als die datum slecht is."
        tags: [admission]
        unlocks: {facts: [heard:hermans_dates], proposals: [date_per_block]}
    reframe: "Vanuit uw planner? Die zit in de eerste week van de maand tot zeven uur. Hm. Dat wist ik niet."
    warning: "Ik heb een bouwvergadering."
    data: ["uneven_release:0", "uneven_release:2"]
    proposals:
      - {id: weekly_release, addresses: [interest], label: "Elke week vrijgeven", say: "Geef elke week een vast aantal woningen vrij in plaats van eens per maand.", reply: "En wat zeg ik tegen mijn kopers?"}
      - {id: date_per_block, hidden: true, addresses: [concern], label: "Een vaste datum per blok", say: "Wat als u elke week vrijgeeft, en wij voor elk blok vooraf een vaste aansluitdatum geven? Dan verkoopt u nog steeds zekerheid. Alleen eerder.", reply: "Een datum per blok, vooraf. Die kan ik in het koopcontract zetten. Dat is beter dan wat ik nu heb."}
    experiments:
      - {id: one_block_trial, addresses: [concern], label: "Eén blok proberen", say: "Eén blok van twintig woningen: elke week vrijgeven, met een vaste datum per week. Klaagt er één koper, dan stoppen we.", reply: "Eén blok. En als de eerste koper zijn datum haalt, doe ik de rest ook zo."}
    co_proposal: {id: date_per_block, text: "Als ik die datum in het koopcontract mag zetten, praat ik zelf met de bank."}
    outcomes:
      commitment: "Afgesproken. En als u de datum haalt, bel ik u voor het volgende project. Eerst u, dan de bank."
      partial: "Ik wil het wel. Als ik de data vooraf heb."
      heard: "Interessant. Daar had ik nooit over nagedacht."
      compliance: "Als het moet. Maar de klachten stuur ik naar u door."
      ruined: "Ik bouw huizen. Uw planning is uw probleem."
    # route: open question +6 48 > paraphrase +7 55 (heard, interest) > show_data +10 65 > inquiry +8 73 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose date_per_block +8 87 > ask: commitment (8 moves)
```

A short third dialog, `yusuf_fourth_draughtsman` (defender; concern: "Als het niet aan mensen ligt, waarom ben ik dan zeven weken achter?"), follows the shape of `joost_vacancies` (dialog scripts §6.1). It is written out only if Merijn wants Havenzij to repeat Act I's lesson (Q4); recommended: a short beat instead, because the act's new lesson is the outside partner.

**Path dependence.**
- `one_dig_agreements` needs the tier-2 contractor trust (`none: [flag:contractor_burned]`), with `repaired:contractor_rework` as the way back. The tier-2 draft's link, honoured here.
- `flag:deep_cables` (the temptation, or the `deep_bypass` countermeasure, which is a poor fix) sets an aftermath of more outages from digging damage later, the callback to Gert and the KLIC map. `t4_investment_plan`'s "Sensoren in het LS-net" sees more faults in Havenzij.
- `fork_first:t3_havenzij:*` gives D4 / D5 as in Act I.

**Grounding.**
- Underground crowding and joint planning of the underground (*ondergrondse ordening*): the GDD backlog item "ondergrondse drukte"; the existing Wibon/KLIC grounding. KLIC shows the position of cables, not a reliable depth (audit M7 and Wibon practice; *verify the depth statement*).
- Heijunka against a developer's batch release: Toyota's levelled production applied to demand (Liker, *The Toyota Way*, principle 4).
- All counts and factors are estimates, with their reasoning in the YAML comments.

**Engrossing.** Two partners outside the company:
- a civil servant who is tired of meetings;
- a developer who sells certainty.

Both are right, and both have a fear that a good proposal can meet. The non-bottleneck branch is a real improvement with a face (Linda's evenings), and the Check says honestly what it did and did not do.

### 1.6 `t3_kaizen_week` — Kaizenweek (M)

Principles tested: **respect** (the team improves its own work) and **improve**. Temptation: a consultant-run kaizen blitz.

```yaml
missions:
  - id: t3_kaizen_week
    name: Kaizenweek
    kind: main
    tier: 3
    act: 4
    chapter: Havenzij
    requires: {any_of: [fix_underground_crowding, fix_uneven_release]}
    goal: {type: kaizen_event, place: current_constraint, days: 5}
    principles: [respect, improve]
    briefing: "Ruud wil dat Zuidmark leert hoe een team in één week zijn eigen werk verbetert: een kaizenweek. Vijf dagen, het hele team, één proces. Waar? Daar waar het de hele stroom ophoudt. Dat moet je eerst weten, en het team moet het willen."
    debrief: "In vijf dagen heeft het team van {place} zijn eigen werk opnieuw ingericht. {gain_line} Het team presenteerde het zelf aan het MT. Ruud zat achteraan en zei niets. Wat moet er gebeuren zodat het er over drie maanden nog is?"
    debrief_variants:
      not_constraint: "Het team heeft hard gewerkt, en het is beter georganiseerd. Maar er gaan niet meer aansluitingen per week door: {place} hield de stroom niet op. Wat zou je een volgende keer eerst meten?"
    beats:
      - {on: accepted, who: ruud, text: "Een kaizenweek is niet van jou. Jij zorgt dat ze tijd hebben, eten en een bord. De rest is van hen."}
      - {on: completed, who: marco, text: "Dit was geen 2012. Dit hebben ze zelf gedaan."}
    temptations:
      - id: consultant_blitz
        who: consultant
        when: accepted
        text: "Wij doen kaizenweken bij netbeheerders door heel Europa. Wij brengen de facilitators, de methode en de presentatie. Uw team hoeft alleen mee te doen."
        accept: "Je laat het bureau de kaizenweek leiden."
        decline: "Je laat het team de week zelf leiden, met jou als begeleider."
        accept_sets_flags: [flag:kaizen_by_consultants]
        accept_effects: {cost: 25000, reputation: 2}
    teaches: [kaizen_event, bottleneck_focus, respect_for_people]
    rewards: {xp: 3000, budget: 25000, reputation: 5, unlocks: [kaizen_event]}
    insights:
      go_see: "Waar houdt de stroom nu op? Hoe weet je dat: heb je het opnieuw gemeten na de vorige verbetering?"
      understand: "Wat wil het team zelf verbeteren? Komt dat overeen met wat jij zag?"
      experiment: "Wat verwacht het team na vijf dagen te zien, in een getal?"
      reflect: "Van wie is het resultaat? Hoe weet het team dat?"
```

**Dialog: `team_lead_kaizen`.** The person depends on where the constraint is (it moved after the fork). The dialog is written for Havenzij's design team (Yusuf, the likely constraint after `fix_uneven_release` or a partial `fix_underground_crowding`), with a variant for Nova's work preparation (Joost).

```yaml
dialogs:
  - id: team_lead_kaizen
    person: yusuf
    kind: persuade
    mission: t3_kaizen_week
    patience: 10
    # start: defender 40 + 0 + 10 x team trust hz_work_prep (+1 after the fork's B branch) + 0 + 0 = 40-50
    opening: "Vijf dagen niet tekenen. Met een achterstand van zes weken. Je snapt dat ik daar niet om sta te springen."
    position: {text: "We kunnen geen week missen. Dan loopt de achterstand alleen maar op.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Elke dag dat we niet tekenen, belt Hermans, belt de gemeente, belt de klant. Mijn mensen krijgen dat over zich heen, niet jij.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "En eerlijk gezegd…", tags: [hesitation]}
        text: "Ik heb dit eerder gezien. Iemand van buiten komt een week vertellen wat er anders moet, en daarna doen wij het werk en krijgt hij de eer. Mijn mensen weten heus wel wat er beter kan. Niemand vraagt het ze."
        tags: [admission]
        unlocks: {facts: [heard:yusuf_kaizen], proposals: [team_chooses_problem]}
    reframe: "Vanuit de klant die zeven weken op een tekening wacht? Die heeft liever één week stilstand en daarna vaart dan zeven weken zoals nu. Hm. Misschien."
    warning: "Ik heb een team dat zit te wachten op mij."
    proposals:
      - {id: cover_the_week, addresses: [interest], label: "Nova vangt de week op", say: "Tijdens de kaizenweek tekent Werkvoorbereiding Nova de standaardaansluitingen van Havenzij.", reply: "Nova. Kunnen die dat dan? Met onze straten?",
         needs: {all: [standardised:custom_design]}}
      - {id: team_chooses_problem, hidden: true, addresses: [concern], label: "Het team kiest het probleem", say: "Wat als jouw team zelf kiest wat ze in die week aanpakken? Ik zorg voor tijd, eten en een bord. Zij presenteren het, niet ik.", reply: "Zelf kiezen. En zelf presenteren. Dan is het van hen. Ja. Dan zeg ik ja."}
    experiments:
      - {id: two_day_pilot, addresses: [concern], label: "Eerst twee dagen", say: "Eerst twee dagen, met het team. Als het niets oplevert, stoppen we en zeg jij het in het MT.", reply: "Twee dagen. En als ik stop zeg, stoppen we."}
    co_proposal: {id: team_chooses_problem, text: "Laat ze het zelf kiezen. Ze weten het allang. Ze hebben het alleen nooit hardop mogen zeggen."}
    outcomes:
      commitment: "Afgesproken. Maandag om acht uur. En er is goede koffie, niet die van de automaat."
      partial: "Ik doe mee. Als mijn achterstand die week wordt opgevangen."
      heard: "Je bent de eerste die vraagt wat mijn mensen ervan vinden."
      compliance: "Prima. Een week. Ik zie wel wat ervan overblijft."
      ruined: "Kom maar terug als je weet wat een tracé in de oude haven is."
    variants:
      - needs: {all: ["constraint_place:connections.design"]}   # Nova's work preparation is the constraint
        person: joost
    # route (start 40): open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > reflect +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose team_chooses_problem +8 87 > ask: commitment (7 moves)
```

**Path dependence.**
- **`standardised:custom_design`** (Act I, Anouk's standard designs) lets Nova cover Havenzij's standard cases during the week (`cover_the_week` exists only then). A sustained Act I fix pays in Act IV, through a person.
- **`flag:kaizen_by_consultants`** gives the week's gains the compliance buy-in (×0.6, dialog spec §4.2): the team watched; it did not own. If `heard:marco_2012` is set, Marco says in a beat: "Dit is 2012." (`marco` trust −1). The way back is a second, team-led kaizen week through `lsw_layered_audit`'s next cycle (Q5).
- **Drie winters (2026-10-16), the regime's way back:** with `flag:lean_programme_2` the consultant blitz is pre-accepted; a team-led week needs Frank's agreement through `frank_interim` (≥ partial). A team-led week presented by the team to the MT clears `flag:lean_programme_2` and sets `flag:regime_eased` (the Obeya returns next to the dashboard). See `2026-10-16-drie-winters-arc.md` §7.3.
- **Holding a kaizen at a non-constraint place** completes the goal with the `not_constraint` debrief. It teaches; it is no failure.

**Grounding.**
- The kaizen event (5 days, a cross-functional team, one process, the team presents): Imai, *Gemba Kaizen* (1997); Laraia, Moody & Hall, *The Kaizen Blitz* (1999).
- That gains from consultant-led events fade without ownership: the commitment versus compliance argument (dialog spec §12).

**Engrossing.** The player gives up control on purpose. The most visible reward is a team presenting its own work to the MT, with Ruud silent at the back.

### 1.7 `fix_priority_first_come` — Wie gaat er voor? (M)

Principles tested: **respect** (for the customers who do not shout) and **long_term** (a rule applied fairly survives an appeal; a favour does not). Temptation: let the alderman's sports hall jump the queue. The id is kept; the title and the problem are corrected (§0.2, item 1).

```yaml
missions:
  - id: fix_priority_first_come
    name: Wie gaat er voor?
    kind: main
    tier: 3
    act: 4
    chapter: Wie gaat er voor?
    requires: {missions: [t3_kaizen_week]}
    goal: {type: solve, problem: priority_first_come}
    principles: [respect, long_term]
    briefing: "Mevrouw Brouwer van zorgcentrum De Linde wil twaalf extra kamers bouwen, met warmtepompen. Ze staat al veertien maanden in de wachtrij voor transportcapaciteit. Sinds januari geldt een nieuw prioriteringskader: zorg gaat voor. Toch staat De Linde nog op plek 61, tussen een autodealer en een datacenter. 'Ik dacht dat het op volgorde ging,' zegt ze. 'Dat zei iedereen.'"
    debrief: "Wie in de wachtrij voorrang heeft, krijgt die nu vanaf de aanvraag, niet pas als hij erom vraagt. {n_reclassified} aanvragen kregen een andere plek. De Linde bouwt in het voorjaar. Thomas: 'Ik heb nog nooit zo weinig gebeld en zo weinig boze mensen gesproken.' Wie stond er onterecht achteraan, en weet die het nu?"
    reopen: "De voorrang wordt weer pas toegekend als iemand erom vraagt. Het formulier heeft een nieuwe versie gekregen, zonder de vraag naar de functie."
    beats:
      - {on: accepted, who: thomas, text: "Ik doe die classificatie tussen mijn klantgesprekken door. Als iemand belt en het vraagt. Zo is het nu eenmaal gegroeid."}
      - {on: completed, who: el_amrani, text: "Mijn moeder vroeg of de buren in De Linde nu eindelijk hun kamers krijgen. Ik zei ja. Dat wist ik van u."}   # only if heard:el_amrani
    temptations:
      - id: sports_hall
        who: mt_member
        when: accepted
        text: "De wethouder belde. De nieuwe sporthal in Havenzij moet in september open, met de verkiezingen in het voorjaar. Kun je die er niet even tussen zetten? Dat helpt ons bij de gemeente, met al die vergunningen."
        accept: "Je zet de sporthal hoger in de wachtrij."
        decline: "Je zegt dat de volgorde het kader volgt, voor iedereen."
        accept_sets_flags: [flag:queue_jumped]
        accept_effects: {reputation: 3}
    teaches: [maatschappelijk_prioriteren, netcongestie, quality_at_the_source]
    rewards: {xp: 3200, budget: 25000, reputation: 5, trust: {key_accounts: 1}}
    insights:
      go_see: "Wie staat er in de wachtrij, en wie zou volgens het kader voor moeten gaan? Heb je dat zelf nagekeken?"
      understand: "Op welk moment hoort Voltana dat een aanvrager voorrang heeft? En op welk moment had dat gekund?"
      experiment: "Hoeveel aanvragen verwacht je dat een andere plek krijgen? Wat merkt een aanvrager die zakt daarvan?"
      reflect: "Wie stond er al die tijd onterecht achteraan, en wist het niet? Wat zegt dat over wie er wél belde?"

problems:
  - id: priority_first_come
    tier: 3
    name: Wie gaat er voor?
    step: congestion.intake
    waste: defects
    severity: high
    visibility: hidden
    kpi: lead_time
    symptoms:
      - Een zorginstelling staat al veertien maanden in de wachtrij, tussen bedrijven zonder voorrang.
      - Voorrang wordt bijna alleen toegekend aan aanvragers die er zelf om bellen.
    root_cause: Het prioriteringskader wordt niet bij de aanvraag toegepast. Het formulier vraagt niet naar de maatschappelijke functie, dus wie voorrang heeft, staat op volgorde van binnenkomst tot hij er zelf om vraagt en bewijs aanlevert. De accountmanager beoordeelt dat met de hand, tussen zijn klantgesprekken door. Wie de regels kent, gaat voor; wie ze niet kent, wacht.
    plausible_causes:
      - Voorrang geven is oneerlijk tegenover wie al jaren wacht.
      - Zorginstellingen vragen hun capaciteit gewoon te laat aan.
      - Het net in Havenzij is vol; aan de volgorde valt niets te verbeteren.
    mismatch_note: Het net is vol, maar wie het eerst aan de beurt komt, is een keuze. Die keuze wordt nu gemaakt door wie belt, niet door het kader.
    countermeasures: {classify_at_intake: 1.0, public_queue_with_class: 0.7, mt_case_by_case: 0.5}
    teaches: [maatschappelijk_prioriteren, quality_at_the_source]
    effects:
      # needs C17b (priority classes on orders) for the real harm: priority orders waiting in date order.
      # Until then: the manual classification on request costs key accounts time (estimate: ~40% more per request,
      # evidence chased by phone).
      - {target: congestion.intake, property: touch_time, value: 1.4}
    clues:
      - {tool: data, key: true, depth: 0, at: congestion.capacity_queue, text: "Van de 214 aanvragen in de wachtrij van Zuidmark zijn er negen van zorginstellingen, scholen of de drinkwaterbeheerder. Twee daarvan hebben een voorrangsstatus."}
      - {tool: conversation, key: false, depth: 0, text: "'Voorrang geven is oneerlijk tegenover wie al jaren wacht. Wie eerst komt, eerst maalt.'"}
      - {tool: documents, key: true, depth: 1, text: "Het aanvraagformulier vraagt naar het vermogen en de gewenste datum, niet naar de functie van het gebouw. Voorrang wordt alleen beoordeeld 'op verzoek van de aanvrager'."}
      - {tool: listen_in, key: true, depth: 1, text: "'Voorrang? Daar wist ik niets van. Ik dacht dat het op volgorde ging. Dat zei iedereen.'"}
      - {tool: data, key: true, depth: 2, text: "Aanvragen die later voorrang kregen, wachtten gemiddeld negen maanden voordat ze die kregen. De status werd meestal pas toegekend als de aanvrager zelf belde."}
      - {tool: conversation, key: true, depth: 2, text: "'Ik doe de beoordeling tussen mijn klantgesprekken door. Wie belt, krijgt aandacht. Wie niet belt…'"}

countermeasures:
  - id: classify_at_intake
    name: Voorrang beoordelen bij de aanvraag
    tier: 3
    category: quality
    description: Het aanvraagformulier vraagt naar de functie van het gebouw en het bewijs dat het kader vraagt. Bij binnenkomst beoordeelt Grootzakelijke klanten de categorie, met een schriftelijk besluit en een bezwaarmogelijkheid. Bestaande aanvragen worden één keer nagelopen.
    budget: 9000
    team_hours: {key_accounts: 30, intake: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.intake, property: touch_time, value: 0.9}
  - id: public_queue_with_class
    name: Een openbare wachtrij met categorie
    tier: 2
    category: visual_management
    description: Per gebied staat op de website hoeveel aanvragen er wachten, per categorie, en waar een aanvrager zelf staat.
    budget: 5000
    team_hours: {key_accounts: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion, property: call_rate, value: 0.85}   # estimate: fewer 'where am I' calls
  - id: mt_case_by_case
    name: Het MT beslist per geval
    tier: 1
    category: standard_work
    description: Aanvragers die vinden dat ze voorrang horen te hebben, kunnen hun zaak voorleggen aan het MT, dat per geval beslist.
    budget: 500
    team_hours: {key_accounts: 5}
    decay_days: 90
    aftermath:                 # estimate: case-by-case favours the loudest; a complaint follows within months
      after_days: 75
      days: 1
      reputation: -5
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialog: `jeroen_classes`.** The resistance is legal care, not unwillingness.

```yaml
dialogs:
  - id: jeroen_classes
    person: jeroen
    kind: persuade
    mission: fix_priority_first_come
    owns: priority_first_come
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 2 (trust 60, if talk_regulation went well) + 0 = 37, Op z'n hoede
    opening: "Prioriteren. Ik hoorde het al. Mag ik eerst iets zeggen voordat je enthousiast wordt?"
    position: {text: "Voorrang geven we op verzoek, met bewijs. Zo blijft het juridisch houdbaar.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "Elke categorie die wij toekennen, kan iemand aanvechten. De datacenters, de telecom, de sportclubs: ze willen er allemaal in.", tags: [claim]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En ik heb het al eens zien gebeuren…", tags: [hesitation]}
        text: "In maart 2025 vernietigde de rechter het hele kader. Ik had de afdeling net uitgelegd hoe het werkte. Als wij nu op eigen houtje gaan classificeren en het sneuvelt, staan wij met tweehonderd boze aanvragers en een rechtszaak. En dan ben ik degene die het had moeten zien aankomen."
        tags: [admission]
        unlocks: {facts: [heard:jeroen_appeal], proposals: [decision_with_appeal]}
    reframe: "Vanuit mevrouw Brouwer? Die heeft recht op voorrang en weet het niet. Juridisch gezien… is dat ook niet houdbaar. Hm."
    warning: "Ik ga dit niet doen zonder dat het juridisch klopt."
    data: ["priority_first_come:0", "priority_first_come:4"]
    proposals:
      - {id: ask_every_applicant, addresses: [interest], label: "Elke aanvrager de vraag stellen", say: "We vragen het voortaan aan iedereen bij de aanvraag, in plaats van te wachten tot iemand belt.", reply: "Vragen mag. Beoordelen is het probleem."}
      - {id: decision_with_appeal, hidden: true, addresses: [concern], label: "Een besluit met bezwaarmogelijkheid", say: "Wat als elke classificatie een schriftelijk besluit wordt, met de regel van het kader erbij en een bezwaarmogelijkheid? Dan beoordelen we niet op eigen houtje. Dan passen we het kader toe, controleerbaar.", reply: "Een besluit met een motivering. Dat is precies wat de rechter in 2025 miste. Ja. Dat kan ik verdedigen."}
    experiments:
      - {id: check_the_nine, addresses: [concern], label: "Eerst de negen nalopen", say: "Laten we eerst de negen zorg- en schoolaanvragen in de rij samen nalopen, met jouw toets erbij.", reply: "Negen. Dat is te overzien. En dan weet ik hoe het in de praktijk uitpakt."}
    co_proposal: {id: decision_with_appeal, text: "Ik schrijf het sjabloon voor het besluit. Dan doet Thomas de toets, en ik de motivering."}
    outcomes:
      commitment: "Afgesproken. En als er bezwaar komt, behandel ik het zelf. Dan leer ik er ook van."
      partial: "Ik wil het. Als het besluit juridisch klopt."
      heard: "Fijn dat je eerst vroeg in plaats van te beginnen."
      compliance: "Als het MT het zo wil. Ik zet mijn bezwaar in de notulen."
      ruined: "Dan doe je het maar zonder mij. Succes bij de rechter."
    # route: open question +6 43 > paraphrase +7 50 (heard) > inquiry +8 58 (interest) > show_data +15 (rule_bound) 73 (lead-in, cue)
    #        > empathy +6 79 (concern) > propose decision_with_appeal +8 87 > ask: commitment (7 moves)
```

**Path dependence.**
- `flag:queue_jumped` pays now: reputation +3 and a friendlier gemeente. Its costs come later:
  - an ACM complaint from the applicant who dropped, 90 days later (reputation −5);
  - if `heard:ilse_lockin` is set, Ilse calls ("Ik sta twee jaar te wachten en de sporthal gaat voor?") and her trust falls by 15;
  - Act V's `nta8120_audit` and the investment plan read `flag:queue_jumped` as a governance finding.

  The way back: `classify_at_intake` with Jeroen's commitment re-reviews every case, the sports hall included (it clears the flag).
- `chose:priority_first_come:classify_at_intake` with `committed:jeroen_classes` is read by the tier-4 `fix_flex_market_unused` (Act V): the queue data can be trusted for the flex market.

**Grounding.**
- The ACM framework annulled by the CBb on 11 March 2025 (ECLI:NL:CBB:2025:145), in force until 1 January 2026; a renewed framework from 1 January 2026 (ACM; Kamerstuk annex; *verify* the exact categories).
- The order: congestion relievers; then safety, health, infrastructure and drinking water; then housing and education (RVO; ANP July 2026).
- 214, nine, two, 14 months, place 61: estimates sized for the model.
- The C17b mechanism (priority classes) is needed for the real harm; the YAML approximates only the manual work.

**Engrossing.**
- The person who is wronged is the one who never complained.
- The temptation comes from your own MT with a sensible reason (the gemeente's goodwill).
- The legal expert's fear is real history (2025), and the countermeasure that answers it is the one the court asked for: a motivated decision.

### 1.8 `fix_household_rush` — Iedereen een zwaardere aansluiting (S, new)

Principles tested: **improve** (find the real need behind the request) and **respect** (the customer's need, not our procedure). Temptation: approve every heavier connection automatically. Side size: one person, one place, one twist, one object (the installer's quote).

```yaml
missions:
  - id: fix_household_rush
    name: Iedereen een zwaardere aansluiting
    kind: side
    tier: 3
    act: 4
    chapter: Wie gaat er voor?
    requires: {missions: [t3_map_region]}
    opens_on: {day_of_year: 196}          # mid-July: the first weeks after 1 July (the rule) in the game's calendar
    goal: {type: solve, problem: household_rush}
    principles: [improve, respect]
    briefing: "Sinds 1 juli komen huishoudens in volle gebieden ook op de wachtlijst als ze een zwaardere aansluiting willen. Wie dat wist, vroeg er in juni nog snel een aan. De Intake krijgt vijf keer zoveel aanvragen als vorig jaar. Sanne: 'Driekwart heeft een offerte van een installateur bij zich. 3x35. Altijd 3x35.'"
    debrief: "Er komen nu {requests_delta}% minder aanvragen voor een zwaardere aansluiting binnen. Bij een op de {n} bleek de oude aansluiting genoeg. Die klanten hebben hun warmtepomp al, en de wachtlijst is korter voor wie het echt nodig heeft."
    beats:
      - {on: completed, who: sjaak, text: "Ik heb mijn offertes aangepast. Eerst meten, dan adviseren. Mijn klanten vinden het nog prettig ook."}
    temptations:
      - id: auto_approve
        who: mt_member
        when: accepted
        text: "Keur alle verzwaringen tot 3x35 gewoon automatisch goed. Dan is de stapel weg en heeft niemand klachten."
        accept: "Je laat alle verzwaringen tot 3x35 automatisch goedkeuren."
        decline: "Je gaat eerst kijken wat de klanten echt nodig hebben."
        accept_sets_flags: [flag:auto_upgrades]
        accept_effects: {complete_goal: true}
    teaches: [failure_demand, netcongestie, customer_value]
    rewards: {xp: 1200, budget: 10000, reputation: 2}

problems:
  - id: household_rush
    tier: 3
    name: Iedereen een zwaardere aansluiting
    step: connections.intake
    waste: overproduction
    severity: medium
    visibility: obvious
    kpi: lead_time
    symptoms:
      - De Intake krijgt vijf keer zoveel aanvragen voor een zwaardere huisaansluiting als vorig jaar.
      - Bijna elke aanvraag vraagt om 3x35A, met een offerte van een installateur erbij.
    root_cause: Installateurs adviseren standaard de zwaarste aansluiting, omdat zij de klacht krijgen als een warmtepomp terugschakelt. Het aanvraagformulier vraagt welke aansluiting de klant wil, niet wat hij ermee gaat doen of wat er nu al zit. Niemand kijkt of de bestaande aansluiting volstaat.
    plausible_causes:
      - Klanten willen gewoon het zekere voor het onzekere.
      - De nieuwe regels zijn slecht uitgelegd.
    mismatch_note: Een betere uitleg remt de stroom aanvragen niet zolang het advies dat de klant krijgt standaard 'de zwaarste' is.
    countermeasures: {heat_pump_check: 1.0, installer_briefing: 0.8, auto_approve_upgrades: 0.5}
    teaches: [failure_demand, netcongestie]
    effects:
      # estimate: the rush settles at ~+25% connection requests for a quarter (the ANP figure of x5 is the peak month)
      - {target: connections, property: demand, value: 1.25}
      # estimate: more upgrade requests above the study threshold: +10 points of orders needing a grid check
      - {target: connections.grid_study, property: applies, value: 0.1}
    clues:
      - {tool: data, key: true, depth: 0, text: "In juli kwamen er vijf keer zoveel aanvragen voor een zwaardere huisaansluiting binnen als een jaar eerder. Negen op de tien vragen om 3x35A."}
      - {tool: listen_in, key: true, depth: 1, at: customer_contact.answer, text: "'Mijn installateur zei: neem 3x35, dan zit u goed. Wat ik nu heb? Geen idee eigenlijk.'"}
      - {tool: documents, key: true, depth: 1, text: "Het formulier vraagt welke aansluiting de klant wil. Het vraagt niet wat hij gaat aansluiten, en niet wat hij nu heeft."}
      - {tool: conversation, key: true, depth: 2, text: "'Bij de helft van de warmtepompen die ik plaats, was de oude aansluiting genoeg geweest. Maar wie het advies geeft, krijgt de klacht als het misgaat.'"}

countermeasures:
  - id: heat_pump_check
    name: Eerst kijken wat er al kan
    tier: 2
    category: quality
    description: Bij elke aanvraag voor een zwaardere aansluiting vraagt de Intake wat de klant gaat aansluiten en wat er nu zit. Een korte rekencheck laat zien of de bestaande aansluiting volstaat, eventueel met een lagere stand van de warmtepomp. Pas als het niet past, gaat de aanvraag door.
    budget: 4000
    team_hours: {intake: 20, grid_analysts: 5}
    decay_days: 120
    needs_discount: {needs: {all: ["agreed:el_amrani_fourth_call:check_existing_connection"]}, team_hours: 0.5}   # the check was already done once, for her
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: installer_briefing
    name: Installateurs meenemen
    tier: 2
    category: standard_work
    description: Voltana en de grote installateurs in de regio maken samen één adviesformulier. Wie het invult en volgt, krijgt de steun van Voltana als de klant later klaagt.
    budget: 3000
    team_hours: {intake: 10, key_accounts: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: auto_approve_upgrades
    name: Verzwaringen automatisch goedkeuren
    tier: 1
    category: flow
    description: Alle aanvragen tot 3x35A worden automatisch goedgekeurd, zonder check op de wijk.
    budget: 500
    team_hours: {intake: 2}
    decay_days: 365
    aftermath:                 # estimate: the next winter, neighbourhood transformers overload on cold evenings ('De koude straat', audit §6.4)
      after_days: 120
      days: 120
      effects:
        - {target: outages, property: demand, value: 1.05}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialog: `sjaak_advice`.**

```yaml
dialogs:
  - id: sjaak_advice
    person: sjaak
    kind: persuade
    mission: fix_household_rush
    owns: household_rush
    patience: 9
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Van Rooij Installatietechniek, met Sjaak. Ik sta op een zolder in Havenzij, dus kort graag."
    position: {text: "Ik adviseer 3x35. Dan zit de klant goed, voor de komende twintig jaar.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Een warmtepomp, een inductieplaat, straks een laadpaal. Als ik nu krap adviseer, sta ik over twee jaar weer in die meterkast.", tags: [claim]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "En weet je wat het is…", tags: [hesitation]}
        text: "Als een warmtepomp op een koude avond terugschakelt omdat de aansluiting te klein is, belt de klant mij. Niet jullie. Mijn naam staat op het busje. In dit dorp weet iedereen wie het was."
        tags: [admission]
        unlocks: {facts: [heard:sjaak_name], proposals: [backed_advice_form]}
    reframe: "Vanuit de klant die nu een jaar op de wachtlijst staat voor iets wat hij misschien niet nodig had? … Ja. Die belt mij óók."
    warning: "Ik heb een klant op de trap staan."
    data: ["household_rush:0", "household_rush:3"]
    proposals:
      - {id: ask_what_is_there, addresses: [interest], label: "Eerst vragen wat er nu zit", say: "Zet op je offerte wat er nu zit en wat de klant gaat aansluiten.", reply: "Dat kan. Al weet de helft van de klanten niet eens wat er in de meterkast hangt."}
      - {id: backed_advice_form, hidden: true, addresses: [concern], label: "Een adviesformulier met Voltana's steun", say: "Wat als wij samen één adviesformulier maken? Wie het invult en volgt, krijgt onze steun als de klant later klaagt. Dan staat niet alleen jouw naam op het busje.", reply: "Jullie steun. Op papier. Dan durf ik ook 'de oude is genoeg' te zeggen."}
    experiments:
      - {id: measure_first_ten, addresses: [concern], label: "De volgende tien samen meten", say: "Bij je volgende tien klanten meten we samen wat er echt nodig is, en Voltana tekent mee onder het advies.", reply: "Tien. Met jullie handtekening eronder. Dat durf ik wel."}
    co_proposal: {id: backed_advice_form, text: "Laat mij met een paar collega's dat formulier maken. Wij weten wat er op een zolder fout gaat."}
    outcomes:
      commitment: "Afgesproken. En ik zeg het tegen de andere installateurs. Die bellen me toch."
      partial: "Ik wil het wel. Als ik er niet alleen voor sta."
      heard: "Fijn dat iemand van de netbeheerder eens belt zonder dat er iets mis is."
      compliance: "Prima. Ik vul jullie formulier in. Mijn advies blijft 3x35."
      ruined: "Dus ik adviseer verkeerd. Leuk. Ik heb een klant op de trap."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose backed_advice_form +8 87 > ask: commitment (7 moves)
```

**Path dependence.**
- The callback to Mrs El Amrani: a player who agreed the existing-connection check with her in Act I has done this once. The countermeasure's team hours halve (`agreed:<dialog>:<proposal>`, a new fact form, §6).
- `flag:auto_upgrades` (the temptation, or the countermeasure, which is a poor fix) brings "De koude straat" the next winter: more outages in heat-pump streets on cold evenings. The tier-4 repair quest for `inverters_tripping` (audit §6.4) reads it too.

**Grounding.**
- Households in congestion areas on the waiting list from 1 July 2026, with a transition period for heavier connections until 1 January 2027; five times as many requests (ANP via Welingelichte Kringen, 24 July 2026; Den Haag; KHN; Kassa).
- Grid operators stress that not everyone needs a heavier connection (Liander via Overstappen.nl; NOS).
- 3x35A as the installer's default and "half" being unnecessary are estimates, labelled as the installer's view in his own words.

**Engrossing.**
- This year's real headline, at the player's own front desk.
- The twist: the request is not the need.
- The callback: a customer the player met in Act I already showed the answer.

### 1.9 `fix_nitrogen_permit` — Stikstof op het tracé (M, deadline)

Principles tested: **long_term** (fix the process for every project, not one exemption) and **improve**. Temptation: a diesel generator park as a bridge. Deadline: the Kanaalzone Waterstof electrolyser's start, 120 days.

```yaml
missions:
  - id: fix_nitrogen_permit
    name: Stikstof op het tracé
    kind: main
    tier: 3
    act: 4
    chapter: Wie gaat er voor?
    requires: {missions: [fix_priority_first_come]}
    goal: {type: solve, problem: nitrogen_permit}
    deadline_days: 120
    fail: "De elektrolyser van Kanaalzone Waterstof is klaar en kan niet aan. Ze hebben het terrein naast het onderstation verkocht om hun eigen uitbreiding te betalen; het tracé over het industrieterrein is weg. De verzwaring komt er, langs de Slikken, met een vergunning die langer duurt."
    fail_closes: [route_via_industrial_zone]
    fail_effects: {reputation: -10}
    principles: [long_term, improve]
    briefing: "Kanaalzone Waterstof bouwt een elektrolyser van tien megawatt. Over vier maanden is hij klaar. Het onderstation in Havenzij moet ervoor worden verzwaard, en dat duurt dertien maanden: zes weken bouwen, de rest wachten op de natuurvergunning. 'Stikstof,' zegt iedereen, en haalt zijn schouders op. Vergunningenadviseur Dennis Wouters maakt voor elk project een nieuwe berekening."
    debrief: "Een verzwaring in Havenzij duurt nu {months_after} maanden in plaats van {months_before}. De natuurvergunning is niet sneller geworden; ze begint alleen niet meer pas als het ontwerp af is. {kzw_line} Dennis: 'Ik reken nu met een sjabloon. Ik heb voor het eerst in jaren tijd voor het moeilijke werk.'"
    reopen: "De stikstofberekening wacht weer tot het ontwerp definitief is. Dennis is met pensioen en het sjabloon staat op zijn oude schijf."
    beats:
      - {on: accepted, who: kzw, text: "Wij hebben vijftig miljoen geïnvesteerd. Over vier maanden staat er een elektrolyser die niets doet. Ik wil weten wat u gaat doen."}
      - {on: day, day: 90, who: ruud, text: "Nog dertig dagen. Wat weet je nu over de vergunning dat je drie maanden geleden niet wist?"}
    temptations:
      - id: diesel_bridge
        who: kzw
        when: accepted
        text: "Weet u wat? Wij huren voor een jaar een aggregatenpark. Dan draaien we vast, en u heeft de tijd. U hoeft alleen akkoord te geven op de tijdelijke aansluiting."
        accept: "Je geeft akkoord op een aggregatenpark als overbrugging."
        decline: "Je zegt dat je eerst de vergunningsstroom zelf wilt aanpakken."
        accept_sets_flags: [flag:diesel_bridge]
        accept_effects: {reputation: 2}
    teaches: [stikstof, waste_waiting, lead_time]
    rewards: {xp: 3400, budget: 30000, reputation: 5}
    insights:
      go_see: "Waar zit de tijd in een verzwaring? Hoeveel daarvan is werk, en hoeveel wachten?"
      understand: "Wat moet er vastliggen voordat de stikstofberekening kan beginnen? Ligt dat eerder vast dan het hele ontwerp?"
      experiment: "Hoeveel maanden verwacht je eraf te halen? Wat verandert er niet, hoe goed je experiment ook is?"
      reflect: "Wat kon je niet veranderen, en wat wel? Geldt dat ook voor de volgende verzwaring, en de volgende?"

problems:
  - id: nitrogen_permit
    tier: 3
    name: Stikstof op het tracé
    step: hz_reinforcement.nature_permit
    waste: waiting
    severity: high
    visibility: subtle
    kpi: wip_age
    symptoms:
      - Een verzwaring in Havenzij duurt dertien maanden; het bouwen zelf zes weken.
      - Voor elke verzwaring wordt een nieuwe stikstofberekening gemaakt, pas als het ontwerp definitief is.
    root_cause: Sinds de bouwvrijstelling is vervallen, heeft elk netproject een eigen stikstofbeoordeling nodig. Voltana maakt de berekening pas als het hele ontwerp vastligt, terwijl alleen het tracé en het materieel ertoe doen, en begint elke keer vanaf nul. Het ontwerp en de vergunning lopen na elkaar in plaats van naast elkaar.
    plausible_causes:
      - Stikstof is politiek; daar kan een netbeheerder niets aan doen.
      - De provincie is te traag met vergunningen.
      - Er zijn te weinig ecologen te vinden.
    mismatch_note: De provincie en de wet bepalen hoe lang de beoordeling duurt. Wanneer Voltana begint en hoe vaak het dezelfde berekening opnieuw maakt, bepaalt Voltana zelf.
    countermeasures: {parallel_ecology: 1.0, route_via_industrial_zone: 0.8, emission_free_build: 0.8, aerius_template: 0.7, diesel_bridge: 0.5}
    teaches: [stikstof, waste_waiting]
    effects:
      # estimate: per-project assessment after the Porthos ruling; Netbeheer Nederland warned of up to ~2 years for
      # large projects. For one MS/HS substation: the 60-day base wait x2.5 = ~5 months.
      - {target: hz_reinforcement.nature_permit, property: wait_time, value: 2.5}
    cost_per_week: 1500   # estimate: the waiting customer's claims and temporary measures, averaged over the queue
    clues:
      - {tool: data, key: true, depth: 0, text: "Een verzwaring in Havenzij duurt gemiddeld dertien maanden. Het bouwen zelf duurt zes weken."}
      - {tool: conversation, key: false, depth: 0, text: "'Stikstof is politiek. Daar kun je als netbeheerder niks aan doen.'"}
      - {tool: documents, key: true, depth: 1, text: "De stikstofberekening wordt pas gemaakt als het ontwerp definitief is. Daarna duurt de beoordeling van de natuurvergunning gemiddeld vijf maanden."}
      - {tool: conversation, key: true, depth: 1, text: "'Ik maak elke berekening vanaf nul. Elk project een nieuw model, terwijl onze stations bijna allemaal hetzelfde worden gebouwd.'"}
      - {tool: data, key: true, depth: 2, at: hz_reinforcement.design, text: "Bij de laatste vier verzwaringen stond het tracé al vast drie maanden voordat het ontwerp definitief was. Voor de stikstofberekening is het tracé genoeg."}
      - {tool: documents, key: true, depth: 2, text: "Het tracé van de nieuwe kabel loopt 1,2 kilometer langs natuurgebied De Slikken. Een tracé over het industrieterrein is 400 meter langer en blijft verder van de natuur."}
      - {tool: shadow, key: false, depth: 1, text: "Het bouwen van een verzwaring gaat vlot: de aannemer werkt netjes en op schema."}

countermeasures:
  - id: parallel_ecology
    name: De stikstofberekening naast het ontwerp
    tier: 3
    category: flow
    description: Zodra het tracé vastligt, begint de stikstofberekening, terwijl het ontwerp verder wordt afgemaakt. Ontwerp en vergunning lopen naast elkaar in plaats van na elkaar.
    budget: 5000
    team_hours: {work_prep: 10, grid_analysts: 5}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_reinforcement.nature_permit, property: starts_with, value: design}
  - id: route_via_industrial_zone
    name: Het tracé over het industrieterrein
    tier: 3
    category: flow
    description: De kabel gaat 400 meter om, over het industrieterrein, verder van De Slikken. Duurder aan kabel, korter in vergunning.
    budget: 35000   # estimate: 400 m of MS cable and trenching at ~EUR 85/m
    team_hours: {work_prep: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_reinforcement.nature_permit, property: wait_time, value: 0.6}
  - id: emission_free_build
    name: Emissievrij bouwen
    tier: 3
    category: flow
    description: De aannemer werkt met elektrische graafmachines en een elektrische kraan. Minder stikstof tijdens de bouw maakt de beoordeling eenvoudiger. Duurder in huur.
    budget: 25000   # estimate: rental premium for electric equipment over a six-week build
    team_hours: {work_prep: 5}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_reinforcement.nature_permit, property: wait_time, value: 0.75}
  - id: aerius_template
    name: Een rekensjabloon voor standaardstations
    tier: 2
    category: standard_work
    description: Voor de standaardstations en standaardtracés een vast AERIUS-rekenmodel, dat per project alleen wordt aangepast waar het anders is.
    budget: 6000
    team_hours: {grid_analysts: 15}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: hz_reinforcement.nature_permit, property: wait_time, value: 0.85}
  - id: diesel_bridge
    name: Een aggregatenpark als overbrugging
    tier: 1
    category: flow
    description: De klant krijgt een tijdelijke aansluiting op een aggregatenpark tot de verzwaring klaar is. Het aggregatenpark heeft zelf ook een stikstofbeoordeling nodig.
    budget: 2000
    team_hours: {grid_analysts: 10}
    decay_days: 365
    aftermath:                 # estimate: the generator park's own nitrogen assessment takes the same advisor's time for months
      after_days: 14
      days: 90
      effects:
        - {target: hz_reinforcement.nature_permit, property: wait_time, value: 1.2}
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialog: `dennis_aerius`.**

```yaml
dialogs:
  - id: dennis_aerius
    person: dennis
    kind: persuade
    mission: fix_nitrogen_permit
    owns: nitrogen_permit
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Als je komt vragen of het sneller kan: de provincie heeft vijf maanden. Wettelijk. Daar kan ik niets aan doen."
    position: {text: "Ik maak de stikstofberekening als het ontwerp definitief is. Anders reken ik twee keer.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "Als het ontwerp nog verandert en mijn berekening klopt niet meer, begint de provincie opnieuw. Dan ben je niet vijf maanden kwijt, maar tien.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En als het misgaat…", tags: [hesitation]}
        text: "Sinds Porthos weet iedereen wat er gebeurt als een berekening niet deugt. Dan gaat het naar de Raad van State, en dan is het mijn berekening die wordt afgeschoten. Ik ben de enige die dit hier doet. Als ik het verkeerd doe, staat het hele project stil. Met mijn naam erop."
        tags: [admission]
        unlocks: {facts: [heard:dennis_alone], proposals: [route_first_with_review]}
    reframe: "Vanuit Kanaalzone Waterstof? Die bouwen iets wat de stikstof juist omlaag moet brengen, en wachten op mijn stikstofberekening. Ja. Dat is ironisch."
    warning: "Ik heb drie berekeningen openstaan."
    data: ["nitrogen_permit:0", "nitrogen_permit:4"]
    proposals:
      - {id: start_on_route, addresses: [interest], label: "Beginnen zodra het tracé vastligt", say: "Begin met de berekening zodra het tracé vastligt. Voor stikstof is dat genoeg.", reply: "Het tracé, en het materieel. Ja. Als het tracé dan echt niet meer verandert."}
      - {id: route_first_with_review, hidden: true, addresses: [concern], label: "Tracé eerst, met een tweede paar ogen", say: "Wat als we het tracé eerder vastzetten, met jouw handtekening erbij, en een ecoloog van buiten jouw eerste berekeningen nakijkt? Dan sta je er niet alleen voor.", reply: "Een tweede paar ogen. Ik heb het in zes jaar nooit gehad. Ja. Dan durf ik eerder te beginnen."}
    experiments:
      - {id: template_on_one_station, addresses: [concern], label: "Een sjabloon, eerst op één station", say: "Maak een rekensjabloon voor de standaardstations, en probeer het eerst op Havenzij. Jij beslist of het goed genoeg is.", reply: "Op één station. En ik beslis. Dat is netjes."}
    co_proposal: {id: route_first_with_review, text: "Laat het tracé eerder vastzetten. En geef me iemand die meekijkt. Dan kan ik in parallel."}
    outcomes:
      commitment: "Afgesproken. Maandag begin ik met Havenzij. En die ecoloog wil ik zelf uitkiezen."
      partial: "Ik wil het. Als het tracé dan ook echt vastligt."
      heard: "Je bent de eerste die vraagt hoe het is om de enige te zijn."
      compliance: "Prima. Ik reken eerder. Op jouw verantwoording."
      ruined: "Stikstof is geen spreadsheet. Succes ermee."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose route_first_with_review +8 89 > ask: commitment (8 moves)
```

**Path dependence.**
- `flag:diesel_bridge` keeps KZW happy now (reputation +2). The generator park needs its own nitrogen assessment from the same single advisor, so the substation's permit slows for three months (the aftermath).
- A miss (deadline) closes `route_via_industrial_zone`; `parallel_ecology` and the template remain.
- `chose:nitrogen_permit:parallel_ecology` or `aerius_template` is read by `t4_investment_plan`'s "Standaardstations in serie": a standard station needs a standard permit route too (a proposed extra `any` branch, Q6).

**Grounding.**
- The Porthos ruling, Raad van State 2 November 2022: the construction exemption cannot be used. Netbeheer Nederland: a nitrogen assessment per expansion project, possibly two years longer permitting; "tens of thousands" of projects without an irrevocable nature permit (Solar Magazine 2022–2023; Netbeheer Nederland 2025 debate notes).
- AERIUS is the national calculation tool for nitrogen deposition.
- Emission-free construction equipment as a mitigation: *verify* the current provincial practice before release.
- 13 months, 6 weeks, 400 m, €85/m, 10 MW: estimates sized for the model.

**Engrossing.** A deadline with a face (KZW's €50M) and an irony (a hydrogen plant waiting on nitrogen). The herring "stikstof is politiek" is true. It only fails because it is not the whole story: *when* you start is yours.

### 1.10 `t3_stop_starting` — Stoppen met starten (M)

Principles tested: **long_term** (finish before you start) and **improve**. Temptation: hide work-in-progress so the number looks good. It holds two numbers for eight weeks: the act's breather and its test of sustain.

```yaml
missions:
  - id: t3_stop_starting
    name: Stoppen met starten
    kind: main
    tier: 3
    act: 4
    chapter: Stoppen met starten
    requires: {facts: {any: [done:fix_nitrogen_permit, failed:fix_nitrogen_permit]}}
    goal: {type: hold_kpi, stream: connections, kpis: [{kpi: wip_age, op: "<=", target: 21}, {kpi: throughput, op: ">=", target: base_x1.1}], weeks: 8}
    principles: [long_term, improve]
    briefing: "Er staan in Nova meer dan driehonderd aansluitingen 'onderhanden'. Iedereen is druk, en toch duurt alles lang. Ruud: 'Wat als we een tijdje minder beginnen, en meer afmaken?' Houd acht weken lang twee getallen vast: het oudste werk niet ouder dan drie weken, en er gaat minstens tien procent meer de deur uit dan vorig jaar."
    debrief: "Acht weken lang ging er meer uit dan erin, tot de stapel klein genoeg was om te stromen. Er staan nu {wip_after} aansluitingen onderhanden in plaats van {wip_before}, en ze zijn gemiddeld {lead_after} dagen onderweg in plaats van {lead_before}. Hetzelfde werk, dezelfde mensen. Minder tegelijk."
    debrief_variants:
      hidden_wip: "De getallen haalden het doel. Maar in de map 'concept' liggen {hidden} aanvragen die niemand telt. De klant telt ze wel."
    beats:
      - {on: accepted, who: joost, text: "Een limiet op wat we mogen beginnen? Dan liggen de dossiers bij de Intake in plaats van bij mij. Wat is daar beter aan?"}
      - {on: completed, who: frank, text: "Minder onderhanden, en meer af. Dat kan ik in de regiegroep uitleggen. Dat had ik niet verwacht."}
    temptations:
      - id: concept_folder
        who: it_manager
        when: accepted
        text: "Simpel: nieuwe aanvragen zetten we eerst op 'concept'. Die tellen niet mee als onderhanden. Je getallen zijn morgen groen."
        accept: "Je laat nieuwe aanvragen eerst als concept registreren."
        decline: "Je laat alles meetellen vanaf de aanvraag, ook als het rood wordt."
        accept_sets_flags: [flag:hidden_wip]
        accept_effects: {measure_bonus: {kpi: wip_age, value: -10}}
    teaches: [conwip, littles_law, wip]
    rewards: {xp: 3400, budget: 30000, reputation: 5}
    insights:
      go_see: "Hoeveel werk is er nu begonnen en niet af? Waar ligt het?"
      understand: "Als je hetzelfde werk met minder tegelijk doet, wat gebeurt er dan met hoe lang elk dossier duurt?"
      experiment: "Welke limiet kies je, en wat verwacht je in week twee te zien? En in week zes?"
      reflect: "Wat moest er gebeuren zodat dit ook in week acht nog klopte? Wie hield het vast?"
```

No new problem: it builds on `connections_wip_limit` (existing countermeasure, tier 2) and the KPI board. The player chooses the limit and runs it.

**Dialog: `joost_wip`.** Joost's arc from the dialog spec's cast: "resists the WIP limit (Act IV)".

```yaml
dialogs:
  - id: joost_wip
    person: joost
    kind: persuade
    mission: t3_stop_starting
    kpi_team: work_prep
    patience: 10
    # start: defender 40 + 0 + 10 x team trust work_prep + (trust - 50)/5 + memory
    #   after Act II's commitment (joost_output_kpi): 40 + 10 + 3 (trust 65) + 0 + 15 = 68, Open
    #   with Act II's compliance: 40 + 0 - 3 (trust 37) + 0 - 10 = 27, Op z'n hoede
    opening: "Ik heb gehoord wat je wilt. Een limiet. Ik heb er een spreadsheet voor gemaakt, natuurlijk."
    position: {text: "Als ik niets nieuws mag beginnen, staan mijn mensen stil terwijl de bak vol ligt.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Een klant belt, ik zie zijn dossier in de bak, en ik mag er niet aan beginnen. Wat zeg ik dan? 'Sorry, we zitten aan onze limiet'?", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [silence, empathy, reflect, inquiry]
        lead_in: {text: "En Frank…", tags: [hesitation]}
        text: "Frank loopt langs en ziet een volle bak en een tekenaar die koffie drinkt. Dan is mijn team lui. Het heeft twee jaar gekost om het beeld van Werkvoorbereiding te veranderen. Eén koffie op het verkeerde moment, en het is weg."
        tags: [admission]
        unlocks: {facts: [heard:joost_wip], proposals: [frank_at_the_board]}
    reframe: "Vanuit het dossier van de klant? Hm. Die ligt liever in een bak met tien dan in een bak met honderd. Dat is eigenlijk… gewoon Little."
    warning: "Even voor de duidelijkheid: ik ga mijn mensen niet laten stilzitten."
    proposals:
      - {id: limit_with_helping_rule, addresses: [interest], label: "Een limiet, en wie klaar is, helpt", say: "Een limiet, en wie zijn dossier af heeft en niet mag beginnen, helpt een collega afmaken.", reply: "Helpen. Dat doen ze nu nooit, want iedereen heeft zijn eigen stapel."}
      - {id: frank_at_the_board, hidden: true, addresses: [concern], label: "Frank komt kijken bij het bord", needs: {any: [committed:frank_kpi_targets]},
         say: "Wat als Frank één keer per week bij het bord komt kijken, met jou erbij? Dan ziet hij waarom iemand koffie drinkt: omdat de rest al stroomt.",
         reply: "Frank aan het bord. Dat… heeft hij bij de KPI's ook gedaan. Ja. Dan ziet hij het zelf."}
      - {id: limit_visible_queue, addresses: [concern], label: "Een limiet met een zichtbare wachtrij", say: "We zetten de limiet op het bord, met de wachtrij ernaast en de reden. Iedereen ziet dat het een keuze is, geen luiheid.", reply: "Een keuze op het bord. Met de reden erbij. Dat kan ik uitleggen."}
    co_proposal: {id: frank_at_the_board, text: "Laat Frank het zelf zien. Op vrijdag, bij het bord. Dan hoef ik het niet uit te leggen."}
    outcomes:
      commitment: "Afgesproken. En als iemand koffie drinkt, staat er op het bord waarom."
      partial: "Ik wil het proberen. Als Frank weet wat hij ziet."
      heard: "Fijn dat je het vroeg. Echt. Ik had een spreadsheet klaarliggen om je tegen te spreken."
      compliance: "Prima. Een limiet. Ik zet hem hoog genoeg."
      ruined: "Dus we beginnen te veel. Dank je. Mijn spreadsheet zegt iets anders."
    # route (start 68, with Act II's commitment): open question > 64 capped (interest; the ceiling of an unrevealed layer applies first)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern) > propose frank_at_the_board +8 89 > ask: commitment (5 moves)
    # route (start 27, after compliance): repair +12 39 > mood +8 47 > open question +6 53 > paraphrase +7 60 (heard, interest) > reflect +10 70
    #        > inquiry +8 78 (lead-in, cue) > silence +12 > 81 capped (concern) > propose limit_visible_queue +8 89 > ask (10 moves: all his patience)
```

**Path dependence.**
- Act II echoes here:
  - `committed:frank_kpi_targets` unlocks `frank_at_the_board`, the easiest concern answer.
  - Joost's Act II commitment starts him at 68.
  - Compliance in Act II starts him at 27, and the player must earn him again (the repair chip is there).
- `flag:hidden_wip` passes the goal sooner (the measure bonus). In Act V, the ACM and the NTA 8120 audit count from the application date (the tier-2 `talk_regulation` clue: "De klok loopt vanaf de aanvraag"). The concept folder surfaces as an audit finding: reputation −10 and a debrief variant. It is cleared by a re-run of this mission's goal without the folder (the `reopen` path).

**Grounding.**
- Little's law (WIP = throughput × lead time): Little (1961); Hopp & Spearman, *Factory Physics*.
- CONWIP: Spearman, Woodruff & Hopp (1990), "CONWIP: a pull alternative to kanban", *International Journal of Production Research* 28(5).
- The existing `connections_wip_limit` countermeasure and the "what WIP costs" decision (PLAN.md 2026-10-12).
- 300, 21 days and +10 % are estimates for the model; the content test checks the target is reachable on the expert path.

**Engrossing.**
- The breather of the act is a test: nothing new happens if you do it right, for eight weeks.
- The temptation is the most common one in real organisations: making the number look good by changing what counts.

### 1.11 Side missions of Act IV

Sides are small ("four ones": one person, one place, one twist, one object; ≤ 4 clues). The coach does not coach them; people still talk.

#### `fix_non_firm_unused` — Niemand wil flex (S)

Principle: **long_term** (offer flexibility first, not last). The object: the 40-page contract nobody reads.

```yaml
missions:
  - id: fix_non_firm_unused
    name: Niemand wil flex
    kind: side
    tier: 3
    act: 4
    chapter: Wie gaat er voor?
    requires: {missions: [t3_map_region]}
    goal: {type: solve, problem: non_firm_unused}
    principles: [long_term, respect]
    briefing: "Voltana biedt bedrijven in de wachtrij al een jaar een flexibel contract aan: transport, behalve op de drukste uren, tegen een lager tarief. Er hebben er twee getekend. Thomas: 'Ze horen het pas na maanden wachten, in een contract van veertig pagina's.'"
    debrief: "Een ondernemer hoort nu bij zijn eerste gesprek wat flex hem kan opleveren. {n_signed} bedrijven tekenden dit kwartaal. ColdChain laadt zijn vrachtwagens 's nachts, en de koelcellen blijven gewoon koud."
    temptations:
      - id: flex_mandatory
        who: mt_member
        when: accepted
        text: "Maak flex gewoon verplicht in elk nieuw contract in Havenzij. Dan tekenen ze wel."
        accept: "Je maakt flex verplicht in nieuwe contracten."
        decline: "Je laat klanten flex eerst zien en kiezen."
        accept_sets_flags: [flag:flex_forced]
        accept_effects: {trust: {key_accounts: -1}}
    teaches: [alternatieve_transportrechten, netcongestie, customer_value]
    rewards: {xp: 1200, budget: 10000, reputation: 2}

problems:
  - id: non_firm_unused
    tier: 3
    name: Niemand wil flex
    step: congestion.offer
    waste: overprocessing
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Van de bedrijven in de wachtrij hebben er twee een flexibel contract getekend.
      - Het flexibele aanbod komt pas na maanden wachten, als apart contract van veertig pagina's.
    root_cause: Flex wordt aangeboden als laatste redmiddel, na de netstudie en maanden in de wachtrij, in een lang maatwerkcontract. Bij het eerste gesprek vraagt niemand wanneer een bedrijf echt stroom nodig heeft, dus niemand ziet dat een deel van de vraag buiten de piek valt.
    plausible_causes:
      - Ondernemers willen geen risico; ze willen altijd vast vermogen.
      - Het tarief van flex is niet aantrekkelijk genoeg.
    mismatch_note: Een lager tarief helpt niet als het aanbod pas komt wanneer de klant al maanden plannen maakt rond vast vermogen.
    countermeasures: {standard_flex_at_first_contact: 1.0, acm_pilot_time_bound: 0.9, group_contract_business_park: 0.7, flex_mandatory: 0.5}
    teaches: [alternatieve_transportrechten]
    effects:
      # estimate: flexible offers that come late keep requests in the queue ~50% longer at the offer step
      - {target: congestion.offer, property: wait_time, value: 1.5}
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de 214 bedrijven in de wachtrij kregen er 31 een flexibel aanbod. Gemiddeld na zeven maanden wachten. Er tekenden er twee."}
      - {tool: documents, key: true, depth: 1, text: "Het flexibele contract is veertig pagina's maatwerk. Het standaardcontract voor vast vermogen is zes pagina's."}
      - {tool: listen_in, key: true, depth: 1, at: congestion.intake, text: "'Wanneer we stroom nodig hebben? Overdag voor de koelcellen. 's Nachts om de vrachtwagens te laden. Waarom vraagt u dat?'"}
      - {tool: conversation, key: false, depth: 0, text: "'Ondernemers willen zekerheid. Flex is voor hippies met een batterij.'"}

countermeasures:
  - id: standard_flex_at_first_contact
    name: Flex bij het eerste gesprek
    tier: 3
    category: flow
    description: In het eerste gesprek vraagt Grootzakelijke klanten wanneer een bedrijf stroom nodig heeft. Een standaardaanbod van twee pagina's laat zien wat vast en wat flexibel kan, met de prijs erbij.
    budget: 6000
    team_hours: {key_accounts: 25}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.8}
  - id: acm_pilot_time_bound
    name: Een pilot met tijdsgebonden transport
    tier: 3
    category: flow
    description: Binnen een pilot van de ACM krijgen bedrijven op het regionale net transport in een vast deel van de uren, tegen korting.
    budget: 8000
    team_hours: {key_accounts: 15, grid_analysts: 10}
    decay_days: null
    needs: {none: [failed:acm_visit]}       # the catalogue's door (Act III)
    preparation: "De ACM moet Voltana eerst weer vertrouwen."
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: congestion.capacity_queue, property: wait_time, value: 0.85}
  - id: group_contract_business_park
    name: Een groepscontract op het bedrijventerrein
    tier: 3
    category: flow
    description: De bedrijven op de Kanaalzone delen samen één transportvermogen en verdelen het onderling. Een pilot, zoals elders in het land.
    budget: 10000
    team_hours: {key_accounts: 30}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: flex_mandatory
    name: Flex verplicht in nieuwe contracten
    tier: 1
    category: standard_work
    description: Elk nieuw contract in Havenzij is flexibel, of de klant het wil of niet.
    budget: 500
    team_hours: {key_accounts: 5}
    decay_days: 180
    trust: {key_accounts: -1}
    aftermath: {after_days: 60, days: 1, reputation: -3}   # estimate: complaints and an ACM question about non-discrimination
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []

dialogs:
  - id: aziz_coldchain
    person: aziz
    kind: persuade
    mission: fix_non_firm_unused
    owns: non_firm_unused
    patience: 9
    # start: defender 40 + 0 + 0 + 0 + 0 = 40; with flag:curtailment_letter (tier-2 heatwave temptation) memory -10 = 30
    opening: "Mohammed Aziz, ColdChain. Als u flex komt verkopen: mijn koelcellen kunnen niet uit. Nooit."
    position: {text: "Ik heb vast vermogen nodig. Twee megawatt. Geen gedoe.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Overdag draaien de koelcellen. 's Nachts laden we de vrachtwagens. Elektrisch, sinds vorig jaar. Dat is het grootste deel van mijn vraag, eerlijk gezegd.", tags: [claim]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "Kijk, het punt is…", tags: [hesitation]}
        text: "Als de koeling uitvalt, gooi ik voor tonnen aan vlees en vis weg. De verzekeraar dekt niets als ik zelf een contract heb getekend waarin staat dat u mag afschakelen. Dan ben ik niet alleen mijn lading kwijt. Dan ben ik mijn bedrijf kwijt."
        tags: [admission]
        unlocks: {facts: [heard:aziz_cooling], proposals: [split_cooling_and_charging]}
    reframe: "Vanuit het net? Ja. 's Nachts is het hier leeg. Behalve bij mij. Hm."
    warning: "Ik heb een vrachtwagen die op u wacht."
    data: ["non_firm_unused:0", "non_firm_unused:2"]
    proposals:
      - {id: flex_offer, addresses: [interest], label: "Een flexibel contract", say: "Een flexibel contract: transport, behalve op de drukste uren.", reply: "En de koelcellen dan?"}
      - {id: split_cooling_and_charging, hidden: true, addresses: [concern], label: "Koeling vast, laden flexibel", say: "Wat als de koelcellen vast vermogen houden, en alleen het laden van de vrachtwagens flexibel wordt? Op de drukste uren wacht het laden, de koeling nooit.", reply: "De koeling vast. Het laden flexibel. Dat kan ik aan mijn verzekeraar uitleggen. Dat kan ik zelfs aan mijn vader uitleggen."}
    experiments:
      - {id: charging_plaza_trial, addresses: [concern], label: "Een kwartaal alleen het laadplein", say: "Probeer het een kwartaal met alleen het laadplein flexibel. De koeling blijft zoals hij is.", reply: "Alleen het laadplein. Mijn koeling blijft vast. Dan kan ik het proberen."}
    co_proposal: {id: split_cooling_and_charging, text: "Als de koeling er nooit onder valt, mag de rest flexibel. Dat zijn toch twee verschillende dingen?"}
    outcomes:
      commitment: "Afgesproken. En ik zeg het tegen de buren op de Kanaalzone. Die hebben hetzelfde."
      partial: "Ik wil het wel. Als mijn verzekeraar het goed vindt."
      heard: "U bent de eerste die vraagt waarom ik twee megawatt wil."
      compliance: "Als het moet, teken ik. Mijn advocaat leest mee."
      ruined: "Mijn koelcellen zijn geen experiment."
    variants:
      - needs: {all: [flag:curtailment_letter]}
        position: {text: "Vorige zomer kreeg ik een brief dat mijn zonnedak misschien uit moest. Nu wilt u dat ik flexibel ben?", tags: [claim, feeling]}
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose split_cooling_and_charging +8 87 > ask: commitment (7 moves)
```

**Path dependence.** `acm_pilot_time_bound` needs `none: [failed:acm_visit]`: the Act III door (catalogue). `flag:curtailment_letter` (the tier-2 heatwave temptation) makes Aziz start lower, so a short-term choice in Act III costs trust with a customer in Act IV. `flag:flex_forced` costs reputation and lowers `t4_investment_plan`'s "Flex eerst, koper later" forecast (customers who were forced do not shift their use).

**Grounding.** Non-firm transport on the regional grid (tier-2 draft §2.16 grounding; Dirkzwager). The groepstransportovereenkomst as an ACM draft code decision with pilots, e.g. Liander's GTO on Deventer A1 (Solar Magazine; ACM consultation responses, 2025; *verify the final decision*). Separating critical load from flexible load (cooling versus EV charging) is standard practice in congestion advice; the numbers are estimates.

#### `fix_solar_feedin_wait` — De zonneweide wacht (S)

Principle: **improve** (share what exists before you build more). The object: the farm's succession papers.

```yaml
missions:
  - id: fix_solar_feedin_wait
    name: De zonneweide wacht
    kind: side
    tier: 3
    act: 4
    chapter: Eén regio
    requires: {missions: [t3_map_region]}
    goal: {type: solve, problem: solar_feedin_wait}
    principles: [improve, long_term]
    briefing: "De familie Verhoeven heeft een zonneweide van vijf hectare klaarliggen op De Hoge Akker in Lindeveld. Ze wacht al twintig maanden op transportcapaciteit om terug te leveren. Twee kilometer verderop draait de windmolen van de buren, met een aansluiting die 's middags bijna leeg is."
    debrief: "De zonneweide van de Verhoevens levert nu terug via de aansluiting van de windmolen, en waar het nodig is, toppen ze de piek af. Ze verliezen een paar procent opbrengst, en ze winnen twee jaar. Gerard Verhoeven: 'Mijn zoon neemt de boerderij over. Met een weide die draait.'"
    teaches: [cable_pooling, netcongestie, energietransitie]
    rewards: {xp: 1200, budget: 10000, reputation: 2}

problems:
  - id: solar_feedin_wait
    tier: 3
    name: De zonneweide wacht
    step: lv_feedin.capacity_queue
    waste: waiting
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Zonneweides in Lindeveld wachten gemiddeld twintig maanden op capaciteit om terug te leveren.
      - Aansluitingen van windmolens in hetzelfde gebied zijn op zonnige middagen grotendeels leeg.
    root_cause: Elke zonneweide vraagt een eigen aansluiting met eigen capaciteit aan, voor zijn hoogste piek, die maar een paar uur per jaar voorkomt. Niemand biedt aan om een bestaande aansluiting te delen of de piek af te toppen, terwijl zon en wind zelden tegelijk op hun hoogst zijn.
    plausible_causes:
      - Het net in Lindeveld is vol; alleen verzwaren helpt.
      - Boeren willen gewoon alles terugleveren wat ze opwekken.
    mismatch_note: Verzwaren duurt jaren. De ruimte die er al is, in een aansluiting die op zonnige middagen leeg is en in de piek die maar een paar uur duurt, wordt niet gebruikt.
    countermeasures: {cable_pooling: 1.0, peak_shaving_contract: 0.8}
    teaches: [cable_pooling]
    effects:
      # estimate: requests wait for full peak capacity; ~x1.4 the base queue wait
      - {target: lv_feedin.capacity_queue, property: wait_time, value: 1.4}
    clues:
      - {tool: data, key: true, depth: 0, text: "De windmolen van De Hoge Akker gebruikt op zonnige middagen gemiddeld een derde van zijn aansluiting."}
      - {tool: documents, key: true, depth: 1, at: lv_feedin.offer, text: "Het aanbod voor een zonneweide is altijd een eigen aansluiting voor het volle piekvermogen. Delen of aftoppen staat er niet in."}
      - {tool: data, key: true, depth: 1, text: "Een zonneweide levert maar een paar honderd uur per jaar boven zeventig procent van zijn piekvermogen."}
      - {tool: conversation, key: false, depth: 0, text: "'Het net is vol. Wachten, of verzwaren. Iets anders is er niet.'"}

countermeasures:
  - id: cable_pooling
    name: Eén aansluiting voor zon en wind
    tier: 3
    category: flow
    description: De zonneweide en de windmolen, vlak bij elkaar, vragen samen één aansluiting aan en delen de capaciteit. Als het zowel hard waait als de zon schijnt, wordt de opwek even beperkt. Alleen voor zon en wind, achter een aansluiting boven 2 MVA.
    budget: 15000
    team_hours: {key_accounts: 15, grid_analysts: 15}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: lv_feedin.capacity_queue, property: wait_time, value: 0.5}
  - id: peak_shaving_contract
    name: De piek aftoppen
    tier: 3
    category: flow
    description: De zonneweide sluit aan op zeventig procent van zijn piekvermogen. Hij verliest een klein deel van zijn jaaropbrengst en past veel sneller op het net.
    budget: 4000
    team_hours: {key_accounts: 10, grid_analysts: 5}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: lv_feedin.capacity_queue, property: wait_time, value: 0.7}

dialogs:
  - id: verhoeven_cap
    person: verhoeven
    kind: persuade
    mission: fix_solar_feedin_wait
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Gerard Verhoeven. Kom binnen, laarzen mogen aan. Gaat het eindelijk over onze weide?"
    position: {text: "Ik wil terugleveren wat ik opwek. Alles. Daar heb ik voor betaald.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "De bank heeft geleend op een opbrengst. Zoveel megawattuur per jaar. Elk procent minder is een procent minder aflossing.", tags: [claim]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "En dan is er nog…", tags: [hesitation]}
        text: "Mijn zoon wil de boerderij overnemen. Melkvee is geen toekomst meer, met de stikstof. Die weide is zijn toekomst. Als hij nog drie jaar stilstaat, gaat Jesse ergens anders werken. En dan is dit de laatste generatie Verhoeven op De Hoge Akker."
        tags: [admission]
        unlocks: {facts: [heard:verhoeven_son], proposals: [two_years_earlier]}
    reframe: "Vanuit de buurman met de windmolen? Die betaalt voor een aansluiting die 's middags leeg staat. Hm. Die zou er ook beter van worden."
    warning: "Ik moet zo melken."
    data: ["solar_feedin_wait:0", "solar_feedin_wait:2"]
    proposals:
      - {id: cap_at_seventy, addresses: [interest], label: "Aftoppen op zeventig procent", say: "Als u aansluit op zeventig procent van uw piek, verliest u een paar procent van uw jaaropbrengst.", reply: "Een paar procent. Dat moet ik aan de bank uitleggen."}
      - {id: two_years_earlier, hidden: true, addresses: [concern], label: "Twee jaar eerder draaien", say: "Wat als u een paar procent opbrengst inlevert, en daarvoor twee jaar eerder draait? Twee jaar opbrengst nu is meer dan een paar procent later. En Jesse heeft volgend jaar al een weide die draait.", reply: "Twee jaar eerder. Volgend jaar. Dat… daar kan Jesse mee verder."}
    experiments:
      - {id: share_with_neighbour, addresses: [concern], label: "Samen met de windmolen", say: "Vraag samen met uw buurman één aansluiting aan, voor zon en wind. Hij heeft ruimte als u die het hardst nodig heeft.", reply: "Met Van Dam? We praten al twintig jaar niet over die sloot. Maar goed. Voor Jesse."}
    co_proposal: {id: share_with_neighbour, text: "Als Van Dam meedoet met zijn molen, hoeven we toch niet allebei een eigen kabel?"}
    outcomes:
      commitment: "Afgesproken. Ik bel Van Dam vanavond. Of morgen. Na het melken."
      partial: "Ik wil het wel. Als de bank meegaat."
      heard: "Fijn dat u het vroeg. Van wie de weide eigenlijk is."
      compliance: "Prima. Zeventig procent. Ik zeg het tegen de bank."
      ruined: "Kom maar terug als het net weer leeg is."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose two_years_earlier +8 87 > ask: commitment (7 moves)
```

**Grounding.**
- Cable pooling: art. 1(7) Elektriciteitswet 1998, for two or more wind or solar parks close together behind a connection above 2 MVA, applying together; not (yet) for storage or consumers (Dirkzwager; RVO "Cable pooling"; *verify the article number under the Energiewet*).
- Peak shaving at 70 % losing "a few percent" of annual yield: an often-cited rule of thumb for Dutch solar parks (*verify* a Netbeheer Nederland or RVO figure before quoting a number).
- Twenty months: an estimate in line with the multi-year queues of 2025.

#### `sector_energy_hub` — Een energiehub op de Kanaalzone (S, sector arc)

Thomas as an expert; three topics. The talk plants Act V's flex market.

```yaml
missions:
  - id: sector_energy_hub
    name: Een energiehub op de Kanaalzone
    kind: side
    tier: 3
    act: 4
    arc: sector
    requires: {missions: [fix_non_firm_unused]}
    goal: {type: talk_to, person: thomas, topics: 3}
    principles: [improve]
    briefing: "ColdChain, Kanaalzone Waterstof en drie andere bedrijven op de Kanaalzone willen samen een energiehub. Thomas weet hoe dat werkt, en waar het nog niet werkt. Vraag het hem."
    debrief: "Een hub deelt wat er al is: vermogen, opslag, tijd. Thomas: 'Het lastigste is niet de techniek. Het is dat vijf bedrijven elkaar moeten vertrouwen met hun stroom.'"
    teaches: [energiehub, groepstransportovereenkomst, cable_pooling]
    rewards: {xp: 600, trust: {key_accounts: 1}}

people:
  - id: thomas
    topics:
      - id: energiehub
        ask: "Wat is een energiehub eigenlijk?"
        open: "Een paar bedrijven die hun stroom samen regelen. De een wekt op, de ander gebruikt, een derde slaat op. Samen hebben ze minder van het net nodig dan ieder apart, omdat hun pieken niet tegelijk vallen. Op een bedrijventerrein is dat vaak zo."
        closed: "Bedrijven die samenwerken."
        teaches: [energiehub]
      - id: groepscontract
        ask: "Hoe regel je dat met de netbeheerder?"
        open: "Met een groepscontract: één transportvermogen voor de hele groep, en zij verdelen het onderling. Het is nog nieuw. Er lopen pilots, zoals in Deventer, en de ACM werkt aan de regels. Wie nu meedoet, doet mee aan iets wat nog vorm krijgt."
        closed: "Met een contract."
        teaches: [groepstransportovereenkomst]
      - id: delen_grenzen
        ask: "Kan iedereen zijn aansluiting zomaar delen?"
        open: "Nee. Een zonneweide en een windmolen vlak bij elkaar mogen één aansluiting delen. Een batterij of een fabriek erbij: dat mag nog niet, al vragen de netbeheerders erom. Dus een hub is nu vooral afspraken maken, niet kabels delen."
        closed: "Niet zomaar."
        teaches: [cable_pooling]
```

#### `coach_work_prep_lead` — Joost coacht zijn team (S, coach)

Principle: **respect** (develop a person rather than solve for him). The catalogue's C7 coach goal: the five Kata questions in order, three sessions. Giving the answer voids the session; it is the temptation, offered by Joost himself.

```yaml
missions:
  - id: coach_work_prep_lead
    name: Joost coacht zijn team
    kind: side
    tier: 3
    act: 4
    requires: {missions: [t3_map_region], trust: {work_prep: 1}}
    goal: {type: coach, person: joost, sessions: 3}
    principles: [respect, improve]
    briefing: "Joost wil zelf leren verbeteren, met zijn team, zonder dat jij er steeds bij bent. Drie keer een kwartier, aan het bord van Werkvoorbereiding. Jij stelt de vijf vragen; hij zoekt de antwoorden."
    debrief: "Drie gesprekken, vijf vragen, en Joosts eigen experiment: {npc_experiment_result}. Volgende week coacht hij Anouk. Met dezelfde vijf vragen, en een kaartje in zijn borstzak."
    npc_experiment:
      id: oldest_first_card
      name: Elke ochtend eerst het oudste dossier
      description: Joost zet elke ochtend het oudste dossier met een rode kaart bovenaan het bord. Wie vrij is, pakt dat eerst.
      effects:
        - {target: connections.design, property: wait_time, value: 0.95}   # estimate: a small, real gain
    temptations:
      - id: give_the_answer
        who: joost
        when: session
        text: "Zeg nou gewoon wat ik moet doen. Jij weet het toch?"
        accept: "Je zegt hem wat je zelf zou doen."
        decline: "Je vraagt: 'Wat denk jij dat de volgende stap is, en wat verwacht je dat er gebeurt?'"
        accept_effects: {session_counts: false}
    teaches: [coaching_kata, improvement_kata, respect_for_people]
    rewards: {xp: 1000, reputation: 3}
```

**The coaching script** (Rother's five questions; the moves are `inquiry` and `open_question` with fixed lines, dialog spec §5.6). Joost's answers grow over the three sessions. The player sees his growth in his words, not in a meter.

| Question (player) | Session 1: Joost | Session 2 | Session 3 |
|---|---|---|---|
| 1. "Wat is je doelsituatie?" | "Minder achterstand." | "Geen dossier ouder dan drie weken. Binnen een kwartaal." | "Geen dossier ouder dan drie weken. En dat het team zelf ziet als het misgaat." |
| 2. "Hoe is het nu?" | "Druk." | "Het oudste is 34 dagen. Vorige week 38." | "Het oudste is 23 dagen. Maar dat is er één; de rest is jonger dan twee weken. Ik heb het geteld." |
| 3. "Welke obstakels houden je tegen? Welke pak je nu aan?" | "Te weinig mensen." *(the player waits: silence)* "… En dat niemand weet welk dossier het oudst is." | "Dat het oudste dossier altijd het moeilijkste is, dus iedereen schuift het door. Die pak ik nu aan." | "Dat ik het zelf nog steeds bijhoud. Als ik op vakantie ben, gebeurt het niet." |
| 4. "Wat is je volgende stap, en wat verwacht je?" | "Een rode kaart op het oudste dossier. Ik verwacht… dat het eerder wordt opgepakt?" | "Het oudste dossier in tweetallen. Ik verwacht dat het binnen twee dagen van het bord is." | "Anouk houdt de rode kaart bij. Ik verwacht dat het blijft werken als ik er niet ben." |
| 5. "Wanneer kunnen we zien wat je ervan leerde?" | "Volgende week dinsdag." | "Vrijdag." | "Over twee weken. Als ik terug ben van vakantie." |

Asking the questions out of order, or answering for him (the temptation), "teaches but does not count" (tier-2 draft §2.13). A blaming question ends the session and costs `work_prep` trust. D23 *Zelf coach* is earned here or with Sanne in Act III.

#### `lsw_layered_audit` — Gelaagde audit (R) and `sustain_connections` — Houd het vast (S)

Both are as in the catalogue §3.6. Text only:

```yaml
missions:
  - id: lsw_layered_audit
    name: Gelaagde audit
    kind: side
    tier: 3
    act: 4
    requires: {missions: [t3_map_region]}
    recurring: {every_days: 28}
    goal: {type: routine, kind: audit, places: standardised_fix_places, count: 3, every_days: 28, times: 1}
    principles: [long_term]
    briefing: "Drie verbeteringen die je ooit hebt gestandaardiseerd. Loop ze na: niet om iemand te betrappen, maar om te zien of de standaard nog klopt met het werk. Een standaard die niet meer klopt, past je aan; een standaard die niemand meer volgt, vraag je waarom."
    debrief: "Je liep drie standaarden na. {audit_line} Een audit is een vraag aan de standaard, niet aan de mensen."
    teaches: [standard_work, leader_standard_work]
    rewards: {xp: 400}

  - id: sustain_connections
    name: Houd het vast
    kind: side
    tier: 3
    act: 4
    requires: {missions: [t3_kaizen_week]}
    goal: {type: hold_kpi, stream: connections, kpis: [{kpi: on_time, op: ">=", target: 0.9}], weeks: 8}
    principles: [long_term, improve]
    briefing: "Na de kaizenweek haalt Nova negen op de tien aansluitingen op tijd. Houd dat acht weken vast. Niet door harder te werken, maar door te zien wanneer het begint te glijden."
    debrief: "Acht weken boven de negentig procent. {slip_line} Wat je acht weken vasthoudt, wordt gewoonte. Wat je niet vasthoudt, wordt een herinnering."
    teaches: [sustain, leading_lagging]
    rewards: {xp: 1000, reputation: 3}
```

### 1.12 The repair quest, worked: `repair_long_drives` — De mannen terughalen

Catalogue §2.15: a poor fix opens a repair side quest 42 days after `poor_fix:<problem>` is set, once the gap shows in the KPI. This is the authored override for `long_drives`. It shows how a repair **reopens** a locked option.

```yaml
problems:
  - id: long_drives
    repair:
      name: De mannen terughalen
      briefing: "Lindeveld rijdt nog steeds. {poor_fix_line} Joke: 'We zijn het een jaar geprobeerd zoals het nu is. Kunnen we het nog eens hebben over die schuur in Oosthoek?'"
      briefing_lines:
        mobile_van_stock: "Er ligt meer in de bussen, maar elke dag begint nog steeds in Nova."
        outsource_area: "De aannemer doet het werk, en de monteurs van Joke doen klussen die ze niet kennen. Twee hebben al gesolliciteerd bij de aannemer."
      debrief: "Lindeveld werkt vanuit Oosthoek. De ploeg rijdt minder en werkt dichter bij huis. Joke: 'Nu kan het MT ook een vaste ploeg hier neerzetten. Daar was eerst geen plek voor.'"
      dialog: joke_depot_repair      # a variant of joke_depot that starts with the repair chip and the memory of the poor fix
    # The quest's goal: rework_fix {problem: long_drives}: a short A3 that swaps the running countermeasure,
    # a 14-day Check that must show the gain, and the problem's effects do not come back while you rework.
    # Result: repaired:long_drives, chose:long_drives:<new>, xp 600, reputation +2. Clears flag:lindeveld_allowance.
```

**What it reopens.** `repaired:long_drives` satisfies the `any` branch of:
- the crew strategy's *Lindeveld crew* option, if the crew strategy is still to come or is offered again in Act V's review;
- `t4_investment_plan`'s "Meer monteurs in Lindeveld".

A player who chose the van stock in Act IV, did the repair, and then reaches Act V sees the Lindeveld option **open**. The same save without the repair sees it **locked**, with the hint "In Lindeveld moet de basis eerst kloppen." This is the content test of catalogue K11 for this problem.

**Grounding.** The repair mechanism: catalogue §2.15 and C20. The trade of the allowance for the depot is fiction, with the respect principle in mind: the team itself decides to give up the allowance, it is not taken from them.

---

## 2. The IT track, tier 3: "De app die niemand gebruikt"

Opens with `t3_map_region`'s `it_campus` unlock. It runs in parallel with Act IV: the player holds one main at a time, grid or IT, and the coach coaches whichever is active. Problems carry `track: it` and their own maturity (catalogue C17d).

**Order (decided 2026-10-15): the field app first, as in the catalogue.** The customer portal and the meter-data platform come later, in the tier-4 IT chapter. Their drafts are kept ready in §2.8.

**The thread.** The monteurs from Acts I–II come back through the tablet:
- Act I's meter-cupboard photos (`fix_installer_not_ready`);
- Act II's as-built sketch "op de motorkap" (`fix_revision_backlog`);
- the close-out at Petra's desk (`fix_done_but_not_closed`).

What the player fixed in the process now meets the software that is supposed to carry it, and the monteurs work around it with paper and a WhatsApp group.

The chapter's twist (§2.2): the fix the monteurs designed themselves cannot reach their tablets, because the app ships twice a year. The release train is not an abstraction; it is Ricardo's afmeldscherm.

**Chapters:**
- "Volg één wijziging": the map, the bypassed app.
- "Kleiner uitbrengen": releases, the fork, regression.
- "De trein": PI planning.

**Sides:** the ops–dev wall, the RTE, the system demo.

### 2.1 `it_map_feature_stream` — Eén wijziging, elf weken (M)

Principles tested: **improve** (go to the gemba, also in IT) and **respect** (sit with the team and the users, not with the dashboard). Temptation: the cycle time the ticket tool already shows.

```yaml
missions:
  - id: it_map_feature_stream
    name: Eén wijziging, elf weken
    kind: main
    tier: 3
    act: 6
    chapter: Volg één wijziging
    track: it
    requires: {missions: [t3_map_region]}
    goal: {type: map_stream, stream: it_features, measure: time_study}
    principles: [improve, respect]
    briefing: "Marco's monteurs vroegen in het voorjaar of ze bij het afmelden in de veldapp een foto van de meterkast konden meesturen. Elf weken later kan het nog steeds niet. Noor Hendriks, product owner van de veldapp: 'Het is een kleine wijziging. Twee dagen werk.' Volg die ene wijziging van idee tot de tablet van de monteur, stap voor stap, en kijk waar de elf weken zitten."
    debrief: "Twee dagen werk, {calendar_days} dagen onderweg. {wait_share}% van de tijd lag de wijziging ergens te wachten: op een plek in de backlog, op een testomgeving, op de release van maart. In Nova zag je hetzelfde met een aansluiting. Het is geen IT-probleem. Het is een stroom."
    beats:
      - {on: accepted, who: noor, text: "Je kunt de cycle time gewoon uit Jira halen. Die staat op zes dagen. Waarom wil je meelopen?"}
      - {on: completed, who: ricardo, text: "Elf weken voor een foto. Weet je hoe wij het nu doen? Kom maar eens kijken in de bus."}
    temptations:
      - id: tool_cycle_time
        who: noor
        when: accepted
        text: "De cycle time staat al in Jira: van 'in progress' tot 'done', gemiddeld zes dagen. Neem die, dan heb je je kaart vandaag."
        accept: "Je neemt de cycle time uit het ticketsysteem."
        decline: "Je loopt de wijziging zelf na, ook vóór en na het ticket."
        accept_sets_flags: [flag:tool_cycle_time]
        accept_effects: {complete_goal: true}
    teaches: [value_stream_identification, lead_time, gemba]
    rewards: {xp: 2600, budget: 20000, reputation: 5}
    insights:
      go_see: "Waar begint een wijziging echt: bij het ticket, of bij de vraag van de monteur? Wanneer eindigt hij?"
      understand: "Hoeveel van de elf weken wordt er aan gewerkt? Waar wacht hij het langst?"
      experiment: "Welk getal wil je volgen: de tijd in het ticket, of de tijd die de monteur ziet?"
      reflect: "Wat zag je in IT dat je in Nova ook al zag?"
```

**Path dependence.**
- `flag:tool_cycle_time`: the IT stream's VSM view shows only "in progress → done" (six days), so the waits before (the backlog) and after (the release) disappear. `fix_release_twice_a_year`'s depth-0 key clue moves to depth 1.
- The way back: walking it later (a `lsw_system_demo` visit at refine and release clears it).

**Grounding.** Value stream identification in IT and the gap between ticket cycle time and user lead time: Poppendieck & Poppendieck, *Implementing Lean Software Development* (2006); Forsgren, Humble & Kim, *Accelerate* (2018), "lead time for changes". Two days and eleven weeks are estimates.

### 2.2 `fix_field_app_bypassed` — De app die niemand gebruikt (M)

Principles tested: **respect** (the users designed their own workaround; honour it) and **long_term**. The catalogue's mission, made content-ready. The chapter's twist: the best countermeasure is `release_gated`.

```yaml
missions:
  - id: fix_field_app_bypassed
    name: De app die niemand gebruikt
    kind: main
    tier: 3
    act: 6
    chapter: Volg één wijziging
    track: it
    requires: {missions: [it_map_feature_stream]}
    goal: {type: solve, problem: field_app_bypassed}
    principles: [respect, long_term]
    briefing: "Bij Meetdata & registratie typt Rachid elke middag werkbonnen over: papieren formulieren, en foto's die monteurs in een WhatsApp-groep zetten. Volgens IT gebruikt negentig procent van de monteurs de veldapp. Ricardo, monteur en beheerder van de WhatsApp-groep, laat je zijn telefoon zien: 'Dit is onze echte app.'"
    debrief: "Monteurs melden een klus nu af op de tablet, in vier schermen in plaats van veertien, ook in een kelder zonder bereik. Rachid typt niets meer over, en een aansluiting staat {days_saved} dagen eerder op 'klaar'. Ricardo heeft de WhatsApp-groep niet opgeheven. Er staan nu alleen nog foto's van verjaardagstaarten in. {release_line}"
    debrief_variants:
      poor_fix: "Monteurs melden af op papier met een vast formulier, en Rachid typt sneller over. De nieuwe afmeldschermen die de monteurs zelf ontwierpen, staan klaar in de code. Ze gaan live in maart."
    reopen: "De veldapp heeft een nieuwe versie gekregen, en er zitten weer negen verplichte velden in het afmeldscherm. De WhatsApp-groep is weer druk."
    beats:
      - {on: accepted, who: rachid, text: "Elke middag twee uur overtypen. Ik heb het Petra geleerd, en nu doe ik het zelf. Dat was niet de bedoeling."}
      - {on: completed, who: ricardo, text: "Ik heb ze in de groep gezegd: we proberen het. Een week. Als het werkt, mag de groep weer over taart gaan."}
    temptations:
      - id: whatsapp_official
        who: it_manager
        when: accepted
        text: "Als ze toch WhatsApp gebruiken, maken we het officieel. Een zakelijke groep per ploeg, en Meetdata leest mee. Morgen geregeld."
        accept: "Je maakt de WhatsApp-groepen het officiële kanaal voor afmeldingen."
        decline: "Je gaat uitzoeken waarom de monteurs de app niet gebruiken."
        accept_sets_flags: [flag:whatsapp_official]
        accept_effects: {complete_goal: false, reputation: 1}
    teaches: [gemba, customer_value, waste_overprocessing]
    rewards: {xp: 2800, budget: 20000, reputation: 5, trust: {monteurs: 1}}
    insights:
      go_see: "Heb je zelf een klus afgemeld, op de tablet, in een meterkast in een kelder?"
      understand: "Waarom gebruiken de monteurs WhatsApp? Wat doet die groep goed wat de app niet doet?"
      experiment: "Welk getal laat over twee weken zien of je experiment werkt? Wanneer kan een monteur je verbetering eigenlijk op zijn tablet zien?"
      reflect: "De verbetering die de monteurs zelf ontwierpen, stond klaar en kon nog niet live. Wat zegt dat over waar je nu moet kijken?"

problems:
  - id: field_app_bypassed
    tier: 3
    track: it
    name: De app die niemand gebruikt
    step: connections.close_out
    waste: overprocessing
    severity: high
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Meetdata & registratie typt elke dag papieren werkbonnen en WhatsApp-foto's over in het systeem.
      - Volgens de cijfers van IT gebruikt negen op de tien monteurs de veldapp.
    root_cause: De veldapp is gebouwd zonder dat iemand met een monteur meeliep. Afmelden kost veertien schermen, de app werkt niet zonder bereik, in kelders en op het platteland, en een foto meesturen kan niet. Monteurs openen de app om de klus te starten, en melden af op papier of in hun eigen WhatsApp-groep. Het werk wordt op kantoor overgetypt.
    plausible_causes:
      - Monteurs zijn nu eenmaal geen computermensen.
      - De tablets zijn te oud.
      - De monteurs hebben een training nodig.
    mismatch_note: Een training of nieuwe tablets helpen niet zolang de app niet doet wat de monteur op dat moment nodig heeft. De monteurs hebben hun eigen app al gebouwd, in WhatsApp.
    countermeasures: {close_out_redesign_with_monteurs: 1.0, offline_mode: 0.8, monteur_in_every_review: 0.7, paper_form_scanning: 0.6, whatsapp_official: 0.4}
    teaches: [gemba, customer_value]
    effects:
      # estimate: every close-out retyped from paper or a photo: ~40% more touch time at close_out, and ~1 in 10 retyped wrong
      - {target: connections.close_out, property: touch_time, value: 1.4}
      - {target: connections.close_out, property: ftr, value: -0.1}
    clues:
      - {tool: data, key: true, depth: 0, text: "Volgens IT opent negen op de tien monteurs de veldapp elke dag. Van de afmeldingen komt een op de vijf via de app binnen."}
      - {tool: shadow, key: true, depth: 1, at: connections.execution, text: "In een kelder in De Kade start de monteur de klus in de app. Bij het afmelden heeft hij geen bereik. Hij maakt een foto van zijn papieren formulier en zet die in de WhatsApp-groep."}
      - {tool: time_study, key: true, depth: 1, text: "Een klus afmelden in de veldapp kost veertien schermen en negen verplichte velden, gemiddeld elf minuten. Op papier: twee minuten."}
      - {tool: conversation, key: false, depth: 0, text: "'Monteurs zijn nu eenmaal geen computermensen. Ze moeten gewoon een training.'"}
      - {tool: documents, key: true, depth: 2, at: it_features.refine, text: "In de backlog van de veldapp staan 212 wensen. Geen enkele is door een monteur ingediend. De laatste keer dat iemand van het team met een monteur meereed, was bij de start van het project in 2021."}
      - {tool: conversation, key: true, depth: 2, text: "'Die WhatsApp-groep heb ik gemaakt omdat de app het niet deed. Hij werkt altijd. Ook in een kelder: dan verstuurt hij hem later.'"}

countermeasures:
  - id: close_out_redesign_with_monteurs
    name: Een afmeldscherm, ontworpen met monteurs
    tier: 3
    category: quality
    description: Drie monteurs en het team van de veldapp ontwerpen samen het afmelden opnieuw, in de bus en in een kelder. Vier schermen, een foto erbij, en het werkt zonder bereik. Het vraagt een wijziging in de code van de app.
    budget: 20000
    team_hours: {app_team: 60, monteurs: 20}
    decay_days: null
    release_gated: true       # its effect starts at the next release of it_features (the chapter's twist)
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.close_out, property: touch_time, value: 0.85}
  - id: offline_mode
    name: Afmelden zonder bereik
    tier: 2
    category: quality
    description: De app bewaart een afmelding als er geen bereik is, en verstuurt hem later vanzelf, zoals WhatsApp.
    budget: 10000
    team_hours: {app_team: 40}
    decay_days: null
    release_gated: true
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: monteur_in_every_review
    name: Een monteur bij elke sprint review
    tier: 1
    category: people
    description: Bij elke sprint review zit een monteur, die de nieuwe schermen op zijn eigen tablet probeert. Er is geen code voor nodig; het verandert wat er gebouwd wordt.
    budget: 1000
    team_hours: {monteurs: 10, app_team: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: paper_form_scanning
    name: Een vast papieren formulier dat wordt gescand
    tier: 1
    category: standard_work
    description: Eén vast papieren afmeldformulier, dat op kantoor wordt gescand en automatisch uitgelezen. Het overtypen wordt minder; de app blijft ongebruikt.
    budget: 4000
    team_hours: {meter_office: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: whatsapp_official
    name: WhatsApp als officieel kanaal
    tier: 1
    category: flow
    description: Zakelijke WhatsApp-groepen per ploeg worden het officiële afmeldkanaal, en Meetdata leest mee. Snel, en met klantgegevens in een chatapp.
    budget: 500
    team_hours: {meter_office: 5}
    decay_days: 365
    aftermath:                 # estimate: customer addresses and meter photos in a chat app; a privacy complaint within months
      after_days: 90
      days: 1
      reputation: -5
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**How `release_gated` plays.** The Check of a `release_gated` countermeasure does not fail. It reads "Staat klaar. Gaat live bij de volgende release, over {days} dagen" and scores as `too_early`. The player may:
- **wait**: the mission stays open and blocks the main slot for months. Allowed, and it hurts on purpose.
- **re-A3 with a countermeasure that works now**: `monteur_in_every_review` or `paper_form_scanning`.

The second is a poor fix (fit 0.3 or more below the best), so `poor_fix:field_app_bypassed` is set. After `fix_release_twice_a_year`, the repair quest `repair_field_app_bypassed` opens. Its countermeasure `close_out_redesign_with_monteurs` *ships* this time, because releases are frequent. The repair reopens what the release cadence had locked: the catalogue's path-dependence rule, inside IT. The main debrief's `{release_line}` is "En de afmeldschermen die Ricardo en zijn collega's ontwierpen? Die staan klaar. Voor de release van maart."

**Dialogs.**

```yaml
dialogs:
  - id: noor_field_app
    person: noor
    kind: persuade
    mission: fix_field_app_bypassed
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "De veldapp? Negentig procent gebruik. Ik heb het dashboard hier. Ik weet niet wat je nog meer wilt."
    position: {text: "De app doet wat in de requirements stond. Als monteurs hem niet gebruiken, hebben ze een training nodig.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Iedereen wil iets van de app. Planning, Meetdata, Veiligheid, de auditor. Elke afdeling een verplicht veld. Ik moet kiezen. Wat het hardst geroepen wordt, komt bovenaan.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "Eerlijk gezegd…", tags: [hesitation]}
        text: "Ik heb nog nooit een dag met een monteur meegereden. Niet één. Ik ben product owner van een app voor tweehonderd monteurs, en ik ken ze uit Jira. Als ik nu meerijd en het blijkt dat ik het al die tijd verkeerd zag… dan heb ik vier jaar de verkeerde dingen gebouwd."
        tags: [admission]
        unlocks: {facts: [heard:noor_ride_along], proposals: [ride_with_ricardo]}
    reframe: "Vanuit Ricardo in een kelder zonder bereik? Die heeft elf minuten en veertien schermen, en zijn volgende klus wacht. … Nee. Dan zou ik ook WhatsApp pakken."
    warning: "Ik heb zo een refinement."
    data: ["field_app_bypassed:0", "field_app_bypassed:2"]
    lines:
      show_data:
        lands: "Een op de vijf afmeldingen via de app. Terwijl negen op de tien hem opent. Dus ze openen hem… en melden ergens anders af."
        misses: "Dat dashboard zegt iets anders."
    proposals:
      - {id: training, addresses: [], label: "Een training voor de monteurs", say: "Een training voor alle monteurs in het gebruik van de app.", reply: "Dat had ik al op de roadmap. Goed."}
      - {id: fewer_mandatory_fields, addresses: [interest], label: "Minder verplichte velden", say: "Haal de verplichte velden terug naar wat de monteur echt weet als hij afmeldt.", reply: "Dan krijg ik vier afdelingen op mijn dak. Maar ja. Negen is te veel."}
      - {id: ride_with_ricardo, hidden: true, addresses: [concern], label: "Een dag meerijden met Ricardo", say: "Wat als je één dag met Ricardo meerijdt? Niet om te zien wat je fout deed. Om te zien wat hij nodig heeft, in de kelder.", reply: "Eén dag. Met Ricardo. … Ja. Liever nu dan over nog vier jaar."}
    experiments:
      - {id: five_monteurs_one_week, addresses: [concern], label: "Vijf monteurs, één week, op de tablet", say: "Vijf monteurs proberen een week een nieuw afmeldscherm, op papier getekend, en vertellen jou elke dag wat er misging.", reply: "Op papier getekend. Dan bouw ik niks voor niks. Dat kan ik."}
    co_proposal: {id: ride_with_ricardo, text: "Laat mij een dag meerijden. En neem de developers ook mee, die hebben ook nog nooit een meterkast gezien."}
    outcomes:
      commitment: "Afgesproken. Donderdag rij ik mee. En ik zet de app weer op 'in progress'. Hij is niet af."
      partial: "Ik wil het wel. Als het niet ten koste gaat van de Energiewet-wijzigingen."
      heard: "Fijn dat je het vroeg. Echt."
      compliance: "Prima. Ik maak er een ticket van."
      ruined: "Dus de app is slecht. Zet het maar in de backlog."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose ride_with_ricardo +8 87 > ask: commitment (7 moves)

  - id: ricardo_whatsapp
    person: ricardo
    kind: persuade
    mission: fix_field_app_bypassed
    owns: field_app_bypassed
    patience: 10
    # start: cynic 30 + 10 x team trust monteurs (often +1 by now) + 0 + 0 = 30-40
    opening: "Kom je mijn WhatsApp afpakken? Die heb ik zelf gemaakt. Hij werkt."
    position: {text: "De groep werkt. De app niet. Laat ons nou gewoon.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, inquiry, paraphrase], text: "In de groep zet je een foto, klaar. In de app tik je elf minuten, en in een kelder lukt het niet eens. Ik heb vijf klussen per dag.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "En die groep…", tags: [hesitation]}
        text: "…is meer dan afmelden. Daar zie je wie er ziek is, wie een baby heeft gekregen, wie hulp nodig heeft bij een rare kast. Als jullie die groep weghalen en ons weer in een app duwen die niet werkt, pakken jullie de ploeg af. Niet alleen een kanaal."
        tags: [admission]
        unlocks: {facts: [heard:ricardo_group], proposals: [design_it_yourselves]}
    reframe: "Vanuit Rachid? Die typt elke middag twee uur mijn foto's over. Hm. Daar had ik nooit bij stilgestaan."
    warning: "Ik moet naar mijn volgende klus."
    data: ["field_app_bypassed:2"]
    lines:
      show_data:
        lands: "Elf minuten, ja. Dat heb ik ze al drie keer gezegd. Nu staat het tenminste ergens."
        misses: "Cijfers. Kom maar eens in een kelder staan."
    proposals:
      - {id: make_app_work, addresses: [interest], label: "De app laten werken zonder bereik", say: "We zorgen dat de app werkt zonder bereik, en dat je een foto kunt meesturen.", reply: "Dat vragen we al vier jaar."}
      - {id: design_it_yourselves, hidden: true, addresses: [concern], label: "Monteurs ontwerpen het afmelden zelf; de groep blijft", say: "Wat als jij en twee collega's het afmelden zelf ontwerpen, met het team van de app? En de groep blijft gewoon bestaan, voor alles wat geen afmelding is.", reply: "De groep blijft. En wij ontwerpen het. Dan is het onze app. Dan wil ik wel."}
    experiments:
      - {id: one_week_in_the_van, addresses: [concern], label: "Het team rijdt een week mee", say: "Laat het team van de app een week met jullie meerijden, voordat ze iets bouwen.", reply: "Een week in de bus. Dan zien ze het zelf. Neem wel een jas mee."}
    co_proposal: {id: design_it_yourselves, text: "Laat ons het scherm op papier tekenen. Vier vakjes en een foto. Meer heb je niet nodig."}
    outcomes:
      commitment: "Afgesproken. En als het werkt, zeg ik het zelf in de groep. Dan gaat de groep weer over taart."
      partial: "Ik doe mee. Als de groep blijft."
      heard: "Hm. Je vroeg wat de groep is. Dat deed niemand van IT."
      compliance: "Prima. Ik gebruik de app. Als hij het doet."
      ruined: "Zie je. Weer een app van kantoor."
    # route (start 30): mood +8 38 > open question +6 44 > paraphrase +7 51 (heard, interest) > empathy +6 57 > show_data +15 (cynic) 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose design_it_yourselves +8 87 > ask: commitment (8 moves)
```

**Path dependence.**
- **Act I and II echoes:**
  - `chose:installer_not_ready:installer_photo_upload` (Act I): the photo exists as a process but not in the app, so the briefing's first wish is that photo.
  - `chose:revision_backlog:revision_at_source` (Act II): the as-built sketch is captured in the field app too. With the app bypassed, the revision backlog quietly regrows (a beat from Mieke: "Er komen weer schetsen binnen op papier.").
- **`committed:ricardo_whatsapp` with `design_it_yourselves`** is read by `fix_manual_regression` (Ricardo's edge cases join Hanneke's: "de kelder zonder bereik") and by the engagement loop's D39.
- **`flag:whatsapp_official`:** quick and visible. Customer addresses and meter photos then live in a chat app, and a privacy complaint follows (the aftermath). It also locks `offline_mode` until cleared: the WhatsApp channel must be retired first (`needs: {none: [flag:whatsapp_official]}`, cleared by `chose:field_app_bypassed:close_out_redesign_with_monteurs`).

**Grounding.**
- Going to the gemba in software (Lean UX; Poppendieck 2006). Users' workarounds as the best requirements: the Lean principle of respect for the people doing the work.
- Customer data in consumer chat apps falls under the AVG/GDPR; the Autoriteit Persoonsgegevens has warned employers about WhatsApp for work data *(verify the page before quoting)*.
- 14 screens, 11 minutes, one in five, 212 wishes and 2021: estimates and fiction sized for the puzzle.

**Engrossing.**
- The workaround is the hero: a monteur built what IT did not.
- The respect question is real: the WhatsApp group is also the team's social glue, and taking it away would be taking more than a channel.
- The twist (the fix ships in March) makes the player *want* the release mission.

### 2.3 `fix_release_twice_a_year` — Twee releases per jaar (M)

Principles tested: **long_term** (small batches are safer) and **respect** (fear has a history; honour it). Temptation: release more often by skipping the regression tests.

```yaml
missions:
  - id: fix_release_twice_a_year
    name: Twee releases per jaar
    kind: main
    tier: 3
    act: 6
    chapter: Kleiner uitbrengen
    track: it
    requires: {missions: [fix_field_app_bypassed]}   # four-tier audit A1: was fix_status_page_wrong, a requirement cycle after the portal moved to tier 4
    goal: {type: solve, problem: release_twice_a_year}
    principles: [long_term, respect]
    briefing: "De veldapp en het werkorderplatform erachter gaan twee keer per jaar live: in maart en in september. Elke release is een weekend van twintig mensen, drie weken testen vooraf en een change advisory board die alles afzonderlijk goedkeurt. Erwin de Groot, release manager, zit de CAB voor. 'Na 2023 doen we het zo. En sindsdien gaat het goed.'"
    debrief: "De veldapp gaat nu {cadence} live, in kleine stukjes. De afmeldschermen die Ricardo en zijn collega's ontwierpen, staan sinds {release_date} op elke tablet. En de storingen na een release? {incidents_line} Erwin: 'Minder grote weekenden. Ik had niet gedacht dat ik dat zou missen. Ik mis het niet.'"
    reopen: "De releases worden weer groter. Er is een 'freeze' ingesteld voor de Energiewet-wijzigingen, en die is nooit opgeheven."
    beats:
      - {on: accepted, who: erwin, text: "Je wilt vaker releasen. Iedereen wil vaker releasen, tot het een keer misgaat. Ik was erbij, in 2023."}
      - {on: completed, who: ricardo, text: "De nieuwe afmelding staat erop. Vier schermen. Ik heb het in de groep gezet, met een duim."}
    temptations:
      - id: skip_regression
        who: it_manager
        when: accepted
        text: "Simpel: elke maand releasen, en de regressietest overslaan voor kleine wijzigingen. Dat scheelt drie weken per keer."
        accept: "Je laat de regressietest vervallen voor kleine wijzigingen."
        decline: "Je maakt de releases kleiner zonder op het testen te bezuinigen."
        accept_sets_flags: [flag:skipped_tests]
        accept_effects: {complete_goal: false}
    teaches: [batching, ci_cd, small_batches]
    rewards: {xp: 3000, budget: 25000, reputation: 5}
    insights:
      go_see: "Wat gebeurt er in het weekend van een release? Ben je erbij geweest?"
      understand: "Waarom zijn de releases zo groot? Wat was er eerst: de grote release, of de angst?"
      experiment: "Als je kleiner uitbrengt, wat verwacht je dan van het aantal storingen na een release? Welk getal laat dat zien?"
      reflect: "Waar wacht de wijziging nu het langst? Was dat er al, of zag je het pas toen de release kleiner werd?"

problems:
  - id: release_twice_a_year
    tier: 3
    track: it
    name: Twee releases per jaar
    step: it_features.release
    waste: waiting
    severity: high
    visibility: obvious
    kpi: lead_time
    symptoms:
      - De veldapp en het werkorderplatform gaan twee keer per jaar live.
      - Een wijziging die af is, wacht gemiddeld drie maanden op de volgende release.
    root_cause: Na een mislukte release in 2023 werd elke wijziging gebundeld in twee grote releases per jaar, met drie weken handmatig testen en een CAB die alles afzonderlijk goedkeurt. Grote releases zijn riskanter, dus de angst bleef en het testen werd langer. Een kleine, veilige stap is nooit geprobeerd.
    plausible_causes:
      - De ontwikkelaars werken te langzaam.
      - Een netbeheerder kan zich geen risico permitteren; twee keer per jaar is gewoon verstandig.
      - De ACM eist zorgvuldige releases.
    mismatch_note: Sneller bouwen helpt niet als wat af is drie maanden op de plank ligt. En grote releases zijn niet veiliger; ze voelen alleen zo.
    countermeasures: {ci_cd_pipeline: 1.0, monthly_release_train: 0.8, feature_toggles: 0.7, skip_regression_small: 0.4}
    teaches: [batching, ci_cd]
    effects:
      - {target: it_features.release, property: batch_days, value: 182}
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de wijzigingen die vorig jaar live gingen, lag de gemiddelde wijziging 94 dagen af en klaar voordat hij live ging."}
      - {tool: documents, key: true, depth: 1, text: "Het releaseprotocol van september 2023: 'Na het incident van 14 juli worden wijzigingen gebundeld in twee releases per jaar.'"}
      - {tool: conversation, key: false, depth: 0, text: "'De ACM kijkt mee. Wij kunnen geen risico nemen.'"}
      - {tool: time_study, key: true, depth: 1, at: it_features.test, text: "De regressietest voor een release duurt drie weken, met de hand. Hoe groter de release, hoe langer."}
      - {tool: data, key: true, depth: 2, at: it_incidents.report, text: "Na de laatste vier grote releases kwamen er in de eerste week gemiddeld elf storingen binnen. Bijna allemaal in wijzigingen die niets met elkaar te maken hadden, maar wel samen live gingen."}
      - {tool: conversation, key: true, depth: 2, text: "'In juli 2023 ging er een release mis. Twee dagen lang konden de monteurs geen werkbonnen openen. Driehonderd klussen vielen uit. Sindsdien willen we het allemaal heel goed doen. Dus doen we het weinig.'"}

countermeasures:
  - id: ci_cd_pipeline
    name: Een pijplijn met automatische controles
    tier: 3
    category: flow
    description: Elke wijziging gaat door een vaste pijplijn met automatische tests en controles, en kan los live. De CAB keurt de pijplijn goed, niet elke wijziging; grote risico's krijgen een eigen beoordeling.
    budget: 40000
    team_hours: {app_team: 60, ops: 40}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.release, property: batch_days, value: 7}
  - id: monthly_release_train
    name: Elke maand een release
    tier: 2
    category: flow
    description: Elke vier weken een vaste release, met een kleinere regressietest en een vaste CAB-dag.
    budget: 8000
    team_hours: {ops: 20, testers: 20}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.release, property: batch_days, value: 28}
  - id: feature_toggles
    name: Uitbrengen en pas later aanzetten
    tier: 3
    category: flow
    description: Wijzigingen gaan uit, maar staan uit, tot het bedrijf ze aanzet. Uitbrengen en aanzetten worden twee verschillende stappen.
    budget: 12000
    team_hours: {app_team: 30}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.release, property: batch_days, value: 60}
  - id: skip_regression_small
    name: Kleine wijzigingen zonder regressietest
    tier: 1
    category: flow
    description: Kleine wijzigingen gaan maandelijks live zonder de regressietest.
    budget: 500
    team_hours: {ops: 5}
    decay_days: 365
    aftermath:
      after_days: 30
      days: 999
      effects:
        - {target: it_incidents, property: demand, value: 1.5}   # estimate: untested changes break things in production
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.release, property: batch_days, value: 28}
```

**Dialog: `erwin_cab`.**

```yaml
dialogs:
  - id: erwin_cab
    person: erwin
    kind: persuade
    mission: fix_release_twice_a_year
    owns: release_twice_a_year
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Kom erin. Op dat bord staat de release van maart. Honderdzestig wijzigingen. Wil je weten hoeveel daarvan iemand nog snapt?"
    position: {text: "Twee releases per jaar, goed getest, goed bewaakt. Dat is zorgvuldig.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "Elke release is een weekend. Twintig mensen, pizza, en ik die om vier uur 's nachts beslist of we teruggaan. Twee keer per jaar is al genoeg.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "In juli 2023…", tags: [hesitation]}
        text: "…zat ik bij de directie. Twee dagen lang konden de monteurs geen werkbonnen openen. Driehonderd klussen vielen uit, klanten hadden voor niets vrij genomen, en het stond in de krant. Ik had die release goedgekeurd. Sindsdien keur ik niets meer goed wat ik niet zelf heb gezien."
        tags: [admission]
        unlocks: {facts: [heard:erwin_2023], proposals: [erwin_designs_the_checks]}
    reframe: "Vanuit de monteur die al vier jaar om een fotoknop vraagt, en hoort dat die in maart komt? … Ja. Die heeft ook een slecht weekend. Elk weekend."
    warning: "Ik heb een CAB om twee uur."
    data: ["release_twice_a_year:0", "release_twice_a_year:4"]
    lines:
      show_data:
        lands: "Elf storingen in de week na een grote release. In wijzigingen die niets met elkaar te maken hadden. Hm. Dat… dat is de bundel zelf."
        misses: "Cijfers. In 2023 hadden we ook cijfers."
    proposals:
      - {id: monthly, addresses: [interest], label: "Elke maand een release", say: "Elke maand een release, kleiner.", reply: "Twaalf weekenden in plaats van twee?"}
      - {id: erwin_designs_the_checks, hidden: true, addresses: [concern], label: "Erwin ontwerpt de automatische controles", say: "Wat als jij de controles ontwerpt die elke wijziging automatisch moet doorstaan? Alles wat jij in 2023 had willen zien, zit erin. Dan keur je de controles goed, één keer, en zie je elke wijziging toch.", reply: "Mijn controles. Elke keer, automatisch. Dan zie ik meer dan nu. Nu zie ik honderdzestig wijzigingen in één keer en begrijp ik er tien."}
    experiments:
      - {id: one_team_weekly, addresses: [concern], label: "Eén team, één kwartaal, wekelijks", say: "Eén team, de veldapp, mag een kwartaal elke week kleine wijzigingen uitbrengen. Jij volgt elke release en mag het stoppen.", reply: "Eén team. En ik mag stoppen. Dat is netjes."}
    co_proposal: {id: erwin_designs_the_checks, text: "Laat mij die controles opschrijven. Ik weet precies wat er in 2023 mis had kunnen worden gevangen."}
    outcomes:
      commitment: "Afgesproken. En de pizza blijft. Op vrijdag. Zonder release."
      partial: "Ik wil het proberen. Als de CAB blijft meekijken."
      heard: "Je bent de eerste die vraagt wat er in 2023 gebeurde, in plaats van te zeggen dat ik te voorzichtig ben."
      compliance: "Als de directie het wil. Het staat in het verslag dat ik het afraadde."
      ruined: "Dus ik ben de rem. Prima. Dan rem ik."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose erwin_designs_the_checks +8 89 > ask: commitment (8 moves)
```

**Path dependence.**
- `flag:skipped_tests` (or `skip_regression_small`): incidents rise a month later. `fix_ops_dev_wall` (side) opens with a heavier problem.
- After `ci_cd_pipeline` or `monthly_release_train`, `close_out_redesign_with_monteurs` ships, and the field app's repair quest opens if it was patched (§2.2).
- The test step becomes the constraint: the fork (§2.4).

**Grounding.**
- *Accelerate* (Forsgren, Humble & Kim, 2018): external change approval is negatively correlated with throughput and not correlated with stability; lightweight change approval and smaller batches go with both higher throughput and higher stability. Deployment frequency and lead time for changes are two of the four key metrics.
- Small batches reduce risk: Reinertsen, *The Principles of Product Development Flow* (2009).
- The 2023 incident, 160 changes, 94 days and eleven incidents: fiction and estimates.

**Engrossing.** A release manager whose caution is a scar, and a proposal that turns his scar into the safety net. The data puzzle: the incidents come *from* the bundling.

### 2.4 The fork `it_after_release`: `fix_test_env_queue` (B) and `fix_code_review_wait` (N)

After smaller releases, work waits in two places. The test environments, two shared by the train's teams, are the constraint. The code reviews wait two days, which is annoying but not the constraint. The non-bottleneck debrief names the lead-time gain (L1).

```yaml
missions:
  - id: fix_test_env_queue
    name: Wachten op de testomgeving
    kind: main
    tier: 3
    act: 6
    chapter: Kleiner uitbrengen
    track: it
    requires: {missions: [fix_release_twice_a_year]}
    fork: {group: it_after_release, role: bottleneck}
    goal: {type: solve, problem: test_env_queue}
    principles: [improve, long_term]
    briefing: "Er zijn twee testomgevingen voor de veldapp en het werkorderplatform. Op het planbord staan ze voor zes weken vol. Teams wachten, of testen 'even snel' tussen de boekingen door. Ops wil een derde omgeving. Een ontwikkelaar zegt dat de reviews het probleem zijn: 'Mijn code wacht twee dagen op een review.'"
    debrief: "Er gaan nu {throughput_after} wijzigingen per week door, was {throughput_before}. Een testomgeving staat er in tien minuten, met nepdata, en is weg als hij niet meer nodig is. Ops bouwt geen omgevingen meer met de hand. Waar wacht het werk nu?"
    debrief_first: "Nu zie je het verschil met de reviews: dit keer gaan er wél meer wijzigingen per week door. Waarom hier wel en daar niet?"
    beats:
      - {on: accepted, who: priya, text: "Een omgeving bouwen kost me drie dagen. Productiedata kopiëren, maskeren, controleren. En dan boekt iemand hem voor zes weken 'voor de zekerheid'."}
    temptations:
      - id: buy_third_env
        who: it_manager
        when: accepted
        text: "Koop gewoon een derde omgeving. Vierduizend euro per maand, en de wachtrij is weg."
        accept: "Je laat een derde testomgeving inrichten."
        decline: "Je kijkt eerst wat de twee omgevingen nu doen."
        accept_sets_flags: [flag:third_env]
        accept_effects: {cost_per_week: 900}
    teaches: [theory_of_constraints, bottleneck_focus, infrastructure_as_code]
    rewards: {xp: 3000, budget: 25000, reputation: 5}
    insights:
      go_see: "Twee plekken waar wijzigingen wachten. Waar wacht het meeste werk, in dagen? Heb je het zelf geteld?"
      understand: "Wat doet een testomgeving op een dag dat hij geboekt is? Hoeveel uur wordt er echt getest?"
      experiment: "Als je deze omgevingen beter benut, hoeveel wijzigingen per week verwacht je? Voordat je er een bij koopt?"
      reflect: "Femke zei het in de netstudie: eerst beter benutten, dan pas groter maken. Gold dat hier ook?"

  - id: fix_code_review_wait
    name: Wachten op een review
    kind: main
    tier: 3
    act: 6
    chapter: Kleiner uitbrengen
    track: it
    requires: {missions: [fix_release_twice_a_year]}
    fork: {group: it_after_release, role: non_bottleneck}
    goal: {type: solve, problem: code_review_wait}
    principles: [respect, improve]
    briefing: "Ontwikkelaar Mark van Leeuwen wacht gemiddeld twee dagen op een review van zijn code. 'Het is altijd hetzelfde: iedereen is druk met zijn eigen werk, en een review is werk van een ander.' Op de testomgevingen wordt ook gewacht, zegt hij, maar daar kan hij niets aan doen."
    debrief: "Code wacht nu {review_hours} uur op een review in plaats van twee dagen. Een wijziging is gemiddeld {lead_delta} dagen eerder klaar. Maar kijk naar de stroom: er gaan niet méér wijzigingen per week live. Het werk wacht nog steeds bij {constraint_place}."
    debrief_first: "Goed dat dit ook vlotter gaat: minder wachten, en het team leert van elkaars code. Het knelpunt zat al ergens anders."
    teaches: [bottleneck_focus, lead_time, pair_programming]
    rewards: {xp: 2600, budget: 15000, reputation: 5}
    insights:
      go_see: "Twee plekken waar wijzigingen wachten. Waar staat het werk het langst stil?"
      understand: "Waarom blijft een review liggen? Wat is er voor de reviewer belangrijker?"
      experiment: "Welk getal verwacht je dat verandert: de wachttijd voor een review, het aantal wijzigingen per week, of allebei?"
      reflect: "Gaan er nu meer wijzigingen per week live? Wat is er wél beter geworden, en voor wie?"

problems:
  - id: test_env_queue
    tier: 3
    track: it
    name: Wachten op de testomgeving
    step: it_features.test
    waste: waiting
    severity: high
    visibility: subtle
    kpi: throughput
    symptoms:
      - Het planbord van de twee testomgevingen staat zes weken vol.
      - Teams testen 'even snel' tussen boekingen door, of wachten.
    root_cause: Een testomgeving wordt met de hand gebouwd, met een kopie van productiedata die drie dagen maskeren kost. Omdat opnieuw bouwen zo lang duurt, boeken teams een omgeving voor weken 'voor de zekerheid', en staat hij het grootste deel van de tijd stil.
    plausible_causes:
      - Er zijn gewoon te weinig testomgevingen.
      - De reviews houden alles op.
      - De testers zijn te langzaam.
    mismatch_note: Een derde omgeving die net zo gebouwd en net zo geboekt wordt, staat over een maand ook vol. De omgevingen zijn schaars omdat ze traag gemaakt en lang vastgehouden worden.
    countermeasures: {environments_on_demand: 1.0, synthetic_test_data: 0.8, third_environment: 0.7, booking_board: 0.6}
    teaches: [theory_of_constraints, infrastructure_as_code]
    effects:
      # estimate: hand-built environments are down or being refreshed ~30% of the time
      - {target: test_envs, property: availability, value: -0.3}
    clues:
      - {tool: queue_count, key: true, depth: 0, text: "Bij de test wachten 23 wijzigingen, ruim drie weken werk. Bij de review wachten er zes."}
      - {tool: shadow, key: true, depth: 1, text: "Testomgeving 2 is voor vier weken geboekt door het team van de veldapp. Vandaag wordt er een uur op getest."}
      - {tool: time_study, key: true, depth: 1, text: "Een testomgeving opnieuw bouwen kost drie werkdagen, waarvan twee voor het kopiëren en maskeren van productiedata."}
      - {tool: conversation, key: false, depth: 0, text: "'De reviews houden alles op. Mijn code wacht twee dagen.'"}
      - {tool: conversation, key: true, depth: 2, text: "'We boeken voor weken, want als we hem teruggeven, duurt het drie dagen voor we er weer een hebben.'"}

  - id: code_review_wait
    tier: 3
    track: it
    name: Wachten op een review
    step: it_features.review
    waste: waiting
    severity: low
    visibility: obvious
    kpi: lead_time
    symptoms:
      - Code wacht gemiddeld twee dagen op een review.
    root_cause: Reviews zijn niemands werk. Iedereen doet ze tussen zijn eigen taken door, als die af zijn.
    plausible_causes:
      - Er zijn te weinig senior ontwikkelaars.
    mismatch_note: Meer seniors reviewen sneller, maar zolang een review 'werk van een ander' is, blijft hij liggen.
    countermeasures: {pairing_on_hard_parts: 1.0, review_rota: 0.7}
    teaches: [bottleneck_focus]
    effects:
      - {target: it_features.review, property: wait_time, value: 2.0}
    clues:
      - {tool: data, key: true, depth: 0, text: "Code wacht gemiddeld twee dagen op een review. Een review zelf duurt twintig minuten."}
      - {tool: shadow, key: true, depth: 1, text: "Een ontwikkelaar heeft drie reviewverzoeken open staan en werkt eerst zijn eigen ticket af."}
      - {tool: conversation, key: true, depth: 1, text: "'Een review is werk van een ander. Mijn eigen werk staat op het bord met mijn naam erop.'"}

countermeasures:
  - id: environments_on_demand
    name: Omgevingen op afroep
    tier: 3
    category: flow
    description: Een testomgeving wordt automatisch gebouwd uit code, in tien minuten, en verdwijnt als hij niet meer nodig is. Niemand hoeft meer te boeken.
    budget: 30000
    team_hours: {ops: 60}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: test_envs, property: headcount, value: 3}
  - id: synthetic_test_data
    name: Nepdata in plaats van productiedata
    tier: 2
    category: quality
    description: Testomgevingen krijgen een vaste set nepdata met alle lastige gevallen, in plaats van een gemaskeerde kopie van productie. Sneller, en er kan geen klantdata lekken.
    budget: 10000
    team_hours: {ops: 20, testers: 20}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: test_envs, property: availability, value: 0.2}
  - id: third_environment
    name: Een derde testomgeving
    tier: 2
    category: flow
    description: Een derde omgeving, op dezelfde manier gebouwd en geboekt.
    budget: 5000
    team_hours: {ops: 15}
    decay_days: null
    cost_per_week: 900   # estimate: ~EUR 4,000 a month for licences and hosting
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: test_envs, property: headcount, value: 1}
  - id: booking_board
    name: Een boekingsbord met maximaal een week
    tier: 1
    category: visual_management
    description: De omgevingen staan op een bord; niemand boekt langer dan een week, en wat niet gebruikt wordt, wordt teruggegeven.
    budget: 500
    team_hours: {ops: 5}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: pairing_on_hard_parts
    name: Samen programmeren op de lastige stukken
    tier: 2
    category: quality
    description: Lastige wijzigingen worden met z'n tweeën gemaakt; de review zit er dan al in. Eenvoudige wijzigingen krijgen een review dezelfde dag, door wie als eerste klaar is.
    budget: 2000
    team_hours: {app_team: 20}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: review_rota
    name: Een reviewrooster
    tier: 1
    category: standard_work
    description: Elke dag heeft één ontwikkelaar reviewdienst.
    budget: 500
    team_hours: {app_team: 5}
    decay_days: 60
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**Dialogs.**

```yaml
dialogs:
  - id: priya_envs
    person: priya
    kind: persuade
    mission: fix_test_env_queue
    owns: test_env_queue
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Als je een omgeving komt vragen: de volgende is vrij op 3 december."
    position: {text: "We hebben gewoon een derde omgeving nodig.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question, paraphrase], text: "Ik bouw ze met de hand. Drie dagen per keer: productiedata kopiëren, maskeren, controleren of er geen echte namen in zitten. Dan geeft iemand hem na een uur terug en begin ik opnieuw.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En weet je waar ik wakker van lig…", tags: [hesitation]}
        text: "Als ik het automatiseer en er glipt één keer echte klantdata door het maskeren, met adres en verbruik, in een omgeving waar dertig mensen bij kunnen… Dan is dat een datalek. Dat is niet een storing. Dat is de Autoriteit Persoonsgegevens."
        tags: [admission]
        unlocks: {facts: [heard:priya_privacy], proposals: [fake_data_first]}
    reframe: "Vanuit het team dat wacht? Die zien een omgeving die vier weken geboekt is en er een uur per dag op testen. Ja. Ik zou ook boos zijn."
    warning: "Ik moet zo een omgeving terugzetten."
    data: ["test_env_queue:1", "test_env_queue:2"]
    proposals:
      - {id: build_from_code, addresses: [interest], label: "Omgevingen uit code", say: "Wat als een omgeving automatisch uit code wordt gebouwd, in tien minuten?", reply: "Met welke data?"}
      - {id: fake_data_first, hidden: true, addresses: [concern], label: "Eerst nepdata, dan pas automatisch", say: "Wat als we eerst een vaste set nepdata maken, met alle lastige gevallen, en die automatisch meebouwen? Dan zit er nooit meer echte klantdata in een testomgeving.", reply: "Nooit meer echte data. Dan hoef ik niet meer te maskeren. Dan lig ik niet meer wakker."}
    experiments:
      - {id: fake_data_one_team, addresses: [concern], label: "Eén team een maand met nepdata", say: "Eén team test een maand alleen met nepdata, en Lisette kijkt mee.", reply: "Een maand, met de privacy-officer erbij. Dan weten we het zeker."}
    co_proposal: {id: fake_data_first, text: "Laat Hanneke de lastige gevallen opschrijven. Die kent ze allemaal. Dan maak ik er nepdata van."}
    outcomes:
      commitment: "Afgesproken. En die derde omgeving hebben we dan niet meer nodig. Ik zeg het zelf tegen de IT-manager."
      partial: "Ik wil het. Als de privacy-officer meekijkt."
      heard: "Fijn dat je vroeg waarom het drie dagen duurt."
      compliance: "Goed. Ik automatiseer het. Op jouw verantwoording."
      ruined: "Dus ik ben te langzaam. Bouw ze dan zelf."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman) 65 > capped 64 (interest) > reflect +10 74 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose fake_data_first +8 89 > ask: commitment (7 moves)

  - id: mark_pairing
    person: mark
    kind: persuade
    mission: fix_code_review_wait
    owns: code_review_wait
    patience: 9
    # start: defender 40 + 0 + 0 + 0 + 0 = 40
    opening: "Pairen? Als je dat komt verkopen: twee mensen voor één klus."
    position: {text: "Review zo snel mogelijk, prima. Maar ik ga niet de hele dag naast iemand zitten.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Ik werk het best als het stil is. Koptelefoon op. Dan zie ik de hele code in mijn hoofd.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "Het is gewoon…", tags: [hesitation]}
        text: "Een hele dag praten is voor mij als een hele dag in de wachtrij. Ik ben 's avonds op. Bij mijn vorige werkgever moest alles in pairs, en na een halfjaar zat ik thuis."
        tags: [admission]
        unlocks: {facts: [heard:mark_quiet], proposals: [pair_only_hard_parts]}
    reframe: "Vanuit de collega die twee dagen op mijn review wacht? Die zit ook met een koptelefoon op, te wachten. Hm."
    proposals:
      - {id: pair_all_day, addresses: [interest], label: "Altijd in tweetallen", say: "Iedereen werkt voortaan in tweetallen.", reply: "Nee. Echt niet."}
      - {id: pair_only_hard_parts, hidden: true, addresses: [concern], label: "Alleen de lastige stukken samen", say: "Wat als je alleen de lastige stukken samen doet, een uur of twee, en de rest gewoon met je koptelefoon? De review zit er dan al in.", reply: "Een uur of twee. Op de lastige stukken. Daar wil ik eigenlijk toch al iemand bij."}
    experiments:
      - {id: same_day_review, addresses: [concern], label: "Review dezelfde dag, wie eerst klaar is", say: "Wie als eerste klaar is met zijn taak, doet de openstaande review. Dezelfde dag. Geen rooster, geen gepraat.", reply: "Dat kan ik. Twintig minuten, stil. Prima."}
    co_proposal: {id: pair_only_hard_parts, text: "Op de lastige stukken wil ik wel. Daar maak ik anders toch fouten die iemand anders twee dagen later vindt."}
    outcomes:
      commitment: "Afgesproken. Twee uur per dag, max. En daarna gaat de koptelefoon op."
      partial: "Ik probeer het. Als niemand me de hele dag naast zich zet."
      heard: "Fijn dat je vroeg hoe ik werk."
      compliance: "Prima. Ik pair. Tot ik weer thuis zit."
      ruined: "Dus ik moet socialer worden. Dank je."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > reflect +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose pair_only_hard_parts +8 87 > ask: commitment (7 moves)
    # Respect: a practice is not good if it breaks the person doing it. Pairing where it adds value, not as a rule.
```

**Path dependence.**
- `flag:third_env` (elevate before exploit) works for a few weeks. The third environment fills up the same way: the booking problem moves with it. A `poor_fix` follows when it is chosen as the countermeasure (fit 0.3 below the best).
- `committed:priya_envs` with `synthetic_test_data` is read by `fix_meter_data_mandates` (tier 4, §2.8): the privacy officer starts one band higher ("Er zit geen echte data meer in test. Dat had ik nooit gedacht.").
- `fork_first:it_after_release:*` gives D4 / D5.

**Grounding.**
- Infrastructure as code and on-demand environments: Humble & Farley, *Continuous Delivery* (2010).
- Test data and privacy (production data in test environments is personal data under the AVG/GDPR): Autoriteit Persoonsgegevens guidance *(verify the page before quoting)*.
- The fork's lesson: Goldratt (TOC), and audit L1.
- 23, six, three days and four weeks: estimates.

### 2.5 `fix_manual_regression` — Drie weken handmatig testen (M)

Principles tested: **respect** (the tester's knowledge becomes the suite) and **long_term**. Temptation: an offshore test factory. The shifted bottleneck after the fork.

```yaml
missions:
  - id: fix_manual_regression
    name: Drie weken handmatig testen
    kind: main
    tier: 3
    act: 6
    chapter: Kleiner uitbrengen
    track: it
    requires: {any_of: [fix_test_env_queue, fix_code_review_wait]}
    goal: {type: solve, problem: manual_regression}
    principles: [respect, long_term]
    briefing: "De omgevingen zijn er nu. Maar elke release vraagt nog steeds een regressietest van drie weken, met de hand, door drie testers. Hanneke Willems test al twintig jaar bij Voltana. 'Automatiseren? Prima. Als de computer weet wat ik weet.'"
    debrief: "De regressietest duurt nu {test_hours} uur in plaats van drie weken, en hij draait bij elke wijziging. De lastige gevallen die Hanneke in haar hoofd had, staan nu als eerste in de testset. Hanneke test nu wat nog niemand heeft bedacht. 'Ik doe eindelijk weer waar ik goed in ben.'"
    reopen: "De geautomatiseerde tests worden bij nieuwe wijzigingen niet meer bijgewerkt. Er staan er veertig 'tijdelijk uit'."
    temptations:
      - id: test_factory
        who: it_manager
        when: accepted
        text: "Een testfabriek in het buitenland doet de regressietest in een week, voor de helft van de prijs. Dan kunnen onze testers ander werk doen."
        accept: "Je besteedt de regressietest uit aan een testfabriek."
        decline: "Je laat de testers hun kennis in de automatische tests zetten."
        accept_sets_flags: [flag:test_factory]
        accept_effects: {trust: {testers: -2}}
    teaches: [test_automation, jidoka, respect_for_people]
    rewards: {xp: 3200, budget: 25000, reputation: 5}
    insights:
      go_see: "Wat doet een tester in die drie weken? Wat ziet zij dat een script niet ziet?"
      understand: "Welke tests vinden echt fouten, en welke bevestigen alleen wat al werkte?"
      experiment: "Wat automatiseer je eerst, en waarom dat? Wat verwacht je te zien bij de volgende release?"
      reflect: "Wiens kennis zit er nu in de testset? Weet ze dat?"

problems:
  - id: manual_regression
    tier: 3
    track: it
    name: Drie weken handmatig testen
    step: it_features.test
    waste: overprocessing
    severity: high
    visibility: obvious
    kpi: throughput
    symptoms:
      - Elke release vraagt een regressietest van drie weken, met de hand.
      - Na de omgevingen is de test opnieuw de plek waar wijzigingen het langst wachten.
    root_cause: Elke release wordt met de hand helemaal opnieuw getest, met een draaiboek van zeshonderd stappen. Het grootste deel controleert wat al jaren werkt; de lastige gevallen die echt fouten vinden, zitten in het hoofd van één ervaren tester en staan nergens.
    plausible_causes:
      - De testers werken te langzaam.
      - Software van een netbeheerder is te complex om te automatiseren.
    mismatch_note: Sneller met de hand testen of alles blind automatiseren lost het niet op. Het draaiboek test vooral wat al werkt, en de kennis van wat vaak misgaat, staat er niet in.
    countermeasures: {test_automation_pyramid: 1.0, edge_cases_first: 0.8, testers_in_teams: 0.7, offshore_test_factory: 0.6}
    teaches: [test_automation, jidoka]
    effects:
      - {target: it_features.test, property: touch_time, value: 3.0}
    clues:
      - {tool: time_study, key: true, depth: 0, text: "De regressietest heeft een draaiboek van zeshonderd stappen. Drie testers doen er drie weken over."}
      - {tool: data, key: true, depth: 1, text: "Van de fouten die de regressietest vorig jaar vond, kwam negen op de tien uit veertig van de zeshonderd stappen. De rest vond niets."}
      - {tool: conversation, key: true, depth: 2, text: "'De klant met twee aansluitingen op één adres. De boerderij met een windmolentje. De flat waar de meters in de kelder hangen. Die staan niet in het draaiboek. Die staan in mijn hoofd.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Onze software is te ingewikkeld om te automatiseren. Dat hebben we in 2018 al geprobeerd.'"}

countermeasures:
  - id: test_automation_pyramid
    name: Automatische tests, van klein naar groot
    tier: 3
    category: quality
    description: Veel kleine automatische tests op de code, minder op de koppelingen, een paar op de hele app. Ze draaien bij elke wijziging. De testers schrijven de lastige gevallen als eerste.
    budget: 35000
    team_hours: {testers: 60, app_team: 40}
    decay_days: 180
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.test, property: touch_time, value: 0.4}
  - id: edge_cases_first
    name: Eerst de veertig stappen die fouten vinden
    tier: 2
    category: quality
    description: De veertig stappen die de meeste fouten vonden, plus Hannekes lastige gevallen, worden als eerste geautomatiseerd. De rest van het draaiboek wordt opgeschoond.
    budget: 12000
    team_hours: {testers: 40}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: testers_in_teams
    name: Testers in de teams, vanaf het begin
    tier: 2
    category: people
    description: Elke tester zit in een ontwikkelteam en denkt mee vanaf het moment dat een wijziging wordt besproken.
    budget: 2000
    team_hours: {testers: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.build, property: ftr, value: 0.03}
  - id: offshore_test_factory
    name: Een testfabriek in het buitenland
    tier: 1
    category: people
    description: Een externe testfabriek voert het draaiboek uit, in een week. De lastige gevallen kent zij niet.
    budget: 3000
    team_hours: {testers: 10}
    decay_days: 365
    trust: {testers: -2}
    aftermath: {after_days: 60, days: 999, effects: [{target: it_incidents, property: demand, value: 1.2}]}   # estimate: the edge cases are missed
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []

dialogs:
  - id: hanneke_edge_cases
    person: hanneke
    kind: persuade
    mission: fix_manual_regression
    owns: manual_regression
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40
    opening: "Twintig jaar. Ik heb vier apps zien komen en drie zien gaan. Ga zitten."
    position: {text: "Automatiseren is prima. Als de computer weet wat ik weet.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [inquiry, open_question, paraphrase], text: "Het draaiboek test wat al jaren werkt. De fouten zitten in de rare gevallen: twee aansluitingen op één adres, een boerderij met een windmolentje, een flat met de meters in de kelder.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En als jullie alleen…", tags: [hesitation]}
        text: "Als jullie alleen de makkelijke gevallen automatiseren, want dat gaat snel, dan zegt de computer 'groen' en gaat het mis bij de boer met de windmolen. Dan heb ik twintig jaar opgelet voor niets. En dan zegt iemand: 'De tests waren groen. Hoe kan dat nou?'"
        tags: [admission]
        unlocks: {facts: [heard:hanneke_cases], proposals: [hanneke_writes_first]}
    reframe: "Vanuit de klant met de windmolen? Die merkt niet of ik drie weken heb getest. Die merkt of zijn teruglevering klopt. Ja."
    warning: "Ik zit midden in stap 412."
    data: ["manual_regression:0", "manual_regression:1"]
    proposals:
      - {id: automate_the_script, addresses: [interest], label: "Het draaiboek automatiseren", say: "We automatiseren het draaiboek, stap voor stap.", reply: "Zeshonderd stappen, waarvan er vijfhonderdzestig niks vinden. Die automatiseer je dan heel efficiënt."}
      - {id: hanneke_writes_first, hidden: true, addresses: [concern], label: "Hannekes lastige gevallen eerst", say: "Wat als jij als eerste de lastige gevallen opschrijft, en die worden als eerste geautomatiseerd? Dan staat jouw kennis in de testset, niet alleen in jouw hoofd.", reply: "Mijn gevallen eerst. Dan zegt de computer pas 'groen' als de boer met de windmolen ook klopt. Ja. Dan wil ik."}
    experiments:
      - {id: pair_ten_cases, addresses: [concern], label: "Tien lastige gevallen, samen met een ontwikkelaar", say: "Jij en een ontwikkelaar automatiseren deze maand samen tien van jouw lastigste gevallen.", reply: "Tien. De boer met de windmolen als eerste. Dan zie ik of het werkt."}
    co_proposal: {id: hanneke_writes_first, text: "Geef me twee weken. Dan schrijf ik ze allemaal op. Ook de rare. Vooral de rare."}
    outcomes:
      commitment: "Afgesproken. En als het draait, ga ik eindelijk testen wat nog niemand heeft bedacht."
      partial: "Ik wil het wel. Als mijn gevallen erin komen."
      heard: "Je bent de eerste die vraagt wát ik test, in plaats van hoe lang."
      compliance: "Prima. Automatiseer het maar. Ik zal er niet bij zijn als het misgaat. O nee, wacht. Toch wel."
      ruined: "Dus ik ben duur en langzaam. Zet dat maar in het verslag."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman) 65 > capped 64 (interest) > reflect +10 74 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose hanneke_writes_first +8 89 > ask: commitment (7 moves)
```

**Grounding.**
- The test automation pyramid: Cohn, *Succeeding with Agile* (2009).
- Built-in quality and stopping at the defect (jidoka in software): Poppendieck (2006); SAFe "Built-in Quality".
- 600 steps, three weeks and "nine in ten from forty": estimates sized for the puzzle; the content test must make the briefing's numbers true on the IT stream.
- The edge cases are the content's own: Lindeveld's farms with turbines, the silent meters in basement flats (Act II's `silent_meter`). Hanneke's knowledge *is* the game's history.

### 2.6 `fix_pi_overcommit` — PI-planning als toneelstuk (M)

Principles tested: **long_term** (predictability over promises) and **respect** (a plan people can keep). Temptation: plan at 100 % plus "stretch", and push overtime.

```yaml
missions:
  - id: fix_pi_overcommit
    name: PI-planning als toneelstuk
    kind: main
    tier: 3
    act: 6
    chapter: De trein
    track: it
    requires: {missions: [fix_manual_regression]}
    goal: {type: solve, problem: pi_overcommit}
    principles: [long_term, respect]
    briefing: "De veldapp, het werkorderplatform en vier andere teams, waaronder het klantportaal en het meetdataplatform, vormen sinds vorig jaar één release train: 'Veld & Klant', zestig mensen. Elke tien weken plannen ze twee dagen samen. Bas Kuipers, de release train engineer: 'Elke keer belooft iedereen alles. Na tien weken is de helft af, en niemand is verbaasd.' Carla Wijnands, directeur Klant & Markt, wil dat alle Energiewet-wijzigingen er dit kwartaal in zitten."
    debrief: "Het team belooft nu wat het kan waarmaken, en zegt eerlijk wat het misschien niet haalt. Van wat beloofd werd, is {predictability}% af, was {predictability_before}%. Carla: 'Ik krijg minder beloofd, en meer geleverd. Dat had ik eerder willen weten.'"
    reopen: "Bij de laatste PI-planning werd weer 'alles' beloofd. Er kwam een nieuwe directeur die het niet anders kende."
    beats:
      - {on: accepted, who: bas, text: "Kom naar de volgende PI-planning. Twee dagen. Neem een stoel achterin en kijk wie er 'ja' zegt."}
    temptations:
      - id: stretch_and_overtime
        who: carla
        when: accepted
        text: "Plan alles in, en zet er een 'stretch' bij. Als het team een paar avonden doorwerkt, halen we het."
        accept: "Je laat alles inplannen, met stretch en overwerk."
        decline: "Je laat het team plannen op wat het kan, en eerlijk zeggen wat onzeker is."
        accept_sets_flags: [flag:pi_stretch]
        accept_effects: {reputation: 2}
    teaches: [pi_planning, wip, art]
    rewards: {xp: 3400, budget: 25000, reputation: 5}
    insights:
      go_see: "Wie zegt er 'ja' bij de PI-planning, en wie zegt niets?"
      understand: "Hoeveel werk past er in tien weken? Hoeveel werd er beloofd? Wat gebeurt er met het verschil?"
      experiment: "Als het team minder belooft, wat verwacht je dan dat er geleverd wordt? Meer of minder?"
      reflect: "Wat is meer waard voor Carla: een belofte van honderd procent, of een voorspelling die klopt?"

problems:
  - id: pi_overcommit
    tier: 3
    track: it
    name: PI-planning als toneelstuk
    step: it_features.refine
    waste: overproduction
    severity: high
    visibility: subtle
    kpi: on_time
    symptoms:
      - Bij elke PI-planning wordt anderhalf keer zoveel werk beloofd als er past.
      - Na tien weken is ongeveer de helft van wat beloofd werd af.
    root_cause: De PI-planning begint bij wat het bedrijf wil, niet bij wat de teams kunnen. Alles wordt toegezegd, dus alles wordt tegelijk begonnen; teams springen tussen taken en maken weinig af. Niemand maakt onderscheid tussen wat zeker moet en wat mooi zou zijn.
    plausible_causes:
      - De teams schatten slecht.
      - De Energiewet-wijzigingen zijn gewoon te veel.
    mismatch_note: Beter schatten helpt niet als het plan begint bij de wensen in plaats van bij de capaciteit, en alles tegelijk begint.
    countermeasures: {capacity_based_pi: 1.0, committed_and_uncommitted: 0.8, stretch_overtime: 0.5}
    teaches: [pi_planning, wip]
    effects:
      # estimate: planned work at 150% of capacity; context switching adds ~15% to build time
      - {target: it_features, property: demand, value: 1.3}
      - {target: it_features.build, property: touch_time, value: 1.15}
    clues:
      - {tool: data, key: true, depth: 0, text: "Van de doelen die bij de laatste drie PI-planningen werden toegezegd, was na tien weken 48, 52 en 45 procent af."}
      - {tool: shadow, key: true, depth: 1, at: it_features.refine, text: "Op de tweede dag van de PI-planning schuift de directeur drie extra doelen naar het team van de veldapp. Niemand zegt nee. Het team schrijft ze erbij."}
      - {tool: queue_count, key: true, depth: 1, at: it_features.build, text: "Het team van de veldapp heeft veertien wijzigingen tegelijk onder handen, met zes mensen."}
      - {tool: conversation, key: false, depth: 0, text: "'De teams schatten gewoon slecht. Alles duurt twee keer zo lang.'"}
      - {tool: conversation, key: true, depth: 2, text: "'Als ik nee zeg tegen de directeur, ben ik niet loyaal. Als ik ja zeg en het niet haal, ben ik niet goed genoeg. Dus zeg ik ja.'"}

countermeasures:
  - id: capacity_based_pi
    name: Plannen op wat het team kan
    tier: 2
    category: flow
    description: De PI-planning begint bij de capaciteit van elk team, min een vaste ruimte voor storingen en onderhoud. Er gaat pas iets nieuws in als er iets af is (een limiet op wat tegelijk onder handen is).
    budget: 5000
    team_hours: {app_team: 10, platform_team: 10}
    decay_days: 120
    sustains: true     # the PI rhythm is itself a leader routine
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features, property: wip_limit, value: 12}
  - id: committed_and_uncommitted
    name: Toegezegd en niet toegezegd
    tier: 3
    category: visual_management
    description: Elk team zegt per doel of het toegezegd is (dat halen we) of niet toegezegd (dat proberen we). De directeur ziet vooraf wat zeker is en wat niet.
    budget: 2000
    team_hours: {app_team: 5, platform_team: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_features.build, property: touch_time, value: 0.95}
  - id: stretch_overtime
    name: Stretch en overwerk
    tier: 1
    category: people
    description: Alles wordt ingepland, met een 'stretch'. Het team werkt over waar nodig.
    budget: 0
    team_hours: {}
    decay_days: 60
    trust: {app_team: -1, platform_team: -1}
    aftermath: {after_days: 42, days: 70, effects: [{target: app_team, property: availability, value: -0.1}]}   # estimate: fatigue and sick leave
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []

dialogs:
  - id: carla_must_haves
    person: carla
    kind: persuade
    mission: fix_pi_overcommit
    patience: 8
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Ik heb twintig minuten. Als het over de PI gaat: alles wat op de lijst staat, moet erin. De Energiewet wacht niet."
    position: {text: "Alle Energiewet-wijzigingen moeten dit kwartaal live. Dat heb ik toegezegd.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "De ACM kijkt mee, de leveranciers wachten op onze nieuwe datasets, en de raad van bestuur vraagt elk kwartaal of we compliant zijn.", tags: [claim]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En ik zal eerlijk zijn…", tags: [hesitation]}
        text: "Ik heb de raad van bestuur beloofd dat alles erin zit. Als ik nu terug moet en zeggen dat de helft misschien niet lukt, sta ik er als directeur slecht op. Zes maanden in deze baan, en dan al terugkrabbelen."
        tags: [admission]
        unlocks: {facts: [heard:carla_promise], proposals: [certain_and_maybe]}
    reframe: "Vanuit het team? Die beloven elke keer alles en leveren de helft. En dan zegt iedereen dat ze slecht schatten. Hm. Dat is mijn belofte, doorgeschoven."
    warning: "Ik heb een bestuursvergadering. Kort, graag."
    data: ["pi_overcommit:0", "pi_overcommit:1"]
    lines:
      show_data:
        lands: "Achtenveertig, tweeënvijftig, vijfenveertig procent. Dus ik beloof de raad van bestuur elke keer iets wat voor de helft niet gebeurt."
        misses: "Dat zijn de cijfers van mijn voorganger."
    proposals:
      - {id: plan_on_capacity, addresses: [interest], label: "Plannen op capaciteit", say: "Laat de teams plannen op wat ze kunnen. Dan is de helft van de lijst er niet.", reply: "De helft. En de Energiewet?"}
      - {id: certain_and_maybe, hidden: true, addresses: [concern], label: "Zeker en misschien, vooraf", say: "Wat als de teams de Energiewet-wijzigingen als eerste toezeggen, en de rest eerlijk als 'proberen we'? Dan ga jij naar de raad van bestuur met wat zeker is, en kom je terug met meer dan je beloofde.", reply: "Zeker en misschien. Vooraf. Dan beloof ik minder en lever ik meer. Dat… is beter dan andersom."}
    experiments:
      - {id: one_pi_honest, addresses: [concern], label: "Eén PI eerlijk plannen", say: "Eén PI: de teams plannen op capaciteit, en jij krijgt na tien weken te zien wat er van de toezeggingen af is.", reply: "Eén PI. En als het tegenvalt, plannen we weer zoals altijd."}
    co_proposal: {id: certain_and_maybe, text: "Laat me de Energiewet-wijzigingen zelf rangschikken. Ik weet welke de ACM het eerst ziet."}
    outcomes:
      commitment: "Afgesproken. En ik vertel het de raad van bestuur zelf: zeker en misschien. Dat hebben ze nooit gehoord."
      partial: "Ik wil het proberen. Als de Energiewet-wijzigingen zeker zijn."
      heard: "Interessant. U bent de eerste die vraagt wat ik beloofd heb, in plaats van wat ik vraag."
      compliance: "Als het moet. Maar de Energiewet zit erin. Hoe dan ook."
      ruined: "De Energiewet is geen wens. Plan het in."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose certain_and_maybe +8 89 > ask: commitment (8 moves)
```

**Path dependence.**
- `flag:pi_stretch` pays now (reputation +2). Fatigue follows in weeks 6–16, and `t4`'s IT chapter (`fix_team_dependencies`) opens with lower `app_team` trust.
- `chose:pi_overcommit:capacity_based_pi` with `committed:carla_must_haves` is read by Act V's `t4_hoshin`: the IT train already plans by capacity, so the X-matrix has one honest row.

**Grounding.**
- An ART of 5–12 teams, about 50–125 people; a PI of 8–12 weeks; PI planning as a two-day event; committed and uncommitted objectives; predictability measured on business value (Scaled Agile Framework; Lucid and Appfire summaries; *verify against the current SAFe 6.0 pages*).
- The Energiewet in force since 1 January 2026 (tier-2 draft §4.2 grounding). The regulatory work packages named here are fiction.
- 48, 52 and 45 % and fourteen changes in progress: estimates.

**Engrossing.** A director who learns that a smaller promise kept is worth more than a big one broken, and who makes it her own message to the board. The team member's line (clue 4) is the human core: nobody can say no.

### 2.7 Side missions of the IT chapter

```yaml
missions:
  - id: fix_ops_dev_wall
    name: Over de muur gegooid
    kind: side
    tier: 3
    act: 6
    track: it
    requires: {missions: [it_map_feature_stream]}
    goal: {type: solve, problem: ops_dev_wall}
    principles: [respect, improve]
    briefing: "Als het werkorderplatform 's nachts hapert, belt Beheer. Beheer zegt dat het aan de code ligt, de ontwikkelaars zeggen dat het aan de servers ligt, en een storing gaat drie keer heen en weer voordat iemand hem oplost. Bart Jacobs van Beheer: 'Het is altijd hun schuld. Behalve als het de onze is.'"
    debrief: "Een storing gaat nu één keer de muur over, niet drie keer. Na elke grote storing praten Beheer en de ontwikkelaars samen, zonder schuldige te zoeken. Bart: 'Ik weet nu wie ik moet bellen. En hij neemt op.'"
    temptations:
      - id: find_the_culprit
        who: mt_member
        when: accepted
        text: "Zoek uit wie die storing van vorige week heeft veroorzaakt. Dan weten we het voor de volgende keer."
        accept: "Je laat uitzoeken wie de storing veroorzaakte."
        decline: "Je laat uitzoeken hoe de storing kon ontstaan, niet door wie."
        accept_sets_flags: [flag:blame_postmortem]
        accept_effects: {trust: {ops: -1, platform_team: -1}}
    teaches: [blameless_postmortem, devops, respect_for_people]
    rewards: {xp: 1200, budget: 10000, reputation: 2}

  - id: talk_rte
    name: Wat is een release train?
    kind: side
    tier: 3
    act: 6
    arc: sector
    track: it
    requires: {missions: [it_map_feature_stream]}
    goal: {type: talk_to, person: bas, topics: 3}
    principles: [improve]
    briefing: "Bas Kuipers is release train engineer: hij zorgt dat zestig mensen in zes teams in hetzelfde ritme werken. Vraag hem hoe dat werkt, en waarom het soms niet werkt."
    debrief: "Een trein rijdt op een dienstregeling, ook als niet iedereen instapt. Bas: 'Het lastigste is niet het plannen. Het is dat iedereen durft te zeggen wat er niet past.'"
    teaches: [art, pi_planning, dora_metrics]
    rewards: {xp: 600}

  - id: lsw_system_demo
    name: Systeemdemo
    kind: side
    tier: 3
    act: 6
    track: it
    requires: {missions: [fix_release_twice_a_year]}
    recurring: {every_days: 14}
    goal: {type: routine, kind: gemba_walk, places: [it_features.in_use], every_days: 14, times: 1}
    principles: [improve]
    briefing: "Elke twee weken laat de train zien wat er werkt. Niet in een presentatie, maar op de echte tablet. Ga kijken, en neem een monteur mee."
    debrief: "Je zag wat er deze twee weken live ging. {demo_line}"
    teaches: [pdca, customer_value]
    rewards: {xp: 300}

problems:
  - id: ops_dev_wall
    tier: 3
    track: it
    name: Over de muur gegooid
    step: it_incidents.fix
    waste: defects
    severity: medium
    visibility: subtle
    kpi: lead_time
    symptoms:
      - Een storing aan het werkorderplatform gaat gemiddeld drie keer heen en weer tussen Beheer en de ontwikkelaars.
    root_cause: Beheer en de ontwikkelaars werken in aparte teams met aparte doelen. Een storing wordt doorgezet met 'ligt aan jullie' in plaats van samen onderzocht, en na afloop wordt gezocht wie het deed, niet hoe het kon. Dus vertelt niemand meer dan nodig.
    plausible_causes:
      - De ontwikkelaars leveren slechte code.
      - Beheer begrijpt de applicatie niet.
    mismatch_note: Betere code of meer kennis bij Beheer verandert niets zolang een storing een pingpongbal is en elke nabespreking een schuldvraag.
    countermeasures: {blameless_postmortems: 1.0, shared_on_call: 0.8, you_build_it_you_run_it: 0.9}
    teaches: [blameless_postmortem, devops]
    effects:
      - {target: it_incidents.fix, property: ftr, value: -0.2}
    clues:
      - {tool: data, key: true, depth: 0, text: "Een storing aan het werkorderplatform wordt gemiddeld drie keer doorgezet voordat hij is opgelost."}
      - {tool: documents, key: true, depth: 1, text: "Elke nabespreking van een storing eindigt met de vraag: 'Wie heeft deze wijziging gedaan?'"}
      - {tool: conversation, key: true, depth: 2, text: "'Na de laatste nabespreking zei niemand meer iets. Je gaat toch niet vertellen dat je iets niet wist, als ze zoeken wie het was.'"}
      - {tool: conversation, key: false, depth: 0, text: "'Het ligt altijd aan de code.'"}

countermeasures:
  - id: blameless_postmortems
    name: Nabesprekingen zonder schuldvraag
    tier: 2
    category: people
    description: Na elke grote storing een nabespreking met Beheer en de ontwikkelaars samen. De vraag is hoe het kon gebeuren en wat het systeem kan veranderen, nooit wie het deed.
    budget: 2000
    team_hours: {ops: 10, platform_team: 10}
    decay_days: 120
    sustains: true
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: shared_on_call
    name: Samen piket
    tier: 2
    category: people
    description: "'s Nachts hebben een beheerder en een ontwikkelaar samen piket."
    budget: 6000
    team_hours: {ops: 10, platform_team: 10}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: you_build_it_you_run_it
    name: Wie het bouwt, beheert het
    tier: 3
    category: flow
    description: Het team van het werkorderplatform beheert zijn eigen platform in productie, met Beheer als ondersteuning voor de servers.
    budget: 15000
    team_hours: {platform_team: 30, ops: 20}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: it_incidents.fix, property: ftr, value: 0.05}

people:
  - id: bas
    name: Bas Kuipers
    role: release train engineer
    place: it_features.refine
    topics:
      - id: art
        ask: "Wat is een release train eigenlijk?"
        open: "Een groep teams die samen één stroom van waarde leveren, hier de veldapp, het werkorderplatform, het klantportaal en de meetdata. Zestig mensen, zes teams, één ritme. Elke tien weken plannen we samen, elke twee weken laten we zien wat er werkt. Een trein vertrekt op tijd, ook als niet iedereen is ingestapt. Wat niet af is, gaat met de volgende."
        closed: "Een paar teams die samenwerken."
        teaches: [art]
      - id: pi_planning
        ask: "Wat gebeurt er bij zo'n PI-planning?"
        open: "Twee dagen, iedereen in één ruimte. De directeur vertelt wat er belangrijk is, de teams plannen wat ze kunnen, en dan zie je de afhankelijkheden: wie op wie wacht. Het lastigste is niet het plannen. Het is dat iedereen durft te zeggen wat er niet past."
        closed: "We plannen het kwartaal."
        teaches: [pi_planning]
      - id: dora
        ask: "Hoe weet je of de trein goed rijdt?"
        open: "Vier getallen. Hoe vaak we iets uitbrengen, hoe lang een wijziging erover doet van code tot klant, hoe vaak een release iets kapotmaakt, en hoe snel we het dan herstellen. De eerste twee gaan over snelheid, de laatste twee over stabiliteit. Het mooie: teams die vaak en klein uitbrengen, scoren meestal op allebei beter."
        closed: "Aan de cijfers."
        teaches: [dora_metrics]
```

**Dialogs for the sides** (short; the same shape):

```yaml
dialogs:
  - id: bart_postmortem
    person: bart
    kind: persuade
    mission: fix_ops_dev_wall
    owns: ops_dev_wall
    patience: 10
    # start: cynic 30 (+10 team trust ops if no blame postmortem was ordered)
    opening: "Weer iemand die DevOps komt brengen. We hebben al een poster."
    position: {text: "Het ligt aan de code. Wij draaien wat zij bouwen.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, inquiry, paraphrase], text: "Om drie uur 's nachts sta ik met een storing die ik niet begrijp, in software die ik niet heb gebouwd. Ik bel de ontwikkelaar. Die neemt niet op.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "En na afloop…", tags: [hesitation]}
        text: "Na de storing van mei zat ik in een nabespreking waar de eerste vraag was: wie had dienst? Ik had dienst. Ik had het goed gedaan, maar ik had dienst. Sindsdien zeg ik in nabesprekingen niks meer. Niemand zegt nog iets."
        tags: [admission]
        unlocks: {facts: [heard:bart_may], proposals: [how_not_who]}
    reframe: "Vanuit de ontwikkelaar die om drie uur gebeld wordt? Die wordt wakker voor iets wat hij niet kan zien. Hm. Die staat ook alleen."
    data: ["ops_dev_wall:0", "ops_dev_wall:1"]
    proposals:
      - {id: shared_night, addresses: [interest], label: "Samen piket", say: "'s Nachts een beheerder en een ontwikkelaar samen op piket.", reply: "Samen. Dan neemt hij tenminste op."}
      - {id: how_not_who, hidden: true, addresses: [concern], label: "Nabesprekingen: hoe, niet wie", say: "Wat als in elke nabespreking één regel geldt: we vragen hoe het kon, nooit wie het was? En jij zit de eerste voor.", reply: "Ik zit voor. En de eerste die 'wie' zegt, haalt koffie. Ja. Dan ga ik weer praten."}
    experiments:
      - {id: may_again, addresses: [concern], label: "Mei opnieuw bespreken, zonder namen", say: "Zet de storing van mei nog één keer op het bord, en bespreek hem opnieuw. Zonder namen.", reply: "Mei opnieuw. Zonder namen. … Dan zeg ik wat ik toen niet durfde."}
    outcomes:
      commitment: "Afgesproken. En ik vertel in de eerste nabespreking zelf wat ik in mei niet wist."
      partial: "Ik doe mee. Als de MT ook stopt met 'wie'."
      heard: "Hm. Je vroeg naar mei. Dat deed niemand."
      compliance: "Prima. Weer een poster."
      ruined: "Zie je. Het ligt aan de code."
    # route: mood +8 38 > open question +6 44 > paraphrase +7 51 (heard, interest) > empathy +6 57 > show_data +15 (cynic x1.5) 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose how_not_who +8 87 > ask: commitment (8 moves)
```

**Path dependence (sides).**
- `flag:blame_postmortem` closes `you_build_it_you_run_it` until a blameless postmortem has been held once (`needs: {none: [flag:blame_postmortem]}` with `chose:ops_dev_wall:blameless_postmortems` clearing it).

**Grounding.**
- **Blameless postmortems:** Allspaw (2012), "Blameless PostMortems and a Just Culture"; Google SRE book (2016), ch. 15.
- **DORA's four keys** (deployment frequency, lead time for changes, change failure rate, time to restore; velocity and stability): DORA / *Accelerate*.
- **"You build it, you run it":** Vogels (2006), ACM Queue interview.

---

### 2.8 Moved to the tier-4 IT chapter: the customer portal and the meter-data platform (decided 2026-10-15)

Merijn's decision: the field app comes first in tier 3, as in the catalogue. The two customer-side missions drafted here move to the tier-4 IT chapter, unchanged in content except their gates (`tier: 4`, `requires: {missions: [fix_pi_overcommit]}`). The tier-4 draft places them in its chain.

**What changes with the move:**
- **The release twist moves to the field app** (§2.2). In tier 4, `forecast_from_planning` keeps its `release_gated` flag. It ships at once if the release cadence was fixed well, and waits if `fix_release_twice_a_year` ended in a poor fix. That is path dependence across tiers, through the same rule.
- **The meter-data platform meets a train** that already plans by capacity (if `fix_pi_overcommit` went well).

#### `fix_status_page_wrong` — De statuspagina liegt (M, tier-4 IT)

Principles tested: **respect** (for the customer reading the page) and **long_term**. The chapter's twist: the best countermeasure is `release_gated`.

```yaml
missions:
  - id: fix_status_page_wrong
    name: De statuspagina liegt
    kind: main
    tier: 4
    act: 6
    chapter: Het digitale loket
    track: it
    requires: {missions: [fix_pi_overcommit]}
    goal: {type: solve, problem: status_page_wrong}
    principles: [respect, long_term]
    briefing: "Bij het klantcontactcentrum komen weer meer statusvragen binnen. Esra: 'Ze bellen niet omdat ze niets horen. Ze bellen omdat het portaal iets zegt wat niet klopt.' Een klant las vorige week 'Fase 4: TV gereed' en dacht dat zijn televisie klaar was. Noor zegt dat de statuspagina sinds 2024 af is. Hij staat in de kolom 'done'."
    debrief: "Klanten lezen nu op het portaal wat er met hun aansluiting gebeurt, in gewone taal, op de dag dat het gebeurt. Er komen {calls_delta}% minder statusvragen binnen. Noor luisterde een middag mee bij Esra. 'Ik dacht dat ik onze klanten kende,' zei ze. 'Ik kende onze tickets.' {release_line}"
    debrief_variants:
      poor_fix: "De pagina spreekt nu gewone taal. Maar de datum is nog steeds de wettelijke termijn, geen voorspelling. De echte verwachte datum staat klaar in de code. Hij gaat live in maart."
    reopen: "Op het portaal staan weer interne fasenamen. Een nieuwe fase in het werkordersysteem kreeg geen vertaling."
    beats:
      - {on: accepted, who: el_amrani, text: "Ik kijk elke dag op uw portaal. Al drie weken staat er 'In behandeling'. Wat betekent dat?"}   # only if heard:el_amrani
      - {on: completed, who: noor, text: "Ik ga elke maand een middag meeluisteren. Dat zet ik in mijn agenda, niet in de backlog."}
    temptations:
      - id: faq_page
        who: noor
        when: accepted
        text: "Ik zet een FAQ onder de statuspagina: 'Wat betekenen de fasen?' Dat kan vandaag nog, zonder release."
        accept: "Je laat een FAQ onder de statuspagina zetten."
        decline: "Je laat de pagina zelf zeggen wat er gebeurt."
        accept_sets_flags: [flag:status_faq]
        accept_effects: {measure_bonus: {kpi: call_rate, value: -0.05}}
    teaches: [failure_demand, customer_value, gemba]
    rewards: {xp: 2800, budget: 20000, reputation: 5, trust: {contact_centre: 1}}
    insights:
      go_see: "Heb je zelf gelezen wat een klant op het portaal ziet, en gehoord wat hij daarna aan de telefoon vraagt?"
      understand: "Waar komt de tekst op de statuspagina vandaan? Wie heeft hem ooit voor een klant geschreven?"
      experiment: "Welk getal laat over twee weken zien of je experiment werkt? Wanneer kan een klant je verbetering eigenlijk zien?"
      reflect: "Je beste oplossing stond klaar en kon nog niet live. Wat zegt dat over waar je nu moet kijken?"

problems:
  - id: status_page_wrong
    tier: 4
    track: it
    name: De statuspagina liegt
    step: it_features.in_use
    waste: defects
    severity: high
    visibility: subtle
    kpi: on_time
    symptoms:
      - Het aantal statusvragen bij het klantcontactcentrum stijgt weer.
      - Klanten bellen met vragen over teksten op het portaal ('Wat is fase 4?').
    root_cause: De statuspagina leest de status uit een nachtelijke export van het werkordersysteem en toont de interne fasenamen. De 'verwachte datum' is de wettelijke termijn, geen voorspelling uit de planning. Het team dat de pagina bouwde, heeft nooit een klant gesproken of meegeluisterd; de pagina is 'af' omdat het ticket af is.
    plausible_causes:
      - Klanten lezen niet goed.
      - Het portaal is verouderd; er moet een nieuw portaal komen.
      - Het klantcontactcentrum legt het niet goed uit.
    mismatch_note: Een nieuw portaal met dezelfde teksten en dezelfde nachtelijke export vertelt de klant hetzelfde verkeerde verhaal, alleen mooier.
    countermeasures: {forecast_from_planning: 1.0, sms_on_planning_change: 0.8, plain_language_status: 0.7, new_portal: 0.5}
    teaches: [failure_demand, customer_value]
    effects:
      # estimate: confusing or stale status sends ~30% more status calls back to the contact centre
      - {target: connections, property: call_rate, value: 1.3}
    clues:
      - {tool: listen_in, key: true, depth: 0, at: customer_contact.answer, text: "'Op uw site staat Fase 4: TV gereed. Is mijn televisie nou klaar of niet?'"}
      - {tool: data, key: true, depth: 1, at: customer_contact.answer, text: "Een op de drie statusvragen begint met 'Op het portaal staat…'."}
      - {tool: documents, key: true, depth: 1, text: "De statuspagina toont de fasenamen uit het werkordersysteem. De 'verwachte datum' is de aanvraagdatum plus achttien weken."}
      - {tool: shadow, key: true, depth: 2, at: it_features.refine, text: "Het team bespreekt een nieuwe wijziging aan de statuspagina. Niemand in de kamer heeft ooit met een klant gesproken over die pagina."}
      - {tool: data, key: true, depth: 2, text: "De status op het portaal is gemiddeld één werkdag oud: hij komt uit een export die elke nacht om twee uur draait."}
      - {tool: conversation, key: false, depth: 0, text: "'Het portaal is uit 2019. Er moet gewoon een nieuw portaal komen.'"}

countermeasures:
  - id: forecast_from_planning
    name: Een echte verwachte datum, uit de planning
    tier: 3
    category: quality
    description: De statuspagina toont de datum uit de planning van Voltana, met een bandbreedte, en wordt bijgewerkt zodra de planning verandert. Het vraagt een wijziging in de code van het portaal.
    budget: 15000
    team_hours: {portal_team: 60, planners: 10}
    decay_days: null
    release_gated: true       # its effect starts at the next release of it_features (the chapter's twist)
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections, property: call_rate, value: 0.8}
  - id: sms_on_planning_change
    name: Een sms als de planning verandert
    tier: 2
    category: quality
    description: Via de bestaande sms-dienst krijgt de klant een bericht zodra zijn afspraak wordt gepland of verschoven, buiten het portaal om.
    budget: 5000
    team_hours: {planners: 10, ops: 10}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: plain_language_status
    name: Gewone taal op de statuspagina
    tier: 1
    category: standard_work
    description: Elke interne fase krijgt een zin in gewone taal, geschreven met het klantcontactcentrum, in het contentsysteem van het portaal. Er is geen release voor nodig.
    budget: 1500
    team_hours: {portal_team: 10, contact_centre: 5}
    decay_days: 90
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
  - id: new_portal
    name: Een nieuw klantportaal
    tier: 1
    category: flow
    description: Een leverancier bouwt in een jaar een nieuw portaal, op basis van de huidige gegevens.
    budget: 120000
    team_hours: {portal_team: 40}
    decay_days: 365
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects: []
```

**How `release_gated` plays.** The Check of a `release_gated` countermeasure does not fail. It reads "Staat klaar. Gaat live bij de volgende release, over {days} dagen" and scores as `too_early`. The player may:
- **wait**: the mission stays open and blocks the main slot for months. Allowed, and it hurts on purpose.
- **re-A3 with another countermeasure** (`sms_on_planning_change` or `plain_language_status`), which works now.

The second is a poor fix (fit 0.3 below the best), so `poor_fix:status_page_wrong` is set. After `fix_release_twice_a_year`, the repair quest `repair_status_page_wrong` opens. Its countermeasure `forecast_from_planning` *ships* this time, because releases are frequent. The repair reopens what the release cadence had locked: the catalogue's path-dependence rule, inside IT. The main debrief's `{release_line}` is "En de echte voorspelling? Die staat klaar. Voor de release van maart."

**Dialog: `noor_status`.**

```yaml
dialogs:
  - id: noor_status
    person: noor
    kind: persuade
    mission: fix_status_page_wrong
    owns: status_page_wrong
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "De statuspagina? Die is af. Hij staat in 'done' sinds 2024. Ik heb er driehonderd andere dingen in de backlog."
    position: {text: "De pagina doet wat in de requirements stond. Als klanten hem niet snappen, moet het KCC het uitleggen.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Iedereen wil iets van het portaal. Marketing, de ACM, Juridisch, het KCC. Ik moet kiezen. Wat het hardst geroepen wordt, komt bovenaan.", tags: [claim, feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "Eerlijk gezegd…", tags: [hesitation]}
        text: "Ik heb nog nooit met een klant gesproken. Niet één. Ik ben product owner van een portaal voor tweehonderdduizend klanten, en ik ken ze uit Jira. Als ik nu ga meeluisteren en het blijkt dat ik het al die tijd verkeerd zag… dan heb ik twee jaar de verkeerde dingen gebouwd."
        tags: [admission]
        unlocks: {facts: [heard:noor_customers], proposals: [listen_with_esra]}
    reframe: "Vanuit mevrouw El Amrani? Die ziet elke dag 'In behandeling' en weet niet wat het betekent. … Nee. Dat zou ik ook niet weten."
    warning: "Ik heb zo een refinement."
    data: ["status_page_wrong:0", "status_page_wrong:1"]
    proposals:
      - {id: rewrite_texts, addresses: [interest], label: "De teksten herschrijven", say: "Laat het KCC de fasenamen herschrijven in gewone taal.", reply: "Dat kan zonder release. Goed. Maar dat is een pleister."}
      - {id: listen_with_esra, hidden: true, addresses: [concern], label: "Een middag meeluisteren, samen met Esra", say: "Wat als je één middag naast Esra zit en meeluistert? Niet om te zien wat je fout deed. Om te horen wat ze nodig hebben.", reply: "Eén middag. Met Esra. … Ja. Liever nu dan over nog twee jaar."}
    experiments:
      - {id: five_customers, addresses: [concern], label: "Vijf klanten bellen", say: "Bel vijf klanten die vorige maand belden, en vraag wat ze op de pagina zagen.", reply: "Vijf. Dat is te overzien. En dan weet ik het tenminste."}
    co_proposal: {id: listen_with_esra, text: "Laat mij een middag bij Esra zitten. En neem de developers mee. Die hebben ook nog nooit een klant gehoord."}
    outcomes:
      commitment: "Afgesproken. Donderdag. En ik zet de pagina weer op 'in progress'. Hij is niet af."
      partial: "Ik wil het wel. Als het niet ten koste gaat van de Energiewet-wijzigingen."
      heard: "Fijn dat je het vroeg. Echt."
      compliance: "Prima. Ik maak er een ticket van."
      ruined: "Dus het portaal is slecht. Zet het maar in de backlog."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose listen_with_esra +8 87 > ask: commitment (7 moves)
```

**Path dependence.**
- `chose:status_callers:proactive_status_updates` (Act I): the proactive messages read the same status data. The listen-in clue then reads "'Ik kreeg een sms dat mijn monteur morgen komt. Er kwam niemand.'", and the briefing names it. Act I's durable fix exposes Act IV's software flaw.
- `flag:status_faq` lowers calls a little (the measure bonus) and sets nothing right. A FAQ explaining internal language is the documentation trap again (audit L10's videos for Henk).

**Grounding.**
- Failure demand caused by information (Seddon; audit M4).
- Customer status tracking with a request code: the national application portal mijnaansluiting.nl (Stedin brochure). Voltana's portal is fictional.
- The 18-week reference term (audit §2.3).
- Two hundred thousand customers and the nightly export at two o'clock: estimates and fiction.

**Engrossing.** A PO who admits she never met a customer: a common, human truth in IT. And the twist: the right fix is done and cannot reach the customer. The player *wants* the next mission.

#### `fix_meter_data_mandates` — Een mandaat dat niemand ziet (S, tier-4 IT)

```yaml
missions:
  - id: fix_meter_data_mandates
    name: Een mandaat dat niemand ziet
    kind: side
    tier: 4
    act: 6
    track: it
    requires: {missions: [fix_pi_overcommit]}
    goal: {type: solve, problem: meter_data_mandates}
    principles: [long_term, respect]
    briefing: "Klanten met een dynamisch energiecontract hebben hun verbruik per kwartier nodig. Hun leverancier vraagt die data bij Voltana op, met een mandaat van de klant. Eén medewerker controleert al die mandaten met de hand. De achterstand is drie weken, en de apps van de leveranciers tonen 'geen data'."
    debrief: "Een mandaat wordt nu automatisch gecontroleerd, met een logboek dat de privacy-officer zelf heeft ontworpen. De achterstand is weg. Lisette Koster: 'Ik kan nu elk mandaat terugvinden. Dat kon ik vroeger niet eens met de hand.'"
    temptations:
      - id: trust_big_suppliers
        who: it_manager
        when: accepted
        text: "Sla de mandaatcontrole over voor de vijf grote leveranciers. Die regelen dat toch netjes."
        accept: "Je laat de mandaatcontrole vervallen voor de grote leveranciers."
        decline: "Je laat elk mandaat controleren, maar sneller."
        accept_sets_flags: [flag:mandates_skipped]
        accept_effects: {complete_goal: true}
    teaches: [klantmandaat, quality_at_the_source, poka_yoke]
    rewards: {xp: 1200, budget: 10000, reputation: 2}


problems:
  - id: meter_data_mandates
    tier: 4
    track: it
    name: Een mandaat dat niemand ziet
    step: meter_data.mandate_check
    waste: overprocessing
    severity: medium
    visibility: obvious
    kpi: lead_time
    symptoms:
      - Aanvragen voor kwartierdata wachten drie weken op een mandaatcontrole.
      - Apps van leveranciers tonen 'geen data' bij klanten met een dynamisch contract.
    root_cause: Mandaten komen binnen in negen verschillende vormen, van pdf tot e-mail, en worden met de hand vergeleken met het klantregister. Er is geen standaardformaat met de leveranciers en geen automatische controle; één medewerker doet alles.
    plausible_causes:
      - De leveranciers vragen te veel data op.
      - De privacyregels zijn te streng.
    mismatch_note: "De regel is helder en terecht: zonder toestemming van de klant geen data. Wat traag is, is de manier waarop de toestemming wordt gecontroleerd."
    countermeasures: {automated_mandate_check: 1.0, standard_mandate_format: 0.8}
    teaches: [klantmandaat, poka_yoke]
    effects:
      - {target: meter_data.mandate_check, property: touch_time, value: 2.0}
    clues:
      - {tool: queue_count, key: true, depth: 0, text: "Er wachten 180 mandaten op controle; de oudste is drie weken oud."}
      - {tool: shadow, key: true, depth: 1, text: "De medewerker opent een pdf, zoekt de klant op in het register, vergelijkt naam, adres en EAN, en vinkt aan. Twaalf minuten per mandaat."}
      - {tool: documents, key: true, depth: 1, text: "Mandaten komen binnen in negen verschillende vormen. Er is geen afspraak met de leveranciers over één formaat."}
      - {tool: conversation, key: false, depth: 0, text: "'Die privacyregels maken alles traag. Vroeger kon het gewoon.'"}

countermeasures:
  - id: automated_mandate_check
    name: Automatisch mandaten controleren
    tier: 3
    category: quality
    description: Mandaten komen binnen in één standaardformaat en worden automatisch tegen het klantregister gecontroleerd, met een logboek per mandaat. Afwijkingen gaan naar de medewerker.
    budget: 20000
    team_hours: {data_team: 40, data_desk: 10}
    decay_days: null
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: meter_data.mandate_check, property: touch_time, value: 0.3}
  - id: standard_mandate_format
    name: Eén formaat voor mandaten
    tier: 2
    category: standard_work
    description: Voltana spreekt met de leveranciers één formaat voor mandaten af. De controle blijft met de hand, maar gaat veel sneller.
    budget: 4000
    team_hours: {data_desk: 10, key_accounts: 5}
    decay_days: 120
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: meter_data.mandate_check, property: touch_time, value: 0.7}

dialogs:
  - id: lisette_privacy
    person: lisette
    kind: persuade
    mission: fix_meter_data_mandates
    owns: meter_data_mandates
    patience: 10
    # start: rule_bound 35; +10 with committed:priya_envs and synthetic_test_data (team trust), as a memory of a privacy-respecting fix
    opening: "Als je komt vragen of het sneller kan zonder mandaat: nee."
    position: {text: "Geen kwartierdata zonder controle van het mandaat. Elk mandaat.", tags: [claim]}
    layers:
      - {id: interest, at: 52, via: [inquiry, open_question, paraphrase], text: "Kwartierdata vertelt wanneer iemand thuis is, wanneer hij slaapt, wanneer hij op vakantie is. Dat is geen meterstand. Dat is een dagboek.", tags: [claim, feeling]}
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En als het misgaat…", tags: [hesitation]}
        text: "Als er één keer data naar een leverancier gaat zonder geldig mandaat, ben ik degene die het moet melden bij de Autoriteit Persoonsgegevens. En als ze vragen hoe we controleren, moet ik zeggen: met de hand, door één persoon, in een Excel. Dat kan ik niet verdedigen. Dus houd ik het vast."
        tags: [admission]
        unlocks: {facts: [heard:lisette_log], proposals: [lisette_designs_the_log]}
    reframe: "Vanuit de klant met het dynamische contract? Die heeft toestemming gegeven, en ziet drie weken 'geen data'. Ja. Die wordt ook niet beschermd door mijn achterstand."
    data: ["meter_data_mandates:0", "meter_data_mandates:1"]
    proposals:
      - {id: one_format, addresses: [interest], label: "Eén formaat met de leveranciers", say: "Eén formaat voor alle mandaten, met de leveranciers afgesproken.", reply: "Dat helpt. Mits het formaat klopt."}
      - {id: lisette_designs_the_log, hidden: true, addresses: [concern], label: "Lisette ontwerpt de controle en het logboek", say: "Wat als jij de automatische controle ontwerpt, met een logboek per mandaat? Dan kun je de Autoriteit precies laten zien hoe we het doen. Beter dan nu.", reply: "Mijn controle, met een logboek. Dan kan ik het verdedigen. Beter dan nu. Veel beter."}
    experiments:
      - {id: double_check_month, addresses: [concern], label: "Een maand dubbel controleren", say: "Een maand lang wordt elk automatisch gecontroleerd mandaat ook met de hand nagelopen, tot je het vertrouwt.", reply: "Een maand dubbel. Daarna weet ik of ik het kan loslaten."}
    outcomes:
      commitment: "Afgesproken. En het logboek krijgt een knop: 'laat zien'. Voor als de Autoriteit belt."
      partial: "Ik wil het. Als ik de controle mag goedkeuren."
      heard: "Fijn dat je eerst vroeg waarom."
      compliance: "Prima. Op jouw naam."
      ruined: "Privacy is geen obstakel. Het is de wet."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose lisette_designs_the_log +8 89 > ask (8 moves)

```

**Path dependence and grounding for the meter-data mission** (moved with it):
- `flag:mandates_skipped` completes the mission at once. It never pays: 30 days later a supplier's app shows data for a customer without a mandate (a complaint to the Autoriteit Persoonsgegevens; reputation −10, as the tier-2 `fix_klic_expired` "dig anyway" pattern). It is cleared only by `automated_mandate_check`.
- `committed:priya_envs` with synthetic data starts Lisette higher.
- **Meter data only with an unambiguous customer mandate (*klantmandaat*):** grid operators may read consumption data only for their legal tasks and pass it to market parties only with the customer's explicit consent, through the P4 interface; quarter-hour values are stored a limited time (Kamerstuk 29023-202; supplier consent forms; the regulators' note on a central mandate register still to come: *verify its status*).
- 180 mandates, twelve minutes and nine formats: estimates.

---

## 3. Path dependence: what tier 3 reads, and what it leaves for tier 4

### 3.1 Earlier play read by tier 3

| Fact (set in) | Read by | What it changes |
|---|---|---|
| `chose:installer_not_ready:*` (Act I, fork N) | `t3_crew_strategy` | Opens "De uren van de lege ritten" (audit Q3). |
| `chose:planning_reshuffle:daytime_outage_crew` or `standardised:planning_reshuffle` (Act I side) | `t3_crew_strategy` | Opens "Een vaste storingsploeg overdag". |
| `chose:knowledge_drain:twi_job_instruction` / `skills_matrix_buddy`, `heard:ahmed_trainer` (Acts I, III) | `fix_training_capacity`, `t3_crew_strategy` | `train_the_trainer` 40 % cheaper; Ahmed named in the debrief; opens "Leermeester en leerling". |
| `standardised:custom_design` (Act I) | `t3_kaizen_week` | Nova covers Havenzij's standard cases during the week (`cover_the_week`). |
| `agreed:el_amrani_fourth_call:check_existing_connection` (Act I) | `fix_household_rush` | `heat_pump_check` at half the team hours. |
| `heard:el_amrani` (Act I) | `fix_priority_first_come` (tier 4: `fix_status_page_wrong`) | Her beats. |
| `chose:installer_not_ready:installer_photo_upload` (Act I) | `it_map_feature_stream`, `fix_field_app_bypassed` | The photo exists as a process but not in the app: the change the player follows. |
| `chose:revision_backlog:revision_at_source` (Act II) | `fix_field_app_bypassed` | The as-built sketch is meant to be captured in the app; with the app bypassed, Mieke's backlog quietly regrows (a beat). |
| `agreed:petra_batch:rachid_backup` (Act I) | `fix_field_app_bypassed` | Rachid is the one who retypes; the briefing and the beat name him. |
| `heard:marco_2012`, Marco's commitments, `marco_day_100` lifted (Act I) | `marco_crew`, `t3_kaizen_week` | Marco starts at 59 instead of 30; the consultant kaizen triggers "Dit is 2012". |
| `committed:frank_kpi_targets`; Joost's Act II outcome | `joost_wip` | `frank_at_the_board` exists; Joost starts at 68 (commitment) or 27 (compliance). |
| `done:fix_contractor_rework`, `repaired:contractor_rework`, `flag:contractor_burned` (Act III) | `one_dig_agreements` | The tier-2 link: available only with the contractors' trust. |
| `failed:acm_visit` (Act III) | `acm_pilot_time_bound` | Closed (the catalogue's door). |
| `flag:curtailment_letter` (Act III heatwave) | `aziz_coldchain` | He starts at 30 with a variant position. |
| `flag:vsm_bought` (this act) | Joke, Yusuf; `fix_long_drives` clue depth | Team trust −1 until the areas are walked. |

### 3.2 Tier 3 read by tier 4

| Fact (set here) | Read by (catalogue §3.7 and the tier-4 IT chapter) |
|---|---|
| `flag:crew_lindeveld`, `repaired:long_drives` | `t4_investment_plan`: "Meer monteurs in Lindeveld". |
| `chose:training_capacity:*`, `flag:freelance_crews` | `t4_investment_plan`: "Opleiden: 12 aankomend monteurs" (`none: [flag:freelance_crews]` unless `train_the_trainer`). |
| `chose:nitrogen_permit:parallel_ecology` / `aerius_template` | `t4_investment_plan`: "Standaardstations in serie" (a proposed extra `any` branch, Q6). |
| `flag:deep_cables` | More digging faults in Havenzij; the "Sensoren in het LS-net" forecast. |
| `flag:queue_jumped`, `flag:hidden_wip` | `nta8120_audit`: governance findings; reputation −10 each when found. |
| `flag:auto_upgrades` | "De koude straat" (audit §6.4), winter outages. |
| `flag:flex_forced`; `chose:priority_first_come:classify_at_intake` with `committed:jeroen_classes` | `fix_flex_market_unused`: customer response and trusted queue data. |
| `chose:pi_overcommit:capacity_based_pi` with `committed:carla_must_haves`; `flag:pi_stretch` | `t4_hoshin` (an honest IT row in the X-matrix); the tier-4 IT chapter's starting trust. |
| `flag:blame_postmortem`, `flag:whatsapp_official` | IT maturity; `fix_team_dependencies` starts with lower trust; the privacy aftermath. |
| `committed:ricardo_whatsapp`, `chose:field_app_bypassed:close_out_redesign_with_monteurs` | Tier 4's field data (the asset data meets an app the monteurs use). |

### 3.3 Repair quests in tier 3

Every countermeasure marked as a poor fix (fit ≥ 0.2 below the best, or with `trust < 0` or an `aftermath` while a better one was offered: tier-2 draft §6) sets `poor_fix:<problem>`. The catalogue's template then opens a repair quest 42 days later, once the gap shows in the KPI. Authored overrides:
- `repair_long_drives` (§1.12, worked in full): reopens the Lindeveld crew and the investment option.
- `repair_field_app_bypassed` (§2.2): reopens `close_out_redesign_with_monteurs`, which now ships because releases are frequent.

The template's text covers the rest:
- Act IV: `mobile_van_stock`, `outsource_area`, `freelance_monteurs`, `deep_bypass`, `peak_temps`, `mt_case_by_case`, `auto_approve_upgrades`, `diesel_bridge`, `flex_mandatory`.
- IT: `monteur_in_every_review`, `paper_form_scanning`, `whatsapp_official`, `third_environment`, `booking_board`, `skip_regression_small`, `offshore_test_factory`, `stretch_overtime`.

**Validator check (catalogue §2.15), by hand.** Every option and every `needs` in this draft keeps one branch that no failure or skip can close:
- the crew options: the repair quests, train-the-trainer, the always-open baseline;
- `one_dig_agreements`: `repaired:contractor_rework`;
- `acm_pilot_time_bound`: the only `needs` that a failure closes for good. That is the catalogue's own door, and other countermeasures for `non_firm_unused` remain.

---

## 4. Summary tables

### 4.1 Missions (28, plus 2 tier-4 drafts)

| id | Track · act | Kind | Goal | Problem | Deadline → door | Principles | Temptation (later cost) | Dialogs |
|---|---|---|---|---|---|---|---|---|
| t3_map_region | grid · IV | M | map_stream (areas) | — | — | improve, respect | bought VSM (averages hide the areas; trust) | — |
| fix_long_drives | grid · IV | M | solve | long_drives | — | respect, long_term | travel allowance (an entitlement; trust −2 later) | joke_depot |
| fix_training_capacity | grid · IV | M | solve | training_capacity | 63 d → apprentice_cohort_september | respect, long_term | freelance monteurs (no one trained; options locked) | patrick_trainers (+ Ahmed check-in) |
| t3_crew_strategy | grid · IV | M | strategy | — | — | long_term, respect | overtime push (aftermath in weeks 7–14) | marco_crew |
| fix_underground_crowding | grid · IV | M (B) | solve | underground_crowding | — | respect, long_term | deep bypass (digging faults later) | marloes_one_agenda |
| fix_uneven_release | grid · IV | M (N) | solve | uneven_release | — | improve, respect | peak temps (the peak returns monthly) | hermans_release |
| t3_kaizen_week | grid · IV | M | kaizen_event | — | — | respect, improve | consultant blitz (compliance buy-in; "Dit is 2012") | team_lead_kaizen |
| fix_priority_first_come | grid · IV | M | solve | priority_first_come | — | respect, long_term | the sports hall (ACM complaint; audit finding) | jeroen_classes |
| fix_household_rush | grid · IV | S | solve | household_rush | — | improve, respect | auto-approve (De koude straat) | sjaak_advice |
| fix_nitrogen_permit | grid · IV | M | solve | nitrogen_permit | 120 d → route_via_industrial_zone | long_term, improve | diesel bridge (its own permit slows the station's) | dennis_aerius |
| t3_stop_starting | grid · IV | M | hold_kpi | — | — | long_term, improve | concept folder (audit finding) | joost_wip |
| fix_non_firm_unused | grid · IV | S | solve | non_firm_unused | — | long_term, respect | flex mandatory (reputation; forecast) | aziz_coldchain |
| fix_solar_feedin_wait | grid · IV | S | solve | solar_feedin_wait | — | improve, long_term | — | verhoeven_cap |
| sector_energy_hub | grid · IV | S | talk_to | — | — | improve | — | thomas (topics) |
| coach_work_prep_lead | grid · IV | S | coach | — | — | respect, improve | giving the answer (the session does not count) | the Kata script |
| lsw_layered_audit | grid · IV | R | routine | — | — | long_term | skipping it (decay) | — |
| sustain_connections | grid · IV | S | hold_kpi | — | — | long_term, improve | — | — |
| repair_long_drives | grid · IV | S (repair) | rework_fix | long_drives | — | long_term, improve | — | joke_depot_repair |
| it_map_feature_stream | IT · VI | M | map_stream | — | — | improve, respect | the tool's cycle time (waits hidden) | — |
| fix_field_app_bypassed | IT · VI | M | solve | field_app_bypassed | — | respect, long_term | WhatsApp made official (privacy aftermath) | noor_field_app, ricardo_whatsapp |
| fix_release_twice_a_year | IT · VI | M | solve | release_twice_a_year | — | long_term, respect | skip regression (incidents ×1.5) | erwin_cab |
| fix_test_env_queue | IT · VI | M (B) | solve | test_env_queue | — | improve, long_term | a third environment (elevate before exploit) | priya_envs |
| fix_code_review_wait | IT · VI | M (N) | solve | code_review_wait | — | respect, improve | — | mark_pairing |
| fix_manual_regression | IT · VI | M | solve | manual_regression | — | respect, long_term | a test factory (edge cases missed) | hanneke_edge_cases |
| fix_pi_overcommit | IT · VI | M | solve | pi_overcommit | — | long_term, respect | stretch and overtime (fatigue) | carla_must_haves |
| *(tier 4)* fix_status_page_wrong · fix_meter_data_mandates | IT · VI | M · S | solve | status_page_wrong · meter_data_mandates | — | respect, long_term | a FAQ · skip big suppliers | noor_status · lisette_privacy |
| fix_ops_dev_wall | IT · VI | S | solve | ops_dev_wall | — | respect, improve | find the culprit (silence; option locked) | bart_postmortem |
| talk_rte | IT · VI | S | talk_to | — | — | improve | — | bas (topics) |
| lsw_system_demo | IT · VI | R | routine | — | — | improve | — | — |

**The 1 + 3 rule:**
- One main at a time across both chains; a fork offers two and the player takes one.
- Sides open spread over the act. The heaviest moment is after `t3_map_region`: up to five sides become available (`fix_non_firm_unused`, `fix_solar_feedin_wait`, `fix_household_rush` in July, `fix_ops_dev_wall`, plus `lsw_layered_audit`). The player can hold only three; this is the act's real trade-off between routines and side problems (catalogue §2.9).

**Forks:** two, `t3_havenzij` and `it_after_release`, in parallel chains, both throughput forks (correction 8). **Hard deadlines:** two, never active at the same time by the chain order.

### 4.2 Problems (16, plus 2 tier-4 drafts) and countermeasures (57, plus 6)

| Problem | Step | Waste | KPI | Countermeasures (fit) |
|---|---|---|---|---|
| long_drives | lv_connections.execution | transport | throughput | satellite_depot 1.0 · area_day_routing 0.8 · mobile_van_stock 0.6 · outsource_area 0.6 |
| training_capacity | monteurs (pool; C17c) | skills | capacity | train_the_trainer 1.0 · apprentice_cohort_september 0.9 · hybrid_crews 0.8 · freelance_monteurs 0.6 |
| underground_crowding | hz_connections.design | overprocessing | throughput | joint_street_planning 1.0 · one_dig_agreements 0.8 · standard_duct_designs 0.7 · deep_bypass 0.6 |
| uneven_release | hz_connections.release | waiting | lead_time | level_release_with_developer 1.0 · frozen_planning_window 0.8 · peak_temps 0.6 |
| priority_first_come | congestion.intake | defects | lead_time | classify_at_intake 1.0 · public_queue_with_class 0.7 · mt_case_by_case 0.5 |
| household_rush | connections.intake | overproduction | lead_time | heat_pump_check 1.0 · installer_briefing 0.8 · auto_approve_upgrades 0.5 |
| nitrogen_permit | hz_reinforcement.nature_permit | waiting | wip_age | parallel_ecology 1.0 · route_via_industrial_zone 0.8 · emission_free_build 0.8 · aerius_template 0.7 · diesel_bridge 0.5 |
| non_firm_unused | congestion.offer | overprocessing | lead_time | standard_flex_at_first_contact 1.0 · acm_pilot_time_bound 0.9 · group_contract_business_park 0.7 · flex_mandatory 0.5 |
| solar_feedin_wait | lv_feedin.capacity_queue | waiting | lead_time | cable_pooling 1.0 · peak_shaving_contract 0.8 |
| field_app_bypassed | connections.close_out | overprocessing | lead_time | close_out_redesign_with_monteurs 1.0 (release-gated) · offline_mode 0.8 (release-gated) · monteur_in_every_review 0.7 · paper_form_scanning 0.6 · whatsapp_official 0.4 |
| release_twice_a_year | it_features.release | waiting | lead_time | ci_cd_pipeline 1.0 · monthly_release_train 0.8 · feature_toggles 0.7 · skip_regression_small 0.4 |
| test_env_queue | it_features.test | waiting | throughput | environments_on_demand 1.0 · synthetic_test_data 0.8 · third_environment 0.7 · booking_board 0.6 |
| code_review_wait | it_features.review | waiting | lead_time | pairing_on_hard_parts 1.0 · review_rota 0.7 |
| manual_regression | it_features.test | overprocessing | throughput | test_automation_pyramid 1.0 · edge_cases_first 0.8 · testers_in_teams 0.7 · offshore_test_factory 0.6 |
| pi_overcommit | it_features.refine | overproduction | on_time | capacity_based_pi 1.0 · committed_and_uncommitted 0.8 · stretch_overtime 0.5 |
| *(tier 4)* status_page_wrong · meter_data_mandates | it_features.in_use · meter_data.mandate_check | defects · overprocessing | on_time · lead_time | §2.8 |
| ops_dev_wall | it_incidents.fix | defects | lead_time | blameless_postmortems 1.0 · you_build_it_you_run_it 0.9 · shared_on_call 0.8 |

**Wastes.** Six of the eight: transport, skills, overprocessing, waiting, defects and overproduction. Motion and inventory are carried by tiers 1–2 (the tray, the revision backlog, unused capacity).

**Countermeasures by category.** People-developing options are present in every people-shaped problem:
- `train_the_trainer`, `hybrid_crews`;
- `testers_in_teams`, `edge_cases_first`;
- `blameless_postmortems`, `pairing_on_hard_parts`.

D26 *Ontwikkelen, niet vervangen* can be earned in this tier.

---

## 5. Voice sheet: the tier-3 cast

As in the Acts 0–II scripts §2. Everyone speaks standard Dutch (decided 2026-10-15: no dialect). Voices differ in word choice, rhythm, humour and worry: Lindeveld people talk in distances and hours, Havenzij people are direct, and IT people use English loanwords ("backlog", "release"), which is real and stays.

| id | Who (age) | Voice | Humour | Worry (hidden) |
|---|---|---|---|---|
| `joke` | Joke van Beek (51), TL monteurs Lindeveld | Farmer's daughter; practical, warm, talks in distances: "kijk", "veertig kilometer", "mijn mannen". | "Neem koffie mee, het is ver." | That "efficiënter" means her people work eight hours underground with no breath. |
| `patrick` | Patrick Smeets (58), head of the Opleidingscentrum | Ex-instructor; precise, safety first: "veilig", "aftekenen". | Dry about cable drums in the doorway. | Signing for a young monteur he never saw. |
| `yusuf` | Yusuf Demir (38), TL Werkvoorbereiding Havenzij | Rotterdam-direct, proud of his team: "mijn mensen", "puzzelen". | "Neem een vergrootglas mee." | That outsiders take the credit for what his people already knew. |
| `marloes` | Marloes Kramer (46), gemeente Havenzij | Civil-servant formal, "u", tired of meetings. | "Daar heb ik er al vier van." | Being the face of yet another meeting that delivers nothing. |
| `dennis` | Dennis Wouters (44), vergunningenadviseur | Careful, legal words: "Raad van State", "berekening", "afgeschoten". | Rare: the irony of a hydrogen plant waiting on nitrogen. | That he is the only one, and his calculation gets shot down in court. |
| `hermans` | Peter Hermans (55), Hermans Bouw | Businesslike, "u", talks in certainty and contracts. | — | A lawyer calling because one buyer got power later than his neighbour. |
| `sjaak` | Sjaak van Rooij (49), installer | Busy, on a ladder, short sentences: "kort graag". | "Mijn naam staat op het busje." | The complaint when a heat pump throttles: his name, his village. |
| `aziz` | Mohammed Aziz (43), ColdChain Havenzij | Firm, numbers and insurance: "tonnen aan vlees en vis". | "Dat kan ik zelfs aan mijn vader uitleggen." | One cut, one lost cargo, one lost company. |
| `verhoeven` | Gerard Verhoeven (61), Zonnepark De Hoge Akker | Farmer, slow, "u", proud. | The sloot dispute with neighbour Van Dam. | That his son Jesse leaves, and he is the last Verhoeven on the farm. |
| `noor` | Noor Hendriks (33), PO veldapp | Office Dutch with Jira words: "backlog", "done", "refinement". | — | That she never rode along with a monteur and built four years of the wrong things. |
| `ricardo` | Ricardo (34), monteur, admin of the WhatsApp group | Practical, quick, a little defiant: "hij werkt", "kom maar eens in een kelder staan". | Birthday cakes in the group. | That taking the group away takes the team's glue, not just a channel. |
| `erwin` | Erwin de Groot (52), release manager, CAB chair | Procedural, a scar: "in 2023…". | "De pizza blijft." | Approving another release that breaks 40,000 customers' data. |
| `priya` | Priya Ramdin (36), infra engineer (Beheer) | Technical, careful: "maskeren", "omgeving". | "De volgende is vrij op 3 december." | A data leak through a test environment: the Autoriteit Persoonsgegevens. |
| `mark` | Mark van Leeuwen (29), developer | Quiet, honest, headphones. | — | Pairing all day; he burned out once at a previous employer. |
| `hanneke` | Hanneke Willems (57), senior tester | Twenty years of edge cases; dry: "vooral de rare". | "Ik zal er niet bij zijn als het misgaat. O nee, wacht. Toch wel." | Green tests that miss the farmer with the wind turbine. |
| `carla` | Carla Wijnands (49), directeur Klant & Markt | Board language: "raad van bestuur", "compliant", "toegezegd". | — | Six months in the job and already taking back a promise. |
| `lisette` | Lisette Koster (45), functionaris gegevensbescherming (tier 4) | Firm: "geen data zonder mandaat". | "Een knop: 'laat zien'." | Defending a manual Excel check to the Autoriteit. |
| `bart` | Bart Jacobs (40), ops engineer | Cynic: "we hebben al een poster". | "De eerste die 'wie' zegt, haalt koffie." | The May postmortem that asked who had duty. |
| `bas` | Bas Kuipers (45), RTE (expert) | Calm facilitator: "trein", "ritme", "dienstregeling". | "Een trein vertrekt op tijd." | — (expert) |

---

## 6. New concepts (for `content/concepts.yaml`)

Each concept gets a Dutch `short` and `text` and a `source`, or `estimate:` (the existing validator rule: a sector concept needs one or the other). Sketch:

| id | Category | Name (NL) | Source |
|---|---|---|---|
| `value_stream_mapping` | lean | Waardestroom in kaart brengen | Rother & Shook, *Learning to See* (1999) |
| `kaizen_event` | lean | Kaizenweek | Imai, *Gemba Kaizen* (1997); Laraia, Moody & Hall (1999) |
| `conwip`, `littles_law` | lean | Een vaste hoeveelheid onderhanden; De wet van Little | Spearman, Woodruff & Hopp (1990); Little (1961) |
| `twi_job_instruction` | lean | Iemand een handeling leren in vier stappen | TWI manuals (1940s) |
| `ondergrondse_ordening` | sector | Wie ligt waar onder de stoep | Wibon / KLIC (Kadaster); *estimate* for the practice of joint planning |
| `maatschappelijk_prioriteren` | sector | Wie gaat er voor in de wachtrij | ACM prioritisation framework (2024; renewed 2026); RVO |
| `stikstof` | sector | Stikstof en netuitbreiding | Raad van State, Porthos, 2 Nov 2022; Netbeheer Nederland |
| `cable_pooling` | sector | Eén aansluiting voor zon en wind | Art. 1(7) E-wet 1998 *(verify under the Energiewet)*; RVO |
| `energiehub`, `groepstransportovereenkomst` | sector | Een energiehub; het groepscontract | ACM draft code decision (2025); Liander Deventer pilot |
| `klantmandaat` | sector | Meetdata alleen met toestemming | Kamerstuk 29023-202; P4 |
| `value_stream_identification`, `small_batches`, `ci_cd`, `infrastructure_as_code` | lean | IT: de stroom, klein uitbrengen, de pijplijn, omgevingen uit code | Poppendieck (2006); Reinertsen (2009); Humble & Farley (2010) |
| `test_automation` | lean | Testen bij elke wijziging | Cohn (2009) |
| `pair_programming` | lean | Samen programmeren | Beck, *Extreme Programming Explained* (1999) |
| `art`, `pi_planning` | lean | Release train; PI-planning | Scaled Agile Framework *(verify SAFe 6.0 pages)* |
| `dora_metrics` | measure | De vier DORA-getallen | Forsgren, Humble & Kim, *Accelerate* (2018) |
| `blameless_postmortem`, `devops` | lean | Nabespreken zonder schuldvraag; DevOps | Allspaw (2012); Google SRE (2016); Vogels (2006) |

---

## 7. What these drafts require from code

Beyond the catalogue (C1–C20), the tier-2 draft (§6 there) and the dialog spec (D1–D11):
1. **Areas and IT streams (K6, K9):** the pools and streams of §0.3. `map_stream` takes `areas`.
2. **A problem on a pool** (`training_capacity`, `step: monteurs`) with the C17c headcount ramp. Until then, its effects work on today's properties, but the problem needs a place for its clues (the training centre: a new place, `training.yard`).
3. **Facts:**
   - `agreed:<dialog>:<proposal>`, set when a dialog ends in commitment or partial with that proposal on the table;
   - `constraint_place:<step>`, live, for dialog variants;
   - flags with `cleared_by` (`content/flags.yaml`).
4. **Countermeasures:**
   - `needs_discount`;
   - `release_gated` (the Check's `too_early` with the reason "release", and the effect starting at the stream's next release);
   - `cost_per_week` on countermeasures, not only on problems.
5. **Goals:**
   - `hold_kpi` (the tier-2 draft's suggested name) with several KPIs and a target relative to the base (`base_x1.1`);
   - `kaizen_event` with `place: current_constraint`;
   - `requires.facts` with `done | failed` of a mission.
6. **Strategy options** with `cost_per_week` and an `aftermath` inside the forecast horizon, so a short-term option's cost shows in the 91-day forecast.
7. **Temptations** with `when: session` (the coach goal), and the accept effects `complete_goal`, `measure_bonus`, `cost`, `cost_per_week`, `trust`, `reputation`.
8. **`opens_on: {day_of_year: n}`** for a calendar date (the household rush in July).
9. **Content tests:**
   - the fork honesty test (C15) for `t3_havenzij` and `it_after_release` on throughput;
   - `t3_crew_strategy` offers ≥ 2 options on the expert path and the baseline plus overtime on the worst path;
   - the repair of `long_drives` reopens the Lindeveld option (K11);
   - `fix_field_app_bypassed` can be completed without waiting for a release (through another countermeasure);
   - every dialog's listening route stays within patience (the Acts 0–II scripts §9 method).

---

## 8. Questions for Merijn: decided

Merijn answered on 2026-10-15 (PLAN.md "Decisions Made"). Every choice is also logged under "Claude's calls, pending Merijn" so he can overrule it.

1. **Where the IT track starts.** **Decided (b): the field app first, as in the catalogue.** The tier-3 IT chapter now opens with `fix_field_app_bypassed` (§2.2). The customer portal and the meter-data platform follow in the tier-4 IT chapter (§2.8).
2. **The `release_gated` twist.** **Decided (a):** the Check says "staat klaar, gaat live bij de volgende release"; the player can wait or re-A3, and the repair quest later ships the best fix. It now sits in the field-app mission.
3. **"Wie gaat er voor?"** **Decided (a):** reframed to the 2026 reality.
4. **Yusuf's "fourth draughtsman" talk.** **Decided (a):** a beat only.
5. **The way back after a consultant-led kaizen.** **Decided (a):** a second, team-led kaizen week through the layered audit's next cycle.
6. **The nitrogen fix and the investment plan.** **Decided (a):** an `any` branch for "Standaardstations in serie".
7. **The household rush.** **Decided (a):** an Act IV side, opening in mid-July of the game's calendar.
8. **The overtime option in the crew strategy.** **Decided (a):** always open, with its aftermath inside the forecast.
9. **Area sizes.** **Decided (a):** Lindeveld 5 monteurs; Havenzij 6 monteurs and 3 draughtsmen; calibrated in K6.
10. **Temptations per mission.** **Decided (a):** one per main mission; on sides only where it teaches something new.
11. **The new cast.** **Decided (a):** kept.

Related decisions: standard Dutch for every character (no dialect; §5 and all lines revised); customers by phone now, home visits later; colleagues leave rarely; "Respect the player's time" is a CLAUDE.md rule.

---

## Sources

- Netbeheer Nederland — *Stand van de uitvoering, halfjaarpublicatie 2025*: https://www.netbeheernederland.nl/sites/default/files/2025-10/stand_van_de_uitvoering_halfjaarpublicatie_2025.pdf
- Minister's letter on congestion, Kamerstuk 29023 (queue on 1 July 2025): https://zoek.officielebekendmakingen.nl/kst-29023-AM.pdf
- KHN — "Netcongestie: vanaf 1 juli 2026 ook kleinverbruikers op de wachtlijst": https://khn.nl/nieuws/netcongestie-vanaf-1-juli-2026-ook-kleinverbruikers-op-de-wachtlijst
- Gemeente Den Haag — "Adviezen aan bedrijven bij vol elektriciteitsnet": https://www.denhaag.nl/nl/?p=135463
- Welingelichte Kringen (ANP, 24 July 2026) — "Vlak voor ingaan nieuwe regels piek in aanvragen netaansluiting": https://www.welingelichtekringen.nl/samenleving/vlak-voor-ingaan-nieuwe-regels-piek-in-aanvragen-netaansluiting
- RVO — "Voorrang op elektriciteitsnet": https://www.rvo.nl/onderwerpen/netcongestie/voorrang-op-elektriciteitsnet
- Overstappen.nl — "Nieuwe regels voor het stroomnet zijn ingegaan": https://www.overstappen.nl/nieuws/nieuwe-regels-voor-het-stroomnet-zijn-ingegaan-heb-je-echt-een-zwaardere-aansluiting-nodig/
- Rechtspraak (CBb, 11 March 2025) — "Prioriteringskader van ACM voor transportverzoeken elektriciteit houdt geen stand": https://www.rechtspraak.nl/organisatie-en-contact/organisatie/college-van-beroep-voor-het-bedrijfsleven/nieuws/2025/03/prioriteringskader-van-acm-voor-transportverzoeken-elektriciteit-houdt-geen-stand
- ACM — "Voorrang maatschappelijke projecten blijft mogelijk met nieuw prioriteringskader": https://www.acm.nl/nl/node/28593
- Raad van State — "Bouwvrijstelling stikstof van tafel" (Porthos): https://www.raadvanstate.nl/@133608/bouwvrijstelling-stikstof-van-tafel/
- Solar Magazine — "Stikstofuitspraak: netbeheerders vrezen vertraging door wegvallen bouwvrijstelling": https://solarmagazine.nl/nieuws-zonne-energie/i28300/stikstofuitspraak-netbeheerders-vrezen-vertraging-door-wegvallen-bouwvrijstelling
- Netbeheer Nederland — commissiedebat stikstof en natuur (2025): https://www.netbeheernederland.nl/sites/default/files/2025-04/netbeheer_nederland_l_commissiedebat_stikstof_en_natuur.pdf
- Dirkzwager — "Cable pooling en de Energiewet": https://www.dirkzwager.nl/kennis/artikelen/blogreeks-juridische-oplossingen-netcongestie-2-cable-pooling-en-de-energiewet
- RVO — "Cable pooling": https://www.rvo.nl/onderwerpen/netcongestie/cable-pooling
- Solar Magazine — "Liander sluit groepstransportcontract voor energiehub Deventer": https://solarmagazine.nl/nieuws-zonne-energie/i41235/liander-sluit-groepstransportcontract-voor-energiehub-deventer
- Solar Magazine — "Netbeheerders presenteren voorstel groepstransportovereenkomst": https://solarmagazine.nl/nieuws-zonne-energie/i38888/netbeheerders-presenteren-voorstel-groepstransportovereenkomst-voor-delen-transportcapaciteit
- Solar Magazine — "Netbeheerders en aannemers werven 5.000 extra technici via opschalingsplan": https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan
- Stedin — brochure "Uw zakelijke aansluiting" (mijnaansluiting.nl, request code): https://www.stedin.net/-/media/project/online/files/aansluiting/brochure-zakelijke-aansluiting-mijnaansluitingen.pdf
- Kamerstuk 29023-202 (smart-meter data, customer mandate): https://zoek.officielebekendmakingen.nl/kst-29023-202.pdf
- DORA metrics summary (Codefresh): https://codefresh.io/learn/software-deployment/dora-metrics-4-key-metrics-for-improving-devops-performance
- PI planning summaries (Appfire; Lucid): https://appfire.com/resources/blog/pi-planning-101 · https://lucid.co/blog/what-is-pi-planning
- Books: Rother & Shook (1999); Imai (1997); Laraia, Moody & Hall (1999); Spearman, Woodruff & Hopp (1990); Hopp & Spearman, *Factory Physics*; Liker (2004); Poppendieck & Poppendieck (2006); Reinertsen (2009); Humble & Farley (2010); Cohn (2009); Beck (1999); Forsgren, Humble & Kim (2018); Allspaw (2012); Beyer et al., *Site Reliability Engineering* (2016); Vogels (2006).
