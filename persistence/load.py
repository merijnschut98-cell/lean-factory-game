"""Load factory state from SQLite."""
from __future__ import annotations

import json
from pathlib import Path

from config.constants import DB_FILENAME
from persistence.schema import connect


def _db_path() -> Path:
    return Path(DB_FILENAME)


def has_save() -> bool:
    path = _db_path()
    if not path.exists():
        return False
    conn = connect(path)
    row = conn.execute("SELECT id FROM factory_state WHERE id=1").fetchone()
    conn.close()
    return row is not None


def load(factory) -> bool:
    """
    Deserialise factory state from DB.
    Returns True if a save was found and loaded, False otherwise.
    """
    if not has_save():
        return False

    conn = connect(_db_path())
    row = conn.execute("SELECT data_json FROM factory_state WHERE id=1").fetchone()
    conn.close()

    if row is None:
        return False

    data = json.loads(row["data_json"])
    factory.from_dict(data)
    return True
