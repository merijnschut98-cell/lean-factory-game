"""Milestones, dates and scenes in the content pipeline (phase-2 design §3.1–3.2):
`kind: milestone` (no slot; a scene or the story's order), `opens_on`, `deadline_on_day`,
`sets_flags_on_fail`, content/scenes.yaml, and the too_early debrief variant."""
from __future__ import annotations

import pytest
import yaml

import build_content as bc
from tests.test_build_content import _mission, _rules, dirs, rules_dirs  # noqa: F401 (fixtures)

SCENES_YAML = """scenes:
  - id: review
    room: mt_room
    present: [ruud]
    beats:
      - {speaker: ruud, line: "Honderd dagen."}
      - {speaker: ruud, line: "De stapel ligt er nog steeds niet.", needs: {all: ["holds:custom_design"]}}
      - speaker: ruud
        line: "Wat neem je mee?"
        choice:
          - {label: "De mensen", fact: "flag:review_people", reply: "Dat dacht ik al."}
          - {label: "De getallen", fact: "flag:review_numbers"}
"""


def _review(**extra) -> dict:
    m = {"id": "review", "name": "Honderd dagen", "kind": "milestone", "tier": 1, "act": 1,
         "requires": {"missions": ["walk_connections"]}, "opens_on": {"day": 100}, "scene": "review",
         "goal": {"type": "scene"}, "steps": {"go": "Ga naar de MT-kamer"},
         "briefing": "Het MT wil je spreken.", "debrief": "Honderd dagen.",
         "rewards": {"xp": 500}}
    return _changed(m, extra)


def _changed(m: dict, extra: dict) -> dict:
    """`m` with `extra` over it; a None drops the key."""
    m.update(extra)
    return {k: v for k, v in m.items() if v is not None}


def _winter(**extra) -> dict:
    m = {"id": "winter", "name": "Voor de vorst", "kind": "milestone", "tier": 1, "act": 1,
         "requires": {"missions": ["walk_connections"]}, "opens_on": {"date": "2026-11-30"}, "deadline_on_day": 70,
         "goal": {"type": "story_order", "story": "el_amrani", "by": "deadline",
                  "met_if": {"any": ["delivered:el_amrani", "flag:review_people"]}},
         "briefing": "Het gaat vriezen.", "debrief": "Ze zat warm.", "fail": "Ze logeert bij haar dochter.",
         "sets_flags_on_fail": ["flag:el_amrani_complaint"], "rewards": {"xp": 300}}
    return _changed(m, extra)


def _add(*missions, scenes: str = SCENES_YAML):
    def mutate(d):
        d["missions"]["missions"].extend(missions)
        d["scenes"] = yaml.safe_load(scenes)
    return mutate


def _load(content, mutate) -> dict:
    """_rules with scenes.yaml written too (it is not one of the fixture's files)."""
    def with_scenes(d):
        mutate(d)
        scenes = d.pop("scenes", None)
        if scenes is not None:
            (content / "scenes.yaml").write_text(yaml.safe_dump(scenes, allow_unicode=True), encoding="utf-8")
    _rules(content, with_scenes)
    return bc.load_content(content)


def test_milestones_dates_and_scenes_are_valid(rules_dirs):
    content, _ = rules_dirs
    gated = {"id": "after", "name": "Daarna", "kind": "side", "tier": 1, "briefing": "Kijk.", "debrief": "Gezien.",
             "requires": {"missions": ["walk_connections"],
                          "facts": {"any": ["flag:el_amrani_complaint", "flag:review_numbers", "done:walk_connections"]}},
             "goal": {"type": "walk", "stream": "meters"}}
    docs = _load(content, _add(_review(), _winter(), gated))
    assert [s["id"] for s in docs["scenes"]["scenes"]] == ["review"]
    winter = next(m for m in docs["missions"]["missions"] if m["id"] == "winter")
    assert winter["deadline_on_day"] == 70


