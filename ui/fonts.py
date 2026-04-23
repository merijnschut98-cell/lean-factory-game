"""
Shared font factory — one place to change sizes for all UI panels.
Call make() after pygame.init().
"""
import pygame


def make() -> dict:
    return {
        "mono":  pygame.font.SysFont("Courier New", 13, bold=True),
        "body":  pygame.font.SysFont("Arial",       14),
        "title": pygame.font.SysFont("Arial",       16, bold=True),
        "large": pygame.font.SysFont("Arial",       15, bold=True),
        "kpi":   pygame.font.SysFont("Arial",       22, bold=True),
        "big":   pygame.font.SysFont("Arial",       30, bold=True),
        "label": pygame.font.SysFont("Arial",       14, bold=True),
    }
