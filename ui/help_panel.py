"""
Keyboard shortcut reference — [F1] overlay showing all controls grouped by context.

Non-blocking overlay: the game continues to tick behind it. Close with F1 or Esc.
Listed keys mirror the routing in main.py and ui/inspector.py — keep in sync.
"""
from __future__ import annotations

import pygame

C_BG_OVERLAY = (0, 0, 0, 180)
C_PANEL      = (18, 17, 13)
C_GOLD       = (255, 214, 131)
C_INK        = (220, 215, 200)
C_DIM        = (140, 135, 120)
C_GROUP      = (180, 170, 120)


_SECTIONS: list[tuple[str, list[tuple[str, str]]]] = [
    ("MOVEMENT", [
        ("W / A / S / D",   "Move"),
        ("Arrow keys",      "Move (or scroll panel when inspector open)"),
        ("Shift (hold)",    "Run — 2.5× movement speed"),
        ("E  /  Space",     "Interact — open inspector on facing object"),
    ]),
    ("TIME", [
        ("P",               "Pause / resume simulation"),
        ("Tab",             "Cycle speed: 1× → 2× → 5×"),
    ]),
    ("PANELS", [
        ("K",               "Open / close Lean Codex"),
        ("F1",              "Open / close this help screen"),
        ("Esc",             "Close current panel, or pause menu if nothing open"),
    ]),
    ("INSPECTOR  —  open via [E] / [Space]", [
        ("1 / 2 / 3",       "Pick fork choice (investigation, 5 Whys, verification)"),
        ("Enter",           "Continue after a choice is revealed"),
        ("C",               "Apply countermeasure (opens catalog)"),
        ("R",               "Resolve problem and see score"),
        ("U",               "Roll back countermeasure (−25% credits)"),
        ("S",               "Standardize after correct verification (+15% bonus)"),
        ("A",               "Adjust after wrong verification (retry the check)"),
        ("H",               "Hire zone specialist (500 credits)"),
    ]),
    ("COUNTERMEASURE CATALOG  —  open via [C]", [
        ("↑ / ↓",           "Navigate the CM list"),
        ("Enter",           "Select highlighted CM"),
        ("Esc",             "Close catalog without applying"),
    ]),
    ("DIALOGS  —  implementation quiz, warnings, score", [
        ("1 / 2 / 3",       "Pick a quiz answer"),
        ("Enter",           "Continue to next question or dismiss"),
        ("Esc",             "Skip quiz / dismiss dialog"),
    ]),
]


class HelpPanel:

    def __init__(self, screen: pygame.Surface) -> None:
        self.screen   = screen
        self.sw       = screen.get_width()
        self.sh       = screen.get_height()
        self._open    = False
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_group = f["label"]
        self._font_body  = f["body"]
        self._font_mono  = f["mono"]

    @property
    def is_open(self) -> bool:
        return self._open

    def toggle(self) -> None:
        self._open = not self._open

    def close(self) -> None:
        self._open = False

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type == pygame.KEYDOWN and event.key in (pygame.K_ESCAPE, pygame.K_F1):
            self.close()

    def draw(self) -> None:
        if not self._open:
            return

        pw, ph = 640, self.sh - 80
        px = (self.sw - pw) // 2
        py = 40

        self._overlay.fill(C_BG_OVERLAY)
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, C_PANEL, (px, py, pw, ph), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD, (px, py, pw, ph), 1, border_radius=6)

        y = py + 18
        self.screen.blit(
            self._font_title.render("KEYBOARD REFERENCE", True, C_GOLD),
            (px + 20, y),
        )
        y += 24
        pygame.draw.line(self.screen, (40, 38, 30), (px + 12, y), (px + pw - 12, y))
        y += 10

        key_col_x = px + 24
        desc_col_x = px + 220

        for group_title, rows in _SECTIONS:
            self.screen.blit(
                self._font_group.render(group_title, True, C_GROUP),
                (key_col_x, y),
            )
            y += 18
            for key_label, description in rows:
                self.screen.blit(
                    self._font_mono.render(key_label, True, C_GOLD),
                    (key_col_x, y),
                )
                self.screen.blit(
                    self._font_body.render(description, True, C_INK),
                    (desc_col_x, y),
                )
                y += 17
            y += 8

        self.screen.blit(
            self._font_mono.render("[F1]  or  [Esc]   Close", True, C_DIM),
            (px + 20, py + ph - 28),
        )