def test_a_designed_failed_check_has_its_own_debrief(rules_dirs):
    content, _ = rules_dirs
    docs = _load(content, lambda d: _mission(d).update(debrief_variants={"too_early": "Te vroeg. Wat nu?"}))
    assert docs["missions"]["missions"][1]["debrief_variants"] == {"too_early": "Te vroeg. Wat nu?"}


@pytest.mark.parametrize("mutate, message", [
    (_add(_review(goal={"type": "walk", "stream": "connections"})), "a milestone, and only a milestone"),
    (_add(dict(_review(), kind="side")), "a milestone, and only a milestone"),
    (_add(_review(scene="ghost")), "names no scene 'ghost'"),
    (_add(_review(scene=None)), "'scene' must be"),
    (_add(_review(steps=None)), "missing go"),
    (_add(_winter(payoff=[{"who": "ruud", "by": "fax", "text": "Hoi."}])), "'by' must be one of"),
    (_add(_winter(steps={"go": "Ga naar huis"})), "'go' leads to a milestone's scene"),
    (_add(_review(opens_on={"week": 3})), "'opens_on' is"),
    (_add(_review(opens_on={"date": "30-11-2026"})), "'opens_on' is"),
    (_add(_review(opens_on={"date": "2026-01-05"})), "before the first day of play"),
    (_add(_review(opens_on={"day": 100, "date": "2026-11-30"})), "'opens_on' is"),
    (_add(_winter(deadline_on_day=40)), "deadline_on_day 40 falls before it opens"),
    (_add(_winter(fail=None)), "'fail' must be a non-empty string"),
    (_add(_winter(deadline_on_day=None)), "a story_order goal is judged on its deadline_on_day"),
    (_add(_winter(goal={"type": "story_order", "story": "ghost", "by": "deadline",
                        "met_if": {"any": ["delivered:el_amrani"]}})), "'story' must be one of"),
    (_add(_winter(goal={"type": "story_order", "story": "el_amrani", "by": "promise",
                        "met_if": {"any": ["delivered:el_amrani"]}})), "'by' must be one of"),
    (_add(_winter(goal={"type": "story_order", "story": "el_amrani", "by": "deadline",
                        "met_if": {"any": ["delivered:ghost"]}})), "names no followed story"),
    (_add(_winter(sets_flags_on_fail=["done:walk_connections"])), "'sets_flags_on_fail' entries are flag:<name>"),
    (lambda d: _mission(d).update(sets_flags_on_fail=["flag:x"]), "'sets_flags_on_fail' needs a deadline"),
    (lambda d: _mission(d).update(debrief_variants={"too_late": "Hm."}), "unknown key.s. 'too_late'"),
    (_add(_review(), scenes=SCENES_YAML.replace("speaker: ruud, line: \"Honderd", "speaker: ruud, said: \"Honderd")),
     "unknown key.s. 'said'"),
    (_add(_review(), scenes=SCENES_YAML.replace("fact: \"flag:review_numbers\"", "fact: \"done:walk_connections\"")),
     "a choice's fact is flag:<name>"),
    (_add(_review(), scenes=SCENES_YAML.replace("holds:custom_design", "holds:ghost")), "names an unknown problem"),
    (_add(_review(), scenes=SCENES_YAML + "  - id: review\n    room: mt_room\n    beats: [{speaker: ruud, line: Hoi.}]\n"),
     "duplicate scenes ids: review"),
    (_add(_review(), scenes=SCENES_YAML.replace("Honderd dagen.", "Honderd dagen in dit spel.")), "names the game"),
])
def test_milestone_errors_are_caught(rules_dirs, mutate, message):
    content, _ = rules_dirs
    with pytest.raises(bc.ContentError, match=message):
        _load(content, mutate)


