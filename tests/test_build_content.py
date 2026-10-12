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


REAL_STREAMS = (bc.CONTENT_DIR / "value_streams.yaml").read_text(encoding="utf-8")


@pytest.fixture
def dirs(tmp_path: Path) -> tuple[Path, Path]:
    content, data = tmp_path / "content", tmp_path / "data"
    content.mkdir()
    (content / "game.yaml").write_text(GAME_YAML, encoding="utf-8")
    (content / "value_streams.yaml").write_text(REAL_STREAMS, encoding="utf-8")
    for stem in ("countermeasures", "problems_tier1"):
        (content / f"{stem}.yaml").write_text((bc.CONTENT_DIR / f"{stem}.yaml").read_text(encoding="utf-8"), encoding="utf-8")
    return content, data


def test_repo_content_is_valid_and_built():
    docs = bc.load_content()
    assert docs["game"]["town"] == "Nova"
    assert bc.stale_files(docs) == [], "run: python tools/build_content.py"


def test_write_then_check_is_clean(dirs):
    content, data = dirs
    docs = bc.load_content(content)
    assert bc.stale_files(docs, data) == sorted(f"{stem}.json" for stem in docs)
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


@pytest.mark.parametrize("text, message", [
    # A comma in unquoted text inside {…} splits it: the rest becomes a key without a value.
    ("company: {name: Voltana, motto: Licht, warmte en vooruitgang}\n", "line 1: 'warmte en vooruitgang' has no value"),
    ("company: Voltana\ncompany: Enexis\n", "line 2: duplicate key 'company'"),
])
def test_yaml_that_would_lose_text_is_reported(dirs, text, message):
    content, _ = dirs
    (content / "game.yaml").write_text(text, encoding="utf-8")
    with pytest.raises(bc.ContentError, match=message):
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
    assert seen == [sorted(path.stem for path in content.glob("*.yaml"))]


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
    (lambda d: _step(d, "design").pop("stale_to"), "'stale_to' must name an earlier step"),
    (lambda d: _step(d, "design").update(stale_after_days=60, stale_to="design"), "'stale_to' must name an earlier step"),
    (lambda d: _step(d, "design").update(stale_after_days=0, stale_to="quote"), "'stale_after_days' must be >= 1"),
    (lambda d: _step(d, "execution").update(stale_after_days=60, stale_to="design"), "takes material twice"),
    (lambda d: _connections(d).update(wip_limit=-1), "'wip_limit' must be >= 0"),
    (lambda d: _connections(d).update(wip_limit=2.5), "'wip_limit' must be an integer"),
    (lambda d: _connections(d).update(status_calls={"to": "connections", "after_days": 21, "per_week": 1}), "'status_calls' needs 'to': another stream"),
    (lambda d: _connections(d)["status_calls"].update(after_days=0), "'after_days' must be >= 1"),
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


def test_real_streams_cover_the_four_value_streams_and_customer_contact():
    ids = [s["id"] for s in _streams()["streams"]]
    assert ids == ["connections", "outages", "meters", "congestion", "customer_contact"]


# ── problems and countermeasures ─────────────────────────────────────────────

CMS_YAML = """countermeasures:
  - id: standard_designs
    name: Standaardontwerpen
    tier: 1
    category: standard_work
    description: Een standaardontwerp voor standaardaansluitingen.
    budget: 8000
    team_hours: {work_prep: 40}
    decay_days: 45
    multipliers: {full: 0.9, reduced: 0.5, minimal: 0.25}
    effects:
      - {target: connections.design, property: touch_time, value: 0.75}
  - id: weekly_meeting
    name: Wekelijks overleg
    tier: 1
    category: visual_management
    description: Elke week bespreken.
    budget: 1000
    team_hours: {}
    decay_days: null
    multipliers: {full: 0.6, reduced: 0.3, minimal: 0.1}
    effects: []
"""

PROBLEMS_YAML = """problems:
  - id: custom_design
    tier: 1
    name: Maatwerk voor standaardwerk
    step: connections.design
    waste: overprocessing
    severity: high
    visibility: obvious
    kpi: throughput
    symptoms: [De stapel ontwerpen groeit.]
    root_cause: Standaardaansluitingen krijgen een volledig maatwerkontwerp.
    plausible_causes: [De werkvoorbereiders zijn te langzaam.]
    mismatch_note: Het werk zelf is niet veranderd.
    countermeasures: {standard_designs: 1.0}
    teaches: [standard_work]
    effects:
      - {target: connections.design, property: touch_time, value: 1.3}
    clues:
      - {tool: time_study, key: true, depth: 0, text: Een standaardaansluiting kost vijf uur ontwerp.}
      - {tool: queue_count, key: false, depth: 0, text: Er liggen veertig dossiers.}
      - {tool: documents, key: true, depth: 1, text: Elk dossier heeft drie handtekeningen.}
      - {tool: conversation, key: true, depth: 1, at: connections.intake, text: Intake vraagt nooit of het standaard is.}
"""


@pytest.fixture
def rules_dirs(dirs):
    content, data = dirs
    (content / "countermeasures.yaml").write_text(CMS_YAML, encoding="utf-8")
    (content / "problems_tier1.yaml").write_text(PROBLEMS_YAML, encoding="utf-8")
    return content, data


