# Mission system and full catalogue — design

> Status: design by Claude (2026-10-15), for Merijn to review. Nothing here is built yet. It covers four things: a review of today's mission system, improvements to the system itself, a chronological catalogue of every mission for tiers 1–4 and the IT value streams, and an implementation plan split into independent tasks.
>
> Read for it: `CLAUDE.md` §2, `PLAN.md` (incl. the decisions of 2026-10-15), `docs/GDD.md`, `content/missions.yaml`, `content/problems_tier1.yaml`, `content/countermeasures.yaml`, `content/concepts.yaml`, `game/src/rules/missions.gd`, `mission_def.gd`, `region.gd`, `progression.gd`, `game/src/game/session.gd`, `tools/build_content.py` (`validate_missions`, `check_missions`).

## 0. Summary

- **Story:** six acts after the training week, grouped since 2026-10-16 into **three years with a winter each** (*Drie winters*, PLAN §4.0; §3.1 below and `2026-10-16-drie-winters-arc.md`). You start as the new CI lead in Nova's connections office. You become the CI lead of the whole region (Nova, rural Lindeveld, port town Havenzij) in the year Ruud is seconded to Den Haag, then work on strategy (NTA 8120 audit, investment plan, hoshin). The finale is the succession (`de_opvolger`): you coach your own successor. The IT value streams are their own act, open from tier 3 on, running in parallel.
- **Catalogue:** 96 authored missions: tier 1 has 35 (5 training, the 22 existing missions with their ids kept, 8 new, incl. the winter-1 milestone); tier 2 has 16; tier 3 has 17 (with the Act IV opener `t3_interim_mt`); tier 4 has 15 (the finale `de_opvolger` replaces the placeholder); IT has 13. Repair side quests come on top: they are generated from a template when the player made a poor fix. The missions bring 31 new problems (8 / 8 / 6 / 9).
- **Five forks** (bottleneck vs non-bottleneck), one per act from Act I on, except Act II (it teaches linked causes instead). **Ten deadline missions.** Each non-recovery one closes a named door and leaves another way to solve the problem. Three are **milestones** (day 100, the ACM visit, the NTA 8120 audit): judged on their date, they take no slot.
- **Top system changes:**
  1. Eleven new goal types: `talk_to`, `measure`, `sustain`, `routine`, `map_stream`, `kaizen_event`, `coach`, `kpi_review`, `okr`, `audit`, `strategy`.
  2. Graded *hold* on every fix (sustain-or-decay) plus stagnation drift, both fed back through reopened missions.
  3. Recurring leader-standard-work side quests that slow decay.
  4. People and expert conversations (`content/people.yaml`), plus a sector side quest arc in every tier.
  5. Story and pacing as data: acts, chapters, beats, calendar openings, gates on maturity, reputation and trust, fork metadata, richer missed-deadline consequences. Belts rescaled so the campaign does not hit master black in tier 1.
  6. **Path dependence** (Merijn, 2026-10-15), a first-class mechanism (§2.15):
     - *facts* record what the player did, skipped or chose;
     - strategic options and missions require facts;
     - a poor past fix spawns a *repair* side quest, which reopens options.
- **One bug-like gap to fix first:** a problem can stay open with no mission holding it (§1.2, gap 1).

---

## 1. Review of today's mission system

### 1.1 What works (keep it)

- **The 1 + 3 rule is enforced in code** (`Missions.accept`: `main_active`, `side_full`). Region's `MAX_OPEN` = 4 matches it.
- **Problems arrive only through missions.** Accepting a mission activates its problem. The validator requires a mission for every problem and allows only one solving mission per problem.
- **A faded fix comes back through its mission** (`_reopen_faded`), with no second reward.
- **A deadline is a real event.** The clock starts when the mission opens, taken on or not. `fail_closes` closes countermeasures for good, and the validator demands another way to solve the problem (Henk).
- **The coach works from the player's real state.** The stage comes from the problem's phase (go_see, understand, experiment, reflect). An insight comes every third ask. The coach helps with the main mission and the training days only.
- **The first fork exists** (after `fix_custom_design`). The Check, not the text, shows that the non-bottleneck fix adds no flow.
- **The training week** (five days, skippable) uses a staged `setup` and a 3-day Check. `teaches` hands out glossary cards on accept.
- **Saves and the validator.** Saves restore by id and drop unknown ids. The validator checks references, cycles, an open way in, and that every mission unlocks on XP alone (the hard case).

### 1.2 Gaps, each with a concrete improvement

