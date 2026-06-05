from heitang_kb_forge.llm.provider import ProviderResponse


class OpenAICompatibleAdapter:
    provider_name = "openai_compatible"

    def __init__(self, model_name: str, base_url: str | None = None, api_key: str | None = None) -> None:
        self.model_name = model_name
        self.base_url = base_url
        self.api_key = api_key

    def generate_json(self, prompt: str, schema_name: str) -> ProviderResponse:
        if not self.base_url or not self.api_key:
            raise RuntimeError("OpenAI-compatible provider is not configured")
        raise RuntimeError("OpenAI-compatible provider network calls are disabled in v1.7 tests")
