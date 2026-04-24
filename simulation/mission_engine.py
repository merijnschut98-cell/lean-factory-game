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
            # Always evaluate — the sticky flag inside `_mission_trigger_met`
            # must track KPI crossings that happen before the prereq completes.
            trigger_met = self._mission_trigger_met(mission)
            if count >= 2:
                break
            if mission.visible_after:
                prereq = self.missions.get(mission.visible_after)
                if not (prereq and prereq.completed):
                    continue
            if trigger_met:
                mission.active = True
                count += 1

    def _mission_trigger_met(self, mission) -> bool:
        t = mission.trigger
        currently_met = False
        if t.type == "auto":
            currently_met = True
        elif t.type == "day":
            currently_met = self.time.day >= t.after_day
        elif t.type == "kpi":
            val = {"oee": self.live_oee, "ftr": self.last_day_ftr,
                   "wip": float(self.live_wip)}.get(t.metric, 0.0)
            currently_met = val >= t.threshold if t.direction == "gte" else val <= t.threshold
        elif t.type == "inspect":
            currently_met = any(e["entity"].startswith(t.zone_id) for e in self.inspection_log)

        if currently_met:
            mission.trigger_ever_met = True
        return mission.trigger_ever_met

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
