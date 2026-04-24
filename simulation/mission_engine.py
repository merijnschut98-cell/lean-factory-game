"""
MissionsMixin — all mission trigger and activation logic.

Separated from factory.py to keep each file focused.
Factory inherits this mixin; no behaviour change.
"""
from __future__ import annotations

from typing import Optional


class MissionsMixin:

    @property
    def active_mission_count(self) -> int:
        return sum(1 for m in self.missions.values() if m.active and not m.completed)

    def _check_mission_triggers(self) -> None:
        count = self.active_mission_count
        for mission in self.missions.values():
            if mission.active or mission.completed:
                continue
            if count >= 2:
                break
            if mission.visible_after:
                prereq = self.missions.get(mission.visible_after)
                if not (prereq and prereq.completed):
                    continue
            if self._mission_trigger_met(mission):
                mission.active = True
                count += 1

    def _mission_trigger_met(self, mission) -> bool:
        t = mission.trigger
        if t.type == "auto":
            return True
        if t.type == "day":
            return self.time.day >= t.after_day
        if t.type == "kpi":
            val = {"oee": self.live_oee, "ftr": self.last_day_ftr,
                   "wip": float(self.live_wip)}.get(t.metric, 0.0)
            return val >= t.threshold if t.direction == "gte" else val <= t.threshold
        if t.type == "npc":
            return False
        if t.type == "inspect":
            return any(e["entity"].startswith(t.zone_id) for e in self.inspection_log)
        return False

    def trigger_npc_mission(self, npc_role: str) -> Optional[str]:
        if self.active_mission_count >= 2:
            return None
        for mission in self.missions.values():
            if mission.active or mission.completed:
                continue
            if mission.trigger.type != "npc" or mission.trigger.npc_role != npc_role:
                continue
            if mission.visible_after:
                prereq = self.missions.get(mission.visible_after)
                if not (prereq and prereq.completed):
                    continue
            mission.active = True
            return mission.id
        return None

    def active_mission_hint(self) -> str:
        for mission in self.missions.values():
            if mission.active and not mission.completed:
                return mission.current_hint
        return ""
