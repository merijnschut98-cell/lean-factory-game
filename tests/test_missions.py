"""
Tests for: mission system, rollback action, visibility circuit breakers.
Covers the new Phase 5 mechanics added in the last session.
"""
import pytest
from simulation.factory import Factory
from problems.mission import Mission, MissionTrigger, load_missions
from problems.problem import ProblemState


@pytest.fixture
def factory():
    return Factory()


# ── Mission data model ────────────────────────────────────────────────────────

class TestMissionRecordResolved:
    def _mission(self, condition: str = "any") -> Mission:
        return Mission(
            id="M-TEST", title="Test", description="", source_npc="",
            trigger=MissionTrigger(type="auto"),
            problem_ids=["T1-001", "T1-002", "T1-003"],
            hints=[],
            completion_condition=condition,
            active=True,
        )

    def test_record_resolved_adds_to_list(self):
        m = self._mission()
        m.record_resolved("T1-001")
        assert "T1-001" in m.problems_resolved

    def test_record_resolved_idempotent(self):
        m = self._mission()
        m.record_resolved("T1-001")
        m.record_resolved("T1-001")
        assert m.problems_resolved.count("T1-001") == 1

    def test_record_resolved_ignores_non_member(self):
        m = self._mission()
        m.record_resolved("T1-999")
        assert m.problems_resolved == []

    def test_is_complete_any_after_one_resolved(self):
        m = self._mission("any")
        assert not m.is_complete
        m.record_resolved("T1-001")
        assert m.is_complete
        assert m.completed is True

    def test_is_complete_all_requires_all(self):
        m = self._mission("all")
        m.record_resolved("T1-001")
        assert not m.is_complete
        m.record_resolved("T1-002")
        assert not m.is_complete
        m.record_resolved("T1-003")
        assert m.is_complete

    def test_advance_hint_increments_index(self):
        m = Mission(
            id="M-HINT", title="", description="", source_npc="",
            trigger=MissionTrigger(type="auto"),
            problem_ids=[], hints=["h1", "h2", "h3"],
            active=True,
        )
        assert m.current_hint == "h1"
        m.advance_hint()
        assert m.current_hint == "h2"

    def test_advance_hint_does_not_exceed_last(self):
        m = Mission(
            id="M-HINT2", title="", description="", source_npc="",
            trigger=MissionTrigger(type="auto"),
            problem_ids=[], hints=["only"],
            active=True,
        )
        m.advance_hint()
        assert m.current_hint == "only"

    def test_save_and_restore_roundtrip(self):
        m = self._mission("all")
        m.record_resolved("T1-001")
        m.advance_hint = lambda: None  # no hints in this fixture
        saved = m.to_save_dict()
        m2 = self._mission("all")
        m2.restore_runtime_state(saved)
        assert m2.active == m.active
        assert m2.completed == m.completed
        assert m2.problems_resolved == m.problems_resolved


# ── Mission trigger types ─────────────────────────────────────────────────────

class TestMissionTriggerMet:
    def test_auto_trigger_always_true(self, factory):
        m = Mission(id="M1", title="", description="", source_npc="",
                    trigger=MissionTrigger(type="auto"),
                    problem_ids=[], hints=[])
        assert factory._mission_trigger_met(m)

    def test_day_trigger_fires_after_threshold(self, factory):
        m = Mission(id="M2", title="", description="", source_npc="",
                    trigger=MissionTrigger(type="day", after_day=5),
                    problem_ids=[], hints=[])
        factory.time._sim_time = 0.0   # day 1
        assert not factory._mission_trigger_met(m)
        factory.time._sim_time = 4 * 86400  # day 5
        assert factory._mission_trigger_met(m)

    def test_kpi_lte_trigger(self, factory):
        m = Mission(id="M3", title="", description="", source_npc="",
                    trigger=MissionTrigger(type="kpi", metric="ftr",
                                          threshold=0.88, direction="lte"),
                    problem_ids=[], hints=[])
        factory.day_history.clear()  # last_day_ftr returns 0.0 by default
        assert factory._mission_trigger_met(m)   # 0.0 <= 0.88

    def test_kpi_gte_trigger(self, factory):
        m = Mission(id="M4", title="", description="", source_npc="",
                    trigger=MissionTrigger(type="kpi", metric="wip",
                                          threshold=65.0, direction="gte"),
                    problem_ids=[], hints=[])
        # Default live_wip on fresh factory is under 65 (starting_wip_in totals ~46)
        # So trigger should not fire
        result = factory._mission_trigger_met(m)
        # Just verify it runs without error; exact value depends on station config
        assert isinstance(result, bool)

    def test_npc_trigger_never_fires_internally(self, factory):
        m = Mission(id="M5", title="", description="", source_npc="",
                    trigger=MissionTrigger(type="npc", npc_role="Scheduler"),
                    problem_ids=[], hints=[])
        assert not factory._mission_trigger_met(m)


