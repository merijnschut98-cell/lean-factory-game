"""Problem model — loaded from YAML, state machine managed per instance."""
from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional


class ProblemState(str, Enum):
    DORMANT                = "dormant"
    ACTIVE                 = "active"
    UNDER_INVESTIGATION    = "investigating"
    COUNTERMEASURE_APPLIED = "cm_applied"
    RESOLVED               = "resolved"
    REGRESSED              = "regressed"


@dataclass
class Problem:
    # ── YAML-derived (static) ────────────────────────────────────────────────
    id:                        str
    name:                      str
    category:                  str
    severity:                  str   # low / medium / high / critical
    visibility:                str   # obvious / subtle / hidden
    zone_id:                   str
    station_id:                str
    symptoms:                  List[str]
    root_cause:                str
    effective_countermeasures: List[str]
    maturity_prerequisite:     Optional[str]
    mismatch_note:             str
    side_effect_ref:           Optional[str]
    effect_modifiers:          Dict[str, float]

    # Phase 5: learning tags and authored dialogue forks
    teaches:  List[str] = field(default_factory=list)
    dialogue: Optional["problems.dialogue.ProblemDialogue"] = field(default=None)

    # ── Runtime state (serialised on save) ───────────────────────────────────
    state:                   ProblemState = ProblemState.DORMANT
    investigation_log:       List[dict]   = field(default_factory=list)
    applied_countermeasure:  Optional[str] = None
    score:                   Optional[dict] = None
    first_seen_day:          Optional[int] = None
    solved_day:              Optional[int] = None

    @classmethod
    def from_dict(cls, d: dict) -> "Problem":
        from problems.dialogue import parse_dialogue
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
            teaches=list(d.get("teaches") or []),
            dialogue=parse_dialogue(d.get("dialogue")),
        )

    # ── Serialisation of runtime state only ──────────────────────────────────

    def to_save_dict(self) -> dict:
        """Return only the mutable runtime state — not YAML-derived fields."""
        return {
            "id":                      self.id,
            "state":                   self.state.value,
            "investigation_log":       self.investigation_log,
            "applied_countermeasure":  self.applied_countermeasure,
            "score":                   self.score,
            "first_seen_day":          self.first_seen_day,
            "solved_day":              self.solved_day,
        }

    def restore_runtime_state(self, d: dict) -> None:
        """Overwrite mutable fields from a save dict. YAML fields stay intact."""
        self.state                  = ProblemState(d.get("state", self.state.value))
        self.investigation_log      = d.get("investigation_log", [])
        self.applied_countermeasure = d.get("applied_countermeasure")
        self.score                  = d.get("score")
        self.first_seen_day         = d.get("first_seen_day")
        self.solved_day             = d.get("solved_day")
