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


def _entries(doc: dict, key: str, source: str) -> list[dict]:
    items = doc.get(key)
    if not isinstance(items, list) or not all(isinstance(i, dict) for i in items):
        raise ContentError(f"{source}: '{key}' must be a list of mappings")
    _check_ids([i.get("id") for i in items], key, source)
    for item in items:
        _require_strings(item, ["name"], f"{source}: {key} '{item['id']}'")
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
                "plausible_causes", "mismatch_note", "countermeasures", "teaches", "effects", "clues", "cost_per_week"}
COUNTERMEASURE_KEYS = {"id", "tier", "name", "category", "description", "budget", "team_hours", "decay_days", "needs",
                       "preparation",
                       "multipliers", "effects", "unlocks", "sustains", "trust", "aftermath"}
# A short-term fix's later cost (tier-2 draft §0.1): effects for `days` from
# `after_days` after the Act, and a one-off cost.
AFTERMATH_KEYS = {"after_days", "days", "effects", "cost"}
UNLOCKS = ["kpi_board"]  # CountermeasureDef.UNLOCKS: what a countermeasure opens in the game
CLUE_KEYS = {"tool", "text", "key", "depth", "at", "note", "teaches"}
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


# ── facts and needs (path dependence, game/src/rules/facts.gd) ───────────────
# A fact kind → how many ids follow it ("chose:<problem>:<cm>"). The dialog
# facts (heard: ... blocked:) name a dialog; they are checked once dialogs exist.
FACT_KINDS = {"done": 1, "failed": 1, "chose": 2, "standardised": 1, "poor_fix": 1, "repaired": 1, "fork_first": 2,
              "flag": 1, "heard": 1, "committed": 1, "complied": 1, "partial": 1, "blocked": 1,
              "checked": 1, "accepted": 1}  # Facts.KINDS
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


def _sets_flags(item: dict, where: str) -> list:
    flags = _string_list(item, "sets_flags", where)
    for flag in flags:
        if _atom_parts(flag, where)[0] != "flag":
            raise ContentError(f"{where}: 'sets_flags' entries are flag:<name> (got {flag!r})")
    return flags


# training: the Inwerkweek before the campaign; it takes no side slot and the
# coach helps with it (Missions).
MISSION_KINDS = ["main", "side", "training"]
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
                "fork", "debrief_first", "reopen", "sets_flags", "questions", "debrief_variants", "containment"}
# A safety mission's containment (audit §2.4.1): a short measure against an
# acute risk, taken once while the mission is active; it fades after `days`.
CONTAINMENT_KEYS = {"name", "budget", "days", "effects"}
MAX_CONTAINMENT_DAYS = 30  # containment buys time for the fix; it is not the fix
DEBRIEF_VARIANTS = ["blamed", "poor_fix", "not_standardised"]  # Missions.DEBRIEF_VARIANTS, in the order they win
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
    solved: dict[str, str] = {}
    for m in missions.values():
        where = f"missions.yaml: mission '{m['id']}'"
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
    return {
        "missions": {m["id"] for m in missions},
        "deadlines": {m["id"] for m in missions if "deadline_days" in m},
        "problems": {p["id"]: set(p["countermeasures"]) for _, p in _all_problems(docs)},
        "fork_members": {(m["fork"]["group"], m["id"]) for m in missions if "fork" in m},
        "flags": {f for m in missions for f in m.get("sets_flags", [])},
        "closable": {c for m in missions for c in m.get("fail_closes", [])},
        "solved_by": {m["goal"]["problem"]: m["id"] for m in missions if m["goal"]["type"] == "solve"},
    }


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
    if kind in ("chose", "standardised", "poor_fix", "repaired", "checked") and ids[0] not in index["problems"]:
        raise ContentError(f"{where}: {atom!r} names an unknown problem")
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
    index = dict(index, flags_by={m["id"]: set(m.get("sets_flags", [])) for m in missions.values()})
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
DIALOG_TAGS = ["claim", "feeling", "hesitation", "admission", "doubt"]
DIALOG_ARCHETYPES = ["defender", "cynic", "craftsman", "overloaded", "rule_bound", "quiet", "customer_upset", "expert"]
DIALOG_KINDS = ["persuade", "checkin", "expert"]
DIALOG_MOODS = ["goed", "neutraal", "gespannen", "moe", "stil"]
DIALOG_OUTCOMES = ["commitment", "partial", "heard", "none", "blocked", "compliance", "ruined", "lifted"]
LAYERS = {"interest": (40, 65), "concern": (60, 85)}  # layer id → the range its `at` threshold must lie in
REPLY_SITUATIONS = ["lands", "misses", "too_early"]
# The bank's fallback replies: every move that has no reply of its own elsewhere
# (a layer, a proposal, an outcome) needs these situations.
BANK_REPLIES = {**{m: ["lands", "misses"] for m in LISTEN_MOVES + ["perspective", "show_data", "propose_experiment"]},
                "pressure": ["lands"], "confront": ["lands"], "repair": ["lands"]}
