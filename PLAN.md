# Spanning — Build Plan

*Spanning* (Dutch: voltage, and tension) is a 3D learning game (Godot 4, desktop + web export) in which you practise Lean and continuous improvement as the new CI lead at **Voltana Netbeheer**, a fictional Dutch regional grid operator in the region *Zuidmark*. Game text is **Dutch**; code, comments and this plan are English.

> **How to read this plan.** §1 says where we are and what to do next. §2 is what the game is. §3 is the roadmap: seven phases, each ending in something Merijn can play. §4 is the creative direction for missions and dialogs (the part of the game that decides whether it is any good). §5 is the world: the building, the campus, the town. §6 says how sessions run. §7 holds the questions only Merijn can answer. §8–§10 carry the problem backlog, every decision made and every pending call. The previous plan is archived in full at `docs/plans/PLAN-archive-2026-10-15.md`; nothing was dropped, only compressed.
>
> Rewritten 2026-10-16 by Fable (the planning session) on Merijn's instruction, from the old plan, `CLAUDE.md`, the specs of 2026-10-15 and `docs/handoff/2026-10-15-session-end.md`. Opus 5.5 executes; Fable plans. `CLAUDE.md` §1 still applies: keep this file in sync inline.

---

## 1. Current status and next task

**Current status: Phase 1 — Mensen (people, dialogs, the session layer) 🔧 starting.** The engine, rules, content pipeline, tier-1 content, the office slice, sustain-or-decay, the honest Check, mission waves 1–2 and the QA bot are built and green (see §2.4). The dialog *engine* is built but not merged. Tier 2–4 and all dialogs are designed, not built. Characters are sample quality.

