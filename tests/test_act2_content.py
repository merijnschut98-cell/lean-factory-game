"""Act II, Wat onder de grond zit (phase-2 design §3.3, PLAN 2.5): the order of its mains
and the designed failure that lives on digging damage."""
from __future__ import annotations

import copy

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


def test_every_act2_debrief_reads_the_players_numbers(real):
    """C16 (PLAN 2.5): the debrief names the problem's KPI as the player's Check measured
    it, without and with the fix (Missions._with_numbers)."""
    missions = _missions(real)
    for mid in ACT2_MAINS:
        text = missions[mid]["debrief"]
        assert "{kpi_before}" in text and "{kpi_after}" in text, mid


@pytest.mark.parametrize("mission, debrief, message", [
    ("fix_custom_design", "Van {kpi_before} naar {kpi_now}.", "unknown number token"),
    ("walk_outages", "Van {kpi_before} naar {kpi_after}.", "needs a goal with a problem"),
])
def test_debrief_numbers_are_checked(real, mission, debrief, message):
    doc = copy.deepcopy(real["missions"])
    next(m for m in doc["missions"] if m["id"] == mission)["debrief"] = debrief
    with pytest.raises(bc.ContentError, match=message):
        bc.validate_missions(doc, "missions.yaml")


# ── Act II gets one deadline (Merijn, 2026-10-27, M1) ────────────────────────
# Digging damage must be fixed before the winter, and the cheap contractor briefing is the door
# that closes. Winter 1's frost window (day 70, 21 December 2026) is already running when the
# first player who took the bottleneck first opens Act II (the expert: day 76), so the winter this
# deadline means is the next one: the same shortest day a year on. No Act II fork (the next is
# planned in Act III).
FIRST_FROST_DAY = 70          # winter_el_amrani's deadline_on_day
WINTER_TWO_FROST_DAY = FIRST_FROST_DAY + 365


def test_act_two_has_exactly_one_deadline_and_no_fork(real):
    missions = _missions(real)
    timed = [m for m in ACT2_MAINS if "deadline_on_day" in missions[m] or "deadline_days" in missions[m]]
    assert timed == ["fix_digging_damage"]
    assert not [m for m in ACT2_MAINS if "fork" in missions[m]]


def test_digging_damage_must_be_fixed_before_the_second_winter(real):
    digging = _missions(real)["fix_digging_damage"]
    assert digging["deadline_on_day"] == WINTER_TWO_FROST_DAY
    assert digging["deadline_on_day"] > FIRST_FROST_DAY, "a player who plays Act I in order opens Act II after day 70"
    assert digging["fail"]


def test_the_briefing_states_the_clock_without_naming_the_door(real):
    briefing = _missions(real)["fix_digging_damage"]["briefing"].lower()
    assert "21 december 2027" in briefing
    assert "briefing" not in briefing and "briefen" not in briefing, "the way out is the player's to find"


def test_a_missed_deadline_closes_the_cheap_contractor_briefing_and_nothing_else(real):
    digging = _missions(real)["fix_digging_damage"]
    assert digging["fail_closes"] == ["contractor_briefing"]
    problem = next(p for p in real["problems_tier1"]["problems"] if p["id"] == "digging_damage")
    left = [cm for cm in problem["countermeasures"] if cm not in digging["fail_closes"]]
    assert "standard_test_trenches" in left, "another countermeasure still solves it"
    assert _eff(real, "digging_damage", "standard_test_trenches", 2) >= CHECK_PASS, "at Act II's maturity"


def test_a_door_closed_by_a_day_deadline_needs_that_deadline(real):
    docs = copy.deepcopy(real["missions"])
    digging = next(m for m in docs["missions"] if m["id"] == "fix_digging_damage")
    bc.validate_missions(docs, "missions.yaml")
    del digging["deadline_on_day"]
    with pytest.raises(bc.ContentError, match="'fail_closes' needs a deadline"):
        bc.validate_missions(docs, "missions.yaml")
