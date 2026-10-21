"""The tells (PLAN 2.6, design §1.5): problems_tier1.yaml `tells:` names which prop on the 1e
shows a problem's symptom. Every listed tell exists, its text never names the problem, and
every problem whose place is in a room with tells has at least one."""
from __future__ import annotations

import copy

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}


def _problem(docs: dict, problem_id: str) -> dict:
    return next(p for p in docs["problems_tier1"]["problems"] if p["id"] == problem_id)


def _check(mutate) -> None:
    docs = copy.deepcopy(REAL)
    mutate(docs)
    bc.validate_problems(docs["problems_tier1"], "problems_tier1.yaml")
    bc.check_tells(docs)


def test_the_real_tells_are_valid():
    _check(lambda docs: None)


def test_the_tells_on_the_1e_cover_its_connections_room():
    rooms_with_tells = set(bc.TELLS.values())
    assert rooms_with_tells == {"connections"}
    shown = {p["id"]: [t["tell"] for t in p.get("tells", [])] for p in REAL["problems_tier1"]["problems"]}
    assert "intake_stack" in shown["incomplete_application"]
    assert "prep_tray" in shown["custom_design"]
    assert "planning_board" in shown["planning_reshuffle"]


def test_an_unknown_tell_is_refused():
    def mutate(docs):
        _problem(docs, "custom_design")["tells"] = [{"tell": "coffee_machine", "text": "De koffie is op."}]
    with pytest.raises(bc.ContentError, match="unknown tell 'coffee_machine'"):
        _check(mutate)


def test_a_tell_that_names_its_problem_is_refused():
    def mutate(docs):
        _problem(docs, "custom_design")["tells"] = [
            {"tell": "prep_tray", "text": "Het bakje ligt vol: maatwerk voor standaardwerk."}]
    with pytest.raises(bc.ContentError, match="names the problem"):
        _check(mutate)


def test_a_problem_in_a_room_with_tells_needs_one():
    def mutate(docs):
        _problem(docs, "planning_reshuffle").pop("tells")
    with pytest.raises(bc.ContentError, match="planning_reshuffle.*no tell"):
        _check(mutate)


def test_a_tell_needs_a_text():
    def mutate(docs):
        _problem(docs, "custom_design")["tells"] = [{"tell": "prep_tray"}]
    with pytest.raises(bc.ContentError, match="tell"):
        _check(mutate)
