"""content/explainers.yaml: the "Hoe werkt het?" explainers (PLAN 2.7c; spec
2026-10-16-explainer-spanning-stroom-weerstand §6.2, tests T7, T9 and T10 on the content)."""
from __future__ import annotations

import copy

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture
def docs() -> dict:
    return bc.load_content()


@pytest.fixture
def doc() -> dict:
    return yaml.safe_load((bc.CONTENT_DIR / "explainers.yaml").read_text(encoding="utf-8"))


def _first(doc: dict) -> dict:
    return doc["explainers"][0]


def _beat(doc: dict, beat_id: str) -> dict:
    return next(b for b in _first(doc)["beats"] if b["id"] == beat_id)


def _refused(doc: dict, match: str) -> None:
    with pytest.raises(bc.ContentError, match=match):
        bc.validate_explainers(doc, "explainers.yaml")


def test_the_repo_explainer_is_valid_and_built(docs):
    first = docs["explainers"]["explainers"][0]
    assert first["id"] == "spanning_stroom_weerstand"
    assert {b["id"] for b in first["beats"]} >= set(bc.EXPLAINER_RIGS["ohm_cable"]["beats"])


def test_a_digit_in_a_beat_is_refused(doc):
    _beat(doc, "a1")["lines"][0] = "Kijk: 230 volt."
    _refused(doc, "digit")


def test_a_formula_outside_the_reveal_is_refused(doc):
    _first(doc)["hint"]["meterkast"] = "Onthoud: U = I · R"
    _refused(doc, "formula")


def test_a_formula_in_the_reveal_is_fine(doc):
    bc.validate_explainers(doc, "explainers.yaml")
    assert bc.FORMULA.search(_first(doc)["reveal"]["lines"][0]["formula"])


@pytest.mark.parametrize("token", ["3x25", "netstudie", "Trafo", "zonnepanelen", "warmtepomp", "El Amrani"])
def test_a_line_that_names_a_mission_answer_is_refused(doc, token):
    _first(doc)["caption"].append(f"Denk ook aan de {token}.")
    _refused(doc, "never the answer")


def test_a_step_or_kpi_name_is_refused(docs):
    broken = copy.deepcopy(docs)
    broken["explainers"]["explainers"][0]["caption"].append("Kijk naar de Doorlooptijd end-to-end.")
    with pytest.raises(bc.ContentError, match="step or KPI"):
        bc.check_explainers(broken)


def test_an_unknown_wait_is_refused(doc):
    _beat(doc, "a1")["wait_for"] = "dance"
    _refused(doc, "wait_for")


def test_an_alt_beat_must_replace_a_main_beat(doc):
    _beat(doc, "r5_lamp")["alt_of"] = "nowhere"
    _refused(doc, "alt_of")


def test_a_missing_beat_is_refused(doc):
    _first(doc)["beats"] = [b for b in _first(doc)["beats"] if b["id"] != "r8a"]
    _refused(doc, "r8a")


def test_a_parameter_needs_a_source_or_an_estimate(doc):
    del _first(doc)["parameters"][2]["estimate"]
    _refused(doc, "source or an estimate")


def test_a_parameter_source_must_exist(doc):
    _first(doc)["parameters"][0]["source"] = "a_blog"
    _refused(doc, "a_blog")


def test_a_mapping_pair_must_join_the_two_skins(docs):
    broken = copy.deepcopy(docs)
    broken["explainers"]["explainers"][0]["analogy"]["mapping"][0]["pair"] = ["wall_tap", "tap_gauge"]
    with pytest.raises(bc.ContentError, match="tuin layer and a meterkast layer"):
        bc.check_explainers(broken)


def test_a_control_needs_its_layers_in_the_manifest(docs):
    broken = copy.deepcopy(docs)
    broken["explainers"]["explainers"][0]["controls"][0]["meterkast"] = "switch_toaster"
    with pytest.raises(bc.ContentError, match="switch_toaster"):
        bc.check_explainers(broken)
