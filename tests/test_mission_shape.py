"""Face, number, choice (phase-2 design §3.4): every tier-1 main mission with a problem
names a person met before any KPI (a talk the mission needs comes before the first dig
step), states a measurable claim in its briefing (a number with a unit), and offers at
least one tempting countermeasure tagged `shortcut: true` whose later cost is real (path
dependence: a poor fix, a chosen-fact gate or an aftermath; or a sustain penalty: it
fades sooner than another way to fix it). Failures block the slice: fix the content,
never the test."""
from __future__ import annotations

import copy
import re

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}
CMS = {c["id"]: c for c in REAL["countermeasures"]["countermeasures"]}
PROBLEMS = {p["id"]: p for p in REAL["problems_tier1"]["problems"]}
DIALOGS = {d["id"]: d for d in REAL["dialogs"]["dialogs"]}
PERSONS = {p["id"] for p in REAL["dialogs"]["people"]}
MAINS = [m for m in REAL["missions"]["missions"]
         if m["kind"] == "main" and m.get("tier", 1) == 1 and "problem" in m["goal"]]

# Missions.POOR_FIT_GAP: a fix this much below the problem's best fit is a poor fix
# (fact poor_fix:, a repair quest later), read from the rules so the two cannot drift.
_GAP = re.search(r"const POOR_FIT_GAP := ([0-9.]+)",
                 (bc.ROOT / "game" / "src" / "rules" / "missions.gd").read_text(encoding="utf-8"))
POOR_FIT_GAP = float(_GAP.group(1))

_NUMBER_WORDS = ("twee|drie|vier|vijf|zes|zeven|acht|negen|tien|elf|twaalf|dertien|veertien|vijftien|zestien|"
                 "zeventien|achttien|negentien|twintig|dertig|veertig|vijftig|zestig|zeventig|tachtig|negentig|"
                 "honderd|duizend")
_UNITS = ("weken|week|dagen|dag|maanden|maand|jaar|jaren|uur|uren|minuten|procent|euro|dossiers|aanvragen|"
          "adressen|agents|keer|studies|netstudies|woningen|huizen|huishoudens|megawatt|meter|meters|schetsen|"
          "klanten|storingen|ritten|bezoeken|monteurs|analisten|aansluitingen|graafschades|schades|kilometer")
# A count (digits, or a Dutch number word, also inside a compound such as "achtendertig")
# and within two words its unit; "%" and "€" carry their own unit.
CLAIM = re.compile(rf"(\d+([.,]\d+)?\s*%|€\s*\d|\b(\d+([.,]\d+)?|\w*(?:{_NUMBER_WORDS}))\b(\s+\S+){{0,2}}?\s+({_UNITS})\b)",
                   re.IGNORECASE)


def _ids(missions: list[dict]) -> list[str]:
    return [m["id"] for m in missions]


def test_the_shape_covers_the_tier1_mains():
    assert len(MAINS) >= 11, _ids(MAINS)


@pytest.mark.parametrize("m", MAINS, ids=_ids(MAINS))
def test_a_person_comes_before_the_numbers(m):
    talks = [t["dialog"] for t in m.get("talk_to", [])]
    assert talks, f"{m['id']}: no talk the mission needs (talk_to)"
    steps = list(m.get("steps", {}))
    assert "talk" in steps and "dig" in steps and steps.index("talk") < steps.index("dig"), \
        f"{m['id']}: the talk step must come before the first dig step ({steps})"
    for dialog_id in talks:
        d = DIALOGS[dialog_id]
        assert d["person"] in PERSONS
        assert not d.get("requires_clue"), f"{m['id']}: {dialog_id} waits for a clue, so it cannot come first"


@pytest.mark.parametrize("m", MAINS, ids=_ids(MAINS))
def test_the_briefing_makes_a_measurable_claim(m):
    assert CLAIM.search(m["briefing"]), f"{m['id']}: no number with a unit in the briefing"


def test_the_claim_pattern():
    for text in ["ruim honderd dossiers", "38 netstudies", "Twee op de vijf adressen", "vier extra agents",
                 "Driehonderd huizen", "zes weken overuren", "een kwart van de 40 %", "€ 12.000"]:
        assert CLAIM.search(text), text
    for text in ["Ergens ligt werk dat niemand ziet.", "de vijfde graafschade", "een kwartaal geleden"]:
        assert not CLAIM.search(text), text


def _later_cost(problem_id: str, cm_id: str) -> list[str]:
    """Why choosing `cm_id` for `problem_id` costs later; empty when it does not."""
    fits = PROBLEMS[problem_id]["countermeasures"]
    cm = CMS[cm_id]
    why = []
    if fits[cm_id] <= max(fits.values()) - POOR_FIT_GAP + 1e-9:
        why.append("poor fix")
    decay = cm.get("decay_days")
    if decay is not None and any(CMS[o].get("decay_days") is None or CMS[o]["decay_days"] > decay
                                 for o in fits if o != cm_id):
        why.append("fades sooner")
    if cm.get("aftermath"):
        why.append("aftermath")
    if f"chose:{problem_id}:{cm_id}" in yaml.safe_dump(REAL):
        why.append("a later gate reads the choice")
    return why


@pytest.mark.parametrize("m", MAINS, ids=_ids(MAINS))
def test_a_tempting_shortcut_with_a_real_later_cost(m):
    problem_id = m["goal"]["problem"]
    shortcuts = [c for c in PROBLEMS[problem_id]["countermeasures"] if CMS[c].get("shortcut")]
    assert shortcuts, f"{m['id']}: no countermeasure of {problem_id} is tagged shortcut: true"
    for c in shortcuts:
        assert _later_cost(problem_id, c), f"{m['id']}: shortcut {c} costs nothing later"


def test_every_shortcut_anywhere_has_a_later_cost_and_is_never_the_only_way():
    for p in PROBLEMS.values():
        shortcuts = [c for c in p["countermeasures"] if CMS[c].get("shortcut")]
        assert len(shortcuts) < len(p["countermeasures"]), f"{p['id']}: every way is a shortcut"
        for c in shortcuts:
            assert _later_cost(p["id"], c), f"{p['id']}: shortcut {c} costs nothing later"


@pytest.mark.parametrize("change", [{"kind": "main"}, {"recurring": {"every_days": 0}}])
def test_only_a_side_mission_recurs_and_at_least_daily(change):
    doc = copy.deepcopy(REAL["missions"])
    mission = next(x for x in doc["missions"] if x["id"] == "lsw_gemba_round")
    mission.update(change)
    with pytest.raises(bc.ContentError):
        bc.validate_missions(doc, "missions.yaml")
