# Spanning — Game Design Document

> Repo copy of the shared Claude Doc "Spanning — Game Design Document", synced 2026-10-12 after Merijn's review. The shared doc is the place for comments; this copy is versioned with the code. When they differ, the newer one wins and gets synced.

Spanning is a 3D game, built in Godot 4 for desktop with a browser build as well, in which you practise Lean as the new continuous improvement lead of Voltana Netbeheer, a fictional Dutch grid operator.

## Vision and pillars

The game exists so you learn two things at once: how a Dutch grid operator really works and struggles, and how to apply Lean there with judgement, not by the book. It is built for Merijn first. Game text is Dutch; design and code are English.

Every feature must serve these seven pillars. When a feature conflicts with a pillar, the pillar wins.

| # | Pillar | What it means in play |
| --- | --- | --- |
| 1 | Learn by doing, safely | Mistakes cost time, budget and trust, never the game. Recovery is always possible and often is the lesson. |
| 2 | Thinking, not quizzing | Clues are earned through gemba actions and good questions. You write the A3; the simulation judges the result. No multiple-choice answers with a "correct" label. |
| 3 | Respect for people | Problems live in the process. Blaming questions cost trust and information; good coaching opens doors. |
| 4 | Quality first | Rework loops are simulated and visible: incomplete applications, wrong GIS data, failed commissioning, repeat visits. |
| 5 | See the 8 wastes | TIMWOODS in a service and field organisation: the backlog itself, waiting for permits, driving, searching for materials, approvals nobody needs, rework, unused expertise. |
| 6 | Bottleneck first, end to end | Every value stream is mapped end to end. Improving a non-constraint is shown for what it is: no extra output. You build the value stream map by walking it. |
| 7 | Real sector problems | Grid congestion is one problem among many. The catalogue covers the well-known and the less-known struggles of Dutch grid operators, grounded in public sources. |

## Player role and core loop

You are the new CI lead of region Zuidmark. You have no formal authority over the departments, only your questions, your data and the trust you earn. Each in-game day follows the same loop. Problems run the full PDCA cycle, and Check judges on numbers, not on your intentions.

The loop (drawn as a diagram in the shared doc):

1. **Dagstart:** board, numbers, focus.
2. **Go to the gemba:** walk campus and town.
3. **Investigate:** tools, talks, clues.
4. **Write the A3:** cause, fix, prediction. *(Plan ends here.)*
5. **Run the experiment:** countermeasure live. *(Do)*
6. **Check at the gemba:** step and end to end. *(Check)*
   - If the numbers did not improve, go back to step 3.
7. **Act:** standardise or adjust. *(Act)*
8. **Reflect:** score, lessons, codex. Then the next day starts at step 1.

The way back from Check to Investigate is the most important arrow. When Check shows no improvement, you return to the gemba with what you learned. That is PDCA working, not failing.

**Story** (Merijn, 2026-10-12): a narrative arc with side quests, with some open-world freedom. Candidate milestones: the first 100 days, an NTA 8120 certification audit, an ACM visit, a storm week.

## World

The gemba is spread out: an operations campus where work is prepared, and a town where it is done. Both are walkable in 3D. Long trips go by van, and you can ride along or skip ahead.

**Campus Nova** is Voltana's regional base. Every room shows its work-in-progress physically, because in an office WIP is invisible and that is half the problem.

