"""
Claude API client — Phase 8 stub.

All Claude API calls are isolated here. No other module imports anthropic.
Default model: claude-sonnet-4-6 (cost target: <€0.50/hr gameplay).
"""
from __future__ import annotations
from typing import Optional


class LeanFactoryAgent:
    def __init__(self, api_key: str) -> None:
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY is required for AI features")
        self._api_key = api_key
        self._client  = None
        self._session_cost_eur = 0.0

    def _ensure_client(self):
        if self._client is None:
            import anthropic
            self._client = anthropic.Anthropic(api_key=self._api_key)

    def coach_query(self, system_prompt: str, conversation: list) -> str:
        """Phase 8: implement full coach dialogue with prompt caching."""
        raise NotImplementedError("AI integration is Phase 8")

    def generate_problem(self, factory_state: dict) -> dict:
        """Phase 8: implement problem generation when catalog is exhausted."""
        raise NotImplementedError("AI integration is Phase 8")

    @property
    def session_cost_eur(self) -> float:
        return self._session_cost_eur
