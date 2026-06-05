from pydantic import BaseModel


class LLMProviderPolicy(BaseModel):
    default_provider: str = "mock"
    allow_network: bool = False
    fallback_provider: str = "mock"
    require_audit_log: bool = True
    redact_sensitive_input: bool = True
    fail_safe: bool = True
