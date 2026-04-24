"""
CountermeasuresMixin — all countermeasure/resolve/rollback/decay logic.

Separated from factory.py to keep each file focused.
Factory inherits this mixin; no behaviour change.
"""
from __future__ import annotations

from problems.problem import ProblemState

# ── CM category → (avail_delta, perf_delta, qual_delta) baselines ────────────

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
    a, p, q = _CM_CATEGORY_MODIFIERS.get(category, _CM_DEFAULT_MODIFIERS)
    return a * eff_mult, p * eff_mult, q * eff_mult


# ── Mixin ─────────────────────────────────────────────────────────────────────

class CountermeasuresMixin:

    def _apply_problem_modifiers(self, prob) -> None:
        st = self.stations.get(prob.station_id)
        if st and prob.effect_modifiers:
            st.apply_modifier(
                avail_delta=prob.effect_modifiers.get("avail_delta", 0.0),
                perf_delta=prob.effect_modifiers.get("perf_delta", 0.0),
                quality_delta=prob.effect_modifiers.get("quality_delta", 0.0),
            )

    def _remove_problem_modifiers(self, prob) -> None:
        st = self.stations.get(prob.station_id)
        if st and prob.effect_modifiers:
            st.remove_modifier(
                avail_delta=prob.effect_modifiers.get("avail_delta", 0.0),
                perf_delta=prob.effect_modifiers.get("perf_delta", 0.0),
                quality_delta=prob.effect_modifiers.get("quality_delta", 0.0),
            )

    def apply_countermeasure(self, problem_id: str, cm_id: str) -> dict:
        from maturity.mismatch import effectiveness_multiplier
        prob = self.problems.get(problem_id)
        cm   = self.cm_catalog.get(cm_id)
        if not prob or not cm:
            return {"success": False, "error": "Unknown problem or countermeasure"}

        zone_maturity = self.maturity.zone_maturity(prob.zone_id)
        eff_mult = effectiveness_multiplier(cm.tier_int, zone_maturity)

        # Suppressed when already at the active problem cap — avoids overwhelming the player.
        side_effect_id = None
        if eff_mult == 0.0 and cm.effectiveness and cm.effectiveness.harmful_side_effect_ref:
            side_effect_id = cm.effectiveness.harmful_side_effect_ref
            linked = self.problems.get(side_effect_id)
            if linked and linked.state == ProblemState.DORMANT and not self._active_problem_cap_reached:
                linked.state = ProblemState.ACTIVE
                linked.first_seen_day = self.time.day
                self._apply_problem_modifiers(linked)

        eff = cm.effectiveness
        if eff and self.stations.get(prob.station_id):
            st = self.stations[prob.station_id]
            base_avail, base_perf, base_qual = _cm_modifiers(cm.category, eff_mult)
            st.apply_modifier(avail_delta=base_avail, perf_delta=base_perf, quality_delta=base_qual)
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

        if eff_mult < 0.5:
            session = self.investigation_sessions.get(prob.id)
            if session:
                session.wrong_cm_count += 1

        return {"success": True, "eff_multiplier": eff_mult, "side_effect_id": side_effect_id}

    def resolve_problem(self, problem_id: str):
        from scoring.metrics import calculate_all, total_score, credits_earned, explain_scores
        from config.constants import CREDIT_BASE

        prob = self.problems.get(problem_id)
        if not prob or prob.state != ProblemState.COUNTERMEASURE_APPLIED:
            return None

        cm_id     = prob.applied_countermeasure
        cm        = self.cm_catalog.get(cm_id) if cm_id else None
        cm_name   = cm.name if cm else ""
        cm_record = self.active_countermeasures.get(cm_id, {})

        scores = calculate_all(
            inspection_log      = self.inspection_log,
            problem             = prob,
            applied_cm_name     = cm_name,
            applied_cm_tier     = cm.tier_int if cm else 0,
            applied_cm_category = cm.category if cm else "",
            applied_cm_zone_id  = cm_record.get("zone_id", prob.zone_id),
            applied_day         = cm_record.get("applied_day", self.time.day),
            zone_maturity       = self.maturity.zone_maturity(prob.zone_id),
        )

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
            # Implementation-quiz correct answers boost CIM (capped at 5)
            if session.quiz_correct_count > 0:
                scores["CIM"] = min(5, scores["CIM"] + session.quiz_correct_count)

        total  = total_score(scores)
        earned = credits_earned(total, prob.severity)

        if session and session.wrong_cm_count >= 2:
            penalty = 0.10 * (session.wrong_cm_count - 1)
            earned  = round(earned * max(0.6, 1.0 - min(penalty, 0.40)))

        rally_bonus = session.earned_rally_bonus if session else False
        if rally_bonus:
            earned = round(earned * 1.1)

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
        prob.score      = scores
        prob.state      = ProblemState.RESOLVED

        for mission in self.missions.values():
            if mission.active and problem_id in mission.problem_ids:
                mission.record_resolved(problem_id)
                mission.advance_hint()

        self._check_mission_triggers()
        self._reevaluate_visibility()

        explanations = explain_scores(
            scores              = scores,
            inspection_log      = self.inspection_log,
            problem             = prob,
            applied_cm_name     = cm_name,
            applied_cm_tier     = cm.tier_int if cm else 0,
            applied_cm_category = cm.category if cm else "",
            applied_cm_zone_id  = cm_record.get("zone_id", prob.zone_id),
            zone_maturity       = self.maturity.zone_maturity(prob.zone_id),
        )

        return {"scores": scores, "total": total, "credits_earned": earned,
                "rally_bonus": rally_bonus, "pdca_complete": pdca_complete,
                "explanations": explanations}

    @property
    def follow_up_due_stations(self) -> set:
        due: set = set()
        for rec in self.active_countermeasures.values():
            if self.time.day - rec.get("applied_day", self.time.day) >= 3:
                due.add(rec["station_id"])
        return due

    def standardize_cm(self, problem_id: str) -> bool:
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
        session = self.investigation_sessions.get(problem_id)
        if not session or not session.verification_complete:
            return False
        session.verification_complete  = False
        session.verification_choices   = []
        return True

    def rollback_countermeasure(self, problem_id: str):
        from config.constants import CREDIT_BASE
        prob = self.problems.get(problem_id)
        if not prob or prob.state != ProblemState.COUNTERMEASURE_APPLIED:
            return None

        cm_id = prob.applied_countermeasure
        rec   = self.active_countermeasures.pop(cm_id, {})

        st = self.stations.get(rec.get("station_id", prob.station_id))
        if st:
            st.remove_modifier(rec.get("avail_d", 0.0), rec.get("perf_d", 0.0), rec.get("qual_d", 0.0))

        if rec.get("zone_id"):
            self.maturity.remove_cm(rec["zone_id"], cm_id or "")

        # Rollbacks are free during recovery mode — the player needs room
        # to experiment without further credit damage while they rebuild.
        penalty = 0 if self.recovery_mode else round(CREDIT_BASE.get(prob.severity, 150) * 0.25)
        self.credits = max(0, self.credits - penalty)

        prob.state                  = ProblemState.ACTIVE
        prob.applied_countermeasure = None
        self._apply_problem_modifiers(prob)
        self.investigation_sessions.pop(problem_id, None)

        return {"penalty_paid": penalty, "problem_id": problem_id}

    def _tick_decay(self) -> None:
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
