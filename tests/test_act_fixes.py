"""The fixes a mission offers in its own act (Act 0/I mission audit, 2026-10-24).

A countermeasure works by its fit times the region's maturity (Pdca.effectiveness), and
the A3 offers only those up to one tier above the maturity (Region.available_countermeasures).
Read with the maturity an act is played at, three things must hold:
- the patient fix is reachable: every solve mission's problem has a fix that the A3
  offers, that works (CHECK_PASS) and that is not a poor fix (Missions.POOR_FIT_GAP);
- a designed failed Check is real: a mission's `too_early` debrief needs a fitting
  countermeasure that the A3 offers in its act and that works below CHECK_PASS;
- a debrief never tells a player who chose a passing poor fix that they chose the best
  one: such a mission has a `poor_fix` debrief (training days excepted: their debriefs
  hold for every fix, and Friday's lesson is borgen).
Failures are content to fix, never the test."""
from __future__ import annotations

import re

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}
CMS = {c["id"]: c for c in REAL["countermeasures"]["countermeasures"]}
PROBLEMS = {p["id"]: p for p in REAL["problems_tier1"]["problems"]}
SOLVES = [m for m in REAL["missions"]["missions"] if m["goal"].get("type") == "solve"]

_RULES = bc.ROOT / "game" / "src" / "rules"
CHECK_PASS = float(re.search(r"const CHECK_PASS := ([0-9.]+)", (_RULES / "pdca.gd").read_text(encoding="utf-8")).group(1))
POOR_FIT_GAP = float(re.search(r"const POOR_FIT_GAP := ([0-9.]+)",
                               (_RULES / "missions.gd").read_text(encoding="utf-8")).group(1))
LEVELS = ["full", "reduced", "minimal"]
# ESTIMATE (the autoplay of 2026-10-23): the training week and Act I play at maturity 1
# (twelve of the twenty tier-1 problems must be resolved for 2; the expert has nine by
# the last Act I main), Act II at 2.
ACT_MATURITY = {0: 1, 1: 1, 2: 2}


def _ids(missions: list[dict]) -> list[str]:
    return [m["id"] for m in missions]


def _offered(cm_id: str, maturity: int) -> bool:
    return CMS[cm_id]["tier"] <= maturity + 1


def _eff(problem_id: str, cm_id: str, maturity: int) -> float:
    cm = CMS[cm_id]
    level = LEVELS[max(0, cm["tier"] - maturity)]
    return cm["multipliers"][level] * PROBLEMS[problem_id]["countermeasures"][cm_id]


def _poor(problem_id: str, cm_id: str) -> bool:
    fits = PROBLEMS[problem_id]["countermeasures"]
    return fits[cm_id] <= max(fits.values()) - POOR_FIT_GAP + 1e-9


def _passing(m: dict) -> list[str]:
    """The countermeasures of `m`'s problem that its act's A3 offers and that work."""
    problem_id, maturity = m["goal"]["problem"], ACT_MATURITY[m["act"]]
    return [c for c in PROBLEMS[problem_id]["countermeasures"]
            if _offered(c, maturity) and _eff(problem_id, c, maturity) >= CHECK_PASS]


@pytest.mark.parametrize("m", SOLVES, ids=_ids(SOLVES))
def test_the_patient_fix_is_reachable_in_its_act(m):
    problem_id = m["goal"]["problem"]
    assert any(not _poor(problem_id, c) for c in _passing(m)), \
        f"{m['id']}: in act {m['act']} every fix that works is a poor fix ({_passing(m)})"


@pytest.mark.parametrize("m", [m for m in SOLVES if "too_early" in m.get("debrief_variants", {})],
                         ids=lambda m: m["id"])
def test_a_designed_failed_check_can_happen(m):
    problem_id, maturity = m["goal"]["problem"], ACT_MATURITY[m["act"]]
    too_early = [c for c in PROBLEMS[problem_id]["countermeasures"]
                 if _offered(c, maturity) and CMS[c]["tier"] > maturity and _eff(problem_id, c, maturity) < CHECK_PASS]
    assert too_early, f"{m['id']}: no countermeasure the A3 offers in act {m['act']} is too early"


@pytest.mark.parametrize("m", [m for m in SOLVES if m["kind"] != "training"], ids=lambda m: m["id"])
def test_a_passing_poor_fix_has_its_own_debrief(m):
    poor = [c for c in _passing(m) if _poor(m["goal"]["problem"], c)]
    assert not poor or "poor_fix" in m.get("debrief_variants", {}), \
        f"{m['id']}: {poor} pass as poor fixes, but the debrief describes the best fix"
