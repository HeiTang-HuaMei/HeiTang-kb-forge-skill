from pydantic import BaseModel, Field


class LiveProviderSmokeReport(BaseModel):
    live_smoke_version: str = "1.0.0"
    llm_provider_configured: bool = False
    embedding_provider_configured: bool = False
    llm_callable: bool = False
    embedding_callable: bool = False
    llm_assets_generated: bool = False
    embeddings_generated: bool = False
    llm_quality_report_generated: bool = False
    api_key_leak_detected: bool = False
    hallucination_risk_warning: bool = False
    warnings: list[str] = Field(default_factory=list)
