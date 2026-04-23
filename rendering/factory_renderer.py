"""
Factory renderer — draws the tilemap, objects, NPCs, and player.

Rendering is fully separated from simulation state.  It reads data
from the factory model but never writes to it.

Drawing order (painter's algorithm):
  1. Tilemap (static background, prerendered to a surface once)
  2. Objects sorted by (ty + h) so taller objects overlap correctly
  3. NPCs
  4. Player
  5. Interaction highlight (dashed outline on facing target)
  6. HUD and UI panels (drawn by ui/ layer on top)
"""
from __future__ import annotations

import math
from typing import Optional, Tuple, List

import pygame

from config.world_data import TILE_COLORS, OBJECTS, NPCS, TILE
from navigation.camera import Camera, TILE_SIZE, MAP_W, MAP_H
from navigation.tilemap import Tilemap
from navigation.player import Player

# ── Palette ───────────────────────────────────────────────────────────────────
COLOR_INK      = (28,  27,  23)
COLOR_GOLD     = (202, 162, 74)
COLOR_ORANGE   = (255, 138, 31)
COLOR_RUNNING  = (111, 211, 111)
COLOR_WAITING  = (255, 184, 77)
COLOR_BLOCKED  = (232, 96,  74)

# Machine kind → fill color (body of the machine sprite)
KIND_COLORS = {
    "dock":     (90,  90,  80),
    "bench":    (180, 160, 120),
    "rack":     (120, 130, 140),
    "machine":  (70,  100, 130),
    "cnc":      (60,  80,  100),
    "cell":     (100, 130, 110),
    "line":     (80,  110, 150),
    "rig":      (100, 90,  130),
    "pad":      (50,  90,  110),
    "packline": (130, 100, 100),
    "desk":     (160, 140, 100),
    "desk-exec":(140, 110,  80),
    "board":    (200, 180, 130),
    "metro":    (120, 120, 140),
    "server":   (60,  60,  80),
    "shelf":    (140, 120,  90),
    "sofa":     (160, 130, 110),
    "table":    (150, 130, 100),
    "vend":     (80,  110,  80),
    "tools":    (100, 90,  70),
    "mill":     (70,  80,  90),
    "parts":    (110, 100, 80),
    "lockers":  (140, 140, 150),
    "clock":    (60,  60,  60),
    "truck":    (80,  90,  70),
    "sofa":     (160, 130, 110),
}


