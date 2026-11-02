# Phase A Step 4 — Problem Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Problems and countermeasures change the simulation through named, removable effects on top of the content's base values. The Check step can then compare before and after, and saves can store which effects are active.

**Architecture:**
- A `SimModifiers` object, owned by the `Network`, keeps:
  - the effects per *source* (e.g. `problem:incomplete_application`, `cm:poka_yoke_form`);
  - a snapshot of each touched field's base value.
- Any change recomputes every effective field as `clamp(base × Π factors + Σ additions)` and writes it into the plain sim fields. The hot paths (`_tick`, `Capacity`) stay unchanged and automatically see effective values.
- `Network.set_effects / clear_effects` are the public entry points.

**Tech Stack:** Godot 4.7.2, typed GDScript, headless test runner.

**Spec:** `PLAN.md` Phase A step 4 ("target a step, pool, stock item or stream; modify touch time, FTR, availability, headcount, wait days, demand … keep content values as base values … so effects can be removed, saved and compared"); `docs/GDD.md` (Problem catalogue, Simulation model).

## Global Constraints
- An effect is `{target, property, value}`. The property decides both the kind of target and the operation:

  | property | target | operation | bounds |
  | --- | --- | --- | --- |
  | `touch_time` | step `stream.step` | × | ≥ 1 min |
  | `ftr` | step | + | 0.05–1 |
  | `applies` | step | + | 0–1 |
  | `wait_time` | step | × | ≥ 0 |
  | `availability` | pool | + | 0–1 |
  | `headcount` | pool | + | ≥ 0 |
  | `lead_time` | stock | × | ≥ 0 |
  | `reorder_point` | stock | + | ≥ 0 |
  | `demand` | stream | × | ≥ 0 |

- Factors must be > 0. Integer fields are rounded.
- Setting a source replaces its earlier effects. An invalid effect list changes nothing and returns an error string.
- An effect applies to work from then on. An order already in progress keeps its remaining time. A headcount change shows in attendance from the next day.
- `sim/` stays pure: the modifiers never store the Network (no reference cycle).

## Review Focus
1. Clearing every source must restore the base values exactly, bit for bit, including ints. Test: snapshot the fields, set, clear, compare.
2. Two sources on the same field must combine, not overwrite. Test: factors multiply and additions add.
3. A step id is only unique within its stream (`intake` exists in connections and congestion). The target `connections.intake` must not touch `congestion.intake`. Test.
4. Bounds: FTR −0.5 on a 0.75 step stops at 0.05; headcount −20 stops at 0. Test.
5. The constraint moves: a 30% faster design moves the connections constraint from work_prep to gis. This is the GDD's core lesson. Test on real content.

---

### Task 1: `SimModifiers` + Network entry points
**Files:**
- Create: `game/src/sim/modifiers.gd`
- Modify: `game/src/sim/network.gd`, `game/src/sim/value_stream.gd` (`demand := 1.0`, used by `per_week()` and `_start_day`)
- Test: `game/tests/test_modifiers.gd`

**Interfaces (produces):**
- `Network.set_effects(source: String, effects: Array) -> String` ("" on success)
- `Network.clear_effects(source: String) -> void`
- `Network.modifiers: SimModifiers`
- `SimModifiers.sources() -> Dictionary` (source → effects, for saves and the UI)
- `static SimModifiers.scaled(effects: Array, k: float) -> Array` (k = 0 means no effect, 1 means full: a factor f becomes 1 + (f − 1)·k, an addition v becomes v·k; for countermeasure effectiveness in step 5)

- [ ] Tests (all in `test_modifiers.gd`):
  - `test_touch_time_factor_reaches_capacity`
  - `test_clearing_restores_base_exactly`
  - `test_sources_stack`
  - `test_setting_a_source_again_replaces_it`
  - `test_step_targets_are_scoped_to_their_stream`
  - `test_bounds_clamp`
  - `test_invalid_effects_change_nothing`
  - `test_demand_scales_arrivals`
  - `test_scaled`
- [ ] Implement; run `-- modifiers` and the full suite; commit.

### Task 2: Real-content lesson test + docs
- `test_value_streams.gd::test_standard_designs_move_the_constraint_to_gis`
- ARCHITECTURE.md (Modifiers section) and PLAN.md (step 4 done). Record the open Phase B decision there: are the content values the healthy process (with starting problems as active effects), or the starting state?
- simplify; full suites; push.
