"""
Start screen and pause menu for Lean Factory.

start_screen() — runs before the game loop; returns 'new', 'continue', or 'quit'
pause_menu()   — overlay during gameplay; returns one of 'resume', 'save', 'load',
                 'new_game', or 'quit'
"""
from __future__ import annotations

from pathlib import Path

import pygame

C_BG     = (14,  13,  10)
C_DARK   = (21,  20,  15)
C_GOLD   = (255, 214, 131)
C_INK    = (220, 215, 200)
C_DIM    = (120, 116, 100)
C_WARN   = (232,  96,  74)
C_PANEL  = (28,  26,  20, 230)

_TITLE   = "LEAN FACTORY"
_SUB     = "NovaGlide Plant 01  —  A continuous improvement simulation"
_VERSION = "v0.5  /  Phase 5"


def _make_fonts() -> dict:
    return {
        "huge":  pygame.font.SysFont("Arial", 52, bold=True),
        "large": pygame.font.SysFont("Arial", 22, bold=True),
        "body":  pygame.font.SysFont("Courier New", 16),
        "dim":   pygame.font.SysFont("Courier New", 13),
    }


def _option(screen, font, key: str, label: str, x: int, y: int,
            enabled: bool = True) -> None:
    key_col  = C_GOLD  if enabled else C_DIM
    text_col = C_INK   if enabled else C_DIM
    key_surf  = font.render(f"[{key}]", True, key_col)
    text_surf = font.render(f"  {label}", True, text_col)
    screen.blit(key_surf,  (x, y))
    screen.blit(text_surf, (x + key_surf.get_width(), y))


def start_screen(screen: pygame.Surface, clock: pygame.time.Clock,
                 save_exists: bool) -> str:
    """Blocking loop. Returns 'new', 'continue', or 'quit'."""
    fonts = _make_fonts()
    sw, sh = screen.get_width(), screen.get_height()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return "quit"
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_n:
                    return "new"
                if event.key == pygame.K_c and save_exists:
                    return "continue"
                if event.key in (pygame.K_q, pygame.K_ESCAPE):
                    return "quit"

        screen.fill(C_BG)

        # Title block
        title_surf = fonts["huge"].render(_TITLE, True, C_GOLD)
        tx = (sw - title_surf.get_width()) // 2
        screen.blit(title_surf, (tx, sh // 2 - 140))

        sub_surf = fonts["body"].render(_SUB, True, C_DIM)
        screen.blit(sub_surf, ((sw - sub_surf.get_width()) // 2, sh // 2 - 75))

        # Divider
        pygame.draw.line(screen, (50, 48, 40),
                         (sw // 2 - 200, sh // 2 - 50),
                         (sw // 2 + 200, sh // 2 - 50), 1)

        # Options
        opts_x = sw // 2 - 100
        _option(screen, fonts["large"], "N", "New Game",    opts_x, sh // 2 - 30)
        _option(screen, fonts["large"], "C", "Continue",    opts_x, sh // 2 + 10,
                enabled=save_exists)
        _option(screen, fonts["large"], "Q", "Quit",        opts_x, sh // 2 + 50)

        if not save_exists:
            no_save = fonts["dim"].render("(no save found)", True, C_DIM)
            screen.blit(no_save, (opts_x + 160, sh // 2 + 14))

        # Version
        ver_surf = fonts["dim"].render(_VERSION, True, C_DIM)
        screen.blit(ver_surf, (sw - ver_surf.get_width() - 16, sh - 24))

        pygame.display.flip()
        clock.tick(30)


def pause_menu(screen: pygame.Surface, clock: pygame.time.Clock) -> str:
    """Blocking overlay. Returns 'resume', 'save', 'load', 'new_game', or 'quit'."""
    fonts   = _make_fonts()
    sw, sh  = screen.get_width(), screen.get_height()
    confirm = False   # waiting for Y/N on new-game reset

    # Capture current screen to dim it
    bg = screen.copy()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return "quit"
            if event.type == pygame.KEYDOWN:
                if confirm:
                    if event.key == pygame.K_y:
                        return "new_game"
                    confirm = False
                    continue
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_r:
                    return "resume"
                if event.key == pygame.K_s:
                    return "save"
                if event.key == pygame.K_l:
                    return "load"
                if event.key == pygame.K_n:
                    confirm = True
                if event.key == pygame.K_q:
                    return "quit"

        # Dim background
        screen.blit(bg, (0, 0))
        dim = pygame.Surface((sw, sh), pygame.SRCALPHA)
        dim.fill((0, 0, 0, 160))
        screen.blit(dim, (0, 0))

        # Panel
        pw, ph = 340, confirm and 310 or 270
        px = (sw - pw) // 2
        py = (sh - ph) // 2
        panel = pygame.Surface((pw, ph), pygame.SRCALPHA)
        panel.fill(C_PANEL)
        pygame.draw.rect(panel, C_GOLD, (0, 0, pw, ph), 1, border_radius=6)
        screen.blit(panel, (px, py))

        # Heading
        hdr = fonts["large"].render("PAUSED", True, C_GOLD)
        screen.blit(hdr, (px + (pw - hdr.get_width()) // 2, py + 18))

        pygame.draw.line(screen, (60, 58, 45), (px + 20, py + 50), (px + pw - 20, py + 50))

        ox = px + 40
        if confirm:
            warn = fonts["body"].render("Erase all progress?", True, C_WARN)
            screen.blit(warn, (px + (pw - warn.get_width()) // 2, py + 70))
            _option(screen, fonts["large"], "Y", "Yes, start over", ox, py + 110)
            esc = fonts["dim"].render("[Esc]  Cancel", True, C_DIM)
            screen.blit(esc, (ox, py + 148))
        else:
            _option(screen, fonts["large"], "Esc", "Resume",       ox, py + 68)
            _option(screen, fonts["large"], "S",   "Save",         ox, py + 104)
            _option(screen, fonts["large"], "L",   "Load save",    ox, py + 140)
            _option(screen, fonts["large"], "N",   "New Game",     ox, py + 176)
            _option(screen, fonts["large"], "Q",   "Quit",         ox, py + 212)

        pygame.display.flip()
        clock.tick(30)
