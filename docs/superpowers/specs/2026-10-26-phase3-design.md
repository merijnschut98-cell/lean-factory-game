# Phase 3 — *Voelbaar*: design (Fable with Merijn, 2026-10-26)

Supersedes the roadmap's "Phase 3 — Zichtbaar maken: tier 2 and the campus" (PLAN.md §3). When this spec is approved, PLAN.md §1 and §3 point here and the slice tasks become PLAN 3.0–3.3. Built by Opus with agents, one commit at a time through the gate; the standing rules of the Phase 2 design (§4 "Standing rules") hold unchanged.

## 0. Why this phase, and why not the roadmap's

Phase 2 ended with slices 1–3 built (~250 commits, 1319 Godot tests, the machine half of the gate holding on 18 autoplay runs) and **zero human hours of play**. The slice-1 playtest that was to gate the talk rewrite never happened, so slices 2 and 3 stand on talks Merijn called "not great". The automated personas prove the lessons land in the KPIs; they cannot say whether a talk feels like a person or whether the player feels the company improve.

The harsh assessment that shaped this phase (Fable, 2026-10-26; Merijn agreed with the direction):

1. **Nobody has played it.** Planning another content batch before a human plays repeats the mistake a third time; it is the batch-over-flow anti-pattern the game teaches.
2. **The game measures everything and feels nothing.** Improvement shows on the Check, the KPI board and the prop stacks, not in people. Linda still works late after a holding fix; Ruud says nothing about what changed; nobody is promoted; El Amrani's thanks is a letter.
3. **For a grid operator, the grid is invisible.** Three floors and a yard; most tier-1 problems happen in the field the player cannot enter. A sign-out list on a counter stands in for a monteur driving back for a joint.
4. **Tier 2 is not ready to pour.** The draft's own simulation check (2026-10-15): targets reachable 1 of 9, "best fit gains most" 4 of 11, "the temptation scores lower over a year" 5 of 9; the simulation has moved a lot since, so those numbers are stale both ways.
5. **Repetition would kill Act III.** 34 tier-1 missions of gemba → A3 → Check → sustain, and the draft adds 22 of the same loop. The verb has to change (coach, routine, measure), and those goal types do not exist in the engine yet.
6. **The talk engine is the least trusted and most loaded part.** Phase 3 carries the heaviest talks (Ruud's farewell, Frank's MT, coaching Sanne) on a model no human has judged.
7. **It is long.** The expert persona needs 165 in-game days for tier 1, average 470–580; 94 authored missions over three years.
8. **Decision debt.** About thirty of Claude's calls (§10) and six questions (§7) wait on Merijn; content keeps building on them.
9. **Merijn's playtest is the bottleneck and we treat it as an event.** No jump-to-day, no talk replay; every playtest costs a weekend and answers vague questions.

What to protect: the honest simulation and the fork that proves it; the explainers; the *Drie winters* reversal; the content pipeline with its validators (shape test, spoiler check, debrief guards).

## 1. Merijn's decisions (2026-10-26)

1. **Shape: *Voelbaar*, people and the field first.** Gate: a human feels the company got better because of them (§6). Tier 2 enters only as far as the Act III spine needs.
2. **The talk engine stays; only the writing changes.** The playtest checklist asks one pointed question per talk ("kon je voorspellen waarom dit antwoord werkte?") so a model problem shows after one evening, not after Act III is written.
3. **One real street** in Nova, not sites-only and not nothing (§4).
4. **The Act III spine (about eight missions) with the reversal at its end:** Ruud to Den Haag, Frank's first MT as the first group talk. The other drafted tier-2 missions move to Phase 4 or are cut (§5).
5. **Play length for Acts 0–II: about 15–20 hours** for a careful human. Pacing stays as it is; no cuts to tier 1 for length.
6. **Promotions as presented** (§3.2): a job ladder beside the belts, earned in review talks on results that hold, your people and the customer; colleagues promoted too; salary as feeling only.
7. **Designer playtest tools first**, before anything else in the phase (§2).
8. From the "improvement felt" brainstorm (2026-10-24): approach A (two phone apps plus moments in the world); the four company groups Klant & wachtlijst, Geld, Imago & vertrouwen, Mensen.

