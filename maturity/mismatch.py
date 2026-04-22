"""Maturity-mismatch effectiveness calculator — Phase 4 stub."""
from __future__ import annotations


def effectiveness(cm_tier: int, zone_maturity: float) -> float:
    """
    Returns effectiveness multiplier (0–1) based on countermeasure tier
    vs zone maturity.
    Phase 4: implement full effectiveness table per spec §7.1.
    """
    gap = cm_tier - zone_maturity
    if gap <= 0:
        return 1.0   # on-tier or below
    elif gap <= 1:
        return 0.65  # one tier above
    else:
        return 0.30  # two+ tiers above (premature)


def mismatch_warning(cm_name: str, cm_tier: int, zone_maturity: float) -> str | None:
    """Return a warning string if a significant mismatch is detected, else None."""
    gap = cm_tier - zone_maturity
    if gap >= 2:
        pct = int(effectiveness(cm_tier, zone_maturity) * 100)
        return (
            f"This countermeasure is designed for Tier {cm_tier} maturity. "
            f"The target zone is at Tier {zone_maturity:.0f}. "
            f"Proceeding will produce approximately {pct}% of potential effect "
            f"and a reduced score."
        )
    return None
