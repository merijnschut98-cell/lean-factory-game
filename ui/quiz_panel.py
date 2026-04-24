"""
Implementation quiz panel — shown between catalog selection and CM application.

Asks 2 questions about how the chosen countermeasure is correctly implemented.
Not a gate: the CM is always applied afterwards regardless of answers.
Correct answers give a small CIM bonus + unlock teaches tags. Wrong answers
still show the correct approach as feedback — the quiz is a teaching moment.

Controls:
  1 / 2 / 3   pick a choice
  Enter       continue after the feedback is revealed
  Esc         skip remaining questions (no bonus for skipped)
"""
from __future__ import annotations

from typing import List, Optional

import pygame

from problems.countermeasure import Countermeasure, QuizStep
from problems.dialogue import ChoiceOutcome
from ui.text_utils import wrap_text

C_BG        = (14, 13, 10, 230)
C_PANEL     = (20, 19, 15)
C_GOLD      = (255, 214, 131)
C_INK       = (220, 215, 200)
C_DIM       = (140, 135, 120)
C_CORRECT   = (111, 211, 111)
C_PLAUSIBLE = (255, 214, 131)
C_WRONG     = (232, 96, 74)

_OUTCOME_COLOR = {
    ChoiceOutcome.CORRECT:   C_CORRECT,
    ChoiceOutcome.PLAUSIBLE: C_PLAUSIBLE,
    ChoiceOutcome.WRONG:     C_WRONG,
}


