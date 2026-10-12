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


def _known_keys(d: dict, allowed: set[str], where: str) -> None:
    """Reject keys nobody reads, such as a misspelt optional field."""
    unknown = sorted(str(k) for k in d if k not in allowed)
    if unknown:
        raise ContentError(f"{where}: unknown key(s) {', '.join(map(repr, unknown))}")


def _check_ids(ids: list, label: str, where: str) -> None:
    for i in ids:
        if not isinstance(i, str) or not _ID.match(i):
            raise ContentError(f"{where}: every {label} entry needs a lowercase snake_case 'id' (got {i!r})")
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
            # A dossier that waited too long goes back to an earlier step.
            _number(step, "stale_after_days", where, 1)
            if not _earlier(step_ids, step.get("stale_to"), step["id"]):
                raise ContentError(f"{where}: 'stale_to' must name an earlier step (got {step.get('stale_to')!r})")
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
KPIS = ["throughput", "lead_time", "first_time_right", "on_time"]
SEVERITIES = ["low", "medium", "high", "critical"]
VISIBILITIES = ["obvious", "subtle", "hidden"]
PROBLEM_KEYS = {"id", "tier", "name", "step", "waste", "severity", "visibility", "kpi", "symptoms", "root_cause",
                "plausible_causes", "mismatch_note", "countermeasures", "teaches", "effects", "clues", "cost_per_week"}
COUNTERMEASURE_KEYS = {"id", "tier", "name", "category", "description", "budget", "team_hours", "decay_days",
                       "multipliers", "effects"}
CLUE_KEYS = {"tool", "text", "key", "depth", "at", "note", "teaches"}
EFFECT_KEYS = {"target", "property", "value"}
CHECK_PASS = 0.5  # the effectiveness a Check needs to pass (Pdca.CHECK_PASS)
# property → (target kind, required step kind or None, value type: factor | number | bool | count | reserve | step)
EFFECT_PROPERTIES = {
    "touch_time": ("step", "work", "factor"), "ftr": ("step", "work", "number"),
    "applies": ("step", None, "number"), "wait_time": ("step", "wait", "factor"),
    "availability": ("pool", None, "number"), "headcount": ("pool", None, "number"),
    "lead_time": ("stock", None, "factor"), "reorder_point": ("stock", None, "number"),
    "demand": ("arrivals", None, "factor"), "reserve": ("pool", None, "reserve"),
    "preempts": ("stream", None, "bool"), "wip_limit": ("stream", None, "count"),
    "call_rate": ("stream", None, "factor"),
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
        if e.get("property") not in EFFECT_PROPERTIES:
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
        _effects_shape(cm, where)


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


def _validate_clues(p: dict, where: str) -> None:
    clues = p.get("clues")
    if not isinstance(clues, list) or not clues or not all(isinstance(c, dict) for c in clues):
        raise ContentError(f"{where}: 'clues' must be a non-empty list of mappings")
    keys_at = set()
    for i, c in enumerate(clues):
        _known_keys(c, CLUE_KEYS, f"{where} clue {i}")
        if c.get("tool") not in TOOLS:
            raise ContentError(f"{where} clue {i}: unknown tool {c.get('tool')!r}")
        _require_strings(c, ["text"], f"{where} clue {i}")
        if not isinstance(c.get("key"), bool):
            raise ContentError(f"{where} clue {i}: 'key' must be true or false")
        _number(c, "depth", f"{where} clue {i}", 0, integer=True)
        if c["key"]:
            keys_at.add(c["depth"])
    if 0 not in keys_at:
        raise ContentError(f"{where}: needs a key clue at depth 0 (where the investigation starts)")
    for c in clues:
        if c["depth"] > 0 and c["depth"] - 1 not in keys_at:
            raise ContentError(f"{where}: a clue at depth {c['depth']} needs a key clue at depth {c['depth'] - 1}")


def _network_index(streams_doc: dict) -> dict:
    """What effects and places can refer to, by target kind: steps ('stream.step',
    with their kind and their stream's step ids), pools, stock items, streams,
    and arrivals (a stream, or one of its sources with an id: 'stream.source')."""
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
    }


