# Playtest checklist: the first winter and the first hundred days (Merijn)

Slices 2 "De eerste winter" and 3 "Honderd dagen" (PLAN 2.15, 2.16; design `docs/superpowers/specs/2026-10-21-phase2-design.md` §4).
Play `docs/qa/playtest-checklist-act0-1.md` first: this one starts where the training week ends.

Build: the **Playtest** release on GitHub (Releases → Playtest → `Spanning-windows-playtest.zip`).
- **Check the build date first.** The release on 2026-10-24 was built from `067621b` (22 October), so it holds slice 1 only.
- Slices 2 and 3 need a new commit whose subject starts with `[playtest]`, and CI on GitHub has been failing with no steps run (PLAN §10, Billing).
- If the release is older than this file, you are playing slice 1: stop here.

Aim: play Act I to the first frost, then on to day 100 and as far into Act II as you like. Play as a new CI lead would. Note what you *feel*, with the in-game date.
Time: a guess, not measured: Act I to the frost is 2–3 hours at a normal pace. Day 100 comes about an hour after that. Act II runs mostly after day 100: the expert bot finishes it around day 175.

## The calendar at a glance

| In-game date | Day of play | What happens |
|---|---|---|
| Mon 12 Oct 2026 | 0 | Your first day (slice 1) |
| Fri 16 Oct | 4 | Act I opens on the board once Friday's training is done (straight away if you skipped the week) |
| Mon 30 Nov | 49 | "Voor de vorst" opens on its own: mevrouw El Amrani's winter |
| Mon 21 Dec | 70 | The first frost: the winter is judged (did her connection get delivered?) |
| 8 weeks after you take "Henks kennis" | — | Henk retires (his farewell); the deadline closes |
| Wed 20 Jan 2027 | 100 | "Honderd dagen" opens: Ruud and Frank in the MT-kamer on the 2e |
| after "Twee recordmaanden" | ~175 for a fast player | "Het eerste kwartaal": the KPI board at Directie & Obeya |

## How to get there fast

The designer (you) jumps to a play day with the **designer saves**: the autoplay bot plays the campaign to a stop and writes a save. They are not in the player build's menu: only with the flag.
- [ ] **Make the saves** (once, and again after a content change; several minutes each): `python tools/make_designer_saves.py` (expert bot, seed 11). They land in Godot's `user://saves/designer/` (on Windows `%APPDATA%\Godot\app_userdata\Spanning\saves\designer\`).
- [ ] **Start the game with `--designer`** after `--` (`Spanning.exe -- --designer`, or `godot --path game -- --designer`; the editor has it on already). The title menu then has **Ontwerper**: one card per save with its play day. "Spelen" copies it into the autosave and plays from there, so it replaces whatever the autosave held (keep your own game in a slot first).
- [ ] A card that says "Oude inhoud: maak de opslag opnieuw" was made before the missions changed: make the saves again.

| Save | Starts at | Use it for |
|---|---|---|
| `designer_training_done` | day 5 | §1: Act I just open |
| `designer_day045` | day 45 | §6: just before "Voor de vorst" (day 49) |
| `designer_day070` | day 70 | §6: the first frost, the winter judged |
| `designer_day095` | day 95 | §7: just before "Honderd dagen" (day 100) |
| `designer_act2` | about day 76 on seed 11 | §8: Act II just opened |

The bot plays an expert on seed 11, so the world is the bot's, not yours (its name, its fixes). It does not play Act I the way you would; note what feels off.

The other honest shortcuts, in a game you play yourself:
- [ ] **Skip the training week:** at the ontvangst on the first morning, the link top left "Ik ken Voltana al: sla de inwerkweek over". Or on Monday at the mission board, the skip row. Act I opens at once, and the first mission "Volg het dossier" counts as done.
- [ ] **Skip to a Check:** once you hand in an A3, the A3 says "Wacht tot de Check (…)". The *Intussen* card opens by itself: "Spoel door tot de Check: N dagen". The skip stops by itself when a person wants you (a check-in, a deadline, a call). You can reopen *Intussen* from Notities.
- [ ] **End the day:** after 17:00, go to the front door on the begane grond and press E ("Naar huis"). You start the next working morning at 08:30. The clock moves only with what you do. There is no "wait until five".
- [ ] **Save before the big moments:** Esc → "Opslaan" → one of five slots. Good moments to save:
  - just before day 49, to replay the winter with a different promise;
  - before you pick a branch of the fork;
  - just before day 100, to replay Frank's question.

