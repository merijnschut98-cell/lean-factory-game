# Tier-2 draft: checked in the simulation

> QA, 2026-10-15. The draft `docs/superpowers/specs/2026-10-15-tier2-missions-draft.md` (after the source fixes of 31b8f91: trench 50 cm, TDTR up to 65 %, the KNMI criteria): 11 problems and 36 countermeasures, run on the real network. Nothing in the draft or `content/` was changed; every fix below is a proposal for the mission builder.

## Method

- **Harness:** `game/tools/draft_check.gd` (kept: clean and reusable for any later draft).
  `godot --headless --path game --script res://tools/draft_check.gd -- <draft.json> [out.json]`
  The draft's YAML blocks were extracted to JSON in a scratch copy (problems, countermeasures, `aftermath`), and the KPI-menu expansions applied as the catalogue does.
- **Network:** `res://data/value_streams.json` (as `Network.load_file`), seeds 11–15, common random numbers, warm-up `GameSession.WARMUP_DAYS` (182 days), maturity 2 (the Act III gate).
- **At the Check:** the steady state while the experiment runs (`Pdca.treated_effects`: the problem at 1 − eff, the countermeasure at eff), over 84 days, against the problem left open. The gain is shown two ways: the problem's **named KPI** (paired per seed), and `KpiBoard.improvement` on the problem's stream (the quarterly-review measure). `not_constraint` is `Region.check`'s rule.
- **Over a year:** 365 days from the A3: the Check, then wear as `Sustain` models it with nothing else done, a recurrence found again within 7 days (estimate) and redone with the same countermeasure; the draft's `aftermath` runs from each adoption. "Loose" = not standardised, "std" = standardised at the Act. Gain against the problem left open all year; euros = budgets + standardising + aftermath cost + the problem's `cost_per_week` at its strength.
- **Harm:** the measures of `game/tests/test_catalog.gd` (seed 11, 150 days): flow harm > 1.03, and for `first_time_right` / `on_time` problems a named-KPI drop of more than 5 points.
- **Scenarios:** the fork (both problems open, then one branch resolved, 112-day window), the ACM visit (70 days from its start, last 56 measured), the OKR quarter (91 days), the worst legal mix on `connections.execution`.
- Numbers are mean ± sd over the 5 seeds. "pt" = percentage points, "d" = days, "h" = hours.

