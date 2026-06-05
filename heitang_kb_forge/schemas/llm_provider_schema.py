from pydantic import BaseModel


class LLMProviderSettings(BaseModel):
    provider: str = "mock"
    model: str = "mock-model"
    base_url: str | None = None
    api_key_env: str | None = None
    call_log: bool = True
