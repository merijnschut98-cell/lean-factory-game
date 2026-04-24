"""
InspectorDrawMixin — all rendering methods and content data for the inspector panel.

Separated from inspector.py (control/event logic) to keep each file focused.
Inspector inherits this mixin; no behaviour change.
"""
from __future__ import annotations

import pygame

from problems.dialogue import ChoiceOutcome, build_verification_fork
from problems.problem import ProblemState
from simulation.specialist import Specialist, ZONE_SPECIALIST, SPECIALIST_COST
from ui.micro_lessons import MICRO_LESSONS
from ui.text_utils import wrap_text

# ── Colours ───────────────────────────────────────────────────────────────────

C_PANEL      = (21, 20, 15, 240)
C_PANEL_INK  = (220, 215, 200)
C_GOLD       = (255, 214, 131)
C_DIM        = (140, 135, 120)
C_RUNNING    = (111, 211, 111)
C_WAITING    = (255, 184, 77)
C_BLOCKED    = (232, 96, 74)

PANEL_W = 340

# ── NPC static lines ──────────────────────────────────────────────────────────

NPC_LINES = {
    "Team Leader":          "Board's clean, but the numbers… don't ask.",
    "Scheduler":            "I'm trying to level the schedule. The dock disagrees.",
    "Quality Lead":         "FTR is 91.8%. That 8.2% keeps me up at night.",
    "IT Engineer":          "MES says one thing. The floor says another. I believe the floor.",
    "Controller":           "Cost of poor quality is real. Nobody tracks it properly.",
    "HR Manager":           "We have 24 operators. 1 of them carries the whole line.",
    "Maintenance Lead":     "Reactive maintenance is a tax. Nobody reads the invoice.",
    "Plant Manager (you)":  "Your plant. Your call. Walk the floor first.",
}

# ── Content dicts ─────────────────────────────────────────────────────────────

_PANEL_SURF_H = 2400   # tall enough for any inspector content

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
    "M-T2-001": (
        "Management was operating from reports. Now it's operating from observation. "
        "The floor looks the same — but decisions are arriving faster, closer to where "
        "the problem is. That's the difference."
    ),
    "M-T2-002": (
        "The signals are connected now. Quality stops get a response. "
        "Shift handovers transfer what matters. A factory that can't signal "
        "can't improve — and now this one can."
    ),
    "M-T2-003": (
        "Culture is the hardest thing to change and the one that lasts longest. "
        "People are reporting again. Ideas are being heard. "
        "That's not a process improvement — it's a change in what this place is."
    ),
    "M-T2-004": (
        "The improvements are holding now. That's not the same as just making them — "
        "it's harder, and it matters more. PDCA without Check and Act is just PD."
    ),
    "M-T2-005": (
        "Targets are aligned. Analysis is reaching systemic causes. "
        "When teams optimise for the same thing and investigations go deep enough, "
        "the same problems stop coming back."
    ),
    "M-T3-001": (
        "The flow is pulling now — not pushing. Units move when the next step needs them, "
        "not when the previous step finishes. That's not a small change. "
        "It changes how waste accumulates and where it's visible."
    ),
    "M-T3-002": (
        "Operators are at their stations. Material comes to them. "
        "The spaghetti diagram from three months ago would look completely different today. "
        "Motion and transport waste are the most invisible costs in a factory — "
        "until you draw the lines."
    ),
    "M-T3-003": (
        "Changeover is fast enough to level the schedule. "
        "The schedule is level enough to reduce WIP. "
        "WIP is low enough that quality feedback is immediate. "
        "Those three things connect."
    ),
    "M-T3-004": (
        "Quality at source. That's the phrase. Defects prevented where they form — "
        "not caught four stations later. The cost difference between detection and prevention "
        "is an order of magnitude. You've moved the line."
    ),
    "M-T4-001": (
        "The data can be trusted now. That sentence sounds simple — "
        "but every decision made before this was made on numbers that were telling "
        "the wrong story. Measurement system analysis isn't glamorous. "
        "It's foundational."
    ),
    "M-T4-002": (
        "Tools used correctly. PDCA running all four phases. "
        "SPC interpreted by people who understand what control limits mean. "
        "The difference between a tool and a method is whether the thinking comes with it."
    ),
    "M-T4-003": (
        "Risk is managed now — prospectively, not reactively. "
        "The FMEA updates when the process changes. The supplier changes are reviewed. "
        "Maintenance intervals follow failure patterns, not calendar habits. "
        "Prevention is invisible: the failures that didn't happen."
    ),
    "M-T4-004": (
        "The dominant factor was found. Not guessed, not debated — found. "
        "Data, structure, and the willingness to test combinations rather than assumptions. "
        "That's the difference between a year of experiments and a week of DOE."
    ),
}

