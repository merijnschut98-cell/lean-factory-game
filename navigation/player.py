"""
Player character — tile-aware 2D movement with pixel-level position.

The player moves in pixel space.  Collision is resolved against the
solid grid at the player's foot-circle sample points.
"""
from __future__ import annotations

import math
from typing import Optional, Tuple

from navigation.tilemap import Tilemap

TILE_SIZE   = 24     # px — matches v3.html TS
WALK_SPEED  = 2.0    # px per frame at 60 fps → 120 px/s
RUN_MULT    = 2.5
FOOT_RADIUS = 6      # px — collision sample circle radius


class Player:
    def __init__(self, spawn_tile: Tuple[int, int], tilemap: Tilemap) -> None:
        self.tilemap = tilemap
        # Pixel position (centre of player sprite)
        self.x = spawn_tile[0] * TILE_SIZE + TILE_SIZE // 2
        self.y = spawn_tile[1] * TILE_SIZE + TILE_SIZE // 2
        self.dir = "left"       # "up" / "down" / "left" / "right"
        self.running = False
        # Distance walked since spawn, in pixels — drives the walk-cycle frame.
        self.step_phase: float = 0.0
        self.moving_this_frame: bool = False

        # Interaction detection
        self.facing_object: Optional[dict] = None   # world_data OBJECTS entry
        self._interact_requested = False

    # ── Movement ──────────────────────────────────────────────────────────────

    def move(self, dx: float, dy: float) -> None:
        """
        Apply (dx, dy) pixel-space movement with wall sliding.
        Call once per frame with direction-scaled velocity.
        """
        speed = WALK_SPEED * (RUN_MULT if self.running else 1.0)

        # Normalise diagonal
        length = math.hypot(dx, dy)
        if length > 0:
            dx = dx / length * speed
            dy = dy / length * speed

        # Update facing direction
        if abs(dx) >= abs(dy):
            self.dir = "right" if dx > 0 else "left"
        else:
            self.dir = "down" if dy > 0 else "up"

        # Try full move, then axis-by-axis for wall sliding
        prev_x, prev_y = self.x, self.y
        if not self._is_blocked(self.x + dx, self.y + dy):
            self.x += dx
            self.y += dy
        elif not self._is_blocked(self.x + dx, self.y):
            self.x += dx
        elif not self._is_blocked(self.x, self.y + dy):
            self.y += dy
        travelled = math.hypot(self.x - prev_x, self.y - prev_y)
        self.step_phase += travelled
        self.moving_this_frame = travelled > 0.1

    def _is_blocked(self, px: float, py: float) -> bool:
        """Test foot-circle sample points against the solid grid."""
        r = FOOT_RADIUS
        foot_y = py + 4    # feet slightly below centre
        for sx, sy in [(px - r, foot_y), (px + r, foot_y),
                       (px, foot_y - r), (px, foot_y + r)]:
            tx = int(sx // TILE_SIZE)
            ty = int(sy // TILE_SIZE)
            if self.tilemap.is_solid(tx, ty):
                return True
        return False

    # ── Tile position helpers ─────────────────────────────────────────────────

    @property
    def tile_x(self) -> int:
        return int(self.x // TILE_SIZE)

    @property
    def tile_y(self) -> int:
        return int(self.y // TILE_SIZE)

    @property
    def facing_tile(self) -> Tuple[int, int]:
        tx, ty = self.tile_x, self.tile_y
        offsets = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
        dx, dy = offsets[self.dir]
        return tx + dx, ty + dy

    def current_room(self) -> str:
        return self.tilemap.room_at(self.tile_x, self.tile_y)

    # ── Interaction ───────────────────────────────────────────────────────────

    def detect_facing(self, objects: list) -> Optional[dict]:
        """
        Find the nearest interactable object adjacent to the player.
        Checks the facing tile and its 4 neighbours.
        Also the once-per-frame latch for `moving_this_frame`: move() sets it
        True when velocity lands; the next detect_facing resets it so idle
        frames correctly report "not walking".
        """
        was_moving = self.moving_this_frame
        self.moving_this_frame = False  # cleared each frame; move() re-sets if travelling

        fx, fy = self.facing_tile
        check_tiles = [(fx, fy), (fx-1, fy), (fx+1, fy), (fx, fy-1), (fx, fy+1)]

        for obj in objects:
            ox, oy = obj["tx"], obj["ty"]
            ow, oh = obj["w"], obj["h"]
            for ctx, cty in check_tiles:
                if ox <= ctx < ox + ow and oy <= cty < oy + oh:
                    self.facing_object = obj
                    return obj

        self.facing_object = None
        return None

    def request_interact(self) -> Optional[dict]:
        """Called when E/Space is pressed. Returns the target object."""
        return self.facing_object

    # ── Pixel rect (for rendering) ─────────────────────────────────────────────

    @property
    def rect(self) -> Tuple[int, int, int, int]:
        w, h = 10, 18
        return (int(self.x) - w // 2, int(self.y) - h // 2, w, h)
