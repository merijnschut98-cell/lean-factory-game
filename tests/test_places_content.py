"""What a player can do at a place (content/places.yaml, PLAN 2.12; spec
docs/superpowers/specs/2026-10-18-place-actions.md §6) in the content pipeline: the tools that fit,
their observations, the questions to the people there, the tool cards and the training week's
growing toolbox (grant_tools). One failing fixture per validator rule."""
from __future__ import annotations

import copy

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}
INTAKE = "connections.intake"
DESIGN = "connections.design"


def _check(mutate) -> None:
    docs = copy.deepcopy(REAL)
    mutate(docs)
    bc.validate_places(docs["places"], "places.yaml")
    bc.validate_missions(docs["missions"], "missions.yaml")
    bc.check_places(docs)


def _place(docs: dict, place: str) -> dict:
    return docs["places"]["places"][place]


def _mission(docs: dict, mission_id: str) -> dict:
    return next(m for m in docs["missions"]["missions"] if m["id"] == mission_id)


def test_the_real_places_pass_and_cover_the_monday_places_with_people_to_ask():
    docs = bc.load_content()
    places = docs["places"]["places"]
    for place in (INTAKE, DESIGN):
        assert places[place]["questions"], f"someone to ask at {place}"
    assert [t["tool"] for t in places[INTAKE]["tools"]] == ["listen_in", "documents", "queue_count", "data"], \
        "the build keeps the content's order"


def test_no_time_study_where_work_is_not_timed():
    for place in (INTAKE, "connections.planning", "meters.registration"):
        assert "time_study" not in REAL["places"]["places"][place]["tools"], place


def test_nothing_says_there_is_nothing_new():
    for path in list((bc.ROOT / "game" / "src").rglob("*.gd")) + list(bc.CONTENT_DIR.glob("*.yaml")):
        assert "Je vindt hier niets nieuws" not in path.read_text(encoding="utf-8"), path


def test_the_places_file_is_optional_for_a_content_set():
    assert "places" in bc.OPTIONAL


def _drop(docs: dict, place: str) -> None:
    del docs["places"]["places"][place]


def _drop_tool(docs: dict, place: str, tool: str) -> None:
    del _place(docs, place)["tools"][tool]


def _only_closed_questions(docs: dict) -> None:
    _place(docs, DESIGN)["questions"] = [q for q in _place(docs, DESIGN)["questions"]
                                         if bc.QUESTION_KINDS[q["id"]] != "open"]


def _drop_people_also(docs: dict) -> None:
    _place(docs, "connections.commissioning").pop("people_also")


def _move_grant(docs: dict) -> None:
    _mission(docs, "training_wed")["grant_tools"] = []
    _mission(docs, "training_thu")["grant_tools"].append("queue_count")


def _no_conversation_on_monday(docs: dict) -> None:
    _mission(docs, "training_mon")["grant_tools"] = []
    _mission(docs, "training_tue")["grant_tools"].append("conversation")


def _ask_twice(docs: dict) -> None:
    qs = _place(docs, INTAKE)["questions"]
    qs[1] = dict(qs[1], id=qs[0]["id"])


@pytest.mark.parametrize("mutate, message", [
    # 1. every place used has an entry (a problem, a mission's walk, a discovery, a room)
    (lambda d: _drop(d, DESIGN), "has no entry"),
    (lambda d: _drop(d, "outages.report"), "has no entry"),
    (lambda d: _drop(d, "connections.close_out_wait"), "has no entry"),
    (lambda d: d["places"]["places"].__setitem__("connections.nowhere", _place(d, INTAKE)), "unknown place"),
    # 2. 2-5 tools, never conversation, a label and 2-3 observations
    (lambda d: _place(d, INTAKE)["tools"].__setitem__("conversation", {"label": "x", "observations": ["a", "b"]}),
     "a conversation is the place's questions"),
    (lambda d: _place(d, "voltage_complaints.analysis")["tools"].pop("documents"), "must map 2 to 5 tools"),
    (lambda d: _place(d, INTAKE)["tools"]["data"].__setitem__("observations", ["Alleen."]), "2 to 3 observations"),
    (lambda d: _place(d, INTAKE)["tools"]["data"].__setitem__("label", ""), "label"),
    (lambda d: _place(d, INTAKE)["tools"]["data"]["observations"].__setitem__(0, "Je vindt hier niets nieuws."),
     "niets nieuws"),
    # 3. every clue reachable
    (lambda d: _drop_tool(d, DESIGN, "time_study"), "the tool does not fit the place"),
    (_only_closed_questions, "no open question there"),
    # 4. questions: at most 4, no thanks, no id twice, someone who is here
    (lambda d: _place(d, INTAKE)["questions"].append(dict(_place(d, INTAKE)["questions"][0], id="ok")), "at most 4"),
    (lambda d: _place(d, DESIGN)["questions"].__setitem__(0, dict(_place(d, DESIGN)["questions"][0], id="thanks")),
     "must be one of"),
    (_ask_twice, "asked twice"),
    (lambda d: _place(d, INTAKE)["questions"].__setitem__(0, dict(_place(d, INTAKE)["questions"][0], person="anouk")),
     "anouk is not here"),
    (_drop_people_also, "ahmed is not here"),
    (lambda d: _place(d, INTAKE).__setitem__("people_also", ["nobody"]), "unknown person"),
    # 5. a discovery's place and tool fit
    (lambda d: _drop_tool(d, "connections.revision", "documents"), "discovery .* needs documents"),
    # 6. the week grants each tool once, conversation first, before a goal needs it
    (_move_grant, "needs queue_count, not granted by its day"),
    (_no_conversation_on_monday, "the first day grants conversation"),
    (lambda d: _mission(d, "training_fri").__setitem__("grant_tools", ["data"]), "exactly once"),
    (lambda d: _mission(d, "fix_custom_design").__setitem__("grant_tools", ["data"]), "only a training day"),
    (lambda d: _mission(d, "training_wed")["goal"].__setitem__("tool", "material_check"), "not granted|does not fit"),
    (lambda d: d["missions"]["missions"][0].__setitem__("grant_tools", ["stopwatch"]), "unknown tool"),
    # 7. one tool card per tool
    (lambda d: d["places"]["tool_cards"].pop(), "one card per tool"),
])
def test_the_places_rules(mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(mutate)


def test_an_observe_goal_needs_as_many_different_actions_as_it_asks():
    def mutate(docs: dict) -> None:
        _mission(docs, "training_tue")["goal"]["uses"] = 7
    with pytest.raises(bc.ContentError, match="different actions"):
        _check(mutate)


def test_places_awaiting_content_are_only_those_still_without_an_entry():
    # The exemption shrinks as the designer writes them; an entry written must leave the set.
    assert not bc.PLACES_AWAITING_CONTENT & set(REAL["places"]["places"])
