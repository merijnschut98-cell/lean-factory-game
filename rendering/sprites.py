"""
Kenney sprite loader — loads CC0 assets from assets/kenney/* and exposes
pygame Surfaces cached by (pack, index). Tiles are scaled from their native
16×16 / 18×18 up to TILE_SIZE (24) so they align with the existing tile grid.

Packs available:
    rpg_urban           (16×16, 486 tiles) — characters, buildings, props
    tiny_town           (16×16, 132 tiles) — village buildings, trees
    industrial          (18×18, 112 tiles) — conveyors, chains, hazard signs
    onebit              (16×16) — monochrome/coloured misc icons

Characters in rpg_urban follow a consistent layout: each row's last 4 columns
(cols 23–26) hold one character's four directional sprites (down, left, right,
up). Character rows live at rows 0–4 of the packed tilemap, giving 5 starter
characters; more appear further down for variants/walk frames.
"""
from __future__ import annotations

from pathlib import Path
from typing import Dict, Tuple

import pygame

from navigation.camera import TILE_SIZE  # 24

# ── Paths ─────────────────────────────────────────────────────────────────────
_ASSETS = Path(__file__).parent.parent / "assets" / "kenney"

_PACK_PATHS = {
    "rpg_urban":  _ASSETS / "rpg_urban"  / "Tilemap" / "tilemap_packed.png",
    "tiny_town":  _ASSETS / "tiny_town"  / "Tilemap" / "tilemap_packed.png",
    "industrial": _ASSETS / "industrial" / "Tilemap" / "tilemap_packed.png",
}

# Native tile sizes per pack (packed tilemaps have no gutters)
_PACK_TILE_PX = {
    "rpg_urban":  16,
    "tiny_town":  16,
    "industrial": 18,
}

# Columns per row in each packed tilemap — inferred from image width / tile size.
_PACK_COLS = {
    "rpg_urban":  27,
    "tiny_town":  12,
    "industrial": 16,
}


# ── Sprite cache ──────────────────────────────────────────────────────────────
_cache: Dict[Tuple[str, int, int], pygame.Surface] = {}
_sheets: Dict[str, pygame.Surface] = {}


def _sheet(pack: str) -> pygame.Surface:
    if pack not in _sheets:
        path = _PACK_PATHS[pack]
        _sheets[pack] = pygame.image.load(str(path)).convert_alpha()
    return _sheets[pack]


def tile(pack: str, index: int, size: int = TILE_SIZE) -> pygame.Surface:
    """Return a scaled pygame Surface for a single tile in a pack."""
    key = (pack, index, size)
    if key in _cache:
        return _cache[key]
    sheet    = _sheet(pack)
    tile_px  = _PACK_TILE_PX[pack]
    cols     = _PACK_COLS[pack]
    col      = index % cols
    row      = index // cols
    src_rect = pygame.Rect(col * tile_px, row * tile_px, tile_px, tile_px)
    raw      = sheet.subsurface(src_rect).copy()
    if size != tile_px:
        raw = pygame.transform.scale(raw, (size, size))
    _cache[key] = raw
    return raw


# ── Character indices ─────────────────────────────────────────────────────────
# Each character in the RPG Urban pack occupies the last 4 columns of a row:
#   col 23 — facing down, idle / walk frame A
#   col 24 — facing down, walk frame B (alternates with A for walk cycle)
#   col 25 — side view (used as-is for right, flipped horizontally for left)
#   col 26 — facing up (back view)
_CHAR_ROWS = [
    (23,  24,  25,  26),   # row 0
    (50,  51,  52,  53),   # row 1
    (77,  78,  79,  80),   # row 2
    (104, 105, 106, 107),  # row 3
    (131, 132, 133, 134),  # row 4
]

_ROLE_CHAR_ROW = {
    "player":              4,   # CI Specialist — distinctive middle character
    "Team Leader":         0,
    "Scheduler":           1,
    "Quality Lead":        2,
    "IT Engineer":         3,
    "Controller":          1,
    "HR Manager":          2,
    "Maintenance Lead":    0,
    "Plant Manager (you)": 4,
    "Lean Coach":          3,   # Black-belt vibe — share row 3 style with IT
}


def character(role: str, direction: str, frame: int = 0,
              size: int = TILE_SIZE) -> pygame.Surface:
    """
    Return a character sprite facing a direction, scaled to `size`.
    `frame` (0 or 1) picks between the two walk-cycle frames for down/up.
    """
    row_idx = _ROLE_CHAR_ROW.get(role, 0)
    quad    = _CHAR_ROWS[row_idx]
    if direction == "down":
        idx = quad[0] if frame == 0 else quad[1]
        return tile("rpg_urban", idx, size)
    if direction == "up":
        # Only one up-frame in the sheet; re-use it for both phases.
        return tile("rpg_urban", quad[3], size)
    # Side view — flip horizontally for "left".
    key = ("rpg_urban_char_side", quad[2], direction, size)
    if key in _cache:
        return _cache[key]
    base = tile("rpg_urban", quad[2], size)
    surf = pygame.transform.flip(base, True, False) if direction == "left" else base
    _cache[key] = surf
    return surf


# ── Station decoration indices (industrial expansion) ─────────────────────────
# Useful industrial tiles. Each station type picks an accent motif — these read
# at a glance as "conveyor", "machine", "control panel", etc.
IND_CONVEYOR_H     = 64   # horizontal conveyor belt
IND_CONVEYOR_STRIP = 68   # hazard-striped conveyor
IND_CHAIN          = 21   # vertical chain
IND_PIPE_H         = 104  # horizontal pipe
IND_PIPE_V         = 44   # vertical pipe
IND_CONTROL_BOX    = 40   # warning/control box
IND_ALARM          = 48   # amber alarm light
IND_GEAR           = 53   # gear / cog
IND_SIGN_WARN      = 42   # yellow warning sign
IND_HAZARD_STRIPE  = 84   # yellow/black hazard stripes
IND_GIRDER_H       = 3    # orange horizontal girder
IND_DIRT_FLOOR     = 0    # dirt/concrete base


_STATION_DECOR = {
    "dock":      IND_CHAIN,
    "bench":     IND_CONTROL_BOX,
    "rack":      IND_CHAIN,
    "machine":   IND_GEAR,
    "cnc":       IND_GEAR,
    "cell":      IND_CONTROL_BOX,
    "line":      IND_CONVEYOR_STRIP,
    "rig":       IND_ALARM,
    "pad":       IND_SIGN_WARN,
    "packline":  IND_CONVEYOR_H,
    "mill":      IND_GEAR,
    "parts":     IND_CHAIN,
    "tools":     IND_CONTROL_BOX,
    "server":    IND_CONTROL_BOX,
    "metro":     IND_SIGN_WARN,
    "truck":     IND_HAZARD_STRIPE,
    "shelf":     IND_CHAIN,
    "lockers":   IND_CONTROL_BOX,
    "clock":     IND_SIGN_WARN,
    "board":     IND_SIGN_WARN,
    "desk":      None,      # offices stay clean
    "desk-exec": None,
    "sofa":      None,
    "vend":      None,
}


def station_decor(kind: str, size: int = TILE_SIZE) -> pygame.Surface | None:
    idx = _STATION_DECOR.get(kind)
    if idx is None:
        return None
    return tile("industrial", idx, size)
