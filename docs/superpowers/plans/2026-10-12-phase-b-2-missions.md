# Phase B.2 — Evidence-Based Fixes and the Mission System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:**
- Ground the open review answers in evidence.
- Make the game a progressive RPG through missions: one main mission and at most three side missions active at once, unlocked by progress, with a senior-manager coach who mostly asks questions and only helps with the main mission (CLAUDE.md §2).

## Part 1 — Evidence-based content (Merijn's answers, 2026-10-12)

| Item | Evidence | Content |
| --- | --- | --- |
| Connection norm | The 18-week term (art. 23 E-wet) was removed in Feb 2025; the ACM still uses 18–22 weeks as reference in disputes; a new ACM draft is due. Real average waits were ~40–44 weeks in 2024–2025 (Netbeheer Nederland), mostly from grid capacity. | Norm 126 days (18 weeks). The healthy base gets realistic external waits: customer approval 14 d, permit/instemming 30 d (60% of jobs), grid reinforcement 120 d for 15% of jobs. The base meets the norm ~90% of the time. Status calls start after 6 weeks without news. |
| Digging-damage claims | 46,799 damages in 2022 (5.6% of digs); €38.8M direct repair costs a year (~€850 per damage); €200–290M consequential damage (Wibon evaluation). | Problems may have `cost_per_week` (€). Region charges it daily to the budget while the problem is active, weakened by a working countermeasure; Check shows the cost before and after. Graafschade: ~5 extra damages a week × €850 ≈ €4,250. |
| Revision backlog → digging damage | ~60% of damages happen because it is not precisely known what lies where (Bouwend Nederland); no figure for outdated maps specifically. | Estimate, marked as one: a four-month backlog leaves a few percent of cables unmapped, concentrated in new-build areas where digging happens → daytime outages ×1.05 (was 1.1), cost €425 a week. |
| Intake checklist | — | Already real but weak (fit 0.7). |

## Part 2 — Mission system

**Content** (`content/missions.yaml`):
- `coach: {name, role, stages: {stage: [questions]}}` holds the generic Kata questions per stage.
- `missions`: id, name, kind (main | side), tier, `requires {missions, belt}`, briefing, debrief, optional fail text, a `goal` and optional `deadline_days`, rewards `{xp, budget}`, and (main only) `coach` insights per stage.
- Goal types:
  - `walk {stream}`: observe every work step of a stream (gemba walk);
  - `investigate {problem, clues}`: find that many key clues (activates the problem);
  - `solve {problem}`: the problem is resolved (activates it).

**Rules** (`game/src/rules/missions.gd`, `Missions`; pure, holds the Region, Region does not point back):
- `available()`: the requirements are met and the mission is not active or completed.
- `accept(id) -> String` returns an error code: `unknown`, `locked`, `not_available`, `main_active`, `side_full`, `problem_unavailable`. Accepting activates the goal's problem.
- `abandon(id)`.
- `update()`, after any player action or time step: completes goals (rewards, events) and fails expired deadlines.
- `ask_coach() -> {kind: question|insight|no_main, text, stage}`. The coach speaks only about the active main mission:
  - the stage follows from the goal and the problem's phase (`go_see`, `understand`, `experiment`, `reflect`);
  - questions rotate, and every third ask at the same stage gives the mission's insight for that stage, if it has one.
- Saved with `to_dict`/`load_dict`. `Region.MAX_OPEN` becomes 4 (1 main + 3 side).

**Validation:** `tools/build_content.py` checks:
- ids and kinds;
- that requirements exist and form no cycle;
- that goal targets exist;
- `clues` ≤ the problem's key clues;
- one mission per solved problem;
- at least one main mission open from the start;
- that every mission is reachable.

**Tests:**
- `test_missions.gd` (fixture): limits, unlock by mission and belt, coach only for main, insight rotation, walk/investigate/solve completion, deadline failure, abandon, save round trip.
- Real content (`test_catalog`): every mission loads; the first main mission is available on day 0.

**Tier-1 chain** (Dutch text): main missions walk → custom_design → incomplete_application → status_callers → done_but_not_closed → revision_backlog → digging_damage → grid_study_queue → knowledge_drain (Henk retires: a deadline). Side missions: walk outages, wrong joint, not at home, permits, installer not ready, silent meter, investigate the grid-study queue.

## Verification
The full gate after each step (Godot tests, content check, pytest), simplify on every code change, PLAN.md kept in sync, CI green on each push.
