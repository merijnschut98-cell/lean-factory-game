"""Tests for the dialog content (content/dialogs.yaml) in tools/build_content.py.

Design: docs/superpowers/specs/2026-10-15-dialog-system-design.md §9.
"""
from __future__ import annotations

import copy
from pathlib import Path

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture(scope="module")
def real() -> dict:
    """The real content files as plain YAML documents (unvalidated)."""
    return {p.stem: yaml.safe_load(p.read_text(encoding="utf-8")) for p in sorted(bc.CONTENT_DIR.glob("*.yaml"))}


def _load(tmp_path: Path, docs: dict) -> dict:
    content = tmp_path / "content"
    content.mkdir(exist_ok=True)
    for stem, doc in docs.items():
        (content / f"{stem}.yaml").write_text(yaml.safe_dump(doc, allow_unicode=True), encoding="utf-8")
    return bc.load_content(content)


def _dialog(docs: dict, dialog_id: str) -> dict:
    return next(d for d in docs["dialogs"]["dialogs"] if d["id"] == dialog_id)


def _person(docs: dict, person_id: str) -> dict:
    return next(p for p in docs["dialogs"]["people"] if p["id"] == person_id)


def _layer(docs: dict, dialog_id: str, layer_id: str) -> dict:
    return next(layer for layer in _dialog(docs, dialog_id)["layers"] if layer["id"] == layer_id)


def test_the_sample_dialogs_are_built():
    docs = bc.load_content()
    ids = [d["id"] for d in docs["dialogs"]["dialogs"]]
    assert {"joost_output_kpi", "frank_kpi_targets", "ahmed_after_henk"} <= set(ids)
    assert bc.stale_files(docs) == [], "run: python tools/build_content.py"


def test_a_learned_concern_adds_a_clue_only_its_dialog_reveals():
    docs = bc.load_content()
    concern = next(layer for layer in _dialog(docs, "joost_output_kpi")["layers"] if layer["id"] == "concern")
    clue_id = concern["unlocks"]["clue"]
    problem_id, index = clue_id.split(":")
    problem = next(p for p in docs["problems_tier1"]["problems"] if p["id"] == problem_id)
    clue = problem["clues"][int(index)]
    assert problem_id == "silo_kpis"
    assert clue["dialog"] == "joost_output_kpi", "marked, so no gemba tool or quick question finds it"
    assert clue["tool"] == "conversation" and clue["at"] == "connections.design" and clue["key"]
    assert clue["depth"] == 2


def test_dialogs_are_optional_for_a_content_set_without_people(tmp_path, real):
    docs = {stem: doc for stem, doc in real.items() if stem != "dialogs"}
    assert "dialogs" not in _load(tmp_path, docs)


def test_the_vocabulary_lists_the_dialog_words():
    vocab = bc.load_content()["vocabulary"]
    assert vocab["dialog_moves"][:8] == ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry",
                                         "experience", "silence"]
    assert "ask_commitment" in vocab["dialog_moves"] and "close" in vocab["dialog_moves"]
    assert vocab["dialog_tags"] == ["claim", "feeling", "hesitation", "admission", "doubt"]
    assert "rule_bound" in vocab["dialog_archetypes"]
    assert vocab["dialog_outcomes"] == ["commitment", "partial", "heard", "none", "blocked", "compliance", "ruined",
                                        "lifted"]


def _drop_route(d: dict) -> None:
    _dialog(d, "frank_kpi_targets")["block"]["routes"] = [
        {"needs": {"all": ["chose:knowledge_drain:skills_matrix_buddy"]}, "hint": "Alleen met Henks buddy."}]


