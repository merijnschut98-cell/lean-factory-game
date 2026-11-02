# Place actions: fitting tools, a growing toolbox, real observations

*Design agent, 2026-10-18. Plan: `/root/.claude/plans/graceful-booping-cocke.md` §B. For one builder; paste-ready.*

## 0. Why, and the calls in one screen

Merijn's playtest: at Intake and Werkvoorbereiding the place menu showed about 15 options (7 tools and 8 questions), the same at every place. Most were useless ("Je vindt hier niets nieuws met dit instrument."), there was nobody to talk to at Intake, and the right option stood out because the others were clearly wrong.

His decision: **each place offers only the tools that fit it, the toolbox grows through the training week, and an empty result gives a real observation from that place**, logged in the journal as "Waarneming".

The calls in this spec:

1. **Content lives in a new `content/places.yaml`**, keyed by `stream.step`. `world.yaml` stays about rooms and floors.
2. **`tools` lists the investigation tools only.** `conversation` is never in it: a place's questions are its conversation. A conversation clue needs at least one **open** question at its place.
3. **Labels are place-specific and never name the answer.** I dropped the plan's example "Bekijk de onvolledige aanvragen" because it hands over *De onvolledige aanvraag*. It reads "Blader door de aanvragen van deze week" instead.
4. **Questions are asked to a named person** ("Sanne: …"). There are at most 4 per place, mixing open, closed and blaming kinds, and every one is phrased the way a real colleague might ask it. The bad questions are no longer cartoons ("Wie heeft de laatste fout gemaakt?"), so the good ones stop standing out. `thanks` (repair) is not a regular chip: it shows only after a blame or guarded reply at that place.
5. **People can be met at more than one place** (`people_also` in places.yaml). This fixes four conversation clues that had nobody to ask (§3).
6. **Kees Mulder** (operator, already named in `discoveries.yaml`) becomes a person at `outages.report`, with no talks yet. This leaves no place in a walk without a person.
7. **Monday grants questions only.** Monday's menu at a place is its people and their 3–4 questions: about 4–6 buttons, all useful.
8. **Grants sit on the training missions (`grant_tools`)**, and the morning-note text sits in `places.yaml` `tool_cards`, one card per tool.
9. **Observations cycle per place and tool and are saved.** No line repeats until all lines for that pair have been seen. Each one goes into the journal as "Waarneming". `queue_count` still shows the live count, followed by the observation. The spotted line and the hidden signal stay as they are.
10. **A time study is offered only where work is timed:** design, grid study, revision, the contact centre and the field places. It is never offered at Intake, Planning, Meetdata or the waiting steps.

## 1. Places and their tools

