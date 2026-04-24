"""
Factory — top-level aggregator.

Owns all stations, operators, and the material-flow graph.
Wires the time engine to per-station ticks and shift/day events.
Exposes plant-level KPI properties that the HUD reads.
"""
from __future__ import annotations

import random
from typing import Dict, List, Optional

from config.constants import (
    STATION_DEFINITIONS, OPERATOR_DEFINITIONS, STATION_FLOW_ORDER,
    SHIFTS_PER_DAY, CREDIT_BASE,
)
from simulation.station     import Station
from simulation.operator    import Operator
from simulation.flow        import MaterialFlow
from simulation.time_engine import TimeEngine
from problems.catalog         import load_all
from problems.visibility      import evaluate_visibility
from problems.problem         import Problem, ProblemState
from problems.countermeasure  import CountermeasureCatalog
from problems.dialogue        import InvestigationSession
from problems.mission         import Mission, load_all_missions
from maturity.maturity_engine import MaturityEngine
from maturity.mismatch        import effectiveness_multiplier


# Per-category station modifier baselines (avail, perf, qual) at eff_mult=1.0.
# These are scaled by eff_mult at apply time.
_CM_CATEGORY_MODIFIERS: dict = {
    "workplace_organization":  (0.02, 0.06, 0.03),
    "process_standardization": (0.02, 0.07, 0.05),
    "quality":                 (0.01, 0.02, 0.10),
    "visual_management":       (0.01, 0.05, 0.02),
    "maintenance":             (0.09, 0.04, 0.02),
    "flow":                    (0.02, 0.08, 0.02),
    "flow_analysis":           (0.01, 0.04, 0.02),
    "problem_solving":         (0.02, 0.04, 0.05),
    "management_system":       (0.03, 0.05, 0.03),
    "people":                  (0.02, 0.06, 0.03),
    "information":             (0.01, 0.03, 0.04),
    "improvement_events":      (0.03, 0.06, 0.04),
    "coaching":                (0.01, 0.03, 0.02),
    "safety":                  (0.04, 0.02, 0.02),
}
_CM_DEFAULT_MODIFIERS = (0.04, 0.04, 0.03)


