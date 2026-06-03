import hashlib

from heitang_kb_forge.embedding.provider import EmbeddingResponse


class FakeEmbeddingProvider:
    provider_name = "fake"
    dimensions = 8

    def __init__(self, model_name: str = "fake-embedding-model") -> None:
        self.model_name = model_name

    def embed(self, text: str) -> EmbeddingResponse:
        digest = hashlib.sha256(text.encode("utf-8")).digest()
        vector = [round((digest[index] / 255.0) * 2 - 1, 6) for index in range(self.dimensions)]
        return EmbeddingResponse(
            vector=vector,
            dimensions=self.dimensions,
            provider=self.provider_name,
            model=self.model_name,
        )
