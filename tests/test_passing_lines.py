"""What people say in passing (Phase 2 design §1.4): greetings, quick lines, coffee chatter.

content/dialogs.yaml `greetings:`, `quick:`, `chatter:`, validated by tools/build_content.py:
every office person has three ordinary greetings, the shared lines cover every fact and mood,
a chatter is two lines with known teams and load, and every line is spoken (no banned word).
"""
from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture(scope="module")
def real() -> dict:
    return {p.stem: yaml.safe_load(p.read_text(encoding="utf-8")) for p in sorted(bc.CONTENT_DIR.glob("*.yaml"))}


def _load(tmp_path: Path, docs: dict) -> dict:
    content = tmp_path / "content"
    content.mkdir(exist_ok=True)
    for stem, doc in docs.items():
        (content / f"{stem}.yaml").write_text(yaml.safe_dump(doc, allow_unicode=True), encoding="utf-8")
    return bc.load_content(content)


def _cast() -> list[dict]:
    return json.loads(bc.CAST_FILE.read_text(encoding="utf-8"))["characters"]


def test_every_office_person_has_three_ordinary_greetings(real):
    greetings = real["dialogs"]["greetings"]
    people = [c["id"] for c in _cast() if c["id"] != "player"]
    assert "yvonne" in people
    for pid in people:
        assert len(greetings[pid]["day"]) >= 3, pid


def test_the_shared_lines_cover_every_fact_and_mood(real):
    assert set(real["dialogs"]["greetings"]["_all"]) == set(bc.GREETING_FACTS)
    assert set(real["dialogs"]["quick"]["_all"]) == set(bc.QUICK_MOODS)
    assert len(real["dialogs"]["chatter"]) >= 10


def test_weekend_chatter_waits_for_the_end_of_the_week(real):
    """A chatter's `days` (mon..sun): the weekend's plans come up on Thursday or Friday."""
    weekend = next(c for c in real["dialogs"]["chatter"] if c["id"] == "weekend")
    assert weekend["days"] and "mon" not in weekend["days"]


def test_the_real_lines_build_and_are_spoken(real):
    texts = [t for _, t in bc.spoken_texts(real)]
    assert real["dialogs"]["greetings"]["sanne"]["day"][0] in texts
    assert real["dialogs"]["quick"]["_all"]["busy"][0] in texts
    assert real["dialogs"]["chatter"][0]["lines"][1] in texts


@pytest.mark.parametrize("mutate, message", [
    (lambda d: d["greetings"]["sanne"].__setitem__("day", ["Hoi.", "Hé."]), "sanne.*three ordinary"),
    (lambda d: d["greetings"].__setitem__("nobody", {"day": ["a", "b", "c"]}), "nobody.*not in the cast"),
    (lambda d: d["greetings"]["sanne"].__setitem__("cheered", ["Hoi."]), "sanne.*unknown key"),
    (lambda d: d["greetings"].pop("yvonne"), "yvonne.*three ordinary"),
    (lambda d: d["quick"]["_all"].pop("late"), "quick _all.*late"),
    (lambda d: d["quick"]["sanne"].__setitem__("grumpy", ["Hm."]), "quick sanne.*unknown key"),
    (lambda d: d["chatter"][0]["lines"].append("En verder?"), "chatter intake_half_requests.*two lines"),
    (lambda d: d["chatter"][0].__setitem__("teams", ["kantine"]), "chatter intake_half_requests.*team"),
    (lambda d: d["chatter"][0].__setitem__("load", "vol"), "chatter intake_half_requests.*load"),
    (lambda d: d["chatter"][0].__setitem__("days", ["vrijdag"]), "chatter intake_half_requests: days lists"),
    (lambda d: d["chatter"][0].__setitem__("days", []), "chatter intake_half_requests: days lists"),
    (lambda d: d["greetings"]["sanne"]["day"].__setitem__(0, ""), "sanne.*text"),
])
def test_passing_line_errors_are_caught(real, tmp_path, mutate, message):
    docs = copy.deepcopy(real)
    mutate(docs["dialogs"])
    with pytest.raises(bc.ContentError, match=message):
        _load(tmp_path, docs)


def test_a_banned_word_in_a_greeting_fails_the_build(real):
    docs = copy.deepcopy(real)
    docs["dialogs"]["greetings"]["sanne"]["day"][0] = "Hoi {speler}, klaar voor het volgende level?"
    with pytest.raises(bc.ContentError, match="greetings.*names the game"):
        bc.check_spoken(docs)


@pytest.mark.parametrize("characters", [["sanne"], [None], [{"name": "zonder id"}], "sanne"])
def test_a_damaged_cast_is_a_content_error(tmp_path, monkeypatch, characters):
    cast = tmp_path / "cast.json"
    cast.write_text(json.dumps({"characters": characters}), encoding="utf-8")
    monkeypatch.setattr(bc, "CAST_FILE", cast)
    with pytest.raises(bc.ContentError, match="cannot read the cast"):
        bc._cast_ids()
