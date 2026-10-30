# Dutch style guide for spoken lines

> Status: written by Claude (dialogue writer, 2026-10-19) after Merijn's playtest of the opening, PLAN 2.13 E. Binding for every line a person says or writes in the world of Spanning. **Merijn approves it together with the sample** (`docs/qa/dutch-sample-2026-10-19.md`); the rewrite of the remaining talks waits for that approval.
>
> Merijn's playtest (2026-10-19): "'Maandag is altijd maandag' is not something we say in the Netherlands. Same goes for 'sorry, rare week, 3 van mijn vier zitten er middenin'… 'weet je waarom dit spel... sorry. Weet je waarom dit vak spanning heet' is also a really weird sentence… don't mention the game." "The explanation again is weird." And: not everyone should be in a foul mood.

## 1. The one test

Read the line out loud as a colleague at a Dutch netbeheerder, at the coffee machine or at a desk. **Would someone say exactly this, in these words, on a normal working day?** If you have to think "well, you could say that", rewrite it. If it sounds like a subtitle of an English series, rewrite it. If it sounds like a policy memo and the speaker is not Frank, rewrite it.

## 2. Spoken office Dutch

- **Je/jij** between colleagues, always; also to the director. **U** only from and to customers (mevrouw El Amrani, Ilse) and from Rob until he opens up.
- **Short sentences, but whole ones.** Spoken Dutch drops less than English: "Mijn kamer. Voorlopig." reads like a screenplay. Say "Dit is mijn kamer. Voorlopig dan." Fragments are a voice trait (Marco, Dirk, Ahmed), not the default.
- **Small words carry the tone.** Dutch speech is full of particles: *even, maar, eens, wel, hoor, hè, toch, gewoon, eigenlijk, nou, joh*. A line without any of them often sounds stiff ("Kijk naar de tang." → "Kijk eens naar de stroomtang."). Do not stack them either: one or two per line.
- **Word order of speech:** the main point early, the afterthought after a comma ("Ik wilde je zelf ophalen, maar het MT liep uit."). Avoid long front-loaded clauses.
- **Contractions only as people say them:** "'t" and "da's" sparingly and only in quick, informal lines ("Da's mooi."); never "'k", "m'n" in running text except "m'n" and "z'n" where the speaker is casual ("met z'n vieren" is standard). Never dialect spelling (decided 2026-10-15: standard Dutch for everyone).
- **Numbers as people say them:** "half negen", "na drieën", "twintig jaar", "drie keer al"; digits only on paper, screens and phones.
- **Greetings and goodbyes that exist:** "Hoi", "Goedemorgen", "Welkom!", "Fijn weekend", "Tot morgen", "Succes ermee", "Sterkte" (ironic, for IT). No "Prettige dag verder" between colleagues.

## 3. No translated English

Merijn's examples, and the fix:

| Before (sounds translated or made up) | Why | After |
|---|---|---|
| "Maandag is hier altijd maandag." | Not a Dutch saying. | "Na het weekend staat hier de telefoon roodgloeiend." |
| "Je komt in een rare week. Drie van mijn vier zitten op cursus." | "rare week" is *weird week*; "drie van mijn vier" counts people like English *three of my four*. | "Je treft het niet: bijna mijn hele team zit deze week op cursus. Alleen Anouk is er." |
| "Sorry, ik zit er even middenin." | Half an idiom; you are midden *in* something. | "Sorry, ik moet dit even afmaken. Ik spreek je straks!" |
| "Weet je waarom dit spel… sorry. Weet je waarom dit vak spanning heet?" | Names the game, and nobody asks why a trade "heet" spanning. | "Iedereen die hier begint, krijgt van mij hetzelfde verhaal. Over spanning. Heb je een minuutje?" |
| "Onthoud dat bureau." | *Remember that desk.* | "Dat bureau van Anouk: daar kom je nog wel terug." |
| "Hoeveel water er per tel doorheen gaat" | "per tel" is not how you explain a flow. | "Hoeveel water er per seconde doorheen gaat" |
| "Die tellen we in volt." | You *meet* voltage. | "Die meten we in volt." |
| "Nu hetzelfde. Maar dan echt." | *Now the same. But for real.* | "Goed. En nu hetzelfde, maar dan met stroom." |

More traps, with the Dutch that people actually use:

- *make sense* → "klopt", "is logisch", never "maakt zin".
- *at the end of the day* → "uiteindelijk", never "aan het eind van de dag".
- *I'm in the middle of it* → "ik zit er nog midden in", "ik ben er nog mee bezig".
- *weird* → "gek", "vreemd", "apart"; "raar" is fine in Sanne's "raar goed", not as a filler.
- *Good sign* → "Dat is een goed teken" (whole sentence), not "Goed teken."
- *Take your time* → "Kijk gerust even rond", "Doe rustig aan", not "Neem je tijd" on its own.
- *Fair enough* → "Dat is ook zo", "Daar zit wat in".
- *We'll see* → "We zien wel", "Dat merken we vanzelf".
- *Deal* stays Esra's word; everyone else says "Afgesproken" or "Doen we".

