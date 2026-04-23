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

from problems.dialogue import ChoiceOutcome, build_verification_fork
from problems.problem import ProblemState
from ui.micro_lessons import MICRO_LESSONS
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


_DEFAULT_DEBRIEF = (
    "Good work. The cluster is closed for now — keep an eye on it as conditions change."
)

_MISSION_DEBRIEFS = {
    "M-T1-001": (
        "That's exactly what I was hoping for. The waste was there all along — "
        "it just needed someone to stop and look. Zone 2 already feels different. "
        "Let's keep the discipline."
    ),
    "M-T1-002": (
        "FTR is moving. I've been watching that number for months. "
        "What you found was upstream of where we were looking — that's the lesson. "
        "Don't trust the defect location; trust the root cause."
    ),
    "M-T1-003": (
        "The schedule is responding now. WIP isn't piling the way it was. "
        "Maya says the dock is smoother. I think you've found the lever — "
        "now we just have to hold it."
    ),
    "M-T1-004": (
        "We won't fully know the impact until the next time that operator is out. "
        "But the knowledge is out of one person's head and into the system now. "
        "That's a real improvement in resilience."
    ),
    "M-T1-005": (
        "The numbers are starting to agree with each other again. "
        "Priya says the gap between MES and the floor is closing. "
        "Trust in data is slow to build and fast to destroy — you've started rebuilding it."
    ),
}


_PANEL_SURF_H = 2400   # tall enough for any inspector content

_WRONG_CM_TIPS = {
    1: "Floor Manager: That CM tier doesn't match this problem — check the zone maturity.",
    2: "Floor Manager: Another mismatch. Credits penalty will apply on resolve.",
    3: "Floor Manager: Third wrong CM. Score will be reduced — consider rolling back.",
}


