"""
Lean Codex panel — [K] key overlay showing all discovered lean/SS/digitalization concepts.

Concepts unlock as the player encounters them through problems, fork choices, and CM application.
Locked concepts are visible as grey question marks so the player knows how much there is to learn.
"""
from __future__ import annotations
from pathlib import Path

import pygame
import yaml
from ui.text_utils import wrap_text

C_BG      = (14, 13, 10, 245)
C_GOLD    = (255, 214, 131)
C_INK     = (220, 215, 200)
C_DIM     = (100, 96, 82)
C_LOCKED  = (55, 52, 44)
C_GREEN   = (111, 211, 111)

# ── Concept definitions ───────────────────────────────────────────────────────
# All concepts the player can discover. Key = teaches: tag used in YAML.
# Source of truth is data/concepts.yaml (shared with the 3D web build).
_CONCEPTS_PATH = Path(__file__).resolve().parent.parent / "data" / "concepts.yaml"


def _load_codex(path: Path = _CONCEPTS_PATH) -> dict:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    concepts = data.get("concepts")
    if not isinstance(concepts, dict):
        raise ValueError(f"{path}: expected a 'concepts' mapping")
    return {str(k): str(v) for k, v in concepts.items()}


CODEX = _load_codex()

_ALL_KEYS   = sorted(CODEX.keys())
_CODEX_SIZE = len(CODEX)


class CodexPanel:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen   = screen
        self.sw       = screen.get_width()
        self.sh       = screen.get_height()
        self._open    = False
        self._scroll  = 0
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_label = f["label"]
        self._font_body  = f["body"]
        self._font_mono  = f["mono"]

    @property
    def is_open(self) -> bool:
        return self._open

    def toggle(self) -> None:
        self._open = not self._open
        if self._open:
            self._scroll = 0

    def close(self) -> None:
        self._open = False

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type == pygame.MOUSEWHEEL:
            self._scroll = max(0, self._scroll - event.y * 30)
        elif event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_ESCAPE, pygame.K_k):
                self.close()
            elif event.key == pygame.K_UP:
                self._scroll = max(0, self._scroll - 30)
            elif event.key == pygame.K_DOWN:
                self._scroll += 30

    def draw(self, factory=None) -> None:
        if not self._open:
            return

        discovered = factory.discovered_concepts if factory else set()
        unlocked   = [k for k in _ALL_KEYS if k in discovered]
        locked     = [k for k in _ALL_KEYS if k not in discovered]

        pw, ph = 760, self.sh - 60
        px = (self.sw - pw) // 2
        py = 30

        self._overlay.fill((0, 0, 0, 180))
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, (18, 17, 13), (px, py, pw, ph), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD, (px, py, pw, ph), 1, border_radius=6)

        # Header
        ty = py + 16
        self.screen.blit(self._font_title.render("LEAN CODEX", True, C_GOLD), (px + 20, ty))
        count_txt = f"{len(unlocked)} / {len(_ALL_KEYS)} concepts discovered"
        self.screen.blit(self._font_mono.render(count_txt, True, C_DIM),
                         (px + pw - 260, ty + 2))
        ty += 30
        pygame.draw.line(self.screen, (40, 38, 30), (px + 12, ty), (px + pw - 12, ty))
        ty += 8

        # Content area (scrollable)
        content_y_start = ty
        clip_rect = pygame.Rect(px, content_y_start, pw, ph - (content_y_start - py) - 40)
        self.screen.set_clip(clip_rect)

        y = content_y_start - self._scroll

        if unlocked:
            label = f"DISCOVERED  ({len(unlocked)})"
            self.screen.blit(self._font_mono.render(label, True, C_GREEN),
                             (px + 20, y))
            y += 22
            for key in unlocked:
                y = self._draw_entry(px, pw, y, key, CODEX[key], discovered=True)

        if locked:
            y += 6
            label = f"NOT YET ENCOUNTERED  ({len(locked)})"
            self.screen.blit(self._font_mono.render(label, True, C_DIM),
                             (px + 20, y))
            y += 22
            for key in locked:
                y = self._draw_entry(px, pw, y, key, None, discovered=False)

        content_h = y + self._scroll - content_y_start
        self._scroll = min(self._scroll, max(0, content_h - clip_rect.height + 10))

        self.screen.set_clip(None)

        # Scroll indicator
        if content_h > clip_rect.height:
            track_h = clip_rect.height - 8
            thumb_h = max(20, int(track_h * clip_rect.height / content_h))
            thumb_y = content_y_start + 4 + int(
                (self._scroll / max(1, content_h - clip_rect.height)) * (track_h - thumb_h))
            pygame.draw.rect(self.screen, (50, 48, 40),
                             (px + pw - 8, content_y_start + 4, 4, track_h), border_radius=2)
            pygame.draw.rect(self.screen, (140, 130, 100),
                             (px + pw - 8, thumb_y, 4, thumb_h), border_radius=2)

        # Footer hint
        self.screen.blit(
            self._font_mono.render("[K] or [Esc]  Close codex", True, C_DIM),
            (px + 20, py + ph - 28),
        )

    def _draw_entry(self, px: int, pw: int, y: int, key: str,
                    definition: str | None, discovered: bool) -> int:
        label_color = C_GOLD if discovered else C_LOCKED
        def_color   = C_INK  if discovered else C_LOCKED
        tag_display = key.replace("_", " ").upper()

        self.screen.blit(self._font_label.render(tag_display, True, label_color),
                         (px + 20, y))
        y += 18
        if discovered and definition:
            for ln in wrap_text(definition, self._font_body, pw - 48)[:2]:
                self.screen.blit(self._font_body.render(ln, True, def_color),
                                 (px + 28, y))
                y += 16
        elif not discovered:
            self.screen.blit(self._font_body.render("???", True, C_LOCKED),
                             (px + 28, y))
            y += 16
        y += 4
        return y
