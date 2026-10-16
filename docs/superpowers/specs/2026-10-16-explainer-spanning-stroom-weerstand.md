# Hoe werkt het? #1: spanning, stroom en weerstand op het bord van Ruud (PLAN 2.7c spike)

> Status: by the mission-and-dialog design agent (Claude, 2026-10-16). **Docs only.** The first "Hoe werkt het?" explainer and the 2.7c spike, placed by the first-five-minutes spec (`2026-10-16-first-five-minutes.md`, B4). Dutch game text, English ids and comments; every number sourced from the approved list or marked `estimate:` with its reasoning.
>
> Read with: CLAUDE.md §2 (immersion; evidence first; nothing handed over; respect the player's time); PLAN 2.7c (design rules), 2.7d (the opening), 2.10 (diegetic UI); the voice sheet (`2026-10-15-four-tier-audit.md` §6, Ruud); the `anatomy` skill (the authoring tool).
>
> **What changes in the first-five-minutes spec.** B4's opening choice ("Leg maar uit" / "Ik ken het, Ruud") and its last two lines stay. The figure and the lines in between are replaced by §2 and §3 here: the control is no longer a "Weerstand" slider on a kettle (no one turns the resistance of a kettle) but **switches on a stekkerdoos and a choice of verlengkabel**, which are things a person really does, and which carry the two ideas the game needs later (a cable heats; voltage is lost along a cable). The kettle's numbers are kept.

---

## 1. Learning goal

**In one sentence:** spanning pushes, stroom is what actually flows, and every cable has weerstand, so more stroom through the same cable means more warmte in the cable (P = I²·R) and less spanning at the far end (ΔU = I·R).

**What the player can do afterwards** (and where the game uses it):

| The player can… | Where the game leans on it |
|---|---|
| say that switching on more appliances raises the stroom, not the spanning | reading a meter, a load curve, a KPI in kW or A |
| predict that the cable warms faster than the stroom grows (twice the current, four times the heat) | **netcongestie**: a street cable or a transformer carries the current of a whole street; at peak it heats, and an operator must keep it below its limit (Netbeheer Nederland, *Wat is netcongestie?*: overloaded transformers and cables risk damage and longer outages) |
| predict that a longer or thinner cable leaves less spanning at the end | **spanningsdaling** at the end of a long rural line; why the Netcode sets a band around 230 V at the connection point (±10 %) |
| tell spanning (V), stroom (A) and vermogen (W) apart on a readout | every later explainer (transformator, kabel en mof, slimme meter) and the KPI views |

What it deliberately does **not** teach here: feed-in raising the voltage (solar), transformer taps, three-phase connections, protection and tripping. Those belong to later explainers, and two of them sit close to a tier-1 mission answer (§4).

---

## 2. The object

### 2.1 Concept (anatomy step 3)

**A real group from a real meterkast feeding a real verlengkabel.** On Ruud's whiteboard tray stands what every house has: a small panel with one **groep** (a 16 A installatieautomaat and the kWh-meter display), a **kabelhaspel** with 25 m of cable unrolled across the bench, and at its end a **stekkerdoos** with three switched appliances: an LED-lamp, a **waterkoker** and an **elektrische kachel**. A **stroomtang** clamps the cable near the panel; a **multimeter** is plugged into the stekkerdoos; a small **contactthermometer** is taped to the cable halfway. A second haspel with a thicker cable stands beside the first.

*What moves and what it means:* a switch flips and the appliance draws stroom; the stroomtang's number rises; the multimeter at the far end drops a few volts; the cable on the bench slowly darkens toward warm (a heat tint, no flames) and its thermometer climbs. Swap the haspel and the same load leaves more spanning at the end and a cooler cable.

**Why this object and not a water tank** (Merijn's brief): the player is at a grid operator. Every number on the figure is one they can meet on a real instrument in a real meterkast, and the same parts reappear in the field (Marco's crew carries a stroomtang). The analogy to the street is made by Ruud in words (§3, R5), not by the picture.

**Card** (anatomy step 8; drawn as a sheet clipped to the whiteboard, not a game window, PLAN 2.10):
- top left `Hoe werkt het? 1`; top right **Spanning, stroom, weerstand**;
- bottom left the hint: *"Zet een apparaat aan. Pak de andere haspel."*;
- bottom right the live readout (§2.4).

**Theme:** the anatomy **light** theme (paper), because the figure lives on a whiteboard. Ink tones only; the one `lit` accent is **the cable** (the part the player should watch). The only colour is the heat tint on the cable, because heat is the subject.

### 2.2 Parts (anatomy step 4; a Figure, 40–80 parts)

| Group | Parts |
|---|---|
| **Base** (`lo`) | bench plate with bevel; four rubber feet; groove inset along the front edge; corner screws (dots with rings); ruler strip along the front with ticks every metre of cable, major every 5 m (0–25 m, so the length is read off the bench); a label plate (three rule lines) |
| **Panel** (`mid`) | back plate on two stand-offs; DIN rail with two end clips; **installatieautomaat 16 A** (body, toggle, the engraved "B16" as the one engraved label); aardlekschakelaar beside it (body, test button); **kWh-meter** body with LCD window (Godot label, §5) and a pulse LED; cable gland at the bottom; four screws |
| **Haspel 1, dun** (`mid`, cable `lit`) | drum with two flanges and their spokes; crank with knurled handle; frame with two feet; socket on the drum face with its lid; the unrolled cable (a `tube` route along the ruler strip with a gentle sag, never crossing itself); cable label sleeve; plug into the panel's socket |
| **Haspel 2, dik** (`mid`) | the same parts, a visibly thicker cable, a different label sleeve; stands rolled up until chosen |
| **Stekkerdoos** (`mid`) | body; three sockets; three rocker switches (each its own layer, two states); the cable entry with strain relief; two screws |
| **Appliances** (`hi`) | LED-lamp in a small table foot (bulb, shade, cord); waterkoker (body, lid, handle, base plate, water window, the switch with its own lamp); elektrische kachel (housing, grille bars, two feet, knob) |
| **Instruments** (`hi`) | **stroomtang** clamped on the cable (jaws, body, rotary knob, LCD window); **multimeter** on the stekkerdoos (body, rubber holster, rotary knob, two probes with leads ending on terminal dots in the socket, LCD window); **contactthermometer** taped to the cable (tape band, probe, small LCD) |

About 60 parts; every one sits on another (the haspels on the bench, the panel on its stand-offs, the instruments on the cable or the stekkerdoos, the leads ending on terminal dots).

### 2.3 Painter's order (back to front, bottom to top; anatomy step 7)

Camera: azimuth 45°, elevation 30° (`estimate:` the default; it shows the bench length and the stekkerdoos face). World units ≈ 1 px; the panel stands at the back left, the cable runs to the front right.

1. halo under the bench; bench plate; feet (back two first); groove; ruler strip and ticks; label plate; screws
2. panel stand-offs; back plate; DIN rail; automaat, aardlekschakelaar, kWh-meter (left to right, `depthOf`); gland; panel screws
3. haspel 2 (rolled, back right): frame back half → drum → flanges → frame front half → crank
4. haspel 1 (back left): frame back half → drum with the remaining windings → flanges → frame front half → crank → drum socket
5. **the cable route** (tube chunks, `A.settle` for true depth); the thicker cable occupies **the same slot** (variant layer, §5), so a swap never re-sorts
6. stroomtang (back jaw → cable chunk inside the jaws is already drawn → front jaw → body → knob)
7. contactthermometer (tape band back half → probe → tape front half → LCD)
8. stekkerdoos body → sockets → **switches** (three variant layers) → plugs and cords
9. appliances (lamp, kachel, waterkoker, back to front by `depthOf`)
10. multimeter holster → body → knob → probe leads (`wire`, terminal dots on the socket)
11. **heat tint** over the cable (a separate layer drawn in the cable's own slot, alpha only)
12. card frame, hint, readout (Godot, §5)

Split parts that wrap another: the stroomtang jaws (back/front around the cable), the tape band, the haspel frames around the drum. `--audit` to `audit passed` and the line check to `line ends: 0` before export (anatomy step 10).

### 2.4 Controls and live readout

**Two controls**, both real actions:

1. **Belasting: the three switches on the stekkerdoos** (click a rocker, or keys 1–3). LED-lamp 8 W · waterkoker 2.000 W · kachel 1.500 W; any combination.
2. **Kabel: which haspel** (click the other haspel, or key H). Dun (1,5 mm²) or dik (2,5 mm²), both 25 m. The swap is shown as Ruud's hand rolling one in and plugging the other (a 0.6 s AnimationPlayer clip), not a menu toggle.

**Readout**, shown twice: on the instruments in the drawing (diegetic: the kWh-meter shows W, the stroomtang A, the multimeter V, the thermometer °C) and in the card's bottom right for accessibility and readability:

| Readout | Dutch label | Shown on | Format |
|---|---|---|---|
| U_eind | Spanning aan het eind | multimeter | `225 V` (whole volts) |
| I | Stroom | stroomtang | `8,5 A` (one decimal; two below 1 A: `0,03 A`) |
| P_app | Vermogen in de apparaten | kWh-meter | `1.915 W` (whole watts, Dutch thousands dot) |
| P_kabel | Warmte in de kabel | (card only) | `42 W` |
| T_kabel | Kabel | thermometer | `31 °C` |

**Model** (one pure function; the same model drives the readout, the heat tint and the instruments; anatomy step 2):

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

The cable temperature **eases** to its steady value (exponential follow, time constant `estimate:` 4 s of game time, so the player sees it climb after the switch, not jump; a real cord takes minutes, and the figure says so in its caption: *"In het echt duurt opwarmen minuten; hier gaat het sneller."*). The heat tint's alpha follows (T_kabel − 20) / 50, clamped to 0..1.

**Expected readouts** (computed from the model; these are the test fixtures, §5.4):

| Kabel | Aan | I (A) | U_eind (V) | ΔU (V, %) | P_app (W) | P_kabel (W) | T_kabel (°C) |
|---|---|---|---|---|---|---|---|
| 1,5 mm² | lamp | 0,03 | 230 | 0,0 | 8 | 0 | 20 |
| 1,5 mm² | waterkoker | 8,51 | 225 | 5,0 (2,2 %) | 1.915 | 42 | 31 |
| 1,5 mm² | waterkoker + kachel | 14,65 | 221 | 8,5 (3,7 %) | 3.245 | 125 | 54 |
| 1,5 mm² | alle drie | 14,68 | 221 | 8,6 (3,7 %) | 3.252 | 126 | 54 |
| 2,5 mm² | waterkoker | 8,58 | 227 | 3,0 (1,3 %) | 1.948 | 26 | 25 |
| 2,5 mm² | waterkoker + kachel | 14,87 | 225 | 5,2 (2,3 %) | 3.343 | 77 | 34 |

What the player can find by playing: twice the stroom is about four times the warmte (42 → 125 W for 1,72× the stroom, 1,72² = 2,96); the thin cable is about 20 °C warmer at the same load; the appliances get a little less than their label (1.915 W, not 2.000 W) because the cable keeps some spanning; the lamp changes nothing. The 16 A automaat is never reached with these loads (14,9 A at most), so nothing trips (tripping is a later explainer).

### 2.5 Every number and its source

| Number | Value | Source |
|---|---|---|
| Nominal voltage, low-voltage net | 230 V, 50 Hz | Netbeheer Nederland, *Spanningskwaliteit* (netbeheernederland.nl/veiligheid-en-infrastructuur/spanningskwaliteit): "In Nederland is de hoogte van de spanning in dit net 230 volt met een frequentie van 50 Hertz"; at the connection the voltage must meet NEN-EN 50160 |
| Allowed band at the connection point | Un ± 10 % for 95 % of 10-min averages over a week; +10 % / −15 % for all | Netcode elektriciteit, quoted in Netbeheer Nederland, *Achtergronddocument Spanningskwaliteit in Nederland, resultaten 2024* (netbeheernederland.nl, PDF) |
| Three phases of 230 V each in a 3-fase meterkast | 3 × 230 V + nul | Netbeheer Nederland, factsheet *Spanningsproblemen door zonnepanelen* (netbeheernederland.nl, PDF). **Not shown to the player** (§4) |
| A household connection up to 3×25 A | 3×25 A | ACM, *Ruim 300.000 huishoudens en bedrijven kunnen geld besparen met kleinere aansluiting stroomnet* (acm.nl). Drawn only as the engraved rating on the meterkast's main switch if the panel is extended; **never said** (§4) |
| Congestion: cables and transformers overloaded at peak, risk of damage | — | Netbeheer Nederland, *Wat is netcongestie?* (netbeheernederland.nl, PDF, 2026-06) |
| Ohm's law, P = U·I, P = I²·R, R = ρ·L/A | — | physics; any textbook (no web source needed) |
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

The source verifier (2.7c rule) checks the sourced rows; the estimates carry their reasoning here and in `content/explainers.yaml` (§5.2).

---

## 3. The script: Ruud at the whiteboard

**Voice** (four-tier audit §6): short; one question per line; questions, not lectures; self-mocking about his age; never says the right move; no "goed gedaan" without a question after it. He explains here because he explains it to every new colleague (B4's premise), but each beat ends in a question he does not answer.

**Format.** Six beats, R1–R6. Each beat is one or two lines in the talk panel's small strip at the bottom of the card (the same font as the talk panel, no portrait frame; Ruud stands beside the whiteboard in the room behind the cross-fade). **Skippable at every beat:** Spatie / klik advances a beat; Esc or **[Klaar]** in the card's top-right closes the explainer at once, back into the room at B4's last two lines. A beat that waits for a control (R2, R4, R5) also advances on its own after 10 s, and the control stays live. **No quiz:** Ruud's questions have no answer buttons; the player answers with the switches, or not at all.

| Beat | Trigger | Ruud | What the figure does |
|---|---|---|---|
| **R1** | cross-fade done | "Kijk. Een groep uit de meterkast, een haspel van vijfentwintig meter, een stekkerdoos. Meer is het niet." | idle: everything off; the multimeter reads 230 V |
| **R2** | after R1 | "Spanning is de druk: tweehonderddertig volt. Stroom is wat er echt loopt, in ampère. Wat verwacht je als je de waterkoker aanzet?" | the waterkoker's switch pulses once (an ease, no arrow); waits for any switch or 10 s |
| **R3** | a switch flipped (any) | "Zo'n {ampere} ampère. En kijk naar de meter aan het eind. Waar zijn die {volt_weg} volt gebleven?" *(two seconds of silence)* "In de kabel. Een kabel heeft ook weerstand. Wat daar blijft hangen, wordt warmte." | the readout updates; the cable begins to tint. *If the player switched only the lamp:* "Een lampje. Zie je de meter bewegen? Probeer de waterkoker eens." and R3's main line waits for the waterkoker |
| **R4** | after R3 | "Zet de kachel er eens bij. Hoe warm wordt de kabel, denk je?" | waits for the kachel or 10 s; the thermometer climbs to 54 °C on the dun cable |
| **R4b** | kachel on, after the waterkoker alone was seen | "Bijna twee keer zoveel stroom. Bijna drie keer zoveel warmte. Dat leerde ik op de MTS, en toen had ik nog haar." | the card's *Warmte in de kabel* goes 42 → 125 W. *If the player never had the waterkoker on alone:* "Zet de kachel eens uit en weer aan. Let op de warmte in de kabel." and R4b's main line waits for that |
| **R5** | after R4b | "Pak de andere haspel eens. Wat zie je?" *(after the swap, or 10 s)* "Een kabel in de straat werkt net zo. Alleen hangt er een hele straat aan. En op het platteland is hij lang. Wat blijft er dan over aan het eind?" | the swap clip; the cable cools toward 34 °C, the multimeter climbs to 225 V |
| **R6** | after R5 | *(back in the room; B4's lines, unchanged)* "Bij ons op kantoor is het net zo. Er staat druk op: mensen willen een aansluiting. Er loopt maar zoveel door. En ergens zit weerstand." · "Waar? Dat weet ik niet. Dat ga jij zien." | cross-fade back to the whiteboard; the three words stay; the explainer is filed in the codex (K) |

**State rules, so Ruud never says a wrong number.** `{ampere}` (whole amperes) and `{volt_weg}` (whole volts lost, ΔU) are filled from the live model when R3 starts: waterkoker alone on the dun cable gives "Zo'n 9 ampère … die 5 volt", waterkoker and kachel together "Zo'n 15 ampère … die 9 volt". The haspel is not clickable before R5 (in the codex it is free from the start), so R3–R4b always speak about the dun cable; R4b's "bijna twee keer / bijna drie keer" holds for the step from waterkoker alone to waterkoker + kachel (8,51 → 14,65 A; 42 → 125 W) and is spoken only after that step. R1–R5 are new; R6 is B4's existing close. If the player had the kachel on before R4, R4 is skipped and R4b (or its variant) plays. Ruud never says which switch is "right"; the waterkoker is suggested because it is the biggest single change, and the lamp is allowed to do nothing, which is its own lesson.

**Real time:** `estimate:` 45–60 s for a player who follows the prompts (first-five-minutes budget for B4: 0–60 s); 3 s for one who presses Esc at R1.

**Codex revisit** (K → *Hoe werkt het?* → *Spanning, stroom, weerstand*): the same figure without Ruud's strip; the card's hint and readout only, and a three-line caption under the card:

> *Spanning (V) duwt, stroom (A) is wat er loopt, weerstand (Ω) houdt het tegen: I = U / R.*
> *Een kabel heeft ook weerstand. Wat daar verloren gaat, wordt warmte: P = I² · R. Twee keer zoveel stroom geeft vier keer zoveel warmte.*
> *Hoe langer of dunner de kabel, hoe minder spanning er aan het eind overblijft: ΔU = I · R. In het echt duurt opwarmen minuten; hier gaat het sneller.*

---

## 4. "The how, never the answer"

The explainer teaches physics that later missions rest on. It must not tell the player what is wrong at Voltana or which countermeasure fits. Concretely, checked against `content/problems_tier1.yaml` and `content/missions.yaml`:

**It must NOT show, say or caption:**

1. **Anything about the El Amrani dossier** or why any order waits: no heat pump in the figure, no "aansluiting verzwaren", no claim that the wait is physical (congestion) or not. The tier-1 problems behind that wait are process problems; the explainer must neither point at them nor send the player toward "het net is vol" as a false lead. Ruud's R5 line names the street cable as an analogy; it says nothing about Nova-Oost.
2. **"3×25 A" as a standard, a threshold or "enough"**: `custom_design`'s key clue (*driekwart van de ontwerpen is een standaard 3x25A-aansluiting*) and `grid_study_queue`'s root cause (*elke aanvraag boven 3x25A krijgt een volledige netstudie*) both turn on it. The rating may appear only as an engraved label on a meterkast part, never in a line or caption.
3. **Voltage *rising* from feed-in** (solar panels pushing the voltage up, the 253 V cut-out of an omvormer, transformer taps / aftakkingen): that is `inverters_tripping`'s mechanism, its key clue (254 V at noon, the 253 V norm) and its best countermeasure (`tap_review_per_neighbourhood`). The spike shows consumption only; the feed-in direction belongs to a later explainer that unlocks only after `inverters_tripping` is closed (PLAN 2.7c: *net capacity/congestion*).
4. **"Dikkere kabel" as the fix for anything at Voltana.** The haspel swap shows physics in a house; it never says the street needs a thicker cable (`targeted_reinforcement` is a countermeasure with a fit of 0.7, below the tap review's 1.0).
5. **Transformers, ordering or lead times** (`transformer_wait`), **reserved capacity** (`unused_capacity`), **wachtlijsten, netstudies**.
6. **Any step name or KPI** of the simulation (Intake, Werkvoorbereiding, doorlooptijd …), and any number that is also a clue.

**Allowed:** the physics, the words *netcongestie* and *spanningsdaling* in the codex caption of a *later* explainer (not this one), and Ruud's last line ("ergens zit weerstand … dat ga jij zien"), which names no step.

**Test:** the explainer's Dutch strings (beats, hint, caption, labels) contain none of the forbidden tokens (§5.4, T7).

---

## 5. Godot pipeline for the spike

### 5.1 Authoring → export (outside Godot)

1. **Author with `anatomy`** in `tools/explainers/spanning/` (a Node `build.mjs` per anatomy's framework-free path, with `model.mjs` holding §2.4's model). The page it builds is the design proof: capture desktop and close-ups, `--audit` to zero, line check to zero (anatomy step 10), **light theme only**.
2. **Export layers**: a second script, `export.mjs`, writes one SVG per **layer** and a `manifest.json`:
   - a layer is a painter's-order slot that changes independently: `static_back` (steps 1–4 minus haspel 1's cable), `cable_thin`, `cable_thick`, `heat_tint_thin`, `heat_tint_thick` (pure white silhouettes, tinted in Godot), `haspel2_rolled`/`haspel2_unrolled` and the same for haspel 1, `switch_{lamp,kettle,heater}_{off,on}`, `kettle_lamp_on`, `heater_glow`, `static_front` (instruments' bodies, leads);
   - every SVG shares one viewBox, so layers stack at offset (0,0) and the manifest holds only `{id, file, z, group}`; LCD windows are exported as rects in the manifest (`{id, rect}`), not drawn;
   - **inline every style**: resolve `ISO_CSS` classes to `fill`/`stroke` attributes, no `<style>`, no CSS variables, no filters, no masks the renderer may drop; **text to paths** (the one engraved "B16"). Godot renders SVG with ThorVG, whose SVG support is limited and which does not rasterise text (Godot docs, *Importing images*);
   - the script also writes `fixtures.json`: §2.4's table computed by `model.mjs`, for the cross-check test (T2).
3. Output goes to `game/assets/explainers/spanning/` (SVGs, manifest, fixtures). The authoring folder is not shipped.

### 5.2 Content

`content/explainers.yaml` (new; built by `tools/build_content.py` like the other content):

```yaml
explainers:
  - id: spanning_stroom_weerstand
    name: Spanning, stroom, weerstand
    place: ruud.office.whiteboard          # the world object that opens it
    assets: explainers/spanning            # folder with manifest.json
    model: ohm_cable                       # the GDScript model id
    controls: [switch_lamp, switch_kettle, switch_heater, haspel]
    hint: "Zet een apparaat aan. Pak de andere haspel."
    caption: [...]                         # §3's three lines
    beats:
      - {id: r1, speaker: ruud, text: "Kijk. Een groep uit de meterkast, …"}
      - {id: r2, speaker: ruud, text: "…", wait_for: any_switch, timeout_s: 10}
      # … r3, r3_lamp, r4, r4b, r5a, r5b as §3
    sources:
      - {fact: "230 V, 50 Hz", title: "Netbeheer Nederland, Spanningskwaliteit"}
      - {fact: "Un ± 10 %", title: "Netbeheer Nederland, Achtergronddocument Spanningskwaliteit 2024 (Netcode)"}
    estimates:
      - {fact: "rho 0,0175", reasoning: "…"}   # every estimate row of §2.5
```

The build validates: every beat has an id and text; `wait_for` is a known control or empty; every control id exists in the manifest; every number in `model` parameters has a `sources` or `estimates` row.

### 5.3 Runtime

- **Opening** (immersion, 2.7c): the whiteboard is an interactable in Ruud's room. On "Leg maar uit" the office `Camera3D` tweens toward the board (0.6 s, ease in-out); then the explainer's `CanvasLayer` fades in over 0.4 s (an `AnimationPlayer` clip `open`), the 3D view stays rendered and dims behind it. Closing plays `close` and the camera tween in reverse, and the player is back in the room at R6.
- **Scene** `game/src/ui/explainer/explainer_view.tscn`: `CanvasLayer` → `Control` (the card, drawn as a sheet with a clip) → a `Control` "stage" that scales the viewBox to the card (keep aspect) → one `TextureRect` per manifest layer in z order → `Label`s on the LCD rects (a 7-segment-like font, ink colour) → the card's hint `Label` and readout `Label`s → Ruud's strip (`RichTextLabel`) and **[Klaar]**.
- **Import**: SVG as `Texture2D` rasterised at import with **SVG > Scale 2.0** (`estimate:` sharp at 1080p–1440p for a card of about 60 % of the screen; tune in the spike). The project renders with **GL Compatibility**; Godot's DPITexture (runtime re-rasterisation of SVG) is worth a 10-minute test in the spike, with import-time rasterisation as the default.
- **Motion**: switches swap `on`/`off` layers with a 0.08 s rocker ease (`Tween` on `scale.y` about the pivot from the manifest); the readout and LCD labels follow the model each frame while the cable temperature eases (`T += (T_target − T) · (1 − exp(−dt/τ))`, τ = 4 s); the heat tint is the tint layer's `modulate` (colour ramp from ink to a warm orange at 70 °C, alpha from §2.4); the haspel swap is an `AnimationPlayer` clip that crossfades the two cable layers and the two haspel states over 0.6 s. Everything stops when the explainer closes; **reduced motion** (settings) sets τ → 0 and swaps without the clip.
- **Model**: `game/src/rules/explainers/ohm_cable.gd`, a pure `RefCounted` with `static func solve(switches: Dictionary, cross_section_mm2: float) -> Dictionary` returning `{current_a, u_end_v, du_v, p_app_w, p_cable_w, t_cable_c}`; no scene access, so it is tested headless.
- **Input**: mouse on the rockers and haspels (hit areas from manifest rects); keys 1–3 and H; Spatie advances, Esc closes; controller later.
- **Codex**: on first open (or on "Ik ken het, Ruud"), the session marks `explainers_seen.spanning_stroom_weerstand`; the codex (K) gets a *Hoe werkt het?* section that lists seen explainers and opens the same view without Ruud's strip. Saved in the save file (a list of ids, validated against the content on load; an unknown id is dropped, never a crash).

**Alternative judged in the spike: pre-rendered frames.** The figure has 2³ × 2 = 16 discrete states plus a continuous heat tint and LCD numbers. Frames would need 16 full images plus the tint and labels anyway, so layers win on size and on keeping the numbers live. Frames win only if ThorVG mis-renders the anatomy output (gradients, fine strokes at 0.4 px). **Decision rule:** if the layered render's screenshot differs visibly from the anatomy PNG at 2× (missing fills, broken strokes) and inlining styles does not fix it, export PNG layers from headless Chrome (anatomy's `capture.mjs`) instead of SVG, with the same manifest; the runtime does not change.

### 5.4 Acceptance tests

**Godot logic tests** (`game/tests/test_explainer_ohm.gd`, run by `run_tests.gd`):

- **T1 Model numbers.** For every row of §2.4's table, `solve()` matches within 0,01 A, 0,1 V, 1 W and 0,5 °C.
- **T2 One model.** `solve()` matches every case in `fixtures.json` written by `model.mjs` (the picture and the game cannot drift apart).
- **T3 Physics properties.** For all 16 states: more switches on never lowers `current_a` or raises `u_end_v`; the 2,5 mm² cable always gives a lower `du_v` and `t_cable_c` than 1,5 mm² at the same load; on the same cable, `p_cable_w / p_cable_w'` equals `(I/I')²` within 0,1 %; `p_app_w + p_cable_w` equals `U_n · I` within 1 W (energy is conserved); nothing on → all zeros and 230 V.
- **T4 Parts load.** Every manifest layer's file exists and loads as a `Texture2D`; z values are unique; every control id in the content has a hit rect and its on/off layers; every LCD id has a rect.
- **T5 Flow.** The beat machine runs R1 → R6 with simulated input; each `wait_for` beat advances on its control and on the 10 s timeout; R3's lamp branch, R4b's variant and the R4/R5 shortcuts behave as §3; R3's tokens equal the model's rounded values; the haspel ignores clicks before R5; Esc at any beat closes and leaves the player in Ruud's room with `explainers_seen` set.
- **T6 No quiz.** The view contains no button other than the controls and **[Klaar]**; no beat has choices.
- **T7 Never the answer.** No Dutch string of the explainer (beats, hint, caption, labels) contains any of: `3x25`, `3×25`, `zonnepaneel`, `omvormer`, `253`, `trafo`, `transformator`, `aftakking`, `warmtepomp`, `El Amrani`, `netstudie`, `wachtlijst`, `verzwar`, and no simulation step name or KPI name from the content.
- **T8 Save.** `explainers_seen` round-trips; an unknown id is dropped on load.

**Content pipeline** (`python tools/build_content.py --check`): `explainers.yaml` validates (§5.2), and every model parameter has a source or an estimate.

**Visual and play acceptance** (screenshots, as for every visual task; the spike's go/no-go):

- **V1** the in-game card at 1920×1080 and at 1280×720 next to anatomy's own PNG: same parts, no missing fills, lines end on something, the cable readable as the `lit` part;
- **V2** the open and close transitions run without a pop (a contact sheet of 10 frames);
- **V3** frame time with the explainer open ≤ the office's own frame time + 2 ms on the dev machine; texture memory for the layers ≤ 32 MB (`estimate:` budget for one card at Scale 2.0; measure and record);
- **V4** in the 2.7d cold playtest, B4 takes ≤ 60 s median for players who choose "Leg maar uit", and asked afterwards "wat gebeurt er met een kabel als er meer stroom door gaat?", at least two of three say it gets warmer (any wording). No one is asked to name a formula.

**Spike done when:** T1–T8 pass, V1–V3 are recorded, and PLAN 2.7c records the pipeline decision (layers as SVG or as PNG) for the next explainers.

---

## 6. Claude's calls (for PLAN §10)

1. **The object is a meterkast group, a verlengkabel on a haspel and a stekkerdoos**, not the kettle with a resistance slider of the first-five-minutes draft: real actions (switching, swapping a cable) and both later ideas (heating, voltage drop) in one bench.
2. **Two controls: the three switches and the haspel**; cable length stays fixed at 25 m (the rural long line is Ruud's question in R5, and a later explainer).
3. **Consumption only**; voltage rise from feed-in waits for a later explainer that unlocks after `inverters_tripping` (§4.3).
4. **No heat pump on the bench** (the El Amrani letter is about one; §4.1).
5. **Light theme on the whiteboard**; the only colour is the cable's heat.

## Sources

Opened (approved list):
- Netbeheer Nederland, *Spanningskwaliteit*: https://www.netbeheernederland.nl/veiligheid-en-infrastructuur/spanningskwaliteit (230 V, 50 Hz; NEN-EN 50160 at the connection).
- Netbeheer Nederland, *Achtergronddocument Spanningskwaliteit in Nederland, resultaten 2024*: https://www.netbeheernederland.nl/sites/default/files/2025-04/04.03._achtergronddocument_spanningskwaliteit_2024_0.pdf (the Netcode's ±10 % / +10 −15 % band; Un = 230 V in LS-netten).
- Netbeheer Nederland, *Wat is netcongestie?*: https://www.netbeheernederland.nl/sites/default/files/2026-06/wat_is_netcongestie.pdf (overload of cables and transformers at peak; risk of damage).
- Netbeheer Nederland, factsheet *Spanningsproblemen door zonnepanelen*: https://www.netbeheernederland.nl/sites/default/files/Factsheet__258.pdf (three phases of 230 V; the 253 V omvormer cut-out, used only for §4).
- Netbeheer Nederland, *Laagspanningsnet*: https://www.netbeheernederland.nl/netcapaciteit-en-flexibiliteit/laagspanningsnet (context: extra transformatorhuisjes, work in the street).
- ACM, *Ruim 300.000 huishoudens en bedrijven kunnen geld besparen met kleinere aansluiting stroomnet*: https://www.acm.nl/nl/publicaties/acm-ruim-300000-huishoudens-en-bedrijven-kunnen-geld-besparen-met-kleinere-aansluiting-stroomnet (standard connection up to 3×25 A; used only for §4).
- Godot docs, *Importing images*: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html (SVG rasterised at import with ThorVG, limited support, text must be paths; SVG > Scale; DPITexture).

Not opened: NEN 1010 / IEC 60364-5-52 and NEN-EN 50160 themselves (nen.nl, paywalled): the cable ratings, the 16 A group and the PVC temperature are marked `estimate:` until checked there.
