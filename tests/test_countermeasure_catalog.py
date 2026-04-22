"""Tests for problems/countermeasure.py — catalog loading and parsing."""
import pytest
from pathlib import Path

from problems.countermeasure import CountermeasureCatalog, Countermeasure, _parse_cm


class TestCatalogLoad:
    def setup_method(self):
        self.catalog = CountermeasureCatalog()
        self.catalog.load()

    def test_loads_correct_total_count(self):
        assert len(self.catalog) == 79

    def test_tier1_count(self):
        assert len(self.catalog.by_tier(1)) == 10

    def test_tier2_count(self):
        assert len(self.catalog.by_tier(2)) == 16

    def test_tier3_count(self):
        assert len(self.catalog.by_tier(3)) == 24

    def test_tier4_count(self):
        assert len(self.catalog.by_tier(4)) == 18

    def test_diagnostic_count(self):
        assert len(self.catalog.diagnostics()) == 11

    def test_get_by_id_returns_correct_cm(self):
        cm = self.catalog.get("CM-T1-001")
        assert cm is not None
        assert cm.name == "5S System"
        assert cm.tier == 1

    def test_get_unknown_id_returns_none(self):
        assert self.catalog.get("CM-FAKE-999") is None

    def test_all_playable_excludes_diagnostics(self):
        playable = self.catalog.all_playable()
        assert all(not cm.is_diagnostic for cm in playable)

    def test_all_playable_sorted_by_tier_then_name(self):
        playable = self.catalog.all_playable()
        tiers = [cm.tier_int for cm in playable]
        assert tiers == sorted(tiers)

    def test_applicable_to_all_station_type(self):
        cms = self.catalog.applicable_to_station("final_assembly")
        assert len(cms) > 0

    def test_cm_with_decay_has_days(self):
        cm = self.catalog.get("CM-T1-001")  # 5S System — decay enabled
        assert cm.decay_enabled is True
        assert cm.decay_days == 30


class TestParseCm:
    def test_missing_id_raises_key_error(self):
        with pytest.raises(KeyError):
            _parse_cm({"name": "Test", "tier": 1})

    def test_invalid_tier_raises_value_error(self):
        with pytest.raises((ValueError, TypeError)):
            _parse_cm({"id": "X", "tier": "bogus_tier"})

    def test_diagnostic_tier_string_parsed(self):
        raw = {
            "id": "CM-DX-TEST",
            "name": "Test Diagnostic",
            "tier": "diagnostic",
            "category": "problem_solving",
            "description": "Test",
            "effectiveness": "always_full",
            "decay": {"enabled": False},
            "cost_credits": 0,
        }
        cm = _parse_cm(raw)
        assert cm.is_diagnostic is True
        assert cm.tier_int == 0

    def test_maturity_requirement_as_none_string(self):
        """Diagnostic CMs have maturity_requirement: 'none' (string) in YAML."""
        raw = {
            "id": "CM-DX-007",
            "name": "Gemba Walk",
            "tier": "diagnostic",
            "category": "management_system",
            "description": "...",
            "maturity_requirement": "none",
            "effectiveness": "always_full",
            "decay": {"enabled": False},
            "cost_credits": 0,
        }
        cm = _parse_cm(raw)
        assert cm.prerequisites == []


class TestCountermeasureProperties:
    def setup_method(self):
        self.catalog = CountermeasureCatalog()
        self.catalog.load()

    def test_effectiveness_multipliers_present_for_tier1(self):
        cm = self.catalog.get("CM-T1-001")
        assert cm.effectiveness is not None
        assert 0.0 < cm.effectiveness.full <= 1.0
        assert cm.effectiveness.reduced < cm.effectiveness.full
        assert cm.effectiveness.minimal < cm.effectiveness.reduced
