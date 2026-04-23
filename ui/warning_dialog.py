"""
Mismatch warning dialog (spec §7.2).

Shows when the player applies a countermeasure to a zone that isn't mature
enough. Non-blocking: player can proceed, cancel, or (Phase 5) ask the coach.

Controls:
  P / Enter   Proceed
  C / Escape  Cancel
"""
from __future__ import annotations
from typing import Optional

import pygame

from ui.text_utils import wrap_text

C_BG    = (14, 13, 10, 240)
C_GOLD  = (255, 214, 131)
C_DIM   = (140, 135, 120)
C_INK   = (220, 215, 200)
C_WARN  = (255, 184, 77)


class WarningDialog:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self._open   = False
        self._text   = ""
        self._result: Optional[str] = None   # "proceed" | "cancel"
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_body  = f["body"]
        self._font_mono  = f["mono"]

    def show(self, warning_text: str) -> None:
        self._text   = warning_text
        self._result = None
        self._open   = True

    def close(self) -> None:
        self._open = False

    @property
    def is_open(self) -> bool:
        return self._open

    def consume_result(self) -> Optional[str]:
        result = self._result
        self._result = None
        return result

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open or event.type != pygame.KEYDOWN:
            return
        if event.key in (pygame.K_RETURN, pygame.K_p):
            self._result = "proceed"
            self._open   = False
        elif event.key in (pygame.K_ESCAPE, pygame.K_c):
            self._result = "cancel"
            self._open   = False

    def draw(self) -> None:
        if not self._open:
            return

        sw, sh = self.screen.get_width(), self.screen.get_height()
        w, h = 580, 240
        x, y = (sw - w) // 2, (sh - h) // 2

        self._overlay.fill((0, 0, 0, 160))
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, (20, 19, 15), (x, y, w, h), border_radius=6)
        pygame.draw.rect(self.screen, C_WARN, (x, y, w, h), 2, border_radius=6)

        self.screen.blit(
            self._font_title.render("⚠  MATURITY MISMATCH WARNING", True, C_WARN),
            (x + 20, y + 18),
        )

        ty = y + 56
        for ln in wrap_text(self._text, self._font_body, w - 40)[:5]:
            self.screen.blit(self._font_body.render(ln, True, C_INK), (x + 20, ty))
            ty += 20

        self.screen.blit(
            self._font_mono.render("[Enter / P]  Proceed    [Esc / C]  Cancel",
                                   True, C_DIM),
            (x + 20, y + h - 30),
        )