**Real idioms are welcome** when they fit the speaker: *de telefoon staat roodgloeiend*, *je treft het niet*, *met de deur in huis vallen*, *de kat uit de boom kijken*, *er de brui aan geven*, *door de bomen het bos niet meer zien*, *op de winkel passen*, *voor niks staan* (a monteur at a house that is not ready), *dat is roeien met de riemen die je hebt*. Never an invented idiom, never an English one in Dutch words.

## 4. Never the game

Nobody in Voltana knows they are in a game. **No spoken or in-world line names the game, the player, a level or a mission.** The player is a new colleague: "de nieuwe", "de nieuwe van Ruud", "{speler}", "jij". The week is "je eerste week" or "de inwerkweek", a task is "een klus", "een opdracht", "dit dossier", "wat Ruud je vroeg"; progress is "volgende week begin je echt".

**The banned list** (checked by `tools/build_content.py` and the Godot test `test_spoken_words.gd`; the list itself lives in `BANNED_SPOKEN` in the build and is exported to `game/data/vocabulary.json`):

| Word | Notes |
|---|---|
| game, games, gamen | |
| spel, spelletje(s) | **Whole words only.** "haspel", "voorspelling", "spelregels", "spelen" (*er spelen twee dingen*) are fine. One fixed idiom is allowed: **"op het spel"** (*er staat veel op het spel*, *je reputatie op het spel zetten*), which is real office Dutch. |
| speler, spelers, speelster | Tokens such as `{speler}` and `{haar_hem_speler}` are filled with the name or pronoun before anyone reads them and are not checked. |
| level, levels | |
| quest, quests | |
| missie, missies | **Allowed in UI chrome** (the board, the HUD, the journal headings), never in a spoken line. |
| player | |

**What counts as spoken** (the validator checks exactly these):

- `content/dialogs.yaml`: every person's `voice`; the whole `bank` except `labels` (player lines, replies, wear-out lines, special lines, Ruud's coach questions and his Act 0 names, outcome texts); and every dialog's `opening`, `retry_opening`, `warning`, `position`, layer `text` and `lead_in`, proposal and experiment `say` and `reply`, `co_proposal`, `lines`, `replies`, `outcomes`, `beats_after`, `block` text and `variants`. Not checked: names, `label`s (the chip on a proposal), `prompt` (the dagstart line), block route `hint`s and `move_cards`: those are UI.
- `content/explainers.yaml`: the beats' `lines` and the `limit_line` (Ruud at the whiteboard). Captions, hints and labels are UI.
- `content/missions.yaml`: the coach's `stages` and `conditional` questions, and per mission the `briefing`, `debrief`, `debrief_first`, `debrief_variants`, `fail`, `reopen`, `insights` and `questions`. They are Ruud's notes and Ruud's questions, so they are in-world even when they appear on the board. The mission `name` and `chapter` are UI.
- `content/places.yaml`: the place `questions` (`text` is what you ask, `reply` what you hear).
- GDScript: every string constant of `game/src/world/office/office_opening.gd` and `game/src/ui/scene_lines.gd` (the opening scene and its line box), via `test_spoken_words.gd`.

## 5. Jargon: the words people at a netbeheerder really say

Use the work's own words, the way colleagues use them, and let the context explain them. Do not explain a word in the same sentence as you use it unless the speaker is explaining to the new colleague on day one.

- **Aansluitingen:** *aansluiting*, *aanvraag*, *verzwaring* ("een zwaardere aansluiting"), *aansluitvermogen*, *meterkast*, *EAN*, *het portaal*, *dossier*, *de wachtrij*, *offerte*, *opdrachtbevestiging*.
- **Werkvoorbereiding and netplanning:** *werkvoorbereiding*, *werkvoorbereider*, *ontwerp*, *tracé*, *tekening*, *netstudie*, *capaciteit*, *netcongestie* ("het net zit vol"), *wachtlijst*.
- **Uitvoering:** *monteur*, *ploeg*, *uitvoerder*, *aannemer*, *graafwerk*, *KLIC-melding*, *mof*, *kabel*, *trafo*, *onderstation*, *middenspanning (MS)*, *laagspanning (LS)*, *voor niks staan*, *niet gereed* (on paper; a monteur says "niet klaar").
- **Storingen:** *storing*, *storingsdienst*, *consignatie* ("ik heb consignatie"), *schakelen*, *de bedrijfsvoering*, *het BVC*.
- **Klant en organisatie:** *KCC* (spoken "het KCC"), *klantcontact*, *terugbellen*, *het MT*, *de directie*, *de ACM*, *de aansluittermijn* ("de wettelijke termijn" is how most people say it), *NTA 8120*, *revisie*, *GIS*, *Meetdata*.
- **Lean words** are the player's and Ruud's and only slowly become others'. Marco sneers at "KPI" and "stakeholder" (his voice sheet). A person who has not been through it says "het getal", "het bord", "ons overleg"; after a successful change they may start saying "dagstart" or "het bord".

## 6. Mood: friendly by default in the first week

The office is a nice place to work with too much work in it. **People are friendly or neutral when the player meets them;** a bad mood needs a reason the player can see (a storing, a late evening, being watched with a stopwatch) and comes later (PLAN 2.13 D). In Act 0:

- Busy is shown as busy-but-kind: "Sorry, ik zit net aan de telefoon. Ik loop straks even bij je langs!" not "Sorry. Maandag."
- A warm welcome comes first; the complaint, if any, comes after. Marco may be gruff, with a wink ("Maar goed. Welkom.").
- The hooks stay (Marco's 2012, Anouk at seven, Sanne's "postkantoor"), but they are worries people share, not grudges.

## 7. Each person's voice

From the voice sheets (`2026-10-15-dialog-scripts-act0-2.md` §2, `2026-10-15-four-tier-audit.md` §6, which wins where they differ). Everyone speaks standard Dutch; voices differ in word choice, rhythm and humour.

| Person | Voice in one or two lines | Sample |
|---|---|---|
| **Ruud Hoekstra**, directeur, the coach | Warm, calm, asks more than he says; one question per line; self-mocking about his age and the coffee. No jargon unless you used it first. | "Wat zie je? En wat had je verwacht?" |
| **Yvonne Kramer**, receptie | Cheerful, quick, knows everyone and their habits. | "Kijk, daar is hij al. Nooit te laat, wel altijd net op tijd." |
| **Sanne Bakker**, TL Intake | Fast, lists in threes, *joh, hè, nou*; sarcasm about "het postkantoor"; stops joking when tired. | "Joh. Portaal, werkbak, dossiernummer. Drie stappen, hè. Op papier dan." |
| **Rachid Ouali**, Intake | New (four months), polite, careful; would rather call three times than be wrong. | "Ik vraag het wel even na." |
| **Joost van Dijk**, TL Werkvoorbereiding | Tidy, complete sentences, numbers when nervous: *even voor de duidelijkheid, eerlijk is eerlijk*. | "Even voor de duidelijkheid: we halen ons doel." |
| **Anouk de Vries**, werkvoorbereider | Apologises first, kind, precise about drawings; *nee joh, ik zit erbovenop*. Draws the stack as a mountain with a flag. | "Sorry, het is een beetje een rommeltje. Ik zit erbovenop, hoor." |
| **Marco Peters**, ploegleider monteurs | Short, flat sentences; *mijn mannen, kijk, klaar*; office words only with a sneer; gallows humour. | "En wie bouwt dat na?" |
| **Mieke van der Veen**, Revisie & GIS | Careful craftswoman; *dat moet kloppen, uitzoeken*. | "Dat moet kloppen, dus dat zoek ik uit." |
| **Linda Jansen**, planner | Fast and tired, apologises while she talks, *omplannen*; her board is "het kaartenhuis". | "Sorry, ik ben aan het omplannen. Zeg het maar." |
| **Petra Vos**, Meetdata | Precise, dry, a bit prickly; *klopt*; the register is "de Molen". | "Klopt. Dat staat in mijn map." |
| **Henk Verbeek**, senior monteur | Warm, gruff, slow; stories with a year in them; calls Ahmed "jongen". | "Laat het me voordoen." |
| **Ahmed Bouzid**, monteur | Short; *gewoon, toch, man, echt wel*; says "Henk". | "Gaat wel." |
| **Esra Yilmaz**, TL KCC | Direct; *kijk, serieus?, mijn mensen*; imitates the hold music. | "Mijn mensen zijn geen stootkussen." |
| **Frank Hulshof**, manager | Formal management Dutch: *jaarplan, verantwoorden, de directie, de ACM*. | "Dat moet ik kunnen uitleggen." |
| **Femke de Wit**, netplanner | Enthusiastic engineer, draws while talking; *kort gezegd, dat past*. | "Vijf minuten werk, als ik eraan toekom." |
| **Dirk Smits**, magazijn | The fewest words in the building. | "Ik heb ze gewoon liggen." |
| **Mevrouw El Amrani**, klant | Polite, organised, says *u*; dates from her notebook; firm, never rude. | "Ik vraag niet om voorrang. Ik vraag om een datum." |

The others (Thomas, Gert, Kees, Wendy, Ruben, Ingrid, Monique, Noor, Mark, Lotte, Rob, Ilse) keep their sheet in the four-tier audit §6.

## 8. The player's sentences

The player picks from four full sentences (PLAN 2.13 B); the move under it is never shown. So each sentence must:

- be something a thoughtful new colleague says, in the first person, *je* to colleagues;
- carry its move by what it does, not by a label ("Hoe gaat het met je, echt?" is a mood check; nobody says "Ik peil even je stemming");
- fit any person when it comes from the bank, and this person's words when it comes from the talk's own `lines`;
- never coach-speak ("Wat ik je hoor zeggen is…", "Ik hoor je") and never therapy-speak ("Hoe voelt dat voor jou?") unless the moment really is that open.

## 9. Checklist per line

1. Out loud: would a colleague say it like this?
2. Is it this person's voice (§7), and their mood today (§6)?
3. No banned word (§4); no translated English (§3).
4. One idea per line; the line before and after still read as a conversation.
5. Tokens (`{speler}`, `{hij_zij}`, `{person}`) and ids untouched; no digits in explainer beats.
