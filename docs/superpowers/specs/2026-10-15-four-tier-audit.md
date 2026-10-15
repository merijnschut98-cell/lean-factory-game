# Four-tier audit: missions, facts and dialogs (tiers 1–4 and the IT track)

> Status: by the mission and dialog design agent (Claude, 2026-10-15). **Docs only. Partly done:** the session ended mid-audit. Every section marked **To do** is still open and is tracked in PLAN.md.
>
> Scope: `content/missions.yaml` (tier 1), the tier-2 draft, the tier-2 dialogs, the tier-3 and tier-4 drafts, the Acts 0–II scripts, the catalogue and the engagement loop.
>
> Method: scripts over every YAML block in these docs (88 dialogs, 97 missions, 57 problems, 178 countermeasures), plus reading by hand.

## 0. Summary

| # | Finding | Severity | Status |
|---|---|---|---|
| A1 | **Requirement cycle in the IT chain.** `fix_release_twice_a_year` required `fix_status_page_wrong`, which moved to tier 4 and (via `fix_team_dependencies` → `fix_pi_overcommit` → … → the release fork) required the release again. Nine IT mains were unreachable. | Critical | **Fixed** (tier-3 draft: now requires `fix_field_app_bypassed`). The reachability check now reaches every main. |
| A2 | **Fact names read but never set** (§1). | High | To do: fixes listed. |
| A3 | **Tier-2 draft promises to Act V that the tier-4 draft missed** (§1.2). | High | To do: fixes listed. |
| A4 | **Temptations with no later payoff** (§1.3). | Medium | To do. |
| A5 | **Side offers pile up**: up to 7 open at once when `t2_daily_boards` completes; 15–21 for a player who skips sides (§2). | Medium | To do: stagger proposals listed. |
| A6 | **Dialogs are formulaic across tiers** (§4). | High: a player would quit on rote talks | To do: fixes listed. |
| A7 | **Mission shapes**: no consecutive repeat found in the main chains (§3). | — | Checked. |
| A8 | Tier-4 questions marked decided (standing rule). | — | **Done.** |

## 1. The facts chain, end to end

### 1.1 Read but never set (script)

| Fact | Read in | Fix (owner) |
|---|---|---|
| `flag:curtailment_letter` | tier-3 `aziz_coldchain` | The tier-2 draft sets `flag:solar_curtail_letter`; rename the reader in tier 3 (mine). **To do.** |
| `flag:late_clock` | tier-2 dialogs `acm_inspector` | The tier-2 draft sets `flag:acm_clock_gamed`; rename the reader (mine). **To do.** |
| `flag:lindeveld_overtime` | tier-3 §0.1 schema example | Should be `flag:lindeveld_allowance` (mine). **To do.** |
| `flag:rest_rule` | tier-2 dialogs §6 | It is a consequence of `committed:ruben_storm`; set it via `unlocks`/`sets_flags_on_commitment` or read the commitment directly (mine). **To do.** |
| `flag:henk_postcards` | Acts 0–II scripts | It is set by `sets_flags_on_lifted`, a field the script did not scan. **No fix needed.** |
| `committed:ruud_backs_obeya` | dialog spec §7.4 | Already flagged as an audit change in the Acts 0–II scripts (Ruud is not a dialog target). The spec owner should apply it. |
| `flag:okr_region` | tier-2 draft | It is never set in YAML (the tier-2 draft's owner); `lsw_catchball` should read it (§1.2). |

### 1.2 Tier-2 promises to Act V not honoured in the tier-4 draft (to do, mine)

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

### 1.3 Set but not paid off (to do)

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
- **Proposals (to do):**
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

### 4.2 Fixes (to do, mine)

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

- **Spot-checked consistent:** Frank (rule-bound, "uitleggen"), Kees (craftsman), Mieke (craftsman, "klopt"), Yvonne (quiet), Marco (cynic), Ruben (craftsman).
- **Thomas:** an expert in talk_to and a defender in `thomas_flex`. That is allowed (the archetype is per talk), but note it in the voice sheet.
- **To do:** a full read of each returning person's lines across tiers.

## 5. The three principles' payoffs

**To do.** Planned method:
- for every mission's `principles`, check that the temptation's later cost is read somewhere (§1.3 is the first part);
- check that each tier has a reward per principle (engagement loop §4.3: tiers 1–4 now covered, D1–D50);
- count missions per principle per tier for balance.
