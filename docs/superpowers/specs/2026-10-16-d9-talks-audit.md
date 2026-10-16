# D9 talks audit: the Act 0 week and the Act I–II talks as the builder lands them

> Status: by the mission-and-dialog design agent (Claude, 2026-10-16 evening), PLAN 1.11a and §4.3 item 9 (the quality bar). **Docs only.** For the **builder** (D9). Dutch game text, English notes. Merijn was away; calls are logged in §6 and PLAN §10.
>
> **What was audited.** D9 had not landed on `origin/claude/compassionate-heisenberg-ynlqyr` (head `da81c77`; `content/dialogs.yaml` there holds four talks). The builder's work in progress was read instead: its worktree's `content/dialogs.yaml` as of **16:35 UTC** (2,635 lines; 19 people; 36 talks: the four in origin, the eleven Act 0 talks, and 21 Act I–II talks and check-ins). Line numbers below are that snapshot's. When D9 lands, re-check the P0/P1 items against the landed file (§5 has the list).
>
> Audited against: `2026-10-16-act0-tutorial-talks.md` (the week, the cards, `ruud_names`, §7 needs), `2026-10-16-first-five-minutes.md` (the shifted Monday, B1–B7), the voice sheets (`2026-10-15-four-tier-audit.md` §6, and the Acts 0–II scripts §2), `2026-10-16-person-needs.md`, the tier-1 content audit (C1–C16), the content rules T1–T11, the arc (`2026-10-16-drie-winters-arc.md` §3: the El Amrani promise), `content/world.yaml` and `cast.json` (can the talk be reached?).
>
> **Route check:** not run. The route tool needs a full `--import` of the project in this worktree (characters, explainer SVGs) on a machine already at load 7 on 4 cores, and the builder's suite measures the same thing (`test_dialog_routes.gd`, `TIER1_RATCHET`). **Every rewrite below keeps the line's `tags`, `tell` and the layer's `via`,** so none changes a route; the builder's route test stays the judge.

## 0. Summary

The builder carried the specs over faithfully: every Act 0 talk has its day's move as a line, every persuasion has its five outcome lines, the tells of the needs spec are in, the shifted Monday is in (`anouk_seven`, `sanne_tuesday`, `mieke_wednesday`), and Rachid has a third tell. The **writing** holds the bar almost everywhere. What fails is mostly **around** the writing, and it is the kind of thing a playtester meets in the first hour:

| # | Headline | Priority |
|---|---|---|
| A1 | **Three of the eleven Act 0 talks cannot be reached**: Mieke (Revisie & GIS is shut until `fix_revision_backlog`), Petra (Meetdata is shut until `walk_meters`…), Linda (`connections.planning` is in no room). Rachid, Mieke and Linda have **no body** (`cast.json`). | P0 |
| A2 | **`anouk_seven` hangs on `training_mon`**, whose observe goal the walk meets at ~08:35 (first five minutes §4.1). If the mission completes then, the first talk of the game is gone by 19:00. | P0 |
| A3 | **`bank.ruud_names` and the move cards are not in** (tutorial talks §2, §3). Without them the week teaches no move by name. | P0 (if not still coming) |
| A4 | **The El Amrani date is an untracked promise**: "half november", hard-coded, no `promise`, no `{promise_date}` (arc §3; tier-1 audit F12/C3). Winter 1 checks exactly this. | P0 |
| A5 | **The Act 0 week spends Act I's reveals.** Linda's Wednesday concern *is* her Act I concern, almost word for word; Petra's Act I interest repeats her Thursday interest verbatim; Sanne's "postkantoor" concern comes three times. A player who listened in week one hears nothing new in Act I: the opposite of "people remember". | P1 |
| A6 | **Lines that claim what the player did not do**: "Fijn dat je eerst vroeg hoe het ging" (Sanne, Anouk) when the player may never have asked; Sanne's Friday position quotes Rachid's list, but Rachid's talk is optional. | P1 |
| A7 | **The new opening made two experience lines false**: Petra's "Maandag wist ik niet eens waar Intake zat" (Ruud walked the player through Intake on Monday); Marco's "Bij mijn vorige werk…" invents a past (C2). | P1 |
| A8 | **Sanne's Friday worry is upstream-wrong**: Intake sits *before* Werkvoorbereiding, so a faster WVB does not push more work into Intake. Directive 7 (correct). | P1 |
| A9 | **Mevrouw El Amrani is Fatima; the B5 letter was signed "N."**, and three dates (letter 20 August, her notebook 27 July, the followed order ~31 days old) disagree. | P1 (letter fixed in the first-five-minutes spec) |
| A10 | **Opener limits break**: compliance "Prima." opens 10 of 29 (T1/T2 limit 9); check-in lifted "Weet je wat" opens 4 of 7 (limit 2), and "Weet je wat ik ga doen?" is Ruud's signature (T8). | P1 |
| A11 | Smaller voice and continuity slips: Rob switches from *u* to *je*; Sanne borrows Marco's "Wie bouwt dat?"; Marco has had "drie" predecessors in one talk and "twee" in the next; "boterhamzakje" / "broodzakje". | P2–P3 |
| A12 | **Henk calls the player "jongen" three times**; with the creator (2.7b) half the players are women. Token `{jongen_meid}` added to the creator spec. | P1 |

**Scores** (§3): two Act 0 talks fall under 25/35 as built (`linda_wednesday` 24, `sanne_friday` 24) and two Act I talks (`el_amrani_fourth_call` 23, `petra_batch` 23); one check-in sits at 24 (`marco_day_100`). All five are rewritten below; with the fixes every talk audited scores 26–31.

---

## 1. P0: the week cannot be played as built

### A1. Reach every Act 0 talk, and give its person a body

