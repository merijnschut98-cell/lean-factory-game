# Phase A Step 4b — Structural Levers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The flow countermeasures for catalogue problems 6 (*Storing gooit de planning om*) and 8 (*Vergunningen in batches*) can be simulated as changes to how work flows, not only as faster or better steps.

**Architecture:**
- New optional fields in the content.
- `SimModifiers` gains a third operation, SET (the last source wins), so countermeasures can switch a lever on and off like any other effect, and it is saved with it.

**Spec:** PLAN.md Phase A step 4b; GDD problems 6 and 8 and the tier-3 countermeasures ("frozen planning window and reserved outage capacity", "permits in parallel").

## Levers

| Lever | Content field | Effect property (op) | Behaviour |
| --- | --- | --- | --- |
| Reserved capacity | pool `reserve: {stream, people}` | `reserve` (+, ≥ 0) and `reserve_for` (SET stream id) on a pool | Up to `people` of those present are held for that stream. Other streams cannot use them while they are idle. |
| Frozen planning window | stream `preempts` | `preempts` (SET bool) on a stream | Without it, outages wait for a free person (or the reserve) instead of interrupting planned work. |
| Cost of interruption | work step `interrupt_to` + `interrupt_wait_days` | content only (it is how the process reacts) | An interrupted order goes back to `interrupt_to` (re-planning, a new appointment) after the wait, instead of resuming. |
| Batching | wait step `batch_days` | `batch_days` (+, ≥ 0) on a step | The wait starts at the next multiple of `batch_days` (e.g. weekly on Monday). |
| In parallel | wait step `starts_with: <earlier step>` | `starts_with` (SET step id, "" = in sequence) on a step | The wait starts when the order enters that earlier step. On reaching the wait, the order only waits for what is left. |

## Explicitly not in this step
- **WIP limits.** In the current model nothing is lost while an order waits, and people work one order at a time, so a limit only moves the queue upstream. Showing its value needs a cost of WIP: multitasking overhead or dossiers going stale. That is a modelling decision for Merijn; tracked in PLAN.md.
- **Heijunka.** It needs a release mechanism; it can follow the WIP decision.

## Review Focus
1. Without any lever, results are identical to before. The existing regression and skip-idle tests cover this; the content changes are additive.
2. A reserve must not starve its own stream. Reserved people take outage work first; outages may still pre-empt others when the reserve is busy.
3. A parallel wait that has already finished when the order arrives costs nothing. One that has not finished costs only the rest.
4. Rework back past the start step must not start the parallel wait again.
5. Capacity: the reserve lowers the spare capacity other streams have on that pool. Test.

### Task 1: Tests, then sim
- `test_levers.gd`:
  - `test_reserve_keeps_people_free_for_outages`
  - `test_frozen_window_stops_preemption`
  - `test_interrupted_work_is_replanned`
  - `test_batched_wait_starts_on_the_batch_day`
  - `test_parallel_wait_overlaps_the_earlier_step`
  - `test_rework_does_not_restart_a_parallel_wait`
  - `test_levers_switch_by_effect`
  - `test_reserve_lowers_capacity_for_other_streams`
- Implement in `pool.gd` (`reserve`, `reserve_for`, `free_for(stream)`), `step.gd`, `work_order.gd` (`early`), `network.gd`, `modifiers.gd` (SET), `capacity.gd`.

### Task 2: Validator + content + docs
- Python validation of the new fields, with pytest cases.
- Content: connections `execution` gets `interrupt_to: planning`, `interrupt_wait_days: 2` (a monteur pulled away to an outage means a new appointment). Re-check the calibration.
- ARCHITECTURE.md, PLAN.md, simplify, push.