# Ambient comments from NPCs near an active mission but not its source.
# Keyed by (npc_role, mission_id).
_NPC_AWARENESS: dict = {
    ("Team Leader", "M-T1-002"): (
        "Something's off in the integration area. Product comes through looking fine "
        "but it's going back for rework — twice on the same defect."
    ),
    ("Team Leader", "M-T1-003"): (
        "The dock flooded again. Third time this week. "
        "Then it'll be empty for three days and Component Prep will be guessing."
    ),
    ("Team Leader", "M-T1-001"): (
        "The area's not right. I can't put my finger on it, but it takes longer "
        "than it should to get anything done in there."
    ),
    ("Scheduler", "M-T1-001"): (
        "Input from Component Prep is unpredictable. "
        "I've tried leveling the schedule but I can't plan around this variance."
    ),
    ("Scheduler", "M-T1-002"): (
        "FTR issues are hitting our schedule — rework takes time we didn't plan for. "
        "The numbers say one thing; what I see on the floor says another."
    ),
    ("Quality Lead", "M-T1-003"): (
        "High WIP means quality problems have more places to hide. "
        "By the time a defect surfaces, it's already been in three stations."
    ),
    ("Quality Lead", "M-T1-004"): (
        "When the same operator isn't there, the output quality changes noticeably. "
        "That kind of variation shouldn't depend on a single person."
    ),
    ("IT Engineer", "M-T1-001"): (
        "Utilization data shows the prep area burning capacity on non-value activity. "
        "I can see it in the numbers but I can't tell you what it is from here."
    ),
    ("IT Engineer", "M-T1-003"): (
        "The WIP inventory counts don't match what the system expects. "
        "There's a buffer somewhere that isn't being tracked properly."
    ),
    ("Controller", "M-T1-002"): (
        "Cost of poor quality is ticking up. Rework labour isn't free — "
        "it just doesn't show up on the right line."
    ),
    ("Controller", "M-T1-003"): (
        "Working capital tied up in WIP is money sitting on the floor. "
        "Every unit in a queue is a unit that hasn't been sold yet."
    ),
    ("Controller", "M-T1-005"): (
        "The daily output report looks better than the floor. "
        "When the numbers and reality disagree, trust the floor."
    ),
    ("Quality Lead", "M-T2-001"): (
        "Management decisions are a week behind the floor. "
        "By the time a problem reaches the weekly report, we've already lived with it."
    ),
    ("Scheduler", "M-T2-002"): (
        "Shift handovers are losing context. I get different numbers from morning and night "
        "for the same production window. Someone isn't passing information."
    ),
    ("Team Leader", "M-T2-003"): (
        "Operators have stopped raising issues in the log. "
        "I don't know if it's the form or something else."
    ),
    ("HR Manager", "M-T2-004"): (
        "Improvement projects are closing on paper but I keep seeing the same problems "
        "come back in the satisfaction surveys. Something isn't holding."
    ),
    ("Quality Lead", "M-T2-005"): (
        "Throughput is up in one zone and quality is down in another. "
        "I don't think those two teams are talking to each other."
    ),
    ("Quality Lead", "M-T3-001"): (
        "WIP is accumulating in front of Integration 4 again. "
        "Every time we improve something upstream, it feeds the pile faster."
    ),
    ("Scheduler", "M-T3-002"): (
        "Operators are leaving stations to fetch materials. "
        "I can see it in the cycle time variance — it spikes when the bin runs out."
    ),
    ("Team Leader", "M-T3-003"): (
        "Changeover is consuming a significant chunk of available time. "
        "We're avoiding short runs because the setup cost isn't worth it."
    ),
    ("Quality Lead", "M-T3-004"): (
        "FTR is dropping again — and it's correlating with throughput improvement. "
        "Faster flow is surfacing quality gaps that the slower pace was hiding."
    ),
    ("Team Leader", "M-T4-001"): (
        "Final QA pass/fail feels inconsistent. Same product, different shift, "
        "different outcome. I've stopped fully trusting the inspection numbers."
    ),
    ("Scheduler", "M-T4-002"): (
        "DMAIC results looked great for a month. Now we're back to where we started. "
        "I don't understand what changed — or why it didn't hold."
    ),
    ("Quality Lead", "M-T4-003"): (
        "Battery Assembly defect rate hasn't recovered since the increase six months ago. "
        "Every investigation finds nothing. Something changed that nobody noticed."
    ),
    ("Team Leader", "M-T4-004"): (
        "Seven months of experiments and we still don't know what's driving "
        "Deck Cutting defects. Each factor looks fine individually. "
        "Combined, they fail."
    ),
}

