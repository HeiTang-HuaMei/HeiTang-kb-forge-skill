from heitang_kb_forge.llm.provider import ProviderResponse


class OpenAICompatibleProvider:
    provider_name = "openai-compatible"

    def __init__(self, model_name: str, api_key: str | None = None, endpoint: str | None = None) -> None:
        self.model_name = model_name
        self.api_key = api_key
        self.endpoint = endpoint

    def generate_json(self, prompt: str, schema_name: str) -> ProviderResponse:
        if not self.api_key or not self.endpoint:
            raise RuntimeError("OpenAI-compatible LLM provider is not configured")
        raise RuntimeError("OpenAI-compatible LLM provider network calls are not implemented in v0.9.0")
