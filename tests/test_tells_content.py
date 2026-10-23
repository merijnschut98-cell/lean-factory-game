"""The tells (PLAN 2.6, design §1.5): problems_tier1.yaml `tells:` names which prop on the 1e
shows a problem's symptom. Every listed tell exists, its text never names the problem, and
every problem whose place is on the 1e has at least one."""
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


def test_the_tells_cover_every_room_of_the_1e():
    rooms_with_tells = set(bc.TELLS.values())
    assert rooms_with_tells == {"connections", "revision_gis", "meter_data"}
    shown = {p["id"]: [t["tell"] for t in p.get("tells", [])] for p in REAL["problems_tier1"]["problems"]}
    assert "intake_stack" in shown["incomplete_application"]
    assert "prep_tray" in shown["custom_design"]
    assert "planning_board" in shown["planning_reshuffle"]
    assert "revision_cabinet" in shown["revision_backlog"]
    assert "close_out_cabinet" in shown["done_but_not_closed"]
    assert "meter_board" in shown["silent_meter"]


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


def test_every_problem_on_the_1e_needs_a_tell_whatever_its_room():
    """A new room on the 1e with no prop of its own still needs its problems shown somewhere."""
    def mutate(docs):
        rooms = docs["world"]["rooms"]
        next(r for r in rooms if r["id"] == "meter_data")["places"].remove("connections.close_out_wait")
        rooms.append({"id": "archive", "floor": "first", "name": "Archief", "places": ["connections.close_out_wait"],
                      "opens_with": []})
        next(t for t in docs["world"]["tells"] if t["id"] == "close_out_cabinet")["place"] = "connections.close_out"
        _problem(docs, "done_but_not_closed").pop("tells")
    with pytest.raises(bc.ContentError, match="done_but_not_closed.*no tell"):
        _check(mutate)


def test_a_problem_off_the_1e_needs_no_tell():
    def mutate(docs):
        assert not _problem(docs, "wrong_joint_in_van").get("tells")
    _check(mutate)


def _look(docs: dict, tell_id: str) -> dict:
    return next(t for t in docs["world"]["tells"] if t["id"] == tell_id)


def test_the_world_has_words_for_every_tell_at_every_height():
    assert {t["id"] for t in REAL["world"]["tells"]} == set(bc.TELLS)
    for t in REAL["world"]["tells"]:
        assert all(t[v] for v in ("low", "mid", "high")), t["id"]


def test_a_tell_missing_from_the_world_is_refused():
    def mutate(docs):
        docs["world"]["tells"] = [t for t in docs["world"]["tells"] if t["id"] != "meter_board"]
    with pytest.raises(bc.ContentError, match="meter_board"):
        _check(mutate)


def test_a_look_that_names_a_problem_is_refused():
    def mutate(docs):
        _look(docs, "meter_board")["high"] = "Het bord staat vol: de zwijgende meter."
    with pytest.raises(bc.ContentError, match="names the problem"):
        _check(mutate)


def test_a_look_placed_outside_its_room_is_refused():
    def mutate(docs):
        _look(docs, "meter_board")["place"] = "connections.intake"
    with pytest.raises(bc.ContentError, match="meter_board.*room"):
        _check(mutate)


def test_a_look_needs_every_height():
    docs = copy.deepcopy(REAL)
    _look(docs, "prep_tray").pop("mid")
    with pytest.raises(bc.ContentError, match="prep_tray"):
        bc.validate_world(docs["world"], "world.yaml")


def test_a_tell_needs_a_text():
    def mutate(docs):
        _problem(docs, "custom_design")["tells"] = [{"tell": "prep_tray"}]
    with pytest.raises(bc.ContentError, match="tell"):
        _check(mutate)
