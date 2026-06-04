from __future__ import annotations

import sqlite3
from pathlib import Path

from heitang_kb_forge.store.schema import SCHEMA_SQL


def connect_store(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    return connection


def init_store(db_path: Path) -> dict:
    with connect_store(db_path) as connection:
        connection.executescript(SCHEMA_SQL)
    return {"store_version": "1.4.0", "db_path": str(db_path).replace("\\", "/"), "status": "initialized"}
