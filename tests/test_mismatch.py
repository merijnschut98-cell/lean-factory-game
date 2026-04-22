"""Tests for maturity/mismatch.py"""
import pytest

from maturity.mismatch import effectiveness_tier, effectiveness_multiplier, mismatch_warning


class TestEffectivenessTier:
    def test_on_tier_is_full(self):
        assert effectiveness_tier(1, 1.0) == "full"

    def test_below_tier_is_full(self):
        assert effectiveness_tier(1, 2.0) == "full"

    def test_one_tier_above_is_reduced(self):
        assert effectiveness_tier(2, 1.0) == "reduced"

    def test_boundary_gap_exactly_one_is_reduced(self):
        assert effectiveness_tier(2, 1.0) == "reduced"   # gap = 1.0 → reduced

    def test_boundary_gap_just_above_one_is_minimal(self):
        assert effectiveness_tier(3, 1.9) == "minimal"   # gap = 1.1 → minimal

    def test_two_tiers_above_is_minimal(self):
        assert effectiveness_tier(3, 1.0) == "minimal"

    def test_three_plus_tiers_above_is_no_effect(self):
        assert effectiveness_tier(4, 1.0) == "no_effect"


class TestEffectivenessMultiplier:
    def test_full_is_one(self):
        assert effectiveness_multiplier(1, 1.0) == 1.00

    def test_reduced_is_sixty_percent(self):
        assert effectiveness_multiplier(2, 1.0) == 0.60

    def test_minimal_is_thirty_percent(self):
        assert effectiveness_multiplier(3, 1.0) == 0.30

    def test_no_effect_is_five_percent(self):
        assert effectiveness_multiplier(4, 1.0) == 0.05


class TestMismatchWarning:
    def test_full_match_returns_none(self):
        assert mismatch_warning("5S System", 1, 1.0) is None

    def test_reduced_returns_warning_string(self):
        warning = mismatch_warning("Kanban", 2, 1.0)
        assert warning is not None
        assert "60%" in warning
        assert "Kanban" in warning

    def test_minimal_returns_warning_with_thirty_percent(self):
        warning = mismatch_warning("SPC", 3, 1.0)
        assert warning is not None
        assert "30%" in warning

    def test_no_effect_returns_warning_with_five_percent(self):
        warning = mismatch_warning("DMAIC", 4, 1.0)
        assert warning is not None
        assert "5%" in warning