def _check_effect(e: dict, where: str, net: dict) -> None:
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
    if value_type == "step" and value != "":
        step = net["step"][target]
        if not _earlier(step["stream_ids"], value, step["id"]):
            raise ContentError(f"{where}: can only start with an earlier step (got {value!r})")


def _check_countermeasure(cm: dict, net: dict) -> None:
    where = f"countermeasures.yaml: '{cm['id']}'"
    for pool in cm.get("team_hours", {}):
        if pool not in net["pool"]:
            raise ContentError(f"{where}: team_hours for unknown pool {pool!r}")
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
    net = _network_index(docs["value_streams"])
    cms = {c["id"]: c for c in docs["countermeasures"]["countermeasures"]}
    for cm in cms.values():
        _check_countermeasure(cm, net)
    for stem, doc in docs.items():
        if stem.startswith(PROBLEM_FILES):
            for p in doc["problems"]:
                _check_problem(p, f"{stem}.yaml: problem '{p['id']}'", net, cms)


MISSION_KINDS = ["main", "side"]
MISSION_GOALS = {"walk": {"stream"}, "investigate": {"problem", "clues"}, "solve": {"problem"}}
COACH_STAGES = ["go_see", "understand", "experiment", "reflect"]  # Missions.STAGES
BELT_XP = [0, 1200, 3500, 7000, 12000]  # Progression.BELTS
MISSION_KEYS = {"id", "name", "kind", "tier", "requires", "briefing", "debrief", "fail", "goal", "deadline_days",
                "rewards", "insights"}


def validate_missions(doc: Any, source: str) -> None:
    """The campaign: the coach's questions per stage and the missions (CLAUDE.md §2)."""
    _require_strings(doc, [], source)
    coach = doc.get("coach")
    if not isinstance(coach, dict):
        raise ContentError(f"{source}: 'coach' must be a mapping")
    _known_keys(coach, {"name", "role", "stages"}, f"{source} coach")
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
        requires = m.get("requires", {})
        if not isinstance(requires, dict):
            raise ContentError(f"{where}: 'requires' must be a mapping")
        _known_keys(requires, {"missions", "belt"}, f"{where} requires")
        _string_list(requires, "missions", f"{where} requires")
        _number(requires, "belt", f"{where} requires", 0, len(BELT_XP) - 1, integer=True, default=0)
        goal = m.get("goal")
        if not isinstance(goal, dict) or goal.get("type") not in MISSION_GOALS:
            raise ContentError(f"{where}: 'goal' needs a type: {', '.join(MISSION_GOALS)}")
        _known_keys(goal, {"type"} | MISSION_GOALS[goal["type"]], f"{where} goal")
        _require_strings(goal, sorted(MISSION_GOALS[goal["type"]] - {"clues"}), f"{where} goal")
        if goal["type"] == "investigate":
            _number(goal, "clues", f"{where} goal", 1, integer=True)
        if "deadline_days" in m:
            _number(m, "deadline_days", where, 1, integer=True)
            _require_strings(m, ["fail"], where)
        rewards = m.get("rewards", {})
        if not isinstance(rewards, dict):
            raise ContentError(f"{where}: 'rewards' must be a mapping")
        _known_keys(rewards, {"xp", "budget"}, f"{where} rewards")
        for key in ("xp", "budget"):
            _number(rewards, key, f"{where} rewards", 0, integer=True, default=0)
        insights = m.get("insights", {})
        if insights and m["kind"] != "main":
            raise ContentError(f"{where}: only main missions get the coach's insights")
        if not isinstance(insights, dict) or any(s not in COACH_STAGES or not isinstance(t, str) for s, t in insights.items()):
            raise ContentError(f"{where}: 'insights' maps a coach stage to a text")


