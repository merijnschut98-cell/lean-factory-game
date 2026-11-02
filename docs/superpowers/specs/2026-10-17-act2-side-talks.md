# Act II side talks: Petra and the silent meters, Wim Kortekaas and tab three

> Status: by the mission-and-dialog design agent (Claude, 2026-10-17). The D9 audit's third pass (T5) proposed this target and the coordinator assigned it. **Docs only, paste-ready.** The YAML below passed `python tools/build_content.py` and the route tool on the real engine (§3). It was tested in a scratch copy of `content/dialogs.yaml` and then reverted. Dutch game text, English notes.
>
> Read with: `content/missions.yaml` `fix_silent_meter`, `fix_inverters_tripping` (Act II sides); `content/problems_tier1.yaml` `silent_meter`, `inverters_tripping` (clues, causes, countermeasures); the voice sheets (four-tier audit §6); the person-needs spec; the D9 talks audit, whose rules apply here: no claims about the player, no repeated reveals, a way in that differs from the universal route.

## 0. Summary

| | Petra (`petra_silent_meters`) | Wim (`wim_spreadsheet`) |
|---|---|---|
| Mission | `fix_silent_meter` (side, Act II) | `fix_inverters_tripping` (side, Act II) |
| Person | Petra Vos, defender, need **facts** (exists) | **Wim Kortekaas**, new: retired electrical engineer, archetype **expert**, need **recognition** |
| The way in: interest | **the record or the other side** (`show_data`, `perspective`) | **a feeling under the irony** (`reflect`, `mood`) |
| The way in: concern | **a doubt** (`experience`, `show_data`) | **the record** (`show_data`, `perspective`) |
| What the player learns | listening opens Petra only so far: a facts person moves on her own numbers, and a doubt shrinks on a true story | questions about his data do not open an expert who has been right for three years; naming what the receipts did to him does |
| Countermeasures it leads toward (never names) | `on_site_comm_test` (the lampje), `coverage_check_in_planning` | `tap_review_per_neighbourhood` (the trafo), `smart_meter_voltage_data` |
| Route numbers | winnable, 221 distinct routes | winnable, 253 distinct routes |

**Neither talk is won by the tier-1 universal route** (`open_question empathy inquiry open_question paraphrase silence propose ask_commitment`), **nor by the content-wide best route** (15 of 31, §3). None of their four doors is a move that route uses. That was the brief: the defender-heavy route must not win them.

## 1. Design

**Petra again, but new.** She has had three talks already: the Molen on Thursday, the monthly run in Act I, the shame in `petra_after`. This one must not repeat them. Her worry here is new and follows from the last. The whole kantine knew that EANs sat with her for two weeks. Now her list shows a pattern that points at *how the monteurs place meters*, and she will not say it until it is in her map.
- **The lead-in** is the briefing's "Petra twijfelt".
- **Her interest** opens on the record (her own street pattern shown back) or on the monteur's side. She is a facts person.
- **Her doubt** is drawn out by a true story of the player's own (the training tray in their first week, which happens in every game), or by the numbers in black and white.
- **The universal route's silence** at the lead-in lands on her hesitation but draws nothing out.
- **The temptation** is the problem's plausible cause, a complaint to the supplier: "Dan sturen ze nieuwe meters. Die hangen dan in dezelfde kelders."

