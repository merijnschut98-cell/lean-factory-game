"""One-off migration: tag every non-WRONG investigation / 5-Whys choice in the
problem YAML with the gemba tool that reveals its evidence (`tool:` field).

The 3D build turns these choices into clues found by *doing* things at the
gemba instead of picking answers. Line-based edit so comments and folded
strings in the YAML survive. Idempotent: choices that already have a tool
are left alone. Run: python tools/tag_clue_tools.py [--dry-run]
"""
from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

import yaml

DATA = Path(__file__).resolve().parent.parent / "data"

# Ordered: first matching rule wins. Matched against the choice text, then evidence.
RULES: list[tuple[str, tuple[str, ...]]] = [
    ("data", ("plot", "chart", "calculate", "cpk", "histogram", "pareto", "regression", "trend",
              "side by side", "map which", "map all", "data", "analy", "msa", "gauge r")),
    ("ask", ("ask", "conversation", "interview", "talk to", "talk with", "discuss", "find out",
             "survey", "listen")),
    ("time", ("time every", "time exactly", "time study", "time the", "stopwatch", "cycle time", "timing",
              "duration", "how long")),
    ("count", ("count", "categor", "inventory", "tag", "shelf", "age of", "how many", "stock", "pile", "bin")),
    ("defects", ("defect", "rework", "scrap", "reject", "escape", "failure", "fails", "returns", "complaint")),
    ("machine", ("machine", "maintenance", "equipment", "calibrat", "sensor", "nozzle", "head", "gauge",
                 "fixture", "tool", "jig", "oven", "rig", "wear")),
    ("docs", ("procedure", "record", "document", "standard", "file", "report", "log", "spec", "board",
              "responsib", "owner", "history", "approv", "plan", "policy", "training", "schedule", "trace")),
]


OBSERVE_VERBS = ("observe", "watch", "film", "walk", "shadow", "follow", "go to", "stand")


def _match(blob: str) -> str | None:
    for i, (tool, words) in enumerate(RULES):
        if i == 3 and blob.startswith(OBSERVE_VERBS):  # after data/ask/time, before the rest
            return "observe"
        if any(w in blob for w in words):
            return tool
    return "observe" if blob.startswith(OBSERVE_VERBS) else None


def classify(text: str, evidence: str, is_why: bool = False) -> str:
    """Investigation choices are actions: classify the action. 5-Whys choices
    are causes: classify by how the evidence was found, then by the cause."""
    blobs = (evidence, text) if is_why else (text, evidence)
    for blob in blobs:
        tool = _match(blob.lower().strip())
        if tool:
            return tool
    return "observe"


def tag_file(path: Path, dry: bool) -> Counter:
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    # Queue of tools in document order, for every non-WRONG fork / why choice.
    tools: list[str] = []
    for p in doc.get("problems", []):
        dl = p.get("dialogue") or {}
        forks = [(dl.get("investigation") or {}, False)] + [(w, True) for w in (dl.get("five_whys") or [])]
        for fork, is_why in forks:
            for c in fork.get("choices", []):
                if c.get("outcome") != "WRONG" and "tool" not in c:
                    tools.append(classify(str(c.get("text", "")), str(c.get("evidence") or ""), is_why))
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    out, it = [], iter(tools)
    for i, line in enumerate(lines):
        out.append(line)
        m = re.match(r"^(\s*)outcome:\s*(CORRECT|PLAUSIBLE)\s*$", line)
        if not m:
            continue
        nxt = lines[i + 1] if i + 1 < len(lines) else ""
        if re.match(r"^\s*tool:", nxt):
            continue
        out.append(f"{m.group(1)}tool: {next(it)}\n")
    leftover = list(it)
    if leftover:
        raise SystemExit(f"{path.name}: {len(leftover)} tools not placed — YAML layout unexpected")
    if not dry:
        path.write_text("".join(out), encoding="utf-8")
    return Counter(tools)


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv
    total = Counter()
    for t in range(1, 5):
        c = tag_file(DATA / f"problems_tier{t}.yaml", dry)
        print(f"tier {t}: {dict(c)}")
        total += c
    print("total:", dict(total))