_RECOVERY_ADVICE = {
    1: (
        "That countermeasure didn't land quite right — but that's information. "
        "Check the zone maturity: the CM tier needs to match where this zone actually is, "
        "not where you'd like it to be. Roll back if it's not helping."
    ),
    2: (
        "Two mismatches on the same problem. Before picking another CM, "
        "go back to the investigation fork and verify you've identified the real root cause. "
        "The wrong diagnosis leads to the wrong fix every time."
    ),
    3: (
        "Three attempts, none landing. Step back completely. "
        "Roll back the current CM, re-read the symptoms, and walk the station again. "
        "The answer is in the gemba — it's not in the catalog."
    ),
}

_WRONG_CM_TIPS = {
    1: "Floor Manager: That CM tier doesn't match this problem — check the zone maturity.",
    2: "Floor Manager: Another mismatch. Credits penalty will apply on resolve.",
    3: "Floor Manager: Third wrong CM. Score will be reduced — consider rolling back.",
}


def _status_color(status: str) -> tuple:
    return {"run": C_RUNNING, "wait": C_WAITING, "block": C_BLOCKED}.get(status, C_DIM)


# ── Draw mixin ────────────────────────────────────────────────────────────────

class InspectorDrawMixin:

    def _draw_header(self, surf: pygame.Surface, y: int) -> int:
        obj = self._obj
        eyebrow = obj.get("zone", obj.get("kind", "OBJECT")).upper()
        surf.blit(self._font_mono.render(eyebrow, True, C_DIM), (18, y + 14))
        surf.blit(self._font_title.render(obj.get("label", ""), True, C_GOLD), (18, y + 28))
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

        if st and st.ct_history:
            y += 8
            pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
            y += 8
            surf.blit(self._font_mono.render("TIME OBSERVATION", True, C_DIM), (18, y))
            y += 14
            y = self._draw_ct_history(surf, y, st)

        if factory and factory.inspection_log:
            y += 8
            pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
            y += 8
            surf.blit(self._font_mono.render("GEMBA LOG", True, C_DIM), (18, y))
            y += 14
            recent = factory.recent_inspections(5)
            for entry in reversed(recent):
                entity = entry["entity"].split(":")[-1]
                day = entry.get("day", "—")
                surf.blit(self._font_body.render(f"Day {day}  {entity}", True, C_DIM), (18, y))
                y += 14

        return y

    def _draw_problem_card(self, surf: pygame.Surface, y: int, prob) -> int:
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

        if prob.state == ProblemState.ACTIVE:
            surf.blit(self._font_mono.render("[C]  Apply Countermeasure", True, C_GOLD), (18, y))
            y += 16
        elif prob.state == ProblemState.COUNTERMEASURE_APPLIED:
            surf.blit(self._font_mono.render("[R]  Resolve & Score", True, (111, 211, 111)), (18, y))
            y += 16
            surf.blit(self._font_mono.render("[U]  Rollback CM  (-25% credits)", True, (200, 120, 60)), (18, y))
            y += 16

        if self._factory:
            session = self._factory.investigation_sessions.get(prob.id)
            if session and session.wrong_cm_count > 0:
                tip = _WRONG_CM_TIPS.get(session.wrong_cm_count, _WRONG_CM_TIPS[3])
                y += 4
                for ln in wrap_text(tip, self._font_body, PANEL_W - 36)[:2]:
                    surf.blit(self._font_body.render(ln, True, C_WAITING), (18, y))
                    y += 15

        if self._factory and prob.dialogue and prob.dialogue.investigation:
            y = self._draw_dialogue_fork(surf, y, prob)

        y += 6
        return y

    def _get_verification_fork(self, prob, cm_rec, factory):
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

        if (self._revealed_choice and
                self._revealed_choice.get("problem_id") == prob.id):
            choice = self._revealed_choice["choice"]
            outcome_colors = {
                ChoiceOutcome.CORRECT:  (111, 211, 111),
                ChoiceOutcome.PLAUSIBLE:(255, 214, 131),
                ChoiceOutcome.WRONG:    (232, 96,  74),
            }
            o_color = outcome_colors.get(choice.outcome, C_DIM)
            surf.blit(self._font_mono.render(choice.outcome.value, True, o_color), (18, y))
            y += 18
            if choice.evidence:
                for ln in wrap_text(choice.evidence, self._font_body, PANEL_W - 36)[:3]:
                    surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
                    y += 16
            y += 4
            for ln in wrap_text(choice.hint, self._font_body, PANEL_W - 36)[:3]:
                surf.blit(self._font_body.render(ln, True, C_DIM), (18, y))
                y += 16

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

        if session and session.fork_complete:
            five_whys = prob.dialogue.five_whys if prob.dialogue else []

            if five_whys and not session.five_whys_complete:
                step     = five_whys[session.five_whys_step]
                step_num = session.five_whys_step + 1
                total    = len(five_whys)
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

            cm_rec = factory.active_countermeasures.get(prob.applied_countermeasure or "")
            if self._should_show_verification(prob, session, cm_rec, factory):
                vfork = self._get_verification_fork(prob, cm_rec, factory)
                if vfork:
                    surf.blit(self._font_mono.render("PDCA  —  CHECK", True, (111, 211, 111)), (18, y))
                    y += 18
                    surf.blit(self._font_mono.render(f"[ {vfork.npc} ]", True, C_GOLD), (18, y))
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
                surf.blit(self._font_mono.render("✓ EFFECT VERIFIED", True, (111, 211, 111)), (18, y))
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
                    surf.blit(self._font_mono.render("[A]  Adjust — observe again", True, C_WAITING), (18, y))
                    y += 16
            if session.earned_rally_bonus:
                surf.blit(self._font_body.render(
                    "+10% credit bonus (Learning Rally)", True, (255, 214, 131)), (18, y))
                y += 16
            return y

        npc_header = f"[ {fork.npc} ]"
        surf.blit(self._font_mono.render(npc_header, True, C_GOLD), (18, y))
        y += 18
        for ln in wrap_text(fork.prompt, self._font_body, PANEL_W - 36)[:3]:
            surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (18, y))
            y += 16
        y += 4
        for i, choice in enumerate(fork.choices[:3]):
            surf.blit(self._font_mono.render(f"[{i + 1}]", True, C_GOLD), (18, y))
            for ln in wrap_text(choice.text, self._font_body, PANEL_W - 56)[:2]:
                surf.blit(self._font_body.render(ln, True, C_PANEL_INK), (44, y))
                y += 16
            y += 2
        return y

    def _draw_ct_history(self, surf: pygame.Surface, y: int, st) -> int:
        history = st.ct_history[-8:]
        target  = st.target_cycle_time
        avg     = sum(history) / len(history) if history else target

        surf.blit(self._font_body.render(
            f"avg {avg:.0f}s  target {target:.0f}s", True, C_DIM), (18, y))
        y += 14

        bar_w      = int((PANEL_W - 36) / max(len(history), 1))
        max_ct     = (max(max(history), target) if history else target) * 1.2
        bar_area_h = 28

        for i, ct in enumerate(history):
            bx    = 18 + i * bar_w
            bar_h = int((ct / max_ct) * bar_area_h)
            color = C_RUNNING if ct <= target else C_BLOCKED
            pygame.draw.rect(surf, color, (bx, y + bar_area_h - bar_h, bar_w - 2, bar_h))

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

        ambient = ""
        if self._factory:
            nearby = next(
                (m for m in self._factory.missions.values()
                 if m.active and not m.completed and m.source_npc != role
                 and _NPC_AWARENESS.get((role, m.id))),
                None,
            )
            if nearby:
                ambient = _NPC_AWARENESS[(role, nearby.id)]
        talk_line = ambient or NPC_LINES.get(role, "No comment.")
        for line_txt in wrap_text(talk_line, self._font_body, PANEL_W - 36):
            surf.blit(self._font_body.render(line_txt, True, C_PANEL_INK), (18, y))
            y += 16

        if self._factory:
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

            if mission:
                wrong_sessions = [
                    s for pid in mission.problem_ids
                    if (s := self._factory.investigation_sessions.get(pid))
                    and s.wrong_cm_count >= 1
                ]
                if wrong_sessions:
                    worst = max(wrong_sessions, key=lambda s: s.wrong_cm_count)
                    y += 8
                    pygame.draw.line(surf, (40, 38, 30), (18, y), (PANEL_W - 18, y))
                    y += 10
                    surf.blit(self._font_mono.render("CM REVIEW", True, C_WAITING), (18, y))
                    y += 14
                    advice = _RECOVERY_ADVICE.get(worst.wrong_cm_count, _RECOVERY_ADVICE[3])
                    for line_txt in wrap_text(advice, self._font_body, PANEL_W - 36):
                        surf.blit(self._font_body.render(line_txt, True, C_PANEL_INK), (18, y))
                        y += 16

        return y + 8

    def _draw_specialist(self, surf: pygame.Surface, y: int) -> int:
        factory    = self._factory
        station_id = self._obj.get("station_id")
        st         = factory.stations.get(station_id)
        if not st or st.zone_id not in ZONE_SPECIALIST:
            return y

        zone_id = st.zone_id
        y += 10
        pygame.draw.line(surf, (40, 38, 30), (12, y), (PANEL_W - 12, y))
        y += 10
        surf.blit(self._font_title.render("SPECIALISTS", True, C_GOLD), (18, y))
        y += 20

        existing = factory.specialists.get(zone_id)
        if existing:
            surf.blit(
                self._font_mono.render(f"✓ {existing.display_name}  (hired Day {existing.hired_day})",
                                       True, (111, 211, 111)),
                (18, y),
            )
            y += 18
            surf.blit(self._font_body.render(existing.description, True, C_DIM), (18, y))
            y += 18
        else:
            stub = Specialist.for_zone(zone_id, 0)
            surf.blit(
                self._font_body.render(f"Available: {stub.display_name}  —  {SPECIALIST_COST} credits",
                                       True, C_PANEL_INK),
                (18, y),
            )
            y += 18
            surf.blit(self._font_body.render(stub.description, True, C_DIM), (18, y))
            y += 18
            hint_col = (111, 211, 111) if factory.credits >= SPECIALIST_COST else (232, 96, 74)
            surf.blit(self._font_mono.render("[H] Hire Specialist", True, hint_col), (18, y))
            y += 18
        return y

    def _draw_generic(self, surf: pygame.Surface, y: int) -> int:
        obj = self._obj
        details = [
            ("ID",   obj.get("id",   "—")),
            ("Kind", obj.get("kind", "—")),
        ]
        for k, v in details:
            surf.blit(self._font_mono.render(k, True, C_DIM), (18, y))
            surf.blit(self._font_body.render(v, True, C_PANEL_INK), (130, y))
            y += 18

        y += 8
        for line_txt in wrap_text(
            "Detailed inspector panel arrives in a later iteration.", self._font_body, PANEL_W - 36
        ):
            surf.blit(self._font_body.render(line_txt, True, C_DIM), (18, y))
            y += 16
        return y
