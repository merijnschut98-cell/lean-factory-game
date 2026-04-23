"""
Lean Codex panel — [K] key overlay showing all discovered lean/SS/digitalization concepts.

Concepts unlock as the player encounters them through problems, fork choices, and CM application.
Locked concepts are visible as grey question marks so the player knows how much there is to learn.
"""
from __future__ import annotations
import pygame
from ui.text_utils import wrap_text

C_BG      = (14, 13, 10, 245)
C_GOLD    = (255, 214, 131)
C_INK     = (220, 215, 200)
C_DIM     = (100, 96, 82)
C_LOCKED  = (55, 52, 44)
C_GREEN   = (111, 211, 111)

# ── Concept definitions ───────────────────────────────────────────────────────
# All concepts the player can discover. Key = teaches: tag used in YAML.
CODEX = {
    "5S":                    "Sort, Set in order, Shine, Standardize, Sustain — the foundation of workplace organization.",
    "5S_sort":               "The first S: separate necessary items from unnecessary ones, remove the unnecessary.",
    "standard_work":         "Documented work sequence, takt time, and WIP target — the baseline for all improvement.",
    "WIP":                   "Work In Progress — inventory between process steps. High WIP hides waste and delays quality feedback.",
    "kanban":                "A pull signal that triggers replenishment only when downstream consumes — prevents overproduction.",
    "heijunka":              "Production leveling — smoothing the schedule to match takt and avoid flood/drought cycles.",
    "jidoka":                "Autonomation — the ability to stop on defect and call for help rather than passing the problem forward.",
    "poka_yoke":             "Error proofing — a device or method that prevents defects from occurring or passing to the next step.",
    "takt_time":             "The rate at which customers demand product: available time ÷ demand. The heartbeat of flow.",
    "gemba":                 "The actual place where value is created. Go and see before drawing conclusions.",
    "kaizen":                "Continuous incremental improvement — small, frequent changes by the people doing the work.",
    "VSM":                   "Value Stream Map — shows the flow of material and information from supplier to customer.",
    "TPM":                   "Total Productive Maintenance — operators take ownership of basic machine care: clean, inspect, lubricate.",
    "SMED":                  "Single Minute Exchange of Die — reducing changeover time to under 10 minutes.",
    "FIFO":                  "First In, First Out — oldest items consumed first, preventing inventory ageing and hidden defects.",
    "flow":                  "One-piece flow — processing one unit at a time through a connected, balanced sequence.",
    "waste_muda":            "Muda: non-value-adding activity. Seven types: transport, inventory, motion, waiting, overproduction, over-processing, defects.",
    "waste_mura":            "Mura: unevenness or variation in flow, workload, or quality — stresses the system unevenly.",
    "waste_muri":            "Muri: overburden — pushing people or machines beyond their sustainable capacity.",
    "skill_matrix":          "A visual grid mapping each operator's current skill level against each station or task type.",
    "cross_training":        "Training operators in multiple skills to increase flexibility and resilience.",
    "line_balancing":        "Distributing work evenly across stations so no one is idle while another is overwhelmed.",
    "quality_gate":          "A defined check point where defects are caught before passing to the next process step.",
    "MSA":                   "Measurement System Analysis — verifying that the measurement tool, method, and environment are reliable.",
    "SPC":                   "Statistical Process Control — control charts detect when a process goes out of statistical control.",
    "DMAIC":                 "Define → Measure → Analyze → Improve → Control — the Six Sigma structured problem-solving method.",
    "leader_standard_work":  "Defined daily leadership routines that audit, support, and sustain standard work on the floor.",
    "visual_management":     "Making process status, problems, and standards visible at a glance — reduces reliance on memory.",
    "information_flow":      "How information travels alongside material flow. Often the real bottleneck in lean systems.",
    "digitalization":        "Replacing paper-based processes with digital tools — only valuable when the process is stable first.",
    "MES":                   "Manufacturing Execution System — tracks and controls production on the shop floor in real time.",
    "andon":                 "A signal (light, sound, or screen) alerting the team when a problem occurs. Stops the line to fix at source.",
    "OEE":                   "Overall Equipment Effectiveness = Availability × Performance × Quality. The combined utilization measure.",
    "FTR":                   "First Time Right — proportion of units passing quality checks on the first attempt. Reveals hidden cost of poor quality.",
    "shift_handover":        "Structured transfer of status, in-progress work, and issues between shifts. Prevents cold-start losses.",
    "documentation":         "Written records of processes and standards that can be used, taught, and improved by anyone.",
    "safety":                "Designing work so people cannot be hurt — physical conditions, procedures, and near-miss culture.",
    "near_miss_reporting":   "Capturing incidents that nearly caused harm — the leading indicator that prevents future accidents.",
    "measurement_system":    "The full system of instrument, method, operator, and environment that produces a measurement.",
    "data_capture":          "Deciding what to record, when, and how before worrying about analysis.",
    "data_accuracy":         "The degree to which system records match physical reality — lost trust is hard to rebuild.",
    "inventory_management":  "Controlling quantity, location, and movement of materials to support stable flow.",
    "supplier_quality":      "Ensuring incoming materials meet specification — cannot be compensated by downstream inspection.",
    "replenishment":         "Triggering resupply based on consumption signals, not a fixed schedule.",
    "overproduction":        "Making more than the customer currently needs — considered the most dangerous of the seven wastes.",
    "time_study":            "Observing and timing work elements to understand current performance and locate waste.",
    "tacit_knowledge":       "Knowledge that lives in people's heads and habits — only made explicit through observation and documentation.",
    "knowledge_management":  "Systems and practices for capturing, sharing, and retaining organisational knowledge.",
    "decision_authority":    "Defining who is empowered to decide what — removes bottlenecks and builds operator confidence.",
    "variation":             "Differences in process output over time. Lean reduces common-cause variation; Six Sigma eliminates special causes.",
    "operator_variation":    "Differences in output between operators doing the same task — usually a sign that standard work is missing.",
    "shift_readiness":       "The physical and information state of a station at shift start — ready for the first unit immediately.",
    "version_control":       "Managing document versions so everyone works from the correct, current standard.",
    "performance_reporting": "The system producing KPI reports — only as trustworthy as its metric definitions.",
    "data_integrity":        "Accuracy, consistency, and trustworthiness of data over its lifecycle.",
    "management_system":     "Structured routines, meetings, and reports through which leaders manage performance.",
    "leveled_production":    "Producing at a smooth, even rate — requires stable upstream supply and takt discipline.",
    "push_vs_pull":          "Push: produce to forecast. Pull: produce only when downstream signals need. Pull eliminates overproduction.",
    "autonomous_maintenance":"Operators performing basic machine care — cleaning, inspecting, lubricating — as part of standard work.",
    "rework_waste":          "Correcting defects after the fact — the visible cost of poor quality, not the total cost.",
    "inspection":            "Checking work against a standard — only valuable if the standard is clear and measurement is valid.",
    "maintenance":           "Keeping equipment in a condition that supports reliable, quality production.",
}

