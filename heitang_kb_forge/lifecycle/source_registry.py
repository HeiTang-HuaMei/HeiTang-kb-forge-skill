from __future__ import annotations

from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path

from heitang_kb_forge.schemas.lifecycle_schema import SourceRecord, SourceRegistry


def make_source_registry(input_path: Path, source_files: list[Path]) -> SourceRegistry:
    root = input_path if input_path.is_dir() else input_path.parent
    records = [_make_record(path, root) for path in sorted(source_files, key=lambda item: item.name.lower())]
    return SourceRegistry(
        input_path=str(input_path).replace("\\", "/"),
        source_count=len(records),
        sources=records,
    )


def registry_by_relative_path(registry: SourceRegistry | dict | None) -> dict[str, SourceRecord]:
    if not registry:
        return {}
    if isinstance(registry, dict):
        registry = SourceRegistry.model_validate(registry)
    return {record.relative_path: record for record in registry.sources}


def _make_record(path: Path, root: Path) -> SourceRecord:
    stat = path.stat()
    relative_path = _relative_path(path, root)
    digest = sha256(path.read_bytes()).hexdigest()
    source_id = sha256(relative_path.encode("utf-8")).hexdigest()[:16]
    return SourceRecord(
        source_id=source_id,
        source_path=str(path).replace("\\", "/"),
        relative_path=relative_path,
        source_name=path.name,
        extension=path.suffix.lower(),
        size_bytes=stat.st_size,
        modified_at=datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        content_hash=digest,
    )


def _relative_path(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.name
