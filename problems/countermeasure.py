"""
Countermeasure catalog — loads from data/countermeasures_v1.yaml.

Each Countermeasure entry is validated on load. The catalog is a read-only
reference; application state lives on Factory.active_countermeasures.
"""
from __future__ import annotations

import logging
import random
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import yaml

log = logging.getLogger(__name__)

_CATALOG_PATH = Path(__file__).parent.parent / "data" / "countermeasures_v1.yaml"

VALID_TIERS = {1, 2, 3, 4, "diagnostic"}


@dataclass
class Effectiveness:
    full: float
    reduced: float
    minimal: float
    harmful_side_effect_ref: Optional[str]  # problem ID to trigger, or None


@dataclass
class QuizChoice:
    text: str
    outcome: "ChoiceOutcome"    # imported lazily below to avoid a circular import at module load
    feedback: str      # shown after the player picks this choice
    teaches: List[str] = field(default_factory=list)


@dataclass
class QuizStep:
    question: str
    npc: str           # role name (e.g. "Team Leader")
    choices: List[QuizChoice] = field(default_factory=list)


@dataclass
class Countermeasure:
    id: str
    name: str
    tier: int | str          # 1–4 or "diagnostic"
    category: str
    description: str
    prerequisites: List[str] = field(default_factory=list)
    effectiveness: Optional[Effectiveness] = None
    decay_enabled: bool = False
    decay_days: Optional[int] = None
    applicable_to: List[str] = field(default_factory=lambda: ["all"])
    cost_credits: int = 0    # only non-zero for some diagnostic tools
    teaches: List[str] = field(default_factory=list)  # codex concept tags unlocked on apply
    implementation_quiz: List[QuizStep] = field(default_factory=list)

    @property
    def is_diagnostic(self) -> bool:
        return self.tier == "diagnostic"

    @property
    def tier_int(self) -> int:
        """Numeric tier for mismatch calculation (diagnostics = 0)."""
        return 0 if self.is_diagnostic else int(self.tier)


class CountermeasureCatalog:
    def __init__(self) -> None:
        self._cms: Dict[str, Countermeasure] = {}

    def load(self, path: Path = _CATALOG_PATH) -> None:
        """Load and validate countermeasures from YAML. Raises on bad file."""
        if not path.exists():
            raise FileNotFoundError(f"Countermeasure catalog not found: {path}")

        try:
            raw = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as exc:
            raise ValueError(f"Invalid YAML in countermeasure catalog: {exc}") from exc

        entries = raw.get("countermeasures") if isinstance(raw, dict) else None
        if not isinstance(entries, list):
            raise ValueError("Countermeasure catalog must have a top-level 'countermeasures' list")

        self._cms.clear()
        for raw_cm in entries:
            try:
                cm = _parse_cm(raw_cm)
            except (KeyError, TypeError, ValueError) as exc:
                log.warning("Skipping malformed countermeasure entry %s: %s",
                            raw_cm.get("id", "?"), exc)
                continue
            self._cms[cm.id] = cm

        log.info("Loaded %d countermeasures from %s", len(self._cms), path)

    def get(self, cm_id: str) -> Optional[Countermeasure]:
        return self._cms.get(cm_id)

    def by_tier(self, tier: int | str) -> List[Countermeasure]:
        return [cm for cm in self._cms.values() if cm.tier == tier]

    def applicable_to_station(self, station_type: str) -> List[Countermeasure]:
        return [
            cm for cm in self._cms.values()
            if "all" in cm.applicable_to or station_type in cm.applicable_to
        ]

    def all_playable(self) -> List[Countermeasure]:
        """All non-diagnostic CMs, sorted by tier then name."""
        return sorted(
            (cm for cm in self._cms.values() if not cm.is_diagnostic),
            key=lambda c: (c.tier_int, c.name),
        )

    def diagnostics(self) -> List[Countermeasure]:
        return [cm for cm in self._cms.values() if cm.is_diagnostic]

    def __len__(self) -> int:
        return len(self._cms)


