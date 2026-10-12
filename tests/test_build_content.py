"""Tests for tools/build_content.py — the YAML → JSON content pipeline of Spanning."""
from __future__ import annotations

import copy
from pathlib import Path

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

GAME_YAML = """company: Voltana Netbeheer
region: Zuidmark
town: Nova
campus: Campus Nova
player_role: CI-lead
locale: nl
"""


REAL_STREAMS = (Path(__file__).resolve().parent.parent / "content" / "value_streams.yaml").read_text(encoding="utf-8")


@pytest.fixture
def dirs(tmp_path: Path) -> tuple[Path, Path]:
    content, data = tmp_path / "content", tmp_path / "data"
    content.mkdir()
    (content / "game.yaml").write_text(GAME_YAML, encoding="utf-8")
    (content / "value_streams.yaml").write_text(REAL_STREAMS, encoding="utf-8")
    return content, data


def test_repo_content_is_valid_and_built():
    docs = bc.load_content()
    assert docs["game"]["town"] == "Nova"
    assert bc.stale_files(docs) == [], "run: python tools/build_content.py"


def test_write_then_check_is_clean(dirs):
    content, data = dirs
    docs = bc.load_content(content)
    assert bc.stale_files(docs, data) == ["game.json", "value_streams.json"]
    bc.write(docs, data)
    assert bc.stale_files(docs, data) == []
    assert '"town": "Nova"' in (data / "game.json").read_text(encoding="utf-8")


def test_orphaned_data_is_reported_and_removed(dirs):
    content, data = dirs
    docs = bc.load_content(content)
    bc.write(docs, data)
    (data / "old.json").write_text("{}", encoding="utf-8")
    assert bc.stale_files(docs, data) == ["old.json"]
    bc.write(docs, data)
    assert not (data / "old.json").exists()


def test_missing_field_is_rejected(dirs):
    content, _ = dirs
    (content / "game.yaml").write_text(GAME_YAML.replace("town: Nova\n", ""), encoding="utf-8")
    with pytest.raises(bc.ContentError, match="'town'"):
        bc.load_content(content)


def test_file_without_validator_is_rejected(dirs):
    content, _ = dirs
    (content / "mystery.yaml").write_text("a: 1\n", encoding="utf-8")
    with pytest.raises(bc.ContentError, match="no validator"):
        bc.load_content(content)


def test_invalid_yaml_is_reported(dirs):
    content, _ = dirs
    (content / "game.yaml").write_text("company: [unclosed\n", encoding="utf-8")
    with pytest.raises(bc.ContentError, match="invalid YAML"):
        bc.load_content(content)


def test_cross_checks_see_all_files(dirs, monkeypatch):
    content, _ = dirs
    seen = []
    monkeypatch.setattr(bc, "CROSS_CHECKS", [lambda docs: seen.append(sorted(docs))])
    bc.load_content(content)
    assert seen == [["game", "value_streams"]]


def test_cross_check_failure_is_reported(dirs, monkeypatch):
    content, _ = dirs

    def fail(docs):
        raise bc.ContentError("mission M1 names unknown problem P9")

    monkeypatch.setattr(bc, "CROSS_CHECKS", [fail])
    with pytest.raises(bc.ContentError, match="unknown problem"):
        bc.load_content(content)


def test_missing_registered_file_is_reported(dirs):
    content, _ = dirs
    (content / "game.yaml").unlink()
    with pytest.raises(bc.ContentError, match="missing content files: game.yaml"):
        bc.load_content(content)


def test_cli_build_then_check(dirs, monkeypatch):
    content, data = dirs
    monkeypatch.setattr(bc, "CONTENT_DIR", content)
    monkeypatch.setattr(bc, "DATA_DIR", data)
    assert bc.main(["--check"]) == 1
    assert bc.main([]) == 0
    assert bc.main(["--check"]) == 0


def test_cli_reports_content_errors(dirs, monkeypatch):
    content, data = dirs
    (content / "game.yaml").write_text("town: Nova\n", encoding="utf-8")
    monkeypatch.setattr(bc, "CONTENT_DIR", content)
    monkeypatch.setattr(bc, "DATA_DIR", data)
    assert bc.main([]) == 1
    assert not data.exists()


# ── value_streams.yaml ───────────────────────────────────────────────────────

def _streams() -> dict:
    return copy.deepcopy(yaml.safe_load(REAL_STREAMS))


def _connections(doc: dict) -> dict:
    return next(s for s in doc["streams"] if s["id"] == "connections")


