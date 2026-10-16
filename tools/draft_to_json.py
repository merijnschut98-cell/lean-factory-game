"""Collect a mission draft's YAML blocks into one JSON file for game/tools/draft_check.gd.

    python tools/draft_to_json.py <draft.md> <out.json> [--only id,id] [--maturity n] [--quick]

Every ```yaml block of the draft is read; their top-level lists (missions,
problems, countermeasures, concepts, people, ...) are concatenated by key.
`--only` limits the harness to those problem ids. The draft's KPI-menu
expansions are not needed: draft_check.gd loads the catalogue's KPIs itself.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

_BLOCK = re.compile(r"^```yaml\n(.*?)^```", re.MULTILINE | re.DOTALL)


def collect(text: str) -> dict[str, list]:
    """The draft's YAML blocks, their top-level lists joined by key."""
    out: dict[str, list] = {}
    for i, block in enumerate(_BLOCK.findall(text)):
        try:
            doc = yaml.safe_load(block)
        except yaml.YAMLError as e:
            raise SystemExit(f"yaml block {i + 1}: {e}") from e
        if not isinstance(doc, dict):
            continue
        for key, items in doc.items():
            if isinstance(items, list):
                out.setdefault(key, []).extend(items)
    return out


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("draft", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--only", default="", help="comma-separated problem ids to measure")
    parser.add_argument("--maturity", type=int, default=2)
    parser.add_argument("--quick", action="store_true", help="skip the year runs (harm and the Check only)")
    args = parser.parse_args(argv)
    doc = collect(args.draft.read_text(encoding="utf-8"))
    draft = {"problems": doc.get("problems", []), "countermeasures": doc.get("countermeasures", []),
             "maturity": args.maturity, "quick": args.quick}
    if args.only:
        draft["only"] = [p for p in args.only.split(",") if p]
    args.out.write_text(json.dumps(draft, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(draft['problems'])} problems, {len(draft['countermeasures'])} countermeasures -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