_ALL_KEYS = sorted(CODEX.keys())


class CodexPanel:
    def __init__(self, screen: pygame.Surface) -> None:
        self.screen   = screen
        self.sw       = screen.get_width()
        self.sh       = screen.get_height()
        self._open    = False
        self._scroll  = 0
        self._overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

        from ui.fonts import make as _fonts
        f = _fonts()
        self._font_title = f["title"]
        self._font_label = f["label"]
        self._font_body  = f["body"]
        self._font_mono  = f["mono"]

    @property
    def is_open(self) -> bool:
        return self._open

    def toggle(self) -> None:
        self._open = not self._open
        if self._open:
            self._scroll = 0

    def close(self) -> None:
        self._open = False

    def handle_event(self, event: pygame.event.Event) -> None:
        if not self._open:
            return
        if event.type == pygame.MOUSEWHEEL:
            self._scroll = max(0, self._scroll - event.y * 30)
        elif event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_ESCAPE, pygame.K_k):
                self.close()
            elif event.key == pygame.K_UP:
                self._scroll = max(0, self._scroll - 30)
            elif event.key == pygame.K_DOWN:
                self._scroll += 30

    def draw(self, factory=None) -> None:
        if not self._open:
            return

        discovered = factory.discovered_concepts if factory else set()
        unlocked   = [k for k in _ALL_KEYS if k in discovered]
        locked     = [k for k in _ALL_KEYS if k not in discovered]

        pw, ph = 760, self.sh - 60
        px = (self.sw - pw) // 2
        py = 30

        self._overlay.fill((0, 0, 0, 180))
        self.screen.blit(self._overlay, (0, 0))

        pygame.draw.rect(self.screen, (18, 17, 13), (px, py, pw, ph), border_radius=6)
        pygame.draw.rect(self.screen, C_GOLD, (px, py, pw, ph), 1, border_radius=6)

        # Header
        ty = py + 16
        self.screen.blit(self._font_title.render("LEAN CODEX", True, C_GOLD), (px + 20, ty))
        count_txt = f"{len(unlocked)} / {len(_ALL_KEYS)} concepts discovered"
        self.screen.blit(self._font_mono.render(count_txt, True, C_DIM),
                         (px + pw - 260, ty + 2))
        ty += 30
        pygame.draw.line(self.screen, (40, 38, 30), (px + 12, ty), (px + pw - 12, ty))
        ty += 8

        # Content area (scrollable)
        content_y_start = ty
        clip_rect = pygame.Rect(px, content_y_start, pw, ph - (content_y_start - py) - 40)
        self.screen.set_clip(clip_rect)

        y = content_y_start - self._scroll

        if unlocked:
            label = f"DISCOVERED  ({len(unlocked)})"
            self.screen.blit(self._font_mono.render(label, True, C_GREEN),
                             (px + 20, y))
            y += 22
            for key in unlocked:
                y = self._draw_entry(px, pw, y, key, CODEX[key], discovered=True)

        if locked:
            y += 6
            label = f"NOT YET ENCOUNTERED  ({len(locked)})"
            self.screen.blit(self._font_mono.render(label, True, C_DIM),
                             (px + 20, y))
            y += 22
            for key in locked:
                y = self._draw_entry(px, pw, y, key, None, discovered=False)

        content_h = y + self._scroll - content_y_start
        self._scroll = min(self._scroll, max(0, content_h - clip_rect.height + 10))

        self.screen.set_clip(None)

        # Scroll indicator
        if content_h > clip_rect.height:
            track_h = clip_rect.height - 8
            thumb_h = max(20, int(track_h * clip_rect.height / content_h))
            thumb_y = content_y_start + 4 + int(
                (self._scroll / max(1, content_h - clip_rect.height)) * (track_h - thumb_h))
            pygame.draw.rect(self.screen, (50, 48, 40),
                             (px + pw - 8, content_y_start + 4, 4, track_h), border_radius=2)
            pygame.draw.rect(self.screen, (140, 130, 100),
                             (px + pw - 8, thumb_y, 4, thumb_h), border_radius=2)

        # Footer hint
        self.screen.blit(
            self._font_mono.render("[K] or [Esc]  Close codex", True, C_DIM),
            (px + 20, py + ph - 28),
        )

    def _draw_entry(self, px: int, pw: int, y: int, key: str,
                    definition: str | None, discovered: bool) -> int:
        label_color = C_GOLD if discovered else C_LOCKED
        def_color   = C_INK  if discovered else C_LOCKED
        tag_display = key.replace("_", " ").upper()

        self.screen.blit(self._font_label.render(tag_display, True, label_color),
                         (px + 20, y))
        y += 18
        if discovered and definition:
            for ln in wrap_text(definition, self._font_body, pw - 48)[:2]:
                self.screen.blit(self._font_body.render(ln, True, def_color),
                                 (px + 28, y))
                y += 16
        elif not discovered:
            self.screen.blit(self._font_body.render("???", True, C_LOCKED),
                             (px + 28, y))
            y += 16
        y += 4
        return y
