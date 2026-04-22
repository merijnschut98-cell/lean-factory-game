"""
Score display panel — shown after a problem is resolved.

Displays all six metrics with scores, total, and credits earned.
Player presses any key to dismiss.
"""
from __future__ import annotations
from typing import Optional

import pygame

C_BG    = (14, 13, 10, 245)
C_GOLD  = (255, 214, 131)
C_DIM   = (140, 135, 120)
C_INK   = (220, 215, 200)
C_GOOD  = (111, 211, 111)
C_MID   = (255, 214, 131)
C_BAD   = (232, 96, 74)

_METRIC_LABELS = {
    "DQQ": "Diagnostic Question Quality",
    "EI":  "Evidence Integration",
    "RCA": "Root Cause Accuracy",
    "CMP": "Countermeasure Practicality",
    "LM":  "Lean Maturity",
    "CIM": "Continuous Improvement Mindset",
}


def _score_color(score: int) -> tuple:
    if score >= 5:
        return C_GOOD
    elif score >= 3:
        return C_MID
    return C_BAD


class ScorePanel:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen  = screen
        self._open   = False
        self._scores: dict = {}
        self._total  = 0
        self._credits_earned = 0
        self._problem_name = ""
        self._dismissed = False
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        self._font_title = pygame.font.SysFont("Arial", 16, bold=True)
        self._font_label = pygame.font.SysFont("Arial", 12, bold=True)
        self._font_body  = pygame.font.SysFont("Arial", 12)
        self._font_big   = pygame.font.SysFont("Arial", 28, bold=True)
        self._font_mono  = pygame.font.SysFont("Courier New", 10, bold=True)

    def show(self, problem_name: str, scores: dict, total: int, credits_earned: int) -> None:
        self._problem_name   = problem_name
        self._scores         = scores
        self._total          = total
        self._credits_earned = credits_earned
        self._dismissed      = False
        self._open           = True

    def close(self) -> None:
        self._open = False

    @property
    def is_open(self) -> bool:
        return self._open

    def consume_dismiss(self) -> bool:
        if self._dismissed:
            self._dismissed = False
            self._open = False
            return True
        return False

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type == pygame.KEYDOWN:
            self._dismissed = True

    def draw(self) -> None:
        if not self._open:
            return

        sw, sh = self.screen.get_width(), self.screen.get_height()
        w, h = 560, 440
        x, y = (sw - w) // 2, (sh - h) // 2

        self._overlay.fill((0, 0, 0, 180))
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, (20, 19, 15), (x, y, w, h), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD, (x, y, w, h), 1, border_radius=6)

        ty = y + 18
        self.screen.blit(
            self._font_title.render("PROBLEM RESOLVED", True, C_GOLD), (x + 20, ty))
        ty += 22
        self.screen.blit(
            self._font_body.render(self._problem_name, True, C_DIM), (x + 20, ty))
        ty += 28

        pygame.draw.line(self.screen, (40, 38, 30), (x + 12, ty), (x + w - 12, ty))
        ty += 12

        for metric_key, label in _METRIC_LABELS.items():
            score = self._scores.get(metric_key, 0)
            color = _score_color(score)

            self.screen.blit(self._font_label.render(label, True, C_INK), (x + 20, ty))
            # Score dots
            for dot_i in range(5):
                dot_color = color if dot_i < score else (50, 48, 40)
                pygame.draw.circle(self.screen, dot_color,
                                   (x + w - 90 + dot_i * 18, ty + 7), 6)
            score_txt = self._font_label.render(f"{score}/5", True, color)
            self.screen.blit(score_txt, (x + w - 40, ty))
            ty += 24

        pygame.draw.line(self.screen, (40, 38, 30), (x + 12, ty + 4), (x + w - 12, ty + 4))
        ty += 16

        total_txt = self._font_big.render(f"{self._total}  /  30", True, C_GOLD)
        self.screen.blit(total_txt, (x + 20, ty))

        credits_txt = self._font_title.render(
            f"+{self._credits_earned} improvement credits", True, C_GOOD)
        self.screen.blit(credits_txt, (x + 20, ty + 38))

        self.screen.blit(
            self._font_mono.render("Press any key to continue", True, C_DIM),
            (x + 20, y + h - 30),
        )
