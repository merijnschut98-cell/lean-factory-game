"""A problem's name says what the player sees, never what causes it (Merijn, 2026-10-27, M3;
CLAUDE.md §2: nothing is handed over). The name shows in the A3, the journal and the debriefs, so
it may not hold one of the problem's own countermeasure names, nor a word of its cause bank (the
root cause and the plausible causes) that the problem's symptoms do not already show."""
from __future__ import annotations

import copy

import pytest

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

# The names that read like the answer, before M3, that the check refuses. (Two more were rewritten
# by reading: "De onvolledige aanvraag" gave the key clue away, "KPI's die elkaar bevechten" named the
# silo cause in words no list holds.)
OLD_NAMES = {
    "wrong_joint_in_van": "De verkeerde mof in de bus",
    "custom_design": "Maatwerk voor standaardwerk",
    "permits_in_batches": "Vergunningen in batches",
    "knowledge_drain": "De laatste kennisdrager",
    "status_callers": "De statusbellers",
    "unused_capacity": "Gereserveerd maar ongebruikt",
    "planning_reshuffle": "Storing gooit de planning om",
    "training_tray": "Twee bakken voor hetzelfde werk",
    "overtime_planning": "Overwerk dat in de planning zit",
    "installer_not_ready": "Meterkast niet gereed",
    "transformer_wait": "Wachten op de trafo",
}


@pytest.fixture(scope="module")
def real() -> dict:
    return bc.load_content()


def _problem(docs: dict, problem_id: str) -> dict:
    return next(p for _, p in bc._all_problems(docs) if p["id"] == problem_id)


def _renamed(real: dict, problem_id: str, name: str) -> dict:
    docs = copy.deepcopy(real)
    _problem(docs, problem_id)["name"] = name
    return docs


def test_every_real_problem_name_passes(real):
    bc.check_problems(real)


@pytest.mark.parametrize("problem_id, name", OLD_NAMES.items())
def test_a_name_that_names_the_cause_is_refused(real, problem_id, name):
    with pytest.raises(bc.ContentError, match=rf"problem '{problem_id}': the name {name!r} names"):
        bc.check_problems(_renamed(real, problem_id, name))


def test_a_name_may_not_hold_a_countermeasure_name(real):
    cms = {c["id"]: c["name"] for c in real["countermeasures"]["countermeasures"]}
    for stem, p in bc._all_problems(real):
        for cm in p["countermeasures"]:
            with pytest.raises(bc.ContentError, match=rf"the name .* names countermeasure {cm!r}"):
                bc.check_problems(_renamed(real, p["id"], f"Ons {cms[cm].lower()}"))


def test_a_word_of_the_cause_bank_is_refused_unless_the_symptoms_show_it(real):
    # 'onbetrouwbaar' is a plausible (wrong) cause of not_at_home, and no symptom says it.
    with pytest.raises(bc.ContentError, match="the cause bank"):
        bc.check_problems(_renamed(real, "not_at_home", "Onbetrouwbare klanten"))
    # 'netstudie' is in the root cause of grid_study_queue, and its symptoms show the studies.
    bc.check_problems(_renamed(real, "grid_study_queue", "Netstudies in de wachtrij"))


def test_a_short_word_is_never_a_cause_word(real):
    # 'keer' and 'twee' sit in cause texts; short words are function words and are let through.
    bc.check_problems(_renamed(real, "double_visits", "Twee keer naar hetzelfde adres"))
