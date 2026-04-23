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

from ui.text_utils import wrap_text

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
        self._pending_action: Optional[dict] = None
        self._revealed_choice: Optional[dict] = None  # {problem_id, choice} shown after pick
        if factory and obj.get("station_id"):
            st = factory.stations.get(obj["station_id"])
            if st:
                factory.log_inspection(f"{st.zone_id}:{obj['station_id']}", "oee")

    def close(self) -> None:
        self._open = False
        self._obj  = None

    @property
    def is_open(self) -> bool:
        return self._open

    def consume_action(self) -> Optional[dict]:
        """Returns and clears a pending action dict, e.g. {type:'apply_cm', problem_id:...}."""
        action = self._pending_action
        self._pending_action = None
        return action

    def handle_action_key(self, key: int) -> None:
        """Called by game loop for keys that are inspector-specific actions."""
        if not self._open or not self._obj or not self._factory:
            return
        factory = self._factory
        station_id = self._obj.get("station_id")

        # Acknowledge a revealed dialogue choice result
        if self._revealed_choice and key == pygame.K_RETURN:
            self._revealed_choice = None
            return

        if not station_id:
            return

        from problems.problem import ProblemState
        problems = [p for p in factory.active_problems.values()
                    if p.station_id == station_id]

        if key == pygame.K_c:
            active = [p for p in problems if p.state == ProblemState.ACTIVE]
            if active:
                self._pending_action = {"type": "apply_cm", "problem_id": active[0].id}

        elif key == pygame.K_r:
            applied = [p for p in problems
                       if p.state == ProblemState.COUNTERMEASURE_APPLIED]
            if applied:
                self._pending_action = {"type": "resolve", "problem_id": applied[0].id}

        elif key in (pygame.K_1, pygame.K_2, pygame.K_3):
            choice_index = key - pygame.K_1   # 0, 1, or 2
            # Find the first active problem at this station with an open fork
            for prob in problems:
                session = factory.investigation_sessions.get(prob.id)
                fork = prob.dialogue.investigation if prob.dialogue else None
                if fork and (session is None or not session.fork_complete):
                    if choice_index < len(fork.choices):
                        self._pending_action = {
                            "type":        "dialogue_choice",
                            "problem_id":  prob.id,
                            "choice_index": choice_index,
                        }
                    break

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

        oee     = f"{st.oee * 100:.1f}%" if st else "—"
        avail   = f"{st.availability * 100:.1f}%" if st else "—"
        perf    = f"{st.performance * 100:.1f}%" if st else "—"
        qual    = f"{st.quality * 100:.1f}%" if st else "—"
        wip_in  = str(st.wip_in) if st else "—"
        ops_cnt = str(len(st.operators)) if st else str(obj.get("ops", "—"))
        status  = obj.get("status", "run")

        kpis = [
            ("OEE",        oee),
            ("AVAIL",      avail),
            ("PERFORMANCE",perf),
            ("QUALITY",    qual),
            ("WIP IN",     wip_in),
            ("OPERATORS",  ops_cnt),
        ]
        for i, (k, v) in enumerate(kpis):
            col = i % 2
            row = i // 2
            kx = 18 + col * 155
            ky = y + row * 48
            surf.blit(self._font_mono.render(k, True, C_DIM), (kx, ky))
            surf.blit(self._font_kpi.render(v, True, C_PANEL_INK), (kx, ky + 14))

        y += len(kpis) // 2 * 48 + 12
        pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
        y += 10

        surf.blit(self._font_mono.render(f"● {status.upper()}", True, _status_color(status)), (18, y))
        y += 20

        for k, v in [
            ("Station ID", obj.get("id", "—")),
            ("Zone",       obj.get("zone", "—")),
            ("Cycle Time", f"{obj.get('ct', '—')} s (target)"),
        ]:
            surf.blit(self._font_mono.render(k, True, C_DIM), (18, y))
            surf.blit(self._font_body.render(v, True, C_PANEL_INK), (130, y))
            y += 18

        # Active problems panel
        if factory:
            problems = [
                p for p in factory.active_problems.values()
                if p.station_id == obj.get("station_id")
            ]
            if problems:
                y += 8
                pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
                y += 8
                surf.blit(self._font_mono.render("ACTIVE PROBLEMS", True, (220, 80, 80)), (18, y))
                y += 16
                for prob in problems:
                    y = self._draw_problem_card(surf, y, prob)

        # Time Observation diagnostic
        if st and st.ct_history:
            y += 8
            pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
            y += 8
            surf.blit(self._font_mono.render("TIME OBSERVATION", True, C_DIM), (18, y))
            y += 14
            y = self._draw_ct_history(surf, y, st)

        # Gemba walk log (last 5 inspections in this session)
        if factory and factory.inspection_log:
            y += 8
            pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
            y += 8
            surf.blit(self._font_mono.render("GEMBA LOG", True, C_DIM), (18, y))
            y += 14
            recent = factory.recent_inspections(5)
            for entry in reversed(recent):
                entity = entry["entity"].split(":")[-1]  # show station id only
                day = entry.get("day", "—")
                txt = f"Day {day}  {entity}"
                surf.blit(self._font_body.render(txt, True, C_DIM), (18, y))
                y += 14

        return y

    def _draw_problem_card(self, surf: pygame.Surface, y: int, prob) -> int:
        """Problem card: severity badge, name, first symptom, state + action hint."""
        from problems.problem import ProblemState

        sev_colors = {
            "critical": (220, 50, 50),
            "high":     (220, 120, 50),
            "medium":   (220, 180, 50),
            "low":      (180, 180, 50),
        }
        sev_color = sev_colors.get(prob.severity, C_DIM)
        surf.blit(self._font_mono.render(f"[{prob.severity.upper()}]", True, sev_color), (18, y))

        state_labels = {
            ProblemState.ACTIVE:                 ("ACTIVE",     (220, 180, 50)),
            ProblemState.UNDER_INVESTIGATION:    ("DIAGNOSING", (255, 214, 131)),
            ProblemState.COUNTERMEASURE_APPLIED: ("CM APPLIED", (111, 211, 111)),
            ProblemState.RESOLVED:               ("RESOLVED",   (111, 211, 111)),
        }
        state_lbl, state_col = state_labels.get(prob.state, ("UNKNOWN", C_DIM))
        surf.blit(self._font_mono.render(state_lbl, True, state_col), (PANEL_W - 90, y))
        y += 14

        surf.blit(self._font_body.render(prob.name, True, C_PANEL_INK), (18, y))
        y += 16

        if prob.symptoms:
            for ln in wrap_text(prob.symptoms[0], self._font_body, PANEL_W - 36)[:2]:
                surf.blit(self._font_body.render(ln, True, C_DIM), (18, y))
                y += 15

        # Action hint
        if prob.state == ProblemState.ACTIVE:
            hint = "[C]  Apply Countermeasure"
            surf.blit(self._font_mono.render(hint, True, C_GOLD), (18, y))
            y += 16
        elif prob.state == ProblemState.COUNTERMEASURE_APPLIED:
            hint = "[R]  Resolve & Score"
            surf.blit(self._font_mono.render(hint, True, (111, 211, 111)), (18, y))
            y += 16

        # Dialogue fork section
        if self._factory and prob.dialogue and prob.dialogue.investigation:
            y = self._draw_dialogue_fork(surf, y, prob)

        y += 6
        return y

    def _draw_dialogue_fork(self, surf: pygame.Surface, y: int, prob) -> int:
        from problems.dialogue import ChoiceOutcome
        factory = self._factory
        fork    = prob.dialogue.investigation
        session = factory.investigation_sessions.get(prob.id)

        pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
        y += 8

        # Revealed-choice panel (shown after player makes a pick)
        if (self._revealed_choice and
                self._revealed_choice.get("problem_id") == prob.id):
            choice = self._revealed_choice["choice"]
            outcome_colors = {
                ChoiceOutcome.CORRECT:  (111, 211, 111),
                ChoiceOutcome.PLAUSIBLE:(255, 214, 131),
                ChoiceOutcome.WRONG:    (232, 96,  74),
            }
            o_color = outcome_colors.get(choice.outcome, C_DIM)
            surf.blit(self._font_mono.render(
                choice.outcome.value, True, o_color), (18, y))
            y += 18
            if choice.evidence:
                for ln in wrap_text(choice.evidence, self._font_body, PANEL_W - 36)[:3]:
                    surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
                    y += 16
            y += 4
            for ln in wrap_text(choice.hint, self._font_body, PANEL_W - 36)[:3]:
                surf.blit(self._font_body.render(ln, True, C_DIM), (18, y))
                y += 16
            surf.blit(self._font_mono.render("[Enter]  Continue", True, C_GOLD), (18, y))
            y += 18
            return y

        # Completed fork summary
        if session and session.fork_complete:
            surf.blit(self._font_mono.render(
                "✓ INVESTIGATION COMPLETE", True, (111, 211, 111)), (18, y))
            y += 16
            if session.earned_rally_bonus:
                surf.blit(self._font_body.render(
                    "+10% credit bonus (Learning Rally)", True, (255, 214, 131)), (18, y))
                y += 16
            return y

        # Fork prompt + choices
        npc_header = f"[ {fork.npc} ]"
        surf.blit(self._font_mono.render(npc_header, True, C_GOLD), (18, y))
        y += 18
        for ln in wrap_text(fork.prompt, self._font_body, PANEL_W - 36)[:3]:
            surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
            y += 16
        y += 4
        for i, choice in enumerate(fork.choices[:3]):
            key_lbl = f"[{i + 1}]"
            surf.blit(self._font_mono.render(key_lbl, True, C_GOLD), (18, y))
            for ln in wrap_text(choice.text, self._font_body, PANEL_W - 56)[:2]:
                surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (44, y))
                y += 16
            y += 2
        return y

    def _draw_ct_history(self, surf: pygame.Surface, y: int, st) -> int:
        """Mini bar chart of the last 8 observed cycle times vs. target."""
        history = st.ct_history[-8:]
        target = st.target_cycle_time
        avg = sum(history) / len(history) if history else target

        avg_txt = f"avg {avg:.0f}s  target {target:.0f}s"
        surf.blit(self._font_body.render(avg_txt, True, C_DIM), (18, y))
        y += 14

        bar_w = int((PANEL_W - 36) / max(len(history), 1))
        max_ct = (max(max(history), target) if history else target) * 1.2
        bar_area_h = 28

        for i, ct in enumerate(history):
            bx = 18 + i * bar_w
            bar_h = int((ct / max_ct) * bar_area_h)
            color = C_RUNNING if ct <= target else C_BLOCKED
            pygame.draw.rect(surf, color, (bx, y + bar_area_h - bar_h, bar_w - 2, bar_h))

        # Target line
        target_y = y + bar_area_h - int((target / max_ct) * bar_area_h)
        pygame.draw.line(surf, C_GOLD, (18, target_y), (PANEL_W - 18, target_y), 1)

        return y + bar_area_h + 4

    def _draw_npc(self, surf: pygame.Surface, y: int) -> int:
        obj  = self._obj
        role = obj.get("role", "")

        surf.blit(self._font_mono.render("ROLE", True, C_DIM), (18, y))
        surf.blit(self._font_body.render(role, True, C_PANEL_INK), (18, y + 14))
        y += 38

        surf.blit(self._font_mono.render("TALK", True, C_DIM), (18, y))
        y += 14
        for line_txt in wrap_text(NPC_LINES.get(role, "No comment."), self._font_body, PANEL_W - 36):
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