def check_missions(docs: dict[str, Any]) -> None:
    """Missions against problems and value streams, and the campaign as a
    whole: no cycles, a way in, and every mission reachable."""
    missions = {m["id"]: m for m in docs["missions"]["missions"]}
    streams = {s["id"] for s in docs["value_streams"]["streams"]}
    problems = {p["id"]: p for stem, doc in docs.items() if stem.startswith(PROBLEM_FILES) for p in doc["problems"]}
    solved: dict[str, str] = {}
    for m in missions.values():
        where = f"missions.yaml: mission '{m['id']}'"
        for req in m.get("requires", {}).get("missions", []):
            if req not in missions:
                raise ContentError(f"{where}: requires unknown mission {req!r}")
        goal = m["goal"]
        if goal["type"] == "walk" and goal["stream"] not in streams:
            raise ContentError(f"{where}: unknown stream {goal['stream']!r}")
        if "problem" in goal:
            p = problems.get(goal["problem"])
            if p is None:
                raise ContentError(f"{where}: unknown problem {goal['problem']!r}")
            keys = sum(1 for c in p["clues"] if c["key"])
            if goal["type"] == "investigate" and goal["clues"] > keys:
                raise ContentError(f"{where}: asks for {goal['clues']} key clues, the problem has {keys}")
            if goal["type"] == "solve":
                if goal["problem"] in solved:
                    raise ContentError(f"{where}: problem {goal['problem']!r} is already solved in mission {solved[goal['problem']]!r}")
                solved[goal["problem"]] = m["id"]
    # Play the campaign forward: complete whatever is unlocked, earning only
    # the missions' own XP (problems give more, so this is the hard case).
    done: set[str] = set()
    xp = 0
    progressed = True
    while progressed:
        progressed = False
        for m in missions.values():
            req = m.get("requires", {})
            belt_xp = BELT_XP[req.get("belt", 0)]
            if m["id"] not in done and xp >= belt_xp and all(r in done for r in req.get("missions", [])):
                done.add(m["id"])
                xp += m.get("rewards", {}).get("xp", 0)
                progressed = True
    if not any(m["kind"] == "main" and not m.get("requires") for m in missions.values()):
        raise ContentError("missions.yaml: no main mission is open from the start")
    stuck = sorted(set(missions) - done)
    if stuck:
        raise ContentError(f"missions.yaml: missions that can never unlock (a cycle or too little XP): {', '.join(stuck)}")


def vocabulary() -> dict[str, Any]:
    """The words content may use, written to game/data so a Godot test can
    check the game knows exactly the same ones."""
    return {
        "tools": sorted(TOOLS), "wastes": WASTES, "kpis": KPIS, "severities": SEVERITIES,
        "visibilities": VISIBILITIES, "check_pass": CHECK_PASS,
        "mission_kinds": MISSION_KINDS, "mission_goals": sorted(MISSION_GOALS), "coach_stages": COACH_STAGES,
        "belt_xp": BELT_XP,
        "effect_properties": {p: {"kind": k, "step_kind": sk or ""} for p, (k, sk, _) in sorted(EFFECT_PROPERTIES.items())},
    }


# Required files and their validators; problems_tier<n>.yaml files (one per
# tier) all use validate_problems.
VALIDATORS: dict[str, Callable[[Any, str], None]] = {
    "game": validate_game,
    "value_streams": validate_value_streams,
    "countermeasures": validate_countermeasures,
    "missions": validate_missions,
}

# Checks that need several files at once. Each gets {stem: document}.
CROSS_CHECKS: list[Callable[[dict[str, Any]], None]] = [check_problems, check_missions]


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
    missing = sorted(set(VALIDATORS) - set(docs))
    if missing:
        raise ContentError(f"missing content files: {', '.join(m + '.yaml' for m in missing)}")
    for check in CROSS_CHECKS:
        check(docs)
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
