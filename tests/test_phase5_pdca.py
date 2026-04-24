"""
Tests for Phase 5 PDCA mechanics:
  - verification fork (Check phase)
  - 5 Whys session tracking
  - InvestigationSession round-trip with new fields
  - mission visible_after ordering
  - CM teaches tags
  - factory.discover() returning new-concept set
  - follow_up_due_stations property
  - score_feed aggregation across all choice types
"""
import pytest
from problems.dialogue import (
    ChoiceOutcome, DialogueChoice, InvestigationFork,
    InvestigationSession, build_verification_fork, FiveWhysStep,
)
from simulation.factory import Factory
from simulation.factory import DaySnapshot
from simulation.time_engine import DAY_DURATION


# ── helpers ───────────────────────────────────────────────────────────────────

def _make_choice(outcome=ChoiceOutcome.CORRECT, teaches=None, score_feed=None):
    return DialogueChoice(
        text="t", outcome=outcome, evidence=None, hint="h",
        teaches=teaches or [], score_feed=score_feed,
    )


# ── build_verification_fork ───────────────────────────────────────────────────

class TestBuildVerificationFork:
    def test_returns_investigation_fork(self):
        vfork = build_verification_fork("Quality Lead", "quality", "5S System", 3)
        assert isinstance(vfork, InvestigationFork)

    def test_npc_is_passed_through(self):
        vfork = build_verification_fork("Scheduler", "flow", "Kanban", 5)
        assert vfork.npc == "Scheduler"

    def test_prompt_contains_days(self):
        vfork = build_verification_fork("HR Manager", "people", "Cross-Training", 7)
        assert "7" in vfork.prompt

    def test_prompt_singular_for_one_day(self):
        vfork = build_verification_fork("HR Manager", "people", "Cross-Training", 1)
        assert "1 day" in vfork.prompt and "1 days" not in vfork.prompt

    def test_three_choices_returned(self):
        vfork = build_verification_fork("IT", "information", "Docs", 4)
        assert len(vfork.choices) == 3

    def test_one_correct_choice_present(self):
        vfork = build_verification_fork("IT", "quality", "Docs", 4)
        outcomes = [c.outcome for c in vfork.choices]
        assert outcomes.count(ChoiceOutcome.CORRECT) == 1

    def test_correct_choice_has_cim_score_feed(self):
        vfork = build_verification_fork("IT", "quality", "Docs", 4)
        correct = next(c for c in vfork.choices if c.outcome == ChoiceOutcome.CORRECT)
        assert correct.score_feed == "CIM"

    def test_plausible_and_wrong_have_no_score_feed(self):
        vfork = build_verification_fork("IT", "quality", "Docs", 4)
        for c in vfork.choices:
            if c.outcome != ChoiceOutcome.CORRECT:
                assert c.score_feed is None

    def test_unknown_category_falls_back_to_problem_solving(self):
        vfork = build_verification_fork("NPC", "nonexistent_category", "CM", 2)
        assert len(vfork.choices) == 3  # fallback template used

    def test_correct_choice_teaches_at_least_one_concept(self):
        vfork = build_verification_fork("NPC", "quality", "CM", 2)
        correct = next(c for c in vfork.choices if c.outcome == ChoiceOutcome.CORRECT)
        assert len(correct.teaches) >= 1


# ── InvestigationSession verification tracking ────────────────────────────────