@pytest.mark.parametrize("mutate, message", [
    (lambda d: _dialog(d, "joost_output_kpi").update(person="nobody"), "unknown person"),
    (lambda d: _person(d, "joost").update(archetype="grumpy"), "archetype"),
    (lambda d: _person(d, "joost").update(place="connections.permit"), "place"),
    (lambda d: _person(d, "joost").update(team="ghosts"), "team"),
    (lambda d: _person(d, "joost").update(trust=120), "trust"),
    (lambda d: _dialog(d, "joost_output_kpi").update(colour="blue"), "unknown key"),
    (lambda d: _dialog(d, "joost_output_kpi").update(kind="chat"), "kind"),
    (lambda d: _dialog(d, "joost_output_kpi").update(mission="fix_nothing"), "unknown mission"),
    (lambda d: _dialog(d, "joost_output_kpi").update(owns="custom_design"), "owns"),
    (lambda d: _dialog(d, "joost_output_kpi").update(kpi_team="ghosts"), "kpi_team"),
    (lambda d: _dialog(d, "joost_output_kpi")["proposals"][0].update(kpis=["intake_output"]), "not on the menu"),
    (lambda d: _dialog(d, "joost_output_kpi")["proposals"][0].update(kpis=[]), "one or two"),
    (lambda d: _dialog(d, "joost_output_kpi").update(requires_clue="silo_kpis:99"), "unknown clue"),
    (lambda d: _dialog(d, "joost_output_kpi").update(data=["custom_design:0"]), "mission's problem"),
    (lambda d: _dialog(d, "joost_output_kpi").update(mood="blij"), "mood"),
    (lambda d: _layer(d, "joost_output_kpi", "interest").update(at=30), "between 40 and 65"),
    (lambda d: _layer(d, "joost_output_kpi", "concern").update(at=95), "between 60 and 85"),
    (lambda d: _layer(d, "joost_output_kpi", "interest").update(via=["inquiry"]), "two"),
    (lambda d: _layer(d, "joost_output_kpi", "interest").update(via=["inquiry", "shout"]), "unknown move"),
    (lambda d: _layer(d, "joost_output_kpi", "interest").update(tags=["angry"]), "unknown tag"),
    (lambda d: _layer(d, "joost_output_kpi", "concern")["lead_in"].update(tags=["claim"]), "hesitation"),
    (lambda d: _layer(d, "joost_output_kpi", "concern").pop("lead_in"), "lead_in"),
    (lambda d: _layer(d, "joost_output_kpi", "concern").update(wait_for=3), "wait_for"),
    (lambda d: _layer(d, "joost_output_kpi", "interest").update(wait_for="Frank."), "without a condition"),
    (lambda d: _dialog(d, "joost_output_kpi")["layers"].reverse(), "interest, then concern"),
    (lambda d: _layer(d, "joost_output_kpi", "concern")["unlocks"].update(facts=["loved:joost"]), "fact"),
    (lambda d: _layer(d, "joost_output_kpi", "concern")["unlocks"].update(proposals=["lead_and_oldest"]), "hidden"),
    (lambda d: _layer(d, "joost_output_kpi", "concern")["unlocks"]["clue"].update(depth=9), "depth"),
    (lambda d: [p.update(addresses=[]) for p in _dialog(d, "joost_output_kpi")["proposals"]
                + _dialog(d, "joost_output_kpi")["experiments"]], "no single right answer"),
    (lambda d: _dialog(d, "joost_output_kpi").update(co_proposal={"id": "lead_and_oldest", "text": "Ja."}), "hidden"),
    (lambda d: _dialog(d, "joost_output_kpi").update(condition_needs={"some": ["committed:frank_kpi_targets"]}),
     "unknown key"),
    (lambda d: _dialog(d, "joost_output_kpi").update(condition_needs={"all": ["committed:nobody"]}), "unknown dialog"),
    (lambda d: _dialog(d, "joost_output_kpi")["outcomes"].update(victory="Ja!"), "outcome"),
    (lambda d: _dialog(d, "joost_output_kpi")["lines"].update(shout="Hé!"), "unknown move"),
    (lambda d: _dialog(d, "joost_output_kpi")["replies"].update(mood={"loudly": {"text": "Ja."}}), "situation"),
    (lambda d: _dialog(d, "joost_output_kpi").update(opening=" "), "opening"),
    (lambda d: _dialog(d, "joost_output_kpi").update(tutorial="yes"), "tutorial"),
    (lambda d: d["dialogs"]["bank"]["special"].pop("no_repair"), "no_repair"),
    (_drop_route, "never game over"),
    (lambda d: _dialog(d, "ahmed_after_henk").update(mission="fix_silo_kpis"), "check-in"),
    (lambda d: _dialog(d, "ahmed_after_henk").pop("trigger"), "trigger"),
    (lambda d: _dialog(d, "ahmed_after_henk")["proposals"][0].update(kpis=["work_prep_ftr"]), "check-in"),
    (lambda d: _dialog(d, "ahmed_after_henk")["variants"][0].update(needs={"all": ["chose:knowledge_drain:magic"]}),
     "does not list that countermeasure"),
    (lambda d: d["dialogs"]["bank"]["player"].pop("silence"), "silence"),
    (lambda d: d["dialogs"]["bank"]["replies"]["reflect"].pop("misses"), "reflect"),
    (lambda d: d["dialogs"]["bank"]["special"].pop("repeat"), "repeat"),
    (lambda d: d["dialogs"]["bank"]["outcomes"].pop("ruined"), "ruined"),
])
def test_dialog_errors_are_caught(tmp_path, real, mutate, message):
    docs = copy.deepcopy(real)
    mutate(docs)
    with pytest.raises(bc.ContentError, match=message):
        _load(tmp_path, docs)


def _talk_mission(real: dict, goal: dict) -> dict:
    """The real content with Frank's talk as a side mission's goal."""
    docs = copy.deepcopy(real)
    side = copy.deepcopy(next(m for m in docs["missions"]["missions"] if m["id"] == "fix_wrong_joint"))
    side.update({"id": "talk_frank", "goal": goal})
    for key in ("fail_closes", "deadline_days", "check_days", "fork", "debrief_variants", "setup"):
        side.pop(key, None)
    docs["missions"]["missions"].append(side)
    frank = _dialog(docs, "frank_kpi_targets")
    frank["mission"] = "talk_frank"
    frank.pop("data")  # a talk_to mission holds no problem to show data of
    return docs


def test_a_talk_goal_names_a_dialog_of_its_own_mission(real, tmp_path):
    _load(tmp_path, _talk_mission(real, {"type": "talk_to", "dialog": "frank_kpi_targets", "outcome": "partial"}))
    with pytest.raises(bc.ContentError, match="unknown dialog"):
        _load(tmp_path, _talk_mission(real, {"type": "talk_to", "dialog": "nobody_talk"}))
    with pytest.raises(bc.ContentError, match="belongs to mission"):
        _load(tmp_path, _talk_mission(real, {"type": "talk_to", "dialog": "joost_output_kpi"}))
    with pytest.raises(bc.ContentError, match="outcome"):
        _load(tmp_path, _talk_mission(real, {"type": "talk_to", "dialog": "frank_kpi_targets", "outcome": "heard"}))


def test_the_coach_s_talk_questions_are_checked(real, tmp_path):
    docs = copy.deepcopy(real)
    docs["dialogs"]["bank"]["coach"]["after"]["heard"] = "Hoe was het?"
    with pytest.raises(bc.ContentError, match="after"):
        _load(tmp_path, docs)
    docs = copy.deepcopy(real)
    docs["dialogs"]["bank"]["coach"]["questions"] = []
    with pytest.raises(bc.ContentError, match="questions"):
        _load(tmp_path, docs)
