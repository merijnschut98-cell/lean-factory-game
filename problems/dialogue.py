"""
Dialogue choice engine — Phase 5 learning mechanic.

Drives the NPC-guided decision forks described in the Learning Pillars.
All data is loaded from YAML (problems_tier*.yaml, field: investigation / five_whys).
No LLM involved here; forks are deterministic authored content.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional


class ChoiceOutcome(str, Enum):
    CORRECT  = "CORRECT"
    PLAUSIBLE = "PLAUSIBLE"
    WRONG    = "WRONG"


@dataclass
class DialogueChoice:
    text:      str
    outcome:   ChoiceOutcome
    evidence:  Optional[str]   # text revealed to player after choosing
    hint:      str             # lean explanation shown after choosing (correct or wrong)
    teaches:   List[str] = field(default_factory=list)
    score_feed: Optional[str] = None  # metric key boosted on CORRECT (e.g. "RCA")


@dataclass
class InvestigationFork:
    """Single-level NPC fork: 'what should we check next?'"""
    npc:     str
    prompt:  str
    choices: List[DialogueChoice] = field(default_factory=list)


@dataclass
class FiveWhysStep:
    why:     str
    choices: List[DialogueChoice] = field(default_factory=list)
    step:    int = 0


@dataclass
class ProblemDialogue:
    investigation: Optional[InvestigationFork] = None
    five_whys:     List[FiveWhysStep] = field(default_factory=list)


# ── YAML parsing ──────────────────────────────────────────────────────────────

def parse_dialogue(raw: dict) -> Optional[ProblemDialogue]:
    """Parse the optional 'dialogue' block from a problem YAML entry."""
    if not raw:
        return None

    inv_raw  = raw.get("investigation")
    fw_raw   = raw.get("five_whys", [])

    investigation = _parse_investigation(inv_raw) if inv_raw else None
    five_whys     = [_parse_five_whys_step(i, s) for i, s in enumerate(fw_raw)]

    if investigation is None and not five_whys:
        return None
    return ProblemDialogue(investigation=investigation, five_whys=five_whys)


def _parse_investigation(raw: dict) -> Optional[InvestigationFork]:
    if not isinstance(raw, dict):
        return None
    return InvestigationFork(
        npc=str(raw.get("npc", "")),
        prompt=str(raw.get("prompt", "")),
        choices=[_parse_choice(c) for c in raw.get("choices", [])],
    )


def _parse_five_whys_step(index: int, raw: dict) -> FiveWhysStep:
    return FiveWhysStep(
        why=str(raw.get("why", "")),
        choices=[_parse_choice(c) for c in raw.get("choices", [])],
        step=index,
    )


def _parse_choice(raw: dict) -> DialogueChoice:
    outcome_str = str(raw.get("outcome", "WRONG")).upper()
    outcome = ChoiceOutcome(outcome_str) if outcome_str in ChoiceOutcome._value2member_map_ else ChoiceOutcome.WRONG
    return DialogueChoice(
        text=str(raw.get("text", "")),
        outcome=outcome,
        evidence=raw.get("evidence") or None,
        hint=str(raw.get("hint", "")),
        teaches=list(raw.get("teaches") or []),
        score_feed=raw.get("score_feed") or None,
    )


# ── Runtime state ─────────────────────────────────────────────────────────────

@dataclass
class InvestigationSession:
    """
    Tracks one player's investigation of a specific problem.
    Created when player opens an investigation fork; discarded on resolve.
    """
    problem_id:     str
    choices_made:   List[Dict] = field(default_factory=list)  # {text, outcome, teaches}
    fork_complete:  bool = False

    def record_choice(self, choice: DialogueChoice) -> None:
        self.choices_made.append({
            "text":    choice.text,
            "outcome": choice.outcome.value,
            "teaches": choice.teaches,
        })
        if choice.outcome == ChoiceOutcome.CORRECT:
            self.fork_complete = True

    @property
    def correct_count(self) -> int:
        return sum(1 for c in self.choices_made if c["outcome"] == ChoiceOutcome.CORRECT.value)

    @property
    def wrong_count(self) -> int:
        return sum(1 for c in self.choices_made if c["outcome"] == ChoiceOutcome.WRONG.value)

    @property
    def earned_rally_bonus(self) -> bool:
        """True if player got a correct answer after at least one wrong — the Learning Rally."""
        had_wrong = False
        for c in self.choices_made:
            if c["outcome"] == ChoiceOutcome.WRONG.value:
                had_wrong = True
            elif c["outcome"] == ChoiceOutcome.CORRECT.value and had_wrong:
                return True
        return False

    def concepts_encountered(self) -> List[str]:
        seen: List[str] = []
        for c in self.choices_made:
            for tag in c.get("teaches", []):
                if tag not in seen:
                    seen.append(tag)
        return seen

    def to_dict(self) -> dict:
        return {
            "problem_id":    self.problem_id,
            "choices_made":  self.choices_made,
            "fork_complete": self.fork_complete,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "InvestigationSession":
        s = cls(problem_id=d["problem_id"])
        s.choices_made  = d.get("choices_made", [])
        s.fork_complete = d.get("fork_complete", False)
        return s
