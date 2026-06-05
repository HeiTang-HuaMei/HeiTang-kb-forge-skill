from heitang_kb_forge.providers.registry import add_provider, list_providers


def test_provider_registry_does_not_store_api_key(tmp_path):
    workspace = tmp_path / "workspace"

    add_provider(workspace, "mock_default", "mock", "mock-model", "OPENAI_API_KEY")
    registry = list_providers(workspace)
    text = (workspace / "registries" / "provider_registry.json").read_text(encoding="utf-8")

    assert registry["providers"][0]["provider_id"] == "mock_default"
    assert "OPENAI_API_KEY" in text
    assert "sk-" not in text
