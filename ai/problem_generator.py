"""AI-generated problem creation — Phase 5 stub."""
from __future__ import annotations
from typing import Optional


class ProblemGenerator:
    def __init__(self, agent=None) -> None:
        self._agent = agent

    def generate(self, tier: int, factory_snapshot: dict) -> Optional[dict]:
        """Phase 5: call Claude to generate a new problem in YAML format."""
        raise NotImplementedError("Problem generation is a Phase 5 feature")