def _step(doc: dict, step_id: str) -> dict:
    return next(s for s in _connections(doc)["steps"] if s["id"] == step_id)


def test_real_value_streams_are_valid():
    bc.validate_value_streams(_streams(), "value_streams.yaml")


@pytest.mark.parametrize("mutate, message", [
    (lambda d: _step(d, "design").update(pool="nobody"), "unknown pool 'nobody'"),
    (lambda d: _step(d, "materials").update(item="ghost"), "unknown stock item 'ghost'"),
    (lambda d: _step(d, "intake").update(rework_to="revision"), "earlier one"),
    (lambda d: _step(d, "intake").update(rework_to="nope"), "earlier one"),
    (lambda d: _step(d, "design").update(ftr=1.5), "'ftr' must be between"),
    (lambda d: _step(d, "permit").update(applies=0), "'applies' must be between"),
    (lambda d: _step(d, "design").update(kind="dance"), "'kind' must be one of"),
    (lambda d: _step(d, "materials").update(quantity=1.5), "'quantity' must be an integer"),
    (lambda d: d["pools"][0]["schedule"][0].update(to=930), 'quoted "HH:MM"'),
    (lambda d: d["pools"][0]["schedule"][0].update({"from": "16:00", "to": "08:00"}), "end after it starts"),
    (lambda d: d["pools"][0]["schedule"][0].update({"from": "24:00"}), 'quoted "HH:MM"'),
    (lambda d: d["pools"][0]["schedule"][0].update({"from": "07:35"}), "10-minute grid"),
    (lambda d: d["pools"][0]["schedule"][0].update(days="maandag"), "'days'"),
    (lambda d: d["pools"][0]["schedule"][0].update(days="fri-mon"), "'days'"),
    (lambda d: d["pools"][0].pop("schedule"), "'schedule' must be a non-empty list"),
    (lambda d: _connections(d)["arrivals"][0].pop("per_week"), "'per_week' must be a number"),
    (lambda d: _connections(d).pop("arrivals"), "'arrivals' must be a non-empty list"),
    (lambda d: _connections(d).update(norm_hours=4), "exactly one of 'norm_days' or 'norm_hours'"),
    (lambda d: _connections(d).pop("norm_days"), "exactly one of 'norm_days' or 'norm_hours'"),
    (lambda d: _connections(d).update(preempts="yes"), "'preempts' must be true or false"),
    (lambda d: _step(d, "design").update(pool=["work_prep", "ghost"]), "unknown pool 'ghost'"),
    (lambda d: _step(d, "design").update(pool=[]), "unknown pool"),
    (lambda d: _step(d, "execution").update(rework_to="design"), "takes material twice"),
    (lambda d: _step(d, "execution").update(interrupt_to="design"), "takes material twice"),
    (lambda d: _step(d, "intake").update(interrupt_to="revision"), "'interrupt_to' must name this step or an earlier one"),
    (lambda d: _step(d, "permit").update(starts_with="revision"), "'starts_with' must name an earlier step"),
    (lambda d: _step(d, "design").update(starts_with="intake"), "only a wait step"),
    (lambda d: _step(d, "permit").update(batch_days=-1), "'batch_days' must be >= 0"),
    (lambda d: d["pools"][4].update(reserve={"stream": "ghost", "people": 2}), "reserve.*unknown stream 'ghost'"),
    (lambda d: d["pools"][4].update(reserve={"stream": "outages", "people": 99}), "'people' must be between 1 and 14"),
    (lambda d: d["pools"][0].update(headcount=True), "'headcount' must be an integer"),
    (lambda d: d["pools"].append(dict(d["pools"][0])), "duplicate pools ids: intake"),
    (lambda d: d["pools"][0].update(id="Intake Team"), "snake_case"),
    (lambda d: _connections(d).update(steps=[]), "at least one step"),
])
def test_value_stream_errors_are_caught(mutate, message):
    doc = _streams()
    mutate(doc)
    with pytest.raises(bc.ContentError, match=message.replace("(", r"\(")):
        bc.validate_value_streams(doc, "value_streams.yaml")


def test_unquoted_time_in_yaml_is_caught():
    doc = yaml.safe_load(REAL_STREAMS.replace('to: "15:30"', "to: 15:30", 1))
    with pytest.raises(bc.ContentError, match="HH:MM"):
        bc.validate_value_streams(doc, "value_streams.yaml")


def test_real_streams_cover_the_four_value_streams():
    ids = [s["id"] for s in _streams()["streams"]]
    assert ids == ["connections", "outages", "meters", "congestion"]
