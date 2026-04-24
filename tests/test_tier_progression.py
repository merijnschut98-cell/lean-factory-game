"""Tests for multi-tier mission loading and tier progression visibility."""
import pytest
from problems.mission import load_all_missions, load_missions
from problems.catalog import load_all, load_tier
from problems.problem import ProblemState
from problems.visibility import evaluate_visibility
from pathlib import Path


# ── Mission loading ────────────────────────────────────────────────────────────

class TestLoadAllMissions:
    @pytest.fixture(scope="class")
    def all_missions(self):
        return load_all_missions()

    def test_loads_all_four_tiers(self, all_missions):
        ids = set(all_missions.keys())
        assert any(m.startswith("M-T1-") for m in ids)
        assert any(m.startswith("M-T2-") for m in ids)
        assert any(m.startswith("M-T3-") for m in ids)
        assert any(m.startswith("M-T4-") for m in ids)

    def test_tier1_count(self, all_missions):
        assert sum(1 for m in all_missions if m.startswith("M-T1-")) == 5

    def test_tier2_count(self, all_missions):
        assert sum(1 for m in all_missions if m.startswith("M-T2-")) == 5

    def test_tier3_count(self, all_missions):
        assert sum(1 for m in all_missions if m.startswith("M-T3-")) == 4

    def test_tier4_count(self, all_missions):
        assert sum(1 for m in all_missions if m.startswith("M-T4-")) == 4

    def test_total_mission_count(self, all_missions):
        assert len(all_missions) == 18

    def test_all_problems_covered(self, all_missions):
        """Every problem in tiers 1–4 must appear in exactly one mission."""
        problems = load_all()
        gated = set()
        for m in all_missions.values():
            gated.update(m.problem_ids)
        ungated = [pid for pid in problems if pid not in gated]
        assert ungated == [], f"Problems not in any mission: {ungated}"

    def test_no_duplicate_problem_assignments(self, all_missions):
        """No problem should appear in more than one mission."""
        seen = {}
        for mid, mission in all_missions.items():
            for pid in mission.problem_ids:
                assert pid not in seen, (
                    f"{pid} assigned to both {seen[pid]} and {mid}"
                )
                seen[pid] = mid

    def test_visible_after_references_valid_mission(self, all_missions):
        """All visible_after values must reference a real mission ID."""
        for mission in all_missions.values():
            if mission.visible_after:
                assert mission.visible_after in all_missions, (
                    f"{mission.id} visible_after={mission.visible_after!r} is not a real mission"
                )

    def test_t2_missions_gated_after_t1(self, all_missions):
        """All Tier 2 missions must require a Tier 1 mission to be completed first."""
        for mid, mission in all_missions.items():
            if mid.startswith("M-T2-"):
                assert mission.visible_after is not None, f"{mid} has no visible_after"
                assert mission.visible_after.startswith("M-T1-") or \
                       mission.visible_after.startswith("M-T2-"), \
                    f"{mid} visible_after={mission.visible_after} is unexpected"

    def test_t3_missions_gated_after_t2(self, all_missions):
        """All Tier 3 missions must require a Tier 2 mission to be completed first."""
        for mid, mission in all_missions.items():
            if mid.startswith("M-T3-"):
                assert mission.visible_after is not None
                assert mission.visible_after.startswith("M-T2-") or \
                       mission.visible_after.startswith("M-T3-"), \
                    f"{mid} visible_after={mission.visible_after} is unexpected"

    def test_t4_missions_gated_after_t3(self, all_missions):
        """All Tier 4 missions must require a Tier 3 mission to be completed first."""
        for mid, mission in all_missions.items():
            if mid.startswith("M-T4-"):
                assert mission.visible_after is not None
                assert mission.visible_after.startswith("M-T3-") or \
                       mission.visible_after.startswith("M-T4-"), \
                    f"{mid} visible_after={mission.visible_after} is unexpected"

    def test_all_missions_have_hints(self, all_missions):
        for mission in all_missions.values():
            assert len(mission.hints) >= 1, f"{mission.id} has no hints"

    def test_all_missions_have_source_npc(self, all_missions):
        for mission in all_missions.values():
            assert mission.source_npc, f"{mission.id} has no source_npc"

    def test_tier_problem_ids_match_catalog(self, all_missions):
        """Problem IDs referenced in mission YAML must exist in the problem catalog."""
        catalog = load_all()
        for mission in all_missions.values():
            for pid in mission.problem_ids:
                assert pid in catalog, f"Mission {mission.id} references unknown problem {pid}"


# ── Visibility: hidden problem activation ─────────────────────────────────────

