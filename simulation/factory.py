"""
Factory — top-level aggregator and simulation orchestrator.

Countermeasure logic: simulation.countermeasure_engine (CountermeasuresMixin)
Mission logic:        simulation.mission_engine (MissionsMixin)
"""
from __future__ import annotations

import random
from typing import Dict, List, Optional

from config.constants import (
    STATION_DEFINITIONS, OPERATOR_DEFINITIONS, STATION_FLOW_ORDER,
    SHIFTS_PER_DAY,
)
from simulation.station              import Station
from simulation.operator             import Operator
from simulation.flow                 import MaterialFlow
from simulation.time_engine          import TimeEngine
from simulation.countermeasure_engine import CountermeasuresMixin
from simulation.mission_engine        import MissionsMixin
from simulation.specialist            import Specialist, ZONE_SPECIALIST, SPECIALIST_COST
from problems.catalog                 import load_all
from problems.visibility              import evaluate_visibility
from problems.problem                 import Problem, ProblemState
from problems.countermeasure          import CountermeasureCatalog
from problems.dialogue                import InvestigationSession
from problems.mission                 import Mission, load_all_missions
from maturity.maturity_engine         import MaturityEngine


class DaySnapshot:
    """Plant-level metrics snapshot at end of a simulated day."""
    def __init__(self) -> None:
        self.day:       int   = 0
        self.output:    int   = 0
        self.plant_oee: float = 0.0
        self.total_wip: int   = 0
        self.ftr:       float = 0.0
        self.on_time:   float = 0.0


