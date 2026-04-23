"""
Mission system — thematic problem clusters that gate problem visibility.

Missions are the discovery layer: problems only surface when their parent
mission is active. Each mission is triggered by talking to an NPC, observing
a KPI threshold, or after a certain number of in-game days.

No timers. No deadlines. Urgency comes from the factory gradually degrading
while problems go unresolved — never from a countdown.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import yaml


@dataclass
class MissionTrigger:
    type: str               # "npc" | "kpi" | "day" | "inspect" | "auto"
    npc_role: str = ""      # for type "npc": role name that must be interacted with
    metric: str = ""        # for type "kpi": "oee" | "ftr" | "wip"
    threshold: float = 0.0  # for type "kpi": trigger value
    direction: str = "lte"  # for type "kpi": "lte" (<=) or "gte" (>=)
    after_day: int = 0      # for type "day": trigger after this many in-game days
    zone_id: str = ""       # for type "inspect": trigger after player inspects zone


@dataclass
class Mission:
    id: str
    title: str
    description: str        # narrative briefing shown when mission starts
    source_npc: str         # NPC role that delivers the briefing
    trigger: MissionTrigger
    problem_ids: List[str]  # problems gated behind this mission
    hints: List[str]        # progressive hints — one surfaces at a time via NPC ambient
    completion_condition: str = "any"       # "any" = solve at least one; "all" = solve all
    visible_after: Optional[str] = None    # mission ID that must be completed first

    # Runtime state (serialised)
    active: bool    = False
    completed: bool = False
    hint_index: int = 0
    problems_resolved: List[str] = field(default_factory=list)

    def record_resolved(self, problem_id: str) -> None:
        """Record that a problem in this mission was resolved."""
        if problem_id in self.problem_ids and problem_id not in self.problems_resolved:
            self.problems_resolved.append(problem_id)
            self.completed = self.is_complete

    @property
    def is_complete(self) -> bool:
        if self.completion_condition == "any":
            return bool(self.problems_resolved)
        return all(pid in self.problems_resolved for pid in self.problem_ids)

    @property
    def current_hint(self) -> str:
        if self.hints and self.hint_index < len(self.hints):
            return self.hints[self.hint_index]
        return ""

    def advance_hint(self) -> None:
        if self.hint_index < len(self.hints) - 1:
            self.hint_index += 1

    def to_save_dict(self) -> dict:
        return {
            "id":                self.id,
            "active":            self.active,
            "completed":         self.completed,
            "hint_index":        self.hint_index,
            "problems_resolved": list(self.problems_resolved),
        }

    def restore_runtime_state(self, d: dict) -> None:
        self.active            = d.get("active", False)
        self.completed         = d.get("completed", False)
        self.hint_index        = d.get("hint_index", 0)
        self.problems_resolved = d.get("problems_resolved", [])


# ── YAML loading ──────────────────────────────────────────────────────────────

_MISSIONS_PATH = Path(__file__).parent.parent / "data" / "missions_tier1.yaml"


def load_missions(path: Path = _MISSIONS_PATH) -> Dict[str, Mission]:
    if not path.exists():
        return {}
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict) or "missions" not in raw:
        return {}
    result: Dict[str, Mission] = {}
    for entry in raw["missions"]:
        mission = _parse_mission(entry)
        result[mission.id] = mission
    return result


def _parse_mission(raw: dict) -> Mission:
    trig_raw = raw.get("trigger", {})
    trigger  = MissionTrigger(
        type      = str(trig_raw.get("type", "auto")),
        npc_role  = str(trig_raw.get("npc_role", "")),
        metric    = str(trig_raw.get("metric", "")),
        threshold = float(trig_raw.get("threshold", 0.0)),
        direction = str(trig_raw.get("direction", "lte")),
        after_day = int(trig_raw.get("after_day", 0)),
        zone_id   = str(trig_raw.get("zone_id", "")),
    )
    return Mission(
        id                   = str(raw["id"]),
        title                = str(raw["title"]),
        description          = str(raw.get("description", "")),
        source_npc           = str(raw.get("source_npc", "")),
        trigger              = trigger,
        problem_ids          = list(raw.get("problem_ids", [])),
        hints                = list(raw.get("hints", [])),
        completion_condition = str(raw.get("completion_condition", "any")),
        visible_after        = raw.get("visible_after") or None,
    )
