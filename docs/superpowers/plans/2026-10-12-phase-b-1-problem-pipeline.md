# Phase B.1 — Problem and Countermeasure Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the problem catalogue of the GDD into validated content files that the rules (`ProblemDef`, `CountermeasureDef`, `Region`) load, starting with six tier-1 problems.

**Architecture:**
- `content/countermeasures.yaml` and `content/problems_tier1.yaml` follow the shapes that `RulesFixture` already uses.
- `tools/build_content.py` validates each file and cross-checks references against `value_streams.yaml`: steps, pools, tools, countermeasures and effect targets.
- `game/src/rules/catalog.gd` (`Catalog`) loads the JSON into definitions.
- Godot tests on real content prove that each problem is solvable and that it actually hurts its stream in the simulation.

**Spec:**
- `docs/GDD.md`: Problem catalogue v1, Countermeasures (tiers), Problem solving.
- Merijn's decisions (PLAN.md):
  - several countermeasures per problem, each with a fit;
  - the content holds a reasonable base, and the starting problems are active effects on top.

## Global Constraints
- Game text in Dutch; ids and keys in English (snake_case).
- Effect properties and their target kinds as in `SimModifiers.PROPERTIES`; tools, wastes and KPIs as in `Investigation`. The Python validator keeps its own copy of these lists (tracked tech debt); the Godot content test makes any mismatch fail.

## Review Focus
1. Every problem has a key clue at depth 0, and a key clue at depth n − 1 for every clue at depth n. Otherwise deeper clues are unreachable.
2. Every clue's place exists, and a conversation clue sits at a work step, where there is a team to talk to.
3. Every problem has at least one fitting countermeasure that can work at full strength in its tier, with `multiplier.full × fit ≥ 0.5`.
4. Every effect resolves on the real network: right target kind, right step kind.
5. Every problem measurably hurts the KPI it names, or its stream's capacity, over 60 simulated days. This keeps the content honest.

### Task 1: Validator + cross-checks (pytest first)
### Task 2: Content: 6 problems, about 12 countermeasures
1. De onvolledige aanvraag
2. Meterkast niet gereed
3. De verkeerde mof in de bus
4. Maatwerk voor standaardwerk
5. Niet thuis
6. Vergunningen in batches (uses the `batch_days` and `starts_with` levers)

### Task 3: `Catalog` loader + real-content tests in Godot
### Task 4: Docs, PLAN.md, simplify, push
