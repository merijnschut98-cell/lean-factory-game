# Hoe werkt het? #2: de transformator (PLAN 2.7c)

> Status: by the explainer agent S3-X (Claude, 2026-10-24). The second "Hoe werkt het?" explainer, needed in Act II (`fix_transformer_wait`, `fix_unused_capacity`, Femke's expert talk `femke_expert`) and opened from the trafohuisje mock-up on the opleidingsterrein. Built through the pipeline of the first one (`2026-10-16-explainer-spanning-stroom-weerstand.md` §6: anatomy figure → SVG layers + manifest → `content/explainers.yaml` → `ExplainerView`), which this explainer generalises (§6 here). Dutch game text, English ids and comments; every number from the approved list or marked `estimate:` with its reasoning.
>
> Read with: CLAUDE.md §2 (immersion, evidence first, nothing handed over, respect the player's time); PLAN 2.7c (simple first with an everyday analogy; one or two controls with a live readout; the how, never the answer; always optional; kept in the codex); the Dutch style guide (`2026-10-19-dutch-style-guide.md`: spoken office Dutch, Ruud's voice, no digits in explainer beats).

---

## 1. The teaching layer (written before anything is drawn)

### 1.1 The one idea

**The one idea a player should be able to say back:** *"Een trafo ruilt spanning in voor stroom, en hoe meer stroom de straat vraagt, hoe warmer hij wordt."*

Two supporting ideas are shown, not stressed: a trafo can carry more than its nameplate for a while, but not for ever (the hours under the readout), and on a hot day that while is shorter. Everything else (the ratio, kVA, the √3, the loading guide's exponents, ageing) is behind **"Laat de rekensom zien"**.

**One idea per beat** (§4's last column), as in explainer #1.

### 1.2 The analogy and the order of reveal

**The analogy: the gears of a bicycle**, on a fietstrainer (a home trainer, the bike's back wheel on a roller with a resistance knob). In a light gear you pedal **fast and light**; the back wheel turns **slower but strong**. The gears trade speed for force, and nothing is gained or lost but a little warmth in the chain.

- the **spanning** is the **tempo** (how fast the pedals or the wheel go round; it stays the same whatever the load, as the voltage does);
- the **stroom** is the **kracht** (how hard you push or the wheel pulls; it grows with the load);
- the **trapper** side is the **middenspanning** (fast and light: high voltage, little current); the **wiel** side is the **laagspanning** (slow and strong: low voltage, much current);
- the **weerstand van de trainer** (the knob: "een berg op") is **de vraag van de straat**;
- the **ketting** is the **ijzeren kern met de wikkelingen**: it passes the work from one side to the other;
- the chain warms under a heavy load, as the windings do.

**Same picture, two skins** (as #1): the bike drivetrain stands on the bench in the same slots as the transformer. The trapper with its small chainring stands where the 10 kV cable and its bushings stand; the chain loops where the core and windings stand; the back wheel and roller stand where the low-voltage side and the laagspanningsrek stand; the trainer's resistance unit stands where the street (four small houses) stands. Two parts are **shared** and do not cross-fade: the **load knob** on its control box (the trainer's knob is the training rig's knob: on the opleidingsterrein the mock-up has one) and the **wall thermometer** (the weather is the same for a cyclist and a trafo).

**Order of reveal:**

1. **Tempo en kracht**: the pedals go round fast and light, the wheel slow and strong (no load yet).
2. **Zwaarder**: the knob up; the wheel's force gauge climbs a lot, the pedal's a little; the tempo stays.
3. **Warm**: very heavy; the chain warms. The one idea, on a bike.
4. **Cross-fade** into the transformer, part for part.
5. **The mapping** in one line, then the names: erin hoge spanning en weinig stroom, eruit lage spanning en veel stroom.
6. **Where the analogy stops**: nothing moves in a trafo.
7. **The real heat**: the street up; the windings warm, the oil carries it to the cooling fins (the oil thermometer).
8. **Above the nameplate**: it holds a while, and the sheet says how long.
9. **The weather** (the second control): a hot day shortens that while; then the one idea again, with wear.

### 1.3 Mapping: analogy → real thing

The pairs are layer pairs in the manifest (`pair`), the content's `analogy.mapping` and test T10.

| In the analogy (what you see) | Everyday meaning | The real thing | Its name in the game |
|---|---|---|---|
| de trapper met het kleine voorblad | fast and light: where the work goes in | de middenspanningskabel en de drie hoge doorvoeren | middenspanning, 10 kV |
| de ketting tussen de bladen | passes the work on | de ijzeren kern met de wikkelingen | kern, wikkeling |
| het grote achterblad en het wiel | slow and strong: where the work comes out | de vier lage doorvoeren en het laagspanningsrek | laagspanning, 400 V |
| de rol van de trainer met zijn rem | what asks for force | de straat (vier huizen) | de vraag van de straat |
| de krachtmeter bij de trapper | how hard you push | de stroommeter aan de middenspanningskant | stroom erin |
| de krachtmeter bij het wiel | how hard the wheel pulls | de stroommeter in het laagspanningsrek | stroom eruit |
| de ketting wordt warm | the cost of a heavy load | de wikkelingen en de olie worden warm (thermometer op de ketel) | warmte |
| de standaard van de fiets | holds it all | de ketel met olie en koelribben | ketel, olie, koelribben |

### 1.4 Where the analogy stops

**Said by Ruud (T3):** *"Eén verschil met de fiets: in een trafo beweegt niks. Er draait geen ketting. Het ijzer geeft het door, zonder dat de draden elkaar raken."*

| The analogy says | The truth | Where it is told |
|---|---|---|
| a chain moves the work across | nothing moves: the alternating current in one winding makes a changing magnetic field in the iron, which drives the current in the other (so a trafo only works on wisselstroom) | Ruud T3 (the first half); reveal (the second) |
| the small chainring is the fast side | in a trafo the fast (high-voltage) side has *many* windings, the slow side few: the count works the other way round from teeth | reveal |
| a chain gets warm | a chain barely warms; a trafo's windings really do, and the oil and fins exist for it | codex caption |
| a cyclist recovers at once | a trafo's oil takes hours to warm and to cool (shown sped up here) | codex caption |
| the gear ratio is about three | a 10 kV → 400 V trafo trades twenty-five times | codex caption, reveal |

### 1.5 Plain Dutch

The rules of #1 §1.5 hold: short sentences, the everyday meaning before the word (*tempo* and *kracht* before *spanning* and *stroom*), **no numbers in Ruud's mouth** (the meters show them; "veel", "een poosje", "korter" are words), a question at the end of most beats and no quiz, no formula on screen until the player opens the reveal. Never said outside the reveal: *kVA, ampère-getallen, wortel drie, verhouding, veroudering, IEC*.

### 1.6 "Laat de rekensom zien"

From T2 on (in the codex from the start). Words first, then the symbols, then the live numbers of the current state:

> *Wat er in gaat, komt er (bijna) helemaal weer uit: vermogen erin = vermogen eruit.* S = √3 · U · I → 630 kVA × 75 % = 473 kVA
> *Stroom erin = vermogen ÷ (√3 × hoge spanning).* I = S / (√3 · U) → 473 kVA ÷ (1,73 × 10.000 V) = 27,3 A
> *Stroom eruit = vermogen ÷ (√3 × lage spanning).* → 473 kVA ÷ (1,73 × 400 V) = 682 A
> *10.000 ÷ 400 = 25: eruit komt vijfentwintig keer zoveel stroom als erin. De hoge kant heeft vijfentwintig keer zoveel windingen.*
> *De warmte groeit met de stroom in het kwadraat; de olie volgt in uren, de wikkeling in minuten.* Δθ = 55 K · ((1 + 5K²)/6)^0,8 + 23 K · K^1,6 → 58 °C olie, 73 °C wikkeling
> *Boven de 98 °C slijt het papier om de wikkeling sneller: elke 6 graden twee keer zo snel.* V = 2^((θ − 98)/6) → 0,05 × zo snel
> *De fiets was een vergelijking: in een trafo draait niks. Wisselstroom in de ene wikkeling maakt een wisselend veld in het ijzer, en dat drijft de stroom in de andere.*

---

## 2. Learning goal

**For the designers:** a transformer keeps power (S in ≈ S out), so the current scales inversely with the voltage (I₂ = I₁ · U₁/U₂ = 25 · I₁); its losses grow with I², the oil and windings warm with a lag of hours and minutes; a distribution transformer may carry more than its rating for hours when it started cool, less on a hot day, and every hour hot wears its insulation (IEC 60076-7).

| The player can… | Where the game leans on it |
|---|---|
| say that a trafo turns high voltage with little current into low voltage with much current | Femke's *msr* topic; reading kW and A on the network screens; why a street's cable carries much more current than the 10 kV cable that feeds it |
| predict that more demand from the street means a warmer trafo, faster than the demand grows | Femke's *full* topic ("op het drukste moment … niet harder werken dan waarvoor hij gemaakt is"); netcongestie in Act II |
| tell that above the nameplate a trafo holds for a while, shorter when it is hot | the evening peak, the seasons in the KPI views |

What it deliberately does **not** teach: feed-in, voltage rise and the tap changer (*aftakking*: `inverters_tripping`'s answer), protection, the three-phase vector group, how a trafo is ordered or how long it takes to make.

---

## 3. The object

### 3.1 Concept

**One bench, two skins**, the trafohuisje's training rig on the opleidingsterrein. Skin 1, **de fiets**: a bicycle drivetrain on a fietstrainer bolted to the bench: a bottom bracket on a post with crank, pedal and a small chainring (left); a chain; a big sprocket on the back hub of a wheel standing on the trainer's roller, whose resistance unit (a finned flywheel) sits beside it (right); a dial gauge (*krachtmeter*) at the pedal and one at the wheel. Skin 2, **de trafo**: a 10 kV → 400 V oil transformer on its skid with the front of the tank cut away (core with three legs, the inner low-voltage and outer high-voltage windings on each, the oil up to its line), corrugated cooling fins on the side walls, three tall high-voltage bushings with the 10 kV cable on the lid's left, four short low-voltage bushings on the lid's right with the busbar to a laagspanningsrek (four fuse groups, an ammeter), the cables to a row of four small houses at the bench's front right whose windows light with the load, an oil thermometer on the lid and the nameplate. Shared: the bench, the load knob's control box, the wall thermometer on its backboard.

*What moves and what it means:* the crank (fast) and the wheel (slow) turn at a fixed tempo whatever the load (the voltage stays); the knob raises the load; the wheel's gauge climbs a lot, the pedal's a little (the analogy's ratio of three; the real one is twenty-five, in the reveal); the chain warms. In the trafo the two current meters climb (twenty-five to one), the houses light up, the windings warm (a heat tint), the oil thermometer climbs; the readout shows the winding's warmest point and how long the trafo holds this; the wall thermometer changes the weather.

**Card:** top left `Hoe werkt het? 2`, top right **DE TRANSFORMATOR**; bottom left the hint (*fiets*: "Draai aan de knop." · *trafo*: "Draai aan de knop: dat is de straat." · from T6: "Draai aan de knop. Tik op de thermometer."), the reveal corner from T2; bottom right the readout in the trafo skin only. Light theme (paper); the one `lit` accent is the chain, then the windings.

### 3.2 Parts (a Figure: ~45 parts per skin)

| Group | Fiets | Trafo |
|---|---|---|
| **Base** (shared) | bench plate, feet, groove, screws, label plate with rule lines | — |
| **Backboard** (shared) | a backboard on two feet at the back right; the wall thermometer (dial, bezel, ticks; needle by Godot) | — |
| **Control box** (shared) | box, the load knob (knurled, pointer by Godot), a scale arc with seven ticks, a cable to the rig | — |
| **source** | bottom-bracket post with foot plate, axle, small chainring with teeth (crank arm and pedal turning, by Godot) | the 10 kV cable rising from the bench through a gland, three cable terminations to three tall bushings with sheds |
| **core** | the chain loop (`lit`), its links | the cutaway tank's inside: three core legs and yokes, LV (inner) and HV (outer) windings on each leg, the oil line (`lit` windings) |
| **tank** | the trainer's frame (rails, clamp, feet) | the tank on its skid, corrugated fins on both sides, lid with screws, lifting eyes, nameplate |
| **out** | the big sprocket, the back hub, the wheel (tyre, rim; spokes turning, by Godot) on its roller | four LV bushings, the busbars to the laagspanningsrek (panel, four fuse groups, the outgoing cables) |
| **street** | the resistance unit (finned flywheel, cable to the knob) | four houses with windows (a window layer per load step) |
| **meter_in** | the pedal's krachtmeter (dial, needle by Godot) | the MS stroommeter box on a post (LCD) |
| **meter_out** | the wheel's krachtmeter (dial, needle) | the rek's ammeter (LCD) |
| **heat** | the chain's heat tint | the windings' heat tint; the oil thermometer (dial, needle) |

### 3.3 Painter's order

Back to front: bench → backboard and wall thermometer → control box (back right) → source → the far half of the core / chain → tank and fins (the far fins first) → core front, windings → heat tints → lid, bushings and cables → out (sprocket, wheel or LV bushings and rek) → street → meters → the knob's pointer and needles (Godot). Each analogy part sits in its counterpart's slot, so the cross-fade never re-sorts. As in #1 the painter's order is by hand and checked by eye in the screenshots; `A.recorder`/`--audit` stays a follow-up (PLAN 2.7c anatomy polish).

### 3.4 Controls, readout and the model

**Two controls**, both parts of the drawing:

1. **Belasting** (the knob on the control box; ↑/↓, or a click on the knob's right or left half): 0, 25, 50, 75, 100, 125, 150 % of the nameplate. It starts at 25 %. In the fiets skin it is the trainer's resistance ("een berg op"), in the trafo skin the street's demand. The state carries over the cross-fade.
2. **Buitentemperatuur** (a click on the wall thermometer, or T), **only from T6 on** (in the codex from the start): 20 → 30 → 0 → 10 °C, round. It starts at 20 °C.

**In the fiets there are no numbers**: the crank and the wheel turn, the two gauges show force without units (the wheel's gauge spans the full load, the pedal's moves a third of it: `estimate:` the analogy's gear ratio of three, so both move visibly), the chain warms.

**In the trafo, the readout** (instruments in the drawing and the card's bottom right):

| Readout | Dutch label | Shown on | Format |
|---|---|---|---|
| I₁ | Stroom erin | the MS meter's LCD | `27,3 A` |
| I₂ | Stroom eruit | the rek's LCD | `682 A` |
| θ_oil | — | the oil thermometer's needle (0–120 °C dial) | — |
| θ_h | Wikkeling | card | `73 °C` |
| hours | Volhouden | card | "Kan dit blijven dragen" · "Houdt dit zo'n 5,5 uur vol" · "Minder dan een uur" |
| θ_a | — | the wall thermometer's needle (−10–40 °C) and the card | `Buiten 20 °C` |
| S, ratio, ageing | — | reveal only | |

**Model** (`game/src/rules/explainers/trafo_thermal.gd`, twin `tools/explainers/trafo/model.mjs`):

```
inputs: load L (%), ambient θa (°C)
K        = L / 100
S        = 630 kVA · K
I1       = S / (√3 · 10 000 V)            I2 = S / (√3 · 400 V)        I2 / I1 = 25
Δθo(K)   = 55 K · ((1 + R·K²) / (1 + R))^x      R = 5, x = 0,8      top-oil rise, steady
Δθh(K)   = 23 K · K^y                            y = 1,6             hot spot over top oil
θh       = θa + Δθo + Δθh
hours    : the oil starts at Δθo(0,5) (a long day at half load) and follows
           Δθo(t) = Δθo,i + (Δθo(K) − Δθo,i)(1 − e^(−t/τo)), τo = 180 min;
           the hours until θh reaches 120 °C (the winding's minutes are left out);
           none when the steady θh ≤ 120 °C
ageing   = 2^((θh − 98)/6)
```

In the view the oil follows its steady value with a sped-up time constant (`estimate:` 6 s of game time for the real three hours, so the player sees it climb; the codex caption says so); the winding's warmest point is θa + the eased oil rise + Δθh(K). The heat tint is (θh − 60)/70, clamped; the houses' windows light one step per 25 %.

**Expected readouts** (the test fixtures, T1/T2; `blijft` = no limit reached):

| θa (°C) | L (%) | I1 (A) | I2 (A) | θ_oil (°C) | θh (°C) | hours | ageing |
|---|---|---|---|---|---|---|---|
| 20 | 0 | 0,0 | 0 | 33 | 33 | blijft | 0,00 |
| 20 | 25 | 9,1 | 227 | 36 | 39 | blijft | 0,00 |
| 20 | 50 | 18,2 | 455 | 45 | 53 | blijft | 0,01 |
| 20 | 75 | 27,3 | 682 | 58 | 73 | blijft | 0,05 |
| 20 | 100 | 36,4 | 909 | 75 | 98 | blijft | 1,00 |
| 20 | 125 | 45,5 | 1137 | 95 | 128 | 5,6 | 30,8 |
| 20 | 150 | 54,6 | 1364 | 117 | 161 | 1,7 | 1509 |
| 0 | 125 | 45,5 | 1137 | 75 | 108 | blijft | 3,1 |
| 0 | 150 | 54,6 | 1364 | 97 | 141 | 3,7 | 150 |
| 30 | 100 | 36,4 | 909 | 85 | 108 | blijft | 3,2 |
| 30 | 125 | 45,5 | 1137 | 105 | 138 | 3,1 | 98 |
| 30 | 150 | 54,6 | 1364 | 127 | 171 | 1,0 | 4790 |

What the player can find by playing: the current out is always twenty-five times the current in; the tempo of the pedals never changes; at no load the oil is still a little warm (the iron's own losses); the winding warms much faster than the load grows; at its nameplate on a normal day the trafo holds for ever, at a quarter above it for hours, at half above it less than two; on a cold day a quarter above the nameplate holds for ever, on a tropical day the nameplate itself already wears it three times as fast (reveal).

### 3.5 Every number and its source

| Number | Value | Source |
|---|---|---|
| The most common MS level; transformation to LS in transformatorhuisjes in residential areas | 10 kV | Netbeheer Nederland, *Betrouwbaarheid van elektriciteitsnetten in Nederland, resultaten 2017* §2.4–2.5 (netbeheernederland.nl, PDF): "Het meest voorkomende spanningsniveau in het middenspanningsnet is 10 kV"; "de transformatie van midden- naar laagspanning veelal gebeurt in 'transformatorhuisjes' die in woonwijken staan" |
| LS: three phases, 400 V between phases, 230 V phase to neutral | 400 V | the same document §2.5 |
| The loading guide: the effect of ambient temperature and load on a transformer's life | — | NEN, *IEC 60076-7:2018, Energietransformatoren – Deel 7: Leidraad voor het belasten van met olie gevulde transformatoren* (nen.nl; the standard itself is paywalled, not opened) |
| A *zomerse dag* ≥ 25 °C, a *tropische dag* ≥ 30 °C | 30 °C | KNMI, *Hittegolf* (knmi.nl): "Een hittegolf is een serie van minstens 5 zomerse dagen, waarvan er zeker 3 tropisch zijn" |
| Overloaded transformers risk damage and longer outages | — | Netbeheer Nederland, *Wat is netcongestie?* (netbeheernederland.nl, PDF, 2026-06), as in #1 |
| Rated power | 630 kVA | `estimate:` a common size of a distribution transformer in a Dutch MSR (400 and 630 kVA are the usual steps); the ratio and the thermal shape do not depend on it |
| Δθor 55 K, H·gr 23 K, R 5, x 0,8, y 1,6, τo 180 min | — | `estimate:` the IEC 60076-7 default thermal constants for ONAN distribution transformers, recalled (the standard is paywalled); they give the classic 98 °C hot spot at rated load in 20 °C air |
| Hot-spot limit | 120 °C | `estimate:` the IEC 60076-7 limit for normal cyclic loading, recalled |
| Ageing: 1 at 98 °C, doubling per 6 K | — | `estimate:` IEC 60076-7 for non-thermally-upgraded paper, recalled |
| Load steps up to 150 % | 150 % | `estimate:` IEC 60076-7's current limit for distribution transformers, recalled; beyond it the model does not hold |
| The day before an overload at half load | 50 % | `estimate:` a design choice so the hours mean something; a trafo that was already hot holds shorter (the codex caption says "na een gewone dag") |
| Ambient steps | 0 / 10 / 20 / 30 °C | 30 °C the KNMI's tropische dag; 0 °C a winter evening, 10 °C spring, 20 °C the loading guide's reference ambient (`estimate:`, recalled) |
| The air around the trafo is the outside air | — | `estimate:` a simplification; an enclosure adds a few kelvin (IEC 60076-7 has a correction for it) |
| The oil's sped-up time constant in the view | 6 s | `estimate:` a design choice for visibility; the codex caption says the real one is hours |
| The analogy's gear ratio | about 3 | `estimate:` a light bicycle gear; the real trafo trades 25 times (reveal) |

---

## 4. The script: Ruud at the trafohuisje

**Voice:** Ruud's (warm, calm, one question per line, self-mocking about his age). No numbers. He explains the trafo the way he explained spanning: with something everyone has done. Skippable at every beat (Spatie, [Klaar], a held Spatie), no quiz, ← goes back, a counter, "Tekst loopt vanzelf door" honoured: the beat machine of #1, unchanged.

| Beat | Trigger | Ruud | The figure | The one idea |
|---|---|---|---|---|
| **f1** | opened | "Een trafo leg ik altijd uit met een fiets." · "In een lichte versnelling trap je snel, maar je hoeft bijna geen kracht te zetten. Het wiel draait langzamer, maar met veel meer kracht." · "Zie je dat het tempo niet verandert, ook al trapt niemand hard?" | the crank turns fast, the wheel slow; the gauges rest | **snel en licht, langzaam en sterk** |
| **f2** | after f1 | "Draai de knop van de trainer eens verder open. Dan wordt het zwaarder, alsof je een berg op fietst." | the knob pulses; waits for a step up or 10 s (auto) | **zwaarder = meer kracht** |
| **f2_already** (alt of f2, the load already ≥ 50 %) | | "Je hebt hem al zwaarder gezet. Kijk eens naar de twee meters." | | |
| **f3** | after f2 | "Kijk naar de meters. Bij het wiel stijgt de kracht flink, bij de trapper maar een beetje." · "En het tempo? Dat blijft precies hetzelfde." · "Zet hem eens helemaal zwaar. Wat merk je aan de ketting?" · *(silence)* "Die wordt warm. Hoe zwaarder, hoe warmer." | waits for the load ≥ 100 % (or 10 s); the chain tints | **zwaar = warm** |
| **x** | after f3 | "Goed. En nu hetzelfde, maar dan met een echte trafo." | the cross-fade, part by part; tags *snel en licht*, *ketting*, *langzaam en sterk* | — |
| **t1** | done | "De trapper is nu de kabel van de middenspanning. Het wiel is de kant van de straat. En de ketting is de ijzeren kern met de wikkelingen." | the tags fade | **hetzelfde, maar echt** |
| **t2** | after t1 | "Er gaat hoge spanning in, met weinig stroom. Er komt lage spanning uit, met heel veel stroom." · "Kijk maar op de twee stroommeters." | the readout and the reveal corner appear | **spanning in, stroom uit** |
| **t3** | after t2 | "Eén verschil met de fiets: in een trafo beweegt niks. Er draait geen ketting." · "Het ijzer geeft het door, zonder dat de draden elkaar raken." | the core's three legs pulse once | **waar de vergelijking stopt** |
| **t4** | after t3 | "Zet de straat eens zwaarder, alsof iedereen tegelijk gaat koken." | waits for the load ≥ 100 % or 10 s; the houses light | **meer vraag = meer stroom** |
| **t4_already** (alt, ≥ 100 % already) | | "De straat vraagt al veel. Kijk eens naar de huizen." | | |
| **t5** | after t4 | "De wikkelingen worden warm. De olie neemt die warmte mee naar de koelribben, daar raakt hij hem kwijt." · "Kijk eens naar de thermometer op de ketel. Hoe snel gaat dat, denk je?" | the windings tint, the oil needle climbs | **de olie koelt** |
| **t6** | after t5 | "Draai nog eens verder, boven wat er op het typeplaatje staat." · "Dat houdt hij een poosje vol. Hoe lang, dat staat onderaan het blad." | waits for the load > 100 % or 10 s; the hours line | **even meer kan, niet eeuwig** |
| **t7** | after t6 | "Tik eens op de thermometer aan de muur. Wat doet een hete zomerdag met die tijd?" · *(after the change or 10 s)* "Op een warme dag houdt hij het korter vol." · "Net als ik op de fiets, tegenwoordig. Met rust is hij zo weer koel, maar elke dag te zwaar, dan slijt hij hard." | the thermometer becomes clickable (`unlocks: [ambient]`) | **warm weer = korter; te zwaar slijt** |

Ten main beats (f1, f2, f3, x, t1–t7 is eleven with x; the counter counts mains: 11). **State rules:** the lines depend only on the controls (f2's and t4's already-variants); the thermometer is not clickable before t7; Ruud never says which load is "right".

**Real time:** `estimate:` 75–100 s for a player who follows the prompts.

**Codex revisit** (K → Hoe werkt het? → De transformator, and Femke's topic *msr*): the same figure without Ruud, the trafo skin with **[De fiets]** / **[De trafo]** tabs, both controls free, the reveal, and the caption:

> *Een trafo ruilt spanning in voor stroom. Erin gaat hoge spanning met weinig stroom, eruit komt lage spanning met veel stroom.*
> *Hoe meer de straat vraagt, hoe warmer de wikkelingen. De olie brengt die warmte naar de koelribben.*
> *Even meer dan het typeplaatje kan, na een gewone dag. Op een hete dag korter, en elk uur te heet slijt hij sneller.*
> *De fiets is een vergelijking. In een trafo draait niks, en hij ruilt veel sterker dan een fietsversnelling. Een echte ketting wordt nauwelijks warm; een trafo wel. Opwarmen duurt in het echt uren; hier gaat het sneller.*

---

## 5. "The how, never the answer"

Checked against `content/problems_tier1.yaml` and `content/missions.yaml`. **It must NOT show, say or caption:**

1. **Anything about ordering a transformer, lead times, the manufacturer, stock or framework contracts** (`transformer_wait`: root cause and every countermeasure, `early_transformer_order`, `framework_contracts`, `strategic_transformer_stock`). No *bestellen, levertijd, fabrikant, voorraad, raamcontract*.
2. **Contracted vs used capacity** (`unused_capacity`: *gecontracteerd, contract, reserveren, ongebruikt*, the 62 %, the empty distribution hall, *use it or lose it*). The explainer's load is "wat de straat vraagt", never what is booked; it never says the net is "vol" or "niet vol", or that a trafo is fuller on paper than in reality.
3. **Which transformer in the region is overloaded**, De Boomgaard, Hermans Bouw, Ilse, the bakery, any street or station name.
4. **Voltage rise from feed-in, the tap changer** (`inverters_tripping`: *aftakking, zonnepanelen, omvormer, 253*), as in #1. The trafo's nameplate is drawn with rule lines only; no tap switch is drawn.
5. **"Tijdelijk zwaarder belasten" as a measure** against congestion. The hours line is physics about one trafo; no line says the operator should or does run them hotter.
6. **The things #1 kept out** that still apply: *3x25, warmtepomp, El Amrani, netstudie, wachtlijst, verzwaren*; any simulation step or KPI name.

**Allowed:** *trafo, transformator, middenspanning, laagspanning, wikkeling, kern, olie, koelribben, typeplaatje*, the physics of the hours, the season.

**Test (T7):** every Dutch string of the explainer avoids the common list (minus the trafo words, which #1 keeps in its own list) and its own list (`never:` in the content).

---

## 6. Pipeline: what changes to carry a second explainer

#1's pipeline was written for one model. The second one generalises it without changing #1's behaviour:

- **`ExplainerRig`** (`game/src/rules/explainers/explainer_rig.gd`): the controls' state and the model behind one explainer, behind one interface (`toggle(control, step)`, the beat conditions and waits, `step(dt)`, which layers a state shows, the needles, wheels and LEDs, the LCD texts, the card's readout, the reveal's live values, the heat). `OhmRig` holds #1's switches and reel (moved out of `ExplainerView` and `ExplainerBeats`, unchanged); `TrafoRig` holds the load and the weather. `ExplainerRig.create(def)` picks one by the content's `model`. `ExplainerBeats` takes a rig (its `on`, `haspel` and `haspel_unlocked` still read through, so #1's tests stand); a control named in a beat's `unlocks` is locked until then.
- **Content** gets: `speaker` (the name in the strip; #1 keeps Ruud), `skins: {analogy, real, tabs}`, `groups` (the cross-fade's order), `never` (this explainer's own forbidden words), controls with `keys: {up, down}` for a stepped control, and `labels` and `hint` keyed as each rig needs. The build validates them; beats ids are no longer a fixed list (each explainer lists its own), phases are its two skins and `cross`, waits and conditions are checked against the rig's list for its model (`EXPLAINER_RIGS` in the build, the same names the rig knows).
- **Manifest**: needles, wheels, LEDs and LCDs carry their `group` (#1's export re-run, its SVGs unchanged); a hit may carry `step` (−1 or +1: the knob's halves).
- **The trafohuisje** (`OfficeTrafohuisje`, built in Godot like Ruud's whiteboard, no Blender rebuild): an interaction point at the mock-up's doors on the opleidingsterrein, "E — Trafohuisje: hoe werkt een trafo?", once the opleidingsterrein is open; it opens the explainer with Ruud's beats as the whiteboard does. **Femke's topic `msr`** unlocks it (`unlocks: {explainer: transformator}`), opened the codex way over her talk.

### Tests (T1–T10 equivalents, `test_explainer_trafo.gd` and the shared ones)

- **T1** the model matches §3.4's table; **T2** `fixtures.json` (both models); **T3** properties: I₂ = 25 · I₁ always; more load never cools; more ambient never lengthens the hours; the hours are none at or below the nameplate in 20 °C air.
- **T4** the parts load (every layer a texture, z unique, the knob's two hit halves, the thermometer's hit, the LCDs and needles).
- **T5** the beats in order for a player who follows, the already-variants, the thermometer locked until t7, Esc and [Klaar].
- **T6** no quiz (only [Klaar] and the reveal corner; the codex adds the two tabs).
- **T7** never the answer (the lists above, and no step or KPI name).
- **T8** the codex lists it once seen, and the log round-trips it.
- **T9** no formula and no digit outside the readout and the reveal; the reveal shows the sums.
- **T10** the analogy maps (every pair a fiets and a trafo layer; after X the fiets is gone; the load carries over).
- **World:** the trafohuisje's point exists on the yard once the opleidingsterrein is open, says "hoe werkt een trafo?", and opens the explainer; Femke's *msr* topic returns it.

Screenshots: `docs/screenshots/play_explainer_trafo_{fiets,cross,trafo}.png` (f3 with the chain warm, the cross-fade mid-way, t6 above the nameplate with the hours line).

## 7. Claude's calls

1. **Ruud speaks**, as the brief asked, not Henk: Henk retires before Act II, when this explainer is needed. Cost if wrong: one `speaker` field and ten lines in another voice.
2. **The fiets on a fietstrainer** as the gearbox: the trainer's knob is a real "load", the tempo staying is the voltage staying. The analogy maps *tempo* → spanning and *kracht* → stroom, the convention of #1's hose (druk → spanning). Cost if wrong: the teaching layer and the fiets skin.
3. **The second control is the weather**, not the time of day: the load already is what the time of day would change, and the weather is the second thing that sets how long a trafo holds.
4. **630 kVA** and IEC 60076-7's default constants, marked as estimates (the standard is paywalled); the shape, not the exact hours, is the lesson.
5. **The hours start from a long day at half load**; said in the caption, not by Ruud.
6. **The generalised pipeline** (rigs, content fields) instead of a second view: one view, one beat machine.
