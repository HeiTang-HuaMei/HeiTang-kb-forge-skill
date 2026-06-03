from heitang_kb_forge.embedding.provider import EmbeddingResponse


class OpenAICompatibleEmbeddingProvider:
    provider_name = "openai-compatible"

    def __init__(self, model_name: str, api_key: str | None = None, endpoint: str | None = None) -> None:
        self.model_name = model_name
        self.api_key = api_key
        self.endpoint = endpoint

    def embed(self, text: str) -> EmbeddingResponse:
        if not self.api_key or not self.endpoint:
            raise RuntimeError("OpenAI-compatible embedding provider is not configured")
        raise RuntimeError("OpenAI-compatible embedding provider network calls are not implemented in v0.9.0")