| Talk | Person's place | Today | Fix (recommended) |
|---|---|---|---|
| `rachid_counter` | `connections.intake` | reachable through "Mensen hier", but **no avatar** | `cast.json`: Rachid at an Intake desk behind Sanne (first five minutes B3 leg 4 already puts him there with "the three trays") |
| `mieke_wednesday` | `connections.revision` | **room shut** (`revision_gis` opens with `fix_revision_backlog`, `fix_digging_damage`); no avatar | `content/world.yaml`: add `training_wed` to `revision_gis.opens_with`; `cast.json`: Mieke at a Revisie & GIS desk |
| `linda_wednesday` | `connections.planning` | **no room holds the place**, so no marker, no menu; no avatar | `world.yaml`: put `connections.planning` in the `connections` room (planners sit with Werkvoorbereiding at most DSOs; a desk next to Joost's team), marker at the next rebake; `cast.json`: Linda there |
| `petra_thursday` | `connections.close_out` | **room shut** (`meter_data` opens with `walk_meters`, …); Petra visible through glass | `world.yaml`: add `training_thu` to `meter_data.opens_with` (2.1c-people already wants it opened by `walk_connections`; Thursday is earlier and is when the talk needs it) |

The progressive rule holds: a room opens because a mission (here the training day) needs it. **Test for the builder:** for every dialog with a `mission`, its person's `place` is a place in a room that the mission (or an earlier one) opens, and its person has a `cast.json` entry. That one check would have caught all four.

### A2. Keep Monday open until Anouk's talk

`anouk_seven` (l. 766) has `mission: training_mon`. The first-five-minutes spec (§4.1) meets `training_mon`'s observe goal *on the walk*; if the mission completes at that moment, `training_tue` takes over and the talk at 19:00 has no active mission. **Fix:** `training_mon` completes at the end of B7 (the talk's end, or the player leaving the building on Monday evening), not when its places are observed; or the talk hangs on a beat (`trigger: {beat: monday_evening}`) once dated beats exist (1.0a-i). Test: on a new game, after the walk and the skip to 19:02, `dialog_for("anouk")` is `anouk_seven`.

Also missing from the spec's YAML: `place: connections.design` and `clock: "19:02"`. The scene can drive both; if the schema has no `clock`, leave it out and let B6 set the time (P3).

### A3. The cards and Ruud's naming

`bank.ruud_names` (ten lines, `none`, `week_end`) and `move_cards` (eight cards plus the Friday card *Wie zit er tegenover je?*) are not in the snapshot. Without them the week has no names for the moves and Ruud says nothing after a talk. If they are coming in a later D9 commit, ignore this item; the texts are final in the tutorial talks spec §2–§3. One addition from the first-five-minutes spec: **Monday's naming line arrives as Ruud's text message at 19:41** (B7), not on the summary card.

### A4. The El Amrani date must be a promise the game keeps

`el_amrani_fourth_call`, proposal `name_a_date` (l. 1708–1712):

> say: "Volgens de planning wordt u half november aangesloten."
> reply: "Half november. Ik schrijf het op."

