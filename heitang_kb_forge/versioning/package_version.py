from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

from heitang_kb_forge.schemas.versioning_schema import PackageVersion


def make_package_version(package_path: Path) -> PackageVersion:
    chunks = _read_jsonl(package_path / "chunks.jsonl")
    source_hashes: dict[str, str] = {}
    chunk_hashes: dict[str, str] = {}
    for chunk in chunks:
        source_path = str(chunk.get("source_path", ""))
        text = str(chunk.get("text", ""))
        source_hashes[source_path] = _hash_text(source_hashes.get(source_path, "") + text)
        chunk_hashes[str(chunk.get("chunk_id", ""))] = _hash_text(text)
    asset_hashes = {
        name: _hash_file(package_path / name)
        for name in ["cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "quality_report.json"]
        if (package_path / name).exists()
    }
    payload = json.dumps({"source_hashes": source_hashes, "chunk_hashes": chunk_hashes, "asset_hashes": asset_hashes}, sort_keys=True)
    return PackageVersion(
        generated_at=datetime.now(timezone.utc).isoformat(),
        package_path=str(package_path).replace("\\", "/"),
        source_count=len(source_hashes),
        chunk_count=len(chunk_hashes),
        source_hashes=source_hashes,
        chunk_hashes=chunk_hashes,
        asset_hashes=asset_hashes,
        package_hash=_hash_text(payload),
    )


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _hash_file(path: Path) -> str:
    return _hash_text(path.read_text(encoding="utf-8")) if path.exists() else ""


def _hash_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()