| Room | Who works there | Visible WIP | Value streams |
| --- | --- | --- | --- |
| Klantcontactcentrum | customer service agents | call queue board, ringing phones, sticky notes of callbacks | all (inbound demand and failure demand) |
| Intake & aanvraagbeheer | intake officers | in-trays of applications, "onvolledig" pile | connections, congestion |
| Netstrategie & netstudies | grid analysts | study queue on a wall board, maps of congested areas | connections, congestion |
| Werkvoorbereiding & engineering | work planners, designers | drawing stacks, permit folders waiting for the gemeente | connections, reinforcement |
| Planning | short- and long-term planners | the week planning board; red cards when storingen bump planned work | all field work |
| Bedrijfsvoeringscentrum (control room) | operators on shifts | video wall with the grid, alarms, open storingen | outages, congestion |
| Magazijn & logistiek | warehouse staff | racks of cable drums, joints, meters, transformers; empty bins | all field work |
| Werkplaats & opleidingscentrum | trainers, apprentices | training yard with practice cables and cabinets | people capacity |
| Revisie & GIS | GIS specialists | backlog of as-built drawings waiting to be entered | connections, outages (data quality) |
| Directie & Obeya | regional manager, the Lean coach | Obeya walls: value stream maps, KPIs, A3s | strategy |

**The town of Nova** has about 12,000 connections:
- streets of terraced houses with solar panels, heat pumps and EV chargers;
- a newer district still under construction;
- a business park waiting for capacity;
- a farm with a solar field;
- a school and a care home (priority customers).

The grid is visible where it would be in reality:
- green distribution substations (MSR) on street corners;
- an MS ring;
- LS cables under the pavement, shown when you look at a street through "grid view";
- the primary substation (onderstation) at the edge of town.

Things you can see happen in town:

- vans driving to jobs, crews digging and jointing cables, meter technicians ringing doorbells (and nobody answering);
- a street going dark during an outage, the van racing in, the lights coming back;
- inverters tripping on a sunny afternoon in the solar-heavy street;
- a contractor's excavator hitting a cable;
- an empty lot on the business park where a company waits for capacity.

## Value streams

Four value streams run at the same time and compete for the same people, above all the monteurs. Outages always go first, so a busy outage week visibly wrecks the planning of connections and meter jobs. A fifth stream, IT, comes in a later phase. Gas comes in a later phase too.

### 1. Nieuwe aansluitingen & netverzwaring

A household, builder or business asks for a new or heavier connection.
- **Quote norm:** a quote within 10 working days of a complete application, with 5 days to ask for missing details.
- **Connection term:** the legal term was 18 weeks (12 without digging), but the CBb annulled the ACM decision in September 2024. A new draft is expected in 2026.
- **In practice:** real quotes have shown 65+ weeks where the grid needs reinforcement first.

| # | Step | Who (pool) | Where it waits | Typical rework |
| --- | --- | --- | --- | --- |
| 1 | Aanvraag & intake | intake officers | application incomplete | missing data, wrong capacity requested |
| 2 | Netstudie (only if near capacity) | grid analysts | study queue | assumptions on outdated load data |
| 3 | Offerte & akkoord | intake officers | customer signing | quote changed after site visit |
| 4 | Werkvoorbereiding & ontwerp | work planners | drawings queue | design based on wrong GIS data |
| 5 | Vergunning & KLIC | work planners (external: gemeente) | permit lead time | permit expired, route changed |
| 6 | Materiaal reserveren | warehouse | stock-out (meters, cable, MSR) | wrong material picked |
| 7 | Planning | planners | next free monteur slot | bumped by storingen |
| 8 | Uitvoering (graven, aansluiten) | monteurs, contractors | travel, installer not ready | meterkast niet gereed → wasted visit |
| 9 | Inbedrijfname & meter | monteurs | — | failed commissioning |
| 10 | Revisie & administratie | GIS specialists, admin | revision backlog | EAN not registered → customer cannot get a contract |

### 2. Storingen (outage response)

An outage is reported or detected.
- **Norms** from the grid code (2013 wording, to verify): on site within 2 hours for connections up to 3×80 A, and restored within 4 hours on networks up to 1 kV. Customers get a standard compensation after 4 hours.
- **2024 Dutch averages:** 23.9 outage minutes per customer; 27,341 interruptions, each affecting 113 customers for 69.8 minutes.