The scripts and the arc (§3, l. 114 and 147) make this the temptation of tier 1: a date that calms her now and is checked later (kept: trust +5; broken: memory −15, reputation −1, she reads her notebook aloud on the next call; the north star's `date_kept`). As built it is a date nobody checks, which is exactly the untracked promise C3 forbids. **Replace with the scripts' version:**

```yaml
      - id: name_a_date
        label: "Een datum noemen"
        say: "Ik zie hier {promise_date}. Dan wordt u aangesloten."
        addresses: [interest]
        reply: "{promise_date}. Ik schrijf het op."
        promise: {kind: delivery_date, source: planning_estimate}   # checked against the followed order (arc §3)
```

If the engine has no `promise` or `{promise_date}` yet, add the key to the schema now (validated, stored as `agreed:` plus the date) and log the check under 2.4b (winter 1). Do not ship a fixed "half november".

Same talk, the honest proposal (`honest_window_and_contact`): "ik bel u vrijdag terug" is also a promise. P2: record it the same way (`promise: {kind: callback, days: 3}`), or the player who chose honesty is the one who breaks a promise unseen.

---

## 2. P1–P3: line-level fixes, in order

Each row quotes the line as it stands (snapshot line number) and gives the replacement. Tags, tells and `via` stay as they are unless the row says otherwise.

### 2.1 The week spends Act I's reveals (A5)

| # | Where | As built | Replace with | Why |
|---|---|---|---|---|
| 1 | `linda_wednesday` concern text (l. 1142) | "Als ik ruimte inplan voor storingen, zit er een monteur koffie te drinken als het rustig is. Dan zegt iedereen dat ik niet kan plannen. Dus plan ik vol. En dan valt het om. Elke dag." | "Ik bel elke dag twaalf mensen af. Mensen die een dag vrij hebben genomen. In het begin vond ik dat vreselijk. Nu merk ik dat ik het gewoon doe, tussen twee slokken koffie door. Dat vind ik eigenlijk erger." | This is `linda_replanning`'s concern (l. 1904), nearly word for word. The tutorial keeps a true, smaller fear (what the reshuffling does to *her*), and Act I keeps its reveal (the buffer). Tags `[admission]` stay. |
| 2 | `linda_wednesday` proposal `count_the_reshuffles` reply (l. 1157) | "Tellen. Dan zie je dat het niet aan mij ligt. … Toch?" | keep | still fits the new concern |
| 3 | `petra_batch` interest text (l. 1764) | "Elke keer dat ik in het register ga, ben ik een kwartier kwijt voordat ik iets heb gedaan. Twee tokens, de controles, de export. De Molen maalt, maar langzaam." | "Je kent de Molen. Een kwartier opstarten, elke keer. Dus doe ik het één keer per maand. Dat is de rekensom, en die klopt. Alleen staat er in die rekensom geen familie die op een EAN wacht." | Verbatim from `petra_thursday` (l. 1249). Written so it also reads right to a player who skipped Thursday ("Je kent de Molen" is how she talks: everyone knows the Molen). Tags `[claim, feeling]` stay. |
| 4 | `petra_batch` concern text (l. 1770) | "Ik ben alleen. Als ik het elke dag doe en ik ben een week ziek, dan ligt het stil en ziet iedereen het meteen. Nu merkt niemand het als ik er een week niet ben. De maandrun schuift gewoon een weekje op." | "Weet je waarom die maandrun me eigenlijk goed uitkomt? Als ik een week ziek ben, schuift hij gewoon een weekje op. Niemand die het merkt. Doe ik het elke dag en ik ben er niet, dan ziet iedereen het meteen. Dan is Petra het probleem." | Thursday's concern was "nobody asked who takes over"; this one is the next layer (the batch hides her absence). The first two sentences repeated Thursday. |
| 5 | `sanne_checker` concern text (l. 1494) | "Hier denken ze dat Intake het postkantoor is. Stempel erop, doorsturen. Als er iets misgaat, is het de Intake. Met een controleur kan ik tenminste laten zíen dat het niet aan ons ligt." | "Mijn mensen horen elke dag aan de telefoon dat ze het fout doen. Rachid belt een installateur drie keer na en krijgt de schuld als het toch terugkomt. Ik kan ze alleen maar zeggen dat het niet aan hen ligt. Met een controleur kan ik het tenminste laten zíen." | "Postkantoor" was her Tuesday interest (l. 845) and comes back on Friday (l. 1372). Here it goes deeper: her team, not her title (recognition, `tell` stays). Rachid by name works whether or not the player met him: he is on her team. |
| 6 | `joost_vacancies` interest text (l. 1416) | "Elke week komen er meer dossiers binnen dan we eruit krijgen. Anouk zat gisteren om zeven uur nog te tekenen. Dat wil ik niet meer." | "Elke week komen er meer dossiers binnen dan we eruit krijgen. Ik zie mijn mensen moe worden. En ik heb ze niks te bieden behalve 'het is tijdelijk'. Dat wil ik niet meer." | "Anouk at seven" is the first talk of the game and Joost's own Wednesday concern; this echoes his Wednesday words ("dat het tijdelijk is") as a man who has said it once too often. Tags `[claim, feeling]` stay. |
| 7 | `mieke_redraw` interest (l. 2325) | "… Deze is op een broodzakje getekend. Met pindakaasvlek." | "… Deze is op een boterhamzakje getekend. Met pindakaasvlek. Het is niet de eerste." | the same object as Wednesday's (l. 1046 says "boterhamzakje"); "niet de eerste" reads right with or without Wednesday (P3) |
| 8 | `mieke_redraw` commitment (l. 2369) | "… En het broodzakje lijst ik in." | "… En het boterhamzakje lijst ik in." | P3 |

### 2.2 Lines that claim what the player did not do (A6)

| # | Where | As built | Replace with |
|---|---|---|---|
| 9 | `sanne_tuesday` heard (l. 884) | "Joh. Fijn dat je eerst vroeg hoe het ging. Dat doet niemand op zo'n ochtend." | "Joh. Jij luistert gewoon. Dat doet niemand op zo'n ochtend." |
| 10 | `anouk_first_look` heard (l. 999) | "Fijn dat je eerst vroeg. Dat doet niet iedereen." | "Fijn. Je schreef niks op. Dat merkte ik wel." (answers her safety tell, "Je hoeft het niet op te schrijven") |
| 11 | `sanne_friday` position (l. 1361) | "Je loopt overal rond en je vraagt dingen. Rachid zei dat je zijn lijstje wilde zien. Niemand wil Rachids lijstje zien." | "Je loopt overal rond en je vraagt dingen. Ook aan mensen die nooit iets gevraagd wordt. Dat valt op, hier." (tags `[claim, feeling]` stay) |
| 12 | `sanne_friday` commitment (l. 1392) | "Maandag. Om negen uur. Ik neem Rachids lijstje mee. Zeg niks tegen hem." | "Maandag. Om negen uur. Ik neem de stapel terugkomers mee. De echte, niet die uit het weekrapport." |

Rachid's talk is optional (first five minutes §4.2); his list exists only in his own talk and stays his to show. Rule for the builder (add to T9's spirit): **a line in a required or always-reachable talk may not name what only an optional talk revealed**, unless the talk has a variant on that fact.

### 2.3 Experience lines must be the CI lead's own, and true to the opening (A7)

| # | Where | As built | Replace with |
|---|---|---|---|
| 13 | `petra_thursday` line `experience` (l. 1278) | "Maandag wist ik niet eens waar Intake zat. Ik heb het aan de schoonmaker gevraagd. Ik dacht: als ik vandaag ziek word, weet niemand wat ik al gezien heb." | "Maandagavond kon ik de uitgang niet vinden. Ik heb het aan de schoonmaker gevraagd. En ik dacht: als Ruud morgen ziek is, weet hier niemand wat ik kom doen." |
| 14 | `marco_day_100` line `experience` (l. 2205) | "Bij mijn vorige werk hing er ook zo'n bord. Toen de man die het had opgehangen wegging, hing het er nog een jaar. Leeg." | "Mijn eerste week liep ik langs dat bord in de gang, met de cijfers van 2023. Ik vroeg van wie het was. Niemand wist het meer." |
| 15 | `marco_wasted_trips` reply `experience.misses` (l. 1598) | "Bij jouw vorige baan. Ja. Hier is het Nova." | "Jouw eerste weken. Ja. Ik zit hier drieëntwintig jaar. Hier is het Nova." (answers the bank line, which is about *this* job) |
| 16 | `esra_after` line `experience` (l. 2131) | "In mijn eerste weken hier keek ik ook vooral naar getallen. Ruud vroeg me toen: wie heb je vandaag gesproken? Ik wist het niet." | "Mijn eerste week vroeg Ruud elke avond: wie heb je vandaag gesproken? Niet wat ik gezien had. Wie." |

