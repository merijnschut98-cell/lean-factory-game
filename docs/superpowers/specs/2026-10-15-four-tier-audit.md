# Four-tier audit: missions, facts and dialogs (tiers 1–4 and the IT track)

> Status: by the mission and dialog design agent (Claude, 2026-10-15; **finished 2026-10-16**, PLAN 1.6). **Docs only.** Every fix below is applied in the design docs; the builder applies them to `content/` when each tier enters it. New: the route simulator (§4.4), the principles check (§5), a voice sheet per recurring person (§6) and the content-test rules that keep the limits (§7).
>
> Scope: `content/missions.yaml` (tier 1), the tier-2 draft, the tier-2 dialogs, the tier-3 and tier-4 drafts, the Acts 0–II scripts, the catalogue and the engagement loop.
>
> Method: scripts over every YAML block in these docs (88 dialogs, 97 missions, 57 problems, 178 countermeasures), plus reading by hand.

## 0. Summary

| # | Finding | Severity | Status |
|---|---|---|---|
| A1 | **Requirement cycle in the IT chain.** `fix_release_twice_a_year` required `fix_status_page_wrong`, which moved to tier 4 and (via `fix_team_dependencies` → `fix_pi_overcommit` → … → the release fork) required the release again. Nine IT mains were unreachable. | Critical | **Fixed** (tier-3 draft: now requires `fix_field_app_bypassed`). The reachability check now reaches every main. |
| A2 | **Fact names read but never set** (§1). | High | **Fixed** 2026-10-16 in the drafts. |
| A3 | **Tier-2 draft promises to Act V that the tier-4 draft missed** (§1.2). | High | **Fixed** 2026-10-16 in the tier-4 draft. |
| A4 | **Temptations with no later payoff** (§1.3). | Medium | **Fixed** 2026-10-16: all 43 temptations now have a later cost that some rule reads (§5.1). |
| A5 | **Side offers pile up**: up to 7 open at once when `t2_daily_boards` completes; 15–21 for a player who skips sides (§2). | Medium | **Fixed** 2026-10-16: six sides staggered; the bursts are now 3 / 5 / 2 (§2). The UI drawer and the one-hard-deadline rule stay builder tasks. |
| A6 | **Dialogs are formulaic across tiers** (§4). | High: a player would quit on rote talks | **Fixed** 2026-10-16: 101 outcome lines rewritten per voice, 32 concerns cued by a feeling, interest `via` by archetype on 46 dialogs, routes re-checked by a simulator (§4.4): the content is fixed, but the engine's numbers still let one listening route win every talk; five engine changes are proposed (E1–E5) and tiers 3–4 need more structural variety. |
| A7 | **Mission shapes**: no consecutive repeat found in the main chains (§3). | — | Checked. |
| A8 | Tier-4 questions marked decided (standing rule). | — | **Done.** |
| A9 | **Temptations that complete a goal at once pay full reward** (`bought_vsm`, `dashboard_not_board`, `mandates_skipped`, `t3_consultants`): a quick win that costs the future scores the same as the patient fix (§5.2). | Medium | **Proposed rule** for the builder: such a goal pays half, like compliance. |
| A10 | **Tier-1 missions in content carry no `principles`** (§5.3). | Low | **Proposed** assignment in §5.3. |
| A11 | **A date error in `el_amrani_fourth_call`**: the dates she quotes predate her request. | Medium (correctness) | **Fixed** 2026-10-16 (drie-winters §3); a date-sanity content test proposed (§7, T9). |

## 1. The facts chain, end to end

### 1.1 Read but never set (script)