class Inspector:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen = screen
        self.sh     = screen.get_height()
        self._open  = False
        self._obj: Optional[dict] = None
        self._factory = None
        self._scroll_y    = 0
        self._content_h   = 0
        self._panel_surf  = pygame.Surface((PANEL_W, _PANEL_SURF_H), pygame.SRCALPHA)
        # Cache: (problem_id, cm_category, days_active) → InvestigationFork
        self._vfork_cache: dict = {}

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
        self._scroll_y  = 0
        self._pending_action: Optional[dict] = None
        self._revealed_choice: Optional[dict] = None  # {problem_id, choice} shown after pick
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
        """Returns and clears a pending action dict, e.g. {type:'apply_cm', problem_id:...}."""
        action = self._pending_action
        self._pending_action = None
        return action

    def handle_event(self, event: pygame.event.Event) -> None:
        """Handle scroll events (mouse wheel and keyboard) when inspector is open."""
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

        elif key == pygame.K_u:
            applied = [p for p in problems
                       if p.state == ProblemState.COUNTERMEASURE_APPLIED]
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
            choice_index = key - pygame.K_1   # 0, 1, or 2
            for prob in problems:
                if not prob.dialogue:
                    continue
                session   = factory.investigation_sessions.get(prob.id)
                fork      = prob.dialogue.investigation
                five_whys = prob.dialogue.five_whys

                # Active 5 Whys step
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

                # Active verification fork (PDCA Check)
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

                # Active investigation fork
                if fork and (session is None or not session.fork_complete):
                    if choice_index < len(fork.choices):
                        self._pending_action = {
                            "type":         "dialogue_choice",
                            "problem_id":   prob.id,
                            "choice_index": choice_index,
                        }
                    break

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

        self._content_h = y + 10

        sw = self.screen.get_width()
        panel_x = sw - PANEL_W

        # Clamp scroll
        max_scroll = max(0, self._content_h - self.sh + 20)
        self._scroll_y = min(self._scroll_y, max_scroll)

        # Blit a window of the tall surface to the screen
        src_rect = pygame.Rect(0, self._scroll_y, PANEL_W, self.sh)
        self.screen.blit(surf, (panel_x, 0), src_rect)

        # Scroll indicator (draw directly on screen, not on surf)
        if self._content_h > self.sh:
            track_h = self.sh - 8
            thumb_h = max(24, int(track_h * self.sh / self._content_h))
            thumb_y = 4 + int((self._scroll_y / max(1, max_scroll)) * (track_h - thumb_h))
            pygame.draw.rect(self.screen, (60, 58, 48),
                             (panel_x + PANEL_W - 5, 4, 3, track_h), border_radius=2)
            pygame.draw.rect(self.screen, (140, 130, 100),
                             (panel_x + PANEL_W - 5, thumb_y, 3, thumb_h), border_radius=2)

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
            surf.blit(self._font_mono.render("[C]  Apply Countermeasure", True, C_GOLD), (18, y))
            y += 16
        elif prob.state == ProblemState.COUNTERMEASURE_APPLIED:
            surf.blit(self._font_mono.render("[R]  Resolve & Score", True, (111, 211, 111)), (18, y))
            y += 16
            surf.blit(self._font_mono.render("[U]  Rollback CM  (-25% credits)", True, (200, 120, 60)), (18, y))
            y += 16

        # Soft-punishment tip after wrong CM applications
        if self._factory:
            session = self._factory.investigation_sessions.get(prob.id)
            if session and session.wrong_cm_count > 0:
                tip = _WRONG_CM_TIPS.get(session.wrong_cm_count, _WRONG_CM_TIPS[3])
                y += 4
                for ln in wrap_text(tip, self._font_body, PANEL_W - 36)[:2]:
                    surf.blit(self._font_body.render(ln, True, C_WAITING), (18, y))
                    y += 15

        # Dialogue fork section
        if self._factory and prob.dialogue and prob.dialogue.investigation:
            y = self._draw_dialogue_fork(surf, y, prob)

        y += 6
        return y

    def _get_verification_fork(self, prob, cm_rec, factory):
        """Return cached verification fork; rebuild only when CM/days changes."""
        cm = factory.cm_catalog.get(prob.applied_countermeasure)
        if not cm:
            return None
        fork = prob.dialogue.investigation if prob.dialogue else None
        npc  = fork.npc if fork else "Team Leader"
        days = factory.time.day - cm_rec["applied_day"]
        key  = (prob.id, cm.category, days)
        if key not in self._vfork_cache:
            self._vfork_cache[key] = build_verification_fork(npc, cm.category, cm.name, days)
        return self._vfork_cache[key]

    @staticmethod
    def _should_show_verification(prob, session, cm_rec, factory) -> bool:
        five_whys = prob.dialogue.five_whys if prob.dialogue else []
        five_whys_done = not five_whys or session.five_whys_complete
        return (
            five_whys_done
            and prob.state == ProblemState.COUNTERMEASURE_APPLIED
            and cm_rec is not None
            and factory.time.day - cm_rec.get("applied_day", factory.time.day) >= 3
            and not session.verification_complete
        )

    def _draw_dialogue_fork(self, surf: pygame.Surface, y: int, prob) -> int:
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

            # Micro-lesson for the first newly discovered concept
            new_concepts = self._revealed_choice.get("new_concepts") or set()
            lesson_concept = next(
                (c for c in (choice.teaches or []) if c in new_concepts and c in MICRO_LESSONS),
                None,
            )
            if lesson_concept:
                y += 6
                pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
                y += 8
                surf.blit(self._font_mono.render(
                    f"CONCEPT: {lesson_concept.upper().replace('_', ' ')}", True, C_GOLD), (18, y))
                y += 14
                for ln in wrap_text(MICRO_LESSONS[lesson_concept], self._font_body, PANEL_W - 36):
                    surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
                    y += 15

            surf.blit(self._font_mono.render("[Enter]  Continue", True, C_GOLD), (18, y))
            y += 18
            return y

        # Completed fork — show 5 Whys drill or completion summary
        if session and session.fork_complete:
            five_whys = prob.dialogue.five_whys if prob.dialogue else []

            if five_whys and not session.five_whys_complete:
                step      = five_whys[session.five_whys_step]
                step_num  = session.five_whys_step + 1
                total     = len(five_whys)
                surf.blit(self._font_mono.render(
                    f"5 WHYS  —  STEP {step_num} / {total}", True, C_GOLD), (18, y))
                y += 18
                for ln in wrap_text(step.why, self._font_body, PANEL_W - 36)[:3]:
                    surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
                    y += 16
                y += 4
                for i, choice in enumerate(step.choices[:3]):
                    surf.blit(self._font_mono.render(f"[{i + 1}]", True, C_GOLD), (18, y))
                    for ln in wrap_text(choice.text, self._font_body, PANEL_W - 56)[:2]:
                        surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (44, y))
                        y += 16
                    y += 2
                return y

            # Verification fork (PDCA Check) — shown after investigation + optional 5 Whys
            cm_rec = factory.active_countermeasures.get(prob.applied_countermeasure or "")
            if self._should_show_verification(prob, session, cm_rec, factory):
                vfork = self._get_verification_fork(prob, cm_rec, factory)
                if vfork:
                    surf.blit(self._font_mono.render(
                        "PDCA  —  CHECK", True, (111, 211, 111)), (18, y))
                    y += 18
                    surf.blit(self._font_mono.render(
                        f"[ {vfork.npc} ]", True, C_GOLD), (18, y))
                    y += 16
                    for ln in wrap_text(vfork.prompt, self._font_body, PANEL_W - 36)[:2]:
                        surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
                        y += 16
                    y += 4
                    for i, choice in enumerate(vfork.choices[:3]):
                        surf.blit(self._font_mono.render(f"[{i + 1}]", True, C_GOLD), (18, y))
                        for ln in wrap_text(choice.text, self._font_body, PANEL_W - 56)[:2]:
                            surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (44, y))
                            y += 16
                        y += 2
                    return y

            surf.blit(self._font_mono.render(
                "✓ INVESTIGATION COMPLETE", True, (111, 211, 111)), (18, y))
            y += 16
            if session.five_whys_complete:
                surf.blit(self._font_mono.render(
                    "✓ ROOT CAUSE IDENTIFIED", True, (111, 211, 111)), (18, y))
                y += 16
            if session.verification_complete:
                surf.blit(self._font_mono.render(
                    "✓ EFFECT VERIFIED", True, (111, 211, 111)), (18, y))
                y += 16
                if session.standardized:
                    surf.blit(self._font_mono.render(
                        "✓ STANDARDIZED  (+15% bonus on resolve)", True, (111, 211, 111)), (18, y))
                    y += 16
                elif session.verification_correct:
                    surf.blit(self._font_mono.render(
                        "[S]  Standardize — lock benefit, disable decay", True, C_GOLD), (18, y))
                    y += 16
                else:
                    surf.blit(self._font_mono.render(
                        "[A]  Adjust — observe again", True, C_WAITING), (18, y))
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

        # Mission briefing: shown whenever this NPC's mission is active
        if self._factory:
            # Completed mission debriefing — shown after player resolves the mission cluster
            completed = next(
                (m for m in self._factory.missions.values()
                 if m.source_npc == role and m.completed),
                None,
            )
            if completed:
                y += 8
                pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
                y += 10
                surf.blit(self._font_mono.render("MISSION COMPLETE", True, (111, 211, 111)), (18, y))
                y += 14
                surf.blit(self._font_title.render(completed.title, True, C_GOLD), (18, y))
                y += 22
                debrief = _MISSION_DEBRIEFS.get(completed.id, _DEFAULT_DEBRIEF)
                for line_txt in wrap_text(debrief, self._font_body, PANEL_W - 36):
                    surf.blit(self._font_body.render(line_txt, True, C_PANEL_INK), (18, y))
                    y += 16

            # Active mission briefing — shown while mission is running
            mission = next(
                (m for m in self._factory.missions.values()
                 if m.source_npc == role and m.active and not m.completed),
                None,
            )
            if mission:
                y += 8
                pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
                y += 10
                surf.blit(self._font_mono.render("ACTIVE MISSION", True, C_GOLD), (18, y))
                y += 14
                surf.blit(self._font_title.render(mission.title, True, C_GOLD), (18, y))
                y += 22
                for line_txt in wrap_text(mission.description.strip(), self._font_body, PANEL_W - 36):
                    surf.blit(self._font_body.render(line_txt, True, C_PANEL_INK), (18, y))
                    y += 16
                if mission.current_hint:
                    y += 4
                    surf.blit(self._font_mono.render("HINT", True, C_DIM), (18, y))
                    y += 14
                    for line_txt in wrap_text(mission.current_hint, self._font_body, PANEL_W - 36):
                        surf.blit(self._font_body.render(line_txt, True, C_DIM), (18, y))
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
        y += 8
        for line_txt in wrap_text(placeholder, self._font_body, PANEL_W - 36):
            surf.blit(self._font_body.render(line_txt, True, C_DIM), (18, y))
            y += 16
        return y