| # | Step | Who (pool) | Where it waits |
| --- | --- | --- | --- |
| 1 | Melding / detectie | klantcontact, control room | LS faults are only known when customers call |
| 2 | Lokaliseren | control room operators | no sensors on most LS cables |
| 3 | Uitsturen | control room | nearest on-call monteur far away |
| 4 | Aanrijden | on-call monteur | travel time |
| 5 | Herstel (schakelen, mof maken) | monteurs | right joint not in the van |
| 6 | Afmelden & oorzaak vastleggen | monteurs, control room | cause recorded as "onbekend" |

### 3. Veldservice & slimme meters

Meter replacements and service jobs at homes. Two programmes run now:
- the last ~500,000 analogue meters are being replaced, with letters in 2026–2027 and an appointment within six weeks of the letter;
- about 2.5 million first-generation smart meters with outdated GPRS are being replaced between 2024 and 2029.

| # | Step | Who (pool) | Where it waits | Typical rework |
| --- | --- | --- | --- | --- |
| 1 | Aanbiedingsbrief | back office | customer response | no response, wrong address |
| 2 | Afspraak maken | klantcontact | call queue | rescheduled appointments |
| 3 | Route & planning | planners | — | bumped by storingen |
| 4 | Bezoek & vervanging | meter monteurs, contractors | travel | niet thuis → repeat visit |
| 5 | Communicatietest | back office | — | meter not communicating → second visit |

### 4. Congestiemanagement

Large consumers and producers wait for transport capacity. At the end of 2025, more than 15,000 large-consumer requests sat in the regional queue nationally.

Instruments:
- congestion studies;
- flexible contracts: non-firm, the time-bound transport right (≥85% availability at about half the tariff), and the capaciteitsbeperkingscontract;
- reclaiming unused capacity (GOTORK);
- the prioritisation framework for societal projects (mandatory since 1 October 2024).

| # | Step | Who (pool) | Where it waits |
| --- | --- | --- | --- |
| 1 | Aanvraag transportcapaciteit | intake (zakelijk) | queue position |
| 2 | Toetsing & congestieonderzoek | grid analysts | study backlog |
| 3 | Aanbod: vast, flexibel of wachtrij | account managers | customer decision |
| 4 | Contract & meting | account managers, back office | — |
| 5 | Netverzwaring (project) | engineering, contractors | permits, nitrogen, transformer lead times |

### 5. IT-waardestromen (later phase)

Features for the field app and planning systems, and incident handling. Scope for Phase G: release trains, dependencies, test environments, DevOps practices.

## Regulation and management systems

Merijn asked for ACM regulation and ISO to be modelled, not kept light. Two sources of rules shape the game:
- **ACM** (the regulator): connection terms, the grid code norms, congestion instruments and the prioritisation framework.
- **NTA 8120**: the Dutch safety, quality and capacity management system for grid operators, aligned with ISO 55001 asset management and certified under NN-CAM 5.0. It supplies audits, risk-based maintenance decisions and PDCA at system level.

## Simulation model

The simulation moves individual work orders through a network of steps, so queues, waiting and rework are real objects you can count and see, not abstract numbers. It is plain GDScript with no scene nodes, so it runs and is tested headless, separate from the 3D visuals.

**Building blocks**

| Element | What it is | Examples |
| --- | --- | --- |
| Work order | one unit of work with a type, a value stream, a birth time and a due date | a connection request, an outage, a meter job |
| Step | a stage with touch time per order, a first-time-right rate, and where rework goes back to | Werkvoorbereiding: 6 h touch time, 85% FTR, rework to Intake |
| People pool | people with skills, working hours, availability (sickness, training, travel) and an order of priority | monteurs (14), grid analysts (4), planners (3) |
| External wait | a delay nobody at Voltana works on | gemeente permit, customer signature, supplier delivery |
| Stock item | a material with stock level, reorder point and supplier lead time | smart meters, LS cable, joints, MSR transformers |
| Arrivals | demand per day per order type, with weekly patterns and shocks | heatwave, storm, a new housing project |

**Rules that create realistic behaviour**

