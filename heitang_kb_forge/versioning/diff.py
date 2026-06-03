import json
from pathlib import Path

from heitang_kb_forge.versioning.package_version import make_package_version

DIFF_OUTPUT_FILES = [
    "package_version.json",
    "package_diff_report.md",
    "changed_chunks.jsonl",
    "removed_chunks.jsonl",
    "new_chunks.jsonl",
]


def diff_packages(old_package: Path, new_package: Path) -> tuple[dict, str, list[dict], list[dict], list[dict]]:
    old_chunks = _chunks_by_id(old_package / "chunks.jsonl")
    new_chunks = _chunks_by_id(new_package / "chunks.jsonl")
    old_ids = set(old_chunks)
    new_ids = set(new_chunks)
    new_records = [new_chunks[chunk_id] for chunk_id in sorted(new_ids - old_ids)]
    removed_records = [old_chunks[chunk_id] for chunk_id in sorted(old_ids - new_ids)]
    changed_records = [
        new_chunks[chunk_id]
        for chunk_id in sorted(old_ids & new_ids)
        if str(old_chunks[chunk_id].get("text", "")) != str(new_chunks[chunk_id].get("text", ""))
    ]
    version = make_package_version(new_package).model_dump(mode="json")
    report = _report(old_package, new_package, changed_records, removed_records, new_records)
    return version, report, changed_records, removed_records, new_records


def _chunks_by_id(path: Path) -> dict[str, dict]:
    if not path.exists():
        return {}
    return {
        str(item.get("chunk_id", "")): item
        for item in (json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip())
        if item.get("chunk_id")
    }


def _report(old_package: Path, new_package: Path, changed: list[dict], removed: list[dict], new: list[dict]) -> str:
    old_path = str(old_package).replace("\\", "/")
    new_path = str(new_package).replace("\\", "/")
    return f"""# Package Diff Report

## Summary

- Old package: {old_path}
- New package: {new_path}
- Changed chunks: {len(changed)}
- Removed chunks: {len(removed)}
- New chunks: {len(new)}
"""
