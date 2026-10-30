# Phase 2 design and plan, first draft (Fable with Merijn, 2026-10-21)

Approved by Merijn on 2026-10-21 (plan mode, four sections and the slices each approved). PLAN.md §1 and §3 point here; the slice-1 tasks are PLAN 2.14. Follows 2.13 (built and green on `46f6dbf`).

## Context

Merijn played the first five minutes (2026-10-19), and 2.13 repaired what he found: scenes that pause and wait for his key, talks as four sentences, one objective line, a friendly first week, natural Dutch. He has not yet replayed, so his feedback on the talks is still to come. He asked for a longer planning session with Fable for **all of Phase 2 as a first draft**, with more focus on **world building** (all four meanings: a living place, a believable company, more places, the player in it), the mission system continuing, and the research into how popular RPGs stage conversations taken as reference points, not templates ("our game obviously differs").

**What the exploration found (2026-10-21):**
- **The world stands still.** Three floors and the yard exist (`content/world.yaml`, `tools/blender/build_office.py`, `build_yard.py`), but nothing changes with the clock except the vans (`office_yard.gd`). People appear at lunch instead of walking there (`office_people.gd:105-113`), one person walks (Marco), nobody turns to the player, there is no arriving or leaving, no evening light (`office.gd:869-884`, one fixed sun), no audio at all (0 streams under `game/`), and the stacks and trays are baked into the glbs, so the world never shows the queue (PLAN 2.6 not started). Yvonne is a stand-in model; name tags do not appear when Ruud names people; the opening's evening lamp is not built.
- **The mission code is ahead of the content.** 27 missions (Act 0: 5 training, Act I: 6 main + 8 side, Act II: 6 main + 2 side). No `milestone` kind, no `opens_on`/seasons, no `talk_to` goals in content (talks hang on missions by `mission:`), one fork, `too_early` debrief unsupported, `steps:` only on 6 missions. Missing from the catalogue (`2026-10-15-mission-system-and-catalogue-design.md` §3): Act I `review_100_days`, `winter_el_amrani`, `talk_netplanner`, `lsw_gemba_round`; Act II `first_kpi_review`, `sector_congestion_map`, `lsw_van_round`, `stagnation_alarm`. `GameSession.kpi_review` exists, no screen calls it. QA findings 2.12 (a)–(e) open.
- **The talk engine is richer than its screen.** `dialog.gd`: hidden layers (position → interest → concern), a ceiling until the concern is earned, 17 moves judged by the person's last line's tags, nine archetypes, five hidden needs, memory between talks (`people.gd:25-26`), wear-out, `offer()` with four sentences. Shapes built: persuade, checkin; `expert` named but unused; customer calls are persuade talks through the KCC place menu; no phone. On screen: a bottom panel with Openheid bar, band, trust pips, Stemming, the Standpunt/Belang/Zorg tracker, a 2D stand-in `MoodFace`; the NPC has no face, gesture, look-at or turn; the summary card still names moves. The camera: `CameraRig.converse` over the shoulder, `two_shot` for scenes.

