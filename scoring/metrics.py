"""
Six-metric scoring (spec §8.1). All deterministic math — no AI.

Metrics (each 1–5, max total 30):
  DQQ  Diagnostic Question Quality
  EI   Evidence Integration
  RCA  Root Cause Accuracy
  CMP  Countermeasure Practicality
  LM   Lean Maturity
  CIM  Continuous Improvement Mindset
"""
from __future__ import annotations
from typing import List

from config.constants import CREDIT_BASE

# CM category groupings for EI scoring (quality of evidence vs. CM type)
_QUALITY_CATEGORIES = frozenset({"quality", "maintenance"})
_FLOW_CATEGORIES    = frozenset({"flow", "flow_analysis"})
_PEOPLE_CATEGORIES  = frozenset({"people", "management_system"})


def score_dqq(inspection_log: List[dict], problem_zone_id: str) -> int:
    """
    Breadth and depth of investigation before applying a countermeasure.

    5 — 5+ unique entities inspected, at least one diagnostic tool used,
        and both the problem zone and an adjacent zone covered
    3 — 3–4 entities inspected in the correct zone, no diagnostic tool
    1 — fewer than 3 entities, or only the most obvious station inspected
    """
    unique_entities = {e["entity"] for e in inspection_log}
    zones_inspected = {e["entity"].split(":")[0] for e in inspection_log}
    tools_used = any(e.get("metric", "").startswith("diagnostic") for e in inspection_log)

    if len(unique_entities) >= 5 and tools_used and len(zones_inspected) >= 2:
        return 5
    elif len(unique_entities) >= 3 and problem_zone_id in zones_inspected:
        return 3
    return 1


def score_ei(inspection_log: List[dict], applied_cm_category: str) -> int:
    """
    Evidence Integration — was the countermeasure grounded in observed data?

    We approximate EI by checking whether the CM's category matches
    the types of metrics the player actually inspected.

    5 — player inspected quality/OEE/WIP metrics consistent with the CM category
    3 — player inspected the correct zone but with limited metric variety
    1 — player inspected very little before applying
    """
    observed_metrics = {e.get("metric", "") for e in inspection_log}
    unique_entities = len({e["entity"] for e in inspection_log})

    metric_match = (
        (applied_cm_category in _QUALITY_CATEGORIES and "quality" in observed_metrics)
        or (applied_cm_category in _FLOW_CATEGORIES and any(
            m in observed_metrics for m in {"oee", "wip", "cycle_time"}))
        or (applied_cm_category in _PEOPLE_CATEGORIES and "oee" in observed_metrics)
        or applied_cm_category not in (_QUALITY_CATEGORIES | _FLOW_CATEGORIES | _PEOPLE_CATEGORIES)
    )

    if unique_entities >= 4 and metric_match:
        return 5
    elif unique_entities >= 2:
        return 3
    return 1


def score_rca(applied_cm_id: str, problem) -> int:
    """
    Root Cause Accuracy — does the countermeasure choice reveal correct diagnosis?

    The countermeasure the player chose implicitly reveals their root cause hypothesis.
    If they chose from the problem's effective list, they diagnosed correctly.

    5 — applied CM is in the problem's effective_countermeasures list
    3 — applied CM is in the same tier as an effective CM (adjacent understanding)
    1 — applied CM has no relationship to the problem's root cause
    """
    if applied_cm_id in problem.effective_countermeasures:
        return 5

    # Check if the CM name keyword-matches any effective CM name
    effective_set = {cm.lower() for cm in problem.effective_countermeasures}
    applied_words = set(applied_cm_id.lower().replace("-", " ").split())
    for eff in effective_set:
        eff_words = set(eff.lower().replace("-", " ").split())
        if applied_words & eff_words:
            return 3

    return 1


def score_cmp(applied_cm_id: str, problem, zone_maturity: float, cm_zone_id: str) -> int:
    """
    Countermeasure Practicality — right tool, right zone.

    5 — CM is in effective list AND zone matches the problem zone
    3 — CM addresses the problem but zone is adjacent, OR CM is in effective list
        but applied to wrong zone
    1 — CM is unrelated to the root cause
    """
    in_effective_list = applied_cm_id in problem.effective_countermeasures
    correct_zone = cm_zone_id == problem.zone_id

    if in_effective_list and correct_zone:
        return 5
    elif in_effective_list or correct_zone:
        return 3
    return 1


def score_lm(cm_tier: int, zone_maturity: float) -> int:
    """
    Lean Maturity — did the player sequence tools appropriately?

    5 — CM tier matches or is one tier above zone maturity (appropriate stretch)
    3 — CM tier is one tier above with mismatch warning acknowledged
    1 — CM tier is two+ tiers above zone maturity (premature application)
    """
    gap = cm_tier - zone_maturity
    if -0.5 <= gap <= 1.0:
        return 5
    elif 1.0 < gap <= 2.0:
        return 3
    return 1


