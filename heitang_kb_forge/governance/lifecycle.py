from pathlib import Path
import json

from heitang_kb_forge.schemas.governance_schema import LifecycleManifest


def make_lifecycle_manifest(package: Path, stale_chunk_ids: set[str] | None = None) -> LifecycleManifest:
    stale_chunk_ids = stale_chunk_ids or set()
    chunks = _load_jsonl(package / "chunks.jsonl")
    review_required = [
        chunk for chunk in chunks
        if chunk.get("metadata", {}).get("review_required") or chunk.get("chunk_id") in stale_chunk_ids
    ]
    return LifecycleManifest(
        package=str(package).replace("\\", "/"),
        active_count=max(0, len(chunks) - len(stale_chunk_ids)),
        review_required_count=len(review_required),
        stale_count=len(stale_chunk_ids),
    )


def _load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
