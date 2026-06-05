import json

from heitang_kb_forge.workspace_refresh import make_workspace_refresh


def test_workspace_refresh_dependency_impact_json(tmp_path):
    workspace = tmp_path / "workspace"
    package = workspace / "package"
    package.mkdir(parents=True)
    (package / "manifest.json").write_text("{}", encoding="utf-8")

    make_workspace_refresh(workspace, tmp_path / "out")

    impact = json.loads((tmp_path / "out" / "dependency_impact_report.json").read_text(encoding="utf-8"))
    assert impact["package_count"] == 1

