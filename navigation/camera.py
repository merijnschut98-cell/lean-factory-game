"""Camera — smoothed lerp, clamped to world bounds."""
from __future__ import annotations

TILE_SIZE  = 24
MAP_W      = 100
MAP_H      = 60
WORLD_W    = MAP_W * TILE_SIZE   # 2400
WORLD_H    = MAP_H * TILE_SIZE   # 1440
LERP_FACTOR = 0.18


class Camera:
    def __init__(self, screen_w: int, screen_h: int) -> None:
        self.screen_w = screen_w
        self.screen_h = screen_h
        # Top-left corner of the viewport in world px
        self.x: float = 0.0
        self.y: float = 0.0

    def update(self, target_px: float, target_py: float) -> None:
        """Lerp toward target (player centre), clamped to world bounds."""
        desired_x = target_px - self.screen_w / 2
        desired_y = target_py - self.screen_h / 2

        self.x += (desired_x - self.x) * LERP_FACTOR
        self.y += (desired_y - self.y) * LERP_FACTOR

        self.x = max(0, min(WORLD_W - self.screen_w, self.x))
        self.y = max(0, min(WORLD_H - self.screen_h, self.y))

    def world_to_screen(self, wx: float, wy: float):
        return wx - self.x, wy - self.y

    def screen_to_world(self, sx: float, sy: float):
        return sx + self.x, sy + self.y

    def visible_tile_range(self):
        """Returns (tx_min, ty_min, tx_max, ty_max) of tiles on screen."""
        tx_min = max(0, int(self.x // TILE_SIZE) - 1)
        ty_min = max(0, int(self.y // TILE_SIZE) - 1)
        tx_max = min(MAP_W - 1, int((self.x + self.screen_w) // TILE_SIZE) + 1)
        ty_max = min(MAP_H - 1, int((self.y + self.screen_h) // TILE_SIZE) + 1)
        return tx_min, ty_min, tx_max, ty_max