- Pools serve the highest priority first: outages pre-empt planned work. That is why planned work slips in a storm week, and the plan shows it.
- Rework sends an order back to an earlier step, so poor quality at the front shows up as extra load downstream (quality first).
- External waits cannot be worked faster, only managed: request in time, batch less, follow up.
- Each value stream has an end-to-end capacity and a constraint, computed from touch times, people, availability and FTR (generalised from the factory prototype). The constraint can move when you fix things.
- Failure demand is modelled: late orders generate status calls at the klantcontactcentrum, which load agents who then answer fewer real requests.
- Improvements cost both a *verbeterbudget* in euros and team hours (Merijn, 2026-10-12).

**Time**

- A working day takes about 60 seconds at 1× speed (pause, 1×, 4×, 16×). Outages resolve within the day; connections take weeks; reinforcement projects take months.
- Each morning the game pauses for the *dagstart*: yesterday's numbers, today's board, choose where you go. Then the day runs in real time.
- Seasons and events matter: summer brings solar overvoltage and heatwave transformer load, winter brings storms and evening peaks.
- Target session length: 15–40 minutes (Merijn, 2026-10-12). Saving is automatic and a session can end at any dagstart.

**KPIs per value stream:**
- throughput per week;
- backlog (WIP);
- lead time (median and 85th percentile);
- share on time against the norm;
- first-time-right;
- for outages, the outage minutes per customer.

Little's Law is visible everywhere: backlog = throughput × lead time.

## Problem solving

You solve problems the way you would on a real assignment: go and see, collect facts, ask good questions, form your own conclusion, run an experiment, and let the numbers judge. The game never shows a list of three answers with one marked correct.

**Gemba tools.** Each takes game time, so investigating has a cost and choosing where to look is part of the skill.

| Tool (in game) | What you do | What it typically reveals |
| --- | --- | --- |
| Meelopen | shadow a monteur, planner or agent for half a day | motion, waiting, workarounds, missing materials |
| Tijdstudie | time 10 cycles of a step | touch time vs waiting, variation |
| Wachtrij tellen | count and age the orders in a queue | backlog size, oldest items, FIFO violations |
| Data analyseren (SAP/GIS/Nestor) | pull system data and look for patterns | rework rates, repeat faults, seasonal peaks |
| Dossiers doorlezen | read applications, drawings, permits, procedures | missing standards, unclear ownership |
| Meeluisteren klantcontact | listen to calls at the contact centre | failure demand, what customers actually ask |
| Materiaal checken | check stock, bins and vans | stock-outs, hoarding, wrong items |
| Gesprek | talk to the person doing the work | their view, obstacles, ideas |

**Conversations and trust.** How you ask decides what you learn:
- Open questions ("walk me through…", "what gets in your way?") produce stories and clues.
- Closed questions get "yeah, mostly."
- Blaming questions cost trust: that person, and soon their team, stops sharing until you repair it.

Respect for people is a mechanic, not a slogan.

**Clues.** Every problem has key clues (pointing at the real cause) and red herrings (true facts that are not the cause). Deeper clues only appear after you have found the shallower one: the 5 Whys as an investigation. All clues land in your notebook with where and how you found them.

**The A3.** When you think you understand a problem, you write the A3:

1. Problem statement: from the symptoms you observed.
2. Current condition: the numbers you measured (unmeasured steps show "?").
3. Waste: which of the 8 wastes you see.
4. Evidence: link the facts that prove your case (red herrings count against you).
5. Root cause: choose from a bank of plausible causes, including real causes of other problems.
6. Countermeasure: from the full catalogue.
7. Prediction: what will change and roughly how much (Toyota Kata).

**Check and Act.** After the experiment has run, you go back to the gemba to check. You see the step's numbers and the end-to-end numbers of the value stream, before and after.
- A fix that works on a non-constraint is flagged: "the step improved, but the stream still waits on X."
- A fix without the right root cause can work by luck, but scores low: you can't standardise what you can't explain.

