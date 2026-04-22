"""
Save factory state to SQLite with rolling backups.
"""
from __future__ import annotations

import json
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path

from config.constants import SAVE_ROLLING_BACKUPS, DB_FILENAME
from persistence.schema import connect


def _db_path() -> Path:
    return Path(DB_FILENAME)


def save(factory) -> Path:
    """
    Serialise factory to JSON and upsert into the DB.
    Rotate rolling backups before writing.
    Returns the path to the DB file.
    """
    path = _db_path()
    _rotate_backups(path)

    data_json = json.dumps(factory.to_dict(), ensure_ascii=False)
    conn = connect(path)

    conn.execute(
        "INSERT INTO factory_state (id, data_json) VALUES (1, ?) "
        "ON CONFLICT(id) DO UPDATE SET data_json=excluded.data_json, saved_at=datetime('now')",
        (data_json,)
    )
    _write_day_history(conn, factory)
    conn.commit()
    conn.close()
    return path


def _write_day_history(conn: sqlite3.Connection, factory) -> None:
    for snap in factory.day_history:
        conn.execute(
            "INSERT INTO day_history (day, output, plant_oee, total_wip, ftr) "
            "VALUES (?,?,?,?,?) ON CONFLICT(day) DO UPDATE SET "
            "output=excluded.output, plant_oee=excluded.plant_oee, "
            "total_wip=excluded.total_wip, ftr=excluded.ftr",
            (snap.day, snap.output, snap.plant_oee, snap.total_wip, snap.ftr),
        )


def _rotate_backups(path: Path) -> None:
    if not path.exists():
        return
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(f".{ts}.bak")
    shutil.copy2(path, backup)

    # Keep only the most recent N backups
    backups = sorted(path.parent.glob(f"{path.stem}.*.bak"))
    for old in backups[:-SAVE_ROLLING_BACKUPS]:
        old.unlink(missing_ok=True)
