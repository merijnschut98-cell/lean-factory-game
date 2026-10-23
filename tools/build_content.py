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
from datetime import date
from pathlib import Path
from typing import Any, Callable

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "content"
DATA_DIR = ROOT / "game" / "data"
# The floors' models (world.yaml `model`), built by tools/blender/build_office.py.
OFFICE_ASSETS = ROOT / "game" / "assets" / "office"
# The cast list (who is in the office): greetings are written per cast member.
CAST_FILE = ROOT / "game" / "assets" / "characters" / "cast.json"


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


class _StrictLoader(yaml.SafeLoader):
    """safe_load that refuses YAML which silently loses text: a duplicate key
    (the last one wins), or an unquoted comma inside {…}, which splits a text
    and turns the rest into a key without a value."""

    def construct_mapping(self, node: yaml.MappingNode, deep: bool = False) -> dict:
        seen = set()
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            line = key_node.start_mark.line + 1
            if key in seen:
                raise ContentError(f"line {line}: duplicate key {key!r}")
            seen.add(key)
            if node.flow_style and value_node.tag == "tag:yaml.org,2002:null" and value_node.value == "":
                raise ContentError(f"line {line}: {key!r} has no value (a comma in unquoted text? quote the text)")
        return super().construct_mapping(node, deep)


def _mapping(item: dict, key: str, allowed: set[str], where: str) -> dict:
    """An optional mapping under `key` with only `allowed` keys ({} when absent)."""
    value = item.get(key, {})
    if not isinstance(value, dict):
        raise ContentError(f"{where}: '{key}' must be a mapping")
    _known_keys(value, allowed, f"{where} {key}")
    return value


def _known_keys(d: dict, allowed: set[str], where: str) -> None:
    """Reject keys nobody reads, such as a misspelt optional field."""
    unknown = sorted(str(k) for k in d if k not in allowed)
    if unknown:
        raise ContentError(f"{where}: unknown key(s) {', '.join(map(repr, unknown))}")


def _check_ids(ids: list, label: str, where: str, pattern: re.Pattern = _ID,
               rule: str = "a lowercase snake_case 'id'") -> None:
    for i in ids:
        if not isinstance(i, str) or not pattern.match(i):
            raise ContentError(f"{where}: every {label} entry needs {rule} (got {i!r})")
    dupes = sorted(i for i, n in Counter(ids).items() if n > 1)
    if dupes:
        raise ContentError(f"{where}: duplicate {label} ids: {', '.join(dupes)}")


def _entries(doc: dict, key: str, source: str, name: str = "name") -> list[dict]:
    items = doc.get(key)
    if not isinstance(items, list) or not all(isinstance(i, dict) for i in items):
        raise ContentError(f"{source}: '{key}' must be a list of mappings")
    _check_ids([i.get("id") for i in items], key, source)
    for item in items:
        _require_strings(item, [name], f"{source}: {key} '{item['id']}'")
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


def _earlier(step_ids: list[str], target: Any, here: str, or_same: bool = False) -> bool:
    """Whether `target` names a step before `here` (or `here` itself)."""
    if target not in step_ids:
        return False
    return step_ids.index(target) < step_ids.index(here) + (1 if or_same else 0)


def _validate_step(step: dict, where: str, pools: set[str], stock: set[str], step_ids: list[str]) -> None:
    kind = step.get("kind")
    if kind not in STEP_KINDS:
        raise ContentError(f"{where}: 'kind' must be one of {sorted(STEP_KINDS)}")
    if "applies" in step:
        _number(step, "applies", where, 0.01, 1)
    if kind != "wait" and ("starts_with" in step or "batch_days" in step):
        raise ContentError(f"{where}: only a wait step can start in parallel or in batches")
    if kind == "work":
        served_by = step.get("pool")
        served_by = served_by if isinstance(served_by, list) else [served_by]
        for pool in served_by or [None]:
            if pool not in pools:
                raise ContentError(f"{where}: unknown pool {pool!r}")
        _number(step, "touch_hours", where, 0.05)
        _number(step, "ftr", where, 0.05, 1)
        if "fail_hours" in step:  # what a failed attempt costs (default: the full touch time)
            _number(step, "fail_hours", where, 0.05, step["touch_hours"])
        for key in ("rework_to", "interrupt_to"):
            target = step.get(key, step["id"])
            if not _earlier(step_ids, target, step["id"], or_same=True):
                raise ContentError(f"{where}: '{key}' must name this step or an earlier one (got {target!r})")
        for key in ("rework_wait_days", "interrupt_wait_days", "stale_wait_days"):
            if key in step:
                _number(step, key, where, 0)
        if "stale_after_days" in step or "stale_to" in step:
            # A dossier that waited too long goes back to this step (the first
            # step of a stream: the customer checks the application again) or an earlier one.
            _number(step, "stale_after_days", where, 1)
            if not _earlier(step_ids, step.get("stale_to"), step["id"], or_same=True):
                raise ContentError(f"{where}: 'stale_to' must name this step or an earlier one (got {step.get('stale_to')!r})")
    elif kind == "wait":
        _number(step, "days", where, 0)
        _number(step, "spread", where, 0, 0.95, default=0)
        _number(step, "batch_days", where, 0, default=0)
        if "starts_with" in step and not _earlier(step_ids, step["starts_with"], step["id"]):
            raise ContentError(f"{where}: 'starts_with' must name an earlier step (got {step['starts_with']!r})")
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
    streams = _entries(doc, "streams", source)
    stream_ids = {s["id"] for s in streams}
    for pool in pools:
        if "reserve" in pool:
            where = f"{source}: pool '{pool['id']}' reserve"
            reserve = pool["reserve"] if isinstance(pool["reserve"], dict) else {}
            if reserve.get("stream") not in stream_ids:
                raise ContentError(f"{where}: unknown stream {reserve.get('stream')!r}")
            _number(reserve, "people", where, 1, pool["headcount"], integer=True)
    stock = _entries(doc, "stock", source)
    for item in stock:
        where = f"{source}: stock '{item['id']}'"
        for key in ("level", "reorder_point"):
            _number(item, key, where, 0, integer=True)
        _number(item, "order_quantity", where, 1, integer=True)
        _number(item, "lead_days", where, 0)
    pool_ids, stock_ids = {p["id"] for p in pools}, {s["id"] for s in stock}
    for stream in streams:
        where = f"{source}: stream '{stream['id']}'"
        arrivals = _blocks(stream, "arrivals", where)
        for arrival in arrivals:
            _number(arrival, "per_week", f"{where} arrivals", 0)
        _check_ids([a["id"] for a in arrivals if "id" in a], "arrival source", where)
        if ("norm_days" in stream) == ("norm_hours" in stream):
            raise ContentError(f"{where}: give exactly one of 'norm_days' or 'norm_hours'")
        _number(stream, "norm_days" if "norm_days" in stream else "norm_hours", where, 0.1)
        _number(stream, "priority", where, 0, integer=True)
        if not isinstance(stream.get("preempts", False), bool):
            raise ContentError(f"{where}: 'preempts' must be true or false")
        _number(stream, "wip_limit", where, 0, integer=True, default=0)
        calls = stream.get("status_calls")
        if calls is not None:
            # Failure demand: late orders make customers call another stream.
            if not isinstance(calls, dict) or calls.get("to") not in stream_ids or calls.get("to") == stream["id"]:
                raise ContentError(f"{where}: 'status_calls' needs 'to': another stream")
            _number(calls, "after_days", f"{where} status_calls", 1)
            _number(calls, "per_week", f"{where} status_calls", 0)
        steps = _entries(stream, "steps", where)
        if not steps:
            raise ContentError(f"{where}: needs at least one step")
        step_ids = [s["id"] for s in steps]
        for step in steps:
            _validate_step(step, f"{where} step '{step['id']}'", pool_ids, stock_ids, step_ids)
        _check_rework_loops(steps, step_ids, where)


def _check_rework_loops(steps: list[dict], step_ids: list[str], where: str) -> None:
    """A loop back (rework, or re-planning after an interruption) must not pass
    a material step: every pass would take stock again."""
    for i, step in enumerate(steps):
        if step["kind"] != "work":
            continue
        for key in ("rework_to", "interrupt_to", "stale_to"):
            start = step_ids.index(step.get(key, step["id"]))
            for between in steps[start:i]:
                if between["kind"] == "material":
                    raise ContentError(f"{where} step '{step['id']}': {key} '{steps[start]['id']}' "
                                       f"passes '{between['id']}' and takes material twice")


# ── problems_tier*.yaml and countermeasures.yaml ─────────────────────────────
# Vocabularies the game also defines (game/src/rules/investigation.gd,
# game/src/sim/modifiers.gd); the Godot content test fails if they diverge.

TOOLS = {"shadow", "time_study", "queue_count", "data", "documents", "listen_in", "material_check", "conversation"}
WASTES = ["transport", "inventory", "motion", "waiting", "overproduction", "overprocessing", "defects", "skills"]
KPIS = ["throughput", "lead_time", "first_time_right", "on_time", "wip_age", "capacity"]  # Investigation.KPIS
SEVERITIES = ["low", "medium", "high", "critical"]
VISIBILITIES = ["obvious", "subtle", "hidden"]
PROBLEM_KEYS = {"id", "tier", "name", "step", "waste", "severity", "visibility", "kpi", "symptoms", "root_cause",
                "plausible_causes", "mismatch_note", "countermeasures", "teaches", "effects", "clues", "cost_per_week",
                "tells"}
COUNTERMEASURE_KEYS = {"id", "tier", "name", "category", "description", "budget", "team_hours", "decay_days", "needs",
                       "preparation",
                       "multipliers", "effects", "unlocks", "sustains", "trust", "aftermath"}
# A short-term fix's later cost (tier-2 draft §0.1): effects for `days` from
# `after_days` after the Act, and a one-off cost.
AFTERMATH_KEYS = {"after_days", "days", "effects", "cost"}
UNLOCKS = ["kpi_board"]  # CountermeasureDef.UNLOCKS: what a countermeasure opens in the game
CLUE_KEYS = {"tool", "text", "key", "depth", "at", "note", "teaches"}
# The props that read the simulation (PLAN 2.6, design §1.5): tell id → the world.yaml room
# it stands in. The game's OfficeTells.THRESHOLDS (game/src/world/office/office_tells.gd)
# has the same ids, and tools/blender/build_office.py builds a node `tell_<id>` for each.
TELLS = {"intake_stack": "connections", "prep_tray": "connections", "planning_board": "connections",
         "revision_cabinet": "revision_gis", "close_out_cabinet": "meter_data", "meter_board": "meter_data"}
TELL_KEYS = {"tell", "text"}
# world.yaml `tells:`: what each tell looks like at each height (OfficeTells.VARIANTS).
TELL_HEIGHTS = ("low", "mid", "high")
WORLD_TELL_KEYS = {"id", "place", *TELL_HEIGHTS}
# A tell text names its problem if it holds the name or one of its words this long.
_TELL_NAME_WORD = 7
_WORD = re.compile(r"[a-zà-ÿ]+")
EFFECT_KEYS = {"target", "property", "value"}
START_RULES = ["push", "pull"]  # SimPool.START_RULES
ORDER_RULES = ["first_come", "oldest", "shortest", "due"]  # SimPool.ORDER_RULES
WORK_RULES = {"start_rule": START_RULES, "order_rule": ORDER_RULES}  # value type → its values
CARE_RULES = ["normal", "careful", "hasty"]  # KpiDef.CARE_RULES
KPI_KINDS = ["leading", "lagging"]  # KpiDef.KINDS
KPI_RULES = {"start": START_RULES, "order": ORDER_RULES, "care": CARE_RULES}  # a KPI's rule → its values
KPI_KEYS = {"id", "name", "pool", "kind", "rules", "note"}
KPIS_PER_POOL = 5
KPI_EFFECT = "kpis"  # not a simulation property: the game expands it into the KPIs' rule effects
CHECK_PASS = 0.5  # the effectiveness a Check needs to pass (Pdca.CHECK_PASS)
# property → (target kind, required step kind or None, value type: factor | number | bool | count | reserve | step | start_rule | order_rule)
EFFECT_PROPERTIES = {
    "touch_time": ("step", "work", "factor"), "ftr": ("step", "work", "number"),
    "applies": ("step", None, "number"), "wait_time": ("step", "wait", "factor"),
    "availability": ("pool", None, "number"), "headcount": ("pool", None, "number"),
    "lead_time": ("stock", None, "factor"), "reorder_point": ("stock", None, "number"),
    "demand": ("arrivals", None, "factor"), "reserve": ("pool", None, "reserve"),
    "preempts": ("stream", None, "bool"), "wip_limit": ("stream", None, "count"),
    "call_rate": ("stream", None, "factor"),
    "start_rule": ("pool", None, "start_rule"), "order_rule": ("pool", None, "order_rule"),
    "batch_days": ("step", "wait", "number"), "starts_with": ("step", "wait", "step"),
}


def _string_list(item: dict, key: str, where: str, allow_empty: bool = True) -> list:
    value = item.get(key, [])
    if not isinstance(value, list) or not all(isinstance(v, str) and v.strip() for v in value) or (not allow_empty and not value):
        raise ContentError(f"{where}: '{key}' must be a {'' if allow_empty else 'non-empty '}list of texts")
    return value


def _one_of(item: dict, key: str, options: list, where: str) -> None:
    if item.get(key) not in options:
        raise ContentError(f"{where}: '{key}' must be one of {list(options)} (got {item.get(key)!r})")


def _effects_shape(item: dict, where: str) -> list:
    effects = item.get("effects", [])
    if not isinstance(effects, list) or not all(isinstance(e, dict) for e in effects):
        raise ContentError(f"{where}: 'effects' must be a list of mappings")
    for i, e in enumerate(effects):
        _known_keys(e, EFFECT_KEYS, f"{where} effect {i}")
        if not isinstance(e.get("target"), str) or "value" not in e:
            raise ContentError(f"{where}: every effect needs a target and a value")
        if e.get("property") not in EFFECT_PROPERTIES and e.get("property") != KPI_EFFECT:
            raise ContentError(f"{where}: unknown effect property {e.get('property')!r}")
    return effects