## Before you start
- [ ] Notepad ready: write the in-game date with every note (top bar).
- [ ] The playtest log is on (Instellingen); it records events and real minutes.
- [ ] Sound on, low: listen for the van, the phone buzz and the ringing call.

## 1. Act I opens up (after the training week)
At the mission board (1e, Aansluitingen) and in *Opdrachten* on the phone (Tab):
- [ ] One main at a time, at most three sides. Did the board ever offer too much at once?
- [ ] **The fork** after "De stapel bij Werkvoorbereiding": "De onvolledige aanvraag" (Sanne, the bottleneck) and "Meterkast niet gereed" (Marco, not the bottleneck) are offered together.
  - Which did you pick, and why?
  - Did Marco's pressure make the wrong one feel right?
- [ ] After the Check on Marco's branch: did the Check show you that fixing a step that is not the bottleneck brings no flow gain? (Known weak: the autoplay finds the gap inside the noise. Look for the note "dit was niet het knelpunt".)
- [ ] **Your desk** on Werkvoorbereiding's bench, beside Joost and Anouk ("E — Je bureau: je A3"):
  - your name plate, your badge photo and the El Amrani letter are on it;
  - the A3 opens as the sheet on your clipboard.
  - Did it feel like *your* desk?
- [ ] **The Check at Petra's screen** (Meetdata, 1e; "E — Scherm van Petra: de Check", only while a Check waits): do you say "I went to Petra", or "I opened the Check screen"? (PLAN 2.10's own test.)
- [ ] **"Waarom is het net vol?"** (side, from the end of the training week). Femke on the 2e (Netstrategie), an expert talk: questions, no meters.
  - Did you learn something about the grid that you would repeat to a friend?
  - Her "middenspanningsruimte" topic opens the transformer explainer (see §4).
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] **"De gemba-ronde"** (side, weekly, after the first main): walk Intake, Werkvoorbereiding and Planning.
  - Useful habit, or a chore?
  - **Your call (§10):** this routine does not take one of the three side slots. That changes a CLAUDE.md rule. Keep it, or count it?
  - Also §10: the round pays no trust (+1 a week could be farmed); its debrief asks whether the agreed way still holds. Fair?
- [ ] **Sanne's talk** for "De onvolledige aanvraag" (`sanne_checker`): try pressing her once on purpose.
  - **Your call (§7, careless and Sanne):** the autoplay bot pressed her 20 times and never got through, which stops the main chain. Should a presser ever get through? Or should the coach ask one question that points at listening?
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] Mission names: "Maatwerk voor standaardwerk", "De statusbellers" and "De laatste kennisdrager" still name the cause in the A3 and in Notities.
  - **Your call (§7):** rename them after the symptom, like "De stapel bij Werkvoorbereiding"?

## 2. The phone rings: customer calls
From "De telefoon staat roodgloeiend" (Esra's main), and again from day 49 in the winter:
- [ ] **An incoming call:** mevrouw El Amrani rings your phone between 09:00 and 17:00, once a day, only when you are free (not in a talk or a panel).
  - 1 "Opnemen", 2 "Niet opnemen" (a voicemail in Berichten, no penalty).
  - Did the ring pull you in, or interrupt you?
- [ ] **The KCC headset** (begane grond, Klantcontactcentrum, a free desk: "E — Headset opzetten"). You sit down and take the next call. With nobody waiting: "Het is rustig op de lijn. Er hangt niemand voor je in de wacht."
  - Did sitting among Esra's agents make the KCC feel real?
- [ ] **Her fourth call** (`el_amrani_fourth_call`): the talk in phone mode, no face, only her voice in subtitles.
  - Does it work without a face?
  - Three ways to close it:
    - "Een datum noemen" names a real date six weeks out ("Op … Ik schrijf het op");
    - "Eerlijk zijn, en één aanspreekpunt" promises a callback on Friday;
    - a hidden one opens only if you reach her fear: "Kan de warmtepomp nu al draaien?".
  - Did the date you promised feel like a promise *you* made?
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] If you named a date and missed it: her next call opens with her notebook ("Hier staat: 'Volgens de planning over een week of zes aangesloten.' … Die datum is geweest."). Did that sting the right amount?
- [ ] **Your call (§7, kleinverbruikers):** since 1 July 2026 small consumers join the same waiting list as large ones (Netbeheer Nederland). Should her story follow that?

