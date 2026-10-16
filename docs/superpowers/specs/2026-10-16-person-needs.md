# Person needs and moves that wear out: the content side of PLAN 1.6c

> Status: by the mission and dialog design agent (Claude, 2026-10-16), PLAN 1.6c, Merijn's decision of 2026-10-16 on the golden route ("if E1–E5 fall short, build both"). **Docs only.** The builder builds the engine side in parallel (constants and tests in `rules/dialog.gd` and `rules/people.gd`); this doc is the content those constants act on, and the contract where the two meet (§6).
>
> Read with: CLAUDE.md §2 (MORE PIES; nothing handed over; respect for people; immersion); PLAN §4.3 and 1.6c; the dialog spec §3.3 (moves and Δ), §3.5 (patience), §3.6 (mood, archetype weights), §3.7 (meter); the four-tier audit §4.4 (the route simulator, E1–E5), §6 (voice sheets), §7 (T1–T11); the Act 0 tutorial talks; `content/dialogs.yaml`.

## 0. Summary

- **Why.** With the spec's numbers one fixed listening route wins every persuasion talk (audit §4.4). E1–E5 cut that to about half in tiers 1–2, not in tiers 3–4. The archetype weights alone cannot break it: there are eight archetypes, and a player learns eight routes. Real people differ in what they *need* from a conversation, and that is what a good listener reads first.
- **The need.** Every person carries one hidden `need`: **facts** (feiten) · **safety** (veiligheid) · **recognition** (erkenning) · **time** (tijd) · **fairness** (eerlijkheid). It multiplies how each move lands (§1.2), and the person's mood sharpens or softens it (§1.4). Across the five needs the best opening move differs: inquiry, empathy, paraphrase, mood, open question (§1.3).
- **The read.** The need is never shown. The person shows it in *tells*: lines in their own voice, tagged in content (§1.5). The Mensen tab collects what the player saw and heard; it never names the need (§4).
- **Wear-out.** A move type used too often in one talk loses force, and the person says so in character, with two lines per archetype (§3).
- **Who needs what.** All 29 speaking people of the four tiers, spread so that no need holds more than a third of a tier's speaking cast and every tier meets all five (§2).
- **Acceptance.** The route test (T6) stays the acceptance test. New tests N1–N8 cover the rest; the main one: for each need, a real talk where a different first move is best (§5).

All numbers here are **estimates** chosen for play, with their reasoning; the builder tunes them against T6 and records the tuned values in this doc.

---

## 1. The five needs

### 1.1 What each need is

A need is what the person must get from the talk before they open up. It is not a flaw, and it is not the archetype. The archetype is how someone defends (a defender holds their position, a cynic tests you). The need is what the defence protects. Two defenders with different needs open to different moves: Joost (safety) needs to know it will not land on his name; Petra (facts) needs to know you looked properly. Problems live in the process, never in the person, and a need is a person's reasonable response to their process (CLAUDE.md §2).

| Need | Dutch (internal only, never on screen) | What the person responds to | What falls flat | Typical root in the process |
|---|---|---|---|---|
| **facts** | feiten | precise questions about their numbers; a summary that gets the details right; data they can check | comfort without content ("Dat is ook niet niks"); questions about how they feel | they are judged on numbers, so vagueness feels like a trap |
| **safety** | veiligheid | being told it is not about blame; a small true story from someone who also struggled; small, reversible steps | being questioned before they feel heard (it sounds like an audit); data about their work early on | a predecessor moved after one bad quarter; a name on a damage claim; being watched with a stopwatch |
| **recognition** | erkenning | hearing their work said back in their own terms; room to tell what they know | the player's own stories; numbers that replace what they know; generic comfort | their knowledge is invisible ("het postkantoor", "overtekenen") until something goes wrong |
| **time** | tijd | being seen as someone short of time; short summaries; one small concrete step | broad open questions ("Hoe ziet jouw week eruit?"); long silences; the player's stories | overload: a full plan, a shift pattern, a queue that never ends |
| **fairness** | eerlijkheid | open questions that let them tell what is unjust; looking through the eyes of the others involved; naming the feeling of injustice | sympathy without action (it sounds like pity); being asked how they feel instead of what happened | one team carries the cost of another's step; promises from earlier programmes were broken |

### 1.2 How moves land per need (multipliers, estimates)

