"""
Zone maturity score (1.0–5.0 per zone, matching the Lean Six Sigma Academy tiers).

Score composition (each component capped so total stays 1.0–5.0):
  Base:                 1.0  (always — factory exists)
  Tier 1 CMs active:   up to +1.0  (fully equipped T1 zone → 2.0)
  Tier 2 CMs active:   up to +1.0  (→ 3.0)
  Tier 3 CMs active:   up to +1.0  (→ 4.0)
  Tier 4 CMs active:   up to +1.0  (→ 5.0)

CMs are registered by the countermeasure system (Phase 4) via `register_cm`.
Until Phase 4 wires countermeasures in, all zones stay at 1.0.
"""
from __future__ import annotations
from typing import Dict, List, Tuple


ZONES = ["z1", "z2", "z3", "z4", "z5", "z6"]

# CMs per tier (denominator for fraction calculation)
_CMS_PER_TIER = {1: 10, 2: 16, 3: 24, 4: 18}


class MaturityEngine:
    def __init__(self) -> None:
        self.scores: Dict[str, float] = {z: 1.0 for z in ZONES}
        self._active_cms: Dict[str, List[Tuple[int, str]]] = {z: [] for z in ZONES}

    def register_cm(self, zone_id: str, cm_id: str, cm_tier: int) -> None:
        """Called by Phase 4 countermeasure system when a CM is applied."""
        entry = (cm_tier, cm_id)
        if zone_id in self._active_cms and entry not in self._active_cms[zone_id]:
            self._active_cms[zone_id].append(entry)

    def remove_cm(self, zone_id: str, cm_id: str) -> None:
        """Called when a CM decays or is removed."""
        if zone_id in self._active_cms:
            self._active_cms[zone_id] = [
                (t, cid) for (t, cid) in self._active_cms[zone_id] if cid != cm_id
            ]

    def update(self, factory) -> None:
        """Recalculate zone scores from active countermeasures."""
        for zone_id in ZONES:
            cms = self._active_cms[zone_id]
            score = 1.0
            for tier in (1, 2, 3, 4):
                count = sum(1 for (t, _) in cms if t == tier)
                total = _CMS_PER_TIER.get(tier, 1)
                score += min(1.0, count / total)
            self.scores[zone_id] = round(min(5.0, score), 2)

    def zone_maturity(self, zone_id: str) -> float:
        return self.scores.get(zone_id, 1.0)

    def plant_maturity(self) -> float:
        return round(sum(self.scores.values()) / len(self.scores), 2)
