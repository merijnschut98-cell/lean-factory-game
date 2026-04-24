"""
Inspector panel — right-side overlay shown when player interacts with an object.

Control logic only. All rendering methods live in ui.inspector_drawing (InspectorDrawMixin).
"""
from __future__ import annotations

from typing import Optional

import pygame

from problems.problem import ProblemState
from ui.inspector_drawing import (
    InspectorDrawMixin, C_PANEL, PANEL_W, _PANEL_SURF_H,
)


class Inspector(InspectorDrawMixin):

    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self.sh     = screen.get_height()
        self._open  = False
        self._obj: Optional[dict] = None
        self._factory = None
        self._scroll_y    = 0
        self._content_h   = 0
        self._panel_surf  = pygame.Surface((PANEL_W, _PANEL_SURF_H), pygame.SRCALPHA)
        # (problem_id, cm_category, days_active) → InvestigationFork; invalidated on close
        self._vfork_cache: dict = {}
        self._pending_action:  Optional[dict] = None
        self._revealed_choice: Optional[dict] = None

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_mono  = f["mono"]
        self._font_body  = f["body"]
        self._font_title = f["title"]
        self._font_kpi   = f["kpi"]

    # ── Control ───────────────────────────────────────────────────────────────

    def open(self, obj: dict, factory=None) -> None:
        self._obj     = obj
        self._factory = factory
        self._open    = True
        self._scroll_y        = 0
        self._pending_action  = None
        self._revealed_choice = None
        if factory and obj.get("station_id"):
            st = factory.stations.get(obj["station_id"])
            if st:
                factory.log_inspection(f"{st.zone_id}:{obj['station_id']}", "oee")

    def close(self) -> None:
        self._open = False
        self._obj  = None
        self._vfork_cache.clear()

    @property
    def is_open(self) -> bool:
        return self._open

    def consume_action(self) -> Optional[dict]:
        action = self._pending_action
        self._pending_action = None
        return action

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type == pygame.MOUSEWHEEL:
            max_scroll = max(0, self._content_h - self.sh + 20)
            self._scroll_y = max(0, min(max_scroll, self._scroll_y - event.y * 28))
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_UP:
                self._scroll_y = max(0, self._scroll_y - 28)
            elif event.key == pygame.K_DOWN:
                max_scroll = max(0, self._content_h - self.sh + 20)
                self._scroll_y = min(max_scroll, self._scroll_y + 28)

    def handle_action_key(self, key: int) -> None:
        if not self._open or not self._obj or not self._factory:
            return
        factory    = self._factory
        station_id = self._obj.get("station_id")

        if self._revealed_choice and key == pygame.K_RETURN:
            self._revealed_choice = None
            return

        if not station_id:
            return

        problems = [p for p in factory.active_problems.values()
                    if p.station_id == station_id]

        if key == pygame.K_c:
            active = [p for p in problems if p.state == ProblemState.ACTIVE]
            if active:
                self._pending_action = {"type": "apply_cm", "problem_id": active[0].id}

        elif key == pygame.K_r:
            applied = [p for p in problems if p.state == ProblemState.COUNTERMEASURE_APPLIED]
            if applied:
                self._pending_action = {"type": "resolve", "problem_id": applied[0].id}

        elif key == pygame.K_u:
            applied = [p for p in problems if p.state == ProblemState.COUNTERMEASURE_APPLIED]
            if applied:
                self._pending_action = {"type": "rollback", "problem_id": applied[0].id}

        elif key == pygame.K_s:
            for prob in problems:
                session = factory.investigation_sessions.get(prob.id)
                if (session and session.verification_complete
                        and session.verification_correct and not session.standardized):
                    self._pending_action = {"type": "standardize", "problem_id": prob.id}
                    break

        elif key == pygame.K_a:
            for prob in problems:
                session = factory.investigation_sessions.get(prob.id)
                if (session and session.verification_complete
                        and not session.verification_correct and not session.standardized):
                    self._pending_action = {"type": "adjust", "problem_id": prob.id}
                    break

        elif key in (pygame.K_1, pygame.K_2, pygame.K_3):
            choice_index = key - pygame.K_1
            for prob in problems:
                if not prob.dialogue:
                    continue
                session   = factory.investigation_sessions.get(prob.id)
                fork      = prob.dialogue.investigation
                five_whys = prob.dialogue.five_whys

                if (fork and session and session.fork_complete and
                        five_whys and not session.five_whys_complete):
                    step = five_whys[session.five_whys_step]
                    if choice_index < len(step.choices):
                        self._pending_action = {
                            "type":         "five_whys_choice",
                            "problem_id":   prob.id,
                            "choice_index": choice_index,
                        }
                    break

                cm_rec = factory.active_countermeasures.get(prob.applied_countermeasure or "")
                if (session and session.fork_complete
                        and self._should_show_verification(prob, session, cm_rec, factory)):
                    vfork = self._get_verification_fork(prob, cm_rec, factory)
                    if vfork and choice_index < len(vfork.choices):
                        self._pending_action = {
                            "type":         "verification_choice",
                            "problem_id":   prob.id,
                            "choice_index": choice_index,
                        }
                    break

                if fork and (session is None or not session.fork_complete):
                    if choice_index < len(fork.choices):
                        self._pending_action = {
                            "type":         "dialogue_choice",
                            "problem_id":   prob.id,
                            "choice_index": choice_index,
                        }
                    break

        elif key == pygame.K_h:
            st = factory.stations.get(station_id)
            if st:
                self._pending_action = {"type": "hire_specialist", "zone_id": st.zone_id}

    # ── Draw ──────────────────────────────────────────────────────────────────

    def draw(self) -> None:
        if not self._open or not self._obj:
            return

        surf = self._panel_surf
        surf.fill((0, 0, 0, 0))
        surf.fill(C_PANEL)
        pygame.draw.line(surf, (0, 0, 0), (0, 0), (0, _PANEL_SURF_H), 1)

        y = 0
        y = self._draw_header(surf, y)

        obj = self._obj
        if "station_id" in obj:
            y = self._draw_station(surf, y)
        elif "role" in obj:
            y = self._draw_npc(surf, y)
        else:
            y = self._draw_generic(surf, y)

        if "station_id" in obj and self._factory:
            y = self._draw_specialist(surf, y)

        self._content_h = y + 10

        sw      = self.screen.get_width()
        panel_x = sw - PANEL_W

        max_scroll     = max(0, self._content_h - self.sh + 20)
        self._scroll_y = min(self._scroll_y, max_scroll)

        src_rect = pygame.Rect(0, self._scroll_y, PANEL_W, self.sh)
        self.screen.blit(surf, (panel_x, 0), src_rect)

        if self._content_h > self.sh:
            track_h = self.sh - 8
            thumb_h = max(24, int(track_h * self.sh / self._content_h))
            thumb_y = 4 + int((self._scroll_y / max(1, max_scroll)) * (track_h - thumb_h))
            pygame.draw.rect(self.screen, (60, 58, 48),
                             (panel_x + PANEL_W - 5, 4, 3, track_h), border_radius=2)
            pygame.draw.rect(self.screen, (140, 130, 100),
                             (panel_x + PANEL_W - 5, thumb_y, 3, thumb_h), border_radius=2)
