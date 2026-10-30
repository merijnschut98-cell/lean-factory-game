# Mission audit, rewrites, hidden rewards and engagement — design

> Status: written by the mission auditor (Claude, 2026-10-15), for Merijn to review. **Docs only.** Nothing in `content/` or `game/` changes here: the rewrites below become content in a later pass, after Merijn's calls in §8.
>
> Inputs I read: `CLAUDE.md` §2, including "The mission system decides the game" with its 7 criteria; `docs/superpowers/specs/2026-10-15-mission-system-and-catalogue-design.md` (the "catalogue doc"); `content/missions.yaml`, `problems_tier1.yaml`, `countermeasures.yaml`, `concepts.yaml`, `value_streams.yaml`; `docs/GDD.md`; `docs/energy-notes.md`; the training-arc spec; `game/src/rules/region.gd`, `investigation.gd` and `pdca.gd`, to see which signals the rules can detect.
>
> Builds on the catalogue doc and does not replace it. Mission ids, goal types, cast ids and acts are kept. This doc adds faces, hooks, Dutch text, Lean corrections, a hidden-reward system and engagement rules.

## 0. Summary

**Audit.** The 27 existing missions (5 training days and the 22 tier-1 missions) average **21/35**.

- **What works.**
  - The problems themselves are strong: real, well sourced, with good red herrings and clue chains.
  - The coach's question bank is good Kata.
  - `fix_silo_kpis`, `fix_inverters_tripping` and `fix_unused_capacity` are already near the bar.
- **What does not work.**
  - The *missions around* the problems are thin:
    - briefings are one or two faceless sentences;
    - debriefs state the lesson as a slogan before the player has seen it in the numbers;
    - there is almost no ticking clock;
    - customers never appear;
    - a few texts give the answer away.

**The five weakest:**

| Mission | Score | Why |
|---|---|---|
| `walk_connections` | 15 | Completes without the player doing anything. |
| `walk_meters` | 15 | A walk with no question to answer. |
| `fix_revision_backlog` | 17 | No face. The briefing tells the consequence. The KPI is wrong. |
| `fix_permits_in_batches` | 16 | Teaches a *wrong* lesson: "not the constraint, so no gain" for a wait that really shortens lead time. |
| `fix_incomplete_application` | 19 | The title "Het knelpunt verschuift" and the briefing pre-solve the fork. |

**Six Lean corrections that matter most** (§2.2):

1. **Throughput is not lead time.** A non-bottleneck fix adds no throughput, but removing a wait or a rework loop anywhere on the path shortens lead time. Today the Check and the debriefs blur the two.
2. **The fork's text spoils the fork.**
3. **Training Wednesday counts orders, not days of work.**
4. **The revision backlog's KPI should be `wip_age`.**
5. **"Oliedrukkabel" is a high-voltage cable.** An LS/MS monteur meets *GPLK* (papierloodkabel).
6. **Henk's knowledge transfer needs TWI Job Instruction.** Videos alone are documentation, not skill.