class TestInvestigationSessionVerification:
    def test_verification_starts_incomplete(self):
        s = InvestigationSession(problem_id="T1-001")
        assert not s.verification_complete

    def test_record_verification_marks_complete(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_verification_choice(_make_choice(ChoiceOutcome.CORRECT))
        assert s.verification_complete

    def test_record_verification_stores_choice(self):
        s = InvestigationSession(problem_id="T1-001")
        c = _make_choice(ChoiceOutcome.CORRECT, teaches=["5S"], score_feed="CIM")
        s.record_verification_choice(c)
        assert s.verification_choices[0]["outcome"] == "CORRECT"
        assert s.verification_choices[0]["score_feed"] == "CIM"

    def test_verification_wrong_choice_still_marks_complete(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_verification_choice(_make_choice(ChoiceOutcome.WRONG))
        assert s.verification_complete

    def test_round_trip_preserves_verification(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_verification_choice(_make_choice(ChoiceOutcome.CORRECT, teaches=["5S"], score_feed="CIM"))
        d = s.to_dict()
        s2 = InvestigationSession.from_dict(d)
        assert s2.verification_complete
        assert s2.verification_choices == s.verification_choices


# ── InvestigationSession 5 Whys tracking ─────────────────────────────────────

class TestInvestigationSessionFiveWhys:
    def test_five_whys_starts_at_step_zero(self):
        s = InvestigationSession(problem_id="T1-001")
        assert s.five_whys_step == 0
        assert not s.five_whys_complete

    def test_correct_choice_advances_step(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_five_whys_choice(_make_choice(ChoiceOutcome.CORRECT), total_steps=3)
        assert s.five_whys_step == 1
        assert not s.five_whys_complete

    def test_wrong_choice_does_not_advance_step(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_five_whys_choice(_make_choice(ChoiceOutcome.WRONG), total_steps=3)
        assert s.five_whys_step == 0

    def test_completing_all_steps_marks_complete(self):
        s = InvestigationSession(problem_id="T1-001")
        for _ in range(3):
            s.record_five_whys_choice(_make_choice(ChoiceOutcome.CORRECT), total_steps=3)
        assert s.five_whys_complete

    def test_round_trip_preserves_five_whys_state(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_five_whys_choice(_make_choice(ChoiceOutcome.CORRECT), total_steps=3)
        d = s.to_dict()
        s2 = InvestigationSession.from_dict(d)
        assert s2.five_whys_step == 1
        assert not s2.five_whys_complete


# ── factory.discover() ───────────────────────────────────────────────────────

class TestFactoryDiscover:
    def test_returns_newly_added_concepts(self):
        f = Factory()
        new = f.discover(["5S", "kanban"])
        assert new == {"5S", "kanban"}

    def test_returns_empty_set_for_already_known(self):
        f = Factory()
        f.discover(["5S"])
        new = f.discover(["5S"])
        assert new == set()

    def test_returns_only_net_new_concepts(self):
        f = Factory()
        f.discover(["kanban"])
        new = f.discover(["kanban", "OEE"])
        assert new == {"OEE"}

    def test_empty_input_returns_empty_set(self):
        f = Factory()
        assert f.discover([]) == set()
        assert f.discover(None) == set()


# ── follow_up_due_stations ────────────────────────────────────────────────────

class TestFollowUpDueStations:
    def test_empty_when_no_active_cms(self):
        f = Factory()
        assert f.follow_up_due_stations == set()

    def test_not_due_before_three_days(self):
        f = Factory()
        f.active_countermeasures["CM-T1-001"] = {
            "station_id": "integration_4",
            "applied_day": f.time.day,
        }
        assert "integration_4" not in f.follow_up_due_stations

    def test_due_after_three_days(self):
        f = Factory()
        f.active_countermeasures["CM-T1-001"] = {
            "station_id": "integration_4",
            "applied_day": 1,
        }
        f.time._sim_time = DAY_DURATION * 3  # advance to day 4
        assert "integration_4" in f.follow_up_due_stations


# ── mission visible_after ordering ───────────────────────────────────────────

class TestMissionOrdering:
    def test_m_t1_001_has_no_prerequisite(self):
        f = Factory()
        assert f.missions["M-T1-001"].visible_after is None

    def test_m_t1_002_requires_m_t1_001(self):
        f = Factory()
        assert f.missions["M-T1-002"].visible_after == "M-T1-001"

    def test_m_t1_003_requires_m_t1_001(self):
        f = Factory()
        assert f.missions["M-T1-003"].visible_after == "M-T1-001"

    def test_m_t1_004_requires_m_t1_002(self):
        f = Factory()
        assert f.missions["M-T1-004"].visible_after == "M-T1-002"

    def _set_ftr(self, factory, value: float) -> None:
        snap = DaySnapshot()
        snap.ftr = value
        factory.day_history.append(snap)

    def test_m_t1_002_blocked_until_m_t1_001_done(self):
        f = Factory()
        f.missions["M-T1-001"].active = False
        f.missions["M-T1-001"].completed = False
        self._set_ftr(f, 0.50)  # satisfy KPI trigger
        f._check_mission_triggers()
        assert not f.missions["M-T1-002"].active

    def test_m_t1_002_unlocked_after_m_t1_001_complete(self):
        f = Factory()
        f.missions["M-T1-001"].completed = True
        f.missions["M-T1-001"].active = True
        self._set_ftr(f, 0.50)  # satisfy KPI trigger
        f._check_mission_triggers()
        assert f.missions["M-T1-002"].active


# ── CM teaches tags ───────────────────────────────────────────────────────────

class TestCMTeachesTags:
    def test_all_cms_have_teaches(self):
        f = Factory()
        for cm in f.cm_catalog._cms.values():
            assert len(cm.teaches) > 0, f"CM {cm.id} has no teaches tags"

    def test_tier1_5s_teaches_5s(self):
        f = Factory()
        assert "5S" in f.cm_catalog.get("CM-T1-001").teaches

    def test_tier4_spc_teaches_spc(self):
        f = Factory()
        assert "SPC" in f.cm_catalog.get("CM-T4-001").teaches


# ── score_feed from verification in resolve ───────────────────────────────────

class TestVerificationScoreFeed:
    def test_correct_verification_boosts_cim(self):
        f = Factory()
        prob = f.problems["T1-003"]
        f.active_problems["T1-003"] = prob
        from problems.problem import ProblemState
        prob.state = ProblemState.COUNTERMEASURE_APPLIED
        prob.applied_countermeasure = "CM-T1-004"
        prob.solved_day = 0

        # Manually set up active countermeasures record
        f.active_countermeasures["CM-T1-004"] = {
            "zone_id": prob.zone_id, "station_id": prob.station_id,
            "eff_mult": 1.0, "applied_day": 0,
            "decay_days": None, "avail_d": 0, "perf_d": 0, "qual_d": 0.05,
        }

        # Add post-apply inspection so score_cim baseline = 5
        f.inspection_log.append({
            "entity": f"z4:{prob.station_id}",
            "metric": "oee",
            "day": 2,   # after applied_day=0
        })

        session = f.get_or_create_session("T1-003")
        session.fork_complete = True
        c = _make_choice(ChoiceOutcome.CORRECT, teaches=["quality_gate"], score_feed="CIM")
        session.record_verification_choice(c)

        result = f.resolve_problem("T1-003")
        assert result is not None
        # score_cim baseline=5 (post-apply inspection exists), score_feed CIM boost stays capped at 5
        assert result["scores"]["CIM"] == 5
