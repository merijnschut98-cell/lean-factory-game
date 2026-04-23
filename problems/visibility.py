"""Problem visibility logic — determines when dormant problems surface."""
from __future__ import annotations
from typing import List
from problems.problem import Problem, ProblemState

_SEVERITY_PRIORITY = {"critical": 0, "high": 1, "medium": 2, "low": 3}


def evaluate_visibility(problems: dict, factory) -> List[str]:
    """
    Activate dormant problems whose visibility conditions are now met.
    Returns list of newly-activated problem IDs.

    Problems are evaluated in severity order (critical first) so the cap
    preferentially surfaces the most important problems.
    """
    newly_active = []
    inspected_zones = {entry["entity"].split(":")[0] for entry in factory.inspection_log}

    # Count already-active problems to enforce the cap
    active_count   = sum(1 for p in problems.values()
                         if p.state not in (ProblemState.DORMANT, ProblemState.RESOLVED))
    critical_count = sum(1 for p in problems.values()
                         if p.state not in (ProblemState.DORMANT, ProblemState.RESOLVED)
                         and p.severity == "critical")

    # Build the set of problems unlocked by active/completed missions
    gated_problems: set = set()
    mission_system_active = bool(factory.missions)
    for mission in factory.missions.values():
        if mission.active or mission.completed:
            gated_problems.update(mission.problem_ids)

    # Sort dormant problems by severity so critical/high surface first when cap is tight
    dormant = sorted(
        (p for p in problems.values() if p.state == ProblemState.DORMANT),
        key=lambda p: _SEVERITY_PRIORITY.get(p.severity, 9),
    )

    for prob in dormant:
        if active_count >= 3:
            break
        if prob.severity == "critical" and critical_count >= 1:
            continue
        if mission_system_active and prob.id not in gated_problems:
            continue

        if prob.visibility == "obvious":
            _activate(prob, factory, newly_active)
            active_count += 1
            if prob.severity == "critical":
                critical_count += 1

        elif prob.visibility == "subtle" and prob.zone_id in inspected_zones:
            _activate(prob, factory, newly_active)
            active_count += 1
            if prob.severity == "critical":
                critical_count += 1

        # hidden: gated by mission system and maturity (Phase 5/6)

    return newly_active


def _activate(prob: Problem, factory, newly_active: List[str]) -> None:
    prob.state = ProblemState.ACTIVE
    prob.first_seen_day = factory.time.day
    newly_active.append(prob.id)
