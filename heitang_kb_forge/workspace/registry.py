import json
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.versioning.package_version import make_package_version

WORKSPACE_FILES = ["workspace_index.json", "package_registry.json", "package_status_report.md"]


def init_workspace(workspace: Path) -> tuple[dict, dict, str]:
    workspace.mkdir(parents=True, exist_ok=True)
    index = {"workspace_version": "1.2.0", "created_at": _now(), "package_count": 0}
    registry = {"packages": []}
    report = _status_report(registry)
    return index, registry, report


def register_package(workspace: Path, package: Path) -> tuple[dict, str]:
    workspace.mkdir(parents=True, exist_ok=True)
    registry = _read_registry(workspace)
    package_path = str(package).replace("\\", "/")
    existing = [item for item in registry["packages"] if item["package_path"] != package_path]
    existing.append(_package_record(package))
    registry["packages"] = sorted(existing, key=lambda item: item["package_path"])
    return registry, _status_report(registry)


def workspace_status(workspace: Path) -> tuple[dict, str]:
    registry = _read_registry(workspace)
    return registry, _status_report(registry)


def _package_record(package: Path) -> dict:
    version = make_package_version(package)
    manifest = _read_json(package / "manifest.json")
    quality = _read_json(package / "quality_report.json")
    validation = _read_json(package / "package_validation_report.json")
    return {
        "package_path": str(package).replace("\\", "/"),
        "package_hash": version.package_hash,
        "registered_at": _now(),
        "source_count": version.source_count,
        "chunk_count": version.chunk_count,
        "domain": manifest.get("domain"),
        "mode": manifest.get("mode"),
        "agent_type": manifest.get("agent_type"),
        "quality_score": quality.get("quality_score"),
        "quality_level": quality.get("quality_level"),
        "readiness_level": validation.get("readiness_level"),
        "risk_level": validation.get("hallucination_risk_level"),
    }


def _read_registry(workspace: Path) -> dict:
    path = workspace / "package_registry.json"
    if not path.exists():
        return {"packages": []}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _status_report(registry: dict) -> str:
    rows = "\n".join(
        f"| {item['package_path']} | {item.get('quality_score')} | {item.get('readiness_level')} | {item.get('risk_level')} |"
        for item in registry["packages"]
    ) or "| - | - | - | - |"
    return f"""# Workspace Package Status

## Summary

- Package count: {len(registry['packages'])}

## Packages

| Package | Quality Score | Readiness | Risk |
| --- | --- | --- | --- |
{rows}
"""


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