| # | Area | Gap today | Improvement |
|---|---|---|---|
| 1 | **Problems without a mission** | An `investigate` mission (`look_at_grid_study`) activates its problem and leaves it open when it completes. `abandon()` also leaves the problem open ("Its problem stays"). The open problem then hurts the simulation with no mission holding it, which breaks "problems only through missions". It also takes one of `MAX_OPEN`'s 4 places, so a later `accept` can fail with `problem_unavailable`. | A problem is open only while an active mission names it. When an investigate mission completes, or a mission is abandoned, the problem goes back to sleep (`Region.deactivate`); found clues are kept, because `Region.found` is global. Abandoning during a running experiment is refused (`experiment_running`). Test: complete `look_at_grid_study`, then fill 1 main + 3 sides; every accept succeeds. |
| 2 | **Goal types** | Five goals: walk, investigate, solve, observe, check. After the walk, every campaign mission is `solve`. Nothing asks for a number, for holding a result, for a routine, a conversation, or developing a person. | Eleven new goal types (§2.1). The directives "measure", "people first" and "sustain" each get their own goal type. |
| 3 | **Story pacing** | One linear chain of 11 solves, told only in briefings. There are no chapters, story beats or named people besides Ruud and Henk, and no milestone (the GDD's "first 100 days" is missing). | Acts and chapters as data, `beats` (short lines on accept, on complete, on a day), a named cast (§2.3), and dated milestones that take no slot (`review_100_days`, the ACM visit, the audit). |
| 4 | **Deadlines** | Only Henk has one. It counts from when the mission opens, and his mission opens only after `fix_wrong_joint`, so a player who never takes that side mission never meets the deadline. The clue text says "Henk gaat in maart met pensioen", but the mission says 56 days. A miss can only close countermeasures. | Calendar openings (`opens_on`) and absolute deadlines (`deadline_on_day`) for real events. Richer consequences: `fail_effects` (a cost per week for N weeks, a reputation loss), `fail_opens` (a recovery mission), `fail_closes_missions` (a door). Henk opens on day 42 or after `fix_wrong_joint`, whichever comes first, and the clue text becomes relative. |
| 5 | **Forks** | The fork is implicit: two main missions share a `requires`. Nothing marks it as a choice. The non-bottleneck mission stays on the board forever, and the debrief is the same whichever branch came first. | Fork metadata: `fork: {group, role: bottleneck \| non_bottleneck}`. The board shows the pair as a choice. A debrief variant (`debrief_first`) and the coach's reflect question refer to the other branch. **A content test proves each fork's roles on the real network** (§4, C15). |
| 6 | **Rewards** | XP and budget only, the same whatever the result. Mission XP alone (≈15,000 in tier 1, plus up to 250 per problem) passes master black (12,000) inside tier 1, so the belt curve is spent before tier 2. | Rewards can also carry `reputation`, `trust: {team: n}`, `unlocks` (a tool or feature: VSM view, kaizen event, OKR) and cards. Belts are rescaled (§2.13). |
| 7 | **Side-quest variety** | Every side mission is a walk or a full PDCA solve. A full solve is not "small", which the rule asks side missions to be. | New small side types: expert conversations, routines (leader standard work), sustain goals, coaching a team lead, event preparation. Problem-solving sides stay, but most new sides are smaller. |
| 8 | **Training week** | Works (open items are in PLAN.md: the fade does not show in the numbers; Friday can start on a Sunday). The week never shows the side slot or an expert. After it, `walk_connections` completes without the player doing anything. | Friday's debrief hands out the first side quest, `talk_netplanner`: it shows side slots and an expert conversation, and gives the first sector card. `walk_connections` stays the story stand-in until the campus exists, then becomes a real walk. |
| 9 | **Decay and stagnation** | A fix is either kept forever (standardised) or gone after `decay_days`. Merijn's rule (2026-10-15) asks for decay graded by how strong the sustaining habits are, and for drift when improvement stops. The reopened mission shows its first-time briefing, as if nothing had happened. | A graded *hold* per fix, slowed by habits (standard work, routines, the board, a coached team), plus a stagnation multiplier (§2.8). A reopened mission gets its own text (`reopen`), a "Terugval" lane on the board, and the earlier countermeasure shown in the A3. |
| 10 | **KPI board** | It unlocks only at the last tier-1 mission. Quarterly reviews are events, not missions. OKRs, which are a core directive, appear nowhere. | Tier 1 introduces the board through `first_kpi_review`. Tier 2 brings recurring `lsw_kpi_review` side quests and the region's first OKR (`t2_first_okr`). Tier 4 cascades OKRs with hoshin. `measure`/`sustain`/`okr` goals put numbers in the missions themselves. |
| 11 | **Coach** | Generic stage questions plus one insight per mission. The coach never mentions a number. | Templated questions that read the main mission's KPI ("De doorlooptijd is nu {value} dagen; wat is je doel?"). During an experiment, the five Kata questions in order. A reflect question that refers to the fork. The coach still never coaches side missions. |
| 12 | **Unlock gates** | Missions and belt only. Region maturity and trust exist but gate nothing. | `requires.maturity`, `requires.reputation`, `requires.trust {team: n}`, and calendar openings (§2.4). |
| 13 | **Sector depth** | Merijn (2026-10-15): cards, an expert conversation and a sector side quest. Only the cards exist. | `content/people.yaml` with experts and topics, the `talk_to` goal, and a sector side quest arc in every tier (§2.10). |
| 14 | **Story events** | Storm week, ACM visit and NTA 8120 audit are listed in PLAN.md but unbuilt. | Events come through missions. A mission may carry `event` effects (source `event:<id>`) for a time window, so the storm itself arrives through its mission (§2.12). |
| 15 | **Region maturity** | Computed, but invisible and never reported falling, although a faded fix lowers it (its state resets). | Maturity gates the tiers. A drop raises a `maturity_dropped` event, and the coach names it. Missions already done stay done. |

---

## 2. Improvements to the system

### 2.1 Goal types

The existing five stay. New ones:

| Type | Fields | Done when | Teaches | Rules support needed |
|---|---|---|---|---|
| `talk_to` | `person`, `topics` (n, default 1) | n topics finished with that person through open questions (a closed question gives the short answer; a blaming one costs trust) | sector knowledge, respect for people | `People` + `Conversation` (new), `content/people.yaml` |
| `measure` | `stream`, `kpi`, `op` (`<=`/`>=`), `target`, `window_days` | the KPI over the last `window_days` meets the target while the mission is active | measuring, leading vs lagging | `Region.measures` over a window (exists for a place; add per stream) |
| `sustain` | `stream`, `kpi`, `op`, `target`, `weeks` | the target is held for `weeks` consecutive weekly samples (a missed week resets the count) | sustain or decay | weekly sample in `Missions.update` |
| `routine` | `kind` (`gemba_walk` \| `dagstart` \| `audit` \| `5s`), `places`, `tool?`, `every_days`, `times` | `times` visits, each inside its own cadence window | leader standard work | observe-like counting with windows; feeds the habit support (§2.8) |
| `map_stream` | `stream`, `measure` (`queue_count` \| `time_study`) | every work step measured with that tool | value stream mapping | unlocks the stream's VSM view (Phase D) |
| `kaizen_event` | `place`, `days` (3–5) | a kaizen event held at the place (the team's hours are blocked `days`), and its short Check shows a gain at the step | kaizen, bottleneck focus | kaizen effects per step kind (new content: modest standard-work gains, estimates) |
| `coach` | `person`, `sessions` | `sessions` coaching-kata sessions held: the player asks the five questions in order; the NPC's own small experiment runs in the simulation | coaching kata, people first | `Conversation` with the Kata script; the NPC's experiment as a small countermeasure |
| `kpi_review` | `reviews` (n) | n quarterly KPI-board reviews held (`Region.kpi_review`) | KPIs, Goodhart | exists (KpiBoard); count reviews |
| `okr` | `objective` (Dutch), `key_results: [{stream, kpi, op, target}]`, `quarter_days` (91) | at the quarter's end, at least 0.7 of the key results met (the usual OKR convention) | OKRs | quarter clock; uses `measure` |
| `audit` | `standardised` (n), `problems` | on the audit day: at least n fixes still holding above 0.8 and the named problems resolved | NTA 8120, sustaining | reads hold (§2.8) |
| `strategy` | `options: [{id, name, effects, cost, needs, preparation}]`, `horizon_days` | the player chooses among the options **unlocked now** (§2.15). Each unlocked option's future is forecast on a network copy (the `KpiBoard.forecast` pattern), and the chosen one is applied and paid. No option is marked correct; the forecast judges. | systems thinking, capacity planning, path dependence | reuse `NetworkState.copy`; facts (§2.15) |

`solve` gets an optional `standardise: true`: the Act must standardise. `walk`, `investigate`, `observe` and `check` stay as they are.

### 2.2 Acts, chapters, arcs, story beats

New mission fields:
- `act` (0–6);
- `chapter` (a Dutch title on the board);
- `arc` (a side chain, e.g. `sector`, `henk`, `people`);
- `beats`: a list of `{on: accepted | completed | failed | day, day?, who, text}`, short lines a character says (a toast or card in the UI). They carry the story between missions without new mechanics.

The board shows the act title once, when its first mission opens: a title card from Ruud.

### 2.3 Cast (people.yaml)

Fictional names. Each person has a role, a place and topics. Team leads are the people the player coaches. Experts carry the sector side quests.

| id | Name | Role | Place | Appears |
|---|---|---|---|---|
| `ruud` | Ruud Hoekstra | Directeur Netbeheer regio Zuidmark, your coach | Directie & Obeya | throughout |
| `sanne` | Sanne Bakker | teamleider Intake | connections.intake | Acts I, III (coached) |
| `joost` | Joost van Dijk | teamleider Werkvoorbereiding | connections.design | Acts I, IV (coached) |
| `marco` | Marco Peters | teamleider Monteurs | connections.execution | Acts I–III |
| `henk` | Henk Verbeek | senior monteur, 40 years at Voltana | outages.locate | Act I (deadline) |
| `esra` | Esra Yilmaz | teamleider Klantcontactcentrum | customer_contact.answer | Act I |
| `femke` | Femke de Wit | netplanner, Netstrategie (expert) | connections.grid_study | Acts I, II, IV (sector) |
| `linda` | Linda Jansen | planner | connections.planning | Acts I, III |
| `kees` | Kees Mulder | operator Bedrijfsvoeringscentrum | outages.locate | Act III |
| `jeroen` | Jeroen Dekker | adviseur regulering (expert: ACM, Energiewet) | Directie & Obeya | Act III (sector) |
| `thomas` | Thomas Visser | accountmanager grootzakelijk | congestion.offer | Acts II, IV |
| `ingrid` | Ingrid Bos | assetmanager (expert: NTA 8120, asset health) | Directie & Obeya | Act V (sector) |
| `noor` | Noor Hendriks | product owner veldapp | IT | Act VI |
| `bas` | Bas Kuipers | release train engineer (expert) | IT | Act VI (sector) |
| `monique` | Monique de Ruiter | directeur Financiën | Directie & Obeya | Act IV (the interim MT), Act V |
| `lotte` | Lotte Smit | CI-lead regio Zuidmark, external hire | connections.intake | finale, only if the player picks her (drie-winters §8) |

### 2.4 Unlock gates

`requires`:
- `missions`, `belt` (as today);
- `maturity` (1–4, `Region.maturity`);
- `reputation` (0–100, §2.7);
- `trust: {team: n}` (−2..1; coaching a team lead needs that team's trust ≥ 1);
- `any_of` (one of these missions done; used after a fork).

`opens_on`: `{day: n}` (days of play), `{season: winter | storm | summer}` (the first such season after the other requires are met; winter = 1 Dec–end Feb, storm = 1 Oct–31 Mar, summer = Jun–Aug; drie-winters §1), `{day_before: <dated beat>, days: n}`, or a combination. A mission with `opens_on` opens on that date whatever the player is doing. That makes real events independent of the player's route (Henk, storm, heatwave, audit).

A gate only decides when a mission opens. A mission that is done stays done, even if maturity later falls.

### 2.5 Forks as data

```yaml
fork: {group: t1_after_design, role: bottleneck}   # or non_bottleneck
```

- **Validator:** a group has exactly one bottleneck and at least one non-bottleneck mission, all `kind: main`, with the same `requires`. What follows the fork requires the bottleneck branch, or `any_of` both.
- **Board:** the pair is shown side by side as a choice ("Twee teams vragen om je aandacht").
- **Coach:** a fork mission's `go_see` insight asks where the work waits longest. Its `reflect` insight asks whether more work flows through per week. `debrief_first` is the debrief when this branch came first.
- **Fork honesty test (content):** on the real network, the bottleneck problem's best countermeasure raises the stream's throughput (or, for lead-time streams, lowers p85 lead time) at least 3× more than the non-bottleneck one, and the non-bottleneck Check carries `not_constraint`. If the measure disagrees, the content is wrong, not the test.

Forks in the catalogue:
1. `fix_incomplete_application` vs `fix_installer_not_ready` (existing);
2. `fix_on_call_far` vs `fix_shift_handover`;
3. `fix_underground_crowding` vs `fix_uneven_release`;
4. `fix_ls_grid_blind` vs `fix_grid_losses_theft` (the non-bottleneck one saves money but adds no flow, a different lesson);
5. `fix_test_env_queue` vs `fix_code_review_wait`.

### 2.6 Deadlines and lasting consequences

| Field | Meaning |
|---|---|
| `deadline_days` | as today: days from when the mission opens |
| `deadline_on_day` | an absolute day of play (the MT's day-100 review) |
| `fail` | the Dutch text, as today |
| `fail_closes` | countermeasures closed for good, as today (validator: another way stays open) |
| `fail_closes_missions` | missions that will never open (a door: e.g. the sensor pilot after a failed audit). Validator: none of them is the only mission solving a problem. |
| `fail_opens` | a recovery mission (e.g. `acm_improvement_plan`) |
| `fail_effects` | `{cost_per_week, weeks}` and/or `{reputation: -n}`. Never a lasting KPI penalty beyond the event itself, and never game over. |

Every deadline mission except a recovery mission closes a door *and* leaves the problem solvable. The catalogue has ten: Henk; Honderd dagen; Code oranje; Hitte in het trafohuisje; De ACM komt langs; Het opleidingscentrum zit vol; Stikstof op het tracé; De audit; and two recovery missions (Een plan voor de ACM, De heraudit), which only cost reputation.

**Milestones** (`kind: milestone`, new) are dated reviews. Each opens on its own trigger, takes no main or side slot, can't be accepted or abandoned, and is judged on its deadline day by its `measure` or `audit` goal. It brings no problem, so the 1 + 3 rule and "problems only through missions" are untouched. The coach does not coach a milestone, but the main mission's insights may point at it ("Wat wil je de ACM over acht weken laten zien?"). Milestones keep the story's dates from blocking the main slot for weeks.

### 2.7 Rewards, reputation, trust

`rewards: {xp, budget, reputation, trust: {team: n}, unlocks: [feature]}`. Features: `vsm_view`, `kpi_board` (still by the Obeya countermeasure), `kaizen_event`, `okr`, `strategy`, `region_lindeveld`, `region_havenzij`, `it_campus`.

**Reputation** (region-level, 0–100, start 30; all numbers estimates) is how the MT sees the CI lead:
- **+5** for a completed main mission;
- **+2** for a side mission or a routine;
- **+3** for a Check with flow score ≥ 4;
- **−10** for a missed deadline;
- **−1** for a blaming question;
- **−5** when the region enters a bad period.

It gates the region-wide and strategic work (tier 3 needs ≥ 50, tier 4 ≥ 65). Small missions can always rebuild it, so it never locks the game.

Trust stays per team. Coaching a team lead needs that team's trust ≥ 1, earned with open questions and repairs.

### 2.8 Sustain or decay, stagnation, reopened missions

**Hold.** Each resolved problem has a hold *h* ∈ [0, 1], starting at 1. While it is resolved, the fix works at strength *h*: `Pdca.treated_effects` is computed with the countermeasure's effectiveness × *h* (re-applied weekly, not every tick). So a fading fix shows up gradually in the numbers. This also fixes the training-week open item, where the fade did not show.

**Decay per day:**

`Δh = − base × (1 − support) × drift`, where:

- `base`:
  - not standardised: chosen so that *h* reaches 0.5 at the countermeasure's `decay_days` (today's behaviour, now gradual);
  - standardised: a half-life of 365 days (estimate).
- `support` ∈ [0, 0.8], the sustaining habits at the problem's team. Each adds 0.2 (estimates):
  - standard work (the Act standardised);
  - visual management (a `dagstart` routine at that team in the last 14 days);
  - leader routine (a `gemba_walk` or `audit` routine at that place in its cadence);
  - a steering KPI (a KPI on the board whose kind matches the problem's KPI);
  - a coached team (its lead completed a `coach` mission).
- `drift`, the stagnation multiplier: 1, rising linearly to 2 between 42 and 84 days since the last improvement (a passed Check or a completed routine), then flat. Estimates.

**Reopen.** When *h* < 0.5 the problem goes dormant (today's `_recur`) and its mission reopens:
- The board shows the `reopen` text in the "Terugval" lane.
- No XP or budget the second time; reputation +2 on completion.
- The A3 shows the earlier countermeasure as "eerder geprobeerd, weggezakt na N dagen".
- A reopened main mission stays a main mission, so the player faces a real choice between pushing on and fixing the regression.

**Stagnation alarm.** When drift first passes 1, the side mission `stagnation_alarm` opens ("Stilstand is achteruitgang"). Its goal: any passed Check or routine within 21 days. It brings no problem, so the rule holds: drift only weakens fixes that already exist.

**Maturity can fall** when fixes fade. A `maturity_dropped` event tells the player, and higher-tier countermeasures half-work again (`Pdca.effectiveness`): *build the foundation first*.

### 2.9 Leader standard work: recurring side quests

`recurring: {every_days: n}`: after completion the mission becomes available again n days later. XP only the first time; after that it pays in *support* (§2.8) and reputation +2. Each takes a side slot only while accepted, and one visit or review completes it. Together they make the real trade-off of leader standard work: three side slots, shared between routines and side problems.

| id | Title | Cadence | Goal | From |
|---|---|---|---|---|
| `lsw_gemba_round` | De gemba-ronde | 7 days | `routine gemba_walk` at 3 places of a stream | Act I |
| `lsw_van_round` | Bussenronde | 28 days | `routine 5s` with `material_check` at outages.joint and connections.materials | Act II |
| `lsw_kpi_review` | Kwartaalreview | 91 days | `kpi_review 1` | Act III |
| `lsw_layered_audit` | Gelaagde audit | 28 days | `routine audit` at the places of 3 standardised fixes | Act IV |
| `lsw_catchball` | Catchball | 91 days | `routine dagstart` at every department on the board, with the OKR | Act V |
| `lsw_system_demo` | Systeemdemo | 14 days | `routine` at the IT stream's demo place | Act VI |

### 2.10 Expert conversations and the sector side quest (Merijn, 2026-10-15)

**Conversations.** A conversation with a person has topics. Each topic has an `open` reply (the story, a concept card and sometimes a *sector clue*) and a `closed` reply (one line). A blaming question costs that team's trust, as at the gemba.

A sector clue is a fact about the sector (e.g. "Een MSR is ontworpen op 1,5 kW gelijktijdig per woning; een warmtepomp vraagt er 3"). It can be used as A3 evidence only when its problem is active. A clue never activates a problem.

The texts come from `concepts.yaml` sources or are marked as estimates there.

**Sector arc**, one small side quest per act (`arc: sector`):

| Act | Mission | Expert | Topics |
|---|---|---|---|
| I | Waarom is het net vol? | Femke de Wit (netplanner) | netcongestie, MSR, simultaneity, the queue |
| II | De congestiekaart | Thomas Visser + Femke | GOTORK, non-firm and time-bound transport rights, the congestion map |
| III | Wie houdt toezicht? | Jeroen Dekker (regulering) | ACM, the connection term and its reference, the Energiewet, outage compensation |
| IV | Een energiehub op de Kanaalzone | Thomas Visser | energy hubs, group contracts, cable pooling |
| V | Hoe gezond is een kabel? / Het net van 2035 | Ingrid Bos | NTA 8120, asset health, risk-based maintenance, II3050 scenarios |
| VI | Wat is een release train? | Bas Kuipers | ART, PI planning, DORA |

### 2.11 Measuring: KPI board, OKRs, the Check

Missions name numbers in four ways:
1. `measure`/`sustain` goals carry a target.
2. Every `solve` mission's briefing names the symptom in a number the player can verify at the gemba. The content test checks that the number is true on the network.
3. The board shows each active mission's KPI as a line.
4. OKRs arrive in tier 2 (one region objective, 2–3 key results). Hoshin in tier 4 cascades them to departments.

The Check already judges the A3's KPI prediction. The coach's templated questions (§1.2, gap 11) read the same numbers.

### 2.12 Events through missions

A mission may carry `event: {effects, at: deadline | accepted, days}`. The effects go on the network as `event:<mission>` for `days` (e.g. storm: outage demand ×3 for 4 days, an estimate), whether or not the mission was taken on. Taking it on is the chance to prepare. Events in the catalogue:
- *Code oranje* (winter storm);
- *Hitte in het trafohuisje* (summer heat);
- *De ACM komt langs* (a measurement on a date);
- *De audit* (NTA 8120).

### 2.13 Belts and XP pacing

**Today.** Tier 1's missions give ≈15,100 XP. Problems give up to 25 × 10 × tier each (`Pdca.xp_for`). Master black (12,000) arrives inside tier 1.

**Proposed thresholds (estimates, checked by the validator's XP-reachability pass and a new pacing test):**

| Belt | XP | Reached around |
|---|---|---|
| white | 0 | start |
| yellow | 2,000 | Act I, after the fork |
| green | 6,000 | Act II, before `fix_grid_study_queue` (which needs green) |
| black | 30,000 | middle of Act III |
| master black | 110,000 | Act V |

Mission XP per tier: tier 1 as today; tier 2 mains 1,600–2,400; tier 3 2,600–3,400; tier 4 3,600–5,000; IT 2,600–3,400. Side missions get about 40% of a main.

### 2.14 Regions and areas

Tiers 1–4 play in one region, Zuidmark, with one network. Tier 3 adds two *areas* as content in that network: new pools and streams for Lindeveld (rural: long drives, solar fields, farms) and Havenzij (a port town: crowded streets, an industrial canal zone with congestion). This needs no multi-region code. Separate regions in other provinces stay a later Phase F item. IT problems carry `track: it` and have their own maturity, so the grid's maturity does not depend on IT play.

### 2.15 Path dependence: facts, prerequisites and repair quests (Merijn, 2026-10-15)

Merijn's rule: what you can decide depends on what you did before.
- A decision that needs preparations you didn't make can't be made.
- You can pivot, but to get back on the "right" path you must first do certain other things.
- Example: a poor countermeasure in a main mission later brings a side quest to fix it. Doing that side quest opens different strategic options than skipping it.

**Facts.** The region keeps a set of facts, saved with the missions. Most are derived automatically from play, so content can't forget to set them:

| Fact | Set when |
|---|---|
| `done:<mission>` / `failed:<mission>` | the mission completes / its deadline passes |
| `skipped:<mission>` | the mission was still open when a `skip_when` event happened: its act ended, or a later mission named it in `closes_on_accept` |
| `chose:<problem>:<cm>` | the Act closed the problem with that countermeasure (kept until it is replaced) |
| `standardised:<problem>` | the Act standardised it |
| `poor_fix:<problem>` | the problem was resolved with a countermeasure whose fit is at least 0.2 below the problem's best, or with a wrong root cause in the A3 (estimate thresholds) |
| `repaired:<problem>` | its repair quest completed (removes `poor_fix`) |
| `fork_first:<group>:<mission>` | that fork branch was completed first |
| `flag:<name>` | content sets it explicitly: `sets_flags` on a mission's completion or failure, or on a strategy option once chosen |

Maturity and reputation are read live (`maturity>=3`, `reputation>=60`).

**Needs.** One expression, used in three places:
- strategic options: `needs`;
- missions: `requires.facts`;
- countermeasures: `needs` (e.g. `acm_pilot_time_bound` needs `none: [failed:acm_visit]`, which replaces an ad-hoc `fail_closes`).

```yaml
needs: {all: [done:fix_training_capacity, maturity>=3], any: [chose:transformer_wait:framework_contracts, repaired:transformer_wait], none: [failed:nta8120_audit]}
```

**Locked options are visible, not explained.** A strategic option whose needs are not met shows as "niet voorbereid", with its authored `preparation` hint. The hint is a Dutch line that points at a place or team, never at a mission or the answer (e.g. "Hiervoor moet de bestelling van trafo's anders geregeld zijn."). The player works out the route; the coach asks about it only in the main mission's reflect stage.

**Pivoting is always possible.** The validator checks every option and every fact-gated mission:
- each `all`/`any` branch has at least one fact that is still obtainable after any failure or skip. Something like `done:` of a recurring mission, `repaired:` of a problem whose repair quest exists, or a flag set by a mission that can't be closed;
- every `strategy` goal has at least one option with no needs (the baseline), so a decision can always be made.

A door can close one route (a missed deadline), but another route back always remains. That is "setbacks, never game over" applied to strategy.

**Repair side quests.** One template in `missions.yaml` (`repair_template`), instantiated per problem as `repair_<problem>`. It opens `repair_after_days` (42, an estimate) after `poor_fix:<problem>` is set, and only once the weak fix shows in the problem's KPI (worse than the best countermeasure's forecast by 5% or more). So the player meets it as a measurable symptom, not as a verdict.
- **Text:** a generic briefing/debrief with the problem's name. Key problems may carry an authored override (`repair: {briefing, debrief}` on the problem).
- **Goal (`rework_fix {problem}`):** a short A3 (cause, countermeasure, prediction) that swaps the running countermeasure for a better one. The Check (14 days) must show the gain. The problem's own effects do not come back while you rework.
- **Result:** `repaired:<problem>` and `chose:<problem>:<new cm>`, small XP, reputation +2.
- **Not taken on:** the quest stays available; no deadline unless authored. Skipping it is legitimate, but the options that need the better fix stay locked.
- It is a side quest, so it takes a side slot and the coach does not help: the 1 + 3 rule holds. Its problem is resolved, not open, so "problems only through missions" holds too.

**Where it shows in the catalogue:**
- Repair quests from tier 1 on.
- Fact-gated countermeasures (the ACM pilot, Henk's buddy system).
- Two strategy decisions: `t3_crew_strategy` (Act IV, a first taste) and `t4_investment_plan` (Act V).

### 2.16 Schema sketch

```yaml
  - id: fix_on_call_far
    name: De verste storingsdienst
    kind: main
    tier: 2
    act: 3
    chapter: Zichtbaar maken
    requires: {missions: [fix_cause_unknown], belt: 2, maturity: 2}
    fork: {group: t2_outage_time, role: bottleneck}
    goal: {type: solve, problem: on_call_far}
    briefing: "..."
    debrief: "..."
    debrief_first: "..."          # this fork branch was done first
    reopen: "..."                 # the fix faded; the mission is back
    beats:
      - {on: accepted, who: kees, text: "..."}
    teaches: [waste_transport, lead_time]
    rewards: {xp: 2000, budget: 15000, reputation: 5, trust: {on_call: 1}}
    insights: {go_see: "...", reflect: "..."}
  - id: prep_storm_week
    kind: side
    opens_on: {season: winter}
    deadline_days: 21
    event: {at: deadline, days: 4, effects: [{target: outages, property: demand, value: 2.0}]}
    fail_closes: [mutual_aid_agreement]
    fail_effects: {reputation: -10}
    recurring: null
```

---

## 3. The catalogue

### 3.1 The story arc: *Drie winters* (reworked 2026-10-16)

The acts and their missions stand. Since PLAN §4.0 (Fable, 2026-10-16) they are grouped into **three years, each with a winter that tests what the player built**. One number runs through all three: the north star `waiting_list`, *de wachtlijst van Zuidmark* (open requests, average wait, and the share of given dates kept), on the HUD from Act II. Full design, dialogs and schema needs: `2026-10-16-drie-winters-arc.md`.

| Year | Act | Title | Tier | Setting | Story | Lean / Kata focus | Missions |
|---|---|---|---|---|---|---|---|
| **1 · Het eerste jaar** (Oct 2026 –) | 0 | Inwerkweek | 1 | connections office | Ruud gives the new CI lead a safe week of Starter Kata. A letter from the El Amrani family is the first thing on his desk. | gemba, bottleneck, PDCA, A3, sustain | 5 |
| | I | De eerste honderd dagen | 1 | Nova: connections, contact centre, field | The team leads ask for more people; you show that the work was made too heavy. **Winter 1, *Voor de vorst*:** on the first frost period (day 70) the game checks whether mevrouw El Amrani's mother is warm. The MT reviews you on day 100. | waste, flow, bottleneck shifts, quality at the source, failure demand | 17 |
| | II | Wat onder de grond zit | 1 | Revisie & GIS, grid studies, congestion | The quiet backlogs (revision, studies, transformers, contracts) turn out to hold up the grid. The waiting list appears on the HUD. Ending: the departments fight over KPIs, and the KPI board is born. | linked causes, external waits in parallel, inventory, KPI alignment | 13 |
| **2 · Het jaar zonder Ruud** | III | Zichtbaar maken | 2 | campus-wide: control room, field, regulation | Ruud: "Problems should not be found by you; the teams should see them." Daily boards, escalation, a heatwave, the ACM's visit, the first OKR. **The act ends with Ruud's secondment** to Den Haag for a year (the farewell talk `ruud_farewell`; the monthly call unlocked). | visual management, daily management, andon, tiered escalation, OKRs, coaching kata | 16 |
| | IV | Flow door de regio | 3 | Zuidmark: Nova, Lindeveld, Havenzij | **Frank Hulshof is interim director.** His first MT (`t3_interim_mt`, a group talk) reads the Frank facts of Acts II–III: a *sponsor* (the Obeya stands, the strategy screen opens early) or a *regime* (a dashboard, the consultancy temptation `t3_consultants`, and the team-led kaizen week as the way back). **Winter 2, *De storm zonder Ruud*:** Code oranje at the control room's escalation board. Then long drives, crowded streets, nitrogen, the technician shortage, the prioritisation framework, and a first strategic choice. Ruud coaches by phone, one Kata cycle a month. | VSM, kaizen events, WIP limits/CONWIP, heijunka, flow across areas; running your own Kata and coaching others | 17 |
| **3 · Het jaar van de opvolger** | V | Het systeem | 4 | the MT and the asset side | Ruud returns and names his last day (1 April, the AOW date). Strategy: one direction (hoshin), the NTA 8120 audit, risk-based maintenance, losses, the flex market, the investment plan, shaped by every earlier choice. **Winter 3, *De opvolger*:** the finale `de_opvolger`; who sits across the table depends on whom you developed (Anouk, Ahmed, Sanne, or Lotte from outside). The last scene is your first Kata question. | hoshin kanri, risk-based maintenance, systems thinking, path dependence, coaching kata | 15 |
| 2–3 (parallel) | VI | Het digitale net | IT (tier 3+) | IT on campus: the field app | The field app the monteurs bypass; releases twice a year; test environments; ARTs and PI planning; DORA. It serves the number: the portal where households register, the app that records the work, the release cadence that decides how fast a fix reaches the street. | value streams in IT, flow of work, SAFe, DevOps, DORA | 13 |

**The winters as fixed points** (drie-winters §1): winter 1's frost period on day 70 (an estimate); the first storm in the first storm season (October–March, KNMI) after Ruud's secondment; Ruud's last day on the first 1 April at least 240 days after Act V opens. Acts are paced by the player; the winters are not.

**The antagonists are forces, never people:** the queue (it grows by itself: drift), the number (the output KPI the directie looks at: Frank's pressure), and time (Henk retires, Ruud retires, seasons come).

Act VI opens after `t3_map_region` and runs in parallel with Acts IV–V. It is its own main chain, so the player chooses which main mission to take on next. That is prioritising, though not a bottleneck fork.

**Difficulty curve:**
- Clues: problems move from obvious to subtle to hidden, with more red herrings and deeper clue chains.
- Causes: they move further from where the symptom shows (a crisis two departments downstream), and later into other areas or external parties.
- Indicators: from leading to lagging, and the gap widens.
- Pressure: forks and deadlines become more frequent.
- Countermeasures: a higher tier needs the maturity built earlier.

Notation:
- **Kind:** M main, S side, T training, R recurring side, Ms milestone (no slot, judged on its date).
- **Gates:** belt Y/G/B/MB, maturity M2–M4, reputation rep≥n, and `opens_on`.
- **Rewards:** XP · € (k = thousand) · rep.
- **B / N:** fork bottleneck / non-bottleneck.
- *(new)* marks a new mission.

### 3.2 Act 0 — Inwerkweek (tier 1, training)

Unchanged ids and goals. Improvements: Friday hands out `talk_netplanner` (side slot plus expert); the PLAN.md open items (fade in the numbers via hold, §2.8; Friday weekday).

| id | Titel | Kind | Requires | Goal | Problem | Rewards | Teaches |
|---|---|---|---|---|---|---|---|
| `training_mon` | Rondleiding | T | — | observe intake, design | — | 50 | netbeheerder, aansluiting, aansluittermijn |
| `training_tue` | Kijken zonder oordeel | T | mon | observe design ×2 | — | 50 | gemba, five_whys, eight_wastes |
| `training_wed` | Waar zit de stapel? | T | tue | observe queue_count | — | 50 | flow, wip, bottleneck_focus, netcongestie |
| `training_thu` | Een klein experiment | T | wed | check | training_tray (practice) | 50 | PDCA, A3, leading_lagging |
| `training_fri` | Borgen of laten wegzakken | T | thu | solve | training_tray | 50 · hands out `talk_netplanner` | standard_work, improvement_kata |

### 3.3 Act I — De eerste honderd dagen (tier 1)

**Chapter "De stapel":** custom design, then the fork. **Chapter "De telefoon":** failure demand and close-out. **Milestones:** winter 1, *Voor de vorst* (day 70), and day 100. Side missions open around the field streams and Henk.

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline → door | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `walk_connections` | Eerste week: loop de stroom | M | training_fri | walk connections | — | — | 300 (story; done after the week) | gemba, flow, lead_time |
| `fix_custom_design` | De stapel bij Werkvoorbereiding | M | walk_connections | solve | custom_design | — | 600 · €10k · rep 5 | waste_overprocessing, standard_work |
| `fix_incomplete_application` | Het knelpunt verschuift | M | fix_custom_design | solve | incomplete_application | **B** (t1_after_design) | 700 · €8k | quality_at_the_source, poka_yoke |
| `fix_installer_not_ready` | Meterkast niet gereed | M | fix_custom_design | solve | installer_not_ready | **N** (t1_after_design) | 500 · €5k | readiness_check, theory_of_constraints |
| `fix_status_callers` | De telefoon staat roodgloeiend | M | fix_incomplete_application | solve | status_callers | — | 800 · €8k | failure_demand, value_demand |
| `fix_done_but_not_closed` | Klaar maar niet af | M | fix_status_callers, Y | solve | done_but_not_closed | — | 900 · €8k | batching, one_piece_flow, ean_code |
| `review_100_days` *(new)* | Honderd dagen | Ms | walk_connections; `opens_on: {day: 70}` | measure connections on_time ≥ 0.90 over 28 d, judged on day 100 | — | `deadline_on_day: 100` → the MT hires two temps at Werkvoorbereiding: `fail_effects` €2.5k/week × 13 (estimate: 2 × 36 h × €35/h), rep −10; door: the €15k "verbeterfonds" reward is gone | 1,000 · €15k · rep 10 | kpi, lead_time, leading_lagging |
| `winter_el_amrani` *(new, 2026-10-16)* | Voor de vorst | Ms | walk_connections; `opens_on: {day: 49}` | `story_order el_amrani`: delivered, **or** the heat pump on the existing connection (`agreed:el_amrani_fourth_call:check_existing_connection`), by day 70 | — | `deadline_on_day: 70` (the first frost period, estimate) → the mother stays with her other daughter; rep −2; `flag:el_amrani_cold_winter` (Act IV thread) | 300 · rep 3 | lead_time, customer_value, warmtepomp_aansluiting (new) |
| `walk_outages` | Mee met de storingsdienst | S | walk_connections | walk outages | — | — | 200 | gemba |
| `walk_meters` | Mee met de meterwisselaars | S | walk_connections | walk meters | — | — | 200 | gemba |
| `talk_netplanner` *(new)* | Waarom is het net vol? | S | training_fri | talk_to femke, 2 topics | — | — | 150 · trust grid_analysts +1 | netcongestie, middenspanningsruimte, transformator |
| `fix_permits_in_batches` | Vergunningen in batches | S | fix_custom_design | solve | permits_in_batches | (a side non-bottleneck: Check says "not the constraint") | 400 · €4k | batching |
| `fix_wrong_joint` | De verkeerde mof in de bus | S | walk_outages | solve | wrong_joint_in_van | — | 400 · €4k | 5s, kanban, waste_transport |
| `fix_planning_reshuffle` | De planning die nooit klopt | S | walk_outages | solve | planning_reshuffle | — | 500 · €5k | heijunka, capacity_planning |
| `fix_not_at_home` | Niet thuis | S | walk_meters | solve | not_at_home | — | 400 · €4k | customer_value, waste_transport |
| `save_henks_knowledge` | Henks kennis | S | fix_wrong_joint **or** `opens_on: {day: 42}` | solve | knowledge_drain | 56 d → closes `skills_matrix_buddy` (videos still work) | 600 · €6k | monteurstekort, waste_skills, respect_for_people |
| `lsw_gemba_round` *(new)* | De gemba-ronde | R | fix_custom_design | routine gemba_walk, 3 connections places, every 7 d | — | — | 150 first time; support | leader standard work (new concept) |

Improvements to existing Act I missions:
- `teaches` on every mission (columns above).
- Fork metadata, and a `debrief_first` for the non-bottleneck branch.
- `reopen` texts.
- Henk's calendar opening; the clue "Henk gaat in maart" becomes "over twee maanden".
- `fix_permits_in_batches` keeps its side role as a deliberate non-bottleneck lesson.

### 3.4 Act II — Wat onder de grond zit (tier 1)

**Chapter "De kaart klopt niet":** revision, then digging damage, a linked cause. **Chapter "Het net is vol":** studies, transformers, contracts. **Chapter "Wat je meet":** silo KPIs, then the board.

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline → door | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `fix_revision_backlog` | De revisieberg | M | fix_done_but_not_closed | solve | revision_backlog | — | 900 · €10k | waste_inventory, klic_melding |
| `fix_digging_damage` | Graafschade | M | fix_revision_backlog | solve | digging_damage | — | 1,000 · €12k | systems_thinking, root_cause |
| `fix_grid_study_queue` | De netstudie-wachtrij | M | fix_digging_damage, G | solve | grid_study_queue | — | 1,200 · €12k | triage, netcongestie |
| `fix_transformer_wait` | Wachten op de trafo | M | fix_grid_study_queue | solve | transformer_wait | — | 1,300 · €12k | transformator, wip |
| `fix_unused_capacity` | Gereserveerd maar ongebruikt | M | fix_transformer_wait | solve | unused_capacity | — | 1,400 · €12k | netcongestie, acm, gotork (new) |
| `fix_silo_kpis` | KPI's die elkaar bevechten | M | fix_unused_capacity | solve | silo_kpis | — | 1,500 · €12k · board via Obeya | kpi_alignment, obeya |
| `first_kpi_review` *(new)* | Het eerste kwartaal | M | fix_silo_kpis | kpi_review 1 (the first real review after the baseline) | — | — | 800 · €8k · rep 5 · unlocks tier 2 | kpi, leading_lagging, okr |
| `look_at_grid_study` | Een kijkje bij Netstrategie | S | fix_status_callers | investigate grid_study_queue, 2 | (problem sleeps again after; gap 1) | — | 250 | five_whys |
| `fix_silent_meter` | De zwijgende meter | S | fix_not_at_home | solve | silent_meter | — | 400 · €4k | jidoka |
| `fix_inverters_tripping` | Omvormers die afschakelen | S | fix_silent_meter | solve | inverters_tripping | — | 400 · €4k | energietransitie |
| `sector_congestion_map` *(new)* | De congestiekaart | S | talk_netplanner, fix_grid_study_queue | talk_to thomas, 2 topics + observe congestion.capacity_queue | — | — | 300 · trust key_accounts +1 | gotork, non_firm (new) |
| `lsw_van_round` *(new)* | Bussenronde | R | fix_wrong_joint | routine 5s, material_check at outages.joint + connections.materials, every 28 d | — | — | 150; support for van stock | 5s, visual_management |
| `stagnation_alarm` *(new, system)* | Stilstand is achteruitgang | S | opens when drift > 1 (any tier) | any passed Check or routine within 21 d | — | — | 100 · rep 2 | sustain (new concept: kaizen mindset) |

Act II deliberately has no fork. Its lesson is that causes link across departments (revision feeds digging damage) and that external waits can run in parallel.

### 3.5 Act III — Zichtbaar maken (tier 2)

Gates: `first_kpi_review`, maturity 2, belt green.

**The act's end (Drie winters):** when `t2_first_okr` is done and `acm_visit` judged, Ruud is seconded to Den Haag. The farewell talk `ruud_farewell` (cannot be ruined) sets `flag:ruud_seconded`, unlocks his monthly call (coach cooldown 28 days, one Kata cycle per call, main quest only) and opens Act IV.

**New tier-2 problems** (`content/problems_tier2.yaml`). Mechanisms marked "exists" use today's levers.

| id | Name | Stream · step | Waste | Mechanism | Grounding | Countermeasures (tier, fit) |
|---|---|---|---|---|---|---|
| `cause_unknown` | Oorzaak: onbekend | outages.repair | defects | daytime outage demand ×1.15 (repeat faults on known weak joints): exists. Estimate. | Nestor outage registration records a cause; backlog idea | cause codes + weekly Pareto (2, 1.0); stop-and-record at closure (1, 0.7); repeat-fault analysis (3, 0.9) |
| `on_call_far` | De verste storingsdienst | outages.locate → repair (travel) | transport | on-call travel wait +40% (estimate); `cost_per_week` for outages > 4 h | grid code: on site within 2 h, compensation after 4 h (GDD, verify the amount) | standby locations by fault map (1, 1.0); smaller on-call areas (2, 0.8); `mutual_aid_agreement` with a neighbouring DSO (2, 0.7) |
| `shift_handover` | De overdracht die niet overkomt | outages.locate | overprocessing | locate touch time ×1.2 at shift change: exists. Estimate. | backlog: handovers without notes | handover at the board with a standard (1, 1.0); open-actions list in the control-room system (2, 0.8) |
| `contractor_rework` | Twee keer graven | connections.execution | defects | execution ftr −0.15: exists. Estimate. | contractor model; backlog | first-job inspection with the contractor (1, 0.8); shared standard + feedback loop (2, 1.0); contractor scorecard (2, 0.7) |
| `escalation_hallway` | Escalatie via de gang | connections.design + planning | waiting | wait_time +2 d (blockers wait for the weekly meeting): exists. Estimate. | tiered escalation (GDD tier 2) | tiered escalation with a 24 h rule (2, 1.0); daily stand-up with an andon card (1, 0.7) |
| `safety_stock_calendar` | Altijd net op | meters.reserve_meter | waiting | reorder point set in calendar days: exists (`reorder_point`) | found while tuning the simulation (PLAN backlog) | reorder point in working days (1, 1.0); warehouse two-bin kanban (2, 0.9) |
| `lmra_tickbox` | LMRA als vinkje | connections.execution | overprocessing | touch time +0.25 h; ftr −0.05 (near-miss stops): exists. Estimates. | LMRA practice; Safety Culture Ladder (verify) | task-specific LMRA cards (1, 1.0); stop-the-work andon (2, 0.8) |
| `heatwave_overload` | Hitte in het trafohuisje | outages.report | defects | under the summer event: daytime outages ×1.3 (estimate) | GDD seasons; backlog | peak-load list from smart-meter data (2, 1.0); `preventive_transformer_swap` (1, 0.7); temporary mobile transformers (2, 0.6) |

**Missions:**

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline → door | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `t2_daily_boards` | Het bord aan de muur | M | first_kpi_review, M2, G | routine dagstart at intake, design, planning; 10 times in 21 d | — | — | 1,600 · €12k · rep 5 · support | visual_management, daily_management (new) |
| `fix_cause_unknown` | Oorzaak: onbekend | M | t2_daily_boards | solve | cause_unknown | — | 1,800 · €15k | pareto (new), five_whys |
| `fix_on_call_far` | De verste storingsdienst | M | fix_cause_unknown | solve | on_call_far | **B** (t2_outage_time) | 2,000 · €15k | waste_transport, lead_time |
| `fix_shift_handover` | De overdracht die niet overkomt | M | fix_cause_unknown | solve | shift_handover | **N** (t2_outage_time) | 1,600 · €10k | standard_work |
| `fix_contractor_rework` | Twee keer graven | M | any_of the fork | solve | contractor_rework | — | 2,000 · €15k | quality_at_the_source |
| `fix_escalation_hallway` | Escalatie via de gang | M | fix_contractor_rework | solve | escalation_hallway | — | 2,100 · €15k | tiered_escalation (new), andon (new) |
| `acm_visit` | De ACM komt langs | Ms | fix_contractor_rework | measure connections on_time ≥ 0.85 over 56 d, judged on the visit day | — | 70 d → `fail_opens: acm_improvement_plan`; closes `acm_pilot_time_bound` (an Act IV countermeasure for `non_firm_unused`; others remain); rep −10 | 2,200 · €20k · rep 10 | acm, aansluittermijn |
| `t2_first_okr` | Een doel voor Zuidmark | M | fix_escalation_hallway | okr: 1 objective, 3 KRs, 91 d, ≥ 0.7 met | — | — | 2,400 · €20k · unlocks okr | okr, kpi |
| `fix_safety_stock_calendar` | Altijd net op | S | t2_daily_boards | solve | safety_stock_calendar | — | 700 · €6k | kanban, capacity_planning |
| `fix_lmra_tickbox` | LMRA als vinkje | S | t2_daily_boards | solve | lmra_tickbox | — | 700 · €6k | respect_for_people, standard_work |
| `prep_storm_week` | Code oranje | S | M2; first occurrence also `flag:ruud_seconded`; `opens_on: {season: storm}` (Drie winters: winter 2's climax, with the scene `storm_night_board`) | observe joint stock + on-call plan (material_check at outages.joint, conversation at outages.locate) before the storm | event: outage demand ×2 for 4 d (estimate) | 21 d; the storm comes anyway → closes `mutual_aid_agreement`; rep −10 | 600 · €5k | jidoka, capacity_planning |
| `fix_heatwave_overload` | Hitte in het trafohuisje | S | M2; `opens_on: {season: summer}` | solve | heatwave_overload | 42 d → closes `preventive_transformer_swap`; heat event arrives; rep −5 | 800 · €8k | transformator, energietransitie |
| `talk_regulation` | Wie houdt toezicht? | S | t2_daily_boards | talk_to jeroen, 3 topics | — | — | 400 | acm, energiewet (new, verify), compensatie (new, verify) |
| `coach_intake_lead` | Sanne leert verbeteren | S | t2_daily_boards, trust intake ≥ 1 | coach sanne, 3 sessions | — | — | 700 · rep 3 · support (intake) | coaching_kata, respect_for_people |
| `lsw_kpi_review` | Kwartaalreview | R | first_kpi_review | kpi_review 1, every 91 d | — | — | 300 first time | kpi, leading_lagging |
| `acm_improvement_plan` | Een plan voor de ACM | S (recovery) | only through `fail_opens` | measure connections on_time ≥ 0.85 over 56 d | — | 112 d → rep −5 (no further door) | 600 | acm |

### 3.6 Act IV — Flow door de regio (tier 3)

Gates: `t2_first_okr`, maturity 3, belt black, rep ≥ 50. Lindeveld and Havenzij come in as areas of the same network (§2.14).

**The opener (Drie winters):** `t3_interim_mt`, Frank's first MT as interim director, a group talk whose opening reads the Frank facts (sponsor or regime). The storm (`prep_storm_week`) falls in this year, after Ruud has left. Under the regime the act's big shortcut is `t3_consultants` (Lean-programma 2.0); the way back is a team-led `t3_kaizen_week` with Frank's agreement (`frank_interim`).

**New tier-3 problems:**

| id | Name | Stream · step | Waste | Mechanism | Grounding | Countermeasures |
|---|---|---|---|---|---|---|
| `long_drives` | Een uur rijden per klus | Lindeveld meters.visit / connections.execution | transport | travel as touch time +1 h per job (estimate) | GDD: rural region with long drives | regional satellite depot (3, 1.0); area-day routing (2, 0.8); mobile van stock (2, 0.6) |
| `training_capacity` | Het opleidingscentrum zit vol | monteurs (pool) | skills | headcount ramp limited by trainers; **needs a timed headcount ramp** | 28,000-technician shortage to 2029; training capacity is the bottleneck (GDD) | train-the-trainer (2, 1.0); `apprentice_cohort_september` (3, 0.9); hybrid crews: aankomend monteur does the simple jobs (3, 0.8) |
| `underground_crowding` | Geen plek onder de stoep | Havenzij connections.permit + design | waiting | permit wait +20 d; design ftr −0.1: exists. Estimates. | backlog: ondergrondse drukte | joint street planning with gemeente and utilities (3, 1.0); standard duct designs (2, 0.7); one-dig agreements (3, 0.8) |
| `uneven_release` | De maandpiek | connections.planning | unevenness (mura; teaches as `waste_waiting` + heijunka) | project developers release 200 homes at once; **needs weekly demand patterns** (deferred in Phase A step 3) | estimate | level release with developers (3, 1.0); frozen planning window (3, 0.8) |
| `priority_first_come` | Wie het eerst komt | congestion.capacity_queue | waiting | first come, first served while schools and care wait; **needs priority classes on orders** | prioritisation framework for societal projects, mandatory since 1 Oct 2024 (GDD) | prioritisation in the queue (3, 1.0); a publicly visible queue (2, 0.7) |
| `nitrogen_permit` | Stikstof op het tracé | congestion grid reinforcement (Havenzij substation) | waiting | reinforcement wait +90 d: exists. Estimate. | the Raad van State's Porthos ruling (Nov 2022) ended the construction exemption; >300 Liander projects late (PLAN backlog) | ecology assessment in parallel with design (`starts_with`) (3, 1.0); standard AERIUS calculation template (2, 0.7); `route_via_industrial_zone` (3, 0.8) |
| `non_firm_unused` | Niemand wil flex | congestion.offer | overprocessing | the flex offer comes late as a long contract; few take it: offer wait +, queue | time-bound transport right (≥85% availability at about half the tariff; GDD) | standard flex offer at first contact (3, 1.0); `acm_pilot_time_bound` (3, 0.9; closed if the ACM visit failed); group contract on the business park (3, 0.7) |
| `solar_feedin_wait` | De zonneweide wacht | Lindeveld congestion (feed-in) | waiting | feed-in requests wait for full capacity | cable pooling (legal since 2023, verify) | cable pooling (3, 1.0); curtailment contract (3, 0.8) |

**Missions:**

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline → door | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `t3_interim_mt` *(new, 2026-10-16)* | De interim-directeur | M | t2_first_okr, `flag:ruud_seconded` | talk_to `interim_mt` (a group talk), outcome ≥ heard | — | sets `flag:interim_sponsor` or `flag:interim_regime` (from the Frank facts), plus `strategy_early` / `regime_one_stream` / `dashboard_agreed` by outcome | 1,200 · rep 3 | respect_for_people, kpi_alignment, catchball |
| `t3_map_region` | Eén regio, drie gebieden | M | t3_interim_mt, M3, B, rep ≥ 50 (regime: temptation `t3_consultants`, Lean-programma 2.0) | map_stream connections (queue_count) across the areas | — | — | 2,600 · €20k · unlocks vsm_view, Lindeveld, Havenzij, it_campus | value_stream_mapping (new) |
| `fix_long_drives` | Een uur rijden per klus | M | t3_map_region | solve | long_drives | — | 2,800 · €25k | waste_transport |
| `fix_training_capacity` | Het opleidingscentrum zit vol | M | fix_long_drives | solve | training_capacity | 63 d (the September intake) → closes `apprentice_cohort_september`; train-the-trainer remains | 3,000 · €25k | monteurstekort, respect_for_people |
| `t3_crew_strategy` *(new)* | Waar zetten we de monteurs in? | M | fix_training_capacity (done **or** failed) | strategy, forecast 91 d. Options: Lindeveld satellite crew (needs `chose:long_drives:satellite_depot` **or** `repaired:long_drives`); daytime outage reserve (needs `chose:planning_reshuffle:daytime_outage_crew` **or** `standardised:planning_reshuffle`); a Havenzij street-works crew (needs `done:fix_training_capacity`); baseline: spread evenly | — | sets `flag:crew_<option>`; read by `t4_investment_plan` | 2,800 · €20k | path dependence, capacity_planning |
| `fix_underground_crowding` | Geen plek onder de stoep | M | t3_crew_strategy | solve | underground_crowding | **B** (t3_havenzij) | 3,000 · €25k | theory_of_constraints |
| `fix_uneven_release` | De maandpiek | M | t3_crew_strategy | solve | uneven_release | **N** (t3_havenzij) | 2,600 · €20k | heijunka |
| `t3_kaizen_week` | Kaizenweek | M | any_of the fork | kaizen_event at the current constraint place, 5 d | — | — | 3,000 · €25k · unlocks kaizen_event | kaizen_event (new), bottleneck_focus |
| `fix_priority_first_come` | Wie het eerst komt | M | t3_kaizen_week | solve | priority_first_come | — | 3,200 · €25k | customer_value, maatschappelijk_prioriteren (new) |
| `fix_nitrogen_permit` | Stikstof op het tracé | M | fix_priority_first_come | solve | nitrogen_permit | 120 d (the canal-zone factory's opening) → closes `route_via_industrial_zone`; rep −10 | 3,400 · €30k | stikstof (new), waste_waiting |
| `t3_stop_starting` | Stoppen met starten | M | fix_nitrogen_permit (done **or** failed) | sustain connections wip_age ≤ target and throughput ≥ target, 8 weeks | — | — | 3,400 · €30k | conwip (new), littles_law (new), wip |
| `fix_non_firm_unused` | Niemand wil flex | S | t3_map_region | solve | non_firm_unused | — | 1,200 · €10k | netcongestie |
| `fix_solar_feedin_wait` | De zonneweide wacht | S | t3_map_region | solve | solar_feedin_wait | — | 1,200 · €10k | energietransitie, cable_pooling (new) |
| `sector_energy_hub` | Een energiehub op de Kanaalzone | S | fix_non_firm_unused | talk_to thomas, 3 topics | — | — | 600 | energiehub (new) |
| `coach_work_prep_lead` | Joost coacht zijn team | S | t3_map_region, trust work_prep ≥ 1 | coach joost, 3 sessions | — | — | 1,000 · support (work_prep) | coaching_kata |
| `lsw_layered_audit` | Gelaagde audit | R | t3_map_region | routine audit at 3 standardised places, every 28 d | — | — | 400 first time | standard_work, leader standard work |
| `sustain_connections` | Houd het vast | S | t3_kaizen_week | sustain connections on_time ≥ 0.9, 8 weeks | — | — | 1,000 · rep 3 | sustain |

### 3.7 Act V — Het systeem (tier 4)

Gates: `t3_stop_starting`, maturity 4, belt black, rep ≥ 65.

**Drie winters:** Ruud returns when the act opens (`ruud_returns`, `flag:ruud_back`; the call rule ends) and names his last day, the campaign's last deadline (`ruud_retirement`, the first 1 April at least 240 days after the act opens). Frank goes back to his manager's role. The waiting list's `date_kept` is hoshin's true north.

**New tier-4 problems:**

| id | Name | Stream · step | Waste | Mechanism | Grounding | Countermeasures |
|---|---|---|---|---|---|---|
| `strategy_silos` | Twintig prioriteiten | all departments (KPI board) | overproduction | every department runs its own projects and KPIs; board rules disagree: exists (kpis effects) | hoshin kanri; the ACM's biennial investment plans (verify) | hoshin with catchball (4, 1.0); X-matrix (4, 0.8) |
| `maintenance_calendar` | Onderhoud op de kalender | outages (asset faults) + monteurs load | overprocessing | maintenance on fixed intervals: monteurs' availability −, old joints still fail (outages ×1.1). Estimates. | NTA 8120 / ISO 55001, NN-CAM 5.0 (GDD) | risk-based maintenance with an asset health index (4, 1.0); Pareto of fault data (3, 0.7); condition monitoring of MS cables (4, 0.8) |
| `ls_grid_blind` | Blind in het laagspanningsnet | outages.report | waiting | LS faults are known only when customers call: report wait. Exists. | GDD outage stream ("LS faults only known when customers call") | the meter's power-failure log (DSMR), read daily (4, 1.0; verify the feature); `lv_sensors_msr` (4, 0.9; only from `t4_sensor_pilot`) |
| `grid_losses_theft` | Stroom die verdwijnt | grid (cost) | defects | `cost_per_week` (grid losses bought in); illegal connections cause some faults | ~1 billion kWh a year stolen (DutchNews 2019, in GDD) | balance analytics, transformer vs meters (4, 1.0); joint checks with police and gemeente (3, 0.7) |
| `flex_market_unused` | Een markt zonder bieders | congestion.capacity_queue | inventory | congestion relief is not bought on the flex market | GOPACS (the grid operators' congestion platform) | GOPACS participation (4, 1.0); flex as standard in contracts (4, 0.8) |
| `gas_phaseout` | Onderhoud aan een verdwijnend net | monteurs (gas work as load) | overprocessing | gas maintenance in streets due to go off gas (monteurs load). Approximated without a gas stream. Estimate. | Transitievisie Warmte (every municipality, by end 2021) | align with the municipal neighbourhood plans (4, 1.0); risk-based gas maintenance (4, 0.8) |

**Missions:**

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline → door | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `t4_hoshin` | Eén richting | M | t3_stop_starting, M4, B, rep ≥ 65 | solve | strategy_silos | — | 3,600 · €30k · unlocks strategy | hoshin_kanri (new), x_matrix (new) |
| `fix_maintenance_calendar` | Onderhoud op de kalender | M | t4_hoshin | solve | maintenance_calendar | — | 4,000 · €35k | risk_based_maintenance (new), nta_8120 |
| `nta8120_audit` | De audit | Ms | t4_hoshin | audit on the audit day: 6 fixes holding ≥ 0.8 + maintenance_calendar resolved | — | 90 d (audit date) → `fail_closes_missions: [t4_sensor_pilot]`, `fail_opens: nta8120_reaudit`, rep −10 | 4,200 · €40k · rep 10 | nta_8120, sustain |
| `t4_sensor_pilot` | Sensoren in het net | S | nta8120_audit passed | observe 3 MSR places + talk_to ingrid | — | (the door) | 1,500 · unlocks `lv_sensors_msr` | asset_health_index (new) |
| `fix_ls_grid_blind` | Blind in het laagspanningsnet | M | fix_maintenance_calendar | solve | ls_grid_blind | **B** (t4_detect) | 4,400 · €40k | jidoka, lead_time |
| `fix_grid_losses_theft` | Stroom die verdwijnt | M | same | solve | grid_losses_theft | **N** (t4_detect): saves money, no flow | 3,800 · €45k | systems_thinking, customer_value |
| `fix_flex_market_unused` | Een markt zonder bieders | M | any_of the fork | solve | flex_market_unused | — | 4,600 · €40k | gopacs (new), netcongestie |
| `t4_investment_plan` | Het investeringsplan | M | fix_flex_market_unused | strategy, forecast 182 d, among the unlocked options (see below) | — | — | 4,800 · €50k | capacity_planning, systems_thinking, path dependence |
| `de_opvolger` *(replaces `t4_new_ci_lead`, 2026-10-16)* | De opvolger | Finale (no slot, cannot fail) | t4_investment_plan, or six weeks before Ruud's last day | sequence: `successor_choice` with Ruud → the chosen successor's talk (≥ partial) → the last scene `first_question` | — | Ruud's last day (`ruud_retirement`) is a dated beat: missing it means Ruud is not at the table | title Coach · Ruud's Kata card · rep 5 | coaching_kata, respect_for_people |
| `fix_gas_phaseout` | Onderhoud aan een verdwijnend net | S | t4_hoshin | solve | gas_phaseout | — | 1,500 · €12k | energietransitie, transitievisie_warmte (new) |
| `talk_asset_manager` | Hoe gezond is een kabel? | S | t4_hoshin | talk_to ingrid, 3 topics | — | — | 800 | nta_8120, asset_health_index |
| `sector_grid_2035` | Het net van 2035 | S | talk_asset_manager | talk_to femke + ingrid, 2 topics each | — | — | 800 | energietransitie, ii3050 (new) |
| `nta8120_reaudit` | De heraudit | S (recovery) | only through `fail_opens` | audit: 6 fixes holding ≥ 0.8 | — | 120 d → rep −5 | 1,500 | nta_8120 |
| `lsw_catchball` | Catchball | R | t4_hoshin | routine dagstart at every board department, every 91 d | — | — | 600 first time | hoshin_kanri |
| `sustain_region` | Twaalf weken stabiel | S | nta8120_audit | sustain on_time ≥ 0.9 in connections, outages and meters, 12 weeks | — | — | 1,800 · rep 5 | sustain, leading_lagging |

**`t4_investment_plan`'s options** (each `needs`; the `preparation` hint is in brackets):

| Option | Needs | Locked hint |
|---|---|---|
| Opleiden: 12 aankomend monteurs | `any: [chose:training_capacity:train_the_trainer, chose:training_capacity:apprentice_cohort_september, repaired:training_capacity]` | "Het opleidingscentrum moet dit aankunnen." |
| Strategische trafovoorraad | `any: [chose:transformer_wait:framework_contracts, chose:transformer_wait:strategic_transformer_stock, repaired:transformer_wait]` | "Hiervoor moet de bestelling van trafo's anders geregeld zijn." |
| Standaardstations in serie | `all: [standardised:custom_design, maturity>=4]` | "Werkvoorbereiding moet standaard kunnen werken, en dat volhouden." |
| Flex eerst, koper later | `all: [done:fix_flex_market_unused, done:fix_non_firm_unused]` | "Klanten moeten flex al kennen." |
| Sensoren in het LS-net | `any: [done:t4_sensor_pilot, chose:ls_grid_blind:meter_power_failure_log]` | "We weten nog te weinig van wat het LS-net doet." |
| Meer monteurs in Lindeveld | `any: [flag:crew_lindeveld, repaired:long_drives]` | "In Lindeveld moet de basis eerst kloppen." |
| Klassiek verzwaren (baseline) | — | always open; the most expensive per unit of capacity (estimate) |

**Finale (2026-10-16, Drie winters):** `de_opvolger` replaces the placeholder. Ruud returns when Act V opens and names his last day; the player coaches their own successor. Candidates by facts: Anouk (standard designs held, developed), Ahmed (the trainer), Sanne (coached), or Lotte Smit from outside (always offered). The last scene ends on the player's first Kata question, judged by nothing. Design: `2026-10-16-drie-winters-arc.md` §8. The earlier idea (coach Lotte as the new CI lead of Lindeveld) is dropped.

### 3.8 Act VI — Het digitale net (IT value streams, Phase G)

Opens with `t3_map_region`'s `it_campus` unlock. Two IT streams:
- **Veldapp-features:** idea → refine → build → review → test → release → in gebruik.
- **IT-incidenten:** melding → triage → fix → deploy.

Problems carry `track: it` and `content/problems_it.yaml`, with their own maturity (§2.14).

**New IT problems:**

| id | Name | Step | Waste | Mechanism | Grounding | Countermeasures |
|---|---|---|---|---|---|---|
| `field_app_bypassed` | De app die monteurs omzeilen | in gebruik → connections.close_out | skills / defects | monteurs use paper; close-out retyped (close_out touch +, ftr −) | Lean in IT: go to the gemba | PO rides along with monteurs (1, 1.0); user feedback loop (2, 0.8) |
| `release_twice_a_year` | Twee releases per jaar | release | waiting | `batch_days: 182` at release: exists | PLAN backlog | monthly releases (2, 0.8); CI/CD pipeline (3, 1.0); feature toggles (3, 0.7) |
| `test_env_queue` | Wachten op de testomgeving | test | waiting | test environment pool of 2 | PLAN backlog | booking board (1, 0.6); environments on demand, infrastructure as code (3, 1.0) |
| `code_review_wait` | Wachten op een review | review | waiting | review wait +2 d (not the constraint) | estimate | pair programming (2, 1.0); review rota (1, 0.7) |
| `manual_regression` | Drie weken handmatig testen | test | overprocessing | test touch ×3 | estimate | test automation pyramid (3, 1.0); shift-left with monteurs as testers (2, 0.7) |
| `team_dependencies` | Afhankelijk van vier teams | build | waiting | handoffs between teams (wait per handoff) | SAFe, Team Topologies | dependency board at PI planning (2, 0.7); stream-aligned team (3, 1.0) |
| `pi_overcommit` | PI-planning als toneelstuk | refine | overproduction | WIP at 150% of capacity; nothing finishes | SAFe PI planning every 8–12 weeks | capacity-based PI planning with WIP limits (2, 1.0); PI objectives with business value + predictability (3, 0.8) |
| `ops_dev_wall` | Over de muur gegooid | incidents triage ↔ fix | defects | incidents bounce between dev and ops (rework loop) | DevOps | "you build it, you run it" (3, 1.0); shared on-call + blameless postmortems (2, 0.8) |
| `tech_debt` | De schuld in de code | build | overprocessing | build touch +x% growing over time (estimate) | — | 20% capacity for debt (2, 0.8); refactor at the constraint (3, 1.0) |

**Missions:**

| id | Titel | Kind | Requires | Goal | Problem | Fork / deadline | Rewards | Teaches |
|---|---|---|---|---|---|---|---|---|
| `it_map_feature_stream` | Mee met een feature | M | t3_map_region (it_campus) | map_stream it_features (time_study) | — | — | 2,600 · €20k | value_stream_identification (new) |
| `fix_field_app_bypassed` | De app die monteurs omzeilen | M | it_map_feature_stream | solve | field_app_bypassed | — | 2,800 · €20k | gemba, customer_value |
| `fix_release_twice_a_year` | Twee releases per jaar | M | fix_field_app_bypassed | solve | release_twice_a_year | — | 3,000 · €25k | batching, ci_cd (new) |
| `fix_test_env_queue` | Wachten op de testomgeving | M | fix_release_twice_a_year | solve | test_env_queue | **B** (it_after_release) | 3,000 · €25k | theory_of_constraints |
| `fix_code_review_wait` | Wachten op een review | M | same | solve | code_review_wait | **N** (it_after_release) | 2,600 · €15k | bottleneck_focus |
| `fix_manual_regression` | Drie weken handmatig testen | M | any_of the fork | solve | manual_regression | (the shifted bottleneck) | 3,200 · €25k | jidoka, test_automation (new) |
| `fix_team_dependencies` | Afhankelijk van vier teams | M | fix_manual_regression | solve | team_dependencies | — | 3,200 · €25k | art (new), team_topologies (new) |
| `fix_pi_overcommit` | PI-planning als toneelstuk | M | fix_team_dependencies | solve | pi_overcommit | — | 3,400 · €25k | pi_planning (new), wip |
| `it_dora_metrics` | Meten zoals DevOps | M | fix_pi_overcommit | sustain it_features lead_time ≤ target, 8 weeks (DORA lead time for changes; the other three keys on the board) | — | — | 3,400 · €30k | dora_metrics (new) |
| `fix_ops_dev_wall` | Over de muur gegooid | S | it_map_feature_stream | solve | ops_dev_wall | — | 1,200 · €10k | blameless_postmortem (new) |
| `fix_tech_debt` | De schuld in de code | S | fix_release_twice_a_year | solve | tech_debt | — | 1,200 · €10k | technical_debt (new) |
| `talk_rte` | Wat is een release train? | S | it_map_feature_stream | talk_to bas, 3 topics | — | — | 600 | art, pi_planning |
| `lsw_system_demo` | Systeemdemo | R | fix_release_twice_a_year | routine at the IT demo place, every 14 d | — | — | 300 first time | pdca, customer_value |

### 3.9 Counts

| Tier / act | Main | Milestone | Side | Recurring | Training | Recovery | Total | New problems |
|---|---|---|---|---|---|---|---|---|
| Tier 1 (Acts 0–II) | 13 | 2 | 13 | 2 | 5 | — | 35 | 0 (uses all 18) |
| Tier 2 (Act III) | 7 | 1 | 6 | 1 | — | 1 | 16 | 8 |
| Tier 3 (Act IV) | 11 | — | 5 | 1 | — | — | 17 | 8 |
| Tier 4 (Act V) | 6 + finale | 1 | 5 | 1 | — | 1 | 15 | 6 |
| IT (Act VI) | 9 | — | 3 | 1 | — | — | 13 | 9 |
| **All** | **46 + finale** | **4** | **32** | **6** | **5** | **2** | **96** | **31** |

On top of these: generated repair quests (`repair_<problem>`, 0 to n per playthrough, one per poor fix).

**New concepts** for `concepts.yaml`, each with a source or marked as an estimate:
- **Lean and management:** leader_standard_work, daily_management, pareto, tiered_escalation, andon, value_stream_mapping, kaizen_event, conwip, littles_law, hoshin_kanri, x_matrix, risk_based_maintenance, asset_health_index, sustain, path_dependence.
- **Sector:** gotork, non_firm, maatschappelijk_prioriteren, stikstof, cable_pooling, energiehub, gopacs, energiewet *(verify)*, compensatie *(verify)*, ii3050, transitievisie_warmte.
- **IT:** value_stream_identification, ci_cd, test_automation, art, team_topologies, pi_planning, dora_metrics, blameless_postmortem, technical_debt.

---

## 4. Implementation plan

Tasks are independent unless a dependency is named. **Code** tasks touch `game/src/rules/`, `session.gd` and `tools/build_content.py`. **Content** tasks touch `content/` only (plus their content tests). Every task follows TDD: write the failing test first, then the code, then the full suite (`godot --headless --path game --script res://tests/run_tests.gd`, `python tools/build_content.py --check`, `python -m pytest tests/ -v`), then `simplify`, then a PLAN.md update.

### 4.1 Code tasks

| # | Task | Depends on | Tests (first, failing) |
|---|---|---|---|
| C0 | **Problems need a holding mission** (gap 1): investigate completion and abandon put the problem to sleep; abandon refused during an experiment | — | complete `look_at_grid_study`, then 1 main + 3 sides all accept; abandon puts the problem to sleep and keeps its clues; abandon while DOING → `experiment_running` |
| C1 | **Mission schema:** kind `milestone`, act, chapter, arc, beats, fork, debrief_first, reopen, opens_on, deadline_on_day, fail_closes_missions, fail_opens, fail_effects, recurring, event; rewards reputation/trust/unlocks; requires maturity/reputation/trust/any_of. `MissionDef` + `validate_missions` + vocabulary. | — | each field loads; unknown keys refused; fork groups well-formed; fail_closes_missions never removes a problem's only mission; today's `missions.yaml` loads unchanged |
| C2 | **Gates and calendar** in `Missions._unlocked`/`update`: maturity, reputation, trust, any_of, opens_on (day, season), deadline_on_day | C1 | a gated mission opens exactly when the gate is met; an `opens_on` mission opens on its day without the player; an absolute deadline fails on its day; save/load keeps it |
| C3 | **Reopen flow:** reopen text event, "Terugval" in `GameSession`, no second reward, rep +2, the earlier countermeasure in the A3 view | C1, C9 | a faded fix reopens with the `reopen` text; no XP the second time; `GameSession` exposes the earlier countermeasure |
| C4 | **Goals batch 1:** measure, sustain, kpi_review, map_stream (with `Region.measures` per stream over a window, weekly samples) | C1 | each goal on the shared fixture: met / not met / reset on a missed week; samples saved |
| C5 | **People and conversations:** `people.yaml` loader + validator, `Conversation` (topics, open/closed/blame, sector clues), `talk_to` goal, `GameSession.talk(person, question)` | C1 | finishing topics completes the goal; a blame costs trust; a sector clue is A3 evidence only for an active problem; a clue never activates a problem |
| C6 | **Routines and recurring** (`routine` goal with cadence windows; `recurring` re-availability) | C1 | visits outside the window do not count; a recurring mission comes back after `every_days`; XP only the first time |
| C7 | **Coach goal** (the Kata script with an NPC, the NPC's experiment as a small effect) | C5 | five questions in order complete a session; out of order teaches but does not count; trust gate respected |
| C8 | *(owned by the sustain agent, see §5.4)* **Graded hold, support and stagnation drift** in `Region` (`SimModifiers.scaled`), reopen at h < 0.5, `maturity_dropped` event, `stagnation_alarm` opening | C6 (support from routines) | not standardised: h = 0.5 at `decay_days`; standardised: half-life ≈ 365 d; each support source slows decay; drift doubles decay at 84 d; save/load keeps h; the training fade now shows in the numbers |
| C9 | **Reputation** on `Profile`/`Region` with the deltas of §2.7; saved | — | each delta; bounds 0–100; old saves load at 30 |
| C10 | **Events, milestones and fail consequences:** milestones judged on their date without a slot, `event` effects window (`event:` source), fail_effects (cost per week for N weeks, reputation), fail_opens, fail_closes_missions | C1, C9 | a milestone passes or fails on its day without being accepted and never counts toward 1 + 3; the storm comes whether or not the mission was accepted; the effects clear after `days`; fail_opens makes the recovery available; a closed mission never opens |
| C19 | **Facts and needs** (§2.15): derived facts (done, failed, skipped, chose, standardised, poor_fix, repaired, fork_first) + `sets_flags`; one `needs` evaluator for missions (`requires.facts`), countermeasures and strategic options; saved | C1 | each fact is set by its event and survives save/load; needs all/any/none; a countermeasure with unmet needs is not offered; **validator: every needs branch stays obtainable after any failure or skip, and every strategy goal has a baseline option** |
| C20 | **Repair quests**: `repair_template` instantiation per problem, opening on `poor_fix` + days + the KPI gap; `rework_fix` goal (swap the countermeasure through a short A3 and Check without the problem's effects returning) | C19, C4 | a poor fix spawns its quest after the delay and only with the KPI gap; a good fix never does; rework sets `repaired:` and `chose:`; 1 + 3 respected; no reward the second time |
| C11 | **OKR and strategy goals** (quarter clock; counterfactual forecast among the *unlocked* options, reused from `KpiBoard.forecast`; locked options returned with their hint, never with what unlocks them) | C4, C19 | OKR met at 0.7; strategy forecasts only unlocked options, applies the chosen one, sets its flag and pays the forecast gain; no option is marked correct; the same save with and without a repair quest offers different options |
| C12 | **Kaizen event goal** (team hours blocked, short Check at the step) | C4 | a gain at the constraint completes the goal; at a non-constraint the Check says so |
| C13 | **Audit goal** (reads hold) | C8 | passes with n fixes ≥ 0.8; fails on the day otherwise |
| C14 | **Belts rescaled** (`Progression.BELTS`, `BELT_XP` in the validator) | — | the validator's reachability passes; a pacing test: the expert path through tier 1 ends green ≤ belt < black |
| C15 | **Fork honesty test** (content test using the problem-report machinery) | C1 | for every fork group the bottleneck fix beats the non-bottleneck by ≥ 3× on the stream's flow measure, and the non-bottleneck Check says `not_constraint` |
| C16 | **Coach templates** (KPI placeholders; the five Kata questions during an experiment; the fork reflect) | C1 | the reply reads the live KPI; never coaches a side mission |
| C17a | Sim: **weekly demand patterns** (for `uneven_release`) | — | a Monday peak shows in arrivals; base unchanged when off |
| C17b | Sim: **priority classes on orders** (for `priority_first_come`) | — | a priority order overtakes in the queue under the rule; base unchanged |
| C17c | Sim: **timed headcount ramp** (for `training_capacity`) | — | headcount grows on schedule; Capacity follows |
| C17d | **Problem tracks** (`track: it`, own maturity) | — | grid maturity ignores IT problems |
| C18 | Mission UI (Phase D): lanes Main / Side / Terugval / Routines, fork pair, deadline countdown, act title cards, beats as toasts | C1–C3 | `test_ui_text.gd` for every new Dutch string; screenshots |

### 4.2 Content tasks

| # | Task | Depends on | Tests |
|---|---|---|---|
| K0 | **Concepts:** the new entries of §3.9 with sources or `estimate:`; sector items marked `verify: true` where noted | — (can start now) | the existing concepts validator; every `teaches` id resolves |
| K1 | **Tier-1 polish:** teaches, reopen texts, fork metadata, act/chapter, Henk's calendar opening + relative clue text | C1, C2 | content check; fork test (C15) on the existing fork |
| K2 | **Tier-1 new missions:** review_100_days, first_kpi_review, talk_netplanner, sector_congestion_map, lsw_gemba_round, lsw_van_round, stagnation_alarm | C4, C5, C6, C8, C10 | the 100-day target is reachable on the expert path and not without fixes (content test); validator reachability |
| K3 | **`people.yaml`:** the cast of §2.3, with topics for Acts I–III first | C5 | the people validator; every topic's concepts resolve |
| K4 | **Tier-2 problems + countermeasures** (`problems_tier2.yaml`) | — (existing mechanisms) | the existing content tests: expert can solve, every problem hurts its stream, every countermeasure can pass |
| K5 | **Tier-2 missions** (Act III) | K4, C2, C4, C7, C10, C11 | validator; fork test; ACM target reachable on the expert path |
| K6 | **Tier-3 areas** (Lindeveld/Havenzij pools and streams in `value_streams.yaml`) + problems | C17a–c | base stays stable (no team > 85%); content tests per problem |
| K7 | **Tier-3 missions** (Act IV) | K6, C12 | validator; fork test |
| K8 | **Tier-4 problems + missions** (Act V; finale only as a placeholder id) | C8, C11, C13, C19 | content tests; audit reachable on the expert path; the investment plan offers ≥ 2 options on the expert path and the baseline on the worst path |
| K11 | **Repair template + overrides** for key problems; `needs` on fact-gated countermeasures (replacing ad-hoc `fail_closes` where the facts express it) | C19, C20 | validator; a content test that plays a weak fix of `transformer_wait`, does the repair quest, and sees the stock option unlock |
| K9 | **IT streams + problems + missions** (Act VI) | C17d | content tests; fork test |
| K10 | **Review doc for Merijn** per tier (problem report numbers, texts, open estimates) | each tier | — |

**Order for Phase 2:**
1. Wave 1, in parallel: C0, C1, C9, C14, K0, C19 (after C1's schema).
2. Wave 2, in parallel: C2, C4, C5, C6, C10, C16, K4.
3. Wave 3: C3, C7, C11, C12, C13, C15, C20, then K1–K3, K5, K11. (C8 is the sustain agent's.)
4. Waves 4 and on: tiers 3–4 and IT behind their simulation tasks.

**PLAN.md** should get a Phase B line pointing to this spec, the C/K tasks, and the gap-1 fix as the first item. This doc does not edit PLAN.md, because other agents are working in it.

---

## 5. Answers (2026-10-15)

**Merijn's decisions:**
1. **Reputation** is a separate measure, next to trust and budget (§2.7 as designed).
2. **Belts are rescaled** to 2k / 6k / 30k / 110k XP (§2.13; C14).
3. **Areas, not regions:** Lindeveld and Havenzij sit inside Zuidmark's network (§2.14).
4. **Decay:**
   - A standardised fix decays slowly, and faster the longer nothing is done, until a "have a look" mission appears (`stagnation_alarm`, §2.8).
   - A stronger sustaining mechanism means less decay.
   - **With planned audits or routines there is no decay at all.** This replaces §2.8's support cap of 0.8: an active routine or audit at the fix's place sets support to 1.
   - The sustain agent builds this (C8 is theirs, not part of the mission work). The mission tasks consume its API: hold, the reopen at the threshold, and the stagnation trigger. C6 (routines) feeds it.

5. **Strategy goal: yes, with path dependence.** The strategic options available depend on what the player has done so far. A decision whose preparations were not made can't be made. You can pivot, but to get back on the "right" path you must first do certain other things (e.g. a poor countermeasure later brings a repair side quest; doing it opens different options than skipping it). Designed as a first-class mechanism in §2.15:
   - facts and `needs` on options, missions and countermeasures;
   - repair side quests;
   - the strategy goal judged by forecast among the unlocked options only.

   Built as C19, C20 and C11, with K11.
6. **Finale:** a good plan, but far in the future. `t4_new_ci_lead` is a placeholder id with no detailed design. *Superseded 2026-10-16 by the arc* Drie winters *(PLAN §4.0 item 6): the finale is `de_opvolger` (§3.7).*
7. **IT runs in parallel from tier 3**, after `t3_map_region` (§3.8).
