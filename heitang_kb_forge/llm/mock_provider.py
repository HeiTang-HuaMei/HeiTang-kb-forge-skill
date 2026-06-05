from heitang_kb_forge.llm.provider import ProviderResponse


class MockProvider:
    provider_name = "mock"

    def __init__(self, model_name: str = "mock-model") -> None:
        self.model_name = model_name
        self.call_count = 0

    def generate_json(self, prompt: str, schema_name: str) -> ProviderResponse:
        self.call_count += 1
        low = prompt.lower()
        supported = not any(word in low for word in ["outside", "unsupported", "无依据", "外部"])
        payload = {
            "supported": supported,
            "confidence": 0.86 if supported else 0.35,
            "reason": "mock provider found evidence support" if supported else "mock provider found no support",
            "boundary": "inside" if supported else "outside",
            "risk_level": "low" if supported else "high",
        }
        return ProviderResponse(
            payload=payload,
            provider_name=self.provider_name,
            model_name=self.model_name,
            token_usage={"input_tokens": len(prompt.split()), "output_tokens": 24},
            latency_ms=1,
        )
