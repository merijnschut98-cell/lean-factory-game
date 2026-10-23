"""Expert talks in content/dialogs.yaml (phase 2 design §2.5; game/src/rules/expert_talk.gd):
topic by topic, no layers or meters; a topic can unlock a clue (inline, merged into the
problem it names), a fact or an explainer, and wait for a fact or for trust."""
from __future__ import annotations

import copy
from pathlib import Path

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture(scope="module")
def real() -> dict:
    return {p.stem: yaml.safe_load(p.read_text(encoding="utf-8")) for p in sorted(bc.CONTENT_DIR.glob("*.yaml"))}


def _expert(**extra) -> dict:
    d = {"id": "petra_expert", "name": "Petra legt uit", "person": "petra", "kind": "expert",
         "opening": "Vraag maar.", "closing": "Graag gedaan.",
         "topics": [
             {"id": "molen", "ask": "Wat is de Molen?", "answer": "Het register.",
              "unlocks": {"clue": {"problem": "silent_meter", "key": False, "depth": 1, "text": "'De Molen.'"},
                          "facts": ["heard:petra_molen"]}},
             {"id": "map", "ask": "Wat staat er in je map?", "answer": "Alles.", "trust": 60,
              "needs": {"all": ["heard:petra_molen"]}},
         ]}
    d.update(extra)
    return d


def _load(tmp_path: Path, real: dict, expert: dict) -> dict:
    docs = copy.deepcopy(real)
    docs["dialogs"]["dialogs"].append(expert)
    content = tmp_path / "content"
    content.mkdir(exist_ok=True)
    for stem, doc in docs.items():
        (content / f"{stem}.yaml").write_text(yaml.safe_dump(doc, allow_unicode=True), encoding="utf-8")
    return bc.load_content(content)


def test_an_expert_talk_builds_and_its_topic_clue_joins_the_problem(tmp_path, real):
    docs = _load(tmp_path, real, _expert())
    built = next(d for d in docs["dialogs"]["dialogs"] if d["id"] == "petra_expert")
    clue_id = built["topics"][0]["unlocks"]["clue"]
    problem = next(p for _, p in bc._all_problems(docs) if p["id"] == "silent_meter")
    assert clue_id == f"silent_meter:{len(problem['clues']) - 1}"
    assert problem["clues"][-1]["dialog"] == "petra_expert"
    assert problem["clues"][-1]["tool"] == "conversation"


@pytest.mark.parametrize("change, message", [
    ({"topics": []}, "needs topics"),
    ({"closing": None}, "closing"),
    ({"layers": []}, "unknown"),
    ({"mission": "no_such_mission"}, "unknown mission"),
    ({"topics": [{"id": "x", "ask": "Wat?"}]}, "answer"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.", "trust": 120}]}, "trust"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.", "unlocks": {"explainer": "no_such"}}]}, "unknown explainer"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.", "unlocks": {"facts": ["loved:petra"]}}]}, "fact"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.", "unlocks": {"clue": "silent_meter:0"}}]}, "mapping"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.",
                  "unlocks": {"clue": {"problem": "nope", "key": True, "depth": 0, "text": "t"}}}]}, "unknown problem"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit.", "needs": {"all": ["heard:never_unlocked"]}}]},
     "no dialog unlocks it"),
    ({"topics": [{"id": "x", "ask": "Wat?", "answer": "Dit is een spel."}]}, "names the game"),
])
def test_expert_errors_are_caught(tmp_path, real, change, message):
    expert = _expert(**change)
    expert = {k: v for k, v in expert.items() if v is not None}
    with pytest.raises(bc.ContentError, match=message):
        _load(tmp_path, real, expert)