def score_cim(inspection_log: List[dict], problem_station_id: str, applied_day: int) -> int:
    """
    Continuous Improvement Mindset — did the player observe the effect?

    5 — player re-inspected the station AFTER applying the countermeasure
    3 — player inspected the station at some point but not after applying
    1 — no re-inspection at all
    """
    post_apply = any(
        e["entity"].endswith(f":{problem_station_id}")
        and e.get("day", 0) > applied_day
        for e in inspection_log
    )
    any_inspect = any(
        e["entity"].endswith(f":{problem_station_id}")
        for e in inspection_log
    )

    if post_apply:
        return 5
    elif any_inspect:
        return 3
    return 1


def calculate_all(
    inspection_log: List[dict],
    problem,
    applied_cm_id: str,
    applied_cm_tier: int,
    applied_cm_category: str,
    applied_cm_zone_id: str,
    applied_day: int,
    zone_maturity: float,
) -> dict:
    """Run all six metrics and return {metric_name: score}."""
    return {
        "DQQ": score_dqq(inspection_log, problem.zone_id),
        "EI":  score_ei(inspection_log, applied_cm_category),
        "RCA": score_rca(applied_cm_id, problem),
        "CMP": score_cmp(applied_cm_id, problem, zone_maturity, applied_cm_zone_id),
        "LM":  score_lm(applied_cm_tier, zone_maturity),
        "CIM": score_cim(inspection_log, problem.station_id, applied_day),
    }


def total_score(scores: dict) -> int:
    return sum(scores.values())


def credits_earned(total: int, severity: str) -> int:
    base = CREDIT_BASE.get(severity, 150)
    return round((total / 30) * base)


# ── Score explanations ───────────────────────────────────────────────────────
# One short line per metric matching its achieved tier (1/3/5). Shown under
# the score bars on the resolve panel so the player learns *why* they got
# that score — not just the number.

def _explain_dqq(score: int, unique_entities: int, zones: int) -> str:
    if score == 5:
        return f"Strong investigation — {unique_entities} entities across {zones} zones, diagnostic tool used."
    if score == 3:
        return f"Partial investigation — {unique_entities} entities, single zone. Try diagnostic tools next time."
    return f"Too little gemba work — only {unique_entities} entities inspected before acting."


def _explain_ei(score: int, unique_entities: int, cm_category: str) -> str:
    if score == 5:
        return f"Evidence matched the {cm_category} countermeasure — {unique_entities} entities with relevant metrics."
    if score == 3:
        return "Some data collected, but not enough variety to ground the countermeasure choice."
    return "Almost no observation before applying — the choice wasn't backed by evidence."


def _explain_rca(score: int) -> str:
    if score == 5:
        return "Countermeasure is in the problem's effective list — diagnosis was correct."
    if score == 3:
        return "Countermeasure is related but not the best fit — adjacent understanding."
    return "Countermeasure is unrelated to the root cause — diagnosis missed the mark."


def _explain_cmp(score: int, in_effective: bool, correct_zone: bool) -> str:
    if score == 5:
        return "Right tool applied in the right zone — full practicality."
    if score == 3 and in_effective:
        return "Right countermeasure, but applied to the wrong zone — reduced impact."
    elif score == 3 and correct_zone:
        return "Right zone, but the countermeasure doesn't address the root cause — reduced impact."
    return "Wrong tool in the wrong zone — no practical match."


def _explain_lm(score: int, cm_tier: int, zone_maturity: float) -> str:
    gap = cm_tier - zone_maturity
    if score == 5:
        return f"Tier {cm_tier} CM on a Tier {zone_maturity:.1f} zone — appropriate stretch."
    if score == 3:
        return f"Tier {cm_tier} CM on a Tier {zone_maturity:.1f} zone — one tier ahead of maturity."
    return f"Tier {cm_tier} CM on a Tier {zone_maturity:.1f} zone — applied too early in the journey."


def _explain_cim(score: int) -> str:
    if score == 5:
        return "Re-inspected the station after applying — closed the PDCA Check loop."
    if score == 3:
        return "Station was inspected at some point, but not after applying the fix."
    return "No re-inspection after applying — the effect was never verified."


def explain_scores(
    scores: dict,
    inspection_log: List[dict],
    problem,
    applied_cm_id: str,
    applied_cm_tier: int,
    applied_cm_category: str,
    applied_cm_zone_id: str,
    zone_maturity: float,
) -> dict:
    unique_entities = len({e["entity"] for e in inspection_log})
    zones           = len({e["entity"].split(":")[0] for e in inspection_log})
    in_effective    = applied_cm_id in problem.effective_countermeasures
    correct_zone    = applied_cm_zone_id == problem.zone_id
    return {
        "DQQ": _explain_dqq(scores["DQQ"], unique_entities, zones),
        "EI":  _explain_ei(scores["EI"], unique_entities, applied_cm_category),
        "RCA": _explain_rca(scores["RCA"]),
        "CMP": _explain_cmp(scores["CMP"], in_effective, correct_zone),
        "LM":  _explain_lm(scores["LM"], applied_cm_tier, zone_maturity),
        "CIM": _explain_cim(scores["CIM"]),
    }
