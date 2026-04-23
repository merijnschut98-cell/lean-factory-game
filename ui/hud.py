"""
HUD — always-visible overlay.

Draws:
  - Top bar:  clock, speed, room name
  - KPI strip: output, OEE, WIP, FTR, credits
  - Interaction prompt (bottom-centre) when near an interactable
  - Minimap (top-right)
"""
from __future__ import annotations

from typing import Optional

import pygame

from navigation.camera import MAP_W, MAP_H, TILE_SIZE
from config.world_data import TILE_COLORS, ROOMS

# Colors
C_DARK   = (16,  15,  12, 220)
C_GOLD   = (255, 214, 131)
C_INK    = (220, 215, 200)
C_DIM    = (140, 135, 120)
C_GOOD   = (111, 211, 111)
C_WARN   = (255, 184,  77)
C_BAD    = (232,  96,  74)

HUD_H    = 50   # top bar height in px


class HUD:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen   = screen
        self.sw       = screen.get_width()
        self.sh       = screen.get_height()

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_mono  = f["mono"]
        self._font_body  = f["body"]
        self._font_large = f["large"]

        self._minimap_surf: Optional[pygame.Surface] = None
        self._mm_dirty = True
        self._mm_w, self._mm_h = 200, 128

    # ── Main draw ─────────────────────────────────────────────────────────────

    def draw(self, factory, player, facing_obj: Optional[dict] = None) -> None:
        self._draw_top_bar(factory, player)
        self._draw_minimap(player)
        self._draw_room_hud(player, facing_obj)
        if facing_obj:
            self._draw_interact_prompt(facing_obj)

    # ── Top bar ───────────────────────────────────────────────────────────────

    def _draw_top_bar(self, factory, player) -> None:
        surf = pygame.Surface((self.sw, HUD_H), pygame.SRCALPHA)
        surf.fill(C_DARK)
        self.screen.blit(surf, (0, 0))

        # Clock + speed
        clock_txt = factory.time.format_clock() if factory else "Day 1  Shift 1  00:00"
        speed_txt = factory.time.speed_label if factory else "1×"
        left = f"NovaGlide Plant 01   {clock_txt}   [{speed_txt}]"
        self.screen.blit(self._font_mono.render(left, True, C_GOLD), (12, 11))

        # KPI strip
        if factory:
            kpis = [
                ("OUTPUT", f"{factory.last_day_output:>3} / day"),
                ("OEE",    f"{factory.live_oee * 100:>4.1f}%"),
                ("WIP",    f"{factory.live_wip:>3} units"),
                ("FTR",    f"{factory.last_day_ftr * 100:>5.1f}%"),
                ("CREDITS",f"{factory.credits:>6}"),
            ]
            x = self.sw // 2 - 300
            for key, val in kpis:
                k_surf = self._font_mono.render(key, True, C_DIM)
                v_surf = self._font_mono.render(val, True, C_INK)
                self.screen.blit(k_surf, (x, 8))
                self.screen.blit(v_surf, (x, 26))
                x += 130

    # ── Room HUD (top-left, over world) ──────────────────────────────────────

    def _draw_room_hud(self, player, facing_obj: Optional[dict]) -> None:
        room_name = player.current_room()
        sub = "Step up to a machine and press [E]"
        if facing_obj:
            sub = f"Press [E] to inspect · {facing_obj.get('label', '')}"

        surf = pygame.Surface((320, 46), pygame.SRCALPHA)
        surf.fill((16, 15, 12, 180))
        pygame.draw.rect(surf, C_GOLD, (0, 0, 320, 46), 1, border_radius=5)
        self.screen.blit(surf, (10, HUD_H + 8))

        self.screen.blit(
            self._font_large.render(room_name, True, C_GOLD),
            (18, HUD_H + 12)
        )
        self.screen.blit(
            self._font_body.render(sub, True, C_DIM),
            (18, HUD_H + 28)
        )

    # ── Minimap ───────────────────────────────────────────────────────────────

    def _draw_minimap(self, player) -> None:
        if self._mm_dirty or self._minimap_surf is None:
            self._minimap_surf = self._build_minimap()
            self._mm_dirty = False

        mm = self._minimap_surf.copy()

        # Player blip
        mm_tx = int(player.tile_x / MAP_W * self._mm_w)
        mm_ty = int(player.tile_y / MAP_H * self._mm_h)
        pygame.draw.circle(mm, (255, 138, 31), (mm_tx, mm_ty), 2)

        # Viewport rect
        from navigation.camera import Camera
        vw = int(self.sw / (MAP_W * TILE_SIZE) * self._mm_w)
        vh = int(self.sh / (MAP_H * TILE_SIZE) * self._mm_h)
        vx = max(0, mm_tx - vw // 2)
        vy = max(0, mm_ty - vh // 2)
        pygame.draw.rect(mm, (255, 255, 255), (vx, vy, vw, vh), 1)

        # Border
        pygame.draw.rect(mm, C_GOLD, (0, 0, self._mm_w, self._mm_h), 1)

        # Position on screen: top-right
        mm_x = self.sw - self._mm_w - 10
        mm_y = HUD_H + 8
        self.screen.blit(mm, (mm_x, mm_y))

    def _build_minimap(self) -> pygame.Surface:
        surf = pygame.Surface((self._mm_w, self._mm_h))
        surf.fill((10, 9, 8))
        px_per_tx = self._mm_w / MAP_W
        px_per_ty = self._mm_h / MAP_H
        for room in ROOMS:
            x1 = int(room["x1"] * px_per_tx)
            y1 = int(room["y1"] * px_per_ty)
            x2 = int((room["x2"] + 1) * px_per_tx)
            y2 = int((room["y2"] + 1) * px_per_ty)
            # Use a muted room color
            id_colors = {
                "yard":    (80, 75, 65), "factory": (160, 150, 130),
                "corr":    (140, 132, 116), "ops": (120, 140, 160),
                "qua":     (130, 150, 130), "it":  (140, 130, 160),
                "fin":     (130, 150, 150), "hr":  (155, 135, 120),
                "brk":     (145, 128, 108), "mnt": (150, 140, 100),
                "lkr":     (155, 148, 135),
            }
            color = id_colors.get(room["id"], (100, 100, 100))
            pygame.draw.rect(surf, color, (x1, y1, x2 - x1, y2 - y1))
        return surf

    # ── Interaction prompt (bottom-centre) ────────────────────────────────────

    def _draw_interact_prompt(self, obj: dict) -> None:
        label = f"[E]  {obj.get('label', 'Inspect')}"
        txt_surf = self._font_mono.render(label, True, C_GOLD)
        w = txt_surf.get_width() + 24
        h = 28
        x = (self.sw - w) // 2
        y = self.sh - h - 20

        bg = pygame.Surface((w, h), pygame.SRCALPHA)
        bg.fill((16, 15, 12, 200))
        pygame.draw.rect(bg, C_GOLD, (0, 0, w, h), 1, border_radius=4)
        self.screen.blit(bg, (x, y))
        self.screen.blit(txt_surf, (x + 12, y + 7))
