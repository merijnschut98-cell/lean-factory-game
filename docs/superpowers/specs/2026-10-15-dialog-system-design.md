# Dialog system — design

> Status: design by Claude (2026-10-15), for Merijn to review. **Design only; nothing is built.** The build is tracked in PLAN.md ("Dialog system: build per spec", Phase B; its UI in Phase D).
>
> Read for it: `CLAUDE.md` §2, in particular "Dialogs are give and take", "The mission system decides the game", the three deep-thinking principles, "Action-based problem solving" and "Setbacks, never game over"; PLAN.md "Decisions Made"; the mission catalogue (`2026-10-15-mission-system-and-catalogue-design.md`, §2.1 `talk_to`, §2.3 cast, §2.7 reputation and trust, §2.15 facts and needs, C5 and C7); the audit (`2026-10-15-mission-audit-and-engagement.md`, §3A coach, §4 discoveries, §5.3 recurring characters); the tier-2 draft (`2026-10-15-tier2-missions-draft.md`, §1.2, §2.12–2.13, §4 people topics); `game/src/rules/region.gd` (`ask`, `trust`), `investigation.gd` (`QUESTIONS`), `missions.gd` (`ask_coach`, `_goal_met`), `sustain.gd` and `game/src/game/session.gd`.
>
> Merijn's binding decisions (2026-10-15):
> 1. **A visible meter.** Openness and trust in you move after each move, so the player sees the effect of listening versus pushing. The meter shows how the NPC feels, **never which reply is right**. Replies show only their type of move, never their effect in advance. The underlying concern stays hidden until earned; a cue ("Er zit meer achter…") appears once openness is high enough. Tone, body language and wording remain a second layer of cues.
> 2. **Pressure can win compliance; compliance without commitment decays faster** through `sustain.gd` (long term over short term, respect first).

## 0. Summary

