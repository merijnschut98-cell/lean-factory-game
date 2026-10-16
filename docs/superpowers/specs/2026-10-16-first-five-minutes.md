# De eerste vijf minuten: the opening as one scene (PLAN 2.7d)

> Status: by the mission-and-dialog design agent (Claude, 2026-10-16), from Fable's 2.7d. **Docs only**; built with the floors (2.1), the creator (2.7b), the minimap (2.1b), the first explainer (2.7c) and the title screen (2.7). Dutch game text, English ids and comments; numbers sourced or marked `estimate:`.
>
> Read with: CLAUDE.md §2 (immersion; respect the player's time; dialogs are give and take; nothing handed over); PLAN §4.1 (a mission is a mystery with *a face*, a number and a choice), 2.1, 2.1b, 2.7, 2.7b, 2.7c, 2.10; the Act 0 tutorial talks (`2026-10-16-act0-tutorial-talks.md`); the dialog UI audit (`2026-10-16-dialog-ui-audit.md`); `content/missions.yaml` `training_mon` (Rondleiding, the El Amrani letter, the training setup: three of Anouk's four colleagues on a course all week).

## 0. Summary

**Why.** Immersion is decided in the first five minutes, and so is whether a player stays. Today a new game drops the player in the office with a HUD full of numbers, a mission line ("Geen missie: ga naar het missiebord") and a control bar. This doc replaces that with **one continuous scene**: no menu chain, no mission board, no score, until the player has met a person.

**The scene, in seven beats** (§2 has every line):

| # | Beat | Real time (estimate) | What the player learns by doing | HUD that appears |
|---|---|---|---|---|
| B1 | **De pasfoto**: the creator as the photo for your Voltana badge | 60–120 s | who *you* are | nothing |
| B2 | **De ontvangst**, Monday 12 October 2026, 08:25: Yvonne prints your badge | 20 s | your name and face are in the world | nothing |
| B3 | **Ruud haalt je op**: the walk to Aansluitingen, 1e verdieping | 90–150 s | walking (WASD/klik), the camera, the stairs, **the minimap**, **name tags** (he introduces people as you pass) | movement hint (fades), minimap at the top of the stairs, name tags |
| B4 | **Het bord van Ruud**: the first *Hoe werkt het?* (spanning, stroom, weerstand), skippable; a garden hose first, then the real circuit | 0–90 s | the game's own name; one idea: more stroom through the same cable makes it warm | nothing |
| B5 | **De brief**: why you are here | 15 s | what you are here to do | nothing |
| B6 | **De rest van je eerste dag**: a named skip to 19:00 | 10 s | time passes when you let it | the clock |
| B7 | **Anouk, om zeven uur**: the first talk, unruinable | 90–180 s | the meter, listening, that people are people | the talk panel; afterwards the journal (J) |

The first talk starts at about **5½ minutes** for a player who walks without hurrying and follows the whiteboard (`estimate:` 90 s creator + 20 s + 120 s walk + 80 s board + 25 s = 335 s; the board grew from 45 s when the explainer went simple-first with the hose analogy, 2026-10-16). A player who skips the board starts it before minute 4½. The mission line, the board, the budget, XP and the belt all come **after** the first talk (§3).

**What the player can answer at the end** (the acceptance test, §5): *"Ik ben de nieuwe CI-lead bij Voltana. Ik moet uitzoeken waarom mensen zo lang op een aansluiting wachten, te beginnen bij de familie El Amrani. Ik heb Ruud, Sanne, Joost, Marco en Anouk ontmoet."*

---

## 1. Design rules for the opening

1. **One scene, no menus.** From "Nieuw spel" to the end of Anouk's talk the player never opens a panel they did not walk to. The creator is in the fiction (a badge photo); the explainer is on a whiteboard; the skip is the day passing.
2. **A face before a number** (PLAN §4.1). The first person the game asks the player to *listen* to is Anouk, still drawing at seven in the evening. The first number (`{dossier_weken}`, the El Amrani wait) comes on a letter, from a family, not from a KPI.
3. **The HUD appears one element at a time, when first needed** (§3). Nothing on screen before it means something.
4. **Five names, no more.** Ruud introduces four people on the walk (Sanne, Joost, Marco, Anouk); everyone else has a name tag on hover but is not introduced. Yvonne at reception is a sixth face, not a name to remember. `estimate:` working memory holds about four to five new chunks (Cowan, 2001); the acceptance test asks for the names.
5. **Nothing handed over.** Ruud says *what* you are here to do (look, at one dossier), never *what* is wrong. The whiteboard explains spanning, stroom and weerstand; it does not say where the resistance in Voltana is.
6. **Respect the player's time.** Every beat after the creator's first name can be cut short: the creator has a "Zo is het goed" at every step; Ruud's walk can be overtaken ("Ik loop zelf wel"); the board is skippable; the skip is one click; the talk can be ended politely at any moment and cannot be ruined. A returning player who chooses "Inwerkweek overslaan" on the title screen (2.7) skips the whole scene except the creator.
7. **The world is already running.** People sit at their desks, phones ring at Intake, Marco comes up the stairs in PPE. The player is new; Voltana is not.
8. **No timer, no fail.** Ruud waits where you left him. Nothing in the opening can be missed for good: a person not passed on the walk is met on Tuesday; a skipped explainer stays on the board and in the codex.

