"""Build Spanning's game content: content/*.yaml → validated JSON in game/data/.

Authoring happens in YAML (readable, reviewable, comments allowed); the game
loads the JSON this script writes, so Godot needs no YAML parser. Every file
is validated before anything is written: one bad file means nothing changes.

Usage:
    python tools/build_content.py           # validate and write game/data/*.json
    python tools/build_content.py --check   # validate and fail if game/data is out of date (CI)

Validation runs in two passes: each file against its own validator
(VALIDATORS; a file without one is refused, so nothing reaches the game
unchecked), then CROSS_CHECKS over all files together (references between
files, e.g. a mission naming a problem).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Callable

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "content"
DATA_DIR = ROOT / "game" / "data"


class ContentError(ValueError):
    """Raised when a content file breaks its schema."""


def _require_strings(doc: Any, keys: list[str], source: str) -> None:
    if not isinstance(doc, dict):
        raise ContentError(f"{source}: expected a mapping at the top level")
    for key in keys:
        value = doc.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ContentError(f"{source}: '{key}' must be a non-empty string")


def validate_game(doc: Any, source: str) -> None:
    _require_strings(doc, ["company", "region", "town", "campus", "player_role", "locale"], source)


# ── value_streams.yaml ───────────────────────────────────────────────────────

_TIME = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")
_END_TIME = re.compile(r"^(([01]\d|2[0-3]):[0-5]\d|24:00)$")  # "24:00" ends a day
_ID = re.compile(r"^[a-z][a-z0-9_]*$")
STEP_KINDS = {"work", "wait", "material"}
DAY_NAMES = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
TICK_MINUTES = 10  # the simulation step; schedule times must sit on its grid


def _number(item: dict, key: str, where: str, low: float, high: float | None = None,
            integer: bool = False, default: float | None = None) -> float:
    value = item.get(key, default)
    ok_type = isinstance(value, int) if integer else isinstance(value, (int, float))
    if isinstance(value, bool) or not ok_type:
        raise ContentError(f"{where}: '{key}' must be {'an integer' if integer else 'a number'}")
    if value < low or (high is not None and value > high):
        bounds = f"between {low} and {high}" if high is not None else f">= {low}"
        raise ContentError(f"{where}: '{key}' must be {bounds} (got {value})")
    return value


def _entries(doc: dict, key: str, source: str) -> list[dict]:
    items = doc.get(key)
    if not isinstance(items, list) or not all(isinstance(i, dict) for i in items):
        raise ContentError(f"{source}: '{key}' must be a list of mappings")
    ids = [i.get("id") for i in items]
    for i, item in zip(ids, items):
        if not isinstance(i, str) or not _ID.match(i):
            raise ContentError(f"{source}: every {key} entry needs a lowercase snake_case 'id' (got {i!r})")
        _require_strings(item, ["name"], f"{source}: {key} '{i}'")
    dupes = sorted(i for i, n in Counter(ids).items() if n > 1)
    if dupes:
        raise ContentError(f"{source}: duplicate {key} ids: {', '.join(dupes)}")
    return items


def _minutes(hhmm: str) -> int:
    hours, minutes = hhmm.split(":")
    return int(hours) * 60 + int(minutes)


def _valid_days(text: Any) -> bool:
    """'mon-fri', 'sat-sun', 'wed': a day or a non-wrapping range of days."""
    ends = text.split("-") if isinstance(text, str) else []
    return (0 < len(ends) <= 2 and all(e in DAY_NAMES for e in ends)
            and DAY_NAMES.index(ends[0]) <= DAY_NAMES.index(ends[-1]))


def _validate_block(block: Any, where: str) -> None:
    """One schedule block: {days, from, to}; 'to' may be "24:00" (end of the day)."""
    if not isinstance(block, dict):
        raise ContentError(f"{where}: each block must be a mapping with days, from and to")
    if not _valid_days(block.get("days")):
        raise ContentError(f"{where}: 'days' must be a day or a range like mon-fri (got {block.get('days')!r})")
    start, end = block.get("from"), block.get("to")
    if not (isinstance(start, str) and _TIME.match(start) and isinstance(end, str) and _END_TIME.match(end)):
        raise ContentError(f'{where}: \'from\' and \'to\' must be quoted "HH:MM" times')
    if _minutes(start) % TICK_MINUTES or _minutes(end) % TICK_MINUTES:
        raise ContentError(f"{where}: times must be on the {TICK_MINUTES}-minute grid")
    if _minutes(start) >= _minutes(end):
        raise ContentError(f"{where}: a block must end after it starts (split blocks at midnight)")


def _blocks(item: dict, key: str, where: str) -> list:
    blocks = item.get(key)
    if not isinstance(blocks, list) or not blocks:
        raise ContentError(f"{where}: '{key}' must be a non-empty list of blocks")
    for block in blocks:
        _validate_block(block, f"{where} {key}")
    return blocks


def _validate_step(step: dict, where: str, pools: set[str], stock: set[str], step_ids: list[str]) -> None:
    kind = step.get("kind")
    if kind not in STEP_KINDS:
        raise ContentError(f"{where}: 'kind' must be one of {sorted(STEP_KINDS)}")
    if "applies" in step:
        _number(step, "applies", where, 0.01, 1)
    if kind == "work":
        served_by = step.get("pool")
        served_by = served_by if isinstance(served_by, list) else [served_by]
        for pool in served_by or [None]:
            if pool not in pools:
                raise ContentError(f"{where}: unknown pool {pool!r}")
        _number(step, "touch_hours", where, 0.05)
        _number(step, "ftr", where, 0.05, 1)
        target = step.get("rework_to", step["id"])
        if target not in step_ids or step_ids.index(target) > step_ids.index(step["id"]):
            raise ContentError(f"{where}: 'rework_to' must name this step or an earlier one (got {target!r})")
        if "rework_wait_days" in step:
            _number(step, "rework_wait_days", where, 0)
    elif kind == "wait":
        _number(step, "days", where, 0)
        _number(step, "spread", where, 0, 0.95, default=0)
    else:
        if step.get("item") not in stock:
            raise ContentError(f"{where}: unknown stock item {step.get('item')!r}")
        _number(step, "quantity", where, 1, integer=True)


def validate_value_streams(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    pools = _entries(doc, "pools", source)
    for pool in pools:
        where = f"{source}: pool '{pool['id']}'"
        _number(pool, "headcount", where, 1, integer=True)
        _number(pool, "availability", where, 0.1, 1)
        _blocks(pool, "schedule", where)
    stock = _entries(doc, "stock", source)
    for item in stock:
        where = f"{source}: stock '{item['id']}'"
        for key in ("level", "reorder_point"):
            _number(item, key, where, 0, integer=True)
        _number(item, "order_quantity", where, 1, integer=True)
        _number(item, "lead_days", where, 0)
    pool_ids, stock_ids = {p["id"] for p in pools}, {s["id"] for s in stock}
    for stream in _entries(doc, "streams", source):
        where = f"{source}: stream '{stream['id']}'"
        for arrival in _blocks(stream, "arrivals", where):
            _number(arrival, "per_week", f"{where} arrivals", 0)
        if ("norm_days" in stream) == ("norm_hours" in stream):
            raise ContentError(f"{where}: give exactly one of 'norm_days' or 'norm_hours'")
        _number(stream, "norm_days" if "norm_days" in stream else "norm_hours", where, 0.1)
        _number(stream, "priority", where, 0, integer=True)
        if not isinstance(stream.get("preempts", False), bool):
            raise ContentError(f"{where}: 'preempts' must be true or false")
        steps = _entries(stream, "steps", where)
        if not steps:
            raise ContentError(f"{where}: needs at least one step")
        step_ids = [s["id"] for s in steps]
        for step in steps:
            _validate_step(step, f"{where} step '{step['id']}'", pool_ids, stock_ids, step_ids)
        _check_rework_loops(steps, step_ids, where)


def _check_rework_loops(steps: list[dict], step_ids: list[str], where: str) -> None:
    """A rework loop must not pass a material step: every retry would take stock again."""
    for i, step in enumerate(steps):
        if step["kind"] != "work":
            continue
        start = step_ids.index(step.get("rework_to", step["id"]))
        for between in steps[start:i]:
            if between["kind"] == "material":
                raise ContentError(f"{where} step '{step['id']}': rework to '{steps[start]['id']}' "
                                   f"passes '{between['id']}' and takes material twice")


VALIDATORS: dict[str, Callable[[Any, str], None]] = {
    "game": validate_game,
    "value_streams": validate_value_streams,
}

# Checks that need several files at once. Each gets {stem: document}.
CROSS_CHECKS: list[Callable[[dict[str, Any]], None]] = []


def load_content(content_dir: Path | None = None) -> dict[str, Any]:
    """Parse and validate every YAML file. Returns {stem: document}."""
    content_dir = content_dir or CONTENT_DIR
    docs: dict[str, Any] = {}
    for path in sorted(content_dir.glob("*.yaml")):
        validator = VALIDATORS.get(path.stem)
        if validator is None:
            raise ContentError(f"{path.name}: no validator registered in tools/build_content.py")
        try:
            doc = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as exc:
            raise ContentError(f"{path.name}: invalid YAML — {exc}") from exc
        validator(doc, path.name)
        docs[path.stem] = doc
    missing = sorted(set(VALIDATORS) - set(docs))
    if missing:
        raise ContentError(f"missing content files: {', '.join(m + '.yaml' for m in missing)}")
    for check in CROSS_CHECKS:
        check(docs)
    return docs


def render(doc: Any) -> str:
    """Stable JSON text, so unchanged content produces byte-identical files."""
    return json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True) + "\n"


def _orphans(docs: dict[str, Any], data_dir: Path) -> list[Path]:
    """Data files whose content file no longer exists."""
    return [p for p in sorted(data_dir.glob("*.json")) if p.stem not in docs]


def stale_files(docs: dict[str, Any], data_dir: Path | None = None) -> list[str]:
    """Names of data files that are missing, different, or no longer produced."""
    data_dir = data_dir or DATA_DIR
    stale = []
    for stem, doc in docs.items():
        path = data_dir / f"{stem}.json"
        if not path.is_file() or path.read_text(encoding="utf-8") != render(doc):
            stale.append(path.name)
    return stale + [p.name for p in _orphans(docs, data_dir)]


def write(docs: dict[str, Any], data_dir: Path | None = None) -> None:
    data_dir = data_dir or DATA_DIR
    data_dir.mkdir(parents=True, exist_ok=True)
    for stem, doc in docs.items():
        (data_dir / f"{stem}.json").write_text(render(doc), encoding="utf-8")
    for orphan in _orphans(docs, data_dir):
        orphan.unlink()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="fail if game/data is out of date")
    args = parser.parse_args(argv)
    try:
        docs = load_content()
    except ContentError as exc:
        print(f"content error: {exc}", file=sys.stderr)
        return 1
    if args.check:
        stale = stale_files(docs)
        if stale:
            print(f"game/data is out of date ({', '.join(stale)}); run python tools/build_content.py", file=sys.stderr)
            return 1
        print(f"content OK: {len(docs)} file(s) up to date")
        return 0
    write(docs)
    print(f"wrote {len(docs)} file(s) to {DATA_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
