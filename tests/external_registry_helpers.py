import json
from pathlib import Path

from heitang_kb_forge.workbench.external_capabilities import make_external_capability_bundle


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
    if ui_registry.exists():
        return json.loads(ui_registry.read_text(encoding="utf-8-sig"))
    return make_external_capability_bundle(repo_root)["external_capability_registry.json"]
