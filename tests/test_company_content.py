"""content/company.yaml (phase-2 design §1.6, S1-E): the company file, one source for who
works where, under whom and with what title."""
from __future__ import annotations

import copy
import json

import pytest

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)


@pytest.fixture(scope="module")
def real() -> dict:
    return bc.load_content()


def _cast() -> list[dict]:
    return json.loads(bc.CAST_FILE.read_text(encoding="utf-8"))["characters"]


def _check(real: dict, mutate) -> None:
    docs = copy.deepcopy(real)
    mutate(docs["company"])
    bc.validate_company(docs["company"], "company.yaml")
    bc.check_company(docs)


def _dept(company: dict, dept_id: str) -> dict:
    return next(d for d in company["departments"] if d["id"] == dept_id)


def _team(company: dict, team_id: str) -> dict:
    return next(t for d in company["departments"] for t in d["teams"] if t["id"] == team_id)


def test_every_cast_member_and_speaking_person_is_placed(real):
    placed = bc.company_people(real["company"])
    for c in _cast():
        assert c["id"] in placed, c["id"]
    for p in real["dialogs"]["people"]:
        assert p["id"] in placed, p["id"]


def test_every_voltana_person_has_a_department_and_a_manager(real):
    managers = bc.company_managers(real["company"])
    assert managers["anouk"] == "Joost van Dijk"
    assert managers["joost"] == "Frank Hulshof"
    assert managers["frank"] == "Ruud Hoekstra"
    assert managers["linda"] == "Frank Hulshof", "a team without a lead: the department's head"
    assert managers["mieke"] == "Karin Hoekman", "a manager named here, not yet in the cast"
    assert managers["player"] == "Ruud Hoekstra"
    assert managers["ruud"] == "", "the directeur reports to the hoofdkantoor"
    people = bc.company_people(real["company"])
    for pid, entry in people.items():
        if entry["department"]:
            assert managers[pid] or pid == "ruud", pid


def test_the_second_floor_reports_to_ruud(real):
    """Design §1.6 to the 2e: the directie, Netstrategie and the congestiedesk each report
    to Ruud; their teams have the cast's people as leads."""
    company = real["company"]
    managers = bc.company_managers(company)
    for dept in ["netstrategie", "congestiedesk"]:
        assert _dept(company, dept)["reports_to"] == "directie", dept
    assert managers["thomas"] == "Ruud Hoekstra", "the congestiedesk is the directie's"
    assert _team(company, "netplanning")["lead"]["id"] == "femke"
    assert managers["femke"] == "Ingrid Bos"
    assert managers["frank"] == "Ruud Hoekstra"
    assert _team(company, "directie_staf").get("about"), "the MT and who sits in it"


def test_the_congestion_numbers_carry_their_sources(real):
    """The waiting list, GOTORK (fix_unused_capacity) and the technician shortage: national
    numbers from an approved source, Zuidmark's as estimates with their reasoning."""
    numbers = {n["id"]: n for n in real["company"]["numbers"]}
    for nid in ["wachtlijst_afname_nl", "gotork_drempel_benut", "gotork_drempel_mw", "technici_nodig_nl"]:
        assert "source" in numbers[nid], nid
    assert numbers["gotork_drempel_benut"]["source"]["url"].startswith("https://www.acm.nl/")
    for nid in ["wachtlijst_afname_zuidmark", "gecontracteerd_benut_zuidmark", "technici_zuidmark"]:
        assert "estimate" in numbers[nid], nid


def test_titles_agree_with_the_cast_and_the_dialogs(real):
    titles = {pid: e["title"] for pid, e in bc.company_people(real["company"]).items()}
    for c in _cast():
        assert titles[c["id"]] == c["role"], c["id"]
    for p in real["dialogs"]["people"]:
        assert titles[p["id"]] == p["role"], p["id"]


def test_a_pooled_team_has_its_pools_headcount_and_every_number_its_source(real):
    built = real["company"]
    assert _team(built, "werkvoorbereiding")["headcount"]["value"] == 4, "the pool's four: Anouk and three colleagues"
    for n in built["numbers"]:
        assert ("source" in n) != ("estimate" in n), n["id"]


@pytest.mark.parametrize("mutate, message", [
    (lambda c: _team(c, "werkvoorbereiding")["members"].clear(), "'anouk' .* is not in company.yaml"),
    (lambda c: _team(c, "werkvoorbereiding")["members"][0].update(title="tekenaar"),
     "'anouk': title 'tekenaar' .* 'werkvoorbereider'"),
    (lambda c: _team(c, "planning").update(pool="ghosts", headcount={"value": 2, "pool": "ghosts"}),
     "unknown pool 'ghosts'"),
    (lambda c: _team(c, "magazijn")["headcount"].pop("estimate"), "a source or an estimate"),
    (lambda c: c["numbers"][0]["source"].update(url="https://example.com/x"), "not an approved source"),
    (lambda c: _dept(c, "kcc").update(reports_to="nowhere"), "reports to unknown department 'nowhere'"),
    (lambda c: _dept(c, "revisie_gis").update(head={"id": "nobody", "title": "baas"}), "'nobody' is not in the cast"),
    (lambda c: _dept(c, "revisie_gis").update(head={"name": "Anouk de Vries", "title": "baas"}),
     "is in the cast: name them by id"),
    (lambda c: _team(c, "kcc_agents")["members"].append({"id": "anouk", "title": "werkvoorbereider"}),
     "'anouk' is placed twice"),
    (lambda c: _dept(c, "directie").update(reports_to="kcc"), "the directie reports to no department"),
    (lambda c: _dept(c, "kcc").update(site="mars"), "unknown site 'mars'"),
])
def test_company_errors_are_caught(real, mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(real, mutate)