The multiplier applies to the **landing** Δ of a move (the dialog spec §3.3 "Lands" column, after E1–E5), exactly as the archetype weights do. It never touches a miss, a cost, pressure or blame: a weak move for this person still helps a little, and nothing becomes a trap.

| Move | facts | safety | recognition | time | fairness |
|---|---|---|---|---|---|
| `mood` Stemming peilen | ×0.5 | ×1.0 | ×0.75 | **×1.5** | ×0.75 |
| `open_question` Open vraag | ×0.75 | ×1.0 | ×1.25 | ×0.5 | **×1.5** |
| `reflect` Gevoel benoemen | ×0.75 | ×1.25 | ×1.0 | ×1.0 | ×1.25 |
| `empathy` Begrip tonen | ×0.5 | **×1.5** | ×0.75 | ×1.0 | ×0.5 |
| `paraphrase` Samenvatten | ×1.25 | ×1.0 | **×1.5** | ×1.25 | ×1.0 |
| `inquiry` Doorvragen | **×1.5** | ×0.5 (×1.0 once `heard`) | ×1.0 | ×0.75 | ×1.0 |
| `experience` Ervaring delen | ×0.75 | **×1.5** | ×0.5 | ×0.5 | ×1.0 |
| `silence` Stilte laten | ×1.0 | ×1.0 | ×1.0 | ×0.5 | ×1.0 |
| `perspective` Ander perspectief | ×1.0 | ×0.75 | ×0.75 | ×1.0 | **×1.5** |
| `show_data` Data laten zien | **×1.5** | ×0.5 | ×0.75 | ×1.0 | ×1.0 |
| `propose_experiment` Experiment voorstellen | ×1.0 | ×1.25 | ×1.0 | **×1.5** | ×0.75 |
| `propose`, `ask_commitment`, `repair`, `close` | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |

**Reasoning (estimates).**
- Each need has one or two strong moves (×1.5), one or two leaning moves (×1.25) and two or three weak ones (×0.5–0.75), so the spread between the best and the worst move for a person is about ×3. That is enough to change the best route without making any move useless.
- The pattern follows the MORE PIES literature on adapting to the listener: people who expect scrutiny want precision (facts); people under threat need safety before inquiry (psychological safety, Edmondson 1999); people whose expertise is unseen open when it is named (recognition); people under time pressure want brevity; people with a sense of injustice want to be asked what happened (procedural justice, Tyler & Lind 1992).
- **Safety's one exception.** For a safety person, inquiry before `heard` feels like an audit (×0.5); once they feel heard, the same question is curiosity (×1.0). This keeps the tutorial's "first summarise, then dig" route true for Joost (§7 of the tutorial talks).
- **Combining with the archetype:** `landing Δ × archetype weight × need weight`, with the combined factor clamped to **×0.25–×2.0**. Example: Frank (rule_bound, facts) on `show_data`: 1.5 × 1.5 = 2.25 → ×2.0.

### 1.3 The best first move, per need

The first move is where reading the person pays most. Measured with the spec's Δ and E1 (empathy +8 in the first two moves), a defender at mood `neutraal` whose position is a claim, interest within 15:

| Need | mood | open_question | paraphrase | inquiry | empathy | Best first move |
|---|---|---|---|---|---|---|
| facts | 4 | 4.5 | 8.75 | **12** | 4 | Doorvragen |
| safety | 8 | 6 | 7 | 4 | **12** | Begrip tonen |
| recognition | 6 | 7.5 | **10.5** | 8 | 6 | Samenvatten |
| time | **12** | 3 | 8.75 | 6 | 8 | Stemming peilen |
| fairness | 6 | **9** | 7 | 8 | 4 | Open vraag |

(`reflect`, `silence` and `experience` are not opening moves: they need a feeling, a hesitation or a doubt first. A fairness person whose position carries a feeling opens best to `reflect`: 10 × 1.25 = 12.5.)

### 1.4 How mood shifts the need

Mood decides how strongly the need shows that day. One rule, as a constant table:

`need weight today = 1 + (need weight − 1) × k`, with **k = 1.5** at `gespannen` (the need sharpens), **k = 1.0** at `goed` and `neutraal`, **k = 0.5** at `moe` and `stil` (the need softens: tired or quiet people first need to be seen at all, which the archetype and the mood move already carry).