class FactoryRenderer:
    def __init__(self, screen: pygame.Surface, tilemap: Tilemap) -> None:
        self.screen   = screen
        self.tilemap  = tilemap
        self.camera   = Camera(screen.get_width(), screen.get_height())
        self._bg_surface: Optional[pygame.Surface] = None
        self._bg_dirty = True

        # Sorted object list for painter's algorithm
        self._sorted_objects = sorted(OBJECTS, key=lambda o: o["ty"] + o["h"])

        # Cached fonts for hot-path rendering (SysFont is expensive to build per-frame)
        self._font_label       = pygame.font.SysFont("Courier New", 9)
        self._font_badge       = pygame.font.SysFont("Arial", 10, bold=True)
        self._font_indicator   = pygame.font.SysFont("Arial", 11, bold=True)

    # ── Background prerender ──────────────────────────────────────────────────

    def _prerender_bg(self) -> None:
        world_w = MAP_W * TILE_SIZE
        world_h = MAP_H * TILE_SIZE
        surf = pygame.Surface((world_w, world_h))

        for ty in range(MAP_H):
            for tx in range(MAP_W):
                color = self.tilemap.color_at(tx, ty)
                rect  = (tx * TILE_SIZE, ty * TILE_SIZE, TILE_SIZE, TILE_SIZE)
                surf.fill(color, rect)

                # Subtle grout lines on concrete tiles
                tile_code = self.tilemap.tile_at(tx, ty)
                if tile_code == TILE["concrete"]:
                    darker = tuple(max(0, c - 18) for c in color)
                    pygame.draw.rect(surf, darker, rect, 1)

        # Zone labels (semi-transparent monospace text on floor)
        font = pygame.font.SysFont("Courier New", 11, bold=True)
        labels = [
            ("Z1  RECEIVING",   4,  6,  13),
            ("Z2  COMPONENT PREP", 18, 6, 14),
            ("Z3  SUBASSEMBLY", 35, 6, 15),
            ("Z4  FINAL ASSEMBLY", 11, 22, 16),
            ("Z5  TESTING",     11, 28, 17),
            ("Z6  PACKAGING",   43, 28, 18),
        ]
        for text, tx, ty, tile_code in labels:
            base_color = TILE_COLORS.get(tile_code, (180, 160, 120))
            ink = tuple(max(0, c - 60) for c in base_color)
            label_surf = font.render(text, True, ink)
            label_surf.set_alpha(140)
            px = tx * TILE_SIZE + 4
            py = ty * TILE_SIZE + 4
            surf.blit(label_surf, (px, py))

        self._bg_surface = surf
        self._bg_dirty   = False

    # ── Main draw ─────────────────────────────────────────────────────────────

    def draw(self, player: Player, factory=None) -> None:
        if self._bg_dirty or self._bg_surface is None:
            self._prerender_bg()

        # Update camera to follow player
        self.camera.update(player.x, player.y)
        cam_x = int(self.camera.x)
        cam_y = int(self.camera.y)

        # 1. Background (blit the prerendered tile surface)
        self.screen.blit(self._bg_surface, (-cam_x, -cam_y))

        # 2. Objects (machines, desks, etc.)
        for obj in self._sorted_objects:
            self._draw_object(obj, cam_x, cam_y, factory)

        # 3. NPCs
        for npc in NPCS:
            self._draw_npc(npc, cam_x, cam_y)

        # 4. Player
        self._draw_player(player, cam_x, cam_y)

        # 5. Interaction highlight
        if player.facing_object:
            self._draw_highlight(player.facing_object, cam_x, cam_y)

        # 6. Interaction indicators (dialogue fork available + PDCA follow-up due)
        if factory:
            self._draw_interaction_indicators(factory, cam_x, cam_y)
            self._draw_followup_badges(factory, cam_x, cam_y)

    # ── Object drawing ────────────────────────────────────────────────────────

    def _draw_object(self, obj: dict, cam_x: int, cam_y: int, factory) -> None:
        px = obj["tx"] * TILE_SIZE - cam_x
        py = obj["ty"] * TILE_SIZE - cam_y
        pw = obj["w"]  * TILE_SIZE
        ph = obj["h"]  * TILE_SIZE

        if px + pw < 0 or px > self.screen.get_width():
            return
        if py + ph < 0 or py > self.screen.get_height():
            return

        body_color = KIND_COLORS.get(obj.get("kind", ""), (120, 120, 120))
        rect = pygame.Rect(px + 2, py + 2, pw - 4, ph - 4)
        pygame.draw.rect(self.screen, body_color, rect, border_radius=3)

        if "station_id" in obj and factory:
            st = factory.stations.get(obj["station_id"])
            if st:
                oee = st.oee
                dot_color = COLOR_RUNNING if oee > 0.5 else (COLOR_WAITING if oee > 0.25 else COLOR_BLOCKED)
                pygame.draw.circle(self.screen, dot_color, (px + pw - 8, py + 8), 4)

            # Problem indicator: red ! badge if station has an active problem
            has_problem = any(
                p.station_id == obj["station_id"]
                for p in factory.active_problems.values()
            )
            if has_problem:
                self._draw_problem_badge(px + pw - 10, py + ph - 10)

        label_surf = self._font_label.render(obj.get("label", ""), True, (230, 225, 210))
        self.screen.blit(label_surf, (px + 4, py + 4))

    def _draw_problem_badge(self, cx: int, cy: int) -> None:
        """Red exclamation badge indicating an active problem on this station."""
        pygame.draw.circle(self.screen, (220, 50, 50), (cx, cy), 7)
        surf = self._font_badge.render("!", True, (255, 255, 255))
        self.screen.blit(surf, (cx - surf.get_width() // 2, cy - surf.get_height() // 2))

    def _draw_npc(self, npc: dict, cam_x: int, cam_y: int) -> None:
        px = npc["tx"] * TILE_SIZE + TILE_SIZE // 2 - cam_x
        py = npc["ty"] * TILE_SIZE + TILE_SIZE // 2 - cam_y
        color = npc.get("color", (180, 140, 100))
        pygame.draw.circle(self.screen, color, (px, py), 7)
        pygame.draw.circle(self.screen, COLOR_INK, (px, py), 7, 1)

    def _draw_player(self, player: Player, cam_x: int, cam_y: int) -> None:
        sx = int(player.x) - cam_x
        sy = int(player.y) - cam_y
        # Body
        pygame.draw.rect(self.screen, (245, 240, 225),
                         (sx - 5, sy - 7, 10, 14), border_radius=2)
        # Hi-vis collar
        pygame.draw.rect(self.screen, COLOR_ORANGE,
                         (sx - 5, sy - 7, 10, 4), border_radius=2)
        # Head
        pygame.draw.circle(self.screen, (240, 210, 175), (sx, sy - 10), 5)

    # ── Interaction highlight ─────────────────────────────────────────────────

    def _draw_interaction_indicators(self, factory, cam_x: int, cam_y: int) -> None:
        """
        Draw [?] badges on stations and role-desks that have an unread dialogue fork.
        Pulse alpha based on game time so badges draw the eye without being distracting.
        """
        ticks = pygame.time.get_ticks()
        pulse = int(180 + 75 * abs(math.sin(ticks / 700.0)))

        # Collect NPC roles that have an available (incomplete) fork
        roles_with_fork: set = set()
        stations_with_fork: set = set()
        for prob in factory.active_problems.values():
            if not prob.dialogue or not prob.dialogue.investigation:
                continue
            session = factory.investigation_sessions.get(prob.id)
            if session and session.fork_complete:
                continue
            roles_with_fork.add(prob.dialogue.investigation.npc)
            stations_with_fork.add(prob.station_id)

        if not roles_with_fork and not stations_with_fork:
            return

        for obj in OBJECTS:
            has_indicator = False
            if obj.get("station_id") in stations_with_fork:
                has_indicator = True
            elif obj.get("role") in roles_with_fork:
                has_indicator = True

            if not has_indicator:
                continue

            px = obj["tx"] * TILE_SIZE - cam_x
            py = obj["ty"] * TILE_SIZE - cam_y
            pw = obj["w"]  * TILE_SIZE

            # Skip off-screen
            if px + pw < 0 or px > self.screen.get_width():
                continue

            # Pulsing ring above the object
            cx = px + pw // 2
            cy = py - 6
            ring_surf = pygame.Surface((20, 20), pygame.SRCALPHA)
            pygame.draw.circle(ring_surf, (255, 214, 131, pulse), (10, 10), 9, 2)
            # [?] label inside
            q = self._font_indicator.render("?", True, (255, 214, 131))
            ring_surf.set_alpha(pulse)
            self.screen.blit(ring_surf, (cx - 10, cy - 10))
            self.screen.blit(q, (cx - q.get_width() // 2, cy - q.get_height() // 2))

    def _draw_followup_badges(self, factory, cam_x: int, cam_y: int) -> None:
        """Pulsing ↻ badge on stations where a CM follow-up check (PDCA Check) is due."""
        due = factory.follow_up_due_stations
        if not due:
            return

        ticks = pygame.time.get_ticks()
        pulse = int(160 + 95 * abs(math.sin(ticks / 900.0)))
        color = (111, 211, 111)   # green — positive prompt, not a warning

        for obj in OBJECTS:
            if obj.get("station_id") not in due:
                continue
            px = obj["tx"] * TILE_SIZE - cam_x
            py = obj["ty"] * TILE_SIZE - cam_y
            pw = obj["w"]  * TILE_SIZE

            if px + pw < 0 or px > self.screen.get_width():
                continue

            cx = px + pw // 2
            cy = py - 6

            ring_surf = pygame.Surface((20, 20), pygame.SRCALPHA)
            pygame.draw.circle(ring_surf, (*color, pulse), (10, 10), 9, 2)
            lbl = self._font_indicator.render("↻", True, color)
            ring_surf.set_alpha(pulse)
            self.screen.blit(ring_surf, (cx - 10, cy - 22))
            self.screen.blit(lbl, (cx - lbl.get_width() // 2, cy - 22 - lbl.get_height() // 2 + 10))

    def _draw_highlight(self, obj: dict, cam_x: int, cam_y: int) -> None:
        px = obj["tx"] * TILE_SIZE - cam_x - 2
        py = obj["ty"] * TILE_SIZE - cam_y - 2
        pw = obj["w"]  * TILE_SIZE + 4
        ph = obj["h"]  * TILE_SIZE + 4
        # Dashed golden outline (approximated with 4 corner rects)
        color = COLOR_GOLD
        thickness = 2
        pygame.draw.rect(self.screen, color,
                         (px, py, pw, ph), thickness, border_radius=4)
