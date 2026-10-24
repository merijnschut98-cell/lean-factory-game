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
    docs["company"].pop("people")  # built by check_company, never authored
    mutate(docs["company"])
    bc.validate_company(docs["company"], "company.yaml")
    bc.check_company(docs)


def _dept(company: dict, dept_id: str) -> dict:
    return next(d for d in company["departments"] if d["id"] == dept_id)


def _team(company: dict, team_id: str) -> dict:
    return next(t for d in company["departments"] for t in d["teams"] if t["id"] == team_id)


def _number(company: dict, number_id: str) -> dict:
    return next(n for n in company["numbers"] if n["id"] == number_id)


def test_a_zuidmark_number_that_is_a_clue_waits_for_the_clue(real):
    """The 62 % is unused_capacity's key data clue: the codex shows it only once found."""
    assert _number(real["company"], "gecontracteerd_benut_zuidmark")["revealed_by"] == ["unused_capacity:0"]
    for nid in ["gotork_drempel_benut", "gotork_drempel_mw"]:
        assert "revealed_by" not in _number(real["company"], nid), "national regulation stays a sector fact"


def test_an_estimated_number_shows_its_basis_never_its_reasoning(real):
    for n in real["company"]["numbers"]:
        if "estimate" in n:
            assert n["basis"] and bc.developer_word(n["basis"]) is None, n["id"]


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


def test_every_team_has_a_lead(real):
    """Slice 3 (§1.6): a team names its lead: someone in the cast, a named person not in
    it yet, or `head` (the department's head leads it directly)."""
    company = real["company"]
    managers = bc.company_managers(company)
    for d in company["departments"]:
        for t in d["teams"]:
            assert "lead" in t, t["id"]
    assert _team(company, "planning")["lead"] == "head"
    assert managers["linda"] == "Frank Hulshof"
    assert managers["yvonne"] == _team(company, "ontvangst")["lead"]["name"], "a named lead"
    assert managers["dirk"] == "Marco Peters"


def test_act_two_has_its_teams(real):
    """The six Act II mains touch Revisie & GIS, Netstudies, the projectteam netverzwaring
    and Inkoop, the congestiedesk and the MT: all are in the company with a lead."""
    company = real["company"]
    for team in ["revisie", "netplanning", "projecten", "inkoop", "grootzakelijk", "directie_staf"]:
        assert _team(company, team)["lead"], team
    assert _team(company, "projecten")["lead"]["title"] == "projectleider netverzwaring"


def test_a_teams_headcount_holds_the_people_placed_in_it(real):
    for d in real["company"]["departments"]:
        for t in d["teams"]:
            placed = len(t.get("members", [])) + int(isinstance(t["lead"], dict) and "id" in t["lead"])
            assert t["headcount"]["value"] >= placed, t["id"]


def test_the_built_file_indexes_every_person(real):
    """company.json carries `people`: id → title, department, team and manager (by name),
    so Wie is wie and the briefings read one place."""
    people = real["company"]["people"]
    assert people["anouk"] == {"title": "werkvoorbereider", "department": "Aansluitingen & Netverzwaring",
                               "team": "Werkvoorbereiding", "manager": "Joost van Dijk"}
    assert people["ruud"]["manager"] == ""
    assert people["gert"] == {"title": "uitvoerder, Grondwerk Peeters", "organisation": "Grondwerk Peeters"}
    assert set(people) == set(bc.company_people(real["company"]))


def test_the_sector_numbers_come_from_all_three_named_sources(real):
    """Design §1.6 names netbeheernederland.nl, acm.nl and cbs.nl."""
    hosts = {n["source"]["url"].split("/")[2] for n in real["company"]["numbers"] if "source" in n}
    for host in ["www.netbeheernederland.nl", "www.acm.nl", "www.cbs.nl"]:
        assert host in hosts, host


def test_a_site_staff_count_carries_an_estimate(real):
    sites = {s["id"]: s for s in real["company"]["sites"]}
    for site in ["lindeveld", "havenzij"]:
        assert "estimate" in sites[site]["headcount"], site


@pytest.mark.parametrize("mutate, message", [
    (lambda c: _team(c, "planning").pop("lead"), "team 'planning': needs a 'lead'"),
    (lambda c: _team(c, "planning").update(lead="boss"), "team 'planning' lead: needs"),
    (lambda c: _team(c, "magazijn")["members"].extend(_team(c, "kcc_agents").pop("members")),
     "team 'magazijn': 3 people placed but a headcount of 2"),
    (lambda c: next(s for s in c["sites"] if s["id"] == "havenzij")["headcount"].pop("estimate"),
     "site 'havenzij' headcount: give a source or an estimate"),
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
    # A Zuidmark number that is a problem's clue shows only once the clue is found.
    (lambda c: _number(c, "gecontracteerd_benut_zuidmark").pop("revealed_by"), "repeats clue 'unused_capacity:0'"),
    (lambda c: _number(c, "gotork_drempel_mw").update(label="Use-it-or-lose-it-gesprekken"),
     "names countermeasure 'use_it_or_lose_it'"),
    (lambda c: _number(c, "technici_zuidmark").update(basis="Zoals Ilse de Graaf zegt."),
     "names 'Ilse de Graaf'"),
    (lambda c: _number(c, "wachtlijst_afname_zuidmark").update(revealed_by=["unused_capacity:99"]),
     "'unused_capacity:99' is not a clue or a fact"),
    # Shown text is in-world: the developer's reasoning stays in `estimate`.
    (lambda c: _number(c, "technici_zuidmark").update(basis="Zie value_streams.yaml, monteurs."), "developer word"),
    (lambda c: _number(c, "technici_zuidmark").update(label="Monteurs die de simulatie rekent"), "developer word"),
    (lambda c: next(s for s in c["sites"] if s["id"] == "havenzij").update(about="Het spel begint hier."),
     "developer word"),
    (lambda c: _number(c, "technici_zuidmark").pop("basis"), "number 'technici_zuidmark': an estimate needs a "
                                                             "'basis'"),
])
def test_company_errors_are_caught(real, mutate, message):
    with pytest.raises(bc.ContentError, match=message):
        _check(real, mutate)