BANK_SPECIAL = ["repeat", "refusal", "no_proposal", "other_data", "lucky_guess", "no_repair", "patience_low",
                "cooling_down"]
# Ruud's line after a main-mission talk that ended this way (People.coach_question;
# pressure: a yes under pressure).
COACH_AFTER = ["pressure", "ruined", "blocked", "commitment"]
PERSON_KEYS = {"id", "name", "short", "role", "place", "team", "archetype", "trust", "morale", "voice"}
DIALOG_KEYS = {"id", "name", "person", "kind", "mission", "requires_clue", "needs", "owns", "kpi_team", "mood",
               "patience", "opening", "retry_opening", "position", "layers", "data", "proposals", "experiments",
               "co_proposal", "condition_needs", "block", "lines", "replies", "outcomes", "variants", "trigger",
               "tutorial", "prompt", "warning"}
LAYER_KEYS = {"id", "at", "via", "text", "tags", "lead_in", "condition", "unlocks"}
PROPOSAL_KEYS = {"id", "name", "text", "kpis", "addresses", "reply", "hidden"}
VARIANT_KEYS = {"needs", "mood", "position", "layers"}


def _line(item: Any, where: str) -> dict:
    """A spoken line: {text, tags?}."""
    if not isinstance(item, dict):
        raise ContentError(f"{where}: a line is a mapping with a text and optional tags")
    _known_keys(item, {"text", "tags"}, where)
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
    _known_keys(doc, {"people", "bank", "dialogs"}, source)
    for p in _entries(doc, "people", source):
        where = f"{source}: person '{p['id']}'"
        _known_keys(p, PERSON_KEYS, where)
        _require_strings(p, ["role", "place", "team"] + (["short"] if "short" in p else []), where)
        _one_of(p, "archetype", DIALOG_ARCHETYPES, where)
        _number(p, "trust", where, 0, 100, integer=True)
        _number(p, "morale", where, 0, 100, integer=True, default=60)
    _validate_bank(doc.get("bank"), f"{source}: bank")
    for d in _entries(doc, "dialogs", source):
        _validate_dialog(d, f"{source}: dialog '{d['id']}'")


def _validate_bank(bank: Any, where: str) -> None:
    if not isinstance(bank, dict):
        raise ContentError(f"{where}: needs labels, player, replies, special and outcomes")
    _known_keys(bank, {"labels", "player", "replies", "special", "outcomes", "coach"}, where)
    labels = _mapping(bank, "labels", {"bands", "cue", "chips", "outcomes"}, where)
    if len(_string_list(labels, "bands", f"{where} labels")) != 5:
        raise ContentError(f"{where} labels: 'bands' names the five openness bands")
    _require_strings(labels, ["cue"], f"{where} labels")
    for key, ids in (("chips", DIALOG_MOVES), ("outcomes", DIALOG_OUTCOMES)):
        _require_strings(_mapping(labels, key, set(ids), f"{where} labels"), ids, f"{where} labels {key}")
    _require_strings(_mapping(bank, "player", set(DIALOG_MOVES), where), DIALOG_MOVES, f"{where} player")
    replies = _mapping(bank, "replies", set(BANK_REPLIES), where)
    for move, situations in BANK_REPLIES.items():
        if not isinstance(replies.get(move), dict) or set(situations) - set(replies[move]):
            raise ContentError(f"{where} replies: {move!r} needs {', '.join(situations)}")
        _replies({move: replies[move]}, f"{where} replies")
    _require_strings(_mapping(bank, "special", set(BANK_SPECIAL), where), BANK_SPECIAL, f"{where} special")
    _require_strings(_mapping(bank, "outcomes", set(DIALOG_OUTCOMES), where), DIALOG_OUTCOMES, f"{where} outcomes")
    coach = _mapping(bank, "coach", {"questions", "after"}, where)
    if coach:
        _string_list(coach, "questions", f"{where} coach", allow_empty=False)
        after = _mapping(coach, "after", set(COACH_AFTER), f"{where} coach")
        _require_strings(after, list(after), f"{where} coach after")


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


