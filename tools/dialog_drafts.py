"""Collect a dialog draft's persuasion talks into JSON for game/tools/route_check.gd.

    python tools/dialog_drafts.py <draft.md> <out.json>

The route test (PLAN 1.6c; four-tier audit §4.4, T6) runs on the real rules;
the tiers not yet in content are measured from their drafts. Every ```yaml
block's `dialogs` are read; persuasion talks are turned into the engine's
shape (the drafts' `label`/`say` and `lines.<move>.{say, lands, misses}`,
`reframe`), and each talk's start comes from its `# start: <archetype> ... = N`
comment (the base by archetype when the comment has no total). A person's
`need` comes from docs/superpowers/specs/2026-10-16-person-needs.md §2.2
(NEEDS below); people a tier names only once have none yet.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

_BLOCK = re.compile(r"^```yaml\n(.*?)^```", re.MULTILINE | re.DOTALL)
_ID = re.compile(r"^  - id: (\w+)", re.MULTILINE)
_START = re.compile(r"#\s*start[^:]*:\s*([a-z_]+)\s+(\d+)([^\n]*)")
_TOTAL = re.compile(r"=\s*(\d+)")
# Person needs (person-needs spec §2.2), by draft person id.
NEEDS = {
    "ruud": "facts", "frank": "facts", "joost": "safety", "sanne": "recognition", "marco": "fairness",
    "anouk": "safety", "henk": "recognition", "ahmed": "safety", "esra": "fairness", "petra": "facts",
    "femke": "time", "thomas": "fairness", "mieke": "recognition", "linda": "time", "dirk": "fairness",
    "gert": "safety", "el_amrani": "facts", "kees": "facts", "ruben": "time", "wendy": "recognition",
    "ingrid": "recognition", "monique": "fairness", "noor": "time", "mark": "time", "lotte": "fairness",
    "rachid": "fairness", "rob": "safety", "ilse": "time",
}


def starts(block: str) -> dict[str, dict]:
    """Per dialog id in a YAML block: {archetype, openness} from its start comment."""
    out: dict[str, dict] = {}
    ids = [(m.start(), m.group(1)) for m in _ID.finditer(block)]
    for m in _START.finditer(block):
        owner = [i for pos, i in ids if pos < m.start()]
        if not owner or owner[-1] in out:
            continue
        total = _TOTAL.search(m.group(3).split(";")[0])
        out[owner[-1]] = {"archetype": m.group(1), "openness": int(total.group(1)) if total else int(m.group(2))}
    return out


def _line(value) -> dict:
    return value if isinstance(value, dict) else {"text": str(value)}


def engine_shape(d: dict) -> dict:
    """A draft talk in the shape DialogDef reads."""
    out = {k: v for k, v in d.items() if k not in ("lines", "reframe", "proposals", "experiments")}
    out["proposals"], out["experiments"] = [], []
    for key in ("proposals", "experiments"):
        for item in d.get(key) or []:
            item = dict(item)
            item["name"] = item.pop("label", item.get("name", ""))
            item["text"] = item.pop("say", item.get("text", ""))
            out[key].append(item)
    lines, replies = {}, {m: dict(v) for m, v in (d.get("replies") or {}).items()}
    for move, value in (d.get("lines") or {}).items():
        if isinstance(value, str):
            lines[move] = value
            continue
        if "say" in value:
            lines[move] = value["say"]
        for situation in ("lands", "misses"):
            if situation in value:
                replies.setdefault(move, {})[situation] = _line(value[situation])
    if "reframe" in d:
        replies.setdefault("perspective", {})["lands"] = _line(d["reframe"])
    out["lines"], out["replies"] = lines, replies
    return out


def collect(text: str) -> dict:
    talks, people = [], {}
    for block in _BLOCK.findall(text):
        doc = yaml.safe_load(block)
        if not isinstance(doc, dict):
            continue
        found = starts(block)
        for d in doc.get("dialogs") or []:
            if d.get("kind") != "persuade" or d["id"] not in found:
                continue
            talk = engine_shape(d)
            talk["start"] = found[d["id"]]["openness"]
            talks.append(talk)
            people.setdefault(d["person"], {"id": d["person"], "name": d["person"], "archetype": found[d["id"]]["archetype"],
                                            "trust": 50, "morale": 50, "need": NEEDS.get(d["person"], "")})
    return {"people": list(people.values()), "dialogs": talks}


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    data = collect(Path(argv[0]).read_text(encoding="utf-8"))
    Path(argv[1]).write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(data['dialogs'])} persuasion talks, {len(data['people'])} people -> {argv[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
