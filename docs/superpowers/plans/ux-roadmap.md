# UX roadmap: Spanning (living plan)

> **Owner:** the UX lead (charter: `.superpowers/sdd/ux-lead/charter.md`). **First written** 2026-10-27, from the UX audit (`docs/qa/ux-audit-2026-10-27.md`, 27 findings), Merijn's answers on it (PLAN §9, 2026-10-27), the Phase 2 design (§1.8 the phone, §2 the talks), the Phase 3 design, the first-five-minutes spec, the Dutch style guide and the screens themselves (`play_shot.gd`, branch `claude/compassionate-heisenberg-ynlqyr` at `5bea89d`).
>
> **How to read it.** §0 is the bar every UI change is reviewed against. §1 lists the waves. §2 is wave UX-2, designed to build. §3 is wave UX-3, with the company word list for Merijn. §4 holds the new items beyond the audit, ranked. §5 lists where this roadmap touches slices 3.1–3.3. §6 holds the UX lead's own calls. §7 holds the questions for Merijn. Each item names the player problem, the change, its size (S under half a day, M one to two days, L more), the files, and whether a decision of Merijn's comes first.
>
> **Standing rules for whoever builds from this:** TDD per item, one commit per item, the gate green (`godot --headless --path game --import`, `python tools/run_godot_tests.py`, `python tools/build_content.py --check`, `python -m pytest tests/ -q`); a screenshot before and after with `game/tools/play_shot.gd` (one Godot process at a time, never `pkill godot` broadly); every string through `tr()`; every spoken line through the style guide and `BANNED_SPOKEN`. **Network rule (CLAUDE.md §3):** never open a domain Merijn has not approved; sounds come from `opengameart.org` or `itch.io` only, listed in `game/assets/audio/SOURCES.md`.

---

## 0. The bar: ten questions for every screen

A change passes when the answer to each is yes. Reviews quote the number.

