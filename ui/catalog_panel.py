"""
Countermeasure browser panel.

Opens as a full-screen overlay. Player scrolls through CMs filtered by
applicability to the current problem's station type. Pressing Enter / clicking
Apply triggers the mismatch check → warning dialog → application.

Controls:
  Arrow Up / Down   scroll list
  Enter / E         select highlighted CM → apply flow
  Escape            close without applying
"""
from __future__ import annotations
from typing import Optional, List

import pygame

from maturity.mismatch import effectiveness_tier
from problems.countermeasure import Countermeasure

C_BG        = (14, 13, 10, 230)
C_GOLD      = (255, 214, 131)
C_DIM       = (140, 135, 120)
C_INK       = (220, 215, 200)
C_HIGHLIGHT = (50, 48, 40)
C_TIER      = {1: (111, 211, 111), 2: (255, 214, 131),
               3: (255, 170, 80),  4: (232, 96, 74), 0: (160, 160, 180)}
C_LOCKED    = (55, 52, 44)

ROW_H   = 58
VISIBLE = 9    # rows visible at once


class CatalogPanel:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self.sw = screen.get_width()
        self.sh = screen.get_height()

        self._open       = False
        self._cms:       List[Countermeasure] = []
        self._cursor     = 0
        self._scroll     = 0
        self._problem_id: Optional[str] = None
        self._selected:  Optional[Countermeasure] = None
        self._overlay    = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_mono  = f["mono"]
        self._font_body  = f["body"]

    # ── Control ───────────────────────────────────────────────────────────────

    def open(self, problem_id: str, cms: List[Countermeasure]) -> None:
        self._problem_id = problem_id
        self._cms        = cms
        self._cursor     = 0
        self._scroll     = 0
        self._selected   = None
        self._open       = True

    def close(self) -> None:
        self._open     = False
        self._selected = None

    @property
    def is_open(self) -> bool:
        return self._open

    @property
    def problem_id(self) -> Optional[str]:
        return self._problem_id

    @property
    def selected(self) -> Optional[Countermeasure]:
        """Set when player presses Enter on a CM. Caller reads and resets."""
        return self._selected

    def consume_selection(self) -> Optional[Countermeasure]:
        sel = self._selected
        self._selected = None
        return sel

    # ── Input ─────────────────────────────────────────────────────────────────

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type != pygame.KEYDOWN:
            return

        if event.key in (pygame.K_ESCAPE,):
            self.close()
        elif event.key in (pygame.K_UP, pygame.K_w):
            self._cursor = max(0, self._cursor - 1)
            self._clamp_scroll()
        elif event.key in (pygame.K_DOWN, pygame.K_s):
            self._cursor = min(len(self._cms) - 1, self._cursor + 1)
            self._clamp_scroll()
        elif event.key in (pygame.K_RETURN, pygame.K_e):
            if 0 <= self._cursor < len(self._cms):
                self._selected = self._cms[self._cursor]

    def _clamp_scroll(self) -> None:
        if self._cursor < self._scroll:
            self._scroll = self._cursor
        elif self._cursor >= self._scroll + VISIBLE:
            self._scroll = self._cursor - VISIBLE + 1

    # ── Draw ──────────────────────────────────────────────────────────────────

    def draw(self, factory=None) -> None:
        if not self._open:
            return

        self._overlay.fill(C_BG)
        self.screen.blit(self._overlay, (0, 0))

        panel_x, panel_y = 80, 60
        panel_w = self.sw - 160
        panel_h = self.sh - 120

        pygame.draw.rect(self.screen, (20, 19, 15),
                         (panel_x, panel_y, panel_w, panel_h), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD,
                         (panel_x, panel_y, panel_w, panel_h), 1, border_radius=6)

        y = panel_y + 16
        self.screen.blit(
            self._font_title.render("COUNTERMEASURE CATALOG", True, C_GOLD),
            (panel_x + 20, y),
        )
        hint = "[↑↓] scroll   [E/Enter] apply   [Esc] cancel"
        self.screen.blit(self._font_mono.render(hint, True, C_DIM),
                         (panel_x + 20, y + 20))
        y += 46

        pygame.draw.line(self.screen, (40, 38, 30),
                         (panel_x + 12, y), (panel_x + panel_w - 12, y))
        y += 8

        list_area_h = VISIBLE * ROW_H
        visible_cms = self._cms[self._scroll: self._scroll + VISIBLE]

        for i, cm in enumerate(visible_cms):
            abs_i = self._scroll + i
            row_y = y + i * ROW_H
            is_selected = abs_i == self._cursor

            if is_selected:
                pygame.draw.rect(self.screen, C_HIGHLIGHT,
                                 (panel_x + 8, row_y - 2, panel_w - 16, ROW_H - 4),
                                 border_radius=4)

            tier_color = C_TIER.get(cm.tier_int, C_DIM)
            tier_label = f"T{cm.tier}" if not cm.is_diagnostic else "DX"
            self.screen.blit(
                self._font_mono.render(tier_label, True, tier_color),
                (panel_x + 20, row_y + 6),
            )
            self.screen.blit(
                self._font_title.render(cm.name, True, C_INK if not is_selected else C_GOLD),
                (panel_x + 60, row_y + 4),
            )
            desc = cm.description[:90] + "…" if len(cm.description) > 90 else cm.description
            self.screen.blit(
                self._font_body.render(desc, True, C_DIM),
                (panel_x + 60, row_y + 24),
            )

            # Prerequisites met indicator
            if factory and cm.prerequisites:
                active_ids = set(factory.active_countermeasures.keys())
                prereqs_met = all(p in active_ids for p in cm.prerequisites)
                dot = "●" if prereqs_met else "○"
                dot_color = (111, 211, 111) if prereqs_met else (232, 96, 74)
                self.screen.blit(
                    self._font_mono.render(dot, True, dot_color),
                    (panel_x + panel_w - 40, row_y + 14),
                )

        # Tier 5 locked stub — shown when player has scrolled to the bottom
        end_reached = self._scroll + len(visible_cms) >= len(self._cms)
        if end_reached:
            stub_y = y + len(visible_cms) * ROW_H
            if stub_y + ROW_H <= y + list_area_h:
                self._draw_tier5_stub(panel_x, stub_y, panel_w)

        # Detail pane for highlighted CM
        if self._cms and 0 <= self._cursor < len(self._cms):
            self._draw_detail(panel_x, y + list_area_h + 8,
                              panel_w, panel_h - list_area_h - 56, factory)

    def _draw_tier5_stub(self, px: int, py: int, pw: int) -> None:
        self.screen.blit(
            self._font_mono.render("T5", True, C_LOCKED),
            (px + 20, py + 6),
        )
        self.screen.blit(
            self._font_title.render("Tier 5  —  Coming in v2", True, C_LOCKED),
            (px + 60, py + 4),
        )
        self.screen.blit(
            self._font_body.render(
                "Advanced digital integration, AI-driven quality systems, and autonomous improvement loops.",
                True, C_LOCKED,
            ),
            (px + 60, py + 24),
        )

    def _draw_detail(self, px: int, py: int, pw: int, ph: int, factory) -> None:
        if ph < 30:
            return
        cm = self._cms[self._cursor]
        pygame.draw.line(self.screen, (40, 38, 30), (px + 12, py), (px + pw - 12, py))
        y = py + 10
        zone_maturity = 1.0
        if factory:
            # Use first zone that has the CM's station type (approximation)
            zone_maturity = factory.maturity.plant_maturity()

        tier_label = effectiveness_tier(cm.tier_int, zone_maturity)
        eff_colors = {"full": (111, 211, 111), "reduced": (255, 214, 131),
                      "minimal": (255, 140, 60), "no_effect": (232, 96, 74)}
        eff_color = eff_colors.get(tier_label, C_DIM)
        self.screen.blit(
            self._font_mono.render(f"Effect at current maturity: {tier_label.upper()}",
                                   True, eff_color),
            (px + 20, y),
        )
        if cm.prerequisites:
            prereq_txt = "Prereqs: " + ", ".join(cm.prerequisites[:3])
            self.screen.blit(self._font_body.render(prereq_txt, True, C_DIM), (px + 20, y + 18))
