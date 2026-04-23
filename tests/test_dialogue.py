"""
Tests for the dialogue choice engine (Phase 5 — learning mechanics).
Covers: YAML parsing, choice outcome tagging, InvestigationSession tracking,
Learning Rally detection, and concept collection.
"""
import pytest
from problems.dialogue import (
    ChoiceOutcome, DialogueChoice, InvestigationFork,
    ProblemDialogue, InvestigationSession, parse_dialogue,
)
from problems.catalog import load_tier


# ── Parse tests ───────────────────────────────────────────────────────────────

class TestParseDialogue:
    def test_returns_none_for_empty_input(self):
        assert parse_dialogue({}) is None
        assert parse_dialogue(None) is None

    def test_parses_investigation_fork(self):
        raw = {
            "investigation": {
                "npc": "Team Leader",
                "prompt": "What should we check first?",
                "choices": [
                    {"text": "Count the shelf", "outcome": "CORRECT",
                     "evidence": "23 coils.", "hint": "Good.", "teaches": ["5S"]},
                    {"text": "Do nothing", "outcome": "WRONG",
                     "evidence": None, "hint": "Not ideal.", "teaches": []},
                ],
            }
        }
        result = parse_dialogue(raw)
        assert result is not None
        assert result.investigation is not None
        assert result.investigation.npc == "Team Leader"
        assert len(result.investigation.choices) == 2
        assert result.investigation.choices[0].outcome == ChoiceOutcome.CORRECT
        assert result.investigation.choices[1].outcome == ChoiceOutcome.WRONG

    def test_parses_five_whys(self):
        raw = {
            "five_whys": [
                {
                    "why": "Why is quality low?",
                    "choices": [
                        {"text": "No standard", "outcome": "CORRECT",
                         "evidence": None, "hint": "Yes.", "teaches": ["standard_work"]},
                    ],
                }
            ]
        }
        result = parse_dialogue(raw)
        assert result is not None
        assert len(result.five_whys) == 1
        assert result.five_whys[0].why == "Why is quality low?"
        assert result.five_whys[0].step == 0

    def test_invalid_outcome_defaults_to_wrong(self):
        raw = {
            "investigation": {
                "npc": "X", "prompt": "Y",
                "choices": [
                    {"text": "A", "outcome": "INVALID_VALUE",
                     "evidence": None, "hint": ".", "teaches": []},
                ],
            }
        }
        result = parse_dialogue(raw)
        assert result.investigation.choices[0].outcome == ChoiceOutcome.WRONG

    def test_score_feed_parsed(self):
        raw = {
            "investigation": {
                "npc": "X", "prompt": "Y",
                "choices": [
                    {"text": "A", "outcome": "CORRECT", "evidence": "E",
                     "hint": "H", "teaches": [], "score_feed": "RCA"},
                ],
            }
        }
        result = parse_dialogue(raw)
        assert result.investigation.choices[0].score_feed == "RCA"


# ── YAML integration tests ────────────────────────────────────────────────────

class TestTier1DialogueParsed:
    @pytest.fixture(scope="class")
    def tier1(self):
        return load_tier(1)

    def test_all_25_problems_loaded(self, tier1):
        assert len(tier1) == 25

    def test_all_problems_have_teaches_tags(self, tier1):
        missing = [p.id for p in tier1 if not p.teaches]
        assert missing == [], f"Problems missing teaches tags: {missing}"

    def test_first_5_problems_have_dialogue(self, tier1):
        with_dialogue = [p for p in tier1 if p.dialogue is not None]
        ids = [p.id for p in with_dialogue]
        for expected in ("T1-001", "T1-002", "T1-003", "T1-004", "T1-005"):
            assert expected in ids, f"{expected} should have a dialogue fork"

    def test_dialogue_choices_have_at_least_correct_and_wrong(self, tier1):
        for prob in tier1:
            if prob.dialogue and prob.dialogue.investigation:
                outcomes = {c.outcome for c in prob.dialogue.investigation.choices}
                assert ChoiceOutcome.CORRECT in outcomes, \
                    f"{prob.id} investigation fork has no CORRECT choice"
                assert ChoiceOutcome.WRONG in outcomes, \
                    f"{prob.id} investigation fork has no WRONG choice"

    def test_correct_choices_have_evidence(self, tier1):
        for prob in tier1:
            if prob.dialogue and prob.dialogue.investigation:
                for c in prob.dialogue.investigation.choices:
                    if c.outcome == ChoiceOutcome.CORRECT:
                        assert c.evidence, \
                            f"{prob.id}: CORRECT choice '{c.text}' has no evidence"

    def test_correct_choices_have_score_feed(self, tier1):
        for prob in tier1:
            if prob.dialogue and prob.dialogue.investigation:
                for c in prob.dialogue.investigation.choices:
                    if c.outcome == ChoiceOutcome.CORRECT:
                        assert c.score_feed, \
                            f"{prob.id}: CORRECT choice '{c.text}' has no score_feed"


# ── InvestigationSession tests ────────────────────────────────────────────────

class TestInvestigationSession:
    def _make_choice(self, outcome: ChoiceOutcome, teaches=None) -> DialogueChoice:
        return DialogueChoice(
            text="test", outcome=outcome, evidence=None,
            hint=".", teaches=teaches or [],
        )

    def test_correct_count(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_choice(self._make_choice(ChoiceOutcome.WRONG))
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT))
        assert s.correct_count == 1
        assert s.wrong_count == 1

    def test_fork_complete_after_correct(self):
        s = InvestigationSession(problem_id="T1-001")
        assert not s.fork_complete
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT))
        assert s.fork_complete

    def test_fork_not_complete_after_wrong(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_choice(self._make_choice(ChoiceOutcome.WRONG))
        assert not s.fork_complete

    def test_learning_rally_detected(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_choice(self._make_choice(ChoiceOutcome.WRONG))
        assert not s.earned_rally_bonus
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT))
        assert s.earned_rally_bonus

    def test_no_rally_on_first_try_correct(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT))
        assert not s.earned_rally_bonus

    def test_concepts_encountered_deduplicated(self):
        s = InvestigationSession(problem_id="T1-001")
        s.record_choice(self._make_choice(ChoiceOutcome.WRONG, teaches=["5S", "WIP"]))
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT, teaches=["5S", "gemba"]))
        concepts = s.concepts_encountered()
        assert concepts.count("5S") == 1
        assert "WIP" in concepts
        assert "gemba" in concepts

    def test_round_trip_serialisation(self):
        s = InvestigationSession(problem_id="T1-002")
        s.record_choice(self._make_choice(ChoiceOutcome.WRONG, teaches=["5S"]))
        s.record_choice(self._make_choice(ChoiceOutcome.CORRECT, teaches=["gemba"]))

        restored = InvestigationSession.from_dict(s.to_dict())
        assert restored.problem_id == "T1-002"
        assert restored.fork_complete is True
        assert restored.wrong_count == 1
        assert restored.earned_rally_bonus is True