## 3. The yard (werf), the van ride and the opleidingsterrein
The yard is behind the kantine's back door (begane grond). It opens with "Een nacht met de storingsdienst" or "Acht adressen" (sides after "Volg het dossier").
- [ ] **The van ride:** at the van park, E at the monteur's van. You sit in the cab beside them while the edge of town goes by (about 26 s, hold Space to skip, no game time passes). Then a fade, and you stand at the job.
  - Rides: "Acht adressen" and "Niet thuis" with Sandra Vermeulen; "De verkeerde mof in de bus" with Ahmed; "Henks kennis" with Henk.
  - Does the drive feel like going out with someone, or like a loading screen?
  - Is 26 s too long?
- [ ] **Henk's talk in the cab** ("Henks kennis", `henk_camera`): his face while he speaks, the two of you while you choose. Natural?
  - Note: only Henk's ride has a talk. Ahmed's and Sandra's rides are silent drives (see Findings).
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] **Henk's expert talk** ("Henk over het vak", E on Henk on the yard while his mission runs). Questions about moffen, GPLK cable, digging and his practice trench.
  - Did you want to ask more?
  - He ends with "Als je wilt, doe ik het je een keer voor." Did you expect that to happen? (It does not yet.)
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] **The opleidingsterrein** (fenced, off the yard, south of the werkplaats; open from "Henks kennis"): Henk and Ahmed at the practice trench, a meterkast on a stand, a trafohuisje.
- [ ] **Henk's deadline:** eight weeks after you take his mission. Let it run out once (in a save you do not need).
  - Does the closed door feel fair: "Een buddy die het kan voordoen is er niet meer"?
  - Is the problem still solvable another way?
- [ ] **Monteurs Ricardo and Joyce** have their own vans. Did the yard feel like a working place?

## 4. Looking closer, and the transformer explainer
- [ ] **Tells:** the props show the work, in three heights.
  - On the 1e: Intake's stack, Werkvoorbereiding's in-tray, the planners' weekbord, Revisie & GIS's sketches, Meetdata's whiteboard, the close-out cabinet.
  - On the yard: the uitgiftelijst at the magazijn's counter, the moffen rack, the returns pallet, the storingsbord, the spanningsklachten tray.
  - On the 2e (Act II): Netstrategie's tray and the Netverzwaring board, Thomas's waiting list, the directie's board.
- [ ] **Look closer:** E beside a tell (or a click). The camera moves in, one line says what you see, and it is noted once in Notities as a "Waarneming".
  - Did a tell ever make you go and look before a mission told you?
  - Did any tell feel like it was *telling* you the answer?
- [ ] **Your call (§10, minor 7)**, read these where they appear (each shows from the middle height up while its problem is open):
  - Netstrategie's tray (2e, "De netstudie-wachtrij"): *"Bovenop de stapel in het bakje ligt een studieaanvraag voor een gewone woning met een warmtepomp."*
  - The Netverzwaring board (2e, "Wachten op de trafo"): *"Achter de oudste straatnamen op het bord staat in pen: 'trafo nog niet binnen'."*
  - The storingsbord (yard, werkplaats, while "Henks kennis" runs): *"… en daarachter in hoofdletters: HENK."*
  - Too close to naming the cause? Keep, soften, or cut?
- [ ] **"Hoe werkt het? 2: de transformator"**:
  - at the trafohuisje on the opleidingsterrein ("E — Trafohuisje: hoe werkt een trafo?");
  - or after Femke's "middenspanningsruimte" topic;
  - afterwards in Begrippen (K).
  - A bike on a fietstrainer becomes a 10 kV → 400 V trafo; two controls (load, the weather).
  - Could you say the one idea back afterwards?
  - **Your calls (§10):** Ruud speaks it (Henk has retired by Act II). The bike is the analogy (tempo = spanning, force = stroom). 630 kVA and the IEC constants are estimates.
  - **Open (2.7c V5):** let three non-technical people try it cold and say the idea back.

