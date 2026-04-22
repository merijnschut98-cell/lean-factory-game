"""
User-configurable settings. Persisted to settings.json alongside the save DB.
"""
import json
import os
from pathlib import Path

_SETTINGS_FILE = Path(__file__).parent.parent / "settings.json"

_DEFAULTS = {
    "speed_index":        1,      # index into SPEED_MULTIPLIERS (1 = 1×)
    "volume_sfx":         0.7,
    "volume_music":       0.4,
    "anthropic_api_key":  "",     # set by player in options menu
    "show_flow_lines":    True,
    "show_oee_overlay":   False,
    "fullscreen":         False,
}

_current: dict = {}


def load() -> None:
    global _current
    _current = dict(_DEFAULTS)
    if _SETTINGS_FILE.exists():
        try:
            saved = json.loads(_SETTINGS_FILE.read_text())
            _current.update({k: v for k, v in saved.items() if k in _DEFAULTS})
        except Exception:
            pass


def save() -> None:
    _SETTINGS_FILE.write_text(json.dumps(_current, indent=2))


def get(key: str):
    if not _current:
        load()
    return _current.get(key, _DEFAULTS.get(key))


def set(key: str, value) -> None:
    if not _current:
        load()
    if key in _DEFAULTS:
        _current[key] = value
        save()
