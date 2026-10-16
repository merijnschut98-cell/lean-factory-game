# Act 0 tutorial talks: the eight MORE PIES moves, one or two a day

> Status: by the mission and dialog design agent (Claude, 2026-10-16), PLAN §4.3.7. **Docs only, content-ready:** the YAML below uses the schema `content/dialogs.yaml` has since the engine merge (proposals with `name`/`text`/`reply`; `lines` as move → the player's line; `replies` as move → `lands`/`misses`/`too_early`). Two new keys, `teaches` and `ruud_names`, are listed in §5 for the builder.
>
> Read with: CLAUDE.md §2 ("Dialogs are give and take"; MORE PIES); PLAN §4.3.7 (tutorial talks: Act 0, cannot be ruined, the eight moves by name, one or two a day, Ruud names the move the player used well, never again after Act 0); the dialog spec; the Acts 0–II scripts §5 (Anouk's two talks, which this doc adopts and rebuilds in the content schema); the four-tier audit §6 (voices) and §4.4 (route variety); `content/missions.yaml` (`training_mon` … `training_fri`).

## 0. Summary

> **Schedule change (2026-10-16, `2026-10-16-first-five-minutes.md` §4.2):** the arrival Monday now holds one talk, `anouk_seven` at 19:00 (Stemming peilen), the first talk of the game. `sanne_monday` becomes `sanne_tuesday` (Tuesday 08:30, Open vraag, re-dated opening); `rachid_monday` becomes an optional walk-around talk (Tuesday–Thursday); `mieke_tuesday` becomes `mieke_wednesday` (Samenvatten moves to Wednesday's card). The table below is the original schedule; the talks' texts and routes are unchanged apart from the re-dated lines.

> **Person needs (2026-10-16, `2026-10-16-person-needs.md`):** every person here has a hidden `need`, and the week now teaches *reading a person* as well as the eight moves: a tell in each talk's position, Rachid as the week's fairness person, a contrast on Wednesday, a Friday card and a closing question from Ruud. All changes are listed in §7.

- **Ten talks across the training week, two a day.** Each day introduces one or two moves by name, on a card in Ruud's morning briefing, and each talk is written so that the day's move is *one* good way through, never the only one:

  | Day | Mission | Moves of the day | Talk 1 | Talk 2 |
  |---|---|---|---|---|
  | Maandag | `training_mon` Rondleiding | **Stemming peilen**, **Open vraag** | `sanne_monday` (Intake) | `rachid_monday` (Intake) |
  | Dinsdag | `training_tue` Kijken zonder oordeel | **Begrip tonen**, **Samenvatten** | `anouk_first_look` (Werkvoorbereiding) | `mieke_tuesday` (Revisie & GIS) |
  | Woensdag | `training_wed` Waar zit de stapel? | **Doorvragen**, **Gevoel benoemen** | `joost_wednesday` (Werkvoorbereiding) | `linda_wednesday` (Planning) |
  | Donderdag | `training_thu` Een klein experiment | **Stilte laten**, **Ervaring delen** | `anouk_thursday` (Werkvoorbereiding) | `petra_thursday` (Meetdata) |
  | Vrijdag | `training_fri` Borgen of laten wegzakken | all eight, no new one | `anouk_owns_tray` (Werkvoorbereiding) | `sanne_friday` (Intake) |

- **All ten are `tutorial: true`:** openness never falls below 10, patience is 12, and no talk can be ruined. Pushing still costs; it just never ends the talk. The player learns the meter where nothing is lost.
- **Ruud names one move after each talk**, the one the player used well, by its chip name (§3). He never names a move that went wrong, never names a move after Act 0, and asks a question instead when nothing landed.
- **Every talk is a small piece of the week's lesson:** Sanne's Monday is failure demand in a sentence; Rachid's is the incomplete form seen from the newest desk; Mieke's is work done twice; Joost's is the stack nobody asked about; Linda's is the plan that is always full; Anouk's Thursday is the fear of an experiment; Petra's is the batch. Act I then picks these threads up.
- **The cast grows by meeting people as people first:** six of the ten persons return in Act I with a harder talk. A player who listened in Act 0 starts those talks higher (memory `heard` +10, `committed` +15; dialog spec §3.6). Respect earlier pays later, from week one.

---

## 1. Design rules for the tutorial talks

1. **One or two moves a day, by name.** The morning card names the move and says what it is for, in one sentence, with no hint of when to use it in today's talk (§2). The chips are the usual fixed palette: all moves always visible, nothing highlighted (decided 2026-10-15). The card teaches the word; the talk teaches the moment.
2. **The day's move is a good way, not the way.** Each talk's routes (comments) show at least three winning sequences. At least one of them does not use the day's move. A player who already listens well is never forced into the lesson.
3. **Low stakes, real people.** No talk asks for a decision that matters to the simulation. The proposals are small requests ("Mag ik een uur meekijken?"). The concerns are true workplace fears, small enough for a first week.
4. **Unruinable, but still honest.** Pushing early costs openness (−12) and the person closes; the `warning` line comes (R-D3) and the floor at 10 holds. The summary card shows the trace like any other talk.
5. **Ruud names, then stops.** After Friday he never names a move again (PLAN §4.3.7). From Act I he asks (dialog spec §5.6).
6. **No false experience.** The player's *Ervaring delen* lines are about this week at Voltana, the only experience the game knows the CI lead has (Acts 0–II audit F9).

---

## 2. The eight move cards

Shown on the morning briefing of the day the move is introduced, and kept in the codex under *Gesprekken*. Each card: the chip name, what the move does, and one line of why. No card says when a move fails; the talk shows that.

```yaml
move_cards:
  - {move: mood, day: training_mon, title: "Stemming peilen",
     text: "Je vraagt hoe het met iemand gaat, en je bedoelt het. Vroeg in een gesprek, of als iemand er moe of gespannen uitziet.",
     why: "Wie zich gezien voelt, praat anders."}
  - {move: open_question, day: training_mon, title: "Open vraag",
     text: "Een vraag waar geen ja of nee op past. 'Hoe ziet jouw week eruit?' in plaats van 'Is het druk?'",
     why: "Het verhaal zit in wat iemand zelf kiest te vertellen."}
  - {move: empathy, day: training_tue, title: "Begrip tonen",
     text: "Je laat merken dat je snapt dat iets zwaar is, zonder het op te lossen.",
     why: "Iets erkennen is iets anders dan het eens zijn."}
  - {move: paraphrase, day: training_tue, title: "Samenvatten",
     text: "Je zegt in je eigen woorden terug wat de ander zei. Kort.",
     why: "Pas als iemand weet dat je het gehoord hebt, luistert hij naar jou."}
  - {move: inquiry, day: training_wed, title: "Doorvragen",
     text: "Je vraagt door op één woord of één getal dat de ander noemde. 'Wat bedoel je met druk?'",
     why: "Het eerste antwoord is zelden het hele antwoord."}
  - {move: reflect, day: training_wed, title: "Gevoel benoemen",
     text: "Je zegt het gevoel dat je hoort: 'Het klinkt alsof je klem zit.' Zit je ernaast, dan zegt de ander dat. Ook dat helpt.",
     why: "Een gevoel dat iemand benoemd hoort, hoeft niet meer bewezen te worden."}
  - {move: silence, day: training_thu, title: "Stilte laten",
     text: "Je zegt niets en wacht. Vooral als iemand aarzelt.",
     why: "Wie de stilte opvult, neemt het woord terug."}
  - {move: experience, day: training_thu, title: "Ervaring delen",
     text: "Je vertelt kort iets van jezelf dat lijkt op wat de ander meemaakt. Echt gebeurd, en over jou.",
     why: "Twijfel wordt kleiner als iemand anders hem ook kent. Te vroeg, en het gaat over jou."}
  - {move: null, day: training_fri, title: "Wie zit er tegenover je?",       # person needs §7: the skill, never the needs
     text: "Dezelfde zet landt bij de één hard en bij de ander nauwelijks. Wat iemand zelf zegt, en hoe, vertelt je wat hij nodig heeft. In je journaal, onder Mensen, staat wat jij hebt gehoord.",
     why: "Wie eerst kijkt wie er zit, hoeft daarna minder te raden."}
```

---

## 3. Ruud names the move

After each tutorial talk ends, Ruud's line appears on the summary card ("Ruud kwam even langs" on Monday; from Tuesday a short message on the phone).

**The rule** (`ruud_names`, §5):
1. If the day's move landed (its Δ was positive) at least once, he names it.
2. Else, if the concern was revealed, he names the move that revealed it.
3. Else, if any listening move landed, he names the one that landed most.
4. Else he asks: "Wat zag je aan {person} toen je begon?" (a question, no name).

He names one move. He never names one that missed, never names a steering move, and never says what the player should have done.

```yaml
bank:
  ruud_names:                              # Act 0 only; {person} is the person's short name
    mood: "Je vroeg eerst hoe het met {person} ging. Dat heet Stemming peilen. Daarna praatte {person} anders. Zag je dat?"
    open_question: "Je stelde een vraag waar geen ja of nee op past. Een Open vraag. Toen kwam het verhaal, niet het antwoord."
    empathy: "Je zei dat het niet niks is. Begrip tonen. Je hoefde het niet op te lossen om het te erkennen."
    paraphrase: "Je zei in je eigen woorden terug wat {person} zei. Samenvatten. Vanaf dat moment wist {person} dat je luisterde."
    inquiry: "Je vroeg door op precies dat ene woord. Doorvragen. Daar zat het."
    reflect: "Je zei wat {person} voelde, niet wat {person} zei. Gevoel benoemen. Wat gebeurde er daarna?"
    silence: "Toen {person} aarzelde, zei je niets. Stilte laten. Dat is het moeilijkste wat er is."
    experience: "Je vertelde iets van deze week, toen {person} twijfelde. Ervaring delen. Kort, en over jou."
    none: "Wat zag je aan {person} toen je begon?"
    week_end: "Acht manieren van luisteren, in vijf dagen. Vanaf maandag noem ik ze niet meer. Eén vraag voor het weekend: wat werkte bij de één en niet bij de ander? Waar zag je dat aan?"
```

`week_end` is Ruud's last naming line, on Friday after the second talk. It marks the change: from Act I he asks (`bank.coach`, dialog spec §5.6).

---

## 4. The ten talks

People not yet in `content/dialogs.yaml`:

```yaml
people:
  - {id: sanne, name: Sanne Bakker, short: Sanne, role: teamleider Intake, place: connections.intake, team: intake,
     archetype: overloaded, need: recognition, trust: 50, morale: 55, voice: "We zijn een postkantoor geworden."}
  - {id: rachid, name: Rachid Ouali, short: Rachid, role: medewerker Intake, place: connections.intake, team: intake,
     archetype: quiet, need: fairness, trust: 50, morale: 60, voice: "Ik vraag het wel even na."}
  - {id: anouk, name: Anouk de Vries, short: Anouk, role: werkvoorbereider, place: connections.design, team: work_prep,
     archetype: overloaded, need: safety, trust: 50, morale: 50, voice: "Ik zit erbovenop."}
  - {id: mieke, name: Mieke van der Veen, short: Mieke, role: tekenaar Revisie & GIS, place: connections.revision, team: gis,
     archetype: craftsman, need: recognition, trust: 50, morale: 55, voice: "We tekenen zo snel als we kunnen."}
  - {id: linda, name: Linda Jansen, short: Linda, role: planner, place: connections.planning, team: planners,
     archetype: overloaded, need: time, trust: 50, morale: 45, voice: "Ik plan iedereen. Behalve mezelf."}
  - {id: petra, name: Petra Vos, short: Petra, role: Meetdata & registratie, place: connections.close_out, team: meter_office,
     archetype: defender, need: facts, trust: 50, morale: 55, voice: "Alles klopt. Tot op de laatste EAN."}
```

Needs per the person-needs spec §2 (Joost: `safety`, added to his entry in `content/dialogs.yaml`). (Joost is in content already. Rachid is new as a dialog target; the Acts 0–II scripts named him in lines and gave him a walk-around check-in, `rachid_new`.)

Starts follow the spec §3.6 (archetype base + mood + team trust + trust + morale + memory). Route comments use the built engine's rules (dialog spec §3.3 with the merge's calls: `inquiry` reaches 15 below a threshold; a layer opens only on a move that landed; the lead-in follows a landing listening move at openness ≥ 65).

### 4.1 Maandag: Stemming peilen, Open vraag

```yaml
dialogs:
  - id: sanne_monday
    name: Sanne op maandagochtend
    person: sanne
    kind: persuade
    mission: training_mon
    tutorial: true
    teaches: [mood]
    mood: moe                                # Monday morning, the weekend's applications
    patience: 12
    # start: overloaded 35 - 10 (moe) + 0 + 0 + 0 (morale 55) = 25, Op z'n hoede
    opening: "Goedemorgen. Jij bent de nieuwe? Sorry, ik heb drie telefoons en een bak die overloopt. Wat kan ik voor je doen?"
    position: {text: "Het is maandag. Maandag is altijd zo. Alles wat in het weekend binnenkwam, plus wat vrijdag bleef liggen. Maar dat ziet boven niemand, hè.", tags: [claim], tell: recognition}
    layers:
      - id: interest
        at: 45
        via: [mood, empathy, open_question]
        text: "Kijk, deze. Een warmtepomp, geen foto van de meterkast. Die stuur ik terug. Over drie weken komt hij weer binnen, met een boze klant aan de telefoon. Iedereen denkt dat Intake een postkantoor is. Stempel erop, door."
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [silence, empathy, reflect]
        lead_in: {text: "En als ik eerlijk ben…", tags: [hesitation]}
        text: "Ik ben hier vijftien jaar. Ik weet precies welke aanvragen terugkomen. Maar niemand vraagt het me. Ze tellen alleen hoeveel ik er doorzet."
        tags: [admission]
        unlocks:
          facts: [heard:sanne_monday]
          proposals: [sanne_shows_the_returns]
    proposals:
      - {id: come_back_later, name: Later terugkomen, text: "Ik zie dat het nu niet uitkomt. Mag ik vanmiddag terugkomen, als de telefoons rustiger zijn?",
         addresses: [concern], reply: "Na drieën. Dan is het hier stil. Kom maar."}
      - {id: sit_and_watch, name: Een uur meekijken, text: "Mag ik een uur naast je zitten? Ik wil zien hoe een aanvraag binnenkomt, niet controleren hoe snel.",
         addresses: [concern], reply: "Zien hoe het binnenkomt. Ja. Dat mag."}
      - {id: sanne_shows_the_returns, name: Laat zien welke terugkomen, hidden: true,
         text: "Wil je me laten zien welke aanvragen terugkomen? Jij weet het. Ik niet.",
         addresses: [concern], reply: "De terugkomers. Ik heb ze op een stapel. Niemand heeft er ooit naar gevraagd. Kom maar kijken."}
    co_proposal: {id: sanne_shows_the_returns, text: "Weet je wat. Ik leg de terugkomers van vorige week apart. Dan zie je het zelf."}
    lines:
      mood: "Hoe begint jouw week, eigenlijk?"
      open_question: "Wat komt er op een maandag allemaal binnen?"
      empathy: "Drie telefoons en een volle bak, op maandagochtend. Dat is ook wat."
    replies:
      mood:
        lands: {text: "Hoe mijn week begint? Met koffie die koud wordt. … Fijn dat je het vraagt, eigenlijk.", tags: [feeling]}
    outcomes:
      commitment: "Kom maar. Na drieën. Neem koffie mee, die van ons is op."
      partial: "Goed. Maar niet vandaag, hè. Vandaag is maandag."
      heard: "Joh. Fijn dat je eerst vroeg hoe het ging. Dat doet niemand op maandag."
      none: "Ik moet echt verder. Sorry."
      compliance: "Prima. Als Ruud het zegt."
      ruined: "Ik moet echt verder."
    # routes (start 25):
    #   A (the day's move): mood x1.5 +12 37 > open_question +6 43 > empathy +6 49 (interest, a feeling) > paraphrase +7 56 (heard)
    #     > reflect +10 66 (lead-in) > silence +12 > 74 capped (concern) > propose sanne_shows_the_returns +8 > ask: commitment (8 moves)
    #   B (no mood): open_question 31 > paraphrase 38 (heard) > empathy 44 > open_question 50 (interest) > reflect 60 > inquiry 68 (lead-in)
    #     > silence (concern) > propose sit_and_watch > ask (9 moves)
    #   C: mood > paraphrase > empathy (interest) > reflect > open_question (lead-in) > empathy (concern) > propose come_back_later > ask (8 moves)
    # the lesson: on a tired Monday, asking how she is lands twice as hard as a question about work (overloaded x1.5).
    # Ruud names: mood if it landed; else the move that revealed the concern.

  - id: rachid_monday
    name: Rachid aan de balie
    person: rachid
    kind: persuade
    mission: training_mon
    tutorial: true
    teaches: [open_question]
    patience: 12
    # start: quiet 47 + 0 + 0 + 0 + 0 = 47, Luistert
    opening: "O. Hoi. Ik ben Rachid. Sanne zegt dat ik je de bakken moet laten zien."
    position: {text: "Links wat binnenkomt, rechts wat compleet is. Wat in het midden ligt, daar mist iets. Meestal niet door ons, hoor.", tags: [claim], tell: fairness}
    layers:
      - id: interest
        at: 52
        via: [open_question, mood, silence]
        text: "In het midden ligt het meest. Meestal mist er een foto van de meterkast. Of het vermogen klopt niet met wat de installateur schreef. Ik bel ze dan na. Soms drie keer."
        tags: [claim]
      - id: concern
        at: 66
        via: [silence, open_question, empathy]
        lead_in: {text: "Het is alleen…", tags: [hesitation]}
        text: "Ik werk hier vier maanden. Als ik iets doorzet wat niet klopt, komt het terug met mijn naam erop. Dus ik bel liever drie keer. Maar dan duurt het lang. En dat is ook mijn naam."
        tags: [admission, doubt]
        unlocks:
          facts: [heard:rachid_monday]
          proposals: [rachid_shows_his_list]
    proposals:
      - {id: watch_one_call, name: Eén belletje meeluisteren, text: "Mag ik meeluisteren als je de volgende installateur belt?",
         addresses: [concern], reply: "Meeluisteren. Ja. Als je niet zegt dat ik het fout doe."}
      - {id: count_the_middle, name: De middelste bak tellen, text: "Mag ik vanmiddag tellen wat er in de middelste bak ligt, en waarom?",
         addresses: [interest], reply: "Tellen mag. Ik weet ook niet precies hoeveel het er zijn."}
      - {id: rachid_shows_his_list, name: Zijn eigen lijstje, hidden: true,
         text: "Heb je zelf bijgehouden wat er het vaakst mist?",
         addresses: [concern], reply: "Ik heb een lijstje. In mijn la. Foto meterkast, vermogen, handtekening. Ik dacht dat dat stom was."}
    co_proposal: {id: rachid_shows_his_list, text: "Ik heb een lijstje in mijn la. Wat er mist. Wil je dat zien?"}
    lines:
      open_question: "Wat gebeurt er met wat in de middelste bak ligt?"
      mood: "Hoe bevalt het, vier maanden hier?"
      silence: "(je kijkt mee naar de bakken en wacht)"
    outcomes:
      commitment: "Morgen leg ik het lijstje op tafel. Als Sanne het goedvindt. Ze vindt het vast goed."
      partial: "Misschien. Ik vraag het Sanne."
      heard: "Oké. Dank je. Niemand vraagt wat er in het midden ligt."
      none: "Ik moet weer bellen."
      compliance: "Oké."
      ruined: "Ik moet weer bellen."
    # routes (start 47):
    #   A (the day's move): open_question +6 53 (interest) > open_question +6 59 > paraphrase +7 66 (heard; lead-in) > silence x1.5 +18 > 75 capped (concern)
    #     > propose rachid_shows_his_list > ask: commitment (6 moves)
    #   B: mood +8 55 (interest via mood) > paraphrase 62 (heard) > empathy 68 (lead-in) > silence (concern) > propose watch_one_call > ask
    #   C: silence (misses: the position is no hesitation, -4) 43 > open_question 49 > ... the quiet one forgives a silence; then as A.
    # Ruud names: open_question if it landed.
```

### 4.2 Dinsdag: Begrip tonen, Samenvatten

`anouk_first_look` is the Acts 0–II scripts' talk (§5 there), rebuilt in the content schema, with `teaches: [empathy]`. Its route already leads through *Begrip tonen* at the lead-in.

```yaml
dialogs:
  - id: anouk_first_look
    name: Anouk en de stopwatch
    person: anouk
    kind: persuade
    mission: training_tue
    tutorial: true
    teaches: [empathy]
    patience: 12
    # start: overloaded 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "O, hoi. Sorry, het is een beetje een bende. Drie collega's zitten op cursus."
    position: {text: "Het is gewoon druk deze week. Ik zit erbovenop, echt. Je hoeft het niet op te schrijven.", tags: [claim], tell: safety}
    layers:
      - id: interest
        at: 45
        via: [empathy, mood, open_question]
        text: "Achter elk dossier zit iemand die wacht. Een gezin, een bakker, een school. Dus ik wil het niet laten liggen."
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [reflect, empathy]
        lead_in: {text: "Het is alleen… ik word er zenuwachtig van. Sorry.", tags: [feeling, hesitation]}   # feeling cue; drop hesitation once the validator allows (PLAN 1.6a)
        text: "Iedereen komt kijken als het druk is. Met een stopwatch. En dan denk ik: nu zien ze hoe langzaam ik ben."
        tags: [admission]
        unlocks:
          facts: [heard:anouk_first_look]
          proposals: [come_at_eight]
    proposals:
      - {id: sit_beside, name: Een uur meekijken, zonder oordeel, text: "Mag ik een uur naast je zitten? Ik kijk naar het werk, niet naar jou.",
         addresses: [concern], reply: "Naar het werk. Oké. Dat… is eigenlijk wel fijn."}
      - {id: stopwatch, name: Je werk timen, text: "Ik wil even timen hoe lang een ontwerp duurt.",
         addresses: [], reply: "Timen. Dus toch."}
      - {id: come_at_eight, name: Morgen om acht uur, hidden: true, text: "Mag ik morgen om acht uur komen, als de dag begint?",
         addresses: [concern], reply: "Kom maar. Dan zie je hoe het begint: koffie, de twee bakken, en dan zoeken."}
    co_proposal: {id: come_at_eight, text: "Kom morgen om acht uur. Dan zie je hoe het begint: koffie, de twee bakken, en dan zoeken."}
    lines:
      empathy: "Alleen met vier mensen werk, terwijl de rest op cursus zit. Dat is ook niet niks."
      reflect: "Het klinkt alsof je je bekeken voelt."
    outcomes:
      commitment: "Kom maar. Ik zet koffie. Slechte koffie, maar koffie."
      partial: "Goed. Maar zonder stopwatch, hè."
      heard: "Fijn dat je eerst vroeg. Dat doet niet iedereen."
      none: "Ik moet echt door. Sorry."
      compliance: "Oké. Als het moet."
      ruined: "Ik moet echt door."
    # routes (start 35): mood x1.5 +12 47 (interest) > paraphrase +7 54 (heard) > empathy +6 60 > reflect +10 (interest is a feeling) 70 (lead-in)
    #   > empathy (concern; +10 after the admission next) > propose sit_beside > ask (7 moves). Without empathy: reflect at the lead-in reveals it too.
    # the lesson: the stopwatch is the gemba tool the player was just given. Asked for bluntly, it scares the person it measures.

  - id: mieke_tuesday
    name: Mieke en de schetsen
    person: mieke
    kind: persuade
    mission: training_tue
    tutorial: true
    teaches: [paraphrase]
    patience: 12
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Kom je voor de revisie? Dan moet je hier zijn. Pas op de doos."
    position: {text: "Dit zijn de schetsen van de monteurs. Wat ze in de grond hebben gelegd. Wij tekenen het over in GIS. 'Overtekenen', noemen ze het boven. Zo snel als we kunnen.", tags: [claim], tell: recognition}
    layers:
      - id: interest
        at: 50
        via: [paraphrase, inquiry, open_question]
        text: "Een schets is een begin. Er staat een mof op, maar niet hoe diep. Een kabel, maar niet welke kant hij op buigt. Dat moet ik uitzoeken. Bellen, foto's zoeken, soms zelf gaan kijken."
        tags: [claim]
      - id: concern
        at: 68
        via: [paraphrase, silence, inquiry]
        lead_in: {text: "Alleen, kijk…", tags: [hesitation]}
        text: "Als wij een kabel verkeerd intekenen, graaft er straks iemand doorheen. Dan wijst iedereen naar GIS. Niet naar de schets met de pindakaasvlek."
        tags: [admission]
        unlocks:
          facts: [heard:mieke_tuesday]
          proposals: [show_the_worst_sketch]
    proposals:
      - {id: look_at_one, name: Eén schets samen bekijken, text: "Mag ik er één met je doorlopen, van schets tot tekening?",
         addresses: [concern], reply: "Eén. Dan zie je waarom het geen vijf minuten is."}
      - {id: count_the_box, name: De doos tellen, text: "Mag ik tellen hoeveel er in de doos zitten, en hoe oud ze zijn?",
         addresses: [interest], reply: "Tel maar. Het zijn er meer dan je denkt."}
      - {id: show_the_worst_sketch, name: De slechtste schets, hidden: true, text: "Laat me de slechtste schets zien die je deze maand kreeg.",
         addresses: [concern], reply: "De slechtste. … Hier. Op een boterhamzakje. Met een pindakaasvlek precies op de mof."}
    co_proposal: {id: show_the_worst_sketch, text: "Wil je de slechtste zien? Dan snap je het meteen."}
    lines:
      paraphrase: "Dus een schets vertelt je waar iets ligt, maar niet precies hoe. Dat stuk moet jij erbij zoeken."
      inquiry: "Wat moet je dan uitzoeken, bij zo'n schets?"
    replies:
      paraphrase:
        lands: {text: "Precies. Dat zegt bijna niemand. Ze denken dat het overtekenen is.", tags: [claim], tell: recognition}
    outcomes:
      commitment: "Dat moet kloppen, dus kom donderdag terug. Dan heb ik de slechtste apart gelegd."
      partial: "Misschien later in de week. Als de doos kleiner is. Dat wordt hij niet."
      heard: "Fijn. Je bent de eerste die het niet 'overtekenen' noemt."
      none: "Ik moet verder met deze."
      compliance: "Goed."
      ruined: "Ik moet verder met deze."
    # routes (start 40): paraphrase +7 47 (heard) > inquiry x1.5 +12 59 (interest) > paraphrase +7 66 (lead-in) > paraphrase (repeat x0.5; reveals: in via) > propose look_at_one > ask (6 moves)
    #   other: open_question > inquiry (interest) > empathy > silence at the lead-in; or the co-proposal at Denkt mee.
    # the lesson: a craftswoman opens when you say back what her work is, in her terms. Ruud names paraphrase if it landed.
```

### 4.3 Woensdag: Doorvragen, Gevoel benoemen

```yaml
dialogs:
  - id: joost_wednesday
    name: Joost en de stapel
    person: joost
    kind: persuade
    mission: training_wed
    tutorial: true
    teaches: [inquiry]
    patience: 12
    # start: defender 40 + 0 + 0 + 0 + 0 (morale 50) = 40, Luistert
    opening: "Je komt de stapel tellen, hoorde ik. Even voor de duidelijkheid: we halen ons doel."
    position: {text: "Drie van de vier zitten op cursus. Dan ligt er meer. Dat is gewoon een feit, geen probleem. En als dit naar Frank gaat, wil ik het eerst zien.", tags: [claim], tell: safety}
    layers:
      - id: interest
        at: 52
        via: [inquiry, paraphrase, open_question]
        text: "Normaal haalt mijn team dertig ontwerpen per week. Deze week twaalf. Maar maandag zijn ze terug. Dan halen we het in. Dat doen we altijd."
        tags: [claim]
      - id: concern
        at: 68
        via: [inquiry, silence, empathy]
        lead_in: {text: "Al moet ik zeggen…", tags: [hesitation]}
        text: "Inhalen betekent overwerken. Anouk werkt nu al tot zeven uur. Ik zie het. Ik weet alleen niet wat ik anders moet doen dan zeggen dat het tijdelijk is."
        tags: [admission]
        unlocks:
          facts: [heard:joost_wednesday]
          proposals: [count_together]
    proposals:
      - {id: count_alone, name: Zelf de stapel tellen, text: "Ik tel straks wat er ligt, en hoeveel dagen werk het is.",
         addresses: [interest], reply: "Tel maar. Het getal klopt, dat beloof ik je."}
      - {id: count_together, name: Samen tellen, hidden: true, text: "Zullen we samen tellen? Niet hoeveel er ligt, maar hoe lang het oudste al ligt.",
         addresses: [concern], reply: "Het oudste. Hm. Dat heb ik nooit geteld. Goed. Om twee uur."}
      - {id: ask_anouk_first, name: Eerst Anouk vragen, text: "Mag ik Anouk vragen wat zij ziet, voordat ik iets tel?",
         addresses: [concern], reply: "Anouk. Ja. Vraag het haar. Zij weet het beter dan mijn Excel."}
    co_proposal: {id: count_together, text: "Tel het oudste dossier met me mee. Dan weet ik ook eens wat mijn Excel niet zegt."}
    lines:
      inquiry: "Wat bedoel je met 'inhalen'?"
      paraphrase: "Dus deze week ligt er meer, en maandag lossen jullie het op zoals altijd."
    replies:
      inquiry:
        lands: {text: "Wat ik bedoel met inhalen? … Dat is een goede vraag, eigenlijk.", tags: [hesitation]}
    outcomes:
      commitment: "Om twee uur. Ik print de lijst. Mijn Excel heeft meer tabbladen dan ik mensen heb."
      partial: "Tel eerst maar. Dan praten we."
      heard: "Eerlijk is eerlijk: niemand vraagt wat 'inhalen' kost."
      none: "Ik heb om elf uur overleg."
      compliance: "Prima. Tel maar."
      ruined: "Ik heb om elf uur overleg."
    # routes (start 40): paraphrase +7 47 (heard) > inquiry +8 55 (interest) > inquiry (x0.5) +4 59 > empathy +6 65 (lead-in) > inquiry (reveals) > propose count_together > ask (7 moves)
    #   other: open_question > paraphrase > inquiry (interest) > silence at the lead-in; or ask_anouk_first after the concern.
    # the lesson: the one word ("inhalen") hides the overtime. Ruud names inquiry if it landed.

  - id: linda_wednesday
    name: Linda en het kaartenhuis
    person: linda
    kind: persuade
    mission: training_wed
    tutorial: true
    teaches: [reflect]
    mood: moe
    patience: 12
    # start: overloaded 35 - 10 (moe) + 0 + 0 - 0 (morale 45 -> -1) = 24, Op z'n hoede
    opening: "Sorry, ik ben aan het omplannen. Twee monteurs zijn naar een storing. Zeg het maar."
    position: {text: "Dit gebeurt elke dag. Er is een storing, de monteurs gaan erheen, en ik plan alles om. Dat is mijn werk. Ik heb tot de volgende storing.", tags: [claim, feeling], tell: time}
    layers:
      - id: interest
        at: 45
        via: [reflect, empathy, mood]
        text: "Ik noem het het kaartenhuis. Elke ochtend bouw ik het op, en om tien uur waait er een storing doorheen. Dan bel ik twaalf klanten af. Die zijn boos op mij, niet op de kabel."
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [reflect, empathy]
        lead_in: {text: "Ik word er gewoon zo moe van. Sorry.", tags: [feeling, hesitation]}   # feeling cue; drop hesitation once the validator allows (PLAN 1.6a)
        text: "Als ik ruimte inplan voor storingen, zit er een monteur koffie te drinken als het rustig is. Dan zegt iedereen dat ik niet kan plannen. Dus plan ik vol. En dan valt het om. Elke dag."
        tags: [admission]
        unlocks:
          facts: [heard:linda_wednesday]
          proposals: [watch_one_morning]
    proposals:
      - {id: come_back_later, name: Later terugkomen, text: "Ik zie dat je bezig bent. Mag ik straks terugkomen?",
         addresses: [], reply: "Straks is het weer om. Maar goed."}
      - {id: count_the_reshuffles, name: Tellen hoe vaak het omvalt, text: "Mag ik deze week tellen hoe vaak je moet omplannen, en waarom?",
         addresses: [concern], reply: "Tellen. Dan zie je dat het niet aan mij ligt. … Toch?"}
      - {id: watch_one_morning, name: Eén ochtend meekijken, hidden: true, text: "Mag ik morgen om zeven uur naast je zitten, als je het kaartenhuis bouwt?",
         addresses: [concern], reply: "Om zeven uur. Dan zie je het voordat het omvalt. Ja."}
    co_proposal: {id: watch_one_morning, text: "Kom morgen om zeven uur. Dan zie je hoe het staat, en om tien uur hoe het valt."}
    lines:
      reflect: "Het klinkt alsof je elke ochtend iets opbouwt waarvan je al weet dat het omvalt."
      mood: "Hoe gaat het met je, zo halverwege de week?"
    replies:
      reflect:
        lands: {text: "Ja. Precies dat. Elke ochtend.", tags: [feeling]}
        misses: {text: "Nee, boos ben ik niet. Ik ben moe. Dat is anders.", tags: [feeling]}
    outcomes:
      commitment: "Zeven uur. Ik zet een stoel klaar. Die staat er toch, er zit nooit iemand op."
      partial: "Misschien. Als het morgen rustig is. Dat is het nooit."
      heard: "Dank je. Je zei het beter dan ik het zelf had kunnen zeggen."
      none: "Ik moet verder omplannen. Sorry."
      compliance: "Oké. Als het moet."
      ruined: "Ik moet verder omplannen. Sorry."
    # routes (start 24):
    #   A (the day's move): mood x1.5 +12 36 > reflect +10 46 (heard; interest) > empathy +6 52 > reflect +10 62 > paraphrase +7 69 (lead-in, a feeling)
    #     > reflect +10 > 74 capped (concern) > propose watch_one_morning > ask: commitment (8 moves)
    #   B: mood > empathy (interest) > paraphrase (heard) > open_question > empathy (lead-in) > empathy (concern) > propose count_the_reshuffles > ask
    #   a misread reflect costs 3, and her correction ("Ik ben moe. Dat is anders.") is itself a feeling: the next reflect lands.
    # the lesson: naming the feeling ("je weet al dat het omvalt") is what she has been waiting for. Ruud names reflect if it landed.
```

### 4.4 Donderdag: Stilte laten, Ervaring delen

```yaml
dialogs:
  - id: anouk_thursday
    name: Anouk en het experiment
    person: anouk
    kind: persuade
    mission: training_thu
    tutorial: true
    teaches: [silence]
    patience: 12
    # start: overloaded 35 + 0 + 0 + 0 + 0 + memory (10 heard, 15 committed on Tuesday) = 35-50
    opening: "Dus we gaan het proberen? Eén bak, oudste bovenop? Drie dagen?"
    position: {text: "Prima. Ik doe mee. Het is maar drie dagen. En verder hoeft niemand het te weten, toch?", tags: [claim], tell: safety}
    layers:
      - id: interest
        at: 48
        via: [empathy, open_question, mood]
        text: "Ik snap het wel. Als het oudste bovenop ligt, hoef ik niet te zoeken. Dat is logisch. Ik had het zelf kunnen bedenken."
        tags: [claim]
      - id: concern
        at: 65
        via: [silence, empathy, inquiry]
        lead_in: {text: "Maar…", tags: [hesitation]}
        text: "Als het werkt, zien ze dat ik al die tijd heb zitten zoeken. Twee jaar. Dan was ik dus de langzame. En als het niet werkt, was het mijn bak."
        tags: [admission, doubt]
        unlocks:
          facts: [heard:anouk_thursday]
          proposals: [it_is_the_tray]
    proposals:
      - {id: just_try, name: Gewoon proberen, text: "Het is een proef. Als het niet werkt, stoppen we.",
         addresses: [interest], reply: "Ja. Een proef."}
      - {id: it_is_the_tray, name: Het ligt aan de bakken, hidden: true, text: "Als het werkt, zegt dat iets over twee bakken, niet over jou. Jij zocht omdat het werk zo lag.",
         addresses: [concern], reply: "Over de bakken. Niet over mij. … Dat had ik zo nog niet bedacht."}
      - {id: we_present_together, name: Samen vertellen, text: "Vrijdag vertellen we samen wat we zagen. Wat er ook uitkomt.",
         addresses: [concern], reply: "Samen. Oké. Dan sta ik er niet alleen."}
    lines:
      silence: "(je knikt, en wacht)"
      empathy: "Twee jaar zoeken in twee bakken. Dat is ook wat."
    outcomes:
      commitment: "Goed. Eén bak. Oudste bovenop. En vrijdag kijken we samen."
      partial: "Ik doe het. Maar vrijdag zeg jij het, niet ik."
      heard: "Sorry. Ik wist niet dat ik dat ging zeggen."
      none: "Ik ga maar beginnen."
      compliance: "Oké."
      ruined: "Ik ga maar beginnen."
    # routes (start 35, no Tuesday history): empathy +6 41 > open_question +6 47 > empathy (x0.5) 50 (interest) > paraphrase +7 57 (heard) > mood (late: +2 x1.5) ...
    #   > reflect misses (no feeling) — better: inquiry +8 65 (lead-in "Maar…") > silence +12 > 74 capped (concern) > propose it_is_the_tray > ask (8 moves)
    #   with Tuesday's commitment (start 50): open_question (interest) > paraphrase > inquiry (lead-in) > silence (concern) > propose > ask (6 moves)
    #   other: empathy at the lead-in instead of silence (in via).
    # the lesson: after "Maar…", the player wants to reassure. Waiting is what lets her finish the sentence. Ruud names silence if it landed.

  - id: petra_thursday
    name: Petra en de Molen
    person: petra
    kind: persuade
    mission: training_thu
    tutorial: true
    teaches: [experience]
    patience: 12
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Meetdata en registratie. Jij bent de nieuwe van Ruud. Ga zitten, maar raak de map niet aan."
    position: {text: "Ik registreer alles één keer per maand. Dan doe ik de hele stapel in één keer. Dat is efficiënter, ik heb het uitgerekend. Klopt.", tags: [claim], tell: facts}
    layers:
      - id: interest
        at: 52
        via: [paraphrase, inquiry, open_question]
        text: "Elke keer dat ik in het register ga, ben ik een kwartier kwijt voordat ik iets heb gedaan. Twee tokens, de controles, de export. Ik noem hem de Molen. Die maalt, maar langzaam."
        tags: [claim]
      - id: concern
        at: 66
        via: [silence, experience, empathy]
        lead_in: {text: "En dan nog iets…", tags: [hesitation]}
        text: "Ik ben de enige die het kan. Als ik een week ziek ben, ligt alles stil. Niemand heeft ooit gevraagd wie het van me overneemt. Ik weet niet eens of ik het goed uit zou kunnen leggen."
        tags: [admission, doubt]
        unlocks:
          facts: [heard:petra_thursday]
          proposals: [write_it_down_together]
    proposals:
      - {id: see_the_molen, name: De Molen laten zien, text: "Mag ik een keer meekijken als je een registratie doet?",
         addresses: [interest], reply: "Een keer. Volgende maand. Dan zie je hoe hij maalt."}
      - {id: write_it_down_together, name: Samen opschrijven, hidden: true, text: "Zullen we samen opschrijven hoe het werkt? Dan heb jij een vervanger, en ik snap het ook.",
         addresses: [concern], reply: "Opschrijven. Met de tokens erbij. Dat staat nog nergens. Klopt."}
      - {id: ask_ruud_backup, name: Ruud om een vervanger vragen, text: "Wil je dat ik Ruud vraag om iemand die jou kan vervangen?",
         addresses: [concern], reply: "Vragen mag. Als ik zelf mag kiezen wie."}
    lines:
      experience: "Maandag wist ik niet eens waar Intake zat. Ik heb het aan de schoonmaker gevraagd. Ik dacht: als ik vandaag ziek word, weet niemand wat ik al gezien heb."
      paraphrase: "Dus elke keer dat je begint, kost het je eerst een kwartier. Daarom doe je het liever in één keer."
    replies:
      experience:
        lands: {text: "De schoonmaker. Ha. Die weet meer dan het organogram. … Ja. Zo voelt het hier ook.", tags: [feeling]}
    outcomes:
      commitment: "Klopt. Volgende week dinsdag, om tien uur. Ik leg de map klaar. Jij mag hem aanraken."
      partial: "Misschien. Als Ruud het goedvindt."
      heard: "Hm. Je vroeg wie het overneemt. Dat had nog niemand gevraagd."
      none: "Ik heb nog een stapel."
      compliance: "Prima."
      ruined: "Ik heb nog een stapel."
    # routes (start 40): paraphrase +7 47 (heard) > inquiry +8 55 (interest) > paraphrase +7 62 > open_question +6 68 (lead-in "En dan nog iets…")
    #   > silence +12 > 75 capped (concern: admission, doubt) > experience +8 (heard, trust 50, after doubt: lands) 83 > propose write_it_down_together > ask (8 moves)
    #   other: experience after the concern is the day's move; empathy at the lead-in also reveals it. Experience BEFORE her doubt costs -5 ("Het gaat nu even niet over jou.").
    # the lesson: experience only helps once she has shown a doubt; then a small, true story from this week makes her doubt smaller. Ruud names experience if it landed.
```

### 4.5 Vrijdag: all eight

`anouk_owns_tray` is the Acts 0–II scripts' talk, rebuilt in the content schema (`teaches: []`: Friday names whatever landed best). `sanne_friday` closes the week: Sanne has noticed what the player did all week.

```yaml
dialogs:
  - id: anouk_owns_tray
    name: Anouk en het A4
    person: anouk
    kind: persuade
    mission: training_fri
    owns: training_tray
    tutorial: true
    teaches: []
    mood: goed
    patience: 12
    # start: overloaded 35 + 10 (goed) + 0 + 0 + 0 + 15 (memory: committed on Tuesday or Thursday) = 60, Open; without it 45
    opening: "Het werkt. Ik heb vandaag niet één keer gezocht. Niet één keer!"
    position: {text: "Maandag komen de anderen terug. Dan leg ik het wel even uit.", tags: [claim]}
    layers:
      - id: interest
        at: 62
        via: [open_question, inquiry, paraphrase]
        text: "Eén bak, oudste bovenop. Het is zo simpel dat je het vergeet. Dat is het gevaarlijke."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [reflect, empathy, silence, inquiry]
        lead_in: {text: "Alleen…", tags: [hesitation]}
        text: "Ze werken alle drie langer hier dan ik. Wie ben ik om te zeggen hoe het moet?"
        tags: [admission, doubt]
        tell: safety
        unlocks:
          facts: [heard:anouk_owner]
          proposals: [anouk_writes_a4]
    proposals:
      - {id: joost_announces, name: Joost kondigt het aan, text: "Joost kan het maandag in het werkoverleg aankondigen. Dan is het geregeld.",
         addresses: [], reply: "Ja. Dat kan. Dan is het van Joost."}
      - {id: a4_above_tray, name: Een A4 boven de bak, text: "Een A4 boven de bak, met de regel erop. Dan hoeft niemand het te onthouden.",
         addresses: [interest], reply: "Een A4. Ja. Al hangen er hier al zes A4'tjes die niemand leest."}
      - {id: anouk_writes_a4, name: "Jij schrijft het A4, in jouw woorden", hidden: true,
         text: "Wat als jij het A4 schrijft, in jouw woorden, en het maandag zelf laat zien? Niet als regel. Als wat je ontdekte.",
         addresses: [concern], reply: "Als wat ik ontdekte. Dan is het geen regel van de nieuwe. Dan is het… mijn trucje."}
    experiments:
      - {id: decide_together_friday, name: Een week proberen, samen beslissen, text: "Probeer het een week met z'n vieren, en beslis vrijdag samen of het blijft.",
         addresses: [concern], reply: "Samen beslissen. Dan is het niet mijn regel. Dan is het de onze."}
    co_proposal: {id: anouk_writes_a4, text: "Als ik het A4 zelf mag schrijven. En jij er maandag bij staat. Niet om te praten, gewoon erbij."}
    outcomes:
      commitment: "Afgesproken. Ik teken er een bergje bij. Met een vlag."
      partial: "Goed. Als Joost het ook zegt."
      heard: "Dank je. Ik ga het A4 in elk geval maken."
      none: "Ik ga het A4 maar vast schrijven."
      compliance: "Oké. Als Joost het zegt."
      ruined: "Ik ga het A4 maar vast schrijven."
    # route (start 60): open question +6 66 (interest) > reflect +10 76 (lead-in) > silence +12 > 81 capped (concern) > propose anouk_writes_a4 > ask: commitment (5 moves)
    # joost_announces wins at most a partial: the change is imposed on the person whose work it is (buy-in none). Friday's time-lapse shows the buy-in factor.

  - id: sanne_friday
    name: Sanne op vrijdagmiddag
    person: sanne
    kind: persuade
    mission: training_fri
    tutorial: true
    teaches: []
    mood: goed
    patience: 12
    # start: overloaded 35 + 10 (goed) + 0 + 0 + 0 + memory (+10 heard / +15 committed on Monday) = 45-60
    opening: "Zo. De nieuwe. Het hele gebouw heeft het over je, weet je dat?"
    position: {text: "Je loopt overal rond en je vraagt dingen. Rachid zei dat je zijn lijstje wilde zien. Niemand wil Rachids lijstje zien.", tags: [claim, feeling]}
    layers:
      - id: interest
        at: 55
        via: [mood, open_question, reflect]
        text: "Ik dacht maandag: weer iemand van het hoofdkantoor met een stopwatch. Maar je hebt nog niks verbeterd. Je hebt alleen gekeken. Dat is raar. Raar goed, bedoel ik."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [silence, empathy, reflect, inquiry]
        lead_in: {text: "Alleen, nou…", tags: [hesitation]}
        text: "Volgende week begin je echt, toch? Met de stapel van Joost. Als het daar beter gaat, komt alles nog harder bij ons binnen. En dan zijn wij weer het postkantoor dat het niet bijhoudt."
        tags: [admission]
        tell: recognition
        unlocks:
          facts: [heard:sanne_friday]
          proposals: [walk_the_flow_monday]
    proposals:
      - {id: promise_to_come_back, name: Beloven terug te komen, text: "Als ik bij Joost begin, kom ik daarna eerst bij jou kijken.",
         addresses: [concern], reply: "Eerst bij ons. Oké. Ik houd je eraan."}
      - {id: walk_the_flow_monday, name: Maandag samen de stroom lopen, hidden: true,
         text: "Loop je maandag met me mee? Eén aanvraag, van jouw bak tot de monteur. Dan zie je zelf waar hij straks blijft liggen.",
         addresses: [concern], reply: "Van mijn bak tot de monteur. Dat heb ik in vijftien jaar nooit gedaan. Ja. Maandag."}
    co_proposal: {id: walk_the_flow_monday, text: "Neem me maandag mee. Van mijn bak tot de monteur. Dan zie ik het ook eens."}
    outcomes:
      commitment: "Maandag. Om negen uur. Ik neem Rachids lijstje mee. Zeg niks tegen hem."
      partial: "We zien maandag wel. Joh. Fijn weekend."
      heard: "Hè. Je luistert echt, hè. Dat is ook raar. Raar goed."
      none: "Ik moet de bakken nog leegmaken. Fijn weekend."
      compliance: "Prima. Fijn weekend."
      ruined: "Fijn weekend."
    # routes: any of the eight. With Monday's commitment (start 60): open_question (interest) > reflect (lead-in) > silence (concern) > propose walk_the_flow_monday > ask (5 moves).
    #   Without it (45): mood x1.5 > paraphrase (heard) > open_question (interest) > reflect > empathy (lead-in) > silence (concern) > propose > ask (8 moves).
    # After this talk Ruud says week_end (§3): he will not name a move again.
```

---

## 5. Schema needs for the builder

| Key | On | Meaning |
|---|---|---|
| `teaches` | dialog (tutorial only) | The move(s) the day's card introduced; Ruud's naming rule prefers these (§3). Validator: only on `tutorial: true`; moves from `dialog_moves`. |
| `bank.ruud_names` | bank | Ruud's naming line per listening move, plus `none` and `week_end` (§3). |
| `move_cards` | `content/dialogs.yaml` (or concepts) | The eight cards (§2), each tied to a training mission; shown in the morning briefing and in the codex under *Gesprekken*. |
| `move_cards[].move: null` | the Friday card | A card that names a skill, not a move ("Wie zit er tegenover je?", §7); no chip, no naming line. |
| `need`, `tell` | people, line objects | Person needs spec §6. |
| `People.last_landed` | rules | Per talk, which listening moves landed and which revealed the concern, so the naming rule can pick (tutorial talks only). |
| validator | `_layers` | Accept a concern lead-in tagged `feeling` without `hesitation` (four-tier audit §4.2; PLAN 1.6a). Until then the two feeling cues here (Anouk Tuesday, Linda Wednesday) carry both tags. |

**Where the talks open:** each talk is available while its training mission is active, at its person's place (`connections.intake`, `.design`, `.revision`, `.planning`, `.close_out`). The two talks of a day can be had in either order. `training_mon`'s goal stays `observe`; the talks are optional, as every dialog in a solve mission is (dialog spec §5.1). A player who skips them is not blocked, and Monday's card still names the moves.

**Tests** (dialog spec §9.3, plus):
- every tutorial talk reaches `commitment` within patience by at least three distinct sequences, one of them without the day's move;
- no tutorial talk can end in `ruined`;
- Ruud's naming line never names a move that missed, and never fires outside Act 0.
- with needs on (§7): every talk keeps three routes and one without the day's move; the day's move still lands (Δ > 0) on its own talk; each talk shows a tell in its position.

## 6. Questions, decided by the standing rule

1. **How many talks.** **(a) Two a day (ten), all optional.** (b) One a day. *(a) is what the coordinator asked for, and optional talks respect a returning player who skips the week.*
2. **Where the move is taught.** **(a) A card in the morning briefing, no highlighted chip.** (b) The day's chip glows. *(a) teaches the name without handing over the moment; (b) would be a golden path for a week.*
3. **Ruud's naming.** **(a) One move per talk, only one that landed, Act 0 only.** (b) Every landed move. *(a) is a coach's single observation; a list is a report card.*

---

## 7. Reading a person: audit against the person needs (2026-10-16)

Audited against `2026-10-16-person-needs.md`. The question: does the week teach the player to *read the person* before choosing a move, without naming any need? Numbers are first-move Δ with the spec's values, E1, the archetype weights and the need weights at the talk's mood (needs spec §1.2–§1.4); estimates, to be confirmed on the engine.

### 7.1 Findings

| Talk | Person · need · mood | Day's move: need weight | Best first move with needs | Verdict |
|---|---|---|---|---|
| `anouk_seven` (Mon) | Anouk · safety · moe | mood ×1.0 (archetype ×1.5): 12 | mood 12, empathy 10 | Holds: on a tired evening, asking how she is still opens best. |
| `sanne_tuesday` | Sanne · recognition · moe | open_question ×1.125: 6.75 | mood 10.5, paraphrase 8.75 | Holds as "a good way, not the way"; her tell now says what she misses. |
| Rachid (walk-around) | Rachid · **fairness** · neutraal | open_question ×1.5: 9 | open_question 9 | Holds, and it is the week's only fairness person (F1). |
| `anouk_first_look` (Tue) | Anouk · safety · neutraal | empathy ×1.5: 12 | empathy 12 = mood 12 | The day's move is her need's move: the clearest lesson of the week. |
| `mieke_wednesday` | Mieke · recognition · neutraal | paraphrase ×1.5: 10.5 | inquiry 12 (craftsman), paraphrase 10.5 | Holds. |
| `joost_wednesday` | Joost · safety · neutraal | inquiry ×0.5 before `heard`: 4; ×1.0 after: 8 | empathy 12 | **Contrast (F2):** the same Doorvragen lands ▲▲ on Mieke and only ▲ on Joost, until he feels heard. Route A (paraphrase, then inquiry) already does it right. |
| `linda_wednesday` | Linda · time · moe | reflect ×1.0: 10 | mood 15 | Holds; route A opens with mood. |
| `anouk_thursday` | Anouk · safety | silence ×1.0 | (memory-dependent) | Holds; Ervaring delen would land ×1.5 for her, a find for the curious. |
| `petra_thursday` | Petra · facts · neutraal | experience ×0.75: 6 | inquiry 12 | Lands, but weaker (F3). |
| `anouk_owns_tray`, `sanne_friday` | safety, recognition | all eight | as their people | Hold. |

- **F1. The week met only four needs** (Anouk, Rachid and Joost were all safety-shaped). Rachid's worry ("komt terug met mijn naam erop", for errors made by installers) reads as well as fairness, and the walk-around talk teaches the open question, fairness's strong move. **Applied:** Rachid's need is `fairness`; his position carries the tell. A player who skips him meets fairness in Act I (Marco, Esra).
- **F2. Wednesday is the contrast day.** Three people, three needs (recognition, safety, time), and the same move landing differently is visible in the arrows. No change to the talks; the closing question (F5) asks about exactly this.
- **F3. Petra's Ervaring delen lands at ×0.75.** Kept: it still lands (Ruud names it), and her story is factual (whom to ask, the cleaner), the kind of experience a facts person accepts. Route numbers in her comment shift by −2; no route is lost.
- **F4. No talk showed a tell early.** The needs were in the concerns, which come late. **Applied:** a tell in each talk's position, in the person's voice (below), and `tell` tags on the later lines that already were tells (Mieke's "overtekenen", Anouk's Friday doubt, Sanne's "postkantoor").
- **F5. Nothing in the week asked the player to compare people.** **Applied:** a Friday card, *Wie zit er tegenover je?*, that names the skill and points to the Mensen tab (never a need), and Ruud's `week_end` line now ends with a question: "Wat werkte bij de één en niet bij de ander? Waar zag je dat aan?"

### 7.2 Edits applied in this doc

| Where | Change |
|---|---|
| people block | `need` for Sanne (recognition), Rachid (fairness), Anouk (safety), Mieke (recognition), Linda (time), Petra (facts); Joost (safety) goes on his existing entry |
| `sanne_monday` / `sanne_tuesday` position | + "Maar dat ziet boven niemand, hè." `tell: recognition` (the Tuesday re-dated position in the first-five-minutes doc §4.2 gets the same ending) |
| Rachid's position | + "Meestal niet door ons, hoor." `tell: fairness` |
| `anouk_first_look` position | + "…, echt. Je hoeft het niet op te schrijven." `tell: safety` |
| `mieke_wednesday` position | + "'Overtekenen', noemen ze het boven." `tell: recognition`; her paraphrase reply `tell: recognition` |
| `joost_wednesday` position | + "En als dit naar Frank gaat, wil ik het eerst zien." `tell: safety` |
| `linda_wednesday` position | + "Ik heb tot de volgende storing." `tell: time` |
| `anouk_thursday` position | + "En verder hoeft niemand het te weten, toch?" `tell: safety` |
| `petra_thursday` position | "Dat is efficiënter, ik heb het uitgerekend." `tell: facts` |
| `anouk_owns_tray` concern, `sanne_friday` concern | `tell: safety`, `tell: recognition` |
| move cards (§2) | the Friday card *Wie zit er tegenover je?* (`move: null`) |
| `ruud_names.week_end` (§3) | ends with the comparing question (F5) |
| tests (§5) | with needs on: three routes, one without the day's move, the day's move lands, a tell in each position |
| first-five-minutes `anouk_seven` | position + "Zeg maar niet tegen Joost dat ik er nog zat, hè." `tell: safety` |

The route comments above are computed without needs; the builder's tests on the engine are the judge (N4 in the needs spec).

