"""
Simulation clock.

Tracks simulated time (in seconds from the start of Day 1 Shift 1).
Emits events: on_shift_start, on_shift_end, on_day_end.
"""
from __future__ import annotations
from typing import Callable, Dict, List

from config.constants import (
    SHIFT_DURATION, SHIFTS_PER_DAY, DAY_DURATION,
    SIM_SECONDS_PER_REAL_SECOND, SPEED_MULTIPLIERS,
)


class TimeEngine:
    def __init__(self, speed_index: int = 1) -> None:
        self._sim_time:     float = 0.0   # total simulated seconds elapsed
        self._speed_index:  int   = speed_index
        self._paused:       bool  = False

        # Event callbacks: name → list of callables
        self._listeners: Dict[str, List[Callable]] = {
            "on_shift_start": [],
            "on_shift_end":   [],
            "on_day_end":     [],
            "on_tick":        [],
        }

        self._last_day   = 0
        self._last_shift = 0

    # ── Clock properties ──────────────────────────────────────────────────────

    @property
    def sim_time(self) -> float:
        return self._sim_time

    @property
    def day(self) -> int:
        return int(self._sim_time // DAY_DURATION) + 1

    @property
    def shift(self) -> int:
        elapsed_in_day = self._sim_time % DAY_DURATION
        return int(elapsed_in_day // SHIFT_DURATION) + 1

    @property
    def shift_elapsed(self) -> float:
        return self._sim_time % SHIFT_DURATION

    @property
    def paused(self) -> bool:
        return self._paused

    @property
    def speed_label(self) -> str:
        if self._paused:
            return "⏸"
        return f"{SPEED_MULTIPLIERS[self._speed_index]}×"

    # ── Control ───────────────────────────────────────────────────────────────

    def pause(self) -> None:
        self._paused = True

    def resume(self) -> None:
        self._paused = False

    def toggle_pause(self) -> None:
        self._paused = not self._paused

    def set_speed(self, index: int) -> None:
        self._speed_index = max(0, min(len(SPEED_MULTIPLIERS) - 1, index))

    def cycle_speed(self) -> None:
        """Cycle through 1× → 2× → 4× → 8× → pause → 1×."""
        if self._paused:
            self._paused = False
            self._speed_index = 1
        else:
            next_idx = self._speed_index + 1
            if next_idx >= len(SPEED_MULTIPLIERS):
                self._paused = True
            else:
                self._speed_index = next_idx

    # ── Tick ─────────────────────────────────────────────────────────────────

    def tick(self, real_dt: float) -> float:
        """
        Advance simulation by real_dt real-world seconds.
        Returns the number of simulated seconds advanced.
        """
        if self._paused or SPEED_MULTIPLIERS[self._speed_index] == 0:
            return 0.0

        sim_dt = real_dt * SIM_SECONDS_PER_REAL_SECOND * SPEED_MULTIPLIERS[self._speed_index]
        prev_sim = self._sim_time
        self._sim_time += sim_dt

        # Fire events for any crossed boundaries
        self._fire_boundary_events(prev_sim, self._sim_time)

        for cb in self._listeners["on_tick"]:
            cb(sim_dt)

        return sim_dt

    def _fire_boundary_events(self, prev: float, curr: float) -> None:
        prev_day   = int(prev  // DAY_DURATION) + 1
        curr_day   = int(curr  // DAY_DURATION) + 1

        prev_shift_abs = int(prev  // SHIFT_DURATION)
        curr_shift_abs = int(curr  // SHIFT_DURATION)

        for shift_abs in range(prev_shift_abs, curr_shift_abs):
            day_of   = (shift_abs // SHIFTS_PER_DAY) + 1
            shift_no = (shift_abs  % SHIFTS_PER_DAY) + 1
            # Shift just ended at boundary
            for cb in self._listeners["on_shift_end"]:
                cb(day_of, shift_no)
            # Next shift starts
            next_shift = (shift_no % SHIFTS_PER_DAY) + 1
            next_day   = day_of if next_shift != 1 else day_of + 1
            for cb in self._listeners["on_shift_start"]:
                cb(next_day, next_shift)

        if curr_day > prev_day:
            for day in range(prev_day, curr_day):
                for cb in self._listeners["on_day_end"]:
                    cb(day)

    # ── Event registration ────────────────────────────────────────────────────

    def on(self, event: str, callback: Callable) -> None:
        self._listeners[event].append(callback)

    # ── Serialisation ─────────────────────────────────────────────────────────

    def to_dict(self) -> dict:
        return {
            "sim_time":    self._sim_time,
            "speed_index": self._speed_index,
            "paused":      self._paused,
        }

    def from_dict(self, d: dict) -> None:
        self._sim_time    = d.get("sim_time", 0.0)
        self._speed_index = d.get("speed_index", 1)
        self._paused      = d.get("paused", False)

    # ── Display helpers ───────────────────────────────────────────────────────

    def format_clock(self) -> str:
        elapsed_in_shift = self.shift_elapsed
        h = int(elapsed_in_shift // 3600)
        m = int((elapsed_in_shift % 3600) // 60)
        return f"Day {self.day}  Shift {self.shift}  {h:02d}:{m:02d}"
