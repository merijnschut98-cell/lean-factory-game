"""
Inspector panel — right-side overlay shown when player interacts with an object.

Matches the v3.html inspector panel design:
  Station  → 2×2 KPI grid + station details
  NPC/Role → character info + dialog line
  Generic  → placeholder card
"""
from __future__ import annotations

from typing import Optional

import pygame

C_PANEL      = (21, 20, 15, 240)
C_PANEL_INK  = (220, 215, 200)
C_GOLD       = (255, 214, 131)
C_DIM        = (140, 135, 120)
C_RUNNING    = (111, 211, 111)
C_WAITING    = (255, 184, 77)
C_BLOCKED    = (232, 96, 74)

PANEL_W = 340


def _status_color(status: str) -> tuple:
    return {"run": C_RUNNING, "wait": C_WAITING, "block": C_BLOCKED}.get(status, C_DIM)


NPC_LINES = {
    "Team Leader":       "Board's clean, but the numbers… don't ask.",
    "Scheduler":         "I'm trying to level the schedule. The dock disagrees.",
    "Quality Lead":      "FTR is 91.8%. That 8.2% keeps me up at night.",
    "IT Engineer":       "MES says one thing. The floor says another. I believe the floor.",
    "Controller":        "Cost of poor quality is real. Nobody tracks it properly.",
    "HR Manager":        "We have 24 operators. 1 of them carries the whole line.",
    "Maintenance Lead":  "Reactive maintenance is a tax. Nobody reads the invoice.",
    "Plant Manager (you)": "Your plant. Your call. Walk the floor first.",
}


class Inspector:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self.sh     = screen.get_height()
        self._open  = False
        self._obj: Optional[dict] = None
        self._factory = None

        self._font_mono  = pygame.font.SysFont("Courier New", 10, bold=True)
        self._font_body  = pygame.font.SysFont("Arial", 12)
        self._font_title = pygame.font.SysFont("Arial", 14, bold=True)
        self._font_kpi   = pygame.font.SysFont("Arial", 20, bold=True)

    # ── Control ───────────────────────────────────────────────────────────────

    def open(self, obj: dict, factory=None) -> None:
        self._obj     = obj
        self._factory = factory
        self._open    = True

    def close(self) -> None:
        self._open = False
        self._obj  = None

    @property
    def is_open(self) -> bool:
        return self._open

    # ── Draw ──────────────────────────────────────────────────────────────────

    def draw(self) -> None:
        if not self._open or not self._obj:
            return

        sw = self.screen.get_width()
        panel_x = sw - PANEL_W
        surf = pygame.Surface((PANEL_W, self.sh), pygame.SRCALPHA)
        surf.fill(C_PANEL)
        pygame.draw.line(surf, (0, 0, 0), (0, 0), (0, self.sh), 1)

        y = 0
        y = self._draw_header(surf, y)

        obj = self._obj
        if "station_id" in obj:
            y = self._draw_station(surf, y)
        elif "role" in obj:
            y = self._draw_npc(surf, y)
        else:
            y = self._draw_generic(surf, y)

        self.screen.blit(surf, (panel_x, 0))

    def _draw_header(self, surf: pygame.Surface, y: int) -> int:
        obj = self._obj
        # Eyebrow
        eyebrow = obj.get("zone", obj.get("kind", "OBJECT")).upper()
        surf.blit(self._font_mono.render(eyebrow, True, C_DIM), (18, y + 14))
        # Title
        surf.blit(self._font_title.render(obj.get("label", ""), True, C_GOLD), (18, y + 28))
        # Divider
        pygame.draw.line(surf, (0, 0, 0), (0, y + 50), (PANEL_W, y + 50), 1)
        return y + 58

    def _draw_station(self, surf: pygame.Surface, y: int) -> int:
        obj     = self._obj
        factory = self._factory
        st      = factory.stations.get(obj["station_id"]) if factory else None

        # 2×2 KPI grid
        oee     = f"{st.oee * 100:.1f}%" if st else "—"
        avail   = f"{st.availability * 100:.1f}%" if st else "—"
        perf    = f"{st.performance * 100:.1f}%" if st else "—"
        qual    = f"{st.quality * 100:.1f}%" if st else "—"
        wip_in  = str(st.wip_in) if st else "—"
        ops_cnt = str(len(st.operators)) if st else str(obj.get("ops", "—"))
        status  = obj.get("status", "run")
        status_color = _status_color(status)

        kpis = [
            ("OEE",        oee,    None),
            ("AVAIL",      avail,  None),
            ("PERFORMANCE",perf,   None),
            ("QUALITY",    qual,   None),
            ("WIP IN",     wip_in, None),
            ("OPERATORS",  ops_cnt,None),
        ]
        for i, (k, v, _) in enumerate(kpis):
            col = i % 2
            row = i // 2
            kx = 18 + col * 155
            ky = y + row * 48
            surf.blit(self._font_mono.render(k, True, C_DIM), (kx, ky))
            surf.blit(self._font_kpi.render(v, True, C_PANEL_INK), (kx, ky + 14))

        y += len(kpis) // 2 * 48 + 12
        pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
        y += 10

        # Status badge
        badge_surf = self._font_mono.render(f"● {status.upper()}", True, status_color)
        surf.blit(badge_surf, (18, y))
        y += 20

        # Details
        details = [
            ("Station ID", obj.get("id", "—")),
            ("Zone",       obj.get("zone", "—")),
            ("Cycle Time", f"{obj.get('ct', '—')} s (target)"),
        ]
        for k, v in details:
            surf.blit(self._font_mono.render(k, True, C_DIM), (18, y))
            surf.blit(self._font_body.render(v, True, C_PANEL_INK), (130, y))
            y += 18

        return y

    def _draw_npc(self, surf: pygame.Surface, y: int) -> int:
        obj  = self._obj
        role = obj.get("role", "")

        surf.blit(self._font_mono.render("ROLE", True, C_DIM), (18, y))
        surf.blit(self._font_body.render(role, True, C_PANEL_INK), (18, y + 14))
        y += 38

        line = NPC_LINES.get(role, "No comment.")
        # Word-wrap line
        words = line.split()
        lines_out, current = [], ""
        for w in words:
            test = current + (" " if current else "") + w
            if self._font_body.size(test)[0] > PANEL_W - 36:
                lines_out.append(current)
                current = w
            else:
                current = test
        if current:
            lines_out.append(current)

        surf.blit(self._font_mono.render("TALK", True, C_DIM), (18, y))
        y += 14
        for line_txt in lines_out:
            surf.blit(self._font_body.render(line_txt, True, C_PANEL_INK), (18, y))
            y += 16
        return y + 8

    def _draw_generic(self, surf: pygame.Surface, y: int) -> int:
        obj = self._obj
        details = [
            ("ID",       obj.get("id", "—")),
            ("Kind",     obj.get("kind", "—")),
        ]
        for k, v in details:
            surf.blit(self._font_mono.render(k, True, C_DIM), (18, y))
            surf.blit(self._font_body.render(v, True, C_PANEL_INK), (130, y))
            y += 18

        placeholder = "Detailed inspector panel arrives in a later iteration."
        words = placeholder.split()
        lines_out, current = [], ""
        for w in words:
            test = current + (" " if current else "") + w
            if self._font_body.size(test)[0] > PANEL_W - 36:
                lines_out.append(current)
                current = w
            else:
                current = test
        if current:
            lines_out.append(current)

        y += 8
        for line_txt in lines_out:
            surf.blit(self._font_body.render(line_txt, True, C_DIM), (18, y))
            y += 16
        return y
