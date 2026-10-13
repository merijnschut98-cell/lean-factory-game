# Counterfactual KPI reward — design

> Status: Merijn chose the counterfactual reward, paid at the review (2026-10-13, multiple choice). The details below are Claude's calls, recorded in PLAN.md as pending Merijn.

## Why
The quarter-over-quarter reward (department-KPIs feature) paid mostly for noise. Guarding it with a best-level mark and a dead band made it almost never pay. In the simulation, a KPI choice moves the end-to-end numbers less than random variation between quarters does. Merijn's rule: no points for what doesn't really help, and full points for what does.

## The rule
At a review, after the KPIs are chosen, the board runs the coming quarter twice from the same moment. The two runs share common random numbers: every random sequence continues from the same state, so they differ only in the work rules.
- **Habit run:** without the board's rules (the effect source `board:kpis` removed). Each department works as it always did, under whatever problems, experiments and fixes are in force.
- **Chosen run:** with the chosen KPIs' rules.

The reward is the measured difference between the two runs: `improvement(habit, chosen)` over the streams the departments touch, with each KPI's change capped at ±50% and thin streams (fewer than 10 finished orders) ignored. A negative difference pays nothing. The coach words the result as a forecast: "Met deze KPI's verwachten we …".

## Claude's calls (pending Merijn)
1. **Compare with the habit, not with last quarter's choice.** Comparing with the previous choice opens an exploit: pick bad KPIs one quarter, good ones the next, and get paid for the swing. Against the habit, the same good choice pays every quarter, as a dividend on good management, and a choice no better than the habit pays nothing. That includes picking the same rules the Obeya already set, because the fix was paid at the Check.
2. **No baseline review, no best levels, no dead band.** The paired runs carry no quarter-to-quarter noise, so these guards go, and so does the saved snapshot. The first review pays like any other.
3. **The forecast is the reward**; the real quarter that follows is not re-measured. Merijn chose to pay at the review.

## Mechanism
- `NetworkState.copy(net) -> Network`: a fresh network from the same content (`Network.config`, kept by `Network.create`), restored from `capture(net)`. Pool settings that are not effects (the menu's `pull_limit_days`) are copied too. Reading the original changes nothing in it.
- `KpiBoard.forecast(net) -> {habit, chosen}`: two copies, the habit one with `board:kpis` cleared, each advanced `REVIEW_DAYS`, then measured per stream (the existing measures plus `wip_age`).
- `review()` validates, sets the real `board:kpis`, calls `forecast`, pays `max(0, improvement)` × 1,000 XP / €10,000, and returns `{error, improvement, paid, xp, budget, question, habit, chosen}`.
- Save: the board keeps `unlocked`, `chosen` and `next_review_at`. Old saves' `snapshot`, `best` and `has_baseline` are ignored.
- Cost: two 91-day runs per review, about 1–2 s on the real network, once a quarter.

## Tests
- A choice that changes no rule (the habit) pays exactly 0.
- A choice that measurably beats the habit in the paired runs pays more than 0, and the same choice pays again next quarter.
- A worse choice pays 0.
- A copy runs exactly like the original (same finished records after N days), and reading it leaves the original untouched.
- The error codes, save/load and the unlock behave as before.