Then you decide: standardise (costs effort, prevents the problem coming back) or move on (it may return).

**Score**: five dimensions, each 1–5. The score explains itself in plain sentences.
- Go & See: key facts found, respect.
- Root cause: right cause, right waste, good evidence.
- Countermeasure: fit and maturity.
- Check & Act: prediction, standardised.
- Flow impact: did the end-to-end stream improve?

## Problem catalogue v1

Eighteen problems for the first region. They mix the famous ones (congestion, transformer lead times, technician shortage) with the quieter ones that eat capacity every day. Each will get full content in Phase B: symptoms, key clues per tool, red herrings, 5 Whys depth and effects on the simulation. Merijn approved the mix and asked for the catalogue to keep growing per difficulty tier; see the problem ideas backlog in `PLAN.md`.

| # | Problem (game name) | Stream · where | Waste | Root cause (hidden) | Effective countermeasures | Grounding |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | De onvolledige aanvraag | Connections · intake | Defects | The online form accepts applications without capacity, installer and meterkast details; nothing checks at the source | Poka-yoke form with mandatory fields; intake checklist; first-time-right at intake | Enexis norm: 5 working days to ask for missing details |
| 2 | Meterkast niet gereed | Connections · uitvoering | Waiting | Jobs are planned without checking the installer is ready | Readiness check 48 h before (call or photo upload); planning only on "ready" | common cause of wasted field visits |
| 3 | De statusbellers | Klantcontact · all streams | Defects (failure demand) | Customers are never told where their request stands, so they call | Proactive status updates; realistic promise date; measure failure vs value demand | long waits for connections (Enexis, 2025) |
| 4 | De revisieberg | Revisie & GIS | Inventory | As-built changes are drawn on paper after the job and typed in weeks later by a small team | Revision at the source (tablet as-built at completion); WIP limit on the backlog | less-known; feeds 5 and 10 |
| 5 | Graafschade | Outages · uitvoering | Defects | KLIC maps are outdated (see 4) and test trenches are skipped under time pressure | Standard test trenches; accurate GIS; contractor briefing | ~7% of digs in Brabant cause damage, 10.7% in Vught (Enexis) |
| 6 | Storing gooit de planning om | Planning · monteurs | Waiting | Every monteur is planned at 100%, so each outage reshuffles the week | Reserved outage capacity; frozen planning window; heijunka | planners plan across work streams with day windows for faults (Enexis vacancy) |
| 7 | De verkeerde mof in de bus | Outages · herstel | Transport | No standard van stock and no replenishment signal; monteurs drive back to the warehouse | Standard van stock list; two-bin kanban; 5S of the van | less-known |
| 8 | Vergunningen in batches | Werkvoorbereiding · vergunning | Waiting | Permits are requested weekly, and only after the design is finished | Request permits in parallel and early; standard permit packages; one contact at the gemeente | permits named as time-consuming by Enexis |
| 9 | De netstudie-wachtrij | Netstrategie | Waiting (constraint) | Every request gets a full custom study, even those clearly below capacity | Triage with fast lane; standard calculation templates; WIP limit | 15,000+ large-consumer requests waiting nationally (end 2025) |
| 10 | Maatwerk voor standaardwerk | Werkvoorbereiding | Over-processing | Standard household connections get a full custom design and three approvals | Standard designs for standard jobs; delegated approval | Enexis moved stations from custom to standard: ~10 to ~100 a year |
| 11 | Niet thuis | Meters · bezoek | Transport | Appointment windows of a whole day, no confirmation, no "on my way" message | Two-hour windows; confirmation the day before; standby list | ~500,000 analogue meters still to replace (2026–2027) |
| 12 | De zwijgende meter | Meters · communicatietest | Defects | The communication module is chosen without a coverage check, and nobody tests before leaving | On-site communication test before closing the job (jidoka); coverage check in planning | 2G/3G sunset; ~2.5 million GPRS meters replaced 2024–2029 |
| 13 | Omvormers die afschakelen | Congestion · LS grid | Defects | Transformer tap settings date from before rooftop solar, and the LS grid is not monitored | Use smart-meter voltage data; adjust taps; targeted reinforcement | inverters trip above 253 V; complaints tripled |
| 14 | Gereserveerd maar ongebruikt | Congestion · contracts | Inventory | Contracted capacity is never compared with actual use | Usage dashboard; GOTORK review; flexible contracts | GOTORK / use-it-or-lose-it (ACM) |
| 15 | Wachten op de trafo | Connections & congestion · materials | Waiting | Transformers are ordered per project after the design is done | Framework contracts; standard station designs; strategic stock | transformer lead times delay reinforcement 2–4 years |
| 16 | De laatste kennisdrager | Monteurs · people | Skills | Knowledge of old cable types and switching sits with a few retiring monteurs; training capacity is scarce | Skills matrix; buddy system; standard work videos; train-the-trainer | 28,000-technician shortage up to 2029; training capacity is the bottleneck |
| 17 | Klaar maar niet af | Connections · administratie | Inventory | Close-out is batched monthly and EAN registration is manual, so customers cannot get an energy contract | Close-out at job completion; one-piece flow; checklist | less-known |
| 18 | KPI's die elkaar bevechten | All streams · management | Overproduction | Each department is measured on its own output (orders started), not on end-to-end lead time | End-to-end KPI; Obeya; WIP limits | less-known; the classic silo trap |

