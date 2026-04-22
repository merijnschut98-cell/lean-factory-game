"""Problem model — loaded from YAML, state machine managed per instance."""
from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional


class ProblemState(str, Enum):
    DORMANT          = "dormant"
    ACTIVE           = "active"
    UNDER_INVESTIGATION = "investigating"
    COUNTERMEASURE_APPLIED = "cm_applied"
    RESOLVED         = "resolved"
    REGRESSED        = "regressed"


@dataclass
class Problem:
    id:                  str
    name:                str
    category:            str
    severity:            str   # low / medium / high / critical
    visibility:          str   # obvious / subtle / hidden
    zone_id:             str
    station_id:          str
    symptoms:            List[str]
    root_cause:          str
    effective_countermeasures: List[str]
    maturity_prerequisite: Optional[str]
    mismatch_note:       str
    side_effect_ref:     Optional[str]
    effect_modifiers:    Dict[str, float]

    state: ProblemState = ProblemState.DORMANT
    investigation_log: List[dict] = field(default_factory=list)
    applied_countermeasure: Optional[str] = None
    score: Optional[dict] = None
    first_seen_day: Optional[int] = None
    solved_day: Optional[int] = None

    @classmethod
    def from_dict(cls, d: dict) -> "Problem":
        return cls(
            id=d["id"],
            name=d["name"],
            category=d.get("category", ""),
            severity=d.get("severity", "medium"),
            visibility=d.get("visibility", "obvious"),
            zone_id=d.get("zone_id", ""),
            station_id=d.get("station_id", ""),
            symptoms=d.get("symptoms", []),
            root_cause=d.get("root_cause", ""),
            effective_countermeasures=d.get("effective_countermeasures", []),
            maturity_prerequisite=d.get("maturity_prerequisite"),
            mismatch_note=d.get("mismatch_note", ""),
            side_effect_ref=d.get("side_effect_ref"),
            effect_modifiers=d.get("effect_modifiers", {}),
        )
