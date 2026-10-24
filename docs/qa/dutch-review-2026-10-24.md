# Dutch review of the text written since 2026-10-19

> Reviewer: S2-D, a native-speaker pass (years at a Dutch netbeheerder), 2026-10-24, against `docs/superpowers/specs/2026-10-19-dutch-style-guide.md` and what the last review fixed (`docs/qa/dutch-sample-2026-10-19.md` §7). Text only: keys, ids, tokens and structure are unchanged. Not touched: the existing lines of the Act I/II persuasion talks, which wait for Merijn's playtest feedback.

## Scope: what was read

Everything new since `46f6dbf` (the last reviewed state) in `content/` and the Dutch string constants added to `game/src`:

- `dialogs.yaml`: the two voicemails (El Amrani, Ilse), El Amrani's notebook variant and the date she is given, `wim_expert`, `henk_expert`, `greetings`, `quick`, `chatter`, Anouk's Thursday lines (the one-day trial).
- `missions.yaml`: every new `steps:` line, the milestones `winter_el_amrani` (briefing, debrief, fail, missed, both payoffs) and `review_100_days`, the two `too_early` debriefs, the Sandra Vermeulen renames, the one-day training week.
- `scenes.yaml` (`review_100_days`), `world.yaml` `tells:`, the `tells:` in `problems_tier1.yaml`, `company.yaml` descriptions.
- GDScript: the phone apps (Berichten, Opdrachten, Notities, Wie is wie, Instellingen), the incoming call, TalkView and its summary, the KCC headset, the van ride and look-closer prompts, the door ("Naar huis"), the away lines, the late-evening note, the reputation reasons and the new toasts.

**Second round** (landed while I worked, merged and read the same way): `femke_expert`, Ilse's new mood line, the coach's `numbers` and `kata`, the `principles:` bank, the missions `talk_netplanner`, `lsw_gemba_round`, `fix_double_visits`, `fix_overtime_planning`, `first_kpi_review` (mission and scene), `kpis.yaml` `review_lines`, the KPI board strings, the new problems and countermeasures, Ruud's "Daar is nu geen geld voor…".

**Not landed when I finished:** new `bank.player` variants and new feeling lines for Femke beyond her persuasion talk's tags. They need the same pass when they land.

## What I changed, and why

### Greetings never say "gisteren"
A greeting remembers a talk up to three days old (`GREETING_MEMORY_DAYS`), across a weekend too, so "gisteren" was wrong more often than right. All shared and personal fact lines now say "laatst", "ons vorige gesprek" or "dat gesprek van laatst".

Two of them were also translated or empty:
- "Vandaag is een nieuwe dag." (*today is a new day*) → "Ik was na ons gesprek nog wel even chagrijnig. Het zakt wel weer."
- "Ik heb nog even nagedacht over ons gesprek. Later misschien." ("later misschien" answers nothing) → "Ik zit nog een beetje met ons gesprek. Laten we het even laten rusten."
- "Laten we het rustiger aanpakken." (sounds like an instruction to the player) → "Kunnen we het de volgende keer rustiger aanpakken?"

