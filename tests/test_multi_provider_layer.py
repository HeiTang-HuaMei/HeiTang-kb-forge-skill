from heitang_kb_forge.llm.provider_fallback import fallback_provider
from heitang_kb_forge.llm.provider_policy import default_provider_policy
from heitang_kb_forge.llm.provider_router import choose_provider


def test_multi_provider_layer_defaults_to_offline_mock():
    policy = default_provider_policy()
    registry = {"providers": [{"provider_id": "mock_default", "provider_type": "mock"}]}

    assert policy["allow_network"] is False
    assert choose_provider(registry, "mock_default")["provider_type"] == "mock"
    assert fallback_provider({"provider_type": "openai_compatible"})["provider_type"] == "mock"
