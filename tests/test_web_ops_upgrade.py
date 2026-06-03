import json

from heitang_kb_forge.web.app import load_workspace_packages


def test_web_loads_workspace_registry(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "package_registry.json").write_text(
        json.dumps({"packages": [{"package_path": "package", "quality_score": 100}]}),
        encoding="utf-8",
    )

    packages = load_workspace_packages(workspace)

    assert packages[0]["package_path"] == "package"
