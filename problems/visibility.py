"""Problem visibility logic — Phase 3 stub."""
from __future__ import annotations
from typing import List
from problems.problem import Problem, ProblemState


def evaluate_visibility(problems: dict, factory) -> List[str]:
    """
    Check dormant problems and activate any whose visibility conditions are met.
    Returns list of newly-activated problem IDs.
    Phase 3: implement full prerequisite checking against factory maturity.
    """
    newly_active = []
    for prob in problems.values():
        if prob.state != ProblemState.DORMANT:
            continue
        if prob.visibility == "obvious" and prob.maturity_prerequisite is None:
            prob.state = ProblemState.ACTIVE
            prob.first_seen_day = factory.time.day
            newly_active.append(prob.id)
    return newly_active