**Deep thinking (Merijn's new directive, CLAUDE.md §2).** Every mission is also audited against three principles: long term over short term, respect for people first, and always improve (§2.4).
- **The design passes; the rewards don't yet.** The mission designs mostly pass. The **reward economics do not**: today the short-term choice pays more.
- **The worst case:** a cheap, fading countermeasure saves €4,500–6,500 at once and costs only one score point. Standardising costs €3,000 and earns back about €640–960.
- **Six reward flags (R1–R6), with fixes:**
  - mission rewards scaled by the score;
  - a lifecycle cost shown in the A3;
  - a *borgingsdividend* for fixes that hold;
  - a trust cost for overloading a team;
  - a trust cost for blaming an outside partner;
  - Henk's deadline counted when the respectful fix is in place.

**Hidden rewards ("Ontdekkingen").**
- 25 rewards, each with a trigger the rules can detect. They surface as a quiet toast and fill a physical display cabinet in the CI lead's office.
- The principle check dropped three earlier candidates.
- Five rewards are new and reward deep thinking: going the extra why, choosing the patient fix, developing a person rather than replacing them, nobody burned out, and containing safety first.
- Every reward that rewards speed or thrift also checks quality.
- The five best:
  - **Het knelpunt eerst** and **Leren van de Check**, a pair: each fork branch earns something different;
  - **Terug naar de gemba**, which rewards the PDCA arrow back after a failed Check;
  - **De lange adem**, for the durable fix chosen over a cheaper quick win, still holding after 180 days;
  - **Ontwikkelen, niet vervangen**;
  - **Het dossier van de familie El Amrani**.

**Coach audit (§3A).**
- **The repetition has one cause.** The question index restarts for every mission, so 14 missions open with the same line (QA findings 20 and 24).
- **The fix:** rotate the questions across missions, give each mission its own questions first, and keep a 6-line no-repeat memory.
- **Gaps filled:** all 22 missing stage insights (and every other stage) get a Kata question, with deep-thinking variants.

**Top engagement changes:**
1. **One followed customer dossier across Act 0–I** (the El Amrani family). It makes lead time personal, and its delivery date is computed by the simulation.
2. **A face, a stake and a verifiable number in every briefing.** Debriefs read the player's own numbers and end on a question.
3. **Nine mission shapes, with a target mix per act.** No two adjacent main missions share a shape.
4. **Recurring characters with arcs** that feed path dependence. Example: Henk's buddy Ahmed becomes the trainer in Act IV.
5. **A cliffhanger beat at every act break.**
6. **The "four ones" rule for side missions:** one person, one place, one twist, one object.

---

## 1. Rubric

Each mission gets 1–5 per criterion of CLAUDE.md §2 ("The mission system decides the game"):

| # | Criterion | 1 | 3 | 5 |
|---|---|---|---|---|
| 1 | **Real**: real problem, real fix | invented or generic | real, but sector-neutral | a named sector problem with sourced numbers and a real-world fix |
| 2 | **Entertaining** | an instruction | a situation | a scene: a person, a stake, a moment you remember |
| 3 | **Intriguing** | nothing to wonder about | a question | a mystery that unfolds clue by clue, with a turn |
| 4 | **Challenging** | done by following the text | needs the right tool in the right place | needs judgement: herrings, prioritising, trade-offs |
| 5 | **Draws in**: engrossing, wants the next step | no pull | some curiosity | a ticking clock, a callback, a cliffhanger, a person you care about |
| 6 | **Intuitive** | unclear what to do | clear goal, unclear how | clear goal, a clear first move, no hand-holding |
| 7 | **Correct**: Lean method and numbers | wrong lesson or number | right, but naive | right method, right number, the nuance a practitioner would add |

Scores are judged on today's text in `content/missions.yaml` plus its problem in `problems_tier1.yaml`, played the way the rules allow today.

### 1.1 Scoreboard

| Mission | Kind | Real | Fun | Intrigue | Challenge | Draws in | Intuitive | Correct | **Total** |
|---|---|---|---|---|---|---|---|---|---|
| `training_mon` | T | 3 | 1 | 1 | 1 | 2 | 4 | 4 | **16** |
| `training_tue` | T | 3 | 2 | 2 | 1 | 2 | 4 | 4 | **18** |
| `training_wed` | T | 4 | 2 | 3 | 2 | 3 | 4 | 3 | **21** |
| `training_thu` | T | 3 | 3 | 3 | 3 | 3 | 3 | 4 | **22** |
| `training_fri` | T | 4 | 3 | 3 | 2 | 3 | 3 | 5 | **23** |
| `walk_connections` | M | 3 | 1 | 1 | 1 | 1 | 4 | 4 | **15** |
| `fix_custom_design` | M | 5 | 3 | 3 | 3 | 3 | 4 | 4 | **25** |
| `fix_incomplete_application` | M (fork B) | 4 | 2 | 2 | 2 | 2 | 4 | 3 | **19** |
| `fix_installer_not_ready` | M (fork N) | 4 | 3 | 3 | 3 | 3 | 3 | 3 | **22** |
| `fix_status_callers` | M | 5 | 3 | 3 | 3 | 3 | 4 | 4 | **25** |
| `fix_done_but_not_closed` | M | 4 | 2 | 4 | 3 | 2 | 3 | 4 | **22** |
| `fix_revision_backlog` | M | 4 | 1 | 2 | 3 | 1 | 3 | 3 | **17** |
| `fix_digging_damage` | M | 5 | 3 | 3 | 3 | 3 | 4 | 4 | **25** |
| `fix_grid_study_queue` | M | 5 | 2 | 3 | 3 | 2 | 3 | 4 | **22** |
| `fix_transformer_wait` | M | 5 | 2 | 3 | 3 | 2 | 3 | 4 | **22** |
| `fix_unused_capacity` | M | 5 | 3 | 4 | 4 | 3 | 3 | 4 | **26** |
| `fix_silo_kpis` | M | 4 | 3 | 4 | 4 | 3 | 3 | 5 | **26** |
| `walk_outages` | S | 3 | 2 | 1 | 1 | 2 | 4 | 4 | **17** |
| `walk_meters` | S | 3 | 1 | 1 | 1 | 1 | 4 | 4 | **15** |
| `fix_wrong_joint` | S | 4 | 3 | 3 | 2 | 2 | 4 | 3 | **21** |
| `fix_not_at_home` | S | 4 | 2 | 2 | 2 | 2 | 4 | 4 | **20** |
| `fix_silent_meter` | S | 3 | 2 | 3 | 2 | 2 | 4 | 3 | **19** |
| `fix_permits_in_batches` | S | 4 | 1 | 2 | 3 | 1 | 3 | 2 | **16** → see note |
| `look_at_grid_study` | S | 3 | 2 | 4 | 2 | 3 | 3 | 3 | **20** |
| `fix_inverters_tripping` | S | 5 | 4 | 4 | 3 | 3 | 4 | 4 | **27** |
| `save_henks_knowledge` | S (deadline) | 5 | 3 | 3 | 3 | 4 | 3 | 3 | **24** |
| `fix_planning_reshuffle` | S | 5 | 2 | 3 | 3 | 2 | 3 | 4 | **22** |

Note on `fix_permits_in_batches`: its Correct score is 2, not 4, because of correction L1. The scoreboard keeps the row total at 16, which makes it, with `training_mon`, the joint third-weakest. The summary counts it among the five weakest because of the wrong lesson, not the total.

**Patterns** (they explain most of the low scores):

| # | Pattern | Missions | Fix |
|---|---|---|---|
| P1 | **No face.** "De teamleider", "de monteurs", "de manager": nobody has a name, and no customer appears. | 22 of 27 | Every briefing names a person with a stake (§5.3 cast); every main mission shows a customer in at least one line. |
| P2 | **The debrief is a slogan** ("Faalvraag los je op bij de bron"). It explains instead of showing, and ignores what the player did. | all | The debrief reads the player's numbers (`{placeholders}` from the Check) and ends on a question or a callback. A variant for a poor fix and one for not standardised (§5.7). |
| P3 | **No clock.** Only Henk has a deadline; nothing else ticks. | 26 of 27 | A soft clock in most mains, as a **beat** (the MT decides about vacancies on day 21; the developer hands over keys in five months). Hard deadlines stay rare (§5.6). |
| P4 | **The text gives the answer.** "Het knelpunt verschuift", "Nu staat het werk bij de intake", "Vergelijk ... woningaansluiting met een bedrijfsaansluiting" (coach). | fork, custom_design, revision | Briefings name the *symptom* with a number. Coach insights ask about the actual condition and the obstacles, never about the cause. |
| P5 | **Walks without a question.** | walk_* (3) | Each walk carries one question the player answers by looking: "how many doors open?", "where did the time go?". |
| P6 | **Sides are not small.** `fix_planning_reshuffle` has three effects and five clues. | planning, permits | Side clue trees of at most 4 clues; or promote to main (§8 Q4). |

---

## 2. Lean and sector correctness

### 2.1 What is right (keep)

- Quality at the source versus inspection: poka-yoke 1.0 versus checklist 0.7.
- Failure demand (Seddon).
- Batching: monthly close-out.
- Standardisation as the most proven lever in the sector: Enexis' standard substations.
- Ordering in parallel instead of in series (transformers).
- Goodhart and silo KPIs.
- 100%-loaded planning.
- 253 V and inverters.
- GOTORK.
- The Kata questions in `coach.stages`.
- The Check judging, not the text.

### 2.2 Corrections

| # | Where | What is wrong or naive | Correct version | Change (content or code) |
|---|---|---|---|---|
| **L1** | `Region.check` (`not_constraint`), fork debriefs, `fix_permits_in_batches`, catalogue doc §3.3 ("Check says not the constraint"). **Confirmed by QA finding 21:** 102 misleading "not the bottleneck" warnings on wait-step problems (permits ×47, close-out ×43). | `not_constraint` compares **capacity**. That is right for *throughput*: a non-bottleneck fix adds no output (Goldratt). But a wait, batch or rework loop removed **anywhere on the path** shortens **lead time** for every order that went through it (Little's law: WIP = throughput × lead time). The game now risks teaching that a permit batch "brings nothing". | Two separate statements in the Check and the debrief: "**Er gaan niet meer aansluitingen per week door**" (capacity unchanged) and "**maar wie erdoor kwam, is {n} dagen eerder klaar**" (lead time). The fork's lesson stays true for **throughput**. A non-bottleneck fix can still save money (operating expense) and lead time. It cannot buy more output. | **Code:** Check result gains `lead_time_gain`. `not_constraint` stays capacity-only, and the UI text shows both. **Content:** the fork honesty test (catalogue C15) uses throughput for throughput forks. Permits is reframed as a lead-time and waiting lesson, not a "no gain" lesson. |
| **L2** | `fix_incomplete_application` name and briefing; `fix_installer_not_ready` briefing | The B branch is titled "Het knelpunt verschuift", and its briefing says "Nu staat het werk bij de intake". The N branch says "de teamleider intake zegt dat bij haar de stapel groeit". The fork is decided by the text. | Symmetric briefings: two team leads, each with a true number. Neither names a queue. The player has to count. | Content: rename B to "De onvolledige aanvraag". New briefings in §3. |
| **L3** | `training_wed` | "Tel de wachtrij ... Waar wacht het werk het langst?" Counting orders confuses *number* with *work*: 20 dossiers of a quarter of an hour are less work than 10 of four hours. The constraint is where the most **days of work** wait (`queue_at` already returns `days`). | Teach "dagen werk in de wachtrij" next to the count. | Content: briefing and debrief. UI: the queue_count result shows both. |
| **L4** | `fix_custom_design` teaches `standard_work` | A standard *design* is product standardisation. Lean standard work is the *method*: the sequence, the time and the WIP of the person doing it. Close, but conflated. | Teach both: a standard design (what), plus standard work for the designer (the sequence and the one check that replaces three signatures). | Content: the concept text of `standard_work` and the debrief. No mechanic changes. |
| **L5** | `revision_backlog` `kpi: throughput` | Revision sits after commissioning. The customer is already connected, so the stream's throughput doesn't move. The harm is the **age of the backlog**: unmapped cables. | `kpi: wip_age`. The A3 waste "inventory" is right, and the root cause names the double work (overprocessing). | Content: the KPI. Consider a secondary waste in the A3 (code, later). |
| **L6** | `knowledge_drain` clue: "een oliedrukkabel" | Oil-pressure cables are high-voltage (50–150 kV: TenneT and the regional HV grid), not the LS/MS work of a DSO monteur. | "een oude **papierloodkabel (GPLK)**": the paper-insulated lead-sheathed cable of pre-1970s LS/MS grids. | Content: the clue text. |
| **L7** | `silent_meter`: "Drie op de tien nieuwe meters" | 30% silent is not plausible as a region-wide rate. In practice, communication problems cluster where coverage is poor (concrete basement meter rooms, rural edges). | Localise it: "Drie op de tien meters in kelderbergingen van nieuwe flats zwijgen; elders één op de twintig". Mark it as an estimate with that reasoning. | Content: clue texts, plus `estimate:` in the YAML comment. |
| **L8** | `inverters_tripping` countermeasure `tap_review_per_neighbourhood` | Lowering the tap of a distribution transformer lowers the voltage all year. On a winter evening with heat pumps and EVs a street can fall below **207 V** (EN 50160: 230 V ±10%). A tap set from a summer measuring week alone is naive. | The debrief and the countermeasure text say "op basis van zomer- én wintermeting". A later echo: "De koude straat" (tier 2, idea in §6.4) for a poor fix. | Content: countermeasure description and debrief. Idea for the problem backlog. |
| **L9** | `transformer_wait` → `early_transformer_order` | Ordering before the design is approved carries a risk: the wrong size. Practitioners reduce it with a few standard transformer sizes. Without that, the game makes the countermeasure look free. | Coach experiment question about that risk. The countermeasure description names standard sizes. | Content. |
| **L10** | `knowledge_drain` countermeasures | Videos and work instructions are documentation. Lean transfers skill with **TWI Job Instruction** (prepare, present, try out, follow up) and practice under a master. The buddy system is close to this; the videos at 0.8 are generous. | Add `twi_job_instruction` (tier 1, fit 0.9, "Henk leert Ahmed het vak in vier stappen"). Lower the videos to 0.7. | Content: a new countermeasure (it can't hit Henk's deadline door because of `fail_closes`). |
| **L11** | waste class of people's travel | TIMWOODS in services: moving *material and information* is transport; moving *people* is motion. Field-service practice usually books a wasted trip to a job as transport. The game uses transport for wrong_joint and not_at_home but never says why. | Write the convention into the concepts: "In de buitendienst rekenen we een rit voor niets tot transport". The A3 stays single-waste. | Content: `waste_transport`, `waste_motion` texts. |
| **L12** | `fix_grid_study_queue` | Two nuances are missing. (a) The congestion queue is for **grootverbruik** (> 3x80A); a kleinverbruik request gets an LS capacity check, not a queue place. (b) TOC's order is *exploit before elevate*: get the most from the scarce analysts (triage) before hiring. | The briefing distinguishes the two. The debrief names the five focusing steps implicitly ("je hebt het knelpunt eerst beter benut voordat je het groter maakte"). | Content: briefing, debrief, concept `theory_of_constraints` (add the five steps). |
| **L13** | Coach insights that point at the cause | `fix_custom_design.understand` ("Vergelijk ... woningaansluiting met een bedrijfsaansluiting") and `fix_unused_capacity.go_see` ("niet naar wat er gecontracteerd is") are hints, not Kata questions. | Kata coaching asks about the target, the actual condition, obstacles, the next step and learning. It does not point at the answer. Rewrites in §3. | Content. |
| **L14** | `look_at_grid_study` | Gap 1 of the catalogue doc: the problem stays open with no mission holding it. That breaks "problems only through missions". | Fix as catalogue C0. | Code (already planned). |
| **L15** | `fix_planning_reshuffle` (Kingman) | Correct, but the insight is the classic one and goes unsaid: wait time explodes as utilisation nears 100% under variability (Kingman). That is the lesson a practitioner adds. | The debrief and the `capacity_planning` concept name it, without a formula. | Content. |

### 2.3 Grounding table (numbers used in the rewrites)

| Number in text | Source or estimate |
|---|---|
| Compensation **€35** for an outage of 4–8 h on a small connection (≤ 3x25A), **+€20** per 4 h after | ACM, "Vergoeding stroomstoring en gasstoring" (acm.nl/nl/node/24620). *Verify the current amounts before release.* |
| Inverters switch off above **253 V**; the band is 230 V **±10%** (207–253 V) | EN 50160 (voltage characteristics); Solar Magazine (complaints tripled), already in `concepts`/`problems` |
| **7%** of digs in Brabant hit a cable | Omroep Brabant (in GDD) |
| **46,799** digging damages, **€38.8M** (2022) | Wibon evaluation (in `problems_tier1.yaml`) |
| The digger is expected to dig a **test trench** where the position is uncertain | CROW 500 *Richtlijn zorgvuldig graafproces*. Its weight is confirmed in HR 13 April 2018 (ECLI:NL:HR:2018:772) and described by KWR (H2O 2008). *Verify the edition.* |
| **~28,000** technicians short up to 2029; training capacity is the bottleneck | Netbeheer Nederland, via Solar Magazine (energy-notes) |
| **15,000+** requests in the congestion queue | LAN / Netbeheer Nederland (energy-notes) |
| Enexis: substations from **~10 to ~100 a year** through one standard design | Solar Magazine, Siemens (energy-notes) |
| Stedin: transformer-station lead time **9 → 3 months** | IO+ (energy-notes) |
| The last **~500,000 analogue meters** replaced 2026–2027 (Energiewet) | Solar Magazine (energy-notes) |
| **2.5 million** GPRS meters replaced 2024–2029 (2G/3G sunset) | Gaslicht (energy-notes) |
| **18 weeks** as the reference connection term (the CBb annulled the decision in 2024) | Rechtspraak, ACM (concepts) |
| **27 March 2015, Diemen:** about 1 million households without power for up to ~5.5 h; a switch drive motor failure plus a test error | ACM publication "Onderzoek ACM naar stroomstoring Diemen afgerond"; Kamerstuk 29023-185/209 |
| Failure demand is often more than half of service-centre demand | Seddon, *Freedom from Command and Control* (2003): case figures, *estimate band* |
| Kingman: waiting grows steeply as utilisation nears 100% | Hopp & Spearman, *Factory Physics*: textbook |
| TWI Job Instruction, four steps | TWI (War Manpower Commission, 1940s): public-domain manuals |
| Toyota Kata: five questions | Rother, *Toyota Kata* (2009); the Kata card is published by the author |
| Goodhart's law | Goodhart (1975); Strathern's phrasing (1997) |
| Monteur's cost **€75/h** (fully loaded) | **Estimate:** a CAO wage of roughly €25–30/h, × ~2 for overhead, van and tools. Used only for `cost_per_week` of wasted trips. |
| Contracted vs used **62%** | **Estimate** already in content. Keep marked; Netbeheer Nederland reports that large consumers use only part of their contracted capacity (verify a figure). |

### 2.4 The three deep-thinking principles (Merijn, 2026-10-15)

CLAUDE.md §2: problem solving under three principles, and the rewards must follow them.
1. **Long term outweighs short term in 95% of cases.** The rare exception must be real, e.g. a safety risk that needs containment now.
2. **Respect for people comes first.** Trust and reputation measure it.
3. **Always improve.**

#### 2.4.1 Reward flags: where today's rules pay the short-term or disrespectful choice more

Numbers come from `pdca.gd` (`BUDGET_BASE`, `score`, `xp_for`), `region.gd` (`STANDARDISE_BUDGET` 3,000) and `countermeasures.yaml`.

| # | Flag | Evidence (today) | Fix (proposal) |
|---|---|---|---|
| **R1** | **The quick, fading fix pays more now.** | Fit 0.7 against 1.0 lowers effectiveness only from about 0.9 to 0.56: the countermeasure score drops one point (5 → 4), ≈ −10 × tier XP and −€320/−€480 budget. Meanwhile `intake_checklist` costs €1,000 (decays in 30 days) against `poka_yoke_application` €6,000 (durable). `delegated_approval` €1,500 (30 d) against `standard_designs` €8,000 (60 d). The quick fix nets ≈ **€4,500–6,500 more today**. The cost comes later, as a reopened mission that pays no XP the second time, and the player rarely connects the two. | (a) **Show a lifecycle cost in the A3**: "kosten over een jaar ≈ budget + herstel × (365 / decay_days)" (an estimate, labelled as one). (b) **Mission rewards scale with the score** (catalogue gap 6): `reward × total / 25`. (c) Add a **durability** term to the countermeasure score: +1 for `decay_days: null` or for standardised, so durable fixes reach 5 more easily. |
| **R2** | **Standardising loses money in the short run.** | Standardising costs €3,000 and earns check_act +2: about +€960 (high severity) or +€640 (medium) and +20 × tier XP. That is net −€2,000 to −€2,400 at the moment of choice. The Friday training time-lapse teaches the opposite of what the budget says. | A **borgingsdividend**: a fix that still holds (health ≥ 0.9) pays €1,500 at 90 days and €1,500 at 180 days, plus reputation +2 at 180 days (estimates). Standardising then pays back, visibly, over time: long term beats short term in the numbers, not only in the text. |
| **R3** | **Overloading a team costs nothing.** | `team_hours` lower a pool's availability during the experiment. Running a heavy countermeasure at a team already above ~95% load, or at the constraint, has no people cost; the only price is flow. The story says Anouk works until seven, but the simulation does not care. | **Overload signal:** a pool above 95% utilisation for 14 days *while an experiment of the player's draws on it* loses trust −1 ("overbelast"), and the coach asks about it (§3A). Burning people out costs trust; spreading the work (another time, a smaller step) avoids it. |
| **R4** | **Blaming an outside party is free.** | `ask(...)` only costs trust with the *team at the place*. Blaming Gert (a contractor) or a customer costs nothing. | Persons in `people.yaml` carry their own trust. Blaming any person costs that person's trust and reputation −1 (catalogue §2.7 already plans −1 per blaming question). |
| **R5** | **The respectful fix is the risky one under a deadline.** | QA finding 19: Henk's deadline counts only once the problem is *solved*, so a 14-day Check that ends after the date fails the mission. `skills_matrix_buddy` (80 monteur hours, the respectful and effective fix) is slower to land than the videos (40 hours). | Adopt the QA fix: **the deadline is met once the A3 is submitted with the countermeasure in place.** The Check still judges, and the door closes only if nothing was started. |
| **R6** | **Reputation does not reward sustaining.** | The catalogue doc's reputation deltas: +5 per main mission, +3 per good Check, +2 per reopened mission done. Nothing is paid for a fix that *holds*. | Reputation +2 when a fix passes 180 days held (the same trigger as R2), and the hidden reward D7 at 365 days. |

**The real exception (short term first):**
- In **safety** missions, containment now is right: the MS cable strike (digging damage), the LMRA tick-box (Act III) and the heatwave.
- Proposal: a `containment` action for missions flagged `safety: true`. It is a short, cheap measure, such as a stop-and-call on digs near MS cables, taken at the start.
- Containment isn't scored as the fix, does not end the mission, and is rewarded (hidden reward D28) only when the root-cause fix follows.
- Containment *without* the root-cause fix fades in 14 days (an estimate).

#### 2.4.2 Per-mission check

✓ follows the principle · ⚠ a risk to fix (see the note) · — not applicable

| Mission | Long term | Respect for people | Always improve | Note |
|---|---|---|---|---|
| `training_mon`–`wed` | — | ✓ "oordeel nog niet", a customer's face | — | — |
| `training_thu` | ✓ | ✓ the mismatch note: "niet de mensen" | ✓ | — |
| `training_fri` | ✓ the central lesson | ✓ | ✓ | ⚠ **R2**: the budget contradicts the lesson. |
| `walk_connections` | — | ✓ follow a customer | — | — |
| `fix_custom_design` | ⚠ | ✓ no hiring; Anouk's overtime ends | ✓ | **R1**: `delegated_approval` (€1.5k, 30 d) against `standard_designs` (€8k, 60 d). The debrief's `poor_fix` variant shows the slow fade. The story's overtime should become an **R3** signal. |
| fork B `incomplete_application` | ⚠ | ✓ Sanne is not blamed | ✓ | **R1**: the checklist (an inspection; 30 d) against poka-yoke. The new reflect question asks what a checker leaves after a year (§3A). |
| fork N `installer_not_ready` | ⚠ | ✓ scarce monteur hours respected | ✓ | **R1**: the readiness call (45 d) against photo upload (durable). |
| `fix_status_callers` | ⚠ | ✓ no extra agents; agents freed | ✓ | **R1**: `realistic_promise` (60 d) against `proactive_status_updates` (durable). The reflect asks what Esra's team does with its freed time (developing people, not cutting them). |
| `fix_done_but_not_closed` | ✓ | ✓ Petra | ✓ | The durable option (automatic EAN, tier 3, €25k) is a legitimate long-term investment, not a trap. |
| `fix_revision_backlog` | ✓ | ✓ (the monteur's sketch is a process gap, not sloppiness; keep the tone) | ✓ | The text must not mock "op de motorkap". |
| `fix_digging_damage` | ⚠ **exception** | ⚠ **R4** (blaming Gert is free) | ✓ | Containment is legitimate (safety). Proposal: the `containment` action plus D28. `contractor_briefing` (30 d) is the quick win. |
| `fix_grid_study_queue` | ✓ exploit before elevate | ✓ "lange dagen": an **R3** candidate | ✓ | The reflect asks when hiring *is* right. |
| `fix_transformer_wait` | ✓ | — | ✓ | The strategic stock (€40k) is the long-term option, read by `t4_investment_plan`. |
| `fix_unused_capacity` | ✓ | ✓ (customers get a conversation, not a confiscation) | ✓ | The reflect asks how the customers giving capacity back were treated. |
| `fix_silo_kpis` | ✓ | ✓ exemplary: "mensen doen wat hun cijfers vragen" | ✓ | — |
| `walk_outages`, `walk_meters` | — | ✓ ride along | — | — |
| `fix_wrong_joint` | ⚠ | ✓ "allebei gelijk" | ✓ | **R1**: the standard list (45 d) against two-bin (durable, tier 3). |
| `fix_not_at_home` | ✓ | ✓ customers not blamed | ✓ | — |
| `fix_silent_meter` | ⚠ | ✓ (the monteur's "tien minuten langer" is a process incentive; keep the tone) | ✓ | The on-site test (45 d) against the coverage check (durable). |
| `fix_permits_in_batches` | ✓ | ✓ the gemeente is not blamed | ✓ | L1. |
| `look_at_grid_study` | — | ✓ | — | — |
| `fix_inverters_tripping` | ⚠ L8 | ✓ Wim, a customer as expert | ✓ | A tap change without winter data is the quick fix. |
| `save_henks_knowledge` | ✓ | ✓✓ the core | ✓ | ⚠ **R5**: the deadline mechanics favour the less respectful fix. Add `twi_job_instruction` (L10). |
| `fix_planning_reshuffle` | ✓ | ✓ Linda's overload is the stake: an **R3** candidate | ✓ | — |

---

## 3. Audit and rewrite per mission

Format per mission: the score table (one line of evidence per criterion), then the rewrite: hook, briefing (NL), debrief (NL, with outcome variants where useful), coach insights (NL, Ruud Hoekstra, Kata-style, main and training only), twist / red herring, the *aha*, grounding, Lean check, content changes.

`{curly}` placeholders are filled from the Check or the simulation, to be built with the templated coach (catalogue C16). Persons marked † are new to the cast (§5.3). **The coach lines in §3A are the canonical set.** Where a §3 line differs, §3A wins.

### 3.0 The thread through Act 0–I: the El Amrani dossier

One customer dossier runs through the training week and Act I as a **followed order**:
- The El Amrani family in Nova-Oost asked for a 3x25A connection for their new heat pump.
- Their dossier is a real work order in the simulation, tagged at birth (`story: el_amrani`, a code need).
- It travels the connections stream like any other order. The player meets it:
  - in Anouk's tray (Thursday's practice problem);
  - in the status calls (Mrs El Amrani rings for the fourth time);
  - at close-out ("uw EAN bestaat niet").
- Its delivery day is **computed, not scripted**. Delivered within 126 days (18 weeks), it earns the hidden reward D14; later, it earns a kinder card.

This teaches lead time the way a customer feels it, and it ties together missions that are otherwise separate.

---

### T1 · `training_mon` — Rondleiding

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | Real places and terms (netbeheerder, aansluittermijn), but no situation. |
| Entertaining | 1 | "Kijk rond." |
| Intriguing | 1 | Nothing to wonder about. |
| Challenging | 1 | Two visits. Fine for day 1, but no thought needed. |
| Draws in | 2 | Only the promise of "morgen". |
| Intuitive | 4 | Clear: two places, the map key named. |
| Correct | 4 | The gemba-first framing is right. |

**Rewrite**
- **Hook:** a letter on the doormat. The El Amrani family has waited eleven weeks; the reference is 18. The first thing the player hears about Voltana is a customer, not a process.
- **Briefing:** "Welkom bij Voltana Netbeheer. Ik ben Ruud Hoekstra. Deze week oefen je in het klein; als er iets misgaat, raakt niemand iets kwijt. Vanochtend lag er een brief op mijn bureau van de familie El Amrani uit Nova-Oost. Ze wachten al elf weken op een aansluiting voor hun warmtepomp. Zoek met de kaart (M) de Intake en Werkvoorbereiding op en vraag bij elk team hoe het werk binnenkomt. Als je hun dossier ziet: onthoud waar het ligt."
- **Debrief:** "Je kent nu twee plekken waar een aanvraag langskomt. Elf weken onderweg, en hoeveel uur is er al aan gewerkt? Morgen ga je beter kijken."
- **Coach:** go_see: "Een aanvraag doet er maanden over. Hoeveel van die tijd wordt er echt aan gewerkt, denk je? En hoe zou je dat kunnen zien?"
- **Twist:** none (day 1). The dossier is a seed.
- **Aha:** "Er is een klant achter elk dossier."
- **Grounding:** the 18 weeks (aansluittermijn, concepts).
- **Content changes:** briefing, debrief, insight; a beat `{on: accepted, who: ruud}` with the letter. Code: tag the El Amrani order (§7).

### T2 · `training_tue` — Kijken zonder oordeel

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | Observing before judging is real Lean (gemba). |
| Entertaining | 2 | No person to watch. |
| Intriguing | 2 | No question. |
| Challenging | 1 | Any two tools. |
| Draws in | 2 | — |
| Intuitive | 4 | Clear. |
| Correct | 4 | Right, and it names the tool cost. |

**Rewrite**
- **Hook:** Anouk de Vries† is the only work preparer this week; three colleagues are on a course. She works fast and is drowning.
- **Briefing:** "Bij Werkvoorbereiding zit deze week alleen Anouk de Vries; haar drie collega's zitten op cursus. Ga bij haar kijken met twee verschillende hulpmiddelen. Elk hulpmiddel kost tijd en laat iets anders zien. Oordeel nog niet, ook niet in je hoofd: schrijf op wát je ziet, niet wat je ervan vindt."
- **Debrief:** "Wat liet het ene hulpmiddel zien dat het andere miste? Anouk werkt snel. Toch ligt er veel. Waar zit dan de tijd?"
- **Coach:** go_see: "Wat deed Anouk, en wat deed het werk terwijl zij bezig was?"
- **Twist:** the time study shows Anouk is quick. The pile is not her speed.
- **Aha:** "Mensen druk ≠ werk loopt."
- **Content changes:** texts; Anouk in `people.yaml`.

### T3 · `training_wed` — Waar zit de stapel?

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Bottleneck plus the netcongestie link. |
| Entertaining | 2 | Counting. |
| Intriguing | 3 | "Waar?" is a question. |
| Challenging | 2 | The setup makes the answer obvious. |
| Draws in | 3 | Leads into Thursday. |
| Intuitive | 4 | Clear. |
| Correct | 3 | **L3**: count, not days of work. "Dat is de plek die de hele stroom ophoudt" is stated, not discovered. |

**Rewrite**
- **Briefing:** "Tel vandaag de wachtrij bij Intake en bij Werkvoorbereiding. Let op: twintig dossiers van een kwartier zijn minder werk dan tien dossiers van vier uur. Waar ligt het meeste werk te wachten, in dagen werk? Schrijf het op voordat je het met je gevoel vergelijkt."
- **Debrief:** "Bij Intake lagen {count_intake} dossiers, {days_intake} dagen werk. Bij Anouk {count_design} dossiers, {days_design} dagen werk. Als Intake morgen twee keer zo hard werkt, waar ligt het werk dan overmorgen?"
- **Coach:** go_see: "Welke van de twee getallen vertelt je meer: het aantal dossiers of de dagen werk? Waarom?"
- **Twist:** if the simulation allows it, Intake shows the *longer count* (many short applications), but Werkvoorbereiding holds more days of work. *Check this on the training setup; if the counts already agree, the debrief still teaches days.*
- **Aha:** the constraint is where the most *work* waits, and every other step can only feed it or starve.
- **Grounding:** netcongestie is a bottleneck in copper (concepts).
- **Content changes:** texts. UI: the queue_count result shows count and days (`Region.queue_at` already returns both).

### T4 · `training_thu` — Een klein experiment

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | Two trays: invented but plausible office waste. |
| Entertaining | 3 | A small puzzle. |
| Intriguing | 3 | "Iets kleins gaat mis." |
| Challenging | 3 | A first real A3. |
| Draws in | 3 | The three-day Check. |
| Intuitive | 3 | The briefing is long and explains the setup the player saw yesterday. |
| Correct | 4 | Motion waste, FIFO, a leading indicator. |

**Rewrite**
- **Hook — a mystery:** Anouk always takes the oldest dossier, yet the El Amrani dossier has lain there for nine days.
- **Briefing:** "Anouk pakt altijd het oudste dossier. Toch ligt het dossier van de familie El Amrani al negen dagen bij haar. Hoe kan dat? Zoek het uit, schrijf een oefen-A3 met een voorspelling en probeer een tegenmaatregel. Over drie dagen kijken we samen of je voorspelling uitkwam."
- **Debrief:** "Je voorspelde {prediction}; het werd {result}. Of het tegenviel of meeviel: je weet nu iets wat je gisteren niet wist. Dat is een experiment."
- **Coach:** understand: "Wat doet Anouk voordat het echte werk aan een dossier begint? Hoe lang?" · experiment: "Welk getal laat over drie dagen zien of het werkt, en wat verwacht je dat het dan is?"
- **Twist:** the El Amrani dossier came back with additions and went into the *second* tray (terugkomers), so "het oudste" in the first tray was never the oldest.
- **Aha:** two queues without one order break first-in-first-out, and searching is motion waste.
- **Content changes:**
  - Briefing.
  - The clue at depth 1 (conversation) gets a line: "'... het dossier van El Amrani? Dat zit vast in de andere bak.'"

### T5 · `training_fri` — Borgen of laten wegzakken

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Sustain-or-decay is the real Lean problem. |
| Entertaining | 3 | The time-lapse is a moment. |
| Intriguing | 3 | "Wat gebeurt er als ...?" |
| Challenging | 2 | A binary choice. |
| Draws in | 3 | The week ends; the campaign starts. |
| Intuitive | 3 | Fine. |
| Correct | 5 | The fade shows (with the sustain agent's hold). |

**Rewrite**
- **Hook:** on Monday Anouk's three colleagues come back. Will they know about the one tray?
- **Briefing:** "Je experiment werkt: Anouk zoekt niet meer. Maandag komen haar drie collega's terug van hun cursus. Weten zij van de ene bak? Beslis: borg je het als standaard werk (dat kost budget), of laat je het zo? Kijk daarna een maand vooruit."
- **Debrief (standardised):** "Een maand later pakt iedereen het oudste dossier uit één bak. Het staat op een A4 boven de bak, en Anouk legt het aan nieuwe collega's uit."
- **Debrief (not):** "Een maand later staan er weer twee bakken. Niemand deed iets fout; niemand wist het nog. Een verbetering blijft alleen als iemand haar borgt."
- **Cliffhanger beat (Ruud):** "Mooi werk. Maandag vraagt Joost van Dijk het MT om twee extra werkvoorbereiders. Ik heb gezegd dat jij eerst gaat kijken." It hands out `talk_netplanner` (catalogue doc).
- **Coach:** reflect: "Wat gebeurt er met de nieuwe werkwijze als het team het druk krijgt en niemand erop let? Wie zou erop moeten letten?"
- **Content changes:** the two debrief variants (`debrief_variants.not_standardised`); the beat.

---

### M1 · `walk_connections` — Eerste week: loop de stroom → **"Volg het dossier"**

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | Walking the value stream is real. |
| Entertaining | 1 | Today it completes without the player (story stand-in, catalogue gap 8). |
| Intriguing | 1 | — |
| Challenging | 1 | — |
| Draws in | 1 | — |
| Intuitive | 4 | Clear. |
| Correct | 4 | Gemba first. |

**Rewrite**
- **Hook:** follow the El Amrani dossier through every step, and at the end see the customer journey on the Obeya: weeks of calendar time, hours of work.
- **Briefing:** "Voordat je iets verandert, wil ik dat je de weg van één aansluiting hebt gezien. Volg het dossier van de familie El Amrani: loop mee bij elke stap, van intake tot administratieve afhandeling, ook bij de stappen waar het nog niet is. Tel bij elke stap hoeveel er ligt."
- **Debrief:** "Het dossier van de familie El Amrani is nu {age_days} dagen onderweg. Er is {touch_hours} uur aan gewerkt. De rest van de tijd lag het ergens te wachten. Waar het langst?"
- **Coach:** go_see: "Kijk niet alleen naar de mensen. Kijk naar het werk dat ligt te wachten. Waar zou jij als dossier het liefst niet liggen?"
- **Aha:** the value-added ratio. A few hours of work against weeks of waiting is typical of office processes.
- **Grounding:**
  - The touch hours come from `value_streams.yaml` and the simulation (intake 1.0 h, design 3.2 h, execution 5 h ...).
  - The ratio is computed, not quoted. No external number is needed.
- **Lean check:** right. The value stream map starts here.
- **Content and code changes:** a real `walk` goal once the campus exists (catalogue gap 8). The debrief template needs the followed order's age and touch hours (code §7).

### M2 · `fix_custom_design` — De stapel bij Werkvoorbereiding

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | Standardisation is the sector's most proven lever (Enexis 10 → 100 stations a year). |
| Entertaining | 3 | "De teamleider vraagt om twee extra mensen" is a stake, but faceless. |
| Intriguing | 3 | "Wat is er echt aan de hand" is a question. |
| Challenging | 3 | A good herring (100 dossiers → more people). |
| Draws in | 3 | — |
| Intuitive | 4 | Clear. |
| Correct | 4 | **L4** (standard design vs standard work); the coach hint is **L13**. |

**Rewrite**
- **Hook:**
  - Joost van Dijk asks the MT for two vacancies.
  - Anouk was still drawing at seven in the evening.
  - The MT will decide in three weeks: a *soft* clock, as a beat, not a deadline.
- **Briefing:** "Werkvoorbereiding maakt al zes weken overuren, en toch groeit de stapel: ruim honderd dossiers. Joost van Dijk, de teamleider, vraagt het MT om twee extra werkvoorbereiders. Anouk zat gisteravond om zeven uur nog te tekenen. Over drie weken beslist het MT. Wat is hier echt aan de hand?"
- **Beats:**
  - Day 21, if unresolved: Ruud: "Het MT houdt Joosts vacatures aan tot jouw A3 er ligt. Ze wachten wel, maar niet eeuwig."
  - On accept: Anouk: "Ik teken ze allemaal hetzelfde. Maar het moet langs drie handtekeningen."
- **Debrief:** "Een standaardaansluiting kost nu {design_hours} uur ontwerp in plaats van vijf, en de stapel is {queue_delta} dossiers kleiner. Joost trekt zijn vacatures in, en Anouk is om vier uur thuis. Eén vraag voor je volgende stap: als Werkvoorbereiding nu sneller is, waar gaat het werk dan wachten?"
  - **Variant `poor_fix`** (delegated approval only): "Er zijn minder handtekeningen, maar elk ontwerp wordt nog steeds van nul getekend. De stapel zakt, langzaam."
- **Coach (Ruud):**
  - go_see: "Wat is je doel voor Werkvoorbereiding, in een getal? En hoe ziet het er nu uit?"
  - understand: "Welk deel van wat Anouk doet, merkt de klant? En welk deel niet?"
  - experiment: "Wat verwacht je dat er met de stapel gebeurt: hoeveel, en wanneer kun je het zien?"
  - reflect: "Wie in het team wist het antwoord al voordat jij kwam? Wat zegt dat?"
- **Twist / red herring:**
  - "Meer dan honderd dossiers" pulls the player toward headcount.
  - "De software is verouderd" is plausible.
  - The person who knows the cause is the one doing the work (respect for people).
- **Aha:** a household connection got as much design as a business. The work was made heavy; the people were not slow.
- **Grounding:** Enexis standard substations (Solar Magazine, Siemens). Three approvals and five hours are an estimate (content).
- **Lean check:** add L4 to the debrief: "een vast ontwerp (wat) en een vaste werkwijze voor het tekenen (hoe)".
- **Content changes:** texts, beats, the `poor_fix` variant, the cast (Joost, Anouk).

### M3 · Fork `t1_after_design`: `fix_incomplete_application` (B) vs `fix_installer_not_ready` (N)

Both missions open together under one fork card on the board: "**Twee teams vragen om je aandacht.**" Both briefings are equally loud and both carry true numbers. Neither names where work waits.

#### `fix_incomplete_application` — rename to **De onvolledige aanvraag** (B)

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Incomplete applications and the Enexis 5-day norm are real. |
| Entertaining | 2 | Faceless. |
| Intriguing | 2 | The cause is half-given ("gaat terug naar de klant"). |
| Challenging | 2 | **L2**: the title and briefing decide the fork. |
| Draws in | 2 | — |
| Intuitive | 4 | Clear. |
| Correct | 3 | Poka-yoke is right; the spoiler undermines the fork's lesson. |

- **Hook:** Sanne Bakker keeps a tally: 19 of the last 40 applications went back. "We zijn een postkantoor geworden."
- **Briefing:** "Sanne Bakker, teamleider Intake, heeft een turflijst: van de laatste veertig aanvragen stuurde haar team er negentien terug naar de klant. 'We zijn een postkantoor geworden,' zegt ze. 'Ik heb iemand extra nodig om alles na te lopen.'"
- **Debrief (bottleneck, first):** "Wat binnenkomt is nu compleet: {ftr_intake}% gaat in één keer goed, was {ftr_before}%. Er gaan {throughput_delta} aansluitingen per week meer door. Sanne heeft niemand extra nodig: haar team controleert niet harder, het formulier voorkomt de fout. Waar wacht het werk nu?"
- **Debrief variant `debrief_first: false`** (after the N branch): "Nu zie je het verschil met de monteurs: dit keer gaan er wél meer aansluitingen per week door. Waarom hier wel en daar niet?"
- **Coach:**
  - go_see: "Twee teams vragen om je aandacht. Waar ligt het meeste werk te wachten, in dagen werk? Heb je dat zelf geteld?"
  - understand: "Waar ontstaat de fout: bij Sanne, of al eerder? Hoe weet je dat?"
  - experiment: "Als je voorspelling klopt, welk getal bij de intake verandert, en welk getal aan het eind van de stroom?"
  - reflect: "Wat is het verschil tussen een fout vinden en een fout voorkomen?"
- **Twist:**
  - Sanne asks for an extra checker. That is the inspection trap: `intake_checklist` works, at 0.7.
  - "Klanten lezen de instructies niet" is a plausible cause.
  - Listening in shows the form never asked.
- **Aha:** quality at the source beats inspection, and fixing the constraint moves the whole stream.
- **Grounding:** the Enexis norm of 5 working days to ask for missing details (TenderNed, in GDD).

#### `fix_installer_not_ready` — Meterkast niet gereed (N)

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Wasted trips to unready meter cupboards are a classic. |
| Entertaining | 3 | Two leads arguing is a scene. |
| Intriguing | 3 | "Jij kiest." |
| Challenging | 3 | A real prioritisation, but the text helps. |
| Draws in | 3 | — |
| Intuitive | 3 | "Jij kiest" without saying *how* to choose (fine), but the other briefing gives it away. |
| Correct | 3 | **L1**: the lesson "no gain" is too strong. There is no throughput gain, but monteur hours and lead time for the affected customers are saved. |

- **Hook:** Marco Peters: "Mijn monteurs rijden voor niets: twee op de vijf adressen zijn niet klaar. Dat kost me elke week twintig uur." Monteurs are scarce (the technician shortage); this is the obvious suspect.
- **Briefing:** "Marco Peters, teamleider Monteurs, is er klaar mee: 'Twee op de vijf adressen zijn niet klaar als mijn mensen voor de deur staan. Dat zijn twintig monteursuren per week die we niet hebben.' Hij wil dat dit eerst wordt opgelost. Sanne zegt hetzelfde over haar team. Jij kiest wat eerst gaat."
- **`cost_per_week`:** about **€675**. *Estimate*: ~6 wasted trips a week × 1.5 h (`fail_hours`) × €75/h. It makes the saving visible in euros.
- **Debrief (non-bottleneck, first):** "Er rijdt pas een monteur als de meterkast klaar is. Dat scheelt {hours_saved} monteursuren en €{cost_saved} per week, en de klanten van wie het adres niet klaar was, zijn {lead_delta} dagen eerder aangesloten. Maar kijk naar de stroom: er gaan niet méér aansluitingen per week door. Het werk wacht nog steeds bij {constraint_place}. Bewaar die monteursuren goed; je zult ze nog nodig hebben."
- **Debrief variant (after B):** "Goed dat dit ook is opgelost: minder ritten voor niets, en geld bespaard. Het knelpunt zat al ergens anders."
- **Coach:** go_see: "Twee teams vragen om je aandacht. Waar staat het werk het langst te wachten?" · reflect: "Gaan er nu meer aansluitingen per week door? Wat is er wél beter geworden, en voor wie?"
- **Twist:** the time study shows a monteur's connection work is within norm (a herring that blames nobody).
- **Aha (correct TOC):**
  - A non-bottleneck fix saves money and some lead time, but **not output**.
  - Freed monteur hours are a bank for later. Act IV's technician shortage cashes it: a fact `chose:installer_not_ready:*` could feed the `t3_crew_strategy` options (a call for Merijn, §8).
- **Content changes:** both names and briefings; `cost_per_week`; `debrief_first` variants; the fork card text. Code: L1 (the Check shows lead time as well as capacity).

### M4 · `fix_status_callers` — De telefoon staat roodgloeiend

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | Failure demand from waiting customers (Seddon). |
| Entertaining | 3 | The phone wall is vivid, but no person. |
| Intriguing | 3 | "Waarom bellen al die mensen?" |
| Challenging | 3 | A good herring (agents fast and friendly). |
| Draws in | 3 | — |
| Intuitive | 4 | Clear. |
| Correct | 4 | Right; the debrief's slogan is too early. |

**Rewrite**
- **Hook:**
  - Esra Yilmaz asks for four extra agents.
  - Mrs El Amrani is in the queue for the fourth time this month.
  - Callers wait a quarter of an hour.
- **Briefing:** "Wie het klantcontactcentrum belt, hangt gemiddeld een kwartier in de wacht. Esra Yilmaz, de teamleider, vraagt om vier extra agents. Voordat het MT ja zegt: wie bellen er eigenlijk, en waarom? Eén van hen ken je al: mevrouw El Amrani belt deze maand voor de vierde keer."
- **Debrief:** "Er komen {calls_delta}% minder statusvragen binnen. Esra houdt haar team zoals het is, en haar agents hebben weer tijd voor de vragen die ertoe doen. Bijna de helft van wat ze binnenkregen was vraag die wíj veroorzaakten: niemand vertelde de klant hoe het ervoor stond. Mevrouw El Amrani belde deze maand niet meer; ze kreeg een bericht."
- **Coach:**
  - go_see: "Wat wil je dat er over vier weken anders is aan de telefoon? In een getal?"
  - understand: "Welk deel van de gesprekken had de klant liever niet gevoerd? Hoe heb je dat geteld?"
  - experiment: "Welk getal laat over twee weken zien of je experiment werkt: de wachttijd, of het aantal statusvragen? Waarom kies je dat?"
  - reflect: "Waar ontstond de vraag die je hebt weggenomen? Wat zegt dat over meer agents?"
- **Twist:**
  - The agents are fast and kind (time study, a herring).
  - The deep clue sits two departments upstream: "Wij weten zelf ook niet wanneer het klaar is."
- **Aha:** the call centre's problem is created by the connection stream. Demand is shaped by the process.
- **Grounding:** Seddon (failure demand); the stream's `status_calls` model (after 63 days, every two weeks).
- **Lean check:** right. A practitioner's nuance for the reflect stage: the root of failure demand from waiting is the lead time itself, and status updates treat the information gap. Say so.

### M5 · `fix_done_but_not_closed` — Klaar maar niet af

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | The EAN must be registered before a supplier can contract. A real, less-known pain. |
| Entertaining | 2 | Faceless. |
| Intriguing | 4 | "Werk dat niemand ziet": a real mystery. |
| Challenging | 3 | The "team has time" herring is subtle. |
| Draws in | 2 | — |
| Intuitive | 3 | Where to start isn't obvious. Good, but give a place. |
| Correct | 4 | Batching, one-piece flow. |

**Rewrite**
- **Hook — the El Amrani payoff, part 1:**
  - The cable is in; the heat pump is installed.
  - The supplier says the EAN doesn't exist. In November the heat pump is off.
  - Petra Vos† (Meetdata & registratie, a team of one) has time to spare.
- **Briefing:** "De aansluiting van de familie El Amrani ligt er sinds vorige week. Toch zegt hun energieleverancier dat hun EAN-code niet bestaat, en hun nieuwe warmtepomp staat uit. Bij Meetdata & registratie heeft Petra Vos tijd over. Ergens ligt werk dat niemand ziet."
- **Debrief:** "Een dossier wordt nu afgehandeld op de dag dat het klaar is. Gemiddeld stond een aansluiting {days_before} dagen op 'administratief open'; nu {days_after}. De warmtepomp van de familie El Amrani draait. Bij Petra is de stapel niet kleiner geworden, want er was geen stapel werk. Er was een stapel wachten."
- **Coach:**
  - understand: "Waarop wacht een aansluiting die technisch klaar is? Wie wacht er nog meer op?"
  - experiment: "Als de batch kleiner wordt, wat verwacht je dan van de doorlooptijd? En van Petra's werkdag?"
  - reflect: "Welke andere batches zie je in de stroom die niemand een batch noemt?"
- **Twist:** "het team heeft tijd over" looks like a herring and is actually the proof that the cause is a batch, not capacity.
- **Aha:** a monthly batch adds two weeks to every customer while nobody is busy.
- **Grounding:**
  - The supplier needs the connection in the central connection register (C-AR, EDSN) before it can contract. *Verify the naming.*
  - The EAN concept (EDSN) is in concepts.
- **Content changes:** texts; Petra in the cast.

### M6 · `fix_revision_backlog` — De revisieberg

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Revision lag and KLIC data quality are real (Wibon, NTA 8120). |
| Entertaining | 1 | "Een stapel schetsen." |
| Intriguing | 2 | The briefing gives the consequence away ("kaarten onbetrouwbaar"). |
| Challenging | 3 | Hidden visibility; good herrings. |
| Draws in | 1 | No stake felt. |
| Intuitive | 3 | — |
| Correct | 3 | **L5**: the KPI throughput. The waste is ambiguous. |

**Rewrite.** Proposed **order swap** (§8 Q1): Act II opens with Graafschade (the crisis), whose deepest clue points here. De revisieberg follows as "fix it upstream". The symptom comes before the cause, as in reality.
- **Hook:**
  - The cable Gert hit lay two metres from where the map put it; it had been moved four months earlier.
  - Mieke van der Veen† has a box of 240 sketches. One is drawn on a sandwich bag.
- **Briefing:** "De kabel die Gert Peeters raakte, lag twee meter naast de plek op de kaart. Hij was vier maanden eerder verlegd. Bij Revisie & GIS staat een doos met 240 schetsen van opgeleverde aansluitingen. De oudste is van juni; één is getekend op een broodzakje. 'We tekenen ze over zo snel als we kunnen,' zegt Mieke van der Veen. Hoe komt een kabel zo laat op de kaart?"
- **Debrief:** "Een nieuwe kabel staat nu op de kaart op de dag dat hij in de grond ligt. De oudste open revisie was {age_before} dagen oud, nu {age_after}. Mieke tekent niet meer over; ze controleert. Het broodzakje heeft ze ingelijst."
- **Coach:**
  - go_see: "Hoe oud is de oudste schets in de doos? Wat betekent dat voor wie morgen gaat graven?"
  - understand: "Hoe vaak wordt dezelfde kabel getekend voordat hij op de kaart staat? Door wie?"
  - experiment: "Welk getal laat zien dat de kaart bijblijft: de stapel, of de leeftijd van de oudste schets?"
  - reflect: "Welk probleem verderop wordt kleiner als dit blijft werken? En wie merkt het als het wegzakt?"
- **Twist:**
  - "De bak is overzichtelijk geordend op datum" (tidy inventory is still inventory).
  - "Het GIS-team is te klein" is plausible; more people would redraw faster and still redraw.
- **Aha:** the work is done twice; capturing at the source removes both the backlog and the errors.
- **Grounding:** the Wibon duty to deliver accurate location data through KLIC (Rijksoverheid, graafschade); data quality is an NTA 8120 audit point (NN-CAM 5.0); the 1.5 h redraw is an estimate (content).
- **Lean check:** L5, `kpi: wip_age`. Add the `fact standardised:revision_backlog` as a later NTA 8120 audit input (catalogue `nta8120_audit`). The audit in Act V should *remember* this mission.
- **Content changes:** KPI, texts, the order swap (`requires`), cast.

### M7 · `fix_digging_damage` — Graafschade

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | 7% of digs hit a cable; €38.8M a year; CROW 500 test trenches. |
| Entertaining | 3 | "Klanten zitten zonder stroom": a stake, but faceless. |
| Intriguing | 3 | The linked cause is good. |
| Challenging | 3 | A blame trap ("aannemers graven onvoorzichtig"). |
| Draws in | 3 | — |
| Intuitive | 4 | Clear. |
| Correct | 4 | Right. |

**Rewrite** (as the Act II opener)
- **Hook:**
  - Tuesday 10:12. An excavator of Grondwerk Peeters† hits an MS cable.
  - 300 houses and Zorgcentrum De Linde† go dark; the care home runs on its generator.
  - Gert Peeters shows his KLIC report: "Volgens deze kaart lag hier niks."
  - The four-hour compensation clock starts.
- **Briefing:** "Dinsdag 10.12 uur: de graafmachine van Grondwerk Peeters raakt een middenspanningskabel. Driehonderd huizen en zorgcentrum De Linde zitten zonder stroom; De Linde draait op het noodaggregaat. Uitvoerder Gert Peeters laat zijn KLIC-melding zien: 'Volgens deze kaart lag hier niks.' Het is de vijfde graafschade deze maand. Elke schade kost ons geld, en na vier uur krijgt elke getroffen klant een vergoeding."
- **Debrief:** "Er zijn {damages_per_week} graafschades per week, was {before}. Gert graaft weer met proefsleuven, en zijn opdrachtgever plant er tijd voor in. Maar de kaart klopt nog steeds niet overal. Wie houdt de kaart eigenlijk bij?" (The cliffhanger into De revisieberg.)
  - **Variant `blamed`** (a blame question to the key accounts team or the contractor): "De schades zijn minder. Gert werkt mee, maar hij vertelt je niets meer dan nodig."
- **Coach:**
  - go_see: "Wat zou je willen zien bij de volgende graafklus, voordat de schop de grond in gaat?"
  - understand: "Gert deed een KLIC-melding. Wat kreeg hij terug, en klopte dat?"
  - experiment: "Hoeveel schades per week verwacht je over een maand? Waar meet je dat?"
  - reflect: "Zocht je de oorzaak bij Gert, of in het proces? Wat leverde dat je op?"
- **Twist:**
  - Gert did everything by the book.
  - The shadow clue "monteurs herstellen snel" is true but irrelevant.
  - The deepest clue lands in our own house (revision).
- **Aha:** a crisis downstream with a cause upstream, and a partner who is not the culprit.
- **Grounding:** the Omroep Brabant 7%; the Wibon evaluation; CROW 500 (HR 2018:772); the ACM €35 compensation for 4–8 h.
- **Content changes:** texts, the `blamed` variant, cast (Gert, De Linde), and the order swap.

### M8 · `fix_grid_study_queue` — De netstudie-wachtrij

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | A study queue, 15,000+ in the national queue, triage. |
| Entertaining | 2 | Faceless. |
| Intriguing | 3 | "Hoeveel studies leveren een ander antwoord op?" is great, but buried in the coach. |
| Challenging | 3 | The herring ("analisten maken lange dagen"). |
| Draws in | 2 | Femke is met in the side quest, but not used. |
| Intuitive | 3 | — |
| Correct | 4 | **L12**: the kleinverbruik/grootverbruik nuance; exploit before elevate. |

**Rewrite**
- **Hook:**
  - Femke de Wit, whom the player met in `talk_netplanner`, has 38 studies on her board.
  - The school in Nova-Oost has waited nine weeks for a study that is "waarschijnlijk vijf minuten werk, als ik eraan toekom".
  - Netstrategie asks for two analysts; analysts are scarce nationally.
- **Briefing:** "Femke de Wit en haar collega maken lange dagen: er staan 38 netstudies op het bord. De uitbreiding van de basisschool in Nova-Oost wacht al negen weken op een studie die volgens Femke 'waarschijnlijk vijf minuten werk is, als ik eraan toekom'. Netstrategie vraagt om twee extra analisten, en die zijn in heel Nederland schaars. Wat kan er nog meer?"
- **Debrief:** "Vier op de tien nieuwe aansluitingen kregen een volledige studie; nu {share_after}. Femke rekent weer aan de studies die ertoe doen, en de school had binnen een week antwoord. Je hebt het knelpunt eerst beter benut voordat je het groter maakte. Die volgorde onthoud je."
- **Coach:**
  - go_see: "Wat doet Femke in een uur? Welk deel daarvan kan alleen zij?"
  - understand: "Hoeveel van de studies leveren een ander antwoord op dan 'het past'?" (kept)
  - experiment: "Als je dit knelpunt beter benut, hoeveel studies per week verwacht je? Wanneer zie je dat?"
  - reflect: "Wanneer is extra analisten aannemen wél de goede stap?"
- **Twist:** the work instruction "netstudie bij elke aanvraag boven 3x25A" was written when that was rare. With heat pumps, 3x35A is common (the clue: 40% versus 25% last year).
- **Aha:** TOC's order: exploit the constraint (spend its time only on what needs it) before elevating it (hiring).
- **Grounding:** the national queue (Netbeheer Nederland / LAN); 4 h against 15 min (content estimate). L12: the congestion queue applies to grootverbruik, while this mission is about an LS capacity check for kleinverbruik. Say so in the `triage` concept card.
- **Content changes:** texts; concept `theory_of_constraints` gets the five focusing steps.

### M9 · `fix_transformer_wait` — Wachten op de trafo

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | Transformer lead times; Stedin 9 → 3 months. |
| Entertaining | 2 | "Iedereen wijst naar de fabrikant." |
| Intriguing | 3 | Good herring. |
| Challenging | 3 | — |
| Draws in | 2 | No one waiting with a face. |
| Intuitive | 3 | — |
| Correct | 4 | **L9**: the risk of ordering early is not named. |

**Rewrite**
- **Hook:**
  - Hermans Bouw† hands over 48 homes in De Boomgaard in five months.
  - On today's plan they will have no power: the transformer has six months' lead time.
  - The buyers have moving dates.
- **Briefing:** "Projectontwikkelaar Hermans Bouw levert over vijf maanden 48 woningen op in De Boomgaard. Volgens onze planning hebben die dan nog geen stroom: de trafo voor het nieuwe station heeft zes maanden levertijd. 'Heel Europa wil trafo's,' zegt het projectteam. Dat klopt. Wat kunnen wíj dan nog doen?"
- **Beat (day 60, if unresolved):** Hermans: "Mijn kopers hebben hun huur opgezegd. Wat zeg ik ze?"
- **Debrief:** "De fabrikant is niet sneller geworden. We bestellen alleen niet meer te laat: zodra de netstudie zegt dat er een trafo bij moet. De oudste wachtende verzwaring is {wip_age_after} dagen oud, was {wip_age_before}. De Boomgaard krijgt stroom {weeks_earlier} weken eerder."
- **Coach:**
  - go_see: "Op welk moment weten we dat er een trafo nodig is? En op welk moment bestellen we hem?"
  - understand: "Welke wachttijden lopen nu na elkaar die naast elkaar zouden kunnen?" (from today's reflect)
  - experiment: "Wat is het risico als je bestelt vóór het ontwerp is goedgekeurd? Hoe maak je dat risico klein?"
  - reflect: "Wat kon je niet veranderen, en wat wel? Waar geldt dat nog meer?"
- **Twist:** the herring is true (Europe-wide demand) and still not the cause.
- **Aha:** you cannot shorten someone else's lead time; you can stop starting it late.
- **Grounding:**
  - Stedin 9 → 3 months (IO+).
  - Transformer lead times have grown sharply since 2021: IEA, *Building the Future Transmission Grid* (2025). *Verify the figure before quoting.*
  - Six months is an estimate (content).
- **Content changes:** texts, beat, the countermeasure description (standard sizes, L9).

### M10 · `fix_unused_capacity` — Gereserveerd maar ongebruikt

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | GOTORK and the congestion queue. |
| Entertaining | 3 | The neighbour with 2 MW and an empty hall is a great clue line, but buried. |
| Intriguing | 4 | "Is het net vol, of zijn de contracten vol?" |
| Challenging | 4 | Hidden visibility; a strong herring from the experts. |
| Draws in | 3 | — |
| Intuitive | 3 | Hard to know where to look first. Fine for its tier. |
| Correct | 4 | Inventory of reserved capacity is apt. The legal nuance is missing: reclaiming follows ACM rules and contract terms. |

**Rewrite**
- **Hook:**
  - Ilse de Graaf† wants to replace her bakery's gas ovens with electric ones and has been in the queue for two years.
  - Next door, a logistics hall holds 2 MW and stands empty.
  - Thomas Visser is caught between them, and Ilse threatens to go to the ACM.
- **Briefing:** "Ilse de Graaf wil de gasovens van haar bakkerij vervangen door elektrische. Ze staat al twee jaar op de wachtlijst voor transportcapaciteit. Naast haar staat een distributiehal met twee megawatt gecontracteerd vermogen; de hal is leeg. 'Leg me eens uit waarom het net vol is,' zei ze tegen Thomas Visser. Ze dreigt naar de ACM te stappen. Volgens Netstrategie is het net vol. Is het dat ook?"
- **Debrief:** "Op het drukste kwartier van het jaar gebruikten de grote klanten {share_used}% van wat ze gecontracteerd hadden. Een deel daarvan komt, volgens de regels van de ACM, terug in de wachtrij. Bakkerij De Graaf bakt in het voorjaar elektrisch. Ilse stuurt een krentenbol mee met haar contract."
- **Coach:**
  - go_see: "Wat wil je weten over het drukste moment van het jaar? Waar zou je dat kunnen zien?"
  - understand: "Is het net vol, of zijn de contracten vol?" (kept; it is a question, not a pointer)
  - experiment: "Hoeveel megawatt verwacht je terug te krijgen, en hoeveel bedrijven op de wachtlijst helpt dat?"
  - reflect: "Welke andere voorraad houden wij aan die op papier vol lijkt?"
- **Twist:** the experts' "het net is vol, alleen verzwaren helpt" is the herring. On paper it is true.
- **Aha:** reserved but unused capacity is inventory, and it hides in contracts, not in cables.
- **Grounding:** GOTORK (ACM draft code decision, Solar Magazine; *verify the final status*); the ACM overview of congestion measures; 62% is an estimate (marked).
- **Content changes:** texts; cast (Ilse); the `use_it_or_lose_it` description adds "binnen de regels van de ACM en het contract".

### M11 · `fix_silo_kpis` — KPI's die elkaar bevechten

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Silo KPIs (Goodhart, Deming). Less sector-specific. |
| Entertaining | 3 | Leads pointing at each other. |
| Intriguing | 4 | Records everywhere and no gain. |
| Challenging | 4 | No villain; seven clues; three plausible causes. |
| Draws in | 3 | — |
| Intuitive | 3 | Fine. |
| Correct | 5 | Goodhart, an end-to-end KPI, the Obeya. Excellent. |

**Rewrite** (light touch: this is near the bar)
- **Hook:** the MT meeting. Sanne and Joost each present a record month. Marco: "Mooi. En wie bouwt jullie fouten na?"
- **Briefing:** "In het MT presenteerden Sanne en Joost allebei een recordmaand: meer aanvragen door, meer ontwerpen af. Marco Peters zei niets, tot het einde: 'Mooi. En wie bouwt jullie fouten na?' Er gaan niet meer aansluitingen per week de deur uit dan een kwartaal geleden. Kijk wat hun cijfers van hen vragen."
- **Debrief:** "Sanne en Joost kijken nu naar dezelfde aansluiting en hetzelfde getal: de doorlooptijd en de oudste aanvraag. In het volgende MT presenteren ze samen. Wat je meet, bepaalt wat mensen doen; en wat je níet meet, bepaalt wat ze laten liggen."
- **Coach:** keep all four (already Kata).
- **Aha:** people do exactly what their numbers ask.
- **Act II climax beat** → `first_kpi_review`.

### S1 · `walk_outages` — Mee met de storingsdienst → **"Een nacht met de storingsdienst"**

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | Real stream, no situation. |
| Entertaining | 2 | — |
| Intriguing | 1 | — |
| Challenging | 1 | — |
| Draws in | 2 | — |
| Intuitive | 4 | — |
| Correct | 4 | — |

**Rewrite**
- **Briefing:** "De storingsdienst werkt als de rest slaapt. Loop een dienst mee met monteur Ahmed Bouzid, van melding tot herstel. Let op de klok: na vier uur zonder stroom krijgt elke klant een vergoeding. Waar gaat de tijd naartoe?"
- **Debrief:** "Je zag een storing van melding tot herstel in {minutes} minuten. Halverwege reed Ahmed naar het magazijn voor een mof. Dat onthoud je."
  - This seeds `fix_wrong_joint`, the callback.
- **Hidden:** walking it between 22:00 and 05:00 triggers D9 (Nachtdienst).
- **Aha:** an outage has a clock, and every minute has a place.

### S2 · `walk_meters` — Mee met de meterwisselaars → **"Acht adressen"**

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | — |
| Entertaining | 1 | — |
| Intriguing | 1 | — |
| Challenging | 1 | — |
| Draws in | 1 | — |
| Intuitive | 4 | — |
| Correct | 4 | — |

**Rewrite**
- **Briefing:** "Loop een dag mee met meterwisselaar Sandra Vermeulen†. Er staan acht adressen op haar lijst; de laatste analoge meters in Nova moeten eruit. Tel hoe vaak de deur opengaat."
- **Debrief:** "Van de {n} adressen deed {k} keer niemand open. Sandra liet {k} kaartjes achter: 'helaas niet thuis'. Ze heeft er een dikke stapel van in de bus."
  - It seeds `fix_not_at_home`. The stack of cards is the object.

### S3 · `fix_wrong_joint` — De verkeerde mof in de bus

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Van stock and the 4 h compensation. |
| Entertaining | 3 | — |
| Intriguing | 3 | The warehouse herring. |
| Challenging | 2 | Shallow. Fine for a side. |
| Draws in | 2 | — |
| Intuitive | 4 | — |
| Correct | 3 | L11 (waste class unexplained). Otherwise right. |

**Rewrite**
- **Hook:** "Ze hebben allebei gelijk." The monteurs say the warehouse is late; Dirk Smits† says the joints are on the shelf.
- **Briefing:** "Bij de storing in de Lindelaan was de stroom vijf uur weg; 140 huishoudens krijgen elk €35 vergoeding. Ahmed reed halverwege veertig minuten heen en terug naar het magazijn voor een mof. 'Het magazijn levert te laat,' zeggen de monteurs. Dirk Smits van het magazijn: 'Ik heb ze gewoon liggen.' Ze hebben allebei gelijk. Hoe kan dat?"
- **Debrief:** "Wat in de bus hoort, ligt er nu ook, en een lege bak zegt Dirk wat hij moet aanvullen. De volgende lange storing kostte geen rit naar het magazijn."
- **Twist:** both sides are right. The material exists; it is not at the point of use.
- **Aha:** the right material in the right place is a system (5S, kanban), not memory.
- **Grounding:** ACM €35 for 4–8 h; 140 × €35 = €4,900.

### S4 · `fix_not_at_home` — Niet thuis

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | The analogue-meter programme. |
| Entertaining | 2 | — |
| Intriguing | 2 | The title answers itself. |
| Challenging | 2 | — |
| Draws in | 2 | — |
| Intuitive | 4 | — |
| Correct | 4 | — |

**Rewrite**
- **Briefing:** "Sandra Vermeulen laat elke dag drie kaartjes achter: 'helaas niet thuis'. Het programma om de laatste analoge meters te vervangen loopt achter. Meneer De Jong belde boos: hij had een halve dag vrij genomen, en er kwam niemand. Wie is hier eigenlijk niet thuis?"
- **Debrief:** "Klanten zijn thuis als ze weten wanneer we komen. Sandra's stapel kaartjes is bijna op; ze bestelt geen nieuwe."
- **Twist:** the customer who wasn't home was also the customer who waited for nothing. Both sides lose.
- **Grounding:** the Energiewet and ~500,000 analogue meters (Solar Magazine).

### S5 · `fix_silent_meter` — De zwijgende meter

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | **L7**: the rate is implausible region-wide. |
| Entertaining | 2 | — |
| Intriguing | 3 | — |
| Challenging | 2 | — |
| Draws in | 2 | — |
| Intuitive | 4 | — |
| Correct | 3 | Jidoka is right; the number is not. |

**Rewrite**
- **Hook:** why always the same streets? Petra's list clusters in the new flats on De Kade, with basement meter rooms behind concrete.
- **Briefing:** "Petra Vos heeft een lijst met nieuwe slimme meters die geen standen sturen. Bijna allemaal in dezelfde straten. Monteurs moeten terug naar adressen waar ze vorige week al waren. 'De meters van de nieuwe leverancier deugen niet,' zegt iedereen. Petra twijfelt."
- **Debrief:** "Een meter is pas klaar als hij praat. De monteur ziet het nu voordat hij wegrijdt, niet een week later."
- **Twist:** the supplier herring, and a geographic pattern.
- **Aha:** catch the fault where it happens (jidoka).
- **Grounding:** the 2G/3G sunset (Gaslicht). The rates "3 in 10 in basements; 1 in 20 elsewhere" are an **estimate** (coverage drops behind concrete).

### S6 · `fix_permits_in_batches` — Vergunningen in batches

| Criterion | Score | Evidence |
|---|---|---|
| Real | 4 | Per-project permit batches. |
| Entertaining | 1 | — |
| Intriguing | 2 | — |
| Challenging | 3 | A good herring (the gemeente meets its term). |
| Draws in | 1 | — |
| Intuitive | 3 | — |
| Correct | **2** | **L1**: framed (catalogue doc) as "Check says not the constraint". Batching at a wait step doesn't change capacity, but it does add lead time for every order. The lesson must be about lead time. |

**Rewrite**
- **Hook:** the Bos family's† dossier has been ready for three weeks. It waits in a folder with eleven other homes in De Appelgaard.
- **Briefing:** "Het dossier van de familie Bos is al drie weken klaar bij Werkvoorbereiding. Het ligt in een map met de andere elf woningen van De Appelgaard, want de vergunning gaat per project de deur uit. De gemeente haalt haar termijn bijna altijd. Waar wacht het dossier dan op?"
- **Debrief:** "Een dossier gaat nu de deur uit zodra het tracé bekend is. Er gaan niet méér aansluitingen per week door, want de capaciteit is gelijk gebleven. Maar elke klant is gemiddeld {lead_delta} dagen eerder klaar, en de familie Bos had haar vergunning binnen drie weken. Een knelpunt bepaalt hoeveel er doorgaat; elke wachttijd onderweg bepaalt hoe lang het duurt."
- **Twist:** the municipality is the obvious suspect and is innocent.
- **Aha:** throughput and lead time are different levers (Little's law).
- **Grounding:** the gemeente's consent for cable work in public ground (instemmingsbesluit under the local leidingenverordening/AVOI). *Verify the usual term.* The 14 days per project is an estimate (content).
- **Content changes:** texts; the catalogue doc's note ("Check says not the constraint") is replaced by the L1 two-line Check.

### S7 · `look_at_grid_study` — Een kijkje bij Netstrategie → **"Het bord van Femke"**

| Criterion | Score | Evidence |
|---|---|---|
| Real | 3 | — |
| Entertaining | 2 | — |
| Intriguing | 4 | A teaser: "Dit wordt later een grote klus." |
| Challenging | 2 | — |
| Draws in | 3 | Foreshadowing. |
| Intuitive | 3 | — |
| Correct | 3 | **L14**: the gap-1 bug. |

**Rewrite**
- **Briefing:** "Bij Netstrategie hangt een bord vol netstudies, met gele briefjes die er al maanden hangen. Femke de Wit heeft vijf minuten voor je. Zoek twee feiten over waarom het zo vol is. Oplossen hoeft nog niet."
- **Debrief:** "Je weet nu twee dingen over dat bord. Femke ook: ze vroeg of je terugkomt."
- **Code:** catalogue C0 (the problem sleeps again after the investigation).

### S8 · `fix_inverters_tripping` — Omvormers die afschakelen

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | 253 V; complaints tripled. |
| Entertaining | 4 | Sunny afternoons, panels doing nothing: visible in town. |
| Intriguing | 4 | One measurement per address never finds it. |
| Challenging | 3 | The cheap-inverter herring. |
| Draws in | 3 | — |
| Intuitive | 4 | — |
| Correct | 4 | **L8**: the winter undervoltage is missing. |

**Rewrite**
- **Hook:** Wim Kortekaas†, a retired electrical engineer in the Zonnestraat, sends a spreadsheet every month: three years of inverter trips. Now twenty neighbours complain.
- **Briefing:** "Wim Kortekaas, gepensioneerd elektrotechnicus in de Zonnestraat, stuurt ons elke maand een spreadsheet: zijn omvormer schakelt op zonnige middagen uit, al drie jaar. Inmiddels klagen er twintig buren. Onze monteurs meten adres na adres en vinden in de woning niets mis. Wat zien ze niet?"
- **Debrief:** "Eén aftakking per wijk lost tientallen klachten op. De slimme meters hadden het al die tijd gezien. Wim stuurt geen spreadsheet meer, alleen een kerstkaart. Eén ding nog: wie de spanning in juli omlaag zet, moet in januari kijken wat de warmtepompen ervan vinden."
- **Twist:** each measurement at one address is right and useless. The cause is the street.
- **Aha:** treat the system, not the complaint.
- **Grounding:** EN 50160 (230 V ±10%); Solar Magazine.
- **Lean check:** L8. Problem-backlog idea "De koude straat" (§6.4).

### S9 · `save_henks_knowledge` — Henks kennis

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | The retirement wave; the technician shortage. |
| Entertaining | 3 | Henk is a face. |
| Intriguing | 3 | — |
| Challenging | 3 | A deadline plus a choice. |
| Draws in | 4 | The only ticking clock in tier 1. |
| Intuitive | 3 | The clue says "maart", the mission 56 days (catalogue gap 4). |
| Correct | 3 | **L6** (oliedrukkabel), **L10** (TWI missing). |

**Rewrite**
- **Hook:**
  - Henk's farewell party date is pinned on the board, with the countdown in the HUD.
  - Ahmed searched for 90 minutes in a GPLK cable and then called Henk.
  - Henk doesn't want to be filmed: "Ik laat het je liever zien."
- **Briefing:** "Henk Verbeek werkt veertig jaar bij Voltana. Als in een oude wijk de stroom uitvalt, belt iedereen Henk. Over acht weken geeft hij zijn afscheidsfeest; de uitnodiging hangt al op het prikbord. Vorige week zocht Ahmed Bouzid anderhalf uur naar een fout in een oude papierloodkabel en belde toen... Henk. Zorg dat Henks vakmanschap niet met hem de deur uit gaat."
- **Debrief:**
  - **buddy or TWI:** "Gisteren vond Ahmed zelf de fout in een papierloodkabel in Nova-Oud. Henk stond ernaast en zei niets. Dat was het compliment."
  - **videos:** "Henks video's staan op de tablet. Of ze genoeg zijn, merk je bij de eerste lastige storing zonder hem."
- **Fail:** "Henk is met pensioen. Zijn afscheid was mooi, maar zijn kennis van de oude netten is met hem vertrokken. Een buddy die het kan voordoen is er niet meer. Wat er op papier staat, en wat Ahmed zelf leert, moet het nu doen."
- **Twist:** Henk resists video. The respectful route is to let him teach the way he knows: TWI, buddy.
- **Aha:** skill transfers by doing under a master, not by documentation.
- **Grounding:** the technician shortage (Netbeheer Nederland); GPLK; TWI JI.
- **Lean check:**
  - L6: the clue text.
  - L10: add `twi_job_instruction`; the videos go to 0.7.
  - The calendar opening and the relative clue text ("over twee maanden"), as in the catalogue doc.
- **Path dependence:** `chose:knowledge_drain:skills_matrix_buddy` or `twi_job_instruction` lets Ahmed be the trainer in `fix_training_capacity` (Act IV): a faster train-the-trainer start. A call for Merijn (§8 Q5).

### S10 · `fix_planning_reshuffle` — De planning die nooit klopt

| Criterion | Score | Evidence |
|---|---|---|
| Real | 5 | Planning at 100% load against daily outages. |
| Entertaining | 2 | — |
| Intriguing | 3 | — |
| Challenging | 3 | — |
| Draws in | 2 | — |
| Intuitive | 3 | — |
| Correct | 4 | **L15**: the Kingman nuance is unsaid. Not small (P6). |

**Rewrite**
- **Briefing:** "Planner Linda Jansen is de halve week bezig met omplannen. Vorige week werd een op de drie klussen verschoven, de meeste op de dag zelf. 'Ik werk harder dan ooit,' zegt ze, 'en het wordt alleen maar erger.' Storingen gaan altijd voor. Maar zijn storingen eigenlijk een verrassing?"
- **Debrief:** "Er staan nu elke dag mensen klaar voor storingen, en de rest van de planning blijft staan. Een planning die voor honderd procent vol zit, breekt bij het eerste onverwachte; hoe voller, hoe harder."
- **Aha:** variability is certain. Plan for it, or it plans you (Kingman).
- **Grounding:** Factory Physics (Kingman); day windows in Enexis planner vacancies (GDD).
- **Size (P6):** trim to 4 clues for a side mission, or promote to main (§8 Q4).

---

## 3A. Coach audit (Ruud Hoekstra)

Input: QA autoplay findings 20 ("the coach repeats the same questions across missions": 40 distinct lines over 450 expert asks; "Wat wil je bereiken? ..." opens 14 missions) and 24 (22 mission/stage pairs without an insight). Code read: `Missions.ask_coach`, `stage_of`, `INSIGHT_EVERY`.

### 3A.1 Why Ruud repeats himself

| # | Cause | Where | Fix |
|---|---|---|---|
| C1 | The question index is `(asks[stage] − 1) % size`, and `asks` is per mission. Every mission opens on line 0 of each stage, so the same opener appears in 14 missions. | `missions.gd` `ask_coach` | Offset the index by a stable per-mission number (`Rng.fnv1a(mission_id)`) **plus** a global no-repeat memory: skip any line among the last 6 the player heard (saved with the missions). |
| C2 | Only one insight per stage, shown every third ask. A curious player hears the same insight on asks 3, 6 and 9. | `insights: {stage: text}` | `insights: {stage: [text, text]}`: two per stage, cycled. After both, fall back to questions. |
| C3 | The bank is generic (13 lines) and never names the mission's situation or numbers. | `coach.stages` | The order per ask: (1) the mission's own `questions[stage]` (new, 1–2 per stage); (2) a templated KPI question (catalogue C16: "De doorlooptijd is nu {value} dagen; wat is je doel?"); (3) the rotated bank. |
| C4 | Some insights are instructions or hints, not questions ("Luister eens mee met een paar gesprekken"; "Vergelijk ... woningaansluiting met een bedrijfsaansluiting"; "Kijk niet ... naar wat er gecontracteerd is"; "Waarom wordt hetzelfde werk twee keer gedaan?"). | `missions.yaml` | Rewritten below as Kata questions about the target, the actual condition, the obstacles, the next step and learning. |
| C5 | No question carries the deep-thinking principles. | bank | A long-term, a respect and an always-improve question per stage (§3A.2). |

### 3A.2 The generic bank (rewritten and extended: 6 per stage)

Kata question numbers: **K1** target · **K2** actual condition · **K3** obstacles · **K4** next step and expectation · **K5** what did you learn. Principles: **LT** long term · **RP** respect for people · **AI** always improve. Existing lines are kept (marked =).

| Stage | Line | Kata | Principle |
|---|---|---|---|
| go_see | = "Wat wil je bereiken? Hoe ziet het eruit als het hier goed loopt?" | K1 | |
| go_see | = "Wat heb je zelf gezien op de werkvloer, niet in het rapport?" | K2 | |
| go_see | = "Waar in de stroom ligt het werk stil?" | K2 | |
| go_see | "Wie doet dit werk elke dag? Wat heb je hem of haar gevraagd?" | K2 | RP |
| go_see | "Als je over een jaar terugkijkt, welk getal wil je dan veranderd hebben?" | K1 | LT |
| go_see | "Wat zie je hier dat de mensen zelf al lang niet meer zien?" | K2 | AI |
| understand | = "Hoe is de situatie nu, in cijfers?" | K2 | |
| understand | = "Welke obstakels staan tussen jou en de doelsituatie? Welke pak je nu aan?" | K3 | |
| understand | = "Hoe weet je dat dit de oorzaak is, en niet een symptoom?" | K3 | |
| understand | = "Met wie heb je gesproken die het werk zelf doet?" | K2 | RP |
| understand | "Welke 'waarom' heb je nog niet gesteld?" | K3 | AI (deep) |
| understand | "Wat zou de snelste oplossing zijn, en hoe ziet die er over een half jaar uit?" | K3 | LT |
| experiment | = "Wat is je volgende stap, en wat verwacht je dat er gebeurt?" | K4 | |
| experiment | = "Wanneer kunnen we zien wat je van die stap hebt geleerd?" | K4 | |
| experiment | = "Welk getal vertelt je of het werkt?" | K4 | |
| experiment | "Hoeveel uren kost dit experiment het team, en wie draagt die?" | K4 | RP |
| experiment | "Wat moet er gebeuren zodat dit ook werkt als jij er niet bent?" | K4 | LT |
| experiment | "Wat doe je als het tegenvalt?" | K4 | AI |
| reflect | = "Wat had je verwacht, en wat gebeurde er echt?" | K5 | |
| reflect | = "Wat heb je geleerd?" | K5 | |
| reflect | = "Hoe zorg je dat de verbetering blijft?" | K5 | LT |
| reflect | "Wie heeft dit mogelijk gemaakt, en weten ze dat?" | K5 | RP |
| reflect | "Wat is de volgende kleine stap?" | K4 | AI |
| reflect | "Wat zou je anders doen als je opnieuw begon?" | K5 | AI |

**Conditional lines** (shown when their condition holds; they need the R3 and R1 signals):
- **Overload:** a team above 95% load during the player's experiment: "Het team van {team} draait al twee weken boven de 95%. Wat vraagt jouw experiment van hen, en kan het anders?" (RP)
- **Fading fix:** the A3 picks a countermeasure with `decay_days ≤ 45` while a durable one fits: "Hoe lang verwacht je dat dit blijft werken? En dan?" (LT)
- **After a blame question:** "Wat wilde je eigenlijk weten toen je dat vroeg?" (RP)

### 3A.3 Mission-specific insights: the full set

All 22 pairs flagged by QA finding 24 are filled (marked ●). Every other reachable stage gets a line too. Two lines in a cell means the cell is cycled (C2). Training days without a problem only reach `go_see`; `walk_connections` likewise.

| Mission | go_see | understand | experiment | reflect |
|---|---|---|---|---|
| `training_mon` | "Een aanvraag doet er maanden over. Hoeveel van die tijd wordt er echt aan gewerkt, denk je? En hoe zou je dat kunnen zien?" (K2) | — | — | — |
| `training_tue` | "Wat deed Anouk, en wat deed het werk terwijl zij bezig was?" (K2, RP) | — | — | — |
| `training_wed` | "Welke van de twee getallen vertelt je meer: het aantal dossiers of de dagen werk? Waarom?" (K2) | — | — | — |
| `training_thu` | ● "Gisteren telde je waar het werk wacht. Wat wil je over drie dagen anders zien bij Anouk, in een getal?" (K1) | "Wat doet Anouk voordat het echte werk aan een dossier begint? Hoe lang duurt dat?" (K2) | "Welk getal laat over drie dagen zien of het werkt, en wat verwacht je dat het dan is?" (K4) | "Wat had je verwacht, en wat gebeurde er? Wat neem je mee naar maandag?" (K5) |
| `training_fri` | — | — | — | "Wat gebeurt er met de nieuwe werkwijze als het team het druk krijgt en niemand erop let? Wie zou erop moeten letten?" (LT) · "Wat kost borgen nu, en wat kost niet borgen over een jaar?" (LT) |
| `walk_connections` | "Waar zou jij als dossier het liefst niet liggen, en waarom ligt het er toch?" (K2) | — | — | — |
| `fix_custom_design` | ● "Wat is je doel voor Werkvoorbereiding, in een getal? En hoe ziet het er nu uit?" (K1, K2) | "Welk deel van wat Anouk doet, merkt de klant? En welk deel niet?" (K3; replaces the hint, C4) | "Wat verwacht je dat er met de stapel gebeurt: hoeveel, en wanneer kun je het zien?" (K4) | "Wie in het team wist het antwoord al voordat jij kwam? Wat betekent dat voor hoe je de volgende keer begint?" (K5, RP) · "Joost vroeg om twee mensen. Wat heeft zijn team nu nodig om dit vast te houden?" (LT, RP) |
| `fix_incomplete_application` | ● "Twee teams vragen om je aandacht. Waar ligt het meeste werk te wachten, in dagen werk? Heb je dat zelf geteld?" (K2) | "Waar ontstaat de fout: bij Sanne, of al eerder? Hoe weet je dat?" (K3) | ● "Als je voorspelling klopt, welk getal bij de intake verandert, en welk getal aan het eind van de stroom?" (K4) | "Wat is het verschil tussen een fout vinden en een fout voorkomen?" (K5) · "Een extra controleur had ook geholpen. Wat was daar over een jaar van over geweest?" (LT) |
| `fix_installer_not_ready` | "Twee teams vragen om je aandacht. Waar staat het werk het langst te wachten?" (K2) | ● "Wie weet als eerste dat een meterkast niet klaar is, en wanneer hoort de planner het?" (K3) | ● "Welk getal verwacht je dat verandert: de monteursuren, de doorlooptijd, het aantal aansluitingen per week? Allemaal?" (K4) | "Gaan er nu meer aansluitingen per week door? Wat is er wél beter geworden, en voor wie?" (K5) · "Marco's monteurs hebben uren terug. Wat wil je dat ze ermee doen?" (RP, AI) |
| `fix_status_callers` | "Wat wil je dat er over vier weken anders is aan de telefoon? In een getal?" (K1; replaces the instruction, C4) | "Welk deel van de gesprekken had de klant liever niet gevoerd? Hoe heb je dat geteld?" (K2) | ● "Welk getal laat over twee weken zien of je experiment werkt: de wachttijd, of het aantal statusvragen? Waarom kies je dat?" (K4) | ● "Waar ontstond de vraag die je hebt weggenomen? Wat zegt dat over meer agents?" (K5) · "Esra's agents hebben nu tijd over. Wat zou jij met die tijd doen, samen met hen?" (RP, AI) |
| `fix_done_but_not_closed` | ● "Hoe lang staat een aansluiting die technisch klaar is op 'administratief open'? Hoe weet je dat?" (K2) | "Waarop wacht een aansluiting die technisch klaar is? Wie wacht er nog meer op?" (K3) | ● "Als de batch kleiner wordt, wat verwacht je dan van de doorlooptijd? En van Petra's werkdag?" (K4, RP) | ● "Welke andere batches zie je in de stroom die niemand een batch noemt?" (AI) |
| `fix_revision_backlog` | ● "Hoe oud is de oudste schets in de doos? Wat betekent dat voor wie morgen gaat graven?" (K2) | "Hoe vaak wordt dezelfde kabel getekend voordat hij op de kaart staat? Door wie?" (K3; replaces the hint, C4) | ● "Welk getal laat zien dat de kaart bijblijft: de stapel, of de leeftijd van de oudste schets?" (K4) | ● "Wie merkt het als dit over een jaar wegzakt, en hoe snel? Wat houdt het vast?" (LT) |
| `fix_digging_damage` | ● "Wat moet er vandaag gebeuren zodat er deze week niemand gewond raakt? En wat pas daarna?" (K3; the safety exception) | "Gert deed een KLIC-melding. Wat kreeg hij terug, en klopte dat?" (K2) | ● "Hoeveel schades per week verwacht je over een maand? Waar meet je dat?" (K4) | "Zocht je de oorzaak bij Gert, of in het proces? Wat leverde dat je op?" (K5, RP) · "Welk probleem dat je eerder oploste, hielp hier mee?" (=) |
| `fix_grid_study_queue` | "Wat doet Femke in een uur? Welk deel daarvan kan alleen zij?" (K2) | "Hoeveel van de studies leveren een ander antwoord op dan 'het past'?" (=, K3) | ● "Als je dit knelpunt beter benut, hoeveel studies per week verwacht je? Wanneer zie je dat?" (K4) | ● "Wanneer is extra analisten aannemen wél de goede stap? Wat moet er dan eerst kloppen?" (LT) · "Femke maakte lange dagen. Hoe zie je of dat nu anders is?" (RP) |
| `fix_transformer_wait` | ● "Op welk moment weten we dat er een trafo nodig is? En op welk moment bestellen we hem?" (K2) | "Welke wachttijden lopen nu na elkaar die naast elkaar zouden kunnen?" (K3) | ● "Wat is het risico als je bestelt vóór het ontwerp is goedgekeurd? Hoe maak je dat risico klein?" (K4) | "Wat kon je niet veranderen, en wat wel? Waar geldt dat nog meer?" (K5, AI) |
| `fix_unused_capacity` | "Wat wil je weten over het drukste moment van het jaar? Waar zou je dat kunnen zien?" (K2; replaces the hint, C4) | "Is het net vol, of zijn de contracten vol?" (=, K3) | ● "Hoeveel megawatt verwacht je terug te krijgen, en hoeveel bedrijven op de wachtlijst helpt dat?" (K4) | ● "Welke andere voorraad houden wij aan die op papier vol lijkt?" (AI) · "Hoe heb je de klanten behandeld die capaciteit teruggaven? Komen ze bij ons terug als ze groeien?" (RP, LT) |
| `fix_silo_kpis` | = (kept) | = | = | = · "Wie heeft last gehad van de oude cijfers, en weten ze dat het niet aan hen lag?" (RP) |

**Debrief notes on key clues** (QA finding 25: 76 key clues have no `note:`). Out of scope for this pass; it follows the same rule. A note is one question in Ruud's voice, e.g. for `custom_design` clue 4 (data, depth 2): "Driekwart is standaard. Waarom werd het als maatwerk behandeld?"

---

## 4. Hidden rewards ("Ontdekkingen")

### 4.1 Principles

1. **Unannounced.** No list, no progress bar, no hint until an act ends. A quiet toast at the bottom left, "**Ontdekking** — {naam}", with one Dutch line, no XP number and no fanfare.
2. **They reward the learning, never a shortcut past it.** Any trigger about speed, thrift or efficiency also requires quality: the right cause, deep evidence, no red herrings linked, a first-pass Check. No reward for skipping the gemba, the coach or a mission.
3. **Small in power, big in meaning.** No belt jumps; XP at most 0, and reputation at most +3. Rewards are recognition (titles, objects, a private note from Ruud), stories (grid lore with sources), or *alternatives* (a countermeasure that is another real path, never strictly better than the best existing fit).
4. **Detectable.** Each trigger is a predicate over signals the rules have or can cheaply log (§4.4).
5. **Every fork branch can earn something.** There is no "right" branch to farm (D4 and D5).
6. **Once each.** Except where noted, a discovery fires once per save.
7. **Deep thinking first (Merijn, 2026-10-15).** Rewards favour:
   - the extra why;
   - the patient, durable fix;
   - developing a person rather than replacing them;
   - spreading load instead of burning a team out.

   A reward never pays the short-term or the disrespectful choice more. The only exception is real: safety containment *followed by* the root-cause fix (D28). The principle check removed three earlier candidates:
   - **Haringvisser**, "no herrings ×10": folded into D1, which requires it anyway;
   - **Stille week**, "28 days without an outage over 4 h": a system state the player can't directly cause, and it tempted short-term firefighting;
   - **Vroege dienst**, "a van check before 07:00": it risked praising long hours over good habits.

### 4.2 How they surface

- **The toast:** "Ontdekking — Terug naar de gemba. *De belangrijkste pijl is de pijl terug.*"
- **The vitrine:** a display cabinet in the CI lead's office (3D, Phase C). It fills with objects: Henk's knife, the framed sandwich-bag sketch, the El Amrani thank-you card. Each object, when inspected, tells where it came from.
- **The codex tab "Ontdekkingen":**
  - Found ones show with their story.
  - Unfound ones are silhouettes.
  - **At the end of an act**, unfound discoveries of that act show a cryptic Dutch hint (e.g. "Sommige teams werken als jij slaapt."). It invites replay and curiosity without spoiling.
- **Recognition:** in the next act's title card, Ruud mentions one discovery (e.g. "Ik hoorde dat je om drie uur 's nachts in de meldkamer stond."). He never mentions one while coaching.
- **Titles:** shown under the player's name in the HUD profile (one chosen at a time).

### 4.3 The catalogue (25)

Rewards: **T** title · **V** vitrine object · **A** avatar cosmetic · **R** Ruud's private note (a handwritten card: a deeper reflection plus a pointer to a real Lean source) · **S** story card (grid lore, sourced) · **C** an alternative countermeasure unlocked · **Rep** reputation · **Tr** trust.

| # | Name (NL) | Trigger (detectable) | Reward | Learning reinforced | Anti-shortcut guard |
|---|---|---|---|---|---|
| D1 | **Scherpe blik** | A problem resolved with **all** key clues found and gemba minutes ≤ par; the cause is correct, a key clue at the deepest depth is linked, no herrings are linked, and the Check passes first time. | T "Scherpe blik", R ("Ga kijken, maar kijk naar het goede.") | Thorough *and* focused: choosing where to look is the skill. | All key clues are required, so it never rewards stopping early. Par is computed from the full clue tree (§4.4). |
| D2 | **Veilige haven** | An act completed with zero blame questions and every team's trust ≥ 0 at its end. | T "Veilige haven"; each team lead volunteers one *observation* in the next act. | Respect for people pays. | An observation, never a key clue. |
| D3 | **Excuses aanvaard** | In one mission: a blame at team X, then a repair at X, then a key clue from a conversation at X. | R (on repairing trust), V: a coffee mug from that team. | Recovery is the lesson (GDD pillar 1). | Fires once. The blame still cost trust and score (`blamed`). |
| D4 | **Het knelpunt eerst** | Fork: `queue_count` or `time_study` used at **both** branch places in the 7 days before accepting a branch, then the bottleneck branch completed first. | Rep +3; T "Knelpuntjager" (first fork); V: an hourglass that gains a band per fork. | Measure before you choose. | Measuring is the requirement, so guessing right doesn't count. |
| D5 | **Leren van de Check** | Fork: the non-bottleneck branch done first, its Check shows `not_constraint`, and then the bottleneck branch passes first time with the right cause and prediction. | R ("Een experiment dat niet uitkomt is geen mislukking."); V: the framed Check printout. | The Check is a teacher, and the other branch is not "wrong". | Needs a first-pass Check on the second branch. |
| D6 | **Terug naar de gemba** | A failed Check (`too_early` or `mismatch`), then **a new key clue** found before the next A3, then a pass with the right cause. | A: muddy boots; R ("De belangrijkste pijl is de pijl terug."). | GDD's most important arrow. | Needs a new key clue. Resubmitting the same A3 doesn't count. |
| D7 | **Een jaar later** | A fix holds health ≥ 0.9 for 365 in-game days. | V: a team photo by that fix; Tr +1 at that team; a beat in which the team lead thanks you. | Sustain (Merijn's decay rule). | Possible only with real sustaining habits. Repeatable per problem. |
| D8 | **Ritme** | `lsw_gemba_round` completed 8 times in a row, each inside its cadence window. | T "Ritme"; A: a worn clipboard. | Leader standard work is a rhythm. | — |
| D9 | **Nachtdienst** | A gemba tool or open question at an `outages.*` place between 22:00 and 05:00 in-game. | S "Diemen, 27 maart 2015", told by Kees in the control room (ACM investigation, Kamerstukken); A: the control room's thermos mug. | The gemba runs 24/7; grid lore. | — (curiosity) |
| D10 | **Voorspeller** | 5 A3s in a row with the right prediction KPI and a first-pass Check. | T "Voorspeller"; R (on Kata predictions: "een voorspelling is een hypothese, geen gok"). | Kata prediction. | Needs a Check pass, not only the KPI. |
| D12 | **Faalvraag-jager** | `listen_in` at `customer_contact.answer` during 3 different main missions, plus `status_callers` resolved with `proactive_status_updates`. | R from Esra; S on Seddon's failure demand. | The customer's voice as a gemba. | — |
| D13 | **Henks mes** | `save_henks_knowledge` completed with `skills_matrix_buddy` or `twi_job_instruction`, and an open conversation with Henk at `outages.locate` in his last 7 days. | V: Henk's cable knife; **C** "Henks storingsboekje" (a TWI job breakdown for GPLK cables, tier 1, fit 0.8 for `cause_unknown` in Act III: an alternative, not the best). | Respect for people; knowledge transfer. | C still needs an A3 and a Check. |
| D14 | **Het dossier van de familie El Amrani** | The followed order is delivered (EAN registered) within 126 days of birth. | V: their thank-you card; Rep +2. If later: a different, kind card with no reward (no shame). | Lead time as the customer feels it. | Computed from the simulation, not scripted. |
| D15 | **Wims spreadsheet** | The `data` tool at `voltage_complaints.measurement` in summer, between 11:00 and 15:00, while `inverters_tripping` is active. | S on 253 V and EN 50160; one extra *observation* (Wim's 3-year log); A: a solar-panel pin. | Go and see *when* the problem happens. | Observation only. |
| D16 | **Het eerste net** | `documents` at `connections.revision` while **no** problem is active there. | V: a framed 1930s hand-drawn map of Nova's first grid; S (fiction, labelled as Nova lore). | Curiosity at the gemba. | — (Easter egg) |
| D18 | **Goodhart ontweken** | A KPI review choosing no output or utilisation KPI for any department, with a forecast gain > 0. | R (Goodhart, Deming); V: a compass "Noordster". | KPI alignment. | Needs a positive forecast gain. |
| D19 | **Capaciteit gevonden** | `fix_custom_design`, `fix_status_callers` and `fix_grid_study_queue` (the three "we need more people" missions) each scored ≥ 20/25, with no `temporary_hire` countermeasure used (to be added: a real but weak option with a weekly cost). | T "Capaciteit gevonden"; S on Enexis 10 → 100 stations a year. | Capacity hides in the work. | Needs high scores; hiring stays legitimate, just not this title. |
| D21 | **Een andere weg** | After a missed deadline (e.g. Henk), the same problem solved through the remaining route with a score ≥ 20/25. | Rep +3; R ("Een gesloten deur is geen einde."). | Setbacks are not game over. | Rewards the recovery, not the miss. Its rep (+3) is far below the miss's (−10). |
| D22 | **De hele cyclus** | In one main mission, the coach asked at all four stages (go_see, understand, experiment, reflect), and the Check passes with the right prediction. | A: Ruud's Kata card in the shirt pocket (Rother's five questions). | The Kata rhythm. | Needs the Check pass. Asking alone isn't enough. |
| D23 | **Zelf coach** | A `coach` goal (Act III+): 3 sessions with the five questions in order and no closed or blaming question. | T "Coach"; Sanne (or Joost) gets her own Kata card in the vitrine. | Coaching kata. | — |
| D24 | **Nog één waarom** | At A3 submission: the problem's **deepest** key clue (max depth) is found and linked, and the cause is correct, although a valid A3 was already possible with shallower evidence (the `submit_a3` minimum). Five times. | T "Nog één waarom"; R ("Het eerste antwoord is zelden het laatste."). | The 5 Whys as a habit: going one level deeper than needed. | Needs the right cause; the depth comes from the content's clue tree. |
| D25 | **De lange adem** | The A3 chose a countermeasure with `decay_days: null` (or standardised) while a cheaper one with `decay_days ≤ 45` also fitted (fit ≥ 0.6), and the fix still holds (health ≥ 0.9) **180 days** later. Three times. | V: an old oak cable drum ("gebouwd om te blijven"); Rep +2; R on long-term thinking. | Long term over short term, *proven by time*, not by the choice alone. | Paid only when the hold is confirmed; choosing expensive without holding earns nothing. |
| D26 | **Ontwikkelen, niet vervangen** | Three problems solved with a countermeasure of category `people` or `standard_work` that develops the team (e.g. `skills_matrix_buddy`, `twi_job_instruction`, `shared_team_goals`, `standard_designs` standardised), **without** ever using `temporary_hire`, **and** a `coach` mission completed (Act III+). | T "Mensenmens"; the coached team lead gives a talk at the Obeya (beat); Tr +1 at each team involved. | People are the most valuable resource; develop them rather than replace them. | Needs a coach mission, so a countermeasure label alone isn't enough. |
| D27 | **Niemand opgebrand** | An act completed in which no pool drawn on by the player's experiments stayed above 95% utilisation for 14 days (the R3 signal), with at least 3 experiments run. | T "Goede werkgever"; R ("Een team dat altijd op 100% draait, heeft geen ruimte om te verbeteren."). | Respect for people as load management; slack enables improvement (Kingman). | Needs ≥ 3 experiments, so doing nothing doesn't earn it. |
| D28 | **Eerst veilig, dan beter** | In a `safety: true` mission (digging damage; Act III LMRA, heatwave): the `containment` action taken within 2 days of accepting, **and** the root-cause fix resolved afterwards with the right cause. | A: a safety helmet with a Voltana sticker; R ("Indammen is geen oplossen, maar soms moet het eerst."). | The real exception to long-term-first, and that containment is not the fix. | Containment alone pays nothing; it fades in 14 days (§2.4.1). |

Dropped after the principle check: D11 Haringvisser, D17 Stille week, D20 Vroege dienst (§4.1, item 7).

*Best five:*
1. **D4 + D5**, as a pair. Both fork branches teach: a measured choice, or learning from the Check.
2. **D6 Terug naar de gemba.**
3. **D25 De lange adem.**
4. **D26 Ontwikkelen, niet vervangen.**
5. **D14 Het dossier van de familie El Amrani.**

D1, D13 and D24 come close.

### 4.4 Signals the rules must provide

| Signal | Status | For |
|---|---|---|
| `trust`, `blamed`, `found`, `observed`, `key_clues_found`, the score inputs (`herrings_linked`, `failed_checks`, `prediction_right`, `cause_correct`, `standardised`, `at_constraint`), Check `not_constraint`, `health()`, `held_by_routine()`, the KPI review result, `net.time` | **exists** (`region.gd`, `pdca.gd`) | most |
| **Gemba log:** every `use_tool` and `ask` as `{time, place, tool or question, open problem ids}` | new (small): append in `Region.use_tool` and `ask` | D1, D3, D4, D9, D12, D13, D15, D16 |
| **Gemba minutes per problem:** the sum of tool minutes at places of the problem's stream while it is open | new: derived from the log | D1 |
| **Par per problem:** 1.5 × the minimal minutes to reveal the key clues on the deepest chain (cheapest tool per key clue, `Investigation.TOOLS[...].minutes`) | new: computed in `tools/build_content.py`, stored in the problem JSON | D1 |
| **Coach-ask log:** `{mission, stage}` | new (small): in `GameSession` | D22 |
| **Followed order:** a tag on one work order at birth; its delivery time | new: sim `WorkOrder.story` | D14, M1/M4/M5 debriefs |
| Facts (`fork_first`, `chose`, `failed`, `done`) | planned (catalogue C19) | D4, D5, D13, D21 |
| Season and time of day | exists (`SimCalendar`) | D9, D15 |
| **Pool load window:** utilisation per pool over 14 days, and whether a player experiment (`do:` effects) draws on it | new: from pool stats and `net.effects()` | R3, D27, the coach's overload line |
| **Countermeasure durability** at A3 time: the alternatives that fit and their `decay_days` | exists in content; new: logged at `submit_a3` | R1 lifecycle cost, D25, the coach's fading-fix line |
| **`containment` action** and `safety: true` on missions | new (§2.4.1) | D28 |
| **Max clue depth** per problem | derived in `tools/build_content.py` | D24 |

**Architecture:** a separate `rules/discoveries.gd`.
- It reads `content/discoveries.yaml`, consumes `Region.drain_events()` and the gemba log, and evaluates predicates.
- It emits `{type: "discovery", id}`, and its state is saved.
- No other module depends on it, so the architecture skill's "dependency of 3+" trigger is avoided.
- Each trigger type is one small function: `a3_quality`, `deepest_why`, `fork_order`, `check_recovery`, `sustained`, `durable_choice_held`, `develop_people`, `no_overload_act`, `contain_then_fix`, `routine_streak`, `tool_at`, `kpi_review_choice`, `followed_order`, `missions_scored`, `coach_cycle`, `coach_sessions`, `no_blame_act`, `blame_repair_clue`, `recovered_after_fail`.

```yaml
# content/discoveries.yaml (sketch)
discoveries:
  - id: back_to_gemba
    name: Terug naar de gemba
    line: "De belangrijkste pijl is de pijl terug."
    hint: "Een Check die tegenvalt, is het begin van iets."   # shown after the act if not found
    act: any
    trigger: {type: check_recovery, new_key_clue: true}
    reward: {cosmetic: muddy_boots, note: ruud_back_to_gemba}
```

---

## 5. Engagement design

### 5.1 Pacing curve

**Per act:** an opener (calm, a walk or a talk), then rising investigation, a mid-act **turn** (a linked cause or a fork), a **crisis** (a deadline or event), a **climax** (a milestone or the act's hardest solve), a **breather** (sustain, routine or a reflection) and a **cliffhanger** beat.

| Act | Opener | Rising | Turn | Crisis | Climax | Breather | Cliffhanger beat (into next act) |
|---|---|---|---|---|---|---|---|
| 0 Inwerkweek | Mon tour (the letter) | Tue/Wed observe | Thu: where did the El Amrani dossier go? | — | Fri: standardise or fade | — | Ruud: "Maandag vraagt Joost om twee extra mensen. Ik heb gezegd dat jij eerst gaat kijken." |
| I Honderd dagen | Volg het dossier | custom design | **fork** | Henk's deadline (side) | `review_100_days` | `lsw_gemba_round` | At the day-100 drinks, Ruud's phone: an excavator hit an MS cable near De Linde. "Volgens de kaart lag daar niks." |
| II Onder de grond | Graafschade (crisis as opener) | revision → studies | linked causes: the map, the transformer order | Ilse threatens the ACM | silo KPIs → first KPI review | `lsw_van_round` | The first review shows outage minutes rising, and a storm warning for next month. Ruud: "Jij vindt de problemen. Ik wil dat de teams ze zelf zien." |
| III Zichtbaar | daily boards | cause unknown | **fork** (on-call vs handover) | storm / heatwave events | the ACM visit | coach Sanne | ACM verdict, then a promotion. Lindeveld's lead calls: "Bij ons rijden ze een uur per klus. En er gaan er drie met pensioen." |
| IV Regio | map the region | long drives | **strategy** (crew) + **fork** | nitrogen deadline | stop starting (sustain) | layered audit | The Raad van State letter, and the MT: "We hebben twintig prioriteiten." The NTA 8120 audit date arrives by post. |
| V Systeem | hoshin | maintenance | **fork** (detect vs theft) | the audit | investment plan | sustain the region | (finale placeholder) Lotte, the new CI lead of Lindeveld, knocks on your door. |

**Intensity** (1–5) across the campaign: 1 → 2 → 3 → 4 (fork) → 3 → 5 (day 100) → 4 (Act II opener crisis) → … Each act peaks at its milestone, and each act's floor is higher than the last.

**Session rhythm (15–40 minutes, GDD):**
- Every in-game week has at least one **beat** (a line from a person).
- Every session should contain one discovery at the gemba and one number that changed.
- The *dagstart* ends on a "vandaag" hook line from the most urgent person ("Henk: nog 12 dagen.").
- Saving at a dagstart keeps a cliffhanger natural: the next session opens with the consequence.

### 5.2 Mission shapes and mix

| Shape | What makes it good | Goal types | Examples |
|---|---|---|---|
| **Investigation** | a mystery with a turn in the clue chain | `solve` | custom design, done-but-not-closed, unused capacity |
| **Crisis with a deadline** | a visible clock with a face; a door closes on a miss; another way stays open | `solve` + `deadline_days`, `event` | Henk, storm, heatwave, nitrogen |
| **People and conflict** | two people who are both right; blame costs | `solve`, `talk_to`, `coach` | silo KPIs, wrong joint ("allebei gelijk"), coach Sanne |
| **Data puzzle** | the answer is in data nobody looks at | `solve` with `data` key clues, `measure` | inverters (smart meters), unused capacity, cause unknown (Pareto) |
| **Fork dilemma** | two equally loud asks with true numbers; you measure, the Check judges | fork pair | the five forks |
| **Sustain / routine** | the win is that nothing happens; a quiet streak | `sustain`, `routine`, recurring | `lsw_*`, `sustain_connections`, `t3_stop_starting` |
| **Strategic choice** | the options depend on your past; locked options visible, not explained | `strategy`, `okr` | `t3_crew_strategy`, `t4_investment_plan` |
| **Follow the order** | one customer's journey makes lead time personal | `walk` + a followed order | Volg het dossier (Act 0–I) |
| **Expert conversation** | a sector story through open questions | `talk_to` | `talk_netplanner`, `talk_regulation` |

**Mix rules:**
1. No two **consecutive main** missions share a shape.
2. Every act has at least one each of: investigation, people/conflict, data puzzle, crisis.
3. Forks: one per act from Act I, except Act II (catalogue doc).
4. Hard deadlines: at most one *active* at a time.

**Tier-1 main chain with shapes (after the rewrites):**
- Act I: follow → investigation (custom design) → fork → people/data (status callers) → investigation (done but not closed).
- Act II: crisis (digging) → investigation (revision) → data (grid study) → investigation (transformer) → data/people (unused capacity) → people (silo KPIs).

There are no back-to-back repeats.

### 5.3 Recurring characters and arcs

Extends the catalogue doc's cast (§2.3). New entries are marked †. Each arc has stages that missions and beats advance. Several feed **path dependence**.

| id | Name | Role / place | Arc (stages) | Path-dependent hook |
|---|---|---|---|---|
| `ruud` | Ruud Hoekstra | coach | asks → trusts → reveals his own failed 2012 "verbeterprogramma" that consultants ran and that faded (Act III, a lesson on sustaining) → lets go (finale) | private notes (D-rewards) |
| `anouk`† | Anouk de Vries | werkvoorbereider | drowning alone (Act 0) → overtime (custom design) → owns the standard designs → kata learner (Act III) → team lead (Act IV) | `standardised:custom_design` makes her the owner; if it fades, she leaves for Enexis in Act IV (a beat), and the investment option "Standaardstations" gets harder |
| `joost` | Joost van Dijk | TL Werkvoorbereiding | asks for people → withdraws the vacancies → resists WIP limits (Act IV) → coached | — |
| `sanne` | Sanne Bakker | TL Intake | "postkantoor" → owner of the poka-yoke form → coached (Act III) → coaches others | trust ≥ 1 gates `coach_intake_lead` |
| `marco` | Marco Peters | TL Monteurs | cynic ("weer een verbeterprogramma") → ally after van kanban → fights for his hours in the crew strategy | `chose:installer_not_ready:*` gives freed hours (§8 Q3) |
| `henk` | Henk Verbeek | senior monteur | "laat het me voordoen" → leaves (day ~98) → a postcard each act if his knowledge was saved | D13; C "Henks storingsboekje" |
| `ahmed`† | Ahmed Bouzid | young monteur | lost in GPLK → Henk's buddy → trainer in Act IV `fix_training_capacity` | **if** buddy or TWI was chosen, train-the-trainer starts with Ahmed (a faster ramp) |
| `esra` | Esra Yilmaz | TL KCC | asks for agents → failure-demand champion → runs a board in Act III | D12 |
| `femke` | Femke de Wit | netplanner (expert) | overloaded → triage owner → "het net van 2035" (Act V) | — |
| `linda` | Linda Jansen | planner | re-plans half the week → planning with windows → heijunka (Act IV) | — |
| `petra`† | Petra Vos | Meetdata (one-person team) | "tijd over" → close-out at completion → Act III: Petra is sick for a week, a single-point-of-failure lesson (skills matrix) | — |
| `mieke`† | Mieke van der Veen | Revisie & GIS | the box of sketches → checker, not redrawer → NTA 8120 audit witness (Act V) | `standardised:revision_backlog` is read by the audit |
| `gert`† | Gert Peeters | uitvoerder, Grondwerk Peeters (contractor) | hit the cable "by the book" → test trenches → Act III `contractor_rework` callback (Twee keer graven): a partner, not a culprit | trust with key_accounts |
| `wim`† | Wim Kortekaas | resident, Zonnestraat | the spreadsheet → a Christmas card → Act V: a flex-market volunteer with his home battery | D15 |
| `el_amrani`† | familie El Amrani | customer, Nova-Oost | the letter → a FIFO victim → the fourth call → "EAN bestaat niet" → the heat pump runs | D14 |
| `ilse`† | Ilse de Graaf | Bakkerij De Graaf | queue for two years → electric ovens → Act IV: wants to join an energy hub | `sector_energy_hub` |
| `de_linde`† | Zorgcentrum De Linde (manager mevr. Brouwer) | priority customer | on its generator (Act II) → storm (Act III) → prioritisation framework (Act IV), where it is the face of "maatschappelijk prioriteren" | — |
| `yvonne`† | Sandra Vermeulen | meterwisselaar | the stack of cards → none left | — |
| `dirk`† | Dirk Smits | magazijn | "ik heb ze gewoon liggen" → kanban owner → Act III `safety_stock_calendar` | — |
| `hermans`† | Hermans Bouw | project developer | 48 homes waiting → Act IV `uneven_release` (De maandpiek: he releases 200 homes at once) | — |

**Writing rules for the cast:**
- Each person has one **voice line** that recurs: Henk: "Laat het me voordoen."; Marco: "En wie bouwt dat na?"; Femke: "Vijf minuten werk, als ik eraan toekom."
- People are never the cause; the process is. A person may hold a *wrong belief* (a plausible cause) that the clues correct, never a vice.

### 5.4 Side missions: small but memorable

**The four ones:** one **person**, one **place**, one **twist**, one **object** (Sandra's stack of cards, Henk's knife, the sandwich-bag sketch, Wim's spreadsheet).

- **Size:**
  - ≤ 4 clues, ≤ 2 tools needed;
  - ≤ 14 in-game days of play;
  - a briefing of ≤ 3 sentences.
- **A callback:** every side mission plants or pays off something in the main line. `walk_outages` plants the warehouse trip, which `fix_wrong_joint` pays off. `look_at_grid_study` plants Femke's board.
- **The last line is a small smile,** not a lesson ("Wim stuurt alleen nog een kerstkaart.").
- **No coach** (CLAUDE.md), but people talk. That keeps sides human without breaking the rule.

### 5.5 Forks

- **Shown as a pair** on one card: "Twee teams vragen om je aandacht." Each team lead has one line with a true number.
- **No branch is marked right.** D4 rewards measuring first, D5 rewards learning from the Check.
- **The non-bottleneck debrief always names what did improve** (euros, lead time for those affected) and what did not (output per week). L1 keeps it honest.
- Use them rarely: five in the campaign (catalogue doc), never two acts in a row with the same fork pattern.

### 5.6 Deadlines and clocks

- **Hard deadlines** have a face and a date the player can see: Henk's party invitation on the board, the developer's key handover, the ACM letter. The countdown is in the HUD only for the active one.
- **Soft clocks** are beats, not failures. The MT waits for your A3 on Joost's vacancies; Ilse threatens the ACM. They create urgency without multiplying fail states. If a soft clock passes, a beat raises the pressure. No door closes.
- **The miss text** is respectful and names the other way (Henk's fail text above).

### 5.7 Debriefs that read the play

New optional fields, consumed by the templated coach and debrief (catalogue C16):

```yaml
debrief: "... {throughput_delta} ... {lead_delta} ..."
debrief_variants:
  poor_fix: "..."            # fact poor_fix:<problem> (catalogue §2.15)
  not_standardised: "..."
  blamed: "..."
debrief_first: "..."          # fork branch done first (catalogue §2.5)
```

The order of preference is `blamed` > `poor_fix` > `not_standardised` > `debrief_first` > `debrief`. A debrief always contains one of the player's numbers and ends on a question or a callback, never a slogan alone.

### 5.8 Anti-patterns (the content checker could flag some)

| Anti-pattern | Check |
|---|---|
| The briefing names the root cause or the bottleneck | manual review; a validator warning when a briefing contains words from `root_cause` |
| A coach insight that points at the answer | manual review (L13) |
| A debrief with no `{placeholder}` | a validator warning for main missions |
| A main briefing without a person | a validator warning: `cast` must be non-empty for main missions |
| A side mission with > 4 clues or > 1 effect | a validator warning |

---

## 6. Content backlog from this audit

### 6.1 Text (content pass, after Merijn's calls)

- **Missions (`content/missions.yaml`):** new `briefing`, `debrief`, `debrief_variants`, `insights`, `beats` and `cast` for all 27, from §3.
- **Coach (§3A):**
  - insights per §3A.3, which fill all 22 of QA finding 24;
  - the extended bank of §3A.2 in `coach.stages`;
  - `safety: true` on `fix_digging_damage`.
- **Renames:** `fix_incomplete_application` → "De onvolledige aanvraag"; `walk_connections` → "Volg het dossier"; `walk_outages` → "Een nacht met de storingsdienst"; `walk_meters` → "Acht adressen"; `look_at_grid_study` → "Het bord van Femke".

### 6.2 Problems and countermeasures

- **`problems_tier1.yaml`:**
  - L5: `revision_backlog.kpi: wip_age`.
  - L6: the oliedrukkabel clue becomes GPLK.
  - L7: localise the silent-meter rates and mark them as estimates.
  - The El Amrani lines in the training_tray clue.
  - The Henk clue becomes relative time.
  - `installer_not_ready.cost_per_week` (estimate).
- **`countermeasures.yaml`:**
  - L8: the tap review uses summer and winter measurements.
  - L9: standard transformer sizes.
  - L10: add `twi_job_instruction`; the videos go to 0.7.
  - `use_it_or_lose_it` gets the ACM wording.
  - Add `temporary_hire`: a real but weak option with a weekly cost, for D19 and for honest choices.
- **`concepts.yaml`:** `standard_work` (L4), `theory_of_constraints` (the five focusing steps, L12), `waste_transport` and `waste_motion` (L11), `capacity_planning` (Kingman, L15), `triage` (kleinverbruik vs grootverbruik).

### 6.3 New files

- `content/people.yaml`: the cast additions of §5.3.
- `content/discoveries.yaml`: §4.3.

### 6.4 Problem-backlog ideas

- **De koude straat** (tier 2): undervoltage on winter evenings after a tap lowered without winter data. A repair-quest candidate for `inverters_tripping`.
- **Petra's ziekteweek** (tier 2): a one-person team as a single point of failure; the skills matrix.

---

## 7. Code needs (for the code agents; not done here)

1. **L1:** the Check returns `lead_time_gain` next to the capacity-based `not_constraint`; the UI shows both lines.
2. **A followed order:** a `WorkOrder.story` tag, set at birth for one connections order; `GameSession` exposes its age, touch hours and delivery day.
3. **A gemba log and minutes per problem;** `par` computed per problem in `tools/build_content.py`.
4. **A coach-ask log.**
5. **`rules/discoveries.gd`,** with save state and the `discovery` event.
6. **Templated debriefs** with `debrief_variants` (catalogue C16 extended).
7. **Validator warnings** of §5.8.
8. **Deep-thinking reward economics (§2.4.1):**
   - R1: the lifecycle cost in the A3, mission rewards × score / 25, and a durability term in the countermeasure score;
   - R2: the borgingsdividend at 90 and 180 days;
   - R3: the overload signal and its trust cost;
   - R4: trust per person, and blaming a person costs it;
   - R5: Henk's deadline is met when the A3 is submitted (QA finding 19);
   - R6: reputation +2 for a fix held 180 days;
   - the `containment` action for `safety: true` missions.
9. **The coach (§3A.1):**
   - C1: rotate the questions per mission plus a 6-line no-repeat memory, saved;
   - C2: `insights` as a list per stage;
   - C3: per-mission `questions` first, then templated KPI questions, then the bank;
   - the conditional lines (overload, fading fix, after a blame).

---

## 8. Questions for Merijn

1. **Act II order:** swap to Graafschade first (crisis), then De revisieberg (the upstream cause)? *Recommendation: yes.* The symptom comes before the cause, the Act II opener is a crisis, and the chain still teaches the linked cause.
2. **The followed El Amrani order** (a small sim tag): build it? *Recommendation: yes.* It is the strongest engagement device for lead time.
3. **Freed monteur hours** from the non-bottleneck fork branch: should `chose:installer_not_ready:*` open a `t3_crew_strategy` option? *Recommendation: yes, as an `any` branch next to the existing ones.* The non-bottleneck fix then earns a later payoff that is honest TOC (operating expense now, a scarce resource later).
4. **`fix_planning_reshuffle`:** trim it to a side-sized mission (4 clues), or promote it to an Act I main between `fix_status_callers` and `fix_done_but_not_closed`? *Recommendation: trim. Kingman returns in Act IV (`t3_stop_starting`).*
5. **Ahmed as trainer:** let a saved Henk (buddy or TWI) speed up train-the-trainer in Act IV? *Recommendation: yes.* It is a path-dependence payoff with a face.
6. **Hidden rewards:**
   - Show silhouettes and act-end hints in the codex (recommended)?
   - Or keep them fully hidden until found?
7. **Avatar cosmetics:** is there an avatar to dress (Phase C)? If not, cosmetics become vitrine objects only, until it exists.
8. **Borgingsdividend (R2):** pay a held fix back at 90 and 180 days (recommended), or lower the standardise cost? *Recommendation: the dividend.* It teaches that sustaining pays over time, which a cheaper button would not.
9. **Overload costs trust (R3):** a pool above 95% for 14 days under the player's experiment loses trust −1. *Recommendation: yes.* It is the only mechanic that makes "burning people out costs" true in the simulation.
10. **Containment (D28, §2.4.1):** add a `containment` action for safety missions as the named exception to long-term-first? *Recommendation: yes, starting with `fix_digging_damage`.*

---

## Sources (new in this doc; the rest are in the GDD and energy-notes)

- ACM — Vergoeding stroomstoring en gasstoring: https://www.acm.nl/nl/node/24620
- ACM — Onderzoek ACM naar stroomstoring Diemen afgerond: https://www.acm.nl/nl/publicaties/publicatie/16370/Onderzoek-ACM-naar-stroomstoring-Diemen-afgerond
- Kamerstuk 29023-185 (stroomstoring Noord-Holland, 2015): https://zoek.officielebekendmakingen.nl/kst-29023-185.pdf
- KWR, Vloerbergh — Kabels en leidingen: wetgeving, veilig graven (H2O 2008; on CROW 500 and test trenches): https://api.kwrwater.nl//uploads/2017/04/Vloerbergh-Kabels-en-leidingen-wetgeving-veilig-graven-en-duurzame-ondergrond-H2O-41-(2008)-10-p.8-9.pdf
- Hoge Raad 13 April 2018, ECLI:NL:HR:2018:772 (the weight of the CROW 500 guideline): https://uitspraken.rechtspraak.nl/details?id=ECLI:NL:HR:2018:772 *(verify)*
- NEN-EN 50160, voltage characteristics of public distribution networks (230 V ±10%) *(standard; verify the edition)*
- IEA — Building the Future Transmission Grid (2025), on transformer lead times *(verify the figure before quoting)*
- Seddon, J. — *Freedom from Command and Control* (2003), failure demand
- Rother, M. — *Toyota Kata* (2009), the five questions
- Goldratt, E. — *The Goal* (1984), the five focusing steps
- Hopp, W. & Spearman, M. — *Factory Physics*, Kingman's approximation
- TWI Job Instruction manuals (War Manpower Commission, 1940s; public domain)
- Goodhart, C. (1975); Strathern, M. (1997), "When a measure becomes a target …"
