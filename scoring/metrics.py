"""
Six-metric scoring — Phase 4 stub.

All scoring is deterministic math; no AI involved.
Metrics: DQQ, EI, RCA, CMP, LM, CIM  (each 1–5, max total 30).
"""
from __future__ import annotations
from typing import Optional


def score_dqq(inspection_log: list) -> int:
    """Diagnostic Question Quality — based on inspection breadth."""
    unique_entities = len({e["entity"] for e in inspection_log})
    tools_used = any("diagnostic" in e.get("metric", "") for e in inspection_log)
    if unique_entities >= 5 and tools_used:
        return 5
    elif unique_entities >= 3:
        return 3
    return 1


def score_ei(inspection_log: list, diagnosis_claims: list) -> int:
    """Evidence Integration — diagnosis cites only observed metrics."""
    observed = {e["metric"] for e in inspection_log}
    claimed  = set(diagnosis_claims)
    unobserved = claimed - observed
    if not unobserved:
        return 5
    elif len(unobserved) <= 1:
        return 3
    return 1


def score_rca(player_root_cause: str, canonical_root_cause: str) -> int:
    """Root Cause Accuracy — exact match = 5, contributing = 3, wrong = 1."""
    # Phase 4: implement semantic matching via keyword lists per problem
    if not player_root_cause:
        return 1
    return 3   # placeholder


def score_cmp(countermeasure_id: str, problem, zone_maturity: float) -> int:
    """Countermeasure Practicality."""
    if countermeasure_id in problem.effective_countermeasures:
        return 5
    return 1


def score_lm(cm_tier: int, zone_maturity: float) -> int:
    """Lean Maturity — tier match vs zone."""
    gap = cm_tier - zone_maturity
    if -0.5 <= gap <= 1.0:
        return 5
    elif 1.0 < gap <= 2.0:
        return 3
    return 1


def score_cim(observed_effect: bool, iterated: bool) -> int:
    """Continuous Improvement Mindset."""
    if observed_effect and iterated:
        return 5
    elif observed_effect:
        return 3
    return 1


def total_score(scores: dict) -> int:
    return sum(scores.values())


def credits_earned(total: int, severity: str) -> int:
    from config.constants import CREDIT_BASE
    base = CREDIT_BASE.get(severity, 150)
    return round((total / 30) * base)