### Greetings: time of day, voice tics as filler, translated English
- Henk: "Sinds 1987 sta ik hier elke ochtend. Jij bent er ook vroeg bij." The office shows greetings at any hour, so "vroeg" was wrong in the afternoon; and 1987 clashed with his own talk ("ouwe Toon… in 1984"). → "Sinds 1984 loop ik hier rond. Nog steeds niet uitgeleerd, hoor."
- Voice tics used as filler, which §7 of the last review already removed from the talks: Petra's "Klopt, ik ben er weer" and "Rustig. Klopt, dat gebeurt soms." (*klopt* is a reaction, not a full stop), Mieke's "Dat moet kloppen, hè" after a plain fact, Anouk's "Ik zit erbovenop, hoor" with nothing to be on top of. Rewritten in their voice ("Alles staat klaar voor vandaag. Zoals altijd."; "Ik ben de revisies van vorige week nog aan het uitzoeken."; "Heb je al koffie gehad? Ik wilde net gaan.").
- Frank: "Goed je te zien" (*good to see you*) → "Dag {speler}. Ik heb vandaag het ene overleg na het andere."
- Ruud: "De koffie hier is nog steeds slecht. Of went het al?" (who or what *went*?) → "Ben je al gewend aan de koffie hier? Ik nog steeds niet." (his self-mocking, and a question).
- Ahmed: "Hé {speler}. Gaat wel, man." answered a question nobody asked → "Ook weer hier, man?"
- Sanne: "koffie op" reads as *the coffee is finished* → "koffie erbij… Kom maar op."; "Joh, het is weer een drukte vandaag, hè" (two particles stacked at the front) → "Wat een drukte weer vandaag, joh."
- Joyce: "de nieuwe van Aansluitingen": the player is in Ruud's staff, and the guide's name for them is "de nieuwe van Ruud".
- Wim (a retired man of seventy, a customer): "Hoi" → "Goedendag"; "Veertig jaar in het vak, en…" → "Veertig jaar in het vak gezeten, en…".
- Anouk: "Oh" → "O"; "zoals we zeiden" → "zoals we hadden afgesproken".

### Quick lines
- "Na de lunch is het altijd even een dipje" → "heb ik altijd even een dipje" (a dip is something you have).
- "Ik werk wat achterstallige dingen weg" → "Eindelijk tijd voor wat er al weken blijft liggen."
- "Ik moet echt even koffie" → "…koffie hebben".
- Esra: "twintig bellers in de wacht" → "twintig mensen in de wacht" (callers *hangen* in de wacht).

### Chatter: an observation, not the answer
`portal_asks_too_little` had a colleague say "Omdat het portaal niet vraagt wat wij nodig hebben. Al jaren niet." That is the root cause of `incomplete_application` handed over at the coffee machine, which breaks "nothing is handed over". The question stays (it is a good hook); the answer is now what people really say about an old problem: "Geen idee. Dat is al zo zolang ik hier zit."

### El Amrani
- Voicemail: "Ik bel morgen terug" (she is not returning a call) → "Ik bel morgen weer."
- The date: "over een week of zes aangesloten. Op maandag 23 november." puts a vague span and a hard date side by side as two sentences. → "…over een week of zes aangesloten. Dat wordt dan {promise_date:42}." Her reply ("Op {promise_date:42}. Ik schrijf het op…") and the notebook variant still match.