13: B6 (the first evening) has the cleaners' trolley at Intake, so the new line is true in every game. 14: Marco's concern names "de gang met de cijfers van 2023", so the player has walked past it. 16: the player's first week *was* talks, so "I mostly looked at numbers" was false.

### 2.4 Correctness: Sanne's Friday worry (A8)

| # | Where | As built | Replace with |
|---|---|---|---|
| 17 | `sanne_friday` concern text (l. 1372) | "Volgende week begin je echt, toch? Met de stapel van Joost. Als het daar beter gaat, komt alles nog harder bij ons binnen. En dan zijn wij weer het postkantoor dat het niet bijhoudt." | "Volgende week begin je echt, toch? Waar je ook begint: als het daar beter gaat, kijkt iedereen naar wat wij doorsturen. Elke aanvraag die terugkomt, heet dan weer 'een fout van Intake'. En dan zijn wij weer het postkantoor." |

Intake is upstream of Werkvoorbereiding: a faster WVB sends more work *downstream*, never more into Intake. What a better WVB does to Intake is make its rework visible (the incomplete applications come back faster), which is her real fear and the Act I problem `incomplete_application`. "Waar je ook begint" also stops her from pointing at the first main mission's step (nothing handed over). `tell: recognition` stays.

### 2.5 The El Amrani dates and name (A9)

| # | Where | As built | Replace with |
|---|---|---|---|
| 18 | `el_amrani_fourth_call` opening (l. 1689) | "… Ik bel voor de vierde keer deze maand, en ik heb ze allemaal opgeschreven." | "… Ik bel voor de vierde keer, en ik heb ze allemaal opgeschreven." (her dated calls span two months) |
| 19 | interest text (l. 1696) | "Op 7 september zei iemand 'binnenkort'. Op 21 september 'we zijn ermee bezig'. Op 5 oktober wist niemand het. …" | "Drie weken geleden, dinsdag, kwart over tien: 'binnenkort'. Twee weken geleden: 'we zijn ermee bezig'. Vorige week wist niemand het. Ik wil gewoon weten waar ik aan toe ben." |
| 20 | reply `open_question.lands` (l. 1733) | "Aangevraagd op 27 juli. Ontvangstbevestiging op 3 augustus, nummer erbij. Sindsdien hoor ik alleen Vivaldi." | "Aangevraagd op {aanvraag_datum}. Een week later de ontvangstbevestiging, nummer erbij. Sindsdien hoor ik alleen Vivaldi." |

The talk opens in Act I on whatever day the player reaches `fix_status_callers`; fixed September dates break T9 for a late player and for a dossier younger than the arc's (1.8a measured ~31 days at the start, which would make her 7 September call predate her request). Relative dates with a clock time keep her notebook voice (`tell: facts`). `{aanvraag_datum}` is the same token the B5 letter uses (the first-five-minutes spec now reads it and is signed *F. El Amrani*); the followed order must be born on **27 July** as the arc says (PLAN 1.8a). If the dialog text cannot take tokens yet, add `{aanvraag_datum}` beside `{person}` (P1).

### 2.6 Opener limits (A10)

Compliance "Prima." opens 10 of 29 (T1: at most ⌊29/3⌋ = 9; T2 counts "Prima" as a narrator word). Lifted "Weet je wat" opens 4 of 7 (at most 2), and "Weet je wat ik ga doen?" is Ruud's signature (T8).

