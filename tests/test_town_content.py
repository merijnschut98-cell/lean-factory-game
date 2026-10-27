"""The street the player reaches by van (content/town.yaml, slice 3.2): a tiny street graph in the content pipeline."""
from __future__ import annotations

import copy
import json

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}


def _lot(town: dict, lot_id: str) -> dict:
    return next(l for l in town["lots"] if l["id"] == lot_id)


def _prop(town: dict, prop_id: str) -> dict:
    return next(p for p in town["props"] if p["id"] == prop_id)


def _check(mutate) -> None:
    docs = copy.deepcopy(REAL)
    mutate(docs["town"])
    bc.validate_town(docs["town"], "town.yaml")
    bc.check_town(docs)


def _refused(mutate, match: str) -> None:
    with pytest.raises(bc.ContentError, match=match):
        _check(mutate)


def _drop(town: dict, key: str, kind: str, keep: int = 0) -> None:
    """Remove every entry of `kind` from town[key] after the first `keep`."""
    town[key][:] = [e for e in town[key] if e["kind"] != kind] + [e for e in town[key] if e["kind"] == kind][:keep]


def test_the_real_street_is_valid_with_twelve_houses_a_shop_and_a_trafohuisje():
    town = bc.load_content()["town"]
    kinds = [l["kind"] for l in town["lots"]]
    assert kinds.count("house") == 12 and kinds.count("shop") == 1 and kinds.count("trafohuisje") == 1
    seg = town["segments"][0]
    assert len(town["segments"]) == 1 and seg["to"] == [120, 0] and seg["name"] == "Zonnestraat"


def test_el_amrani_lives_at_nine_and_carries_the_story():
    lot = next(l for l in bc.load_content()["town"]["lots"] if l.get("story") == "el_amrani")
    assert (lot["n"], lot["resident"]) == (9, "el_amrani")


def test_the_three_residents_and_the_field_steps_of_the_real_street():
    town = bc.load_content()["town"]
    assert {l["resident"]: l["n"] for l in town["lots"] if "resident" in l} == {"de_jong": 4, "wim": 14, "el_amrani": 9}
    assert {f["step"]: f["at"] for f in town["fields"]} == {"meters.visit": "house_7", "outages.locate": "trench"}


def test_the_street_dimensions_are_marked_as_an_estimate_with_their_reasoning():
    text = (bc.CONTENT_DIR / "town.yaml").read_text(encoding="utf-8")
    assert "estimate:" in text.split("segments:")[0], "the estimate and its reasoning stand at the top"


def test_house_numbers_follow_the_side():
    _refused(lambda t: _lot(t, "house_2").update(n=3), "number 3 .* odd side")
    _refused(lambda t: _lot(t, "house_3").update(n=4), "number 4 .* even side")
    _refused(lambda t: _lot(t, "house_6").update(n=4), "number 4 .*twice")


def test_every_house_and_the_shop_has_a_number():
    _refused(lambda t: _lot(t, "house_8").pop("n"), "needs a number")


def test_there_are_exactly_twelve_houses():
    _refused(lambda t: t["lots"].remove(_lot(t, "house_12")), "12 houses")


def test_lots_on_one_side_must_not_overlap():
    _refused(lambda t: _lot(t, "house_6").update(at=20), "overlaps")


def test_a_lot_must_lie_inside_the_street():
    _refused(lambda t: _lot(t, "house_11").update(at=115), "outside the street")
    _refused(lambda t: _lot(t, "house_2").update(at=-1), "outside the street")


def test_a_prop_must_lie_within_the_street_and_its_ends():
    _refused(lambda t: _prop(t, "lamp_1").update(at=-6), "outside the street")
    _refused(lambda t: _prop(t, "lamp_1").update(at=136), "outside the street")
    _check(lambda t: _prop(t, "lamp_1").update(at=135))


