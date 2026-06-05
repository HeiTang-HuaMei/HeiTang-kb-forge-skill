from heitang_kb_forge.llm.provider_health import check_provider_health
from heitang_kb_forge.providers import add_provider
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_provider_health_checks_mock_provider_without_network(tmp_path):
    workspace = tmp_path / "workspace"
    init_portable_workspace(workspace)
    add_provider(workspace, "mock_default", "mock", "mock-model")

    result, report = check_provider_health(workspace, allow_network=False)

    assert result["status"] == "pass"
    assert result["providers"][0]["provider_type"] == "mock"
    assert "Provider Health Report" in report
    assert (workspace / "provider_health_result.json").exists()
