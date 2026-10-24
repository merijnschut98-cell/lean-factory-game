"""The tells (PLAN 2.6, design §1.5): problems_tier1.yaml `tells:` names which prop on the 1e, the
2e, the begane grond or the yard shows a problem's symptom. Every listed tell exists, its text never names the
problem, and every problem whose place is on a floor with tells has at least one on that floor."""
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


def test_the_tells_cover_every_room_of_the_1e_the_2e_the_begane_grond_and_the_yard():
    rooms_with_tells = set(bc.TELLS.values())
    assert rooms_with_tells == {"connections", "revision_gis", "meter_data",
                                "directors_obeya", "grid_strategy", "congestion_desk",
                                "contact_centre",
                                "magazijn", "werkplaats", "van_park"}
    shown = {p["id"]: [t["tell"] for t in p.get("tells", [])] for p in REAL["problems_tier1"]["problems"]}
    assert "intake_stack" in shown["incomplete_application"]
    assert "prep_tray" in shown["custom_design"]
    assert "planning_board" in shown["planning_reshuffle"]
    assert "revision_cabinet" in shown["revision_backlog"]
    assert "close_out_cabinet" in shown["done_but_not_closed"]
    assert "meter_board" in shown["silent_meter"]
    assert "grid_study_tray" in shown["grid_study_queue"]
    assert "reinforcement_board" in shown["transformer_wait"]
    assert "congestion_list" in shown["unused_capacity"]
    assert "obeya_board" in shown["silo_kpis"]
    assert "terugbelbord" in shown["status_callers"]


def test_every_problem_on_the_2e_needs_a_tell():
    def mutate(docs):
        _problem(docs, "unused_capacity").pop("tells")
    with pytest.raises(bc.ContentError, match="unused_capacity.*no tell"):
        _check(mutate)


def test_a_look_in_a_room_without_places_is_filed_under_its_room():
    assert "place" not in _look(REAL, "obeya_board") and _look(REAL, "obeya_board")["room"] == "directors_obeya"

    def elsewhere(docs):
        _look(docs, "obeya_board")["room"] = "mt_room"
    with pytest.raises(bc.ContentError, match="obeya_board.*room"):
        _check(elsewhere)


def test_a_look_names_a_place_or_its_room_never_both():
    docs = copy.deepcopy(REAL)
    _look(docs, "obeya_board")["place"] = "connections.design"
    with pytest.raises(bc.ContentError, match="obeya_board"):
        bc.validate_world(docs["world"], "world.yaml")
    docs = copy.deepcopy(REAL)
    _look(docs, "obeya_board").pop("room")
    with pytest.raises(bc.ContentError, match="obeya_board"):
        bc.validate_world(docs["world"], "world.yaml")


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


def test_a_problem_off_the_floors_with_tells_needs_no_tell():
    """A room on a floor with no tells at all (here a made-up attic) asks for none."""
    def mutate(docs):
        rooms = docs["world"]["rooms"]
        next(r for r in rooms if r["id"] == "contact_centre")["places"].remove("customer_contact.answer")
        rooms.append({"id": "attic", "floor": "attic", "name": "Zolder", "places": ["customer_contact.answer"],
                      "opens_with": []})
        docs["world"]["floors"].append({"id": "attic", "name": "Zolder", "level": 3, "model": "x.glb"})
        _look(docs, "terugbelbord").pop("place")
        _look(docs, "terugbelbord")["room"] = "contact_centre"
        _problem(docs, "status_callers").pop("tells")
    _check(mutate)


def test_every_problem_on_the_begane_grond_needs_a_tell():
    """R-1 #4: the KCC's callback board shows the status callers (PLAN 2.6: every active tier-1
    problem has a tell)."""
    def mutate(docs):
        _problem(docs, "status_callers").pop("tells")
    with pytest.raises(bc.ContentError, match="status_callers.*no tell"):
        _check(mutate)


def test_the_yard_shows_its_field_problems():
    """PLAN 2.6 (S3-Y): the werf shows the field work as the 1e and the 2e show the office work."""
    shown = {p["id"]: [t["tell"] for t in p.get("tells", [])] for p in REAL["problems_tier1"]["problems"]}
    assert "uitgiftelijst" in shown["wrong_joint_in_van"]
    assert "storingsbord" in shown["wrong_joint_in_van"]
    assert "storingsbord" in shown["digging_damage"]
    assert "magazijn_rack" in shown["digging_damage"]
    assert "storingsbord" in shown["knowledge_drain"]
    assert "van_returns" in shown["not_at_home"]
    assert "van_returns" in shown["double_visits"]
    assert "van_returns" in shown["installer_not_ready"]
    assert "measurement_tray" in shown["inverters_tripping"]


def test_every_problem_on_the_yard_needs_a_tell():
    def mutate(docs):
        _problem(docs, "knowledge_drain").pop("tells")
    with pytest.raises(bc.ContentError, match="knowledge_drain.*no tell"):
        _check(mutate)


def test_a_problem_needs_a_tell_on_its_own_floor():
    """Meterkast niet gereed shows on the planners' board upstairs too, but its place is on the
    yard: a tell only on the 1e leaves the yard silent about it."""
    def mutate(docs):
        _problem(docs, "installer_not_ready")["tells"] = [
            t for t in _problem(docs, "installer_not_ready")["tells"] if t["tell"] == "planning_board"]
    with pytest.raises(bc.ContentError, match="installer_not_ready.*no tell"):
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


@pytest.mark.parametrize("problem_id, giveaways", [
    # The street-level insight is the investigation's to find (review of 3c40ed8..381d21c #5).
    ("inverters_tripping", ["dezelfde straten", "straat"]),
    # The van kanban wall is wrong_joint_in_van's countermeasure, its empty column the root cause (#3).
    ("wrong_joint_in_van", ["kanban", "bestellen", "kaartje", "aanvul"]),
    # The root cause (no word about progress after the application) is the investigation's (R-1 #4).
    ("status_callers", ["voortgang", "niets meer", "geen bericht", "wachttijd", "faalvraag"]),
])
def test_a_tell_is_a_neutral_observation_never_the_cause_or_the_fix(problem_id, giveaways):
    for tell in _problem(REAL, problem_id)["tells"]:
        for word in giveaways:
            assert word not in tell["text"].lower(), (tell["tell"], word)


def test_henks_one_point_lessons_cost_what_their_estimate_says():
    """Review of 3c40ed8..381d21c #6 (a countermeasure, tested here beside its problem's tell):
    ten half-day lessons for Henk and a young monteur is 80 hours of the monteurs' time; it
    stays the cheapest option in money."""
    cms = {c["id"]: c for c in REAL["countermeasures"]["countermeasures"]}
    lessons = cms["henks_one_point_lessons"]
    assert lessons["team_hours"] == {"monteurs": 80}
    for other in _problem(REAL, "knowledge_drain")["countermeasures"]:
        assert lessons["budget"] <= min(3000, cms[other]["budget"]), other


def test_the_callback_board_shows_volume_and_repeats_not_the_question():
    """Review 381d21c..0ec040f #5: looking gives what anyone sees (how many slips, names twice),
    never what the callers ask: that is the listen-in's key clue (status_callers:0)."""
    board = REAL["world"]["tells"]
    lines = [t["text"] for t in _problem(REAL, "status_callers")["tells"]]
    lines += [t[h] for t in board if t["id"] == "terugbelbord" for h in bc.TELL_HEIGHTS]
    for line in lines:
        for word in ("aansluiting", "wanneer", "waar blijft"):
            assert word not in line.lower(), f"{line!r} says what they ask"