**Next task (first session of Phase 1), in this order:**
1. **Relaunch the mission-and-dialog agents first** (CLAUDE.md §2: continuous; §6.2 names the three roles). Nothing else starts before they run.
2. **Merge the dialog engine** from `docs/handoff/dialog-engine-f5319f4.patch` (gate-clean on `fae460a`; conflicts in five files against today's head: `tools/build_content.py`, `game/src/game/session.gd`, `game/src/rules/catalog.gd`, `PLAN.md`, `game/data/vocabulary.json`). Apply on a branch from `fae460a`, merge HEAD into it, run the full gate.
3. **Build the dialog UI** (Phase 1, item 1.2) and **put the first six people at their desks** (1.3), so Act 0–I can be played *with people*. That is the Phase 1 playable.
4. In parallel, by other agents: the session layer (1.4), the four-tier audit fixes (1.6), the tier-2 simulation fixes (1.7).

The gate for every commit: `godot --headless --path game --import`, `godot --headless --path game --script res://tests/run_tests.gd`, `python tools/build_content.py --check`, `python -m pytest tests/ -q` (check the exit code). Last green: 414 Godot tests, pytest green, CI green on `d2109ff`.

---

## 2. What this game is

### 2.1 The thesis
You cannot fix a process without its people, and you cannot keep people without fixing the process. Every system in the game serves that sentence: the simulation judges the process, the dialogs judge how you treat the people, and sustain-or-decay ties the two together, because a fix that was pushed through without commitment decays faster than one the team owns.

### 2.2 Directives (binding, from CLAUDE.md §2)
- A learning game about continuous improvement: Lean first, later IT / Agile / DevOps / SAFe, in the energy sector.
- People are the most valuable resource. An RPG where the player searches and thinks; nothing is handed over. Fix processes end to end. Measure. The 8 wastes and sector issues come up often.
- **The mission system decides the game.** Every mission: real problems with real fixes; entertaining; intriguing; challenging; engrossing; intuitive; correct. Primary directives: players learn Lean and the sector, and players keep playing. Secondary: process management, SAFe, Agile, DevOps, Six Sigma, IT, project management.
- **Reward deep thinking** under three principles: long term over short term (95 %); respect for people first (trust and reputation measure it; keeping and developing talent pays); always improve.
- One main mission, at most three side missions. Problems only through missions. Forks now and then. A senior manager coaches, Kata-style, main quest only. Action-based problem solving. Many healthier processes. Evidence first. Setbacks, never game over. Missed deadlines have lasting consequences. Sustain or decay. Stagnation is regression. Respect the player's time. Dialogs are give and take (MORE PIES; a visible meter that shows feeling, never the right reply). Dutch text, English code.
- Mission *and dialog* agents run continuously; Claude tells Merijn when that stops.

### 2.3 Setting, cast and value streams
- **Company:** Voltana Netbeheer, region Zuidmark. **Towns:** Nova (campus and the first town), later rural Lindeveld and port town Havenzij (tier 3, inside Zuidmark).
- **Player:** the new CI lead. **Coach:** Ruud Hoekstra, Directeur Netbeheer regio Zuidmark. **Recurring cast** (dialog spec §6): Joost (Werkvoorbereiding), Sanne (Intake), Marco (monteurs), Henk and Ahmed (storingsdienst), Anouk (werkvoorbereider), Petra (Meetdata & registratie), Esra (Klantcontactcentrum), Frank Hulshof (the blocking manager), the El Amrani family (customer). Experts: Femke (Netstrategie), Thomas, Jeroen. More per tier in the drafts.
- **Value streams** (`content/value_streams.yaml`): 1 Nieuwe aansluitingen & netverzwaring; 2 Storingen; 3 Veldservice & slimme meters; 4 Congestiemanagement; 5 Klantvragen (failure demand); IT value streams from tier 3. Streams share people, so outages pre-empting planned work emerges, not scripted.
- **The story** (§4.0, *Drie winters*): the six acts of the catalogue (0 Inwerkweek · I De eerste honderd dagen · II Wat onder de grond zit · III Zichtbaar maken · IV Flow door de regio · V Het systeem · VI Het digitale net, IT in parallel from tier 3) grouped into three years, each with a winter as its test: the El Amrani heat pump, the storm without Ruud, the succession. 94 authored missions plus generated repair quests.

### 2.4 What exists today (pointers, not a changelog)
| Area | State | Where |
|---|---|---|
| Simulation | discrete-event network, shared pools, external waits, stock, rework, failure demand, common random numbers, `NetworkState.copy` | `game/src/sim/` |
| Rules | Region, PDCA/A3, investigation tools, the honest Check (`CheckForecast`), KPI board (counterfactual reward), Missions (1+3, forks, deadlines, reopen, schema with acts/facts/requires), Facts (path dependence), Repairs, Reputation, Stewardship (dividends, overload), Sustain (wear, routines, drift), Discoveries, Progression (belts 2k/6k/30k/110k), Profile, saves | `game/src/rules/`, `game/src/save/` |
| Content | 18 tier-1 problems, 41+ countermeasures, the tier-1 campaign (34 missions incl. the training week), 101 glossary concepts, 18 discoveries, KPIs, value streams; YAML → validated JSON | `content/`, `tools/build_content.py`, `game/data/` |
| World | one floor: the connections office (Intake, Werkvoorbereiding, Obeya, coach, mission board), Blender-scripted, third person with a Sims-like camera, click-to-move, player map (M) | `game/src/world/`, `game/assets/office/`, `tools/blender/` |
| UI | HUD, place menu (side panel), clue journal, A3, Check panel (leading/lagging tags), coach, mission board, codex (K), sustain view, training cards | `game/src/ui/` |
| Characters | three samples (player, Ruud, monteur), mannequin quality | `game/assets/characters/`, `docs/screenshots/characters_*.png` |
| QA | autoplay personas and report; tier-2 simulation check | `game/tools/autoplay.gd`, `docs/qa/` |
| Design docs | mission system and catalogue; audit and engagement; tier-2/3/4 drafts; tier-2 dialogs; dialog system; dialog scripts Acts 0–II; engagement loop; four-tier audit (partial); sustain and drift; training arc; counterfactual KPI reward; department KPIs; office slice | `docs/superpowers/specs/` |
| Unmerged | the dialog engine (patch); the El Amrani followed order + containment (WIP patch) | `docs/handoff/` |

---

## 3. Roadmap

Each phase ends in a **playable** that Merijn plays before the next phase starts. The world grows with the acts, not all at once (progressive RPG: a new building or floor opens when a mission needs it). Three tracks run through every phase: the mission-and-dialog agents (continuous), QA autoplay (every phase gate), and the art pipeline.

### Phase 1 — Mensen: people, dialogs, the session layer 🔧
**Playable:** Act 0 and Act I in the office, with people at their desks you can walk up to and talk with; a session that starts with a terugblik and ends at a dagstart. Merijn plays it and the autoplay bot plays it.

- ⬜ **1.1 Merge the dialog engine** (`docs/handoff/dialog-engine-f5319f4.patch`). Then the leftovers in the spec's task list: D6 Ruud's talk stage after a main-mission dialog; D7 check-in cadence (≤ 1 visible, ≤ 2 a week, 14-day cooldown); D8 discoveries D29–D34; D9 the rest of the cast; `talk_to` mission goals (`talk_outcome()` is ready). Dialog spec: `docs/superpowers/specs/2026-10-15-dialog-system-design.md`.
- ⬜ **1.2 Dialog UI** (D11): the speech panel; the openness **bar that fills**, with ▲/▲▲ ▼/▼▼ per reply and never a number (Merijn); trust pips; mood word and face; the layer tracker (Standpunt · Belang · Zorg); reply chips by move type, all moves always visible; the cue "Er zit meer achter…"; the summary card with the openness trace; the Mensen tab in the journal; the **walk-around energy bar** over people who need a talk. Screenshot every state.
- ⬜ **1.3 People in the office.** NPC avatars at their desks (Joost, Anouk at Werkvoorbereiding; Sanne at Intake; Petra at Meetdata; Esra and two agents at the contact centre once that room exists, see Phase 2; Marco passes through from the yard), idle and work animations, a name tag on hover, walk up and press E to talk. Ruud in his room. Henk and Ahmed appear for their missions. Characters: the method Merijn chooses (§7 Q1); until then the samples.
- ⬜ **1.4 Session layer** (engagement loop §2, all decided): the *terugblik* card when the game opens (Ruud's line; Veranderd · Wacht op je · Komt eraan; one button); the "goed moment om te stoppen" note at the dagstart after ~30 real minutes; the *Intussen* panel during a Check with a named time skip that stops at beats with people; ≤ 1 discovery toast per in-game day; ≤ 2 new side offers a week, older ones in a "Nog open" drawer; a local playtest log (opt-out, never sent).
- ✅ **1.5 UI debts the rules already need** (built 2026-10-16, `test_ui_debts.gd`): the Check panel shows the forecast ("Zonder jouw maatregel" / "Met jouw maatregel" over `forecast.days`, the measuring window named) and the A3 says the Check is simulating before it runs; Dutch text for `not_moved`, `impact_lead_time_small` and the `same_countermeasure` refusal; the HUD budget shows the weekly savings of held fixes and, in debt, the floor (orange); `dividend`, `overload`, `repair`, `reputation` events in Dutch (team names from the pools); the board labels a repair quest "herstel", the A3 shows "Eerder geprobeerd: …" on a rework; the A3's "Niet voorbereid" list with each `preparation` hint and "±€ … /jaar" (year cost, rounded: an estimate) next to each countermeasure; the board (now scrolling) and the debriefs use `mission_briefing` / `mission_debrief`, missions grouped under act and chapter titles (`UiText.ACT_TITLES`), the fork shown as a pair under "Twee hoofdmissies tegelijk"; the codex has an "Ontdekkingen" tab (silhouettes "? ? ?", end-of-act hints, found ones with object and Ruud's note) with the earned titles under "Jij, CI-lead bij Voltana Netbeheer"; training-week leftovers: the fade now shows in the numbers (fade_forecast re-applies the problem) and Friday starts on the next working morning (both already fixed in the session), and a practice fix no longer reads "knelpunt aangepakt" (impact notes hidden, a practice note instead); `CheckPanel` uses `Pdca.LOWER_IS_BETTER`. Screenshots `play_check.png`, `play_simulating.png`, `play_fork_board.png`, `play_discoveries.png`, `play_debt.png`, `play_a3.png`, `play_timelapse.png`.
- ✅ **1.0 The story arc into the catalogue** (design agent, docs, 2026-10-16): catalogue §3.1 and the act tables reworked to *Drie winters*; full design in `docs/superpowers/specs/2026-10-16-drie-winters-arc.md`: the calendar and seasons, the `waiting_list` north star (open · average wait · dates kept), winter 1's milestone `winter_el_amrani` (day 70), `ruud_farewell`, the group-talk shape and `interim_mt` (sponsor/regime on the Frank facts), `t3_interim_mt`, `t3_consultants` and the team-led way back (`frank_interim`), Ruud's monthly call (`ruud_call`), the storm scene `storm_night_board`, Ruud's return and last day, the finale `de_opvolger` (four successor talks and the last scene), all dialogs in Dutch. Tier drafts, engagement loop and the El Amrani call carry notes.
  - ⬜ **1.0a Builder: the arc's schema needs** (arc doc §10, S1–S18): seasons incl. `storm`, dated beats, the coach cooldown and `coach_calls`, the `north_star` KPI block, the group-talk engine (Phase 3), dialog variants, archetype `mentor`, kind `finale` and `scene`, `story_order`, the new facts. Winter 1 (S11, S12) belongs with Phase 2 (2.4b).
  - ⬜ **1.0b Design agent: one human thread per act** (arc doc §9, proposed: the storm-night family, Samira El Amrani's bakery, Ahmed as trainer, Ricardo's notebook): write their beats and one short dialog each.
- ⬜ **1.6 Four-tier audit fixes** (`docs/superpowers/specs/2026-10-15-four-tier-audit.md`): fact names read but never set (§1.1); tier-2 promises in tier 4 (§1.2); temptations with no later cost (§1.3); staggered side openings (§2); **dialog formula drift** (§4: no opener in more than a third of a tier; vary the concern cue between hesitation and feeling; vary interest `via` by person; re-check routes so no single route wins every talk); the three principles' payoffs (§5). Owner: the design agent, docs; the builder applies to content.
- ⬜ **1.7 Tier-2 simulation fixes** (`docs/qa/tier2-sim-check.md`: 107/137 pass): `safety_stock_calendar` is inert; the ACM 85 % target cannot be failed; all six OKR key results wrong; four problems fail the named-KPI test; `repeat_fault_analysis` fails at maturity 2. Apply the confirmed numeric fixes, re-measure the estimates with `game/tools/draft_check.gd`.
- ⬜ **1.8 Finish the WIP patch** (`docs/handoff/wip-mission-followed-order-containment.patch`): the El Amrani followed order (D14) and containment (D28) with the validator and the content on `fix_digging_damage`.
- ⬜ **1.9 Rules leftovers:** R1(c) a durability term in the countermeasure score; the Check over the cohort of orders that entered after the fix (so a rework fix can predict first time right again); replications if the Check's seconds allow; re-standardise after the Act; re-run the autoplay personas and regenerate `docs/qa/autoplay-report.md` (careless seeds 12 and 13 never ran; ~16 min each).
- ⬜ **1.10 Phase gate:** autoplay (expert, average, careless, plus a new *talker* persona and a *never-talks* persona) on the new build; `requesting-code-review` on the phase; Merijn plays Act 0–I with people and answers the playtest questions (engagement loop §8), and confirms the office-slice UI calls still open from 2026-10-13: interaction by standing at a marker (a green ring, 1.6 m) rather than by looking; the clue journal grouped by place, never saying which clues matter; the A3 evidence list offering every found clue, red herrings included.

### Phase 2 — Het hoofdgebouw: the building and the whole of tier 1 ⬜
**Playable:** Acts 0–II end to end (the whole tier-1 campaign) in a three-floor head office with a contact centre, a yard with vans, and the first customer phone calls; the first full playtest.

- ⬜ 2.1 The head office as three floors (§5.2), the stairwell and lift as seams, the player map with a floor switch. Begane grond: ontvangst, Klantcontactcentrum, kantine. 1e: Aansluitingen (what exists) plus Revisie & GIS and Meetdata & registratie. 2e: Directie & Obeya, Netstrategie, the congestion desk, the MT room, Ruud's office.
- ⬜ 2.2 The yard: the magazijn and werkplaats, the van park, the van kanban wall; monteurs leaving in the morning and returning (`fix_wrong_joint`, `fix_not_at_home` sides live here).
- ⬜ 2.3 The opleidingsterrein (training yard): Henk teaches Ahmed by doing (TWI); later the training-capacity missions of tier 3.
- ⬜ 2.4 Customer calls at the contact centre (Merijn: phone now, home visits later): the El Amrani calls, Ilse; the headset as a place.
- ⬜ 2.4b Winter 1 as the climax of tier 1: the El Amrani followed order delivered before the first frost (or not), the date you promised checked by the simulation; the first-frost beat on the calendar.
- ⬜ 2.5 Act II content complete and tested (Graafschade first, De revisieberg, the grid studies, transformers, contracts, the KPI board's birth, the day-100 milestone); the fork tests on the real network (C15); templated debriefs with the player's numbers (C16); authored repair texts (K11).
- ⬜ 2.6 Gemba readability pass (§5.4): every active tier-1 problem has at least one visible tell in the world.
- ⬜ 2.7 Save slots, pause menu, settings (key rebinding, camera, volume), a title screen that is not the boot scene; gamepad later.
- ⬜ 2.8 Phase gate: autoplay on the full tier 1; code review; Merijn's first full playtest → a tuning backlog.

### Phase 3 — Zichtbaar maken: tier 2 and the campus ⬜
**Playable:** Act III: daily boards, tiered escalation, the control room, a storm week, a heatwave, the ACM visit, the first OKR, coaching Sanne.

- ⬜ 3.1 Tier 2 into content (wave 3: 22 missions, 11 problems, 36 countermeasures, the 17 Act III talks and check-ins), after 1.6–1.7.
- ⬜ 3.1b The reversal (§4.0): Ruud's secondment at the end of Act III; the interim director's MT group talk reading the Frank facts; Act IV's sponsor and regime openings; Ruud's monthly phone call (coach cooldown 28 days, one Kata cycle); the consultancy temptation and the team-led way back.
- ⬜ 3.2 The bedrijfsvoeringscentrum (control room) building: shift handover, the storm night (day/night and weather for the first time), the escalation board.
- ⬜ 3.3 Daily boards at every team (the dagstart as a *group* scene at the board: several people, one room meter, see §4.3), andon, the layered audit as a real recurring visit.
- ⬜ 3.4 The coaching kata as play: the player asks Sanne the five questions; her experiment runs in the simulation.
- ⬜ 3.5 Seasons and the calendar: storm (autumn), heatwave (July), 1 July rule changes, year-end budget; missions `opens_on` dates; the HUD shows the season.
- ⬜ 3.6 Phase gate as above.

### Phase 4 — De regio: the town, two more areas and the IT chapter ⬜
**Playable:** Act IV and Act VI side by side: the player is CI lead for all of Zuidmark, drives (map travel) to Lindeveld and Havenzij, visits the El Amrani home, and starts on the field app with IT.

- ⬜ 4.1 The town of Nova as hand-built *sites* first (§5.3): a street with a dig (graafschade), a meterkast at a home, a trafohuisje, a hall on the industrial estate, the El Amrani home; reached by van from the yard (a map travel with a short drive, not a driving game). Then streets between them.
- ⬜ 4.2 Lindeveld depot (rural, long drives) and Havenzij (port, crowded underground, nitrogen): small depots with their own people; the region map.
- ⬜ 4.3 The IT building (or floor): the field-app team, the release train, the test environments; the IT category in the codex.
- ⬜ 4.4 Tier 3 into content (29 missions, 17 problems, 58 countermeasures, 20 dialogs), with the strategy screen that shows the player's own history as open and locked options (path dependence on screen), the crew strategy, kaizen events, VSM built by walking.
- ⬜ 4.5 Heijunka in the simulation, when the content shows where it is needed.
- ⬜ 4.6 Phase gate.

### Phase 5 — Het systeem: tier 4 ⬜
**Playable:** Act V: hoshin, the NTA 8120 audit, risk-based maintenance, losses and theft, the flex market, the investment plan shaped by every earlier choice; the IT chapter "Het digitale loket".
- ⬜ 5.1 Tier 4 into content (9 new problems, 35 countermeasures, 11 dialogs, D45–D50). Two new wait steps the fork needs. The fork judged on outage minutes.
- ⬜ 5.2 The MT room as a stage: the hoshin X-matrix as an in-world object; catchball as a dialog with several parties.
- ⬜ 5.3 Winter 3: Ruud's return and retirement date as the last deadline; the succession mission `de_opvolger` with its four variants on facts (Anouk, Ahmed, Sanne, an external hire); the last scene is the player's first Kata question to their successor.
- ⬜ 5.4 Phase gate; a full-campaign autoplay (three years of play).

### Phase 6 — Afwerking: polish and release ⬜
- ⬜ Web export that plays (gl_compatibility is already the renderer); Windows/Linux/mac builds; itch.io or a private page first (§7 Q3).
- ⬜ Audio: ambient office, the yard, rain in the storm week, a soft cue per event (no music loop that nags).
- ⬜ Accessibility: colour-blind palette, text size, remappable keys, no timed inputs anywhere (follows from "respect the player's time").
- ⬜ Performance: the contact stream's ~20k calls a year make a simulated year ~2.8 s; batch calls if fast-forward ever feels slow.
- ⬜ Tech debt tracked from Phase A: content rules live twice (Python validates, GDScript loads); let `build_content.py` emit canonical JSON so the game parses nothing.
- ⬜ Verify key sector figures against the source pages themselves (the environment's network policy blocked the pages; only search extracts were available), including the glossary entries still marked `verify: true`.
- ⬜ English localisation, only if Merijn wants a wider audience (§7 Q4).

### Phase 7 — Stem: the AI voice ⬜
- ⬜ Claude voices the dialog lines over the *same* state model (the rules still judge; decided: dialog spec Q11). Free text for the player's questions to people, grounded in each problem's hidden facts. Ruud's coaching with memory of the player's own A3s. Cost tracking, offline fallback, prompt caching (CLAUDE.md §3 `claude-api`).

---

## 4. Creative direction: missions and dialogs

This is the part Merijn asked Fable to think hardest about. It tells Opus and the mission-and-dialog agents *where to take* missions and dialogs, beyond the specs that already exist. Everything here respects the directives in §2.2 and the decisions in §9.

### 4.0 The story arc: *Drie winters* (rewritten 2026-10-16; Merijn asked for creative freedom within the directives)

**Why change it.** The catalogue's six acts are sound and all 94 drafted missions stay usable. But as a *story* it was a syllabus with faces: each act a Lean topic, the player only ever ascending, and nothing ever testing what they built. Real improvement careers have one defining moment: the sponsor leaves, and the programme is judged by what holds. Marco's backstory ("the 2012 programme vanished when the consultants left") already says it. This arc makes that the present, and it turns the game's three big mechanics (sustain-or-decay, commitment versus compliance, path dependence) into the plot.

**The spine: three winters, one number, one coach who wants to become unnecessary.**
- **One number.** From Act II the HUD carries the region's north star: *de wachtlijst van Zuidmark* (open connection requests and congestion requests, with the average wait in weeks), driven by the simulation and never scripted. It is the sector's real headline (households on the waiting list since 1 July 2026). Every act moves it; the finale is not zero but "iedereen krijgt een eerlijke datum, en die klopt".
- **Three winters.** Play starts on 12 October 2026, so the calendar (§4.2.1) gives the campaign three winters, each a test of what the player built:
  - **Winter 1 — De warmtepomp van de familie El Amrani** (Acts I–II, tier 1). Does your first fix hold long enough for the heavier connection before the cold? The stakes are one family and one honest date. Day 100 is the midpoint review; the KPI board is born at the end of Act II.
  - **Winter 2 — De storm zonder Ruud** (Acts III–IV and VI, tiers 2–3). *The reversal.* At the end of Act III, Ruud is seconded to Den Haag for a year, to the national programme on the waiting list. **Frank Hulshof becomes interim director.** Which Frank you get is path-dependent: the one you brought along in Act II opens the year as a sponsor; the one you blocked or bypassed opens it with a dashboard regime, output targets and the temptation of a consultancy's "Lean-programma 2.0". The storm week falls in this winter, with the control room's new boards or without them. The coach is still Ruud, by phone, **one Kata conversation a month**: the player must run their own Kata and start coaching others (Sanne, Joost). What was built with commitment holds; what was pushed slips, and repair quests show the way back. Nothing is lost for good; everything is tested.
  - **Winter 3 — De opvolger** (Act V, tier 4). Ruud comes back in the spring as regional director and announces his retirement date: the campaign's last deadline, the bookend of Henk's in the first act. The NTA 8120 audit and hoshin are the system's test; the finale is **the succession**: the player coaches their own successor, and *who sits across the table depends on the play*: Anouk or Ahmed if you developed them (TWI, buddy, coaching kata), Sanne if you coached her, an external hire if you developed nobody (the game says so kindly, and the hire's first question is one you once asked Ruud). The last scene is the first Kata question, asked by the player.
- **Act VI (IT, "Het digitale net")** runs in parallel through winters 2–3 as drafted, and it serves the number: the portal where households register, the field app the monteurs bypass, the release cadence that decides how fast a fix reaches the street.

**The antagonists are forces, never people** (people are never the cause): *the queue* (it grows by itself: drift), *the number* (the output KPI the directie and the ACM look at: Frank's pressure), and *time* (Henk retires, people leave, seasons come). Frank is an obstacle with a concern, and the game's best arc if you listen to him.

**Bookends and echoes.** Henk's retirement opens the game, Ruud's closes it. Anouk drowning at Werkvoorbereiding in Act 0, Anouk (or Ahmed) at the table in Act V. The El Amrani heat pump in winter 1; their daughter's bakery on the Havenzij waiting list in winter 2 (the Act IV thread). The first fork taught "the Check shows no gain at a non-bottleneck"; the last strategy screen shows the whole history of such choices.

**What changes in the catalogue** (the design agent reworks §3.1 of `2026-10-15-mission-system-and-catalogue-design.md`; the builder follows):
1. Group the acts into three *years* with the winter as each year's climax; add `opens_on {season: winter}` beats and the three winter missions as milestones (no slot).
2. New beats at the end of Act III: *Ruud gaat naar Den Haag* (a farewell talk; the monthly phone call unlocked) and *De interim-directeur*, a **group talk** in the MT room whose opening state reads the facts about Frank (Act II dialogs: `committed:frank_*`, `blocked:frank`, `heard:frank`).
3. Act IV's opener reads the Frank variant: sponsor (the Obeya stands; the strategy screen opens early) or regime (the Obeya replaced by a dashboard; `fix_silo_kpis` can recur; the consultancy temptation `t3_consultants` as the act's big shortcut, with its later cost and the way back through a team-led kaizen week).
4. Coach rule for winter 2: Ruud's `ask_coach` has a 28-day cooldown and one Kata cycle per call; the coaching-kata missions (`coach` goals) carry the player instead. The coach still helps only with the main quest.
5. The north-star KPI `waiting_list` in `kpis.yaml`, on the HUD from Act II, named in hoshin (Act V) and in the ACM visit (Act III).
6. Act V: Ruud's return and retirement date; the succession mission `de_opvolger` with four candidate variants on facts; the "finale placeholder" is replaced by this one authored scene. The far-future "coach a new region" idea is dropped.
7. Winter 2's storm (`prep_storm_week`, Code oranje) becomes the Act III–IV climax, with a control-room scene; winter 1 gets the El Amrani date as its climax (`fix_status_callers` → the followed order's delivery before the first frost).

**Why it fits the directives.** Problems still arrive only through missions; one main and three sides hold; the coach is still a senior manager who asks; nothing is handed over; recovery is always possible (the regime is a setback, not a loss); the three principles decide the outcome (what you built with respect and patience holds under pressure); the sector is the plot (the waiting list, the ACM, the storm, the technician shortage); and the player learns the deepest Lean lesson there is: a leader's job is to make themselves unnecessary.

### 4.1 What a Spanning mission is
A mission is **a mystery with a face, a number and a choice**:
- **A face:** someone whose day the problem ruins (Anouk working till seven; Mrs El Amrani's fourth call). The player meets them before they see a KPI.
- **A number:** a measurable claim the player can check at the gemba, and a KPI the A3 must predict. The Check judges the number; the debrief reads the player's own numbers back.
- **A choice:** at least one tempting shortcut whose cost shows up later through path dependence (the quick hire, the consultant, the comforting promise), and a patient fix that holds. Never a marked right answer; the simulation and the sustain rules do the judging, in time.

And the **verbs**: kijken → praten → denken → proberen → meten → borgen, each with its own small reward (engagement loop §1). A session touches two verbs; a mission touches all six.

### 4.2 Where to take the missions next (Opus, with the design agent)
1. **A living calendar.** The region has a year: storm season, the July heatwave, the 1 July rule change, year-end budget, the ACM's visit, Henk's retirement date. Missions open on dates, not only after other missions, and the HUD shows the season. This makes the world push back on its own, and it makes the stagnation drift feel like weather, not a penalty.
2. **One thread per act.** Tier 1 has the El Amrani dossier. Every act needs one such thread: a person or a customer whose life the act's KPI touches, met at the start, paid off at the end (Act III: the storm-night family without power; Act IV: the Havenzij bakery on the waiting list; Act V: Ahmed as trainer; Act VI: the monteur who keeps a paper notebook because the app fails). The thread is the act's cliffhanger device.
3. **Failure as a designed path, not a punishment.** Every act gets one mission where the *expected* first Check fails (a lagging KPI, a wrong but plausible cause) and the real lesson is in the retry: the rework A3, the second gemba visit, the person who was not asked. The debrief for a failed Check must be the best-written text in the act. "Terug naar de gemba" (a discovery) rewards exactly this.
4. **False bottlenecks from tier 3.** The data says one step; the gemba says another (a shared pool, a batch wait, a pre-emption). The fork becomes three-way: bottleneck, non-bottleneck, and the step that *looks* like the bottleneck in the dashboard. Only the tools find it.
5. **Make others see.** The arc of the tiers is a widening lens: tier 1 *you* see waste; tier 2 the *teams* see it (boards, andon); tier 3 the *region* sees flow (VSM, strategy); tier 4 the *system* sees itself (hoshin, audits). Mission goals should move from `solve` toward `coach`, `routine`, `map_stream`, `okr` and `strategy` as the tiers rise, so the player stops being the hero who fixes and becomes the leader who develops others. That is "respect for people" as game design.
6. **Visible history.** From Act II on, the player can see their own story: the strategy screen's open and locked options, the vitrine of discoveries, the Mensen tab with each person's arc, and Ruud's *act-end terugblik*: a short Kata retrospective in which the player writes, in free text, what they learned (kept in the journal, never judged). Reflection is a Lean habit; the game should have it as a ritual.
7. **Hidden rewards with teeth.** Keep the Ontdekkingen honest: each one must reward one of the three principles or a sector insight, never grinding. Silhouettes and end-of-act hints (decided). Add one *regional* reward per tier that only a player who talks to people can find.
8. **Milestones that take no slot** (day 100, the ACM visit, the NTA 8120 audit) are the act climaxes. Build them as *scenes* (the MT room, the inspector at the table), not as a popup.
9. **Shapes.** Nine mission shapes (audit §5.2); no two consecutive mains alike (checked: true today, keep the test). Sides stay small: "one person, one place, one twist, one object".
10. **Correctness is a feature.** Every number from a public source or a marked estimate; every Lean method used the way a Master Black Belt would recognise. The sim-check harness (`draft_check.gd`) runs on every new tier before it enters content. A mission that cannot pass its own Check on the real network does not ship.

### 4.3 Where to take the dialogs next
1. **Voices, not formulas.** The four-tier audit found one narrator creeping in ("Afgesproken." opening 22 of 22 tier-3 commitments; silence as the key to every concern). The fix is a **voice sheet per person** (word choice, rhythm, humour, worry; standard Dutch, no dialect, decided) and three hard limits enforced by a content test: no outcome opener in more than a third of a tier's dialogs; at least a third of concerns revealed by a *feeling* (reflect) rather than a hesitation (silence); interest `via` varies by archetype (craftsmen open to inquiry, defenders to paraphrase, the overloaded to empathy). A player who learns one route must *not* win every talk.
2. **Seven dialog shapes**, so talks feel different: persuasion (bring someone along); check-in (lift a spirit, no mission); expert talk (sector knowledge, topic by topic); customer call (by phone, a promise the game checks); coaching kata (the player asks the five questions, the NPC experiments); confrontation (a hard block with routes); and, from tier 2, the **group talk**: a dagstart or an MT meeting with several people and one *room* meter, where listening to the quiet one changes the room. Catchball in tier 4 is a group talk.
3. **People remember and move.** Trust and morale persist; a retry starts where the last talk ended; arcs cross acts (Marco cynic → ally → fighting for his hours; Anouk drowning → owner → team lead, or leaving if her fix fades and nobody checks in). Every recurring person has a beat in at least three acts.
4. **The walk-around layer.** People who need a talk show a low-energy bar when you pass (decided). Keep it rare (≤ 2 prompts a week, expiring without cost) so a check-in stays a kindness, not a chore. The best clues sometimes come from these talks: the quiet werkvoorbereider knows why the drawings come back.
5. **Dialogs as evidence.** What a person tells you is a clue with a depth; the deep clues come only when the person feels heard. The A3's evidence list shows "gehoord van Joost" next to "geteld bij Intake", and the Check does not care which, but the strategy screen later does ("Marco vertelt je niets meer dan nodig").
6. **Compliance decays.** Already built into the rules (×0.6 / ×1.25). Make it *visible* in the sustain view: a fix won by pressure shows a thinner bar and the person's face. The player should be able to see, months later, why that fix slipped.
7. **Tutorial talks** (Act 0, cannot be ruined, decided) teach the eight MORE PIES moves by name, one or two per day, with Ruud naming the move the player used well. After Act 0 he never names a move again.
8. **Phase 7 keeps the judge.** When Claude voices the lines later, the state model stays the judge, so fairness and tests survive.
9. **Quality bar.** Each dialog is scored on the seven mission criteria plus four of its own: does it feel like a real person; is the meter readable; can the player feel progress without a golden path; would a player quit here. Anything under 25/35 is rewritten before it ships. The content test proves ≥ 3 distinct successful move sequences per persuasion dialog, that pushing early costs, and that pressure yields compliance, not commitment.

### 4.4 The coach
Ruud asks; he rarely tells. The question bank per stage exists and no longer repeats. Next: templated questions that read the main mission's numbers ("De doorlooptijd is nu 54 dagen; wat is je doel?"), the Kata five in order during an experiment, a reflect question that names the fork, the after-talk question after a hard main-mission dialog, and the act-end terugblik (§4.2.6). He never coaches a side mission and never names a dialog move after Act 0.

---

## 5. The world: company, floors, town

### 5.1 Principles
- **The world grows with the acts.** A new room, floor, building or town site opens when a mission first needs it, and the player map grows with it. Nothing is open from the start (progressive RPG); nothing is built before its missions exist.
- **Gemba readability.** Waste must be *seen* from the Sims camera: stacks of dossiers, a full in-tray, a whiteboard with stale dates, a rack that is empty, a van with the wrong joint, a queue at the counter. Each active problem has at least one visible tell, ambiguous enough that only tools and questions settle it ("nothing is handed over": a stack can be normal).
- **Semi-realistic, scripted first.** Blender via `bpy` builds rooms and props (consistent, licence-free, re-bakeable); characters by the method Merijn chooses (§7 Q1). CC0 textures where the network allows. Lightmaps baked.
- **Seams, not loading screens.** Floors and buildings connect through stairwells, doors and the yard; the van to town and to the other areas is a short map travel with a drive-by view, never a driving game.

### 5.2 The campus in Nova (built across Phases 1–4)
| Place | Opens | What happens there |
|---|---|---|
| **Hoofdgebouw, 1e verdieping — Aansluitingen** (exists) | Act 0 | Intake, Werkvoorbereiding, the Obeya wall, Ruud's room, the mission board; later Revisie & GIS and Meetdata & registratie on the same floor |
| **Hoofdgebouw, begane grond** | Act I | Ontvangst, the Klantcontactcentrum (Esra and her agents, the headsets, the El Amrani calls), the kantine (check-ins happen here) |
| **Hoofdgebouw, 2e verdieping** | Act II | Directie & Obeya (the KPI board's home), Netstrategie (Femke's board), the congestion desk, the MT room (day 100, the ACM visit, hoshin), Frank's office |
| **The yard: magazijn, werkplaats, bussen** | Act I sides | the van park, the kanban wall, the storeroom racks, monteurs leaving and returning |
| **Opleidingsterrein** | Act I (Henk) | TWI by doing; the training-capacity missions of tier 3 |
| **Bedrijfsvoeringscentrum** (control room) | Act III | shift handover, the storm night, escalation; the first night scene |
| **IT-gebouw** (or a floor) | Act VI (tier 3) | the field-app team, the release train, test environments |

Three floors is the right size for the head office: it mirrors how a DSO's office works (customer-facing below, operations in the middle, direction above), gives the player map a vertical story, and keeps each floor small enough to walk in a minute. Lifts and stairs are the seams; the player map gets a floor switch.

### 5.3 The town of Nova and the region (Phase 4)
- **Nova** is the gemba of the field. Build it as *sites* first, each a small hand-built scene a van drives to: a street with an open trench (graafschade, the KLIC map in hand), a home's meterkast (niet gereed, niet thuis), a trafohuisje (the heatwave), a hall on the industrial estate (the congestion customer), the El Amrani home (home visits once the town exists, decided). Then the streets between them, solar roofs, chargers, a primary substation on the edge. Outages darken streets at night.
- **Lindeveld** (rural: long drives, one depot, five monteurs) and **Havenzij** (port: crowded underground, nitrogen, six monteurs and three draughtsmen) are small depots with their own people, reached from the region map. They are inside Zuidmark (decided).
- **Vans** carry the shared-pool story: you see them leave for storingen and not come back for the planned job.

### 5.4 Characters and animation
Samples exist (scripted Blender: clear at camera distance, mannequins up close). Decision pending (§7 Q1). Whatever the method, the needs are: ~30 named people by tier 4 with distinct silhouettes (role, age, PPE), idle/work/walk/talk animations, a face readable enough for the mood word to make sense, and a hover name tag. Fix the known issues: the walk animation paced for 1.2 m/s against a 3 m/s player speed; 3.5–4.2 MB per glb.

---

## 6. Working agreements

### 6.1 Roles
- **Fable** plans and reviews direction (this document). **Opus 5.5** executes with agents. **Merijn** decides, playtests and answers the multiple-choice questions.
- **Agents, every session:** (a) a *mission-and-dialog builder* in the main tree (content, rules hooks, schema); (b) a *mission-and-dialog designer/auditor* in docs (new tiers, dialog scripts, audits, voice sheets); (c) when a tier enters content, a *simulation checker* and a *source verifier*. At least one of (a) or (b) is running at all times; if not, Claude tells Merijn. Other agents (UI, world, rules, QA, art) work in **git worktrees** and merge through the coordinator.
- **The coordinator (Opus main)** pushes every agent commit after a clean-worktree gate, at least every 30 minutes (a `send_later` check-in), so CI never goes quiet. Agents commit by explicit paths, never `-A`, and never push.

### 6.2 Rules of work
- Superpowers skills per CLAUDE.md §3: brainstorming before a feature, writing-plans for multi-step work, TDD (watch it fail), systematic-debugging, verification-before-completion, requesting-code-review before a phase gate, `simplify` after every change.
- The full gate before every commit (§1). Screenshots for anything visual, and *look at them*.
- PLAN.md is updated inline: a ✅ the moment a task is done; a ⬜ the moment one is found. Design calls Claude makes without Merijn go under "Claude's calls, pending Merijn" (§10); the ~40 small open questions in the specs take their recommended option (decided).
- Evidence first: a number from a public source or a marked estimate with reasoning, in the content file.
- Unfinished work never lives only in a worktree or a stash at session end: save it as a patch under `docs/handoff/` and point to it here.
- "Send now" in the app interrupts every running agent and a stopped agent cannot resume: relaunch it fresh, pointed at its worktree.

### 6.3 Questions for Merijn
Asked as multiple choice with a recommended option, batched at the end of a session (or when a decision blocks a phase), never one by one during his day.

---

## 7. Questions for Merijn (open)

1. **Characters:** (a) **an asset pack plus motion-capture animation, re-dressed in Blender for Voltana's uniforms and PPE** (recommended: real faces and hands, good walk cycles, our own clothing; licence to check) · (b) an AI character generator per person (unique faces, licence and consistency to check) · (c) keep scripting in Blender (full control, mannequin look).
2. **The town:** (a) **sites first, streets later, van as map travel** (recommended) · (b) a full walkable town from the start of Phase 4 · (c) the town only ever as sites.
3. **Release target for the first public build** (Phase 6): (a) **a private web/Windows build for friends and colleagues** (recommended first) · (b) itch.io · (c) Steam.
4. **Language:** (a) **Dutch only** (recommended until the game is proven) · (b) plan English from Phase 3 on.
5. **Act-end terugblik with free text** (§4.2.6): (a) **yes, kept in the journal, never judged** (recommended) · (b) no free text; Ruud's questions only.

---

## 8. Problem ideas backlog (keep growing)

Standing instruction from Merijn (2026-10-12): the v1 mix of 18 problems is fine, but the game needs more as it grows. Whenever a new problem idea fits the game or a difficulty tier, add it here, then promote it into the catalogue for the tier being built.

| Tier | Idea | Stream · waste | Grounding / note |
| --- | --- | --- | --- |
| 1 | LMRA as a tick-box: the last-minute risk analysis is a long generic form signed without looking | field work · over-processing | safety culture; stop-the-work |
| 1 | Contractor rework: jobs by contractors fail inspection and need a second visit | connections · defects | contractor model |
| 2 | Cause recorded as "onbekend": most outage causes are never classified, so repeat faults stay invisible | outages · defects | Nestor outage registration |
| 2 | Control-room shift handover loses open actions | outages · waiting | — |
| 2 | Heatwave transformer overload: no load monitoring on distribution transformers | congestion · defects | summer events |
| 3 | No space under the street (ondergrondse drukte): coordination with gemeente and other utilities | connections · waiting | — |
| 3 | Nitrogen permits delay a substation project | reinforcement · waiting | construction exemption scrapped; >300 Liander projects late |
| 4 | Power theft and grid losses: cannabis farms hidden in the data | grid · defects | ~1 billion kWh a year |
| 4 | NTA 8120 / ISO 55001 audit finding: maintenance not risk-based (oil-paper cables, old joints) | assets · over-processing | NN-CAM 5.0 |
| 4 | Gas-grid maintenance while the grid is being phased out (heat transition) | gas (later) · over-processing | — |
| 2 | Safety stock sized on calendar days while demand only comes on working days: a 10-day lead time holds 8–9 working days, so the reorder point is too low and meters or kits run out "unexpectedly" | meters, connections · waiting | found while tuning the simulation (2026-10-12) |
| 2 | Work in progress handed over at the end of a shift without notes: the next crew starts the fault-finding again | outages · over-processing | handover is now simulated |
| IT | Field app releases twice a year; every fix waits for the release train | IT · waiting | Phase G |
| IT | Test environments scarce; teams queue for them | IT · waiting | Phase G |

---

## 9. Decisions Made

- **The story arc is *Drie winters* (Fable's call, 2026-10-16, on Merijn's invitation to change the arc; pending his read).** Three years with a winter each as the test of what the player built; the waiting list as the north-star number; Ruud seconded for a year with Frank as interim director (path-dependent sponsor or regime); the coach by phone once a month in that year; Ruud's retirement as the last deadline; the succession as the finale, with the successor depending on whom the player developed. Full text in §4.0; the catalogue's 94 missions stay, regrouped. Easy to reverse: the act content is unchanged, only the beats, the openings and the finale move.

> Phase letters in older entries (Phase A–H) refer to the archived plan: A engine, B content, C world, D UI, E first playable, F depth, G IT, H AI voice. They map onto §3 as: A/B/E → done or Phase 1–2, C → Phases 2–4, D → Phase 1–2, F → Phases 3–5, G → Phase 4, H → Phase 7.

- **Answers on missions and dialogs (Merijn, 2026-10-15, multiple choice).**
  - Dialog meter: a bar that fills (openness), with arrows (▲/▼▼) for each reply's effect, no numbers. People met while walking around show a low-energy bar, inviting a spirit-lifting talk.
  - Reply chips: all moves always visible. The first two talks (Act 0) are tutorials that cannot be ruined. Colleagues leave rarely (morale < 20 for 60 days and two ignored check-ins), closing a door, never the game.
  - No dialect: standard Dutch for every character.
  - Sustaining pays as a dividend at 90 and 180 days for a fix that holds. Overloading a team (> 95 % for 14 days under the player's experiment) costs trust −1.
  - Hidden rewards show as silhouettes plus end-of-act hints in the codex.
  - IT track: the field app comes first in tier 3, as in the catalogue (not the agent's proposed customer-first order).
  - Customers are met by phone at the contact centre now; home visits come with the town map.
  - Engagement red lines are a CLAUDE.md §2 rule ("Respect the player's time").
  - The ~40 smaller open questions in the specs take their recommended option; each is logged under "Claude's calls, pending Merijn" so Merijn can overrule.
- **Mission agents own dialogs too, continuously (Merijn, 2026-10-15).** The mission agents create, improve, redesign and audit dialogs as well as missions, always with at least one active; bad dialogs make players quit. Dialogs show a visible openness/trust meter (feeling, never the right reply); compliance without commitment decays faster (approved).
- **Dialogs as give and take (Merijn, 2026-10-15; now a CLAUDE.md §2 rule).** Missions can hold dialogs with managers, customers, employees and others: they voice struggles, resist or block changes, and the player must bring them along (change a view, get the right KPIs used, win support). Never one right answer; progress comes from listening and perspective (MORE PIES). A ruined dialog costs a few points and can be retried later (e.g. after a day). Some dialogs build trust or lift spirits with no mission attached (respect for people). Design spec: `docs/superpowers/specs/2026-10-15-dialog-system-design.md` (written 2026-10-15); build tracked in Phase B ("Dialog system: build per spec"). ⬜
- **Dialogs show a visible openness/trust meter that shows feeling, never the right reply (Merijn, 2026-10-15); compliance without commitment decays faster (approved).**
- **Reward deep thinking, under three principles (Merijn, 2026-10-15; now CLAUDE.md §2 mission system).** Long-term thinking outweighs short-term in 95% of cases; respect for people comes first (trust and reputation also measure it: keeping, developing and rewarding talent pays); always improve. Mission rewards and consequences must follow these. Passed to the mission agents.
- **Sustain or decay, and stagnation is regression (Merijn, 2026-10-15; now CLAUDE.md §2 rules).** Decay is graded by the strength of the sustaining habits (standard work, visual management, leader routines, steering KPIs), so even a standardised fix erodes, slowly. Plus a slow drift that sets processes back when the player stops improving. Built 2026-10-15 (Phase B).
- **How decay works (Merijn, 2026-10-15):** "Standardised fixes also decay: slowly, but faster the longer you don't do something about it, until at some point you get a mission to have a look at it. Also, the stronger the sustaining mechanism, the less it decays. Especially if audits and routines are planned: then it doesn't decay, it stays the same." Built as: wear accelerating with neglect, a check-in side mission at a threshold, a longer life for stronger habits, and planned routines that stop the wear.
- **Reputation is a separate measure (Merijn, 2026-10-15)**, not folded into budget or XP. To design and build.
- **Belts rescaled (Merijn, 2026-10-15).** To apply to the belt thresholds.
- **Tier-3 areas sit inside Zuidmark (Merijn, 2026-10-15)**: the harder content stays in the same region, not a new one.
- **Answers to Claude's open calls (Merijn, 2026-10-15, multiple choice).**
  - **Kept as built:** "Capaciteit" as a predictable A3 KPI; a 5-day training week, always skippable; orange mission places on the map; the KPI board compares with the habit, so a good choice pays every quarter.
  - **Sector depth: all three.** Glossary cards, a conversation with an expert (e.g. a grid planner on congestion), and a sector side quest.
  - **The coach is a man:** Ruud Hoekstra, Directeur Netbeheer regio Zuidmark (name chosen by Claude; replaces Marleen Verhoef).
  - **Characters:** pending Merijn's choice of method (Blender script, AI generator or asset packs). Samples built 2026-10-15: `tools/blender/build_character.py` makes the player, Ruud Hoekstra and a monteur in PPE (rigged, idle and walk, textures embedded); renders in `docs/screenshots/characters_*.png`. The player scene uses `sample_player.glb` already.
- **Third person, not first person (Merijn, 2026-10-14).** The player sees their own character from slightly above. Camera: **Sims-like** (Merijn agreed, 2026-10-14) (a raised, rotatable, zoomable camera; click or WASD to move), because a gemba game is about seeing the whole flow: stacks of work, queues, who is busy. This makes a player character, and so the people question, part of the next 3D step. ✅ Built (2026-10-15): a visible player (`player_avatar.tscn`: a capsule stand-in, replaced by `assets/characters/sample_player.glb` with idle/walk when that file is there), a camera rig (`camera_rig.gd`: follows smoothly, Z/C or right-drag turns, the wheel zooms 2.5–18 m, close by it looks lower across the desks so stacks and boards read, the ceiling is cut away and the camera stays over the floor), WASD relative to the camera and click-to-move over a walk grid baked from the office's collision navmesh (`office_nav.gd`). Clicking a ring walks there and opens it; using a place (E, a ring click, or holding right-click still) frames its workstation close by until the panel closes or the button is let go; the ring under the cursor lights up. Rotation is Z/C, not Q/E, because E stays the use key. The mouse is no longer captured. Rules, UI, map and office model unchanged.
- **The Check labels lagging measures (Merijn, 2026-10-14).** A measure that only moves after about one lead time (lead time, first-time-right of finished orders, on time) is marked "volgindicator: effect zichtbaar na ±1 doorlooptijd" in the Check panel, so a dip right after a fix reads as a lesson about leading and lagging indicators, not as failure.
- **Training arc details (Claude, 2026-10-14, for Merijn to confirm).** The week is the default for a new game; the story walk (`walk_connections`) counts as done once the week ends, as it does for a returning player. Wednesday's lesson uses a marked training setup so the measured queues give a clear answer, and the debrief names whatever the counts say.
- **Training arc built with Claude's recommended answers (2026-10-14; Merijn asked to continue without reviewing).** 5 days, skippable for returning players, short glossary cards, an invented practice problem. Each one is easy to change once Merijn answers.
- **Player map and training arc (Merijn, 2026-10-13).** Both go into the plan (Phase C and Phase D), not to be built right away.
- **Prototype and KPI reward (Merijn, 2026-10-13, multiple choice).**
  - **The 3D world comes first** for the prototype (est. 1.5–2 months to first play). The first piece is **one building with one mission**: the connections office (Intake, Werkvoorbereiding), walkable, with its gemba tools and one mission playable end to end.
  - **3D style: semi-realistic.** Models are built by script in Blender (`bpy` from PyPI) and exported to Godot as glTF. CC0 textures (Poly Haven, ambientCG) are used once the environment allows their domains.
  - **KPI board reward: counterfactual, paid at the review.** From the same moment, the coming quarter is simulated twice with common random numbers, once with the old KPIs and once with the new ones, and the review pays the difference. The coach words it as a forecast.
  - **Autonomy: design, then build.** Claude writes the designs and builds; calls Merijn hasn't made are listed under "Claude's calls, pending Merijn".

- **Problems only through missions; occasional forks (Merijn, 2026-10-13).** Never more than one main and three side problems at a time, and no free menu of problems. Sometimes the main quest forks into a bottleneck and a non-bottleneck problem, so the player has to prioritise. Recorded in CLAUDE.md §2.
- **Review answers, round 2 (Merijn, 2026-10-13, multiple choice).**
  - **Kept as built:** the close-out spiral (mild); Henk; the bad period (−3 points); trafo ×1.75; 3 in 10 tap changes that don't hold; 62% use of contracted capacity; use-it-or-lose-it at tier 2; 9 in 20 incomplete applications; the wrong joint ×1.5; three signatures; design +30%; a two-day re-plan for pulled monteurs; 4 in 10 grid studies; 3 in 10 silent meters; 1 in 10 failed registrations in the base; a measuring week, with 4 in 10 ending in a tap change. The earlier "kept as they are" values were also confirmed.
  - **Changed:** voltage complaints 2 → 5 a week in the base (15 with the problem); permits batched per project (about every two weeks, an estimate) instead of a weekly run; the grid analysts serve congestion requests before connections, so connections now pay for De netstudie-wachtrij.
- **Core directives (Merijn, 2026-10-12).** A learning game about continuous improvement (Lean, later IT/Agile/DevOps/SAFe) in the energy sector; people are the most valuable resource; an RPG where the player searches and thinks; fix processes end to end (a non-bottleneck fix brings nothing); a strong focus on measuring (KPIs, OKRs); the 8 wastes and sector issues come up often. Recorded in CLAUDE.md §2.
- **Never game over (Merijn, 2026-10-12).** Claims cost money and the region can go into debt and a bad period, but the company never goes down.
- **Henk is a side mission with a deadline (Merijn, 2026-10-12).** Missing it means doing without the knowledge transfer: the countermeasures that need Henk are gone; the problem can still be solved another way.
- **Superpowers is a core skill (Merijn, 2026-10-12)**, in CLAUDE.md §3.
- **Mission system (Merijn, 2026-10-12).** The game is a progressive RPG: missions unlock new and harder missions as the player progresses. At most one main mission and three side missions are active at once. A senior manager coaches, mostly by asking questions, and only on the main mission. Recorded as a standing rule in CLAUDE.md §2.
- **Review answers (Merijn, 2026-10-12):**
  - connections norm: the industry norm (the 18-week term the ACM still uses as reference);
  - digging-damage claims count as money;
  - failed trips 1.5 h / 0.5 h: fine;
  - the revision backlog's effect on digging damage is based on evidence where it exists;
  - the intake checklist is a real but weak improvement;
  - Henk: explained (the retiring expert in De laatste kennisdrager's clues), proposed as a deadline mission.

## 10. Claude's calls, pending Merijn

Each call is easy to reverse; Merijn can overrule any of them. Newest first.

### Claude's calls, pending Merijn (2026-10-16, Drie winters into the catalogue)
By the design agent, recommended options per the standing rule; details in `docs/superpowers/specs/2026-10-16-drie-winters-arc.md` §11.
- **The first frost period is day 70 (21 December 2026),** an estimate: the national average first frost night is 21 October (1991–2020), but one frost night leaves no family cold. The El Amrani call opens on day 49 from the milestone for a player not yet in `fix_status_callers`. Winter 1 passes by delivery *or* by the heat pump on the existing connection (the hidden proposal a listener finds).
- **The storm waits for Ruud's secondment** (its first occurrence), in the storm season October–March (KNMI).
- **Ruud's last day is the first 1 April at least 240 days after Act V opens** (AOW age 67 + 3 months in 2029–2030). PLAN §4.0's "comes back in the spring" is read as: he returns when Act V opens and *leaves* in the spring. Missing the date means he is not at the finale's table, never a failure.
- **The player chooses the successor** among the candidates the play qualified; Lotte Smit (external) is always offered. The finale is kind `finale`: no slot, cannot fail; free play continues after it.
- **The regime's way back** is a team-led kaizen week with Frank's agreement (`frank_interim`); one MT talk cannot flip a regime into a sponsor (path dependence), it only shapes the year's start.
- **Ruud is a dialog target only twice** (the farewell, the successor choice), both unruinable; a new archetype `mentor`.
- **The secondment is to the real Landelijk Actieprogramma Netcongestie**, with Ruud fictional.
- **`t3_interim_mt` is a short main** (the Act IV opener; one group talk).
- **Fixed in the El Amrani call:** its dates predated her request (now September–October), "bijna november" became "elke nacht kouder", the promised date is `{promise_date}`.

### Claude's calls, pending Merijn (2026-10-12)
Merijn asked me to fix the content review's findings with my own judgement while he is away. Each call is easy to reverse, and the same questions sit in the review doc.
- ~~Connections norm: six weeks~~ → answered: the 18-week industry norm.
- **Graafschade hurts through pulled monteurs**: daytime outages ×1.5, and planned connection work is interrupted and re-planned. Answered: claims count too (€4,250 a week).
- **A failed trip costs the trip** (1.5 h at a meterkast that is not ready, 0.5 h when nobody is home), not the full job.
- **De revisieberg feeds Graafschade in the simulation**, not only in the clues. Answered: base it on evidence; now +5% daytime outages and €425 a week, marked as an estimate.
- **Kept as they are, plausible and grounded:** the contact-centre spiral of Klaar maar niet af, the monthly EAN batch, three times as many calls from late customers, 40 minutes to the warehouse, two of five meterkasten not ready, three of eight not at home, 240 open revisions.
- **Henk becomes a story hook** for the missions (built: a deadline mission); the buddy system's team hours stay as they are.
- ~~Still open: the contact-centre spiral~~ → answered 2026-10-13: keep it mild.

### Claude's calls, pending Merijn (2026-10-15, mission system phase 2)
Made by the mission agent while building waves 1–3; each is easy to reverse.
- **Repair quests** look at a poor fix after 42 days, then weekly, and open only with a ≥ 5 % KPI gap to the best countermeasure over a 28-day forecast (estimates, `rules/repairs.gd`); 150 XP. A rework's Act pays the problem's score again, like any Act.
- **A poor fix** (fact `poor_fix:`): the countermeasure fits 0.2 or more below the problem's best, or the A3 named a wrong root cause (catalogue §2.15 thresholds, estimates). Recomputed at every new Act, so a better later fix clears it.
- **Merijn's answers to the audit's §8 (2026-10-15), recommended options, as built or planned:** (1) Act II opens with Graafschade, De revisieberg follows ✅; (2) the El Amrani dossier as a followed order (a sim tag) ⬜; (3) the non-bottleneck fork's freed monteur hours feed `t3_crew_strategy` (tier 3) ⬜; (4) `fix_planning_reshuffle` trimmed to four clues ✅ (the "Er zijn elke dag storingen" quote dropped); (5) Ahmed as trainer in Act IV after the buddy or TWI route ⬜ (tier 3); (6) hidden rewards with silhouettes and end-of-act hints; (8) the borgingsdividend; (9) overload costs trust; (10) containment for safety missions.
- **Revision backlog keeps throughput** as its KPI (audit L5 not applied): measured, a wip_age prediction cannot move in the Check (see Phase B correctness fixes). Later moved to capacity by the Check agent (see below).
- **Mission glossary cards give context, not the answer:** the catalogue listed teaches such as poka_yoke on the incomplete-application mission; a card handed over on accept would name the fix, so those cards come with the Act (problem `teaches`) instead.
- **Reputation deltas** (all estimates, `rules/reputation.gd`): the catalogue's §2.7 numbers, plus +2 for redoing a faded mission (the audit's "owning a regression"). Reputation is never scaled by the score: the MT sees the mission done; the score pays in XP and budget.
- **Mission rewards follow the score:** half of a solve mission's XP and budget is for finishing, half for the PDCA score (`0.5 + 0.5 × total / 25`, at least 0.6). The audit proposed `× total / 25`; the floor keeps a poor fix from locking a player below the green belt (the validator checks reachability at 0.6).

### Claude's calls, pending Merijn (2026-10-15, the Check and recovery from debt)
Made while fixing QA autoplay findings 4, 5, 6 and 21. Numbers are estimates, marked in `region.gd` and `pdca.gd`.
- **The Check is a forecast, like the KPI review and the Friday lesson:** after the two-week experiment, the coming lead time is run twice (with and without the fix), so the verdict is the fix's own effect, not the stream's trend. The game clock does not move. The horizon is one lead time of the orders the problem holds up plus eight weeks of measuring, at least a quarter and at most three (grid reinforcement waits seven months: its Check looks half a year ahead).
- **A pass needs both:** the countermeasure works (fit × maturity ≥ 0.5, as before) and the predicted KPI moved by more than 2 %. A too-early countermeasure still fails as too_early even if its numbers move a little ("it only half works").
- **Noise:** paired runs drift apart once the fix changes who works on what. The 2 % band is below the drift of first time right and WIP age on KPIs a fix does not touch (up to ±10 % between the runs), so a lucky guess of an untouched KPI can pass; the score's prediction_wrong note still catches it. The expert's KPI moved beyond 2 % on every seed in the probe after the content changes below.
- **Content KPIs changed to what each best fix moves within the Check:** De onvolledige aanvraag, Graafschade, De netstudiewachtrij and De revisieberg capacity; Gereserveerd maar ongebruikt throughput. First time right over finished orders lags behind a fix that removes rework (a returned order finishes weeks later), so for a problem opened at the mission's start it shows on some seeds only. A KPI over the orders that entered after the fix (a cohort) would let these name first time right again; not built.
- **A step that is not the bottleneck now fails its Check** when the A3 predicts throughput or capacity (not_moved, with the bottleneck warning), instead of passing with a low impact score.
- **A countermeasure that misses the cause does nothing** (was: weakens the problem by 10 %).
- **A wait step has no bottleneck question:** its impact is the lead time it takes out (5 points at ≥ 10 %, 4 at ≥ 5 %, 2 above the noise).
- **Recovery from debt:** a floor at −€50,000 (the size of the starting budget; the directie carries the rest) and savings from held fixes (each year a fix holds, the grant for a perfect result on it; €96–346 a week a fix, at the fix's health), only while the team at the fix trusts you. In debt the bad period stays until the budget is positive again.

### Claude's calls, pending Merijn (2026-10-15, sustain and drift)
Made while building Merijn's two new rules and his answer on decay; spec `docs/superpowers/specs/2026-10-15-sustain-and-drift-design.md`. All numbers are estimates, marked in `game/src/rules/sustain.gd`.
- **Sustain weights:** standard work 0.6, a board on the stream 0.2, KPIs the team steers by 0.2. Only the Obeya is tagged `sustains: true` (the capacity dashboard is about usage data, not a daily board of the work). "Steers by KPIs" means a team at the fix's step has KPIs chosen on the board; KPIs carry no link to a problem's KPI yet.
- **Wear curve:** `wear = (neglect / L)²` and `L = base / (1 − 0.9·S)`: standard work alone gives 2.2× the countermeasure's `decay_days`, all habits 10×. At S = 0 a fix lasts exactly its `decay_days` (today's timing). A fix with `decay_days: null` (built in) now lasts about a year of neglect.
- **Partial return:** the problem's factor and addition effects come back at (1 − health), its levers (rules) only when it recurs; its cost per week too.
- **Recurrence threshold:** health 0.5. Between recurrence and accepting the reopened mission the problem does nothing (problems only through missions).
- **Check-in:** opens at health 0.75 for standardised fixes only (an unstandardised fix has nothing to audit and fades back to its mission as before); a side mission (takes a side slot, no coach), 100 XP, no budget; rewarded once; comes back when the fix slips again.
- **Audit:** an hour; refreshes standardised fixes at that place only. **Routine:** 2 team hours a week (availability effect on the place's team); it holds standardised fixes only (a routine holds people to a standard).
- **Drift:** starts when the campaign opens; 28 days of grace, full after a further 365; at full demand ×1.06 on connections and congestion (no clean public growth figure; Netbeheer Nederland reports ~107,000 small connections a year at a flat pace while waits grew), availability −3 % (~10 % turnover × ~4 months to productivity), first-time-right −2 points. A resolved Act resets it fully (an improving organisation absorbs the growth).

### Claude's calls, pending Merijn (2026-10-14, training week)
- **"Capaciteit" is now a KPI the A3 can predict** (needed so the practice problem's fade shows within 30 days). This also affects scoring for the real problems; confirm or revert.
- **The practice problem now sits at Werkvoorbereiding**, and the course setup (three of four work preparers away) runs all week, so Wednesday's bottleneck and Thursday's fix tell one story. Its harm is touch time ×1.12 (invented, training only).
- **Friday's lesson compares two futures** on copies of the network ("Met borgen" / "Zonder borgen", 30 days); in a probe, capacity was 35.0 vs 31.4 a week. The game clock does not move.
- **Friday starts Monday 19 Oct** when Thursday's 3-day Check ends on a Sunday; the day title follows the real weekday.
- Earlier calls from this week: `walk_connections` counts as done after the week (the office only has Intake and Werkvoorbereiding); Monday visits those two places only.
- Screenshots `play_training_board.png` and `play_timelapse.png` still show the earlier version; they need refreshing.

### Claude's calls, pending Merijn (2026-10-13 night, office slice)
Made on my own while you were away; each is easy to reverse.
- **The map marks the active mission's places in orange**, including the place where its problem shows. Today every briefing names that place already; a later mission that keeps its place secret would need the marker off.
- **The map is a panel:** you stand still while it is open; there is no mini-map while walking.
- **Problems teach `waste_<waste>`** (renamed from bare waste ids) so each waste has one glossary entry. Saves made before tonight may hold the old ids; harmless, they no longer match a glossary entry.
- **Two glossary sources to verify:** `ean_code` (eancodeboek.nl) and `middenspanningsruimte` (typical 10 kV / 400 V values, an estimate) are marked `verify: true`.
- **Training arc:** a draft only (`docs/superpowers/specs/2026-10-14-training-arc-design.md`), with four questions for you.

### Claude's calls, pending Merijn (2026-10-13, department KPIs)
Rulings I made while building the KPI board without you; each is easy to reverse.
- **Output KPIs also make a team hurry.** `intake_output` and `work_prep_output` set `care: hasty` besides push + shortest first (the spec table had push + shortest only). The probe showed care is where KPIs act in the simulation; rushing for a weekly number is Goodhart's law. Revert: two lines in `content/kpis.yaml`.
- **KPI's die elkaar bevechten names first-time-right** as its KPI instead of the age of open work: the harm shows as rework (FTR 42% → 35%), not as waiting, because design is not the bottleneck.
- **The first review only sets the baseline** (no reward): the Check already paid for the Obeya fix that unlocks the board.
- ~~**The reward only pays for real, lasting gains**~~ (superseded by the counterfactual reward below): each measure is compared with the best level reached so far, only on streams the departments touch, and only the part above a 5% dead band pays; each KPI's change is capped at ±50% and a stream needs 10+ completions in both quarters (all estimates). The final review measured that without this the board paid for noise and for recovering from a bad quarter.
- ~~**Open question for you:**~~ → answered 2026-10-13: (b), the counterfactual reward, paid at the review (it replaces the best-level guard above). The question was: in the simulation a department's KPI choice moves the end-to-end numbers less than quarter-to-quarter noise, so with the guard above the board almost never pays (measured: 1 payout of 0.002 in 24 quarterly reviews with nothing changed; each measure's best level is set by a lucky quarter). Options: (a) keep it: the lesson is that targets matter less than fixing the process; (b) a counterfactual reward: at the review, simulate the quarter with the old and the new KPIs and pay the difference; (c) stronger KPI effects (care, pull) so the choice shows in the numbers. The board also cannot tell a KPI gain from another mission's fix in the same quarter.
- **Counterfactual reward, built 2026-10-13** (spec: `docs/superpowers/specs/2026-10-13-counterfactual-kpi-reward-design.md`). My calls:
  - It compares with the **habit** (no board rules), not with last quarter's choice. Comparing with the last choice would pay for swinging between bad and good KPIs. Against the habit, a good choice pays every quarter it is kept.
  - The baseline review and best levels are gone. The pairing is not perfect (±0.5% between seeds), so a small dead band of 0.3% stays.
  - Measured over 5 seeds: silo KPIs always worse (−0.8%, pays 0), Obeya's lead time + oldest about zero (+0.06%), lead time + complete handover (lagging + leading) always better (+0.76%). The ranking matches your expectation.
  - **Scale:** REVIEW_XP 30,000 / REVIEW_BUDGET €300,000 per 100%, so the best choice earns about 140 XP and €1,400 a quarter after the band, like a small side mission. This is an estimate.
  - A review costs about 2 s of simulation; the UI should show the analyst at work.
- **Precedence:** an open problem's rules beat the board; the board beats a solved problem's countermeasure (reordered with `Network.move_effects_last`, so a running WIP limit is never released); a running experiment still overrides the board.

- **Many healthier processes, not one (2026-10-12).** Problems list several countermeasures with a fit (0–1); each countermeasure brings its own effects and levers, so different players end up with different, all improved, processes. Content values are a reasonable base; the starting problems are active effects on top.
- **What WIP costs (2026-10-12).** Dossiers go stale when they wait too long (quotes, permits, designs need work again); this is what makes WIP limits pay off in the simulation.
- **GDD answers from Merijn (2026-10-12)**: company name Voltana Netbeheer stays; the town is called Nova; a narrative arc with side quests and some open-world freedom; improvements cost both euros and team hours; model ACM regulation and ISO / NTA 8120 asset management; no own energy-sector cases, so content is research-based; sessions of 15–40 minutes; desktop first
- **Problem catalogue keeps growing (2026-10-12)**: the v1 mix is approved; new problems are added continuously via the backlog above, per difficulty tier
- **Pace (2026-10-12)**: multi-month project; design first, reviewed increments, no publishing deadline
- **Grid operator setting (2026-10-12)**: fictional DSO "Voltana Netbeheer", campus + one town; player is CI-lead; game text Dutch
- **Engine: Godot 4 + GDScript from the start (2026-10-12)**, at Merijn's suggestion. The goal is a desktop game, and porting a TypeScript simulation later would mean rewriting all logic. GDScript (not C#) keeps a web export possible. Godot runs headless here, so logic tests run and scenes can be screenshotted (Xvfb + OpenGL compatibility renderer, verified with 4.4.1). The Three.js prototype in `web/` is superseded (kept in `archive/factory-3d/`)
- **Problem solving is action-based, not multiple choice (2026-10-12)**: clues are earned through tools and questions; the player writes the A3; the simulation judges the countermeasure
- **Bottleneck first (2026-10-12)**: Check always shows end-to-end capacity per value stream; improving a non-constraint is called out
- **Shared resources (2026-10-12)**: monteurs are one pool across streams with priorities, so outage-driven disruption of planned work emerges from the simulation
- **Factory work archived (2026-10-12)**: `archive/factory-3d/` + commit `b3a4c8c`; the Python factory game stays runnable as the legacy build

---
