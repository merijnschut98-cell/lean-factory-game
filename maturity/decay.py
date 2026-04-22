"""Countermeasure decay logic — Phase 4 stub."""
from __future__ import annotations
from typing import Dict


class DecayTracker:
    def __init__(self) -> None:
        self._applied: Dict[str, dict] = {}   # cm_id → {day_applied, decay_days, current_eff}

    def register(self, cm_id: str, day: int, initial_eff: float, decay_days: int | None) -> None:
        self._applied[cm_id] = {
            "day_applied": day,
            "decay_days":  decay_days,
            "current_eff": initial_eff,
        }

    def update(self, current_day: int) -> list:
        """Returns list of cm_ids that have fully decayed."""
        decayed = []
        for cm_id, info in self._applied.items():
            if info["decay_days"] is None:
                continue
            days_elapsed = current_day - info["day_applied"]
            if days_elapsed >= info["decay_days"]:
                info["current_eff"] = 0.0
                decayed.append(cm_id)
            elif days_elapsed > 0:
                fraction = days_elapsed / info["decay_days"]
                info["current_eff"] = max(0.0, 1.0 - fraction) * info.get("initial_eff", 1.0)
        return decayed
