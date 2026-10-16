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
    # Ruud names a move after an Act 0 talk, and the cards name them (tutorial talks spec §2, §3).
    (lambda d: d["dialogs"]["bank"]["ruud_names"].pop("silence"), "ruud_names"),
    (lambda d: d["dialogs"]["bank"]["ruud_names"].pop("week_end"), "ruud_names"),
    (lambda d: d["dialogs"]["move_cards"][0].update(move="shout"), "move card"),
    (lambda d: d["dialogs"]["move_cards"][0].update(day="fix_nothing"), "move card"),
    (lambda d: d["dialogs"]["move_cards"][0].pop("why"), "move card"),
    # The Act 0 talks name the day's move (tutorial talks spec §5).
    (lambda d: _dialog(d, "joost_output_kpi").update(teaches=["mood"]), "'teaches' only on a tutorial"),
    (lambda d: _dialog(d, "joost_output_kpi").update(tutorial=True, teaches=["shout"]), "'teaches' names listening"),
    (lambda d: _dialog(d, "joost_output_kpi").update(tutorial=True, teaches=["propose"]), "'teaches' names listening"),
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
    # Tier-1 content audit C8, C9 and the four-tier audit's cue rule (T4).
    (lambda d: d["dialogs"]["bank"]["replies"]["open_question"]["lands"].update(tags=["claim"]), "no claim or feeling"),
    (lambda d: _dialog(d, "joost_output_kpi")["outcomes"].pop("heard"), "authors its own outcome"),
    (lambda d: _dialog(d, "frank_kpi_targets")["outcomes"].pop("blocked"), "authors its own outcome"),
    (lambda d: _layer(d, "sanne_kpi", "concern").update(via=["reflect", "silence"]), "feeling"),
    (lambda d: _layer(d, "sanne_kpi", "concern").update(via=["empathy", "inquiry"]), "feeling"),
    (lambda d: _dialog(d, "joost_output_kpi")["proposals"][0].pop("say"), "say"),
    # Person needs and moves that wear out (person-needs spec §6, N5, N7, N8).
    (lambda d: _person(d, "joost").update(need="love"), "need"),
    (lambda d: _person(d, "joost").pop("need"), "need"),
    (lambda d: _dialog(d, "joost_output_kpi").update(need="speed"), "need"),
    (lambda d: d["dialogs"]["bank"]["wear_out"].pop("cynic"), "wear_out"),
    (lambda d: d["dialogs"]["bank"]["wear_out"]["quiet"].pop("say"), "wear_out"),
    (lambda d: _dialog(d, "frank_kpi_targets")["position"].update(tell="safety"), "tell"),
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
    frank.pop("owns")  # nor a problem to own, so no clue to unlock
    frank["layers"][1]["unlocks"].pop("clue")
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


def test_only_a_checkin_has_a_dagstart_prompt(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "joost_output_kpi")["prompt"] = "Joost is stil."
    with pytest.raises(bc.ContentError, match="prompt"):
        _load(tmp_path, docs)


def test_a_checkin_may_wait_for_a_mission_taken_on(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "ahmed_after_henk")["trigger"]["needs"] = {"all": ["accepted:fix_status_callers"]}
    _load(tmp_path, docs)
    _dialog(docs, "ahmed_after_henk")["trigger"]["needs"] = {"all": ["accepted:no_such_mission"]}
    with pytest.raises(bc.ContentError, match="no such mission"):
        _load(tmp_path, docs)


def test_a_warning_line_is_text(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "joost_output_kpi")["warning"] = ["Ik ga dit niet nog een keer uitleggen."]
    with pytest.raises(bc.ContentError, match="warning"):
        _load(tmp_path, docs)


def test_a_proposal_has_a_chip_label_and_a_spoken_line(real, tmp_path):
    """Tier-1 content audit C1, Q1: `label` (the chip) and `say` (the player's
    line), built as the engine's name and text."""
    proposal = _dialog(_load(tmp_path, copy.deepcopy(real)), "joost_output_kpi")["proposals"][0]
    assert proposal["name"] == "Doorlooptijd + oudste dossier" and proposal["text"].startswith("Wat als je")
    assert "label" not in proposal and "say" not in proposal


def test_frank_sets_the_fact_the_arc_reads(real):
    """Tier-1 content audit C4: the interim MT reads heard:frank_budget."""
    concern = _layer(real, "frank_kpi_targets", "concern")
    assert "heard:frank_budget" in concern["unlocks"]["facts"] and concern["unlocks"]["clue"]["key"]
    assert len(_dialog(real, "frank_kpi_targets")["block"]["routes"]) >= 2, "C5: the team leads' route too"


def test_no_false_experience_and_no_untracked_promise(real):
    """Tier-1 content audit C2, C3: the player's experience is the CI lead's own."""
    ahmed = _dialog(real, "ahmed_after_henk")["lines"]
    assert "eerste jaar" not in ahmed["experience"] and "Ruud" in ahmed["experience"]
    assert "langs" not in ahmed["close"]
    assert "Toen ik net begon" not in real["dialogs"]["bank"]["player"]["experience"]


def test_a_dialog_may_give_the_person_their_own_worn_line(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "joost_output_kpi")["replies"]["paraphrase"]["worn"] = {"text": "Ja. Dat zei je al."}
    _load(tmp_path, docs)


def test_a_tell_shows_the_person_s_own_need(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "frank_kpi_targets")["position"]["tell"] = "facts"
    _load(tmp_path, docs)


# N7 (person-needs spec §2.1, §5): the needs spread over each tier's speaking cast.
def test_a_tier_s_cast_spreads_its_needs():
    five = {"a": "facts", "b": "safety", "c": "recognition", "d": "time", "e": "fairness"}
    bc.check_need_spread({1: five})
    bc.check_need_spread({2: {"a": "safety", "b": "safety", "c": "facts", "d": "time"}})  # n < 5: not all five
    with pytest.raises(bc.ContentError, match="tier 1.*safety.*3 of 6"):
        bc.check_need_spread({1: {**five, "f": "safety", "e": "safety"}})
    with pytest.raises(bc.ContentError, match="tier 3.*every need.*fairness"):
        bc.check_need_spread({3: {**five, "e": "facts"}})


def test_the_speaking_cast_is_read_per_tier_from_the_missions_acts(real):
    cast = bc.speaking_cast(real)
    assert {"joost": "safety", "sanne": "recognition", "frank": "facts"}.items() <= cast[1].items(), "Act II is tier 1"
    assert cast[1]["anouk"] == "safety", "and so is the Act 0 week"
    assert bc.TIER_OF_ACT == {0: 1, 1: 1, 2: 1, 3: 2, 4: 3, 5: 4, 6: 3}


def _strip_tells(node) -> None:
    if isinstance(node, dict):
        node.pop("tell", None)
    for child in node.values() if isinstance(node, dict) else node if isinstance(node, list) else []:
        _strip_tells(child)


def test_a_crowded_need_in_a_tier_fails_the_build(real, tmp_path):
    docs = copy.deepcopy(real)
    for person in docs["dialogs"]["people"]:
        person["need"] = "safety"
    _strip_tells(docs["dialogs"]["dialogs"])  # they name the old needs
    with pytest.raises(bc.ContentError, match="tier 1.*safety"):
        _load(tmp_path, docs)
