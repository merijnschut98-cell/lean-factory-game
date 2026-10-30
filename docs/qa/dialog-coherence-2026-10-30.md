# Dialog coherence: why talks contradicted what the player said (2026-10-30)

> Status: written by Claude (dialog lead) after Merijn's playtest of build 27d28db
> (`.superpowers/sdd/playtest-2026-10-30.md`, phase 1 item 4, Anouk's `anouk_seven`).
> Merijn asked for an agent that checks every conversation and its branches so they
> run logically and in good Dutch, because playtesting every talk takes hours. This
> document is the diagnosis, the rules that now make the incoherence impossible, the
> transcript tool, and the order in which the other talks get fixed.

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
   with `{said}` ("Je zei: “Ik zeg niks, hoor. Maar hoe is het eigenlijk met je?”
   Daarmee vroeg je hoe het met Anouk ging…"); silence is described ("Toen Anouk aarzelde,
   zei je niets"), since it is no sentence. Checked by the build.
4. **Every ending carries the person's word.** `Dialog.say` returns `farewell`, the
   outcome line in the person's voice, whenever the talk ended and the reply did not
   already say it (not after a condition or a block, which name it); the talk view
   speaks it after their reply.
5. **Lines follow what was said.** A talk's own `lines.<move>` and `replies.<move>.<case>`
   may be keyed by what the person spoke of last (`Dialog.TOPICS`: position, interest,
   lead_in, concern, `_`), and a reply may be a list (the n-th for the move's n-th time),
   so a summary sums up what was said and an answer fits the question. Validated by the
   build; the bank stays plain and keeps no claim or feeling tags.
6. **The gate.** `game/tests/test_talk_coherence.gd` walks every persuasion and check-in
   through the real rules (TalkWalk, below) and fails on any of the flags `repeat`,
   `clarify`, `empty`, `farewell`, `ruud`. On the old content it fails on every talk; it
   passes now.

The first-talk hint now says what to watch: "Kies wat je zegt. Hoe het valt, zie je aan
Anouk en aan het pijltje achter je zin: ▲ ze gaat meer open, ▼ ze klapt dicht. De
bolletjes linksboven: hoeveel ze je vertrouwt."

## 4. The transcript tool

    godot --headless --path game --script res://tools/talk_transcripts.gd -- [talk ids…] [--out=<dir>] [--budget=<n>] [--full]

Without ids it writes every persuasion and check-in to `docs/qa/talk-transcripts/<id>.md`
and the ranking to `docs/qa/talk-transcripts/README.md` (about 90 s). Each transcript has:

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
`ruud` (Ruud's note does not quote you), and the reading hint `question` (the person asked
the player something and the player's sentence is a stock line of the bank, which cannot
know the question). The walk lives in `game/tests/lib/talk_walk.gd` (TalkWalk), shared by
the tool and the gate test.

## 5. Anouk, the reference talk

Rewritten end to end by reading her transcripts until every branch read like two Dutch
colleagues at seven in the evening: her question about Joost is answered before the
player asks anything; a summary only sums up what she said; her answers follow the
question (keyed by layer, lists for the second and third time); her interest opens with
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

Score 84.5 → 1.1 (no flags; stock replies 66 % → 11 %). Full text:
[talk-transcripts/anouk_seven.md](talk-transcripts/anouk_seven.md).

## 6. The other talks, worst first

All talks are free of the five hard flags now (the bank and the rules fixed those
everywhere). What is left is the cause of symptom 4: 47–80 % of each talk's replies are
stock lines of the bank, and the person's questions are answered by stock sentences.
The ranking in [talk-transcripts/README.md](talk-transcripts/README.md) (10 × stock share
+ √ question hints) puts these first:

1. `linda_replanning` 21.3 · 2. `petra_batch` 20.9 · 3. `marco_wasted_trips` 20.0 ·
4. `mieke_redraw` 19.7 · 5. `anouk_owns_tray` 19.6 · 6. `henk_camera` 19.4 ·
7. `femke_triage` 19.3 · 8. `sanne_checker` 19.2 · 9. `joost_vacancies` 18.8 ·
10. `linda_evenings` 18.7.

The spread is narrow (12–21) because every unrewritten talk shares the bank; read the
order as "which talks lean hardest on stock lines", and weigh it with when the player meets
them: the Act 0 week (`sanne_tuesday`, `rachid_counter`, `anouk_first_look`,
`mieke_wednesday`, `joost_wednesday`, `linda_wednesday`, `anouk_thursday`,
`petra_thursday`, `anouk_owns_tray`, `sanne_friday`) is what Merijn plays next.

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
