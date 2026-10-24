"""Nothing is handed over (CLAUDE.md; review 381d21c..0ec040f #4): a mission's name and
briefing, and a tell's line, never repeat a key clue of the problem they are about (five words
in a row, as the company file's check). The key clue is the player's to find."""
from __future__ import annotations

import copy
import re

import pytest

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture(scope="module")
def real() -> dict:
    return bc.load_content()


def _mission(docs: dict, mission_id: str) -> dict:
    return next(m for m in docs["missions"]["missions"] if m["id"] == mission_id)


def _problem(docs: dict, problem_id: str) -> dict:
    return next(p for stem, doc in docs.items() if stem.startswith("problems") for p in doc["problems"]
                if p["id"] == problem_id)


def _key_clue(docs: dict, problem_id: str) -> str:
    return next(c["text"] for c in _problem(docs, problem_id)["clues"] if c["key"])


def test_the_real_content_hands_over_no_key_clue(real):
    bc.check_clue_spoilers(real)


def test_ilse_s_briefing_gives_her_struggle_not_the_empty_halls(real):
    briefing = _mission(real, "fix_unused_capacity")["briefing"].lower()
    for word in ("hal", "hallen", "donker", "leeg", "lege"):
        assert not re.search(rf"\b{word}\b", briefing), f"the briefing says {word!r}: that is the clue's to find"
    for struggle in ("twee jaar", "acm"):
        assert struggle in briefing


def _spoiled(real: dict, mutate) -> None:
    docs = copy.deepcopy(real)
    mutate(docs)
    bc.check_clue_spoilers(docs)


@pytest.mark.parametrize("mutate, message", [
    (lambda d: _mission(d, "fix_unused_capacity").update(
        briefing="Ilse zegt: '" + _key_clue(d, "unused_capacity") + "'"),
     "mission 'fix_unused_capacity' briefing repeats key clue 'unused_capacity:"),
    (lambda d: _mission(d, "fix_wrong_joint").update(name=_key_clue(d, "wrong_joint_in_van")),
     "mission 'fix_wrong_joint' name repeats key clue 'wrong_joint_in_van:"),
    (lambda d: _mission(d, "fix_wrong_joint").update(reopen=_key_clue(d, "wrong_joint_in_van")),
     "mission 'fix_wrong_joint' reopen repeats key clue"),
    (lambda d: _problem(d, "status_callers")["tells"][0].update(text=_key_clue(d, "status_callers")),
     "problem 'status_callers' tell .* repeats key clue 'status_callers:"),
    (lambda d: next(t for t in d["world"]["tells"] if t["id"] == _problem(d, "status_callers")["tells"][0]["tell"])
     .update(high=_key_clue(d, "status_callers")),
     "world.yaml tell .* high repeats key clue 'status_callers:"),
])
def test_a_text_that_repeats_a_key_clue_is_caught(real, mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _spoiled(real, mutate)
