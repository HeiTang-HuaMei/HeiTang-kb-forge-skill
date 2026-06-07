from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path


REGISTRY_TYPES = ["package", "skill", "agent", "memory", "document", "index"]


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def content_hash(path: Path) -> str | None:
    if not path.exists() or not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative_path(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def asset_type_for(path: Path) -> str:
    name = path.name.lower()
    parent = path.parent.name.lower()
    if name in {"manifest.json", "chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"}:
        return "package"
    if parent == "skill_package" or name in {"skill_manifest.yaml", "skill_manifest.json", "skill.md"}:
        return "skill"
    if parent == "agent_package" or name in {"agent_manifest.json", "agent_profile.yaml", "soul.md", "system_prompt.md"}:
        return "agent"
    if "memory" in name or parent.startswith("memory"):
        return "memory"
    if "index" in name or name.endswith(".index"):
        return "index"
    if name.startswith("generated") or name.endswith((".docx", ".pptx", ".pdf")):
        return "document"
    return "document" if path.suffix.lower() in {".md", ".json", ".jsonl", ".yaml", ".yml"} else "package"


def registry_entry(path: Path, root: Path, *, track_hash: bool = True, source: str = "scan") -> dict:
    stat = path.stat()
    asset_type = asset_type_for(path)
    return {
        "asset_id": stable_asset_id(path, root),
        "asset_type": asset_type,
        "path": relative_path(path, root),
        "created_at": datetime.fromtimestamp(stat.st_ctime, timezone.utc).isoformat(),
        "updated_at": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        "size_bytes": stat.st_size,
        "content_hash": content_hash(path) if track_hash else None,
        "status": "active",
        "source_refs": [source],
    }


def stable_asset_id(path: Path, root: Path) -> str:
    rel = relative_path(path, root).replace("/", "_").replace("\\", "_")
    return rel.replace(".", "_").replace(" ", "_")


def scan_workspace(root: Path, *, track_hash: bool = True) -> dict[str, list[dict]]:
    root.mkdir(parents=True, exist_ok=True)
    registries = {name: [] for name in REGISTRY_TYPES}
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if path.name.startswith("workbench_"):
            continue
        entry = registry_entry(path, root, track_hash=track_hash)
        registries.setdefault(entry["asset_type"], []).append(entry)
    return registries


def workspace_registry(root: Path, registries: dict[str, list[dict]]) -> dict:
    return {
        "workspace_registry_version": "3.9.0-alpha.1",
        "generated_at": now_iso(),
        "storage_backend": "local_workspace",
        "workspace_root": root.as_posix(),
        "registry_format": "json",
        "asset_types": REGISTRY_TYPES,
        "asset_counts": {name: len(registries.get(name, [])) for name in REGISTRY_TYPES},
        "no_cloud_upload_required": True,
        "tests_require_real_llm_api_network": False,
    }