class _MockFactory:
    """Minimal factory stub for visibility testing."""
    def __init__(self, missions, inspection_log=None):
        self.missions = missions
        self.inspection_log = inspection_log or []

    @property
    def time(self):
        class _T:
            day = 1
        return _T()


class TestHiddenVisibility:
    def _make_problem(self, pid, visibility, zone_id="z1", severity="medium"):
        from problems.problem import Problem
        return Problem(
            id=pid, name=pid, category="Test", severity=severity,
            visibility=visibility, zone_id=zone_id, station_id="s1",
            symptoms=[], root_cause="", effective_countermeasures=[],
            maturity_prerequisite=None, mismatch_note="",
            side_effect_ref=None, effect_modifiers={},
        )

    def test_hidden_stays_dormant_with_no_mission_resolutions(self):
        from problems.mission import Mission, MissionTrigger
        hidden = self._make_problem("T2-004", "hidden")
        obvious = self._make_problem("T2-006", "obvious")
        problems = {p.id: p for p in [hidden, obvious]}

        mission = Mission(
            id="M-T2-001", title="Test", description="", source_npc="Team Leader",
            trigger=MissionTrigger(type="auto"),
            problem_ids=["T2-004", "T2-006"],
            hints=["hint"],
            active=True,
            problems_resolved=[],
        )
        factory = _MockFactory({"M-T2-001": mission})
        evaluate_visibility(problems, factory)

        assert hidden.state == ProblemState.DORMANT
        assert obvious.state == ProblemState.ACTIVE

    def test_hidden_activates_after_peer_resolved(self):
        from problems.mission import Mission, MissionTrigger
        hidden = self._make_problem("T2-004", "hidden")
        obvious = self._make_problem("T2-006", "obvious")
        problems = {p.id: p for p in [hidden, obvious]}
        obvious.state = ProblemState.RESOLVED

        mission = Mission(
            id="M-T2-001", title="Test", description="", source_npc="Team Leader",
            trigger=MissionTrigger(type="auto"),
            problem_ids=["T2-004", "T2-006"],
            hints=["hint"],
            active=True,
            problems_resolved=["T2-006"],
        )
        factory = _MockFactory({"M-T2-001": mission})
        newly = evaluate_visibility(problems, factory)

        assert "T2-004" in newly
        assert hidden.state == ProblemState.ACTIVE

    def test_hidden_not_activated_if_not_in_gated_problems(self):
        """A hidden problem with no active mission stays DORMANT."""
        from problems.mission import Mission, MissionTrigger
        hidden = self._make_problem("T2-004", "hidden")
        problems = {"T2-004": hidden}

        mission = Mission(
            id="M-T2-001", title="Test", description="", source_npc="Team Leader",
            trigger=MissionTrigger(type="auto"),
            problem_ids=["T2-099"],  # different problem
            hints=["hint"],
            active=True,
            problems_resolved=["T2-099"],
        )
        factory = _MockFactory({"M-T2-001": mission})
        evaluate_visibility(problems, factory)

        assert hidden.state == ProblemState.DORMANT


# ── Factory integration: all missions loaded ──────────────────────────────────

class TestFactoryMissionCount:
    def test_factory_loads_all_18_missions(self):
        from simulation.factory import Factory
        f = Factory()
        assert len(f.missions) == 18

    def test_only_m_t1_001_active_at_start(self):
        from simulation.factory import Factory
        f = Factory()
        active = [mid for mid, m in f.missions.items() if m.active]
        assert active == ["M-T1-001"]

    def test_t2_missions_dormant_at_start(self):
        from simulation.factory import Factory
        f = Factory()
        for mid, m in f.missions.items():
            if mid.startswith("M-T2-"):
                assert not m.active, f"{mid} should not be active at start"

    def test_tier2_problems_dormant_at_start(self):
        """No Tier 2 problems should be active at factory init."""
        from simulation.factory import Factory
        f = Factory()
        for pid, prob in f.problems.items():
            if pid.startswith("T2-"):
                assert prob.state == ProblemState.DORMANT, (
                    f"{pid} should be DORMANT at start, got {prob.state}"
                )

    def test_t2_mission_unlocks_after_t1_completed(self):
        """M-T2-001 should become eligible once M-T1-001 is done and day >= 5."""
        from simulation.factory import Factory
        from config.constants import DAY_DURATION
        f = Factory()
        # Complete all T1 missions so their slots are freed and T2 can activate
        for mid, m in f.missions.items():
            if mid.startswith("M-T1-"):
                m.active = False
                m.completed = True
        f.time._sim_time = 5 * DAY_DURATION  # day 6
        f._check_mission_triggers()
        assert f.missions["M-T2-001"].active
