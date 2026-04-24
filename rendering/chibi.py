"""
Programmatic chibi character sprites — drawn from pygame primitives.

No external art assets. A small human figure is composed each frame from
head + torso + arms + legs shapes. Four directions, two-frame walk cycle.
Used for the player and for role NPCs.
"""
from __future__ import annotations

import pygame

C_OUTLINE = (28, 24, 20)


def draw_chibi(
    surf: pygame.Surface,
    cx: int,
    cy: int,
    direction: str,
    frame: int,
    skin:  tuple = (240, 210, 175),
    shirt: tuple = (232, 96, 74),
    pants: tuple = (50, 50, 70),
    hat:   tuple | None = None,
    prop:  str | None = None,
) -> None:
    """
    Draw a small human figure centred on (cx, cy).

    direction : "up" | "down" | "left" | "right"
    frame     : 0 or 1 — alternates leg positions for the walk cycle
    hat       : optional cap colour (None = no hat)
    prop      : optional "clipboard" | "wrench" | "tablet" | "binder"
    """
    # The torso is the anchor; limbs offset from it.
    torso_w, torso_h = 8, 9
    head_r = 4
    head_y = cy - torso_h // 2 - head_r + 1
    torso_top = cy - torso_h // 2 + 1
    torso_rect = pygame.Rect(cx - torso_w // 2, torso_top, torso_w, torso_h)

    # Legs — two small rects, alternating on frame for walk cycle
    leg_w, leg_h = 3, 5
    leg_y = torso_top + torso_h
    if direction in ("left", "right"):
        # Side view: front leg and back leg alternate
        front_off = -1 if frame == 0 else 1
        back_off  = 1 if frame == 0 else -1
        pygame.draw.rect(surf, pants, (cx - leg_w + front_off, leg_y, leg_w, leg_h))
        pygame.draw.rect(surf, pants, (cx + back_off,          leg_y, leg_w, leg_h))
    else:
        # Front/back view: legs alternate slightly in vertical offset
        lift_l = -1 if frame == 0 else 0
        lift_r = 0 if frame == 0 else -1
        pygame.draw.rect(surf, pants, (cx - leg_w,     leg_y + lift_l, leg_w, leg_h))
        pygame.draw.rect(surf, pants, (cx + 1,         leg_y + lift_r, leg_w, leg_h))

    # Torso (hi-vis shirt) with a darker band for collar
    pygame.draw.rect(surf, shirt, torso_rect)
    band_h = 2
    pygame.draw.rect(surf, _darken(shirt, 0.75),
                     (torso_rect.x, torso_rect.y, torso_rect.w, band_h))

    # Arms — two small rects flanking the torso, with gentle swing
    arm_w, arm_h = 2, 6
    arm_y = torso_top + 2
    if direction == "left":
        swing = 1 if frame == 0 else -1
        pygame.draw.rect(surf, shirt,
                         (torso_rect.x - arm_w, arm_y - swing, arm_w, arm_h))
    elif direction == "right":
        swing = 1 if frame == 0 else -1
        pygame.draw.rect(surf, shirt,
                         (torso_rect.right,     arm_y + swing, arm_w, arm_h))
    else:
        swing_l = 1 if frame == 0 else 0
        swing_r = 0 if frame == 0 else 1
        pygame.draw.rect(surf, shirt,
                         (torso_rect.x - arm_w, arm_y + swing_l, arm_w, arm_h))
        pygame.draw.rect(surf, shirt,
                         (torso_rect.right,     arm_y + swing_r, arm_w, arm_h))

    # Head — skin tone circle, with simple facial hint per direction
    pygame.draw.circle(surf, skin, (cx, head_y), head_r)
    pygame.draw.circle(surf, C_OUTLINE, (cx, head_y), head_r, 1)
    _draw_face(surf, cx, head_y, direction)

    # Hat — drawn over the head
    if hat is not None:
        _draw_hat(surf, cx, head_y, head_r, direction, hat)

    # Prop — a role accessory (clipboard, wrench, etc.) shown side-adjacent
    if prop is not None:
        _draw_prop(surf, cx, torso_top + 3, direction, prop)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _darken(color: tuple, factor: float) -> tuple:
    return tuple(max(0, min(255, int(c * factor))) for c in color[:3])


def _draw_face(surf: pygame.Surface, cx: int, cy: int, direction: str) -> None:
    if direction == "up":
        # Back of head — no features visible
        return
    if direction == "left":
        surf.set_at((cx - 2, cy), C_OUTLINE)  # single eye dot
        return
    if direction == "right":
        surf.set_at((cx + 2, cy), C_OUTLINE)
        return
    # Down (facing camera)
    surf.set_at((cx - 2, cy), C_OUTLINE)
    surf.set_at((cx + 2, cy), C_OUTLINE)


def _draw_hat(surf: pygame.Surface, cx: int, head_y: int, head_r: int,
              direction: str, color: tuple) -> None:
    # Brim (wider ellipse) + crown (smaller rect) gives a hard-hat silhouette.
    brim_rect = pygame.Rect(cx - head_r - 1, head_y - head_r + 1, head_r * 2 + 2, 2)
    crown_rect = pygame.Rect(cx - head_r + 1, head_y - head_r - 1, head_r * 2 - 2, head_r)
    pygame.draw.rect(surf, color, brim_rect, border_radius=1)
    pygame.draw.rect(surf, color, crown_rect, border_radius=2)
    pygame.draw.rect(surf, _darken(color, 0.6), brim_rect, 1, border_radius=1)


def _draw_prop(surf: pygame.Surface, cx: int, cy: int,
               direction: str, prop: str) -> None:
    side = 1 if direction in ("right", "down") else -1
    px = cx + side * 6
    if prop == "clipboard":
        pygame.draw.rect(surf, (220, 210, 180), (px - 2, cy - 1, 4, 5))
        pygame.draw.rect(surf, C_OUTLINE,       (px - 2, cy - 1, 4, 5), 1)
    elif prop == "wrench":
        pygame.draw.rect(surf, (180, 180, 190), (px - 1, cy, 2, 5))
        pygame.draw.circle(surf, (180, 180, 190), (px, cy), 2)
    elif prop == "tablet":
        pygame.draw.rect(surf, (40, 60, 90),    (px - 2, cy - 1, 5, 4))
        pygame.draw.rect(surf, (111, 211, 211), (px - 1, cy,     3, 2))
    elif prop == "binder":
        pygame.draw.rect(surf, (110, 60, 60), (px - 2, cy - 1, 4, 5))
        pygame.draw.rect(surf, (60, 30, 30),  (px - 2, cy - 1, 4, 5), 1)
    elif prop == "paper":
        pygame.draw.rect(surf, (245, 240, 225), (px - 2, cy - 1, 4, 4))
        surf.set_at((px - 1, cy), C_OUTLINE)
        surf.set_at((px - 1, cy + 1), C_OUTLINE)
    elif prop == "scope":
        pygame.draw.rect(surf, (60, 60, 70), (px - 1, cy - 1, 2, 5))
        pygame.draw.circle(surf, (140, 200, 220), (px, cy - 2), 2)
