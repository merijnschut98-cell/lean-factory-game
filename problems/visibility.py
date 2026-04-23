"""Problem visibility logic — determines when dormant problems surface."""
from __future__ import annotations
from typing import List
from problems.problem import Problem, ProblemState


def evaluate_visibility(problems: dict, factory) -> List[str]:
    """
    Activate dormant problems whose visibility conditions are now met.
    Returns list of newly-activated problem IDs.

    Visibility tiers:
      obvious  — always active from Day 1, no prerequisites
      subtle   — activates after player has inspected the zone at least once
      hidden   — activates only after specific factory maturity threshold is met
    """
    newly_active = []
    inspected_zones = {entry["entity"].split(":")[0] for entry in factory.inspection_log}

    # Circuit breaker: don't activate new problems beyond the cap (max 3 active, max 1 critical)
    active_now = [p for p in problems.values()
                  if p.state not in (ProblemState.DORMANT, ProblemState.RESOLVED)]
    active_count   = len(active_now)
    critical_count = sum(1 for p in active_now if p.severity == "critical")

    # Build set of problem IDs unlocked by active/completed missions
    gated_problems: set = set()
    if hasattr(factory, "missions") and factory.missions:
        for mission in factory.missions.values():
            if mission.active or mission.completed:
                gated_problems.update(mission.problem_ids)
        mission_system_active = True
    else:
        mission_system_active = False

    for prob in problems.values():
        if prob.state != ProblemState.DORMANT:
            continue
        if active_count >= 3:
            break
        if prob.severity == "critical" and critical_count >= 1:
            continue
        # Mission gate: if missions are loaded, only activate problems in active missions
        if mission_system_active and prob.id not in gated_problems:
            continue

        if prob.visibility == "obvious":
            _activate(prob, factory, newly_active)
            active_count += 1
            if prob.severity == "critical":
                critical_count += 1

        elif prob.visibility == "subtle":
            if prob.zone_id in inspected_zones:
                _activate(prob, factory, newly_active)
                active_count += 1
                if prob.severity == "critical":
                    critical_count += 1

        elif prob.visibility == "hidden":
            pass  # gated by mission system and maturity (Phase 5/6)

    return newly_active


def _activate(prob: Problem, factory, newly_active: List[str]) -> None:
    prob.state = ProblemState.ACTIVE
    prob.first_seen_day = factory.time.day
    newly_active.append(prob.id)