# Codex concept tags unlocked when a CM is applied for the first time.
# Keyed by CM ID. YAML teaches: field overrides if present.
_CM_TEACHES_MAP: Dict[str, List[str]] = {
    # Tier 1
    "CM-T1-001": ["5S", "5S_sort", "workplace_organization", "waste_muda"],
    "CM-T1-002": ["standard_work", "operator_variation", "documentation"],
    "CM-T1-003": ["safety", "near_miss_reporting", "standard_work"],
    "CM-T1-004": ["quality_gate", "inspection", "FTR"],
    "CM-T1-005": ["workplace_organization", "5S", "waste_muda"],
    "CM-T1-006": ["visual_management", "workplace_organization"],
    "CM-T1-007": ["workplace_organization", "5S", "waste_muda"],
    "CM-T1-008": ["5S", "workplace_organization"],
    "CM-T1-009": ["documentation", "version_control", "standard_work"],
    "CM-T1-010": ["skill_matrix", "cross_training", "knowledge_management"],
    # Tier 2
    "CM-T2-001": ["management_system", "leader_standard_work", "visual_management"],
    "CM-T2-002": ["visual_management", "performance_reporting", "management_system"],
    "CM-T2-003": ["kaizen", "standard_work"],
    "CM-T2-004": ["kaizen", "waste_muda", "standard_work"],
    "CM-T2-005": ["kaizen", "decision_authority"],
    "CM-T2-006": ["kaizen", "waste_muda", "gemba"],
    "CM-T2-007": ["variation", "waste_muda", "kaizen"],
    "CM-T2-008": ["DMAIC", "standard_work", "documentation"],
    "CM-T2-009": ["gemba", "waste_muda", "visual_management"],
    "CM-T2-010": ["safety", "near_miss_reporting", "decision_authority"],
    "CM-T2-011": ["andon", "jidoka", "visual_management"],
    "CM-T2-012": ["leader_standard_work", "management_system"],
    "CM-T2-013": ["decision_authority", "management_system"],
    "CM-T2-014": ["cross_training", "skill_matrix", "knowledge_management"],
    "CM-T2-015": ["leader_standard_work", "management_system", "standard_work"],
    "CM-T2-016": ["management_system", "leader_standard_work"],
    # Tier 3
    "CM-T3-001": ["VSM", "flow", "waste_muda", "information_flow"],
    "CM-T3-002": ["VSM", "flow", "kaizen"],
    "CM-T3-003": ["kanban", "replenishment", "push_vs_pull", "WIP"],
    "CM-T3-004": ["kanban", "replenishment", "push_vs_pull"],
    "CM-T3-005": ["FIFO", "flow", "inventory_management"],
    "CM-T3-006": ["line_balancing", "flow", "takt_time", "waste_mura"],
    "CM-T3-007": ["WIP", "flow", "standard_work"],
    "CM-T3-008": ["SMED", "flow", "waste_muda"],
    "CM-T3-009": ["heijunka", "leveled_production", "flow", "waste_mura"],
    "CM-T3-010": ["flow", "replenishment", "waste_muda"],
    "CM-T3-011": ["flow", "line_balancing", "waste_muda"],
    "CM-T3-012": ["poka_yoke", "quality_gate", "jidoka"],
    "CM-T3-013": ["jidoka", "quality_gate", "poka_yoke", "andon"],
    "CM-T3-014": ["takt_time", "flow", "line_balancing"],
    "CM-T3-015": ["flow", "line_balancing", "waste_mura"],
    "CM-T3-016": ["waste_muda", "waste_mura", "waste_muri", "kaizen"],
    "CM-T3-017": ["data_capture", "waste_muda"],
    "CM-T3-018": ["heijunka", "flow", "leveled_production"],
    "CM-T3-019": ["gemba", "waste_muda", "flow"],
    "CM-T3-020": ["heijunka", "leveled_production", "waste_mura"],
    "CM-T3-021": ["takt_time", "flow", "management_system"],
    "CM-T3-022": ["heijunka", "leveled_production", "flow"],
    "CM-T3-023": ["digitalization", "data_capture", "information_flow"],
    "CM-T3-024": ["digitalization", "standard_work"],
    # Tier 4
    "CM-T4-001": ["SPC", "variation", "quality_gate", "measurement_system"],
    "CM-T4-002": ["SPC", "variation", "quality_gate"],
    "CM-T4-003": ["DMAIC", "variation", "standard_work"],
    "CM-T4-004": ["MSA", "measurement_system", "variation"],
    "CM-T4-005": ["variation", "DMAIC"],
    "CM-T4-006": ["quality_gate", "poka_yoke", "safety"],
    "CM-T4-007": ["standard_work", "quality_gate", "documentation"],
    "CM-T4-008": ["DMAIC", "waste_muda"],
    "CM-T4-009": ["variation", "DMAIC", "measurement_system"],
    "CM-T4-010": ["variation", "data_capture", "measurement_system"],
    "CM-T4-011": ["variation", "DMAIC"],
    "CM-T4-012": ["quality_gate", "standard_work"],
    "CM-T4-013": ["TPM", "OEE"],
    "CM-T4-014": ["TPM", "OEE", "autonomous_maintenance"],
    "CM-T4-015": ["OEE", "TPM", "waste_muda"],
    "CM-T4-016": ["variation", "DMAIC"],
    "CM-T4-017": ["digitalization", "data_capture", "performance_reporting", "information_flow"],
    "CM-T4-018": ["DMAIC", "kaizen"],
    # Diagnostic
    "CM-DX-001": ["waste_muda", "kaizen", "gemba"],
    "CM-DX-002": ["variation", "waste_muda"],
    "CM-DX-003": ["standard_work", "takt_time", "gemba"],
    "CM-DX-004": ["standard_work", "waste_muda", "gemba"],
    "CM-DX-005": ["waste_muda", "kaizen"],
    "CM-DX-006": ["DMAIC", "standard_work"],
    "CM-DX-007": ["gemba", "waste_muda", "visual_management"],
    "CM-DX-008": ["gemba", "waste_muda", "flow"],
    "CM-DX-009": ["VSM", "flow", "waste_muda"],
    "CM-DX-010": ["kaizen", "DMAIC"],
    "CM-DX-011": ["DMAIC", "management_system"],
}