## 5. The coach reads the numbers (main mission only)
E at Ruud ("E — Coach: Ruud"). He is on the 1e until day 100, then in his own office on the 2e.
- [ ] At the start he names a number from the stream ("De doorlooptijd is nu … dagen"), then asks a question.
- [ ] During an experiment, the Kata five come in order (target, actual condition, obstacles, next step, when we go and see).
- [ ] Ask him about a side mission: he should not coach it.
- [ ] Did a number make you think, or did it hand you the answer?
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] **Your call (§10):** his go-see number is the stream's lead time, never your A3's KPI. Right?

## 6. Voor de vorst (day 49 → day 70)
- [ ] Day 49 (Mon 30 Nov): "Voor de vorst" opens by itself (a milestone, no slot): *"Rond de kortste dag, 21 december, gaat het meestal echt vriezen…"*. Did you notice it open?
- [ ] Between day 49 and day 70, did you feel the clock? Did you change what you worked on because of her?
- [ ] **Kept** (her connection delivered by day 70): a message from her in Berichten (*"…om te zeggen dat mijn moeder het warm heeft…"*) and a letter, also in Berichten (*"…Deze keer schrijf ik iets anders op: dank u wel."*).
  - Did it land? Did you feel you had earned it?
  - Note: the design put the letter on your desk; it arrives in Berichten.
- [ ] **Missed:** a short toast (*"Het vriest. In Nova-Oost staat een warmtepomp nog steeds uit."*). Her mother stays with her other daughter, and a letter goes to the directie with a copy to the ACM. It comes back at day 100.
  - Fair? Too soft? Too harsh?
- [ ] There is no frost in the world (no weather, no season yet). Did you miss it?
- [ ] **Your call (§10, winter 1's stakes):** her dossier is an incomplete application that loops back to her until "De onvolledige aanvraag" holds. Picking the bottleneck first keeps her warm (the bot: connected on day 56–63); the other branch misses (day 78–81).
  - Does that teach the fork, or feel rigged?
- [ ] **Your call (autoplay backlog 6):** a player who never phones her still keeps the promise if the flow is right. Should the winter also need her fourth call?

## 7. Honderd dagen (day 100, Wed 20 Jan 2027)
- [ ] The milestone opens: *"Frank Hulshof en ik willen je even spreken, in de MT-kamer op de 2e."* Walk in, and you sit down at the table. Frank presents at the screen; the camera is on whoever speaks.
- [ ] The lines read what you did:
  - which fixes hold;
  - who carries a change ("Dit is ons eigen werk geworden") and who only complies;
  - who left;
  - the El Amrani letter or her call.
  - Did it feel like *your* hundred days, or a report card?
- [ ] **Frank's one question:** *"Wat zou jij ze vertellen?"* (in numbers / that the people do it / too early). Did any answer feel like the "right" one?
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] Afterwards Ruud has moved upstairs ("Directeur Netbeheer" on the 2e). His old room on the 1e is the team's overlegkamer. Did you notice?
- [ ] Optional replay from your save: answer differently.

## 8. Act II on the 2e (after "Klaar maar niet af")
The order of the mains:
1. "Graafschade" (Gert; a containment "Stop en bel" for 14 days)
2. "De revisieberg" (Mieke)
3. "De netstudie-wachtrij" (Femke; needs belt 2)
4. "Wachten op de trafo" (Rob)
5. "Twee jaar op de wachtlijst" (Thomas; Ilse calls)
6. "Twee recordmaanden" (Sanne, Joost, Frank)