class QuizPanel:

    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        self._open            = False
        self._cm: Optional[Countermeasure] = None
        self._steps: List[QuizStep] = []
        self._step_index = 0
        self._revealed_idx: Optional[int] = None  # index of the picked choice (or None)
        self._correct_count = 0
        self._teaches_earned: List[str] = []
        self._result: Optional[dict] = None       # filled when quiz closes
        # Wrapped text cached on state change — avoids re-wrapping on every frame
        self._wrapped_question: List[str]  = []
        self._wrapped_choices:  List[List[str]] = []
        self._wrapped_feedback: List[str]  = []
        self._wrapped_choice_text: List[str] = []

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_body  = f["body"]
        self._font_mono  = f["mono"]

    # ── Control ───────────────────────────────────────────────────────────────

    def open(self, cm: Countermeasure) -> None:
        self._cm              = cm
        self._steps           = list(cm.implementation_quiz)
        self._step_index      = 0
        self._revealed_idx    = None
        self._correct_count   = 0
        self._teaches_earned  = []
        self._result          = None
        self._open            = bool(self._steps)
        if self._open:
            self._refresh_cache()

    @property
    def is_open(self) -> bool:
        return self._open

    def consume_result(self) -> Optional[dict]:
        """Returns {correct_count, total, teaches_earned} after quiz closes, or None."""
        result, self._result = self._result, None
        return result

    # ── Input ─────────────────────────────────────────────────────────────────

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open or event.type != pygame.KEYDOWN:
            return

        if event.key == pygame.K_ESCAPE:
            self._close("skipped")
            return

        step = self._steps[self._step_index]

        if self._revealed_idx is None:
            # Waiting for a pick
            for key, idx in ((pygame.K_1, 0), (pygame.K_2, 1), (pygame.K_3, 2)):
                if event.key == key and idx < len(step.choices):
                    self._revealed_idx = idx
                    chosen = step.choices[idx]
                    if chosen.outcome == ChoiceOutcome.CORRECT:
                        self._correct_count += 1
                        self._teaches_earned.extend(chosen.teaches)
                    self._refresh_feedback_cache()
                    return
        elif event.key == pygame.K_RETURN:
            self._revealed_idx = None
            self._step_index += 1
            if self._step_index >= len(self._steps):
                self._close("completed")
            else:
                self._refresh_cache()

    def _close(self, reason: str) -> None:
        self._result = {
            "reason":         reason,
            "correct_count":  self._correct_count,
            "total":          len(self._steps),
            "teaches_earned": list(self._teaches_earned),
        }
        self._open = False

    # ── Text wrapping cache ───────────────────────────────────────────────────
    # Panel width is 700; inner text area roughly 660 for questions,
    # 630 for choices (offset by 30 for the bullet).

    def _refresh_cache(self) -> None:
        step = self._steps[self._step_index]
        self._wrapped_question = wrap_text(step.question, self._font_body, 660)[:4]
        self._wrapped_choices  = [
            wrap_text(c.text, self._font_body, 630)[:3] for c in step.choices[:3]
        ]
        self._wrapped_feedback = []
        self._wrapped_choice_text = []

    def _refresh_feedback_cache(self) -> None:
        if self._revealed_idx is None:
            return
        step   = self._steps[self._step_index]
        chosen = step.choices[self._revealed_idx]
        self._wrapped_choice_text = wrap_text(chosen.text, self._font_body, 660)[:3]
        self._wrapped_feedback    = wrap_text(chosen.feedback, self._font_body, 660)[:6]

    # ── Draw ──────────────────────────────────────────────────────────────────

    def draw(self) -> None:
        if not self._open or not self._cm:
            return

        sw, sh = self.screen.get_width(), self.screen.get_height()
        w, h   = 700, 520
        x, y   = (sw - w) // 2, (sh - h) // 2

        self._overlay.fill(C_BG)
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, C_PANEL, (x, y, w, h), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD, (x, y, w, h), 1, border_radius=6)

        ty = y + 18
        self.screen.blit(self._font_mono.render("IMPLEMENTATION", True, C_DIM), (x + 20, ty))
        ty += 18
        self.screen.blit(self._font_title.render(self._cm.name, True, C_GOLD), (x + 20, ty))
        ty += 26

        step = self._steps[self._step_index]
        progress = f"Question {self._step_index + 1} of {len(self._steps)}"
        self.screen.blit(self._font_mono.render(progress, True, C_DIM), (x + 20, ty))
        ty += 18

        pygame.draw.line(self.screen, (40, 38, 30), (x + 12, ty), (x + w - 12, ty))
        ty += 12

        self.screen.blit(self._font_mono.render(f"[ {step.npc} ]", True, C_GOLD), (x + 20, ty))
        ty += 18

        for ln in self._wrapped_question:
            self.screen.blit(self._font_body.render(ln, True, C_INK), (x + 20, ty))
            ty += 18
        ty += 6

        if self._revealed_idx is None:
            ty = self._draw_choices(x, ty, step)
        else:
            ty = self._draw_feedback(x, ty, step)

        hint = (
            "[1][2][3]  pick an answer        [Esc]  skip quiz"
            if self._revealed_idx is None
            else "[Enter]  continue          [Esc]  skip remaining"
        )
        self.screen.blit(self._font_mono.render(hint, True, C_DIM), (x + 20, y + h - 28))

    def _draw_choices(self, x: int, ty: int, step: QuizStep) -> int:
        for i, lines in enumerate(self._wrapped_choices):
            self.screen.blit(self._font_mono.render(f"[{i + 1}]", True, C_GOLD), (x + 20, ty))
            for ln in lines:
                self.screen.blit(self._font_body.render(ln, True, C_INK), (x + 50, ty))
                ty += 18
            ty += 6
        return ty

    def _draw_feedback(self, x: int, ty: int, step: QuizStep) -> int:
        chosen = step.choices[self._revealed_idx]
        color  = _OUTCOME_COLOR.get(chosen.outcome, C_DIM)

        self.screen.blit(self._font_mono.render(chosen.outcome.value, True, color), (x + 20, ty))
        ty += 22

        for ln in self._wrapped_choice_text:
            self.screen.blit(self._font_body.render(ln, True, C_INK), (x + 20, ty))
            ty += 18
        ty += 8

        for ln in self._wrapped_feedback:
            self.screen.blit(self._font_body.render(ln, True, C_DIM), (x + 20, ty))
            ty += 18
        return ty