class Factory(CountermeasuresMixin, MissionsMixin):

    def __init__(self) -> None:
        self.stations:  Dict[str, Station]  = {}
        self.operators: Dict[str, Operator] = {}
        self.flow:      Optional[MaterialFlow] = None
        self.time:      TimeEngine = TimeEngine()

        self.credits:          int   = 0
        self.session_cost_eur: float = 0.0
        # Recovery mode: triggered when credits hit 0. Rollbacks are free and
        # a HUD banner frames the week as a learning reset, not a punishment.
        self.recovery_mode:         bool = False
        self.recovery_started_day:  Optional[int] = None
        self.day_history:      List[DaySnapshot] = []
        self.problems:         Dict[str, Problem] = {}
        self.inspection_log:   List[dict] = []
        self.maturity:         MaturityEngine = MaturityEngine()
        self.cm_catalog:       CountermeasureCatalog = CountermeasureCatalog()
        # cm_id → {zone_id, eff_multiplier, applied_day, decay_days, avail_d, perf_d, qual_d}
        self.active_countermeasures:  Dict[str, dict] = {}
        self.investigation_sessions:  Dict[str, InvestigationSession] = {}
        self.discovered_concepts:     set = set()
        self.circuit_breaker_events:  List[dict] = []
        self._active_problem_cap_reached: bool = False
        self._critical_cap_reached:       bool = False
        self.missions:    Dict[str, Mission]    = load_all_missions()
        self.specialists: Dict[str, Specialist] = {}

        self._daily_output: int = 0
        self._daily_rework: int = 0
        self._daily_scrap:  int = 0

        self._build_stations()
        self._build_operators()
        self._build_flow()
        self._wire_events()
        self._load_problems()
        self.cm_catalog.load()

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
        valid_order = [sid for sid in STATION_FLOW_ORDER if sid in self.stations]
        self.flow = MaterialFlow(valid_order)

    def _wire_events(self) -> None:
        self.time.on("on_tick",      self._on_tick)
        self.time.on("on_shift_end", self._on_shift_end)
        self.time.on("on_day_end",   self._on_day_end)

    def _load_problems(self) -> None:
        self.problems = load_all()
        self._check_mission_triggers()
        evaluate_visibility(self.problems, self)
        for prob in self.active_problems.values():
            self._apply_problem_modifiers(prob)

    # ── Simulation callbacks ──────────────────────────────────────────────────

    def _on_tick(self, sim_dt: float) -> None:
        shift_elapsed = self.time.shift_elapsed
        for op in self.operators.values():
            op.tick(sim_dt, shift_elapsed)
        for st in self.stations.values():
            completed = st.tick(sim_dt)
            if st.id == "packaging":
                self._daily_output += completed
            st._sample_wip()
        self.flow.propagate_all(self.stations)
        self._inject_incoming(sim_dt)

    def _inject_incoming(self, sim_dt: float) -> None:
        dock = self.stations.get("dock")
        if dock and dock.wip_in < 10 and self.live_wip < 80 and random.random() < sim_dt / 5400.0:
            dock.wip_in += 1

    def _on_shift_end(self, day: int, shift: int) -> None:
        for op in self.operators.values():
            if op.shift == shift:
                op.shift_reset()

    def _on_day_end(self, day: int) -> None:
        snap        = DaySnapshot()
        snap.day    = day
        snap.output = self._daily_output

        oee_sum = wip_total = qual_good = qual_total = 0
        for st in self.stations.values():
            m           = st.end_of_day_snapshot()
            oee_sum    += m.oee
            wip_total  += st.wip_in + st.wip_out
            qual_good  += m.units_completed
            qual_total += m.units_completed + m.units_reworked + m.units_scrapped

        snap.plant_oee = round(oee_sum / len(self.stations), 4) if self.stations else 0.0
        snap.total_wip = wip_total
        snap.ftr       = round(qual_good / qual_total, 4) if qual_total > 0 else 1.0
        self.day_history.append(snap)

        self._daily_output = self._daily_rework = self._daily_scrap = 0

        self._tick_decay()
        self.maturity.update(self)
        self._check_mission_triggers()
        self._check_circuit_breakers()
        self._check_recovery_state()
        self._reevaluate_visibility()

    def _reevaluate_visibility(self) -> None:
        newly_active = evaluate_visibility(self.problems, self)
        for pid in newly_active:
            self._apply_problem_modifiers(self.problems[pid])

    # ── Investigation helpers ─────────────────────────────────────────────────

    def get_or_create_session(self, problem_id: str) -> Optional[InvestigationSession]:
        prob = self.problems.get(problem_id)
        if not prob or not prob.dialogue or not prob.dialogue.investigation:
            return None
        if problem_id not in self.investigation_sessions:
            self.investigation_sessions[problem_id] = InvestigationSession(problem_id=problem_id)
        return self.investigation_sessions[problem_id]

    def discover(self, tags) -> set:
        if not tags:
            return set()
        new = set(tags) - self.discovered_concepts
        self.discovered_concepts.update(tags)
        return new

    def log_inspection(self, entity_id: str, metric: str) -> None:
        self.inspection_log.append({"entity": entity_id, "metric": metric, "day": self.time.day})
        newly_active = evaluate_visibility(self.problems, self)
        for pid in newly_active:
            self._apply_problem_modifiers(self.problems[pid])
        station_id = entity_id.split(":")[-1] if ":" in entity_id else entity_id
        for prob in self.active_problems.values():
            if prob.station_id == station_id:
                self.discover(prob.teaches)

    def recent_inspections(self, n: int = 5) -> List[dict]:
        return self.inspection_log[-n:]

    # ── Circuit breakers ──────────────────────────────────────────────────────

    def _check_circuit_breakers(self) -> None:
        if self.live_wip > 100 and not self.time.paused:
            if self.time._speed_index > 1:
                self.time.set_speed(1)
            self._add_circuit_event("wip_ceiling", "Lines backing up — simulation slowed to 1×.")

        active = list(self.active_problems.values())
        self._active_problem_cap_reached = len(active) >= 3
        self._critical_cap_reached = sum(1 for p in active if p.severity == "critical") >= 1

        if self.live_oee < 0.20:
            worst = min(self.stations.values(), key=lambda s: s.oee)
            self._add_circuit_event("oee_floor", f"Critical OEE on {worst.name} — check immediately.")

        # Guard > 0.0 skips day 1 when last_day_ftr is not yet computed (defaults to 0.0).
        if self.last_day_ftr < 0.60 and self.last_day_ftr > 0.0:
            if not self.time.paused and self.time._speed_index > 1:
                self.time.set_speed(1)
            self._add_circuit_event(
                "ftr_floor",
                "Too many failures reaching Final QA — slowed to 1× while defect rate is critical.",
            )

    def _add_circuit_event(self, event_type: str, message: str) -> None:
        self.circuit_breaker_events.append(
            {"type": event_type, "day": self.time.day, "message": message}
        )
        if len(self.circuit_breaker_events) > 50:
            self.circuit_breaker_events = self.circuit_breaker_events[-50:]

    def _check_recovery_state(self) -> None:
        if not self.recovery_mode and self.credits <= 0:
            self.recovery_mode = True
            self.recovery_started_day = self.time.day
            self._add_circuit_event(
                "recovery_begin",
                "Back to basics — credit balance hit zero. Rollbacks are free this week. "
                "Try the obvious fixes first; it's a learning reset, not a failure.",
            )
        elif self.recovery_mode:
            days_in_recovery = self.time.day - (self.recovery_started_day or self.time.day)
            if self.credits >= 150 or days_in_recovery >= 7:
                self.recovery_mode = False
                self.recovery_started_day = None
                self._add_circuit_event(
                    "recovery_end",
                    "Recovery week complete. You're back on your feet — keep going.",
                )

    # ── Specialist hiring ─────────────────────────────────────────────────────

    def hire_specialist(self, zone_id: str) -> dict:
        if zone_id not in ZONE_SPECIALIST:
            return {"success": False, "reason": "No specialist available for this zone."}
        if zone_id in self.specialists:
            return {"success": False, "reason": "A specialist is already hired for this zone."}
        if self.credits < SPECIALIST_COST:
            return {"success": False, "reason": f"Not enough credits (need {SPECIALIST_COST})."}
        specialist = Specialist.for_zone(zone_id, self.time.day)
        self.specialists[zone_id] = specialist
        self.credits -= SPECIALIST_COST
        self._apply_specialist_modifiers(zone_id, specialist)
        return {"success": True, "reason": ""}

    def _apply_specialist_modifiers(self, zone_id: str, specialist: Specialist) -> None:
        for st in self.stations.values():
            if st.zone_id == zone_id:
                st.apply_modifier(specialist.avail_bonus, specialist.perf_bonus, specialist.qual_bonus)

    # ── KPI properties ────────────────────────────────────────────────────────

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
        return self.day_history[-1].output if self.day_history else 0

    @property
    def last_day_ftr(self) -> float:
        return self.day_history[-1].ftr if self.day_history else 0.0

    @property
    def active_problems(self) -> Dict[str, Problem]:
        return {pid: p for pid, p in self.problems.items()
                if p.state != ProblemState.DORMANT}

    # ── Advance simulation ────────────────────────────────────────────────────

    def tick(self, real_dt: float) -> None:
        self.time.tick(real_dt)

    def run_headless(self, days: int = 1) -> None:
        from config.constants import DAY_DURATION, SIM_SECONDS_PER_REAL_SECOND
        target_sim_time = self.time.sim_time + DAY_DURATION * days
        tick_real = 30.0 / SIM_SECONDS_PER_REAL_SECOND
        while self.time.sim_time < target_sim_time:
            self.time.tick(tick_real)

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
            "problems":               {pid: p.to_save_dict() for pid, p in self.problems.items()},
            "active_countermeasures": dict(self.active_countermeasures),
            "inspection_log":         list(self.inspection_log),
            "maturity":               self.maturity.to_dict(),
            "investigation_sessions": {pid: s.to_dict() for pid, s in self.investigation_sessions.items()},
            "discovered_concepts":    sorted(self.discovered_concepts),
            "missions":               {mid: m.to_save_dict() for mid, m in self.missions.items()},
            "specialists":            {zid: s.to_dict() for zid, s in self.specialists.items()},
            "recovery_mode":          self.recovery_mode,
            "recovery_started_day":   self.recovery_started_day,
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
        self.credits          = d.get("credits", 0)
        self.session_cost_eur = d.get("session_cost_eur", 0.0)
        for snap_d in d.get("day_history", []):
            s           = DaySnapshot()
            s.day       = snap_d["day"]
            s.output    = snap_d["output"]
            s.plant_oee = snap_d["oee"]
            s.total_wip = snap_d["wip"]
            s.ftr       = snap_d["ftr"]
            self.day_history.append(s)
        for pid, state_d in d.get("problems", {}).items():
            if pid in self.problems:
                self.problems[pid].restore_runtime_state(state_d)
        self.active_countermeasures = d.get("active_countermeasures", {})
        self.inspection_log         = d.get("inspection_log", [])
        if d.get("maturity"):
            self.maturity.from_dict(d["maturity"])
        for pid, s_d in d.get("investigation_sessions", {}).items():
            self.investigation_sessions[pid] = InvestigationSession.from_dict(s_d)
        self.discovered_concepts = set(d.get("discovered_concepts", []))
        for mid, state_d in d.get("missions", {}).items():
            if mid in self.missions:
                self.missions[mid].restore_runtime_state(state_d)
        for zid, spec_d in d.get("specialists", {}).items():
            specialist = Specialist.from_dict(spec_d)
            self.specialists[zid] = specialist
            self._apply_specialist_modifiers(zid, specialist)
        self.recovery_mode        = d.get("recovery_mode", False)
        self.recovery_started_day = d.get("recovery_started_day")
