# Dialog coherence: why talks contradicted what the player said (2026-10-30)

> Status: written by Claude (dialog lead) after Merijn's playtest of build 27d28db
> (`.superpowers/sdd/playtest-2026-10-30.md`, phase 1 item 4, Anouk's `anouk_seven`).
> Merijn asked for an agent that checks every conversation and its branches so they
> run logically and in good Dutch, because playtesting every talk takes hours. This
> document is the diagnosis, the rules that now make the incoherence impossible, the
> transcript tool, and the order in which the other talks get fixed.

## Run order (Merijn, 2026-10-31: the inwerkweek first)

Every talk the player can meet in the inwerkweek (Act 0, `training_mon` to
`training_fri`), in the order a player meets them, each rewritten to `anouk_seven`'s
standard and then added to `TalkWalk.REVIEWED` (the echo gate). Ruud's opening on Monday
morning is a scripted scene (`office_opening.gd`, `scenes.yaml`), not a talk of the
dialog rules; no check-in or call opens that week. One expert talk can: `henk_expert` has
no condition and Henk stands on the yard every day, so a player who walks out there meets
him. Expert talks are question and answer, topic by topic, outside the move rules, so
TalkWalk does not walk them; Henk's is read by hand after the persuasions.

| Day | Talk | Person | Status |
|---|---|---|---|
| Mon 19:00 | `anouk_seven` | Anouk | reference talk (rounds 1–2) |
| Tue 08:30 | `sanne_tuesday` | Sanne | rewritten; review round 1 fixed (score 30.4 → 0.5, echoes 188 → 0) |
| Tue | `anouk_first_look` | Anouk | rewritten; review round 1 fixed (30.9 → 0.5, echoes 196 → 0) |
| Tue–Thu, optional | `rachid_counter` | Rachid | rewritten; review round 1 fixed (30.6 → 1.1, echoes 193 → 0, no flag) |
| Wed | `mieke_wednesday` | Mieke | rewritten; review round 1 fixed (28.9 → 1.2, echoes 199 → 0) |
| Wed | `joost_wednesday` | Joost | rewritten; review round 1 fixed (29.0 → 0.9, echoes 206 → 0) |
| Wed | `linda_wednesday` | Linda | rewritten; review round 1 fixed (30.1 → 0.8, echoes 186 → 0) |
| Thu | `anouk_thursday` | Anouk | rewritten; review round 1 fixed (31.2 → 0.5, echoes 196 → 0) |
| Thu | `petra_thursday` | Petra | rewritten; review round 1 fixed (29.2 → 0.9, echoes 185 → 0) |
| Fri | `anouk_owns_tray` | Anouk | rewritten; review round 1 fixed (35.4 → 0.5, echoes 234 → 0) |
| Fri | `sanne_friday` | Sanne | rewritten; review round 1 fixed (33.6 → 0.3, echoes 226 → 0) |
| any day, the yard | `henk_expert` | Henk | expert talk, read by hand: every answer fits its question; no change |

After the week: the worst of the README ranking (Act I), worst first. Act I talks steer
and push too (data, perspective, pressure, blame are not held back as in the tutorial), so
each also got its own lines for those moves and their replies: a clue that matters, one
that does not ("Wat heeft dat met de doos te maken?"), pressure and blame in the person's
voice, and its own "Daar denk ik nog over na" lines.

| Act I talk | Person | Status |
|---|---|---|
| `petra_batch` | Petra | rewritten; review round 1 fixed (38.3 → 0.5, echoes 294 → 0, no flag) |
| `linda_replanning` | Linda | rewritten; review round 1 fixed (36.7 → 0.4, echoes 235 → 0, no flag) |
| `mieke_redraw` | Mieke | rewritten; review round 1 fixed (36.7 → 0.4, echoes 285 → 0, no flag) |
| `joost_vacancies` | Joost | rewritten, batch 2 (35.8 → 1.0, echoes 284 → 0, no flag) |
| `marco_wasted_trips` | Marco | rewritten, batch 2 (35.1 → 1.1, echoes 228 → 0, no flag) |
| `sanne_checker` | Sanne | rewritten, batch 2 (35.1 → 0.7, echoes 245 → 0, no flag) |
| `henk_camera` | Henk | rewritten, batch 2 (36.0 → 1.2, echoes 261 → 0, no flag) |

| `joost_output_kpi` | Joost | rewritten, batch 3 (36.9 → 1.3, echoes 322 → 0, no flag at budget 8000) |
| `sanne_kpi` | Sanne | rewritten, batch 3 (35.0 → 0.8, echoes 241 → 0, no flag at budget 8000) |
| `gert_klic` | Gert | rewritten, batch 3 (35.4 → 0.6, echoes 268 → 0, no flag at budget 8000) |
| `wim_spreadsheet` | Wim | rewritten, batch 3 (37.1 → 0.8, echoes 301 → 0, no flag at budget 8000) |
| `dirk_shelf` | Dirk | rewritten, batch 4 (35.0 → 0.1, echoes 265 → 0, no flag at budget 8000) |

The two KPI talks are the audited ones of `test_dialog_content.gd`: their reply tags stay
the audited ones (a talk's own untagged reply clears the moment's tags, a bank reply keeps
them; Joost's interest answers carry the `[feeling]` the bank's reply used to leave), so the
scripted routes keep their exact traces. Gert's first pressure line stays the safety stop.

Batch 2, review round 1 (2026-11-01, `review3-findings.md`): no flag in the four at walk
budget 8000 either (Marco's third clue answer). Commitments name only what every route to
them brings; `test_a_reviewed_talk_s_commitment_fits_every_route_to_it` checks it for every
reviewed talk: a commitment word that a proposal or its answer brings, but not every
proposal or experiment that meets the concern, fails, unless the person said it before
any proposal. Its limit: a word the person said first can still lean on one route.

Each also has its own words where it used to take the bank's: the ending with no outcome
(`outcomes.none`), an experiment proposed again, the refusal, the shrug at a silence, and
its own sentence for the ask (the bank's "Zullen we dat afspreken?" after a question of
theirs was a `question` flag). The stock share left (4–6 %) is the bank's "you said that"
lines for a sentence said again (`again`) and its `repeat` for a clue shown again.

Engine changes that came with the week and the batch (each test first, in
`game/tests/test_dialog_coherence.gd`): their own idea is not offered after the player
proposed it earlier (`_proposed`); a clue that does not matter, a lucky guess and a
refusal may be answered in the talk's own words (`replies.show_data.other`,
`replies.propose.misses`, `replies.ask_commitment.misses`); two clues on offer in one turn
are shown in two different sentences (`_player_line`).

### Review round 1 of the week and the batch (2026-11-01)

The task review (`.superpowers/sdd/dialog-lead/review2-findings.md`) found the same
families one level deeper: answers that do not fit the question, endings that name what
was never said. Fixed in content and, where the cause was structural, made a gate first:

- `tools/build_content.py` `_talk_holds` (tests in `tests/test_dialog_coherence.py`): a
  player sentence in two places of one talk; a preface of three words or more opening the
  lines of two moves (a promise said again); a list turned by the seed beside replies in
  written order (key the lines `{_: [...]}`); two clues on offer and a show_data reply
  picked by order (key each clue's reply by its id). `other` belongs to show_data only.
- `game/tests/test_talk_coherence.gd`: a reviewed talk has its own inquiry misses at the
  interest and the concern, and no inquiry or open-question miss says "weet ik niet",
  "geen idee", "nakijken" or "zo gaat dat hier" about the person's own work.
- Engine (`dialog.gd`): a show_data reply keyed by the clue shown (`_clue`); no proposal
  and no ask dealt while the person breaks off (the lead-in); a reply list keyed by the
  layer answers the talk's questions for that layer place by place (`_asked`), so a
  question that missed does not hand its answer to the next one.
- Content, all reviewed talks: own inquiry and open-question misses per layer, each
  fitting both questions of that layer; layer texts that open with a hinge every move into
  them can meet ("Eerlijk?"); questions that re-asked what the layer just told, replaced;
  commitment lines that fit every proposal leading there; `heard` lines about the person,
  not a claimed action; Ruud's note on empathy names what the line did, not "dat het zwaar is".

### Review round 2 (2026-11-01)

- A story is told once (R1). The rules no longer deal a sentence of the talk's own the
  player already said (`Dialog._said_before`, in `_candidates`, so the walk sees it too); a
  talk with one own sentence for a move falls back to the bank's unsaid general line, and a
  bank line of more than 12 words (`Dialog.STORY_WORDS`) is told once too; the ask,
  proposals, clues and gestures may come again. Every reviewed talk's
  `experience.concern` (and Petra's `experience.interest`) got a second variant.
- Walk gate `told` (`TalkWalk`, every talk): a player sentence of more than 12 words said
  twice in one route. A proposal made again is a choice with its own acknowledgement and is
  left out. Before the engine change it failed in 23 talks.
- Gate brittleness: the shared-opening rule needs four words ("Dat herken ik." is ordinary
  speech); a flat ask list may sit beside ordered refusals; the disowning pattern also
  catches "zo gaat het hier" and "zo gaat het nu eenmaal".

## 1. The one root cause

**What a person answers was keyed to the kind of move the player made, never to the
sentence the player said; and the talk kept no record of the sentences.** The rules
(`game/src/rules/dialog.gd`) judged a move by its kind and the tags of the person's last
line, then fetched a reply by `(move, lands | misses)` from the shared bank or the talk's
own `replies`. The player's sentence itself came from `lines[move]`, one fixed sentence
(or a rotating list) per move kind, chosen without looking at what the person had said.
The talk remembered the moves (`made`) and the tags (`_last_tags`), not the words. So
nothing could check whether a reply, an option or Ruud's note was true for this
conversation, and every symptom Merijn saw is this one cause showing up in another place.
It is structural: rewriting a few lines would have moved the contradictions around.

## 2. Each symptom, its code path, and why it contradicted the talk

| # | What Merijn saw | Code path (before) | Why the line could not be true |
|---|---|---|---|
| 1 | "Ja, dat zei je al." after a new sentence | `Dialog.say` → `_effect` → `_listen("empathy")`: empathy misses once `moves_made >= EARLY_MOVES` and the last words carry no feeling or admission → `_reply("empathy", "misses")` → `bank.replies.empathy.misses` | The miss line asserted a history ("you said that already") that the rules never checked: it fired on the *first* empathy late in a talk. Same family: `open_question.misses` "Dat heb ik je net verteld.", `paraphrase.misses` "Dat zei ik, ja." (after a summary of something the person had not said), `special.repeat` "Dat vroeg je net ook." (after three *silences* or three statements in a row), and the wear-out lines "Dat zei je al" (on the third use of a move kind, while the player's sentences rotate through *different* variants). |
| 2 | "Kun je daar iets meer over vertellen?" → "Hoe bedoel je?", and no way to explain | `_listen("inquiry")` misses when openness is more than `INQUIRY_REACH` below the next layer or the last words hold no claim or hesitation → `bank.replies.inquiry.misses` "Hoe bedoel je?" | A reply could not open a sub-exchange: the rules have no state for "the person asked the player something", and `offer()` deals the next four sentences from the moves' fit alone. So the person asked a question no turn could answer. |
| 3 | Ruud: "Je vroeg eerst hoe het met Anouk ging. Dat heet Stemming peilen…" though the player did not recognise that | `People.ruud_names(d)`: the day's move (`teaches`) if it raised openness, else the move that raised it most → `bank.ruud_names[move]`, a fixed description | The note described a *move kind* in canned words, and the player never sees move names (they choose sentences, `offer()` hides the move). "Eerst" was false whenever mood came later (on a tired day mood lands once at any point; Anouk is `moe`). The talk kept no sentences, so Ruud could not quote the one he meant. |
| 4 | The four answers to "Nog twee tekeningen en dan ga ik… Niet tegen Joost zeggen, hè?" read oddly | `Dialog._player_line(move)` → `def.lines[move]` or `bank.player[move]` | One sentence per move kind, blind to what was said: Anouk's summary line was her *interest* ("Dus als het vanavond niet af is, sta je er morgen alleen voor."), offered on turn one, before she said it; "Waar ben je mee bezig?" right after she said what she was doing; nothing answered her own question about Joost. Her replies had the same flaw: one per move, so "Ach, je kent het. Te veel werk, te weinig tijd." came back to three different questions. |
| 5 | At the end, no sense of how the talk went | `Dialog.say`: when patience runs out, `outcome = _close_outcome()`, but the reply is replaced by the outcome line only for `ruined`, `commitment`, `compliance` or a close | A talk that ran out of time ended on whatever the last reply was ("Precies.", "Hoe bedoel je?") and then the summary card's label ("Gehoord"). The person never said, in their words, how it landed. |
| 6 | "Openheid: hoe open Anouk nu met je praat…" with no introduction | `OfficeOpening.TALK_HINT`, shown over the first talk's sentences | It named an instrument that has not been on screen since the 2026-10-19 talk view (the meter is hidden; the body and the arrows show it). |

Measured on the old build with the transcript tool (§4), every persuasion and check-in in
content had all of these: 15–53 false "you repeat yourself" lines, 20–67 clarification
requests, 21–104 endings with no word on how it went, and every Act 0 talk ended with a
Ruud note that quoted nothing the player said (Anouk: 15 · 64 · 73 · 86; score 84.5).

## 3. The rules that make it impossible now

Each was written as a failing test first (`game/tests/test_dialog_coherence.gd`,
`tests/test_dialog_coherence.py`), and none changes how a move lands: the openness numbers,
the tags the rules read and the route check are as before (`test_dialog_routes.gd` green,
the tier-1 ratchet still 2).

1. **"Dat zei je al" only when the player said it.** The talk keeps the player's
   sentences (`Dialog.said`). A miss uses the move's `again` line only when the sentence
   repeats one said before in this talk (`Dialog._repeats`: the same sentence, or a move
   whose sentences all say the same, `SAME_SAYING` = how-are-you and silence). The same
   move three times in a row with a *new* sentence gets the ordinary miss (a new proposal
   or clue gets its own reply); a repeated one gets `again`, else `special.repeat`. A
   wear-out line describes the pattern ("Je vraagt het nu op drie manieren"), never a
   repeat. `again` lines carry no tags, so the rules read them as the miss they replace.
   Content check (`check_coherence`): a "you repeat yourself" phrase (`REPEAT_CLAIM`)
   may stand only in an `again` slot or `special.repeat`, nowhere else a person reacts.
2. **No clarification request without a clarification.** No turn can offer one, so no
   person line may ask for one (`CLARIFY_ASK`, checked over every line a person says in a
   talk). Inquiry's miss is now an honest non-answer ("Tja. Moeilijk te zeggen.").
3. **Ruud quotes the player.** `People.ruud_named(d)` returns the move *and the sentence*
   the player said for it; every listening move's line in `bank.ruud_names` quotes it
   with `{said}`, a question as a question ("Je vroeg: “Hoe gaat het met je, zo aan het
   eind van de dag?” Je wilde weten hoe het met Anouk ging…"), and claims nothing it
   cannot know (no "en je meende het"); silence is described ("Toen Anouk aarzelde, zei je
   niets"), since it is no sentence. Checked by the build.
4. **Every ending carries the person's word.** `Dialog.say` returns `farewell`, the
   outcome line in the person's voice, whenever the talk ended and the reply did not
   already say it (not after a condition or a block, which name it); the talk view
   speaks it after their reply.
5. **Lines follow what was said.** A talk's own `lines.<move>` and `replies.<move>.<case>`
   may be keyed by what the person spoke of last (`Dialog.TOPICS`: position, interest,
   lead_in, concern, `_`), and a reply may be a list (the first line the person has not
   said yet in this talk); keyed player lines are said in the order written on any deal
   (review 2: a follow-up never comes before its question), so a summary sums up what was
   said and an answer fits the question. Validated by the build; the bank stays plain and
   keeps no claim or feeling tags.
6. **Nobody says the same thing twice where it jars** (review 1). The talk keeps what
   the person said (`Dialog.answered`). The concern's lead-in is said in its own words
   once; when its moment passed and comes back, the person says a short form
   (`lead_in.again`, a line or a list, else `special.lead_in_again`) with the same cue.
   A proposal made again gets a short acknowledgement (`replies.propose.again`, else
   `special.proposal_again`), not its first answer word for word. They no longer offer
   as their own idea what the player just proposed; once they did offer it, taking it up
   is one of the four sentences, in the talk's words (`co_proposal.take`). A talk may give
   its own refusal (`replies.ask_commitment.misses`). None of this changes a number the
   rules read: the short forms keep the original's tags, the acknowledgement the
   proposal answer's.
7. **The gate.** `game/tests/test_talk_coherence.gd` walks every persuasion and check-in
   through the real rules (TalkWalk, below) and fails on any of the flags `repeat`,
   `clarify`, `empty`, `farewell`, `ruud` and `retold` (a story line said twice: a layer, a
   lead-in, a proposal's answer, their own idea; whatever the player said, review 2); a
   reviewed talk (`TalkWalk.REVIEWED`, for now Anouk) also fails on any `echo` (a line the person already said, word for word,
   to a sentence the player had not said before). On the old content it fails on every
   talk; it passes now. Measured with the full walk: Anouk 177 echoes and 15 retold lines
   → 0 and 0; Sanne (`sanne_checker`) 250 and 9 → 245 and 0; `sanne_tuesday` 213 and 30 →
   188 and 0 (Sanne's talks are not rewritten yet, so their echoes stay a measure, not a gate).

The first-talk hint now says what to watch: "Kies wat je zegt. Hoe het valt, zie je aan
Anouk en aan het pijltje achter je zin: ▲ ze gaat meer open, ▼ ze klapt dicht. De
bolletjes linksboven: hoeveel ze je vertrouwt."

## 4. The transcript tool

    godot --headless --path game --script res://tools/talk_transcripts.gd -- [talk ids…] [--out=<dir>] [--budget=<n>] [--full]

Without ids it writes every persuasion and check-in to `docs/qa/talk-transcripts/<id>.md`
and the ranking to `docs/qa/talk-transcripts/README.md` (about 90 s). Only the ranking and
`anouk_seven.md` are kept in git (`.gitignore`); the others are generated on demand. Each
transcript has:

- **Whole talks** as the player sees them, on the route check's deal: the four sentences
  each turn offers (the chosen one in bold), what the player said with the arrow they
  see, the person's answer, their own idea, their last word, the note (outcome, curve,
  what was heard) and Ruud's word. Nine players: one who listens first, one who always
  takes sentence 1 (2, 3, 4), one who steers at once, three who choose at random.
- **Exchanges to read**: every option any deal could offer after every line the person can
  say (breadth first over 1500 states, then 300 random talks to the end), grouped by the
  person's line, showing those with a flag or a stock reply of the bank (`--full`: all).
- **Every ending** the walk saw, once per outcome and last word.

Flags: `repeat` (says you repeat yourself; you did not), `clarify` (asks what you mean; no
answer offered), `empty` (says nothing), `farewell` (the talk ends without their word),
`ruud` (Ruud's note does not quote you), `retold` (a story line said twice), `echo` (a line
said again word for word, to a new sentence), and the reading hint `question` (the person asked
the player something and the player's sentence is a stock line of the bank, which cannot
know the question). The walk lives in `game/tests/lib/talk_walk.gd` (TalkWalk), shared by
the tool and the gate test.

## 5. Anouk, the reference talk

Rewritten end to end by reading her transcripts until every branch read like two Dutch
colleagues at seven in the evening: one first sentence answers her question about Joost
("Ik zeg niks, beloofd.", in that one only); a summary only sums up what she said; her
answers follow the question (keyed by layer) and never come back word for word to a new
sentence (lists, review 1); her lead-in has three short forms; when she offers her own idea,
the player can take it up ("Graag. Dan kom ik morgen even kijken."); her interest opens with
"Eerlijk?", so it answers any of its three ways in; her lead-in starts with her phone
("Sorry, mijn telefoon. Mijn vriend appte net…"), so it never cuts across the player; her
misses stay kind (no "Het gaat nu even niet over jou."); and every ending has her word.

Before (always sentence 1): *"In je eentje hier, op een maandagavond. Dat is ook niet
niks."* three times, the same sentence, *"Hé, hoe is het?"* twice, a summary of what she
had not said yet, and the talk ends on *"Precies."* with Ruud's "Je vroeg eerst hoe het
met Anouk ging".

After (listens first): *"Ik zeg niks, beloofd. Hoe komt het dat je hier nog zit?"* → *"Die
twee moeten de deur uit. Een rijtjeshuis in Lindeveld met een warmtepomp, en een school die
een lokaal bijbouwt."* → *"Dus nog twee tekeningen, en dan ben je weg."* → *"Ja. Nou ja…
als het meezit."* → … → *"Ik pak mijn jas. Dank je."*, and Ruud quotes the sentence he names.

Score 84.5 → 0.6 (no flags, no echo; stock replies 66 % → 6 %). Full text:
[talk-transcripts/anouk_seven.md](talk-transcripts/anouk_seven.md).

## 6. The other talks, worst first

All talks are free of the hard flags now (the bank and the rules fixed those everywhere).
What is left is the cause of symptom 4: 47–80 % of each talk's replies are stock lines of
the bank, the same line comes back word for word to new sentences (`echo`), and the
person's questions are answered by stock sentences. The ranking in
[talk-transcripts/README.md](talk-transcripts/README.md) (10 × stock share + per flag its
weight × √ count) puts these first:

1. `petra_batch` 38.3 · 2. `linda_replanning` 36.7 · 3. `mieke_redraw` 36.7 ·
4. `joost_vacancies` 35.8 · 5. `anouk_owns_tray` 35.4 · 6. `marco_wasted_trips` 35.2 ·
7. `sanne_checker` 35.0 · 8. `dirk_shelf` 34.9 · 9. `henk_camera` 34.9 ·
10. `thomas_reclaim` 34.8.

The spread is narrow because every unrewritten talk shares the bank; read the
order as "which talks lean hardest on stock lines", and weigh it with when the player meets
them: the Act 0 week (`sanne_tuesday`, `rachid_counter`, `anouk_first_look`,
`mieke_wednesday`, `joost_wednesday`, `linda_wednesday`, `anouk_thursday`,
`petra_thursday`, `anouk_owns_tray`, `sanne_friday`) is what Merijn plays next.

Update 2026-10-31: the week and the first three are rewritten (see Run order). Update
2026-11-01: the second Act I batch too (`joost_vacancies`, `marco_wasted_trips`,
`sanne_checker`, `henk_camera`); their pressure, blame and perspective answers are keyed
`_`, so each line meets its own answer. The README ranking shows the next batch.

## 7. What a next run fixes (not in this one)

- The other talks, as Anouk's: keyed lines and replies, the position answered first.
- The summary card's curve still names moves under its points (chip labels); quoting the
  player's sentences there too would finish rule 3.
- Some of Ruud's names overclaim ("Daar zat het.", "Toen kwam het verhaal") when the move
  only raised openness a little.
- A layer's text must answer every move in its `via` (Anouk's interest needed "Eerlijk?");
  a content check cannot judge that, the transcripts show it.
- The bank's `lucky_guess` "Hm. Misschien." and the ask lines ("Doen we het zo?") are the
  same for everyone.