def test_the_shop_stands_on_a_corner_and_the_trafohuisje_at_the_far_end():
    _refused(lambda t: _lot(t, "shop").update(at=80), "corner")
    _refused(lambda t: _lot(t, "trafohuisje").update(at=76), "far end")
    _refused(lambda t: _lot(t, "trafohuisje").update(at=14), "far end")
    _refused(lambda t: t["lots"].remove(_lot(t, "shop")), "exactly one shop")
    _refused(lambda t: t["lots"].remove(_lot(t, "trafohuisje")), "exactly one trafohuisje")


def test_a_resident_lives_in_one_house_only():
    _refused(lambda t: _lot(t, "house_6").update(resident="de_jong"), "one house")


def test_only_a_house_has_a_resident():
    _refused(lambda t: _lot(t, "shop").update(resident="wim"), "only a house")


def test_the_story_lot_is_el_amrani_s_own_house():
    _refused(lambda t: _lot(t, "house_9").pop("story"), "exactly one .*el_amrani")
    _refused(lambda t: _lot(t, "house_9").update(resident="someone_else"), "story 'el_amrani' needs its own resident")
    _refused(lambda t: _lot(t, "house_7").update(story="el_amrani"), "exactly one .*el_amrani")
    _refused(lambda t: _lot(t, "house_9").update(story="nobody"), "unknown story")


def test_exactly_one_kerb_van_with_its_yard_van():
    _refused(lambda t: _prop(t, "van_kerb").pop("kerb"), "exactly one kerb van")
    _refused(lambda t: _prop(t, "van_peeters").update(kerb=True, yard_van=6), "exactly one kerb van")
    _refused(lambda t: _prop(t, "van_kerb").pop("yard_van"), "yard_van")
    _refused(lambda t: _prop(t, "van_kerb").update(yard_van="five"), "yard_van")
    _refused(lambda t: _prop(t, "van_peeters").update(yard_van=3), "yard_van")


def test_the_trench_the_hedges_the_canal_and_the_lamps():
    _refused(lambda t: t["props"].remove(_prop(t, "trench")), "exactly one trench")
    _refused(lambda t: t["props"].remove(_prop(t, "canal")), "exactly one canal")
    _refused(lambda t: t["props"].remove(_prop(t, "hedge_west")), "2 hedges")
    _refused(lambda t: _drop(t, "props", "lamp", keep=3), "4 to 8 lamps")
    _refused(lambda t: t["props"].extend({"id": f"lamp_x{i}", "kind": "lamp", "side": "odd", "at": 5 + i} for i in range(3)),
             "4 to 8 lamps")


def test_a_prop_stands_on_a_side_or_across_the_street():
    _refused(lambda t: _prop(t, "lamp_1").pop("side"), "side or across")
    _refused(lambda t: _prop(t, "hedge_west").update(side="even"), "side or across")


def test_a_field_names_a_real_step_and_a_lot_or_prop():
    _refused(lambda t: t["fields"][0].update(step="meters.nowhere"), "unknown step")
    _refused(lambda t: t["fields"][0].update(at="house_99"), "unknown lot or prop")
    _refused(lambda t: t["fields"].append(dict(t["fields"][0])), "twice")


def test_lot_and_prop_ids_are_unique_together():
    _refused(lambda t: _prop(t, "trench").update(id="house_7"), "duplicate")


def test_the_street_has_one_segment_of_a_sane_length():
    _refused(lambda t: t["segments"].append(dict(t["segments"][0], id="other")), "exactly one segment")
    _refused(lambda t: t["segments"][0].update(to=[90, 0]), "between 100 and 140")
    _refused(lambda t: t["segments"][0].update(to=[120]), "two numbers")


def test_unknown_keys_are_refused():
    _refused(lambda t: t.update(doors=[]), "unknown key")
    _refused(lambda t: t["segments"][0].update(lanes=2), "unknown key")
    _refused(lambda t: _lot(t, "house_2").update(colour="red"), "unknown key")
    _refused(lambda t: _prop(t, "lamp_1").update(bulb="led"), "unknown key")
    _refused(lambda t: t["fields"][0].update(why="x"), "unknown key")


def test_the_built_json_carries_the_street():
    data = json.loads((bc.DATA_DIR / "town.json").read_text(encoding="utf-8"))
    assert data == bc.load_content()["town"]