So a tense facts person takes empathy at ×0.25 and inquiry at ×1.75; a tired one at ×0.75 and ×1.25.

| Need | Under `gespannen` (sharper), in character | Under `moe` / `stil` (softer), in character |
|---|---|---|
| facts | wants it in writing: "Zwart op wit graag. Dan praten we verder." | lets the numbers go: "Ik weet het precieze getal even niet. Het is veel." |
| safety | every question sounds like an audit: "Waarom wil je dat weten?" | more open to a kind word: "Sorry. Ik ben gewoon moe." |
| recognition | sarcasm about being unseen: "Nee hoor, wij stempelen alleen." | wants to be seen as a person, not for the work: "Het gaat niet eens om het werk." |
| time | shorter: "Kort." | slowing down is suddenly welcome: "Weet je wat, ga even zitten." |
| fairness | anger at the injustice: "Dat is gewoon niet eerlijk, en iedereen weet het." | resignation: "Het is altijd zo geweest. Het blijft ook zo." |

### 1.5 Tells: how an attentive player reads the need

A **tell** is a line in the person's own voice that shows the need without naming it. In content a line object carries `tell: <need>` (§6). Rules:

1. Every persuasion talk shows **at least one tell in its first two lines** (the position or the first reply), and every person has **at least three tells** across their talks once they are in content.
2. A tell matches the person's need (or the dialog's `need` override). A line that only *looks* like another need (Joost's numbers are armour, not a need for facts) is simply not tagged.
3. Tells are in the voice sheet's words (audit §6), never a formula: two people with the same need do not share a tell line.
4. Walk-around barks (people at their desks, 1.3) may carry tells too; a tell heard in passing enters the Mensen tab like one heard in a talk.

Examples per need (generic; each person's own tells are written in their voice when their talks enter content):

| Need | Example tells (Dutch, in character) |
|---|---|
| facts | "Hoeveel precies? 'Veel' zegt mij niks." · "Is dat gemeten, of gevoeld?" · "Dat staat in mijn map. Wil je het zien?" · "Noem eens een getal, dan kan ik er iets mee." |
| safety | "Komt dit ergens in een rapport?" · "Sorry. Ik weet niet of ik dit hoor te zeggen." · "Wie krijgt dit allemaal te zien?" · "Als het misgaat, staat mijn naam erop." |
| recognition | "Ze denken boven dat het overtekenen is." · "Vijftien jaar doe ik dit. Niemand heeft het ooit gevraagd." · "Weet je hoeveel werk erin zit? Nee, natuurlijk niet." · "Het valt pas op als het misgaat." |
| time | "Zeg het maar. Ik heb twee minuten." · "Kort graag, ik moet zo weer omplannen." · "Kan dit ook in een mailtje?" · "(kijkt op de klok) Sorry. Ga door." |
| fairness | "Waarom moeten wij dat altijd oplossen?" · "Ze hebben een contract. Dat is hun recht." · "Bij Intake mag het wel, en bij ons niet?" · "Iedereen krijgt een eerlijke datum, behalve wij." |

---

## 2. A need for every person

### 2.1 The rule for assigning a need

- The need follows the person's **hidden worry** in the voice sheet (audit §6) and their concern lines, not their surface. The surface is the archetype; the worry is the need.
- **Spread:** within a tier's speaking cast, no need holds more than ⌈n/3⌉ people, and every need appears at least once when the cast is five or more. No archetype maps to one need (both rule-bound people differ, the six defenders spread over four needs).
- A dialog may override the need for one scene (`need:` with a `need_reason:` comment), like a scene mood. Rare; none is proposed today.
- **The need is constant.** People change their trust, mood and morale, not who they are. A player who learned Petra in Act I still knows her in Act III.

### 2.2 Assignments

Tiers as in the audit: 1 = Acts 0–II, 2 = Act III, 3 = Acts IV and VI, 4 = Act V. Archetypes as in the drafts.

| Person | Archetype | Tiers | Need | Why (one sentence) |
|---|---|---|---|---|
| **Ruud Hoekstra** | mentor (two talks) | 2, 4 | facts | A Kata coach wants what you *saw*, not what you feel: "Wat zie je?" is his whole method, and he softens only for something you observed yourself. |
| **Frank Hulshof** | rule_bound | 1–4 | facts | He has to "verantwoorden" every number to the directie and the ACM, and "Ik ga niet op gevoel een kwartaal gokken" is his concern in one line. |
| **Joost van Dijk** | defender | 1, 3 | safety | His predecessor moved to Inkoop after one bad quarter; his numbers are armour, and what he needs is to know it will not land on his name. |
| **Sanne Bakker** | overloaded | 1, 2, 4 | recognition | Fifteen years of knowing which applications come back, and "niemand vraagt het me": Intake is "het postkantoor". |
| **Marco Peters** | cynic | 1–3 | fairness | The 2012 programme took his monteurs' hours and left; he promised them "never again", and "wie bouwt dat na?" is a question about who pays. |
| **Anouk de Vries** | overloaded | 1, 4 | safety | She works till seven so nobody sees she is "slow"; being watched with a stopwatch is her fear, not the workload itself. |
| **Henk Verbeek** | craftsman | 1 | recognition | Forty years of craft that might end as "a video nobody watches"; he opens when his way of knowing is named. |
| **Ahmed Bouzid** | quiet | 1, 3, 4 | safety | He calls a retiree at two in the morning and is ashamed of it; he needs to hear that not knowing is allowed. |
| **Esra Yilmaz** | defender | 1–3 | fairness | Her agents take the anger for errors made elsewhere; "gewoon eerlijk" is her own word. |
| **Petra Vos** | defender | 1, 2 | facts | "Dat staat in mijn map", "klopt": she trusts what has been checked, and opens to someone who looked properly at her batch. |
| **Femke de Wit** | craftsman | 1, 2, 4 | time | Thirty-eight studies on the board; she talks "kort gezegd" and draws to save words, and a concrete small step wins her over a broad question. |
| **Thomas Visser** | defender | 1, 3, 4 | fairness | "Ze hebben een contract. Dat is hun recht": taking capacity from customers he has known for twenty years is a question of what is fair to them. |
| **Mieke van der Veen** | craftsman | 1, 4 | recognition | "Je bent de eerste die het niet 'overtekenen' noemt": her trade is invisible until a cable is cut. |
| **Linda Jansen** | overloaded | 1, 2 | time | She re-plans all day and in the evening; "omplannen" in every other sentence, and every minute you take is one she re-plans later. |
| **Dirk Smits** | defender | 1, 2 | fairness | The warehouse is blamed for vans that were never restocked; "dan moeten ze ze komen halen" is about who carries whose work. |
| **Gert Peeters** | defender | 1, 2 | safety | His crew's safety (he saw a man fall after an MS flash) and his family name on a damage claim come before any map. |
| **Mevrouw El Amrani** | customer_upset | 1, 3 | facts | Dates from her notebook, and "een datum, een echte": sympathy without a date makes it worse, which turns her archetype's empathy weight around. |
| **Kees Mulder** | craftsman | 2–4 | facts | The control room only ever sees the light come back, never why it went; he opens to someone who wants to know the cause. |
| **Ruben Smulders** | craftsman | 2 | time | Sleeping in blocks of three hours as a young father on call; his scarce thing is rest, and "Dus ik moet gewoon harder" is what a time-starved person says. |
| **Wendy de Bruijn** | craftsman | 2, 3 | recognition | Twenty-eight years of shifts and "een overdracht is een verhaal": she resists forms that say operators could not do it. |
| **Ingrid Bos** | expert | 3, 4 | recognition | The quiet one who warned about 2012's dashboard and was not heard; in a group talk she opens when what she said back then is named. |
| **Monique de Ruiter** | rule_bound | 3, 4 | fairness | Every euro of the network tariff is paid by all customers, and "de vorige keer" a plan missed: she guards what is fair to the payer, not only the number. |
| **Noor Hendriks** | defender | 3, 4 | time | She lives in sprints and refinements ("Donderdag…"); a talk competes with the next ceremony, and a small concrete experiment fits her week. |
| **Mark van Leeuwen** | quiet / defender | 3, 4 | time | Pairing all day and cleaning up at night, after one burn-out: his need is time back, and he answers best to brevity. |
| **Lotte Smit** | defender | 4 | fairness | The external hire who knows she sits where someone developed should have sat: she wants to be judged on her work, not on where she came from. |
| **Rachid Ouali** (tutorial) | quiet | 1 | fairness | Four months at Intake, and errors made by installers come back "met mijn naam erop"; he would never say it is unfair, so he says it sideways. |
| **Rob Verhagen** (Acts 0–II) | rule_bound | 1 | safety | An audit in 2022 named him for two 630 kVA transformers; "conform de procedure" is his shelter. |
| **Ilse de Graaf** (Acts 0–II, customer) | customer_upset | 1 | time | "Ik sta hier om vier uur", two years on the list: her ovens and her hours are the clock she lives by. |

(Joost, Frank and Ahmed are the three people already in `content/dialogs.yaml`; the rest enter with their tiers.)

### 2.3 The spread per tier

| Tier | Speaking cast in scope | facts | safety | recognition | time | fairness | Limit ⌈n/3⌉ |
|---|---|---|---|---|---|---|---|
| 1 (Acts 0–II) | 19 | 3 (Frank, Petra, El Amrani) | 5 (Joost, Anouk, Ahmed, Gert, Rob) | 3 (Sanne, Henk, Mieke) | 3 (Femke, Linda, Ilse) | 5 (Marco, Esra, Thomas, Dirk, Rachid) | 7 |
| 2 (Act III) | 13 | 4 (Ruud, Frank, Petra, Kees) | 1 (Gert) | 2 (Sanne, Wendy) | 3 (Femke, Linda, Ruben) | 3 (Marco, Esra, Dirk) | 5 |
| 3 (Acts IV, VI) | 13 | 3 (Frank, Kees, El Amrani) | 2 (Joost, Ahmed) | 2 (Wendy, Ingrid) | 2 (Noor, Mark) | 4 (Marco, Esra, Thomas, Monique) | 5 |
| 4 (Act V) | 14 | 3 (Ruud, Frank, Kees) | 2 (Anouk, Ahmed) | 3 (Sanne, Mieke, Ingrid) | 3 (Femke, Noor, Mark) | 3 (Thomas, Monique, Lotte) | 5 |

People who speak in one tier only (tier 2's Inge, Koen, Nicole, Brouwer, Van Dalen; tier 3's Joke, Yusuf, Hermans, Aziz and others; tier 4's Theo, Harrie, Tim, Rianne) get their need when their tier enters content, by the same rule, so the counts above stay inside the limit (content test N7). Tier 2 is light on safety today: Koen ("answering fast and wrong") and Nicole (the monteur in hospital) are the natural safety people there.

---

## 3. Moves that wear out

### 3.1 The rule (content side)

The builder sets the numbers (PLAN 1.6c: the third use of one move type in a row lands at a fraction; audit E4: ×0.7 a second time in a talk, ×0.4 a third). The content gives the person a voice for it: the **first time in a talk** that a move type's wear factor reaches ×0.5 or lower, the person answers with their archetype's wear-out line instead of the move's reply. The Δ is the worn one; the line is said once per move type per talk. A person's dialog may override it (`replies.<move>.worn`) for a line in their own voice.

- **Questions** (`mood`, `open_question`, `inquiry`) use the `ask` line.
- **Statements** (`reflect`, `empathy`, `paraphrase`, `experience`) use the `say` line.
- **`silence`** keeps its miss line ("… Was er nog iets?"): silence that wears out sounds like silence, not like a remark.
- The line replaces the spec's generic `special.repeat` ("Dat vroeg je net ook.") wherever a wear-out line exists; `special.repeat` remains the fallback.
- Wear-out applies in tutorial talks too: Act 0 is where the player should first hear it, at no cost.

### 3.2 The lines, per archetype

```yaml
bank:
  wear_out:                          # PLAN 1.6c; once per move type per talk, when its wear factor first reaches <= 0.5
    defender:
      ask: "Je vraagt het nu op drie manieren. Het antwoord blijft hetzelfde."
      say: "Ja. Dat zei je al. Ik hoef mezelf niet terug te horen."
    cynic:
      ask: "Staat dat ook zo in de cursus? Drie keer dezelfde vraag?"
      say: "Hm. Dit is de techniek, toch? Herhalen tot ik ja zeg."
    craftsman:
      ask: "Dezelfde vraag, andere woorden. Kom liever kijken, dan zie je het."
      say: "Je zegt het nu voor de derde keer. Ik geloof je wel, hoor."
    overloaded:
      ask: "Sorry, maar dit vroeg je net. Ik heb echt niet veel tijd."
      say: "Ja. Ja. Dat weet ik nou wel. Wat wil je eigenlijk?"
    rule_bound:
      ask: "Die vraag is gesteld, en beantwoord. Wat is het volgende punt?"
      say: "Dit punt hebben we gehad. Laten we verdergaan."
    quiet:
      ask: "… Dat vroeg je al."
      say: "Mm. Ja. Dat zei je."
    customer_upset:
      ask: "Dit heb ik nu twee keer verteld. Mag ik ook eens iets vragen?"
      say: "Dat zei u al. Ik hoef geen begrip, ik wil weten wat er gebeurt."
    expert:
      ask: "Die vraag hadden we. Wil je een andere kant op?"
      say: "Klopt, zo zei ik het. Zullen we verder?"
    mentor:
      ask: "Je stelt me mijn eigen vraag terug. Goed geleerd. Wat wil je nu echt weten?"
      say: "Je herhaalt me nu. Wat zie je zelf?"
```

Voice check (audit §6, T8): no line uses a person's signature opener ("Klopt." stands mid-line for experts only, never as an outcome opener; no "Afgesproken", "Zie je", "Prima"). The customer line keeps "u" (customers say "u" to the player); the rule-bound lines avoid a pronoun, because Frank says "je" and Rob "u".

---

## 4. The Mensen tab: what the player has learned, never the need

The Mensen tab (journal, 1.2) shows per person what the player has **seen and heard**. The reading is the player's own.

**On each person's page:**
1. **Header** (as designed): portrait, name, role, place, trust pips, today's mood word, the morale band.
2. **"Wat {naam} je vertelde"**: in the order the player heard them, the revealed layers (interest, concern; already in the design) **and the tell lines** the player has seen, each as a quote with the day and place ("di 13 okt · Werkvoorbereiding"). A line enters once, when it is shown in a talk or heard as a walk-around bark. Up to eight, newest first; older ones fold under "Eerder". The quotes are not grouped, sorted or coloured by need, and tells are mixed with the layers, so the list reads as a notebook, not a diagnosis.
3. **"Jullie gesprekken"**: each talk's date, outcome label, the openness sparkline and the moves under it (UI audit U7). The player's own record of what landed (▲▲) and what barely did (▲), with no summary of "what works".
4. **"Jouw notitie"**: an optional free-text field ("Wat weet je over {naam}?"), the player's own reading in their own words. Never read by the rules, never judged, kept in the save (like the act-end terugblik, PLAN §4.2.6).

**Never on screen, in any act:** the need's id or Dutch name; an icon, colour or tag per need; a "werkt goed bij" or "beste aanpak" line; a ranking or percentage per move; a highlighted chip. Ruud never names a need either (he did not name moves after Act 0; he never names needs at all). His Kata questions already point at reading: K3 "Wat houdt {person} tegen, denk je? Hoe weet je dat?", and the tutorial's "Wat zag je aan {person} toen je begon?".

**A hidden reward for reading** (proposal for D8, with the discoveries D29–D34): **D35 "Mensenkenner"**: five talks with five different people, each opened with the best first move for that person (by the engine's own reckoning, §1.3), covering at least four needs. Reward: a title, and Ruud's line "Je luistert niet harder. Je kijkt eerst wie er zit." Guard: four needs, so learning one person does not earn it.

---

## 5. Acceptance tests (for the builder)

**The route test stays the acceptance test** (T6, audit §7): with needs on, and with wear-out on if it is built, no fixed sequence of moves wins more than half of a tier's persuasion talks, run on `rules/dialog.gd` itself (a headless Godot test), per tier as each tier enters content. Plus:

| # | Test | Fails when |
|---|---|---|
| N1 | **Each need has a talk where a different first move is best.** On real content, at the stated mood, the listening move with the largest first Δ (the engine's own reckoning) is: `frank_kpi_targets` (facts, neutraal) → `inquiry` · `joost_output_kpi` (safety, gespannen) → `empathy` · `sanne_kpi` (recognition, neutraal) → `paraphrase` · `linda_replanning` (time, moe) → `mood` · `marco_wasted_trips` (fairness, neutraal) → `open_question`. Until those talks are in content, the same five as fixtures (defender, neutraal, position a claim, interest within 15, start 40), one per need. | any of the five differs, or two needs share a best first move |
| N2 | **The need, not the talk, decides it.** One fixture talk, played with each of the five needs in turn: the best first move changes with the need, and nothing else in the talk changes. | the best first move is the same for two needs |
| N3 | **No trap.** Every landing move still lands (Δ > 0) for every need, mood and archetype (combined factor ≥ ×0.25). | a landing Δ becomes ≤ 0 through a need |
| N4 | **Every talk stays winnable.** T7 (≥ 3 distinct winning sequences) on every persuasion talk with needs and wear-out on; every tutorial talk still has a route without the day's move and cannot be ruined. | a talk falls below 3 routes, or a tutorial talk can be ruined |
| N5 | **Tells are honest.** Validator: a `tell` equals the person's need (or the dialog's override); every persuasion talk shows a tell in its position or first authored reply; every person in content has ≥ 3 tells once all their tier's talks are in. | a mismatched tell; a talk without an early tell; a person with fewer than 3 |
| N6 | **The need is never shown.** A UI test renders the Mensen tab, the talk panel and the summary card for each need: none contains the need ids or the labels "feiten", "veiligheid", "erkenning", "tijd" or "eerlijkheid" as a label (quotes from the person may contain the words). | any label leaks |
| N7 | **Spread.** Per tier's speaking cast in content: no need above ⌈n/3⌉; all five present when n ≥ 5; every person with a dialog has a `need`. | as stated |
| N8 | **Wear-out has a voice.** `bank.wear_out` has `ask` and `say` for every archetype in `dialog_archetypes`; the line shows exactly once per move type per talk, at the first use whose factor is ≤ 0.5; `silence` keeps its miss line. | a missing archetype, a repeated line, a line on silence |

The route counts from the audit's simulator (50 % / 53 % / 68 % / 82 % with E1–E5) are the baseline. Needs should bring tiers 3–4 under half because the talks there are alike in shape but not in people: the same route now meets five different first moves. That is an expectation, not a measurement; the builder's T6 run decides, and records the numbers here.

---

## 6. The contract with the engine

| Key / constant | Where | Meaning |
|---|---|---|
| `need` | `content/dialogs.yaml` `people[]` | One of `facts`, `safety`, `recognition`, `time`, `fairness`. Required for every person with a dialog. |
| `need`, `need_reason` | a dialog (optional) | A one-scene override, with the reason as a comment. |
| `tell` | any line object (`position`, a layer's `text`/`lead_in` object, `replies.<move>.<case>`) | The need this line shows. Validator N5. Not on `opening` (a plain string); put the tell in the position. |
| `bank.wear_out.<archetype>.ask` / `.say` | bank | §3.2. |
| `replies.<move>.worn` | a dialog (optional) | The person's own wear-out line for that move. |
| `NEED_WEIGHTS` | `rules/dialog.gd` | The table in §1.2, plus safety's `inquiry` ×1.0 once `heard`. |
| `NEED_MOOD_K` | `rules/dialog.gd` | `gespannen` 1.5 · `goed` 1.0 · `neutraal` 1.0 · `moe` 0.5 · `stil` 0.5 (§1.4). |
| `WEIGHT_MIN`, `WEIGHT_MAX` | `rules/dialog.gd` | 0.25 and 2.0, the clamp on archetype × need. |
| `People.observed` | `rules/people.gd`, saved | Per person, the tell lines seen (dialog id, line key, day, place), for the Mensen tab. |
| `People.note` | `rules/people.gd`, saved | The player's free-text note per person (§4). |

---

## 7. Claude's calls (for PLAN §10)

1. **Five needs with fixed multipliers**, one strong opening move each; the multiplier acts on landings only, so no move becomes a trap.
2. **Safety's exception:** inquiry recovers once the person feels heard. It keeps "first summarise, then dig" true, and it is how a defensive person actually behaves.
3. **Mood scales the need** (sharper when tense, softer when tired) with one constant, rather than a table per need and mood.
4. **The need is constant per person**; a dialog may override it for one scene with a reason.
5. **The Mensen tab shows quotes, talks and the player's own note**, never a label; tells are mixed with the revealed layers so the page reads as a notebook.
6. **Wear-out lines per archetype**, split into a question line and a statement line; silence keeps its own miss.
7. **Rachid is fairness, not safety**, so that the tutorial week meets all five needs (see the tutorial talks §7).
8. **D35 "Mensenkenner"** as a hidden reward for reading people, guarded by four needs.