## Countermeasures

Countermeasures come in four maturity tiers. A tool above the region's current maturity only half-works: the lesson is to build the foundation first. Each costs budget and team hours, and some need people's buy-in (trust) before they stick.

| Tier | Theme | Countermeasures in a grid-operator setting |
| --- | --- | --- |
| 1 · Stabiel | Make work visible and standard | Standard work for standard jobs; checklists at handovers; 5S of vans and warehouse; standard van stock; readiness checks; dagstart with a visual board; simple data on a wall |
| 2 · Zichtbaar | Make problems visible fast | Andon for field crews (stop and call); daily management system; tiered escalation; proactive customer status updates; failure-demand measurement; skills matrix |
| 3 · Flow | Make work flow end to end | Triage and fast lanes; WIP limits per team; frozen planning window and reserved outage capacity; heijunka; permits in parallel; revision at the source; two-bin kanban; standard designs; framework contracts |
| 4 · Systeem | Improve the system with data | Smart-meter and sensor data for the LS grid; Pareto and root-cause analysis of repeat faults; flexible contracts and capacity reclaim; Obeya and end-to-end KPIs; hoshin kanri for the region |

Diagnostic tools (5 Whys, fishbone, value stream mapping, spaghetti diagram, Pareto) are not countermeasures. They are how you use the gemba tools, and the game teaches them in context.

## Progression

You grow from gemba walker to strategist, the way a CI lead does on a real assignment.

- **Region maturity (tier 1–4)** rises as problems are solved and standardised. Higher maturity makes higher-tier countermeasures fully effective.
- **Your belt** (white → yellow → green → black → master black belt) rises with XP from PDCA scores. Belts unlock tools:
  - the Obeya at yellow;
  - flow and planning levers (WIP limits, frozen window, outage reserve) at green;
  - strategic choices at black.
- **Trust** in each department grows when you coach and fades when you blame. Some countermeasures need trust to stick.
- **Regions** unlock as you progress, each with its own character: a rural region with long drive times, a city with no space under the street, an industrial region full of congestion.
- **The strategic layer** (later). Every choice shows its end-to-end effect:
  - apply the prioritisation framework to the queue;
  - choose contract types (firm, non-firm, time-bound);
  - invest in people (trainees, contractors) or materials (strategic stock);
  - set hoshin goals for the region.

## UI flows

The screen stays mostly world: you walk, look and talk. Panels open only for thinking work. Desktop first (Merijn, 2026-10-12).

