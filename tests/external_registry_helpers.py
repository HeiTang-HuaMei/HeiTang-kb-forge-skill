import json
from pathlib import Path


def load_external_capability_registry(repo_root: Path) -> dict:
    ui_registry = (
        repo_root.parent
        / "kb-forge-skill-ui"
        / "web"
        / "workbench"
        / "flutter_app"
        / "assets"
        / "external"
        / "external_capability_registry.json"
    )
    core_registry = repo_root / "docs" / "audits" / "s_a_contract_inclusion" / "external_capability_registry.json"
    path = ui_registry if ui_registry.exists() else core_registry
    return json.loads(path.read_text(encoding="utf-8-sig"))
