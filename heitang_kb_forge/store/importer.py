from __future__ import annotations

import json
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path

from heitang_kb_forge.store.db import connect_store, init_store


def import_package(db_path: Path, package: Path) -> dict:
    init_store(db_path)
    manifest = _read_json(package / "manifest.json")
    if not manifest:
        raise ValueError(f"Package manifest not found: {package}")
    quality = _read_json(package / "quality_report.json")
    registry = _read_json(package / "source_registry.json")
    chunks = _read_jsonl(package / "chunks.jsonl")
    risks = _read_jsonl(package / "risk_labels.jsonl")
    run_manifest = _read_json(package / "run_manifest.json")
    publish_manifest = _read_json(package / "publish_manifest.json")
    package_id = _package_id(package)

    with connect_store(db_path) as connection:
        connection.execute(
            """
            INSERT OR REPLACE INTO packages (
              package_id, package_path, package_name, domain, mode, source_count, chunk_count,
              quality_score, quality_level, agent_type, imported_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                package_id,
                str(package).replace("\\", "/"),
                package.name,
                manifest.get("domain"),
                manifest.get("mode"),
                int(manifest.get("source_count", 0)),
                int(manifest.get("chunk_count", len(chunks))),
                quality.get("quality_score"),
                quality.get("quality_level"),
                manifest.get("agent_type"),
                datetime.now(timezone.utc).isoformat(),
            ),
        )
        connection.execute("DELETE FROM sources WHERE package_id = ?", (package_id,))
        for source in registry.get("sources", []):
            connection.execute(
                """
                INSERT OR REPLACE INTO sources (
                  package_id, source_id, source_path, relative_path, source_name, extension, content_hash
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    package_id,
                    source.get("source_id") or _source_id(source),
                    source.get("source_path"),
                    source.get("relative_path"),
                    source.get("source_name"),
                    source.get("extension"),
                    source.get("content_hash"),
                ),
            )
        connection.execute("DELETE FROM chunks_index WHERE package_id = ?", (package_id,))
        for chunk in chunks:
            connection.execute(
                """
                INSERT OR REPLACE INTO chunks_index (
                  package_id, chunk_id, text, source_path, domain, mode
                ) VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    package_id,
                    chunk.get("chunk_id"),
                    chunk.get("text"),
                    chunk.get("source_path"),
                    chunk.get("domain"),
                    chunk.get("mode"),
                ),
            )
        connection.execute(
            "INSERT OR REPLACE INTO quality_records (package_id, quality_score, quality_level, warning_count) VALUES (?, ?, ?, ?)",
            (package_id, quality.get("quality_score"), quality.get("quality_level"), len(quality.get("warnings", []))),
        )
        connection.execute("DELETE FROM risk_records WHERE package_id = ?", (package_id,))
        for index, risk in enumerate(risks, start=1):
            connection.execute(
                "INSERT OR REPLACE INTO risk_records (package_id, risk_id, label, severity, source_path) VALUES (?, ?, ?, ?, ?)",
                (package_id, risk.get("risk_id") or str(index), risk.get("label"), risk.get("severity"), risk.get("source_path")),
            )
        if run_manifest:
            connection.execute(
                "INSERT OR REPLACE INTO runs (package_id, run_id, status, started_at) VALUES (?, ?, ?, ?)",
                (package_id, run_manifest.get("run_id", "unknown"), run_manifest.get("status"), run_manifest.get("started_at")),
            )
        if publish_manifest:
            connection.execute(
                "INSERT OR REPLACE INTO publish_records (package_id, profile, publish_manifest) VALUES (?, ?, ?)",
                (package_id, publish_manifest.get("profile"), json.dumps(publish_manifest, ensure_ascii=False)),
            )
        if (package / "agent_profile.yaml").exists():
            connection.execute(
                "INSERT OR REPLACE INTO agent_targets (package_id, agent_type, agent_name, agent_profile_path) VALUES (?, ?, ?, ?)",
                (
                    package_id,
                    manifest.get("agent_type"),
                    manifest.get("agent_name"),
                    str(package / "agent_profile.yaml").replace("\\", "/"),
                ),
            )

    return {"package_id": package_id, "package_path": str(package).replace("\\", "/"), "chunk_count": len(chunks)}


def sync_workspace(db_path: Path, workspace: Path) -> list[dict]:
    imported: list[dict] = []
    for manifest_path in sorted(workspace.rglob("manifest.json")):
        imported.append(import_package(db_path, manifest_path.parent))
    return imported


def _package_id(package: Path) -> str:
    return sha256(str(package.resolve()).encode("utf-8")).hexdigest()[:16]


def _source_id(source: dict) -> str:
    value = str(source.get("relative_path") or source.get("source_path") or source)
    return sha256(value.encode("utf-8")).hexdigest()[:16]


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