1. **World first.** Could this be shown by a person, a place or an object in the office before it is shown by a panel? If a panel is needed, could it be on the phone? A panel over the world is the last resort (Phase 2 design §4, standing rules).
2. **A person or place before a number.** Where a number is shown, does someone say it or does a place show it first?
3. **Company words.** Would a colleague at a Dutch netbeheerder use this word on a normal working day (§3.1)? Game words stay on the title and pause menus only.
4. **One thing at a time.** While someone talks, a call rings or a panel is open, is everything else hidden (audit #9)?
5. **Every action lands.** Within a tenth of a second of the player's action, is there a sound, a motion and a visible place where the result went (§4, U4-2)?
6. **Readable on a laptop.** At 1366×768, is body text at least 15 px and secondary text at least 13 px on screen (§4, U4-6)? At 1080p the project's 1600×900 canvas scales text by 1.2; at 1366×768 by 0.85.
7. **Colour is never alone.** Does every colour that means something also carry a shape, an arrow or a word (§4, U4-7)?
8. **Keys and mouse both work.** Does every key action have a click, and every click a key (§4, U4-10)?
9. **Your own name and choices.** Where generic text could stand, does the player's name, the person's name or the player's own words stand instead?
10. **No timers, no guilt.** Can the player stop here and come back without loss (CLAUDE.md §2)?

---

## 1. The waves

| Wave | What | Who | State |
|---|---|---|---|
| **UX-1** | Audit #1 #2 #6 #8 (pronoun) #9 #10 #11 #12 #18 #22: the S items for Friday's playtest | another agent | in flight |
| **UX-2** | #3 the talk camera, #8 Ruud as a real talk, #7 in-world panel styles | UX lead or a UI agent | designed here (§2), ready to build |
| **UX-3** | #4 company words, #5 the top bar, and the audit's other build-now items (#13–#17, #19–#21, #23–#27) | UI agent | designed here (§3); #4 waits for Merijn to see the list (§7 Q1) |
| **UX-4** | New items beyond the audit, ranked (§4) | UX lead with the world and UI agents | ranked; the top three can start after UX-2 |

**Order inside the waves and why.** UX-2 first, because the talk is the game's most repeated moment and the camera makes every talk feel either like a film or like a floor plan. Within UX-2, the camera (#3) lands before Ruud's talk (#8), because the talk is staged with it. The board in #7 uses the new words, so Merijn's answer on the word list (§7 Q1) should come before #7b is built; if it has not, #7b is built with the words behind constants, and #4 swaps them. UX-3's top bar (#5) waits for the Ik and Voltana apps (slice 3.1, Task 9), which are where XP, the belt and the budget go.

---

## 2. Wave UX-2 (designed to build)

### 2.1 #3 The talk camera: over the shoulder, not over the floor plan (M, build now)

**Player problem.** Every turn the camera jumps from a 1.5 m face shot to a 7.5 m shot at 62° pitch (`CameraRig.SCENE_DISTANCE`, `SCENE_PITCH`). The player and Joost become 40 px figures in a floor plan, and the four sentences float over the carpet (`docs/screenshots/ux-audit/talk_choose.png`). The opening's beats, Frank's question in the MT room (`mt_room.png`) and the talk summary are shot from the same height. The van talk (`play_van_choose`) shows what it should be: both people at seat height, faces readable, the world around them.

**What the player sees, beat by beat.**
1. **They speak:** the face shot as today (1.5 m, 5°, from the side that sees their face: `OfficeStaging.frame_face`).
2. **You choose:** a **cut** (not a 0.5 s swoop) to an over-the-shoulder two-shot: the camera stands about 2.8 m from the point between you, about 22° above level, behind your shoulder on the side that sees more of their face. Your shoulder and the back of your head fill the left or right third; their face and upper body fill the other third, above the sentences. Their last line stays as the subtitle.
3. **The next line:** a cut back to their face. The cuts alternate like a film's shot and reverse shot. Only the first framing of a talk glides in (from the walking view), so the player sees where they are.
4. **Boxed in** (a corridor, a desk against a wall): the other shoulder; then square to the pair at 3.2 m; only then the high shot of today, as the last resort.
5. **The summary note** (or, after UX-3 #13, the talk's end) holds the last over-the-shoulder frame.
6. **The same grammar** for the opening's Yvonne and Ruud lines (`OfficeStaging.frame_scene`), the MT room (a table shot: from your seat across the table to the speaker, ~3.5 m, ~25°) and the walking talk (a following two-shot at ~4 m and ~30°, from behind and beside the pair).

**The change.**
- `CameraRig`: a new shot `OVER_SHOULDER` with `OTS_DISTANCE := 2.8`, `OTS_PITCH := deg_to_rad(22.0)`, `OTS_SHIFT` (the player's shoulder to one third) and `TABLE_DISTANCE := 3.5`, `TABLE_PITCH := deg_to_rad(25.0)`, `WALK_DISTANCE := 4.0`, `WALK_PITCH := deg_to_rad(30.0)`. Estimates, tuned on the screenshots; the comment says so. A `cut()` that sets the shown values to the wanted ones (the existing `snap()` does this; use it on a phase change inside a talk).
- `OfficeStaging._two_shot` becomes `_pair_shot(person, lift, mode)`: candidates in order (the shoulder that sees more of the face, the other shoulder, square to the pair, the old high shot), each accepted only when `in_sight(eye, face)` and the player's head and shoulder are seen (`sees` with the player's upper body points only). The ceiling cutaway already works (`CUTAWAY_LAYER`); walls between camera and pair fail `in_sight`, so the next candidate is tried.
- `OfficeStaging.stage_talk` calls `rig.snap()` after a phase change while a talk is open (the cut). `frame_scene` uses the pair shot; `OfficeMilestone` uses the table shot.
- The sentences' box (`TalkView._choose_box`) keeps its place at the bottom; with the camera lower, `PAIR_LIFT` (0.12) is re-tuned so the face sits above the sentences.

**Files.** `game/src/world/office/camera_rig.gd`, `office_staging.gd`, `office_milestone.gd`, `office_opening.gd` (its framing calls only); tests `game/tests/test_talk_staging.gd` (new) or the existing staging tests in `test_dialog_ui.gd`.

**Tests.** In the open office beside Joost, the choose phase's camera is under 3.2 m from its point and its pitch under 28°, and `in_sight` holds for Joost's face; a pair against a wall gets the other shoulder; a pair boxed in on both sides gets the high shot; a phase change inside a talk cuts (the shown distance equals the wanted one the same frame); the van's own framing is untouched (`VanRide.frame_talk`). The route check and autoplay are unchanged (they use the engine, not the view).

**Screenshots** (before and after): `talk_choose`, `talk_face`, `dialog_summary`, `open_reception`, `milestone_question`, `play_van_choose` (unchanged).

**Decisions.** None needed (Merijn: "build now"). The cut instead of the glide is the UX lead's call (§6); the playtest checklist asks about it.

---

### 2.2 #8 Talking to Ruud: a real talk (L, build now; Merijn decided it)

**Player problem.** Ruud is a menu: a light-blue web card over his room with his question in a quote box before you ask, a button "Vraag om coaching", and a help line under it (`coach.png`). The coaching that should feel like a mentor's attention feels like pressing for a hint. Merijn decided (2026-10-27): talking to Ruud becomes a real talk in the talk view.

**The rules this must keep** (CLAUDE.md §2, PLAN §4.4): Ruud is a senior manager who coaches **the main mission only** (and the training week); he **mostly answers with a question** in Toyota Kata style (target, actual condition, obstacles, next step, what did you learn) and rarely with an answer; asking about a side mission gets **no coaching**; **nothing is handed over**; there is **never one right answer**; and the player's time is respected.

**The idea in one sentence.** Ruud asks one Kata question; the player answers in **their own words, built from what they really found** (their clues, their A3, the people they spoke to), or honestly says they do not know yet; Ruud's next question follows from *what kind* of answer it was, never from whether it was "right"; three exchanges at most; the answers fill a Kata card in Notities, the learner's storyboard (Rother, *Toyota Kata*).

#### Beat by beat

**B0 · Approaching him.** Ruud sits at his desk in his glass room on the 1e (from `review_100_days` in his office on the 2e: cast `moves`). He keeps his day (`cast.json`: in 07:45, coffee 10:00, lunch 12:15, out 17:30). Near him the prompt reads **"E — Praat met Ruud"** (today "E — Coach: Ruud Hoekstra"). He is a person like the others: hover shows his name tag; E or a click on him starts the talk wherever he is (at the coffee corner too: he stops and turns). In his empty room the place itself says where he is, in his words on a sticky note on the door: "Even lunchen. R." / "Morgen weer. R." There is no way to summon him by menu; the coach never blocks progress, so an empty room costs nothing.

**B1 · He looks up.** He swivels his chair towards you (`face_toward`, the talk pose), the camera cuts to his face (§2.1), the name tag shows **"Ruud Hoekstra · directeur"**, **with no trust pips** (the coach is not a meter; §6). His first line is chosen by the first that holds:
1. **A comment is due** (slice 3.1-E, `Coach.comment_due`): he says it (holds: what he saw, "Ik liep langs Werkvoorbereiding. Anouk ging om vijf uur naar huis."; slips: a question, "Zag je het bord bij Intake vanmorgen?") and `comment_said` marks it. Then B2. This is the same comment he says in passing (`greet`) or by Berichten after three days unmet; it is said once, wherever you meet him first.
2. **You just had a hard main-mission talk** (`People.coach_after`): his after-talk question is his first question ("Wie was er aan het woord in de eerste minuut?"). Slot `talk` (below).
3. **You already spoke today and nothing changed since** (no new clue, no new phase, no talk: compared with a small `coach_seen` stamp): "We spraken elkaar vanochtend. Wat heb je sindsdien gezien?" Answers: one *own* answer per new thing if any, else **"Nog niets nieuws, eerlijk gezegd."** → "Dan weet je waar je heen moet." and the talk ends. One Kata cycle a day, never more (§7 Q5); no hint can be farmed.
4. **No main mission and no training day:** "Hoi {speler}. Waar wil je aan werken?" Answers: **"Ik ga kijken wat er op het verbeterbord hangt."** → "Doe dat. Ik ben benieuwd wat je kiest." · **"Ik kwam eigenlijk even gedag zeggen."** → "Dat waardeer ik. Echt. Koffie staat daar." Both end the talk. (The second is the respect-for-people door: talking with your people, no mission attached.)
5. **Otherwise:** a greeting by the time of day ("Goedemorgen. Kom erbij zitten." · "Kom binnen. Waar sta je?" · after 16:30 "Ik ga zo naar huis, maar één vraag kan nog.") and then his question from `Coach.ask` exactly as today: the number first when `CoachNumbers` reads one ("De doorlooptijd is nu 54 dagen. Waar wil je naartoe, en waarom juist dat getal?"), a conditional once (`blamed`, `fading_fix`), the Kata five in order during an experiment, else the stage bank without repeats; every third ask at one stage, an insight (rare answers stay rare).

**B2 · Your answer.** Three or four sentences above his line, as in every talk, plus **"Afronden"**. They are never a quiz: each is something the player can truthfully say *now*, built from their own play, so different players see different sentences. Each sentence has a **kind** that steers his next question, and nothing in the sentence's look shows the kind:

| Kind | When it is offered | Example (fix_custom_design) |
|---|---|---|
| `own` | the player has it: a key clue found, a count made, the A3's cause, countermeasure or predicted KPI, the Check's result | "Wat ik zag: elk ontwerp, ook een standaard huisaansluiting, gaat langs drie handtekeningen." |
| `heard` | a clue that came from a person (a talk, a place question) | "Anouk vertelde me dat ze elk ontwerp van nul tekent." |
| `face` | the mission's person (the `talk_to` dialog's person, or a new optional `face:` on the mission) | "Dat Anouk weer gewoon om vijf uur naar huis kan." |
| `leap` | before the experiment: the tempting shortcut (the problem's `shortcut: true` countermeasure, said in a person's words via an optional `leap:` line on the problem; a generic line otherwise) | "Twee extra werkvoorbereiders erbij, dan is het toch opgelost?" |
| `gap` | always | "Eerlijk gezegd weet ik dat nog niet." |

When the player has two *own* things for a slot, both are offered (pick the one you think matters: that choice is the thinking). No sentence is ever tagged, coloured or ordered by fit; the order is fixed per slot (own, heard, face, leap, gap) so it says nothing either.

**B3 · His next question.** One line, a question, chosen by the slot of his question and the kind of your answer (content, two or three variants each, no repeats in a row). It never says "goed" or "fout"; it asks the next thing a Kata coach asks. A `gap` answer is never punished: it gets the question that points to the gemba. A `leap` gets "Dat is een oplossing. Welk probleem lost die op?". The slots and the full first set of lines are in the table under *Content*.

**B4 · Three exchanges at most.** After your third answer, or earlier when his question was the fifth Kata question, he closes the cycle with the Kata's last question: **"Wanneer kunnen we gaan kijken wat je ervan geleerd hebt?"** Answers: "Morgen al." · "Na de Check, {check_dag}." (only while an experiment runs) · "Als ik bij {team} ben geweest." → "Goed. Dan kijk ik daarna even met je mee." (an estimate: Rother's coaching cycle takes about twenty minutes; an exchange is five in-game minutes, as an expert topic, `ExpertTalk.MINUTES_PER_TOPIC`).

**B5 · The talk ends.** He turns back to his screen; the view closes without a summary screen (as an expert talk). Notities gets the **Kata-kaart** for the main mission (below), updated with what you said, with the pen sound (U4-2). Nothing else: no XP, no trust, no toast. "Afronden" at any point: "Goed. Je weet waar ik zit." No cost.

**Side missions.** While a side is active, the first answer list (B2 after B1.5) offers one more sentence once per side: **"Ik wilde het eigenlijk over {zij_opdracht} hebben."** → "Dat is jouw eigen klus, daar bemoei ik me niet mee. Hoe staat het met {hoofdopdracht}?" and his first question again. No coaching on the side, in his own words (the rule taught by the fiction, not by a help line).

**After a hard talk.** The talk summary's "Bespreek met Ruud" button (`TalkView._talk_over`) becomes **"Bel Ruud"** while he is at work (before `RUUD_HOME_AT`): the same coach talk in the PHONE setting, opening on B1.2. After 18:00 the button is not shown; his after-talk question waits for your next visit (it already waits in `People.coach_after` until the main mission changes).

**Later, by phone.** From `ruud_farewell` (slice 3.3) the same talk runs in the PHONE setting from Wie is wie ("Bel Ruud"), once a month (`ask_coach` cooldown 28 days, one cycle per call). Nothing in this design needs changing for it; the cooldown replaces B1.3's once-a-day rule.

#### The Kata-kaart in Notities

An index card per main mission, styled as Rother's coaching card, five rows: **Doel · Nu · Obstakel · Volgende stap · Wanneer kijken we**. Each row holds the player's last answer for that slot in their own sentence; a `gap` answer shows "nog niet bekend"; a slot never answered stays empty. It is the player's storyboard: it shows them their own thinking without a grade, and it is what Ruud reads back next time (B1.3 compares against it). It replaces nothing; it sits above the clues of that mission. Saved in Missions progress (`kata`), so `test_split_keeps_save_keys` gains the key.

#### Content

Where: `content/missions.yaml` under `coach:` (it already holds `stages`, `conditional`, `numbers`, `kata`): a new `talk:` block (Ruud's lines: openers by time of day, `again_today`, `no_main`, `hello`, `side`, `close`, `afronden`, and `replies: {slot: {kind: [lines]}}`) and `answers: {slot: {kind: template}}` (the player's sentences). Per mission, optional `face:` (a person id); per problem, optional `leap:` (one spoken line). The stage bank's questions gain a slot each: `stages.go_see` entries become `{q, slot}` (default per stage: go_see → actual, understand → obstacle, experiment → next, reflect → reflect); `kata[n]` maps to target, actual, obstacle, next, when; `conditional` to `blamed` and `fading`; the after-talk bank to `talk`.

Tokens (filled before anyone reads them, never checked by `BANNED_SPOKEN`): `{speler}`, `{team}`, `{wie}`, `{aanwijzing}` (a clue's text, first letter lowered, its own quotes kept), `{oorzaak}` (the A3's cause), `{maatregel}` (the countermeasure's name), `{kpi_naam}`, `{kpi_doel}` and `{richting}` (from a new `goal_phrase` and `better_phrase` per KPI in `content/kpis.yaml`: "een kortere doorlooptijd", "korter wordt"), `{check_dag}`, `{hoofdopdracht}`, `{zij_opdracht}`.

The first set of lines (Ruud: warm, calm, one question per line; the player: a thoughtful new colleague, *je* to Ruud; style guide §7–§8). The writer may improve them; the slots and kinds stay.

| Slot (his question) | Player sentences by kind | His next question by kind |
|---|---|---|
| **target** ("Wat wil je bereiken?", Kata 1) | own: "{kpi_doel}, bij {team}." · face: "Dat {wie} weer gewoon op tijd naar huis kan." · leap: (problem's `leap:`) · gap: "Eerlijk gezegd weet ik dat nog niet." | own: "Hoeveel, en wanneer wil je dat zien?" · face: "Mooi. Hoe zie je dat straks aan het werk zelf?" · leap: "Dat is een oplossing. Welk probleem lost die op?" · gap: "Wat zou je over een maand graag anders zien?" |
| **actual** ("Hoe is het nu echt?", Kata 2) | own: "Wat ik zag: {aanwijzing}" · heard: "{wie} vertelde me: {aanwijzing}" · own (a count): "Ik heb geteld: {telling}." · gap: "Ik ben er nog niet echt gaan kijken." | own: "Hoe vaak gebeurt dat, denk je?" · heard: "En heb je het ook zelf gezien?" · count: "Is dat veel of weinig? Waarmee vergelijk je het?" · gap: "Wat houdt je tegen?" |
| **obstacle** (Kata 3) | own: "Volgens mij: {oorzaak}." · face: "Ik weet nog niet of {wie} meedoet." · gap: "Ik zie zoveel dat ik niet weet waar ik moet beginnen." | own: "Welk obstakel pak je als eerste aan?" · face: "Wat heb je {wie} al gevraagd?" · gap: "Welk obstakel zit het dichtst bij het werk?" |
| **next** (Kata 4) | own (experiment): "{maatregel}. Ik verwacht dat {kpi_naam} {richting}." · own (before the A3): "Nog een keer kijken bij {team}, maar dan anders." · face: "Eerst met {wie} praten." · gap: "Ik weet het nog niet." | own: "Wanneer kunnen we zien of dat klopt?" · look: "Wat ga je anders doen dan de vorige keer?" · face: "Wat wil je dat {wie} na dat gesprek denkt?" · gap: "Wat is de kleinste stap die je morgen kunt zetten?" |
| **when** (Kata 5) | "Morgen al." · "Na de Check, {check_dag}." · "Als ik bij {team} ben geweest." | (all) "Goed. Dan kijk ik daarna even met je mee." (ends the cycle) |
| **reflect** ("Wat had je verwacht, en wat gebeurde er echt?") | own (it moved): "Ik verwachtte dat {kpi_naam} {richting}, en dat gebeurde ook." · own (it did not): "Ik verwachtte dat {kpi_naam} {richting}. Dat gebeurde niet." · face: "Dat {wie} het antwoord eigenlijk al wist." · gap | moved: "Hoe weet je dat het door jouw stap kwam?" · not: "Wat zegt dat verschil je?" · face: "Wat betekent dat voor hoe je de volgende keer begint?" · gap: "Wat zou je anders doen als je opnieuw begon?" |
| **talk** (after a hard talk) | "Ik, vooral." · "Vooral {wie}." · "Dat weet ik eerlijk gezegd niet meer." | "Wat had je gehoord als je langer had gezwegen?" · "Wat zei {wie} wat je nog niet wist?" · "Let er de volgende keer eens op. Wat verwacht je te zien?" |
| **blamed** ("Wat wilde je eigenlijk weten toen je dat vroeg?") | "Waarom het zo lang duurt." · "Wie er fout zat, eerlijk gezegd." · "Dat weet ik niet precies." | (all) "Hoe vraag je dat zonder dat iemand zich aangesproken voelt?" |
| **fading** ("Hoe lang verwacht je dat dit blijft werken? En dan?") | "Een paar maanden. Daarna zien we wel." · "Zolang iemand het bijhoudt." · "Daar heb ik nog niet over nagedacht." | (all) "Wie houdt het bij als jij er niet bent?" |

Validation (`tools/build_content.py`): every slot has a `gap` sentence and a reply for every kind it offers; Ruud's `replies` all end in "?" except `close`, `afronden`, `hello` and the comments; Ruud's lines and the player's sentences are spoken (`BANNED_SPOKEN`, the style guide's checklist), the answers' tokens are only those listed; no digit in a template (numbers come only through `CoachNumbers`' `{value}`).

#### The change in code

- **Rules:** `game/src/rules/coach_talk.gd` (new, `class_name CoachTalk`, RefCounted, no nodes, like `ExpertTalk`): built from `Coach`, the region, the player's clues and facts; `opening() -> {text, slot}`, `offers() -> Array[{text, kind, slot}]`, `say(index) -> {reply, ended, slot}`, `card() -> Dictionary`. `Coach` gains `slot_of(question)` and the once-a-day stamp; Missions saves `kata` and `coach_seen`.
- **Session:** `SessionTalks.start_coach_talk(s)` and `choose_coach(s, index)`, mirroring `start_dialog` / `_ask_expert`; `GameSession.ask_coach` stays for autoplay and tests (the bots keep using it).
- **View:** `TalkView.coach()` (as `expert()`): no pips, no arrow, no summary screen; the sentences from `offers()`; the end closes the view. `CoachPanel` is removed with its tests moved to `test_coach_talk.gd`; `GameUI.open_coach` starts the talk (and `talk_view.coach_requested` becomes the "Bel Ruud" call).
- **World:** `Office.talk_to` for `person.talk == "coach"` starts the talk where he is; `Office` prompt strings (`office.gd:501`, `:518`, `:546`); the empty-room note on the door (an `OfficeTells`-style sign with the text from his day, or a `Label3D` on the door).
- **Notities:** `notes_app.gd` / `ClueJournal` shows the Kata-kaart at the top of the main mission's section.

**Tests** (`game/tests/test_coach_talk.gd`, new): the opening order (comment, after-talk, again-today, no main, normal); a side's sentence leads to the redirect and no coaching question (`Coach.ask` is not called for the side); an `own` sentence is offered only when the evidence exists (no clue, no "Wat ik zag"); `gap` is always offered; at most three exchanges, then the `when` close; a second visit the same day with nothing new ends on "Dan weet je waar je heen moet."; no trust, XP or reputation moves; the Kata-kaart holds the last answer per slot and survives a save round trip; every Ruud line in a run ends in "?" except the allowed kinds; replay of a talk in the designer page still works (`talk_replay.gd` lists the coach talk). Autoplay and the route check are untouched.

**Screenshots:** `coach_talk_face` (Ruud's face shot with his question), `coach_talk_choose` (the over-the-shoulder shot with the sentences), `coach_side` (the redirect), `phone_notes_kata` (the card).

**Size:** L, in four commits: (1) content and validator, (2) `CoachTalk` and the session API, (3) the view, the world and the removal of `CoachPanel`, (4) the Kata-kaart.

**Decisions.** Merijn decided the talk. One rule question is his (§7 Q5: one cycle a day). The rest are the UX lead's calls (§6).

---

### 2.3 #7 In-world panel styles (M each part, build now)

**Player problem.** Two styles fight. The A3 (a clipboard), the Check (Petra's monitor), the KPI board (a whiteboard) and the phone are in the world. The mission board, coach, intussen, terugblik, pause menu and place menu are light-blue web cards with blue "Sluiten (Esc)" buttons (`board.png`, `intussen.png`, `terugblik.png`), and behind the board the camera frames a corner of beige wall blocks.

**One rule for all:** a panel shows the object it is in the fiction, and the camera frames that object behind it. `UiPanel` gets a `material` (`PAPER`, `CORK`, `PHONE`, `SCREEN`, `META`) that sets the panel's style box, ink colour, font and close affordance from `UiTheme` tokens; the big blue "Sluiten (Esc)" button becomes a small "×" in the corner with "Esc" beside it in the ink colour, on every material but `META`. The coach panel disappears (§2.2).

**7a · The pause menu and the place menu (S–M).**
- *Pause* (`META`): it is outside the fiction and may stay a menu, but it stops looking like a web page: the world dims and blurs (the phone's backdrop shader, `phone_backdrop.gdshader`), one plain card in the palette's paper and ink, no blue buttons. "Inwerkweek overslaan" lives here and on the title menu (audit #22).
- *Place menu* (`PAPER`): your **notitieblok**, a spiral pad docked right, the place as a handwritten heading ("Werkvoorbereiding · ma 12 okt"), the tools as lines you can tick ("Tel de stapel", "Loop een dossier mee"); a result is written in under its line with the pen sound (U4-2), and a *Waarneming* in the same hand. The camera keeps framing the station beside it (`OfficeStaging.frame`).

**7b · The verbeterbord (M).** What the player sees: E at the board on the 1e; the camera frames the real cork board (`staging.frame` on the board's interactable, the board filling the left two thirds); the panel is the board itself in close-up (`CORK`), three columns in marker on paper strips: **Open · Mee bezig · Klaar** (a kanban, which teaches visual management by being one).
- A main mission is an A5 index card with a red pin, its chapter as a small line on top ("De eerste honderd dagen"), the name, the briefing in typewriter ink. A side is a yellow sticky. A routine is a laminated card ("vaste ronde"). A repair is a card with a red corner ("terug"). A fork is two cards side by side with Ruud's sticky note between them: "Welke eerst? R."
- **"Oppakken"** under an open card: the card slides from Open to Mee bezig (0.3 s) with a pin sound; the phone's Opdrachten app follows.
- *Klaar* shows the last five cards stacked with their date ("ma 26 okt"); older ones are "nog 7" (the full history lives in the Ik app or Notities, not on a board).
- Arrow keys move between cards, Enter picks up, Esc closes (§0.8).
- The prop's own texture (`tools/blender/textures.py` `missions()`: "MISSIES", "HOOFDMISSIE", "ZIJMISSIE", "AFGEROND") is redrawn with the new words and re-baked; if Blender is not available in the session, a `Label3D` or decal over the sign until the next bake, logged in PLAN.
- Words: from the approved list (§3.1); until Merijn answers, behind constants.

**7c · Intussen becomes the phone's Agenda (M).** What the player sees: when the A3 goes in, the phone rises with a new **Agenda** app open on the days up to the Check: the Check as an appointment ("Check met Petra · ma 26 okt"), who wants you ("Anouk · wil je spreken"), what could fit alongside ("Kan ernaast: Een nacht met de storingsdienst"), deadlines further out ("Henk met pensioen · 31 mrt"). At the bottom, one button: **"Door naar ma 26 okt"**; the phone's clock runs while the world fades, and stops early when someone wants you (the existing skip rules, `SessionLayer.intussen`). The Agenda stays on the phone's home afterwards, so the player can look ahead any time (the phone is the hub: Phase 2 decision 2). The words "skip" and "Spoel door" go (§3.1).
Files: `game/src/ui/phone/agenda_app.gd` (new, wraps `SessionLayer.intussen`), `phone.gd` (`AGENDA`), `game_ui.gd` (open the phone on Agenda where it opened `IntussenPanel`), `intussen_panel.gd` removed; tests move to `test_agenda_app.gd`.

**7d · The terugblik becomes the lock screen (S–M).** What the player sees on resuming a game: the office at the moment they left, the phone raised showing its **lock screen** with the time and three or four notifications stacked as a phone shows them: Ruud's note at the top (his photo, his question), the Voltana app's change ("Doorlooptijd Nieuwe aansluitingen 55 → 47 dagen"), who wants you ("Anouk · 'Heb je even?'"), what is coming (an Agenda reminder). One action: **"Ontgrendel"** (or any key) and the phone lowers into the day. The card's content is unchanged (`TerugblikCard` builds it); only its frame moves to the phone.
Files: `game/src/ui/terugblik_card.gd` (render into the phone), `phone.gd` (a lock-screen state), `game_ui.gd`.

**Tests** for 7a–7d: each panel's material is the one listed; no "Sluiten (Esc)" button remains outside `META`; the board's three columns hold the right cards (open, active, done) and Oppakken moves a card; the Agenda's button names the Check date and the skip stops as before; the lock screen shows Ruud's note first and lowers on any key; the camera frames the board while it is open (`rig.shot == INSPECT`, its point on the board).

**Screenshots:** `board`, `training_board`, `fork_board`, `intussen` (now the Agenda), `terugblik` (now the lock screen), `pause`, `inspect`, `tools`.

---

## 3. Wave UX-3

### 3.1 #4 Company words: the full list for Merijn (M, needs Merijn to see it)

**Player problem.** Game words are on screen every few minutes: "Missiebord", "hoofdmissie · zijmissie", "Missie aangenomen", "Akte I", "Je score: 24 van de 25", "Voor wie het spel al kent", "Titel: Knelpuntjager", and a cork board painted "MISSIES". Merijn decided (2026-10-27) that they become company words.

**Principles of the list.** (1) Use the words a Dutch office with a Lean programme uses: *verbeterbord*, *opdracht*, *oppakken*, *afgerond*, kanban columns. (2) Lean's own words stay (A3, Check, KPI, gemba, dagstart, borgen): they are company words at Voltana and the game teaches them. (3) The phone app already says *Opdrachten* and the objective line already says *opdracht*, so *opdracht* is the generic word, not *klus* (people may still say *klus* out loud). (4) Grades become a person's words. (5) The title menu, the pause menu and the save slots are outside the fiction and keep *spel* (allowed: "Nieuw spel", "opgeslagen spel").

| # | Now (where) | Becomes | Note |
|---|---|---|---|
| 1 | **Missiebord** (`mission_board.gd:37`, `office.gd:548`, the prompt "E — Missiebord") | **Verbeterbord** | prompt "E — Verbeterbord" |
| 2 | Prop texture **MISSIES**, card labels HOOFDMISSIE / ZIJMISSIE / AFGEROND (`tools/blender/textures.py:417`) | **VERBETERBORD**; columns **OPEN · MEE BEZIG · KLAAR** | re-bake (§2.3 7b) |
| 3 | missie (generic, `ui_text.gd` ACCEPT_ERRORS, `office_map.gd:60` "Je missie") | **opdracht** ("Deze opdracht bestaat niet.", "● Je opdracht") | |
| 4 | hoofdmissie (`mission_board.gd:259`) | **hoofdopdracht** | |
| 5 | zijmissie (`mission_board.gd:262`) | **erbij** as the card's tag; in a sentence "een opdracht erbij" | "Je hebt al drie opdrachten erbij." |
| 6 | Aannemen (board button, `missions_app.gd:17`) | **Oppakken** | "Oppakken doe je bij het verbeterbord." |
| 7 | Actief / Beschikbaar / Afgerond (board sections) | **Mee bezig / Open / Klaar** | |
| 8 | "Nog geen missie. Kies er hieronder een." | "Nog niets opgepakt." | |
| 9 | "Er staan nu geen nieuwe missies open." | "Er hangt nu niets nieuws." | |
| 10 | "Missie aangenomen: %s" (`ui_text.gd:146`, `game_ui.gd:611`) | **"Opgepakt: %s"** | |
| 11 | "Missie voltooid: %s" | **"Afgerond: %s"** | |
| 12 | "Missie verlopen: %s" | **"Te laat: %s"** | the door that closed is said by its fail line |
| 13 | "Verlopen: %s De missie blijft open, nu zonder klok." | "Te laat: %s De opdracht blijft staan, nu zonder datum." | |
| 14 | "Op het missiebord: %s" / "Herstel op het missiebord: %s" | "Nieuw op het verbeterbord: %s" / "Terug op het verbeterbord: %s" | becomes a phone bubble with UX-3 #17 |
| 15 | "Twee hoofdmissies tegelijk: welke pak je eerst aan?" | Ruud's sticky note between the two cards: "Welke eerst? R." | §2.3 7b |
| 16 | "Je hebt al een hoofdmissie. Maak die eerst af." | "Je hebt al een hoofdopdracht. Rond die eerst af." | |
| 17 | "Kies je volgende opdracht op het missiebord" (`objective.gd:18`) | "Kijk op het verbeterbord wat je oppakt" | |
| 18 | "Er zit nog geen A3 op je klembord. Neem eerst een missie aan op het missiebord." | "Er zit nog geen A3 op je klembord. Pak eerst een opdracht op van het verbeterbord." | |
| 19 | Ruud's spoken coach lines with "missiebord", "hoofdmissie", "zijmissie" (`ui_text.gd:116–117`) | his talk lines (§2.2: "Waar wil je aan werken?", "Dat is jouw eigen klus…") | they break the style guide today: spoken, but not validated |
| 20 | "Ruud · er ligt een nieuwe hoofdmissie op het bord: %s" (`terugblik_card.gd:24`) | Ruud: "Er hangt iets nieuws op het verbeterbord: %s." | spoken |
| 21 | **Akte I · De eerste honderd dagen** … **Akte VI** (`ui_text.gd:180–182`) | the chapter only: **De eerste honderd dagen · Wat onder de grond zit · Zichtbaar maken · Flow door de regio · Het systeem · Het digitale net** | no act number on screen; the designer page keeps "Akte" |
| 22 | "Inwerkweek — ma: Rondleiding", "Voltooid: Inwerkweek — …" | "Inwerkweek · maandag: Rondleiding" on a Klaar card | |
| 23 | "Voor wie het spel al kent." (board, `mission_board.gd:230`) | gone from the board; "Inwerkweek overslaan" on the title and pause menus | audit #22 |
| 24 | **"Je score: 24 van de 25"** and five "4 / 5" grades; "Om van te leren" (`check_panel.gd:254–257`) | **"Ruud over je A3"**: two or three handwritten margin notes on your A3, one thing that was strong and one to learn (from `SCORE_NOTES` plus a new positive line per dimension); no number, no grade | the score stays internal (Discoveries read it) |
| 25 | "Check geslaagd" / "Check niet geslaagd" (`check_panel.gd:145`) | **"De Check: het werkt"** / **"De Check: het werkt (nog) niet"** | Check stays: a Lean word |
| 26 | **XP** (`hud.gd:172`), "Nieuwe band: %s!" | off the screen (§3.2); the belt as a certificate (U4-4) and in the Ik app | belt names: §7 Q2 |
| 27 | "Achteruitgang 20%" (`hud.gd:175`), "achteruitgang door stilstand: 0%" (Notities) | gone; the world and Ruud say it (§3.2, #20) | |
| 28 | "Reputatie bij het MT −5 (het budget staat rood)" | Frank's message in Berichten, no number: "Frank: 'Het budget staat rood. Kunnen we morgen even zitten?'" | UX-3 #17; §7 Q4 |
| 29 | "Ontdekking: %s (K)" toast; codex tab **Ontdekkingen**; "Titel: Knelpuntjager" (`codex_panel.gd:291`) | the object lands on your desk with Ruud's card ("Ruud legde iets op je bureau"); the tab **Aandenkens**; a title becomes a **bijnaam** colleagues use ("Ze noemen je hier de knelpuntjager"), heard once in a greeting or chatter | U4-4 |
| 30 | "Spoel door tot de Check: %d dagen", "De skip stopt vanzelf…", "Niemand wacht op een vaste datum: de skip loopt door…" (`intussen_panel.gd`) | "Door naar %s" (the date); "Wil iemand je eerder spreken, dan hoor je het." | §2.3 7c |
| 31 | "E — Coach: Ruud Hoekstra" (`office.gd:501`, `:518`), "Coach: Ruud Hoekstra" (map) | "E — Praat met Ruud"; on the map "Ruud" | |
| 32 | "Aanwijzingen" (Notities' title, "komt in je aanwijzingen (J)") | **Notities** everywhere | audit #19 |
| 33 | "Telefoon · Tab · 8 nieuw" | a phone icon with a badge "8" | §3.2 |
| 34 | key letters in toasts "(K)", "(J)" | gone | audit #17 |
| 35 | REPUTATION_REASONS "missie voltooid", "een deadline gemist" | "opdracht afgerond", "een deadline gemist" | they become Frank's or Ruud's words with #17 |

**Kept on purpose:** A3, Check (and Plan, Do, Act), KPI, gemba, dagstart, borgen, standaard, Stuurindicator / Volgindicator, verbeterbudget, Inwerkweek, deadline (Dutch offices say it), herstel, vaste routine, Berichten, Kaart, Opdrachten, Notities, Wie is wie; and "spel" on the title, pause and save screens.

**The change.** Every string in the table, through `tr()`; `BANNED_SPOKEN` stays as it is (the chrome word *missie* is still allowed there by the style guide, but after this list no chrome uses it); a new pytest `tests/test_ui_vocabulary.py` greps `game/src/ui`, `game/src/world` and `game/src/rules/objective.gd` string constants for `[Mm]issie`, `Akte`, `[Ss]core`, `XP`, `\bspel\b` outside the allowed files (`title_menu.gd`, `pause_menu.gd`, `save_list.gd`, `designer*.gd`), so the words do not creep back.
**Size:** M (35 strings, the prop, the test). **Decision:** Merijn sees and approves the list (§7 Q1); rows 24, 26 and 29 carry the design changes.

### 3.2 #5 The top bar: date and time only (M, decided; waits for slice 3.1 Task 9)

**Player problem.** One bar on every world screen reads "VOLTANA · ma 26 okt, 14:00 · Budget € 50.520 · besparing € 231 /week · 240 XP · Witte band · Achteruitgang 20%" (`act.png`, `terugblik.png`). Merijn decided: the date and time only; XP and the belt go to the Ik app; the decline shows in the world and in Ruud's comments.

**What the player sees.** Top left, a small rounded pill like a phone's status line: **"ma 26 okt · 14:00"** (from slice 3.3 the light and the weather say the season; no season word: §6). Top right, the phone as a small icon with a badge when something is unread; "Tab" beside it only until the player has raised the phone once (then F1 or the pause menu shows the keys: audit #11). No full-width navy band: the world gets the top of the screen back. Everything else moves:
- **XP and belt** → the Ik app (slice 3.1 Task 9 has the section; it shows the belt and a bar towards the next, no XP number: §7 Q2) and the certificate at your desk (U4-4). A belt earned arrives as an HR mail in Berichten and Ruud hands it over at your desk the next morning.
- **Budget and savings** → the Voltana app's *Geld* tile (slice 3.1 Task 9), and on the A3 where money matters: under the countermeasure, "Verbeterbudget: € 42.000 vrij". Going into debt: Frank's message (UX-3 #17); the bad period is said by Frank and Ruud, and the Voltana tile shows it.
- **Decline** → the tells, Ruud's `slips` comment (slice 3.1-E), people working late again (3.1-A). No number anywhere.

**The change.** `hud.gd` (labels, the bar's style), `game/src/game/opening.gd` (the reveal table drops `budget` and `xp`), `a3_form.gd` (the budget line), `ui_text.gd` (the belt event becomes a Berichten mail), `messages.gd`, `ik_app.gd` (no XP number). **Tests:** the HUD has the clock and the phone badge only (no budget, XP, belt or decline label exists); the A3 shows the free budget beside the countermeasure; a belt earned lands in Berichten; the opening's reveal table no longer names `budget` or `xp`. **Screenshots:** `office`, `act`, `debt`, `terugblik`, `office_at_2000`.
**Depends on:** slice 3.1 Task 9 (the Ik and Voltana apps). **Decision:** made; §7 Q2–Q4 settle the details.

### 3.3 The audit's other build-now items

| # | Player problem (short) | The change | Size | Files | Decision |
|---|---|---|---|---|---|
| 13 | Talk summary: 15 px quotes over the overhead shot, colliding move names, instrument words, buttons outside the card | Quotes at 19 px (17 on a 1366 screen), curve labels alternate above and below, openness and mood only in Notities, buttons inside the card; with §2.1 the summary holds the over-the-shoulder frame | S | `talk_summary.gd`, `trace_line.gd`, `talk_view.gd` | none |
| 14 | The Check: your prediction fell (orange) under "Check geslaagd", and "Wat zegt de Check?" does not answer it; 12 numbers × 2 tables, the tag repeated per row | First line answers the prediction in words with a person ("Doorzet zakte in de twee weken. Petra: 'Dat is de omschakeling; kijk naar de capaciteit.'"); the leading/lagging tag once per group; the title per row 25 of §3.1. See also U4-8 | M | `check_panel.gd`, `check_forecast.gd` (facts only), `ui_text.gd` | wording with Merijn only if the verdict logic changes |
| 15 | A3: the countermeasure dropdown clipped mid-number; straight quotes | The countermeasure list as rows with the cost on its own line (no `OptionButton`); one Dutch quote style (‘ ’ for quotes inside, “ ” for speech) across UI and content, checked by a pytest | S | `a3_form.gd`, `ui_text.gd`, content pass, `tests/` | none |
| 16 | Phone call: an empty black rectangle over the overhead office | The call in the raised phone frame: the phone in your hand, the world blurred, the caller's name and photo (#24), a call timer counting up (a clock, not a limit) | S–M | `talk_view.gd` (`_phone_screen`), `phone.gd` | none |
| 17 | Notifications in two styles; HUD toasts with key letters and numbers | Every event a phone bubble with a sender and time: Frank for reputation and debt, Petra for "de Check staat klaar", Ruud for a slipping fix, Voltana for a dividend; no key letters, no reputation number; the bubble buzzes the phone (existing sound) | M | `game_ui.gd` (toasts), `hud.gd`, `messages.gd`, `ui_text.gd` (EVENTS, REPUTATION) | §7 Q4 (the number) |
| 19 | Naming inside the phone: Notities vs Aanwijzingen; codex header "Begrippen" on every tab | One name per app on its icon, title and every mention; the codex title follows the tab | S | `notes_app.gd`, `place_menu.gd`, `codex_panel.gd`, `phone.gd` | none |
| 20 | Notities shows a rules readout ("achteruitgang door stilstand: 0%") | Drop the card; once drift starts, one line in your own words at the top ("Sinds de stapel niets meer verbeterd.") | S | `notes_app.gd` / `clue_journal.gd` | none |
| 21 | Kaart: pills overlap and clip; legend cut off; minimap labels 14 px grey | Pills laid out to avoid collisions (nudge, then hide the lesser at this zoom); legend inside the phone; minimap labels ≥ 16 px effective with an outline | S–M | `office_map.gd`, `map_app.gd`, `minimap.gd` | none |
| 23 | Creator hair names in English ("Korte fade", "Textured crop", "Buzzcut") | Dutch: "Kort opgeschoren", "Kort met lok", "Millimeter", "Krullen bovenop" | S | `game/src/ui/creator/` | none |
| 24 | People are 2D cartoon heads while you have a badge photo | Every cast member's badge photo from `PortraitPhoto`, in Wie is wie, the call (#16), the name tag and the lock screen (§2.3 7d) | M | `people_app.gd`, `mood_face.gd` users, `creator` portrait code | none |
| 25 | KPI board: every value red | Ink for values; colour only against a norm, always with an arrow or word (§0.7) | S | `kpi_board_view.gd` | none |
| 26 | Title: "Alles wissen" as heavy as "Nieuw spel" | Into Instellingen, with its confirmation | S | `title_menu.gd`, `settings_app.gd` | none |
| 27 | Explainer: "Klaar" low contrast; help line 16 px light grey on white | Standard button; help line in `MUTED` at 17 px; the page count as a row of dots | S | `game/src/ui/explainer/` | none |
| 12+ | (after UX-1's #12) In the van shot four solid blue bars cover the half of the frame where the people are | Lighter sentence rows: translucent ink, the key chip left, one line each where it fits; the person stays visible behind them | S | `talk_view.gd` | none |

**Order.** #4 first (words used by all the rest), then #5, #17, #14, #13, #19, #20, #15, #16, #24, #21, #25, #12+, #23, #26, #27.

---

## 4. Beyond the audit (UX-4 and later), ranked

Ranked by how much each pulls the player in or teaches the Lean lesson, per day of work. M and L items carry a short beat list.

**U4-1 · The value stream map on the obeya is live (M, build now).** *Problem:* the core lesson ("fix the bottleneck; improving a non-bottleneck brings no gain") is shown only in a table on Petra's screen. Meanwhile the obeya wall shows a hand-drawn value stream map with inventory triangles that are baked into the texture as **12, 9, 47 and 15** (`tools/blender/textures.py`, `obeya()`): numbers that never change and do not match the simulation, so a careful player who reads the wall is misled (the same "correct numbers" breach as audit #6). *Change:* the triangles' numbers (and the C/T line under each step) become live, in marker handwriting, from the simulation's queue per step, rewritten at each dagstart. *Beats:* the player walks past the obeya on Monday and sees 47 under Werkvoorbereiding; after the fix the number drops and the one under Planning rises over the next weeks; nobody says it; Ruud's `reflect` question ("als Werkvoorbereiding nu sneller is, waar gaat het werk dan wachten?") now has a place to look. After a fork taken at the non-bottleneck, the end of the wall does not change. *Files:* `office_tells.gd` or a new `office_obeya.gd` (a `Label3D` per triangle, positions from the texture's layout), `textures.py` (triangles without numbers), the sim's per-step queue (`Network` already keeps the history for the VSM, `network.gd:13`). *Tests:* the wall's numbers equal the sim's queues at the dagstart; the texture carries no digits.

**U4-2 · Every verb lands: feedback and sound (M, build now).** *Problem:* the six verbs (kijken, praten, denken, proberen, meten, borgen) have little felt confirmation; a found clue is a line of text, the A3 going in is a panel closing. *Change, one cue per verb:* a found clue: the pen scratches it into the notitieblok (§2.3 7a) and the phone's Notities badge ticks; a talk's end: the person goes back to work with a small nod or sigh by outcome (existing poses); the A3 handed in: the clipboard's clack and the sheet sliding into the tray at Petra's desk; the Check: the numbers count from before to after on Petra's screen, one row at a time, with a soft tick; borgen: a laminated werkinstructie appears at the team's desk and stays (a new tell, the world shows the standard); a card picked up: the pin. A third audio bus **Interface** in Instellingen beside the room sound (sound categories: Omgeving, Interface). *Files:* `soundscape.gd` (cues and the bus), `game/assets/audio/` with `SOURCES.md` (approved domains only), `place_menu.gd`, `check_panel.gd`, `office_tells.gd`, `a3_form.gd`. *Tests:* each verb's event plays its cue once; the Interface volume applies; the werkinstructie prop appears on Standardise and goes when the fix recurs.

**U4-3 · Time the first hour (S, build now; research).** *Problem:* the first-five-minutes spec measured the opening (about 5½ minutes to the first talk); nobody has measured the rest of the first hour (the training week's Tuesday to Friday): how long a player walks between beats, how often the objective line points to another floor, where nothing happens. *Change:* run the autoplay *careful* persona with real-time pacing estimates (walk distance ÷ `Player.SPEED`, lines at a reading speed of ~15 characters a second, an estimate) over Act 0, and write a beat chart: each beat, its real seconds, the gap before it. Flag every gap over 90 s with no person, choice or new place. *Output:* `docs/qa/first-hour-2026-10.md` and items for this roadmap. *Files:* a tool script `game/tools/pace_chart.gd`.

**U4-4 · Your desk shows who you have become (S–M, build now; after 3.1).** *Problem:* with #5 the belt and XP leave the screen; the player's progress then lives only in an app. *Change:* the desk at Aansluitingen (already with your name plate, badge photo and the El Amrani letter) gains: the belt certificate in a frame on the partition (from the HR mail); the *Aandenkens* objects (the hourglass, §3.1 row 29) on the desk with Ruud's card under each; the name plate's title changes on promotion (slice 3.1-C); El Amrani's reply letter after the winter (exists as a payoff); a photo strip of the colleagues promoted (3.1-D's cake scenes). Hover any object: its card. *Files:* `office_desk.gd`, `discoveries.yaml` (objects exist), `career.yaml`. *Tests:* each object appears with its fact and only then.

**U4-5 · Evidence with a face and a place (S–M, build now).** *Problem:* PLAN §4.3.5 promised "gehoord van Joost" next to "geteld bij Intake" in the A3's evidence; today clues have no source on screen (`a3.png`, `phone_notes.png`). *Change:* every clue carries its source: a small badge photo for something heard (the person, #24), a place stamp for something seen or counted ("geteld · Werkvoorbereiding · di 13 okt"). The A3's evidence list and Notities show it; Ruud's `heard` sentence (§2.2) uses it. *Files:* `clue.gd` (source already known where the clue is found: talk, place, tool), `a3_form.gd`, `clue_journal.gd`. *Tests:* a clue found in a talk shows the person; one found with a tool shows the place and date.

**U4-6 · Text size and the laptop screen (M, build now).** *Problem:* the 1600×900 canvas stretches; on a 1366×768 laptop `UiTheme.SMALL` (17) shows as 14.5 px, the talk's key hints (11) as 9 px, the minimap's 12 as 10 px. Sixteen font sizes are literals outside `UiTheme`. *Change:* (1) every size from a `UiTheme` token (BODY, SMALL, CAPTION, HEADING, SUBTITLE), no literal below CAPTION; (2) a **Tekstgrootte** setting in Instellingen (Normaal · Groot · Extra groot: ×1.0, ×1.15, ×1.3) that scales the tokens; (3) a floor per token in screen pixels, so CAPTION never shows below 13 px at 1366×768 (§0.6); (4) subtitles at most two lines of about 42 characters (the line length streaming subtitle guides use; an estimate for a game screen), the line box widening before it grows a third line. *Files:* `ui_theme.gd`, every `add_theme_font_size_override` with a literal, `settings_app.gd`. *Tests:* no literal font size under `game/src/ui` and `game/src/world` (a pytest grep); the setting scales the theme; screenshots at `--resolution 1366x768` for `talk_choose`, `phone_notes`, `check`, `a3`.

**U4-7 · Colour is never alone (S–M, build now).** *Problem:* better and worse are green and red in the Check's "Na" column, the KPI board, the trust flash and (planned) the Voltana tiles; about 8 % of men have red-green colour vision deficiency (an often-cited estimate for men of northern European descent). *Change:* every meaning-bearing colour gets a shape or word (▲/▼, "beter", "slechter"); better/worse use blue and orange, not green and red, where the palette allows (`Palette` already has `SAFETY_ORANGE`); a palette check in tests (each pair of meaning colours differs in lightness by a set margin, an estimate). *Files:* `palette.gd`, `check_panel.gd`, `kpi_board_view.gd`, `talk_view.gd`, slice 3.1's `company_app.gd`. *Tests:* the Check rows carry an arrow; the palette pairs pass the lightness check.

**U4-8 · The Check as Petra's talk, the forecast as a picture (M, build now; extends #14).** *Problem:* the Check is 12 numbers in two tables (`act.png`); it reads like a spreadsheet, which is exactly what the charter asks to avoid. *Beats:* the player walks to Meetdata; Petra turns from her screen and says the headline in one line, in her dry voice, reading the prediction (a face shot); the camera moves to her screen; the screen shows **one chart**: the predicted KPI over the coming months, two lines ("met jouw maatregel", "zonder"), the gap shaded; the other KPIs as small multiples under it; the full table one click away ("Alle cijfers"). Then Act as today. *Files:* `check_panel.gd`, `monitor_screen.gd`, `office_check_screen.gd`, a short line set for Petra in `dialogs.yaml` (spoken, validated). *Tests:* the chart's two series equal `CheckForecast`'s runs; Petra's line names the predicted KPI.

**U4-9 · Walk there from the Kaart (M, build now).** *Problem:* three floors and a yard; finding Petra or Ruud means walking with the minimap; respecting the player's time without teleporting (immersion). *Change:* in the Kaart app, tap a place or a person: **"Loop erheen"**; the phone lowers and the character walks the path at run speed (stairs and lift included), any key or click takes back control. People on the way still greet. *Files:* `map_app.gd`, `player.gd` (a path follow over `office_nav.gd`), `office_floors.gd`. *Tests:* the path reaches the place across floors; any input cancels.

**U4-10 · Keys you can change, and every key has a click (M, build now).** *Problem:* only the phone key is remappable (`phone.gd:288`); Z/C to turn, E to use, 1–4 in talks and Shift to run are fixed; some actions have no click (the HUD's phone label, the prompt pill). *Change:* a **Toetsen** page in Instellingen (rebind each action, reset to default; saved in the settings file); every key action has a click target (the phone icon, the prompt pill, the talk's sentences already do). Controller support is out of scope until the web export. *Files:* `settings_app.gd`, `Settings`, `hud.gd`, the input handling in `player.gd` and `camera_rig.gd` moved to named actions. *Tests:* a rebound key works and survives a restart; the prompt pill and phone icon respond to clicks.

**U4-11 · The act's reflection on Ruud's whiteboard (M, build now when the act-end terugblik is built).** *Problem:* PLAN §4.2.6 plans Ruud's act-end terugblik with a free-text "what did you learn", kept in the journal and never judged; as a text field in a panel it would be a form. *Beats:* the last day of the act, Ruud asks you into his room; the whiteboard still has the three words from your first day; he hands you a marker: "Schrijf eens op wat je dit jaar geleerd hebt. Voor jezelf."; you type, and the words appear on the whiteboard in handwriting as you type; he reads it, says one line (a question, never a grade); the board keeps your sentence in the world until the next act. The text is saved to Notities. *Files:* `office_whiteboard.gd`, a `SceneLines` scene, `notes_app.gd`.

**U4-12 · Other screen shapes (S–M, build now; research then fixes).** *Problem:* the stretch mode is `canvas_items` with `aspect = expand`; nobody has looked at 16:10 laptops, 21:9 monitors or the 1366×768 laptop. *Change:* a screenshot pass of ten states at 1366×768, 1440×900, 2560×1080; fix what clips (docked panels, the phone's position, the talk's sentence width). *Output:* fixes plus a line in this roadmap.

**U4-13 · The A3's causes grow from your evidence (L, needs Merijn).** *Problem:* "Wat is de oorzaak?" offers five causes as a radio list (`Investigation.cause_options`: the real one plus four from other problems), so a player can pick by elimination, which weakens "nothing is handed over" and "no multiple choice with one marked correct". *Change:* the cause list starts empty ("Nog geen oorzaak: wat heb je gezien?"); each clue found or heard adds the cause it supports (red herrings add theirs), so the list is the player's own evidence and a player who did not look has nothing to pick. *Decision:* §7 Q6 (it changes difficulty and the A3's rule).

---

## 5. Where this touches the slices

- **Slice 3.1-E (Ruud comments):** §2.2 B1.1 opens the coach talk with the due comment through the same `Coach.comment_due` / `comment_said`; whichever lands first leaves a hook for the other. The comment's "never a number" rule stays.
- **Slice 3.1 Task 9 (Ik and Voltana apps):** #5 needs them; the Ik app shows no XP number (§7 Q2) and the Voltana tiles follow U4-7 (colour never alone). Its line "No HUD change" is superseded by Merijn's #5.
- **Slice 3.3 (`waiting_list` on the HUD, the season word on the date line):** conflicts with #5's "date and time only". §7 Q3 asks; the recommendation keeps the bar clean.
- **Slice 3.3 (`ruud_farewell`, monthly phone call):** the coach talk runs in the PHONE setting with the 28-day cooldown (§2.2 *Later, by phone*).
- **Slice 3.2 (the street):** the talk camera (§2.1) must hold outdoors (no ceiling, open sight lines); the street's first talk (Gert at the trench) is in the screenshot set.
- **Slice 3.1-H (talk rewrite after the playtest):** the coach talk's lines (§2.2 *Content*) join the same writer-and-reviewer pass.

---

## 6. The UX lead's calls (overrule any)

1. Talk shot changes are **cuts**, not glides (only the first framing glides in): film grammar, and the 1.5 m to 2.8 m change is too small to swoop without looking like a wobble. The playtest checklist asks.
2. Ruud's talk shows **no trust pips** and moves no trust: the coach is not a meter, and the player should not court him.
3. **Three exchanges** per coach talk, then the Kata's fifth question closes it (Rother's coaching cycle is short by design; an estimate).
4. The **Kata-kaart** in Notities shows the player's own answers; it is the learner's storyboard, never graded.
5. The empty coach room shows a **sticky note on the door** in Ruud's words, not a toast.
6. Intussen becomes the phone's **Agenda** and the terugblik its **lock screen**, rather than paper props: Merijn's "the phone is the hub" decides it.
7. The board's columns are **Open · Mee bezig · Klaar**, a kanban, so the board teaches visual management by being one.
8. The date line shows **no season word** once seasons exist; the light, the weather and the calendar's events show it (consistent with #5).
9. Generic word for a mission is **opdracht** (the phone app and the objective line already say it), with *hoofdopdracht* and *erbij* as the card tags.

---

## 7. Questions for Merijn

Only what is truly his: taste, scope and his design rules. Each has a recommendation.

1. **The company word list (§3.1).** Do you approve the 35 rows as written, in particular *Verbeterbord*, *opdracht* / *hoofdopdracht* / *erbij*, *Oppakken*, the columns *Open · Mee bezig · Klaar*, chapters without "Akte", the score replaced by "Ruud over je A3" (margin notes, no number), and discoveries as *Aandenkens* with titles as *bijnamen*? **Recommendation: yes, as listed**, so UX-2's board and UX-3 change the words in one pass.
2. **Belts: which words, and where.** Today "Witte band … Zwarte band" reads like judo. Dutch companies with a Lean programme say *Yellow Belt*, *Green Belt*, *Black Belt* in English. **Recommendation:** the English belt names as Dutch companies use them, shown as a certificate at your desk and in the Ik app with a bar to the next belt, and **no XP number anywhere** (XP stays internal).
3. **The waiting list on screen.** The *Drie winters* arc puts the north-star KPI `waiting_list` "on the HUD from Act II" (slice 3.3: from the ACM visit); your #5 decision keeps the bar to date and time. **Recommendation:** not on the bar: a wall screen at the ontvangst and the obeya ("Wachtlijst Zuidmark: {n} aansluitingen · gemiddeld {w} weken", live from the simulation), the first tile of the Voltana app, and Frank saying it at the monthly figures.
4. **The reputation number.** Audit #17 asks whether toasts may still show "Reputatie bij het MT −5". **Recommendation:** no number in any message (Frank says it in words); the Voltana app's *Imago & vertrouwen* tile keeps its number, as a company report would.
5. **How often Ruud coaches.** Today the coach answers every press. **Recommendation:** one Kata cycle a day in person (a second visit the same day with nothing new: "Wat heb je sindsdien gezien?"), never blocking anything; from winter 2 the monthly call as already planned. It makes his attention worth something and stops hint-farming, and it fits "respect for people" (his time too).
6. **The A3's causes from evidence (U4-13).** Make the cause list grow only from clues found or heard, so it can no longer be picked by elimination? It makes the A3 harder and truer to "nothing is handed over". **Recommendation:** yes, but as an experiment on one Act I mission after Friday's playtest, judged by the route check and one human play.
