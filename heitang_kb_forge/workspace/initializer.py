from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.workspace_schema import WorkspaceManifest


V19_DIRS = [
    "knowledge_packages",
    "skill_packages",
    "agent_packages",
    "registries",
    "reports",
    "exports",
    "logs",
    "templates",
]


def init_portable_workspace(workspace: Path) -> WorkspaceManifest:
    workspace.mkdir(parents=True, exist_ok=True)
    for name in V19_DIRS:
        (workspace / name).mkdir(parents=True, exist_ok=True)
    manifest = WorkspaceManifest(workspace_id=workspace.name or "workspace", root_path=str(workspace).replace("\\", "/"))
    write_json(workspace / "workspace_manifest.json", manifest.model_dump(mode="json"))
    _ensure_files(workspace)
    return manifest


def _ensure_files(workspace: Path) -> None:
    registries = workspace / "registries"
    for name in ["package_registry.jsonl", "skill_registry.jsonl", "agent_registry.jsonl", "llm_call_audit.jsonl"]:
        (registries / name).touch(exist_ok=True)
    for name, payload in [
        ("relationship_graph.json", {"nodes": [], "edges": []}),
        ("provider_registry.json", {"providers": []}),
        ("prompt_profile_registry.json", {"profiles": []}),
    ]:
        path = registries / name
        if not path.exists():
            write_json(path, payload)