**Claude's calls (overrule any):** the English pass moves to Phase 4 (translating talks about to be rewritten is waste); the dagstart becomes a short scene so a day has a visible start, with no other pacing change; the missions.gd and region.gd splits proposed in `docs/qa/tech-debt-2026-10-25.md` happen in 3.0 before new rules land on them; `People.agreed_kpis` is wired into the KPI board in 3.1; the control room is a small building across the yard, not a new campus block.

## 2. Slice 3.0 — *Spelen*: tools, then decision day

The shortest slice (about two weeks of agent time) and the only one with no new game content.

**3.0a Designer tools** (never in the player's build; behind `OS.has_feature("editor")` or a `--designer` flag, and excluded from the export presets):
- **Jump-to-day saves.** The autoplay bot (`game/tools/autoplay.gd`, the expert persona unless named) plays to a day and writes a normal save slot: day 1 (after the training week), day 45 (the fork taken, the winter not yet open), day 70 (the frost), day 95 (before day 100), the start of Act II, the start of Act III once it exists. A hidden designer page on the title menu lists them with the persona and seed. Saves are regenerated by a tool script when content changes (`tools/make_designer_saves.py`), never committed.
- **Replay a talk.** From the designer page: pick any dialog id and a facts preset (none / after a ruined talk / after a kept promise) and play it in the TalkView with the real engine; the summary shows the route taken. Reuses `route_check.gd`'s presets.
- **The playtest log you hand back.** The existing playtest log (`SessionLayer`) gains a designer marker key (F8: "noteer dit moment" with a free-text line) and an export to one Markdown file in the saves folder, with the day, the place, the active mission and the last five events per marker. Merijn pastes that file; the agents read it.
- **Time of day for screenshots and the street:** `play_shot.gd` gains a `--at HH:MM` and `--season` argument (needed by 3.2 and 3.3 anyway).

**3.0b The file splits** from `docs/qa/tech-debt-2026-10-25.md` items 3 and 4 (missions.gd: `Coach` and `MissionSync`; region.gd: `RegionSustain`), behaviour-neutral, same test counts before and after, as TD-2 did for office.gd and session.gd.

**3.0c Decision day.** Merijn clears PLAN §7 and §10 in one sitting (a checklist of the open items is prepared as `docs/qa/decision-day-2026-10.md`: each item, the default, the cost if changed). His slice 2–3 playtest notes land in PLAN §9. The talk verdict (decision 2) is recorded per talk: keep / rewrite / restage.

**Exit:** tools work on the current build; Merijn has played slices 2–3 with the jump saves; the decision list is empty; the splits landed.

## 3. Slice 3.1 — *Mensen*: making improvement felt

### 3.1 People change with the load
The simulation already knows each team's load (`session.energy_of`, `People` morale and needs); today only `late_until` reads it. One rule, `PersonState.strain(team)` (a 0–1 from load above norm, morale and recent pressure), read by four things:
- **Who is still at their desk at 18:30.** Fades within two weeks of a holding fix on the team's stream; returns when the fix slips or the drift bites. The evening light already exists; the player walking out at 17:30 sees who stays.
- **Posture at the desk:** slumped vs. upright (clips exist in Animation Library 2); a hand to the neck at strain > 0.7.
- **Kantine and coffee-corner chatter:** the `chatter:` pool gets a strain condition; complaints vs. shop talk vs. a joke.
- **Absence:** at strain > 0.8 for three weeks, a sick day a week (the desk empty, the greeting missed); the team's capacity in the simulation already drops with a missing person (`People.left` path reused for a day).
Tests: a holding fix at Werkvoorbereiding sends Anouk home at 17:00 within 14 days; a slipped fix brings 18:30 back; no new number is invented (every reading traces to a simulation value).

### 3.2 Promotions
**The player's ladder** (content: `content/career.yaml`, validated): CI-lead Aansluitingen → Senior CI-lead (the year-end review, after winter 1) → Manager Continu Verbeteren (the review after Act II, with a small team: two named people report to you in Wie is wie). A **review talk** is a new dialog kind `review` with Frank and Ruud in the MT room: three conditions, each read from facts and numbers, never XP alone:
1. *Results that hold:* at least N fixes held through their sustain window (N per step; estimates in content);
2. *Your people:* average trust ≥ T in the teams you worked with, nobody left from them, no `pressured:` fact in the last quarter;
3. *The customer:* the waiting list or lead time moved by the step's threshold.
Refusal names the failed condition in plain Dutch and the next review's date; it is a setback, never a dead end. **Salary** is shown in the Ik app only (a Dutch grid-company scale, marked estimate); it feeds nothing.

**Colleagues step up** when your fixes developed them, read from facts: Anouk → team lead Werkvoorbereiding (`skills_matrix_buddy` or TWI held), Ahmed → trainer (Henk's transfer held), Sanne → quality (coached in Act III). Each is a short scene at the coffee corner (cake, Ruud's two sentences, the person's one), a new name tag and title in `company.yaml` (so Wie is wie and the tags follow), a changed greeting, and the team lead's spot in the office. The reverse exists already: burnt-out people leave.

### 3.3 Ruud comments
Three triggers, main quest only, written from facts like greetings are (`coach_comments:` in `dialogs.yaml`, 3 variants each, the style guide and `BANNED_SPOKEN` apply):
- the week after a Check holds: what he saw, never the number ("Ik liep langs Werkvoorbereiding. Anouk ging om vijf uur naar huis.");
- the month a fix slips: a question ("Zag je het bord bij Intake vanmorgen?");
- the monthly figures moment (3.4): one sentence.
Delivered as an in-passing line when you meet him, or a Berichten note if you don't for three days.

### 3.4 The monthly figures moment
First working day of the month, 09:00, from the KPI board's birth (day 100): Frank at the board on the 2e with whoever is there; a one-minute scene (`SceneLines`): the four tiles for the month, one sentence from Ruud, back to work. The only place the company numbers are *said*. Skippable with the usual hold-to-skip; missing it costs nothing (the Voltana app shows the same).

### 3.5 The two phone apps
**Voltana** (`game/src/ui/phone/company_app.gd`): four tiles — *Klant & wachtlijst* (lead time for a new connection, households and firms waiting, on-time vs. the 18-week norm, calls per week), *Geld* (budget, savings from improvements, the directie advance owed), *Imago & vertrouwen* (reputation with the directie, the ACM and the public; customer satisfaction from the followed orders and calls), *Mensen* (morale, late evenings per week, sick days, left, promoted). Each tile: headline number, ▲/▼ since you started, a 12-month sparkline, one line naming what moved it most ("wachttijd −3 weken sinds de intake-checklist", from the Check facts). Reads only what the simulation already tracks; the same numbers Frank says at the board.
**Ik** (`ik_app.gd`): job and salary, belt and XP, "wat ze over je zeggen" (three people's trust in words, from the same bands the pips use), your fixes holding and slipping (from Sustain), the next step's three conditions with ✓/✗.
Both reachable from the phone's home; the old Mensen tab stays in Wie is wie. HUD unchanged.

### 3.6 The Acts I–II talk rewrite
On the voice sheets (`docs/superpowers/specs/2026-10-19-dutch-style-guide.md` plus a per-person sheet in `docs/superpowers/specs/2026-10-xx-voice-sheets.md`, written first), from Merijn's playtest notes and the per-talk verdicts of 3.0c. The content tests of Phase 2 design §2.6 are enforced (no outcome opener in more than a third of a tier's talks; ≥ a third of concerns revealed by a feeling; `via` varies by archetype; per-person never-says words). The three talks the careless persona cannot win (`sanne_checker`, `linda_replanning`, `marco_wasted_trips`) get the coach's listening question after N ruined tries (main quest only). The route check's ratchet may only tighten.

**Exit:** Merijn plays from the day-45 save to day 110 and answers "zag ik iemand veranderen door wat ik deed?"; autoplay on Acts 0–II with the five personas shows the talker's people promoted and never-talks' not.

## 4. Slice 3.2 — *De straat*

**One street in Nova-Oost**, about 120 m, walkable end to end in a minute: twelve houses (one the El Amranis'), a corner with a bakery (Samira's; shut until Act IV), a trafohuisje at the far end, an open trench with a KLIC printout in a contractor's hand, parked vans, two hedges and a canal that hide the world's edge. Built by `tools/blender/build_street.py` from a tiny street graph (`content/town.yaml`: segments, lots, props), CC0 textures, lightmaps for day and a second set or a runtime dim for night (3.0a's `--at`). This script is the seed of Phase 4's town script; nothing is thrown away. People from the cast pipeline: three residents with `day:` schedules, Gert the contractor, Ahmed at the trench.

**Getting there:** the van ride that exists ends at the kerb (`rides:` in `world.yaml` gains the street as a destination); Tab's map gains a *Nova* page; the minimap becomes a street map there; back by the same van. No streets beyond this one.

**What moves onto the street** (from reports and tells): `fix_not_at_home` (ring the bell, the note on the door), the El Amrani payoff (she opens the door; the heat pump hums; winter 1's letter becomes a doorstep scene; missed, the house is dark and she does not open), `fix_digging_damage`'s containment (Gert at the hole; the map that says nothing was there), the trafohuisje explainer (moves here from the training-ground mock-up; the mock-up stays for Henk), and in Act III the heatwave (the trafohuisje's fan, the 207 V complaint, 3.3) and the storm night (the street dark, the control room on the phone). Tells on the street, same rules as indoors: a flickering lamp, a dug-up pavement, a "wanneer?" note in a window; `check_tells` extends to the street. Yard tells that stood in for the field (the uitgiftelijst stays; it is real) are left as they are.

**Budget to know:** the street is the phase's biggest single cost (art, navmesh, lightmaps, night, frame time in the later web export). One agent owns it for the whole phase; a plain look lands before a late one.

**Exit:** Merijn drives to the street from the day-45 save, meets Gert at the trench, rings the El Amrani bell, and answers "voelde de buitenwereld als onderdeel van het bedrijf?"; a screenshot set at 09:00, 17:30 and night.

## 5. Slice 3.3 — *Zichtbaar maken*: the Act III spine and the reversal

### 5.1 The eight missions (half of them not an A3)
Each is redesigned from the tier-2 draft against today's simulation with `draft_check.gd` **before** it enters content, and passes the tier-1 validators (shape test, spoiler check, `POOR_FIX_TEXT_READ_FOR` / `PLAIN_TEXT_READ_FOR`, the title token). Numbers sourced or marked estimate.
1. **`first_daily_board`** (main, `routine` then `coach`): the first dagstart at Werkvoorbereiding as a **group talk** (5.2): Joost, Anouk, two werkvoorbereiders, one room meter; the quiet one knows why the drawings come back. Opens 3.3; the board is a prop with three states.
2. **`coach_sanne`** (main, `coach`): the coaching kata as play. Over three in-game weeks the player asks Sanne the five questions (target condition, actual, obstacles, next step, when do we see what we learned); each answer is hers, written in content with two or three variants per question keyed to what the player asked before; her experiment (a countermeasure she picks from her own short list) runs in the simulation and her Check is hers, not the player's. Reward: Sanne's promotion path (3.2) opens.
3. **`fix_cause_unknown`** (main, A3): outage causes recorded as "onbekend", so repeat faults hide; the control room's first look; Nestor-style registration as the patient fix, a "fill it in later" tick box as the shortcut.
4. **`prep_storm_week`** (milestone + main): the calendar's first season. Code oranje in the autumn (KNMI criteria from the draft); the control room on a storm night (the game's first night), the street dark, the escalation board or its absence; the `storm` event in the simulation (outage arrivals ×k for 36 hours, crews pre-empted). Prepared or not is read from the player's Act III choices (the board, the handover routine, the stock).
5. **`heatwave_trafo`** (side, on the street, July): the trafohuisje under load; the transformer explainer pays off; the 207 V complaint; the tap review vs. the quick cut.
6. **`acm_visit`** (milestone, scene): the inspector at the MT table; the waiting list said out loud (the `waiting_list` north-star KPI enters the HUD from here, per the arc); your numbers or Frank's, read from facts.
7. **`zandbergen_farm`** (the act's human thread, side): the farm at the end of a long line, met at the act's start (a call, a visit on the street's edge), without power on the storm night if the crews were not freed, paid off after the storm.
8. **`lsw_board_round`** (routine): the layered audit as a real recurring visit to the new boards; a routine takes no side slot (the rule Merijn confirmed on decision day or revised).

### 5.2 The reversal
- **`ruud_farewell`** (talk, kind `checkin` with the farewell beat): Ruud goes to Den Haag for a year; the monthly phone call unlocks (`ask_coach` cooldown 28 days, one Kata cycle per call; the coaching-kata missions carry the player).
- **`interim_mt`** (the first MT group talk): Frank's opening state reads the Act II facts (`committed:frank_*`, `blocked:frank`, `heard:frank`): the sponsor opens the year with the Obeya standing; the regime opens it with a dashboard, output targets and the consultancy temptation named. Phase 3 ends on that room; Act IV opens it in Phase 4.

### 5.3 Engine this needs
- Goal types `coach`, `routine`, `measure` in `mission_def.gd` and `missions.gd`, with objective lines.
- **The group talk** (`dialog.gd` shape `group`): several people, one room meter, each person keeps their own position/interest/concern layers; a move aimed at one person moves the room by their weight; listening to the quiet one is the designed route; the TalkView frames the room (the two-shot becomes a table shot), the chooser names whom you address. Built with Act III's two group talks only; catchball (tier 4) later.
- **Seasons and the calendar:** `SimCalendar` season of the date; `opens_on {season}`; the `storm` and `heatwave` events in `Network` (arrival multipliers, a temperature for the trafo model); the HUD's date line shows the season word; the daylight follows (shorter days in winter, the first night scene).
- **The control room:** a small building across the yard (`build_control_room.py`, like the yard), the escalation board as a tell with three states, two shift workers in the cast, the storm-night scene.
- The `waiting_list` KPI block in `kpis.yaml` and on the HUD from the ACM visit.
- The tier-2 problems that these missions use (about five of the draft's eleven) in `content/problems_tier2.yaml`, run through `draft_check.gd` on today's network first; the rest of the draft stays a draft.

**Exit:** Merijn plays Act III from the Act-III save to Frank's MT and answers "wil ik weten wat er gebeurt zonder Ruud?"; autoplay on Acts 0–III with six personas; the route check incl. the two group talks; code review of the slice.

## 6. The Phase 3 gate
- **Human half:** Merijn and one cold player finish Act III. Both say, unprompted in the terugblik's free text or to Merijn, that Voltana got better because of them, and both can name a person who changed. Merijn's four slice questions answered yes.
- **Machine half:** autoplay on Acts 0–III, six personas, three seeds: no dead end by Act III's end for any careful persona; the storm hurts the unprepared (outage minutes ×≥1.5 vs. prepared); the talker's colleagues get promoted and never-talks' do not; careless still recovers from the floor; the route check's ratchet unchanged or tighter including the group talks; frame time on the street ≥ 30 fps on the reference machine.
- A code review per slice; the technical-debt trigger before Phase 4.

## 7. Dropped or moved
- The other 14 drafted tier-2 missions, the first OKR, tiered escalation as a system: Phase 4 (or cut when Phase 4 is planned).
- The English pass (3.7): Phase 4.
- `sector_congestion_map`, `lsw_van_round`, `stagnation_alarm`: unchanged, Phase 4.
- The tutorial for the group talk: Act III's first dagstart is its own tutorial (Ruud names nothing).

## 8. Open questions for Merijn (decision day, 3.0c)
Everything in PLAN §7 and §10 as of 2026-10-26, plus:
- The two names on the Voltana tiles' *Imago & vertrouwen*: reputation with the directie and the ACM exist; "the public" and "customer satisfaction" would be new numbers derived from followed orders and calls. Keep both, or only what exists?
- Does a missed El Amrani winter close her door for good on the street (the house stays dark; her daughter's thread in Act IV reads it), or does a later connection open it?
- Who plays the cold player for the gate.

## 9. Standing rules (unchanged from Phase 2)
One commit at a time through the gate (`scratchpad/gate`, `g.sh`, `land.sh`); every brief repeats the network rule; the style guide and `BANNED_SPOKEN` on every line; a new HUD element only with its first-needed moment; nothing in a panel that could be in the world or on the phone; mission and dialog agents run continuously and Claude says when they stop; unlanded work as a patch under `docs/handoff/`; agents commit by explicit paths and never push; Claude's calls go to PLAN §10; questions that are truly Merijn's go to §7.
