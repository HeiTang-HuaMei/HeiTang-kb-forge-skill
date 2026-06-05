from pydantic import BaseModel


class LLMQualityAssistResult(BaseModel):
    enabled: bool = False
    provider: str = "mock"
    status: str = "fallback"
