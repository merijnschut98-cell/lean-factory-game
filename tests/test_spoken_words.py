"""No spoken line names the game (PLAN 2.13 E; docs/superpowers/specs/2026-10-19-dutch-style-guide.md §4).

The build flags a banned word (game, spel, speler, level, quest, missie, ...)
in every line a person says or writes in the world; UI chrome may still say
"missie".
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


@pytest.mark.parametrize("text, hit", [
    ("Weet je waarom dit spel… sorry.", "spel"),
    ("Dit is jouw eerste missie.", "missie"),
    ("Level twee, zeg maar.", "level"),
    ("De speler loopt mee.", "speler"),
    ("Een GAME is het niet.", "game"),
    ("Pak de andere haspel.", None),
    ("Wat is je voorspelling?", None),
    ("Er staat veel op het spel.", None),
    ("Jij bent {speler}, toch? Vertel het {haar_hem_speler} maar.", None),
    ("De spelregels van de ACM.", None),
])
def test_a_banned_word_is_a_whole_word_outside_tokens_and_the_one_idiom(text, hit):
    assert bc.banned_word(text) == hit


def test_the_real_spoken_lines_are_clean_and_cover_every_voice(real):
    docs = real
    texts = [t for _, t in bc.spoken_texts(docs)]
    anouk = _dialog(docs, "anouk_seven")
    assert anouk["opening"] in texts, "a dialog's opening"
    assert anouk["proposals"][0]["say"] in texts and anouk["proposals"][0]["reply"] in texts
    assert anouk["layers"][1]["lead_in"]["text"] in texts
    assert anouk["proposals"][0]["label"] not in texts, "a proposal's chip label is UI"
    assert docs["dialogs"]["bank"]["special"]["repeat"] in texts
    assert docs["dialogs"]["bank"]["labels"]["cue"] not in texts, "bank labels are UI"
    assert docs["explainers"]["explainers"][0]["beats"][0]["lines"][0] in texts
    assert docs["missions"]["missions"][0]["briefing"] in texts, "Ruud's note is in-world"
    assert docs["missions"]["missions"][0]["name"] not in texts, "a mission's name is UI"
    question = docs["places"]["places"]["connections.intake"]["questions"][0]
    assert question["text"] in texts and question["reply"] in texts
    assert [w for w, t in bc.spoken_texts(docs) if bc.banned_word(t)] == []


@pytest.mark.parametrize("mutate, where", [
    (lambda r: _dialog(r, "anouk_seven").__setitem__("opening", "Welkom in het spel!"), "anouk_seven"),
    (lambda r: r["dialogs"]["bank"]["player"].__setitem__("close", "Op naar de volgende missie."), "bank player"),
    (lambda r: r["dialogs"]["bank"]["player"].__setitem__("close", ["Dank je.", "Op naar het volgende level."]),
     "bank player"),
    (lambda r: r["explainers"]["explainers"][0]["beats"][0]["lines"].__setitem__(0, "Dit spel leert je stroom."),
     "beat a1"),
    (lambda r: r["missions"]["missions"][0].__setitem__("briefing", "Je eerste quest."), "training_mon"),
    (lambda r: r["places"]["places"]["connections.intake"]["questions"][0].__setitem__("reply", "Speler, kom."),
     "connections.intake"),
])
def test_a_banned_word_in_a_spoken_line_fails_the_build(real, tmp_path, mutate, where):
    docs = copy.deepcopy(real)
    mutate(docs)
    with pytest.raises(bc.ContentError, match=rf"{where}.*names the game"):
        bc.check_spoken(docs)


def test_ui_chrome_may_say_missie(real):
    docs = copy.deepcopy(real)
    docs["dialogs"]["bank"]["labels"]["cue"] = "Er zit meer achter deze missie…"
    docs["missions"]["missions"][0]["name"] = "Missie: rondleiding"
    bc.check_spoken(docs)


def test_the_build_runs_the_spoken_check(real, tmp_path):
    docs = copy.deepcopy(real)
    _dialog(docs, "anouk_seven")["opening"] = "Welkom bij het spel."
    with pytest.raises(bc.ContentError, match="names the game"):
        _load(tmp_path, docs)


def test_the_vocabulary_exports_the_banned_list_for_the_godot_scan():
    vocab = bc.vocabulary()
    assert vocab["banned_spoken"] == {"words": bc.BANNED_SPOKEN, "allowed": bc.ALLOWED_SPOKEN}
    assert {"game", "spel", "speler", "level", "quest", "missie"} <= set(bc.BANNED_SPOKEN)
