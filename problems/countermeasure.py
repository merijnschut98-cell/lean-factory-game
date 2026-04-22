"""
Countermeasure catalog — loads from data/countermeasures_v1.yaml.

Each Countermeasure entry is validated on load. The catalog is a read-only
reference; application state lives on Factory.active_countermeasures.
"""
from __future__ import annotations

import logging
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
    )
