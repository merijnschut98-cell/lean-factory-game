"""
Integration tests for the countermeasure application and problem resolution flow.
Uses Factory directly (no pygame required — headless simulation layer only).
"""
import pytest

from simulation.factory import Factory
from problems.problem import ProblemState


@pytest.fixture
def factory():
    """Fresh factory with problems loaded but no save file."""
    return Factory()


class TestApplyCountermeasure:
    def test_apply_valid_cm_returns_success(self, factory):
        prob_id = next(iter(factory.active_problems))
        cm_id = "CM-T1-001"  # 5S System — always valid
        result = factory.apply_countermeasure(prob_id, cm_id)
        assert result["success"] is True

    def test_apply_sets_problem_state_to_cm_applied(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        assert factory.problems[prob_id].state == ProblemState.COUNTERMEASURE_APPLIED

    def test_apply_records_cm_on_problem(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        assert factory.problems[prob_id].applied_countermeasure == "CM-T1-001"

    def test_apply_registers_cm_in_active_countermeasures(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        assert "CM-T1-001" in factory.active_countermeasures

    def test_apply_unknown_problem_returns_failure(self, factory):
        result = factory.apply_countermeasure("FAKE-ID", "CM-T1-001")
        assert result["success"] is False

    def test_apply_unknown_cm_returns_failure(self, factory):
        prob_id = next(iter(factory.active_problems))
        result = factory.apply_countermeasure(prob_id, "CM-FAKE-999")
        assert result["success"] is False

    def test_full_effect_at_tier1_maturity(self, factory):
        prob_id = next(iter(factory.active_problems))
        result = factory.apply_countermeasure(prob_id, "CM-T1-001")
        # Zone starts at 1.0 maturity; Tier 1 CM → full effect
        assert result["eff_multiplier"] == 1.0

    def test_station_modifier_applied_to_station(self, factory):
        prob = next(iter(factory.active_problems.values()))
        st = factory.stations[prob.station_id]
        oee_before = st.oee
        factory.apply_countermeasure(prob.id, "CM-T1-001")
        assert st.oee > oee_before


class TestResolveProblem:
    def _apply_and_check_resolve(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        return factory.resolve_problem(prob_id), prob_id

    def test_resolve_returns_scores_dict(self, factory):
        result, _ = self._apply_and_check_resolve(factory)
        assert result is not None
        assert "scores" in result
        assert set(result["scores"].keys()) == {"DQQ", "EI", "RCA", "CMP", "LM", "CIM"}

    def test_resolve_returns_total(self, factory):
        result, _ = self._apply_and_check_resolve(factory)
        assert result["total"] == sum(result["scores"].values())

    def test_resolve_awards_credits(self, factory):
        result, _ = self._apply_and_check_resolve(factory)
        assert result["credits_earned"] >= 0
        assert factory.credits == result["credits_earned"]

    def test_resolve_sets_state_resolved(self, factory):
        result, prob_id = self._apply_and_check_resolve(factory)
        assert factory.problems[prob_id].state == ProblemState.RESOLVED

    def test_resolve_without_cm_applied_returns_none(self, factory):
        prob_id = next(iter(factory.active_problems))
        assert factory.resolve_problem(prob_id) is None

    def test_resolve_removes_problem_negative_modifiers(self, factory):
        prob = next(iter(factory.active_problems.values()))
        st = factory.stations[prob.station_id]
        oee_before = st.oee
        factory.apply_countermeasure(prob.id, "CM-T1-001")
        factory.resolve_problem(prob.id)
        # Resolve removes the problem's negative modifiers; CM positive modifiers stay.
        # Net result: OEE should be higher than before (problem degradation gone, CM still active).
        assert st.oee > oee_before


class TestDecay:
    def test_decay_removes_cm_after_days_elapsed(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        rec = factory.active_countermeasures.get("CM-T1-001")
        if rec and rec["decay_days"]:
            # Manually advance time past decay threshold
            factory.time._sim_time += rec["decay_days"] * 86400 + 1
            factory._tick_decay()
            assert "CM-T1-001" not in factory.active_countermeasures
