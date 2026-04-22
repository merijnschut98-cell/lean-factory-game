"""Tests for scoring/metrics.py — all six deterministic metrics."""
import pytest
from unittest.mock import MagicMock

from scoring.metrics import (
    score_dqq, score_ei, score_rca, score_cmp, score_lm, score_cim,
    total_score, credits_earned,
)


def _make_log(*entries):
    """Build a minimal inspection log."""
    return [{"entity": e, "metric": m, "day": d} for e, m, d in entries]


def _make_problem(effective_cms=None, zone_id="z1", station_id="dock"):
    prob = MagicMock()
    prob.effective_countermeasures = effective_cms or ["5S System"]
    prob.zone_id   = zone_id
    prob.station_id = station_id
    return prob


class TestDQQ:
    def test_score_1_when_no_inspections(self):
        assert score_dqq([], "z1") == 1

    def test_score_3_when_three_entities_in_problem_zone(self):
        log = _make_log(
            ("z1:dock", "oee", 1),
            ("z1:incoming_qa", "oee", 1),
            ("z1:coil_winding", "oee", 1),
        )
        assert score_dqq(log, "z1") == 3

    def test_score_5_when_five_entities_with_diagnostic_and_two_zones(self):
        log = _make_log(
            ("z1:dock", "oee", 1),
            ("z1:incoming_qa", "oee", 1),
            ("z1:coil_winding", "oee", 1),
            ("z2:pcb_prep", "oee", 1),
            ("z2:deck_cutting", "diagnostic_time_obs", 1),
        )
        assert score_dqq(log, "z1") == 5


class TestEI:
    def test_score_1_when_no_inspections(self):
        assert score_ei([], "quality") == 1

    def test_score_3_with_two_entities(self):
        log = _make_log(("z1:dock", "oee", 1), ("z1:qa", "oee", 1))
        assert score_ei(log, "quality") == 3

    def test_score_5_quality_cm_with_quality_metric_observed(self):
        log = _make_log(
            ("z1:dock", "quality", 1),
            ("z1:qa", "quality", 1),
            ("z1:winding", "quality", 1),
            ("z2:pcb", "oee", 1),
        )
        assert score_ei(log, "quality") == 5


class TestRCA:
    def test_score_5_when_cm_in_effective_list(self):
        prob = _make_problem(["5S System", "Standard Work Definition"])
        assert score_rca("5S System", prob) == 5

    def test_score_1_when_cm_unrelated(self):
        prob = _make_problem(["5S System"])
        assert score_rca("DMAIC", prob) == 1

    def test_score_1_when_empty_cm(self):
        prob = _make_problem(["5S System"])
        assert score_rca("", prob) == 1


class TestCMP:
    def test_score_5_correct_cm_correct_zone(self):
        prob = _make_problem(["5S System"], zone_id="z1")
        assert score_cmp("5S System", prob, 1.0, "z1") == 5

    def test_score_3_correct_cm_wrong_zone(self):
        prob = _make_problem(["5S System"], zone_id="z1")
        assert score_cmp("5S System", prob, 1.0, "z2") == 3

    def test_score_3_wrong_cm_correct_zone(self):
        prob = _make_problem(["5S System"], zone_id="z1")
        assert score_cmp("DMAIC", prob, 1.0, "z1") == 3

    def test_score_1_wrong_cm_wrong_zone(self):
        prob = _make_problem(["5S System"], zone_id="z1")
        assert score_cmp("DMAIC", prob, 1.0, "z2") == 1


class TestLM:
    def test_score_5_on_tier(self):
        assert score_lm(1, 1.0) == 5

    def test_score_5_one_tier_above(self):
        assert score_lm(2, 1.0) == 5   # gap = 1.0 — appropriate stretch

    def test_score_3_two_tiers_above(self):
        assert score_lm(3, 1.0) == 3

    def test_score_1_three_tiers_above(self):
        assert score_lm(4, 1.0) == 1


class TestCIM:
    def test_score_1_no_inspections(self):
        assert score_cim([], "dock", applied_day=1) == 1

    def test_score_3_inspected_before_apply(self):
        log = _make_log(("z1:dock", "oee", 1))
        assert score_cim(log, "dock", applied_day=2) == 3

    def test_score_5_reinspected_after_apply(self):
        log = _make_log(
            ("z1:dock", "oee", 1),
            ("z1:dock", "oee", 3),  # day 3 > applied_day 2
        )
        assert score_cim(log, "dock", applied_day=2) == 5


class TestTotalAndCredits:
    def test_total_sums_all_metrics(self):
        scores = {"DQQ": 5, "EI": 3, "RCA": 5, "CMP": 5, "LM": 5, "CIM": 3}
        assert total_score(scores) == 26

    def test_max_score_earns_full_credits(self):
        assert credits_earned(30, "high") == 200

    def test_half_score_earns_half_credits(self):
        assert credits_earned(15, "high") == 100

    def test_zero_score_earns_zero_credits(self):
        assert credits_earned(0, "high") == 0

    def test_unknown_severity_uses_default(self):
        earned = credits_earned(30, "unknown_tier")
        assert earned == 150  # CREDIT_BASE default
