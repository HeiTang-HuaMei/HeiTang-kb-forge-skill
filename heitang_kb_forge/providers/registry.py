from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.providers.config import sanitize_provider_config
from heitang_kb_forge.providers.health import check_provider
from heitang_kb_forge.providers.report import render_provider_registry_report
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def add_provider(workspace: Path, provider_id: str, provider_type: str, model: str, api_key_env: str | None = None) -> dict:
    if not (workspace / "workspace_manifest.json").exists():
        init_portable_workspace(workspace)
    path = workspace / "registries" / "provider_registry.json"
    registry = _read(path)
    record = check_provider(sanitize_provider_config(provider_id, provider_type, model, api_key_env))
    providers = [item for item in registry.get("providers", []) if item.get("provider_id") != provider_id]
    providers.append(record)
    registry["providers"] = providers
    write_json(path, registry)
    (workspace / "reports" / "provider_registry_report.md").write_text(render_provider_registry_report(registry), encoding="utf-8")
    return record


def list_providers(workspace: Path) -> dict:
    return _read(workspace / "registries" / "provider_registry.json")


def _read(path: Path) -> dict:
    if not path.exists():
        return {"providers": []}
    return json.loads(path.read_text(encoding="utf-8"))
