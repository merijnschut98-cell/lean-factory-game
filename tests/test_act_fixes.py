"""The fixes a mission offers in its own act (Act 0/I mission audit, 2026-10-24).

A countermeasure works by its fit times the region's maturity (Pdca.effectiveness), and
the A3 offers only those up to one tier above the maturity (Region.available_countermeasures).
Read with the maturity an act is played at, three things must hold:
- the patient fix is reachable: every solve mission's problem has a fix that the A3
  offers, that works (CHECK_PASS) and that is not a poor fix (Missions.POOR_FIT_GAP);
- a designed failed Check is real: a mission's `too_early` debrief needs a fitting
  countermeasure that the A3 offers in its act and that works below CHECK_PASS;
- a debrief never tells a player who chose a passing poor fix that they chose the best
  one: such a mission has a `poor_fix` debrief (training days excepted: their debriefs
  hold for every fix, and Friday's lesson is borgen).
Failures are content to fix, never the test."""
from __future__ import annotations

import re

import pytest
import yaml

import build_content as bc  # tools/ is on pytest's pythonpath (pytest.ini)

REAL = {path.stem: yaml.safe_load(path.read_text(encoding="utf-8")) for path in bc.CONTENT_DIR.glob("*.yaml")}
CMS = {c["id"]: c for c in REAL["countermeasures"]["countermeasures"]}
PROBLEMS = {p["id"]: p for p in REAL["problems_tier1"]["problems"]}
SOLVES = [m for m in REAL["missions"]["missions"] if m["goal"].get("type") == "solve"]

_RULES = bc.ROOT / "game" / "src" / "rules"
CHECK_PASS = float(re.search(r"const CHECK_PASS := ([0-9.]+)", (_RULES / "pdca.gd").read_text(encoding="utf-8")).group(1))
POOR_FIT_GAP = float(re.search(r"const POOR_FIT_GAP := ([0-9.]+)",
                               (_RULES / "missions.gd").read_text(encoding="utf-8")).group(1))
LEVELS = ["full", "reduced", "minimal"]
# ESTIMATE (the autoplay of 2026-10-23): the training week and Act I play at maturity 1
# (twelve of the twenty tier-1 problems must be resolved for 2; the expert has nine by
# the last Act I main), Act II at 2.
ACT_MATURITY = {0: 1, 1: 1, 2: 2}


def _ids(missions: list[dict]) -> list[str]:
    return [m["id"] for m in missions]


def _offered(cm_id: str, maturity: int) -> bool:
    return CMS[cm_id]["tier"] <= maturity + 1


def _eff(problem_id: str, cm_id: str, maturity: int) -> float:
    cm = CMS[cm_id]
    level = LEVELS[max(0, cm["tier"] - maturity)]
    return cm["multipliers"][level] * PROBLEMS[problem_id]["countermeasures"][cm_id]


def _poor(problem_id: str, cm_id: str) -> bool:
    fits = PROBLEMS[problem_id]["countermeasures"]
    return fits[cm_id] <= max(fits.values()) - POOR_FIT_GAP + 1e-9


def _passing(m: dict) -> list[str]:
    """The countermeasures of `m`'s problem that its act's A3 offers and that work."""
    problem_id, maturity = m["goal"]["problem"], ACT_MATURITY[m["act"]]
    return [c for c in PROBLEMS[problem_id]["countermeasures"]
            if _offered(c, maturity) and _eff(problem_id, c, maturity) >= CHECK_PASS]


@pytest.mark.parametrize("m", SOLVES, ids=_ids(SOLVES))
def test_the_patient_fix_is_reachable_in_its_act(m):
    problem_id = m["goal"]["problem"]
    assert any(not _poor(problem_id, c) for c in _passing(m)), \
        f"{m['id']}: in act {m['act']} every fix that works is a poor fix ({_passing(m)})"


@pytest.mark.parametrize("m", [m for m in SOLVES if "too_early" in m.get("debrief_variants", {})],
                         ids=lambda m: m["id"])
def test_a_designed_failed_check_can_happen(m):
    problem_id, maturity = m["goal"]["problem"], ACT_MATURITY[m["act"]]
    too_early = [c for c in PROBLEMS[problem_id]["countermeasures"]
                 if _offered(c, maturity) and CMS[c]["tier"] > maturity and _eff(problem_id, c, maturity) < CHECK_PASS]
    assert too_early, f"{m['id']}: no countermeasure the A3 offers in act {m['act']} is too early"


@pytest.mark.parametrize("m", [m for m in SOLVES if m["kind"] != "training"], ids=lambda m: m["id"])
def test_a_passing_poor_fix_has_its_own_debrief(m):
    poor = [c for c in _passing(m) if _poor(m["goal"]["problem"], c)]
    assert not poor or "poor_fix" in m.get("debrief_variants", {}), \
        f"{m['id']}: {poor} pass as poor fixes, but the debrief describes the best fix"