| Screen | When | What it shows |
| --- | --- | --- |
| HUD | always | date and time, speed, budget, belt, one KPI strip per value stream (backlog, lead time, on time), minimap |
| Dagstart | each morning | yesterday vs norm, events, open experiments, your focus for the day |
| Gemba toolkit | at a desk, room, van or site | live numbers you have measured, the tools, the conversation, your notes |
| A3 | when you choose to | the seven boxes, filled by you from your notebook |
| Check & Act | when an experiment has run | before/after for the step and for the whole stream, prediction vs result, standardise or not, score with explanations |
| Value stream map | from the Obeya or the notebook | each stream end to end; steps you have not measured stay "?"; the constraint lights up once the stream is measured |
| Notebook | any time | problems and their PDCA stage, clues, missions, solved A3s |
| Codex | any time | Lean concepts and sector terms you have met (Dutch) |

## Art direction

Stylised low-poly 3D, warm and readable, like a management game rather than a realistic simulator.
- **Colours:** Voltana's deep blue with a bright green accent (energy transition); safety orange for field work.
- **Characters:** simple and expressive, with role colours: monteurs in orange workwear, office staff in blue, the control room in dark polos.
- **WIP is always readable at a glance:** piles of folders, full whiteboards, queues of vans, a dark street.
- **Grid view:** a toggle that shows cables, stations and their load as a glowing overlay.

## Roadmap

Built in Godot 4 with GDScript from the start (decided 12 Oct 2026): desktop builds for Windows, Mac and Linux, plus a browser build. Every phase ends in a reviewable increment; nothing moves on until the gate is met.

| Phase | What | Gate to move on |
| --- | --- | --- |
| 0 · Design | research, this GDD, architecture note | open questions answered (done 12 Oct 2026) |
| A · Engine | Godot project, headless tests, work-order simulation, problem/A3/PDCA logic | four value streams run headless with realistic KPIs |
| B · Content | 18 problems in Dutch, countermeasures, missions, codex | Merijn has reviewed the content for realism |
| C · World | campus and town in 3D, characters, vans, visible WIP | screenshots approved |
| D · UI | dagstart, gemba toolkit, A3, Check & Act, value stream map | one problem playable end to end |
| E · First playable | one value stream fully playable, builds to download | playtest and tuning list |
| F · Depth | tiers 2–4, more regions, strategic layer, gas grid | — |
| G · IT value streams | SAFe, Agile and DevOps on campus | — |
| H · AI conversations | optional free-text talks with characters, grounded in each problem's facts | — |

## Decisions from the review (2026-10-12)

| Question | Decision |
| --- | --- |
| Names | Voltana Netbeheer, region Zuidmark, town and campus **Nova** |
| Story | narrative arc with side quests and some open-world freedom |
| Budget | improvements cost euros and team hours |
| Regulation | model ACM rules and ISO / NTA 8120 in detail |
| Own cases | none available; content is research-based |
| Session length | 15–40 minutes |
| Devices | desktop first |
| Catalogue | v1 mix approved; keep adding problems per tier throughout development |

## Sources

The figures were taken from search-engine extracts of the pages below, because this environment's network policy blocked opening them directly. Each will be verified against the page itself before it goes into game content.

