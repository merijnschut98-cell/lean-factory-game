"""
Maturity-mismatch effectiveness (spec §7.1).

gap = cm_tier − zone_maturity

  gap ≤ 0        full effect   (on-tier or applying below maturity — fine)
  0 < gap ≤ 1    reduced       (~60%) — one tier premature, warned
  1 < gap ≤ 2    minimal       (~30%) — two tiers premature, warned
  gap > 2        no_effect     (~5%)  — three+ tiers premature, no side effect
  harmful        special case: gap > 2 AND a required prerequisite is absent
                 → side-effect problem triggered instead of no_effect
"""
from __future__ import annotations
from typing import Optional


_MULTIPLIERS = {
    "full":     1.00,
    "reduced":  0.60,
    "minimal":  0.30,
    "no_effect":0.05,
    "harmful":  0.00,   # effect is zero; a side-effect problem is triggered instead
}


def effectiveness_tier(cm_tier: int, zone_maturity: float) -> str:
    """Return the effectiveness tier label for this cm_tier / zone_maturity pair."""
    gap = cm_tier - zone_maturity
    if gap <= 0:
        return "full"
    elif gap <= 1:
        return "reduced"
    elif gap <= 2:
        return "minimal"
    return "no_effect"


def effectiveness_multiplier(cm_tier: int, zone_maturity: float) -> float:
    return _MULTIPLIERS[effectiveness_tier(cm_tier, zone_maturity)]


def mismatch_warning(cm_name: str, cm_tier: int, zone_maturity: float) -> Optional[str]:
    """
    Return a warning string when the mismatch is significant enough to warn the player.
    Returns None when no warning is needed (full effect).
    """
    tier_label = effectiveness_tier(cm_tier, zone_maturity)
    if tier_label == "full":
        return None

    pct = int(_MULTIPLIERS[tier_label] * 100)
    gap = cm_tier - zone_maturity
    return (
        f'"{cm_name}" is designed for Tier {cm_tier} maturity. '
        f"This zone is at Tier {zone_maturity:.1f}. "
        f"Applying now will produce approximately {pct}% of the potential effect "
        f"and a reduced score."
    )
