import pytest

from heitang_kb_forge.llm.extractor import create_provider
from heitang_kb_forge.llm.fake_provider import FakeProvider
from heitang_kb_forge.llm.openai_compatible_provider import OpenAICompatibleProvider


def test_fake_provider_old_behavior_unchanged():
    provider = FakeProvider()
    response = provider.generate_json("Chunk text:\nProvider readiness fixture", "cards")

    assert response.provider_name == "fake"
    assert response.model_name == "fake-model"
    assert response.payload["items"][0]["title"] == "Provider readiness fixture"


def test_openai_compatible_llm_provider_is_recognized():
    provider = create_provider("openai-compatible", "gpt-compatible")

    assert provider.provider_name == "openai-compatible"
    assert provider.model_name == "gpt-compatible"


def test_openai_compatible_llm_provider_requires_config():
    provider = OpenAICompatibleProvider("gpt-compatible")

    with pytest.raises(RuntimeError, match="OpenAI-compatible LLM provider is not configured"):
        provider.generate_json("prompt", "cards")


def test_openai_compatible_llm_provider_does_not_leak_api_key():
    provider = OpenAICompatibleProvider("gpt-compatible", api_key="secret-key", endpoint="https://example.invalid")

    with pytest.raises(RuntimeError) as exc:
        provider.generate_json("prompt", "cards")
    assert "secret-key" not in str(exc.value)
    assert "network calls are not implemented" in str(exc.value)
