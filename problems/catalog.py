"""Load problem catalog from YAML. Phase 3 stub."""
from __future__ import annotations
from pathlib import Path
from typing import Dict, List

import yaml

from problems.problem import Problem


def load_tier(tier: int) -> List[Problem]:
    path = Path(__file__).parent.parent / "data" / f"problems_tier{tier}.yaml"
    if not path.exists():
        return []
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return [Problem.from_dict(p) for p in data.get("problems", [])]


def load_all() -> Dict[str, Problem]:
    problems = {}
    for tier in range(1, 5):
        for prob in load_tier(tier):
            problems[prob.id] = prob
    return problems