def _validate_dialog(d: dict, where: str) -> None:
    _known_keys(d, DIALOG_KEYS, where)
    _require_strings(d, ["person", "opening"], where)
    for key in ("retry_opening", "warning"):
        if key in d:
            _require_strings(d, [key], where)
    _one_of(d, "kind", DIALOG_KINDS, where)
    if "mood" in d:
        _one_of(d, "mood", DIALOG_MOODS, where)
    _number(d, "patience", where, 3, 15, integer=True, default=10)
    if not isinstance(d.get("tutorial", False), bool):
        raise ContentError(f"{where}: 'tutorial' must be true or false (an Act 0 talk that cannot be ruined)")
    _line(d.get("position"), f"{where} position")
    _layers(d.get("layers"), where)
    proposals = _entries(d, "proposals", where) if "proposals" in d else []
    experiments = _entries(d, "experiments", where) if "experiments" in d else []
    for item in proposals + experiments:
        at = f"{where} proposal '{item['id']}'"
        is_proposal = any(item is p for p in proposals)
        _known_keys(item, PROPOSAL_KEYS, at)
        _require_strings(item, ["text"], at)
        if "reply" in item:
            _require_strings(item, ["reply"], at)
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
    for layer in d["layers"]:
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
    lines = d.get("lines", {})
    if not isinstance(lines, dict) or set(lines) - set(DIALOG_MOVES):
        raise ContentError(f"{where}: 'lines' maps a move to the player's line (unknown move in {sorted(lines)})")
    _require_strings(lines, list(lines), f"{where} lines")
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
    if d["kind"] == "checkin":
        _checkin(d, proposals + experiments, where)
    else:
        _require_strings(d, ["mission"], where)
        # No single right answer (spec §9.2 rule 10): two ways at least to meet the concern.
        if d["kind"] == "persuade" and sum(1 for i in proposals + experiments if "concern" in i.get("addresses", [])) < 2:
            raise ContentError(f"{where}: no single right answer: needs two proposals or experiments that address the concern")


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
        _line({k: layer[k] for k in ("text", "tags") if k in layer}, at)
        if "condition" in layer:
            _require_strings(layer, ["condition"], at)
        unlocks = _mapping(layer, "unlocks", {"clue", "facts", "proposals"}, at)
        for fact in _string_list(unlocks, "facts", f"{at} unlocks"):
            if _atom_parts(fact, f"{at} unlocks")[0] != "heard":
                raise ContentError(f"{at} unlocks: {fact!r} is not a fact heard:<id>")
        _string_list(unlocks, "proposals", f"{at} unlocks")
        if "clue" in unlocks:
            clue = unlocks["clue"]
            if not isinstance(clue, dict):
                raise ContentError(f"{at} unlocks: 'clue' is a mapping with key, depth and text")
            _known_keys(clue, {"key", "depth", "text", "note"}, f"{at} unlocks clue")
            _require_strings(clue, ["text"], f"{at} unlocks clue")
            if not isinstance(clue.get("key"), bool):
                raise ContentError(f"{at} unlocks clue: 'key' must be true or false")
            _number(clue, "depth", f"{at} unlocks clue", 0, integer=True)
    concern = layers[1]
    if not isinstance(concern.get("lead_in"), dict):
        raise ContentError(f"{where}: the concern needs a lead_in (the line that carries the cue)")
    if "hesitation" not in _line(concern["lead_in"], f"{where} concern lead_in").get("tags", []):
        raise ContentError(f"{where}: the concern's lead_in carries the tag hesitation")


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


def _checkin(d: dict, items: list[dict], where: str) -> None:
    """A check-in has no mission, owns nothing and asks no KPIs (spec §9.2 rule 12)."""
    for key in ("mission", "owns", "kpi_team", "requires_clue", "data", "condition_needs", "block", "co_proposal"):
        if key in d:
            raise ContentError(f"{where}: a check-in has no {key!r}")
    if any("kpis" in i for i in items):
        raise ContentError(f"{where}: a check-in proposes no KPIs")
    trigger = d.get("trigger")
    if not isinstance(trigger, dict) or not trigger:
        raise ContentError(f"{where}: a check-in needs a trigger (morale_below and/or needs)")
    _known_keys(trigger, {"morale_below", "needs"}, f"{where} trigger")
    if "morale_below" in trigger:
        _number(trigger, "morale_below", f"{where} trigger", 1, 100, integer=True)
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
    index = _fact_index(docs)
    clue_ids = {f"{p['id']}:{i}" for p in problems.values() for i in range(len(p["clues"]))}
    for d in dialogs.values():
        where = f"dialogs.yaml: dialog '{d['id']}'"
        if d["person"] not in people:
            raise ContentError(f"{where}: unknown person {d['person']!r}")
        for expr in _needs_of(d):
            for atom in _needs(expr, where):
                _dialog_atom_robust(atom, where, index, dialogs, heard)
        if d.get("requires_clue") is not None and d["requires_clue"] not in clue_ids:
            raise ContentError(f"{where}: requires unknown clue {d['requires_clue']!r}")
        if "block" in d and not any("none" not in r["needs"] and _robust_route(r["needs"], where, index, dialogs, heard)
                                    for r in d["block"]["routes"]):
            raise ContentError(f"{where}: never game over: the block needs a route no failure or skip can close")
        if d["kind"] != "checkin":
            _check_mission_dialog(d, where, missions, problems, net)