**Research (web search extracts only; no page opened outside the approved list):**
- *The Witcher 3* (GDC 2016, Tomsinski): two modes. "Consumer" while they speak (voiced, generated shot/reverse-shot camera, gestures; 2.5 h of 35 h are cutscenes, ~1,460 talks use the generated camera; "a close-up gesture builds more connection than a line"). "Producer" when you choose: time stops, camera pulls back, the person idles, their last line stays on screen. Options are short; story-moving ones marked and listed first. Consequences late and unmarked. Objective: one line + a marker.
- *GTA V*: no choices; talk happens while you do something (driving, walking, phone); directed cutscenes at mission starts; ambient chatter.
- *RDR2* (OXM 2018 via TweakTown): contextual interaction (greet/ask/antagonize) depending on who and the situation; memory was the origin; 1,000 NPCs with mood state.
- *Cyberpunk 2077*: real time, three or four options, you keep moving, the person comments on what you look at. *Baldur's Gate 3* (CGM): "a conversation is a fork in the road, not flavour text"; mercy in hour one echoes in hour forty.
- Sources: [howtomakeanrpg on Witcher 3 conversations](https://howtomakeanrpg.com/r/a/witcher-three-conversation.html), [GDC Vault: Behind the Scenes of Cinematic Dialogues in The Witcher 3](https://www.gdcvault.com/play/1022988/The-Witcher-3-Wild-Hunt), [TweakTown on the dialogue generator](https://www.tweaktown.com/news/51166/cdpr-reveals-science-behind-witcher-3s-dialogue-animations/index.html), [Prima: Witcher 3 dialogues](https://primagames.com/eguides/the-witcher-3-wild-hunt-eguide/getting-started/witcher-training/dialogues), [TweakTown: RDR2 NPC system](https://www.tweaktown.com/news/63303/red-dead-redemption-2-npc-system-explained-rockstar-devs/index.html), [SegmentNext: RDR2 interaction system](https://segmentnext.com/2018/08/30/red-dead-redemption-2-interaction-system/), [TweakTown: Cyberpunk first person](https://www.tweaktown.com/news/66427/cyberpunk-2077-work-third-person-cdpr/index.html), [CGM: BG3 dialogue](https://www.cgmagonline.com/articles/baldurs-gate-3-redefined-crpg-dialogue/), [Vulkk: Witcher 3 quest designers Q&A](https://vulkk.com/2016/05/07/witcher-3-qa-cdprs-quest-designers/), [GameSpot: Witcher 3 open world](https://www.gamespot.com/articles/cd-projekt-red-explains-why-the-witcher-3s-open-wo/1100-6477549/).

**Merijn's decisions in this session (2026-10-21), to record in PLAN §9:**
1. Scope: all of Phase 2, a first draft; world building in all four senses; the mission system continues; talk feedback comes after his playtest of 2.13.
2. **The phone is the hub** for everything that is now a panel (Berichten, Kaart, Opdrachten, Notities, Wie is wie, Instellingen). The A3 stays at the desk, the Check at Petra's screen or the obeya.
3. **Three playable slices**, each ending with his playtest: "Een week bij Voltana", "De eerste winter", "Honderd dagen".
4. Talks: the face and body replace the instruments; **trust stays visible, small** (the five pips by the name); the ▲/▼ arrow stays; openness, mood and the layer tracker leave the talk screen.
5. Act II trimmed to its six mains plus the KPI review and the day-100 scene; `sector_congestion_map`, `lsw_van_round`, `stagnation_alarm` wait for Phase 3.
6. The reference games are examples of what a real game feels like, never a template.

---

## Design

### 1. The world

**1.1 The office keeps time.** Every cast member gets a `day:` in `game/assets/characters/cast.json` (`arrive`, `coffee`, `lunch`, `leave`, optional `late_until`), with per-person defaults (in 08:00–08:45, coffee ~10:00 for 10 min, lunch 12:00–13:00 at the kantine, out 17:00–17:30). `OfficePeople` (`game/src/world/office/office_people.gd`) resolves where each person is at `session.minute_of_day` and **walks** them there over the floor's navmesh (`office_nav.gd`) instead of teleporting; between waypoints they use the walk clip. Who stays late is a tell driven by the simulation: a person whose team's load is above the norm (`People` morale/needs, `session.energy_of`) has `late_until` 18:30. The opening's evening (B6) uses the same path with `leave` forced for everyone but Anouk.

**1.2 Light follows the clock.** `Office._add_light` becomes `OfficeDaylight` (`game/src/world/office/office_daylight.gd`): sun rotation, colour temperature and environment ambient per hour band (07–09 low warm, 09–16 neutral, 16–18 low warm, after 18 dark with desk lamps as emissive spots at occupied desks; the opening's "one lamp at Werkvoorbereiding" is this rule with only Anouk present). Lightmaps stay baked for the day; the evening is a second baked set or a runtime dim (spike decides; the dim is the fallback). Seasons wait for Phase 3.

**1.3 A thin sound layer (pulled forward from Phase 6).** `game/src/audio/soundscape.gd`: an office bed (keys, murmur, a far phone) that follows occupancy (louder at 10:00, near silent at 18:30), footsteps on the player's walk cycle, doors, the lift, the phone buzz, the camera shutter in the creator, the van engines in the yard. CC0 assets from `opengameart.org` or `itch.io` only (approved list); every file listed with its licence in `game/assets/audio/SOURCES.md`. Master volume and "Geluid uit" in Instellingen; default low. No music.

**1.4 People react.** `OfficePerson` gets `face_toward(player)` (within 2 m, a head/torso turn, back to work after), a daily greeting by name in the person's voice (`greetings:` in `dialogs.yaml` per person, 3 variants, reading the facts: yesterday's outcome, a kept promise, a pressured talk), a **quick exchange** on E when there is nothing to discuss (one line about today that reads morale and load; no panel; replaces the "nothing to say" toast), and pair chatter at the coffee corner (two people, a two-line snippet shown as subtitles when the player is within 4 m, `chatter:` in `dialogs.yaml` with department and load conditions). Posture carries mood: new or re-used clips (Animation Library 2: folded arms, phone call, nodding, carrying, slumped sit) replace the 2D `MoodFace`. The energy bar becomes rare (≤ 2 prompts a week, as §4.3.4).

**1.5 The world shows the work (PLAN 2.6).** Props that read the simulation: `game/src/world/office/office_tells.gd` binds named prop groups in the floor glbs (`tell:intake_stack`, `tell:prep_tray`, `tell:planning_board`, `tell:van_bay_n`) to region numbers (queue length in bands of three heights, planning churn as red cards, a van that stayed). `build_office.py` exports the three heights as separate meshes under one named node; the runtime shows one. One ambiguous tell per active tier-1 problem, listed in `content/problems_tier1.yaml` under `tells:` and validated (every active problem has ≥ 1 tell; a tell never names the problem).

**1.6 A believable company.** `content/company.yaml`: Voltana (regio Zuidmark): departments and teams, team leads and reporting lines, headcount by team, the 2012 programme and what became of it, the waiting list and congestion numbers with sources (`netbeheernederland.nl`, `acm.nl`, `cbs.nl`), the sites (hoofdgebouw Nova, werf, Lindeveld, Havenzij). It feeds name tags (name + role from one source), the *Wie is wie* app (org chart, who you have spoken to and what they told you: the Mensen tab moves here), briefings and the company page of the codex. Tests: every cast member has a department and a manager; every manager is in the cast or named; no two sources disagree on a title; numbers carry a source or `estimate:`.

**1.7 Places, by slice.** Slice 1: the 1e and begane grond alive (1.1–1.5), the ontvangst and kantine with people and schedules, Yvonne's own look. Slice 2: the yard with the **van ride** (a scene type: you sit beside Dirk or Henk, the window shows a short canned drive-by loop, the talk runs as a walking-mode talk; used by `fix_wrong_joint`, `fix_not_at_home`, `henk_camera`); the KCC with headsets and the customer call (2.4); the opleidingsterrein as a small fenced area off the yard with Henk's trench and meterkast (2.3). Slice 3: the 2e alive (directie, netstrategie, congestiedesk, MT room). The town stays Phase 4.

**1.8 You.** The **phone as hub** (`game/src/ui/phone/`): one key (Tab, remappable) raises the phone in your character's hand, the world blurs; apps: *Berichten* (Ruud's notes and move cards, El Amrani's calls, the week-end message; a buzz and a badge on arrival), *Kaart* (the M map and the floor switch), *Opdrachten* (the active main, the sides, the board's available list; accepting still happens at the board), *Notities* (the journal: clues, observations, talk summaries with the move trace and Ruud's naming), *Wie is wie* (1.6), *Instellingen*. J, M, K open the phone on that app, so the old keys keep working. Your desk at Aansluitingen holds your A3 (opened there or from anywhere as "your clipboard", PLAN 2.10), a name plate with your name, the badge photo and the El Amrani letter. The HUD keeps only the top bar and the objective line.

### 2. The talks

**2.1 Watch, then choose.** `DialogPanel` is replaced by `TalkView` (`game/src/ui/talk_view.gd`) with two modes. *They speak:* `CameraRig.face_shot(person)` (a medium shot of their face and shoulders, from a side that sees the face; falls back to `converse` in corridors), posture and gaze carry the state, the line types out and waits for the key (the `SceneLines` input: first press completes, second advances, ← re-reads). *You choose:* the camera returns to the two-shot, their last line stays as a subtitle, the four sentences appear above it as a short list (keys 1–4, Esc "Afronden"). Time stands still in both. No bottom panel.

**2.2 The face replaces the instruments; trust stays small.** On screen during a talk: the name and role, **the five trust pips** (small, by the name, flashing ▲/▼ on change), the ▲/▼ arrow after your line, and nothing else. Openness is posture and gaze: five band poses (Dicht: half turned away, arms folded · Op z'n hoede: facing, closed · Luistert: facing, open · Open: nod on a landing move · Denkt mee: leaning in); the band change triggers the pose change with a short blend. Mood is in the idle clip (tired: slower, a hand to the neck). The cue "Er zit meer achter…" becomes a visible hesitation (a pause, a look away) plus the line's ellipsis. The layer tracker, Openheid bar, band name and Stemming go to the talk summary in *Notities*; the summary's trace keeps the move names there (named afterwards, never during).

**2.3 Talk where the work is.** Three settings: *standing* (at their desk; the person stands up or swivels to you), *walking* (Ruud's walk, a shadow day: you move between lines, the camera a following two-shot), *the van* (slice 2). A *phone call* is a talk with the phone raised and no face: the subtitles and the voice lines carry it, so those lines get the most writing care.

**2.4 Memory out loud.** Every talk's first line reads the facts (`Facts`): last outcome, a pressured or ruined talk ("Vorige keer liep het niet lekker."), a kept or broken promise, a standardised fix. Greetings and quick exchanges (1.4) use the same facts.

**2.5 Shapes in Phase 2.** Persuasion and check-in as they are. The **customer call** (El Amrani, Ilse): started from the headset at the KCC or from an incoming call on the phone; a `promise` the simulation checks (exists in yaml, gets its UI and its `story_order` check in slice 2). The **expert talk** for Wim and Henk: `kind: expert`, topic by topic, no meters, each topic a clue or an explainer. Coaching kata and group talks wait for tier 2.

**2.6 Writing.** The style guide (`2026-10-19-dutch-style-guide.md`) rules all 38 talks; Act 0 is done (2.13 E). The writer-and-reviewer pair rewrites Act I in slice 2 and Act II in slice 3, after Merijn's feedback on the Act 0 sample and his slice-1 playtest. Content tests enforce §4.3.1: no outcome opener in more than a third of a tier's talks, ≥ a third of concerns revealed by a feeling, interest `via` varies by archetype, per-person "never says" words.

**2.7 The feedback gate.** Slice 1 ends with Merijn playing the week. His notes on the talks (staging, instruments, writing, pacing) are collected with the playtest checklist §3 and decide 2.1–2.2's details before the Act I rewrite starts.

### 3. Missions and the campaign

**3.1 Schema.** `mission_def.gd` gets `kind: milestone` (no slot, plays as a scene: `scene:` names a `SceneLines` script in `content/scenes.yaml`), `opens_on: {day: N}` and `opens_on: {date: "2026-12-01"}` (seasons wait), `deadline_on_day`, `sets_flags_on_fail`, and `talk_to` goals used in content (every talk that a mission needs becomes a goal, so the objective line can say "Praat met Joost"). `DEBRIEF_VARIANTS` gets `too_early` and the two designed-failure debriefs are written (`2026-10-16-designed-failed-checks.md`). `steps:` becomes required on every main mission (validator), so the objective is authored.

**3.2 Act I is the first winter.** New: `talk_netplanner` (side), `lsw_gemba_round` (side), `review_100_days` (milestone, the MT room, reads the facts: which fixes hold, who committed), **`winter_el_amrani`** (milestone): the followed order (`followed_order.gd`) must be delivered before the first frost (`opens_on: {date}` for the frost beat, a KNMI-sourced date range as an estimate); the date you promised Mrs El Amrani on the phone (`promise` in `el_amrani_fourth_call`) is what the simulation checks (`story_order {story, by, met_if}` from the arc's S12). Kept: a scene at the El Amrani front door is Phase 4; in Phase 2 the payoff is her call and the letter's reply on your desk. Missed: a door closes (her complaint to the ACM goes into Act III's visit), the problem stays solvable.

**3.3 Act II, trimmed.** The six mains with authored `steps:`; `first_kpi_review` calls the existing `GameSession.kpi_review` from a screen at the directie obeya; the KPI board's birth and day 100 are scenes. Order: the spec's (revision before digging damage) if the draft-check passes on the real network; else content's. `sector_congestion_map`, `lsw_van_round`, `stagnation_alarm`: Phase 3.

**3.4 Face, number, choice: tested.** `tests/test_mission_shape.py`: every tier-1 main mission names a person met before any KPI (a `talk_to` or scripted talk precedes the first `dig`), states a measurable claim in its briefing (a number with a unit), and lists ≥ 1 countermeasure tagged `shortcut: true` with a later cost (`path_dependence` or `sustain` penalty). Failures block the slice.

**3.5 QA findings close.** (a) a `terugval_` check-in for your own slipped fix pays 25 XP, holding it (an audit or routine that prevents the slip) pays the 100; (b) morale drifts daily with team load above norm, ignored check-ins and fixes won by pressure, so `never-talks` loses people; (c) the debt floor gets a way back: a cost-saving side chain (`fix_double_visits`, `fix_overtime_planning`) that opens at the floor; (d) `marco_day_100` and `petra_after` end after their arc beat; (e) Femke's and Ilse's talks get a listening route (route check proves it).

**3.6 The coach.** Ruud's questions read the main mission's numbers (templates over `region` KPIs), the Kata five come in order during an experiment, the after-talk question after a hard main-mission talk; main quest only; questions, rarely answers.

**3.7 Rewards name the principle.** The debrief says which of the three principles paid or cost (long term, respect, always improve), in one sentence from the facts. No new currencies.

### 4. Slices, playtests, the gate

| Slice | Content | Ends with |
|---|---|---|
| **1 · Een week bij Voltana** | 1.1–1.6 on the 1e and begane grond, Yvonne, 1.8 the phone, 2.1–2.4 talk staging, `steps:` on every Act I mission, 3.1 the `talk_to` goals in Act 0–I content, QA (a) and (b), the 2.13 follow-ups | Merijn plays the opening, the week and `walk_connections` → `fix_custom_design`; reviews the Dutch sample; gives talk feedback (2.7) |
| **2 · De eerste winter** | 3.1 the rest of the schema, 3.2 Act I complete, 1.7 the yard, van ride, KCC and customer call, opleidingsterrein, 2.5 shapes, 2.6 Act I rewrite, 3.4 the shape test, QA (c)–(e), 3.6 | Merijn plays Act I to the first frost |
| **3 · Honderd dagen** | 1.7 the 2e, 3.3 Act II, 1.6 company file complete, 2.6 Act II rewrite, 3.7 | The Phase 2 gate: autoplay on full tier 1 (five personas), the route check, code review of the Phase 2 diff, Merijn's full playtest, a tuning backlog |

**Standing rules:** one commit at a time through the gate (`scratchpad/gate`, `g.sh`); every brief repeats the network rule; the style guide and `BANNED_SPOKEN` on every line; a new HUD element only with its first-needed moment; nothing in a panel that could be in the world or on the phone; mission and dialog agents run continuously and I say when they stop; no night work, no scheduled wake-ups; unlanded work as a patch under `docs/handoff/`.

**Out of scope:** the town (Phase 4), the launcher 2.11 (the CI artifact `Spanning-windows-playtest` stays the build), group talks and coaching kata, seasons and weather, English, Claude's voice, music.

**Claude's calls (overrule any):** sound at a low default with an off switch; the van ride's drive-by is a canned loop; the opening's one lamp comes with 1.2; Yvonne's look in slice 1; Tab raises the phone; the Mensen tab moves into *Wie is wie*; the evening dim is a runtime dim unless the spike shows a second lightmap set is cheap.

---

## Implementation plan: slice 1 in detail

Agents in worktrees, each brief with the common rules file (`scratchpad/brief_common.md`, updated for this slice) and the network rule; TDD per task; `simplify` before each final commit; the coordinator gates and pushes each commit as it arrives. Each task names its files, its tests and its screenshot.

### S1-A · The office keeps time (world agent)
- `cast.json`: `day:` per person with defaults in `office_people.gd`; `OfficePeople.place_for(person, minute)`; walking between spots over `office_nav.gd`; arriving from the lift, leaving to the lift; `late_until` from load (`session.energy_of` / `People`).
- `office_daylight.gd` replaces `Office._add_light`; hour bands; desk lamps as spots at occupied desks; the opening's B6 uses it (remove the comment-only "one lamp").
- Spike first (½ day): runtime dim vs. a second lightmap set for the evening; pick by look and frame time (`play_shot.gd` timelapse state).
- Tests (`test_office_day.gd`): a person is at the lift at 08:05 and at the desk at 08:45; lunch is walked (position changes over several refreshes), not teleported; at 18:30 only `late_until` people remain; the daylight band changes with the clock; the opening's evening has one lit desk.
- Screenshots: `play_day_0830.png`, `play_day_1230.png`, `play_day_1830.png`.

### S1-B · Sound (world agent, after S1-A)
- Assets: office bed, footsteps (carpet, tile), door, lift, phone buzz, shutter, van engine; CC0 from `opengameart.org`/`itch.io` only, listed in `game/assets/audio/SOURCES.md` with URL and licence; the agent stops and reports if a download redirects to another host.
- `game/src/audio/soundscape.gd` (autoload): bed volume from occupancy and hour; one-shots from signals (`player.step`, door open, lift, `phone.buzz`, creator shutter); settings `[audio] master`, `[audio] muted`.
- Tests (`test_soundscape.gd`): the bed volume at 10:00 > at 18:30; muted plays nothing; every referenced file exists and is in SOURCES.md.

### S1-C · People react (world + dialog agent)
- `office_person.gd`: `face_toward`, greeting bubble (a `Label3D` subtitle for 3 s), quick exchange on E (`GameSession.quick_line(person)` reads facts and morale; `greetings:`/`quick:` in `dialogs.yaml`, validated: 3 variants per person, banned words checked), pair chatter at the coffee corner (`chatter:` with conditions), posture clips (Animation Library 2 via `tools/blender/`), `MoodFace` removed from the talk screen.
- Tests (`test_office_react.gd`): within 2 m the person's yaw turns to the player and back; one greeting per person per day; the quick exchange needs no mission and shows no panel; chatter only when two are at the corner; a ruined talk yesterday changes today's greeting.

### S1-D · The world shows the work (world agent + rules)
- `build_office.py`: tell nodes with three variants for `intake_stack`, `prep_tray`, `planning_board` on the 1e; rebuild `office.glb`, lightmaps.
- `office_tells.gd`: bands from region numbers (queue length of `connections.intake`, `work_prep` load, planning churn); `problems_tier1.yaml` `tells:`; validator: every active tier-1 problem on the 1e has ≥ 1 tell, no tell text names a problem.
- Tests: a long queue shows the tall stack; a fixed problem returns to the low stack within the sustain window; the tell list validates.
- Screenshot: `play_tell_intake_high.png` / `_low.png`.

### S1-E · The company file (design agent)
- `content/company.yaml` as in 1.6, sources on every number (approved domains only; search extracts otherwise, marked `estimate:`); `build_content.py` validation; name tags and briefings read titles from it; `tests/test_company_content.py`.

### S1-F · The phone (UI agent)
- `game/src/ui/phone/phone.gd` + apps `messages.gd`, `map_app.gd` (wraps `OfficeMap`), `missions_app.gd`, `notes_app.gd` (wraps `ClueJournal`), `people_app.gd` (the Mensen tab + org chart from `company.yaml`), `settings_app.gd` (existing settings + audio). Tab raises it; J/M/K deep-link; Esc lowers it; the world blurs and pauses input; notifications buzz (S1-B) and badge; Ruud's notes (`session_layer.carded`) and the week-end message arrive in *Berichten*; the HUD loses everything but the top bar and the objective line; the `Opening.hud` reveal table maps the old elements to the phone's apps (the phone itself appears at B6 where it already does).
- Tests (`test_phone.gd`): each app opens by key and by tap; a new note badges *Berichten*; nothing is reachable by the old panels; the opening reveals the phone at B6 and not before; `tr()` on every string.
- Screenshots: `play_phone_home.png`, `play_phone_messages.png`, `play_phone_map.png`.

### S1-G · Talk staging (UI + world agent)
- `CameraRig.face_shot(person)`; `TalkView` replacing `DialogPanel` (same `session` API: `start`, `say`, `offer`, `finish`); two modes with the `SceneLines` input; the five band poses on `OfficePerson` (`pose_for_band`), the hesitation on the cue; trust pips small by the name; ▲/▼ after the line; the summary (trace with move names, layers, Ruud's naming) written to *Notities* and shown once as the talk's last screen; walking-mode talk for Ruud's walk and the shadow day; the phone-call mode (no face, phone raised) for El Amrani and Ilse.
- Tests (`test_talk_view.gd`, extend `test_dialog_ui.gd`): no openness number, band name, Stemming or layer tracker on screen mid-talk; trust pips present; the person's pose changes with the band; the camera is in `face_shot` while they speak and `two_shot` while you choose; the summary lands in the journal; the route check and autoplay unchanged (they use the engine, not the view).
- Screenshots: `play_talk_face.png`, `play_talk_choose.png`, `play_talk_phone.png`.

### S1-H · Missions: authored steps and talk goals (design agent + rules)
- `steps:` on all 14 Act I missions (validator makes it required for `main`); `talk_to` goals in Act 0–I content for every talk a mission needs (`mission_def.gd` already parses them); the objective line reads them; QA (a) and (b) in `missions.gd` / `people.gd` with autoplay numbers before and after (`docs/qa/autoplay-report.md` regenerated).
- Tests: every Act I mission has an objective at every state; `talk_to` goals complete through a real talk; the never-talks persona ends below the talker in XP and loses at least one person's morale below 40 by day 100.

### S1-I · 2.13 follow-ups (small, any agent)
- The glossary card to *Notities*; the summary hints to the journal; the dialog spec in `docs/` updated for four sentences; Anouk's "drie dagen" vs. Friday (timeline fix in content and `test_office_scene.gd`); settings helper (`game/src/save/settings.gd`) used by minimap, session log, scene lines, audio; the notes toast on Monday; the buzzcut specks (art); Yvonne's look (art; `cast.json`).

### Slice 1 exit
- Full gate green; CI green; `Spanning-windows-playtest` artifact; Merijn's playtest with the checklist (`docs/qa/playtest-checklist-act0-1.md`, §1–3 and §5 updated for the phone and the staged talks) and the Dutch sample; his talk feedback recorded in PLAN §9; the slice-2 plan written from it.

## Slices 2 and 3 at task level
- **S2:** schema (milestone, `opens_on`, `deadline_on_day`, `too_early`), `review_100_days` scene, `winter_el_amrani` + `story_order` + the promise UI, `talk_netplanner`, `lsw_gemba_round`; the yard's van ride scene type and the three sides on it; the KCC headsets and the customer call; the opleidingsterrein; `kind: expert` for Wim and Henk; the Act I talk rewrite (writer + reviewer) after the feedback gate; `test_mission_shape.py`; QA (c)–(e); the coach's number-reading questions; Merijn plays Act I to the first frost.
- **S3:** the 2e alive; Act II's six mains with `steps:`; `first_kpi_review` screen; the KPI board's birth and day 100 as scenes; `company.yaml` complete; the Act II rewrite; the principle line in debriefs; the Phase 2 gate (autoplay five personas, route check, code review of the Phase 2 diff, Merijn's full playtest, tuning backlog).

## Verification (Phase 2 as a whole)
- Per commit: the gate (`godot --headless --import`, `tools/run_godot_tests.py`, `build_content.py --check`, pytest) and CI.
- Per slice: the screenshot set looked at; autoplay on the slice's acts with the five personas, report regenerated; the route check ratchet unchanged or better; Merijn's playtest with the checklist; his notes into PLAN §9 before the next slice is planned.
- Phase end: the §4 gate, plus the acceptance from the first-five-minutes spec (two cold players can say what they are there to do and whom they met) extended to "and what the waiting list is".
