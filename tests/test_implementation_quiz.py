"""Tests for the implementation quiz feature."""
import pytest

from problems.countermeasure import CountermeasureCatalog, QuizChoice, QuizStep


class TestImplementationQuizLoading:
    @pytest.fixture(scope="class")
    def catalog(self):
        cat = CountermeasureCatalog()
        cat.load()
        return cat

    def test_5s_has_quiz(self, catalog):
        cm = catalog.get("CM-T1-001")
        assert len(cm.implementation_quiz) == 2

    def test_standard_work_has_quiz(self, catalog):
        cm = catalog.get("CM-T1-002")
        assert len(cm.implementation_quiz) == 2

    def test_quality_gates_has_quiz(self, catalog):
        cm = catalog.get("CM-T1-004")
        assert len(cm.implementation_quiz) == 2

    def test_visual_labels_has_quiz(self, catalog):
        cm = catalog.get("CM-T1-006")
        assert len(cm.implementation_quiz) == 2

    def test_tool_locations_has_quiz(self, catalog):
        cm = catalog.get("CM-T1-007")
        assert len(cm.implementation_quiz) == 2

    def test_cm_without_quiz_has_empty_list(self, catalog):
        # All Tier 1 CMs have quizzes; use a Tier 2 CM as the "no quiz" fixture.
        cm = catalog.get("CM-T2-001")
        assert cm.implementation_quiz == []

    def test_each_question_has_three_choices(self, catalog):
        for cid in (
            "CM-T1-001", "CM-T1-002", "CM-T1-003", "CM-T1-004", "CM-T1-005",
            "CM-T1-006", "CM-T1-007", "CM-T1-008", "CM-T1-009", "CM-T1-010",
        ):
            cm = catalog.get(cid)
            for step in cm.implementation_quiz:
                assert len(step.choices) == 3, f"{cid} question has wrong choice count"

    def test_each_question_has_correct_plausible_wrong(self, catalog):
        for cid in ("CM-T1-001", "CM-T1-002", "CM-T1-004", "CM-T1-006", "CM-T1-007"):
            cm = catalog.get(cid)
            for step in cm.implementation_quiz:
                outcomes = {c.outcome for c in step.choices}
                assert outcomes == {"CORRECT", "PLAUSIBLE", "WRONG"}, (
                    f"{cid} question {step.question[:40]!r} has outcomes {outcomes}"
                )

    def test_all_choices_have_feedback(self, catalog):
        for cid in ("CM-T1-001", "CM-T1-002", "CM-T1-004", "CM-T1-006", "CM-T1-007"):
            cm = catalog.get(cid)
            for step in cm.implementation_quiz:
                for choice in step.choices:
                    assert choice.feedback, (
                        f"{cid} choice {choice.text[:40]!r} has no feedback"
                    )

    def test_correct_choices_have_teaches_tags(self, catalog):
        for cid in ("CM-T1-001", "CM-T1-002", "CM-T1-004", "CM-T1-006", "CM-T1-007"):
            cm = catalog.get(cid)
            for step in cm.implementation_quiz:
                correct = next(c for c in step.choices if c.outcome == "CORRECT")
                assert correct.teaches, (
                    f"{cid} CORRECT choice has no teaches tags"
                )


class TestQuizCimBonus:
    def test_quiz_correct_count_boosts_cim(self):
        from simulation.factory import Factory
        from problems.problem import ProblemState

        f = Factory()
        pid = "T1-001"
        prob = f.problems[pid]
        prob.state = ProblemState.ACTIVE
        session = f.get_or_create_session(pid)
        session.fork_complete = True

        # Apply 5S, then resolve with and without quiz bonus
        f.apply_countermeasure(pid, "CM-T1-001")
        baseline_cim = f.problems[pid]  # save state

        # Reset to re-run with bonus
        f.problems[pid].state = ProblemState.ACTIVE
        session.quiz_correct_count = 2
        f.apply_countermeasure(pid, "CM-T1-001")
        result = f.resolve_problem(pid)

        # Base CIM is 1 (no post-apply inspection). With 2 quiz correct, CIM = 3.
        assert result["scores"]["CIM"] == 3

    def test_quiz_correct_count_capped_at_5(self):
        from simulation.factory import Factory
        from problems.problem import ProblemState

        f = Factory()
        pid = "T1-001"
        prob = f.problems[pid]
        prob.state = ProblemState.ACTIVE
        session = f.get_or_create_session(pid)
        session.fork_complete = True
        session.quiz_correct_count = 10  # absurdly high

        f.apply_countermeasure(pid, "CM-T1-001")
        result = f.resolve_problem(pid)
        assert result["scores"]["CIM"] <= 5


class TestQuizSaveLoad:
    def test_quiz_correct_count_persists(self):
        from simulation.factory import Factory

        f = Factory()
        pid = "T1-001"
        session = f.get_or_create_session(pid)
        session.fork_complete       = True
        session.quiz_correct_count  = 2

        d = f.to_dict()
        f2 = Factory()
        f2.from_dict(d)
        assert f2.investigation_sessions[pid].quiz_correct_count == 2