def test_real_act_one_milestones():
    """review_100_days around day 100 in the MT room (opened for it); winter_el_amrani judged on
    the first frost period, its call's promise checked."""
    docs = bc.load_content()
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    review, winter = missions["review_100_days"], missions["winter_el_amrani"]
    assert review["kind"] == winter["kind"] == "milestone"
    assert review["opens_on"] == {"day": 100} and review["scene"] == "review_100_days"
    assert winter["goal"]["promise"] == "el_amrani_fourth_call" and winter["deadline_on_day"] == 70
    assert "flag:el_amrani_complaint" in winter["sets_flags_on_fail"]
    rooms = {r["id"]: r for r in docs["world"]["rooms"]}
    assert "review_100_days" in rooms["mt_room"]["opens_with"]
    scene = next(s for s in docs["scenes"]["scenes"] if s["id"] == "review_100_days")
    assert scene["room"] == "mt_room" and set(scene["present"]) >= {"ruud", "frank"}
    assert sum(1 for b in scene["beats"] if "choice" in b) == 1, "one question for the player"
    for variant, mission in [("too_early", "fix_done_but_not_closed"), ("too_early", "fix_digging_damage")]:
        assert missions[mission]["debrief_variants"][variant]


BOARD_SCENE = SCENES_YAML.replace("""        choice:
          - {label: "De mensen", fact: "flag:review_people", reply: "Dat dacht ik al."}
          - {label: "De getallen", fact: "flag:review_numbers"}
""", """        board: true
      - {speaker: ruud, line: "Doorlooptijd, dus.", needs: {all: ["steers:flow"]}}
""")


def test_a_scene_can_end_at_the_kpi_board(rules_dirs):
    """The first quarterly review (PLAN 2.4c): a beat with `board: true` opens the KPI
    board where the scene's question would be; steers:<focus> reads the choice after it."""
    content, _ = rules_dirs
    docs = _load(content, _add(_review(), scenes=BOARD_SCENE))
    assert docs["scenes"]["scenes"][0]["beats"][2]["board"] is True


@pytest.mark.parametrize("scenes, message", [
    (BOARD_SCENE.replace("board: true", "board: yes please"), "'board' must be true"),
    (BOARD_SCENE.replace("        board: true\n", """        board: true
        choice:
          - {label: "De mensen", fact: "flag:review_people"}
          - {label: "De getallen", fact: "flag:review_numbers"}
"""), "one question for the player at most"),
    (BOARD_SCENE.replace("steers:flow", "steers:speed"), "the board steers on"),
])
def test_board_scene_errors_are_caught(rules_dirs, scenes, message):
    content, _ = rules_dirs
    with pytest.raises(bc.ContentError, match=message):
        _load(content, _add(_review(), scenes=scenes))


def test_the_real_first_kpi_review():
    """Act II's quarterly review (catalogue: first_kpi_review): a milestone after
    fix_silo_kpis, Ruud and Frank at Directie & Obeya, ending at the board."""
    docs = bc.load_content()
    m = next(m for m in docs["missions"]["missions"] if m["id"] == "first_kpi_review")
    assert m["kind"] == "milestone" and m["act"] == 2 and m["requires"]["missions"] == ["fix_silo_kpis"]
    scene = next(s for s in docs["scenes"]["scenes"] if s["id"] == m["scene"])
    assert scene["room"] == "directors_obeya" and set(scene["present"]) == {"ruud", "frank"}
    assert sum(1 for b in scene["beats"] if b.get("board")) == 1
    assert not any("choice" in b for b in scene["beats"])
    rooms = {r["id"]: r for r in docs["world"]["rooms"]}
    assert "first_kpi_review" in rooms["directors_obeya"]["opens_with"]
    read = {atom for b in scene["beats"] for atoms in b.get("needs", {}).values() for atom in atoms}
    for fact in ["holds:silo_kpis", "committed:frank_kpi_targets", "complied:frank_kpi_targets",
                 "blocked:frank_kpi_targets", "steers:output", "steers:flow", "steers:customer",
                 "forecast_positive:kpi_board"]:
        assert fact in read, f"the scene reads {fact}"