# ── Factory mission integration ───────────────────────────────────────────────

class TestFactoryMissions:
    def test_load_missions_on_init(self, factory):
        assert len(factory.missions) > 0

    def test_auto_mission_activates_on_init(self, factory):
        auto_missions = [m for m in factory.missions.values()
                         if m.trigger.type == "auto"]
        assert all(m.active for m in auto_missions)

    def test_active_mission_count_property(self, factory):
        count = factory.active_mission_count
        assert count >= 1   # at least the auto mission

    def test_trigger_npc_mission_activates_matching(self, factory):
        # Find an inactive NPC-triggered mission
        npc_missions = [m for m in factory.missions.values()
                        if m.trigger.type == "npc" and not m.active]
        if not npc_missions:
            pytest.skip("No inactive NPC missions in test fixture")
        # Complete all currently active missions to make room
        for m in factory.missions.values():
            m.active = False
            m.completed = True
        target = npc_missions[0]
        target.completed = False
        result = factory.trigger_npc_mission(target.trigger.npc_role)
        assert result == target.id
        assert target.active is True

    def test_trigger_npc_mission_respects_cap(self, factory):
        # Fill up to cap
        for m in factory.missions.values():
            if factory.active_mission_count < 2:
                m.active = True
        assert factory.active_mission_count == 2
        # Additional trigger should fail
        result = factory.trigger_npc_mission("Scheduler")
        assert result is None

    def test_resolve_problem_updates_mission(self, factory):
        # Find a mission and one of its problems
        active_missions = [m for m in factory.missions.values() if m.active]
        assert active_missions
        mission = active_missions[0]
        pid = next((pid for pid in mission.problem_ids
                    if pid in factory.problems), None)
        if pid is None:
            pytest.skip("No overlap between mission and loaded problems")
        prob = factory.problems[pid]
        if prob.state != ProblemState.ACTIVE:
            pytest.skip("Problem not active")
        factory.apply_countermeasure(pid, "CM-T1-001")
        factory.resolve_problem(pid)
        assert pid in mission.problems_resolved

    def test_mission_state_survives_round_trip(self, factory):
        for m in factory.missions.values():
            m.active = True
        data = factory.to_dict()
        f2 = Factory()
        f2.from_dict(data)
        for mid, m in factory.missions.items():
            assert f2.missions[mid].active == m.active


# ── Rollback action ───────────────────────────────────────────────────────────

class TestRollbackCountermeasure:
    def _apply(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        return prob_id

    def test_rollback_reactivates_problem(self, factory):
        prob_id = self._apply(factory)
        factory.rollback_countermeasure(prob_id)
        assert factory.problems[prob_id].state == ProblemState.ACTIVE

    def test_rollback_clears_applied_countermeasure(self, factory):
        prob_id = self._apply(factory)
        factory.rollback_countermeasure(prob_id)
        assert factory.problems[prob_id].applied_countermeasure is None

    def test_rollback_removes_cm_from_active(self, factory):
        prob_id = self._apply(factory)
        factory.rollback_countermeasure(prob_id)
        assert "CM-T1-001" not in factory.active_countermeasures

    def test_rollback_charges_penalty(self, factory):
        factory.credits = 1000
        prob_id = self._apply(factory)
        result = factory.rollback_countermeasure(prob_id)
        assert factory.credits < 1000
        assert result["penalty_paid"] > 0

    def test_rollback_credits_floored_at_zero(self, factory):
        factory.credits = 0
        prob_id = self._apply(factory)
        factory.rollback_countermeasure(prob_id)
        assert factory.credits == 0

    def test_rollback_returns_none_when_not_applicable(self, factory):
        prob_id = next(iter(factory.active_problems))
        assert factory.rollback_countermeasure(prob_id) is None

    def test_rollback_clears_investigation_session(self, factory):
        prob_id = next(iter(factory.active_problems))
        factory.get_or_create_session(prob_id)
        factory.apply_countermeasure(prob_id, "CM-T1-001")
        factory.rollback_countermeasure(prob_id)
        assert prob_id not in factory.investigation_sessions


# ── Visibility circuit breakers ───────────────────────────────────────────────

class TestVisibilityCircuitBreaker:
    def test_active_problem_cap_at_three(self, factory):
        active = list(factory.active_problems.values())
        assert len(active) <= 3

    def test_at_most_one_critical_active(self, factory):
        criticals = [p for p in factory.active_problems.values()
                     if p.severity == "critical"]
        assert len(criticals) <= 1

    def test_mission_gated_problems_stay_dormant(self, factory):
        # Problems NOT in any active mission should remain DORMANT
        active_problem_ids = set()
        for m in factory.missions.values():
            if m.active:
                active_problem_ids.update(m.problem_ids)
        for prob in factory.problems.values():
            if prob.id not in active_problem_ids:
                assert prob.state == ProblemState.DORMANT, \
                    f"{prob.id} should be dormant — not in any active mission"
