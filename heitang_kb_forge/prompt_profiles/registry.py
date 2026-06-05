from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.prompt_profiles.profile import make_prompt_profile_record
from heitang_kb_forge.prompt_profiles.report import render_prompt_profile_report
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def add_prompt_profile(workspace: Path, profile_id: str, profile_type: str, rules: Path) -> dict:
    if not (workspace / "workspace_manifest.json").exists():
        init_portable_workspace(workspace)
    path = workspace / "registries" / "prompt_profile_registry.json"
    registry = _read(path)
    record = make_prompt_profile_record(profile_id, profile_type, rules)
    profiles = [item for item in registry.get("profiles", []) if item.get("profile_id") != profile_id]
    profiles.append(record)
    registry["profiles"] = profiles
    write_json(path, registry)
    (workspace / "reports" / "prompt_profile_registry_report.md").write_text(render_prompt_profile_report(registry), encoding="utf-8")
    return record


def list_prompt_profiles(workspace: Path) -> dict:
    return _read(workspace / "registries" / "prompt_profile_registry.json")


def _read(path: Path) -> dict:
    if not path.exists():
        return {"profiles": []}
    return json.loads(path.read_text(encoding="utf-8"))