### Wim's expert talk (u, his voice)
- "Zelf gebouwd, hoor, van een printplaatje…" → "Zelf in elkaar gezet, hoor: een printplaatje en een oude telefoonlader."
- "En elk voorjaar komen er een paar volt bij. Sinds de halve straat panelen heeft." (a dangling fragment) → "En sinds de halve straat panelen heeft, komen er elk voorjaar een paar volt bij."
- "Dan ziet u… Dan weet u ook waar u moet kijken." (two *dan*'s) → "En dan weet u meteen waar u moet zoeken."
- The norm answer (230 V + 10 %, ten-minute average, the inverter disconnects) is right and stays.

### Henk's expert talk
- Retry: "Jij weer, {jongen_meid}." is cold for the warm one of the two gruff men → "Daar ben je weer, {jongen_meid}."
- Closing: "als je het wilt zien in plaats van horen: je weet me te vinden" (written) → "Maar zien is beter dan horen. Als je wilt, doe ik het je een keer voor." (his "Laat het me voordoen").
- Joints: "aan weerszijden" (written) → "aan allebei de kanten"; "kunststof kabels" → "kunststofkabels"; "die heeft niet elke bus bij zich" (a van does not carry things *bij zich*) → "die ligt niet in elke bus", also in the clue text.
- GPLK: "dicht solderen" → "dichtsolderen" (one verb), also in the clue; "Mijn eerste mof op zo'n kabel maakte ik in 1979" → "heb ik in 1984 gemaakt" (the perfect, and the year his own talk gives for ouwe Toon).

### Mission steps
- Subject–verb agreement in the generated "Beslis… hoe X verdergaat": "de monteurs", "de meterwisselaars" and "beide teams" take *verdergaan*.
- "Zoek uit waarom de planning steeds omgaat" (a planning does not *omgaan*) → "…steeds wordt omgegooid" (Linda's own word in the chatter).
- "hoeveel gecontracteerd vermogen er echt draait" → "…echt wordt gebruikt" (capacity is used; machines run). All steps are still at most 60 characters.

### Milestones and debriefs (Ruud's notes)
- `winter_el_amrani` briefing: "Het KNMI verwacht rond 21 december de eerste echte vorst" was not correct: the KNMI does not forecast three weeks ahead, and the date is our own estimate (the content comment says so). → "Rond de kortste dag, 21 december, gaat het meestal echt vriezen: een paar nachten achter elkaar onder nul."
- Debrief: "Op de eerste vorstnacht" → "In de eerste vorstnacht"; "Haar moeder zat warm" → "had het warm" (*er warmpjes bij zitten* means being well off). Fail: "Tijdens de eerste vorstnachten…". Missed: "…nog steeds uit."
- `review_100_days` briefing: "Je zit hier nu honderd dagen. Neem niks mee, alleen jezelf." (the second sentence is a translated *just bring yourself*) → "Je werkt hier nu honderd dagen. Je hoeft niks voor te bereiden."
- The `too_early` debriefs: "De Check zegt: maar half" / "De Check zegt: nauwelijks" (a check does not *say*) → "De Check laat zien: dat helpt maar half" / "nauwelijks minder". "Je verwachtte dat Meetdata sneller zou afmelden als het systeem de EAN-codes zelf aanmeldt" (afmelden/aanmelden in one breath, and Meetdata is not what gets faster) → "Je verwachtte dat dossiers sneller afgemeld zouden worden als…". Digging: "de graafmachine van volgende week graaft op de kaart van vorig jaar" → "de aannemer die volgende week graaft, graaft op…"; "Wat kan er deze week al veilig" → "Wat maakt het graven deze week al veiliger"; Gert, an uitvoerder with a ploeg, no longer stands "met een schop in de grond": "Maar volgende week staat mijn ploeg weer te graven. Waar kijken we dan op?"

### The hundred-days scene
- Frank: "de standaardontwerpen liggen nog steeds bovenop" (unclear) → "werken ze nog steeds met de standaardontwerpen. Joost laat ze me zelf zien…"
- Frank: "een stuk minder telefoon" → "telefoontjes".
- Ruud: "Mevrouw El Amrani belde me laatst": she called the player, not Ruud → "Ik hoorde dat mevrouw El Amrani nog heeft gebeld. Alleen om te zeggen dat haar moeder het warm heeft."
- "wat er anders gaat dan in oktober" → "wat er nu anders gaat…".

### Tells
- `incomplete_application`: "De stapel dossiers op de kast bij Intake is hoger dan het werk van een dag" (a stack is not *higher than work*) → "Op de kast bij Intake ligt meer dan een dag werk aan dossiers." The other tells read well and none names a problem or its cause.

### GDScript
- Incoming call: "Laten gaan" (*let it go*) → "Niet opnemen", the words on a Dutch phone screen.
- KCC headset when nobody waits: "Er wacht niemand op jou" (stressed *jou*, sounds reproachful) → "Er hangt niemand voor je in de wacht."

### Second round: Femke's expert talk
- Opening: "Kort gezegd: dat leg ik je graag uit" used her tic for a long explanation, and "Neem een stoel" is *take a seat* → "Dat leg ik je graag uit. Pak een stoel. De koffie is wel koud, sorry."
- Retry: "Jij weer. Goed. Waar waren we?" is curt for the enthusiastic one → "Daar ben je weer! Waar waren we gebleven?"
- "Hoeveel er tegelijk gebeurt, daar rekenen wij **op**" (*we count on it*) → "Hoeveel er tegelijk aanstaat, daar rekenen wij **aan**." That is the whole point of her job, so the preposition matters.
- "ontworpen op wat die huizen tegelijk vragen" → "berekend op" (also in the `talk_netplanner` debrief); "Wat is zo'n middenspanningsruimte precies?" → "Wat is een middenspanningsruimte eigenlijk?" (nobody had mentioned one yet); "Dat huisje in je straat" → "bij jou in de straat"; two fragments joined ("Niet de hele dag, maar op dat ene moment."; "Er staan achtendertig studies op het bord").

### Second round: missions, principles, scenes
- Principles: "wie zich aangesproken voelde op een fout" (*zich aangesproken voelen* means to feel addressed) → "wie de schuld kreeg van een fout"; "glijdt dit vanzelf terug naar hoe het was" → "gaat het vanzelf weer zoals het was"; "die betaalt zich elke week terug" → "die verdient zich elke week terug".
- `fix_double_visits`: Ruud wrote "aan de grens van wat de directie draagt", but Ruud is the directie → "aan de grens van ons budget".
- `fix_overtime_planning`: "waar die uren in gaan zitten" → "waar die uren naartoe gaan"; "een dag dat de monteur…" → "een dag waarop" (also in the countermeasure `route_by_area`).
- `first_kpi_review`: "Sanne en Joost hadden vorige week in het MT één getal bij zich": teamleiders do not sit in the MT (fixed the same way in the last review) → "Sanne en Joost kwamen vorige week samen bij me, met één getal: de doorlooptijd."
- Read and kept: the coach's number clauses and the Kata five, the `review_lines`, the gemba round (briefing, debrief, steps), both way-back sides' briefings and clues, the KPI board's strings ("Waar sturen de teams op?", "Ophangen", "Kwartaalreview"), Ruud's "Daar is nu geen geld voor. Wat kun je doen met wat er wel is?", Ilse's "Mijn deeg rijst, mijn oven is oud, en ik hang bij jullie aan de lijn. Raad maar."

## Read and kept

- Both voicemails apart from "terug"; El Amrani's notebook variant ("Die datum is geweest." is how people say it); her payoff call and letter, which are among the best lines in the game.
- `company.yaml`: the descriptions are plain and correct; the titles must match the cast word for word and were not touched.
- `world.yaml` tells: they describe what anyone sees, three heights each, no causes.
- Most chatter ("Niet hardop zeggen. Dan gaat meteen de telefoon." is exactly right), Marco's "rijden zich het schompes", Femke's "Kort gezegd: het past nét", Rob's *u*.
- Phone and UI strings: Berichten, Opdrachten, Notities, Wie is wie, Kaart; "Naar huis", "Van dichtbij bekijken", "Meerijden met …", "Headset opzetten", "… is al naar huis. Morgen weer.", "… zit in de kantine.", the late note. "missiebord" stays: UI chrome may say *missie*.

## For a native ear to decide

1. **"Kan wel een goed gesprek gebruiken."** (Wie is wie, low morale). *Iets kunnen gebruiken* is real Dutch ("ik kan wel een bak koffie gebruiken"), but here it sits close to *could use a good talk*. Kept; "Zou wel een goed gesprek willen" is the alternative.
2. **Rob says *u* with a first name** ("Dag {speler}… zegt u het maar"). Deliberate stiffness from his sheet; some readers will find the mix odd.
3. **Ricardo: "Ik zag je in de appgroep."** Would the CI-lead be in the monteurs' app group? Plausible if Ruud announced the new colleague there.
4. **"Nog plannen voor het weekend?"** (chatter `weekend`) can come on a Monday. A `days:` filter would fix it; that is code, not text.
5. **Who is "de directie"?** Frank says it often (his voice sheet), also in the hundred-days and KPI scenes, while Ruud, "Directeur Netbeheer regio Zuidmark", sits next to him. I first changed it to "het hoofdkantoor" and then put it back: it is Frank's word, and in corporate Dutch *de directie* often means the board above the region. Merijn should say which it is; if it means Ruud, Frank's lines in both scenes need rewording.
6. **"Akte I · …"** in the act titles (pre-existing UI): theatre Dutch says *bedrijf*, but "akte" is understood and fits a game menu.
7. **Speaking Henk's years**: "Sinds 1984" and "in 1984 gemaakt" are digits in a spoken line; the guide allows years in Henk's stories. A voice actor reads them as *negentien vierentachtig*.