**Wim, the customer who is right.** Tier 1's customers so far are upset (mevrouw El Amrani, Ilse). Wim is a third kind: polite, thorough, retired after forty years in electrical engineering. He has sent a spreadsheet a month for three years and kept all thirty-six receipts. He needs **recognition**: not to be right, but for someone to look.
- **His interest** opens when someone names the feeling under his irony ("Het klinkt alsof u het gevoel heeft dat niemand ze leest."), or asks how he is.
- **Asking about his data**, the engineer's obvious move, lands but does not open him: he has told it thirty-six times.
- **His concern** comes out only on **our own data next to his** (the 254 V at quarter past one, the smart meters' quarter-hours) or on the monteur's side ("Hij kijkt alleen op het verkeerde uur.").
- **The temptation** is the one a call centre offers: retune his inverter to trip later. He refuses it as both not allowed and wrong ("de thermometer stukmaken omdat je koorts hebt").

**Correctness.**
- **253 V** is the upper limit (230 V + 10 %, NEN-EN 50160, as in the problem's clue 2). An inverter must disconnect above it, and raising its trip setting is not allowed, which is why Wim refuses.
- **The silent meters** follow the problem's root cause: a GPRS module chosen without a coverage check, in concrete cellar storage, and nobody testing the connection before the monteur leaves.
- **Wim's season:** Act II falls in winter, so he says "Het is winter … in maart begint het weer". The experiment fetches **last summer's** smart-meter data, which exists (clue 4).

**Nothing handed over.** Each concern unlocks one key clue, earned by listening. Petra's is the lampje: the meter shows its connection after a few minutes, by when the monteur has gone. Wim's is "kijk naar de hele straat tegelijk, en dan naar de trafo". Neither names a countermeasure. The proposals are about the person (Petra rides along; Wim sits next to someone with the trafo data), not about the fix.

**The D9 audit's rules, kept.**
- **No assumed moves:** no line assumes a move the player may not have made. The heard lines are "Je liet me het zelf zeggen" and "Ik wil alleen dat iemand kijkt".
- **One fixed date:** Wim's own measurement, last 14 June.
- **No forgotten appointments:** Petra's commitment is "de eerste ochtend dat er een monteur gaat", not a weekday.
- **True experience:** the player's experience line is the CI lead's own first week.
- **Openers:** they avoid the tier's crowded ones ("Afgesproken.", "Prima.", "Weet je wat"). Petra's ruined line is her voice sheet's "Dan vraag je het maar aan de Molen.", and her commitment opens with "Klopt.".

## 2. Content (paste)

**`people:`**: add after `ilse` (Petra exists already):

```yaml
  - id: wim
    name: Wim Kortekaas
    short: meneer Kortekaas
    role: bewoner Zonnestraat, gepensioneerd elektrotechnicus
    place: customer_contact.answer   # a customer; he comes to the ontvangst with his ring binder (cast), the KCC menu is the fallback
    team: contact_centre             # where his mails land; he is not on the team
    archetype: expert                # forty years in electrical engineering; right, polite, thorough
    need: recognition                # three years of spreadsheets answered by a receipt: he needs someone to look
    trust: 45                        # thirty-six receipts (estimate: a little below the default)
    morale: 50
    voice: "Het staat op tabblad drie."
```

**`dialogs:`**: append at the end:

```yaml
  # ── Petra en de zwijgende meters (Act II side, fix_silent_meter; spec 2026-10-17-act2-side-talks.md) ─────
  # The way in is the record and then a doubt: her interest opens to the data (her own pattern, confirmed)
  # or to the monteur's side; her concern is a doubt, drawn out by Ervaring delen or the numbers.
  - id: petra_silent_meters
    name: "Petra en de zwijgende meters"
    person: petra
    kind: persuade
    mission: fix_silent_meter
    owns: silent_meter
    mood: neutraal
    patience: 10
    opening: "Je komt voor de lijst. Hier. Tweeënveertig meters die niks zeggen. Ik heb ze per straat gesorteerd."
    warning: "Mijn lijst klopt. Daar hoef je niet over te beginnen."
    position: {text: "Iedereen zegt: de meters van de nieuwe leverancier deugen niet. Dat kan. Maar dan zou het overal zijn. Het is niet overal.", tags: [claim], tell: facts}
    layers:
      - id: interest
        at: 52
        via: [show_data, perspective]   # the record or the other side; listening alone does not open her pattern
        text: "De Lindeflats. De Kade. De Hofstede. Allemaal nieuwbouw, allemaal met de meterkast in een betonnen kelderberging. In de rijtjeshuizen heb ik er bijna geen."
        tags: [claim]
      - id: concern
        at: 66
        via: [experience, show_data]    # a doubt: a true story of the player's own, or the numbers in black and white, make it smaller
        lead_in: {text: "Ik weet het alleen niet zeker. En wat ik niet zeker weet, zeg ik liever niet.", tags: [hesitation, doubt]}
        text: "De vorige keer dat er iets bij Meetdata bleef liggen, wist de hele kantine het binnen een week. Als ik nu zeg dat het niet aan de meters ligt maar aan hoe we ze plaatsen, dan zegt Meetdata weer iets over de monteurs. En het staat nog niet in mijn map."
        tags: [admission]
        tell: facts
        unlocks:
          clue: {key: true, depth: 2, text: "'Het lampje op de meter zegt na een paar minuten of hij verbinding heeft. Maar dan is de monteur al weg. Niemand wacht erop.'"}
          facts: [heard:petra_meters]
          proposals: [petra_rides_along]
    data: [silent_meter:0, silent_meter:3]
    proposals:
      - id: supplier_complaint
        label: "Een klacht naar de leverancier"
        say: "We sturen een klacht naar de leverancier, met jouw lijst erbij."
        addresses: []
        reply: "Kan. Dan sturen ze nieuwe meters. Die hangen dan in dezelfde kelders."
      - id: list_by_address
        label: "De lijst per adres naast elkaar"
        say: "Zullen we je lijst naast de adressen leggen? Flat of rijtjeshuis, kelder of gang."
        addresses: [interest]
        reply: "Per adres. Dat kan ik vanmiddag. Dan staat het tenminste in mijn map."
      - id: petra_rides_along
        label: "Petra kijkt één ochtend mee bij het plaatsen"
        say: "Wat als jij één ochtend meegaat naar de Lindeflats? Jij en de monteur kijken samen naar dat lampje. Dan staat het in jouw map én in de zijne."
        hidden: true
        addresses: [concern]
        reply: "Samen kijken. Dan is het geen Meetdata tegen de monteurs. Dan is het gewoon gemeten. … Klopt."
    experiments:
      - id: one_street_two_weeks
        label: "Twee weken, één flat: wachten op het lampje"
        say: "Twee weken, één flat: de monteur wacht tot de meter verbinding heeft voordat hij wegrijdt. Jij houdt bij wat er gebeurt."
        addresses: [interest, concern]
        reply: "Twee weken. Dan heb ik het zwart op wit. Of niet. Dat is ook een uitkomst."
    co_proposal: {id: petra_rides_along, text: "Laat mij één ochtend met een monteur mee naar de Lindeflats. Hij plaatst, ik kijk naar het lampje. Dan zien we het allebei."}
    lines:
      perspective: "Hoe zou de monteur die bij de Lindeflats stond dit zien, denk je?"
      experience: "Mijn eerste week dacht ik dat de stapel bij Werkvoorbereiding aan Anouk lag. Het lag aan hoe de bakken stonden. Ik had het niet gezien als ik het niet had geteld."
    replies:
      show_data:
        lands: {text: "Drie op de tien in de flats. Eén op de twintig elders. … Dat had ik ook. Ik had het alleen nog niet opgeschreven.", tags: [claim], tell: facts}
        misses: {text: "Een gemiddelde over de hele regio. Daar zit het niet in."}
      perspective:
        lands: {text: "De monteur? Die plaatst, sluit de kast en rijdt door. Zo is het hem geleerd. Hij ziet nooit wat ik zie, een week later.", tags: [claim]}
      experience:
        lands: {text: "Geteld. Ja. … Ik heb het eigenlijk al geteld. Ik heb het alleen nog niemand laten zien."}
    outcomes:
      commitment: "Klopt. De eerste ochtend dat er een monteur naar de Lindeflats gaat, ga ik mee. Met de lijst. En mijn map."
      partial: "Ik wil het wel. Als het eerst per adres in de lijst staat."
      heard: "Hm. Je liet me het zelf zeggen. Dat was nodig, geloof ik."
      none: "Ik moet de lijst nog bijwerken."
      compliance: "Als je het zo wilt. Het komt in de map."
      ruined: "Dan vraag je het maar aan de Molen."

  # ── Wim en tabblad drie (Act II side, fix_inverters_tripping; spec 2026-10-17-act2-side-talks.md) ─────
  # The way in is a feeling and then the record: his interest opens when someone names what three years of
  # receipts feel like (or asks how he is); his concern comes out only on our own data, or the monteur's side.
  - id: wim_spreadsheet
    name: "Wim en tabblad drie"
    person: wim
    kind: persuade
    mission: fix_inverters_tripping
    owns: inverters_tripping
    mood: neutraal
    patience: 10
    opening: "Goedemiddag. Kortekaas, Zonnestraat veertien. U kent mij waarschijnlijk van de spreadsheets."
    warning: "Met alle respect: dit zei de vorige meneer ook."
    position: {text: "Elke maand stuur ik u mijn metingen. Elke maand krijg ik een ontvangstbevestiging. Zesendertig ontvangstbevestigingen. Ik heb ze bewaard.", tags: [claim, feeling], tell: recognition}
    layers:
      - id: interest
        at: 50
        via: [reflect, mood]            # a feeling under the irony: name it, or ask how he is
        text: "Het is winter, dus u denkt: nu heeft hij nergens last van. Maar in maart begint het weer. Op een zonnige middag gaat mijn omvormer uit. Tien minuten later aan. Dan weer uit. Bij de buren ook. Twintig adressen inmiddels."
        tags: [claim]
      - id: concern
        at: 66
        via: [show_data, perspective]   # the record: our numbers next to his
        lead_in: {text: "Ik heb het in 2023 al opgeschreven. Tabblad drie. Elke zonnige middag boven de tweehonderddrieënvijftig volt.", tags: [hesitation, claim], tell: recognition}
        text: "Mijn buren noemen me de zeur van de Zonnestraat. Twintig mensen klagen nu, en ze kijken allemaal naar mij. Ik heb veertig jaar in de elektrotechniek gewerkt. Heb ik het mis, dan ben ik een oude man met een spreadsheet. Heb ik het goed, dan heeft niemand drie jaar gekeken."
        tags: [admission]
        tell: recognition
        unlocks:
          clue: {key: true, depth: 2, text: "'Het is niet één huis. Kijk op een zonnige middag naar de hele straat tegelijk. En kijk dan naar de trafo, niet naar mijn omvormer.'"}
          facts: [heard:wim_spreadsheet]
          proposals: [wim_reads_the_data]
    data: [inverters_tripping:2, inverters_tripping:4]
    proposals:
      - id: retune_inverter
        label: "Zijn omvormer later laten afschakelen"
        say: "Wij betalen een monteur die uw omvormer zo instelt dat hij later afschakelt."
        addresses: []
        reply: "Dan gaat de spanning nog hoger, en mag dat niet eens. Dat is de thermometer stukmaken omdat je koorts hebt."
      - id: logger_one_week
        label: "Een week een meter in zijn meterkast"
        say: "We komen nog een keer meten. Een hele week, met een logger in uw meterkast."
        addresses: [interest]
        reply: "Een week. Bij mij. Dan heeft u één adres. Er zijn er twintig."
      - id: wim_reads_the_data
        label: "Zijn spreadsheet naast onze metingen"
        say: "Wilt u met een van onze netbeheerders naar de metingen van de hele straat kijken? Uw spreadsheet naast onze slimme meters."
        hidden: true
        addresses: [concern]
        reply: "Mijn tabblad naast uw metingen. … Daar zit ik al drie jaar op te wachten."
    experiments:
      - id: last_summer_street
        label: "De metingen van afgelopen zomer, de hele straat"
        say: "We halen de metingen van afgelopen zomer op: de hele Zonnestraat, elk kwartier, uit de slimme meters. U krijgt de grafiek."
        addresses: [interest, concern]
        reply: "Elk kwartier. De hele straat. … Dan hoeft u mijn spreadsheet niet eens meer te geloven."
    co_proposal: {id: wim_reads_the_data, text: "Laat me één middag naast iemand zitten die bij de gegevens van de trafo kan. Ik neem mijn laptop mee. En ik beloof dat ik niet zeg dat ik het al wist."}
    lines:
      mood: "Hoe gaat het met u, met al die spreadsheets?"
      reflect: "Het klinkt alsof u het gevoel heeft dat niemand ze leest."
      perspective: "Hoe zou de monteur die bij u kwam meten dit zien, denkt u?"
      paraphrase: "Dus u stuurt al drie jaar uw metingen, en u krijgt alleen een bevestiging terug."
    replies:
      open_question:
        lands: {text: "Wat er gebeurt? Zevenentwintig keer afgeschakeld op 14 juni. Het staat erin, per minuut.", tags: [claim], tell: recognition}
      reflect:
        lands: {text: "Leest. Nou. Ze worden ontvangen. Dat staat er elke keer bij.", tags: [feeling]}
      show_data:
        lands: {text: "Tweehonderdvierenvijftig volt, om kwart over één. … Dat is mijn getal. Dat is precies mijn getal.", tags: [claim]}
        misses: {text: "Een daggemiddelde. Daar zit het niet in. Het zit in de middag."}
      perspective:
        lands: {text: "De monteur? Die meet bij mij om tien uur 's ochtends. Dan is er niks. Hij doet zijn werk goed. Hij kijkt alleen op het verkeerde uur.", tags: [claim]}
    outcomes:
      commitment: "Dan neem ik mijn laptop mee. En een verlengsnoer; die hebben jullie hier vast niet."
      partial: "Ik stuur de spreadsheet nog één keer. Als iemand hem deze keer opent."
      heard: "Dank u. Ik hoef geen gelijk. Ik wil alleen dat iemand kijkt."
      none: "Ik mail u tabblad drie nog even."
      compliance: "Goed. Dan wacht ik weer op de ontvangstbevestiging."
      ruined: "Dan stuur ik volgende maand weer een spreadsheet. En de maand daarna."
```

### 2.1 Outside `dialogs.yaml` (world agent, D9 builder)

- **Wim needs a body** (the third pass's rule: every talk's person has a body or a place in a room). Cast entry: the ontvangst on the begane grond, `missions: [fix_inverters_tripping]`, pose `talk`, a ring binder under his arm; a retired engineer brings his printouts in person. The KCC menu (`customer_contact.answer`) is the fallback, as for mevrouw El Amrani. One line in the briefing: "Hij staat beneden bij de ontvangst, met een ordner."
- **Petra** is at her Meetdata desk already; the room is open by Act II.
- **Wim's need** goes into the person-needs spread (N7): tier 1 had three recognition people (Sanne, Mieke, Henk), and he makes four, under the cap.

## 3. Verified on the engine

Inserted into a scratch copy of `content/dialogs.yaml` (on top of `bc42d1f` + `1e04a99`), then reverted.

- **`python tools/build_content.py` passes.** Its rules shaped three details:
  - every layer needs two ways in, so Petra's concern got `show_data` beside `experience`;
  - a concern's lead-in must carry a hesitation or a feeling, so they are `[hesitation, doubt]` and `[hesitation, claim]`, as Rob's and Mieke's are;
  - two proposals or experiments must address the concern (the "no single right answer" rule), so both experiments address it.
- **The route tool on all of content** (`godot --headless --path game --script res://tools/route_check.gd`, width 300, 302 s):
  - `petra_silent_meters` is winnable, by 221 distinct routes;
  - `wim_spreadsheet` is winnable, by 253;
  - the content-wide best route wins 15 of 31 (48 %), neither of these among them.
- **The `tier1` run stays at 9 of 20.** It measures the Acts 0–II scripts' set, which the ratchet counts and which does not include side talks.
- **Starts:** Petra 41 (defender), Wim 59 (expert: warm and polite). Wim's openness alone does not open him; the doors do.
- **After pasting:** check `TIER1_RATCHET`. It should be unchanged, since these two talks are outside its set.

## 4. Scores (the quality bar)

| | Real | Entertaining | Intriguing | Challenging | Draws in | Intuitive | Correct | /35 |
|---|---|---|---|---|---|---|---|---|
| `petra_silent_meters` | 5 | 4 | 4 | 4 | 4 | 4 | 5 | **30** |
| `wim_spreadsheet` | 5 | 5 | 4 | 4 | 5 | 4 | 5 | **32** |

The dialog checks pass for both:
- a real person;
- a readable meter;
- progress without a golden path (200+ routes, none universal);
- no sign a player would quit here.

Wim is the warmest talk in tier 1: being heard after three years of being right is its own reward. It is the respect-for-people principle as a scene.

## 5. Claude's calls (for PLAN §10)

1. **Wim Kortekaas is an `expert` with a recognition need**, and he comes to the ontvangst with a ring binder.
2. **The ways in avoid the universal route by design**: Petra opens on the record and then a doubt, Wim on a feeling and then the record.
3. **Petra's concern is new**: after the kantine knew about the EANs, she will not point at the monteurs until it is in her map.