Two limits of the model matter for reading the tables:
1. **The 10-minute tick.** `SimCalendar.TICK` is 10 minutes, so effects smaller than that on outage steps (e.g. `standby_by_fault_map`'s own `touch_time 0.95` on a 1 h step) do not show.
2. **After the Act the problem is cleared whatever the fit** (`Region.act`). A fit-0.6 fix and a fit-1.0 fix then differ only by decay, their own effects and the `aftermath`. The draft's long-term penalties (`trust`, `poor_fix` repair quests, `needs`) are not simulated yet, so the year comparisons below show only what the simulation itself makes of a temptation.

## Summary

| Area | Claims | PASS | FAIL |
|---|---|---|---|
| 1. The fork (≥ 3× gain, `not_constraint`) | 3 | 3 | 0 |
| 2. Targets reachable (ACM, OKR) | 9 | 1 | 8 |
| 3a. Every countermeasure passes the Check at maturity 2 | 36 | 35 | 1 |
| 3b. Each countermeasure is a real improvement at the Check | 36 | 33 | 3 |
| 3c. Some better than others (best fit gains most) | 11 | 4 | 7 |
| 3d. Temptation scores lower over a year than the patient fix | 9 | 5 | 4 |
| 4. Harm within the tests (> 1.03; named KPI > 5 pt; no team ≥ 100 %) | 28 | 23 | 5 |
| Draft's own simulation claims | 5 | 3 | 2 |
| **Total** | **137** | **107** | **30** |

**Worst failures**
1. **`safety_stock_calendar` does nothing in the simulation** (harm ×0, on-time unchanged). Its three countermeasures gain 0. Even a reorder point of 35 moves meters on-time by only −2 pt, and a material step has no wait statistic in the harm test. The story's arithmetic is off as well: over a 10-*calendar*-day lead time, demand per calendar day × 10 = 57 is right on average; the error only bites when the lead time is in *working* days.
2. **The ACM milestone cannot fail and can fail by luck:** connections on-time over 56 days is 0.885 with every Act III problem left open (4 of 5 seeds ≥ 0.85) and 0.837 in the *healthy* base on seed 11. Connections' on-time is set by the 120-day reinforcement wait, not by the Act III problems.
3. **The OKR menu: five of six key results are wrong.** On-time 0.92, WIP age 45 d and meters FTR 0.85 are out of reach; throughput 33 a week is above demand (30); the reinforcement KR is met before you start. With three picks the 0.7 average is out of reach.
4. **Four problems fail the named-KPI test** (`contractor_rework`, `lmra_tickbox`, `heatwave_overload`, `safety_stock_calendar`). Their countermeasures' gains are then lost in the noise, so the order by fit does not show.
5. **`repeat_fault_analysis` (tier 3) fails the Check at maturity 2** (eff 0.45).

## 1. The fork: `on_call_far` (bottleneck) vs `shift_handover` (non-bottleneck)

Outages stream, window 112 days. Both open, then one branch resolved with its best fit (the others branch-for-branch in the second table).

| State | p85 lead (h) | p50 lead (h) | On time | Throughput / wk | Customer-hours / wk |
|---|---|---|---|---|---|
| Neither open (healthy) | 3.60 ± 0.37 | 2.83 | 0.925 ± 0.030 | 17.25 | — |
| Both open | 4.63 ± 0.55 | 3.50 | 0.816 ± 0.042 | 17.25 | — |
| B fixed (`standby_by_fault_map`) | 3.77 ± 0.37 | 3.00 | 0.894 ± 0.038 | 17.25 | −10.2 vs both open |
| N fixed (`handover_standard_at_board`) | 4.40 ± 0.51 | 3.33 | 0.823 ± 0.043 | 17.25 | −2.9 vs both open |

| Claim | Bottleneck gain | Non-bottleneck gain | Ratio | Verdict |
|---|---|---|---|---|
| p85 lead-time gain ≥ 3× (draft C15) | −0.86 h (per seed 0.50–1.17) | −0.23 h (0.17–0.33) | **3.7×** | PASS |
| On-time gain (the KPI both missions name) | +7.8 pt (6.4–9.7) | +0.7 pt (0.0–1.1) | **11.8×** | PASS |
| `not_constraint` on N's Check, not on B's | `on_call_far`: false for all four fixes (capacity 87.5 → 94.5–101.3 / wk) | `shift_handover`: true for both (capacity 100.6 → 100.6) | — | PASS |

Notes:
- The p50 ratio is exactly 3.0× (0.021 d vs 0.007 d, quantised by the tick); throughput does not move in either branch (outages are demand-bound). Lead time p85 and on-time carry the lesson.
- `smaller_on_call_areas` and `extra_on_call_shifts` (on-call headcount +1) resolve to p85 3.50 h / on-time 0.910, slightly *better* than `standby_by_fault_map` (3.77 h / 0.894): the latter's own effect is below the tick. See the fixes.
- On-call load is only 10–12 % with the problem open. The draft says "travel queues outages"; in the simulation the harm is the travel time itself, not a queue. The fork still holds.

## 2. Targets

### ACM visit (`acm_visit`, `acm_improvement_plan`): connections on time ≥ 0.85 over 56 days

70 days from the visit's start. "Left open" = the worst legal mix then: `contractor_rework` resolved (it gates the visit), `escalation_hallway` (main) + `monteur_hours`, `lmra_tickbox`, `stale_capacity_map` (sides) open.

| Scenario | On time (per seed 11–15) | Mean | Seeds ≥ 0.85 | p50 lead (d) per seed |
|---|---|---|---|---|
| Healthy base | 0.837 / 0.883 / 0.897 / 0.925 / 0.868 | 0.882 | 4/5 | 47.8 / 47.9 / 53.9 / 51.2 / 50.8 |
| Act III left open | 0.838 / 0.880 / 0.921 / 0.906 / 0.880 | 0.885 | 4/5 | 51.7 / 58.9 / 58.9 / 60.2 / 55.9 |
| Only the main fixed | 0.844 / 0.878 / 0.909 / 0.898 / 0.880 | 0.882 | 4/5 | 46.8 / 56.9 / 57.1 / 60.7 / 55.1 |
| Expert (all four fixed with the best fit, day 0) | 0.850 / 0.896 / 0.906 / 0.915 / 0.887 | 0.891 | 5/5 | 45.1 / 52.1 / 56.1 / 57.8 / 52.0 |

| Claim | Verdict |
|---|---|
| Reachable on the expert path | PASS (5/5, seed 11 at exactly 0.850) |
| Missed with the Act III problems left open (draft: "K5 must show it is … missed with the Act III problems left open") | **FAIL**: 4/5 seeds pass with everything open |

The p50 lead time does separate the paths: the expert is faster than "left open" on every seed (−6.5, −6.8, −2.8, −2.4, −3.9 d). An absolute threshold does not separate them cleanly (seed spread ± 4 d); a relative one does.

### OKR `t2_first_okr` (91-day quarter)

"Expert" = every Act III problem resolved with its best fit; "healthy" = no problems.

| Key result | Target | Healthy | Expert | Verdict |
|---|---|---|---|---|
| `kr_conn_on_time` | ≥ 0.92 | 0.888 ± 0.028 | 0.888 ± 0.017 (0.869–0.912) | **FAIL**: unreachable; no tier-2 fix moves connections on-time |
| `kr_conn_wip_age` | ≤ 45 d | 101.8 ± 9.9 | 102.3 ± 7.3 | **FAIL**: open-work p85 age is set by the 120-day reinforcement wait |
| `kr_outage_on_time` | ≥ 0.92 | 0.927 ± 0.028 | 0.916 ± 0.041 (3/5 ≥ 0.92) | **FAIL** (marginal): the target sits at the expert's mean |
| `kr_meters_ftr` | ≥ 0.85 | 0.717 ± 0.017 | 0.723 ± 0.021 | **FAIL**: base visit 0.80 × registration 0.90; no tier-2 fix touches meters FTR |
| `kr_conn_throughput` (the temptation) | ≥ 33 / wk | 29.6 ± 1.7 | 29.7 ± 1.6 | **FAIL**: demand is 30 / wk; it cannot be "easy" |
| `kr_reinforcement_wip` | ≤ 120 d | 101.8 | 102.3 | **FAIL**: met before the quarter starts; it measures all open connections, not reinforcement |
| `pass_average ≥ 0.7` with any 3 picks | — | — | — | **FAIL** (follows) |

The leading measure that does move: connections FTR 0.421 (healthy) → 0.462 ± 0.029 (expert), p50 lead 49.4 → 48.5 ± 1.0 d.

## 3. Countermeasures per problem

Columns: fit, tier, effectiveness at maturity 2, the Check, the named-KPI gain at the Check (paired, positive = better), `KpiBoard.improvement` at the Check, the named-KPI gain over the year (loose / standardised), the year's KpiBoard gain, euros a year and adoptions (redone after recurrence).

Note on `KpiBoard.improvement`: it counts higher throughput as better. For problems that *add* demand (`cause_unknown`, `stale_capacity_map`, `heatwave_overload`), fixing them lowers throughput, so the KpiBoard gain reads low or negative. The named KPI is the fairer judge there.

### cause_unknown (outages.repair, KPI on_time)

Harm ×1.214 (on-call load), on-time 0.916 → 0.862 (test seed). Open: on-time 86.99 ± 3.40 %. Constraint: monteurs (at constraint).

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ on time at Check (pt) | KpiBoard at Check (%) | Year Δ on time loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| cause_codes_pareto | 1.00 | 2 | 0.900 | PASS | +5.21 ± 1.78 | +2.41 ± 5.74 | +3.54 ± 1.12 / +4.19 ± 1.26 | +1.36 / −0.63 | 48,456 / 42,806 | 5 / 3 |
| repeat_fault_analysis | 0.90 | 3 | 0.450 | **FAIL** | +2.61 ± 2.02 | +3.52 ± 5.39 | 0 / 0 (never passes) | 0 / 0 | 113,429 / 113,429 | 1 / 1 |
| stop_and_record | 0.70 | 1 | 0.630 | PASS | +3.28 ± 3.90 | +3.27 ± 6.19 | +3.71 ± 0.92 / +3.93 ± 1.48 | +1.88 / +2.09 | 30,805 / 34,660 | 6 / 4 |
| mandatory_cause_field (temptation) | 0.60 | 1 | 0.540 | PASS | +2.88 ± 2.65 | +3.35 ± 5.78 | +1.91 ± 0.79 / +2.37 ± 0.76 | +1.10 / +1.24 | 28,276 / 25,010 | 4 / 2 |

Left open for the year: € 83,429.

| Claim | Verdict |
|---|---|
| Harm, named KPI, load | PASS |
| All pass the Check at m2 | **FAIL**: `repeat_fault_analysis` 0.45 |
| Best fit gains most at the Check | PASS (+5.2 vs +2.6 to +3.3) |
| Temptation lower over the year | PASS on the KPI (1.9 vs 3.5 pt loose; 2.4 vs 4.2 std); € favours the temptation (28k vs 48k): the Pareto is redone 5 times at €6,000 |

### on_call_far (outages.locate, KPI on_time)

Harm ×1.149, on-time 0.916 → 0.789 (test seed). Open: 82.94 ± 4.62 %. Constraint: monteurs (at constraint).

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ on time at Check (pt) | KpiBoard at Check (%) | Year Δ on time loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| standby_by_fault_map | 1.00 | 1 | 0.900 | PASS | +9.71 ± 3.39 | +5.35 ± 0.94 | +8.04 ± 0.42 / +8.82 ± 0.46 | +6.27 / +6.56 | 23,594 / 20,995 | 4 / 2 |
| smaller_on_call_areas | 0.80 | 2 | 0.720 | PASS | +3.69 ± 1.42 | +2.87 ± 0.31 | +8.09 ± 0.84 / +10.94 ± 0.85 | +6.20 / +7.08 | 24,932 / 20,865 | 1 / 1 |
| mutual_aid_agreement | 0.70 | 2 | 0.630 | PASS | +1.76 ± 0.97 | +2.43 ± 0.25 | +6.78 ± 0.56 / +9.23 ± 0.47 | +5.87 / +6.66 | 15,121 / 11,054 | 1 / 1 |
| extra_on_call_shifts (temptation) | 0.65 | 1 | 0.585 | PASS | +3.39 ± 1.63 | +2.80 ± 0.36 | +4.24 ± 1.12 / +6.38 ± 0.57 | +5.05 / +3.56 | 35,419 / 33,358 | 5 / 3 |

Left open for the year: € 54,750.

| Claim | Verdict |
|---|---|
| Harm, named KPI, load | PASS |
| All pass the Check | PASS |
| Best fit gains most at the Check | PASS (+9.7 vs +1.8 to +3.7) |
| Temptation lower over the year | PASS (4.2 vs 8.0 pt loose, 6.4 vs 8.8 std; €35k vs €24k) |
| (note) | Standardised, the structural fixes (`smaller_on_call_areas` +10.9, `mutual_aid_agreement` +9.2) beat the best fit (+8.8) over a year: decay 90 vs 365 days |

### shift_handover (outages.report, KPI lead_time)

Harm ×1.600 (control-room load, at 1.3 % → 2 %). Open: p50 3.00 h. Constraint: monteurs (not at constraint).

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ p50 lead at Check (h) | KpiBoard at Check (%) | Year Δ p50 loose / std (h) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| handover_standard_at_board | 1.00 | 1 | 0.900 | PASS | +0.17 ± 0.00 | +1.90 ± 0.43 | +0.16 / +0.17 | +1.63 / +1.72 | 5,000 / 12,000 | 5 / 3 |
| open_actions_list | 0.80 | 2 | 0.720 | PASS | +0.17 ± 0.00 | +1.90 ± 0.43 | +0.17 / +0.17 | +1.73 / +1.73 | 7,000 / 10,000 | 1 / 1 |

| Claim | Verdict |
|---|---|
| Harm, load | PASS |
| All pass the Check | PASS |
| Best fit gains most at the Check | **FAIL**: identical. The difference (problem at 0.10 vs 0.28 strength on a 15-minute step) is 3 minutes, below the 10-minute tick |

### contractor_rework (connections.execution, KPI first_time_right)

Harm ×1.120 (planners load). **Named KPI: FTR 0.415 → 0.397 (−1.8 pt; the test needs > 5).** Over 5 seeds the drop is 41.8 → 35.4 %, but the test runs one seed. Constraint: intake (not at constraint).

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ FTR at Check (pt) | KpiBoard at Check (%) | Year Δ FTR loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| shared_trench_standard | 1.00 | 2 | 0.900 | PASS | +6.39 ± 1.78 | +4.11 ± 1.87 | +7.07 ± 0.92 / +7.36 ± 0.92 | +4.85 / +4.85 | 24,282 / 20,425 | 4 / 2 |
| first_job_inspection | 0.80 | 1 | 0.720 | PASS | +6.44 ± 2.31 | +4.37 ± 2.04 | +5.68 ± 0.74 / +5.73 ± 1.31 | +3.83 / +4.02 | 19,817 / 24,671 | 6 / 4 |
| contractor_scorecard | 0.70 | 2 | 0.630 | PASS | +4.59 ± 3.00 | +3.25 ± 2.18 | +6.09 ± 1.24 / +6.41 ± 0.89 | +4.23 / +4.42 | 14,514 / 17,265 | 3 / 2 |
| switch_contractor (temptation) | 0.60 | 1 | 0.540 | PASS | +4.43 ± 2.83 | +3.62 ± 2.25 | +2.92 ± 0.73 / +4.39 ± 1.14 | +2.15 / +3.04 | 32,919 / 29,535 | 3 / 2 |

Left open for the year: € 39,107.

| Claim | Verdict |
|---|---|
| Harm > 1.03, load | PASS |
| Named-KPI test | **FAIL** |
| All pass the Check | PASS |
| Best fit gains most at the Check | **FAIL** (noise: +6.39 vs +6.44; the eff gap 0.90 vs 0.72 is worth ~1.3 pt here) |
| Temptation lower over the year | PASS (2.9 vs 7.1 pt loose; €33k vs €24k) |

### escalation_hallway (connections.design, KPI lead_time)

Harm ×1.164 (work-prep load, planned 0.967, actual 0.925). Open: p50 53.65 ± 2.93 d. Constraint: work_prep (at constraint).

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ p50 at Check (d) | KpiBoard at Check (%) | Year Δ p50 loose / std (d) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| tiered_escalation_24h | 1.00 | 2 | 0.900 | PASS | +4.17 ± 3.28 | +3.86 ± 1.81 | +4.44 ± 1.85 / +4.73 ± 1.91 | +3.78 / +3.74 | 15,000 / 18,000 | 5 / 3 |
| andon_standup (cheap) | 0.70 | 1 | 0.630 | PASS | +3.36 ± 1.98 | +2.53 ± 1.69 | +4.34 ± 1.59 / +4.71 ± 1.61 | +3.28 / +3.52 | 4,000 / 17,500 | 8 / 5 |

| Claim | Verdict |
|---|---|
| Harm, load (< 100 %) | PASS (work prep planned at 96.7 %: close to the edge) |
| All pass the Check | PASS |
| Best fit gains most at the Check | PASS |
| Cheap option lower over the year | **FAIL**: a tie (4.34 vs 4.44 d loose, 4.71 vs 4.73 std) and €4k vs €15k. After the Act both clear the problem; andon is just redone 8 times at €500 |

### safety_stock_calendar (meters.reserve_meter, KPI on_time)

**Harm ×0 (step wait 0 → 0), on-time 0.879 → 0.879.** Open: on-time 87.75 ± 0.82 % = the base. Constraint: monteurs.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ on time at Check (pt) | KpiBoard at Check (%) | Year Δ on time loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| reorder_point_working_days | 1.00 | 1 | 0.900 | PASS | 0.00 | 0.00 | −0.06 / −0.05 | +0.12 / +0.13 | 1,000 / 3,500 | 2 / 1 |
| warehouse_kanban | 0.90 | 2 | 0.810 | PASS | 0.00 | 0.00 | −0.08 / −0.08 | +0.12 / +0.12 | 3,000 / 6,000 | 1 / 1 |
| double_stock (temptation) | 0.60 | 1 | 0.540 | PASS | 0.00 | 0.00 | −0.03 / −0.03 | +0.13 / +0.13 | 20,000 / 23,000 | 1 / 1 |

| Claim | Verdict |
|---|---|
| Harm > 1.03 | **FAIL** |
| Named-KPI test | **FAIL** |
| Real improvement at the Check | **FAIL** ×3 |
| Best fit gains most | **FAIL** |
| Temptation lower over the year | **FAIL** on the KPI (all ≈ 0); only the €18k aftermath separates them |

Probe (5 seeds, best fit only): smart_meter −45 / kit −30 → on-time 0.873 (−0.4 pt); smart_meter −60 / kit −45 (reorder point 35) → on-time 0.858 (−1.9 pt), p50 lead +0.6 d. Harm is still ×0: the test measures wait and queue at the step, and a material step has neither (in the test it is 0 / 0 = NaN, which fails).

### lmra_tickbox (connections.execution, KPI first_time_right)

Harm ×1.035 (just over 1.03). **Named KPI: FTR 0.415 → 0.422 (rises on the test seed).** Open over 5 seeds: 41.5 ± 2.3 % against base 41.8 %. Constraint: intake.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ FTR at Check (pt) | KpiBoard at Check (%) | Year Δ FTR loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| task_specific_lmra | 1.00 | 1 | 0.900 | PASS | +0.73 ± 2.01 | +0.68 ± 1.15 | +1.34 ± 1.21 / +1.55 ± 1.30 | +0.88 / +1.01 | 6,000 / 10,000 | 3 / 2 |
| stop_the_work_andon | 0.80 | 2 | 0.720 | PASS | +1.82 ± 1.72 | +0.63 ± 0.65 | +1.22 ± 1.14 / +1.45 ± 1.41 | +0.80 / +1.04 | 10,000 / 11,000 | 4 / 2 |
| two_person_rule_old_cabinets (containment) | 0.60 | 1 | 0.540 | PASS | +0.48 ± 2.04 | +0.08 ± 0.63 | +0.77 ± 1.04 / +1.14 ± 1.54 | +0.43 / +0.61 | 4,000 / 17,500 | 8 / 5 |

| Claim | Verdict |
|---|---|
| Harm > 1.03, load | PASS (barely) |
| Named-KPI test | **FAIL** |
| Best fit gains most | **FAIL** (noise) |
| Containment lower over the year than the fix (the named exception) | PASS (0.8 vs 1.3 pt): it may run *next to* the fix, as designed |

### heatwave_overload (outages.report, KPI on_time)

Harm ×1.056 (control room). **Named KPI: on-time 0.916 → 0.919.** Open over 5 seeds: 90.97 ± 4.61 % against base 92.65 %. Extra outages do not make outages late: monteurs and on-call have plenty of slack.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ on time at Check (pt) | KpiBoard at Check (%) | Year Δ on time loose / std (pt) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| peak_load_list_smart_meters | 1.00 | 2 | 0.900 | PASS | +1.32 ± 1.37 | −1.04 ± 1.73 | +0.12 ± 0.62 / +0.28 ± 0.47 | −0.67 / −0.86 | 8,000 / 11,000 | 1 / 1 |
| preventive_transformer_swap | 0.70 | 1 | 0.630 | PASS | +1.37 ± 1.37 | −0.43 ± 1.21 | +0.15 ± 0.57 / +0.35 ± 0.37 | −0.64 / −0.84 | 25,000 / 28,000 | 1 / 1 |
| mobile_transformers (temptation) | 0.60 | 2 | 0.540 | PASS | +1.24 ± 1.73 | −0.21 ± 0.92 | +0.32 ± 0.78 / +0.55 ± 0.27 | −2.57 / −2.54 | 48,000 / 30,000 | 4 / 2 |

| Claim | Verdict |
|---|---|
| Harm > 1.03 | PASS |
| Named-KPI test | **FAIL** |
| Best fit gains most | **FAIL** (all ≈ +1.3 pt, noise) |
| Temptation lower over the year | **FAIL** on the KPI (+0.32 / +0.55 vs +0.12 / +0.28, noise-level); € does separate them (48k vs 8k) |

### stale_capacity_map (congestion.intake, KPI lead_time)

Harm ×1.375 (key accounts 0.48 → 0.70; grid analysts 0.80 → 0.89, the draft's "~79 % → ~90 %" holds). Open: congestion p50 97.4 ± 13.7 d. With 4 requests a week and a 90-day queue at spread 0.8, the p50 lead time is noise (± 14 d); the mechanism shows in team load.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ p50 at Check (d) | Grid-analyst load at Check | KpiBoard at Check (%) | Year Δ p50 loose / std (d) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|---|
| quick_scan_at_intake | 1.00 | 2 | 0.900 | PASS | −1.85 ± 15.06 | 0.72 | −3.51 ± 7.31 | +0.09 / −0.31 | −0.05 / −0.68 | 16,000 / 14,000 | 4 / 2 |
| map_update_from_studies | 0.80 | 1 | 0.720 | PASS | +5.12 ± 16.77 | 0.85 | −2.88 ± 5.44 | −0.95 / +0.28 | −1.03 / −1.65 | 7,500 / 13,500 | 5 / 3 |
| flex_options_on_map | 0.70 | 2 | 0.630 | PASS | +4.36 ± 11.73 | 0.84 | −1.72 ± 7.39 | −0.26 / −1.14 | −1.20 / −1.78 | 5,000 / 8,000 | 1 / 1 |
| map_all_red (temptation) | 0.60 | 1 | 0.540 | PASS | −6.48 ± 15.07 | 0.86 | −4.42 ± 7.49 | −3.39 / −3.73 | −5.45 / −5.43 | 0 / 3,000 | 1 / 1 |

| Claim | Verdict |
|---|---|
| Harm, load | PASS |
| Real improvement (load down) | PASS ×4 (0.89 → 0.72–0.86) |
| Best fit gains most | **FAIL** on the named KPI (noise); PASS on load. The Check shows a lead-time number that jumps ± 15 d |
| Temptation lower over the year | PASS (−5.4 % KpiBoard, every seed −3.8 to −7.4; partly because fewer requests read as lower throughput) |

### monteur_hours (connections.execution, KPI capacity)

Harm ×2.5 (wait at execution). Monteur load 0.71 → 0.85 (draft: ~67 % → ~78 %). Connections p50 +0.7 d, outages on-time unchanged (outages pre-empt). Constraint stays intake.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ p50 at Check (d) | KpiBoard at Check (%) | Year Δ p50 loose / std (d) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| kitting_night_before | 1.00 | 2 | 0.900 | PASS | +0.36 ± 0.79 | −0.11 ± 1.34 | +0.34 / +0.59 | +0.15 / +0.28 | 20,000 / 16,000 | 4 / 2 |
| digital_work_orders | 0.80 | 2 | 0.720 | PASS | +0.46 ± 0.83 | −0.21 ± 0.71 | +0.46 / +0.58 | +0.20 / +0.42 | 9,000 / 12,000 | 1 / 1 |
| start_from_home | 0.70 | 1 | 0.630 | PASS | +0.22 ± 0.81 | −0.12 ± 1.16 | +0.62 / +0.61 | +0.12 / +0.21 | 10,000 / 15,000 | 5 / 3 |
| monteur_overtime (temptation) | 0.60 | 1 | 0.540 | PASS | +0.47 ± 0.80 | −0.54 ± 0.90 | +0.58 / +0.73 | +0.44 / +0.45 | 40,000 / 26,000 | 4 / 2 |

| Claim | Verdict |
|---|---|
| Harm > 1.03, load < 100 % | PASS |
| Draft: "not the constraint of connections" | PASS |
| Draft: "hurts connections' lead time and outages' on-time" | **FAIL** (+0.7 d, 0.0 pt) |
| Draft: monteur load ~67 % → ~78 % | **FAIL** (71 % → 85 %) |
| Best fit gains most | **FAIL** (all ≈ +0.4 d, noise) |
| Temptation lower over the year | **FAIL** on the KPI (0.58 / 0.73 vs 0.34 / 0.59 d, noise-level); € separates them (40k vs 20k) |

### klic_expired (connections.execution, KPI lead_time)

Harm ×1.058 (planners). Open: p50 50.63 ± 1.29 d (base 49.36). Constraint: intake.

| Countermeasure | Fit | Tier | Eff @ m2 | Check | Δ p50 at Check (d) | KpiBoard at Check (%) | Year Δ p50 loose / std (d) | Year KpiBoard loose / std (%) | € a year loose / std | Adoptions |
|---|---|---|---|---|---|---|---|---|---|---|
| klic_at_planning | 1.00 | 1 | 0.900 | PASS | +1.04 ± 0.76 | +2.19 ± 0.89 | +1.00 / +0.95 | +2.69 / +2.31 | 4,000 / 8,000 | 4 / 2 |
| klic_expiry_alert | 0.90 | 2 | 0.810 | PASS | +0.77 ± 0.92 | +2.86 ± 1.11 | +0.95 / +1.05 | +2.23 / +2.61 | 6,000 / 9,000 | 1 / 1 |
| klic_in_readiness_check | 0.80 | 1 | 0.720 | PASS | +0.62 ± 0.48 | +2.02 ± 0.96 | +0.94 / +0.93 | +1.90 / +1.85 | 3,000 / 11,000 | 6 / 4 |

All claims PASS (harm, Check, best fit gains most on the named KPI). No temptation here (`dig_anyway` is a dialog choice, not a countermeasure).

### Worst legal mix on `connections.execution` (draft §3.2: "ftr ≥ 0.4")

Main `contractor_rework` + sides `lmra_tickbox`, `monteur_hours`, `escalation_hallway`: the step's FTR is 0.85 − 0.15 − 0.05 = 0.65 (≥ 0.4, PASS; `klic_expired` cannot be open with `contractor_rework` unless it recurs, and even then 0.57). The *stream* FTR falls to 0.265 ± 0.005 (healthy 0.42); monteurs 0.905, work prep 0.925, no team ≥ 100 % (PASS).

## 4. Harm within the tests

| Problem | Harm (> 1.03) | Named KPI (> 5 pt) | Max planned team load (< 1) |
|---|---|---|---|
| cause_unknown | 1.214 PASS | on time −5.4 pt PASS | 0.857 PASS |
| on_call_far | 1.149 PASS | on time −12.7 pt PASS | 0.857 PASS |
| shift_handover | 1.600 PASS | n/a (lead_time) | 0.857 PASS |
| contractor_rework | 1.120 PASS | FTR −1.8 pt **FAIL** | 0.857 PASS |
| escalation_hallway | 1.164 PASS | n/a | 0.967 PASS (work prep, near the edge) |
| safety_stock_calendar | 0 **FAIL** | on time 0.0 pt **FAIL** | 0.857 PASS |
| lmra_tickbox | 1.035 PASS | FTR +0.7 pt **FAIL** | 0.857 PASS |
| heatwave_overload | 1.056 PASS | on time +0.3 pt **FAIL** | 0.857 PASS |
| stale_capacity_map | 1.375 PASS | n/a | 0.957 PASS (key accounts) |
| monteur_hours | 2.500 PASS | n/a (capacity) | 0.857 PASS |
| klic_expired | 1.058 PASS | n/a | 0.857 PASS |

No harm is larger than the tests allow; four are too *small* for the named-KPI test, one has none.

## 5. Fixes for the mission builder

Each fix names the number to change. "Verified" = re-run in the harness (5 seeds, best fit); "estimate" = extrapolated, re-measure before it goes into `content/`.

**Problems (effects)**
1. `contractor_rework`: `connections.execution ftr −0.15 → −0.20` (verified: harm ×1.305; FTR 0.415 → 0.318 on the test seed, PASS; 5 seeds 41.8 → 32.2 %, best fit +9.8 ± 2.9 pt at the Check; p50 +2.2 d). Clue text "Drie op de twintig" → "Vier op de twintig"; `cost_per_week 750 → 1000` (4 trenches × €250). A smaller −0.18 is not yet run.
2. `lmra_tickbox`: `ftr −0.05 → −0.13` and `touch_time 1.03 → 1.05`. At −0.10 / 1.05 (verified): harm ×1.110, FTR −4.1 pt on the test seed (still FAIL), best fit +4.5 ± 1.9 pt. −0.13 is extrapolated (≈ −5.3 pt), not yet run. Comment: "one job in eight is stopped late".
3. `heatwave_overload`: add `{target: outages.repair, property: touch_time, value: 1.25}` (estimate: a station that trips under solar load must be relieved in sections before the fuse goes back in). Verified: harm ×1.175, on time 0.916 → 0.826 (PASS), 5 seeds 92.6 → 81.7 %, best fit +8.2 ± 1.4 pt at the Check.
4. `monteur_hours`: as drafted it is a non-bottleneck in disguise: no countermeasure gains anything measurable. Either
   - make it bite: `availability −0.12 → −0.20` (verified: monteurs become the connections constraint at 0.94 load; p50 +3.3 d; `kitting_night_before` −3.1 ± 1.9 d at the Check). Then fix the comment ("~67 % → ~78 %" → "71 % → 94 %; monteurs become the constraint") and the clue text ("bijna een uur" → "ruim anderhalf uur"). −0.16 is not yet run; or
   - keep −0.12 and make it an explicit non-bottleneck lesson (the Check says `not_constraint`; the debrief says the hours freed matter only once monteurs limit the flow).
   In both cases correct the draft's load claim: 71 % → 85 % at −0.12.
5. `safety_stock_calendar`: cannot pass the tests through `reorder_point` alone (verified: −60 / −45 → on time only −1.9 pt; harm ×0). Needed:
   - a **code/test change** (C-task): a material step's harm = its stock-out wait (`test_catalog._flow_harm` divides 0 by 0 today);
   - **the story**: make the supplier's lead time "tien werkdagen" (= 14 calendar days). Then calendar-day demand × 10 = 57 against a real 80, which is the draft's "~20 lower";
   - **the KPI**: `kpi: on_time → lead_time` (meters p50 +0.6 d at −60) or move the problem to a step whose norm has less slack. Until then, keep it out of `content/`.
6. `stale_capacity_map`: `kpi: lead_time → capacity`. The Check then reads team load and congestion capacity (quick scan: 5.6 → 8.0 a week; grid analysts 0.89 → 0.72), not a p50 that jumps ± 15 d.

**Countermeasures**
7. `repeat_fault_analysis`: `tier 3 → 2` (eff at m2 0.45 → 0.81, passes the Check). Or keep tier 3 and drop it from tier 2's list until maturity 3.
8. `standby_by_fault_map`: own effect `outages.locate touch_time 0.95 → 0.85` (6 minutes, visible above the tick). Without it the headcount fixes beat the best fit once resolved (p85 3.50 vs 3.77 h). Estimate, re-measure.
9. `andon_standup` vs `tiered_escalation_24h` (a tie over the year): `andon_standup decay_days 30 → 21` and `tiered_escalation_24h` own effect `connections.design ftr +0.02 → +0.04`, so the full route keeps an edge after the Act. Estimate, re-measure. The structural fix is the draft's `poor_fix` repair quest, which the simulation does not model yet.
10. `cause_codes_pareto`: `decay_days 60 → 120` (a weekly review with `sustains: true` should outlast a one-off field). The patient fix then costs fewer redos than the temptation (now €48k vs €28k a year). Estimate.
11. `smaller_on_call_areas` / `mutual_aid_agreement` (decay null) beat the best fit over a standardised year. Acceptable (both are good fixes), or give `standby_by_fault_map decay_days 90 → 180` (the map is reviewed every quarter, says its own text). Estimate.

**Targets**
12. `acm_visit` / `acm_improvement_plan`: on-time ≥ 0.85 does not separate the paths. Replace with `{kpi: lead_time, op: '<=', target: 0.96 × the p50 at acceptance}` (a relative target: the expert path improves on every seed by 4–12 %, "left open" by 0). If goals must stay absolute: `kpi: lead_time, op: '<=', target: 56` with `deadline_days 70 → 84`, and re-measure. Either needs C4 support for a relative target or K5 calibration.
13. `t2_first_okr` key results:
    - `kr_conn_on_time 0.92` → replace with `connections lead_time (p50) <= 49` (expert 48.5 ± 1.0; with Act III open 55–57);
    - `kr_conn_wip_age 45` → replace with `connections first_time_right >= 0.45` (leading; expert 0.462 ± 0.029, healthy 0.421);
    - `kr_outage_on_time 0.92 → 0.91`;
    - `kr_meters_ftr 0.85` → drop, or `>= 0.74` once a meters countermeasure exists (nothing in tier 2 moves it: 0.72);
    - `kr_conn_throughput 33 → 30` (demand is 30 a week: the output KR is met by doing nothing, which is the lesson);
    - `kr_reinforcement_wip` → needs a reinforcement-only measure (code), or `<= 95` on the stream's wip_age (healthy 101.8: a stretch).
14. Code note (not content): `KpiBoard.improvement` counts throughput up as better, so fixing failure demand (`cause_unknown`, `stale_capacity_map`, `heatwave_overload`) reads as a loss at the quarterly review. Weigh throughput against demand, or leave it out for demand-driven streams.

## Not yet run

**Not yet run** (the session ended first): `contractor_rework ftr −0.18` (A2), `lmra_tickbox ftr −0.13` with `touch_time 1.05` (C2), `monteur_hours availability −0.16` (E2). Until they are measured, use the verified values in fixes 1 and 4 (−0.20 for both) and treat fix 2's −0.13 as an estimate. Fixes 8–11 and the targets in 12–13 also still need a re-measure.

## Re-measure 2026-10-16 (the mission builder)

Applied to the draft, then re-run with `draft_check.gd` in its new quick mode (harm and the Check, no year runs), seeds 11–15, maturity 2. Gains are paired per seed, positive = better.

| Fix | Change in the draft | Result | Verdict |
|---|---|---|---|
| 1 `contractor_rework` | ftr −0.15 → −0.20, "Vier op de twintig", cost €1,000 a week | harm ×1.305; FTR 0.415 → 0.318 (−9.7 pt); best fit +9.8 pt (+6.4 to +14.0), the others +7.5 to +7.6 | PASS: named KPI, and the best fit gains most |
| 2 `lmra_tickbox` | ftr −0.05 → −0.13, touch time 1.03 → 1.05 | harm ×1.101; FTR 0.415 → 0.378 (−3.7 pt, the test needs > 5); best fit +6.6 pt, andon +6.0, the two-person rule +2.5 | named KPI still FAIL; the order by fit now shows. Next: −0.17 (one job in six), not yet run |
| 3 `heatwave_overload` | + `outages.repair touch_time 1.25` | harm ×1.175; on time 0.916 → 0.826; best fit +8.2 pt, the others +7.4 to +7.8 | PASS |
| 4 `monteur_hours` | availability −0.12 → −0.20 (texts: "ruim anderhalf uur", 2.6 FTE) | harm ×3.94; monteurs the connections constraint (planned load 0.94); every fix +2.0 capacity a week on seed 11 | PASS (the fixes all pass; the steady state does not separate them by fit) |
| 5 `safety_stock_calendar` | base `smart_meter` lead 10 → 28 days (20 working days), reorder point 95 → 190 (`content/value_streams.yaml`, an estimate; the base never runs out); the problem's reorder point −20 → −60 (the sheet's 20 × 40/7 + a small sigma); the kit effect dropped (its supplier counts calendar days; the clue says so); KPI on_time → wip_age; the sim now records a stock-out's wait at a material step | harm ×12,000 (stock-out wait from ~0); every fix gains +1.6 d on the age of open work (+1.0 to +2.8 per seed, ~9 %); on time moves < 1 pt (the meters norm has slack). Named-KPI test on the harm seed: wip_age 15.5 → 14.6 at day 150 | harm and Check PASS; the named-KPI snapshot FAILS (a point-in-time age; it rose on all five seeds at day 266). When tier 2 enters content, the test should average the age over the window |
| 6 `stale_capacity_map` | KPI lead_time → capacity, tried | only the quick scan adds congestion capacity (+2.3 a week); the other three fixes read `not_constraint` and would fail the Check | REJECTED: KPI stays lead_time (noisy); open |
| 7 `repeat_fault_analysis` | tier 3 → 2 | eff 0.81, passes; +3.9 pt on time, below the Pareto's +5.2 | PASS |

Probe for fix 5 (5 seeds, 84 days after the warm-up, meters stream): base lead 28 / reorder point 190: on time 0.877, p50 9.9 d, open-work age 16.7 d, no stock-out. Reorder point −60: on time 0.869, p50 10.4 d, age 18.3 d, stock-out wait 12.8 h per order. −70: on time 0.861, age 17.9 d. At a lead of 10 calendar days even −30 gave only 3 h of waiting.

Still to run: `lmra_tickbox` at −0.17; the ACM and OKR scenarios after these changes (their targets in fixes 12–13 still need it); fixes 8–11 (estimates).

## Reproduce

```
python tools/draft_to_json.py docs/superpowers/specs/2026-10-15-tier2-missions-draft.md draft.json [--only a,b] [--quick]
godot --headless --path game --import
godot --headless --path game --script res://tools/draft_check.gd -- draft.json out.json
```

Add `"only": [problem ids]` to split the run over processes (about 10 minutes per problem on one core) and `"scenarios"` for the fork, ACM and OKR runs (format in the harness header).
