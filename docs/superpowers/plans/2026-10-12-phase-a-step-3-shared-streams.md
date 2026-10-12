# Phase A Step 3 — Shared Streams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the outage, meter and congestion value streams to the simulation. They share people with the connections stream, outages arrive day and night, and they pre-empt planned monteur work.

**Architecture:**
- A new `WeekSchedule` (a bitmap of the 1008 ten-minute slots in a week) replaces the single daily `shift`. Pools use it for working hours; streams use it for when orders arrive.
- A work step may be served by several pools: during the day the monteurs do outages, at night and at weekends the on-call crew does.
- At the end of a shift, work in progress goes back to the front of its queue (handover).
- `Capacity` moves from per-working-day to per-week units, because some streams now run 7 days.

**Tech Stack:** Godot 4.7.2, typed GDScript, custom headless runner; Python 3 + PyYAML content pipeline with pytest.

**Spec:** `PLAN.md` (Phase A step 3 and its design points), `docs/GDD.md` §4 (value streams) and §5 (simulation model).

## Global Constraints
- Times are quoted `"HH:MM"` strings on the 10-minute grid; `"24:00"` is allowed as an end time only.
- Days are `mon`…`sun`, a single day or a range `a-b` with a ≤ b (e.g. `mon-fri`, `sat-sun`, `mon-sun`).
- Game text is Dutch, keys and ids are English. `sim/` stays pure (no nodes) and has no RefCounted cycles.
- Results must be identical with and without idle skipping (existing test, extended to the full network).

## Review Focus
1. A pool whose schedule wraps through midnight (on-call 15:00–24:00 then 00:00–07:00) must not hand over at midnight. Test: on-call work started at 23:30 continues past 00:00.
2. An outage that is still in progress at 07:00 when on-call ends must be picked up by the monteurs, not wait until 15:00. Test: handover puts it at the front of the queue.
3. Rework must not take material twice. In the meter stream, the material step comes before the step that rework returns to (asserted by the content design; the connections stream already does this).
4. A day in a stream's arrival schedule must not produce arrivals outside its window. Test: weekend arrivals only for 7-day streams.
5. With 24/7 pools, idle skipping must still skip: a simulated year with all four streams stays under ~2 s. This is a measured check, not a test.

---

### Task 1: `WeekSchedule` + day parsing
**Files:**
- Create: `game/src/sim/week_schedule.gd`
- Modify: `game/src/sim/calendar.gd`
- Test: `game/tests/test_calendar.gd`

**Interfaces:**
- Produces:
  - `SimCalendar.WEEK := 7 * MINUTES_PER_DAY`
  - `SimCalendar.parse_days(text: String) -> PackedInt32Array` (empty on error)
  - `WeekSchedule.from_blocks(blocks: Array) -> WeekSchedule` (null on error)
  - `contains(t: int) -> bool`
  - `hours() -> float` (per week)
  - `next_start(t: int) -> int` (first on-minute ≥ t, or `t + WEEK` if never)
  - `overlap_hours(other: WeekSchedule) -> float`
  - `slots_on_day(day: int) -> PackedInt32Array` (minute offsets within that weekday)
- [ ] Tests:
  - `parse_days("mon-fri") == [0..4]`, `"sat"` → `[5]`, `"fri-mon"` and `"x"` → empty;
  - a mon–fri 07:00–15:00 block gives 40 h; a schedule with blocks 15:00–24:00 and 00:00–07:00 contains 23:55 and 00:05;
  - `next_start` from Friday 16:00 is Monday 07:00;
  - `overlap_hours` of weekday-day vs 24/7 is 40.
- [ ] Implement; run `-- calendar`; commit.

### Task 2: Pools on schedules, multi-pool steps, per-week arrivals, handover, preempts flag
**Files:**
- Modify: `pool.gd`, `step.gd` (`pool_ids: PackedStringArray`), `value_stream.gd` (inner `class Arrivals {per_week, when}`, `arrivals: Array[Arrivals]`, `per_week()`, `preempts: bool`), `network.gd`, `capacity.gd`, `tests/lib/net_fixture.gd`
- Tests: `test_network.gd`, `test_capacity.gd`

Config shape:
- pool `schedule: [{days, from, to}]`;
- stream `arrivals: [{per_week, days, from, to}]`, `norm_days` or `norm_hours`, optional `preempts: true`;
- step `pool: id | [ids]`.

Network:
- `_start_day` draws Poisson(per_week × today's slots / week slots) per source, at random on-slots of that day;
- `_hand_over()` runs first in `_tick`;
- pre-emption only when the stream has `preempts`;
- `_next_busy_tick`: a pool with busy orders → next tick; a pool with queued work and `present > 0` → `schedule.next_start`; plus arrivals, waits, deliveries and the day boundary.

Capacity:
- per week;
- a multi-pool step's load is split by each pool's `overlap_hours` with the stream's arrival schedules (weighted by `per_week`);
- result key `capacity_per_week`.

- [ ] Tests:
  - 24/7 on-call works on Saturday;
  - the handover at shift end puts the order in front of the queue, and the next shift's pool finishes it;
  - midnight inside a schedule causes no handover;
  - a stream without `preempts` never pre-empts;
  - weekend arrivals only for streams whose schedule includes the weekend;
  - Capacity: utilisation tests rewritten per week (same ratios), plus the multi-pool split.
- [ ] Implement; run all Godot tests; commit.

### Task 3: Content validator + content
**Files:**
- Modify: `tools/build_content.py`, `tests/test_build_content.py`, `content/value_streams.yaml`, regenerate `game/data/value_streams.json`

Validator:
- `_validate_block`: days syntax, times on the grid, 24:00 as end only, from < to;
- pools need `schedule`, streams need `arrivals`;
- exactly one of `norm_days` or `norm_hours`;
- `preempts` must be a boolean;
- `pool` is a string or a non-empty list of known pools.

New pools:
- `on_call` (Storingsdienst, 2, 1.0, weeknights and weekends);
- `control_room` (Bedrijfsvoeringscentrum, 2, 1.0, 24/7);
- `key_accounts` (Grootzakelijk, 1, 0.85);
- `meter_office` (Meetdata & registratie, 1, 0.85).

New stock: `cable_joint`, `smart_meter`.

Streams:

| Stream | Arrivals | Norm | Priority | Steps |
| --- | --- | --- | --- | --- |
| `outages` | 10/week daytime + 8/week around the clock | 4 h (compensation norm) | 3, preempts | report → locate → joint (applies 0.5) → repair |
| `meters` | 40/week | 21 days | 2 | reserve meter → appointment → customer window → visit (ftr 0.8, rework to appointment, wait 2 d) → registration |
| `congestion` | 4/week | 126 days | 1 | intake (ftr 0.7, wait 10 d) → congestion study (grid_analysts) → capacity queue wait (applies 0.7) → offer → customer signs → register |

- [ ] pytest error cases added; run the build and `--check`; commit.

### Task 4: Real-content regression tests + docs + PLAN.md
- `test_value_streams.gd` (renamed from `test_connections_stream.gd`):
  - design is still the connections constraint;
  - outages p85 lead < 0.5 day;
  - preemptions happen;
  - meters and congestion finish orders;
  - skip-idle equivalence over all streams.
- Update `docs/ARCHITECTURE.md` (`WeekSchedule`, handover, per-week capacity), PLAN.md, and the measured year runtime.
- Run `simplify`, the full suites; push.
