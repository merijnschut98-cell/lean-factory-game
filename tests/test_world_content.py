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
    assert [f.get("level") for f in world["floors"]] == [0, 1, 2, None], "three floors and the yard outside"
    by_floor = {f["id"]: [r["name"] for r in world["rooms"] if r["floor"] == f["id"]] for f in world["floors"]}
    assert by_floor == {
        "ground": ["Ontvangst", "Klantcontactcentrum", "Kantine"],
        "first": ["Aansluitingen", "Revisie & GIS", "Meetdata & registratie"],
        "second": ["Directie & Obeya", "Netstrategie", "Congestiedesk", "MT-kamer", "Directeur Netbeheer"],
        "yard": ["Magazijn", "Werkplaats & storingsdienst", "Bussen", "Opleidingsterrein"],
    }
    assert world["start_floor"] == "first"
    assert _room(world, "connections")["opens_with"] == ["start"], "the existing floor is open from the start"


def test_ruuds_office_upstairs_stays_shut_until_day_100():
    # Merijn, 2026-10-16 (Q10): Ruud sits with Aansluitingen in Act 0-I by choice and moves
    # back up when Act II opens the 2e (the cast's `moves`, after the hundred-day review).
    assert _room(REAL["world"], "ruud_office")["opens_with"] == ["review_100_days"]
    ruud = next(c for c in bc._cast() if c["id"] == "ruud")
    assert ruud["office"]["moves"]["after"] == ["review_100_days"]
    assert ruud["office"]["moves"]["floor"] == "second"


def _room_of(world: dict, place: str) -> dict | None:
    return next((r for r in world["rooms"] if place in r["places"]), None)


def test_every_talk_is_reachable_when_its_mission_is_on():
    # A talk's person sits in a room: the room must be open while the talk's mission is
    # (opened by it, or by a mission before it in the same chain), or the talk is unreachable.
    docs = bc.load_content()
    world, dialogs = docs["world"], docs["dialogs"]
    people = {p["id"]: p for p in dialogs["people"]}
    for talk in dialogs["dialogs"]:
        mission = talk.get("mission")
        room = _room_of(world, people[talk["person"]]["place"])
        if not mission or room is None:
            continue
        assert "start" in room["opens_with"] or mission in room["opens_with"], \
            f"{talk['id']}: {talk['person']} sits in {room['id']}, which does not open with {mission}"


def test_the_week_opens_the_rooms_its_talks_and_tour_need():
    world = REAL["world"]
    assert "training_mon" in _room(world, "canteen")["opens_with"], "Ruud's tour shows the kantine"
    assert "training_wed" in _room(world, "revision_gis")["opens_with"], "Mieke's Wednesday talk (D9 audit P0)"
    assert "training_thu" in _room(world, "meter_data")["opens_with"], "Petra's Thursday talk (D9 audit P0)"


def test_the_yard_is_an_outside_area_of_the_begane_grond_with_the_field_steps():
    world = REAL["world"]
    yard = next(f for f in world["floors"] if f["id"] == "yard")
    assert yard["outside_of"] == "ground" and "level" not in yard, "reached by a door, never by the stairs"
    rooms = {r["id"]: r for r in world["rooms"] if r["floor"] == "yard"}
    assert set(rooms) == {"magazijn", "werkplaats", "van_park", "opleidingsterrein"}
    assert set(rooms["magazijn"]["places"]) == {"outages.joint", "connections.materials", "meters.reserve_meter"}
    assert {"outages.repair", "meters.visit"} == set(rooms["van_park"]["places"])
    assert "outages.locate" in rooms["werkplaats"]["places"]
    assert not any("start" in r["opens_with"] for r in rooms.values()), "nothing on the yard is open from the start"
    assert "fix_wrong_joint" in rooms["magazijn"]["opens_with"], "Dirk's talk"


def test_the_opleidingsterrein_opens_with_henks_knowledge():
    # PLAN 2.3: a small fenced training ground off the yard where Henk teaches Ahmed by doing.
    room = _room(REAL["world"], "opleidingsterrein")
    assert room["floor"] == "yard" and room["places"] == []
    assert room["opens_with"] == ["save_henks_knowledge"]


def test_the_three_yard_sides_ride_out_in_a_van():
    # The van ride (design §1.7): you sit beside the monteur, the ride ends at the side's field step.
    rides = {r["mission"]: (r["with"], r["to"]) for r in REAL["world"]["rides"]}
    assert rides == {"fix_wrong_joint": ("ahmed", "outages.repair"), "fix_not_at_home": ("sandra", "meters.visit"),
                     "save_henks_knowledge": ("henk", "outages.locate")}


@pytest.mark.parametrize("mutate, message", [
    (lambda w: w["rides"].append({"mission": "fix_ghost", "with": "henk", "to": "outages.locate"}),
     "ride: unknown mission 'fix_ghost'"),
    (lambda w: w["rides"].append(dict(w["rides"][0])), "two rides for mission"),
    (lambda w: w["rides"][0].update(to="connections.intake"), "not a place on the yard"),
    (lambda w: w["rides"][1].update(to="outages.joint"), "does not open"),
    (lambda w: w["rides"][0].update(**{"with": "anouk"}), "has no van"),
    (lambda w: w["rides"][0].update(**{"with": "nobody"}), "not in the cast"),
    (lambda w: w["rides"][0].update(by="bike"), "unknown key"),
])
def test_a_ride_is_checked(mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(mutate)


@pytest.mark.parametrize("mutate, message", [
    (lambda w: w["floors"][-1].update(outside_of="attic"), "outside of unknown floor 'attic'"),
    (lambda w: w["floors"][-1].update(level=0), "either a level or 'outside_of'"),
])
def test_an_outside_area_is_checked(mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(mutate)


def test_every_place_a_tier1_problem_or_clue_uses_lies_in_a_room():
    # Otherwise the 3D game has no station for it: the problem is never spotted there and its
    # clues there are never found (connections.permit: permits_in_batches, 2026-10-18).
    docs = bc.load_content()
    in_room = {p for r in docs["world"]["rooms"] for p in r["places"]}
    missing = set()
    for p in docs["problems_tier1"]["problems"]:
        for place in {p["step"]} | {c.get("at", p["step"]) for c in p.get("clues", [])}:
            if place not in in_room:
                missing.add(f"{p['id']}: {place}")
    assert not missing, sorted(missing)


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
     w["floors"].append({"id": "roof", "level": 3, "name": "Dak", "model": "office.glb"}),
     "floor 'roof' has no rooms"),
    # Phase 1 review S5: a typo in a model would load the stand-in office.
    (lambda w: w["floors"][2].update(model="office_secnd.glb"), "office_secnd.glb.*does not exist"),
])
def test_world_errors_are_caught(mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(mutate)
