"""
Dialogue choice engine — Phase 5 learning mechanic.

Drives the NPC-guided decision forks described in the Learning Pillars.
All data is loaded from YAML (problems_tier*.yaml, field: investigation / five_whys).
No LLM involved here; forks are deterministic authored content.
"""
from __future__ import annotations

import random
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
    choices = [_parse_choice(c) for c in raw.get("choices", [])]
    random.shuffle(choices)
    return InvestigationFork(
        npc=str(raw.get("npc", "")),
        prompt=str(raw.get("prompt", "")),
        choices=choices,
    )


def _parse_five_whys_step(index: int, raw: dict) -> FiveWhysStep:
    choices = [_parse_choice(c) for c in raw.get("choices", [])]
    random.shuffle(choices)
    return FiveWhysStep(
        why=str(raw.get("why", "")),
        choices=choices,
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


# ── Verification fork builder ─────────────────────────────────────────────────

_VERIFICATION_TEMPLATES: dict = {
    "workplace_organization": (
        "Tools are where they should be — operators stop searching. "
        "Cycle time variance has dropped noticeably.",
        "The area looks cleaner, but cycle time hasn't changed.",
        "The station looks the same as before the countermeasure.",
        ["waste_muda", "standard_work"],
        "visual_management",
    ),
    "process_standardization": (
        "Operators are following the same sequence now. "
        "The variation between shifts has dropped — output is more predictable.",
        "Output looks more consistent, but I haven't verified whether operators are following the standard.",
        "There's no visible change in how the station is running.",
        ["standard_work", "operator_variation"],
        "operator_variation",
    ),
    "quality": (
        "The defect pattern is changing. Fewer units entering rework, "
        "and the ones that do show different failure modes from before.",
        "OEE looks marginally higher, but I haven't confirmed whether FTR is actually moving.",
        "Rework pile looks the same as before.",
        ["quality_gate", "FTR", "rework_waste"],
        "inspection",
    ),
    "safety": (
        "Near-miss reports have increased — not because more incidents are happening, "
        "but because people are now reporting. That's the culture shift.",
        "Operators seem more careful, but I haven't seen any reports come in.",
        "Still the same working conditions as before.",
        ["safety", "near_miss_reporting"],
        "near_miss_reporting",
    ),
    "visual_management": (
        "Status is now visible at a glance. Operators are reacting to abnormal "
        "conditions before they escalate into stoppages.",
        "The boards are up, but it's not clear operators are actively reading them.",
        "Information flow looks unchanged from before.",
        ["visual_management", "andon"],
        "information_flow",
    ),
    "information": (
        "Data is consistent across sources now. The gap between system "
        "records and floor reality has narrowed.",
        "The new documentation is in place, but I haven't verified whether people are using it.",
        "Still seeing discrepancies between what the system shows and what's on the floor.",
        ["documentation", "data_integrity", "information_flow"],
        "data_capture",
    ),
    "management_system": (
        "Issues are surfacing faster and response times have dropped. "
        "The floor team is more proactive than reactive.",
        "Meetings are happening regularly, but the response to problems seems the same.",
        "Problem resolution still takes the same time as before.",
        ["management_system", "leader_standard_work"],
        "decision_authority",
    ),
    "people": (
        "Output is more consistent across operators — the variance between "
        "individuals has measurably shrunk.",
        "New training is underway, but the knowledge gap is still clearly visible.",
        "Still the same dependency on the most experienced operator.",
        ["skill_matrix", "cross_training", "tacit_knowledge"],
        "knowledge_management",
    ),
    "flow": (
        "WIP between stations has dropped. Material is moving more steadily "
        "without the flood-and-drought pattern.",
        "The schedule looks smoother, but WIP levels are about the same.",
        "The flooding and starvation pattern is unchanged.",
        ["flow", "WIP", "waste_mura"],
        "heijunka",
    ),
    "flow_analysis": (
        "The analysis has given the team a shared map of where value is and "
        "isn't added. Improvement actions are now more targeted.",
        "The map is useful, but we haven't started acting on the findings yet.",
        "Back to normal — the analysis hasn't changed how we operate.",
        ["VSM", "flow", "waste_muda"],
        "gemba",
    ),
    "problem_solving": (
        "The team now has a shared understanding of the root cause. "
        "Actions are targeted at the right place in the process.",
        "The analysis was clear, but implementation of the fix is still uncertain.",
        "Same problems recurring — the structured approach didn't surface anything new.",
        ["kaizen", "waste_muda"],
        "standard_work",
    ),
    "improvement_events": (
        "The focused improvement produced a measurable step change. "
        "The team owns the result because they built it.",
        "The event produced ideas, but only a few have been implemented.",
        "Activity was high during the event, but nothing has lasted.",
        ["kaizen", "standard_work"],
        "management_system",
    ),
    "maintenance": (
        "Minor stoppages have decreased. Operators are catching issues "
        "earlier — before they become unplanned stops.",
        "OEE looks better, but it's hard to tell if that's the countermeasure or just variance.",
        "Still the same pattern of unplanned breakdowns.",
        ["TPM", "OEE", "autonomous_maintenance"],
        "TPM",
    ),
    "coaching": (
        "The consultation clarified the direction. The team is now investigating "
        "with a clearer hypothesis instead of reacting to symptoms.",
        "The session was useful for framing, but the team hasn't changed approach yet.",
        "Back to normal — no visible change from before the consultation.",
        ["kaizen", "DMAIC"],
        "gemba",
    ),
}

_VERIFICATION_WRONG_TEACHES = ["gemba", "waste_muda"]


def build_verification_fork(
    npc: str,
    cm_category: str,
    cm_name: str,
    days_active: int,
) -> InvestigationFork:
    """Generate a PDCA-Check verification fork for any CM category."""
    template = _VERIFICATION_TEMPLATES.get(cm_category, _VERIFICATION_TEMPLATES["problem_solving"])
    correct_txt, plausible_txt, wrong_txt, correct_teaches, plausible_teach = template

    prompt = (
        f"{cm_name} has been in place for {days_active} day{'s' if days_active != 1 else ''}. "
        "Walk the station. What do you observe?"
    )

    choices = [
        DialogueChoice(
            text=correct_txt,
            outcome=ChoiceOutcome.CORRECT,
            evidence=None,
            hint=(
                "Correct. Observing the specific effect confirms the countermeasure "
                "is working and completes the Check phase of PDCA. "
                "Now decide: standardize it, or adjust."
            ),
            teaches=correct_teaches,
            score_feed="CIM",
        ),
        DialogueChoice(
            text=plausible_txt,
            outcome=ChoiceOutcome.PLAUSIBLE,
            evidence=None,
            hint=(
                "Close — but vague observation isn't enough. "
                "Check the specific metric the countermeasure targeted. "
                "What was the expected improvement? Is it there?"
            ),
            teaches=[plausible_teach],
            score_feed=None,
        ),
        DialogueChoice(
            text=wrong_txt,
            outcome=ChoiceOutcome.WRONG,
            evidence=None,
            hint=(
                "Go back and look again — carefully. "
                "What metric was this countermeasure supposed to move? "
                "Compare before and after. Gemba first."
            ),
            teaches=_VERIFICATION_WRONG_TEACHES,
            score_feed=None,
        ),
    ]
    random.shuffle(choices)
    return InvestigationFork(npc=npc, prompt=prompt, choices=choices)


# ── Runtime state ─────────────────────────────────────────────────────────────

@dataclass
class InvestigationSession:
    """
    Tracks one player's investigation of a specific problem.
    Created when player opens an investigation fork; discarded on resolve.
    """
    problem_id:              str
    choices_made:            List[Dict] = field(default_factory=list)
    fork_complete:           bool = False
    five_whys_step:          int  = 0
    five_whys_complete:      bool = False
    five_whys_choices:       List[dict] = field(default_factory=list)
    verification_complete:   bool = False
    verification_choices:    List[dict] = field(default_factory=list)
    standardized:            bool = False
    wrong_cm_count:          int  = 0
    quiz_correct_count:      int  = 0

    def record_choice(self, choice: DialogueChoice) -> None:
        self.choices_made.append({
            "text":    choice.text,
            "outcome": choice.outcome.value,
            "teaches": choice.teaches,
        })
        if choice.outcome == ChoiceOutcome.CORRECT:
            self.fork_complete = True

    def record_verification_choice(self, choice: DialogueChoice) -> None:
        self.verification_choices.append({
            "text":       choice.text,
            "outcome":    choice.outcome.value,
            "teaches":    choice.teaches,
            "score_feed": choice.score_feed,
        })
        self.verification_complete = True

    def record_five_whys_choice(self, choice: DialogueChoice, total_steps: int) -> None:
        self.five_whys_choices.append({
            "step":    self.five_whys_step,
            "text":    choice.text,
            "outcome": choice.outcome.value,
            "teaches": choice.teaches,
        })
        if choice.outcome == ChoiceOutcome.CORRECT:
            self.five_whys_step += 1
            if self.five_whys_step >= total_steps:
                self.five_whys_complete = True

    @property
    def correct_count(self) -> int:
        return sum(1 for c in self.choices_made if c["outcome"] == ChoiceOutcome.CORRECT.value)

    @property
    def wrong_count(self) -> int:
        return sum(1 for c in self.choices_made if c["outcome"] == ChoiceOutcome.WRONG.value)

    @property
    def verification_correct(self) -> bool:
        """True if the last verification choice was CORRECT."""
        return bool(
            self.verification_choices
            and self.verification_choices[-1]["outcome"] == ChoiceOutcome.CORRECT.value
        )

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
            "problem_id":            self.problem_id,
            "choices_made":          self.choices_made,
            "fork_complete":         self.fork_complete,
            "five_whys_step":        self.five_whys_step,
            "five_whys_complete":    self.five_whys_complete,
            "five_whys_choices":     self.five_whys_choices,
            "verification_complete": self.verification_complete,
            "verification_choices":  self.verification_choices,
            "standardized":          self.standardized,
            "wrong_cm_count":        self.wrong_cm_count,
            "quiz_correct_count":    self.quiz_correct_count,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "InvestigationSession":
        s = cls(problem_id=d["problem_id"])
        s.choices_made           = d.get("choices_made", [])
        s.fork_complete          = d.get("fork_complete", False)
        s.five_whys_step         = d.get("five_whys_step", 0)
        s.five_whys_complete     = d.get("five_whys_complete", False)
        s.five_whys_choices      = d.get("five_whys_choices", [])
        s.verification_complete  = d.get("verification_complete", False)
        s.verification_choices   = d.get("verification_choices", [])
        s.standardized           = d.get("standardized", False)
        s.wrong_cm_count         = d.get("wrong_cm_count", 0)
        s.quiz_correct_count     = d.get("quiz_correct_count", 0)
        return s