def _cm_modifiers(category: str, eff_mult: float) -> tuple[float, float, float]:
    """Return (avail_delta, perf_delta, qual_delta) scaled by effectiveness multiplier."""
    a, p, q = _CM_CATEGORY_MODIFIERS.get(category, _CM_DEFAULT_MODIFIERS)
    return a * eff_mult, p * eff_mult, q * eff_mult


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
        self.problems:          Dict[str, Problem] = {}
        self.inspection_log:    List[dict] = []
        self.maturity:          MaturityEngine = MaturityEngine()
        self.cm_catalog:        CountermeasureCatalog = CountermeasureCatalog()
        # cm_id → {zone_id, eff_multiplier, applied_day, decay_days, avail_d, perf_d, qual_d}
        self.active_countermeasures: Dict[str, dict] = {}
        # problem_id → InvestigationSession (Phase 5 learning fork tracking)
        self.investigation_sessions: Dict[str, InvestigationSession] = {}
        # Concepts the player has encountered (teaches: tags from problems, forks, CMs)
        self.discovered_concepts: set = set()
        # Circuit breaker flags and event log
        self.circuit_breaker_events: List[dict] = []
        self._active_problem_cap_reached: bool = False
        self._critical_cap_reached: bool = False
        # Mission system
        self.missions: Dict[str, Mission] = load_all_missions()

        # Running plant-level totals (reset each day)
        self._daily_output:  int   = 0
        self._daily_rework:  int   = 0
        self._daily_scrap:   int   = 0

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
        # Only include stations that exist
        valid_order = [sid for sid in STATION_FLOW_ORDER if sid in self.stations]
        self.flow = MaterialFlow(valid_order)

    def _wire_events(self) -> None:
        self.time.on("on_tick",        self._on_tick)
        self.time.on("on_shift_end",   self._on_shift_end)
        self.time.on("on_day_end",     self._on_day_end)

    def _load_problems(self) -> None:
        self.problems = load_all()
        self._check_mission_triggers()   # activate auto/day-0 missions before first visibility pass
        evaluate_visibility(self.problems, self)
        for prob in self.active_problems.values():
            self._apply_problem_modifiers(prob)

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
        """Trickle raw materials into dock, gated by total WIP cap to prevent unbounded growth."""
        dock = self.stations.get("dock")
        if dock and dock.wip_in < 10 and self.live_wip < 80 and random.random() < sim_dt / 5400.0:
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

        self._tick_decay()
        self.maturity.update(self)
        self._check_mission_triggers()
        self._check_circuit_breakers()
        newly_active = evaluate_visibility(self.problems, self)
        for pid in newly_active:
            self._apply_problem_modifiers(self.problems[pid])

    def _apply_problem_modifiers(self, prob: Problem) -> None:
        st = self.stations.get(prob.station_id)
        if st and prob.effect_modifiers:
            st.apply_modifier(
                avail_delta=prob.effect_modifiers.get("avail_delta", 0.0),
                perf_delta=prob.effect_modifiers.get("perf_delta", 0.0),
                quality_delta=prob.effect_modifiers.get("quality_delta", 0.0),
            )

    def _remove_problem_modifiers(self, prob: Problem) -> None:
        st = self.stations.get(prob.station_id)
        if st and prob.effect_modifiers:
            st.remove_modifier(
                avail_delta=prob.effect_modifiers.get("avail_delta", 0.0),
                perf_delta=prob.effect_modifiers.get("perf_delta", 0.0),
                quality_delta=prob.effect_modifiers.get("quality_delta", 0.0),
            )

    def get_or_create_session(self, problem_id: str) -> Optional[InvestigationSession]:
        """Return existing session, or create one if the problem has a dialogue fork."""
        prob = self.problems.get(problem_id)
        if not prob or not prob.dialogue or not prob.dialogue.investigation:
            return None
        if problem_id not in self.investigation_sessions:
            self.investigation_sessions[problem_id] = InvestigationSession(problem_id=problem_id)
        return self.investigation_sessions[problem_id]

    def discover(self, tags) -> set:
        """Add concept tags; returns the set of concepts newly discovered this call."""
        if not tags:
            return set()
        new = set(tags) - self.discovered_concepts
        self.discovered_concepts.update(tags)
        return new

    def log_inspection(self, entity_id: str, metric: str) -> None:
        """Record a player inspection and immediately check for newly visible problems."""
        self.inspection_log.append({"entity": entity_id, "metric": metric, "day": self.time.day})
        newly_active = evaluate_visibility(self.problems, self)
        for pid in newly_active:
            self._apply_problem_modifiers(self.problems[pid])
        # Discover concepts from active problems at the inspected station
        station_id = entity_id.split(":")[-1] if ":" in entity_id else entity_id
        for prob in self.active_problems.values():
            if prob.station_id == station_id:
                self.discover(prob.teaches)

    def recent_inspections(self, n: int = 5) -> List[dict]:
        return self.inspection_log[-n:]

    # ── Countermeasure application ────────────────────────────────────────────

    def apply_countermeasure(self, problem_id: str, cm_id: str) -> dict:
        """
        Apply a countermeasure to a problem's station.
        Returns a result dict with keys: success, eff_multiplier, warning, side_effect_id.
        """
        prob = self.problems.get(problem_id)
        cm   = self.cm_catalog.get(cm_id)
        if not prob or not cm:
            return {"success": False, "error": "Unknown problem or countermeasure"}

        zone_maturity = self.maturity.zone_maturity(prob.zone_id)
        eff_mult = effectiveness_multiplier(cm.tier_int, zone_maturity)

        # Side-effect: harmful tier triggers a linked problem.
        # Suppressed when already at the active problem cap — avoids overwhelming the player.
        side_effect_id = None
        if eff_mult == 0.0 and cm.effectiveness and cm.effectiveness.harmful_side_effect_ref:
            side_effect_id = cm.effectiveness.harmful_side_effect_ref
            linked = self.problems.get(side_effect_id)
            if linked and linked.state == ProblemState.DORMANT and not self._active_problem_cap_reached:
                linked.state = ProblemState.ACTIVE
                linked.first_seen_day = self.time.day
                self._apply_problem_modifiers(linked)

        # Scale station modifiers by effectiveness multiplier
        eff = cm.effectiveness
        if eff and self.stations.get(prob.station_id):
            st = self.stations[prob.station_id]
            base_avail, base_perf, base_qual = _cm_modifiers(cm.category, eff_mult)
            st.apply_modifier(avail_delta=base_avail, perf_delta=base_perf,
                              quality_delta=base_qual)
            self.active_countermeasures[cm_id] = {
                "zone_id":      prob.zone_id,
                "station_id":   prob.station_id,
                "eff_mult":     eff_mult,
                "applied_day":  self.time.day,
                "decay_days":   cm.decay_days if cm.decay_enabled else None,
                "avail_d":      base_avail,
                "perf_d":       base_perf,
                "qual_d":       base_qual,
            }

        self.maturity.register_cm(prob.zone_id, cm_id, cm.tier_int)
        prob.applied_countermeasure = cm_id
        prob.state = ProblemState.COUNTERMEASURE_APPLIED
        self.discover(cm.teaches)

        # Track wrong CM applications for soft-punishment ladder (only if player investigated)
        if eff_mult < 0.5:
            session = self.investigation_sessions.get(prob.id)
            if session:
                session.wrong_cm_count += 1

        return {
            "success":        True,
            "eff_multiplier": eff_mult,
            "side_effect_id": side_effect_id,
        }

    def resolve_problem(self, problem_id: str) -> Optional[dict]:
        """
        Score and resolve a problem. Returns score dict, or None if not resolvable.
        """
        from scoring.metrics import calculate_all, total_score, credits_earned

        prob = self.problems.get(problem_id)
        if not prob or prob.state != ProblemState.COUNTERMEASURE_APPLIED:
            return None

        cm_id = prob.applied_countermeasure
        cm    = self.cm_catalog.get(cm_id) if cm_id else None
        cm_record = self.active_countermeasures.get(cm_id, {})

        scores = calculate_all(
            inspection_log    = self.inspection_log,
            problem           = prob,
            applied_cm_id     = cm_id or "",
            applied_cm_tier   = cm.tier_int if cm else 0,
            applied_cm_category = cm.category if cm else "",
            applied_cm_zone_id  = cm_record.get("zone_id", prob.zone_id),
            applied_day       = cm_record.get("applied_day", self.time.day),
            zone_maturity     = self.maturity.zone_maturity(prob.zone_id),
        )

        # Phase 5: +1 boost per correct choice (investigation, 5 Whys, and verification)
        session = self.investigation_sessions.get(problem_id)
        if session:
            all_choices = (
                session.choices_made
                + session.five_whys_choices
                + session.verification_choices
            )
            for choice in all_choices:
                feed = choice.get("score_feed")
                if choice.get("outcome") == "CORRECT" and feed and feed in scores:
                    scores[feed] = min(5, scores[feed] + 1)

        total = total_score(scores)
        earned = credits_earned(total, prob.severity)

        # Soft-punishment: count=2 → 10%, count=3 → 20% (capped at 40%)
        if session and session.wrong_cm_count >= 2:
            penalty = 0.10 * (session.wrong_cm_count - 1)
            earned  = round(earned * max(0.6, 1.0 - min(penalty, 0.40)))

        # Learning Rally bonus — +10% for solving after an initial wrong attempt
        rally_bonus = session.earned_rally_bonus if session else False
        if rally_bonus:
            earned = round(earned * 1.1)

        # PDCA completion bonus — +15% when all four phases complete
        pdca_complete = (
            session is not None
            and session.fork_complete
            and session.verification_complete
            and session.verification_correct
            and session.standardized
        )
        if pdca_complete:
            earned = round(earned * 1.15)

        self.credits += earned
        self._remove_problem_modifiers(prob)
        prob.solved_day = self.time.day
        prob.score = scores
        prob.state = ProblemState.RESOLVED

        # Update mission progress
        for mission in self.missions.values():
            if mission.active and problem_id in mission.problem_ids:
                mission.record_resolved(problem_id)
                mission.advance_hint()

        return {"scores": scores, "total": total, "credits_earned": earned,
                "rally_bonus": rally_bonus, "pdca_complete": pdca_complete}

    @property
    def follow_up_due_stations(self) -> set:
        """Station IDs where a CM has been active >= 3 days — PDCA Check phase due."""
        due: set = set()
        for rec in self.active_countermeasures.values():
            if self.time.day - rec.get("applied_day", self.time.day) >= 3:
                due.add(rec["station_id"])
        return due

    def standardize_cm(self, problem_id: str) -> bool:
        """Lock CM benefit permanently (disables decay). Returns True on success."""
        prob = self.problems.get(problem_id)
        if not prob or not prob.applied_countermeasure:
            return False
        cm_id = prob.applied_countermeasure
        if cm_id in self.active_countermeasures:
            self.active_countermeasures[cm_id]["decay_days"] = None
        session = self.investigation_sessions.get(problem_id)
        if session:
            session.standardized = True
        return True

    def adjust_verification(self, problem_id: str) -> bool:
        """Reset verification so the player can observe again (PDCA Adjust). Returns True on success."""
        session = self.investigation_sessions.get(problem_id)
        if not session or not session.verification_complete:
            return False
        session.verification_complete = False
        session.verification_choices = []
        return True

    @property
    def active_mission_count(self) -> int:
        return sum(1 for m in self.missions.values() if m.active and not m.completed)

    def _check_mission_triggers(self) -> None:
        """Activate missions whose trigger conditions are now met (max 2 active at once)."""
        count = self.active_mission_count
        for mission in self.missions.values():
            if mission.active or mission.completed:
                continue
            if count >= 2:
                break
            # Prerequisite gate: visible_after must be completed first
            if mission.visible_after:
                prereq = self.missions.get(mission.visible_after)
                if not (prereq and prereq.completed):
                    continue
            if self._mission_trigger_met(mission):
                mission.active = True
                count += 1

    def _mission_trigger_met(self, mission: Mission) -> bool:
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
        """Called when player talks to an NPC. Activates any pending NPC-triggered mission."""
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
        """Returns the current hint from the highest-priority active mission."""
        for mission in self.missions.values():
            if mission.active and not mission.completed:
                return mission.current_hint
        return ""

    def _check_circuit_breakers(self) -> None:
        """Simulation safety nets — record events and slow simulation. No station mutation."""
        # WIP ceiling: auto-slow to 1× when WIP > 100
        if self.live_wip > 100 and not self.time.paused:
            if self.time._speed_index > 1:
                self.time.set_speed(1)
            self._add_circuit_event("wip_ceiling", "Lines backing up — simulation slowed to 1×.")

        # Update caps for visibility.py to read
        active = list(self.active_problems.values())
        self._active_problem_cap_reached = len(active) >= 3
        self._critical_cap_reached = sum(1 for p in active if p.severity == "critical") >= 1

        # OEE floor: record event for NPC notification (no station mutation — avoids accumulation)
        if self.live_oee < 0.20:
            worst = min(self.stations.values(), key=lambda s: s.oee)
            self._add_circuit_event("oee_floor", f"Critical OEE on {worst.name} — check immediately.")

        # FTR floor: too many defects reaching Final QA — slow and log.
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

    def rollback_countermeasure(self, problem_id: str) -> Optional[dict]:
        """
        Undo an applied countermeasure. Costs 25% of base credit for this severity.
        Re-activates the problem so the player can try a different approach.
        Returns None if the problem has no CM applied.
        """
        prob = self.problems.get(problem_id)
        if not prob or prob.state != ProblemState.COUNTERMEASURE_APPLIED:
            return None

        cm_id = prob.applied_countermeasure
        rec   = self.active_countermeasures.pop(cm_id, {})

        st = self.stations.get(rec.get("station_id", prob.station_id))
        if st:
            st.remove_modifier(rec.get("avail_d", 0.0),
                               rec.get("perf_d",  0.0),
                               rec.get("qual_d",  0.0))

        if rec.get("zone_id"):
            self.maturity.remove_cm(rec["zone_id"], cm_id or "")

        penalty = round(CREDIT_BASE.get(prob.severity, 150) * 0.25)
        self.credits = max(0, self.credits - penalty)

        prob.state = ProblemState.ACTIVE
        prob.applied_countermeasure = None
        self._apply_problem_modifiers(prob)
        self.investigation_sessions.pop(problem_id, None)

        return {"penalty_paid": penalty, "problem_id": problem_id}

    def _tick_decay(self) -> None:
        """Reduce effectiveness of decaying countermeasures each day."""
        decayed = []
        for cm_id, rec in self.active_countermeasures.items():
            if rec["decay_days"] is None:
                continue
            days_active = self.time.day - rec["applied_day"]
            if days_active >= rec["decay_days"]:
                st = self.stations.get(rec["station_id"])
                if st:
                    st.remove_modifier(rec["avail_d"], rec["perf_d"], rec["qual_d"])
                self.maturity.remove_cm(rec["zone_id"], cm_id)
                decayed.append(cm_id)
        for cm_id in decayed:
            del self.active_countermeasures[cm_id]

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

    @property
    def active_problems(self) -> Dict[str, Problem]:
        return {
            pid: p for pid, p in self.problems.items()
            if p.state != ProblemState.DORMANT
        }

    # ── Advance simulation (called by game loop) ───────────────────────────────

    def tick(self, real_dt: float) -> None:
        self.time.tick(real_dt)

    # ── Headless run (Phase 1 testing) ────────────────────────────────────────

    def run_headless(self, days: int = 1) -> None:
        """Run the factory for N simulated days and print metrics."""
        from config.constants import DAY_DURATION, SIM_SECONDS_PER_REAL_SECOND
        target_sim_time = self.time.sim_time + DAY_DURATION * days

        # 30 sim-seconds per step: precise enough for shortest CT (600 s)
        # while keeping step count manageable (~2880/day).
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
        for pid, state_d in d.get("problems", {}).items():
            if pid in self.problems:
                self.problems[pid].restore_runtime_state(state_d)
        self.active_countermeasures = d.get("active_countermeasures", {})
        self.inspection_log = d.get("inspection_log", [])
        if d.get("maturity"):
            self.maturity.from_dict(d["maturity"])
        for pid, s_d in d.get("investigation_sessions", {}).items():
            self.investigation_sessions[pid] = InvestigationSession.from_dict(s_d)
        self.discovered_concepts = set(d.get("discovered_concepts", []))
        for mid, state_d in d.get("missions", {}).items():
            if mid in self.missions:
                self.missions[mid].restore_runtime_state(state_d)
