"""Operator model — skill, fatigue, state, shift assignment."""
from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict

from config.constants import (
    FATIGUE_RATE, FATIGUE_RESET_BREAK, FATIGUE_PERF_PENALTY,
    BREAK_DURATION, SHIFT_DURATION,
)


class OperatorState(str, Enum):
    WORKING        = "working"
    WAITING        = "waiting"
    ON_BREAK       = "on_break"
    TROUBLESHOOTING = "troubleshooting"


@dataclass
class Operator:
    id:               str
    name:             str
    home_station_id:  str
    skill_levels:     Dict[str, int]          # station_type → 1-5
    shift:            int                     # 1 / 2 / 3
    fatigue:          float = 0.0             # 0.0–1.0
    state:            OperatorState = OperatorState.WORKING
    current_station_id: str = ""

    # Internal timing
    _break_timer:     float = field(default=0.0, repr=False)
    _next_break_at:   float = field(default=SHIFT_DURATION * 0.4, repr=False)

    def __post_init__(self) -> None:
        if not self.current_station_id:
            self.current_station_id = self.home_station_id

    # ── Performance modifier ──────────────────────────────────────────────────

    def skill_for(self, station_type: str) -> int:
        return self.skill_levels.get(station_type, 1)

    def performance_modifier(self, station_type: str) -> float:
        """
        Returns a multiplier 0.5–1.15 applied to station performance.
        Skill 5 → +15 %, skill 1 → −40 %, modified downward by fatigue.
        """
        skill = self.skill_for(station_type)
        skill_mod = {1: 0.60, 2: 0.80, 3: 1.00, 4: 1.10, 5: 1.15}[skill]
        fatigue_penalty = self.fatigue * FATIGUE_PERF_PENALTY
        return max(0.30, skill_mod - fatigue_penalty)

    # ── State machine ─────────────────────────────────────────────────────────

    def tick(self, dt: float, shift_elapsed: float) -> None:
        """Advance operator state by dt simulated seconds."""
        if self.state == OperatorState.ON_BREAK:
            self._break_timer += dt
            if self._break_timer >= BREAK_DURATION:
                self._end_break()
            return

        if self.state == OperatorState.WORKING:
            self.fatigue = min(1.0, self.fatigue + FATIGUE_RATE * dt)
            if shift_elapsed >= self._next_break_at and self.fatigue > 0.3:
                self._start_break()

    def _start_break(self) -> None:
        self.state = OperatorState.ON_BREAK
        self._break_timer = 0.0

    def _end_break(self) -> None:
        self.fatigue = max(0.0, self.fatigue - FATIGUE_RESET_BREAK)
        self._next_break_at += SHIFT_DURATION * 0.35
        self.state = OperatorState.WORKING

    def shift_reset(self) -> None:
        """Called at shift boundary."""
        self.fatigue = 0.0
        self.state = OperatorState.WORKING
        self._break_timer = 0.0
        self._next_break_at = SHIFT_DURATION * 0.4

    # ── Serialisation ─────────────────────────────────────────────────────────

    def to_dict(self) -> dict:
        return {
            "id":                 self.id,
            "name":               self.name,
            "home_station_id":    self.home_station_id,
            "skill_levels":       self.skill_levels,
            "shift":              self.shift,
            "fatigue":            self.fatigue,
            "state":              self.state.value,
            "current_station_id": self.current_station_id,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Operator":
        o = cls(
            id=d["id"],
            name=d["name"],
            home_station_id=d["home_station_id"],
            skill_levels=d["skill_levels"],
            shift=d["shift"],
            fatigue=d.get("fatigue", 0.0),
            state=OperatorState(d.get("state", "working")),
            current_station_id=d.get("current_station_id", d["home_station_id"]),
        )
        return o
