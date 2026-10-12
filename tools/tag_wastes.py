"""One-off migration: give every problem a primary `waste:` — one of the 8 wastes
(TIMWOODS). Hand-assigned: the waste the player would *see* at the gemba.
Inserted right after each problem's `category:` line so comments survive.
Idempotent. Run: python tools/tag_wastes.py
"""
from __future__ import annotations

import re
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data"

WASTES = {"transport", "inventory", "motion", "waiting", "overproduction", "overprocessing", "defects", "skills"}

ASSIGN = {
    # Tier 1
    "T1-001": "inventory", "T1-002": "motion", "T1-003": "defects", "T1-004": "waiting",
    "T1-005": "skills", "T1-006": "inventory", "T1-007": "defects", "T1-008": "defects",
    "T1-009": "transport", "T1-010": "defects", "T1-011": "inventory", "T1-012": "skills",
    "T1-013": "inventory", "T1-014": "defects", "T1-015": "defects", "T1-016": "waiting",
    "T1-017": "waiting", "T1-018": "motion", "T1-019": "overprocessing", "T1-020": "inventory",
    "T1-021": "waiting", "T1-022": "overprocessing", "T1-023": "overprocessing", "T1-024": "defects",
    "T1-025": "overprocessing",
    # Tier 2
    "T2-001": "waiting", "T2-002": "waiting", "T2-003": "skills", "T2-004": "waiting",
    "T2-005": "skills", "T2-006": "overprocessing", "T2-007": "defects", "T2-008": "defects",
    "T2-009": "skills", "T2-010": "defects", "T2-011": "waiting", "T2-012": "skills",
    "T2-013": "overproduction", "T2-014": "defects", "T2-015": "defects",
    # Tier 3
    "T3-001": "overproduction", "T3-002": "waiting", "T3-003": "overproduction", "T3-004": "motion",
    "T3-005": "waiting", "T3-006": "waiting", "T3-007": "defects", "T3-008": "inventory",
    "T3-009": "overprocessing", "T3-010": "waiting", "T3-011": "waiting", "T3-012": "overproduction",
    "T3-013": "transport", "T3-014": "overprocessing", "T3-015": "inventory",
    # Tier 4
    "T4-001": "overprocessing", "T4-002": "defects", "T4-003": "defects", "T4-004": "defects",
    "T4-005": "defects", "T4-006": "overprocessing", "T4-007": "waiting", "T4-008": "defects",
    "T4-009": "defects", "T4-010": "defects", "T4-011": "waiting", "T4-012": "defects",
}
assert set(ASSIGN.values()) <= WASTES


def main() -> None:
    seen = set()
    for t in range(1, 5):
        path = DATA / f"problems_tier{t}.yaml"
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        out, current = [], None
        for i, line in enumerate(lines):
            m = re.match(r"^\s*- id:\s*(T\d-\d{3})\s*$", line)
            if m:
                current = m.group(1)
            out.append(line)
            c = re.match(r"^(\s*)category:", line)
            if c and current in ASSIGN:
                nxt = lines[i + 1] if i + 1 < len(lines) else ""
                if not re.match(r"^\s*waste:", nxt):
                    out.append(f"{c.group(1)}waste: {ASSIGN[current]}\n")
                seen.add(current)
                current = None
        path.write_text("".join(out), encoding="utf-8")
    missing = set(ASSIGN) - seen
    if missing:
        raise SystemExit(f"problems not found: {sorted(missing)}")
    print(f"tagged {len(seen)} problems")


if __name__ == "__main__":
    main()