---

## 2. The beats, with every line

Speakers: **Ruud** Hoekstra (Directeur Netbeheer regio Zuidmark, the coach); **Yvonne** Kramer (new, receptie, begane grond; a face, not a dialog target); Sanne Bakker, Joost van Dijk, Marco (as in the cast); Anouk de Vries. `{speler}` is the player's first name; `{hij_zij}` follows the chosen body (2.7b).

### B1 — De pasfoto (the creator)

"Nieuw spel" fades to a phone screen, a mail from Voltana's HR, then into the camera: the creator is the photo for your badge. The traits and options are 2.7b's; only the frame and the labels are new here. (Layout, controls, the name's validation, the portrait and the tests: `2026-10-16-creator-and-minimap.md` §1.)

**The mail** (one screen, one button):

> **Van:** HR Voltana Netbeheer
> **Onderwerp:** Welkom! Je eerste dag, maandag 12 oktober
>
> Hoi,
>
> Fijn dat je maandag begint als CI-lead bij Aansluitingen, regio Zuidmark. Om half negen word je verwacht bij de ontvangst, Stationsweg 4 in Nova. Ruud Hoekstra haalt je daar op.
>
> Wil je vast een pasfoto sturen? Dan ligt je toegangspas maandag klaar.
>
> Groet, HR
>
> **[Pasfoto maken]**

**The camera** (the creator itself; the player's character in a neutral grey photo booth light, head and shoulders, turning slowly). Labels in the creator (2.7b's traits, written as a phone camera would):

| Step | Label | Line under it |
|---|---|---|
| 1 | **Je voornaam** (op je pas) | "Zo noemen je collega's je." |
| 2 | **Lichaam** · man / vrouw | "Collega's spreken over je als hij of zij." |
| 3 | **Huidskleur**, **Haar**, **Haarkleur**, **Ogen**, **Gezicht**, **Bril** | — |
| 4 | **Wat trek je maandag aan?** (Kleding) | "Buiten draag je er je PBM overheen." |
| 5 | **[Foto maken]** | the shutter sound; the photo freezes |

The photo freezes, a small "Verzonden ✓" appears, and the phone goes dark. **[Zo is het goed]** at every step jumps to step 5 with what is chosen so far (only the first name is required; an empty name asks once: "Hoe mogen we je noemen?").

### B2 — De ontvangst, maandag 12 oktober, 08:25

Fade in: the begane grond of the hoofdgebouw from behind the player, the revolving door turning behind them. Rain on the windows (`estimate:` October in the Netherlands; a dry day is fine too, the line does not depend on it). Yvonne at the counter, a monitor, a lanyard box. No HUD at all.

The player walks or is placed one step from the counter; E or a click on the counter (the first interaction, shown by a ring, as every place today).

> **Yvonne:** "Goedemorgen! Jij bent {speler}, toch? Ik herkende je van de foto."
> *(she slides the badge across: the player's photo from B1, their first name, "CI-lead · Aansluitingen")*
> **Yvonne:** "Je pas. Daarmee kom je overal, behalve in het onderstation. Daar heb je Ruud voor nodig. Hij komt je zo halen, hij zit nog in het MT."
> *(a beat; the lift pings)*
> **Yvonne:** "O, kijk. Daar is hij al. Hij is nooit te laat. Wel altijd net."

**Immersion payoff:** the badge with the player's own face is the first object the world hands them. It stays visible on the character's lanyard and is the slot's portrait on the title screen (2.7).

### B3 — Ruud haalt je op: the walk to Aansluitingen

Ruud comes out of the lift, coffee in a paper cup. He shakes hands. **He walks ahead and stops at each person; he waits if the player lags** (no timer) and says one waiting line after 20 s at most once per stop.

**Leg 1 — the hall to the stairs (walking).** When Ruud turns to go, the first and only control hint appears, small, bottom centre: **"Lopen: WASD of klik op de vloer"**. It fades after the player has moved three metres, and is never shown again.

> **Ruud:** "{speler}. Ruud. Welkom. Ik had je zelf willen ophalen om half negen, maar het MT liep uit. Dat gaat vaker gebeuren, en het is nooit een goed teken."
> **Ruud:** "We nemen de trap. De lift is voor de koffie."
> *(waiting line, if the player lags:)* "Neem je tijd. Ik sta hier."

The Klantcontactcentrum is visible through glass on the right: headsets, a wall screen. Ruud nods at it while walking and does not stop:

> **Ruud:** "Daar komen de telefoontjes binnen. Van mensen die wachten. Daar kom je nog."

**Leg 2 — the stairs (the camera).** The stairwell turns; the first time the walls block the view, a second hint fades in for five seconds: **"Draaien: Z en C · Zoomen: muiswiel"**. It is shown once, only if the player has not turned the camera yet.

**Leg 3 — the top of the stairs (the minimap; its build spec is `2026-10-16-creator-and-minimap.md` §2).** On the landing of the 1e verdieping, Ruud hands over a folded floor plan. The minimap appears in its corner (2.1b) **at that moment**, with a soft fold-open animation, drawn as the same site plan:

> **Ruud:** "Hier. De plattegrond. Ik werk hier twintig jaar en ik loop nog steeds de verkeerde gang in."
> *(the minimap opens; the rim arrow points to Aansluitingen)*
> **Ruud:** "Aansluitingen is rechtsaf. Waar de stapels liggen."

**Leg 4 — Intake (name tags).** The walk enters the open office of Aansluitingen at Intake. Ruud stops at Sanne. **The first name tag appears the moment Ruud says her name** (from then on, tags show on hover and in reach, as built in 1.3):

> **Ruud:** "Sanne Bakker. Teamleider Intake. Hier komt elke aanvraag binnen."
> **Sanne** *(one hand over the phone)*: "Hoi! Sorry. Maandag. Ik spreek je nog, echt."
> **Ruud** *(walking on, quieter)*: "Maandag is hier altijd maandag."

Rachid sits behind Sanne with the three trays. He has a name tag on hover but Ruud does not introduce him (rule 4). If the player hovers him: the tag reads "Rachid Ouali · Intake".

**Leg 5 — Marco on the stairs from the yard.** As they cross toward Werkvoorbereiding, Marco comes in through the side door in his orange jacket, helmet in his hand:

> **Ruud:** "Marco. Ploegleider monteurs. Hij komt alleen boven als er iets misgaat."
> **Marco:** "Dan zie je me vaak." *(to Ruud)* "Klaverstraat, weer niet gereed. Derde keer."
> **Ruud:** "Vertel het {haar_hem_speler} straks maar. {Zij_Hij_speler} is er om dat soort dingen te horen."
> **Marco** *(a look at the player, not unfriendly)*: "Dat zeiden ze in 2012 ook."

(`{haar_hem_speler}` and `{Zij_Hij_speler}` are the player's own pronoun tokens, 2.7b; the line is the one third-person line about the player in the opening, per the token audit 2.7b asks for.)

**Leg 6 — Werkvoorbereiding.** Four desks; three empty with course folders on the chairs; at the fourth Anouk draws, two trays beside her. Joost stands behind her, a printout in his hand.

> **Ruud:** "Joost van Dijk, teamleider Werkvoorbereiding. En Anouk de Vries."
> **Joost:** "Welkom. Je komt in een rare week. Drie van mijn vier zitten op cursus."
> **Anouk** *(looks up, a quick smile, back to the drawing)*: "Hoi. Sorry, ik zit er even middenin."
> **Ruud** *(walking on)*: "Onthoud dat bureau."

That is all. Ruud does not say why. (Gemba readability, PLAN §5.1: the two trays, the three empty chairs and the stack are the tell; a player who looks sees it, nobody says it.)

**At his door** (added 2026-10-16 evening, Merijn Q10: Ruud sits with Aansluitingen by choice in the first hundred days; `2026-10-16-creator-and-minimap.md` §3). Ruud opens a glass door at the edge of the open office: a small room, a desk with a ring from a coffee cup, a whiteboard.

> **Ruud:** "Mijn kamer. Voorlopig."
> **Ruud:** "Boven heb ik er een met uitzicht op het spoor. Maar boven zit ik te ver van het werk."

He does not explain it (nothing handed over); B4 starts here.

**Overtaking Ruud.** If the player walks ahead to Ruud's room on their own, he catches up there: "Je vond het zelf. Goed teken.", then the two lines at his door. Every person not passed is met later in the week; their tags work from the start.

### B4 — Het bord van Ruud: *Hoe werkt het?* (spanning, stroom, weerstand)

> **Updated (2026-10-16, the "Simple first" rule, PLAN 2.7c):** the figure and Ruud's lines between "Leg maar uit" and the last two lines are those of `2026-10-16-explainer-spanning-stroom-weerstand.md` §4, which is the source of truth; the summary below follows it. The opening choice and the last two lines stay.

Ruud's room. A whiteboard with three words in his handwriting, half wiped from an earlier meeting. He picks up a marker. Two answers appear as the first choice of the game, both fine:

> **Ruud:** "Weet je waarom dit spel… sorry. Weet je waarom dit vak *spanning* heet? Ik leg het iedere nieuwe collega uit. Het duurt een minuut."
> **[Leg maar uit]** · **[Ik ken het, Ruud]**

**[Ik ken het, Ruud]:**
> **Ruud:** "Mooi. Dan laat ik het op het bord staan. Voor als je het ooit wilt zien." *(→ B5; the explainer is in the codex, K, under "Hoe werkt het?")*

**[Leg maar uit]:** the camera moves to the whiteboard and cross-fades into the explainer (2.7c, the first one; the rules of 2.7c apply: simple first, interactive, one or two controls, no quiz, closes back into the room). **The one idea** the player should be able to say back: *"Hoe meer stroom er door dezelfde kabel moet, hoe warmer die kabel wordt."* One idea per beat; Ruud speaks plain Dutch, short sentences, **no numbers** (the instruments show them); formulas only behind the sheet's folded corner **Laat de rekensom zien**.

*De tuin (the analogy first):* the board shows a buitenkraan, a garden hose on a slanghaspel and three kraantjes, on the same bench where the real circuit will stand.

> **Ruud:** "Vergeet even de elektriciteit. Denk aan een tuinslang." · "De kraan duwt het water de slang in. Dat duwen heet druk." · "Wat verwacht je als je een kraantje opendraait?" *(A1; waits for a kraantje or 10 s)*
> **Ruud:** "Nu loopt er water. Hoeveel water er per tel doorheen gaat, heet stroom." · "Kijk naar het wieltje op de slang. Draai er nog een open." *(A2)*
> **Ruud:** "Meer kraantjes open. Meer water door dezelfde slang." · "Kijk naar de drukmeter aan het eind. Waarom zakt die?" *(silence)* "De slang houdt het water een beetje tegen. Dat tegenhouden heet weerstand." *(A3)*
> **Ruud:** "En duw je heel veel door een smalle slang?" *(silence)* "Dan wordt hij warm. Voel maar." *(A4)*

*De meterkast (the cross-fade, part by part: kraan → groep, slang → kabel, kraantjes → knoppen op de stekkerdoos, wieltje → stroomtang, drukmeter → multimeter):*

> **Ruud:** "Nu hetzelfde. Maar dan echt." *(X)*
> **Ruud:** "De kraan is nu de meterkast. De slang is de kabel. De kraantjes zijn de knoppen." *(R1)*
> **Ruud:** "Druk heet hier spanning. Die tellen we in volt." · "Stroom tellen we in ampère. Kijk maar op de tang." *(R2; the readout and the reveal corner appear)*
> **Ruud:** "Eén verschil. Water loopt de slang uit." · "Stroom niet: die gaat door de kabel heen, en komt weer terug." *(R3: where the analogy stops)*
> **Ruud:** "Zet de waterkoker eens aan. Wat doet de tang?" *(R4)* → "Dat getal is de stroom." · "Kijk nu naar de meter aan het eind. Waar is dat stukje spanning gebleven?" *(silence)* "In de kabel. Daar wordt het warmte. Net als bij de slang." *(R5)*
> **Ruud:** "Zet de kachel er eens bij. Hoe warm wordt de kabel, denk je?" *(R6)* → "Meer stroom. En de kabel wordt veel warmer dan je zou denken." · "Dat leerde ik op de MTS. Toen had ik nog haar." *(R7)*
> **Ruud:** "Pak de dikke haspel eens. Wat zie je?" → "Dikke kabel, net als een dikke slang." · "Een kabel in de straat werkt net zo. Maar soms is hij heel lang. Wat blijft er dan over aan het eind?" *(R8)*

*Back in the room (the close, unchanged):*

> **Ruud:** "Bij ons op kantoor is het net zo. Er staat druk op: mensen willen een aansluiting. Er loopt maar zoveel door. En ergens zit weerstand."
> **Ruud:** "Waar? Dat weet ik niet. Dat ga jij zien."

Branches (a small load only, an appliance already on, the kachel before R6) and every state rule are in the explainer spec §4. Skippable at every beat (Esc / **[Klaar]** → the close).

**Correctness** (evidence first): the model, every number and its source are in the explainer spec §3.4–3.5 (Ohm's law over the loop with the cable's resistance; 230 V nominal, Netbeheer Nederland / NEN-EN 50160, ±10 % at the connection under the Netcode; a 2,000 W kettle on 25 m of 1,5 mm² cable draws about 8,5 A and the cable keeps about 5 V). The water analogy is a comparison, not physics: Ruud names where it stops (R3), and the codex caption names the rest (a real hose barely warms).

**Nothing handed over:** the last line says there is resistance somewhere and that the player will find it; it names no step.

### B5 — De brief: what you are here to do

Ruud sits down, slides a letter across the desk (the `training_mon` letter; its `{dossier_weken}` is the real age of the followed order, 1.8):

> **Ruud:** "Dit lag vanochtend op mijn bureau."
> *(the letter, in a handwriting font, close up; 6–8 lines)*
>
> > *Geachte heer Hoekstra,*
> > *Wij hebben op {aanvraag_datum} een zwaardere aansluiting aangevraagd voor onze warmtepomp. Nu wachten we al {dossier_weken}. Mijn moeder woont bij ons in. Zij heeft het snel koud. Niemand kan ons zeggen wanneer u komt. Ik vraag niet om voorrang. Ik vraag om een datum.*
> > *Met vriendelijke groet, F. El Amrani, Nova-Oost*
>
> **Ruud:** "Ik wil niet dat je dit oplost. Nog niet. Ik wil dat je gaat kijken. Deze week leer je hoe. Volgende week volg je dit dossier, van de brief tot de meter."
> **Ruud:** "En als je iemand spreekt: vraag eerst hoe het gaat. En meen het."

The last line is the **first move card** (Stemming peilen, tutorial talks §2), spoken instead of shown on a briefing card; the card itself appears in the codex (K) under *Gesprekken* when the talk in B7 ends.

(`training_mon`'s goal, observing Intake and Werkvoorbereiding, is met by the walk; its debrief moves to Tuesday morning's briefing, §4.)

> **Ruud:** "De rest van de dag ben je van IT en HR. Laptop, pas, wachtwoorden. Sterkte."

**Fixed 2026-10-16 evening (D9 audit A9):** the letter is signed *F. El Amrani* (she is Fatima in the cast and on the phone; it was "N."), and the date is the token `{aanvraag_datum}`: per the arc (§3 there) her request was born on **27 July**, eleven weeks before 12 October, so the followed order must be that old (PLAN 1.8a) and her notebook, this letter and `{dossier_weken}` all read the same date. The paragraph below is the earlier note.

The letter's date: `training_mon` says "vanochtend lag er een brief"; the El Amrani call (arc doc §3) dates her request to September–October; the letter's "20 augustus" is the date of the *request*, not the letter. **Check with the followed order (1.8):** the date shown must be the order's real creation day; if the order is younger, the line reads `{aanvraag_datum}` (a token the builder fills from the dossier). The line above uses a fixed date only as an example.

### B6 — De rest van je eerste dag (the skip)

The first named skip, drawn as the phone (diegetic, PLAN 2.10), in three notifications that stack and fade, while the light in Ruud's window turns from grey to dark:

> 📱 **IT Servicedesk** · 10:40 — "Je laptop staat klaar. Je wachtwoord moet je bij de eerste keer wijzigen."
> 📱 **IT Servicedesk** · 11:15 — "Je wachtwoord is gewijzigd." · 11:16 — "Je wachtwoord is gewijzigd." · 11:20 — "Je account is tijdelijk geblokkeerd."
> 📱 **Leerplatform** · 16:50 — "E-learning *Veilig werken bij Voltana* afgerond. Score: geslaagd."

**The clock appears now**, top left, as the skip ends: **"ma 12 okt, 19:02"**. It is the first HUD element (rule 3): the first time time matters is the first time time has passed.

The player stands in the corridor with their coat on (the character model's jacket, 2.7b clothing + coat). The office is dim; the cleaners' trolley at Intake. One desk lamp is on, at Werkvoorbereiding. The minimap's arrow points to the exit; nothing points to Anouk. The player walks out past her, or toward her (the only lit desk is the tell). If they walk to the exit without stopping, Anouk calls out as they pass within 6 m:

> **Anouk:** "O! Jij bent er ook nog? Ik dacht dat ik de laatste was."

(That line opens the talk, so a player who does not look still meets her. It is not a trap and not a timer: the exit simply passes her desk.)

### B7 — Anouk, om zeven uur: the first talk

The first dialog of the game. **Unruinable** (`tutorial: true`), short, and the first time the player sees the talk panel. Before the first move, one line under the meter, once in the game, in the panel's own small grey text:

> *Openheid: hoe open Anouk nu met je praat. Kies hoe je reageert; je ziet aan haar wat het doet.*

It disappears after the first move. Nothing else explains the UI: the band names, the arrows and Anouk's face do (dialog UI audit U2, U3).

```yaml
dialogs:
  - id: anouk_seven
    name: Anouk om zeven uur
    person: anouk
    kind: persuade
    mission: training_mon                  # the arrival day; its observe goal is met by the walk (§4)
    tutorial: true                         # the first talk of the game: openness floor 10, patience 12, cannot be ruined
    teaches: [mood]                        # Ruud's spoken card in B5
    mood: moe                              # seven in the evening, alone at four desks
    patience: 12
    place: connections.design
    clock: "19:02"                         # the scene's time; the talk ends at about 19:30 (spec §3.5)
    # start: overloaded 35 - 10 (moe) + 0 (team trust) + 0 (trust 50) + 0 (morale 50) + 0 = 25, Op z'n hoede
    opening: "O! Jij bent er ook nog? Ik dacht dat ik de laatste was."
    position: {text: "Nog twee tekeningen. Dan ga ik. Echt. Zeg maar niet tegen Joost dat ik er nog zat, hè.", tags: [claim], tell: safety}   # person needs: Anouk is safety
    layers:
      - id: interest
        at: 45
        via: [mood, empathy, open_question]
        text: "Morgen zit ik hier alleen. Joost moet naar het MT, de anderen zitten op cursus. Als dit vanavond niet af is, ligt het er morgen nog. En achter elke tekening wacht iemand."
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [silence, empathy, reflect]
        lead_in: {text: "Mijn vriend appte net…", tags: [hesitation]}
        text: "Of ik weer laat ben. Ik had gezegd dat ik Noor van de opvang zou halen. Nu doet hij het. Weer. … Ik zeg steeds dat het tijdelijk is."
        tags: [admission]
        unlocks:
          facts: [heard:anouk_seven]
          proposals: [come_tomorrow]
    proposals:
      - {id: walk_out_together, name: Samen naar buiten, text: "Zullen we samen naar buiten lopen? De tekeningen zijn er morgen ook nog.",
         addresses: [concern], reply: "… Ja. Ja, goed. Ik pak mijn jas."}
      - {id: leave_one_drawing, name: Eén tekening laten liggen, text: "Wat als je er één laat liggen, en die morgen als eerste doet?",
         addresses: [interest], reply: "Eén. Hm. De school kan een dag wachten. Die vragen het pas in januari."}
      - {id: come_tomorrow, name: Morgen even langskomen, hidden: true,
         text: "Mag ik morgen langskomen, overdag? Gewoon kijken hoe het hier gaat als je alleen zit.",
         addresses: [concern], reply: "Kijken. Overdag. … Ja. Dan zie je het tenminste niet alleen om zeven uur."}
    co_proposal: {id: come_tomorrow, text: "Weet je wat. Kom morgen langs. Dan zie je hoe het er overdag uitziet. Het ziet er overdag niet beter uit, hoor."}
    lines:
      mood: "Hoe is het met je? Je zit hier nog best laat."
      open_question: "Waar werk je nu aan?"
      empathy: "Alleen aan vier bureaus, op een maandagavond. Dat is ook wat."
      reflect: "Het klinkt alsof je het liever anders had."
      silence: "(je blijft staan en wacht)"
      paraphrase: "Dus als het vanavond niet af is, ligt het morgen bij jou alleen."
    replies:
      mood:
        lands: {text: "Hoe het is? … Moe. Eerlijk gezegd. Fijn dat je het vraagt.", tags: [feeling]}
    warning: "Sorry. Ik moet echt nog even."
    outcomes:
      commitment: "Ik pak mijn jas. Dank je. Dat had ik nodig, iemand die zegt dat het mag."
      partial: "Nog één tekening. Dan ga ik. Beloofd."
      heard: "Fijn dat je even bleef staan. Dat doet niet iedereen om deze tijd."
      none: "Ik moet echt nog even. Tot morgen!"
      compliance: "Oké. Als jij het zegt."
      ruined: "Ik moet echt nog even."        # unreachable (tutorial); kept for the validator
    # routes (start 25; the engine of the tutorial talks doc §4, same archetype, mood and thresholds as sanne_monday there):
    #   A (the day's move): mood x1.5 +12 37 (her line, a feeling) > empathy +6 43 > open_question +6 49 (interest, tagged feeling)
    #     > reflect +10 59 (heard) > paraphrase +7 66 (lead-in, a hesitation) > silence +12 > 74 capped (concern)
    #     > propose come_tomorrow +8 > ask: commitment (8 moves)
    #   B (no mood): open_question 31 > paraphrase 38 (heard) > empathy 44 > open_question 50 (interest) > reflect 60 > inquiry 68 (lead-in)
    #     > empathy (concern) > propose walk_out_together > ask: commitment (9 moves)
    #   C (short, honest): mood 37 > paraphrase +7 44 (heard: her position is a claim) > empathy +6 50 (interest) > propose leave_one_drawing +8 58
    #     (addresses the revealed interest) > close: heard (>= 15 above the start; 5 moves)
    #   trap (pushing early): propose walk_out_together before heard: -12, floor 10; "Sorry. Ik moet echt nog even." (the warning); the talk goes on.
    # the lesson: the face of Act I's problem (overtime at the bottleneck) is met as a person, before any number;
    #   the concern is personal, not the process: the player hears what the overtime costs, not why it happens.
```

**Distinct from her later talks** (one person, three beats, no repeats): Monday evening is *what the overtime costs her* (Noor, the opvang); Tuesday's `anouk_first_look` is *being watched* (the stopwatch); the later check-in `anouk_late` is *perfectionism as fear*. A player who heard her on Monday starts Tuesday's talk 10 higher (memory `heard`, spec §3.6), so the first kindness pays the next morning.

**After the talk.** Anouk walks out with the player (on `walk_out_together` or a commitment) or stays at her lamp (otherwise). Outside, the player's phone buzzes once (tutorial talks §3: Ruud names the move; Monday's "Ruud kwam even langs" becomes a text, because Ruud went home):

> 📱 **Ruud** · 19:41 — the `ruud_names` line, e.g. "Je vroeg eerst hoe het met Anouk ging. Dat heet Stemming peilen. Daarna praatte Anouk anders. Zag je dat?"

Then the journal key appears in the HUD (**"J  journaal"**), with one entry in the Mensen tab: Anouk, and what the player heard in her words. **The first five minutes end here.** The screen fades to Tuesday morning.

---

## 3. The HUD, one element at a time

Today's HUD shows everything from the first frame: VOLTANA, date and time, budget, XP and belt, the mission line, and a control bar. In the opening each comes when it is first needed, and stays from then on.

| Element | Appears | Why then |
|---|---|---|
| Control hints | B3 leg 1 (lopen), leg 2 (draaien, zoomen), each once, fading | when the player first needs to move or look |
| Name tags | B3 leg 4, when Ruud says "Sanne" | the world names people the way people do |
| **Minimap** (2.1b) | B3 leg 3, the plan Ruud hands over | the first time the player could get lost |
| **Clock** (date and time) | B6, as the first skip ends | the first time time has passed |
| Talk panel | B7 | the first talk |
| **Journal** (J) | after B7 | the first thing worth remembering |
| **Mission line** (top right) | Tuesday 08:30, with `training_tue`'s briefing | the first assigned task; **no mission board before the first talk** (2.7d) |
| Mission board | Tuesday, at Ruud's briefing ("Het bord hangt bij de Obeya") | when there is more than one thing to choose from |
| **Budget** | Thursday, `training_thu` (the first experiment that costs money) | the first time money matters |
| XP and belt | Friday, at the week's debrief (the first belt line: "Witte band") | the first reward |
| Codex (K) | after B4 if the explainer was opened, else Tuesday with the first glossary card | the first thing to look up |
| Map (M) | Tuesday, "the floor plan, bigger" | the minimap first, the overview when the player wants it |

**For returning players** ("Inwerkweek overslaan", 2.7): the full HUD from the start, as today.

**Rule for later features (add to PLAN §6.2):** a new HUD element gets an appearance moment, written next to it in its task, or it waits.

---

## 4. Changes this needs elsewhere

1. **`training_mon` becomes the arrival day.** Its goal (observe Intake and Werkvoorbereiding) is met by Ruud's walk; its briefing is spoken in B3–B5 instead of shown on a card; its debrief ("Je kent nu twee plekken …") moves to the top of Tuesday's briefing, from Ruud: "Gisteren zag je twee plekken waar een aanvraag langskomt. {dossier_weken} onderweg: hoeveel uur is er al echt aan gewerkt, denk je?" (the debrief's hard-coded "Elf weken" becomes `{dossier_weken}`, as the briefings already do, 1.8).
2. **The Act 0 tutorial schedule shifts by one talk.** Monday now holds one talk, `anouk_seven` (Stemming peilen). Monday's two daytime talks cannot happen *after* a talk at seven in the evening:
   - `sanne_monday` → **`sanne_tuesday`**, Tuesday 08:30, the first talk of Tuesday, `teaches: [open_question]` (the second Monday move, now Tuesday's first card). Her opening is re-dated: "Goedemorgen. Sorry, het is dinsdag, maar hier is het nog maandag: alles van het weekend ligt er nog." Her position: "Dinsdag is hier de nieuwe maandag. Alles wat in het weekend binnenkwam, plus wat gisteren bleef liggen. Maar dat ziet boven niemand, hè." (`tell: recognition`, person needs §7 of the tutorial talks) Everything else unchanged; her route B (without mood) is the open-question route.
   - `rachid_monday` → **an optional walk-around talk** (`trigger: {walkaround: true, days: [training_tue, training_thu]}`, tutorial, unchanged text), so the quiet newcomer is met by those who look; no card depends on him.
   - Tuesday then holds Sanne (Open vraag) and `anouk_first_look` (Begrip tonen); **Samenvatten** moves to Wednesday's card with `mieke_tuesday` → `mieke_wednesday` as Wednesday's first talk. Wednesday has three talks (Mieke, Joost, Linda) and three cards (Samenvatten, Doorvragen, Gevoel benoemen); Thursday and Friday are unchanged. The eight moves are still all named by Friday.
   - The tutorial talks doc's summary table is updated with a pointer here (done with this doc).
3. **Yvonne Kramer** joins `cast.json` (receptie, begane grond; not a dialog target in Phase 2; a walk-around check-in later is fine).
4. **Two new tokens** for third-person lines about the player: `{haar_hem_speler}`, `{Zij_Hij_speler}` (Marco's leg 5), with `{speler}` and `{hij_zij}` from 2.7b.
5. **The followed order's date** (`{aanvraag_datum}`) for the letter in B5, from 1.8's dossier.
6. **The 2.7c explainer spike** should be *this* one (spanning, stroom, weerstand: a garden hose first, then a meterkast group, a haspel and a stekkerdoos), not the transformer: it comes first in the story, it is the simplest physics, and it carries the game's name. The transformer follows in Act II.

---

## 5. Acceptance

From PLAN 2.7d, made checkable:

1. **The cold test (Merijn and two friends, none of whom has seen the opening).** Each plays from "Nieuw spel" until the screen fades to Tuesday, without help. Afterwards, asked "Wat kom je hier doen?" and "Wie heb je ontmoet?", each can say, in their own words:
   - **what they are there to do:** find out why people wait so long for a connection, starting with the El Amrani family (any wording with *wachten*/*aansluiting*/*El Amrani*/*kijken* counts);
   - **whom they met:** at least **three of the five** (Ruud, Sanne, Joost, Marco, Anouk), with Anouk among them.
   Two of three passing is a pass; a fail sends the beat that lost them back to design (observe where they hesitated: the playtest log, 1.4, records the time per beat).
2. **The first talk starts within five minutes** of "Nieuw spel" for a player who takes the default path (watches the board, follows Ruud): measured in the playtest log, target ≤ 5:00 (median of the three). *Decided (Merijn, 2026-10-16):* the simple-first board (B4, 0–90 s) puts it at about 5:35, and that stands: five minutes is a target, not a must, and a good explanation trumps it. Acceptance is ≤ 6:00; trim the creator's default path or the walk only if players get bored, never the teaching layer.
3. **No panel before B7** except the creator and the letter; no budget, XP, belt or mission line before Tuesday (screenshot of every beat, as for every visual task).
4. **Every beat after the first name can be cut short** (the creator's "Zo is het goed", overtaking Ruud, "Ik ken het, Ruud", the one-click skip, *Afronden* in the talk), and the opening can be skipped whole by a returning player.
5. **Nothing can be missed for good:** a player who runs straight to Ruud's room meets Sanne, Joost and Marco on Tuesday; one who skips the board finds it in the codex; one who walks past Anouk is called by her.

**Tests for the builder** (Godot, with the beats in content):
- the beat order B1 → B7 holds and no mission is offered before `anouk_seven` ends;
- each HUD element's visibility flips exactly at its beat (§3), and a returning player's "Inwerkweek overslaan" shows the full HUD at once;
- `anouk_seven` cannot be ruined; routes A, B and C reach their outcomes on the real engine; the trap costs and the talk goes on;
- the badge's portrait and name match the save's `player.look` and first name;
- the letter's date and `{dossier_weken}` come from the followed order (no hard-coded weeks).

---

## 6. Claude's calls (for PLAN §10)

1. **The creator is framed as a mail and a phone camera**, not a booth at reception: Fable's order puts the creator before the arrival, and the badge waiting at reception pays it off.
2. **Five introduced names** (Ruud, Sanne, Joost, Marco, Anouk); Rachid and Petra wait for the week (memory, rule 4).
3. **Monday holds one talk;** Sanne's moves to Tuesday, Rachid's becomes optional, Mieke's moves to Wednesday (§4.2). Reversible: if Merijn prefers the five-day schedule untouched, Anouk's talk can move to Monday's end *after* Sanne's and Rachid's daytime talks, and the opening loses "the first talk is Anouk".
4. **The first explainer is spanning/stroom/weerstand**, and it is the 2.7c spike (§4.6).
5. **The minimap appears as a paper plan from Ruud** and stays a site plan in style (2.1b).
6. **Ruud names the first move by text message** on Monday evening (he has gone home); in person from Tuesday.

## Sources

- Ohm's law (I = U/R) and power (P = U·I): any physics textbook; the kettle numbers are computed from them.
- Nominal low voltage 230 V ± 10 % in Dutch and European public grids: NEN-EN 50160 (*Spanningskarakteristieken in openbare elektriciteitsnetten*); Netbeheer Nederland and grid operators' public pages state 230 V. **(verify against a grid operator's own page)**
- Working memory of about four chunks: Cowan, N. (2001), *The magical number 4 in short-term memory*, Behavioral and Brain Sciences 24(1).
- 12 October 2026 is a Monday (`content/game.yaml`; checked).
