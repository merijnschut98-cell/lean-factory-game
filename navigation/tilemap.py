"""
Tilemap — builds the 100×60 tile grid procedurally, mirroring the logic in
Lean Factory Topology v3.html.

Tile codes and colors are defined in config/world_data.py.
"""
from __future__ import annotations

from typing import List

from config.world_data import TILE, SOLID_TILES, OBJECTS, TILE_COLORS


MAP_W = 100
MAP_H = 60


class Tilemap:
    def __init__(self) -> None:
        # tiles[row][col]
        self.tiles: List[List[int]] = [[TILE["void"]] * MAP_W for _ in range(MAP_H)]
        self.solid: List[List[int]] = [[1] * MAP_W for _ in range(MAP_H)]
        self._build()

    # ── Builder helpers ───────────────────────────────────────────────────────

    def _fill(self, x1: int, y1: int, x2: int, y2: int, val: int) -> None:
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                if 0 <= y < MAP_H and 0 <= x < MAP_W:
                    self.tiles[y][x] = val

    def _stroke(self, x1: int, y1: int, x2: int, y2: int, val: int) -> None:
        for x in range(x1, x2 + 1):
            if 0 <= y1 < MAP_H: self.tiles[y1][x] = val
            if 0 <= y2 < MAP_H: self.tiles[y2][x] = val
        for y in range(y1, y2 + 1):
            if 0 <= y < MAP_H and 0 <= x1 < MAP_W: self.tiles[y][x1] = val
            if 0 <= y < MAP_H and 0 <= x2 < MAP_W: self.tiles[y][x2] = val

    def _door(self, tx: int, ty: int) -> None:
        if 0 <= ty < MAP_H and 0 <= tx < MAP_W:
            self.tiles[ty][tx] = TILE["door"]
            self.solid[ty][tx] = 0

    # ── Main build — mirrors v3.html procedural logic exactly ─────────────────

    def _build(self) -> None:
        T = TILE
        # Grass strip top row
        self._fill(0, 0, MAP_W - 1, 0, T["grass"])
        # Exterior yard (rows 1–3, cols 0–69)
        self._fill(0, 1, 69, 3, T["asphalt"])
        # Factory floor (rows 4–30, cols 0–69)
        self._fill(0, 4, 69, 30, T["concrete"])
        # Factory outer walls
        self._stroke(0, 4, 69, 30, T["wall"])
        # Dock gate opening top edge (cols 4–10, row 4 → asphalt instead of wall)
        for x in range(4, 11):
            self.tiles[4][x] = T["asphalt"]

        # Zone paint colours (U-shape layout)
        self._fill(3,  6, 16, 15, T["zone_recv"])
        self._fill(18, 6, 33, 15, T["zone_prep"])
        self._fill(35, 6, 65, 15, T["zone_sub"])
        self._fill(11, 22, 65, 26, T["zone_final"])
        self._fill(11, 28, 39, 30, T["zone_test"])
        self._fill(43, 28, 65, 30, T["zone_pack"])

        # Hazard stripes at dock gate
        for x in range(4, 11):
            self.tiles[5][x] = T["hazard"]

        # Office wing — corridor (cols 70–77)
        self._fill(70, 4, 77, 59, T["carpet_gray"])
        # Office rooms
        self._fill(78, 4,  99, 12, T["carpet_blue"])    # Operations
        self._fill(78, 13, 99, 21, T["carpet_green"])   # Quality
        self._fill(78, 22, 99, 30, T["carpet_purple"])  # IT
        self._fill(78, 31, 99, 39, T["carpet_teal"])    # Finance
        self._fill(78, 40, 99, 48, T["carpet_orange"])  # HR
        self._fill(78, 49, 99, 59, T["carpet_brown"])   # Break
        # Office outer walls + room separators
        self._stroke(70, 4, 99, 59, T["wall"])
        for sep_y in [13, 22, 31, 40, 49]:
            for x in range(78, 100):
                if 0 <= x < MAP_W:
                    self.tiles[sep_y][x] = T["wall"]
        # Corridor / room dividing wall at col 78 with doors
        for y in range(4, 60):
            if 0 <= y < MAP_H:
                self.tiles[y][78] = T["wall"]
        for door_y in [8, 17, 26, 35, 44, 54]:
            self._door(78, door_y)

        # Factory floor → corridor door
        self._door(69, 17)
        if 0 <= 70 < MAP_W:
            self.tiles[17][70] = T["carpet_gray"]

        # South wing: maintenance + locker
        self._fill(0,  31, 69, 59, T["maintenance"])
        self._stroke(0, 31, 69, 59, T["wall"])
        self._fill(30, 48, 69, 59, T["locker"])
        self._stroke(30, 48, 69, 59, T["wall"])
        # Inner wall between maintenance and locker (col 30), door at row 54
        for y in range(31, 60):
            if 0 <= y < MAP_H:
                self.tiles[y][30] = T["door"] if y == 54 else T["wall"]
                if y == 54:
                    self.solid[y][30] = 0

        # Doors in factory south wall to sub-wings
        self._door(14, 30)
        self._door(48, 30)
        if 0 <= 31 < MAP_H: self.tiles[31][14] = T["maintenance"]
        if 0 <= 31 < MAP_H: self.tiles[31][48] = T["locker"]

        # Locker → corridor door
        self._door(69, 54)

        # Re-apply factory south wall (overwrite zone paint that may have spilled)
        for x in range(0, 70):
            if self.tiles[30][x] != T["door"]:
                self.tiles[30][x] = T["wall"]
        for y in range(4, 31):
            if self.tiles[y][69] != T["door"]:
                self.tiles[y][69] = T["wall"]

        # Build collision grid: walls, void, grass are solid
        for y in range(MAP_H):
            for x in range(MAP_W):
                self.solid[y][x] = 1 if self.tiles[y][x] in SOLID_TILES else 0

        # Mark object footprints as solid
        for obj in OBJECTS:
            for dy in range(obj["h"]):
                for dx in range(obj["w"]):
                    tx, ty = obj["tx"] + dx, obj["ty"] + dy
                    if 0 <= ty < MAP_H and 0 <= tx < MAP_W:
                        self.solid[ty][tx] = 1

    # ── Query helpers ─────────────────────────────────────────────────────────

    def is_solid(self, tx: int, ty: int) -> bool:
        if tx < 0 or ty < 0 or tx >= MAP_W or ty >= MAP_H:
            return True
        return bool(self.solid[ty][tx])

    def tile_at(self, tx: int, ty: int) -> int:
        if tx < 0 or ty < 0 or tx >= MAP_W or ty >= MAP_H:
            return TILE["void"]
        return self.tiles[ty][tx]

    def color_at(self, tx: int, ty: int) -> tuple:
        return TILE_COLORS.get(self.tile_at(tx, ty), (10, 9, 8))

    def room_at(self, tx: int, ty: int) -> str:
        from config.world_data import ROOMS
        for room in ROOMS:
            if room["x1"] <= tx <= room["x2"] and room["y1"] <= ty <= room["y2"]:
                return room["name"]
        return "Unknown"
