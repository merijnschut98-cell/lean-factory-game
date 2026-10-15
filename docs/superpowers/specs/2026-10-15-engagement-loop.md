# Engagement loop — session hooks, cliffhangers, hidden rewards, pacing and the "one more mission" pull

> Status: design by the mission and dialog design agent (Claude, 2026-10-15), for Merijn to review. **Docs only.** It builds on, and does not replace:
> - the audit's engagement section (`2026-10-15-mission-audit-and-engagement.md` §5: pacing curve, mission shapes, cast, sides, forks, clocks, debriefs) and its hidden rewards (§4, D1–D28);
> - the dialog spec's D29–D34;
> - the catalogue (`2026-10-15-mission-system-and-catalogue-design.md`);
> - the tier-2 and tier-3 drafts;
> - the Acts 0–II dialog scripts.
>
> Read with: `CLAUDE.md` §2: "The mission system decides the game", with its primary directive "players keep playing (intriguing missions, rewarding play, hidden rewards for notable play)", and the three deep-thinking principles. PLAN.md "Decisions Made": sessions of 15–40 minutes (GDD answers, 2026-10-12); never game over.

## 0. Summary

- **The loop has four layers**, and each needs its own pull (§1):
  - **the moment** (a clue lands, the meter moves);
  - **the session** (one step of a mission, 15–40 minutes);
  - **the mission** (a mystery with a Check);
  - **the act and the campaign** (people you care about, a region that remembers).

  The catalogue and the audit designed the mission and act layers well. **The session layer is the weakest** today: nothing in the design says how a session starts, where it may stop, or what pulls the player back the next evening.
- **Session hooks (§2):**
  - a *terugblik* card when the game opens (what changed, who is waiting, what is due);
  - a rule that every session can end at a *natural stop* (the dagstart) with at least one open loop;
  - seven hook types the content can use.
