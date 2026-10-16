"""The head office's floors and rooms (content/world.yaml, PLAN 2.1) in the content pipeline."""
from __future__ import annotations

import copy
from pathlib import Path

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}


def _room(doc: dict, room_id: str) -> dict:
    return next(r for r in doc["rooms"] if r["id"] == room_id)


def _check(mutate) -> None:
    docs = copy.deepcopy(REAL)
    mutate(docs["world"])
    bc.validate_world(docs["world"], "world.yaml")
    bc.check_world(docs)


def test_the_real_building_is_valid_with_three_floors_and_the_planned_rooms():
    docs = bc.load_content()
    world = docs["world"]
    assert [f["level"] for f in world["floors"]] == [0, 1, 2]
    by_floor = {f["id"]: [r["name"] for r in world["rooms"] if r["floor"] == f["id"]] for f in world["floors"]}
    assert by_floor == {
        "ground": ["Ontvangst", "Klantcontactcentrum", "Kantine"],
        "first": ["Aansluitingen", "Revisie & GIS", "Meetdata & registratie"],
        "second": ["Directie & Obeya", "Netstrategie", "Congestiedesk", "MT-kamer", "Kantoor Ruud"],
    }
    assert world["start_floor"] == "first"
    assert _room(world, "connections")["opens_with"] == ["start"], "the existing floor is open from the start"


def test_only_the_way_in_and_the_first_teams_are_open_from_the_start():
    world = REAL["world"]
    assert sorted(r["id"] for r in world["rooms"] if "start" in r["opens_with"]) == ["connections", "reception"]


def test_the_world_file_is_optional_for_a_content_set(tmp_path: Path):
    assert "world" in bc.OPTIONAL


@pytest.mark.parametrize("mutate, message", [
    (lambda w: w.update(start_floor="attic"), "start_floor 'attic' is not a floor"),
    (lambda w: w["floors"][1].update(level=0), "two floors on level 0"),
    (lambda w: w["floors"][0].update(model="../../etc/x.glb"), "'model' must be a .glb file name"),
    (lambda w: w["floors"][0].update(name=""), "'name' must be a non-empty string"),
    (lambda w: w["floors"][0].update(lift=True), "unknown key"),
    (lambda w: _room(w, "canteen").update(floor="roof"), "unknown floor 'roof'"),
    (lambda w: _room(w, "canteen").update(opens_with="start"), "'opens_with' must be a list"),
    (lambda w: _room(w, "canteen").update(places=["connections.nowhere"]), "unknown place 'connections.nowhere'"),
    (lambda w: _room(w, "meter_data").update(places=["connections.intake"]), "'connections.intake' is in two rooms"),
    (lambda w: _room(w, "canteen").update(opens_with=["fix_ghost"]), "opens with unknown mission 'fix_ghost'"),
    (lambda w: _room(w, "canteen").update(opens_with=["ghost_*"]), "opens with unknown mission 'ghost_\\*'"),
    (lambda w: _room(w, "revision_gis").update(opens_with=["fix_revision_backlog"]),
     "mission 'fix_digging_damage' leads to 'connections.revision' in room 'revision_gis', which does not open with it"),
    (lambda w: w["rooms"].append({"id": "attic", "floor": "second", "name": "Zolder", "places": [], "opens_with": []}) or
     w["floors"].append({"id": "roof", "level": 3, "name": "Dak", "model": "office_roof.glb"}),
     "floor 'roof' has no rooms"),
])
def test_world_errors_are_caught(mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(mutate)