def _parse_cm(raw: dict) -> Countermeasure:
    cm_id = str(raw["id"])
    tier  = raw["tier"]
    if tier not in VALID_TIERS:
        try:
            tier = int(tier)
        except (ValueError, TypeError):
            raise ValueError(f"Invalid tier {tier!r} for CM {cm_id}")

    eff_raw = raw.get("effectiveness")
    effectiveness = None
    if isinstance(eff_raw, dict) and "multipliers" in eff_raw:
        mults = eff_raw["multipliers"]
        harmful_ref = None
        if isinstance(eff_raw.get("harmful"), dict):
            harmful_ref = eff_raw["harmful"].get("side_effect_ref")
        effectiveness = Effectiveness(
            full=float(mults.get("full", 1.0)),
            reduced=float(mults.get("reduced", 0.5)),
            minimal=float(mults.get("minimal", 0.2)),
            harmful_side_effect_ref=harmful_ref,
        )

    decay = raw.get("decay", {}) or {}
    mat_req = raw.get("maturity_requirement")
    prereqs = mat_req.get("prerequisites") or [] if isinstance(mat_req, dict) else []

    teaches = list(raw["teaches"]) if raw.get("teaches") else _CM_TEACHES_MAP.get(cm_id, [])
    quiz = _parse_quiz(raw.get("implementation_quiz"))

    return Countermeasure(
        id=cm_id,
        name=str(raw.get("name", "")),
        tier=tier,
        category=str(raw.get("category", "")),
        description=str(raw.get("description", "")).strip(),
        prerequisites=[str(p) for p in prereqs],
        effectiveness=effectiveness,
        decay_enabled=bool(decay.get("enabled", False)),
        decay_days=int(decay["days"]) if decay.get("days") else None,
        applicable_to=list(raw.get("applicable_to", ["all"])),
        cost_credits=int(raw.get("cost_credits", 0)),
        teaches=teaches,
        implementation_quiz=quiz,
    )


def _parse_quiz(raw) -> List[QuizStep]:
    from problems.dialogue import ChoiceOutcome
    if not isinstance(raw, list):
        return []

    def _to_outcome(v) -> ChoiceOutcome:
        try:
            return ChoiceOutcome(str(v).upper())
        except ValueError:
            return ChoiceOutcome.WRONG

    steps: List[QuizStep] = []
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        choices = [
            QuizChoice(
                text=str(c.get("text", "")),
                outcome=_to_outcome(c.get("outcome", "WRONG")),
                feedback=str(c.get("feedback", "")).strip(),
                teaches=list(c.get("teaches") or []),
            )
            for c in (entry.get("choices") or [])
            if isinstance(c, dict)
        ]
        random.shuffle(choices)
        steps.append(QuizStep(
            question=str(entry.get("question", "")).strip(),
            npc=str(entry.get("npc", "Team Leader")),
            choices=choices,
        ))
    return steps