def validate_countermeasures(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    for cm in _entries(doc, "countermeasures", source):
        where = f"{source}: countermeasure '{cm['id']}'"
        _known_keys(cm, COUNTERMEASURE_KEYS, where)
        _require_strings(cm, ["category", "description"], where)
        _number(cm, "tier", where, 1, 4, integer=True)
        _number(cm, "budget", where, 0, integer=True)
        hours = cm.get("team_hours", {})
        if not isinstance(hours, dict):
            raise ContentError(f"{where}: 'team_hours' must map pools to hours")
        for pool in hours:
            _number(hours, pool, f"{where} team_hours", 0.5)
        if cm.get("decay_days") is not None:
            _number(cm, "decay_days", where, 1, integer=True)
        m = cm.get("multipliers")
        if not isinstance(m, dict):
            raise ContentError(f"{where}: 'multipliers' needs full, reduced and minimal")
        for level in ("full", "reduced", "minimal"):
            _number(m, level, f"{where} multipliers", 0, 1)
        if not m["full"] >= m["reduced"] >= m["minimal"]:
            raise ContentError(f"{where}: multipliers must be full >= reduced >= minimal")
        if "unlocks" in cm:
            _one_of(cm, "unlocks", UNLOCKS, where)
        if not isinstance(cm.get("sustains", False), bool):
            raise ContentError(f"{where}: 'sustains' must be true or false")
        if "needs" in cm:
            # Path dependence: an option that needs earlier preparations shows
            # as "niet voorbereid" with this hint (a place or team, never the answer).
            _validate_needs(cm["needs"], where)
            _require_strings(cm, ["preparation"], where)
        elif "preparation" in cm:
            raise ContentError(f"{where}: 'preparation' is the hint for unmet 'needs'")
        _effects_shape(cm, where)
        _trust_map(cm, where, *TRUST_RANGE)
        if "aftermath" in cm:
            after = _mapping(cm, "aftermath", AFTERMATH_KEYS, where)
            _number(after, "after_days", f"{where} aftermath", 1, integer=True)
            _number(after, "cost", f"{where} aftermath", 0, integer=True, default=0)
            if _effects_shape(after, f"{where} aftermath"):
                if "days" not in after:
                    raise ContentError(f"{where} aftermath: needs 'days' for its effects")
                _number(after, "days", f"{where} aftermath", 1, integer=True)


def validate_problems(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    for p in _entries(doc, "problems", source):
        where = f"{source}: problem '{p['id']}'"
        _known_keys(p, PROBLEM_KEYS, where)
        _require_strings(p, ["step", "root_cause", "mismatch_note"], where)
        _number(p, "tier", where, 1, 4, integer=True)
        _number(p, "cost_per_week", where, 0, integer=True, default=0)
        _one_of(p, "waste", WASTES, where)
        _one_of(p, "severity", SEVERITIES, where)
        _one_of(p, "visibility", VISIBILITIES, where)
        _one_of(p, "kpi", KPIS, where)
        _string_list(p, "symptoms", where, allow_empty=False)
        _string_list(p, "plausible_causes", where)
        _string_list(p, "teaches", where)
        fits = p.get("countermeasures")
        if not isinstance(fits, dict) or not fits:
            raise ContentError(f"{where}: 'countermeasures' must map countermeasure ids to a fit")
        for cm in fits:
            _number(fits, cm, f"{where} countermeasure '{cm}' fit", 0.05, 1)
        _effects_shape(p, where)
        _validate_clues(p, where)
        _validate_tells(p, where)


def _validate_tells(p: dict, where: str) -> None:
    """`tells`: [{tell, text}], what a prop shows of the problem, ambiguous by design: the text
    describes what anyone can see and never names the problem."""
    tells = p.get("tells", [])
    if not isinstance(tells, list):
        raise ContentError(f"{where}: 'tells' must be a list of {{tell, text}}")
    for i, t in enumerate(tells):
        here = f"{where} tell {i}"
        if not isinstance(t, dict):
            raise ContentError(f"{here}: must be a mapping {{tell, text}}")
        _known_keys(t, TELL_KEYS, here)
        _require_strings(t, ["tell", "text"], here)
        if t["tell"] not in TELLS:
            raise ContentError(f"{here}: unknown tell {t['tell']!r} (known: {', '.join(sorted(TELLS))})")
        _never_names(t["text"], p, here)


def _never_names(text: str, p: dict, where: str) -> None:
    """A tell's words describe what anyone can see: they never hold the problem's name or one
    of its long words."""
    name = p["name"].lower()
    name_words = {w for w in _WORD.findall(name) if len(w) >= _TELL_NAME_WORD}
    if name in text.lower() or name_words & set(_WORD.findall(text.lower())):
        raise ContentError(f"{where}: the text names the problem ({p['name']!r}); a tell shows, it never says")


def _validate_clues(p: dict, where: str, keys: set[str] = CLUE_KEYS) -> None:
    clues = p.get("clues")
    if not isinstance(clues, list) or not clues or not all(isinstance(c, dict) for c in clues):
        raise ContentError(f"{where}: 'clues' must be a non-empty list of mappings")
    keys_at = set()
    for i, c in enumerate(clues):
        _known_keys(c, keys, f"{where} clue {i}")
        if c.get("tool") not in TOOLS:
            raise ContentError(f"{where} clue {i}: unknown tool {c.get('tool')!r}")
        _require_strings(c, ["text"], f"{where} clue {i}")
        if not isinstance(c.get("key"), bool):
            raise ContentError(f"{where} clue {i}: 'key' must be true or false")
        _number(c, "depth", f"{where} clue {i}", 0, integer=True)
        _string_list(c, "teaches", f"{where} clue {i}")
        if c["key"]:
            keys_at.add(c["depth"])
    if 0 not in keys_at:
        raise ContentError(f"{where}: needs a key clue at depth 0 (where the investigation starts)")
    for c in clues:
        if c["depth"] > 0 and c["depth"] - 1 not in keys_at:
            raise ContentError(f"{where}: a clue at depth {c['depth']} needs a key clue at depth {c['depth'] - 1}")


def _network_index(streams_doc: dict, kpis_doc: dict) -> dict:
    """What effects and places can refer to, by target kind: steps ('stream.step',
    with their kind and their stream's step ids), pools, stock items, streams,
    and arrivals (a stream, or one of its sources with an id: 'stream.source').
    Also `menu`: pool id → the ids of its KPIs."""
    steps = {}
    for stream in streams_doc["streams"]:
        ids = [s["id"] for s in stream["steps"]]
        for step in stream["steps"]:
            steps[f"{stream['id']}.{step['id']}"] = {"kind": step["kind"], "id": step["id"], "stream_ids": ids}
    return {
        "step": steps,
        "pool": {p["id"]: p for p in streams_doc["pools"]},
        "stock": {s["id"] for s in streams_doc["stock"]},
        "stream": {s["id"] for s in streams_doc["streams"]},
        "arrivals": {s["id"] for s in streams_doc["streams"]} | {
            f"{s['id']}.{a['id']}" for s in streams_doc["streams"] for a in s["arrivals"] if "id" in a},
        "menu": {pool: {k["id"] for k in kpis_doc["kpis"] if k["pool"] == pool} for pool in {k["pool"] for k in kpis_doc["kpis"]}},
    }


def _check_kpis_effect(e: dict, where: str, net: dict) -> None:
    """A department follows one or two KPIs, both from its own menu."""
    target, ids = e["target"], e["value"]
    where = f"{where} {KPI_EFFECT} on {target}"
    if target not in net["pool"]:
        raise ContentError(f"{where}: unknown pool {target!r}")
    if not isinstance(ids, list) or not 1 <= len(ids) <= 2 or not all(isinstance(i, str) for i in ids):
        raise ContentError(f"{where}: needs a list of one or two KPIs")
    if len(set(ids)) != len(ids):
        raise ContentError(f"{where}: needs two different KPIs")
    for i in ids:
        if i not in net["menu"].get(target, set()):
            raise ContentError(f"{where}: {i!r} is not on the menu of {target!r}")


def _check_effect(e: dict, where: str, net: dict) -> None:
    if e["property"] == KPI_EFFECT:
        return _check_kpis_effect(e, where, net)
    kind, step_kind, value_type = EFFECT_PROPERTIES[e["property"]]
    target, value = e["target"], e["value"]
    if target not in net[kind]:
        raise ContentError(f"{where}: unknown {kind} {target!r}")
    if step_kind and net["step"][target]["kind"] != step_kind:
        raise ContentError(f"{where}: {target} is not a {step_kind} step (for {e['property']})")
    where = f"{where} {e['property']} on {target}"
    if value_type == "factor" and not (isinstance(value, (int, float)) and not isinstance(value, bool) and value > 0):
        raise ContentError(f"{where}: needs a factor above 0")
    if value_type == "number":
        _number(e, "value", where, float("-inf"))
    if value_type == "count":
        _number(e, "value", where, 0, integer=True)
    if value_type == "bool" and not isinstance(value, bool):
        raise ContentError(f"{where}: needs true or false")
    if value_type == "reserve":
        if not isinstance(value, dict) or value.get("stream") not in net["stream"]:
            raise ContentError(f"{where}: a reserve is {{stream, people}} with a known stream")
        _number(value, "people", where, 0, net["pool"][target]["headcount"], integer=True)
    if value_type in WORK_RULES:
        _one_of(e, "value", WORK_RULES[value_type], where)
    if value_type == "step" and value != "":
        step = net["step"][target]
        if not _earlier(step["stream_ids"], value, step["id"]):
            raise ContentError(f"{where}: can only start with an earlier step (got {value!r})")


def _check_countermeasure(cm: dict, net: dict) -> None:
    where = f"countermeasures.yaml: '{cm['id']}'"
    for pool in cm.get("team_hours", {}):
        if pool not in net["pool"]:
            raise ContentError(f"{where}: team_hours for unknown pool {pool!r}")
    for team in cm.get("trust", {}):
        if team not in net["pool"]:
            raise ContentError(f"{where}: trust of unknown team {team!r}")
    for e in cm.get("aftermath", {}).get("effects", []):
        _check_effect(e, f"{where} aftermath", net)
    for e in cm["effects"]:
        _check_effect(e, where, net)


def _check_problem(p: dict, where: str, net: dict, cms: dict) -> None:
    if p["step"] not in net["step"]:
        raise ContentError(f"{where}: unknown step {p['step']!r}")
    for e in p["effects"]:
        _check_effect(e, where, net)
    for i, c in enumerate(p["clues"]):
        at = c.get("at", p["step"])
        if at not in net["step"]:
            raise ContentError(f"{where} clue {i}: unknown step {at!r}")
        if c["tool"] == "conversation" and net["step"][at]["kind"] != "work":
            raise ContentError(f"{where} clue {i}: a conversation clue at a step without a team ({at})")
    for cm_id, fit in p["countermeasures"].items():
        if cm_id not in cms:
            raise ContentError(f"{where}: unknown countermeasure {cm_id!r}")
        # Each listed countermeasure is an improvement, so each must be able
        # to pass the Check (Pdca.CHECK_PASS) at full strength.
        if cms[cm_id]["multipliers"]["full"] * fit < CHECK_PASS:
            raise ContentError(f"{where}: {cm_id!r} can never pass the Check "
                               f"(full multiplier x fit < {CHECK_PASS})")
    if not any(cms[c]["tier"] <= p["tier"] for c in p["countermeasures"]):
        raise ContentError(f"{where}: no countermeasure that can solve it at its tier")


PROBLEM_FILES = "problems_tier"


def check_problems(docs: dict[str, Any]) -> None:
    """Problems and countermeasures against the value streams and each other."""
    net = _network_index(docs["value_streams"], docs["kpis"])
    cms = {c["id"]: c for c in docs["countermeasures"]["countermeasures"]}
    for cm in cms.values():
        _check_countermeasure(cm, net)
    for stem, p in _all_problems(docs):
        _check_problem(p, f"{stem}.yaml: problem '{p['id']}'", net, cms)


def _all_problems(docs: dict[str, Any]) -> list[tuple[str, dict]]:
    """(file stem, problem) for every problem in every problems_tier* file."""
    return [(stem, p) for stem, doc in docs.items() if stem.startswith(PROBLEM_FILES) for p in doc["problems"]]


def check_tells(docs: dict[str, Any]) -> None:
    """Every problem whose place is on a floor with tells (the 1e) shows on at least one of them,
    whichever room it is in."""
    world = docs.get("world")
    if world is None:
        return
    floor_of = {r["id"]: r["floor"] for r in world["rooms"]}
    room_of = {place: r["id"] for r in world["rooms"] for place in r["places"]}
    unknown = set(TELLS.values()) - set(floor_of)
    if unknown:
        raise ContentError(f"build_content.TELLS: unknown room(s) {', '.join(sorted(unknown))}")
    looks = {t["id"]: t for t in world.get("tells", [])}
    if set(looks) != set(TELLS):
        raise ContentError(f"world.yaml tells: must hold exactly {', '.join(sorted(TELLS))} "
                           f"(missing: {', '.join(sorted(set(TELLS) - set(looks))) or '-'}; "
                           f"unknown: {', '.join(sorted(set(looks) - set(TELLS))) or '-'})")
    problems = [p for _, p in _all_problems(docs)]
    for tell, look in looks.items():
        if room_of.get(look["place"]) != TELLS[tell]:
            raise ContentError(f"world.yaml tell '{tell}': place {look['place']!r} is not in its room '{TELLS[tell]}'")
        for v in TELL_HEIGHTS:
            for p in problems:
                _never_names(look[v], p, f"world.yaml tell '{tell}' {v}")
    floors = {floor_of[room] for room in TELLS.values()}
    for stem, p in _all_problems(docs):
        room = room_of.get(p["step"])
        if floor_of.get(room) in floors and not p.get("tells"):
            near = [t for t, r in TELLS.items() if r == room] \
                or [t for t, r in TELLS.items() if floor_of[r] == floor_of[room]]
            raise ContentError(f"{stem}.yaml: problem '{p['id']}' at {p['step']} (room '{room}') has no tell; "
                               f"list one under 'tells:' ({', '.join(near)})")


# ── facts and needs (path dependence, game/src/rules/facts.gd) ───────────────
# A fact kind → how many ids follow it ("chose:<problem>:<cm>"). The dialog
# facts (heard: ... blocked:) name a dialog; they are checked once dialogs exist.
FACT_KINDS = {"done": 1, "failed": 1, "chose": 2, "standardised": 1, "poor_fix": 1, "repaired": 1, "fork_first": 2,
              "flag": 1, "heard": 1, "committed": 1, "complied": 1, "partial": 1, "blocked": 1,
              "checked": 1, "accepted": 1, "forecast_positive": 1,
              # the story's (phase-2 design §3.2): a proposal agreed, a followed story delivered,
              # a person who left, a promised date checked, a fix that holds (live)
              "agreed": 2, "delivered": 1, "left": 1, "promise_kept": 1, "promise_broken": 1,
              "holds": 1,
              "promised": 2}  # Facts.KINDS; promised:<dialog>:<ISO date | action kind>, recorded by GameSession
# The followed stories (FollowedOrder.STORY): delivered:<story>, a story_order goal's story.
STORIES = ["el_amrani"]
# What a forecast_positive:<subject> fact names: the KPI board's quarterly
# review, or the KPI a Check predicted (Investigation.KPIS).
FORECAST_SUBJECTS = ["kpi_board"] + KPIS
DIALOG_FACTS = {"heard", "committed", "complied", "partial", "blocked"}
MEASURES = {"maturity": (1, 4), "reputation": (0, 100)}  # Facts.MEASURES: "maturity>=3"
_MEASURE = re.compile(r"^([a-z]+)>=(\d+)$")
NEEDS_KEYS = ["all", "any", "none"]


def _atom_parts(atom: Any, where: str) -> tuple[str, list[str]]:
    """("measure", [name, at least]) or (fact kind, ids); raises on a malformed atom."""
    if not isinstance(atom, str):
        raise ContentError(f"{where}: a needs entry must be a text (got {atom!r})")
    measure = _MEASURE.match(atom)
    if measure:
        name, value = measure.group(1), int(measure.group(2))
        if name not in MEASURES or not MEASURES[name][0] <= value <= MEASURES[name][1]:
            raise ContentError(f"{where}: {atom!r}: measures are {', '.join(f'{m}>=n ({lo}-{hi})' for m, (lo, hi) in MEASURES.items())}")
        return "measure", [name, str(value)]
    kind, _, rest = atom.partition(":")
    ids = rest.split(":") if rest else []
    if kind not in FACT_KINDS or len(ids) != FACT_KINDS[kind] or not all(_ID.match(i) for i in ids):
        raise ContentError(f"{where}: {atom!r} is not a fact (kinds: {', '.join(FACT_KINDS)}) or a measure")
    if kind == "forecast_positive" and ids[0] not in FORECAST_SUBJECTS:
        raise ContentError(f"{where}: {atom!r}: a forecast is of {', '.join(FORECAST_SUBJECTS)}")
    return kind, ids


def _validate_needs(needs: Any, where: str) -> None:
    """{all, any, none}: lists of facts or measures (the grammar only)."""
    if not isinstance(needs, dict) or not needs:
        raise ContentError(f"{where}: 'needs' must map {', '.join(NEEDS_KEYS)} to lists")
    _known_keys(needs, set(NEEDS_KEYS), f"{where} needs")
    for key, atoms in needs.items():
        if not isinstance(atoms, list) or not atoms:
            raise ContentError(f"{where} needs: '{key}' must be a non-empty list")
        for atom in atoms:
            _atom_parts(atom, f"{where} needs")


def _sets_flags(item: dict, where: str, key: str = "sets_flags") -> list:
    flags = _string_list(item, key, where)
    for flag in flags:
        if _atom_parts(flag, where)[0] != "flag":
            raise ContentError(f"{where}: '{key}' entries are flag:<name> (got {flag!r})")
    return flags


# training: the Inwerkweek before the campaign; it takes no side slot and the
# coach helps with it (Missions). milestone: a dated moment of the story that opens
# itself and takes no slot (phase-2 design §3.1): its scene played, or the story's
# order met by its deadline_on_day.
MISSION_KINDS = ["main", "side", "training", "milestone"]
MILESTONE_GOALS = ["scene", "story_order"]  # MissionDef.MILESTONE_GOALS
STORY_BY = ["deadline"]  # MissionDef.STORY_BY
# What reaches the player once a mission is done in time (MissionDef.payoff, Berichten).
PAYOFF_KEYS = {"who", "by", "text"}
PAYOFF_BY = ["call", "letter"]  # MissionDef.PAYOFF_BY
PLAY_START = date(2026, 10, 12)  # MissionDef.PLAY_START, GameSession.PLAY_START_DATE: day 0 of play
COACHED_KINDS = ["main", "training"]
# goal type → (required keys, optional keys). observe: use a gemba tool (or any,
# without `tool`) at each place, `uses` distinct place-tool pairs in all;
# check: the problem's Check passed; sustain: the problem's fix back in use
# (audited, or held by a routine; the game opens these as check-ins);
# rework_fix: a poor fix swapped for a better one (the game's repair quests);
# talk_to: a dialog of this mission reached `outcome` (partial | commitment,
# default commitment; dialog spec §5.1; checked against dialogs.yaml).
MISSION_GOALS = {
    "walk": ({"stream"}, set()), "investigate": ({"problem", "clues"}, set()), "solve": ({"problem"}, set()),
    "observe": ({"places"}, {"tool", "uses"}), "check": ({"problem"}, set()),
    "sustain": ({"problem"}, set()), "rework_fix": ({"problem"}, set()),
    "talk_to": ({"dialog"}, {"outcome"}),
    # scene: the milestone's `scene` (content/scenes.yaml) played; story_order (drie winters
    # S12): met_if holds by the deadline_on_day, and the date promised in `promise`'s call
    # is checked on its day (Missions._judge_promises).
    "scene": (set(), set()), "story_order": ({"story", "by", "met_if"}, {"promise"}),
}
TALK_OUTCOMES = ["partial", "commitment"]  # MissionDef.TALK_OUTCOMES
MAX_CHECK_DAYS = 14  # Region.CHECK_DAYS: a mission may only shorten the Check
MATURITY_STEP = 0.6  # Region.MATURITY_STEP
COACH_STAGES = ["go_see", "understand", "experiment", "reflect"]  # Missions.STAGES
# The coach's questions for a situation (Missions._conditions): after a
# blaming question, and a fix chosen to fade soon while a lasting one fits.
COACH_CONDITIONS = ["blamed", "fading_fix"]
BELT_XP = [0, 2000, 6000, 30000, 110000]  # Progression.BELTS
# The least share of a solve mission's reward a player earns (Missions.reward_share
# at the lowest score, 5 of 25): the hard case for reaching every mission.
MIN_REWARD_SHARE = 0.6
MISSION_KEYS = {"id", "name", "kind", "tier", "requires", "briefing", "debrief", "fail", "goal", "deadline_days",
                "fail_closes", "rewards", "insights", "teaches", "check_days", "setup", "act", "chapter", "arc",
                "fork", "debrief_first", "reopen", "sets_flags", "questions", "debrief_variants", "containment",
                "ends_with_talk", "deadline_beat", "grant_tools", "steps", "talk_to", "scene", "opens_on",
                "deadline_on_day", "sets_flags_on_fail", "payoff"}
# The objective line's steps (game/src/rules/objective.gd STEPS, MAX_CHARS): a main or
# training mission may word its own; the problem steps need a goal with a problem; `go`
# is a scene milestone's way to its room.
OBJECTIVE_STEPS = ["look", "again", "dig", "a3", "wait", "check", "act", "talk", "go"]
PROBLEM_STEPS = {"dig", "a3", "wait", "check", "act"}
# The steps each goal can reach (Objective._where): a main mission words every one of
# them, so its objective is authored at every state (phase-2 design §3.1).
GOAL_STEPS = {
    "walk": ["look"], "observe": ["look"], "investigate": ["look", "dig"],
    "solve": ["look", "dig", "a3", "wait", "check", "act"], "check": ["look", "dig", "a3", "wait", "check"],
    "rework_fix": ["a3", "wait", "check", "act"], "sustain": [], "talk_to": ["talk"],
    "scene": ["go"], "story_order": [],
}
MAX_STEP_CHARS = 60
# A safety mission's containment (audit §2.4.1): a short measure against an
# acute risk, taken once while the mission is active; it fades after `days`.
CONTAINMENT_KEYS = {"name", "budget", "days", "effects"}
MAX_CONTAINMENT_DAYS = 30  # containment buys time for the fix; it is not the fix
# Missions.DEBRIEF_VARIANTS, in the order they win; too_early is said at a failed Check
# (Missions.check_debrief: the designed failed Checks, 2026-10-16 spec).
DEBRIEF_VARIANTS = ["blamed", "poor_fix", "not_standardised", "too_early"]
REQUIRES_KEYS = {"missions", "belt", "maturity", "reputation", "trust", "any_of", "facts"}
FORK_ROLES = ["bottleneck", "non_bottleneck"]
MAX_ACT = 6  # Act 0 is the training week; Act VI the IT value streams
TRUST_RANGE = (-2, 1)  # Region.TRUST_MIN, TRUST_MAX
DEFAULT_REPUTATION = {"main": 5, "side": 2}  # Reputation.MAIN_MISSION, SIDE_MISSION
START_REPUTATION = 30  # Reputation.START


def validate_missions(doc: Any, source: str) -> None:
    """The campaign: the coach's questions per stage and the missions (CLAUDE.md §2)."""
    _require_strings(doc, [], source)
    coach = _mapping(doc, "coach", {"name", "role", "stages", "conditional"}, source)
    conditional = _mapping(coach, "conditional", set(COACH_CONDITIONS), f"{source} coach")
    _require_strings(conditional, list(conditional), f"{source} coach conditional")
    _require_strings(coach, ["name", "role"], f"{source} coach")
    stages = coach.get("stages")
    if not isinstance(stages, dict) or sorted(stages) != sorted(COACH_STAGES):
        raise ContentError(f"{source} coach: 'stages' must give questions for {', '.join(COACH_STAGES)}")
    for stage in COACH_STAGES:
        _string_list(stages, stage, f"{source} coach stages", allow_empty=False)
    beats: set[str] = set()
    for m in _entries(doc, "missions", source):
        where = f"{source}: mission '{m['id']}'"
        _known_keys(m, MISSION_KEYS, where)
        _one_of(m, "kind", MISSION_KINDS, where)
        _number(m, "tier", where, 1, 4, integer=True)
        _require_strings(m, ["briefing", "debrief"], where)
        _validate_requires(_mapping(m, "requires", REQUIRES_KEYS, where), f"{where} requires")
        _validate_story(m, where)
        _validate_goal(m.get("goal"), where)
        if "deadline_days" in m:
            if m["kind"] == "training":
                raise ContentError(f"{where}: a training mission has no deadline (it is practice)")
            _number(m, "deadline_days", where, 1, integer=True)
            _require_strings(m, ["fail"], where)
        fail_closes = _string_list(m, "fail_closes", where)
        if fail_closes and "deadline_days" not in m:
            raise ContentError(f"{where}: 'fail_closes' needs a deadline")
        _validate_milestone(m, where)
        _validate_deadline_beat(m, where, beats)
        if "check_days" in m:
            if "problem" not in m["goal"]:
                raise ContentError(f"{where}: 'check_days' needs a goal with a problem")
            _number(m, "check_days", where, 1, MAX_CHECK_DAYS, integer=True)
        _string_list(m, "teaches", where)
        if "setup" in m:
            # A staged situation for a training day's lesson (not a real number).
            if m["kind"] != "training":
                raise ContentError(f"{where}: only a training day has a setup")
            setup = _effects_shape({"effects": m["setup"]}, f"{where} setup")
            if any(e["property"] == KPI_EFFECT for e in setup):
                raise ContentError(f"{where} setup: a setup changes the simulation, not the KPI board")
        if "containment" in m:
            _validate_containment(m, where)
        rewards = _mapping(m, "rewards", {"xp", "budget", "reputation", "trust"}, where)
        for key in ("xp", "budget"):
            _number(rewards, key, f"{where} rewards", 0, integer=True, default=0)
        _number(rewards, "reputation", f"{where} rewards", 0, 20, integer=True, default=0)
        _trust_map(rewards, f"{where} rewards", -3, 3)
        _sets_flags(m, where)
        for tool in _string_list(m, "grant_tools", where):
            if tool not in TOOLS:
                raise ContentError(f"{where}: grant_tools names an unknown tool {tool!r}")
        variants = _mapping(m, "debrief_variants", set(DEBRIEF_VARIANTS), where)
        _require_strings(variants, list(variants), f"{where} debrief_variants")
        if variants and "problem" not in m["goal"]:
            raise ContentError(f"{where}: 'debrief_variants' read the play on the goal's problem")
        for key in ("insights", "questions"):
            lines = m.get(key, {})
            if lines and m["kind"] not in COACHED_KINDS:
                raise ContentError(f"{where}: only main and training missions get the coach's {key}")
            if not isinstance(lines, dict) or any(
                    stage not in COACH_STAGES or not (isinstance(t, str) and t.strip() or isinstance(t, list) and t
                                                      and all(isinstance(x, str) and x.strip() for x in t))
                    for stage, t in lines.items()):
                raise ContentError(f"{where}: '{key}' maps a coach stage to a text or a list of texts")
        _validate_talk_goals(m, where)
        _validate_steps(m, where)


def _opens_on_day(m: dict, where: str) -> int | None:
    """The day of play `opens_on` names ({day: N} or {date: "YYYY-MM-DD"} from PLAY_START), or None."""
    if "opens_on" not in m:
        return None
    on = m["opens_on"]
    shape = f"{where}: 'opens_on' is {{day: N}} or {{date: \"YYYY-MM-DD\"}}"
    if not isinstance(on, dict) or len(on) != 1 or not set(on) <= {"day", "date"}:
        raise ContentError(shape)
    if "day" in on:
        return int(_number(on, "day", where, 0, integer=True))
    try:
        when = date.fromisoformat(on["date"]) if isinstance(on["date"], str) else None
    except ValueError:
        when = None
    if when is None:
        raise ContentError(shape)
    if when < PLAY_START:
        raise ContentError(f"{where}: 'opens_on' {when} is before the first day of play ({PLAY_START})")
    return (when - PLAY_START).days


def _validate_milestone(m: dict, where: str) -> None:
    """A milestone (and only a milestone) has a scene or story_order goal; dates count days of
    play; a deadline on a day of play is told (`fail`) and may set flags for later acts."""
    goal = m["goal"]
    if (m["kind"] == "milestone") != (goal["type"] in MILESTONE_GOALS):
        raise ContentError(f"{where}: a milestone, and only a milestone, has a scene or story_order goal")
    if goal["type"] == "scene":
        _require_strings(m, ["scene"], where)
    elif "scene" in m:
        raise ContentError(f"{where}: 'scene' is for a scene goal")
    opens = _opens_on_day(m, where)
    if "deadline_on_day" in m:
        if m["kind"] == "training":
            raise ContentError(f"{where}: a training mission has no deadline (it is practice)")
        due = _number(m, "deadline_on_day", where, 1, integer=True)
        _require_strings(m, ["fail"], where)
        if opens is not None and due < opens:
            raise ContentError(f"{where}: deadline_on_day {due} falls before it opens (day {opens})")
    if goal["type"] == "story_order":
        _one_of(goal, "story", STORIES, f"{where} goal")
        _one_of(goal, "by", STORY_BY, f"{where} goal")
        _validate_needs(goal["met_if"], f"{where} goal met_if")
        if "promise" in goal:
            _require_strings(goal, ["promise"], f"{where} goal")
        if "deadline_on_day" not in m:
            raise ContentError(f"{where}: a story_order goal is judged on its deadline_on_day")
    if _sets_flags(m, where, "sets_flags_on_fail") and not ("deadline_days" in m or "deadline_on_day" in m):
        raise ContentError(f"{where}: 'sets_flags_on_fail' needs a deadline")
    payoff = m.get("payoff", [])
    if not isinstance(payoff, list) or not all(isinstance(e, dict) for e in payoff):
        raise ContentError(f"{where}: 'payoff' lists {{who, by, text}}")
    for e in payoff:
        _known_keys(e, PAYOFF_KEYS, f"{where} payoff")
        _require_strings(e, ["who", "text"], f"{where} payoff")
        _one_of(e, "by", PAYOFF_BY, f"{where} payoff")


def _validate_talk_goals(m: dict, where: str) -> None:
    """The talks a mission needs besides its goal (MissionDef.talk_goals): each a dialog
    and the least outcome that meets it (checked against dialogs.yaml later)."""
    talks = m.get("talk_to", [])
    if not isinstance(talks, list):
        raise ContentError(f"{where}: 'talk_to' lists talks: [{{dialog, outcome}}]")
    for t in talks:
        if not isinstance(t, dict):
            raise ContentError(f"{where}: 'talk_to' lists talks: [{{dialog, outcome}}]")
        _known_keys(t, {"dialog", "outcome"}, f"{where} talk_to")
        if "dialog" not in t:
            raise ContentError(f"{where} talk_to: needs a 'dialog'")
        _require_strings(t, ["dialog"], f"{where} talk_to")
        if "outcome" in t:
            _one_of(t, "outcome", TALK_OUTCOMES, f"{where} talk_to")


def _validate_steps(m: dict, where: str) -> None:
    """The objective line's own words per step (Objective): short, and only for a step
    the goal has; `look` may map an observe goal's places to their texts. A main mission
    words every step its goal can reach (and its talk, when it has one)."""
    steps = _mapping(m, "steps", set(OBJECTIVE_STEPS), where)
    goal = m["goal"]
    if m["kind"] in ("main", "milestone"):
        needed = GOAL_STEPS[goal["type"]] + (["talk"] if _has_talk(m) and goal["type"] != "talk_to" else [])
        missing = [key for key in needed if key not in steps]
        if missing:
            raise ContentError(f"{where} steps: a main mission words every step its goal reaches; "
                               f"missing {', '.join(missing)}")
    for key, text in steps.items():
        if key == "look" and isinstance(text, dict):
            if goal["type"] != "observe":
                raise ContentError(f"{where} steps: 'look' per place only for an observe goal")
            for place, line in text.items():
                if place not in goal.get("places", []):
                    raise ContentError(f"{where} steps: {place!r} is not one of the goal's places")
                _step_text(line, f"{where} steps look {place}", key)
        else:
            _step_text(text, f"{where} steps", key)
        if key == "again" and goal["type"] != "observe":
            raise ContentError(f"{where} steps: 'again' is for an observe goal")
        if key == "talk" and goal["type"] != "talk_to" and not _has_talk(m):
            raise ContentError(f"{where} steps: 'talk' needs a talk (a talk_to goal or ends_with_talk)")
        if key == "go" and goal["type"] != "scene":
            raise ContentError(f"{where} steps: 'go' leads to a milestone's scene")
        if key in PROBLEM_STEPS and "problem" not in goal:
            raise ContentError(f"{where} steps: '{key}' needs a goal with a problem")


def _has_talk(m: dict) -> bool:
    """The mission waits for a talk besides its goal (ends_with_talk, talk_to goals)."""
    return bool(m.get("ends_with_talk") or m.get("talk_to"))


def _step_text(text: Any, where: str, key: str) -> None:
    if not isinstance(text, str) or not text.strip():
        raise ContentError(f"{where}: '{key}' must be a non-empty string")
    if len(text) > MAX_STEP_CHARS:
        raise ContentError(f"{where}: '{key}' is one line on the HUD: at most {MAX_STEP_CHARS} characters")


def _check_step_words(m: dict, where: str, problems: dict, cms: list[dict], tool_titles: list[str]) -> None:
    """The objective names where and with whom, never how or what is wrong: no tool,
    problem or countermeasure (id or name) in a step's text."""
    names = list(TOOLS) + tool_titles + [n for p in problems.values() for n in (p["id"], p.get("name", ""))] \
        + [n for c in cms for n in (c["id"], c.get("name", ""))]
    for text in m.get("steps", {}).values():
        for line in text.values() if isinstance(text, dict) else [text]:
            for name in names:
                if len(name) >= 4 and re.search(rf"(?<!\w){re.escape(name.lower())}(?!\w)", line.lower()):
                    raise ContentError(f"{where} steps: {line!r} names {name!r}: the how is the player's")


def _validate_deadline_beat(m: dict, where: str, beats: set[str]) -> None:
    """A dated beat (drie winters S2) falls on its mission's deadline day: it
    needs that deadline, and names a beat no other mission does. `beats`
    collects the names seen so far."""
    if "deadline_beat" not in m:
        return
    beat = m["deadline_beat"]
    if not isinstance(beat, str) or not _ID.match(beat):
        raise ContentError(f"{where}: 'deadline_beat' must be an id")
    if "deadline_days" not in m:
        raise ContentError(f"{where}: 'deadline_beat' falls on the deadline's day: needs deadline_days")
    if beat in beats:
        raise ContentError(f"{where}: 'deadline_beat' {beat!r} is already another mission's")
    beats.add(beat)


def _validate_containment(m: dict, where: str) -> None:
    if "problem" not in m["goal"]:
        raise ContentError(f"{where}: a containment needs a goal with a problem (it holds the risk while that is fixed)")
    containment = _mapping(m, "containment", CONTAINMENT_KEYS, where)
    where = f"{where} containment"
    _require_strings(containment, ["name"], where)
    _number(containment, "budget", where, 0, integer=True, default=0)
    _number(containment, "days", where, 1, MAX_CONTAINMENT_DAYS, integer=True)
    effects = _effects_shape(containment, where)
    if not effects:
        raise ContentError(f"{where}: a containment needs effects")
    if any(e["property"] == KPI_EFFECT for e in effects):
        raise ContentError(f"{where}: a containment changes the simulation, not the KPI board")


def _trust_map(item: dict, where: str, low: int, high: int) -> dict:
    """An optional {team: n} mapping (teams are checked against the pools later)."""
    trust = item.get("trust", {})
    if not isinstance(trust, dict):
        raise ContentError(f"{where}: 'trust' must map teams to a number")
    for team in trust:
        _number(trust, team, f"{where} trust", low, high, integer=True)
    return trust


def _validate_requires(requires: dict, where: str) -> None:
    """Gates: missions done, a belt, the region's maturity and reputation,
    a team's trust, one of a set of missions (after a fork) and facts."""
    _string_list(requires, "missions", where)
    _string_list(requires, "any_of", where)
    _number(requires, "belt", where, 0, len(BELT_XP) - 1, integer=True, default=0)
    _number(requires, "maturity", where, *MEASURES["maturity"], integer=True, default=1)
    _number(requires, "reputation", where, *MEASURES["reputation"], integer=True, default=0)
    _trust_map(requires, where, *TRUST_RANGE)
    if "facts" in requires:
        _validate_needs(requires["facts"], where)


def _validate_story(m: dict, where: str) -> None:
    """Story as data: act, chapter, arc; fork metadata; the reopen text."""
    if "act" in m:
        _number(m, "act", where, 0, MAX_ACT, integer=True)
    _require_strings(m, [k for k in ("chapter", "reopen", "debrief_first") if k in m], where)
    if "arc" in m and not (isinstance(m["arc"], str) and _ID.match(m["arc"])):
        raise ContentError(f"{where}: 'arc' must be an id such as sector or henk")
    if "fork" in m:
        fork = _mapping(m, "fork", {"group", "role"}, where)
        if m["kind"] != "main" or not isinstance(fork.get("group"), str) or not _ID.match(fork["group"]):
            raise ContentError(f"{where}: a fork is between main missions and needs a 'group' id")
        _one_of(fork, "role", FORK_ROLES, f"{where} fork")
    elif "debrief_first" in m:
        raise ContentError(f"{where}: 'debrief_first' is for a fork branch done first")


def _validate_goal(goal: Any, where: str) -> None:
    if not isinstance(goal, dict) or goal.get("type") not in MISSION_GOALS:
        raise ContentError(f"{where}: 'goal' needs a type: {', '.join(MISSION_GOALS)}")
    required, optional = MISSION_GOALS[goal["type"]]
    _known_keys(goal, {"type"} | required | optional, f"{where} goal")
    for key in required:
        if key not in goal:
            raise ContentError(f"{where} goal: needs '{key}'")
    _require_strings(goal, sorted(required & {"stream", "problem"}), f"{where} goal")
    if goal["type"] == "investigate":
        _number(goal, "clues", f"{where} goal", 1, integer=True)
    if goal["type"] == "talk_to":
        _require_strings(goal, ["dialog"], f"{where} goal")
        if "outcome" in goal:
            _one_of(goal, "outcome", TALK_OUTCOMES, f"{where} goal")
    if goal["type"] == "observe":
        places = _string_list(goal, "places", f"{where} goal", allow_empty=False)
        if "tool" in goal and goal["tool"] not in TOOLS:
            raise ContentError(f"{where} goal: unknown tool {goal['tool']!r}")
        tools = 1 if "tool" in goal else len(TOOLS)
        _number(goal, "uses", f"{where} goal", 1, tools * len(places), integer=True, default=1)


def check_missions(docs: dict[str, Any]) -> None:
    """Missions against problems and value streams, and the campaign as a
    whole: every problem solved by one mission, no cycles, a way in, and
    every mission reachable."""
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    streams = {s["id"] for s in docs["value_streams"]["streams"]}
    net = _network_index(docs["value_streams"], docs["kpis"])
    steps = net["step"]
    problems = {p["id"]: p for _, p in _all_problems(docs)}
    pools = {p["id"] for p in docs["value_streams"]["pools"]}
    cms = docs["countermeasures"]["countermeasures"]
    tool_titles = [str(c.get("title", "")) for c in docs.get("places", {}).get("tool_cards", [])]
    solved: dict[str, str] = {}
    for m in missions.values():
        where = f"missions.yaml: mission '{m['id']}'"
        _check_step_words(m, where, problems, cms, tool_titles)
        requires = m.get("requires", {})
        for req in requires.get("missions", []) + requires.get("any_of", []):
            if req not in missions:
                raise ContentError(f"{where}: requires unknown mission {req!r}")
        for team in list(requires.get("trust", {})) + list(m.get("rewards", {}).get("trust", {})):
            if team not in pools:
                raise ContentError(f"{where}: trust of unknown team {team!r}")
        for e in m.get("setup", []):
            _check_effect(e, f"{where} setup", net)
        for e in m.get("containment", {}).get("effects", []):
            _check_effect(e, f"{where} containment", net)
        goal = m["goal"]
        if goal["type"] == "walk" and goal["stream"] not in streams:
            raise ContentError(f"{where}: unknown stream {goal['stream']!r}")
        for place in goal.get("places", []):
            if place not in steps:
                raise ContentError(f"{where}: unknown place {place!r}")
            if steps[place]["kind"] != "work":
                raise ContentError(f"{where}: {place!r} has no team to watch (not a work step)")
        if "problem" in goal:
            p = problems.get(goal["problem"])
            if p is None:
                raise ContentError(f"{where}: unknown problem {goal['problem']!r}")
            keys = sum(1 for c in p["clues"] if c["key"])
            # A missed deadline closes a door, never the last one (CLAUDE.md §2),
            # for every problem that shares a closed countermeasure.
            closes = set(m.get("fail_closes", []))
            for cm in closes - set(p["countermeasures"]):
                raise ContentError(f"{where}: closes {cm!r}, which problem {p['id']!r} does not list")
            for other in problems.values():
                if closes & set(other["countermeasures"]) and set(other["countermeasures"]) <= closes:
                    raise ContentError(f"{where}: a missed deadline leaves no other way to solve {other['id']!r}")
            if goal["type"] == "investigate" and goal["clues"] > keys:
                raise ContentError(f"{where}: asks for {goal['clues']} key clues, the problem has {keys}")
            if goal["type"] == "solve":
                if goal["problem"] in solved:
                    raise ContentError(f"{where}: problem {goal['problem']!r} is already solved in mission {solved[goal['problem']]!r}")
                solved[goal["problem"]] = m["id"]
    unsolved = sorted(set(problems) - set(solved))
    if unsolved:
        raise ContentError(f"missions.yaml: no mission solves {', '.join(unsolved)} (the campaign reaches every problem)")
    _check_forks(missions)
    index = _fact_index(docs)
    for m in missions.values():
        if "facts" in m.get("requires", {}):
            _check_needs(m["requires"]["facts"], f"missions.yaml: mission '{m['id']}' requires", index)
        if m["goal"]["type"] == "story_order":
            _check_story_order(m, index)
    gated = set()
    for cm in docs["countermeasures"]["countermeasures"]:
        if "needs" in cm:
            _check_needs(cm["needs"], f"countermeasures.yaml: '{cm['id']}'", index)
            gated.add(cm["id"])
    for p in problems.values():
        if set(p["countermeasures"]) <= gated:
            raise ContentError(f"{p['id']}: no countermeasure without 'needs' (one way must need no preparation)")
    if not any(m["kind"] in COACHED_KINDS and not m.get("requires") for m in missions.values()):
        raise ContentError("missions.yaml: no main or training mission is open from the start")
    stuck = sorted(set(missions) - _reachable(missions, problems, index))
    if stuck:
        raise ContentError(f"missions.yaml: missions that can never unlock (a cycle, too little XP, reputation, "
                           f"maturity or facts): {', '.join(stuck)}")


def _check_story_order(m: dict, index: dict) -> None:
    """The facts that meet the story's order name real things; the promise is a call whose
    agreement can name a delivery date."""
    where = f"missions.yaml: mission '{m['id']}' goal"
    for atoms in m["goal"]["met_if"].values():
        for atom in atoms:
            _atom_robust(atom, where, index)
    promise = m["goal"].get("promise")
    if promise is not None and index["dialogs"] is not None and promise not in index["dialogs"]:
        raise ContentError(f"{where}: 'promise' names an unknown dialog {promise!r}")


def _check_forks(missions: dict) -> None:
    """A fork: one bottleneck and at least one non-bottleneck main mission,
    opening together (the same requires)."""
    groups: dict[str, list[dict]] = {}
    for m in missions.values():
        if "fork" in m:
            groups.setdefault(m["fork"]["group"], []).append(m)
    for group, branches in groups.items():
        roles = Counter(b["fork"]["role"] for b in branches)
        if roles["bottleneck"] != 1 or roles["non_bottleneck"] < 1:
            raise ContentError(f"missions.yaml: fork {group!r} needs one bottleneck and at least one non-bottleneck branch")
        if any(b.get("requires", {}) != branches[0].get("requires", {}) for b in branches):
            raise ContentError(f"missions.yaml: fork {group!r}: its branches must open together (the same requires)")


def _fact_index(docs: dict[str, Any]) -> dict:
    """What facts content can name, and which choices a missed deadline can
    take away for good (its fail_closes)."""
    missions = docs["missions"]["missions"]
    dialogs = (docs.get("dialogs") or {}).get("dialogs")
    return {
        "missions": {m["id"] for m in missions},
        "deadlines": {m["id"] for m in missions if "deadline_days" in m or "deadline_on_day" in m},
        "problems": {p["id"]: set(p["countermeasures"]) for _, p in _all_problems(docs)},
        "fork_members": {(m["fork"]["group"], m["id"]) for m in missions if "fork" in m},
        "flags_by": _flags_by(docs),
        "flags": set().union(*_flags_by(docs).values()),
        "closable": {c for m in missions for c in m.get("fail_closes", [])},
        "solved_by": {m["goal"]["problem"]: m["id"] for m in missions if m["goal"]["type"] == "solve"},
        # dialog id → its proposals, and the people (None: a content set without dialogs)
        "dialogs": {d["id"]: {p["id"] for p in d.get("proposals", [])} for d in dialogs} if dialogs is not None else None,
        "people": {p["id"] for p in docs["dialogs"]["people"]} if dialogs is not None else None,
    }


def _flags_by(docs: dict[str, Any]) -> dict[str, set]:
    """mission id → the flags it can set: done (sets_flags), missed (sets_flags_on_fail),
    or answered in its scene."""
    scenes = _scene_flags(docs)
    return {m["id"]: set(m.get("sets_flags", [])) | set(m.get("sets_flags_on_fail", [])) | scenes.get(m.get("scene"), set())
            for m in docs["missions"]["missions"]}


def _check_needs(needs: dict, where: str, index: dict) -> None:
    """Every fact names something real, and every route stays open: an 'all'
    fact, or every 'any' fact, that a missed deadline can take away for good
    would close the option for good (CLAUDE.md §2: setbacks, never game over)."""
    def robust(atom: str) -> bool:
        return _atom_robust(atom, where, index)
    if not all(robust(a) for a in needs.get("all", [])) or ("any" in needs and not any([robust(a) for a in needs["any"]])):
        raise ContentError(f"{where}: a missed deadline can close this route for good (keep another way open)")
    for atom in needs.get("none", []):
        robust(atom)


def _atom_robust(atom: str, where: str, index: dict) -> bool:
    """Whether no missed deadline can take `atom` away for good; raises when it
    names something that does not exist."""
    kind, ids = _atom_parts(atom, where)
    if kind in ("done", "accepted") and ids[0] not in index["missions"] or kind == "failed" and ids[0] not in index["deadlines"]:
        raise ContentError(f"{where}: {atom!r} names no such mission{' with a deadline' if kind == 'failed' else ''}")
    if kind in ("chose", "standardised", "poor_fix", "repaired", "checked", "holds") and ids[0] not in index["problems"]:
        raise ContentError(f"{where}: {atom!r} names an unknown problem")
    if kind == "delivered" and ids[0] not in STORIES:
        raise ContentError(f"{where}: {atom!r} names no followed story ({', '.join(STORIES)})")
    dialogs, people = index.get("dialogs"), index.get("people")
    if kind in ("agreed", "promise_kept", "promise_broken") and dialogs is not None and ids[0] not in dialogs:
        raise ContentError(f"{where}: {atom!r} names an unknown dialog")
    if kind == "agreed" and dialogs is not None and ids[1] not in dialogs[ids[0]]:
        raise ContentError(f"{where}: {atom!r}: dialog {ids[0]!r} has no such proposal")
    if kind == "left" and people is not None and ids[0] not in people:
        raise ContentError(f"{where}: {atom!r} names an unknown person")
    if kind == "chose" and ids[1] not in index["problems"][ids[0]]:
        raise ContentError(f"{where}: {atom!r}: problem {ids[0]!r} does not list that countermeasure")
    if kind == "fork_first" and tuple(ids) not in index["fork_members"]:
        raise ContentError(f"{where}: {atom!r} names no branch of that fork")
    if kind == "flag" and atom not in index["flags"]:
        raise ContentError(f"{where}: {atom!r}: no mission sets that flag")
    return not (kind == "chose" and ids[1] in index["closable"])


def _fact_reachable(atom: str, done: set, maturity: int, reputation: int, index: dict) -> bool:
    """Whether a fact can hold once the missions in `done` are done (the
    player's choices and luck taken at their best)."""
    kind, ids = _atom_parts(atom, "needs")
    if kind == "measure":
        return (maturity if ids[0] == "maturity" else reputation) >= int(ids[1])
    if kind in ("done", "fork_first", "accepted"):
        return ids[-1] in done
    if kind == "failed":
        return True  # a deadline can always be missed
    if kind in ("chose", "standardised", "poor_fix", "repaired", "checked"):
        return index["solved_by"].get(ids[0]) in done
    if kind == "flag":
        return any(atom in m_flags for m_id, m_flags in index["flags_by"].items() if m_id in done)
    return True  # dialog facts: checked once dialogs exist


def _reachable(missions: dict, problems: dict, index: dict) -> set[str]:
    """Play the campaign forward: complete whatever is unlocked, earning only
    the missions' own XP and reputation, solve missions at their lowest share
    (problems give more XP, so this is the hard case). Maturity follows the
    problems the done missions solve; trust can always be repaired."""
    practice = {m["goal"].get("problem") for m in missions.values() if m["kind"] == "training"}
    done: set[str] = set()
    xp, reputation = 0, START_REPUTATION
    progressed = True
    while progressed:
        progressed = False
        maturity = _maturity(problems, practice, done, index)
        for m in missions.values():
            req = m.get("requires", {})
            facts = req.get("facts", {})
            open_now = (m["id"] not in done and xp >= BELT_XP[req.get("belt", 0)]
                        and all(r in done for r in req.get("missions", []))
                        and (not req.get("any_of") or any(r in done for r in req["any_of"]))
                        and maturity >= req.get("maturity", 1) and reputation >= req.get("reputation", 0)
                        and all(_fact_reachable(a, done, maturity, reputation, index) for a in facts.get("all", []))
                        and (not facts.get("any") or any(_fact_reachable(a, done, maturity, reputation, index)
                                                         for a in facts["any"])))
            if open_now:
                done.add(m["id"])
                rewards = m.get("rewards", {})
                share = MIN_REWARD_SHARE if m["goal"]["type"] == "solve" else 1.0
                xp += int(rewards.get("xp", 0) * share)
                reputation = min(100, reputation + rewards.get("reputation", DEFAULT_REPUTATION.get(m["kind"], 0)))
                progressed = True
    return done


def _maturity(problems: dict, practice: set, done: set, index: dict) -> int:
    """Region.maturity: a tier counts once MATURITY_STEP of its (non-practice)
    problems are solved."""
    level = 1
    while level < 4:
        tier = [p for p in problems.values() if p["tier"] == level and p["id"] not in practice]
        solved = [p for p in tier if index["solved_by"].get(p["id"]) in done]
        if not tier or len(solved) < len(tier) * MATURITY_STEP:
            break
        level += 1
    return level


# ── world.yaml (the head office: floors and rooms, PLAN 2.1) ─────────────────
WORLD_FLOOR_KEYS = {"id", "name", "level", "outside_of", "model"}
WORLD_ROOM_KEYS = {"id", "floor", "name", "places", "opens_with"}
# The van ride (design §1.7): a side rides out with its monteur from the van park.
WORLD_RIDE_KEYS = {"mission", "with", "to"}
VAN_ROOM = "van_park"
_MODEL = re.compile(r"^[a-z][a-z0-9_]*\.glb$")
# Missions made during play (game/src/rules/missions.gd CHECKIN_PREFIX, repairs.gd
# PREFIX): a room may open with any of them ("terugval_*").
DYNAMIC_MISSION_PREFIXES = ["terugval_", "repair_"]
OPEN_FROM_START = "start"


def validate_world(doc: Any, source: str) -> None:
    if not isinstance(doc, dict):
        raise ContentError(f"{source}: expected a mapping at the top level")
    _known_keys(doc, {"start_floor", "floors", "rooms", "rides", "tells"}, source)
    floors = _entries(doc, "floors", source)
    levels: dict[int, str] = {}
    for f in floors:
        where = f"{source}: floor '{f['id']}'"
        _known_keys(f, WORLD_FLOOR_KEYS, where)
        if ("level" in f) == ("outside_of" in f):
            # an outside area (the yard) is reached by a door from its floor, never by the stairs
            raise ContentError(f"{where}: needs either a level or 'outside_of' (an outside area)")
        if "level" in f:
            level = int(_number(f, "level", where, 0, 9, integer=True))
            if level in levels:
                raise ContentError(f"{where}: two floors on level {level} ({levels[level]!r} too)")
            levels[level] = f["id"]
        if not isinstance(f.get("model"), str) or not _MODEL.match(f["model"]):
            raise ContentError(f"{where}: 'model' must be a .glb file name (lowercase, no folders)")
    floor_ids = {f["id"] for f in floors}
    for f in floors:
        if "outside_of" in f and f["outside_of"] not in levels.values():
            raise ContentError(f"{source}: floor '{f['id']}': outside of unknown floor {f['outside_of']!r}")
    if doc.get("start_floor") not in floor_ids:
        raise ContentError(f"{source}: start_floor {doc.get('start_floor')!r} is not a floor")
    rooms = _entries(doc, "rooms", source)
    for r in rooms:
        where = f"{source}: room '{r['id']}'"
        _known_keys(r, WORLD_ROOM_KEYS, where)
        if r.get("floor") not in floor_ids:
            raise ContentError(f"{where}: unknown floor {r.get('floor')!r}")
        for key in ("places", "opens_with"):
            if not isinstance(r.get(key), list) or not all(isinstance(x, str) and x for x in r[key]):
                raise ContentError(f"{where}: '{key}' must be a list of texts")
    for f in floors:
        if not any(r["floor"] == f["id"] for r in rooms):
            raise ContentError(f"{source}: floor '{f['id']}' has no rooms")
    rides = doc.get("rides", [])
    if not isinstance(rides, list) or not all(isinstance(r, dict) for r in rides):
        raise ContentError(f"{source}: 'rides' must be a list of mappings")
    for ride in rides:
        where = f"{source}: ride {ride.get('mission')!r}"
        _known_keys(ride, WORLD_RIDE_KEYS, where)
        _require_strings(ride, sorted(WORLD_RIDE_KEYS), where)
    if "tells" in doc:
        for t in _entries(doc, "tells", source, name="place"):
            where = f"{source}: tell '{t['id']}'"
            _known_keys(t, WORLD_TELL_KEYS, where)
            _require_strings(t, ["place", *TELL_HEIGHTS], where)


def _mission_places(m: dict, problems: dict, streams: dict) -> set[str]:
    """The places a mission leads the player to: its goal's places, its walk's
    steps, its problem's step and the places of the problem's clues."""
    goal = m["goal"]
    places = set(goal.get("places", []))
    if goal["type"] == "walk":
        places |= {f"{goal['stream']}.{s['id']}" for s in streams[goal["stream"]]["steps"]}
    p = problems.get(goal.get("problem"))
    if p is not None:
        places.add(p["step"])
        places |= {c.get("at", p["step"]) for c in p.get("clues", [])}
    return places


def _check_rides(world: dict, missions: dict, room_of: dict[str, str]) -> None:
    """A ride: one per mission, which opens the van park; its monteur is in the cast with a
    van; it ends at a place on the yard in a room the mission opens."""
    rooms = {r["id"]: r for r in world["rooms"]}
    vans = {str(c["id"]): (c.get("office") or {}).get("van") for c in _cast_entries()}
    seen: set[str] = set()
    for ride in world.get("rides", []):
        mission, who, to = ride["mission"], ride["with"], ride["to"]
        where = f"world.yaml: ride {mission!r}"
        if mission not in missions:
            raise ContentError(f"world.yaml: ride: unknown mission {mission!r}")
        if mission in seen:
            raise ContentError(f"{where}: two rides for mission {mission!r}")
        seen.add(mission)
        if who not in vans:
            raise ContentError(f"{where}: {who!r} is not in the cast ({CAST_FILE.name})")
        if not isinstance(vans[who], int) or isinstance(vans[who], bool):
            raise ContentError(f"{where}: {who!r} has no van (cast.json office.van)")
        room = rooms.get(room_of.get(to, ""))
        if room is None or room["floor"] != "yard":
            raise ContentError(f"{where}: {to!r} is not a place on the yard")
        for needed in (room, rooms.get(VAN_ROOM)):
            if needed is not None and mission not in needed["opens_with"]:
                raise ContentError(f"{where}: room '{needed['id']}' does not open with it")


def check_world(docs: dict[str, Any]) -> None:
    """Rooms against the network and the missions: every place is a step and
    lies in one room; every opener is a mission (or a kind made in play); and
    a mission that leads to a room's place opens that room."""
    world = docs.get("world")
    if world is None:
        return
    steps = _network_index(docs["value_streams"], docs["kpis"])["step"]
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    problems = {p["id"]: p for _, p in _all_problems(docs)}
    streams = {s["id"]: s for s in docs["value_streams"]["streams"]}
    room_of: dict[str, str] = {}
    for r in world["rooms"]:
        where = f"world.yaml: room '{r['id']}'"
        for place in r["places"]:
            if place not in steps:
                raise ContentError(f"{where}: unknown place {place!r}")
            if place in room_of:
                raise ContentError(f"{where}: {place!r} is in two rooms ({room_of[place]!r} too)")
            room_of[place] = r["id"]
        for opener in r["opens_with"]:
            dynamic = opener.endswith("*") and opener[:-1] in DYNAMIC_MISSION_PREFIXES
            if opener != OPEN_FROM_START and opener not in missions and not dynamic:
                raise ContentError(f"{where}: opens with unknown mission {opener!r}")
    rooms = {r["id"]: r for r in world["rooms"]}
    for m in missions.values():
        for place in sorted(_mission_places(m, problems, streams)):
            room = rooms.get(room_of.get(place, ""))
            if room is not None and OPEN_FROM_START not in room["opens_with"] and m["id"] not in room["opens_with"]:
                raise ContentError(f"world.yaml: mission '{m['id']}' leads to {place!r} in room '{room['id']}', "
                                   f"which does not open with it")
    _check_rides(world, missions, room_of)
    for f in world["floors"]:
        if not (OFFICE_ASSETS / f["model"]).is_file():
            # The game would load the stand-in office for this floor without a word.
            raise ContentError(f"world.yaml: floor '{f['id']}': model {f['model']!r} does not exist in "
                               f"{OFFICE_ASSETS.relative_to(ROOT).as_posix()}")


# ── places.yaml (what a player can do at a place, PLAN 2.12) ─────────────────
# Per place: the gemba tools that fit the work there, each with the place's own
# label and its observations (shown when a tool finds no clue), the questions to
# the people who work there, and who else can be met there (people_also). And
# one tool card per tool for Ruud's morning note (game/src/rules/place_actions.gd;
# design: docs/superpowers/specs/2026-10-18-place-actions.md §6).
PLACE_KEYS = {"people_also", "tools", "questions"}
PLACE_TOOL_KEYS = {"label", "observations"}
PLACE_QUESTION_KEYS = {"id", "person", "text", "reply"}
TOOL_CARD_KEYS = {"tool", "title", "text"}
PLACE_TOOLS = (2, 5)
PLACE_OBSERVATIONS = (2, 3)
MAX_PLACE_QUESTIONS = 4
# Investigation.QUESTIONS: id → kind. `thanks` (repair) is never a chip of its
# own: it shows after a blame or guarded reply.
QUESTION_KINDS = {"walk": "open", "obstacle": "open", "last": "open", "standard": "closed", "ok": "closed",
                  "behind": "blame", "who": "blame", "thanks": "repair"}
_PLACE = re.compile(r"^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$")
# Places in a room whose tools, observations and questions still wait for the
# designer (PLAN 2.12); until then they keep every tool and the team's questions.
# Empty since the magazijn's three places got content (2026-10-18). Shrink this
# set, never grow it.
PLACES_AWAITING_CONTENT: set[str] = set()
# A tool result never says there was nothing (Merijn, 2026-10-18).
_NOTHING = re.compile(r"niets nieuws", re.IGNORECASE)


def validate_places(doc: Any, source: str) -> None:
    if not isinstance(doc, dict):
        raise ContentError(f"{source}: expected a mapping at the top level")
    _known_keys(doc, {"places", "tool_cards"}, source)
    places = doc.get("places")
    if not isinstance(places, dict) or not all(isinstance(p, dict) for p in places.values()):
        raise ContentError(f"{source}: 'places' must map a place 'stream.step' to its entry")
    for place, entry in places.items():
        where = f"{source}: place {place!r}"
        if not isinstance(place, str) or not _PLACE.match(place):
            raise ContentError(f"{where}: a place is named 'stream.step'")
        _known_keys(entry, PLACE_KEYS, where)
        _string_list(entry, "people_also", where)
        _validate_place_tools(entry.get("tools"), where)
        questions = entry.get("questions", [])
        if not isinstance(questions, list) or len(questions) > MAX_PLACE_QUESTIONS \
                or not all(isinstance(q, dict) for q in questions):
            raise ContentError(f"{where}: 'questions' must list at most {MAX_PLACE_QUESTIONS} questions")
        for q in questions:
            _known_keys(q, PLACE_QUESTION_KEYS, f"{where} question")
            _require_strings(q, ["person", "text", "reply"], f"{where} question")
            if q.get("id") not in QUESTION_KINDS or q["id"] == "thanks":
                raise ContentError(f"{where}: question id {q.get('id')!r} must be one of "
                                   f"{', '.join(k for k in QUESTION_KINDS if k != 'thanks')}")
        ids = [q["id"] for q in questions]
        if len(set(ids)) != len(ids):
            raise ContentError(f"{where}: a question id is asked twice")
    cards = doc.get("tool_cards")
    if not isinstance(cards, list) or not all(isinstance(c, dict) for c in cards):
        raise ContentError(f"{source}: 'tool_cards' must be a list of mappings")
    for c in cards:
        _known_keys(c, TOOL_CARD_KEYS, f"{source} tool card")
        _require_strings(c, ["title", "text"], f"{source} tool card {c.get('tool')!r}")
    tools = [c.get("tool") for c in cards]
    if sorted(tools, key=str) != sorted(TOOLS):
        raise ContentError(f"{source}: 'tool_cards' needs exactly one card per tool ({', '.join(sorted(TOOLS))})")


def _validate_place_tools(tools: Any, where: str) -> None:
    low, high = PLACE_TOOLS
    if not isinstance(tools, dict) or not low <= len(tools) <= high:
        raise ContentError(f"{where}: 'tools' must map {low} to {high} tools to their label and observations")
    for tool, t in tools.items():
        if tool not in TOOLS - {"conversation"}:
            raise ContentError(f"{where}: unknown tool {tool!r} (a conversation is the place's questions)")
        if not isinstance(t, dict):
            raise ContentError(f"{where} tool '{tool}': needs a label and observations")
        _known_keys(t, PLACE_TOOL_KEYS, f"{where} tool '{tool}'")
        _require_strings(t, ["label"], f"{where} tool '{tool}'")
        lines = _string_list(t, "observations", f"{where} tool '{tool}'", allow_empty=False)
        n_low, n_high = PLACE_OBSERVATIONS
        if not n_low <= len(lines) <= n_high or not all(isinstance(x, str) and x.strip() for x in lines):
            raise ContentError(f"{where} tool '{tool}': needs {n_low} to {n_high} observations")
        if any(_NOTHING.search(x) for x in lines):
            raise ContentError(f"{where} tool '{tool}': an observation shows something, never 'niets nieuws'")


def _places_used(docs: dict[str, Any]) -> dict[str, str]:
    """Every place the content leads the player to → who leads there: missions
    (their goal's places, a walk's work steps, their problem's), problems (step,
    clue places), discoveries (a full place) and the rooms of world.yaml."""
    missions = docs["missions"]["missions"]
    problems = {p["id"]: p for _, p in _all_problems(docs)}
    streams = {s["id"]: s for s in docs["value_streams"]["streams"]}
    used: dict[str, str] = {}
    for m in missions:
        goal = m["goal"]
        places = set(goal.get("places", []))
        if goal["type"] == "walk":
            places |= {f"{goal['stream']}.{s['id']}" for s in streams[goal["stream"]]["steps"] if s["kind"] == "work"}
        p = problems.get(goal.get("problem"))
        if p is not None:
            places |= {p["step"]} | {c.get("at", p["step"]) for c in p["clues"]}
        for place in places:
            used.setdefault(place, f"mission '{m['id']}'")
    for p in problems.values():
        for place in [p["step"]] + [c.get("at", p["step"]) for c in p["clues"]]:
            used.setdefault(place, f"problem '{p['id']}'")
    for d in docs.get("discoveries", {}).get("discoveries", []):
        place = d["trigger"].get("place")
        if place and not place.endswith("."):
            used.setdefault(place, f"discovery '{d['id']}'")
    for r in docs.get("world", {}).get("rooms", []):
        for place in r["places"]:
            used.setdefault(place, f"room '{r['id']}'")
    return used


def check_places(docs: dict[str, Any]) -> None:
    """Places against the network, the cast, the missions, the clues and the
    discoveries: every place used has an entry; every clue can be found there;
    a question goes to someone who is there; the training week hands out each
    tool once, before a goal needs it (spec §6, validator rules 1-7)."""
    places_doc = docs.get("places")
    if places_doc is None:
        return
    places = places_doc["places"]
    steps = _network_index(docs["value_streams"], docs["kpis"])["step"]
    for place in places:
        if place not in steps:
            raise ContentError(f"places.yaml: unknown place {place!r}")
    for place, who in sorted(_places_used(docs).items()):
        if place not in places and place not in PLACES_AWAITING_CONTENT:
            raise ContentError(f"places.yaml: {who} leads to {place!r}, which has no entry")
    for _, p in _all_problems(docs):
        for i, c in enumerate(p["clues"]):
            at = c.get("at", p["step"])
            where = f"places.yaml: problem '{p['id']}' clue {i} ({c['tool']} at {at!r})"
            if c["tool"] == "conversation":
                if not any(QUESTION_KINDS[q["id"]] == "open" for q in places[at].get("questions", [])):
                    raise ContentError(f"{where}: no open question there, so the clue can never be found")
            elif c["tool"] not in places[at]["tools"]:
                raise ContentError(f"{where}: the tool does not fit the place, so the clue can never be found")
    for d in docs.get("discoveries", {}).get("discoveries", []):
        t = d["trigger"]
        if "tool" in t and t.get("place") in places and t["tool"] not in places[t["place"]]["tools"]:
            raise ContentError(f"places.yaml: discovery '{d['id']}' needs {t['tool']} at {t['place']!r}, "
                               f"which does not fit there")
    if "dialogs" in docs:  # a content set without people has nobody to check the questions against
        _check_place_people(places, {p["id"]: p for p in docs["dialogs"]["people"]})
    _check_grants(docs["missions"]["missions"], places)


def _check_place_people(places: dict, people: dict) -> None:
    for pid, entry in places.items():
        for person in entry.get("people_also", []):
            if person not in people:
                raise ContentError(f"places.yaml: place '{pid}': people_also names unknown person {person!r}")
        for q in entry.get("questions", []):
            person = people.get(q["person"])
            if person is None:
                raise ContentError(f"places.yaml: place '{pid}': question to unknown person {q['person']!r}")
            if person["place"] != pid and q["person"] not in entry.get("people_also", []):
                raise ContentError(f"places.yaml: place '{pid}': {q['person']} is not here "
                                   f"(works at {person['place']!r}; add to people_also)")


def order_place_tools(docs: dict[str, Any]) -> None:
    """A place's tools as a list in the content's order ({tool, label,
    observations}): the JSON is written with sorted keys, and the menu shows
    the tools in the order the content gives them."""
    for entry in docs.get("places", {}).get("places", {}).values():
        entry["tools"] = [{"tool": tool, **t} for tool, t in entry["tools"].items()]


def _check_grants(missions: list[dict], places: dict) -> None:
    """The training week hands out each tool exactly once, conversation on the
    first day; an observe goal's tool is known by its day and fits its places."""
    week = [m for m in missions if m["kind"] == "training"]
    granted: list[str] = []
    for day, m in enumerate(week):
        granted += m.get("grant_tools", [])
        if day == 0 and "conversation" not in m.get("grant_tools", []):
            raise ContentError(f"missions.yaml: mission '{m['id']}': the first day grants conversation")
        tool = m["goal"].get("tool") if m["goal"]["type"] == "observe" else None
        if tool and tool not in granted:
            raise ContentError(f"missions.yaml: mission '{m['id']}' needs {tool}, not granted by its day")
    if sorted(granted) != sorted(TOOLS):
        raise ContentError(f"missions.yaml: the training week's grant_tools must grant each tool exactly once "
                           f"(granted: {', '.join(sorted(granted))})")
    for m in missions:
        if "grant_tools" in m and m["kind"] != "training":
            raise ContentError(f"missions.yaml: mission '{m['id']}': only a training day grants tools")
        goal = m["goal"]
        if goal["type"] != "observe":
            continue
        for place in goal["places"]:
            where = f"places.yaml: mission '{m['id']}' observes {place!r}"
            if "tool" in goal and goal["tool"] != "conversation" and goal["tool"] not in places[place]["tools"]:
                raise ContentError(f"{where} with {goal['tool']}, which does not fit there")
            actions = len(places[place]["tools"]) + (1 if places[place].get("questions") else 0)
            if "tool" not in goal and actions < goal.get("uses", 1):
                raise ContentError(f"{where}: {goal.get('uses', 1)} different actions, the place offers {actions}")


# ── kpis.yaml ────────────────────────────────────────────────────────────────

def validate_kpis(doc: Any, source: str) -> None:
    _require_strings(doc, ["review_question"], source)
    _known_keys(doc, {"pull_limit_days", "review_question", "care", "kpis"}, source)
    _number(doc, "pull_limit_days", source, 0.5)
    care = doc.get("care")
    levels = [c for c in CARE_RULES if c != "normal"]  # normal is the habit: no effects
    if not isinstance(care, dict) or sorted(care) != sorted(levels):
        raise ContentError(f"{source}: 'care' needs exactly {', '.join(levels)}")
    for level, change in care.items():
        where = f"{source}: care '{level}'"
        if not isinstance(change, dict):
            raise ContentError(f"{where}: needs touch_time and ftr")
        _known_keys(change, {"touch_time", "ftr"}, where)
        _number(change, "touch_time", where, 0.1)
        _number(change, "ftr", where, -0.5, 0.5)
    kpis = _entries(doc, "kpis", source)
    for k in kpis:
        where = f"{source}: kpi '{k['id']}'"
        _known_keys(k, KPI_KEYS, where)
        _require_strings(k, ["pool", "note"], where)
        _one_of(k, "kind", KPI_KINDS, where)
        rules = _mapping(k, "rules", set(KPI_RULES), where)
        if not rules:
            raise ContentError(f"{where}: needs at least one rule")
        for rule in rules:
            _one_of(rules, rule, KPI_RULES[rule], f"{where} rules")
    for pool, n in Counter(k["pool"] for k in kpis).items():
        if n > KPIS_PER_POOL:
            raise ContentError(f"{source}: '{pool}' has {n} KPIs; at most {KPIS_PER_POOL} KPIs per department")


def check_kpis(docs: dict[str, Any]) -> None:
    """KPIs against the value streams: each belongs to a team."""
    pools = {p["id"] for p in docs["value_streams"]["pools"]}
    for k in docs["kpis"]["kpis"]:
        if k["pool"] not in pools:
            raise ContentError(f"kpis.yaml: kpi '{k['id']}': unknown pool {k['pool']!r}")


# ── concepts.yaml ────────────────────────────────────────────────────────────
# The glossary (the game's codex): every concept a problem, clue or the rules
# teach. Ids are what `teaches` lists and Profile.learn() use; acronyms keep
# their capitals (PDCA, A3).

_CONCEPT_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_]*$")
CONCEPT_CATEGORIES = ["lean", "sector", "kata", "measure"]
CONCEPT_KEYS = {"id", "name", "category", "short", "text", "example", "source", "estimate", "verify"}
# Concepts the rules teach by id (game/src/rules/region.gd, profile.learn), plus
# waste_<waste> for every waste.
CODE_CONCEPTS = ["respect_for_people", "open_questions", "gemba", "A3", "kata_prediction", "PDCA",
                 "eight_wastes", "bottleneck_focus", "theory_of_constraints", "standard_work"]


def validate_concepts(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    items = doc.get("concepts")
    if not isinstance(items, list) or not all(isinstance(i, dict) for i in items):
        raise ContentError(f"{source}: 'concepts' must be a list of mappings")
    _check_ids([i.get("id") for i in items], "concepts", source, _CONCEPT_ID, "an id of letters, digits and _")
    for c in items:
        where = f"{source}: concept '{c['id']}'"
        _known_keys(c, CONCEPT_KEYS, where)
        _require_strings(c, ["name", "short", "text", "example"], where)
        _one_of(c, "category", CONCEPT_CATEGORIES, where)
        if not isinstance(c.get("verify", False), bool):
            raise ContentError(f"{where}: 'verify' must be true or false")
        if "source" in c:
            src = c["source"]
            if not isinstance(src, dict) or set(src) != {"title", "url"} or not str(src["url"]).startswith("https://") \
                    or not isinstance(src["title"], str) or not src["title"].strip():
                raise ContentError(f"{where}: 'source' needs a title and an https url")
        if "estimate" in c:
            _require_strings(c, ["estimate"], where)
        if c["category"] == "sector" and "source" not in c and "estimate" not in c:
            raise ContentError(f"{where}: a sector fact needs a 'source' or an 'estimate' (CLAUDE.md §2, evidence first)")


def check_concepts(docs: dict[str, Any]) -> None:
    """Everything the game teaches has a glossary entry."""
    known = {c["id"] for c in docs["concepts"]["concepts"]}
    for concept_id in CODE_CONCEPTS + [f"waste_{w}" for w in WASTES]:
        if concept_id not in known:
            raise ContentError(f"concepts.yaml: missing concept {concept_id!r} (the rules teach it)")
    taught_by: list[tuple[str, list]] = [(f"missions.yaml: mission '{m['id']}'", m.get("teaches", []))
                                         for m in docs["missions"]["missions"]]
    for stem, p in _all_problems(docs):
        where = f"{stem}.yaml: problem '{p['id']}'"
        taught_by += [(where, p.get("teaches", []))] + [
            (f"{where} clue {i}", c.get("teaches", [])) for i, c in enumerate(p["clues"])]
    for at, ids in taught_by:
        for concept_id in ids:
            if concept_id not in known:
                raise ContentError(f"{at}: teaches unknown concept {concept_id!r}")


# ── dialogs.yaml ─────────────────────────────────────────────────────────────
# Conversations with named people (docs/superpowers/specs/2026-10-15-dialog-
# system-design.md §9). Vocabularies mirrored in game/src/rules/dialog.gd; the
# Godot content test fails if they diverge. Optional: a content set without
# people (the test fixtures) builds without it.

LISTEN_MOVES = ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry", "experience", "silence"]
STEER_MOVES = ["perspective", "show_data", "propose_experiment", "propose", "ask_commitment"]
DIALOG_MOVES = LISTEN_MOVES + STEER_MOVES + ["pressure", "confront", "repair", "close"]
DATA_TOKEN = "{data}"  # Dialog.DATA_TOKEN: where a shown clue's text goes in the player's line
DIALOG_TAGS = ["claim", "feeling", "hesitation", "admission", "doubt"]
DIALOG_NEEDS = ["facts", "safety", "recognition", "time", "fairness"]  # Dialog.NEEDS (person-needs spec)
DIALOG_ARCHETYPES = ["defender", "cynic", "craftsman", "overloaded", "rule_bound", "quiet", "customer_upset", "expert", "mentor"]
DIALOG_KINDS = ["persuade", "checkin", "expert"]
DIALOG_MOODS = ["goed", "neutraal", "gespannen", "moe", "stil"]
DIALOG_OUTCOMES = ["commitment", "partial", "heard", "none", "blocked", "compliance", "ruined", "lifted"]
LAYERS = {"interest": (40, 65), "concern": (60, 85)}  # layer id → the range its `at` threshold must lie in
REPLY_SITUATIONS = ["lands", "misses", "too_early", "worn"]
# The bank's fallback replies: every move that has no reply of its own elsewhere
# (a layer, a proposal, an outcome) needs these situations.
BANK_REPLIES = {**{m: ["lands", "misses"] for m in LISTEN_MOVES + ["perspective", "show_data", "propose_experiment"]},
                "pressure": ["lands"], "confront": ["lands"], "repair": ["lands"]}
BANK_SPECIAL = ["repeat", "refusal", "no_proposal", "other_data", "lucky_guess", "no_repair", "patience_low",
                "cooling_down"]
# Ruud's line after a main-mission talk that ended this way (People.coach_question;
# pressure: a yes under pressure).
COACH_AFTER = ["pressure", "ruined", "blocked", "commitment"]
PERSON_KEYS = {"id", "name", "short", "role", "place", "team", "archetype", "need", "trust", "morale", "voice",
               "leaves_on", "customer", "voicemail"}   # a customer's talks are calls (PLAN 2.4), with a voicemail
DIALOG_KEYS = {"id", "name", "person", "kind", "mission", "requires_clue", "needs", "owns", "kpi_team", "mood",
               "patience", "opening", "retry_opening", "position", "layers", "data", "proposals", "experiments",
               "co_proposal", "condition_needs", "block", "lines", "replies", "outcomes", "variants", "trigger",
               "tutorial", "teaches", "prompt", "warning", "need", "beats_after", "also_during", "missions"}
LAYER_KEYS = {"id", "at", "via", "text", "tags", "tell", "lead_in", "condition", "wait_for", "unlocks"}
PROPOSAL_KEYS = {"id", "label", "say", "kpis", "addresses", "reply", "hidden", "promise"}
# A proposal that promises the person something the game checks later (D9
# talks audit A4; the check is 2.4b): {kind, days}.
PROMISE_KINDS = ["delivery_date", "callback"]
# A persuasion speaks its own outcomes in the person's voice; the bank's are a
# narrator, kept for check-ins and experts (tier-1 content audit C9).
PERSUADE_OUTCOMES = ["commitment", "partial", "heard", "compliance", "ruined"]
# A bank reply never carries these: whether a summary or a named feeling lands
# must depend on what this person said (tier-1 content audit C8).
BANK_UNTAGGED = {"claim", "feeling"}
VARIANT_KEYS = {"needs", "mood", "position", "layers"}
# An expert talk (phase 2 design §2.5; ExpertTalk): topic by topic, no meters.
EXPERT_KEYS = {"id", "name", "person", "kind", "mission", "also_during", "needs", "need", "opening",
               "retry_opening", "closing", "topics"}
TOPIC_KEYS = {"id", "ask", "answer", "needs", "trust", "unlocks"}
# A topic's clue is inline ({problem, key, depth, text}, merged into that
# problem like a concern's), its explainer an id of explainers.yaml.
TOPIC_UNLOCKS = {"clue", "explainer", "facts"}


def _line(item: Any, where: str) -> dict:
    """A spoken line: {text, tags?}."""
    if not isinstance(item, dict):
        raise ContentError(f"{where}: a line is a mapping with a text and optional tags")
    _known_keys(item, {"text", "tags", "tell"}, where)
    if "tell" in item:
        _one_of(item, "tell", DIALOG_NEEDS, where)
    _require_strings(item, ["text"], where)
    for tag in _string_list(item, "tags", where):
        if tag not in DIALOG_TAGS:
            raise ContentError(f"{where}: unknown tag {tag!r}")
    return item


def _needs(expr: Any, where: str) -> list[str]:
    """A needs expression in the C19 grammar (_validate_needs). Returns its atoms."""
    _validate_needs(expr, where)
    return [atom for atoms in expr.values() for atom in atoms]


def validate_dialogs(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    _known_keys(doc, {"people", "bank", "move_cards", "dialogs", "greetings", "quick", "chatter"}, source)
    for p in _entries(doc, "people", source):
        where = f"{source}: person '{p['id']}'"
        _known_keys(p, PERSON_KEYS, where)
        _require_strings(p, ["role", "place", "team"] + (["short"] if "short" in p else []), where)
        _one_of(p, "archetype", DIALOG_ARCHETYPES, where)
        _one_of(p, "need", DIALOG_NEEDS, where)
        _number(p, "trust", where, 0, 100, integer=True)
        _number(p, "morale", where, 0, 100, integer=True, default=60)
        if not isinstance(p.get("customer", False), bool):
            raise ContentError(f"{where}: 'customer' must be true or false")
        if p.get("customer", False) != ("voicemail" in p):
            raise ContentError(f"{where}: a customer, and only a customer, leaves a 'voicemail' line")
        if "voicemail" in p:
            _require_strings(p, ["voicemail"], where)
    _validate_bank(doc.get("bank"), f"{source}: bank")
    for i, card in enumerate(doc.get("move_cards") or []):
        _move_card(card, f"{source}: move card {i}")
    for d in _entries(doc, "dialogs", source):
        _validate_dialog(d, f"{source}: dialog '{d['id']}'")
    _validate_passing(doc, source)


# ── In passing (Phase 2 design §1.4; game/src/rules/reactions.gd) ───────────
# Mirrored in Reactions.FACTS / MOODS / LOADS.
GREETING_FACTS = ["ruined", "pressured", "committed", "heard", "standardised"]
QUICK_MOODS = ["tired", "busy", "calm", "morning", "afternoon", "late"]
CHATTER_LOADS = ["busy", "calm"]
GREETINGS_PER_PERSON = 3
SHARED_LINES = "_all"


def _lines(value: Any, where: str) -> None:
    if not isinstance(value, list) or not value or not all(isinstance(t, str) and t.strip() for t in value):
        raise ContentError(f"{where}: a list of spoken lines, each a non-empty text")


def _cast_entries() -> list[dict]:
    """The cast list's people (cast.json), the player left out."""
    try:
        cast = json.loads(CAST_FILE.read_text(encoding="utf-8"))["characters"]
        out = [c for c in cast if c.get("id") != "player"]
        for c in out:
            str(c["id"])
            if not isinstance(c.get("office") or {}, dict):
                raise TypeError(f"{c['id']}: office is not a mapping")
        return out
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        raise ContentError(f"{CAST_FILE.name}: cannot read the cast ({exc})") from exc


def _cast_ids() -> list[str]:
    return [str(c["id"]) for c in _cast_entries()]


def _validate_passing(doc: dict, source: str) -> None:
    """greetings (every cast member: GREETINGS_PER_PERSON ordinary ones; the shared lines per
    fact), quick (the shared lines per mood), chatter (two lines, known teams and load)."""
    if not any(k in doc for k in ("greetings", "quick", "chatter")):
        return   # a content set without people
    cast = _cast_ids()
    teams = {p.get("team") for p in doc.get("people") or []}
    for key, kinds, shared in (("greetings", ["day"] + GREETING_FACTS, GREETING_FACTS),
                               ("quick", QUICK_MOODS, QUICK_MOODS)):
        table = doc.get(key)
        if not isinstance(table, dict):
            raise ContentError(f"{source}: {key} is a mapping of people")
        for pid, own in table.items():
            where = f"{source}: {key} {pid}"
            if pid != SHARED_LINES and pid not in cast:
                raise ContentError(f"{where}: {pid!r} is not in the cast ({CAST_FILE.name})")
            if not isinstance(own, dict):
                raise ContentError(f"{where}: a mapping of lines per kind")
            _known_keys(own, set(kinds), where)
            for kind, lines in own.items():
                _lines(lines, f"{where} {kind}")
        missing = [k for k in shared if k not in (table.get(SHARED_LINES) or {})]
        if missing:
            raise ContentError(f"{source}: {key} {SHARED_LINES} has no lines for {', '.join(missing)}")
    for pid in cast:
        if len((doc["greetings"].get(pid) or {}).get("day") or []) < GREETINGS_PER_PERSON:
            raise ContentError(f"{source}: greetings {pid}: needs at least three ordinary greetings (day)")
    for c in _entries(doc, "chatter", source, name="id"):
        where = f"{source}: chatter {c['id']}"
        _known_keys(c, {"id", "teams", "load", "lines"}, where)
        if not (isinstance(c.get("lines"), list) and len(c["lines"]) == 2):
            raise ContentError(f"{where}: two lines, the first person's and the second's")
        _lines(c["lines"], where)
        unknown = [t for t in c.get("teams", []) if t not in teams] if isinstance(c.get("teams", []), list) else ["?"]
        if unknown:
            raise ContentError(f"{where}: teams names people's teams (unknown: {unknown})")
        if "load" in c and c["load"] not in CHATTER_LOADS:
            raise ContentError(f"{where}: load is one of {', '.join(CHATTER_LOADS)}")


MOVE_CARD_KEYS = {"move", "day", "title", "text", "why"}


def _move_card(card: Any, where: str) -> None:
    """A card of the Act 0 week (tutorial talks spec §2): a listening move, or
    none for a card that names a skill; the training day it is shown on."""
    if not isinstance(card, dict) or set(card) != MOVE_CARD_KEYS:
        raise ContentError(f"{where}: a move card has {', '.join(sorted(MOVE_CARD_KEYS))}")
    if card["move"] is not None and card["move"] not in LISTEN_MOVES:
        raise ContentError(f"{where}: a move card names a listening move or none")
    _require_strings(card, ["day", "title", "text", "why"], where)


def _validate_bank(bank: Any, where: str) -> None:
    if not isinstance(bank, dict):
        raise ContentError(f"{where}: needs labels, player, replies, special and outcomes")
    _known_keys(bank, {"labels", "player", "replies", "special", "outcomes", "coach", "wear_out", "ruud_names"}, where)
    # Ruud names one move after an Act 0 talk (tutorial talks spec §3).
    names = LISTEN_MOVES + ["none", "week_end"]
    ruud = _mapping(bank, "ruud_names", set(names), where)
    if set(ruud) != set(names):
        raise ContentError(f"{where} ruud_names: a line for every listening move, 'none' and 'week_end'")
    _require_strings(ruud, names, f"{where} ruud_names")
    # Moves that wear out (person-needs spec §3.2): a question and a statement line per archetype.
    wear_out = _mapping(bank, "wear_out", set(DIALOG_ARCHETYPES), where)
    for archetype in DIALOG_ARCHETYPES:
        lines = wear_out.get(archetype)
        if not isinstance(lines, dict) or set(lines) != {"ask", "say"}:
            raise ContentError(f"{where} wear_out: {archetype!r} needs an 'ask' and a 'say' line")
        _require_strings(lines, ["ask", "say"], f"{where} wear_out {archetype}")
    labels = _mapping(bank, "labels", {"bands", "cue", "chips", "outcomes"}, where)
    if len(_string_list(labels, "bands", f"{where} labels")) != 5:
        raise ContentError(f"{where} labels: 'bands' names the five openness bands")
    _require_strings(labels, ["cue"], f"{where} labels")
    for key, ids in (("chips", DIALOG_MOVES), ("outcomes", DIALOG_OUTCOMES)):
        _require_strings(_mapping(labels, key, set(ids), f"{where} labels"), ids, f"{where} labels {key}")
    _player_lines(_mapping(bank, "player", set(DIALOG_MOVES), where), f"{where} player")
    replies = _mapping(bank, "replies", set(BANK_REPLIES), where)
    for move, situations in BANK_REPLIES.items():
        if not isinstance(replies.get(move), dict) or set(situations) - set(replies[move]):
            raise ContentError(f"{where} replies: {move!r} needs {', '.join(situations)}")
        _replies({move: replies[move]}, f"{where} replies")
        for situation, line in replies[move].items():
            if BANK_UNTAGGED & set(line.get("tags", [])):
                raise ContentError(f"{where} replies {move} {situation}: a bank reply carries no claim or feeling tag")
    _require_strings(_mapping(bank, "special", set(BANK_SPECIAL), where), BANK_SPECIAL, f"{where} special")
    _require_strings(_mapping(bank, "outcomes", set(DIALOG_OUTCOMES), where), DIALOG_OUTCOMES, f"{where} outcomes")
    coach = _mapping(bank, "coach", {"questions", "after"}, where)
    if coach:
        _string_list(coach, "questions", f"{where} coach", allow_empty=False)
        after = _mapping(coach, "after", set(COACH_AFTER), f"{where} coach")
        _require_strings(after, list(after), f"{where} coach after")


def _player_lines(player: dict, where: str) -> None:
    """The player's lines (PLAN 2.13 B, four sentences a turn): per move a line
    or a list of variants, each a non-empty string; showing data names the
    clue through DATA_TOKEN (Dialog.DATA_TOKEN)."""
    for move in DIALOG_MOVES:
        lines = player.get(move)
        variants = [lines] if isinstance(lines, str) else lines
        if not isinstance(variants, list) or not variants or not all(isinstance(v, str) and v.strip() for v in variants):
            raise ContentError(f"{where} {move}: a line, or a non-empty list of lines")
        if move == "show_data" and not all(DATA_TOKEN in v for v in variants):
            raise ContentError(f"{where} show_data: every line names the clue with {DATA_TOKEN}")


def _replies(replies: dict, where: str) -> None:
    for move, by_situation in replies.items():
        if move not in DIALOG_MOVES:
            raise ContentError(f"{where}: unknown move {move!r}")
        if not isinstance(by_situation, dict):
            raise ContentError(f"{where} {move}: maps a situation to a line")
        for situation, line in by_situation.items():
            if situation not in REPLY_SITUATIONS:
                raise ContentError(f"{where} {move}: unknown situation {situation!r} ({', '.join(REPLY_SITUATIONS)})")
            _line(line, f"{where} {move} {situation}")


def _validate_expert(d: dict, where: str) -> None:
    """An expert talk (game/src/rules/expert_talk.gd): topics, each a question the
    player asks and the expert's answer; no layers, meters or outcomes."""
    _known_keys(d, EXPERT_KEYS, where)
    _require_strings(d, ["person", "opening", "closing"] + [k for k in ("retry_opening", "mission") if k in d], where)
    if "needs" in d:
        _needs(d["needs"], f"{where} needs")
    topics = _entries(d, "topics", where, "ask")
    if not topics:
        raise ContentError(f"{where}: an expert talk needs topics")
    for t in topics:
        at = f"{where} topic '{t['id']}'"
        _known_keys(t, TOPIC_KEYS, at)
        _require_strings(t, ["ask", "answer"], at)
        if "needs" in t:
            _needs(t["needs"], f"{at} needs")
        if "trust" in t:
            _number(t, "trust", at, 0, 100, integer=True)
        unlocks = _mapping(t, "unlocks", TOPIC_UNLOCKS, at)
        for fact in _string_list(unlocks, "facts", f"{at} unlocks"):
            if _atom_parts(fact, f"{at} unlocks")[0] != "heard":
                raise ContentError(f"{at} unlocks: {fact!r} is not a fact heard:<id>")
        if "explainer" in unlocks:
            _require_strings(unlocks, ["explainer"], f"{at} unlocks")
        if "clue" in unlocks:
            _inline_clue(unlocks["clue"], f"{at} unlocks", ["problem"])


def _inline_clue(clue: Any, where: str, more: list[str]) -> None:
    """A clue a talk unlocks, written where it is said: {key, depth, text, note?} and `more`."""
    if not isinstance(clue, dict):
        raise ContentError(f"{where}: 'clue' is a mapping with {', '.join(more + ['key', 'depth', 'text'])}")
    _known_keys(clue, {"key", "depth", "text", "note", *more}, f"{where} clue")
    _require_strings(clue, more + ["text"], f"{where} clue")
    if not isinstance(clue.get("key"), bool):
        raise ContentError(f"{where} clue: 'key' must be true or false")
    _number(clue, "depth", f"{where} clue", 0, integer=True)


def _validate_dialog(d: dict, where: str) -> None:
    if d.get("kind") == "expert":
        return _validate_expert(d, where)
    _known_keys(d, DIALOG_KEYS, where)
    _require_strings(d, ["person", "opening"], where)
    for key in ("retry_opening", "warning"):
        if key in d:
            _require_strings(d, [key], where)
    _one_of(d, "kind", DIALOG_KINDS, where)
    if "need" in d:
        _one_of(d, "need", DIALOG_NEEDS, where)
    if "mood" in d:
        _one_of(d, "mood", DIALOG_MOODS, where)
    _number(d, "patience", where, 3, 15, integer=True, default=10)
    if not isinstance(d.get("tutorial", False), bool):
        raise ContentError(f"{where}: 'tutorial' must be true or false (an Act 0 talk that cannot be ruined)")
    if "teaches" in d:  # the day's move on Ruud's morning card (tutorial talks spec §5)
        if not d.get("tutorial"):
            raise ContentError(f"{where}: 'teaches' only on a tutorial talk")
        if set(_string_list(d, "teaches", where)) - set(LISTEN_MOVES):
            raise ContentError(f"{where}: 'teaches' names listening moves ({', '.join(LISTEN_MOVES)})")
    _line(d.get("position"), f"{where} position")
    _layers(d.get("layers"), where)
    proposals = _entries(d, "proposals", where, "label") if "proposals" in d else []
    experiments = _entries(d, "experiments", where, "label") if "experiments" in d else []
    for item in proposals + experiments:
        at = f"{where} proposal '{item['id']}'"
        is_proposal = any(item is p for p in proposals)
        _known_keys(item, PROPOSAL_KEYS, at)
        _require_strings(item, ["label", "say"], at)
        if "reply" in item:
            _require_strings(item, ["reply"], at)
        if "promise" in item:
            promise = item["promise"]
            if not isinstance(promise, dict) or set(promise) != {"kind", "days"}:
                raise ContentError(f"{at}: a promise is {{kind, days}}")
            _one_of(promise, "kind", PROMISE_KINDS, f"{at} promise")
            _number(promise, "days", f"{at} promise", 1, 365, integer=True)
        if is_proposal and "reply" not in item:
            raise ContentError(f"{at}: a proposal needs the person's reply")
        if not isinstance(item.get("hidden", False), bool):
            raise ContentError(f"{at}: 'hidden' must be true or false")
        for layer in _string_list(item, "addresses", at):
            if layer not in LAYERS:
                raise ContentError(f"{at}: addresses unknown layer {layer!r}")
        if "kpis" in item and not (1 <= len(_string_list(item, "kpis", at)) <= 2):
            raise ContentError(f"{at}: 'kpis' names one or two KPIs")
    ids = [i["id"] for i in proposals + experiments]
    _check_ids(ids, "proposal and experiment", where)
    hidden = {p["id"] for p in proposals if p.get("hidden")}
    for layer in (layer for layers in _all_layers(d) for layer in layers):
        for pid in layer.get("unlocks", {}).get("proposals", []):
            if pid not in hidden:
                raise ContentError(f"{where}: unlocks {pid!r}, which is not a hidden proposal")
    if "co_proposal" in d:
        co = d["co_proposal"]
        if not isinstance(co, dict) or co.get("id") not in hidden:
            raise ContentError(f"{where}: co_proposal names a hidden proposal (their own idea)")
        _known_keys(co, {"id", "text"}, f"{where} co_proposal")
        _require_strings(co, ["text"], f"{where} co_proposal")
    _string_list(d, "data", where)
    for key in ("needs", "condition_needs"):
        if key in d:
            _needs(d[key], f"{where} {key}")
    if "block" in d:
        _block(d["block"], where)
    if "beats_after" in d:
        _beats_after(d, where)
    lines = d.get("lines", {})
    if not isinstance(lines, dict) or set(lines) - set(DIALOG_MOVES):
        raise ContentError(f"{where}: 'lines' maps a move to the player's line (unknown move in {sorted(lines)})")
    _require_strings(lines, list(lines), f"{where} lines")
    if DATA_TOKEN not in lines.get("show_data", DATA_TOKEN):
        raise ContentError(f"{where} lines: show_data names the clue with {DATA_TOKEN}")
    replies = d.get("replies", {})
    if not isinstance(replies, dict):
        raise ContentError(f"{where}: 'replies' maps a move to its replies")
    _replies(replies, f"{where} replies")
    outcomes = d.get("outcomes", {})
    if not isinstance(outcomes, dict) or set(outcomes) - set(DIALOG_OUTCOMES):
        raise ContentError(f"{where}: 'outcomes' overrides texts of known outcome(s) only: {', '.join(DIALOG_OUTCOMES)}")
    _require_strings(outcomes, list(outcomes), f"{where} outcomes")
    for i, variant in enumerate(d.get("variants", [])):
        at = f"{where} variant {i}"
        if not isinstance(variant, dict):
            raise ContentError(f"{at}: a variant is a mapping")
        _known_keys(variant, VARIANT_KEYS, at)
        _needs(variant.get("needs"), f"{at} needs")
        if "mood" in variant:
            _one_of(variant, "mood", DIALOG_MOODS, at)
        if "position" in variant:
            _line(variant["position"], f"{at} position")
        if "layers" in variant:
            _layers(variant["layers"], at)
    if "prompt" in d:
        if d["kind"] != "checkin":
            raise ContentError(f"{where}: only a check-in has a dagstart 'prompt'")
        _require_strings(d, ["prompt"], where)
    elif d["kind"] == "checkin":  # the dagstart names who could use a talk, in one line
        raise ContentError(f"{where}: a check-in needs a dagstart 'prompt'")
    if d["kind"] == "checkin":
        _checkin(d, proposals + experiments, where)
    else:
        if "missions" not in d:
            _require_strings(d, ["mission"], where)
        elif "mission" in d:  # a talk on more than one mission (arc S11) names them in one list
            raise ContentError(f"{where}: 'mission' or 'missions', not both")
        else:
            _string_list(d, "missions", where, allow_empty=False)
        # No single right answer (spec §9.2 rule 10): two ways at least to meet the concern.
        if d["kind"] == "persuade" and sum(1 for i in proposals + experiments if "concern" in i.get("addresses", [])) < 2:
            raise ContentError(f"{where}: no single right answer: needs two proposals or experiments that address the concern")
        if d["kind"] == "persuade":
            missing = [o for o in PERSUADE_OUTCOMES + (["blocked"] if "block" in d else []) if o not in outcomes]
            if missing:
                raise ContentError(f"{where}: a persuasion authors its own outcome lines; missing {', '.join(missing)}")


def _layers(layers: Any, where: str) -> None:
    if not isinstance(layers, list) or [layer.get("id") if isinstance(layer, dict) else None for layer in layers] != list(LAYERS):
        raise ContentError(f"{where}: 'layers' must be interest, then concern")
    for layer in layers:
        at = f"{where} layer '{layer['id']}'"
        _known_keys(layer, LAYER_KEYS, at)
        low, high = LAYERS[layer["id"]]
        _number(layer, "at", at, low, high, integer=True)
        via = _string_list(layer, "via", at)
        if len(set(via)) < 2:
            raise ContentError(f"{at}: needs two 'via' moves at least (more than one way in)")
        for move in via:
            if move not in DIALOG_MOVES:
                raise ContentError(f"{at}: unknown move {move!r} in via")
        _line({k: layer[k] for k in ("text", "tags", "tell") if k in layer}, at)
        if "condition" in layer:
            _require_strings(layer, ["condition"], at)
        if "wait_for" in layer:  # what still has to happen, for the summary card
            if "condition" not in layer:
                raise ContentError(f"{at}: 'wait_for' without a condition")
            _require_strings(layer, ["wait_for"], at)
        unlocks = _mapping(layer, "unlocks", {"clue", "facts", "proposals"}, at)
        for fact in _string_list(unlocks, "facts", f"{at} unlocks"):
            if _atom_parts(fact, f"{at} unlocks")[0] != "heard":
                raise ContentError(f"{at} unlocks: {fact!r} is not a fact heard:<id>")
        _string_list(unlocks, "proposals", f"{at} unlocks")
        if "clue" in unlocks:
            _inline_clue(unlocks["clue"], f"{at} unlocks", [])
    concern = layers[1]
    if not isinstance(concern.get("lead_in"), dict):
        raise ContentError(f"{where}: the concern needs a lead_in (the line that carries the cue)")
    # The cue (four-tier audit §4.2): a hesitation opens to silence, a feeling
    # to reflect and empathy, never to silence (rules T4).
    cue = set(_line(concern["lead_in"], f"{where} concern lead_in").get("tags", [])) & {"hesitation", "feeling"}
    if not cue:
        raise ContentError(f"{where}: the concern's lead_in carries the tag hesitation or feeling")
    if cue == {"feeling"} and ("silence" in concern["via"] or "reflect" not in concern["via"]):
        raise ContentError(f"{where}: a concern cued by a feeling opens to reflect, never to silence")


def _block(block: Any, where: str) -> None:
    if not isinstance(block, dict):
        raise ContentError(f"{where}: 'block' is a mapping with a text and routes")
    _known_keys(block, {"text", "routes"}, f"{where} block")
    _require_strings(block, ["text"], f"{where} block")
    routes = block.get("routes")
    if not isinstance(routes, list) or not routes:
        raise ContentError(f"{where} block: needs one route at least")
    for i, route in enumerate(routes):
        if not isinstance(route, dict):
            raise ContentError(f"{where} block route {i}: a mapping with needs and a hint")
        _known_keys(route, {"needs", "hint"}, f"{where} block route {i}")
        _require_strings(route, ["hint"], f"{where} block route {i}")
        _needs(route.get("needs"), f"{where} block route {i}")


def _beats_after(d: dict, where: str) -> None:
    """[{when: a fact atom, text}]: what a person who agreed under condition
    says once `when` comes true (tier-1 content audit C15). Only a persuasion
    has an agreement to upgrade."""
    if d.get("kind") != "persuade":
        raise ContentError(f"{where}: only a persuasion has beats_after (a partial agreement to upgrade)")
    lines = d["beats_after"]
    if not isinstance(lines, list) or not lines:
        raise ContentError(f"{where}: 'beats_after' is a list of {{when, text}}")
    for i, line in enumerate(lines):
        at = f"{where} beats_after {i}"
        if not isinstance(line, dict):
            raise ContentError(f"{at}: a mapping with when and text")
        _known_keys(line, {"when", "text"}, at)
        _require_strings(line, ["when", "text"], at)
        _atom_parts(line["when"], at)


def _checkin(d: dict, items: list[dict], where: str) -> None:
    """A check-in has no mission, owns nothing and asks no KPIs (spec §9.2 rule 12)."""
    for key in ("mission", "missions", "owns", "kpi_team", "requires_clue", "data", "condition_needs", "block", "co_proposal"):
        if key in d:
            raise ContentError(f"{where}: a check-in has no {key!r}")
    if any("kpis" in i for i in items):
        raise ContentError(f"{where}: a check-in proposes no KPIs")
    trigger = d.get("trigger")
    if not isinstance(trigger, dict) or not trigger:
        raise ContentError(f"{where}: a check-in needs a trigger (morale_below and/or needs)")
    _known_keys(trigger, {"morale_below", "needs", "beat", "after_days", "before_days"}, f"{where} trigger")
    if "morale_below" in trigger:
        _number(trigger, "morale_below", f"{where} trigger", 1, 100, integer=True)
    if "after_days" in trigger and "before_days" in trigger:
        raise ContentError(f"{where} trigger: either after_days or before_days, not both")
    for key, low in (("after_days", 0), ("before_days", 1)):
        if key in trigger:
            if "beat" not in trigger:
                raise ContentError(f"{where} trigger: {key} needs a beat to count from")
            _number(trigger, key, f"{where} trigger", low, integer=True)
    if "beat" in trigger:
        _require_strings(trigger, ["beat"], f"{where} trigger")
    if "needs" in trigger:
        _needs(trigger["needs"], f"{where} trigger needs")


def check_dialogs(docs: dict[str, Any]) -> None:
    """Dialogs against people, missions, problems, KPI menus and each other."""
    _check_talk_goals(docs)
    if "dialogs" not in docs:
        return
    net = _network_index(docs["value_streams"], docs["kpis"])
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    problems = {p["id"]: p for _, p in _all_problems(docs)}
    doc = docs["dialogs"]
    people = {p["id"]: p for p in doc["people"]}
    for p in people.values():
        where = f"dialogs.yaml: person '{p['id']}'"
        if net["step"].get(p["place"], {}).get("kind") != "work":
            raise ContentError(f"{where}: place {p['place']!r} is not a work step")
        if p["team"] not in net["pool"]:
            raise ContentError(f"{where}: unknown team {p['team']!r}")
    dialogs = {d["id"]: d for d in doc["dialogs"]}
    heard = {f for d in dialogs.values() for layers in _all_layers(d) for layer in layers
             for f in layer.get("unlocks", {}).get("facts", [])}
    heard |= {f for d in dialogs.values() for t in d.get("topics", []) for f in t.get("unlocks", {}).get("facts", [])}
    explainers = {e["id"] for e in (docs.get("explainers") or {}).get("explainers", [])}
    index = _fact_index(docs)
    beats = {m["deadline_beat"] for m in missions.values() if "deadline_beat" in m}
    for p in people.values():
        if "leaves_on" in p and p["leaves_on"] not in beats:
            raise ContentError(f"dialogs.yaml: person '{p['id']}': leaves_on names unknown beat {p['leaves_on']!r}")
    clue_ids = {f"{p['id']}:{i}" for p in problems.values() for i in range(len(p["clues"]))}
    for d in dialogs.values():
        where = f"dialogs.yaml: dialog '{d['id']}'"
        if d["person"] not in people:
            raise ContentError(f"{where}: unknown person {d['person']!r}")
        need = d.get("need", people[d["person"]]["need"])
        for tell in _tells(d):
            if tell != need:
                raise ContentError(f"{where}: a tell shows {tell!r}, but the person's need here is {need!r}")
        for expr in _needs_of(d):
            for atom in _needs(expr, where):
                _dialog_atom_robust(atom, where, index, dialogs, heard)
        beat = d.get("trigger", {}).get("beat")
        if beat is not None and beat not in beats:
            raise ContentError(f"{where}: trigger names unknown beat {beat!r} (a mission's deadline_beat)")
        if d.get("requires_clue") is not None and d["requires_clue"] not in clue_ids:
            raise ContentError(f"{where}: requires unknown clue {d['requires_clue']!r}")
        if "block" in d and not any("none" not in r["needs"] and _robust_route(r["needs"], where, index, dialogs, heard)
                                    for r in d["block"]["routes"]):
            raise ContentError(f"{where}: never game over: the block needs a route no failure or skip can close")
        if d["kind"] == "expert":
            _check_expert(d, where, missions, problems, explainers)
        elif d["kind"] != "checkin":
            _check_mission_dialog(d, where, missions, problems, net)
    check_need_spread(speaking_cast(docs))
    training = {m["id"] for m in missions.values() if m.get("kind") == "training"}
    for i, card in enumerate(doc.get("move_cards") or []):
        if card["day"] not in training:
            raise ContentError(f"dialogs.yaml: move card {i}: {card['day']!r} is not a training day")


# The tiers of the four-tier audit by act: 1 = Acts 0–II, 2 = III, 3 = IV and VI, 4 = V.
TIER_OF_ACT = {0: 1, 1: 1, 2: 1, 3: 2, 4: 3, 5: 4, 6: 3}


def speaking_cast(docs: dict[str, Any]) -> dict[int, dict[str, str]]:
    """Per tier, the people with a mission's dialog in it and their need (a
    check-in belongs to no mission, so to no tier)."""
    acts = {m["id"]: m["act"] for m in docs["missions"]["missions"] if "act" in m}
    people = {p["id"]: p["need"] for p in docs["dialogs"]["people"]}
    cast: dict[int, dict[str, str]] = {}
    for d in docs["dialogs"]["dialogs"]:
        owner = next(iter(dialog_missions(d)), None)
        if owner in acts:
            cast.setdefault(TIER_OF_ACT[acts[owner]], {})[d["person"]] = people[d["person"]]
    return cast


def check_need_spread(cast: dict[int, dict[str, str]]) -> None:
    """N7 (person-needs spec §2.1): within a tier's speaking cast no need holds
    more than a third (rounded up), and a cast of five or more meets them all."""
    for tier, needs in sorted(cast.items()):
        n = len(needs)
        for need in DIALOG_NEEDS:
            count = list(needs.values()).count(need)
            if count > -(-n // 3):
                raise ContentError(f"dialogs.yaml: tier {tier}: the need {need!r} holds {count} of {n} speaking people "
                                   f"(at most a third)")
        missing = [need for need in DIALOG_NEEDS if need not in needs.values()]
        if n >= 5 and missing:
            raise ContentError(f"dialogs.yaml: tier {tier}: a cast of {n} meets every need; missing {', '.join(missing)}")


def _check_talk_goals(docs: dict[str, Any]) -> None:
    """A talk_to goal names a dialog of its own mission (spec §9.2 rule 4)."""
    dialogs = {d["id"]: d for d in docs.get("dialogs", {}).get("dialogs", [])}
    for m in docs["missions"]["missions"]:
        talk = m.get("ends_with_talk")  # the day ends with this talk, however it goes (D9 talks audit A2)
        if talk is not None and dialogs and m["id"] not in dialog_missions(dialogs.get(talk, {})):
            raise ContentError(f"missions.yaml: mission '{m['id']}': ends_with_talk names no dialog of its own: {talk!r}")
        names = [t["dialog"] for t in m.get("talk_to", [])] if dialogs else []  # a fixture without dialogs
        if m["goal"]["type"] == "talk_to":
            names.append(m["goal"]["dialog"])
        where = f"missions.yaml: mission '{m['id']}'"
        for name in names:
            d = dialogs.get(name)
            if d is None:
                raise ContentError(f"{where}: talk_to names unknown dialog {name!r}")
            if m["id"] not in dialog_missions(d):
                raise ContentError(f"{where}: dialog {d['id']!r} belongs to mission(s) {dialog_missions(d)!r}")
            if d.get("kind") != "persuade":
                raise ContentError(f"{where}: talk_to names {d['id']!r}, which is no persuasion")


def _tells(d: dict) -> list[str]:
    """Every `tell` on the dialog's lines (person-needs spec §1.5, N5)."""
    lines = [d["position"]] if "position" in d else []
    lines += [v["position"] for v in d.get("variants", []) if "position" in v]
    for layers in _all_layers(d):
        lines += layers + [layer["lead_in"] for layer in layers if "lead_in" in layer]
    lines += [line for by_situation in d.get("replies", {}).values() for line in by_situation.values()]
    return [line["tell"] for line in lines if "tell" in line]


def _all_layers(d: dict) -> list[list[dict]]:
    if d["kind"] == "expert":   # topics, no layers
        return []
    return [d["layers"]] + [v["layers"] for v in d.get("variants", []) if "layers" in v]


def _needs_of(d: dict) -> list[dict]:
    exprs = [d[k] for k in ("needs", "condition_needs") if k in d]
    exprs += [r["needs"] for r in d.get("block", {}).get("routes", [])]
    exprs += [v["needs"] for v in d.get("variants", [])]
    exprs += [{"all": [line["when"]]} for line in d.get("beats_after", [])]
    exprs += [t["needs"] for t in d.get("topics", []) if "needs" in t]
    return exprs + ([d["trigger"]["needs"]] if "needs" in d.get("trigger", {}) else [])


def _dialog_atom_robust(atom: str, where: str, index: dict, dialogs: dict, heard: set) -> bool:
    """_atom_robust, with the dialog facts checked against the dialogs: a
    commitment, an agreement or a heard concern can always still be won."""
    kind, ids = _atom_parts(atom, where)
    if kind == "heard" and atom not in heard:
        raise ContentError(f"{where}: {atom!r}: no dialog unlocks it")
    if kind in DIALOG_FACTS - {"heard"} and ids[0] not in dialogs:
        raise ContentError(f"{where}: {atom!r} names an unknown dialog")
    return _atom_robust(atom, where, index)


def _robust_route(expr: dict, where: str, index: dict, dialogs: dict, heard: set) -> bool:
    """Every 'all' atom, and one 'any' atom, stays reachable whatever is missed."""
    robust = [_dialog_atom_robust(a, where, index, dialogs, heard) for a in expr.get("all", [])]
    either = [_dialog_atom_robust(a, where, index, dialogs, heard) for a in expr.get("any", [])]
    return all(robust) and (not either or any(either))


def dialog_missions(d: dict) -> list:
    """The missions a talk is on: `missions:` (arc S11, the first owns it) or the one `mission:`."""
    return d["missions"] if "missions" in d else [d["mission"]] if "mission" in d else []


def _check_expert(d: dict, where: str, missions: dict, problems: dict, explainers: set) -> None:
    """An expert talk's mission (optional), and what its topics unlock exists."""
    for m in ([d["mission"]] if "mission" in d else []) + _string_list(d, "also_during", where):
        if m not in missions:
            raise ContentError(f"{where}: unknown mission {m!r}")
    for t in d["topics"]:
        unlocks = t.get("unlocks", {})
        if "explainer" in unlocks and unlocks["explainer"] not in explainers:
            raise ContentError(f"{where} topic '{t['id']}': unknown explainer {unlocks['explainer']!r}")
        if isinstance(unlocks.get("clue"), dict) and unlocks["clue"]["problem"] not in problems:
            raise ContentError(f"{where} topic '{t['id']}': its clue names unknown problem {unlocks['clue']['problem']!r}")


def _check_mission_dialog(d: dict, where: str, missions: dict, problems: dict, net: dict) -> None:
    for m in dialog_missions(d):
        if m not in missions:
            raise ContentError(f"{where}: unknown mission {m!r}")
    mission = missions[dialog_missions(d)[0]]  # the first owns the talk: its problem, data and KPI menu
    for later in _string_list(d, "also_during", where):  # open over these missions' days too
        if later not in missions:
            raise ContentError(f"{where}: also_during names unknown mission {later!r}")
    problem = mission["goal"].get("problem")
    if "owns" in d and d["owns"] != problem:
        raise ContentError(f"{where}: owns {d['owns']!r}, which is not the problem of mission {mission['id']!r}")
    for clue in d.get("data", []):
        if problem is None or clue not in {f"{problem}:{i}" for i in range(len(problems[problem]["clues"]))}:
            raise ContentError(f"{where}: data {clue!r} is not a clue of the mission's problem")
    if "kpi_team" in d and d["kpi_team"] not in net["menu"]:
        raise ContentError(f"{where}: kpi_team {d['kpi_team']!r} has no KPI menu")
    for item in d.get("proposals", []):
        if "kpis" in item and "kpi_team" not in d:
            raise ContentError(f"{where}: proposal {item['id']!r} names KPIs, so the dialog needs a kpi_team")
        for kpi in item.get("kpis", []):
            if kpi not in net["menu"][d["kpi_team"]]:
                raise ContentError(f"{where}: {kpi!r} is not on the menu of {d['kpi_team']!r}")
    for layers in _all_layers(d):
        clue = layers[1].get("unlocks", {}).get("clue")
        if clue is not None and not d.get("owns"):
            raise ContentError(f"{where}: a concern unlocks a clue of the problem the dialog owns: needs 'owns'")


def name_dialog_items(docs: dict[str, Any]) -> None:
    """A proposal's or experiment's `label` (the chip) and `say` (the player's
    line) become the engine's `name` and `text` (tier-1 content audit C1)."""
    for d in docs.get("dialogs", {}).get("dialogs", []):
        for item in d.get("proposals", []) + d.get("experiments", []):
            item["name"] = item.pop("label")
            item["text"] = item.pop("say")


def merge_dialog_clues(docs: dict[str, Any]) -> None:
    """Append every clue a concern unlocks to its owned problem's clues (tool
    conversation at the person's place, marked with the dialog: only the
    conversation reveals it) and put the clue's id in the dialog instead."""
    if "dialogs" not in docs:
        return
    people = {p["id"]: p for p in docs["dialogs"]["people"]}
    problems = {p["id"]: (stem, p) for stem, p in _all_problems(docs)}
    for d in docs["dialogs"]["dialogs"]:
        unlocking = [layers[1].get("unlocks", {}) for layers in _all_layers(d)]
        unlocking += [t["unlocks"] for t in d.get("topics", []) if "unlocks" in t]   # an expert's topic names its problem
        for unlocks in unlocking:
            if not isinstance(unlocks.get("clue"), dict):
                continue
            stem, problem = problems[unlocks["clue"].pop("problem", None) or d["owns"]]
            clue = {"tool": "conversation", "at": people[d["person"]]["place"], "dialog": d["id"], **unlocks["clue"]}
            problem["clues"].append(clue)
            _validate_clues(problem, f"{stem}.yaml: problem '{problem['id']}' (with dialog '{d['id']}')",
                            CLUE_KEYS | {"dialog"})
            unlocks["clue"] = f"{problem['id']}:{len(problem['clues']) - 1}"


# ── discoveries.yaml ─────────────────────────────────────────────────────────
# Hidden rewards (audit §4): trigger types and their parameters
# (Discoveries.TRIGGERS), and what a reward may hold.
DISCOVERY_TRIGGERS = {
    "check_recovery": [], "fork_measured": ["window_days"], "fork_learned": [], "held": ["days"],
    "tool_at": ["place", "tool", "hours", "months", "problem_active", "no_problem_at"],
    "predictions": ["count"], "deepest_why": ["count"], "durable_held": ["count", "days"],
    "blame_repair_clue": [], "no_blame_act": [], "no_overload_act": ["experiments"],
    "missions_scored": ["missions", "score"], "recovered_after_fail": ["score"], "coach_cycle": [],
    "tool_in_missions": ["place", "tool", "missions", "problem", "countermeasure"],
    "farewell": ["mission", "place", "days", "countermeasures"],
    "followed_order": ["days"], "contain_then_fix": ["days"],
    "listened_first": ["count"], "silence_reveal": ["count"], "second_chance": [], "own_idea": [],
    "lifted_low": ["count", "morale"], "no_pressure_act": ["commitments"],
}
DISCOVERY_KEYS = {"id", "name", "line", "hint", "act", "trigger", "reward"}
MAX_DISCOVERY_REPUTATION = 3  # small in power (audit §4.1)


def validate_discoveries(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    for d in _entries(doc, "discoveries", source):
        where = f"{source}: discovery '{d['id']}'"
        _known_keys(d, DISCOVERY_KEYS, where)
        _require_strings(d, ["line", "hint"], where)
        _number(d, "act", where, 0, MAX_ACT, integer=True)
        trigger = d.get("trigger")
        if not isinstance(trigger, dict) or trigger.get("type") not in DISCOVERY_TRIGGERS:
            raise ContentError(f"{where}: 'trigger' needs a type: {', '.join(DISCOVERY_TRIGGERS)}")
        _known_keys(trigger, {"type", *DISCOVERY_TRIGGERS[trigger["type"]]}, f"{where} trigger")
        for key in ("window_days", "days", "count", "experiments", "score", "commitments"):
            if key in trigger:
                _number(trigger, key, f"{where} trigger", 1, integer=True)
        if "hours" in trigger and not (isinstance(trigger["hours"], list) and len(trigger["hours"]) == 2
                                       and all(isinstance(h, int) and 0 <= h <= 24 for h in trigger["hours"])):
            raise ContentError(f"{where} trigger: 'hours' is [from, to], whole hours")
        if "morale" in trigger:
            _number(trigger, "morale", f"{where} trigger", 1, 100, integer=True)
        if "months" in trigger and not (isinstance(trigger["months"], list)
                                        and all(isinstance(m, int) and 1 <= m <= 12 for m in trigger["months"])):
            raise ContentError(f"{where} trigger: 'months' is a list of 1-12")
        reward = _mapping(d, "reward", {"reputation", "trust", "title", "object", "note"}, where)
        _number(reward, "reputation", f"{where} reward", 0, MAX_DISCOVERY_REPUTATION, integer=True, default=0)
        _trust_map(reward, f"{where} reward", 0, 1)
        _require_strings(reward, [k for k in ("title", "object", "note") if k in reward], f"{where} reward")


def check_discoveries(docs: dict[str, Any]) -> None:
    """Discoveries name real places, tools, problems, missions and teams."""
    net = _network_index(docs["value_streams"], docs["kpis"])
    problems = {p["id"]: p for _, p in _all_problems(docs)}
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    pools = {p["id"] for p in docs["value_streams"]["pools"]}
    for d in docs["discoveries"]["discoveries"]:
        where, t = f"discoveries.yaml: '{d['id']}'", d["trigger"]
        place = t.get("place")
        if place is not None and not (place in net["step"] or place.endswith(".")
                                      and any(s.startswith(place) for s in net["step"])):
            raise ContentError(f"{where}: unknown place {place!r}")
        if "tool" in t and t["tool"] not in TOOLS:
            raise ContentError(f"{where}: unknown tool {t['tool']!r}")
        for key in ("problem_active", "problem"):
            if key in t and t[key] not in problems:
                raise ContentError(f"{where}: unknown problem {t[key]!r}")
        for m in t.get("missions", []) if isinstance(t.get("missions"), list) else []:
            if m not in missions:
                raise ContentError(f"{where}: unknown mission {m!r}")
        if "mission" in t and t["mission"] not in missions:
            raise ContentError(f"{where}: unknown mission {t['mission']!r}")
        cms = t.get("countermeasures", []) + ([t["countermeasure"]] if "countermeasure" in t else [])
        listed = set(problems[t["problem"]]["countermeasures"]) if "problem" in t else \
            set(problems[missions[t["mission"]]["goal"]["problem"]]["countermeasures"]) if "mission" in t else set()
        for cm in cms:
            if cm not in listed:
                raise ContentError(f"{where}: countermeasure {cm!r} is not one of its problem's")
        for team in d.get("reward", {}).get("trust", {}):
            if team not in pools:
                raise ContentError(f"{where}: trust of unknown team {team!r}")


def vocabulary() -> dict[str, Any]:
    """The words content may use, written to game/data so a Godot test can
    check the game knows exactly the same ones."""
    return {
        "tools": sorted(TOOLS), "wastes": WASTES, "kpis": KPIS, "severities": SEVERITIES,
        "visibilities": VISIBILITIES, "check_pass": CHECK_PASS, "countermeasure_unlocks": UNLOCKS,
        "mission_kinds": MISSION_KINDS, "mission_goals": sorted(MISSION_GOALS), "coach_stages": COACH_STAGES,
        "belt_xp": BELT_XP, "min_reward_share": MIN_REWARD_SHARE, "fact_kinds": sorted(FACT_KINDS),
        "measures": sorted(MEASURES), "fork_roles": FORK_ROLES, "coach_conditions": COACH_CONDITIONS,
        "debrief_variants": DEBRIEF_VARIANTS, "start_rules": START_RULES, "order_rules": ORDER_RULES,
        "discovery_triggers": {k: v for k, v in sorted(DISCOVERY_TRIGGERS.items())},
        "care_rules": CARE_RULES, "kpi_kinds": KPI_KINDS,
        "effect_properties": {p: {"kind": k, "step_kind": sk or ""} for p, (k, sk, _) in sorted(EFFECT_PROPERTIES.items())},
        "dialog_moves": DIALOG_MOVES, "dialog_tags": DIALOG_TAGS, "dialog_archetypes": DIALOG_ARCHETYPES,
        "dialog_needs": DIALOG_NEEDS,
        "dialog_kinds": DIALOG_KINDS, "dialog_moods": DIALOG_MOODS, "dialog_outcomes": DIALOG_OUTCOMES,
        "banned_spoken": {"words": BANNED_SPOKEN, "allowed": ALLOWED_SPOKEN},
    }


# Required files and their validators; problems_tier<n>.yaml files (one per
# tier) all use validate_problems.
# ── explainers.yaml ─────────────────────────────────────────────────────────
# "Hoe werkt het?" (PLAN 2.7c; spec 2026-10-16-explainer-spanning-stroom-weerstand §6.2).

# The beats the beat machine (game/src/rules/explainers/explainer_beats.gd) plays.
EXPLAINER_BEATS = ["a1", "a2", "a2_dripper", "a3", "a4", "x", "r1", "r2", "r3", "r4", "r4_already_on",
                   "r5", "r5_lamp", "r6", "r7", "r7_never_alone", "r8a", "r8b"]
EXPLAINER_PHASES = {"tuin", "cross", "meterkast"}
EXPLAINER_WAITS = {"any_on", "two_on", "kettle_on", "heater_on", "heater_again", "haspel"}
EXPLAINER_CONDITIONS = {"only_lamp", "kettle_on", "heater_on", "never_kettle_alone"}
EXPLAINER_SHOWS = {"readout", "reveal"}
# A formula on screen (test T9): operators, units as symbols, I/U/P/R in an equation.
FORMULA = re.compile(r"[=÷×²·Ω]|ΔU|\b[IUPR]\s*[=/]")
# "The how, never the answer" (spec §5, test T7): mission clues and countermeasures.
NEVER_THE_ANSWER = ["3x25", "3×25", "zonnepaneel", "zonnepanelen", "omvormer", "253", "trafo", "transformator",
                    "aftakking", "warmtepomp", "el amrani", "netstudie", "wachtlijst", "verzwar"]
_EXPLAINER_KEYS = {"id", "name", "number", "place", "assets", "model", "one_idea", "analogy", "controls", "hint",
                   "labels", "tags", "caption", "reveal", "beats", "parameters", "sources"}
_BEAT_KEYS = {"id", "phase", "idea", "lines", "wait_for", "timeout_s", "alt_of", "when", "then", "skip_when",
              "silence_after", "pulse", "shows", "unlocks"}


def _explainer_texts(e: dict) -> list[tuple[str, str]]:
    """(where, text) for every Dutch string the player can read, the reveal included."""
    out = [("name", e["name"]), ("one_idea", e["one_idea"]), ("limit_line", e["analogy"]["limit_line"])]
    out += [(f"mapping {i}", row[side]) for i, row in enumerate(e["analogy"]["mapping"]) for side in ("analogy", "real")]
    out += [(f"hint {k}", v) for k, v in e["hint"].items()]
    out += [(f"label {k}", v) for k, v in e["labels"].items()]
    out += [("tag", t) for t in e["tags"]]
    out += [("caption", c) for c in e["caption"]]
    out += [(f"beat {b['id']}", line) for b in e["beats"] for line in b["lines"]]
    out += [("reveal", e["reveal"]["label"])]
    out += [("reveal", line[k]) for line in e["reveal"]["lines"] for k in ("words", "formula", "live") if k in line]
    return out


def _plain_texts(e: dict) -> list[tuple[str, str]]:
    """The texts that must stay plain: no digit, no formula (spec §1.5)."""
    return [(w, t) for w, t in _explainer_texts(e) if not w.startswith("reveal")]


def validate_explainers(doc: Any, source: str) -> None:
    for e in _entries(doc, "explainers", source):
        where = f"{source}: explainer {e['id']}"
        _known_keys(e, _EXPLAINER_KEYS, where)
        _require_strings(e, ["name", "place", "assets", "model", "one_idea"], where)
        _validate_explainer_parts(e, where)
        _validate_explainer_beats(e, where)
        _validate_explainer_evidence(e, where)
        for w, text in _explainer_texts(e):
            low = text.lower()
            hit = next((t for t in NEVER_THE_ANSWER if t in low), None)
            if hit:
                raise ContentError(f"{where}: {w} names {hit!r}, a mission's answer (the how, never the answer)")
        for w, text in _plain_texts(e):
            if re.search(r"\d", text):
                raise ContentError(f"{where}: {w} has a digit (numbers are readouts on the instruments): {text!r}")
            if FORMULA.search(text):
                raise ContentError(f"{where}: {w} has a formula (formulas only under reveal): {text!r}")


def _validate_explainer_parts(e: dict, where: str) -> None:
    analogy = _mapping(e, "analogy", {"skin", "mapping", "limit_line"}, where)
    if not isinstance(analogy.get("mapping"), list) or not analogy["mapping"]:
        raise ContentError(f"{where}: analogy.mapping must be a non-empty list")
    for i, row in enumerate(analogy["mapping"]):
        _require_strings(row, ["analogy", "real"], f"{where} mapping {i}")
        pair = row.get("pair")
        if not (isinstance(pair, list) and len(pair) == 2 and all(isinstance(p, str) for p in pair)):
            raise ContentError(f"{where} mapping {i}: 'pair' must be two layer ids")
    _require_strings(analogy, ["limit_line"], f"{where} analogy")
    controls = e.get("controls")
    if not isinstance(controls, list) or not all(isinstance(c, dict) for c in controls):
        raise ContentError(f"{where}: 'controls' must be a list of mappings")
    _check_ids([c.get("id") for c in controls], "controls", where)
    for name in ("hint", "labels"):
        if not isinstance(e.get(name), dict) or not all(isinstance(v, str) and v for v in e[name].values()):
            raise ContentError(f"{where}: '{name}' must map to non-empty strings")
    for name in ("tags", "caption"):
        if not isinstance(e.get(name), list) or not all(isinstance(v, str) and v for v in e[name]):
            raise ContentError(f"{where}: '{name}' must be a list of non-empty strings")
    reveal = _mapping(e, "reveal", {"label", "lines"}, where)
    _require_strings(reveal, ["label"], f"{where} reveal")
    for i, line in enumerate(reveal.get("lines") or []):
        _known_keys(line, {"words", "formula", "live"}, f"{where} reveal {i}")
        _require_strings(line, ["words"], f"{where} reveal {i}")


def _id_list(doc: dict, key: str, where: str) -> list[dict]:
    """A list of mappings with unique snake_case ids (no 'name' needed, unlike _entries)."""
    items = doc.get(key)
    if not isinstance(items, list) or not all(isinstance(i, dict) for i in items):
        raise ContentError(f"{where}: '{key}' must be a list of mappings")
    _check_ids([i.get("id") for i in items], key, where)
    return items


def _validate_explainer_beats(e: dict, where: str) -> None:
    beats = _id_list(e, "beats", where)
    ids = [b["id"] for b in beats]
    missing = [b for b in EXPLAINER_BEATS if b not in ids]
    if missing:
        raise ContentError(f"{where}: beats missing: {', '.join(missing)}")
    mains = {b["id"] for b in beats if "alt_of" not in b}
    for b in beats:
        at = f"{where} beat {b['id']}"
        _known_keys(b, _BEAT_KEYS, at)
        if b.get("phase") not in EXPLAINER_PHASES:
            raise ContentError(f"{at}: 'phase' must be one of {sorted(EXPLAINER_PHASES)}")
        if not isinstance(b.get("lines"), list) or not b["lines"] or not all(isinstance(t, str) and t for t in b["lines"]):
            raise ContentError(f"{at}: 'lines' must be a list of non-empty strings")
        if "wait_for" in b:
            if b["wait_for"] not in EXPLAINER_WAITS:
                raise ContentError(f"{at}: wait_for must be one of {sorted(EXPLAINER_WAITS)}")
            _number(b, "timeout_s", at, 1, 60)
        for key in ("when", "skip_when"):
            if key in b and b[key] not in EXPLAINER_CONDITIONS:
                raise ContentError(f"{at}: {key} must be one of {sorted(EXPLAINER_CONDITIONS)}")
        if "alt_of" in b and (b["alt_of"] not in mains or "when" not in b):
            raise ContentError(f"{at}: alt_of must name a main beat, with a 'when'")
        if "then" in b and b["then"] not in mains:
            raise ContentError(f"{at}: then must name a main beat")
        if not set(b.get("shows", [])) <= EXPLAINER_SHOWS:
            raise ContentError(f"{at}: shows must be among {sorted(EXPLAINER_SHOWS)}")
        lines = len(b["lines"])
        if not all(isinstance(i, int) and 0 <= i < lines - 1 for i in b.get("silence_after", [])):
            raise ContentError(f"{at}: silence_after must index a line before the last")


def _validate_explainer_evidence(e: dict, where: str) -> None:
    sources = _id_list(e, "sources", where)
    for s in sources:
        _require_strings(s, ["fact", "title", "url"], f"{where} source {s['id']}")
    known = {s["id"] for s in sources}
    params = e.get("parameters")
    if not isinstance(params, list) or not params:
        raise ContentError(f"{where}: 'parameters' must be a non-empty list")
    for p in params:
        at = f"{where} parameter {p.get('name')}"
        if "source" in p:
            if p["source"] not in known:
                raise ContentError(f"{at}: unknown source {p['source']!r}")
        elif not isinstance(p.get("estimate"), str) or not p["estimate"].strip():
            raise ContentError(f"{at}: needs a source or an estimate with its reasoning")


EXPLAINER_ASSETS = ROOT / "game" / "assets"


def check_explainers(docs: dict[str, Any]) -> None:
    """Explainers against their layer manifest, and against the mission content
    (no step or KPI name: an explainer never points at the answer)."""
    if "explainers" not in docs:
        return
    names = [s["name"] for stream in docs["value_streams"]["streams"] for s in stream["steps"]]
    names += [k["name"] for k in docs["kpis"]["kpis"]]
    for e in docs["explainers"]["explainers"]:
        where = f"explainers.yaml: explainer {e['id']}"
        for w, text in _explainer_texts(e):
            hit = next((n for n in names if n.lower() in text.lower()), None)
            if hit:
                raise ContentError(f"{where}: {w} names the step or KPI {hit!r}")
        manifest_path = EXPLAINER_ASSETS / e["assets"] / "manifest.json"
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            raise ContentError(f"{where}: cannot read {manifest_path.name} ({exc}); run tools/explainers/*/export.mjs") from exc
        skins = {layer["id"]: layer["skin"] for layer in manifest.get("layers", [])}
        for i, row in enumerate(e["analogy"]["mapping"]):
            if [skins.get(p) for p in row["pair"]] != ["tuin", "meterkast"]:
                raise ContentError(f"{where} mapping {i}: pair {row['pair']} must name a tuin layer and a meterkast layer")
        for c in e["controls"]:
            for skin, states in (("tuin", ("closed", "open")), ("meterkast", ("off", "on"))):
                if skin in c:
                    for state in states:
                        if f"{c[skin]}_{state}" not in skins:
                            raise ContentError(f"{where}: control {c['id']} has no layer {c[skin]}_{state}")


# ── Spoken lines never name the game ────────────────────────────────────────
# PLAN 2.13 E; docs/superpowers/specs/2026-10-19-dutch-style-guide.md §4: the
# banned words (whole words, outside {tokens}) and what counts as spoken.
# Exported in vocabulary.json, so the Godot test scans the scene consts too.
BANNED_SPOKEN = ["game", "games", "gamen", "spel", "spelletje", "spelletjes", "speler", "spelers", "speelster",
                 "level", "levels", "quest", "quests", "missie", "missies", "player"]
# Real Dutch that contains a banned word ("er staat veel op het spel").
ALLOWED_SPOKEN = ["op het spel"]
_BANNED_RE = re.compile(r"\b(" + "|".join(BANNED_SPOKEN) + r")\b", re.IGNORECASE)
_TOKEN_RE = re.compile(r"\{[^{}]*\}")
# Keys inside a spoken part that hold no Dutch text.
_NOT_SPOKEN = {"id", "label", "tags", "tell", "via", "unlocks", "at", "when", "needs", "kpis", "addresses", "hidden",
               "promise", "routes", "condition", "wait_for"}
_SPOKEN_DIALOG = ["opening", "retry_opening", "warning", "position", "layers", "proposals", "experiments",
                  "co_proposal", "lines", "replies", "outcomes", "beats_after", "block", "variants", "topics",
                  "closing"]
_SPOKEN_MISSION = ["briefing", "debrief", "debrief_first", "debrief_variants", "fail", "reopen", "insights",
                   "questions", "payoff"]


def banned_word(text: str) -> str | None:
    """The first banned word in a spoken line, lower-cased, or None."""
    text = _TOKEN_RE.sub(" ", text.lower())
    for phrase in ALLOWED_SPOKEN:
        text = text.replace(phrase, " ")
    hit = _BANNED_RE.search(text)
    return hit.group(1) if hit else None


def _strings(node: Any, where: str) -> list[tuple[str, str]]:
    """Every string under `node`, skipping keys that hold no text."""
    if isinstance(node, str):
        return [(where, node)]
    if isinstance(node, dict):
        return [s for k, v in node.items() if k not in _NOT_SPOKEN for s in _strings(v, f"{where} {k}")]
    if isinstance(node, list):
        return [s for i, v in enumerate(node) for s in _strings(v, f"{where} {i}")]
    return []


def spoken_texts(docs: dict[str, Any]) -> list[tuple[str, str]]:
    """(where, text) for every line a person says or writes in the world."""
    out: list[tuple[str, str]] = []
    dialogs = docs.get("dialogs") or {}
    for p in dialogs.get("people", []):
        out += _strings(p.get("voice"), f"dialogs.yaml: person {p['id']} voice")
        out += _strings(p.get("voicemail"), f"dialogs.yaml: person {p['id']} voicemail")
    out += _strings({k: v for k, v in (dialogs.get("bank") or {}).items() if k != "labels"}, "dialogs.yaml: bank")
    out += _strings({k: dialogs[k] for k in ("greetings", "quick", "chatter") if k in dialogs}, "dialogs.yaml:")
    for d in dialogs.get("dialogs", []):
        out += _strings({k: d[k] for k in _SPOKEN_DIALOG if k in d}, f"dialogs.yaml: dialog {d['id']}")
    for e in (docs.get("explainers") or {}).get("explainers", []):
        where = f"explainers.yaml: explainer {e['id']}"
        out += _strings(e["analogy"]["limit_line"], f"{where} limit_line")
        out += [s for b in e["beats"] for s in _strings(b["lines"], f"{where} beat {b['id']}")]
    missions = docs.get("missions") or {}
    coach = missions.get("coach") or {}
    out += _strings({k: coach[k] for k in ("stages", "conditional") if k in coach}, "missions.yaml: coach")
    for m in missions.get("missions", []):
        out += _strings({k: m[k] for k in _SPOKEN_MISSION if k in m}, f"missions.yaml: mission {m['id']}")
    for s in (docs.get("scenes") or {}).get("scenes", []):  # the lines and the replies; a choice's label is UI
        out += [(f"scenes.yaml: scene {s['id']} beat {i}", text) for i, b in enumerate(s["beats"])
                for text in [b["line"]] + [o["reply"] for o in b.get("choice", []) if "reply" in o]]
    for place, entry in ((docs.get("places") or {}).get("places") or {}).items():
        out += _strings((entry or {}).get("questions", []), f"places.yaml: {place} questions")
    return out


def check_spoken(docs: dict[str, Any]) -> None:
    for where, text in spoken_texts(docs):
        hit = banned_word(text)
        if hit:
            raise ContentError(f"{where}: {hit!r} names the game in a spoken line (style guide §4): {text!r}")


# ── company.yaml (phase-2 design §1.6, S1-E) ─────────────────────────────────

CAST_FILE = ROOT / "game" / "assets" / "characters" / "cast.json"
COMPANY_KEYS = {"company", "sites", "departments", "externals", "history", "numbers"}
DEPARTMENT_KEYS = {"id", "name", "site", "head", "reports_to", "teams"}
TEAM_KEYS = {"id", "name", "pool", "lead", "members", "headcount", "about"}
NUMBER_KEYS = {"id", "label", "value", "unit", "source", "estimate"}
# The source domains Merijn approved (CLAUDE.md, network rule); a number from anywhere
# else is an estimate until he approves the domain.
SOURCE_DOMAINS = ("rijksoverheid.nl", "officielebekendmakingen.nl", "wetten.overheid.nl", "acm.nl",
                  "netbeheernederland.nl", "cbs.nl", "knmi.nl", "nen.nl", "tennet.eu")


def validate_company(doc: Any, source: str) -> None:
    """The company's shape: sites, departments with a head and teams, externals, the
    2012 programme, and numbers that carry a source or an estimate."""
    if not isinstance(doc, dict):
        raise ContentError(f"{source}: expected a mapping at the top level")
    _known_keys(doc, COMPANY_KEYS, source)
    _require_strings(_mapping(doc, "company", {"name", "region", "about"}, source), ["name", "region", "about"],
                     f"{source} company")
    sites = {s["id"] for s in _entries(doc, "sites", source)}
    departments = _entries(doc, "departments", source)
    for d in departments:
        where = f"{source}: department '{d['id']}'"
        _known_keys(d, DEPARTMENT_KEYS, where)
        if d.get("site") not in sites:
            raise ContentError(f"{where}: unknown site {d.get('site')!r}")
        _person_ref(d.get("head"), f"{where} head")
        teams = _entries(d, "teams", where)
        for t in teams:
            _validate_team(t, f"{where} team '{t['id']}'")
    _check_ids([t["id"] for d in departments for t in d["teams"]], "team", source)
    ids = {d["id"] for d in departments}
    for d in departments:
        boss = d.get("reports_to")
        if d["id"] == "directie" and boss is not None:
            raise ContentError(f"{source}: the directie reports to no department (it reports to the hoofdkantoor)")
        if d["id"] != "directie" and boss not in ids:
            raise ContentError(f"{source}: department '{d['id']}' reports to unknown department {boss!r}")
    for e in _entries(doc, "externals", source, name="title"):
        _known_keys(e, {"id", "title", "organisation"}, f"{source}: external '{e['id']}'")
        _require_strings(e, ["organisation"], f"{source}: external '{e['id']}'")
    for h in _entries(doc, "history", source):
        _require_strings(h, ["about"], f"{source}: history '{h['id']}'")
    for n in _entries(doc, "numbers", source, name="label"):
        where = f"{source}: number '{n['id']}'"
        _known_keys(n, NUMBER_KEYS, where)
        _number(n, "value", where, 0)
        _require_strings(n, ["unit"], where)
        _evidence(n, where)


def _validate_team(t: dict, where: str) -> None:
    _known_keys(t, TEAM_KEYS, where)
    if "lead" in t:
        _person_ref(t["lead"], f"{where} lead", named=False)
    members = t.get("members", [])
    if not isinstance(members, list):
        raise ContentError(f"{where}: 'members' must be a list of {{id, title}}")
    for m in members:
        _person_ref(m, f"{where} member", named=False)
    headcount = t.get("headcount")
    if "pool" in t:
        if headcount is not None and headcount.get("pool") != t["pool"]:
            raise ContentError(f"{where}: a team with a pool has the pool's headcount (value_streams.yaml)")
        return
    if not isinstance(headcount, dict):
        raise ContentError(f"{where}: a team without a pool needs a 'headcount' with a source or an estimate")
    _known_keys(headcount, {"value", "source", "estimate"}, f"{where} headcount")
    _number(headcount, "value", f"{where} headcount", 1, integer=True)
    _evidence(headcount, f"{where} headcount")


def _person_ref(ref: Any, where: str, named: bool = True) -> None:
    """{id, title} for someone in the cast, or (a head only) {name, title} for someone not yet."""
    keys = {"id", "title"} | ({"name"} if named else set())
    if not isinstance(ref, dict) or ("id" in ref) == ("name" in ref):
        raise ContentError(f"{where}: needs {{id, title}}" + (" or {name, title}" if named else ""))
    _known_keys(ref, keys, where)
    _require_strings(ref, ["title", "id" if "id" in ref else "name"], where)


def _evidence(item: dict, where: str) -> None:
    """A number carries a source on an approved domain, or an estimate with its reasoning."""
    if ("source" in item) == ("estimate" in item):
        raise ContentError(f"{where}: give a source or an estimate (one of them)")
    if "estimate" in item:
        _require_strings(item, ["estimate"], where)
        return
    src = item["source"]
    if not isinstance(src, dict):
        raise ContentError(f"{where}: 'source' is {{url, title, date}}")
    _known_keys(src, {"url", "title", "date"}, f"{where} source")
    _require_strings(src, ["url", "title", "date"], f"{where} source")
    host = re.sub(r"^https://([^/]+)/.*$", r"\1", src["url"])
    if not any(host == d or host.endswith("." + d) for d in SOURCE_DOMAINS):
        raise ContentError(f"{where}: {src['url']!r} is not an approved source domain (an estimate until Merijn "
                           f"approves it)")


def company_people(company: dict) -> dict[str, dict]:
    """Every placed person: id → {title, department ("" for an external), team, lead
    (the team's lead's id, or "")}."""
    out: dict[str, dict] = {}

    def place(ref: dict, department: str, team: str, lead: str) -> None:
        pid = ref.get("id")
        if pid is None:
            return
        if pid in out:
            raise ContentError(f"company.yaml: {pid!r} is placed twice")
        out[pid] = {"title": ref["title"], "department": department, "team": team, "lead": lead}

    for d in company["departments"]:
        place(d["head"], d["id"], "", "")
        for t in d["teams"]:
            lead = t.get("lead", {})
            place(lead, d["id"], t["id"], "") if lead else None
            for m in t.get("members", []):
                place(m, d["id"], t["id"], lead.get("id", ""))
    for e in company["externals"]:
        place(e, "", "", "")
    return out


def company_managers(company: dict, names: dict[str, str] | None = None) -> dict[str, str]:
    """Each Voltana person's manager by name: their team's lead, else their department's
    head, else (the head themself) the head of the department theirs reports to; "" for
    the directeur. `names`: id → name for cast ids (the dialogs' and cast's names)."""
    names = names or _cast_names()
    depts = {d["id"]: d for d in company["departments"]}

    def name_of(ref: dict) -> str:
        return ref.get("name") or names.get(ref.get("id"), ref.get("id", ""))

    out = {}
    for pid, p in company_people(company).items():
        if not p["department"]:
            continue
        d = depts[p["department"]]
        if p["lead"]:
            out[pid] = names.get(p["lead"], p["lead"])
        elif d["head"].get("id") != pid:
            out[pid] = name_of(d["head"])
        else:
            boss = d.get("reports_to")
            out[pid] = name_of(depts[boss]["head"]) if boss else ""
    return out


def _cast() -> list[dict]:
    try:
        return json.loads(CAST_FILE.read_text(encoding="utf-8"))["characters"]
    except (OSError, ValueError, KeyError) as exc:
        raise ContentError(f"{CAST_FILE.name}: cannot read the cast ({exc})") from exc


def _cast_names() -> dict[str, str]:
    return {c["id"]: c.get("name", "") for c in _cast()}


def check_company(docs: dict[str, Any]) -> None:
    """The company against the cast, the dialogs' people and the pools: everyone placed
    once with the same title everywhere; heads and leads in the cast (or named heads not
    in it); pooled teams get their pool's headcount."""
    company = docs.get("company")
    if company is None:
        return
    cast = _cast()
    speakers = docs.get("dialogs", {}).get("people", [])
    roles: dict[str, list[tuple[str, str]]] = {}
    for c in cast:
        roles.setdefault(c["id"], []).append(("cast.json", c.get("role", "")))
    for p in speakers:
        roles.setdefault(p["id"], []).append(("dialogs.yaml", p.get("role", "")))
    placed = company_people(company)
    for pid, said in roles.items():
        if pid not in placed:
            raise ContentError(f"company.yaml: {pid!r} ({said[0][0]}) is not in company.yaml")
        for where, role in said:
            if role != placed[pid]["title"]:
                raise ContentError(f"company.yaml: {pid!r}: title {placed[pid]['title']!r} but {where} says {role!r}")
    cast_names = {c.get("name") for c in cast} | {p.get("name") for p in speakers}
    for d in company["departments"]:
        head = d["head"]
        if "id" in head and head["id"] not in roles and "dialogs" in docs:
            raise ContentError(f"company.yaml: department '{d['id']}': {head['id']!r} is not in the cast")
        if "name" in head and head["name"] in cast_names:
            raise ContentError(f"company.yaml: department '{d['id']}': {head['name']!r} is in the cast: name them by id")
    for pid in placed if "dialogs" in docs else []:  # a content set without people knows only the cast
        if pid not in roles:
            raise ContentError(f"company.yaml: {pid!r} is not in the cast")
    pools = {p["id"]: p for p in docs["value_streams"]["pools"]}
    for d in company["departments"]:
        for t in d["teams"]:
            if "pool" not in t:
                continue
            if t["pool"] not in pools:
                raise ContentError(f"company.yaml: team '{t['id']}': unknown pool {t['pool']!r}")
            t["headcount"] = {"value": pools[t["pool"]]["headcount"], "pool": t["pool"]}


# ── scenes.yaml (a milestone's scene, phase-2 design §3.1) ───────────────────
# A scene plays where it happens (`room`, opened for its milestone), with the people
# `present`: beats of SceneLines (speaker, line), a beat only when its `needs` hold
# (the facts choose the lines), and at most one beat asking the player a question
# (`choice`): each answer a flag remembered for later, and what is said back.
SCENE_KEYS = {"id", "room", "present", "beats"}
BEAT_KEYS = {"speaker", "line", "needs", "choice"}
CHOICE_KEYS = {"label", "fact", "reply"}
CHOICE_OPTIONS = (2, 4)


def validate_scenes(doc: Any, source: str) -> None:
    _require_strings(doc, [], source)
    for s in _entries(doc, "scenes", source, name="room"):
        where = f"{source}: scene '{s['id']}'"
        _known_keys(s, SCENE_KEYS, where)
        present = _string_list(s, "present", where)
        beats = s.get("beats")
        if not isinstance(beats, list) or not beats or not all(isinstance(b, dict) for b in beats):
            raise ContentError(f"{where}: 'beats' must be a non-empty list of {{speaker, line}}")
        if sum(1 for b in beats if "choice" in b) > 1:
            raise ContentError(f"{where}: one question for the player at most")
        for i, b in enumerate(beats):
            at = f"{where} beat {i}"
            _known_keys(b, BEAT_KEYS, at)
            _require_strings(b, ["speaker", "line"], at)
            if b["speaker"] not in present:
                raise ContentError(f"{at}: {b['speaker']!r} speaks but is not 'present'")
            if "needs" in b:
                _validate_needs(b["needs"], at)
            if "choice" in b:
                _validate_choice(b["choice"], at)


def _validate_choice(options: Any, where: str) -> None:
    low, high = CHOICE_OPTIONS
    if not isinstance(options, list) or not low <= len(options) <= high or not all(isinstance(o, dict) for o in options):
        raise ContentError(f"{where}: 'choice' lists {low} to {high} answers {{label, fact, reply?}}")
    for o in options:
        _known_keys(o, CHOICE_KEYS, f"{where} choice")
        _require_strings(o, ["label", "fact"] + (["reply"] if "reply" in o else []), f"{where} choice")
        if _atom_parts(o["fact"], f"{where} choice")[0] != "flag":
            raise ContentError(f"{where}: a choice's fact is flag:<name> (got {o['fact']!r})")


def _scene_flags(docs: dict[str, Any]) -> dict[str, set]:
    """scene id → the flags its answers set."""
    return {s["id"]: {o["fact"] for b in s["beats"] for o in b.get("choice", [])}
            for s in (docs.get("scenes") or {}).get("scenes", [])}


def check_scenes(docs: dict[str, Any]) -> None:
    """Every milestone's scene exists and is used once; it plays in a room its milestone
    opens (world.yaml), with people of the cast; its facts name real things."""
    scenes = {s["id"]: s for s in (docs.get("scenes") or {}).get("scenes", [])}
    # Who can be named: the talkers and the cast (Ruud, the coach, has no talks of his own;
    # a customer has no body, only talks). A content set without people names nobody.
    people = {p["id"] for p in (docs.get("dialogs") or {}).get("people", [])}
    if people:
        people |= {c["id"] for c in _cast()}
    users: dict[str, str] = {}
    for m in docs["missions"]["missions"]:
        for e in m.get("payoff", []) if people else []:
            if e["who"] not in people:
                raise ContentError(f"missions.yaml: mission '{m['id']}' payoff: {e['who']!r} is not in the cast")
        if "scene" not in m:
            continue
        where = f"missions.yaml: mission '{m['id']}'"
        if m["scene"] not in scenes:
            raise ContentError(f"{where}: names no scene {m['scene']!r} (content/scenes.yaml)")
        if m["scene"] in users:
            raise ContentError(f"{where}: scene {m['scene']!r} is already {users[m['scene']]!r}'s")
        users[m["scene"]] = m["id"]
    rooms = {r["id"]: r for r in (docs.get("world") or {}).get("rooms", [])}
    index = _fact_index(docs)
    for s in scenes.values():
        where = f"scenes.yaml: scene '{s['id']}'"
        if s["id"] not in users:
            raise ContentError(f"{where}: no milestone plays it")
        if rooms:
            room = rooms.get(s["room"])
            if room is None:
                raise ContentError(f"{where}: unknown room {s['room']!r}")
            if not ({OPEN_FROM_START, users[s["id"]]} & set(room["opens_with"])):
                raise ContentError(f"{where}: room {s['room']!r} must open with {users[s['id']]!r} (world.yaml opens_with)")
        for person in s.get("present", []) if people else []:
            if person not in people:
                raise ContentError(f"{where}: {person!r} is not in the cast")
        for b in s["beats"]:
            for atom in _needs(b["needs"], where) if "needs" in b else []:
                _atom_robust(atom, where, index)


VALIDATORS: dict[str, Callable[[Any, str], None]] = {
    "game": validate_game,
    "company": validate_company,
    "value_streams": validate_value_streams,
    "countermeasures": validate_countermeasures,
    "missions": validate_missions,
    "kpis": validate_kpis,
    "concepts": validate_concepts,
    "dialogs": validate_dialogs,
    "discoveries": validate_discoveries,
    "explainers": validate_explainers,
    "world": validate_world,
    "places": validate_places,
    "scenes": validate_scenes,
}
# Registered files a content set may leave out.
OPTIONAL = {"dialogs", "explainers", "world", "places", "company", "scenes"}

# Checks that need several files at once. Each gets {stem: document}.
CROSS_CHECKS: list[Callable[[dict[str, Any]], None]] = [check_kpis, check_problems, check_missions, check_concepts,
                                                      check_dialogs, check_discoveries, check_explainers, check_world,
                                                      check_places, check_spoken, check_tells, check_company,
                                                      check_scenes]


def _validator_for(stem: str) -> Callable[[Any, str], None] | None:
    return validate_problems if stem.startswith(PROBLEM_FILES) else VALIDATORS.get(stem)


def load_content(content_dir: Path | None = None) -> dict[str, Any]:
    """Parse and validate every YAML file. Returns {stem: document}."""
    content_dir = content_dir or CONTENT_DIR
    docs: dict[str, Any] = {}
    for path in sorted(content_dir.glob("*.yaml")):
        validator = _validator_for(path.stem)
        if validator is None:
            raise ContentError(f"{path.name}: no validator registered in tools/build_content.py")
        try:
            doc = yaml.load(path.read_text(encoding="utf-8"), Loader=_StrictLoader)
        except yaml.YAMLError as exc:
            raise ContentError(f"{path.name}: invalid YAML — {exc}") from exc
        except ContentError as exc:
            raise ContentError(f"{path.name}: {exc}") from exc
        validator(doc, path.name)
        docs[path.stem] = doc
    missing = sorted(set(VALIDATORS) - OPTIONAL - set(docs))
    if missing:
        raise ContentError(f"missing content files: {', '.join(m + '.yaml' for m in missing)}")
    for check in CROSS_CHECKS:
        check(docs)
    merge_dialog_clues(docs)
    name_dialog_items(docs)
    order_place_tools(docs)
    docs["vocabulary"] = vocabulary()
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