def _check_talk_goals(docs: dict[str, Any]) -> None:
    """A talk_to goal names a dialog of its own mission (spec §9.2 rule 4)."""
    dialogs = {d["id"]: d for d in docs.get("dialogs", {}).get("dialogs", [])}
    for m in docs["missions"]["missions"]:
        if m["goal"]["type"] != "talk_to":
            continue
        where, d = f"missions.yaml: mission '{m['id']}'", dialogs.get(m["goal"]["dialog"])
        if d is None:
            raise ContentError(f"{where}: talk_to names unknown dialog {m['goal']['dialog']!r}")
        if d.get("mission") != m["id"]:
            raise ContentError(f"{where}: dialog {d['id']!r} belongs to mission {d.get('mission')!r}")


def _all_layers(d: dict) -> list[list[dict]]:
    return [d["layers"]] + [v["layers"] for v in d.get("variants", []) if "layers" in v]


def _needs_of(d: dict) -> list[dict]:
    exprs = [d[k] for k in ("needs", "condition_needs") if k in d]
    exprs += [r["needs"] for r in d.get("block", {}).get("routes", [])]
    exprs += [v["needs"] for v in d.get("variants", [])]
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


def _check_mission_dialog(d: dict, where: str, missions: dict, problems: dict, net: dict) -> None:
    mission = missions.get(d["mission"])
    if mission is None:
        raise ContentError(f"{where}: unknown mission {d['mission']!r}")
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


def merge_dialog_clues(docs: dict[str, Any]) -> None:
    """Append every clue a concern unlocks to its owned problem's clues (tool
    conversation at the person's place, marked with the dialog: only the
    conversation reveals it) and put the clue's id in the dialog instead."""
    if "dialogs" not in docs:
        return
    people = {p["id"]: p for p in docs["dialogs"]["people"]}
    problems = {p["id"]: (stem, p) for stem, p in _all_problems(docs)}
    for d in docs["dialogs"]["dialogs"]:
        for layers in _all_layers(d):
            unlocks = layers[1].get("unlocks", {})
            if not isinstance(unlocks.get("clue"), dict):
                continue
            stem, problem = problems[d["owns"]]
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
        for key in ("window_days", "days", "count", "experiments", "score"):
            if key in trigger:
                _number(trigger, key, f"{where} trigger", 1, integer=True)
        if "hours" in trigger and not (isinstance(trigger["hours"], list) and len(trigger["hours"]) == 2
                                       and all(isinstance(h, int) and 0 <= h <= 24 for h in trigger["hours"])):
            raise ContentError(f"{where} trigger: 'hours' is [from, to], whole hours")
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
        "dialog_kinds": DIALOG_KINDS, "dialog_moods": DIALOG_MOODS, "dialog_outcomes": DIALOG_OUTCOMES,
    }


# Required files and their validators; problems_tier<n>.yaml files (one per
# tier) all use validate_problems.
VALIDATORS: dict[str, Callable[[Any, str], None]] = {
    "game": validate_game,
    "value_streams": validate_value_streams,
    "countermeasures": validate_countermeasures,
    "missions": validate_missions,
    "kpis": validate_kpis,
    "concepts": validate_concepts,
    "dialogs": validate_dialogs,
    "discoveries": validate_discoveries,
}
# Registered files a content set may leave out.
OPTIONAL = {"dialogs"}

# Checks that need several files at once. Each gets {stem: document}.
CROSS_CHECKS: list[Callable[[dict[str, Any]], None]] = [check_kpis, check_problems, check_missions, check_concepts,
                                                      check_dialogs, check_discoveries]


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