# A `poor_fix` debrief describes the poor fix the player chose, so it must read true for every
# poor fix that can trigger it (review 381d21c..0ec040f #3; a wrong root cause no longer does:
# fact wrong_cause). Each text was read against these countermeasures; a new poor fix for one of
# these problems fails here until someone rereads the text for it and adds it.
POOR_FIX_TEXT_READ_FOR = {
    "fix_custom_design": {"delegated_approval"},
    "fix_incomplete_application": {"intake_checklist"},
    "fix_installer_not_ready": {"backup_job_per_day"},
    "fix_status_callers": {"realistic_promise"},
    "fix_done_but_not_closed": {"mid_month_run"},
    "fix_revision_backlog": {"daily_revision_template"},
    "fix_grid_study_queue": {"calculation_templates", "study_overtime_sprint"},
    "fix_transformer_wait": {"strategic_transformer_stock"},
    "fix_unused_capacity": {"capacity_usage_dashboard", "flexible_contracts"},
    "fix_silo_kpis": {"connections_wip_limit", "shared_team_goals"},
    "fix_wrong_joint": {"van_refill_card"},
    "fix_silent_meter": {"coverage_check_in_planning"},
    "fix_inverters_tripping": {"tap_trial_one_station", "smart_meter_voltage_data", "targeted_reinforcement"},
    "save_henks_knowledge": {"henks_one_point_lessons", "work_instruction_videos"},
    "fix_double_visits": {"customer_self_report"},
    "fix_overtime_planning": {"overtime_cap"},
}


def test_every_poor_fix_debrief_was_read_for_every_poor_fix_that_shows_it():
    with_text = {m["id"]: m for m in REAL["missions"]["missions"] if "poor_fix" in m.get("debrief_variants", {})}
    assert set(with_text) == set(POOR_FIX_TEXT_READ_FOR), "a poor_fix debrief added or removed: read it and list it"
    for mission_id, m in with_text.items():
        fits = PROBLEMS[m["goal"]["problem"]]["countermeasures"]
        poor = {c for c, f in fits.items() if f <= max(fits.values()) - POOR_FIT_GAP + 1e-9}
        assert poor == POOR_FIX_TEXT_READ_FOR[mission_id], f"{mission_id}: reread its poor_fix debrief for {poor}"


# The plain debrief (and a fork branch's `debrief_first`) is what every other fix that passes
# gets: a good fit, or a poor one where the mission has no `poor_fix` debrief, with the cause
# named right or wrong. It describes what changed in the work and the numbers, so it must
# read true for each of them, not only for the best fix (Q-1, 2026-10-25). A mission can be
# played after its act (a careless player, a fix that faded), so this counts every fix that
# passes at full maturity. Each text was read against these countermeasures; a new one fails
# here until someone rereads the text for it and adds it.
PLAIN_TEXT_READ_FOR = {
    "fix_custom_design": {"standard_designs"},
    "fix_incomplete_application": {"poka_yoke_application"},
    "fix_installer_not_ready": {"readiness_check", "installer_photo_upload"},
    "fix_status_callers": {"milestone_mail_by_hand", "proactive_status_updates"},
    "fix_done_but_not_closed": {"close_out_at_completion", "automatic_ean_registration"},
    "fix_digging_damage": {"standard_test_trenches", "contractor_briefing", "revision_at_source"},
    "fix_revision_backlog": {"revision_at_source"},
    "fix_grid_study_queue": {"triage_fast_lane"},
    "fix_transformer_wait": {"early_transformer_order", "framework_contracts"},
    "fix_unused_capacity": {"use_it_or_lose_it"},
    "fix_silo_kpis": {"obeya_end_to_end"},
    "fix_wrong_joint": {"standard_van_stock", "two_bin_van_kanban"},
    "fix_not_at_home": {"appointment_reminder", "two_hour_window"},
    "fix_silent_meter": {"on_site_comm_test"},
    "fix_permits_in_batches": {"request_permits_daily", "parallel_permits"},
    "fix_inverters_tripping": {"tap_review_per_neighbourhood"},
    "save_henks_knowledge": {"twi_job_instruction", "skills_matrix_buddy"},
    "fix_planning_reshuffle": {"daytime_outage_crew", "planning_with_fault_windows", "heijunka_release"},
    "fix_double_visits": {"cupboard_photo_at_booking", "register_cupboard_check"},
    "fix_overtime_planning": {"route_by_area", "area_teams"},
}


def test_every_plain_debrief_was_read_for_every_fix_that_shows_it():
    with_text = {m["id"]: m for m in SOLVES if m["kind"] != "training"}
    assert set(with_text) == set(PLAIN_TEXT_READ_FOR), "a solve mission added or removed: read its debrief and list it"
    for mission_id, m in with_text.items():
        problem_id = m["goal"]["problem"]
        has_poor_text = "poor_fix" in m.get("debrief_variants", {})
        # at a maturity of its own tier, a countermeasure works at full strength
        shown = {c for c in PROBLEMS[problem_id]["countermeasures"]
                 if _eff(problem_id, c, CMS[c]["tier"]) >= CHECK_PASS and not (has_poor_text and _poor(problem_id, c))}
        assert shown == PLAIN_TEXT_READ_FOR[mission_id], f"{mission_id}: reread its plain debrief for {shown}"
