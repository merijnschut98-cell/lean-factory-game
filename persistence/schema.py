"""SQLite schema — schema-versioned, migration-safe."""
import sqlite3
from pathlib import Path

SCHEMA_VERSION = 1

DDL = """
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS factory_state (
    id          INTEGER PRIMARY KEY CHECK (id = 1),
    data_json   TEXT NOT NULL,
    saved_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS problems (
    problem_id      TEXT PRIMARY KEY,
    tier            INTEGER NOT NULL,
    state           TEXT NOT NULL DEFAULT 'dormant',
    investigation_json TEXT,
    countermeasure_applied TEXT,
    score_json      TEXT,
    first_seen_day  INTEGER,
    solved_day      INTEGER
);

CREATE TABLE IF NOT EXISTS day_history (
    day         INTEGER PRIMARY KEY,
    output      INTEGER NOT NULL DEFAULT 0,
    plant_oee   REAL NOT NULL DEFAULT 0,
    total_wip   INTEGER NOT NULL DEFAULT 0,
    ftr         REAL NOT NULL DEFAULT 0,
    recorded_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS session_costs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    session_date TEXT NOT NULL DEFAULT (date('now')),
    cost_eur    REAL NOT NULL DEFAULT 0,
    tokens_in   INTEGER NOT NULL DEFAULT 0,
    tokens_out  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS improvements (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    problem_id      TEXT NOT NULL,
    countermeasure  TEXT NOT NULL,
    applied_day     INTEGER NOT NULL,
    score_total     INTEGER,
    credits_earned  INTEGER
);
"""


def connect(db_path: str | Path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init(conn)
    return conn


def _init(conn: sqlite3.Connection) -> None:
    conn.executescript(DDL)
    row = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()
    if row is None:
        conn.execute("INSERT INTO meta VALUES ('schema_version', ?)", (str(SCHEMA_VERSION),))
        conn.commit()
    else:
        _migrate(conn, int(row["value"]))


def _migrate(conn: sqlite3.Connection, current_version: int) -> None:
    """Run any pending migrations in order."""
    # future: if current_version < 2: run migration_002.py, etc.
    pass
