import pytest

from heitang_kb_forge.llm.provider import ProviderSettings, get_provider


def test_get_provider_returns_mock_provider():
    provider = get_provider(ProviderSettings(provider="mock", model="mock-model"))

    assert provider.provider_name == "mock"


def test_get_provider_rejects_unknown_provider():
    with pytest.raises(ValueError):
        get_provider(ProviderSettings(provider="unknown"))
