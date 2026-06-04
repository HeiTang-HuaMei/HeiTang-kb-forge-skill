from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.schemas.store_schema import StorePackageRecord, StoreQueryResult
from heitang_kb_forge.store.db import connect_store


def list_packages(db_path: Path) -> list[StorePackageRecord]:
    with connect_store(db_path) as connection:
        rows = connection.execute("SELECT * FROM packages ORDER BY imported_at DESC").fetchall()
    return [StorePackageRecord(**dict(row)) for row in rows]


def query_packages(
    db_path: Path,
    *,
    domain: str | None = None,
    agent_type: str | None = None,
    min_quality_score: int | None = None,
) -> StoreQueryResult:
    clauses: list[str] = []
    params: list[object] = []
    if domain:
        clauses.append("domain = ?")
        params.append(domain)
    if agent_type:
        clauses.append("agent_type = ?")
        params.append(agent_type)
    if min_quality_score is not None:
        clauses.append("quality_score >= ?")
        params.append(min_quality_score)
    where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    with connect_store(db_path) as connection:
        rows = connection.execute(f"SELECT * FROM packages {where} ORDER BY imported_at DESC", params).fetchall()
    packages = [StorePackageRecord(**dict(row)) for row in rows]
    return StoreQueryResult(
        filters={"domain": domain, "agent_type": agent_type, "min_quality_score": min_quality_score},
        total=len(packages),
        packages=packages,
    )


def package_status(db_path: Path, package_id: str) -> dict:
    with connect_store(db_path) as connection:
        package = connection.execute("SELECT * FROM packages WHERE package_id = ?", (package_id,)).fetchone()
        source_count = connection.execute("SELECT COUNT(*) FROM sources WHERE package_id = ?", (package_id,)).fetchone()[0]
        chunk_count = connection.execute("SELECT COUNT(*) FROM chunks_index WHERE package_id = ?", (package_id,)).fetchone()[0]
    if not package:
        raise ValueError(f"Package not found: {package_id}")
    payload = dict(package)
    payload.update({"indexed_source_count": source_count, "indexed_chunk_count": chunk_count})
    return payload