- **The Check wait is the biggest quit risk** (§2.4). A 3–14 day Check is dead time unless the game fills it. Fix: a *Intussen* panel (what happens while you wait, with the next beat's date), people to talk to, and a time skip that names what it skips.
- **Act cliffhangers (§3)** for all seven transitions, including the two chains of tier 3 (Act IV and the IT chapter) and their joint ending into tier 4. Each carries a person, a number and an open question, and is recalled in the next act's title card.
- **The hidden-reward map (§4)** lays D1–D34 over the acts and adds **ten for tier 3 (D35–D44)**:
  - each passes the principle check of audit §4.1;
  - every act has at least four discoverable rewards, at least one per principle, and one that only a *careful* player finds.
- **Pacing (§5):**
  - a target session mix of about 60 % main, 25 % side and 15 % people (estimate);
  - a breather after every main;
  - no two hard deadlines overlapping;
  - sides that plant mains;
  - for tier 3's two chains, an "idle chain" beat so neither chain is forgotten.
- **The "one more mission" pull (§6):** eight mechanisms, each tied to a content rule, plus a line the game will not cross. No real-time timers, no loss for stopping, no loot boxes, no streak punishment. Respect for people includes the player.
- **Check against "players keep playing" (§7):** a scored audit per act and per layer. Ten risks with fixes. The weakest spots:
  - the Act 0 opening hour;
  - the Check wait;
  - Act IV's eight-week hold (`t3_stop_starting`);
  - a player who never talks to anyone.
- **Playtest measures (§8)** for Merijn's own play, kept local, and **9 questions for Merijn (§9)**.

---

## 1. The loop in layers

| Layer | Length | The pull today (designed) | What is missing |
|---|---|---|---|
| **Moment** | seconds | A clue appears in the journal; the dialog meter moves (▲/▼); the cue "Er zit meer achter…"; a toast for a discovery | Feedback that the *A3 got better* when a deep clue is linked (a subtle "sterker bewijs" mark; never a score). |
| **Session** | 15–40 min | Nothing explicit | A start (terugblik), a natural stop (the dagstart), open loops at the stop, and wait-time filled (§2). |
| **Mission** | 2–6 sessions | A face, a stake, a number, a twist; the Check judges; a debrief that reads your numbers and ends on a question (audit §5.7) | The step between "A3 submitted" and "Check" (§2.4). |
| **Act** | 15–30 sessions | Opener, turn, crisis, climax, breather, cliffhanger (audit §5.1); a milestone; forks | Cliffhangers for tier 3's two chains (§3); a mid-act "where am I" moment. |
| **Campaign** | months | Belts, region maturity, the vitrine, path dependence, recurring characters | A visible *story of the player*: the strategy screens of tier 3 do this; earlier tiers need small echoes (§6, mechanism 7). |

**The core loop**, in the player's verbs: **kijken → praten → denken → proberen → meten → borgen**, and then the world pushes back (decay, drift, a new constraint).

Every verb has its own small reward:
- **kijken:** a clue;
- **praten:** a layer or a person's trust;
- **denken:** a stronger A3;
- **proberen:** the experiment running;
- **meten:** the Check's number;
- **borgen:** the fix holds, the *borgingsdividend*.

A session should touch at least two verbs; a mission touches all six.

---

## 2. Session hooks

### 2.1 How a session starts: the *terugblik*

When the game opens (not when a new in-game day starts), a card appears over the dagstart.

- **The heading:** Ruud's one line about the most important change since the last session, in his voice and never a lecture. E.g. "Het oudste dossier bij Werkvoorbereiding is weer onder de drie weken. Joost liet het me zelf zien."
- **Up to three lines, one of each:**
  - **Veranderd:** a number that moved since the last session, with its arrow (from the KPI board or the active Check).
  - **Wacht op je:** a person with a reason ("Petra · ze heeft iets gezien in De Kade" for a check-in; "Frank · de route is open" for a block route met; "Mevrouw El Amrani · u zou vrijdag bellen" for a promise).
  - **Komt eraan:** the nearest date (a Check result, a deadline, a beat), as a day name, not a countdown in hours.
- **One button:** "Naar de dagstart". No skip penalty; the card can be reopened from the journal.

**Why:** a returning player needs, in under ten seconds, a reason and a direction. The card never says *what to do*: it names people, numbers and dates, and the player decides.

### 2.2 Where a session may stop: natural stops

- **The dagstart is the natural stop.** Saving is always possible, but the game *suggests* stopping at a dagstart: the "Morgen" button carries a small "goed moment om te stoppen" note once a session passes about 30 minutes of real time (Q2).
- **At every natural stop, at least one loop is open:**
  - a Check running;
  - a person who said "kom morgen terug";
  - a clue chain at depth 1 of 2;
  - a promise with a date.

  The design rule for content: no mission step ends with *everything* closed except a mission's final debrief, and that debrief ends on a question or a callback (audit §5.7).
- **No session ends on a cold failure.** A ruined talk or a failed Check gives three things at the end-of-day card:
  - the moment it went wrong (the openness trace, or the Check's line);
  - when it can be tried again ("Joost praat morgen om 8.30 uur weer met je");
  - for a main mission, Ruud's one question.

  The player leaves with a next step, not a verdict (dialog scripts R-D4; never game over).

### 2.3 Seven hook types the content uses

Every main mission uses at least two; every act uses all seven.

| Hook | What it is | Example (from the drafts) | Content rule |
|---|---|---|---|
| **Gevolg** (consequence) | What you did last time changed something you can now see | "Lindeveld rijdt minder; het uur ging half naar de nieuwe jongens." | Debriefs and the terugblik read the player's numbers and facts. |
| **Klok** (clock) | A date with a face | Henk's farewell invitation; the September intake; KZW's electrolyser | Hard deadlines: at most one active (audit §5.6). Soft clocks are beats. |
| **Persoon** (person waiting) | Someone has something to say | The "…" bubble; Frank's route met; Marco "kom maandag bij de koffie" | Check-ins by signal (dialog spec §5.7); promises and conditions name a person. |
| **Getal** (number) | A KPI moved, and the reason is not yet known | Calls up 30 % after the portal change | Every main briefing names a number the player can verify (catalogue §2.11). |
| **Raadsel** (mystery) | A clue chain half-walked | "Waarom staat De Linde op plek 61?" | Main problems have a depth-2 key clue; the first clue raises a question, not an answer. |
| **Belofte** (promise) | Something the player said they would do | "Ik bel u vrijdag terug" (El Amrani); "Ik zorg dat Ruud tekent" (Femke) | Proposals that promise carry `promise` (dialog scripts Q11); kept promises pay trust, broken ones cost it. |
| **Terugval** (relapse) | A fix you made is slipping | The "Terugval" lane; Ruud: "Bij Intake staat weer een tweede bak." | The sustain rules (graded decay, drift) surface through missions, never as a free menu. |

### 2.4 The Check wait: filling dead time

**The risk.** After the A3, the experiment runs for 3–14 in-game days. The player can only wait or press "Morgen" repeatedly. This is the single most likely place for a session to end in boredom rather than at a natural stop.

**The fix, in three parts:**
1. **An *Intussen* panel** while a Check runs. It shows, as a short list:
   - the Check's date;
   - the next beats before it ("Dinsdag · Henks afscheid"; "Donderdag · kwartaalreview");
   - people with something to say;
   - the side missions that fit in the gap ("past in 5 dagen").

   It is information, never a nag.
2. **People fill the gap.** The check-in cadence (spec §5.7) prefers Check windows: a due check-in prompt is shown at the start of a Check window rather than in the middle of a hard investigation (a scheduling preference, not a new prompt).
3. **A time skip that names what it skips.** "Door naar de Check (6 dagen)" lists what will happen in between ("Je mist: het gesprek met Sanne kan ook later; de dagstart van dinsdag") and stops automatically at any beat with a person. Skipping is always allowed. It respects the player's time, and the stops keep the story from being skipped by accident.

**Measure (estimate):** the target is that no more than one in five sessions ends during a Check window with nothing done in it (§8).

### 2.5 The first hour

The first hour decides whether there is a second session. Today: the Monday tour, two places, two observations.

**Targets for the opening hour** (estimates, to check in playtest):
- **A face in the first two minutes:** the El Amrani letter (audit T1).
- **A person who talks in the first ten minutes:** Anouk's tutorial talk on Tuesday (dialog scripts §5). It is in the training week by design, so the meter is learned where nothing can be ruined.
- **A discovery within the first twenty minutes for a curious player:** D16 *Het eerste net* is possible on Monday (documents at `connections.revision`, where no problem is active). That is an Easter egg for someone who wanders, which is exactly the behaviour the game wants to reward.
- **A number that moves before the first hour ends:** Thursday's 3-day Check (training).
- **A cliffhanger at the end of the week:** "Maandag vraagt Joost om twee extra mensen. Ik heb gezegd dat jij eerst gaat kijken." (audit T5).

**Skippable for returning players**, as today.

---

## 3. Act cliffhangers

Design rules:
1. **A person, a number and an open question**, delivered as a beat at the act's last debrief.
2. **Recalled** in the next act's title card (Ruud), so a player who stopped between acts is pulled straight back in.
3. **Never a fake-out:** the cliffhanger's problem is the next act's opener or a mission in it.
4. **Path-dependent where possible:** the text names something the player did.

| Transition | Cliffhanger beat (NL) | Who · number · question | Next act's title card (Ruud) |
|---|---|---|---|
| **0 → I** | Ruud: "Mooi werk. Maandag vraagt Joost van Dijk het MT om twee extra werkvoorbereiders. Ik heb gezegd dat jij eerst gaat kijken." | Joost · two vacancies · is it people or the work? | "De eerste honderd dagen. Het MT kijkt mee, op dag honderd. Ik ook." |
| **I → II** | At the day-100 drinks, Ruud's phone: "Een graafmachine heeft een middenspanningskabel geraakt bij De Linde. Driehonderd huizen. Volgens de kaart lag daar niks." | Gert · 300 homes · how can a map be wrong? | "Wat onder de grond zit. Wat je niet ziet, kan je wel raken." |
| **II → III** | At the first KPI review, a red number: outage minutes rising. Kees from the control room: "Volgende maand wordt een storm voorspeld." Ruud: "Jij vindt de problemen. Ik wil dat de teams ze zelf zien." | Kees · outage minutes · who sees the problem first? | "Zichtbaar maken. Vanaf nu wil ik dat de borden het eerst weten, niet jij." |
| **III → IV** | The ACM's verdict letter (passed or not), then Ruud: "Je wordt CI-lead voor heel Zuidmark." Joke's call that evening: "Bij ons rijden ze een uur per klus. En er gaan er drie met pensioen." | Joke · one hour per job · is Lindeveld the same stream as Nova? | "Flow door de regio. Wat in Nova werkte, is geen recept. Het is een vraag die je in Lindeveld opnieuw stelt." (also mentions one discovery the player earned: audit §4.2) |
| **Mid-IV (the IT chapter opens)** | Esra, at the end of `t3_map_region`: "Weet je wat ik nog steeds niet snap? Ik vroeg in het voorjaar om een datum op het portaal. Die staat er nog steeds niet." | Esra · one date, eleven weeks · where does a change wait? | (No title card; a board card "Het digitale loket" with Noor's face.) |
| **Mid-IT (the twist)** | `fix_status_page_wrong`'s debrief: "En de echte voorspelling? Die staat klaar. Voor de release van maart." | Noor · March · why can't a finished fix go live? | — |
| **IV and IT → V** | Three letters on the same morning: the Raad van State on a permit; the MT's list "Twintig prioriteiten"; the NTA 8120 audit date. And Ricardo, at the van, shows his phone: a WhatsApp group with photos of meter cupboards. "Dit is onze echte app." | Ricardo · twenty priorities · who decides what matters? | "Het systeem. Twintig prioriteiten is er geen. Wat is de ene?" |
| **V → finale** | (Placeholder, catalogue.) Lotte, the new CI lead of Lindeveld, knocks: "Ik heb gehoord dat jij vragen stelt in plaats van antwoorden geeft. Wil je dat bij mij ook doen?" | Lotte · — · can you coach without telling? | (finale placeholder) |

**Path-dependent variants** (one line each, chosen by facts):
- **I → II:** if `review_100_days` failed, Ruud adds "De tijdelijke krachten zitten er nu. Laten we zorgen dat ze straks niet meer nodig zijn."
- **III → IV:** if `failed:acm_visit`, Joke's call is the same, but Ruud's title card begins "We hebben een plan voor de ACM. En een regio die niet wacht."
- **IV → V:** if `flag:hidden_wip`, the audit letter has a second page: "Wij verzoeken u de aanvraagdata vanaf de datum van aanvraag aan te leveren." The player knows what that means.

---

## 4. The hidden-reward map across tiers

### 4.1 Where the existing rewards live

From the audit (D1–D28; D11, D17 and D20 dropped) and the dialog spec (D29–D34). "Any" means it can fire in any act.

| Act | Rewards that can fire here (first chance) | By principle (LT · RP · AI) |
|---|---|---|
| 0 | D16 Het eerste net; D22 De hele cyclus (training mission) | — · — · AI |
| I | D1 Scherpe blik; D2 Veilige haven; D3 Excuses aanvaard; D4 Het knelpunt eerst; D5 Leren van de Check; D6 Terug naar de gemba; D8 Ritme; D9 Nachtdienst; D10 Voorspeller; D12 Faalvraag-jager; D13 Henks mes; D14 Het dossier van de familie El Amrani; D19 Capaciteit gevonden (across I–II); D21 Een andere weg; D24 Nog één waarom; D29–D34 (dialogs) | LT (D13, D21) · RP (D2, D3, D13, D29–D34) · AI (D1, D6, D24) |
| II | D7 Een jaar later (first fixes reach 365 days in Act III–IV); D15 Wims spreadsheet; D18 Goodhart ontweken; D25 De lange adem (first holds at 180 days); D28 Eerst veilig, dan beter | LT (D7, D25) · RP (D28) · AI (D18) |
| III | D23 Zelf coach; D26 Ontwikkelen, niet vervangen; D27 Niemand opgebrand | LT · RP (D23, D26, D27) · AI |
| IV, IT | **D35–D44 (new, §4.2)** | see §4.2 |
| Any | D2 (per act), D7 (per problem), D27 (per act) | |

**Gaps found:**
1. **Act 0** has only one real discovery. Fine for a tutorial week, but the first one should be easy to stumble on (D16 is).
2. **Act II** has few rewards of its own; most of its rewards are *time-based* (D7, D25) and arrive later. Proposed: no new reward. Instead, move the end-of-act hint for D15 to Act II (Wim's spreadsheet is possible there), so the act-end codex shows one solvable silhouette.
3. **Tier 3** has none of its own. Added below.

### 4.2 Ten new rewards for tier 3 (D35–D44)

Same rules as audit §4.1:
- unannounced;
- they reward learning, never a shortcut;
- small in power, big in meaning;
- detectable, and once each;
- every one also requires quality;
- every fork branch can earn something;
- deep thinking first.

| # | Name (NL) | Trigger (detectable) | Reward | Principle | Anti-shortcut guard |
|---|---|---|---|---|---|
| D35 | **Het uur van Joke** | `committed:joke_depot` with `half_hour_for_training` on the table, and 180 days later Lindeveld's apprentices work alone ≥ 2 months sooner than Nova's (C17c ramp data) | V: a thermos with "Oosthoek" on it; R ("Tijd die vrijkomt, is geen gat om te vullen. Het is ruimte om te groeien.") | RP, LT | Needs the measured ramp gain, not only the choice. |
| D36 | **Eén straat** | `joint_street_planning` chosen with `committed:marloes_one_agenda`, and the Havenstraat has had no second opening for 365 days (the countermeasure holds ≥ 0.9) | V: a cobblestone from the Havenstraat; S on joint underground planning | LT | Needs a year of hold. |
| D37 | **Geen aggregaat** | `fix_nitrogen_permit` solved before its deadline with the diesel bridge declined, and the KZW electrolyser connected on time | V: a hydrogen-blue hard hat; Rep +2 | LT | Declining alone earns nothing; the deadline must be met. |
| D38 | **De lege map** | `t3_stop_starting` passed with the concept folder declined, and the Act V audit's application-date check finds nothing hidden | T "Eerlijk getal"; R on Goodhart ("Wat je niet meet, verbergt zich niet. Het wacht.") | LT, AI | Only checked at the Act V audit, so it cannot be gamed in Act IV. |
| D39 | **Gewone taal** | Noor's commitment with `listen_with_esra`, status calls down ≥ 30 % (Check), and `forecast_from_planning` live (directly or through the repair quest) | V: Esra's headset; S on failure demand in IT | RP, AI | Needs the forecast shipped, so it includes the release lesson. |
| D40 | **Klein en vaak** | 10 consecutive releases (`it_features.release`) with no incident linked to them, after `ci_cd_pipeline`, with `flag:skipped_tests` never set | T "Klein en vaak"; R on Reinertsen ("Kleine stappen zijn veiliger dan grote; ze voelen alleen niet zo.") | LT | The no-skipped-tests guard; a streak of quality, not of speed. |
| D41 | **De boer met de windmolen** | Hanneke's edge-case suite (`hanneke_writes_first` or `edge_cases_first`) catches a defect before release: a sim event when a change touches a tagged edge case | V: a toy wind turbine on Hanneke's desk, then in the vitrine; Tr +1 testers | RP | An event the player cannot cause directly; it rewards the people-first choice made earlier. |
| D42 | **Wie het vroeg** | The crew strategy chosen with Marco's commitment through `volunteers_first` or `rotation_quarter`, no overtime option, and no monteur in a moved crew leaves within 180 days | T "Wie het vroeg"; Marco's postcard from the Lindeveld depot | RP | Needs the 180-day retention, not just the talk. |
| D43 | **De cirkel** | A person the player coached (D23) completes a `coach` session of their own with someone else (Joost coaching Anouk after `coach_work_prep_lead`; a beat with a check) | V: a second Kata card, in Joost's handwriting; R ("Je bent pas klaar als zij het zonder jou kunnen.") | RP, AI | Needs the player's own coaching done by the book first. |
| D44 | **Eerst wie het nodig heeft** | `classify_at_intake` with Jeroen's commitment and the sports-hall temptation declined, and De Linde's extension connected within the act | V: a thank-you drawing from De Linde's residents; Rep +2 | RP, LT | Needs the declined favour and a delivered priority customer. |

**After the principle check, dropped:**
- **"Snelle trein"** (a PI with ≥ 90 % predictability): it could be earned by committing to very little, so it rewards sandbagging.
- **"Zonder consultant"** (a whole act without the bureau): an absence of a choice, not an act of skill. D34 *Geen druk nodig* already covers the pattern.

### 4.3 Distribution check

| Act | Discoverable rewards with a first chance in the act | LT | RP | AI | One for the careful player |
|---|---|---|---|---|---|
| 0 | 2 | — | — | ✓ | D16 (wander) |
| I | 21 (incl. D29–D34) | ✓ | ✓ | ✓ | D9 (night shift) |
| II | 5 | ✓ | ✓ | ✓ | D15 (the right hour) |
| III | 3 + any-act | ✓ | ✓ | (D27) | D23 |
| IV + IT | 10 (D35–D44) + any-act | ✓ | ✓ | ✓ | D41 (an earlier choice pays off unseen) |
| V | (catalogue: D7/D25 holds, D21; the tier-4 draft should add 4–6) | | | | |

Act I is rich because it is where the player learns the game's verbs. The risk is the opposite: **too many toasts early** can make discoveries feel cheap. Rule: **at most one discovery toast per in-game day.** A second is queued for the next dagstart, where the terugblik names it ("Ontdekking · Nachtdienst"). That gives the return session a small gift.

---

### 4.4 Hints at the end of an act

Audit §4.2 decided: unfound discoveries of an act show a cryptic hint when the act ends. Proposed hint lines for D35–D44 (the act-end codex):
- D35: "Een uur dat vrijkomt, kun je maar één keer weggeven."
- D36: "Sommige straten gaan te vaak open."
- D37: "Een snelle brug kan langzaam maken."
- D38: "Een lege map is ook een getal."
- D39: "Wie de pagina schreef, had de klant nooit gehoord."
- D40: "Klein en vaak, zonder iets over te slaan."
- D41: "Iemand onthield de rare gevallen."
- D42: "De kaart ziet stippen."
- D43: "Een vraag kun je doorgeven."
- D44: "Wie niet belt, staat achteraan. Hoe lang nog?"

---

## 5. Pacing of main versus side

### 5.1 Targets per act (estimates)

Sessions are 15–40 minutes (GDD). In-game time per session varies widely: a Check skip can cover a week.

| Act | Mains | Sides (incl. recurring) | Milestones | In-game duration (estimate) | Sessions (estimate) | Session mix: main · side · people |
|---|---|---|---|---|---|---|
| 0 | 5 (training) | (1 handed out) | — | 1 week | 2–3 | 80 · 10 · 10 |
| I | 4 + fork | 9 | day 100 | ~100 days | 12–18 | 60 · 25 · 15 |
| II | 7 | 6 | — | ~120 days | 12–16 | 60 · 25 · 15 |
| III | 5 + fork | 9 | ACM visit | ~180 days | 15–20 | 55 · 30 · 15 |
| IV | 9 + fork | 8 | — | ~200 days (parallel with IT) | 15–20 | 55 · 30 · 15 |
| IT (tier 3) | 5 + fork | 4 | — | parallel with IV | 10–14 | 55 · 30 · 15 |

"People" means talks that are not a mission's `talk_to` goal (check-ins, voluntary talks, the coach). The 15 % is a target, not a quota. A player who talks less is not punished (§7, risk R7).

### 5.2 Rules

1. **After every main, a breather.** The next main does not open the same in-game day. The board shows the sides that fit, and one check-in prompt is preferred for that window. Exception: a fork opens both branches at once, by design.
2. **No two hard deadlines active at once** (audit §5.6), across both tier-3 chains. The chain order already guarantees it: Henk is Act I; storm and heat are Act III seasons; training and nitrogen are sequential in Act IV; the IT chain has none. The validator checks `deadline_days` windows against the `requires` graph.
3. **Sides plant mains.** Every side's debrief or last beat points at a later main (audit §5.4).
4. **Side slots are a trade-off from Act III on.** Routines (`lsw_*`) and side problems share three slots (catalogue §2.9). The board shows each routine's next due date. The player chooses: a routine now, or a side problem now.
5. **At most two new side offers per in-game week.** If more sides unlock at once (after `t3_map_region`, five can), the board reveals them over two weeks, each with a beat from its person. Five cards at once read as a to-do list; two a week read as a world.
6. **The idle-chain beat (tier 3).** If one chain (grid or IT) has had no main progress for 45 in-game days, a person from that chain gets a short beat ("Noor: Het team vraagt of je nog langskomt. Er ligt iets klaar." or "Joke: Het depot staat. Wanneer kom je kijken?"). It is information, not a penalty, and once per idle stretch.
7. **The longest main is never followed by another long main.** Act IV's `t3_stop_starting` (an eight-week hold) is followed by the act's end. The IT chain's shorter missions sit beside it, so a player who wants action has some during the hold.

### 5.3 Shape sequence across tier 3

The audit's mix rule (no two consecutive mains of the same shape) extended to tier 3:

- **Act IV:** follow-the-stream (map) → investigation + people (long drives) → crisis with a clock (training) → strategic choice (crew) → fork dilemma (Havenzij) → people (kaizen, the team leads) → data puzzle + people (priority) → crisis with a clock (nitrogen) → sustain (stop starting).
- **IT:** follow-the-change (map) → investigation with a twist (status page) → people (release, Erwin) → fork dilemma → people + data (regression, Hanneke) → strategic and people (PI, Carla).

No two adjacent mains share a shape. Both chains include every shape the audit's §5.2 requires per act.

---

## 6. The "one more mission" pull

Eight mechanisms, each tied to a content rule that already exists or is proposed here:

| # | Mechanism | How it shows | Content rule |
|---|---|---|---|
| 1 | **The debrief points at the next constraint** | "Als Werkvoorbereiding nu sneller is, waar gaat het werk dan wachten?" | Every main debrief ends on a question that the next main answers (audit §5.7). The shifted bottleneck is the game's natural "next". |
| 2 | **The next hook is visible at once** | The board card of the next mission appears with a face and a number in the same debrief screen | Each main's `beats.on: completed` introduces the next main's person when it is the one that unlocks. |
| 3 | **Partial progress is visible** | The dialog layer tracker (Standpunt · Belang · Zorg); the belt bar; the vitrine's silhouettes; the region map greying in as areas are walked | Dialog scripts Q3; audit §4.2. |
| 4 | **A short first step** | Every mission's first meaningful action takes ≤ 5 minutes of real time: a talk, one tool, a walk to a place | Content check: the briefing names a place and a person; the first key clue is depth 0 at that place. |
| 5 | **Open loops** (Zeigarnik) | An unfinished clue chain, a person who said "morgen", a Check running | §2.2: every natural stop leaves a loop open. |
| 6 | **Variable reward** | Discoveries arrive unannounced (audit §4) | ≤ 1 toast per day (§4.3); rewards for learning, never for grinding. |
| 7 | **People come back** | Henk's postcard, Wim's Christmas card, Mrs El Amrani's mother, Marco at day 100, Ahmed with two apprentices | Recurring cast and arcs (audit §5.3); `beats_after` (dialog scripts). The player's story is told back to them by people. |
| 8 | **The future is forecast** | The KPI board's counterfactual; the strategy screen's forecasts; the A3's lifecycle cost (audit R1) | "What if" is always visible before a choice, never the answer. |

**What the game does not do** (respect for people includes the player):
- **No real-time timers:** nothing decays while the game is closed; in-game time stops.
- **No loss for stopping:** no streaks that break, no daily login rewards.
- **No loot boxes** and no random paid rewards.
- **No guilt.** Check-in prompts expire without cost (dialog spec §5.7); the terugblik never says "je bent lang weggeweest".
- **No artificial scarcity of the player's time:** the time skip is always available (§2.4).

These match the game's own values. A game that teaches "people are the most valuable resource" and "burning people out costs" should not burn out its player.

---

## 7. Check against "players keep playing"

### 7.1 Scored audit (1–5; designed content, not yet built)

| Layer | Act 0 | Act I | Act II | Act III | Act IV | IT (t3) |
|---|---|---|---|---|---|---|
| Moment (something to notice now) | 3 | 4 | 4 | 4 | 4 | 4 |
| Session (a reason to sit down and a good place to stop) | 2 → 4 with §2 | 2 → 4 | 2 → 4 | 2 → 4 | 2 → 4 | 2 → 4 |
| Mission (a mystery with stakes) | 3 | 4 | 4 | 4 | 4 | 4 |
| Act (an arc with a peak and a cliffhanger) | 3 | 5 (day 100) | 4 | 5 (ACM, storm) | 4 → 5 with the strategy screen | 4 (the March twist) |
| Campaign (people, history, mastery) | 2 | 4 | 4 | 4 | 5 (path dependence on screen) | 4 |

The session layer is the gap at every act. §2 is the fix, and it is mostly UI and scheduling, not new content.

### 7.2 Risks and fixes

| # | Risk | Where | Fix |
|---|---|---|---|
| R1 | The opening hour is slow (two observations on Monday) | Act 0 | §2.5 targets: a face in 2 minutes, a talk in 10, a discovery possible in 20, a number moving within the hour. |
| R2 | **Dead time during Checks** | every mission | §2.4: the *Intussen* panel, people in the gap, a named time skip. |
| R3 | **An eight-week hold** with nothing new | `t3_stop_starting` (Act IV) | The IT chain runs beside it. A mid-way beat at week 4 (Joost or Frank) shows the WIP falling. The goal's weekly samples show as a streak on the board (§6, mechanism 3). |
| R4 | Long deadlines are forgotten | `fix_nitrogen_permit` (120 d), `fix_training_capacity` (63 d) | The HUD countdown for the active deadline only; a beat at two-thirds (Ruud at day 90 / day 42, as drafted); the terugblik's "Komt eraan". |
| R5 | Five sides at once read as a to-do list | after `t3_map_region` | §5.2 rule 5: at most two new side offers a week. |
| R6 | One chain starves in tier 3 | grid versus IT | §5.2 rule 6: the idle-chain beat. |
| R7 | **A player who never talks** to anyone | all | Talks are optional clue sources (dialog spec §5.1), so the game stays playable. But the missed people are *felt*: debrief variants that name who was not asked ("Marco vertelt je niets meer dan nodig"), and the strategy screen's locked options. The pull is curiosity, not a gate. |
| R8 | Toasts feel cheap in Act I | Act I | ≤ 1 discovery toast per in-game day (§4.3). |
| R9 | A ruined talk or failed Check ends a session on a bad note | all | §2.2: the end-of-day card always gives the moment, the retry time and, for a main, Ruud's question. |
| R10 | The IT track feels like a different game | tier 3 | It starts at the customer the player already knows (the portal, El Amrani, Esra) and keeps the same verbs, tools, people and Check. The release twist ties it back to the grid's own lesson (batches). |

### 7.3 Verdict

With §2 (session hooks and the Check wait), §3 (cliffhangers for every transition) and §5.2 (side offers and the idle chain), the design meets "players keep playing" at every layer, with the session layer raised from 2 to about 4.

What remains unknown is real pacing: how many real minutes a mission takes. Only playtesting can say (§8).

---

## 8. Playtest measures (for Merijn's own play)

A small local log, never sent anywhere: a file in the save folder, readable as text, with an opt-out in the settings (privacy and respect, Q8). It records:

| Measure | Why | Target (estimate) |
|---|---|---|
| Session length (real minutes) | The GDD's 15–40 minutes | median 20–35 |
| Where a session ended (dagstart, mid-dialog, during a Check, mid-investigation) | Natural stops versus quitting | ≥ 70 % at a dagstart |
| Open loops at the end of a session | §2.2 | ≥ 1 in ≥ 90 % of sessions |
| Real minutes from mission accept to first key clue | §6 mechanism 4 | ≤ 5 |
| Sessions ending during a Check window with nothing done in it | §2.4 | ≤ 20 % |
| Time to first discovery (a curious player) | §2.5 | ≤ 20 minutes |
| Dialogs ruined in a row, then quit within 5 minutes | R9 | rare: zero in a playtest of an act |
| Main/side/people share of session time | §5.1 | within ±15 points of the act's targets |

---

## 9. Questions for Merijn

Each has a recommended option (**bold**).

1. **The terugblik card when the game opens.** **(a) Yes: one line from Ruud, up to three lines (Veranderd · Wacht op je · Komt eraan), one button.** (b) No card; the dagstart is enough. *(a) answers a returning player's first question, "where was I?", in ten seconds without telling them what to do.*
2. **A "good moment to stop" note at the dagstart after ~30 real minutes.** **(a) Yes, small and quiet.** (b) No. *(a) treats the player's time with respect; it also makes the dagstart the natural cliffhanger point.*
3. **The *Intussen* panel and a named time skip during a Check.** **(a) Yes, both; the skip stops at beats with people.** (b) Only the skip. (c) Neither. *The Check wait is the biggest quit risk in the design.*
4. **At most one discovery toast per in-game day** (others queued to the next terugblik). **(a) Yes.** (b) No limit. *(a) keeps discoveries special and gives the return session a gift.*
5. **At most two new side offers per in-game week.** **(a) Yes.** (b) Show all that unlock at once. *(a) turns a list into a world.*
6. **The idle-chain beat in tier 3** (after 45 days without progress in one chain). **(a) Yes, once per idle stretch.** (b) No; the player chooses freely. *(a) is information, not pressure, and keeps the IT track from being forgotten.*
7. **The ten tier-3 discoveries (D35–D44).** **(a) Add all ten.** (b) Fewer: D37, D38, D40, D42 and D44 only. *Each passed the principle check; (a) gives tier 3 the same density as Act II.*
8. **A local playtest log.** **(a) Yes: a readable text file in the save folder, opt-out in settings, never sent.** (b) No log. *Only real play can tell whether a mission takes 20 or 60 minutes.*
9. **Lines the game will not cross** (§6: no real-time timers, no loss for stopping, no streaks, no guilt). **(a) Record them as a design rule in CLAUDE.md §2 next to "Setbacks, never game over".** (b) Keep them in this doc only. *They follow from "respect for people" and protect the game from engagement tricks later.*

---

## Sources

- Zeigarnik, B. (1927). "Über das Behalten von erledigten und unerledigten Handlungen." *Psychologische Forschung* 9, 1–85: unfinished tasks are remembered and pull attention (open loops, §2.2, §6).
- Ryan, R. M. & Deci, E. L. (2000). "Self-determination theory and the facilitation of intrinsic motivation, social development, and well-being." *American Psychologist* 55(1), 68–78: autonomy, competence and relatedness.
- Ryan, R. M., Rigby, C. S. & Przybylski, A. (2006). "The motivational pull of video games: a self-determination theory approach." *Motivation and Emotion* 30(4), 344–360: competence and autonomy predict enjoyment and future play; the basis for "people come back" and "choices with consequences" over compulsion loops.
- Csikszentmihalyi, M. (1990). *Flow: The Psychology of Optimal Experience*: challenge matched to skill (the difficulty curve, catalogue §3.1).
- Hodent, C. (2017). *The Gamer's Brain*: onboarding, the first hour and cognitive load (§2.5, the terugblik).
- Schell, J. (2008). *The Art of Game Design: A Book of Lenses*: the lenses of curiosity, surprise and the "interest curve" behind §3 and §7.
- Audit, catalogue, tier-2 and tier-3 drafts, the dialog spec and the Acts 0–II dialog scripts in this folder, for every mission, character and reward named here.