def _rules(content, mutate) -> None:
    docs = {stem: yaml.safe_load((content / f"{stem}.yaml").read_text(encoding="utf-8"))
            for stem in ("game", "value_streams", "countermeasures", "problems_tier1")}
    mutate(docs)
    for stem, doc in docs.items():
        (content / f"{stem}.yaml").write_text(yaml.safe_dump(doc, allow_unicode=True), encoding="utf-8")
    bc.load_content(content)


def _problem(docs: dict) -> dict:
    return docs["problems_tier1"]["problems"][0]


def _cm(docs: dict) -> dict:
    return docs["countermeasures"]["countermeasures"][0]


def test_sample_problems_are_valid(rules_dirs):
    content, _ = rules_dirs
    docs = bc.load_content(content)
    assert docs["problems_tier1"]["problems"][0]["id"] == "custom_design"


@pytest.mark.parametrize("mutate, message", [
    (lambda d: _problem(d).update(waste="laziness"), "'waste' must be one of"),
    (lambda d: _problem(d).update(kpi="happiness"), "'kpi' must be one of"),
    (lambda d: _problem(d).update(step="connections.nowhere"), "unknown step 'connections.nowhere'"),
    (lambda d: _problem(d)["clues"][0].update(tool="crystal_ball"), "unknown tool 'crystal_ball'"),
    (lambda d: _problem(d)["clues"][0].update(key=False), "needs a key clue at depth 0"),
    (lambda d: _problem(d)["clues"][2].update(depth=3), "depth 3 needs a key clue at depth 2"),
    (lambda d: _problem(d)["clues"][3].update(at="connections.permit"), "conversation clue at a step without a team"),
    (lambda d: _problem(d)["clues"][1].update(at="ghosts.step"), "unknown step 'ghosts.step'"),
    (lambda d: _problem(d).update(countermeasures={"magic_wand": 1.0}), "unknown countermeasure 'magic_wand'"),
    (lambda d: _problem(d).update(countermeasures={"standard_designs": 1.5}), "fit"),
    (lambda d: _cm(d).update(tier=2), "no countermeasure that can solve it"),
    # Every listed countermeasure is an improvement (some more than others), so each can pass the Check.
    (lambda d: _problem(d).update(countermeasures={"standard_designs": 1.0, "weekly_meeting": 0.5}),
     "'weekly_meeting' can never pass the Check"),
    (lambda d: _problem(d)["effects"][0].update(property="speed"), "unknown effect property 'speed'"),
    (lambda d: _problem(d)["effects"][0].update(target="connections.permit"), "is not a work step"),
    (lambda d: _problem(d)["effects"][0].update(target="nobody"), "unknown step 'nobody'"),
    (lambda d: _problem(d)["effects"][0].update(value=0), "factor above 0"),
    (lambda d: _problem(d)["effects"].append({"target": "connections", "property": "wip_limit", "value": 2.5}), "'value' must be an integer"),
    (lambda d: _problem(d)["effects"].append({"target": "monteurs", "property": "reserve", "value": {"stream": "outages", "people": 99}}), "'people' must be between"),
    (lambda d: _problem(d)["effects"].append({"target": "outages", "property": "preempts", "value": "yes"}), "true or false"),
    (lambda d: _problem(d).update(symptoms=[]), "'symptoms' must be a non-empty list"),
    (lambda d: _cm(d).update(tier=5), "'tier' must be between 1 and 4"),
    (lambda d: _cm(d).update(team_hours={"wizards": 10}), "unknown pool 'wizards'"),
    (lambda d: _cm(d).update(multipliers={"full": 0.5, "reduced": 0.7, "minimal": 0.1}), "full >= reduced >= minimal"),
    (lambda d: _cm(d).update(decay_days=0), "'decay_days' must be"),
    # Misspelt fields would be ignored silently.
    (lambda d: _problem(d)["clues"][0].update(dept=1), "clue 0: unknown key.s. 'dept'"),
    (lambda d: _problem(d)["effects"][0].update(strength=2), "effect 0: unknown key.s. 'strength'"),
    (lambda d: _problem(d).update(teach=["flow"]), "unknown key.s. 'teach'"),
    (lambda d: _cm(d).update(decay=30), "unknown key.s. 'decay'"),
    (lambda d: d["countermeasures"]["countermeasures"].append(dict(_cm(d))), "duplicate countermeasures ids"),
])
def test_problem_errors_are_caught(rules_dirs, mutate, message):
    content, _ = rules_dirs
    with pytest.raises(bc.ContentError, match=message.replace("(", r"\(")):
        _rules(content, mutate)


def test_vocabulary_is_written_for_the_game():
    docs = bc.load_content()
    assert "conversation" in docs["vocabulary"]["tools"]
    assert docs["vocabulary"]["effect_properties"]["touch_time"] == {"kind": "step", "step_kind": "work"}


def test_any_problems_tier_file_is_validated(rules_dirs):
    content, _ = rules_dirs
    (content / "problems_tier2.yaml").write_text("problems: [{}]\n", encoding="utf-8")
    with pytest.raises(bc.ContentError, match="problems_tier2.yaml"):
        bc.load_content(content)