This covers every place that a tier-1 problem (its `step`, or a clue's `at`), a tier-1 mission (`observe` places, and the work steps of `walk` streams) or a `discoveries.yaml` trigger uses. Every room place in `world.yaml` is covered too. The labels are the button text, and the UI appends the duration as it does now ("Volg één dossier (4 uur)"). **Who is there** lists the people the player can ask at that place. *(also)* means the person comes from `people_also`.

| Place | Who is there | Tools: label |
|---|---|---|
| `connections.intake` | Sanne, Rachid | `listen_in` Luister mee met een aanvraaggesprek · `documents` Blader door de aanvragen van deze week · `queue_count` Tel de inbox · `data` Draai de intakecijfers uit het systeem |
| `connections.design` | Anouk, Joost, Frank, Rob | `shadow` Volg één dossier · `documents` Bekijk de tekeningen · `queue_count` Tel de stapel · `time_study` Klok één ontwerp · `data` Draai de ontwerpcijfers uit het systeem |
| `connections.grid_study` | Femke | `shadow` Kijk mee bij een netstudie · `documents` Lees de werkinstructie netstudies · `time_study` Klok een netstudie · `data` Bekijk de cijfers van de netstudies |
| `connections.grid_reinforcement` | nobody (a wait) | `documents` Bekijk de dossiers van netverzwaringen · `data` Bekijk de lijst met verzwaringen |
| `connections.permit` | nobody (a wait) | `documents` Lees de vergunningsaanvragen · `data` Bekijk de doorlooptijden van vergunningen |
| `connections.planning` | Linda | `documents` Bekijk de weekplanning · `queue_count` Tel de klussen zonder datum · `data` Bekijk de planningscijfers |
| `connections.execution` | Marco | `shadow` Rijd een dag mee met een monteur · `time_study` Klok een aansluiting · `material_check` Kijk in de bus · `data` Bekijk de uitvoeringscijfers |
| `connections.commissioning` | Ahmed *(also)* | `shadow` Kijk mee bij het in bedrijf nemen · `documents` Bekijk de opleverpapieren · `time_study` Klok een oplevering |
| `connections.revision` | Mieke | `queue_count` Tel de bak met schetsen · `documents` Bekijk de schetsen van de monteurs · `time_study` Klok één revisie · `data` Bekijk de cijfers in GIS |
| `connections.close_out_wait` | nobody (a wait) | `data` Bekijk de status van opgeleverde aansluitingen · `queue_count` Tel de dossiers die op afhandeling wachten |
| `connections.close_out` | Petra | `documents` Bekijk Petra's afhandelmap · `queue_count` Tel de dossiers bij Meetdata · `data` Bekijk de registratiecijfers |
| `customer_contact.answer` | Esra, Kim, Saskia | `listen_in` Luister mee met een klantgesprek · `queue_count` Kijk naar het wachtrijbord · `time_study` Klok de gesprekken · `data` Bekijk de belcijfers |
| `outages.report` | Kees *(new)* | `listen_in` Luister mee met een storingsmelding · `documents` Bekijk de schakelinstructies · `data` Bekijk het storingslogboek |
| `outages.locate` | Henk, Ahmed, Gert | `shadow` Rijd mee met de storingsdienst · `time_study` Klok het lokaliseren · `documents` Bekijk de kabelkaarten · `data` Bekijk de storingsgegevens |
| `outages.repair` | Dirk | `shadow` Kijk mee bij het herstel · `material_check` Bekijk de voorraad in de bus · `time_study` Klok het herstel · `data` Bekijk de herstelgegevens |
| `meters.appointment` | Linda *(also)* | `documents` Bekijk de afspraakbrieven · `listen_in` Luister mee met het inplannen · `data` Bekijk de afspraakcijfers |
| `meters.visit` | Ahmed *(also)* | `shadow` Rijd mee met een metermonteur · `time_study` Klok een meterwissel · `material_check` Kijk in de bus · `data` Bekijk de wisselcijfers |
| `meters.registration` | Petra *(also)* | `data` Bekijk de uitleesgegevens · `queue_count` Tel de registraties die wachten · `documents` Bekijk de plaatsingsbonnen |
| `congestion.intake` | Thomas | `listen_in` Luister mee met een aanvraag voor capaciteit · `documents` Bekijk de aanvragen voor transportcapaciteit · `data` Bekijk de cijfers van de aanvragen |
| `congestion.congestion_study` | Femke *(also)* | `shadow` Kijk mee bij het congestieonderzoek · `documents` Lees het congestieonderzoek · `data` Bekijk de belastingsmetingen |
| `congestion.capacity_queue` | nobody (a wait) | `queue_count` Tel de wachtrij · `data` Bekijk de wachtrij voor netcapaciteit · `documents` Bekijk de brieven aan wachtenden |
| `congestion.offer` | Thomas *(also)* | `documents` Lees de aanbiedingen en contracten · `data` Bekijk de contractcijfers |
| `voltage_complaints.analysis` | Petra *(also)* | `data` Bekijk de klachtgegevens · `documents` Lees de klachtformulieren |
| `voltage_complaints.measurement` | Ahmed *(also)* | `shadow` Kijk mee bij het plaatsen van een spanningsmeter · `time_study` Klok het plaatsen · `data` Bekijk de meetresultaten |
| `voltage_complaints.tap_change` | Ahmed *(also)* | `documents` Bekijk de gegevens van de wijktrafo · `shadow` Kijk mee in het trafohuisje |

`people_also` sets where these people can also be met:
- **Ahmed** at `connections.commissioning`, `meters.visit`, `voltage_complaints.measurement` and `voltage_complaints.tap_change`. He is the monteur the player knows, and the monteurs do all field work.
- **Linda** at `meters.appointment`, the same `planners` pool.
- **Petra** at `meters.registration` and `voltage_complaints.analysis`, the same `meter_office` pool.
- **Femke** at `congestion.congestion_study`, the same `grid_analysts` pool.
- **Thomas** at `congestion.offer`, the same `key_accounts` pool.

**Kees Mulder** is added to `dialogs.yaml` `people` with role "operator bedrijfsvoeringscentrum", place `outages.report` and no dialogs. If a `people` entry needs a cast body, `outages.report` ships without questions until he has one; log a ⬜ for the art agent.

## 2. Reachability: every tier-1 clue against its place's list

I computed the list mechanically: for each clue, the place is `at`, or else the problem's `step`. Every clue tool except `conversation` is in its place's `tools`, by construction. Conversation clues need an open question from someone at that place.

| Would have become unreachable | Clue | Resolved by |
|---|---|---|
| `congestion.congestion_study` conversation (unused_capacity, the red herring) | nobody was placed there | Femke in `people_also` |
| `meters.visit` conversation (silent_meter, depth 2, **key**) | nobody was placed there | Ahmed in `people_also` |
| `connections.commissioning` conversation (revision_backlog, depth 2, **key**) | nobody was placed there | Ahmed in `people_also` |
| `voltage_complaints.measurement` conversation (inverters_tripping, the red herring) | nobody was placed there | Ahmed in `people_also` |
| Discovery `connections.revision` + `documents` | revision's clues used no `documents` | `documents` added at revision |

The discovery `customer_contact.answer` + `listen_in` and the discovery `voltage_complaints.measurement` + `data` are both in the lists. `outages.*` (any tool, at night) has tools at all three outage places.

**Found in passing (not this spec's job):** `connections.permit` (permits_in_batches' depth-0 key clue, `data`) is in no room in `world.yaml`. Neither are `meters.appointment`, `outages.report`, the `voltage_complaints.*` places or the field places. The field places wait for Phase 4. Check that `fix_permits_in_batches` can actually reach `connections.permit` today; if not, give it a room (the clue's natural home is Werkvoorbereiding, which files the permit).

## 3. Questions per place

Each question uses an existing id from `Investigation.QUESTIONS`, so its kind and rules are unchanged. `text` is what the player says. `reply` is the person's line whenever no clue comes out:

- an open question with no conversation clue gives `reply`, then the live team observation (`UiText.observation`, unchanged);
- a closed question gives `reply`;
- a blame question gives `reply`. The trust and reputation cost stays.

A guarded reply (team trust below 0) stays generic, prefixed with the person's name. When a conversation clue is ready, an open question gives the clue's text, as now. Voices follow the four-tier audit §6. Henk's `{jongen_meid}` is filled by `GameSession.fill_tokens`.

### `connections.intake` (Sanne, Rachid)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Sanne | "Sanne, wil je me laten zien hoe een aanvraag bij jullie binnenkomt?" | "Nou, kijk. Portaal, werkbak, dossiernummer. Drie stappen, hè. Op papier dan." Ze klikt een aanvraag open en laat zien welke velden ze nakijkt. |
| obstacle | Rachid | "Rachid, wat maakt jouw werk lastiger dan nodig?" | "Lastig? Op maandag is het systeem traag. En als een klant belt, weet ik niet altijd bij wie zijn dossier ligt." |
| standard | Sanne | "Werken jullie volgens de werkinstructie voor de intake?" | "Joh, natuurlijk. Die hangt daar." Ze wijst naar een uitgeprint vel bij het raam. |
| behind | Sanne | "Hoe kan het dat Werkvoorbereiding zoveel dossiers van jullie terugstuurt?" | "Van ons?" Ze legt haar pen neer. "Wij zijn het postkantoor, hè. Wij krijgen het altijd." |

### `connections.design` (Anouk, Joost, Frank)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Anouk | "Anouk, wil je me laten zien hoe jij een dossier oppakt?" | "Sorry, het is een beetje een rommeltje." Ze opent een dossier, zoekt het adres op en begint aan het tracé. "Ik zit erbovenop, hoor." |
| obstacle | Joost | "Joost, wat maakt het werk hier lastiger dan nodig?" | "Even voor de duidelijkheid: vier vacatures in twee jaar. Dat is gewoon een feit." Hij opent een tabblad met de bezetting per week. |
| ok | Frank | "Frank, loopt het hier volgens plan?" | "Volgens het jaarplan wel. Ik moet het alleen kunnen uitleggen aan de directie." |
| who | Joost | "Wie heeft het dossier van de familie El Amrani laten liggen?" | "Eerlijk is eerlijk: dat zoek ik uit." Hij kijkt even naar Anouk en dan weer naar jou. "Maar niet hier." |

### `connections.grid_study` (Femke)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Femke | "Femke, kun je me laten zien hoe een netstudie gaat?" | "Kijk, kort gezegd: aanvraag erin, model rekenen, conclusie eruit." Ze tekent het terwijl ze praat. "Het past, of het past niet." |
| obstacle | Femke | "Wat maakt jullie werk lastiger dan nodig?" | "Het net verandert sneller dan ons model. Elke week komen er zonnepanelen en laadpalen bij die we nog niet kennen." |
| standard | Femke | "Doen jullie elke studie volgens de procedure?" | "Volgens de procedure, ja." Ze tekent verder. |

### `connections.planning` (Linda)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Linda | "Linda, hoe maak jij de planning van een week?" | "Sorry, het gaat snel hoor. Maandag vul ik de week, daarna is het omplannen." Ze laat het rooster zien. "Het is een kaartenhuis." |
| last | Linda | "Kun je laten zien wat er de laatste keer misging?" | "De laatste keer? Een monteur was ziek en ik had geen vervanger met de juiste aanwijzing." Ze zucht. "Dan bel ik de klant, met excuses." |
| standard | Linda | "Plan je volgens een vaste volgorde?" | "Ja. Meestal wel." |
| behind | Linda | "Waarom staan monteurs zo vaak voor niets bij een klant?" | "Dat ligt niet aan de monteurs." Ze neemt de telefoon op, die net gaat. |

### `connections.execution` (Marco)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Marco | "Marco, wil je me laten zien hoe een aansluitdag eruitziet?" | "Kijk. Om zeven uur de bus in, adres, graven, aansluiten, klaar." Hij haalt zijn schouders op. "Mijn mannen kunnen dit." |
| obstacle | Marco | "Wat maakt het werk van je mannen lastiger dan nodig?" | "Kantoor." Een stilte. "Nee, serieus: een verkeersplan regelen voor een straat waar niemand rijdt." |
| ok | Marco | "Loopt het vandaag?" | "Het loopt." |
| who | Marco | "Welke monteur maakt de meeste fouten?" | Hij kijkt je aan zonder iets te zeggen. Dan: "Zo begon het in 2012 ook." |

### `connections.commissioning` (Ahmed)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Ahmed | "Ahmed, wil je me laten zien hoe je een aansluiting oplevert?" | "Gewoon. Meten, meter erin, schakelaar om. Echt wel snel, man." |
| last | Ahmed | "Wat ging er de laatste keer mis bij een oplevering?" | "Mis? Niks, toch. Nou ja, de klant had zijn wasmachine al aangesloten voordat ik klaar was." |
| standard | Ahmed | "Doe je de metingen volgens de checklist?" | "Ja, toch." |

### `connections.revision` (Mieke)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Mieke | "Mieke, wil je laten zien hoe een revisie gaat?" | "Dat moet kloppen, dus ik doe het rustig." Ze laat zien hoe een schets een lijn in GIS wordt. |
| obstacle | Mieke | "Wat maakt jouw werk lastiger dan nodig?" | "Het systeem. Na elke update staan de knoppen ergens anders." Ze glimlacht. "Daar wen ik wel aan." |
| standard | Mieke | "Werken jullie op volgorde van binnenkomst?" | "Ja. Dat moet kloppen." |
| behind | Mieke | "Waarom loopt GIS zo achter op de straat?" | "Achter?" Ze legt haar potlood neer. "Mijn team tekent wat het krijgt." |

### `connections.close_out` (Petra)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Petra | "Petra, wil je laten zien hoe een aansluiting bij jou wordt afgerond?" | "Klopt, dat kan." Ze opent haar map. "Alles staat in mijn map. Stap voor stap." |
| obstacle | Petra | "Wat maakt jouw werk lastiger dan nodig?" | "Ik ben hier alleen. Als ik ziek ben, blijft het liggen." |
| ok | Petra | "Loopt het een beetje?" | "Klopt. Het loopt." |

### `customer_contact.answer` (Esra, Kim, Saskia)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Esra | "Esra, wil je laten zien hoe een gesprek bij jullie loopt?" | "Kijk, gewoon eerlijk: aannemen, luisteren, opzoeken, antwoorden." Ze doet de wachtmuziek na. "En dit hoort de klant ertussendoor." |
| obstacle | Kim | "Kim, wat maakt je werk lastiger dan nodig?" | "De headsets. Na een uur knellen ze." Ze lacht. "Nee, echt." |
| standard | Saskia | "Gebruiken jullie een vaste opbouw voor een gesprek?" | "Ja hoor. Begroeten, vraag, oplossing, afsluiten." |
| behind | Esra | "Waarom duren de gesprekken hier zo lang?" | "Serieus?" Ze kijkt je recht aan. "Mijn mensen zijn niet traag." |

### `outages.report` (Kees)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Kees | "Kees, wat gebeurt er als er een storing binnenkomt?" | "Melding. Kijken op de videowand. Schakelen." Hij wijst naar het scherm. "Zo komt het licht terug." |
| obstacle | Kees | "Wat maakt jouw werk lastiger dan nodig?" | "De nacht. Dan ben ik alleen met de wand." |
| standard | Kees | "Schakel je altijd volgens de instructie?" | "Altijd." |

### `outages.locate` (Henk, Ahmed, Gert)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Henk | "Henk, wil je me laten zien hoe je een fout zoekt?" | "Ik laat het je wel zien, {jongen_meid}. In '87 hadden we alleen een kaart en onze oren." |
| obstacle | Ahmed | "Ahmed, wat maakt het zoeken lastiger dan nodig?" | "Gewoon, de oude wijken. Mijn navigatie kent Nova-Oud beter dan ik." |
| last | Gert | "Gert, wat ging er de laatste keer mis bij het graven?" | "Mis? Een buurman die zijn hond losliet bij de sleuf." Hij lacht kort. "Verder niks." |
| who | Ahmed | "Wie had deze kabel als laatste in handen?" | "Dat moet ik Henk vragen." Ahmed kijkt naar de grond. |

### `outages.repair` (Dirk)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Dirk | "Dirk, hoe komt een mof van het magazijn in de bus?" | "Ik heb ze gewoon liggen." Hij wijst naar de vakken. "Wie iets nodig heeft, pakt het." |
| ok | Dirk | "Heb je genoeg op voorraad?" | "Hm. Genoeg." |
| behind | Dirk | "Waarom ligt er zo vaak het verkeerde materiaal in de bus?" | "Hm." Dirk draait zich om naar de vakken. "Dat is niet het magazijn." |

### `meters.appointment` (Linda)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Linda | "Linda, hoe plan je een meterwissel in?" | "Snel, sorry. Postcode, monteur, dag. En dan hopen dat het kaartenhuis blijft staan." |
| obstacle | Linda | "Wat maakt het inplannen lastiger dan nodig?" | "Omplannen. Als er een monteur ziek is, schuift alles." |
| ok | Linda | "Loopt het inplannen goed?" | "Ja. Meestal wel." |

### `meters.visit` (Ahmed)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Ahmed | "Ahmed, hoe gaat een meterwissel?" | "Gewoon. Aanbellen, kast open, wisselen. Als het meezit, ben je zo klaar." |
| obstacle | Ahmed | "Wat maakt het werk lastiger dan nodig?" | "Honden." Hij grijnst. "Echt wel." |
| ok | Ahmed | "Gaat het goed vandaag?" | "Ja, toch." |

### `meters.registration` (Petra)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Petra | "Petra, hoe registreer je een nieuwe meter?" | "Bon erin, serienummer aan de EAN koppelen, klaar. Klopt het niet, dan gaat het in mijn map." |
| standard | Petra | "Registreer je alles op dezelfde dag?" | "Klopt." |

### `congestion.intake` (Thomas)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Thomas | "Thomas, wat gebeurt er met een aanvraag voor capaciteit?" | "Mijn klanten vragen, wij rekenen, en dan wachten we samen." Hij glimlacht. "Meestal bij een lunch op het bedrijventerrein." |
| obstacle | Thomas | "Wat maakt jouw werk lastiger dan nodig?" | "Nee zeggen tegen mensen die ik ken. Dat is het lastigste." |
| ok | Thomas | "Loopt het een beetje met de aanvragen?" | "Ja hoor. Het loopt." |

### `congestion.congestion_study` (Femke)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Femke | "Femke, hoe stel je vast of het net vol is?" | "Kort gezegd: alles wat is aangevraagd erin, en kijken of het past." Ze tekent een station met pijlen. |
| standard | Femke | "Rekenen jullie volgens de landelijke methode?" | "Ja. Dat past." |

### `congestion.offer` (Thomas)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Thomas | "Thomas, hoe komt een aanbod tot stand?" | "Ik ga erheen, ik leg het uit, en dan tekenen ze. Of niet." |
| ok | Thomas | "Tekenen de klanten een beetje?" | "De meesten wel." |

### `voltage_complaints.analysis` (Petra)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Petra | "Petra, hoe beoordeel je een spanningsklacht?" | "Klopt het verhaal, dan gaat er een monteur heen met een meetkastje. Een week meten." |

### `voltage_complaints.measurement` (Ahmed)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Ahmed | "Ahmed, wat doe je bij een spanningsklacht?" | "Kastje ophangen, week wachten, kastje ophalen. Gewoon." |
| ok | Ahmed | "Meet het kastje goed?" | "Ja, toch." |

### `voltage_complaints.tap_change` (Ahmed)
| id | Person | The player says | Reply |
|---|---|---|---|
| walk | Ahmed | "Ahmed, wat doe je in het trafohuisje?" | "Trafo uit, aftakking om, trafo weer aan. Henk heeft het me laten zien." |

The waiting steps (`connections.grid_reinforcement`, `connections.permit`, `connections.close_out_wait`, `congestion.capacity_queue`) have no people and no questions.

## 4. Observations (Waarneming)

Each tool at each place has 2–3 lines: 3 at Intake and Werkvoorbereiding, which the training week visits most, and 2 elsewhere. The lines describe how the work really runs. None names a mission's cause or countermeasure. Some are plausible red herrings (the slow system on Monday, the headsets, the vacancies), and none contradicts a problem's clue while that problem is active. They carry no numbers, except where a number has a source (see `voltage_complaints.measurement`). Sector facts used: EAN registration in the national connection register makes switching supplier possible; a KLIC request before digging is a legal duty (WIBON); BEI authorisations; the smart meter swap is free; the voltage band is 230 V ±10 % (EN 50160 / Netcode elektriciteit); non-firm and time-bound transport rights exist (ACM, 2024); billing goes through the energy supplier.

```yaml
connections.intake:
  listen_in:
    - "Een installateur belt namens een klant: kan er een laadpaal op dezelfde aansluiting? Rachid zoekt het aansluitvermogen op in het dossier en legt uit wat een verzwaring kost."
    - "Een klant vraagt wat een EAN-code is. Sanne legt het uit zonder op haar scherm te kijken; ze heeft het vaker gedaan."
    - "Een aannemer wil voor een nieuwbouwproject een hele straat tegelijk aanvragen. Het portaal kent één adres per aanvraag; Rachid zet de rest in een Excelbestand."
  documents:
    - "De aanvragen staan in het portaal op volgorde van binnenkomst. Bij elk dossier hoort een checklist die Intake afvinkt voordat het naar de offerte gaat."
    - "Veel aanvragen van deze week zijn verzwaringen voor een warmtepomp of een laadpaal; de rest is nieuwbouw."
    - "Bij een paar dossiers staat in de kantlijn 'klant gebeld, belt terug'. Er staat geen datum bij."
  queue_count:
    - "De werkbak telt alleen wat nog geen behandelaar heeft. Wat Rachid of Sanne al heeft geopend, staat onder hun eigen naam."
    - "Op het whiteboard naast Sanne staat het aantal van gisteren, met een pijl erbij. Niemand weet meer of een pijl omhoog goed of slecht is."
    - "Rachid sorteert de werkbak op postcode; Sanne op datum. Ze wisselen het af, afhankelijk van wie er het eerst is."
  data:
    - "Het systeem telt aanvragen per dag en per postcode. Maandag is altijd de drukste dag: dan staat erin wat in het weekend via het portaal binnenkwam."
    - "Nova-Oost en het nieuwe bedrijventerrein leveren de meeste aanvragen. De rest is verspreid over de regio."
    - "Per medewerker staat hoeveel aanvragen hij deze week heeft verwerkt. Sanne heeft die kolom zelf verborgen."
connections.design:
  shadow:
    - "Anouk opent een dossier, zoekt het adres op in GIS, tekent het tracé van de kabel en maakt een materiaalstaat. Tussendoor belt Planning twee keer over een ander dossier."
    - "Voor een oud huis vraagt Anouk een schouw aan: een monteur moet eerst kijken waar de meterkast precies zit."
    - "Joost komt langs met een vraag over de overuren van vorige maand. Anouk maakt eerst haar lijn af voordat ze antwoordt."
  documents:
    - "Op elke tekening staan het tracé, de kabellengte, de aansluitkast en de kabels en leidingen uit de KLIC-melding. Anouk gebruikt kleuren die je terugvindt in de legenda."
    - "Sommige tekeningen zijn van vorig jaar en opnieuw geopend, omdat de klant toch een ander vermogen wilde. De oude versie staat doorgestreept in het dossier."
    - "Naast de tekeningen staat een map 'bijzondere situaties': een monumentaal pand, een aansluiting over een sloot, een boom met beschermde wortels."
  queue_count:
    - "De stapel is een digitale werkbak plus een plank met papieren dossiers die nog niet zijn ingescand."
    - "In de werkbak staan per dossier de datum van binnenkomst en de naam van de klant."
    - "Op de plank liggen ook een paar dossiers met een geel briefje: 'wacht op schouw'."
  time_study:
    - "Je klokt een ontwerp van begin tot eind. Het tekenen zelf gaat snel; het opzoeken van wat er al in de grond ligt, kost meer tijd."
    - "Halverwege moet Anouk een vraag stellen aan Netstudies over de straat. Ze wacht op antwoord en begint intussen aan een ander dossier."
    - "Anouk werkt met twee schermen: links GIS, rechts de tekening. Ze kent de sneltoetsen uit haar hoofd."
  data:
    - "Het systeem telt ontwerpen per week en per werkvoorbereider. Joost houdt er een eigen Excel naast, met extra tabbladen."
    - "De ontwerpen zijn verdeeld over nieuwbouw, verzwaringen en verleggingen. Verleggingen zijn de kleinste groep."
    - "De overuren van Werkvoorbereiding staan per week in een grafiek. Na de zomer lopen ze op."
connections.grid_study:
  shadow:
    - "Femke zet de nieuwe aansluiting in het netmodel van de wijk en laat het rekenprogramma lopen. Intussen tekent ze op een kladblok hoe de kabels van het station lopen."
    - "Een collega vergelijkt de uitkomst van een berekening met de metingen in het middenspanningsstation. Ze komen aardig overeen."
  documents:
    - "De werkinstructie is een paar pagina's, met een stroomschema en een lijst met uitzonderingen. De laatste versie is van een paar jaar geleden."
    - "Bij elke studie zit een rapport met een kaartje van de wijk, de belasting van de kabels en een conclusie in één zin."
  time_study:
    - "Het meeste werk zit in het opbouwen van het model van de straat; de berekening zelf loopt in een paar minuten."
    - "Tussen twee studies door beantwoordt Femke vragen van Werkvoorbereiding over kabeldiktes."
  data:
    - "De studies zijn verdeeld over woningen, bedrijven en laadpleinen. De laadpleinen zijn het snelst gegroeid."
    - "Per station staat in een tabel de belasting op het drukste moment van het jaar. Een paar stations kleuren oranje."
connections.grid_reinforcement:
  documents:
    - "Elk dossier van een netverzwaring heeft een ontwerp, een begroting en een lijst met parafen. Bij een paar zit een brief van de gemeente over de plek van een nieuw station."
    - "In een dossier zit een foto van een trafohuisje dat te klein is voor een grotere transformator. Erbij staat: 'nieuwe plek zoeken'."
  data:
    - "De verzwaringen staan in een lijst per wijk. Nova-Oost staat bovenaan, met de meeste wachtende aansluitingen erachter."
    - "Bij elke verzwaring staat een geplande opleverdatum. Een paar data zijn al eens verschoven."
connections.permit:
  documents:
    - "Een vergunningsaanvraag beschrijft het tracé, hoe er gegraven wordt en wanneer de bestrating wordt hersteld. De gemeente wil ook weten welke bomen er staan."
    - "Voordat er gegraven wordt, moet er een KLIC-melding zijn gedaan: wie graaft, moet weten welke kabels en leidingen er al liggen."
  data:
    - "Per gemeente staat in een tabel hoe lang een vergunning duurt. Nova is de snelste; de kleinere gemeenten wisselen."
    - "Een paar aanvragen kwamen terug met een vraag over de verkeersmaatregelen tijdens het graven."
connections.planning:
  documents:
    - "De weekplanning is een groot rooster: monteurs per rij, dagen per kolom, klussen in vakjes met een kleur per soort werk."
    - "Bij sommige klussen staat een sterretje: de KLIC-melding moet nog worden gedaan."
  queue_count:
    - "In de werkbak van Planning liggen klussen die klaar zijn voor uitvoering maar nog geen datum hebben. Linda sorteert ze op postcode."
    - "Een aparte lijst houdt de vervolgafspraken van storingen bij. Die gaan voor."
  data:
    - "Het systeem toont per week hoeveel klussen er gepland stonden en hoeveel er zijn gedaan. Linda kijkt er vooral op vrijdag naar."
    - "Per monteur staat in een kolom welke aanwijzing hij heeft volgens de BEI. Niet iedereen mag alles."
connections.execution:
  shadow:
    - "De monteur graaft een sleuf van de straat naar de gevel, legt de kabel, maakt de mof en zet de aansluitkast. Het weer zit mee; het werk gaat vlot."
    - "Bij het eerste adres wacht de monteur tot een buurman zijn auto heeft weggezet. Intussen drinkt hij koffie uit zijn thermosfles."
  time_study:
    - "Je klokt een aansluiting: graven, kabel leggen, moffen, aansluitkast plaatsen, dichtgooien. Het moffen vraagt de meeste precisie."
    - "De monteur werkt in een vaste volgorde en legt zijn gereedschap telkens op dezelfde plek in de bus terug."
  material_check:
    - "In de bus liggen kabelhaspels, moffen en aansluitkasten. Alles staat vast met spanbanden."
    - "Achterin staat een doos met kleine onderdelen: kabelschoenen, tape, krimpkousen."
  data:
    - "Per monteur staan de afgemelde klussen per week in een lijst. De verschillen tussen monteurs zijn klein."
    - "De uitvoering heeft een eigen afmeldcode voor 'weersomstandigheden'. In de winter wordt die vaker gebruikt."
connections.commissioning:
  shadow:
    - "De monteur meet de spanning, plaatst de meter, controleert de draairichting en zet de hoofdschakelaar om. Het licht in de meterkast gaat aan."
    - "De klant kijkt mee en vraagt of de laadpaal nu kan. De monteur zegt dat de installateur daarover gaat."
  documents:
    - "Bij elke oplevering hoort een formulier met de meterstand, het meternummer en de EAN-code."
    - "De oplevering heeft een checklist met veiligheidsmetingen. Elk vakje is aangekruist."
  time_study:
    - "Het in bedrijf nemen zelf gaat snel. De klant moet eerst de meterkast vrijmaken."
    - "De monteur doet de metingen in een vaste volgorde, uit zijn hoofd."
connections.revision:
  queue_count:
    - "De bak met schetsen staat naast Miekes scherm. Daarnaast ligt een mapje met schetsen waar ze nog een vraag over heeft."
    - "In GIS staat een filter 'nog te reviseren'. Mieke opent het elke ochtend als eerste."
  documents:
    - "Op de schetsen staan de kabel, de mof en de afstanden tot de gevel. Sommige zijn met potlood, andere met balpen."
    - "Bij een schets zit een kopie van de KLIC-kaart, met de nieuwe kabel er met de hand bij getekend."
  time_study:
    - "Mieke tekent de kabel in GIS, vult de kenmerken in (type, doorsnede, jaar) en controleert hoe hij op het net aansluit. Ze werkt zorgvuldig en in stilte."
    - "Halverwege haalt ze een boterham uit een zakje met een vlek pindakaas. Daarna tekent ze verder."
  data:
    - "GIS houdt per kabel bij wanneer en door wie hij is ingetekend. De oudste kabels in Nova-Oud zijn nooit digitaal nagemeten."
    - "Per week staat er hoeveel revisies zijn afgerond. Het getal schommelt met de vakanties."
connections.close_out_wait:
  data:
    - "Elke aansluiting heeft een status: in uitvoering, technisch gereed, administratief open, gesloten. Elke status heeft een eigen kleur."
    - "Bij 'technisch gereed' staat de datum waarop de monteur heeft afgemeld."
  queue_count:
    - "De dossiers die op afhandeling wachten, staan in een lijst die je kunt filteren op datum en op wijk."
    - "In de lijst staan ook een paar dossiers met de opmerking 'meter nog niet geregistreerd'."
connections.close_out:
  documents:
    - "Petra's map heeft een tabblad per maand. In elk tabblad zit een lijst met EAN-codes en een vinkje per stap."
    - "Om een aansluiting aan te melden, vult Petra de gegevens in het landelijke aansluitingenregister in. Daarna kan de klant een energieleverancier kiezen."
  queue_count:
    - "Op Petra's bureau ligt een kleine stapel post. De rest is digitaal."
    - "Op het scherm staat een teller met openstaande taken. Petra heeft het geluid uitgezet."
  data:
    - "Het systeem telt de aanmeldingen per energieleverancier. De grote leveranciers krijgen de meeste klanten."
    - "Een tabel houdt per wijk bij hoeveel meters op afstand worden uitgelezen."
customer_contact.answer:
  listen_in:
    - "Een klant belt over een storing in zijn straat. Kim kijkt op de storingskaart en zegt dat er een monteur onderweg is."
    - "Een vrouw vraagt waarom haar voorschot omhoog is gegaan. Saskia legt uit dat dat bij de energieleverancier ligt, niet bij de netbeheerder."
    - "Een man wil zijn meter laten verplaatsen voor een verbouwing. Kim zet de aanvraag voor hem klaar in het portaal."
  queue_count:
    - "Het wachtrijbord aan de muur toont hoeveel bellers er wachten en hoe lang de langste al wacht. Het getal wisselt elke paar seconden."
    - "Naast het bord hangt een A4'tje: 'Eerst de klant, dan de notitie.'"
  time_study:
    - "Elk gesprek eindigt met een korte notitie in het klantsysteem. Wie snel typt, is eerder klaar voor het volgende gesprek."
    - "Tussen twee gesprekken zet Kim haar headset even af en drinkt water. Het lampje op het bord springt meteen weer aan."
  data:
    - "Het systeem telt gesprekken per uur. Rond negen uur en na de lunch is het het drukst."
    - "Bij elk gesprek kiest de agent een reden uit een lijst. 'Overig' wordt het vaakst gekozen."
outages.report:
  listen_in:
    - "Een melding komt binnen: een straat in Nova-Oud zonder stroom. Kees ziet op de videowand welke kabel is uitgevallen en belt de storingsdienst."
    - "Een beller meldt knipperend licht. Kees vraagt of de buren het ook hebben; dan weet hij of het in het huis zit of in het net."
  documents:
    - "Voor elk middenspanningsstation is er een schakelinstructie: welke schakelaar eerst, welke daarna. Een geplastificeerde kopie hangt in een map bij de videowand."
    - "Een schakelopdracht wordt door een tweede persoon gecontroleerd voordat hij wordt uitgevoerd."
  data:
    - "Het logboek houdt per storing de tijden bij van melden, uitrukken, lokaliseren en herstellen. De velden zijn verplicht."
    - "Elke storing krijgt een oorzaakcode. 'Onbekend' komt vaker voor dan je zou denken."
outages.locate:
  shadow:
    - "De monteur rijdt naar het middenspanningsstation, opent de deur en kijkt welke schakelaar is uitgevallen. Dan begint het zoeken langs de kabel."
    - "Vanuit een meetwagen stuurt de monteur een puls door de kabel. Op het scherm verschijnt een piek: daar ergens zit de fout."
  time_study:
    - "Het lokaliseren bestaat uit drie delen: het juiste station vinden, de foutplaats voormeten en de plek nameten in de straat."
    - "Tussen het voormeten en het nameten rijdt de monteur een paar straten verder. Het verkeer bepaalt hoe lang dat duurt."
  documents:
    - "De kabelkaarten tonen per straat de kabels, het type en het jaar van aanleg. Op de kaarten van oude wijken staan handgeschreven aantekeningen."
    - "Als er gegraven werd, zit de KLIC-melding van de aannemer los in het storingsdossier."
  data:
    - "De storingen staan op een kaart van Nova. De meeste zitten in de oudste wijken."
    - "Per kabeltype is te zien hoe vaak het storing geeft. Oude papierloodkabels staan bovenaan."
outages.repair:
  shadow:
    - "De monteur graaft de fout bloot, zaagt het beschadigde stuk kabel eruit en maakt twee moffen. Een collega houdt de sleuf droog met een pomp."
    - "Voor het moffen zet de monteur een tentje over de sleuf, zodat het droog blijft."
  material_check:
    - "In de bus liggen moffen van verschillende merken. Op de dozen staat met stift voor welk kabeltype ze zijn."
    - "In het magazijn ligt elke soort mof in een eigen vak met een etiket. Dirk weet zonder te kijken waar alles ligt."
  time_study:
    - "Het moffen zelf is precisiewerk: strippen, schoonmaken, krimpen. Daar haast niemand zich."
    - "Na het herstel wacht de monteur op het telefoontje van de meldkamer dat de kabel weer onder spanning gaat."
  data:
    - "Per storing staat hoe lang het herstel duurde. De lange herstellingen zijn vaak 's nachts."
    - "Het systeem telt hoeveel moffen er per maand worden gebruikt. In de winter zijn het er meer."
meters.appointment:
  documents:
    - "De afspraakbrief noemt de datum, het adres en wat de klant moet doen: de meterkast vrijmaken en thuis zijn."
    - "In de brief staat een link om de afspraak te verzetten. Weinig klanten gebruiken hem."
  listen_in:
    - "Linda belt een klant om een meterwissel in te plannen. De klant vraagt of het na vijf uur kan; dat kan niet."
    - "Een klant belt terug over de brief en vraagt of de wissel iets kost. Dat doet hij niet."
  data:
    - "Per wijk staat hoeveel meters er dit jaar gewisseld moeten worden. Nova-Oud loopt achter op het schema."
    - "Het systeem toont per dag hoeveel afspraken er zijn gemaakt en door wie."
meters.visit:
  shadow:
    - "De monteur belt aan, zegt wie hij is en vraagt naar de meterkast. Hij legt een kleedje op de vloer voordat hij begint."
    - "Bij het wisselen gaat de stroom even van het huis af. De monteur zegt het van tevoren, zodat niemand schrikt."
  time_study:
    - "Je klokt een meterwissel: de oude meter eraf, de nieuwe erop, de standen noteren, verzegelen."
    - "Tussen twee adressen zoekt de monteur een parkeerplek. In de oude wijk duurt dat het langst."
  material_check:
    - "In de bus liggen dozen met slimme meters, zegels en communicatiemodules in losse zakjes."
    - "Op elke doos zit een sticker met het serienummer. De monteur scant hem voordat hij de meter plaatst."
  data:
    - "Per monteur staat hoeveel meters hij per dag wisselt. Het aantal verschilt per wijk."
    - "Bij elk bezoek wordt een uitkomst vastgelegd: gewisseld, niet thuis, kast niet bereikbaar."
meters.registration:
  data:
    - "Het systeem laat per meter zien of hij vandaag standen heeft gestuurd: een groen bolletje of een rood."
    - "Per wijk is te zien hoeveel meters op afstand worden uitgelezen."
  queue_count:
    - "De lijst met meters die nog geregistreerd moeten worden, staat op volgorde van plaatsingsdatum."
    - "Een paar regels hebben een opmerking: 'serienummer klopt niet met de bon'."
  documents:
    - "Bij elke meter hoort een plaatsingsbon met het serienummer, de meterstand en de EAN-code. De bonnen komen digitaal binnen."
    - "Op sommige bonnen staat een opmerking van de monteur: 'kast krap', 'hond'."
congestion.intake:
  listen_in:
    - "Een ondernemer belt over een nieuwe koelcel. Thomas vraagt hoeveel vermogen hij nodig heeft en wanneer. Het antwoord: zo veel mogelijk, zo snel mogelijk."
    - "Een projectontwikkelaar vraagt of er nog ruimte is voor een laadplein. Thomas legt uit dat er een wachtrij is en hoe die werkt."
  documents:
    - "Elke aanvraag noemt het gevraagde vermogen, het adres en de gewenste startdatum. Sommige aanvragen zijn al een jaar oud."
    - "Bij één aanvraag zit een brief van een wethouder die vraagt om voorrang voor een nieuwe school."
  data:
    - "De wachtrij staat op volgorde van binnenkomst. Bovenaan staan vooral bedrijven van het nieuwe bedrijventerrein."
    - "Per station staat hoeveel capaciteit er is aangevraagd. Bij een paar stations is dat meer dan het station aankan."
congestion.congestion_study:
  shadow:
    - "Femke zet de aanvragen uit de wachtrij één voor één in het model. Bij elke aanvraag kijkt ze of het station het nog houdt."
    - "Ze overlegt met de landelijke netbeheerder over een nieuw station dat over een paar jaar klaar moet zijn."
  documents:
    - "Het congestieonderzoek beschrijft per station de verwachte belasting en of er ruimte is. Het eindigt met een kaart in groen, oranje en rood."
    - "In een bijlage staan de afspraken met de landelijke netbeheerder over hoeveel vermogen er van het hoogspanningsnet kan komen."
  data:
    - "De metingen van het station beslaan het hele jaar. In de winter en op zonnige middagen zijn de pieken het hoogst."
    - "De belasting is per kwartier opgeslagen. Het bestand is zo groot dat het rekenprogramma er even over doet."
congestion.capacity_queue:
  queue_count:
    - "De wachtrij is een lijst op het scherm. Wie van de lijst afgaat, verdwijnt zonder opmerking."
    - "Naast de lijst houdt Thomas een eigen lijstje bij van klanten die hem elke maand bellen."
  data:
    - "Bij elke aanvrager in de wachtrij staan het gevraagde vermogen en de sector: logistiek, bouw, zorg, onderwijs."
    - "Een paar aanvragers staan al op de lijst sinds de wachtrij begon."
  documents:
    - "Elke aanvrager krijgt een brief met zijn plek in de rij en de verwachte datum van de netverzwaring."
    - "In de standaardbrief staat dat die datum kan verschuiven."
congestion.offer:
  documents:
    - "Een aanbod noemt het vermogen, de startdatum en de voorwaarden. Er zijn drie soorten: vast, niet-vast en tijdsduurgebonden."
    - "Bij elk contract zit een bijlage met de technische gegevens van de aansluiting."
  data:
    - "Per klant staat het gecontracteerde vermogen in een tabel. De grootste klanten staan bovenaan."
    - "Het systeem toont per maand hoeveel aanbiedingen zijn verstuurd en hoeveel er zijn getekend."
voltage_complaints.analysis:
  data:
    - "Elke spanningsklacht krijgt een adres, een omschrijving en een datum. Veel klachten gaan over knipperende lampen."
    - "De klachten staan op een kaart. Ze komen uit verschillende wijken, oud en nieuw."
  documents:
    - "De klant beschrijft wat hij merkt: 'de omvormer valt uit', 'de lampen knipperen', 'de wasmachine stopt'. Soms zit er een foto van een foutmelding bij."
    - "Op het formulier staat de vraag of de buren het ook merken. De meeste klanten laten die leeg."
voltage_complaints.measurement:
  shadow:
    - "De monteur hangt een meetkastje in de meterkast van de klant. Het legt een week lang de spanning vast."
    - "De klant vraagt of het kastje gevaarlijk is. De monteur legt uit dat het alleen meet."
  time_study:
    - "Het plaatsen van het kastje gaat snel. De meeste tijd zit in de rit en in het uitleggen aan de klant."
    - "De monteur noteert de meterstand en het tijdstip waarop het kastje begint te meten."
  data:
    # 230 V ±10 %: NEN-EN 50160 and the Netcode elektriciteit (the same band value_streams.yaml cites).
    - "Een meetweek levert een grafiek op met de spanning per uur. De norm is 230 volt, met tien procent marge naar boven en naar beneden."
    - "Bij elke meting staat welke wijktransformator het adres voedt."
voltage_complaints.tap_change:
  documents:
    - "Op een kaart in het trafohuisje staan het bouwjaar, het vermogen en de stand van de aftakking."
    - "In het onderhoudsboekje staan de inspecties. De laatste was dit voorjaar."
  shadow:
    - "Om de aftakking te verstellen, moet de trafo eerst spanningsloos. De monteur kondigt de onderbreking aan in de straat."
    - "In het trafohuisje hangt een schema van de vertrekkende kabels. Het is met de hand bijgewerkt."
```

## 5. The growing toolbox

| Day (mission) | `grant_tools` | Why it fits the day's goal |
|---|---|---|
| Mon `training_mon` | `conversation` | "kijk of vraag" at Intake and design: a question to Sanne or Rachid, and to Anouk or Joost, meets it (`note_use(place, "conversation")`). Ruud's briefing should read "…en vraag bij elk team hoe het werk binnenkomt." |
| Tue `training_tue` | `shadow`, `documents` | Two different pairs at design: shadow, documents and questions give three. |
| Wed `training_wed` | `queue_count` | Count at Intake and at design. |
| Thu `training_thu` | `time_study`, `data`, `listen_in`, `material_check` | The oefen-A3 needs one key clue on `training_tray`: shadow (Tue) or a question works; the time study adds the depth-1 clue. |
| Fri, and anything after | none | All eight tools are known from Thursday. `walk_connections` needs `queue_count`, which is known since Wednesday. |

**Everyone else gets all tools:** a returning player who skips the week, a player who skips mid-week, and an old save without `tools_known`.

**Ruud's morning note** shows the card(s) of the day's new tool(s), next to the move cards. Each card says what the tool is for, never when to use it. The text lives in `places.yaml` `tool_cards`:

| Tool | Title | Text |
|---|---|---|
| conversation | Vragen stellen | Wie het werk doet, weet hoe het loopt. Een vraag kost jullie allebei een halfuur. |
| shadow | Meelopen | Je loopt een halve dag mee en ziet het werk zoals het echt gaat, ook wat niemand opschrijft. |
| documents | Dossiers doorlezen | Papier en schermen laten zien wat er is afgesproken en wat er is vastgelegd. |
| queue_count | Wachtrij tellen | Je telt wat er ligt te wachten: hoeveel dossiers, en hoeveel dagen werk dat is. |
| time_study | Tijdstudie | Met een stopwatch meet je hoe lang een stap echt duurt, en waar de tijd binnen die stap heen gaat. |
| data | Data analyseren | Cijfers uit de systemen laten zien wat je met eigen ogen niet ziet: maanden, wijken, honderden dossiers tegelijk. |
| listen_in | Meeluisteren | Je hoort wat de klant zelf zegt, in zijn eigen woorden. |
| material_check | Materiaal checken | Je kijkt wat er in de bus of het magazijn ligt, en wat er ontbreekt. |

## 6. Schema sketch

```yaml
# content/places.yaml — what the player can do at each place ("stream.step").
# Game text is Dutch; keys are English. Built by tools/build_content.py into game/data/places.json.
#
# people_also  cast ids met here besides those whose dialogs.yaml `place` is here
# tools        2-5 investigation tools that fit here (never `conversation`), each with
#              label (the button, without duration) and observations (2-3 Dutch lines)
# questions    0-4 {id (Investigation.QUESTIONS, not `thanks`), person, text, reply}

places:
  connections.intake:
    tools:
      listen_in:
        label: "Luister mee met een aanvraaggesprek"
        observations:
          - "Een installateur belt namens een klant: …"
      documents: {label: "Blader door de aanvragen van deze week", observations: ["…", "…", "…"]}
      queue_count: {label: "Tel de inbox", observations: ["…"]}
      data: {label: "Draai de intakecijfers uit het systeem", observations: ["…"]}
    questions:
      - {id: walk, person: sanne, text: "Sanne, wil je me laten zien …?", reply: "\"Nou, kijk. …\" Ze klikt …"}
      - {id: obstacle, person: rachid, text: "…", reply: "…"}
  connections.commissioning:
    people_also: [ahmed]
    tools: {…}

tool_cards:
  - {tool: conversation, title: "Vragen stellen", text: "Wie het werk doet, …"}
  - {tool: shadow, title: "Meelopen", text: "…"}
```

`missions.yaml`, on training missions only: `grant_tools: [shadow, documents]`.

**Validator** (`tools/build_content.py --check`, with pytest):
1. Every place used by a mission (`observe` places, the work steps of a `walk` stream), by a problem (`step`, clue `at`), by a `discoveries.yaml` trigger with a full place, or by a room in `world.yaml` has an entry.
2. Each entry has 2–5 tools. Every tool is in `Investigation.TOOLS` and is not `conversation`, and has a non-empty label and 2–3 observations.
3. Every clue's `tool` is in its place's tools. For a `conversation` clue, the place has at least one open question (`walk`, `obstacle` or `last`).
4. At most 4 questions per place. No `thanks`, and no question id twice. `person` is someone whose `place` is this place or who is listed in its `people_also`.
5. A discovery's `{place, tool}` is in the lists.
6. Across the training missions, `grant_tools` grants each of the 8 tools exactly once, and `conversation` on the first day. The tools an `observe` goal names (`tool:`) are granted on or before that mission's day.
7. Each tool has exactly one `tool_cards` entry.
8. The text checks that already run on content (no "niets nieuws", Dutch text present) also run on the observations.

**Rules and save:**
- `GameSession.tools_known: Array[String]` is saved. A missing field means all tools. `Missions.accept` of a training mission adds its `grant_tools`, and a skip adds all of them.
- `GameSession.use_tool(place, tool)` refuses with `tool_not_here` when the tool is not in the place's list, and with `tool_not_known` when the player does not know it yet (Dutch in `UiText.PLACE_ERRORS`). `ask` refuses a question that is not one of the place's questions (`unknown_question`), except `thanks` after a blame or guarded reply there. Region stays free of content: the session checks.
- With no clue: if `queue_count`, the count; then the next observation for `place.tool` (`observation_seen: {"place.tool": n}`, saved, line `n % len`); then the spotted line and the hidden signal, as now. The journal gets `{kind: "waarneming", day, place, tool, text}`. **`NOTHING_NEW` is deleted.**
- UI (`place_menu.gd`): people come first, each with their question chips under their name ("Sanne" → the two chips Sanne answers), then a "Praat met …" talk where one is open. Then the tools that are both known and fit the place, as `label (duur)`. Nothing is greyed out. The `thanks` chip appears under the person who gave the blame or guarded reply, after that reply.

## 7. Tests (TDD, watch each fail first)

1. **Menu per day:** at `connections.intake` and `connections.design`, the menu shows Monday only people and questions; Tuesday adds `shadow`/`documents` where they fit (design gets both, Intake only `documents`); Wednesday adds `queue_count`; Thursday shows the full lists (Intake 4 tools, design 5).
2. **Monday at Intake:** asking Sanne `walk` with no problem known returns her reply line, not `nobody` and not empty.
3. **No "niets nieuws":** with no clue ready, every place × tool in `places.yaml` returns an observation. The string `Je vindt hier niets nieuws` exists nowhere in `game/` or `content/`.
4. **Observation cycle:** using one tool at one place n+1 times shows all n lines once before any repeats. The cycle survives a save and load. Each use writes one "Waarneming" to the journal.
5. **Refusals:** `use_tool` refuses a tool that does not fit the place (`time_study` at Intake) and a tool not yet known on Tuesday (`data`).
6. **Clue reachability (content):** every tier-1 clue's tool is in its place's list, and every conversation clue's place has an open question (§2).
7. **Training week end to end:** an autoplay that uses only the menu's offered actions completes `training_mon` through `training_fri` and `walk_connections`.
8. **Old save:** a save without `tools_known` loads with all 8 tools; a skip of the week grants all 8.
9. **Python validator tests** for rules 1–7 of the validator, each with a failing fixture.
10. **Screenshots** of Intake and design on Monday and Thursday (plan §B). The designer then audits them the way Merijn played.