- [Netbeheer Nederland — Betrouwbaarheid van elektriciteitsnetten, resultaten 2024](https://www.netbeheernederland.nl/sites/default/files/2025-04/03.02._betrouwbaarheid_van_elektriciteitsnetten_in_nederland_-_resultaten_2024.pdf) — outage minutes, interruptions
- [ACM — Aansluiting op elektriciteitsnet en gasnet](https://www.acm.nl/nl/energie/elektriciteit-en-gas/netbeheer/aansluiting-op-elektriciteitsnet-en-gasnet) — connection terms, CBb ruling
- [Rechtspraak — CBb: ACM-besluit aansluittermijnen houdt geen stand (2024)](https://www.rechtspraak.nl/organisatie-en-contact/organisatie/college-van-beroep-voor-het-bedrijfsleven/nieuws/2024/09/-acm-besluit-over-aansluittermijnen-kleinverbruikers-op-het-elektriciteitsnet-houdt-geen-stand)
- [Enexis servicenorm: offertes kleinverbruik binnen 10 werkdagen (TenderNed)](https://www.tenderned.nl/papi/tenderned-rs-tns/v2/publicaties/30204/documenten/283051/content)
- [Netbeheer Nederland — communicatie use cases (aanrijtijd, hersteltermijn)](https://www.netbeheernederland.nl/sites/default/files/2024-03/20240229_-_communicatie_use_cases.pdf)
- [Netbeheer Nederland — NN-CAM 5.0 (NTA 8120 certification scheme)](https://netbeheernederland.nl/sites/default/files/2024-10/nn-cam_versie_5.0.pdf)
- [Solar Magazine — netbeheerders en aannemers werven 5.000 extra technici](https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan)
- [Solar Magazine — Enexis: geen nieuwe knelpunten maar wachtlijsten blijven](https://solarmagazine.nl/nieuws-zonne-energie/i41358/enexis-geen-nieuwe-knelpunten-op-stroomnet-maar-wachtlijsten-blijven)
- [Solar Magazine — 3 keer zo veel klachten over uitvallen omvormers](https://solarmagazine.nl/nieuws-zonne-energie/i34795/3-keer-zo-veel-klachten-over-uitvallen-omvormers-zonnepanelen)
- [Solar Magazine — gestandaardiseerde aanpak verdeelstations Enexis](https://solarmagazine.nl/nieuws-zonne-energie/i43650/gestandaardiseerde-aanpak-verdeelstations-versnelt-uitbreiding-elektriciteitsnet-enexis)
- [Siemens — Siemens Nederland en Enexis slaan de handen ineen](https://press.siemens.com/nl/en/node/123)
- [Solar Magazine — ACM ontwerp-codebesluit ongebruikte transportcapaciteit (GOTORK)](https://solarmagazine.nl/nieuws-zonne-energie/i35667/acm-publiceert-ontwerp-codebesluit-om-ongebruikte-transportcapaciteit-af-te-pakken)
- [ACM-overzicht netcongestiemaatregelen](https://bouwstenen.nl/sites/default/files/uploads/overzicht-netcongestiemaatregelen-acm_0.pdf) — time-bound transport right
- [Omroep Brabant — graafschade zorgt voor miljoenen schade](https://www.omroepbrabant.nl/nieuws/4454940/gaslekken-en-stroomuitval-graafwerkzaamheden-zorgen-voor-miljoenen-schade)
- [Omroep Brabant — verzwaring stroomnet Brabant loopt vertraging op](https://www.omroepbrabant.nl/nieuws/4676647/Verzwaring-van-het-stroomnet-in-Brabant-loopt-ernstige-vertraging-op) — transformer lead times
- [Solar Magazine — stikstofregels bedreigen uitbreiding stroomnet Gelderland](https://solarmagazine.nl/nieuws-zonne-energie/i40627/stikstofregels-bedreigen-uitbreiding-stroomnet-gelderland-liander-vraagt-uitzonderingspositie)
- [Solar Magazine — nog 500.000 oude meters moeten vervangen](https://solarmagazine.nl/nieuws-zonne-energie/i42697/einde-salderingsregeling-nog-500-000-oude-meters-moeten-verplicht-vervangen-last-onder-dwangsom-bij-weigering)
- [Gaslicht — slimme meter](https://www.gaslicht.com/energie-informatie/slimme-meter) — GPRS meter replacement 2024–2029
- [DutchNews — marijuana growers steal one billion kWh a year](https://dutchnews.nl/2019/03/marijuana-growers-are-stealing-one-billion-kilowatts-of-electricity-a-year)
