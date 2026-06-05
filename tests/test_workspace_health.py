from heitang_kb_forge.workspace.health import check_workspace_health
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_workspace_health_passes_for_initialized_workspace(tmp_path):
    workspace = tmp_path / "workspace"
    init_portable_workspace(workspace)

    result, report = check_workspace_health(workspace)

    assert result["status"] == "pass"
    assert "Workspace Health Report" in report