| Fact | Read in | Fix (owner) |
|---|---|---|
| `flag:curtailment_letter` | tier-3 `aziz_coldchain` | The tier-2 draft sets `flag:solar_curtail_letter`; rename the reader in tier 3 (mine). **Done 2026-10-16.** |
| `flag:late_clock` | tier-2 dialogs `acm_inspector` | The tier-2 draft sets `flag:acm_clock_gamed`; rename the reader (mine). **Done 2026-10-16.** |
| `flag:lindeveld_overtime` | tier-3 §0.1 schema example | Should be `flag:lindeveld_allowance` (mine). **Done 2026-10-16.** |
| `flag:rest_rule` | tier-2 dialogs §6 | It is a consequence of `committed:ruben_storm`; set it via `unlocks`/`sets_flags_on_commitment` or read the commitment directly (mine). **Done 2026-10-16:** `ruben_storm` sets it on commitment (`sets_flags_on_outcome`), and so does the storm scene `storm_night_board` (drie-winters §7.4). |
| `flag:henk_postcards` | Acts 0–II scripts | It is set by `sets_flags_on_lifted`, a field the script did not scan. **No fix needed.** |
| `committed:ruud_backs_obeya` | dialog spec §7.4 | **Done 2026-10-16:** applied to the dialog spec §7.4 (route 2 is now the two team leads' partials). |
| `flag:okr_region` | tier-2 draft | **Done 2026-10-16:** `t2_first_okr` sets it (`sets_flags`); `lsw_catchball` reads it as `{catchball_start}`. |

### 1.2 Tier-2 promises to Act V not honoured in the tier-4 draft (done 2026-10-16)

All six are applied in the tier-4 draft. Two needed small schema additions, listed in §7: `holding_correction` on an audit finding, and `fit_modifiers` on a problem. The `acm_clock_gamed` finding is waived by an honest connections KR (`picked:t2_first_okr:kr_conn_on_time`, a new fact kind).

1. **`flag:acm_clock_gamed` at the NTA 8120 audit.** The tier-2 draft says it is a data-integrity finding, reputation −15, and one fix fewer counted as holding.
   - Add it to `nta8120_audit.findings`.
   - The "one fewer" is a correction of the measure, not a finding deciding the verdict, so it fits decided Q3.
2. **`flag:cause_field_policed`** should lock `fault_pareto` (`none`), with `repaired:cause_unknown` as the way back.
3. **`flag:okr_region`** should be read by `lsw_catchball` (the region's OKR as catchball's starting point).
4. **`chose:heatwave_overload:peak_load_list_smart_meters`** becomes an extra `any` branch of "Sensoren in het LS-net".
5. **`flag:map_all_red`:**
   - flex fits −0.1 in `fix_flex_market_unused` unless `repaired:stale_capacity_map`;
   - "Flex eerst, koper later" gets `none: [flag:map_all_red]`.
6. **`flag:dug_without_klic`** becomes an audit finding (the tier-2 draft's "fail-safe beat in Act V").

### 1.3 Set but not paid off (done 2026-10-16)

Applied: `flag:test_factory` carries the aftermath, blocks D41 and clears on the repair; `flag:peak_temps` runs until `repaired:uneven_release` and the investment plan's forecast and screen name it; `flag:crew_trainer_pairs` makes "Opleiden" 30 % cheaper. Found while checking all 43 temptations (§5.1): `flag:status_faq` had no later cost; it now fades, blocks D45 and gives Esra a line.

| Flag | Fix |
|---|---|
| `flag:test_factory` (tier 3) | Apply `offshore_test_factory`'s aftermath (incidents ×1.2 from day 60) to the accepted temptation; D41 cannot fire; cleared by `repaired:manual_regression`. |
| `flag:peak_temps` (tier 3) | Its €900 a week continues; add it to the tier-4 investment plan's forecast list and give it a path note. |
| `flag:crew_trainer_pairs`, `crew_daytime_reserve`, `crew_havenzij`, `crew_freed_hours` | Their effects persist in the simulation, so the forecast carries them. Add one explicit read: `crew_trainer_pairs` makes "Opleiden: twaalf aankomend monteurs" 30 % cheaper. |
| `flag:plan_*` (tier 4) | Reserved for the finale; no fix needed. |

`talk_netplanner` is a catalogue mission not yet in `content/` (the builder's K-list).

## 2. The 1 + 3 rule at the busiest moments

- **One main at a time holds** in every chain. Forks offer two mains, and the grid and IT chains run in parallel from `t3_map_region`. That is a choice of chain, not two active mains.
- **Side offers burst:**

  | Moment | Sides that open at once |
  |---|---|
  | `t2_daily_boards` done | 4 sides (safety stock, LMRA, regulation, coach Sanne), plus 2 seasonal, plus `fix_stale_capacity_map` |
  | `t3_map_region` done | 3 sides, plus the household rush (July), plus the layered audit, plus 2 IT sides after `it_map_feature_stream` |
  | `t4_hoshin` done | 2 sides, plus catchball |

- **Worst case:** a player who skips sides has 21 offers open by Act V, from Act I's `walk_outages` on.
- **Proposals (staggers applied 2026-10-16 in the drafts and the catalogue):**
  - **Stagger openings (mine, tiers 3–4):**
    - `coach_work_prep_lead` after `t3_kaizen_week`;
    - `fix_solar_feedin_wait` after `fix_long_drives`;
    - `fix_gas_phaseout` after `fix_maintenance_calendar`.
  - **Stagger openings (tier-2 draft owner):**
    - `talk_regulation` after `fix_contractor_rework` (ACM preparation);
    - `fix_lmra_tickbox` after `fix_cause_unknown`;
    - `coach_intake_lead` after the outage fork.
  - **Builder (UI):** the mission board shows at most three new side offers; older ones fold into a "Nog open" drawer, with no loss (Respect the player's time).
  - **Builder (runtime):** a seasonal side with a hard deadline (storm, heatwave) opens only when no other hard deadline is active. Seasons repeat, so nothing is lost. This keeps "at most one hard deadline".

## 3. Mission shapes (no repeat twice in a row)

Main chains classified (audit §5.2 shapes):
- **Act I:** follow → investigation → fork → people/data → investigation.
- **Act II** (content order): crisis → investigation → data → investigation → data/people → people → KPI review.
- **Act III:** routine → data → fork → people → investigation → milestone → OKR.
- **Act IV:** map → investigation → crisis → strategy → fork → kaizen → people → crisis → sustain.
- **IT:** map → people → investigation → fork → investigation → people → investigation → people + twist → data at source → sustain.
- **Act V:** people/strategy → investigation → fork → people → strategy.

No two consecutive mains share a shape. The repeat that does exist is structural, not a shape: every main has one temptation and one persuasion talk (§4).

## 4. Dialog quality across tiers

### 4.1 Formula drift (script counts, 85 dialogs with outcomes)

| Pattern | Acts 0–II | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|---|
| commitment starts "Afgesproken." | 12/32 | 14/20 | **22/22** | 10/11 |
| ruined starts "Zie je." | 1/32 | 3/20 | 3/22 | **9/11** |
| heard says "Je vroeg…" | 0/32 | 6/20 | 2/22 | **9/11** |
| concern cue is a hesitation (so silence is always the key) | 32/32 | 20/20 | 22/22 | 11/11 |
| interest `via` is the same three moves (open question, inquiry, paraphrase) | most | all | all | all |

- The voices drift toward one narrator, worst in tier 4.
- The mechanics drift toward one route. In tier 3, nine defender talks share the route "open question > paraphrase > inquiry > show data > silence > propose > ask", and six rule-bound talks share another. A player who learns one route wins every talk: rote, the biggest quit risk.

### 4.2 Fixes (done 2026-10-16)

**Result** (script counts after the rewrite; `opener` = the outcome line up to its first punctuation, counted per outcome kind):

| Pattern | Acts 0–II | Tier 2 | Tier 3 | Tier 4 | Limit |
|---|---|---|---|---|---|
| commitment starts "Afgesproken." | 8/32 | 6/20 | 6/22 | 2/11 | ≤ a third |
| ruined starts "Zie je." | 1/32 | 3/20 | 3/22 | 2/11 | ≤ a third |
| heard starts "Je vroeg…" / "U vroeg…" | 0/32 | 5/20 | 2/22 | 2/11 | ≤ a third |
| compliance starts "Prima." | 6/32 | 6/20 | 6/22 | 1/11 | ≤ a third |
| partial starts "Ik doe mee." | 6/32 | 6/20 | 5/22 | 2/11 | ≤ a third |
| concern cued by a **feeling** (reflect or empathy is the key; silence misses) | 12/32 | 8/23 | 8/22 | 4/11 | ≥ a third |
| interest `via` follows the archetype table | all | all | all | all | — |

- **Outcome lines:** 101 lines rewritten in the person's own voice (4 in Acts 0–II, 20 in tier 2, 43 in tier 3, 34 in tier 4). The new openers come from the voice sheet (§6): Petra "Klopt.", Femke "Dat past.", Marco "Klaar." / "Kijk.", Wendy "Zo doen we dat dan.", Joost "Even voor de duidelijkheid:", Rob "Conform.", Carla "Toegezegd.", Hermans "Akkoord.", Mieke "Dat moet kloppen", Noor's Jira words, Sjaak's "Kort dan:".
- **The cue rule changes** (dialog spec §3.7 and validator rule 9, edited): the cue shows on the concern's lead-in whether it is tagged `hesitation` or `feeling`. A feeling lead-in names the emotion ("Ik word daar onrustig van."), its concern `via` holds `reflect` and `empathy` and never `silence`. Each changed dialog carries a dated comment.
- **Interest `via` by archetype** (applied to 46 dialogs; others already matched):

  | Archetype | Interest `via` | Why |
  |---|---|---|
  | craftsman | inquiry, open_question | they open to a real question about the work, not to a summary |
  | defender | paraphrase, open_question, inquiry | they need to hear their position back first |
  | overloaded | empathy, mood, open_question | they open to being seen, not to analysis |
  | cynic | paraphrase, inquiry | an open question gets sarcasm; a precise summary gets respect |
  | rule_bound | inquiry, paraphrase | precise questions about the rule and its reason |
  | quiet | open_question, mood, silence | room and time |
  | customer_upset | paraphrase, empathy | heard first, then felt |
  | relational (Thomas) | reflect, open_question, paraphrase | he talks in people; name the feeling about them |

**The original plan, kept for the record:**

1. **Rewrite outcome lines per voice.** No opener may appear in more than a third of a tier's dialogs. Order: tier 4 (all 11), then tier 3 (commitment lines), then tier 2.
2. **Vary the concern cue.** In about a third of dialogs, make the lead-in a *feeling* (reflect is the key) rather than a hesitation (silence is the key).
   - Tier 4: Theo, Thomas, Mieke.
   - Tier 3: Joke, Aziz, Verhoeven, Noor (`noor_field_app`).
   - Tier 2: Inge, Petra, Femke.
   - Rewrite each lead-in text as an emotion ("Ik zeg het u eerlijk: ik word er onrustig van."), and update its route comment.
3. **Vary interest `via` by person.**
   - Craftsmen reveal to inquiry, not paraphrase (Harrie, Tim).
   - Relational people reveal to reflect (Thomas).
4. **Vary the hidden proposal's kind.** "Let them own/design it" is the answer in most tier-3 talks. Keep tier 4's mix (shared decision, safety rule, transparency with a cap, checkpoints, development, protection) and rebalance tier 3.
5. **Re-run the route check** (Acts 0–II scripts §9) after 2–3.

### 4.3 Voice consistency of returning people (to do)

- **Spot-checked consistent:** Frank (rule-bound, "uitleggen"), Kees (craftsman), Mieke (craftsman, "klopt"), Sandra (quiet), Marco (cynic), Ruben (craftsman).
- **Thomas:** an expert in talk_to and a defender in `thomas_flex`. That is allowed (the archetype is per talk), but note it in the voice sheet.
- **Done 2026-10-16:** a full read of each returning person's lines across tiers, now written down as the voice sheet in §6. Fixes made while reading: Marco's commitments no longer all start alike ("Klaar." / "Kijk."); Noor's two talks (field app, status page) had identical outcome lines and now differ; Mieke's tier-4 lines now carry her "dat moet kloppen"; Petra's tier-2 commitment uses her "Klopt."; Frank's tier-4 lines keep his formal register ("paraaf", "directie"). Thomas stays an expert in `talk_to` and a defender in `thomas_flex`; his interest `via` is the relational one in both persuasions.

### 4.4 The route check, by simulator

**What was measured.** A Python model of the engine's rules (dialog spec §3.3 and §4.1 with R-D1's lead-in turn and ceiling; the archetype multipliers of §3.6) plays every persuasion talk in the four tiers. Moves are the fifteen chips; proposals are abstracted (the player picks the best proposal on offer, `P`, or experiment, `X`); bank replies carry no tags (see the tier-1 content audit, C8). Two questions: is every talk winnable, and does one *fixed* sequence of moves win many talks? The second is what makes play rote. The model and its scripts are kept with the design agent; the builder should re-run the same tests on `rules/dialog.gd` (§7, T6).

**Result 1: with the spec's numbers, one listening sequence wins every talk.** Before and after this audit's content fixes:

| Tier | Persuasion talks | Best fixed route, before | After the content fixes (§4.2) |
|---|---|---|---|
| Acts 0–II | 20 | 20 (100 %) | 20 (100 %) |
| 2 | 17 | 17 (100 %) | 17 (100 %) |
| 3 | 22 | 22 (100 %) | 22 (100 %) |
| 4 | 11 | 11 (100 %) | 11 (100 %) |

A typical winner: *Samenvatten · Open vraag · Begrip tonen · Open vraag · Doorvragen · Samenvatten · Doorvragen · Begrip tonen · Voorstel · Afspraak*. It wins because, in the spec's table, three moves land almost always: `open_question` (+6 always), `empathy` (+6 always, and it is in nearly every concern's `via`), and `inquiry` (+8 whenever openness is within 10 of the next threshold, which a rising talk always reaches). The content changes of §4.2 make talks *read* differently (voices, cues, archetypes) but cannot break a route that never misses. **The cause is in the engine's numbers, not in the content.** (The built engine lets `inquiry` land within 15 of the next threshold, not 10: PLAN §10, dialog-engine calls. That only widens the route.)

**Result 2: five engine changes (proposed, estimates) cut the universal route to about half in tiers 1–2.** Measured in the model:

| # | Change (dialog spec §3.3) | Why it is true to people |
|---|---|---|
| E1 | `empathy` lands (+8, +10 after an admission) only after a line tagged `feeling` or `admission`, or in the first two moves; otherwise +2 | Sympathy for nothing in particular sounds hollow. |
| E2 | `inquiry` lands only when the last authored line is a claim (or a hesitation); otherwise +2 | You can only dig into something the person said. |
| E3 | A misread at the lead-in costs more: `silence` after a feeling −6 ("…"), `reflect` after a hesitation −5 ("Nee, dat is het niet.") | Missing what someone just showed you is felt. |
| E4 | The same move *type* used a second time in a talk lands ×0.7, a third time ×0.4 (not only when consecutive) | People notice a technique. |
| E5 | Patience by archetype: overloaded 7, rule_bound 8, cynic 9, quiet 9, others 10 (the spec's −3 for the overloaded, made general) | Busy and sceptical people give less time. |

Plus the content rule already applied in §4.2: concern `via` by cue (a hesitation opens to `silence` and `inquiry`, a feeling to `reflect` and `empathy`), and in tiers 3–4 the layer thresholds by archetype (interest 45–58, concern 66–76; applied to 30 talks, each with a dated comment).

| Tier | Best fixed route, with E1–E5 | Talks the model could not win with E1–E5 |
|---|---|---|
| Acts 0–II | 10 of 20 (50 %) | none (`linda_replanning` has fewer than 3 routes) |
| 2 | 9 of 17 (53 %) | `linda_klic` (overloaded, patience 7: too tight) |
| 3 | 15 of 22 (68 %) | none at E5's cynic patience 9 (at 8, `marco_crew` failed); the best fixed route still wins 15 |
| 4 | 9 of 11 (82 %) | none |

**Reading it.**
- The universal-route counts are *upper* estimates for real play: the model picks the best proposal for the player, and in the game choosing the proposal that answers *this* person's concern is itself part of the route.
- Tiers 3 and 4 stay above half because their talks are alike in shape: nearly every concern sits at 70–72, nearly every talk has patience 10 and a data clue. The threshold spread helped (tier 3 from 77 % to 68 %, measured before and after), but the tiers also need variety in *structure*: more talks where the interest comes only from data (`show_data` in `via` for rule-bound people), talks with a block, check-ins instead of persuasions, and the group talk (drie-winters §5), which no single-person route can win.
- **Every talk stays winnable under the current numbers.** E1–E5 must be tuned so that the two talks above become winnable again (a tight patience is the usual cause).

**What follows (PLAN 1.6c):** the builder adds E1–E5 to `rules/dialog.gd` behind constants (all estimates), the design agent re-measures with the model and the real engine, and tiers 3–4 get the structural variety above when they enter content. Target for test T6: no fixed route wins more than half of a tier's persuasion talks.


## 5. The three principles' payoffs (done 2026-10-16)

Method as planned: every mission's `principles` against its temptation's later cost; a reward per principle per tier; the balance of principles per tier. A script read every mission block in the tier-2, tier-3 and tier-4 drafts and the arc doc (73 missions with `principles`, 43 temptations).

### 5.1 Long term over short term: every temptation has a later cost

All 43 temptations set a flag or an effect whose cost some rule reads later: an aftermath, a lost support step (sustain), a locked strategic option, a trust loss, an audit finding, a weekly cost, or a blocked discovery. The weakest twelve (each flag named only where it is set and once in its path note) were checked by hand; eleven had a real cost already, one did not (`flag:status_faq`, fixed, §1.3). The rare true exception, containment for safety (`fix_lmra_tickbox`, `fix_digging_damage`), is the only place where pressure carries no buy-in penalty (dialog spec §4.2).

### 5.2 A gap in the score: a quick win that completes a goal pays in full

Four temptations complete their mission's goal at once (`bought_vsm`, `dashboard_not_board`, `mandates_skipped`, `t3_consultants`). Their later costs are real, but the mission's XP and budget are paid in full on the day, so the score itself says the shortcut was as good as the patient route. That breaks principle 1 ("a quick win that costs the future scores lower").

**Proposed rule (A9, for the builder):** a goal completed by a temptation (`accept_effects.complete_goal`) pays **half** the mission's XP and budget and no reputation from the mission, the same rule as compliance in a `talk_to` goal (dialog spec §5.1). The debrief names it ("Het is gedaan. Door wie?"). Recorded in §8 as a decided question.

### 5.3 Balance of principles per tier

| Tier · track | Missions with `principles` | long_term | respect | improve |
|---|---|---|---|---|
| 1 (content) | 0 of 34 | — | — | — |
| 2 · grid | 20 | 15 | 9 | 9 |
| 3 · grid | 18 | 12 | 12 | 10 |
| 3 · IT | 10 | 5 | 7 | 6 |
| 4 · grid | 16 | 11 | 8 | 10 |
| 4 · IT | 6 | 5 | 5 | 2 |

- **Tier 1 has no `principles` in content (A10).** Proposed assignment for the builder (main missions; sides by the same logic):

  | Mission | Principles |
  |---|---|
  | `fix_custom_design` | respect (Anouk's overtime), improve |
  | `fix_incomplete_application` (B) / `fix_installer_not_ready` (N) | improve (the bottleneck) / respect (Marco's wasted trips) |
  | `fix_status_callers` | respect (Esra's agents), long_term (the honest date) |
  | `fix_done_but_not_closed` | long_term (Petra as a single point of failure) |
  | `save_henks_knowledge` | respect, long_term |
  | `winter_el_amrani` | respect, long_term |
  | `fix_revision_backlog`, `fix_digging_damage` | long_term (the map), respect (Gert is a partner) |
  | `fix_grid_study_queue`, `fix_transformer_wait`, `fix_unused_capacity` | improve, long_term |
  | `fix_silo_kpis`, `first_kpi_review` | long_term (lagging and leading), respect (Frank, Joost, Sanne) |
- **Tier 2 is light on respect** (9 of 20) although its dialogs carry it: the coaching and the people talks are where respect is tested. No change to the missions; the tier's dialog count makes up for it.
- **Tier-4 IT is light on improve** (2 of 6). `it_dora_metrics` tests improvement in its very goal; add `improve` to its `principles` (one line, builder).

### 5.4 Respect for people pays in the numbers

Respect is rewarded through mechanics that already exist, and the check found no tier without one: commitment ×1.25 against compliance ×0.6 on a fix's life; morale and the rare departure; check-ins; trust gates on coaching; D29–D34 and their successors in every tier. The arc adds its biggest payoff: the successor in the finale is someone you developed (drie-winters §8.3).

### 5.5 Always improve pays

Drift, the stagnation alarm, recurring routines, the borgingsdividend and the re-audit cover it in every tier. The arc adds a year in which the player must run their own Kata (the monthly call) and coach others.

---

## 6. Voice sheet per recurring person

One sheet for everyone who speaks in more than one act. It complements the per-tier sheets (Acts 0–II §2, tier-2 dialogs §2, tier-3 draft §5, tier-4 draft §5.3) and wins where they differ. Everyone speaks standard Dutch. **Openers** are the outcome openers this person may use, so that a builder writing a new line does not fall back on the narrator's "Afgesproken."; the content test (§7, T1) counts them per tier.

| Person | Word choice | Rhythm | Humour | Worry, by act | Openers (commitment · partial · heard · compliance · ruined) | Never says |
|---|---|---|---|---|---|---|
| **Ruud Hoekstra** (directeur, coach) | questions; "kijk", "wat zie je", "wat verwacht je"; no jargon unless the player used it first | short; one question per line; silences | the coffee from the machine; self-mocking about his age | III: leaving at the wrong moment (2012) · IV: from Den Haag, the national averages · V: not seeing whether it lasts | (farewell and choice only) "Weet je wat ik ga doen?" · "Goed." · "Dank je." | the right move; "goed gedaan" without a question after it |
| **Frank Hulshof** (manager, interim directeur) | "jaarplan", "verantwoorden", "de directie", "uitleggen", "paraaf" | formal, complete sentences; lists | rare and dry: "Ik word betaald om nee te zeggen." | II: the budget round · III: the red number · IV: being the interim who let it slip · V: six projects that shield one | "Goed." / "Drie eraf." · "Als … , doe ik mee." · "Interessant." / "Hm." · "Laat het staan." · "Ik stel voor dat we dit punt verdagen." | anything personal before "Denkt mee" |
| **Joost van Dijk** (TL Werkvoorbereiding) | "even voor de duidelijkheid", "eerlijk is eerlijk", "dat is gewoon een feit", numbers | tidy, complete; numbers when nervous | his Excel tabs | I: vacancies and face · II: the predecessor at Inkoop · IV: the WIP limit looks like idleness | "Afgesproken." / "Even voor de duidelijkheid:" · "Eerlijk is eerlijk:" · "Fijn dat je het vroeg." · "Prima." · "Dus …" | blaming Anouk; swearing |
| **Sanne Bakker** (TL Intake) | "joh", "hè", "nou", "het postkantoor" | fast; lists in threes; stops joking when tired | sarcasm about Intake's status | I: blame for others' errors · II: the dip · III: being coached · V: not having studied | "Afgesproken." · "Ik doe mee." · "Zo. Dat had ik nog nooit hardop gezegd." · "Prima. Weer een getal." · "Zie je wel." | anything bad about her team |
| **Marco Peters** (TL Monteurs) | "mijn mannen", "kijk", "klaar"; office words only with a sneer | short and flat | gallows humour about consultants | I: 2012 · III: the contractor and his hours · IV: who gets sent away | "Klaar." / "Kijk." · "Ik doe mee." · "Hm." · "Ik praat met hem. Het verandert toch niks." · "Zie je." + "Wie bouwt dat na?" | "stakeholder", "KPI" without a sneer |
| **Anouk de Vries** (werkvoorbereider) | "sorry", "nee joh", "ik zit erbovenop" | apologises first; precise about drawings | the mountain with a flag | 0: being watched · I: overtime · V: everyone looking | "Kom maar." / "Goed." · "Ik doe het." · "Dank je." · "Als jij het zegt." · — | that she is overloaded |
| **Henk Verbeek** (senior monteur) | "jongen", "ik laat het je wel zien", years in his stories | slow, warm, gruff | anecdotes from '87 | I: a video nobody watches; Ahmed alone at night | "Ik laat het je wel zien." · — · — · — · — | self-pity |
| **Ahmed Bouzid** (monteur, later trainer) | "gewoon", "toch", "man", "echt wel"; says "Henk" | short sentences; long only when very open | his sat-nav knows Nova-Oud better | I: not good enough · IV: being looked at like Henk · V: the office | "Doe ik." · "Ik probeer het." · "Ik moet het Henk vragen." · "Oké." · "Zie je." | long speeches early |
| **Esra Yilmaz** (TL KCC) | "kijk", "serieus?", "gewoon eerlijk", "mijn mensen" | direct | imitates the hold music | I: her agents' stress · III: the storm calls · IV: a date that holds | "Deal." · — · — · — · — | that her agents are slow |
| **Petra Vos** (Meetdata) | "klopt", "dat staat in mijn map", "de Molen" | precise, dry | the Molen grinds slowly | I: alone · III: her sick week; personal data | "Klopt." · "Ik wil het wel." · — · "Prima." · "Dan vraag je het maar aan de Molen." | that she is behind |
| **Femke de Wit** (netplanner) | "kijk", "kort gezegd", "dat past" | enthusiastic; draws while talking | grid jokes | II: signing without authority · III: the red map · V: the grid of 2035 | "Dat past." / "Afgesproken." · "Ik wil het wel." · "Fijn dat je vroeg …" · "Ik werk hem bij." · "Dan zet ik hem op rood." | that the procedure is stupid |
| **Thomas Visser** (accountmanager) | "mijn klanten", names and lunches | smooth, relational | the business-park lunch | II: taking capacity from people he knows · IV–V: selling a restriction | "Afgesproken." / "Dat doen we." · "Ik doe mee." · "Die verjaardag." · "Goed." · "Flex is het nieuwe woord voor nee." | a customer's name in a joke |
| **Kees Mulder** (operator) | "videowand", "schakelen", "melding" | calm night voice, few words | the wall is the only light at night | III: only seeing the light come back · IV: the storm without Ruud · V: the alarm he clicks away | "Afgesproken." · "Die drempel bepaal ik." · "Je vroeg naar 2021." · "Zet het maar aan." · "Zie je." | panic |
| **Mieke van der Veen** (Revisie & GIS) | "dat moet kloppen", "uitzoeken" | careful | the sandwich bag with a peanut-butter stain | II: obsolete · V: the app takes her trade | "Dat moet kloppen, dus …" · "Als mijn team de controle houdt." · "Fijn." · "Prima." · "Mijn team kan weg." | that the monteurs are sloppy |
| **Linda Jansen** (planner) | "omplannen", apologies while talking, "het kaartenhuis" | fast, tired | the house of cards | I: evenings · III: the KLIC duty | "Afgesproken." / "Goed." · "Ik doe mee." · "Dank je." · "Prima." · "Dus Planning …" | that monteurs are unreliable |
| **Dirk Smits** (magazijn) | "ik heb ze gewoon liggen" | the fewest words | a van is a warehouse on wheels | I: blame for the warehouse · III: the sheet | "Doen we." / "Doe ik." · "Dan doe ik mee." · "Hm." · "Jullie sheet." · "Zoek het verder zelf maar uit." | hurry |
| **Gert Peeters** (aannemer) | "mijn jongens", "volgens de kaart" | plain, defensive at first | thirty years of digging | II: his crew, his name · III: the contract | "Afgesproken." · "Ik doe mee." · "Je vroeg naar mijn jongens." · "Als het moet voor het contract." · "Neem een andere aannemer." | blame toward his crew |
| **Ruben Smulders** (consignatiemonteur) | "even", "toch?", "snap je" | half sentences | sleeping in blocks of three hours | III: blamed for "onbekend"; driving tired | "Doe ik." / "Afgesproken." · "… ben ik erbij." · "Je vroeg naar die sloot." · "Ik ben oproepbaar." · "Dus ik moet gewoon harder." | that he can't handle it |
| **Wendy de Bruijn** (senior operator) | "onderbuik", "zo doen we dat" | stories | 28 years of shifts | III: forms turn operators into box-tickers · IV: Ruben at three a.m. | "Zo doen we dat dan." · "Ik doe mee." · "Achtentwintig jaar, en …" · "Prima." · "Een formulier. Zie je wel." | — |
| **Ingrid Bos** (assetmanager) | "kans maal gevolg", "eerlijk antwoord" | calm; weighs | the calendar that never failed, until it did | IV: 2012's dashboard (the quiet one) · V: the audit | (expert; in a group talk she has one layer and no openers) | — |
| **Monique de Ruiter** (Financiën) | "doelmatig", "maatstaf", "euro voor euro" | numbers | "Begin maar bij de duurste." | IV: what the programme costs · V: another plan that misses | "Ik teken." · "Als we het nakijken, teken ik." · "De vorige keer." · "Het staat op uw naam." · "Ik wil cijfers." | enthusiasm without numbers |
| **Noor Hendriks** (PO) | Jira words: "backlog", "done", "in progress", "ticket" | office Dutch | — | IV: never rode along · V: never spoke to a customer | "Dan zet ik dit op 'done'." / "Donderdag …" · "Ja, als …" / "Graag, maar …" · "Ik ga dit opschrijven." · "Prima." / "Ik maak er een ticket van." · "Zet het maar in de backlog." | "gebruiker" when she means a monteur, after Act IV |
| **Mark van Leeuwen** (developer) | honest, short; headphones | quiet | — | IV: pairing all day · V: nights cleaning up | "Oké." · "Ik probeer het." / "Alleen als …" · "Hoe ik werk." / "De avonden." · "Ik pair." / "Ik doe mijn best." · "Socialer worden." / "Sneller." | — |
| **Mevrouw El Amrani** (klant) | "ik heb het opgeschreven", dates from her notebook | polite, organised | the hold music | I: her mother in the cold · IV: her daughter's bakery | "Goed." · "Ik schrijf het op." · "Dank u dat u luisterde." · "Ik heb geen keus, hè." · "Dan bel ik de Geschillencommissie." | swear words; threats she won't carry out |
| **Lotte Smit** (new, finale) | project words she unlearns: "planning", "stuurgroep" | notes while talking | the four-centimetre folder | V: being the new one from outside | "Goed." · "Ik ga kijken." · "Dank je." · "Prima." · "Oké." | — |

---

## 7. Content-test rules that keep the limits (for the builder)

PLAN §4.3.1 asks for hard limits enforced by a content test. Proposed as Python checks in `tools/build_content.py --check` (structure) and Godot content tests (routes), run on `content/dialogs.yaml` per tier:

| # | Rule | How it is measured | Fails when |
|---|---|---|---|
| T1 | **Opener limit** | per tier and per outcome kind, the outcome line up to its first `.`, `,`, `!`, `?` or `:` | one opener appears in more than ⌊n/3⌋ of the tier's dialogs that have that outcome |
| T2 | **Narrator words** | "Afgesproken", "Zie je", "Je vroeg", "U vroeg", "Prima" as openers, across all outcome kinds of a tier | any one of them opens more than a third of the tier's dialogs |
| T3 | **Feeling cues** | the concern's `lead_in.tags` | fewer than ⌈n/3⌉ of a tier's concerns are tagged `feeling` without `hesitation` |
| T4 | **Feeling cue keys** | a feeling-cued concern's `via` | `via` holds `silence`, or lacks `reflect` |
| T5 | **Interest by archetype** | the interest `via` against the archetype table (§4.2) | a mismatch without a `via_reason:` comment field explaining why |
| T6 | **No universal route** | the route simulator (§4.4): every winning sequence of every persuasion dialog in a tier, tried on every other | one fixed sequence of moves wins more than half of a tier's persuasion talks |
| T7 | **No golden path** (spec §9.3, kept) | breadth-first search | fewer than 3 winning sequences that differ in at least two positions |
| T8 | **Voice openers** | each person's outcome openers against their row in §6 | a person uses an opener that is another person's signature (e.g. Petra's "Klopt.", Marco's "Wie bouwt dat na?") |
| T9 | **Date sanity** | dates and month names in lines, against the earliest day the dialog can open (from its mission's `requires`, `opens_on` and the act estimates) | a line names a date before the story it belongs to could have happened (the El Amrani case) |
| T10 | **Group talks** (drie-winters §5.1) | the simulator with targets | `partial` unreachable without the quiet one, or `commitment` reachable without them |
| T11 | **Pushing costs; pressure works** (spec §9.3, kept) | scripted sequences | as in the spec |

The simulator used for §4.4 is a Python model of the spec's rules (§3.3, §4.1, R-D1). The builder should run the same tests against `rules/dialog.gd` itself (a headless Godot test), so the test judges the engine the game uses, not a copy.

---

## 8. Decisions (by the standing rule, 2026-10-16)

Each takes its recommended option, **bold**, logged in PLAN §10.

1. **A goal completed by a temptation.** **(a) Pays half its XP and budget and no mission reputation, like compliance.** (b) Full pay; the later cost is enough. *(a) makes the score itself follow principle 1.*
2. **The cue for a feeling.** **(a) The cue shows on any lead-in; a feeling answers to reflect and empathy, a hesitation to silence.** (b) Keep the cue for hesitations only and let feelings show only in the portrait. *(a) keeps the scaffold the decided Q9 promised for tiers 1–2, and makes the player read which kind of "more" it is.*
3. **Interest by archetype.** **(a) A fixed table per archetype, with a documented waiver.** (b) Free per dialog, checked only by the universal-route test. *(a) teaches that people differ, in a way a player can learn.*
4. **Engine changes E1–E5 (§4.4).** **(a) Adopt them as constants in `rules/dialog.gd`, re-measured with the simulator and the real engine.** (b) Keep the spec's numbers and rely on content variety alone. *(a) is the only change the model shows to break the universal route; content alone left it at 100 %.*
5. **The route test's threshold.** **(a) No single sequence wins more than half of a tier's persuasion talks.** (b) None wins more than a third. *(a) is strict enough to stop rote play and loose enough that listening still works broadly, which is the lesson.*