Sides: "De zwijgende meter", "Omvormers die afschakelen" (Wim).
- [ ] **The 2e alive:** directie, Netstrategie, the congestiedesk, the MT-kamer, Ingrid Bos (Netstrategie's head), coffee and chatter at the 2e's corner. Does the floor feel like where decisions are made?
- [ ] Briefings now name people by their function (from the company file). In *Wie is wie*, each person shows where they sit and who their manager is; Begrippen (K) has a Voltana page. Believable company?
- [ ] **Ilse's call** (KCC headset or the phone) and **Wim**:
  - Wim's spreadsheet talk (`wim_spreadsheet`);
  - after it, his expert talk by phone ("Wim en zijn metingen", he says u).
  - Wim is not a customer, so he never rings; an expert who is a customer rings unasked at most once a week, and only while a topic serves an active mission. Should Wim be reachable by phone?
  - **Kon je voorspellen waarom dit antwoord werkte?** Verdict: houden / herschrijven / anders in beeld (note it in the table at the end).
- [ ] Femke and Ilse can now be won by listening (QA (e)). Try it.
- [ ] **Your call (§7, Act II fork and deadline):** after the act, Act II has neither a fork nor a deadline. Claude's proposal:
  - no fork here; plan one in Act III;
  - one deadline: digging damage before the winter, where the cheap contractor briefing is the door that closes.
  - Did Act II feel flatter than Act I without them?
- [ ] **Your call (§7, maturity rule):** the rule offers fixes at most one tier above where you are. That conflicts with the designed failed Checks, which assumed tier 3 works weakly in Act I; the content was changed (EAN registration is tier 2), not the rule. Did a fix you wanted never show up?

## 9. Het eerste kwartaal: the KPI board
After "Twee recordmaanden" (or when its fix makes the board), at Directie & Obeya on the 2e:
- [ ] Ruud and Frank stand at the board. Their lines read whether the teams still look at one number, and where Frank stands.
- [ ] Then the board: you hang the teams' KPIs for the coming quarter ("E — KPI-bord: waar sturen de teams op?" later).
  - Did choosing KPIs feel like a real decision?
  - Did the forecast tell you something?
- [ ] It ends with the next review "over een kwartaal". Did that promise feel real (nothing schedules it yet)?

## 10. Debriefs, decay, money
- [ ] Every main mission's debrief ends with one sentence from Ruud naming the principle your play paid or cost: long term, respect for people, or always improve. Helpful or preachy?
- [ ] A fix you left alone slips. Its mission comes back ("… groeit weer …"). Did the decay feel fair and visible (tells, check-ins)?
- [ ] Money:
  - **Your call (§10):** at the debt floor the active main and any deadline mission stay fundable, and the directie advances the rest.
  - Every problem now has a fix under € 3,000. Do the four new cheap ones feel like easy ways through? (`van_refill_card`, `henks_one_point_lessons`, `milestone_mail_by_hand`, `tap_trial_one_station`.)
- [ ] Only if you hit the debt floor for four weeks: Financiën's side "Twee keer naar hetzelfde adres" opens as a way back. (Known: the directie advance has no ceiling yet; tuning T-1 is in flight.)

## Verdicts on the talks (feeds 3.0c, the talk rewrite)
One row per talk, filled in while you play. "Voorspelbaar": could you say beforehand why the answer that worked would work? Verdict: **houden** (keep as it is), **herschrijven** (the talk itself is weak) or **anders in beeld** (the talk is fine, how it is shown is not).

| Talk | Voorspelbaar? (ja / nee) | Verdict (houden / herschrijven / anders in beeld) | Why, with the in-game date |
|---|---|---|---|
| Sanne, `sanne_checker` (§1) | | | |
| Femke, "Waarom is het net vol?" (§1) | | | |
| Ruud, the coach's questions (§5) | | | |
| Mevrouw El Amrani, the fourth call (§2) | | | |
| Henk in the cab, `henk_camera` (§3) | | | |
| Henk, "Henk over het vak" (§3) | | | |
| Frank's question in the MT-kamer (§7) | | | |
| Ilse's call (§8) | | | |
| Wim, `wim_spreadsheet` (§8) | | | |

## Afterwards (5 minutes)
- [ ] Three things that pulled you in, three that pushed you out.
- [ ] The moment you almost stopped, and why.
- [ ] Without looking: what is the waiting list, and why is the grid "vol"? (The phase acceptance.)
- [ ] Would you play on to Act III? Why, or why not?
- [ ] Share the playtest log: `%APPDATA%\Godot\app_userdata\Spanning\saves\playtest_log.txt`.

## Known before you play (do not log these)
- The talks still look and read as in slice 1. The Act I and Act II rewrites and any restyle wait for your feedback (design §2.7).
- Nothing starts a walking talk yet. Ruud's walk is a scripted scene.
- No weather or seasons: the frost is a date, not a sight.
- The El Amrani front door is Phase 4. In Phase 2 the payoff is her call and her letter.
