"""
Factory — top-level aggregator.

Owns all stations, operators, and the material-flow graph.
Wires the time engine to per-station ticks and shift/day events.
Exposes plant-level KPI properties that the HUD reads.
"""
from __future__ import annotations

from typing import Dict, List, Optional

from config.constants import (
    STATION_DEFINITIONS, OPERATOR_DEFINITIONS, STATION_FLOW_ORDER,
    SHIFTS_PER_DAY,
)
from simulation.station   import Station
from simulation.operator  import Operator
from simulation.flow      import MaterialFlow
from simulation.time_engine import TimeEngine


class DaySnapshot:
    """Plant-level metrics snapshot at end of a simulated day."""
    def __init__(self) -> None:
        self.day:           int   = 0
        self.output:        int   = 0    # hoverboards completed
        self.plant_oee:     float = 0.0
        self.total_wip:     int   = 0
        self.ftr:           float = 0.0
        self.on_time:       float = 0.0


class Factory:
    def __init__(self) -> None:
        self.stations:  Dict[str, Station]  = {}
        self.operators: Dict[str, Operator] = {}
        self.flow:      Optional[MaterialFlow] = None
        self.time:      TimeEngine = TimeEngine()

        self.credits:           int   = 0
        self.session_cost_eur:  float = 0.0
        self.day_history:       List[DaySnapshot] = []

        # Running plant-level totals (reset each day)
        self._daily_output:  int   = 0
        self._daily_rework:  int   = 0
        self._daily_scrap:   int   = 0

        self._build_stations()
        self._build_operators()
        self._build_flow()
        self._wire_events()

    # ── Construction ──────────────────────────────────────────────────────────

    def _build_stations(self) -> None:
        for defn in STATION_DEFINITIONS:
            (sid, name, zone_id, zone_name, stype,
             ct, avail, perf, qual, ops, wip_in) = defn
            st = Station(
                id=sid, name=name, zone_id=zone_id, zone_name=zone_name,
                station_type=stype, target_cycle_time=ct,
                base_availability=avail, base_performance=perf,
                base_quality=qual, operator_count=ops,
                starting_wip_in=wip_in,
            )
            self.stations[sid] = st

    def _build_operators(self) -> None:
        for defn in OPERATOR_DEFINITIONS:
            oid, name, home, shift, skills = defn
            op = Operator(id=oid, name=name, home_station_id=home,
                          skill_levels=skills, shift=shift)
            self.operators[oid] = op
            if home in self.stations:
                self.stations[home].operators.append(op)

    def _build_flow(self) -> None:
        # Only include stations that exist
        valid_order = [sid for sid in STATION_FLOW_ORDER if sid in self.stations]
        self.flow = MaterialFlow(valid_order)

    def _wire_events(self) -> None:
        self.time.on("on_tick",        self._on_tick)
        self.time.on("on_shift_end",   self._on_shift_end)
        self.time.on("on_day_end",     self._on_day_end)

    # ── Simulation callbacks ──────────────────────────────────────────────────

    def _on_tick(self, sim_dt: float) -> None:
        shift_elapsed = self.time.shift_elapsed

        # Tick all operators
        for op in self.operators.values():
            op.tick(sim_dt, shift_elapsed)

        # Tick all stations; accumulate output
        for st in self.stations.values():
            completed = st.tick(sim_dt)
            if st.id == "packaging":
                self._daily_output += completed
            st._sample_wip()

        # Propagate flow
        self.flow.propagate_all(self.stations)

        # Inject new units at dock based on delivery cadence
        self._inject_incoming(sim_dt)

    def _inject_incoming(self, sim_dt: float) -> None:
        """
        Push raw materials into the dock at a rate sufficient to keep the factory fed.
        Deliveries arrive in batches (T1-006 problem simulation).
        Simplified: constant trickle for Phase 1; batch logic wired later.
        """
        dock = self.stations.get("dock")
        if dock and dock.wip_in < 12:
            # Drip-feed: aim for one new unit every ~4000 sim-seconds at dock
            import random
            if random.random() < sim_dt / 4000.0:
                dock.wip_in += 1

    def _on_shift_end(self, day: int, shift: int) -> None:
        for op in self.operators.values():
            if op.shift == shift:
                op.shift_reset()

    def _on_day_end(self, day: int) -> None:
        snap = DaySnapshot()
        snap.day    = day
        snap.output = self._daily_output

        oee_sum = 0.0
        wip_total = 0
        qual_good  = 0
        qual_total = 0

        for st in self.stations.values():
            m = st.end_of_day_snapshot()
            oee_sum    += m.oee
            wip_total  += st.wip_in + st.wip_out
            qual_good  += m.units_completed
            qual_total += m.units_completed + m.units_reworked + m.units_scrapped

        snap.plant_oee  = round(oee_sum / len(self.stations), 4) if self.stations else 0.0
        snap.total_wip  = wip_total
        snap.ftr        = round(qual_good / qual_total, 4) if qual_total > 0 else 1.0

        self.day_history.append(snap)

        # Reset daily accumulators
        self._daily_output = 0
        self._daily_rework = 0
        self._daily_scrap  = 0

    # ── KPI properties (live, for HUD) ───────────────────────────────────────

    @property
    def live_wip(self) -> int:
        return sum(st.wip_in + st.wip_out for st in self.stations.values())

    @property
    def live_oee(self) -> float:
        if not self.stations:
            return 0.0
        return sum(st.oee for st in self.stations.values()) / len(self.stations)

    @property
    def last_day_output(self) -> int:
        if self.day_history:
            return self.day_history[-1].output
        return 0

    @property
    def last_day_ftr(self) -> float:
        if self.day_history:
            return self.day_history[-1].ftr
        return 0.0

    # ── Advance simulation (called by game loop) ───────────────────────────────

    def tick(self, real_dt: float) -> None:
        self.time.tick(real_dt)

    # ── Headless run (Phase 1 testing) ────────────────────────────────────────

    def run_headless(self, days: int = 1) -> None:
        """Run the factory for N simulated days and print metrics."""
        from config.constants import DAY_DURATION
        target_sim_time = self.time.sim_time + DAY_DURATION * days

        tick_size = 60.0   # 60 real seconds per step → large sim jump
        while self.time.sim_time < target_sim_time:
            self.time.tick(tick_size)

    # ── Serialisation ─────────────────────────────────────────────────────────

    def to_dict(self) -> dict:
        return {
            "time":        self.time.to_dict(),
            "stations":    {sid: st.to_dict()  for sid, st in self.stations.items()},
            "operators":   {oid: op.to_dict()  for oid, op in self.operators.items()},
            "flow":        self.flow.to_dict() if self.flow else {},
            "credits":     self.credits,
            "session_cost_eur": self.session_cost_eur,
            "day_history": [
                {"day": s.day, "output": s.output, "oee": s.plant_oee,
                 "wip": s.total_wip, "ftr": s.ftr}
                for s in self.day_history
            ],
        }

    def from_dict(self, d: dict) -> None:
        self.time.from_dict(d.get("time", {}))
        for sid, st_d in d.get("stations", {}).items():
            if sid in self.stations:
                self.stations[sid].from_dict(st_d)
        for oid, op_d in d.get("operators", {}).items():
            if oid in self.operators:
                self.operators[oid] = Operator.from_dict(op_d)
        if self.flow and d.get("flow"):
            self.flow.from_dict(d["flow"])
        self.credits = d.get("credits", 0)
        self.session_cost_eur = d.get("session_cost_eur", 0.0)
        for snap_d in d.get("day_history", []):
            s = DaySnapshot()
            s.day        = snap_d["day"]
            s.output     = snap_d["output"]
            s.plant_oee  = snap_d["oee"]
            s.total_wip  = snap_d["wip"]
            s.ftr        = snap_d["ftr"]
            self.day_history.append(s)