| # | Where | As built | Replace with |
|---|---|---|---|
| 21 | `sanne_tuesday` compliance (l. 886) | "Prima. Als Ruud het zegt." | "Nou. Als Ruud het zegt." |
| 22 | `joost_wednesday` compliance (l. 1117) | "Prima. Tel maar." | "Tel maar. Het getal klopt." |
| 23 | `petra_thursday` compliance (l. 1288) | "Prima." | "Dat zet ik in mijn map." |
| 24 | `sanne_friday` compliance (l. 1396) | "Prima. Fijn weekend." | "Goed hoor. Fijn weekend." |
| 25 | `esra_after` lifted (l. 2133) | "Weet je wat ik ga doen? Haar eerste dag ga ik gewoon naast haar zitten. Zonder scherm." | "Deal. Haar eerste dag ga ik gewoon naast haar zitten. Zonder scherm." (her own opener) |
| 26 | `marco_day_100` lifted (l. 2207) | "Weet je wat. Ik laat Ricardo het bord bijhouden. …" | "Kijk. Ik laat Ricardo het bord bijhouden. …" (his) |
| 27 | `anouk_owns_tray` commitment (l. 1344) | "Afgesproken. Ik teken er een bergje bij. Met een vlag." | "Goed. Ik teken er een bergje bij. Met een vlag." ("Afgesproken." is at 8 of 29, one under the limit; Anouk's sheet has "Kom maar." / "Goed.") |

After 21–27: compliance "Prima." 6 of 29, lifted "Weet je wat" 2 of 7, commitment "Afgesproken." 7 of 29. Make T1/T2/T8 part of `build_content.py --check` if they are not yet (four-tier audit §7).

### 2.7 Voice and continuity (A11, A12)

| # | Where | As built | Replace with |
|---|---|---|---|
| 28 | `henk_camera` opening (l. 1827) | "Je komt zeker voor die camera. Jongen, ik zeg het maar meteen." | "Je komt zeker voor die camera. Ik zeg het je maar meteen, {jongen_meid}." |
| 29 | `henk_last_week` heard (l. 2075) | "Dag, jongen. Tot zaterdag." | "Dag, {jongen_meid}. Tot zaterdag." |
| 30 | `henk_last_week` variant concern (l. 2090) | "… Dat is een raar gevoel, jongen. …" | "… Dat is een raar gevoel, {jongen_meid}. …" |
| 31 | `rob_order_rule` commitment (l. 2507) | "Conform. Ik pas de procedure aan. En die uitdraai mag je houden; …" | "Conform. Ik pas de procedure aan. En die uitdraai mag u houden; …" (every other Rob line says *u*) |
| 32 | `sanne_checker` proposal `required_fields` reply (l. 1512) | "Dan zien we het niet eens meer… als het werkt. Wie bouwt dat dan?" | "Dan zien we het niet eens meer… als het werkt. Nou. En wie maakt dat? IT zegt al een jaar 'volgend kwartaal'." ("Wie bouwt dat" is Marco's signature, T8) |
| 33 | `marco_day_100` opening (l. 2189) | "Honderd dagen. Je bent er nog. Dat is al meer dan de vorige twee." | "Honderd dagen. Je bent er nog. Dat is al meer dan de vorige drie." (`marco_wasted_trips`: "Ik heb er al drie gehad.") |
| 34 | `anouk_first_look` opening (l. 958) | "O, hoi. Sorry, het is een beetje een bende. Drie collega's zitten op cursus." | "O, hoi. Daar ben je weer. Sorry, het is nog steeds een bende." (Ruud introduced her on Monday's walk, and Joost told the player about the course: she does not explain it to a stranger twice) |
| 35 | `rachid_counter` `teaches` (l. 896) | `[open_question]` | `[]` (P3: Sanne teaches Open vraag the same morning; with `[]` Ruud names Rachid's best-landing move, so Tuesday does not name one move twice) |
| 36 | `anouk_late` concern (l. 2018) | "Ik denk dat ik langzamer ben dan de rest. Ik kijk alles drie keer na. Als ik tot zeven blijf, ziet niemand dat." | "Ik kijk alles drie keer na. Niemand vraagt me dat. Maar één fout van mij ligt straks bij een monteur in een sleuf. Als ik tot zeven blijf, ziet niemand hoe lang dat duurt." (P3: "langzaam" is already her Tuesday and Thursday concern; this is the perfectionism-as-fear beat the tutorial spec promised) |

`{jongen_meid}` (jongen / meid, from `player.look.body`) is added to the creator spec §1.6 with the other player tokens. Henk's "die jongen" about Ahmed (l. 1841, 1877, 2089, 2103) stays: that is Ahmed.

### 2.8 Appointments the week never keeps (P2)

The tutorial talks let the *player* propose times ("morgen om zeven uur"). Where the next day's talk or mission visits that person, the promise is kept by the world (Anouk Tuesday, Joost's count on Wednesday). Where nothing follows, the player promises and the game forgets (F12):

| # | Where | As built | Replace with |
|---|---|---|---|
| 37 | `linda_wednesday` proposal `watch_one_morning` say (l. 1160) | "Mag ik morgen om zeven uur naast je zitten, als je het kaartenhuis bouwt?" | "Mag ik een keer een ochtend naast je zitten, als je het kaartenhuis bouwt?" (reply: "Een ochtend. Dan zie je het voordat het omvalt. Ja.") |
| 38 | `mieke_wednesday` commitment (l. 1055) | "Dat moet kloppen, dus kom vrijdag terug. Dan heb ik de slechtste apart gelegd." | "Dat moet kloppen, dus kom terug wanneer je wilt. De slechtste leg ik apart. Die gaat nergens heen, geloof me." |
| 39 | `petra_thursday` commitment (l. 1284) | "Klopt. Volgende week dinsdag, om tien uur. Ik leg de map klaar. Jij mag hem aanraken." | "Klopt. Zeg maar wanneer. Ik leg de map klaar. Jij mag hem aanraken." |
| 40 | `sanne_friday` `walk_the_flow_monday` | Monday 09:00 with Sanne | keep, and pay it off: with `agreed:sanne_friday:walk_the_flow_monday`, Sanne joins the first step of `walk_connections` (one line at Intake: "Daar ben ik. Mijn bak eerst."). If that cannot be built in Phase 1, soften the commitment to "Volgende week. Ik neem de stapel terugkomers mee." |

### 2.9 Rachid's availability (P2)

`rachid_counter` hangs on `training_tue` only (l. 889 notes why: walk-around triggers do not exist yet). The spec makes him optional Tuesday to Thursday; as built, a player who spends Tuesday on Sanne and Anouk loses him for good, which is a missed deadline nobody designed. Interim: bind him to `training_tue` and keep him through `training_thu` if the engine allows a list of missions; otherwise leave it and log a ⬜ to move him to `trigger: {walkaround: true, days: [training_tue, training_thu]}` with the walk-around layer.

---

## 3. Scores (the quality bar, PLAN §4.3.9)

Seven mission criteria, 1–5 each: **R**eal problem · **E**ntertaining · **I**ntriguing · **C**hallenging · **D**raws in · i**N**tuitive · c**O**rrect. Then the four dialog checks: a real person (P), the meter readable (M), progress without a golden path (G: three routes in the spec or the builder's test), would a player quit here (Q: ✓ = no). Tutorial talks score lower on Challenging by design (unruinable).

| Talk | R | E | I | C | D | N | O | /35 | P M G Q | After fixes |
|---|---|---|---|---|---|---|---|---|---|---|
| `anouk_seven` | 5 | 4 | 4 | 3 | 5 | 4 | 4 | **29** | ✓✓✓✓ | 29 (A2 decides whether it is played at all) |
| `sanne_tuesday` | 5 | 4 | 3 | 3 | 4 | 4 | 3 | **26** | ✓✓✓✓ | 27 (#9, #21) |
| `rachid_counter` | 4 | 3 | 4 | 3 | 4 | 4 | 4 | **26** | ✓✓✓✓ | 26 (needs a body, A1) |
| `anouk_first_look` | 4 | 4 | 4 | 3 | 4 | 4 | 3 | **26** | ✓✓✓✓ | 28 (#10, #34) |
| `mieke_wednesday` | 5 | 4 | 4 | 3 | 4 | 4 | 4 | **28** | ✓✓✓✓ | 28 (unreachable until A1) |
| `joost_wednesday` | 4 | 4 | 4 | 3 | 4 | 4 | 5 | **28** | ✓✓✓✓ | 28 |
| `linda_wednesday` | 4 | 3 | 3 | 3 | 3 | 4 | 4 | **24** | ✓✓✓✓ | 27 (#1, #37; unreachable until A1) |
| `anouk_thursday` | 5 | 4 | 4 | 3 | 4 | 4 | 4 | **28** | ✓✓✓✓ | 28 |
| `petra_thursday` | 4 | 4 | 4 | 3 | 4 | 4 | 3 | **26** | ✓✓✓✓ | 27 (#13, #39; unreachable until A1) |
| `anouk_owns_tray` | 5 | 5 | 4 | 3 | 5 | 4 | 4 | **30** | ✓✓✓✓ | 30 |
| `sanne_friday` | 4 | 4 | 3 | 3 | 4 | 4 | 2 | **24** | ✓✓✓✗ | 28 (#11, #12, #17, #24) |
| `joost_vacancies` | 5 | 4 | 4 | 4 | 4 | 4 | 4 | **29** | ✓✓✓✓ | 30 (#6) |
| `sanne_checker` | 5 | 4 | 3 | 4 | 4 | 4 | 3 | **27** | ✓✓✓✓ | 28 (#5, #32) |
| `marco_wasted_trips` | 5 | 4 | 4 | 4 | 4 | 4 | 3 | **28** | ✓✓✓✓ | 29 (#15) |
| `esra_agents` | 5 | 4 | 4 | 4 | 5 | 4 | 4 | **30** | ✓✓✓✓ | 30 |
| `el_amrani_fourth_call` | 5 | 4 | 4 | 4 | 4 | 4 | 1 | **26 → 23** ¹ | ✓✓✓✗ | 31 (A4, #18–20) |
| `petra_batch` | 4 | 3 | 2 | 4 | 3 | 4 | 3 | **23** | ✓✓✓✓ | 28 (#3, #4) |
| `henk_camera` | 5 | 4 | 4 | 4 | 5 | 4 | 3 | **29** | ✓✓✓✓ | 30 (#28) |
| `linda_replanning` | 5 | 4 | 3 | 4 | 4 | 4 | 4 | **28** | ✓✓✓✓ | 29 once #1 frees its reveal |
| `dirk_shelf` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | **28** | ✓✓✓✓ | 28 |
| `gert_klic` | 5 | 4 | 4 | 4 | 4 | 4 | 4 | **29** | ✓✓✓✓ | 29 |
| `mieke_redraw` | 5 | 4 | 4 | 4 | 4 | 4 | 4 | **29** | ✓✓✓✓ | 29 |
| `femke_triage` | 5 | 4 | 4 | 4 | 4 | 4 | 5 | **30** | ✓✓✓✓ | 30 |
| `rob_order_rule` | 5 | 4 | 4 | 4 | 4 | 4 | 4 | **29** | ✓✓✓✓ | 29 (#31) |
| `thomas_reclaim` | 5 | 4 | 4 | 4 | 4 | 4 | 5 | **30** | ✓✓✓✓ | 30 |
| `ilse_queue` | 5 | 4 | 4 | 4 | 5 | 4 | 4 | **30** | ✓✓✓✓ | 30 |
| check-in `anouk_late` | 4 | 3 | 3 | 3 | 4 | 4 | 4 | **25** | ✓✓–✓ | 27 (#36) |
| check-in `henk_last_week` | 5 | 4 | 4 | 3 | 5 | 4 | 3 | **28** | ✓✓–✓ | 29 (#29, #30) |
| check-in `esra_after` | 5 | 4 | 4 | 3 | 4 | 4 | 3 | **27** | ✓✓–✓ | 28 (#16, #25) |
| check-in `petra_after` | 4 | 4 | 4 | 3 | 4 | 4 | 4 | **27** | ✓✓–✓ | 27 |
| check-in `marco_day_100` | 4 | 3 | 3 | 3 | 4 | 4 | 3 | **24** | ✓✓–✓ | 27 (#14, #26, #33) |
| check-in `linda_evenings` | 5 | 4 | 4 | 3 | 5 | 4 | 4 | **29** | ✓✓–✓ | 29 |

¹ 26 on the page; 23 counting what the untracked promise does to the arc (Correct 1: the game's one family-sized promise is never checked) and the date conflicts. Check-ins have no persuasion routes (G "–"). The four talks already in origin (`joost_output_kpi`, `sanne_kpi`, `frank_kpi_targets`, `ahmed_after_henk`) were audited in the tier-1 content audit and are not re-scored.

**Where a player would quit:** `sanne_friday` (she quotes a list the player never saw; for most players the week's last talk opens on something untrue) and `el_amrani_fourth_call` (the honest player and the comforting player get the same world afterwards). Both are fixed above.

---

## 4. What holds (keep it)

- **The day's move is always one good way, never the only one**, and every Act 0 talk carries that move's line. The feeling cues (Anouk Tuesday, Linda Wednesday) dropped `hesitation` as the validator now allows.
- **Tells everywhere the needs spec asked**, plus Rachid's third (`replies.mood.lands`, fairness): good.
- **Every Act I–II persuasion has its five outcome lines, a `warning` and an in-character ruin** (C6, C7, C9 hold). The temptations still have later costs in their replies ("Al moet Anouk ze dan wel eerst inwerken. Naast haar eigen bak.", Esra's "zes weken ingewerkt").
- **Sector correctness** is good: 3x25A as the standard connection, the KLIC duty and proefsleuven, ACM rules on unused capacity and the capaciteitsbeperkingscontract, the 630/400 kVA order, the 4-step TWI in Henk's words ("Zo heeft ouwe Toon het mij geleerd. In 1984.").
- **Voices** are the sheets' voices nearly everywhere: Joost's "even voor de duidelijkheid", Sanne's "joh", Marco's "mijn mannen", Esra's "Serieus?", Petra's "Klopt.", Rob's "Conform."

---

## 5. Checklist for the builder (in order)

1. ⬜ A1: rooms open for `training_wed` (Revisie & GIS) and `training_thu` (Meetdata); `connections.planning` in the Aansluitingen room; cast entries for Rachid, Mieke, Linda; the reachability test.
2. ⬜ A2: `training_mon` stays active until `anouk_seven` can be had (or a beat trigger); the test.
3. ⬜ A3: `bank.ruud_names`, `move_cards` (if not already coming); Monday's line as a 19:41 text.
4. ⬜ A4: `name_a_date` with `{promise_date}` and `promise`; the callback promise recorded (P2).
5. ⬜ §2 rows 1–6, 9–20 (P1), 21–27 (opener limits), 28–30 (`{jongen_meid}`, with the UI agent's token).
6. ⬜ §2 rows 7–8, 31–40 (P2–P3), §2.9 Rachid's days.
7. ⬜ Re-run `test_dialog_routes.gd` (all rewrites keep tags and `via`, so the ratchet should not move) and T1/T2/T8 in `build_content.py --check`.
8. ⬜ Designer: re-audit the landed file against this list (next pass), with the route numbers.

## 6. Claude's calls (for PLAN §10)

1. **Audit the work in progress** (the builder's worktree file at 16:35) rather than wait: D9 had not landed, and early fixes are cheaper.
2. **Open Revisie & GIS on Wednesday and Meetdata on Thursday of the training week**, and give Linda a planning desk in Aansluitingen, rather than moving the talks to other places.
3. **The tutorial week gives up its Act I reveals:** Linda's Wednesday gets a new, smaller concern; Act I keeps the buffer.
4. **Relative dates in mevrouw El Amrani's notebook** ("drie weken geleden, dinsdag, kwart over tien"), and `{aanvraag_datum}` for the request; the letter is signed F. El Amrani.
5. **No line in an always-reachable talk may name what only an optional talk revealed** (Rachid's list).
6. **`{jongen_meid}`** joins the player tokens for Henk.

---

## § Re-audit (batch 1+2), 2026-10-16 19:30 UTC

**What was read.** Batch 1 (the Act 0 week) on origin at `9acf607` and batch 2 (Acts I–II, local `55c7d4b`), both merged into this worktree; and, because the builder is applying the checklist on top, its uncommitted `content/dialogs.yaml` as of 18:54 UTC (read only, snapshot in the designer's scratchpad). **Batch 1+2 as committed is byte-identical to the 16:35 snapshot the first pass audited:** the same 19 people and 36 talks (batch 2's "ten new people, fifteen persuasion talks, six check-ins" are the ones already scored in §3). So no committed talk is new to this audit; this pass checks the fixes and goes one level deeper on batch 2 (tells per person, lines that assume a move, repeats inside a talk).

**Route numbers: not run.** This worktree has no `.godot` import cache, so `route_check.gd` first needs a full `--import` (character glbs, 63 explainer SVGs), then a width-300 beam search over the tier's talks, on a machine at load ~8 on 4 cores: well past the 20-minute limit. Every fix below and in §2 keeps the line's `tags`, `tell` and the layer's `via` (new lines are untagged, like the bank's), so the builder's `test_dialog_routes.gd` (`TIER1_RATCHET`) remains the judge and should not move.

### R1. Status of the first pass's items

"Committed" = in batch 1+2; "builder WIP" = in the builder's uncommitted file at 18:54.

| Item | Committed | Builder WIP | Still to do |
|---|---|---|---|
| **A1** rooms for Mieke/Petra, a place for Linda, bodies for Rachid/Mieke/Linda | ❌ | ❌ (`world.yaml`, `cast.json` unchanged) | **all of it: P0.** The week's Wednesday and Thursday talks still cannot be opened. |
| **A2** `training_mon` must stay open until `anouk_seven` | ❌ | ❌ (`missions.yaml` unchanged) | **P0** (with the 2.7d build) |
| **A3** `bank.ruud_names`, `move_cards` | ❌ | ✅ both, texts as specced, cards on the shifted days | commit; Monday's line as Ruud's 19:41 text is the UI's (2.7d) |
| **A4** El Amrani promise | ❌ | ◐ the hard "half november" is gone: "Volgens de planning bent u over een week of zes aangesloten." / "Zes weken. Ik schrijf het op, met de datum van vandaag erbij." (a good line: she notes the day) | **P1:** still recorded nowhere. Minimum now: the agreed fact plus the talk's day, so 2.4b can check "six weeks from that day"; log the check under 2.4b. |
| §2.1 repeated reveals #1–#8 | ❌ | ✅ all eight | commit |
| §2.2 claims about the player #9–#12 | ❌ | ✅ | commit |
| §2.3 experience lines #13–#16 | ❌ | ✅ | commit |
| §2.4 Sanne's Friday worry #17 | ❌ | ✅ | commit |
| §2.5 El Amrani #18, #19 | ❌ | ✅ | commit |
| §2.5 #20 `{aanvraag_datum}` | ❌ | ❌ still "Aangevraagd op 27 juli. Ontvangstbevestiging op 3 augustus" | **P1**, or keep "27 juli" only if the followed order is made 27 July (1.8a) |
| §2.6 opener limits #21–#27 | ❌ | ✅ compliance "Prima." 6/29, lifted "Weet je wat" 2/7, commitment "Afgesproken." 7/29: all within T1/T2 | commit |
| §2.7 Henk's "jongen" #28–#30 | ❌ | ❌ | **P1**, with the `{jongen_meid}` token (UI agent, 2.7b) |
| §2.7 #31–#36 | ❌ | ✅ (#35: Rachid's `teaches` removed) | commit |
| §2.8 #37–#39 appointments | ❌ | ✅ | commit |
| §2.8 #40 Sanne's Monday walk paid off | ❌ | ❌ | P2 |
| §2.9 Rachid Tue–Thu | ❌ | ❌ | P2 |

**In one line:** the builder's WIP fixes 33 of the 40 line-level items and A3. Open: **A1 and A2 (P0, both outside `dialogs.yaml`)**, A4's record, #20, #28–#30, #40, §2.9. Nothing in batch 1+2 as committed carries a fix yet.

### R2. Batch 2, second look

**Tells per person** (needs spec N5: at least three per person), counted on the builder's file: everyone has 3–4 except **Gert, Femke and Thomas (2 each)**. Every tell matches its person's need. A third tell each, as an authored reply, untagged (route-neutral, like the bank's replies):

| Talk | Add | Line (Dutch) |
|---|---|---|
| `gert_klic` (safety) | `replies.open_question.lands` | `{text: "Mijn jongens graven waar de kaart zegt dat het kan. Klopt die kaart niet, dan sta ík er straks naast. Niet jullie.", tell: safety}` |
| `femke_triage` (time) | `replies.mood.lands` | `{text: "Hoe het gaat? Ik heb vanochtend drie keer koffie gehaald. Drie keer koud laten worden. Zo gaat het.", tell: time}` |
| `thomas_reclaim` (fairness) | `replies.open_question.lands` | `{text: "Ik verkoop die mensen al twintig jaar zekerheid. Nu moet ik ze bellen dat die zekerheid tijdelijk was. Dat vind ik niet netjes.", tell: fairness}` |

**"Je bent de eerste die vraagt…": a heard formula, and three of them assume a move.** Seven of the 36 `heard` lines are "(Je/Jij/U) bent de eerste die …" (`joost_vacancies`, `petra_batch`, `henk_camera`, `linda_replanning`, `gert_klic`, `mieke_redraw`, `rob_order_rule`), plus Esra's "Fijn dat iemand een keer vraagt…". T1 cannot see it, because each opener runs to a different first comma. Most are fair (a talk that ends *heard* got close to that topic). Three claim a question the player may never have asked ("hoe het met ze gaat": a mood move): rewrite those three, which also breaks the formula.

| # | Where | As committed | Replace with |
|---|---|---|---|
| 41 | `joost_vacancies` heard | "Je bent de eerste die vraagt hoe het met ze gaat in plaats van hoeveel ze maken." | "Eerlijk is eerlijk: dat had ik nog tegen niemand gezegd. Ook niet tegen mijn team." |
| 42 | `esra_agents` heard | "Fijn dat iemand een keer vraagt hoe het met ze gaat." | "Oké. Het is eruit. Mijn mensen weten niet dat ik zo over ze praat, hè. Laat dat zo." |
| 43 | `gert_klic` heard | "Je bent de eerste van Voltana die vraagt hoe het met mijn jongens gaat." | "Je laat me tenminste uitpraten. Dat doet jullie schadeafdeling niet." |

**A line said twice in one talk.** `esra_agents`: the proposal `status_messages` replies "… Werkvoorbereiding weet zelf niet eens wanneer iets klaar is." and her `open_question` reply opens "Kijk, Werkvoorbereiding weet zelf niet wanneer iets klaar is…". A player who asks and then proposes hears it twice.

| # | Where | As committed | Replace with |
|---|---|---|---|
| 44 | `esra_agents` proposal `status_messages` reply | "Dan bellen ze niet. … Als het bericht klopt. Werkvoorbereiding weet zelf niet eens wanneer iets klaar is." | "Dan bellen ze niet. … Als het bericht klopt. Een bericht dat niet klopt, is een telefoontje extra." |

**Checked, no finding:** voices against the sheets (§6 of the four-tier audit) for the ten new people (Marco "mijn mannen"/"Kijk.", Esra "Serieus?"/"Deal.", mevrouw El Amrani's notebook, Henk's years, Dirk's fewest words, Gert "volgens de kaart", Femke "kort gezegd", Rob's *u* and "Conform.", Thomas's lunches, Ilse's ovens); no repeated reveal between batch 2 talks (Mieke's and Gert's graafschade lines are two sides of one event, which is intended); needs match the person-needs spec for all ten; the sector content stands as in §4.

### R3. Scores after the builder's WIP

With the WIP fixes, every talk scored under 25 in §3 now scores **26 or higher on the page**: `linda_wednesday` 27, `sanne_friday` 28, `petra_batch` 28, `marco_day_100` 27; `el_amrani_fourth_call` 28 (not 31: the promise is still unrecorded, Correct 3). With #41–#44, `joost_vacancies` 30, `esra_agents` 30, `gert_klic` 29. **Three Act 0 talks are still unplayable until A1 lands**, whatever their score.

### R4. Checklist update for the builder

1. ⬜ **Commit the WIP fixes** (33 items and A3).
2. ⬜ **A1** (`world.yaml`: `training_wed` opens Revisie & GIS, `training_thu` opens Meetdata, `connections.planning` goes into the Aansluitingen room; `cast.json`: Rachid, Mieke, Linda; the reachability test). **A2** (`training_mon` open until Anouk's talk).
3. ⬜ A4's record (agreed fact plus day); #20; #28–#30 once `{jongen_meid}` exists; #41–#44; the three tells.
4. ⬜ P2: #40, §2.9.
5. ⬜ Run `test_dialog_routes.gd` after 1–3 (expected unchanged) and T1/T2/T8 in `--check`.
6. ⬜ Designer: the third pass once 1–3 land, with route numbers if a worktree with an import cache is free.
