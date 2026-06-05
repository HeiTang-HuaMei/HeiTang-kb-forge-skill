from pathlib import Path
import hashlib
import json

from heitang_kb_forge.schemas.governance_schema import PackageDiff


def make_package_diff(new_package: Path, old_package: Path | None = None) -> PackageDiff:
    new_chunks = _load_chunks(new_package)
    old_chunks = _load_chunks(old_package) if old_package else {}
    new_ids = set(new_chunks)
    old_ids = set(old_chunks)
    changed = sorted(
        chunk_id for chunk_id in new_ids & old_ids if _hash(new_chunks[chunk_id]) != _hash(old_chunks[chunk_id])
    )
    unchanged = sorted((new_ids & old_ids) - set(changed))
    return PackageDiff(
        old_package=str(old_package).replace("\\", "/") if old_package else None,
        new_package=str(new_package).replace("\\", "/"),
        added=sorted(new_ids - old_ids),
        removed=sorted(old_ids - new_ids),
        changed=changed,
        unchanged=unchanged,
    )


def _load_chunks(package: Path | None) -> dict[str, dict]:
    if package is None:
        return {}
    path = package / "chunks.jsonl"
    if not path.exists():
        return {}
    chunks: dict[str, dict] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            item = json.loads(line)
            chunks[str(item.get("chunk_id", ""))] = item
    return chunks


def _hash(item: dict) -> str:
    value = f"{item.get('source_path', '')}\n{item.get('text', '')}"
    return hashlib.sha256(value.encode("utf-8")).hexdigest()
