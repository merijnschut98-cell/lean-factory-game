"""Coach dialogue controller — Phase 5 stub."""
from __future__ import annotations
from typing import Optional


class Coach:
    def __init__(self, agent=None) -> None:
        self._agent     = agent
        self._active    = False
        self._history:  list = []

    @property
    def is_active(self) -> bool:
        return self._active

    def start_session(self, problem_id: str, factory_snapshot: dict) -> None:
        self._active  = True
        self._history = []

    def ask(self, question: str) -> str:
        """Phase 5: route through Claude API via agent."""
        return "[Coach not yet active — Phase 5 feature]"

    def end_session(self) -> None:
        self._active  = False
