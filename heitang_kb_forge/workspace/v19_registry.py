from datetime import datetime, timezone
from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from heitang_kb_forge.workspace.relationships import rebuild_relationship_graph
from heitang_kb_forge.workspace.report import render_workspace_report


def register_workspace_asset(workspace: Path, path: Path, asset_type: str, tags: list[str] | None = None) -> dict:
    if not (workspace / "workspace_manifest.json").exists():
        init_portable_workspace(workspace)
    tags = tags or []
    if asset_type == "knowledge":
        record = _knowledge_record(path, tags)
        registry = "package_registry.jsonl"
    elif asset_type == "skill":
        record = _skill_record(path, tags)
        registry = "skill_registry.jsonl"
    elif asset_type == "agent":
        record = _agent_record(path, tags)
        registry = "agent_registry.jsonl"
    else:
        raise ValueError(f"Unsupported workspace asset type: {asset_type}")
    registry_path = workspace / "registries" / registry
    records = [item for item in _read_jsonl(registry_path) if _record_key(item, asset_type) != _record_key(record, asset_type)]
    records.append(record)
    write_jsonl(registry_path, records)
    rebuild_relationship_graph(workspace)
    _update_manifest(workspace)
    return record


def list_workspace_assets(workspace: Path) -> dict:
    registries = workspace / "registries"
    return {
        "packages": _read_jsonl(registries / "package_registry.jsonl"),
        "skills": _read_jsonl(registries / "skill_registry.jsonl"),
        "agents": _read_jsonl(registries / "agent_registry.jsonl"),
    }


def _knowledge_record(path: Path, tags: list[str]) -> dict:
    manifest = _read_json(path / "manifest.json")
    quality = _read_json(path / "quality_report.json")
    return {
        "package_id": manifest.get("package_id") or path.name,
        "package_name": path.name,
        "package_path": str(path).replace("\\", "/"),
        "contract_version": manifest.get("contract_version"),
        "created_at": manifest.get("created_at") or manifest.get("generated_at"),
        "registered_at": _now(),
        "source_count": manifest.get("source_count", 0),
        "chunk_count": manifest.get("chunk_count", 0),
        "quality_status": quality.get("quality_level", "unknown"),
        "review_status": "required" if (path / "review_queue.jsonl").exists() and (path / "review_queue.jsonl").read_text(encoding="utf-8").strip() else "none",
        "governance_status": _status(path / "governance_report.md"),
        "retrieval_status": "pass" if (path / "retrieval_index.jsonl").exists() else "not_enabled",
        "evidence_gate_status": _status_json(path / "evidence_gate_result.json"),
        "tags": tags,
    }


def _skill_record(path: Path, tags: list[str]) -> dict:
    manifest = _read_yaml_like(path / "skill_manifest.yaml")
    validation = _find_validation(path)
    return {
        "skill_id": manifest.get("skill_id", path.name),
        "skill_name": manifest.get("skill_name", path.name),
        "skill_path": str(path).replace("\\", "/"),
        "source_package_id": manifest.get("source_package_id"),
        "skill_version": manifest.get("skill_version"),
        "created_at": manifest.get("created_at"),
        "registered_at": _now(),
        "validation_status": validation.get("status", "not_validated"),
        "release_ready": bool(validation.get("release_ready", False)),
        "tags": tags,
    }


def _agent_record(path: Path, tags: list[str]) -> dict:
    profile = _read_yaml_like(path / "agent_profile.yaml")
    return {
        "agent_id": profile.get("agent_id", path.name),
        "agent_name": profile.get("agent_name", path.name),
        "agent_path": str(path).replace("\\", "/"),
        "source_package_id": profile.get("source_package_id"),
        "source_skill_id": profile.get("source_skill_id"),
        "agent_type": profile.get("agent_type", "generic"),
        "created_at": profile.get("created_at"),
        "registered_at": _now(),
        "launch_ready": (path / "launch_checklist.md").exists(),
        "tags": tags,
    }


def _update_manifest(workspace: Path) -> None:
    manifest_path = workspace / "workspace_manifest.json"
    manifest = _read_json(manifest_path)
    assets = list_workspace_assets(workspace)
    manifest.update(
        {
            "updated_at": _now(),
            "package_count": len(assets["packages"]),
            "skill_count": len(assets["skills"]),
            "agent_count": len(assets["agents"]),
            "provider_count": len(_read_json(workspace / "registries" / "provider_registry.json").get("providers", [])),
            "prompt_profile_count": len(_read_json(workspace / "registries" / "prompt_profile_registry.json").get("profiles", [])),
        }
    )
    write_json(manifest_path, manifest)
    (workspace / "reports" / "workspace_report.md").write_text(render_workspace_report(manifest), encoding="utf-8")


def _record_key(item: dict, asset_type: str) -> str:
    return str(item.get({"knowledge": "package_id", "skill": "skill_id", "agent": "agent_id"}[asset_type]))


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _read_yaml_like(path: Path) -> dict:
    data = {}
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8").splitlines():
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            data[key.strip()] = value.strip()
    return data


def _find_validation(path: Path) -> dict:
    candidates = [path / "skill_validation_result.json", path.parent / "skill_validation" / "skill_validation_result.json"]
    for candidate in candidates:
        if candidate.exists():
            return _read_json(candidate)
    return {}


def _status(path: Path) -> str:
    return "pass" if path.exists() else "not_enabled"


def _status_json(path: Path) -> str:
    if not path.exists():
        return "not_enabled"
    payload = _read_json(path)
    return "pass" if payload.get("decision") == "allow" else payload.get("decision", "warning")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
