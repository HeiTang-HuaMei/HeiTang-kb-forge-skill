from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.store.db import init_store, connect_store
from heitang_kb_forge.store.reporter import render_store_status_report, store_counts


STORE_OUTPUT_FILES = [
    "store_manifest.json",
    "store_package_index.jsonl",
    "store_source_index.jsonl",
    "store_chunk_index.jsonl",
    "store_status_report.md",
]


def export_store_index(db_path: Path) -> tuple[dict, list[dict], list[dict], list[dict], str]:
    init_store(db_path)
    manifest = store_counts(db_path)
    with connect_store(db_path) as connection:
        packages = [dict(row) for row in connection.execute("SELECT * FROM packages ORDER BY imported_at DESC").fetchall()]
        sources = [dict(row) for row in connection.execute("SELECT * FROM sources ORDER BY package_id, relative_path").fetchall()]
        chunks = [dict(row) for row in connection.execute("SELECT * FROM chunks_index ORDER BY package_id, chunk_id").fetchall()]
    return manifest.model_dump(mode="json"), packages, sources, chunks, render_store_status_report(manifest)
