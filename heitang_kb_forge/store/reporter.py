from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.schemas.store_schema import StoreManifest
from heitang_kb_forge.store.db import connect_store


def store_counts(db_path: Path) -> StoreManifest:
    with connect_store(db_path) as connection:
        package_count = connection.execute("SELECT COUNT(*) FROM packages").fetchone()[0]
        source_count = connection.execute("SELECT COUNT(*) FROM sources").fetchone()[0]
        chunk_count = connection.execute("SELECT COUNT(*) FROM chunks_index").fetchone()[0]
    return StoreManifest(
        db_path=str(db_path).replace("\\", "/"),
        package_count=package_count,
        source_count=source_count,
        chunk_count=chunk_count,
    )


def render_store_status_report(manifest: StoreManifest) -> str:
    return f"""# Local Knowledge Store Status

## Summary

- DB path: {manifest.db_path}
- Packages: {manifest.package_count}
- Sources: {manifest.source_count}
- Chunks: {manifest.chunk_count}
"""
