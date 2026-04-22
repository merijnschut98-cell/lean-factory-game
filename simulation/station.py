"""
Station model.

Each station processes one unit at a time.  While processing:
  - availability governs random stoppages (breakdowns, changeovers)
  - performance governs cycle-time elongation
  - quality governs first-time-right rate at this step

OEE = availability × performance × quality (all 0–1).
"""
from __future__ import annotations

import random
from dataclasses import dataclass
from typing import List, Optional

from simulation.operator import Operator, OperatorState


@dataclass
class StationMetrics:
    """Rolling snapshot updated each simulated day."""
    oee:              float = 0.0
    availability:     float = 0.0
    performance:      float = 0.0
    quality:          float = 0.0
    units_completed:  int   = 0
    units_reworked:   int   = 0
    units_scrapped:   int   = 0
    cycle_time_avg:   float = 0.0
    wip_in_avg:       float = 0.0


class Station:
    def __init__(
        self,
        id:                   str,
        name:                 str,
        zone_id:              str,
        zone_name:            str,
        station_type:         str,
        target_cycle_time:    float,    # seconds/unit at full efficiency
        base_availability:    float,
        base_performance:     float,
        base_quality:         float,
        operator_count:       int,
        starting_wip_in:      int = 0,
    ) -> None:
        self.id            = id
        self.name          = name
        self.zone_id       = zone_id
        self.zone_name     = zone_name
        self.station_type  = station_type

        self.target_cycle_time  = target_cycle_time
        self.base_availability  = base_availability
        self.base_performance   = base_performance
        self.base_quality       = base_quality
        self.operator_count     = operator_count

        # Runtime state
        self.wip_in:  int = starting_wip_in
        self.wip_out: int = 0

        self._processing:       bool  = False
        self._time_in_cycle:    float = 0.0
        self._current_ct:       float = 0.0   # actual CT for the unit being processed
        self._stopped:          bool  = False  # unplanned stop active?
        self._stop_timer:       float = 0.0
        self._stop_duration:    float = 0.0

        # Problem / countermeasure modifiers (additive deltas applied to base)
        self._avail_delta:      float = 0.0
        self._perf_delta:       float = 0.0
        self._quality_delta:    float = 0.0

        # Operators assigned to this station (set by factory.py)
        self.operators: List[Operator] = []

        # Daily accumulators (reset each day)
        self._acc_available_time: float = 0.0
        self._acc_run_time:       float = 0.0
        self._acc_ideal_time:     float = 0.0
        self._acc_good_units:     int   = 0
        self._acc_total_units:    int   = 0
        self._acc_rework:         int   = 0
        self._acc_scrap:          int   = 0
        self._acc_ct_sum:         float = 0.0
        self._acc_wip_samples:    List[float] = []

        # Rolling window of completed cycle times (last 20) for Time Observation diagnostic
        self.ct_history:          List[float] = []

        # Published snapshot
        self.metrics = StationMetrics(
            availability=base_availability,
            performance=base_performance,
            quality=base_quality,
            oee=base_availability * base_performance * base_quality,
        )

    # ── Effective parameters ──────────────────────────────────────────────────

    @property
    def availability(self) -> float:
        return max(0.05, min(1.0, self.base_availability + self._avail_delta))

    @property
    def performance(self) -> float:
        return max(0.05, min(1.0, self.base_performance + self._perf_delta))

    @property
    def quality(self) -> float:
        return max(0.05, min(1.0, self.base_quality + self._quality_delta))

    @property
    def oee(self) -> float:
        return self.availability * self.performance * self.quality

    @property
    def current_cycle_time(self) -> float:
        """Expected actual CT given current performance and operator skill."""
        op_mod = self._operator_performance_modifier()
        return self.target_cycle_time / (self.performance * op_mod)

    # ── Operator helpers ──────────────────────────────────────────────────────

    def _operator_performance_modifier(self) -> float:
        active = [
            op for op in self.operators
            if op.state not in (OperatorState.ON_BREAK, OperatorState.TROUBLESHOOTING)
        ]
        if not active:
            return 0.5
        mods = [op.performance_modifier(self.station_type) for op in active]
        return sum(mods) / len(mods)

    # ── Tick ─────────────────────────────────────────────────────────────────

    def tick(self, dt: float) -> int:
        """
        Advance by dt simulated seconds.
        Returns number of units pushed to wip_out this tick.
        """
        self._acc_available_time += dt
        completed = 0

        # Handle unplanned stop
        if self._stopped:
            self._stop_timer += dt
            if self._stop_timer >= self._stop_duration:
                self._stopped = False
            return 0

        # P(no stop in dt) = availability^(dt/CT) — step-size independent
        p_stop = 1.0 - self.availability ** (dt / max(1.0, self.target_cycle_time))
        if random.random() < p_stop:
            self._stopped = True
            self._stop_timer = 0.0
            self._stop_duration = random.uniform(60, self.target_cycle_time * 0.5)
            return 0

        self._acc_run_time += dt

        # Start a new unit if idle and input available
        if not self._processing and self.wip_in > 0:
            self.wip_in -= 1
            self._processing = True
            self._time_in_cycle = 0.0
            self._current_ct = max(
                self.target_cycle_time * 0.7,
                self.current_cycle_time * random.uniform(0.85, 1.15),
            )
            self._acc_ideal_time += self.target_cycle_time

        # Advance current unit
        if self._processing:
            self._time_in_cycle += dt
            if self._time_in_cycle >= self._current_ct:
                self._processing = False
                self._acc_total_units += 1
                self._acc_ct_sum += self._current_ct
                self.ct_history.append(round(self._current_ct, 1))
                if len(self.ct_history) > 20:
                    self.ct_history.pop(0)

                # Quality check
                if random.random() < self.quality:
                    self.wip_out += 1
                    self._acc_good_units += 1
                    completed += 1
                else:
                    # 70% chance rework (stays in system, goes back to wip_in),
                    # 30% chance scrap
                    if random.random() < 0.70:
                        self.wip_in += 1      # rework loop
                        self._acc_rework += 1
                    else:
                        self._acc_scrap += 1

        return completed

    # ── Daily reset and metric snapshot ──────────────────────────────────────

    def end_of_day_snapshot(self) -> StationMetrics:
        """Compute OEE metrics from daily accumulators and reset them."""
        avail = (
            (self._acc_run_time / self._acc_available_time)
            if self._acc_available_time > 0 else self.availability
        )
        perf = (
            (self._acc_ideal_time / self._acc_run_time)
            if self._acc_run_time > 0 else self.performance
        )
        qual = (
            (self._acc_good_units / self._acc_total_units)
            if self._acc_total_units > 0 else self.quality
        )
        oee = avail * perf * qual

        avg_ct = (
            (self._acc_ct_sum / self._acc_total_units)
            if self._acc_total_units > 0 else self.current_cycle_time
        )

        self.metrics = StationMetrics(
            oee=round(oee, 4),
            availability=round(avail, 4),
            performance=round(perf, 4),
            quality=round(qual, 4),
            units_completed=self._acc_good_units,
            units_reworked=self._acc_rework,
            units_scrapped=self._acc_scrap,
            cycle_time_avg=round(avg_ct, 1),
            wip_in_avg=round(sum(self._acc_wip_samples) / max(1, len(self._acc_wip_samples)), 1),
        )

        # Reset accumulators
        self._acc_available_time = 0.0
        self._acc_run_time       = 0.0
        self._acc_ideal_time     = 0.0
        self._acc_good_units     = 0
        self._acc_total_units    = 0
        self._acc_rework         = 0
        self._acc_scrap          = 0
        self._acc_ct_sum         = 0.0
        self._acc_wip_samples    = []

        return self.metrics

    def _sample_wip(self) -> None:
        """Called periodically by factory to record WIP samples."""
        self._acc_wip_samples.append(float(self.wip_in))

    # ── Problem / countermeasure interface ────────────────────────────────────

    def apply_modifier(self, avail_delta: float = 0.0, perf_delta: float = 0.0, quality_delta: float = 0.0) -> None:
        self._avail_delta  += avail_delta
        self._perf_delta   += perf_delta
        self._quality_delta += quality_delta

    def remove_modifier(self, avail_delta: float = 0.0, perf_delta: float = 0.0, quality_delta: float = 0.0) -> None:
        self._avail_delta  -= avail_delta
        self._perf_delta   -= perf_delta
        self._quality_delta -= quality_delta

    # ── Serialisation ─────────────────────────────────────────────────────────

    def to_dict(self) -> dict:
        return {
            "id":             self.id,
            "wip_in":         self.wip_in,
            "wip_out":        self.wip_out,
            "avail_delta":    self._avail_delta,
            "perf_delta":     self._perf_delta,
            "quality_delta":  self._quality_delta,
            "metrics": {
                "oee":             self.metrics.oee,
                "availability":    self.metrics.availability,
                "performance":     self.metrics.performance,
                "quality":         self.metrics.quality,
                "units_completed": self.metrics.units_completed,
                "units_reworked":  self.metrics.units_reworked,
                "units_scrapped":  self.metrics.units_scrapped,
                "cycle_time_avg":  self.metrics.cycle_time_avg,
                "wip_in_avg":      self.metrics.wip_in_avg,
            },
        }

    def from_dict(self, d: dict) -> None:
        self.wip_in          = d.get("wip_in", self.wip_in)
        self.wip_out         = d.get("wip_out", 0)
        self._avail_delta    = d.get("avail_delta", 0.0)
        self._perf_delta     = d.get("perf_delta", 0.0)
        self._quality_delta  = d.get("quality_delta", 0.0)
        m = d.get("metrics", {})
        if m:
            self.metrics = StationMetrics(
                oee=m.get("oee", self.oee),
                availability=m.get("availability", self.availability),
                performance=m.get("performance", self.performance),
                quality=m.get("quality", self.quality),
                units_completed=m.get("units_completed", 0),
                units_reworked=m.get("units_reworked", 0),
                units_scrapped=m.get("units_scrapped", 0),
                cycle_time_avg=m.get("cycle_time_avg", self.current_cycle_time),
                wip_in_avg=m.get("wip_in_avg", 0.0),
            )
