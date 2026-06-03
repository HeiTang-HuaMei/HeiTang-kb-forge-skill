from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class EmbeddingResponse:
    vector: list[float]
    dimensions: int
    provider: str
    model: str


class EmbeddingProvider(Protocol):
    provider_name: str
    model_name: str

    def embed(self, text: str) -> EmbeddingResponse:
        ...
