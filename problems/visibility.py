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

    for prob in problems.values():
        if prob.state != ProblemState.DORMANT:
            continue

        if prob.visibility == "obvious":
            _activate(prob, factory, newly_active)

        elif prob.visibility == "subtle":
            if prob.zone_id in inspected_zones:
                _activate(prob, factory, newly_active)

        elif prob.visibility == "hidden":
            # Hidden problems require maturity engine (Phase 4). Kept dormant until then.
            pass

    return newly_active


def _activate(prob: Problem, factory, newly_active: List[str]) -> None:
    prob.state = ProblemState.ACTIVE
    prob.first_seen_day = factory.time.day
    newly_active.append(prob.id)
