"""Act II, Wat onder de grond zit (phase-2 design §3.3, PLAN 2.5): the order of its mains
and the designed failure that lives on digging damage."""
from __future__ import annotations

import pytest

import build_content as bc

CHECK_PASS = 0.5  # Pdca.CHECK_PASS
ACT2_MAINS = ["fix_digging_damage", "fix_revision_backlog", "fix_grid_study_queue", "fix_transformer_wait",
              "fix_unused_capacity", "fix_silo_kpis"]


@pytest.fixture(scope="module")
def real() -> dict:
    return bc.load_content()


def _missions(real: dict) -> dict[str, dict]:
    return {m["id"]: m for m in real["missions"]["missions"]}


def _eff(real: dict, problem_id: str, cm_id: str, maturity: int) -> float:
    """Pdca.effectiveness: the multiplier at the tier gap times the fit."""
    problem = next(p for p in real["problems_tier1"]["problems"] if p["id"] == problem_id)
    cm = next(c for c in real["countermeasures"]["countermeasures"] if c["id"] == cm_id)
    level = ["full", "reduced", "minimal"][max(0, cm["tier"] - maturity)]
    return cm["multipliers"][level] * problem["countermeasures"][cm_id]


def test_digging_damage_comes_before_the_revision_backlog(real):
    """Content's order, kept over the catalogue's (design §3.3 draft check, 2026-10-24):
    both orders pass every Check on the real network (expert, seeds 11-13, identical
    gains), so the order is the lesson's: the symptom first, then its cause upstream.
    Digging damage's deepest clue lies at Revisie & GIS, the revisieberg's briefing opens
    on Gert's cable, and the revision room opens with digging damage."""
    missions = _missions(real)
    order = [missions[m]["requires"]["missions"] for m in ACT2_MAINS]
    assert order[0] == ["fix_done_but_not_closed"]
    for i in range(1, len(ACT2_MAINS)):
        assert order[i] == [ACT2_MAINS[i - 1]], ACT2_MAINS[i]
    assert "Gert" in missions["fix_revision_backlog"]["briefing"], "the revisieberg follows the cable he hit"
    digging = next(p for p in real["problems_tier1"]["problems"] if p["id"] == "digging_damage")
    assert any(c.get("at") == "connections.revision" and c["key"] for c in digging["clues"])


def test_revision_at_the_source_is_too_early_on_digging_damage(real):
    """The designed failure (2026-10-16 spec §2): at Act II's maturity (2) the right idea
    is too early for the damage it should prevent, and works on its own problem."""
    assert _eff(real, "digging_damage", "revision_at_source", 2) < CHECK_PASS
    assert _eff(real, "revision_backlog", "revision_at_source", 2) >= CHECK_PASS
    assert _missions(real)["fix_digging_damage"]["debrief_variants"]["too_early"]
