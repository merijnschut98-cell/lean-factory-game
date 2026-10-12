"""Tests for tools/build_content.py — the YAML → JSON content pipeline of Spanning."""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import build_content as bc  # noqa: E402

GAME_YAML = """company: Voltana Netbeheer
region: Zuidmark
town: Nova
campus: Campus Nova
player_role: CI-lead
locale: nl
"""


@pytest.fixture
def dirs(tmp_path: Path) -> tuple[Path, Path]:
    content, data = tmp_path / "content", tmp_path / "data"
    content.mkdir()
    (content / "game.yaml").write_text(GAME_YAML, encoding="utf-8")
    return content, data


def test_repo_content_is_valid_and_built():
    docs = bc.load_content()
    assert docs["game"]["town"] == "Nova"
    assert bc.stale_files(docs) == [], "run: python tools/build_content.py"


def test_write_then_check_is_clean(dirs):
    content, data = dirs
    docs = bc.load_content(content)
    assert bc.stale_files(docs, data) == ["game.json"]
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
