"""
Tests for full game-state serialisation and restore (Phase 4 save/load fix).
Verifies that to_dict / from_dict round-trips problem states, active CMs,
inspection log, maturity scores, and station modifiers correctly.
"""
import pytest
from simulation.factory import Factory
from problems.problem import ProblemState


@pytest.fixture
def factory():
    return Factory()


class TestProblemStateRoundTrip:
    def test_active_problem_state_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        assert factory.problems[prob_id].state == ProblemState.ACTIVE

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.problems[prob_id].state == ProblemState.ACTIVE

    def test_cm_applied_state_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.problems[prob_id].state == ProblemState.COUNTERMEASURE_APPLIED
        assert f2.problems[prob_id].applied_countermeasure == "CM-T1-001"

    def test_resolved_state_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        factory.resolve_problem(prob_id)

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.problems[prob_id].state == ProblemState.RESOLVED
        assert f2.problems[prob_id].solved_day is not None

    def test_first_seen_day_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.problems[prob_id].first_seen_day = 3

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.problems[prob_id].first_seen_day == 3

    def test_score_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        result = factory.resolve_problem(prob_id)

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.problems[prob_id].score == result["scores"]


class TestActiveCountermeasuresRoundTrip:
    def test_active_cm_survives_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        assert "CM-T1-001" in factory.active_countermeasures

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert "CM-T1-001" in f2.active_countermeasures

    def test_cm_record_fields_survive_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        rec_orig = factory.active_countermeasures["CM-T1-001"]

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        rec_restored = f2.active_countermeasures["CM-T1-001"]
        assert rec_restored["zone_id"]     == rec_orig["zone_id"]
        assert rec_restored["applied_day"] == rec_orig["applied_day"]
        assert rec_restored["avail_d"]     == pytest.approx(rec_orig["avail_d"], abs=1e-6)

    def test_no_active_cms_on_fresh_load(self, factory):
        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)
        # Only problems with CM applied should have entries
        assert len(f2.active_countermeasures) == 0


class TestInspectionLogRoundTrip:
    def test_inspection_log_survives_round_trip(self, factory):
        factory.log_inspection("z2:coil_winding", "oee")
        factory.log_inspection("z3:deck_assembly", "wip")

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert len(f2.inspection_log) == 2
        assert f2.inspection_log[0]["entity"] == "z2:coil_winding"
        assert f2.inspection_log[1]["entity"] == "z3:deck_assembly"


class TestMaturityRoundTrip:
    def test_maturity_scores_survive_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        factory.maturity.update(factory)
        zone_id = factory.problems[prob_id].zone_id
        score_before = factory.maturity.zone_maturity(zone_id)

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.maturity.zone_maturity(zone_id) == pytest.approx(score_before, abs=0.01)

    def test_active_cms_in_maturity_survive_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        zone_id = factory.problems[prob_id].zone_id
        factory.apply_countermeasure(prob_id, "CM-T1-001")

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        # Maturity engine should have CM-T1-001 registered for the zone
        cms_in_zone = [cid for _, cid in f2.maturity._active_cms.get(zone_id, [])]
        assert "CM-T1-001" in cms_in_zone


class TestStationModifiersRoundTrip:
    def test_station_deltas_survive_round_trip(self, factory):
        prob = next(iter(factory.active_problems.values()))
        st = factory.stations[prob.station_id]
        factory.apply_countermeasure(prob.id, "CM-T1-001")
        avail_delta_before = st._avail_delta

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        st2 = f2.stations[prob.station_id]
        assert st2._avail_delta == pytest.approx(avail_delta_before, abs=1e-6)

    def test_credits_survive_round_trip(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        factory.resolve_problem(prob_id)
        credits_before = factory.credits

        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)

        assert f2.credits == credits_before
