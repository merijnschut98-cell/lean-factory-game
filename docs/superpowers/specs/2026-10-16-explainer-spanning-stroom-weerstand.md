# Hoe werkt het? #1: spanning, stroom en weerstand op het bord van Ruud (PLAN 2.7c spike)

> Status: by the mission-and-dialog design agent (Claude, 2026-10-16). **Docs only.** The first "Hoe werkt het?" explainer and the 2.7c spike, placed by the first-five-minutes spec (`2026-10-16-first-five-minutes.md`, B4). Dutch game text, English ids and comments; every number sourced from the approved list or marked `estimate:` with its reasoning.
>
> **Revised the same day for the "Simple first" rule (PLAN 2.7c, Merijn 2026-10-16).** The first version (on the coordinator's brief) ruled out a water analogy and opened on the meterkast with numbers and formulas in Ruud's mouth. That was wrong for a player with no prior knowledge. Now: the teaching layer comes first (§1); the explainer opens on a **garden hose** and cross-fades into the real circuit in the same picture; Ruud speaks plain Dutch with no numbers (the instruments show them); every formula sits behind **"Laat de rekensom zien"**. The object, the model, the sourced numbers, the "never the answer" list and the pipeline are kept.
>
> Read with: CLAUDE.md §2 (immersion; evidence first; nothing handed over; respect the player's time); PLAN 2.7c (design rules, above all *Simple first*), 2.7d (the opening), 2.10 (diegetic UI); the voice sheet (`2026-10-15-four-tier-audit.md` §6, Ruud: questions, "kijk", "wat zie je", no jargon unless the player used it first); the `anatomy` skill (the authoring tool).
>
> **What changes in the first-five-minutes spec.** B4's opening choice ("Leg maar uit" / "Ik ken het, Ruud") and its last two lines stay. Everything in between is §4 here. B4's time budget grows from 0–60 s to 0–90 s (§4, *Real time*); B4 in that spec is updated to match.

---

## 1. The teaching layer (written before anything is drawn)

### 1.1 The one idea

**The one idea a player should be able to say back:** *"Hoe meer stroom er door dezelfde kabel moet, hoe warmer die kabel wordt."*

Two supporting ideas follow from it and are shown, not stressed: at the far end of a cable a little less *druk* (spanning) is left, and a thicker cable holds back less. Everything else (watts, ohms, the squares) is behind the reveal (§1.6).

**One idea per beat.** Every beat of §4 carries exactly one new idea, named in the table's last column. A beat that would need a second idea is split, or the idea is dropped.

### 1.2 The analogy and the order of reveal

**The analogy:** water through a garden hose. A tap pushes water into the hose (the push is **druk** = spanning); what actually moves through it is **water per tel** (= stroom); a narrow hose holds the water back (= weerstand), and if you push a lot through a narrow hose it gets warm.

**Same picture, two skins.** The analogy figure is drawn on **the same bench, in the same slots**, as the real circuit (§3): where the meterkast group will stand there is a **buitenkraan** on a wall plate; the **slanghaspel** is the same drum as the kabelhaspel, with a green garden hose on it; where the stekkerdoos will be there is a **verdeelstuk with three kraantjes**; where the stroomtang clamps the cable, a **doorstroommeter** clamps the hose; where the multimeter sits, a **drukmeter** sits. So the cross-fade is part for part: each piece turns into its real counterpart where it stands, and the player sees the mapping happen instead of being told it.

**Order of reveal:**

1. **Druk** (the tap pushes) → the player opens a kraantje.
2. **Stroom** (water per tel; the doorstroommeter's needle) → more kraantjes, more flow.
3. **Weerstand** (the hose holds back; the drukmeter at the end sinks a little).
4. **Warm** (a lot through a narrow hose: it warms). The one idea, in water.
5. **Cross-fade** into the real circuit; the mapping, part by part.
6. **The names and units** (spanning in volt, stroom in ampère): only now, once each has an everyday meaning.
7. **Where the analogy stops** (one plain line).
8. **The same four steps on the real circuit**, the player switching appliances; the one idea again, now on a cable with a thermometer.
9. **The thick haspel** and the street (an analogy back to the job, no answer).

### 1.3 Mapping: analogy → real thing

Shown in the figure by the cross-fade; said by Ruud in R1–R2; written in this table for the build (it is also the content's `mapping`, §6.2, and the pairs T10 checks).

| In the analogy (what you see) | Everyday meaning | The real thing (what it turns into) | Its name in the game | Unit (only from R2 on) |
|---|---|---|---|---|
| de buitenkraan aan de muur | where the push comes from | de groep in de meterkast | het stopcontact / de groep | — |
| de druk van de kraan | how hard it is pushed | de spanning | spanning | volt (V) |
| water per tel door de slang | how much actually moves | de stroom | stroom | ampère (A) |
| de tuinslang op de haspel | the road it travels | de kabel op de haspel | kabel | — |
| een smalle slang | holds the water back | een dunne kabel | weerstand | (ohm, Ω: reveal only) |
| een dikke slang | holds back less | een dikke kabel | weerstand (minder) | — |
| de drie kraantjes op het verdeelstuk | you decide how much flows | de drie knoppen op de stekkerdoos | schakelaar | — |
| de druppelaar, de grote sproeier, de tuinsproeier | things that use water | de LED-lamp, de waterkoker, de kachel | apparaat | — |
| de doorstroommeter (wieltje achter glas) | counts the water | de stroomtang om de kabel | stroomtang | A |
| de drukmeter aan het eind | how much push is left | de multimeter in de stekkerdoos | spanning aan het eind | V |
| de slang wordt warm | the cost of pushing a lot through | de kabel wordt warm (thermometer) | warmte in de kabel | °C (W: reveal only) |

### 1.4 Where the analogy stops being true

**Said by Ruud, one plain line (R3):** *"Eén verschil. Water loopt de slang uit. Stroom niet: die gaat door de kabel heen, en komt weer terug."*

Chosen because it is the limit that matters for what follows (a cable is a loop, which is also why the model counts the cable length twice). The other limits are not said; they stand in the codex caption (§4, *Codex revisit*) and the reveal, for the curious:

| The analogy says | The truth | Where it is told |
|---|---|---|
| water leaves the hose | current goes out and back through two wires; nothing is used up, only energy is passed on | Ruud, R3 |
| a narrow hose gets warm | a real garden hose barely warms (the friction heat is tiny); in a cable that warmth is exactly the point | codex caption, line 4 |
| pressure drops along the hose because water rubs | voltage drops along a cable because the cable has resistance; the picture is right, the cause is different | reveal (§1.6), last line |

The analogy figure shows the hose warming (Merijn's brief: *a narrow hose that gets warm*) because that is the idea the real circuit then confirms. The codex line keeps it honest.

### 1.5 Plain Dutch: the rules for every line

- **Short sentences.** At most about ten words; one idea per sentence.
- **Everyday meaning before the word.** *Druk* before *spanning*; *water per tel* before *stroom*; *tegenhouden* before *weerstand*. *Volt* and *ampère* only after R2 has said what they count. Never said at all outside the reveal: *ohm, vermogen, watt, Joule, spanningsdaling, doorsnede, mm², I, U, P, R.*
- **No numbers in Ruud's mouth.** Numbers are readouts on the instruments; Ruud points at them ("Kijk naar de tang", "Dat getal is de stroom"). Comparisons in words ("veel warmer dan je denkt") are allowed. The first version's state tokens (`{ampere}`, `{volt_weg}`) are gone.
- **A question at the end of most beats**, never answered with a button (no quiz). Ruud's voice: "kijk", "wat zie je", "wat verwacht je".
- **No formula on screen** until the player opens the reveal (§1.6; test T9).

### 1.6 "Laat de rekensom zien"

A folded corner of the sheet (bottom left of the card, under the hint) reads **Laat de rekensom zien**. It appears from R2 on (the analogy has no units, so nothing to reckon), in the codex from the start. Clicking it (or key R) unfolds a strip under the figure with the sums, **words first, then the symbols, then the live numbers** of the current state:

> *Stroom = spanning ÷ weerstand.* I = U / R → 230 V ÷ 27,0 Ω = 8,5 A
> *Warmte in de kabel = stroom × stroom × weerstand van de kabel.* P = I² · R → 8,5 × 8,5 × 0,58 Ω = 42 W
> *Twee keer zoveel stroom geeft vier keer zoveel warmte.*
> *Spanning die de kabel kost = stroom × weerstand van de kabel.* ΔU = I · R → 8,5 A × 0,58 Ω = 5 V
> *Wat de apparaten krijgen (vermogen, in watt) = spanning × stroom.* P = U · I → 225 V × 8,5 A = 1.915 W
> *De slang was een vergelijking: in een kabel zakt de spanning door de weerstand van de kabel, niet doordat er iets schuurt.*

The numbers follow the model live (§3.4). The strip stays open until folded back; the choice is remembered for the session and in the codex. Opening it is not a quiz and gives no reward; Ruud does not comment on it.

---

## 2. Learning goal

**In plain words:** the one idea of §1.1. **For the designers** (not shown): spanning pushes, stroom is what actually flows, and every cable has weerstand, so more stroom through the same cable means more warmte in the cable (P = I²·R) and less spanning at the far end (ΔU = I·R).

**What the player can do afterwards** (and where the game uses it):

| The player can… | Where the game leans on it |
|---|---|
| say that switching on more appliances means more stroom, not more spanning | reading a meter, a load curve, a KPI in kW or A |
| predict that a cable gets warm when a lot of stroom goes through it, and faster than the stroom grows | **netcongestie**: a street cable or a transformer carries the current of a whole street; at peak it heats, and an operator must keep it below its limit (Netbeheer Nederland, *Wat is netcongestie?*: overloaded transformers and cables risk damage and longer outages) |
| predict that a longer or thinner cable leaves less spanning at the end | **spanningsdaling** at the end of a long rural line; why the Netcode sets a band around 230 V at the connection point (±10 %) |
| tell spanning (V) and stroom (A) apart on a readout; find watts in the reveal | every later explainer (transformator, kabel en mof, slimme meter) and the KPI views |

What it deliberately does **not** teach here: feed-in raising the voltage (solar), transformer taps, three-phase connections, protection and tripping. Those belong to later explainers, and two of them sit close to a tier-1 mission answer (§5).

---

## 3. The object

### 3.1 Concept (anatomy step 3)

**One bench, two skins.** On Ruud's whiteboard tray stands a bench with a ruler strip (0–25 m). Skin 1, **de tuin** (§1.2): a buitenkraan on a wall plate, a slanghaspel with 25 m of green hose unrolled along the ruler, a doorstroommeter on the hose near the tap, at the end a verdeelstuk with three kraantjes feeding a druppelaar, a grote sproeier and a tuinsproeier, and a drukmeter on the verdeelstuk. A second, thicker slanghaspel stands rolled beside it.

Skin 2, **de meterkast**: what every house has: a small panel with one **groep** (a 16 A installatieautomaat and the kWh-meter), a **kabelhaspel** with 25 m of cable unrolled along the same ruler, and at its end a **stekkerdoos** with three switched appliances: an LED-lamp, a **waterkoker** and an **elektrische kachel**. A **stroomtang** clamps the cable near the panel; a **multimeter** is plugged into the stekkerdoos; a small **contactthermometer** is taped to the cable halfway. A second haspel with a thicker cable stands beside the first.

*What moves and what it means:* a kraantje or a switch opens and something flows; the doorstroommeter's wheel spins faster, or the stroomtang's number rises; the drukmeter's needle, or the multimeter, sinks a little; the hose or the cable slowly darkens toward warm (a heat tint, no flames) and, on the cable, the thermometer climbs. Swap the haspel and the same load leaves more at the end and a cooler cable.

**Why the analogy first and then this real object:** the analogy gives a player with no prior knowledge a picture they already own; the real object is what they will meet at a grid operator (Marco's crew carries a stroomtang). Because both skins share every slot, the second is learned as "the same thing, for real", not as a new picture. The step to the street is made by Ruud in words (§4, R8), not by the picture.

**Card** (anatomy step 8; drawn as a sheet clipped to the whiteboard, not a game window, PLAN 2.10):
- top left `Hoe werkt het? 1`; top right **Spanning, stroom, weerstand**;
- bottom left the hint: in the tuin *"Draai een kraantje open."*, in the meterkast *"Zet een apparaat aan."*, from R8 on *"Zet een apparaat aan. Pak de andere haspel."*; under it the folded corner **Laat de rekensom zien** (from R2, §1.6);
- bottom right the live readout (§3.4), in the meterkast only.

**Theme:** the anatomy **light** theme (paper), because the figure lives on a whiteboard. Ink tones only; the one `lit` accent is **the hose, then the cable** (the part the player should watch). The only colours are the hose's green (it must read as a garden hose at once) and the heat tint, because heat is the subject.

### 3.2 Parts (anatomy step 4; a Figure, 40–80 parts per skin)

**Shared by both skins** (drawn once; they do not cross-fade):

| Group | Parts |
|---|---|
| **Base** (`lo`) | bench plate with bevel; four rubber feet; groove inset along the front edge; corner screws (dots with rings); ruler strip along the front with ticks every metre, major every 5 m (0–25 m); a label plate (three rule lines) |
| **Haspel frames** (`mid`) | for both haspels: drum with two flanges and their spokes; crank with knurled handle; frame with two feet. A haspel is a haspel; only what is wound on it changes |

**Skin 1, de tuin** (each part names its counterpart in skin 2; the pair is a manifest field, §6.1):

| Group | Parts → counterpart |
|---|---|
| **Wall** (`mid`) | wall plate on two stand-offs → panel back plate; **buitenkraan** (body, handle, spout with hose coupling) → automaat + aardlekschakelaar; a small drukmeter at the tap (dial, needle) → kWh-meter; hose coupling → cable gland |
| **Slanghaspel 1, smal** (hose `lit`) | green hose route along the ruler (a `tube` with a gentle sag) → cable route; hose coupling on the drum → drum socket; hose label → cable label sleeve |
| **Slanghaspel 2, breed** | the same, visibly wider hose, rolled until chosen → haspel 2's cable |
| **Verdeelstuk** (`mid`) | body; three outlets; **three kraantjes** (each its own layer, two states: dicht/open) → stekkerdoos body, sockets, three rocker switches; inlet with clamp → cable entry with strain relief |
| **Outlets** (`hi`) | druppelaar on a short stick → LED-lamp; grote sproeier on a spike → waterkoker; tuinsproeier (rotating) → kachel; **spray** layers per outlet (three densities, by flow) → the waterkoker's lamp and the kachel's glow |
| **Instruments** (`hi`) | **doorstroommeter** clamped on the hose (two clamp halves, body, glass window with a paddle wheel) → stroomtang; **drukmeter** on the verdeelstuk (dial, needle, collar) → multimeter; no thermometer in the tuin (Ruud says "Voel maar"; the tint is enough) → contactthermometer appears at the cross-fade |

**Skin 2, de meterkast:**

| Group | Parts |
|---|---|
| **Panel** (`mid`) | back plate on two stand-offs; DIN rail with two end clips; **installatieautomaat 16 A** (body, toggle, the engraved "B16" as the one engraved label); aardlekschakelaar beside it (body, test button); **kWh-meter** body with LCD window (Godot label, §6) and a pulse LED; cable gland at the bottom; four screws |
| **Haspel 1, dun** (cable `lit`) | socket on the drum face with its lid; the unrolled cable (a `tube` route along the ruler strip with a gentle sag, never crossing itself); cable label sleeve; plug into the panel's socket |
| **Haspel 2, dik** | the same, a visibly thicker cable, a different label sleeve; rolled until chosen |
| **Stekkerdoos** (`mid`) | body; three sockets; three rocker switches (each its own layer, two states); the cable entry with strain relief; two screws |
| **Appliances** (`hi`) | LED-lamp in a small table foot (bulb, shade, cord); waterkoker (body, lid, handle, base plate, water window, the switch with its own lamp); elektrische kachel (housing, grille bars, two feet, knob) |
| **Instruments** (`hi`) | **stroomtang** clamped on the cable (jaws, body, rotary knob, LCD window); **multimeter** on the stekkerdoos (body, rubber holster, rotary knob, two probes with leads ending on terminal dots in the socket, LCD window); **contactthermometer** taped to the cable (tape band, probe, small LCD) |

About 60 parts per skin, about 95 in all (the base and haspel frames are shared); every one sits on another.

### 3.3 Painter's order (back to front, bottom to top; anatomy step 7)

Camera: azimuth 45°, elevation 30° (`estimate:` the default; it shows the bench length and the stekkerdoos face). World units ≈ 1 px; the wall/panel stands at the back left, the hose/cable runs to the front right. **Each analogy part sits in the same slot as its counterpart**, so the cross-fade never re-sorts.

1. halo under the bench; bench plate; feet (back two first); groove; ruler strip and ticks; label plate; screws
2. stand-offs; back plate / wall plate; DIN rail, automaat, aardlekschakelaar, kWh-meter **or** buitenkraan and its drukmeter (left to right, `depthOf`); gland / hose coupling; screws
3. haspel 2 (rolled, back right): frame back half → drum → flanges → frame front half → crank
4. haspel 1 (back left): frame back half → drum with the remaining windings → flanges → frame front half → crank → drum socket / hose coupling
5. **the hose or cable route** (tube chunks, `A.settle` for true depth); thin/thick and hose/cable are variant layers in **the same slot** (§6.1)
6. doorstroommeter / stroomtang (back half → the hose or cable chunk inside is already drawn → front half → body → knob or window)
7. contactthermometer (skin 2 only: tape band back half → probe → tape front half → LCD)
8. verdeelstuk / stekkerdoos body → outlets / sockets → **kraantjes / switches** (three variant layers each) → plugs and cords
9. outlets / appliances (back to front by `depthOf`); spray layers over the outlets
10. drukmeter / multimeter (holster → body → needle or knob → probe leads as `wire`, terminal dots on the socket)
11. **heat tint** over the hose or cable (a separate layer in the route's own slot, alpha only)
12. card frame, hint, reveal corner, readout (Godot, §6)

Split parts that wrap another: the stroomtang jaws and the doorstroommeter's clamp halves (back/front around the cable or hose), the tape band, the haspel frames around the drum. `--audit` to `audit passed` and the line check to `line ends: 0` for **each skin** before export (anatomy step 10).

### 3.4 Controls and live readout

**Two controls**, both real actions, the same in both skins:

1. **Belasting: the three kraantjes, then the three switches** (click, or keys 1–3). Druppelaar / LED-lamp 8 W · grote sproeier / waterkoker 2.000 W · tuinsproeier / kachel 1.500 W; any combination. **The state carries over the cross-fade**: what was open in the tuin is switched on in the meterkast.
2. **Kabel: which haspel** (click the other haspel, or key H), **only from R8 on** (in the codex from the start). Dun (1,5 mm²) or dik (2,5 mm²), both 25 m. The swap is shown as Ruud's hand rolling one in and plugging the other (a 0.6 s AnimationPlayer clip), not a menu toggle.

**In the tuin there are no numbers.** The doorstroommeter's paddle wheel spins at a speed ∝ I, the drukmeter's needle shows U_eind, the spray grows with each outlet's share; there are no units on the dials. The end drukmeter's dial is drawn as a **zoomed band** (needle range covers 210–230 V of the model; `estimate:` a design choice so the small drop, 2–4 %, is visible; it is a dial without units, so it misstates nothing). The tap's own drukmeter never moves (the source stays the same: one of the things to notice).

**In the meterkast, the readout** is shown twice: on the instruments in the drawing (diegetic: the stroomtang A, the multimeter V, the thermometer °C; the kWh-meter shows only its pulse LED blinking faster, no number) and in the card's bottom right, plain-labelled, for accessibility and readability:

| Readout | Dutch label | Shown on | Format |
|---|---|---|---|
| I | Stroom | stroomtang | `8,5 A` (one decimal; two below 1 A: `0,03 A`) |
| U_eind | Spanning aan het eind | multimeter | `225 V` (whole volts) |
| T_kabel | Kabel | thermometer | `31 °C` |
| P_kabel, P_app, R | — | **reveal only** (§1.6) | `42 W`, `1.915 W` (Dutch thousands dot), `0,58 Ω` |

**Model** (one pure function; the same model drives both skins, the readout, the heat tint, the needles and the reveal; anatomy step 2):

```
inputs: switches s_i ∈ {0,1}, cable cross-section A (mm²)
U_n      = 230 V                      nominal low-voltage, ideal source at the socket
ρ        = 0,0175 Ω·mm²/m             copper at 20 °C
L        = 25 m                       haspel length; the current flows out and back: 2·L
R_kabel  = 2·ρ·L / A                  1,5 mm² → 0,583 Ω ; 2,5 mm² → 0,350 Ω
R_i      = U_n² / P_i                 each appliance as a resistor at its rated power
R_last   = 1 / Σ(s_i / R_i)           parallel; no switch on → I = 0
I        = U_n / (R_kabel + R_last)   Ohm's law over the whole loop
U_eind   = I · R_last                 what the multimeter reads
ΔU       = I · R_kabel                lost along the cable
P_app    = U_eind · I                 P = U·I
P_kabel  = I² · R_kabel               Joule heating in the cable
T_kabel  = T_kamer + ΔT_max · (I / I_z)²   steady state; heat ∝ I²
T_kamer  = 20 °C, ΔT_max = 40 K, I_z(1,5) = 16 A, I_z(2,5) = 25 A
```

The cable (and hose) temperature **eases** to its steady value (exponential follow, time constant `estimate:` 4 s of game time, so the player sees it climb after the switch, not jump; a real cord takes minutes, and the codex caption says so). The heat tint's alpha follows (T_kabel − 20) / 50, clamped to 0..1, in both skins.

**Expected readouts** (computed from the model; these are the test fixtures, §6.4):

| Kabel | Aan | I (A) | U_eind (V) | ΔU (V, %) | P_app (W) | P_kabel (W) | T_kabel (°C) |
|---|---|---|---|---|---|---|---|
| 1,5 mm² | lamp | 0,03 | 230 | 0,0 | 8 | 0 | 20 |
| 1,5 mm² | waterkoker | 8,51 | 225 | 5,0 (2,2 %) | 1.915 | 42 | 31 |
| 1,5 mm² | waterkoker + kachel | 14,65 | 221 | 8,5 (3,7 %) | 3.245 | 125 | 54 |
| 1,5 mm² | alle drie | 14,68 | 221 | 8,6 (3,7 %) | 3.252 | 126 | 54 |
| 2,5 mm² | waterkoker | 8,58 | 227 | 3,0 (1,3 %) | 1.948 | 26 | 25 |
| 2,5 mm² | waterkoker + kachel | 14,87 | 225 | 5,2 (2,3 %) | 3.343 | 77 | 34 |

What the player can find by playing: the cable warms much faster than the stroom grows (in the reveal: 42 → 125 W for 1,72× the stroom, 1,72² = 2,96); the thin cable is about 20 °C warmer at the same load; the appliances get a little less than their label (1.915 W, not 2.000 W) because the cable keeps some spanning; the lamp changes nothing. The 16 A automaat is never reached with these loads (14,9 A at most), so nothing trips (tripping is a later explainer).

### 3.5 Every number and its source

| Number | Value | Source |
|---|---|---|
| Nominal voltage, low-voltage net | 230 V, 50 Hz | Netbeheer Nederland, *Spanningskwaliteit* (netbeheernederland.nl/veiligheid-en-infrastructuur/spanningskwaliteit): "In Nederland is de hoogte van de spanning in dit net 230 volt met een frequentie van 50 Hertz"; at the connection the voltage must meet NEN-EN 50160 |
| Allowed band at the connection point | Un ± 10 % for 95 % of 10-min averages over a week; +10 % / −15 % for all | Netcode elektriciteit, quoted in Netbeheer Nederland, *Achtergronddocument Spanningskwaliteit in Nederland, resultaten 2024* (netbeheernederland.nl, PDF) |
| Three phases of 230 V each in a 3-fase meterkast | 3 × 230 V + nul | Netbeheer Nederland, factsheet *Spanningsproblemen door zonnepanelen* (netbeheernederland.nl, PDF). **Not shown to the player** (§5) |
| A household connection up to 3×25 A | 3×25 A | ACM, *Ruim 300.000 huishoudens en bedrijven kunnen geld besparen met kleinere aansluiting stroomnet* (acm.nl). Drawn only as the engraved rating on the meterkast's main switch if the panel is extended; **never said** (§5) |
| Congestion: cables and transformers overloaded at peak, risk of damage | — | Netbeheer Nederland, *Wat is netcongestie?* (netbeheernederland.nl, PDF, 2026-06) |
| Ohm's law, P = U·I, P = I²·R, R = ρ·L/A | — | physics; any textbook (no web source needed) |
| The water analogy (pressure ↔ voltage, flow ↔ current, narrow pipe ↔ resistance) | — | the standard teaching analogy of school physics; its limits are named in §1.4. A garden hose's own friction heating is negligible: `estimate:` shown exaggerated on purpose and said so in the codex |
| End drukmeter's zoomed band | 210–230 V across the needle | `estimate:` a design choice so a 2–4 % drop is visible on a dial without units |
| Copper resistivity at 20 °C | 0,0175 Ω·mm²/m | `estimate:` the textbook value (standard annealed copper is 1/58 ≈ 0,0172; 0,0175 is the usual rounded installers' value). The ~1,5 % difference does not change any rounded readout by more than 0,1 V |
| Haspel length | 25 m | `estimate:` a common verlengkabel length in Dutch DIY stores; chosen so the effect is visible but realistic |
| Cable cross-sections | 1,5 and 2,5 mm² | `estimate:` the two usual cross-sections of household verlengkabels and installation groups; to verify against NEN 1010 (nen.nl, paywalled) |
| Group protection | 16 A (B16) | `estimate:` the usual rating of a Dutch household group; to verify against NEN 1010 |
| Current rating I_z of a flexible PVC cord in free air | 1,5 mm² → 16 A; 2,5 mm² → 25 A | `estimate:` common manufacturer tables for H05VV-F; to verify against NEN 1010 / IEC 60364-5-52 (nen.nl) |
| Max conductor temperature PVC 70 °C at 30 °C reference ambient → ΔT_max 40 K | 40 K | `estimate:` recalled from IEC 60364-5-52 (NEN 1010 part 5-52); the model applies the rated rise from a 20 °C room, so it reads slightly cool, which is the safe side for a teaching figure |
| Temperature ∝ I² at steady state | — | `estimate:` follows from P = I²R with constant cooling; ignores copper's resistance rise with temperature (+0,4 %/K, about +13 % at 54 °C), so the hot case is slightly understated |
| Waterkoker | 2.000 W | as in the first-five-minutes spec; a common rating (`estimate:`); resistive, so R = U²/P holds |
| Elektrische kachel | 1.500 W | `estimate:` a common small heater rating; resistive |
| LED-lamp | 8 W | `estimate:` a typical household LED bulb; not resistive, but at 0,03 A the error is invisible |
| Source impedance upstream of the socket | ignored | `estimate:` a simplification; the real socket voltage moves within the Netcode band during the day |
| Heating time constant | 4 s (game) | `estimate:` a design choice for visibility; the caption says the real one is minutes |

The source verifier (2.7c rule) checks the sourced rows; the estimates carry their reasoning here and in `content/explainers.yaml` (§6.2).

---

## 4. The script: Ruud at the whiteboard

**Voice** (four-tier audit §6): short; one question per line; questions, not lectures ("kijk", "wat zie je", "wat verwacht je"); self-mocking about his age; never says the right move; no "goed gedaan" without a question after it; **no numbers** (§1.5). He explains here because he explains it to every new colleague (B4's premise).

**Format.** Thirteen beats: four in the tuin (A1–A4), the cross-fade (X), eight in the meterkast (R1–R8); then B4's close in the room. Each beat is one to three short lines in the talk panel's small strip at the bottom of the card (the same font as the talk panel, no portrait frame; Ruud stands beside the whiteboard in the room behind the cross-fade). **Skippable at every beat:** Spatie / klik advances a beat; Esc or **[Klaar]** in the card's top-right closes the explainer at once, back into the room at B4's last two lines. A beat that waits for a control also advances on its own after 10 s, and the control stays live. **No quiz:** Ruud's questions have no answer buttons; the player answers with the kraantjes and switches, or not at all.

| Beat | Trigger | Ruud | What the figure does | The one idea |
|---|---|---|---|---|
| **A1** | the cross-fade from the room is done | "Vergeet even de elektriciteit. Denk aan een tuinslang." · "De kraan duwt het water de slang in. Dat duwen heet druk." · "Wat verwacht je als je een kraantje opendraait?" | the tuin, all kraantjes dicht; the big sproeier's kraantje pulses once (an ease, no arrow); waits for any kraantje or 10 s | **druk duwt** |
| **A2** | a kraantje open | "Nu loopt er water. Hoeveel water er per tel doorheen gaat, heet stroom." · "Kijk naar het wieltje op de slang. Draai er nog een open." | spray from the outlet; the paddle wheel spins; waits for a second kraantje or 10 s. *If only the druppelaar is open:* "Een druppelaar. Zie je het wieltje? Bijna niks. Probeer de grote sproeier eens." and A2's last line waits for it | **stroom is wat er echt loopt** |
| **A3** | two or more open | "Meer kraantjes open. Meer water door dezelfde slang." · "Kijk naar de drukmeter aan het eind. Waarom zakt die?" *(two seconds of silence)* "De slang houdt het water een beetje tegen. Dat tegenhouden heet weerstand." | the end needle sinks a little; the tap's needle does not move | **weerstand houdt tegen** |
| **A4** | after A3 | "En duw je heel veel door een smalle slang?" *(two seconds of silence)* "Dan wordt hij warm. Voel maar." | the hose tints warm, slowly | **veel erdoor = warm** (the one idea, in water) |
| **X** | after A4 | "Nu hetzelfde. Maar dan echt." | the cross-fade, part by part (§6.3): kraan → groep, slang → kabel, kraantjes → knoppen, wieltje → stroomtang, drukmeter → multimeter; the thermometer appears on the cable. Open kraantjes are now switched-on appliances; the cable keeps the warmth the hose had. For 3 s, marker tags in Ruud's hand stand beside the parts: *druk*, *stroom*, *tegenhouden* | — (the picture does the mapping) |
| **R1** | cross-fade done | "De kraan is nu de meterkast. De slang is de kabel. De kraantjes zijn de knoppen." | the marker tags fade | **het is hetzelfde, maar echt** |
| **R2** | after R1 | "Druk heet hier spanning. Die tellen we in volt." · "Stroom tellen we in ampère. Kijk maar op de tang." | the card's readout appears; the reveal corner appears | **de namen: spanning en stroom** |
| **R3** | after R2 | "Eén verschil. Water loopt de slang uit." · "Stroom niet: die gaat door de kabel heen, en komt weer terug." | the cable's two wires glow faintly in turn, out and back (0.8 s, once) | **waar de vergelijking stopt** |
| **R4** | after R3 | "Zet de waterkoker eens aan. Wat doet de tang?" *(if the waterkoker is already on from the tuin:* "De waterkoker staat al aan. Kijk naar de tang." *)* | the waterkoker's switch pulses once; waits for it or 10 s | **een apparaat aan = stroom** |
| **R5** | the waterkoker on | "Dat getal is de stroom." · "Kijk nu naar de meter aan het eind. Waar is dat stukje spanning gebleven?" *(two seconds of silence)* "In de kabel. Daar wordt het warmte. Net als bij de slang." | the readout updates; the cable tints. *If the player switched only the lamp:* "Een lampje. Bijna niks. Probeer de waterkoker eens." and R5 waits for it | **de kabel houdt ook tegen, en wordt warm** |
| **R6** | after R5 | "Zet de kachel er eens bij. Hoe warm wordt de kabel, denk je?" | waits for the kachel or 10 s; the thermometer climbs | — (the player tries) |
| **R7** | kachel on, after the waterkoker alone was seen | "Meer stroom. En de kabel wordt veel warmer dan je zou denken." · "Dat leerde ik op de MTS. Toen had ik nog haar." | the cable deepens to warm; the thermometer settles. *If the player never had the waterkoker on alone:* "Zet de kachel eens uit en weer aan. Kijk naar de kabel." and R7's main line waits | **meer stroom = veel warmer** (the one idea, on a cable) |
| **R8** | after R7 | "Pak de dikke haspel eens. Wat zie je?" *(after the swap, or 10 s)* "Dikke kabel, net als een dikke slang." · "Een kabel in de straat werkt net zo. Maar soms is hij heel lang. Wat blijft er dan over aan het eind?" | the haspel becomes clickable; the swap clip; the cable cools, the multimeter climbs; the hint adds *"Pak de andere haspel."* | **dik houdt minder tegen; lang kost meer** |
| **close** | after R8 | *(back in the room; B4's lines, unchanged)* "Bij ons op kantoor is het net zo. Er staat druk op: mensen willen een aansluiting. Er loopt maar zoveel door. En ergens zit weerstand." · "Waar? Dat weet ik niet. Dat ga jij zien." | cross-fade back to the whiteboard; the three words stay; the explainer is filed in the codex (K) | (B4's own) |

**State rules.** Ruud never says a number, so no line depends on the model's values; the lines depend only on *which* controls are on (A2's and R5's lamp branches, R4's already-on variant, R7's never-alone variant). The haspel is not clickable before R8 (in the codex it is free from the start), so A1–R7 always run on the thin hose and cable. If the player had the kachel on before R6 (from the tuin or by themselves), R6 is skipped and R7 (or its variant) plays. Ruud never says which kraantje or switch is "right"; the big one is suggested because it is the biggest single change, and the small one is allowed to do nothing, which is its own lesson.

**Real time:** `estimate:` 70–90 s for a player who follows the prompts (thirteen beats of about 4 s to read, plus the waits); 3 s for one who presses Esc at A1. B4's budget in the first-five-minutes spec moves from 0–60 s to 0–90 s.

**Codex revisit** (K → *Hoe werkt het?* → *Spanning, stroom, weerstand*): the same figure without Ruud's strip, opened in the meterkast skin with a **[De tuin]** / **[De meterkast]** tab on the sheet to switch skins (a cross-fade, the same pairs); the hint, the readout and the reveal corner; and a plain caption under the card (no formulas; those stay behind the reveal):

> *Spanning is de druk. Stroom is wat er echt loopt. Weerstand houdt het tegen.*
> *Een kabel houdt ook een beetje tegen. Gaat er veel stroom door, dan wordt hij warm, en veel sneller dan je denkt.*
> *Hoe langer of dunner de kabel, hoe minder spanning er aan het eind overblijft.*
> *De tuinslang is een vergelijking. Water loopt eruit; stroom gaat heen en weer terug. En een echte tuinslang merk je nauwelijks warm worden; een kabel wel. In het echt duurt opwarmen minuten; hier gaat het sneller.*

---

## 5. "The how, never the answer"

The explainer teaches physics that later missions rest on. It must not tell the player what is wrong at Voltana or which countermeasure fits. Concretely, checked against `content/problems_tier1.yaml` and `content/missions.yaml`:

**It must NOT show, say or caption:**

1. **Anything about the El Amrani dossier** or why any order waits: no heat pump in either skin, no "aansluiting verzwaren", no claim that the wait is physical (congestion) or not. The tier-1 problems behind that wait are process problems; the explainer must neither point at them nor send the player toward "het net is vol" as a false lead. Ruud's R8 line names a long street cable as an analogy; it says nothing about Nova-Oost, and it asks about length, not about a street being full.
2. **"3×25 A" as a standard, a threshold or "enough"**: `custom_design`'s key clue (*driekwart van de ontwerpen is een standaard 3x25A-aansluiting*) and `grid_study_queue`'s root cause (*elke aanvraag boven 3x25A krijgt een volledige netstudie*) both turn on it. The rating may appear only as an engraved label on a meterkast part, never in a line, caption or reveal.
3. **Voltage *rising* from feed-in** (solar panels pushing the voltage up, the 253 V cut-out of an omvormer, transformer taps / aftakkingen): that is `inverters_tripping`'s mechanism, its key clue (254 V at noon, the 253 V norm) and its best countermeasure (`tap_review_per_neighbourhood`). The spike shows consumption only (in the tuin, water only flows *from* the tap); the feed-in direction belongs to a later explainer that unlocks only after `inverters_tripping` is closed (PLAN 2.7c: *net capacity/congestion*).
4. **"Dikkere kabel" as the fix for anything at Voltana.** The haspel swap shows physics in a house; it never says the street needs a thicker cable (`targeted_reinforcement` is a countermeasure with a fit of 0.7, below the tap review's 1.0). R8's "Dikke kabel, net als een dikke slang" is about the bench.
5. **Transformers, ordering or lead times** (`transformer_wait`), **reserved capacity** (`unused_capacity`), **wachtlijsten, netstudies**.
6. **Any step name or KPI** of the simulation (Intake, Werkvoorbereiding, doorlooptijd …), and any number that is also a clue.

**Allowed:** the physics, the analogy, the words *netcongestie* and *spanningsdaling* in the codex caption of a *later* explainer (not this one), and Ruud's last line ("ergens zit weerstand … dat ga jij zien"), which names no step.

**Test:** the explainer's Dutch strings (beats, hint, caption, reveal, labels, marker tags) contain none of the forbidden tokens (§6.4, T7).

---

## 6. Godot pipeline for the spike

### 6.1 Authoring → export (outside Godot)

1. **Author with `anatomy`** in `tools/explainers/spanning/` (a Node `build.mjs` per anatomy's framework-free path, with `model.mjs` holding §3.4's model). The page it builds is the design proof, **both skins** with a toggle: capture desktop and close-ups of each, `--audit` to zero, line check to zero (anatomy step 10), **light theme only**.
2. **Export layers**: a second script, `export.mjs`, writes one SVG per **layer** and a `manifest.json`:
   - a layer is a painter's-order slot that changes independently. Shared: `base`, `haspel1_frame`, `haspel2_frame`. Meterkast: `panel`, `cable_thin`, `cable_thick`, `haspel{1,2}_{rolled,unrolled}`, `switch_{lamp,kettle,heater}_{off,on}`, `kettle_lamp_on`, `heater_glow`, `stroomtang`, `multimeter`, `thermometer`, `appliances`. Tuin: `wall_tap`, `tap_gauge`, `tap_gauge_needle`, `hose_thin`, `hose_thick`, `hosereel{1,2}_{rolled,unrolled}`, `tap_{dripper,big,small}_{closed,open}`, `outlets`, `spray_{dripper,big,small}_{1,2,3}` (three densities), `flowmeter`, `flowmeter_wheel`, `end_gauge`, `end_gauge_needle`. Heat: `heat_tint_{hose,cable}_{thin,thick}` (pure white silhouettes, tinted in Godot);
   - every SVG shares one viewBox, so layers stack at offset (0,0); the manifest holds `{id, file, z, group, skin, pair}` (`skin` ∈ {shared, tuin, meterkast}; `pair` = the counterpart's id for every tuin layer and every meterkast layer that has one; needles also carry `pivot`); LCD windows are exported as rects (`{id, rect}`), not drawn;
   - **inline every style**: resolve `ISO_CSS` classes to `fill`/`stroke` attributes, no `<style>`, no CSS variables, no filters, no masks the renderer may drop; **text to paths** (the one engraved "B16"). Godot renders SVG with ThorVG, whose SVG support is limited and which does not rasterise text (Godot docs, *Importing images*);
   - the script also writes `fixtures.json`: §3.4's table computed by `model.mjs`, for the cross-check test (T2).
3. Output goes to `game/assets/explainers/spanning/` (SVGs, manifest, fixtures). The authoring folder is not shipped.

### 6.2 Content

`content/explainers.yaml` (new; built by `tools/build_content.py` like the other content):

```yaml
explainers:
  - id: spanning_stroom_weerstand
    name: Spanning, stroom, weerstand
    place: ruud.office.whiteboard          # the world object that opens it
    assets: explainers/spanning            # folder with manifest.json
    model: ohm_cable                       # the GDScript model id
    one_idea: "Hoe meer stroom er door dezelfde kabel moet, hoe warmer die kabel wordt."
    analogy:
      skin: tuin
      mapping:                             # §1.3; each row names its layer pair
        - {analogy: "de buitenkraan", real: "de groep in de meterkast", pair: [wall_tap, panel]}
        - {analogy: "de tuinslang", real: "de kabel", pair: [hose_thin, cable_thin]}
        # … every row of §1.3 that has a picture
      limit_line: "Eén verschil. Water loopt de slang uit. Stroom niet: die gaat door de kabel heen, en komt weer terug."
    controls: [switch_lamp, switch_kettle, switch_heater, haspel]
    hint: {tuin: "Draai een kraantje open.", meterkast: "Zet een apparaat aan.", haspel: "Zet een apparaat aan. Pak de andere haspel."}
    caption: [...]                         # §4's four codex lines, no formulas
    reveal:                                # §1.6; the ONLY field that may hold a formula
      label: "Laat de rekensom zien"
      lines:
        - {words: "Stroom = spanning ÷ weerstand.", formula: "I = U / R", live: current}
        # … as §1.6
    beats:
      - {id: a1, phase: tuin, speaker: ruud, idea: druk, text: "Vergeet even de elektriciteit. …", wait_for: any_switch, timeout_s: 10}
      # … a2, a2_dripper, a3, a4, x, r1, r2, r3, r4, r4_already_on, r5, r5_lamp, r6, r7, r7_never_alone, r8a, r8b as §4
    sources:
      - {fact: "230 V, 50 Hz", title: "Netbeheer Nederland, Spanningskwaliteit"}
      - {fact: "Un ± 10 %", title: "Netbeheer Nederland, Achtergronddocument Spanningskwaliteit 2024 (Netcode)"}
    estimates:
      - {fact: "rho 0,0175", reasoning: "…"}   # every estimate row of §3.5
```

The build validates: every beat has an id, a phase and text; `wait_for` is a known control or empty; every control id exists in the manifest; every mapping `pair` names two manifest layers with opposite skins; every number in the `model` parameters has a `sources` or `estimates` row; **no formula pattern (§6.4, T9) and no digit appears in `beats`, `hint`, `caption` or `analogy`**; formulas only under `reveal`.

### 6.3 Runtime

- **Opening** (immersion, 2.7c): the whiteboard is an interactable in Ruud's room. On "Leg maar uit" the office `Camera3D` tweens toward the board (0.6 s, ease in-out); then the explainer's `CanvasLayer` fades in over 0.4 s (an `AnimationPlayer` clip `open`) on the **tuin** skin; the 3D view stays rendered and dims behind it. Closing plays `close` and the camera tween in reverse, and the player is back in the room at the close.
- **Scene** `game/src/ui/explainer/explainer_view.tscn`: `CanvasLayer` → `Control` (the card, drawn as a sheet with a clip) → a `Control` "stage" that scales the viewBox to the card (keep aspect) → one `TextureRect` per manifest layer in z order (the off-skin's layers at alpha 0) → `Label`s on the LCD rects (a 7-segment-like font, ink colour) → the card's hint `Label`, readout `Label`s and the reveal corner (a `Button` drawn as a folded paper corner) with its `RichTextLabel` strip (hidden until opened) → Ruud's strip (`RichTextLabel`) and **[Klaar]**.
- **The skin cross-fade (X)**: a `Tween` that, for each mapping pair in content order, fades the tuin layer out and the meterkast layer in over 0.3 s, staggered 0.25 s (`estimate:` about 1.4 s for the five groups; tune in the spike so the eye can follow one pair at a time); the marker tags are `Label`s in a handwriting font placed at the pair's rect. Reduced motion: one 0.3 s fade of all pairs at once.
- **Import**: SVG as `Texture2D` rasterised at import with **SVG > Scale 2.0** (`estimate:` sharp at 1080p–1440p for a card of about 60 % of the screen; tune in the spike). The project renders with **GL Compatibility**; Godot's DPITexture (runtime re-rasterisation of SVG) is worth a 10-minute test in the spike, with import-time rasterisation as the default.
- **Motion**: kraantjes and switches swap `open`/`closed` and `on`/`off` layers with a 0.08 s ease (`Tween` on `scale.y` or a quarter turn about the pivot from the manifest); the needles rotate about their pivot and the paddle wheel spins at a rate ∝ I; spray layers pick a density by each outlet's current share; the readout, LCD labels and the reveal's numbers follow the model each frame while the temperature eases (`T += (T_target − T) · (1 − exp(−dt/τ))`, τ = 4 s); the heat tint is the tint layer's `modulate` (colour ramp from ink to a warm orange at 70 °C, alpha from §3.4), the same value on the hose and on the cable so the warmth carries through X; the haspel swap is an `AnimationPlayer` clip that crossfades the two cable layers and the two haspel states over 0.6 s. Everything stops when the explainer closes; **reduced motion** (settings) sets τ → 0, stops the wheel and spray animation (static densities), and swaps without the clip.
- **Model**: `game/src/rules/explainers/ohm_cable.gd`, a pure `RefCounted` with `static func solve(switches: Dictionary, cross_section_mm2: float) -> Dictionary` returning `{current_a, u_end_v, du_v, p_app_w, p_cable_w, t_cable_c, r_cable_ohm, r_total_ohm}`; no scene access, so it is tested headless. The tuin's needles and wheel read the same result.
- **Reveal**: `explainer_view.gd` builds the strip text from `content.reveal` and the live result; `reveal_open` is a session flag (and saved for the codex). The strip is the only node whose text may contain a formula.
- **Input**: mouse on the kraantjes, switches, haspels and reveal corner (hit areas from manifest rects); keys 1–3, H and R; Spatie advances, Esc closes; controller later.
- **Codex**: on first open (or on "Ik ken het, Ruud"), the session marks `explainers_seen.spanning_stroom_weerstand`; the codex (K) gets a *Hoe werkt het?* section that lists seen explainers and opens the same view without Ruud's strip, with the skin tab. Saved in the save file (a list of ids, validated against the content on load; an unknown id is dropped, never a crash).

**Alternative judged in the spike: pre-rendered frames.** The figure has 2³ × 2 = 16 discrete states per skin plus a continuous heat tint, needles and LCD numbers. Frames would need 32 full images plus the tint and labels anyway, and the part-by-part cross-fade needs separate layers, so layers win on size, on the cross-fade and on keeping the numbers live. Frames win only if ThorVG mis-renders the anatomy output (gradients, fine strokes at 0.4 px). **Decision rule:** if the layered render's screenshot differs visibly from the anatomy PNG at 2× (missing fills, broken strokes) and inlining styles does not fix it, export PNG layers from headless Chrome (anatomy's `capture.mjs`) instead of SVG, with the same manifest; the runtime does not change.

### 6.4 Acceptance tests

**Godot logic tests** (`game/tests/test_explainer_ohm.gd`, run by `run_tests.gd`):

- **T1 Model numbers.** For every row of §3.4's table, `solve()` matches within 0,01 A, 0,1 V, 1 W and 0,5 °C.
- **T2 One model.** `solve()` matches every case in `fixtures.json` written by `model.mjs` (the picture and the game cannot drift apart).
- **T3 Physics properties.** For all 16 states: more switches on never lowers `current_a` or raises `u_end_v`; the 2,5 mm² cable always gives a lower `du_v` and `t_cable_c` than 1,5 mm² at the same load; on the same cable, `p_cable_w / p_cable_w'` equals `(I/I')²` within 0,1 %; `p_app_w + p_cable_w` equals `U_n · I` within 1 W (energy is conserved); nothing on → all zeros and 230 V.
- **T4 Parts load.** Every manifest layer's file exists and loads as a `Texture2D`; z values are unique within a skin; every control id in the content has a hit rect and its on/off (open/closed) layers in both skins; every LCD id has a rect; every needle has a pivot.
- **T5 Flow.** The beat machine runs A1 → close with simulated input; each `wait_for` beat advances on its control and on the 10 s timeout; A2's and R5's small-load branches, R4's already-on variant, R7's never-alone variant and the R6 skip behave as §4; the control state carries over X; the haspel ignores clicks before R8; Esc at any beat closes and leaves the player in Ruud's room with `explainers_seen` set.
- **T6 No quiz.** The view contains no button other than the controls, the reveal corner, the codex skin tab and **[Klaar]**; no beat has choices.
- **T7 Never the answer.** No Dutch string of the explainer (beats, hint, caption, reveal, labels, marker tags) contains any of: `3x25`, `3×25`, `zonnepaneel`, `omvormer`, `253`, `trafo`, `transformator`, `aftakking`, `warmtepomp`, `El Amrani`, `netstudie`, `wachtlijst`, `verzwar`, and no simulation step name or KPI name from the content.
- **T8 Save.** `explainers_seen` and the codex's `reveal_open` round-trip; an unknown id is dropped on load.
- **T9 No formula until asked** (new, the simple-first rule). With the reveal folded, walk the view through every beat (A1 → close) and every control state, and collect the text of every visible `Label` and `RichTextLabel`; none matches the formula pattern `[=÷×²·Ω]|ΔU|\b[IUPR]\s*[=/]`. Open the reveal: the strip matches it (the reveal works). Fold it again: no match. Also on the content: no string in `beats`, `hint`, `caption` or `analogy` matches the pattern or contains a digit (numbers only as readouts, §1.5).
- **T10 The analogy maps.** Every tuin layer has a `pair` in the meterkast skin and vice versa where the mapping says so; every `analogy.mapping` row names a pair that exists; after X every tuin layer is at alpha 0 and every paired meterkast layer at alpha 1; the switch state and the heat tint's value are the same just before and just after X.

**Content pipeline** (`python tools/build_content.py --check`): `explainers.yaml` validates (§6.2), every model parameter has a source or an estimate, and the T9 content check runs here too.

**Visual and play acceptance** (screenshots, as for every visual task; the spike's go/no-go):

- **V1** the in-game card at 1920×1080 and at 1280×720 next to anatomy's own PNG, **for each skin**: same parts, no missing fills, lines end on something, the hose and the cable readable as the `lit` part, the hose recognisably a garden hose;
- **V2** the open and close transitions and the skin cross-fade X run without a pop (a contact sheet of 10 frames each); in X, a viewer can point at which tuin part became which meterkast part;
- **V3** frame time with the explainer open ≤ the office's own frame time + 2 ms on the dev machine; texture memory for both skins' layers ≤ 48 MB (`estimate:` budget for two skins at Scale 2.0, up from 32 MB for one; measure and record);
- **V4** in the 2.7d cold playtest, B4 takes ≤ 90 s median for players who choose "Leg maar uit". No one is asked to name a formula.
- **V5 Say the one idea back** (new; PLAN 2.7c playtest check). At least three test readers **with no technical background** (no electrical, physics or engineering training beyond secondary school; not working in energy) play B4 cold. Right after, each is asked one open question: *"Wat liet Ruud je zien? Zeg het in je eigen woorden."* Pass: at least two of three say the one idea (§1.1) in any wording, e.g. "als er meer stroom door een kabel gaat, wordt hij warm" or "net als een slang: hoe meer erdoor, hoe warmer". Record each answer verbatim in the playtest notes; also record whether they used the water picture to explain it (a sign the analogy carried) and whether anyone opened the reveal. A fail sends the teaching layer (§1) back for a rewrite before the next explainer is designed.

**Spike done when:** T1–T10 pass, V1–V3 are recorded, V5 has run, and PLAN 2.7c records the pipeline decision (layers as SVG or as PNG) and the V5 result for the next explainers.

---

## 7. Claude's calls (for PLAN §10)

1. **Analogy first, then the real object, in one picture.** The tuin and the meterkast share the bench and every slot, so the cross-fade *is* the mapping (Merijn's simple-first rule; this reverses the first version's "no water tank").
2. **The real object is a meterkast group, a verlengkabel on a haspel and a stekkerdoos**, not the kettle with a resistance slider of the first-five-minutes draft: real actions (switching, swapping a cable) and both later ideas (heating, voltage drop) in one bench.
3. **Ruud says no numbers**; the instruments do. Every formula is behind **"Laat de rekensom zien"**, words first, then symbols, then the live numbers.
4. **The limit Ruud says is the loop** ("stroom gaat heen en komt terug"); the exaggerated warm hose is owned up to in the codex caption.
5. **Two controls: the kraantjes/switches and the haspel**; the haspel only from R8 on; cable length stays fixed at 25 m (the long rural line is Ruud's question in R8, and a later explainer).
6. **Consumption only**; voltage rise from feed-in waits for a later explainer that unlocks after `inverters_tripping` (§5.3).
7. **No heat pump on the bench** in either skin (the El Amrani letter is about one; §5.1).
8. **Light theme on the whiteboard**; the only colours are the hose's green and the heat.
9. **B4 grows to 0–90 s.** Simple first costs about thirty seconds for a player who follows; it stays skippable at every beat.

## Sources

Opened (approved list) for the first version; nothing new was opened for this revision:
- Netbeheer Nederland, *Spanningskwaliteit*: https://www.netbeheernederland.nl/veiligheid-en-infrastructuur/spanningskwaliteit (230 V, 50 Hz; NEN-EN 50160 at the connection).
- Netbeheer Nederland, *Achtergronddocument Spanningskwaliteit in Nederland, resultaten 2024*: https://www.netbeheernederland.nl/sites/default/files/2025-04/04.03._achtergronddocument_spanningskwaliteit_2024_0.pdf (the Netcode's ±10 % / +10 −15 % band; Un = 230 V in LS-netten).
- Netbeheer Nederland, *Wat is netcongestie?*: https://www.netbeheernederland.nl/sites/default/files/2026-06/wat_is_netcongestie.pdf (overload of cables and transformers at peak; risk of damage).
- Netbeheer Nederland, factsheet *Spanningsproblemen door zonnepanelen*: https://www.netbeheernederland.nl/sites/default/files/Factsheet__258.pdf (three phases of 230 V; the 253 V omvormer cut-out, used only for §5).
- Netbeheer Nederland, *Laagspanningsnet*: https://www.netbeheernederland.nl/netcapaciteit-en-flexibiliteit/laagspanningsnet (context: extra transformatorhuisjes, work in the street).
- ACM, *Ruim 300.000 huishoudens en bedrijven kunnen geld besparen met kleinere aansluiting stroomnet*: https://www.acm.nl/nl/publicaties/acm-ruim-300000-huishoudens-en-bedrijven-kunnen-geld-besparen-met-kleinere-aansluiting-stroomnet (standard connection up to 3×25 A; used only for §5).
- Godot docs, *Importing images*: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html (SVG rasterised at import with ThorVG, limited support, text must be paths; SVG > Scale; DPITexture).

Not opened: NEN 1010 / IEC 60364-5-52 and NEN-EN 50160 themselves (nen.nl, paywalled): the cable ratings, the 16 A group and the PVC temperature are marked `estimate:` until checked there. The water analogy needs no web source (standard school physics); its limits are argued in §1.4.
