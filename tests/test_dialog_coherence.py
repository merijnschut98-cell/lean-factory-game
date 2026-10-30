"""A talk holds together (Merijn's playtest 2026-10-30; docs/qa/dialog-coherence-2026-10-30.md):
the content checks in tools/build_content.py that keep a person from saying what the
player's own sentences cannot have earned."""
from __future__ import annotations

import copy
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


def _dialog(docs: dict, dialog_id: str) -> dict:
    return next(d for d in docs["dialogs"]["dialogs"] if d["id"] == dialog_id)


def _bank(docs: dict) -> dict:
    return docs["dialogs"]["bank"]


@pytest.mark.parametrize("mutate, message", [
    # "Ja, dat zei je al." after a sentence never said: only the `again` slot may say it.
    (lambda d: _bank(d)["replies"]["empathy"].update(misses={"text": "Ja, dat zei je al."}), "repeat"),
    (lambda d: _bank(d)["replies"]["open_question"].update(misses={"text": "Dat heb ik je net verteld."}), "repeat"),
    (lambda d: _bank(d)["special"].update(refusal="Dat vroeg je net ook."), "repeat"),
    # A wear-out line answers the same kind of sentence in other words: no "you said that".
    (lambda d: _bank(d)["wear_out"]["quiet"].update(say="Mm. Ja. Dat zei je."), "repeat"),
    (lambda d: _dialog(d, "joost_output_kpi").setdefault("replies", {}).update(
        paraphrase={"worn": {"text": "Ja. Dat zei je al."}}), "repeat"),
    (lambda d: _dialog(d, "joost_output_kpi").setdefault("replies", {}).update(
        inquiry={"misses": {"text": "Dat zei ik, ja."}}), "repeat"),
    (lambda d: _dialog(d, "joost_output_kpi")["outcomes"].update(none="Dat zei je al. Tot later."), "repeat"),
    # "Hoe bedoel je?": no turn offers a clarification, so nobody asks for one.
    (lambda d: _bank(d)["replies"]["inquiry"].update(misses={"text": "Hoe bedoel je?"}), "clarif"),
    (lambda d: _bank(d)["replies"]["inquiry"].update(again={"text": "Wat bedoel je nou?"}), "clarif"),
    (lambda d: _dialog(d, "joost_output_kpi")["position"].update(text="Wat bedoel je precies?"), "clarif"),
    # An `again` line is read like the miss it replaces: no tags.
    (lambda d: _bank(d)["replies"]["empathy"].update(again={"text": "Ja, dat zei je al.", "tags": ["doubt"]}), "tags"),
    # Ruud quotes the sentence he names (every listening move but silence, which is no sentence).
    (lambda d: _bank(d)["ruud_names"].update(mood="Je vroeg eerst hoe het met {person} ging."), "{said}"),
    # A talk's own line for a move may answer the layer spoken of last.
    (lambda d: _dialog(d, "joost_output_kpi")["lines"].update(paraphrase={"later": "Dus straks."}), "position"),
    (lambda d: _dialog(d, "joost_output_kpi")["lines"].update(paraphrase={"position": []}), "line"),
    (lambda d: _dialog(d, "joost_output_kpi")["lines"].update(show_data={"position": "Kijk."}), "{data}"),
    # A talk's own reply may answer the layer spoken to, or turn through a list; the bank's stay plain.
    (lambda d: _dialog(d, "joost_output_kpi").setdefault("replies", {}).update(
        inquiry={"lands": {"later": {"text": "Straks."}}}), "position"),
    (lambda d: _dialog(d, "joost_output_kpi").setdefault("replies", {}).update(inquiry={"lands": []}), "line"),
    (lambda d: _dialog(d, "joost_output_kpi").setdefault("replies", {}).update(
        inquiry={"again": {"_": {"text": "Dat vroeg je al.", "tags": ["claim"]}}}), "tags"),
    (lambda d: _bank(d)["replies"]["mood"].update(lands=[{"text": "Goed."}]), "mapping"),
])
def test_incoherent_content_is_rejected(real, tmp_path, mutate, message):
    docs = copy.deepcopy(real)
    mutate(docs)
    with pytest.raises(bc.ContentError, match=message):
        _load(tmp_path, docs)


def test_a_repeat_may_be_said_from_the_again_slot_and_lines_may_answer_a_layer(real, tmp_path):
    docs = copy.deepcopy(real)
    _bank(docs)["replies"]["empathy"]["again"] = {"text": "Ja, dat zei je al."}
    _dialog(docs, "joost_output_kpi").setdefault("replies", {})["inquiry"] = {"again": {"text": "Dat vroeg je al."}}
    _dialog(docs, "joost_output_kpi")["lines"]["paraphrase"] = {
        "position": "Dus het getal klopt.", "interest": ["Dus je wilt…", "Als ik je goed hoor…"], "_": "Dus…"}
    _dialog(docs, "joost_output_kpi")["replies"]["empathy"] = {
        "lands": {"position": {"text": "Dank je.", "tags": ["feeling"]}, "_": [{"text": "Ja."}, {"text": "Mm."}]}}
    _load(tmp_path, docs)


def test_the_patterns_reach_the_game():
    vocab = bc.vocabulary()["dialog_coherence"]
    assert vocab == {"repeat": bc.REPEAT_CLAIM, "clarify": bc.CLARIFY_ASK}
    assert bc._REPEAT_RE.search("Ja, dat zei je al.") and bc._REPEAT_RE.search("Dat heb ik je net verteld.")
    assert not bc._REPEAT_RE.search("Morgen zit ik hier alleen.")
    assert bc._CLARIFY_RE.search("Hoe bedoel je?") and not bc._CLARIFY_RE.search("Hoe gaat het?")