- **Recommended approach: a state-driven conversation (approach B, §2).** The NPC has a state: openness, trust in you, mood, and a hidden stack of *layers* (stated position, interest, underlying concern). The player picks a *move* each turn. Eight listening moves are MORE PIES; five steering moves are advocacy (perspective, data, experiment, proposal, ask for agreement); two are pressure and blame. Each move's effect depends on the NPC's state and on what was just said, so the same chip helps at one moment and hurts at another. There is no tree with a golden path. The content authors write *who the person is and what they would say*; the rules decide *how they respond*.
- **The meter:** an openness bar with five named bands (Dicht · Op z'n hoede · Luistert · Open · Denkt mee), trust in you as five pips, the mood as a word and a face, and a small trace of openness over the conversation. It moves *after* each move. The cue "Er zit meer achter…" shows at openness ≥ 65 when the person hesitates. Chips show the move type and, on hover, the line you will say; never the effect.
- **Outcomes:** *staat erachter* (commitment), *afspraak onder voorwaarde* (partial with a condition), *gehoord* (nothing agreed, trust earned), *geblokkeerd* (a hard block: another route needed), *gaat akkoord onder druk* (compliance), *mislukt* (ruined: reputation −1, trust −5, retry from the next working day; the person remembers). A learned concern unlocks a clue, a countermeasure or a fact (path dependence).
- **Commitment versus compliance is tracked as such.** A fix whose owner committed lasts ×1.25 longer; one won by pressure, or acted on without asking the owner, lasts ×0.6 (estimates; multiplied into `Sustain.life_days`). KPIs chosen at the board count fully as a sustaining habit only when the team lead committed to them.
- **Links:** `talk_to` goals and clues, trust per person *and* per team, reputation, the KPI board, sustain and morale, six new discoveries (D29–D34), Ruud's Kata questions after a hard conversation (main mission only), and light, signal-driven check-ins with no mission attached.
- **Cast:** ten recurring people, each with a role, a typical resistance, an underlying concern and an arc: Joost, Sanne, Marco, Henk, Ahmed, Anouk, Petra, Esra, the blocking manager Frank Hulshof (new) and Mrs El Amrani.
- **Two sample dialogs in Dutch** (§7–§8): Joost on his output KPI (tier 1, `fix_silo_kpis`), pushed and ruined, then replayed the next day by listening, plus a pressure path; and a check-in with Ahmed after Henk's farewell, with the "fixing mode" trap and a path that depends on how Henk's knowledge was saved.
- **Twelve questions for Merijn** (§14), each multiple choice with a recommendation.

---

## 1. Constraints this design honours

| Rule (CLAUDE.md §2 / decisions) | How the design meets it |
|---|---|
| Dialogs are give and take; never one right answer | No reply is correct. Every persuasion dialog has ≥ 2 proposals that can win commitment, and a content test proves ≥ 3 distinct successful move sequences (§9.3). |
| Nothing is handed over | Chips name the move type, not its effect. The concern is hidden until earned. The meter reports feeling after the fact. |
| Action-based problem solving | Data you show must be a clue you found. Proposals come from the mission's real options (KPI menus, countermeasures). The simulation, not the dialog, judges whether the agreed change works. |
| Respect for people comes first; long term over short term | Pressure and blame are available and work short term (compliance), but cost trust, morale and sustain later. A ruined dialog costs a few points, never a door. |
| Setbacks, never game over | Ruined → retry tomorrow. A hard block always has a route that cannot be closed (validator). |
| Improvements must be sustained | Buy-in multiplies a fix's life (§5.4). Check-ins keep morale up. |
| The coach helps only with the main quest | Ruud's after-talk questions only for dialogs of the main mission (§5.6). |
| One main, at most three side missions; problems only through missions | Dialogs never open a problem. Check-ins are not missions and take no slot. |
| Evidence first | Every number in §3–§5 is an estimate, marked so, with its reasoning; the method is sourced (§12). |
| Dutch game text, English code and docs | Game lines in Dutch; ids, keys, docs in English. |

---

## 2. Approaches

| | A. Authored branching tree | **B. State-driven conversation (recommended)** | C. Free text with an LLM |
|---|---|---|---|
| **How** | Each dialog is a graph of nodes; each node offers 3–4 written replies that lead to fixed next nodes. | The NPC has a state; the player picks a move type each turn; rules compute the effect from the state and the move; authored *layers* and *lines* give the words. | The player types; Claude plays the NPC, grounded in the person's hidden facts, and scores the move. |
| **Golden path** | Inherent: some branch is the right one, and a retry is memorisation. | None by construction: the same move's value depends on the moment; tested (§9.3). | None, but also no guarantee of fairness. |
| **Teaches MORE PIES** | Only if the writer labels replies, which hands the answer over. | The moves *are* MORE PIES; the player learns their names and when each lands. | Implicitly; hard to give feedback on the skill. |
| **Meter** | Must be authored per node; easy to make it point at the answer. | Falls out of the state; shows feeling, never the right reply. | Possible, but scores drift between runs. |
| **Retry** | Same tree; the player replays the known path. | The person remembers (§3.6); the start state differs; the moves that land differ. | Natural, but unrepeatable. |
| **Authoring cost** | Very high: combinatorial branches per dialog. | Moderate: per dialog a few layers, proposals and override lines; a shared line bank does the rest (§9.1). | Low text, high prompt engineering, plus cost per play. |
| **Testable headless** | Yes. | Yes: deterministic, no randomness. | No: nondeterministic, needs network and an API key. |
| **Fits Phase H** | Replaced later. | **Kept**: an LLM can later voice the lines over the same state model (§14 Q11). | Is Phase H. |

**Recommendation: B.** It is the only approach that makes "never one right answer" structural instead of a writing promise, makes the meter honest (it is the state), keeps retries meaningful (memory changes the start), stays testable like the rest of the rules, and leaves the door open to free text in Phase H as a *voice* on top of the same judge. Its risk, generic-sounding lines, is handled by per-dialog override lines at the moments that matter (position, layers, proposals, outcomes) and by archetype-specific fallback banks.

---

## 3. The conversation model

### 3.1 The NPC's state

| Field | Range | Persistent? | Shown? | Meaning |
|---|---|---|---|---|
| `openness` | 0–100 | per conversation (start derived, §3.6) | **yes**, the main meter | How receptive the person is right now: to hearing you, to sharing, to changing a view. |
| `trust` | 0–100 per person | **yes** (saved) | **yes**, five pips (one per 20) | Trust in *you*. Moves a little within a talk, more on outcomes. Feeds the start openness of every later talk. |
| `mood` | `goed` · `neutraal` · `gespannen` · `moe` · `stil` | derived each day from signals (§3.6) | **yes**, a word and the portrait's face | How the day is going. Sets the start and which listening move is apt first. |
| `morale` | 0–100 per person | yes (saved) | as a band in the Mensen journal only (§14 Q6) | Enthusiasm for the work. Low morale shortens the life of fixes they own; check-ins raise it (§5.4, §5.7). |
| `layers` | ordered: `position` → `interest` → `concern` | revealed layers persist per person | the *text* once revealed; a cue before the concern | What they say, why, and what really worries them. The concern is hidden until earned. |
| `heard` | bool | per conversation | via body language only | The person feels heard: a paraphrase or reflection landed on what they said. Steering before this backfires. |
| `proposal` | a proposal id or empty | per conversation | the chip you chose | What is on the table. |
| `pressured`, `confronted` | bools | per conversation, remembered after | no | Pressure or blame was used. |
| `patience` | moves left | per conversation | body language (looks at the clock), and the line "Ik heb nog vijf minuten" two moves before the end | Busy people give less time. |

### 3.2 The moves

All ids are English; chips show the Dutch label and, on hover, the line the player will say (from the dialog or the shared bank; §9.1).

**Listening: MORE PIES (row "Luisteren")**

| Id | Chip (NL) | MORE PIES | Example line (NL) |
|---|---|---|---|
| `mood` | Stemming peilen | **M**ood | "Hoe gaat het vandaag, echt?" |
| `open_question` | Open vraag | **O**pen questions | "Hoe ziet jouw week eruit?" |
| `reflect` | Gevoel benoemen | **R**eflecting | "Het klinkt alsof je klem zit." |
| `empathy` | Begrip tonen | **E**mpathy | "Dat is ook niet niks, als je zo je best doet." |
| `paraphrase` | Samenvatten | **P**araphrasing | "Dus als ik je goed begrijp: …" |
| `inquiry` | Doorvragen | **I**nquiry | "Wat maakt dat dít het getal is?" |
| `experience` | Ervaring delen | **E**xperience | "Toen ik net begon, had ik precies dat." |
| `silence` | Stilte laten | **S**ilence | *(je zegt niets en wacht)* |

**Steering: advocacy (row "Sturen")**

| Id | Chip (NL) | Pick | Notes |
|---|---|---|---|
| `perspective` | Ander perspectief | — | Invite them to look through someone else's eyes (the monteur, the customer). |
| `show_data` | Data laten zien ▸ | a clue or number **the player found** | Data you did not earn cannot be shown. |
| `propose_experiment` | Experiment voorstellen ▸ | a small, reversible try (the dialog's experiments, or a countermeasure on the A3) | PDCA lowers the stakes. |
| `propose` | Voorstel doen ▸ | one of the dialog's proposals (e.g. a KPI pair from that team's menu, a countermeasure) | Puts a proposal on the table. |
| `ask_commitment` | Afspraak maken | — | Ask for agreement on what is on the table. Decides the outcome (§4). |

**Pressure and blame (small, honest labels, row "Sturen", right side)**

| Id | Chip (NL) | Notes |
|---|---|---|
| `pressure` | Druk zetten | Invoke the MT, Ruud, a deadline. Works short term: compliance. |
| `confront` | Aanspreken | A blaming line ("Jouw team zet toch gewoon te snel door?"). The same rule as the gemba's blame questions (`Region.ask`). |

**Other**

| Id | Chip (NL) | When |
|---|---|---|
| `repair` | Terugkomen op vorige keer | Only on a retry after a ruined, pressured or confronted talk. An apology that names your part. |
| `close` | Afronden | Always. Ends the talk gracefully; never ruins it. |

The listening row always shows all eight, and the steering row all five plus the two pressure chips: a fixed palette. Nothing is filtered by fit, so the palette itself hands nothing over (§14 Q1).

> **Superseded on screen (PLAN 2.13 B, Merijn's playtest 2026-10-19; staged in 2.14 S1-G):** the player no longer picks from a palette of 17 named chips. Each turn `Dialog.offer` gives **four whole sentences** (one move hidden under each, never its name, none styled by fit, at most one costly), keys 1–4, with "Afronden" under them. The moves, their effects and the palette stay in the rules; the move names appear only afterwards, under the curve of the talk's note.

### 3.3 What a move does

All numbers are **estimates**, chosen so that listening first, then steering, reaches commitment in 7–9 moves, and pushing first ruins a guarded person in 3. They live as constants in `rules/dialog.gd` (like `Sustain`), each with this reasoning. Each NPC line carries *tags* (authored): `claim` (a statement of position or fact), `feeling`, `hesitation`, `admission`, `doubt`.

**Listening moves** (Δ openness):

| Move | Lands (Δ) | When it lands | Otherwise (Δ, and the person's reply) |
|---|---|---|---|
| `mood` | +8 | in the first two moves, or when mood is `gespannen`, `moe` or `stil` and not yet asked | +2 ("Gaat wel.") |
| `open_question` | +6 | always; it is the safe move | +3 from the fourth time on (the person has said what is easy to say) |
| `paraphrase` | +7, sets `heard` | the last line was a `claim` not yet summarised | +1 ("Dat zei ik, ja.") |
| `reflect` | +10, sets `heard` | the last line carries `feeling` | −3, a misread the person corrects ("Ik ben niet boos. Ik ben moe."): the correction itself is information |
| `empathy` | +6; +10 after an `admission` | always mild | ×0.5 when repeated ("Ja, dat zei je al.") |
| `inquiry` | +8 | the person has stated a position, and the next layer is within 10 of its threshold | +3 ("Hoe bedoel je?") |
| `experience` | +8 | `heard`, trust ≥ 50, and the last line carries `doubt` or `admission` | −5 ("Het gaat nu even niet over jou.") |
| `silence` | +12 | the last line carries `hesitation` | −4 (awkward: "… Was er nog iets?") |

**Steering moves.** *Pushing too early* means a steering move before `heard`, or below openness 40: every steering move then costs **−12** and the person repeats the position defensively. Otherwise:

| Move | Effect when not too early |
|---|---|
| `perspective` | +8 at openness ≥ 50 (the person tries the other view, an authored `reframe` line); else −4 |
| `show_data` | a clue in the dialog's `data` list: +10 at openness ≥ 55 (curious: "Laat eens zien… van 85 naar 80?"), −8 below 55 ("Dus het ligt aan mijn mensen?"); any other clue: 0 ("En?") |
| `propose_experiment` | +6 at openness ≥ 45; it puts the experiment on the table as a proposal |
| `propose` | the proposal goes on the table. If it `addresses` a revealed layer: +8 and its authored reply. If it addresses the concern before the concern is revealed (a lucky guess): +4 ("Hm. Misschien."). Otherwise 0 and the person names their objection |
| `ask_commitment` | decides the outcome (§4.1) |

**Pressure and blame:**

| Move | Openness | Trust | Also |
|---|---|---|---|
| `pressure` | −15 | −8 | sets `pressured`: an agreement in this talk is compliance (§4.2) |
| `confront` | −20 | −10 | team trust −1 and the team's open problems get `blamed` (the existing `Region.ask` rule); the coach's after-blame line (audit §3A.2) |
| `repair` | +12 | +3 | only offered on a retry |

**Repetition.** The same move as the previous one: ×0.5. A third time in a row: −3, and the person says so ("Dat vroeg je net ook."). A conversation is not a slot machine.

**Ceiling: the concern must be earned.** Openness cannot rise above the next unrevealed layer's threshold + 9. Listening alone reaches the cue, but not "Denkt mee": to get there the person has to say what really worries them. This is what makes the hidden concern matter.

**Revealing a layer.** After a move's Δ is applied: if openness ≥ the layer's `at` and the move is in the layer's `via` list, the layer is revealed (its line is the person's reply). Each layer lists 2–4 `via` moves, so there is always more than one way in.

### 3.4 Layers

| Layer | Typical threshold (authored, validated range) | Typical `via` | What it is |
|---|---|---|---|
| `position` | shown in the opening | — | What they say: "Ik wil twee extra mensen." |
| `interest` | 50–60 (validator: 40–65) | `open_question`, `inquiry`, `paraphrase` | Why they say it: "Frank vraagt elke maandag naar dat getal." |
| `concern` | 65–75 (validator: 60–85) | `silence`, `reflect`, `empathy`, `inquiry` | What really worries them: fear of losing face, of being alone, of the craft being thrown away. It carries the cue and its `unlocks` (§4.3). |

An expert conversation (`kind: expert`, Femke, Thomas, Jeroen) uses the same engine with *topics* as layers: an open question at the threshold gives the open reply, a closed one the short reply (the catalogue's C5 design, unchanged in effect). Experts rarely resist, so their base openness is high and they have no proposals.

### 3.5 Patience and time

- **Patience:** 10 moves by default; the archetype and mood adjust it (`overloaded` −3, mood `moe` −2). Two moves before the end the person looks at the clock and says so. When patience runs out the talk ends as *gehoord* or *geen uitkomst* (§4.1), never as ruined.
- **Time:** each move is about 3 in-game minutes; the clock advances once, when the talk ends (a full talk ≈ 30 minutes, the same as today's conversation tool). The world does not tick mid-sentence.
- **Determinism:** no randomness. Line variants are picked by a stable hash (`Rng.fnv1a(dialog + turn + move)`), so a test can replay any path exactly.

### 3.6 The start of a talk, and memory

`start openness = base (archetype) + mood + 10 × team trust + (trust − 50) / 5 + (morale − 50) / 10 + memory`, clamped to 5–80.

| Term | Values (estimates) |
|---|---|
| base, by archetype (§6) | `defender` 40 · `cynic` 30 · `craftsman` 40 · `overloaded` 35 · `rule_bound` 35 · `quiet` 47 · `customer_upset` 25 · `expert` 60 |
| mood | `goed` +10 · `neutraal` 0 · `gespannen` −5 · `stil` −5 · `moe` −10 |
| team trust | today's `Region.trust` per pool, −2..1 |
| memory (of the last talk with this person) | the single most negative of: ruined −10 · pressured −10 · confronted −15; plus the single most positive of: heard +10 · committed +15. Revealed layers stay revealed. |

**Mood from signals** (computed each morning; first match wins): the person's team was blamed by the player in the last 7 days → `gespannen`; their pool ran ≥ 95 % utilisation for 14 days (the audit's R3 overload signal) → `moe`; an authored personal beat (Henk's farewell for Ahmed) → `stil`; a fix at their step resolved or held in the last 14 days → `goed`; otherwise `neutraal`. A dialog may also set a mood for its own scene (Joost the day before the MT).

**Archetype weights.** An archetype multiplies the *landing* values of some moves (estimates): `cynic` ×1.5 on `show_data`, ×0.5 on `experience`; `craftsman` ×1.5 on `inquiry` about the work; `overloaded` ×1.5 on `mood`; `rule_bound` ×1.5 on `show_data` and `propose_experiment`, ×0.5 on `reflect`; `quiet` ×1.5 on `silence`; `customer_upset` ×1.5 on `empathy` and `paraphrase`, and steering lands only after `heard` *and* the concern. People differ, so learning to read a person is part of the game; the archetype is never shown.

### 3.7 The meter

> **Superseded on screen (2026-10-21, phase 2 design §2.1–2.2, built in PLAN 2.14 S1-G):** the meter still exists in the rules (`Dialog.meter`), but a talk no longer shows it as instruments. Mid-talk only the five **trust pips** stay, small by the name (a ▲/▼ flashes beside them when trust moves), and the **▲/▼ arrow after your own line**. Openness and its band are the person's posture and gaze (`OfficePerson.pose_for_band`), the mood is their idle, and the cue is a visible hesitation (`OfficePerson.hesitate`) plus the line trailing off ("…"), never the words "Er zit meer achter…". The Openheid bar, the band name, Stemming and the Standpunt/Belang/Zorg tracker move to the **talk's note** (`People.talk_note`, drawn by `TalkSummary`): shown once as the talk's last screen and kept in the journal's notes. The list below is the original design, kept for the rules.

**What it displays** (originally the top of the speech panel, §11):

- **Openheid:** a horizontal bar with five labelled bands. After each move the marker slides to the new value; the change flashes as ▲ or ▲▲ (▼ or ▼▼) by its size for a second, **never a number** (Merijn, 2026-10-15). Nothing is shown before the move.
- **Vertrouwen:** five pips (one per 20 points of trust), next to the person's name; a pip fills or empties with a short animation.
- **Stemming:** a word (`goed`, `neutraal`, `gespannen`, `moe`, `stil`) and the portrait's face.
- **Verloop:** a small sparkline of openness over this talk's moves. It makes the summary card readable ("waar ging het mis?") and gives Ruud something to ask about.
- **The cue:** "*Er zit meer achter…*" in italics under the person's line, when openness ≥ 65, the concern is not yet revealed and the line is the concern's lead-in (tagged `hesitation` or, since 2026-10-16, `feeling`: the cue says there is more, never which move draws it out; a hesitation answers to silence, a feeling to reflecting). It says the person has more to say; it does not say which move will draw it out.

**Thresholds** (estimates; one table in `rules/dialog.gd`):

| Openness | Band (NL) | Colour (plus the label, never colour alone) | What the person does |
|---|---|---|---|
| 0–9 | — | — | Ends the talk: *mislukt* (§4.1). |
| 10–19 | **Dicht** | red | One-word answers; every steering move costs. |
| 20–39 | **Op z'n hoede** | orange | Short answers; repeats the position. |
| 40–59 | **Luistert** | yellow | Explains; the interest is reachable. |
| 60–79 | **Open** | light green | Tells stories; the cue can appear (≥ 65); partial agreement possible (≥ 55). |
| 80–100 | **Denkt mee** | green | Thinks along and may propose an idea of their own (an authored `co_proposal`). Accepting *their* idea is the strongest commitment (D32). |

**The second layer of cues** (never needed to play, always there to read):

| Band | Body language (3D, Phase C) | Tone and wording |
|---|---|---|
| Dicht | turns to the screen, arms crossed, stands while you sit | "Hm." · "Nee." · full stops |
| Op z'n hoede | half turned, short eye contact | repeats the position, "toch?" |
| Luistert | turns the chair toward you | longer sentences, explains |
| Open | leans back, offers coffee | stories, names people, "eerlijk gezegd" |
| Denkt mee | stands up to the whiteboard, picks up a pen | "Wat als we…", asks *you* questions |
| `heard` reached | shoulders drop, a nod | "Precies." |
| patience low | looks at the clock | "Ik heb nog vijf minuten." |

---

## 4. Outcomes

### 4.1 How a talk ends

| Outcome (NL label) | Id | When | Effects (estimates) |
|---|---|---|---|
| **Staat erachter** | `commitment` | `ask_commitment` at openness ≥ 70, the concern revealed, the proposal on the table addresses it, no pressure used, and no unmet condition | trust +10; team trust +1 (cap 1); reputation +1; morale +10; fact `committed:<dialog>`; buy-in `commitment` for the dialog's `owns` problem (§4.2) |
| **Afspraak onder voorwaarde** | `partial` | `ask_commitment` at openness ≥ 55 without commitment's conditions; or commitment's conditions with the dialog's `condition` unmet. The person names a condition: the concern turned into a demand (authored), or, when the concern is still hidden, the generic "Eerst zien, dan geloven": a passed Check of the mission's problem | trust +5; fact `partial:<dialog>`; buy-in `none` until the condition is met, then it upgrades to `commitment` by itself |
| **Gehoord** | `heard` | `close` (or patience out) with openness ≥ 60, or ≥ 15 above the start | trust +3; memory `heard` (+10 next time) |
| **Geen uitkomst** | `none` | `close` (or patience out) otherwise | nothing; the talk can be had again later the same day |
| **Geblokkeerd** | `blocked` | `ask_commitment` while the dialog's `block` applies: the concern is revealed and lies outside the person's power (§4.4) | no cost; fact `blocked:<dialog>`; the route hint goes into the Mensen journal |
| **Gaat akkoord onder druk** | `compliance` | `ask_commitment` with `pressured` set and openness ≥ 10, a proposal on the table | trust −5; morale −10; memory `pressured`; fact `complied:<dialog>`; buy-in `compliance` (§4.2); a `talk_to` goal completes at half its reward and no reputation (§5.1) |
| **Mislukt** | `ruined` | openness falls below 10 | reputation −1; trust −5; memory `ruined`; the person will talk again from the next working day at 08:30 (§14 Q5) |

`ask_commitment` below 55 without pressure is a refusal ("Nee. Nog niet."): −10, and the talk goes on (unless that drops it below 10).

### 4.2 Commitment versus compliance (approved, binding)

Compliance is a real option: under a deadline it gets the change in *now*. It is never hidden or forbidden. The game makes its price visible over time, through `sustain.gd`:

- **Buy-in per problem.** A dialog may name the problem whose fix its person will *own* (`owns: silo_kpis`). The buy-in recorded at the Act is the owner's best agreement so far:

  | Buy-in | Life factor on the fix (estimate) | Reasoning |
  |---|---|---|
  | `commitment` | ×1.25 | People who want the change keep it alive: they notice drift and correct it without being asked (affective commitment predicts discretionary support; Herscovitch & Meyer 2002, §12). |
  | `none` (no owner, or a partial still pending) | ×1.0 | Today's behaviour. |
  | `compliance` | ×0.6 | Compliance lasts while the pressure lasts; workarounds return once attention moves (Kotter & Schlesinger 1979; Senge 1990, §12). |

  `life = base / (1 − 0.9·S) × buy_in`. Example on the real content: the Obeya (`obeya_end_to_end`, `decay_days` 45), standardised (S = 0.6): 45 / 0.46 = **97.8 days**; with Joost's commitment **122 days**, with his compliance **59 days**.
- **Acting without asking** (§14 Q3, recommended): when a problem has an owner dialog and the Act happens with no agreement at all, the buy-in is `compliance`. The change was imposed on the person whose work it changes.
- **It can be repaired.** A later talk that reaches commitment upgrades the buy-in of the running fix (path dependence: you can pivot back). The fix's wear so far stays; only its life lengthens.
- **Tracked as facts** (`committed:`, `complied:`, `partial:`), so debriefs (`debrief_variants.complied`, after `blamed` in the audit's order of preference), discoveries and later options can read them.
- **The safety exception.** In a `safety: true` mission, `pressure` used to *contain* (stop unsafe digging today) carries no buy-in penalty for the containment, which is short by design (audit §2.4.1). The root-cause fix still needs its owner's commitment.

### 4.3 A learned concern unlocks something (path dependence)

A revealed `concern` (sometimes an `interest`) has `unlocks`, any of:
- **a clue** of the mission's problem (tool `conversation`, usually a key clue at depth 2): it goes into the journal and can be A3 evidence. A clue never activates a problem;
- **a fact** `heard:<dialog>`, read by the C19 `needs` evaluator: a countermeasure, a strategic option or a later mission can need it. Example: `twi_job_instruction` needs `heard:henk_teach` — you only see the option where Henk teaches the way he knows if you listened to him;
- **a dialog proposal** that only exists once the concern is known (Joost's "samen presenteren met Sanne").

Revealed layers are remembered per person, so a retry does not have to earn them again.

### 4.4 Hard blocks

Some resistance is not the person's to give up: a target the directie set, a contract, a rule. A dialog's `block` names this. Once its concern is revealed, `ask_commitment` ends in *geblokkeerd*, with no openness loss: the person is honest about it, and so is the game.

- A block lists **routes**, each a C19 `needs` expression plus a Dutch hint that points at a place, a person or a number, never at a mission or the answer ("Laat het me eerst zien op één stroom."). Typical routes: a passed Check (show it works), another person's commitment (Ruud at the table, Frank's okay), the KPI board's forecast.
- When a route is met, the next talk with that person can end in commitment.
- **Validator:** every block has at least one route no failure or skip can close ("setbacks, never game over").

### 4.5 Ruined, and the retry

- **Cost:** reputation −1, trust −5 (both "a few points"). No door closes.
- **Cooldown:** the person talks to you again from the next working day at 08:30. Before that, walking up gives one line ("Niet nu.") and no dialog.
- **Memory:** the next talk starts lower (−10, or −15 after blame), and the `repair` chip appears ("Terugkomen op vorige keer"). Layers already revealed stay revealed.
- **Deadlines:** a ruined talk costs a day; under Henk's clock that day matters. That is the real price, and it is fair.

---

## 5. Links to the rest of the game

### 5.1 `talk_to` goals and clues

The catalogue's C5 goal stays one goal type with two forms (validator: exactly one):
- `talk_to {person, topics: n}`: an expert conversation (unchanged in meaning; it runs on this engine).
- `talk_to {dialog, outcome: partial | commitment}`: a persuasion. Met when the dialog reaches at least that outcome *while the mission is active*. Compliance meets `partial` and `commitment` goals, but pays **half** the mission's XP and budget and no reputation (long term over short term: a quick win scores lower).

Inside a `solve` mission, dialogs are optional **clue sources**: the problem's key clues stay findable at the gemba, and a dialog's concern adds a deeper one. A player who skips the people can still solve the problem, but loses that clue and the commitment.

The existing quick question at a place (`Region.ask`, 30 minutes, one question to the *team*) stays: it is the gemba's quick word. A dialog is a conversation with a named *person*. Their vocabularies match (open, closed, blame, repair), so a player who learned one understands the other.

### 5.2 Trust per person and per team, and reputation

- **Person trust** (0–100, new, saved in `People`) is what the meter's pips show. It starts per person (authored, 40–60) and moves with outcomes (§4.1) and with the audit's R4 rule (blaming a person costs that person's trust).
- **Team trust** (`Region.trust`, −2..1, existing) stays the gemba's measure. A dialog touches it in two ways only: `confront` −1 (the same rule as a blaming question) and `commitment` +1. A team lead's start openness reads it (+10 per point).
- **Reputation** (catalogue §2.7, C9): +1 per commitment, −1 per ruined talk. Compliance: 0. No reputation for check-ins (respect is not a quest), except the discoveries' small amounts.

### 5.3 KPI choice

KPI dialogs make "use the right KPIs" a conversation, and the simulation judges the choice:

- A dialog with `kpi_team: work_prep` offers proposals that are KPI pairs from that team's menu in `content/kpis.yaml`. Which pair the person accepts depends on their concern, not on which pair is "right". Joost may commit to "ontwerpen per week + eerste keer goed": it addresses his fear of looking bad. The board's forecast and the Check will show what that choice does (the counterfactual board, PLAN.md decisions 2026-10-13).
- An agreed pair is recorded as `agreed_kpis[team]`.
- **At the quarterly review,** the `kpis` sustain mechanism for a team (`Sustain.WEIGHTS.kpis`, 0.2) counts in full only if the chosen KPIs include the lead's committed pair; otherwise at half (0.1). A team steers by a number it believes in.
- The coach's leading/lagging question now has a face: Joost's concern *is* the lagging-indicator problem (lead time dips before it improves). The proposals that address it pair a lagging KPI with a leading one he controls this week.

### 5.4 Sustain and morale

- **Buy-in** multiplies the fix's life (§4.2).
- **Morale** (0–100 per person, start 60): +10 commitment, +15 a lifted check-in, +5 when a fix they own holds 90 days; −10 compliance, −10 a blame of their team, −10 when a fix they own recurs, −5 per 14 days at ≥ 95 % utilisation (R3). It drifts 1 point a week toward 50.
- **Effects** (estimates): start openness ±(morale − 50)/10; below 30, fixes the person owns wear ×1/0.85 faster (disengaged owners stop noticing drift).
- **People can leave** (§14 Q7, recommended, rare): morale below 20 for 60 days *and* two check-in prompts ignored → a beat: the person moves to another grid operator (the audit's Anouk-to-Enexis beat). That closes a door (her owned fixes lose their owner, buy-in `none`; story options that need her), never the game.

### 5.5 Hidden rewards (discoveries)

New entries for `content/discoveries.yaml` (audit §4), with guards so they reward the skill, not a shortcut:

| # | Name (NL) | Trigger | Reward | Guard |
|---|---|---|---|---|
| D29 | **Twee oren, één mond** | Commitment reached with no steering move before the concern was revealed, three times | T "Luisteraar"; R from Ruud ("Wie eerst begrijpt, hoeft daarna minder te overtuigen.") | Needs commitment, not just listening. |
| D30 | **De stilte die sprak** | A concern revealed directly after `silence`, three different people | V: an empty coffee cup; S on silence in negotiation | Silence only lands after a hesitation, so it cannot be spammed. |
| D31 | **Tweede kans** | A ruined talk, then commitment with the same person on the retry | R ("Een gesprek dat misgaat, is het begin van het volgende.") | The ruin still cost its points. |
| D32 | **Haar eigen idee** | In "Denkt mee", the person's `co_proposal` accepted instead of your own proposal, and committed | V: the whiteboard marker; Tr +1 at that team | Needs openness ≥ 80 and commitment. |
| D33 | **Iemand die er is** | Five check-ins lifted with five different people whose morale was below 50 | T "Er zijn"; a beat where someone checks in on *you* | Needs low morale before, so it cannot be farmed on happy people. |
| D34 | **Geen druk nodig** | An act completed with no `pressure` or `confront` move and at least three commitments | Rep +2; R on Kotter & Schlesinger | Needs three commitments, so avoiding talks does not earn it. |

D2 *Veilige haven* (no blame in an act) now also counts `confront` in dialogs.

### 5.6 The coach after a hard conversation

Ruud only coaches the main quest (CLAUDE.md §2), so only dialogs of the main mission count:

- When a main-mission dialog ends in `ruined`, `blocked`, `compliance`, `partial` or `commitment`, the next `ask_coach` is about the talk: a `talk` stage for one ask, then back to the mission's stage.
- **The `talk` bank** (Kata; he never names the right move):
  - K1 "Wat wilde je dat {person} na het gesprek dacht of deed?"
  - K2 "Wat gebeurde er? Waar veranderde het gesprek?" (he can read the trace)
  - K3 "Wat houdt {person} tegen, denk je? Hoe weet je dat?"
  - K4 "Hoe begin je het volgende gesprek, en wat verwacht je dat er dan gebeurt?"
  - K5 "Wat heb je geleerd over luisteren?"
- **Conditional lines:** after `pressure`: "{person} zei ja. Wat zei zijn gezicht?" · after `ruined`: "Wie was er aan het woord in de eerste minuut?" · after `blocked`: "Is dit iets wat {person} kan beslissen? Wie wel?" · after `commitment`: "Wiens idee was het uiteindelijk?"
- A side-mission dialog or a check-in returns `not_main`, as today. People still talk in side missions; Ruud does not coach them.
- **Kata coaching goal (C7)** uses the same engine with a fixed move order (the five questions); out of order teaches but does not count (tier-2 draft §2.13). The move vocabulary is shared: Rother's five questions are `inquiry` and `open_question` moves with fixed lines.

### 5.7 Check-ins: lifting someone's spirit, with no mission

Respect for people means a lead talks with their people, sometimes only to see how they are. Check-ins (`kind: checkin`) are dialogs with no mission, no proposal and no XP.

- **Signal-driven, light cadence** (§14 Q8, recommended):
  - A prompt appears when a person's morale is below 50, or an authored life beat fires (Henk's farewell for Ahmed; Petra's sick week; Anouk's overtime).
  - At most **one** prompt visible at a time; at most **two** a week; a **14-day** cooldown per person; a prompt **expires** after 3 days with no cost.
  - The prompt is a small "…" bubble over the person's head and a line on the dagstart ("Ahmed is stil sinds Henk weg is.").
  - Check-ins take no main or side slot and never open a problem.
- **The skill is different:** a check-in has no proposal to win. Steering moves are *fixing mode*, the classic mistake (the "righting reflex" of motivational interviewing): every steering move before the concern is revealed costs −12. The talk ends at `close`:
  - **Opgebeurd** (`lifted`): concern revealed and openness ≥ 70 → morale +15, trust +5; sometimes the person volunteers an *observation* (never a key clue; a lead for a later mission).
  - **Gehoord**: as in §4.1.
  - **Niet het moment**: no cost but the time; the prompt stays until it expires.
  - Ruin is possible only through `confront` or repeated pushing, with the usual small cost.
- **No chore:** check-ins are never required, nothing fails when one is skipped, and a check-in with someone whose morale is already high is a short pleasant chat (trust +1 at most).
- **Content can vary by facts:** the same check-in can have layer variants keyed on facts (§8, path C).

---

## 6. The cast

Ten recurring people for dialogs, from the catalogue's §2.3 and the audit's §5.3 (new: Frank). Ruud is the coach, not a dialog target. Femke, Thomas and Jeroen stay *experts* (topic conversations). People are never the cause; a person may hold a wrong belief, never a vice (audit §5.3).

| id | Name | Role · place | Archetype | Typical resistance (their position) | Underlying concern (hidden) | Arc (dialog beats) |
|---|---|---|---|---|---|---|
| `joost` | Joost van Dijk | teamleider Werkvoorbereiding · connections.design | `defender` | "Ik heb twee mensen extra nodig." Later: "Mijn team haalt dertig ontwerpen per week." | One year in the job; his predecessor had one bad quarter and was moved to Inkoop. A KPI that dips first frightens him. | asks for people (Act I) → steers on lead time with Sanne (Act II, §7) → resists the WIP limit (Act IV) → coached |
| `sanne` | Sanne Bakker | teamleider Intake · connections.intake | `overloaded` | "Ik heb iemand extra nodig om alles na te lopen." | Her team takes the angry calls for errors made elsewhere; intake is seen as "het postkantoor". | wants a checker → owns the poka-yoke form → coached (Act III) → coaches others |
| `marco` | Marco Peters | teamleider Monteurs · connections.execution | `cynic` | "Weer een verbeterprogramma. En wie bouwt dat na?" | The 2012 programme took field hours and vanished when the consultants left; he promised his monteurs "never again". | cynic → ally after the van kanban → fights for his hours in the crew strategy |
| `henk` | Henk Verbeek | senior monteur · outages.locate | `craftsman` | "Ik laat me niet filmen." | That forty years of craft becomes a video nobody watches; that Ahmed is sent alone at night too soon. | refuses the camera → teaches by doing (TWI) → leaves with dignity → postcards |
| `ahmed` | Ahmed Bouzid | jonge monteur · outages.locate | `quiet` | "Gaat wel." | Afraid he is not good enough; ashamed he still calls a retiree at night. | lost → Henk's buddy → (check-in, §8) → trainer in Act IV |
| `anouk` | Anouk de Vries | werkvoorbereider · connections.design | `overloaded` | "Het is gewoon druk." | She thinks she is slow; she works until seven so nobody notices. | drowning (Act 0) → owns the standard designs → kata learner → team lead, or leaves if her fix fades and her morale stays low (§5.4) |
| `petra` | Petra Vos | Meetdata & registratie (one-person team) · connections.close_out | `defender` | "Eens per maand registreren is efficiënter. Dan doe ik de hele stapel in één keer." | Each session in the EAN register has a real set-up; and she is alone: if she works daily, a sick day leaves a gap nobody covers. | gives up the batch *if* she gets a backup (unlocks the skills-matrix option) → Act III: her sick week tests it |
| `esra` | Esra Yilmaz | teamleider Klantcontactcentrum · customer_contact.answer | `defender` | "Ik heb vier agents extra nodig." | Two of her agents are home with stress from angry callers; she protects her people. | asks for agents → failure-demand champion → runs a board (Act III) |
| `frank`† | Frank Hulshof | manager Aansluitingen & Netverzwaring (Joost's and Sanne's manager) · Directie & Obeya | `rule_bound` | "Ontwerpen en aanvragen per week staan in het jaarplan. Daar stuur ik op." | The directie judges him on connections per year, a number that goes to the ACM; a lagging KPI that dips first could cost him the region's reinforcement budget. **The blocking manager:** his block has routes (§7.4). | blocks (Act II) → allows an experiment on one stream → champions the Obeya → hoshin partner (Act V) |
| `el_amrani` | mevrouw Fatima El Amrani | customer, Nova-Oost (by phone or at the counter) · customer_contact.answer | `customer_upset` | "Ik bel nu voor de vierde keer. Ik wil een datum, anders ga ik naar de geschillencommissie." | The installer advised them to remove the gas boiler; the heat pump is in, but needs the heavier connection. Her mother lives with them, and winter is coming. | the letter → the fourth call (`fix_status_callers`) → a realistic date, or a promise that breaks (temptation) → the heat pump runs (D14) |

**The El Amrani dialog** carries the customer-side temptation: `propose` offers "een datum noemen" (a date you cannot guarantee). It calms her now (+8, a partial), and if the followed order (audit §3.0) misses that date, the next call starts at memory −15 and a reputation −1. "Een eerlijke datum en één vast aanspreekpunt" addresses her concern and holds. This is `realistic_promise` versus a lie, felt from the customer's side, and it gives `fix_status_callers` a key clue: "Niemand belt me terug, dus bel ik zelf."

---

## 7. Sample dialog 1: Joost and the output KPI (tier 1, `fix_silo_kpis`)

**Context.** Act II main mission `fix_silo_kpis` (KPI's die elkaar bevechten). The player has found the data clue (records everywhere, nothing more delivered) and Joost's conversation clue ("Mijn doel is dertig ontwerpen per week."). The dialog `joost_output_kpi` is available at Werkvoorbereiding. It `owns: silo_kpis`, `kpi_team: work_prep`, and its condition is Frank's okay.

**Start state.** Archetype `defender` 40; mood `gespannen` (the MT is tomorrow) −5; team trust 0; trust 50 (0); morale 50, worn down by the conflict (0). **Openness 35, Op z'n hoede.** Patience 10.

**Opening.** Joost (looks at his screen): "Ik heb tien minuten. Morgen is het MT."
**Position** (`claim`): "Mijn team haalt dertig ontwerpen per week. Een record. Als de aansluitingen niet sneller gaan, ligt dat niet aan ons."

### 7.1 Path A, first try: pushing early (ruined)

| # | Chip | Speler (NL) | Joost (NL) | Openness | Trust | Cue / body |
|---|---|---|---|---|---|---|
| A1 | Data laten zien ▸ *(clue: eerste keer goed 85 → 80 %)* | "Kijk: het aandeel ontwerpen dat de monteur zonder aanpassing kan bouwen, zakte van 85 naar 80 procent." | "Dus mijn mensen werken slordig? Ze halen elke week hun doel. Elke week." | 35 → **23** (−12, too early) | 50 | arms crossed |
| A2 | Voorstel doen ▸ *(doorlooptijd + oudste dossier)* | "Stuur voortaan op de doorlooptijd en het oudste dossier." | "Doorlooptijd? Daar gaat de vergunning over, en de monteur, en de klant. Niet ik." | 23 → **11** (−12) | 50 | turns half away |
| A3 | Druk zetten | "Ruud wil dat dit verandert. Het MT ook." | "Dan moet Ruud dat maar tegen mij zeggen. Ik heb een MT voor te bereiden." | 11 → **0** (−15) | 42 | turns to the screen |

**Mislukt.** Reputation −1; trust 42 − 5 = **37**; memory `ruined` (and `pressured`, but only the most negative counts: −10). Summary card: "*Mislukt — Joost praat morgen weer met je.*" The trace shows three red steps from the first move. In this main mission Ruud's next ask: "Wie was er aan het woord in de eerste minuut?"

### 7.2 Path B, the retry the next day: listening first

**Start.** 40 base; mood `neutraal` 0 (the MT is over); team trust 0; trust 37 → −3 (rounded); morale 50 → 0; memory −10. **Openness 27, Op z'n hoede.** The `repair` chip is offered.

**Opening.** Joost: "Jij weer."

| # | Chip | Speler (NL) | Joost (NL) | Openness | Trust | Cue / body |
|---|---|---|---|---|---|---|
| B1 | Terugkomen op vorige keer | "Gisteren begon ik met mijn verhaal in plaats van met het jouwe. Dat was niet handig." | "Nee. Dat was het niet." *(stilte)* "Koffie?" | 27 → **39** (+12) | 40 | turns the chair toward you |
| B2 | Stemming peilen | "Hoe ging het MT?" | "Zoals altijd. Dertig ontwerpen, record, applaus. En dan vraagt Marco wie onze fouten nabouwt." *(`claim`, `feeling`)* | 39 → **47** (+8) | 40 | Luistert |
| B3 | Samenvatten | "Je haalt je doel, je krijgt applaus, en toch hoor je dat er werk terugkomt." | "Precies. Ik doe wat er gevraagd wordt. En het is nooit goed." | 47 → **54** (+7, `heard`) | 40 | shoulders drop, a nod |
| B4 | Doorvragen | "Wie vraagt er eigenlijk om die dertig?" | "Frank. Elke maandag om negen uur. Ontwerpen per week staat bovenaan zijn lijst, dus bovenaan de mijne." *(interest revealed; `feeling`)* | 54 → **62** (+8) | 40 | Open |
| B5 | Gevoel benoemen | "Je zit klem tussen wat Frank vraagt en wat de monteurs nodig hebben." | "Ja. En…" *(`hesitation`)* | 62 → **72** (+10) | 40 | ***Er zit meer achter…*** |
| B6 | Stilte laten | *(je zegt niets en wacht)* | "Mijn voorganger had één slecht kwartaal. Hij werkt nu bij Inkoop. Als ik op doorlooptijd ga sturen en dat getal wordt eerst slechter, en dat wordt het, dan sta ik in het MT met lege handen." *(concern revealed; `admission`)* | 72 → **84** (+12) | 40 | Denkt mee |
| B7 | Voorstel doen ▸ *(doorlooptijd + oudste dossier)* | "Wat als je naast de doorlooptijd het oudste dossier meet? Dat beweegt binnen een paar weken, en dat heb jij in de hand." | "Het oudste dossier… dat zie ik volgende week al zakken." *(co-proposal:)* "En als Sanne hetzelfde doet, presenteren we het samen. Dan sta ik er niet alleen." | 84 → **92** (+8, addresses the concern) | 40 | stands up to the whiteboard |
| B8 | Afspraak maken | "Spreken we af: een kwartaal sturen op doorlooptijd en het oudste dossier, en je presenteert het samen met Sanne?" | "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst." | 92 | 45 | — |

**Afspraak onder voorwaarde** (`partial`): trust +5 → 45; fact `partial:joost_output_kpi`; agreed KPIs pending; buy-in `none` until the condition is met. The concern unlocked a key clue for the A3: "*Werkvoorbereiding stuurt op ontwerpen per week omdat de manager er elke maandag naar vraagt. Een doorlooptijd die pas na maanden beter wordt, voelt als een risico.*" (`conversation`, depth 2; the problem's root cause in Joost's words), and the fact `heard:joost_kpi`. Eight moves, 24 minutes. The Mensen journal: "Frank Hulshof: het jaarplan." Ruud: "Wiens idee was het samen presenteren?"

**Other paths through the same talk** (no golden path):
- **B5′** *Ervaring delen* at 62: "Bij mijn vorige werkgever…" — trust is 40 (< 50), so −5 → 57: "Hm. Ander bedrijf." Not fatal. Then *Doorvragen*: "Wat gebeurt er als dat getal een maand zakt?" (+8 → 65, `hesitation`: the cue), then *Begrip tonen* (+6 → 71; `empathy` is in the concern's `via`) → the concern. Same destination, other route.
- **B7′** *Voorstel doen ▸ doorlooptijd + eerste keer goed*: "Twee getallen die pas na maanden bewegen? Dat is precies wat ik bedoel." (0). The player can try *Experiment voorstellen ▸ een kwartaal proberen, met de oude cijfers ernaast zichtbaar* (+6; it addresses the concern too).
- **B7″** *Voorstel doen ▸ ontwerpen per week + eerste keer goed*: "Dat kan ik wel aan Frank verkopen." It addresses his fear, so he can commit. The dialog does not judge the pair; the board's forecast and the Check will (output still makes his team hurry: `care: hasty` against `careful`, mixed signals, the habit).

### 7.3 Path C, another game: pressure (compliance)

| # | Chip | Speler (NL) | Joost (NL) | Openness | Trust |
|---|---|---|---|---|---|
| C1 | Open vraag | "Hoe loopt het bij jullie?" | "Prima. We halen ons doel." | 35 → 41 | 50 |
| C2 | Druk zetten | "Het MT gaat de KPI's toch omgooien. Beter dat je meedoet." | "Aha." | 41 → 26 | 42 |
| C3 | Voorstel doen ▸ *(doorlooptijd + oudste dossier)* | "Dan stuur je voortaan op doorlooptijd en het oudste dossier." | "Als dat moet." | 26 → 14 | 42 |
| C4 | Afspraak maken | "Afgesproken?" | "Prima. Dan meet ik wat jullie willen." | 14 | 37 |

**Gaat akkoord onder druk** (`compliance`): trust 37; morale −10; fact `complied:joost_output_kpi`; the `talk_to` goal (if any) pays half. At the Act, the Obeya fix's life is ×0.6: **59 days** of neglect instead of 98 (or 122 with commitment). At the quarterly review, `work_prep`'s KPIs count as a sustaining habit at half weight. The debrief variant `complied`: "De KPI's zijn om. Joost presenteert ze, maar het zijn de jouwe." Ruud: "Joost zei ja. Wat zei zijn gezicht?" A later talk that reaches commitment repairs the buy-in.

### 7.4 The block behind the condition: Frank (sketch)

`frank_kpi_targets` (archetype `rule_bound`, base 35). Position: "Ontwerpen en aanvragen per week staan in het jaarplan." Interest (`show_data` lands ×1.5 for him): "Het jaarplan gaat naar de directie, en het aantal aansluitingen per jaar naar de ACM." Concern: "Als de doorlooptijd eerst slechter wordt, verlies ik in het najaar het budget voor netverzwaring. Ik ga niet op gevoel een kwartaal gokken."

**Block** (`geblokkeerd`): "Ik kan dit niet toezeggen. Laat het me eerst zien." Routes (any one; the hint goes into the journal):
1. `checked:silo_kpis` passed: an Obeya experiment on the connections stream whose Check shows throughput not lower ("Laat het me zien op één stroom.");
2. `partial:joost_output_kpi`, `partial:sanne_kpi` and reputation ≥ 40: the two team leads explain it themselves ("Als Sanne en Joost het zelf komen uitleggen, sta ik er niet alleen voor."). *(Audit change, applied 2026-10-16: the earlier `committed:ruud_backs_obeya` could never be set, because Ruud is the coach and not a persuasion target. The people bring their boss along.)*
3. the KPI board's forecast for the quarter is positive (once the board exists).

When a route is met, Frank can commit. His commitment meets Joost's condition, so Joost's partial becomes **commitment** by itself, and the buy-in for `silo_kpis` becomes ×1.25. Joost's B8 condition was the dialog's way of saying: *this is not his decision.* The player learns to look one level up, as Ruud's after-block question asks.

---

## 8. Sample dialog 2: a check-in with Ahmed (no mission)

**Trigger.** 16 days after Henk's farewell (an authored life beat) and Ahmed's morale is 42. The dagstart line: "*Ahmed is stil sinds Henk weg is.*" A "…" bubble over Ahmed in the depot yard (outages.locate), where he sits in his van.

**Start.** Archetype `quiet` 47; mood `stil` −5; team trust 0; trust 60 (he met you in Henk's mission) +2; morale 42 → −1 (rounded). **Openness 43, Luistert.** Patience 8. No proposals: the steering chips are there, as always.

**Opening.** Ahmed (rolls down the window): "Hé."
**Position** (`claim`): "Gaat wel."

**Layers** (path-dependent; the default, when Henk's knowledge was saved with videos only, or not at all):
- interest (50; via `open_question`, `inquiry`): "Nachtdienst in Nova-Oud is anders zonder Henk. Die kabels zijn ouder dan ik." (`feeling`)
- concern (65; via `silence`, `empathy`, `reflect`): "Vorige week stond ik om twee uur 's nachts bij een papierloodkabel en ik wist het niet. Ik heb Henk gebeld. Hij is met pensioen, en ik bel hem uit zijn bed. Wat voor monteur ben ik dan?" (`admission`, `doubt`)

### 8.1 Path A: fixing mode

| # | Chip | Speler (NL) | Ahmed (NL) | Openness |
|---|---|---|---|---|
| A1 | Stemming peilen | "Hoe gaat het nu echt, sinds Henk weg is?" | "Gaat wel." | 43 → 51 |
| A2 | Voorstel doen ▸ *een cursus* | "Zal ik een extra cursus voor je regelen?" | "Een cursus. Ja. Misschien." | 51 → 39 (−12: fixing before listening) |
| A3 | Experiment voorstellen ▸ *een maand meelopen* | "Je kunt de eerste maand met een collega mee op nachtdienst." | "Ik red me wel." *(rolls the window up halfway)* | 39 → 27 |
| A4 | Afronden | "Goed. Je weet me te vinden." | "Ja. Doei." | 27 |

**Niet het moment.** No cost but 12 minutes; the prompt stays for two more days. Nothing in the meter said "wrong": it showed Ahmed closing, and the window going up said the rest. (A misread is also possible: *Gevoel benoemen* at A2 on "Gaat wel." gives −3 and "Ik ben niet ziek, hoor.")

### 8.2 Path B: listening

| # | Chip | Speler (NL) | Ahmed (NL) | Openness | Cue / body |
|---|---|---|---|---|---|
| B1 | Stemming peilen | "Hoe gaat het nu echt, sinds Henk weg is?" | "Gaat wel." | 43 → **51** | — |
| B2 | Open vraag | "Hoe waren de nachtdiensten deze week?" | "Anders. Nachtdienst in Nova-Oud is anders zonder Henk. Die kabels zijn ouder dan ik." *(interest)* | 51 → **57** | gets out of the van |
| B3 | Gevoel benoemen | "Het klinkt alsof je er 's nachts alleen voor staat." | "Ja. Nou…" *(`hesitation`)* | 57 → **67** | ***Er zit meer achter…*** |
| B4 | Stilte laten | *(je leunt tegen de bus en wacht)* | "Vorige week stond ik om twee uur 's nachts bij een papierloodkabel en ik wist het niet. Ik heb Henk gebeld. Hij is met pensioen, en ik bel hem uit zijn bed. Wat voor monteur ben ik dan?" *(concern)* | 67 → **79** | looks at you |
| B5 | Begrip tonen | "Dat je belt als je het niet weet, is precies wat een goede monteur doet. Om twee uur 's nachts al helemaal." | "Denk je? Ik weet het niet, hoor." *(`doubt`)* | 79 → **89** (+10 after an admission) | — |
| B6 | Ervaring delen | "Mijn eerste jaar belde ik ook steeds iemand. Zo leer je het." | "Henk zei: bel me maar, jongen. Ik denk dat hij het eigenlijk fijn vond." *(laughs)* | 89 → **97** | — |
| B7 | Afronden | "Fijn dat je het vertelde. Ik loop vaker even langs." | "Doe dat. En… in Nova-Oud weet niemand van de nachtdienst welke kabel waar ligt. Dat zat in Henks hoofd." | 97 | — |

**Opgebeurd** (`lifted`): morale 42 → 57; trust +5 → 65. The last line is an *observation* (not a key clue): it plants Act III's `fix_cause_unknown` and the on-call questions, and sets `heard:ahmed_night`, which `needs` can read (e.g. *Henks storingsboekje*, D13). 21 minutes.

### 8.3 Path C: the same check-in when Henk taught Ahmed (path dependence)

When the fact `chose:knowledge_drain:skills_matrix_buddy` or `chose:knowledge_drain:twi_job_instruction` is set, Ahmed's layers differ (`variants` keyed on facts), his mood is `goed` and his morale higher, so the check-in only fires through its life beat:
- position: "Goed, eigenlijk."
- interest: "Gisteren vond ik zelf een fout in een papierloodkabel in Nova-Oud. Henk stuurde een kaartje."
- concern (the hidden thing is pride, and a doubt): "Ruud vroeg of ik straks de nieuwe jongens wil opleiden. Ik weet niet of ik dat kan. Henk kon het."

*Gevoel benoemen* ("Je bent er trots op, hè?") and *Ervaring delen* land; *Voorstel doen* (a train-the-trainer course) before the concern is again fixing mode. Lifted, it sets `heard:ahmed_trainer`, which the audit's Act IV payoff can read (Ahmed as trainer in `fix_training_capacity`, audit §8 Q5).

---

## 9. Content schema and validator

### 9.1 Files

**`content/people.yaml`** (the catalogue's K3 file, extended):

```yaml
people:
  - id: joost
    name: Joost van Dijk
    role: teamleider Werkvoorbereiding
    place: connections.design          # where the player finds them
    team: work_prep                    # a pool id: team trust, load, mood signals
    archetype: defender                # vocabulary: dialog_archetypes
    trust: 50                          # start trust in the player (0–100)
    voice: "Mijn team haalt het doel."  # the recurring voice line (audit §5.3)
    topics: []                         # expert topics (catalogue C5); empty for non-experts
```

**`content/dialogs.yaml`:**

```yaml
dialogs:
  - id: joost_output_kpi
    person: joost
    kind: persuade                     # persuade | checkin | expert
    mission: fix_silo_kpis             # available while this mission is active (persuade); absent for checkin
    requires_clue: "silo_kpis:4"       # optional: the talk opens once this clue is found (Joost's "dertig ontwerpen")
    needs: null                        # optional, the C19 evaluator: further conditions
    owns: silo_kpis                    # optional: the problem whose fix this person owns (buy-in)
    kpi_team: work_prep                # optional: proposals are KPI pairs from this team's menu
    mood: gespannen                    # optional scene mood, first talk only
    patience: 10                       # optional; default from the archetype
    opening: "Ik heb tien minuten. Morgen is het MT."
    position: {text: "Mijn team haalt dertig ontwerpen per week. ...", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [inquiry, open_question, paraphrase]
        text: "Frank. Elke maandag om negen uur. ..."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [silence, reflect, empathy, inquiry]
        lead_in: {text: "Ja. En…", tags: [hesitation]}   # the line that carries the cue
        text: "Mijn voorganger had één slecht kwartaal. ..."
        tags: [admission]
        condition: "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst."
        unlocks:
          clue: {key: true, depth: 2, text: "Werkvoorbereiding stuurt op ontwerpen per week omdat de manager er elke maandag naar vraagt. ..."}
          facts: [heard:joost_kpi]
          proposals: [present_with_sanne]
    data: ["silo_kpis:0", "silo_kpis:2"]   # clue ids (problem:index) that land when shown at the right moment
    proposals:
      - id: lead_and_oldest
        kpis: [work_prep_lead_time, work_prep_oldest]
        addresses: [concern]
        reply: "Het oudste dossier… dat zie ik volgende week al zakken."
      - id: ftr_and_oldest
        kpis: [work_prep_ftr, work_prep_oldest]
        addresses: [concern]
        reply: "Eerste keer goed, en iets wat ik deze week kan laten zien. Dat is eerlijk."
      - id: output_and_ftr
        kpis: [work_prep_output, work_prep_ftr]
        addresses: [concern]
        reply: "Dat kan ik wel aan Frank verkopen."
      - id: lead_and_ftr
        kpis: [work_prep_lead_time, work_prep_ftr]
        addresses: []
        reply: "Twee getallen die pas na maanden bewegen? Dat is precies wat ik bedoel."
      - id: present_with_sanne         # exists only once the concern unlocked it
        hidden: true
        addresses: [concern]
        reply: "Samen. Dan sta ik er niet alleen."
    experiments:
      - id: one_quarter_trial
        text: "Een kwartaal proberen, met de oude cijfers ernaast zichtbaar."
        addresses: [concern]
    co_proposal: {id: present_with_sanne, text: "En als Sanne hetzelfde doet, presenteren we het samen."}
    condition_needs: {all: [committed:frank_kpi_targets]}   # the condition that upgrades a partial
    block: null                        # or {text, routes: [{needs, hint}]} (Frank's dialog)
    lines:                             # optional overrides per move and band; else dialog_lines.yaml
      mood: {early: "Hoe ging het MT?"}
      confront: {any: "Jouw team zet toch gewoon te snel door?"}
    outcomes:                          # override texts; defaults in dialog_lines.yaml
      ruined: "Dan moet Ruud dat maar tegen mij zeggen. Ik heb een MT voor te bereiden."
      compliance: "Prima. Dan meet ik wat jullie willen."
    variants: []                       # [{needs, position?, layers?}]: fact-keyed versions (§8.3)
```

**`content/dialog_lines.yaml`:** the shared bank. Player lines per move (with `{position}`, `{person}`, `{feeling}` placeholders), the person's fallback reply per move × band × archetype, the outcome defaults, the cue text, the band labels and the chip labels. Dutch only in content and `UiText`, never in the rules.

**`content/concepts.yaml`** (K0 additions): `more_pies`, `commitment_vs_compliance`, `humble_inquiry`, `active_listening`, `resistance_to_change` (Kotter & Schlesinger, ADKAR), each with a source (§12).

### 9.2 Validator rules (`tools/build_content.py`)

Schema and references:
1. Unknown keys refused (the existing `_StrictLoader` rule); duplicate ids refused.
2. `person` exists; the person's `place` is a real step and `team` a real pool.
3. `kind` ∈ vocabulary (`persuade`, `checkin`, `expert`); `archetype` ∈ `dialog_archetypes`; every move in `via` and `lines` ∈ `dialog_moves`; every tag ∈ `dialog_tags` (all mirrored in `vocabulary.json`, guarded by the existing two-language test).
4. `mission` exists; a mission with `talk_to {dialog}` names a dialog whose `mission` is that mission.
5. `owns` is a problem of that mission; `kpi_team` is a pool with a KPI menu; every `kpis` entry is on that team's menu, 1–2 per proposal.
6. `unlocks.clue`: a new clue for the `owns` (or mission's) problem; the build appends it to that problem's clues with tool `conversation` at the person's place, so it gets an ordinary id (`silo_kpis:7`) and the existing clue-depth chain check covers it. `requires_clue` and `data` are existing clue ids (`problem:index`). `facts` well-formed (`heard:<dialog>`); every `proposals` id exists and is `hidden: true`.
7. `data` entries are clue ids of the mission's problem.
8. `needs`, `condition_needs` and `block.routes[].needs` use the C19 grammar.

Rules of the design:
9. **Layers:** `interest.at` 40–65, `concern.at` 65–85 (R-D1), strictly ascending; each layer has ≥ 2 `via` moves; the concern has a `lead_in` tagged `hesitation` **or** `feeling` (four-tier audit §4, 2026-10-16: at least a third of a tier's concerns are cued by a feeling, whose `via` holds `reflect` and not `silence`).
10. **No single right answer:** a `persuade` dialog has ≥ 2 proposals or experiments that address the concern, and no field marks a proposal correct (there is no such key).
11. **Never game over:** every `block` has ≥ 1 route that no failure or skip can close (the C19 obtainability check).
12. **Check-ins:** no `mission`, no `owns`, no `kpi_team`, no proposals with KPIs; a trigger from the vocabulary (`morale_below`, `beat`).
13. **Completeness:** for every move, a line exists for this dialog or in the bank for its archetype and every band (so no chip is ever empty).
14. **Text:** every Dutch field is non-empty; outcome overrides are only for known outcomes.

### 9.3 Content tests (Godot, on the real content)

- **Reachable:** a scripted listening-first player reaches the dialog's best outcome within patience, from the default start state.
- **No golden path:** a breadth-first search over move sequences (pruned: moves with a known negative Δ in that state only once) finds ≥ 3 successful sequences that differ in at least two positions, and no move is required at a fixed turn in all of them.
- **Pushing costs:** steering first at the default start ends in `ruined` or `none` for every `persuade` dialog with a base ≤ 40.
- **Pressure works short term:** a pressure path reaches `compliance` in ≤ 5 moves.

---

## 10. Rules API sketch

Pure logic in `game/src/rules/`, no nodes, tested headless like the rest.

```gdscript
class_name DialogDef      # content: one dialog (people.yaml + dialogs.yaml), loaded by Catalog
class_name PersonDef      # content: one person

class_name Dialog         # one conversation in progress; deterministic; numbers as consts
extends RefCounted
const BANDS := [10, 20, 40, 60, 80]           # band floors; < 10 ends the talk
const CUE_AT := 65
const LANDS := {"mood": 8, "open_question": 6, "paraphrase": 7, "reflect": 10, "empathy": 6,
	"inquiry": 8, "experience": 8, "silence": 12}            # ESTIMATES, see the spec §3.3
const TOO_EARLY := -12
const PRESSURE := {"openness": -15, "trust": -8}
const CONFRONT := {"openness": -20, "trust": -10}
const MINUTES_PER_MOVE := 3

func _init(def: DialogDef, start: Dictionary) -> void      # start: openness, trust, mood, memory, revealed, facts, found clues
func moves() -> Array[Dictionary]                           # [{id, row, line, picks?}]: the fixed palette, lines filled
func say(move: String, pick: String = "") -> Dictionary
	# {line, reply, tags, openness, delta, trust, band, cue, revealed?, unlocked?, ended, outcome?}
func meter() -> Dictionary                                  # {openness, band, trust_pips, mood, trace}
func outcome() -> String                                    # "" while running

class_name People         # persistent state of every person; saved
extends RefCounted
var trust: Dictionary[String, int]
var morale: Dictionary[String, int]
var memory: Dictionary[String, Dictionary]    # {last_outcome, flags, revealed: {layer: true}, cooldown_until}
var outcomes: Dictionary[String, String]      # dialog id -> best outcome so far
var agreed_kpis: Dictionary[String, Array]    # team -> [kpi ids], with commitment
func _init(region: Region, persons: Array[PersonDef], dialogs: Array[DialogDef]) -> void
func dialog_for(person_id: String, active_missions: Array[MissionDef]) -> DialogDef  # main > side > check-in > none
func start(person_id: String, dialog: DialogDef) -> Dialog  # builds the start state (§3.6)
func finish(d: Dialog) -> Array[Dictionary]                 # applies outcomes: trust, morale, facts, team trust, reputation; events
func buy_in(problem_id: String) -> String                   # commitment | none | compliance
func checkins_due(day: int) -> Array[String]                # the cadence rules of §5.7
func daily(day: int) -> void                                # mood signals, morale drift, prompt expiry
func to_dict() -> Dictionary
func load_dict(d: Dictionary) -> void                       # unknown ids dropped; old saves load with defaults
```

**Changes elsewhere (small):**
- `ProblemState.buy_in` (saved; default `none`), set by `GameSession.act` from `People.buy_in`. `Sustain.BUY_IN := {"commitment": 1.25, "none": 1.0, "compliance": 0.6}` (estimates) and a `buy_in` factor in `Region.life_days`; the morale factor likewise.
- `Region.sustain`: the `kpis` mechanism at half weight for a team without a committed pair (§5.3).
- `Missions._goal_met`: `talk_to` reads `People.outcomes`; `Missions.ask_coach`: the `talk` stage for one ask after a main-mission dialog (§5.6).
- Facts (`heard:`, `committed:`, `complied:`, `partial:`, `blocked:`) go into the C19 fact set.
- `rules/discoveries.gd` consumes the dialog events for D29–D34.

**Dependencies:** People reads Region (team trust, pool load, facts) and Missions reads People. Region knows neither (as today with Missions). Only GameSession depends on all three, so no new module becomes a dependency of three others (the architecture trigger).

**GameSession facade:**

```gdscript
func people_at(place: String) -> Array[Dictionary]   # [{id, name, role, mood, has_dialog, checkin}]
func talk(person_id: String) -> Dictionary           # opens the person's dialog: {dialog, opening, meter, moves}
	# errors: unknown_person | not_here | cooling_down | nothing_to_say | in_dialog
func say(move: String, pick: String = "") -> Dictionary   # Dialog.say; errors: no_dialog | unknown_move | bad_pick
func end_talk() -> Dictionary                         # = say("close"); advances the clock once; returns the summary
func person(person_id: String) -> Dictionary          # {trust_pips, morale_band, known_layers, last_outcome, cooldown}
```

`pick` is player input: it must be one of the picks `moves()` offered this turn (found clues, the dialog's proposals and experiments); anything else is `bad_pick` and changes nothing (the data-validation rule).

**Save:** `People.to_dict` under `people` in the save, with `buy_in` per problem in `ProblemState`; a conversation in progress is not saved (saving ends it as `none`).

**Tests first (TDD), `test_dialog.gd`, `test_people.gd`, `test_session.gd`:** each Δ rule; repetition; the ceiling; layer reveal by each `via`; the cue at 65 with `hesitation`; pushing early; every outcome from §4.1; ruined → cooldown → retry with memory and `repair`; a learned concern reveals its clue and fact; a block and its route; compliance ×0.6 and commitment ×1.25 on `life_days`; acting without asking; KPI weight halving; check-in cadence, expiry and slot-free; the coach's `talk` stage only for main; morale effects; save/load round trip and an old save.

---

## 11. UI sketch

**Walking up.** In the Sims-like office, people stand or sit at their workstations. A person with something to say has a small speech bubble; a check-in prompt is a quiet "…". Hovering shows the name, role and mood word. Click or E: the player walks over (as with place rings) and the camera frames the two of them over the player's shoulder, close, as it frames a workstation today.

**The talk view** (since 2026-10-21: phase 2 design §2, built in PLAN 2.14 S1-G as `game/src/ui/talk_view.gd`, replacing the speech panel below). A talk looks like two people talking, not a panel. There is no panel behind it; the world is the background. Two modes, watch then choose:

- **They speak.** The camera frames their face and shoulders (`CameraRig.face_shot`, from the side that sees the face; over the player's shoulder, `converse`, where the floor is too tight). The line types out as a film's subtitle and waits for the key (`SceneLines`: the first press shows it whole, the next goes on, ← re-reads). Your own line sits small over their answer, with ▲/▲▲ or ▼/▼▼ after it (never a number). On the cue they hesitate (`OfficePerson.hesitate`) and the line trails off "…".
- **You choose.** The camera returns to the two-shot; their last line stays as the subtitle and the four sentences sit above it, one under the other, each with its key (1–4), none named by its move, none styled by fit. "Afronden" sits small under them. Esc pauses (the pause menu of 2.13), mid-talk as everywhere.
- **On screen through the talk:** the name and role with the five trust pips beside them (a ▲/▼ flashes there when trust moves), the ▲/▼ after your line, the subtitle and the sentences. Nothing else: openness is the person's posture and gaze (`OfficePerson.pose_for_band`, five band poses), mood their idle.
- **Settings:** *standing* (at their desk), *walking* (Ruud's walk, a shadow day: `GameUI.open_talk(id, TalkView.WALKING)`; the player walks between lines, the person keeps beside them, the camera a following two-shot) and the *phone call* (someone not in the office, El Amrani and Ilse from the KCC's place menu: no face shot, the phone raised on screen, the subtitles carry it).
- **The talk's note** after their last words, shown once as the last screen and kept in the journal's notes (`People.talk_note` with the talk log, drawn by `TalkSummary`): the outcome and what comes next, the curve with the move names under it (named afterwards, never during), the band it ended in and the mood, what was heard per layer (Standpunt, Belang, Zorg), a new clue, a block's route hints ("Wat zou helpen"), Ruud's word after an Act 0 talk, and for a main-mission talk "Bespreek met Ruud".

**The speech panel** (the original design, superseded by the talk view above; bottom third of the screen):

```
┌─ Joost van Dijk · teamleider Werkvoorbereiding ─────────── ●●○○○ · neutraal ─┐
│ Openheid  ▕██████████████░░░░░░░▏ Open          ▲ +10                          │
│           Dicht · Op z'n hoede · Luistert · Open · Denkt mee     verloop ▁▃▄▅▆▇ │
│                                                                                │
│ [portret]  "Ja. En…"                                                           │
│            Er zit meer achter…                                                 │
│                                                                                │
│ Luisteren  [Stemming peilen] [Open vraag] [Gevoel benoemen] [Begrip tonen]     │
│            [Samenvatten] [Doorvragen] [Ervaring delen] [Stilte laten]          │
│ Sturen     [Ander perspectief] [Data laten zien ▸] [Experiment voorstellen ▸]  │
│            [Voorstel doen ▸] [Afspraak maken]      [Druk zetten] [Aanspreken]  │
│                                                                   [Afronden]   │
└────────────────────────────────────────────────────────────────────────────────┘
```

- **Chips** (superseded: four sentences, see the talk view): the move type as the label; hover or focus shows the line you will say. Never an effect, a colour or a hint about fit. "▸" chips open a small picker (your found clues, the dialog's proposals, your A3's countermeasures). Keys 1–8 for listening, Q–T for steering.
- **The meter** animates *after* the reply: the marker slides, ▲/▲▲ or ▼/▼▼ flashes (never a number), pips fill or empty. Band names are always written, so colour is never the only signal.
- **The reply** types out; tags show only through the portrait's face and the 3D body language.
- **The summary card** after the talk: the outcome in Dutch ("Staat erachter", "Afspraak onder voorwaarde", "Gehoord", "Geblokkeerd", "Gaat akkoord onder druk", "Mislukt — morgen weer"), the openness trace with the move chips under it, what you learned (a revealed layer, a new clue, a route hint) and, for a main-mission talk, "Bespreek met Ruud".
- **Mensen** (a new tab in the journal, J): per person the portrait, trust pips, morale band, what you know (position, interest, concern once earned), the last outcome, when you can talk again, and any route hint.
- **Dutch strings** only in `UiText` and content; `test_ui_text.gd` covers every new one.

---

## 12. Evidence

| Design element | Source | What it supports |
|---|---|---|
| The eight listening moves | **MORE PIES** as Merijn gave it: Mood, Open questions, Reflecting, Empathy, Paraphrasing, Inquiry, Experience, Silence, from **Order Out of Chaos** (Merijn's source; *verify*: not found online from this environment). The closely related crisis-negotiation mnemonic **MOREPIES** (Minimal encouragers, Open-ended questions, Reflecting/mirroring, Emotional labelling, Paraphrasing, I-messages, Effective pauses, Summarising) is documented in the FBI's Behavioral Change Stairway Model: Vecchi, G. M., Van Hasselt, V. B. & Romano, S. J. (2005), "Crisis (hostage) negotiation: current strategies and issues in high-risk conflict resolution", *Aggression and Violent Behavior* 10(5), 533–551; listening-skills handouts, e.g. https://www.yorksj.ac.uk/media/content-assets/careers-placements-and-student-opportunities/Non-Judgemental-Listening-Techniques.pdf | Listening first; reflecting feelings and paraphrasing make people feel heard; effective pauses (silence) draw out what is unsaid; the stairway (active listening → empathy → rapport → influence → behavioural change) is the order of §3.3: influence only lands after rapport. |
| Resistance and the six approaches; coercion gives compliance | **Kotter, J. P. & Schlesinger, L. A. (1979)**, "Choosing Strategies for Change", *Harvard Business Review* 57(2) (reprinted 2008). **Kotter, J. P. (1996)**, *Leading Change*. | Education, participation, facilitation, negotiation, manipulation and coercion map to perspective/data, co-proposal/experiment, empathy and check-ins, partial-with-condition, and pressure. Coercion is fast but risks resentment; it can be right when speed is essential (the safety exception, §4.2). |
| Awareness and desire before ability | **Hiatt, J. M. (2006)**, *ADKAR: A Model for Change in Business, Government and our Community*, Prosci. | Awareness (data, perspective) and Desire (the concern addressed → commitment) are what a talk can win; Knowledge and Ability come from the countermeasure and training; Reinforcement from sustain, buy-in and check-ins. |
| Commitment versus compliance; compliance fades | **Senge, P. (1990)**, *The Fifth Discipline*, ch. 11 (commitment, enrolment, genuine/formal/grudging compliance). **Herscovitch, L. & Meyer, J. P. (2002)**, "Commitment to organizational change: extension of a three-component model", *Journal of Applied Psychology* 87(3), 474–487. | Affective commitment predicts discretionary support for a change (championing, cooperation); compliance gives minimal, conditional support. The ×1.25 / ×0.6 factors are **estimates** of that direction, not measured values. |
| Pushing raises resistance; the "righting reflex" | **Miller, W. R. & Rollnick, S. (2013)**, *Motivational Interviewing*, 3rd ed. (OARS; the righting reflex; discord). **Miller, W. R., Benefield, R. G. & Tonigan, J. S. (1993)**, "Enhancing motivation for change in problem drinking: a controlled comparison of two therapist styles", *Journal of Consulting and Clinical Psychology* 61(3), 455–461. | A directive-confrontational style produced more resistance and worse outcomes than an empathic one: the TOO_EARLY and confront penalties; fixing mode in check-ins. |
| Asking instead of telling | **Schein, E. H. (2013)**, *Humble Inquiry: The Gentle Art of Asking Instead of Telling*, Berrett-Koehler. | Inquiry and open questions build the relationship that makes information flow upward; Ruud's after-talk questions. |
| Respect for people | **Toyota Motor Corporation (2001)**, *The Toyota Way 2001* (internal; its two pillars: continuous improvement and respect for people). **Liker, J. K. (2004)**, *The Toyota Way*, principles 9–10. Fujio Cho's "Go see, ask why, show respect". | Talking with your people, developing rather than replacing, check-ins with no mission. |
| Kata coaching after the talk | **Rother, M. (2009)**, *Toyota Kata* (the five coaching questions). | Ruud's `talk` stage (K1–K5). |

All dialog numbers (Δ values, thresholds, patience, buy-in and morale factors, reputation and trust changes) are **estimates** chosen for play, with their reasoning in §3–§5; they live as named constants in `rules/dialog.gd` and `sustain.gd`, marked `ESTIMATE`.

---

## 13. Build tasks

Mirrored in PLAN.md ("Dialog system: build per spec"). Each task: failing test first, then code, then the full suite (`godot --headless --path game --script res://tests/run_tests.gd`, `python tools/build_content.py --check`, `python -m pytest tests/ -v`), then `simplify`, then a PLAN.md update.

| # | Task | Depends on |
|---|---|---|
| D1 | Content schema + validator: `people.yaml` (with C5/K3), `dialogs.yaml`, `dialog_lines.yaml`, vocabularies; rules §9.2 | catalogue C1 (mission schema), C19 (needs grammar) |
| D2 | `Dialog`: state, moves, Δ rules, repetition, ceiling, layers, cue, patience, outcomes | D1 |
| D3 | `People`: trust, morale, memory, cooldowns, mood signals, buy-in, agreed KPIs, save/load | D2 |
| D4 | Links in the rules: `talk_to {dialog, outcome}` (with C5), buy-in in `Sustain`/`Region.life_days`, acting without asking, KPI weight halving, facts, unlocked clues/proposals, blocks and routes | D3, C9 (reputation), C19 |
| D5 | `GameSession`: `people_at`, `talk`, `say`, `end_talk`, `person`; one clock advance per talk | D4 |
| D6 | Coach: the `talk` stage and its bank (main mission only) | D5, audit §3A (C16) |
| D7 | Check-ins: cadence, prompts, expiry, `lifted`, fact variants | D3 |
| D8 | Discoveries D29–D34 (and D2 counting `confront`) | `rules/discoveries.gd` |
| D9 | Content: the cast of §6; the two sample dialogs; Frank's block; a dialog for each tier-1 people/conflict mission (Joost, Sanne, Marco, Esra, Petra, Henk, Mrs El Amrani); concepts | D1 |
| D10 | Content tests of §9.3 (reachable, no golden path, pushing costs, pressure works) | D2, D9 |
| D11 | UI (Phase D): speech panel, meter, chips and pickers, summary card, Mensen tab, NPC bubbles; `UiText` + tests; screenshots | D5 |

---

## 14. Open questions for Merijn

Each has a recommended option (**bold**).

1. **The reply chips.** **(a) A fixed palette: all eight MORE PIES moves and all steering moves always visible.** (b) 5–6 chips per turn, chosen by context. (c) A free palette with categories folded. *(a) teaches the eight by name, and nothing is filtered by fit, so nothing is handed over. (b) quietly hints which moves fit.*
2. **What a chip shows.** **(a) The move type, with the line on hover.** (b) The move type only. (c) The line only. *(a) keeps the decision about the kind of move, and the line keeps it human.*
3. **Acting without asking the owner.** **(a) Counts as compliance (×0.6).** (b) Neutral (×1.0); only pressure counts. *(a) makes "respect first" true in the numbers: imposing a change on someone without talking is pressure too.*
4. **The buy-in factors.** **(a) Commitment ×1.25, compliance ×0.6.** (b) Stronger: ×1.5 / ×0.5. (c) Milder: ×1.1 / ×0.8. *(a) is visible within one fix's life (the Obeya: 122 vs 59 days) without making talks matter more than standard work.*
5. **The cost of a ruined talk.** **(a) Reputation −1, trust −5, retry from the next working day.** (b) Reputation −2 and two days. (c) Trust only. *(a) is "a few points" and "after a day", as you described.*
6. **Morale.** **(a) A hidden number per person, shown as a band in the Mensen journal, with mild effects.** (b) A visible meter like openness. (c) No morale; trust only. *(a) keeps the screen calm and still makes check-ins matter.*
7. **People leaving.** **(a) Rarely: morale below 20 for 60 days and two ignored check-ins; a beat that closes a door, never the game.** (b) Nobody ever leaves. (c) More often. *(a) gives "people are the most valuable resource" a real consequence (the audit's Anouk beat).*
8. **Check-in cadence.** **(a) Signal-driven: at most one prompt, two a week, 14 days per person, expiring without cost.** (b) A weekly one-on-one routine (leader standard work, a side slot). (c) Authored beats only. *(a) is light enough not to become a chore; (b) could come later as a routine.*
9. **The cue "Er zit meer achter…".** **(a) Shown in tiers 1–2, then body language only from tier 3 on.** (b) Always shown. (c) Never; body language only. *(a) scaffolds the skill and then lets the player read people, as the game asks more.*
10. **The openness trace in the summary.** **(a) Yes, with the chips under it.** (b) No. *It is the best reflection tool, and it gives Ruud's K2 question something to point at.*
11. **Free text (Phase H).** **(a) Later, as a voice over the same state model: the LLM words the lines, the rules judge.** (b) Never. (c) Replace the model with an LLM judge. *(a) keeps play fair, deterministic and testable.*
12. **XP for talks.** **(a) None for dialogs themselves; mission goals pay, compliance at half.** (b) A small XP per commitment. *(a) avoids grinding talks and keeps respect from becoming a quest.*

---

## Sources

- Vecchi, Van Hasselt & Romano (2005), *Aggression and Violent Behavior* 10(5): 533–551 (the Behavioral Change Stairway Model; active listening skills).
- York St John University, "Non-Judgemental Listening Techniques": https://www.yorksj.ac.uk/media/content-assets/careers-placements-and-student-opportunities/Non-Judgemental-Listening-Techniques.pdf
- Wesley Mission, "Effective Listening Helpcard 1": https://church.wesleymission.org.au/wp-content/uploads/2024/11/Effective-Listening-Helpcard-1.pdf
- Kotter & Schlesinger (1979), "Choosing Strategies for Change", *Harvard Business Review* 57(2); Kotter (1996), *Leading Change*.
- Hiatt (2006), *ADKAR*, Prosci.
- Senge (1990), *The Fifth Discipline*.
- Herscovitch & Meyer (2002), *Journal of Applied Psychology* 87(3): 474–487.
- Miller & Rollnick (2013), *Motivational Interviewing*, 3rd ed.; Miller, Benefield & Tonigan (1993), *Journal of Consulting and Clinical Psychology* 61(3): 455–461.
- Schein (2013), *Humble Inquiry*.
- Toyota Motor Corporation (2001), *The Toyota Way 2001*; Liker (2004), *The Toyota Way*.
- Rother (2009), *Toyota Kata*.
- Order Out of Chaos, MORE PIES (Merijn's source; *verify*).
