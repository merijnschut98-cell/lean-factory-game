# Dialog scripts, Acts 0–II — audit and content-ready drafts

> Status: written by the mission and dialog design agent (Claude, 2026-10-15), for Merijn to review. **Docs only:** nothing in `content/` or `game/` changes here. A builder agent turns these blocks into `content/people.yaml`, `content/dialogs.yaml` and `content/dialog_lines.yaml` once the dialog engine (dialog spec §13, D1–D3) exists.
>
> Read with: `CLAUDE.md` §2 (the 7 mission criteria; "Reward deep thinking"; "Dialogs are give and take"); PLAN.md "Decisions Made" (the visible meter, commitment versus compliance); the dialog spec `2026-10-15-dialog-system-design.md` (the engine, the schema of §9.1, the cast of §6); the mission catalogue `2026-10-15-mission-system-and-catalogue-design.md`; the audit `2026-10-15-mission-audit-and-engagement.md` (§3 rewrites, §5.3 cast); the tier-2 draft `2026-10-15-tier2-missions-draft.md` (§4 people topics); `content/problems_tier1.yaml` (clue ids used below) and `content/kpis.yaml` (KPI ids).

## 0. Summary

- **Audit of the two sample dialogs (§3).** Both are strong in voice and in their Lean point; Joost scores **27/35**, Ahmed **26/35**. They share four flaws:
  1. **Arithmetic and timing.** The concern is revealed one move too late and the openness ceiling is not applied (Joost B5–B6, Ahmed B3–B4, and Ahmed's silence misses his `quiet` ×1.5). Fix: a defined *lead-in turn* and a defined order (Δ, then cap, then reveal) (§1.2, R-D1).
  2. **The meter invites min-maxing.** Showing "▲ +12" teaches the Δ table, and the table *is* a golden path. Fix: show the size of the change (▲ / ▲▲ / ▼ / ▼▼), never the number (Q1).
  3. **A first-time player can quit at Joost's path A**: the instinct the game itself trained ("show the data") ruins the talk in three moves, with a cold summary card. Fix: a forgiving tutorial talk in Act 0 (Anouk), a *warning line* the first time a person drops into "Dicht", and an in-character ruined line that says how it felt (§1.2, R-D3–R-D5).
  4. **One fake line.** In Ahmed's check-in the CI lead says "Mijn eerste jaar belde ik ook steeds iemand", but the CI lead was never a monteur. Experience must be the player's real experience.
- **29 dialogs for Acts 0–II**, in the spec's schema, with three small proposed additions (§1.1):
  - 2 in Act 0 (Anouk's tutorial, Anouk owns the tray);
  - 10 in Act I (Joost's vacancies, Sanne's checker, Marco the cynic, Esra's agents, Mrs El Amrani's fourth call, Petra's batch, Henk and the camera, Linda, Dirk, Femke as an expert);
  - 10 in Act II (Gert after the cable strike, Mieke's sketches, Femke's triage, Rob from Inkoop, Thomas and the unused capacity, Ilse the baker, Joost's KPI talk rewritten, Sanne's KPI, Frank's block, Thomas as an expert);
  - 7 check-ins: Ahmed (rewritten) plus 6 new (Anouk, Henk's last week, Esra, Petra, Marco at day 100, Linda);
  - 5 short walk-around check-ins (§8.1, added after Merijn's decision on the meter): Yvonne, Kees, Mieke, Rachid, Femke.
- **Every person has a voice sheet (§2):** word choice, rhythm, humour, worry, a recurring line, and what they never say. Everyone speaks standard Dutch (Merijn, 2026-10-15: no dialect); voices differ in what people say and how, not in spelling.
- **Every concern is a real workplace fear** that also carries the Lean or sector point: Joost protects Anouk's face (respect), Petra's batch hides that she is a single point of failure, Femke fears signing a fast check without authority (psychological safety, exploit before elevate), Rob was named in an audit for a wrong transformer size (standard sizes, L9), Gert saw a man fall after an MS flash (safety, test trenches), Ilse will buy a new *gas* oven if hers breaks (lock-in in the energy transition), Mrs El Amrani's heat pump hangs on the wall without power while her mother lives with them.
- **No golden path:** each persuasion dialog lists at least three working routes and the trap, and at least two proposals or experiments that address the concern. The dialog never judges *which* proposal is better; the Check does (Sanne may commit gladly to the weaker checker).
- **11 questions for Merijn (§10), now decided** (2026-10-15): standard Dutch for everyone, an openness bar with arrows, tutorial first talks, and the rest as recommended.

---

## 1. Conventions and the small schema additions

### 1.1 Schema used

The blocks follow the dialog spec §9.1 (`content/people.yaml`, `content/dialogs.yaml`). Three small additions, flagged **(new)**:

| Field | On | Meaning | Why |
|---|---|---|---|
| `label`, `say` **(new)** | proposals, experiments | `label` is the picker's short text; `say` is the player's line when it is chosen | The spec's proposals had no player line. A proposal needs words, or the chip feels like a menu item. |
| `reframe` **(new)** | dialog | The person's reply when `perspective` lands (spec §3.3 mentions "an authored reframe line" but the schema had no key) | The "look through someone else's eyes" move must have someone to look through. |
| `warning` **(new)** | dialog | The line said the first time openness drops into "Dicht" (10–19) | R-D3: a readable last chance before a ruin. |
| `lines.<move>.lands` / `.misses` / `.say` | dialog | Override of the bank's reply when the move lands or misses, and of the player's line | The spec's `lines: {move: {band: text}}` keyed by band; outcome-keyed overrides read better at the moments that matter. Both forms stay valid. |
| `trigger` | check-in | `{beat: <id>, after_days \| before_days: n}`, `{morale_below: n, signal: <id>}`, `after_mission_open` or `after_resolved` | Spec §5.7 names the triggers; this is their shape. |
| `tutorial` **(new)** | dialog | `true`: openness cannot fall below 10, patience 12 (R-D5) | A forgiving first talk. |
| `place` **(new)** | dialog | Overrides the person's place for this talk (a phone call at the contact centre) | Customers are met where the grid operator meets them. |
| `promise` **(new)** | proposal | `{kind: delivery_date, source: planning_estimate}`: the game checks the promise against the simulation | An honest date versus a comforting lie, with a real consequence (Q11). |
| `beats_after` **(new)** | dialog | `[{when: <needs>, text}]`: a line the person says when a later condition is met | The upgrade from a partial to commitment must be *felt* (F6). |
| `observation`, `sets_flags_on_lifted` **(new)** | check-in | The lead the person volunteers when lifted (`plants` names the mission it points at; never a key clue), and flags set on *opgebeurd* | Spec §5.7 mentions observations; this is their shape. |
| `topics`, `closing` | expert | Topic list in the tier-2 draft's `people.yaml` format (`ask`, `open`, `closed`, `teaches`, `sector_clue`), and a last line | Experts run on the same engine (spec §3.4). |
| `lines.<move>.lands` as `{text, tags}` | dialog | An authored reply with its tags, so the next move can read them | Whether `reflect` or `paraphrase` lands depends on the last line's tags; the routes below never rely on an untagged bank line. |

Each persuasion dialog has a comment with its **start** (spec §3.6) and its **routes**: one listening route with the openness after each move, two or more other routes, and the trap. These are for the content tests of spec §9.3, and for a reviewer to see that no route is the only one. Ids, keys and comments are English; every line a player reads is Dutch.

### 1.2 Engine clarifications (R-D1 to R-D5)

Found while auditing the samples (§3). They are proposals for the dialog spec, not changes made here.

- **R-D1, the lead-in turn and the order of a move.** After a move:
  1. apply its Δ;
  2. cap at the next unrevealed layer's `at` + 9 (the ceiling, spec §3.3);
  3. check reveals.

  The concern then needs **two** turns. The first move that lands with openness ≥ `concern.at` gets the `lead_in` line ("Ja. En…"), which carries `hesitation` and shows the cue. The concern is revealed by the **next** move in its `via` list, while openness is still ≥ `at`. Without this, the cue can never appear: in both samples the move that reached the threshold was already in `via`, so the concern should have come out at once. **Validator:** `concern.at` 65–85 (was 60–85), so the cue (≥ 65) always shows with the lead-in.
- **R-D2, steering sizes are shown, not numbered.** See Q1.
- **R-D3, a warning line.** The first time openness falls into "Dicht" in a talk, the person says their `warning` line. It is a last chance to repair before a ruin. It tells the player how the person feels, not which move to make.
- **R-D4, the ruined line says how it felt.** Each `outcomes.ruined` is in character and names the feeling ("Je kwam binnen met je antwoord al klaar."). It tells the player what went wrong without naming a move.
- **R-D5, a forgiving first talk.** Act 0's two dialogs carry `tutorial: true`: openness cannot fall below 10, so they cannot be ruined, and patience is 12. Everything else works as in any talk (Q4).

### 1.3 Grounding

- Sector facts in the lines are sourced in the grounding notes under each act, or are the existing content's numbers (marked as estimates there).
- Facts checked for this doc (2026-10-15, through search extracts):
  - the congestion queue of 14,044 large-consumer requests on 1 July 2025;
  - small-consumer waits of 43–45 weeks in 2025;
  - the ACM prioritisation order (congestion relievers, then safety, health, infrastructure and drinking water, then housing and education);
  - households in congestion areas on the same waiting list from 1 July 2026;
  - the "not every heat pump needs a heavier connection" advice of grid operators;
  - the technician shortage and the training-capacity bottleneck.

  See Sources.

---

## 2. Voice sheet

One rule for all: **people are never the cause.** A person may hold a wrong belief (a plausible cause the clues correct), never a vice. Everyone speaks standard Dutch, in standard spelling (decided: Q5). A voice is made of word choice, sentence rhythm, humour and worry, never of dialect.

| id | Who (age) | Voice: words and rhythm | Humour | Worry (never said early) | Recurring line | Never says |
|---|---|---|---|---|---|---|
| `anouk` | Anouk de Vries (29), werkvoorbereider | Apologises first: "sorry", "nee joh, gaat prima", "ik zit erbovenop". Precise about drawings. | Draws the stack as a mountain on a post-it, with a flag on top. | That she is slower than the rest; she stays late so nobody sees it. | "Ik zit erbovenop." | That she is overloaded; complaints about Joost. |
| `joost` | Joost van Dijk (34), TL Werkvoorbereiding | From an engineering firm in Utrecht; tidy, complete sentences, numbers when nervous: "even voor de duidelijkheid", "eerlijk is eerlijk", "dat is gewoon een feit". | Dry about his spreadsheets: "Mijn Excel heeft meer tabbladen dan ik mensen heb." | Losing face; his predecessor "moved to Inkoop" after one bad quarter; protecting his people's face. | "Mijn team haalt het doel." | Swearing; blaming Anouk. |
| `sanne` | Sanne Bakker (45), TL Intake | Born in Nova. Fast, lists in threes, interjections: "joh", "hè", "nou". | Sarcasm about Intake's status: "het postkantoor". | That Intake gets the blame for errors made elsewhere; that her team is seen as low-skilled. | "We zijn een postkantoor geworden." | Anything bad about her team. When tired she stops joking: a cue. |
| `marco` | Marco Peters (53), TL Monteurs | Thirty years a monteur. Short, flat sentences; "mijn mannen", "kijk", "klaar"; never an office word without a sneer. | Gallows humour about consultants: "Mooie plaatjes. Wie bouwt dat na?" | The 2012 programme that took field hours and vanished; he promised his monteurs "nooit meer". | "En wie bouwt dat na?" | Office words (stakeholder, KPI) without a sneer. |
| `henk` | Henk Verbeek (64), senior monteur | Warm, gruff, slow; calls Ahmed "jongen"; "ik laat het je wel zien", "dat is niet zo moeilijk". Stories with a year in them. | Anecdotes: "In '87 lag hier een kabel van de gemeente die niemand getekend had." | That forty years becomes a video nobody watches; that Ahmed goes out alone at night too soon. | "Laat het me voordoen." | Self-pity. |
| `ahmed` | Ahmed Bouzid (24), monteur | Grew up in Nova; mbo Elektrotechniek. Short sentences, "gewoon", "toch", "man", "echt wel". Says "Henk", never "meneer". | Self-mocking: "Mijn navigatie kent Nova-Oud beter dan ik." | Not good enough; ashamed he still calls a retiree at night. | "Gaat wel." | Long speeches, unless he is very open. |
| `esra` | Esra Yilmaz (41), TL Klantcontactcentrum | From a Rotterdam call centre: direct, "kijk", "serieus?", "gewoon eerlijk", "mijn mensen". | Imitates the hold music and the callers. | One of her four agents is home with stress, another cried in her car; she feels she should have seen it. | "Mijn mensen zijn geen stootkussen." | That her agents are slow. |
| `petra` | Petra Vos (58), Meetdata & registratie | Precise, dry, a little prickly; proud of her system: "Dat staat in mijn map." Says "klopt" a lot. | Calls the registration system "de Molen" ("die maalt, maar langzaam"). | She is alone: a sick week stops everything, and the monthly batch hides that. | "Alles klopt. Tot op de laatste EAN." | That she is behind. |
| `frank` | Frank Hulshof (56), manager Aansluitingen & Netverzwaring | Formal management Dutch: "jaarplan", "verantwoorden", "de directie", "naar de ACM", "daar moet ik op kunnen sturen". | Rare and dry: "Ik word betaald om nee te zeggen. Ja zeggen kan iedereen." | Losing the region's reinforcement budget in the autumn round; the ACM figures. | "Dat moet ik kunnen uitleggen." | Anything personal, until "Denkt mee". |
| `el_amrani` | mevrouw Fatima El Amrani (52), klant, Nova-Oost | Polite, organised, standard Dutch, dates from her notebook. Firm, never rude. | Dry: "Ik ken uw wachtmuziek inmiddels uit mijn hoofd." | Her mother lives with them; the gas boiler is gone; winter is coming. | "Ik heb het opgeschreven." | Swear words; threats she will not carry out. |
| `linda` | Linda Jansen (36), planner | Fast, tired; "omplannen" in every other sentence; apologises while she talks. | Calls her planning board "het kaartenhuis". | That a planning with room for outages looks like she can't plan; she re-plans in the evening, with her children asleep. | "Ik plan iedereen. Behalve mezelf." | That the monteurs are unreliable. |
| `dirk` | Dirk Smits (60), magazijn | Laconic, the fewest words in the building: "Ik heb ze gewoon liggen." | Dry about vans: "Een bus is een magazijn op wielen, alleen zonder magazijnman." | That his warehouse is blamed; he takes pride in a full shelf. | "Ik heb ze gewoon liggen." | Hurry. |
| `femke` | Femke de Wit (38), netplanner | Enthusiastic engineer, draws while talking: "kijk", "kort gezegd", "dat past". | Grid jokes: "Een trafo is net een mens: een piek kan hij aan, een hele dag niet." | Signing a fast check without authority: if a station burns out, her name is under it. | "Vijf minuten werk, als ik eraan toekom." | That the procedure is stupid (she wrote half of it). |
| `gert` | Gert Peeters (50), uitvoerder, Grondwerk Peeters (family firm) | Defensive at first, plain-spoken: "Ik heb gewoon een KLIC-melding gedaan." Talks about "mijn jongens". | "Ik graaf al dertig jaar. Ik heb meer kabels gezien dan jullie kaart." | The safety of his crew; in 2019 he saw a man fall after an MS flash. And his family name on a damage claim. | "Volgens de kaart lag hier niks." | Blame toward his own crew. |
| `mieke` | Mieke van der Veen (49), Revisie & GIS | Careful, a craftswoman of drawings: "dat moet kloppen", "uitzoeken". | The sketch on a sandwich bag ("met pindakaasvlek"). | That "intekenen bij de bron" makes her team obsolete; that since the cable strike everyone looks at GIS. | "We tekenen zo snel als we kunnen." | That the monteurs are sloppy. |
| `rob` † | Rob Verhagen (44), inkoper | Rule-bound, calm, procedural: "aanbesteding", "conform", "de procedure". Says "u" until he is Open. | Accountant jokes: "Een trafo in het magazijn is een dure kapstok." | An audit in 2022 named him for two 630 kVA transformers bought for a project that needed 400. | "Zonder goedgekeurd ontwerp geen bestelling." | That he likes rules for their own sake. |
| `thomas` | Thomas Visser (47), accountmanager grootzakelijk | Smooth, relational, stories about "mijn klanten". | Name-drops the lunch at the business park. | Being the man who takes capacity away from people he has known for twenty years. | "Ik ken die mensen." | A customer's name in a joke. |
| `ilse` † | Ilse de Graaf (44), Bakkerij De Graaf | Warm and fed up, talks in hours of the day: "ik sta hier om vier uur". | "Mijn ovens zijn ouder dan jouw stagiair." | If an oven dies, she buys a new **gas** oven, because that works now, and stays on gas for twenty years. | "Twee jaar." | That she wants special treatment. |

† New to the cast (Rob Verhagen; Ilse de Graaf is in the audit's §5.3 already). Kim and Saskia (two of Esra's four agents), Rachid Ouali (Intake) and Ricardo (a monteur) are named in lines but are not dialog targets.

---
## 3. Audit of the two sample dialogs

### 3.1 Scores

The 7 criteria of CLAUDE.md §2 (1–5, the audit's rubric), judged on the spec's §7 and §8 as written.

| Criterion | Joost (`joost_output_kpi`) | Ahmed (`ahmed_after_henk`) |
|---|---|---|
| 1 Real | **4**: silo KPIs and a lagging indicator that dips first; the predecessor moved after one bad quarter is a real fear in a KPI culture | **5**: knowledge leaving with retirees; a young monteur alone on a night shift in a pre-1970 GPLK network |
| 2 Entertaining | **3**: a good scene, but Joost is grim from start to end; no human moment, no humour | **3**: the van, the window going up and down: good. Little warmth until the very end |
| 3 Intriguing | **4**: the hidden concern, then the condition that points one level up (Frank) | **3**: the concern is guessable from "sinds Henk weg is" |
| 4 Challenging | **4**: listening first, then a proposal that must address the concern; a partial that sends you to Frank | **4**: the "fixing mode" trap is subtle and true |
| 5 Draws in | **4**: the retry the next day; Frank as the next door | **4**: the fact-keyed variant (Henk taught him) is a payoff the player feels |
| 6 Intuitive | **4**: clear chips; but see the quit risk below | **4** |
| 7 Correct | **4**: the Lean is right (Goodhart, leading versus lagging); the numbers break the engine's own rules (F1, F2) | **3**: the numbers miss Ahmed's `quiet` multiplier and the ceiling (F1–F3); a false line (F9) |
| **Total** | **27 / 35** | **26 / 35** |

**The four extra questions:**

| Question | Joost | Ahmed |
|---|---|---|
| **Does it feel like a real person?** | Mostly. "Jij weer." and "Prima. Dan meet ik wat jullie willen." are perfect. He lacks one human moment before the concern; people under pressure still make a joke or offer coffee. | Yes, until his concern: a quiet 24-year-old does not speak in one polished paragraph. And the player's "Mijn eerste jaar belde ik ook steeds iemand" is a lie: the CI lead was never a monteur. |
| **Is the meter readable?** | Readable, too readable: "▲ +12" after silence teaches the Δ table, and a learned table *is* a golden path. Five bands + five pips + mood + sparkline + a number is a lot to read while also reading Joost. Pips that drop mid-talk (pressure) are good; pips that move on every move are noise. | Same. The cue is the best part of the meter: it says "there is more" without saying how. |
| **Can the player feel progress without a golden path?** | Partly. The bands give progress, but nothing shows that a *layer* was reached, so a player who reaches "Open" without the concern does not know why the agreement fails. The partial at B8 can feel like a cheat ("I did everything right") unless the condition is shown as progress. | Yes: the window, getting out of the van, the laugh. |
| **Would a player quit here?** | **At path A, yes.** The game spent the gemba teaching "find the data". The first time the player uses it on a person, the talk is ruined in three moves, with a cold card ("Mislukt — morgen weer"). No warning came before the fall. | No. A failed check-in costs nothing and the window going up says why. |

### 3.2 Findings and fixes

| # | Finding | Where | Fix |
|---|---|---|---|
| F1 | **The concern comes out one move late.** At B5 (Joost) and B3 (Ahmed) openness reaches the concern's `at` with a move in its `via` list, so by the spec's rule the concern is revealed *then*; the walkthrough instead gives the lead-in, and reveals on the next move. The walkthrough is the better play, but the rule does not produce it. | both | R-D1: the lead-in turn (§1.2). |
| F2 | **The ceiling is not applied.** Joost B6 goes to 84 and Ahmed B4 to 79 *before* the concern is revealed; the ceiling is `at` + 9 = 79 and 74. | both | R-D1 order: Δ, cap, reveal. Numbers corrected below. |
| F3 | **Ahmed's silence misses ×1.5** (`quiet`): +18, not +12. | Ahmed B4 | Corrected below (it is capped anyway). |
| F4 | **The Δ number invites min-maxing.** | meter | Show ▲ / ▲▲ / ▼ / ▼▼ (a change under 8, or 8 and over), never the number (Q1). |
| F5 | **The quit risk at Joost's path A.** | Joost A | (a) The first persuasion talks are forgiving: Act 0's Anouk talks cannot be ruined (R-D5). By Act II the player has had about ten talks. (b) A `warning` line on first entering "Dicht" (R-D3). (c) An in-character ruined line (R-D4). |
| F6 | **The partial at B8 can feel like a cheat.** | Joost B8 | The summary card shows "Afspraak onder voorwaarde · nog nodig: Frank Hulshof", and the Mensen journal holds the route. When Frank commits, Joost says a beat line ("Frank heeft getekend. Nu sta ik er ook echt achter."), so the upgrade to commitment is *felt*. |
| F7 | **No layer progress visible.** | meter | A three-step tracker under the name: *Standpunt · Belang · Zorg*. A step fills when that layer is revealed, showing the player has reached the person (Q3). It never shows which move reveals it. |
| F8 | **Joost has no human moment.** | Joost | A coffee and a self-mocking line in B1, and the predecessor told as a fact first, before the feeling. |
| F9 | **A false experience line.** | Ahmed B6 | "In mijn eerste maand hier belde ik Ruud drie keer per dag. Niemand vond dat raar." The player's experience must be the CI lead's own. |
| F10 | **Ahmed's concern is a speech.** | Ahmed | Broken into short sentences with a pause; the doubt as a question he does not finish. |
| F11 | **Trust pips move on every outcome mid-talk.** | meter | Pips change during a talk only on `pressure`, `confront` and `repair` (so their cost is *felt*); the rest at the end, on the summary card (Q1). |
| F12 | **The player's closing line in Ahmed B7 is a promise the game cannot keep** ("Ik loop vaker even langs"). | Ahmed B7 | "Fijn dat je het vertelde." A promise the system does not track is a small lie. |
| F13 | **The cast must match the simulated teams.** The spec's Esra has "two agents at home with stress", but the contact centre has four agents in `content/value_streams.yaml`; half a team on sick leave is not the story the board shows. Likewise Revisie & GIS has two people. | cast | Lines name the real sizes: Esra has one agent at home and one who cried in her car; Mieke works "met z'n tweeën". |

### 3.3 `joost_output_kpi`, rewritten (Act II, `fix_silo_kpis`)

```yaml
dialogs:
  - id: joost_output_kpi
    person: joost
    kind: persuade
    mission: fix_silo_kpis
    requires_clue: "silo_kpis:4"          # 'Mijn doel is dertig ontwerpen per week...'
    owns: silo_kpis
    kpi_team: work_prep
    mood: gespannen                        # the MT is tomorrow (first talk only)
    patience: 10
    # start (first talk): defender 40 - 5 (gespannen) + 0 (team) + 0 (trust 50) + 0 (morale 50) = 35, Op z'n hoede
    opening: "Ik heb tien minuten. Morgen is het MT."
    position: {text: "Mijn team haalt dertig ontwerpen per week. Een record. Als de aansluitingen niet sneller gaan, ligt dat niet aan ons.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [inquiry, open_question, paraphrase]
        text: "Frank. Elke maandag om negen uur. Ontwerpen per week staat bovenaan zijn lijst, dus staat het bovenaan de mijne."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [silence, reflect, empathy, inquiry]
        lead_in: {text: "Ja. En…", tags: [hesitation]}
        text: "Mijn voorganger had één slecht kwartaal. Hij werkt nu bij Inkoop. … Als ik op doorlooptijd ga sturen, wordt dat getal eerst slechter. Dat weet ik gewoon. En dan sta ik in het MT met lege handen."
        tags: [admission]
        condition: "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst."
        unlocks:
          clue: {key: true, depth: 2, text: "Werkvoorbereiding stuurt op ontwerpen per week omdat de manager er elke maandag naar vraagt. Een doorlooptijd die pas na maanden beter wordt, voelt als een risico voor wie erop wordt afgerekend."}
          facts: [heard:joost_kpi]
          proposals: [present_with_sanne]
    reframe: "Vanuit de monteur gezien… die krijgt mijn record als een stapel tekeningen waar hij mee terug moet. Ja. Dat is geen record, dat is een rekening."
    warning: "Hm. Ik heb hier eigenlijk geen tijd voor."
    data: ["silo_kpis:0", "silo_kpis:2"]
    lines:
      show_data:
        lands: "Laat eens zien… van 85 naar 80 procent? Dat had ik niet zo gezien."
        misses: "Dus mijn mensen werken slordig? Ze halen elke week hun doel. Elke week."
      mood: {say: "Hoe ging het MT?"}
      confront: {say: "Jouw team zet toch gewoon te snel door?"}
    proposals:
      - {id: lead_and_oldest, kpis: [work_prep_lead_time, work_prep_oldest], addresses: [concern],
         label: "Doorlooptijd + oudste dossier", say: "Wat als je naast de doorlooptijd het oudste dossier meet? Dat beweegt binnen een paar weken, en dat heb jij in de hand.",
         reply: "Het oudste dossier… dat zie ik volgende week al zakken."}
      - {id: ftr_and_oldest, kpis: [work_prep_ftr, work_prep_oldest], addresses: [concern],
         label: "Eerste keer goed + oudste dossier", say: "Meet wat er bij de monteur goed aankomt, en het oudste dossier in je bak.",
         reply: "Eerste keer goed, en iets wat ik deze week kan laten zien. Dat is eerlijk."}
      - {id: output_and_ftr, kpis: [work_prep_output, work_prep_ftr], addresses: [concern],
         label: "Ontwerpen per week + eerste keer goed", say: "Houd je ontwerpen per week, en zet eerste keer goed ernaast.",
         reply: "Dat kan ik wel aan Frank verkopen."}
      - {id: lead_and_ftr, kpis: [work_prep_lead_time, work_prep_ftr], addresses: [],
         label: "Doorlooptijd + eerste keer goed", say: "Stuur op de doorlooptijd en op eerste keer goed.",
         reply: "Twee getallen die pas na maanden bewegen? Dat is precies wat ik bedoel."}
      - {id: present_with_sanne, hidden: true, addresses: [concern],
         label: "Samen met Sanne presenteren", say: "En als je het niet alleen presenteert, maar samen met Sanne?",
         reply: "Samen. Dan sta ik er niet alleen."}
    experiments:
      - {id: one_quarter_trial, addresses: [concern], label: "Een kwartaal proberen",
         say: "Probeer het een kwartaal, met de oude cijfers er gewoon naast zichtbaar.",
         reply: "Met de oude ernaast. Dan kan ik altijd laten zien wat we deden."}
    co_proposal: {id: present_with_sanne, text: "En als Sanne hetzelfde doet, presenteren we het samen. Dan sta ik er niet alleen."}
    condition_needs: {all: [committed:frank_kpi_targets]}
    outcomes:
      commitment: "Afgesproken. En als het eerst slechter wordt, zeg ik dat zelf in het MT. Voordat Frank het vraagt."
      partial: "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst."
      heard: "Fijn dat je het vroeg. Echt."
      compliance: "Prima. Dan meet ik wat jullie willen."
      ruined: "Je kwam binnen met je antwoord al klaar. Dan moet Ruud het maar tegen mij zeggen."
    beats_after:                           # (new, optional) a line when a condition is met later
      - {when: "committed:frank_kpi_targets", text: "Frank heeft getekend. Nu sta ik er ook echt achter."}
```

**Path A, first try (pushing), corrected:**

| # | Move | Joost | Openness |
|---|---|---|---|
| A1 | Data laten zien ▸ eerste keer goed 85 → 80 % | "Dus mijn mensen werken slordig? Ze halen elke week hun doel. Elke week." | 35 → 23 ▼▼ (too early) |
| A2 | Voorstel doen ▸ doorlooptijd + oudste dossier | "Doorlooptijd? Daar gaat de vergunning over, en de monteur, en de klant. Niet ik." … "Hm. Ik heb hier eigenlijk geen tijd voor." (`warning`) | 23 → 11 ▼▼, Dicht |
| A3 | Druk zetten | "Je kwam binnen met je antwoord al klaar. Dan moet Ruud het maar tegen mij zeggen." | 11 → 0: **mislukt** |

The warning at A2 is the change: a player who now switches to *Begrip tonen* (+6 → 17) or *Stemming peilen* (+2, not early any more) still ends the talk as *geen uitkomst* instead of *mislukt*, and learns more from it. The ruined line says how it felt, not which move to use.

**Path B, the retry the next day, corrected** (start 27: base 40, mood `neutraal` 0, trust 37 → −3, memory `ruined` −10; the `repair` chip is offered):

| # | Move | Speler | Joost | Openness | Tracker / cue |
|---|---|---|---|---|---|
| B1 | Terugkomen op vorige keer | "Gisteren begon ik met mijn verhaal in plaats van met het jouwe. Dat was niet handig." | "Nee. Dat was het niet." *(stilte)* "Koffie? Die van de automaat is slecht. Die van mij is erger." | 27 → 39 ▲▲ | turns his chair |
| B2 | Stemming peilen | "Hoe ging het MT?" | "Zoals altijd. Dertig ontwerpen, record, applaus. En dan vraagt Marco wie onze fouten nabouwt." *(claim, feeling)* | 39 → 47 ▲▲ | Luistert |
| B3 | Samenvatten | "Je haalt je doel, je krijgt applaus, en toch hoor je dat er werk terugkomt." | "Precies. Ik doe wat er gevraagd wordt. En het is nooit goed." | 47 → 54 ▲ (`heard`) | a nod |
| B4 | Doorvragen | "Wie vraagt er eigenlijk om die dertig?" | *(interest)* "Frank. Elke maandag om negen uur…" | 54 → 62 ▲▲ | ● Belang |
| B5 | Gevoel benoemen | "Je zit klem tussen wat Frank vraagt en wat de monteurs nodig hebben." | "Ja. En…" *(lead-in)* | 62 → 72 ▲▲ | *Er zit meer achter…* |
| B6 | Stilte laten | *(je wacht)* | *(concern)* "Mijn voorganger had één slecht kwartaal…" | 72 → 79 ▲ (capped at 79) | ● Zorg |
| B7 | Voorstel doen ▸ doorlooptijd + oudste dossier | "Wat als je naast de doorlooptijd…" | "Het oudste dossier… dat zie ik volgende week al zakken." *(then the co-proposal)* "En als Sanne hetzelfde doet, presenteren we het samen." | 79 → 87 ▲▲ | Denkt mee |
| B8 | Afspraak maken | "Spreken we af: een kwartaal op doorlooptijd en het oudste dossier, en je presenteert samen met Sanne?" | "Ik doe mee. Maar Frank moet het goedvinden. Het blijft zijn lijst." | — | **Afspraak onder voorwaarde · nog nodig: Frank Hulshof** |

**Other routes** (unchanged in spirit from the spec, renumbered):
- **B5′** *Ervaring delen* at 62 lands only with trust ≥ 50. Trust is 40 here: −5 → 57, "Hm. Ander bedrijf." Not fatal. Then:
  - *Doorvragen* ("Wat gebeurt er als dat getal een maand zakt?"): +8 → 65, below `at` 70, no lead-in yet;
  - *Begrip tonen*: +6 → 71, the lead-in;
  - *Gevoel benoemen*: the concern.
- **B7″** *Experiment voorstellen ▸ een kwartaal proberen* addresses the concern too.
- **B7‴** *ontwerpen per week + eerste keer goed* also wins commitment. The dialog does not judge the pair; the board's forecast does.

The compliance path (spec §7.3) stays: correct as written.

### 3.4 `ahmed_after_henk`, rewritten (check-in, no mission)

```yaml
dialogs:
  - id: ahmed_after_henk
    person: ahmed
    kind: checkin
    trigger: {beat: henk_farewell, after_days: 16, morale_below: 50}
    patience: 8
    # start: quiet 47 - 5 (stil) + 0 + 2 (trust 60) - 1 (morale 42) = 43, Luistert
    opening: "Hé."
    position: {text: "Gaat wel.", tags: [claim]}
    layers:
      - id: interest
        at: 50
        via: [open_question, inquiry]
        text: "Anders. Nachtdienst in Nova-Oud is anders zonder Henk. Die kabels zijn ouder dan ik."
        tags: [feeling]
      - id: concern
        at: 65
        via: [silence, empathy, reflect]
        lead_in: {text: "Ja. Nou…", tags: [hesitation]}
        text: "Vorige week. Twee uur 's nachts. Papierloodkabel, en ik wist het niet. … Ik heb Henk gebeld. Hij is met pensioen, man. Ik bel hem uit z'n bed. Wat voor monteur ben ik dan, als ik…"
        tags: [admission, doubt]
        unlocks: {facts: [heard:ahmed_night]}
    warning: "Ik moet zo weer rijden, hoor."
    lines:
      mood: {say: "Hoe gaat het nu echt, sinds Henk weg is?"}
      reflect: {misses: "Ik ben niet ziek, hoor."}
      experience: {say: "In mijn eerste maand hier belde ik Ruud drie keer per dag. Niemand vond dat raar."}
      close: {say: "Fijn dat je het vertelde."}
    proposals:                             # check-ins have none; the steering chips are fixing mode (spec §5.7)
      []
    outcomes:
      lifted: "Doe dat. En… in Nova-Oud weet niemand van de nachtdienst welke kabel waar ligt. Dat zat in Henks hoofd."
      heard: "Oké. Ja. Bedankt."
      none: "Ja. Doei."
    observation: {text: "In Nova-Oud weet niemand van de nachtdienst welke kabel waar ligt. Dat zat in Henks hoofd.", plants: fix_cause_unknown}
    variants:
      - needs: {any: ["chose:knowledge_drain:skills_matrix_buddy", "chose:knowledge_drain:twi_job_instruction"]}
        trigger: {beat: henk_farewell, after_days: 16}   # fires through the beat, whatever his morale
        mood: goed
        position: {text: "Goed, eigenlijk.", tags: [claim]}
        layers:
          - {id: interest, at: 50, via: [open_question, inquiry], text: "Gisteren vond ik zelf een fout in een papierloodkabel. In Nova-Oud. Henk stuurde een kaartje. Met een vis erop.", tags: [feeling]}
          - {id: concern, at: 65, via: [reflect, empathy, silence], lead_in: {text: "Alleen…", tags: [hesitation]},
             text: "Ruud vroeg of ik straks de nieuwe jongens wil opleiden. Ik weet niet of ik dat kan. Henk kon het. Ik ben… ik ben gewoon Ahmed.", tags: [admission, doubt],
             unlocks: {facts: [heard:ahmed_trainer]}}
        outcomes: {lifted: "Misschien moet ik het gewoon doen zoals Henk. Eerst voordoen. Dan zij."}
```

**Route B (listening), corrected:** 43 → *Stemming peilen* +8 → 51 → *Open vraag* +6 → 57 (interest) → *Gevoel benoemen* "Het klinkt alsof je er 's nachts alleen voor staat." +10 → 67 (lead-in, cue) → *Stilte laten* (+18, `quiet` ×1.5) → capped 74 (concern) → *Begrip tonen* "Dat je belt als je het niet weet, is precies wat een goede monteur doet. Om twee uur 's nachts al helemaal." +10 → 84 → *Ervaring delen* (the CI lead's own line) +8 → 92 → *Afronden*: **opgebeurd**. Other routes: *Doorvragen* instead of *Open vraag*; *Begrip tonen* instead of *Stilte* at the lead-in. The trap (path A, fixing mode) is unchanged and right.

---
## 4. The dialog map, Acts 0–II

"Slot" is the mission whose `talk_to` goal or clue the dialog serves; a dialog never opens a problem and takes no slot of its own. "Surfaces" is the Lean or sector point the *person* carries; nobody lectures it.

| # | id | Person | Kind | Mission (slot) | `owns` | Start | Surfaces |
|---|---|---|---|---|---|---|---|
| 1 | `anouk_first_look` | Anouk | persuade (tutorial) | `training_tue` (T) | — | 35 | Gemba is respect: watch the work, not the person. Busy people ≠ flowing work. |
| 2 | `anouk_owns_tray` | Anouk | persuade (tutorial) | `training_fri` (T) | `training_tray` | 60 | A standard lives when the person doing the work owns it: the first taste of commitment versus compliance. |
| 3 | `joost_vacancies` | Joost | persuade | `fix_custom_design` (M) | `custom_design` | 35 | Capacity hides in the work; the fix must not shame the team that worked overtime. |
| 4 | `sanne_checker` | Sanne | persuade | `fix_incomplete_application` (M, fork B) | `incomplete_application` | 30 | Inspection versus prevention; poka-yoke designed by those who see the errors. |
| 5 | `marco_wasted_trips` | Marco | persuade | `fix_installer_not_ready` (M, fork N) | `installer_not_ready` | 30 | The cynic's history: sustaining is the real question; monteur hours are the scarcest resource. |
| 6 | `esra_agents` | Esra | persuade | `fix_status_callers` (M) | `status_callers` | 30 | Failure demand; people as the shock absorber of a broken process. |
| 7 | `el_amrani_fourth_call` | Mrs El Amrani | persuade (customer) | `fix_status_callers` (M) | — | 20 | Lead time as the customer feels it; an honest date versus a comforting one; not every heat pump needs a heavier connection. |
| 8 | `petra_batch` | Petra | persuade | `fix_done_but_not_closed` (M) | `done_but_not_closed` | 40 | A batch is rational given its set-up time, and it hides a single point of failure. Set-up reduction makes small batches pay. |
| 9 | `henk_camera` | Henk | persuade | `save_henks_knowledge` (S, deadline) | `knowledge_drain` | 40 | Skill moves by doing under a master (TWI Job Instruction), not by video. |
| 10 | `linda_replanning` | Linda | persuade | `fix_planning_reshuffle` (S) | `planning_reshuffle` | 25 | A plan that is 100 % full breaks at the first surprise (Kingman). |
| 11 | `dirk_shelf` | Dirk | persuade | `fix_wrong_joint` (S) | `wrong_joint_in_van` | 50 | Material at the point of use; two-bin kanban; both sides are right. |
| 12 | `femke_netplanner` | Femke | expert | `talk_netplanner` (S) | — | 60 | Grid congestion, simultaneity, the queue and who goes first. |
| 13 | `gert_klic` | Gert | persuade | `fix_digging_damage` (M, safety) | — | 35 | A partner is not a culprit; contain the safety risk now, solve the cause next; the map is late. |
| 14 | `mieke_redraw` | Mieke | persuade | `fix_revision_backlog` (M) | `revision_backlog` | 35 | Work done twice; capture at the source, with the expert as the owner of quality. |
| 15 | `femke_triage` | Femke | persuade | `fix_grid_study_queue` (M) | `grid_study_queue` | 31 | Exploit before elevate; a rule nobody dares to change without authority. |
| 16 | `rob_order_rule` | Rob | persuade | `fix_transformer_wait` (M) | `transformer_wait` | 35 | Waits in series that could run in parallel; the risk of ordering early, made small by standard sizes. |
| 17 | `thomas_reclaim` | Thomas | persuade | `fix_unused_capacity` (M) | `unused_capacity` | 40 | Reserved capacity is inventory; congestion management as an offer (capaciteitsbeperkingscontract), not a confiscation. |
| 18 | `ilse_queue` | Ilse | persuade (customer) | `fix_unused_capacity` (M) | — | 20 | Lock-in in the energy transition; a bakery that bakes at night when the grid is empty. |
| 19 | `joost_output_kpi` | Joost | persuade | `fix_silo_kpis` (M) | `silo_kpis` | 35 | §3.3. |
| 20 | `sanne_kpi` | Sanne | persuade | `fix_silo_kpis` (M) | — (`kpi_team: intake`) | 35 / 62 | A leading KPI you control next to a lagging one; the dip before the gain. |
| 21 | `frank_kpi_targets` | Frank | persuade (block) | `fix_silo_kpis` (M) | — | 35 | Look one level up; the regulator's number versus the department's. |
| 22 | `thomas_congestion_map` | Thomas | expert | `sector_congestion_map` (S) | — | 60 | Tier-2 draft §4.1 topics (capacity map, alternative transport rights, GOTORK). |
| 23 | `ahmed_after_henk` | Ahmed | check-in | — | — | 43 | §3.4. |
| 24 | `anouk_late` | Anouk | check-in | — | — | 26 | Overtime as a hidden signal of a process problem; perfectionism as fear. |
| 25 | `henk_last_week` | Henk | check-in | — | — | 37 | Respect at the end of a career; the payoff of knowledge saved by teaching. |
| 26 | `esra_after` | Esra | check-in | — | — | 30 | A leader who watched the numbers and missed the people. |
| 27 | `petra_after` | Petra | check-in | — | — | 40 | A fix that makes someone's old way look stupid; respect for the reason behind it. |
| 28 | `marco_day_100` | Marco | check-in | — | — | 40 | Will it last when you leave? Ownership as sustain. |
| 29 | `linda_evenings` | Linda | check-in | — | — | 24 | The planner nobody plans for. |

**Coverage.** Every `talk_to` goal in Acts 0–II has its dialog (`talk_netplanner` → 12, `sector_congestion_map` → 22). Every main mission of Acts I–II except the walk and `review_100_days` has at least one resistant person. The sides that have a resistant person (Henk, Linda, Dirk) have a short dialog. Every Act I and II main mission has a person whose concern adds a clue or a fact, as spec §5.1 asks.

**Pacing.** 9 persuasion dialogs in Act I, 9 in Act II, at most two per mission. Check-ins arrive by signal, at most two a week (spec §5.7), so a player meets about one every ten in-game days.

---

## 5. Act 0 — Inwerkweek

Both are `tutorial: true` (R-D5): they cannot be ruined, patience is 12, and the meter, the cue and the tracker all work as later. The first one teaches the meter and the cue. The second one teaches that a fix someone *owns* lasts longer.

```yaml
dialogs:
  - id: anouk_first_look
    person: anouk
    kind: persuade
    mission: training_tue
    tutorial: true
    patience: 12
    # start: overloaded 35 + 0 (neutraal) + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "O, hoi. Sorry, het is een beetje een bende. Drie collega's zitten op cursus."
    position: {text: "Het is gewoon druk deze week. Ik zit erbovenop.", tags: [claim]}
    layers:
      - id: interest
        at: 45
        via: [open_question, inquiry, paraphrase]
        text: "Achter elk dossier zit iemand die wacht. Een gezin, een bakker, een school. Dus ik wil het niet laten liggen."
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [reflect, empathy, silence]
        lead_in: {text: "Het is alleen…", tags: [hesitation]}
        text: "Iedereen komt kijken als het druk is. Met een stopwatch. En dan denk ik: nu zien ze hoe langzaam ik ben."
        tags: [admission]
        unlocks: {facts: [heard:anouk_first_look], proposals: [come_at_eight]}
    reframe: "Vanuit het dossier gezien? Ha. Dat ligt vooral. In een bak."
    proposals:
      - {id: sit_beside, addresses: [concern], label: "Een uur meekijken, zonder oordeel",
         say: "Mag ik een uur naast je zitten? Ik kijk naar het werk, niet naar jou.",
         reply: "Naar het werk. Oké. Dat… is eigenlijk wel fijn."}
      - {id: stopwatch, addresses: [], label: "Je werk timen",
         say: "Ik wil even timen hoe lang een ontwerp duurt.",
         reply: "Timen. Dus toch."}
      - {id: come_at_eight, hidden: true, addresses: [concern], label: "Morgen om acht uur",
         say: "Mag ik morgen om acht uur komen, als de dag begint?",
         reply: "Kom maar. Dan zie je hoe het begint: koffie, de twee bakken, en dan zoeken."}
    co_proposal: {id: come_at_eight, text: "Kom morgen om acht uur. Dan zie je hoe het begint: koffie, de twee bakken, en dan zoeken."}
    outcomes:
      commitment: "Kom maar. Ik zet koffie. Slechte koffie, maar koffie."
      partial: "Goed. Maar zonder stopwatch, hè."
      heard: "Fijn dat je eerst vroeg. Dat doet niet iedereen."
    # route: mood +12 (overloaded x1.5) 47 > open question +6 53 (interest) > paraphrase +7 60 (heard)
    #        > empathy +6 66 (lead-in, cue) > silence +12 > 74 capped (concern) > propose sit_beside +8 82 > ask: commitment (8 moves)
    # other routes: inquiry instead of open question; reflect instead of empathy at the lead-in; the co-proposal at Denkt mee.
    # the lesson: the stopwatch is the gemba tool the player was just given. Asked for bluntly, it scares the person it measures.

  - id: anouk_owns_tray
    person: anouk
    kind: persuade
    mission: training_fri
    owns: training_tray
    tutorial: true
    patience: 12
    mood: goed
    # start: overloaded 35 + 10 (goed: the experiment worked) + 0 + 0 + 0 + 15 (memory: committed on Tuesday) = 60, Open
    # without Tuesday's commitment: 45 (Luistert); with a stopwatch partial: 45
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
        unlocks: {facts: [heard:anouk_owner], proposals: [anouk_writes_a4]}
    reframe: "Vanuit de nieuwe collega die volgend jaar begint? Die ziet twee bakken en denkt: zo hoort het. Hm."
    proposals:
      - {id: joost_announces, addresses: [], label: "Joost kondigt het aan",
         say: "Joost kan het maandag in het werkoverleg aankondigen. Dan is het geregeld.",
         reply: "Ja. Dat kan. Dan is het van Joost."}
      - {id: a4_above_tray, addresses: [interest], label: "Een A4 boven de bak",
         say: "Een A4 boven de bak, met de regel erop. Dan hoeft niemand het te onthouden.",
         reply: "Een A4. Ja. Al hangen er hier al zes A4'tjes die niemand leest."}
      - {id: anouk_writes_a4, hidden: true, addresses: [concern], label: "Jij schrijft het A4, in jouw woorden",
         say: "Wat als jij het A4 schrijft, in jouw woorden, en het maandag zelf laat zien? Niet als regel. Als wat je ontdekte.",
         reply: "Als wat ik ontdekte. Dan is het geen regel van de nieuwe. Dan is het… mijn trucje."}
    experiments:
      - {id: decide_together_friday, addresses: [concern], label: "Een week proberen, samen beslissen",
         say: "Probeer het een week met z'n vieren, en beslis vrijdag samen of het blijft.",
         reply: "Samen beslissen. Dan is het niet mijn regel. Dan is het de onze."}
    co_proposal: {id: anouk_writes_a4, text: "Als ik het A4 zelf mag schrijven. En jij er maandag bij staat. Niet om te praten, gewoon erbij."}
    outcomes:
      commitment: "Afgesproken. Ik teken er een bergje bij. Met een vlag."
      partial: "Goed. Als Joost het ook zegt."
      heard: "Dank je. Ik ga het A4 in elk geval maken."
    # route: open question +6 66 (interest) > reflect +10 76 (lead-in, cue) > silence +12 > 81 capped (concern)
    #        > propose anouk_writes_a4 +8 89 > ask: commitment (5 moves)
    # joost_announces wins at most a partial: the change is imposed on the person whose work it is (buy-in none).
    # This is where the Friday time-lapse can show the buy-in factor for the first time (spec §4.2), at no risk.
```

---

## 6. Act I — De eerste honderd dagen

### 6.1 Main missions

```yaml
dialogs:
  - id: joost_vacancies
    person: joost
    kind: persuade
    mission: fix_custom_design
    owns: custom_design
    mood: gespannen                        # the MT decides about his vacancies in three weeks
    patience: 10
    # start: defender 40 - 5 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Als je komt vertellen dat we efficiënter moeten werken: dat weet ik. Ik heb het uitgerekend."
    position: {text: "Ik heb twee werkvoorbereiders extra nodig. Ruim honderd dossiers in de bak, zes weken overwerk. Dat is gewoon een feit.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Elke week komen er meer dossiers binnen dan we eruit krijgen. Anouk zat gisteren om zeven uur nog te tekenen. Dat wil ik niet meer."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [reflect, empathy, silence, inquiry]
        lead_in: {text: "Kijk, en als het niet aan mensen ligt…", tags: [hesitation]}
        text: "…dan zeg ik eigenlijk dat mijn team het al die tijd verkeerd deed. Anouk heeft zich zes weken kapotgewerkt. Ik ga niet in het MT zeggen dat het ook anders had gekund."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Niemand heeft ooit gevraagd of het anders mocht. Drie handtekeningen, zo is het altijd gegaan. Ook voor een gewone woning.'"}
          facts: [heard:joost_vacancies]
          proposals: [anouk_leads]
    reframe: "Vanuit de klant? Die ziet niet hoeveel uur er in een tekening zit. Die ziet alleen dat hij wacht."
    warning: "Ik ga dit niet nog een keer uitleggen."
    data: ["custom_design:0", "custom_design:4"]
    lines:
      show_data:
        lands: "Vijf uur voor een gewone woning… even voor de duidelijkheid: dat is net zo lang als voor de bakker op de hoek."
        misses: "Dus we zijn traag. Dank je."
    proposals:
      - {id: hold_and_trial, addresses: [interest], label: "Vacatures drie weken aanhouden, standaardontwerp proberen",
         say: "Houd de vacatures drie weken aan. In die tijd probeert het team een standaardontwerp voor een gewone woning.",
         reply: "En als het niks wordt, ben ik drie weken kwijt en is Anouk nog steeds om zeven uur hier."}
      - {id: team_presents, addresses: [concern], label: "Het team presenteert wat het ontdekte",
         say: "Laat het team het zelf in het MT vertellen: wat ze ontdekten. Niet wat er fout ging.",
         reply: "Wat ze ontdekten. Ja. Dat is iets anders dan 'we deden het fout'."}
      - {id: anouk_leads, hidden: true, addresses: [concern], label: "Anouk tekent het standaardontwerp",
         say: "Wat als Anouk het standaardontwerp uittekent? Zij weet het beste wat er altijd hetzelfde is.",
         reply: "Dan is het hun idee. Niet het mijne, niet het jouwe. Dat kan ik in het MT vertellen."}
      - {id: temp_hire, addresses: [], label: "Tijdelijk twee mensen inhuren",
         say: "Neem tijdelijk twee mensen in, terwijl we kijken.",
         reply: "Dat vraag ik al zes weken. … Al moet Anouk ze dan wel eerst inwerken. Naast haar eigen bak."}
    experiments:
      - {id: one_signature_week, addresses: [interest], label: "Eén week één handtekening",
         say: "Eén week: een standaardaansluiting met één handtekening in plaats van drie.",
         reply: "Eén week. Dat overleeft het MT wel."}
    co_proposal: {id: anouk_leads, text: "Laat Anouk het eerste standaardontwerp tekenen. Ze tekent ze toch al allemaal hetzelfde."}
    outcomes:
      commitment: "Goed. Ik zeg in het MT dat we de vacatures drie weken aanhouden. Omdat het team iets wil proberen."
      partial: "Ik wil het proberen. Maar de vacatures blijven staan tot ik iets zie."
      heard: "Je bent de eerste die vraagt hoe het met ze gaat in plaats van hoeveel ze maken."
      compliance: "Als Ruud dat wil. Dan schrijf ik het zo op."
      ruined: "Dus het ligt aan ons. Duidelijk. Ik zie je in het MT."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry "Wat zou er veranderen als je die twee mensen krijgt?" +8 56 (interest)
    #        > reflect +10 66 > empathy +6 72 (lead-in, cue) > silence +12 > 79 capped (concern) > propose team_presents +8 87
    #        (Denkt mee: the co-proposal) > ask: commitment (8 moves)
    # other routes: show_data at 56 (+10, lands) instead of reflect; inquiry at the lead-in instead of silence; anouk_leads instead of team_presents.
    # trap: show_data before 'heard' ("Dus we zijn traag."); temp_hire wins at most a partial and is the D19 counter-signal.

  - id: sanne_checker
    person: sanne
    kind: persuade
    mission: fix_incomplete_application
    owns: incomplete_application
    mood: gespannen
    patience: 9                            # overloaded 10 - 3 = 7; she gives two more once she feels heard (authored)
    # start: overloaded 35 - 5 + 0 + 0 + 0 = 30, Op z'n hoede
    opening: "Twee minuten. Ik heb vier mensen in de wacht en één aan de lijn."
    position: {text: "Ik heb iemand extra nodig om alles na te lopen. Negentien van de laatste veertig aanvragen moesten terug.", tags: [claim]}
    layers:
      - id: interest
        at: 50
        via: [open_question, inquiry, paraphrase]
        text: "Elke aanvraag die terug moet, kost ons twee telefoontjes en een mail. En de klant is boos op óns. Wij hebben dat formulier niet gemaakt."
        tags: [claim, feeling]
      - id: concern
        at: 68
        via: [reflect, empathy, silence]
        lead_in: {text: "Weet je wat het is…", tags: [hesitation]}
        text: "Hier denken ze dat Intake het postkantoor is. Stempel erop, doorsturen. Als er iets misgaat, is het de Intake. Met een controleur kan ik tenminste laten zíen dat het niet aan ons ligt."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Wat er mist, is altijd hetzelfde: het vermogen, de meterkastfoto, de installateur. Wij zien het elke dag. Niemand heeft ons ooit gevraagd wat er op het formulier moet.'"}
          facts: [heard:sanne_checker]
          proposals: [team_designs_form]
    reframe: "Vanuit de klant gezien… die vult in wat wij vragen. En wij vragen het niet. Hè. Dat is eigenlijk best gek."
    warning: "Joh, ik heb echt geen tijd voor een praatje."
    data: ["incomplete_application:2", "incomplete_application:4"]
    lines:
      show_data:
        lands: "Een week wachten voor een meterkastfoto. Ja. Dat geloof ik meteen."
        misses: "Ja, dat wéét ik. Daarom vraag ik om iemand."
    proposals:
      - {id: extra_checker, addresses: [concern], label: "Een extra controleur",
         say: "Goed: één iemand die elke aanvraag naloopt voordat hij verder gaat.",
         reply: "Ja! Dat vraag ik al een halfjaar."}
      - {id: required_fields, addresses: [interest], label: "Verplichte velden in het webformulier",
         say: "Wat als het formulier pas verder gaat als vermogen, foto en installateur erin staan?",
         reply: "Dan zien we het niet eens meer… als het werkt. Wie bouwt dat dan?"}
      - {id: team_designs_form, hidden: true, addresses: [concern], label: "Jullie ontwerpen het formulier",
         say: "Jouw team weet als enige wat er altijd mist. Wat als jullie het nieuwe formulier ontwerpen?",
         reply: "Wij. Ontwerpen. Het postkantoor ontwerpt het formulier. … Dat wil ik Joost weleens horen zeggen."}
    experiments:
      - {id: tally_per_field, addresses: [concern], label: "Twee weken turven per veld",
         say: "Twee weken turven wat er mist, per veld, op een A4 aan de muur.",
         reply: "Een turflijst heb ik al. Maar per veld… dan zie je waar het vandaan komt. Niet bij ons."}
    co_proposal: {id: team_designs_form, text: "Laat ons de verplichte velden kiezen. Wij weten precies wat er altijd mist."}
    outcomes:
      commitment: "Afgesproken. En als het werkt, wil ik dat het in het MT gezegd wordt. Door jou. Dat het het formulier was, niet mijn team."
      partial: "Ik doe het. Maar mijn aanvraag voor een controleur gaat niet van tafel tot ik het zie."
      heard: "Zo. Dat moest er even uit."
      compliance: "Prima. Weer iets erbij."
      ruined: "Dus wij moeten beter opletten. Dank je, dat zeggen ze al tien jaar."
    # route: mood +12 (gespannen, overloaded x1.5) 42 > open question +6 48 > paraphrase +7 55 (heard, interest)
    #        > reflect +10 65 > empathy +6 71 (lead-in, cue) > silence +12 > 77 capped (concern) > propose team_designs_form +8 85 > ask: commitment (8 moves)
    # other routes: inquiry for paraphrase; show_data at 55 (+10 lands) then empathy; the tally experiment for the proposal.
    # NOTE the dialog does not judge: extra_checker also addresses her concern (proof) and wins commitment. The Check then shows
    # an inspection at fit 0.7 that fades in 30 days. The weaker fix with a committed owner is a real, honest outcome.

  - id: marco_wasted_trips
    person: marco
    kind: persuade
    mission: fix_installer_not_ready
    owns: installer_not_ready
    patience: 10
    # start: cynic 30 + 0 + 0 (team monteurs) + 0 + 0 = 30, Op z'n hoede
    opening: "Ah. De nieuwe verbetermanager. Ik heb er al drie gehad. Koffie staat daar."
    position: {text: "Twee op de vijf adressen zijn niet klaar als mijn mannen voor de deur staan. Twintig monteursuren per week. Die heb ik niet.", tags: [claim]}
    layers:
      - id: interest
        at: 50
        via: [open_question, inquiry, paraphrase]
        text: "Elke rit voor niks is een klant die wél klaar was en een week langer wacht. En mijn mannen zitten in de bus te bellen met een installateur die z'n telefoon niet opneemt."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [inquiry, silence, empathy]
        lead_in: {text: "Kijk. In 2012…", tags: [hesitation]}
        text: "In 2012 kwam er ook een programma. Consultants, mooie plaatjes, workshops. Mijn mannen zaten twee dagen per maand in een zaaltje in plaats van op straat. Toen de consultants weggingen, was alles weer bij het oude. Ik heb mijn mannen beloofd: nooit meer. Als ik nu weer ja zeg, ben ik een leugenaar."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Mijn mannen zien op een foto in één oogopslag of een meterkast klaar is. Maar niemand vraagt ze iets voordat ze rijden.'"}
          facts: [heard:marco_2012]
          proposals: [monteurs_judge_photos]
    reframe: "Vanuit de planner? Die plant op de datum van het akkoord. Die weet ook niet dat de kast niet klaar is. Nee. Die heeft het ook niet makkelijk."
    warning: "Zeg het maar gewoon. Wat moet ik doen?"
    data: ["installer_not_ready:2"]
    lines:
      show_data:
        lands: "Zeventig procent. Zie je. Dat zeg ik al twee jaar. Nu staat het tenminste ergens."
        misses: "Cijfers. Ik heb mannen nodig, geen cijfers."
      experience: {misses: "Bij jouw vorige baan. Ja. Hier is het Nova."}
    proposals:
      - {id: readiness_call, addresses: [interest], label: "Planning belt vooraf",
         say: "Wat als Planning twee dagen vooraf belt of de meterkast klaar is?",
         reply: "Bellen. Ja. Als ze het volhouden."}
      - {id: photo_upload, addresses: [interest], label: "Foto van de meterkast vooraf",
         say: "De installateur stuurt een foto van de meterkast voordat er een monteur rijdt.",
         reply: "Een foto. Daar zie ik meer op dan op tien formulieren."}
      - {id: monteurs_judge_photos, hidden: true, addresses: [concern], label: "Jouw mannen beoordelen de foto's",
         say: "Wat als jouw mannen de foto's beoordelen? Geen zaaltje. Tien minuten bij de koffie op de werkplaats.",
         reply: "Tien minuten bij de koffie. Op de werkplaats. Dat… is iets anders dan 2012."}
    experiments:
      - {id: one_month_you_decide, addresses: [concern], label: "Eén maand, één wijk, jij beslist",
         say: "Eén maand, één wijk. En na die maand zeg jij of het blijft. Niet Ruud, niet ik.",
         reply: "Ik zeg of het blijft. Ik. Goed."}
    co_proposal: {id: monteurs_judge_photos, text: "Laat Ricardo het doen. Die ziet aan een foto of de aarding goed is."}
    outcomes:
      commitment: "Goed. Eén maand. En als het na een maand weg is, ben jij de vierde."
      partial: "Ik doe mee. Als het na een maand nog loopt."
      heard: "Hm. Jij luistert tenminste. Dat deed de vorige niet."
      compliance: "Komt op de stapel."
      ruined: "Zie je. Mooie woorden. En wie bouwt dat na?"
    # route: open question +6 36 > paraphrase +7 43 (heard) > inquiry +8 51 (interest) > empathy +6 57
    #        > show_data +15 (cynic x1.5) 72 (lead-in, cue) > silence +12 > 79 capped (concern) > experiment +6 85 > ask: commitment (8 moves)
    # other routes: inquiry instead of silence at the lead-in; monteurs_judge_photos instead of the experiment; two listening moves instead of the data.
    # trap: experience lands at half for a cynic ("Bij jouw vorige baan. Ja."). The data is his ally, but only after he feels heard.
    # Path dependence: heard:marco_2012 is read by Ruud's own 2012 reveal (audit §5.3) and by marco_day_100.

  - id: esra_agents
    person: esra
    kind: persuade
    mission: fix_status_callers
    owns: status_callers
    mood: moe                              # one of her four agents is home with stress
    patience: 9                            # defender 10 - 2 (moe) = 8; +1 authored: she wants this talk
    # start: defender 40 - 10 + 0 + 0 + 0 = 30, Op z'n hoede
    opening: "Kijk, ik geef je tien minuten. Dan moet ik de wachtrij weer in."
    position: {text: "Ik heb vier agents extra nodig. Een kwartier in de wacht, de hele dag. Dat is niet normaal.", tags: [claim]}
    layers:
      - id: interest
        at: 50
        via: [open_question, inquiry, paraphrase]
        text: "Dat scherm daar staat de hele dag op rood. Mijn mensen krijgen elk uur iemand aan de lijn die al vier keer gebeld heeft en dat op hén afreageert."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [reflect, empathy, silence]
        lead_in: {text: "En eerlijk gezegd…", tags: [hesitation]}
        text: "Saskia zit thuis. Stress. En Kim zat vorige week te huilen in haar auto op de parkeerplaats. Op een team van vier. Ik had het moeten zien. Ik ga er niet nog een kwijtraken."
        tags: [admission]
        unlocks: {facts: [heard:esra_people], proposals: [one_agent_calls_back]}
    reframe: "Vanuit de beller? Die heeft een warmtepomp aan de muur en geen stroom. Ik zou ook bellen. Vier keer."
    warning: "Serieus? Ik heb hier geen tijd voor."
    data: ["status_callers:0", "status_callers:2"]
    lines:
      show_data:
        lands: "Vier op de tien. Dat zijn… dat zijn mijn rode uren. Allemaal dezelfde vraag."
        misses: "Ja. En? Dan heb ik nog steeds mensen tekort."
    proposals:
      - {id: four_agents, addresses: [], label: "Vier agents extra",
         say: "Vier extra agents, tijdelijk.",
         reply: "Vier. Ja. … Al moeten ze dan eerst zes weken worden ingewerkt. Door de mensen die nu al op hun tandvlees lopen."}
      - {id: status_messages, addresses: [interest], label: "Klanten krijgen vanzelf bericht",
         say: "Klanten krijgen bij elke stap vanzelf een bericht waar hun aansluiting is.",
         reply: "Dan bellen ze niet. … Als het bericht klopt. Werkvoorbereiding weet zelf niet eens wanneer iets klaar is."}
      - {id: one_agent_calls_back, hidden: true, addresses: [concern], label: "Eén agent belt de wachtenden zelf",
         say: "Eén van je mensen gaat een week uit de wachtrij en belt de klanten die al drie weken wachten. Vóórdat die ons bellen.",
         reply: "Kim. Die kent de dossiers. En die zit dan een week niet in de vuurlinie."}
    experiments:
      - {id: listen_and_tally, addresses: [interest], label: "Een middag meeluisteren en turven",
         say: "Eén middag samen meeluisteren en turven waarom mensen bellen.",
         reply: "Turven. Ik heb het gevoel al. Maar goed, een getal is sterker dan een gevoel in het MT."}
      - {id: rotate_off_the_queue, addresses: [concern], label: "Om de beurt een uur uit de wachtrij",
         say: "Elke agent een uur per dag uit de wachtrij om wachtende klanten zelf te bellen. Om de beurt.",
         reply: "Om de beurt een uur niet in de vuurlinie. Dat merken ze. Dat merk ik."}
    co_proposal: {id: one_agent_calls_back, text: "Laat Kim de wachtenden terugbellen. Een week. Die kent de dossiers, en zij heeft het het hardst nodig."}
    outcomes:
      commitment: "Deal. En als het werkt, wil ik niet horen dat ik dus geen agents nodig had. Ik had ze nodig. Alleen niet hiervoor."
      partial: "Ik doe het. Maar mijn aanvraag voor vier agents blijft liggen tot ik de wachtrij groen zie."
      heard: "Fijn dat iemand een keer vraagt hoe het met ze gaat."
      compliance: "Prima. Komt erbij."
      ruined: "Mijn mensen zijn geen stootkussen. En ik ook niet."
    # route: mood +8 38 > open question +6 44 > paraphrase +7 51 (heard, interest) > reflect +10 61 > inquiry +8 69
    #        > empathy +6 75 (lead-in, cue) > silence +12 > 79 capped (concern) > propose one_agent_calls_back +8 87 > ask: commitment (9 moves)
    # other routes: show_data at 61 (+10 lands) instead of inquiry; reflect at the lead-in; rotate_off_the_queue.
    # Team size: the contact-centre pool has 4 agents (content/value_streams.yaml); the lines say so, so the story never contradicts the board.
    # trap: four_agents is her position and still wins no commitment: it does not touch what she fears.

  - id: el_amrani_fourth_call
    person: el_amrani
    kind: persuade
    missions: [fix_status_callers, winter_el_amrani]   # 2026-10-16 (drie-winters §3): the frost milestone opens the call on day 49 for a player not yet in fix_status_callers
    place: customer_contact.answer         # the player takes her fourth call over from an agent
    mood: gespannen
    patience: 10
    # start: customer_upset 25 - 5 + 0 + 0 + 0 = 20, Op z'n hoede
    # customer_upset: empathy and paraphrase x1.5; steering lands only after 'heard' AND the concern
    opening: "Goedemiddag. U spreekt met Fatima El Amrani. Ik bel voor de vierde keer deze maand, en ik heb ze allemaal opgeschreven."
    position: {text: "Ik wil een datum. Een echte. Anders ga ik naar de Geschillencommissie.", tags: [claim]}
    layers:
      - id: interest
        at: 45
        via: [paraphrase, open_question, inquiry]
        text: "Op 7 september zei iemand 'binnenkort'. Op 21 september 'we zijn ermee bezig'. Op 5 oktober wist niemand het. Ik wil gewoon weten waar ik aan toe ben."   # dates fixed 2026-10-16: her request is born ~27 July
        tags: [claim, feeling]
      - id: concern
        at: 65
        via: [empathy, reflect, silence]
        lead_in: {text: "Het gaat niet eens om mij…", tags: [hesitation]}
        text: "Mijn moeder woont bij ons. Ze is eenentachtig en heeft het altijd koud. De installateur zei: haal die cv-ketel eruit, de warmtepomp is beter. Die hangt nu aan de muur. Zonder stroom. Het wordt elke nacht kouder."   # 2026-10-16: fits any call date before the frost (drie-winters §3)
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Niemand belt me terug. Dus bel ik zelf. Elke twee weken, met mijn schrift erbij.'"}
          facts: [heard:el_amrani]
          proposals: [check_existing_connection]
    reframe: "Vanuit uw kant? U zit daar met honderd mensen zoals ik. … Goed. Maar ik ben wel deze."
    warning: "Ik heb geen behoefte aan een riedeltje."
    lines:
      confront:
        say: "Mevrouw, als u de aanvraag compleet had ingevuld, was het sneller gegaan."
        any: "Het formulier vroeg er niet om! Ik heb het hier, uitgeprint."
      mood: {lands: "Hoe het gaat? Ik ken uw wachtmuziek inmiddels uit mijn hoofd. Vivaldi, toch?"}
      inquiry:
        say: "Wat wilt u het liefst weten, als u één ding mocht vragen?"
        lands: {text: "Of ik deze winter warm zit. Dat is alles.", tags: [feeling]}
    proposals:
      - {id: name_a_date, addresses: [interest], label: "Een datum noemen",
         say: "Ik zie hier {promise_date}. Dan wordt u aangesloten.",   # 2026-10-16: the planning estimate the game shows and checks
         reply: "Veertien november. Ik schrijf het op.",
         promise: {kind: delivery_date, source: planning_estimate}}   # (new) checked against the followed order (audit §3.0)
      - {id: honest_window_and_contact, addresses: [interest, concern], label: "Eerlijk zijn, en één aanspreekpunt",
         say: "Ik ga u geen datum beloven die ik niet zeker weet. Ik zoek uit waar uw dossier ligt, ik bel u vrijdag terug, en vanaf nu heeft u één aanspreekpunt: mij.",
         reply: "Vrijdag. U. Goed. Ik schrijf uw naam op."}
      - {id: check_existing_connection, hidden: true, addresses: [concern], label: "Kan de warmtepomp nu al draaien?",
         say: "Er is misschien iets wat sneller kan. Veel warmtepompen kunnen al op een gewone aansluiting draaien, op een lagere stand. Mag ik een monteur laten kijken of dat bij u kan, voor de winter?",
         reply: "Dus… mijn moeder zit misschien volgende week al warm? Waarom heeft niemand dat gezegd?"}
    outcomes:
      commitment: "Goed. Ik wacht op uw telefoontje. En als u niet belt, bel ik. Dat weet u."
      partial: "Ik schrijf het op. Als het niet klopt, hoort u van me."
      heard: "Dank u dat u luisterde. Dat is de eerste keer."
      compliance: "Ik heb geen keus, hè. Ik schrijf het op."
      ruined: "Dan bel ik de Geschillencommissie. Het nummer staat al in mijn schrift."
    # route: empathy +9 29 > paraphrase +10 39 (heard) > open question +6 45 (interest) > paraphrase +10 55 > inquiry +8 63
    #        > reflect +10 73 (lead-in, cue) > empathy +9 > 74 capped (concern) > propose honest_window_and_contact +8 82 > ask: commitment (9 moves)
    # other routes: silence at the lead-in; check_existing_connection (+8, her own question "waarom heeft niemand dat gezegd" is the commitment).
    # temptation: name_a_date after the concern lands (+8, it addresses her interest) and wins a partial that calms her NOW.
    #   If the followed order misses that date: her next call starts at memory -15 and reputation -1 (spec §6). This is realistic_promise
    #   versus a lie, felt from the customer's side. Before the concern, any proposal is too early ("Data. Iedereen noemt data.").
    # trap: confront. The incomplete form IS part of the story (fork B), and blaming her for it is still blaming the customer for our form.

  - id: petra_batch
    person: petra
    kind: persuade
    mission: fix_done_but_not_closed
    owns: done_but_not_closed
    patience: 10
    # start: defender 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Als je komt voor de EAN van die familie: die zit in de maandrun. Volgende week dinsdag."
    position: {text: "Eens per maand registreren is efficiënter. Dan doe ik de hele stapel in één keer, en alles klopt.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [inquiry, open_question, paraphrase]
        text: "Elke keer dat ik in het register ga, ben ik een kwartier kwijt voordat ik iets heb gedaan. Twee tokens, de controles, de export. De Molen maalt, maar langzaam."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [silence, empathy, inquiry]
        lead_in: {text: "En dan nog iets…", tags: [hesitation]}
        text: "Ik ben alleen. Als ik het elke dag doe en ik ben een week ziek, dan ligt het stil en ziet iedereen het meteen. Nu merkt niemand het als ik er een week niet ben. De maandrun schuift gewoon een weekje op."
        tags: [admission]
        condition: "Ik wil het wel. Maar niet zolang ik de enige ben."
        unlocks: {facts: [heard:petra_alone], proposals: [rachid_backup]}
    reframe: "Vanuit de klant… die heeft een kabel in de grond en een leverancier die zegt dat hij niet bestaat. Ja. Dat is geen administratie meer. Dat is een koude woonkamer."
    warning: "Mijn cijfers kloppen. Wat wil je nog meer?"
    data: ["done_but_not_closed:0", "done_but_not_closed:3"]
    lines:
      show_data:
        lands: "Twee weken… voor elke aansluiting? Ik dacht altijd: het is maar administratie."
        misses: "Mijn cijfers kloppen. Tot op de laatste EAN."
    proposals:
      - {id: daily_run, addresses: [interest], label: "Elke dag één sessie",
         say: "Wat als je elke dag om vier uur één sessie doet, met wat er die dag klaar is?",
         reply: "Elke dag een kwartier opstarten. Dat is twintig keer zoveel opstarten."}
      - {id: same_day, addresses: [], label: "Registreren op de dag zelf",
         say: "De monteur meldt het af, en jij registreert het dezelfde dag.",
         reply: "Dezelfde dag. En als ik er niet ben?"}
      - {id: rachid_backup, hidden: true, addresses: [concern], label: "Rachid leert het van je",
         say: "Wat als Rachid van Intake het van je leert? Eén middag per week naast je. Dan ben je niet meer de enige.",
         reply: "Rachid. Die is precies. … Dan kan ik ook eens op vakantie zonder de maandrun in mijn hoofd."}
    experiments:
      - {id: shorter_login, addresses: [interest], label: "De inlog van de Molen korter",
         say: "Ik vraag IT of de inlog korter kan. Eén token in plaats van twee, en de controles automatisch.",
         reply: "Dat vraag ik al vier jaar. Maar goed. Als jij het vraagt…"}
      - {id: sick_week_a4, addresses: [concern], label: "Eén A4 voor als Petra er niet is",
         say: "We schrijven samen op wat er moet gebeuren als jij een week weg bent. Eén A4, en iemand oefent het één keer.",
         reply: "Een A4 voor als ik ziek ben. Dan hoef ik niet ziek te zijn met mijn laptop op schoot."}
    co_proposal: {id: rachid_backup, text: "Als Rachid het leert, wil ik het wel elke ochtend doen. Dan zie ik het werk ook eens stromen in plaats van stapelen."}
    outcomes:
      commitment: "Afgesproken. Elke ochtend. En jij regelt die token."
      partial: "Ik wil het wel. Maar niet zolang ik de enige ben."
      heard: "Je bent de eerste die naar de Molen vraagt."
      compliance: "Als het moet. Dan doe ik het elke dag. Tot ik ziek ben."
      ruined: "Dus ik doe het al elf jaar fout. Fijn om te horen."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +8 61 (interest) > show_data +10 71 > empathy +6 77 (lead-in, cue)
    #        > silence +12 > 81 capped (concern) > propose rachid_backup +8 89 > ask: commitment (8 moves)
    # other routes: inquiry at the lead-in; the shorter_login experiment plus daily_run (a partial; a retry with rachid_backup upgrades it).
    # Lean: her batch is rational. With a 15-minute set-up, a monthly run IS cheaper for her. Set-up reduction (shorter_login) makes
    #   small batches pay; a backup removes the single point of failure the batch was hiding. heard:petra_alone is read in Act III
    #   (Petra's sick week) and by the skills-matrix option.
```

### 6.2 Side missions

Shorter: sides are small (the audit's "four ones").

```yaml
dialogs:
  - id: henk_camera
    person: henk
    kind: persuade
    mission: save_henks_knowledge          # deadline mission: a ruined talk costs a day of Henk's clock (spec §4.5)
    owns: knowledge_drain
    patience: 10
    # start: craftsman 40 + 0 + 0 + 0 + 0 = 40, Luistert
    opening: "Je komt zeker voor die camera. Jongen, ik zeg het maar meteen."
    position: {text: "Ik laat me niet filmen.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [inquiry, open_question, paraphrase]
        text: "Wat ik weet, zit in m'n handen. Niet in m'n mond. Je ruikt of een mof vocht heeft. Je voelt aan de kabel of hij van voor '70 is. Dat zie je niet op een filmpje."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "Kijk, het is niet dat ik niet wil…", tags: [hesitation]}
        text: "Ik ben bang dat ze straks een filmpje van mij hebben en denken: klaar, Henk is geregeld. En dat ze die jongen, Ahmed, 's nachts alleen naar Nova-Oud sturen met een tablet. Die jongen is goed. Maar hij is nog niet klaar."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'Dit vak leer je niet uit een boek. Je leert het naast iemand die het kan, tot je het zelf doet en hij alleen nog kijkt.'"}
          facts: [heard:henk_teach]          # needed by twi_job_instruction (spec §4.3)
          proposals: [teach_ahmed_four_steps]
    reframe: "Vanuit Ahmed? … Die staat om twee uur 's nachts in de regen bij een kabel die ouder is dan z'n vader. Met een filmpje. Nee."
    warning: "Ik ga zo naar huis, hè."
    data: ["knowledge_drain:2"]
    lines:
      show_data:
        lands: "Twee keer zo vaak opnieuw zoeken. Ja. Die oude netten liggen nergens zoals op de kaart."
        misses: "Cijfers. Ik heb een kabel nodig, geen cijfers."
      inquiry: {say: "Hoe weet je eigenlijk dat een mof vocht heeft, voordat je hem openmaakt?"}
    proposals:
      - {id: hands_only_video, addresses: [], label: "Alleen je handen filmen",
         say: "Dan filmen we alleen je handen, niet jou.",
         reply: "M'n handen. En wie vertelt dat filmpje wat 't moet doen als het anders loopt dan op het filmpje?"}
      - {id: buddy_nights, addresses: [concern], label: "Ahmed rijdt mee",
         say: "Wat als Ahmed de komende weken bij elke storing in de oude wijken met je meegaat?",
         reply: "Meegaan is goed. Maar meegaan is kijken. Kijken is nog niet kunnen."}
      - {id: teach_ahmed_four_steps, hidden: true, addresses: [concern], label: "Henk leert het Ahmed zoals hij het zelf leerde",
         say: "Hoe leerde jij het vroeger? Wat als je het Ahmed precies zo leert: jij doet het voor, hij doet het na terwijl jij kijkt, en op het eind doet hij het alleen en bel jij hem de dag erna.",
         reply: "Zo heeft ouwe Toon het mij geleerd. In 1984. Ja. Zo."}
    co_proposal: {id: teach_ahmed_four_steps, text: "Laat 'm de komende nachten met mij meerijden. Eerst doe ik het. Dan doet hij het en ik kijk. En de laatste week zit ik in de bus en doet hij het alleen."}
    outcomes:
      commitment: "Afgesproken. Maar ik bepaal wanneer hij klaar is. Niet de planning."
      partial: "Ik doe mee. Als die jongen niet alleen de nacht in gaat voordat ik zeg dat het kan."
      heard: "Jij bent de eerste die vraagt hoe ik het geleerd heb."
      compliance: "Zet die camera dan maar neer. Ik zeg niks."
      ruined: "Film dan maar wat je wilt. Zonder mij."
    # route: open question +6 46 > paraphrase +7 53 (heard) > inquiry +12 (craftsman x1.5) > 64 capped (interest)
    #        > reflect +10 74 (lead-in, cue) > silence +12 > 81 capped (concern) > propose teach_ahmed_four_steps +8 89 > ask: commitment (7 moves)
    # other routes: inquiry again at the lead-in ("En wat als hij het verkeerd ruikt?"); buddy_nights also addresses the concern.
    # Lean: teach_ahmed_four_steps is TWI Job Instruction in Henk's words (prepare, present, try out, follow up).
    #   Videos (hands_only_video) can still be chosen as the countermeasure; Henk then complies, buy-in x0.6, and his concern stays.

  - id: linda_replanning
    person: linda
    kind: persuade
    mission: fix_planning_reshuffle
    owns: planning_reshuffle
    mood: moe
    patience: 9                            # overloaded 10 - 3 - 2 = 5; +4 authored: she sits down once someone asks
    # start: overloaded 35 - 10 + 0 + 0 + 0 = 25, Op z'n hoede
    opening: "Als het over de planning gaat: die klopt niet. Hij klopt nooit. Ga zitten, als je een stoel vindt."
    position: {text: "Ik werk harder dan ooit, en het wordt alleen maar erger. Een op de drie klussen schuift.", tags: [claim]}
    layers:
      - id: interest
        at: 45
        via: [open_question, paraphrase, inquiry]
        text: "Om tien uur komt er een storing, dan gaan er twee monteurs weg en vallen er zes klanten om. Elke dag. Mijn kaartenhuis."
        tags: [claim, feeling]
      - id: concern
        at: 66
        via: [reflect, empathy, silence]
        lead_in: {text: "En als ik ruimte inplan…", tags: [hesitation]}
        text: "…dan zit er om twee uur een monteur koffie te drinken omdat er toevallig geen storing was. En dan zegt Marco dat ik niet kan plannen. Dan plan ik liever 's avonds om, als de kinderen slapen."
        tags: [admission]
        unlocks: {facts: [heard:linda_buffer], proposals: [daytime_crew_with_marco]}
    reframe: "Vanuit de klant die om acht uur vrij heeft genomen? Die ziet geen storing. Die ziet niemand."
    warning: "Sorry. Ik moet dit kaartenhuis voor morgen nog overeind krijgen."
    data: ["planning_reshuffle:0", "planning_reshuffle:2"]
    proposals:
      - {id: jobs_after_noon, addresses: [interest], label: "Klussen na twaalven",
         say: "Plan de klantafspraken na twaalven, als de ochtendstoringen meestal voorbij zijn.",
         reply: "Na twaalven. Hm. Dat kan ik zelf."}
      - {id: daytime_crew_with_marco, hidden: true, addresses: [concern], label: "Een storingsploeg overdag, met Marco",
         say: "Een maand lang twee monteurs per dag vrij voor storingen. Is het rustig, dan doen ze kleine klussen van een lijstje. En Marco tekent het mee.",
         reply: "Marco tekent mee. Dan is het niet mijn idee als er iemand koffie drinkt."}
    experiments:
      - {id: buffer_week_counted, addresses: [concern], label: "Eén week ruimte, elke middag geteld",
         say: "Eén week houden we per monteur twee uur vrij, en we tellen elke middag wat ermee gebeurde. Dan heb jij de cijfers als iemand iets zegt.",
         reply: "Met cijfers. Dan hoef ik me niet te verdedigen. Dan laat ik het zien."}
    outcomes:
      commitment: "Goed. Een maand. En ik ga om vijf uur naar huis."
      partial: "Ik probeer het. Als Marco het niet afschiet."
      heard: "Dank je. Je bent de eerste die gaat zitten."
      compliance: "Prima. Nog een regel erbij in het kaartenhuis."
      ruined: "Dus ik plan slecht. Fijn. Dat wist ik al."
    # route: mood +12 (overloaded x1.5) 37 > open question +6 43 > paraphrase +7 50 (heard, interest) > reflect +10 60 > empathy +6 66 (lead-in, cue)
    #        > silence +12 > 75 capped (concern) > propose daytime_crew_with_marco +8 83 > ask: commitment (8 moves)
    # Lean: Kingman, in her words: the fuller the plan, the harder it breaks. Her fear is the honest objection to slack ("idle monteurs").

  - id: dirk_shelf
    person: dirk
    kind: persuade
    mission: fix_wrong_joint
    owns: wrong_joint_in_van
    mood: goed
    patience: 10
    # start: defender 40 + 10 + 0 + 0 + 0 = 50, Luistert
    opening: "Als je een mof zoekt: rij drie, vak twaalf. Ik heb ze gewoon liggen."
    position: {text: "Ik heb ze gewoon liggen. Als ze in de bus missen, moeten ze ze komen halen.", tags: [claim]}
    layers:
      - id: interest
        at: 58
        via: [inquiry, open_question]
        text: "Ik weet niet wat er in die bussen ligt. Ze pakken wat ze pakken. Een bus is een magazijn op wielen, alleen zonder magazijnman."
        tags: [claim]
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "En weet je wat ik hoor…", tags: [hesitation]}
        text: "In de kantine zeggen ze: het magazijn levert te laat. Vierendertig jaar sta ik hier. Er heeft nog nooit een mof ontbroken op die plank. Nooit."
        tags: [admission, feeling]
        unlocks: {facts: [heard:dirk_shelf], proposals: [dirk_fills_bins]}
    reframe: "Vanuit Ahmed, om half drie 's nachts, veertig minuten van rij drie? Ja. Dan is mijn plank ver weg."
    proposals:
      - {id: standard_list, addresses: [interest], label: "Een vaste lijst per bus",
         say: "Een vaste lijst per bus met wat erin hoort.",
         reply: "Een lijst. Die hangt over een maand onder de koffievlekken."}
      - {id: dirk_fills_bins, hidden: true, addresses: [concern], label: "Twee bakjes per mof, Dirk vult",
         say: "Twee bakjes per moftype in elke bus. Is er één leeg, dan legt de monteur het lege bakje bij jou neer, en jij vult het. Jouw plank, in de bus.",
         reply: "Mijn plank, maar dan op wielen. Dan ben ik de magazijnman van die bus ook."}
    experiments:
      - {id: monday_van_check, addresses: [concern], label: "Elke maandag één bus, samen",
         say: "Loop elke maandag één bus na, met de monteur erbij.",
         reply: "Met de monteur erbij. Dan hoort hij het van mij, niet uit de kantine."}
    outcomes:
      commitment: "Doen we. En als er dan nog een mof ontbreekt, wil ik dat lege bakje zien."
      partial: "Prima. Maar ik ga niet elke bus zelf nalopen."
      heard: "Hm. Fijn dat iemand het vraagt."
      compliance: "Als het moet. Ik heb ze gewoon liggen."
      ruined: "Ik heb ze gewoon liggen. Zoek het verder zelf maar uit."
    # route: open question +6 56 > inquiry +8 64 (interest) > paraphrase +7 71 (heard; lead-in, cue) > silence +12 > 79 capped (concern)
    #        > propose dirk_fills_bins +8 87 > ask: commitment (6 moves)
    # Lean: "Ze hebben allebei gelijk" (audit S3): the joint exists; it is not at the point of use. The two-bin kanban gives Dirk the owner role.
```

### 6.3 Expert: Femke for `talk_netplanner`

Experts use topics as layers (spec §3.4): an open question at the threshold gives the open reply, a closed one the short reply. Base openness 60, so the topics flow; the craft is asking open questions, not winning anyone over.

```yaml
dialogs:
  - id: femke_netplanner
    person: femke
    kind: expert
    mission: talk_netplanner
    opening: "Vijf minuten. Ik heb vijf minuten. … Nee, grapje. Kom maar. Koffie?"
    topics:
      - id: net_vol
        ask: "Wat betekent het eigenlijk, dat het net vol is?"
        open: "Kijk. Een kabel of een trafo kan een bepaalde stroom aan. Wordt hij warmer dan hij hebben kan, dan slijt hij harder of springt de beveiliging. 'Vol' betekent: op het drukste kwartier van het jaar zitten we aan die grens. De andere achtduizend uur is er vaak ruimte zat. Dat is het rare eraan."
        closed: "Dat er geen ruimte meer is."
        teaches: [netcongestie]
      - id: gelijktijdigheid
        ask: "Hoe reken je uit wat een wijk nodig heeft?"
        open: "Met gelijktijdigheid. Niet iedereen kookt tegelijk. Een middenspanningsruimte uit de jaren tachtig is ontworpen op zo'n anderhalve kilowatt per woning, tegelijk. Een warmtepomp vraagt er op een koude avond zo'n drie. Zet er een laadpaal naast en je voelt hem al. Een trafo is net een mens: een piek kan hij aan, een hele avond niet."
        closed: "Met een rekenmodel."
        teaches: [middenspanningsruimte, transformator]
        sector_clue: {problem: grid_study_queue, text: "Een middenspanningsruimte uit de jaren tachtig is ontworpen op ongeveer 1,5 kW gelijktijdig per woning; een warmtepomp vraagt op een koude avond ongeveer 3 kW."}   # estimate, as in the catalogue §2.10 example; verify against a DSO design guideline
      - id: wachtrij
        ask: "Waarom staan er zoveel bedrijven in de wachtrij, en wie mag eerst?"
        open: "Omdat iedereen tegelijk van het gas af wil, en wij het net niet zo snel verzwaren als de vraag groeit. Landelijk stonden er in de zomer van 2025 ruim veertienduizend grootverbruikers in de rij. En sinds 1 juli komen in volle gebieden ook huishoudens die zwaarder willen achteraan. Wie eerst mag? Wie het net ontlast. Dan zorg, veiligheid, drinkwater. Dan woningbouw en scholen. De rest op volgorde."
        closed: "Omdat het net vol is."
        teaches: [netcongestie, maatschappelijk_prioriteren]
    closing: "En als je wil weten hoe het écht zit: kom eens kijken bij mijn bord. Vijf minuten werk, als ik eraan toekom."   # plants look_at_grid_study
```

### 6.4 Grounding, Act I

- **"Veel warmtepompen kunnen al op een gewone aansluiting draaien"**: grid operators stress that not everyone needs a heavier connection, and that many heat pumps and chargers work on the current one (Liander via Overstappen.nl, 2026; NOS on the rush for heavier connections). The El Amrani proposal sends a monteur to *check*; it promises nothing.
- **Fourteen thousand in the queue (Femke):** 14,044 large-consumer requests on the MS/LS queue of the regional DSOs on 1 July 2025 (minister's letter, Kamerstuk 29023; Netbeheer Nederland half-year report 2025). Small-consumer waits rose to 43–44 weeks in 2025.
- **Households on the same list from 1 July 2026, and who goes first:** Gemeente Den Haag; KHN; ANP 24 July 2026 (via Welingelichte Kringen); RVO "Voorrang op elektriciteitsnet". The order: congestion relievers, then health, safety, infrastructure and drinking water, then housing and education. The ACM's first framework was annulled by the CBb on 11 March 2025 (ECLI:NL:CBB:2025:145) and a renewed one applies from 1 January 2026. **Calendar caveat:** if the game's calendar does not run in 2026, Femke's "sinds 1 juli" becomes "binnenkort".
- **1.5 kW per home, simultaneous**: an estimate already used in the catalogue (§2.10); verify against a DSO design guideline before release.
- **TWI Job Instruction** (Henk's four steps): War Manpower Commission manuals, 1940s (audit §2.3).
- **Set-up time makes batches rational** (Petra): standard Lean (SMED, Shingo). The 15 minutes and the two tokens are an estimate.
- **Kingman** (Linda): Hopp & Spearman, *Factory Physics* (audit §2.3).

---
## 7. Act II — Wat onder de grond zit

Order as in the audit's Q1 recommendation: Graafschade opens the act, De revisieberg follows. `joost_output_kpi` is §3.3.

```yaml
dialogs:
  - id: gert_klic
    person: gert
    kind: persuade
    mission: fix_digging_damage            # safety: true (audit §2.4.1)
    mood: gespannen
    patience: 10
    # start: defender 40 - 5 + 0 (an outside partner: no team trust) + 0 + 0 = 35, Op z'n hoede
    opening: "Ik heb mijn verzekeraar al gebeld, als je daarvoor komt."
    position: {text: "Ik heb gewoon een KLIC-melding gedaan. Volgens de kaart lag hier niks.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Proefsleuven graven kost tijd, en die tijd staat niet in de planning van mijn opdrachtgever. Die betaalt per meter. Als ik bij elke kabel ga zoeken, ben ik de duurste van de regio."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "Weet je wat het is…", tags: [hesitation]}
        text: "In 2019 stond ik ernaast toen een jongen van ons een middenspanningskabel raakte. Een flits, en hij lag. Hij leeft nog. Maar ik slaap er slecht van, elke keer dat er een schop de grond in gaat. En dan zegt Voltana dat het mijn schuld is."
        tags: [admission, feeling]
        unlocks:
          clue: {key: true, depth: 1, text: "'Die kabel lag twee meter verder dan op mijn KLIC. Jullie monteur zei: die is in het voorjaar verlegd. Op mijn kaart stond nog de oude ligging.'"}
          facts: [heard:gert_safety]
          proposals: [stop_and_call_near_ms, first_metre_together]
    reframe: "Vanuit de mensen in De Linde? … Die zaten op een aggregaat omdat ik op een kaart vertrouwde. Ja. Dat is ook niet niks."
    warning: "Moet ik mijn advocaat erbij halen?"
    data: ["digging_damage:2"]
    lines:
      show_data:
        lands: "De helft lag anders dan op de kaart? Dus het ligt niet aan ons. … Al raak je hem dan nog steeds."
        misses: "Dus jullie gaan het met cijfers op mij schuiven."
      confront:
        say: "Jullie graven gewoon te snel."
        any: "Ik graaf al dertig jaar. Ik heb meer kabels gezien dan jullie kaart."
      pressure:                            # the safety exception (spec §4.2): containment by pressure carries no buy-in penalty
        say: "Tot we weten waar die kabels liggen, graaft niemand binnen twee meter van een middenspanningskabel. Dat is geen verzoek."
        any: "… Oké. Dat snap ik eigenlijk wel."
    proposals:
      - {id: trenches_in_the_order, addresses: [interest], label: "Proefsleuven in de opdracht",
         say: "Wat als Voltana bij elke opdracht vooraf aangeeft waar proefsleuven nodig zijn, en jouw opdrachtgever die in de planning moet opnemen?",
         reply: "Als het in de opdracht staat, betaalt hij het. Dan ben ik niet de duurste."}
      - {id: stop_and_call_near_ms, hidden: true, addresses: [concern], label: "Bij middenspanning: eerst bellen",
         say: "Binnen twee meter van een middenspanningskabel: eerst bellen, en een monteur van ons wijst ter plekke aan. Vanaf morgen.",
         reply: "Vanaf morgen. … Dan hoeft mijn jongen niet te gokken."}
      - {id: first_metre_together, hidden: true, addresses: [concern], label: "De eerste meter samen",
         say: "Laat onze monteur en jouw uitvoerder bij de eerste meter samen kijken. Vijf minuten.",
         reply: "Samen. Dan zie jij ook eens hoe het op straat gaat."}
    co_proposal: {id: first_metre_together, text: "Laat jullie monteur en mijn uitvoerder bij de eerste meter samen kijken. Vijf minuten. Dan weten we het allebei."}
    outcomes:
      commitment: "Afgesproken. En als jullie kaart weer niet klopt, wil ik dat ook horen. Niet alleen ik van jullie."
      partial: "Ik doe mee. Als het in de opdracht komt te staan."
      heard: "Je bent de eerste van Voltana die vraagt hoe het met mijn jongens gaat."
      compliance: "Als het moet voor het contract."
      ruined: "Dan zie ik je bij de rechter. Ik heb gewoon een melding gedaan."
    # route: mood +8 43 > open question +6 49 > paraphrase +7 56 (heard, interest) > show_data +10 66 > empathy +6 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose stop_and_call_near_ms +8 87 > ask: commitment (8 moves)
    # other routes: reflect for empathy; first_metre_together; trenches_in_the_order (a partial, upgraded on a retry).
    # trap: confront (R4: blaming an outside partner costs his trust and reputation -1; the debrief variant 'blamed').
    # The concern's clue points upstream to Revisie & GIS: the cliffhanger into fix_revision_backlog, through a person.

  - id: mieke_redraw
    person: mieke
    kind: persuade
    mission: fix_revision_backlog
    owns: revision_backlog
    mood: gespannen                        # since the cable strike, everyone looks at GIS
    patience: 10
    # start: craftsman 40 - 5 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Als je komt voor de kabel van Gert: die zat in de doos. Ergens tussen juni en nu."
    position: {text: "We tekenen ze over zo snel als we kunnen. Tweehonderdveertig schetsen. Met z'n tweeën.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [inquiry, open_question, paraphrase]
        text: "Het tekenen is het probleem niet. Het uitzoeken. Welke kabel, welke mof, wat bedoelt hij met dat pijltje? Deze is op een broodzakje getekend. Met pindakaasvlek."
        tags: [claim, feeling]
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En nu wil iedereen…", tags: [hesitation]}
        text: "…dat de monteur het zelf intekent op een tablet. Prima. Maar wat zijn wij dan nog? Ik doe dit zesentwintig jaar. Ik zie aan een schets of een monteur haast had. En sinds die graafschade kijkt het hele gebouw naar GIS, alsof wíj die kabel hebben verlegd."
        tags: [admission]
        unlocks: {facts: [heard:mieke_craft], proposals: [mieke_sets_the_standard, mieke_rides_along]}
    reframe: "Vanuit Gert? Die graaft op mijn kaart. Op mijn kaart van vier maanden geleden. … Ja."
    warning: "Ik heb hier een doos die niet kleiner wordt van praten."
    data: ["revision_backlog:0", "revision_backlog:2"]
    lines:
      show_data:
        lands: "Anderhalf uur per schets, waarvan een uur uitzoeken. Ja. Dat klopt precies."
        misses: "Ja, er staan er 240 open. Dat weet ik. Ik zie de doos elke dag."
    proposals:
      - {id: tablet_at_source, addresses: [interest], label: "De monteur tekent in op de dag zelf",
         say: "De monteur tekent het as-built in op de dag zelf, met foto's en maten.",
         reply: "En wie controleert of het klopt?"}
      - {id: daily_template, addresses: [interest], label: "Een vast sjabloon",
         say: "Een vast sjabloon voor de schets, elke dag ingeleverd.",
         reply: "Een sjabloon helpt. Een broodzakje is ook een sjabloon, als je het vriendelijk bekijkt."}
      - {id: mieke_sets_the_standard, hidden: true, addresses: [concern], label: "Mieke bepaalt wat een goed as-built is",
         say: "Wat als jij bepaalt wat een goed as-built is? Jouw A4 met wat er altijd mist. En jouw team controleert, in plaats van over te tekenen.",
         reply: "Controleren in plaats van overtekenen. Dan zijn wij… de kwaliteit. Niet de achterstand."}
      - {id: mieke_rides_along, hidden: true, addresses: [concern], label: "Mieke loopt een dag mee met de monteurs",
         say: "Loop één dag met de monteurs mee, en neem je A4 mee.",
         reply: "Een dag op straat. Ik ben in twintig jaar niet bij een oplevering geweest."}
    co_proposal: {id: mieke_rides_along, text: "Laat mij één dag met de monteurs meelopen. Dan zie ik waarom het pijltje een pijltje is. En dan leer ik ze wat ik nodig heb."}
    outcomes:
      commitment: "Afgesproken. En het broodzakje lijst ik in. Als laatste van zijn soort."
      partial: "Ik wil het proberen. Als de monteurs het ook willen."
      heard: "Je bent de eerste die vraagt wát we eigenlijk doen."
      compliance: "Als het moet. Dan teken ik wat er komt."
      ruined: "Dus GIS is het probleem. Dank je. Dat hoorde ik al in de kantine."
    # route: mood +8 43 > open question +6 49 > inquiry +12 (craftsman x1.5) 61 (interest) > reflect +10 71 (heard)
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose mieke_sets_the_standard +8 89 > ask: commitment (8 moves)
    # Lean: the work is done twice; capture at the source removes the backlog AND the errors, and the expert becomes the owner of quality.
    #   standardised:revision_backlog with Mieke's commitment is what the Act V audit remembers (audit §3 M6).

  - id: femke_triage
    person: femke
    kind: persuade
    mission: fix_grid_study_queue
    owns: grid_study_queue
    mood: moe                              # 38 studies, long days
    patience: 9                            # craftsman 10 - 2 (moe) = 8; +1 authored
    # start: craftsman 40 - 10 + 0 + 1 (trust 55, from talk_netplanner) + 0 = 31, Op z'n hoede
    opening: "Vijf minuten werk, als ik eraan toekom. Dat zeg ik nu over alles. Sorry. Ga zitten."
    position: {text: "We hebben twee analisten extra nodig. Achtendertig studies op het bord.", tags: [claim]}
    layers:
      - id: interest
        at: 52
        via: [inquiry, open_question, paraphrase]
        text: "Bij de meeste studies weet ik na vijf minuten al dat het past. Daarna reken ik nog vier uur, omdat de werkinstructie het zegt. En die school in Nova-Oost wacht."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [inquiry, silence, empathy]
        lead_in: {text: "Maar…", tags: [hesitation]}
        text: "Als ik een snelle check doe en ik zit ernaast, en er brandt in februari een station door, dan staat mijn naam eronder. Niemand heeft ooit gezegd dat het mag. En die werkinstructie… die heb ik zelf geschreven. In 2019. Toen vroeg bijna niemand 3x35."
        tags: [admission]
        condition: "Ik doe het. Maar het moet op papier, met een handtekening van boven mij."
        unlocks:
          clue: {key: true, depth: 2, text: "'De grens van 3x25A in de werkinstructie komt uit 2019, toen bijna niemand zwaarder vroeg. Nu vraagt bijna elke warmtepompklant meer.'"}
          facts: [heard:femke_authority]
          proposals: [signed_triage_rule]
    reframe: "Vanuit de school? Negen weken wachten op een antwoord dat ik in vijf minuten had kunnen geven. … Ja. Dat is eigenlijk niet te verdedigen."
    warning: "Ik moet echt verder rekenen."
    data: ["grid_study_queue:0", "grid_study_queue:4"]
    lines:
      show_data:
        lands: "Vier uur tegen een kwartier. Ja. Ik weet het. Ik zie het elke dag gebeuren."
        misses: "Ik weet hoe lang een studie duurt. Ik maak ze."
    proposals:
      - {id: two_analysts, addresses: [], label: "Twee analisten erbij",
         say: "Twee extra analisten.",
         reply: "Als je ze kunt vinden. Heel Nederland zoekt ze."}
      - {id: fast_lane, addresses: [interest], label: "Een snelle check, alleen het twijfelgeval volledig",
         say: "Een snelle check van een kwartier voor alles onder een grens. Alleen wat niet zeker past, krijgt de volle studie.",
         reply: "Een snelweg. Ja. Maar wie bepaalt de grens?"}
      - {id: signed_triage_rule, hidden: true, addresses: [concern], label: "Jij schrijft de grens, Ruud tekent",
         say: "Jij schrijft de nieuwe grens, en ik zorg dat Ruud hem tekent. Dan is het de regel van Voltana, niet jouw gok.",
         reply: "Ruud tekent. Dan… ja. Dan durf ik."}
    experiments:
      - {id: one_in_ten_check, addresses: [concern], label: "Eén op de tien toch volledig",
         say: "Een maand de snelle check, en bij één op de tien doet een collega toch de volle studie. Om te zien of je ernaast zat.",
         reply: "Eén op de tien nalopen. Dan weet ik het zeker. Dat is gewoon goede techniek."}
    co_proposal: {id: signed_triage_rule, text: "Ik schrijf de grens. Op basis van de vrije ruimte per station, niet per aansluiting. Dat had ik in 2019 al moeten doen."}
    outcomes:
      commitment: "Afgesproken. En die twee analisten: die vraag ik over een halfjaar opnieuw. Als het dan nog nodig is."
      partial: "Ik wil het. Maar niet zonder handtekening."
      heard: "Fijn dat je even bleef. Echt."
      compliance: "Prima. Op jouw verantwoording dan."
      ruined: "Dus ik reken te veel. Fijn. Dan reken ik vanaf nu niks meer zonder brief."
    # route: mood +8 39 > open question +6 45 > paraphrase +7 52 (heard, interest) > reflect +10 62 > inquiry +12 (craftsman) 74 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose signed_triage_rule +8 87 > ask: commitment (8 moves)
    # other routes: show_data at 62 (+10 lands) instead of inquiry; inquiry right after the interest misses (+3): the concern is still 18 away.
    #              the one_in_ten_check experiment (it addresses the concern by making the risk visible).
    # Lean: exploit before elevate (TOC); she says it herself in the commitment line. Psychological safety: a rule nobody may change.

  - id: rob_order_rule
    person: rob
    kind: persuade
    mission: fix_transformer_wait
    owns: transformer_wait
    patience: 10
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    # Rob says 'u' until he is Open; his commitment line is the first 'je'.
    opening: "Als het over de trafo's gaat: ik heb de procedure voor u uitgeprint."
    position: {text: "Zonder goedgekeurd ontwerp geen bestelling. Zo staat het in de inkoopprocedure.", tags: [claim]}
    layers:
      - id: interest
        at: 52
        via: [inquiry, open_question, paraphrase]
        text: "Een trafo is veel geld en een half jaar levertijd. Bestelt u de verkeerde maat, dan staat hij een jaar in het magazijn. Een dure kapstok."
        tags: [claim]
      - id: concern
        at: 70
        via: [inquiry, silence, empathy]
        lead_in: {text: "Er is een reden dat die regel er staat.", tags: [hesitation]}
        text: "In 2022 hebben we twee 630's besteld voor een project dat uiteindelijk 400 werd. De accountant schreef het in zijn rapport. Met mijn naam. Ik ben niet tegen sneller. Ik ben tegen nog een keer."
        tags: [admission]
        unlocks: {facts: [heard:rob_audit], proposals: [standard_sizes]}
    reframe: "Vanuit die kopers in De Boomgaard? Die hebben hun huur opgezegd. En wij hebben een regel die zegt: wacht maar. Hm."
    warning: "Als u de procedure wilt wijzigen, loopt dat via de directie."
    data: ["transformer_wait:0", "transformer_wait:2"]
    lines:
      show_data:
        lands: "Zeven maanden doorlooptijd, waarvan twee weken werk in de straat. Dus de rest is… wachten op ons eigen papier."
        misses: "Cijfers zonder procedure zijn een mening."
    proposals:
      - {id: order_at_study, addresses: [interest], label: "Bestellen zodra de netstudie het zegt",
         say: "Bestel de trafo zodra de netstudie zegt dat hij nodig is, niet pas na het goedgekeurde ontwerp.",
         reply: "En als de maat dan nog verandert? Dan sta ik weer in het rapport."}
      - {id: standard_sizes, hidden: true, addresses: [concern], label: "Drie standaardmaten",
         say: "Wat als we drie standaardmaten afspreken? Zodra de netstudie een maat kiest, bestellen we die. Een standaardmaat kun je altijd bij het volgende project kwijt.",
         reply: "Drie maten. Een 400 die we niet nodig hebben, gaat naar het volgende project. Dat is geen kapstok. Dat is voorraad."}
      - {id: framework_contract, addresses: [interest], label: "Een raamcontract met de fabrikant",
         say: "Een raamcontract met de fabrikant: vaste productieplekken, en wij roepen per project af.",
         reply: "Een raamcontract gaat via een aanbesteding. Dat duurt. Maar het is netjes."}
    experiments:
      - {id: one_project_you_evaluate, addresses: [concern], label: "Eén project, Rob beoordeelt",
         say: "Eén project, De Boomgaard: bestellen na de netstudie, in een standaardmaat. U schrijft zelf de evaluatie.",
         reply: "Eén project, en ik schrijf de evaluatie. Daar kan ik mee leven."}
    co_proposal: {id: standard_sizes, text: "Als ik die drie maten in de procedure mag zetten. Met mijn naam eronder. Dan staat er een keer iets goeds van mij in een rapport."}
    outcomes:
      commitment: "Afgesproken. Ik pas de procedure aan. En die uitdraai mag je houden; die klopt vanaf maandag niet meer."
      partial: "Ik wil het wel. Maar niet zonder standaardmaten."
      heard: "U bent de eerste die vraagt wáárom die regel er staat."
      compliance: "Als de directie het wil, bestel ik. Op uw naam."
      ruined: "Ik volg de procedure. Als u die wilt veranderen, loopt dat via de directie."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound x1.5) 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > experiment +9 (rule_bound x1.5) 88 > ask: commitment (7 moves)
    # other routes: standard_sizes; inquiry at the lead-in ("Wat ging er toen mis?").
    # Lean (audit L9): ordering before the approved design carries a wrong-size risk; standard sizes make that risk small.
    #   Waits in series that could run in parallel. The data lands hard on a rule-bound person: numbers are his language.

  - id: thomas_reclaim
    person: thomas
    kind: persuade
    mission: fix_unused_capacity
    owns: unused_capacity
    patience: 10
    # start: defender 40 + 0 + 0 + 1 (trust 55, from sector_congestion_map) + 0 = 41, Luistert
    opening: "Als je komt om mijn klanten capaciteit af te pakken: ik heb om drie uur een lunch op de Kanaalzone."
    position: {text: "Ik ga mijn klanten niet vragen capaciteit in te leveren. Ze hebben een contract. Dat is hun recht.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Logistiek Zuid heeft twee megawatt omdat ze willen uitbreiden. Over twee jaar, misschien. Als ik dat nu afpak en ze groeien, staan zíj in de rij."
        tags: [claim]
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "Kijk, het is…", tags: [hesitation]}
        text: "Ik ken die mensen twintig jaar. Ik was bij hun opening, bij de begrafenis van de oude Van Hal. Als ik nu bel om iets af te pakken, ben ik de man die afpakt. Dan bellen ze mij nooit meer als eerste."
        tags: [admission]
        unlocks: {facts: [heard:thomas_relations], proposals: [offer_a_cbc]}
    reframe: "Vanuit Ilse? Die staat om vier uur 's nachts bij gasovens van 1998, naast een lege hal met twee megawatt. … Ja. Dat zou ik ook niet kunnen uitleggen."
    warning: "Mijn klanten zijn geen spreadsheet."
    data: ["unused_capacity:0", "unused_capacity:2"]
    lines:
      show_data:
        lands: "Tweeënzestig procent. Op het drukste kwartier van het jaar. Dus de rest staat er voor… voor de zekerheid."
        misses: "Een gemiddelde. Mijn klanten zijn geen gemiddelde."
    proposals:
      - {id: reclaim_by_the_rules, addresses: [interest], label: "Terugvragen, volgens de ACM-regels",
         say: "Wie structureel veel minder gebruikt dan hij gecontracteerd heeft, krijgt het verzoek een deel terug te geven. Volgens de regels van de ACM en het contract.",
         reply: "Volgens de regels. Ja. Maar ík ben degene die belt."}
      - {id: usage_dashboard, addresses: [interest], label: "Klanten zien hun eigen gebruik",
         say: "Laat klanten elk kwartaal zien wat ze gebruiken tegenover wat ze hebben.",
         reply: "Dat zou ik zelf ook weleens willen zien, eerlijk gezegd."}
      - {id: offer_a_cbc, hidden: true, addresses: [concern], label: "Bellen met een aanbod",
         say: "Bel ze niet om iets af te pakken, maar met een aanbod: een capaciteitsbeperkingscontract. Ze houden hun contract, en krijgen betaald als ze op de drukste uren minder afnemen.",
         reply: "Ik bel om ze geld te bieden. Dat is een heel ander gesprek."}
    experiments:
      - {id: ask_one_customer, addresses: [concern], label: "Eén klant bellen, alleen met een vraag",
         say: "Bel één klant die je goed kent, en vraag alleen hoe ze hun capaciteit gebruiken. Geen verzoek. Een vraag.",
         reply: "Een vraag. Dat kan ik. Dat doe ik al twintig jaar."}
    co_proposal: {id: offer_a_cbc, text: "Laat mij de eerste drie bellen. Ik weet wie ruimte heeft en wie niet. Logistiek Zuid niet als eerste; die zitten midden in een herfinanciering."}
    outcomes:
      commitment: "Afgesproken. Ik bel. Met een aanbod, niet met een rekening."
      partial: "Ik doe mee. Als het in de taal van een aanbod blijft."
      heard: "Fijn dat je het vroeg. De meeste mensen hier zien alleen megawatts."
      compliance: "Goed. Ik stuur ze de brief. Mijn naam staat er niet onder."
      ruined: "Ik bel mijn klanten niet om ze te bedreigen. Ook niet voor jou."
    # route: open question +6 47 > paraphrase +7 54 (heard) > inquiry +8 62 (interest) > show_data +10 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose offer_a_cbc +8 87 > ask: commitment (7 moves)
    # other routes: usage_dashboard as a first step (partial); empathy at the lead-in; the perspective move through Ilse (+8 at >= 50).
    # Sector: reclaiming follows ACM rules and the contract (audit M10); a capaciteitsbeperkingscontract is an existing congestion
    #   management product (tier-2 draft §4.1). Thomas's fear is the account manager's real one.

  - id: ilse_queue
    person: ilse
    kind: persuade
    mission: fix_unused_capacity
    place: congestion.intake               # by phone, 07:30, after her night shift
    mood: gespannen
    patience: 10
    # start: customer_upset 25 - 5 + 0 + 0 + 0 = 20, Op z'n hoede
    opening: "Met Ilse de Graaf. Bakkerij De Graaf. Ik sta hier sinds vier uur, dus maak het kort."
    position: {text: "Twee jaar. Twee jaar sta ik op jullie lijst.", tags: [claim]}
    layers:
      - id: interest
        at: 45
        via: [paraphrase, open_question, inquiry]
        text: "En naast me staat een hal met twee megawatt. Leeg. Leg me eens uit waarom het net vol is."
        tags: [claim, feeling]
      - id: concern
        at: 66
        via: [empathy, silence, reflect]
        lead_in: {text: "Wat ik echt bang voor ben…", tags: [hesitation]}
        text: "Mijn ovens zijn van 1998. Gaat er één kapot, dan koop ik een nieuwe gasoven. Want dat kan wél, morgen. En dan zit ik nog twintig jaar aan het gas. Dat wil ik niet. Mijn dochter wil de zaak overnemen."
        tags: [admission]
        unlocks: {facts: [heard:ilse_lockin], proposals: [night_contract, call_before_gas]}
    reframe: "Vanuit jullie? Ja, ja. Iedereen wil tegelijk. Maar ik bak niet tegelijk. Ik bak als iedereen slaapt."
    warning: "Als je me een folder gaat voorlezen, hang ik op."
    lines:
      reflect:
        lands: {text: "Ja. Ik ben moe. Ik bak al dertig jaar op dezelfde plek, en ik wil gewoon verder.", tags: [claim, feeling]}
    proposals:
      - {id: honest_status, addresses: [interest], label: "Eerlijk zeggen waar ze staat",
         say: "Ik kan geen datum beloven. Wel eerlijk zeggen waar u staat, en u elk kwartaal bellen.",
         reply: "Elk kwartaal. Nou. Dat is meer dan ik nu krijg."}
      - {id: night_contract, hidden: true, addresses: [concern], label: "Een contract voor de nacht",
         say: "U bakt 's nachts, als het net leeg is. Ik ga met onze accountmanager kijken of er een contract kan voor de daluren, zodat u niet hoeft te wachten tot alles verzwaard is.",
         reply: "Een contract voor de nacht. Dan bak ik elektrisch voordat de rest wakker is."}
      - {id: call_before_gas, hidden: true, addresses: [concern], label: "Eerst bellen, dan pas een oven kopen",
         say: "Als een oven het begeeft voordat u aangesloten bent: bel mij, voordat u een gasoven koopt. Dan kijken we samen wat er op uw huidige aansluiting kan.",
         reply: "Bellen voordat ik een gasoven koop. Ja. Dat beloof ik."}
    co_proposal: {id: night_contract, text: "Ik bak om vier uur 's nachts. Is jullie net dan ook vol?"}
    outcomes:
      commitment: "Afgesproken. En als het lukt, krijgt die accountmanager van jullie een krentenbol. Twee."
      partial: "Ik wacht. Maar niet nog twee jaar."
      heard: "Fijn dat er eens iemand luistert in plaats van voorleest."
      compliance: "Ik heb geen keus, hè."
      ruined: "Dan ga ik naar de ACM. En naar de krant."
    # route: empathy +9 29 > paraphrase +10 39 (heard) > open question +6 45 (interest) > reflect +10 55 > paraphrase +10 65
    #        > empathy +9 74 (lead-in, cue) > silence +12 > 75 capped (concern) > propose night_contract +8 83 > ask: commitment (9 moves)
    # Sector: lock-in in the energy transition (a broken oven is replaced by gas because gas is available now); a non-firm (time-bound)
    #   contract for off-peak use on the regional grid (tier-2 draft §2.16 grounding: the non-firm ATO). Her co-proposal is the insight.

  - id: sanne_kpi
    person: sanne
    kind: persuade
    mission: fix_silo_kpis
    kpi_team: intake
    patience: 9
    # start, default: overloaded 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    # start, after sanne_checker ended in commitment: 35 + 10 (team trust intake +1) + 2 (trust 60) + 0 + 15 (memory: committed) = 62, Open
    opening: "Als het over het MT gaat: ja, ik had een recordmaand. Nee, ik weet ook niet waarom er niks meer doorkomt."
    position: {text: "Ik stuur op aanvragen per week. Dat werkt: we halen het.", tags: [claim]}
    layers:
      - id: interest
        at: 55
        via: [open_question, inquiry, paraphrase]
        text: "Elke vrijdag om drie uur tellen we. Nog vier voor het weekdoel? Dan zet je ze door. Ook als de meterkastfoto mist. Dat vraagt Werkvoorbereiding dan maar."
        tags: [claim, feeling]
      - id: concern
        at: 70
        via: [reflect, empathy, silence]
        lead_in: {text: "Alleen…", tags: [hesitation]}
        text: "Als ik op 'compleet doorgezet' ga sturen, zakt mijn aantal per week. Eerst. En dan is Intake weer het postkantoor dat traag is. Ik heb twee jaar gedaan over dat beeld."
        tags: [admission]
        condition: "Ik doe mee. Als Frank het goedvindt. Het jaarplan is van hem."
        unlocks: {facts: [heard:sanne_kpi], proposals: [present_with_joost]}
    reframe: "Vanuit Joost? Die krijgt mijn vrijdagmiddag op maandag op zijn bord. Halve dossiers. Ja. Dat zou ik ook niet leuk vinden."
    warning: "Joh. Niet nu."
    data: ["silo_kpis:3", "silo_kpis:5"]
    lines:
      show_data:
        lands: "'Nog vier voor vrijdag.' Ja. Dat zijn wij. Dat klinkt anders als je het zo terughoort."
        misses: "Mijn cijfers zijn goed. Die van Joost ook. Dat is toch het hele punt?"
    proposals:
      - {id: complete_and_oldest, kpis: [intake_complete, intake_oldest], addresses: [concern], label: "Compleet doorgezet + oudste aanvraag",
         say: "Compleet doorgezet, en de oudste aanvraag in de bak. Allebei getallen die je deze week ziet bewegen.",
         reply: "Die oudste aanvraag… die ligt er nu drie weken. Die kan ik morgen pakken."}
      - {id: lead_and_complete, kpis: [intake_lead_time, intake_complete], addresses: [concern], label: "Doorlooptijd + compleet doorgezet",
         say: "De doorlooptijd van de hele stroom, en compleet doorgezet ernaast.",
         reply: "Eentje kijkt ver vooruit, eentje kijkt naar ons. Oké. Dat is eerlijk."}
      - {id: output_and_complete, kpis: [intake_output, intake_complete], addresses: [concern], label: "Aanvragen per week + compleet doorgezet",
         say: "Houd je aantal per week, en zet compleet doorgezet ernaast.",
         reply: "Dan zie ik ze elkaar bevechten. Maar goed. Dan zie ik het tenminste."}
      - {id: output_and_utilisation, kpis: [intake_output, intake_utilisation], addresses: [], label: "Aanvragen per week + bezettingsgraad",
         say: "Je houdt wat je hebt: aanvragen per week en bezettingsgraad.",
         reply: "Dat is wat ik nu heb. En dat werkt dus niet, hè."}
      - {id: present_with_joost, hidden: true, needs: {any: [heard:joost_kpi]}, addresses: [concern], label: "Samen met Joost presenteren",
         say: "Joost wil het samen met jou presenteren. Eén stroom, niet twee teams.",
         reply: "Joost? Samen? … Dan is het geen postkantoor tegen de ingenieurs. Dan is het één stroom."}
    co_proposal: {id: present_with_joost, text: "Als Joost en ik dezelfde aansluiting volgen, van aanvraag tot monteur. Eén dossier, op het bord. Dan ziet iedereen waar het blijft."}
    condition_needs: {all: [committed:frank_kpi_targets]}
    outcomes:
      commitment: "Afgesproken. En ik zeg het zelf in het MT: ons getal gaat eerst omlaag. Met reden."
      partial: "Ik doe mee. Als Frank het goedvindt. Het jaarplan is van hem."
      heard: "Zo. Dat had ik nog nooit hardop gezegd."
      compliance: "Prima. Weer een getal."
      ruined: "Dus het ligt weer aan de Intake. Natuurlijk."
    beats_after:
      - {when: "committed:frank_kpi_targets", text: "Frank heeft getekend. Joost en ik presenteren donderdag. Samen. Ik ben zenuwachtig, en dat is lang geleden."}
    # route (default start): mood +12 47 > open question +6 53 > paraphrase +7 60 (heard, interest) > reflect +10 70 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > propose complete_and_oldest +8 87 > ask: partial until Frank commits (7 moves)
    # Path dependence: a player who won Sanne's commitment in Act I starts at 62 and needs about four moves. Respect earlier pays now.

  - id: frank_kpi_targets
    person: frank
    kind: persuade
    mission: fix_silo_kpis
    needs: {any: ["partial:joost_output_kpi", "partial:sanne_kpi", "heard:joost_kpi"]}   # opens once a team lead names him
    patience: 8                            # a manager's diary (authored)
    # start: rule_bound 35 + 0 + 0 + 0 + 0 = 35, Op z'n hoede
    opening: "Ik heb een kwartier. Daarna de regiegroep. Gaat het over het jaarplan, dan weet je dat het vastligt."
    position: {text: "Ontwerpen en aanvragen per week staan in het jaarplan. Daar stuur ik op.", tags: [claim]}
    layers:
      - id: interest
        at: 52
        via: [inquiry, open_question, paraphrase]
        text: "Het jaarplan gaat naar de directie, en het aantal aansluitingen per jaar gaat naar de ACM. Dat moet ik kunnen uitleggen. Elk kwartaal."
        tags: [claim]
      - id: concern
        at: 72
        via: [inquiry, silence, empathy]
        lead_in: {text: "En daar komt bij…", tags: [hesitation]}
        text: "In de najaarsronde wordt het budget voor netverzwaring over de regio's verdeeld. Als onze cijfers een kwartaal slechter worden, gaat dat geld naar het westen. Ik ga niet op gevoel een kwartaal gokken met de verzwaring van Zuidmark."
        tags: [admission]
        unlocks:
          clue: {key: true, depth: 2, text: "'De directie vraagt elk kwartaal naar aantallen. Hoe lang een klant wacht, vraagt alleen de ACM. Eén keer per jaar.'"}
          facts: [heard:frank_budget]
    reframe: "Vanuit de ACM gezien… die meet de termijn vanaf de aanvraag. Niet het aantal ontwerpen. Hm. Dat is eigenlijk een ander getal dan het mijne."
    warning: "Ik heb een regiegroep. Kom ter zake."
    data: ["silo_kpis:0", "silo_kpis:2"]
    lines:
      show_data:
        lands: "Twee recordmaanden, en niet één aansluiting meer de deur uit. Dat is geen record. Dat is een rapport."
        misses: "Een kwartaalcijfer is een kwartaalcijfer."
    proposals:
      - {id: keep_targets, addresses: [], label: "De doelen houden zoals ze zijn",
         say: "We houden de doelen zoals ze zijn.",
         reply: "Dat is wat ik heb."}
      - {id: obeya_one_stream, addresses: [concern], label: "Eén kwartaal, één stroom, oude cijfers ernaast",
         say: "Eén kwartaal, alleen de aansluitingenstroom, met de oude getallen ernaast zichtbaar. Als het eerst zakt, zie je ook waarom.",
         reply: "Met de oude ernaast. Dan kan ik het in de regiegroep altijd uitleggen."}
    experiments:
      - {id: obeya_trial, addresses: [concern], label: "Een Obeya op één stroom, zes weken",
         say: "Zes weken een Obeya op de aansluitingenstroom. Sanne, Joost en Marco aan één bord. U komt elke vrijdag kijken.",
         reply: "Elke vrijdag. Tien minuten. En als ik iets zie wat ik niet kan uitleggen, stoppen we."}
    block:
      text: "Ik kan dit niet toezeggen. Laat het me eerst zien."
      routes:
        - {needs: {all: ["checked:silo_kpis"]}, hint: "Laat het me zien op één stroom."}
        - {needs: {all: ["partial:joost_output_kpi", "partial:sanne_kpi", "reputation>=40"]}, hint: "Als Sanne en Joost het zelf komen uitleggen, sta ik er niet alleen voor."}
        - {needs: {all: ["forecast_positive:kpi_board"]}, hint: "Als het bord laat zien dat volgend kwartaal niet slechter wordt."}
    outcomes:
      commitment: "Goed. Ik zet mijn handtekening eronder. En als het eerst slechter wordt, leg ík het uit. Daar word ik voor betaald."
      blocked: "Ik kan dit niet toezeggen. Laat het me eerst zien."
      heard: "Interessant. Kom terug als je iets te laten zien hebt."
      compliance: "Als Ruud het zo wil, staat het in het verslag. Op zijn naam."
      ruined: "Ik heb een regiegroep. Plan maar iets in via mijn secretariaat."
    # route: open question +6 41 > paraphrase +7 48 (heard) > inquiry +8 56 (interest) > show_data +15 (rule_bound x1.5) 71
    #        > empathy +6 77 (lead-in, cue) > silence +12 > 81 capped (concern) > propose obeya_one_stream +8 89 > ask: geblokkeerd (8 moves)
    # After a route is met, the next talk ends in commitment; Joost's and Sanne's partials upgrade by themselves (spec §7.4).
    # AUDIT CHANGE to spec §7.4: route 2 there needs 'committed:ruud_backs_obeya', but Ruud is the coach and not a dialog target,
    #   so that fact can never be set. Replaced by the two team leads' partials: the people bring their boss along.
    # Route 1 (checked:silo_kpis) can never be closed by a failure or a skip: the validator rule of spec §9.2 #11 holds.
```

### 7.1 Grounding, Act II

- **MS strike and test trenches** (Gert): CROW 500 and HR 13 April 2018 (audit §2.3); 7 % of digs in Brabant hit a cable (Omroep Brabant, in GDD). Gert's 2019 accident is fiction.
- **Revision lag** (Mieke): Wibon and KLIC location data (audit M6); 240 sketches and 1.5 h per redraw are the content's estimates.
- **Exploit before elevate** (Femke): Goldratt's five focusing steps (audit L12). The 2019 date is fiction, consistent with the content clue `grid_study_queue:2` (the 3x25A rule in the work instruction).
- **Wrong transformer size** (Rob): audit L9 (standard sizes). The 2022 audit story is fiction. 400 and 630 kVA are common distribution-transformer ratings.
- **Capaciteitsbeperkingscontract** (Thomas) and **non-firm contracts** (Ilse): the tier-2 draft §4.1 and §2.16 grounding (ACM code decisions on alternative transport rights; the non-firm ATO on the regional grid).
- **Budget per region** (Frank): DSO investment plans are reviewed by the ACM every two years (catalogue §3.7, *verify*). The "autumn round" inside Voltana is fiction.

---
## 8. Check-ins: six talks that lift someone's spirit

Check-ins have no mission, no proposal and no XP (spec §5.7). Steering before the concern is "fixing mode" (−12). *Opgebeurd* needs the concern revealed and openness ≥ 70 at `close`. Each one teaches a different listening skill, and each gives back something small: an *observation* (a lead, never a key clue), a fact a later option reads, or an object. Ahmed's is §3.4.

| id | Trigger | The skill it teaches | What it gives back |
|---|---|---|---|
| `anouk_late` | morale < 50 and the R3 overload signal on `work_prep` (≥ 95 % for 14 days), or 18:30+ on a weekday while `fix_custom_design` is open | Perfectionism as fear; empathy after an admission | An observation pointing at the signatures; a variant once the standard designs exist |
| `henk_last_week` | beat `henk_farewell`, 5 days before | Respect at the end of a career; *silence* with a craftsman | His cable knife (D13, if the knowledge was saved by teaching) and `flag:henk_postcards` |
| `esra_after` | morale < 50 after `fix_status_callers` opens | A leader's guilt; the CI lead's honest *experience* | An observation that plants `fix_done_but_not_closed` |
| `petra_after` | morale < 50 after `fix_done_but_not_closed` is resolved | A fix that makes someone's old way look stupid | An observation that plants `fix_silent_meter` |
| `marco_day_100` | beat `review_100_days`, 2 days after | Will it last when you leave? | An observation (the vans), and his own sustain idea |
| `linda_evenings` | morale < 45 and the R3 signal on `planners` | The planner nobody plans for | An observation that plants `fix_planning_reshuffle`, or a quiet thank-you |

```yaml
dialogs:
  - id: anouk_late
    person: anouk
    kind: checkin
    trigger: {morale_below: 50, signal: overload_work_prep}
    patience: 8
    # start: overloaded 35 - 10 (moe) + 0 + 2 (trust 60) - 1 (morale 45) = 26, Op z'n hoede
    opening: "O. Hoi. Ik ben zo klaar, hoor. Nog eentje."    # it is 18:40
    position: {text: "Nee joh, gaat prima. Ik zit erbovenop.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [open_question, inquiry], text: "Het is gewoon druk. Als ik het laat liggen, ligt het er morgen nog. En overmorgen.", tags: [feeling]}
      - id: concern
        at: 65
        via: [reflect, empathy, silence]
        lead_in: {text: "Het is alleen…", tags: [hesitation]}
        text: "Ik denk dat ik langzamer ben dan de rest. Ik kijk alles drie keer na. Als ik tot zeven blijf, ziet niemand dat."
        tags: [admission, doubt]
        unlocks: {facts: [heard:anouk_slow]}
    warning: "Echt, het gaat prima. Ik moet dit even afmaken."
    lines:
      mood: {say: "Hoe gaat het met je? Niet met de bak. Met jou."}
    outcomes:
      lifted: "Ik ga naar huis. Echt. Morgen is er ook nog."
      heard: "Dank je. Echt."
      none: "Ja. Ik ben zo klaar."
    observation: {text: "Weet je wat raar is? Het tekenen gaat snel. Het wachten op handtekeningen niet."}
    variants:
      - needs: {all: ["standardised:custom_design"]}
        mood: goed
        position: {text: "Goed! Echt.", tags: [claim]}
        layers:
          - {id: interest, at: 50, via: [open_question, inquiry], text: "Ik ben om vier uur thuis. Mijn vriend vroeg of ik ontslagen was.", tags: [feeling]}
          - {id: concern, at: 68, via: [reflect, empathy, silence], lead_in: {text: "Alleen…", tags: [hesitation]},
             text: "Joost vroeg of ik de standaardontwerpen wil bijhouden. Voor het hele team. Wat als ik er een fout in zet, en dan doet iedereen het fout?", tags: [admission, doubt],
             unlocks: {facts: [heard:anouk_owner_doubt]}}
        outcomes: {lifted: "Dan zet ik er een versienummer op. En een vakje 'gecontroleerd door'. Mijn vakje."}
        observation: null
    # route: mood +12 (overloaded x1.5) 38 > open question +6 44 > inquiry +8 52 (interest) > reflect +10 62 > empathy +6 68 (lead-in, cue)
    #        > silence +12 > 74 capped (concern) > empathy +10 (after an admission) 84 > close: opgebeurd (8 moves)
    # trap: "Zal ik met Joost praten over je uren?" (propose, fixing mode, -12): she shuts down and stays until seven.
    # The observation is a lead toward the 'documents' clue (three signatures); it is not that clue.

  - id: henk_last_week
    person: henk
    kind: checkin
    trigger: {beat: henk_farewell, before_days: 5}
    patience: 8
    # start: craftsman 40 - 5 (stil) + 0 + 2 (trust 60) + 0 = 37, Op z'n hoede; when his knowledge was saved by teaching: mood goed, 52
    opening: "Kijk wie we daar hebben. Kom je afscheid nemen? Ik ben er nog vijf dagen, hoor."
    position: {text: "Nog vijf dagen. Dan ga ik vissen.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, inquiry], text: "Veertig jaar. Ik heb in elke straat van Nova-Oud een gat gegraven. Ik weet bij elk huis of ze koffie zetten.", tags: [feeling]}
      - id: concern
        at: 68
        via: [silence, reflect, empathy]
        lead_in: {text: "Alleen…", tags: [hesitation]}
        text: "Wat moet ik maandagochtend? Om zes uur ben ik wakker. Altijd geweest. Mijn vrouw zegt: ga vissen. Maar vissen is voor zondag."
        tags: [admission]
    warning: "Ik moet nog een bus uitruimen. Veertig jaar troep."
    lines:
      inquiry: {say: "Welke straat in Nova-Oud vergeet je nooit?"}
    outcomes:
      lifted: "Weet je wat? Kom zaterdag op m'n afscheid. En neem die jonge Ahmed mee. Die moet weten dat het een feest is, geen begrafenis."
      heard: "Dag, jongen. Tot zaterdag."
      none: "Dag."
    variants:
      - needs: {any: ["chose:knowledge_drain:skills_matrix_buddy", "chose:knowledge_drain:twi_job_instruction"]}
        mood: goed
        layers:
          - {id: interest, at: 55, via: [open_question, inquiry], text: "Veertig jaar. En de laatste zes weken waren de beste. Raar, hè.", tags: [feeling]}
          - {id: concern, at: 70, via: [silence, reflect, empathy], lead_in: {text: "Die jongen…", tags: [hesitation]},
             text: "Die jongen kan het. Ik had het niet gedacht, eerlijk gezegd. Vorige week stond ik ernaast en hij had me niet nodig. Dat is een raar gevoel, jongen. Goed raar. Maar raar.", tags: [admission]}
        outcomes: {lifted: "Hier. Dit is van mij geweest. Veertig jaar. Hij is bot. Laat 'm zo."}   # the cable knife (D13's vitrine object)
        sets_flags_on_lifted: [flag:henk_postcards]                                                 # (new) a postcard each act
      - needs: {all: ["chose:knowledge_drain:work_instruction_videos"]}
        layers:
          - {id: interest, at: 50, via: [open_question, inquiry], text: "Ze hebben me gefilmd, uiteindelijk. Twaalf filmpjes.", tags: [feeling]}
          - {id: concern, at: 68, via: [silence, reflect, empathy], lead_in: {text: "Ik heb ze teruggekeken…", tags: [hesitation]},
             text: "Op geen enkel filmpje zie je wat ik ruik. Ik hoop maar dat die jongen het nooit nodig heeft. 's Nachts. Alleen.", tags: [admission, doubt]}
        outcomes: {lifted: "Zeg tegen Ahmed dat hij me mag bellen. Ook om twee uur 's nachts. Ik ben toch wakker."}
    # route: open question +6 43 > inquiry +12 (craftsman) 55 (interest) > reflect +10 65 > empathy +6 71 (lead-in, cue)
    #        > silence +12 > 77 capped (concern) > empathy +10 87 > close: opgebeurd (7 moves)
    # trap: "Je kunt toch als vrijwilliger terugkomen?" (propose, fixing mode). He laughs it off: "Ja, ja." and the talk stays shallow.
    # The videos variant is the quiet cost of the short-term fix, felt through a person, months later. No penalty; only his words.

  - id: esra_after
    person: esra
    kind: checkin
    trigger: {morale_below: 50, after_mission_open: fix_status_callers}
    patience: 8
    # start: defender 40 - 10 (moe) + 0 + 1 (trust 55) - 1 (morale 40) = 30, Op z'n hoede
    opening: "Kom erin. Ik zit hier al een uur naar een rooster te staren."
    position: {text: "Het gaat wel. De wachtrij is groener.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, inquiry], text: "Saskia komt volgende week terug. Halve dagen. Ik weet niet goed wat ik tegen haar moet zeggen.", tags: [feeling]}
      - id: concern
        at: 68
        via: [reflect, empathy, silence]
        lead_in: {text: "Kijk…", tags: [hesitation]}
        text: "Ik had het moeten zien. Ik zat de hele dag naar dat scherm te kijken. Wachttijd, wachttijd. Niet naar haar. Wat voor teamleider ben ik dan?"
        tags: [admission, doubt]
    warning: "Serieus, ik moet dit rooster nog rond krijgen."
    lines:
      experience: {say: "In mijn eerste weken hier keek ik ook vooral naar getallen. Ruud vroeg me toen: wie heb je vandaag gesproken? Ik wist het niet."}
    outcomes:
      lifted: "Weet je wat ik ga doen? Haar eerste dag ga ik gewoon naast haar zitten. Zonder scherm."
      heard: "Dank je. Dit zeg ik niet tegen mijn team, hè."
      none: "Ja. Komt goed."
    observation: {text: "Trouwens: steeds meer mensen bellen over hun EAN. 'Mijn leverancier zegt dat hij niet bestaat.' Dat is nieuw.", plants: fix_done_but_not_closed}
    # route: mood +8 38 > open question +6 44 > paraphrase +7 51 (heard) > inquiry +8 59 (interest) > reflect +10 69 (lead-in, cue)
    #        > silence +12 > 77 capped (concern) > experience +8 85 > close: opgebeurd (8 moves)
    # trap: "Zal ik een cursus stressmanagement voor je team regelen?" Fixing mode, and it puts the problem in her people again.

  - id: petra_after
    person: petra
    kind: checkin
    trigger: {morale_below: 50, after_resolved: done_but_not_closed}
    patience: 8
    # start: defender 40 + 0 + 1 (trust 55) - 1 (morale 45) = 40, Luistert
    opening: "Alles klopt. Tot op de laatste EAN. Ik zeg het maar even, voordat je het vraagt."
    position: {text: "Het gaat goed. Elke ochtend één sessie. De Molen maalt.", tags: [claim]}
    layers:
      - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Rachid kan het nu ook. Hij is sneller dan ik, eerlijk gezegd. Jonge handen.", tags: [feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, reflect]
        lead_in: {text: "Het is alleen…", tags: [hesitation]}
        text: "Nu lijkt het alsof ik het al jaren fout deed. Elf jaar die maandrun. Ik dacht dat ik efficiënt was. En iedereen in de kantine weet dat de EAN's twee weken bij mij lagen."
        tags: [admission]
    warning: "Als je komt controleren: alles klopt."
    lines:
      reflect: {say: "Het klinkt alsof je je schaamt voor iets wat jarenlang logisch was."}
    outcomes:
      lifted: "Elf jaar efficiënt in het verkeerde. Nou ja. Nu twee weken efficiënt in het goede."
      heard: "Hm. Dank je."
      none: "Alles klopt. Echt."
    observation: {text: "Weet je wat ik wel zie, nu ik elke dag kijk? De meters in De Kade sturen niks. Allemaal in die nieuwe flats.", plants: fix_silent_meter}
    variants:
      - needs: {all: ["complied:petra_batch"]}           # the daily run was imposed, with no backup
        layers:
          - {id: interest, at: 55, via: [open_question, inquiry, paraphrase], text: "Elke dag een kwartier opstarten. Het werkt. Voor de klant.", tags: [feeling]}
          - {id: concern, at: 70, via: [silence, empathy, reflect], lead_in: {text: "En als ik ziek word…", tags: [hesitation]},
             text: "Dan ligt het stil. Dat zei ik toch. Niemand heeft geluisterd. Ik werk nu met koorts, want anders zien ze het meteen.", tags: [admission]}
        outcomes: {lifted: "Als je die Rachid toch nog eens vraagt… ik leer het hem graag."}
    # route: open question +6 46 > inquiry +8 54 > paraphrase +7 61 (heard, interest) > reflect +10 71 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > empathy +10 89 > close: opgebeurd (7 moves)
    # Respect: the batch was a rational answer to a 15-minute set-up and a one-person team. Saying so (reflect) is the move that lands.

  - id: marco_day_100
    person: marco
    kind: checkin
    trigger: {beat: review_100_days, after_days: 2}
    patience: 8
    # start: cynic 30 + 10 (goed: the review passed; 0 if it failed) + 0 + 0 + 0 = 40, Luistert
    #   after marco_wasted_trips ended in commitment: + 10 (team monteurs +1) + 2 (trust 60) + 15 (memory) = 67
    opening: "Honderd dagen. Je bent er nog. Dat is al meer dan de vorige twee."
    position: {text: "Het gaat goed bij ons. Minder ritten voor niks.", tags: [claim]}
    layers:
      - {id: interest, at: 50, via: [open_question, inquiry], text: "Mijn mannen vragen wat er nu komt. Ze zijn het niet gewend dat iets blijft.", tags: [feeling]}
      - id: concern
        at: 70
        via: [silence, empathy, inquiry]
        lead_in: {text: "En eerlijk is eerlijk…", tags: [hesitation]}
        text: "Ze vragen of jij blijft. Als jij over een jaar weggaat, hangt dit ook in de gang met de cijfers van 2023. Dan heb ik het ze weer beloofd. Voor niks."
        tags: [admission]
    warning: "Ik moet de bussen in. Kort dan."
    lines:
      experience: {say: "Bij mijn vorige werk hing er ook zo'n bord. Toen de man die het had opgehangen wegging, hing het er nog een jaar. Leeg."}
    outcomes:
      lifted: "Weet je wat. Ik laat Ricardo het bord bijhouden. Niet ik, niet jij. Hij. Dan blijft het."
      heard: "Hm. Ja. We zien wel."
      none: "Goed. Tot ziens."
    observation: {text: "En die bussen van ons: geen twee hetzelfde. Daar zou ik ook eens naar kijken.", plants: fix_wrong_joint, needs: {none: ["done:fix_wrong_joint"]}}
    # route: open question +6 46 > inquiry +8 54 (interest) > reflect +10 64 (heard) > inquiry +8 72 (lead-in, cue)
    #        > silence +12 > 79 capped (concern) > empathy +10 89 > close: opgebeurd (7 moves)
    # experience lands at half for a cynic (+4): the player's line is honest, but Marco trusts what he sees.
    # Sustain: his lifted line is ownership as the sustaining habit, in his words. The game does not reward it; it is his choice.

  - id: linda_evenings
    person: linda
    kind: checkin
    trigger: {morale_below: 45, signal: overload_planners}
    patience: 8
    # start: overloaded 35 - 10 (moe) + 0 + 0 - 1 (morale 40) = 24, Op z'n hoede
    opening: "Ik zit nog even. Het kaartenhuis is weer omgevallen."
    position: {text: "Gaat wel. Morgen is er weer een dag.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [open_question, inquiry], text: "Ik plan 's avonds om. Thuis. Als de kinderen slapen. Anders begint de dag met een gat.", tags: [feeling]}
      - id: concern
        at: 65
        via: [reflect, empathy, silence]
        lead_in: {text: "Mijn dochter vroeg gisteren…", tags: [hesitation]}
        text: "…waarom ik altijd op mijn laptop zit. Ik zei: mama plant de monteurs. Zij zei: en wie plant jou dan? … Ik plan iedereen. Behalve mezelf."
        tags: [admission]
    warning: "Sorry. Nog tien minuten, dan staat het."
    outcomes:
      lifted: "Weet je wat. Vanavond gaat de laptop dicht. Het kaartenhuis valt morgen toch weer om."
      heard: "Dank je. Echt."
      none: "Ja. Morgen weer."
    observation: {text: "Het rare is: de storingen komen altijd tussen tien en twaalf. Altijd. Alsof ze een afspraak hebben.", plants: fix_planning_reshuffle, needs: {none: ["done:fix_planning_reshuffle"]}}
    variants:
      - needs: {all: ["done:fix_planning_reshuffle"]}
        outcomes: {lifted: "Sinds die storingsploeg overdag ga ik om vijf uur naar huis. Bijna altijd. Mijn dochter heeft het gemerkt."}
    # route: mood +12 (overloaded x1.5) 36 > open question +6 42 > inquiry +8 50 (interest) > reflect +10 60 > empathy +6 66 (lead-in, cue)
    #        > silence +12 > 74 capped (concern) > empathy +10 84 > close: opgebeurd (8 moves)
```

---

### 8.1 Walk-around check-ins (decided 2026-10-15)

Merijn's decision: people the player passes while walking around show their energy as a low bar above their head when their morale is low, which invites a short spirit-lifting talk. These are check-ins in the spec's sense (no mission, no XP, no slot), shorter than §8's.

**Shape:**
- **Trigger:** the player walks within a few metres of the person while their morale is below 45. Their bar shows low (an energy bar, not openness: openness only appears once a talk starts).
- **Length:** patience 7. The talk opens with a line the person says while doing something else.
- **Outcome:** *opgebeurd* as in spec §5.7. The reward is small: morale +10, trust +3, sometimes an observation.
- **Respect the player's time** (CLAUDE.md, 2026-10-15): walking past costs nothing. The bar fades after the day, and nobody remembers being ignored.

```yaml
dialogs:
  - id: yvonne_cards
    person: yvonne                         # Yvonne Kok, meterwisselaar (audit §5.3)
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, after_mission_open: walk_meters}
    patience: 7
    # start: quiet 47 - 5 (stil) + 0 + 0 - 1 = 41, Luistert
    opening: "O. Sorry. Ik zat even in de bus. Pauze."
    position: {text: "Gaat prima. Nog vier adressen.", tags: [claim]}
    layers:
      - {id: interest, at: 47, via: [open_question, inquiry], text: "Drie keer vandaag niemand thuis. Drie kaartjes. Ik heb er een hele stapel van in het handschoenenkastje.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, silence, empathy]
        lead_in: {text: "En dan…", tags: [hesitation]}
        text: "Meneer De Jong had een halve dag vrij genomen. Hij was er wel, maar om één uur. Ik kwam om drie uur. Hij schreeuwde tegen mij. Niet tegen de planning. Tegen mij, op de stoep."
        tags: [admission]
    outcomes:
      lifted: "Weet je wat ik eigenlijk zou willen? Dat ze een sms krijgen. 'Yvonne komt tussen twee en vier.' Dan kennen ze mijn naam ook."
      heard: "Dank je. Ik ga weer."
      none: "Ja. Nog vier adressen."
    observation: {text: "Dat ze een sms krijgen met een tijdvak. Dan zijn ze thuis.", plants: fix_not_at_home, needs: {none: ["done:fix_not_at_home"]}}
    # route: open question +6 47 (interest) > reflect +10 57 > empathy +6 63 > inquiry +8 71 (lead-in, cue)
    #        > silence +18 (quiet x1.5) > 74 capped (concern) > close: opgebeurd (6 moves). Trap: silence before the hesitation (-4, awkward).

  - id: kees_night
    person: kees
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, time_of_day: night}   # the control room at night (D9 Nachtdienst may fire on the same visit)
    patience: 7
    # start: craftsman 40 + 0 + 0 + 0 - 1 = 39, Op z'n hoede
    opening: "Je bent laat. Of vroeg. Koffie staat daar; hij is van tien uur."
    position: {text: "Rustige nacht. Twee storingen, allebei hersteld.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [open_question, inquiry], text: "'s Nachts is de wand het enige wat licht geeft. Je ziet een wijk rood worden, en dan weer groen. Dan ben je klaar.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [silence, inquiry, empathy]
        lead_in: {text: "Alleen…", tags: [hesitation]}
        text: "Ik zie alleen dat het licht terugkomt. Nooit waarom het uitging. Twintig jaar zie ik dezelfde straten rood worden. Niemand vraagt mij wat ik zie. Ik ben de man van de knoppen."
        tags: [admission]
    outcomes:
      lifted: "Weet je wat. Ik schrijf het voortaan op, welke straten. Op een briefje naast de wand. Misschien vraagt iemand er ooit naar."
      heard: "Fijn dat er eens iemand 's nachts langskomt."
      none: "Goed. Rustige nacht."
    observation: {text: "Twintig jaar dezelfde straten rood. Kees houdt het voortaan bij.", plants: fix_cause_unknown}
    # route: open question +6 45 (interest) > reflect +10 55 > inquiry x1.5 +12 (craftsman) 67 (lead-in, cue) > silence +12 > 74 capped (concern)
    #        > empathy +10 84 > close: opgebeurd (6 moves)

  - id: mieke_archive
    person: mieke
    kind: checkin
    trigger: {walkaround: true, morale_below: 45}
    patience: 7
    # start: craftsman 40 + 0 + 0 + 0 - 1 = 39
    opening: "Ik ben een schets aan het uitzoeken. Wil je raden wat dit pijltje betekent? Ik ook niet."
    position: {text: "Het gaat wel. Er komen er meer bij dan ik er wegwerk.", tags: [claim]}
    layers:
      - {id: interest, at: 45, via: [open_question, inquiry], text: "Ik teken nu zesentwintig jaar. Elke kabel in Nova is een keer langs mijn bureau gekomen.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, silence, empathy]
        lead_in: {text: "Mijn dochter vroeg…", tags: [hesitation]}
        text: "…wat ik eigenlijk doe. Ik wist het niet uit te leggen. 'Ik teken over wat een ander al getekend heeft.' Zo klinkt het. Zesentwintig jaar."
        tags: [admission]
    outcomes:
      lifted: "Weet je wat ik haar ga laten zien? In het archief ligt de eerste kaart van Nova. Met de hand getekend, 1930-nogwat. Dat is pas tekenen."
      heard: "Dank je. Terug naar het pijltje."
      none: "Ja. Er komen er meer bij."
    observation: {text: "In het archief van Revisie & GIS ligt de eerste kaart van Nova, met de hand getekend."}   # a lead toward D16 Het eerste net, never the trigger itself
    # route: open question +6 45 (interest) > reflect +10 55 > inquiry x1.5 +12 (craftsman; concern within 10) 67 (lead-in, cue) > silence +12 > 74 capped (concern)
    #        > empathy +10 84 > close: opgebeurd (6 moves)

  - id: rachid_new
    person: rachid                         # Rachid Ouali, Intake; Petra's backup after petra_batch
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, needs: {any: ["agreed:petra_batch:rachid_backup"]}}
    patience: 7
    # start: quiet 47 - 5 (stil) + 0 + 0 - 1 = 41
    opening: "Hé. Ik zit bij Petra. Zij is er vandaag niet, dus… ik doe het."
    position: {text: "Gaat goed. Denk ik.", tags: [claim]}
    layers:
      - {id: interest, at: 47, via: [open_question, inquiry], text: "Elke EAN die ik aanmeld, controleer ik drie keer. Petra doet het één keer en het klopt altijd.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [silence, empathy, reflect]
        lead_in: {text: "Als ik er één fout doe…", tags: [hesitation]}
        text: "…dan heeft een gezin geen energiecontract. Door mij. En dan zegt iedereen: zie je, het had bij Petra moeten blijven."
        tags: [admission, doubt]
    lines:
      experience: {say: "Mijn eerste weken hier controleerde ik alles ook drie keer. Ruud zei: na de tiende keer goed mag je het twee keer doen."}
    outcomes:
      lifted: "Na de tiende keer goed, twee keer. Oké. Ik tel mee."
      heard: "Dank je. Ik ga verder. Langzaam."
      none: "Ja. Gaat goed."
    # route: open question +6 47 (interest) > reflect +10 57 > empathy +6 63 > inquiry +8 71 (lead-in, cue)
    #        > silence +18 (quiet x1.5) > 74 capped (concern) > experience +8 82 > close: opgebeurd (7 moves)

  - id: femke_2035
    person: femke
    kind: checkin
    trigger: {walkaround: true, morale_below: 45, after_mission_open: fix_grid_study_queue}
    patience: 7
    # start: craftsman 40 - 10 (moe) + 0 + 1 - 1 = 30
    opening: "Studie achtendertig. Of negenendertig. Ik ben de tel kwijt."
    position: {text: "Het is gewoon druk. Dat gaat wel weer over.", tags: [claim]}
    layers:
      - {id: interest, at: 42, via: [open_question, inquiry], text: "Ik reken de hele dag of iets past. Bijna altijd past het.", tags: [claim, feeling]}
      - id: concern
        at: 65
        via: [reflect, silence, empathy]
        lead_in: {text: "Ik ben netplanner geworden om…", tags: [hesitation]}
        text: "…het net van 2035 te ontwerpen. Waar de warmtepompen komen, de laadpleinen, de batterijen. Niet om vier uur per dag te bewijzen dat een gewone woning past."
        tags: [admission]
    outcomes:
      lifted: "Wil je hem zien? Ik heb een schets. Thuis gemaakt, op zondag. Niemand heeft hem ooit gevraagd."
      heard: "Dank je. Terug naar studie negenendertig."
      none: "Ja. Het gaat wel weer over."
    observation: {text: "Femke heeft een schets van het net van 2035, thuis gemaakt.", plants: sector_grid_2035}
    # route: mood +8 (moe) 38 > open question +6 44 (interest) > reflect +10 54 > empathy +6 60 > inquiry x1.5 +12 72 (lead-in, cue)
    #        > silence +12 > 74 capped (concern) > close: opgebeurd (7 moves)
```

## 9. Self-check against the validator (spec §9.2) and the content tests (§9.3)

Every persuasion dialog, by hand. "Concern options" counts the proposals and experiments that address the concern, including hidden ones, for the "no single right answer" rule (§9.2 #10). "Route" is the listening route in its comment: moves used / patience.

| Dialog | interest.at | concern.at | `via` (≥ 2) | lead-in | Concern options | Route | Pushing first at the start ruins? |
|---|---|---|---|---|---|---|---|
| anouk_first_look | 45 | 65 | 3 / 3 | ✓ | 2 | 8 / 12 | no (tutorial) |
| anouk_owns_tray | 62 | 72 | 3 / 4 | ✓ | 2 | 5 / 12 | no (tutorial) |
| joost_vacancies | 55 | 70 | 3 / 4 | ✓ | 2 | 8 / 10 | yes: 35 → 23 → 11 → (pressure) 0 |
| sanne_checker | 50 | 68 | 3 / 3 | ✓ | 3 | 8 / 9 | yes: 30 → 18 → 6 |
| marco_wasted_trips | 50 | 70 | 3 / 3 | ✓ | 2 | 8 / 10 | yes: 30 → 18 → 6 |
| esra_agents | 50 | 70 | 3 / 3 | ✓ | 2 | 9 / 9 | yes: 30 → 18 → 6 |
| el_amrani_fourth_call | 45 | 65 | 3 / 3 | ✓ | 2 | 9 / 10 | yes: 20 → 8 |
| petra_batch | 55 | 72 | 3 / 3 | ✓ | 2 | 8 / 10 | yes, in 3 with pressure |
| henk_camera | 55 | 72 | 3 / 3 | ✓ | 2 | 7 / 10 | yes, in 3 with pressure |
| linda_replanning | 45 | 66 | 3 / 3 | ✓ | 2 | 8 / 9 | yes: 25 → 13 → 1 |
| dirk_shelf | 58 | 70 | 2 / 3 | ✓ | 2 | 6 / 10 | no: base 50 > 40 (outside the test's scope) |
| gert_klic | 55 | 70 | 3 / 3 | ✓ | 2 | 8 / 10 | yes, in 3 with pressure (but see the safety exception) |
| mieke_redraw | 55 | 72 | 3 / 3 | ✓ | 2 | 8 / 10 | yes, in 3 with pressure |
| femke_triage | 52 | 70 | 3 / 3 | ✓ | 2 | 8 / 9 | yes: 31 → 19 → 7 |
| rob_order_rule | 52 | 70 | 3 / 3 | ✓ | 2 | 7 / 10 | yes, in 3 with pressure |
| thomas_reclaim | 55 | 70 | 3 / 3 | ✓ | 2 | 7 / 10 | yes, in 3 with pressure (base 41: borderline; pressure path gives compliance) |
| ilse_queue | 45 | 66 | 3 / 3 | ✓ | 2 | 9 / 10 | yes: 20 → 8 |
| joost_output_kpi | 55 | 70 | 3 / 4 | ✓ | 5 | 8 / 10 | yes (§3.3, path A) |
| sanne_kpi | 55 | 70 | 3 / 3 | ✓ | 4 | 7 / 9 | yes, in 3 with pressure |
| frank_kpi_targets | 52 | 72 | 3 / 3 | ✓ | 2 (blocked until a route) | 8 / 8 | yes, in 3 with pressure |

Every block route keeps one route that no failure can close (Frank: `checked:silo_kpis`). Every check-in's route reaches *opgebeurd* within its patience; the same rows apply to them (layers within range, a lead-in, ≥ 2 `via`).

**What I could not verify by hand**: the content test's breadth-first search for three distinct successful sequences (spec §9.3) and the bank replies' tags, which decide whether `reflect` and `paraphrase` land after a bank line. The routes above use only authored lines for those moves. The builder should run §9.3's search on these blocks first and report any dialog with fewer than three routes.

---

## 10. Questions for Merijn: decided

Merijn answered on 2026-10-15 (PLAN.md "Decisions Made"). Where he took the recommended option, it is marked **decided (a)**; where he chose otherwise, the decision is written out. Every choice below is logged under "Claude's calls, pending Merijn" in PLAN.md, so he can still overrule it.

1. **The size of a change on the meter.** **Decided:** openness is a bar that fills up, with arrows per reply (▲ or ▲▲, ▼ or ▼▼), never a number. People met while walking around show a low-energy bar that invites a spirit-lifting talk (§8.1, new).
2. **The lead-in turn (R-D1).** **Decided (a):** the concern takes two turns (the hesitation, then the reveal), and a move is applied as Δ, cap, reveal.
3. **A layer tracker (Standpunt · Belang · Zorg).** **Decided (a):** three steps that fill when a layer is revealed.
4. **The first two talks (Act 0).** **Decided (a):** tutorials that cannot be ruined, with patience 12.
5. **Dialect.** **Decided: none.** Every character speaks standard Dutch, in standard spelling. Voices stay distinct through word choice, rhythm, humour and worry (§2). This replaces the recommended light dialect; all lines in this doc are revised.
6. **The ruined line.** **Decided (a):** in character, naming how it felt.
7. **Customers.** **Decided:** by phone at the contact centre now; home visits come with the town map (Phase C). Mrs El Amrani and Ilse are phone calls.
8. **The El Amrani heat-pump check.** **Decided (a):** kept.
9. **New cast.** **Decided (a):** Rob Verhagen joins; Kim, Saskia, Rachid Ouali and Ricardo are named in lines only.
10. **The Frank route.** **Decided (a):** "both team leads at partial, and reputation ≥ 40" replaces the Ruud route.
11. **Promises the game checks.** **Decided (a):** a `promise` field on a proposal, checked against the simulation.

Related decisions that touch these scripts: colleagues leave rarely (morale below 20 for 60 days and two ignored check-ins), and the new CLAUDE.md rule "Respect the player's time" (no real-time timers, no loss for stopping, no streaks, no guilt). Check-in prompts in §8 expire without cost, in line with it.

---

## Sources

- Netbeheer Nederland — *Stand van de uitvoering, halfjaarpublicatie 2025* (queue growth; 891 large connections in H1 2025; small-consumer waits 43 → 44 weeks): https://www.netbeheernederland.nl/sites/default/files/2025-10/stand_van_de_uitvoering_halfjaarpublicatie_2025.pdf
- Minister's letter on congestion (14,044 requests and 9.1 GW in the regional queue on 1 July 2025), Kamerstuk 29023: https://zoek.officielebekendmakingen.nl/kst-29023-AM.pdf
- Solar Magazine — "Netbeheerders bouwden in 2024 ruim 2.400 trafohuisjes; wachttijd consument 40 weken": https://solarmagazine.nl/nieuws-zonne-energie/i40092/netbeheerders-bouwden-in-2024-ruim-2-400-trafohuisjes-wachttijd-consument-40-weken
- KHN — "Netcongestie: vanaf 1 juli 2026 ook kleinverbruikers op de wachtlijst": https://khn.nl/nieuws/netcongestie-vanaf-1-juli-2026-ook-kleinverbruikers-op-de-wachtlijst
- Gemeente Den Haag — "Adviezen aan bedrijven bij vol elektriciteitsnet" (up to 3x80A on the list from 1 July): https://www.denhaag.nl/nl/?p=135463
- Kassa (BNNVARA) — "Wachtlijst voor stroom: dit verandert er per 1 juli voor huishoudens": https://www.bnnvara.nl/kassa/artikelen/wachtlijst-voor-stroom-dit-verandert-er-per-1-juli-voor-huishoudens
- Welingelichte Kringen (ANP, 24 July 2026) — "Vlak voor ingaan nieuwe regels piek in aanvragen netaansluiting" (five times as many requests; priority order; transition period): https://www.welingelichtekringen.nl/samenleving/vlak-voor-ingaan-nieuwe-regels-piek-in-aanvragen-netaansluiting
- RVO — "Voorrang op elektriciteitsnet": https://www.rvo.nl/onderwerpen/netcongestie/voorrang-op-elektriciteitsnet
- Overstappen.nl — "Nieuwe regels voor het stroomnet zijn ingegaan: heb je écht een zwaardere aansluiting nodig?": https://www.overstappen.nl/nieuws/nieuwe-regels-voor-het-stroomnet-zijn-ingegaan-heb-je-echt-een-zwaardere-aansluiting-nodig/
- NOS — "Run op zwaardere stroomaansluiting voor huishoudens nu wachtlijst dreigt": https://nos.nl/l/2615927
- Rechtspraak (CBb, 11 March 2025) — "Prioriteringskader van ACM voor transportverzoeken elektriciteit houdt geen stand": https://www.rechtspraak.nl/organisatie-en-contact/organisatie/college-van-beroep-voor-het-bedrijfsleven/nieuws/2025/03/prioriteringskader-van-acm-voor-transportverzoeken-elektriciteit-houdt-geen-stand
- ACM — "Voorrang maatschappelijke projecten blijft mogelijk met nieuw prioriteringskader": https://www.acm.nl/nl/node/28593
- Solar Magazine — "Netbeheerders en aannemers werven 5.000 extra technici via opschalingsplan" (training and supervision capacity as the bottleneck): https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan
- The method sources (MORE PIES, Kotter & Schlesinger, Senge, Herscovitch & Meyer, Miller & Rollnick, Schein, Rother, TWI) are in the dialog spec §12 and the audit's Sources.
