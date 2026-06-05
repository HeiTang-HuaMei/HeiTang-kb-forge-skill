from heitang_kb_forge.web.app import load_workspace_summary
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from heitang_kb_forge.providers.registry import add_provider


def test_workspace_ui_summary_loads_registries(tmp_path):
    workspace = tmp_path / "workspace"
    init_portable_workspace(workspace)
    add_provider(workspace, "mock_default", "mock", "mock-model")

    summary = load_workspace_summary(workspace)

    assert summary["workspace_manifest.json"]["workspace_version"] == "1.9"
    assert summary["registries/provider_registry.json"]["providers"][0]["provider_id"] == "mock_default"
