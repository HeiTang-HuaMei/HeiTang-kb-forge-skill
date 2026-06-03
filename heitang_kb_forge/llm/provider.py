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
