from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class ProviderResponse:
    payload: dict
    provider_name: str
    model_name: str
    token_usage: dict[str, int]
    latency_ms: int
    error: str | None = None


class LLMProvider(Protocol):
    provider_name: str
    model_name: str

    def generate_json(self, prompt: str, schema_name: str) -> ProviderResponse:
        ...


@dataclass(frozen=True)
class ProviderSettings:
    provider: str = "mock"
    model: str = "mock-model"
    base_url: str | None = None
    api_key: str | None = None


def get_provider(settings: ProviderSettings):
    if settings.provider in {"mock", "fake"}:
        from heitang_kb_forge.llm.mock_provider import MockProvider

        return MockProvider(settings.model)
    if settings.provider in {"openai_compatible", "openai-compatible"}:
        from heitang_kb_forge.llm.openai_compatible import OpenAICompatibleAdapter

        return OpenAICompatibleAdapter(settings.model, settings.base_url, settings.api_key)
    raise ValueError(f"Unsupported LLM provider: {settings.provider}")
